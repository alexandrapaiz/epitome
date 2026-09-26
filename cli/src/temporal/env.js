// Where the engine is, and the names of the things we put in it. One module so
// `epito run`, `epito worker` and `epito ps` cannot disagree about any of it.
//
// TEMPORAL_NAMESPACE defaults to "default" so a laptop and `temporal server
// start-dev` work with no configuration. The company host sets "asc" in
// /srv/asc/env. Both processes log the address and namespace they connected to
// on their first line, so a misconfigured host is visible immediately instead
// of after a silent day of writing to the wrong namespace.

export const DEFAULT_RUN_TIMEOUT_MS = 60 * 60 * 1000;
export const DEFAULT_WINDOW_MS = 4 * 60 * 60 * 1000;
export const DEFAULT_PORT = 4747;

export function temporalEnv(env = process.env) {
  return {
    address: env.TEMPORAL_ADDRESS || "127.0.0.1:7233",
    namespace: env.TEMPORAL_NAMESPACE || "default",
    taskQueue: env.EPITO_TASK_QUEUE || "seats",
    runTimeoutMs: Number(env.EPITO_RUN_TIMEOUT_MS) || DEFAULT_RUN_TIMEOUT_MS,
    windowMs: Number(env.EPITO_WINDOW_MS) || DEFAULT_WINDOW_MS,
    executor: env.EPITO_EXECUTOR || "claude",
  };
}

// The ids. A schedule is named for the seat it wakes; a run and a window are
// named for the seat they belong to, so every id in the Temporal UI reads as a
// sentence about an agent rather than as a uuid.
export const scheduleId = (name) => `seat:${name}`;
export const seatOfScheduleId = (id) => (id.startsWith("seat:") ? id.slice(5) : null);

// One id per seat for every ingress-triggered run, so `signalWithStart` either
// starts the run or hands the trigger to the run already going. That is v0's
// coalescing, done by the engine. Scheduled runs get this id plus the
// scheduled time, which Temporal appends itself.
export const runId = (name) => `run:${name}`;
export const windowId = (name) => `window:${name}`;
export const seatOfWindowId = (id) => (id.startsWith("window:") ? id.slice(7) : null);

// The seat a workflow id belongs to. Three shapes reach this, and an agent
// name may itself contain hyphens, so the suffixes come off in order rather
// than by one greedy pattern:
//   run:pm                              an ingress-triggered run
//   run:market-agent-2026-09-27T06:00Z  a scheduled run (Temporal stamps the time)
//   run:pm:message:3                    a window's child run
export function seatOfWorkflowId(id) {
  if (typeof id !== "string") return null;
  const m = /^(?:run|window):(.+)$/.exec(id);
  if (!m) return null;
  const name = m[1]
    .replace(/-\d{4}-\d{2}-\d{2}T[0-9:.]+Z?$/, "")   // the scheduled time
    .split(":")[0];                                    // a window child's suffix
  return /^[a-z0-9-]{1,40}$/.test(name) ? name : null;
}

export const WORKFLOW_TYPES = { run: "SeatRun", window: "SeatWindow" };
