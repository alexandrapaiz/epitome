#!/usr/bin/env node --test
// Unit tests for the parts that need no server: the reconcile diff, the
// manifest additions, and the clone-path guard. Run with:
//
//   node --test test/unit.mjs      # from cli/
//
// The reconcile diff is a pure function of (desired roster, schedules already
// registered), which is the whole reason `epito run` is safe to re-run: these
// six cases are the command's entire behavior.
import { test, after } from "node:test";
import assert from "node:assert/strict";
import { reconcilePlan, scheduleShape, listSeatSchedules } from "../src/temporal/schedules.js";
import { validateManifest, loadManifest, FIELDS, TABLES } from "../src/lib/manifest.js";
import { blockers, unchecked, REPO_REQUIRED_BY, SCOPE_REQUIRED_BY } from "../src/lib/readiness.js";
import { parseGitHubRemote, originRepo, repoRoot } from "../src/lib/origin.js";
import { loadRoster, rosterRules, ROSTER_RULES } from "../src/lib/roster.js";
import { SEVERITY, checkManifest, shape } from "../src/validate.js";
import { readdirSync } from "node:fs";
import { webhookName } from "../src/lib/slack.js";
import { runtimeBuild, buildLine, buildNote, porcelainPaths, thisRuntime } from "../src/lib/build.js";
import { rosterEnv, namesFor, envTemplate, holding, runShortfall, shortfallSays, HELD, EMPTY, ABSENT } from "../src/lib/boxenv.js";
import { isCloneDir, cloneDirPrefix, executeAgent, cloneAgentRepo, gitEnvFor, buildPrompt, shortfallLine, runBranchPrefix, pullRequestForRun, GIT_TOKEN_ENV } from "../src/lib/runner.js";
import { permissionsFor, appJwt, envNames, loadPrincipal, SCOPE_MAP, noRepoMessage, webRoot, installUrl, appSettingsUrl } from "../src/lib/identity.js";
import {
  actsAs, rosterActs, rosterInstalled, grantGap, IDENTITY_FIX,
  OWN, REFUSED, HALF, SHARED, NONE,
  INSTALLED, MISMATCH, UNGRANTED, GH_REFUSED, UNREACHABLE, INSTALL_REFUSES,
} from "../src/lib/acts.js";
import { spawn, execFileSync } from "node:child_process";
import { parse } from "smol-toml";
import { mkdirSync } from "node:fs";
import { once } from "node:events";
import { generateKeyPairSync, createVerify } from "node:crypto";
import { readFileSync, writeFileSync, mkdtempSync, rmSync, existsSync, chmodSync, realpathSync } from "node:fs";
import { seatOfWorkflowId, scheduleId, runId, windowId } from "../src/temporal/env.js";
import { justCompleted, sendOrRestart, sayShortfall } from "../src/run.js";
import { ADAPTERS, ADAPTER_NAMES, adapterFor, unknownAdapter, LANGGRAPH_SHIM } from "../src/lib/adapters.js";
import {
  DEFAULT_ADDRESS, connectReason, engineAnswering, engineFix, engineMissing,
  engineUnreachableMessage, splitAddress,
} from "../src/lib/engine.js";
import { createServer as createTcpServer } from "node:net";
import {
  routesFor, routeErrors, liveRoutes, noRouteMessage, anthropicRouteEnv, routeFacts,
  resolveEndpoint, endpointLabel,
  classifyAttempt, withLane, DEFAULT_ROUTE, ROUTE_FIELDS,
} from "../src/lib/router.js";
import { SPEC_VERSION } from "../src/lib/fields.js";
import { baseRunEnv, RUNTIME_GIVEN } from "../src/lib/runenv.js";
import { whichIn, lookAtExecutor, deepKey, probeFor, PROBES } from "../src/lib/probe.js";
import { engineLook } from "../src/doctor.js";
import {
  describeQueue, summarize, psMark, ageMs, durationMs, WORKER_FIX, WORKER_REFUSES,
  POLLED, STALLED, HALF as WORKER_HALF, NONE as WORKER_NONE, UNASKED as WORKER_UNASKED,
  RECENT_MS, STALLED_MS, TASK_QUEUE_TYPE,
} from "../src/temporal/pollers.js";
import {
  traceConfig, traceIdFor, spanIdFor, traceparentFor, childTraceEnv, attributes,
  span, payload, emit, parseHeaders, traceNote, resetQuiet,
} from "../src/lib/trace.js";
import { createServer } from "node:http";
import { cpSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { tmpdir } from "node:os";
import { join } from "node:path";

// Every temp dir this suite makes, swept when the suite ends. Ten call sites
// made one each and removed none, so a single `node --test test/unit.mjs` left
// a hundred-odd directories in $TMPDIR — and the smoke test asserts "no clone
// was left behind" by globbing that same directory, so the mess is not only
// untidy, it is in the way.
// Nothing in this suite talks to GitHub. Every run now ends by asking the
// code host whether it opened a pull request, so the default here is a port
// nothing listens on: a test that does not stand up its own stand-in gets a
// lookup refused in a millisecond and the fallback it always had, and no
// assertion in this file depends on somebody's network or spends a rate
// limit. The cases that DO assert the lookup point this at their own server.
process.env.EPITO_GITHUB_API = "http://127.0.0.1:1";

const TMPDIRS = [];
const tmpDir = (prefix = "epito-unit-") => {
  const d = mkdtempSync(join(tmpdir(), prefix));
  TMPDIRS.push(d);
  return d;
};
after(() => { for (const d of TMPDIRS) rmSync(d, { recursive: true, force: true }); });

const seat = (name, over = {}) => ({
  agent: { name, description: "A seat." },
  identity: { scopes: ["github:contents"] },
  trigger: { cron: "0 6 * * *", ...(over.trigger ?? {}) },
  runtime: { model: "claude-sonnet-5", entry: `prompts/${name}.md`, repo: "acme/roster", ...(over.runtime ?? {}) },
});

const desiredOf = (...manifests) => new Map(manifests.map((m) => [m.agent.name, m]));
const actualOf = (...manifests) => manifests.map((m) => ({ id: scheduleId(m.agent.name), shape: scheduleShape(m) }));

test("reconcile: a seat that gained a cron is created", () => {
  const p = reconcilePlan(desiredOf(seat("pm")), []);
  assert.deepEqual(p.create.map((c) => c.id), ["seat:pm"]);
  assert.equal(p.update.length + p.delete.length + p.unchanged.length, 0);
});

test("reconcile: an unchanged manifest churns nothing", () => {
  const pm = seat("pm");
  const p = reconcilePlan(desiredOf(pm), actualOf(pm));
  assert.deepEqual(p.unchanged.map((c) => c.id), ["seat:pm"]);
  assert.equal(p.create.length + p.update.length + p.delete.length, 0);
});

test("reconcile: a changed cron is an update, and names what changed", () => {
  const before = seat("pm");
  const after = seat("pm", { trigger: { cron: "30 7 * * 1-5" } });
  const p = reconcilePlan(desiredOf(after), actualOf(before));
  assert.equal(p.update.length, 1);
  assert.equal(p.update[0].shape.cron, "30 7 * * 1-5");
  assert.equal(p.update[0].was.cron, "0 6 * * *");
});

test("reconcile: a changed model is an update — the schedule carries the manifest", () => {
  const before = seat("pm");
  const after = seat("pm", { runtime: { model: "claude-opus-5" } });
  const p = reconcilePlan(desiredOf(after), actualOf(before));
  assert.equal(p.update.length, 1);
  assert.equal(p.update[0].shape.model, "claude-opus-5");
});

test("reconcile: [runtime].env order alone is not a change", () => {
  const before = seat("pm", { runtime: { env: ["GH_TOKEN", "CLAUDE_CODE_OAUTH_TOKEN"] } });
  const after = seat("pm", { runtime: { env: ["CLAUDE_CODE_OAUTH_TOKEN", "GH_TOKEN"] } });
  const p = reconcilePlan(desiredOf(after), actualOf(before));
  assert.equal(p.unchanged.length, 1, "sorting the same names is not a manifest change");
});

test("reconcile: a seat that LOST its cron has its schedule deleted", () => {
  const withCron = seat("pm");
  const presenceOnly = seat("pm", { trigger: { cron: undefined, webhook: true } });
  delete presenceOnly.trigger.cron;
  // The caller only puts cron'd seats in `desired`, which is the point: a
  // presence-only seat is simply absent from it.
  const p = reconcilePlan(new Map(), actualOf(withCron));
  assert.deepEqual(p.delete.map((d) => d.id), ["seat:pm"]);
  assert.equal(scheduleShape(withCron).cron, "0 6 * * *");
  assert.equal(presenceOnly.trigger.cron, undefined);
});

test("reconcile: a schedule with no manifest behind it is deleted, and a foreign id is left alone", () => {
  const p = reconcilePlan(desiredOf(seat("pm")), [
    { id: "seat:gone", shape: scheduleShape(seat("gone")) },
    { id: "something-else", shape: null },
  ]);
  assert.deepEqual(p.delete.map((d) => d.id), ["seat:gone"]);
  assert.deepEqual(p.create.map((c) => c.id), ["seat:pm"]);
});

// The bug these four cover was found on 2026-10-06 by running
// test/smoke-temporal.sh against a real engine for the first time, and it had
// survived precisely because the only suite that could see it is the one that
// needs a `temporal` binary and so reports `unrun` on every box. The pure
// planner above was correct the whole time; what was wrong was the `actual`
// handed to it. So these stub the client: no engine, catchable anywhere.
//
// `epito run` stored the registered shape in the schedule's memo and read it
// back from there. `ScheduleHandle.update()` accepts a memo and Temporal's
// UpdateSchedule RPC has no memo field, so the SDK drops it: the memo holds the
// CREATE-time shape forever, and reconcile reapplied the same update on every
// restart while `epito ps` printed a cron the engine was not using.
const fakeClient = (schedules) => ({
  schedule: {
    async *list() { for (const s of schedules) yield { scheduleId: s.id, note: s.note ?? null, memo: s.memo ?? undefined }; },
    getHandle(id) {
      const s = schedules.find((x) => x.id === id);
      return { describe: async () => {
        if (!s || s.describeThrows) throw new Error("schedule not found");
        return { memo: s.memo ?? undefined, action: { type: "startWorkflow", args: s.args ?? [] } };
      } };
    },
  },
});

test("listSeatSchedules: the shape comes from the action, not from the stale memo", async () => {
  const live = seat("pm", { trigger: { cron: "0 13 * * 5" } });
  const got = await listSeatSchedules(fakeClient([{
    id: "seat:pm",
    // What the engine will actually run: the manifest the action carries.
    args: [{ name: "pm", manifest: live }],
    // What the memo still says, because an update could not rewrite it.
    memo: { seat: "pm", shape: JSON.stringify(scheduleShape(seat("pm", { trigger: { cron: "0 12 * * 5" } }))) },
  }]));
  assert.equal(got.length, 1);
  assert.equal(got[0].shape.cron, "0 13 * * 5", "read the action's cron, not the memo's");
});

test("reconcile CONVERGES after an update: the second pass has nothing to do", async () => {
  const live = seat("pm", { trigger: { cron: "0 13 * * 5" } });
  const actual = await listSeatSchedules(fakeClient([{
    id: "seat:pm",
    args: [{ name: "pm", manifest: live }],
    memo: { seat: "pm", shape: JSON.stringify(scheduleShape(seat("pm", { trigger: { cron: "0 12 * * 5" } }))) },
  }]));
  const p = reconcilePlan(desiredOf(live), actual);
  assert.equal(p.unchanged.length, 1, "an applied update must not be reapplied forever");
  assert.equal(p.update.length, 0);
});

test("listSeatSchedules: ids that are not seats are left out, and only seats are described", async () => {
  const got = await listSeatSchedules(fakeClient([
    { id: "seat:pm", args: [{ name: "pm", manifest: seat("pm") }] },
    { id: "someone-elses-schedule", args: [] },
  ]));
  assert.deepEqual(got.map((g) => g.id), ["seat:pm"]);
});

test("listSeatSchedules: an unreadable schedule reads as a difference, so the next pass rewrites it", async () => {
  const got = await listSeatSchedules(fakeClient([
    { id: "seat:pm", describeThrows: true },
    { id: "seat:okr", args: [{ name: "okr", manifest: { agent: { name: "okr" }, trigger: {}, runtime: {} } }] },
  ]));
  assert.deepEqual(got.map((g) => g.shape), [null, null]);
  // null is not "unchanged": it must plan an update rather than leave a
  // schedule nobody can account for in place.
  const p = reconcilePlan(desiredOf(seat("pm")), got.filter((g) => g.id === "seat:pm"));
  assert.equal(p.update.length, 1);
});

test("reconcile: 36 presence-only seats register nothing at all", () => {
  const p = reconcilePlan(new Map(), []);
  assert.deepEqual(p, { create: [], update: [], delete: [], unchanged: [] });
});

// --- the bar on a refusal: name the rule, in our words, with the fix -------
//
// The spec states the bar once and `epito validate` is where a vibecoder meets
// it: "name the rule broken, in the product's own vocabulary, with the fix in
// the message". The messages written after the bar was set carry an explicit
// `Fix:`; the ones written before it said only what was wrong — nineteen of
// the twenty-five refusals `epito validate` can print, including the three a
// newcomer is most likely to see.
//
// So the bar is a test. Every refusal the validator can print in its own voice
// is named below with a manifest that provokes it, and each has to carry a fix
// the reader can act on. The count assertions are the drift catch: a new
// `errors.push` with no case here fails this test rather than shipping a
// message nobody held to the bar.

// A fix is an instruction, not a diagnosis. Ours say it as `Fix:` — except the
// credential tripwire, which was written as "Move it to a secret" and reads
// better that way.
const carriesAFix = (msg) => /Fix:|\bMove it to\b/.test(msg);

// `seat()` with fields set, removed (undefined) or whole tables stripped.
const provoke = ({ strip = [], tables = {}, raw = "", ...over }) => {
  const m = seat("pm");
  for (const t of strip) delete m[t];
  for (const [t, fields] of Object.entries(over)) {
    m[t] = { ...m[t], ...fields };
    for (const [k, v] of Object.entries(fields)) if (v === undefined) delete m[t][k];
  }
  return validateManifest({ ...m, ...tables }, { baseDir: "/nonexistent", raw });
};

const held = (label, manifest) => test(`a refusal carries the fix: ${label}`, () => {
  const errors = provoke(manifest);
  assert.ok(errors.length > 0, `"${label}" was meant to be refused and validated clean`);
  for (const e of errors) assert.ok(carriesAFix(e), `says what is wrong and not what to do:\n    ${e}`);
});

// One per literal `errors.push` in src/lib/manifest.js, in source order.
const REFUSALS = [
  ["missing triad",         { strip: ["identity"] }],
  ["unknown table",         { tables: { cron: { at: "0 6" } } }],
  ["name missing",          { agent: { name: undefined } }],
  ["name shape",            { agent: { name: "Historian" } }],
  ["description missing",   { agent: { description: undefined } }],
  ["scopes not an array",   { identity: { scopes: "github:contents" } }],
  ["scope shape",           { identity: { scopes: ["repo"] } }],
  ["trigger empty",         { trigger: { cron: undefined } }],
  ["cron unparseable",      { trigger: { cron: "@daily" } }],
  ["webhook not a bool",    { trigger: { webhook: "yes" } }],
  ["subscriptions scalar",  { trigger: { subscriptions: "asc.events.>" } }],
  ["subscriptions empty",   { trigger: { subscriptions: [] } }],
  ["two subjects overlap",  { trigger: { subscriptions: ["asc.events.>", "asc.events.pm.message.posted"] } }],
  ["model missing",         { runtime: { model: undefined } }],
  ["entry missing",         { runtime: { entry: undefined } }],
  ["entry absent on disk",  { runtime: { entry: "prompts/nope.md", repo: undefined } }],
  ["repo shape",            { runtime: { repo: "github.com/acme/roster" } }],
  ["ref shape",             { runtime: { ref: "-rf" } }],
  ["adapter unknown",       { runtime: { adapter: "crewai" } }],
  ["graph shape",           { runtime: { graph: "a b" } }],
  ["graph without adapter", { runtime: { graph: "digest" } }],
  ["max_turns shape",       { runtime: { max_turns: "40" } }],
  ["env holds a value",     { runtime: { env: ["TOKEN=abc"] } }],
  ["slack name shape",      { runtime: { slack_webhook_env: "https://hooks.slack.com/x" } }],
  ["slack name unlisted",   { runtime: { slack_webhook_env: "PM_SLACK" } }],
  ["a pasted credential",   { raw: `token = "ghp_${"A".repeat(36)}"` }],
];
for (const [label, manifest] of REFUSALS) held(label, manifest);

// And one per literal push in src/lib/router.js, which prints through the same
// `epito validate` and so answers to the same bar.
const ROUTE_REFUSALS = [
  ["route table not a list", { runtime: { route: "kimi" } }],
  ["route not a table",      { runtime: { route: ["kimi"] } }],
  ["route name shape",       { runtime: { route: [{ name: "Kimi!", model: "m" }] } }],
  ["two routes one name",    { runtime: { route: [{ name: "k", model: "m" }, { name: "k", model: "m" }] } }],
  ["route model missing",    { runtime: { model: undefined, route: [{ name: "k" }] } }],
  ["base_url not a URL",     { runtime: { route: [{ name: "k", model: "m", base_url: "moonshot.ai" }] } }],
  ["base_url holds a key",   { runtime: { route: [{ name: "k", model: "m", base_url: "https://u:p@x.ai" }] } }],
  ["base_url_env shape",     { runtime: { route: [{ name: "k", model: "m", base_url_env: "my var" }] } }],
  ["base_url_env unlisted",  { runtime: { route: [{ name: "k", model: "m", base_url_env: "GATEWAY_URL" }] } }],
  ["base_url_env + base_url", { runtime: { env: ["GATEWAY_URL"], route: [{ name: "k", model: "m", base_url_env: "GATEWAY_URL", base_url: "https://x.ai" }] } }],
  ["token_env shape",        { runtime: { route: [{ name: "k", model: "m", token_env: "my key" }] } }],
  ["token_env unlisted",     { runtime: { route: [{ name: "k", model: "m", token_env: "KIMI_KEY" }] } }],
  ["concurrency shape",      { runtime: { route: [{ name: "k", model: "m", concurrency: 0 }] } }],
];
for (const [label, manifest] of ROUTE_REFUSALS) held(label, manifest);

test("the bar covers EVERY refusal these two modules print in their own voice", () => {
  const read = (f) => readFileSync(new URL(`../src/lib/${f}`, import.meta.url), "utf8");
  // Three of the pushes delegate to a module with its own bar (`...unknownKeys`
  // from fields.js, `...routeErrors` from router.js, counted on its own line
  // below, and `...subjectErrors` from subjects.js, whose every branch is held
  // to this same bar in test/unit-bus.mjs); every other push is the file's own
  // voice, including the spread of its own `repoErrors`. router.js also refuses
  // the whole field with a bare `return [message]`, which is why its count gets
  // a +1.
  const mine = (src) => (src.match(/errors\.push\(/g) ?? []).length
    - (src.match(/errors\.push\(\.\.\.(unknownKeys|routeErrors|subjectErrors)/g) ?? []).length;
  const manifestJs = read("manifest.js");
  const routerJs = read("router.js");
  // `adapter unknown` is a push of a message adapters.js composed; it is still
  // this validator's output, and adapters.js already carries its own fix.
  assert.equal(mine(manifestJs), REFUSALS.length,
    `src/lib/manifest.js prints ${mine(manifestJs)} refusals in its own voice and REFUSALS covers ` +
    `${REFUSALS.length}. A new message needs a case above, or nobody held it to the bar.`);
  assert.equal(mine(routerJs) + 1, ROUTE_REFUSALS.length,
    `src/lib/router.js prints ${mine(routerJs) + 1} refusals and ROUTE_REFUSALS covers ${ROUTE_REFUSALS.length}.`);
});

// --- [runtime].repo is a GitHub repository, and GitHub has rules -----------
//
// The old rule was "two things with a slash". It blessed `acme/roster.git` —
// GitHub refuses a name ending in .git, and `epito run` clones
// `https://github.com/<repo>.git`, so that manifest asked for roster.git.git —
// and it blessed `../..`, which `epito deploy` and `epito token` would have put
// in an api.github.com path. Both got a ✓ and then failed at clone or mint
// time, which is the one thing src/lib/readiness.js exists to prevent.
test("[runtime].repo: GitHub's own rules for an owner and a name", () => {
  const refused = (repo) => validateManifest(seat("pm", { runtime: { repo } }), { baseDir: "/nonexistent" })
    .filter((e) => e.startsWith("[runtime].repo"));
  for (const repo of [
    "acme/roster.git",                 // GitHub: a name cannot end in .git
    "../..",                           // a path, in a field that becomes a URL
    "acme/..",
    "acme/.",
    "-acme/roster",                    // an owner cannot begin with a hyphen
    "acme-/roster",                    // nor end with one
    "acme.co/roster",                  // nor hold a dot
    "acme_co/roster",                  // nor an underscore
    `${"a".repeat(40)}/roster`,        // 39 is GitHub's ceiling for an owner
    `acme/${"r".repeat(101)}`,         // 100 is its ceiling for a name
    "github.com/acme/roster",
    "https://github.com/acme/roster",
    "git@github.com:acme/roster.git",
    "acme/roster/",
    "/acme/roster",
    "acme//roster",
    "acme roster",
    "acme",
  ]) assert.equal(refused(repo).length, 1, `[runtime].repo "${repo}" was accepted`);

  for (const repo of [
    "alexandrapaiz/epitome",           // this company's own
    "acme/roster",
    "a/b",
    "acme-co/my_roster.v2",
    `${"a".repeat(39)}/${"r".repeat(100)}`,
    "99designs/aws-vault",             // a real repo whose owner starts with a digit
  ]) assert.deepEqual(refused(repo), [], `[runtime].repo "${repo}" is a real repository and was refused`);
});

test("the repo refusal names the half that is wrong", () => {
  const one = (repo) => validateManifest(seat("pm", { runtime: { repo } }), { baseDir: "/nonexistent" })
    .find((e) => e.startsWith("[runtime].repo"));
  assert.match(one("acme/roster.git"), /\.git/);
  assert.match(one("acme.co/roster"), /owner/);
  assert.match(one("acme/ros ter"), /name/);
  assert.match(one("github.com/acme/roster"), /owner\/name/);
});

// --- the manifest addition -------------------------------------------------

const errorsFor = (over) => validateManifest({ ...seat("pm", over) }, { baseDir: "/nonexistent" });

test("[runtime].slack_webhook_env accepts a NAME that is also listed in env", () => {
  const errs = errorsFor({ runtime: { slack_webhook_env: "SLACK_WEBHOOK_URL_EPITOME", env: ["SLACK_WEBHOOK_URL_EPITOME"] } });
  assert.deepEqual(errs, [], errs.join("\n"));
});

test("[runtime].slack_webhook_env refuses a URL, naming the rule and the fix", () => {
  const errs = errorsFor({ runtime: { slack_webhook_env: "https://hooks.slack.com/services/x", env: [] } });
  assert.equal(errs.length, 1);
  assert.equal(errs[0], `[runtime].slack_webhook_env "https://hooks.slack.com/services/x" must be the NAME of an environment variable (letters, digits, underscore) — the webhook URL itself never appears in the manifest. Fix: slack_webhook_env = "PM_SLACK_WEBHOOK", list that same name under [runtime].env, and set its value as a secret.`);
});

test("[runtime].slack_webhook_env must also be listed under [runtime].env", () => {
  const errs = errorsFor({ runtime: { slack_webhook_env: "SLACK_WEBHOOK_URL_URSA", env: ["GH_TOKEN"] } });
  assert.equal(errs.length, 1);
  assert.equal(errs[0], `[runtime].slack_webhook_env names "SLACK_WEBHOOK_URL_URSA", so "SLACK_WEBHOOK_URL_URSA" must also be listed in [runtime].env — the runtime injects only the names the manifest lists, so an unlisted webhook can never resolve to a value. Fix: add "SLACK_WEBHOOK_URL_URSA" to [runtime].env.`);
});

test("a manifest with no slack_webhook_env is unchanged: spec v0.1 stays compatible", () => {
  assert.deepEqual(errorsFor({ runtime: { env: ["GH_TOKEN"] } }), []);
});

test("webhookName routes per agent, falls back to #hq, and honours opting out", () => {
  assert.equal(webhookName(seat("a", { runtime: { env: ["SLACK_WEBHOOK_URL"] } })), "SLACK_WEBHOOK_URL");
  assert.equal(webhookName(seat("b", { runtime: { slack_webhook_env: "SLACK_WEBHOOK_URL_URSA", env: ["SLACK_WEBHOOK_URL_URSA"] } })), "SLACK_WEBHOOK_URL_URSA");
  assert.equal(webhookName(seat("c", { runtime: { env: [] } })), null);
  assert.equal(webhookName(seat("d", { runtime: { slack_webhook_env: "NOT_LISTED", env: [] } })), null);
});

// --- the clone-path guard --------------------------------------------------
// A clone path reaches `cleanup` from a workflow input, and a workflow input is
// not a trusted source.

test("isCloneDir accepts this agent's clone and refuses everything else", () => {
  assert.equal(isCloneDir("pm", `${cloneDirPrefix("pm")}Xy9abc`), true);
  assert.equal(isCloneDir("pm", cloneDirPrefix("pm")), false, "the bare prefix is not a clone");
  assert.equal(isCloneDir("pm", `${cloneDirPrefix("okr")}Xy9abc`), false, "another agent's clone");
  assert.equal(isCloneDir("pm", `${cloneDirPrefix("pm")}Xy9/../../etc`), false, "no escaping upward");
  assert.equal(isCloneDir("pm", join(tmpdir(), "epito-pm-Xy9", "nested")), false, "a clone is one level deep");
  assert.equal(isCloneDir("pm", "/"), false);
  assert.equal(isCloneDir("pm", ""), false);
  assert.equal(isCloneDir("pm", undefined), false);
});

// --- ids ------------------------------------------------------------------

test("a workflow id names the seat it belongs to, including a schedule's stamped id", () => {
  assert.equal(seatOfWorkflowId(runId("engineer")), "engineer");
  assert.equal(seatOfWorkflowId("run:engineer-2026-09-27T06:00:00Z"), "engineer");
  assert.equal(seatOfWorkflowId("run:pm:message:3"), "pm");
  assert.equal(seatOfWorkflowId(windowId("okr")), "okr");
  assert.equal(seatOfWorkflowId("something-else"), null);
});


// --- identity: the ceiling ------------------------------------------------
// Spec rule 2 says scopes are the ceiling, and the mint is the one place that
// is enforced, so these are the tests that hold the rule up.

test("permissionsFor maps the three v0.1 scopes and nothing else", () => {
  assert.deepEqual(permissionsFor(["github:contents"]), { contents: "write" });
  assert.deepEqual(permissionsFor(["github:contents", "github:pull_requests"]),
    { contents: "write", pull_requests: "write" });
  assert.deepEqual(permissionsFor(["github:issues"]), { issues: "write" });
  // Every key the map can emit, so a new scope cannot widen a token silently.
  const emitted = new Set(Object.values(SCOPE_MAP).flatMap((p) => Object.keys(p)));
  assert.deepEqual([...emitted].sort(), ["contents", "issues", "pull_requests"]);
});

test("an unmapped scope refuses the mint, names the scope and offers the fix", () => {
  assert.throws(() => permissionsFor(["github:contents", "github:packages"]), (e) => {
    assert.match(e.message, /"github:packages"/, "names the offending scope");
    assert.match(e.message, /Fix:/, "offers a fix");
    assert.doesNotMatch(e.message, /undefined|\[object/, "product voice, not a stack");
    return true;
  });
});

test("no mintable scope refuses rather than asking GitHub for everything", () => {
  // GitHub reads an empty `permissions` as "all this installation has", which
  // is the exact inverse of the rule, so this path must fail closed.
  assert.throws(() => permissionsFor([]), /scopes are the ceiling/);
});

test("appJwt signs RS256, under GitHub's 10-minute ceiling, backdated for skew", () => {
  const { privateKey, publicKey } = generateKeyPairSync("rsa", { modulusLength: 2048 });
  const pem = privateKey.export({ type: "pkcs1", format: "pem" });
  const now = 1_800_000_000;
  const jwt = appJwt("123456", pem, now);
  const [h, p, sig] = jwt.split(".");
  const un = (x) => JSON.parse(Buffer.from(x.replace(/-/g, "+").replace(/_/g, "/"), "base64").toString());
  assert.equal(un(h).alg, "RS256");
  const claims = un(p);
  assert.equal(claims.iss, "123456");
  assert.equal(claims.iat, now - 60, "backdated 60s: GitHub rejects an iat ahead of its clock");
  assert.ok(claims.exp - claims.iat <= 600, "GitHub's maximum App JWT lifetime is 10 minutes");
  const v = createVerify("RSA-SHA256");
  v.update(`${h}.${p}`);
  assert.ok(v.verify(publicKey.export({ type: "spki", format: "pem" }),
    Buffer.from(sig.replace(/-/g, "+").replace(/_/g, "/"), "base64")), "signature verifies");
});

test("appJwt refuses a key that is not an RSA PEM, in the product's voice", () => {
  assert.throws(() => appJwt("1", "not a pem"), /not a readable PEM/);
  const { privateKey } = generateKeyPairSync("ed25519");
  assert.throws(() => appJwt("1", privateKey.export({ type: "pkcs8", format: "pem" })),
    /a GitHub App signs with RSA/);
});

test("one agent, one App key: the env names are per agent and slug-safe", () => {
  assert.deepEqual(envNames("pm"), {
    id: "EPITO_APP_ID_PM", key: "EPITO_APP_KEY_PM",
    keyFile: "EPITO_APP_KEY_FILE_PM", installation: "EPITO_INSTALLATION_ID_PM",
  });
  assert.equal(envNames("run-reports").key, "EPITO_APP_KEY_RUN_REPORTS");
});

test("a key can be a .pem on disk, which is what a systemd EnvironmentFile needs", () => {
  const { privateKey } = generateKeyPairSync("rsa", { modulusLength: 2048 });
  const pem = privateKey.export({ type: "pkcs1", format: "pem" }).toString();
  const dir = tmpDir();
  const keyPath = join(dir, "pm.pem");
  writeFileSync(keyPath, pem, { mode: 0o600 });
  const p = loadPrincipal("pm", { env: { EPITO_APP_ID_PM: "7", EPITO_APP_KEY_FILE_PM: keyPath }, dir });
  assert.equal(p.privateKey, pem);
  assert.equal(p.source, "$EPITO_APP_ID_PM/$EPITO_APP_KEY_FILE_PM", "the audit line says where the key came from");
  // A key file that is named and missing is a misconfiguration, not a reason
  // to fall through to somebody else's credential.
  assert.throws(() => loadPrincipal("pm", { env: { EPITO_APP_ID_PM: "7", EPITO_APP_KEY_FILE_PM: join(dir, "gone.pem") }, dir }),
    (e) => {
      assert.match(e.message, /cannot read/);
      assert.match(e.message, /Fix:/);
      return true;
    });
});

test("loadPrincipal reads a PEM whose newlines arrived escaped, and is null with no App", () => {
  const { privateKey } = generateKeyPairSync("rsa", { modulusLength: 2048 });
  const pem = privateKey.export({ type: "pkcs1", format: "pem" }).toString();
  const env = { EPITO_APP_ID_PM: 99, EPITO_APP_KEY_PM: pem.replace(/\n/g, "\\n") };
  const p = loadPrincipal("pm", { env, dir: tmpDir() });
  assert.equal(p.appId, "99", "an App id from the environment is a string");
  assert.equal(p.privateKey, pem, "a single-line PEM is unescaped before use");
  assert.equal(p.installationId, null, "discovered from [runtime].repo when unnamed");
  assert.equal(loadPrincipal("okr", { env, dir: "." }), null, "no App is not an error here");
});

// --- who a seat acts as on this box (src/lib/acts.js) --------------------
// The question `epito doctor` could not answer until now: not "would a run
// start" but "and whose name would the pull request open under". Every case
// below is read through the RUN path's own loadPrincipal, which is the point —
// a preflight that keeps its own copy of the precedence would eventually
// predict a seat the runtime does not run.

const rsaPem = () => generateKeyPairSync("rsa", { modulusLength: 2048 }).privateKey.export({ type: "pkcs1", format: "pem" }).toString();

test("acts as itself: an App id and a key this box can read and sign with", () => {
  const dir = tmpDir();
  const pem = rsaPem();
  const keyPath = join(dir, "pm.pem");
  writeFileSync(keyPath, pem, { mode: 0o600 });
  const row = actsAs("pm", seat("pm"), { env: { EPITO_APP_ID_PM: "123456", EPITO_APP_KEY_FILE_PM: keyPath }, dir });
  assert.equal(row.state, OWN);
  assert.match(row.says, /its own GitHub App: id 123456/);
  assert.match(row.says, /\$EPITO_APP_ID_PM\/\$EPITO_APP_KEY_FILE_PM/, "and where the key came from");
  assert.equal(row.appId, "123456");
  assert.ok(!row.says.includes(pem.split("\n")[1]), "never a byte of the key itself");
});

test("an App whose mint cannot start is a refusal, because the mint is step one of the run", () => {
  const dir = tmpDir();
  // A PEM mangled on its way into an EnvironmentFile is the ordinary case: the
  // file has no multi-line values, so the escaping is done by hand.
  const mangled = actsAs("pm", seat("pm"), { env: { EPITO_APP_ID_PM: "1", EPITO_APP_KEY_PM: "-----BEGIN RSA PRIVATE KEY-----\ntruncated\n" }, dir });
  assert.equal(mangled.state, REFUSED);
  assert.match(mangled.says, /an App whose mint cannot start/);
  assert.match(mangled.says, /not a readable PEM/);
  assert.match(mangled.says, /Fix:/);

  // A scope v0.2 cannot mint. `epito doctor` calls this a report for a seat
  // with no App — a run never mints, so a run never cares — and it is the
  // opposite for this seat: the mint IS the run's first step.
  const scoped = actsAs("pm", seat("pm", {}), { env: { EPITO_APP_ID_PM: "1", EPITO_APP_KEY_PM: rsaPem() }, dir });
  assert.equal(scoped.state, OWN, "github:contents is mintable");
  const unmintable = { ...seat("pm"), identity: { scopes: ["github:packages"] } };
  const row = actsAs("pm", unmintable, { env: { EPITO_APP_ID_PM: "1", EPITO_APP_KEY_PM: rsaPem() }, dir });
  assert.equal(row.state, REFUSED);
  assert.match(row.says, /"github:packages"/);

  // An App and nothing to scope the token to.
  const noRepo = { ...seat("pm"), runtime: { model: "claude-sonnet-5", entry: "prompts/pm.md" } };
  const r2 = actsAs("pm", noRepo, { env: { EPITO_APP_ID_PM: "1", EPITO_APP_KEY_PM: rsaPem() }, dir });
  assert.equal(r2.state, REFUSED);
  assert.match(r2.says, /\[runtime\]\.repo/);
});

test("half an identity is loud, because the runtime reads it as none", () => {
  const dir = tmpDir();
  // An App id and no key: loadPrincipal returns null, the seat falls back to
  // the box's shared credential, and nothing ever said so.
  const idOnly = actsAs("pm", seat("pm"), { env: { EPITO_APP_ID_PM: "123456" }, dir });
  assert.equal(idOnly.state, HALF);
  assert.match(idOnly.says, /half an identity/);
  assert.match(idOnly.says, /\$EPITO_APP_KEY_FILE_PM/);
  // The fallback is whatever else the box gives this seat, and for a manifest
  // that names no GitHub credential that is nothing at all — the same
  // precision docs/deploy/README.md needed this pass.
  assert.match(idOnly.fix, /falls back to whatever else this box gives it — nothing/);
  const sharer = seat("pm", { runtime: { env: ["GH_TOKEN"] } });
  assert.match(actsAs("pm", sharer, { env: { EPITO_APP_ID_PM: "1", GH_TOKEN: "t" }, dir }).fix,
    /\$GH_TOKEN, a person's credential/, "and a person's credential where the manifest names one");

  // A key and no id.
  const keyOnly = actsAs("pm", seat("pm"), { env: { EPITO_APP_KEY_PM: rsaPem() }, dir });
  assert.equal(keyOnly.state, HALF);
  assert.match(keyOnly.says, /\$EPITO_APP_ID_PM is not/);

  // A line somebody half-filled in. Same third state `epito env` names, same
  // answer: the box HAS this one and has it wrong.
  const empty = actsAs("pm", seat("pm"), { env: { EPITO_APP_ID_PM: "", EPITO_APP_KEY_FILE_PM: "" }, dir });
  assert.equal(empty.state, HALF);
  assert.match(empty.says, /set here and set to nothing/);
});

test("half an identity in the file store names both paths it looked at", () => {
  const dir = tmpDir();
  mkdirSync(join(dir, ".epito/keys"), { recursive: true });
  writeFileSync(join(dir, ".epito/principals.json"), JSON.stringify([{ agent: "pm", externalId: "9" }]));
  const row = actsAs("pm", seat("pm"), { env: {}, dir });
  assert.equal(row.state, HALF);
  assert.match(row.says, /principals\.json records an App for this seat/);
  assert.match(row.says, /keys\/pm\.pem/);

  // The other half: a key with no record of which App it is.
  const d2 = tmpDir();
  mkdirSync(join(d2, ".epito/keys"), { recursive: true });
  writeFileSync(join(d2, ".epito/keys/pm.pem"), rsaPem(), { mode: 0o600 });
  const r2 = actsAs("pm", seat("pm"), { env: {}, dir: d2 });
  assert.equal(r2.state, HALF);
  assert.match(r2.says, /does not exist/);
});

test("no App: a shared credential has an owner, and no credential at all is a different sentence", () => {
  const dir = tmpDir();
  const withToken = seat("pm", { runtime: { env: ["GH_TOKEN"] } });
  const shared = actsAs("pm", withToken, { env: { GH_TOKEN: "a-token-nobody-will-call" }, dir });
  assert.equal(shared.state, SHARED);
  assert.match(shared.says, /the owner of \$GH_TOKEN, a person/);
  assert.ok(!shared.says.includes("a-token-nobody-will-call"), "presence, never a value");
  assert.equal(shared.fix, null, "the fix is one line under the block, not one per seat");

  // Named and not held: `epito env` reports the absent name; this says what it
  // means for who the seat is.
  const absent = actsAs("pm", withToken, { env: {}, dir });
  assert.equal(absent.state, NONE);
  assert.match(absent.says, /not set here, so nothing reaches the run/);

  // Named nowhere. This is the state every seat in this company's own roster
  // is in: a run starts, and its `gh` has nothing to authenticate with.
  const none = actsAs("pm", seat("pm"), { env: { GH_TOKEN: "held-but-unnamed" }, dir });
  assert.equal(none.state, NONE);
  assert.match(none.says, /names neither GH_TOKEN nor GITHUB_TOKEN/);
  assert.match(IDENTITY_FIX, /EPITO_APP_ID_<SEAT>/, "the two names, with the rule for the suffix");
});

test("an installation id left empty is an id to discover, not an id of nothing", () => {
  // `EPITO_INSTALLATION_ID_PM=` in an EnvironmentFile holds the empty string.
  // Read as present, the mint POSTs to /app/installations//access_tokens and
  // GitHub answers 404 — which the run reports as an App installed nowhere,
  // naming the wrong fix for a line somebody half-filled in.
  const env = { EPITO_APP_ID_PM: "7", EPITO_APP_KEY_PM: rsaPem(), EPITO_INSTALLATION_ID_PM: "" };
  assert.equal(loadPrincipal("pm", { env, dir: tmpDir() }).installationId, null);
  const row = actsAs("pm", seat("pm"), { env, dir: tmpDir() });
  assert.equal(row.state, OWN, "and it is not half an identity: the pair is the id and the key");
  assert.match(row.says, /installation discovered from \[runtime\]\.repo/);
});

test("rosterActs: only a broken or half identity may reach the exit code", () => {
  const dir = tmpDir();
  const roster = new Map([
    ["pm", { manifest: seat("pm") }],
    ["okr", { manifest: seat("okr") }],
  ]);
  const clean = rosterActs(roster, { env: {}, dir });
  assert.equal(clean.refusals.length, 0, "no App is nobody's error");
  assert.equal(clean.none.length, 2);
  const broken = rosterActs(roster, { env: { EPITO_APP_ID_PM: "1" }, dir });
  assert.deepEqual(broken.refusals.map((r) => r.agent), ["pm"]);
});

// --- and the half that has to leave the box (rosterInstalled) ------------
// `own` proves the key here signs the JWT a mint starts with. It cannot prove
// the App is installed on the repository it would mint for, which is the most
// ordinary setup mistake there is — so these cases are the online half, with
// GitHub stood in for by `lookup`. Nothing below reaches the network.

// A box that holds an App for one seat, and the rows actsAs makes of it.
const ownRow = (name = "pm", over = {}, manifest = seat(name)) => {
  const dir = tmpDir();
  const keyPath = join(dir, `${name}.pem`);
  writeFileSync(keyPath, rsaPem(), { mode: 0o600 });
  const env = { [`EPITO_APP_ID_${name.toUpperCase()}`]: "123456", [`EPITO_APP_KEY_FILE_${name.toUpperCase()}`]: keyPath, ...(over.env ?? {}) };
  return { row: actsAs(name, manifest, { env, dir }), env, dir };
};
// What GitHub answers GET /repos/{repo}/installation with, as far as this
// matters: the id, and what the App was granted there.
const ghSays = (over = {}) => ({ id: 4242, permissions: { metadata: "read", contents: "write", pull_requests: "write", issues: "write" }, ...over });
// And what GET /app answers, reduced to what identity.js's `appAs` returns:
// the App's own name, and who owns it.
const appSays = (over = {}) => ({ slug: "asc-pm", login: "asc-pm[bot]", owner: "acme", ownerType: "User", ...over });

// Every case below goes through this and not through `rosterInstalled`
// directly, which is not a convenience. The real `describe` is identity.js's
// `appAs`, and that one calls api.github.com — so a case that forgot to inject
// it would still pass and quietly make a live request out of CI, which is the
// one thing no test here may do. The last case in this section is the guard
// that nothing in this file forgets.
const installed = (rows, opts = {}) => rosterInstalled(rows, { describe: async () => appSays(), ...opts });

test("installed: GitHub names the installation, and one request covers every seat on that App", async () => {
  const dir = tmpDir();
  const keyPath = join(dir, "key.pem");
  writeFileSync(keyPath, rsaPem(), { mode: 0o600 });
  const env = {
    EPITO_APP_ID_PM: "123456", EPITO_APP_KEY_FILE_PM: keyPath,
    EPITO_APP_ID_OKR: "123456", EPITO_APP_KEY_FILE_OKR: keyPath,
  };
  const rows = [actsAs("pm", seat("pm"), { env, dir }), actsAs("okr", seat("okr"), { env, dir })];
  assert.deepEqual(rows.map((r) => r.state), [OWN, OWN]);
  const asked = [];
  const lookup = async (jwt, repo) => { asked.push({ jwt, repo }); return ghSays(); };
  const out = await installed(rows, { env, dir, lookup });
  assert.equal(asked.length, 1, "two seats on one App and one repo are ONE request, not two");
  assert.match(asked[0].jwt, /^[\w-]+\.[\w-]+\.[\w-]+$/, "asked as the App, with a signed JWT");
  assert.equal(asked[0].repo, "acme/roster", "about the repo the manifest names");
  assert.deepEqual(out.map((o) => [o.agent, o.state]), [["pm", INSTALLED], ["okr", INSTALLED]]);
  assert.equal(out[0].installation, "4242");
  assert.match(out[0].says, /installed on acme\/roster as installation 4242/);
  assert.ok(!out[0].says.includes("—"), "no em dash: doctor appends '— covers a, b' to this line");
  assert.equal(out[0].fix, null);
});

test("installed: a seat with no App of its own is not asked about at all", async () => {
  const dir = tmpDir();
  const rows = [actsAs("pm", seat("pm"), { env: {}, dir }), actsAs("okr", seat("okr"), { env: { GH_TOKEN: "t" }, dir })];
  let calls = 0;
  const out = await installed(rows, { env: {}, dir, lookup: async () => { calls++; return ghSays(); } });
  assert.deepEqual(out, [], "no App is nothing to ask GitHub about");
  assert.equal(calls, 0, "and a roster of them spends no requests — this company's own, today");
});

test("mismatch: the id this box names is not the one GitHub has, so the mint 404s", async () => {
  const { row, env, dir } = ownRow("pm", { env: { EPITO_INSTALLATION_ID_PM: "9999" } });
  assert.equal(row.installation, "9999", "the mint uses the id the box names rather than discovering one");
  const [out] = await installed([row], { env, dir, lookup: async () => ghSays() });
  assert.equal(out.state, MISMATCH);
  assert.equal(out.declared, "9999");
  assert.equal(out.installation, "4242");
  assert.match(out.says, /installation 4242, while this box tells its runs to mint from 9999/);
  assert.match(out.fix, /\$EPITO_INSTALLATION_ID_PM/, "the fix names the thing an operator would edit");
  assert.match(out.fix, /correct it to 4242/);

  // The same id, right: not a refusal, and the sentence says whose id it is.
  const ok = ownRow("pm", { env: { EPITO_INSTALLATION_ID_PM: "4242" } });
  const [good] = await installed([ok.row], { env: ok.env, dir: ok.dir, lookup: async () => ghSays() });
  assert.equal(good.state, INSTALLED);
  assert.match(good.says, /the id this box names for it/);
});

test("ungranted: installed, and granted less there than [identity].scopes need", async () => {
  // The 422 the mint learns at 06:00, knowable now from the answer GitHub has
  // already given — no second request.
  const manifest = { ...seat("pm"), identity: { scopes: ["github:contents", "github:pull_requests"] } };
  const { row, env, dir } = ownRow("pm", {}, manifest);
  const lookup = async () => ghSays({ permissions: { metadata: "read", contents: "read" } });
  const [out] = await installed([row], { env, dir, lookup });
  assert.equal(out.state, UNGRANTED);
  assert.match(out.says, /contents is read and the manifest needs write/);
  assert.match(out.says, /pull_requests is not granted at all and the manifest needs write/);
  assert.match(out.fix, /grant the App contents:write, pull_requests:write/);
  assert.match(out.fix, /scopes are the ceiling/);
});

test("grantGap says nothing rather than guessing when GitHub described no permissions", () => {
  assert.deepEqual(grantGap(["github:contents"], null), [], "an older answer is not evidence of a shortfall");
  assert.deepEqual(grantGap(["github:contents"], { contents: "write" }), []);
  assert.deepEqual(grantGap(["github:contents"], { contents: "admin" }), [], "admin outranks write");
  assert.deepEqual(grantGap(["github:contents"], { contents: "read" }),
    [{ permission: "contents", need: "write", granted: "read" }]);
  assert.deepEqual(grantGap(["github:contents"], { contents: "something-new" }),
    [{ permission: "contents", need: "write", granted: "something-new" }],
    "a level this CLI does not know ranks below everything: report a mint you are unsure of, never tick it");
  assert.deepEqual(grantGap(["github:packages"], { contents: "write" }), [],
    "an unmintable scope is the OFFLINE half's refusal, and this one does not speak for it");
});

test("GitHub's two permanent refusals arrive as its own sentences, with the status for a machine", async () => {
  const { row, env, dir } = ownRow();
  const notThere = Object.assign(new Error("this agent's GitHub App is not installed on acme/roster — an App with no installation there can mint nothing, however valid its key. Fix: install the App on acme/roster (its owner does this once), then mint again."), { permanent: true, status: 404 });
  const [a] = await installed([row], { env, dir, lookup: async () => { throw notThere; } });
  assert.equal(a.state, GH_REFUSED);
  assert.equal(a.status, 404, "404 and 401 are two different fixes, and --json reads which off this");
  assert.match(a.says, /is not installed on acme\/roster/, "the run path's own words, not a paraphrase");
  assert.match(a.says, /Fix: install the App/);

  const badPair = Object.assign(new Error("GitHub rejected this agent's App credentials (401)."), { permanent: true, status: 401 });
  const [b] = await installed([row], { env, dir, lookup: async () => { throw badPair; } });
  assert.equal(b.state, GH_REFUSED);
  assert.equal(b.status, 401);
});

test("a GitHub this box cannot reach is a report, because the run path retries that one", async () => {
  // The line this file does not draw itself: identity.js marks a mint failure
  // `permanent` because the clone activity retries, and this reads that flag
  // rather than re-deciding by status code.
  const { row, env, dir } = ownRow();
  const blip = new Error("could not reach GitHub at https://api.github.com/repos/acme/roster/installation (fetch failed). Fix: check this machine's network.");
  const [out] = await installed([row], { env, dir, lookup: async () => { throw blip; } });
  assert.equal(out.state, UNREACHABLE);
  assert.match(out.says, /could not reach GitHub/);
  assert.ok(!INSTALL_REFUSES.has(out.state), "and it never reaches the exit code");
});

test("a preflight does not wait on a half-open socket for the length of the kernel's patience", async () => {
  const { row, env, dir } = ownRow();
  const started = Date.now();
  const [out] = await installed([row], { env, dir, deadline: 40, lookup: () => new Promise(() => {}) });
  assert.equal(out.state, UNREACHABLE, "a deadline spent is not evidence against the App");
  assert.match(out.says, /did not answer within 0.04s/);
  assert.ok(Date.now() - started < 2000, "and it came back rather than hanging the operator's terminal");
});

// --- the App's own name, and the pages it makes reachable -----------------
// `GET /app` is the second free request per App, and what it buys is two
// sentences nothing offline can write: the page that performs the fix a
// refusal names, and the login a pull request actually opens as.

test("a page is built from the API root the box was pointed at, because a link is not an API call", () => {
  assert.equal(webRoot("https://api.github.com"), "https://github.com");
  assert.equal(installUrl("asc-pm", "https://api.github.com"), "https://github.com/apps/asc-pm/installations/new");
  // GitHub Enterprise: the API root is the host's web root plus /api/v3, so
  // the pages are up one level and NOT on github.com, where this App does
  // not exist at all.
  assert.equal(webRoot("https://ghe.acme.test/api/v3"), "https://ghe.acme.test");
  assert.equal(installUrl("asc-pm", "https://ghe.acme.test/api/v3/"), "https://ghe.acme.test/apps/asc-pm/installations/new");
  // Anything else is taken at its word rather than rewritten into github.com:
  // a box pointed somewhere gets pages there, which is the only answer that is
  // not a lie about where its own App lives.
  assert.equal(webRoot("http://127.0.0.1:47474"), "http://127.0.0.1:47474");
  assert.equal(webRoot("not a url"), "https://github.com", "an unreadable root falls back rather than throwing inside a report");
});

test("an App's settings page is under whoever owns it, and the path differs by owner type", () => {
  const app = { slug: "asc-pm", owner: "acme", ownerType: "User" };
  assert.equal(appSettingsUrl(app, "permissions", "https://api.github.com"),
    "https://github.com/settings/apps/asc-pm/permissions");
  assert.equal(appSettingsUrl({ ...app, ownerType: "Organization" }, "permissions", "https://api.github.com"),
    "https://github.com/organizations/acme/settings/apps/asc-pm/permissions",
    "an org-owned App is not reachable under /settings/apps at all, which is why the owner is read and not only the slug");
  assert.equal(appSettingsUrl({ slug: "asc-pm", owner: null, ownerType: "Organization" }, "permissions", "https://api.github.com"),
    "https://github.com/settings/apps/asc-pm/permissions",
    "an owner type with no login to put in the path falls back to the form that at least exists");
});

test("the ✓ row says the login a pull request opens as, and it is the App's and not the seat's", async () => {
  const { row, env, dir } = ownRow("pm");
  const [out] = await installed([row], { env, dir, lookup: async () => ghSays() });
  assert.equal(out.state, INSTALLED);
  assert.equal(out.login, "asc-pm[bot]");
  assert.equal(out.slug, "asc-pm");
  assert.ok(out.under.some((u) => u.includes("asc-pm[bot]")), "printed, not merely carried in --json");
  assert.ok(!/\bas pm\[bot\]/.test(out.under.join(" ")), "and never dressed up as the seat's name");
  // The whole point of reading it: this seat is called `pm` and opens its
  // pull requests as `asc-pm[bot]`, because an App name is unique across
  // GitHub and the plain one was taken.
  assert.notEqual(out.login, "pm[bot]");
});

test("the 404 refusal hands over the page that fixes it, and the 401 has none to hand over", async () => {
  const { row, env, dir } = ownRow();
  const notThere = Object.assign(new Error("this agent's GitHub App is not installed on acme/roster. Fix: install the App on acme/roster (its owner does this once), then mint again."), { permanent: true, status: 404 });
  const [a] = await installed([row], { env, dir, lookup: async () => { throw notThere; } });
  assert.equal(a.state, GH_REFUSED);
  assert.deepEqual(a.under, ["The page that does it: https://github.com/apps/asc-pm/installations/new"]);
  assert.ok(!a.fix, "the fix is identity.js's own sentence inside `says`; this is the page, not a second fix");

  // A 401 is an App id and a key that are not from the same App, and the same
  // credentials cannot read GET /app either — so there is no slug to build a
  // page out of, and asking would spend a request to be refused twice.
  const badPair = Object.assign(new Error("GitHub rejected this agent's App credentials (401)."), { permanent: true, status: 401 });
  let described = 0;
  const [b] = await installed([row], { env, dir, describe: async () => { described++; return appSays(); }, lookup: async () => { throw badPair; } });
  assert.equal(b.state, GH_REFUSED);
  assert.deepEqual(b.under, []);
  assert.equal(b.login, null, "and never a guessed login");
  assert.equal(described, 0, "nor a second request to hear the same no");
});

test("a GitHub with no route from here is not asked who the App is either", async () => {
  const { row, env, dir } = ownRow();
  let described = 0;
  const [out] = await installed([row], {
    env, dir,
    describe: async () => { described++; return appSays(); },
    lookup: async () => { throw new Error("could not reach GitHub at https://api.github.com/repos/acme/roster/installation (fetch failed)."); },
  });
  assert.equal(out.state, UNREACHABLE);
  assert.equal(described, 0, "one unreachable GitHub is unreachable for both calls");
  assert.equal(out.login, null);
});

test("an App GitHub will not describe loses a link and nothing else", async () => {
  // The trade mintToken already makes about the commit identity: an avatar is
  // not worth a refusal. A sentence that was complete before this existed is
  // complete after it fails.
  const { row, env, dir } = ownRow();
  const [out] = await installed([row], { env, dir, describe: async () => { throw new Error("GitHub refused GET /app with 403"); }, lookup: async () => ghSays() });
  assert.equal(out.state, INSTALLED, "the verdict is the installation lookup's, never this one's");
  assert.equal(out.login, null);
  assert.deepEqual(out.under, []);
  assert.match(out.says, /installed on acme\/roster as installation 4242/);
});

test("the grant shortfall names the permissions page, under the owner that actually has it", async () => {
  const manifest = { ...seat("pm"), identity: { scopes: ["github:contents"] } };
  const { row, env, dir } = ownRow("pm", {}, manifest);
  const thin = async () => ghSays({ permissions: { metadata: "read", contents: "read" } });
  const [user] = await installed([row], { env, dir, lookup: thin });
  assert.equal(user.state, UNGRANTED);
  assert.deepEqual(user.under, ["The page that does it: https://github.com/settings/apps/asc-pm/permissions"]);

  const [org] = await installed([row], { env, dir, lookup: thin, describe: async () => appSays({ ownerType: "Organization" }) });
  assert.deepEqual(org.under, ["The page that does it: https://github.com/organizations/acme/settings/apps/asc-pm/permissions"]);
});

test("two seats on one App ask who it is once, and a mismatch is still told nothing to click", async () => {
  const dir = tmpDir();
  const keyPath = join(dir, "key.pem");
  writeFileSync(keyPath, rsaPem(), { mode: 0o600 });
  const env = {
    EPITO_APP_ID_PM: "123456", EPITO_APP_KEY_FILE_PM: keyPath,
    EPITO_APP_ID_OKR: "123456", EPITO_APP_KEY_FILE_OKR: keyPath,
    EPITO_INSTALLATION_ID_OKR: "9999",
  };
  const rows = [actsAs("pm", seat("pm"), { env, dir }), actsAs("okr", seat("okr"), { env, dir })];
  let described = 0;
  const out = await installed(rows, { env, dir, describe: async () => { described++; return appSays(); }, lookup: async () => ghSays() });
  assert.equal(described, 1, "one App and one repo is one question about who that App is");
  assert.deepEqual(out.map((o) => o.state), [INSTALLED, MISMATCH]);
  assert.deepEqual(out[1].under, [], "a mismatch is fixed by editing this box, so there is no page to open");
  assert.match(out[1].fix, /\$EPITO_INSTALLATION_ID_OKR/);
});

test("no case in this file calls rosterInstalled by hand, because the real describe() is a live request", () => {
  // The structural half of the wrapper's comment above. `appAs` reaches
  // api.github.com; a case that passed `lookup` and forgot `describe` would
  // go green while making a real call out of CI, and nothing in its output
  // would say so. Built at runtime so this assertion is not its own match.
  const needle = "rosterInstalled" + "(";
  const body = readFileSync(new URL("./unit.mjs", import.meta.url), "utf8");
  const uses = body.split(needle).length - 1;
  assert.equal(uses, 1, `only the wrapper may call ${needle}...) — found ${uses} call sites`);
});

test("the preflight and the run read one precedence: only acts.js asks who a seat is", () => {
  // The same guard src/lib/runenv.js has for the environment allowlist, for
  // the same reason: two readers of loadPrincipal drift, and the one that
  // drifts is the one that stops predicting the run.
  for (const f of ["src/doctor.js", "src/env.js"]) {
    const src = readFileSync(new URL(`../${f}`, import.meta.url), "utf8");
    assert.ok(!/from "\.\/lib\/identity\.js"/.test(src) && !/from "\.\.\/lib\/identity\.js"/.test(src),
      `${f} must read identity through src/lib/acts.js, not reach into identity.js itself`);
  }
});

// --- identity: the token reaches the child and not the log ----------------

test("a minted token is injected into the run and scrubbed out of its log", async () => {
  const dir = tmpDir();
  const cwd = process.cwd();
  process.chdir(dir);                              // .epito/logs/<agent>/ is relative
  const work = mkdtempSync(cloneDirPrefix("pm"));
  try {
    const token = "ghs_UNITTESTTOKEN00000000000000000000";
    const agent = {
      agent: { name: "pm" },
      runtime: { model: "m", entry: "e", repo: "acme/roster", env: ["GH_TOKEN", "EPITO_STUB_ECHO_TOKEN", "EPITO_STUB_DIR"] },
    };
    // The shared credential a box has today, which the agent's own must beat.
    process.env.GH_TOKEN = "the-operators-shared-token";
    process.env.EPITO_STUB_ECHO_TOKEN = "1";
    process.env.EPITO_STUB_DIR = join(dir, "stub");
    const r = await executeAgent({
      agent, trigger: "cron", runId: "r1", workDir: work, timeoutMs: 30_000, log: () => {},
      executor: new URL("./stub-executor.mjs", import.meta.url).pathname,
      inject: { GH_TOKEN: token, GITHUB_TOKEN: token }, redact: [token],
    });
    assert.equal(r.exit, 0);
    const logged = readFileSync(r.log, "utf8");
    // The stub printed the credential it was handed, the way a `gh` error does.
    assert.match(logged, /GH_TOKEN=\[redacted: this run's token\]/, "the child DID get the minted token");
    assert.doesNotMatch(logged, /ghs_UNITTESTTOKEN/, "and it is written nowhere, including this log");
    assert.doesNotMatch(logged, /the-operators-shared-token/, "the shared token never reached the child");
    assert.match(logged, /GH_TOKEN from \[runtime\]\.env is overridden/, "the log names which identity won");
  } finally {
    process.chdir(cwd);
    // A clone this test made is a clone this test removes: smoke-temporal.sh
    // asserts that no epito-<agent>-* directory survives a run, and a unit
    // test that litters $TMPDIR fails it from the outside.
    rmSync(work, { recursive: true, force: true });
    delete process.env.GH_TOKEN; delete process.env.EPITO_STUB_ECHO_TOKEN; delete process.env.EPITO_STUB_DIR;
  }
});

test("with no App, the run is exactly what it was before the identity slice", async () => {
  const dir = tmpDir();
  const cwd = process.cwd();
  process.chdir(dir);
  const work = mkdtempSync(cloneDirPrefix("okr"));
  try {
    const agent = {
      agent: { name: "okr" },
      runtime: { model: "m", entry: "e", repo: "acme/roster", env: ["GH_TOKEN", "EPITO_STUB_ECHO_TOKEN", "EPITO_STUB_DIR"] },
    };
    process.env.GH_TOKEN = "the-operators-shared-token";
    process.env.EPITO_STUB_ECHO_TOKEN = "1";
    process.env.EPITO_STUB_DIR = join(dir, "stub");
    const r = await executeAgent({
      agent, trigger: "cron", runId: "r1", workDir: work, timeoutMs: 30_000, log: () => {},
      executor: new URL("./stub-executor.mjs", import.meta.url).pathname,
    });
    assert.equal(r.exit, 0);
    const logged = readFileSync(r.log, "utf8");
    assert.match(logged, /GH_TOKEN=the-operators-shared-token/, "no principal: the seat runs on the secrets its manifest names");
    assert.doesNotMatch(logged, /overridden/, "and nothing claims an identity it does not have");
  } finally {
    process.chdir(cwd);
    // A clone this test made is a clone this test removes: smoke-temporal.sh
    // asserts that no epito-<agent>-* directory survives a run, and a unit
    // test that litters $TMPDIR fails it from the outside.
    rmSync(work, { recursive: true, force: true });
    delete process.env.GH_TOKEN; delete process.env.EPITO_STUB_ECHO_TOKEN; delete process.env.EPITO_STUB_DIR;
  }
});

// --- the clone's own credential -------------------------------------------
// gitEnvFor is the whole of "the clone runs as the agent", so its three rules
// are asserted on the value itself, and then proved end to end against a
// server that refuses anything else.

test("gitEnvFor: the token is in the environment and nowhere else", () => {
  const token = "ghs_CLONETOKEN000000000000000000000000";
  const env = gitEnvFor(token, { PATH: "/usr/bin" });
  assert.equal(env[GIT_TOKEN_ENV], token, "the credential arrives by environment");
  const configured = Object.entries(env).filter(([k]) => /^GIT_CONFIG_(KEY|VALUE)_/.test(k));
  for (const [k, v] of configured) {
    assert.doesNotMatch(String(v), /ghs_CLONETOKEN/, `${k} must not carry the credential: git config is read by anyone who can read the repo`);
  }
});

test("gitEnvFor: the box's own credential helper is reset before ours is added", () => {
  const env = gitEnvFor("ghs_CLONETOKEN000000000000000000000000", {});
  assert.equal(env.GIT_CONFIG_COUNT, "2");
  assert.equal(env.GIT_CONFIG_KEY_0, "credential.helper");
  assert.equal(env.GIT_CONFIG_VALUE_0, "", "an empty helper clears every helper configured before it — including provision-host.sh's system-wide `gh auth git-credential`");
  assert.equal(env.GIT_CONFIG_KEY_1, "credential.helper");
  assert.match(env.GIT_CONFIG_VALUE_1, new RegExp(`\\$${GIT_TOKEN_ENV}`), "ours reads the token from the environment at call time");
});

test("gitEnvFor: GIT_CONFIG_* the operator already set survives", () => {
  const base = { GIT_CONFIG_COUNT: "1", GIT_CONFIG_KEY_0: "url.file:///tmp/.insteadOf", GIT_CONFIG_VALUE_0: "https://github.com/" };
  const env = gitEnvFor("ghs_CLONETOKEN000000000000000000000000", base);
  assert.equal(env.GIT_CONFIG_COUNT, "3", "appended at the next free index, not overwritten from zero");
  assert.equal(env.GIT_CONFIG_KEY_0, "url.file:///tmp/.insteadOf", "the operator's rule is untouched");
  assert.equal(env.GIT_CONFIG_KEY_1, "credential.helper");
  assert.equal(env.GIT_CONFIG_KEY_2, "credential.helper");
});

test("gitEnvFor: a git epito runs never blocks on a prompt, identity or not", () => {
  assert.equal(gitEnvFor(null, {}).GIT_TERMINAL_PROMPT, "0");
  assert.equal(gitEnvFor("ghs_CLONETOKEN000000000000000000000000", {}).GIT_TERMINAL_PROMPT, "0");
});

// The end-to-end proof. A real `git clone` over http against a server that
// answers 401 to every credential but the agent's, with a global git config
// that offers the *operator's* token — which is the box's situation exactly.
// If the reset in rule 2 did not work, this test hangs or fails; that is the
// point of running it rather than reading the config back.
test("the clone authenticates as the agent, over the box's own helper", async (t) => {
  const AGENT_TOKEN = "ghs_AGENTOWNTOKEN0000000000000000000000";
  const HUMAN_TOKEN = "gho_THEOPERATORSSHAREDTOKEN0000000000";
  const dir = mkdtempSync(join(tmpdir(), "epito-clonetest-"));
  const cwd = process.cwd();
  let server, work;
  try {
    // A bare repo with one commit, served as "acme/roster.git".
    const src = join(dir, "src"), bare = join(dir, "repos", "acme", "roster.git");
    mkdirSync(src, { recursive: true }); mkdirSync(join(dir, "repos", "acme"), { recursive: true });
    const git = (args, opts = {}) => new Promise((res, rej) => {
      const p = spawn("git", args, { stdio: "ignore", ...opts });
      p.on("close", (c) => (c === 0 ? res() : rej(new Error(`git ${args.join(" ")} exited ${c}`))));
    });
    await git(["init", "-q", "-b", "main", src]);
    writeFileSync(join(src, "charter.md"), "# a charter\n");
    await git(["-c", "user.email=t@t", "-c", "user.name=t", "add", "-A"], { cwd: src });
    await git(["-c", "user.email=t@t", "-c", "user.name=t", "commit", "-qm", "seed"], { cwd: src });
    await git(["clone", "-q", "--bare", src, bare]);
    await git(["-C", bare, "update-server-info"]);

    const httpLog = join(dir, "http.jsonl");
    writeFileSync(httpLog, "");
    server = spawn(process.execPath, [new URL("./git-http-stub.mjs", import.meta.url).pathname,
      "0", join(dir, "repos"), AGENT_TOKEN, httpLog], { stdio: ["ignore", "pipe", "inherit"] });
    const [line] = await once(server.stdout, "data");
    // The stub prints its port once it is listening; asking for 0 and reading
    // it back is how this test avoids racing another test for a fixed port.
    let port = /git-http-stub on (\d+)/.exec(String(line))?.[1];
    if (port === "0") port = null;
    t.diagnostic(`git-http-stub said: ${String(line).trim()}`);
    assert.ok(port, "the stub must report the port it bound");

    // The box, as provision-host.sh leaves it: a global credential helper
    // that hands out the operator's shared token for everything.
    const globalCfg = join(dir, "gitconfig");
    writeFileSync(globalCfg,
      `[credential]\n\thelper = "!f() { if [ \\"$1\\" = get ]; then echo username=x-access-token; echo password=${HUMAN_TOKEN}; fi; }; f"\n`);

    process.chdir(dir);                              // .epito/logs/<agent>/ is relative
    const agent = { agent: { name: "pm" }, runtime: { repo: "acme/roster", entry: "charter.md", model: "m" } };
    const base = {
      ...process.env,
      GIT_CONFIG_GLOBAL: globalCfg, GIT_CONFIG_SYSTEM: "/dev/null",
      // github.com is this test's own server, so nothing leaves the machine.
      GIT_CONFIG_COUNT: "1",
      GIT_CONFIG_KEY_0: `url.http://127.0.0.1:${port}/.insteadOf`,
      GIT_CONFIG_VALUE_0: "https://github.com/",
    };
    const saved = process.env;
    process.env = base;
    try {
      const out = await cloneAgentRepo({ agent, runId: "clone-1", token: AGENT_TOKEN, log: () => {} });
      work = out.workDir;
      assert.ok(existsSync(join(work, "charter.md")), "the clone succeeded, so the server accepted the credential it was offered");
    } finally { process.env = saved; }

    const seen = readFileSync(httpLog, "utf8").trim().split("\n").filter(Boolean).map(JSON.parse);
    const offered = seen.filter((r) => r.password !== null);
    assert.ok(offered.length > 0, "git offered a credential at all");
    for (const r of offered) {
      assert.equal(r.password, AGENT_TOKEN, `git offered ${r.password} on ${r.route} — the agent's own token is the only one it may offer`);
      assert.equal(r.user, "x-access-token");
    }
    assert.ok(seen.some((r) => r.ok), "at least one authorized request, or nothing was actually fetched");

    const logged = readFileSync(join(".epito", "logs", "pm", "clone-1.log"), "utf8");
    assert.doesNotMatch(logged, /ghs_AGENTOWNTOKEN/, "the run log holds no copy of the credential");
    assert.match(logged, /clone credential: this run's own minted token/, "the log says which credential the clone used");
  } finally {
    process.chdir(cwd);
    server?.kill();
    if (work) rmSync(work, { recursive: true, force: true });
    rmSync(dir, { recursive: true, force: true });
  }
});

test("with no token, the clone is exactly what it was: the machine's own git credentials", () => {
  const env = gitEnvFor(null, { GIT_CONFIG_COUNT: "1", GIT_CONFIG_KEY_0: "x.y", GIT_CONFIG_VALUE_0: "z" });
  assert.equal(env.GIT_CONFIG_COUNT, "1", "no helper is reset and none is added");
  assert.equal(env[GIT_TOKEN_ENV], undefined);
});

// --- the commit identity ---------------------------------------------------
// Both of these run against test/github-stub.mjs, because the claim is about
// which credential goes to which endpoint, and only a server can answer that.
// identity.js reads EPITO_GITHUB_API once at module load, so each case imports
// it under its own specifier to get a module with its own view of the world.

async function withGithubStub(mode, body) {
  const dir = mkdtempSync(join(tmpdir(), "epito-bot-"));
  const { privateKey, publicKey } = generateKeyPairSync("rsa", { modulusLength: 2048 });
  writeFileSync(join(dir, "app.pem"), privateKey.export({ type: "pkcs1", format: "pem" }));
  writeFileSync(join(dir, "app.pub.pem"), publicKey.export({ type: "spki", format: "pem" }));
  const httpLog = join(dir, "gh.jsonl");
  writeFileSync(httpLog, "");
  const stub = spawn(process.execPath, [new URL("./github-stub.mjs", import.meta.url).pathname,
    "0", join(dir, "app.pub.pem"), httpLog, mode], { stdio: ["ignore", "pipe", "inherit"] });
  try {
    const [line] = await once(stub.stdout, "data");
    const port = /github-stub on (\d+)/.exec(String(line))[1];
    return await body({ dir, port, httpLog, pem: readFileSync(join(dir, "app.pem"), "utf8") });
  } finally { stub.kill(); rmSync(dir, { recursive: true, force: true }); }
}

const botSeat = { agent: { name: "pm" }, identity: { scopes: ["github:contents"] }, runtime: { repo: "acme/roster" } };

test("the mint reads the App's bot user, and returns the address GitHub links commits by", async () => {
  await withGithubStub("ok", async ({ port, pem, httpLog }) => {
    process.env.EPITO_GITHUB_API = `http://127.0.0.1:${port}`;
    const { mintForRun } = await import("../src/lib/identity.js?case=bot-ok");
    const minted = await mintForRun({
      name: "pm", manifest: botSeat,
      env: { EPITO_APP_ID_PM: "1234", EPITO_APP_KEY_PM: pem },
    });
    assert.deepEqual(minted.meta.commit, {
      name: "epito-seat-1234[bot]",
      email: "99001+epito-seat-1234[bot]@users.noreply.github.com",
    }, "<bot user id>+<slug>[bot]@users.noreply.github.com is the only address that links a commit to the App");
    const seen = readFileSync(httpLog, "utf8").trim().split("\n").map(JSON.parse);
    const users = seen.find((r) => r.url.startsWith("/users/"));
    assert.equal(users.why, null, "GET /users must be asked as the installation — GitHub rejects an App JWT there");
  });
});

test("a bot lookup that fails degrades loudly; it does not lose the run", async () => {
  await withGithubStub("no-bot", async ({ port, pem }) => {
    process.env.EPITO_GITHUB_API = `http://127.0.0.1:${port}`;
    const { mintForRun } = await import("../src/lib/identity.js?case=no-bot");
    const said = [];
    const minted = await mintForRun({
      name: "pm", manifest: botSeat, log: (m) => said.push(m),
      env: { EPITO_APP_ID_PM: "1234", EPITO_APP_KEY_PM: pem },
    });
    assert.ok(minted.token, "the token is good: only the bot's name and id were unreadable");
    assert.equal(minted.meta.commit, null, "the audit records no commit address rather than a guessed one");
    assert.ok(said.some((m) => /could not read this App's bot identity/.test(m)), `the run says so: ${JSON.stringify(said)}`);
    assert.ok(said.some((m) => /agents\.epito\.me/.test(m)), "and names the address it fell back to");
  });
});

// --- the board ------------------------------------------------------------
// The board's whole contract is in two pure functions: what it will accept
// (boardEvent) and what it says once it has (foldBoard). Both are testable
// with no server, no engine and no file, which is why they are pure.
import { boardEvent, appendBoard, readBoard, foldBoard, renderBoard, KINDS } from "../src/lib/board.js";
import { parseFlags } from "../src/board.js";

test("the board has ONE shape: a field it does not know is refused by name", () => {
  const { error } = boardEvent({ agent: "pm", trigger: "cron", priority: "P1", epic: "identity" });
  assert.ok(error, "a run report may not invent a column");
  assert.match(error, /"priority", "epic"/, `both are named: ${error}`);
  assert.match(error, /it holds agent, trigger, runId/, "and the shape it does hold is in the message");
  assert.match(error, /the PM's call/, "with the fix: changing the shape is not a field a run invents");
});

test("the board holds runs and notes, and says so when asked for anything else", () => {
  const { error } = boardEvent({ kind: "view", agent: "pm" });
  assert.match(error, /it holds run and note entries/);
  assert.deepEqual(Object.keys(KINDS), ["run", "note"], "two kinds; a third is a spec change");
});

test("an entry names the agent it is about, and a note has words in it", () => {
  assert.match(boardEvent({ trigger: "cron" }).error, /names the agent it is about/);
  assert.match(boardEvent({ agent: "Not A Name" }).error, /\[a-z0-9-\]/);
  assert.match(boardEvent({ kind: "note", agent: "pm", text: "   " }).error, /an empty note puts nothing on the board/);
});

test("the writer stamps the time; a caller cannot backdate the board", () => {
  const { event } = boardEvent({ agent: "pm", ts: "1999-01-01T00:00:00.000Z" }, { now: new Date("2026-09-27T06:00:00.000Z") });
  assert.equal(event.ts, "2026-09-27T06:00:00.000Z");
  assert.equal(event.outcome, "ok", "a run with no outcome named ran fine; that is what silence means here");
});

test("turns and seconds are numbers, and a word where a number goes is refused", () => {
  assert.equal(boardEvent({ agent: "pm", turns: "6" }).event.turns, 6, "a CLI hands strings; the board stores numbers");
  assert.match(boardEvent({ agent: "pm", turns: "six" }).error, /"turns" is a number on the board/);
});

test("the fold collapses a run filed twice — `record` is a retried activity", () => {
  const e = (over) => boardEvent({ agent: "pm", trigger: "cron", runId: "run-pm-1", ...over }).event;
  const fold = foldBoard([e({}), e({}), e({ runId: "run-pm-2", outcome: "mint" })]);
  assert.equal(fold.duplicates, 1);
  assert.equal(fold.total, 2);
  assert.equal(fold.seats[0].runs, 2, "two runs, not three");
  assert.equal(fold.seats[0].failed, 1, "an outcome that is not ok is a failure on the board");
});

test("a half-written line is counted, never fatal: a crash mid-append leaves one", () => {
  const dir = mkdtempSync(join(tmpdir(), "epito-board-"));
  const path = join(dir, "board.jsonl");
  writeFileSync(path, `{"ts":"2026-09-27T06:00:00.000Z","kind":"run","agent":"pm","outcome":"ok"}\n{"ts":"2026-09-2\n`);
  const { events, unreadable } = readBoard({ path });
  assert.equal(events.length, 1);
  assert.equal(unreadable, 1);
  assert.match(renderBoard(foldBoard(events), { unreadable, path }), /1 line in .* could not be read as JSON/);
  rmSync(dir, { recursive: true, force: true });
});

test("an empty board says how a report gets onto it, not just that there is none", () => {
  const text = renderBoard(foldBoard([]), { path: ".epito/board.jsonl" });
  assert.match(text, /the board is empty/);
  assert.match(text, /epito report <name> --outcome ok --pr <url>/, "the fix is in the message");
});

test("a misspelled flag is refused by name, never silently ignored", () => {
  const { error } = parseFlags(["--outcome", "ok", "--pr-url", "x"], ["outcome", "pr"], "report");
  assert.match(error, /--pr-url/, `the option it refused is named: ${error}`);
  assert.match(error, /`epito report`/, "and so is the command that refused it");
  const { flags, rest } = parseFlags(["pm", "--outcome=mint", "--pr", "https://x/1", "--json"], ["outcome", "pr", "json"]);
  assert.deepEqual(rest, ["pm"]);
  assert.deepEqual(flags, { outcome: "mint", pr: "https://x/1", json: true }, "--flag=value, --flag value, and a bare --flag");
});

// --- options epito does not know (src/lib/flags.js) -----------------------
// The rule board.js already had, now every command's. The two assertions that
// matter are the last two: a dropped --dry-run is not a cosmetic bug, it is
// the real mint and the real App.
import { unknownOption, nearest } from "../src/lib/flags.js";

const VALIDATE = [{ name: "for-runtime", does: "make the readiness notes an error, not a note" }];

test("an unknown option is refused, and the near miss is named as one", () => {
  const e = unknownOption("validate", ["--for-runtimes"], VALIDATE);
  assert.ok(e, "--for-runtimes is not --for-runtime");
  assert.match(e, /`epito validate` has no --for-runtimes option/, e);
  assert.match(e, /Did you mean --for-runtime\?/, "the fix is the flag they meant");
  assert.match(e, /\`epito validate --for-runtime\`/, "spelled as a command they can run");
});

test("an option close to nothing gets the real list instead of a guess", () => {
  const e = unknownOption("validate", ["--wat"], VALIDATE);
  assert.doesNotMatch(e, /Did you mean/, `--wat is nobody's typo for --for-runtime: ${e}`);
  assert.match(e, /--for-runtime  make the readiness notes an error/, "so it says what the command does take");
  assert.equal(nearest("wat", ["for-runtime"]), null);
  assert.equal(nearest("dry-runn", ["dry-run", "json"]), "dry-run");
});

test("a command with no options says that, rather than listing nothing", () => {
  assert.match(unknownOption("init", ["--force"], []), /takes no options, so there is nothing --force could mean/);
});

test("what epito does know still passes, values and positionals and all", () => {
  assert.equal(unknownOption("validate", ["--for-runtime"], VALIDATE), null);
  assert.equal(unknownOption("token", ["pm", ".", "--dry-run"], [{ name: "dry-run" }]), null, "positionals are not options");
  const opts = [{ name: "timeout", value: true }, { name: "dry-run" }];
  assert.equal(unknownOption("deploy", ["--timeout", "30", "--dry-run"], opts), null, "a value is not an option");
  assert.equal(unknownOption("deploy", ["--timeout=30"], opts), null, "--flag=value too");
  // `--timeout -5` is deploy's own range error, with deploy's own message; it
  // must not be swallowed here as an unknown option called "5".
  assert.equal(unknownOption("deploy", ["--timeout", "-5"], opts), null);
});

test("the two flags whose typo is not cosmetic are both refused", () => {
  assert.match(unknownOption("token", ["pm", "--dry-runn"], [{ name: "dry-run" }]),
    /Did you mean --dry-run/, "a dropped --dry-run on `token` is a real mint");
  assert.match(unknownOption("deploy", ["--dry-runn"], [{ name: "dry-run" }]),
    /Did you mean --dry-run/, "and on `deploy` it is a real GitHub App");
});

// --- adapters: what epito spawns, per kind of agent (ADR-17) --------------
// The acceptance test of this card is the first one: a manifest that says
// nothing about adapters must produce the argv it produced before adapters
// existed, character for character. Everything else is new behaviour; that one
// is a promise to every roster already running.

test("the claude adapter's argv is byte-identical to the flags epitod always spawned", () => {
  const m = seat("pm", { runtime: { max_turns: 12 } });
  const { file, args, env } = ADAPTERS.claude.command({
    manifest: m, name: "pm", runId: "r1", trigger: "cron", prompt: "PROMPT", resume: null, binary: "claude",
  });
  assert.equal(file, "claude");
  assert.deepEqual(args, [
    "-p", "PROMPT", "--permission-mode", "bypassPermissions",
    "--model", "claude-sonnet-5", "--max-turns", "12", "--output-format", "json",
  ]);
  assert.deepEqual(env, {}, "the claude adapter adds no environment of its own");
});

test("the claude adapter still resumes a held session, and says it can", () => {
  const { args } = ADAPTERS.claude.command({
    manifest: seat("pm"), name: "pm", runId: "r1", trigger: "message", prompt: "hi", resume: "sess-1", binary: "claude",
  });
  assert.deepEqual(args.slice(-2), ["--resume", "sess-1"]);
  assert.equal(ADAPTERS.claude.resumes, true);
  assert.equal(ADAPTERS.langgraph.resumes, false, "a langgraph app has no session epito configured, and says so");
});

test("a manifest with no [runtime].adapter is a claude agent: spec v0.1 stays compatible", () => {
  assert.equal(adapterFor(seat("pm")).name, "claude");
  assert.deepEqual(validateManifest(seat("pm"), { baseDir: tmpdir() }), []);
  assert.deepEqual(ADAPTER_NAMES, ["claude", "langgraph"]);
});

test("an adapter epito does not have refuses the run, names both of them and the fix", () => {
  const m = seat("pm", { runtime: { adapter: "keras" } });
  assert.throws(() => adapterFor(m), (e) => {
    assert.match(e.message, /^pm: \[runtime\]\.adapter "keras" is not a kind of agent epito can host/);
    assert.match(e.message, /"claude"/); assert.match(e.message, /"langgraph"/);
    assert.match(e.message, /Fix: name one of those, or leave the field out/);
    assert.equal(e.permanent, true, "a typo in a manifest is not a blip: retrying it insults the operator");
    assert.equal(e.stage, "adapter");
    return true;
  });
  // And `epito validate` says the same sentence, from the same source.
  assert.deepEqual(validateManifest(m, { baseDir: tmpdir() }), [unknownAdapter("keras")]);
});

test("[runtime].graph only means something to the langgraph adapter", () => {
  const wrong = validateManifest(seat("pm", { runtime: { graph: "agent" } }), { baseDir: tmpdir() });
  assert.equal(wrong.length, 1);
  assert.match(wrong[0], /only the langgraph adapter reads, and this manifest's adapter is "claude"/);
  assert.match(wrong[0], /Fix: set \[runtime\]\.adapter = "langgraph", or drop \[runtime\]\.graph/);
  const bad = validateManifest(seat("pm", { runtime: { adapter: "langgraph", graph: "not a name" } }), { baseDir: tmpdir() });
  assert.match(bad[0], /must be the NAME of a graph in the agent's langgraph.json/);
  assert.deepEqual(validateManifest(seat("pm", { runtime: { adapter: "langgraph", graph: "seat" } }), { baseDir: tmpdir() }), []);
});

test("the langgraph adapter hands the run in by environment, never in argv", () => {
  const m = seat("seat", { runtime: { adapter: "langgraph", graph: "seat", max_turns: 7 } });
  const { file, args, env } = ADAPTERS.langgraph.command({
    manifest: m, name: "seat", runId: "run-7", trigger: "hook", prompt: "a paragraph", binary: "python3",
  });
  assert.equal(file, "python3");
  assert.deepEqual(args, [LANGGRAPH_SHIM], "one argument, the shim: /proc/<pid>/cmdline is world-readable");
  assert.equal(env.EPITO_PROMPT, "a paragraph");
  assert.equal(env.EPITO_AGENT, "seat");
  assert.equal(env.EPITO_RUN_ID, "run-7");
  assert.equal(env.EPITO_TRIGGER, "hook");
  assert.equal(env.EPITO_CHARTER, "prompts/seat.md");
  assert.equal(env.EPITO_GRAPH, "seat");
  assert.equal(env.EPITO_MAX_TURNS, "7");
  assert.ok(LANGGRAPH_SHIM.endsWith("/adapters/langgraph_run.py"), "the shim ships with epito, not with the agent");
  assert.ok(existsSync(LANGGRAPH_SHIM), "and it is actually there");
});

test("EPITO_EXECUTOR overrides the claude executable and never the interpreter", () => {
  const env = { EPITO_EXECUTOR: "/tmp/stub-executor.mjs", EPITO_PYTHON: "/usr/bin/python3.12" };
  assert.equal(ADAPTERS.claude.binary(env), "/tmp/stub-executor.mjs");
  assert.equal(ADAPTERS.claude.binary(env, "/opt/claude"), "/opt/claude", "and an explicit override beats it");
  assert.equal(ADAPTERS.langgraph.binary(env, "/tmp/stub-executor.mjs"), "/usr/bin/python3.12",
    "every smoke test sets EPITO_EXECUTOR; handing a Python shim to a Node stub is how that becomes a bug");
  assert.equal(ADAPTERS.langgraph.binary({}), "python3");
});

// --- a langgraph seat, actually run ---------------------------------------
// The fixture is a graph-shaped object with no LangGraph installed, because
// the adapter is duck-typed on purpose (epito imports nothing from the agent's
// language). cli/test/smoke-langgraph.sh runs the same shim against the real
// framework.

const fixture = (name, work) => cpSync(fileURLToPath(new URL(`./fixtures/${name}/`, import.meta.url)), work, { recursive: true });

test("a langgraph seat runs: the graph's steps are its turns, and its PR is read off stdout", async () => {
  const dir = tmpDir();
  const cwd = process.cwd();
  process.chdir(dir);
  const work = mkdtempSync(cloneDirPrefix("seat"));
  try {
    fixture("langgraph-stub", work);
    const agent = seat("seat", { runtime: { adapter: "langgraph", env: ["EPITO_STUB_ECHO_TOKEN"] } });
    process.env.EPITO_STUB_ECHO_TOKEN = "1";
    const r = await executeAgent({
      agent, trigger: "cron", runId: "run-lg-1", workDir: work, timeoutMs: 60_000, log: () => {},
      executor: "/nonexistent/claude-stub",         // the claude override must not reach python
      inject: { GH_TOKEN: "ghs_LANGGRAPHTOKEN0000000000000" }, redact: ["ghs_LANGGRAPHTOKEN0000000000000"],
    });
    assert.equal(r.exit, 0, `the graph ran (log: ${r.log})`);
    assert.equal(r.adapter, "langgraph");
    assert.equal(r.turns, 2, "two nodes ran, so the run took two steps");
    assert.equal(r.pr, "https://github.com/acme/roster/pull/777", "a foreign agent's PR is read the same way");
    assert.equal(r.sessionId, null, "and it holds no session, which is the honest answer");
    const logged = readFileSync(r.log, "utf8");
    // The interpreter is whatever this box resolves, not the literal
    // "python3": a box that actually runs langgraph seats sets EPITO_PYTHON
    // (deploy README), and asserting the default made this test pass only
    // where the framework is absent — green on every box except the one the
    // feature is for.
    assert.ok(logged.includes(`adapter=langgraph command=${ADAPTERS.langgraph.binary(process.env)}`),
      "the log names the interpreter the runtime resolved");
    assert.ok(!logged.includes("/nonexistent/claude-stub"), "and the claude override never reached python");
    assert.match(logged, /· read_charter: charter=prompts\/seat\.md trigger=cron/, "the run's facts reached the graph");
    assert.match(logged, /GH_TOKEN=\[redacted: this run's token\]/, "its own credential reached it, and not the log");
  } finally {
    process.chdir(cwd);
    delete process.env.EPITO_STUB_ECHO_TOKEN;
    rmSync(work, { recursive: true, force: true });
  }
});

test("a repository with no langgraph.json refuses in the product's voice, on the board", async () => {
  const dir = tmpDir();
  const cwd = process.cwd();
  process.chdir(dir);
  const work = mkdtempSync(cloneDirPrefix("seat"));
  try {
    writeFileSync(join(work, "README.md"), "a repository that is not a langgraph app\n");
    const r = await executeAgent({
      agent: seat("seat", { runtime: { adapter: "langgraph" } }),
      trigger: "cron", runId: "run-lg-2", workDir: work, timeoutMs: 60_000, log: () => {},
    });
    assert.equal(r.exit, 2, "2 is the adapter refusing before the graph started");
    // `detail` is the fourth key of the result contract and the reason it
    // exists: the sentence lands on the board, not only in a log file.
    assert.match(r.detail, /^seat: \[runtime\]\.adapter is "langgraph", so this run looked for langgraph\.json/);
    assert.match(r.detail, /Fix: commit the langgraph\.json your app already needs/);
    assert.match(r.detail, /or set \[runtime\]\.adapter = "claude"/);
  } finally {
    process.chdir(cwd);
    rmSync(work, { recursive: true, force: true });
  }
});

test("a follow-up to an adapter that holds no session starts a fresh run, and says so", async () => {
  const dir = tmpDir();
  const cwd = process.cwd();
  process.chdir(dir);
  const work = mkdtempSync(cloneDirPrefix("seat"));
  const said = [];
  try {
    fixture("langgraph-stub", work);
    const r = await executeAgent({
      agent: seat("seat", { runtime: { adapter: "langgraph" } }),
      trigger: "message", runId: "run-lg-3", workDir: work, timeoutMs: 60_000,
      text: "one more thing", resume: "sess-from-a-claude-run", log: (m) => said.push(m),
    });
    assert.equal(r.exit, 0);
    assert.ok(said.some((m) => /the langgraph adapter holds no session, so this message starts a fresh run/.test(m)),
      "the operator is told, rather than left to wonder why context was lost");
    const logged = readFileSync(r.log, "utf8");
    assert.doesNotMatch(logged, /resume=/, "and no --resume was invented for an adapter that cannot use one");
  } finally {
    process.chdir(cwd);
    rmSync(work, { recursive: true, force: true });
  }
});

// --- the trace a run files (ADR-18) --------------------------------------

test("tracing is off unless an endpoint is set, and off means nothing happens", async () => {
  assert.equal(traceConfig({}), null);
  assert.deepEqual(childTraceEnv({ runId: "r1", agent: "pm", env: {} }), {});
  assert.deepEqual(await emit([{ name: "run" }], { env: {} }), { sent: false, reason: "no endpoint" });
  assert.match(traceNote({ runId: "r1", env: {} }), /^# trace: off \(no OTEL_EXPORTER_OTLP_ENDPOINT/);
});

test("the standard variables, both spellings, and the path OTLP puts spans on", () => {
  assert.equal(traceConfig({ OTEL_EXPORTER_OTLP_ENDPOINT: "http://127.0.0.1:6006" }).url, "http://127.0.0.1:6006/v1/traces");
  assert.equal(traceConfig({ OTEL_EXPORTER_OTLP_ENDPOINT: "http://127.0.0.1:6006/" }).url, "http://127.0.0.1:6006/v1/traces");
  assert.equal(traceConfig({ OTEL_EXPORTER_OTLP_TRACES_ENDPOINT: "https://otel.example/ingest" }).url, "https://otel.example/ingest");
  assert.equal(traceConfig({ OTEL_EXPORTER_OTLP_ENDPOINT: "x", OTEL_SERVICE_NAME: "asc" }).service, "asc");
  assert.deepEqual(parseHeaders("api_key=abc123,x-tenant=asc"), { api_key: "abc123", "x-tenant": "asc" });
  assert.deepEqual(parseHeaders(undefined), {});
});

test("three activities agree on one trace with nothing passed between them", () => {
  // The whole reason this file exists instead of the OTel SDK: clone, execute
  // and record are separate invocations that may run on different hosts.
  assert.equal(traceIdFor("run-pm-1"), traceIdFor("run-pm-1"));
  assert.equal(spanIdFor("run-pm-1", "execute"), spanIdFor("run-pm-1", "execute"));
  assert.notEqual(traceIdFor("run-pm-1"), traceIdFor("run-pm-2"));
  assert.notEqual(spanIdFor("run-pm-1", "clone"), spanIdFor("run-pm-1", "execute"));
  assert.equal(traceIdFor("run-pm-1").length, 32, "16 bytes, hex, as OTLP/JSON wants them");
  assert.equal(spanIdFor("run-pm-1", "run").length, 16);
  assert.equal(traceparentFor("run-pm-1", "execute"), `00-${traceIdFor("run-pm-1")}-${spanIdFor("run-pm-1", "execute")}-01`);
});

test("the agent inherits the trace and never the export credential", () => {
  const env = {
    OTEL_EXPORTER_OTLP_ENDPOINT: "http://127.0.0.1:6006",
    OTEL_EXPORTER_OTLP_HEADERS: "api_key=phx-secret-key",
    OTEL_RESOURCE_ATTRIBUTES: "deployment.environment=hq",
  };
  const child = childTraceEnv({ runId: "run-pm-1", agent: "pm", trigger: "cron", env });
  assert.equal(child.TRACEPARENT, traceparentFor("run-pm-1", "execute"), "the agent's spans nest under `execute`");
  assert.equal(child.OTEL_EXPORTER_OTLP_ENDPOINT, "http://127.0.0.1:6006");
  assert.equal(child.OTEL_EXPORTER_OTLP_TRACES_ENDPOINT, "http://127.0.0.1:6006/v1/traces");
  // An operator who set only the complete-URL spelling must not hand the child
  // a base for it to append "/v1/traces" to a second time.
  const specific = childTraceEnv({ runId: "run-pm-1", agent: "pm", env: { OTEL_EXPORTER_OTLP_TRACES_ENDPOINT: "https://otel.example/ingest" } });
  assert.equal(specific.OTEL_EXPORTER_OTLP_TRACES_ENDPOINT, "https://otel.example/ingest");
  assert.equal(specific.OTEL_EXPORTER_OTLP_ENDPOINT, undefined);
  assert.equal(child.OTEL_SERVICE_NAME, "pm", "the spans inside a run are the agent's work");
  assert.match(child.OTEL_RESOURCE_ATTRIBUTES, /^deployment\.environment=hq,epito\.agent=pm,epito\.run_id=run-pm-1,epito\.trigger=cron$/);
  assert.equal(child.OTEL_EXPORTER_OTLP_HEADERS, undefined,
    "law 6: a run sees only the secrets its manifest names, and a headers value is an api key");
  assert.match(traceNote({ runId: "run-pm-1", env }), /which the agent is not given/);
});

test("a span names its parent by phase, so no caller has to know how an id is made", () => {
  const s = span({ runId: "run-pm-1", name: "clone", phase: "clone", parent: "run", startMs: 1_000, endMs: 2_500, attrs: { "epito.repo": "acme/roster" } });
  assert.equal(s.traceId, traceIdFor("run-pm-1"));
  assert.equal(s.spanId, spanIdFor("run-pm-1", "clone"));
  assert.equal(s.parentSpanId, spanIdFor("run-pm-1", "run"));
  assert.equal(s.startTimeUnixNano, "1000000000");
  assert.equal(s.endTimeUnixNano, "2500000000");
  assert.deepEqual(s.status, { code: 1 });
  const failed = span({ runId: "run-pm-1", name: "clone", phase: "clone", startMs: 1, endMs: 2, error: "no such repository" });
  assert.deepEqual(failed.status, { code: 2, message: "no such repository" });
  assert.equal(failed.parentSpanId, undefined, "a root has no parent field at all");
});

test("OTLP's attribute encoding: typed, and a null is dropped rather than sent empty", () => {
  const attrs = attributes({ "epito.agent": "pm", "epito.turns": 3, "epito.resumed": false, "epito.pr": null, "epito.cost": 1.5, "epito.scopes": ["github:contents"] });
  assert.deepEqual(attrs, [
    { key: "epito.agent", value: { stringValue: "pm" } },
    { key: "epito.turns", value: { intValue: "3" } },
    { key: "epito.resumed", value: { boolValue: false } },
    { key: "epito.cost", value: { doubleValue: 1.5 } },
    { key: "epito.scopes", value: { arrayValue: { values: [{ stringValue: "github:contents" }] } } },
  ]);
  const p = payload([span({ runId: "r", name: "run", phase: "run", startMs: 1, endMs: 2 })], { service: "epito" });
  assert.equal(p.resourceSpans[0].resource.attributes[0].value.stringValue, "epito");
  assert.equal(p.resourceSpans[0].scopeSpans[0].spans.length, 1);
});

// A local stand-in for Phoenix: the test asserts against OTLP, not against a
// product (ADR-18 — Phoenix is a surface, never a dependency).
const otlpSink = async (t, { status = 200 } = {}) => {
  const received = [];
  const server = createServer((req, res) => {
    const chunks = [];
    req.on("data", (c) => chunks.push(c));
    req.on("end", () => {
      received.push({ url: req.url, headers: req.headers, body: Buffer.concat(chunks).toString() });
      res.writeHead(status, { "content-type": "application/json" }).end("{}");
    });
  });
  server.listen(0, "127.0.0.1");
  await once(server, "listening");
  t.after(() => server.close());
  return { received, port: server.address().port };
};

test("a span reaches an OTLP endpoint, with no token anywhere in the request", async (t) => {
  const { received, port } = await otlpSink(t);
  const token = "ghs_SPANTOKEN00000000000000000000000";
  const env = { OTEL_EXPORTER_OTLP_ENDPOINT: `http://127.0.0.1:${port}`, OTEL_EXPORTER_OTLP_HEADERS: "api_key=phx-key" };
  const out = await emit([span({
    runId: "run-pm-1", name: "run pm", phase: "run", startMs: 1_000, endMs: 2_000,
    // A caller that put a credential on a span would be a bug; the guarantee
    // wanted is that the REQUEST cannot carry one, not that every caller
    // remembered (ADR-18, consequence 3).
    attrs: { "epito.agent": "pm", "epito.oops": `authorization: Bearer ${token}` },
  })], { env, redact: [token] });
  assert.deepEqual(out, { sent: true });
  assert.equal(received.length, 1);
  assert.equal(received[0].url, "/v1/traces");
  assert.equal(received[0].headers.api_key, "phx-key", "the worker's own export credential does authenticate the export");
  assert.doesNotMatch(received[0].body, /ghs_SPANTOKEN/);
  assert.match(received[0].body, /\[redacted: this run's token\]/);
  const sent = JSON.parse(received[0].body).resourceSpans[0].scopeSpans[0].spans[0];
  assert.equal(sent.traceId, traceIdFor("run-pm-1"));
  assert.equal(sent.name, "run pm");
});

test("a trace backend that is down, or answers 500, never fails the run", async (t) => {
  resetQuiet();
  const complaints = [];
  const { port } = await otlpSink(t, { status: 500 });
  const five = await emit([span({ runId: "r", name: "run", phase: "run", startMs: 1, endMs: 2 })],
    { env: { OTEL_EXPORTER_OTLP_ENDPOINT: `http://127.0.0.1:${port}` }, log: (m) => complaints.push(m) });
  assert.deepEqual(five, { sent: false, reason: "http 500" });
  assert.match(complaints[0], /^epito: the run is recorded, but the trace endpoint answered 500/);

  resetQuiet();
  complaints.length = 0;
  const dead = await emit([span({ runId: "r", name: "run", phase: "run", startMs: 1, endMs: 2 })],
    { env: { OTEL_EXPORTER_OTLP_ENDPOINT: "http://127.0.0.1:1" }, log: (m) => complaints.push(m) });
  assert.equal(dead.sent, false);
  assert.match(complaints[0], /^epito: the run is recorded, but its trace did not reach http:\/\/127\.0\.0\.1:1\/v1\/traces/);
  assert.equal(complaints.length, 1, "and it complains once per process, not once per run");
});

test("an agent's own spans land in the run's trace: the shim nests under `execute`", async (t) => {
  const { received, port } = await otlpSink(t);
  const dir = tmpDir();
  const cwd = process.cwd();
  process.chdir(dir);
  const work = mkdtempSync(cloneDirPrefix("seat"));
  const traced = { ...process.env, OTEL_EXPORTER_OTLP_ENDPOINT: `http://127.0.0.1:${port}` };
  const saved = process.env.OTEL_EXPORTER_OTLP_ENDPOINT;
  try {
    process.env.OTEL_EXPORTER_OTLP_ENDPOINT = traced.OTEL_EXPORTER_OTLP_ENDPOINT;
    fixture("langgraph-stub", work);
    const r = await executeAgent({
      agent: seat("seat", { runtime: { adapter: "langgraph" } }),
      trigger: "cron", runId: "run-lg-trace", workDir: work, timeoutMs: 60_000, log: () => {},
    });
    assert.equal(r.exit, 0);
    const spans = received.flatMap((p) => JSON.parse(p.body).resourceSpans.flatMap((rs) => rs.scopeSpans.flatMap((ss) => ss.spans)));
    const graph = spans.find((s) => s.name.startsWith("graph "));
    const nodes = spans.filter((s) => s.name.startsWith("node "));
    assert.ok(graph, `the graph filed a span (got: ${spans.map((s) => s.name).join(", ")})`);
    assert.equal(graph.traceId, traceIdFor("run-lg-trace"), "in the run's own trace");
    assert.equal(graph.parentSpanId, spanIdFor("run-lg-trace", "execute"), "nested under the run's execute span");
    assert.deepEqual(nodes.map((s) => s.name), ["node read_charter", "node open_pr"]);
    assert.ok(nodes.every((s) => s.parentSpanId === graph.spanId), "and each node under the graph");
    assert.equal(readFileSync(r.log, "utf8").includes(`# trace: ${traceIdFor("run-lg-trace")}`), true,
      "the run log says which trace it is, so a transcript and a waterfall can be put side by side");
  } finally {
    process.chdir(cwd);
    if (saved === undefined) delete process.env.OTEL_EXPORTER_OTLP_ENDPOINT; else process.env.OTEL_EXPORTER_OTLP_ENDPOINT = saved;
    rmSync(work, { recursive: true, force: true });
  }
});

// --- the router (ADR-19) --------------------------------------------------
// Three rules, and every test below is one of them: a route is names and
// never values; a road whose key is not on this box is skipped and said so;
// falling back is allowed only while the agent has provably done nothing.

const routed = (over = {}) => ({
  agent: { name: "pm", description: "A seat." },
  identity: { scopes: ["github:contents"] },
  trigger: { cron: "0 6 * * *" },
  runtime: {
    model: "claude-opus-5", entry: "prompts/pm.md", repo: "acme/roster",
    env: ["MOONSHOT_API_KEY"],
    route: [
      { name: "kimi", model: "kimi-k2-turbo-preview", base_url: "https://api.moonshot.ai/anthropic", token_env: "MOONSHOT_API_KEY" },
      { name: "subscription", model: "claude-opus-5" },
    ],
    ...over,
  },
});

test("router: a manifest with no routes has exactly one, and it is the model it always named", () => {
  const rs = routesFor(seat("pm"));
  assert.equal(rs.length, 1);
  assert.deepEqual(
    { name: rs[0].name, model: rs[0].model, baseUrl: rs[0].baseUrl, tokenEnv: rs[0].tokenEnv },
    { name: DEFAULT_ROUTE, model: "claude-sonnet-5", baseUrl: null, tokenEnv: null },
    "every roster written before routing existed means this",
  );
});

test("router: declared routes keep their order, and a route inherits the manifest's model", () => {
  const rs = routesFor(routed({ route: [{ base_url: "http://gateway.internal" }, { name: "subscription" }] }));
  assert.deepEqual(rs.map((r) => r.name), ["route-1", "subscription"], "an unnamed road still has a name to be logged by");
  assert.deepEqual(rs.map((r) => r.model), ["claude-opus-5", "claude-opus-5"]);
});

test("router: a key is a NAME, and a name the manifest does not inject can never resolve", () => {
  const errs = routeErrors(routed({ env: [] }));
  assert.equal(errs.length, 1);
  assert.match(errs[0], /token_env names "MOONSHOT_API_KEY".*must also be listed in \[runtime\]\.env/s);
  assert.match(errs[0], /never resolve to a value/, "the rule, in the product's own words");
});

test("router: a credential inside base_url is refused — a manifest is publishable", () => {
  const errs = routeErrors(routed({ route: [{ name: "kimi", base_url: "https://user:sk-live-abc@api.moonshot.ai/anthropic" }] }));
  assert.equal(errs.length, 1);
  assert.match(errs[0], /carries a credential in the URL/);
  assert.match(errs[0], /Fix: put the key in a secret and name it with token_env/, "the fix is in the message");
});

test("router: two roads with one name would make a run unable to say where it went", () => {
  const errs = routeErrors(routed({ route: [{ name: "kimi", model: "a" }, { name: "kimi", model: "b" }] }));
  assert.equal(errs.length, 1);
  assert.match(errs[0], /both named "kimi"/);
});

test("router: concurrency is a positive integer, and [[runtime.route]] is a list of tables", () => {
  assert.match(routeErrors(routed({ route: [{ name: "kimi", concurrency: 0 }] }))[0], /concurrency must be a positive integer/);
  assert.match(routeErrors(routed({ route: [] }))[0], /double brackets/, "the TOML spelling a vibecoder gets wrong is in the message");
  assert.match(routeErrors(routed({ route: ["kimi"] }))[0], /must be a table of fields/);
});

test("router: `epito validate` refuses a broken route chain with everything else it refuses", () => {
  const errors = validateManifest(routed({ env: [] }), { baseDir: "." });
  assert.ok(errors.some((e) => /token_env names "MOONSHOT_API_KEY"/.test(e)), "one validator, one set of rules");
});

test("router: a road whose key is not on this box is skipped, by name and with the reason", () => {
  const rs = routesFor(routed());
  const { live, skipped } = liveRoutes(rs, { PATH: "/usr/bin" });
  assert.deepEqual(live.map((r) => r.name), ["subscription"], "open routing is opt-in per machine");
  assert.deepEqual(skipped.map((s) => s.route.name), ["kimi"]);
  assert.match(skipped[0].reason, /MOONSHOT_API_KEY is not set on this machine/);
  const both = liveRoutes(rs, { MOONSHOT_API_KEY: "sk-test" });
  assert.deepEqual(both.live.map((r) => r.name), ["kimi", "subscription"], "and open when the key is there");
  assert.deepEqual(liveRoutes(rs, { MOONSHOT_API_KEY: "   " }).live.map((r) => r.name), ["subscription"],
    "an empty key is not a key: a blank secret is how a workflow that was switched off used to fail at turn one");
});

test("router: every road closed is a refusal that names all of them and the fix", () => {
  const rs = routesFor(routed({ route: [{ name: "kimi", token_env: "MOONSHOT_API_KEY" }], env: ["MOONSHOT_API_KEY"] }));
  const { live, skipped } = liveRoutes(rs, {});
  assert.equal(live.length, 0);
  const msg = noRouteMessage("pm", skipped);
  assert.match(msg, /every route this seat declares is closed on this machine/);
  assert.match(msg, /"kimi" \(MOONSHOT_API_KEY is not set/);
  assert.match(msg, /the subscription is the floor/);
});

// --- base_url_env: an endpoint that is a NAME (spec v0.2) -----------------
//
// The field this company's own roster asked for. `pm`, `market` and `okr` take
// a cheaper road whose ADDRESS is the confidential part, so a literal
// `base_url` would have put the one value that is deliberately not in git into
// a file whose whole promise is that it is publishable.
//
// Everything below is one of three claims: the manifest side is `token_env`'s
// rule exactly; the box side has THREE outcomes rather than two, because a
// variable set to the wrong thing is not the same as a variable nobody set;
// and the resolved address is never written down anywhere.

const gated = (over = {}) => ({
  agent: { name: "pm", description: "A seat." },
  identity: { scopes: ["github:contents"] },
  trigger: { cron: "0 6 * * *" },
  runtime: {
    model: "claude-opus-5", entry: "prompts/pm.md", repo: "acme/roster",
    env: ["OPENROUTE_BASE_URL", "OPENROUTE_API_KEY"],
    route: [
      { name: "open", model: "kimi-k2.7-code", base_url_env: "OPENROUTE_BASE_URL", token_env: "OPENROUTE_API_KEY" },
      { name: "subscription", model: "claude-opus-5" },
    ],
    ...over,
  },
});
const BOX = { OPENROUTE_BASE_URL: "https://gateway.example.com/anthropic", OPENROUTE_API_KEY: "sk-test" };

test("base_url_env: the manifest carries the NAME and resolves nothing, so validate works standing anywhere", () => {
  const [open] = routesFor(gated());
  assert.equal(open.baseUrlEnv, "OPENROUTE_BASE_URL");
  assert.equal(open.baseUrl, null, "resolving in routesFor would make the reader depend on the box it is read on");
  assert.deepEqual(routeErrors(gated()), [], "and the road is legal");
});

test("base_url_env: a name the manifest does not inject can never resolve to an endpoint", () => {
  const errs = routeErrors(gated({ env: ["OPENROUTE_API_KEY"] }));
  assert.equal(errs.length, 1);
  assert.match(errs[0], /base_url_env names "OPENROUTE_BASE_URL".*must also be listed in \[runtime\]\.env/s);
  assert.match(errs[0], /Fix: add "OPENROUTE_BASE_URL" to \[runtime\]\.env/, "token_env's rule, and token_env's fix");
});

test("base_url_env: a value where a name belongs is refused, and the message says which field wants a URL", () => {
  const errs = routeErrors(gated({ route: [{ name: "open", model: "m", base_url_env: "https://gateway.example.com" }] }));
  assert.equal(errs.length, 1);
  assert.match(errs[0], /must be the NAME of an environment variable/);
  assert.match(errs[0], /use base_url = "https:\/\/\.\.\." instead if the endpoint is a public URL/,
    "the reader who wanted the other field is told which one it is");
});

test("base_url_env: a variable's NAME in base_url is told which field it belongs in", () => {
  const named = routeErrors(gated({ route: [{ name: "open", model: "m", base_url: "$OPENROUTE_BASE_URL" }] }));
  assert.equal(named.length, 1);
  assert.match(named[0], /if you meant the variable called OPENROUTE_BASE_URL, that is base_url_env = "OPENROUTE_BASE_URL"/,
    "the reader who reached for indirection is told where the indirection lives");
  // Same hint, generic, for a value that is simply not a URL and not a name.
  const other = routeErrors(gated({ route: [{ name: "open", model: "m", base_url: "moonshot.ai" }] }));
  assert.match(other[0], /name the variable with base_url_env instead if the endpoint is confidential/);
});

test("base_url_env: a road with two endpoints is refused — nothing says which one the runtime takes", () => {
  const errs = routeErrors(gated({
    route: [{ name: "open", model: "m", base_url_env: "OPENROUTE_BASE_URL", base_url: "https://api.moonshot.ai/anthropic" }],
  }));
  assert.equal(errs.length, 1);
  assert.match(errs[0], /declares both base_url and base_url_env/);
  assert.match(errs[0], /keep base_url_env .* if the endpoint is confidential/s, "both halves of the fix, so either reader can act");
});

test("base_url_env: an absent variable closes the road exactly the way an absent key does", () => {
  const { live, skipped } = liveRoutes(routesFor(gated()), { OPENROUTE_API_KEY: "sk-test" });
  assert.deepEqual(live.map((r) => r.name), ["subscription"], "an endpoint you do not have is a road you cannot take");
  assert.match(skipped[0].reason, /OPENROUTE_BASE_URL is not set on this machine/);
  assert.equal(skipped[0].misconfigured, false, "a box that never had it is routing working as designed");
});

test("base_url_env: a variable set to something that is NOT an endpoint is a typo, not an absence", () => {
  // Values chosen so that nothing in the message could contain one by accident:
  // the first draft of this test used "gateway.example.com" and failed on the
  // message's own `e.g. https://gateway.example.com/...`, which is a collision
  // and not a leak — but a no-leak assertion that can pass by coincidence is
  // worth no more than no assertion.
  for (const bad of ["internal-gw-7f3a1c.corp", "ftp://internal-gw-7f3a1c.corp", "not a url at all"]) {
    const { live, skipped } = liveRoutes(routesFor(gated()), { ...BOX, OPENROUTE_BASE_URL: bad });
    assert.deepEqual(live.map((r) => r.name), ["subscription"], `the run still happens: ${bad}`);
    assert.equal(skipped[0].misconfigured, true, `and somebody has to go fix it: ${bad}`);
    assert.match(skipped[0].reason, /is set on this machine but does not hold an http\(s\) URL/);
    assert.match(skipped[0].reason, /Fix: set OPENROUTE_BASE_URL to the address scheme and all/);
    assert.ok(!skipped[0].reason.includes(bad),
      "the value is printed nowhere, which is the entire reason the manifest named a variable");
  }
});

test("base_url_env: a URL with a credential in it closes the road, because the endpoint IS logged", () => {
  const { skipped } = liveRoutes(routesFor(gated()), { ...BOX, OPENROUTE_BASE_URL: "https://u:sk-live-abc@gateway.example.com" });
  assert.equal(skipped[0].misconfigured, true);
  assert.match(skipped[0].reason, /holds a URL with a credential in it/);
  assert.match(skipped[0].reason, /name the key with token_env, which is never logged/, "the other field is the fix");
  assert.ok(!skipped[0].reason.includes("sk-live-abc"), "and the refusal does not leak what it is refusing");
});

test("base_url_env: a live road comes back resolved, so nothing downstream asks how it was spelled", () => {
  const { live } = liveRoutes(routesFor(gated()), BOX);
  assert.deepEqual(live.map((r) => r.name), ["open", "subscription"]);
  assert.equal(live[0].baseUrl, "https://gateway.example.com/anthropic");
  assert.deepEqual(anthropicRouteEnv(live[0], BOX), {
    ANTHROPIC_BASE_URL: "https://gateway.example.com/anthropic", ANTHROPIC_AUTH_TOKEN: "sk-test",
  }, "exactly what the workflow sets by hand from the same two secrets");
  assert.equal(routeFacts(live[0]).EPITO_BASE_URL, "https://gateway.example.com/anthropic",
    "a foreign adapter reads one field whichever way the manifest wrote it");
});

test("base_url_env: a log says $NAME and never the address", () => {
  const { live } = liveRoutes(routesFor(gated()), BOX);
  assert.equal(endpointLabel(live[0]), "$OPENROUTE_BASE_URL",
    "the name is the half an operator has to act on, and the only half that is safe in a file");
  assert.equal(endpointLabel(routesFor(routed())[0]), "https://api.moonshot.ai/anthropic",
    "a public provider's published URL is still printed as itself");
  assert.equal(endpointLabel(routesFor(routed())[1]), null);
});

test("base_url_env: resolveEndpoint is the one answer, and a literal road passes through it unchanged", () => {
  const [kimi, sub] = routesFor(routed());
  assert.deepEqual(resolveEndpoint(kimi, {}), { url: "https://api.moonshot.ai/anthropic", problem: null, misconfigured: false });
  assert.deepEqual(resolveEndpoint(sub, {}), { url: null, problem: null, misconfigured: false });
});

test("base_url_env: stranded by a typo gets the stronger fix, not \"set one of those keys\"", () => {
  const one = routesFor(gated({ route: [{ name: "open", model: "m", base_url_env: "OPENROUTE_BASE_URL" }] }));
  const { live, skipped } = liveRoutes(one, { OPENROUTE_BASE_URL: "gateway.example.com" });
  assert.equal(live.length, 0);
  const msg = noRouteMessage("pm", skipped);
  assert.match(msg, /"open" is configured on this box and configured wrongly/);
  assert.doesNotMatch(msg, /Fix: set one of those keys/,
    "useless advice to the operator who set one and got the value wrong");
  // And the ordinary case keeps the ordinary sentence.
  assert.match(noRouteMessage("pm", liveRoutes(one, {}).skipped), /Fix: set one of those keys on the box/);
});

test("router: the endpoint and the key reach the claude CLI under the names it reads", () => {
  const [kimi, sub] = routesFor(routed());
  assert.deepEqual(anthropicRouteEnv(kimi, { MOONSHOT_API_KEY: "sk-test" }), {
    ANTHROPIC_BASE_URL: "https://api.moonshot.ai/anthropic", ANTHROPIC_AUTH_TOKEN: "sk-test",
  }, "exactly what HQ's fifteen workflows set by hand");
  assert.deepEqual(anthropicRouteEnv(sub, { MOONSHOT_API_KEY: "sk-test" }), {},
    "and an unrouted road changes nothing about the child at all");
});

test("router: a foreign agent is told which road it is on, and never handed the key twice", () => {
  const [kimi] = routesFor(routed());
  const facts = routeFacts(kimi);
  assert.deepEqual(facts, { EPITO_ROUTE: "kimi", EPITO_MODEL: "kimi-k2-turbo-preview", EPITO_BASE_URL: "https://api.moonshot.ai/anthropic" });
  assert.ok(!Object.values(facts).includes("sk-test"), "the key arrives under the name [runtime].env already lists");
});

test("router: the adapter spawns the ROUTE's model, not the manifest's", () => {
  const { args } = ADAPTERS.claude.command({
    manifest: routed(), prompt: "hi", binary: "claude", route: routesFor(routed())[0],
  });
  assert.equal(args[args.indexOf("--model") + 1], "kimi-k2-turbo-preview");
  const { env } = ADAPTERS.langgraph.command({
    manifest: routed({ adapter: "langgraph" }), name: "pm", runId: "r", trigger: "cron",
    prompt: "hi", binary: "python3", route: routesFor(routed())[0],
  });
  assert.equal(env.EPITO_MODEL, "kimi-k2-turbo-preview");
});

test("router: whose fault the ending was — the road's, or the agent's", () => {
  assert.equal(classifyAttempt({ exit: 0, turns: 7 }), "ok");
  assert.equal(classifyAttempt({ exit: 1, turns: 1 }), "route", "L-E7's fingerprint: refused at turn one, nothing done");
  assert.equal(classifyAttempt({ exit: 1, turns: null }), "route", "a provider that answered nothing at all");
  assert.equal(classifyAttempt({ exit: 1, turns: 9 }), "agent", "nine turns in, the outcome is the run's own");
  assert.equal(classifyAttempt({ exit: 1, turns: 1, pr: "https://github.com/a/b/pull/1" }), "agent",
    "it opened a pull request: this run exists now and may never be started again somewhere else");
  for (const exit of ["timeout", "cancelled", "workdir-gone", "spawn"]) {
    assert.equal(classifyAttempt({ exit, turns: 1 }), "agent", `${exit} is not a road another provider can fix`);
  }
});

test("router: a one-lane road carries one run at a time", async () => {
  const lane = { name: "kimi", concurrency: 1 };
  let inside = 0, most = 0;
  const body = async () => {
    inside++; most = Math.max(most, inside);
    await new Promise((r) => setTimeout(r, 15));
    inside--;
    return "done";
  };
  const out = await Promise.all([withLane(lane, body), withLane(lane, body), withLane(lane, body)]);
  assert.deepEqual(out, ["done", "done", "done"]);
  assert.equal(most, 1, "a prepaid tier that allows one concurrent request is a single-lane road");
  let free = 0;
  await Promise.all([withLane({ name: "open" }, async () => { free++; await new Promise((r) => setTimeout(r, 10)); }),
                     withLane({ name: "open" }, async () => { free++; })]);
  assert.equal(free, 2, "a road with no ceiling is not serialized");
});

// --- the detour, end to end ----------------------------------------------

const stubRun = async (agent, over = {}, env = {}) => {
  const dir = tmpDir();
  const cwd = process.cwd();
  process.chdir(dir);
  const work = mkdtempSync(cloneDirPrefix(agent.agent.name));
  const saved = {};
  // `null` means this box does NOT hold the name, which stopped being the same
  // thing as holding it empty: a blank value is an env-file line somebody
  // filled in halfway, and the router now says so rather than calling it unset.
  for (const [k, v] of Object.entries(env)) { saved[k] = process.env[k]; if (v === null) delete process.env[k]; else process.env[k] = v; }
  process.env.EPITO_STUB_DIR = join(dir, "stub");
  try {
    const r = await executeAgent({
      agent, trigger: "cron", runId: "r-route", workDir: work, timeoutMs: 30_000, log: () => {},
      executor: new URL("./stub-executor.mjs", import.meta.url).pathname, ...over,
    });
    return { ...r, logged: readFileSync(r.log, "utf8") };
  } finally {
    process.chdir(cwd);
    rmSync(work, { recursive: true, force: true });
    for (const [k, v] of Object.entries(saved)) { if (v === undefined) delete process.env[k]; else process.env[k] = v; }
    delete process.env.EPITO_STUB_DIR;
  }
};

const stubSeat = (over = {}) => ({
  agent: { name: "pm" },
  runtime: {
    model: "claude-opus-5", entry: "e", repo: "acme/roster",
    env: ["MOONSHOT_API_KEY", "EPITO_STUB_DIR", "EPITO_STUB_REFUSE_BASE_URL", "EPITO_STUB_REFUSE_SAYS", "EPITO_STUB_ECHO_ROUTE"],
    route: [
      { name: "kimi", model: "kimi-k2-turbo-preview", base_url: "https://api.moonshot.ai/anthropic", token_env: "MOONSHOT_API_KEY" },
      { name: "subscription", model: "claude-opus-5" },
    ],
    ...over,
  },
});

test("the detour: a provider that refuses at turn one costs the run nothing", async () => {
  const r = await stubRun(stubSeat(), {}, {
    MOONSHOT_API_KEY: "sk-moonshot-unit-key",
    EPITO_STUB_REFUSE_BASE_URL: "https://api.moonshot.ai/anthropic",
    EPITO_STUB_ECHO_ROUTE: "1",
  });
  assert.equal(r.exit, 0, "the run happened");
  assert.equal(r.route, "subscription");
  assert.equal(r.model, "claude-opus-5", "and the model reported is the one that actually ran");
  assert.deepEqual(r.attempts.map((a) => [a.route, a.outcome]), [["kimi", "route"], ["subscription", "ok"]]);
  assert.match(r.logged, /route "kimi" did not start the run .* — taking the next road, "subscription"/,
    "the detour is in the run log, because a fallback nobody can see is a cost nobody can see");
  assert.doesNotMatch(r.logged, /sk-moonshot-unit-key/, "and the road's key is scrubbed like every other secret");
  assert.match(r.logged, /key=\[redacted: the key for route kimi\]/,
    "the child echoed the key it tried; the log names which credential stood there and prints none of it");
});

test("the detour: the cheap road is taken when it works, and nothing else runs", async () => {
  const r = await stubRun(stubSeat(), {}, { MOONSHOT_API_KEY: "sk-moonshot-unit-key", EPITO_STUB_ECHO_ROUTE: "1" });
  assert.equal(r.exit, 0);
  assert.equal(r.route, "kimi");
  assert.equal(r.attempts.length, 1, "one road, one spawn");
  assert.match(r.logged, /"num_turns":1/, "a redaction never breaks the result line the run reads its own turns out of");
  assert.match(r.logged, /model=kimi-k2-turbo-preview endpoint=https:\/\/api\.moonshot\.ai\/anthropic/,
    "the child really was pointed at the open provider");
});

test("the detour: no key on this box means the closed road is announced, not attempted", async () => {
  const r = await stubRun(stubSeat(), {}, { MOONSHOT_API_KEY: null });
  assert.equal(r.exit, 0);
  assert.equal(r.route, "subscription");
  assert.equal(r.attempts.length, 1, "a skipped road is not an attempt");
  assert.match(r.logged, /route "kimi" \(kimi-k2-turbo-preview\) skipped: MOONSHOT_API_KEY is not set/);
});

// A named endpoint, end to end: the child is really pointed at the address the
// box holds, and nothing that gets written down knows what it is. The stub
// echoes ANTHROPIC_BASE_URL back in its result on purpose, which is both how
// this test can see where the child went and exactly what a provider error
// path does — so the same line proves the pointing and the scrubbing.
const GATEWAY = "https://gw-unit-7f3a1c.invalid/anthropic";
const gatedSeat = (over = {}) => stubSeat({
  env: ["OPENROUTE_BASE_URL", "OPENROUTE_API_KEY", "EPITO_STUB_DIR", "EPITO_STUB_REFUSE_BASE_URL", "EPITO_STUB_ECHO_ROUTE"],
  route: [
    { name: "open", model: "kimi-k2.7-code", base_url_env: "OPENROUTE_BASE_URL", token_env: "OPENROUTE_API_KEY" },
    { name: "subscription", model: "claude-opus-5" },
  ],
  ...over,
});

test("the detour: a road whose endpoint is a NAME points the child at it, and writes down neither", async () => {
  const r = await stubRun(gatedSeat(), {}, {
    OPENROUTE_BASE_URL: GATEWAY, OPENROUTE_API_KEY: "sk-gateway-unit-key", EPITO_STUB_ECHO_ROUTE: "1",
  });
  assert.equal(r.exit, 0);
  assert.equal(r.route, "open", "the cheap road opened, because the box holds both halves of it");
  assert.match(r.logged, /model=kimi-k2\.7-code endpoint=\$OPENROUTE_BASE_URL key=\$OPENROUTE_API_KEY/,
    "the log names the variables, which is the half an operator acts on");
  assert.ok(!r.logged.includes(GATEWAY),
    "and never the address — the child echoed it straight back and the scrubber caught it");
  assert.match(r.logged, /endpoint=\[redacted: \$OPENROUTE_BASE_URL, the endpoint for route open\]/,
    "the redaction says which secret stood there, the way it already does for a key");
  assert.doesNotMatch(r.logged, /sk-gateway-unit-key/);
});

test("the detour: an endpoint set to the wrong thing is announced as a typo, and the run still happens", async () => {
  const said = [];
  const r = await stubRun(gatedSeat(), { log: (m) => said.push(m) }, {
    OPENROUTE_BASE_URL: "gw-unit-7f3a1c.invalid", OPENROUTE_API_KEY: "sk-gateway-unit-key", EPITO_STUB_ECHO_ROUTE: "1",
  });
  assert.equal(r.exit, 0, "a run in progress never refuses over a road it has an alternative to");
  assert.equal(r.route, "subscription");
  assert.equal(r.attempts.length, 1, "a closed road is not an attempt, however it came to be closed");
  assert.ok(said.some((m) => /configured on this machine and configured wrongly/.test(m)),
    "the operator-facing line separates a box that never had it from a box that has it wrong");
  assert.ok(said.some((m) => /Fix: set OPENROUTE_BASE_URL to the address scheme and all/.test(m)));
  assert.ok(!said.join("\n").includes("gw-unit-7f3a1c.invalid"), "and still prints no value");
});

test("the detour: a seat with every road closed refuses the run and names each one", async () => {
  const seatNoFloor = stubSeat({ route: [{ name: "kimi", base_url: "https://api.moonshot.ai/anthropic", token_env: "MOONSHOT_API_KEY" }] });
  const r = await stubRun(seatNoFloor, {}, { MOONSHOT_API_KEY: "" });
  assert.equal(r.exit, "no-route");
  assert.match(r.detail, /every route this seat declares is closed on this machine/);
  assert.match(r.detail, /the subscription is the floor/, "the fix names the rule the company already paid for");
});

test("the detour: a run that reached turn nine is the agent's outcome, not the road's", async () => {
  // The stub answers turn N+1 for a session it has seen before, so a second
  // run on the same session id is a run that did work and then failed.
  const dir = tmpDir();
  const stub = join(dir, "many-turns.mjs");
  writeFileSync(stub, `#!/usr/bin/env node
process.stdout.write(JSON.stringify({ type: "result", is_error: true, num_turns: 9, result: "the agent gave up", session_id: "s1" }) + "\\n");
process.exit(1);
`);
  chmodSync(stub, 0o755);
  const r = await stubRun(stubSeat(), { executor: stub }, { MOONSHOT_API_KEY: "sk-moonshot-unit-key" });
  assert.equal(r.exit, 1, "the agent's own exit code, not a stage name");
  assert.equal(r.route, "kimi", "it stayed on the road it started on");
  assert.deepEqual(r.attempts.map((a) => [a.route, a.outcome, a.turns]), [["kimi", "agent", 9]],
    "nine turns in, the runtime keeps its hands off the outcome");
  rmSync(dir, { recursive: true, force: true });
});

test("the detour: a resumed run never falls back — a session belongs to the provider that made it", async () => {
  const r = await stubRun(stubSeat(), { resume: "held-session-1", text: "one more thing", routeName: "kimi" }, {
    MOONSHOT_API_KEY: "sk-moonshot-unit-key",
    EPITO_STUB_REFUSE_BASE_URL: "https://api.moonshot.ai/anthropic",
  });
  assert.notEqual(r.exit, 0, "the road it was held on refused, and the run failed there");
  assert.deepEqual(r.attempts.map((a) => a.route), ["kimi"], "no stranger was handed the session id");
  assert.match(r.logged, /a resumed run does not fall back/);
});

// --- the ingress racing the end of a run -----------------------------------
// `signalWithStart` signals-then-starts on the server, so a run that COMPLETES
// between those two steps is signalled after it closed. It is the ordinary end
// of every run meeting the ingress, and before the retry it answered 500 with
// Temporal's own sentence and dropped whatever the person had said.

test("a signal that lost the race to a run's own ending is recognised, by name and by sentence", () => {
  const byName = Object.assign(new Error("whatever the server said"), { name: "WorkflowNotFoundError" });
  assert.ok(justCompleted(byName), "the SDK's error class is the reliable half");
  assert.ok(justCompleted(new Error("workflow execution already completed")),
    "and the sentence is the half that survives an SDK rename");
  assert.ok(justCompleted(new Error("Workflow Execution Already Completed")), "case is not a promise the server makes");
  assert.ok(!justCompleted(new Error("connection refused")), "an engine that is down is not a run that ended");
  assert.ok(!justCompleted(Object.assign(new Error("x"), { name: "WorkflowExecutionAlreadyStartedError" })),
    "and neither is the opposite race, which openWindow handles its own way");
  assert.ok(!justCompleted(null) && !justCompleted(undefined), "nothing thrown is nothing to classify");
});

test("losing that race starts a fresh run instead of failing the request", async () => {
  let calls = 0;
  const send = async () => {
    calls++;
    if (calls === 1) throw Object.assign(new Error("workflow execution already completed"), { name: "WorkflowNotFoundError" });
    return { workflowId: "run:pm" };
  };
  let said = 0;
  const r = await sendOrRestart(send, () => said++);
  assert.equal(calls, 2, "it tries again: by now the execution is closed, so a new one starts");
  assert.equal(r.raced, true, "and the caller is told, so the 202 does not claim it coalesced");
  assert.equal(r.handle.workflowId, "run:pm");
  assert.equal(said, 1, "the operator sees it once, not on every message");
});

test("a run in flight is signalled once, and nothing is retried", async () => {
  let calls = 0;
  const r = await sendOrRestart(async () => { calls++; return { workflowId: "run:pm" }; });
  assert.equal(calls, 1);
  assert.equal(r.raced, false, "the ordinary path says nothing and costs nothing");
});

test("any other failure is the caller's to see: a retry here would hide a broken workflow", async () => {
  let calls = 0;
  const send = async () => { calls++; throw new Error("connection refused"); };
  await assert.rejects(() => sendOrRestart(send), /connection refused/);
  assert.equal(calls, 1, "it is not retried, because retrying a dead engine just fails twice");
});

// --- the freeze: spec v0.1's field catalogue, and the three seat shapes ----
//
// The backlog card this section closes: "spec/manifest.md reviewed against
// the three alexandria seat shapes (daily builder, weekly writer,
// event-driven responder); every field either earns its place or goes." The
// shapes are real manifests in test/fixtures/shapes/, and the coverage test
// below is that sentence made executable — a field no shape needs is a field
// that did not earn its place, and this suite says so by name.

const SHAPES = ["daily-builder", "weekly-writer", "event-responder"];
const shapePath = (n) => fileURLToPath(new URL(`./fixtures/shapes/${n}/agent.toml`, import.meta.url));

for (const shape of SHAPES) {
  test(`seat shape "${shape}" validates against frozen v0.1`, () => {
    const { errors } = loadManifest(shapePath(shape));
    assert.deepEqual(errors, [], errors.join("\n"));
  });
}

// The one thing a version constant can get wrong: being a different version
// from the document it names. Every "not a field in manifest spec X" message
// generates its field list from the catalogue, so a stale constant makes the
// validator offer a field and then send the reader to a spec without it.
test("SPEC_VERSION is the version spec/manifest.md's own heading claims", () => {
  const spec = readFileSync(new URL("../../spec/manifest.md", import.meta.url), "utf8");
  const heading = spec.split("\n", 1)[0];
  const claimed = heading.match(/spec (v\d+\.\d+)/)?.[1];
  assert.ok(claimed, `spec/manifest.md's first line does not name a version: ${heading}`);
  assert.equal(SPEC_VERSION, claimed,
    "the code implements one version and the document is another — one of the two moved alone");
});

test("every field in the frozen catalogue is needed by at least one of the three shapes", () => {
  const used = { agent: new Set(), identity: new Set(), trigger: new Set(), runtime: new Set() };
  for (const shape of SHAPES) {
    const { manifest } = loadManifest(shapePath(shape));
    for (const t of TABLES) for (const k of Object.keys(manifest[t] ?? {})) used[t].add(k);
  }
  const orphans = [];
  for (const t of TABLES) for (const f of FIELDS[t]) if (!used[t].has(f)) orphans.push(`[${t}].${f}`);
  assert.deepEqual(orphans, [], `these fields are in the spec and no real seat shape needs them: ${orphans.join(", ")}`);
});

test("the three shapes together exercise every key a route has", () => {
  const { manifest } = loadManifest(shapePath("daily-builder"));
  const used = new Set(manifest.runtime.route.flatMap((r) => Object.keys(r)));
  assert.deepEqual(ROUTE_FIELDS.filter((f) => !used.has(f)), []);
});

test("a misspelled field is refused, and the message carries the spelling", () => {
  const errs = validateManifest(baseManifest({ runtime: { ...baseRuntime(), mdoel: "claude-opus-5" } }));
  const hit = errs.find((e) => e.includes("mdoel"));
  assert.ok(hit, `a typo must not validate: ${errs.join("\n")}`);
  assert.match(hit, /did you mean \[runtime\]\.model\?/);
});

test("max_turn (the singular typo) is refused rather than silently meaning 100", () => {
  const errs = validateManifest(baseManifest({ runtime: { ...baseRuntime(), max_turn: 50 } }));
  assert.ok(errs.some((e) => e.includes("max_turn") && e.includes("max_turns")), errs.join("\n"));
});

test("[trigger].on is retired, and the message says what replaces it", () => {
  const errs = validateManifest(baseManifest({ trigger: { on: ["issue.opened"] } }));
  const hit = errs.find((e) => e.includes("[trigger].on"));
  assert.ok(hit, errs.join("\n"));
  assert.match(hit, /webhook = true/);
  // The seat could never have fired, and the triad rule now says so too — in
  // v0.2 it offers three ways to be woken, and the bus is the one that
  // replaces what `on` pretended to be.
  assert.ok(errs.some((e) => /needs at least one of: cron .*webhook .*or subscriptions /.test(e)), errs.join("\n"));
  assert.match(hit, /subscriptions = \[/);
});

test("[runtime].image is retired: an image is a property of the box", () => {
  const errs = validateManifest(baseManifest({ runtime: { ...baseRuntime(), image: "default" } }));
  assert.ok(errs.some((e) => e.includes("[runtime].image") && e.includes("property of the box")), errs.join("\n"));
});

test("a whole table the spec does not define is named as a table", () => {
  const errs = validateManifest(baseManifest({ deploy: { target: "github" } }));
  assert.ok(errs.some((e) => e.startsWith("[deploy] is not a table")), errs.join("\n"));
});

test("an unknown key inside a route table is refused too", () => {
  const rt = { ...baseRuntime(), env: ["K"], route: [{ name: "open", model: "m", token_env: "K", retries: 3 }] };
  const errs = validateManifest(baseManifest({ runtime: rt }));
  assert.ok(errs.some((e) => e.includes("retries") && e.includes("[[runtime.route]] #1")), errs.join("\n"));
});

test("[trigger].webhook is a boolean, and the message says the URL is never the manifest's", () => {
  const errs = validateManifest(baseManifest({ trigger: { webhook: "https://example.com/hooks/x" } }));
  assert.ok(errs.some((e) => e.includes("[trigger].webhook") && e.includes("never the manifest's")), errs.join("\n"));
});

function baseRuntime() {
  return { model: "claude-sonnet-5", entry: "prompts/x.md", repo: "acme/x" };
}
function baseManifest(over = {}) {
  return {
    agent: { name: "x", description: "A seat." },
    identity: { scopes: ["github:contents"] },
    trigger: { cron: "0 6 * * *" },
    runtime: baseRuntime(),
    ...over,
  };
}

// The spec's catalogue and the validator's catalogue are the same list, and
// this is what makes that a fact rather than a comment. The block under "##
// The field catalogue" in spec/manifest.md is valid TOML on purpose, so the
// document can be read by the code it governs: a field added to one side and
// not the other fails here, by name, which is exactly the drift that let five
// fields land as prose without ever being checked.
test("spec/manifest.md's field catalogue is the validator's field catalogue", () => {
  const md = readFileSync(fileURLToPath(new URL("../../spec/manifest.md", import.meta.url)), "utf8");
  const block = md.match(/## The field catalogue[\s\S]*?```toml\n([\s\S]*?)```/);
  assert.ok(block, "spec/manifest.md has no TOML catalogue under '## The field catalogue'");
  const spec = parse(block[1]);
  assert.deepEqual(Object.keys(spec).sort(), [...TABLES].sort(), "the spec and the code disagree about which tables a manifest has");
  for (const t of TABLES) {
    assert.deepEqual(
      Object.keys(spec[t]).sort(),
      [...FIELDS[t]].sort(),
      `[${t}]: spec/manifest.md and cli/src/lib/manifest.js disagree about the fields`,
    );
  }
  // The route table's keys live with the route reader; same rule.
  assert.deepEqual(Object.keys(spec.runtime.route[0]).sort(), [...ROUTE_FIELDS].sort(),
    "[[runtime.route]]: spec/manifest.md and cli/src/lib/router.js disagree about the fields");
  // A retired field must not creep back into the document.
  for (const gone of ["[trigger].on", "[runtime].image"]) {
    const [, table, field] = gone.match(/\[(\w+)\]\.(\w+)/);
    assert.ok(!(field in spec[table]), `${gone} is retired and is back in the spec's catalogue`);
  }
});

// Same rule, one directory over: the runtime box's engine list and the CLI's
// declared peers are one list. cli/package.json stopped shipping @temporalio/*
// with the CLI so `npm i -g epito` is half a megabyte, and the box that exists
// to run `epito run` and `epito worker` therefore has to install them by name
// in deploy/provision-host.sh. Two places naming the same four packages is
// drift waiting to happen — and the failure mode is a provisioned host whose
// units start, print an install line and exit 1, which is why this is an
// assertion and not a comment.
test("the runtime box installs every engine peer the CLI declares", () => {
  const pkg = JSON.parse(readFileSync(fileURLToPath(new URL("../package.json", import.meta.url)), "utf8"));
  const peers = Object.keys(pkg.peerDependencies ?? {});
  assert.ok(peers.length > 0, "cli/package.json declares no peerDependencies — has the engine moved back into dependencies?");
  for (const p of peers) {
    assert.ok(
      (pkg.peerDependenciesMeta?.[p]?.optional) === true,
      `${p} is a peer dependency but not an optional one, so \`npm i -g epito\` drags the engine back in`,
    );
  }

  const sh = readFileSync(fileURLToPath(new URL("../../deploy/provision-host.sh", import.meta.url)), "utf8");
  const line = sh.match(/^ENGINE_PKGS="([^"]*)"/m);
  assert.ok(line, "deploy/provision-host.sh no longer sets ENGINE_PKGS — the runtime box would come up with no engine");
  const installed = line[1].trim().split(/\s+/).map((s) => s.split("@^")[0] || s);
  assert.deepEqual(
    installed.map((s) => s.replace(/@[\^~]?[\d.].*$/, "")).sort(),
    peers.sort(),
    "deploy/provision-host.sh and cli/package.json disagree about which engine packages the runtime box needs",
  );
  // And it must actually be installed globally: a local `npm ci` cannot put a
  // package where a globally installed `epito` will resolve it.
  assert.match(sh, /npm install -g --silent \$ENGINE_PKGS/,
    "provision-host.sh names the engine packages but does not install them globally");
});

// --- readiness: a ✓ that does not overclaim ---------------------------------
//
// `epito init` wrote a manifest, `epito validate` ticked it, and `epito run`,
// `epito deploy` and `epito token` then every one refused it for a missing
// [runtime].repo. Spec v0.1 keeps the validator permissive there on purpose
// (Actions-era manifests stay valid) and leaves an unmapped scope to the mint
// ("a stricter validator would refuse a running roster at startup over one
// word"), so neither is an error — which makes the NOTE the only thing
// standing between a vibecoder and a refusal they were just told would not
// come. These assert the note says the true thing.

const manifestFor = (runtime = {}, identity = {}) => ({
  agent: { name: "digest", description: "One sentence." },
  identity: { scopes: ["github:contents"], ...identity },
  trigger: { cron: "0 6 * * *" },
  runtime: { model: "claude-sonnet-5", entry: "prompts/digest.md", ...runtime },
});

test("a manifest with no [runtime].repo is valid, and the note names every command that will refuse it", () => {
  const m = manifestFor();
  // Anchored on the field, not on the word: the refusals about OTHER fields
  // now name [runtime].repo in their own fix lines ("set repo = owner/name and
  // commit the charter there"), and a filter on /repo/ counted those as a repo
  // error. What this test is about is a refusal whose SUBJECT is the field.
  assert.deepEqual(validateManifest(m, { baseDir: tmpDir() }).filter((e) => e.startsWith("[runtime].repo")), [],
    "[runtime].repo became a validation error — spec v0.1 says validate accepts it absent");
  const [b, ...rest] = blockers(m);
  assert.equal(rest.length, 0, "one blocker expected, got more");
  assert.deepEqual(b.commands, REPO_REQUIRED_BY);
  assert.match(b.problem, /\[runtime\]\.repo is unset/);
  // The bar from `epito validate`: name the rule, in the product's vocabulary,
  // with the fix in the message.
  assert.match(b.fix, /repo = "owner\/name"/, "the note does not carry the fix");
  for (const c of REPO_REQUIRED_BY) assert.match(b.problem, new RegExp(`epito ${c}`), `the note does not name \`epito ${c}\``);
});

test("a manifest WITH [runtime].repo has nothing to warn about", () => {
  assert.deepEqual(blockers(manifestFor({ repo: "acme/product" })), []);
});

test("an unmappable scope is valid, and the note sends it to the two commands that mint", () => {
  const m = manifestFor({ repo: "acme/product" }, { scopes: ["github:contents", "github:packages"] });
  assert.deepEqual(validateManifest(m, { baseDir: tmpDir() }), [],
    "an unmapped scope became a validation error — spec v0.1 sends it to the mint, not the validator");
  const [b] = blockers(m);
  assert.deepEqual(b.commands, SCOPE_REQUIRED_BY);
  assert.match(b.problem, /"github:packages"/, "the note does not name the offending scope");
  assert.ok(!/github:contents"\)/.test(b.problem), "the note blames a scope that maps fine");
  for (const s of Object.keys(SCOPE_MAP)) assert.match(b.fix, new RegExp(s), `the fix does not list the mintable scope ${s}`);
});

test("both blockers at once are both reported — a user fixes what they are shown", () => {
  const m = manifestFor({}, { scopes: ["github:packages"] });
  assert.equal(blockers(m).length, 2);
});

test("the ✓ says the charter was NOT checked when the charter lives in another repo", () => {
  // validateManifest skips the entry stat when repo is set, because the
  // runtime reads it inside the clone. The tick must not imply otherwise.
  assert.deepEqual(validateManifest(manifestFor({ repo: "acme/product", entry: "nope.md" }), { baseDir: tmpDir() }), [],
    "entry is checked locally even though repo is set");
  // Said when the charter is nowhere on this machine either.
  const d = tmpDir();
  const [u] = unchecked(manifestFor({ repo: "acme/product" }), { baseDir: d });
  assert.match(u, /read inside the clone of acme\/product/);
  assert.match(u, /Fix: commit prompts\/digest\.md to acme\/product/);
  // And NOT said when the charter is sitting right here, which is the ordinary
  // case of running `epito validate` in the repo the agent works in. A note on
  // every correct manifest is the noise docs/ideas.md warned about.
  mkdirSync(join(d, "prompts"), { recursive: true });
  writeFileSync(join(d, "prompts", "digest.md"), "# digest\n");
  assert.deepEqual(unchecked(manifestFor({ repo: "acme/product" }), { baseDir: d }), [],
    "the ✓ disclaims a charter that is sitting in the directory");
  // With no repo the entry IS checked by the validator, so nothing to disclaim.
  assert.deepEqual(unchecked(manifestFor(), { baseDir: d }), []);
});

// The roster layout, which is the layout `epito run <dir>` exists for: the
// manifest is at agents/<seat>/agent.toml and the charter it names is at the
// top of the repository, not beside it. Checking only the manifest's own
// folder told all five of this company's seats to commit a charter that was
// already committed (agents/, this branch) — a note on the good case, which
// is the one failure the note was written to avoid.
test("a charter at the repository root counts, when it is the repo the manifest names", () => {
  const d = tmpDir();
  const top = tmpDir();
  mkdirSync(join(top, "prompts"), { recursive: true });
  writeFileSync(join(top, "prompts", "digest.md"), "# digest\n");
  const m = manifestFor({ repo: "acme/product" });

  // The charter is not beside the manifest, but it IS at the top of the work
  // tree the manifest sits in, and that tree's origin is the repo it names.
  assert.deepEqual(unchecked(m, { baseDir: d, root: () => top, origin: () => "acme/product" }), [],
    "a charter committed at the repository root is still evidence the charter exists");

  // Same file on disk, but this work tree is a different repository. Finding
  // prompts/digest.md at the top of some unrelated checkout says nothing
  // about acme/product, so the note stands.
  const [u] = unchecked(m, { baseDir: d, root: () => top, origin: () => "acme/other" });
  assert.match(u, /Fix: commit prompts\/digest\.md to acme\/product/,
    "a charter in a repo the manifest does not name was taken as evidence");

  // Not in a git work tree at all: nothing to fall back to, note stands.
  const [u2] = unchecked(m, { baseDir: d, root: () => null, origin: () => null });
  assert.match(u2, /read inside the clone of acme\/product/);

  // The root is consulted only as a fallback: a charter beside the manifest
  // short-circuits before any git call, so `epito validate` in an ordinary
  // single-manifest repo spawns nothing.
  mkdirSync(join(d, "prompts"), { recursive: true });
  writeFileSync(join(d, "prompts", "digest.md"), "# digest\n");
  let gitCalls = 0;
  assert.deepEqual(unchecked(m, { baseDir: d, root: () => { gitCalls++; return top; }, origin: () => "acme/product" }), []);
  assert.equal(gitCalls, 0, "the charter was beside the manifest and git was asked anyway");
});

test("repoRoot answers the top of a work tree, and null outside one", () => {
  const d = tmpDir();
  assert.equal(repoRoot(d), null, "a bare temp directory is not a work tree");
  execFileSync("git", ["init", "-q", "."], { cwd: d });
  const sub = join(d, "agents", "pm");
  mkdirSync(sub, { recursive: true });
  // realpathSync: macOS hands out /var/... for /private/var/..., and git
  // answers with the resolved one.
  assert.equal(realpathSync(repoRoot(sub)), realpathSync(d),
    "repoRoot from a subdirectory must answer the top, which is what a roster needs");
});

// The drift guard, same shape as the engine-peers assertion above: the note
// prints a list of commands, and the list is only true as long as it is the
// whole list. These are the files that refuse over [runtime].repo today, and
// which commands each one speaks for. A new refusal in a new file fails this
// test rather than quietly making the note a lie.
test("the repo note names every command whose source refuses over [runtime].repo", () => {
  const OWNERS = {
    "lib/roster.js": ["run", "ps"],   // loadRoster, shared by `epito run` and `epito ps <dir>`
    "deploy.js": ["deploy"],
    "token.js": ["token"],
    "lib/identity.js": ["deploy", "token"], // the mint path both of those reach
    // The Cloudflare target refuses for its own reason — the Worker reads the
    // charter out of [runtime].repo on every run, so a manifest with no
    // repository describes a run with nothing to read — but it is still
    // `epito deploy`, so the note's command list is unchanged by it.
    "lib/cfpack.js": ["deploy"],
    // Deliberately absent: src/validate.js. `epito validate <dir> --for-runtime`
    // does refuse a roster over a missing [runtime].repo, but the note is the
    // thing `epito validate` PRINTS, and a note that listed the command you are
    // already running would be noise. The flag is also opt-in, so the default
    // `epito validate` still says yes — which is the whole reason readiness.js
    // exists. It carries no [runtime].repo refusal of its own either: it reads
    // the rule from lib/readiness.js and lib/roster.js, which is why it does
    // not show up in `refusers` below.
  };
  const srcDir = fileURLToPath(new URL("../src/", import.meta.url));
  const files = [];
  const walk = (d, prefix = "") => {
    for (const ent of readdirSync(d, { withFileTypes: true })) {
      if (ent.isDirectory()) walk(join(d, ent.name), `${prefix}${ent.name}/`);
      else if (ent.name.endsWith(".js")) files.push([`${prefix}${ent.name}`, readFileSync(join(d, ent.name), "utf8")]);
    }
  };
  walk(srcDir);
  // A refusal is any of the ways this codebase says no — die(), throw, pushing
  // onto a validator's error list, or returning a tagged rule from a rule set
  // some caller maps to its own refusal (lib/roster.js's rosterRules, which
  // `epito run` turns into errs and `epito validate <dir>` turns into a note).
  // Checked on the statement, not on the file, so a file that merely mentions
  // [runtime].repo in a comment is not counted as refusing over it.
  //
  // `out.push(` earns its place here the hard way: when the roster's two rules
  // were factored into rosterRules so `epito validate <dir>` could apply them
  // at its own severity, lib/roster.js stopped matching this pattern and this
  // test went red — correctly. The rule had not moved out of roster.js, only
  // into a different shape, and a detector that cannot see the shape would
  // have quietly stopped guarding the note.
  // `function no*Message(` is the same lesson a second time, and the second
  // time it was this test that caught it: `epito doctor` reports the mint's
  // own refusals as a preflight, so the sentence moved out of the `throw` and
  // into a named message builder beside noPrincipalMessage — one sentence, two
  // readers, which is the point of the refactor. The refusal did not move out
  // of identity.js; only its shape changed, and a detector blind to the shape
  // would have dropped the file from this list and called the note true.
  const REFUSES = /(?:\bdie\(|\bthrow\b|\berrs\.push\(|\berrors\.push\(|\bout\.push\(|\bfunction no\w+Message\()/;
  // Refusing because the field is ABSENT, which is what the note is about.
  // `epito validate` also refuses a repo that is present and malformed
  // ("must be owner/name"), and that one is not a readiness blocker at all —
  // it is an error the validator already reports on its own.
  const MISSING = /(?:is required|but no \[runtime\]\.repo)/;
  const refusesOverMissingRepo = (body) => {
    for (const m of body.matchAll(/\[runtime\]\.repo/g)) {
      const before = body.slice(Math.max(0, m.index - 200), m.index);
      const stmt = before.slice(before.lastIndexOf(";") + 1);
      // The phrasing can sit on either side of the field name ("is required",
      // "but no [runtime].repo"), so the window spans both.
      if (REFUSES.test(stmt) && MISSING.test(body.slice(Math.max(0, m.index - 100), m.index + 60))) return true;
    }
    return false;
  };
  const refusers = files
    .filter(([rel, body]) => rel !== "lib/readiness.js" && refusesOverMissingRepo(body))
    .map(([rel]) => rel);
  assert.deepEqual(refusers.sort(), Object.keys(OWNERS).sort(),
    "a file refuses over [runtime].repo that readiness.js's command list does not account for — update REPO_REQUIRED_BY (and OWNERS here) so the note stays true");
  const expected = [...new Set(Object.values(OWNERS).flat())];
  assert.deepEqual([...REPO_REQUIRED_BY].sort(), expected.sort(),
    "REPO_REQUIRED_BY and the commands those files speak for have diverged");
});

test("loadRoster is where `epito run` and `epito ps <dir>` refuse, and it names the field", () => {
  const d = tmpDir();
  writeFileSync(join(d, "agent.toml"), `[agent]
name = "digest"
description = "One sentence."
[identity]
scopes = ["github:contents"]
[trigger]
cron = "0 6 * * *"
[runtime]
model = "claude-sonnet-5"
entry = "prompts/digest.md"
`);
  const errs = [];
  const realError = console.error, realExit = process.exit;
  console.error = (m) => errs.push(String(m));
  process.exit = () => { throw new Error("exited"); };
  try { loadRoster(d); } catch { /* the exit */ } finally { console.error = realError; process.exit = realExit; }
  assert.match(errs.join("\n"), /\[runtime\]\.repo is required by `epito run`/);
});

// --- [trigger].cron: parsed by the validator, not counted ------------------
//
// The one outright validator bug behind the false ✓, and the only one with no
// spec cover: the catalogue says "5-field cron, UTC", the validator counted
// five fields, and `epito run` then refused "0 99 * * *" when it built the
// matcher. One check now, so the two commands cannot disagree.

test("[trigger].cron with five impossible fields is refused by the validator, not just by `epito run`", () => {
  for (const [expr, why] of [
    ["0 99 * * *", /hour "99" is outside 0-23/],
    ["0 6 * *", /must have 5 fields, got 4/],
    ["*/0 6 * * *", /step must be >= 1/],
    ["0 6 * * xyz", /is not a number, \*, range, step, or list/],
  ]) {
    const errs = validateManifest(manifestFor({ repo: "a/b" }) && { ...manifestFor({ repo: "a/b" }), trigger: { cron: expr } }, { baseDir: tmpDir() });
    const cron = errs.filter((e) => e.startsWith("[trigger].cron"));
    assert.equal(cron.length, 1, `${expr}: expected exactly one cron error, got ${JSON.stringify(errs)}`);
    assert.match(cron[0], why);
    assert.match(cron[0], /Fix: five fields in UTC/, `${expr}: the cron error carries no fix`);
  }
});

test("every cron the three frozen seat shapes use still validates", () => {
  for (const expr of ["0 6 * * *", "0 7 * * 1", "*/15 * * * *", "0 0 1 1 *", "0 6 * * 0-5"]) {
    const m = { ...manifestFor({ repo: "a/b" }), trigger: { cron: expr } };
    assert.deepEqual(validateManifest(m, { baseDir: tmpDir() }), [], `${expr} was refused`);
  }
});

// --- origin: the repo init no longer has to ask for ------------------------

test("parseGitHubRemote reads the four spellings git writes, and refuses everything else", () => {
  for (const u of [
    "git@github.com:acme/product.git",
    "ssh://git@github.com/acme/product.git",
    "https://github.com/acme/product",
    "https://github.com/acme/product.git",
    "https://github.com/acme/product/",
    "https://token@github.com/acme/product.git",
  ]) assert.equal(parseGitHubRemote(u), "acme/product", `${u} did not read as acme/product`);

  for (const u of [
    "https://gitlab.com/acme/product.git",      // another platform is not a guess we make
    "git@bitbucket.org:acme/product.git",
    "https://github.com/acme",                  // no repo half
    "https://github.com.evil.test/acme/product", // not github.com
    "/srv/git/product.git",
    "", null, undefined,
  ]) assert.equal(parseGitHubRemote(u), null, `${JSON.stringify(u)} was read as a GitHub repo`);
});

test("a repo parsed off a remote is a value [runtime].repo itself accepts", () => {
  // The whole point is that init writes it into a manifest, so a value this
  // returns and the validator refuses would be worse than no value at all.
  const repo = parseGitHubRemote("git@github.com:acme/product.git");
  assert.deepEqual(validateManifest(manifestFor({ repo }), { baseDir: tmpDir() }), []);
  assert.deepEqual(blockers(manifestFor({ repo })), []);
});

test("originRepo returns null outside a git repo instead of throwing", () => {
  assert.equal(originRepo(tmpDir()), null);
});

// --- `epito validate <dir>`: the roster's own rules, and the one invariant that
// --- makes --for-runtime's claim true ------------------------------------

test("every rule a roster adds has a severity in `epito validate`", () => {
  // The claim `epito validate <dir> --for-runtime` makes is that it refuses
  // exactly what `epito run <dir>` refuses, minus the engine. That holds only
  // while every rule roster.js can emit is one validate.js knows about: a rule
  // missing from SEVERITY would be a rule `epito run` refuses and the strict
  // gate passes in silence, which makes the gate a lie rather than a gate.
  //
  // src/validate.js throws at import if this is ever false, so reaching this
  // line already proves it — the assertion is here so the failure reads as a
  // test about the rule set rather than as a module that would not load.
  for (const r of ROSTER_RULES) {
    assert.ok(SEVERITY[r], `roster rule "${r}" has no severity in src/validate.js`);
    assert.ok(["error", "note"].includes(SEVERITY[r]), `severity "${SEVERITY[r]}" for rule "${r}" is neither an error nor a note`);
  }
  assert.deepEqual(Object.keys(SEVERITY).sort(), [...ROSTER_RULES].sort(),
    "SEVERITY and ROSTER_RULES name different rules, so one of them is describing a rule that does not exist");
});

test("rosterRules: a seat with no [runtime].repo trips the repo rule, once", () => {
  const rules = rosterRules(manifestFor(), { path: "agents/a/agent.toml", takenBy: new Map() });
  assert.deepEqual(rules.map((r) => r.rule), ["repo"]);
  assert.match(rules[0].message, /\[runtime\]\.repo is required by `epito run`/);
});

test("rosterRules: a seat WITH a repo and a free name trips nothing", () => {
  assert.deepEqual(rosterRules(manifestFor({ repo: "acme/product" }), { path: "x", takenBy: new Map() }), []);
});

test("rosterRules: two manifests, one [agent].name — spec rule 4, naming the first file", () => {
  const m = manifestFor({ repo: "acme/product" });
  const takenBy = new Map([[m.agent.name, "agents/first/agent.toml"]]);
  const rules = rosterRules(m, { path: "agents/second/agent.toml", takenBy });
  assert.deepEqual(rules.map((r) => r.rule), ["name"]);
  assert.match(rules[0].message, /one manifest, one principal/, "the rule is not named in the spec's words");
  assert.match(rules[0].message, /agents\/first\/agent\.toml/, "the message does not say which file claimed the name first");
  // A refusal, not a note: no --for-runtime should be needed to hear that two
  // seats are asking for one identity.
  assert.equal(SEVERITY.name, "error");
});

test("rosterRules: the two rules are independent and both report", () => {
  const m = manifestFor();                       // no repo
  const takenBy = new Map([[m.agent.name, "agents/first/agent.toml"]]);
  assert.deepEqual(rosterRules(m, { path: "p", takenBy }).map((r) => r.rule), ["repo", "name"]);
});

test("rosterRules tolerates a manifest that did not parse", () => {
  // loadRoster calls it with whatever loadManifest returned, and a file that is
  // not TOML returns manifest: null. A roster of four must still report the
  // other three rather than dying on the first unparseable one.
  for (const m of [null, undefined, {}, { runtime: null }]) {
    assert.deepEqual(rosterRules(m, { path: "p", takenBy: new Map() }), []);
  }
});

test("checkManifest spells the readiness fix with the path the reader typed", () => {
  // findManifests returns absolute paths. Before `as` was threaded through,
  // the fix for a seat in agents/okr named a /tmp path nobody had typed, which
  // fails the error-message bar: the fix has to be an instruction you can run.
  const d = tmpDir();
  writeFileSync(join(d, "agent.toml"), `[agent]
name = "okr"
description = "One sentence."

[identity]
scopes = ["github:contents"]

[trigger]
cron = "0 6 * * *"

[runtime]
model = "claude-sonnet-5"
entry = "prompts/okr.md"
`);
  mkdirSync(join(d, "prompts"), { recursive: true });
  writeFileSync(join(d, "prompts", "okr.md"), "# okr\n");

  const r = checkManifest(join(d, "agent.toml"), { as: "agents/okr/agent.toml" });
  assert.deepEqual(r.errors, [], `a valid manifest was refused: ${r.errors.join("; ")}`);
  assert.equal(r.blocks.length, 1, "the missing [runtime].repo should be one readiness note");
  assert.match(r.blocks[0].fix, /in agents\/okr\/agent\.toml/);
  assert.doesNotMatch(r.blocks[0].fix, new RegExp(d.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")),
    "the fix names the absolute path the reader never typed");
});

test("checkManifest does not ask what a refused manifest would be ready for", () => {
  const d = tmpDir();
  writeFileSync(join(d, "agent.toml"), '[agent]\nname = "x"\n');
  const r = checkManifest(join(d, "agent.toml"));
  assert.ok(r.errors.length > 0, "a manifest with no triad should be refused");
  assert.deepEqual(r.blocks, [], "readiness was computed for a file that is not a manifest");
  assert.deepEqual(r.notes, []);
});

test("checkManifest names an unparseable file by the path the reader typed", () => {
  const d = tmpDir();
  writeFileSync(join(d, "agent.toml"), "[agent\nname = 'x'\n");
  const r = checkManifest(join(d, "agent.toml"), { as: "agents/pm/agent.toml" });
  assert.ok(r.parseError, "a broken TOML file should report a parse error");
  assert.match(r.errors[0], /^agents\/pm\/agent\.toml is not valid TOML/);
});

test("one shape() describes a manifest, so a seat cannot read two ways", () => {
  // The single-manifest ✓ and the roster's column are the same string by
  // construction. This is the acceptance test for factoring `epito validate`
  // out of index.js: the wording that already shipped is the wording both use.
  assert.equal(shape(manifestFor({ repo: "acme/product" })), "identity (1 scope), trigger, runtime");
  assert.equal(shape(manifestFor({}, { scopes: ["github:contents", "github:pull_requests"] })),
    "identity (2 scopes), trigger, runtime");
  // The adapter is named only when it is not the default, so every manifest
  // written before adapters existed reads exactly as it always did.
  assert.equal(shape(manifestFor({ adapter: "claude" })), "identity (1 scope), trigger, runtime");
  assert.match(shape(manifestFor({ adapter: "langgraph", graph: "agent" })), / — a langgraph agent$/);
});

// --- the engine as a fact about the box ------------------------------------
//
// `epito validate agents --for-runtime` used to tick five seats and say "there
// is nothing here `epito run agents` would refuse" on a machine where `epito
// run agents --dry-run` refused in one line, before it read a manifest,
// because nothing was answering at 127.0.0.1:7233. These assert the two
// halves of the fix: that the look needs no engine, and that the sentence
// cannot drift from the two commands that already had to say it.

test("the unreachable-engine sentence exists once, and both clients use that one", () => {
  // The same dead port used to read as "ECONNREFUSED" from `epito run` and as
  // a nested Rust string from `epito worker`, because each file had its own
  // copy of the sentence AND its own reason-extraction. The copies are the
  // drift; this is the assertion that they stay gone. Same rule as
  // REPO_REQUIRED_BY: the thing the message prints is the thing the test
  // checks the source against.
  const src = (f) => readFileSync(fileURLToPath(new URL(`../src/${f}`, import.meta.url)), "utf8");
  for (const f of ["temporal/client.js", "temporal/worker.js"]) {
    assert.ok(!/no Temporal server answering at/.test(src(f)),
      `src/${f} has grown its own copy of the unreachable-engine sentence again — it belongs in lib/engine.js, once`);
    assert.match(src(f), /engineUnreachableMessage/,
      `src/${f} no longer calls engineUnreachableMessage, so the two clients can disagree about a dead port again`);
    assert.ok(!/^function connectReason/m.test(src(f)),
      `src/${f} has its own connectReason again — one dead port, one name for it`);
  }
  assert.match(src("lib/engine.js"), /no Temporal server answering at/,
    "lib/engine.js is supposed to be the one place the sentence lives");
});

test("the engine fix names nothing the reader does not have", () => {
  // `runtime/temporal/install.sh` is HQ's file (alexandra-systems). It is in
  // neither this repository nor `npm i -g epito`, whose package.json `files`
  // ships src, adapters and README.md — so the product's most likely first
  // refusal told you to run a script that exists on no machine you have,
  // which is worse than naming no fix, because it sends you looking. A path
  // is only a fix if the reader has the path.
  const fix = engineFix();
  assert.ok(!/runtime\/temporal\/install\.sh/.test(fix),
    "the fix names HQ's runtime/temporal/install.sh, which the reader does not have");
  assert.match(fix, /temporal server start-dev/, "the fix no longer names the one command a laptop can run");
  // Every repository path the fix names has to be in THIS repository, and
  // named with the repository, since an npm install ships none of them.
  const repoRootDir = fileURLToPath(new URL("../../", import.meta.url));
  for (const [, p] of fix.matchAll(/\b((?:docs|deploy|spec|prompts|agents)\/[\w./-]+)/g)) {
    assert.ok(existsSync(join(repoRootDir, p)), `the engine fix names ${p}, which is not in this repository`);
    assert.match(fix, /github\.com\/[\w-]+\/[\w-]+/,
      `the engine fix names the repository path ${p} without naming the repository, and \`npm i -g epito\` ships no docs`);

    // The path existing is not the same as the reader arriving somewhere. The
    // fix used to name a file that existed and whose named section's third
    // column said "docker, via HQ `runtime/temporal/install.sh`" — so the
    // dead end moved one hop instead of closing, and this test passed the
    // whole time it was open. ADR-24's corollary has to hold at the
    // DESTINATION too, or it only ever held for one string.
    const dest = readFileSync(join(repoRootDir, p), "utf8");
    assert.ok(!/runtime\/temporal\/install\.sh/.test(dest),
      `the engine fix sends the reader to ${p}, and ${p} sends them on to HQ's runtime/temporal/install.sh — a file they still do not have`);

    // And if the fix names a heading inside that file, the heading has to be
    // in it. "see this file, section X" is a dead end the moment X is renamed.
    for (const [, heading] of fix.matchAll(/"([^"]+)"/g)) {
      assert.ok(dest.includes(heading),
        `the engine fix sends the reader to "${heading}" in ${p}, which has no such heading`);
    }
  }
});

test("no operator-facing path in the repository hands the reader HQ's installer", () => {
  // The CLI's one string is not the only place epito tells an operator how to
  // get an engine: deploy/provision-host.sh prints a five-step NEXT block on
  // the real host, and docs/deploy/README.md is what the refusal names. All
  // three used to end at alexandra-systems' runtime/temporal/install.sh.
  // Comments that explain the history are fine and necessary (lib/engine.js,
  // decisions.md, this file); instructions are not.
  const repoRootDir = fileURLToPath(new URL("../../", import.meta.url));
  for (const f of ["deploy/provision-host.sh", "docs/deploy/README.md", "Dockerfile"]) {
    assert.ok(!/runtime\/temporal\/install\.sh/.test(readFileSync(join(repoRootDir, f), "utf8")),
      `${f} tells an operator to run HQ's runtime/temporal/install.sh, which ships in neither this repository nor npm`);
  }
  // And the engine section the refusal names has to carry a command, not just
  // a statement that the engine is somebody else's problem.
  const readme = readFileSync(join(repoRootDir, "docs/deploy/README.md"), "utf8");
  assert.match(readme, /^## Temporal server \+ UI$/m,
    "docs/deploy/README.md lost the heading lib/engine.js's fix line names");
  assert.match(readme, /temporal server start-dev/,
    "the engine section names no command the reader can run");
});

test("asking whether the engine is up pulls in no engine", async () => {
  // This is the invariant behind "no engine required", and it is stronger than
  // the assertion it replaced in smoke-validate.sh (which checked that the
  // output never said the word "temporal"). What must be true is that the
  // module `epito validate` reaches the address through imports nothing —
  // otherwise a future edit to temporal/env.js could quietly make the manifest
  // commands need the ~300 MB of engine that cli/package.json exists to avoid
  // shipping.
  const env = readFileSync(fileURLToPath(new URL("../src/temporal/env.js", import.meta.url)), "utf8");
  assert.ok(!/^import /m.test(env),
    "src/temporal/env.js has grown an import — lib/engine.js reads the address from it, so an @temporalio import there would make `epito validate` need the engine");
  const engine = readFileSync(fileURLToPath(new URL("../src/lib/engine.js", import.meta.url)), "utf8");
  for (const [, spec] of engine.matchAll(/^import .*? from "([^"]+)"/gm)) {
    assert.ok(spec.startsWith("node:") || spec.startsWith("."),
      `src/lib/engine.js imports ${spec}; it may import only node builtins and engine-free local modules`);
  }
});

test("the probe reports what a TCP connect actually proves", async () => {
  const srv = createTcpServer();
  await new Promise((r) => srv.listen(0, "127.0.0.1", r));
  const port = srv.address().port;
  after(() => srv.close());

  const up = await engineAnswering(`127.0.0.1:${port}`);
  assert.equal(up.ok, true, "a listening port should read as answering");
  assert.equal(up.malformed, false);

  // Port 1 on loopback: refused immediately, which is the laptop case.
  const down = await engineAnswering("127.0.0.1:1");
  assert.equal(down.ok, false);
  assert.equal(down.malformed, false);
  assert.match(engineMissing(down), /nothing is answering at 127\.0\.0\.1:1/);

  // A malformed address is a wrong variable, not a dead network, and saying
  // "nothing is answering at garbage" would send an operator to look at the
  // wrong thing.
  const bad = await engineAnswering("garbage");
  assert.equal(bad.ok, false);
  assert.equal(bad.malformed, true);
  assert.match(engineMissing(bad), /TEMPORAL_ADDRESS is "garbage", which is not a host:port address/);
  assert.ok(!/answering/.test(engineMissing(bad)), "a malformed address should not be described as a dead engine");

  // The ceiling is the point: a validator that hangs to tell you your files
  // are fine is a validator people stop running. 198.51.100.x is TEST-NET-2
  // (RFC 5737) and is not routed, so this is a timeout and not a refusal.
  const t0 = Date.now();
  const slow = await engineAnswering("198.51.100.1:7233", { timeoutMs: 150 });
  assert.equal(slow.ok, false);
  assert.ok(Date.now() - t0 < 2000, `the probe took ${Date.now() - t0}ms; it is supposed to cap at its timeout`);
});

test("splitAddress handles the forms TEMPORAL_ADDRESS takes", () => {
  assert.deepEqual(splitAddress("127.0.0.1:7233"), { host: "127.0.0.1", port: 7233 });
  assert.deepEqual(splitAddress("temporal.internal:7233"), { host: "temporal.internal", port: 7233 });
  // The bracketed IPv6 form, which a lastIndexOf(":") alone would cut in half.
  assert.deepEqual(splitAddress("[::1]:7233"), { host: "::1", port: 7233 });
  for (const bad of ["", "7233", "host:", ":7233", undefined]) {
    assert.ok(!splitAddress(bad).host || Number.isNaN(splitAddress(bad).port), `"${bad}" should not parse as host:port`);
  }
});

test("the sentence says which address, and whether the address is the suspect", () => {
  const dflt = engineUnreachableMessage(DEFAULT_ADDRESS, "ECONNREFUSED");
  assert.match(dflt, /^no Temporal server answering at 127\.0\.0\.1:7233 \(ECONNREFUSED\)/);
  assert.match(dflt, /set TEMPORAL_ADDRESS if your engine is somewhere other than/);
  // A wrong TEMPORAL_ADDRESS is the one cause an operator cannot see — a stale
  // export, or an /srv/asc/env copied between boxes, looks exactly like a dead
  // engine. So when the address is not the default, the variable is named as a
  // suspect and the fallback is spelled out.
  const custom = engineUnreachableMessage("10.0.0.5:7233", "ECONNREFUSED");
  assert.match(custom, /point TEMPORAL_ADDRESS at the engine you have — it is currently 10\.0\.0\.5:7233/);
  assert.match(custom, /unsetting it falls back to 127\.0\.0\.1:7233/);
});

test("connectReason reads both transports' idea of a dead port", () => {
  // @temporalio/client: an error with a cause.code.
  assert.equal(connectReason({ cause: { code: "ECONNREFUSED" } }), "ECONNREFUSED");
  // @temporalio/worker's native connection: a nested Rust string.
  assert.equal(connectReason({ message: 'transport error: ConnectError("tcp connect error")' }), "tcp connect error");
  assert.equal(connectReason({ cause: { message: 'status: Unavailable, message: "Failed to connect before the deadline"' } }),
    "Failed to connect before the deadline");
  // Anything else comes through whole rather than as "[object Object]".
  assert.equal(connectReason({ message: "something else entirely" }), "something else entirely");
});

// --- what a roster asks of the box ----------------------------------------
// `epito env`'s half that needs no box: given a roster and an environment,
// which names does this machine owe each seat, and what is it doing about
// them. The silence this closes is in runner.js's one line — the runtime
// injects only the names it HOLDS, so a box short of one produces a seat that
// runs, exits 0, and quietly does less (src/lib/boxenv.js tells the story).

const rosterOf = (...manifests) => new Map(manifests.map((m) => [m.agent.name, { manifest: m, path: `${m.agent.name}/agent.toml` }]));

test("rosterEnv: one row per name, who asks for it, and what this box is doing about it", () => {
  const pm = seat("pm", { runtime: {
    model: "claude-sonnet-5", entry: "prompts/pm.md", repo: "acme/roster",
    env: ["SLACK_WEBHOOK_URL", "BOARD_API_URL", "GATEWAY_URL", "GATEWAY_KEY"],
    route: [
      { name: "open", model: "kimi", base_url_env: "GATEWAY_URL", token_env: "GATEWAY_KEY" },
      { name: "subscription", model: "claude-sonnet-5" },
    ],
  } });
  const okr = seat("okr", { runtime: { model: "m", entry: "e", repo: "acme/roster", env: ["SLACK_WEBHOOK_URL"] } });
  const r = rosterEnv(rosterOf(pm, okr), { SLACK_WEBHOOK_URL: "https://hooks.example/x", BOARD_API_URL: "" });

  assert.deepEqual(r.names.map((x) => x.name), ["BOARD_API_URL", "GATEWAY_KEY", "GATEWAY_URL", "SLACK_WEBHOOK_URL"],
    "alphabetical, because what is generated from it is a file of KEY= lines read by eye");
  assert.deepEqual(r.names.map((x) => x.state), [EMPTY, ABSENT, ABSENT, HELD]);
  // The three states, and the one that is neither "here" nor "not here": an
  // env-file line somebody half filled in. The runtime injects it, empty.
  assert.equal(holding("BOARD_API_URL", { BOARD_API_URL: "" }), EMPTY);
  assert.equal(holding("BOARD_API_URL", {}), ABSENT);
  assert.equal(holding("BOARD_API_URL", { BOARD_API_URL: "x" }), HELD);

  const hook = r.names.find((x) => x.name === "SLACK_WEBHOOK_URL");
  assert.deepEqual(hook.uses.map((u) => u.agent), ["pm", "okr"], "every seat that asks is named");
  assert.equal(hook.uses[0].role, "the one-line post after every run");
  assert.equal(r.names.find((x) => x.name === "GATEWAY_URL").uses[0].role, 'the endpoint for route "open"',
    "a road's halves say which road, so the reader knows to go read `epito routes`");
  assert.equal(r.names.find((x) => x.name === "GATEWAY_KEY").uses[0].role, 'the key for route "open"');

  const pmRow = r.seats.find((s) => s.agent === "pm");
  assert.deepEqual(pmRow.held, ["SLACK_WEBHOOK_URL"]);
  assert.deepEqual(pmRow.missing, ["GATEWAY_URL", "GATEWAY_KEY"]);
  assert.deepEqual(pmRow.empty, ["BOARD_API_URL"]);
  assert.deepEqual(pmRow.short, ["BOARD_API_URL", "GATEWAY_URL", "GATEWAY_KEY"], "short is everything the run will not get, whichever way");
  assert.deepEqual(r.seats.find((s) => s.agent === "okr").short, [], "a seat whose names are all here gets no line");
});

test("namesFor unions a road's halves rather than trusting another file's rule", () => {
  // The validator refuses a token_env or base_url_env that is not also in
  // [runtime].env. This reader is what an operator fills a box in from, so a
  // name missing because of a rule enforced elsewhere is a name they will not
  // put in the file — and the adapter reads a route's key out of the box's
  // environment directly either way.
  const m = seat("pm", { runtime: {
    model: "m", entry: "e", repo: "acme/roster", env: [],
    route: [{ name: "open", model: "kimi", base_url_env: "GW_URL", token_env: "GW_KEY" }],
  } });
  assert.deepEqual(namesFor(m), ["GW_URL", "GW_KEY"]);
  assert.deepEqual(namesFor(seat("pm")), [], "and a manifest that names nothing asks the box for nothing");
});

test("the env template covers every name the manifests ask for, and blanks none that are set", () => {
  const pm = seat("pm", { runtime: { model: "m", entry: "e", repo: "acme/roster", env: ["HELD_ONE", "MISSING_ONE"] } });
  const env = { HELD_ONE: "a-real-value-nobody-should-see" };
  const out = envTemplate(rosterEnv(rosterOf(pm), env), { dir: "agents" });
  assert.match(out, /^MISSING_ONE=$/m, "a name the box lacks is a line to fill in");
  assert.match(out, /^# HELD_ONE=/m, "a name the box HAS comes out commented");
  assert.match(out, /pasting this cannot blank it/, "and says why, because that is the failure it avoids");
  assert.ok(!out.includes("a-real-value-nobody-should-see"), "the template is names only — it is pasted into the one file secrets live in");
  assert.match(out, /# pm$/m, "each name says which seats asked for it");
  assert.match(out, /systemd EnvironmentFile/, "and what kind of file this is");
});

test("runShortfall: what ONE run is short of, and the three things that are not a shortfall", () => {
  const m = seat("pm", { runtime: {
    model: "m", entry: "e", repo: "acme/roster",
    env: ["HELD", "ABSENT_ONE", "EMPTY_ONE", "GH_TOKEN", "GW_URL", "GW_KEY"],
    route: [
      { name: "open", model: "kimi", base_url_env: "GW_URL", token_env: "GW_KEY" },
      { name: "subscription", model: "m" },
    ],
  } });
  const env = { HELD: "yes", EMPTY_ONE: "" };
  const r = runShortfall(m, env, { injected: ["GH_TOKEN"] });
  assert.deepEqual(r.missing, ["ABSENT_ONE"]);
  assert.deepEqual(r.empty, ["EMPTY_ONE"], "set to nothing is a shortfall, and the expensive one: the agent acts on it");
  assert.deepEqual(r.short, ["ABSENT_ONE", "EMPTY_ONE"]);
  // 1. A name the run brings with it. 2. A road's two halves — that box fault
  // is a closed road, and the router says so in its own vocabulary. 3. A name
  // the box holds.
  assert.ok(!r.short.includes("GH_TOKEN"));
  assert.ok(!r.short.includes("GW_KEY") && !r.short.includes("GW_URL"));
  assert.ok(!r.short.includes("HELD"));
  // Without the mint, the same box IS short of the credential — which is the
  // difference between a seat with an App of its own and one without.
  assert.ok(runShortfall(m, env).short.includes("GH_TOKEN"));
  assert.deepEqual(runShortfall(seat("pm"), {}).short, [], "a manifest that names nothing is short of nothing");
});

test("the shortfall is one sentence, and the agent's copy of it is the only one in the second person", () => {
  const both = { missing: ["BOARD_RUNTIME_TOKEN"], empty: ["LINEAR_API_KEY"] };
  // The operator's register, in two subjects: a seat read off a roster, and
  // one run read out of its own log.
  assert.equal(shortfallSays(both), "BOARD_RUNTIME_TOKEN is not available to its runs; LINEAR_API_KEY arrives empty");
  assert.equal(shortfallSays(both, { of: "this run" }), "BOARD_RUNTIME_TOKEN is not available to this run; LINEAR_API_KEY arrives empty");
  assert.equal(shortfallSays({ missing: ["A", "B"], empty: [] }), "A, B are not available to its runs");
  assert.equal(shortfallSays({ missing: [], empty: ["A", "B"] }), "A, B arrive empty");
  assert.equal(shortfallSays({ missing: [], empty: [] }), "", "a seat that is short of nothing says nothing");

  // The agent's copy. It says what was dropped and WHY it is dropped, in the
  // second person, and stops: `[runtime].env` is the list the runtime injects
  // FROM, not a list of what a seat cannot work without, so the only party
  // that knows whether this matters is the charter the agent is about to read.
  const line = shortfallLine(both);
  assert.match(line, /BOARD_RUNTIME_TOKEN is not set on this box, so it is not in your environment at all/);
  assert.match(line, /LINEAR_API_KEY is set to nothing, so it reaches you empty/);
  assert.match(line, /say in your run that this box is short of it rather than working around it silently/);
  assert.equal(shortfallLine({ missing: [], empty: [] }), "", "and a box that holds every name says nothing to the agent either");
  assert.equal(shortfallLine(undefined), "", "an older caller that passes no shortfall gets no line, not a crash");
  assert.match(shortfallLine({ missing: ["A", "B"], empty: [] }), /A, B are not set on this box, so they are not in your environment at all/);
  // The preamble has to survive a run with nothing wrong: the line is dropped
  // entirely rather than left as an empty paragraph.
  const clean = buildPrompt({ name: "pm", entry: "prompts/pm.md", trigger: "cron", date: "2026-10-11", shortfall: { missing: [], empty: [] } });
  assert.ok(!clean.includes("does not hold every name"));
  assert.ok(!/\n\n/.test(clean), "no blank line where the shortfall would have been");
  const told = buildPrompt({ name: "pm", entry: "prompts/pm.md", trigger: "cron", date: "2026-10-11", shortfall: both });
  assert.match(told, /This run was triggered by: cron\.\nThis box does not hold every name/,
    "it arrives after the trigger and before any window instruction, which is the order a reader of the prompt expects");
});

test("`epito run` says the roster's shortfall before it touches the engine", () => {
  const pm = seat("pm", { runtime: { model: "m", entry: "e", repo: "acme/roster", env: ["SLACK_WEBHOOK_URL", "BOARD_API_URL"] } });
  const okr = seat("okr", { runtime: { model: "m", entry: "e", repo: "acme/roster", env: ["SLACK_WEBHOOK_URL"] } });
  const roster = rosterOf(pm, okr);
  const held = { SLACK_WEBHOOK_URL: "https://hooks.example/x" };

  const said = [];
  const before = process.env.BOARD_API_URL; delete process.env.BOARD_API_URL;
  const beforeHook = process.env.SLACK_WEBHOOK_URL; process.env.SLACK_WEBHOOK_URL = held.SLACK_WEBHOOK_URL;
  try {
    sayShortfall(roster, "agents", (m) => said.push(m));
    const out = said.join("\n");
    assert.match(out, /^1 of 2 seats runs here short of a name its manifest asks this box to hold:/m);
    assert.match(out, /! pm: BOARD_API_URL is not available to its runs/);
    assert.ok(!/! okr/.test(out), "a seat whose names are all here gets no line");
    assert.match(out, /`epito env agents` is the whole report/);
    // The rehearsal must not disagree with the thing it rehearses, and the
    // real `epito run` registers these schedules: this block is a report,
    // which is why it borrows none of reconcile's words.
    assert.ok(!/would (create|update|delete)/.test(out));

    said.length = 0;
    process.env.BOARD_API_URL = "https://board.example";
    sayShortfall(roster, "agents", (m) => said.push(m));
    assert.deepEqual(said, [], "a box that holds every name gets a silent rehearsal: `epito env` is where \"and it holds all 7\" belongs");
  } finally {
    if (before === undefined) delete process.env.BOARD_API_URL; else process.env.BOARD_API_URL = before;
    if (beforeHook === undefined) delete process.env.SLACK_WEBHOOK_URL; else process.env.SLACK_WEBHOOK_URL = beforeHook;
  }
});

test("a run says which of its declared names the box did not have", async () => {
  const dir = tmpDir();
  const cwd = process.cwd();
  process.chdir(dir);
  const work = mkdtempSync(cloneDirPrefix("pm"));
  const said = [];
  try {
    const agent = seat("pm", { runtime: {
      model: "m", entry: "e", repo: "acme/roster",
      env: ["EPITO_STUB_DIR", "BOARD_RUNTIME_TOKEN", "LINEAR_API_KEY", "GH_TOKEN", "GW_KEY"],
      route: [
        { name: "open", model: "kimi", base_url_env: "GW_URL", token_env: "GW_KEY" },
        { name: "subscription", model: "m" },
      ],
    } });
    process.env.EPITO_STUB_DIR = join(dir, "stub");
    delete process.env.BOARD_RUNTIME_TOKEN;
    // The third state, and the one this log was blind to: an env-file line
    // somebody half filled in. It reaches the run as "", so `baseEnv[k] ===
    // undefined` called it held and said nothing.
    process.env.LINEAR_API_KEY = "";
    const r = await executeAgent({
      agent, trigger: "cron", runId: "r-env-1", workDir: work, timeoutMs: 30_000, log: (m) => said.push(m),
      executor: new URL("./stub-executor.mjs", import.meta.url).pathname,
      // The mint supplies GH_TOKEN, so the box not holding it is not the box
      // being short of it — which is why `inject` is read when the line is
      // computed, not just when the child's environment is built.
      inject: { GH_TOKEN: "ghs_ENVTESTTOKEN0000000000000000000" }, redact: ["ghs_ENVTESTTOKEN0000000000000000000"],
    });
    assert.equal(r.exit, 0, "the run goes ahead without it: a roster is portable, and this is a note");
    const logged = readFileSync(r.log, "utf8");
    assert.match(logged, /# env missing: BOARD_RUNTIME_TOKEN is not available to this run; LINEAR_API_KEY arrives empty/);
    assert.match(logged, /listed in \[runtime\]\.env and not held as asked on this box/);
    assert.ok(!/env missing:.*GH_TOKEN/.test(logged), "a name this run mints for itself is not a name the box is short of");
    assert.ok(!/env missing:.*GW_KEY/.test(logged),
      "a road's own half is a CLOSED ROAD, said by the route lines a few lines up, not a second sentence here");
    assert.match(logged, /route "open" \(kimi\) skipped: GW_KEY is not set on this machine/,
      "and the route lines really are the ones that say it");
    assert.ok(said.some((m) => /pm: 2 names from \[runtime\]\.env are not what this box holds \(BOARD_RUNTIME_TOKEN, LINEAR_API_KEY\)/.test(m)),
      "and the operator watching journalctl hears it, not only the log file");

    // The party that was never told: the agent. The stub records the prompt it
    // was handed, so this is the prompt the child really received rather than
    // what buildPrompt can be made to say in isolation.
    const transcript = readdirSync(join(dir, "stub")).filter((f) => f.endsWith(".jsonl"));
    assert.equal(transcript.length, 1);
    const handed = JSON.parse(readFileSync(join(dir, "stub", transcript[0]), "utf8").trim().split("\n")[0]).prompt;
    assert.match(handed, /BOARD_RUNTIME_TOKEN is not set on this box, so it is not in your environment at all/);
    assert.match(handed, /LINEAR_API_KEY is set to nothing, so it reaches you empty/);
    assert.ok(!handed.includes("GH_TOKEN"), "the credential the run minted for itself is not a name the agent is short of");
    assert.ok(!handed.includes("GW_KEY"), "and a closed road is the router's sentence, not the agent's problem to route around");
  } finally {
    process.chdir(cwd);
    rmSync(work, { recursive: true, force: true });
    delete process.env.EPITO_STUB_DIR;
    delete process.env.LINEAR_API_KEY;
  }
});

test("a road's credential set to NOTHING is a line to fix, not a road this box never had", () => {
  const route = { name: "open", model: "kimi", baseUrl: null, baseUrlEnv: "GW_URL", tokenEnv: "GW_KEY", concurrency: null };
  // Absent: routing working as designed, and no box has to be corrected.
  const gone = liveRoutes([route], {});
  assert.equal(gone.skipped[0].misconfigured, false);
  assert.match(gone.skipped[0].reason, /^GW_KEY is not set on this machine$/);
  // Blank: an env-file line with nothing after the =, which is a box that HAS
  // this one and has it wrong. `epito env` calls it "set and set to nothing"
  // and refuses; this is the same box, so it cannot be called unset here.
  const blank = liveRoutes([route], { GW_KEY: "", GW_URL: "https://gw.test/x" });
  assert.equal(blank.skipped[0].misconfigured, true);
  assert.match(blank.skipped[0].reason, /GW_KEY is set on this machine and holds nothing/);
  assert.doesNotMatch(blank.skipped[0].reason, /is not set on this machine/);
  // And the endpoint half, the same way.
  const noUrl = resolveEndpoint({ ...route, tokenEnv: null }, { GW_URL: "   " });
  assert.equal(noUrl.misconfigured, true);
  assert.match(noUrl.problem, /GW_URL is set on this machine and holds nothing/);
  assert.equal(resolveEndpoint({ ...route, tokenEnv: null }, {}).misconfigured, false);
});

// ─────────────────────────────────────────────────────────────────────────────
// `epito doctor`: the preflight, and the piece of it nothing checked before.

test("the environment a run gets is one list, and runner.js no longer spells it", () => {
  const m = seat("pm", { runtime: { model: "m", entry: "e", repo: "acme/roster", env: ["HELD_NAME", "ABSENT_NAME"] } });
  const env = { PATH: "/bin", HOME: "/home/pm", USER: "pm", HELD_NAME: "yes", UNASKED: "no" };
  const built = baseRunEnv(m, env);
  assert.deepEqual(Object.keys(built).sort(), ["HELD_NAME", "HOME", "PATH", "USER"],
    "the allowlist is PATH, HOME, USER plus the [runtime].env names this box holds — and nothing else reaches the child");
  assert.equal("ABSENT_NAME" in built, false, "a name the box does not hold is dropped, not faked: that is what keeps a roster portable");
  assert.deepEqual(RUNTIME_GIVEN, ["PATH", "HOME", "USER"]);
  // The drift this module exists to prevent: a probe that spawns the executor
  // under its OWN idea of the run environment proves nothing about a run. The
  // list is read from one place by both, and this is what fails if a second
  // copy appears.
  const runnerSrc = readFileSync(fileURLToPath(new URL("../src/lib/runner.js", import.meta.url)), "utf8");
  assert.ok(!/PATH:\s*process\.env\.PATH/.test(runnerSrc),
    "src/lib/runner.js has grown its own copy of the child's env allowlist again — it belongs in lib/runenv.js, once, because `epito doctor` spawns the executor under the same one");
  assert.match(runnerSrc, /baseRunEnv\(agent, process\.env\)/,
    "src/lib/runner.js no longer builds the child's environment through baseRunEnv, so the preflight and the run can disagree about what a run gets");
});

test("the executor is resolved on the PATH a RUN gets, and the two failures are different fixes", () => {
  const dir = mkdtempSync(join(tmpdir(), "epito-which-"));
  after(() => rmSync(dir, { recursive: true, force: true }));
  const good = join(dir, "claude");
  writeFileSync(good, "#!/bin/sh\nexit 0\n", { mode: 0o755 });
  const dull = join(dir, "dull");
  writeFileSync(dull, "#!/bin/sh\nexit 0\n", { mode: 0o644 });

  assert.equal(whichIn("claude", { PATH: dir }).path, good);
  assert.equal(whichIn("claude", { PATH: "/nowhere-at-all" }).path, null);
  assert.match(whichIn("claude", { PATH: "/nowhere-at-all" }).reason,
    /"claude" is not on the PATH a run gets \(1 directory\)/);
  // There and not executable is not the same mistake as not there, and every
  // other tool says one word for both.
  assert.equal(whichIn("dull", { PATH: dir }).path, null);
  assert.match(whichIn("dull", { PATH: dir }).reason, /is on the PATH a run gets and is not executable by this user/);
  // An empty PATH is the systemd unit case: a service with no Environment=PATH
  // resolves no bare name at all, and "not found" would send the reader
  // looking for a missing install.
  assert.match(whichIn("claude", {}).reason, /the PATH a run gets is empty/);
  // An absolute path skips the search and is stat'd where it says.
  assert.equal(whichIn(good, {}).path, good);
  assert.match(whichIn(join(dir, "ghost"), {}).reason, /no such file/);
});

test("the look spawns the real binary under the run's own environment, and says what that proves", async () => {
  const dir = mkdtempSync(join(tmpdir(), "epito-look-"));
  after(() => rmSync(dir, { recursive: true, force: true }));
  const bin = join(dir, "claude");
  // Answers --version only when the name its credential lookup needs is in the
  // allowlist. That is epitod v0's first real run, in four lines.
  writeFileSync(bin, '#!/bin/sh\n[ -n "$NEEDED_NAME" ] || { echo "Not logged in" >&2; exit 1; }\necho "claude 9.9.9"\n', { mode: 0o755 });

  const without = seat("pm", { runtime: { model: "m", entry: "e", repo: "acme/roster" } });
  const r1 = await lookAtExecutor(without, { env: { PATH: dir, HOME: dir, USER: "pm", EPITO_EXECUTOR: bin, NEEDED_NAME: "x" } });
  assert.equal(r1.state, "broken", "the name is in the worker's environment and NOT in [runtime].env, so the child never sees it — which is the whole bug");
  assert.match(r1.says, /exited 1 on `--version` under the environment a run gives it: Not logged in/);
  assert.match(r1.fix, /only PATH, HOME, USER and this seat's \[runtime\]\.env/);

  const with_ = seat("pm", { runtime: { model: "m", entry: "e", repo: "acme/roster", env: ["NEEDED_NAME"] } });
  const r2 = await lookAtExecutor(with_, { env: { PATH: dir, HOME: dir, USER: "pm", EPITO_EXECUTOR: bin, NEEDED_NAME: "x" } });
  assert.equal(r2.state, "ok");
  assert.equal(r2.version, "claude 9.9.9", "the executor's own first line, so the report names what it found rather than that it found something");
  assert.match(r2.unproven, /that it is logged in/, "and the look never claims the half it did not look at");

  const gone = await lookAtExecutor(with_, { env: { PATH: dir, HOME: dir, USER: "pm", EPITO_EXECUTOR: "claude-nowhere" } });
  assert.equal(gone.state, "missing");
  assert.match(gone.fix, /EPITO_EXECUTOR/, "the fix names the variable that overrides it, with its current value");
});

test("every adapter has a probe, and the one that cannot have a one-turn probe says so", () => {
  // A new adapter with no probe would silently fall back to claude's
  // `--version`, which is a claim about an executable nobody checked. ADAPTERS
  // is the list; PROBES has to answer it.
  for (const name of ADAPTER_NAMES) {
    assert.ok(PROBES[name], `src/lib/probe.js has no probe for the "${name}" adapter, so \`epito doctor\` would check it with another adapter's argv`);
    assert.ok(PROBES[name].proves && PROBES[name].unproven,
      `the "${name}" probe does not say what it proves and what it does not, and a preflight that overclaims is worse than none`);
  }
  assert.equal(PROBES.langgraph.deep, false);
  assert.match(PROBES.langgraph.unproven, /read inside the run's clone/,
    "a LangGraph seat's graph lives in its own repository; no preflight on this box has it");
  assert.equal(probeFor("something-nobody-wrote").look.join(" "), "--version", "an unknown adapter still gets a probe rather than a crash");
});

test("the deep probe is keyed by what changes its answer, so seats sharing a road share one call", () => {
  const a = { name: "open", model: "kimi", baseUrl: null, baseUrlEnv: "GW_URL", tokenEnv: "GW_KEY", concurrency: null };
  const b = { ...a };
  assert.equal(deepKey("claude", a), deepKey("claude", b), "same binary, same road: one call stands in for both seats");
  assert.notEqual(deepKey("claude", a), deepKey("claude", { ...a, tokenEnv: "OTHER_KEY" }), "a different key is a different credential and has to be tried");
  assert.notEqual(deepKey("claude", a), deepKey("claude", { ...a, model: "other" }), "a model the provider may not have is a different answer");
  assert.notEqual(deepKey("claude", a), deepKey("python3", a), "and a different executor is a different question entirely");
  // The endpoint reaches the key by NAME, never by value: `epito routes` made
  // that rule for the same reason (a confidential gateway stays out of the
  // terminal), and a cache key printed in --json must obey it too.
  assert.ok(!deepKey("claude", a).includes("https://"));
});

test("the engine look falls back to the TCP answer when the engine client is not installed", async () => {
  const answering = () => Promise.resolve({ ok: true, address: "127.0.0.1:7233", malformed: false, reason: null });
  const notInstalled = () => {
    const e = new Error("Cannot find package '@temporalio/client' imported from /x/y.js");
    e.code = "ERR_MODULE_NOT_FOUND";
    throw e;
  };
  const tcp = await engineLook({ env: {}, probe: answering, importClient: notInstalled });
  assert.equal(tcp.depth, "tcp");
  assert.equal(tcp.client, false);
  assert.equal(tcp.ok, true, "a box without the engine packages is the ordinary case and is not a failure of anything");

  // Our own broken module is not an optional peer, and swallowing it would
  // turn an epito bug into a sentence about the user's install.
  await assert.rejects(
    () => engineLook({ env: {}, probe: answering, importClient: () => { throw new TypeError("doctor.js is broken"); } }),
    /doctor\.js is broken/);

  // And when the client IS there, the answer is the real connect's — including
  // its refusal, which already names the namespace and the command that
  // creates it.
  const refused = await engineLook({
    env: {}, probe: answering,
    importClient: () => ({ connect: () => { throw new Error('namespace "nope" does not exist on 127.0.0.1:7233'); } }),
  });
  assert.equal(refused.depth, "connect");
  assert.equal(refused.ok, false);
  assert.match(refused.reason, /namespace "nope" does not exist/);
  const up = await engineLook({
    env: {}, probe: answering,
    importClient: () => ({ connect: () => ({ connection: { close: async () => {} } }) }),
  });
  assert.equal(up.depth, "connect");
  assert.equal(up.ok, true);
});

// ─────────────────────────────────────────────────────────────────────────────
// Is anything DOING the work? (src/temporal/pollers.js)
//
// The failure these cover is the one no surface used to report: the engine
// answers, the namespace exists, the manifests are good, and nothing is
// polling the queue — so every run is accepted and none is performed. The
// cases below are the whole of that module's behavior, because its two
// readers (`epito doctor`'s worker row and `epito ps`'s RUNNING column) both
// read their verdict off `state` and their sentence off `says`.

// One poller, as the engine reports it: an identity and when it last polled.
const poller = (identity, agoMs) => ({ identity, agoMs });
const half = (pollers = [], count = 0, ageMs = 0) => ({ pollers, backlog: { count, ageMs } });

test("a worker polling both halves of the queue is the only answer that is fine", () => {
  const s = summarize({ workflow: half([poller("w1@box", 3_000)]), activity: half([poller("w1@box", 4_000)]) });
  assert.equal(s.state, POLLED);
  assert.equal(s.fix, null, "a state with nothing wrong must not offer a fix");
  assert.equal(s.workers.length, 1, "one process polls both queues and is one worker, not two");
  assert.match(s.says, /one worker is polling seats for both workflow and activity tasks/);
  assert.match(s.says, /last polled 3s ago/, "the ✓ carries its own evidence, and it is the FRESHEST of that process's two polls: a poller record is a memory, so the age is the fact");
  assert.ok(!WORKER_REFUSES.has(s.state));
});

test("nothing polling is a refusal that says what happens instead of a failure", () => {
  const s = summarize({ workflow: half(), activity: half() });
  assert.equal(s.state, WORKER_NONE);
  assert.ok(WORKER_REFUSES.has(s.state));
  // The bar every message in this product is held to: name the rule broken,
  // in the product's vocabulary, with the fix in the message.
  assert.match(s.says, /nothing is polling seats/);
  assert.match(s.says, /queued forever rather than refused/, "the consequence is the point: a run that waits forever never shows up as a failure anywhere");
  assert.equal(s.fix, WORKER_FIX);
  assert.match(s.fix, /epito worker/, "the laptop's fix");
  assert.match(s.fix, /systemctl start epitod-worker/, "and the provisioned host's, which is the box this question is asked on");
  assert.match(s.fix, /journalctl/, "a worker that stopped has a reason, and the reason is in the journal");
});

test("the engine remembers a poller for five minutes, so a stale one means the worker STOPPED", () => {
  const s = summarize({ workflow: half([poller("w1@box", 4 * 60_000)]), activity: half([poller("w1@box", 4 * 60_000)]) });
  assert.equal(s.state, WORKER_NONE, "a poller that last polled four minutes ago is not a worker: a live one long-polls with a ~60s timeout");
  assert.equal(s.stale.workflow, 1);
  assert.match(s.says, /still remembers a worker/);
  assert.match(s.says, /stopped rather than never started/, "the two fixes differ: start one, versus find out why this one died");
  assert.match(s.says, /last polled 4m ago/);
  // And the boundary is the documented one, not an accident of rounding.
  assert.equal(summarize({ workflow: half([poller("w@b", RECENT_MS - 1)]), activity: half([poller("w@b", RECENT_MS - 1)]) }).state, POLLED);
  assert.equal(summarize({ workflow: half([poller("w@b", RECENT_MS + 1)]), activity: half([poller("w@b", RECENT_MS + 1)]) }).state, WORKER_NONE);
  // An age the engine did not report is not a fresh one.
  assert.equal(summarize({ workflow: half([poller("w@b", null)]), activity: half([poller("w@b", null)]) }).state, WORKER_NONE);
});

test("the age under a \u2713 is printed in the unit that says which side of the line it is on", () => {
  // 1m 37s is inside the window and rounds to "2m", and two minutes is the
  // documented line between a worker and a memory of one — so the old sentence
  // was "\u2713 one worker is polling seats ... last polled 2m ago", a tick and
  // its own disproof. Seen on a real engine 2026-10-12, 73s after the worker
  // was killed. Seconds inside the window, minutes outside it: the unit alone
  // now answers "is this one still a worker".
  const nearly = summarize({ workflow: half([poller("w@b", 97_000)]), activity: half([poller("w@b", 97_000)]) });
  assert.equal(nearly.state, POLLED);
  assert.match(nearly.says, /last polled 97s ago/, "an age inside the window is never rounded up past the window");
  assert.doesNotMatch(nearly.says, /\bm ago\b/, "a \u2713 may not carry an age in minutes: two minutes is the line it is claiming to be inside of");

  const over = summarize({ workflow: half([poller("w@b", RECENT_MS + 1_000)]), activity: half([poller("w@b", RECENT_MS + 1_000)]) });
  assert.equal(over.state, WORKER_NONE);
  assert.match(over.says, /last polled 2m ago/, "and outside it the age is in minutes, which is the half of the pair that reads as a memory");
});

test("two remembered pollers are two workers that stopped, said in the plural", () => {
  // A restart leaves the old identity in the engine's memory beside the new
  // one, so this list having two entries is the commonest shape it has, not an
  // exotic one. The sentence used to read "2 workers ... so this one stopped".
  const s = summarize({
    workflow: half([poller("old@box", 4 * 60_000), poller("new@box", 3 * 60_000)]),
    activity: half([poller("old@box", 4 * 60_000), poller("new@box", 3 * 60_000)]),
  });
  assert.equal(s.state, WORKER_NONE);
  assert.match(s.says, /still remembers 2 workers/);
  assert.match(s.says, /so these stopped rather than never started/, "two of them did not stop as one");
  assert.match(s.says, /old@box, last polled 4m ago; new@box, last polled 3m ago/, "both, named, with the age that makes each a memory");
});

test("polling one half of the queue and not the other is its own refusal, and says which half", () => {
  const noActivity = summarize({ workflow: half([poller("w@b", 1_000)]), activity: half() });
  assert.equal(noActivity.state, WORKER_HALF);
  assert.match(noActivity.says, /nothing is polling it for activity tasks/);
  assert.match(noActivity.says, /starts and never clones, mints or spawns anything/);
  assert.equal(psMark(noActivity), "no activity worker");

  const noWorkflow = summarize({ workflow: half(), activity: half([poller("w@b", 1_000)]) });
  assert.equal(noWorkflow.state, WORKER_HALF);
  assert.match(noWorkflow.says, /nothing is polling it for workflow tasks/);
  assert.equal(psMark(noWorkflow), "no workflow worker");
  for (const s of [noActivity, noWorkflow]) assert.equal(s.fix, WORKER_FIX);
});

test("a worker listed and not taking the decisions is the state a poller count reports as ✓", () => {
  // The five-minute memory is exactly the window a poller list cannot close,
  // and a workflow task closes it: a decision is dispatched in milliseconds on
  // any queue anything is really polling.
  const fresh = { workflow: half([poller("w@b", 10_000)], 1, 5_000), activity: half([poller("w@b", 10_000)]) };
  assert.equal(summarize(fresh).state, POLLED, "a task waiting five seconds is a task being picked up, not a stall");

  const stalled = { workflow: half([poller("w@b", 10_000)], 2, 4 * 60_000), activity: half([poller("w@b", 10_000)]) };
  const s = summarize(stalled);
  assert.equal(s.state, STALLED);
  assert.ok(WORKER_REFUSES.has(s.state));
  assert.match(s.says, /2 tasks waiting to be decided, the oldest for 4m/);
  assert.match(s.says, /has stopped .* or is wedged/, "the two causes of a listed poller that takes nothing");
  assert.equal(s.fix, WORKER_FIX);
  assert.equal(psMark(s), "worker not taking work");
  assert.equal(summarize({ workflow: half([poller("w@b", 10_000)], 1, STALLED_MS - 1), activity: half([poller("w@b", 10_000)]) }).state, POLLED);
  assert.equal(summarize({ workflow: half([poller("w@b", 10_000)], 1, STALLED_MS + 1), activity: half([poller("w@b", 10_000)]) }).state, STALLED);
});

test("work waiting for a free slot is the runtime working as designed, and never a refusal", () => {
  // A seat run is a whole `claude` process with a clone of a repository and the
  // worker runs a few at a time, so the fifth seat's run waiting an hour is
  // correct behavior. Reporting it is the point — "why has my seat not
  // started" has an answer — and refusing on it would be wrong.
  const s = summarize({ workflow: half([poller("w@b", 2_000)]), activity: half([poller("w@b", 2_000)], 3, 40 * 60_000) });
  assert.equal(s.state, POLLED);
  assert.ok(!WORKER_REFUSES.has(s.state));
  assert.equal(psMark(s), null);
  assert.match(s.says, /3 tasks of work are waiting for a free slot, the oldest for 40m/);
  assert.match(s.says, /EPITO_MAX_CONCURRENT_RUNS/, "the knob that changes it, in the message");
  assert.equal(s.backlog.activity.count, 3);
});

test("a refusing answer names what is waiting, because that is the morning's size", () => {
  const s = summarize({ workflow: half([], 9, 7 * 3600_000), activity: half([], 4, 7 * 3600_000) });
  assert.equal(s.state, WORKER_NONE);
  assert.match(s.says, /9 tasks to decide what happens next, the oldest waiting for 7h/);
  assert.match(s.says, /4 tasks of actual work \(clone, mint, the agent's own process\), the oldest waiting for 7h/);
});

test("an unasked question is never an answer in either direction", () => {
  const unasked = summarize({}, { asked: false, because: "nothing answered at 127.0.0.1:7233" });
  assert.equal(unasked.state, WORKER_UNASKED);
  assert.ok(!WORKER_REFUSES.has(unasked.state), "a box that could not be asked has not failed this check");
  assert.equal(psMark(unasked), null);
  assert.match(unasked.says, /not asked — nothing answered at 127\.0\.0\.1:7233/);
  assert.equal(unasked.fix, null);

  // And the other not-answer: the engine connected, the namespace checked out,
  // and it would not say who is polling. That is not an absent engine.
  const refused = summarize({}, { error: "PERMISSION_DENIED" });
  assert.equal(refused.state, WORKER_UNASKED);
  assert.match(refused.says, /the engine connected and would not say who is polling seats \(PERMISSION_DENIED\)/);
  assert.equal(refused.error, "PERMISSION_DENIED");
});

test("the queue is asked about both task types, with stats, and the names are not guessed", async () => {
  const asked = [];
  const connection = {
    workflowService: {
      describeTaskQueue: async (req) => {
        asked.push(req);
        return req.taskQueueType === TASK_QUEUE_TYPE.workflow
          ? { pollers: [{ identity: "", lastAccessTime: { seconds: 1_000, nanos: 0 } }], stats: { approximateBacklogCount: "2", approximateBacklogAge: { seconds: 90, nanos: 0 } } }
          : { pollers: [{ identity: "w@box", lastAccessTime: { seconds: 1_005, nanos: 0 } }], stats: {} };
      },
    },
  };
  const q = await describeQueue(connection, { namespace: "asc", taskQueue: "seats", nowMs: 1_010_000 });
  assert.deepEqual(asked.map((r) => r.taskQueueType), [TASK_QUEUE_TYPE.workflow, TASK_QUEUE_TYPE.activity]);
  for (const r of asked) {
    assert.equal(r.namespace, "asc");
    assert.deepEqual(r.taskQueue, { name: "seats" });
    assert.equal(r.reportStats, true, "without this the backlog is absent and a wedged worker reads as a healthy one");
  }
  assert.equal(q.workflow.pollers[0].agoMs, 10_000);
  assert.equal(q.workflow.pollers[0].identity, "(unnamed worker)", "a worker with no identity is still a worker, and `` in a sentence reads as a bug");
  assert.equal(q.workflow.backlog.count, 2);
  assert.equal(q.workflow.backlog.ageMs, 90_000);
  // A server too old for reportStats omits stats entirely, which must read as
  // an empty backlog and claim nothing.
  assert.deepEqual(q.activity.backlog, { count: 0, ageMs: null });
  assert.equal(q.activity.pollers[0].agoMs, 5_000);
  assert.equal(summarize(q, { taskQueue: "seats" }).state, STALLED);
});

test("a protobuf timestamp is read as an age, and an unreadable one as nothing", () => {
  assert.equal(ageMs({ seconds: 100, nanos: 500_000_000 }, 101_000), 500);
  assert.equal(ageMs({ seconds: "100", nanos: 0 }, 103_000), 3_000, "seconds arrives as a Long, which stringifies");
  assert.equal(ageMs("2026-10-10T00:00:00Z", Date.parse("2026-10-10T00:00:05Z")), 5_000);
  assert.equal(ageMs(null), null);
  assert.equal(ageMs({ seconds: "not-a-number" }), null);
  assert.equal(ageMs({ seconds: 500 }, 100_000), 0, "a stamp in the future is zero age, never a negative one");
  assert.equal(durationMs(undefined), null);
  assert.equal(durationMs({}), 0, "an absent proto field is the proto default, and for a Duration that is zero");
  assert.equal(durationMs({ seconds: 2, nanos: 250_000_000 }), 2_250);
});

test("the two readers of the worker's state read it, and do not re-decide it", () => {
  // Same rule as readiness.js's REPO_REQUIRED_BY and acts.js's
  // INSTALL_REFUSES: the list the sentence prints is the list the surfaces
  // check against, so an exit code and a row cannot disagree. A surface that
  // spelled its own "none" or "stalled" would be the second answer to one
  // question.
  for (const f of ["src/doctor.js", "src/temporal/ps.js"]) {
    const src = readFileSync(fileURLToPath(new URL(`../${f}`, import.meta.url)), "utf8");
    assert.ok(/WORKER_REFUSES/.test(src), `${f} does not read WORKER_REFUSES`);
    assert.ok(!/=== *"(none|half|stalled|polled|unasked)"/.test(src),
      `${f} compares a worker state against a string literal; import the constant instead`);
  }
  // And the module stays importable on a box with no engine installed, which
  // is what lets `epito doctor` hold these sentences there (same invariant as
  // lib/engine.js: the connection is handed in, never imported).
  //
  // This was written as "pollers.js has no imports at all", which is a proxy
  // for the real rule and refused the first honest import it met: the one
  // locator every message naming a file in this repository shares
  // (src/lib/where.js, two string constants). So it now states the property
  // itself — nothing this module pulls in may pull anything in either, so
  // there is no path from here to an @temporalio package however deep.
  const read = (f) => readFileSync(fileURLToPath(new URL(`../${f}`, import.meta.url)), "utf8");
  const pollers = read("src/temporal/pollers.js");
  for (const [, spec] of pollers.matchAll(/^import .* from "([^"]+)";/gm)) {
    assert.ok(spec.startsWith("."),
      `src/temporal/pollers.js imports the package ${spec} — a package here would make \`epito doctor\`'s sentences need the ~300 MB of engine`);
    const leaf = read(`src/temporal/${spec}`.replace(/[^/]+\/\.\.\//g, ""));
    assert.ok(!/^import /m.test(leaf),
      `src/temporal/pollers.js imports ${spec}, which has imports of its own — the one thing this module may import is a leaf of constants`);
  }
});

test("the engine look asks who is polling on the connection it already opened", async () => {
  const answering = () => Promise.resolve({ ok: true, address: "127.0.0.1:7233", malformed: false, reason: null });
  let closed = false;
  const connection = {
    close: async () => { closed = true; },
    workflowService: {
      describeTaskQueue: async () => ({ pollers: [{ identity: "w@box", lastAccessTime: { seconds: 999, nanos: 0 } }], stats: {} }),
    },
  };
  const up = await engineLook({ env: { TEMPORAL_ADDRESS: "127.0.0.1:7233" }, probe: answering, importClient: () => ({ connect: () => ({ connection }) }) });
  assert.equal(up.ok, true);
  assert.equal(up.taskQueue, "seats");
  assert.equal(up.pollers.workflow.pollers.length, 1);
  assert.equal(up.pollersError, null);
  assert.equal(closed, true, "one connection, asked both questions, then closed");

  // A DescribeTaskQueue that fails is a thing to report, not a reason to call
  // an engine down: the connect and the namespace check have just succeeded.
  const refusing = {
    close: async () => {},
    workflowService: { describeTaskQueue: async () => { throw new Error("PERMISSION_DENIED"); } },
  };
  const partial = await engineLook({ env: {}, probe: answering, importClient: () => ({ connect: () => ({ connection: refusing }) }) });
  assert.equal(partial.ok, true, "the engine is up; it is the poller question that failed");
  assert.equal(partial.pollers, null);
  assert.match(partial.pollersError, /PERMISSION_DENIED/);
  assert.equal(summarize(partial.pollers ?? {}, { taskQueue: partial.taskQueue, asked: false, error: partial.pollersError }).state, WORKER_UNASKED);

  // And on a box without the engine client the question cannot be put at all.
  const notInstalled = () => { const e = new Error("Cannot find package '@temporalio/client' imported from /x/y.js"); e.code = "ERR_MODULE_NOT_FOUND"; throw e; };
  const tcp = await engineLook({ env: {}, probe: answering, importClient: notInstalled });
  assert.equal(tcp.pollers, null);
  assert.equal(tcp.taskQueue, "seats", "the queue a run would use is knowable without an engine, and the row names it");
});

// --- a run's pull request is asked of the code host ------------------------
// The defect: the close handler matched an address out of the last 64 KB of
// the child's output and asked GitHub nothing, so a run that opened its draft
// first and then kept printing was recorded as having shipped nothing. These
// cases are the two halves of the fix — the question put to the host, and the
// transcript half made truncation-proof underneath it.

// A stand-in for GET /repos/<repo>/pulls. It records what was asked, so a
// test can assert that the run asked as ITSELF, and it stamps `created_at`
// when the request arrives unless a case pins its own, because "during this
// run" is the whole filter.
const pullsStub = async (t, pulls, { status = 200, body = null } = {}) => {
  const asked = [];
  const server = createServer((req, res) => {
    asked.push({ url: req.url, auth: req.headers.authorization ?? null, agent: req.headers["user-agent"] });
    res.writeHead(status, { "content-type": "application/json" });
    res.end(body ?? JSON.stringify(pulls.map((p) => ({
      html_url: p.html_url ?? `https://github.com/acme/roster/pull/${p.number ?? 1}`,
      created_at: p.created_at ?? new Date().toISOString(),
      head: { ref: p.ref, repo: { full_name: p.repo ?? "acme/roster" } },
    }))));
  });
  server.listen(0, "127.0.0.1");
  await once(server, "listening");
  t.after(() => server.close());
  return { asked, api: `http://127.0.0.1:${server.address().port}` };
};

test("the branch the prompt asks for and the branch the lookup searches for are one string", () => {
  const made = { name: "epitome-engineer", date: "2026-10-18", trigger: "message" };
  const prefix = runBranchPrefix(made);
  assert.equal(prefix, "epitome-engineer/2026-10-18-message");
  const prompt = buildPrompt({ ...made, entry: "prompts/engineer-agent.md", shortfall: { missing: [], empty: [] } });
  assert.match(prompt, new RegExp(`Work on a branch named ${prefix} \\(append a short suffix`),
    "one function, two readers: the moment these hold separate copies the runtime searches for a branch it never asked for");
  // The registered name is what both use. A seat whose charter calls it
  // something else does not move either of them.
  assert.equal(runBranchPrefix({ name: "pm", date: "2026-10-18", trigger: "cron" }), "pm/2026-10-18-scheduled");
  assert.equal(runBranchPrefix({ name: "pm", date: "2026-10-18", trigger: "nonsense" }), "pm/2026-10-18-hook");
});

test("the lookup finds this run's pull request by branch prefix, and asks as the run itself", async (t) => {
  const { asked, api } = await pullsStub(t, [{ number: 169, ref: "epitome-engineer/2026-10-18-message-4" }]);
  const found = await pullRequestForRun({
    repo: "acme/roster", prefix: "epitome-engineer/2026-10-18-message",
    token: "ghs_LOOKUPTOKEN0000000000000000000000", since: Date.now() - 60_000, api,
  });
  assert.equal(found.pr, "https://github.com/acme/roster/pull/169");
  assert.equal(found.branch, "epitome-engineer/2026-10-18-message-4", "the suffix the agent appended is matched, not demanded");
  assert.equal(found.why, null);
  assert.equal(asked.length, 1);
  assert.match(asked[0].url, /^\/repos\/acme\/roster\/pulls\?state=all/, "state=all: a draft that was merged in the same run is still this run's");
  assert.equal(asked[0].auth, "Bearer ghs_LOOKUPTOKEN0000000000000000000000", "a run with an identity asks as itself");
  assert.equal(asked[0].agent, "epito", "GitHub refuses a request with no user agent, which is a 403 nobody would read as this");
});

test("the lookup never claims a pull request from an earlier run of the same seat", async (t) => {
  const started = Date.now();
  // Three runs of one seat in one day: every branch matches every other's
  // prefix, which is why the clock and not the name is what tells them apart.
  const { api } = await pullsStub(t, [
    { number: 156, ref: "epitome-engineer/2026-10-18-message-3", created_at: new Date(started - 3 * 3600_000).toISOString() },
    { number: 153, ref: "epitome-engineer/2026-10-18-message-2", created_at: new Date(started - 5 * 3600_000).toISOString() },
  ]);
  const found = await pullRequestForRun({ repo: "acme/roster", prefix: "epitome-engineer/2026-10-18-message", since: started, api });
  assert.equal(found.pr, null, "a run that opened nothing records nothing, which is the point of asking");
  assert.match(found.why, /no pull request on acme\/roster has a branch starting with "epitome-engineer\/2026-10-18-message" that was opened during this run/);

  // The same board, with this run's own draft on it: newest wins.
  const mine = await pullsStub(t, [
    { number: 169, ref: "epitome-engineer/2026-10-18-message-4", created_at: new Date(started + 30_000).toISOString() },
    { number: 156, ref: "epitome-engineer/2026-10-18-message-3", created_at: new Date(started - 3 * 3600_000).toISOString() },
  ]);
  const got = await pullRequestForRun({ repo: "acme/roster", prefix: "epitome-engineer/2026-10-18-message", since: started, api: mine.api });
  assert.equal(got.pr, "https://github.com/acme/roster/pull/169");

  // A draft opened in the same second the child was spawned is this run's:
  // GitHub stamps to the second, and rounding it out of its own run would
  // bring back exactly the silence being fixed.
  const edge = await pullsStub(t, [{ number: 170, ref: "pm/2026-10-18-scheduled", created_at: new Date(started - 400).toISOString() }]);
  const close = await pullRequestForRun({ repo: "acme/roster", prefix: "pm/2026-10-18-scheduled", since: started, api: edge.api });
  assert.equal(close.pr, "https://github.com/acme/roster/pull/170");
});

test("a head branch in somebody's fork is not this run's branch", async (t) => {
  const { api } = await pullsStub(t, [{ number: 1, ref: "pm/2026-10-18-scheduled", repo: "stranger/roster" }]);
  const found = await pullRequestForRun({ repo: "acme/roster", prefix: "pm/2026-10-18-scheduled", since: Date.now() - 1000, api });
  assert.equal(found.pr, null);
});

test("every way the lookup can fail names itself and refuses nothing", async (t) => {
  const refused = await pullsStub(t, [], { status: 404, body: '{"message":"Not Found"}' });
  const four = await pullRequestForRun({ repo: "acme/roster", prefix: "pm/2026-10-18-scheduled", api: refused.api });
  assert.equal(four.pr, null);
  assert.match(four.why, /GitHub answered 404 for the pull requests of acme\/roster — either it does not exist or this run's credential cannot read it/);

  const notAList = await pullsStub(t, [], { body: '{"message":"rate limit"}' });
  const obj = await pullRequestForRun({ repo: "acme/roster", prefix: "pm/2026-10-18-scheduled", api: notAList.api });
  assert.equal(obj.pr, null);
  assert.match(obj.why, /answered about the pull requests of acme\/roster with object, not a list/);

  const garbage = await pullsStub(t, [], { body: "<html>a proxy sign-in page</html>" });
  const bad = await pullRequestForRun({ repo: "acme/roster", prefix: "pm/2026-10-18-scheduled", api: garbage.api });
  assert.equal(bad.pr, null);
  assert.match(bad.why, /was not JSON/);

  const dead = await pullRequestForRun({ repo: "acme/roster", prefix: "pm/2026-10-18-scheduled", api: "http://127.0.0.1:1" });
  assert.equal(dead.pr, null);
  assert.match(dead.why, /^http:\/\/127\.0\.0\.1:1 could not be reached about the pull requests of acme\/roster/,
    "a box with no route to the host and a host that is merely slow are not the same sentence");

  // And the slow one, which is the shape that must never hold a run open: one
  // request that answers nothing, against a lookup given 50ms to wait.
  const slow = createServer(() => {});
  slow.listen(0, "127.0.0.1");
  await once(slow, "listening");
  t.after(() => { slow.closeAllConnections?.(); slow.close(); });
  const late = await pullRequestForRun({
    repo: "acme/roster", prefix: "pm/2026-10-18-scheduled",
    api: `http://127.0.0.1:${slow.address().port}`, timeoutMs: 50,
  });
  assert.equal(late.pr, null);
  assert.match(late.why, /did not answer within 50ms about the pull requests of acme\/roster/);

  const nothing = await pullRequestForRun({ repo: null, prefix: null });
  assert.match(nothing.why, /names no repository and no branch prefix/);
});

// The defect end to end, in the shape the handoff measured: the draft's
// address is printed in the first line, 80 KB of output follows it, and the
// result object is padded past the window as well.
const noisyRun = async (t, { api, over = {} } = {}) => {
  const dir = tmpDir();
  const cwd = process.cwd();
  process.chdir(dir);                                   // .epito/logs/<agent>/ is relative
  const work = mkdtempSync(cloneDirPrefix("engineer"));
  const saved = process.env.EPITO_GITHUB_API;
  if (api) process.env.EPITO_GITHUB_API = api;
  t.after(() => {
    process.chdir(cwd);
    rmSync(work, { recursive: true, force: true });
    process.env.EPITO_GITHUB_API = saved;
    delete process.env.EPITO_STUB_DIR; delete process.env.EPITO_STUB_PR_EARLY;
    delete process.env.EPITO_STUB_NOISE_KB; delete process.env.EPITO_STUB_RESULT_KB; delete process.env.EPITO_STUB_PR;
  });
  process.env.EPITO_STUB_DIR = join(dir, "stub");
  process.env.EPITO_STUB_PR_EARLY = "1";
  process.env.EPITO_STUB_NOISE_KB = "80";
  process.env.EPITO_STUB_RESULT_KB = "80";
  process.env.EPITO_STUB_PR = "https://github.com/acme/roster/pull/169";
  const agent = seat("engineer", { runtime: { model: "m", entry: "e", repo: "acme/roster",
    env: ["EPITO_STUB_DIR", "EPITO_STUB_PR_EARLY", "EPITO_STUB_NOISE_KB", "EPITO_STUB_RESULT_KB", "EPITO_STUB_PR"] } });
  const r = await executeAgent({
    agent, trigger: "message", runId: "r-tail-1", workDir: work, timeoutMs: 60_000, log: () => {},
    executor: new URL("./stub-executor.mjs", import.meta.url).pathname, ...over,
  });
  return { r, logged: readFileSync(r.log, "utf8") };
};

test("a run that printed its draft and kept printing is recorded as having shipped it", async (t) => {
  const today = new Date().toISOString().slice(0, 10);
  const { asked, api } = await pullsStub(t, [{ number: 169, ref: `engineer/${today}-message` }]);
  const { r, logged } = await noisyRun(t, { api });

  assert.equal(r.exit, 0);
  assert.equal(r.pr, "https://github.com/acme/roster/pull/169", "the host was asked, and the host knew");
  assert.match(logged, /# pull request: https:\/\/github\.com\/acme\/roster\/pull\/169, which GitHub says acme\/roster opened during this run/);
  assert.equal(asked.length, 1, "one question per attempt, at the end of it");

  // The 64 KB window really did lose the address: this is the defect, proved
  // against the same run that just survived it rather than asserted about.
  // Measured over the child's own output, which ends where the runtime's
  // epilogue — the line just asserted above — begins.
  const child = logged.slice(0, logged.indexOf("# pull request:"));
  const window = child.slice(-64 * 1024);
  assert.ok(child.includes("/pull/169"), "the child did print the address, once, at the start");
  assert.ok(!/\/pull\/169/.test(window), "and the last 64 KB of what it printed holds no pull request address at all");

  // The turn count sits before `result` inside the result object, so a padded
  // result is how a run lost it. The whole line is kept now.
  assert.equal(r.turns, 1, "and the turn count survived with it");
  assert.ok(r.sessionId, "as did the session id, which is what a window resumes on");
});

test("with the host unreachable, the transcript half no longer loses the address either", async (t) => {
  const { r, logged } = await noisyRun(t, { api: "http://127.0.0.1:1" });
  assert.equal(r.exit, 0);
  assert.equal(r.pr, "https://github.com/acme/roster/pull/169",
    "the address is taken as it goes past, not read out of a window it has long since left");
  assert.match(logged, /# pull request: http:\/\/127\.0\.0\.1:1 could not be reached .*; recorded from the address the run printed instead/);
  assert.equal(r.turns, 1);
});

// --- which epito is running here (src/lib/build.js) ------------------------
// The defect these pin: on 2026-10-18 the host's checkout of this repository
// was at the merge of PR #6 (2026-09-20) with two tracked files carrying
// uncommitted hand-patches, so four weeks of merged runtime fixes were not
// running — and the daemon, the run logs, `epito ps` and `epito doctor` all
// described behaviour without naming the code that produced it.

// git, as a function, so every case below is a box and not a mock of one.
const gitSays = (answers) => (args) => answers[args.join(" ")] ?? null;

test("the revision is the runtime's own tree, and a hand-patched one says which files", () => {
  const b = runtimeBuild({
    dir: "/srv/epito/cli",
    readVersion: () => JSON.stringify({ version: "0.1.0" }),
    runGit: gitSays({
      "rev-parse --is-inside-work-tree": "true",
      "rev-parse --short HEAD": "5836dc0",
      "rev-parse --abbrev-ref HEAD": "HEAD",
      "rev-parse --show-toplevel": "/srv/epito",
      // Exactly what the host answered, leading column and all.
      "status --porcelain --untracked-files=no": " M cli/src/index.js\n M cli/src/lib/runner.js",
    }),
  });
  assert.equal(b.commit, "5836dc0");
  assert.equal(b.source, "git");
  assert.equal(b.detached, true, "a detached HEAD is itself worth saying on a runtime host");
  assert.equal(b.branch, null);
  assert.equal(b.root, "/srv/epito", "the repository, not the cli/ directory a pull request cannot be opened from");
  assert.deepEqual(b.modified, ["cli/src/index.js", "cli/src/lib/runner.js"]);
  assert.equal(b.dirty, true);
});

test("porcelain's two status columns are columns, not something to trim", () => {
  // The first version of this trimmed the whole output and reported
  // "li/src/index.js": `.trim()` ate the leading space of an unstaged
  // modification and took the first character of the path with it.
  assert.deepEqual(porcelainPaths(" M cli/src/index.js\nM  a.js\n?? b.js"),
    ["a.js", "b.js", "cli/src/index.js"]);
  assert.deepEqual(porcelainPaths("R  old/name.js -> new/name.js"), ["new/name.js"],
    "a rename is reported as where the file is now");
  assert.deepEqual(porcelainPaths(""), []);
  assert.deepEqual(porcelainPaths(null), []);
});

test("an epito installed from npm is not a fault, and says so without a revision", () => {
  const b = runtimeBuild({
    dir: "/usr/lib/node_modules/epito",
    readVersion: () => JSON.stringify({ version: "0.1.0" }),
    runGit: gitSays({}),
  });
  assert.equal(b.source, "package");
  assert.equal(b.commit, null);
  assert.equal(b.dirty, false);
  assert.equal(buildLine(b), "epito 0.1.0 · installed, not a checkout");
  assert.equal(buildNote(b).level, "ok", "no checkout is the ordinary shape of an install, not a warning");
  assert.match(b.why, /is not a git checkout/);
});

test("a box where neither the version nor a checkout can be read says that, rather than throwing", () => {
  const b = runtimeBuild({
    dir: "/nowhere",
    readVersion: () => { throw new Error("ENOENT"); },
    runGit: gitSays({}),
  });
  assert.equal(b.source, "unknown");
  assert.equal(b.version, null);
  assert.equal(buildNote(b).level, "warn");
  assert.match(buildNote(b).text, /cannot say which build it is/);
});

test("git present and refusing to name HEAD is a warning with its own sentence", () => {
  const b = runtimeBuild({
    dir: "/srv/epito/cli",
    readVersion: () => JSON.stringify({ version: "0.1.0" }),
    runGit: gitSays({ "rev-parse --is-inside-work-tree": "true" }),
  });
  assert.equal(b.source, "git");
  assert.equal(b.commit, null);
  assert.equal(buildNote(b).level, "warn");
  assert.match(buildNote(b).text, /would not name HEAD/);
});

test("the clean line is one line, and the dirty note names the rule, the hazard and the fix", () => {
  const clean = runtimeBuild({
    dir: "/w/cli",
    readVersion: () => JSON.stringify({ version: "0.1.0" }),
    runGit: gitSays({
      "rev-parse --is-inside-work-tree": "true",
      "rev-parse --short HEAD": "3806b83",
      "rev-parse --abbrev-ref HEAD": "main",
      "rev-parse --show-toplevel": "/w",
      "status --porcelain --untracked-files=no": "",
    }),
  });
  assert.equal(buildLine(clean), "epito 0.1.0 · 3806b83 (main) · clean");
  assert.equal(buildNote(clean).level, "ok");

  const dirty = runtimeBuild({
    dir: "/w/cli",
    readVersion: () => JSON.stringify({ version: "0.1.0" }),
    runGit: gitSays({
      "rev-parse --is-inside-work-tree": "true",
      "rev-parse --short HEAD": "5836dc0",
      "rev-parse --abbrev-ref HEAD": "main",
      "rev-parse --show-toplevel": "/w",
      "status --porcelain --untracked-files=no": " M a.js\n M b.js\n M c.js\n M d.js\n M e.js\n M f.js",
    }),
  });
  const note = buildNote(dirty);
  assert.equal(note.level, "warn");
  // The bar `epito validate` set: the rule broken, in the product's own
  // vocabulary, with the fix in the message.
  assert.match(note.text, /6 tracked files modified here: a\.js, b\.js, c\.js, d\.js and 2 more/);
  assert.match(note.text, /not any revision in the repository/);
  assert.match(note.text, /a fix merged on the default branch does not reach it/);
  assert.match(note.text, /Fix, on a host: land them in a pull request from \/w/);
  // And it does not pretend to know which of the two boxes it is on.
  assert.match(note.text, /in a checkout you are working in it means what you expect/);
});

test("the build is read once per process, because the code a daemon runs is the code it loaded", () => {
  // A `git pull` underneath a resident daemon changes the files and changes
  // nothing about the running process. Re-reading would make the log name a
  // revision whose fix the process does not have, which is the lie this
  // module exists to stop.
  const a = thisRuntime();
  const b = thisRuntime();
  assert.equal(a, b, "the same object, not an equal one: it is answered once and kept");
});

test("one tracked file is one file, not one files", () => {
  const one = runtimeBuild({
    dir: "/w/cli",
    readVersion: () => JSON.stringify({ version: "0.1.0" }),
    runGit: gitSays({
      "rev-parse --is-inside-work-tree": "true",
      "rev-parse --short HEAD": "abc1234",
      "rev-parse --abbrev-ref HEAD": "main",
      "rev-parse --show-toplevel": "/w",
      "status --porcelain --untracked-files=no": " M only.js",
    }),
  });
  assert.match(buildLine(one), /1 tracked file modified here: only\.js$/);
});

test("the run log header names the build that produced the run", async (t) => {
  const { r, logged } = await noisyRun(t, { api: "http://127.0.0.1:1" });
  assert.equal(r.exit, 0);
  // Second line of the runtime's own header, above anything the child printed.
  assert.match(logged, /^# epito run [\s\S]*?\n# trigger=[\s\S]*?\n# epito /m);
  assert.match(logged, new RegExp(`# ${buildLine(thisRuntime()).replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}`));
});

// --- a refused run did not fail (src/lib/refusal.js) ----------------------
//
// The measurement behind every assertion here: on 2026-10-18 the host
// attempted 253 runs and a model provider refused 65 of them, 37 before a
// first turn. Every one was recorded as a failure, and every one threw away
// the bus event that woke it. What is pinned below is the three places that
// changed: the reading of the provider's own words, the delay taken from the
// reset time those words name, and the surfaces that now tell a refusal from
// a failure.
import {
  readRefusal, refusalNakMs, refusalSays, parseResetMoment, humanMs,
  MIN_REFUSAL_NAK_MS, MAX_REFUSAL_NAK_MS, RESET_GRACE_MS, FLOOR_MS,
} from "../src/lib/refusal.js";
import { awaitProviderVerdict } from "../src/run.js";
import { formatLine } from "../src/lib/slack.js";

const NOW = Date.parse("2026-10-18T01:57:00.000Z");

test("the shapes a provider actually refuses in are read, each with its own reset time", () => {
  const cases = [
    // The Claude CLI's own machine-readable line: the words, a pipe, an epoch.
    ["Claude AI usage limit reached|1792300800", "limit", "2026-10-18T05:20:00.000Z"],
    // The same thing in prose, which is what lands in a run log.
    ["Claude AI usage limit reached. Your limit will reset at 5am (UTC).", "limit", "2026-10-18T05:00:00.000Z"],
    ["weekly limit exceeded, resets in 2 hours", "limit", "2026-10-18T03:57:00.000Z"],
    // A gateway answering 429 with the seconds it wants back.
    ['{"type":"rate_limit_error","message":"slow down"}\nretry-after: 600', "rate", "2026-10-18T02:07:00.000Z"],
    // Refusals that name no moment at all: still refusals.
    ["HTTP 429 Too Many Requests", "rate", null],
    ['{"type":"overloaded_error"}', "overloaded", null],
    ["Your credit balance is too low to access the Anthropic API.", "balance", null],
  ];
  for (const [text, kind, resetAt] of cases) {
    const r = readRefusal(text, { now: NOW });
    assert.ok(r, `not read as a refusal: ${text}`);
    assert.equal(r.kind, kind, text);
    assert.equal(r.resetAt, resetAt, text);
    assert.ok(r.says.length > 0 && r.says.length <= 200, "the provider's own sentence comes back, bounded");
  }
});

// The correction. The patterns above were written from the shapes the
// provider documents, and this runtime's own host prints none of them: every
// one of the 37 runs refused before a first turn on 2026-10-18 ended
// `{"api_error_status":429,"result":"You've hit your session limit · resets
// 11:20am (UTC)"}`, and the reader returned no-match for all 37. The code was
// right and the sentence was wrong, which saved exactly zero runs.
//
// So the sentences stopped being prose in a test and became data copied out
// of the logs (test/fixtures/refusals.json). A shape the provider invents
// next is a row added by whoever reads the log; the assertion comes free, and
// nobody has to notice that a regex needed editing too.
const REFUSAL_FIXTURE = JSON.parse(readFileSync(new URL("./fixtures/refusals.json", import.meta.url), "utf8"));

test("every refusal sentence this runtime has actually recorded is read, from the fixture", () => {
  assert.ok(REFUSAL_FIXTURE.observed.length >= 12, "the fixture is the coverage; it does not shrink");
  for (const row of REFUSAL_FIXTURE.observed) {
    const r = readRefusal(row.text, { now: Date.parse(row.at) });
    assert.ok(r, `read as no refusal at all, which is the defect this file exists for: ${row.source}`);
    assert.equal(r.kind, row.kind, row.source);
    assert.equal(r.resetAt, row.resetAt, `the reset time in ${row.source}`);
    assert.equal(r.says, row.says, `the sentence quoted back to the operator for ${row.source}`);
    if (row.resetAt) {
      assert.equal(refusalNakMs(r, { now: Date.parse(row.at) }),
        Math.min(Math.max(Date.parse(row.resetAt) - Date.parse(row.at) + RESET_GRACE_MS, MIN_REFUSAL_NAK_MS), MAX_REFUSAL_NAK_MS),
        `the wait for ${row.source} is the moment the provider named, not a floor`);
    } else {
      assert.equal(refusalNakMs(r, { now: Date.parse(row.at) }), FLOOR_MS[row.kind],
        `${row.source} named no moment, so the wait is the floor for ${row.kind}`);
    }
  }
  // The other half of the fixture: sentences that contain every word a
  // refusal contains and are not one. This repository writes them all day.
  for (const row of REFUSAL_FIXTURE.not_refusals) {
    assert.equal(readRefusal(row.text, { now: NOW }), null, `read as a refusal and is not one: ${row.source}`);
  }
});

test("the sentence THIS host prints is in the fixture, by name, and cannot be dropped", () => {
  // Pinned separately from the loop because the loop would still pass if
  // somebody deleted the row. This is the sentence the whole file is for.
  const rows = REFUSAL_FIXTURE.observed.filter((r) => /hit your session limit/i.test(r.text));
  assert.ok(rows.length >= 2, "the host's own sentence, in both the forms it was logged in");
  assert.ok(rows.some((r) => r.text.includes('"api_error_status":429')),
    "including the executor envelope it arrives inside, which is all a refused run leaves behind");
  const r = readRefusal(rows[0].text, { now: Date.parse("2026-10-18T09:30:00.000Z") });
  assert.equal(r.kind, "limit");
  assert.equal(r.resetAt, "2026-10-18T11:20:00.000Z", "and the clock is read as the host wrote it, in UTC");
  assert.ok(!r.says.includes('"'), "the sentence is lifted out of the JSON, not quoted with the JSON");
});

test("a status with no words is still a refusal, and says only what a status can say", () => {
  // 429 is as much as a result envelope carries when the prose is one this
  // runtime has never seen. Holding the event for a minute and backing off
  // is right; inventing a window the provider did not name is not.
  const r = readRefusal('{"api_error_status":429,"result":"request failed after 10 attempts"}', { now: NOW });
  assert.equal(r.kind, "rate", "a bare status does not say which window closed, so it claims the smaller one");
  assert.equal(r.resetAt, null, "and it invents no clock");
  assert.equal(refusalNakMs(r, { now: NOW, delivery: 1 }), FLOOR_MS.rate);
  assert.equal(refusalNakMs(r, { now: NOW, delivery: 5 }), FLOOR_MS.rate * 5, "and backs off if it keeps being refused");
  // A sentence that DID name its reset is never read by this weaker rule:
  // every shape that names a moment is ordered ahead of every shape that
  // does not, which is what the fixture's 429 rows prove together.
  const named = readRefusal('{"api_error_status":429,"result":"You\'ve hit your session limit · resets 5am (UTC)"}', { now: NOW });
  assert.equal(named.kind, "limit");
  assert.equal(named.resetAt, "2026-10-18T05:00:00.000Z", "the status is in the same line and the words still win");
});

test("a run that did its work is not a refusal, whatever it printed", () => {
  // The guard that makes this safe to run over every ending: the caller only
  // asks about an attempt that produced nothing, and the words alone are
  // never enough. An agent writing ABOUT usage limits is the ordinary case
  // on this repository, today especially.
  assert.equal(readRefusal("I read the incident: 65 runs hit a usage limit today."), null,
    "prose about a limit names no refusal shape");
  assert.equal(readRefusal(""), null);
  assert.equal(readRefusal(null), null);
});

test("a bare clock is the NEXT time the clock reads it, and UTC is honoured when named", () => {
  assert.equal(parseResetMoment("5am (UTC)", { now: Date.parse("2026-10-18T09:00:00Z") }), "2026-10-19T05:00:00.000Z",
    "at 9am, 'resets at 5am' is tomorrow");
  assert.equal(parseResetMoment("1792300800", { now: NOW }), "2026-10-18T05:20:00.000Z", "ten digits is seconds");
  assert.equal(parseResetMoment("2026-10-18T05:00:00Z", { now: NOW }), "2026-10-18T05:00:00.000Z");
  assert.equal(parseResetMoment("whenever", { now: NOW }), null, "what it cannot read, it does not invent");
});

test("the delay is the reset the refusal named, not the bus's fixed fifteen seconds", () => {
  const r = readRefusal("Claude AI usage limit reached. Your limit will reset at 5am (UTC).", { now: NOW });
  const ms = refusalNakMs(r, { now: NOW });
  assert.equal(ms, Date.parse("2026-10-18T05:00:00Z") - NOW + RESET_GRACE_MS,
    "three hours and three minutes, plus a moment, because coming back on the second a limit lifts earns a second refusal");
  // 121 of the day's 342 dark minutes were after capacity had already come
  // back. A reset already in the past is a minute away, not six hours.
  assert.equal(refusalNakMs(r, { now: Date.parse("2026-10-18T06:00:00Z") }), MIN_REFUSAL_NAK_MS);
  // And no refusal holds an event past the ceiling.
  assert.equal(refusalNakMs({ kind: "limit", resetAt: "2026-10-25T00:00:00Z", says: "x" }, { now: NOW }), MAX_REFUSAL_NAK_MS);
});

test("a refusal that named no reset gets a floor for what refused, backed off by delivery", () => {
  const balance = readRefusal("Your credit balance is too low to access the Anthropic API.", { now: NOW });
  assert.equal(refusalNakMs(balance, { now: NOW, delivery: 1 }), FLOOR_MS.balance);
  assert.equal(refusalNakMs(balance, { now: NOW, delivery: 4 }), FLOOR_MS.balance * 4,
    "nine runs sat blocked by a billing state for three and a half days; knocking every half hour forever is not the answer");
  assert.ok(refusalNakMs(balance, { now: NOW, delivery: 99 }) <= MAX_REFUSAL_NAK_MS, "and it is still bounded");
  assert.equal(refusalNakMs(null), null, "no refusal, no delay to compute");
});

test("the sentence names what refused, when it is back, and what happened to the event", () => {
  const r = readRefusal("Claude AI usage limit reached. Your limit will reset at 5am (UTC).", { now: NOW });
  const says = refusalSays("engineer", r, { delayMs: refusalNakMs(r, { now: NOW }) });
  assert.match(says, /^engineer: the run did not start/, "the rule broken, first");
  assert.match(says, /a usage limit refused it before a first turn/);
  assert.match(says, /it says it resets at 2026-10-18T05:00/, "in the provider's own words");
  assert.match(says, /NOT acknowledged and comes back in 3\.1h/, "and what the runtime did about it");
  const vague = refusalSays("pm", { kind: "overloaded", says: "overloaded_error", resetAt: null }, { delayMs: 60_000 });
  assert.match(vague, /named no reset time, so the wait is this runtime's floor/, "what it does not know, it says");
  assert.deepEqual([humanMs(45_000), humanMs(600_000), humanMs(3 * 3_600_000)], ["45s", "10m", "3h"]);
});

test("a run the provider refused ends as refused, and carries when capacity comes back", async () => {
  const r = await stubRun(stubSeat({ route: undefined }), {}, {
    EPITO_STUB_REFUSE_SAYS: "Claude AI usage limit reached. Your limit will reset at 5am (UTC).",
  });
  assert.equal(r.exit, "refused", "not exit 1: the code did not fail, a resource would not take it");
  assert.equal(r.pr, null);
  assert.ok(r.refusal, "the run carries the refusal out to the workflow and the bus");
  assert.equal(r.refusal.kind, "limit");
  assert.ok(Date.parse(r.refusal.resetAt) > Date.now(), "with a reset time in the future");
  assert.match(r.logged, /a resource refused this run before a first turn/, "and the run log says so in the product's words");
  assert.match(r.logged, /recorded as refused rather than failed/);
  assert.match(r.logged, /# exit=refused/);
});

test("a run that failed on its own is untouched by any of this", async () => {
  const r = await stubRun(stubSeat({ route: undefined }), {}, { EPITO_STUB_REFUSE_SAYS: null });
  assert.equal(r.exit, 0, "the stub's ordinary run still ends the way it always did");
  assert.equal(r.refusal, null);
});

test("the board counts a refusal in a column of its own, never as a failure", () => {
  const e = (over) => boardEvent({ agent: "pm", trigger: "bus", ...over }).event;
  const fold = foldBoard([
    e({ runId: "a", outcome: "ok", turns: 6 }),
    e({ runId: "b", outcome: "refused", detail: "Claude AI usage limit reached" }),
    e({ runId: "c", outcome: "refused" }),
    e({ runId: "d", outcome: "clone" }),
  ]);
  assert.equal(fold.seats[0].runs, 4);
  assert.equal(fold.seats[0].refused, 2, "two runs nobody has to go and debug");
  assert.equal(fold.seats[0].failed, 1, "and one that somebody does");
  const text = renderBoard(fold);
  assert.match(text, /SEAT +RUNS +FAILED +REFUSED/, "the column is on the board an owner reads");
  assert.match(text, /Claude AI usage limit reached/, "with the provider's own sentence beside it");
});

test("Slack says 'refused', with an hourglass rather than a warning sign", () => {
  const line = formatLine({
    agent: "engineer", trigger: "bus", turns: null, pr: null, durationMs: 7_000,
    exit: "refused", refusal: { kind: "limit", resetAt: "2026-10-18T05:00:00.000Z", says: "usage limit reached" },
  });
  assert.match(line, /^⏳ engineer · bus · 7s · refused by the provider, back at 2026-10-18 05:00 UTC$/);
  assert.ok(!line.includes("⚠️"), "a quarter of the day's runs posted a warning sign for a bug that did not exist");
  assert.match(formatLine({ agent: "pm", trigger: "cron", exit: 1 }), /^⚠️ pm · cron · exit 1$/, "a real failure is unchanged");
  assert.match(formatLine({ agent: "pm", trigger: "cron", exit: 0, turns: 3 }), /^pm · cron · 3 turns$/);
});

// --- the verdict the bus waits for (src/run.js) ---------------------------
//
// The worker is a different process from the ingress, so the run's own state
// is the only channel between the refusal and the consumer holding the event.
// Driven here with a fake handle: the thing being pinned is the decision, and
// it must not need an engine to check.
const fakeHandle = (answers) => {
  let i = 0;
  return { query: async () => { const a = answers[Math.min(i++, answers.length - 1)]; if (a instanceof Error) throw a; return a; } };
};
const instantly = { now: (() => { let t = 0; return () => (t += 1000); })(), sleep: async () => {} };

test("a refusal travels from the run to the consumer, and nothing else does", async () => {
  const refusal = { kind: "limit", says: "usage limit reached", resetAt: "2026-10-18T05:00:00.000Z" };
  const refused = await awaitProviderVerdict({ handle: fakeHandle([{ past: false }, { refusal, past: false }]), windowMs: 120_000, pollMs: 1, ...instantly });
  assert.deepEqual(refused.refusal, refusal);
  assert.match(refused.why, /refused the run before a first turn/);

  const past = await awaitProviderVerdict({ handle: fakeHandle([{ past: true }]), windowMs: 120_000, pollMs: 1, ...instantly });
  assert.equal(past.refusal, null);
  assert.match(past.why, /got past the provider/);
});

test("the window ends, and a run still going is a run that started", async () => {
  const out = await awaitProviderVerdict({ handle: fakeHandle([{ past: false }]), windowMs: 5_000, pollMs: 1_000, ...instantly });
  assert.equal(out.refusal, null, "the old boundary is the fallback, so this can only ever buy events back");
  assert.match(out.why, /still going 5s in/);
});

test("asking can never un-start a run: a query that throws is not a refusal", async () => {
  const out = await awaitProviderVerdict({ handle: fakeHandle([new Error("engine is not answering")]), windowMs: 120_000, ...instantly });
  assert.equal(out.refusal, null);
  assert.match(out.why, /could not be asked how the provider answered \(engine is not answering\)/);
});
