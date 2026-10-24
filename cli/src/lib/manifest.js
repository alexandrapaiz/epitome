// The manifest (agent.toml) parser and validator, against the spec version
// `SPEC_VERSION` names (spec/manifest.md).
// Factored out of index.js so `epito run` can load a directory of manifests
// with the same rules `epito validate` applies. The error strings are product
// surface (spec: "name the rule broken, in the product's own vocabulary, with
// the fix in the message") and must not drift between the two commands.
import { readFileSync, existsSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { parse } from "smol-toml";
import { ADAPTERS, DEFAULT_ADAPTER, unknownAdapter } from "./adapters.js";
import { routeErrors } from "./router.js";
import { parseCron } from "./cron.js";
import { unknownKeys, SPEC_VERSION } from "./fields.js";
import { subjectErrors, subjectsOverlap } from "./subjects.js";
import { SCOPE_MAP } from "./identity.js";

export const NAME_RE = /^[a-z0-9-]{1,40}$/;

// What each half of the triad needs, named in the refusal that misses it, so
// "missing [identity]" is a line a reader can act on without opening the spec.
const TRIAD_FIX = {
  identity: 'scopes = ["github:contents"]',
  trigger: 'cron = "0 6 * * *"',
  runtime: "model, entry and repo",
};

// The name the author probably meant. Offered only when it comes out legal:
// a suggestion that would itself be refused is worse than none.
export const kebab = (name) => {
  const k = String(name).toLowerCase().replace(/[^a-z0-9-]+/g, "-").replace(/^-+|-+$/g, "").slice(0, 40).replace(/-+$/, "");
  return NAME_RE.test(k) ? k : null;
};

// GitHub's classic OAuth scopes that have no colon in them, so they reach the
// shape check rather than the mint. `repo` is the single likeliest wrong answer
// in the whole manifest — it is what every GitHub integration guide has asked
// for since 2013 — and it used to be answered with a regex.
const CLASSIC = new Set([
  "repo", "public_repo", "repo_deployment", "security_events", "gist",
  "notifications", "user", "delete_repo", "workflow", "codespace",
]);

const MINTABLE = Object.keys(SCOPE_MAP).map((s) => `"${s}"`).join(", ");

// The field catalogue. This is the list the spec's table
// section renders and the list this validator enforces, and there is exactly
// one of it so the two cannot drift — the drift is what let five fields land
// as prose without ever being checked.
export const FIELDS = {
  agent: ["name", "description"],
  identity: ["scopes"],
  trigger: ["cron", "webhook", "subscriptions"],
  // `route` is the [[runtime.route]] array; its own keys are router.js's,
  // kept beside the code that reads them.
  runtime: ["model", "entry", "repo", "ref", "adapter", "graph", "max_turns", "env", "slack_webhook_env", "route"],
};

export const TABLES = Object.keys(FIELDS);

// What a key the catalogue does not define costs the manifest it is in, by
// table (spec v0.2, "An unknown key refuses two tables and warns the other
// two"). It is named in all four; it costs the ✓ in two.
//
// REFUSES: `[identity]` and `[runtime]` both have behaviour that DEFAULTS when
// a key is absent — `max_turns`, `adapter`, `ref`, `graph`, the whole of
// `[[runtime.route]]`, and a scope not asked for is a permission not minted.
// An unread key beside those changes how a seat runs with nobody told, which is
// the `max_turn = 50` harm this freeze exists to refuse.
//
// WARNS: `[agent]` and `[trigger]` separately require every field whose absence
// changes behaviour — no `name`, no `description` and a `[trigger]` carrying
// none of cron/webhook/subscriptions are each their own refusal — so an unknown
// key in them cannot leave a seat quietly misconfigured. Measured, not argued:
// on 2026-10-24 these two tables cost alexandra-systems' 41-manifest roster its
// whole run over two keys in two files, and a roster runs whole or not at all.
export const UNKNOWN_KEY_REFUSES = ["identity", "runtime"];
export const UNKNOWN_KEY_WARNS = ["agent", "trigger"];

// Every table is one or the other, checked at import rather than in a test
// someone has to remember to write: a table missing from both lists would be a
// table whose unknown keys are silently ignored again, which is the exact
// pre-freeze behaviour — a ✓ on a manifest nothing read. (src/validate.js does
// the same for roster-rule severities, for the same reason.)
for (const t of TABLES) {
  const n = (UNKNOWN_KEY_REFUSES.includes(t) ? 1 : 0) + (UNKNOWN_KEY_WARNS.includes(t) ? 1 : 0);
  if (n !== 1) {
    throw new Error(`src/lib/manifest.js: table [${t}] appears in ${n === 0 ? "neither" : "both"} of UNKNOWN_KEY_REFUSES and UNKNOWN_KEY_WARNS, so an unknown key in it would be ${n === 0 ? "silently ignored — the pre-freeze behaviour" : "both refused and warned"}. Fix: list [${t}] in exactly one.`);
  }
}

// Fields the v0.1 DRAFT carried that the freeze retired. A reader who copied
// one out of an older spec is owed the reason and the replacement, not
// "unknown field" — that is the difference between a spec that froze and a
// product that just started refusing things.
const RETIRED = {
  trigger: {
    on: `[trigger].on named platform events, and it was retired because nothing read it: a manifest whose only trigger was \`on\` validated with a ✓ and was a seat that could never fire. Event subscription came back in ${SPEC_VERSION} as [trigger].subscriptions, which names BUS subjects and which the runtime does read — it holds one durable consumer per seat filtered to exactly those subjects. Fix: subscriptions = ["asc.events.*.message.posted"], with the subjects your bus publishes on; or webhook = true if what wakes this seat is the ingress.`,
  },
  runtime: {
    image: `[runtime].image names a container image, and an image is a property of the box, not of the agent — the same rule that keeps the interpreter, the virtualenv and every path out of a manifest, because a manifest has to stay publishable and runnable by a second person (spec ${SPEC_VERSION}, "what is deliberately NOT in the manifest"). Nothing has ever read this field. Fix: drop the line; a run happens in the image the runtime box already has.`,
  },
};

// `[runtime].repo` is a repository on github.com, and GitHub has rules for
// what an owner and a name may be. The rule here used to be "two things with a
// slash", which blessed values GitHub can never name — so `epito validate`
// said ✓ and `epito run`, `epito deploy` and `epito token` then failed on the
// network, which is the one outcome src/lib/readiness.js exists to prevent:
//
//   repo = "acme/roster.git"   the runtime clones https://github.com/<repo>.git,
//                              so this asked for roster.git.git — and GitHub
//                              refuses a repository named with that suffix anyway
//   repo = "../.."             two legal halves, and `epito deploy` would have
//                              put it in an api.github.com path
//
// An owner (user or organisation) is 1–39 characters of letters, digits and
// hyphens, and cannot begin or end with a hyphen: no dots, no underscores. A
// name is up to 100 characters of letters, digits, dot, dash and underscore,
// and is not "." or "..".
export const OWNER_RE = /^[A-Za-z0-9](?:[A-Za-z0-9-]{0,37}[A-Za-z0-9])?$/;
export const REPO_NAME_RE = /^[A-Za-z0-9._-]{1,100}$/;

export function repoErrors(repo) {
  const here = `[runtime].repo "${repo}"`;
  const halves = repo.split("/");
  if (halves.length !== 2 || !halves[0] || !halves[1]) {
    return [`${here} must be owner/name — the GitHub repository the runtime clones for every run, which it does over https://github.com/owner/name.git. A URL, an scp-style git address and a path are all the same mistake: epito names the repository, and builds the rest. Fix: write the two halves only, e.g. repo = "acme/roster".`];
  }
  const [owner, name] = halves;
  if (!OWNER_RE.test(owner)) {
    return [`${here}: "${owner}" is not a GitHub owner — a user or organisation is 1–39 characters of letters, digits and hyphens, and cannot begin or end with one, so a dot, an underscore, a space or a colon rules it out. Fix: use the owner exactly as github.com spells it in the URL bar.`];
  }
  if (/\.git$/.test(name)) {
    return [`${here}: GitHub refuses a repository name ending in ".git", and the runtime appends that itself when it clones (https://github.com/${owner}/${name.replace(/\.git$/, "")}.git). Fix: drop the suffix — repo = "${owner}/${name.replace(/\.git$/, "")}".`];
  }
  if (name === "." || name === ".." || !REPO_NAME_RE.test(name)) {
    return [`${here}: "${name}" is not a GitHub repository name — up to 100 characters of letters, digits, dot, dash and underscore, and never "." or "..". Fix: use the name exactly as github.com spells it in the URL bar.`];
  }
  return [];
}

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
    errors.push(`missing [${triad.join("], [")}] — an agent is identity + trigger + runtime; without ${triad.length === 3 ? "them" : triad.length === 2 ? "these" : "it"} this file describes a skill. Fix: add ${triad.map((t) => `[${t}] (${TRIAD_FIX[t]})`).join(", ")}, or run \`epito init\` in an empty directory to see all three written out.`);
  }

  // A table the spec does not define reads as a whole feature the author
  // believes in and the runtime has never heard of, so it is named first.
  for (const t of Object.keys(m)) {
    if (TABLES.includes(t)) continue;
    errors.push(`[${t}] is not a table in manifest spec ${SPEC_VERSION} — a manifest has four: [${TABLES.join("], [")}]. Fix: drop it, or move what it carries into one of the four.`);
  }
  // Only the two tables where an unknown key can hide a default. The other two
  // are reported by `manifestWarnings` below, on the same line shape, at a
  // severity that does not cost the ✓.
  for (const t of UNKNOWN_KEY_REFUSES) {
    if (m[t]) errors.push(...unknownKeys(m[t], FIELDS[t], `[${t}]`, { retired: RETIRED[t] ?? {} }));
  }

  const a = m.agent ?? {};
  if (!a.name) errors.push('[agent].name is required — it is what the schedule, the board and every audit line call this agent. Fix: add name = "my-agent" to [agent].');
  else if (!NAME_RE.test(a.name)) errors.push(`[agent].name "${a.name}" must be lower-case letters, digits and hyphens, 1-40 characters — a name becomes a schedule id, a clone directory and a column on the board, and those three cannot disagree about case. Fix: ${kebab(a.name) ? `name = "${kebab(a.name)}"` : "pick a name of lower-case letters, digits and hyphens"}.`);
  if (!a.description) errors.push('[agent].description is required (one sentence, shown on the roster). Fix: add description = "What this agent does, in one sentence." to [agent].');

  if (m.identity) {
    const s = m.identity.scopes;
    if (!Array.isArray(s) || s.length === 0) errors.push(`[identity].scopes must be a non-empty array of platform:permission strings — scopes are the whole of an agent's identity, and an agent with none has nothing to mint. Fix: scopes = ["github:contents", "github:pull_requests"]; ${SPEC_VERSION} mints ${MINTABLE}.`);
    else for (const sc of s) {
      if (typeof sc !== "string" || !/^[a-z0-9_-]+:[a-z0-9_.-]+$/.test(sc)) {
        errors.push(`scope "${sc}" must look like platform:permission${CLASSIC.has(sc) ? ` — "${sc}" is one of GitHub's CLASSIC OAuth scopes, which are a different thing: a manifest scope maps to a fine-grained App permission, so the App epito creates holds only what the manifest asked for` : " — the platform the permission belongs to, then the permission"}. Fix: scopes = ["github:contents", "github:pull_requests"]; ${SPEC_VERSION} maps ${MINTABLE} and notes anything else as unmintable.`);
      }
    }
  }

  if (m.trigger) {
    const t = m.trigger;
    const subs = t.subscriptions;
    if (!t.cron && !t.webhook && !(Array.isArray(subs) && subs.length)) errors.push('[trigger] needs at least one of: cron (a schedule), webhook (the ingress wakes it) or subscriptions (the bus wakes it) — an agent is triggered, not prompted. Fix: cron = "0 6 * * *" for a clock, webhook = true to be woken by a push, subscriptions = ["asc.events.*.message.posted"] to be woken by an event the bus is holding, or any combination.');
    // Parsed, not counted. Counting five fields passed "0 99 * * *", which
    // `epito run` then refused when it built the matcher — so a tick here
    // promised a schedule the runtime would reject. One check, one message,
    // and loadRoster no longer carries its own copy.
    if (t.cron) {
      try { parseCron(t.cron); }
      catch (e) {
        errors.push(`[trigger].cron "${t.cron}" is not a schedule the runtime can register — ${String(e.message).replace(/^cron /, "")}. Fix: five fields in UTC (minute hour day-of-month month day-of-week) using numbers, *, ranges, steps and lists; "0 6 * * *" is 06:00 every day.`);
      }
    }
    if (t.webhook !== undefined && typeof t.webhook !== "boolean") {
      errors.push(`[trigger].webhook is true or false — it says whether the ingress may wake this seat, not where: the URL is the runtime's to hand out, never the manifest's to name. Got "${t.webhook}". Fix: webhook = true, with no quotes, or drop the line.`);
    }
    // The bus subjects this seat is woken by. Checked HERE rather than left to
    // the server, for the reason `[trigger].cron` is parsed here: the runtime
    // creates the consumer at startup, on a box, and a subject the server
    // refuses is a seat that stops being woken at whatever hour that restart
    // happened — while the person who can fix it is reading this message now.
    if (subs !== undefined) {
      if (!Array.isArray(subs)) {
        errors.push(`[trigger].subscriptions is a list of bus subjects, got ${typeof subs === "object" ? "a table" : `"${subs}"`} — one durable consumer is created per seat, filtered to exactly these. Fix: subscriptions = ["asc.events.*.message.posted"], even for a single subject.`);
      } else if (!subs.length) {
        errors.push(`[trigger].subscriptions is an empty list, which says this seat is woken by the bus and names nothing for it to be woken by — a trigger is explicit and never defaulted (spec ${SPEC_VERSION} rule 3). Fix: name the subjects, e.g. subscriptions = ["asc.events.*.message.posted"], or drop the line and let [trigger].cron or webhook be this seat's trigger.`);
      } else {
        subs.forEach((subject, i) => errors.push(...subjectErrors(subject, `[trigger].subscriptions[${i}]`)));
        // Two filters that overlap are refused by the server when the consumer
        // is created, which would be a startup failure for a manifest that
        // reads fine. Said here, as the pair it is.
        const ok = subs.filter((x) => typeof x === "string" && !subjectErrors(x, "").length);
        for (let i = 0; i < ok.length; i++) {
          for (let j = i + 1; j < ok.length; j++) {
            if (!subjectsOverlap(ok[i], ok[j])) continue;
            const wider = ok[i].split(".").length <= ok[j].split(".").length && /[*>]/.test(ok[i]) ? ok[i] : ok[j];
            const narrower = wider === ok[i] ? ok[j] : ok[i];
            errors.push(`[trigger].subscriptions lists "${ok[i]}" and "${ok[j]}", and they overlap — one consumer cannot hold two filters that can both match the same event, so the bus would refuse this seat's consumer at startup. ${wider === narrower ? "Fix: drop one of the two." : `Fix: keep "${wider}", which already covers "${narrower}", and drop the other.`}`);
          }
        }
      }
    }
  }

  if (m.runtime) {
    const r = m.runtime;
    if (!r.model) errors.push(`[runtime].model is required and explicit — an unset model is silently under-modeled, and nothing in epito guesses one for you. Fix: model = "claude-sonnet-5", or name the model this agent needs.`);
    if (!r.entry) errors.push(`[runtime].entry is required: the charter file the runtime reads, a path inside the repository it clones. Fix: entry = "prompts/${a.name ?? "my-agent"}.md", and commit that file.`);
    else if (!r.repo && !existsSync(resolve(baseDir, r.entry))) errors.push(`[runtime].entry "${r.entry}" does not exist, and with no [runtime].repo there is no repository for it to live in either — the runtime reads the charter inside the clone, and refuses rather than improvise one. Fix: create ${r.entry} here, or set repo = "owner/name" and commit the charter there.`);
    if (r.repo !== undefined) errors.push(...repoErrors(String(r.repo)));
    if (r.ref !== undefined && (typeof r.ref !== "string" || !/^[A-Za-z0-9_./-]{1,200}$/.test(r.ref) || r.ref.startsWith("-"))) {
      errors.push(`[runtime].ref "${r.ref}" must be a branch or tag name — the ref the runtime checks out. Fix: ref = "main", or drop the line to take the repository's default branch.`);
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
        errors.push(`[runtime].graph "${r.graph}" must be the NAME of a graph in the agent's langgraph.json (letters, digits, dot, dash, underscore). Fix: name one key from that file's "graphs" table, e.g. graph = "agent".`);
      } else if (adapter !== "langgraph") {
        errors.push(`[runtime].graph names a graph, which only the langgraph adapter reads, and this manifest's adapter is "${adapter}". Fix: set [runtime].adapter = "langgraph", or drop [runtime].graph.`);
      }
    }
    if (r.max_turns !== undefined && !(Number.isInteger(r.max_turns) && r.max_turns > 0)) {
      errors.push(`[runtime].max_turns must be a positive integer, got "${r.max_turns}" — the ceiling on one run's turns, which is what keeps a loop from running until the bill notices. Fix: ${typeof r.max_turns === "number" ? "max_turns = 40; a run needs at least one turn" : "max_turns = 40, a number with no quotes"}.`);
    }
    // The roads this seat may take, in order (ADR-19). Absent means one road,
    // [runtime].model on whatever this box authenticates the executor with,
    // which is what every manifest written before routing existed means.
    errors.push(...routeErrors(m));
    if (r.env && Array.isArray(r.env)) for (const e of r.env) {
      if (typeof e !== "string" || /[=:]/.test(e)) errors.push(`[runtime].env carries secret NAMES only, and "${e}" doesn't look like one — values never appear in the manifest, which is what keeps it publishable. Fix: env = ["${String(e).split(/[=:]/)[0] || "GH_TOKEN"}"], and set that name as a secret on the box the runtime runs on.`);
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
        errors.push(`[runtime].slack_webhook_env "${w}" must be the NAME of an environment variable (letters, digits, underscore) — the webhook URL itself never appears in the manifest. Fix: slack_webhook_env = "PM_SLACK_WEBHOOK", list that same name under [runtime].env, and set its value as a secret.`);
      } else if (!(Array.isArray(r.env) && r.env.includes(w))) {
        errors.push(`[runtime].slack_webhook_env names "${w}", so "${w}" must also be listed in [runtime].env — the runtime injects only the names the manifest lists, so an unlisted webhook can never resolve to a value. Fix: add "${w}" to [runtime].env.`);
      }
    }
  }

  // Rule 1: nothing personal in the file — cheap tripwires for pasted credentials.
  for (const pat of [/gh[pousr]_[A-Za-z0-9]{20,}/, /sk-[A-Za-z0-9_-]{20,}/, /AKIA[0-9A-Z]{16}/]) {
    if (pat.test(raw)) errors.push("agent.toml appears to contain a credential — a manifest must be publishable without redaction. Move it to a secret and list its NAME under [runtime].env");
  }

  return errors;
}

// Everything a reader is owed about this manifest that does not cost it its ✓.
// Separate from `validateManifest` rather than a second return value, because
// `errors.length` is the verdict in a dozen places and a warning must not be
// able to reach any of them by accident — a caller that never asks for these
// still exits 0 on the same manifests it always did. What it may NOT do is
// leave them unsaid: every surface that prints a manifest's verdict prints
// these too (`epito validate`, and `loadRoster` for `epito run`/`ps`/`routes`).
export function manifestWarnings(m) {
  if (typeof m !== "object" || m === null) return [];
  const warnings = [];
  for (const t of UNKNOWN_KEY_WARNS) {
    if (m[t]) warnings.push(...unknownKeys(m[t], FIELDS[t], `[${t}]`, { retired: RETIRED[t] ?? {}, fatal: false }));
  }
  return warnings;
}

// Load + validate one manifest file. Returns { manifest, errors, warnings, raw, dir }.
export function loadManifest(path) {
  const raw = readFileSync(path, "utf8");
  const { manifest, parseError } = parseManifest(path);
  if (parseError) return { manifest: null, errors: [`agent.toml is not valid TOML: ${parseError}`], warnings: [], raw, dir: dirname(path) };
  return { manifest, errors: validateManifest(manifest, { raw, baseDir: dirname(resolve(path)) }), warnings: manifestWarnings(manifest), raw, dir: dirname(resolve(path)) };
}
