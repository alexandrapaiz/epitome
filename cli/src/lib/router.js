// Where a run's model comes from, and what happens when that road is closed
// (ADR-19). A seat declares an ORDERED list of routes; the runtime tries them
// in order, and the first one that gets the agent started is the one the run
// used.
//
// This exists because the company already built it five times by hand. HQ's
// seat workflows carry an open-routed step with `continue-on-error: true` and
// a Claude step behind it that runs when the first did not succeed — the same
// eleven lines of YAML in fifteen workflows across five repositories (lesson
// L-E7: open routing is best-effort; the subscription is the floor). A detour
// hand-wired into every driver is a detour that is wrong in one driver. The
// runtime is the one place it can be built once.
//
// Three rules, and everything here is one of them:
//
//   1. A route is a model plus, optionally, where to send it and the NAME of
//      the credential that opens it. Values never appear in a manifest
//      (spec rule 1), so `token_env` is a name and must also be listed in
//      [runtime].env — the same contract [runtime].slack_webhook_env has.
//
//   2. A route whose credential is not on this box is SKIPPED, not failed.
//      Open routing is opt-in per box: the same manifest runs on a machine
//      that has a Moonshot key and on one that does not, and only the second
//      goes straight to the floor. What it may never do is go there silently,
//      so every skip is a line in the run log and on the board's trace.
//
//   3. Falling back is only allowed while the agent has provably done
//      NOTHING. `execute` is never retried in this runtime because a run that
//      half-happened has already pushed commits; the same reasoning bounds
//      the router. A provider that refused at turn one did not run the agent,
//      and trying the next road costs nothing. A run that reached turn nine
//      and failed is the agent's own outcome and the router must keep its
//      hands off it.
import { unknownKeys } from "./fields.js";
// The same shape [agent].name has: a route name is read by a human in a run
// log. Spelled here rather than imported from manifest.js, which imports this
// file — one small regexp is cheaper than a cycle between the two.
const ROUTE_NAME_RE = /^[a-z0-9-]{1,40}$/;

// A route's whole vocabulary, frozen with the rest of v0.1. Kept here, beside
// the reader above, for the reason this file already gives: a field accepted
// by the validator and misread by the reader is the bug the pairing prevents.
export const ROUTE_FIELDS = ["name", "model", "base_url", "token_env", "concurrency"];

// The label a manifest with no [[runtime.route]] gets: one route, the model
// the manifest already named, no credential of its own. Every manifest
// written before routing existed means exactly this, so nothing in any roster
// changes by this field arriving.
export const DEFAULT_ROUTE = "default";

// --- reading the manifest -------------------------------------------------

// The routes a manifest declares, normalized, in order. Pure: `epito validate`,
// `epito routes` and a run all read the chain through this function so they
// can never disagree about what a manifest asked for.
export function routesFor(manifest) {
  const rt = manifest?.runtime ?? {};
  const declared = Array.isArray(rt.route) ? rt.route : [];
  if (declared.length === 0) {
    return [{ name: DEFAULT_ROUTE, model: rt.model, baseUrl: null, tokenEnv: null, concurrency: null }];
  }
  return declared.map((r, i) => ({
    name: typeof r?.name === "string" && r.name ? r.name : `route-${i + 1}`,
    model: r?.model ?? rt.model,
    baseUrl: typeof r?.base_url === "string" ? r.base_url : null,
    tokenEnv: typeof r?.token_env === "string" ? r.token_env : null,
    concurrency: Number.isInteger(r?.concurrency) ? r.concurrency : null,
  }));
}

// The validator's half, kept here beside the reader so a field can never be
// accepted by one and misread by the other. Returns sentences, in the
// product's voice, naming the rule and the fix.
export function routeErrors(m) {
  const rt = m?.runtime ?? {};
  if (rt.route === undefined) return [];
  const errors = [];
  if (!Array.isArray(rt.route) || rt.route.length === 0) {
    return ['[[runtime.route]] must be one or more route tables, in the order the runtime should try them. Fix: write `[[runtime.route]]` (double brackets, once per road) with a model under each, or drop the field to run on [runtime].model alone.'];
  }
  const seen = new Set();
  rt.route.forEach((r, i) => {
    const where = `[[runtime.route]] #${i + 1}`;
    if (typeof r !== "object" || r === null || Array.isArray(r)) {
      errors.push(`${where} must be a table of fields (model, name, base_url, token_env, concurrency), not a bare value — a road is the model AND the way to reach it. Fix: write \`[[runtime.route]]\` and put model = "..." on the line under it.`);
      return;
    }
    if (r.name !== undefined) {
      if (typeof r.name !== "string" || !ROUTE_NAME_RE.test(r.name)) {
        errors.push(`${where}: name "${r.name}" must be lower-case letters, digits and hyphens, 1-40 characters — it is what the run log, the board and the audit line call this road. Fix: name = "kimi", or drop the line and let the route be known by its model.`);
      } else if (seen.has(r.name)) {
        errors.push(`${where}: two routes are both named "${r.name}", so a run could not say which one it took. Fix: name them apart.`);
      } else seen.add(r.name);
    }
    const model = r.model ?? rt.model;
    if (!model || typeof model !== "string") {
      errors.push(`${where}: model is required — a route is a model and the way to reach it, and an unset model is silently under-modeled. Fix: give this route its own model = "...", or set [runtime].model as the one every route without one falls back to.`);
    }
    if (r.base_url !== undefined) {
      const u = (() => { try { return new URL(String(r.base_url)); } catch { return null; } })();
      if (!u || !/^https?:$/.test(u.protocol)) {
        errors.push(`${where}: base_url "${r.base_url}" must be an http(s) URL — the endpoint that speaks the model's API. Fix: write it scheme and all, e.g. base_url = "https://api.moonshot.ai/anthropic"; drop the line to use the model's own provider.`);
      } else if (u.username || u.password) {
        errors.push(`${where}: base_url carries a credential in the URL, and a manifest must be publishable without redaction. Fix: put the key in a secret and name it with token_env.`);
      }
    }
    if (r.token_env !== undefined) {
      if (typeof r.token_env !== "string" || !/^[A-Za-z_][A-Za-z0-9_]*$/.test(r.token_env)) {
        errors.push(`${where}: token_env "${r.token_env}" must be the NAME of an environment variable (letters, digits, underscore) — the key itself never appears in the manifest. Fix: token_env = "KIMI_API_KEY", list that same name under [runtime].env, and set its value as a secret.`);
      } else if (!(Array.isArray(rt.env) && rt.env.includes(r.token_env))) {
        errors.push(`${where}: token_env names "${r.token_env}", so "${r.token_env}" must also be listed in [runtime].env — the runtime injects only the names the manifest lists, so an unlisted key can never resolve to a value. Fix: add "${r.token_env}" to [runtime].env.`);
      }
    }
    if (r.concurrency !== undefined && !(Number.isInteger(r.concurrency) && r.concurrency > 0)) {
      errors.push(`${where}: concurrency must be a positive integer, got "${r.concurrency}" — how many of this box's runs may be on this road at once (a prepaid tier that allows one is why this field exists). Fix: concurrency = 1, or drop the line for no limit of epito's.`);
    }
    errors.push(...unknownKeys(r, ROUTE_FIELDS, where));
  });
  return errors;
}

// --- which routes are open on THIS box ------------------------------------

// Rule 2. A route needs its credential present and non-empty; one that isn't
// is skipped with the reason in words, because "it silently went to the
// expensive road" and "it silently went to the cheap road" are the same bug.
export function liveRoutes(routes, env = process.env) {
  const live = [], skipped = [];
  for (const r of routes) {
    if (r.tokenEnv && !(env[r.tokenEnv] ?? "").trim()) {
      skipped.push({ route: r, reason: `${r.tokenEnv} is not set on this machine` });
      continue;
    }
    live.push(r);
  }
  return { live, skipped };
}

// The sentence a run refuses with when routing left it nowhere to go. Names
// every road and why it was closed, because the fix is always one of them.
export function noRouteMessage(name, skipped) {
  const reasons = skipped.map((s) => `"${s.route.name}" (${s.reason})`).join(", ");
  return `${name}: every route this seat declares is closed on this machine — ${reasons}. Fix: set one of those keys on the box, or give the seat a final route that needs none (the subscription is the floor).`;
}

// --- what a route changes about the child ---------------------------------

// The environment that points an Anthropic-API-speaking executor at this
// route. The VALUE is read here, at the last possible moment, out of the
// worker's own environment — it never crosses an activity boundary and is
// never written down (law 7). An unrouted route returns nothing at all, so a
// seat with no [[runtime.route]] spawns exactly the child it always did.
export function anthropicRouteEnv(route, env = process.env) {
  const out = {};
  if (route?.baseUrl) out.ANTHROPIC_BASE_URL = route.baseUrl;
  if (route?.tokenEnv && env[route.tokenEnv]) out.ANTHROPIC_AUTH_TOKEN = env[route.tokenEnv];
  return out;
}

// The facts about the route an agent that is not a Claude session may want.
// No credential here: `token_env` is listed in [runtime].env by rule 1, so a
// foreign agent already receives that key under the name its own code reads.
export function routeFacts(route) {
  return {
    EPITO_ROUTE: route.name,
    EPITO_MODEL: route.model,
    ...(route.baseUrl ? { EPITO_BASE_URL: route.baseUrl } : {}),
  };
}

// --- was that the road's fault, or the agent's? ---------------------------

// Rule 3, and the only judgement call in this file. `exit` is the child's
// code, or one of the stage names executeAgent uses ("timeout", "spawn",
// "cancelled", "workdir-gone").
//
//   "ok"     the run happened, stop here
//   "route"  nothing happened, and the next road is worth trying
//   "agent"  something happened — the outcome belongs to the run, not the road
//
// The fingerprint is L-E7's, written down: a run that ends in error at about
// one turn, on an open model, is the provider's concurrency ceiling until
// proven otherwise. What makes it safe to act on is not the fingerprint but
// the second half — no PR, no turns — because a run that did nothing can be
// started again anywhere, and one that did something can never be.
export function classifyAttempt({ exit, turns = null, pr = null }) {
  if (exit === 0) return "ok";
  if (pr) return "agent";                       // it opened something; the run exists now
  if (turns !== null && turns > 1) return "agent";
  // Stages that say the box or the operator intervened. Another provider
  // cannot help with any of them, and pretending otherwise burns the
  // appetite of a run that was already over.
  if (["timeout", "cancelled", "workdir-gone", "spawn"].includes(exit)) return "agent";
  return "route";
}

// --- the single-lane road -------------------------------------------------
//
// A prepaid tier that allows one concurrent request is a single-lane road:
// two seats that take it at the same moment both die at turn one, and the
// fallback then costs two runs instead of none. HQ could not serialize across
// five repositories because five workflows share nothing. A box running a
// roster shares this process, so here it is one map.
//
// The honest limit, written where the code is: this serializes one worker. A
// second worker host is a second lane counter, and the idea for fixing that
// properly (a lease in the engine) is in docs/ideas.md rather than pretended
// at here.
const lanes = new Map();

export function laneState() { return lanes; }   // tests read it; nothing else should

export async function withLane(route, fn) {
  const width = route?.concurrency ?? null;
  if (!width) return fn();
  const key = route.name;
  let lane = lanes.get(key);
  if (!lane) { lane = { width, active: 0, waiting: [] }; lanes.set(key, lane); }
  lane.width = width;
  if (lane.active >= lane.width) await new Promise((res) => lane.waiting.push(res));
  lane.active += 1;
  try { return await fn(); }
  finally {
    lane.active -= 1;
    const next = lane.waiting.shift();
    if (next) next();
  }
}
