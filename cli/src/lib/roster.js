// The roster: every agent.toml under one directory, loaded through the same
// validator `epito validate` applies. Factored out of run.js because three
// callers now need it — `epito run` (to reconcile schedules), `epito ps` (to
// name the seats a schedule belongs to), and the smoke test — and because the
// worker deliberately does NOT: a workflow's input carries its manifest as a
// snapshot, so the worker never reads this directory (law 3 of the design,
// docs/prfaq/epitod-v1-temporal.md).
import { readdirSync, statSync, existsSync } from "node:fs";
import { join, resolve } from "node:path";
import { loadManifest } from "./manifest.js";
import { parseCron } from "./cron.js";

const SKIP = new Set(["node_modules", ".git", ".epito"]);

// Why this reads the directory through a try. Every command that takes a
// roster path reaches it here — `epito run`, `epito ps`, `epito routes`,
// `epito env`, `epito doctor` — and a path that is not a readable directory
// came back as ten lines of Node: `node:fs:1590 / const result =
// binding.readdir` and a stack through our own files. A typo'd roster path and
// a /srv the runtime user cannot read are both ordinary operating conditions
// on exactly the box this is run on, and `epito validate <dir>` has always
// answered the first one with a sentence. The error-message bar is the
// product's, not one command's: name the rule, in the product's words, with
// the fix in the message.
export function findManifests(dir, depth = 0, out = []) {
  let entries;
  try { entries = readdirSync(dir); }
  catch (e) {
    const err = new Error(e.code === "EACCES" || e.code === "EPERM"
      ? `${dir} cannot be read by this user, so the seats under it cannot be found. Fix: run as the user that owns the roster, or \`chmod +rx ${dir}\` — on a runtime host the roster is read by the service user, not by you`
      : `${dir} cannot be read: ${e.message}`);
    err.epitoHandled = true;
    throw err;
  }
  for (const ent of entries) {
    if (SKIP.has(ent)) continue;
    const p = join(dir, ent);
    const st = statSync(p);
    if (st.isDirectory() && depth < 4) findManifests(p, depth + 1, out);
    else if (ent === "agent.toml") out.push(p);
  }
  return out;
}

// The rules a ROSTER adds to the ones every single manifest must already pass.
// No one manifest can break either of them: both are about the set.
//
// Two commands apply them and they apply them at different severities, which is
// the whole reason this is a function and not two copies. `epito run` refuses —
// it is about to register schedules against the engine. `epito validate <dir>`
// refuses the duplicate name (spec rule 4 is a rule about the file) but reports
// the missing repo as a readiness note, because spec v0.1 blesses a manifest
// without `[runtime].repo` and a validator that refused one would refuse every
// Actions-era file on purpose (src/lib/readiness.js says this at length).
//
// So the rule SET cannot drift between the two commands — only the severity,
// deliberately. ROSTER_RULES is the enumeration both the note text and
// cli/test/unit.mjs ("`validate --for-runtime` refuses every roster rule `epito
// run` refuses") read, so a third rule arriving here cannot quietly be a rule
// `epito validate --for-runtime` does not know about.
export const ROSTER_RULES = ["repo", "name"];

export function rosterRules(manifest, { path, takenBy = new Map() } = {}) {
  const out = [];
  if (manifest?.runtime && !manifest.runtime.repo) {
    out.push({ rule: "repo", message: "[runtime].repo is required by `epito run`: the runtime clones owner/name fresh for every run, so it must know which repository the charter lives in" });
  }
  const name = manifest?.agent?.name;
  if (name && takenBy.has(name)) {
    out.push({ rule: "name", message: `[agent].name "${name}" is already used by ${takenBy.get(name)} — one manifest, one principal (spec rule 4): identity follows the name, so two files with one name are two seats asking for one principal` });
  }
  return out;
}

// Load the roster or exit(1) with every problem named, in the validator's
// voice. Returns Map<name, { path, manifest, cron }> where `cron` is the
// parsed matcher (null for a presence-only seat) — parsed here so a bad
// expression fails the command before anything is registered on the engine.
export function loadRoster(dirArg) {
  const dir = resolve(dirArg);
  // A path that is not a directory, said in one line rather than in a stack.
  // The two cases get different fixes because they are different mistakes: a
  // path that is not there is usually a typo, and a path that is a FILE is
  // usually somebody reaching for the one command that takes one.
  if (!existsSync(dir)) {
    console.error(`epito: no such directory "${dirArg}" — a roster is a directory of seats, each with its own agent.toml. Fix: name the directory that holds them — in this repository that is \`agents\` — or \`epito init <name>\` inside a new one`);
    process.exit(1);
  }
  if (!statSync(dir).isDirectory()) {
    console.error(`epito: "${dirArg}" is a file, and this command reads a ROSTER — the directory the seats live in, one agent.toml each. Fix: name that directory, or \`epito validate ${dirArg}\`, which is the command that checks a single manifest`);
    process.exit(1);
  }
  let paths;
  try { paths = findManifests(dir); }
  catch (e) {
    if (!e?.epitoHandled) throw e;
    console.error(`epito: ${e.message}`);
    process.exit(1);
  }
  if (paths.length === 0) {
    console.error(`epito: no agent.toml found under ${dir} — an empty roster has nothing to run`);
    process.exit(1);
  }
  const agents = new Map();
  // name -> the path that claimed it, for the duplicate-name rule. Only clean
  // manifests claim a name, so a second copy of an already-refused file is
  // reported on its own problems rather than as a collision with a non-seat.
  const takenBy = new Map();
  let bad = 0;
  // Keys the spec does not define, in the two tables where they are a warning
  // (spec v0.2). Printed by the command that is about to START the roster,
  // because this is the last moment anybody is looking: `epito run` reads the
  // directory once at startup and then nothing reads these files again until a
  // restart, so a key dropped here unsaid is a key nobody hears about until
  // whatever hour that restart happens. Collected and said once, after the
  // loop, so a forty-seat roster does not interleave them with its refusals.
  const warned = [];
  for (const p of paths) {
    const { manifest, errors, warnings } = loadManifest(p);
    if (warnings.length) warned.push({ path: p, warnings });
    const errs = [...errors, ...rosterRules(manifest, { path: p, takenBy }).map((r) => r.message)];
    if (errs.length) {
      bad++;
      console.error(`${p}: ${errs.length} problem${errs.length > 1 ? "s" : ""}\n`);
      for (const e of errs) console.error(`  ✗ ${e}`);
      console.error("");
      continue;
    }
    agents.set(manifest.agent.name, { path: p, manifest, cron: manifest.trigger.cron ? parseCron(manifest.trigger.cron) : null });
    takenBy.set(manifest.agent.name, p);
  }
  // Before the refusal verdict, so the one report an operator gets carries
  // both. These never add to `bad`: a warning is not a refusal, and nothing
  // here may change which rosters this function starts.
  for (const { path, warnings } of warned) {
    for (const w of warnings) console.error(`${path}: ⚠ ${w}`);
  }
  if (warned.length) {
    const keys = warned.reduce((t, x) => t + x.warnings.length, 0);
    console.error(`epito: ${keys} key${keys === 1 ? "" : "s"} in ${warned.length} manifest${warned.length === 1 ? "" : "s"} ${keys === 1 ? "is" : "are"} not in the manifest spec and ${keys === 1 ? "is" : "are"} read by nothing; the roster runs anyway — the ⚠ lines say which, and \`epito validate\` says the same thing without starting anything\n`);
  }
  if (bad) {
    console.error(`epito: ${bad} of ${paths.length} manifest${paths.length > 1 ? "s" : ""} refused; fix them and start again — a roster runs whole or not at all`);
    process.exit(1);
  }
  return agents;
}
