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
// on this box would refuse, and name the piece. Six sections, in the order a
// run needs them —
//
//   manifests  the roster loads and passes the spec (the validator's own code)
//   names      what [runtime].env asks this box for, and what it holds
//   roads      which model road each seat takes here, and the dead ones
//   identity   who each seat acts as here: its own GitHub App, or the box's
//              shared credential, or an identity this box holds half of
//              (src/lib/acts.js, reading the run path's own loadPrincipal)
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
//            and has wrong, a name set to nothing, HALF of an identity, an App
//            whose mint could not start, an executor that is missing or will
//            not start, an engine that is not answering
//   exit 0   a name this box does not hold (`[runtime].env` is the list the
//            runtime injects FROM, and nothing in a manifest says which names
//            a seat cannot work without — `epito env --complete` is where an
//            operator asserts that, and this command does not guess), and a
//            scope v0.2 cannot mint (that refusal belongs to `epito deploy`
//            and `epito token`, not to a run — UNLESS this box holds an App
//            for that seat, because then the mint is part of the run and the
//            unmintable scope is what stops it), and a seat with no App at
//            all, which is how every seat ran before the identity leg and is
//            still how this company's own five run
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
import { actsAs, IDENTITY_FIX, OWN, REFUSED, HALF, SHARED, NONE } from "./lib/acts.js";
import { engineAddress, engineAnswering, engineFix, engineMissing, missingEnginePackage } from "./lib/engine.js";
import { temporalEnv } from "./temporal/env.js";
import { SPEC_VERSION } from "./lib/fields.js";

export const DOCTOR_FLAGS = [
  { name: "json", does: "the report as JSON" },
  { name: "deep", does: "also run ONE real turn per road, to prove the executor's credentials — this costs a model call and leaves the box" },
];

const plural = (n, word) => `${n} ${word}${n === 1 ? "" : "s"}`;

// How a road is spelled back to the reader. A seat with no `[[runtime.route]]`
// has exactly one road, named "default" by the router, and quoting that name at
// an operator reads as a route they wrote — `epito routes` already prints "(no
// routes declared)" rather than the name for the same reason. The field it
// actually comes from is the honest label, and it is said once here so the rows
// and the --deep block cannot name one road two ways.
const roadLabel = (name) => (name === DEFAULT_ROUTE ? "[runtime].model" : `"${name}"`);
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
      // Deliberately on the default `dir`, which is the "." mintForRun itself
      // defaults to: the file store is resolved relative to the process's
      // working directory, so a preflight run from somewhere else than the
      // run would be answering about a different store. The report prints the
      // absolute path it looked at for exactly that reason.
      acts: actsAs(s.name, s.manifest),
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
        deepByKey.set(key, { key, agents: [], route: row.roads.takes.name, model: row.roads.takes.model, binary: row.executor.binary, ...(await deepProbe(s.manifest, row.roads.takes)) });
      }
      // Which seats this one call speaks for. The call is keyed by the things
      // that change its answer — the binary, the endpoint, the key — so three
      // seats on one road are one call, and the report says whose turn it
      // stood in for rather than printing the same proof three times.
      deepByKey.get(key).agents.push(s.name);
      row.deep = deepByKey.get(key);
    }
  }

  const engine = await engineLook();

  // --- the verdict ---------------------------------------------------------
  // The executor's problems, grouped by the problem itself, because that is
  // the shape of the fix: five seats sharing one `claude` share one missing
  // `claude`, and a seat whose [runtime].env differs enough to fail on its own
  // gets its own line.
  const execProblems = new Map();
  for (const p of perSeat) {
    if (p.executor.state === "ok") continue;
    const key = `${p.executor.state}|${p.executor.says}|${p.executor.fix}`;
    if (!execProblems.has(key)) execProblems.set(key, { ...p.executor, agents: [] });
    execProblems.get(key).agents.push(p.agent);
  }

  // Identity, grouped the way the executor's problems are: one sentence per
  // distinct answer, carrying the seats it covers. Five seats with no App of
  // their own share one sentence and one fix; a seat with its own App has an
  // App id nobody else has, so it keeps its own line.
  const actGroups = [];
  for (const p of perSeat) {
    const a = p.acts;
    const key = a.state === OWN ? `own|${a.agent}` : `${a.state}|${a.says}|${a.fix}`;
    const found = actGroups.find((g) => g.key === key);
    if (found) found.agents.push(a.agent);
    else actGroups.push({ key, state: a.state, says: a.says, fix: a.fix, agents: [a.agent] });
  }
  const badIdentity = actGroups.filter((g) => g.state === REFUSED || g.state === HALF);

  const stranded = perSeat.filter((p) => !p.roads.takes);
  const brokenRoads = perSeat.flatMap((p) => p.roads.misconfigured.map((m) => ({ agent: p.agent, ...m })));
  const noExecutor = perSeat.filter((p) => p.executor.state !== "ok");
  const refusedDeep = [...deepByKey.values()].filter((d) => d.state === "refused");

  // One list, and the exit code is whether it is empty. Every entry is a thing
  // that makes a RUN on this box refuse, carrying the seats it covers — an
  // empty list of seats means a fact about the box itself, like the engine. The
  // per-seat verdict in --json is read OFF this list rather than recomputed
  // from the sections: two answers to "is this seat ready" is one too many.
  const refusals = [
    ...stranded.map((p) => ({ agents: [p.agent], says: "no open road on this box" })),
    ...brokenRoads.map((r) => ({ agents: [r.agent], says: `the road "${r.name}" is configured here and configured wrongly` })),
    ...[...execProblems.values()].map((e) => ({ agents: e.agents, says: `the executor ${e.state === "missing" ? "is not on the PATH a run gets" : "will not start here"}` })),
    ...env.empty.map((r) => ({ agents: r.uses.map((u) => u.agent), says: `${r.name} is set on this box and set to nothing` })),
    // An identity this box holds and holds wrong. Not "has no App" — that one
    // is how this product worked before the identity leg and is reported, not
    // refused. These two are a mint that would throw permanently, and half a
    // pair the runtime reads as nothing at all.
    ...badIdentity.map((g) => ({
      agents: g.agents,
      says: g.state === HALF
        // Not "falls back to the shared credential": that is true only where
        // the manifest names one, and this box's half-set names say nothing
        // about whether it does. The per-answer block above names the actual
        // fallback per seat.
        ? "this box holds half of an identity for it, so its runs silently fall back to whatever else the box gives them"
        : "it has a GitHub App on this box and the mint would refuse before it reached GitHub",
    })),
    ...refusedDeep.map((d) => ({ agents: d.agents, says: `the executor refused one turn on the road ${roadLabel(d.route)}` })),
    // The engine's own sentence, and a fix appended only when it does not
    // already carry one. A real connect that failed has said the exact thing
    // — an unreachable address, or a namespace that does not exist with the
    // command that creates it — and bolting "run `temporal server start-dev`"
    // onto "namespace nope does not exist" names the wrong fix for the
    // problem the line above just described.
    ...(engine.ok ? [] : [{ agents: [], says: `no engine: ${engine.depth === "connect" ? engine.reason : `${engineMissing(engine)}. Fix: ${engineFix(engine.address)}`}` }]),
  ];

  const report = {
    dir: dirArg, spec: SPEC_VERSION, seats: perSeat.map((p) => ({
      agent: p.agent,
      ready: !refusals.some((r) => r.agents.includes(p.agent)),
      road: p.roads.takes ? { name: p.roads.takes.name, model: p.roads.takes.model, endpoint: endpointLabel(p.roads.takes) } : null,
      closedRoads: p.roads.closed,
      executor: { adapter: p.executor.adapter, binary: p.executor.binary, path: p.executor.path, state: p.executor.state, version: p.executor.version },
      // The App id and the source are facts about which principal, never the
      // key itself: the same line the audit log keeps (spec rule 1).
      identity: { state: p.acts.state, source: p.acts.source, appId: p.acts.appId, installation: p.acts.installation, says: p.acts.says },
      names: { asked: p.env.asked.length, held: p.env.held.length, missing: p.env.missing, empty: p.env.empty },
      blocks: p.blocks.map((b) => b.problem),
      notes: p.notes,
      deep: p.deep ? { state: p.deep.state, route: p.deep.route, turns: p.deep.turns ?? null, says: p.deep.says ?? null } : null,
    })),
    engine: { address: engine.address, namespace: engine.namespace, ok: engine.ok, depth: engine.depth, reason: engine.reason ?? null },
    deep: deep ? [...deepByKey.values()].map((d) => ({ route: d.route, model: d.model, state: d.state, turns: d.turns ?? null, says: d.says ?? null })) : null,
    refusals: refusals.map((r) => ({ agents: r.agents, says: r.says })),
  };
  if (json) {
    console.log(JSON.stringify(report, null, 2));
    process.exit(refusals.length ? 1 : 0);
  }

  // --- the report: one row per section, then the detail --------------------
  const out = refusals.length ? console.error : console.log;
  const n = seats.length;
  out(`roster ${dirArg} on this box — ${plural(n, "seat")}, checked in the order a run needs them\n`);

  const row = (label, state, text) => out(`${MARK[state]} ${label.padEnd(9)}  ${text}`);

  // manifests
  const withBlocks = perSeat.filter((p) => p.blocks.length);
  row("manifests", withBlocks.length ? "note" : "ok",
    `${n} of ${plural(n, "manifest")} ${n === 1 ? "loads and passes" : "load and pass"} spec ${SPEC_VERSION}${withBlocks.length ? `, and ${plural(withBlocks.length, "seat")} ${withBlocks.length === 1 ? "names something" : "name something"} another command will refuse` : ""}`);

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
      : `every seat has an open road — ${[...takers].map(([name, c]) => `${c} on ${roadLabel(name)}`).join(", ")}${brokenRoads.length ? `; ${plural(brokenRoads.length, "road")} here ${brokenRoads.length === 1 ? "is" : "are"} configured wrongly` : ""}`);

  // identity
  const ownSeats = perSeat.filter((p) => p.acts.state === OWN);
  const sharedSeats = perSeat.filter((p) => p.acts.state === SHARED);
  const noneSeats = perSeat.filter((p) => p.acts.state === NONE);
  const identityParts = [
    ownSeats.length ? `${plural(ownSeats.length, "seat")} ${ownSeats.length === 1 ? "acts" : "act"} as ${ownSeats.length === 1 ? "its" : "their"} own GitHub App` : null,
    sharedSeats.length ? `${plural(sharedSeats.length, "seat")} ${sharedSeats.length === 1 ? "acts" : "act"} as the owner of a shared credential` : null,
    noneSeats.length ? `${plural(noneSeats.length, "seat")} ${noneSeats.length === 1 ? "has" : "have"} no GitHub identity in ${noneSeats.length === 1 ? "its runs" : "their runs"}` : null,
  ].filter(Boolean);
  row("identity", badIdentity.length ? "bad" : ownSeats.length === n ? "ok" : "note",
    badIdentity.length
      ? `${plural(badIdentity.reduce((t, g) => t + g.agents.length, 0), "seat")} ${badIdentity.reduce((t, g) => t + g.agents.length, 0) === 1 ? "has an identity" : "have identities"} on this box a run cannot use (${badIdentity.flatMap((g) => g.agents).join(", ")})`
      : identityParts.join(", "));

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
        : `${plural(calls.length, "road")} tried, ${okCalls.length} answered${refusedDeep.length ? `, ${refusedDeep.length} refused` : ""}${unavailable.length ? `, ${unavailable.length} ${unavailable.length === 1 ? "has" : "have"} no one-turn probe` : ""}`);
  }
  out("");

  // --- the executor, once per binary ---------------------------------------
  if (execProblems.size) {
    out("executor, per binary");
    for (const e of execProblems.values()) {
      out(`  ✗ ${e.says} — covers ${e.agents.join(", ")}`);
      out(`      Fix: ${e.fix}.`);
    }
    out("");
  }

  // --- who each seat acts as, once per answer ------------------------------
  // Printed whenever a single seat is not acting as itself, and then for EVERY
  // seat: "who opens the pull request" is a table read whole, not a list of
  // exceptions, and a roster where two of five act as themselves is a fact an
  // operator wants in front of them rather than inferred from a count.
  if (actGroups.some((g) => g.state !== OWN)) {
    out("identity, per answer");
    for (const g of actGroups) {
      const mark = g.state === OWN ? "✓" : g.state === SHARED || g.state === NONE ? "!" : "✗";
      out(`  ${mark} ${g.says} — covers ${g.agents.join(", ")}`);
      if (g.fix) out(`      Fix: ${g.fix}.`);
    }
    // Once, under the block, for every seat in it that has no App: the two
    // names are the same rule for all of them.
    if (actGroups.some((g) => g.state === SHARED || g.state === NONE)) out(`  Fix: ${IDENTITY_FIX}.`);
    out("");
  }

  // --- the names this box has and has wrong --------------------------------
  // Absent names are reported once in the closing verdict; these are the other
  // kind, and they are the kind that exits 1: the box HAS the name and has it
  // set to nothing, so the runtime injects an empty string, the agent reads it
  // and whatever it builds out of it fails somewhere far from here.
  if (env.empty.length) {
    out("names, per name");
    for (const r of env.empty) {
      out(`  ✗ ${r.name} is set here and set to nothing — ${askers(r.uses)}`);
      out(`      Fix: put the value after the = in this box's env file, or delete the line entirely, which is the honest way to say this box does not have it.`);
    }
    out("");
  }

  // --- the detail, only where there is something to act on -----------------
  for (const p of perSeat) {
    const lines = [];
    for (const b of p.blocks) {
      // readiness.js names the commands that refuse over an unmintable scope
      // or an absent [runtime].repo, and `run` is not among them on purpose:
      // for a seat with no App a run never mints, so a run never cares. This
      // box may say otherwise about THIS seat — it holds an App for it, and
      // then the mint is the run's first step — so the note is extended here
      // rather than left to contradict the section above it.
      const alsoTheRun = (p.acts.state === OWN || p.acts.state === REFUSED) && b.commands.includes("token");
      lines.push(`! ${b.problem}${alsoTheRun ? `, and on this box a RUN of this seat too: it has its own App here, so the mint is the first thing a run does` : ""}.\n    Fix: ${b.fix}.`);
    }
    for (const u of p.notes) lines.push(`— ${u}`);
    if (!p.roads.takes) {
      lines.push(`✗ no open road: ${p.roads.closed.map((c) => `"${c.name}" — ${c.reason}`).join("; ")}.\n    Fix: set one of the keys those name, or give this seat a final route that needs none. \`epito routes ${dirArg}\` is the long version.`);
    }
    for (const m of p.roads.misconfigured) {
      lines.push(`✗ road ${roadLabel(m.name)} is configured here and configured wrongly — ${m.reason}.\n    Fix: correct it, or unset it: this seat falls through to the next road and runs, so nothing else would have told you.`);
    }
    // What is deliberately NOT here: the executor, a name held empty, and a
    // name the box does not hold. Those three are facts about the BOX, said
    // once each below or in the verdict with every seat they cover named. The
    // first draft said all three per seat, and five seats short of the same
    // webhook printed five identical paragraphs that buried the one seat with
    // a problem of its own. What stays here is what is genuinely this seat's:
    // its scopes, its charter, and its roads.
    if (!lines.length) continue;
    out(`${p.agent}`);
    for (const l of lines) out(`  ${l}`);
    out("");
  }

  // The deep calls, one line each, named by the road rather than by the seat:
  // one call stands in for every seat that shares its binary, endpoint and
  // key, and saying it per seat would read as five calls when two were made.
  if (deep && deepByKey.size) {
    out("one turn, per road");
    for (const d of deepByKey.values()) {
      const covers = `covers ${d.agents.join(", ")}`;
      if (d.state === "ok") out(`  ✓ ${roadLabel(d.route)} (${d.model}) answered in ${d.turns ?? "?"} turn${d.turns === 1 ? "" : "s"} — ${covers}: the credentials this box holds for that road work`);
      else if (d.state === "unavailable") out(`  — ${roadLabel(d.route)} was not tried — ${covers}: ${d.says}`);
      else out(`  ✗ ${roadLabel(d.route)} refused — ${covers}: ${d.says}.\n      Fix: that sentence is the executor's own, verbatim — fix what it names and run this again.`);
    }
    out("");
  }

  // --- the two reports that are true whichever way the verdict goes --------
  // Said before the split, because an operator whose box is short of a name
  // AND has no engine wants to hear both before they start, not to fix one and
  // be stopped by the other. These used to live under the ✓ only, which meant
  // a refused box never mentioned the names at all — `epito validate` makes
  // the same point at length about its own two halves.
  const asides = [];
  if (env.missing.length) {
    asides.push(`${plural(env.missing.length, "name")} the manifests ask for ${env.missing.length > 1 ? "are" : "is"} not on this box (${env.missing.map((r) => r.name).join(", ")}): the runtime drops ${env.missing.length > 1 ? "them" : "it"} and the seats run without ${env.missing.length > 1 ? "them" : "it"} — a report, not a refusal, because nothing in a manifest says which names a seat cannot work without. \`epito env ${dirArg}\` says who asks for what, and \`--complete\` is where you assert the box should hold them all.`);
  }
  if (withBlocks.length) {
    // True only for a seat with no App here: the mint is not part of its runs.
    // A seat that HAS an App and an unmintable scope is in the refusals above,
    // because for that one the mint is the first thing the run does.
    const noMint = withBlocks.filter((p) => p.acts.state !== OWN && p.acts.state !== REFUSED);
    if (noMint.length) asides.push(`${plural(noMint.length, "seat")} above ${noMint.length === 1 ? "names a scope" : "name scopes"} this spec cannot mint: with no App on this box a RUN does not care, \`epito deploy\` and \`epito token\` refuse.`);
  }
  if (sharedSeats.length || noneSeats.length) {
    asides.push(`${plural(sharedSeats.length + noneSeats.length, "seat")} here ${sharedSeats.length + noneSeats.length === 1 ? "does" : "do"} not act as ${sharedSeats.length + noneSeats.length === 1 ? "itself" : "themselves"} (${[...sharedSeats, ...noneSeats].map((p) => p.agent).join(", ")}): ${sharedSeats.length ? "a shared credential belongs to a person, and every PR it opens is theirs" : "nothing authenticates the run's own \`gh\`"}. That is a report, not a refusal — it is how every seat ran before the identity leg. The block above names the two environment variables that change it per seat.`);
  }

  // --- the closing verdict -------------------------------------------------
  if (refusals.length) {
    out(`epito: a run on this box would refuse — ${plural(refusals.length, "reason")}:`);
    for (const r of refusals) out(`  ✗ ${r.says}${r.agents.length ? ` — ${r.agents.join(", ")}` : ""}`);
    for (const a of asides) out(`  — ${a}`);
    out(`\nThe ✗ lines above each name a fix. Nothing was started, nothing was registered on the engine, and nothing in ${dirArg} was changed.`);
    process.exit(1);
  }

  // What the look did not look at, once per kind of executor in this roster: a
  // claude seat and a LangGraph seat are unproven in different ways, and the
  // first seat's sentence is not the other's.
  const unproven = [...new Set(perSeat.map((p) => probeFor(p.executor.adapter).unproven))];
  out(`✓ nothing here would make a run on this box refuse: ${plural(n, "manifest")} good, every seat on an open road, the executor starts under a run's own environment, and ${engine.address} is ${engine.depth === "connect" ? "Temporal with namespace " + engine.namespace : "answering"}.`);
  if (!deep) {
    out(`  Not proven: ${unproven.join("; and ")}. \`epito doctor ${dirArg} --deep\` runs ONE turn per road ("${DEEP_PROMPT}") — which costs a model call and is the only thing that proves credentials from here.`);
  }
  for (const a of asides) out(`  ${a}`);
  process.exit(0);
}
