// `epito ps`: the roster, read from the engine.
//
// v0 printed .epito/state.json, a file the daemon rewrote on every state
// transition. That file is gone, and with it the class of bug where the file
// and the truth disagree. What ps asks Temporal:
//
//   client.schedule.list()    the registered seats and when each fires next
//   client.workflow.list()    what is running right now, and what ran last
//   handle.query("state")     what an open window is holding
//
// A seat with no schedule, no window and no recent run does not appear, which
// is correct: ps reports the engine, not the roster. Pass a roster directory
// to see the presence-only seats alongside it.
import { connect } from "./client.js";
import { listSeatSchedules } from "./schedules.js";
import { seatOfScheduleId, seatOfWorkflowId, windowId, addressHost, isLoopback, portAnswers, UI_PORTS } from "./env.js";
import { loadRoster } from "../lib/roster.js";

const RECENT = 200;

const shortSession = (id) => (id ? id.slice(0, 8) : "-");
const iso16 = (d) => (d ? new Date(d).toISOString().slice(0, 16) + "Z" : "-");

function leftUntil(iso) {
  const ms = Date.parse(iso) - Date.now();
  if (!(ms > 0)) return "closing";
  const m = Math.round(ms / 60000);
  return m >= 60 ? `${Math.floor(m / 60)}h${String(m % 60).padStart(2, "0")}m left` : `${m}m left`;
}

// Where the engine's own UI is. This line used to assert `127.0.0.1:8080` on
// every machine, which is right on the company host (provision-host.sh starts
// the engine with `--ui-port 8080`) and wrong on every laptop, because a bare
// `temporal server start-dev` -- the exact command this repository's test
// suites tell you to run -- puts the UI on 8233. A footer that sends an
// operator to a dead port while they are mid-incident is worse than no footer,
// so this says only what it can see: TEMPORAL_UI_PORT if it was set, otherwise
// whichever conventional port actually answers, otherwise nothing but the
// knob's name.
async function uiHint(cfg) {
  const host = addressHost(cfg.address);
  const link = (p) => (isLoopback(host)
    ? `the Temporal UI on 127.0.0.1:${p} (over an SSH tunnel if the engine is not this machine: ssh -L ${p}:127.0.0.1:${p} <host>)`
    : `the Temporal UI on ${host}:${p}`);
  if (cfg.uiPort) return link(cfg.uiPort);
  if (isLoopback(host)) {
    for (const p of UI_PORTS) if (await portAnswers(host, p)) return link(p);
  }
  return `the Temporal UI of the engine at ${cfg.address} — nothing is answering on ${UI_PORTS.join(" or ")} here, so set TEMPORAL_UI_PORT if it is somewhere else`;
}

export async function psCmd(dirArg) {
  const { client, connection, cfg } = await connect({ quiet: true });
  try {
    const seats = new Map();
    const seat = (name) => {
      if (!seats.has(name)) seats.set(name, { name, cron: null, next: null, schedule: "-", running: [], window: null, last: null });
      return seats.get(name);
    };

    // A roster directory is optional: it only adds the seats the engine has
    // nothing to say about yet.
    if (dirArg) {
      for (const [name, a] of loadRoster(dirArg)) {
        const s = seat(name);
        s.cron = a.manifest.trigger.cron ?? null;
        s.onDisk = true;
      }
    }

    for (const sch of await listSeatSchedules(client)) {
      const name = seatOfScheduleId(sch.id);
      const s = seat(name);
      s.cron = sch.shape?.cron ?? s.cron;
      s.paused = Boolean(sch.raw?.state?.paused);
      s.schedule = s.paused ? "paused" : "ok";
      // Temporal still reports when a paused schedule WOULD fire. Printing
      // that in a column headed NEXT tells an operator a seat is about to
      // run when it is not, so a paused seat has no next fire.
      s.next = s.paused ? null : (sch.raw?.info?.nextActionTimes?.[0] ?? null);
    }

    const recent = [];
    for await (const wf of client.workflow.list({ query: `WorkflowType = "SeatRun"`, pageSize: 100 })) {
      recent.push(wf);
      if (recent.length >= RECENT) break;
    }
    recent.sort((a, b) => Number(b.startTime) - Number(a.startTime));
    for (const wf of recent) {
      const name = seatOfWorkflowId(wf.workflowId);
      if (!name) continue;
      const s = seat(name);
      if (wf.status?.name === "RUNNING") s.running.push(wf.workflowId);
      else if (!s.last) s.last = { startTime: wf.startTime, closeTime: wf.closeTime, status: wf.status?.name ?? "?", id: wf.workflowId };
    }

    for await (const wf of client.workflow.list({ query: `WorkflowType = "SeatWindow" AND ExecutionStatus = "Running"`, pageSize: 100 })) {
      const name = seatOfWorkflowId(wf.workflowId);
      if (!name) continue;
      const s = seat(name);
      s.window = { expiresAt: null, session: null, runs: null };
      try {
        const st = await client.workflow.getHandle(windowId(name)).query("state");
        s.window = { expiresAt: st.expiresAt, session: st.session, runs: st.runs, queued: st.queued };
      } catch (e) {
        s.window.error = e.message;   // no worker polling, so nothing can answer
      }
    }

    console.log(`epitod on ${cfg.address} namespace=${cfg.namespace} queue=${cfg.taskQueue}`);
    if (seats.size === 0) {
      console.log(`no seats: nothing is scheduled, running, or holding a window in this namespace — \`epito run <roster>\` registers the schedules, \`epito worker\` does the work`);
      return;
    }

    const rows = [["SEAT", "CRON", "NEXT", "SCHEDULE", "RUNNING", "WINDOW", "SESSION", "LAST RUN", "OUTCOME"]];
    for (const s of [...seats.values()].sort((a, b) => a.name.localeCompare(b.name))) {
      rows.push([
        s.name,
        s.cron ?? "-",
        iso16(s.next),
        s.schedule,
        s.running.length ? String(s.running.length) : "-",
        s.window ? (s.window.error ? "open (no worker)" : leftUntil(s.window.expiresAt)) : "-",
        shortSession(s.window?.session),
        s.last ? iso16(s.last.startTime) : "-",
        s.last ? s.last.status.toLowerCase() : "-",
      ]);
    }
    const w = rows[0].map((_, i) => Math.max(...rows.map((r) => r[i].length)));
    for (const r of rows) console.log(r.map((c, i) => c.padEnd(w[i])).join("  ").trimEnd());
    console.log(`\nthe record: \`epito audit\` (what was granted, to whom, until when)   the runs: \`epito board\``);
    console.log(`per-run engine detail — retries, timers, the event history: ${await uiHint(cfg)}`);
  } finally {
    await connection.close().catch(() => {});
  }
}
