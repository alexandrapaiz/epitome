// The agent's own principal (cycle 1 bet 2, docs/cycles/2026-09-21-cycle-1-amendment.md).
//
// An agent is *someone* — "its own identity, never the owner's token" (ADR-2).
// Until now a run borrowed the box's GH_TOKEN, so every PR every seat opened
// wore the owner's face. This module mints the alternative: a short-lived
// GitHub App installation token, scoped by [identity].scopes, valid an hour,
// handed to one run and then forgotten. The PR opens as `<app-slug>[bot]`.
//
// Where the App key lives, and why not in the manifest: spec rule 1 says a
// manifest must be publishable without redaction, so the key can never be a
// field. It is a secret on the runtime box, found by a name derived from the
// agent's name — agent `pm` reads EPITO_APP_ID_PM and EPITO_APP_PRIVATE_KEY_PM.
// Nothing about the principal is written to disk: `.epito/audit.jsonl` records
// that a mint happened, its scopes and its expiry, never the token.
//
// No dependencies: the JWT is ~15 lines of node:crypto, and the two REST calls
// are fetch. GITHUB_API_URL redirects both (the same variable Actions sets),
// which is how the smoke test runs this whole path with no network.
import { createSign, createPrivateKey } from "node:crypto";

// v0.1 maps exactly the scopes the three alexandria seat shapes need
// (deploy-identity-v0 "Rabbit holes": no table sprawl). Anything else fails
// loudly rather than minting a principal the manifest never described.
export const SCOPE_MAP = {
  "github:contents": ["contents", "write"],
  "github:pull_requests": ["pull_requests", "write"],
  "github:issues": ["issues", "write"],
  "github:metadata": ["metadata", "read"],
};

export const API_BASE = () => (process.env.GITHUB_API_URL || "https://api.github.com").replace(/\/+$/, "");

// Secret names, derived from the agent's name: pm -> EPITO_APP_ID_PM.
export function appSecretNames(name) {
  const key = String(name).toUpperCase().replace(/-/g, "_");
  return { idVar: `EPITO_APP_ID_${key}`, keyVar: `EPITO_APP_PRIVATE_KEY_${key}` };
}

// Is there a principal for this agent on this box at all? Absent one, a run
// falls back to whatever [runtime].env gave it — the pre-bet-2 behaviour.
export function hasPrincipal(name, env = process.env) {
  const { idVar, keyVar } = appSecretNames(name);
  return Boolean(env[idVar] && env[keyVar]);
}

// [identity].scopes -> App permissions. Returns { permissions, errors }.
export function mapScopes(scopes) {
  const permissions = {};
  const errors = [];
  const known = Object.keys(SCOPE_MAP).join(", ");
  for (const s of scopes ?? []) {
    const hit = SCOPE_MAP[s];
    if (!hit) {
      errors.push(`scope "${s}" has no GitHub App permission in spec v0.1 — mapped scopes are ${known}. Remove it from [identity].scopes, or keep it and deploy to a platform that has it; a principal is never minted with a scope nobody can honour`);
      continue;
    }
    const [perm, level] = hit;
    // Widest wins, so listing contents twice can never quietly narrow it.
    if (permissions[perm] !== "write") permissions[perm] = level;
  }
  return { permissions, errors };
}

// A private key arrives from a secrets file or a systemd EnvironmentFile,
// where real newlines are awkward: accept the PEM, the PEM with \n escaped,
// and the PEM base64'd whole. Anything else is named as what it is.
export function normalizePrivateKey(raw, keyVar) {
  let pem = String(raw ?? "").trim();
  if (!pem) throw new Error(`${keyVar} is empty — it holds the agent's GitHub App private key (the .pem GitHub gave you when the App was created)`);
  if (!pem.includes("BEGIN") && /^[A-Za-z0-9+/=\s]+$/.test(pem)) {
    const decoded = Buffer.from(pem.replace(/\s+/g, ""), "base64").toString("utf8");
    if (decoded.includes("BEGIN")) pem = decoded.trim();
  }
  if (pem.includes("\\n")) pem = pem.replace(/\\n/g, "\n");
  if (!/-----BEGIN [A-Z ]*PRIVATE KEY-----/.test(pem)) {
    throw new Error(`${keyVar} is not a private key — it must be the App's .pem file contents, beginning "-----BEGIN RSA PRIVATE KEY-----" (escaped \\n or base64 of the whole file are both accepted)`);
  }
  try { createPrivateKey(pem); } catch (e) {
    throw new Error(`${keyVar} is not a usable private key (${e.message}) — re-copy the .pem GitHub gave you when the App was created`);
  }
  return pem;
}

const b64u = (x) => Buffer.from(x).toString("base64url");

// The App's own credential: a 9-minute RS256 JWT signed with the App key.
// GitHub rejects anything over 10 minutes, and clock skew both ways is real,
// so iat is backdated a minute (GitHub's own documented advice).
export function appJwt(appId, pem, now = Date.now()) {
  const iat = Math.floor(now / 1000) - 60;
  const head = b64u(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const body = b64u(JSON.stringify({ iat, exp: iat + 540, iss: String(appId) }));
  const signer = createSign("RSA-SHA256");
  signer.update(`${head}.${body}`);
  return `${head}.${body}.${b64u(signer.sign(createPrivateKey(pem)))}`;
}

async function gh(path, { method = "GET", auth, body, api = API_BASE() } = {}) {
  const res = await fetch(`${api}${path}`, {
    method,
    headers: {
      accept: "application/vnd.github+json",
      authorization: `Bearer ${auth}`,
      "x-github-api-version": "2022-11-28",
      "user-agent": "epito/0.1",
      ...(body ? { "content-type": "application/json" } : {}),
    },
    ...(body ? { body: JSON.stringify(body) } : {}),
  });
  const text = await res.text();
  let json = null;
  try { json = text ? JSON.parse(text) : null; } catch {}
  return { status: res.status, json, text };
}

// Mint one token for one run. Throws Error with a message the reader can act
// on; returns { token, expiresAt, permissions, installationId, appSlug, appId }.
// The token is returned, never logged, never persisted.
export async function mintToken({ name, scopes, repo, env = process.env, api = undefined, fetchBot = true }) {
  const { idVar, keyVar } = appSecretNames(name);
  const appId = env[idVar];
  if (!appId) {
    throw new Error(`no principal for "${name}" on this box — ${idVar} is unset. Each agent mints its own identity from its own GitHub App: put the App's id in ${idVar} and its private key in ${keyVar}, or run without a principal and the agent borrows whatever token [runtime].env gives it`);
  }
  if (!repo) {
    throw new Error(`"${name}" has no [runtime].repo, and an installation token is scoped to a repository — add repo = "owner/name" to [runtime], the repository this agent works in`);
  }
  if (!/^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/.test(repo)) {
    throw new Error(`[runtime].repo "${repo}" must be owner/name — the repository the token is minted for`);
  }
  const { permissions, errors } = mapScopes(scopes);
  if (errors.length) throw new Error(errors.join("\n         "));
  if (!Object.keys(permissions).length) {
    throw new Error(`"${name}" has no [identity].scopes to mint — scopes are the ceiling (spec rule 2), and an empty ceiling is an agent that can do nothing. Declare what it needs, e.g. scopes = ["github:contents", "github:pull_requests"]`);
  }

  const pem = normalizePrivateKey(env[keyVar], keyVar);
  const jwt = appJwt(appId, pem);
  const base = api ?? API_BASE();

  const inst = await gh(`/repos/${repo}/installation`, { auth: jwt, api: base });
  if (inst.status === 404) {
    throw new Error(`"${name}"'s App is not installed on ${repo} — install it there (Settings → GitHub Apps → the App → Install), then run again; an App with no installation on a repository can mint no token for it`);
  }
  if (inst.status === 401) {
    throw new Error(`GitHub refused "${name}"'s App credentials — ${idVar} and ${keyVar} must belong to the same App, and the box's clock must be right (the JWT is signed against it)`);
  }
  if (inst.status !== 200 || !inst.json?.id) {
    throw new Error(`GitHub would not name the installation of "${name}"'s App on ${repo} (HTTP ${inst.status}: ${(inst.json?.message ?? inst.text ?? "").slice(0, 200)})`);
  }

  const mint = await gh(`/app/installations/${inst.json.id}/access_tokens`, {
    method: "POST", auth: jwt, api: base,
    body: { repositories: [repo.split("/")[1]], permissions },
  });
  if (mint.status === 422) {
    const asked = Object.entries(permissions).map(([k, v]) => `${k}:${v}`).join(", ");
    throw new Error(`"${name}"'s App cannot grant what [identity].scopes asks for (${asked}) — GitHub says: ${(mint.json?.message ?? "").slice(0, 200)}. Widen the App's permissions to match the manifest, or narrow the manifest: scopes are the ceiling, and the App is the wall`);
  }
  if (mint.status !== 201 || !mint.json?.token) {
    throw new Error(`the mint for "${name}" failed (HTTP ${mint.status}: ${(mint.json?.message ?? mint.text ?? "").slice(0, 200)})`);
  }

  const appSlug = inst.json.app_slug ?? null;
  const out = {
    token: mint.json.token,
    expiresAt: mint.json.expires_at ?? null,
    permissions: mint.json.permissions ?? permissions,
    installationId: inst.json.id,
    appSlug,
    appId: inst.json.app_id ?? Number(appId),
    bot: null,
  };
  // Commit attribution, best effort: a bot's commits are credited by the
  // <id>+<slug>[bot]@users.noreply.github.com address, and the id is only
  // knowable by asking. If GitHub won't say, the run keeps its old git
  // identity rather than inventing an address that credits nobody.
  if (fetchBot && appSlug) {
    try {
      const u = await gh(`/users/${encodeURIComponent(`${appSlug}[bot]`)}`, { auth: out.token, api: base });
      if (u.status === 200 && u.json?.id) {
        out.bot = { login: `${appSlug}[bot]`, id: u.json.id, email: `${u.json.id}+${appSlug}[bot]@users.noreply.github.com` };
      }
    } catch {}
  }
  return out;
}
