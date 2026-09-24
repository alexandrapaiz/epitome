// `epito run <dir>`: the resident runtime (epitod v0). One long-lived process:
//   - loads every agent.toml under <dir> through the same validator as
//     `epito validate`; a broken manifest stops the daemon at startup, loudly
//   - a 30-second tick checks each [trigger].cron against the current UTC
//     minute (lib/cron.js) and enqueues a run when it matches
//   - a node:http server (lib/hooks.js) turns POST /hooks/<name> into a run,
//     POST /message/<name> into a word in an agent's ear, and
//     POST /window/open|close into presence
//   - one run at a time per agent: a run arriving while one is in progress
//     is coalesced into a single follow-up run, never dropped, never stacked
//   - every event is one line in .epito/audit.jsonl; the roster snapshot is
//     .epito/state.json, which `epito ps` prints
//
// Presence, in one paragraph. A *window* is a stretch of wall-clock time
// (default 4h) during which an agent is expected to be spoken to. Opening one
// fires the agent once with the synchronous instruction; the executor's
// session_id from that run is held, along with the clone it ran in, so a
// later `POST /message/<name>` continues that same conversation with
// `--resume`. Closing the window — by hand or by the clock — discards the id
// and deletes the clone: the PRs are the record (ADR-2, repo-as-state), the
// session is not.
import { rmSync } from "node:fs";
import { resolve } from "node:path";
import { loadManifest, findManifests } from "./lib/manifest.js";
import { parseCron, cronMatches, nextCronFire } from "./lib/cron.js";
import { startHookServer } from "./lib/hooks.js";
import { runAgent, windowInstruction } from "./lib/runner.js";
import { postToSlack } from "./lib/slack.js";
import { appendAudit, writeState, readState, AUDIT_PATH, STATE_PATH } from "./lib/audit.js";

const TICK_MS = 30_000;
const SWEEP_MS = 5_000; // how punctually a window's wall-clock deadline is honoured
const DEFAULT_TIMEOUT_MS = 60 * 60 * 1000;
const DEFAULT_WINDOW_MS = 4 * 60 * 60 * 1000;
const DEFAULT_PORT = 4747;

const ts = () => new Date().toISOString();
const log = (msg) => console.log(`${ts()} ${msg}`);

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

const shortSession = (id) => (id ? id.slice(0, 8) : null);

export async function runDaemon(dirArg) {
  const dir = resolve(dirArg);
  const roster = loadRoster(dir);
  const executor = process.env.EPITO_EXECUTOR || "claude";
  const timeoutMs = Number(process.env.EPITO_RUN_TIMEOUT_MS) || DEFAULT_TIMEOUT_MS;
  const windowMs = Number(process.env.EPITO_WINDOW_MS) || DEFAULT_WINDOW_MS;
  const port = Number(process.env.EPITO_PORT) || DEFAULT_PORT;
  const secret = process.env.EPITO_HOOK_SECRET || "";

  // Per-agent runtime state. `running` is the mutex; `pending` is the
  // coalesced follow-up trigger (kept as the latest one, with a count);
  // `window` is the open stretch of presence; `session` is the executor
  // conversation held inside it, with the clone it lives in.
  const state = new Map();
  for (const [name, a] of roster) {
    state.set(name, { running: false, pending: null, coalesced: 0, lastFiredMinute: null, lastRun: null, child: null,
      window: null, session: null,
      nextCron: a.cron ? nextCronFire(a.cron)?.toISOString() ?? null : null });
  }

  const snapshot = () => {
    const agents = {};
    for (const [name, a] of roster) {
      const s = state.get(name);
      agents[name] = { model: a.manifest.runtime.model, repo: a.manifest.runtime.repo, cron: a.manifest.trigger.cron ?? null,
        running: s.running, pending: s.pending ? { trigger: s.pending.trigger } : null, nextCron: s.nextCron, lastRun: s.lastRun,
        window: s.window, session: s.session ? { id: s.session.id, capturedAt: s.session.capturedAt } : null };
    }
    writeState({ pid: process.pid, startedAt, dir, port, executor, updatedAt: ts(), agents });
  };
  const startedAt = ts();

  async function startRun(name, req) {
    const a = roster.get(name);
    const s = state.get(name);
    // Resume only what a message can legitimately continue, and only while
    // the window that holds the session is still open.
    const resume = req.trigger === "message" && s.window && s.session ? s.session.id : null;
    const workDir = resume ? s.session.workDir : null;
    s.running = true;
    s.lastRun = { trigger: req.trigger, startedAt: ts(), exit: null, durationMs: null, pr: null, log: null, turns: null, resumed: Boolean(resume) };
    snapshot();
    appendAudit({ agent: name, action: "run.start", trigger: req.trigger, model: a.manifest.runtime.model, ...(resume ? { resume } : {}), window: Boolean(s.window) });
    log(`${name}: run.start (${req.trigger})${resume ? ` resuming ${shortSession(resume)}` : ""}`);
    const r = await runAgent({ agent: a.manifest, trigger: req.trigger, hookBody: req.hookBody, text: req.text, instruction: req.instruction,
      resume, workDir, keepWork: Boolean(s.window), executor, timeoutMs, log, onSpawn: (c) => (s.child = c) });
    s.child = null;
    s.lastRun = { ...s.lastRun, exit: r.exit, durationMs: r.durationMs, pr: r.pr, log: r.log, turns: r.turns, endedAt: ts() };

    // Hold, lose, or release the session, in that order of precedence.
    if (r.exit === "workdir-gone") {
      s.session = null;
      appendAudit({ agent: name, action: "session.lost", reason: "the held clone is gone; the next message starts a fresh run" });
    } else if (s.window && r.sessionId && r.workDir) {
      const held = Boolean(s.session);
      s.session = { id: r.sessionId, workDir: r.workDir, capturedAt: ts() };
      if (!held) appendAudit({ agent: name, action: "session.hold", session: r.sessionId, until: s.window.expiresAt });
    } else if (!s.window && r.workDir) {
      // The window closed while this run was in flight: the clone is ours to clean.
      rmSync(r.workDir, { recursive: true, force: true });
      s.session = null;
    }

    appendAudit({ agent: name, action: "run.end", trigger: req.trigger, model: a.manifest.runtime.model, exit: r.exit, durationMs: r.durationMs,
      ...(r.turns != null ? { turns: r.turns } : {}), ...(r.sessionId ? { session: r.sessionId } : {}), ...(r.pr ? { pr: r.pr } : {}) });
    log(`${name}: run.end exit=${r.exit} ${r.durationMs}ms${r.turns != null ? ` turns=${r.turns}` : ""}${r.pr ? ` pr=${r.pr}` : ""} log=${r.log}`);

    const slack = await postToSlack({ agent: name, manifest: a.manifest, trigger: req.trigger, turns: r.turns, pr: r.pr, durationMs: r.durationMs, exit: r.exit });
    if (slack.text) {
      appendAudit({ agent: name, action: "slack.post", posted: slack.posted, ...(slack.reason ? { reason: slack.reason } : {}) });
      if (!slack.posted) log(`${name}: slack post failed (${slack.reason})`);
    }

    s.running = false;
    if (s.pending) {
      const next = s.pending; const n = s.coalesced;
      s.pending = null; s.coalesced = 0;
      log(`${name}: starting the coalesced run (${n} trigger${n > 1 ? "s" : ""} arrived during the last run)`);
      snapshot();
      return startRun(name, next);
    }
    snapshot();
  }

  // The single entry point for every trigger. Returns what happened.
  // Two messages that arrive during one run are merged rather than replaced:
  // a coalesced trigger may be dropped, but something a person said may not.
  function enqueue(name, trigger, payload = {}, extra = {}) {
    const s = state.get(name);
    const req = { trigger, ...payload };
    if (s.running) {
      if (s.pending?.trigger === "message" && trigger === "message") s.pending.text = `${s.pending.text}\n\n${req.text}`;
      else s.pending = req;
      s.coalesced++;
      appendAudit({ agent: name, action: trigger, trigger, ...extra, coalesced: true });
      log(`${name}: ${trigger} while running — coalesced (${s.coalesced} pending)`);
      snapshot();
      return "coalesced";
    }
    appendAudit({ agent: name, action: trigger, trigger, ...extra });
    startRun(name, req);
    return "started";
  }

  // --- windows -------------------------------------------------------------

  // Scope is "all" (or absent) or a comma-separated list of [agent].name
  // values. It matches on names only: the manifest spec is v0.1 and this
  // pitch's no-gos forbid inventing a tag field to group by.
  function resolveScope(scope) {
    if (scope === undefined || scope === null || scope === "" || scope === "all" || scope === "*") return { names: [...roster.keys()] };
    const wanted = (Array.isArray(scope) ? scope : String(scope).split(",")).map((x) => String(x).trim()).filter(Boolean);
    if (!wanted.length) return { error: `scope is empty — use "all", or a comma-separated list of agent names (this roster: ${[...roster.keys()].join(", ")})` };
    const unknown = wanted.filter((n) => !roster.has(n));
    if (unknown.length) return { error: `scope names no agent in this roster: ${unknown.join(", ")} — use "all", or a comma-separated list of agent names (this roster: ${[...roster.keys()].join(", ")})` };
    return { names: [...new Set(wanted)] };
  }

  function openWindow(name, { text, ttlMs }) {
    const s = state.get(name);
    const expiresAt = new Date(Date.now() + ttlMs).toISOString();
    if (s.window) {
      s.window.expiresAt = expiresAt;
      appendAudit({ agent: name, action: "window.refresh", until: expiresAt });
      log(`${name}: window already open — deadline moved to ${expiresAt}`);
      snapshot();
      return { agent: name, outcome: "refreshed", expiresAt };
    }
    s.window = { openedAt: ts(), expiresAt };
    appendAudit({ agent: name, action: "window.open", until: expiresAt, ...(text ? { agenda: text.length } : {}) });
    log(`${name}: window.open until ${expiresAt}`);
    const instruction = [windowInstruction(expiresAt), text].filter(Boolean).join("\n\n");
    const outcome = enqueue(name, "window", { instruction }, { until: expiresAt });
    return { agent: name, outcome, expiresAt };
  }

  function closeWindow(name, reason) {
    const s = state.get(name);
    if (!s.window) return { agent: name, outcome: "not open" };
    const w = s.window;
    s.window = null;
    const sess = s.session;
    // A run in flight owns the clone; startRun's post-run branch deletes it
    // when it finds the window gone.
    if (sess && !s.running) rmSync(sess.workDir, { recursive: true, force: true });
    if (!s.running) s.session = null;
    appendAudit({ agent: name, action: "window.close", reason, openedAt: w.openedAt, ...(sess ? { session: sess.id } : {}) });
    log(`${name}: window.close (${reason})${sess ? ` — session ${shortSession(sess.id)} discarded` : ""}`);
    snapshot();
    return { agent: name, outcome: "closed", reason, session: sess?.id ?? null };
  }

  function sweepWindows() {
    const now = Date.now();
    for (const [name, s] of state) {
      if (s.window && Date.parse(s.window.expiresAt) <= now) closeWindow(name, "expired");
    }
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
  appendAudit({ agent: null, action: "daemon.start", dir, executor, port });
  const timer = setInterval(tick, TICK_MS);
  const sweeper = setInterval(sweepWindows, SWEEP_MS);
  tick();

  const server = startHookServer({ port, secret, log, onRequest: ({ route, name, raw, json }) => {
    if ((route === "hook" || route === "message") && !roster.has(name)) {
      return { status: 404, body: { error: `no agent named "${name}" in this roster — it hosts: ${[...roster.keys()].join(", ")}` } };
    }
    if (route === "hook") {
      const outcome = enqueue(name, "hook", { hookBody: raw || undefined }, { bytes: raw.length });
      return { status: 202, body: { agent: name, outcome } };
    }
    if (route === "message") {
      const text = typeof json.text === "string" ? json.text.trim() : "";
      if (!text) return { status: 400, body: { error: `a message needs {"text": "..."} — an empty message gives the agent nothing to answer` } };
      const s = state.get(name);
      const held = Boolean(s.window && s.session);
      const outcome = enqueue(name, "message", { text }, { bytes: text.length, held });
      return { status: 202, body: { agent: name, outcome, held, session: held ? s.session.id : null,
        note: held ? undefined : "no session is held for this agent, so the message starts a fresh run — open a window first to be answered in context" } };
    }
    const scope = json.scope;
    const r = resolveScope(scope);
    if (r.error) return { status: 400, body: { error: r.error } };
    if (route === "window.open") {
      const ttlMs = Number(json.ttl_ms) > 0 ? Number(json.ttl_ms) : windowMs;
      const text = typeof json.text === "string" && json.text.trim() ? json.text.trim() : null;
      const windows = r.names.map((n) => openWindow(n, { text, ttlMs }));
      return { status: 202, body: { scope: scope ?? "all", windows } };
    }
    const windows = r.names.map((n) => closeWindow(n, "requested"));
    return { status: 200, body: { scope: scope ?? "all", windows } };
  } });

  log(`epito run: ${roster.size} agent${roster.size > 1 ? "s" : ""} from ${dir}; executor=${executor}; audit=${AUDIT_PATH}; state=${STATE_PATH}`);
  for (const [name, a] of roster) log(`  ${name}: repo=${a.manifest.runtime.repo} model=${a.manifest.runtime.model} cron=${a.manifest.trigger.cron ?? "-"} next=${state.get(name).nextCron ?? "-"}`);
  log(`windows default to ${Math.round(windowMs / 60000)} minutes (EPITO_WINDOW_MS)`);
  if (!secret) log("EPITO_HOOK_SECRET is not set: the ingress answers 503 until it is");
  snapshot();

  const shutdown = (sig) => {
    log(`${sig}: shutting down`);
    clearInterval(timer);
    clearInterval(sweeper);
    server.close();
    for (const [name, s] of state) if (s.child) { log(`${name}: killing in-flight run`); try { process.kill(-s.child.pid, "SIGTERM"); } catch {} }
    // Held clones do not survive the daemon: a session id cannot be resumed
    // by the next process anyway, and a temp dir left behind is litter.
    for (const [name, s] of state) if (s.session) { appendAudit({ agent: name, action: "window.close", reason: "daemon.stop", session: s.session.id }); rmSync(s.session.workDir, { recursive: true, force: true }); }
    appendAudit({ agent: null, action: "daemon.stop", signal: sig });
    setTimeout(() => process.exit(0), 300);
  };
  process.on("SIGINT", () => shutdown("SIGINT"));
  process.on("SIGTERM", () => shutdown("SIGTERM"));
  await new Promise(() => {}); // resident: only a signal ends this
}

// `epito ps`: the roster as the daemon last wrote it.
export function ps() {
  const st = readState();
  if (!st) { console.error(`epito: no ${STATE_PATH} here — start \`epito run <dir>\` in this directory first`); process.exit(1); }
  const alive = (() => { try { process.kill(st.pid, 0); return true; } catch { return false; } })();
  console.log(`epitod pid ${st.pid} (${alive ? "alive" : "not running"}) dir=${st.dir} port=${st.port} executor=${st.executor} updated=${st.updatedAt}`);
  const left = (iso) => {
    const ms = Date.parse(iso) - Date.now();
    if (!(ms > 0)) return "closing";
    const m = Math.round(ms / 60000);
    return m >= 60 ? `${Math.floor(m / 60)}h${String(m % 60).padStart(2, "0")}m left` : `${m}m left`;
  };
  const rows = [["AGENT", "MODEL", "STATUS", "WINDOW", "SESSION", "LAST RUN", "EXIT", "MS", "NEXT CRON", "PR"]];
  for (const [name, a] of Object.entries(st.agents)) {
    const status = a.running ? (a.pending ? "running +1 queued" : "running") : "idle";
    rows.push([name, a.model, status, a.window ? left(a.window.expiresAt) : "-", a.session ? shortSession(a.session.id) : "-",
      a.lastRun ? `${a.lastRun.startedAt.slice(0, 19)}Z ${a.lastRun.trigger}` : "-",
      a.lastRun?.exit === null || a.lastRun?.exit === undefined ? "-" : String(a.lastRun.exit),
      a.lastRun?.durationMs != null ? String(a.lastRun.durationMs) : "-", a.nextCron ? a.nextCron.slice(0, 16) + "Z" : "-", a.lastRun?.pr ?? "-"]);
  }
  const w = rows[0].map((_, i) => Math.max(...rows.map((r) => r[i].length)));
  for (const r of rows) console.log(r.map((c, i) => c.padEnd(w[i])).join("  ").trimEnd());
}

// --- the client side of the ingress ---------------------------------------
// `epito message` / `epito window` are thin: they POST to the daemon this
// shell can see (EPITO_PORT, EPITO_HOOK_SECRET), so an operator on the host
// never has to hand-write a curl with a secret in it.
async function callDaemon(path, body) {
  const secret = process.env.EPITO_HOOK_SECRET || "";
  if (!secret) { console.error("epito: EPITO_HOOK_SECRET is not set in this shell — the daemon's ingress needs it, and it is the same value epitod runs with"); process.exit(1); }
  const port = Number(process.env.EPITO_PORT) || DEFAULT_PORT;
  const host = process.env.EPITO_HOST || `http://127.0.0.1:${port}`;
  let res;
  try {
    res = await fetch(`${host}${path}`, { method: "POST", headers: { "content-type": "application/json", "x-epito-secret": secret }, body: JSON.stringify(body) });
  } catch (e) { console.error(`epito: no daemon answering at ${host} (${e.cause?.code ?? e.message}) — is \`epito run\` up, and is EPITO_PORT right?`); process.exit(1); }
  const text = await res.text();
  let out; try { out = JSON.parse(text); } catch { out = { raw: text }; }
  if (!res.ok) { console.error(`epito: ${out.error ?? text.trim()}`); process.exit(1); }
  return out;
}

export async function message(name, text) {
  if (!name || !text) { console.error(`epito: message needs an agent and words — \`epito message <name> "..."\``); process.exit(1); }
  const out = await callDaemon(`/message/${name}`, { text });
  console.log(out.held ? `${out.agent}: ${out.outcome} in held session ${shortSession(out.session)}` : `${out.agent}: ${out.outcome} as a fresh run (no session held)`);
}

export async function windowCmd(action, scope, text) {
  if (action !== "open" && action !== "close") { console.error(`epito: window takes open or close — \`epito window open [scope]\``); process.exit(1); }
  const out = await callDaemon(`/window/${action}`, { ...(scope ? { scope } : {}), ...(text ? { text } : {}) });
  for (const w of out.windows) console.log(`${w.agent}: ${w.outcome}${w.expiresAt ? ` until ${w.expiresAt}` : ""}${w.session ? ` (session ${shortSession(w.session)} discarded)` : ""}`);
}
