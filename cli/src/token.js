// `epito token <name>` — the agent's credential, on demand.
//
// The mint the resident runtime does for itself before every run, exposed as
// a command so an operator can prove the principal works before trusting a
// schedule to it. Two rules shape the output:
//   - the token goes to stdout ALONE, so `GH_TOKEN=$(epito token pm)` is the
//     obvious use and a pipe never swallows a summary;
//   - everything human — what was minted, for which repository, with which
//     permissions, until when — goes to stderr.
// The token is never written to a file. The audit line records the mint
// without it (lib/identity.js, mintAudit).
import { existsSync } from "node:fs";
import { resolve } from "node:path";
import { loadManifest, findManifests } from "./lib/manifest.js";
import { mintToken, mapScopes, readAppCredentials, credentialNames, IdentityError, api } from "./lib/identity.js";
import { appendAudit } from "./lib/audit.js";

const die = (msg) => { console.error(`epito: ${msg}`); process.exit(1); };

// Find one agent by [agent].name in a roster directory, or say what is there.
function findAgent(dir, name) {
  const root = resolve(dir);
  if (!existsSync(root)) die(`no directory ${dir} — \`epito token <name> [dir]\` looks for agent.toml under <dir> (default: here)`);
  const paths = findManifests(root);
  if (!paths.length) die(`no agent.toml under ${dir} — an agent mints a token, and there is no agent here. Run \`epito init\` first.`);
  const roster = [];
  for (const p of paths) {
    const loaded = loadManifest(p);
    const n = loaded.manifest?.agent?.name;
    if (n) roster.push(n);
    if (n === name) return { ...loaded, path: p };
  }
  die(`no agent named "${name}" under ${dir} — this roster is: ${roster.length ? roster.join(", ") : "(no manifest names an agent)"}`);
}

export async function tokenCmd(name, args = []) {
  if (!name || name.startsWith("-")) {
    die(`token needs an agent: \`epito token <name> [dir]\` mints that agent's GitHub token from its [identity].scopes`);
  }
  const dryRun = args.includes("--dry-run");
  const dir = args.find((a) => !a.startsWith("-")) ?? ".";
  const { manifest, errors, path } = findAgent(dir, name);

  if (errors.length) {
    console.error(`${path}: ${errors.length} problem${errors.length > 1 ? "s" : ""} — epito will not mint a token for a manifest it cannot validate\n`);
    for (const e of errors) console.error(`  ✗ ${e}`);
    process.exit(1);
  }

  const scopes = manifest.identity.scopes;
  const names = credentialNames(name);

  // Map before looking for a key. Both are fixable, but an unmappable scope
  // is a manifest bug the operator can fix here and now, and telling them
  // about a missing secret first would send them to the wrong file.
  let permissions;
  try { ({ permissions } = mapScopes(scopes, { agent: name })); }
  catch (e) { if (e instanceof IdentityError) die(e.message); throw e; }

  // --dry-run answers "what would this mint?" with no network and no secret:
  // the scope map is where a manifest most often goes wrong, and finding out
  // at 06:00 from a failed run is the wrong time.
  if (dryRun) {
    let configured = false;
    try { configured = readAppCredentials(name).configured; }
    catch (e) { if (!(e instanceof IdentityError)) throw e; console.error(`epito: ${e.message}\n`); }
    console.error(`${name} would mint against ${manifest.runtime.repo} via ${api()}`);
    for (const [p, level] of Object.entries(permissions)) console.error(`  ${p}: ${level}`);
    console.error(configured
      ? `principal: ${names.id} is set on this box — \`epito token ${name}\` will mint for real`
      : `principal: none on this box yet — set ${names.id} and ${names.key} (or ${names.keyFile}), then run without --dry-run`);
    process.exit(configured ? 0 : 1);
  }

  let result;
  try { result = await mintToken(manifest); }
  catch (e) { if (e instanceof IdentityError) die(e.message); throw e; }

  if (!result.minted) {
    die(`${name} has no GitHub App principal on this box — set ${names.id} to the App's numeric id and ${names.key} to its private key (or ${names.keyFile} to a path holding it), then run again. Until then the runtime falls back to the shared credentials in [runtime].env, and every PR opens as whoever owns that token instead of as ${name}[bot].`);
  }

  appendAudit({ agent: name, action: "token.mint", source: "cli", scopes, repo: result.repo, app: result.appId,
    ...(result.bot ? { as: result.bot.login } : {}), installation: result.installationId,
    permissions: result.permissions, expires: result.expiresAt });

  console.error(`minted for ${result.bot?.login ?? name} on ${result.repo} (app ${result.appId}, installation ${result.installationId})`);
  for (const [p, level] of Object.entries(result.permissions)) console.error(`  ${p}: ${level}`);
  console.error(`expires ${result.expiresAt} — epito mints per run and keeps nothing`);
  console.log(result.token);
}
