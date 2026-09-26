#!/usr/bin/env node --test
// Unit tests for the parts that need no server: the reconcile diff, the
// manifest additions, and the clone-path guard. Run with:
//
//   node --test test/unit.mjs      # from cli/
//
// The reconcile diff is a pure function of (desired roster, schedules already
// registered), which is the whole reason `epito run` is safe to re-run: these
// six cases are the command's entire behavior.
import { test } from "node:test";
import assert from "node:assert/strict";
import { reconcilePlan, scheduleShape } from "../src/temporal/schedules.js";
import { validateManifest } from "../src/lib/manifest.js";
import { webhookName } from "../src/lib/slack.js";
import { isCloneDir, cloneDirPrefix, executeAgent } from "../src/lib/runner.js";
import { permissionsFor, appJwt, envNames, loadPrincipal, SCOPE_MAP } from "../src/lib/identity.js";
import { generateKeyPairSync, createVerify } from "node:crypto";
import { readFileSync, writeFileSync, mkdtempSync, rmSync } from "node:fs";
import { seatOfWorkflowId, scheduleId, runId, windowId } from "../src/temporal/env.js";
import { tmpdir } from "node:os";
import { join } from "node:path";

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

test("reconcile: 36 presence-only seats register nothing at all", () => {
  const p = reconcilePlan(new Map(), []);
  assert.deepEqual(p, { create: [], update: [], delete: [], unchanged: [] });
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
  assert.equal(errs[0], `[runtime].slack_webhook_env "https://hooks.slack.com/services/x" must be the NAME of an environment variable (letters, digits, underscore) — the webhook URL itself never appears in the manifest`);
});

test("[runtime].slack_webhook_env must also be listed under [runtime].env", () => {
  const errs = errorsFor({ runtime: { slack_webhook_env: "SLACK_WEBHOOK_URL_URSA", env: ["GH_TOKEN"] } });
  assert.equal(errs.length, 1);
  assert.equal(errs[0], `[runtime].slack_webhook_env names "SLACK_WEBHOOK_URL_URSA", so "SLACK_WEBHOOK_URL_URSA" must also be listed in [runtime].env — the runtime injects only the names the manifest lists, so an unlisted webhook can never resolve to a value`);
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
  const dir = mkdtempSync(join(tmpdir(), "epito-unit-"));
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
  const p = loadPrincipal("pm", { env, dir: mkdtempSync(join(tmpdir(), "epito-unit-")) });
  assert.equal(p.appId, "99", "an App id from the environment is a string");
  assert.equal(p.privateKey, pem, "a single-line PEM is unescaped before use");
  assert.equal(p.installationId, null, "discovered from [runtime].repo when unnamed");
  assert.equal(loadPrincipal("okr", { env, dir: "." }), null, "no App is not an error here");
});

// --- identity: the token reaches the child and not the log ----------------

test("a minted token is injected into the run and scrubbed out of its log", async () => {
  const dir = mkdtempSync(join(tmpdir(), "epito-unit-"));
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
  const dir = mkdtempSync(join(tmpdir(), "epito-unit-"));
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
