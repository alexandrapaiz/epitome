// Is anything DOING the work?
//
// Every other check in this product asks whether a run would be *accepted*:
// the manifests load, the box holds the names, a road is open, the engine
// answers, the namespace exists. All of that can be true on a box where
// nothing ever runs, because accepting work and performing it are two
// processes here (deploy/provision-host.sh: `epitod` registers the schedules
// and serves the ingress, `epitod-worker` executes the seats). Kill the worker
// and the engine keeps taking schedules, keeps starting workflows, and keeps
// them pending forever — a state that looks like a healthy box from every
// surface this repository had.
//
// It is not hypothetical. During the step-5 rehearsal a schedule fired with no
// worker polling the queue and `epito ps` printed RUNNING 1 for a seat where
// nothing was running: the workflow was started, which is the only thing ps
// was reading, and no task of it had ever been picked up.
//
// Temporal can be asked directly — `DescribeTaskQueue` returns the pollers the
// server has seen — so this is the one question in the preflight whose answer
// is free, local and exact. Two things about that answer have to be respected
// or the row lies in the other direction:
//
//   1. A worker polls TWO queues of the same name: workflow tasks decide what
//      happens next, activity tasks are the clone, the mint and the `claude`
//      process. A poller on one side and not the other is a real state (a
//      half-built worker, an activity worker pointed at the wrong queue) and
//      it still means a run does not complete, so both are asked.
//   2. A poller entry is a memory, not a socket. The server keeps the last
//      pollers it saw for about five minutes, so a worker that died a minute
//      ago is still listed. A live worker long-polls with a ~60s timeout and
//      re-polls at once, which is why "recent" here is 2 minutes and not 10
//      seconds: anything inside that window is a worker, anything outside it
//      is reported as what it is — the engine remembering one.
//
// Nothing in this module imports @temporalio (the connection is handed in by
// the one caller that has one), so `epito doctor` can hold its sentences on a
// box with no engine installed, the same rule lib/engine.js follows.

// The two queue types, as the service's own enum. Spelled here rather than
// imported from @temporalio/proto for the reason above: these two numbers are
// the whole of the dependency, and they are part of a stable wire API.
export const TASK_QUEUE_TYPE = { workflow: 1, activity: 2 };

// How recently a poller must have polled to count as a worker that is here.
// See note 2 above: this is a deliberate overestimate of a long poll, not a
// liveness probe.
export const RECENT_MS = 2 * 60 * 1000;

export const POLLED = "polled";     // both sides have a live poller
export const HALF = "half";         // one side does, so a run stalls mid-way
export const NONE = "none";         // nothing is doing the work
export const UNASKED = "unasked";   // no engine answered, so this was not asked

// The states that mean a run on this box does not get done. `epito doctor`
// reads this rather than re-listing them, so the exit code and the row cannot
// disagree.
export const WORKER_REFUSES = new Set([NONE, HALF]);

// Ask the engine. Returns one entry per type, each carrying the pollers as the
// server reported them — identity and how long ago it last polled — so the
// caller prints a fact and not an inference.
export async function describePollers(connection, { namespace, taskQueue, nowMs = Date.now() } = {}) {
  const ask = async (type) => {
    const res = await connection.workflowService.describeTaskQueue({
      namespace,
      taskQueue: { name: taskQueue },
      taskQueueType: TASK_QUEUE_TYPE[type],
    });
    return (res?.pollers ?? []).map((p) => ({
      identity: p.identity || "(unnamed worker)",
      agoMs: ageMs(p.lastAccessTime, nowMs),
    }));
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
  const secs = Number(stamp.seconds ?? stamp.low ?? NaN);
  if (!Number.isFinite(secs)) return null;
  const ms = secs * 1000 + Number(stamp.nanos ?? 0) / 1e6;
  return Math.max(0, nowMs - ms);
}

const live = (pollers, recentMs) => pollers.filter((p) => p.agoMs !== null && p.agoMs <= recentMs);
const stale = (pollers, recentMs) => pollers.filter((p) => p.agoMs === null || p.agoMs > recentMs);

export const ago = (ms) => {
  if (ms === null || ms === undefined) return "at a time the engine did not report";
  const s = Math.round(ms / 1000);
  if (s < 90) return `${s}s ago`;
  const m = Math.round(s / 60);
  return m < 90 ? `${m}m ago` : `${Math.round(m / 60)}h ago`;
};

// The fix, in both of the places a reader can be standing. A provisioned host
// has the unit (deploy/provision-host.sh writes epitod-worker.service); a
// laptop has the command. Naming only one of them sends half the readers
// looking for a thing their box does not have.
export const WORKER_FIX = "start one: `epito worker` on this box, or `systemctl start epitod-worker` on a host provisioned by deploy/provision-host.sh (`journalctl -u epitod-worker -n 50` says why it stopped).";

// One answer, from the two lists. `says` is the whole sentence a reader gets,
// because the four states are four different facts and a shared template would
// blur the one that matters most: work accepted and never performed.
export function summarize({ workflow = [], activity = [] } = {}, { taskQueue = "seats", recentMs = RECENT_MS, asked = true } = {}) {
  if (!asked) {
    return {
      state: UNASKED, taskQueue, live: { workflow: 0, activity: 0 }, stale: { workflow: 0, activity: 0 }, workers: [],
      says: `not asked — nothing answered at the engine's address, so "is a worker polling ${taskQueue}" has no answer from here`,
      fix: null,
    };
  }
  const liveW = live(workflow, recentMs), liveA = live(activity, recentMs);
  const staleW = stale(workflow, recentMs), staleA = stale(activity, recentMs);
  const counts = { live: { workflow: liveW.length, activity: liveA.length }, stale: { workflow: staleW.length, activity: staleA.length } };

  // Who is here, named once however many of the four polls they answered: one
  // worker process is one identity on both queues, and printing it twice reads
  // as two workers.
  const workers = [...new Map([...liveW, ...liveA].map((p) => [p.identity, p])).values()]
    .map((p) => ({ identity: p.identity, agoMs: p.agoMs }))
    .sort((a, b) => a.identity.localeCompare(b.identity));

  const remembered = [...new Map([...staleW, ...staleA].map((p) => [p.identity, p])).values()];
  // A stale entry is the difference between "nobody ever started a worker
  // here" and "the worker died" — different fixes, and the second one is the
  // incident. Said in the sentence, not left for a reader to work out.
  const lately = remembered.length
    ? ` The engine still remembers ${remembered.length === 1 ? "a worker" : `${remembered.length} workers`} on this queue (${remembered.map((p) => `${p.identity}, last polled ${ago(p.agoMs)}`).join("; ")}), which it forgets about five minutes after one stops — so this one stopped rather than never started.`
    : "";

  if (liveW.length && liveA.length) {
    return {
      ...counts, state: POLLED, taskQueue, workers,
      says: `${workers.length === 1 ? "one worker is" : `${workers.length} workers are`} polling ${taskQueue} for both workflow and activity tasks (${workers.map((w) => `${w.identity}, last polled ${ago(w.agoMs)}`).join("; ")})`,
      fix: null,
    };
  }
  if (liveW.length || liveA.length) {
    const has = liveW.length ? "workflow" : "activity";
    const missing = liveW.length ? "activity" : "workflow";
    return {
      ...counts, state: HALF, taskQueue, workers,
      says: `a worker is polling ${taskQueue} for ${has} tasks and nothing is polling it for ${missing} tasks, so a run here ${missing === "activity" ? "starts and never clones, mints or spawns anything" : "has its clone and mint picked up and nothing to decide what comes next"} — it sits pending instead of failing.${lately}`,
      fix: WORKER_FIX,
    };
  }
  return {
    ...counts, state: NONE, taskQueue, workers,
    says: `nothing is polling ${taskQueue} — the engine accepts a schedule and starts a run, and no process picks the work up, so a run on this box is queued forever rather than refused.${lately}`,
    fix: WORKER_FIX,
  };
}

// The same answer as the one phrase `epito ps` has room for in a column, which
// is why it names the side that is missing rather than the state: a reader of
// that column is being told which process to go and start.
export function psMark(summary) {
  if (!summary || summary.state === POLLED || summary.state === UNASKED) return null;
  if (summary.state === NONE) return "no worker";
  return summary.live.activity ? "no workflow worker" : "no activity worker";
}
