// What a systemd EnvironmentFile actually says, and where a shell reading the
// same bytes would disagree.
//
// This module exists because of one outage, and the outage is the whole
// argument for it. This company's resident host ran eighteen hours with its
// daily health post dead. The file the units read (`/srv/asc/env`, written by
// deploy/provision-host.sh) had acquired a value that was a password hash, a
// hash begins with `$`, and the health script's fourth line read that file
// with `set -a; . "$file"`. systemd was never confused -- it reads the file
// literally, so epitod itself ran fine the whole time -- but every shell
// reader of the same file got something else:
//
//   PASSWORD_HASH=$2b$12$KIX...   a shell expands $2 and $12: the value
//                                 silently becomes a shorter wrong string
//   WITH_SPACE=hello world        a shell sets WITH_SPACE=hello and RUNS
//                                 `world`; that is how a fragment of a
//                                 credential reached a log
//   ANY=`cmd` / $(cmd)            a shell runs it, from inside a secrets file
//   under `set -u`                the source itself exits 1, and the unit dies
//
// Three different wrongs, two of them silent. The box's own reader now has
// systemd's rules instead (`/usr/local/lib/epito-envfile.sh`, installed by
// deploy/provision-host.sh), and this is the same parse in the product, so
// `epito env --file <path>` can answer the question nobody could ask before:
// does any line of this file read differently depending on who reads it.
//
// Rule 1 of this product applies to every surface built on this module: a
// value is never printed, logged or returned to a caller that prints. The
// report carries names, byte counts and verdicts. That is also what makes it
// safe to paste the output of `epito env --file` into a pull request, which is
// exactly what somebody will do with it.

// systemd.exec(5), the parts that apply to a file this product writes:
// KEY=value per line; leading whitespace ignored; `#` and `;` begin a comment
// line; one layer of matching single or double quotes is stripped; nothing is
// ever expanded. The trailing-backslash continuation is NOT implemented, here
// or in the shell reader, and that is deliberate and symmetric: `epito env
// --template` never writes one, and a value that needs a newline cannot live
// in this file at all (cli/src/lib/identity.js says the same thing about a
// PEM, which is why the key has a FILE form).
const NAME_OK = /^[A-Za-z_][A-Za-z0-9_]*$/;

export const ASSIGN = "assign";
export const COMMENT = "comment";
export const BLANK = "blank";
export const MALFORMED = "malformed";   // not a comment, not an assignment
export const BAD_NAME = "bad-name";     // an assignment systemd will not take

// A shell sourcing an unquoted value acts on all of these. Grouped by what the
// reader loses, because the fix differs: expansion and substitution need the
// value quoted (single, not double), splitting and metacharacters need it
// quoted or moved out of the file entirely.
const HAZARD = [
  { re: /\$/, says: "a shell expands it", detail: "`$` starts a parameter or command expansion, so the value a shell gets is shorter than the one systemd gets, with no error anywhere" },
  { re: /`|\$\(/, says: "a shell runs it", detail: "a backtick or `$(` is a command substitution: sourcing this file executes whatever is inside it, as the user that sourced it" },
  { re: /[;&|<>()]/, says: "a shell runs the rest of the line", detail: "`;`, `&`, `|`, `<`, `>` and parentheses end an assignment and start a command" },
  { re: /[ \t]/, says: "a shell splits it", detail: "the value stops at the first space and the rest of it is run as a command — this is the shape that puts a fragment of a secret in a log" },
  { re: /\\/, says: "a shell drops characters from it", detail: "a backslash escapes the next character, so the value loses bytes" },
  { re: /['"]/, says: "a shell may swallow the lines after it", detail: "an unbalanced quote inside an unquoted value runs on until the next one, which can be in another name's value" },
];

// Inside double quotes a shell still expands and still substitutes; it just
// stops splitting. Single quotes are the only form where a shell and systemd
// read the same bytes, which is the one thing an operator quoting a file by
// hand needs to be told.
const IN_DOUBLE = new Set(["a shell expands it", "a shell runs it", "a shell drops characters from it"]);

export function shellDivergence(value, quote) {
  if (quote === "'") return [];
  const hits = HAZARD.filter((h) => h.re.test(value));
  return (quote === '"' ? hits.filter((h) => IN_DOUBLE.has(h.says)) : hits).map((h) => ({ says: h.says, detail: h.detail }));
}

export function parseEnvFile(text) {
  const rows = [];
  const lines = String(text).split("\n");
  // A trailing newline makes a last empty element that is not a line of the
  // file; every other empty line is.
  if (lines.length && lines[lines.length - 1] === "") lines.pop();
  for (let i = 0; i < lines.length; i++) {
    const raw = lines[i];
    const at = i + 1;
    const line = raw.replace(/^[ \t]+/, "").replace(/\r$/, "");
    if (line === "") { rows.push({ at, kind: BLANK }); continue; }
    if (line.startsWith("#") || line.startsWith(";")) { rows.push({ at, kind: COMMENT }); continue; }
    const eq = line.indexOf("=");
    if (eq === -1) { rows.push({ at, kind: MALFORMED, text: line.slice(0, 24) }); continue; }
    const name = line.slice(0, eq);
    let value = line.slice(eq + 1);
    let quote = "";
    if (value.length >= 2 && ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'")))) {
      quote = value[0];
      value = value.slice(1, -1);
    }
    if (!NAME_OK.test(name)) { rows.push({ at, kind: BAD_NAME, name }); continue; }
    rows.push({ at, kind: ASSIGN, name, quote, bytes: Buffer.byteLength(value, "utf8"), diverges: shellDivergence(value, quote) });
  }
  return rows;
}

// The report every surface prints from. `names` is in file order with the LAST
// assignment of a repeated name winning, because that is what systemd does
// with a name written twice -- and a name written twice is worth saying out
// loud, since the line an operator edited may not be the line that wins.
export function envFileReport(text) {
  const rows = parseEnvFile(text);
  const assigns = rows.filter((r) => r.kind === ASSIGN);
  const seen = new Map();
  for (const r of assigns) seen.set(r.name, (seen.get(r.name) ?? 0) + 1);
  const winners = [];
  for (const r of assigns) {
    const i = winners.findIndex((w) => w.name === r.name);
    const row = { ...r, times: seen.get(r.name) };
    if (i === -1) winners.push(row); else winners[i] = row;
  }
  return {
    rows,
    names: winners,
    empty: winners.filter((r) => r.bytes === 0),
    diverging: winners.filter((r) => r.diverges.length),
    repeated: winners.filter((r) => r.times > 1),
    malformed: rows.filter((r) => r.kind === MALFORMED),
    badNames: rows.filter((r) => r.kind === BAD_NAME),
  };
}
