// Can this box actually START this seat? The question `epito validate`,
// `epito routes` and `epito env` all stop one step short of.
//
// Those three read files and the environment. Nothing reads the one thing a
// run cannot do without: the executable epito spawns. The manifests can be
// perfect, every road open and every name held, and the run still ends at
// turn zero because the binary is on the operator's interactive PATH and not
// on the runtime unit's, or because it is there and cannot see its own
// credentials under the environment a run hands it. That is not a
// hypothetical — it is epitod v0's first real run, which exited 1 with "Not
// logged in" until USER joined the allowlist (src/lib/runenv.js).
//
// So there are two probes here and they prove different amounts, which is the
// whole design:
//
//   the look   resolve the binary on the PATH a RUN gets, then spawn it with
//              the run's own environment allowlist and the adapter's cheapest
//              argv (`--version`). Free, offline, instant. It proves the file
//              exists, is executable by this user, and starts under the
//              environment a run gives it. It does NOT prove the executor is
//              logged in, and says so.
//   the deep   one real run of one turn, through the SAME adapter command a
//              run uses, reading the result contract back. It proves the
//              credentials and the road. It costs a model call, which is why
//              it is `--deep` and not the default.
//
// Neither probe is the adapter's secret: `PROBES` is a table beside
// src/lib/adapters.js's, keyed the same way, because what "cheapest argv"
// means is a property of the kind of executor and of nothing else.
import { spawn } from "node:child_process";
import { existsSync, statSync, accessSync, constants } from "node:fs";
import { tmpdir } from "node:os";
import { join, isAbsolute } from "node:path";
import { adapterFor, LANGGRAPH_SHIM } from "./adapters.js";
import { baseRunEnv } from "./runenv.js";
import { parseExecutorResult } from "./runner.js";
import { endpointLabel } from "./router.js";

export const LOOK_TIMEOUT_MS = 10_000;
export const DEEP_TIMEOUT_MS = 180_000;

// The one-turn prompt. Short, answerable without tools, and it asks for a word
// back so the result contract carries evidence rather than an empty success.
export const DEEP_PROMPT = "Reply with the single word: ok. Do nothing else.";

export const PROBES = {
  claude: {
    look: ["--version"],
    // What the look proves, in the sentence the report prints. Said per
    // adapter because it is not the same claim for an interpreter as it is for
    // an executor that holds its own login.
    proves: "the executor epito spawns runs under the environment a run gives it",
    unproven: "that it is logged in — the look never reaches a provider, so a box with an expired session passes it",
    deep: true,
  },
  langgraph: {
    look: ["--version"],
    proves: "the interpreter epito spawns runs under the environment a run gives it",
    // A LangGraph seat's graph is resolved from the `langgraph.json` in its own
    // repository, which exists on this box only inside a clone a run makes. So
    // this is as far as a preflight can honestly go, and the half it cannot
    // reach is named rather than implied.
    unproven: "that this seat's graph imports — `langgraph.json` is read inside the run's clone, which no preflight has",
    deep: false,
    // The shim ships with epito (package.json `files`), so a missing one is a
    // broken install of ours and not a thing the operator did.
    extra: () => (existsSync(LANGGRAPH_SHIM) ? null : `epito's own LangGraph shim is missing from this install (${LANGGRAPH_SHIM}) — reinstall the CLI (\`npm i -g epito\`)`),
  },
};

export const probeFor = (adapter) => PROBES[adapter] ?? PROBES.claude;

// Where the binary a run spawns actually is, resolved on the PATH a RUN gets
// rather than on this shell's. Returns an absolute path, or null with the
// reason the search failed — "nothing by that name" and "it is there and not
// executable" are different fixes.
export function whichIn(binary, env = process.env) {
  const named = String(binary ?? "");
  if (!named) return { path: null, reason: "the adapter named no executable" };
  const runnable = (p) => {
    try { if (!statSync(p).isFile()) return false; accessSync(p, constants.X_OK); return true; }
    catch { return false; }
  };
  if (named.includes("/")) {
    const abs = isAbsolute(named) ? named : join(process.cwd(), named);
    if (!existsSync(abs)) return { path: null, reason: `no such file ${named}` };
    if (!runnable(abs)) return { path: null, reason: `${named} is not executable by this user` };
    return { path: abs, reason: null };
  }
  const dirs = String(env.PATH ?? "").split(":").filter(Boolean);
  if (!dirs.length) return { path: null, reason: "the PATH a run gets is empty, so a bare name resolves to nothing" };
  let sawUnrunnable = null;
  for (const d of dirs) {
    const p = join(d, named);
    if (!existsSync(p)) continue;
    if (runnable(p)) return { path: p, reason: null };
    sawUnrunnable ??= p;
  }
  return {
    path: null,
    reason: sawUnrunnable
      ? `${sawUnrunnable} is on the PATH a run gets and is not executable by this user`
      : `"${named}" is not on the PATH a run gets (${dirs.length} director${dirs.length === 1 ? "y" : "ies"})`,
  };
}

// Spawn something and come back with its ending, never with a throw: every
// failure here is an operating condition the report has a line for.
function run(file, args, { env, timeoutMs, spawnImpl = spawn }) {
  return new Promise((resolve) => {
    const started = Date.now();
    let child;
    try { child = spawnImpl(file, args, { cwd: tmpdir(), env, stdio: ["ignore", "pipe", "pipe"] }); }
    catch (e) { return resolve({ exit: "spawn", out: e.message, ms: 0 }); }
    let out = "";
    const take = (d) => { out = (out + d).slice(-64 * 1024); };
    child.stdout?.on("data", take);
    child.stderr?.on("data", take);
    let timedOut = false;
    const timer = setTimeout(() => { timedOut = true; try { child.kill("SIGKILL"); } catch {} }, timeoutMs);
    let settled = false;
    const done = (v) => { if (settled) return; settled = true; clearTimeout(timer); resolve({ ...v, ms: Date.now() - started }); };
    child.on("error", (e) => done({ exit: "spawn", out: e.message }));
    child.on("close", (code, signal) => done({ exit: timedOut ? "timeout" : (code ?? signal), out }));
  });
}

// The first line of output, which is what `--version` is. Trimmed to one line
// because an executor that prints a banner is still answering.
const firstLine = (s) => String(s ?? "").split("\n").map((l) => l.trim()).find(Boolean) ?? "";

// The look, for one seat. Returns
// { adapter, binary, path, state, says, fix, exit, version }
// where `state` is "ok" | "missing" | "broken" — missing means a run would die
// at spawn, broken means the file is there and did not start.
export async function lookAtExecutor(manifest, { env = process.env, spawnImpl = spawn, timeoutMs = LOOK_TIMEOUT_MS } = {}) {
  const adapter = adapterFor(manifest);
  const probe = probeFor(adapter.name);
  // EPITO_EXECUTOR is read from the WORKER's environment, not from the child's
  // allowlist — that is where runner.js reads it, and a probe that read it
  // somewhere else would resolve a different binary than a run spawns.
  const binary = adapter.binary(env, null);
  const base = { adapter: adapter.name, binary, proves: probe.proves, unproven: probe.unproven };
  const found = whichIn(binary, baseRunEnv(manifest, env));
  if (!found.path) {
    return { ...base, path: null, state: "missing", exit: null, version: null,
      says: found.reason,
      fix: adapter.name === "langgraph"
        ? `install the interpreter this seat's app runs in, or set EPITO_PYTHON to the one you have (it is currently ${env.EPITO_PYTHON ? `"${env.EPITO_PYTHON}"` : "unset, so epito looks for \"python3\""})`
        : `install the executor on the PATH the runtime unit gets — not only the one your login shell has — or set EPITO_EXECUTOR to its absolute path (it is currently ${env.EPITO_EXECUTOR ? `"${env.EPITO_EXECUTOR}"` : "unset, so epito looks for \"claude\""})`,
    };
  }
  const broken = probe.extra?.();
  if (broken) return { ...base, path: found.path, state: "broken", exit: null, version: null, says: broken, fix: "reinstall epito" };
  const r = await run(found.path, probe.look, { env: baseRunEnv(manifest, env), timeoutMs, spawnImpl });
  if (r.exit !== 0) {
    return { ...base, path: found.path, state: "broken", exit: r.exit, version: null,
      says: `${found.path} ${r.exit === "timeout" ? `did not answer \`${probe.look.join(" ")}\` within ${timeoutMs}ms` : `exited ${r.exit} on \`${probe.look.join(" ")}\``} under the environment a run gives it${firstLine(r.out) ? `: ${firstLine(r.out)}` : ""}`,
      fix: `run \`${binary} ${probe.look.join(" ")}\` yourself with only PATH, HOME, USER and this seat's [runtime].env set — a binary that needs a variable the allowlist does not carry fails exactly here, and the fix is to name that variable in [runtime].env`,
    };
  }
  return { ...base, path: found.path, state: "ok", exit: 0, version: firstLine(r.out), says: null, fix: null };
}

// The deep probe: one real run of one turn, on one road, through the adapter's
// own command. `route` is the road the router picked for this seat, so the call
// goes exactly where a run's first attempt would.
//
// Keyed by what actually changes the answer — the binary, and the endpoint and
// key the road reaches — so five seats on one road cost one call and not five.
export const deepKey = (binary, route) =>
  [binary, route?.name ?? "default", route?.model ?? "", endpointLabel(route) ?? "", route?.tokenEnv ?? ""].join("|");

export async function deepProbe(manifest, route, { env = process.env, spawnImpl = spawn, timeoutMs = DEEP_TIMEOUT_MS, binary = null } = {}) {
  const adapter = adapterFor(manifest);
  const probe = probeFor(adapter.name);
  const file = binary ?? adapter.binary(env, null);
  if (!probe.deep) {
    return { state: "unavailable", says: `the ${adapter.name} adapter has no one-turn probe: ${probe.unproven}`, turns: null, result: null };
  }
  const cmd = adapter.command({ manifest, name: manifest.agent.name, runId: "doctor", trigger: "doctor", prompt: DEEP_PROMPT, resume: null, binary: file, route });
  const childEnv = { ...baseRunEnv(manifest, env), ...(cmd.env ?? {}), ...(adapter.routeEnv?.(route, env) ?? {}) };
  const r = await run(cmd.file, cmd.args, { env: childEnv, timeoutMs, spawnImpl });
  const { turns, result, detail } = parseExecutorResult(r.out);
  if (r.exit === 0) {
    return { state: "ok", says: null, turns, result: result ?? detail ?? null, ms: r.ms };
  }
  // The executor's own refusal, verbatim: "Not logged in", a rationed
  // provider's concurrency sentence, a model name it does not have. Reading
  // it out is the entire value of this probe — a paraphrase would be epito
  // guessing at a provider's rules.
  return {
    state: "refused", turns, result: result ?? detail ?? null, ms: r.ms,
    exit: r.exit,
    says: `${file} ${r.exit === "timeout" ? `did not finish one turn within ${timeoutMs}ms` : `exited ${r.exit}`} on route "${route?.name ?? "default"}"${result || detail ? `: ${firstLine(result ?? detail)}` : firstLine(r.out) ? `: ${firstLine(r.out)}` : ""}`,
  };
}
