// One line in .gitignore, added once and never rewritten. `epito init` and
// `epito deploy` both need it for the same reason: the manifest is publishable
// by design (spec rule 1) and `.epito/` — the App keys, the ledger — is not.
// Deploy needs it on its own account because a repo can arrive at deploy
// without ever having been through init (a manifest written by hand, or one
// that predates the directory), and the first thing deploy does is write a
// private key into that directory.
import { readFileSync, existsSync } from "node:fs";
import { writeFileAtomic } from "./atomic.js";

// Returns true when it wrote the line, false when the file already covered it.
// Never rewrites what is there: an existing .gitignore belongs to the repo, not
// to us.
export function ignore(line, path = ".gitignore") {
  const existing = existsSync(path) ? readFileSync(path, "utf8") : "";
  if (existing.split("\n").some((l) => l.trim() === line || l.trim() === line.replace(/\/$/, ""))) return false;
  const sep = existing === "" || existing.endsWith("\n") ? "" : "\n";
  // Appending a line means rewriting the file, and this is the one file in
  // here that belongs to the repository rather than to epito: a plain write
  // truncates it before it can fail, so a device with no room turns somebody
  // else's .gitignore into an empty file (lib/atomic.js).
  writeFileAtomic(path, `${existing}${sep}${existing ? "" : "# epito: the agent's credentials and run state, never committed\n"}${line}\n`, {
    what: `the repository's own .gitignore, which epito only ever adds "${line}" to`,
  });
  return true;
}
