// The agent as a credentialed principal (cycle 1, bet 2 — the identity slice).
//
// One idea: an agent's authority is its manifest's [identity].scopes, and
// nothing wider. This module turns that declaration into a real GitHub
// credential and hands it to one run:
//
//   [identity].scopes  →  fine-grained App permissions  →  a JWT signed with
//   the agent's own App private key  →  an installation access token, scoped
//   to [runtime].repo, that expires in an hour.
//
// Three properties the rest of the product leans on:
//   1. **Nothing personal, anywhere.** The manifest names scopes, not keys
//      (spec rule 1). The App id and private key live on the runtime box as
//      secrets, per agent, found by convention: EPITO_APP_ID_<NAME> and
//      EPITO_APP_KEY_<NAME> (or EPITO_APP_KEY_FILE_<NAME>, a path to the
//      .pem). <NAME> is [agent].name upper-cased with - as _.
//   2. **Scopes are the ceiling** (spec rule 2). A scope with no mapping
//      fails loudly rather than minting something wider; the token asks for
//      exactly the mapped permissions and exactly one repository.
//   3. **The token never touches disk.** It is returned in memory, injected
//      into the run's environment, and forgotten. The audit line records the
//      mint — agent, scopes, permissions, installation, expiry — never the
//      secret.
//
// Zero new dependencies: node:crypto signs the JWT (RS256), and fetch is
// built in from Node 18. EPITO_GITHUB_API redirects every call, which is how
// the smoke test exercises this against a local stub and never a live account.
import { createSign } from "node:crypto";
import { readFileSync } from "node:fs";

const API_VERSION = "2022-11-28";
const UA = "epito/0.1.0";

export const api = () => (process.env.EPITO_GITHUB_API || "https://api.github.com").replace(/\/$/, "");

// An error whose message is already the product's own voice: it names the
// rule broken and the fix, so every caller can print it verbatim.
export class IdentityError extends Error {}

// --- the scope map -------------------------------------------------------
// spec/manifest.md: "The deploy target maps these to fine-grained App
// permissions; anything unmapped fails deploy loudly." v0.1 maps the three
// permissions the three HQ seat shapes actually use, and metadata, which
// GitHub grants implicitly anyway. A bare scope means write, because the
// manifest's own example (a seat that opens pull requests) means write; add
// `.read` to ask for less.
export const SCOPE_MAP = {
  "github:contents": ["contents", "write"],
  "github:contents.read": ["contents", "read"],
  "github:pull_requests": ["pull_requests", "write"],
  "github:pull_requests.read": ["pull_requests", "read"],
  "github:issues": ["issues", "write"],
  "github:issues.read": ["issues", "read"],
  "github:metadata": ["metadata", "read"],
};

const KNOWN = Object.keys(SCOPE_MAP).filter((s) => !s.endsWith(".read")).join(", ");

// Returns { permissions } or throws with every unmapped scope named at once.
export function mapScopes(scopes, { agent = "this agent" } = {}) {
  const permissions = {};
  const unmapped = [];
  for (const s of scopes ?? []) {
    const hit = SCOPE_MAP[s];
    if (!hit) { unmapped.push(s); continue; }
    const [perm, level] = hit;
    // Widest wins: declaring both github:issues and github:issues.read is
    // redundant, not a downgrade.
    if (permissions[perm] !== "write") permissions[perm] = level;
  }
  if (unmapped.length) {
    throw new IdentityError(
      `${agent}: [identity].scopes names ${unmapped.length > 1 ? "scopes" : "a scope"} epito cannot map to a GitHub App permission — ${unmapped.map((s) => `"${s}"`).join(", ")}. ` +
      `Spec v0.1 maps ${KNOWN} (suffix .read for read-only). Fix [identity].scopes: epito never mints a token wider than the manifest, and never quietly narrower.`
    );
  }
  // GitHub grants metadata:read to every installation regardless; naming it
  // keeps the request an honest description of what the token can do.
  if (!permissions.metadata) permissions.metadata = "read";
  return { permissions };
}

// --- credentials on the box ----------------------------------------------

export const envKey = (name) => String(name).toUpperCase().replace(/-/g, "_");

// The three env names an agent's principal is found under, in one place so
// the error strings and the docs cannot drift apart.
export function credentialNames(name) {
  const k = envKey(name);
  return { id: `EPITO_APP_ID_${k}`, key: `EPITO_APP_KEY_${k}`, keyFile: `EPITO_APP_KEY_FILE_${k}` };
}

// Returns { configured: false } when this agent has no principal on this box
// (v0 fallback: the run uses whatever shared secret it uses today), or
// { configured: true, appId, privateKey }. Half a principal is an error, not
// a fallback — silently running as the shared token is exactly the identity
// confusion this slice exists to end.
export function readAppCredentials(name, env = process.env) {
  const n = credentialNames(name);
  const appId = env[n.id]?.trim();
  const inline = env[n.key];
  const file = env[n.keyFile]?.trim();
  if (!appId && !inline && !file) return { configured: false, names: n };

  if (!appId) {
    throw new IdentityError(`${name}: a private key is on this box but ${n.id} is not set — epito needs both the App id and its key to mint a token as ${name}[bot]. Set ${n.id} to the App's numeric id (GitHub → Settings → Developer settings → GitHub Apps).`);
  }
  if (!inline && !file) {
    throw new IdentityError(`${name}: ${n.id} is set but the App's private key is not — set ${n.key} to the .pem contents, or ${n.keyFile} to a path holding it. epito refuses to fall back to a shared token: a PR opened by the wrong principal is worse than no PR.`);
  }
  if (!/^\d+$/.test(appId)) {
    throw new IdentityError(`${name}: ${n.id} must be the App's numeric id, got "${appId}" — that looks like a name or a slug. The id is the number on the App's settings page.`);
  }

  let privateKey;
  if (file) {
    try { privateKey = readFileSync(file, "utf8"); }
    catch (e) { throw new IdentityError(`${name}: ${n.keyFile} points at ${file}, which epito cannot read (${e.code ?? e.message}) — that file holds the App's private key and must be readable by the user epitod runs as, at 0600.`); }
  } else {
    // A one-line env var is the normal way a .pem survives a secrets file;
    // accept both that and a real multi-line value.
    privateKey = inline.includes("\\n") ? inline.replace(/\\n/g, "\n") : inline;
  }
  privateKey = privateKey.trim() + "\n";
  if (!/-----BEGIN [A-Z ]*PRIVATE KEY-----/.test(privateKey)) {
    throw new IdentityError(`${name}: the value in ${file ? n.keyFile : n.key} is not a PEM private key (no "-----BEGIN ... PRIVATE KEY-----" line) — paste the .pem GitHub gave you when the App was created, newlines and all.`);
  }
  return { configured: true, appId, privateKey, names: n };
}

// --- the JWT -------------------------------------------------------------

const b64url = (buf) => Buffer.from(buf).toString("base64url");

// A GitHub App JWT: RS256, at most 10 minutes, backdated a minute against
// clock skew on the box.
export function appJwt({ appId, privateKey, name = "agent", now = Date.now() }) {
  const iat = Math.floor(now / 1000) - 60;
  const head = b64url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const body = b64url(JSON.stringify({ iat, exp: iat + 9 * 60, iss: String(appId) }));
  try {
    const signer = createSign("RSA-SHA256");
    signer.update(`${head}.${body}`);
    signer.end();
    return `${head}.${body}.${b64url(signer.sign(privateKey))}`;
  } catch (e) {
    throw new IdentityError(`${name}: the App private key would not sign (${e.message}) — GitHub issues an RSA .pem; a converted or truncated key fails here, so re-download it from the App's settings page.`);
  }
}

// --- the mint ------------------------------------------------------------

async function gh(url, { token, method = "GET", body, name }) {
  let res;
  try {
    res = await fetch(url, {
      method,
      headers: { authorization: `Bearer ${token}`, accept: "application/vnd.github+json", "x-github-api-version": API_VERSION, "user-agent": UA, ...(body ? { "content-type": "application/json" } : {}) },
      ...(body ? { body: JSON.stringify(body) } : {}),
    });
  } catch (e) {
    throw new IdentityError(`${name}: cannot reach GitHub at ${api()} (${e.cause?.code ?? e.message}) — the box needs outbound HTTPS to mint a token; set EPITO_GITHUB_API if you meant a different host.`);
  }
  const text = await res.text();
  let json = null;
  try { json = text ? JSON.parse(text) : null; } catch { /* reported with the status below */ }
  return { status: res.status, json, text };
}

// Mint one short-lived installation token for one agent, scoped to its
// [runtime].repo and its [identity].scopes. Returns
// { minted: true, token, expiresAt, permissions, installationId, repo } or
// { minted: false, reason } when the agent has no principal on this box.
// Every failure past "no principal" throws IdentityError: an agent that has
// an identity must use it or not run.
export async function mintToken(manifest, { env = process.env } = {}) {
  const name = manifest.agent?.name ?? "agent";
  const repo = manifest.runtime?.repo;
  if (!repo) {
    throw new IdentityError(`${name}: [runtime].repo is required to mint a token — an installation token is scoped to one repository, and epito will not mint an account-wide one.`);
  }
  const creds = readAppCredentials(name, env);
  if (!creds.configured) {
    return { minted: false, reason: `no App principal on this box for ${name} (${creds.names.id} unset)` };
  }

  const { permissions } = mapScopes(manifest.identity?.scopes, { agent: name });
  const jwt = appJwt({ appId: creds.appId, privateKey: creds.privateKey, name });

  const inst = await gh(`${api()}/repos/${repo}/installation`, { token: jwt, name });
  if (inst.status === 404) {
    throw new IdentityError(`${name}: App ${creds.appId} is not installed on ${repo} — install it on that repository (GitHub → the App → Install App → Only select repositories → ${repo}). One manifest, one principal: the App is ${name}'s, and it reaches nothing else.`);
  }
  if (inst.status === 401) {
    throw new IdentityError(`${name}: GitHub refused the App JWT (401) — ${creds.names.id}=${creds.appId} and the key in ${creds.names.key} belong to different Apps, or the box's clock is off by more than a minute.`);
  }
  if (inst.status !== 200 || !inst.json?.id) {
    throw new IdentityError(`${name}: GitHub answered ${inst.status} looking up the installation on ${repo} — ${(inst.json?.message ?? inst.text ?? "").slice(0, 200)}`);
  }

  const [, repoName] = repo.split("/");
  const mint = await gh(`${api()}/app/installations/${inst.json.id}/access_tokens`, {
    token: jwt, method: "POST", name,
    body: { repositories: [repoName], permissions },
  });
  if (mint.status === 422) {
    throw new IdentityError(`${name}: GitHub refused the scopes — ${(mint.json?.message ?? "").slice(0, 200)}. [identity].scopes asks for ${JSON.stringify(permissions)}, and an installation token can never exceed what the App itself was granted: widen the App's permissions on GitHub (the owner must approve), or narrow [identity].scopes.`);
  }
  if (mint.status !== 201 || !mint.json?.token) {
    throw new IdentityError(`${name}: GitHub answered ${mint.status} minting the installation token — ${(mint.json?.message ?? mint.text ?? "").slice(0, 200)}`);
  }

  return {
    minted: true,
    token: mint.json.token,
    expiresAt: mint.json.expires_at ?? null,
    permissions: mint.json.permissions ?? permissions,
    requested: permissions,
    installationId: inst.json.id,
    appId: creds.appId,
    repo,
  };
}

// What the audit line says about a mint. The token is deliberately absent:
// this function is the only shape a mint is ever written down in.
export function mintAudit({ agent, scopes, result, trigger }) {
  return {
    agent, action: "token.mint",
    ...(trigger ? { trigger } : {}),
    scopes, repo: result.repo, app: result.appId,
    installation: result.installationId,
    permissions: result.permissions,
    expires: result.expiresAt,
  };
}
