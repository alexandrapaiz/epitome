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
import { reconcilePlan, scheduleShape } from "../src/temporal/schedules.js";
import { validateManifest, loadManifest, FIELDS, TABLES } from "../src/lib/manifest.js";
import { webhookName } from "../src/lib/slack.js";
import { isCloneDir, cloneDirPrefix, executeAgent, cloneAgentRepo, gitEnvFor, GIT_TOKEN_ENV } from "../src/lib/runner.js";
import { permissionsFor, appJwt, envNames, loadPrincipal, SCOPE_MAP } from "../src/lib/identity.js";
import { spawn } from "node:child_process";
import { parse } from "smol-toml";
import { mkdirSync } from "node:fs";
import { once } from "node:events";
import { generateKeyPairSync, createVerify } from "node:crypto";
import { readFileSync, writeFileSync, mkdtempSync, rmSync, existsSync, chmodSync } from "node:fs";
import { seatOfWorkflowId, scheduleId, runId, windowId } from "../src/temporal/env.js";
import { justCompleted, sendOrRestart } from "../src/run.js";
import { ADAPTERS, ADAPTER_NAMES, adapterFor, unknownAdapter, LANGGRAPH_SHIM } from "../src/lib/adapters.js";
import {
  routesFor, routeErrors, liveRoutes, noRouteMessage, anthropicRouteEnv, routeFacts,
  classifyAttempt, withLane, DEFAULT_ROUTE, ROUTE_FIELDS,
} from "../src/lib/router.js";
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
  assert.match(parseFlags(["--outcome", "ok", "--pr-url", "x"], ["outcome", "pr"]).error, /unknown option "--pr-url"/);
  const { flags, rest } = parseFlags(["pm", "--outcome=mint", "--pr", "https://x/1", "--json"], ["outcome", "pr", "json"]);
  assert.deepEqual(rest, ["pm"]);
  assert.deepEqual(flags, { outcome: "mint", pr: "https://x/1", json: true }, "--flag=value, --flag value, and a bare --flag");
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
  for (const [k, v] of Object.entries(env)) { saved[k] = process.env[k]; process.env[k] = v; }
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
    env: ["MOONSHOT_API_KEY", "EPITO_STUB_DIR", "EPITO_STUB_REFUSE_BASE_URL", "EPITO_STUB_ECHO_ROUTE"],
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
  const r = await stubRun(stubSeat(), {}, { MOONSHOT_API_KEY: "" });
  assert.equal(r.exit, 0);
  assert.equal(r.route, "subscription");
  assert.equal(r.attempts.length, 1, "a skipped road is not an attempt");
  assert.match(r.logged, /route "kimi" \(kimi-k2-turbo-preview\) skipped: MOONSHOT_API_KEY is not set/);
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
  // The seat could never have fired, and the triad rule now says so too.
  assert.ok(errs.some((e) => /needs at least one of: cron .* or webhook/.test(e)), errs.join("\n"));
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
