#!/usr/bin/env node
import { readFileSync, writeFileSync, existsSync, mkdirSync } from "node:fs";
import { parse } from "smol-toml";

const [, , cmdRaw, ...args] = process.argv;
// `epito me` is `epito init`: mint an epitome of yourself.
const cmd = cmdRaw === "me" ? "init" : cmdRaw;

const HELP = `epito — mint agents: identity + trigger + runtime from one file

  epito init [name]   scaffold agent.toml and a charter (alias: epito me)
  epito validate      check agent.toml against spec v0.1
  epito deploy        provision the agent (not yet: platform in progress)
`;

const die = (msg) => { console.error(`epito: ${msg}`); process.exit(1); };

if (!cmd || cmd === "help" || cmd === "--help") {
  console.log(HELP);
  process.exit(0);
}

if (cmd === "init") {
  const name = (args[0] ?? "my-agent").toLowerCase();
  if (!/^[a-z0-9-]{1,40}$/.test(name)) die(`name must be [a-z0-9-], 1-40 chars, got "${name}"`);
  if (existsSync("agent.toml")) die("agent.toml already exists here — one manifest, one agent");
  const charter = `prompts/${name}.md`;
  writeFileSync("agent.toml", `[agent]
name = "${name}"
description = "One sentence: what this agent does."

[identity]
scopes = ["github:contents", "github:pull_requests"]

[trigger]
cron = "0 6 * * *"

[runtime]
model = "claude-sonnet-5"
entry = "${charter}"
`);
  mkdirSync("prompts", { recursive: true });
  if (!existsSync(charter)) {
    writeFileSync(charter, `# ${name}\n\nYou are ${name}. This file is your charter: who you are, what one\nrun accomplishes, and what you never do. Everything worth remembering\nlives in a file, because every run is a fresh context.\n`);
  }
  console.log(`minted ${name}: agent.toml + ${charter}`);
  console.log(`next: edit both, then \`epito validate\``);
  process.exit(0);
}

if (cmd === "validate") {
  if (!existsSync("agent.toml")) die("no agent.toml here — run `epito init` first");
  let m;
  try { m = parse(readFileSync("agent.toml", "utf8")); }
  catch (e) { die(`agent.toml is not valid TOML: ${e.message}`); }

  const errors = [];
  const triad = ["identity", "trigger", "runtime"].filter((t) => !m[t]);
  if (triad.length) {
    errors.push(`missing [${triad.join("], [")}] — an agent is identity + trigger + runtime; without ${triad.length === 3 ? "them" : triad.length === 2 ? "these" : "it"} this file describes a skill`);
  }

  const a = m.agent ?? {};
  if (!a.name) errors.push("[agent].name is required");
  else if (!/^[a-z0-9-]{1,40}$/.test(a.name)) errors.push(`[agent].name "${a.name}" must be [a-z0-9-], 1-40 chars`);
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
    if (!t.cron && !t.on && !t.webhook) errors.push("[trigger] needs at least one of: cron, on, webhook — an agent is triggered, not prompted");
    if (t.cron && !/^\S+ \S+ \S+ \S+ \S+$/.test(t.cron)) errors.push(`[trigger].cron "${t.cron}" must be 5-field cron`);
    if (t.on && (!Array.isArray(t.on) || t.on.length === 0)) errors.push("[trigger].on must be a non-empty array of events");
  }

  if (m.runtime) {
    const r = m.runtime;
    if (!r.model) errors.push("[runtime].model is required and explicit — an unset model is silently under-modeled");
    if (!r.entry) errors.push("[runtime].entry is required: the charter file the runtime reads");
    else if (!existsSync(r.entry)) errors.push(`[runtime].entry "${r.entry}" does not exist`);
    if (r.env && Array.isArray(r.env)) for (const e of r.env) {
      if (typeof e !== "string" || /[=:]/.test(e)) errors.push(`[runtime].env carries secret NAMES only, and "${e}" doesn't look like one — values never appear in the manifest`);
    }
  }

  // Rule 1: nothing personal in the file — cheap tripwires for pasted credentials.
  const raw = readFileSync("agent.toml", "utf8");
  for (const pat of [/gh[pousr]_[A-Za-z0-9]{20,}/, /sk-[A-Za-z0-9_-]{20,}/, /AKIA[0-9A-Z]{16}/]) {
    if (pat.test(raw)) errors.push("agent.toml appears to contain a credential — a manifest must be publishable without redaction. Move it to a secret and list its NAME under [runtime].env");
  }

  if (errors.length) {
    console.error(`agent.toml: ${errors.length} problem${errors.length > 1 ? "s" : ""}\n`);
    for (const e of errors) console.error(`  ✗ ${e}`);
    process.exit(1);
  }
  console.log(`✓ ${a.name} is an agent: identity (${m.identity.scopes.length} scope${m.identity.scopes.length > 1 ? "s" : ""}), trigger, runtime`);
  process.exit(0);
}

if (cmd === "deploy") {
  die("deploy is what the platform does, and the platform is in progress — track spec/manifest.md and docs/backlog.md");
}

die(`unknown command "${cmdRaw}" — try \`epito help\``);
