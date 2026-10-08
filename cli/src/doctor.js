// `epito doctor [dir]` — would a run on THIS box start, and if not, which
// piece is missing.
//
// Four commands already answer a quarter of that question each: `epito
// validate <dir>` reads the manifests, `epito routes` says which model road
// each seat takes here, `epito env` says which names this box holds, and
// `epito validate --for-runtime` adds a 400ms look at the engine. An operator
// standing in front of a new box runs all four, reads three exit codes, and
// still has not checked the one thing none of them touch: the executable epito
// spawns. That gap is not academic. epitod v0's first real run on a real host
// exited 1 at turn zero with "Not logged in", because the environment a run
// hands its child is an allowlist and the executor's credential lookup needed
// a name the allowlist did not carry (src/lib/runenv.js). Every piece of that
// was knowable before 06:00 and nothing looked.
//
// So this is the preflight, and its contract is one sentence: exit 1 if a run
// on this box would refuse, and name the piece. Five sections, in the order a
// run needs them —
//
//   manifests  the roster loads and passes the spec (the validator's own code)
//   names      what [runtime].env asks this box for, and what it holds
//   roads      which model road each seat takes here, and the dead ones
//   executor   the binary a run spawns, resolved on the PATH a RUN gets and
//              started under the environment a RUN gives it (src/lib/probe.js)
//   engine     something answering at TEMPORAL_ADDRESS — and, when the engine
//              client is installed here, the real connect and namespace check
//
// Each section is this command's own reading of a shared module, never a
// re-implementation: the manifests go through loadRoster, the names through
// boxenv, the roads through the router, the engine through src/temporal's one
// connect. A preflight whose answer can differ from the command it predicts is
// worse than no preflight, because it is believed.
//
// What exits 1 and what does not, deliberately:
//
//   exit 1   a refused manifest, a seat with no open road, a road this box has
//            and has wrong, a name set to nothing, an executor that is missing
//            or will not start, an engine that is not answering
//   exit 0   a name this box does not hold (`[runtime].env` is the list the
//            runtime injects FROM, and nothing in a manifest says which names
//            a seat cannot work without — `epito env --complete` is where an
//            operator asserts that, and this command does not guess), and a
//            scope v0.2 cannot mint (that refusal belongs to `epito deploy`
//            and `epito token`, not to a run)
//
// And one thing it refuses to claim: that the executor is logged in. The look
// is free and offline, so it proves the file starts and nothing about the
// account behind it. `--deep` is the half that proves credentials, by running
// one real turn per road and reading the result contract back — it costs a
// model call, which is exactly why it is a flag.
import { resolve } from "node:path";
import { loadRoster } from "./lib/roster.js";
import { blockers, unchecked } from "./lib/readiness.js";
import { rosterEnv, askers, HELD, EMPTY, ABSENT } from "./lib/boxenv.js";
import { routesFor, liveRoutes, endpointLabel, DEFAULT_ROUTE } from "./lib/router.js";
import { lookAtExecutor, deepProbe, deepKey, probeFor, DEEP_PROMPT } from "./lib/probe.js";
import { engineAddress, engineAnswering, engineFix, engineMissing, missingEnginePackage } from "./lib/engine.js";
import { temporalEnv } from "./temporal/env.js";
import { SPEC_VERSION } from "./lib/fields.js";

export const DOCTOR_FLAGS = [
  { name: "json", does: "the report as JSON" },
  { name: "deep", does: "also run ONE real turn per road, to prove the executor's credentials — this costs a model call and leaves the box" },
];

const plural = (n, word) => `${n} ${word}${n === 1 ? "" : "s"}`;
const MARK = { ok: "✓", note: "!", bad: "✗" };

// The engine, as far as this box can honestly be asked.
//
// The cheap look first, because it is the one answer every box can give: a bare
// TCP connect proves "something accepted a connection on that port" and no
// more, which is all `epito validate` has ever claimed. Then, when the engine
// client is actually installed here, the real thing — connect, and
// describeNamespace — through src/temporal/client.js, the one place a
// connection is made, so an operator hears the same sentence the daemon would
// give them. A box without the client is the ordinary case (the packages are
// optional peers, ~300 MB) and is not a failure of anything: it reports the
// look and says that is what it did.
export async function engineLook({ env = process.env, probe = engineAnswering, importClient = () => import("./temporal/client.js") } = {}) {
  const cfg = temporalEnv(env);
  const address = engineAddress(env);
  const look = await probe(address);
  if (!look.ok) return { ...look, address, namespace: cfg.namespace, depth: "tcp", client: false };
  let connect;
  try { ({ connect } = await importClient()); }
  catch (e) {
    // The engine client not being installed is the normal state of a laptop
    // and of every `npm i -g epito`. Anything else — our own broken module —
    // is not ours to swallow.
    if (!missingEnginePackage(e)) throw e;
    return { ...look, address, namespace: cfg.namespace, depth: "tcp", client: false };
  }
  try {
    const { connection } = await connect({ env, quiet: true });
    await connection.close().catch(() => {});
    return { ok: true, reason: null, address, namespace: cfg.namespace, depth: "connect", client: true };
  } catch (e) {
    // connect() already speaks in the product's voice — the unreachable
    // sentence, or the missing-namespace one with the command that creates it.
    // An engine that answers a TCP connect and refuses a namespace check is
    // the case the TCP look reads as healthy, and it is the reason this half
    // exists at all.
    return { ok: false, reason: e.message, address, namespace: cfg.namespace, depth: "connect", client: true, answering: true };
  }
}

// One seat's roads, as the router sees them on this box.
function roadsFor(manifest) {
  const declared = routesFor(manifest);
  const { live, skipped } = liveRoutes(declared, process.env);
  const misconfigured = skipped.filter((s) => s.misconfigured);
  return {
    takes: live[0] ?? null,
    declared: declared.length,
    closed: skipped.map((s) => ({ name: s.route.name, reason: s.reason, misconfigured: Boolean(s.misconfigured) })),
    misconfigured: misconfigured.map((s) => ({ name: s.route.name, reason: s.reason })),
  };
}

export async function doctorCmd(args = []) {
  const dirArg = args.find((a) => !a.startsWith("-")) ?? ".";
  const dir = resolve(dirArg);
  const json = args.includes("--json");
  const deep = args.includes("--deep");

  // Refused manifests end the command here, in loadRoster's own voice: a
  // roster runs whole or not at all, and there is nothing to say about the box
  // a seat that is not a seat would run on.
  const roster = loadRoster(dir);
  const seats = [...roster.entries()].map(([name, entry]) => ({ name, path: entry.path, manifest: entry.manifest }));

  // --- the sections, each one a reading of the module that owns it ----------
  const env = rosterEnv(roster, process.env);
  const perSeat = [];
  for (const s of seats) {
    perSeat.push({
      agent: s.name,
      blocks: blockers(s.manifest, s.path),
      notes: unchecked(s.manifest, { baseDir: resolve(s.path, "..") }),
      roads: roadsFor(s.manifest),
      env: env.seats.find((x) => x.agent === s.name) ?? { asked: [], held: [], missing: [], empty: [] },
      executor: await lookAtExecutor(s.manifest),
    });
  }

  // The deep probe, once per road that actually differs. Five seats sharing one
  // executor and one road are one call; a seat on its own gateway is its own.
  const deepByKey = new Map();
  if (deep) {
    for (const s of seats) {
      const row = perSeat.find((p) => p.agent === s.name);
      if (row.executor.state !== "ok" || !row.roads.takes) continue;
      const key = deepKey(row.executor.binary, row.roads.takes);
      if (!deepByKey.has(key)) {
        deepByKey.set(key, { key, agent: s.name, route: row.roads.takes.name, model: row.roads.takes.model, binary: row.executor.binary, ...(await deepProbe(s.manifest, row.roads.takes)) });
      }
      row.deep = deepByKey.get(key);
    }
  }

  const engine = await engineLook();

  // --- the verdict ---------------------------------------------------------
  // One list, built from the sections, and the exit code is whether it is
  // empty. Every entry is a thing that makes a RUN on this box refuse; the
  // wording is the section's own, because the section is where the fix lives.
  const stranded = perSeat.filter((p) => !p.roads.takes);
  const brokenRoads = perSeat.flatMap((p) => p.roads.misconfigured.map((m) => ({ agent: p.agent, ...m })));
  const noExecutor = perSeat.filter((p) => p.executor.state !== "ok");
  const refusedDeep = [...deepByKey.values()].filter((d) => d.state === "refused");

  // Each refusal carries the seat it belongs to (or null for a fact about the
  // box), so the per-seat verdict in --json is read off this list rather than
  // recomputed from it — two answers to "is this seat ready" is one answer too
  // many.
  const refusals = [
    ...stranded.map((p) => ({ agent: p.agent, says: `${p.agent} has no open road on this box` })),
    ...brokenRoads.map((r) => ({ agent: r.agent, says: `${r.agent}'s road "${r.name}" is configured here and configured wrongly` })),
    ...noExecutor.map((p) => ({ agent: p.agent, says: `${p.agent}'s executor ${p.executor.state === "missing" ? "is not on the PATH a run gets" : "will not start here"}` })),
    ...env.empty.flatMap((r) => r.uses.map((u) => ({ agent: u.agent, says: `${r.name} is set on this box and set to nothing, and ${u.agent} asks for it` }))),
    ...refusedDeep.map((d) => ({ agent: null, says: `the executor refused one turn on route "${d.route}"` })),
    ...(engine.ok ? [] : [{ agent: null, says: `no engine: ${engine.depth === "connect" ? engine.reason : engineMissing(engine)}. Fix: ${engineFix(engine.address)}` }]),
  ];

  const report = {
    dir: dirArg, spec: SPEC_VERSION, seats: perSeat.map((p) => ({
      agent: p.agent,
      ready: !refusals.some((r) => r.agent === p.agent),
      road: p.roads.takes ? { name: p.roads.takes.name, model: p.roads.takes.model, endpoint: endpointLabel(p.roads.takes) } : null,
      closedRoads: p.roads.closed,
      executor: { adapter: p.executor.adapter, binary: p.executor.binary, path: p.executor.path, state: p.executor.state, version: p.executor.version },
      names: { asked: p.env.asked.length, held: p.env.held.length, missing: p.env.missing, empty: p.env.empty },
      blocks: p.blocks.map((b) => b.problem),
      notes: p.notes,
      deep: p.deep ? { state: p.deep.state, route: p.deep.route, turns: p.deep.turns ?? null, says: p.deep.says ?? null } : null,
    })),
    engine: { address: engine.address, namespace: engine.namespace, ok: engine.ok, depth: engine.depth, reason: engine.reason ?? null },
    deep: deep ? [...deepByKey.values()].map((d) => ({ route: d.route, model: d.model, state: d.state, turns: d.turns ?? null, says: d.says ?? null })) : null,
    refusals: refusals.map((r) => ({ agent: r.agent, says: r.says })),
  };
  if (json) {
    console.log(JSON.stringify(report, null, 2));
    process.exit(refusals.length ? 1 : 0);
  }

  // --- the report, five lines and then the detail --------------------------
  const out = refusals.length ? console.error : console.log;
  const n = seats.length;
  out(`roster ${dirArg} on this box — ${plural(n, "seat")}, checked in the order a run needs them\n`);

  const row = (label, state, text) => out(`${MARK[state]} ${label.padEnd(9)}  ${text}`);

  // manifests
  const withBlocks = perSeat.filter((p) => p.blocks.length);
  row("manifests", withBlocks.length ? "note" : "ok",
    `${n} of ${plural(n, "manifest")} load and pass spec ${SPEC_VERSION}${withBlocks.length ? `, and ${plural(withBlocks.length, "seat")} ${withBlocks.length === 1 ? "names something" : "name something"} another command will refuse` : ""}`);

  // names
  const askedNames = env.names.length;
  const heldNames = env.names.filter((r) => r.state === HELD).length;
  row("names", env.empty.length ? "bad" : env.missing.length ? "note" : "ok",
    askedNames === 0
      ? "no manifest here names a variable, so this box owes the roster nothing beyond the runtime's own environment"
      : `${plural(askedNames, "name")} asked for, ${heldNames} held${env.missing.length ? `, ${env.missing.length} not set here` : ""}${env.empty.length ? `, ${env.empty.length} set to nothing` : ""}`);

  // roads
  const takers = new Map();
  for (const p of perSeat) if (p.roads.takes) takers.set(p.roads.takes.name, (takers.get(p.roads.takes.name) ?? 0) + 1);
  row("roads", stranded.length || brokenRoads.length ? "bad" : "ok",
    stranded.length
      ? `${plural(stranded.length, "seat")} ${stranded.length === 1 ? "has" : "have"} no open road here (${stranded.map((p) => p.agent).join(", ")})`
      : `every seat has an open road — ${[...takers].map(([name, c]) => `${c} on ${name === DEFAULT_ROUTE ? "[runtime].model, no route declared" : `"${name}"`}`).join(", ")}${brokenRoads.length ? `; ${plural(brokenRoads.length, "road")} here ${brokenRoads.length === 1 ? "is" : "are"} configured wrongly` : ""}`);

  // executor
  const execOk = perSeat.filter((p) => p.executor.state === "ok");
  const execWhere = [...new Set(execOk.map((p) => p.executor.path))];
  row("executor", noExecutor.length ? "bad" : "ok",
    noExecutor.length
      ? `${plural(noExecutor.length, "seat")} cannot be started here (${noExecutor.map((p) => p.agent).join(", ")})`
      : `${execWhere.join(", ")} started under the environment a run gives it, for ${plural(execOk.length, "seat")}`);

  // engine
  row("engine", engine.ok ? "ok" : "bad",
    engine.ok
      ? engine.depth === "connect"
        ? `${engine.address} is Temporal, namespace "${engine.namespace}" exists (a real connect: the engine client is installed here)`
        : `${engine.address} is answering — a TCP connect, which proves something accepted a connection and not that it is Temporal (the engine client is not installed here, so that is as far as this box can ask)`
      : engine.depth === "connect" ? engine.reason : engineMissing(engine));
  if (deep) {
    const calls = [...deepByKey.values()];
    const okCalls = calls.filter((d) => d.state === "ok");
    const unavailable = calls.filter((d) => d.state === "unavailable");
    row("one turn", refusedDeep.length ? "bad" : okCalls.length ? "ok" : "note",
      calls.length === 0
        ? "no road was in a state to try"
        : `${plural(calls.length, "road")} tried, ${okCalls.length} answered${refusedDeep.length ? `, ${refusedDeep.length} refused` : ""}${unavailable.length ? `, ${unavailable.length} has no one-turn probe` : ""}`);
  }
  out("");

  // --- the detail, only where there is something to act on -----------------
  for (const p of perSeat) {
    const lines = [];
    for (const b of p.blocks) lines.push(`! ${b.problem}.\n    Fix: ${b.fix}.`);
    for (const u of p.notes) lines.push(`— ${u}`);
    if (!p.roads.takes) {
      lines.push(`✗ no open road: ${p.roads.closed.map((c) => `"${c.name}" — ${c.reason}`).join("; ")}.\n    Fix: set one of the keys those name, or give this seat a final route that needs none. \`epito routes ${dirArg}\` is the long version.`);
    }
    for (const m of p.roads.misconfigured) {
      lines.push(`✗ road "${m.name}" is configured here and configured wrongly — ${m.reason}.\n    Fix: correct it, or unset it: this seat falls through to the next road and runs, so nothing else would have told you.`);
    }
    if (p.executor.state !== "ok") {
      lines.push(`✗ executor: ${p.executor.says}.\n    Fix: ${p.executor.fix}.`);
    }
    if (p.env.empty.length) {
      lines.push(`✗ ${p.env.empty.join(", ")} ${p.env.empty.length > 1 ? "arrive" : "arrives"} empty: this box has ${p.env.empty.length > 1 ? "them" : "it"} and has ${p.env.empty.length > 1 ? "them" : "it"} set to nothing.\n    Fix: put the value after the = in this box's env file, or delete the line, which is the honest way to say this box does not have it.`);
    }
    // A name this box does not hold is said ONCE, in the closing verdict, and
    // not per seat: five seats short of the same webhook printed five
    // identical lines and buried the one seat that had a real problem. `epito
    // env` is the per-seat view and it is one command away.
    if (p.deep?.state === "refused") lines.push(`✗ one turn: ${p.deep.says}.\n    Fix: that sentence is the executor's own — fix what it names, then run this again.`);
    if (p.deep?.state === "ok") lines.push(`✓ one real turn on "${p.deep.route}" answered in ${p.deep.turns ?? "?"} turn${p.deep.turns === 1 ? "" : "s"}: this seat's credentials work here.`);
    if (!lines.length) continue;
    out(`${p.agent}`);
    for (const l of lines) out(`  ${l}`);
    out("");
  }

  if (env.empty.length) {
    out(`epito: ${plural(env.empty.length, "name")} on this box ${env.empty.length > 1 ? "are" : "is"} set and set to nothing (${env.empty.map((r) => `${r.name} — ${askers(r.uses)}`).join("; ")}).`);
  }

  // --- the closing verdict -------------------------------------------------
  if (refusals.length) {
    out(`epito: a run on this box would refuse — ${plural(refusals.length, "reason")}:`);
    for (const r of refusals) out(`  ✗ ${r.says}`);
    out(`\nThe ✗ lines above each name a fix. Nothing was started, nothing was registered on the engine, and nothing in ${dirArg} was changed.`);
    process.exit(1);
  }

  const look = probeFor(perSeat[0]?.executor.adapter ?? "claude");
  out(`✓ nothing here would make a run on this box refuse: ${plural(n, "manifest")} good, every seat on an open road, the executor starts under a run's own environment, and ${engine.address} is ${engine.depth === "connect" ? "Temporal with namespace " + engine.namespace : "answering"}.`);
  if (!deep) {
    out(`  Not proven: ${look.unproven}. \`epito doctor ${dirArg} --deep\` runs ONE turn per road — ${DEEP_PROMPT.toLowerCase().replace(/\.$/, "")} — which costs a model call and is the only thing that proves credentials from here.`);
  }
  if (env.missing.length) {
    out(`  ${plural(env.missing.length, "name")} the manifests ask for ${env.missing.length > 1 ? "are" : "is"} not on this box (${env.missing.map((r) => r.name).join(", ")}): the runtime drops ${env.missing.length > 1 ? "them" : "it"} and the seats run without ${env.missing.length > 1 ? "them" : "it"}. \`epito env ${dirArg}\` says who asks for what.`);
  }
  if (withBlocks.length) {
    out(`  And ${plural(withBlocks.length, "seat")} above ${withBlocks.length === 1 ? "names a scope" : "name scopes"} this spec cannot mint: a RUN does not care, \`epito deploy\` and \`epito token\` refuse.`);
  }
  process.exit(0);
}
