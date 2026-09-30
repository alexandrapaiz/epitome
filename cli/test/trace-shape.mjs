#!/usr/bin/env node
// Test helper: assert the shape of one run's trace, and print it as a tree.
//
//   node test/trace-shape.mjs <spans.jsonl> <agent> [--minted] [--agent-spans N]
//
// It finds the run the way an operator would — the newest run.end line for that
// agent in .epito/audit.jsonl — and then asserts the spans a trace backend
// received against the ids DERIVED from that run id (src/lib/trace.js). That is
// the property worth testing: three activity invocations that share no memory
// file into one trace because the ids are a function of the run.
import { readFileSync } from "node:fs";
import { traceIdFor, spanIdFor } from "../src/lib/trace.js";

const [file, agent, ...flags] = process.argv.slice(2);
const want = (f) => flags.includes(f);
const agentSpansWanted = Number(flags[flags.indexOf("--agent-spans") + 1] ?? 0);

const lines = (p) => readFileSync(p, "utf8").trim().split("\n").filter(Boolean).flatMap((l) => { try { return [JSON.parse(l)]; } catch { return []; } });

const audit = lines(".epito/audit.jsonl");
const end = audit.filter((e) => e.agent === agent && e.action === "run.end").pop();
if (!end?.runId) { console.error(`trace-shape: no run.end line for ${agent} in .epito/audit.jsonl`); process.exit(1); }

const traceId = traceIdFor(end.runId);
const spans = lines(file).filter((s) => s.traceId === traceId);
const problems = [];
const find = (phase) => spans.find((s) => s.spanId === spanIdFor(end.runId, phase));

const root = find("run");
if (!root) problems.push(`no root span for ${end.runId} (trace ${traceId})`);
else {
  if (root.name !== `run ${agent}`) problems.push(`the root span is named "${root.name}", not "run ${agent}"`);
  if (root.parent) problems.push(`the root span has a parent (${root.parent}); a run is the top of its own trace`);
}
for (const phase of ["clone", "execute"]) {
  const s = find(phase);
  if (!s) { problems.push(`no ${phase} span`); continue; }
  if (s.parent !== spanIdFor(end.runId, "run")) problems.push(`the ${phase} span hangs off ${s.parent}, not the run`);
}
if (want("--minted")) {
  for (const phase of ["mint-clone", "mint-run"]) {
    const s = find(phase);
    if (!s) { problems.push(`no ${phase} span — this seat has an App, so both halves of the run minted`); continue; }
    if (s.name !== "mint") problems.push(`${phase} is named "${s.name}"`);
    if (!s.attrs?.["epito.installation"]) problems.push(`the ${phase} span does not say which installation it minted from`);
    if (!s.attrs?.["epito.token_expires_at"]) problems.push(`the ${phase} span does not say when the credential dies`);
  }
}
// The agent's OWN spans: whatever it emitted under `execute`, which for a
// langgraph seat is its graph and one span per node. epito did not make these;
// it only handed the child a TRACEPARENT.
const executeId = spanIdFor(end.runId, "execute");
const ours = new Set(["run", "clone", "execute", "mint-clone", "mint-run"].map((p) => spanIdFor(end.runId, p)));
const theirs = spans.filter((s) => !ours.has(s.spanId));
if (agentSpansWanted && theirs.length < agentSpansWanted) {
  problems.push(`the agent filed ${theirs.length} span(s) of its own, wanted at least ${agentSpansWanted}`);
}
const orphan = theirs.find((s) => !spans.some((p) => p.spanId === s.parent) && s.parent !== executeId);
if (orphan) problems.push(`"${orphan.name}" hangs off ${orphan.parent}, which is nothing in this trace`);

// The tree, printed for the transcript: this is the thing a reader wants to see.
const byParent = new Map();
for (const s of spans) byParent.set(s.parent ?? "root", [...(byParent.get(s.parent ?? "root") ?? []), s]);
const ms = (s) => Math.max(0, Math.round((Number(BigInt(s.endNs) - BigInt(s.startNs))) / 1e6));
const show = (parent, depth) => {
  for (const s of (byParent.get(parent) ?? []).sort((a, b) => Number(BigInt(a.startNs) - BigInt(b.startNs)))) {
    const attrs = Object.entries(s.attrs ?? {}).filter(([k]) => /outcome|adapter|turns|installation|graph|node|repo|bot/.test(k))
      .map(([k, v]) => `${k.replace("epito.", "")}=${v}`).join(" ");
    console.log(`${"  ".repeat(depth)}${depth ? "└ " : ""}${s.name}  ${ms(s)}ms  ${s.status === 2 ? "ERROR " : ""}${attrs}`);
    show(s.spanId, depth + 1);
  }
};
console.log(`    trace ${traceId}  (${spans.length} spans, run ${end.runId})`);
show("root", 1);
if (problems.length) { for (const p of problems) console.error(`trace-shape: ${p}`); process.exit(1); }
