#!/usr/bin/env node --test
// The write that must not destroy what it is replacing. Run with:
//
//   node --test test/unit-atomic.mjs      # from cli/
//
// Every refusal in here is the kernel's own, on this filesystem. There is no
// stub for a full disk in this file, because the fault being fixed is one the
// kernel delivers and a stub would be a description of it:
//
//   RLIMIT_FSIZE 0 (`ulimit -f 0`) — a real write(2) refused on a real file,
//                 the same shape of refusal as a full device without needing
//                 one. This is the FAULT's reproduction, and the thing it
//                 shows is the ORDER: the error is catchable and it arrives
//                 after the file is already at zero bytes, so no handler
//                 could have saved it. Only not truncating it saves it.
//   /dev/full   — a real ENOSPC error object from this box, fed to the
//                 message mapping rather than a hand-written one. This is
//                 the fixture, copied: `ENOSPC: no space left on device,
//                 write`, syscall `write`, errno -28.
//   mode 0500 directory — a real EACCES through the whole failure path,
//                 which is how the composed message is asserted.
import { test, after } from "node:test";
import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import {
  chmodSync, mkdtempSync, mkdirSync, readFileSync, readdirSync, rmSync, statSync,
  symlinkSync, writeFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { writeFileAtomic, WriteRefused, deviceSaid } from "../src/lib/atomic.js";

const CLI = dirname(dirname(fileURLToPath(import.meta.url)));

// Every directory this suite makes is removed at the end whether its test
// passed, failed or threw. The first draft removed them at the end of each
// test body, which is the one place that does not run when an assertion
// fails, and ten of them were still on a box at 100% full an hour later —
// which is the same class of fault as everything else in this file.
const made = [];
const work = () => {
  const d = mkdtempSync(join(tmpdir(), "epito-atomic-"));
  made.push(d);
  return d;
};
after(() => {
  for (const d of made) {
    // A test that closed a directory to write in it has to reopen it, or the
    // removal is refused for the same reason the write was.
    try { chmodSync(d, 0o700); } catch { /* already gone */ }
    for (const sub of ["closed"]) { try { chmodSync(join(d, sub), 0o700); } catch { /* not every test makes one */ } }
    rmSync(d, { recursive: true, force: true });
  }
});
const ORIGINAL = "IMPORTANT ORIGINAL CONTENT\n";

// Runs one line of node under RLIMIT_FSIZE 0, where every write(2) to a
// regular file is refused. Returns what the shell said and what the file
// holds afterwards, which is the only thing being asserted.
function underNoRoom(dir, body) {
  // The program goes to a file BEFORE the limit is set, because writing it
  // afterwards is the very thing the limit forbids.
  const prog = join(dir, "prog.mjs");
  writeFileSync(prog, body);
  let out = "";
  try {
    out = execFileSync("/bin/bash", ["-c", `ulimit -f 0; exec node ${JSON.stringify(prog)}`], {
      cwd: dir, encoding: "utf8", stdio: ["ignore", "pipe", "pipe"],
    });
    out += "signal=- status=0";
  } catch (e) {
    out = `${e.stdout ?? ""}${e.stderr ?? ""}signal=${e.signal ?? "-"} status=${e.status ?? "-"}`;
  }
  rmSync(prog, { force: true });
  return out;
}

test("the fault: a plain write refused by the kernel leaves the file at zero bytes", () => {
  const dir = work();
  const victim = join(dir, "victim.txt");
  writeFileSync(victim, ORIGINAL);
  assert.equal(statSync(victim).size, 27);

  const said = underNoRoom(dir, `
    import { writeFileSync } from "node:fs";
    try { writeFileSync("victim.txt", "replacement that cannot fit"); }
    catch (e) { console.log("CAUGHT", e.code); }
  `);

  // The file is gone, not unchanged. This is the fault, and it is the state a
  // seat's own checkout was found in on this box at about 07:30Z 2026-11-02.
  assert.equal(statSync(victim).size, 0, "a plain write that cannot finish truncates first");
  // The error itself was perfectly catchable. That is the point: it is
  // delivered after the truncation, so catching it buys a message and not a
  // file. Nothing in a handler can undo the line above.
  assert.match(said, /CAUGHT (EFBIG|ENOSPC)/, `expected the write to be refused, got: ${said}`);
  rmSync(dir, { recursive: true, force: true });
});

test("the fix: the same refusal, through writeFileAtomic, leaves the file exactly as it was", () => {
  const dir = work();
  const victim = join(dir, "victim.txt");
  writeFileSync(victim, ORIGINAL);

  const said = underNoRoom(dir, `
    import { writeFileAtomic } from "${join(CLI, "src/lib/atomic.js")}";
    try { writeFileAtomic("victim.txt", "replacement that cannot fit"); }
    catch (e) { console.log("REFUSED", e.name, e.code, e.message); }
  `);

  assert.equal(readFileSync(victim, "utf8"), ORIGINAL, "the file it was replacing survived");
  // Either outcome is correct here and both are the same success: the write
  // is refused with a sentence, or the kernel kills the process before it can
  // print one. What may never happen is the file being damaged either way.
  assert.ok(/REFUSED WriteRefused/.test(said) || /signal=SIGXFSZ/.test(said), `unexpected ending: ${said}`);
  // Nothing of ours left behind in the directory either way.
  assert.deepEqual(readdirSync(dir), ["victim.txt"], "the temporary file was cleaned up");
  rmSync(dir, { recursive: true, force: true });
});

test("the fix holds for .gitignore, which is the repository's file and not epito's", () => {
  const dir = work();
  const theirs = "node_modules/\ndist/\n";
  writeFileSync(join(dir, ".gitignore"), theirs);

  underNoRoom(dir, `
    import { ignore } from "${join(CLI, "src/lib/gitignore.js")}";
    try { ignore(".epito/"); } catch (e) { console.log("REFUSED", e.code); }
  `);

  assert.equal(readFileSync(join(dir, ".gitignore"), "utf8"), theirs,
    "a full device must not empty somebody else's .gitignore");
  rmSync(dir, { recursive: true, force: true });
});

test("the whole failure path, with a real EACCES: the message names the file, the device, what survived, and the fix", () => {
  const dir = work();
  const inner = join(dir, "closed");
  mkdirSync(inner);
  const path = join(inner, "principals.json");
  writeFileSync(path, ORIGINAL);
  chmodSync(inner, 0o500);
  try {
    assert.throws(
      () => writeFileAtomic(path, "{}\n", {
        what: "the record of which App is which agent",
        retry: "run this deploy again",
      }),
      (e) => {
        assert.ok(e instanceof WriteRefused);
        assert.equal(e.code, "EACCES");
        assert.match(e.message, /could not write .*principals\.json — the record of which App is which agent/);
        assert.match(e.message, /this user may not write in /);
        assert.match(e.message, /is unchanged and still holds its 27 bytes/);
        // The remedy has to match the cause. An earlier draft let the caller
        // supply the whole Fix clause, and this directory — which this user
        // simply may not write in — was answered with "make room".
        assert.match(e.message, /Fix: make .*\/closed writable by this user, then run this deploy again\.$/);
        assert.doesNotMatch(e.message, /make room/);
        return true;
      },
    );
    assert.equal(readFileSync(path, "utf8"), ORIGINAL);
    assert.deepEqual(readdirSync(inner), ["principals.json"]);
  } finally {
    chmodSync(inner, 0o700);
    rmSync(dir, { recursive: true, force: true });
  }
});

test("each cause gets its own remedy, because a wrong fix is worse than none", () => {
  const dir = work();
  const full = join(dir, "full");
  mkdirSync(full);
  const path = join(full, "principals.json");
  writeFileSync(path, "{}\n");
  // A real ENOSPC cannot be staged in a unit test without a full device, so
  // the mapping is driven through the one cause this box can produce on
  // demand and the rest are asserted on the real error objects' codes
  // (see the /dev/full test below for where the ENOSPC wording comes from).
  chmodSync(full, 0o500);
  try {
    const e = (() => { try { writeFileAtomic(path, "x", { retry: "run it again" }); } catch (err) { return err; } })();
    assert.equal(e.code, "EACCES");
    assert.match(e.message, /this user may not write in/);
    assert.match(e.message, /Fix: make .* writable by this user, then run it again\./);
  } finally {
    chmodSync(full, 0o700);
  }
});

test("a file that was never there says so, rather than claiming something survived", () => {
  const dir = work();
  const inner = join(dir, "closed");
  mkdirSync(inner, { mode: 0o500 });
  try {
    assert.throws(() => writeFileAtomic(join(inner, "new.json"), "{}\n"), (e) => {
      assert.match(e.message, /Nothing was written and nothing was left behind\./);
      assert.doesNotMatch(e.message, /unchanged/);
      return true;
    });
  } finally {
    chmodSync(inner, 0o700);
    rmSync(dir, { recursive: true, force: true });
  }
});

// The fixture, copied from this platform rather than quoted from a manual
// page: the error object `writeFileSync("/dev/full", "x")` actually raises
// here. If this box has no /dev/full the test says it did not run.
test("the device's own ENOSPC error, read off /dev/full, maps to the sentence a reader gets", (t) => {
  let real = null;
  try { writeFileSync("/dev/full", "x"); }
  catch (e) { real = e; }
  if (!real) return t.skip("no /dev/full on this box, so there is no real ENOSPC to read");
  assert.equal(real.code, "ENOSPC");
  assert.equal(real.message, "ENOSPC: no space left on device, write");
  assert.equal(real.syscall, "write");
  assert.equal(deviceSaid(real, "/srv/x/.epito"), "no space left on the device holding /srv/x/.epito");
});

test("a mode the caller names is the published mode, and an existing file's mode is carried across", () => {
  const dir = work();
  // The case writeFileSync could not do: the target already exists and is
  // world-readable, and the new contents are a private key.
  const key = join(dir, "agent.pem");
  writeFileSync(key, "old key\n", { mode: 0o644 });
  writeFileAtomic(key, "new key\n", { mode: 0o600 });
  assert.equal(statSync(key).mode & 0o777, 0o600, "the mode is not a second step any more");
  assert.equal(readFileSync(key, "utf8"), "new key\n");

  // And a file epito does not own keeps the mode it had.
  const theirs = join(dir, ".gitignore");
  writeFileSync(theirs, "dist/\n", { mode: 0o664 });
  // Read the mode the umask actually left, rather than the one asked for:
  // what is being asserted is that the rename does not change it.
  const was = statSync(theirs).mode & 0o7777;
  writeFileAtomic(theirs, "dist/\n.epito/\n");
  assert.equal(statSync(theirs).mode & 0o7777, was);
  rmSync(dir, { recursive: true, force: true });
});

test("a symlinked target is written through, not replaced", () => {
  const dir = work();
  const realFile = join(dir, "real.gitignore");
  writeFileSync(realFile, "dist/\n");
  const link = join(dir, ".gitignore");
  symlinkSync(realFile, link);
  writeFileAtomic(link, "dist/\n.epito/\n");
  assert.equal(readFileSync(realFile, "utf8"), "dist/\n.epito/\n", "the file the link points at was updated");
  assert.ok(statSync(link).isFile());
  assert.equal(readFileSync(link, "utf8"), "dist/\n.epito/\n", "and it is still a link to it");
  rmSync(dir, { recursive: true, force: true });
});

// ===========================================================================
// THE GUARD, and why it looks at the whole repository rather than at cli/src.
//
// The first atomic write this product ever had was reachable through exactly
// one call site — `writeState` in lib/audit.js, 2026-09-20 to 2026-09-26 —
// and it was deleted along with the state.json it protected. Seven truncating
// writes then accumulated over the 37 days after, with nothing in the
// repository able to notice. A guard scoped to the directory those writes
// happen to sit in today dies the same death: one new directory, one `git mv`,
// and it is watching an empty room while reading green.
//
// So the candidates are discovered off this repository's own tracked file set,
// which is what ADR-27 settles and what the other scan gate here already does
// — tools/scan-secret-print.sh, whose hand-written glob list was found two
// surfaces short of the trunk on the day it was written, and which had never
// looked at cli/src at all. The guard below asks `git ls-files` what this
// product is made of, and decides what is a candidate from the SHAPE of each
// path rather than from a list of the directories that exist this morning.
const ROOT = dirname(CLI);

// The languages this product executes. Each one has its own fix for the same
// fault: writeFileAtomic here, `tempfile` + `os.replace` in python, a write
// beside the file and `mv` in shell.
const LANGUAGE = { ".js": "js", ".mjs": "js", ".cjs": "js", ".py": "py", ".sh": "sh", ".bash": "sh" };
const languageOf = (p) => LANGUAGE[(p.match(/\.[^./]+$/) ?? [""])[0]];

// A test, a stub or a fixture rehearses this product rather than running as
// it, and its writes land in a directory mkdtemp made two lines earlier, so a
// refusal there has nothing to destroy. The 83 of those in cli/test are a
// different and already measured card (docs/backlog.md, Next: a suite whose
// fixtures cannot be written is unrun, not failed). Recognised by the shape of
// the path, so a suite in a directory nobody has made yet is excluded on the
// same rule, and a product file is never excluded merely for sitting near one.
const rehearsal = (p) => {
  const segs = p.split("/");
  return segs.some((s) => s === "test" || s === "tests" || s === "__tests__" || s === "fixtures")
    || /^(?:test|smoke|unit)[-_.]/.test(segs.at(-1))
    || /(?:\.test\.[cm]?js|_test\.py)$/.test(p);
};

const isProductCode = (p) => Boolean(languageOf(p)) && !rehearsal(p);

const trackedFiles = () => {
  try {
    return execFileSync("git", ["-C", ROOT, "ls-files", "-z"], { encoding: "utf8", maxBuffer: 1 << 26 })
      .split("\0").filter(Boolean);
  } catch (e) {
    assert.fail("could not look: this guard's candidates are the repository's own tracked files, read with "
      + `\`git ls-files\`, and that could not run here (${e.code ?? e.message}). A guard that cannot see what `
      + "it is guarding must not report green. Fix: run this suite inside the epito git checkout.");
  }
};

// This repository's own tree, named by its tracked top-level directories and
// never by a list typed here.
const repoDirs = (files) => [...new Set(files.filter((p) => p.includes("/")).map((p) => p.split("/")[0]))]
  .sort().map((d) => d.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")).join("|");

// What a truncating write looks like in each language, and nothing wider. A
// bare `>` matcher over the 28 shell files below reports 322 lines, and
// almost none of them are writes: `if len(para) > widest:` inside an embedded
// python heredoc, a usage block's `--domain <fqdn>`, a provisioner's `cat >`
// into /etc on a machine it is building from nothing. A gate with 322
// accepted entries is a gate nobody reads, so the shell matcher asks instead
// where the bytes LAND — inside this repository's own tree or outside it —
// and reads the answer set off `git ls-files` as well. It therefore does not
// see a write into a path a variable this file cannot resolve holds, which is
// the hole in it and is named here rather than left to be discovered.
const matcherFor = (lang, src, dirs) => {
  if (lang === "js") {
    return /\b(?:writeFileSync|writeFile|createWriteStream)\s*\(|\bopenSync\s*\([^)]*["'](?:w|w\+|wx|wx\+)["']/;
  }
  if (lang === "py") return /\bopen\s*\([^)]*["'][wx]|\.write_text\s*\(|\.writelines\s*\(/;
  // `$ROOT/docs/...` counts as much as `docs/...`, and the variable's name is
  // read out of the file rather than guessed at: every instrument here reaches
  // the repository root through `git rev-parse --show-toplevel`, most by
  // cd-ing to it and a few by assigning it first.
  const vars = [...src.matchAll(/(\w+)=\s*"?\$\(\s*git rev-parse --show-toplevel/g)].map((m) => m[1]);
  const root = vars.length ? `(?:${vars.map((v) => `\\$\\{?${v}\\}?/`).join("|")})?` : "";
  return new RegExp(`(?:(?:^|[^<>\\d&])>|\\btee\\s+(?:-a\\s+)?)\\s*"?${root}(?:${dirs})/`);
};

// A line whose first non-blank character opens a comment is prose about code,
// and this repository's code is mostly prose: lib/atomic.js writes
// `writeFileSync(` four times explaining why it does not call it. Only whole
// -line comments are dropped and never a trailing one, because stripping from
// the first `//` on a line would hide `writeFileSync(p, "http://host")`.
const isProse = (line) => /^\s*(?:\/\/|#|\*)/.test(line);

const scan = (path, src, dirs) => {
  const re = matcherFor(languageOf(path), src, dirs);
  const hits = [];
  src.split("\n").forEach((line, i) => {
    if (!isProse(line) && re.test(line)) hits.push({ path, line: i + 1, text: line.trim() });
  });
  return hits;
};

// Accepted, each with the reason it is not the fault. Matched on the text of
// the line rather than its number, and the test after the scan fails if one of
// these stops matching anything — an acceptance that nobody can see expire is
// how a baseline turns into a rubber stamp.
const ACCEPTED = [
  {
    path: "cli/src/lib/atomic.js",
    text: /openSync\(tmp, "wx"/,
    why: "this is the fix. It is the one place in the product that opens a file for writing, and what it "
       + "opens is a temporary name beside the target — with `wx`, so it will not truncate even that",
  },
  {
    path: "docs/agents/recovered.py",
    text: /open\(path, "w"\)/,
    why: "the instrument's own --self-test, writing a log file it invented into a directory "
       + "`tempfile.mkdtemp()` made six lines earlier: the write replaces nothing, so a refusal there has "
       + "nothing to destroy",
  },
];

const THE_RULE = "A write that replaces a file truncates it before it can fail, so a device with no room "
  + "left destroys the file instead of refusing the write. Fix, by language: in js, writeFileAtomic from "
  + "cli/src/lib/atomic.js, with what the file is and the remedy for the reader; in python, write a "
  + "temporary file in the same directory and os.replace it; in shell, redirect beside the file and mv. If "
  + "the line is not a replacement — a brand-new file in a scratch directory, or this module itself — add "
  + "it to ACCEPTED in this file with the reason, which is read in review.";

test("the guard's candidates are the repository's own tracked files, not a list of today's directories", () => {
  const product = trackedFiles().filter(isProductCode);
  assert.ok(product.length > 80, `expected the whole product's own code, found ${product.length} files`);
  const outside = product.filter((p) => !p.startsWith("cli/src/"));
  assert.ok(outside.length >= 30,
    "every truncating write this product has today is in cli/src, which is the whole reason the guard must "
    + `not be scoped there (ADR-27). Candidates outside cli/src: ${outside.length}`);
  for (const dir of ["cli/adapters", "docs/agents", "tools", "deploy"]) {
    assert.ok(product.some((p) => p.startsWith(`${dir}/`)),
      `${dir}/ holds tracked code this product executes, and the guard is not looking at it`);
  }
});

test("a directory this product does not have yet is in scope the day somebody adds it", () => {
  for (const p of ["epitod/src/server.js", "worker/handler.mjs", "tools/ledger.py", "deploy/rollout.sh"]) {
    assert.ok(isProductCode(p), `${p} would be this product's own code and the guard would not look at it`);
  }
  for (const p of ["docs/standards/lessons.md", "spec/manifest.md", "company.yaml", "cli/test/unit.mjs",
    "cli/test/fixtures/langgraph-stub/src/agent.py", "deploy/test-provision.sh", "tools/tests/test-wiring.py"]) {
    assert.ok(!isProductCode(p), `${p} describes or rehearses this product; it is not a candidate`);
  }
});

test("nothing this product executes replaces a file with a truncating write", () => {
  const files = trackedFiles();
  const dirs = repoDirs(files);
  const offenders = [];
  for (const p of files.filter(isProductCode)) {
    for (const hit of scan(p, readFileSync(join(ROOT, p), "utf8"), dirs)) {
      if (ACCEPTED.some((a) => a.path === hit.path && a.text.test(hit.text))) continue;
      offenders.push(`${hit.path}:${hit.line}: ${hit.text}`);
    }
  }
  assert.deepEqual(offenders, [], THE_RULE);
});

test("every accepted exception still names a line that is there", () => {
  const dirs = repoDirs(trackedFiles());
  for (const a of ACCEPTED) {
    const hits = scan(a.path, readFileSync(join(ROOT, a.path), "utf8"), dirs);
    assert.ok(hits.some((h) => a.text.test(h.text)),
      `${a.path} no longer holds the write this file accepts (${a.text}), so the acceptance is stale and `
      + `the reason beside it is no longer true of anything: "${a.why}". Fix: remove the entry.`);
  }
});

// The negative control, because a scan that finds nothing is otherwise
// indistinguishable from a scan that looks at nothing (L77). Each planted
// line is the shape of a write that would really destroy a file, in a path
// that does not exist in this repository today.
test("the guard sees a planted truncating write in each language it covers", () => {
  const dirs = repoDirs(trackedFiles());
  const planted = [
    ["cli/src/lib/roster.js", 'writeFileSync(target, bytes);'],
    ["epitod/src/server.mjs", 'createWriteStream("/srv/asc/state.json");'],
    ["cli/adapters/shim.js", 'const fd = openSync(target, "w", 0o600);'],
    ["tools/ledger.py", 'with open(ledger, "w") as fh:'],
    ["tools/ledger.py", 'Path(ledger).write_text(rows)'],
    ["docs/agents/pending.sh", 'printf "%s\\n" "$row" > docs/agents/pending.md'],
    ["docs/agents/pending.sh", 'ROOT=$(git rev-parse --show-toplevel)\ncat > "$ROOT/docs/agents/pending.md" <<EOF'],
    ["docs/agents/pending.sh", 'printf "%s\\n" "$rows" | tee docs/agents/pending.md'],
  ];
  for (const [p, src] of planted) {
    assert.ok(scan(p, src, dirs).length >= 1,
      `the guard would not have seen this write in ${p}: ${src.split("\n").at(-1)}`);
  }
  // And does not see these, each one a real line out of this repository with
  // the path it came from, because a gate that cries at 322 lines is a gate
  // whose accepted list becomes a rubber stamp.
  const quiet = [
    ["docs/agents/addressed.sh:487", "        if len(para) > widest:"],
    ["deploy/provision-host.sh:49", "  --domain <fqdn>      hostname Caddy serves the ingress on (TLS via ACME)"],
    ["docs/agents/addressed.sh:825", "  cat > \"$tmp/prompts/fixture-agent.md\" <<'MD'"],
    ["deploy/provision-host.sh:488", "cat > /etc/systemd/system/epitod.service <<UNIT"],
    ["cli/src/lib/board.js:99", "  appendFileSync(path, JSON.stringify(event) + \"\\n\");"],
    ["cli/src/lib/atomic.js:53", "// manual page: `fs.writeFileSync(\"/dev/full\", \"x\")` on this box gives"],
    ["tools/check-secret-print.py:1", "    with open(path) as fh:"],
  ];
  for (const [where, line] of quiet) {
    const p = where.split(":")[0];
    assert.equal(scan(p, line, dirs).length, 0, `the guard cried at ${where}, which is not a write: ${line}`);
  }
});

// Why the two appends are NOT converted, asserted rather than claimed. A
// torn last line is what an interrupted append leaves, and both readers of
// the ledger already count such a line instead of dying on it — which is the
// right shape for an append-only record and the wrong shape for a replace.
test("the ledger's reader survives the half-written line an interrupted append leaves", async () => {
  const { readJsonl } = await import("../src/lib/audit.js");
  const dir = work();
  const path = join(dir, "audit.jsonl");
  writeFileSync(path, '{"ts":"2026-11-02T07:30:00.000Z","action":"agent.minted"}\n{"ts":"2026-11-02T07:30:01.000Z","action":"trunca');
  const { entries, unreadable } = readJsonl(path);
  assert.equal(entries.length, 1);
  assert.equal(unreadable, 1, "the torn line is counted, not dropped and not fatal");
  rmSync(dir, { recursive: true, force: true });
});
