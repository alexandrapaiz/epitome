#!/usr/bin/env node
// The bus, against a real nats-server. The half of the bus that unit-bus.mjs
// cannot reach.
//
//   node test/bus-live.mjs nats://127.0.0.1:4222 epito-smoke
//
// Why a second suite. `src/lib/nats.js` is a NATS client written here, byte by
// byte, because the runtime refuses to drag a dependency into a package whose
// whole claim is half a megabyte installed. unit-bus.mjs proves what this
// code does with a stand-in server it also wrote — which means every
// assumption the client makes about the PROTOCOL is asserted against the same
// assumption. A hand-rolled client is exactly the thing that passes its own
// mock and fails on the wire: a header frame off by two bytes, a JetStream
// reply whose defaults the reconcile then fights with forever, an ack that
// went to the wrong subject and left the event to come back.
//
// So this one asks a real server, and asserts the three promises the spec
// makes about `[trigger].subscriptions` (spec v0.2, "Subscriptions: which
// events wake this seat"):
//
//   1. one durable consumer per seat, filtered to exactly its subjects, and
//      reconciled — the second run of the same roster changes nothing, which
//      is only testable against a server that fills in its own defaults
//   2. an event is acknowledged only once the seat's run has STARTED
//   3. a run that will not start leaves the event unacknowledged, and it is
//      redelivered until one does
//
// It is driven by test/smoke-bus.sh, which owns the server; run by hand it
// takes the URL of any JetStream server you do not mind it writing to. It
// creates one stream, named on the command line, and deletes it on the way out.
import { connectBus } from "../src/lib/nats.js";
import { reconcileConsumers, startConsuming, durableFor, consumerConfig, consumerMatches } from "../src/lib/bus.js";

const url = process.argv[2] ?? "nats://127.0.0.1:4222";
const stream = process.argv[3] ?? "epito-smoke";

let pass = 0, fail = 0;
const ok = (m) => { pass++; console.log(`  ok   ${m}`); };
const bad = (m, detail) => { fail++; console.log(`  FAIL ${m}${detail ? `\n       ${detail}` : ""}`); };
const check = (m, cond, detail) => (cond ? ok(m) : bad(m, detail));
// Sections print under the shell suite that owns this file, so they are
// indented rather than numbered: one run, one sequence of == headings.
const step = (m) => console.log(`\n  -- ${m}`);

// A watchdog, because every failure mode of a wire protocol looks like a wait.
// A suite that hangs is a CI job somebody cancels and nobody reads.
const watchdog = setTimeout(() => {
  console.log("  FAIL the live bus suite did not finish within 90s — something is waiting on the wire");
  process.exit(1);
}, 90_000).unref?.() ?? null;

const cfg = { url, stream, group: "smoke", ackWaitMs: 2000, nakDelayMs: 300, batch: 1 };
const SEATS = [
  { name: "listener", subjects: ["smoke.events.*.issue.opened"] },
  { name: "both", subjects: ["smoke.events.support.run.failed"] },
  { name: "ghost", subjects: ["elsewhere.entirely.>"] },
];

const until = async (what, ms = 10_000) => {
  const deadline = Date.now() + ms;
  while (Date.now() < deadline) {
    if (await what()) return true;
    await new Promise((r) => setTimeout(r, 25));
  }
  return false;
};

const bus = await connectBus({ url, name: "epito-smoke" });
let consuming = null;
try {
  step("the handshake and the stream");
  ok(`connected to ${url} and JetStream answered $JS.API.INFO`);
  await bus.api(`STREAM.CREATE.${stream}`, {
    name: stream, subjects: ["smoke.events.>"], storage: "memory", retention: "limits", max_msgs: 1000,
  });
  const info = await bus.api(`STREAM.INFO.${stream}`);
  check("a stream the suite owns exists, carrying smoke.events.>",
    info.config.subjects.includes("smoke.events.>"), JSON.stringify(info.config.subjects));

  step("one durable per seat, reconciled rather than re-created");
  const plan = await reconcileConsumers({ bus, cfg, seats: SEATS });
  check("the first reconcile creates one consumer per seat", plan.create.length === 3 && plan.unchanged.length === 0,
    `created ${plan.create.length}, unchanged ${plan.unchanged.length}`);
  check("a subject no subject of the stream can carry is reported, not refused",
    plan.dead.length === 1 && plan.dead[0].name === "ghost", JSON.stringify(plan.dead));
  const again = await reconcileConsumers({ bus, cfg, seats: SEATS });
  // The assertion this whole file exists for: consumerMatches compares what
  // the manifest owns against what the SERVER says, and the server answers
  // with a config full of defaults nobody asked for. A mock that echoes back
  // what it was sent can never fail this; a real one did, for every client
  // that ever got it wrong.
  check("the same roster twice changes nothing on the server",
    again.unchanged.length === 3 && again.create.length === 0 && again.update.length === 0,
    `created ${again.create.length}, updated ${again.update.length}, unchanged ${again.unchanged.length}`);

  const durable = durableFor(cfg.group, "listener");
  const live = (await bus.api(`CONSUMER.INFO.${stream}.${durable}`)).config;
  const want = consumerConfig({ durable, subjects: SEATS[0].subjects, ackWaitMs: cfg.ackWaitMs, batch: cfg.batch, seat: "listener" });
  const filters = (c) => [c.filter_subject, ...(c.filter_subjects ?? [])].filter(Boolean).sort();
  check("the consumer the server holds is the one the manifest asked for",
    filters(live).join() === SEATS[0].subjects.join()
      && live.ack_policy === "explicit" && live.ack_wait === want.ack_wait
      && live.max_deliver === -1 && live.durable_name === durable,
    JSON.stringify(live));
  // One subject and two subjects are two different fields on the wire —
  // `filter_subject` since 2.2, `filter_subjects` since 2.10 — and the server
  // answers under whichever one it was given. A reconcile that read only one
  // of them would see a difference that is not there and rewrite every
  // consumer on the box at every startup, which is why consumerMatches reads
  // both and why that is worth asserting against the server rather than
  // against our own idea of it.
  check("one subject travels as filter_subject, and the reconcile recognises its own work",
    live.filter_subject === SEATS[0].subjects[0] && live.filter_subjects === undefined
      && consumerMatches(live, want),
    JSON.stringify({ filter_subject: live.filter_subject, filter_subjects: live.filter_subjects }));

  const widened = [{ name: "listener", subjects: ["smoke.events.*.issue.opened", "smoke.events.*.issue.closed"] }];
  const grown = await reconcileConsumers({ bus, cfg, seats: widened });
  const after = await bus.api(`STREAM.INFO.${stream}`);
  check("a seat whose subjects changed updates its own consumer, and gains no second one",
    grown.update.length === 1 && after.state.consumer_count === 3,
    `updated ${grown.update.length}, consumers on the stream ${after.state.consumer_count}`);
  const twoUp = (await bus.api(`CONSUMER.INFO.${stream}.${durable}`)).config;
  check("...and two subjects travel as the other field, which 2.10 is where the list became legal",
    Array.isArray(twoUp.filter_subjects) && twoUp.filter_subjects.length === 2 && twoUp.filter_subject === undefined,
    JSON.stringify({ filter_subject: twoUp.filter_subject, filter_subjects: twoUp.filter_subjects }));
  check("...and the widened consumer is still one the reconcile would leave alone",
    consumerMatches(twoUp, consumerConfig({ durable, subjects: widened[0].subjects, ackWaitMs: cfg.ackWaitMs, batch: cfg.batch, seat: "listener" })),
    JSON.stringify(twoUp.filter_subjects));
  await reconcileConsumers({ bus, cfg, seats: [SEATS[0]] });   // back to one subject

  step("an event is acknowledged once the run has started — and not before");
  const started = [];
  const refusedOnce = new Set();
  const errors = [];
  consuming = startConsuming({
    bus, cfg, seats: [SEATS[0], SEATS[1]],
    // The runtime's start path, stood in for: it resolves when a run has
    // started, and for one event it throws the way a box with no engine does.
    wake: async (seat, ev) => {
      if (ev.id === "evt-refused" && !refusedOnce.has(ev.id)) {
        refusedOnce.add(ev.id);
        throw new Error("no engine answered: the run did not start");
      }
      started.push({ seat, id: ev.id, subject: ev.subject, delivery: ev.delivery });
      return { workflowId: `${seat}-${ev.id}` };
    },
    onError: (seat, e, ev) => errors.push({ seat, says: e.message, id: ev?.id ?? null }),
  });

  bus.publish("smoke.events.acme.issue.opened", JSON.stringify({ type: "issue.opened", company: "acme" }), {
    headers: { "Nats-Msg-Id": "evt-1" },
  });
  check("the event reaches the seat whose filter matches it, once",
    await until(() => started.some((s) => s.id === "evt-1")),
    JSON.stringify(started));
  const first = started.find((s) => s.id === "evt-1");
  check("...and it reaches that seat and not the other one",
    first?.seat === "listener" && !started.some((s) => s.seat === "both"), JSON.stringify(started));
  check("...and the runtime acknowledged it, so the server holds nothing for that seat",
    await until(async () => {
      const c = await bus.api(`CONSUMER.INFO.${stream}.${durable}`);
      return c.num_pending === 0 && c.num_ack_pending === 0;
    }),
    JSON.stringify(await bus.api(`CONSUMER.INFO.${stream}.${durable}`).then((c) => ({ pending: c.num_pending, ack_pending: c.num_ack_pending }))));

  step("a run that will not start leaves the event in the stream");
  bus.publish("smoke.events.acme.issue.opened", JSON.stringify({ type: "issue.opened" }), {
    headers: { "Nats-Msg-Id": "evt-refused" },
  });
  check("the first attempt refuses, and the loop says what refused it",
    await until(() => errors.some((e) => e.says.includes("no engine answered"))), JSON.stringify(errors));
  check("the event comes back rather than being lost, and the second attempt takes it",
    await until(() => started.some((s) => s.id === "evt-refused"), 15_000), JSON.stringify(started));
  const retried = started.find((s) => s.id === "evt-refused");
  check("...and the runtime knows it is a redelivery, not a new event",
    retried?.delivery >= 2, `delivery ${retried?.delivery}`);
  check("...and once a run started, that one is acknowledged too",
    await until(async () => {
      const c = await bus.api(`CONSUMER.INFO.${stream}.${durable}`);
      return c.num_pending === 0 && c.num_ack_pending === 0 && c.num_redelivered >= 0;
    }), "the consumer still holds an unacknowledged event");

  step("the refusals the library produces against a real server");
  await consuming.stop(); consuming = null;
  let says = "";
  try { await reconcileConsumers({ bus, cfg: { ...cfg, stream: "no-such-stream-here" }, seats: SEATS }); }
  catch (e) { says = e.message; }
  check("a stream this box does not have names the seats and the fix",
    says.includes("no stream named no-such-stream-here") && says.includes("Fix:") && says.includes("listener"), says || "(it did not throw)");

  let refused = "";
  try { await connectBus({ url: "nats://127.0.0.1:1", timeoutMs: 1500 }); }
  catch (e) { refused = e.message; }
  check("a bus that is not there is one sentence naming what it costs and the fix",
    refused.includes("nothing is answering the bus") && refused.includes("Fix:"), refused || "(it connected?)");
} catch (e) {
  bad("the live suite threw before it finished", e.stack ?? String(e));
} finally {
  if (consuming) await consuming.stop();
  try { await bus.api(`STREAM.DELETE.${stream}`); } catch { /* the suite owns it; if it is gone, fine */ }
  bus.close();
  if (watchdog) clearTimeout(watchdog);
}

console.log(`\nbus-live: ${pass} ok, ${fail} failed`);
process.exit(fail ? 1 : 0);
