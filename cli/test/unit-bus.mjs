#!/usr/bin/env node --test
// Unit tests for the bus: the subject grammar, the consumer a manifest asks
// for, and the one promise the whole feature rests on — an event is
// acknowledged when the seat's run has STARTED and at no other moment. Run
// with:
//
//   node --test test/unit-bus.mjs        # from cli/
//
// The end-to-end path is test/smoke-bus.sh, against a real nats-server: a
// consumer created from a manifest, an event published, a seat woken, and the
// same event still there after a start that refused. What is pinned here is
// what cannot be seen from outside — that a failed start NAKs rather than
// acks, that a restart reconciles rather than duplicates, and that every
// refusal a manifest can earn names the subject and the fix.
import { test } from "node:test";
import assert from "node:assert/strict";
import { validateManifest, manifestWarnings } from "../src/lib/manifest.js";
import { subjectErrors, subjectsOverlap } from "../src/lib/subjects.js";
import {
  busEnv, durableFor, seatOfDurable, subscribingSeats, consumerConfig, consumerMatches,
  reconcileConsumers, startConsuming, readEvent, eventSays, busOffSays,
} from "../src/lib/bus.js";
import { parseBusUrl, parseAckSubject, encodeHeaders } from "../src/lib/nats.js";

// --- the subject grammar ---------------------------------------------------

test("a legal subject filter passes, wildcards included", () => {
  for (const s of ["asc.events.asc.message.posted", "asc.events.*.message.posted", "asc.events.>", "a", "a.b-c.d_e"]) {
    assert.deepEqual(subjectErrors(s, "[trigger].subscriptions[0]"), [], s);
  }
});

test("every illegal subject is refused by name, with the fix in the message", () => {
  const cases = [
    ["a..b", /empty token.*Fix: "a\.b"/s],
    ["asc.>.x", /">" in the middle.*Fix: "asc\.>".*"asc\.\*\.x"/s],
    ["asc.ev*nts.x", /whole tokens, never characters inside one.*Fix.*"asc\.\*\.x"/s],
    ["asc events", /has whitespace in it/],
    ["", /must be a subject/],
    [42, /must be a subject, got 42/],
  ];
  for (const [subject, re] of cases) {
    const errs = subjectErrors(subject, "[trigger].subscriptions[1]");
    assert.equal(errs.length, 1, `${JSON.stringify(subject)} should be refused once: ${errs.join(" | ")}`);
    assert.match(errs[0], /^\[trigger\]\.subscriptions\[1\] /);
    assert.match(errs[0], re);
  }
});

test("overlap is symmetric, and a deeper subject does not overlap a shorter one by accident", () => {
  assert.equal(subjectsOverlap("asc.events.>", "asc.events.asc.message.posted"), true);
  assert.equal(subjectsOverlap("asc.events.asc.message.posted", "asc.events.>"), true);
  assert.equal(subjectsOverlap("a.*.c", "a.b.c"), true);
  assert.equal(subjectsOverlap("a.b", "a.b"), true);
  assert.equal(subjectsOverlap("asc.events.*.message.posted", "asc.events.*.run.failed"), false);
  // ">" takes at least one token, so it does not match the prefix itself.
  assert.equal(subjectsOverlap("asc.events.>", "asc.events"), false);
  assert.equal(subjectsOverlap("a.b.c", "a.b"), false);
});

// --- what a manifest may say ----------------------------------------------

const base = (trigger) => ({
  agent: { name: "responder", description: "Answers what happened." },
  identity: { scopes: ["github:contents"] },
  trigger,
  runtime: { model: "claude-sonnet-5", entry: "prompts/responder.md", repo: "acme/product" },
});

test("a subscription is a trigger: a seat with no cron and no webhook validates", () => {
  const errs = validateManifest(base({ subscriptions: ["asc.events.*.message.posted"] }));
  assert.deepEqual(errs, [], errs.join("\n"));
});

test("[trigger] with none of the three names all three in the fix", () => {
  const errs = validateManifest(base({}));
  const hit = errs.find((e) => e.includes("[trigger] needs at least one"));
  assert.ok(hit, errs.join("\n"));
  assert.match(hit, /cron \(a schedule\), webhook \(the ingress wakes it\) or subscriptions \(the bus wakes it\)/);
  assert.match(hit, /subscriptions = \["asc\.events\.\*\.message\.posted"\]/);
});

test("an empty subscriptions list is refused rather than read as no trigger at all", () => {
  const errs = validateManifest(base({ subscriptions: [] }));
  const hit = errs.find((e) => e.includes("[trigger].subscriptions is an empty list"));
  assert.ok(hit, errs.join("\n"));
  assert.match(hit, /explicit and never defaulted/);
});

test("subscriptions must be a list, and the refusal says why a single subject is still one", () => {
  const errs = validateManifest(base({ subscriptions: "asc.events.>" }));
  const hit = errs.find((e) => e.includes("[trigger].subscriptions is a list"));
  assert.ok(hit, errs.join("\n"));
  assert.match(hit, /even for a single subject/);
});

test("a bad subject is refused by its index, so the reader finds the line", () => {
  const errs = validateManifest(base({ subscriptions: ["asc.events.*.message.posted", "asc.>.posted"] }));
  assert.ok(errs.some((e) => e.startsWith("[trigger].subscriptions[1]")), errs.join("\n"));
});

test("two filters that overlap are refused here, not by the server at startup", () => {
  const errs = validateManifest(base({ subscriptions: ["asc.events.>", "asc.events.asc.message.posted"] }));
  const hit = errs.find((e) => e.includes("they overlap"));
  assert.ok(hit, errs.join("\n"));
  assert.match(hit, /one consumer cannot hold two filters/);
  // The fix keeps the wider one, because that is the one that still delivers
  // everything the author asked for.
  assert.match(hit, /Fix: keep "asc\.events\.>", which already covers "asc\.events\.asc\.message\.posted"/);
});

test("the same subject twice is refused as a pair to drop one of", () => {
  const errs = validateManifest(base({ subscriptions: ["a.b", "a.b"] }));
  assert.ok(errs.some((e) => /they overlap.*Fix: drop one of the two/s.test(e)), errs.join("\n"));
});

test("retired [trigger].on now names subscriptions as its replacement", () => {
  // Warned rather than refused since spec v0.2 split the tables; the sentence
  // is the same one, and it is still printed by every surface that reads a
  // manifest. What `on` cost a seat — never being woken — is refused by
  // `[trigger]`'s own rule, tested above.
  const hit = manifestWarnings(base({ on: ["issue.opened"] })).find((w) => w.includes("[trigger].on"));
  assert.ok(hit, "the retirement sentence is not printed at any severity");
  assert.match(hit, /\[trigger\]\.subscriptions/);
  assert.match(hit, /one durable consumer per seat/);
});

// --- the consumer a manifest asks for -------------------------------------

test("the durable is named for the group and the seat, and reads back", () => {
  assert.equal(durableFor("epito", "engineer"), "epito-engineer");
  assert.equal(seatOfDurable("epito", "epito-engineer"), "engineer");
  // An agent name may contain hyphens; the group prefix comes off, nothing else.
  assert.equal(seatOfDurable("epito", "epito-exo-centralizer"), "exo-centralizer");
  assert.equal(seatOfDurable("epito", "other-engineer"), null);
});

test("the consumer config is the runtime's promises, written down", () => {
  const cfg = consumerConfig({ durable: "epito-pm", subjects: ["a.b"], ackWaitMs: 30000, batch: 1, seat: "pm" });
  assert.equal(cfg.ack_policy, "explicit", "an event acknowledged on delivery is an event that cannot be redelivered");
  assert.equal(cfg.max_deliver, -1, "redelivered until a seat takes it");
  assert.equal(cfg.deliver_policy, "all", "a consumer created today still sees what the stream held yesterday");
  assert.equal(cfg.ack_wait, 30000 * 1e6);
  assert.equal(cfg.max_ack_pending, 1, "one event at a time per seat, in order");
  assert.equal(cfg.filter_subject, "a.b");
  assert.ok(!("filter_subjects" in cfg), "one subject is written the way every server understands");
});

test("several subjects become filter_subjects, which is what 2.10 reads", () => {
  const cfg = consumerConfig({ durable: "epito-pm", subjects: ["a.b", "c.d"], seat: "pm" });
  assert.deepEqual(cfg.filter_subjects, ["a.b", "c.d"]);
  assert.ok(!("filter_subject" in cfg));
});

test("a consumer matches on what the manifest owns, so a restart does not rewrite it", () => {
  const want = consumerConfig({ durable: "epito-pm", subjects: ["a.b", "c.d"], seat: "pm" });
  // The server answers with a dozen fields the manifest never asked about.
  const asServer = { ...want, num_replicas: 1, metadata: {}, deliver_policy: "all", filter_subjects: ["c.d", "a.b"] };
  assert.equal(consumerMatches(asServer, want), true, "the order of two filters is not a change");
  assert.equal(consumerMatches({ ...asServer, filter_subjects: ["a.b"] }, want), false);
  assert.equal(consumerMatches({ ...asServer, ack_policy: "none" }, want), false);
  assert.equal(consumerMatches(null, want), false);
});

test("subscribingSeats reads the roster and leaves the others alone", () => {
  const roster = new Map([
    ["pm", { manifest: { trigger: { cron: "0 6 * * *" } } }],
    ["engineer", { manifest: { trigger: { cron: "0 6 * * *", subscriptions: ["asc.events.>"] } } }],
    ["exo", { manifest: { trigger: { webhook: true } } }],
  ]);
  assert.deepEqual(subscribingSeats(roster), [{ name: "engineer", subjects: ["asc.events.>"] }]);
});

// --- the reconcile ---------------------------------------------------------

// A bus, faked at the API boundary: `api(path, body)` is the only thing
// reconcileConsumers uses, so this is the whole surface it is tested against.
function fakeBus({ consumers = {}, streamSubjects = ["asc.events.>"], noStream = false } = {}) {
  const calls = [];
  return {
    calls, consumers,
    async api(path, body) {
      calls.push({ path, body });
      if (path.startsWith("STREAM.INFO.")) {
        if (noStream) throw Object.assign(new Error("stream not found"), { code: 10059, status: 404 });
        return { config: { name: path.split(".").pop(), subjects: streamSubjects }, state: { messages: 2 } };
      }
      if (path.startsWith("CONSUMER.INFO.")) {
        const name = path.split(".").pop();
        if (!consumers[name]) throw Object.assign(new Error("consumer not found"), { code: 10014, status: 404 });
        return { config: consumers[name], num_pending: 3, num_ack_pending: 0, num_redelivered: 1, delivered: { stream_seq: 9 } };
      }
      if (path.startsWith("CONSUMER.CREATE.")) { consumers[body.config.durable_name] = body.config; return { config: body.config }; }
      throw new Error(`unexpected ${path}`);
    },
  };
}

const CFG = { url: "nats://127.0.0.1:4222", stream: "ASC_EVENTS", group: "epito", ackWaitMs: 30000, nakDelayMs: 1, batch: 1 };

test("reconcile creates a consumer a seat does not have yet", async () => {
  const bus = fakeBus();
  const plan = await reconcileConsumers({ bus, cfg: CFG, seats: [{ name: "engineer", subjects: ["asc.events.>"] }] });
  assert.deepEqual(plan.create.map((c) => c.durable), ["epito-engineer"]);
  assert.deepEqual(plan.update, []);
  assert.equal(bus.consumers["epito-engineer"].filter_subject, "asc.events.>");
  assert.equal(bus.calls.at(-1).body.action, "create");
});

test("reconcile is idempotent: the same roster twice changes nothing the second time", async () => {
  const bus = fakeBus();
  const seats = [{ name: "engineer", subjects: ["asc.events.>"] }];
  await reconcileConsumers({ bus, cfg: CFG, seats });
  const again = await reconcileConsumers({ bus, cfg: CFG, seats });
  assert.deepEqual(again.create, []);
  assert.deepEqual(again.update, []);
  assert.deepEqual(again.unchanged.map((c) => c.name), ["engineer"]);
});

test("a manifest whose subjects changed updates the consumer rather than a second one", async () => {
  const bus = fakeBus();
  await reconcileConsumers({ bus, cfg: CFG, seats: [{ name: "engineer", subjects: ["asc.events.>"] }] });
  const plan = await reconcileConsumers({ bus, cfg: CFG, seats: [{ name: "engineer", subjects: ["asc.events.asc.message.posted"] }] });
  assert.deepEqual(plan.update.map((c) => c.durable), ["epito-engineer"]);
  assert.equal(Object.keys(bus.consumers).length, 1, "one seat, one durable, however often the manifest changes");
  assert.equal(bus.calls.at(-1).body.action, "update");
});

test("a subject the stream cannot carry is reported, not refused", async () => {
  const bus = fakeBus({ streamSubjects: ["asc.events.>"] });
  const plan = await reconcileConsumers({ bus, cfg: CFG, seats: [{ name: "engineer", subjects: ["other.events.thing"] }] });
  assert.deepEqual(plan.dead, [{ name: "engineer", subject: "other.events.thing" }]);
  assert.deepEqual(plan.create.map((c) => c.name), ["engineer"], "the consumer is still created: a stream may be widened tomorrow");
});

test("no stream by that name is one sentence naming the seats and the fix", async () => {
  const bus = fakeBus({ noStream: true });
  await assert.rejects(
    () => reconcileConsumers({ bus, cfg: CFG, seats: [{ name: "engineer", subjects: ["asc.events.>"] }] }),
    (e) => {
      assert.equal(e.epitoHandled, true, "an operating condition gets a sentence, never a stack");
      assert.match(e.message, /no stream named ASC_EVENTS/);
      assert.match(e.message, /engineer/);
      assert.match(e.message, /nats stream add ASC_EVENTS|EPITO_BUS_STREAM/);
      return true;
    },
  );
});

test("a dry run plans and writes nothing", async () => {
  const bus = fakeBus();
  const said = [];
  const plan = await reconcileConsumers({ bus, cfg: CFG, seats: [{ name: "engineer", subjects: ["asc.events.>"] }], dryRun: true, log: (m) => said.push(m) });
  assert.deepEqual(plan.create.map((c) => c.name), ["engineer"]);
  assert.deepEqual(bus.consumers, {}, "a rehearsal creates nothing");
  assert.match(said.join("\n"), /would create consumer epito-engineer/);
});

// --- the loop, and the promise --------------------------------------------

// A stream of one event, faked at the fetch/ack/nak boundary. `delivered`
// counts how many times this event has been handed out, which is what makes
// redelivery observable without a server.
function fakeStream(events) {
  const state = { acked: [], naked: [], delivered: 0, working: 0 };
  const queue = [...events];
  // A NAK carries a delay and the server honours it: the message is not
  // handed out again before it passes. The fake honours it too, because a
  // fake that redelivers instantly is a fake that cannot tell a fifteen
  // second NAK from a three hour one — which is the whole subject of the
  // refusal tests below.
  let notBefore = 0;
  return {
    state,
    async fetch() {
      const ev = queue[0];
      if (!ev || Date.now() < notBefore) return [];
      state.delivered++;
      return [{ subject: ev.subject, data: ev.data, headers: {}, reply: `$JS.ACK.S.C.${state.delivered}.${ev.seq}.1.0.0`, meta: { streamSeq: ev.seq, delivered: state.delivered, pending: queue.length - 1 } }];
    },
    ack(msg) { state.acked.push(msg.meta.streamSeq); queue.shift(); },
    nak(msg, delay) { state.naked.push({ seq: msg.meta.streamSeq, delay }); notBefore = Date.now() + (delay || 0); },
    // `+WPI`, the half of the protocol that makes waiting for a verdict legal.
    working() { state.working++; },
  };
}

const EVENT = { subject: "asc.events.asc.message.posted", seq: 7, data: JSON.stringify({ id: "e1", type: "message.posted", company: "asc", target: "engineer" }) };

test("an event is acknowledged only after the seat's run has started", async () => {
  const bus = fakeStream([EVENT]);
  let startedAt = null;
  const seen = [];
  const loop = startConsuming({
    bus, cfg: CFG, seats: [{ name: "engineer", subjects: ["asc.events.>"] }],
    wake: async () => {
      assert.deepEqual(bus.state.acked, [], "nothing may be acknowledged before the run has started");
      startedAt = Date.now();
      return { outcome: "started", workflow: "run:engineer" };
    },
    onEvent: (name, ev, started) => seen.push([name, ev.subject, ev.streamSeq, started.outcome]),
  });
  await waitFor(() => bus.state.acked.length === 1);
  await loop.stop();
  assert.ok(startedAt, "the run started");
  assert.deepEqual(bus.state.acked, [7]);
  assert.deepEqual(seen, [["engineer", "asc.events.asc.message.posted", 7, "started"]]);
});

test("a run that will not start leaves the event unacknowledged, and it comes back", async () => {
  const bus = fakeStream([EVENT]);
  const refusals = [];
  let attempts = 0;
  const loop = startConsuming({
    bus, cfg: { ...CFG, nakDelayMs: 5 }, seats: [{ name: "engineer", subjects: ["asc.events.>"] }],
    // The engine is down for the first two tries and up for the third: the
    // event has to survive both and wake the seat on the third.
    wake: async () => {
      attempts++;
      if (attempts < 3) throw new Error("Temporal at 127.0.0.1:7233 is not answering");
      return { outcome: "started", workflow: "run:engineer" };
    },
    onError: (name, e, ev) => refusals.push([name, ev?.delivery, e.message]),
  });
  await waitFor(() => bus.state.acked.length === 1);
  await loop.stop();
  assert.equal(attempts, 3);
  assert.deepEqual(bus.state.naked.map((n) => n.seq), [7, 7], "the event was given back twice, never acknowledged");
  assert.ok(bus.state.naked.every((n) => n.delay === 5), "a NAK carries the delay, so a dead engine is not spun at socket speed");
  assert.deepEqual(bus.state.acked, [7], "and it is acknowledged exactly once, when a run finally started");
  assert.deepEqual(refusals.map((r) => r[1]), [1, 2], "each refusal knows which delivery it was");
});

test("stop() ends the loop and acknowledges nothing on the way out", async () => {
  const bus = fakeStream([EVENT]);
  const loop = startConsuming({
    bus, cfg: CFG, seats: [{ name: "engineer", subjects: ["asc.events.>"] }],
    wake: () => new Promise(() => {}),   // a start that never finishes
  });
  await waitFor(() => bus.state.delivered === 1);
  await Promise.race([loop.stop(), sleep(300)]);
  assert.deepEqual(bus.state.acked, [], "an event whose run never started belongs to the next runtime");
});

// --- the provider's refusal, and the event it no longer loses --------------
//
// The defect, measured on 2026-10-18: `wake` resolves when Temporal accepted
// the workflow, which is milliseconds and almost never fails, so the failure
// that DOES happen — a model provider refusing the run — always landed after
// the acknowledgement. 65 events went that way in one day; 37 of those runs
// took no turn at all and not one of the 65 opened a pull request, so there
// was nothing to duplicate by re-delivering and nothing kept by acking.

const REFUSAL = { kind: "limit", says: "Claude AI usage limit reached", resetAt: null, floorMs: 10 * 60_000 };

test("a run the provider refused gives its event back instead of acknowledging it", async () => {
  const bus = fakeStream([EVENT]);
  const refused = [];
  let wakes = 0;
  const loop = startConsuming({
    bus, cfg: CFG, seats: [{ name: "engineer", subjects: ["asc.events.>"] }],
    wake: async () => {
      wakes++;
      // The run DID start on the engine, and then the provider said no. That
      // is the whole shape of the bug: nothing threw.
      return { outcome: "started", workflow: "run:engineer", verdict: async () => ({ refusal: REFUSAL }) };
    },
    onRefused: (name, ev, refusal, delay) => refused.push([name, ev.streamSeq, refusal.kind, delay]),
  });
  await waitFor(() => bus.state.naked.length >= 1);
  await loop.stop();
  assert.deepEqual(bus.state.acked, [], "the event is NOT acknowledged: this run never began");
  assert.equal(bus.state.naked[0].seq, 7);
  assert.deepEqual(refused[0].slice(0, 3), ["engineer", 7, "limit"]);
  assert.ok(wakes >= 1);
});

test("the delay is the one the refusal named, never the bus's fixed NAK", async () => {
  const bus = fakeStream([EVENT]);
  const resetAt = new Date(Date.now() + 90 * 60_000).toISOString();
  const naked = [];
  const loop = startConsuming({
    bus, cfg: { ...CFG, nakDelayMs: 15_000 }, seats: [{ name: "engineer", subjects: ["asc.events.>"] }],
    wake: async () => ({ outcome: "started", workflow: "run:engineer", verdict: async () => ({ refusal: { ...REFUSAL, resetAt } }) }),
    onRefused: (...a) => naked.push(a),
  });
  await waitFor(() => bus.state.naked.length >= 1);
  await loop.stop();
  const delay = bus.state.naked[0].delay;
  assert.ok(delay > 85 * 60_000 && delay < 95 * 60_000,
    `the event comes back when capacity does (about 90 minutes), not in 15 seconds: ${delay}ms`);
});

test("the event is held alive while the verdict is being decided, so nothing is delivered twice", async () => {
  const bus = fakeStream([EVENT]);
  const loop = startConsuming({
    // The beat is half the ack_wait and never faster than a quarter second,
    // so a tiny ack_wait is what makes it observable in a unit test; on a box
    // it is thirty seconds and the beat is every fifteen.
    bus, cfg: { ...CFG, ackWaitMs: 100 }, seats: [{ name: "engineer", subjects: ["asc.events.>"] }],
    wake: async () => ({
      outcome: "started", workflow: "run:engineer",
      verdict: () => new Promise((r) => setTimeout(() => r({ refusal: null }), 700)),
    }),
  });
  await waitFor(() => bus.state.acked.length === 1);
  await loop.stop();
  assert.ok(bus.state.working >= 1, "the loop told the server it was still working on this event");
  assert.deepEqual(bus.state.acked, [7], "and then acknowledged it, because the provider took the run");
});

test("a verdict that cannot be had acknowledges the event: a run is in flight", async () => {
  const bus = fakeStream([EVENT]);
  const said = [];
  const loop = startConsuming({
    bus, cfg: CFG, seats: [{ name: "engineer", subjects: ["asc.events.>"] }],
    log: (m) => said.push(m),
    wake: async () => ({ outcome: "started", workflow: "run:engineer", verdict: async () => { throw new Error("the engine blinked"); } }),
  });
  await waitFor(() => bus.state.acked.length === 1);
  await loop.stop();
  assert.deepEqual(bus.state.naked, [], "asking must never un-start a run");
  assert.match(said.join("\n"), /could not be asked how the provider answered \(the engine blinked\)/);
});

test("a wake that offers no verdict is acknowledged the moment it resolves, as it always was", async () => {
  const bus = fakeStream([EVENT]);
  const loop = startConsuming({
    bus, cfg: CFG, seats: [{ name: "engineer", subjects: ["asc.events.>"] }],
    wake: async () => ({ outcome: "coalesced", workflow: "run:engineer" }),
  });
  await waitFor(() => bus.state.acked.length === 1);
  await loop.stop();
  assert.deepEqual(bus.state.acked, [7]);
  assert.equal(bus.state.working, 0, "nothing to wait for, nothing to hold alive");
});

// --- the words ------------------------------------------------------------

test("an event is read without trusting its payload to be JSON", () => {
  const json = readEvent({ subject: "a.b", data: JSON.stringify({ id: "x", type: "t", company: "asc" }), headers: { "Nats-Msg-Id": "hdr-id" }, meta: { streamSeq: 2, delivered: 1, pending: 0 } });
  assert.equal(json.id, "hdr-id", "the publisher's own id header wins: it is the one the board wrote");
  assert.equal(json.type, "t");
  const text = readEvent({ subject: "a.b", data: "not json at all", headers: {}, meta: null });
  assert.equal(text.body, null);
  assert.equal(text.data, "not json at all", "a text event still wakes the seat");
  assert.equal(text.delivery, 1);
});

test("the log line names the subject and the delivery, and quotes no payload", () => {
  const ev = readEvent({ subject: "asc.events.asc.message.posted", data: JSON.stringify({ body: "something private" }), headers: {}, meta: { streamSeq: 7, delivered: 3 } });
  const line = eventSays("engineer", ev);
  assert.equal(line, "engineer: bus event asc.events.asc.message.posted (stream seq 7, delivery 3)");
  assert.ok(!line.includes("private"), "an event body is another company's text and the runtime does not log it");
});

test("a box with no stream named says which seats are not woken, and how to fix it", () => {
  const says = busOffSays([{ name: "engineer", subjects: ["asc.events.>"] }, { name: "pm", subjects: ["asc.events.>"] }]);
  assert.match(says, /engineer, pm/);
  assert.match(says, /EPITO_BUS_STREAM/);
  assert.match(says, /ONLY trigger is a subscription will do nothing at all/);
});

test("the box's bus settings default to the local server and no stream", () => {
  const cfg = busEnv({});
  assert.equal(cfg.url, "nats://127.0.0.1:4222");
  assert.equal(cfg.stream, null, "a default stream name would bake one company's roster into the product");
  assert.equal(cfg.group, "epito");
  const set = busEnv({ EPITO_BUS_URL: "nats://bus:4300", EPITO_BUS_STREAM: "ASC_EVENTS", EPITO_BUS_GROUP: "hq", EPITO_BUS_ACK_WAIT_MS: "1000" });
  assert.deepEqual([set.url, set.stream, set.group, set.ackWaitMs], ["nats://bus:4300", "ASC_EVENTS", "hq", 1000]);
  assert.equal(cfg.refusalWindowMs, 120_000, "how long the loop will hold an event waiting to hear from the provider");
  assert.equal(busEnv({ EPITO_BUS_REFUSAL_WINDOW_MS: "5000" }).refusalWindowMs, 5000);
});

// --- the wire ------------------------------------------------------------

test("a bus address is read in the forms a box writes it in", () => {
  assert.deepEqual(parseBusUrl("nats://127.0.0.1:4222"), { host: "127.0.0.1", port: 4222, user: null, pass: null });
  assert.deepEqual(parseBusUrl("bus.internal"), { host: "bus.internal", port: 4222, user: null, pass: null });
  assert.deepEqual(parseBusUrl("nats://u:p@h:4300"), { host: "h", port: 4300, user: "u", pass: "p" });
  assert.match(parseBusUrl("nats://host:port").error ?? "", /not a bus address/);
});

test("the ack subject is read from the end, so a server with a domain still parses", () => {
  const plain = parseAckSubject("$JS.ACK.ASC_EVENTS.epito-engineer.3.7.2.1760000000000000000.4");
  assert.deepEqual([plain.stream, plain.consumer, plain.delivered, plain.streamSeq, plain.pending], ["ASC_EVENTS", "epito-engineer", 3, 7, 4]);
  const domained = parseAckSubject("$JS.ACK.hub.abc123.ASC_EVENTS.epito-engineer.3.7.2.1760000000000000000.4.xyz");
  assert.deepEqual([domained.stream, domained.consumer, domained.delivered, domained.streamSeq], ["ASC_EVENTS", "epito-engineer", 3, 7]);
  assert.equal(parseAckSubject("asc.events.asc.message.posted"), null, "a plain subject is not an ack subject");
});

test("headers go out in the shape the protocol reads", () => {
  assert.equal(encodeHeaders({ "Nats-Msg-Id": "abc" }), "NATS/1.0\r\nNats-Msg-Id: abc\r\n\r\n");
});

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
async function waitFor(cond, ms = 2000) {
  const until = Date.now() + ms;
  while (Date.now() < until) { if (cond()) return; await sleep(5); }
  throw new Error("timed out waiting for the loop");
}
