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

const require = createRequire(import.meta.url);

export async function runWorker({ env = process.env } = {}) {
  const cfg = temporalEnv(env);
  let connection;
  try {
    connection = await NativeConnection.connect({ address: cfg.address, connectTimeout: "10s" });
  } catch (e) {
    console.error(`epito: no Temporal server answering at ${cfg.address} (${e.cause?.code ?? e.message}) — start it on the host with runtime/temporal/install.sh, or locally with \`temporal server start-dev\`, and set TEMPORAL_ADDRESS if it is not 127.0.0.1:7233`);
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
  appendAudit({ agent: null, action: "worker.start", address: cfg.address, namespace: cfg.namespace, queue: cfg.taskQueue, executor: cfg.executor });

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
