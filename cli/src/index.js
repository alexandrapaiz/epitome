#!/usr/bin/env node
import { readFileSync, writeFileSync, existsSync, mkdirSync } from "node:fs";
import { parseManifest, validateManifest, NAME_RE } from "./lib/manifest.js";
import { ignore } from "./lib/gitignore.js";
import { engineImport } from "./lib/engine.js";
import { blockers, unchecked } from "./lib/readiness.js";
import { originRepo } from "./lib/origin.js";

const [, , cmdRaw, ...args] = process.argv;
// `epito me` is `epito init`: mint an epitome of yourself.
const cmd = cmdRaw === "me" ? "init" : cmdRaw;

const HELP = `epito — mint agents: identity + trigger + runtime from one file

  epito init [name]   scaffold agent.toml and a charter (alias: epito me)
  epito validate      check agent.toml against spec v0.1, and name what the
                      runtime will still need before it can run this agent
                      (--for-runtime makes that an error, not a note)
  epito run <dir>     put every agent.toml under <dir> on the runtime: one
                      schedule per [trigger].cron, then serve the ingress
                      (--dry-run prints the schedule changes and stops)
  epito worker        do the work: poll the \`seats\` task queue and run seats
  epito ps [dir]      the roster, read from the runtime
  epito routes [dir]  which model road each seat takes on THIS machine, and
                      which declared roads are closed here (--json)
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
  epito deploy [name] [dir]
                      give the agent its own identity on GitHub: create its
                      App pre-filled from [identity].scopes, keep the key in
                      .epito/ (0600), record the installation on
                      [runtime].repo (--dry-run says what it would create and
                      touches neither the network nor a browser)

The runtime is two processes and one engine: \`epito run\` reconciles and
serves the ingress, \`epito worker\` executes, and Temporal (self-hosted,
TEMPORAL_ADDRESS, default 127.0.0.1:7233) is what makes a run survive a
reboot. See docs/prfaq/epitod-v1-temporal.md.

The board is where the runs show up: every seat epitod runs files its own
report, and a seat that runs somewhere else files one with \`epito report\`.
See ADR-16 (docs/decisions.md).

A seat can declare several roads to a model: \`[[runtime.route]]\` names them in
order, and a run takes the first one that starts it — falling back only while
the agent has provably done nothing (ADR-19). \`epito routes\` says which are
open on this box.

A seat does not have to be a Claude session: \`[runtime].adapter = "langgraph"\`
runs a LangGraph app through the \`langgraph.json\` its author already wrote,
unmodified (ADR-17). Set OTEL_EXPORTER_OTLP_ENDPOINT — Phoenix, Jaeger, Tempo,
anything that takes OTLP — and every run files a trace: the run, its clone, its
mint, and whatever the agent itself emits inside it (ADR-18).
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
  // `[runtime].repo` is the one field the prompt cannot supply and every other
  // command requires, so the manifest init used to write validated and was
  // then refused by `epito run`, `epito deploy` and `epito token` alike. The
  // answer is almost always the directory you are standing in. Local read of
  // one git remote — no network, no account (src/lib/origin.js).
  const origin = originRepo();
  const repoLine = origin
    ? `repo = "${origin}"\n`
    : `# repo = "owner/name"
#   the repository the runtime clones for every run, and what bounds this
#   agent's token to one repo. \`epito run\`, \`epito deploy\` and \`epito token\`
#   all need it, and \`epito validate\` says so until it is set.
`;
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
${repoLine}`);
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
  if (origin) console.log(`  [runtime].repo = ${origin}, read from this directory's git origin`);
  else console.log(`  [runtime].repo is commented out: this directory has no GitHub origin to read it from, and \`epito run\`, \`epito deploy\` and \`epito token\` each need it`);
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
  // The adapter is named only when it is not the default, so every manifest
  // written before adapters existed validates with the line it always had.
  const adapter = m.runtime?.adapter;
  console.log(`✓ ${a.name} is an agent: identity (${m.identity.scopes.length} scope${m.identity.scopes.length > 1 ? "s" : ""}), trigger, runtime${adapter && adapter !== "claude" ? ` — a ${adapter} agent` : ""}`);

  // A valid manifest is not the same thing as a runnable one, and the tick used
  // to imply both: spec v0.1 keeps `[runtime].repo` optional and leaves an
  // unmapped scope to the mint, so `epito validate` passed files that
  // `epito run`, `epito ps`, `epito deploy` and `epito token` all refused.
  // The rules are the other commands' (src/lib/readiness.js); saying them here
  // is the difference between a ✓ that is correct and a ✓ that is honest.
  const ready = blockers(m, "agent.toml");
  const notChecked = unchecked(m);  // cwd is the baseDir, as it is for validate's own entry check
  for (const u of notChecked) console.log(`  — ${u}`);
  if (ready.length) {
    // --for-runtime is the opt-in strict pass, for the person who wants CI to
    // fail here instead of at 06:00. The default stays exit 0, because the spec
    // says these manifests are valid and a validator that refused them would
    // break every Actions-era file on purpose.
    const strict = args.includes("--for-runtime");
    const say = strict ? console.error : console.log;
    say(`\n${a.name} is valid, and not ready to run:\n`);
    for (const b of ready) say(`  ! ${b.problem}.\n    Fix: ${b.fix}.`);
    if (strict) { console.error(`\nepito: --for-runtime asks whether the runtime would accept this manifest, and it would not.`); process.exit(1); }
    say(`\nThis file is a valid v0.1 manifest either way — run \`epito validate --for-runtime\` to make the above an error instead of a note.`);
  }
  process.exit(0);
}

if (cmd === "run") {
  const dir = args.find((a) => !a.startsWith("-"));
  if (!dir) die("run needs a directory: `epito run <dir>` puts every agent.toml under <dir> on the runtime");
  // The engine being unreachable is an operating condition, not a crash: it
  // gets the same one-line treatment as a broken manifest, never a stack.
  // The import is INSIDE the guard on purpose — the engine packages are
  // optional peers (package.json), so "not installed at all" is the first
  // way this fails, and it used to escape the guard as a raw
  // ERR_MODULE_NOT_FOUND. engineImport turns that one into a sentence.
  try {
    const { runDaemon } = await engineImport(() => import("./run.js"), "run");
    await runDaemon(dir, { dryRun: args.includes("--dry-run") });
  } catch (e) { die(e.message); }
} else if (cmd === "worker") {
  try {
    const { runWorker } = await engineImport(() => import("./temporal/worker.js"), "worker");
    await runWorker();
  } catch (e) { die(e.message); }
  process.exit(0);
} else if (cmd === "ps") {
  try {
    const { psCmd } = await engineImport(() => import("./temporal/ps.js"), "ps");
    await psCmd(args[0]);
  } catch (e) { die(e.message); }
  process.exit(0);
} else if (cmd === "window") {
  try {
    const { windowCmd } = await engineImport(() => import("./run.js"), "window");
    await windowCmd(args[0], args[1], args[2]);
  } catch (e) { die(e.message); }
  process.exit(0);
} else if (cmd === "token") {
  const { tokenCmd } = await import("./token.js");
  const rest = args.filter((a) => !a.startsWith("-"));
  await tokenCmd(rest[0], rest[1] ?? ".", { dryRun: args.includes("--dry-run") });
  process.exit(0);
} else if (cmd === "routes") {
  const { routesCmd } = await import("./routes.js");
  await routesCmd(args);
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
  try {
    const { message } = await engineImport(() => import("./run.js"), "message");
    await message(args[0], args.slice(1).join(" "));
  } catch (e) { die(e.message); }
  process.exit(0);
}

if (cmd === "deploy") {
  const { deployCmd } = await import("./deploy.js");
  await deployCmd(args);
  process.exit(0);
}

die(`unknown command "${cmdRaw}" — try \`epito help\``);
