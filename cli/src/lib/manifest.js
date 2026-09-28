// The manifest (agent.toml) parser and validator, spec v0.1.
// Factored out of index.js so `epito run` can load a directory of manifests
// with the same rules `epito validate` applies. The error strings are product
// surface (spec: "name the rule broken, in the product's own vocabulary, with
// the fix in the message") and must not drift between the two commands.
import { readFileSync, existsSync, readdirSync, statSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { parse } from "smol-toml";
import { mapScopes } from "./scopes.js";

export const NAME_RE = /^[a-z0-9-]{1,40}$/;

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

  const a = m.agent ?? {};
  if (!a.name) errors.push("[agent].name is required");
  else if (!NAME_RE.test(a.name)) errors.push(`[agent].name "${a.name}" must be [a-z0-9-], 1-40 chars`);
  if (!a.description) errors.push("[agent].description is required (one sentence, shown on the roster)");

  if (m.identity) {
    const s = m.identity.scopes;
    if (!Array.isArray(s) || s.length === 0) errors.push("[identity].scopes must be a non-empty array");
    else {
      const malformed = [];
      for (const sc of s) {
        if (typeof sc !== "string" || !/^[a-z0-9_-]+:[a-z0-9_.-]+$/.test(sc)) {
          malformed.push(sc);
          errors.push(`scope "${sc}" must look like platform:permission (e.g. github:contents)`);
        }
      }
      // A well-formed scope with no permission behind it is worse than a typo:
      // it reads as granted and mints nothing. Same table `epito token` uses,
      // so validate and the mint can never disagree about the ceiling.
      errors.push(...mapScopes(s.filter((sc) => !malformed.includes(sc))).errors);
    }
  }

  if (m.trigger) {
    const t = m.trigger;
    if (!t.cron && !t.on && !t.webhook) errors.push("[trigger] needs at least one of: cron, on, webhook — an agent is triggered, not prompted");
    if (t.cron && !/^\S+ \S+ \S+ \S+ \S+$/.test(t.cron)) errors.push(`[trigger].cron "${t.cron}" must be 5-field cron`);
    if (t.on && (!Array.isArray(t.on) || t.on.length === 0)) errors.push("[trigger].on must be a non-empty array of events");
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
    if (r.max_turns !== undefined && !(Number.isInteger(r.max_turns) && r.max_turns > 0)) {
      errors.push(`[runtime].max_turns must be a positive integer, got "${r.max_turns}"`);
    }
    if (r.env && Array.isArray(r.env)) for (const e of r.env) {
      if (typeof e !== "string" || /[=:]/.test(e)) errors.push(`[runtime].env carries secret NAMES only, and "${e}" doesn't look like one — values never appear in the manifest`);
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

// Every agent.toml under a directory, four levels deep. `epito run` hosts them
// all; `epito token` looks up one by name in the same tree, so a roster reads
// the same way to both commands.
const SKIP = new Set(["node_modules", ".git", ".epito"]);

export function findManifests(dir, depth = 0, out = []) {
  for (const ent of readdirSync(dir)) {
    if (SKIP.has(ent)) continue;
    const p = join(dir, ent);
    const st = statSync(p);
    if (st.isDirectory() && depth < 4) findManifests(p, depth + 1, out);
    else if (ent === "agent.toml") out.push(p);
  }
  return out;
}
