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
    `On a runtime box you do not do this by hand — ${inRepo("deploy/provision-host.sh")}`,
    `installs the engine with the CLI. And the engine itself (the server \`epito run\` connects to at`,
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

// ─────────────────────────────────────────────────────────────────────────────
// The engine that IS installed, and is not answering.
//
// Two failures wear the same word. The one above is a package epito chose not
// to ship. This one is a server that is not running — and it is the common
// one, because the server is installed separately from the CLI by design
// (deploy/provision-host.sh installs the engine's npm packages and the units;
// it deliberately does not install the Temporal server itself).
//
// The sentence for it lived in two places — src/temporal/client.js and
// src/temporal/worker.js — with two different ways of digging the reason out
// of a gRPC error. That is drift already begun, so it lives here once and
// unit.mjs fails if either file grows its own copy again. Same rule as
// readiness.js's REPO_REQUIRED_BY: the list the message prints is the list the
// test checks the source against.
//
// It lives in lib/ rather than temporal/ for a second reason: `epito validate`
// has to be able to ask "is the engine up" on a machine where the engine is
// not installed at all (test/pack.sh asserts the manifest commands run there).
// Nothing in this module imports @temporalio, and the one thing it does import
// — temporal/env.js, for the address — imports nothing itself, which unit.mjs
// also asserts.
import { createConnection } from "node:net";
import { inRepo } from "./where.js";
import { temporalEnv } from "../temporal/env.js";

export const DEFAULT_ADDRESS = "127.0.0.1:7233";

// How long to wait before calling it unreachable. Short on purpose: the only
// caller that probes on a healthy path is `epito validate <dir>`, and a
// validator that hangs for ten seconds to tell you your files are fine is a
// validator people stop running. The real connect (`epito run`) still uses
// Temporal's own 10s connectTimeout — this is the cheap look, not the open.
export const PROBE_TIMEOUT_MS = 400;

// The fix, as a line the reader can actually run.
//
// `runtime/temporal/install.sh` used to be the first thing this sentence named,
// and that file is HQ's (alexandra-systems). It is in neither this repository
// nor `npm i -g epito`, whose package.json `files` ships src, adapters and
// README.md. So the product's most likely first refusal told you to run a
// script that exists on no machine you have — which is worse than naming no
// fix at all, because it sends you looking. The bar `epito validate` sets is
// the fix IN the message; a path is only a fix if the reader has the path.
//
// A wrong TEMPORAL_ADDRESS is called out separately because it is the one
// cause the reader cannot see: a stale export in a shell, or an /srv/asc/env
// copied between boxes, looks exactly like a dead engine.
export function engineFix(address = DEFAULT_ADDRESS) {
  const where = address === DEFAULT_ADDRESS
    ? `set TEMPORAL_ADDRESS if your engine is somewhere other than the default ${DEFAULT_ADDRESS}`
    : `point TEMPORAL_ADDRESS at the engine you have — it is currently ${address}, and unsetting it falls back to ${DEFAULT_ADDRESS}`;
  return `run \`temporal server start-dev\` for a local engine, or ${where}. On a runtime host the engine is brought up before epitod: ${inRepo('docs/deploy/README.md')} ("Temporal server + UI").`;
}

// Why a connection failed, as a sentence rather than a struct.
//
// The two clients report transport failures differently: @temporalio/client
// hands back an error with a `cause.code`, and @temporalio/worker's native
// connection nests a Rust error string. client.js read the first and worker.js
// read the second, so the same dead port produced "ECONNREFUSED" from `epito
// run` and "Failed to connect before the deadline" from `epito worker`. Both
// shapes are read here, in the order of specificity, so an operator who moves
// between the two commands hears one answer.
export function connectReason(e) {
  const raw = String(e?.cause?.message ?? e?.message ?? e);
  const m = /message: "([^"]+)"/.exec(raw) || /ConnectError\("([^"]+)"/.exec(raw);
  if (m) return m[1];
  return e?.cause?.code ?? raw;
}

// One sentence, both callers, every surface that has to say it.
export function engineUnreachableMessage(address, reason) {
  return `no Temporal server answering at ${address}${reason ? ` (${reason})` : ""} — the engine is a server, and it is installed separately from the CLI. Fix: ${engineFix(address)}`;
}

// host:port, including the bracketed IPv6 form Temporal accepts.
export function splitAddress(address) {
  const s = String(address ?? "");
  const v6 = /^\[(.+)\]:(\d+)$/.exec(s);
  if (v6) return { host: v6[1], port: Number(v6[2]) };
  const i = s.lastIndexOf(":");
  if (i <= 0 || i === s.length - 1) return { host: null, port: NaN };
  return { host: s.slice(0, i), port: Number(s.slice(i + 1)) };
}

// Is anything answering there? A bare TCP connect: no gRPC, no namespace
// check, no @temporalio.
//
// What a successful connect proves is exactly "something accepted a connection
// on that port" — so every call site says that, and none of them says Temporal
// is healthy. `epito run` still does the real connect and the real
// describeNamespace, and will still refuse an engine that answers and is wrong.
// This is the half that turns a validator's overclaim into a sentence an
// operator can act on, and it is the half that costs nothing.
export function engineAnswering(address, { timeoutMs = PROBE_TIMEOUT_MS, connect = createConnection } = {}) {
  const { host, port } = splitAddress(address);
  if (!host || !Number.isInteger(port) || port < 1 || port > 65535) {
    // A malformed address is not a dead engine, and saying "nothing is
    // answering at garbage" would read as a network problem when the problem
    // is the variable. Flagged so callers can say which.
    return Promise.resolve({ ok: false, address, malformed: true, reason: "not a host:port address" });
  }
  return new Promise((resolve) => {
    let done = false;
    const finish = (r) => { if (!done) { done = true; try { socket.destroy(); } catch {} resolve({ address, malformed: false, ...r }); } };
    const socket = connect({ host, port });
    socket.setTimeout(timeoutMs);
    socket.once("connect", () => finish({ ok: true, reason: null }));
    socket.once("timeout", () => finish({ ok: false, reason: `nothing answered within ${timeoutMs}ms` }));
    socket.once("error", (e) => finish({ ok: false, reason: e?.code ?? e?.message ?? "connection failed" }));
  });
}

// The probe's result as a clause, so `epito validate`'s three sentences about a
// missing engine cannot describe one result three ways.
export function engineMissing(engine) {
  return engine?.malformed
    ? `TEMPORAL_ADDRESS is "${engine.address}", which is ${engine.reason}`
    : `nothing is answering at ${engine?.address} (${engine?.reason})`;
}

// The address the runtime would use, asked without loading the runtime.
export const engineAddress = (env = process.env) => temporalEnv(env).address;
