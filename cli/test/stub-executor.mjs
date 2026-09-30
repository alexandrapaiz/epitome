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
//   EPITO_STUB_ECHO_ROUTE
//                    print the route's endpoint and model in the result, so a
//                    test can read which road the run actually took.
//   EPITO_STUB_ECHO_TOKEN
//                    print the GH_TOKEN this child was handed, in its result.
//                    The identity slice's whole claim is about which
//                    credential reaches this process, so a test has to be able
//                    to read it — and printing a credential into stdout is
//                    also precisely what a real `gh` error path does, which is
//                    what the run log's scrubbing is there to survive.
import { mkdirSync, writeFileSync, readFileSync, existsSync } from "node:fs";
import { join } from "node:path";
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
const base = prior.length === 0
  ? `Opened a draft PR: ${pr}`
  : `Continuing session ${sessionId} (turn ${prior.length + 1}); my PR is still ${pr}`;
let result = process.env.EPITO_STUB_ECHO_TOKEN
  ? `${base} [GH_TOKEN=${process.env.GH_TOKEN ?? "(none)"} GITHUB_TOKEN=${process.env.GITHUB_TOKEN ?? "(none)"}]`
  : base;
if (process.env.EPITO_STUB_ECHO_ROUTE) {
  result += ` [model=${flag("--model") ?? "(none)"} endpoint=${process.env.ANTHROPIC_BASE_URL ?? "(none)"} key=${process.env.ANTHROPIC_AUTH_TOKEN ?? "(none)"}]`;
}

process.stdout.write(JSON.stringify({
  type: "result", subtype: "success", is_error: false,
  duration_ms: 12, num_turns: prior.length + 1, result,
  session_id: sessionId, total_cost_usd: 0,
}) + "\n");
