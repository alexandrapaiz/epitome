// The identity leg: a manifest's `[identity].scopes` become a real, expiring
// GitHub credential that belongs to the agent and not to its owner.
//
// The mechanism (docs/architecture.md, "Flow: per run"):
//   1. load the agent's App id + private key (never the owner's PAT)
//   2. sign a <=10-minute RS256 JWT as the App — this proves we are the App
//   3. find the App's installation on the manifest's [runtime].repo
//   4. POST /app/installations/{id}/access_tokens asking for EXACTLY the
//      permissions [identity].scopes maps to, on exactly that one repo
//   5. hand the token back in memory; append an audit line that records the
//      mint and never the token
//
// Spec rule 2, "scopes are the ceiling", is enforced here and nowhere else:
// the permissions object is derived from the manifest on every mint, so a
// token can never carry a permission the (diffable, reviewable) manifest
// does not declare. An unmapped scope fails the mint loudly rather than
// quietly minting a narrower token than the manifest promised.
//
// Route-agnostic by construction (EPI-4, still open): App-per-agent and one
// shared App with per-agent installations both reduce to (app id, key,
// installation id), so nothing below has to be rewritten when the owner
// rules. What differs between the routes is only where those three come
// from — see loadPrincipal.
import { createSign, createPrivateKey } from "node:crypto";
import { readFileSync, existsSync } from "node:fs";
import { join } from "node:path";
import { EPITO_DIR } from "./audit.js";

export const KEYS_DIR = join(EPITO_DIR, "keys");
export const PRINCIPALS_PATH = join(EPITO_DIR, "principals.json");
export const GITHUB_API = process.env.EPITO_GITHUB_API || "https://api.github.com";

// `[identity].scopes` → fine-grained GitHub App permissions. Deliberately the
// three the HQ seat shapes need (docs/pitches/deploy-identity-v0.md rabbit
// hole: "three seat shapes' scopes only"); the full grammar is a v0.2 spec
// question. `metadata: read` is not in the table because GitHub grants it to
// every installation implicitly.
export const SCOPE_MAP = {
  "github:contents": { contents: "write" },
  "github:pull_requests": { pull_requests: "write" },
  "github:issues": { issues: "write" },
};

// Returns { permissions } or throws an Error whose message is product surface.
export function permissionsFor(scopes) {
  const permissions = {};
  const unmapped = [];
  for (const s of scopes) {
    const mapped = SCOPE_MAP[s];
    if (!mapped) { unmapped.push(s); continue; }
    Object.assign(permissions, mapped);
  }
  if (unmapped.length) {
    throw new Error(
      `[identity].scopes has ${unmapped.length === 1 ? "a scope" : "scopes"} this deploy target cannot mint: ${unmapped.map((s) => `"${s}"`).join(", ")}. ` +
      `v0.1 maps ${Object.keys(SCOPE_MAP).map((s) => `"${s}"`).join(", ")} to GitHub App permissions and refuses the rest rather than minting a token narrower than the manifest promises. ` +
      `Fix: remove the scope from agent.toml, or open a card to map it.`
    );
  }
  // GitHub reads an omitted-or-empty `permissions` as "everything this
  // installation has" — the exact inverse of rule 2. `epito validate` already
  // refuses an empty [identity].scopes, so this is unreachable through the
  // CLI; it is here because the one place the ceiling is enforced is the one
  // place that must not fail open.
  if (Object.keys(permissions).length === 0) {
    throw new Error(
      `[identity].scopes mapped to no GitHub permission at all, so there is nothing to mint. ` +
      `GitHub reads an empty permission request as "everything this installation can do", which would hand the agent more than its manifest declares — scopes are the ceiling, so the mint refuses instead. ` +
      `Fix: declare at least one mintable scope in agent.toml (${Object.keys(SCOPE_MAP).map((s) => `"${s}"`).join(", ")}).`
    );
  }
  return permissions;
}

// The agent's own name, uppercased, is the secret's name on the runtime box:
// pm → EPITO_APP_ID_PM / EPITO_APP_KEY_PM. One agent, one App key, so the
// daemon can host a roster without any of them sharing a credential.
export const envNames = (name) => {
  const slug = name.toUpperCase().replace(/-/g, "_");
  return { id: `EPITO_APP_ID_${slug}`, key: `EPITO_APP_KEY_${slug}`, installation: `EPITO_INSTALLATION_ID_${slug}` };
};

// Where an agent's credentials come from, in order:
//   1. .epito/principals.json + .epito/keys/<agent>.pem — what `epito deploy`
//      writes on a laptop (architecture.md's on-disk store, 0600)
//   2. the environment — what a runtime box has: systemd hands epitod an
//      EnvironmentFile, so the key arrives as a secret, never as a file we
//      wrote (deploy/provision-host.sh)
// Returns { appId, privateKey, installationId, source } or null when the agent
// has no principal at all — which is not an error everywhere: the resident
// runtime falls back to the pre-identity behaviour and says so.
export function loadPrincipal(name, { env = process.env, dir = "." } = {}) {
  const principalsPath = join(dir, PRINCIPALS_PATH);
  const keyPath = join(dir, KEYS_DIR, `${name}.pem`);
  if (existsSync(principalsPath) && existsSync(keyPath)) {
    let record;
    try {
      const all = JSON.parse(readFileSync(principalsPath, "utf8"));
      record = (Array.isArray(all) ? all : all.principals ?? []).find((p) => p.agent === name);
    } catch (e) {
      throw new Error(`${principalsPath} is not readable JSON (${e.message}) — it is the record of which App is which agent. Fix: repair the file, or delete it and re-run \`epito deploy\`.`);
    }
    if (record) {
      return {
        appId: String(record.externalId ?? record.appId ?? ""),
        privateKey: readFileSync(keyPath, "utf8"),
        installationId: record.installations?.[0]?.installationId ?? null,
        source: principalsPath,
      };
    }
  }

  const n = envNames(name);
  const appId = env[n.id];
  const key = env[n.key];
  if (appId && key) {
    return {
      appId: String(appId),
      // A PEM in an env var arrives with its newlines escaped as often as not.
      privateKey: key.includes("\\n") ? key.replace(/\\n/g, "\n") : key,
      installationId: env[n.installation] ?? null,
      source: `$${n.id}/$${n.key}`,
    };
  }
  return null;
}

// The error every command shows when an agent has no principal yet. One
// message, so `epito token` and `epito run` never disagree about the fix.
export function noPrincipalMessage(name) {
  const n = envNames(name);
  return `"${name}" has no identity to mint from: no principal in ${PRINCIPALS_PATH} with a key at ${KEYS_DIR}/${name}.pem, and no $${n.id} + $${n.key} in the environment. ` +
    `Fix: put the agent's GitHub App id and private key on this machine under those two names (0600, or a systemd EnvironmentFile), or run \`epito deploy\` once the mint lands to create them.`;
}

const b64url = (buf) => Buffer.from(buf).toString("base64").replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");

// A GitHub App JWT: RS256, iss = App id, <=10 minutes, backdated 60s because
// GitHub rejects a token whose iat is ahead of its clock.
export function appJwt(appId, privateKeyPem, now = Math.floor(Date.now() / 1000)) {
  let key;
  try { key = createPrivateKey(privateKeyPem); }
  catch (e) {
    throw new Error(`the private key for this agent is not a readable PEM (${e.message}) — GitHub hands you a PKCS#1 "BEGIN RSA PRIVATE KEY" file when you create the App. Fix: store that file's exact contents, newlines included.`);
  }
  if (key.asymmetricKeyType !== "rsa") {
    throw new Error(`the private key for this agent is ${key.asymmetricKeyType}, and a GitHub App signs with RSA. Fix: use the .pem GitHub generated for the App, not another key.`);
  }
  const header = b64url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const payload = b64url(JSON.stringify({ iat: now - 60, exp: now + 540, iss: appId }));
  const signer = createSign("RSA-SHA256");
  signer.update(`${header}.${payload}`);
  return `${header}.${payload}.${b64url(signer.sign(key))}`;
}

async function gh(path, { method = "GET", jwt, body } = {}) {
  const url = `${GITHUB_API}${path}`;
  let res;
  try {
    res = await fetch(url, {
      method,
      headers: {
        authorization: `Bearer ${jwt}`,
        accept: "application/vnd.github+json",
        "x-github-api-version": "2022-11-28",
        "user-agent": "epito",
        ...(body ? { "content-type": "application/json" } : {}),
      },
      body: body ? JSON.stringify(body) : undefined,
    });
  } catch (e) {
    throw new Error(`could not reach GitHub at ${url} (${e.message}). Fix: check this machine's network, or set $EPITO_GITHUB_API if you are on GitHub Enterprise.`);
  }
  const text = await res.text();
  let json = null;
  try { json = text ? JSON.parse(text) : null; } catch {}
  if (!res.ok) {
    const detail = json?.message ? `: ${json.message}` : text ? `: ${text.slice(0, 200)}` : "";
    const err = new Error(`GitHub refused ${method} ${path} with ${res.status}${detail}`);
    err.status = res.status;
    err.githubMessage = json?.message ?? null;
    throw err;
  }
  return json;
}

// Which installation of this App covers the manifest's repo. Skipped when the
// principal already records one (a deploy that installed it knows the id).
export async function installationFor(jwt, repo) {
  try {
    const inst = await gh(`/repos/${repo}/installation`, { jwt });
    return String(inst.id);
  } catch (e) {
    if (e.status === 404) {
      throw new Error(`this agent's GitHub App is not installed on ${repo} — an App with no installation there can mint nothing, however valid its key. Fix: install the App on ${repo} (its owner does this once), then mint again.`);
    }
    if (e.status === 401) {
      throw new Error(`GitHub rejected this agent's App credentials (401). Either the App id and the private key are not from the same App, or the key has been revoked. Fix: re-copy both from the App's settings page.`);
    }
    throw e;
  }
}

// Mint. Returns { token, expiresAt, permissions, repo, installationId } and
// never persists any of it: the credential is in-memory only
// (architecture.md's data model says so, and rule 1 is why).
export async function mintToken({ name, scopes, repo, principal, log }) {
  const permissions = permissionsFor(scopes);
  const jwt = appJwt(principal.appId, principal.privateKey);
  const installationId = principal.installationId ?? (await installationFor(jwt, repo));
  const [, repoName] = repo.split("/");

  let res;
  try {
    res = await gh(`/app/installations/${installationId}/access_tokens`, {
      method: "POST",
      jwt,
      // Scoped twice: to the manifest's permissions, and to the one repo the
      // run happens in. A token that outlives its blast radius is the thing
      // this product exists to delete.
      body: { permissions, repositories: [repoName] },
    });
  } catch (e) {
    if (e.status === 422) {
      throw new Error(`GitHub refused the permissions this manifest asks for (422${e.githubMessage ? `: ${e.githubMessage}` : ""}). An installation can only hand out permissions the App was granted. Fix: grant the App ${Object.entries(permissions).map(([k, v]) => `${k}:${v}`).join(", ")} and accept the request on ${repo}.`);
    }
    if (e.status === 404) {
      throw new Error(`installation ${installationId} does not exist for this App, or it cannot see ${repo} (404). Fix: check the installation id, or drop it and let epito discover the installation from the manifest's [runtime].repo.`);
    }
    throw e;
  }
  log?.(`minted for ${name}: installation ${installationId}, ${Object.keys(permissions).length} permission${Object.keys(permissions).length > 1 ? "s" : ""} on ${repo}`);
  return { token: res.token, expiresAt: res.expires_at, permissions, repo, installationId };
}
