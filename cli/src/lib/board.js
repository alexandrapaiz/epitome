// The board: the company's own task manager, and the one place a run report
// lands (owner directive 2026-09-26, priority 1; docs/prfaq/task-board-v0.md).
//
// What it replaces: a Linear mirror that never once had a working API key, and
// a run report that lived in a PR body plus an optional Slack line — two
// surfaces, neither queryable, both reconstructed by hand with `gh pr list`
// and `gh run list` when anyone wanted to know what the seats had been doing.
//
// The store is .epito/board.jsonl: append-only, one JSON object per line,
// folded into the board on read. That route and the two it beat are ADR-16.
// The short version is that the two obvious candidates each fail on one thing
// this file does not:
//
//   a repo-tracked file — seats cannot push to main, so every run report
//   would be a pull request waiting on a merge, and the board would show
//   nothing that happened since the last one. (Today, as this ships: four
//   engineer PRs open and nothing merged since 2026-09-24. A repo-tracked
//   board would be four days blind.)
//
//   Postgres beside the engine — a real dependency, on a product whose whole
//   promise is that `epito run` works on a laptop for nothing (ADR-6).
//
// The event log is what both of those would have been built on anyway, so it
// is what we keep: if the board outgrows a file, the events replay into
// whatever comes next and the fold below is the only thing that changes.
//
// THE ONE SHAPE. `KINDS` is the whole schema, and `boardEvent` refuses a field
// that is not in it, by name. That refusal is the owner's "seats cannot create
// views" written as code rather than as a promise: a seat can fill this board
// in, and cannot grow it a column because its own run happened to have one.
import { appendFileSync } from "node:fs";
import { join } from "node:path";
import { EPITO_DIR, ensureDir, readJsonl, unreadableNote } from "./audit.js";
import { table, iso16, hhmm } from "./table.js";
import { NAME_RE } from "./manifest.js";

export const BOARD_PATH = join(EPITO_DIR, "board.jsonl");

export const KINDS = {
  // A run happened. This is the run report, in the product's vocabulary.
  run: ["agent", "trigger", "runId", "model", "outcome", "turns", "pr", "seconds", "detail", "source"],
  // A line a seat wants on the board that is not a run: a hill moved, a bet
  // was cut, a cycle closes Friday. The PM's way onto the board before the
  // board renders docs/cycles/ itself.
  note: ["agent", "text", "url", "source"],
};

const NUMBERS = new Set(["turns", "seconds"]);

// The outcome the runtime files for a run no resource would take. It is a
// word rather than an exit code for the same reason every other outcome is
// (src/temporal/activities.js): the board speaks the product's vocabulary.
export const REFUSED = "refused";

// -> { event } | { error }. The error is the message the writer shows: it
// names the rule broken and the fix, like `epito validate` does.
export function boardEvent(raw, { now = new Date() } = {}) {
  if (raw === null || typeof raw !== "object" || Array.isArray(raw)) {
    return { error: `a board entry is a JSON object, got ${Array.isArray(raw) ? "an array" : typeof raw}` };
  }
  const kind = raw.kind ?? "run";
  const allowed = KINDS[kind];
  if (!allowed) return { error: `"${kind}" is not something the board holds — it holds ${Object.keys(KINDS).join(" and ")} entries. Fix: send {"kind": "run"} for a run report, or {"kind": "note"} for a line about the work.` };

  const unknown = Object.keys(raw).filter((k) => k !== "kind" && k !== "ts" && !allowed.includes(k));
  if (unknown.length) {
    return { error: `the board has one shape, and a ${kind} entry has no ${unknown.length > 1 ? "fields" : "field"} ${unknown.map((u) => `"${u}"`).join(", ")} — it holds ${allowed.join(", ")}. Fix: put what you meant in "detail" (a run) or "text" (a note); changing the board's shape is the PM's call, in spec and code, not a field a run invents.` };
  }

  const agent = raw.agent;
  if (typeof agent !== "string" || !NAME_RE.test(agent)) {
    return { error: `a board entry names the agent it is about: "agent" must be [a-z0-9-], 1-40 chars, got ${agent === undefined ? "nothing" : JSON.stringify(agent)}` };
  }
  if (kind === "note" && (typeof raw.text !== "string" || !raw.text.trim())) {
    return { error: `a note needs {"text": "..."} — an empty note puts nothing on the board` };
  }

  const event = { ts: now.toISOString(), kind, agent };
  for (const k of allowed) {
    if (k === "agent" || raw[k] === undefined || raw[k] === null) continue;
    if (NUMBERS.has(k)) {
      const n = Number(raw[k]);
      if (!Number.isFinite(n)) return { error: `"${k}" is a number on the board, got ${JSON.stringify(raw[k])}` };
      event[k] = n;
      continue;
    }
    event[k] = typeof raw[k] === "string" ? raw[k] : String(raw[k]);
  }
  if (kind === "run") event.outcome ??= "ok";
  return { event };
}

// Throws the writer's own sentence on a refusal. The runtime's caller catches
// it: a board that will not take a line must never take a run down with it.
export function appendBoard(raw, { path = BOARD_PATH, now = new Date() } = {}) {
  const { event, error } = boardEvent(raw, { now });
  if (error) throw new Error(error);
  ensureDir();
  appendFileSync(path, JSON.stringify(event) + "\n");
  return event;
}

// A line this epito cannot parse is counted, never dropped silently and never
// fatal: a newer epito may have written it, and a half-written line is what a
// crash mid-append leaves behind. That rule was written here first and is now
// shared with the audit ledger, which is the same file format and the same
// argument (lib/audit.js, readJsonl).
export function readBoard({ path = BOARD_PATH } = {}) {
  const { entries, unreadable, exists } = readJsonl(path);
  return { events: entries, unreadable, exists };
}

// The fold: the board as it stands, from the events that made it.
//
// A run may be filed twice — `record` is a retried activity, so a retry after
// a successful append files the same runId again. The audit log keeps both
// (a duplicate you can see is better than a line you lost); the board is a
// thing an owner reads, so the fold keeps the first and says how many it
// collapsed.
export function foldBoard(events, { agent = null, limit = 20, kind = null } = {}) {
  const seen = new Set();
  let duplicates = 0;
  const kept = [];
  for (const e of events) {
    if (e.kind === "run" && e.runId) {
      const key = `${e.agent}\u0000${e.runId}`;
      if (seen.has(key)) { duplicates++; continue; }
      seen.add(key);
    }
    if (agent && e.agent !== agent) continue;
    if (kind && e.kind !== kind) continue;
    kept.push(e);
  }
  kept.sort((a, b) => String(a.ts).localeCompare(String(b.ts)));

  const seats = new Map();
  for (const e of kept) {
    if (!seats.has(e.agent)) seats.set(e.agent, { name: e.agent, runs: 0, failed: 0, refused: 0, notes: 0, last: null, lastPr: null });
    const s = seats.get(e.agent);
    if (e.kind === "note") { s.notes++; continue; }
    s.runs++;
    // A run a resource refused did not fail, and the two have been one number
    // here since the board existed. On 2026-10-18 that number told the owner
    // that a quarter of the day's runs had broken, when what had happened was
    // that a provider said "not now" and named the hour it would be back
    // (exo's incident 8). FAILED is now code that went wrong; REFUSED is
    // capacity, and nobody should go reading a log over it.
    if (e.outcome === REFUSED) s.refused++;
    else if (e.outcome && e.outcome !== "ok") s.failed++;
    s.last = e;
    if (e.pr) s.lastPr = e.pr;
  }
  return {
    seats: [...seats.values()].sort((a, b) => a.name.localeCompare(b.name)),
    recent: kept.slice(-limit).reverse(),
    total: kept.length,
    duplicates,
    since: kept.length ? kept[0].ts : null,
  };
}

// One screen: who has been running, and what the last things that happened
// were. The columns are `epito ps`'s columns where they mean the same thing,
// because an operator should not have to learn two tables.
export function renderBoard(fold, { unreadable = 0, path = BOARD_PATH } = {}) {
  const out = [];
  if (!fold.total) {
    return `the board is empty — no run has been filed to ${path} yet.\n` +
      `a seat on this runtime files its own report when it finishes; a seat somewhere else files one with \`epito report <name> --outcome ok --pr <url>\`.`;
  }
  out.push(`the board — ${fold.seats.length} seat${fold.seats.length === 1 ? "" : "s"}, ${fold.total} entr${fold.total === 1 ? "y" : "ies"} since ${iso16(fold.since)}`);
  out.push("");
  out.push(...table([
    ["SEAT", "RUNS", "FAILED", "REFUSED", "NOTES", "LAST", "OUTCOME", "TURNS", "LAST PR"],
    ...fold.seats.map((s) => [
      s.name, s.runs, s.failed || "-", s.refused || "-", s.notes || "-",
      iso16(s.last?.ts), s.last?.outcome ?? "-", s.last?.turns ?? "-", s.lastPr ?? "-",
    ]),
  ]));
  out.push("");
  out.push(...table([
    ["", "", "", "", ""],
    ...fold.recent.map((e) => e.kind === "note"
      ? [hhmm(e.ts), e.agent, "note", "", `${e.text}${e.url ? ` ${e.url}` : ""}`]
      : [hhmm(e.ts), e.agent, e.trigger ?? "-", e.outcome ?? "-", [
          e.turns != null ? `${e.turns} turn${e.turns === 1 ? "" : "s"}` : null,
          e.seconds != null ? `${e.seconds}s` : null,
          e.pr ?? null,
          e.outcome && e.outcome !== "ok" ? e.detail : null,
        ].filter(Boolean).join("  ")]),
  ]).slice(1));
  if (fold.duplicates) out.push(`\n${fold.duplicates} duplicate run report${fold.duplicates === 1 ? "" : "s"} collapsed (a retried record files the same runId twice)`);
  if (unreadable) out.push(`\n${unreadableNote(unreadable, path)}`);
  return out.join("\n");
}
