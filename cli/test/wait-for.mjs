#!/usr/bin/env node
// Test helper: block until .epito/audit.jsonl says a thing happened, reading
// the same file an operator would. v0's version also consulted
// .epito/state.json; v1 has no state.json, so every condition below is a
// predicate over the audit lines.
//
//   node test/wait-for.mjs runs <agent> <n> [timeoutMs]      n run.end lines
//   node test/wait-for.mjs action <agent> <action> <n> [ms]  n lines of an action
//   node test/wait-for.mjs closed <agent> [timeoutMs]        a window.close line
import { readFileSync, existsSync } from "node:fs";
import { setTimeout as sleep } from "node:timers/promises";

const [what, agent, ...rest] = process.argv.slice(2);

const audit = () => (existsSync(".epito/audit.jsonl")
  ? readFileSync(".epito/audit.jsonl", "utf8").trim().split("\n").filter(Boolean).flatMap((l) => { try { return [JSON.parse(l)]; } catch { return []; } })
  : []);

const count = (pred) => audit().filter(pred).length;

let want, timeoutMs, done, describe;
if (what === "runs") {
  want = Number(rest[0]); timeoutMs = Number(rest[1]) || 60_000;
  done = () => count((e) => e.agent === agent && e.action === "run.end") >= want;
  describe = `${want} run.end line(s) for ${agent}`;
} else if (what === "action") {
  const action = rest[0]; want = Number(rest[1]); timeoutMs = Number(rest[2]) || 60_000;
  done = () => count((e) => e.agent === agent && e.action === action) >= want;
  describe = `${want} ${action} line(s) for ${agent}`;
} else if (what === "closed") {
  timeoutMs = Number(rest[0]) || 60_000;
  done = () => count((e) => e.agent === agent && e.action === "window.close") >= 1;
  describe = `a window.close line for ${agent}`;
} else {
  console.error(`wait-for: unknown condition "${what}" — try runs, action, or closed`);
  process.exit(2);
}

const deadline = Date.now() + timeoutMs;
while (Date.now() < deadline) {
  if (done()) process.exit(0);
  await sleep(200);
}
console.error(`wait-for: timed out after ${timeoutMs}ms waiting for ${describe}`);
process.exit(1);
