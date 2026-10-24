// `epito token <name>` — mint one short-lived credential for one agent and
// print it on stdout, so a shell can do:
//
//     GH_TOKEN="$(epito token pm)" gh pr create --draft ...
//
// stdout is the token and nothing else, for exactly that reason; everything a
// human wants to read (which installation, which permissions, when it dies)
// goes to stderr, and the durable record goes to .epito/audit.jsonl. The
// token is never written anywhere: not the audit line, not the log, not a
// cache. Minting again is cheap; leaking once is not.
import { resolve } from "node:path";
import { existsSync, statSync } from "node:fs";
import { loadManifest } from "./lib/manifest.js";
import { findManifests } from "./lib/roster.js";
import { loadPrincipal, mintToken, noPrincipalMessage, permissionsFor } from "./lib/identity.js";
import { appendAudit } from "./lib/audit.js";

const die = (msg) => { console.error(`epito: ${msg}`); process.exit(1); };

// Find the one manifest named <name>, under <dir> (default: here). The same
// discovery `epito run` uses, so the agent a token is minted for is the same
// agent the daemon would run.
export function findAgent(name, dirArg = ".") {
  const dir = resolve(dirArg);
  // Say so in the product's voice: a bad path is the likeliest typo here, and
  // an ENOENT stack trace names no rule and offers no fix.
  if (!existsSync(dir) || !statSync(dir).isDirectory()) {
    die(`${dir} is not a directory, so there is no roster there to mint from — \`epito token <name> [dir]\` searches a directory of manifests. Fix: pass the directory the agent's agent.toml lives in, or run this from it.`);
  }
  const manifests = findManifests(dir);
  const found = [];
  for (const p of manifests) {
    const { manifest, errors, warnings } = loadManifest(p);
    if (manifest?.agent?.name !== name) continue;
    found.push({ path: p, manifest, errors, warnings });
  }
  if (found.length === 0) {
    const names = manifests.map((p) => loadManifest(p).manifest?.agent?.name).filter(Boolean);
    die(`no agent named "${name}" under ${dir}${names.length ? ` — the roster there is: ${names.join(", ")}` : " — there is no agent.toml there at all"}. Fix: run this from the directory holding the manifests, or pass it: \`epito token ${name} <dir>\``);
  }
  if (found.length > 1) die(`"${name}" is declared by ${found.length} manifests under ${dir} (${found.map((f) => f.path).join(", ")}) — one manifest, one principal. Fix: delete or rename the duplicate.`);
  return found[0];
}

export async function tokenCmd(name, dirArg = ".", { dryRun = false } = {}) {
  if (!name) die("token needs an agent: `epito token <name>` mints a short-lived credential for the agent of that name");

  const { path, manifest, errors, warnings } = findAgent(name, dirArg);
  // Said before the refusal check, because a mint reads the manifest to decide
  // what the token may do, and a key nothing reads is worth hearing from the
  // command whose whole output is a credential's bounds. It never changes them.
  for (const w of warnings) console.error(`  ⚠ ${w}`);
  if (errors.length) {
    console.error(`${path}: ${errors.length} problem${errors.length > 1 ? "s" : ""} — an invalid manifest mints nothing, because the manifest is what bounds the token\n`);
    for (const e of errors) console.error(`  ✗ ${e}`);
    process.exit(1);
  }
  const repo = manifest.runtime.repo;
  if (!repo) die(`[runtime].repo is required to mint for "${name}": a token is scoped to one repository, and the manifest is what says which. Fix: add repo = "owner/name" to [runtime] in ${path}.`);

  // What would this mint? Answered without a network call and without
  // touching a key, because the scope map is where a manifest goes wrong and
  // 06:00 on a cron is the wrong time to find that out.
  if (dryRun) {
    let permissions;
    try { permissions = permissionsFor(manifest.identity.scopes); }
    catch (e) { die(e.message); }
    const principal = (() => { try { return loadPrincipal(name); } catch { return null; } })();
    console.log(`${name} would mint on ${repo}:`);
    for (const [k, v] of Object.entries(permissions)) console.log(`  ${k}: ${v}`);
    console.log(`  from ${manifest.identity.scopes.join(", ")} in ${path}`);
    console.log(principal ? `  using the App in ${principal.source}` : `  no App on this machine yet — a real mint would refuse: ${noPrincipalMessage(name)}`);
    return;
  }

  // .epito/ is read from the working directory, the same place audit.jsonl and
  // state.json are written — one store per machine, not one per manifest.
  let principal;
  try { principal = loadPrincipal(name); }
  catch (e) { die(e.message); }
  if (!principal) die(noPrincipalMessage(name));

  let minted;
  try {
    minted = await mintToken({ name, scopes: manifest.identity.scopes, repo, principal });
  } catch (e) { die(e.message); }

  appendAudit({
    agent: name,
    action: "mint",
    provider: "github-app",
    scopes: manifest.identity.scopes,
    permissions: minted.permissions,
    repo: minted.repo,
    installation: minted.installationId,
    expiresAt: minted.expiresAt,
    commit: minted.commit,
    model: manifest.runtime.model ?? null,
    source: principal.source,
  });

  console.error(`epito: minted for ${name} — ${Object.entries(minted.permissions).map(([k, v]) => `${k}:${v}`).join(", ")} on ${minted.repo}, installation ${minted.installationId}, expires ${minted.expiresAt}`);
  // A human scripting `GH_TOKEN="$(epito token pm)" gh pr create` gets a PR
  // that opens as the bot and commits that do not, unless they are told the
  // address that links. So tell them, in the form they would paste.
  if (minted.commit) {
    console.error(`epito: commits authored as this App's bot user — GIT_AUTHOR_NAME="${minted.commit.name}" GIT_AUTHOR_EMAIL="${minted.commit.email}" (same for GIT_COMMITTER_*); \`epito run\` sets these itself`);
  } else {
    console.error(`epito: could not read this App's bot user, so there is no commit address to report — the token is good and the PR will still open as the bot`);
  }
  // Awaited, not fire-and-forget: the caller is `GH_TOKEN="$(epito token pm)"`,
  // so stdout is a pipe, and a pipe write that has not drained when
  // process.exit runs is a token that never arrives.
  await new Promise((done) => process.stdout.write(minted.token + "\n", done));
}
