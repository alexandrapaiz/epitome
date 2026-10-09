// `epito deploy` — the last stub in the CLI, and the leg the product is named
// for: a manifest becomes a real principal on GitHub that belongs to the agent
// and not to its owner.
//
// What this command does, and what it deliberately does not:
//
//   does      provision the agent's own GitHub App from [identity].scopes,
//             persist (App id, private key) under .epito/, discover the
//             installation on [runtime].repo, record it, audit it, and do all
//             of that idempotently — deploy twice updates one principal
//             (spec rule 4: one manifest, one principal)
//   does not  wire triggers. [trigger].cron and [trigger].webhook are the
//             resident runtime's job (`epito run`), not a GitHub webhook
//             subscription, so the App this creates declares no hook. The
//             deploy pitch's no-gos say so: identity only.
//
// The route (EPI-4, open since the cycle opened, decided here on evidence):
// App-per-agent via GitHub's app-manifest flow, not one shared epito App with
// per-agent installations. The manifest flow is what makes the agent a
// nameable principal — its own bot login, its own avatar, its own commit
// attribution — and that is the thing no competitor in the market brief has.
// The cost is one human click per agent, in a browser, on a page we pre-fill.
// Both routes still reduce to (app id, key, installation id), which is why
// nothing in lib/identity.js had to change for this command to exist.
//
// The click is not a limitation we failed to remove: GitHub has no API that
// creates an App without a human at a keyboard, by design. What epito removes
// is everything around it — the 14-field form, the permission guesswork, the
// key file that ends up in Downloads, the "which App was this again" a month
// later.
import { createServer } from "node:http";
import { randomBytes, timingSafeEqual, createPrivateKey } from "node:crypto";
import { writeFileSync, readFileSync, existsSync, mkdirSync, chmodSync } from "node:fs";
import { join, resolve } from "node:path";
import { spawn } from "node:child_process";
import { loadManifest } from "./lib/manifest.js";
import { findManifests } from "./lib/roster.js";
import {
  permissionsFor, loadPrincipal, appJwt, installationFor,
  GITHUB_API, KEYS_DIR, PRINCIPALS_PATH, envNames,
} from "./lib/identity.js";
import { appendAudit, ensureDir } from "./lib/audit.js";
import { ignore } from "./lib/gitignore.js";
import { unknownOption } from "./lib/flags.js";

const die = (msg) => { console.error(`epito: ${msg}`); process.exit(1); };

// github.com is where a human creates an App; api.github.com is where the
// callback code is exchanged. Two hosts, two overrides — GitHub Enterprise
// splits them the same way, and the smoke test stands in for both.
export const GITHUB_WEB = process.env.EPITO_GITHUB_WEB || "https://github.com";

// GitHub App names are globally unique across all of GitHub and capped at 34
// characters, so "pm" is taken and always will be. The convention is the
// agent's name plus the owner of the repository it works in — deterministic,
// readable in a PR author line, and derived from the manifest rather than
// invented. Not a namespace system (the deploy pitch's rabbit hole): one
// suffix, overridable with --app-name when it collides anyway.
export function appNameFor(agentName, repo) {
  const owner = (repo ?? "").split("/")[0] ?? "";
  const joined = owner ? `${agentName}-${owner}` : agentName;
  return joined.slice(0, 34);
}

// The JSON GitHub's app-manifest flow takes. Every field is derived from the
// manifest, which is the point: the permission set a human would otherwise
// pick from a 40-checkbox form is `[identity].scopes` mapped by the same
// SCOPE_MAP every mint uses, so the App cannot be created wider than the file.
export function appManifestFor({ name, repo, permissions, redirectUrl, appName, isPublic = false }) {
  return {
    name: appName ?? appNameFor(name, repo),
    url: repo ? `https://github.com/${repo}` : "https://epito.me",
    // One-shot, on loopback, and only valid while this command is waiting.
    redirect_url: redirectUrl,
    // A seat's App is private to the account that owns it unless its repo
    // lives somewhere else (--public). Narrower by default.
    public: isPublic,
    // No webhook: this App is an identity, not a subscription. Triggers are
    // the runtime's (`epito run`), and an App that declares a hook URL it
    // cannot serve is a dead endpoint in somebody's settings page forever.
    default_events: [],
    default_permissions: permissions,
  };
}

const escapeHtml = (s) => s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");

// The page the operator's browser lands on. It exists because GitHub's flow
// takes the manifest as a form POST, not as a query string — a URL alone
// cannot carry it. So epito serves one page whose only job is to submit.
export function formPage({ manifest, state, org }) {
  const action = org
    ? `${GITHUB_WEB}/organizations/${encodeURIComponent(org)}/settings/apps/new?state=${encodeURIComponent(state)}`
    : `${GITHUB_WEB}/settings/apps/new?state=${encodeURIComponent(state)}`;
  return `<!doctype html>
<html><head><meta charset="utf-8"><title>epito: create ${escapeHtml(manifest.name)}</title></head>
<body style="font:16px/1.5 system-ui;margin:4rem auto;max-width:34rem">
<h1>${escapeHtml(manifest.name)}</h1>
<p>epito is handing GitHub this agent's App, pre-filled from its manifest. You
click <b>Create GitHub App</b>; nothing exists until you do.</p>
<form id="f" action="${escapeHtml(action)}" method="post">
  <input type="hidden" name="manifest" value="${escapeHtml(JSON.stringify(manifest))}">
  <button type="submit">Continue to GitHub</button>
</form>
<pre style="background:#f6f8fa;padding:1rem;overflow:auto">${escapeHtml(JSON.stringify(manifest, null, 2))}</pre>
<script>document.getElementById("f").submit()</script>
</body></html>
`;
}

// Exchange the one-hour code GitHub sends back for the App's credentials.
// Unauthenticated by design: possession of the code IS the authentication,
// which is why the code never leaves this process and the listener dies with
// the first valid callback.
async function convert(code) {
  const url = `${GITHUB_API}/app-manifests/${encodeURIComponent(code)}/conversions`;
  let res;
  try {
    res = await fetch(url, {
      method: "POST",
      headers: { accept: "application/vnd.github+json", "x-github-api-version": "2022-11-28", "user-agent": "epito" },
    });
  } catch (e) {
    throw new Error(`could not reach GitHub at ${url} (${e.message}) to exchange the code the browser just returned. The code is good for one hour. Fix: check this machine's network and run \`epito deploy\` again.`);
  }
  const text = await res.text();
  let json = null;
  try { json = text ? JSON.parse(text) : null; } catch {}
  if (!res.ok) {
    throw new Error(`GitHub refused to convert the App-creation code (${res.status}${json?.message ? `: ${json.message}` : ""}). A code is single-use and expires in an hour. Fix: run \`epito deploy\` again and click Create once.`);
  }
  if (!json?.id || !json?.pem) {
    throw new Error(`GitHub converted the code but described the App without ${!json?.id ? "an id" : "a private key"}, and the agent's identity is both. Fix: delete the half-created App in your GitHub settings and run \`epito deploy\` again.`);
  }
  return json;
}

// --- the on-disk store -----------------------------------------------------
// .epito/ is read from the process's working directory, exactly as `epito
// token` and the audit log read it: one store per machine, not one per
// manifest. A deploy run from somewhere else would write a principal `epito
// token` could not find.

export function readPrincipals(dir = ".") {
  const path = join(dir, PRINCIPALS_PATH);
  if (!existsSync(path)) return [];
  let parsed;
  try { parsed = JSON.parse(readFileSync(path, "utf8")); }
  catch (e) {
    die(`${path} is not readable JSON (${e.message}) — it is the record of which App is which agent, and deploy will not overwrite a file it cannot read. Fix: repair the file, or move it aside and deploy again.`);
  }
  return Array.isArray(parsed) ? parsed : parsed.principals ?? [];
}

export function writePrincipals(records, dir = ".") {
  ensureDir();
  writeFileSync(join(dir, PRINCIPALS_PATH), JSON.stringify({ principals: records }, null, 2) + "\n");
}

// The installation for the manifest's repo goes first in the list, because
// `lib/identity.js` reads `installations[0]` when a mint does not discover one
// itself: an agent installed on two repositories must mint for the one its
// manifest names.
export function recordInstallation(record, repo, installationId) {
  const rest = (record.installations ?? []).filter((i) => i.repo !== repo);
  record.installations = [{ repo, installationId: String(installationId) }, ...rest];
  return record;
}

function writeKey(name, pem, dir = ".") {
  try { createPrivateKey(pem); }
  catch (e) {
    die(`GitHub returned a private key this machine cannot read as a PEM (${e.message}), so the App exists but has no usable key here. Fix: generate a new private key on the App's settings page and save it as ${join(KEYS_DIR, `${name}.pem`)} (0600).`);
  }
  const keysDir = join(dir, KEYS_DIR);
  mkdirSync(keysDir, { recursive: true, mode: 0o700 });
  const path = join(keysDir, `${name}.pem`);
  writeFileSync(path, pem.endsWith("\n") ? pem : pem + "\n", { mode: 0o600 });
  // writeFileSync's mode is ignored when the file already exists, and a key
  // that was once world-readable stays world-readable. Say what we mean.
  chmodSync(path, 0o600);
  return path;
}

// --- picking the agent -----------------------------------------------------

// `epito deploy` with no arguments deploys the one agent here, because the
// common case is a repo with one manifest and asking it to repeat its own name
// is ceremony. With several, it refuses and names them rather than guessing —
// deploying the wrong agent creates a real App under a real account.
export function resolveAgent(nameArg, dirArg = ".") {
  const dir = resolve(dirArg);
  if (!existsSync(dir)) die(`${dir} is not a directory, so there is no manifest there to deploy. Fix: pass the directory the agent's agent.toml lives in, or run this from it.`);
  const paths = findManifests(dir);
  if (paths.length === 0) die(`no agent.toml under ${dir} — deploy provisions a manifest, and there is none here. Fix: run \`epito init <name>\` first, or pass the directory holding the manifest.`);
  const loaded = paths.map((p) => ({ path: p, ...loadManifest(p) }));
  if (nameArg) {
    const found = loaded.filter((l) => l.manifest?.agent?.name === nameArg);
    if (found.length === 0) {
      const names = loaded.map((l) => l.manifest?.agent?.name).filter(Boolean);
      die(`no agent named "${nameArg}" under ${dir}${names.length ? ` — the roster there is: ${names.join(", ")}` : ""}. Fix: deploy one of those, or run this from the directory holding the manifest.`);
    }
    if (found.length > 1) die(`"${nameArg}" is declared by ${found.length} manifests under ${dir} (${found.map((f) => f.path).join(", ")}) — one manifest, one principal. Fix: delete or rename the duplicate.`);
    return found[0];
  }
  if (loaded.length > 1) {
    const names = loaded.map((l) => l.manifest?.agent?.name ?? l.path).join(", ");
    die(`${loaded.length} manifests under ${dir} (${names}) and deploy provisions one agent at a time — one manifest, one principal. Fix: name the one you mean: \`epito deploy <name> ${dirArg}\`.`);
  }
  return loaded[0];
}

// --- the command -----------------------------------------------------------

// Every option deploy takes, in one list, because it is also what refuses the
// ones it does not. `--dry-runn` used to be dropped, and a dropped --dry-run on
// THIS command opens a browser and creates a real GitHub App.
const DEPLOY_OPTIONS = [
  { name: "dry-run", does: "say what it would create, and touch neither the network nor a browser" },
  { name: "org", does: "create the App under an organisation instead of your account", value: true },
  { name: "app-name", does: "override the derived App name when it collides", value: true },
  { name: "port", does: "the loopback port for the callback (0 picks a free one)", value: true },
  { name: "timeout", does: "seconds to wait for GitHub to come back (default 600)", value: true },
  { name: "public", does: "let the App be installed outside your account" },
  { name: "no-open", does: "print the URL instead of opening a browser" },
];

export async function deployCmd(argv = []) {
  const bad = unknownOption("deploy", argv, DEPLOY_OPTIONS);
  if (bad) die(bad);
  const flag = (n) => argv.includes(n);
  const value = (n, fallback) => { const i = argv.indexOf(n); return i === -1 ? fallback : argv[i + 1]; };
  const positional = [];
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === "--port" || a === "--timeout" || a === "--app-name" || a === "--org") { i++; continue; }
    if (a.startsWith("-")) continue;
    positional.push(a);
  }
  const dryRun = flag("--dry-run");
  const org = value("--org", null);
  const timeoutMs = Number(value("--timeout", 600)) * 1000;
  const port = Number(value("--port", 0));
  if (!Number.isFinite(timeoutMs) || timeoutMs <= 0) die(`--timeout takes seconds, got "${value("--timeout")}"`);
  if (!Number.isInteger(port) || port < 0 || port > 65535) die(`--port takes a port number (0 picks a free one), got "${value("--port")}"`);

  const { path, manifest, errors } = resolveAgent(positional[0], positional[1] ?? ".");
  if (errors.length) {
    console.error(`${path}: ${errors.length} problem${errors.length > 1 ? "s" : ""} — an invalid manifest deploys nothing, because the manifest is what the principal is made of\n`);
    for (const e of errors) console.error(`  ✗ ${e}`);
    process.exit(1);
  }
  const name = manifest.agent.name;
  const repo = manifest.runtime.repo;
  if (!repo) die(`[runtime].repo is required to deploy "${name}": an App is installed on a repository, and the manifest is what says which. Fix: add repo = "owner/name" to [runtime] in ${path}.`);

  // The scope map is where a manifest goes wrong, and the wrong time to find
  // that out is after a human has created an App. Fail before the browser.
  let permissions;
  try { permissions = permissionsFor(manifest.identity.scopes); }
  catch (e) { die(e.message); }

  const appName = value("--app-name", appNameFor(name, repo));
  const existing = (() => { try { return loadPrincipal(name); } catch (e) { die(e.message); } })();

  if (dryRun) {
    const shape = appManifestFor({
      name, repo, permissions, appName, isPublic: flag("--public"),
      redirectUrl: `http://127.0.0.1:<port>/callback`,
    });
    console.log(`${name} would deploy from ${path}:`);
    console.log(`  App name:    ${appName}${org ? ` (owned by the ${org} organization)` : ""}`);
    console.log(`  permissions: ${Object.entries(permissions).map(([k, v]) => `${k}:${v}`).join(", ")}`);
    console.log(`  from ${manifest.identity.scopes.join(", ")} in ${path}`);
    console.log(`  installed on ${repo}`);
    console.log(`  key would land in ${join(KEYS_DIR, `${name}.pem`)} (0600), recorded in ${PRINCIPALS_PATH}`);
    console.log(existing
      ? `  "${name}" already has a principal (${existing.source}) — a real deploy would update it, never create a second App (spec rule 4)`
      : `  no principal for "${name}" on this machine yet — a real deploy would create the App`);
    console.log(`\nthe manifest it would hand GitHub:\n${JSON.stringify(shape, null, 2)}`);
    return;
  }

  // Rule 4, enforced here: the same manifest deployed twice updates one
  // principal. A second App would mean two identities answering to one name,
  // and the audit log could no longer say who acted.
  if (existing) return updateExisting({ name, repo, manifest, path, principal: existing, permissions });

  await create({ name, repo, path, manifest, permissions, appName, org, port, timeoutMs, isPublic: flag("--public"), noOpen: flag("--no-open") });
}

// The already-deployed path: no App is created, the installation is
// re-discovered, and the record catches up with reality.
async function updateExisting({ name, repo, manifest, path, principal, permissions }) {
  console.error(`epito: "${name}" already has an App on this machine (${principal.source}) — deploying again updates it, it does not create a second (spec rule 4: one manifest, one principal)`);
  let installationId;
  try {
    installationId = await installationFor(appJwt(principal.appId, principal.privateKey), repo);
  } catch (e) {
    console.error(`epito: ${e.message}`);
    console.error(`epito: the App exists and its key works; only the installation is missing. Install it on ${repo}, then run \`epito deploy\` again.`);
    process.exit(1);
  }
  const records = readPrincipals();
  const record = records.find((r) => r.agent === name);
  if (record) {
    recordInstallation(record, repo, installationId);
    record.permissions = permissions;
    writePrincipals(records);
    console.log(`✓ ${name} is deployed: App ${principal.appId}, installation ${installationId} on ${repo}`);
    console.log(`  ${PRINCIPALS_PATH} updated — ${records.length} principal${records.length > 1 ? "s" : ""} on this machine, still one for "${name}"`);
  } else {
    // The principal came from the environment (a runtime box, where systemd
    // hands epitod the key as a secret). Nothing to write: a record here with
    // no key beside it is a record `epito token` would step straight over.
    const n = envNames(name);
    console.log(`✓ ${name} is deployed: App ${principal.appId}, installation ${installationId} on ${repo}`);
    console.log(`  this machine holds the key in the environment (${principal.source}), not in ${PRINCIPALS_PATH}, so there is nothing to update here.`);
    console.log(`  optional: set $${n.installation}=${installationId} to skip the installation lookup on every mint.`);
  }
  appendAudit({
    agent: name, action: "deploy", provider: "github-app", created: false,
    appId: principal.appId, scopes: manifest.identity.scopes, permissions,
    repo, installation: installationId, source: principal.source,
  });
  console.log(`next: \`epito token ${name}\` mints this agent's credential; \`epito run <dir>\` puts it on the runtime`);
}

// The create path: serve one page, wait for one callback, write two files.
async function create({ name, repo, path, manifest, permissions, appName, org, port, timeoutMs, isPublic, noOpen }) {
  const state = randomBytes(32).toString("hex");
  const server = createServer();
  await new Promise((done, fail) => {
    server.once("error", (e) => fail(new Error(e.code === "EADDRINUSE"
      ? `something is already listening on port ${port}, and deploy needs one port for the browser to come back to. Fix: run without --port to let it pick a free one.`
      : `could not listen on 127.0.0.1:${port} (${e.message})`)));
    server.listen(port, "127.0.0.1", done);
  }).catch((e) => die(e.message));
  const bound = server.address().port;
  const redirectUrl = `http://127.0.0.1:${bound}/callback`;
  const shape = appManifestFor({ name, repo, permissions, appName, redirectUrl, isPublic });
  const page = formPage({ manifest: shape, state, org });

  console.error(`epito: deploying ${name} from ${path}`);
  console.error(`  App name:    ${appName}${org ? ` (owned by the ${org} organization)` : ""}`);
  console.error(`  permissions: ${Object.entries(permissions).map(([k, v]) => `${k}:${v}`).join(", ")}`);
  console.error(`  from ${manifest.identity.scopes.join(", ")} in ${path}`);
  console.error(`\nopen this and click Create — it is pre-filled from the manifest, and nothing exists until you click:\n\n  http://127.0.0.1:${bound}/\n`);
  console.error(`waiting up to ${Math.round(timeoutMs / 1000)}s for GitHub to come back. Ctrl-C stops this and creates nothing.`);
  if (!noOpen && process.stdout.isTTY) openBrowser(`http://127.0.0.1:${bound}/`);

  const code = await new Promise((done) => {
    const timer = setTimeout(() => done(null), timeoutMs);
    server.on("request", (req, res) => {
      const url = new URL(req.url, `http://127.0.0.1:${bound}`);
      if (url.pathname === "/" ) {
        res.writeHead(200, { "content-type": "text/html; charset=utf-8" });
        return res.end(page);
      }
      if (url.pathname !== "/callback") {
        res.writeHead(404, { "content-type": "text/plain; charset=utf-8" });
        return res.end("epito: this listener answers two paths, / and /callback, and only while a deploy is waiting.\n");
      }
      // The state is what makes this callback ours: a browser is a public
      // surface, and a stray GET to a loopback port must not be able to hand
      // this process an App it did not ask for. Mismatch is refused and the
      // deploy keeps waiting for the real one.
      if (!sameState(url.searchParams.get("state"), state)) {
        res.writeHead(403, { "content-type": "text/plain; charset=utf-8" });
        res.end("epito: this callback did not come from the App-creation page this deploy opened (the state does not match), so it was refused. Nothing was created.\n");
        console.error(`epito: refused a callback whose state did not match this deploy's — still waiting for the real one`);
        return;
      }
      const got = url.searchParams.get("code");
      if (!got) {
        res.writeHead(400, { "content-type": "text/plain; charset=utf-8" });
        res.end("epito: GitHub came back without a code, so there is nothing to exchange. Close this tab and run `epito deploy` again.\n");
        console.error(`epito: the callback carried no code — still waiting`);
        return;
      }
      res.writeHead(200, { "content-type": "text/html; charset=utf-8" });
      res.end(`<!doctype html><meta charset="utf-8"><body style="font:16px/1.5 system-ui;margin:4rem auto;max-width:34rem"><h1>${escapeHtml(appName)} exists</h1><p>Its key is on your machine, in <code>.epito/</code>. You can close this tab — the terminal has the rest.</p></body>`);
      clearTimeout(timer);
      done(got);
    });
  });
  server.close();
  if (!code) die(`no callback arrived within the time allowed, so nothing was created. Fix: run \`epito deploy\` again and click Create on the page it opens (\`--timeout <seconds>\` if you need longer).`);

  let app;
  try { app = await convert(code); }
  catch (e) { die(e.message); }

  const keyPath = writeKey(name, app.pem);
  const records = readPrincipals();
  const record = {
    agent: name,
    provider: "github-app",
    externalId: String(app.id),
    slug: app.slug ?? null,
    htmlUrl: app.html_url ?? null,
    permissions,
    installations: [],
    createdAt: new Date().toISOString(),
  };
  writePrincipals([...records.filter((r) => r.agent !== name), record]);
  // A private key just landed in this directory. Rule 1 says the manifest is
  // publishable; .epito/ is the half that is not, and a repo that arrived here
  // without `epito init` has never been told.
  if (ignore(".epito/")) console.error(`epito: added .epito/ to .gitignore — the App key lives there and is never committed`);

  console.log(`✓ ${name} exists on GitHub as ${app.slug ? `@${app.slug}[bot]` : `App ${app.id}`}`);
  console.log(`  key    ${keyPath} (0600, gitignored — this is the agent's identity, treat it as one)`);
  console.log(`  record ${PRINCIPALS_PATH} (App id ${app.id}, no secret in it)`);
  console.log(`  scopes ${manifest.identity.scopes.join(", ")} → ${Object.entries(permissions).map(([k, v]) => `${k}:${v}`).join(", ")}`);

  // The App exists; it is installed nowhere. That is the second click, and
  // GitHub has no API for it either.
  let installationId = null;
  try { installationId = await installationFor(appJwt(String(app.id), app.pem), repo); }
  catch { /* the expected case on a fresh App: not installed yet */ }
  if (installationId) {
    const all = readPrincipals();
    recordInstallation(all.find((r) => r.agent === name), repo, installationId);
    writePrincipals(all);
    console.log(`  installed on ${repo} (installation ${installationId})`);
  }
  appendAudit({
    agent: name, action: "deploy", provider: "github-app", created: true,
    appId: String(app.id), slug: app.slug ?? null, scopes: manifest.identity.scopes,
    permissions, repo, installation: installationId,
  });

  if (installationId) {
    console.log(`next: \`epito token ${name}\` mints this agent's credential; \`epito run <dir>\` puts it on the runtime`);
  } else {
    const install = app.html_url ? `${app.html_url}/installations/new` : `https://github.com/settings/apps/${app.slug ?? ""}/installations`;
    console.log(`\n${name} has an identity but nowhere to act yet: an App mints nothing until it is installed on the repository it works in.`);
    console.log(`  install it on ${repo}:  ${install}`);
    console.log(`  then: \`epito deploy ${name}\` again — it will not create a second App, it will record the installation.`);
  }
}

function sameState(got, want) {
  if (typeof got !== "string") return false;
  const a = Buffer.from(got), b = Buffer.from(want);
  return a.length === b.length && timingSafeEqual(a, b);
}

// Best effort, and never fatal: the URL is on stdout either way, and a box with
// no browser (a server over ssh, which is where half of these will run) is a
// normal place to deploy from.
function openBrowser(url) {
  const cmd = process.platform === "darwin" ? "open" : process.platform === "win32" ? "start" : "xdg-open";
  try { spawn(cmd, [url], { stdio: "ignore", detached: true }).unref(); } catch { /* the URL is printed */ }
}
