// `epito token <name>`: the agent's own short-lived GitHub principal.
//
// The mechanism, in order:
//   1. read the agent's App credentials — app id + RSA private key — from the
//      runtime box (env) or from .epito/apps/<name>.json (0600)
//   2. sign a 9-minute RS256 JWT as the App (GitHub's ceiling is 10)
//   3. GET /repos/<[runtime].repo>/installation — which installation of this
//      App covers the repository the manifest names
//   4. POST /app/installations/<id>/access_tokens, asking for exactly the
//      permissions lib/scopes.js derives from [identity].scopes, restricted to
//      that one repository
//   5. return the token; append one audit line naming everything about the
//      mint EXCEPT the token
//
// Three properties are load-bearing, and each is a rule from somewhere:
//   - The token is never written to disk (pitch: "mint per run, throw away").
//     It is returned in memory, injected into a run's environment, and
//     redacted out of the run log. `.epito/` holds the App key, never a token.
//   - The token is scoped by the manifest twice over: its permissions come
//     from [identity].scopes (spec rule 2, scopes are the ceiling) and its
//     repository from [runtime].repo. An installation granted more than the
//     manifest declares still mints a narrow token.
//   - One manifest, one principal (spec rule 4): credentials are looked up by
//     [agent].name, so the same name always mints as the same App.
import { createSign } from "node:crypto";
import { readFileSync, existsSync, statSync } from "node:fs";
import { join } from "node:path";
import { EPITO_DIR } from "./audit.js";
import { mapScopes, describePermissions } from "./scopes.js";

export const DEFAULT_API = "https://api.github.com";
const JWT_TTL_S = 9 * 60;

// An error a person can act on: `epito token` prints .message and stops.
export class TokenError extends Error {}

const b64url = (s) => Buffer.from(s).toString("base64url");

// github-actions → GITHUB_ACTIONS. [agent].name is [a-z0-9-], so this is total.
export const envSuffix = (name) => name.toUpperCase().replace(/[^A-Z0-9]/g, "_");

export const envNames = (name) => {
  const s = envSuffix(name);
  return { id: `EPITO_APP_ID_${s}`, key: `EPITO_APP_KEY_${s}` };
};

export const appFilePath = (name, dir = EPITO_DIR) => join(dir, "apps", `${name}.json`);

// Accepts a PEM, a PEM whose newlines survived as the two characters \n (what
// happens to a key pasted into a .env), or base64 of either — the one-line
// form a systemd EnvironmentFile can actually hold.
function normalizeKey(raw, where) {
  let key = String(raw).trim();
  if (!key) throw new TokenError(`${where} is empty — it must hold the App's RSA private key (PEM, or base64 of it)`);
  if (!key.includes("BEGIN")) {
    const decoded = Buffer.from(key, "base64").toString("utf8");
    if (!decoded.includes("BEGIN")) {
      throw new TokenError(`${where} does not look like an RSA private key — expected a PEM beginning "-----BEGIN RSA PRIVATE KEY-----", or base64 of one. Download the App's key from GitHub (Settings → Developer settings → GitHub Apps → Private keys) and set it whole`);
    }
    key = decoded.trim();
  }
  if (key.includes("\\n") && !key.includes("\n")) key = key.replace(/\\n/g, "\n");
  return key + (key.endsWith("\n") ? "" : "\n");
}

// Returns { appId, privateKey, source } when the agent has a principal,
// { absent: true, looked } when it has none. Throws when it has a broken one:
// a half-configured principal is a mistake to name, not a fallback to take.
export function loadAppCredentials(name, { env = process.env, dir = EPITO_DIR } = {}) {
  const { id: idVar, key: keyVar } = envNames(name);
  const file = appFilePath(name, dir);
  const looked = `${idVar} + ${keyVar} in the environment, or ${file}`;

  if (env[idVar] || env[keyVar]) {
    if (!env[idVar]) throw new TokenError(`${name} has ${keyVar} but no ${idVar} — an App is an id and a key, and one without the other mints nothing. Set ${idVar} to the App's numeric id`);
    if (!env[keyVar]) throw new TokenError(`${name} has ${idVar} but no ${keyVar} — an App is an id and a key, and one without the other mints nothing. Set ${keyVar} to the App's private key (PEM, or base64 of it)`);
    return { appId: String(env[idVar]).trim(), privateKey: normalizeKey(env[keyVar], keyVar), source: `${idVar}/${keyVar}` };
  }

  if (existsSync(file)) {
    const mode = statSync(file).mode & 0o777;
    if (mode & 0o077) {
      throw new TokenError(`${file} is mode ${mode.toString(8).padStart(4, "0")} and holds ${name}'s private key — anyone on this box can read it. Run \`chmod 600 ${file}\``);
    }
    let parsed;
    try { parsed = JSON.parse(readFileSync(file, "utf8")); }
    catch (e) { throw new TokenError(`${file} is not valid JSON: ${e.message} — it holds {"app_id": 123, "private_key": "-----BEGIN RSA PRIVATE KEY-----\\n..."}`); }
    if (!parsed?.app_id) throw new TokenError(`${file} has no "app_id" — it holds {"app_id": 123, "private_key": "..."}`);
    if (!parsed?.private_key) throw new TokenError(`${file} has no "private_key" — it holds {"app_id": 123, "private_key": "..."}`);
    return { appId: String(parsed.app_id).trim(), privateKey: normalizeKey(parsed.private_key, file), source: file };
  }

  return { absent: true, looked };
}

// A GitHub App JWT: RS256, issued a minute in the past so a slow clock on the
// box doesn't read as a token from the future.
export function appJwt(appId, privateKey, now = Math.floor(Date.now() / 1000)) {
  const head = b64url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const body = b64url(JSON.stringify({ iat: now - 60, exp: now + JWT_TTL_S, iss: String(appId) }));
  const signer = createSign("RSA-SHA256");
  signer.update(`${head}.${body}`);
  let sig;
  try { sig = signer.sign(privateKey, "base64url"); }
  catch (e) { throw new TokenError(`${appId}'s private key did not sign: ${e.message} — the key must be the App's RSA private key in PEM form, not its client secret and not a personal access token`); }
  return `${head}.${body}.${sig}`;
}

async function call(url, { auth, method = "GET", body } = {}) {
  let res;
  try {
    res = await fetch(url, {
      method,
      headers: { authorization: auth, accept: "application/vnd.github+json", "x-github-api-version": "2022-11-28", "user-agent": "epito", ...(body ? { "content-type": "application/json" } : {}) },
      body: body ? JSON.stringify(body) : undefined,
    });
  } catch (e) {
    throw new TokenError(`could not reach ${new URL(url).host}: ${e.message} — the runtime box needs outbound HTTPS to mint a token`);
  }
  const text = await res.text();
  let json = null;
  try { json = JSON.parse(text); } catch {}
  return { status: res.status, json, message: json?.message ?? text.slice(0, 200) };
}

// Mint one token for one agent. Returns
// { token, expiresAt, permissions, repositories, installationId, scopes, source }.
export async function mintToken(name, manifest, { env = process.env, dir = EPITO_DIR, api = env.EPITO_GITHUB_API || DEFAULT_API } = {}) {
  // The manifest's own problems first: they are the agent's author's to fix,
  // and they are cheaper to fix than anything about the box.
  const repo = manifest?.runtime?.repo;
  if (!repo) throw new TokenError(`${name}'s token is scoped to one repository and [runtime].repo is unset — add repo = "owner/name" to [runtime], the repository this agent works in`);
  const [owner, repoName] = String(repo).split("/");

  const scopes = manifest?.identity?.scopes ?? [];
  if (!scopes.length) throw new TokenError(`${name} declares no [identity].scopes, so there is no permission to mint — scopes are the ceiling (spec rule 2), and an empty ceiling is an agent that can do nothing`);
  const { permissions, errors } = mapScopes(scopes);
  if (errors.length) throw new TokenError(`${name}'s scopes do not all map to GitHub permissions:\n  ✗ ${errors.join("\n  ✗ ")}`);

  const creds = loadAppCredentials(name, { env, dir });
  if (creds.absent) {
    throw new TokenError(`${name} has no principal to mint from — epito looked for ${creds.looked}. Create a GitHub App for ${name}, install it on its repository, and put the App's id and private key there`);
  }

  const jwt = appJwt(creds.appId, creds.privateKey);
  const auth = `Bearer ${jwt}`;

  const inst = await call(`${api}/repos/${owner}/${repoName}/installation`, { auth });
  if (inst.status === 401) {
    throw new TokenError(`GitHub refused ${name}'s App credentials (401: ${inst.message}) — App ${creds.appId} from ${creds.source}. Check the id matches the key, and that this box's clock is right: a JWT signed by a clock more than a minute fast is rejected`);
  }
  if (inst.status === 404) {
    throw new TokenError(`App ${creds.appId} is not installed on ${repo} (404) — an agent's principal must be installed on the repository it works in. Install it at https://github.com/settings/apps (Install App), granting ${describePermissions(permissions)}`);
  }
  if (inst.status !== 200 || !inst.json?.id) {
    throw new TokenError(`GitHub would not say which installation of App ${creds.appId} covers ${repo} (${inst.status}: ${inst.message})`);
  }
  const installationId = inst.json.id;

  const mint = await call(`${api}/app/installations/${installationId}/access_tokens`, {
    auth, method: "POST", body: { repositories: [repoName], permissions },
  });
  if (mint.status === 422) {
    throw new TokenError(`GitHub would not grant ${name} the permissions its manifest declares (422: ${mint.message}) — [identity].scopes asks for ${describePermissions(permissions)}, and App ${creds.appId}'s installation on ${repo} does not carry all of it. Widen the App's permissions on GitHub, or narrow [identity].scopes: the manifest is the ceiling, not the floor`);
  }
  if (mint.status !== 201 || !mint.json?.token) {
    throw new TokenError(`the mint failed for ${name} (${mint.status}: ${mint.message}) — installation ${installationId} on ${repo}`);
  }

  return {
    token: mint.json.token,
    expiresAt: mint.json.expires_at ?? null,
    permissions: mint.json.permissions ?? permissions,
    repositories: (mint.json.repositories ?? []).map((r) => r.full_name ?? r.name),
    installationId,
    repo,
    scopes,
    source: creds.source,
  };
}

// What goes in .epito/audit.jsonl. Everything about the mint except the token:
// the audit trail proves a principal was used, it does not re-issue it.
export const mintAudit = (m) => ({
  action: "token.mint",
  repo: m.repo,
  installation: m.installationId,
  scopes: m.scopes,
  permissions: describePermissions(m.permissions),
  expires: m.expiresAt,
});

export { describePermissions };
