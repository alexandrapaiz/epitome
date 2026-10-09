// What a frozen spec makes possible: refusing a field the spec does not define.
//
// Until v0.1 froze, five fields arrived "PROPOSED in-band" across six merged
// PRs, and a validator that refused unknown keys would have refused the
// manifest that introduced each one. So the validator ignored everything it
// did not recognise — which also meant `mdoel = "claude-opus-5"` validated
// with a ✓ and then ran the seat on whatever `model` was, and `max_turn = 50`
// validated with a ✓ and then ran 100 turns. A silently ignored field is the
// manifest lying to its author, and it is the failure mode a vibecoder cannot
// debug, because the product told them the file was correct.
//
// The freeze is what earns the right to say no. These helpers are that no.

// The version of spec/manifest.md this build implements, in ONE place because
// a dozen error messages name it and the field list inside them is generated.
// When v0.2 added `base_url_env`, every message that said "v0.1's
// [[runtime.route]] is: ..." would have listed the new field under the old
// version's name — the validator telling a reader to check a spec that does
// not have what it just offered. `cli/test/unit.mjs` asserts this string
// matches the heading of spec/manifest.md, so the two cannot drift.
export const SPEC_VERSION = "v0.2";

// Levenshtein, bounded: we only ever ask "is this within two edits", so the
// full matrix is never interesting and a row pair is enough.
function distance(a, b) {
  if (a === b) return 0;
  let prev = Array.from({ length: b.length + 1 }, (_, i) => i);
  for (let i = 1; i <= a.length; i++) {
    const row = [i];
    for (let j = 1; j <= b.length; j++) {
      row[j] = Math.min(prev[j] + 1, row[j - 1] + 1, prev[j - 1] + (a[i - 1] === b[j - 1] ? 0 : 1));
    }
    prev = row;
  }
  return prev[b.length];
}

// The known field a typo most likely meant, or null. Two edits is the limit
// on purpose: at three, "graph" matches "model" and the suggestion becomes
// noise that sends the reader the wrong way.
export function nearest(key, known) {
  let best = null, bestAt = 3;
  for (const k of known) {
    const d = distance(key.toLowerCase(), k.toLowerCase());
    if (d < bestAt) { best = k; bestAt = d; }
  }
  return best;
}

// Every key in `table` that the current spec does not define, as sentences.
//
// `where` is how the reader finds the line: "[runtime]", "[agent]",
// "[[runtime.route]] #2". `retired` maps a key that WAS in the v0.1 draft to
// the sentence explaining where it went — a field the reader copied from an
// older spec deserves better than "unknown".
export function unknownKeys(table, known, where, retired = {}) {
  if (typeof table !== "object" || table === null || Array.isArray(table)) return [];
  const errors = [];
  for (const key of Object.keys(table)) {
    if (known.includes(key)) continue;
    if (retired[key]) { errors.push(retired[key]); continue; }
    const guess = nearest(key, known);
    errors.push(
      `${where}.${key} is not a field in manifest spec ${SPEC_VERSION}, so nothing reads it — ` +
      (guess
        ? `did you mean ${where}.${guess}? Fix: correct the spelling, or drop the line.`
        : `a field the spec does not define is one the runtime will never act on. Fix: drop the line.`) +
      ` ${SPEC_VERSION}'s ${where} is: ${[...known].sort().join(", ")}.`
    );
  }
  return errors;
}
