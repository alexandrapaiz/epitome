// The engine is not installed with the CLI, and a missing engine is a sentence,
// not a stack trace.
//
// `epito` publishes @temporalio/* as OPTIONAL peer dependencies: `npm i -g
// epito` is half a megabyte, and the four engine packages are ~300 MB of
// prebuilt Rust core that most installs never load. For the people who only
// write manifests — `epito init`, `epito validate`, `epito deploy`, `epito
// token`, `epito board` — that weight buys nothing, and every one of those
// commands runs with no engine present (cli/test/pack.sh asserts it).
//
// The price is that three commands can now be run by someone whose machine
// cannot run them: `epito run`, `epito worker`, `epito ps`. index.js already
// wrapped those three in a guard whose comment reads "the engine being
// unreachable is an operating condition, not a crash ... never a stack" — but
// the `await import()` sat OUTSIDE that guard, so the one failure the guard
// was written for was the one it could not catch. A user who ran `npm i -g
// epito && epito run .` got fourteen lines of ERR_MODULE_NOT_FOUND naming a
// file path inside our own package. That fails the bar `epito validate` sets:
// name the rule, in the product's words, with the fix in the message.
//
// So: dynamic import goes through here. A module missing because the engine
// is not installed becomes an epito refusal. Anything else — a syntax error
// in our own code, a module we broke — is re-thrown untouched, because
// swallowing that would turn our bug into the user's problem.

// What each engine-backed command needs on the box, in the order npm wants
// them. Kept here rather than read from package.json's peerDependencies
// because the install line has to be copy-pasteable, and because `epito
// worker` needs three of the four while `epito run` needs one.
const NEEDS = {
  run: ["@temporalio/client"],
  worker: ["@temporalio/worker", "@temporalio/activity", "@temporalio/workflow"],
  ps: ["@temporalio/client"],
  // Both reach the engine through run.js: a window is a workflow that holds a
  // session open, and a message is a signal into it.
  window: ["@temporalio/client"],
  message: ["@temporalio/client"],
};

// Is this the failure of an engine package, or of our own code? Node reports
// both as ERR_MODULE_NOT_FOUND, and the message names the specifier, so the
// test is whether the thing that could not be found is a package we chose not
// to ship. A missing relative import is OUR bug and must not be dressed up as
// a user's missing install.
export function missingEnginePackage(err) {
  if (err?.code !== "ERR_MODULE_NOT_FOUND") return null;
  const m = /(?:Cannot find package|Cannot find module) '(@temporalio\/[a-z]+)'/.exec(err.message || "");
  return m ? m[1] : null;
}

export function engineMissingMessage(cmd, missing) {
  const needs = NEEDS[cmd] ?? ["@temporalio/client"];
  // Name the one that was actually missing first; it is the one the user can
  // check. Then the whole set, because installing one of three leaves them
  // here again with the next name.
  const install = needs.join(" ");
  return [
    `\`epito ${cmd}\` needs the Temporal engine client, and ${missing} is not installed on this machine.`,
    ``,
    `This is not a broken install. \`epito\` ships without the engine on purpose — the`,
    `manifest commands (init, validate, deploy, token, board) are the whole CLI for most`,
    `people, and the engine packages are ~300 MB. Only the two runtime processes`,
    `(\`epito run\`, \`epito worker\`) and \`epito ps\` need them.`,
    ``,
    `Fix: npm i -g ${install}`,
    `then: epito ${cmd}${cmd === "run" ? " <dir>" : ""}`,
    ``,
    `On a runtime box you do not do this by hand — deploy/provision-host.sh installs the`,
    `engine with the CLI. And the engine itself (the server \`epito run\` connects to at`,
    `TEMPORAL_ADDRESS) is a separate thing again: \`temporal server start-dev\` on a laptop.`,
  ].join("\n");
}

// Import a module that may pull in the engine. `cmd` is the command the user
// typed, because the fix line differs per command.
export async function engineImport(loader, cmd) {
  try {
    return await loader();
  } catch (err) {
    const missing = missingEnginePackage(err);
    if (!missing) throw err;
    const e = new Error(engineMissingMessage(cmd, missing));
    e.epitoHandled = true;
    throw e;
  }
}
