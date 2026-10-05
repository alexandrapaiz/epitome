// Columns and timestamps, in one place because two readers now print them.
//
// `epito board` had these three functions privately; `epito audit` prints the
// same kind of thing (a fold on top, a chronological tail under it) and an
// operator should not have to learn two tables. Extracted unchanged in
// behaviour — board.js imports them from here and its output is byte-identical.
// If a third reader appears, this is where its columns come from too.

// Every row padded to the widest cell in its column. Trailing whitespace is
// trimmed so a terminal's selection does not pick up a column of spaces, and
// so the expected output in a smoke test can be written by hand.
export function table(rows) {
  const w = rows[0].map((_, i) => Math.max(...rows.map((r) => String(r[i]).length)));
  return rows.map((r) => r.map((c, i) => String(c).padEnd(w[i])).join("  ").trimEnd());
}

// Minute precision, UTC, with the T removed: these logs are read by a person
// looking for "when did this happen", and the seconds have never once been
// the answer. Both forms take the raw ISO string and never parse it into a
// Date — a line written by a newer epito, or truncated by a crash, prints as
// whatever it says rather than as "Invalid Date".
export const iso16 = (t) => (t ? String(t).slice(0, 16).replace("T", " ") + "Z" : "-");
export const hhmm = (t) => (t ? String(t).slice(11, 16) + "Z" : "-");
