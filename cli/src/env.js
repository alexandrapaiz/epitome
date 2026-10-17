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
import { loadRoster } from "./lib/roster.js";
import { inRepo } from "./lib/where.js";
import { rosterEnv, envTemplate, askers, shortfallSays, HELD, EMPTY, ABSENT } from "./lib/boxenv.js";
import { rosterActs, IDENTITY_FIX, OWN, REFUSED, HALF, SHARED, NONE } from "./lib/acts.js";

export const ENV_FLAGS = [
  { name: "json", does: "the report as JSON" },
  { name: "template", does: "print the env file these names belong in, one commented KEY= per name" },
  { name: "complete", does: "make a name this box does not hold an error, not a report — the box check" },
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

export async function envCmd(args = []) {
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
