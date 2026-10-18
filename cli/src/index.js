#!/usr/bin/env node
import { writeFileSync, existsSync, mkdirSync, statSync, accessSync, constants } from "node:fs";
import { NAME_RE, kebab } from "./lib/manifest.js";
import { ignore } from "./lib/gitignore.js";
import { engineImport } from "./lib/engine.js";
import { originRepo } from "./lib/origin.js";
import { unknownOption } from "./lib/flags.js";

const [, , cmdRaw, ...args] = process.argv;
// `epito me` is `epito init`: mint an epitome of yourself.
const cmd = cmdRaw === "me" ? "init" : cmdRaw;

const HELP = `epito — mint agents: identity + trigger + runtime from one file

  epito init [name]   scaffold agent.toml and a charter (alias: epito me)
  epito validate [dir]
                      check agent.toml against the manifest spec, and name what the
                      runtime will still need before it can run this agent.
                      Given a directory, check the WHOLE ROSTER — every
                      manifest under it plus the rules about the set — needing
                      no engine to do it, and say whether the engine the
                      runtime would use is up (--for-runtime makes both the
                      notes and a missing engine errors, which is exactly what
                      \`epito run <dir>\` would refuse)
  epito doctor [dir]  would a run on THIS box start? the manifests, the names,
                      the roads, the EXECUTOR epito spawns (resolved on the PATH
                      a run gets, started under the environment a run gives it),
                      the engine, and whether a WORKER is polling its queue —
                      exit 1 naming the piece that is missing
                      (--deep also runs one real turn per road, which costs a
                      model call and is the only thing that proves credentials)
  epito run <dir>     put every agent.toml under <dir> on the runtime: one
                      schedule per [trigger].cron, then serve the ingress
                      (--dry-run prints the schedule changes and stops)
  epito worker        do the work: poll the \`seats\` task queue and run seats
  epito ps [dir]      the roster, read from the runtime
  epito routes [dir]  which model road each seat takes on THIS machine, and
                      which declared roads are closed here (--json)
  epito env [dir]     which NAMES this roster asks this machine to hold, who
                      asks for each and whether it is here — the runtime
                      injects only the names it has, so a box short of one
                      makes a seat that runs and quietly does less
                      (--template prints the env file, --complete makes a
                      missing name an error, --json)
  epito board         what the seats have been doing: run reports, newest
                      last (--agent, --kind, --limit, --json)
  epito audit [name]  the ledger: every App created, every token minted and
                      what it could do, every run and every road refused
                      (--agent, --action, --since, --limit, --json)
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
  epito deploy [name] [dir] --target cloudflare
                      pack the SAME manifest as a Cloudflare Worker that is
                      the agent: its own App identity minted inside the
                      Worker, [trigger].cron as the Worker's schedule, one
                      Durable Object holding its runs, and a page showing the
                      agent, its last run and a button that triggers it. Writes
                      the bundle and stops — \`wrangler deploy\` spends your
                      Cloudflare account, so it stays your command (--out,
                      --dry-run)

The runtime is two processes and one engine: \`epito run\` reconciles and
serves the ingress, \`epito worker\` executes, and Temporal (self-hosted,
TEMPORAL_ADDRESS, default 127.0.0.1:7233) is what makes a run survive a
reboot. See docs/prfaq/epitod-v1-temporal.md.

The board is where the runs show up: every seat epitod runs files its own
report, and a seat that runs somewhere else files one with \`epito report\`.
See ADR-16 (docs/decisions.md).

The board and the ledger answer two different questions. The board is "what
have the seats been doing" — run reports, folded for an owner. The ledger
(\`epito audit\`, .epito/audit.jsonl) is "what exactly happened", including the
lines nobody reads until something is wrong: which permissions each agent's
token actually held, on which repository, until when.

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

// An option epito does not know is refused before the command runs. It used to
// be dropped, which made `--dry-runn` a real mint and `--for-runtimes` a ✓ that
// asserted nothing (src/lib/flags.js says why at more length). `window` and
// `message` are absent on purpose: their last argument is free text a person
// wrote, and text is allowed to start with a dash.
const gate = (name, argv, known) => { const e = unknownOption(name, argv, known); if (e) die(e); };

if (!cmd || cmd === "help" || cmd === "--help") {
  console.log(HELP);
  process.exit(0);
}

if (cmd === "init") {
  const self = `epito ${cmdRaw === "me" ? "me" : "init"}`;
  gate(cmdRaw === "me" ? "me" : "init", args, []);
  const asked = args[0] ?? "my-agent";
  const name = String(asked).toLowerCase();
  if (!NAME_RE.test(name)) {
    die(`name must be lower-case letters, digits and hyphens, 1-40 characters, got "${asked}" — a name becomes a schedule id, a clone directory and a column on the board. ` +
      (kebab(asked) ? `Fix: \`${self} ${kebab(asked)}\`.` : "Fix: pick a name of lower-case letters, digits and hyphens."));
  }
  if (existsSync("agent.toml")) {
    die(`agent.toml already exists here — one manifest, one agent. Fix: \`epito validate\` checks the one that is here; a second agent gets its own directory (\`mkdir ../other && cd ../other && ${self} other\`).`);
  }
  // Everything init is about to write, refused BEFORE it writes any of it. It
  // used to write agent.toml first and discover the rest as it went, so a
  // directory it could not write, or a `prompts` that was already a file,
  // answered with a Node stack — `EEXIST: file already exists, mkdir
  // 'prompts'`, fourteen lines of it — and left a half-minted agent behind
  // the trace. It is the first command anyone runs, and it has the ingress's
  // own bar to clear (src/run.js, the taken port).
  try { accessSync(".", constants.W_OK); }
  catch { die(`cannot mint here: ${process.cwd()} is not writable by this user, and nothing was written. Fix: run ${self} in a directory you own — \`mkdir ~/${name} && cd ~/${name} && ${self} ${name}\`.`); }
  if (existsSync("prompts") && !statSync("prompts").isDirectory()) {
    die(`a FILE named prompts is already here, and the charter goes in a directory of that name (prompts/${name}.md). Nothing was written. Fix: rename or remove ./prompts, then run ${self} again.`);
  }
  // Anything left — a race, a full disk, a read-only mount that lied to
  // access(2) — still gets a sentence rather than a stack, and says how far
  // the mint got, because a partly minted directory is the thing the reader
  // has to clean up.
  const sofar = [];
  const wrote = (what, fn) => {
    try { fn(); sofar.push(what); }
    catch (e) {
      die(`${self} could not write ${what} in ${process.cwd()}: ${e.code === "ENOSPC" ? "no space left on the device" : e.message}.` +
        (sofar.length ? ` ${sofar.join(" and ")} ${sofar.length > 1 ? "were" : "was"} written already, so this directory is half minted. Fix: remove ${sofar.join(" and ")}, make room, and run ${self} again.` : ` Fix: make room and run ${self} again.`));
    }
  };
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
  wrote("agent.toml", () => writeFileSync("agent.toml", `[agent]
name = "${name}"
description = "One sentence: what this agent does."

[identity]
scopes = ["github:contents", "github:pull_requests"]

[trigger]
cron = "0 6 * * *"

[runtime]
model = "claude-sonnet-5"
entry = "${charter}"
${repoLine}`));
  // An agent's App key lands in .epito/keys/ and its ledger in
  // .epito/audit.jsonl. The manifest is publishable by design and that
  // directory is not, so init makes the difference structural rather than a
  // thing the reader has to remember (spec rule 1).
  wrote(".gitignore", () => ignore(".epito/"));
  wrote("prompts/", () => mkdirSync("prompts", { recursive: true }));
  if (!existsSync(charter)) {
    wrote(charter, () => writeFileSync(charter, `# ${name}\n\nYou are ${name}. This file is your charter: who you are, what one\nrun accomplishes, and what you never do. Everything worth remembering\nlives in a file, because every run is a fresh context.\n`));
  }
  console.log(`minted ${name}: agent.toml + ${charter}`);
  // Lower-casing is the one thing init does to the name it was handed, and it
  // used to do it in silence: `epito init Historian` minted `historian` and
  // said `minted historian`, leaving the reader to notice. A name that comes
  // back different from the one you typed is worth one line.
  if (String(asked) !== name) console.log(`  the name was lower-cased: "${asked}" is "${name}" to the schedule, the board and every audit line`);
  if (origin) console.log(`  [runtime].repo = ${origin}, read from this directory's git origin`);
  else console.log(`  [runtime].repo is commented out: this directory has no GitHub origin to read it from, and \`epito run\`, \`epito deploy\` and \`epito token\` each need it`);
  console.log(`next: edit both, then \`epito validate\``);
  process.exit(0);
}

if (cmd === "validate") {
  const { validateCmd, VALIDATE_FLAGS } = await import("./validate.js");
  gate("validate", args, VALIDATE_FLAGS);
  await validateCmd(args);
  // validateCmd exits on every path today. This line is here for the same
  // reason `run` and `audit` have one: whether a command reaches the
  // `unknown command` fallthrough must not depend on where another file put
  // its exit (see the comment on `run` below — that one cost a CI gate).
  process.exit(0);
}

if (cmd === "run") {
  gate("run", args, [{ name: "dry-run", does: "print the schedule changes and stop" }]);
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
  // `--dry-run` is the only way this returns — the daemon otherwise serves
  // until a signal — and without this line it fell out of the chain and hit
  // the `unknown command` fallthrough at the bottom: a dry run printed its
  // whole plan, then `epito: unknown command "run"`, then exited 1. A CI gate
  // that ran `epito run agents --dry-run` to check a roster saw a failure on
  // a roster that was fine.
  process.exit(0);
} else if (cmd === "worker") {
  gate("worker", args, []);
  try {
    const { runWorker } = await engineImport(() => import("./temporal/worker.js"), "worker");
    await runWorker();
  } catch (e) { die(e.message); }
  process.exit(0);
} else if (cmd === "ps") {
  gate("ps", args, []);
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
  gate("token", args, [{ name: "dry-run", does: "say what it would ask for, and touch neither the network nor a key" }]);
  const { tokenCmd } = await import("./token.js");
  const rest = args.filter((a) => !a.startsWith("-"));
  await tokenCmd(rest[0], rest[1] ?? ".", { dryRun: args.includes("--dry-run") });
  process.exit(0);
} else if (cmd === "routes") {
  gate("routes", args, [{ name: "json", does: "the report as JSON" }]);
  const { routesCmd } = await import("./routes.js");
  await routesCmd(args);
  process.exit(0);
} else if (cmd === "doctor") {
  const { doctorCmd, DOCTOR_FLAGS } = await import("./doctor.js");
  gate("doctor", args, DOCTOR_FLAGS);
  await doctorCmd(args);
  process.exit(0);
} else if (cmd === "env") {
  const { envCmd, ENV_FLAGS } = await import("./env.js");
  gate("env", args, ENV_FLAGS);
  await envCmd(args);
  process.exit(0);
} else if (cmd === "board") {
  const { boardCmd } = await import("./board.js");
  await boardCmd(args);
  process.exit(0);
} else if (cmd === "audit") {
  const { auditCmd } = await import("./audit.js");
  await auditCmd(args);
  // Every other branch exits here too. `epito audit` happens to exit from
  // inside auditCmd on all three of its paths today, so this line changes
  // nothing — which is the point: whether a command reaches the fallthrough
  // should not depend on where some other file put its exit.
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
