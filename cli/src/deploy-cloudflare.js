// `epito deploy --target cloudflare` — the command half of the Cloudflare
// target. The bytes it writes are lib/cfpack.js's, and everything here is
// about the two things a pure generator cannot do: refuse before it writes,
// and tell the operator what is theirs to run.
//
// What it deliberately does NOT do is `wrangler deploy`. Pushing a Worker
// spends somebody's Cloudflare account, and this product's standing rule is
// that a live account is never touched without a card saying so — the GitHub
// target has the same boundary and solves it the same way: epito prepares
// everything and the human performs the one irreversible step.
import { writeFileSync, mkdirSync, readFileSync, existsSync, chmodSync } from "node:fs";
import { createPrivateKey } from "node:crypto";
import { join, relative, resolve } from "node:path";
import {
  cloudflareBundle, cloudflareBlockers, cloudflareNotes, secretNames,
  wranglerConfig, bundleDir, workerName, BINDINGS,
} from "./lib/cfpack.js";
import { loadPrincipal, KEYS_DIR } from "./lib/identity.js";
import { appendAudit } from "./lib/audit.js";
import { ignore } from "./lib/gitignore.js";

const die = (msg) => { console.error(`epito: ${msg}`); process.exit(1); };

// GitHub hands out PKCS#1 ("BEGIN RSA PRIVATE KEY") and WebCrypto imports
// PKCS#8 only, so an agent deployed to the edge needs its own key in the
// other encoding. Converting it is three lines here and an afternoon on
// Stack Overflow for whoever would otherwise have to; it lands beside the
// original, in the directory that is already 0600 and already gitignored, so
// the number of places this company keeps a private key does not change.
export function pkcs8Beside(name, dir = ".") {
  const source = join(dir, KEYS_DIR, `${name}.pem`);
  if (!existsSync(source)) return null;
  const out = join(dir, KEYS_DIR, `${name}.pkcs8.pem`);
  let pem;
  try {
    pem = createPrivateKey(readFileSync(source, "utf8")).export({ type: "pkcs8", format: "pem" });
  } catch (e) {
    die(`${source} is "${name}"'s GitHub App key and this machine cannot read it as a private key (${e.message}), so there is nothing to convert for the Worker. Fix: download a fresh private key from the App's settings page and save it there (0600).`);
  }
  writeFileSync(out, pem, { mode: 0o600 });
  chmodSync(out, 0o600);
  return out;
}

export async function deployCloudflare({ name, path, manifest, outArg, dryRun, compatibilityDate, dir = "." }) {
  const blockers = cloudflareBlockers(manifest, path);
  if (blockers.length) {
    console.error(`${path}: "${name}" cannot be an agent on Cloudflare yet — ${blockers.length} thing${blockers.length > 1 ? "s" : ""} to fix first. Nothing was written.\n`);
    for (const b of blockers) console.error(`  ✗ ${b}\n`);
    process.exit(1);
  }

  const out = resolve(outArg ?? bundleDir(name));
  const shown = relative(process.cwd(), out) || ".";
  // The manifest's path as a reader of the REPOSITORY would write it. The
  // generated files say where they came from, and a generated file is as
  // publishable as the manifest it came from (rule 1) — an absolute path is
  // somebody's home directory, which is a fact about a box and not about an
  // agent.
  const source = relative(process.cwd(), path) || path;
  // Where the Workers-readable copy of the App key is, or will be. Named in
  // the README as a path FROM the bundle, because that is the directory the
  // README tells you to stand in.
  const keySource = join(dir, KEYS_DIR, `${name}.pem`);
  const keyPath = existsSync(keySource) ? relative(out, resolve(join(dir, KEYS_DIR, `${name}.pkcs8.pem`))) : null;

  const files = cloudflareBundle(manifest, { source, keyPath, compatibilityDate });
  const notes = cloudflareNotes(manifest);
  const secrets = secretNames(manifest);
  const config = wranglerConfig(manifest, { compatibilityDate });
  const say = {
    schedule: config.triggers ? `${config.triggers.crons.join(", ")} (UTC), from [trigger].cron` : "none — this manifest declares no [trigger].cron, so it wakes only by hand",
    page: `GET / — the agent, its last run${manifest.trigger?.webhook ? ", and a button that triggers it" : " (no button: no [trigger].webhook)"}`,
  };

  if (dryRun) {
    console.log(`${name} would deploy to Cloudflare from ${source}:`);
    console.log(`  Worker:      ${workerName(name)}`);
    console.log(`  schedule:    ${say.schedule}`);
    console.log(`  state:       one Durable Object (${BINDINGS.doClass}), addressed by the agent's name, so a redeploy keeps its runs`);
    console.log(`  page:        ${say.page}`);
    console.log(`  identity:    its own GitHub App, minting ${manifest.identity.scopes.join(", ")} on ${manifest.runtime.repo} — the Worker signs its own JWT and can ask for nothing wider`);
    console.log(`  would write: ${files.map((f) => join(shown, f.path)).join(", ")}`);
    console.log(`  secrets it would ask you to set (names only, never values): ${secrets.map((s) => s.name).join(", ")}`);
    if (notes.length) {
      console.log(`\nbefore you deploy it:`);
      for (const n of notes) console.log(`  ! ${n}\n`);
    }
    console.log(`\nthe Workers config it would write:\n${JSON.stringify(config, null, 2)}`);
    console.log(`\nnothing was written, nothing was deployed, and no account was touched.`);
    return;
  }

  mkdirSync(out, { recursive: true });
  for (const f of files) writeFileSync(join(out, f.path), f.contents);
  // deploy's own rule, for the same reason the GitHub target has it: this
  // writes under .epito/, and a repository that arrived here without ever
  // running `epito init` has no line for it.
  if (ignore(".epito/")) console.log(`epito: added .epito/ to .gitignore — this is where the agent's keys and its bundle live, and neither is committable.`);

  const key = pkcs8Beside(name, dir);

  appendAudit({
    agent: name, action: "deploy.cloudflare", provider: "cloudflare-worker",
    worker: workerName(name), out: shown, repo: manifest.runtime.repo,
    scopes: manifest.identity.scopes, cron: manifest.trigger?.cron ?? null,
  });

  console.log(`${name} is packed for Cloudflare — ${files.length} files in ${shown}:\n`);
  for (const f of files) console.log(`  ${join(shown, f.path)}`);
  console.log(`\n  Worker:   ${workerName(name)}`);
  console.log(`  schedule: ${say.schedule}`);
  console.log(`  state:    one Durable Object, addressed by "${name}" — a redeploy keeps its runs`);
  console.log(`  page:     ${say.page}`);
  console.log(key
    ? `  key:      ${key} — the PKCS#8 copy of this agent's App key (0600); the Workers runtime reads no other form`
    : `  key:      "${name}" has no App key on this machine yet, so there is none to convert — run \`epito deploy ${name}\` first, or set $EPITO_APP_KEY on the Worker from wherever the key lives`);

  if (notes.length) {
    console.log(`\nbefore you deploy it:`);
    for (const n of notes) console.log(`  ! ${n}\n`);
  }

  console.log(`\nthe part that is yours, not epito's — it spends your Cloudflare account:\n`);
  console.log(`  cd ${shown}`);
  console.log(`  npx wrangler deploy`);
  for (const s of secrets) {
    console.log(s.name === BINDINGS.appKey && keyPath
      ? `  wrangler secret put ${s.name} < ${keyPath}   # ${s.why}`
      : `  wrangler secret put ${s.name}   # ${s.why}`);
  }
  console.log(`\nthen the link to send: https://${workerName(name)}.<your-subdomain>.workers.dev/?key=<${BINDINGS.door}>`);
}
