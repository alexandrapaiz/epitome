// The one place a connection is made, so there is one place the failure is
// explained. An operator who cannot reach the engine should be told the
// address, the namespace, and what to type next — the same bar `epito
// validate` sets for a broken manifest.
import { Client, Connection } from "@temporalio/client";
import { temporalEnv } from "./env.js";
// The unreachable-engine sentence is not written here. It is one sentence in
// src/lib/engine.js, shared with worker.js — the two files had two copies and
// two different ways of reading the reason out of a gRPC error, which is how
// the wording was already drifting apart.
import { connectReason, engineUnreachableMessage } from "../lib/engine.js";

export async function connect({ env = process.env, quiet = false } = {}) {
  const cfg = temporalEnv(env);
  let connection;
  try {
    connection = await Connection.connect({ address: cfg.address, connectTimeout: "10s" });
  } catch (e) {
    throw new Error(engineUnreachableMessage(cfg.address, connectReason(e)));
  }
  const client = new Client({ connection, namespace: cfg.namespace });
  // Fail here rather than at the first schedule: a missing namespace is the
  // one configuration mistake that otherwise looks like "nothing happened".
  try {
    await connection.workflowService.describeNamespace({ namespace: cfg.namespace });
  } catch (e) {
    await connection.close().catch(() => {});
    if (String(e.message ?? "").toLowerCase().includes("not found") || e.code === 5) {
      throw new Error(`namespace "${cfg.namespace}" does not exist on ${cfg.address} — create it with \`temporal operator namespace create ${cfg.namespace}\`, or set TEMPORAL_NAMESPACE to one that does`);
    }
    throw new Error(`Temporal at ${cfg.address} refused a namespace check for "${cfg.namespace}": ${e.message}`);
  }
  if (!quiet) console.log(`temporal: ${cfg.address} namespace=${cfg.namespace} queue=${cfg.taskQueue}`);
  return { client, connection, cfg };
}
