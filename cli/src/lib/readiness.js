// What a manifest is READY for, as distinct from whether it is a manifest.
//
// `epito validate` answers the second question, and spec v0.1 deliberately
// keeps it permissive on two points:
//
//   - `[runtime].repo` may be absent — "`epito validate` accepts it absent
//     (Actions-era manifests stay valid); `epito run` and `epito token` both
//     refuse without it, and say so" (spec/manifest.md, the field catalogue).
//   - an unmapped scope "fails **the mint**, naming the scope and the mapped
//     set — not `epito validate`. That placement is deliberate: a stricter
//     validator would refuse a running roster at startup over one word"
//     (spec/manifest.md, "Scopes").
//
// Both calls are right and the price was a ✓ that overclaimed. `epito init`
// wrote a manifest, `epito validate` ticked it, and `epito run`, `epito ps`,
// `epito deploy` and `epito token` then every one refused it — so the first
// three commands a vibecoder runs, in order, out of the box, ended in a
// refusal the tick had just told them would not come. The tick was correct and
// the user was still stuck, which is the one failure the error-message bar
// exists to prevent.
//
// So the rules the OTHER commands apply live here, once, and `epito validate`
// reads them out instead of implying they do not exist. Nothing here changes
// an exit code by itself: these are notes, and `--for-runtime` is what turns
// them into errors, opt-in, because the default has to keep saying yes to
// every manifest the spec blesses.
import { SCOPE_MAP } from "./identity.js";

// The commands that refuse a manifest with no `[runtime].repo`. This list is
// the one the note prints AND the one the drift test checks the source
// against, so a fifth command growing the same requirement cannot quietly
// make the note a lie (cli/test/unit.mjs, "the repo note names every command
// that requires it").
export const REPO_REQUIRED_BY = ["run", "ps", "deploy", "token"];

// The commands that refuse a scope outside SCOPE_MAP. `run` is absent on
// purpose: a run mints through `epito token`'s path, but the roster loads and
// the schedule registers either way, so the refusal lands at mint time.
export const SCOPE_REQUIRED_BY = ["deploy", "token"];

// How each command is spelled when it is the one refusing. `ps` reads manifests
// only when it is handed a directory (src/temporal/ps.js: "A roster directory
// is optional"), and a note that said a bare `epito ps` would refuse would be
// the same kind of overclaim this module exists to remove.
const SPELLING = { ps: "ps <dir>" };
const cmd = (x) => `\`epito ${SPELLING[x] ?? x}\``;

const list = (xs) => xs.length === 1
  ? cmd(xs[0])
  : `${xs.slice(0, -1).map(cmd).join(", ")} and ${cmd(xs[xs.length - 1])}`;

// Things that will make another command refuse this manifest. Returns
// [{ commands, problem, fix }]; empty means every command's extra rules pass.
export function blockers(m, path = "agent.toml") {
  const out = [];
  const r = m?.runtime;
  if (r && !r.repo) {
    out.push({
      commands: REPO_REQUIRED_BY,
      problem: `[runtime].repo is unset, so ${list(REPO_REQUIRED_BY)} will refuse this manifest: the runtime clones owner/name fresh for every run, and a minted token is scoped to exactly one repository`,
      fix: `add repo = "owner/name" to [runtime] in ${path}`,
    });
  }
  const scopes = Array.isArray(m?.identity?.scopes) ? m.identity.scopes : [];
  const unmapped = scopes.filter((s) => typeof s === "string" && !SCOPE_MAP[s]);
  if (unmapped.length) {
    out.push({
      commands: SCOPE_REQUIRED_BY,
      problem: `[identity].scopes names ${unmapped.length === 1 ? "a scope" : "scopes"} v0.1 cannot mint (${unmapped.map((s) => `"${s}"`).join(", ")}), so ${list(SCOPE_REQUIRED_BY)} will refuse rather than mint a token narrower than the manifest promises`,
      fix: `declare only ${Object.keys(SCOPE_MAP).map((s) => `"${s}"`).join(", ")} in ${path}, or open a card to map the rest`,
    });
  }
  return out;
}

// Things this command could not check, so the tick does not claim it did.
// `[runtime].entry` is the only one in v0.1: when `repo` is set the charter
// lives in that repository and the runtime reads it inside the clone, so a
// path that is wrong is a run-time refusal and there is nothing here to stat
// (src/lib/manifest.js says the same at the check it skips).
export function unchecked(m) {
  const out = [];
  const r = m?.runtime;
  if (r?.repo && r?.entry) {
    out.push(`[runtime].entry "${r.entry}" is read inside the clone of ${r.repo}, not here, so this ✓ does not say the charter exists — commit it to ${r.repo} before the first run`);
  }
  return out;
}
