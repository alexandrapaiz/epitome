// Which company a run belongs to, read from the roster's own `company.yaml`.
//
// The board's run-report endpoint requires two names: `company` and `seat`.
// `seat` is the agent's name and has never been in doubt. `company` was, and
// the hotfix running on this company's host answered it the cheap way —
// `[runtime].repo`'s last path segment, with one company's repository name
// hardcoded as the exception. That is wrong in a way that only shows up once
// the product is sold: it puts another company's repository name on a board
// row, and it cannot tell two companies apart when their seats clone from
// repositories with the same last segment.
//
// The answer (PM, 2026-10-18) is this file: `company.yaml` is the roster's own
// declaration to HQ (standards/company-interface.md §1), it already sits beside
// every roster this runtime hosts, and its `product` field is the name the
// board already files that company's Actions runs under. Reading it is a
// ROSTER-level choice, not a new manifest key, so spec/manifest.md stays frozen
// and no `agent.toml` changes.
//
// Where it is read, and why that matters: here, by `epito run`, which is the
// one process that reads the roster directory at all. The name then travels in
// the workflow input beside the manifest snapshot, exactly like the manifest
// does, so the worker still never reads the roster directory (law 3 of the
// design, docs/prfaq/epitod-v1-temporal.md). A worker-side environment variable
// would have been fewer lines and would have had the hotfix's bug back: one
// worker serves the `seats` queue for every roster on the box, so a single
// value in its environment cannot name two companies.
import { readFileSync, existsSync } from "node:fs";
import { dirname, join, resolve } from "node:path";

export const COMPANY_FILE = "company.yaml";

// How far up from the roster directory to look. The roster is a subdirectory
// of the company's repository (`agents/` here, `runtime/agents/` on HQ's), and
// the declaration sits at that repository's root, so two or three levels is
// the real distance. Four is the same bound `findManifests` descends with, for
// the same reason: a walk that climbs out of the repository and finds some
// other company's file is worse than one that finds nothing.
const MAX_UP = 4;

// A deliberately tiny YAML reader: top-level `key: value` scalars, nothing
// else. `company.yaml` has nested blocks (`surfaces`, `seats`) and this never
// descends into them — a line that is indented is a line that belongs to
// something, and the two fields this file wants are both at column zero.
//
// Why not a YAML dependency: `smol-toml` is this CLI's ONE runtime dependency
// and the reason `npx epito` is a two-second install (ADR-6). Adding a parser
// for four lines of flat key/value would be the largest thing in the package.
export function topLevelScalars(text) {
  const out = {};
  for (const raw of String(text ?? "").split("\n")) {
    if (/^\s/.test(raw) || !raw.trim() || raw.trimStart().startsWith("#")) continue;
    const m = /^([A-Za-z_][A-Za-z0-9_-]*):[ \t]*(.*)$/.exec(raw);
    if (!m) continue;
    let value = m[2].trim();
    // A trailing comment, but only one introduced by whitespace: `product: a#b`
    // is a value with a hash in it, and `product: a # b` is a value and a note.
    value = value.replace(/\s+#.*$/, "").trim();
    if (value.length >= 2 && ((value[0] === '"' && value.endsWith('"')) || (value[0] === "'" && value.endsWith("'")))) {
      value = value.slice(1, -1);
    }
    if (value === "" || value === "|" || value === ">") continue;   // a block opener is not a scalar
    out[m[1]] = value;
  }
  return out;
}

// The file itself, found by climbing. Returns null when there is none, which
// is the ordinary case for a stranger's roster and never an error.
export function findCompanyFile(startDir, { max = MAX_UP, exists = existsSync } = {}) {
  let dir = resolve(startDir);
  for (let i = 0; i <= max; i++) {
    const p = join(dir, COMPANY_FILE);
    if (exists(p)) return p;
    const up = dirname(dir);
    if (up === dir) break;
    dir = up;
  }
  return null;
}

// -> { name, path, note }
//
//   name  the company a run of this roster files its board report under, or
//         null, in which case no report is filed at all
//   note  one sentence for the daemon's startup log, in every case. A runtime
//         that silently files its runs under a name nobody chose is the thing
//         this function exists to stop, so the name it DID choose is said out
//         loud at startup, next to the engine address and the build line.
//
// The bar for the sentences is `epito validate`'s: name the rule, in the
// product's vocabulary, with the fix in the message.
export function companyFor(rosterDir, { read = readFileSync, exists = existsSync } = {}) {
  const path = findCompanyFile(rosterDir, { exists });
  if (!path) {
    return {
      name: null,
      path: null,
      note: `no ${COMPANY_FILE} at or above ${resolve(rosterDir)}, so these runs file no report to the company board. Fix: put a ${COMPANY_FILE} with a \`product:\` line at the root of the roster's repository — the board files a run under that name, and without one it has no company to file under`,
    };
  }
  let text;
  try { text = read(path, "utf8"); }
  catch (e) {
    return { name: null, path, note: `${path} cannot be read (${e.message}), so these runs file no report to the company board` };
  }
  const fields = topLevelScalars(text);
  const name = fields.product ?? null;
  if (!name) {
    return {
      name: null,
      path,
      note: `${path} has no top-level \`product:\` line, so these runs file no report to the company board. Fix: add one — the board files a run under the PRODUCT's name (\`product: epitome\`), not under the owning company's (\`company: ${fields.company ?? "alexandra-systems"}\`), because that is the name the board already carries this repository's runs under`,
    };
  }
  return { name, path, note: `runs of this roster file to the company board as "${name}" (${COMPANY_FILE}'s \`product\`)` };
}
