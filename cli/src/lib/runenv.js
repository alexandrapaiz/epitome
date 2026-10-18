// The environment a run gets, in one place, because a check that builds its
// own copy of it is a check that eventually tests a different thing.
//
// `executeAgent` spawns the executor with an ALLOWLIST, not with the worker's
// environment: PATH, HOME and USER, plus the names `[runtime].env` asks for and
// this box actually holds. That list is the reason epitod v0's first real run
// exited 1 with "Not logged in" — the claude CLI finds its credentials under
// HOME and, on macOS, through the login keychain it looks up by USER, and
// neither was in the allowlist until that run taught us. It is also what makes
// a roster portable: a name the box does not hold is dropped rather than
// faked, so a seat runs on a box that is short of one.
//
// Both halves of that are now checkable before 06:00 rather than at it, and
// the thing doing the checking (`epito doctor`) must spawn the executor under
// the SAME environment a run would, or it proves nothing about the run. Hence
// this module: src/lib/runner.js and src/doctor.js call one function, and
// cli/test/unit.mjs asserts neither of them spells the allowlist itself again.
//
// What is deliberately NOT here: the run's own minted credential, the trace
// context, the git author identity, and the window's scratch directory
// (`TMPDIR`/`EPITO_SCRATCH`, src/lib/runner.js). Those are facts about one
// run — they are built per run, in runner.js, on top of this — and a
// preflight has no run to build them from: the scratch directory is derived
// from the clone, and a preflight has no clone. The executor does not read
// any of the four to decide whether it can start, which is the only question
// a preflight asks. In particular `TMPDIR` does not belong in the list below:
// a name in RUNTIME_GIVEN is read off the WORKER's environment, which is the
// one directory every window on the box already shared.

// The three the runtime gives every run, whatever the manifest says.
export const RUNTIME_GIVEN = ["PATH", "HOME", "USER"];

// The allowlist, resolved against one environment. Keys whose value is
// undefined are kept as undefined — `child_process` drops those, and dropping
// them here instead would hide a box with no HOME from the test that looks.
export function baseRunEnv(manifest, env = process.env) {
  const out = {};
  for (const k of RUNTIME_GIVEN) out[k] = env[k];
  for (const k of manifest?.runtime?.env ?? []) if (env[k] !== undefined) out[k] = env[k];
  return out;
}

