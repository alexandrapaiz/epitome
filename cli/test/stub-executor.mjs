#!/usr/bin/env node
// A stand-in for `claude` in the smoke test: same CLI shape, no tokens spent.
// It answers `--output-format json` the way the real executor does — one JSON
// object on stdout with session_id, num_turns and result — and it honours
// `--resume <id>` by keeping the same session_id and appending to that
// session's transcript, so a test can prove context was held.
//
//   EPITO_STUB_DIR   where transcripts live (default $TMPDIR/epito-stub)
//   EPITO_STUB_PR    a PR url the first run of a session "opens"
//   EPITO_STUB_REFUSE_BASE_URL
//                    when the child is pointed at THIS endpoint, refuse the
//                    way a rationed provider does: one turn, is_error, exit 1,
//                    nothing done. That is L-E7's fingerprint, and it is the
//                    only failure the router is allowed to take a detour
//                    around.
//   EPITO_STUB_REFUSE_SAYS
//                    refuse before a first turn and say so in the provider's
//                    own words — "Claude AI usage limit reached|<epoch>" and
//                    the rest of the shapes src/lib/refusal.js reads. This is
//                    the 2026-10-18 failure: zero turns, nothing done, a
//                    sentence naming when capacity comes back.
//   EPITO_STUB_ECHO_ROUTE
//                    print the route's endpoint and model in the result, so a
//                    test can read which road the run actually took.
//   EPITO_STUB_PR_EARLY
//                    print the pull request's address on its own line FIRST,
//                    the way an agent that opens its draft before anything
//                    slow does, and keep it out of the result object — so the
//                    only copy of it is at the start of the output.
//   EPITO_STUB_NOISE_KB
//                    then print this many KB of filler, which is how an
//                    address printed in the first minute leaves the run's
//                    64 KB window.
//   EPITO_STUB_RESULT_KB
//                    pad the result string to this many KB. The result object
//                    is one line and `num_turns` sits before `result` inside
//                    it, so a padded result is how a run loses its turn count
//                    to the same window.
//   EPITO_STUB_SCRATCH_FILE
//                    write a file of THIS NAME into the temp directory this
//                    child was given, wait, read it back, and report what came
//                    back — which is incident 5 reproduced exactly: two runs
//                    on one host, each writing its pull request body to a path
//                    it picked by name. What it writes identifies the run (its
//                    cwd is its own clone), so a readback that is not what it
//                    wrote is another run's text. `prior` says whether the file
//                    was already there, which is how a test tells a window
//                    that kept its scratch across a resumed run from a fresh
//                    one. `EPITO_STUB_SCRATCH_WAIT_MS` widens the window
//                    between the write and the read.
//   EPITO_STUB_ECHO_TOKEN
//                    print the GH_TOKEN this child was handed, in its result.
//                    The identity slice's whole claim is about which
//                    credential reaches this process, so a test has to be able
//                    to read it — and printing a credential into stdout is
//                    also precisely what a real `gh` error path does, which is
//                    what the run log's scrubbing is there to survive.
import { mkdirSync, writeFileSync, readFileSync, existsSync } from "node:fs";
import { join, basename } from "node:path";
import { tmpdir } from "node:os";
import { randomUUID } from "node:crypto";

const argv = process.argv.slice(2);
const flag = (name) => { const i = argv.indexOf(name); return i >= 0 ? argv[i + 1] : null; };

const dir = process.env.EPITO_STUB_DIR || join(tmpdir(), "epito-stub");
mkdirSync(dir, { recursive: true });

const resume = flag("--resume");
const sessionId = resume || randomUUID();
const prompt = flag("-p") ?? "";
const transcript = join(dir, `${sessionId}.jsonl`);

// A provider that is out of concurrency answers before the agent does
// anything at all. The stub reproduces exactly that shape: the run never
// started, so the router may try the next road.
// The refusal that names its own reset time, on whichever road it is asked
// for: a usage window is a fact about the account, not about the endpoint.
const says = process.env.EPITO_STUB_REFUSE_SAYS;
if (says) {
  process.stdout.write(JSON.stringify({
    type: "result", subtype: "error_during_execution", is_error: true,
    duration_ms: 7, num_turns: 0, result: says,
    session_id: sessionId, total_cost_usd: 0,
  }) + "\n");
  process.exit(1);
}

const refuse = process.env.EPITO_STUB_REFUSE_BASE_URL;
if (refuse && process.env.ANTHROPIC_BASE_URL === refuse) {
  process.stdout.write(JSON.stringify({
    type: "result", subtype: "error_during_execution", is_error: true,
    duration_ms: 9, num_turns: 1,
    // A provider that refuses is exactly the child that prints what it tried,
    // which is why the run log scrubs the route's key as well as the token.
    result: `request reached max organization concurrency: 1${process.env.EPITO_STUB_ECHO_ROUTE ? ` [key=${process.env.ANTHROPIC_AUTH_TOKEN ?? "(none)"}]` : ""}`,
    session_id: sessionId, total_cost_usd: 0,
  }) + "\n");
  process.exit(1);
}

const prior = existsSync(transcript) ? readFileSync(transcript, "utf8").trim().split("\n").filter(Boolean) : [];
writeFileSync(transcript, [...prior, JSON.stringify({ ts: new Date().toISOString(), cwd: process.cwd(), resumed: Boolean(resume), prompt })].join("\n") + "\n");

// First turn of a session opens a PR; a resumed turn refers back to it, which
// is exactly the continuity the window is for.
const pr = process.env.EPITO_STUB_PR || "https://github.com/alexandrapaiz/epitome/pull/999";
// The house rule, reproduced: the draft's address is printed before anything
// slow happens, and then the run keeps talking.
if (process.env.EPITO_STUB_PR_EARLY) {
  process.stdout.write(`Opened a draft pull request: ${pr}\n`);
  const kb = Number.parseInt(process.env.EPITO_STUB_NOISE_KB ?? "0", 10);
  const line = `${"x".repeat(255)}\n`;
  for (let i = 0; i < (Number.isFinite(kb) ? kb : 0) * 4; i++) process.stdout.write(line);
}
const base = process.env.EPITO_STUB_PR_EARLY
  ? `My draft is open; I printed its address in my first line of output and have been printing since`
  : prior.length === 0
    ? `Opened a draft PR: ${pr}`
    : `Continuing session ${sessionId} (turn ${prior.length + 1}); my PR is still ${pr}`;
let result = process.env.EPITO_STUB_ECHO_TOKEN
  ? `${base} [GH_TOKEN=${process.env.GH_TOKEN ?? "(none)"} GITHUB_TOKEN=${process.env.GITHUB_TOKEN ?? "(none)"}]`
  : base;
if (process.env.EPITO_STUB_ECHO_ROUTE) {
  result += ` [model=${flag("--model") ?? "(none)"} endpoint=${process.env.ANTHROPIC_BASE_URL ?? "(none)"} key=${process.env.ANTHROPIC_AUTH_TOKEN ?? "(none)"}]`;
}

// Incident 5, reproduced: a file this run picks the name of, in the temp
// directory it was handed, written and then read back after a pause.
if (process.env.EPITO_STUB_SCRATCH_FILE) {
  // os.tmpdir() reads $TMPDIR on every call, so this is the directory the
  // runtime gave this child and not the one it was built with.
  const where = tmpdir();
  const path = join(where, process.env.EPITO_STUB_SCRATCH_FILE);
  const prior = existsSync(path) ? readFileSync(path, "utf8") : null;
  const mine = `the body written by the run in ${basename(process.cwd())}`;
  writeFileSync(path, mine);
  const wait = Number.parseInt(process.env.EPITO_STUB_SCRATCH_WAIT_MS ?? "150", 10);
  if (Number.isFinite(wait) && wait > 0) await new Promise((r) => setTimeout(r, wait));
  const back = readFileSync(path, "utf8");
  result += ` [scratch=${where} prior=${prior === null ? "no" : "yes"} wrote="${mine}" read="${back}" ours=${back === mine ? "yes" : "no"} EPITO_SCRATCH=${process.env.EPITO_SCRATCH ?? "(none)"} TMPDIR=${process.env.TMPDIR ?? "(none)"}]`;
}

// `num_turns` before `result` and `session_id` after it, in the real
// executor's own key order: it is what makes a padded result lose the turn
// count and keep the session id.
const padKb = Number.parseInt(process.env.EPITO_STUB_RESULT_KB ?? "0", 10);
if (Number.isFinite(padKb) && padKb > 0) result += ` ${"y".repeat(padKb * 1024)}`;

process.stdout.write(JSON.stringify({
  type: "result", subtype: "success", is_error: false,
  duration_ms: 12, num_turns: prior.length + 1, result,
  session_id: sessionId, total_cost_usd: 0,
}) + "\n");
