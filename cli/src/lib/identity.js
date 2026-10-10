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
import { SPEC_VERSION } from "./fields.js";

// A mint failure is either the kind that passes (GitHub throttling, a network
// blip) or the kind that never will (a key that is not a PEM, a scope with no
// mapping, an App installed nowhere). The `clone` activity retries, so it has
// to be able to tell them apart; `execute` never retries, so it does not care.
// Same convention runner.js already uses for a missing charter: `permanent`
// on the error, set only where we are sure.
const permanent = (msg) => Object.assign(new Error(msg), { permanent: true });

export const KEYS_DIR = join(EPITO_DIR, "keys");
export const PRINCIPALS_PATH = join(EPITO_DIR, "principals.json");
export const GITHUB_API = process.env.EPITO_GITHUB_API || "https://api.github.com";

// --- the pages a refusal can point at -------------------------------------
// A link is not an API call, so it does not come off GITHUB_API unchanged:
// api.github.com's pages live at github.com, and a GitHub Enterprise API root
// is that host's web root plus /api/v3, so stripping the suffix is the
// inverse. A box that points $EPITO_GITHUB_API somewhere else gets pages on
// that somewhere else, which is the only answer that is not a lie.
export function webRoot(api = GITHUB_API) {
  try {
    const u = new URL(api);
    if (u.hostname === "api.github.com") return "https://github.com";
    return `${u.origin}${u.pathname.replace(/\/api\/v3\/?$/, "").replace(/\/+$/, "")}`;
  } catch { return "https://github.com"; }
}

// The page that installs an App on a repository, which is the fix behind "this
// agent's GitHub App is not installed on owner/name". Worth printing in a
// refusal, and it is the only link this product prints anywhere: it is a FORM
// — choose the account, choose the repositories, press Install — so following
// it performs nothing, which is what keeps it inside the rule that a printed
// fix is something a person does deliberately and not something a click does.
export const installUrl = (slug, api = GITHUB_API) => `${webRoot(api)}/apps/${slug}/installations/new`;

// And the page that grants an App a permission, which is the fix behind a
// grant short of what [identity].scopes need. An App's settings live under the
// account that OWNS it, and the path differs by owner type: an org-owned App
// is not reachable at /settings/apps/<slug> at all, so this needs the owner
// GET /app answers with and not just the slug.
export function appSettingsUrl({ slug, owner, ownerType }, page = "permissions", api = GITHUB_API) {
  const tail = `apps/${slug}${page ? `/${page}` : ""}`;
  return ownerType === "Organization" && owner
    ? `${webRoot(api)}/organizations/${owner}/settings/${tail}`
    : `${webRoot(api)}/settings/${tail}`;
}

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
    throw permanent(
      `[identity].scopes has ${unmapped.length === 1 ? "a scope" : "scopes"} this deploy target cannot mint: ${unmapped.map((s) => `"${s}"`).join(", ")}. ` +
      `${SPEC_VERSION} maps ${Object.keys(SCOPE_MAP).map((s) => `"${s}"`).join(", ")} to GitHub App permissions and refuses the rest rather than minting a token narrower than the manifest promises. ` +
      `Fix: remove the scope from agent.toml, or open a card to map it.`
    );
  }
  // GitHub reads an omitted-or-empty `permissions` as "everything this
  // installation has" — the exact inverse of rule 2. `epito validate` already
  // refuses an empty [identity].scopes, so this is unreachable through the
  // CLI; it is here because the one place the ceiling is enforced is the one
  // place that must not fail open.
  if (Object.keys(permissions).length === 0) {
    throw permanent(
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
  return {
    id: `EPITO_APP_ID_${slug}`,
    key: `EPITO_APP_KEY_${slug}`,
    // A PEM is multi-line and a systemd EnvironmentFile is not, so the value
    // form has to be escaped by hand. Pointing at the .pem GitHub downloaded
    // is the form an operator can rotate without re-escaping anything.
    keyFile: `EPITO_APP_KEY_FILE_${slug}`,
    installation: `EPITO_INSTALLATION_ID_${slug}`,
  };
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
      throw permanent(`${principalsPath} is not readable JSON (${e.message}) — it is the record of which App is which agent. Fix: repair the file, or delete it and re-run \`epito deploy\`.`);
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
  const keyFile = env[n.keyFile];
  const key = env[n.key];
  if (appId && keyFile) {
    let pem;
    try { pem = readFileSync(keyFile, "utf8"); }
    catch (e) {
      throw permanent(`$${n.keyFile} points at ${keyFile}, which this machine cannot read (${e.code ?? e.message}) — that file is "${name}"'s GitHub App private key, and without it the agent has no identity to mint from. Fix: put the .pem GitHub downloaded there (0600, readable by the user the runtime runs as), or unset $${n.keyFile} and use $${n.key} instead.`);
    }
    return { appId: String(appId), privateKey: pem, installationId: env[n.installation] || null, source: `$${n.id}/$${n.keyFile}` };
  }
  if (appId && key) {
    return {
      appId: String(appId),
      // A PEM in an env var arrives with its newlines escaped as often as not.
      privateKey: key.includes("\\n") ? key.replace(/\\n/g, "\n") : key,
      // `||`, not `??`: an EnvironmentFile line somebody left as
      // `EPITO_INSTALLATION_ID_PM=` holds the empty string, and an empty
      // string here is not an installation — it is an id the mint must
      // discover from [runtime].repo. Read as present it would POST to
      // /app/installations//access_tokens and come back 404, which reads like
      // an App installed nowhere and is not.
      installationId: env[n.installation] || null,
      source: `$${n.id}/$${n.key}`,
    };
  }
  return null;
}

// The error every command shows when an agent has no principal yet. One
// message, so `epito token` and `epito run` never disagree about the fix.
export function noPrincipalMessage(name) {
  const n = envNames(name);
  return `"${name}" has no identity to mint from: no principal in ${PRINCIPALS_PATH} with a key at ${KEYS_DIR}/${name}.pem, and no $${n.id} with either $${n.keyFile} or $${n.key} in the environment. ` +
    `Fix: put the agent's GitHub App id and private key on this machine under those names (the key as a .pem at 0600 named by $${n.keyFile}, or escaped into $${n.key}), or run \`epito deploy\` once the mint lands to create them.`;
}

// The other refusal an agent with an App can hit before a single byte leaves
// this box: a token is scoped to exactly one repository, so there is nothing to
// mint without one. Said here beside the message above because `epito doctor`
// reports it as a preflight and mintForRun throws it as a run — one sentence,
// so the preflight cannot promise a fix the mint does not name.
export function noRepoMessage(name) {
  return `"${name}" has a GitHub App on this box but no [runtime].repo, and a token is scoped to exactly one repository — there is nothing to scope the mint to, so the run refuses rather than minting something broader. Fix: add repo = "owner/name" to [runtime] in this agent's agent.toml.`;
}

const b64url = (buf) => Buffer.from(buf).toString("base64").replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");

// A GitHub App JWT: RS256, iss = App id, <=10 minutes, backdated 60s because
// GitHub rejects a token whose iat is ahead of its clock.
export function appJwt(appId, privateKeyPem, now = Math.floor(Date.now() / 1000)) {
  let key;
  try { key = createPrivateKey(privateKeyPem); }
  catch (e) {
    throw permanent(`the private key for this agent is not a readable PEM (${e.message}) — GitHub hands you a PKCS#1 "BEGIN RSA PRIVATE KEY" file when you create the App. Fix: store that file's exact contents, newlines included.`);
  }
  if (key.asymmetricKeyType !== "rsa") {
    throw permanent(`the private key for this agent is ${key.asymmetricKeyType}, and a GitHub App signs with RSA. Fix: use the .pem GitHub generated for the App, not another key.`);
  }
  const header = b64url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const payload = b64url(JSON.stringify({ iat: now - 60, exp: now + 540, iss: appId }));
  const signer = createSign("RSA-SHA256");
  signer.update(`${header}.${payload}`);
  return `${header}.${payload}.${b64url(signer.sign(key))}`;
}

// `jwt` authenticates as the App (only /app* accepts it); `token` as one
// installation (everything else). Both are Bearer to GitHub; the distinction
// is which endpoints will answer.
async function gh(path, { method = "GET", jwt, token, body } = {}) {
  const url = `${GITHUB_API}${path}`;
  let res;
  try {
    res = await fetch(url, {
      method,
      headers: {
        authorization: `Bearer ${jwt ?? token}`,
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

// Which installation of this App covers the manifest's repo, as GitHub
// describes it: the id, and the permissions the App was actually granted
// there. One function, two readers — the mint (which wants the id) and `epito
// doctor --deep` (which wants to know, before 06:00, whether the mint it is
// about to predict can succeed at all).
//
// The two refusals it names are the only ones in the mint path that are
// PERMANENT at this step, and `permanent` is what the difference is for: the
// `clone` activity retries, so a throttled GitHub and an App installed nowhere
// must not look alike. The status is carried on the error beside the flag so a
// caller that reports rather than throws can tell the two fixes apart in
// --json without re-parsing the sentence.
export async function installationAt(jwt, repo) {
  try {
    return await gh(`/repos/${repo}/installation`, { jwt });
  } catch (e) {
    if (e.status === 404) {
      throw Object.assign(permanent(`this agent's GitHub App is not installed on ${repo} — an App with no installation there can mint nothing, however valid its key. Fix: install the App on ${repo} (its owner does this once), then mint again.`), { status: 404 });
    }
    if (e.status === 401) {
      throw Object.assign(permanent(`GitHub rejected this agent's App credentials (401). Either the App id and the private key are not from the same App, or the key has been revoked. Fix: re-copy both from the App's settings page.`), { status: 401 });
    }
    throw e;
  }
}

// The mint's own half of that: the id alone. Skipped when the principal
// already records one (a deploy that installed it knows the id).
export async function installationFor(jwt, repo) {
  const inst = await installationAt(jwt, repo);
  return String(inst.id);
}

// --- the agent's commit identity ------------------------------------------
// A PR opened with an installation token opens as `<slug>[bot]`. The commits
// inside it do not follow: git takes author and committer from its
// environment, and GitHub links a commit to an account by email alone. The
// address that links is the bot user's own noreply —
//
//     <bot user id>+<slug>[bot]@users.noreply.github.com
//
// — which needs two facts that are in neither the manifest nor the App key:
// the App's slug (GET /app, as the App) and the bot user's numeric id
// (GET /users/<slug>[bot], as the installation; a JWT is not accepted there).
// Neither changes unless the App is renamed, so they are read once per App per
// process — a worker restarts often enough that a rename catches up, and the
// cost of being a day late on an avatar is smaller than two API calls on every
// mint. Without this the commits carry `<name>@agents.epito.me`, an address
// that belongs to nobody and links to nothing.
const botCache = new Map();
const appCache = new Map();

// Who this App IS, as GitHub describes it: one `GET /app` with the App's own
// JWT — no installation token, nothing minted, no ledger line. Two facts come
// back that no manifest holds and nothing offline can derive:
//
//   slug   the App's name, globally unique across GitHub and therefore NOT
//          `[agent].name`: the seat named `pm` may perfectly well be the App
//          `asc-pm`, and then its pull requests open as `asc-pm[bot]`. Every
//          sentence in this repository promising `<name>[bot]` is describing
//          the usual case, and this is the only thing that knows the real one.
//   owner  the account the App belongs to, and its type, which is the only
//          thing that decides where the App's own settings pages live.
//
// Cached by App id, like the bot identity below and for the same reason:
// neither changes unless the App is renamed, and a worker restarts often
// enough for a rename to catch up.
export async function appAs(appId, jwt) {
  if (appCache.has(appId)) return appCache.get(appId);
  const app = await gh("/app", { jwt });
  if (!app?.slug) throw new Error(`GitHub described this App without a slug, and the slug is its name everywhere a person, a login or a URL refers to it`);
  const identity = {
    slug: app.slug,
    login: `${app.slug}[bot]`,
    owner: app.owner?.login ?? null,
    ownerType: app.owner?.type ?? null,
  };
  appCache.set(appId, identity);
  return identity;
}

export async function commitIdentityFor({ appId, jwt, token }) {
  if (botCache.has(appId)) return botCache.get(appId);
  const { login } = await appAs(appId, jwt);
  const user = await gh(`/users/${encodeURIComponent(login)}`, { token });
  if (!user?.id) throw new Error(`GitHub described ${login} without a numeric id, and the id is the half of the address that does the linking`);
  const identity = { name: login, email: `${user.id}+${login}@users.noreply.github.com` };
  botCache.set(appId, identity);
  return identity;
}

// Mint. Returns { token, expiresAt, permissions, repo, installationId, commit } and
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
      throw permanent(`GitHub refused the permissions this manifest asks for (422${e.githubMessage ? `: ${e.githubMessage}` : ""}). An installation can only hand out permissions the App was granted. Fix: grant the App ${Object.entries(permissions).map(([k, v]) => `${k}:${v}`).join(", ")} and accept the request on ${repo}.`);
    }
    if (e.status === 404) {
      throw permanent(`installation ${installationId} does not exist for this App, or it cannot see ${repo} (404). Fix: check the installation id, or drop it and let epito discover the installation from the manifest's [runtime].repo.`);
    }
    throw e;
  }
  log?.(`minted for ${name}: installation ${installationId}, ${Object.keys(permissions).length} permission${Object.keys(permissions).length > 1 ? "s" : ""} on ${repo}`);

  // Deliberately NOT fatal. "No silent fallback" is a rule about acting as the
  // wrong principal, and committing as `<name>@agents.epito.me` is not acting
  // as a human — it is the agent, less legibly. Losing a whole run over an
  // avatar would be the wrong trade, so this degrades loudly instead: the run
  // says so, and the audit line records `commit: null` rather than a guess.
  let commit = null;
  try { commit = await commitIdentityFor({ appId: principal.appId, jwt, token: res.token }); }
  catch (e) {
    log?.(`minted, but could not read this App's bot identity (${e.message}) — the run opens its PR as the bot either way, and its commits fall back to ${name}@agents.epito.me, which GitHub cannot link to the App`);
  }
  return { token: res.token, expiresAt: res.expires_at, permissions, repo, installationId, commit };
}

// One run's identity, as the run path wants it: null when this agent has no
// App of its own (the pre-identity behaviour, unchanged — the seat runs on
// the secrets its manifest names), a minted credential when it has one, and a
// thrown Error in the product's voice when it has one and the mint failed.
// That third case is deliberately not a fallback: an operator who gave an
// agent an App asked for the agent to act as itself, and quietly acting as a
// human instead is the precise thing this product exists to delete.
//
// The return value is split into `token` and `meta` because of law 7
// (docs/prfaq/epitod-v1-temporal.md): Temporal writes every activity argument
// and result to its database in plain text, so `meta` is the half that may be
// returned to a workflow and `token` is the half that may not. Splitting it
// here rather than at the call site is the point — a caller cannot leak the
// secret by spreading the object it was handed.
export async function mintForRun({ name, manifest, dir = ".", env = process.env, log } = {}) {
  const repo = manifest?.runtime?.repo;
  const scopes = manifest?.identity?.scopes ?? [];
  const principal = loadPrincipal(name, { env, dir });
  if (!principal) return null;
  if (!repo) throw permanent(noRepoMessage(name));
  const minted = await mintToken({ name, scopes, repo, principal, log });
  return {
    token: minted.token,
    meta: {
      installation: minted.installationId,
      permissions: minted.permissions,
      repo: minted.repo,
      expiresAt: minted.expiresAt,
      source: principal.source,
      scopes,
      // Safe on the meta side of the split: a bot's login and noreply address
      // are public facts about the App, and the audit line is where "who
      // authored this commit" stops being a guess.
      commit: minted.commit,
    },
  };
}
