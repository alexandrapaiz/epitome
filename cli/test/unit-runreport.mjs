#!/usr/bin/env node --test
// The run report on the COMPANY board: where a run's company name comes from,
// and what this runtime POSTs to /api/runs.
//
//   node --test test/unit-runreport.mjs      # from cli/
//
// Its own file rather than another thousand lines in unit.mjs, for one
// mechanical reason: the end-to-end test drives the real `record` activity,
// and `.epito/` is resolved against the process's working directory, so this
// file chdirs into a temp directory for its whole run. `node --test` gives
// each file its own process, which is what makes that safe.
import { test } from "node:test";
import assert from "node:assert/strict";
import { createServer } from "node:http";
import { once } from "node:events";
import { mkdtempSync, rmSync, writeFileSync, mkdirSync, readFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { companyFor, findCompanyFile, topLevelScalars, COMPANY_FILE } from "../src/lib/company.js";
import { boardApi, runUrlFor, runReportBody, reportLine, answerSays, postRunReport } from "../src/lib/runreport.js";
import { reconcilePlan, scheduleShape } from "../src/temporal/schedules.js";
import { scheduleId } from "../src/temporal/env.js";

const temps = [];
const temp = () => { const d = mkdtempSync(join(tmpdir(), "epito-runreport-")); temps.push(d); return d; };
process.on("exit", () => { for (const d of temps) { try { rmSync(d, { recursive: true, force: true }); } catch {} } });

// --- where the company name comes from -------------------------------------

test("company.yaml's top-level scalars are read, and its nested blocks are not", () => {
  const f = topLevelScalars(`# a comment
company: alexandra-systems
product: epitome   # the name the board files under
posture: venture
surfaces:
  incidents: docs/agents/incidents.md
  pending: docs/backlog.md
seats:
  - { name: engineer, workflow: .github/workflows/agent-engineer.yml }
`);
  assert.equal(f.company, "alexandra-systems");
  assert.equal(f.product, "epitome");
  assert.equal(f.posture, "venture");
  // The indented keys belong to `surfaces`, and a reader that hoisted them
  // would answer "incidents" to a question about a company.
  assert.equal(f.incidents, undefined);
  assert.equal(f.pending, undefined);
  // A block opener is not a scalar.
  assert.equal(f.surfaces, undefined);
  assert.equal(f.seats, undefined);
});

test("this repository's own roster files its runs as epitome, the PRODUCT, not as the owning company", () => {
  // The whole point of the decision: `company:` here is alexandra-systems,
  // which runs several products, and the board's rows for this repository say
  // epitome. A reader that took the first plausible field would be wrong in a
  // way nobody notices until two companies' rows collide.
  const got = companyFor(new URL("../../agents", import.meta.url).pathname);
  assert.equal(got.name, "epitome");
  assert.match(got.path, /company\.yaml$/);
  assert.match(got.note, /file to the company board as "epitome"/);
});

test("the file is found by climbing out of the roster subdirectory, and not past the bound", () => {
  const root = temp();
  mkdirSync(join(root, "runtime", "agents", "pm"), { recursive: true });
  writeFileSync(join(root, COMPANY_FILE), "product: ursa\n");
  assert.equal(findCompanyFile(join(root, "runtime", "agents")), join(root, COMPANY_FILE));
  assert.equal(companyFor(join(root, "runtime", "agents")).name, "ursa");
  // Five levels down is past the bound: a walk that climbed further would
  // eventually find some OTHER company's file and file runs under it.
  const deep = join(root, "a", "b", "c", "d", "e");
  mkdirSync(deep, { recursive: true });
  assert.equal(findCompanyFile(deep), null);
});

test("a roster with no company.yaml files nothing, and the sentence names the rule and the fix", () => {
  const root = temp();
  const got = companyFor(root);
  assert.equal(got.name, null);
  assert.equal(got.path, null);
  assert.match(got.note, /no company\.yaml at or above/);
  assert.match(got.note, /file no report to the company board/);
  assert.match(got.note, /Fix: put a company\.yaml with a `product:` line/);
});

test("a company.yaml with no product: says which of the two names the board wants", () => {
  const root = temp();
  writeFileSync(join(root, COMPANY_FILE), "company: alexandra-systems\nposture: venture\n");
  const got = companyFor(root);
  assert.equal(got.name, null);
  assert.match(got.note, /has no top-level `product:` line/);
  // And it quotes the company it DID find, so the fix is a copy-paste rather
  // than a second trip to the file.
  assert.match(got.note, /not under the owning company's \(`company: alexandra-systems`\)/);
});

// --- the schedule carries it ------------------------------------------------

test("renaming the product re-registers the schedules instead of filing under the old name", () => {
  const manifest = {
    agent: { name: "pm", description: "d" },
    trigger: { cron: "0 6 * * *" },
    runtime: { model: "m", entry: "e", repo: "acme/roster", env: [] },
  };
  const desired = new Map([["pm", manifest]]);
  const registered = [{ id: scheduleId("pm"), shape: scheduleShape(manifest, { company: "epitome" }) }];

  assert.equal(reconcilePlan(desired, registered, { company: "epitome" }).unchanged.length, 1);
  const after = reconcilePlan(desired, registered, { company: "ursa" });
  assert.equal(after.update.length, 1, "a company rename is a change the engine has to be told about");
  assert.equal(after.unchanged.length, 0);
});

// --- the wire shape ---------------------------------------------------------

test("a company board needs both names, and half of one is reported as half", () => {
  assert.equal(boardApi({}).configured, false);
  assert.equal(boardApi({}).half, false);
  assert.equal(boardApi({ BOARD_API_URL: "https://b.example" }).half, true);
  assert.equal(boardApi({ BOARD_RUNTIME_TOKEN: "t" }).half, true);
  const ok = boardApi({ BOARD_API_URL: "https://b.example/", BOARD_RUNTIME_TOKEN: "t" });
  assert.equal(ok.configured, true);
  assert.equal(ok.url, "https://b.example", "the trailing slash comes off once, here, not at every call site");
});

test("run_url is the same for every retry of one run and different for the next one", () => {
  const a = runUrlFor({ agent: "pm", runId: "run-pm-message-1-abc12345", env: {} });
  const b = runUrlFor({ agent: "pm", runId: "run-pm-message-1-abc12345", env: {} });
  const c = runUrlFor({ agent: "pm", runId: "run-pm-message-2-def67890", env: {} });
  assert.equal(a, b, "the board dedupes on this, so a retried `record` must not invent a second key");
  assert.notEqual(a, c);
  assert.match(a, /^file:\/\/.*\/\.epito\/logs\/pm\/run-pm-message-1-abc12345\.log$/);
  // A host that publishes its logs gets rows an owner can click.
  assert.equal(
    runUrlFor({ agent: "pm", runId: "r 1", env: { EPITO_RUN_URL_BASE: "https://runs.example/x/" } }),
    "https://runs.example/x/pm/r%201",
  );
  assert.equal(runUrlFor({ agent: "pm", env: {} }), null);
});

test("the row's text is the product's vocabulary: a stage name, never an exit code", () => {
  assert.equal(
    reportLine({ agent: "pm", trigger: "cron", outcome: "ok", turns: 1, seconds: 42, pr: "https://x/1" }),
    "epitod · pm · cron · ok\n1 turn · 42s · https://x/1",
  );
  const failed = reportLine({ agent: "pm", trigger: "message", outcome: "clone", detail: "the charter is not there" });
  assert.match(failed, /epitod · pm · message · clone/);
  assert.match(failed, /the charter is not there/);
});

test("the body carries the names the endpoint requires, and an integer exit beside the word", () => {
  const body = runReportBody({
    company: "epitome", agent: "pm", repo: "alexandrapaiz/epitome", trigger: "cron",
    runId: "r1", model: "claude-opus-5", outcome: "clone", detail: "no charter",
    startedAt: "2026-10-18T09:00:00.000Z", runUrl: "file:///x.log",
  });
  assert.equal(body.company, "epitome");
  assert.equal(body.seat, "pm", "the endpoint calls it `seat`, and the agent's name is what goes in it");
  assert.equal(body.exit, 1);
  assert.equal(body.run_url, "file:///x.log");
  assert.equal(body.pr_url, null);
  assert.match(body.report, /clone/);
  assert.equal(runReportBody({ company: "epitome", agent: "pm", outcome: "ok" }).exit, 0);
});

test("each answer the board can give is one sentence that names the fix", () => {
  assert.equal(answerSays(201, {}), null);
  assert.match(answerSays(400, { url: "https://b.example", body: "unknown field" }), /refused this run report as malformed \(400\)/);
  assert.match(answerSays(400, { url: "https://b.example" }), /a bug here rather than on the box/);
  assert.match(answerSays(401, { url: "https://b.example" }), /did not accept BOARD_RUNTIME_TOKEN \(401\)/);
  assert.match(answerSays(401, { url: "https://b.example" }), /Fix: .*set BOARD_RUNTIME_TOKEN to the runtime token for https:\/\/b\.example/);
  assert.match(answerSays(503, { url: "https://b.example" }), /not taking run reports right now \(503\)/);
  assert.match(answerSays(503, { url: "https://b.example" }), /the next run files itself/);
  assert.match(answerSays(418, { url: "https://b.example" }), /answered 418/);
});

// --- the POST itself --------------------------------------------------------

async function boardServer(handler) {
  const seen = [];
  const server = createServer((req, res) => {
    let body = "";
    req.on("data", (c) => { body += c; });
    req.on("end", () => {
      seen.push({ url: req.url, auth: req.headers.authorization, body: JSON.parse(body || "{}") });
      handler(req, res, seen.length);
    });
  });
  server.listen(0, "127.0.0.1");
  await once(server, "listening");
  return { seen, url: `http://127.0.0.1:${server.address().port}`, close: () => server.close() };
}

test("a box with no company board files nothing and says nothing", async () => {
  const said = [];
  const r = await postRunReport({ company: "epitome", seat: "pm" }, { env: {}, log: (m) => said.push(m) });
  assert.equal(r.filed, false);
  assert.equal(r.reason, "no company board on this box");
  assert.deepEqual(said, [], "a stranger has no company board and must not be told they are missing one");
});

test("the report reaches /api/runs with the bearer token, and the token is not in the body", async () => {
  const board = await boardServer((req, res) => { res.writeHead(201); res.end("{}"); });
  try {
    const body = runReportBody({ company: "epitome", agent: "pm", outcome: "ok", runUrl: "file:///x.log" });
    const r = await postRunReport(body, {
      env: { BOARD_API_URL: `${board.url}/`, BOARD_RUNTIME_TOKEN: "sekret" },
      log: () => {},
    });
    assert.equal(r.filed, true);
    assert.equal(board.seen.length, 1);
    assert.equal(board.seen[0].url, "/api/runs");
    assert.equal(board.seen[0].auth, "Bearer sekret");
    assert.equal(board.seen[0].body.company, "epitome");
    assert.doesNotMatch(JSON.stringify(board.seen[0].body), /sekret/);
  } finally { board.close(); }
});

test("a board that refuses, or is not there at all, costs one log line and nothing else", async () => {
  const refusing = await boardServer((req, res) => { res.writeHead(503); res.end("restarting"); });
  const said = [];
  try {
    const r = await postRunReport(runReportBody({ company: "epitome", agent: "pm", outcome: "ok" }), {
      env: { BOARD_API_URL: refusing.url, BOARD_RUNTIME_TOKEN: "t" },
      log: (m) => said.push(m),
    });
    assert.equal(r.filed, false);
    assert.equal(r.status, 503);
  } finally { refusing.close(); }
  assert.equal(said.length, 1);
  assert.match(said[0], /the run is recorded, but/);

  // Nothing listening at all: the same promise, through a different failure.
  const dead = await postRunReport(runReportBody({ company: "epitome", agent: "pm", outcome: "ok" }), {
    env: { BOARD_API_URL: "http://127.0.0.1:1", BOARD_RUNTIME_TOKEN: "t" },
    log: (m) => said.push(m),
  });
  assert.equal(dead.filed, false);
  assert.match(said[1], /did not answer/);
});

// --- end to end, through the real `record` activity -------------------------

test("`record` files a run on the audit log, the local board AND the company board", async (t) => {
  const { record } = await import("../src/temporal/activities.js");
  const work = temp();
  const was = process.cwd();
  process.chdir(work);                      // .epito/ is resolved against cwd
  const board = await boardServer((req, res) => { res.writeHead(200); res.end("{}"); });
  const env = { BOARD_API_URL: board.url, BOARD_RUNTIME_TOKEN: "t" };
  const saved = { url: process.env.BOARD_API_URL, token: process.env.BOARD_RUNTIME_TOKEN };
  Object.assign(process.env, env);
  t.after(() => {
    board.close();
    process.chdir(was);
    if (saved.url === undefined) delete process.env.BOARD_API_URL; else process.env.BOARD_API_URL = saved.url;
    if (saved.token === undefined) delete process.env.BOARD_RUNTIME_TOKEN; else process.env.BOARD_RUNTIME_TOKEN = saved.token;
  });

  await record({
    name: "pm", trigger: "cron", runId: "run-pm-1-abcdef12", model: "claude-opus-5",
    company: "epitome", repo: "alexandrapaiz/epitome",
    startedAt: "2026-10-18T09:00:00.000Z", durationMs: 42_000, exit: 0, turns: 3, pr: "https://x/1",
  });

  assert.equal(board.seen.length, 1);
  const sent = board.seen[0].body;
  assert.equal(sent.company, "epitome");
  assert.equal(sent.seat, "pm");
  assert.equal(sent.repo, "alexandrapaiz/epitome");
  assert.equal(sent.exit, 0);
  assert.equal(sent.pr_url, "https://x/1");
  assert.equal(sent.started_at, "2026-10-18T09:00:00.000Z");
  assert.match(sent.run_url, /run-pm-1-abcdef12/);
  assert.match(sent.report, /epitod · pm · cron · ok/);

  // The two ledgers that work with no board at all are unchanged, and neither
  // of them grew a `company` or `repo` column: the local board refuses a field
  // it does not hold, by name, and that refusal is the thing being protected.
  const audit = readFileSync(join(work, ".epito", "audit.jsonl"), "utf8").trim().split("\n").map(JSON.parse);
  assert.equal(audit.length, 1);
  assert.equal(audit[0].action, "run.end");
  assert.equal(audit[0].company, undefined);
  assert.equal(audit[0].repo, undefined);
  const local = readFileSync(join(work, ".epito", "board.jsonl"), "utf8").trim().split("\n").map(JSON.parse);
  assert.equal(local.length, 1);
  assert.equal(local[0].outcome, "ok");
  assert.equal(local[0].company, undefined);

  // A run from a roster with no company.yaml reaches the same code and files
  // nothing: the company board is an integration, not a dependency.
  await record({
    name: "pm", trigger: "cron", runId: "run-pm-2-abcdef12", model: "m", exit: 0,
  });
  assert.equal(board.seen.length, 1, "no company name, so there was nothing to file under");
  assert.equal(readFileSync(join(work, ".epito", "board.jsonl"), "utf8").trim().split("\n").length, 2);
});
