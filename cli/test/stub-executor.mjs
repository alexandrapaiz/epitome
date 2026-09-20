#!/usr/bin/env node
// A stand-in for `claude` in the smoke test: same CLI shape, no tokens spent.
// It answers `--output-format json` the way the real executor does — one JSON
// object on stdout with session_id, num_turns and result — and it honours
// `--resume <id>` by keeping the same session_id and appending to that
// session's transcript, so a test can prove context was held.
//
//   EPITO_STUB_DIR   where transcripts live (default $TMPDIR/epito-stub)
//   EPITO_STUB_PR    a PR url the first run of a session "opens"
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

const prior = existsSync(transcript) ? readFileSync(transcript, "utf8").trim().split("\n").filter(Boolean) : [];
writeFileSync(transcript, [...prior, JSON.stringify({ ts: new Date().toISOString(), cwd: process.cwd(), resumed: Boolean(resume), prompt })].join("\n") + "\n");

// First turn of a session opens a PR; a resumed turn refers back to it, which
// is exactly the continuity the window is for.
const pr = process.env.EPITO_STUB_PR || "https://github.com/alexandrapaiz/epitome/pull/999";
const result = prior.length === 0
  ? `Opened a draft PR: ${pr}`
  : `Continuing session ${sessionId} (turn ${prior.length + 1}); my PR is still ${pr}`;

process.stdout.write(JSON.stringify({
  type: "result", subtype: "success", is_error: false,
  duration_ms: 12, num_turns: prior.length + 1, result,
  session_id: sessionId, total_cost_usd: 0,
}) + "\n");
