// `epito env [dir]` — the names this roster asks the box to hold, and what
// this box is doing about each of them.
//
// The sibling of `epito routes`. That one answers "which model does each seat
// actually run on here"; this one answers "and what else does each seat
// actually get here", which is the same kind of question — a fact about the
// box that the manifests cannot settle on their own — and had no command.
//
// Why it is worth one: the runtime injects only the names it holds, so a box
// short of a name produces a seat that runs, exits 0, and quietly does less.
// src/lib/boxenv.js tells the story this company lived through.
//
// Three outcomes per name, and the middle one is why the exit code is not just
// "everything is fine":
//
//   held    the box has it
//   absent  the box does not, the runtime drops it, the agent runs without it
//           — a report, never an error. `[runtime].env` is the list the
//           runtime injects FROM, not a list of what the seat cannot work
//           without, and nothing in a manifest distinguishes the two. The PM
//           seat's LINEAR_API_KEY is genuinely optional (its charter skips the
//           mirror cleanly); its BOARD_RUNTIME_TOKEN is not. Guessing which is
//           which would be this command inventing a field, so `--complete` is
//           where the operator asserts it instead.
//   empty   the box has it and has it set to nothing, which is a half-filled
//           line in an env file. Same shape as a `base_url_env` that does not
//           hold a URL, and the same answer: it exits 1, by name, because the
//           box HAS this one and has it wrong (`epito routes` made that split
//           first, and the reasoning is the same there).
// And one block of names that is NOT in any manifest, which is why it was
// missing from the first version of this command: a seat's own identity.
// `EPITO_APP_ID_<SEAT>` and its key are derived from `[agent].name` rather
// than declared by the manifest, and whether this box holds them decides
// whether that seat's pull requests open as `<name>[bot]` or as a person. That
// is a visible difference in every PR the seat opens, and the only commands
// that could see it were `epito token` and the run itself. src/lib/acts.js is
// the reader, shared with `epito doctor`, so the two cannot disagree about who
// a seat is — and the exit code stays this command's own: whether a run would
// REFUSE is doctor's contract, not this one's.
import { readFileSync, statSync } from "node:fs";
import { loadRoster } from "./lib/roster.js";
import { inRepo } from "./lib/where.js";
import { rosterEnv, envTemplate, askers, shortfallSays, HELD, EMPTY, ABSENT } from "./lib/boxenv.js";
import { rosterActs, IDENTITY_FIX, OWN, REFUSED, HALF, SHARED, NONE } from "./lib/acts.js";
import { envFileReport } from "./lib/envfile.js";

export const ENV_FLAGS = [
  { name: "json", does: "the report as JSON" },
  { name: "template", does: "print the env file these names belong in, one commented KEY= per name" },
  { name: "complete", does: "make a name this box does not hold an error, not a report — the box check" },
  { name: "file", value: true, does: "read an env file this box holds the way the UNITS read it, and say which of its lines a shell reading the same bytes would read differently" },
];

// The box's own environment: real, required, and in no manifest. Named in the
// closing line so a reader cannot take "this box holds every name" for "this
// box is ready" — these are the runtime's, not a seat's, and they are
// deploy/provision-host.sh's to write.
const RUNTIME_OWN = ["CLAUDE_CODE_OAUTH_TOKEN", "GH_TOKEN", "TEMPORAL_ADDRESS", "EPITO_PORT", "EPITO_HOOK_SECRET"];

const MARK = { [HELD]: "✓", [ABSENT]: "—", [EMPTY]: "✗" };
const SAYS = {
  [HELD]: "held here",
  [ABSENT]: "not set here",
  [EMPTY]: "set here, and set to nothing",
};

const plural = (n, word) => `${n} ${word}${n === 1 ? "" : "s"}`;

// --- the second block: the names no manifest declares ---------------------
// Grouped by the answer rather than listed per seat, the same way doctor's
// identity section is: five seats with no App of their own share one sentence
// and one fix, and the first draft that printed a paragraph each buried the
// one seat that had something wrong.
function printIdentity(roster, dir) {
  const acts = rosterActs(roster, { env: process.env });
  const groups = [];
  for (const row of acts.seats) {
    const key = row.state === OWN ? `own|${row.agent}` : `${row.state}|${row.says}`;
    const found = groups.find((g) => g.key === key);
    if (found) found.agents.push(row.agent);
    else groups.push({ key, state: row.state, says: row.says, fix: row.fix, agents: [row.agent] });
  }
  const MARKS = { [OWN]: "✓", [SHARED]: "!", [NONE]: "!", [HALF]: "✗", [REFUSED]: "✗" };
  console.log(`and the names no manifest declares — who each seat acts as here, from $EPITO_APP_ID_<SEAT> and its key (the seat's name uppercased, - as _)\n`);
  for (const g of groups) {
    console.log(`${MARKS[g.state]} ${g.says} — ${g.agents.join(", ")}`);
    if (g.fix) console.log(`    Fix: ${g.fix}.`);
  }
  if (acts.shared.length || acts.none.length) console.log(`  Fix: ${IDENTITY_FIX}.`);
  if (acts.refusals.length) {
    console.log(`  ${plural(acts.refusals.length, "seat")} above ${acts.refusals.length === 1 ? "has an identity" : "have identities"} on this box a run cannot use: \`epito doctor ${dir}\` is the command that refuses over ${acts.refusals.length === 1 ? "it" : "them"}, because a run that cannot mint is a run that does not start.`);
  }
  console.log(`  These names are not in \`--template\`: no manifest declares them, and that file is generated from the manifests. ${inRepo('docs/deploy/README.md', '"Giving an agent its own identity"')} is where they go on a box.\n`);
  return acts;
}


// --- `--file`: the file itself, not the box ------------------------------
// A different question from the rest of this command, which is why it is a
// mode and not a column: everything else here asks "what does this box hold",
// read out of `process.env`. This asks "what does this FILE say, and does
// every reader of it agree", which is answerable about a box you are not on
// and about a file no unit has loaded yet.
//
// It exists because the answer was "no" on this company's own host for
// eighteen hours and no command could say so (cli/src/lib/envfile.js tells
// that story). The shell reader the box now uses is
// /usr/local/lib/epito-envfile.sh, installed by deploy/provision-host.sh, and
// it has the same rules as this.
//
// No value is printed, ever -- names, byte counts and verdicts only, the same
// rule the rest of this command follows. That is deliberate and it is the
// reason this output is safe to paste anywhere, which is what somebody will do
// with it the first time a box misbehaves.
function envFileArg(args) {
  const eq = args.find((a) => a.startsWith("--file="));
  if (eq !== undefined) return eq.slice("--file=".length);
  const i = args.indexOf("--file");
  if (i === -1) return null;
  const next = args[i + 1];
  return next === undefined || next.startsWith("-") ? "" : next;
}

const SEVERITY = { "a shell runs it": 3, "a shell runs the rest of the line": 3, "a shell splits it": 2, "a shell expands it": 2, "a shell drops characters from it": 1, "a shell may swallow the lines after it": 1 };

function envFileCmd(path, { json = false } = {}) {
  if (path === "") {
    console.error("epito: `epito env --file` names no file. Fix: give it the path the units name in `EnvironmentFile=` — `epito env --file /srv/asc/env` — which is the file this command reads the way systemd reads it.");
    process.exit(1);
  }
  let text, mode;
  try {
    text = readFileSync(path, "utf8");
    mode = (statSync(path).mode & 0o777).toString(8).padStart(4, "0");
  } catch (e) {
    console.error(`epito: cannot read the env file ${path} (${e.code ?? e.message}) — \`--file\` reads an env file this box already holds, and does not create one. Fix: check the path the units name in \`EnvironmentFile=\`, or run as a user that may read it (the file holds secrets and is 0600 by design); \`epito env <roster> --template\` prints what belongs in it.`);
    process.exit(1);
  }
  const report = envFileReport(text);
  if (json) {
    console.log(JSON.stringify({
      file: path,
      mode,
      names: report.names.map((r) => ({ name: r.name, line: r.at, bytes: r.bytes, quoted: r.quote || null, times: r.times, diverges: r.diverges.map((d) => d.says) })),
      malformed: report.malformed.map((r) => ({ line: r.at })),
      badNames: report.badNames.map((r) => ({ line: r.at, name: r.name })),
    }, null, 2));
    process.exit(report.diverging.length || report.malformed.length || report.badNames.length || report.empty.length ? 1 : 0);
  }

  const n = report.names.length;
  console.log(`${path} — ${plural(n, "name")}, read the way the units read it: one KEY=value per line, nothing expanded (mode ${mode})\n`);
  if (n) {
    const w = Math.max(...report.names.map((r) => r.name.length));
    for (const row of report.names) {
      const worst = [...row.diverges].sort((a, b) => (SEVERITY[b.says] ?? 0) - (SEVERITY[a.says] ?? 0));
      const mark = row.bytes === 0 ? "✗" : worst.length ? "!" : "✓";
      const says = row.bytes === 0
        ? "set here, and set to nothing"
        : `${String(row.bytes).padStart(4)} bytes${row.quote ? `, ${row.quote === "'" ? "single" : "double"}-quoted` : ""}`;
      console.log(`${mark} ${row.name.padEnd(w)}  ${says}${worst.length ? `  —  ${worst.map((d) => d.says).join("; ")}` : ""}`);
    }
    console.log("");
  }

  // The value of a repeated name is not the line most people would edit.
  for (const row of report.repeated) {
    console.log(`! ${row.name} is assigned ${row.times} times in this file and systemd takes the LAST one, line ${row.at} — so an edit to any earlier line of it changes nothing. Fix: delete the lines that do not win.`);
  }
  if (report.repeated.length) console.log("");

  const problems = [];
  if (report.diverging.length) {
    const first = report.diverging[0];
    const worst = [...first.diverges].sort((a, b) => (SEVERITY[b.says] ?? 0) - (SEVERITY[a.says] ?? 0))[0];
    problems.push(`${plural(report.diverging.length, "value")} in ${path} ${report.diverging.length > 1 ? "are read" : "is read"} differently by systemd and by a shell (${report.diverging.map((r) => r.name).join(", ")}) — systemd takes the bytes as they are; of ${first.name}, on line ${first.at}, ${worst.says}: ${worst.detail}. `
      + `A unit with \`EnvironmentFile=${path}\` therefore works while every script that sources the same file gets a wrong value, runs part of one, or dies on \`set -u\` — which is the eighteen-hour outage this check exists because of. `
      + `Fix: stop sourcing this file from a shell — \`. /usr/local/lib/epito-envfile.sh\` then \`load_env_file ${path}\` reads it with systemd's rules (deploy/provision-host.sh installs it) — or, if a shell must source it, single-quote those ${report.diverging.length > 1 ? "values" : "that value"}, which is the one quoting a shell and systemd read alike.`);
  }
  if (report.badNames.length) {
    problems.push(`${plural(report.badNames.length, "line")} in ${path} assign a name neither systemd nor a shell can hold (${report.badNames.map((r) => `line ${r.at}, "${r.name}"`).join("; ")}) — a variable name is a letter or underscore followed by letters, digits and underscores, so systemd drops ${report.badNames.length > 1 ? "those lines" : "that line"} and the name never reaches a run. Fix: rename ${report.badNames.length > 1 ? "them" : "it"}, or delete the ${report.badNames.length > 1 ? "lines" : "line"}.`);
  }
  if (report.malformed.length) {
    problems.push(`${plural(report.malformed.length, "line")} in ${path} ${report.malformed.length > 1 ? "are" : "is"} neither a comment nor a KEY=value assignment (${report.malformed.map((r) => `line ${r.at}`).join(", ")}) — systemd ignores ${report.malformed.length > 1 ? "them" : "it"} silently. Fix: put a \`#\` in front of ${report.malformed.length > 1 ? "them" : "it"} if ${report.malformed.length > 1 ? "they are notes" : "it is a note"}, or give ${report.malformed.length > 1 ? "them" : "it"} a name and an \`=\`.`);
  }
  if (report.empty.length) {
    problems.push(`${plural(report.empty.length, "name")} in ${path} ${report.empty.length > 1 ? "are" : "is"} set and set to nothing (${report.empty.map((r) => r.name).join(", ")}) — the runtime injects an empty value, the agent reads it, and whatever it builds out of it fails somewhere far from here. Fix: put the value after the \`=\`, or delete the line entirely, which is the honest way to say this box does not have it.`);
  }
  if (problems.length) {
    for (const line of problems) console.error(`epito: ${line}`);
    process.exit(1);
  }
  console.log(`✓ every line of ${path} reads the same whether systemd or a shell reads it. ${inRepo("deploy/provision-host.sh")} writes this file and ${inRepo("cli/src/lib/envfile.js")} is the parse both this command and the box's own reader use.`);
  process.exit(0);
}

export async function envCmd(args = []) {
  // Before the roster: this mode asks about a file, and a box being asked
  // about a file does not have to carry manifests at all.
  const file = envFileArg(args);
  if (file !== null) return envFileCmd(file, { json: args.includes("--json") });

  const dir = args.find((a) => !a.startsWith("-")) ?? ".";
  const roster = loadRoster(dir);
  const report = rosterEnv(roster, process.env);

  if (args.includes("--json")) {
    // The identity half rides along rather than needing a second command and a
    // second JSON shape. Which App, never the key (spec rule 1).
    const acts = rosterActs(roster, { env: process.env });
    console.log(JSON.stringify({ ...report, identity: acts.seats.map((r) => ({ agent: r.agent, state: r.state, source: r.source, appId: r.appId, installation: r.installation, says: r.says })) }, null, 2));
    process.exit(report.empty.length ? 1 : 0);
  }
  if (args.includes("--template")) {
    // To stdout and nothing else, because the thing an operator does with this
    // is `>> /srv/asc/env`. Every other word this command says goes to stderr
    // in this mode, or it would end up in the file.
    console.log(envTemplate(report, { dir }));
    process.exit(0);
  }

  const strict = args.includes("--complete");
  const n = report.names.length;
  if (n === 0) {
    console.log(`roster ${dir} — no manifest under it names a variable, so this box needs nothing beyond the runtime's own environment (${RUNTIME_OWN.join(", ")}).\n`);
    // A roster that declares no variables still has identities, and those are
    // the names nobody declares: this block is the whole report here.
    printIdentity(roster, dir);
    process.exit(0);
  }
  const held = report.names.filter((r) => r.state === HELD).length;
  console.log(`roster ${dir} — ${plural(n, "name")} the manifests ask this box to hold, and it holds ${held}\n`);

  const w = Math.max(...report.names.map((r) => r.name.length));
  for (const row of report.names) {
    console.log(`${MARK[row.state]} ${row.name.padEnd(w)}  ${SAYS[row.state]} — ${askers(row.uses)}`);
  }
  console.log("");

  // Per seat, and only for the seats that are short: a seat whose every name
  // is here needs no line, and five lines saying "nothing missing" would bury
  // the one line that is not.
  //
  // The sentence itself is `shortfallSays` in src/lib/boxenv.js, because
  // `epito run` says it at startup and the charter preamble says it to the
  // agent — and a shortfall described three ways in one product is a reader
  // comparing three paraphrases to work out whether they mean the same thing.
  for (const s of report.seats.filter((x) => x.short.length)) {
    console.log(`! ${s.agent} runs here with ${s.held.length} of ${plural(s.asked.length, "name")}: ${shortfallSays(s)}`);
  }
  if (report.seats.some((s) => s.short.length)) console.log("");

  printIdentity(roster, dir);

  if (report.empty.length) {
    const names = report.empty.map((r) => r.name);
    console.error(`epito: ${plural(names.length, "name")} on this box ${names.length > 1 ? "are" : "is"} set and set to nothing (${names.join(", ")}) — the runtime injects an empty value, the agent reads it, and whatever it builds out of it fails somewhere far from here. Fix: put the value after the = in this box's env file, or delete the line entirely, which is the honest way to say this box does not have it.`);
    process.exit(1);
  }

  if (!report.missing.length) {
    console.log(`✓ this box holds every name ${dir} asks for. The runtime's own environment is not counted here and is not in any manifest: ${RUNTIME_OWN.join(", ")} (${inRepo("deploy/provision-host.sh")} writes them).`);
    process.exit(0);
  }

  const missing = report.missing.map((r) => r.name);
  const roadHalves = report.missing.filter((r) => r.uses.some((u) => /^the (key|endpoint) for route/.test(u.role ?? "")));
  if (strict) {
    console.error(`epito: --complete asks whether this box holds every name ${dir} names, and it does not: ${missing.join(", ")}. Fix: add ${missing.length > 1 ? "those lines" : "that line"} to this box's env file — \`epito env ${dir} --template\` prints the file with every name in it, commented, values blank.`);
    process.exit(1);
  }
  console.log(`${plural(missing.length, "name")} ${missing.length > 1 ? "are" : "is"} not on this box. That is not an error here: \`[runtime].env\` is the list the runtime injects FROM, and nothing in a manifest says which of those names a seat cannot work without — so a roster stays portable and this command does not guess. \`epito env ${dir} --complete\` is where you assert that this box should hold all of them.`);
  if (roadHalves.length) {
    console.log(`  ${roadHalves.length} of them ${roadHalves.length > 1 ? "are halves" : "is half"} of a road (${roadHalves.map((r) => r.name).join(", ")}): \`epito routes ${dir}\` says which seats that leaves on which model.`);
  }
  console.log(`  Fix, if they should be here: \`epito env ${dir} --template\` prints this roster's env file, one commented KEY= per name, values blank and never read from the box.`);
  process.exit(0);
}
