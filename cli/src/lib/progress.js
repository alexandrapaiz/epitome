// What a run has DONE, read off the clone it was working in rather than out of
// the child's mouth.
//
// WHY THIS EXISTS. The claude adapter spawns the executor `--output-format
// json`, which prints one object at exit and nothing before it. That object is
// the only account a run ever gives of itself, so it exists for every ending a
// run CHOOSES and for no ending chosen FOR it. A run killed at the bound
// therefore leaves a log with a header, two rules, and a footer the killer
// wrote — 576 bytes, of which not one is the run's:
//
//     # epito run pm 2026-11-02T02-05-03-039Z-message
//     ...
//     ---
//
//     ---
//     # exit=timeout pr=- session=- turns=-
//
// (.epito/logs/pm/2026-11-02T02-05-03-039Z-message.log on this company's
// resident host, a run killed after 60.8 minutes on 2026-11-02. Nineteen of
// that day's runs look exactly like it, and five of them had posted work to the
// board inside their hour.)
//
// The run's words are unreachable without changing what the executor is asked
// to print. Its WORK is not: the clone is still on disk at the moment of the
// kill, and the commits in it are timestamped. So this module answers the two
// questions the footer could not, from a surface that has no opinion about
// output formats:
//
//   what did it finish?        the commits it made, and on which branch
//   was it still working?      how long before the kill the last one landed
//
// The second is the one that makes the bound answerable. A population of
// finished runs cannot say where a kill bound belongs, because every run that
// would have answered is in the killed set. "Committing ninety seconds before
// it died" and "nothing committed, nothing printed, for fifty-four minutes"
// are two different runs wearing the same `exit=timeout`, and only the first
// is evidence that the bound is too tight.
import { spawn } from "node:child_process";

// How often a run that is saying nothing is asked what it has done. Five
// minutes: long enough that a 60-minute run adds twelve lines to its log,
// short enough that the last reading before a kill is never stale by more than
// one interval. Overridable so a smoke test can watch this happen in seconds.
export const PROGRESS_EVERY_MS = 5 * 60 * 1000;

export function progressEveryMs(env = process.env) {
  const asked = Number(env.EPITO_PROGRESS_EVERY_MS);
  return Number.isFinite(asked) && asked > 0 ? asked : PROGRESS_EVERY_MS;
}

// One `git`, in the clone, with a short fuse and a ceiling. A progress reading
// is a comment in a log file, so it may never be the thing that holds a run
// open or the thing that costs the daemon its memory:
//
//   two seconds — a git that does not answer inside that is reported as
//   unread. The run is working; nothing about it waits on this.
//   one megabyte — `git status --porcelain` in a clone where the agent has
//   installed dependencies the repository does not ignore is tens of
//   thousands of lines, and this runs every five minutes for every open
//   window on the box. Everything read here is counted or truncated to a
//   line, so a cut costs an approximate count and never a wrong one about
//   whether there was work.
const MAX_GIT_OUT = 1024 * 1024;

function git(workDir, args, timeoutMs = 2_000) {
  return new Promise((res) => {
    let p;
    try {
      p = spawn("git", ["-C", workDir, ...args], { stdio: ["ignore", "pipe", "pipe"] });
    } catch (e) { return res({ code: -1, out: e.message }); }
    let out = "", err = "";
    const timer = setTimeout(() => { try { p.kill("SIGKILL"); } catch {} }, timeoutMs);
    p.stdout.on("data", (d) => {
      if (out.length >= MAX_GIT_OUT) return;
      out += d;
    });
    p.stderr.on("data", (d) => { if (err.length < 4096) err += d; });
    p.on("error", (e) => { clearTimeout(timer); res({ code: -1, out: e.message }); });
    p.on("close", (code) => { clearTimeout(timer); res({ code, out: code === 0 ? out : (err || out) }); });
  });
}

// Where the clone stood before the child was spawned. It is taken as a
// REVISION and not as a branch name or a clock, because a run that branches,
// commits, switches back and branches again is still fully described by "what
// is on a local branch here and was not reachable from this revision", while a
// `--since` would also count whatever the clone's own history happened to
// carry from the last hour.
export async function baseRev(workDir, run = git) {
  const r = await run(workDir, ["rev-parse", "HEAD"]);
  const rev = r.code === 0 ? r.out.trim() : "";
  return /^[0-9a-f]{7,40}$/.test(rev) ? rev : null;
}

// The run's work, now. Never throws: a clone that has been deleted, a git that
// is not installed and a directory that was never a repository all come back
// as `read: false` with the reason, because a reading that failed must not be
// reported as a run that did nothing. Those are opposite facts.
export async function readProgress(workDir, base, run = git) {
  if (!workDir) return { read: false, why: "this run has no work directory" };
  if (!base) return { read: false, why: "the clone's revision was not read when the run started, so there is nothing to compare against" };
  // `--branches HEAD`, never `--all`. The clone is full on purpose, so
  // `--all` reaches every remote-tracking ref it came with — 416 of them on
  // this product's own repository — and not one of those commits is this
  // run's. Measured before this line was written that way: against a clone of
  // this repository, `--all --not HEAD` reported two hundred commits for a run
  // that had made none. Local heads are where a run's own work can be, and
  // HEAD is named beside them so a detached checkout still answers.
  const log = await run(workDir, ["log", "-n", "200", "--format=%cI%x1f%s", "--branches", "HEAD", "--not", base]);
  if (log.code !== 0) {
    return { read: false, why: `git could not be asked what this run committed (${log.out.trim().split("\n")[0] || `exit ${log.code}`})` };
  }
  const commits = log.out.split("\n").filter(Boolean).map((l) => {
    const [at, ...rest] = l.split("\x1f");
    return { at, subject: rest.join("\x1f") };
  });
  const [head, status] = await Promise.all([
    run(workDir, ["rev-parse", "--abbrev-ref", "HEAD"]),
    run(workDir, ["status", "--porcelain"]),
  ]);
  return {
    read: true,
    commits,
    branch: head.code === 0 ? head.out.trim() : null,
    dirty: status.code === 0 ? status.out.split("\n").filter(Boolean).length : null,
  };
}

const mins = (ms) => `${(ms / 60_000).toFixed(1)}m`;

// How long ago the newest commit landed, measured against a clock the caller
// supplies so the sentence is the same on a replay as it was live.
export function sinceLastCommit(p, now) {
  if (!p?.read || !p.commits?.length) return null;
  const at = Date.parse(p.commits[0].at);
  return Number.isFinite(at) ? Math.max(0, now - at) : null;
}

// What this run has done, in one line, for the log of a run that is still
// going. Written while the child is silent, which — with an executor that
// speaks only at exit — is the whole run.
export function progressSays(p, { elapsedMs, bytes, now }) {
  const head = `${mins(elapsedMs)} in, still running:`;
  if (!p?.read) return `# ${head} ${p?.why ?? "nothing could be read about what it has done"}; ${bytes} bytes of the child's own output so far`;
  const ago = sinceLastCommit(p, now);
  const work = p.commits.length === 0
    ? `nothing committed yet${p.branch ? ` on ${p.branch}` : ""}`
    : `${p.commits.length} commit${p.commits.length > 1 ? "s" : ""}${p.branch ? ` on ${p.branch}` : ""}, the last ${ago === null ? "at an unreadable time" : `${mins(ago)} ago`} ("${p.commits[0].subject}")`;
  const dirt = p.dirty === null ? "" : `, ${p.dirty} path${p.dirty === 1 ? "" : "s"} uncommitted`;
  return `# ${head} ${work}${dirt}, and ${bytes} bytes of the child's own output so far`;
}

// The bound that armed the kill, named where it is declared, so the log of a
// killed run points at the file somebody has to change. No line number: this
// sentence is read months later and a line number rots quietly.
export function boundSays(boundMs, elapsedMs) {
  return `# the ${mins(boundMs)} run bound killed this run after ${mins(elapsedMs)} — it is DEFAULT_RUN_TIMEOUT_MS in cli/src/temporal/bounds.js, and $EPITO_RUN_TIMEOUT_MS on a box that sets one`;
}

// The account of a killing, written by the killer, because nobody else is left
// to write one: what the run had finished, and why none of its own words are
// in this file. The sentence naming WHO stopped it belongs to the caller —
// the bound and a signal from outside are two different endings and the
// runner is the only thing that knows which it just performed.
export function stoppedSays(p, { bytes, now, adapter, format = null }) {
  const lines = [];
  if (!p?.read) {
    lines.push(`# what it had done when it died could not be read: ${p?.why ?? "no reason given"}`);
  } else {
    const ago = sinceLastCommit(p, now);
    lines.push(p.commits.length === 0
      ? `# what it had done when it died: nothing committed${p.branch ? ` on ${p.branch}` : ""}${p.dirty ? `, ${p.dirty} path${p.dirty === 1 ? "" : "s"} left uncommitted` : ""}`
      : `# what it had done when it died: ${p.commits.length} commit${p.commits.length > 1 ? "s" : ""}${p.branch ? ` on ${p.branch}` : ""}, the last ${ago === null ? "at an unreadable time" : `${mins(ago)} before it was stopped`}${p.dirty ? `, and ${p.dirty} path${p.dirty === 1 ? "" : "s"} left uncommitted` : ""}`);
    for (const c of p.commits.slice(0, 20).reverse()) lines.push(`#   ${c.at} ${c.subject}`);
  }
  if (bytes === 0) {
    lines.push(`# the child wrote nothing to this log: the executor the ${adapter} adapter runs${format ? ` (\`${format}\`)` : ""} prints its whole account of the run at exit and nothing before it, so a run stopped before its exit leaves none of its own words here`);
  }
  return lines;
}

// The same account in one sentence, for the ledger and the board — the two
// surfaces somebody queries rather than greps. This is the field that lets the
// next reader ask of the killed set "how many were still committing when they
// died", which is the question a censored population of finished runs cannot
// answer. `says` is how the run ended, in the caller's words ("killed at the
// 60.0m run bound after 60.3m"); the rest is what it had done when that
// happened.
export function stoppedDetail(p, { says, now }) {
  if (!p?.read) return `${says}; what it had done could not be read (${p?.why ?? "no reason given"})`;
  if (p.commits.length === 0) return `${says} with nothing committed${p.dirty ? ` and ${p.dirty} path${p.dirty === 1 ? "" : "s"} uncommitted` : ""}`;
  const ago = sinceLastCommit(p, now);
  return `${says} with ${p.commits.length} commit${p.commits.length > 1 ? "s" : ""}${p.branch ? ` on ${p.branch}` : ""}, the last ${ago === null ? "at an unreadable time" : `${mins(ago)} before it was stopped`}`;
}

// How a run ended, in the vocabulary the board and the ledger read. Three
// endings reach this and they are not the same thing, so they do not get the
// same sentence: our own bound, which names the file that holds it; a signal
// from outside, which is somebody on the box; and a child that reached its own
// exit and still printed no account, which was never stopped by anyone. The
// third used to be told as a killing, which is a confident wrong answer about
// whose fault a run was.
export function stoppedBySays({ boundMs, elapsedMs, exit }) {
  if (exit === "timeout") return `killed at the ${mins(boundMs)} run bound after ${mins(elapsedMs)}`;
  if (typeof exit === "string") return `stopped by ${exit} after ${mins(elapsedMs)}, before it reached its own exit`;
  return `ended after ${mins(elapsedMs)} with exit ${exit} and no account of itself`;
}

// The machine-readable half, carried on the run's result so the ledger holds
// numbers and not only a sentence. Nothing here is secret and nothing here is
// free text: commit SUBJECTS stay in the log, which is scrubbed, and never
// cross an activity boundary into the engine's database (law 7).
export function progressFacts(p, { elapsedMs, bytes, now }) {
  const base = { elapsedMs, bytes };
  if (!p?.read) return { ...base, read: false };
  return {
    ...base, read: true,
    commits: p.commits.length,
    branch: p.branch ?? null,
    dirty: p.dirty,
    sinceLastCommitMs: sinceLastCommit(p, now),
  };
}
