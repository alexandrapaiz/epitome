// The GitHub repository a directory already is.
//
// `epito init` needs it because `[runtime].repo` is the one field a vibecoder
// cannot guess from the prompt and every other command requires (see
// readiness.js): the manifest it scaffolded validated and then got refused by
// `epito run`, `epito deploy` and `epito token` alike. Nearly always the
// answer is sitting in the directory already — you run `epito init` inside the
// repository the agent is going to work in — so init reads it instead of
// asking, and says where it got it.
//
// Local only: one `git remote get-url`, no network, no account. A remote that
// is not GitHub returns null rather than a guess, because v0.1's only identity
// platform is GitHub and a GitLab URL in [runtime].repo would validate and
// then fail at the mint — the exact failure this module exists to remove.
import { spawnSync } from "node:child_process";

// Must agree with [runtime].repo's own rule in manifest.js: owner/name, and
// nothing a path or a URL could smuggle through.
const REPO_RE = /^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/;

// Pull owner/name out of a git remote URL, or null when it is not a GitHub
// one. Exported for its own tests: the four spellings below are what `git
// remote add` actually writes, and getting one wrong puts a bad value in a
// scaffolded manifest, which is worse than leaving the field out.
export function parseGitHubRemote(url) {
  const u = String(url ?? "").trim();
  if (!u) return null;
  const m =
    // git@github.com:owner/name(.git)
    /^(?:ssh:\/\/)?git@github\.com[:/]([^/\s]+)\/([^/\s]+?)(?:\.git)?\/?$/.exec(u) ??
    // https://github.com/owner/name(.git), with or without a userinfo prefix
    /^(?:https?|git):\/\/(?:[^@/\s]*@)?(?:www\.)?github\.com\/([^/\s]+)\/([^/\s]+?)(?:\.git)?\/?$/.exec(u);
  if (!m) return null;
  const repo = `${m[1]}/${m[2]}`;
  // ".." in either half would be a path traversal in something we are about to
  // write into a manifest and later interpolate into a clone URL.
  if (!REPO_RE.test(repo) || m[1] === "." || m[1] === ".." || m[2] === "." || m[2] === "..") return null;
  return repo;
}

// The top of the git work tree `cwd` is in, or null. Here because
// `[runtime].entry` is "a path inside `repo`" (spec/manifest.md) and a roster
// puts the manifest in a subdirectory: agents/pm/agent.toml names
// prompts/pm-agent.md, which is at the top of the repository and not beside
// the manifest. Resolving entry only against the manifest's own folder made
// `epito validate` warn that a committed charter was missing — see
// readiness.js. Local only: one `git rev-parse`, no network.
export function repoRoot(cwd = process.cwd()) {
  let res;
  try {
    res = spawnSync("git", ["rev-parse", "--show-toplevel"], {
      cwd, encoding: "utf8", timeout: 5000, stdio: ["ignore", "pipe", "ignore"],
    });
  } catch { return null; }
  if (!res || res.status !== 0 || typeof res.stdout !== "string") return null;
  const top = res.stdout.trim();
  return top || null;
}

// owner/name for the git repository `cwd` is in, or null. Never throws: not
// being in a repo is the ordinary case for `epito init` in an empty folder.
export function originRepo(cwd = process.cwd()) {
  let res;
  try {
    res = spawnSync("git", ["remote", "get-url", "origin"], {
      cwd, encoding: "utf8", timeout: 5000, stdio: ["ignore", "pipe", "ignore"],
    });
  } catch { return null; }
  if (!res || res.status !== 0 || typeof res.stdout !== "string") return null;
  return parseGitHubRemote(res.stdout);
}
