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
//
// `fatal` is the severity, and it is a property of the TABLE, not of the key
// (spec v0.2, "An unknown key refuses two tables and warns the other two"):
// `[identity]` and `[runtime]` have fields that mean something specific when
// absent, so an unread key beside them changes how a seat runs and nobody is
// told — that is the `max_turn = 50` harm, and it stays a refusal. `[agent]`
// and `[trigger]` separately require every field whose absence changes
// behaviour, so an unknown key there can only be a word nothing reads. The
// list of which table is which lives in manifest.js beside the catalogue; this
// function only knows how to say either sentence.
//
// Both severities name the key, the table and the spec version, and both offer
// the same spelling suggestion: a warning here is not the old silence, which
// printed nothing and handed the author a bare ✓.
export function unknownKeys(table, known, where, { retired = {}, fatal = true } = {}) {
  if (typeof table !== "object" || table === null || Array.isArray(table)) return [];
  const out = [];
  for (const key of Object.keys(table)) {
    if (known.includes(key)) continue;
    // A retired field's own sentence already names where its meaning went, and
    // that sentence is right at either severity — what the table decides is
    // whether hearing it costs the manifest its tick.
    if (retired[key]) { out.push(retired[key]); continue; }
    const guess = nearest(key, known);
    // The head reads the same at either severity: the key, its table, the spec
    // version, and the spelling if one is close. What differs is the clause
    // after it and the fix — a refusal tells you to drop the line, a warning
    // tells you why it is still a ✓ and what the other road is.
    const head = guess
      ? `did you mean ${where}.${guess}?`
      : `a field the spec does not define is one the runtime will never act on.`;
    const why = fatal
      ? ""
      : ` In ${where} that is a warning, not a refusal: ${SPEC_VERSION} separately requires every ${where} field whose absence changes behaviour, so a key nothing reads cannot leave this seat quietly misconfigured.`;
    const fix = guess
      ? `Fix: correct the spelling, or drop the line.`
      : fatal
        ? `Fix: drop the line.`
        : `Fix: drop the line, or raise it as an open question against spec/manifest.md if ${where} should grow the field.`;
    out.push(
      `${where}.${key} is not a field in manifest spec ${SPEC_VERSION}, so nothing reads it — ${head}${why} ${fix}` +
      ` ${SPEC_VERSION}'s ${where} is: ${[...known].sort().join(", ")}.`
    );
  }
  return out;
}
