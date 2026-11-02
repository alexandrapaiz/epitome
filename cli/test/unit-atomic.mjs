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

// The detector, because a repair without one leaves the next pass as exposed
// as this one was. Every write in src/ that replaces a file goes through
// lib/atomic.js; the two appends do not and must not (see the note below).
test("no command in src/ writes a file with a truncating write", () => {
  const files = [];
  const walk = (d) => {
    for (const entry of readdirSync(d, { withFileTypes: true })) {
      const p = join(d, entry.name);
      if (entry.isDirectory()) walk(p);
      else if (entry.name.endsWith(".js")) files.push(p);
    }
  };
  walk(join(CLI, "src"));
  assert.ok(files.length > 40, `expected to have walked src/, found ${files.length} files`);
  const offenders = [];
  for (const f of files) {
    if (f.endsWith("lib/atomic.js")) continue;
    readFileSync(f, "utf8").split("\n").forEach((line, i) => {
      if (/\bwriteFileSync\s*\(/.test(line) || /\bwriteFile\s*\(/.test(line)) {
        offenders.push(`${f.slice(CLI.length + 1)}:${i + 1}`);
      }
    });
  }
  assert.deepEqual(offenders, [],
    "writeFileSync truncates the file before it can fail, so a full device destroys it. " +
    "Fix: writeFileAtomic from src/lib/atomic.js, with what the file is and the fix for the reader.");
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
