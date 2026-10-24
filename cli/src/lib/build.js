// Which epito is actually running here.
//
// The runtime is a resident process started once from a checkout on a box, and
// nothing about a run says which revision of this source produced it. That is
// the gap this closes, and it is not hypothetical: on 2026-10-18 the host's
// checkout of this repository was still at the merge of PR #6 (2026-09-20) and
// carried 35 lines of uncommitted hand-patches, so four weeks of merged runtime
// fixes were not running and every surface that could have said so said nothing
// — the run logs, `epito ps` and `epito doctor` all describe what the code
// DOES, and none of them described WHICH code. A merge that cannot be observed
// to have reached the box is a merge nobody can trust.
//
// Two facts, both cheap and both local:
//
//   version   `cli/package.json`, which is what an npm install has and a git
//             checkout has too
//   commit    the revision of the tree THIS FILE sits in — the runtime's own
//             source, never the agent's clone. A run clones the seat's repo
//             into a temp dir and that clone's HEAD answers a different
//             question entirely, so this deliberately asks about
//             `import.meta.url`'s directory and not about `process.cwd()`.
//
// `dirty` is the one that matters most, because a hand-patched runtime is a
// runtime no merge can change: the next `git pull` either conflicts or discards
// somebody's fix, and until someone looks, neither happens. So the modified
// paths are NAMED rather than counted — "dirty" sends an operator looking,
// "cli/src/lib/runner.js is modified here" tells them what they are about to
// lose.
//
// Never throws and never blocks on a network. A box with no git, an npm
// install with no `.git`, and a `git` that refuses the directory are all
// ordinary and all answered with a reason in words instead of an exception:
// this is called from the daemon's first line, and a runtime that will not
// start because it could not describe itself is a worse runtime.
import { spawnSync } from "node:child_process";
import { readFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

// cli/src/lib/build.js -> cli/
export const CLI_ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "..", "..");

const MODIFIED_SHOWN = 4;
const GIT_TIMEOUT_MS = 2_000;

// Only the trailing newline comes off. `git status --porcelain` puts the file's
// state in the first two COLUMNS, so a plain `.trim()` eats the leading space of
// an unstaged modification and takes the first character of the path with it —
// which is how the first run of this against the real host reported
// "li/src/index.js".
function git(args, cwd) {
  const r = spawnSync("git", args, { cwd, encoding: "utf8", timeout: GIT_TIMEOUT_MS });
  if (r.error || r.status !== 0) return null;
  return r.stdout.replace(/\n$/, "");
}

// " M cli/src/index.js" -> "cli/src/index.js"; "R  old -> new" -> "new".
export function porcelainPaths(status) {
  return (status ?? "").split("\n")
    .map((l) => /^..\s(.*)$/.exec(l)?.[1] ?? null)
    .filter(Boolean)
    .map((p) => (p.includes(" -> ") ? p.split(" -> ").pop() : p))
    .map((p) => p.replace(/^"|"$/g, ""))
    .sort();
}

// { version, commit, dirty, modified, source, why }
//
//   source "git"     the tree is a checkout and git answered
//   source "package" there is a version and no checkout to ask about — the
//                    ordinary shape of `npm i -g epito-cli`, not a fault
//   source "unknown" not even the version could be read
//
// `why` is set whenever a field is null, and it is a sentence rather than an
// error code, because every caller of this prints it to a human.
export function runtimeBuild({ dir = CLI_ROOT, runGit = git, readVersion = null } = {}) {
  let version = null;
  try {
    const pkg = readVersion ? readVersion(dir) : readFileSync(join(dir, "package.json"), "utf8");
    version = JSON.parse(pkg).version ?? null;
  } catch { version = null; }

  const inside = runGit(["rev-parse", "--is-inside-work-tree"], dir);
  if (inside !== "true") {
    return {
      dir, root: dir, version, commit: null, dirty: false, modified: [], branch: null, detached: false,
      source: version ? "package" : "unknown",
      why: version
        ? `${dir} is not a git checkout, so there is no revision to name — an epito installed from npm is the ordinary case`
        : `neither ${join(dir, "package.json")} nor a git checkout could be read at ${dir}, so this runtime cannot say which build it is`,
    };
  }

  const commit = runGit(["rev-parse", "--short", "HEAD"], dir);
  const branch = runGit(["rev-parse", "--abbrev-ref", "HEAD"], dir);
  // The checkout's own root, not the directory this file sits in: the fix for
  // a hand-patched runtime is a pull request from the repository, and naming
  // `.../epitome/cli` sends an operator to a place `git` will not take.
  const root = runGit(["rev-parse", "--show-toplevel"], dir) ?? dir;
  const status = runGit(["status", "--porcelain", "--untracked-files=no"], dir);
  const modified = porcelainPaths(status);
  return {
    dir, root, version, commit, branch: branch === "HEAD" ? null : branch, detached: branch === "HEAD",
    dirty: modified.length > 0, modified,
    source: "git",
    why: commit ? null : `git is here but would not name HEAD at ${dir}, so the revision is unknown`,
  };
}

// One line, for a log header, the daemon's first line and `epito ps`.
//
//   epito 0.1.0 · 3806b83 (main) · clean
//   epito 0.1.0 · 5836dc0 (main) · 2 tracked files modified here: cli/src/index.js, cli/src/lib/runner.js
//   epito 0.1.0 · installed, not a checkout
export function buildLine(b) {
  const head = `epito ${b.version ?? "version unknown"}`;
  if (b.source !== "git") return `${head} · ${b.source === "package" ? "installed, not a checkout" : "build unknown"}`;
  const rev = b.commit ? `${b.commit}${b.branch ? ` (${b.branch})` : b.detached ? " (detached)" : ""}` : "revision unknown";
  if (!b.dirty) return `${head} · ${rev} · clean`;
  const shown = b.modified.slice(0, MODIFIED_SHOWN).join(", ");
  const rest = b.modified.length > MODIFIED_SHOWN ? ` and ${b.modified.length - MODIFIED_SHOWN} more` : "";
  return `${head} · ${rev} · ${b.modified.length} tracked file${b.modified.length === 1 ? "" : "s"} modified here: ${shown}${rest}`;
}

// What `epito doctor` says about it, in the error-message bar's shape: the rule
// in the product's own vocabulary, and the fix in the message.
//
// This never refuses a run — a hand-patched runtime starts runs perfectly well,
// which is exactly why it went unseen for four weeks — so doctor reports it and
// exits 0. The section's whole value is that an operator reading a preflight
// sees the revision before they trust what the preflight said.
export function buildNote(b) {
  if (b.source === "unknown") return { level: "warn", text: b.why };
  if (b.source === "package") return { level: "ok", text: buildLine(b) };
  if (!b.commit) return { level: "warn", text: b.why };
  if (!b.dirty) return { level: "ok", text: buildLine(b) };
  // Two true readings and the command cannot tell them apart, so it states the
  // fact and names the hazard conditionally rather than guessing. A checkout
  // somebody is working in is modified for the obvious reason; a box that hosts
  // seats is a box where the same words mean four weeks of merged fixes are not
  // running. Hedging it into "possibly fine" would be worse than either.
  return {
    level: "warn",
    text: `${buildLine(b)}, so this runtime is not any revision in the repository. On a box that hosts seats that means a fix merged on the default branch does not reach it, and the next \`git pull\` here either conflicts with these edits or discards them; in a checkout you are working in it means what you expect. Fix, on a host: land them in a pull request from ${b.root}, then \`git checkout --\` those files and update the checkout`,
  };
}

// Read ONCE per process, and that is the point rather than a saving.
//
// A resident daemon loads its JavaScript at startup and keeps it; a `git pull`
// in the checkout underneath it changes the files and changes nothing about
// the code that is running. A build read per run would start reporting the new
// revision the moment somebody pulled, which is the exact lie this module
// exists to stop — the log would name a revision whose fix the running process
// does not have. So the answer is taken when this module is first loaded, with
// the code it describes, and never refreshed.
let cached = null;
export function thisRuntime() {
  if (cached === null) cached = runtimeBuild();
  return cached;
}
