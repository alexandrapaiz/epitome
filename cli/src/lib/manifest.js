// The manifest (agent.toml) parser and validator, spec v0.1.
// Factored out of index.js so `epito run` can load a directory of manifests
// with the same rules `epito validate` applies. The error strings are product
// surface (spec: "name the rule broken, in the product's own vocabulary, with
// the fix in the message") and must not drift between the two commands.
import { readFileSync, existsSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { parse } from "smol-toml";
import { ADAPTERS, DEFAULT_ADAPTER, unknownAdapter } from "./adapters.js";
import { routeErrors } from "./router.js";
import { unknownKeys } from "./fields.js";

export const NAME_RE = /^[a-z0-9-]{1,40}$/;

// The frozen field catalogue, spec v0.1. This is the list the spec's table
// section renders and the list this validator enforces, and there is exactly
// one of it so the two cannot drift — the drift is what let five fields land
// as prose without ever being checked.
export const FIELDS = {
  agent: ["name", "description"],
  identity: ["scopes"],
  trigger: ["cron", "webhook"],
  // `route` is the [[runtime.route]] array; its own keys are router.js's,
  // kept beside the code that reads them.
  runtime: ["model", "entry", "repo", "ref", "adapter", "graph", "max_turns", "env", "slack_webhook_env", "route"],
};

export const TABLES = Object.keys(FIELDS);

// Fields the v0.1 DRAFT carried that the freeze retired. A reader who copied
// one out of an older spec is owed the reason and the replacement, not
// "unknown field" — that is the difference between a spec that froze and a
// product that just started refusing things.
const RETIRED = {
  trigger: {
    on: '[trigger].on names platform events to subscribe to, and v0.1 subscribes to nothing and filters on nothing: a seat is woken by [trigger].cron (a schedule the runtime registers) or [trigger].webhook (the ingress), and a hook runs the seat whatever event it carried. A field that cannot change what happens is a field that misleads its author. Fix: drop it, and set webhook = true to be woken by events. Event subscription returns with `epito deploy` — spec v0.1, open questions.',
  },
  runtime: {
    image: '[runtime].image names a container image, and an image is a property of the box, not of the agent — the same rule that keeps the interpreter, the virtualenv and every path out of a manifest, because a manifest has to stay publishable and runnable by a second person (spec v0.1, "what is deliberately NOT in the manifest"). Nothing has ever read this field. Fix: drop the line; a run happens in the image the runtime box already has.',
  },
};

// Parse a manifest file. Returns { manifest } or { parseError }.
export function parseManifest(path) {
  try { return { manifest: parse(readFileSync(path, "utf8")) }; }
  catch (e) { return { parseError: e.message }; }
}

// Validate a parsed manifest. `baseDir` is where relative paths (entry) resolve
// from; `epito validate` uses the cwd, `epito run` uses the manifest's folder.
// When [runtime].repo is set the charter lives in that repo, so the entry path
// is checked at run time inside the clone instead of here.
export function validateManifest(m, { raw = "", baseDir = process.cwd() } = {}) {
  const errors = [];
  const triad = ["identity", "trigger", "runtime"].filter((t) => !m[t]);
  if (triad.length) {
    errors.push(`missing [${triad.join("], [")}] — an agent is identity + trigger + runtime; without ${triad.length === 3 ? "them" : triad.length === 2 ? "these" : "it"} this file describes a skill`);
  }

  // A table the spec does not define reads as a whole feature the author
  // believes in and the runtime has never heard of, so it is named first.
  for (const t of Object.keys(m)) {
    if (TABLES.includes(t)) continue;
    errors.push(`[${t}] is not a table in manifest spec v0.1 — a manifest has four: [${TABLES.join("], [")}]. Fix: drop it, or move what it carries into one of the four.`);
  }
  for (const t of TABLES) {
    if (m[t]) errors.push(...unknownKeys(m[t], FIELDS[t], `[${t}]`, RETIRED[t] ?? {}));
  }

  const a = m.agent ?? {};
  if (!a.name) errors.push("[agent].name is required");
  else if (!NAME_RE.test(a.name)) errors.push(`[agent].name "${a.name}" must be [a-z0-9-], 1-40 chars`);
  if (!a.description) errors.push("[agent].description is required (one sentence, shown on the roster)");

  if (m.identity) {
    const s = m.identity.scopes;
    if (!Array.isArray(s) || s.length === 0) errors.push("[identity].scopes must be a non-empty array");
    else for (const sc of s) {
      if (typeof sc !== "string" || !/^[a-z0-9_-]+:[a-z0-9_.-]+$/.test(sc)) {
        errors.push(`scope "${sc}" must look like platform:permission (e.g. github:contents)`);
      }
    }
  }

  if (m.trigger) {
    const t = m.trigger;
    if (!t.cron && !t.webhook) errors.push("[trigger] needs at least one of: cron (a schedule) or webhook (the ingress wakes it) — an agent is triggered, not prompted");
    if (t.cron && !/^\S+ \S+ \S+ \S+ \S+$/.test(t.cron)) errors.push(`[trigger].cron "${t.cron}" must be 5-field cron`);
    if (t.webhook !== undefined && typeof t.webhook !== "boolean") {
      errors.push(`[trigger].webhook is true or false — it says whether the ingress may wake this seat, not where: the URL is the runtime's to hand out, never the manifest's to name. Got "${t.webhook}".`);
    }
  }

  if (m.runtime) {
    const r = m.runtime;
    if (!r.model) errors.push("[runtime].model is required and explicit — an unset model is silently under-modeled");
    if (!r.entry) errors.push("[runtime].entry is required: the charter file the runtime reads");
    else if (!r.repo && !existsSync(resolve(baseDir, r.entry))) errors.push(`[runtime].entry "${r.entry}" does not exist`);
    if (r.repo !== undefined && !/^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/.test(String(r.repo))) {
      errors.push(`[runtime].repo "${r.repo}" must be owner/name — the GitHub repository the runtime clones for each run`);
    }
    if (r.ref !== undefined && (typeof r.ref !== "string" || !/^[A-Za-z0-9_./-]{1,200}$/.test(r.ref) || r.ref.startsWith("-"))) {
      errors.push(`[runtime].ref "${r.ref}" must be a branch or tag name — the ref the runtime checks out; leave it unset for the default branch`);
    }
    // Which kind of agent this is (ADR-17). Absent means "claude", which is
    // what every manifest written before adapters existed means, so nothing
    // in any roster changes by this field arriving.
    if (r.adapter !== undefined && !(typeof r.adapter === "string" && ADAPTERS[r.adapter])) {
      errors.push(unknownAdapter(r.adapter));
    }
    // A langgraph app may declare several graphs in its langgraph.json; this
    // names the one this seat runs. It means nothing to any other adapter, and
    // a field that quietly means nothing is how a manifest lies to its author.
    if (r.graph !== undefined) {
      const adapter = r.adapter ?? DEFAULT_ADAPTER;
      if (typeof r.graph !== "string" || !/^[A-Za-z0-9_.-]{1,80}$/.test(r.graph)) {
        errors.push(`[runtime].graph "${r.graph}" must be the NAME of a graph in the agent's langgraph.json (letters, digits, dot, dash, underscore)`);
      } else if (adapter !== "langgraph") {
        errors.push(`[runtime].graph names a graph, which only the langgraph adapter reads, and this manifest's adapter is "${adapter}". Fix: set [runtime].adapter = "langgraph", or drop [runtime].graph.`);
      }
    }
    if (r.max_turns !== undefined && !(Number.isInteger(r.max_turns) && r.max_turns > 0)) {
      errors.push(`[runtime].max_turns must be a positive integer, got "${r.max_turns}"`);
    }
    // The roads this seat may take, in order (ADR-19). Absent means one road,
    // [runtime].model on whatever this box authenticates the executor with,
    // which is what every manifest written before routing existed means.
    errors.push(...routeErrors(m));
    if (r.env && Array.isArray(r.env)) for (const e of r.env) {
      if (typeof e !== "string" || /[=:]/.test(e)) errors.push(`[runtime].env carries secret NAMES only, and "${e}" doesn't look like one — values never appear in the manifest`);
    }
    // Per-agent Slack routing: the name of the webhook secret this agent
    // posts to, so a product seat can speak in its own channel instead of
    // #hq. It is a NAME like every other secret reference, and the same rule
    // applies: a name the manifest does not list under [runtime].env is never
    // injected into a run, so a webhook name that isn't listed can never
    // resolve to a value.
    if (r.slack_webhook_env !== undefined) {
      const w = r.slack_webhook_env;
      if (typeof w !== "string" || !/^[A-Za-z_][A-Za-z0-9_]*$/.test(w)) {
        errors.push(`[runtime].slack_webhook_env "${w}" must be the NAME of an environment variable (letters, digits, underscore) — the webhook URL itself never appears in the manifest`);
      } else if (!(Array.isArray(r.env) && r.env.includes(w))) {
        errors.push(`[runtime].slack_webhook_env names "${w}", so "${w}" must also be listed in [runtime].env — the runtime injects only the names the manifest lists, so an unlisted webhook can never resolve to a value`);
      }
    }
  }

  // Rule 1: nothing personal in the file — cheap tripwires for pasted credentials.
  for (const pat of [/gh[pousr]_[A-Za-z0-9]{20,}/, /sk-[A-Za-z0-9_-]{20,}/, /AKIA[0-9A-Z]{16}/]) {
    if (pat.test(raw)) errors.push("agent.toml appears to contain a credential — a manifest must be publishable without redaction. Move it to a secret and list its NAME under [runtime].env");
  }

  return errors;
}

// Load + validate one manifest file. Returns { manifest, errors, raw, dir }.
export function loadManifest(path) {
  const raw = readFileSync(path, "utf8");
  const { manifest, parseError } = parseManifest(path);
  if (parseError) return { manifest: null, errors: [`agent.toml is not valid TOML: ${parseError}`], raw, dir: dirname(path) };
  return { manifest, errors: validateManifest(manifest, { raw, baseDir: dirname(resolve(path)) }), raw, dir: dirname(resolve(path)) };
}
