// Is anything DOING the work?
//
// Every other check in this product asks whether a run would be *accepted*:
// the manifests load, the box holds the names, a road is open, the engine
// answers, the namespace exists. All of that can be true on a box where
// nothing ever runs, because accepting work and performing it are two
// processes here (deploy/provision-host.sh: `epitod` registers the schedules
// and serves the ingress, `epitod-worker` executes the seats). Kill the worker
// and the engine keeps taking schedules, keeps starting workflows, and keeps
// them pending forever — a state that looked healthy from every surface this
// repository had.
//
// It is not hypothetical. During the step-5 rehearsal a schedule fired with no
// worker polling the queue and `epito ps` printed RUNNING 1 for a seat where
// nothing was running: the workflow was started, which is the only thing ps
// was reading, and no task of it had ever been picked up.
//
// Temporal can be asked directly — `DescribeTaskQueue` returns the pollers the
// server has seen and, with `reportStats`, what is waiting in the queue — so
// this is the one question in the preflight whose answer is free, local and
// exact. Four things about that answer have to be respected or the row lies in
// the other direction:
//
//   1. A worker polls TWO queues of the same name: workflow tasks decide what
//      happens next, activity tasks are the clone, the mint and the `claude`
//      process. A poller on one side and not the other is a real state (a
//      half-built worker, an activity worker pointed at the wrong queue) and
//      it still means a run does not complete, so both are asked.
//   2. A poller entry is a memory, not a socket. The server keeps the last
//      pollers it saw for about five minutes, so a worker killed one minute
//      ago is still listed — measured on a real dev server while writing
//      this. A live worker long-polls with a ~60s timeout and re-polls at
//      once, which is why "recent" here is 2 minutes and not 10 seconds:
//      anything inside that window is a worker, anything outside it is
//      reported as what it is — the engine remembering one.
//   3. Which is exactly the window a poller list cannot close, so the backlog
//      closes it. A WORKFLOW task is a decision and is dispatched in
//      milliseconds on any healthy queue, so one waiting a minute with a
//      poller listed is a worker that is listed and not working: stopped
//      inside the five minutes the engine remembers, or wedged. That is a
//      refusal, and it is the state a poller count alone reports as ✓.
//   4. An ACTIVITY backlog is NOT that. A seat run is a whole `claude` process
//      with a clone of a repository, and the worker runs four at a time by
//      default (EPITO_MAX_CONCURRENT_RUNS) — so the fifth seat's run waiting
//      for a slot is the runtime working as designed. It is reported, because
//      "why has my seat not started" is a real question with that answer, and
//      it is never a refusal.
//
// Nothing in this module imports @temporalio (the connection is handed in by
// the callers that have one), so `epito doctor` can hold its sentences on a
// box with no engine installed, the same rule lib/engine.js follows.

// The two queue types, as the service's own enum. Spelled here rather than
// imported from @temporalio/proto for the reason above: these two numbers are
// the whole of the dependency, and they are part of a stable wire API.
export const TASK_QUEUE_TYPE = { workflow: 1, activity: 2 };

// How recently a poller must have polled to count as a worker that is here.
// See note 2: a deliberate overestimate of one long poll, not a liveness probe.
export const RECENT_MS = 2 * 60 * 1000;

// How long a workflow task may sit before the queue is not being worked. See
// note 3: these are decisions, not runs, and they are dispatched in
// milliseconds when anything is actually polling.
export const STALLED_MS = 60 * 1000;

export const POLLED = "polled";     // both sides have a live poller, work moves
export const STALLED = "stalled";   // a poller is listed and decisions are not moving
export const HALF = "half";         // one side polls, so a run stalls mid-way
export const NONE = "none";         // nothing is doing the work
export const UNASKED = "unasked";   // the question could not be put from here

// The states that mean a run on this box does not get done. `epito doctor`
// reads this rather than re-listing them, so the exit code and the row cannot
// disagree.
export const WORKER_REFUSES = new Set([NONE, HALF, STALLED]);

// Ask the engine: who is polling, and what is waiting. One call per queue
// type, each carrying the pollers as the server reported them — identity and
// how long ago it last polled — so the caller prints a fact and not an
// inference. `reportStats` is additive and old servers simply omit it, which
// reads here as an empty backlog and claims nothing.
export async function describeQueue(connection, { namespace, taskQueue, nowMs = Date.now() } = {}) {
  const ask = async (type) => {
    const res = await connection.workflowService.describeTaskQueue({
      namespace,
      taskQueue: { name: taskQueue },
      taskQueueType: TASK_QUEUE_TYPE[type],
      reportStats: true,
    });
    return {
      pollers: (res?.pollers ?? []).map((p) => ({
        identity: p.identity || "(unnamed worker)",
        agoMs: ageMs(p.lastAccessTime, nowMs),
      })),
      backlog: {
        count: Number(res?.stats?.approximateBacklogCount ?? 0) || 0,
        ageMs: durationMs(res?.stats?.approximateBacklogAge),
      },
    };
  };
  const [workflow, activity] = await Promise.all([ask("workflow"), ask("activity")]);
  return { workflow, activity };
}

// Temporal timestamps arrive as protobuf Timestamps ({seconds, nanos}, where
// seconds may be a Long), and occasionally as something already parsed. A
// stamp this cannot read becomes `null`, which summarize() treats as "age
// unknown" rather than as fresh — an unknown age must never be the reason a
// row goes green.
export function ageMs(stamp, nowMs = Date.now()) {
  if (!stamp) return null;
  if (typeof stamp === "string" || stamp instanceof Date) {
    const t = Date.parse(stamp);
    return Number.isFinite(t) ? Math.max(0, nowMs - t) : null;
  }
  const ms = durationMs(stamp);
  return ms === null ? null : Math.max(0, nowMs - ms);
}

// A protobuf Duration or Timestamp as milliseconds. An absent field is the
// proto default — zero — and an unreadable one is null, which no branch below
// treats as either young or old.
export function durationMs(d) {
  if (d === null || d === undefined) return null;
  if (typeof d === "number") return d;
  const secs = Number(d.seconds ?? 0);
  const nanos = Number(d.nanos ?? 0);
  if (!Number.isFinite(secs) || !Number.isFinite(nanos)) return null;
  return secs * 1000 + nanos / 1e6;
}

const live = (pollers, recentMs) => pollers.filter((p) => p.agoMs !== null && p.agoMs <= recentMs);
const stale = (pollers, recentMs) => pollers.filter((p) => p.agoMs === null || p.agoMs > recentMs);

// A poll age, in the unit that keeps it on the right side of the line. The
// threshold below is RECENT_MS and not the usual 90s hand-over point, because
// this number is the evidence under a ✓ and the rule it is evidence for is
// stated in minutes: a record older than two minutes is a worker that stopped.
// Rounding 1m 37s to "2m" put a ✓ and its own disproof in the same sentence —
// seen on this box 2026-10-12, 73 seconds after a worker was killed:
// "✓ worker  one worker is polling seats ... last polled 2m ago". So anything
// still inside the window is printed in seconds and anything outside it in
// minutes, which makes the unit itself say which side of the line it is on.
export const ago = (ms) => {
  if (ms === null || ms === undefined) return "at a time the engine did not report";
  const s = Math.round(ms / 1000);
  if (s * 1000 < RECENT_MS) return `${s}s ago`;
  const m = Math.round(s / 60);
  return m < 90 ? `${m}m ago` : `${Math.round(m / 60)}h ago`;
};

export const forMs = (ms) => {
  if (ms === null || ms === undefined) return "for a time the engine did not report";
  const s = Math.round(ms / 1000);
  if (s < 90) return `for ${s}s`;
  const m = Math.round(s / 60);
  return m < 90 ? `for ${m}m` : `for ${Math.round(m / 60)}h`;
};

const tasks = (n) => `${n} ${n === 1 ? "task" : "tasks"}`;

// The fix, in both of the places a reader can be standing. A provisioned host
// has the unit (deploy/provision-host.sh writes epitod-worker.service); a
// laptop has the command. Naming only one of them sends half the readers
// looking for a thing their box does not have.
export const WORKER_FIX = "start one: `epito worker` on this box, or `systemctl start epitod-worker` on a host provisioned by deploy/provision-host.sh (`journalctl -u epitod-worker -n 50` says why it stopped).";

// One answer, from the two halves. `says` is the whole sentence a reader gets,
// because these are five different facts and a shared template would blur the
// one that matters most: work accepted and never performed.
export function summarize(queue = {}, { taskQueue = "seats", recentMs = RECENT_MS, stalledMs = STALLED_MS, asked = true, error = null, because = "it takes a real connection to the engine and this box did not get one" } = {}) {
  const wf = queue.workflow ?? { pollers: [], backlog: { count: 0, ageMs: 0 } };
  const act = queue.activity ?? { pollers: [], backlog: { count: 0, ageMs: 0 } };

  if (!asked || error) {
    const empty = {
      state: UNASKED, taskQueue, live: { workflow: 0, activity: 0 }, stale: { workflow: 0, activity: 0 },
      workers: [], backlog: { workflow: { count: 0, ageMs: null }, activity: { count: 0, ageMs: null } }, fix: null,
    };
    // Two different not-answers, and the second one is not a missing engine:
    // the connect and the namespace check succeeded a moment earlier, so an
    // engine that refuses this question is reported as having refused it
    // rather than as absent.
    return error
      ? { ...empty, says: `the engine connected and would not say who is polling ${taskQueue} (${error}), so whether anything performs a run here is unknown from this box`, error }
      : { ...empty, says: `not asked — ${because}, so "is a worker polling ${taskQueue}" has no answer from here` };
  }

  const liveW = live(wf.pollers, recentMs), liveA = live(act.pollers, recentMs);
  const staleW = stale(wf.pollers, recentMs), staleA = stale(act.pollers, recentMs);
  const base = {
    taskQueue,
    live: { workflow: liveW.length, activity: liveA.length },
    stale: { workflow: staleW.length, activity: staleA.length },
    backlog: { workflow: wf.backlog, activity: act.backlog },
  };

  // Who is here, named once however many of the two queues they polled: one
  // worker process is one identity on both, and printing it twice reads as two
  // workers.
  // Its freshest poll of the two, not whichever list came second: the age is
  // the evidence behind the ✓, so it has to be the most recent thing the
  // engine actually saw from that process.
  const freshest = new Map();
  for (const p of [...liveW, ...liveA]) {
    const seen = freshest.get(p.identity);
    if (!seen || (p.agoMs ?? Infinity) < (seen.agoMs ?? Infinity)) freshest.set(p.identity, p);
  }
  const workers = [...freshest.values()]
    .map((p) => ({ identity: p.identity, agoMs: p.agoMs }))
    .sort((a, b) => a.identity.localeCompare(b.identity));

  const remembered = [...new Map([...staleW, ...staleA].map((p) => [p.identity, p])).values()];
  // A stale entry is the difference between "nobody ever started a worker
  // here" and "the worker died" — different fixes, and the second one is the
  // incident. Said in the sentence, not left for a reader to work out.
  const lately = remembered.length
    ? ` The engine still remembers ${remembered.length === 1 ? "a worker" : `${remembered.length} workers`} on this queue (${remembered.map((p) => `${p.identity}, last polled ${ago(p.agoMs)}`).join("; ")}), which it forgets about five minutes after one stops — so ${remembered.length === 1 ? "this one" : "these"} stopped rather than never started.`
    : "";
  // What is waiting, when something is. Named in every sentence that has a
  // backlog to name, because "nothing is polling" and "nothing is polling and
  // nine runs are waiting" are different mornings.
  const waiting = [
    wf.backlog.count ? `${tasks(wf.backlog.count)} to decide what happens next, the oldest waiting ${forMs(wf.backlog.ageMs)}` : null,
    act.backlog.count ? `${tasks(act.backlog.count)} of actual work (clone, mint, the agent's own process), the oldest waiting ${forMs(act.backlog.ageMs)}` : null,
  ].filter(Boolean);
  const queued = waiting.length ? ` Waiting on the queue right now: ${waiting.join("; ")}.` : "";

  const who = (list) => list.map((w) => `${w.identity}, last polled ${ago(w.agoMs)}`).join("; ");

  if (liveW.length && liveA.length) {
    // The one state a poller list gets wrong, and the backlog catches: listed,
    // and not taking the decisions. See note 3 at the top.
    if (wf.backlog.count > 0 && wf.backlog.ageMs !== null && wf.backlog.ageMs > stalledMs) {
      return {
        ...base, state: STALLED, workers,
        says: `${workers.length === 1 ? "a worker is" : `${workers.length} workers are`} listed on ${taskQueue} (${who(workers)}) and the engine has ${tasks(wf.backlog.count)} waiting to be decided, the oldest ${forMs(wf.backlog.ageMs)} — a workflow task is a decision and is dispatched in milliseconds when anything is really polling, so this worker has stopped (the engine remembers a poller for about five minutes) or is wedged.${queued}`,
        fix: WORKER_FIX,
      };
    }
    return {
      ...base, state: POLLED, workers,
      says: `${workers.length === 1 ? "one worker is" : `${workers.length} workers are`} polling ${taskQueue} for both workflow and activity tasks (${who(workers)})${act.backlog.count ? `, and ${tasks(act.backlog.count)} of work ${act.backlog.count === 1 ? "is" : "are"} waiting for a free slot, the oldest ${forMs(act.backlog.ageMs)} — that is the runtime working as designed: a seat run is a whole process, and the worker runs a few at a time (EPITO_MAX_CONCURRENT_RUNS)` : ""}`,
      fix: null,
    };
  }
  if (liveW.length || liveA.length) {
    const has = liveW.length ? "workflow" : "activity";
    const missing = liveW.length ? "activity" : "workflow";
    return {
      ...base, state: HALF, workers,
      says: `a worker is polling ${taskQueue} for ${has} tasks and nothing is polling it for ${missing} tasks, so a run here ${missing === "activity" ? "starts and never clones, mints or spawns anything" : "has its clone and mint picked up and nothing to decide what comes next"} — it sits pending instead of failing.${lately}${queued}`,
      fix: WORKER_FIX,
    };
  }
  return {
    ...base, state: NONE, workers,
    says: `nothing is polling ${taskQueue} — the engine accepts a schedule and starts a run, and no process picks the work up, so a run on this box is queued forever rather than refused.${lately}${queued}`,
    fix: WORKER_FIX,
  };
}

// The same answer as the one phrase `epito ps` has room for in a column, which
// is why it names the side that is missing rather than the state: a reader of
// that column is being told which process to go and start.
export function psMark(summary) {
  if (!summary || summary.state === POLLED || summary.state === UNASKED) return null;
  if (summary.state === NONE) return "no worker";
  if (summary.state === STALLED) return "worker not taking work";
  return summary.live.activity ? "no workflow worker" : "no activity worker";
}
