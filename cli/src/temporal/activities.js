// The five activities: everything that touches a disk, a process, a network or
// a clock lives here, and nothing else does.
//
// Law 7 of the design (docs/prfaq/epitod-v1-temporal.md): Temporal persists
// every activity argument and result to its database in plain text, so no
// secret VALUE may ever appear in either. What crosses this boundary is the
// manifest, which is publishable by design, and the manifest names the secrets
// the run may see. Their values are read from this worker's own environment,
// here, at the last possible moment. The same rule is why the identity mint
// lives inside `execute` rather than in an activity of its own: an activity
// that returned a token would be an activity that filed it.
import { Context, ApplicationFailure } from "@temporalio/activity";
import {
  cloneAgentRepo, executeAgent, killGroup, removeClone, windowInstruction, runLogPath,
} from "../lib/runner.js";
import { postToSlack } from "../lib/slack.js";
import { appendAudit } from "../lib/audit.js";
import { appendBoard } from "../lib/board.js";
import { mintForRun } from "../lib/identity.js";
import { temporalEnv } from "./env.js";

const HEARTBEAT_MIN_MS = 5_000;

// --- the mint, as both activities need it ---------------------------------
// A fresh run mints TWICE: once here for the clone, once inside `execute` for
// the run itself. That is a consequence of law 7 rather than an oversight —
// a token may not cross an activity boundary, so every activity that needs
// one asks for its own. Two credentials, each scoped to the same single
// repository, each living and dying inside one activity invocation, is a
// cheaper trade than one credential written to the engine's database in plain
// text. (A run that resumes a held window skips `clone` and so mints once;
// the audit's `phase` field is what tells the two apart afterwards.)
//
// `retryable` differs because the activities differ: `clone` is retried, so a
// mint that failed on a blip should be retried along with it — but only for
// the failures that can pass. identity.js marks the ones that never will (a
// key that is not a PEM, a scope with no mapping, an App installed nowhere),
// and those stop the run on the first attempt rather than four times slower.
// `execute` is never retried, so every failure there is final regardless.
async function mintFor({ name, manifest, runId, phase, retryable }) {
  let minted = null;
  try {
    minted = await mintForRun({ name, manifest, log: (m) => console.log(`${name}: ${m}`) });
  } catch (e) {
    const msg = `${name}: this run has an identity it could not mint, so it did not start — ${e.message}`;
    throw retryable && !e.permanent
      ? ApplicationFailure.retryable(msg, "mint")
      : ApplicationFailure.nonRetryable(msg, "mint");
  }
  // The audit line carries every fact about the credential except the
  // credential: which App, which installation, which permissions, until when,
  // and which half of the run asked for it. That is what makes "who pushed
  // this" answerable later.
  if (minted) appendAudit({ agent: name, action: "mint", provider: "github-app", runId, phase, ...minted.meta });
  return minted;
}

// --- clone ----------------------------------------------------------------
// Retried: a clone fails for reasons that pass (a network blip, GitHub
// throttling). A missing charter is not one of them, so that one is thrown
// nonRetryable with the message the operator needs.
//
// The clone runs on the agent's OWN credential when it has one. Before this
// it ran on whatever the box's git credential helper answered with, which
// deploy/provision-host.sh wires to the roster-wide human GH_TOKEN — so a
// machine hosting a roster needed one human credential that could read every
// seat's repository, which is the thing this leg of the product exists to
// delete. An agent with no App still clones exactly as it did before.
export async function clone({ name, manifest, runId }) {
  const minted = await mintFor({ name, manifest, runId, phase: "clone", retryable: true });
  try {
    const { workDir } = await cloneAgentRepo({ agent: manifest, runId, token: minted?.token, log: (m) => console.log(m) });
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

  // Identity (cycle 1, bet 2). The mint lives HERE, inside the one activity
  // that uses what it mints, for two reasons that are really one reason:
  //
  //   law 7 — a token returned from an activity is a token written to
  //   Temporal's database in plain text, so there can be no `mint` activity
  //   handing a credential up to a workflow. The secret is born and dies
  //   inside this function call.
  //
  //   law 6 — secrets are named by the manifest and read from the worker's
  //   own environment. The App key is $EPITO_APP_KEY_<NAME> on this box; no
  //   part of it crosses a workflow boundary either.
  //
  // No principal means the pre-identity behaviour, unchanged: the seat runs
  // on the secrets its manifest names. A principal that cannot mint stops the
  // run, non-retryably — "identity failed, so I opened the PR as a human
  // instead" is not a recovery.
  const minted = await mintFor({ name, manifest, runId, phase: "run", retryable: false });

  const result = await executeAgent({
    agent: manifest, trigger, runId, workDir, resume,
    hookBody: payload.hookBody, text: payload.text, instruction: payload.instruction,
    executor: executor || cfg.executor,
    timeoutMs: timeoutMs ?? cfg.runTimeoutMs,
    inject: minted ? { GH_TOKEN: minted.token, GITHUB_TOKEN: minted.token } : null,
    redact: minted ? [minted.token] : [],
    // Not a secret, so it travels on the meta side: the bot user's login and
    // noreply address, which are what make the commits inside the PR the
    // agent's rather than an unlinked address nobody owns.
    commitIdentity: minted?.meta?.commit ?? null,
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
  // `minted.meta` and not `minted`: this return value is persisted by the
  // engine and spread into an audit line by the workflow, and the one field
  // that must never travel is one property name away. Naming the safe half
  // explicitly is cheaper than trusting every future caller to remember.
  return minted ? { ...result, identity: minted.meta } : result;
}

// --- record ---------------------------------------------------------------
// The product's own ledger, append-only, in the product's vocabulary. Written
// by an activity so a workflow that is retried or replayed does not rewrite
// history: `runId` is on every line, so a duplicate is identifiable rather
// than invisible. Never throws a retryable error for a full disk, because a
// retry loop on a full disk is worse than a lost line.
//
// Two files, one call, because they answer two different questions. The audit
// log answers "what exactly happened, including the six lines nobody reads
// until something is wrong" — every window opened, every session held, every
// Slack post that failed. The board answers the owner's question, which is
// "what have the seats been doing", and it holds run reports only. Filing a
// run in both from one activity is what makes them agree.
export async function record(entry) {
  const { name, action, runId, ...rest } = entry;
  const line = { agent: name ?? null, action: action ?? "run.end", ...(runId ? { runId } : {}), ...rest };
  for (const k of Object.keys(line)) if (line[k] === undefined) delete line[k];
  try { appendAudit(line); } catch (e) { console.error(`epito: could not append to the audit log (${e.message})`); }
  if (line.action === "run.end") fileOnBoard(line);
  return {};
}

// The run report, on the board (owner directive 2026-09-26, priority 1). A
// board that refuses a line must never take a run down with it, so this
// catches everything: the run already happened, and the record of it is the
// audit log's job first.
function fileOnBoard(line) {
  try {
    appendBoard({
      agent: line.agent,
      trigger: line.trigger ?? null,
      runId: line.runId ?? null,
      model: line.model ?? null,
      // The board speaks outcomes, not exit codes: "ok", or the name of the
      // stage that stopped the run ("mint", "clone", "charter-missing").
      outcome: line.exit === 0 ? "ok" : String(line.exit ?? "failed"),
      turns: line.turns ?? null,
      pr: line.pr ?? null,
      seconds: line.durationMs != null ? Math.max(1, Math.round(line.durationMs / 1000)) : null,
      detail: line.detail ?? null,
      source: "epitod",
    });
  } catch (e) {
    console.error(`epito: the run is recorded, but the board would not take it (${e.message})`);
  }
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
