// The orchestration, and nothing else. Law 4 of the design
// (docs/prfaq/epitod-v1-temporal.md): this file is deterministic — no fs, no
// spawn, no fetch, no randomness. `Date.now()` is allowed and used, because
// the workflow sandbox replaces it with workflow time, which replays
// identically. Every side effect is an activity, and every activity's retry
// policy and timeout is declared at the call site, because "what happens when
// this step fails" is the question this runtime exists to answer.
//
// Two workflows:
//   SeatRun(input)     one run of one seat: clone, execute, record, notify
//   SeatWindow(input)  a stretch of presence: holds the executor session and
//                      the clone, runs a child SeatRun per message
import {
  proxyActivities, defineSignal, defineQuery, setHandler, condition,
  workflowInfo, executeChild, ApplicationFailure, CancellationScope, log,
} from "@temporalio/workflow";

// --- signals and queries (the public surface of a running workflow) --------

// A trigger that arrived while a run was in flight. v0 called this coalescing
// and kept exactly one slot, merging two messages rather than dropping one.
export const followUp = defineSignal("followUp");

export const message = defineSignal("message");
export const close = defineSignal("close");
export const refresh = defineSignal("refresh");

// What `epito ps` asks a running workflow.
export const runState = defineQuery("state");
export const windowState = defineQuery("state");

// --- activity proxies -----------------------------------------------------

// Everything short: a clone, a record, a Slack line, an rm -rf. Retried,
// because all four fail for reasons that pass.
const short = proxyActivities({
  startToCloseTimeout: "2 minutes",
  retry: { initialInterval: "2s", backoffCoefficient: 2, maximumInterval: "30s", maximumAttempts: 5 },
});

// The run itself. ONE attempt, on purpose: an execution that half-ran has
// already pushed commits and may have opened a PR, so replaying it is worse
// than failing. The timeout is the manifest owner's EPITO_RUN_TIMEOUT_MS,
// carried in the input so a replay of an old history keeps its old value.
function executor(runTimeoutMs) {
  return proxyActivities({
    startToCloseTimeout: runTimeoutMs,
    heartbeatTimeout: "5 minutes",
    retry: { maximumAttempts: 1 },
  });
}

// --- SeatRun --------------------------------------------------------------

// input: { name, manifest, trigger, payload?, resume?, route?, workDir?,
//          keepWork?, runTimeoutMs?, executor? }
// result: { exit, durationMs, pr, sessionId, turns, log, workDir, route, model }
//
// `route` travels beside `resume` and for the same reason: a held session
// belongs to the provider that made it (ADR-19), so a window's follow-up must
// land on the road its opening run took. It is a NAME — the one the manifest
// gave that road — and never an endpoint or a key, so nothing secret enters
// the engine's database (law 7).
export async function SeatRun(input) {
  const { name, manifest } = input;
  if (!name || !manifest?.runtime) {
    throw ApplicationFailure.nonRetryable(`SeatRun needs { name, manifest } — a run carries its own manifest snapshot, so the worker never reads the roster directory`);
  }
  const runTimeoutMs = input.runTimeoutMs ?? 60 * 60 * 1000;
  const { execute } = executor(runTimeoutMs);

  // A trigger that lands mid-run waits here. Two messages merge; anything else
  // queues, which is the rule v0's enqueue() applied.
  //
  // Every trigger carries a `token`, and the run's own token is already in
  // `seen` before the handler exists. That is not belt-and-braces: the ingress
  // reaches this workflow with signalWithStart, which delivers the signal even
  // on the call that STARTS the run, so without the token every fresh hook and
  // message would execute twice — once from the input, once from its own
  // signal. The smoke test caught exactly that.
  const queued = [];
  const seen = new Set(input.token ? [input.token] : []);
  setHandler(followUp, (req) => {
    if (req?.token) {
      if (seen.has(req.token)) return;
      seen.add(req.token);
    }
    const last = queued[queued.length - 1];
    if (last && last.trigger === "message" && req?.trigger === "message") {
      last.payload = { ...last.payload, text: `${last.payload?.text ?? ""}\n\n${req.payload?.text ?? ""}` };
    } else queued.push(req);
  });

  const info = workflowInfo();
  const baseRunId = `${info.workflowId.replace(/[^A-Za-z0-9_.-]/g, "-")}-${info.runId.slice(0, 8)}`;
  let attempt = 0;
  let last = null;
  // The two fields the BUS reads, and the only reason this query is asked by
  // anything other than `epito ps`. The consumer that woke this run holds its
  // event unacknowledged until one of them answers:
  //
  //   refusal   a resource refused the run before a first turn. The event is
  //             given back, at the reset time the refusal named — the run
  //             never happened and must not be thrown away with it.
  //   past      the provider took the run, or it ended for a reason that is
  //             not capacity. Acknowledge: whatever happens now belongs to
  //             the run, and a redelivery would be a second one.
  //
  // Both are facts about the attempt in flight, so both are cleared when the
  // next one starts.
  let refusal = null;
  let past = false;
  setHandler(runState, () => ({ name, trigger: last?.trigger ?? input.trigger, attempt, queued: queued.length, last, refusal, past }));

  let req = input;
  for (;;) {
    attempt++;
    const id = attempt === 1 ? baseRunId : `${baseRunId}-${attempt}`;
    // Workflow time, so a replay of this history files the same span: it is
    // where the run's own trace starts, and `record` is the activity that
    // files it (ADR-18).
    const startedAt = new Date().toISOString();
    // A window's clone is borrowed: this run neither makes it nor deletes it.
    const borrowed = Boolean(req.workDir);
    let workDir = borrowed ? req.workDir : null;
    let result;
    refusal = null;
    past = false;
    try {
      if (!borrowed) workDir = (await short.clone({ name, manifest, runId: id })).workDir;
      result = await execute({
        name, manifest, runId: id, workDir,
        trigger: req.trigger, payload: req.payload ?? {}, resume: req.resume ?? null,
        routeName: req.route ?? null,
        executor: req.executor ?? input.executor ?? null,
        timeoutMs: runTimeoutMs,
      });
    } catch (err) {
      // The run failed as a run: a clone that would not clone, a charter that
      // is not there, a timeout, a dead worker, a cancellation. Record it in
      // the product's own ledger before letting the workflow fail, so
      // audit.jsonl never holds a run that just stops mid-sentence.
      //
      // ApplicationFailure.type carries the stage name the activity chose
      // ("clone", "charter-missing", "cancelled"); anything else is a run that
      // died for a reason no activity got to name.
      const exit = err?.cause?.type ?? "failed";
      // Not capacity: a clone that would not clone, a charter that is not
      // there, a dead worker. Said to the consumer at once so it acknowledges
      // now rather than holding the event for the whole refusal window.
      past = true;
      await CancellationScope.nonCancellable(async () => {
        // The useful sentence is the ACTIVITY's message, not the wrapper's:
        // Temporal's ActivityFailure says only "Activity task failed", and an
        // audit line that says that has told the operator nothing.
        const detail = String(err?.cause?.message ?? err?.message ?? err);
        await short.record({ name, trigger: req.trigger, runId: id, model: manifest.runtime.model, exit, detail, startedAt });
        if (!borrowed && workDir) await short.cleanup({ name, workDir });
      });
      throw err;
    }

    refusal = result.refusal ?? null;
    past = !refusal;
    last = { trigger: req.trigger, ...result };
    await short.record({ name, trigger: req.trigger, runId: id, resume: req.resume ?? null, model: manifest.runtime.model, startedAt, ...result });
    await short.notify({ name, manifest, trigger: req.trigger, turns: result.turns, pr: result.pr, durationMs: result.durationMs, exit: result.exit, refusal });

    // Who owns the clone: a window that lent it, a window that asked this run
    // to make one, or nobody, in which case it goes now.
    const keep = borrowed || Boolean(req.keepWork ?? input.keepWork);
    if (!keep) await short.cleanup({ name, workDir });

    if (queued.length === 0) {
      return { ...result, workDir: keep && !borrowed ? workDir : null };
    }
    log.info(`${name}: ${queued.length} trigger(s) arrived during the run — running the coalesced follow-up`);
    req = { ...input, ...queued.shift(), workDir: borrowed ? req.workDir : null };
  }
}

// --- SeatWindow -----------------------------------------------------------

// input: { name, manifest, ttlMs, agenda?, instruction?, runTimeoutMs?, executor? }
export async function SeatWindow(input) {
  const { name, manifest } = input;
  if (!name || !manifest?.runtime) {
    throw ApplicationFailure.nonRetryable(`SeatWindow needs { name, manifest } — a window carries its own manifest snapshot`);
  }
  const info = workflowInfo();
  const openedAt = new Date(info.startTime).toISOString();
  let expiresAt = new Date(info.startTime.getTime() + input.ttlMs).toISOString();
  let closing = null;          // the reason, once there is one
  let session = null;
  // The road the window was opened on, held for the same reason the session
  // is: a follow-up that lands on a different provider is talking to a
  // conversation that does not exist there (ADR-19).
  let route = null;
  let workDir = null;
  let runs = 0;
  const inbox = [];

  setHandler(message, (text) => { if (typeof text === "string" && text.trim()) inbox.push(text.trim()); });
  setHandler(close, () => { closing ??= "requested"; });
  setHandler(refresh, (ttlMs) => {
    const ms = Number(ttlMs) > 0 ? Number(ttlMs) : input.ttlMs;
    expiresAt = new Date(Date.now() + ms).toISOString();
    log.info(`${name}: window already open — deadline moved to ${expiresAt}`);
  });
  setHandler(windowState, () => ({ name, openedAt, expiresAt, session, workDir, runs, queued: inbox.length, closing }));

  const child = (args, suffix) => executeChild(SeatRun, {
    workflowId: `run:${name}:${suffix}`,
    args: [{ name, manifest, runTimeoutMs: input.runTimeoutMs, executor: input.executor, ...args }],
  });

  await short.record({ name, action: "window.open", until: expiresAt, agenda: input.agenda ? input.agenda.length : undefined });

  // Opening a window fires the seat once, and that first run is what produces
  // the session and the clone the rest of the window holds.
  try {
    const first = await child({ trigger: "window", payload: { instruction: input.instruction }, keepWork: true }, `window:${runs}`);
    runs++;
    session = first.sessionId ?? null;
    route = first.route ?? null;
    workDir = first.workDir ?? null;
    if (session && workDir) await short.record({ name, action: "session.hold", session, route, until: expiresAt });
  } catch (e) {
    // The seat could not run (no charter, clone refused). There is nothing to
    // hold, so the window is over rather than open and empty.
    await short.record({ name, action: "window.close", reason: "the opening run failed, so there is no session to hold" });
    throw e;
  }

  while (!closing) {
    const ms = Date.parse(expiresAt) - Date.now();
    if (ms <= 0) { closing = "expired"; break; }
    const awake = await condition(() => inbox.length > 0 || closing !== null, ms);
    if (!awake) { closing = "expired"; break; }
    if (closing) break;

    // Everything said while the seat was busy arrives as one message: a
    // coalesced trigger may be dropped, words a person typed may not.
    const text = inbox.splice(0, inbox.length).join("\n\n");
    const r = await child({ trigger: "message", payload: { text }, resume: session, route, workDir }, `message:${runs}`);
    runs++;
    if (r.sessionId) session = r.sessionId;
    if (r.route) route = r.route;
    if (r.exit === "workdir-gone") { closing = "the held clone is gone; the next message starts a fresh run"; break; }
  }

  // The clone dies with the window, always: the PRs are the record (ADR-2),
  // the session is not. nonCancellable so a terminated window still tidies up.
  await CancellationScope.nonCancellable(async () => {
    if (workDir) await short.cleanup({ name, workDir });
    await short.record({ name, action: "window.close", reason: closing ?? "closed", openedAt, session, runs });
  });
  return { name, openedAt, closedAt: new Date().toISOString(), reason: closing, runs, session };
}
