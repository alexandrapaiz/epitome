#!/usr/bin/env node
import { readFileSync, writeFileSync, existsSync, mkdirSync } from "node:fs";
import { parseManifest, validateManifest, NAME_RE } from "./lib/manifest.js";

const [, , cmdRaw, ...args] = process.argv;
// `epito me` is `epito init`: mint an epitome of yourself.
const cmd = cmdRaw === "me" ? "init" : cmdRaw;

const HELP = `epito — mint agents: identity + trigger + runtime from one file

  epito init [name]   scaffold agent.toml and a charter (alias: epito me)
  epito validate      check agent.toml against spec v0.1
  epito run <dir>     put every agent.toml under <dir> on the runtime: one
                      schedule per [trigger].cron, then serve the ingress
                      (--dry-run prints the schedule changes and stops)
  epito worker        do the work: poll the \`seats\` task queue and run seats
  epito ps [dir]      the roster, read from the runtime
  epito board         what the seats have been doing: run reports, newest
                      last (--agent, --kind, --limit, --json)
  epito report <name> file a run report on the board from anywhere
                      (--trigger --outcome --pr --turns --seconds --detail)
  epito note <name> "..."
                      put a line on the board that is not a run
  epito window open|close [scope] [text]
                      open (default 4h) or close work windows
  epito message <name> "..."
                      speak to an agent in the session its window holds
  epito token <name> [dir]
                      mint this agent's own short-lived GitHub token on
                      stdout (--dry-run says what it would ask for, and
                      touches neither the network nor a key)
  epito deploy        provision the agent (not yet: platform in progress)

The runtime is two processes and one engine: \`epito run\` reconciles and
serves the ingress, \`epito worker\` executes, and Temporal (self-hosted,
TEMPORAL_ADDRESS, default 127.0.0.1:7233) is what makes a run survive a
reboot. See docs/prfaq/epitod-v1-temporal.md.

The board is where the runs show up: every seat epitod runs files its own
report, and a seat that runs somewhere else files one with \`epito report\`.
See docs/prfaq/task-board-v0.md and ADR-16.
`;

const die = (msg) => { console.error(`epito: ${msg}`); process.exit(1); };

// Add one line to .gitignore if it is not already covered. Never rewrites what
// is there: an existing .gitignore belongs to the repo, not to us.
const ignore = (line) => {
  const existing = existsSync(".gitignore") ? readFileSync(".gitignore", "utf8") : "";
  if (existing.split("\n").some((l) => l.trim() === line || l.trim() === line.replace(/\/$/, ""))) return;
  const sep = existing === "" || existing.endsWith("\n") ? "" : "\n";
  writeFileSync(".gitignore", `${existing}${sep}${existing ? "" : "# epito: the agent's credentials and run state, never committed\n"}${line}\n`);
};

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
  // An agent's App key lands in .epito/keys/ and its ledger in
  // .epito/audit.jsonl. The manifest is publishable by design and that
  // directory is not, so init makes the difference structural rather than a
  // thing the reader has to remember (spec rule 1).
  ignore(".epito/");
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
  const dir = args.find((a) => !a.startsWith("-"));
  if (!dir) die("run needs a directory: `epito run <dir>` puts every agent.toml under <dir> on the runtime");
  const { runDaemon } = await import("./run.js");
  // The engine being unreachable is an operating condition, not a crash: it
  // gets the same one-line treatment as a broken manifest, never a stack.
  try { await runDaemon(dir, { dryRun: args.includes("--dry-run") }); } catch (e) { die(e.message); }
} else if (cmd === "worker") {
  const { runWorker } = await import("./temporal/worker.js");
  try { await runWorker(); } catch (e) { die(e.message); }
  process.exit(0);
} else if (cmd === "ps") {
  const { psCmd } = await import("./temporal/ps.js");
  try { await psCmd(args[0]); } catch (e) { die(e.message); }
  process.exit(0);
} else if (cmd === "window") {
  const { windowCmd } = await import("./run.js");
  await windowCmd(args[0], args[1], args[2]);
  process.exit(0);
} else if (cmd === "token") {
  const { tokenCmd } = await import("./token.js");
  const rest = args.filter((a) => !a.startsWith("-"));
  await tokenCmd(rest[0], rest[1] ?? ".", { dryRun: args.includes("--dry-run") });
  process.exit(0);
} else if (cmd === "board") {
  const { boardCmd } = await import("./board.js");
  await boardCmd(args);
  process.exit(0);
} else if (cmd === "report") {
  const { reportCmd } = await import("./board.js");
  await reportCmd(args);
  process.exit(0);
} else if (cmd === "note") {
  const { noteCmd } = await import("./board.js");
  await noteCmd(args);
  process.exit(0);
} else if (cmd === "message") {
  const { message } = await import("./run.js");
  await message(args[0], args.slice(1).join(" "));
  process.exit(0);
}

if (cmd === "deploy") {
  die("deploy is what the platform does, and the platform is in progress — track spec/manifest.md and docs/backlog.md");
}

die(`unknown command "${cmdRaw}" — try \`epito help\``);
