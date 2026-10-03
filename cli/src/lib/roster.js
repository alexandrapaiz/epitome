// The roster: every agent.toml under one directory, loaded through the same
// validator `epito validate` applies. Factored out of run.js because three
// callers now need it — `epito run` (to reconcile schedules), `epito ps` (to
// name the seats a schedule belongs to), and the smoke test — and because the
// worker deliberately does NOT: a workflow's input carries its manifest as a
// snapshot, so the worker never reads this directory (law 3 of the design,
// docs/prfaq/epitod-v1-temporal.md).
import { readdirSync, statSync } from "node:fs";
import { join, resolve } from "node:path";
import { loadManifest } from "./manifest.js";
import { parseCron } from "./cron.js";

const SKIP = new Set(["node_modules", ".git", ".epito"]);

export function findManifests(dir, depth = 0, out = []) {
  for (const ent of readdirSync(dir)) {
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
  const paths = findManifests(dir);
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
  for (const p of paths) {
    const { manifest, errors } = loadManifest(p);
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
  if (bad) {
    console.error(`epito: ${bad} of ${paths.length} manifest${paths.length > 1 ? "s" : ""} refused; fix them and start again — a roster runs whole or not at all`);
    process.exit(1);
  }
  return agents;
}
