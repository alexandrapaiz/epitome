#!/usr/bin/env node
// Test helper: block until the daemon has finished N runs for an agent (or
// until a timeout), reading the same .epito/ files an operator would.
//   node test/wait-for.mjs runs <agent> <n> [timeoutMs]
//   node test/wait-for.mjs closed <agent> [timeoutMs]   (window gone)
import { readFileSync, existsSync } from "node:fs";
import { setTimeout as sleep } from "node:timers/promises";

const [what, agent, ...rest] = process.argv.slice(2);
const n = what === "runs" ? Number(rest[0]) : 0;
const timeoutMs = Number(what === "runs" ? rest[1] : rest[0]) || 30_000;

const audit = () => (existsSync(".epito/audit.jsonl") ? readFileSync(".epito/audit.jsonl", "utf8").trim().split("\n").filter(Boolean).map((l) => JSON.parse(l)) : []);
const state = () => (existsSync(".epito/state.json") ? JSON.parse(readFileSync(".epito/state.json", "utf8")) : null);

const deadline = Date.now() + timeoutMs;
while (Date.now() < deadline) {
  if (what === "runs") {
    const done = audit().filter((e) => e.agent === agent && e.action === "run.end").length;
    const idle = state()?.agents?.[agent]?.running === false;
    if (done >= n && idle) process.exit(0);
  } else if (what === "closed") {
    if (state()?.agents?.[agent]?.window == null) process.exit(0);
  } else { console.error(`wait-for: unknown condition "${what}"`); process.exit(2); }
  await sleep(200);
}
console.error(`wait-for: timed out after ${timeoutMs}ms waiting for ${what} ${agent} ${n || ""}`.trim());
process.exit(1);
