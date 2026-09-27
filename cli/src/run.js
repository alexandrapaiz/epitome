// `epito run <dir>`: reconcile the roster onto the engine, then serve the
// ingress as a thin Temporal client (epitod v1,
// docs/prfaq/epitod-v1-temporal.md).
//
// What this process is NOT any more: a scheduler, a mutex, a retry loop, a
// crash-recovery story, and an executor. Those four were epitod v0's hand-built
// middle, and they are the engine's job now. What is left is the part that is
// ours:
//
//   - load every agent.toml under <dir> through the same validator `epito
//     validate` applies; a broken manifest stops the command, loudly
//   - make Temporal's schedules match that roster (create / update / delete),
//     which is idempotent, so a restart reconciles rather than duplicates
//   - serve POST /hooks/<name>, /message/<name>, /window/open, /window/close
//     and GET /healthz, turning each into a workflow start or a signal
//   - serve the board: POST /board files a run report from a seat anywhere
//     (a GitHub Actions job, a laptop), GET /board reads it back
//   - SIGHUP re-reads the roster and reconciles again, so adding a seat does
//     not need a restart
//
// The ingress refers to workflows and signals BY NAME rather than importing
// src/temporal/workflows.js. That is deliberate: workflow code belongs to the
// worker's sandbox, and an ingress that imports it would be one refactor away
// from running a workflow in the wrong process.
import { resolve } from "node:path";
import { randomUUID } from "node:crypto";
import { loadRoster } from "./lib/roster.js";
import { startHookServer } from "./lib/hooks.js";
import { windowInstruction } from "./lib/runner.js";
import { appendAudit, AUDIT_PATH } from "./lib/audit.js";
import { appendBoard, readBoard, foldBoard, renderBoard, BOARD_PATH } from "./lib/board.js";
import { connect } from "./temporal/client.js";
import { reconcile } from "./temporal/schedules.js";
import { temporalEnv, runId, windowId, DEFAULT_PORT } from "./temporal/env.js";

const ts = () => new Date().toISOString();
const log = (msg) => console.log(`${ts()} ${msg}`);

const ALREADY_STARTED = "WorkflowExecutionAlreadyStartedError";

export async function runDaemon(dirArg, { dryRun = false } = {}) {
  const dir = resolve(dirArg);
  let roster = loadRoster(dir);
  const cfg = temporalEnv();
  const port = Number(process.env.EPITO_PORT) || DEFAULT_PORT;
  const secret = process.env.EPITO_HOOK_SECRET || "";

  const { client, connection } = await connect();
  appendAudit({ agent: null, action: "reconcile.start", dir, address: cfg.address, namespace: cfg.namespace, queue: cfg.taskQueue });
  const plan = await reconcile({ client, roster, dryRun, log: (m) => log(m) });
  for (const k of ["create", "update", "delete"]) {
    for (const s of plan[k]) appendAudit({ agent: s.name, action: `schedule.${k}`, schedule: s.id, cron: s.shape?.cron ?? null });
  }
  if (dryRun) { await connection.close().catch(() => {}); return; }

  // --- starting and signalling ---------------------------------------------

  // The arguments every workflow of this seat carries. The manifest snapshot
  // travels with the run (law 3); the worker never reads <dir>.
  const seatArgs = (name, extra) => ({
    name, manifest: roster.get(name).manifest, runTimeoutMs: cfg.runTimeoutMs, ...extra,
  });

  // A seat's ingress-triggered runs all share one workflow id, so this either
  // starts the run or hands the trigger to the run already going. That is
  // v0's coalescing, expressed once, by the engine.
  async function startOrFollowUp(name, trigger, payload) {
    // One token per trigger. signalWithStart delivers the signal even when it
    // is the call that starts the workflow, so the run needs a way to know
    // that the first followUp it sees IS the trigger it was started with.
    const args = seatArgs(name, { trigger, payload, token: randomUUID() });
    // Asked before, only so the answer can say which of the two happened. The
    // engine is correct either way, so a run that ends in the gap costs a
    // wrong word in a 202 body and nothing else.
    const before = await client.workflow.getHandle(runId(name)).describe().catch(() => null);
    const wasRunning = before?.status?.name === "RUNNING";
    const handle = await client.workflow.signalWithStart("SeatRun", {
      workflowId: runId(name),
      taskQueue: cfg.taskQueue,
      workflowRunTimeout: cfg.runTimeoutMs,
      args: [args],
      signal: "followUp",
      signalArgs: [args],
    });
    if (wasRunning) log(`${name}: ${trigger} while running — coalesced into the run in flight`);
    return { outcome: wasRunning ? "coalesced" : "started", workflow: handle.workflowId };
  }

  async function openWindow(name, { text, ttlMs }) {
    const instruction = [windowInstruction(new Date(Date.now() + ttlMs).toISOString()), text].filter(Boolean).join("\n\n");
    try {
      const h = await client.workflow.start("SeatWindow", {
        workflowId: windowId(name),
        taskQueue: cfg.taskQueue,
        args: [seatArgs(name, { ttlMs, agenda: text ?? null, instruction })],
      });
      log(`${name}: window.open (${h.workflowId})`);
      return { agent: name, outcome: "opened", expiresAt: new Date(Date.now() + ttlMs).toISOString() };
    } catch (e) {
      if (e.name !== ALREADY_STARTED) throw e;
      await client.workflow.getHandle(windowId(name)).signal("refresh", ttlMs);
      log(`${name}: window already open — deadline moved`);
      return { agent: name, outcome: "refreshed", expiresAt: new Date(Date.now() + ttlMs).toISOString() };
    }
  }

  async function closeWindow(name) {
    const h = client.workflow.getHandle(windowId(name));
    const desc = await h.describe().catch(() => null);
    if (!desc || desc.status.name !== "RUNNING") return { agent: name, outcome: "not open" };
    await h.signal("close");
    log(`${name}: window.close (requested)`);
    return { agent: name, outcome: "closed", reason: "requested" };
  }

  // Is a window holding a session for this seat right now? The window workflow
  // itself answers, because it is the thing that knows.
  async function heldSession(name) {
    try {
      const h = client.workflow.getHandle(windowId(name));
      const desc = await h.describe();
      if (desc.status.name !== "RUNNING") return null;
      const st = await h.query("state");
      return st?.session ?? null;
    } catch { return null; }
  }

  // Scope is "all" (or absent) or a comma-separated list of [agent].name
  // values. It matches on names only: the manifest spec is v0.1 and inventing
  // a tag field to group by is somebody else's pitch.
  function resolveScope(scope) {
    if (scope === undefined || scope === null || scope === "" || scope === "all" || scope === "*") return { names: [...roster.keys()] };
    const wanted = (Array.isArray(scope) ? scope : String(scope).split(",")).map((x) => String(x).trim()).filter(Boolean);
    if (!wanted.length) return { error: `scope is empty — use "all", or a comma-separated list of agent names (this roster: ${[...roster.keys()].join(", ")})` };
    const unknown = wanted.filter((n) => !roster.has(n));
    if (unknown.length) return { error: `scope names no agent in this roster: ${unknown.join(", ")} — use "all", or a comma-separated list of agent names (this roster: ${[...roster.keys()].join(", ")})` };
    return { names: [...new Set(wanted)] };
  }

  // --- the ingress ---------------------------------------------------------

  const server = startHookServer({
    port, secret, log,
    onHealth: async () => {
      try { await connection.workflowService.getSystemInfo({}); return { ok: true, temporal: cfg.address, namespace: cfg.namespace }; }
      catch (e) { return { ok: false, error: `Temporal at ${cfg.address} is not answering (${e.cause?.code ?? e.message}) — triggers will be refused until it is back` }; }
    },
    onRequest: async ({ route, name, raw, json, query }) => {
      // The board is the one surface that is not about a workflow, which is
      // why it is served here and not through Temporal: a seat that runs in
      // GitHub Actions has no workflow on this engine and still has a run
      // report to file. The roster does not gate it either — the board holds
      // the reports of seats this runtime has never hosted, and that is the
      // point of there being one board.
      if (route === "board.write") {
        let event;
        try { event = appendBoard({ ...json, source: json.source ?? "ingress" }); }
        catch (e) { return { status: 400, body: { error: e.message } }; }
        log(`${event.agent}: ${event.kind} filed on the board${event.pr ? ` (${event.pr})` : ""}`);
        return { status: 202, body: { filed: event } };
      }

      if (route === "board.read") {
        const { events, unreadable } = readBoard();
        const fold = foldBoard(events, {
          agent: query.agent || null,
          kind: query.kind || null,
          limit: Number(query.limit) > 0 ? Number(query.limit) : 20,
        });
        if (query.format === "text") return { status: 200, text: renderBoard(fold, { unreadable }) };
        return { status: 200, body: { ...fold, unreadable, path: BOARD_PATH } };
      }

      if ((route === "hook" || route === "message") && !roster.has(name)) {
        return { status: 404, body: { error: `no agent named "${name}" in this roster — it hosts: ${[...roster.keys()].join(", ")}` } };
      }

      if (route === "hook") {
        appendAudit({ agent: name, action: "hook", trigger: "hook", bytes: raw.length });
        const r = await startOrFollowUp(name, "hook", { hookBody: raw || undefined });
        return { status: 202, body: { agent: name, ...r } };
      }

      if (route === "message") {
        const text = typeof json.text === "string" ? json.text.trim() : "";
        if (!text) return { status: 400, body: { error: `a message needs {"text": "..."} — an empty message gives the agent nothing to answer` } };
        const session = await heldSession(name);
        if (session !== null) {
          await client.workflow.getHandle(windowId(name)).signal("message", text);
          appendAudit({ agent: name, action: "message", trigger: "message", bytes: text.length, held: true, session });
          log(`${name}: message delivered into held session ${session.slice(0, 8)}`);
          return { status: 202, body: { agent: name, outcome: "delivered", held: true, session } };
        }
        appendAudit({ agent: name, action: "message", trigger: "message", bytes: text.length, held: false });
        const r = await startOrFollowUp(name, "message", { text });
        return { status: 202, body: { agent: name, ...r, held: false, session: null,
          note: "no session is held for this agent, so the message starts a fresh run — open a window first to be answered in context" } };
      }

      const r = resolveScope(json.scope);
      if (r.error) return { status: 400, body: { error: r.error } };

      if (route === "window.open") {
        const ttlMs = Number(json.ttl_ms) > 0 ? Number(json.ttl_ms) : cfg.windowMs;
        const text = typeof json.text === "string" && json.text.trim() ? json.text.trim() : null;
        const windows = [];
        for (const n of r.names) windows.push(await openWindow(n, { text, ttlMs }));
        return { status: 202, body: { scope: json.scope ?? "all", windows } };
      }

      const windows = [];
      for (const n of r.names) windows.push(await closeWindow(n));
      return { status: 200, body: { scope: json.scope ?? "all", windows } };
    },
  });

  log(`epito run: ${roster.size} seat${roster.size === 1 ? "" : "s"} from ${dir}; audit=${AUDIT_PATH}; board=${BOARD_PATH}`);
  for (const [name, a] of roster) log(`  ${name}: repo=${a.manifest.runtime.repo} model=${a.manifest.runtime.model} cron=${a.manifest.trigger.cron ?? "-"}`);
  log(`windows default to ${Math.round(cfg.windowMs / 60000)} minutes (EPITO_WINDOW_MS)`);
  log(`the work happens in the worker: \`epito worker\` on queue ${cfg.taskQueue} (systemd: epitod-worker.service)`);
  if (!secret) log("EPITO_HOOK_SECRET is not set: the ingress answers 503 until it is");

  // SIGHUP: a seat was added, removed, or had its cron changed. Re-read and
  // reconcile without dropping the ingress or touching work in flight.
  process.on("SIGHUP", async () => {
    log("SIGHUP: re-reading the roster and reconciling");
    try {
      roster = loadRoster(dir);
      const p = await reconcile({ client, roster, log: (m) => log(m) });
      for (const k of ["create", "update", "delete"]) {
        for (const s of p[k]) appendAudit({ agent: s.name, action: `schedule.${k}`, schedule: s.id, cron: s.shape?.cron ?? null });
      }
    } catch (e) { log(`SIGHUP: reconcile failed (${e.message}); the previous roster stays in force`); }
  });

  const shutdown = async (sig) => {
    log(`${sig}: shutting down the ingress (schedules and runs in flight are the engine's, and stay)`);
    server.close();
    appendAudit({ agent: null, action: "ingress.stop", signal: sig });
    await connection.close().catch(() => {});
    setTimeout(() => process.exit(0), 200);
  };
  process.on("SIGINT", () => shutdown("SIGINT"));
  process.on("SIGTERM", () => shutdown("SIGTERM"));
  await new Promise(() => {}); // resident: only a signal ends this
}

// --- the client side of the ingress ---------------------------------------
// `epito message` / `epito window` / `epito report` are thin: they POST to the
// ingress this shell can see (EPITO_HOST, EPITO_PORT, EPITO_HOOK_SECRET), so
// neither an operator on the host nor a CI job somewhere else ever has to
// hand-write a curl with a secret in it.
export async function callIngress(path, body) {
  const secret = process.env.EPITO_HOOK_SECRET || "";
  if (!secret) { console.error("epito: EPITO_HOOK_SECRET is not set in this shell — the ingress needs it, and it is the same value `epito run` was started with"); process.exit(1); }
  const port = Number(process.env.EPITO_PORT) || DEFAULT_PORT;
  const host = process.env.EPITO_HOST || `http://127.0.0.1:${port}`;
  let res;
  try {
    res = await fetch(`${host}${path}`, { method: "POST", headers: { "content-type": "application/json", "x-epito-secret": secret }, body: JSON.stringify(body) });
  } catch (e) { console.error(`epito: no ingress answering at ${host} (${e.cause?.code ?? e.message}) — is \`epito run\` up, and is EPITO_PORT right?`); process.exit(1); }
  const text = await res.text();
  let out; try { out = JSON.parse(text); } catch { out = { raw: text }; }
  if (!res.ok) { console.error(`epito: ${out.error ?? text.trim()}`); process.exit(1); }
  return out;
}

const shortSession = (id) => (id ? id.slice(0, 8) : null);

export async function message(name, text) {
  if (!name || !text) { console.error(`epito: message needs an agent and words — \`epito message <name> "..."\``); process.exit(1); }
  const out = await callIngress(`/message/${name}`, { text });
  console.log(out.held ? `${out.agent}: ${out.outcome} in held session ${shortSession(out.session)}` : `${out.agent}: ${out.outcome} as a fresh run (no session held)`);
}

export async function windowCmd(action, scope, text) {
  if (action !== "open" && action !== "close") { console.error(`epito: window takes open or close — \`epito window open [scope]\``); process.exit(1); }
  const out = await callIngress(`/window/${action}`, { ...(scope ? { scope } : {}), ...(text ? { text } : {}) });
  for (const w of out.windows) console.log(`${w.agent}: ${w.outcome}${w.expiresAt ? ` until ${w.expiresAt}` : ""}`);
}
