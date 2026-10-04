// `epito worker`: the process that does the work. One per host, systemd unit
// epitod-worker.service, task queue `seats`.
//
// It takes no roster. A workflow's input carries its manifest as a snapshot
// (law 3), which is what lets this process be stateless and lets a schedule's
// payload be auditable on its own. What the worker DOES hold is the
// environment: CLAUDE_CODE_OAUTH_TOKEN, GH_TOKEN, the Slack webhooks. Those
// never travel through Temporal; the manifest names them and the `execute`
// activity reads their values here.
import { NativeConnection, Worker } from "@temporalio/worker";
import { createRequire } from "node:module";
import * as activities from "./activities.js";
import { temporalEnv } from "./env.js";
import { appendAudit } from "../lib/audit.js";
import { traceConfig } from "../lib/trace.js";
// The unreachable-engine sentence and the reason-extraction behind it are one
// pair in src/lib/engine.js, shared with temporal/client.js. They used to be a
// copy each, and the copies disagreed about what to call a dead port.
import { connectReason, engineUnreachableMessage } from "../lib/engine.js";

const require = createRequire(import.meta.url);

export async function runWorker({ env = process.env } = {}) {
  const cfg = temporalEnv(env);
  let connection;
  try {
    connection = await NativeConnection.connect({ address: cfg.address, connectTimeout: "10s" });
  } catch (e) {
    console.error(`epito: ${engineUnreachableMessage(cfg.address, connectReason(e))}`);
    process.exit(1);
  }

  let worker;
  try {
    worker = await Worker.create({
      connection,
      namespace: cfg.namespace,
      taskQueue: cfg.taskQueue,
      workflowsPath: require.resolve("./workflows.js"),
      activities,
      // One seat run at a time per worker by default: a run is a whole `claude`
      // process with a clone of a repository, not a task, and a host that tries
      // to hold eight of them thrashes. EPITO_MAX_CONCURRENT_RUNS raises it for
      // a bigger box.
      maxConcurrentActivityTaskExecutions: Number(env.EPITO_MAX_CONCURRENT_RUNS) || 4,
    });
  } catch (e) {
    const msg = String(e.message ?? e);
    if (/namespace/i.test(msg) && /not.?(found|exist)/i.test(msg)) {
      console.error(`epito: namespace "${cfg.namespace}" does not exist on ${cfg.address} — create it with \`temporal operator namespace create ${cfg.namespace}\`, or set TEMPORAL_NAMESPACE to one that does`);
    } else {
      console.error(`epito: the worker could not start against ${cfg.address} namespace=${cfg.namespace}: ${msg}`);
    }
    process.exit(1);
  }

  console.log(`epito worker: ${cfg.address} namespace=${cfg.namespace} queue=${cfg.taskQueue} executor=${cfg.executor}`);
  console.log(`epito worker: run timeout ${Math.round(cfg.runTimeoutMs / 60000)} minutes (EPITO_RUN_TIMEOUT_MS)`);
  // Whether this box traces is a thing an operator should be able to read on
  // the first line of the log rather than infer from an empty Phoenix (ADR-18).
  const trace = traceConfig();
  console.log(`epito worker: traces ${trace ? `-> ${trace.url}` : "off (set OTEL_EXPORTER_OTLP_ENDPOINT to see inside a run)"}`);
  appendAudit({ agent: null, action: "worker.start", address: cfg.address, namespace: cfg.namespace, queue: cfg.taskQueue, executor: cfg.executor, traces: trace?.url ?? null });

  const stop = (sig) => {
    console.log(`${sig}: draining the worker (runs in flight get their timeout to finish)`);
    appendAudit({ agent: null, action: "worker.stop", signal: sig });
    worker.shutdown();
  };
  process.on("SIGINT", () => stop("SIGINT"));
  process.on("SIGTERM", () => stop("SIGTERM"));

  await worker.run();
  await connection.close().catch(() => {});
}
