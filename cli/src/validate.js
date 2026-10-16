// `epito validate` — two questions, one set of rules.
//
//   epito validate            is the manifest in this directory an agent
//   epito validate <dir>      is every manifest under it an agent, and is the
//                             ROSTER one (spec rule 4) — with no engine running
//   epito validate <file>     the named manifest, wherever it sits
//
// The roster form is the one an operator has a use for and the one that did not
// exist. Validating this company's own five seats meant five `cd`s and a shell
// loop, and docs/ideas.md raised that twice independently in one run — "an
// operator with five manifests and no box has no single command that says yes".
// The only command that reads a roster whole, `epito run <dir> --dry-run`,
// connects to Temporal first. Whether a directory of files is a roster is a
// filesystem question, and it should not need a server to answer.
//
// Three decisions the card left open, settled here:
//
//   - A POSITIONAL, not a flag. `epito run <dir>`, `epito ps [dir]` and `epito
//     routes [dir]` already mean "the roster at this path"; a `--roster` flag
//     would be a second spelling of an idea this CLI has already spelled.
//   - `--for-runtime` does NOT become implicit when a directory is named, even
//     though asking about a roster is nearly asking the runtime's question. It
//     would make `epito validate agents` refuse a roster the spec blesses, and
//     the default has to keep saying yes to every manifest the spec blesses
//     (src/lib/readiness.js argues this at length). What the flag buys instead
//     is exact: `epito validate <dir> --for-runtime` refuses precisely what
//     `epito run <dir>` refuses. SEVERITY below is what makes that an invariant
//     rather than a sentence in a PR.
//
// That last line used to end "minus the engine", and `epito --help` said the
// flag "asks exactly what `epito run <dir>` would ask". Both shipped, and only
// one of them could be true. On a box with no engine this command ticked five
// seats and said "there is nothing here `epito run agents` would refuse", and
// `epito run agents --dry-run` then refused in one line before it read a
// manifest — the exact failure readiness.js was written to remove ("`epito
// validate` ticked it, and `epito run` then refused it ... a refusal the tick
// had just told them would not come"), reintroduced one level up.
//
// So the engine is looked at, and the look costs nothing: a bare TCP connect
// with a 400ms ceiling, no engine package imported, no gRPC. "No engine
// required" stays literally true — the command needs no engine to run and
// still answers the manifest question in full without one. What changes is
// that it no longer speaks for a command it never consulted. The engine is a
// fact about the BOX, not about a manifest, so it is not a per-seat error or
// blocker: it is the closing verdict, where the overclaim was.
//   - The worst outcome wins the exit code. One refused manifest in five exits
//     1, because "a roster runs whole or not at all" — loadRoster's own words,
//     and the reason `epito run` would not have started either.
import { existsSync, readFileSync, statSync } from "node:fs";
import { dirname, relative, resolve } from "node:path";
import { parseManifest, validateManifest } from "./lib/manifest.js";
import { blockers, unchecked } from "./lib/readiness.js";
import { SPEC_VERSION } from "./lib/fields.js";
import { ROSTER_RULES, findManifests, rosterRules } from "./lib/roster.js";
// The address and the look, through a module that imports no @temporalio: the
// roster form has to be able to say whether the engine is up on a machine that
// could not run it (test/pack.sh asserts the manifest commands work there).
import { engineAddress, engineAnswering, engineFix, engineMissing } from "./lib/engine.js";

export const VALIDATE_FLAGS = [{ name: "for-runtime", does: "make the readiness notes — and an engine that is not up — an error, not a note" }];

// How this command treats each rule a roster adds beyond the per-manifest ones.
// `name` is a refusal: spec rule 4 ("one manifest, one principal") is a rule
// about the files, and no --for-runtime should be needed to hear that two seats
// are asking for one identity. `repo` is a note, because readiness.js already
// carries it with a better sentence and a fix, and because a manifest without
// it is a valid manifest.
//
// Every rule ROSTER_RULES names MUST appear here. A rule missing from this table
// would be a rule `epito run` refuses and `epito validate --for-runtime` passes
// in silence, which is the one way this command could lie — so it is checked at
// import, not in a test that someone has to remember to write.
export const SEVERITY = { name: "error", repo: "note" };
for (const r of ROSTER_RULES) {
  if (!SEVERITY[r]) {
    throw new Error(`src/validate.js: roster rule "${r}" has no severity here, so \`epito validate --for-runtime\` would pass a roster \`epito run\` refuses. Fix: add "${r}" to SEVERITY as "error" or "note".`);
  }
}

const die = (msg) => { console.error(`epito: ${msg}`); process.exit(1); };

// What the ✓ claims about a manifest, in one place, so the single-manifest line
// and the roster's column can never describe the same file differently.
export function shape(m) {
  const n = m.identity.scopes.length;
  const adapter = m.runtime?.adapter;
  return `identity (${n} scope${n > 1 ? "s" : ""}), trigger, runtime${adapter && adapter !== "claude" ? ` — a ${adapter} agent` : ""}`;
}

// One manifest, read and checked, printing nothing — the roster has to have
// seen every seat before it can say "1 of 5 refused", and a shared checker is
// also what keeps the two forms' wording identical.
//
// Readiness is computed only for a manifest that validated: what a refused file
// would be ready for is not a question, and it is the order the single-manifest
// path has always used.
// `as` is how the file is spelled back to the reader. It matters because
// readiness fixes are instructions — "add repo = ... to [runtime] in <as>" —
// and findManifests returns absolute paths, so without this the fix for a seat
// in `agents/okr` named a /tmp path the reader never typed.
export function checkManifest(path, { as = path } = {}) {
  const raw = readFileSync(path, "utf8");
  const { manifest, parseError } = parseManifest(path);
  // Named by the path the reader typed, not by the literal "agent.toml": with
  // no argument those are the same string, and with one they are not.
  if (parseError) return { path, as, parseError, errors: [`${as} is not valid TOML: ${parseError}`], notes: [], blocks: [] };
  const baseDir = dirname(resolve(path));
  const errors = validateManifest(manifest, { raw, baseDir });
  if (errors.length) return { path, as, manifest, errors, notes: [], blocks: [] };
  return { path, as, manifest, errors, notes: unchecked(manifest, { baseDir }), blocks: blockers(manifest, as) };
}

// A roster beside or above the cwd relativises to a ladder of "..", which is
// both harder to read and harder to paste than the path it came from.
const rel = (p) => {
  const r = relative(process.cwd(), p);
  return !r || r.startsWith("..") ? p : r;
};
const plural = (n, word) => `${n} ${word}${n === 1 ? "" : "s"}`;

// ONE manifest. Every line here is the line this command printed before the
// directory form existed; `self` is the only addition, so that the strict-mode
// hint names the path you typed instead of always saying `epito validate`.
function one(path, strict, self) {
  const r = checkManifest(path);
  if (r.parseError) die(`${r.as} is not valid TOML: ${r.parseError}`);
  const name = r.manifest.agent?.name;
  if (r.errors.length) {
    console.error(`${path}: ${plural(r.errors.length, "problem")}\n`);
    for (const e of r.errors) console.error(`  ✗ ${e}`);
    process.exit(1);
  }
  console.log(`✓ ${name} is an agent: ${shape(r.manifest)}`);
  for (const u of r.notes) console.log(`  — ${u}`);
  if (r.blocks.length) {
    const say = strict ? console.error : console.log;
    say(`\n${name} is valid, and not ready to run:\n`);
    for (const b of r.blocks) say(`  ! ${b.problem}.\n    Fix: ${b.fix}.`);
    if (strict) { console.error(`\nepito: --for-runtime asks whether the runtime would accept this manifest, and it would not.`); process.exit(1); }
    say(`\nThis file is a valid ${SPEC_VERSION} manifest either way — run \`${self} --for-runtime\` to make the above an error instead of a note.`);
  }
  process.exit(0);
}

// A WHOLE ROSTER. Collected before anything is printed, because the summary is
// a count and because the stream depends on the verdict: a refused roster goes
// entirely to stderr, so `epito validate agents >/dev/null` in a CI step shows
// exactly the problems and nothing else. That is the same split the
// single-manifest form makes with `say`, applied to the whole report.
async function roster(dirArg, strict, self) {
  const dir = resolve(dirArg);
  if (!existsSync(dir)) die(`no such directory "${dirArg}"`);
  // Sorted by path: deterministic, and it groups the report the way the seats
  // are laid out on disk, which is how an operator reads a roster. A refused
  // manifest may have no [agent].name to sort by at all.
  const paths = findManifests(dir).sort();
  if (!paths.length) {
    die(`no agent.toml found under ${dir} — an empty roster has nothing to validate. Fix: give each seat its own directory under ${dirArg} and run \`epito init <name>\` inside it`);
  }

  const takenBy = new Map();
  const seats = [];
  for (const p of paths) {
    const r = checkManifest(p, { as: rel(p) });
    const extra = rosterRules(r.manifest, { path: p, takenBy })
      .filter((x) => SEVERITY[x.rule] === "error")
      .map((x) => x.message);
    const errors = [...r.errors, ...extra];
    const name = r.manifest?.agent?.name;
    // Only a clean manifest claims its name, so a second copy of an
    // already-refused file is reported on its own problems rather than as a
    // collision with something that is not a seat. loadRoster does the same.
    if (name && !errors.length) takenBy.set(name, rel(p));
    seats.push({ ...r, errors, label: errors.length ? rel(p) : name });
  }

  const bad = seats.filter((s) => s.errors.length);
  const notReady = seats.filter((s) => !s.errors.length && s.blocks.length);
  // The box, asked only when the files are good enough for the answer to
  // change anything. A roster with a refused manifest is refused whatever the
  // engine is doing, and 400ms is 400ms.
  const address = engineAddress();
  const engine = bad.length ? null : await engineAnswering(address);
  // The engine counts toward `refused` so the stream discipline below still
  // holds: `epito validate agents --for-runtime >/dev/null` on a box with no
  // engine shows exactly the problem and nothing else.
  const refused = bad.length > 0 || (strict && (notReady.length > 0 || !engine.ok));
  const out = refused ? console.error : console.log;
  const n = seats.length;
  const noEngine = engine ? engineMissing(engine) : null;

  // "(no engine)" is a statement about what this check REQUIRES, and it is
  // still exact — nothing below needs a server to be true. The engine line in
  // the closing verdict is about what was FOUND on the box. Header: what was
  // needed. Footer: what is there. Do not "fix" one to match the other.
  out(`roster ${rel(dir)} — ${plural(n, "manifest")}, against spec ${SPEC_VERSION} (no engine)\n`);
  // Only the ✓/! rows are padded, so only they set the width — a refused
  // manifest is named by its path, and letting a long path set the column
  // pushed every good seat's description halfway across the terminal.
  const w = Math.max(0, ...seats.filter((s) => !s.errors.length).map((s) => s.label.length));
  for (const s of seats) {
    if (s.errors.length) {
      out(`✗ ${s.label} — ${plural(s.errors.length, "problem")}`);
      for (const e of s.errors) out(`    ✗ ${e}`);
      continue;
    }
    out(`${s.blocks.length ? "!" : "✓"} ${s.label.padEnd(w)}  ${shape(s.manifest)}${s.blocks.length ? " — valid, not ready to run" : ""}`);
    for (const u of s.notes) out(`    — ${u}`);
    for (const b of s.blocks) out(`    ! ${b.problem}.\n      Fix: ${b.fix}.`);
  }
  out("");

  if (bad.length) {
    out(`epito: ${bad.length} of ${plural(n, "manifest")} refused; fix them and start again — a roster runs whole or not at all`);
    if (notReady.length) out(`  ${plural(notReady.length, "other")} ${notReady.length === 1 ? `is a valid ${SPEC_VERSION} manifest that is` : `are valid ${SPEC_VERSION} manifests that are`} not ready to run either — the ! lines say what and how`);
    process.exit(1);
  }
  if (strict && notReady.length) {
    out(`epito: --for-runtime asks whether the runtime would accept this roster, and it would not: ${notReady.length} of ${plural(n, "seat")} ${notReady.length === 1 ? "is" : "are"} not ready to run.`);
    // Both halves at once. An operator with a manifest to fix AND no engine
    // running wants to hear about both before they start, not to fix one and
    // be stopped by the other.
    if (!engine.ok) out(`  There is also no runtime to accept it: ${noEngine}. Fix: ${engineFix(address)}`);
    process.exit(1);
  }

  // The schedule shape, said once the files are known good. An operator about
  // to leave a roster running wants it confirmed that the seat with no
  // [trigger].cron is the seat they meant to leave presence-only — `epito run`
  // says this line too, after it has reached the engine.
  const cronned = seats.filter((s) => s.manifest.trigger?.cron);
  // A seat the bus wakes is not presence-only, and saying it was is the kind
  // of wrong sentence this command exists to not print: `[trigger].
  // subscriptions` is a trigger, so a seat with one and no cron has a way to
  // be woken that this line used to count as none. The clause only appears on
  // a roster that has one, because a note that fires on every roster is noise.
  const subscribed = seats.filter((s) => s.manifest.trigger?.subscriptions?.length);
  const presence = seats.filter((s) => !s.manifest.trigger?.cron && !s.manifest.trigger?.subscriptions?.length).map((s) => s.label);
  const counts = [
    `${cronned.length} on a cron`,
    subscribed.length ? `${subscribed.length} woken by the bus (${subscribed.map((s) => s.label).join(", ")})` : null,
    `${presence.length} presence-only${presence.length ? ` (${presence.join(", ")})` : ""}`,
  ].filter(Boolean);
  out(`✓ ${n} of ${plural(n, "manifest")} ${n === 1 ? "is an agent" : "are agents"}: ${counts.join(", ")}`);
  // What the bus half of that sentence does NOT say, said once rather than
  // per seat: whether any of those subjects can actually reach this box. That
  // is `epito bus`'s question — a stream is a fact about the box, like the
  // engine, and this command answers the manifests' half in full without one.
  if (subscribed.length) out(`  ${subscribed.length === 1 ? "that seat is" : "those seats are"} woken by an event the bus holds, which is a fact about the box and not about these files — \`epito bus ${dirArg}\` says whether this one carries those subjects and what is waiting`);
  if (notReady.length) {
    out(`  ${plural(notReady.length, "seat")} ${notReady.length === 1 ? "is" : "are"} valid and not ready to run — run \`${self} --for-runtime\` to make those an error instead of a note`);
    if (!engine.ok) out(`  and the engine is not up either: ${noEngine}. Fix: ${engineFix(address)}`);
  } else if (engine.ok) {
    // The only sentence here that claims anything about `epito run`, and now
    // the only one that has looked. A TCP connect proves "something accepted a
    // connection", which is why this says the address is answering rather than
    // that Temporal is healthy — `epito run` still does the real connect and
    // the real namespace check, and will still refuse an engine that answers
    // and is the wrong one.
    out(`  every one is ready to run, and ${address} is answering: there is nothing here \`epito run ${dirArg}\` would refuse`);
  } else {
    // The common case on a laptop, and the case the old ✓ got wrong. Two
    // lines, because this is the half that deserves sentences: the files are
    // genuinely fine and the operator is genuinely not ready to run.
    out(`  every manifest is ready; the engine is not: ${noEngine}, so \`epito run ${dirArg}\` refuses before it reads a seat`);
    out(`    Fix: ${engineFix(address)}`);
  }
  if (strict && !engine.ok) {
    out(`\nepito: --for-runtime asks whether the runtime would accept this roster, and there is no runtime: ${noEngine}.`);
    out(`  The manifests are not the problem — \`${self}\` without --for-runtime says so, and that is the question a roster validator can answer with no box.`);
    process.exit(1);
  }
  process.exit(0);
}

export async function validateCmd(args = []) {
  const strict = args.includes("--for-runtime");
  const target = args.find((a) => !a.startsWith("-"));
  if (!target) {
    if (!existsSync("agent.toml")) {
      die("no agent.toml here — run `epito init` first, or name a roster: `epito validate <dir>` checks every manifest under a directory");
    }
    return one("agent.toml", strict, "epito validate");
  }
  if (!existsSync(target)) {
    die(`no such file or directory "${target}" — \`epito validate\` takes a directory of manifests (the whole roster) or one agent.toml, and with no argument reads the one in this directory`);
  }
  const self = `epito validate ${target}`;
  return statSync(target).isDirectory() ? roster(target, strict, self) : one(target, strict, self);
}
