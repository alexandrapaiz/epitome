// `epito token <name> [dir]`: the mint, by hand.
//
// It prints ONE thing on stdout — the token — so a script can say
// `GH_TOKEN="$(epito token pm)"`. Everything a human wants (which App, which
// installation, which permissions, when it dies) goes to stderr, and the
// record of the mint goes to .epito/audit.jsonl without the token in it.
//
// The resident runtime calls the same mint internally (lib/runner.js) before
// every run, so this command is the same identity a run gets, in your hand.
import { loadManifest, findManifests } from "./lib/manifest.js";
import { mintToken, appSecretNames, API_BASE } from "./lib/identity.js";
import { appendAudit } from "./lib/audit.js";

const die = (msg) => { console.error(`epito: ${msg}`); process.exit(1); };

export async function tokenCmd(args) {
  const [name, dirArg] = args;
  const dir = dirArg ?? ".";
  if (!name) die("token needs an agent: `epito token <name> [dir]` mints that agent's own short-lived GitHub token");

  let paths;
  try { paths = findManifests(dir); }
  catch (e) { return die(`cannot read ${dir} (${e.code ?? e.message}) — point \`epito token ${name}\` at the directory holding the roster`); }
  if (!paths.length) die(`no agent.toml under ${dir} — \`epito token ${name}\` mints from a manifest; run it where the roster lives, or pass the directory`);

  const found = [];
  for (const p of paths) {
    const m = loadManifest(p);
    if (m.manifest?.agent?.name === name) found.push({ path: p, ...m });
    else if (m.manifest?.agent?.name) found.push({ path: p, other: m.manifest.agent.name });
  }
  const hit = found.find((f) => !f.other);
  if (!hit) {
    const roster = found.map((f) => f.other).filter(Boolean).sort();
    die(`no agent named "${name}" under ${dir}${roster.length ? ` — it holds: ${roster.join(", ")}` : ""}`);
  }
  if (hit.errors.length) {
    console.error(`${hit.path}: ${hit.errors.length} problem${hit.errors.length > 1 ? "s" : ""} — an invalid manifest mints nothing\n`);
    for (const e of hit.errors) console.error(`  ✗ ${e}`);
    process.exit(1);
  }

  const m = hit.manifest;
  const { idVar } = appSecretNames(name);
  let minted;
  try {
    minted = await mintToken({ name, scopes: m.identity.scopes, repo: m.runtime?.repo });
  } catch (e) {
    appendAudit({ agent: name, action: "token.fail", reason: e.message.split("\n")[0].slice(0, 200) });
    return die(e.message);
  }

  const perms = Object.entries(minted.permissions).map(([k, v]) => `${k}:${v}`).sort().join(", ");
  appendAudit({
    agent: name, action: "token.mint", via: "cli",
    repo: m.runtime.repo, scopes: m.identity.scopes, permissions: minted.permissions,
    app: minted.appSlug, app_id: minted.appId, installation: minted.installationId,
    expires_at: minted.expiresAt,
  });
  console.error(`minted for ${name}: ${minted.bot?.login ?? minted.appSlug ?? `app ${minted.appId}`} on ${m.runtime.repo} (${perms}) — expires ${minted.expiresAt ?? "in an hour"}`);
  console.error(`the token is on stdout and nowhere else; ${API_BASE()} issued it from ${idVar}'s App`);
  process.stdout.write(minted.token + "\n");
}
