// Schedule reconciliation: make Temporal match the roster on disk.
//
// The desired state is a pure function of the roster, which is exactly why
// this is safe to run on every restart — `epito run` is idempotent, and the
// diff below is the whole of its behavior:
//
//   create    in the roster with a [trigger].cron, no schedule yet
//   update    both, and something the run depends on changed
//   delete    a schedule with no manifest behind it, or a seat that lost its cron
//   unchanged everything else
//
// A seat with no [trigger].cron registers nothing. That is the normal case
// today: all 36 manifests across the four companies are presence-only until
// the cutover, so a first reconcile against the live server creates zero
// schedules and fires nothing. `[trigger].webhook` is served by the ingress,
// not by a schedule, which is the division of labor epitod v0 already had —
// and since v0.1 froze, the ingress reads the field instead of waking any seat
// that happens to be in the roster.
import { ScheduleOverlapPolicy } from "@temporalio/client";
import { scheduleId, seatOfScheduleId, runId, temporalEnv } from "./env.js";

// The fields a registered schedule carries. Anything here that differs between
// disk and engine is an update; anything not here cannot change a run, so
// changing it must not churn the schedule.
export function scheduleShape(manifest) {
  const rt = manifest.runtime;
  return {
    cron: manifest.trigger.cron,
    model: rt.model,
    repo: rt.repo,
    ref: rt.ref ?? null,
    entry: rt.entry,
    max_turns: rt.max_turns ?? null,
    env: [...(rt.env ?? [])].sort(),
    slack_webhook_env: rt.slack_webhook_env ?? null,
  };
}

const sameShape = (a, b) => JSON.stringify(a) === JSON.stringify(b);

// The diff, as a pure function so it is testable without a server.
// desired: Map<name, manifest>            (only seats with [trigger].cron)
// actual:  Array<{ id, shape }>           (only ids starting "seat:")
export function reconcilePlan(desired, actual) {
  const plan = { create: [], update: [], delete: [], unchanged: [] };
  const byId = new Map(actual.map((s) => [s.id, s]));
  for (const [name, manifest] of desired) {
    const id = scheduleId(name);
    const shape = scheduleShape(manifest);
    const have = byId.get(id);
    if (!have) plan.create.push({ name, id, shape });
    else if (!sameShape(have.shape, shape)) plan.update.push({ name, id, shape, was: have.shape });
    else plan.unchanged.push({ name, id, shape });
  }
  for (const s of actual) {
    const name = seatOfScheduleId(s.id);
    // An id that is not "seat:<name>" was not registered by epito, so it is
    // not epito's to delete. listSeatSchedules filters these out already; the
    // guard is here because the caller of a pure function is not a promise.
    if (name && !desired.has(name)) plan.delete.push({ name, id: s.id, shape: s.shape });
  }
  return plan;
}

// The workflow argument a schedule carries: the manifest snapshot itself. It
// is publishable by design (spec rule 1), which is the only reason it is safe
// to persist in Temporal's database.
function action({ name, manifest, cfg }) {
  return {
    type: "startWorkflow",
    workflowType: "SeatRun",
    workflowId: runId(name),
    taskQueue: cfg.taskQueue,
    args: [{ name, manifest, trigger: "cron", runTimeoutMs: cfg.runTimeoutMs }],
    workflowRunTimeout: cfg.runTimeoutMs,
  };
}

// The memo is what `epito ps` reads back, so it never has to guess which
// manifest a schedule came from.
const memo = (name, shape) => ({ seat: name, shape: JSON.stringify(shape) });

async function listSeatSchedules(client) {
  const out = [];
  for await (const s of client.schedule.list()) {
    if (!s.scheduleId.startsWith("seat:")) continue;
    let shape = null;
    try { shape = s.memo?.shape ? JSON.parse(s.memo.shape) : null; } catch { shape = null; }
    out.push({ id: s.scheduleId, shape, note: s.note ?? null, raw: s });
  }
  return out;
}

// Reconcile, and report what it did in the product's vocabulary. `dryRun`
// prints the plan and touches nothing.
export async function reconcile({ client, roster, env = process.env, dryRun = false, log = console.log }) {
  const cfg = temporalEnv(env);
  const desired = new Map();
  for (const [name, a] of roster) if (a.manifest.trigger?.cron) desired.set(name, a.manifest);

  const actual = await listSeatSchedules(client);
  const plan = reconcilePlan(desired, actual);

  const presenceOnly = [...roster.keys()].filter((n) => !desired.has(n));
  log(`roster: ${roster.size} seat${roster.size === 1 ? "" : "s"}, ${desired.size} on a cron, ${presenceOnly.length} presence-only`);
  if (presenceOnly.length) log(`  presence-only (no [trigger].cron, so no schedule): ${presenceOnly.join(", ")}`);
  if (dryRun) {
    for (const k of ["create", "update", "delete"]) for (const s of plan[k]) log(`  would ${k} ${s.id}${s.shape?.cron ? ` (${s.shape.cron} UTC)` : ""}`);
    log(`  ${plan.unchanged.length} unchanged`);
    return plan;
  }

  for (const s of plan.create) {
    await client.schedule.create({
      scheduleId: s.id,
      spec: { cronExpressions: [s.shape.cron], timezone: "UTC" },
      // v0 hand-wrote this: a fire arriving while the seat is still running is
      // coalesced into a single follow-up, never dropped, never stacked.
      policies: { overlap: ScheduleOverlapPolicy.BUFFER_ONE, catchupWindow: "1 hour" },
      action: action({ name: s.name, manifest: desired.get(s.name), cfg }),
      memo: memo(s.name, s.shape),
      note: `epito seat ${s.name}: ${desired.get(s.name).agent.description}`,
    });
    log(`  + ${s.id}  ${s.shape.cron} UTC  ${s.shape.model}  ${s.shape.repo}`);
  }

  for (const s of plan.update) {
    const handle = client.schedule.getHandle(s.id);
    await handle.update((prev) => ({
      ...prev,
      spec: { ...prev.spec, cronExpressions: [s.shape.cron], timezone: "UTC", calendars: [], intervals: [] },
      action: action({ name: s.name, manifest: desired.get(s.name), cfg }),
      memo: memo(s.name, s.shape),
    }));
    const changed = Object.keys(s.shape).filter((k) => JSON.stringify(s.shape[k]) !== JSON.stringify(s.was?.[k]));
    log(`  ~ ${s.id}  changed: ${changed.join(", ") || "(re-registered)"}`);
  }

  for (const s of plan.delete) {
    await client.schedule.getHandle(s.id).delete();
    log(`  - ${s.id}  (no manifest with a [trigger].cron behind it any more)`);
  }

  log(`reconciled: ${plan.create.length} created, ${plan.update.length} updated, ${plan.delete.length} deleted, ${plan.unchanged.length} unchanged`);
  return plan;
}

export { listSeatSchedules };
