// Unknown options are refused by name, never ignored.
//
// Every command in this CLI used to read its flags with `args.includes("--x")`,
// which has one failure mode and it is the expensive one: a flag epito does not
// know is a flag epito does not mention. The three that matter, found running
// the installed package out of the box:
//
//   epito validate --for-runtimes   exit 0, a ✓, and nothing asserted — the
//                                   strict gate someone put in CI, silently off
//   epito token pm --dry-runn       not a dry run: a real mint, on the network,
//                                   against a real App key
//   epito deploy pm --dry-runn      not a dry run: the real App-creation flow,
//                                   browser and all
//
// `epito board` already had this right and said why ("a report filed with a
// misspelled --outcome that silently became 'ok' is worse than one that did not
// file"). The rule was correct and applied to one command out of nine. This
// module is that rule, once, for all of them — board's parseFlags now lives
// here too, so there is one spelling of the refusal and not two.
//
// The message obeys the bar `epito validate` set: name what broke in the
// product's own words, and put the fix in the sentence. A near miss gets named
// as a near miss, because that is what a typo is.

// Levenshtein, capped: only used to decide whether to say "did you mean", so it
// stops counting once the answer is "no, not close".
function distance(a, b) {
  if (Math.abs(a.length - b.length) > 2) return 99;
  const prev = Array.from({ length: b.length + 1 }, (_, i) => i);
  for (let i = 1; i <= a.length; i++) {
    let diag = prev[0];
    prev[0] = i;
    for (let j = 1; j <= b.length; j++) {
      const tmp = prev[j];
      prev[j] = Math.min(prev[j] + 1, prev[j - 1] + 1, diag + (a[i - 1] === b[j - 1] ? 0 : 1));
      diag = tmp;
    }
  }
  return prev[b.length];
}

// The closest known flag, if one is close enough to be worth naming. Two edits
// on a short word is already a different word, so the cap is deliberate.
export function nearest(name, known) {
  let best = null, bestD = 3;
  for (const k of known) {
    const d = distance(name, k);
    if (d < bestD) { best = k; bestD = d; }
  }
  return best;
}

// `does` is what the flag is for, in the help text's words. It is printed when
// there is no near miss, because then the useful thing is the real list.
const spell = (f) => (typeof f === "string" ? { name: f } : f);

export function optionError(cmd, name, known) {
  const specs = known.map(spell);
  const names = specs.map((s) => s.name);
  const did = nearest(name, names);
  const where = `\`epito ${cmd}\``;
  if (did) {
    return `${where} has no --${name} option. Did you mean --${did}? Fix: \`epito ${cmd} --${did}\`.\n`
      + `epito refuses an option it does not know rather than ignoring it: a misspelled flag that is dropped silently does the opposite of what you typed.`;
  }
  if (!specs.length) {
    return `${where} takes no options, so there is nothing --${name} could mean. Fix: drop --${name}.`;
  }
  const list = specs.map((s) => (s.does ? `  --${s.name}  ${s.does}` : `  --${s.name}`)).join("\n");
  return `${where} has no --${name} option. Fix: drop it, or use one it takes:\n${list}`;
}

// Walk a command's argv and return the error string for the first option it
// does not know, or null. Flags declared `value: true` consume the next
// argument, so `--timeout -5` reaches the command's own range check with its
// own message instead of being mistaken for an option here.
export function unknownOption(cmd, argv = [], known = []) {
  const specs = known.map(spell);
  const byName = new Map(specs.map((s) => [s.name, s]));
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (typeof a !== "string" || a === "-" || a === "--" || !a.startsWith("-")) continue;
    const eq = a.indexOf("=");
    const raw = eq === -1 ? a : a.slice(0, eq);
    const name = raw.replace(/^--?/, "");
    const spec = byName.get(name);
    if (!spec) return optionError(cmd, name, known);
    if (spec.value && eq === -1) i++;
  }
  return null;
}

// --flag value, --flag=value, and bare --flag, for the commands whose options
// carry values. Moved here from src/board.js unchanged in behaviour; the
// refusal text is now the shared one.
export function parseFlags(argv, known, cmd = "board") {
  const flags = {};
  const rest = [];
  const names = known.map((k) => spell(k).name);
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (!a.startsWith("--")) { rest.push(a); continue; }
    const eq = a.indexOf("=");
    const name = (eq === -1 ? a.slice(2) : a.slice(2, eq));
    if (!names.includes(name)) return { error: optionError(cmd, name, known) };
    if (eq !== -1) { flags[name] = a.slice(eq + 1); continue; }
    const next = argv[i + 1];
    if (next === undefined || next.startsWith("--")) { flags[name] = true; continue; }
    flags[name] = next; i++;
  }
  return { flags, rest };
}
