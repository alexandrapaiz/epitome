// What this box's own run logs say happened, read back by the build that is
// running now.
//
// This module exists because of the shape of the defect it watches for, and
// that shape is worth stating plainly: on 2026-10-18 a model provider refused
// 65 of this host's 253 runs, 37 of them before a first turn, and the reader
// written that day to recognise those refusals (lib/refusal.js) matched none
// of them, because every pattern in it came from the provider's documentation
// and this box prints a different sentence. The suite was green the whole
// time. It had to be: a reader proved only against the sentences somebody
// imagined cannot fail on the sentence nobody imagined.
//
// The gap was found by a person typing a node one-liner at a log directory.
// That is the part this module fixes. The question "can this build read the
// refusals this box is actually recording?" is answerable offline, in a
// second, from files the runtime already writes — so it becomes a row of
// `epito doctor` instead of a thing somebody has to think to ask.
//
// Three rules hold it honest, and they are the same three the reader has.
//
//   It asks only about runs that produced NOTHING: no pull request, no
//   second turn, a non-zero ending. That is the exact guard lib/runner.js
//   puts in front of readRefusal, and copying it is deliberate — a survey
//   with a wider definition than the code it reports on would quote numbers
//   nothing downstream acts on. An agent that did its work and wrote the
//   words "usage limit" into its transcript is not an unread refusal, and
//   this file must never say it is.
//
//   It reads the END of each log, because that is where a run's ending is,
//   and a megabyte of transcript in front of it belongs to the agent.
//
//   It never refuses a run, and `epito doctor` prints it as a note. Nothing
//   here is about whether the next run will start; it is about whether this
//   build could tell you why the last one did not.
import { closeSync, fstatSync, openSync, readSync, readdirSync, statSync } from "node:fs";
import { join } from "node:path";
import { EPITO_DIR } from "./audit.js";
import { readRefusal } from "./refusal.js";

// The default window. A day, because that is the span an operator standing in
// front of a box asks about ("what happened overnight"), and because the logs
// are named by their run's start so a day costs one directory listing per seat.
export const ENDINGS_WINDOW_HOURS = 24;
// Enough of the tail to hold the executor's whole result envelope and the
// footer under it. The same 16 KB the reader itself trims to, for the same
// reason: it is the end that says what happened.
const TAIL_BYTES = 16_384;

export const runLogsDir = (epitoDir = EPITO_DIR) => join(epitoDir, "logs");

// `# exit=1 pr=- session=<id> turns=82 detail="…"` — the last line the runner
// writes, and the only structured thing in a run log. A log with no footer is
// a run that has not ended; it is counted nowhere, because a run still going
// is not an ending this build failed to read.
const FOOTER = /^# exit=(\S+) pr=(\S+) session=(\S+) turns=(\S+)(?: detail="([\s\S]*)")?$/m;

export function footerOf(text) {
  const m = FOOTER.exec(text);
  if (!m) return null;
  const turns = m[4] === "-" ? null : Number(m[4]);
  return {
    exit: m[1],
    pr: m[2] === "-" ? null : m[2],
    session: m[3] === "-" ? null : m[3],
    turns: Number.isFinite(turns) ? turns : null,
    detail: m[5] ?? null,
  };
}

// The runner's own guard, in one place so the two cannot drift: did this run
// produce nothing at all? `refused` is a non-zero ending too — it is what the
// runner writes once it HAS read a refusal — and it belongs in the survey
// because the survey's subject is this build's reading, not the build that
// happened to write the file.
export const endedWithNothing = (f) =>
  Boolean(f) && f.exit !== "0" && !f.pr && (f.turns === null || f.turns <= 1);

// An ending the BOX produced rather than the provider. The runner writes a
// stage word in place of an exit code for the failures it recognises itself,
// and a child killed by a signal ends 128+N — on this host, four runs ended
// 143 at the minute the daemon restarted. Those are endings with no sentence
// in them by construction, and counting them as "a refusal this build cannot
// read" would send an operator to add SIGTERM to a fixture of provider
// sentences. They get their own count and their own clause, because a row
// that cries wolf four times a restart is a row people stop reading.
export const STOPPED_BY_THE_BOX = {
  130: "interrupted", 137: "killed", 143: "asked to stop",
  timeout: "over its time limit", spawn: "never started", cancelled: "cancelled", "workdir-gone": "left with no working directory",
};

export function stoppedByTheBox(exit) {
  if (exit === null || exit === undefined) return null;
  const n = Number(exit);
  const key = Number.isFinite(n) ? n : String(exit);
  return STOPPED_BY_THE_BOX[key] ?? null;
}

// The run's start, from the name the runner gave the file
// (`2026-10-18T02-19-52-615Z-message.log`), falling back to the file's own
// mtime for a name this runtime did not write.
export function startedAt(name, fallbackMs = null) {
  const m = /^(\d{4}-\d{2}-\d{2})T(\d{2})-(\d{2})-(\d{2})-(\d{3})Z/.exec(name);
  if (!m) return fallbackMs;
  const ms = Date.parse(`${m[1]}T${m[2]}:${m[3]}:${m[4]}.${m[5]}Z`);
  return Number.isFinite(ms) ? ms : fallbackMs;
}

function tailOf(path, bytes = TAIL_BYTES) {
  let fd = null;
  try {
    fd = openSync(path, "r");
    const { size, mtimeMs } = fstatSync(fd);
    const want = Math.min(size, bytes);
    const buf = Buffer.allocUnsafe(want);
    readSync(fd, buf, 0, want, Math.max(0, size - want));
    return { text: buf.toString("utf8"), mtimeMs };
  } catch {
    // A log being rotated, a permission this process does not have: an
    // unreadable file is not evidence of anything and must not become a
    // number. It is skipped and counted as skipped.
    return null;
  } finally {
    if (fd !== null) try { closeSync(fd); } catch { /* already gone */ }
  }
}

// The survey. `dir` is `.epito/logs`, one directory per seat under it.
// Returns the counts and — the part that matters — the endings this build
// CANNOT name, newest first, with the sentence each one ended on, because
// that sentence is what somebody has to add to the fixture.
export function surveyEndings({
  dir = runLogsDir(), now = Date.now(), hours = ENDINGS_WINDOW_HOURS,
  tailBytes = TAIL_BYTES, keep = 3,
} = {}) {
  const since = now - hours * 3_600_000;
  const empty = { looked: false, dir, hours, runs: 0, ended: 0, named: 0, withReset: 0, kinds: {}, stopped: [], unnamed: [], skipped: 0 };
  let seatDirs;
  try {
    seatDirs = readdirSync(dir, { withFileTypes: true }).filter((e) => e.isDirectory()).map((e) => e.name);
  } catch {
    // No log directory at all: a box that has run nothing yet. `looked:
    // false` is how the caller knows to print no row rather than a zero.
    return empty;
  }
  const survey = { ...empty, looked: true, kinds: {}, stopped: [], unnamed: [] };
  for (const seat of seatDirs) {
    let files;
    try { files = readdirSync(join(dir, seat)); } catch { continue; }
    for (const name of files) {
      if (!name.endsWith(".log")) continue;
      const path = join(dir, seat, name);
      const named = startedAt(name);
      // The cheap filter first: a filename out of the window costs no read.
      // Only a name this runtime did not write is stat'ed.
      let at = named;
      if (at === null) {
        try { at = statSync(path).mtimeMs; } catch { survey.skipped++; continue; }
      }
      if (at < since || at > now + 60_000) continue;
      const tail = tailOf(path, tailBytes);
      if (!tail) { survey.skipped++; continue; }
      const footer = footerOf(tail.text);
      if (!footer) continue;            // still running; not an ending
      survey.runs++;
      if (!endedWithNothing(footer)) continue;
      survey.ended++;
      const refusal = readRefusal([footer.detail, tail.text].filter(Boolean).join("\n"), { now });
      if (refusal) {
        survey.named++;
        if (refusal.resetAt) survey.withReset++;
        survey.kinds[refusal.kind] = (survey.kinds[refusal.kind] ?? 0) + 1;
      } else {
        // Asked in this order deliberately: a provider sentence in a log the
        // box later killed is still a refusal, and the box's own verdict is
        // only the answer when there is no sentence to read.
        const stopped = stoppedByTheBox(footer.exit);
        if (stopped) survey.stopped.push({ seat, file: name, at, exit: footer.exit, was: stopped });
        else survey.unnamed.push({ seat, file: name, at, exit: footer.exit, turns: footer.turns, says: endingLine(footer, tail.text) });
      }
    }
  }
  for (const list of ["unnamed", "stopped"]) survey[list].sort((a, b) => b.at - a.at);
  survey.stoppedCount = survey.stopped.length;
  survey.stopped = survey.stopped.slice(0, keep);
  survey.unnamedCount = survey.unnamed.length;
  survey.unnamed = survey.unnamed.slice(0, keep);
  return survey;
}

// What an unnamed ending ended on, for a person to read and judge. The
// runner's own `detail` if it wrote one, otherwise the last line of real
// output before the footer. One line, trimmed: this is a hint pointing at a
// log file, never a substitute for opening it.
function endingLine(footer, text) {
  if (footer.detail) return oneLine(footer.detail);
  const lines = text.split("\n").map((l) => l.trim()).filter((l) => l && !l.startsWith("#") && l !== "---");
  return lines.length ? oneLine(lines[lines.length - 1]) : "";
}

const oneLine = (s) => String(s).replace(/\s+/g, " ").trim().slice(0, 160);

// The row `epito doctor` prints. A note at worst, never a refusal — and when
// there is something to fix, the sentence says the rule in the product's own
// words and names the file that fixes it, which is the bar `epito validate`
// set for every message this product prints.
export function endingsSays(survey) {
  const { runs, ended, named, withReset, unnamed } = survey;
  const stoppedCount = survey.stoppedCount ?? 0;
  const missed = ended - named - stoppedCount;
  if (!survey.looked || runs === 0) {
    return { level: "ok", text: `no run on this box has ended in the last ${survey.hours} hours, so there is nothing for this build's refusal reader to be measured against` };
  }
  const window = `${runs} ${runs === 1 ? "run" : "runs"} ended here in the last ${survey.hours} hours`;
  if (ended === 0) {
    return { level: "ok", text: `${window} and every one of them did some work, so no refusal has been recorded for this build to read` };
  }
  const kinds = Object.entries(survey.kinds).map(([k, c]) => `${c} ${k}`).join(", ");
  // What the box did to its own runs, said once and plainly. It is not a
  // gap in the reader and it is not nothing either: a run this box killed
  // lost its work the same way a refusal does, which is a thing an operator
  // should see counted rather than folded into a silence.
  const boxClause = stoppedCount
    ? `, ${stoppedCount} this box ended itself (${[...new Set(survey.stopped.map((x) => x.was))].join(", ")})`
    : "";
  if (missed <= 0) {
    return {
      level: "ok",
      text: named === 0
        ? `${window}, ${ended} of them producing nothing and every one of those ended by this box itself (${[...new Set(survey.stopped.map((x) => x.was))].join(", ")}), so no resource refusal has been recorded for this build to read`
        : `${window}, ${ended} of them producing nothing, and this build names ${named === ended ? (ended === 1 ? "it" : `all ${ended}`) : named} as a refusal (${kinds}${withReset ? `; ${withReset} with the reset time the resource itself named` : ", none naming a reset time"})${boxClause}`,
    };
  }
  const first = unnamed[0];
  return {
    level: "note",
    // Named, then fixed, in the message: the rule is that an ending this
    // build cannot read is a refusal nothing will hold the work back for,
    // and the fix is a row in the fixture, which is one line of data and no
    // code at all. The count is the whole gap and not the sample — a row
    // that said "3 unread" when thirty were would be the same comfortable
    // lie this module exists to end.
    text: `${window}, ${ended} of them producing nothing, and this build can name only ${named}${boxClause} — ${missed === 1 ? "1 ending is" : `${missed} endings are`} unread, newest ${first.seat} at ${new Date(first.at).toISOString().replace("T", " ").slice(0, 16)}Z ending ${first.says ? `"${first.says}"` : "with no output of its own"}. If a resource refused that run, its event is being thrown away and its work lost: copy the sentence into cli/test/fixtures/refusals.json with the kind and reset time it means, and the reader and its proof both follow from the row`,
  };
}
