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
// on this box would refuse, and name the piece. Nine sections, in the order a
// run needs them — seven of them always, the bus only for a roster that
// subscribes to one, and the endings row only on a box that has already run
// something —
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
//   bus        for the seats `[trigger].subscriptions` wakes, whether this box
//              names a stream for them at all — a seat whose only trigger is
//              the bus, on a box with EPITO_BUS_STREAM unset, is a seat that
//              never fires, and until this row existed the way to find that
//              out was to publish an event and watch nothing happen. It reads
//              the box's settings and opens no connection; `epito bus <dir>`
//              is the one that asks the server what is actually waiting
//   worker     and whether anything is POLLING the queue the engine would put
//              that run on (src/temporal/pollers.js). Every other row above
//              asks whether a run would be ACCEPTED; this is the only one that
//              asks whether it would be performed, and the two come apart on
//              any box where `epitod-worker` died — the engine goes on taking
//              schedules and starting runs that nothing picks up
//   endings    and, looking backwards instead of forwards, what this box's own
//              run logs say happened to the runs that produced nothing — and
//              how many of those endings THIS build's refusal reader can name
//              (src/lib/runlogs.js). It is the only row here that reads
//              history, and it is here because of how its defect hides: the
//              reader shipped on 2026-10-18 matched none of the 37 refusals
//              the host recorded that day, with a green suite, and the gap
//              was found by a person typing a one-liner at a log directory.
//              A row costs one directory listing per seat and 16 KB per log,
//              touches no network, and never refuses
//
// And two halves that only `--deep` reaches, because they leave this box:
//
//   installed  for every seat with an App of its own, whether GitHub says that
//              App is installed on the repository it would mint for, and
//              whether the installation id this box names is that one
//              (src/lib/acts.js, rosterInstalled). Costs nothing: one GET per
//              (App, repo) pair, no token minted, no ledger line.
//   one turn   one real turn per road, which is the only thing that proves the
//              executor's credentials — and the only part of `--deep` that
//              costs a model call
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
//            not start, an engine that is not answering, an engine that is
//            answering with nothing polling the queue it would use (a run
//            there is accepted and never performed, which is the one failure
//            on this list that no surface used to report at all)
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
import { thisRuntime, buildNote } from "./lib/build.js";
import { busEnv, subscribingSeats } from "./lib/bus.js";
import { blockers, unchecked } from "./lib/readiness.js";
import { rosterEnv, askers, HELD, EMPTY, ABSENT } from "./lib/boxenv.js";
import { routesFor, liveRoutes, endpointLabel, DEFAULT_ROUTE } from "./lib/router.js";
import { lookAtExecutor, deepProbe, deepKey, probeFor, DEEP_PROMPT } from "./lib/probe.js";
import {
  actsAs, rosterInstalled, IDENTITY_FIX, INSTALL_UNPROVEN, INSTALL_REFUSES,
  OWN, REFUSED, HALF, SHARED, NONE, INSTALLED, MISMATCH, UNGRANTED, GH_REFUSED, UNREACHABLE,
} from "./lib/acts.js";
import { engineAddress, engineAnswering, engineFix, engineMissing, missingEnginePackage } from "./lib/engine.js";
// POLLED/UNASKED only: this file already has a HALF and a NONE, and they
// are acts.js's — half of an identity and no identity at all.
import { describeQueue, summarize, WORKER_REFUSES, POLLED, UNASKED } from "./temporal/pollers.js";
import { temporalEnv } from "./temporal/env.js";
import { surveyEndings, endingsSays } from "./lib/runlogs.js";
import { SPEC_VERSION } from "./lib/fields.js";

export const DOCTOR_FLAGS = [
  { name: "json", does: "the report as JSON" },
  { name: "deep", does: "ask the two questions that leave this box: is each agent's App installed where it would mint and what login its pull requests open as (free), and ONE real turn per road to prove the executor's credentials (a model call)" },
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
  if (!look.ok) return { ...look, address, namespace: cfg.namespace, depth: "tcp", client: false, taskQueue: cfg.taskQueue, pollers: null };
  let connect;
  try { ({ connect } = await importClient()); }
  catch (e) {
    // The engine client not being installed is the normal state of a laptop
    // and of every `npm i -g epito-cli`. Anything else — our own broken module —
    // is not ours to swallow.
    if (!missingEnginePackage(e)) throw e;
    return { ...look, address, namespace: cfg.namespace, depth: "tcp", client: false, taskQueue: cfg.taskQueue, pollers: null };
  }
  try {
    const { connection } = await connect({ env, quiet: true });
    // Who is polling, asked on the connection that is already open and inside
    // the same try: a `DescribeTaskQueue` that throws is a thing to report, not
    // a reason to call the engine down — the connect and the namespace check
    // have both just succeeded, and that is what the engine row states.
    let pollers = null, pollersError = null;
    try { pollers = await describeQueue(connection, { namespace: cfg.namespace, taskQueue: cfg.taskQueue }); }
    catch (e) { pollersError = e.message; }
    await connection.close().catch(() => {});
    return { ok: true, reason: null, address, namespace: cfg.namespace, depth: "connect", client: true, taskQueue: cfg.taskQueue, pollers, pollersError };
  } catch (e) {
    // connect() already speaks in the product's voice — the unreachable
    // sentence, or the missing-namespace one with the command that creates it.
    // An engine that answers a TCP connect and refuses a namespace check is
    // the case the TCP look reads as healthy, and it is the reason this half
    // exists at all.
    return { ok: false, reason: e.message, address, namespace: cfg.namespace, depth: "connect", client: true, answering: true, taskQueue: cfg.taskQueue, pollers: null };
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

  // Which epito this is. First, because it qualifies every row under it: a
  // preflight is believed, and a preflight run by a hand-patched runtime is a
  // preflight describing code nobody can read in the repository. It never
  // refuses — a hand-patched runtime starts runs perfectly well, which is
  // exactly why the host's went four weeks unnoticed — so it is a note and the
  // exit code is untouched.
  const build = thisRuntime();
  const buildSays = buildNote(build);

  const env = rosterEnv(roster, process.env);
  // The bus, from this box's settings and the manifests — no socket. `epito
  // bus` opens one because its question is "what is waiting"; this row's
  // question is "could anything be", and that one is answerable offline.
  const busCfg = busEnv();
  const busSeats = subscribingSeats(roster);
  // The seats for which the bus is the whole trigger. For a seat that also has
  // a cron, a missing stream means it fires late rather than never, and the
  // difference is worth a reader's attention.
  const busOnly = busSeats.filter(({ name }) => {
    const t = roster.get(name)?.manifest?.trigger ?? {};
    return !t.cron && !t.webhook;
  });
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

  // The installation look, for every seat that has an App of its own. Keyed
  // off the rows actsAs already produced, so the offline half and the online
  // half cannot disagree about which seats have one; a roster where no seat
  // does — this company's own, today — makes no request at all.
  const installed = deep ? await rosterInstalled(perSeat.map((p) => p.acts)) : [];
  for (const i of installed) perSeat.find((p) => p.agent === i.agent).installed = i;

  const engine = await engineLook();
  // Who is performing the work, from what that one connection already asked.
  // `asked` is false on every box where the question could not be put — no
  // engine answering, or no engine client installed — and the row says so
  // rather than reading an empty poller list as "nothing is polling": an
  // unasked question has never been evidence here.
  const worker = summarize(engine.pollers ?? {}, {
    taskQueue: engine.taskQueue,
    asked: Boolean(engine.pollers),
    error: engine.pollersError ?? null,
    // Which unasked this is — read off what actually happened, in order, and
    // never off `engine.client` alone. That field is false in TWO states: the
    // client is missing, and the TCP look failed so the client was never
    // reached for. Conflating them put two false clauses in one row on the
    // commonest box there is (no engine running): it claimed the client was
    // not installed when it was, and that the address "answered a TCP
    // connect" one line under `✗ engine … (ECONNREFUSED)`.
    because: !engine.ok
      ? engine.depth === "connect"
        // Something IS there and refused the connection this question needs —
        // a missing namespace, usually. The engine row above says which, so
        // this points at it rather than repeating it.
        ? `the engine at ${engine.address} answered and then refused the connection this question needs (see the engine row above)`
        : `nothing answered at ${engine.address}`
      : `the engine client is not installed on this box (${engine.address} answered a TCP connect, and asking who polls a queue takes a real gRPC connection)`,
  });

  // What already happened here, read by the build running now. Offline, and
  // deliberately last among the sections: every row above is about the next
  // run, and this one is about whether this build could have told you why the
  // last one never started.
  const endings = surveyEndings();
  const endingsNote = endingsSays(endings);

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

  // The installation answers, grouped the same way and for the same reason:
  // two seats sharing an App and a repository share an installation, so they
  // share a sentence and the seats it covers. A mismatch is the one answer
  // that is per seat — it is about an id THIS box names for THIS seat — and it
  // keeps its own line because its `says` carries that id.
  const installGroups = [];
  for (const i of installed) {
    const under = i.under ?? [];
    const key = `${i.state}|${i.says}|${i.fix}|${under.join("|")}`;
    const found = installGroups.find((g) => g.key === key);
    if (found) found.agents.push(i.agent);
    else installGroups.push({ key, state: i.state, says: i.says, fix: i.fix, under, agents: [i.agent] });
  }
  const badInstall = installGroups.filter((g) => INSTALL_REFUSES.has(g.state));

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
    // What `--deep` found at GitHub. Not "has no App" and not "GitHub could not
    // be reached": the first is how this product worked before the identity leg,
    // and the second is the kind of failure the run path RETRIES (identity.js
    // marks the difference with `permanent`, and acts.js reads that flag rather
    // than re-deciding here). These two are mints that would fail every time.
    ...badInstall.map((g) => ({
      agents: g.agents,
      says: g.state === MISMATCH
        ? "this box names an installation id for it that GitHub does not have, so the mint its run starts with is refused"
        : g.state === UNGRANTED
          ? "its App is installed where it would mint and was granted less there than its [identity].scopes need, so GitHub refuses the mint 422"
          : "it has a GitHub App on this box that GitHub will not mint for",
    })),
    ...refusedDeep.map((d) => ({ agents: d.agents, says: `the executor refused one turn on the road ${roadLabel(d.route)}` })),
    // The engine's own sentence, and a fix appended only when it does not
    // already carry one. A real connect that failed has said the exact thing
    // — an unreachable address, or a namespace that does not exist with the
    // command that creates it — and bolting "run `temporal server start-dev`"
    // onto "namespace nope does not exist" names the wrong fix for the
    // problem the line above just described.
    ...(engine.ok ? [] : [{ agents: [], says: `no engine: ${engine.depth === "connect" ? engine.reason : `${engineMissing(engine)}. Fix: ${engineFix(engine.address)}`}` }]),
    // And nothing performing the work. A fact about the box, so no seats —
    // the same shape the engine's own entry uses. Only ever added when the
    // question was actually put: UNASKED carries no refusal, because a box
    // with no engine has already refused one row up and a box without the
    // engine client cannot be asked at all.
    ...(WORKER_REFUSES.has(worker.state)
      ? [{ agents: [], says: `no worker: ${worker.says} Fix: ${worker.fix}` }]
      : []),
  ];

  const report = {
    dir: dirArg, spec: SPEC_VERSION,
    // `modified` is the list and not a count for the same reason the sentence
    // names the files: a machine reading this is deciding whether a `git pull`
    // on this box is safe, and that is a question about which files.
    build: {
      version: build.version, source: build.source, commit: build.commit, branch: build.branch,
      detached: build.detached, dirty: build.dirty, modified: build.modified, dir: build.dir,
      says: buildSays.text,
    },
    seats: perSeat.map((p) => ({
      agent: p.agent,
      ready: !refusals.some((r) => r.agents.includes(p.agent)),
      road: p.roads.takes ? { name: p.roads.takes.name, model: p.roads.takes.model, endpoint: endpointLabel(p.roads.takes) } : null,
      closedRoads: p.roads.closed,
      executor: { adapter: p.executor.adapter, binary: p.executor.binary, path: p.executor.path, state: p.executor.state, version: p.executor.version },
      // The App id and the source are facts about which principal, never the
      // key itself: the same line the audit log keeps (spec rule 1).
      identity: {
        state: p.acts.state, source: p.acts.source, appId: p.acts.appId, installation: p.acts.installation, says: p.acts.says,
        // Only `--deep` asks, so `null` here means unasked and never "fine":
        // `declared` is the id this box names, `installation` the one GitHub
        // named, and `status` GitHub's own code where it refused — 404 (not
        // installed there) and 401 (an id and a key from different Apps) are
        // two different fixes, and this is where a machine reads which.
        installed: p.installed
          // `login` is the one field here that is not about whether the mint
          // would work: it is who the pull request opens as, which is the
          // question the identity leg exists for and the only place it is
          // knowable. Null means not asked or not answered, never a guess.
          ? { state: p.installed.state, declared: p.installed.declared, installation: p.installed.installation, status: p.installed.status, login: p.installed.login ?? null, says: p.installed.says }
          : null,
      },
      names: { asked: p.env.asked.length, held: p.env.held.length, missing: p.env.missing, empty: p.env.empty },
      blocks: p.blocks.map((b) => b.problem),
      notes: p.notes,
      deep: p.deep ? { state: p.deep.state, route: p.deep.route, turns: p.deep.turns ?? null, says: p.deep.says ?? null } : null,
    })),
    engine: { address: engine.address, namespace: engine.namespace, ok: engine.ok, depth: engine.depth, reason: engine.reason ?? null },
    // `stream: null` is the whole answer this row exists for: the box names no
    // stream, so whatever the manifests subscribe to, nothing is consumed
    // here. `asked: false` says this row opened no connection, so a reader of
    // the JSON never reads silence as "the bus is fine".
    bus: {
      url: busCfg.url, stream: busCfg.stream, group: busCfg.group, asked: false,
      seats: busSeats.map(({ name, subjects }) => ({ agent: name, subjects, onlyTrigger: busOnly.some((b) => b.name === name) })),
    },
    // The worker, as its own object rather than a field of `engine`: they are
    // two processes on a provisioned host and the whole point of this row is
    // that one of them can be fine while the other is gone. `state` is the
    // machine-readable answer (polled / half / none / unasked), and `unasked`
    // never means fine — it means this box could not put the question.
    worker: {
      taskQueue: worker.taskQueue, state: worker.state,
      pollers: { workflow: worker.live.workflow, activity: worker.live.activity },
      remembered: { workflow: worker.stale.workflow, activity: worker.stale.activity },
      // What is waiting, by half, because the two halves mean opposite things:
      // a workflow backlog is a queue nothing is working, an activity backlog
      // is runs waiting for a slot on a worker that is working (see
      // temporal/pollers.js, notes 3 and 4).
      backlog: worker.backlog,
      workers: worker.workers.map((w) => ({ identity: w.identity, lastPolledMsAgo: w.agoMs })),
      says: worker.says,
    },
    deep: deep ? [...deepByKey.values()].map((d) => ({ route: d.route, model: d.model, state: d.state, turns: d.turns ?? null, says: d.says ?? null })) : null,
    // One entry per seat with an App — not per request, which is what `deep`
    // above is — and `key` is what says which of them shared one: two seats on
    // the same App and repo carry the same key and cost one request.
    installed: deep ? installed.map((i) => ({ agent: i.agent, key: i.key, appId: i.appId, repo: i.repo, state: i.state, declared: i.declared, installation: i.installation, status: i.status, slug: i.slug ?? null, login: i.login ?? null })) : null,
    // Backwards-looking, and shaped so a machine can watch the gap rather
    // than the prose: `ended` is how many runs produced nothing, `named` how
    // many of those this build can read as a refusal, and `unnamed` the
    // newest few it cannot, each with the sentence it ended on.
    endings: {
      window_hours: endings.hours, runs: endings.runs, ended: endings.ended,
      named: endings.named, withReset: endings.withReset, kinds: endings.kinds,
      unnamed: endings.unnamed.map((u) => ({ agent: u.seat, at: new Date(u.at).toISOString(), exit: u.exit, turns: u.turns, says: u.says })),
      unnamedCount: endings.unnamedCount ?? endings.unnamed.length,
      // Endings the box produced rather than the provider — a signal, a
      // timeout, a daemon restart. Counted apart from the unread ones so a
      // watcher cannot read a restart as a reader that has fallen behind.
      stoppedByTheBox: endings.stoppedCount ?? 0,
      stopped: (endings.stopped ?? []).map((u) => ({ agent: u.seat, at: new Date(u.at).toISOString(), exit: u.exit, was: u.was })),
      unreadable: endings.skipped, says: endingsNote.text,
    },
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

  // build
  row("build", buildSays.level === "ok" ? "ok" : "note", buildSays.text);

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

  // installed — the identity row's online half, and printed beside it rather
  // than with the other --deep row at the bottom for the reason the sections
  // are in this order at all: a run with an App mints before it spawns
  // anything, so this is where an operator reading top to bottom needs it.
  if (deep && installed.length) {
    const okInstall = installed.filter((i) => i.state === INSTALLED);
    const unasked = installed.filter((i) => i.state === UNREACHABLE);
    const apps = new Set(installed.map((i) => i.key)).size;
    const badSeats = badInstall.flatMap((g) => g.agents);
    row("installed", badSeats.length ? "bad" : unasked.length ? "note" : "ok",
      badSeats.length
        ? `${plural(badSeats.length, "seat")} ${badSeats.length === 1 ? "has an App" : "have Apps"} GitHub will not mint for (${badSeats.join(", ")})`
        : unasked.length === installed.length
          ? `GitHub could not be asked from this box about ${plural(apps, "App")}, covering ${plural(installed.length, "seat")}`
          : unasked.length
            ? `${plural(apps, "App")} asked at GitHub for ${plural(installed.length, "seat")}, ${okInstall.length} installed where ${okInstall.length === 1 ? "it" : "they"} would mint, ${unasked.length} GitHub did not answer about`
          : `${plural(apps, "App")} asked at GitHub for ${plural(installed.length, "seat")}, every one installed on the ${apps === 1 ? "repository" : "repositories"} it would mint for`);
  }

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

  // worker — the engine row's other half, and the only row here about whether
  // a run is PERFORMED. A box that could not be asked gets a note and no
  // refusal: the engine row above has already said why, and an unasked
  // question must not read as an answer in either direction.
  row("worker", WORKER_REFUSES.has(worker.state) ? "bad" : worker.state === UNASKED ? "note" : "ok", worker.says);

  // bus — printed only for a roster that asks for it. Every other row is a
  // piece every run needs; a roster where nobody subscribes is not missing a
  // bus, it simply has no events to be woken by, and a permanent "0 seats"
  // line would be the kind of row an operator learns to skip.
  if (busSeats.length) {
    const who = busSeats.map((b) => b.name).join(", ");
    row("bus", busCfg.stream ? "ok" : "note",
      busCfg.stream
        ? `stream "${busCfg.stream}" at ${busCfg.url} for ${plural(busSeats.length, "seat")} (${who}) — this row read the box's settings and opened nothing; \`epito bus ${dirArg}\` asks the server what is waiting`
        : `${plural(busSeats.length, "seat")} ${busSeats.length === 1 ? "is woken" : "are woken"} by the bus (${who}) and this box names no stream${busOnly.length ? `, so ${busOnly.length === busSeats.length ? (busOnly.length === 1 ? "it never fires" : "they never fire") : `${busOnly.map((b) => b.name).join(", ")} never fires`}` : `, so those events do not reach ${busSeats.length === 1 ? "it" : "them"}`}`);
  }
  // endings — printed only when this box has logs to read, for the reason the
  // bus row is conditional too: a permanent "0 runs" line on a fresh box is a
  // row an operator learns to skip, and this one has to be read on the day it
  // changes. Never a refusal: an unread ending does not stop the next run.
  if (endings.looked && endings.runs) row("endings", endingsNote.level, endingsNote.text);

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

  // --- and whether GitHub has that App, once per App -----------------------
  // Printed whole whenever `--deep` asked, ✓ rows included: the flag is an
  // operator saying "go and check", and the answer to that is the table, not
  // only its exceptions. One line per (App, repo) with the seats it covers,
  // because that is what one request covers — except a mismatch, which is
  // about an id this box names for one seat and so is always its own line.
  if (installGroups.length) {
    out("installed, per App");
    for (const g of installGroups) {
      const mark = g.state === INSTALLED ? "✓" : g.state === UNREACHABLE ? "!" : "✗";
      out(`  ${mark} ${g.says} — covers ${g.agents.join(", ")}`);
      if (g.fix) out(`      Fix: ${g.fix}.`);
      // After the fix, never instead of it: these are the page that performs
      // the fix the sentence just named, and the login a ✓ row opens its pull
      // requests as. A row with no fix can still have one (see acts.js).
      for (const u of g.under ?? []) out(`      ${u}`);
    }
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
  const unasked = installed.filter((i) => i.state === UNREACHABLE);
  if (unasked.length) {
    asides.push(`${plural(unasked.length, "seat")} with an App of its own could not be checked at GitHub from this box (${unasked.map((i) => i.agent).join(", ")}): that is a report, not a refusal, for the same reason the runtime retries it — a blocked route and a rate limit are the kind of mint failure that passes, and an App installed nowhere is the kind that never does. The block above carries GitHub's own words. Nothing else about ${unasked.length === 1 ? "that seat" : "those seats"} is in doubt: ${unasked.length === 1 ? "its" : "their"} key signs here.`);
  }
  if (busSeats.length && !busCfg.stream) {
    asides.push(`EPITO_BUS_STREAM is not set here, so ${plural(busSeats.length, "seat")} that ${busSeats.length === 1 ? "subscribes" : "subscribe"} (${busSeats.map((b) => b.name).join(", ")}) ${busSeats.length === 1 ? "is" : "are"} woken by no event${busOnly.length ? `, and ${busOnly.map((b) => b.name).join(", ")} ${busOnly.length === 1 ? "has" : "have"} no other trigger at all` : ""}. That is a report, not a refusal: \`epito run ${dirArg}\` says the same on startup and keeps serving, because a bus is one trigger and not the only one. Fix: set EPITO_BUS_STREAM to the stream that carries those subjects, and EPITO_BUS_URL if the bus is not ${busCfg.url}.`);
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
  // The engine clause and the worker clause are two clauses for the reason the
  // rows are two rows: "Temporal is there" was the end of this sentence on
  // every box where nothing was doing the work.
  out(`✓ nothing here would make a run on this box refuse: ${plural(n, "manifest")} good, every seat on an open road, the executor starts under a run's own environment, and ${engine.address} is ${engine.depth === "connect" ? "Temporal with namespace " + engine.namespace : "answering"}${worker.state === POLLED ? `, with ${worker.workers.length === 1 ? "a worker" : `${worker.workers.length} workers`} polling ${worker.taskQueue}` : ""}.`);
  if (worker.state === UNASKED) {
    out(`  — whether anything is POLLING ${worker.taskQueue} was not asked: ${worker.says.replace(/^not asked — /, "")}. A run accepted by an engine no worker is polling waits forever rather than failing, so this is the one thing above that a ✓ here does not cover.`);
  }
  if (!deep) {
    // Two gaps, and only one of them costs anything to close — so they are
    // named apart rather than behind one price. A roster with no App of its
    // own has nothing to prove in the second half, and is not told about it.
    const gaps = ownSeats.length ? [...unproven, INSTALL_UNPROVEN] : unproven;
    out(`  Not proven: ${gaps.join("; and ")}. \`epito doctor ${dirArg} --deep\` asks both: ONE turn per road ("${DEEP_PROMPT}"), which costs a model call and is the only thing that proves the executor's credentials from here${ownSeats.length ? `, and one free GET at GitHub per App, which is the only thing that proves an installation` : ""}.`);
  }
  for (const a of asides) out(`  ${a}`);
  process.exit(0);
}
