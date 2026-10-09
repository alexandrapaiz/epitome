#!/usr/bin/env node --test
// Unit tests for the ledger's read half — `epito audit`'s fold, its sentences
// and its --since. Run with:
//
//   node --test test/unit-audit.mjs      # from cli/
//
// The end-to-end path is test/smoke-deploy.sh §7, which reads back a ledger
// that `epito deploy` and `epito token` actually wrote. What is pinned here is
// the part that decides what the operator is TOLD, because every one of these
// is a place where the ledger could quietly under-report what an agent was
// allowed to do.
import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, rmSync, writeFileSync, mkdirSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import {
  readJsonl, readAudit, parseSince, foldAudit, describe, renderAudit, actionMatches, ACTIONS,
} from "../src/lib/audit.js";

const temps = [];
const temp = () => { const d = mkdtempSync(join(tmpdir(), "epito-audit-unit-")); temps.push(d); return d; };
process.on("exit", () => { for (const d of temps) rmSync(d, { recursive: true, force: true }); });

const L = (ts, agent, action, rest = {}) => ({ ts, agent, action, ...rest });
const MINT = {
  permissions: { contents: "write", pull_requests: "write" },
  scopes: ["github:contents", "github:pull_requests"],
  repo: "acme/product", installation: "42", expiresAt: "2026-10-02T15:04:07Z",
  commit: { name: "digest[bot]", email: "d@users.noreply.github.com" },
};

const LEDGER = [
  L("2026-10-02T14:02:11.004Z", null, "worker.start", { address: "127.0.0.1:7233", namespace: "default", queue: "seats" }),
  L("2026-10-02T14:03:01.000Z", "digest", "deploy", { created: true, appId: "1234", slug: "digest-acme", repo: "acme/product", installation: "42", permissions: MINT.permissions }),
  L("2026-10-02T14:04:07.880Z", "digest", "mint", { runId: "r-9f12", phase: "clone", ...MINT }),
  L("2026-10-02T14:04:09.100Z", "digest", "run.start", { runId: "r-9f12", trigger: "cron", model: "claude-sonnet-5" }),
  L("2026-10-02T14:31:44.000Z", "digest", "run.end", { runId: "r-9f12", outcome: "ok", turns: 23, seconds: 1654, pr: "https://github.com/acme/product/pull/7" }),
  L("2026-10-02T14:40:00.000Z", "pm", "run.end", { runId: "r-aa01", outcome: "failed", turns: 2, durationMs: 9500, detail: "the charter file is missing" }),
  L("2026-10-02T14:41:00.000Z", "pm", "route.refused", { runId: "r-aa01", route: "bedrock", model: "claude-sonnet-5", exit: "7" }),
];

test("a line this epito cannot parse is counted, never dropped and never fatal", () => {
  const dir = temp();
  mkdirSync(join(dir, ".epito"));
  const path = join(dir, ".epito", "audit.jsonl");
  // A crash mid-append leaves a half line; a JSON array is not a ledger entry.
  writeFileSync(path, [
    JSON.stringify(LEDGER[1]),
    "{\"ts\":\"2026-10-02T14:03:02.000Z\",\"agent\":\"digest\",\"act",
    "[1,2,3]",
    "",
    JSON.stringify(LEDGER[2]),
  ].join("\n") + "\n");

  const { entries, unreadable, exists } = readJsonl(path);
  assert.equal(exists, true);
  assert.equal(entries.length, 2, "the readable lines survive the unreadable ones");
  assert.equal(unreadable, 2, "the half line and the array are both counted");
  assert.match(renderAudit(foldAudit(entries), { unreadable, path }), /2 lines in .* could not be read as JSON/);
});

test("a ledger that is not there is not an error, and says where it would be", () => {
  const { lines, unreadable, exists } = readAudit({ path: join(temp(), ".epito", "audit.jsonl") });
  assert.deepEqual({ lines, unreadable, exists }, { lines: [], unreadable: 0, exists: false });
});

test("the fold answers the identity question: who holds what, on what, until when", () => {
  const fold = foldAudit(LEDGER, { limit: 20 });
  const digest = fold.seats.find((s) => s.name === "digest");
  assert.equal(digest.mints, 1);
  assert.equal(digest.deploys, 1);
  assert.equal(digest.app, "1234");
  assert.equal(digest.repo, "acme/product");
  assert.equal(digest.permissions, "contents:write, pull_requests:write");
  assert.equal(digest.lastMint, "2026-10-02T14:04:07.880Z");
});

test("the permissions column is the LAST mint's, because that is what the agent holds now", () => {
  const widened = [
    L("2026-10-02T10:00:00.000Z", "pm", "mint", { ...MINT, permissions: { contents: "read" } }),
    L("2026-10-02T11:00:00.000Z", "pm", "mint", { ...MINT, permissions: { contents: "write", issues: "write" } }),
  ];
  assert.equal(foldAudit(widened).seats[0].permissions, "contents:write, issues:write");
  // and the older, narrower grant is still in the tail — history is not lost,
  // it is just not what the summary row claims is current.
  assert.equal(foldAudit(widened).recent.length, 2);
});

test("a run is one runId, counted from either end of it", () => {
  // The run.end whose run.start is not in the ledger: truncated, or filtered
  // out by --since. A seat with FAILED 1 and RUNS - is a reader nobody trusts.
  const pm = foldAudit(LEDGER).seats.find((s) => s.name === "pm");
  assert.equal(pm.runs, 1);
  assert.equal(pm.failed, 1);
  assert.equal(pm.refused, 1);
  // Both ends of the same run count once.
  const digest = foldAudit(LEDGER).seats.find((s) => s.name === "digest");
  assert.equal(digest.runs, 1, "run.start and run.end of r-9f12 are one run, not two");
  assert.equal(digest.failed, 0);
});

test("lines that name no seat get no row in a table of seats, and are counted out loud", () => {
  const fold = foldAudit(LEDGER);
  assert.deepEqual(fold.seats.map((s) => s.name), ["digest", "pm"], "no row called null");
  assert.equal(fold.runtimeLines, 1);
  assert.ok(fold.recent.some((l) => l.action === "worker.start"), "and it still appears in the tail");
  assert.match(renderAudit(fold, {}), /1 line names no seat/);
});

test("--agent, --action and --since filter, and the header says how much was left out", () => {
  assert.equal(foldAudit(LEDGER, { agent: "pm" }).matched, 2);
  assert.equal(foldAudit(LEDGER, { action: "mint" }).matched, 1);
  // A prefix matches its family; the exact name matches only itself.
  assert.equal(foldAudit(LEDGER, { action: "run" }).matched, 3, "run.start and both run.ends");
  assert.equal(foldAudit(LEDGER, { action: "run.end" }).matched, 2);
  assert.equal(foldAudit(LEDGER, { since: "2026-10-02T14:35:00.000Z" }).matched, 2);
  assert.match(renderAudit(foldAudit(LEDGER, { agent: "pm" }), {}), /2 of 7 lines/);
});

test("--limit 0 is all of it, and a truncated tail says so", () => {
  assert.equal(foldAudit(LEDGER, { limit: 0 }).recent.length, LEDGER.length);
  const fold = foldAudit(LEDGER, { limit: 2 });
  assert.equal(fold.recent.length, 2);
  assert.deepEqual(fold.recent.map((l) => l.action), ["run.end", "route.refused"], "the tail is the NEWEST lines, oldest first");
  assert.match(renderAudit(fold, {}), /showing the last 2 of 7 matching/);
});

test("--since takes a window or a UTC date, and refuses anything else by name", () => {
  const now = new Date("2026-10-02T12:00:00.000Z");
  assert.equal(parseSince("24h", { now }).at, "2026-10-01T12:00:00.000Z");
  assert.equal(parseSince("30m", { now }).at, "2026-10-02T11:30:00.000Z");
  assert.equal(parseSince("7d", { now }).at, "2026-09-25T12:00:00.000Z");
  // A bare date is midnight UTC, not midnight wherever the reader is sitting:
  // every ts in this file is UTC, and mixing the two would quietly drop the
  // first hours of the day someone asked about.
  assert.equal(parseSince("2026-10-02", { now }).at, "2026-10-02T00:00:00.000Z");
  assert.equal(parseSince("2026-10-02T14:00", { now }).at, "2026-10-02T14:00:00.000Z");
  for (const bad of ["yesterday", "", "24", "h24", "last week"]) {
    const r = parseSince(bad, { now });
    assert.ok(r.error, `"${bad}" should be refused`);
    assert.match(r.error, /--since/);
    assert.match(r.error, /Fix:/, "the refusal carries the fix, like every other epito error");
  }
});

test("every action epito writes has a sentence, and an unknown one still prints", () => {
  for (const action of ACTIONS) {
    const said = describe(L("2026-10-02T14:00:00.000Z", "pm", action, { ...MINT, created: true, appId: "1", trigger: "cron", model: "m", bytes: 1, exit: "1", route: "r", schedule: "s", cron: "0 6 * * *", signal: "SIGTERM", address: "a", dir: "d", outcome: "ok" }));
    assert.ok(said && said !== "(no detail on the line)", `${action} has no sentence`);
    assert.ok(!said.includes("false"), `${action}'s sentence leaked a false from an && guard: ${said}`);
    assert.ok(!said.includes("undefined"), `${action}'s sentence leaked an undefined: ${said}`);
  }
  // The important case: a line written by a NEWER epito than the one reading.
  // If the fallback hid it, upgrading the runtime would silently blind the
  // auditor on exactly the events that are new.
  const future = describe(L("2026-10-02T14:00:00.000Z", "pm", "quota.exhausted", { window: "5h", resets: "2026-10-02T19:00:00Z" }));
  assert.match(future, /window=5h/);
  assert.match(future, /resets=2026-10-02T19:00:00Z/);
  assert.equal(describe(L("2026-10-02T14:00:00.000Z", "pm", "mystery")), "(no detail on the line)");
});

test("the mint sentence carries every fact about the credential except the credential", () => {
  const said = describe(LEDGER[2]);
  assert.match(said, /contents:write, pull_requests:write on acme\/product/);
  assert.match(said, /installation 42/);
  assert.match(said, /expires 15:04Z/);
  assert.match(said, /as digest\[bot\]/);
  // The ledger holds no token by design (src/token.js: "the token is never
  // written anywhere: not the audit line, not the log, not a file"), so there
  // is nothing here to redact — and a reader that invented a token field would
  // be the one place it could come back. Nothing in the render reads one.
  const planted = { ...LEDGER[2], token: "ghs_THISMUSTNEVERBEPRINTED00000000000000" };
  const out = renderAudit(foldAudit([planted]), {});
  assert.ok(!out.includes("ghs_THISMUSTNEVERBEPRINTED00000000000000"),
    "a `token` field that somehow reached the ledger must not be printed by the reader");
});

test("an empty ledger and a ledger with no match say different, useful things", () => {
  assert.match(renderAudit(foldAudit([]), {}), /the ledger is empty/);
  const none = renderAudit(foldAudit(LEDGER, { agent: "nobody" }), { filters: { agent: "nobody" } });
  assert.match(none, /no line in .* matches --agent nobody/);
  assert.match(none, /7 lines in the ledger, none of them this/);
});

test("actionMatches is a family, not a substring", () => {
  assert.ok(actionMatches("run.start", "run"));
  assert.ok(actionMatches("run.start", "run.start"));
  assert.ok(!actionMatches("run.start", "start"), "a suffix is not a family");
  assert.ok(!actionMatches("runner", "run"), "and neither is a word that merely begins the same");
});
