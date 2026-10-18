// `epito bus [dir]` — what the bus is holding for this roster, on THIS box.
//
// The sibling of `epito routes` and `epito env`, and it exists for the same
// reason: the manifests say what a seat subscribes to, and whether anything is
// actually waiting for it is a question only this box can answer. A seat with
// `[trigger].subscriptions` and no stream on the box is a seat that never
// fires, and until this command existed the only way to find that out was to
// publish an event and watch nothing happen.
//
// It needs no engine and starts no run: it reads the roster, asks the bus what
// each seat's consumer holds, and prints it. The one thing it never does is
// consume — a diagnostic that acknowledged an event would wake nobody and
// lose it (the mistake `epito validate` made about Temporal, ADR-24, in a
// shape that costs an event rather than a ✓).
import { loadRoster } from "./lib/roster.js";
import { busEnv, subscribingSeats, durableFor, consumerConfig, consumerMatches } from "./lib/bus.js";
import { subjectsOverlap } from "./lib/subjects.js";
import { connectBus } from "./lib/nats.js";
import { table, iso16 } from "./lib/table.js";

export const BUS_FLAGS = [{ name: "json", does: "the report as JSON" }];

const NO_STREAM = 10059;

export async function busCmd(args = []) {
  const dir = args.find((a) => !a.startsWith("-")) ?? ".";
  const json = args.includes("--json");
  const roster = loadRoster(dir);
  const cfg = busEnv();
  const seats = subscribingSeats(roster);

  const report = { url: cfg.url, stream: cfg.stream, group: cfg.group, seats: [], problems: [] };

  // A roster nobody subscribes for is not a problem, and it is also not
  // nothing: it is the answer to "why is this seat never woken by an event".
  if (!seats.length) {
    if (json) { console.log(JSON.stringify({ ...report, subscribing: 0 }, null, 2)); return; }
    console.log(`no seat under ${dir} subscribes to the bus: ${roster.size} manifest${roster.size === 1 ? "" : "s"}, none with [trigger].subscriptions.`);
    console.log(`a seat is woken by the bus when its manifest names the subjects it answers — subscriptions = ["asc.events.*.message.posted"] under [trigger] (spec v0.2).`);
    return;
  }

  if (!cfg.stream) {
    const names = seats.map((s) => s.name).join(", ");
    if (json) { console.log(JSON.stringify({ ...report, seats: seats.map((s) => ({ ...s, consumer: null, reason: "no stream named on this box" })) }, null, 2)); }
    else {
      console.log(`${seats.length} seat${seats.length === 1 ? "" : "s"} under ${dir} subscribe${seats.length === 1 ? "s" : ""} to the bus and this box names no stream:`);
      for (const s of seats) console.log(`  ✗ ${s.name}: ${s.subjects.join(", ")}`);
    }
    console.error(`\nepito: EPITO_BUS_STREAM is not set, so this box consumes nothing and ${names} ${seats.length === 1 ? "is" : "are"} not woken by any event — \`epito run ${dir}\` says the same on startup and keeps serving, because a bus is one trigger and not the only one. Fix: set EPITO_BUS_STREAM to the stream that carries those subjects, and EPITO_BUS_URL if the bus is not ${cfg.url}.`);
    process.exit(1);
  }

  let bus;
  try { bus = await connectBus({ url: cfg.url, name: "epito-bus" }); }
  catch (e) {
    console.error(`epito: ${e.message}`);
    process.exit(1);
  }

  let stream = null;
  try { stream = await bus.api(`STREAM.INFO.${cfg.stream}`); }
  catch (e) {
    bus.close();
    console.error(e.code === NO_STREAM
      ? `epito: the bus at ${cfg.url} has no stream named ${cfg.stream} — EPITO_BUS_STREAM names the stream this box consumes, and there is nothing by that name to consume. Fix: \`nats stream add ${cfg.stream}\` with the subjects these seats subscribe to (${[...new Set(seats.flatMap((s) => s.subjects))].join(", ")}), or point EPITO_BUS_STREAM at the stream that already carries them.`
      : `epito: ${e.message}`);
    process.exit(1);
  }
  const streamSubjects = stream.config.subjects ?? [];

  for (const seat of seats) {
    const durable = durableFor(cfg.group, seat.name);
    const want = consumerConfig({ durable, subjects: seat.subjects, ackWaitMs: cfg.ackWaitMs, batch: cfg.batch, seat: seat.name });
    let info = null;
    try { info = await bus.api(`CONSUMER.INFO.${cfg.stream}.${durable}`); }
    catch (e) { if (e.status !== 404) { console.error(`epito: ${e.message}`); bus.close(); process.exit(1); } }
    const dead = seat.subjects.filter((subj) => !streamSubjects.some((ss) => subjectsOverlap(ss, subj)));
    report.seats.push({
      agent: seat.name, subjects: seat.subjects, consumer: durable,
      exists: Boolean(info),
      stale: Boolean(info) && !consumerMatches(info.config, want),
      waiting: info?.num_pending ?? null,
      unacked: info?.num_ack_pending ?? null,
      redelivered: info?.num_redelivered ?? null,
      lastDelivered: info?.delivered?.stream_seq ?? null,
      lastActivity: info?.delivered?.last_active ?? null,
      dead,
    });
    for (const subj of dead) report.problems.push(`${seat.name} subscribes to ${subj}, which ${cfg.stream} does not carry`);
  }
  bus.close();

  if (json) { console.log(JSON.stringify({ ...report, streamSubjects, messages: stream.state.messages }, null, 2)); }
  else {
    console.log(`bus ${cfg.url}, stream ${cfg.stream} (${streamSubjects.join(", ")}), ${stream.state.messages} message${stream.state.messages === 1 ? "" : "s"} held, consumer group ${cfg.group}`);
    console.log("");
    const rows = [["SEAT", "SUBJECTS", "CONSUMER", "WAITING", "UNACKED", "REDELIVERED", "LAST EVENT"]];
    for (const s of report.seats) {
      rows.push([
        s.name ?? s.agent, s.subjects.join(" "),
        s.exists ? (s.stale ? `${s.consumer} (stale)` : s.consumer) : "— none yet",
        s.waiting ?? "-", s.unacked ?? "-", s.redelivered ?? "-",
        s.lastDelivered ? `seq ${s.lastDelivered} ${iso16(s.lastActivity)}` : "never",
      ]);
    }
    for (const line of table(rows)) console.log(line);
    console.log("");
    console.log(`WAITING is what the stream is holding for that seat; UNACKED is an event handed to a run that has not started yet; REDELIVERED counts the events a run refused and the bus gave back.`);
    const missing = report.seats.filter((s) => !s.exists);
    if (missing.length) console.log(`a seat with no consumer yet has never been served by a running \`epito run ${dir}\` — it creates one per subscribing seat at startup, and the events it subscribes to are waiting in the stream until it does.`);
    const stale = report.seats.filter((s) => s.stale);
    if (stale.length) console.log(`a (stale) consumer was created from an older manifest: ${stale.map((s) => s.name).join(", ")} — \`epito run ${dir}\` updates it on startup, or SIGHUP without a restart.`);
  }

  if (report.problems.length) {
    console.error(`\nepito: ${report.problems.length} subscription${report.problems.length === 1 ? "" : "s"} on this roster can never deliver — ${report.problems.join("; ")}. The stream carries ${streamSubjects.join(", ")}. Fix: correct the subject in the manifest, or widen the stream to carry it.`);
    process.exit(1);
  }
}
