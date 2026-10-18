// The bus: how an event that happened somewhere else wakes a seat here, and
// survives everything in between.
//
// The ingress already had a door — POST /message/<name> — and what it lacks is
// memory: a message delivered while the runtime is down is gone, and nothing
// anywhere knows it was meant for a seat. That is what the company's chair
// handed this seat on 2026-10-16: the events all pass through a NATS JetStream
// stream now, so the runtime should hold a durable consumer per seat and
// acknowledge an event only once the seat's run has STARTED. Then a restart
// costs nothing and an event is redelivered until a seat takes it.
//
// "Started" was read as "Temporal accepted the workflow" until 2026-10-18,
// when a day's measurement showed that the failure that actually happens —
// a model provider refusing the run — lands after that point and threw 65
// events away. It now means "the provider did not refuse it before a first
// turn", which is startConsuming's contract below and the only line of this
// file that changed shape.
//
// The shape of it mirrors the schedules, deliberately (src/temporal/
// schedules.js): a roster is reconciled onto the bus at startup and on SIGHUP,
// which is idempotent, so a restart reconciles rather than duplicates.
import { subjectsOverlap } from "./subjects.js";
import { refusalNakMs, refusalSays, humanMs } from "./refusal.js";

export const DEFAULT_BUS_URL = "nats://127.0.0.1:4222";
export const DEFAULT_GROUP = "epito";
export const DEFAULT_ACK_WAIT_MS = 30_000;
export const DEFAULT_NAK_MS = 15_000;
// How long the loop will hold one event unacknowledged while it waits to
// learn whether the provider took the run or refused it. Two minutes because
// the provider call is behind a clone, and a cold clone of a large repository
// is the slow half; a refusal itself lands in seconds. Past it the event is
// acknowledged, which is what this runtime did from the first line of code —
// the window only ever buys back the case it can prove.
export const DEFAULT_REFUSAL_WINDOW_MS = 120_000;

// Where the bus is, which stream carries the events, and under what name this
// roster's consumers live. All three are facts about the BOX, never fields in
// a manifest — the same rule that keeps the engine's address, the interpreter
// and the container image out of a publishable file (spec v0.2).
//
// `stream` has no default on purpose. A default would have to be this
// company's own stream name, and a product whose runtime silently looks for
// ASC_EVENTS on every customer's box is a product with our roster baked into
// it. Unset means the bus is off, said out loud, per seat that subscribes.
export function busEnv(env = process.env) {
  return {
    url: env.EPITO_BUS_URL || DEFAULT_BUS_URL,
    stream: env.EPITO_BUS_STREAM || null,
    group: env.EPITO_BUS_GROUP || DEFAULT_GROUP,
    ackWaitMs: Number(env.EPITO_BUS_ACK_WAIT_MS) || DEFAULT_ACK_WAIT_MS,
    nakDelayMs: Number(env.EPITO_BUS_NAK_MS) || DEFAULT_NAK_MS,
    refusalWindowMs: Number(env.EPITO_BUS_REFUSAL_WINDOW_MS) || DEFAULT_REFUSAL_WINDOW_MS,
    batch: Number(env.EPITO_BUS_BATCH) || 1,
  };
}

// One durable per seat, named for the group and the seat, so every consumer on
// the server reads as a sentence about an agent — the rule the workflow ids
// already follow. The group is what lets two rosters read one stream without
// fighting over one position in it.
export const durableFor = (group, seat) => `${group}-${seat}`;
export const seatOfDurable = (group, durable) =>
  durable.startsWith(`${group}-`) ? durable.slice(group.length + 1) : null;

// The seats this roster asks the bus for, in roster order.
export function subscribingSeats(roster) {
  const out = [];
  for (const [name, { manifest }] of roster) {
    const subjects = manifest.trigger?.subscriptions ?? [];
    if (subjects.length) out.push({ name, subjects: [...subjects] });
  }
  return out;
}

// What one seat's consumer must look like. Every line of it is a promise this
// runtime makes somewhere else:
//
//   ack_policy explicit + ack_wait   an event is acknowledged by the runtime
//                                    once the run starts, and by nobody and
//                                    nothing otherwise
//   max_deliver -1                   redelivered until a seat takes it
//   deliver_policy all               a consumer created today still sees what
//                                    the stream was holding yesterday; an
//                                    event is not lost because the seat was
//                                    added after it was published
//   max_ack_pending = batch          one event at a time per seat, in order:
//                                    an event the seat could not take blocks
//                                    the ones behind it rather than being
//                                    skipped, because skipping is the failure
//                                    this whole feature exists to remove
export function consumerConfig({ durable, subjects, ackWaitMs = DEFAULT_ACK_WAIT_MS, batch = 1, seat }) {
  const cfg = {
    durable_name: durable,
    name: durable,
    description: `epito: wakes the ${seat} seat`,
    ack_policy: "explicit",
    ack_wait: ackWaitMs * 1e6,
    max_deliver: -1,
    deliver_policy: "all",
    replay_policy: "instant",
    max_ack_pending: Math.max(1, batch),
  };
  // One subject is written the way every server since 2.2 understands it; a
  // list needs 2.10's `filter_subjects`, which is also when the server started
  // refusing two filters that overlap — the refusal `epito validate` now makes
  // first, where the author can still read it.
  if (subjects.length === 1) cfg.filter_subject = subjects[0];
  else cfg.filter_subjects = [...subjects];
  return cfg;
}

// Is this consumer already the one the manifest asks for? Compared on the
// fields the manifest owns, not on the whole config: the server fills in a
// dozen defaults and a reconcile that diffed all of them would rewrite every
// consumer on every restart.
export function consumerMatches(existing, want) {
  if (!existing) return false;
  const have = [existing.filter_subject, ...(existing.filter_subjects ?? [])].filter(Boolean).sort();
  const asked = [want.filter_subject, ...(want.filter_subjects ?? [])].filter(Boolean).sort();
  return have.join("\n") === asked.join("\n")
    && existing.ack_policy === want.ack_policy
    && existing.ack_wait === want.ack_wait
    && existing.max_deliver === want.max_deliver;
}

const NO_STREAM = 10059;      // the server's code for "stream not found"

// Make the bus match the roster. Returns what changed, in reconcile()'s own
// shape, so `epito run`'s startup lines and the ledger read the same for a
// consumer as they do for a schedule.
export async function reconcileConsumers({ bus, cfg, seats, log = () => {}, dryRun = false }) {
  const plan = { create: [], update: [], unchanged: [] };
  let stream;
  try { stream = await bus.api(`STREAM.INFO.${cfg.stream}`); }
  catch (e) {
    if (e.code === NO_STREAM) {
      const err = new Error(`the bus at ${cfg.url} has no stream named ${cfg.stream}, so there is nothing for ${seats.length === 1 ? "this seat" : "these seats"} to be woken by: ${seats.map((s) => s.name).join(", ")}. Fix: create it (\`nats stream add ${cfg.stream}\`) with the subjects these seats subscribe to, or point EPITO_BUS_STREAM at the stream that already carries them.`);
      err.epitoHandled = true;
      throw err;
    }
    throw e;
  }
  for (const seat of seats) {
    const durable = durableFor(cfg.group, seat.name);
    const want = consumerConfig({ durable, subjects: seat.subjects, ackWaitMs: cfg.ackWaitMs, batch: cfg.batch, seat: seat.name });
    let existing = null;
    try { existing = (await bus.api(`CONSUMER.INFO.${cfg.stream}.${durable}`)).config; }
    catch (e) { if (e.status !== 404) throw e; }
    const where = { name: seat.name, durable, subjects: seat.subjects };
    if (consumerMatches(existing, want)) { plan.unchanged.push(where); continue; }
    const verb = existing ? "update" : "create";
    plan[verb].push(where);
    if (dryRun) { log(`would ${verb} consumer ${durable} on ${cfg.stream} for ${seat.name}: ${seat.subjects.join(", ")}`); continue; }
    await bus.api(`CONSUMER.CREATE.${cfg.stream}.${durable}`, { stream_name: cfg.stream, config: want, action: existing ? "update" : "create" });
    log(`${seat.name}: consumer.${verb} ${durable} on ${cfg.stream} — ${seat.subjects.join(", ")}`);
  }
  // A seat's subscription that no subject of the stream can ever carry is a
  // seat waiting for a bell nobody will ring. The stream says which subjects
  // it accepts, so this is answerable here and nowhere else — and it is a
  // warning rather than a refusal, because the stream may be widened tomorrow
  // and the roster is not wrong to be ready for it.
  const streamSubjects = stream.config.subjects ?? [];
  plan.dead = seats.flatMap((s) =>
    s.subjects.filter((subj) => !streamSubjects.some((ss) => subjectsOverlap(ss, subj)))
      .map((subj) => ({ name: s.name, subject: subj })));
  plan.streamSubjects = streamSubjects;
  return plan;
}

// One event, as the runtime talks about it. The payload is JSON when the
// publisher is the board, and is not required to be: a text event still wakes
// the seat, because refusing to deliver what we cannot parse would make the
// runtime the judge of another company's payloads.
export function readEvent(msg) {
  let body = null;
  try { body = JSON.parse(msg.data); } catch { /* not JSON, and that is allowed */ }
  return {
    subject: msg.subject,
    id: msg.headers?.["Nats-Msg-Id"] ?? body?.id ?? null,
    type: body?.type ?? null,
    company: body?.company ?? null,
    actor: body?.actor ?? null,
    target: body?.target ?? null,
    streamSeq: msg.meta?.streamSeq ?? null,
    delivery: msg.meta?.delivered ?? 1,
    pending: msg.meta?.pending ?? 0,
    data: msg.data,
    body,
  };
}

// One line about an event, for the run log and the board. It names the subject
// and the seat and nothing from the payload: an event body is another
// company's text and the runtime does not quote it into a log.
export const eventSays = (seat, ev) => {
  const where = [
    ev.streamSeq ? `stream seq ${ev.streamSeq}` : null,
    ev.delivery > 1 ? `delivery ${ev.delivery}` : null,
  ].filter(Boolean).join(", ");
  return `${seat}: bus event ${ev.subject}${where ? ` (${where})` : ""}`;
};

// Hold the event alive while we wait for an answer. JetStream will hand the
// same message out again once ack_wait passes, so a loop that waits longer
// than that without saying "still working" wakes the seat twice for one
// event. `working` is optional on the bus object: the unit suite's fake
// stream does not have it, and neither does an older client.
async function whileDeciding(bus, msg, cfg, work) {
  const every = Math.max(250, Math.floor((cfg.ackWaitMs ?? DEFAULT_ACK_WAIT_MS) / 2));
  const beat = setInterval(() => { try { bus.working?.(msg); } catch { /* the ack deadline is best-effort */ } }, every);
  try { return await work(); }
  finally { clearInterval(beat); }
}

// The consume loop, one per seat, each pulling one event at a time.
//
// `wake(name, event, raw)` is the runtime's own start path, and the contract
// is the whole feature: it RESOLVES once the seat's run has started, and then
// and only then is the event acknowledged. If it throws — a dead engine, a
// worker that is not polling, anything — the event is negatively acknowledged
// with a delay and comes back. Nothing here swallows an error quietly: the
// loop logs what refused the start, by name, every time it comes round.
//
// WHERE "STARTED" IS, and why it moved (2026-10-18, exo's incident 8). It
// used to be "Temporal accepted the workflow", which `wake` reaches in
// milliseconds and which almost never fails — so the one failure that
// actually happens, a model provider refusing the run, always landed AFTER
// the acknowledgement, inside a workflow the loop had already counted as
// started. 65 events went that way in one day; 37 of their runs had not taken
// a single turn and none of the 65 opened a pull request, so there was
// nothing to duplicate and nothing to keep. They were simply gone.
//
// So `wake` may now hand back a `verdict()` — a function returning a promise
// that answers the one question the acknowledgement actually turns on:
//
//   { refusal }   a resource refused the run before a first turn. NAK, with
//                 the delay read from the reset time the refusal named in its
//                 own words, so the event comes back when capacity does and
//                 not fifteen seconds from now.
//   anything else acknowledge, exactly as before.
//
// A `wake` that returns no `verdict` is acknowledged the moment it resolves,
// which is every other caller and every older one.
export function startConsuming({ bus, cfg, seats, wake, log = () => {}, onEvent = () => {}, onError = () => {}, onRefused = () => {} }) {
  let running = true;
  const loops = seats.map(async (seat) => {
    const durable = durableFor(cfg.group, seat.name);
    while (running) {
      let batch = [];
      try { batch = await bus.fetch({ stream: cfg.stream, consumer: durable, batch: cfg.batch, expiresMs: 20_000 }); }
      catch (e) {
        if (!running) return;
        onError(seat.name, e);
        log(`${seat.name}: the bus pull failed (${e.message}) — retrying in 5s; events stay in the stream until a run takes them`);
        await sleep(5000, () => running);
        continue;
      }
      // An empty batch is the ordinary case: the server held the pull open for
      // its whole expiry and nothing arrived. The pause is insurance rather
      // than pacing — a bus that answered "nothing for you" instantly and
      // forever would otherwise spin this loop at microtask speed and starve
      // every timer in the process, which is precisely what it did the first
      // time a fake stream in the unit suite answered that way.
      if (!batch.length) { await sleep(50, () => running); continue; }
      for (const msg of batch) {
        if (!running) return;
        const ev = readEvent(msg);
        log(`${eventSays(seat.name, ev)} — starting the run`);
        try {
          const started = await wake(seat.name, ev, msg);
          // Asking must never un-start a run. If the question itself fails —
          // the engine blinked, the query was rejected — the event is
          // acknowledged as it always was, because a run IS in flight and a
          // redelivery would make a second one.
          let verdict = null;
          if (typeof started?.verdict === "function") {
            try { verdict = await whileDeciding(bus, msg, cfg, () => started.verdict()); }
            catch (e) { log(`${seat.name}: the run was started and could not be asked how the provider answered (${e.message}) — acknowledging the event, because a run is in flight`); }
          }
          if (verdict?.refusal) {
            const delay = refusalNakMs(verdict.refusal, { delivery: ev.delivery });
            bus.nak(msg, delay);
            onRefused(seat.name, ev, verdict.refusal, delay, started);
            log(refusalSays(seat.name, verdict.refusal, { delayMs: delay }));
            log(`${seat.name}: the run it was woken for is recorded as refused, not failed — this event is delivery ${ev.delivery} and comes back as delivery ${ev.delivery + 1} in ${humanMs(delay)}`);
            continue;
          }
          bus.ack(msg);
          onEvent(seat.name, ev, started, verdict ?? null);
        } catch (e) {
          bus.nak(msg, cfg.nakDelayMs);
          onError(seat.name, e, ev);
          log(`${seat.name}: the run did not start (${e.message}) — the event is NOT acknowledged and comes back in ${Math.round(cfg.nakDelayMs / 1000)}s (delivery ${ev.delivery} so far)`);
        }
      }
    }
  });
  return {
    stop: async () => { running = false; await Promise.allSettled(loops); },
    done: Promise.allSettled(loops),
  };
}

const sleep = (ms, stillRunning) => new Promise((r) => {
  const t = setTimeout(r, ms);
  if (!stillRunning()) { clearTimeout(t); r(); }
});

// What `epito run` says for a roster that asks for a bus this box has not
// named. The seat would otherwise be a seat that never fires, in silence,
// which is exactly what retired `[trigger].on`.
export function busOffSays(seats) {
  const names = seats.map((s) => s.name).join(", ");
  return `${seats.length} seat${seats.length === 1 ? "" : "s"} subscribe${seats.length === 1 ? "s" : ""} to bus subjects and this box names no stream: ${names}. ` +
    `They will not be woken by any event while EPITO_BUS_STREAM is unset — a cron still fires and the ingress still answers, and a seat whose ONLY trigger is a subscription will do nothing at all. ` +
    `Fix: set EPITO_BUS_STREAM to the stream that carries those subjects (and EPITO_BUS_URL if the bus is not ${DEFAULT_BUS_URL}), then \`epito bus <dir>\` to see what each seat is waiting on.`;
}
