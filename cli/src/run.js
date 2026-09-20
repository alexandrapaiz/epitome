// `epito run <dir>`: the resident runtime (epitod v0). One long-lived process:
//   - loads every agent.toml under <dir> through the same validator as
//     `epito validate`; a broken manifest stops the daemon at startup, loudly
//   - a 30-second tick checks each [trigger].cron against the current UTC
//     minute (lib/cron.js) and enqueues a run when it matches
//   - a node:http server (lib/hooks.js) turns POST /hooks/<name> into a run
//   - one run at a time per agent: a run arriving while one is in progress
//     is coalesced into a single follow-up run, never dropped, never stacked
//   - every event is one line in .epito/audit.jsonl; the roster snapshot is
//     .epito/state.json, which `epito ps` prints
import { readdirSync, statSync } from "node:fs";
import { join, resolve } from "node:path";
import { loadManifest } from "./lib/manifest.js";
import { parseCron, cronMatches, nextCronFire } from "./lib/cron.js";
import { startHookServer } from "./lib/hooks.js";
import { runAgent } from "./lib/runner.js";
import { appendAudit, writeState, readState, AUDIT_PATH, STATE_PATH } from "./lib/audit.js";

const TICK_MS = 30_000;
const DEFAULT_TIMEOUT_MS = 60 * 60 * 1000;
const DEFAULT_PORT = 4747;
const SKIP = new Set(["node_modules", ".git", ".epito"]);

const ts = () => new Date().toISOString();
const log = (msg) => console.log(`${ts()} ${msg}`);

function findManifests(dir, depth = 0, out = []) {
  for (const ent of readdirSync(dir)) {
    if (SKIP.has(ent)) continue;
    const p = join(dir, ent);
    const st = statSync(p);
    if (st.isDirectory() && depth < 4) findManifests(p, depth + 1, out);
    else if (ent === "agent.toml") out.push(p);
  }
  return out;
}

// Load the roster or exit(1) with every problem named, in the validator's voice.
function loadRoster(dir) {
  const paths = findManifests(dir);
  if (paths.length === 0) { console.error(`epito: no agent.toml found under ${dir} — an empty roster has nothing to run`); process.exit(1); }
  const agents = new Map();
  let bad = 0;
  for (const p of paths) {
    const { manifest, errors } = loadManifest(p);
    const errs = [...errors];
    if (manifest?.runtime && !manifest.runtime.repo) errs.push("[runtime].repo is required by `epito run`: the runtime clones owner/name fresh for every run, so it must know which repository the charter lives in");
    if (manifest?.trigger?.cron) { try { parseCron(manifest.trigger.cron); } catch (e) { errs.push(`[trigger].cron: ${e.message}`); } }
    if (manifest?.agent?.name && agents.has(manifest.agent.name)) errs.push(`[agent].name "${manifest.agent.name}" is already used by ${agents.get(manifest.agent.name).path} — one manifest, one principal`);
    if (errs.length) {
      bad++;
      console.error(`${p}: ${errs.length} problem${errs.length > 1 ? "s" : ""}\n`);
      for (const e of errs) console.error(`  ✗ ${e}`);
      console.error("");
      continue;
    }
    agents.set(manifest.agent.name, { path: p, manifest, cron: manifest.trigger.cron ? parseCron(manifest.trigger.cron) : null });
  }
  if (bad) { console.error(`epito: ${bad} of ${paths.length} manifest${paths.length > 1 ? "s" : ""} refused; fix them and start again — a roster runs whole or not at all`); process.exit(1); }
  return agents;
}

export async function runDaemon(dirArg) {
  const dir = resolve(dirArg);
  const roster = loadRoster(dir);
  const executor = process.env.EPITO_EXECUTOR || "claude";
  const timeoutMs = Number(process.env.EPITO_RUN_TIMEOUT_MS) || DEFAULT_TIMEOUT_MS;
  const port = Number(process.env.EPITO_PORT) || DEFAULT_PORT;
  const secret = process.env.EPITO_HOOK_SECRET || "";

  // Per-agent runtime state. `running` is the mutex; `pending` is the
  // coalesced follow-up trigger (kept as the latest one, with a count).
  const state = new Map();
  for (const [name, a] of roster) {
    state.set(name, { running: false, pending: null, coalesced: 0, lastFiredMinute: null, lastRun: null, child: null,
      nextCron: a.cron ? nextCronFire(a.cron)?.toISOString() ?? null : null });
  }

  const snapshot = () => {
    const agents = {};
    for (const [name, a] of roster) {
      const s = state.get(name);
      agents[name] = { model: a.manifest.runtime.model, repo: a.manifest.runtime.repo, cron: a.manifest.trigger.cron ?? null,
        running: s.running, pending: s.pending, nextCron: s.nextCron, lastRun: s.lastRun };
    }
    writeState({ pid: process.pid, startedAt, dir, port, executor, updatedAt: ts(), agents });
  };
  const startedAt = ts();

  async function startRun(name, trigger, hookBody) {
    const a = roster.get(name);
    const s = state.get(name);
    s.running = true;
    s.lastRun = { trigger, startedAt: ts(), exit: null, durationMs: null, pr: null, log: null };
    snapshot();
    appendAudit({ agent: name, action: "run.start", trigger, model: a.manifest.runtime.model });
    log(`${name}: run.start (${trigger})`);
    const r = await runAgent({ agent: a.manifest, trigger, hookBody, executor, timeoutMs, log, onSpawn: (c) => (s.child = c) });
    s.child = null;
    s.lastRun = { ...s.lastRun, exit: r.exit, durationMs: r.durationMs, pr: r.pr, log: r.log, endedAt: ts() };
    appendAudit({ agent: name, action: "run.end", trigger, model: a.manifest.runtime.model, exit: r.exit, durationMs: r.durationMs, ...(r.pr ? { pr: r.pr } : {}) });
    log(`${name}: run.end exit=${r.exit} ${r.durationMs}ms${r.pr ? ` pr=${r.pr}` : ""} log=${r.log}`);
    s.running = false;
    if (s.pending) {
      const next = s.pending; const n = s.coalesced;
      s.pending = null; s.coalesced = 0;
      log(`${name}: starting the coalesced run (${n} trigger${n > 1 ? "s" : ""} arrived during the last run)`);
      snapshot();
      return startRun(name, next.trigger, next.hookBody);
    }
    snapshot();
  }

  // The single entry point for both triggers. Returns what happened.
  function enqueue(name, trigger, hookBody, extra = {}) {
    const s = state.get(name);
    if (s.running) {
      s.pending = { trigger, hookBody }; s.coalesced++;
      appendAudit({ agent: name, action: trigger, trigger, ...extra, coalesced: true });
      log(`${name}: ${trigger} while running — coalesced (${s.coalesced} pending)`);
      snapshot();
      return "coalesced";
    }
    appendAudit({ agent: name, action: trigger, trigger, ...extra });
    startRun(name, trigger, hookBody);
    return "started";
  }

  // Cron: every tick, fire each agent whose expression matches this UTC
  // minute, at most once per minute (two ticks land in every minute).
  function tick() {
    const now = new Date();
    const minute = Math.floor(now.getTime() / 60_000);
    for (const [name, a] of roster) {
      if (!a.cron) continue;
      const s = state.get(name);
      if (s.lastFiredMinute === minute || !cronMatches(a.cron, now)) continue;
      s.lastFiredMinute = minute;
      s.nextCron = nextCronFire(a.cron, now)?.toISOString() ?? null;
      log(`${name}: cron "${a.manifest.trigger.cron}" matched ${now.toISOString().slice(0, 16)}Z`);
      enqueue(name, "cron");
    }
  }
  const timer = setInterval(tick, TICK_MS);
  tick();

  const server = startHookServer({ port, secret, log, onHook: (name, body) => {
    if (!roster.has(name)) return { status: 404, body: { error: `no agent named "${name}" in this roster` } };
    const outcome = enqueue(name, "hook", body || undefined, { bytes: body.length });
    return { status: 202, body: { agent: name, outcome } };
  } });

  log(`epito run: ${roster.size} agent${roster.size > 1 ? "s" : ""} from ${dir}; executor=${executor}; audit=${AUDIT_PATH}; state=${STATE_PATH}`);
  for (const [name, a] of roster) log(`  ${name}: repo=${a.manifest.runtime.repo} model=${a.manifest.runtime.model} cron=${a.manifest.trigger.cron ?? "-"} next=${state.get(name).nextCron ?? "-"}`);
  if (!secret) log("EPITO_HOOK_SECRET is not set: hooks answer 503 until it is");
  snapshot();

  const shutdown = (sig) => {
    log(`${sig}: shutting down`);
    clearInterval(timer);
    server.close();
    for (const [name, s] of state) if (s.child) { log(`${name}: killing in-flight run`); try { process.kill(-s.child.pid, "SIGTERM"); } catch {} }
    appendAudit({ agent: null, action: "daemon.stop", signal: sig });
    setTimeout(() => process.exit(0), 300);
  };
  process.on("SIGINT", () => shutdown("SIGINT"));
  process.on("SIGTERM", () => shutdown("SIGTERM"));
  appendAudit({ agent: null, action: "daemon.start", dir, executor, port });
  await new Promise(() => {}); // resident: only a signal ends this
}

// `epito ps`: the roster as the daemon last wrote it.
export function ps() {
  const st = readState();
  if (!st) { console.error(`epito: no ${STATE_PATH} here — start \`epito run <dir>\` in this directory first`); process.exit(1); }
  const alive = (() => { try { process.kill(st.pid, 0); return true; } catch { return false; } })();
  console.log(`epitod pid ${st.pid} (${alive ? "alive" : "not running"}) dir=${st.dir} port=${st.port} executor=${st.executor} updated=${st.updatedAt}`);
  const rows = [["AGENT", "MODEL", "STATUS", "LAST RUN", "EXIT", "MS", "NEXT CRON", "PR"]];
  for (const [name, a] of Object.entries(st.agents)) {
    const status = a.running ? (a.pending ? "running +1 queued" : "running") : "idle";
    rows.push([name, a.model, status, a.lastRun ? `${a.lastRun.startedAt.slice(0, 19)}Z ${a.lastRun.trigger}` : "-",
      a.lastRun?.exit === null || a.lastRun?.exit === undefined ? "-" : String(a.lastRun.exit),
      a.lastRun?.durationMs != null ? String(a.lastRun.durationMs) : "-", a.nextCron ? a.nextCron.slice(0, 16) + "Z" : "-", a.lastRun?.pr ?? "-"]);
  }
  const w = rows[0].map((_, i) => Math.max(...rows.map((r) => r[i].length)));
  for (const r of rows) console.log(r.map((c, i) => c.padEnd(w[i])).join("  ").trimEnd());
}
