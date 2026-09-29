#!/usr/bin/env node
import { readFileSync, writeFileSync, existsSync, mkdirSync } from "node:fs";
import { parseManifest, validateManifest, NAME_RE } from "./lib/manifest.js";

const [, , cmdRaw, ...args] = process.argv;
// `epito me` is `epito init`: mint an epitome of yourself.
const cmd = cmdRaw === "me" ? "init" : cmdRaw;

const HELP = `epito — mint agents: identity + trigger + runtime from one file

  epito init [name]   scaffold agent.toml and a charter (alias: epito me)
  epito validate      check agent.toml against spec v0.1
  epito run <dir>     resident runtime: host every agent.toml under <dir>
  epito ps            roster of the running daemon (reads .epito/state.json)
  epito window open|close [scope] [text]
                      open (default 4h) or close work windows on the daemon
  epito message <name> "..."
                      speak to an agent in the session its window holds
  epito token <name> [dir]
                      mint that agent's own short-lived GitHub token
  epito deploy        provision the agent (not yet: platform in progress)
`;

const die = (msg) => { console.error(`epito: ${msg}`); process.exit(1); };

if (!cmd || cmd === "help" || cmd === "--help") {
  console.log(HELP);
  process.exit(0);
}

if (cmd === "init") {
  const name = (args[0] ?? "my-agent").toLowerCase();
  if (!NAME_RE.test(name)) die(`name must be [a-z0-9-], 1-40 chars, got "${name}"`);
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
  const { manifest: m, parseError } = parseManifest("agent.toml");
  if (parseError) die(`agent.toml is not valid TOML: ${parseError}`);
  const a = m.agent ?? {};
  const errors = validateManifest(m, { raw: readFileSync("agent.toml", "utf8") });

  if (errors.length) {
    console.error(`agent.toml: ${errors.length} problem${errors.length > 1 ? "s" : ""}\n`);
    for (const e of errors) console.error(`  ✗ ${e}`);
    process.exit(1);
  }
  console.log(`✓ ${a.name} is an agent: identity (${m.identity.scopes.length} scope${m.identity.scopes.length > 1 ? "s" : ""}), trigger, runtime`);
  process.exit(0);
}

if (cmd === "run") {
  const dir = args[0];
  if (!dir) die("run needs a directory: `epito run <dir>` hosts every agent.toml under <dir>");
  const { runDaemon } = await import("./run.js");
  await runDaemon(dir);
} else if (cmd === "ps") {
  const { ps } = await import("./run.js");
  ps();
  process.exit(0);
} else if (cmd === "window") {
  const { windowCmd } = await import("./run.js");
  await windowCmd(args[0], args[1], args[2]);
  process.exit(0);
} else if (cmd === "message") {
  const { message } = await import("./run.js");
  await message(args[0], args.slice(1).join(" "));
  process.exit(0);
} else if (cmd === "token") {
  const { tokenCmd } = await import("./token.js");
  await tokenCmd(args);
  process.exit(0);
}

if (cmd === "deploy") {
  die("deploy is what the platform does, and the platform is in progress — track spec/manifest.md and docs/backlog.md");
}

die(`unknown command "${cmdRaw}" — try \`epito help\``);
