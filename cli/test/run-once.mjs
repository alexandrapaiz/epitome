#!/usr/bin/env node
// One run of one agent, without the daemon: the smallest harness that
// exercises lib/runner.js end to end (clone, identity, executor, log).
// Prints the run result as JSON on stdout; the daemon's own logging goes
// to stderr. Used by test/smoke-token.sh to watch a minted token reach a run.
//
//   node test/run-once.mjs <path/to/agent.toml> [trigger]
import { loadManifest } from "../src/lib/manifest.js";
import { runAgent } from "../src/lib/runner.js";

const [path, trigger = "cron"] = process.argv.slice(2);
const { manifest, errors } = loadManifest(path);
if (errors.length) { console.error(errors.join("\n")); process.exit(1); }
const r = await runAgent({
  agent: manifest, trigger,
  executor: process.env.EPITO_EXECUTOR || "claude",
  timeoutMs: Number(process.env.EPITO_RUN_TIMEOUT_MS) || 120_000,
  log: (m) => console.error(m),
});
console.log(JSON.stringify(r));
