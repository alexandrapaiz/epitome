#!/usr/bin/env node --test
// The env file, read twice: once by this product's parser and once by the
// reader the box itself uses, against the same bytes. Run with:
//
//   node --test test/unit-envfile.mjs        # from cli/
//
// Why two readers and a test that pits them against each other. The file
// `deploy/provision-host.sh` writes is a systemd EnvironmentFile, and systemd
// is not the only thing that reads it: the provision script reads it, the
// daily health unit reads it, and whatever an operator writes next will read
// it. This company's resident host spent eighteen hours with its health post
// dead because those readers were shells and one value was a password hash
// starting with `$`. So there are now exactly two readers in this product —
// `cli/src/lib/envfile.js` here and `/usr/local/lib/epito-envfile.sh` inside
// provision-host.sh — and two readers of one format drift unless something
// makes them agree. That something is the last test in this file: it extracts
// the shell reader out of the provision script, runs it over the same fixture
// this suite parses, and compares name for name.
//
// The fixture carries every shape that broke the host, and the values in it
// are invented: `cli/test/fixtures/` has never held a real credential and this
// adds none (the charter's rule, and the reason this file may print a byte
// count and a checksum of a fixture value at all).
import { test } from "node:test";
import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { mkdtempSync, writeFileSync, readFileSync, existsSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { parseEnvFile, envFileReport, shellDivergence, ASSIGN, COMMENT, BLANK, MALFORMED, BAD_NAME } from "../src/lib/envfile.js";

const HERE = dirname(fileURLToPath(import.meta.url));
const PROVISION = join(HERE, "..", "..", "deploy", "provision-host.sh");
const FIXTURE = join(HERE, "fixtures", "envfile", "box.env");

// --- systemd's rules, as this product implements them ----------------------

test("a plain assignment is a name and a byte count, and nothing is expanded", () => {
  const [row] = parseEnvFile("PASSWORD_HASH=$2b$12$KIXQe1mJ0rZ8wV\n");
  assert.equal(row.kind, ASSIGN);
  assert.equal(row.name, "PASSWORD_HASH");
  // 21 bytes, not the 10 a shell would have left of it: the parse expands
  // nothing, which is the whole point.
  assert.equal(row.bytes, 21);
});

test("comments, semicolon comments, blank lines and leading whitespace, as systemd takes them", () => {
  const rows = parseEnvFile("# a note\n; also a note\n\n   INDENTED=yes\n");
  assert.deepEqual(rows.map((r) => r.kind), [COMMENT, COMMENT, BLANK, ASSIGN]);
  assert.equal(rows[3].name, "INDENTED");
});

test("one layer of matching quotes comes off — the form a requoted file arrives in", () => {
  const rows = parseEnvFile(`A="double"\nB='single'\nC="unmatched\nD=he said "hi"\n`);
  assert.deepEqual(rows.map((r) => r.bytes), [6, 6, 10, 12]);
  assert.deepEqual(rows.map((r) => r.quote), ['"', "'", "", ""]);
});

test("a name no shell and no unit can hold is named as that, not parsed as an assignment", () => {
  const rows = parseEnvFile("9BAD=x\nnot-a-name=x\nGOOD_1=x\n");
  assert.deepEqual(rows.map((r) => r.kind), [BAD_NAME, BAD_NAME, ASSIGN]);
});

test("a line that is neither a comment nor an assignment is malformed, not ignored in silence", () => {
  const rows = parseEnvFile("GH_TOKEN\n");
  assert.equal(rows[0].kind, MALFORMED);
  assert.equal(rows[0].at, 1);
});

test("a last line with no newline is still a line", () => {
  const rows = parseEnvFile("A=1\nB=2");
  assert.equal(rows.length, 2);
  assert.equal(rows[1].name, "B");
});

test("a trailing newline does not invent an empty line at the end", () => {
  assert.equal(parseEnvFile("A=1\n").length, 1);
  assert.equal(parseEnvFile("A=1\n\n").length, 2);
});

test("a name assigned twice: systemd takes the last, and the report says how many times", () => {
  const r = envFileReport("GH_TOKEN=one\nGH_TOKEN=twotwo\n");
  assert.equal(r.names.length, 1);
  assert.equal(r.names[0].bytes, 6);
  assert.equal(r.names[0].at, 2);
  assert.deepEqual(r.repeated.map((x) => x.name), ["GH_TOKEN"]);
});

// --- where a shell disagrees, and where it does not ------------------------

test("every shape that broke the resident host is named, by what the shell does to it", () => {
  const says = (v, q = "") => shellDivergence(v, q).map((d) => d.says);
  assert.deepEqual(says("$2b$12$KIX"), ["a shell expands it"]);
  assert.deepEqual(says("hello world"), ["a shell splits it"]);
  assert.deepEqual(says("`id`"), ["a shell runs it"]);
  assert.ok(says("$(id)").includes("a shell runs it"));
  assert.ok(says("a;rm -rf /").includes("a shell runs the rest of the line"));
  assert.deepEqual(says("back\\slash"), ["a shell drops characters from it"]);
  assert.deepEqual(says("it's"), ["a shell may swallow the lines after it"]);
});

test("an ordinary secret is not flagged: a token, a hostport, a URL, a hash-in-the-middle", () => {
  for (const v of ["gho_16C7e42F292c6912E7710c838347Ae178B4a", "127.0.0.1:7233", "https://hooks.slack.com/services/T/B/x", "value#notacomment", "a-b_c.d/e+f=g"]) {
    assert.deepEqual(shellDivergence(v, ""), [], v);
  }
});

test("single quotes are the only quoting a shell and systemd read alike", () => {
  // The distinction an operator quoting a file by hand has to be told: inside
  // double quotes a shell still expands and still substitutes.
  assert.deepEqual(shellDivergence("$2b$12$KIX", "'"), []);
  assert.deepEqual(shellDivergence("hello world", '"'), []);
  assert.deepEqual(shellDivergence("$2b$12$KIX", '"').map((d) => d.says), ["a shell expands it"]);
  assert.deepEqual(shellDivergence("`id`", '"').map((d) => d.says), ["a shell runs it"]);
});

test("the report separates what is wrong from what is merely absent", () => {
  const r = envFileReport(readFileSync(FIXTURE, "utf8"));
  assert.deepEqual(r.diverging.map((x) => x.name), ["PASSWORD_HASH", "WITH_SPACE", "BACKTICK", "SUBST"]);
  assert.deepEqual(r.empty.map((x) => x.name), ["EMPTY"]);
  assert.deepEqual(r.badNames.map((x) => x.name), ["9BAD", "not-a-name"]);
  assert.deepEqual(r.malformed.map((x) => x.at), [21]);
});

test("no value ever leaves the parse", () => {
  // Rule 1 of this product, pinned: the file holds secrets, and every surface
  // built on this module prints its output somewhere — a pull request body,
  // a provisioning log, a board report. A `value` field here is how a
  // credential ends up in one.
  const json = JSON.stringify(envFileReport(readFileSync(FIXTURE, "utf8")));
  assert.equal(json.includes("hello world"), false);
  assert.equal(json.includes("KIXQe1mJ0rZ8wV"), false);
  for (const row of parseEnvFile(readFileSync(FIXTURE, "utf8"))) {
    assert.equal(Object.hasOwn(row, "value"), false, `row at line ${row.at} carries a value`);
  }
});

// --- the two readers, against the same bytes -------------------------------

// What the shell reader got, as `name bytes checksum` lines -- never values:
// the shell has them, this process never does. `cksum` is POSIX and on every
// box these suites run on. Takes the reader and the fixture as arguments so
// nothing in it is interpolated from JavaScript.
const PROBE = String.raw`#!/usr/bin/env bash
set -u
. "$1"
load_env_file "$2"
for n in $(sed -n 's/^[ \t]*\([A-Za-z_][A-Za-z0-9_]*\)=.*/\1/p' "$2" | sort -u); do
  set +u
  eval "v=\${$n-__UNSET__}"
  set -u
  if [ "$v" = __UNSET__ ]; then
    echo "$n unset"
  else
    echo "$n $(printf '%s' "$v" | wc -c | tr -d ' ') $(printf '%s' "$v" | cksum | cut -d' ' -f1)"
  fi
done
`;

test("the shell reader the box installs reads this file exactly as this parser does", (t) => {
  // The anti-drift assertion. It extracts the reader out of the provision
  // script rather than keeping a copy here, because a copy is the drift.
  if (!existsSync(PROVISION)) return t.skip(`SKIPPED — ${PROVISION} is not in this checkout, so there is no shell reader to compare against`);
  const script = readFileSync(PROVISION, "utf8");
  const m = script.match(/cat > \/usr\/local\/lib\/epito-envfile\.sh <<'ENVLIB'\n([\s\S]*?)\nENVLIB\n/);
  assert.ok(m, "deploy/provision-host.sh no longer installs /usr/local/lib/epito-envfile.sh under that heredoc — if the reader moved, this test has to be pointed at where it went, because the two readers agreeing is the only thing keeping them the same");
  const dir = mkdtempSync(join(tmpdir(), "epito-envfile-"));
  const lib = join(dir, "epito-envfile.sh");
  writeFileSync(lib, m[1]);

  // What the shell reader got, as name/bytes/checksum lines. Not the values:
  // the shell has them, this process never does. `cksum` is in POSIX and on
  // every box these suites run on.
  // The probe is a file, not a JS template literal: every `$` in it is the
  // shell's, and a template literal is the one place those two meanings of
  // `${` collide.
  const probe = join(dir, "probe.sh");
  writeFileSync(probe, PROBE);

  const out = execFileSync("bash", [probe, lib, FIXTURE], { encoding: "utf8" });
  const shell = new Map(out.trim().split("\n").map((l) => { const [n, bytes, sum] = l.split(" "); return [n, { bytes, sum }]; }));

  const report = envFileReport(readFileSync(FIXTURE, "utf8"));
  for (const row of report.names) {
    const got = shell.get(row.name);
    assert.ok(got, `${row.name} is a name this parser found and the shell reader did not export`);
    assert.equal(Number(got.bytes), row.bytes, `${row.name}: the shell reader got ${got.bytes} bytes, this parser says ${row.bytes}`);
  }
  // And the other direction: a name the shell exported that the parser did not
  // find would be just as much a drift.
  for (const [name, got] of shell) {
    if (got.bytes === undefined) continue;  // 'unset' — the bad-name lines
    assert.ok(report.names.some((r) => r.name === name), `the shell reader exported ${name}, which this parser did not report`);
  }
  // The names neither reader may take, taken by neither.
  for (const bad of report.badNames) assert.equal(shell.get(bad.name)?.bytes, undefined, `${bad.name} must reach no reader`);
  assert.equal(shell.size > 0, true);
});
