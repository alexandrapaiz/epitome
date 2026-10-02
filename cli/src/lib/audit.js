// The product's own record: one file, .epito/audit.jsonl in the process's
// working directory, append-only, one JSON object per line, never rewritten.
//
// epitod v0 also kept .epito/state.json, a roster snapshot the daemon rewrote
// on every state transition and `epito ps` read back. v1 retires it: Temporal
// knows what is scheduled, what is running and what a window is holding, and
// `epito ps` asks Temporal (src/temporal/ps.js). A second copy of that truth
// in a file is a second copy that can be wrong.
//
// audit.jsonl stays, and stays engine-agnostic (law 8 of the design). It is
// the record in the PRODUCT's vocabulary — seats, runs, windows, sessions —
// and it must still be readable if Temporal is ever replaced. Both epitod
// processes append to it, from one working directory: O_APPEND writes of a
// single line under the pipe-buffer size do not interleave on Linux, which is
// the whole reason a line is one line.
import { appendFileSync, readFileSync, existsSync } from "node:fs";
import { mkdirSync } from "node:fs";
import { join } from "node:path";
import { table, iso16, hhmm } from "./table.js";

export const EPITO_DIR = ".epito";
export const AUDIT_PATH = join(EPITO_DIR, "audit.jsonl");

export function ensureDir() { mkdirSync(join(EPITO_DIR, "logs"), { recursive: true }); }

export function appendAudit(entry) {
  ensureDir();
  appendFileSync(AUDIT_PATH, JSON.stringify({ ts: new Date().toISOString(), ...entry }) + "\n");
}

// --- reading it back ------------------------------------------------------
//
// The write half of this file shipped on day one; the read half is this, and
// it is three days late. Cycle 1 scope 1e reads "append-only
// .epito/audit.jsonl, one line per mint (agent, scopes, timestamp); optional
// `epito audit` read-back" — the append landed in PR #4 and the read-back was
// named "first named cut if the cycle runs long" and duly cut. Since then six
// code paths have been appending here (deploy, token, run's ingress, the
// worker, and the clone/execute activities) and the only reader has been
// `cat`.
//
// Why it is worth the last day of the cycle: a record nobody can read is a
// record nobody checks, and on THIS product that is the whole claim. "The
// agent acted as itself, with only the permissions its manifest asked for" is
// a promise until someone can go and see which permissions were granted, to
// which agent, on which repository, and when. That question is one fold over
// this file, and nothing in the CLI could ask it.
//
// What this is not: the board. The board answers "what have the seats been
// doing" and holds run reports only, folded for an owner. This answers "what
// exactly happened, including the six lines nobody reads until something is
// wrong" — every mint, every refused road, every ingress restart. The two
// agree about runs because one activity files both (temporal/activities.js,
// `record`).

// One JSONL store, parsed. A line this epito cannot read is COUNTED, never
// dropped silently and never fatal: a newer epito may have written it, and a
// half-written line is what a crash mid-append leaves behind. The board
// written this rule first; it now calls this, so there is one spelling of it.
export function readJsonl(path) {
  if (!existsSync(path)) return { entries: [], unreadable: 0, exists: false };
  let unreadable = 0;
  const entries = [];
  for (const line of readFileSync(path, "utf8").split("\n")) {
    if (!line.trim()) continue;
    try {
      const e = JSON.parse(line);
      if (e && typeof e === "object" && !Array.isArray(e)) entries.push(e); else unreadable++;
    } catch { unreadable++; }
  }
  return { entries, unreadable, exists: true };
}

export function readAudit({ path = AUDIT_PATH } = {}) {
  const { entries, unreadable, exists } = readJsonl(path);
  return { lines: entries, unreadable, exists };
}

// `--since`: a window, not a date range. An operator asking this file a
// question has just been paged or has just run something, so the two forms
// that matter are "the last N hours" and "since this morning". Anything else
// is refused by name with the forms in the sentence, because a --since epito
// silently ignored would answer a different question than the one typed.
const DURATION = /^(\d+(?:\.\d+)?)([smhdw])$/;
const UNIT_MS = { s: 1e3, m: 60e3, h: 3600e3, d: 86400e3, w: 604800e3 };

export function parseSince(raw, { now = new Date() } = {}) {
  if (typeof raw !== "string" || !raw.trim()) {
    return { error: `--since needs a value: a window like \`--since 24h\` (also s, m, h, d, w) or a UTC date like \`--since 2026-10-02\`. Fix: \`epito audit --since 24h\`.` };
  }
  const v = raw.trim();
  const d = DURATION.exec(v);
  if (d) return { at: new Date(now.getTime() - Number(d[1]) * UNIT_MS[d[2]]).toISOString() };
  // An ISO date or datetime. Date-only means midnight UTC, which is what
  // someone typing a bare date means by it; no local timezone enters here,
  // because every ts in this file is UTC and a reader that mixed the two
  // would quietly drop the first hours of the day it was asked about.
  if (/^\d{4}-\d{2}-\d{2}$/.test(v)) return { at: `${v}T00:00:00.000Z` };
  const t = Date.parse(/(Z|[+-]\d{2}:?\d{2})$/.test(v) ? v : `${v}Z`);
  if (Number.isFinite(t)) return { at: new Date(t).toISOString() };
  return { error: `--since does not understand "${v}". It takes a window (\`24h\`, \`30m\`, \`7d\`) or a UTC date (\`2026-10-02\`, \`2026-10-02T14:00\`). Fix: \`epito audit --since 24h\`.` };
}

// `--action run` matches run.start and run.end; `--action run.end` matches
// only that. The actions in this file are dotted namespaces on purpose, so
// the prefix is the useful question ("show me the mints", "show me the
// schedule churn") and the exact name is the precise one.
export const actionMatches = (lineAction, want) =>
  lineAction === want || String(lineAction).startsWith(`${want}.`);

// Every action this epito knows how to say out loud. The catalogue is here
// rather than in the renderer because it is also the list `epito audit
// --action` checks a typo against: an action name nothing ever wrote is a
// filter that would have printed nothing and said nothing about why.
export const ACTIONS = [
  "deploy", "mint", "run.start", "run.end", "route.taken", "route.refused",
  "hook", "message", "window.open", "window.close", "session.hold",
  "slack.post", "schedule.create", "schedule.update", "schedule.delete",
  "reconcile.start", "ingress.stop", "worker.start", "worker.stop",
];

const permList = (p) =>
  p && typeof p === "object" && !Array.isArray(p)
    ? Object.entries(p).map(([k, v]) => `${k}:${v}`).join(", ")
    : Array.isArray(p) ? p.join(", ") : null;

// The parts are written as `cond && "text"`, so a part that does not apply
// arrives here as false, null or undefined rather than as a missing argument.
// filter(Boolean) is the rule board.js already uses on the same shape; an
// earlier spelling of this filtered null and undefined only, and printed the
// word "false" into the ledger's own output.
const phrase = (...parts) => parts.filter(Boolean).join(", ");

// One line of the ledger as a sentence. Each description names the facts an
// operator came looking for and drops the rest; `--json` is there for anyone
// who wants the whole object, so this is allowed to choose.
const SAY = {
  deploy: (l) => phrase(
    l.created ? `created App ${l.appId}${l.slug ? ` (${l.slug})` : ""}` : `recorded App ${l.appId}`,
    permList(l.permissions) && `${permList(l.permissions)} on ${l.repo}`,
    l.installation ? `installation ${l.installation}` : `not installed anywhere yet`,
  ),
  // The line this whole command exists for: what was granted, on what, until
  // when. `permissions` is what GitHub actually issued and `scopes` is what
  // the manifest asked for — they agree when the scope map is right, and the
  // issued set is the one that answers "what could this agent do".
  mint: (l) => {
    const granted = permList(l.permissions) ?? permList(l.scopes);
    return phrase(
      granted && l.repo ? `${granted} on ${l.repo}` : granted || (l.repo && `on ${l.repo}`),
      l.installation && `installation ${l.installation}`,
      l.expiresAt && `expires ${hhmm(l.expiresAt)}`,
      l.phase && `for the ${l.phase}`,
      l.commit?.name && `as ${l.commit.name}`,
    );
  },
  "run.start": (l) => phrase(l.trigger, l.model, l.resume && `resuming ${String(l.resume).slice(0, 8)}`),
  "run.end": (l) => phrase(
    l.outcome ?? "ended",
    l.turns != null && `${l.turns} turn${l.turns === 1 ? "" : "s"}`,
    l.seconds != null ? `${l.seconds}s` : l.durationMs != null ? `${Math.round(l.durationMs / 1000)}s` : null,
    l.pr,
    l.outcome && l.outcome !== "ok" && l.detail,
  ),
  "route.taken": (l) => phrase(l.route, l.model, l.after?.length && `after ${l.after.join(", ")} refused`),
  "route.refused": (l) => phrase(l.route, l.model, `exit ${l.exit}`, l.turns != null && `${l.turns} turns`),
  hook: (l) => phrase(`${l.bytes} bytes`, l.refused && `REFUSED: ${l.refused}`),
  message: (l) => phrase(`${l.bytes} bytes`, l.held ? `into held session ${String(l.session ?? "").slice(0, 8)}` : "no window held, fresh run"),
  "schedule.create": (l) => phrase(l.schedule, l.cron && `cron ${l.cron}`),
  "reconcile.start": (l) => phrase(l.dir, l.address, l.namespace && `namespace ${l.namespace}`, l.queue && `queue ${l.queue}`),
  "worker.start": (l) => phrase(l.address, l.namespace && `namespace ${l.namespace}`, l.queue && `queue ${l.queue}`, l.executor, l.traces && `traces ${l.traces}`),
};
SAY["schedule.update"] = SAY["schedule.create"];
SAY["schedule.delete"] = SAY["schedule.create"];
SAY["worker.stop"] = (l) => phrase(l.signal);
SAY["ingress.stop"] = (l) => phrase(l.signal);

// The fields every line has, which the generic fallback must not repeat.
const SPINE = new Set(["ts", "agent", "action"]);

// An action this epito has never heard of still prints. A ledger is only as
// good as its worst line, and the worst line here is one written by a NEWER
// epito than the one reading: if the fallback hid it, upgrading the runtime
// would silently blind the auditor on exactly the events that are new. So
// unknown actions print their own fields as key=value, which is ugly on
// purpose — it reads as "this reader is older than this line".
export function describe(line) {
  const say = SAY[line.action];
  if (say) {
    const s = say(line);
    if (s) return s;
  }
  const rest = Object.entries(line)
    .filter(([k, v]) => !SPINE.has(k) && v !== null && v !== undefined && v !== "")
    .map(([k, v]) => `${k}=${typeof v === "object" ? JSON.stringify(v) : v}`);
  return rest.join(" ") || "(no detail on the line)";
}

// The fold: who holds what, and what the last things that happened were.
//
// Lines that name no seat (`agent: null` — the worker and ingress starting and
// stopping, a reconcile) are deliberately NOT given a row in the seat table
// and deliberately not dropped either: they are the machine's own lines, they
// are counted in the footer, and they still appear in the tail. A row called
// "null" in a table of seats is a seat that does not exist.
export function foldAudit(lines, { agent = null, action = null, since = null, limit = 20 } = {}) {
  const matched = [];
  for (const l of lines) {
    if (agent && l.agent !== agent) continue;
    if (action && !actionMatches(l.action, action)) continue;
    if (since && !(String(l.ts) >= since)) continue;
    matched.push(l);
  }
  matched.sort((a, b) => String(a.ts).localeCompare(String(b.ts)));

  const seats = new Map();
  let runtimeLines = 0;
  for (const l of matched) {
    if (!l.agent) { runtimeLines++; continue; }
    if (!seats.has(l.agent)) {
      seats.set(l.agent, {
        name: l.agent, mints: 0, deploys: 0, failed: 0, refused: 0,
        repo: null, permissions: null, app: null, lastMint: null, last: null,
        // A run is one runId, counted from either end of it. Counting
        // `run.start` alone looked right and read wrong: a ledger that was
        // truncated, or filtered by --since, or that holds a run the ingress
        // started before the window opened, shows a run.end whose start is
        // not here — and a seat with FAILED 1 and RUNS - is a reader the
        // operator stops trusting.
        runIds: new Set(), unidentifiedRuns: 0,
      });
    }
    const s = seats.get(l.agent);
    s.last = l.ts;
    switch (l.action) {
      case "mint":
        s.mints++; s.lastMint = l.ts;
        // The permissions column is the LAST mint's, because that is what the
        // agent holds now; an older, wider grant is history and the tail is
        // where history is read.
        s.permissions = permList(l.permissions) ?? permList(l.scopes) ?? s.permissions;
        s.repo = l.repo ?? s.repo;
        break;
      case "deploy":
        s.deploys++;
        s.app = l.appId ?? s.app;
        s.repo = l.repo ?? s.repo;
        s.permissions ??= permList(l.permissions);
        break;
      case "run.start":
        if (l.runId) s.runIds.add(l.runId); else s.unidentifiedRuns++;
        break;
      case "run.end":
        if (l.runId) s.runIds.add(l.runId); else s.unidentifiedRuns++;
        if (l.outcome && l.outcome !== "ok") s.failed++;
        break;
      case "route.refused": s.refused++; break;
      case "hook": if (l.refused) s.refused++; break;
    }
  }

  // The Set is the counter's working state, not part of the fold: `--json`
  // emits this object, and a Set serializes to {}.
  const summary = [...seats.values()]
    .map(({ runIds, unidentifiedRuns, ...s }) => ({ ...s, runs: runIds.size + unidentifiedRuns }))
    .sort((a, b) => a.name.localeCompare(b.name));

  return {
    seats: summary,
    recent: limit > 0 ? matched.slice(-limit) : matched,
    total: lines.length,
    matched: matched.length,
    runtimeLines,
    first: matched.length ? matched[0].ts : null,
    last: matched.length ? matched[matched.length - 1].ts : null,
  };
}

// One screen: what has been granted to whom, then what happened, oldest
// first. Oldest first because this is a ledger and a ledger is read forwards —
// the board shows newest first, which is right for "what are the seats up to"
// and wrong for "walk me through what happened".
export function renderAudit(fold, { unreadable = 0, path = AUDIT_PATH, filters = {} } = {}) {
  const named = Object.entries(filters).filter(([, v]) => v).map(([k, v]) => `--${k} ${v}`).join(" ");
  if (!fold.matched) {
    if (!fold.total) {
      return `the ledger is empty — nothing has been appended to ${path} yet.\n`
        + `every \`epito deploy\`, \`epito token\` and every run on this runtime writes a line here.`;
    }
    return `no line in ${path} matches ${named || "that"} — ${fold.total} line${fold.total === 1 ? "" : "s"} in the ledger, none of them this.\n`
      + `\`epito audit\` with no options shows the last 20 of everything.`;
  }

  const out = [];
  const span = fold.first === fold.last ? iso16(fold.first) : `${iso16(fold.first)} → ${hhmm(fold.last)}`;
  out.push(`the ledger — ${fold.seats.length} seat${fold.seats.length === 1 ? "" : "s"}, `
    + `${fold.matched === fold.total ? `${fold.total} line${fold.total === 1 ? "" : "s"}` : `${fold.matched} of ${fold.total} lines`}`
    + `, ${span}   (${path})`);

  if (fold.seats.length) {
    out.push("");
    out.push(...table([
      ["SEAT", "MINTS", "DEPLOYS", "RUNS", "FAILED", "REFUSED", "APP", "REPO", "PERMISSIONS NOW", "LAST MINT"],
      ...fold.seats.map((s) => [
        s.name, s.mints || "-", s.deploys || "-", s.runs || "-", s.failed || "-", s.refused || "-",
        s.app ?? "-", s.repo ?? "-", s.permissions ?? "-", iso16(s.lastMint),
      ]),
    ]));
  }

  out.push("");
  out.push(...table([
    ["", "", "", ""],
    ...fold.recent.map((l) => [hhmm(l.ts), l.agent ?? "-", l.action ?? "?", describe(l)]),
  ]).slice(1));

  const foot = [];
  if (fold.runtimeLines) {
    foot.push(`${fold.runtimeLines} line${fold.runtimeLines === 1 ? "" : "s"} name no seat: the runtime's own (the worker and the ingress starting and stopping, a reconcile)`);
  }
  if (fold.matched > fold.recent.length) {
    foot.push(`showing the last ${fold.recent.length} of ${fold.matched} matching — \`--limit 0\` for all of them`);
  }
  if (unreadable) {
    foot.push(unreadable === 1
      ? `1 line in ${path} could not be read as JSON and was skipped`
      : `${unreadable} lines in ${path} could not be read as JSON and were skipped`);
  }
  if (foot.length) out.push("", ...foot);
  return out.join("\n");
}
