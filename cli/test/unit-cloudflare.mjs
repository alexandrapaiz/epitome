#!/usr/bin/env node --test
// The Cloudflare target, asserted on the bytes it ships. Run with:
//
//   node --test test/unit-cloudflare.mjs      # from cli/
//
// Two halves, and the second is the point of the file. The first asserts the
// generator: what the manifest becomes, and what it refuses to become. The
// second GENERATES A REAL BUNDLE INTO A TEMP DIRECTORY AND IMPORTS THE WORKER
// OUT OF IT — the same worker.mjs an operator would `wrangler deploy` — then
// drives it with a fake Durable Object and a fake fetch. A worker that only
// ever existed as a template string is a worker nobody has run, and this
// product has been burned once already by a six-PR stack that was green in
// pieces and had never been composed.
//
// Nothing here touches the network, GitHub, Cloudflare or a real key. The RSA
// key the mint tests use is generated in the test, for the test; the point of
// those assertions is that the JWT the Worker signs verifies, and a throwaway
// key proves that exactly as well as a real one and is safe to leave in a log.
import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, rmSync, writeFileSync, mkdirSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { pathToFileURL } from "node:url";
import { generateKeyPairSync, createVerify } from "node:crypto";
import {
  cloudflareBundle, cloudflareBlockers, cloudflareNotes, wranglerConfig,
  agentModule, secretNames, workerName, bundleDir, BINDINGS,
} from "../src/lib/cfpack.js";

const temps = [];
const temp = () => { const d = mkdtempSync(join(tmpdir(), "epito-cf-")); temps.push(d); return d; };
process.on("exit", () => { for (const d of temps) rmSync(d, { recursive: true, force: true }); });

// The daily builder, which is the heaviest of the three frozen seat shapes:
// a schedule, a hook, several roads, one of them with its endpoint behind a
// variable. If the target handles this one it handles the roster.
const BUILDER = {
  agent: { name: "daily-builder", description: "Wakes each morning, works one card, leaves a draft pull request." },
  identity: { scopes: ["github:contents", "github:pull_requests"] },
  trigger: { cron: "0 6 * * *", webhook: true },
  runtime: {
    model: "claude-sonnet-5", entry: "prompts/daily-builder.md", repo: "acme/product",
    max_turns: 120, env: ["MOONSHOT_API_KEY", "GATEWAY_BASE_URL", "GATEWAY_API_KEY"],
    route: [
      { name: "open", model: "kimi-k2-turbo-preview", base_url: "https://api.moonshot.ai/anthropic", token_env: "MOONSHOT_API_KEY" },
      { name: "gateway", model: "claude-sonnet-5", base_url_env: "GATEWAY_BASE_URL", token_env: "GATEWAY_API_KEY" },
      { name: "subscription", model: "claude-sonnet-5" },
    ],
  },
};

const clone = (o) => JSON.parse(JSON.stringify(o));

// ---------------------------------------------------------------------------
// 1. The generator: what a manifest becomes
// ---------------------------------------------------------------------------

test("the Worker's schedule is [trigger].cron, verbatim — no translation layer", () => {
  const config = wranglerConfig(BUILDER);
  assert.deepEqual(config.triggers, { crons: ["0 6 * * *"] });
  // Cloudflare takes the same five UTC fields `epito run` registers, so the
  // one safe thing to do is copy them. A translation is where "it ran at the
  // wrong hour" comes from.
  const odd = clone(BUILDER); odd.trigger.cron = "46 11,23 * * *";
  assert.deepEqual(wranglerConfig(odd).triggers, { crons: ["46 11,23 * * *"] });
});

test("a seat with no cron gets no schedule block at all, rather than a default one", () => {
  const hookOnly = clone(BUILDER); delete hookOnly.trigger.cron;
  const config = wranglerConfig(hookOnly);
  assert.equal(config.triggers, undefined, "an invented schedule is rule 3 broken: a trigger is never defaulted");
  // And the operator is told, because waiting for a 06:00 that was never
  // registered is the failure this note exists to prevent.
  assert.match(cloudflareNotes(hookOnly).join("\n"), /no \[trigger\]\.cron/);
});

test("state is one Durable Object addressed by the agent's name — rule 4, read onto storage", () => {
  const config = wranglerConfig(BUILDER);
  assert.deepEqual(config.durable_objects.bindings, [{ name: BINDINGS.state, class_name: BINDINGS.doClass }]);
  assert.deepEqual(config.migrations, [{ tag: "v1", new_sqlite_classes: [BINDINGS.doClass] }]);
});

test("the compatibility date is pinned, so the same manifest deployed twice is the same runtime", () => {
  assert.equal(wranglerConfig(BUILDER).compatibility_date, wranglerConfig(BUILDER).compatibility_date);
  assert.match(wranglerConfig(BUILDER).compatibility_date, /^\d{4}-\d{2}-\d{2}$/);
});

test("the permissions compiled into the Worker ARE the manifest's scopes, mapped — the ceiling travels", () => {
  const mod = agentModule(BUILDER);
  const facts = JSON.parse(mod.slice(mod.indexOf("{"), mod.lastIndexOf("}") + 1));
  assert.deepEqual(facts.permissions, { contents: "write", pull_requests: "write" });
  assert.deepEqual(facts.scopes, BUILDER.identity.scopes);
  // There is no other input. A Worker cannot ask GitHub for a permission that
  // is not in this object, and this object came out of agent.toml.
  assert.equal(Object.keys(facts.permissions).length, 2);
});

test("the bundle is byte-identical for the same manifest — deploy twice, one agent", () => {
  const a = cloudflareBundle(BUILDER, { source: "agent.toml" });
  const b = cloudflareBundle(BUILDER, { source: "agent.toml" });
  assert.deepEqual(a, b, "a timestamp or a random id in here would make rule 4 unprovable");
});

test("nothing in the bundle is a secret VALUE — rule 1 survives generation", () => {
  // The manifest names three variables. The bundle must carry the NAMES (an
  // operator has to know what to set) and never reach for a value, even
  // though the generator runs in a process that has them.
  process.env.MOONSHOT_API_KEY = "sk-moonshot-NOTAREALKEY";
  process.env.GATEWAY_BASE_URL = "https://gateway.internal.example/anthropic";
  process.env.GATEWAY_API_KEY = "sk-gateway-NOTAREALKEY";
  try {
    const text = cloudflareBundle(BUILDER, { source: "agent.toml" }).map((f) => f.contents).join("\n");
    assert.ok(!text.includes("NOTAREALKEY"), "a key value reached a generated file");
    assert.ok(!text.includes("gateway.internal.example"), "a confidential endpoint reached a generated file — that is exactly what base_url_env exists to prevent");
    assert.ok(text.includes("MOONSHOT_API_KEY") && text.includes("GATEWAY_BASE_URL"), "the names must be there, or nobody knows what to set");
  } finally {
    delete process.env.MOONSHOT_API_KEY; delete process.env.GATEWAY_BASE_URL; delete process.env.GATEWAY_API_KEY;
  }
});

test("the secrets it asks for are derived from the manifest, each one named and explained", () => {
  const names = secretNames(BUILDER).map((s) => s.name);
  assert.deepEqual(names, [
    BINDINGS.door, BINDINGS.appId, BINDINGS.appKey,
    // the floor: "subscription" names no token_env, and a Worker holds no
    // Claude subscription
    "ANTHROPIC_API_KEY",
    "MOONSHOT_API_KEY", "GATEWAY_API_KEY", "GATEWAY_BASE_URL",
  ]);
  for (const s of secretNames(BUILDER)) assert.ok(s.why.length > 20, `${s.name} is asked for without saying what it is for`);
  // A seat with no floor road is not asked for a floor key.
  const keyed = clone(BUILDER); keyed.runtime.route.pop();
  assert.ok(!secretNames(keyed).map((s) => s.name).includes("ANTHROPIC_API_KEY"));
});

test("a seat with two roads sharing one key is asked for that key once", () => {
  const shared = clone(BUILDER);
  shared.runtime.route = [
    { name: "a", model: "m", base_url: "https://a.example", token_env: "SHARED_KEY" },
    { name: "b", model: "m", base_url: "https://b.example", token_env: "SHARED_KEY" },
  ];
  const names = secretNames(shared).map((s) => s.name);
  assert.equal(names.filter((n) => n === "SHARED_KEY").length, 1);
});

// --- what it refuses, and in whose words -----------------------------------

test("a langgraph seat is refused, naming the reason and the runtime that does run it", () => {
  const lg = clone(BUILDER); lg.runtime.adapter = "langgraph"; lg.runtime.graph = "agent";
  const errs = cloudflareBlockers(lg, "agents/x/agent.toml");
  assert.ok(errs.length >= 1);
  const text = errs.join("\n");
  assert.match(text, /spawns no processes/);
  assert.match(text, /Fix: deploy this seat to the resident runtime/);
});

test("a manifest with no [runtime].repo is refused, because the Worker reads its charter out of it", () => {
  const noRepo = clone(BUILDER); delete noRepo.runtime.repo;
  const errs = cloudflareBlockers(noRepo, "agent.toml");
  assert.match(errs.join("\n"), /\[runtime\]\.repo is required/);
  assert.match(errs.join("\n"), /Fix: add repo = "owner\/name"/);
});

test("an unmapped scope is refused here, before anything is written", () => {
  const bad = clone(BUILDER); bad.identity.scopes = ["asana:tasks"];
  assert.match(cloudflareBlockers(bad, "agent.toml").join("\n"), /cannot mint: "asana:tasks"/);
});

test("a cron Cloudflare would reject at deploy time is refused here instead", () => {
  const bad = clone(BUILDER); bad.trigger.cron = "0 99 * * *";
  const text = cloudflareBlockers(bad, "agent.toml").join("\n");
  assert.match(text, /is not a schedule/);
  assert.match(text, /Cloudflare would refuse it at deploy time/);
});

test("a seat with neither trigger is refused — a Worker that never wakes is not an agent", () => {
  const dead = clone(BUILDER); dead.trigger = {};
  assert.match(cloudflareBlockers(dead, "agent.toml").join("\n"), /declares no trigger/);
});

test("a valid seat is refused for nothing", () => {
  assert.deepEqual(cloudflareBlockers(BUILDER, "agent.toml"), []);
});

test("a one-turn edge run against a 120-turn manifest is NAMED, not silently delivered", () => {
  const notes = cloudflareNotes(BUILDER).join("\n");
  assert.match(notes, /max_turns is 120, and an edge run is ONE turn/);
  assert.match(notes, /does not clone/);
});

test("the button is off for a seat that did not declare [trigger].webhook, and the note says why", () => {
  const cronOnly = clone(BUILDER); delete cronOnly.trigger.webhook;
  assert.match(cloudflareNotes(cronOnly).join("\n"), /the page's button is OFF/);
});

test("the default bundle lands under .epito/, which is already gitignored", () => {
  assert.equal(bundleDir("pm"), join(".epito", "cloudflare", "pm"));
  assert.equal(workerName("pm"), "epito-pm");
});

// ---------------------------------------------------------------------------
// 2. The worker, imported out of a bundle this test generated
// ---------------------------------------------------------------------------

// A Durable Object, as much of one as these assertions need: single-threaded,
// key/value storage, addressed by name. `backing` is passed in so a test can
// throw the objects away and keep the disk — which is the whole question
// behind "state that survives".
function fakeNamespace(AgentRuns, env, backing = new Map()) {
  const objects = new Map();
  return {
    idFromName: (name) => ({ name, toString: () => name }),
    get(id) {
      if (!objects.has(id.name)) {
        const storage = {
          async get(k) { return backing.has(`${id.name}:${k}`) ? JSON.parse(backing.get(`${id.name}:${k}`)) : undefined; },
          async put(k, v) { backing.set(`${id.name}:${k}`, JSON.stringify(v)); },
        };
        objects.set(id.name, new AgentRuns({ storage }, env));
      }
      const obj = objects.get(id.name);
      return { fetch: (url, init) => obj.fetch(new Request(url, init)) };
    },
  };
}

// One RSA key pair, generated here, used only here. 2048 bits because that is
// what GitHub issues and what the signature check has to be true of.
const { privateKey, publicKey } = generateKeyPairSync("rsa", {
  modulusLength: 2048,
  publicKeyEncoding: { type: "spki", format: "pem" },
  privateKeyEncoding: { type: "pkcs8", format: "pem" },
});

const CHARTER = "# the daily builder\n\nWork one card. Leave a draft pull request.\n";

// A GitHub and a model that answer, and a log of exactly what was asked of
// them — the mint's ceiling is only assertable by reading the request.
function fakeWorld({ charter = CHARTER, answer = "I would land the open stack.", fail = null } = {}) {
  const asked = [];
  const fetchImpl = async (url, init = {}) => {
    const u = String(url);
    asked.push({ url: u, method: init.method ?? "GET", headers: init.headers ?? {}, body: init.body ? JSON.parse(init.body) : null });
    if (fail && fail.when(u)) return new Response(fail.body ?? "", { status: fail.status });
    if (u.endsWith("/installation")) return Response.json({ id: 4242 });
    if (u.endsWith("/access_tokens")) return Response.json({ token: "ghs_TESTTOKEN", expires_at: "2026-10-18T01:00:00Z" });
    if (u.includes("/contents/")) return new Response(charter);
    if (u.endsWith("/v1/messages")) return Response.json({ content: [{ type: "text", text: answer }], usage: { input_tokens: 10, output_tokens: 20 } });
    return new Response("unexpected", { status: 418 });
  };
  return { fetchImpl, asked };
}

// Generate the bundle, write it, import the worker out of it. Everything
// below runs the artifact, not a copy of it.
async function deployed(manifest = BUILDER, { backing = new Map() } = {}) {
  const dir = temp();
  for (const f of cloudflareBundle(manifest, { source: "agent.toml" })) {
    mkdirSync(join(dir, ".."), { recursive: true });
    writeFileSync(join(dir, f.path), f.contents);
  }
  const mod = await import(pathToFileURL(join(dir, "worker.mjs")).href);
  const env = {
    EPITO_TRIGGER_SECRET: "door-key-for-this-test",
    EPITO_APP_ID: "1234567",
    EPITO_APP_KEY: privateKey,
    ANTHROPIC_API_KEY: "sk-ant-TESTONLY",
  };
  env[BINDINGS.state] = fakeNamespace(mod.AgentRuns, env, backing);
  return { mod, env, dir, backing };
}

const KEY = "door-key-for-this-test";
const get = (path, init) => new Request(`https://epito-daily-builder.workers.dev${path}`, init);

test("the door: no key set on the Worker refuses everything rather than standing open", async () => {
  const { mod, env } = await deployed();
  const res = await mod.default.fetch(get("/"), { ...env, EPITO_TRIGGER_SECRET: undefined }, {});
  assert.equal(res.status, 503);
  const text = await res.text();
  assert.match(text, /refuses everything rather than standing open/);
  assert.match(text, /wrangler secret put EPITO_TRIGGER_SECRET/);
});

test("the door: no key on the request is 401, a wrong key is 403, and both name the fix", async () => {
  const { mod, env } = await deployed();
  const none = await mod.default.fetch(get("/"), env, {});
  assert.equal(none.status, 401);
  assert.match(await none.text(), /\?key=/);
  const wrong = await mod.default.fetch(get("/?key=not-it"), env, {});
  assert.equal(wrong.status, 403);
  assert.match(await wrong.text(), /not this agent's door key/);
});

test("the door takes the link form and the header form, because one is for a person", async () => {
  const { mod, env } = await deployed();
  assert.equal((await mod.default.fetch(get(`/?key=${KEY}`), env, {})).status, 200);
  assert.equal((await mod.default.fetch(get("/", { headers: { "x-epito-secret": KEY } }), env, {})).status, 200);
});

test("the page shows the agent and says it has never run, before it ever has", async () => {
  const { mod, env } = await deployed();
  const html = await (await mod.default.fetch(get(`/?key=${KEY}`), env, {})).text();
  assert.match(html, /daily-builder/);
  assert.match(html, /Wakes each morning/);
  assert.match(html, /0 6 \* \* \*/);
  assert.match(html, /contents:write, pull_requests:write/);
  assert.match(html, /This agent has never run here/);
  assert.match(html, /Run daily-builder now/);
});

test("the button triggers a run: the agent mints its own token, reads its charter, answers, and the page shows it", async () => {
  const { mod, env } = await deployed();
  const { fetchImpl, asked } = fakeWorld();
  const run = await mod.performRun(env, "manual", { fetchImpl });

  assert.equal(run.outcome, "ok");
  assert.equal(run.turns, 1);
  assert.equal(run.route, "subscription", "the two keyed roads are closed on this Worker, so it takes the floor");
  assert.equal(run.detail, "I would land the open stack.");
  assert.equal(run.recorded, true);

  // Its own identity: a JWT signed as the App, not a borrowed credential.
  const inst = asked.find((a) => a.url.endsWith("/installation"));
  const jwt = String(inst.headers.authorization).replace(/^Bearer /, "");
  const [h, p, sig] = jwt.split(".");
  const verify = createVerify("RSA-SHA256");
  verify.update(`${h}.${p}`);
  assert.ok(verify.verify(publicKey, Buffer.from(sig.replace(/-/g, "+").replace(/_/g, "/"), "base64")),
    "the Worker's JWT must verify against the App's public key, or it is not the App");
  const claims = JSON.parse(Buffer.from(p, "base64url").toString());
  assert.equal(claims.iss, "1234567");
  assert.ok(claims.exp - claims.iat <= 600, "GitHub refuses an App JWT longer than ten minutes");

  // Rule 2, on the wire: exactly the mapped permissions, on exactly one repo.
  const mint = asked.find((a) => a.url.endsWith("/access_tokens"));
  assert.deepEqual(mint.body, { repositories: ["product"], permissions: { contents: "write", pull_requests: "write" } });

  // And the charter was read fresh, with the minted token, not with the JWT.
  const read = asked.find((a) => a.url.includes("/contents/"));
  assert.match(read.url, /repos\/acme\/product\/contents\/prompts\/daily-builder\.md$/);
  assert.equal(read.headers.authorization, "Bearer ghs_TESTTOKEN");

  // The page now shows it.
  const html = await (await mod.default.fetch(get(`/?key=${KEY}`), env, {})).text();
  assert.match(html, /I would land the open stack\./);
  assert.match(html, /1 of 120/, "the page says one turn against the manifest's cap, every run");
  assert.ok(!html.includes("ghs_TESTTOKEN"), "a minted token must never reach the page");
  assert.ok(!html.includes("sk-ant-TESTONLY"), "a model key must never reach the page");
});

test("POST /runs is the button: it runs the agent and sends a browser back to the page", async () => {
  const { mod, env } = await deployed();
  globalThis.__epitoTestFetch = undefined;
  const res = await mod.default.fetch(
    get(`/runs?key=${KEY}`, { method: "POST", headers: { accept: "application/json" } }), env, {});
  assert.equal(res.status, 200);
  const run = await res.json();
  // No fake world here, so the real `fetch` is what it reached for and failed
  // on; what matters is that the press produced a RUN RECORD and recorded it.
  assert.equal(run.trigger, "manual");
  assert.equal(run.recorded, true);
  assert.ok(["error", "blocked"].includes(run.outcome));

  const html = await mod.default.fetch(
    get(`/runs?key=${KEY}`, { method: "POST", headers: { accept: "text/html" } }), env, {});
  assert.equal(html.status, 303, "a browser that pressed a button wants the page back");
  assert.equal(html.headers.get("location"), `/?key=${KEY}`);
});

test("a seat with no [trigger].webhook refuses to be woken by hand, naming the rule", async () => {
  const cronOnly = clone(BUILDER); delete cronOnly.trigger.webhook;
  const { mod, env } = await deployed(cronOnly);
  const res = await mod.default.fetch(get(`/runs?key=${KEY}`, { method: "POST" }), env, {});
  assert.equal(res.status, 405);
  assert.match(await res.text(), /explicit and never defaulted/);
  const html = await (await mod.default.fetch(get(`/?key=${KEY}`), env, {})).text();
  assert.match(html, /No button/);
});

test("the schedule fires the same run the button does", async () => {
  const { mod, env } = await deployed();
  const run = await mod.default.scheduled({ cron: "0 6 * * *" }, env, {});
  assert.equal(run.trigger, "cron");
  assert.equal(run.recorded, true);
});

test("state survives: the objects are thrown away and the runs are still there", async () => {
  const backing = new Map();
  const first = await deployed(BUILDER, { backing });
  const { fetchImpl } = fakeWorld({ answer: "the first thing I would do" });
  await first.mod.performRun(first.env, "cron", { fetchImpl });

  // A redeploy: new Worker instance, new Durable Object instances, same
  // storage — which is what Cloudflare does and what the agent's name
  // addressing it is for.
  const second = await deployed(BUILDER, { backing });
  const html = await (await second.mod.default.fetch(get(`/?key=${KEY}`), second.env, {})).text();
  assert.match(html, /the first thing I would do/);
  assert.match(html, /1 total/);
});

test("the run log keeps order and counts every run, not just the kept ones", async () => {
  const { mod, env } = await deployed();
  const { fetchImpl } = fakeWorld({ answer: "a" });
  for (let i = 0; i < 3; i++) await mod.performRun(env, i === 0 ? "cron" : "manual", { fetchImpl });
  const state = await (await mod.default.fetch(get(`/api/state?key=${KEY}`), env, {})).json();
  assert.equal(state.count, 3);
  assert.equal(state.runs.length, 3);
  assert.ok(state.runs[0].startedAt >= state.runs[2].startedAt, "newest first");
  assert.equal(state.agent.name, "daily-builder");
});

// --- the three ways a run goes wrong, each said in words -------------------

test("an App key the runtime cannot read blocks the run, and names the converted copy", async () => {
  const { mod, env } = await deployed();
  const pkcs1 = { ...env, EPITO_APP_KEY: "-----BEGIN RSA PRIVATE KEY-----\nMIIE\n-----END RSA PRIVATE KEY-----\n" };
  const run = await mod.performRun(pkcs1, "manual", { fetchImpl: fakeWorld().fetchImpl });
  assert.equal(run.outcome, "blocked", "a run that could never have started is not an 'error' — the page says which");
  assert.match(run.detail, /PKCS#1/);
  assert.match(run.detail, /pkcs8\.pem/);
});

test("an App installed nowhere blocks the run with the install step, not a status code", async () => {
  const { mod, env } = await deployed();
  const { fetchImpl } = fakeWorld({ fail: { when: (u) => u.endsWith("/installation"), status: 404 } });
  const run = await mod.performRun(env, "manual", { fetchImpl });
  assert.equal(run.outcome, "blocked");
  assert.match(run.detail, /not installed on acme\/product/);
  assert.match(run.detail, /install the App on that repository once/);
});

test("a charter that is not in the repository blocks the run and names [runtime].entry", async () => {
  const { mod, env } = await deployed();
  const { fetchImpl } = fakeWorld({ fail: { when: (u) => u.includes("/contents/"), status: 404 } });
  const run = await mod.performRun(env, "manual", { fetchImpl });
  assert.equal(run.outcome, "blocked");
  assert.match(run.detail, /prompts\/daily-builder\.md is not in acme\/product/);
});

test("every road closed is a blocked run naming each one and the edge's floor", async () => {
  const { mod, env } = await deployed();
  const noKeys = { ...env, ANTHROPIC_API_KEY: undefined };
  const run = await mod.performRun(noKeys, "manual", { fetchImpl: fakeWorld().fetchImpl });
  assert.equal(run.outcome, "blocked");
  assert.match(run.detail, /"open" \(\$MOONSHOT_API_KEY is not set on this Worker\)/);
  // The key is asked about before the endpoint, the same order liveRoutes
  // uses on a box: a road with neither is closed for the first thing missing,
  // and naming both would be a list nobody acts on.
  assert.match(run.detail, /"gateway" \(\$GATEWAY_API_KEY is not set on this Worker\)/);
  assert.match(run.detail, /"subscription" \(\$ANTHROPIC_API_KEY is not set on this Worker\)/);
  assert.match(run.detail, /a Worker cannot hold a subscription/);
});

test("the road order is the manifest's, and a road whose key arrives is taken first", async () => {
  const { mod, env } = await deployed();
  const withKey = { ...env, MOONSHOT_API_KEY: "sk-moonshot-TESTONLY" };
  const asks = [];
  const { fetchImpl } = fakeWorld();
  const run = await mod.performRun(withKey, "manual", {
    fetchImpl: async (u, i) => { asks.push(String(u)); return fetchImpl(u, i); },
  });
  assert.equal(run.route, "open");
  assert.equal(run.model, "kimi-k2-turbo-preview");
  assert.ok(asks.some((u) => u === "https://api.moonshot.ai/anthropic/v1/messages"),
    "the road's own endpoint, not api.anthropic.com");
});

test("an endpoint variable set to something that is not a URL closes that road by name", async () => {
  const { mod, env } = await deployed();
  const typo = { ...env, GATEWAY_API_KEY: "sk-gw-TESTONLY", GATEWAY_BASE_URL: "gateway.internal.example", ANTHROPIC_API_KEY: undefined };
  const run = await mod.performRun(typo, "manual", { fetchImpl: fakeWorld().fetchImpl });
  assert.match(run.detail, /\$GATEWAY_BASE_URL is set but does not hold an http\(s\) URL/);
  assert.ok(!run.detail.includes("gateway.internal.example"), "the value of a confidential endpoint is printed nowhere, including in a refusal");
});

test("a provider that answers 500 is an error, not a blocked run — the road worked, the call did not", async () => {
  const { mod, env } = await deployed();
  const { fetchImpl } = fakeWorld({ fail: { when: (u) => u.endsWith("/v1/messages"), status: 500, body: "upstream down" } });
  const run = await mod.performRun(env, "manual", { fetchImpl });
  assert.equal(run.outcome, "error");
  assert.match(run.detail, /answered 500/);
  assert.ok(!run.detail.includes("sk-ant-TESTONLY"));
});

test("the prompt carries the charter and tells the agent what an edge run is", async () => {
  const { mod } = await deployed();
  const prompt = mod.edgePrompt(CHARTER);
  assert.ok(prompt.startsWith(CHARTER), "the charter leads; the agent is itself first");
  assert.match(prompt, /no\s+clone, no shell, no filesystem/);
  assert.match(prompt, /single turn/);
});

test("an address this agent does not answer names the three it does", async () => {
  const { mod, env } = await deployed();
  const res = await mod.default.fetch(get(`/wake?key=${KEY}`), env, {});
  assert.equal(res.status, 404);
  const text = await res.text();
  assert.match(text, /GET \/ \(the page\)/);
  assert.match(text, /POST \/runs/);
  assert.match(text, /GET \/api\/state/);
});
