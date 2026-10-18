// `epito run <dir>`: reconcile the roster onto the engine, then serve the
// ingress as a thin Temporal client (epitod v1,
// docs/prfaq/epitod-v1-temporal.md).
//
// What this process is NOT any more: a scheduler, a mutex, a retry loop, a
// crash-recovery story, and an executor. Those four were epitod v0's hand-built
// middle, and they are the engine's job now. What is left is the part that is
// ours:
//
//   - load every agent.toml under <dir> through the same validator `epito
//     validate` applies; a broken manifest stops the command, loudly
//   - make Temporal's schedules match that roster (create / update / delete),
//     which is idempotent, so a restart reconciles rather than duplicates
//   - hold one durable bus consumer per seat that declares
//     `[trigger].subscriptions`, and acknowledge an event only once that
//     seat's run has started, so an event outlives a restart and is
//     redelivered until a seat takes it
//   - serve POST /hooks/<name>, /message/<name>, /window/open, /window/close
//     and GET /healthz, turning each into a workflow start or a signal
//   - serve the board: POST /board files a run report from a seat anywhere
//     (a GitHub Actions job, a laptop), GET /board reads it back
//   - SIGHUP re-reads the roster and reconciles again, so adding a seat does
//     not need a restart
//
// The ingress refers to workflows and signals BY NAME rather than importing
// src/temporal/workflows.js. That is deliberate: workflow code belongs to the
// worker's sandbox, and an ingress that imports it would be one refactor away
// from running a workflow in the wrong process.
import { resolve } from "node:path";
import { randomUUID } from "node:crypto";
import { loadRoster } from "./lib/roster.js";
import { companyFor } from "./lib/company.js";
import { thisRuntime, buildLine, buildNote } from "./lib/build.js";
import { rosterEnv, shortfallSays } from "./lib/boxenv.js";
import { SPEC_VERSION } from "./lib/fields.js";
import { startHookServer } from "./lib/hooks.js";
import { windowInstruction } from "./lib/runner.js";
import { appendAudit, AUDIT_PATH } from "./lib/audit.js";
import { appendBoard, readBoard, foldBoard, renderBoard, BOARD_PATH } from "./lib/board.js";
import { busEnv, subscribingSeats, reconcileConsumers, startConsuming, busOffSays, durableFor } from "./lib/bus.js";
import { connectBus } from "./lib/nats.js";
import { connect } from "./temporal/client.js";
import { reconcile } from "./temporal/schedules.js";
import { temporalEnv, runId, windowId, DEFAULT_PORT } from "./temporal/env.js";

const ts = () => new Date().toISOString();
const log = (msg) => console.log(`${ts()} ${msg}`);

const ALREADY_STARTED = "WorkflowExecutionAlreadyStartedError";
// The other side of the same coin. `signalWithStart` either signals the
// execution already running under this id or starts one — but the two happen
// on the server in that order, so a run that COMPLETES in between is signalled
// after it closed and the call fails. It is the ordinary end of every run
// racing the ingress, not a broken workflow, and the caller's own intent
// ("start a fresh run") is exactly what a retry does: by the second attempt
// the execution is closed, so signalWithStart starts a new one.
const ALREADY_COMPLETED = "WorkflowNotFoundError";
export const justCompleted = (e) =>
  e?.name === ALREADY_COMPLETED || /workflow execution already completed/i.test(e?.message ?? "");

// The retry itself, lifted out of the closure so a test can drive it without a
// Temporal server: the race it fixes is a race, and a fix that can only be
// checked by losing a coin toss is a fix that comes back. `send` is the
// signalWithStart call; anything that is not this one race propagates
// untouched, because a swallowed error here would hide a real broken workflow.
export async function sendOrRestart(send, onRace = () => {}) {
  try { return { handle: await send(), raced: false }; }
  catch (e) {
    if (!justCompleted(e)) throw e;
    onRace();
    return { handle: await send(), raced: true };
  }
}

// The shortfall block, one line per seat that is short of something and one
// line saying which command is the whole report. Silent on a box that holds
// every name: a rehearsal whose happy path prints nothing is a rehearsal whose
// output is all signal, and `epito env` is where "and it holds all 7" belongs.
export function sayShortfall(roster, dirArg, say) {
  const report = rosterEnv(roster, process.env);
  const short = report.seats.filter((s) => s.short.length);
  if (!short.length) return report;
  say(`${short.length} of ${roster.size} seat${roster.size === 1 ? "" : "s"} run${short.length === 1 ? "s" : ""} here short of a name its manifest asks this box to hold:`);
  for (const s of short) say(`  ! ${s.agent}: ${shortfallSays(s)}`);
  // The closing line says what each kind actually DOES, and only the kinds
  // this box has. Found by running it on a box whose one shortfall was a name
  // set to nothing: the single sentence said "a name this box does not hold is
  // dropped from the run's environment", which is the wrong half of the story
  // for a name the box holds and holds empty — that one is injected, and the
  // agent acts on it.
  const kinds = [
    short.some((s) => s.missing.length) ? "a name this box does not hold is dropped from the run's environment and the seat runs without it" : null,
    short.some((s) => s.empty.length) ? "a name set to nothing is injected as an empty value and the seat acts on it" : null,
  ].filter(Boolean);
  say(`  ${kinds.join("; ")}: \`epito env ${dirArg}\` is the whole report (--template prints the env file it belongs in; --complete makes a name this box lacks an error, and a name set to nothing already is one)`);
  return report;
}

export async function runDaemon(dirArg, { dryRun = false } = {}) {
  // The resident daemon hosts every seat's ingress and windows, so one stray error
  // must not take them all down. Log it, keep running, and let the next run report
  // what broke. The host lost eight daemons and four open windows this way on 2026-10-17.
  process.on("uncaughtException", (e) => console.error(`${new Date().toISOString()} daemon: uncaught ${e?.stack || e}`));
  process.on("unhandledRejection", (e) => console.error(`${new Date().toISOString()} daemon: unhandled rejection ${e?.stack || e}`));
  // The first line, before the roster and before the engine, because it is the
  // one line that qualifies every line after it. A resident daemon is started
  // once from a checkout and then believed for weeks: on 2026-10-18 the host's
  // was four weeks behind main with two files hand-patched, so merged fixes
  // were not running and nothing on any surface said which code was.
  const build = thisRuntime();
  const note = buildNote(build);
  log(note.level === "ok" ? note.text : `! ${note.text}`);

  const dir = resolve(dirArg);
  let roster = loadRoster(dir);
  // Which company these runs are filed under on the company board, read from
  // the roster's own company.yaml — here, because this is the one process that
  // reads the roster directory (law 3), and said out loud at startup for the
  // same reason the build line above it is: a runtime that files runs under a
  // name nobody chose is the thing this reading exists to stop.
  let company = companyFor(dir);
  log(company.name ? company.note : `! ${company.note}`);
  const cfg = temporalEnv();
  const port = Number(process.env.EPITO_PORT) || DEFAULT_PORT;
  const secret = process.env.EPITO_HOOK_SECRET || "";

  // What this box is short of, said BEFORE the engine is touched.
  //
  // `epito run <dir> --dry-run` is the rehearsal an operator runs on the box
  // between pasting the env file and starting the units, and it reported the
  // schedules it would register and nothing at all about the names the seats
  // will be short of — while the runtime drops a name this box does not hold
  // (src/lib/runenv.js) and runs the seat anyway, so the first evidence was a
  // seat that exited 0 having quietly done less. `epito env <dir>` answers
  // this in full, and is a second command an operator has to know exists.
  //
  // Above the connect, so the one box that cannot reach its engine — the box
  // most likely to be half-provisioned — still gets the half of the rehearsal
  // that needs no engine at all.
  //
  // It REPORTS and never refuses, including for a name set to nothing, which
  // `epito env` does exit 1 over. The reason is that this command is the
  // runtime: the real `epito run` injects that empty value and runs the seat,
  // so a rehearsal that refused what the thing it rehearses accepts would be
  // lying about the box in the more expensive direction.
  sayShortfall(roster, dirArg, log);

  const { client, connection } = await connect();
  // A dry run writes nothing to the ledger, and the guard is HERE rather than
  // three lines down because that is where it used to be: `epito run <dir>
  // --dry-run` reconciled nothing on the engine, said "would create", and
  // then appended one `reconcile.start` and one `schedule.create` per seat
  // anyway. The ledger is append-only and is the answer to "what exactly
  // happened" (ADR-22), so four lines claiming four schedules that do not
  // exist are not noise — they are a record that cannot be corrected, written
  // by the one flag whose whole promise is that it touches nothing.
  const record = dryRun ? () => {} : appendAudit;
  // `build` on the ledger line too: the audit is the answer to "what exactly
  // happened" (ADR-22), and for four weeks it could not answer "under which
  // revision of the runtime".
  record({ agent: null, action: "reconcile.start", dir, address: cfg.address, namespace: cfg.namespace, queue: cfg.taskQueue, build: buildLine(build) });
  const plan = await reconcile({ client, roster, company: company.name, dryRun, log: (m) => log(m) });
  for (const k of ["create", "update", "delete"]) {
    for (const s of plan[k]) record({ agent: s.name, action: `schedule.${k}`, schedule: s.id, cron: s.shape?.cron ?? null });
  }
  if (dryRun) {
    // The rehearsal covers the bus as well as the clock, because a seat whose
    // only trigger is a subscription is invisible in a schedule plan: the
    // engine has nothing to register for it, and "0 schedules" on a roster of
    // event-driven seats reads as a roster that does nothing.
    const rehearse = { cfg: busEnv(), seats: subscribingSeats(roster) };
    if (rehearse.seats.length && !rehearse.cfg.stream) log(`! ${busOffSays(rehearse.seats)}`);
    else if (rehearse.seats.length) {
      try {
        const conn = await connectBus({ url: rehearse.cfg.url, name: "epito-run-dry" });
        const plan = await reconcileConsumers({ bus: conn, cfg: rehearse.cfg, seats: rehearse.seats, log: (m) => log(m), dryRun: true });
        for (const c of plan.unchanged) log(`consumer ${c.durable} on ${rehearse.cfg.stream} is already what ${c.name}'s manifest asks for`);
        for (const d of plan.dead) log(`! ${d.name} subscribes to ${d.subject}, which stream ${rehearse.cfg.stream} does not carry (it carries ${plan.streamSubjects.join(", ")}) — nothing will ever arrive on it`);
        conn.close();
      } catch (e) { log(`! the bus would not be consumed (${e.message})`); }
    }
    await connection.close().catch(() => {});
    log(`dry run: nothing was registered on the engine or the bus, and nothing was written to ${AUDIT_PATH}`);
    return;
  }

  // --- starting and signalling ---------------------------------------------

  // The arguments every workflow of this seat carries. The manifest snapshot
  // travels with the run (law 3); the worker never reads <dir>.
  const seatArgs = (name, extra) => ({
    name, manifest: roster.get(name).manifest, company: company.name,
    runTimeoutMs: cfg.runTimeoutMs, ...extra,
  });

  // A seat's ingress-triggered runs all share one workflow id, so this either
  // starts the run or hands the trigger to the run already going. That is
  // v0's coalescing, expressed once, by the engine.
  async function startOrFollowUp(name, trigger, payload) {
    // One token per trigger. signalWithStart delivers the signal even when it
    // is the call that starts the workflow, so the run needs a way to know
    // that the first followUp it sees IS the trigger it was started with.
    const args = seatArgs(name, { trigger, payload, token: randomUUID() });
    // Asked before, only so the answer can say which of the two happened.
    // A run that ends in this gap costs a wrong word in the 202 body — and,
    // until the retry below, cost the whole request: the signal landed on an
    // execution that had just closed and the ingress answered 500 with
    // Temporal's own sentence in it.
    const before = await client.workflow.getHandle(runId(name)).describe().catch(() => null);
    const wasRunning = before?.status?.name === "RUNNING";
    const send = () => client.workflow.signalWithStart("SeatRun", {
      workflowId: runId(name),
      taskQueue: cfg.taskQueue,
      workflowRunTimeout: cfg.runTimeoutMs,
      args: [args],
      signal: "followUp",
      signalArgs: [args],
    });
    // The run may end underneath us. Say so, and start the fresh one the
    // caller asked for — dropping a message here would lose something a
    // person said, which this runtime does not do.
    const { handle, raced } = await sendOrRestart(send, () =>
      log(`${name}: the run ended as the ${trigger} arrived — starting a fresh run for it`));
    if (wasRunning && !raced) log(`${name}: ${trigger} while running — coalesced into the run in flight`);
    return { outcome: wasRunning && !raced ? "coalesced" : "started", workflow: handle.workflowId };
  }

  async function openWindow(name, { text, ttlMs }) {
    const instruction = [windowInstruction(new Date(Date.now() + ttlMs).toISOString()), text].filter(Boolean).join("\n\n");
    try {
      const h = await client.workflow.start("SeatWindow", {
        workflowId: windowId(name),
        taskQueue: cfg.taskQueue,
        args: [seatArgs(name, { ttlMs, agenda: text ?? null, instruction })],
      });
      log(`${name}: window.open (${h.workflowId})`);
      return { agent: name, outcome: "opened", expiresAt: new Date(Date.now() + ttlMs).toISOString() };
    } catch (e) {
      if (e.name !== ALREADY_STARTED) throw e;
      await client.workflow.getHandle(windowId(name)).signal("refresh", ttlMs);
      log(`${name}: window already open — deadline moved`);
      return { agent: name, outcome: "refreshed", expiresAt: new Date(Date.now() + ttlMs).toISOString() };
    }
  }

  async function closeWindow(name) {
    const h = client.workflow.getHandle(windowId(name));
    const desc = await h.describe().catch(() => null);
    if (!desc || desc.status.name !== "RUNNING") return { agent: name, outcome: "not open" };
    await h.signal("close");
    log(`${name}: window.close (requested)`);
    return { agent: name, outcome: "closed", reason: "requested" };
  }

  // Is a window holding a session for this seat right now? The window workflow
  // itself answers, because it is the thing that knows.
  async function heldSession(name) {
    try {
      const h = client.workflow.getHandle(windowId(name));
      const desc = await h.describe();
      if (desc.status.name !== "RUNNING") return null;
      const st = await h.query("state");
      return st?.session ?? null;
    } catch { return null; }
  }

  // Scope is "all" (or absent) or a comma-separated list of [agent].name
  // values. It matches on names only: the manifest spec has no tag field and inventing
  // a tag field to group by is somebody else's pitch.
  function resolveScope(scope) {
    if (scope === undefined || scope === null || scope === "" || scope === "all" || scope === "*") return { names: [...roster.keys()] };
    const wanted = (Array.isArray(scope) ? scope : String(scope).split(",")).map((x) => String(x).trim()).filter(Boolean);
    if (!wanted.length) return { error: `scope is empty — use "all", or a comma-separated list of agent names (this roster: ${[...roster.keys()].join(", ")})` };
    const unknown = wanted.filter((n) => !roster.has(n));
    if (unknown.length) return { error: `scope names no agent in this roster: ${unknown.join(", ")} — use "all", or a comma-separated list of agent names (this roster: ${[...roster.keys()].join(", ")})` };
    return { names: [...new Set(wanted)] };
  }

  // --- the ingress ---------------------------------------------------------

  const server = startHookServer({
    port, secret, log,
    onHealth: async () => {
      try { await connection.workflowService.getSystemInfo({}); return { ok: true, temporal: cfg.address, namespace: cfg.namespace }; }
      catch (e) { return { ok: false, error: `Temporal at ${cfg.address} is not answering (${e.cause?.code ?? e.message}) — triggers will be refused until it is back` }; }
    },
    onRequest: async ({ route, name, raw, json, query }) => {
      // The board is the one surface that is not about a workflow, which is
      // why it is served here and not through Temporal: a seat that runs in
      // GitHub Actions has no workflow on this engine and still has a run
      // report to file. The roster does not gate it either — the board holds
      // the reports of seats this runtime has never hosted, and that is the
      // point of there being one board.
      if (route === "board.write") {
        let event;
        try { event = appendBoard({ ...json, source: json.source ?? "ingress" }); }
        catch (e) { return { status: 400, body: { error: e.message } }; }
        log(`${event.agent}: ${event.kind} filed on the board${event.pr ? ` (${event.pr})` : ""}`);
        return { status: 202, body: { filed: event } };
      }

      if (route === "board.read") {
        const { events, unreadable } = readBoard();
        const fold = foldBoard(events, {
          agent: query.agent || null,
          kind: query.kind || null,
          limit: Number(query.limit) > 0 ? Number(query.limit) : 20,
        });
        if (query.format === "text") return { status: 200, text: renderBoard(fold, { unreadable }) };
        return { status: 200, body: { ...fold, unreadable, path: BOARD_PATH } };
      }

      if ((route === "hook" || route === "message") && !roster.has(name)) {
        return { status: 404, body: { error: `no agent named "${name}" in this roster — it hosts: ${[...roster.keys()].join(", ")}` } };
      }

      // Spec rule 3: triggers are explicit and never defaulted. Until this
      // check existed the ingress woke ANY rostered seat, so a seat that
      // declared only `cron = "0 6 * * *"` — deliberately a scheduled seat,
      // and nothing else — had a live hook endpoint it never asked for, and
      // `[trigger].webhook` was decoration. The refusal is 403 rather than
      // 404 on purpose: the seat exists, and saying otherwise would make a
      // misconfigured manifest look like a typo in the URL.
      if (route === "hook" && roster.get(name).manifest.trigger?.webhook !== true) {
        const cron = roster.get(name).manifest.trigger?.cron;
        appendAudit({ agent: name, action: "hook", trigger: "hook", bytes: raw.length, refused: "no-webhook-trigger" });
        log(`${name}: hook refused — the manifest does not declare [trigger].webhook`);
        return { status: 403, body: { error: `"${name}" does not declare [trigger].webhook, so the ingress may not wake it — a trigger is explicit and never defaulted (spec ${SPEC_VERSION} rule 3). ${cron ? `It runs on its schedule, ${cron} UTC.` : "It has no trigger this runtime can fire at all."} Fix: add \`webhook = true\` under [trigger] in its agent.toml and restart \`epito run\`.` } };
      }

      if (route === "hook") {
        appendAudit({ agent: name, action: "hook", trigger: "hook", bytes: raw.length });
        const r = await startOrFollowUp(name, "hook", { hookBody: raw || undefined });
        return { status: 202, body: { agent: name, ...r } };
      }

      if (route === "message") {
        const text = typeof json.text === "string" ? json.text.trim() : "";
        if (!text) return { status: 400, body: { error: `a message needs {"text": "..."} — an empty message gives the agent nothing to answer` } };
        const session = await heldSession(name);
        if (session !== null) {
          // heldSession() asked whether the window was RUNNING; this signals
          // it. Closing is what a window does, and the ingress holds no lock
          // on it, so the two can straddle the close — and a signal that lands
          // after it means there was no held session after all. Fall through
          // to a fresh run, which is what "no window" has always meant here.
          // Before this, the request answered 500 with Temporal's own sentence
          // and the message was gone.
          const delivered = await client.workflow.getHandle(windowId(name)).signal("message", text)
            .then(() => true)
            .catch((e) => { if (justCompleted(e)) return false; throw e; });
          if (delivered) {
            appendAudit({ agent: name, action: "message", trigger: "message", bytes: text.length, held: true, session });
            log(`${name}: message delivered into held session ${session.slice(0, 8)}`);
            return { status: 202, body: { agent: name, outcome: "delivered", held: true, session } };
          }
          log(`${name}: the window closed as the message arrived — starting a fresh run for it`);
        }
        appendAudit({ agent: name, action: "message", trigger: "message", bytes: text.length, held: false });
        const r = await startOrFollowUp(name, "message", { text });
        return { status: 202, body: { agent: name, ...r, held: false, session: null,
          note: "no session is held for this agent, so the message starts a fresh run — open a window first to be answered in context" } };
      }

      const r = resolveScope(json.scope);
      if (r.error) return { status: 400, body: { error: r.error } };

      if (route === "window.open") {
        const ttlMs = Number(json.ttl_ms) > 0 ? Number(json.ttl_ms) : cfg.windowMs;
        const text = typeof json.text === "string" && json.text.trim() ? json.text.trim() : null;
        const windows = [];
        for (const n of r.names) windows.push(await openWindow(n, { text, ttlMs }));
        return { status: 202, body: { scope: json.scope ?? "all", windows } };
      }

      const windows = [];
      for (const n of r.names) windows.push(await closeWindow(n));
      return { status: 200, body: { scope: json.scope ?? "all", windows } };
    },
  });

  // --- the bus ------------------------------------------------------------
  //
  // One durable consumer per subscribing seat, and `wake` is the contract the
  // whole feature rests on: it resolves when the seat's run has STARTED, and
  // only then does the loop acknowledge the event. Everything that can refuse
  // a start — a dead engine, a worker that is not polling — leaves the event
  // unacknowledged and in the stream.
  //
  // It is wired AFTER the ingress is listening and it never stops the command:
  // a box whose bus is down still serves hooks, still runs its schedules, and
  // says per seat what it cannot be woken by. The bus is a trigger, and a
  // missing trigger is not a reason to take the other two away.
  const bus = { cfg: busEnv(), seats: subscribingSeats(roster), conn: null, loop: null, firstEvent: true };
  async function wireBus() {
    bus.seats = subscribingSeats(roster);
    if (!bus.seats.length) return;
    if (!bus.cfg.stream) { log(`! ${busOffSays(bus.seats)}`); return; }
    try {
      bus.conn = await connectBus({ url: bus.cfg.url, name: `epito-run-${process.pid}` });
      const plan = await reconcileConsumers({ bus: bus.conn, cfg: bus.cfg, seats: bus.seats, log });
      for (const k of ["create", "update"]) {
        for (const c of plan[k]) appendAudit({ agent: c.name, action: `bus.consumer.${k}`, stream: bus.cfg.stream, consumer: c.durable, subjects: c.subjects });
      }
      for (const d of plan.dead) {
        log(`! ${d.name} subscribes to ${d.subject}, which stream ${bus.cfg.stream} does not carry (it carries ${plan.streamSubjects.join(", ")}) — nothing will ever arrive on it. Fix: correct the subject, or widen the stream.`);
      }
      bus.loop = startConsuming({
        bus: bus.conn, cfg: bus.cfg, seats: bus.seats, log,
        wake: async (name, ev) => startOrFollowUp(name, "bus", { hookBody: ev.data }),
        onEvent: (name, ev, started) => {
          appendAudit({ agent: name, action: "bus.event", stream: bus.cfg.stream, consumer: durableFor(bus.cfg.group, name), subject: ev.subject, event: ev.id, streamSeq: ev.streamSeq, delivery: ev.delivery, outcome: started.outcome });
          log(`${name}: run ${started.outcome} (${started.workflow}) — event acknowledged`);
          // The first event this runtime ever takes off the stream is the
          // moment the bus stops being a person forwarding messages by hand,
          // and the board is where the owner reads it. Once, not per event:
          // the ledger holds every one of them (`epito audit --action bus`).
          if (bus.firstEvent) {
            bus.firstEvent = false;
            try { appendBoard({ kind: "note", agent: name, text: `woken by the bus: ${ev.subject} from stream ${bus.cfg.stream}, the first event this runtime consumed`, source: "bus" }); }
            catch (e) { log(`${name}: the board refused the note about the first bus event (${e.message})`); }
          }
        },
        onError: (name, e) => appendAudit({ agent: name, action: "bus.refused", stream: bus.cfg.stream, consumer: durableFor(bus.cfg.group, name), detail: e.message }),
      });
      log(`the bus is live: ${bus.seats.length} consumer${bus.seats.length === 1 ? "" : "s"} on ${bus.cfg.stream} at ${bus.cfg.url}, acknowledged when a run starts (\`epito bus ${dirArg}\` is the report)`);
    } catch (e) {
      // Named, not fatal, and said per seat: these seats are the ones that
      // will not be woken until this is fixed.
      log(`! the bus is not consuming (${e.message})`);
      log(`! until it is, ${bus.seats.map((s) => s.name).join(", ")} ${bus.seats.length === 1 ? "is" : "are"} woken only by what else ${bus.seats.length === 1 ? "its manifest declares" : "their manifests declare"}; events stay in the stream and are redelivered when it comes back`);
    }
  }
  await wireBus();

  log(`epito run: ${roster.size} seat${roster.size === 1 ? "" : "s"} from ${dir}; audit=${AUDIT_PATH}; board=${BOARD_PATH}`);
  for (const [name, a] of roster) log(`  ${name}: repo=${a.manifest.runtime.repo} model=${a.manifest.runtime.model} cron=${a.manifest.trigger.cron ?? "-"}`);
  log(`windows default to ${Math.round(cfg.windowMs / 60000)} minutes (EPITO_WINDOW_MS)`);
  log(`the work happens in the worker: \`epito worker\` on queue ${cfg.taskQueue} (systemd: epitod-worker.service)`);
  if (!secret) log("EPITO_HOOK_SECRET is not set: the ingress answers 503 until it is");

  // SIGHUP: a seat was added, removed, or had its cron changed. Re-read and
  // reconcile without dropping the ingress or touching work in flight.
  process.on("SIGHUP", async () => {
    log("SIGHUP: re-reading the roster and reconciling");
    try {
      roster = loadRoster(dir);
      // A seat added without a restart is the whole point of SIGHUP, and a
      // seat added without a restart is also the likeliest one to name a
      // variable this box has never held: the startup block ran before that
      // manifest existed. Said again, against the roster that is now in force.
      sayShortfall(roster, dirArg, log);
      // Re-read on the same signal: company.yaml is a file in the same
      // repository the roster is, so a `git pull` that adds a seat is also the
      // moment the product gets renamed. Re-registering schedules against a
      // stale company name is the drift this line costs one stat to avoid.
      company = companyFor(dir);
      log(company.name ? company.note : `! ${company.note}`);
      const p = await reconcile({ client, roster, company: company.name, log: (m) => log(m) });
      for (const k of ["create", "update", "delete"]) {
        for (const s of p[k]) appendAudit({ agent: s.name, action: `schedule.${k}`, schedule: s.id, cron: s.shape?.cron ?? null });
      }
      // A seat added without a restart may be a seat the bus wakes, so the
      // consumers are reconciled on the same signal as the schedules. The
      // loops in flight are stopped first: two loops on one durable would
      // both pull, and the second one's events would wait on the first's
      // acknowledgement for no reason.
      if (bus.loop) await bus.loop.stop();
      if (bus.conn) bus.conn.close();
      bus.conn = null; bus.loop = null;
      await wireBus();
    } catch (e) { log(`SIGHUP: reconcile failed (${e.message}); the previous roster stays in force`); }
  });

  const shutdown = async (sig) => {
    log(`${sig}: shutting down the ingress (schedules and runs in flight are the engine's, and stay)`);
    server.close();
    // The bus is let go without acknowledging anything in flight, on purpose:
    // an event whose run had not started is redelivered to the next runtime,
    // which is the promise this whole door exists to keep.
    if (bus.loop) await bus.loop.stop();
    if (bus.conn) bus.conn.close();
    appendAudit({ agent: null, action: "ingress.stop", signal: sig });
    await connection.close().catch(() => {});
    setTimeout(() => process.exit(0), 200);
  };
  process.on("SIGINT", () => shutdown("SIGINT"));
  process.on("SIGTERM", () => shutdown("SIGTERM"));
  await new Promise(() => {}); // resident: only a signal ends this
}

// --- the client side of the ingress ---------------------------------------
// `epito message` / `epito window` / `epito report` are thin: they POST to the
// ingress this shell can see (EPITO_HOST, EPITO_PORT, EPITO_HOOK_SECRET), so
// neither an operator on the host nor a CI job somewhere else ever has to
// hand-write a curl with a secret in it.
export async function callIngress(path, body) {
  const secret = process.env.EPITO_HOOK_SECRET || "";
  if (!secret) { console.error("epito: EPITO_HOOK_SECRET is not set in this shell — the ingress needs it, and it is the same value `epito run` was started with"); process.exit(1); }
  const port = Number(process.env.EPITO_PORT) || DEFAULT_PORT;
  const host = process.env.EPITO_HOST || `http://127.0.0.1:${port}`;
  let res;
  try {
    res = await fetch(`${host}${path}`, { method: "POST", headers: { "content-type": "application/json", "x-epito-secret": secret }, body: JSON.stringify(body) });
  } catch (e) { console.error(`epito: no ingress answering at ${host} (${e.cause?.code ?? e.message}) — is \`epito run\` up, and is EPITO_PORT right?`); process.exit(1); }
  const text = await res.text();
  let out; try { out = JSON.parse(text); } catch { out = { raw: text }; }
  if (!res.ok) { console.error(`epito: ${out.error ?? text.trim()}`); process.exit(1); }
  return out;
}

const shortSession = (id) => (id ? id.slice(0, 8) : null);

export async function message(name, text) {
  if (!name || !text) { console.error(`epito: message needs an agent and words — \`epito message <name> "..."\``); process.exit(1); }
  const out = await callIngress(`/message/${name}`, { text });
  console.log(out.held ? `${out.agent}: ${out.outcome} in held session ${shortSession(out.session)}` : `${out.agent}: ${out.outcome} as a fresh run (no session held)`);
}

export async function windowCmd(action, scope, text) {
  if (action !== "open" && action !== "close") { console.error(`epito: window takes open or close — \`epito window open [scope]\``); process.exit(1); }
  const out = await callIngress(`/window/${action}`, { ...(scope ? { scope } : {}), ...(text ? { text } : {}) });
  for (const w of out.windows) console.log(`${w.agent}: ${w.outcome}${w.expiresAt ? ` until ${w.expiresAt}` : ""}`);
}
