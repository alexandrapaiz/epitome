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
import { loadManifest } from "./lib/manifest.js";
import { findManifests } from "./run.js";
import { loadPrincipal, mintToken, noPrincipalMessage } from "./lib/identity.js";
import { appendAudit } from "./lib/audit.js";

const die = (msg) => { console.error(`epito: ${msg}`); process.exit(1); };

// Find the one manifest named <name>, under <dir> (default: here). The same
// discovery `epito run` uses, so the agent a token is minted for is the same
// agent the daemon would run.
export function findAgent(name, dirArg = ".") {
  const dir = resolve(dirArg);
  const found = [];
  for (const p of findManifests(dir)) {
    const { manifest, errors } = loadManifest(p);
    if (manifest?.agent?.name !== name) continue;
    found.push({ path: p, manifest, errors });
  }
  if (found.length === 0) {
    const names = findManifests(dir).map((p) => loadManifest(p).manifest?.agent?.name).filter(Boolean);
    die(`no agent named "${name}" under ${dir}${names.length ? ` — the roster there is: ${names.join(", ")}` : " — there is no agent.toml there at all"}. Fix: run this from the directory holding the manifests, or pass it: \`epito token ${name} <dir>\``);
  }
  if (found.length > 1) die(`"${name}" is declared by ${found.length} manifests under ${dir} (${found.map((f) => f.path).join(", ")}) — one manifest, one principal. Fix: delete or rename the duplicate.`);
  return found[0];
}

export async function tokenCmd(name, dirArg = ".") {
  if (!name) die("token needs an agent: `epito token <name>` mints a short-lived credential for the agent of that name");

  const { path, manifest, errors } = findAgent(name, dirArg);
  if (errors.length) {
    console.error(`${path}: ${errors.length} problem${errors.length > 1 ? "s" : ""} — an invalid manifest mints nothing, because the manifest is what bounds the token\n`);
    for (const e of errors) console.error(`  ✗ ${e}`);
    process.exit(1);
  }
  const repo = manifest.runtime.repo;
  if (!repo) die(`[runtime].repo is required to mint for "${name}": a token is scoped to one repository, and the manifest is what says which. Fix: add repo = "owner/name" to [runtime] in ${path}.`);

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
    model: manifest.runtime.model ?? null,
    source: principal.source,
  });

  console.error(`epito: minted for ${name} — ${Object.entries(minted.permissions).map(([k, v]) => `${k}:${v}`).join(", ")} on ${minted.repo}, installation ${minted.installationId}, expires ${minted.expiresAt}`);
  process.stdout.write(minted.token + "\n");
}
