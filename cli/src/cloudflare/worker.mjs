// The agent, as a Cloudflare Worker.
//
// This file is copied verbatim into every bundle `epito deploy --target
// cloudflare` writes; the only thing that differs between two agents is the
// generated `agent.js` beside it. It is a real file in the package rather
// than a template string so that it can be linted, read, and — the part that
// matters — IMPORTED BY THE TEST SUITE out of a bundle the suite generated.
// A worker that only exists as a string is a worker nobody has run.
//
// It uses nothing but platform globals (fetch, crypto.subtle, Response, URL,
// atob), and imports nothing from `cloudflare:`. That is what lets Node run
// it. Everything Cloudflare-specific arrives through `env`.
//
// The four things the agent has, and where each one is below:
//
//   its own identity   `mintToken` — it signs a JWT as its OWN GitHub App and
//                      mints an installation token for exactly the
//                      permissions its manifest declares, on exactly the one
//                      repository. No owner credential is anywhere near it.
//   a schedule         `scheduled` — wired by triggers.crons in wrangler.jsonc,
//                      which is [trigger].cron copied verbatim.
//   state that survives  the AgentRuns Durable Object. One per agent, named
//                      after the agent, so a redeploy keeps the history.
//   a page             `page` — the agent, its last run, and a button.
//
// What an edge run IS: one turn. Mint, read the charter out of the seat's own
// repository, ask the model once, record the answer. It does not clone,
// commit or open a pull request, because a Worker has no git and no disk. The
// page says that on every run; a one-turn run quietly presented as a full
// seat is exactly the kind of silence this product refuses elsewhere.
import { AGENT } from "./agent.js";

const GITHUB_API = "https://api.github.com";
const ANTHROPIC_DEFAULT = "https://api.anthropic.com";
const ANTHROPIC_VERSION = "2023-06-01";
const DOOR = "EPITO_TRIGGER_SECRET";
const APP_ID = "EPITO_APP_ID";
const APP_KEY = "EPITO_APP_KEY";
const MODEL_KEY = "ANTHROPIC_API_KEY";
const STATE = "RUNS";
// How many runs the page and the object keep. A prototype's memory, not an
// archive: the ledger on a box is `epito audit`, and the equivalent here is a
// card for the run after this one.
const KEEP_RUNS = 20;
// A model answer is recorded, and a Durable Object value is not a log sink.
const DETAIL_CAP = 4000;

// A refusal the operator can act on: the rule, in the product's words, with
// the fix. The same bar `epito validate` sets, held on a surface where the
// reader cannot open a terminal and ask again.
const refuse = (status, text) => new Response(`epito: ${text}\n`, {
  status, headers: { "content-type": "text/plain; charset=utf-8" },
});
const json = (body, status = 200) => new Response(JSON.stringify(body, null, 2) + "\n", {
  status, headers: { "content-type": "application/json; charset=utf-8" },
});

const blocked = (msg) => Object.assign(new Error(msg), { blocked: true });

// --- the one door ---------------------------------------------------------
// Every request carries the secret: as `?key=` (so a link is a link the owner
// can open) or as `x-epito-secret` (so a script is a script). Same header the
// resident runtime's ingress reads, deliberately — one word to learn.
//
// There is no unauthenticated page, not even a read-only one. A run record
// holds whatever the agent said, and the agent reads a private repository.

function sameSecret(a, b) {
  if (typeof a !== "string" || typeof b !== "string" || a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}

export function checkDoor(request, env) {
  const expected = env[DOOR];
  if (!expected) {
    return refuse(503, `this agent has no door key, so it refuses everything rather than standing open: $${DOOR} is not set on this Worker. Fix: \`wrangler secret put ${DOOR}\` with a long random string, then open the page as .../?key=<that string>.`);
  }
  const url = new URL(request.url);
  const given = request.headers.get("x-epito-secret") ?? url.searchParams.get("key");
  if (!given) {
    return refuse(401, `this agent's page is behind one door and the request carried no key. Fix: open .../?key=<$${DOOR}>, or send it as the x-epito-secret header.`);
  }
  if (!sameSecret(given, expected)) {
    return refuse(403, `that is not this agent's door key. Fix: the value is whatever was set with \`wrangler secret put ${DOOR}\`; Cloudflare will not show it back to you, so rotate it (set it again) if it is lost.`);
  }
  return null;
}

// --- state that survives --------------------------------------------------
// One Durable Object per agent, addressed by the agent's NAME. That is spec
// rule 4 — one manifest, one principal — read onto storage: deploying the
// same manifest twice keeps this history, and renaming the agent starts a new
// one, exactly as renaming starts a new identity.

export class AgentRuns {
  constructor(state, env) { this.state = state; this.env = env; }

  async fetch(request) {
    const url = new URL(request.url);
    if (url.pathname === "/record") {
      const run = await request.json();
      const runs = (await this.state.storage.get("runs")) ?? [];
      const count = (await this.state.storage.get("count")) ?? 0;
      runs.unshift(run);
      await this.state.storage.put("runs", runs.slice(0, KEEP_RUNS));
      await this.state.storage.put("count", count + 1);
      return json({ recorded: run.id });
    }
    if (url.pathname === "/state") {
      return json({
        runs: (await this.state.storage.get("runs")) ?? [],
        count: (await this.state.storage.get("count")) ?? 0,
      });
    }
    return refuse(404, `the run store answers /state and /record, not ${url.pathname} — this is an internal address and nothing outside this Worker should be asking for it.`);
  }
}

function store(env) {
  const ns = env[STATE];
  if (!ns) throw blocked(`this Worker has no ${STATE} binding, so an agent that ran would have nowhere to remember it. Fix: deploy with the generated wrangler.jsonc, which declares the Durable Object; a hand-edited config that dropped the binding is the usual cause.`);
  return ns.get(ns.idFromName(AGENT.name));
}

async function readState(env) {
  const res = await store(env).fetch("https://runs.epito/state");
  return res.json();
}

async function writeRun(env, run) {
  await store(env).fetch("https://runs.epito/record", {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify(run),
  });
}

// --- its own identity -----------------------------------------------------
// The mint, on WebCrypto. Same five steps lib/identity.js takes on a box:
// sign a short JWT as the App, find the installation on [runtime].repo, ask
// for exactly the permissions the manifest maps to, on exactly that one
// repository. Rule 2 — scopes are the ceiling — is enforced by the fact that
// `AGENT.permissions` is generated from the manifest at pack time and is the
// only thing this function can ask for.

const b64url = (bytes) => {
  let s = "";
  for (const b of bytes) s += String.fromCharCode(b);
  return btoa(s).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
};
const utf8 = (s) => new TextEncoder().encode(s);

export function pemToDer(pem) {
  const text = String(pem).replace(/\\n/g, "\n");
  if (/BEGIN RSA PRIVATE KEY/.test(text)) {
    throw blocked(`$${APP_KEY} holds a PKCS#1 key ("BEGIN RSA PRIVATE KEY"), which is what GitHub hands you and which the Workers runtime cannot read — WebCrypto imports PKCS#8 only. Fix: \`epito deploy --target cloudflare\` writes the converted copy beside the original as .epito/keys/<agent>.pkcs8.pem; set that one.`);
  }
  const body = text.replace(/-----(BEGIN|END)[^-]+-----/g, "").replace(/\s+/g, "");
  if (!body) throw blocked(`$${APP_KEY} does not hold a PEM private key, so this agent has no identity to mint from and the run stops before it touches GitHub. Fix: \`wrangler secret put ${APP_KEY}\` with the contents of .epito/keys/<agent>.pkcs8.pem.`);
  const raw = atob(body);
  const der = new Uint8Array(raw.length);
  for (let i = 0; i < raw.length; i++) der[i] = raw.charCodeAt(i);
  return der;
}

export async function appJwt(appId, pem, nowSec = Math.floor(Date.now() / 1000)) {
  let key;
  try {
    key = await crypto.subtle.importKey("pkcs8", pemToDer(pem), { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" }, false, ["sign"]);
  } catch (e) {
    if (e.blocked) throw e;
    throw blocked(`$${APP_KEY} is not a private key this runtime can import (${e.message}). Fix: set it to the PKCS#8 copy epito wrote at .epito/keys/<agent>.pkcs8.pem — the value is never printed anywhere, so a half-pasted PEM looks exactly like a correct one until here.`);
  }
  // Ten minutes is GitHub's ceiling; nine keeps us inside it with a minute of
  // clock skew either side, the same window lib/identity.js uses on a box.
  const header = b64url(utf8(JSON.stringify({ alg: "RS256", typ: "JWT" })));
  const payload = b64url(utf8(JSON.stringify({ iat: nowSec - 60, exp: nowSec + 540, iss: String(appId) })));
  const signed = `${header}.${payload}`;
  const sig = await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, utf8(signed));
  return `${signed}.${b64url(new Uint8Array(sig))}`;
}

async function gh(fetchImpl, url, { method = "GET", bearer, token, body, accept = "application/vnd.github+json" } = {}) {
  const res = await fetchImpl(url, {
    method,
    headers: {
      accept,
      "user-agent": `epito/${AGENT.name}`,
      "x-github-api-version": "2022-11-28",
      authorization: `Bearer ${bearer ?? token}`,
      ...(body ? { "content-type": "application/json" } : {}),
    },
    ...(body ? { body: JSON.stringify(body) } : {}),
  });
  return res;
}

export async function mintToken(env, fetchImpl = fetch, nowSec) {
  const appId = env[APP_ID];
  if (!appId || !env[APP_KEY]) {
    throw blocked(`"${AGENT.name}" has no identity on this Worker: ${!appId ? `$${APP_ID}` : `$${APP_KEY}`} is not set, and an agent with no App of its own would have to borrow somebody's credential to read its charter. Fix: \`wrangler secret put ${APP_ID}\` and \`wrangler secret put ${APP_KEY}\` with this agent's own App id and PKCS#8 key (\`epito deploy\` created the App; \`epito deploy --target cloudflare\` wrote the converted key).`);
  }
  const jwt = await appJwt(appId, env[APP_KEY], nowSec);
  const found = await gh(fetchImpl, `${GITHUB_API}/repos/${AGENT.repo}/installation`, { bearer: jwt });
  if (!found.ok) {
    throw blocked(found.status === 404
      ? `"${AGENT.name}"'s GitHub App is not installed on ${AGENT.repo}, so it cannot read its own charter there. Fix: install the App on that repository once, in a browser — \`epito deploy\` prints the link.`
      : `GitHub refused to say where "${AGENT.name}"'s App is installed (${found.status}). An App id and key that do not match is the usual cause, and GitHub answers that the same way it answers a real 401. Fix: check $${APP_ID} against the App whose key is in $${APP_KEY}.`);
  }
  const installation = await found.json();
  const minted = await gh(fetchImpl, `${GITHUB_API}/app/installations/${installation.id}/access_tokens`, {
    method: "POST",
    bearer: jwt,
    // The ceiling, and the whole of it. `repositories` is the one repo the
    // manifest names; `permissions` is [identity].scopes mapped at pack time.
    body: { repositories: [String(AGENT.repo).split("/")[1]], permissions: AGENT.permissions },
  });
  if (!minted.ok) {
    const detail = await minted.text().catch(() => "");
    throw blocked(`GitHub refused to mint "${AGENT.name}"'s token (${minted.status}${detail ? `: ${detail.slice(0, 200)}` : ""}). A permission the installation does not hold is the usual cause: this agent asks for exactly ${Object.entries(AGENT.permissions).map(([k, v]) => `${k}:${v}`).join(", ")}, from [identity].scopes. Fix: approve the permission on the App's installation, or narrow the scopes in the manifest and deploy again.`);
  }
  const body = await minted.json();
  if (!body?.token) throw blocked(`GitHub answered the mint without a token, so there is nothing to read the charter with. Fix: try again; if it repeats, check the App's installation on ${AGENT.repo}.`);
  return body.token;
}

// --- what the agent reads -------------------------------------------------
// Fetched every run, never compiled in. The charter is the thing that
// changes, and an agent running a stale copy of its own charter is the bug
// the resident runtime avoids by cloning fresh — the edge avoids it by
// reading fresh.

export async function readCharter(env, token, fetchImpl = fetch) {
  const ref = AGENT.ref ? `?ref=${encodeURIComponent(AGENT.ref)}` : "";
  const url = `${GITHUB_API}/repos/${AGENT.repo}/contents/${AGENT.entry.split("/").map(encodeURIComponent).join("/")}${ref}`;
  const res = await gh(fetchImpl, url, { token, accept: "application/vnd.github.raw" });
  if (!res.ok) {
    throw blocked(res.status === 404
      ? `"${AGENT.name}" has no charter to run: ${AGENT.entry} is not in ${AGENT.repo}${AGENT.ref ? ` at ${AGENT.ref}` : ""}. [runtime].entry is a path inside [runtime].repo. Fix: correct entry in the manifest and deploy again, or add the file.`
      : `GitHub refused to hand over ${AGENT.entry} (${res.status}), so the run has no charter. "contents" is in this agent's scopes, so a 403 here is usually the installation not covering ${AGENT.repo}. Fix: check the App's installation on that repository.`);
  }
  const text = await res.text();
  if (!text.trim()) {
    throw blocked(`${AGENT.entry} in ${AGENT.repo} is empty, and an empty charter is an agent with no instructions — it would run and do nothing, which reads like a working deploy. Fix: write the charter, or point [runtime].entry at the file that holds it.`);
  }
  return text;
}

// --- the road to the model ------------------------------------------------
// Same chain the manifest declares, in the same order, skipped for the same
// reason: a road whose key this Worker does not hold is a road it cannot
// take. The one difference from a box is the floor — a box's last road runs
// on the operator's Claude subscription, and a Worker cannot hold one, so the
// bottom road here runs on $ANTHROPIC_API_KEY.

export function pickRoad(env) {
  const closed = [];
  for (const road of AGENT.routes) {
    const keyName = road.tokenEnv ?? MODEL_KEY;
    const key = (env[keyName] ?? "").trim();
    if (!key) {
      closed.push(`"${road.name}" ($${keyName} is ${env[keyName] === undefined ? "not set on this Worker" : "set and holds nothing"})`);
      continue;
    }
    let baseUrl = road.baseUrl;
    if (road.baseUrlEnv) {
      const raw = (env[road.baseUrlEnv] ?? "").trim();
      if (!raw) { closed.push(`"${road.name}" ($${road.baseUrlEnv} holds no endpoint)`); continue; }
      let u = null;
      try { u = new URL(raw); } catch { u = null; }
      if (!u || !/^https?:$/.test(u.protocol)) { closed.push(`"${road.name}" ($${road.baseUrlEnv} is set but does not hold an http(s) URL; its value is printed nowhere)`); continue; }
      if (u.username || u.password) { closed.push(`"${road.name}" ($${road.baseUrlEnv} holds a URL with a credential in it, and a run's road is written into the run record)`); continue; }
      baseUrl = raw;
    }
    return { name: road.name, model: road.model, baseUrl: baseUrl ?? ANTHROPIC_DEFAULT, key, keyName, custom: Boolean(baseUrl) };
  }
  throw blocked(`every road "${AGENT.name}" declares is closed on this Worker — ${closed.join(", ")}. Fix: \`wrangler secret put\` one of those names. On a box the last road is the operator's Claude subscription; a Worker cannot hold a subscription, so the floor here is $${MODEL_KEY}.`);
}

export async function askModel(road, prompt, fetchImpl = fetch) {
  const url = `${String(road.baseUrl).replace(/\/+$/, "")}/v1/messages`;
  // A custom endpoint speaks the Anthropic API behind a bearer token (that is
  // what ANTHROPIC_AUTH_TOKEN means to the runtime on a box); api.anthropic.com
  // takes x-api-key. Sending the wrong one is a 401 that reads like a bad key.
  const auth = road.custom ? { authorization: `Bearer ${road.key}` } : { "x-api-key": road.key };
  const res = await fetchImpl(url, {
    method: "POST",
    headers: { "content-type": "application/json", "anthropic-version": ANTHROPIC_VERSION, ...auth },
    body: JSON.stringify({
      model: road.model,
      max_tokens: 1024,
      messages: [{ role: "user", content: prompt }],
    }),
  });
  if (!res.ok) {
    const detail = await res.text().catch(() => "");
    throw new Error(`the road "${road.name}" answered ${res.status} for ${road.model}${detail ? `: ${detail.slice(0, 300)}` : ""}. Fix: check $${road.keyName} against ${road.baseUrl}; the key's value is printed nowhere, including here.`);
  }
  const body = await res.json();
  const text = (body?.content ?? []).filter((c) => c?.type === "text").map((c) => c.text).join("\n").trim();
  if (!text) throw new Error(`the road "${road.name}" answered with no text at all, so the run has nothing to record. Fix: nothing to do here — this is the provider; try again.`);
  return { text, usage: body?.usage ?? null };
}

// The one turn. A charter written for a seat that clones, commits and opens
// pull requests is being asked for something smaller, and it is told so
// plainly rather than being left to discover it has no git.
export function edgePrompt(charter) {
  return `${charter}

---

You are running as ${AGENT.name} on Cloudflare, in a single turn, with no
clone, no shell, no filesystem and no ability to push or open a pull request.
Your charter above describes the full seat; this run is a prototype of it.

Answer in at most 200 words: given the charter above, what is the one thing
you would do on your next full run, and why that one?`;
}

// --- a run ----------------------------------------------------------------

export async function performRun(env, trigger, { fetchImpl = fetch, now = Date.now } = {}) {
  const t0 = now();
  const run = {
    id: `${new Date(t0).toISOString().replace(/[-:.]/g, "").slice(0, 15)}-${trigger}`,
    trigger,
    startedAt: new Date(t0).toISOString(),
    agent: AGENT.name,
    outcome: "error",
    turns: 0,
    maxTurns: AGENT.maxTurns,
    route: null,
    model: null,
    detail: "",
  };
  try {
    const road = pickRoad(env);
    run.route = road.name;
    run.model = road.model;
    const token = await mintToken(env, fetchImpl);
    const charter = await readCharter(env, token, fetchImpl);
    const answer = await askModel(road, edgePrompt(charter), fetchImpl);
    run.turns = 1;
    run.outcome = "ok";
    run.detail = answer.text.slice(0, DETAIL_CAP);
    if (answer.usage) run.usage = answer.usage;
  } catch (e) {
    // `blocked` is this Worker's half of the same split lib/identity.js makes
    // on a box: a run that could never have started (a secret missing, a key
    // that is not a key, an App installed nowhere) is a different thing from
    // a run that started and went wrong, and the page says which.
    run.outcome = e.blocked ? "blocked" : "error";
    run.detail = String(e.message ?? e).slice(0, DETAIL_CAP);
  }
  const t1 = now();
  run.finishedAt = new Date(t1).toISOString();
  run.seconds = Math.max(0, Math.round((t1 - t0) / 100) / 10);
  try { await writeRun(env, run); run.recorded = true; }
  catch (e) { run.recorded = false; run.detail += `\n\n(this run was not recorded: ${e.message})`; }
  return run;
}

// --- the page -------------------------------------------------------------

const esc = (s) => String(s ?? "").replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
const OUTCOME = { ok: "#1a7f37", error: "#cf222e", blocked: "#9a6700" };

function runRow(run) {
  return `<tr>
  <td><code>${esc(run.startedAt)}</code></td>
  <td>${esc(run.trigger)}</td>
  <td style="color:${OUTCOME[run.outcome] ?? "#57606a"};font-weight:600">${esc(run.outcome)}</td>
  <td>${esc(run.route ?? "—")}</td>
  <td>${esc(run.seconds ?? "—")}s</td>
</tr>`;
}

export function page({ runs = [], count = 0, key = "" }) {
  const last = runs[0] ?? null;
  const q = key ? `?key=${encodeURIComponent(key)}` : "";
  const button = AGENT.webhook
    ? `<form method="post" action="/runs${q}">
  <button type="submit" style="font:inherit;padding:.6rem 1.2rem;border:0;border-radius:6px;background:#1f6feb;color:#fff;cursor:pointer">Run ${esc(AGENT.name)} now</button>
  <span style="color:#57606a;margin-left:.75rem">one turn, about ten seconds</span>
</form>`
    : `<p style="color:#9a6700"><b>No button.</b> This agent's manifest does not declare
<code>[trigger].webhook</code>, and a seat that did not ask to be woken by hand is not
woken by hand. Add <code>webhook = true</code> under <code>[trigger]</code> and deploy again.</p>`;

  return `<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>${esc(AGENT.name)} — an agent on Cloudflare</title>
<style>
 body{font:16px/1.6 -apple-system,BlinkMacSystemFont,"Segoe UI",system-ui,sans-serif;margin:0;color:#1f2328;background:#f6f8fa}
 main{max-width:52rem;margin:0 auto;padding:3rem 1.25rem 5rem}
 h1{margin:0;font-size:2rem}
 .sub{color:#57606a;margin:.25rem 0 2rem}
 .card{background:#fff;border:1px solid #d1d9e0;border-radius:10px;padding:1.25rem 1.5rem;margin-bottom:1.25rem}
 dl{display:grid;grid-template-columns:11rem 1fr;gap:.4rem 1rem;margin:0}
 dt{color:#57606a}
 dd{margin:0}
 code{background:#f6f8fa;border:1px solid #d1d9e0;border-radius:4px;padding:.05rem .3rem;font-size:.9em}
 table{border-collapse:collapse;width:100%;font-size:.92rem}
 th,td{text-align:left;padding:.35rem .5rem;border-bottom:1px solid #eaeef2}
 th{color:#57606a;font-weight:600}
 pre{background:#f6f8fa;border:1px solid #d1d9e0;border-radius:6px;padding:.9rem;overflow:auto;white-space:pre-wrap;font-size:.9rem}
 .note{color:#57606a;font-size:.9rem}
</style></head>
<body><main>
<h1>${esc(AGENT.name)}</h1>
<p class="sub">${esc(AGENT.description)}</p>

<div class="card">
<h2 style="margin-top:0;font-size:1.05rem">Who it is, and when it wakes</h2>
<dl>
  <dt>its own identity</dt><dd>its GitHub App, minting <code>${esc(Object.entries(AGENT.permissions).map(([k, v]) => `${k}:${v}`).join(", "))}</code> on <code>${esc(AGENT.repo)}</code> — from <code>[identity].scopes</code>, and nothing wider is possible</dd>
  <dt>schedule</dt><dd>${AGENT.cron ? `<code>${esc(AGENT.cron)}</code> UTC` : "none — this manifest declares no <code>[trigger].cron</code>"}</dd>
  <dt>charter</dt><dd><code>${esc(AGENT.entry)}</code>, read from the repository on every run</dd>
  <dt>model</dt><dd><code>${esc(AGENT.model)}</code>${AGENT.routes.length > 1 ? `, over ${AGENT.routes.length} roads tried in order` : ""}</dd>
  <dt>runs remembered</dt><dd>${count} total, ${runs.length} kept here</dd>
</dl>
</div>

<div class="card">
<h2 style="margin-top:0;font-size:1.05rem">Trigger it</h2>
${button}
</div>

<div class="card">
<h2 style="margin-top:0;font-size:1.05rem">Last run</h2>
${last ? `<dl>
  <dt>when</dt><dd>${esc(last.startedAt)}</dd>
  <dt>woken by</dt><dd>${esc(last.trigger)}</dd>
  <dt>outcome</dt><dd style="color:${OUTCOME[last.outcome] ?? "#57606a"};font-weight:600">${esc(last.outcome)}</dd>
  <dt>road</dt><dd>${esc(last.route ?? "—")} / <code>${esc(last.model ?? "—")}</code></dd>
  <dt>turns</dt><dd>${esc(last.turns)} of ${esc(last.maxTurns)} — an edge run is one turn; it does not clone, commit or open a pull request</dd>
  <dt>took</dt><dd>${esc(last.seconds)}s</dd>
</dl>
<pre>${esc(last.detail)}</pre>` : `<p class="note">Nothing yet. This agent has never run here.</p>`}
</div>

${runs.length > 1 ? `<div class="card">
<h2 style="margin-top:0;font-size:1.05rem">Before that</h2>
<table><thead><tr><th>started</th><th>woken by</th><th>outcome</th><th>road</th><th>took</th></tr></thead>
<tbody>${runs.slice(1).map(runRow).join("\n")}</tbody></table>
</div>` : ""}

<p class="note">${esc(AGENT.name)} was deployed from one manifest (<code>${esc(AGENT.source)}</code>, spec ${esc(AGENT.spec)}) by
<code>epito deploy --target cloudflare</code>. Its identity, its schedule, its memory and this page
all came out of that file; nothing was configured here by hand.</p>
</main></body></html>
`;
}

// --- the Worker -----------------------------------------------------------

export default {
  async fetch(request, env, ctx) {
    const closed = checkDoor(request, env);
    if (closed) return closed;
    const url = new URL(request.url);
    const key = request.headers.get("x-epito-secret") ? "" : (url.searchParams.get("key") ?? "");

    if (url.pathname === "/" && request.method === "GET") {
      const state = await readState(env);
      return new Response(page({ ...state, key }), { headers: { "content-type": "text/html; charset=utf-8" } });
    }
    if (url.pathname === "/api/state" && request.method === "GET") {
      return json({ agent: AGENT, ...(await readState(env)) });
    }
    if (url.pathname === "/runs" && request.method === "POST") {
      if (!AGENT.webhook) {
        return refuse(405, `"${AGENT.name}" cannot be woken by hand: its manifest declares no [trigger].webhook, and a trigger is explicit and never defaulted (spec rule 3). Fix: add webhook = true under [trigger] and deploy again.`);
      }
      const run = await performRun(env, "manual", {});
      // A browser got here by pressing a button, and the thing it wants next
      // is the page it pressed it on, now showing the run.
      if ((request.headers.get("accept") ?? "").includes("text/html")) {
        return new Response(null, { status: 303, headers: { location: `/${key ? `?key=${encodeURIComponent(key)}` : ""}` } });
      }
      return json(run);
    }
    return refuse(404, `this agent answers three addresses: GET / (the page), POST /runs (trigger it) and GET /api/state (the same thing as JSON). ${url.pathname} is none of them.`);
  },

  // [trigger].cron, arriving as the Workers runtime's own schedule. One line,
  // because the whole of "a schedule that fires" is that wrangler.jsonc
  // carried the manifest's five fields verbatim.
  async scheduled(event, env, ctx) {
    const run = performRun(env, "cron", {});
    if (ctx?.waitUntil) ctx.waitUntil(run);
    return run;
  },
};
