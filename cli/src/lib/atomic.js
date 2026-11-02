// Writing a file without destroying the one that is already there.
//
// WHY THIS EXISTS, and it is not a hypothetical. At about 07:30Z on
// 2026-11-02 this box ran out of space while a seat's run was writing a
// tracked file in its own checkout. The write did not fail and leave the file
// alone: it left the file at **zero bytes**. `open(path, "w")` truncates
// before it writes a byte, so by the time the device refuses anything, what
// the write was replacing is already gone. The error that arrives is a real,
// catchable error and it is too late to be any use: there is no handler that
// can put the bytes back.
//
// Reproduced here, on a real filesystem, with the kernel doing the refusing
// (cli/test/unit-atomic.mjs). `ulimit -f 0` makes every write(2) to a regular
// file fail, which is the same shape of refusal as a full device and does not
// need one:
//
//   $ printf 'ORIGINAL 27 BYTES OF CONTENT\n' > victim.txt    # 28 bytes
//   $ (ulimit -f 0; node prog.mjs >/dev/null 2>&1)             # catches EFBIG
//   $ wc -c victim.txt
//   0 victim.txt
//
// One detail from that measurement, because it is why "just handle the error"
// is not a fix: with stdout pointed at a regular file on the same exhausted
// device, the attempt to PRINT the failure is refused too, and that one does
// arrive as a signal — `File size limit exceeded (core dumped)`, nothing
// printed, nothing in the file. A full device can take the report of its own
// fullness with it.
//
// So the fix cannot be a better error message around the write. It has to be
// that the write never touches the file it is replacing: write the bytes to a
// temporary name **in the same directory**, make the device admit it took
// them, and then `rename(2)` over the target. Rename within one directory is
// atomic and needs no new space, so every way this can fail leaves the old
// file exactly as it was. Same directory is not a detail — `rename` across
// filesystems fails EXDEV, and `os.tmpdir()` is a different mount on the box
// this company runs on.
//
// `fsync` before the rename is the other half, and it is the half that is
// easy to leave out: a `write(2)` into page cache can succeed on a device
// that has no room for it, and the ENOSPC then surfaces at close or flush
// time, after the rename has already published a file whose bytes will never
// land. Syncing first means the error arrives while the only thing at risk is
// a temporary file.
import {
  closeSync, fchmodSync, fstatSync, fsyncSync, lstatSync, openSync, realpathSync, renameSync, statSync,
  unlinkSync, writeSync,
} from "node:fs";
import { basename, dirname, join, resolve } from "node:path";
import { randomBytes } from "node:crypto";

// What the device said, in this product's words rather than errno's. The
// mapping is from the real error objects this platform raises, not from the
// manual page: `fs.writeFileSync("/dev/full", "x")` on this box gives
// `ENOSPC: no space left on device, write`, which is where the ENOSPC line
// below comes from.
export function deviceSaid(e, dir) {
  switch (e?.code) {
    case "ENOSPC": return `no space left on the device holding ${dir}`;
    case "EDQUOT": return `this user is over quota on the device holding ${dir}`;
    case "EROFS": return `${dir} is on a read-only filesystem`;
    case "EACCES":
    case "EPERM": return `this user may not write in ${dir}`;
    case "EFBIG": return `the write is larger than this process's file-size limit (ulimit -f)`;
    case "EXDEV": return `${dir} and its own temporary file are on different filesystems, which should be impossible`;
    default: return e?.message ?? String(e);
  }
}

// Thrown rather than printed: every command in this CLI has its own `die` and
// its own vocabulary for what the file was. `code` survives so a caller can
// still branch on ENOSPC.
export class WriteRefused extends Error {
  constructor(message, { code, path, cause } = {}) {
    super(message);
    this.name = "WriteRefused";
    this.code = code;
    this.path = path;
    this.cause = cause;
  }
}

// Returns the path written. `what` is what the file IS to the reader, and
// `fix` is the sentence that gets them out of it; both land in the message a
// caller prints, so the error-message bar is met in one place instead of at
// each of the seven call sites.
export function writeFileAtomic(path, data, { mode, what, fix } = {}) {
  // `rename` replaces a directory entry, so two things that `writeFileSync`
  // does are not free here and both are handled rather than accepted:
  //
  //  - A symlinked target would be REPLACED by a regular file instead of
  //    written through, so a `.gitignore` symlinked into a dotfiles
  //    repository would quietly stop being that file. Resolve it and write
  //    where it points, which is what the plain write did.
  //  - A second hard link to the target keeps the OLD contents, where the
  //    plain write updated every link. Nothing in this CLI writes a file it
  //    expects to be hard-linked, and not destroying the file is worth more
  //    than that; it is named here so the next reader is not surprised.
  let target = path;
  try { if (lstatSync(path).isSymbolicLink()) target = realpathSync(path); }
  catch { /* nothing there, or a dangling link: write the path we were given */ }
  const dir = dirname(target) || ".";
  // The reader has to be able to go and look at the device, and `.` does not
  // say which one — a real refusal printed "no space left on the device
  // holding .." in this repository's own deploy suite, with the dot of the
  // path and the dot of the sentence next to each other. Resolved, so the
  // message names a place.
  const where = resolve(dir);
  // A `rename` publishes the temporary file's mode, where `writeFileSync`
  // would have left an existing file's mode alone. So an existing target's
  // mode is carried across unless the caller names one.
  let before = null;
  try { before = statSync(target); } catch { /* no file there: nothing to preserve, nothing to lose */ }
  const useMode = mode ?? (before ? before.mode & 0o7777 : 0o666);
  const tmp = join(dir, `.${basename(target)}.epito-${process.pid}-${randomBytes(4).toString("hex")}.tmp`);
  let fd = null;
  try {
    // "wx" — never adopt a temporary file somebody else is holding. The mode
    // is set at creation and before any byte is written, which is why a
    // 0600 key is never briefly readable by anybody else: the old `write
    // then chmod` order left exactly that window whenever the target already
    // existed, because writeFileSync's mode is ignored for an existing file.
    fd = openSync(tmp, "wx", useMode);
    // `open`'s mode is masked by the process umask; a mode this code was told
    // to produce, or one it is carrying across from the file it replaces, is
    // not a request. Still before the first byte.
    if (mode !== undefined || before) fchmodSync(fd, useMode);
    const buf = Buffer.isBuffer(data) ? data : Buffer.from(String(data), "utf8");
    let off = 0;
    while (off < buf.length) {
      // A short write is not an error and is not a finished write. Looping is
      // the only way to tell them apart.
      const n = writeSync(fd, buf, off, buf.length - off);
      if (n <= 0) throw new WriteRefused(`${tmp}: the device accepted ${off} of ${buf.length} bytes and then stopped`, { code: "ENOSPC", path });
      off += n;
    }
    // Make the device admit it has the bytes while the only file at risk is
    // this one.
    fsyncSync(fd);
    const wrote = fstatSync(fd).size;
    if (wrote !== buf.length) {
      throw new WriteRefused(`${tmp}: ${wrote} bytes landed of ${buf.length}`, { code: "ENOSPC", path });
    }
    closeSync(fd);
    fd = null;
    renameSync(tmp, target);
    return target;
  } catch (e) {
    if (fd !== null) { try { closeSync(fd); } catch { /* already gone */ } }
    try { unlinkSync(tmp); } catch { /* never created, or already gone */ }
    const kept = before
      ? `${target} is unchanged and still holds its ${before.size} bytes, because epito writes beside a file and renames: a write that runs out of room never truncates what was there.`
      : `Nothing was written and nothing was left behind.`;
    throw new WriteRefused(
      `could not write ${target}${what ? ` — ${what}` : ""}: ${deviceSaid(e, where)}. ${kept}` +
      ` Fix: ${fix ?? `make room on the device holding ${where} and run the command again`}.`,
      { code: e?.code, path, cause: e },
    );
  }
}
