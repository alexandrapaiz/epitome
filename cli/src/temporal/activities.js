// The five activities: everything that touches a disk, a process, a network or
// a clock lives here, and nothing else does.
//
// Law 7 of the design (docs/prfaq/epitod-v1-temporal.md): Temporal persists
// every activity argument and result to its database in plain text, so no
// secret VALUE may ever appear in either. What crosses this boundary is the
// manifest, which is publishable by design, and the manifest names the secrets
// the run may see. Their values are read from this worker's own environment,
// here, at the last possible moment.
import { Context, ApplicationFailure } from "@temporalio/activity";
import {
  cloneAgentRepo, executeAgent, killGroup, removeClone, windowInstruction, runLogPath,
} from "../lib/runner.js";
import { postToSlack } from "../lib/slack.js";
import { appendAudit } from "../lib/audit.js";
import { temporalEnv } from "./env.js";

const HEARTBEAT_MIN_MS = 5_000;

// --- clone ----------------------------------------------------------------
// Retried: a clone fails for reasons that pass (a network blip, GitHub
// throttling). A missing charter is not one of them, so that one is thrown
// nonRetryable with the message the operator needs.
export async function clone({ name, manifest, runId }) {
  try {
    const { workDir } = await cloneAgentRepo({ agent: manifest, runId, log: (m) => console.log(m) });
    return { workDir };
  } catch (e) {
    if (e.permanent) throw ApplicationFailure.nonRetryable(e.message, e.stage ?? "clone");
    throw ApplicationFailure.retryable(e.message, e.stage ?? "clone");
  }
}

// --- execute --------------------------------------------------------------
// NOT retried (the workflow declares maximumAttempts: 1). It heartbeats
// whenever the child writes output, so a wedged run is detected by
// heartbeatTimeout rather than waited out to the full run timeout, and it
// kills the child's whole process group if the activity is cancelled.
export async function execute({ name, manifest, runId, workDir, trigger, payload = {}, resume, executor, timeoutMs }) {
  const ctx = Context.current();
  const cfg = temporalEnv();
  let child = null;
  let lastBeat = 0;

  ctx.cancellationSignal.addEventListener("abort", () => killGroup(child), { once: true });

  appendAudit({
    agent: name, action: "run.start", trigger, model: manifest.runtime.model, runId,
    ...(resume ? { resume } : {}), workflow: ctx.info.workflowExecution.workflowId,
  });

  const result = await executeAgent({
    agent: manifest, trigger, runId, workDir, resume,
    hookBody: payload.hookBody, text: payload.text, instruction: payload.instruction,
    executor: executor || cfg.executor,
    timeoutMs: timeoutMs ?? cfg.runTimeoutMs,
    log: (m) => console.log(m),
    onSpawn: (c) => { child = c; },
    onOutput: () => {
      const now = Date.now();
      if (now - lastBeat < HEARTBEAT_MIN_MS) return;
      lastBeat = now;
      try { ctx.heartbeat({ runId, workDir }); } catch {}
    },
  });

  if (ctx.cancellationSignal.aborted) {
    throw ApplicationFailure.nonRetryable(`${name}: the run was cancelled; the executor's process group was killed`, "cancelled");
  }
  return result;
}

// --- record ---------------------------------------------------------------
// The product's own ledger, append-only, in the product's vocabulary. Written
// by an activity so a workflow that is retried or replayed does not rewrite
// history: `runId` is on every line, so a duplicate is identifiable rather
// than invisible. Never throws a retryable error for a full disk, because a
// retry loop on a full disk is worse than a lost line.
export async function record(entry) {
  const { name, action, runId, ...rest } = entry;
  const line = { agent: name ?? null, action: action ?? "run.end", ...(runId ? { runId } : {}), ...rest };
  for (const k of Object.keys(line)) if (line[k] === undefined) delete line[k];
  try { appendAudit(line); } catch (e) { console.error(`epito: could not append to the audit log (${e.message})`); }
  return {};
}

// --- notify ---------------------------------------------------------------
// One line to Slack per run, for the seats that named a webhook. The value is
// read from THIS process's environment; the workflow only ever saw the name.
export async function notify({ name, manifest, trigger, turns, pr, durationMs, exit }) {
  const out = await postToSlack({ agent: name, manifest, trigger, turns, pr, durationMs, exit });
  if (out.text) {
    await record({ name, action: "slack.post", posted: out.posted, ...(out.reason ? { reason: out.reason } : {}) });
    if (!out.posted) console.log(`${name}: slack post failed (${out.reason})`);
  }
  return out;
}

// --- cleanup --------------------------------------------------------------
// A clone's path arrives from a workflow input, and a workflow input is not a
// trusted source, so removeClone refuses anything that is not this agent's
// clone directly under the system temp dir.
export async function cleanup({ name, workDir }) {
  if (!workDir) return {};
  try { removeClone(name, workDir); }
  catch (e) { throw ApplicationFailure.nonRetryable(e.message, "cleanup"); }
  return {};
}

// Re-exported so the ingress and the workflow agree on the words a window
// opens with, without the ingress importing the runner.
export { windowInstruction, runLogPath };
