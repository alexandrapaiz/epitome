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
  let bad = 0;
  for (const p of paths) {
    const { manifest, errors } = loadManifest(p);
    const errs = [...errors];
    if (manifest?.runtime && !manifest.runtime.repo) errs.push("[runtime].repo is required by `epito run`: the runtime clones owner/name fresh for every run, so it must know which repository the charter lives in");
    if (manifest?.trigger?.cron) { try { parseCron(manifest.trigger.cron); } catch (e) { errs.push(`[trigger].cron: ${e.message}`); } }
    if (manifest?.agent?.name && agents.has(manifest.agent.name)) errs.push(`[agent].name "${manifest.agent.name}" is already used by ${agents.get(manifest.agent.name).path} — one manifest, one principal`);
    if (errs.length) {
      bad++;
      console.error(`${p}: ${errs.length} problem${errs.length > 1 ? "s" : ""}\n`);
      for (const e of errs) console.error(`  ✗ ${e}`);
      console.error("");
      continue;
    }
    agents.set(manifest.agent.name, { path: p, manifest, cron: manifest.trigger.cron ? parseCron(manifest.trigger.cron) : null });
  }
  if (bad) {
    console.error(`epito: ${bad} of ${paths.length} manifest${paths.length > 1 ? "s" : ""} refused; fix them and start again — a roster runs whole or not at all`);
    process.exit(1);
  }
  return agents;
}
