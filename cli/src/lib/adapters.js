// What epito spawns for a run, per kind of agent (ADR-17).
//
// An adapter is a name, a spawn contract and nothing else: given one run's
// facts it returns a file to spawn, its argv, and the extra environment that
// one child needs. epito links no framework library and imports nothing from
// the agent's language, because the promise is that it runs the agent you
// already have (R4, ADR-10) and an import is a modification.
//
// Every adapter speaks the SAME result contract: the last JSON object the
// child prints, read for `session_id`, `num_turns` and `result`
// (parseExecutorResult in runner.js). `claude --output-format json` already
// emits that shape, which is why it is the shape.
//
// `routeEnv` is the router's half (ADR-19): the same run, on whichever road
// the router picked, differs only in the model it names and the environment
// that points the child at that endpoint. Which variables carry that is a
// property of the KIND of agent — `ANTHROPIC_BASE_URL` means something to the
// claude CLI and nothing to a LangGraph app — so it belongs in this table and
// nowhere else.
//
// `resumes` is the honest half. Presence — a held window, `POST /message`,
// `--resume` — rests on a session id the executor hands back and can be handed
// again. The claude CLI has one; a LangGraph app has a checkpointer we do not
// configure, so `langgraph` declares `resumes: false` and a follow-up message
// starts a fresh run with the message as its prompt, saying so in the log.
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";
import { anthropicRouteEnv, routeFacts } from "./router.js";

// cli/src/lib -> cli/adapters/langgraph_run.py. The shim ships with epito: a
// LangGraph app has no one-shot entry point of its own (the framework's own
// invocation paths are a dev server and a library call), so the adapter's body
// is this file the way claude's flags are that adapter's body.
export const LANGGRAPH_SHIM = join(dirname(dirname(dirname(fileURLToPath(import.meta.url)))), "adapters", "langgraph_run.py");

export const ADAPTERS = {
  claude: {
    resumes: true,
    describe: "the Claude Code CLI, headless (`claude -p`) — the default, and what every manifest written before adapters existed gets",
    binary: (env, override) => override || env.EPITO_EXECUTOR || "claude",
    // Routing, for an executor that speaks the Anthropic API: the endpoint and
    // the key under the two variable names that CLI already reads, which is
    // exactly what HQ's workflows set by hand today (ADR-19).
    routeEnv: (route, env) => anthropicRouteEnv(route, env),
    command({ manifest, prompt, resume, binary, route }) {
      const rt = manifest.runtime;
      const args = [
        "-p", prompt,
        "--permission-mode", "bypassPermissions",
        "--model", route?.model ?? rt.model,
        "--max-turns", String(rt.max_turns ?? 100),
        "--output-format", "json",
      ];
      if (resume) args.push("--resume", resume);
      return { file: binary, args, env: {} };
    },
  },

  langgraph: {
    resumes: false,
    describe: "a LangGraph app, run through the `langgraph.json` its author already has",
    // Not EPITO_EXECUTOR: that variable names the claude executable, and a box
    // that overrides it (every smoke test does) must not thereby hand a
    // Python shim to a Node stub.
    binary: (env, _override) => env.EPITO_PYTHON || "python3",
    // A foreign agent builds its own model client, so the route reaches it as
    // facts rather than as someone else's variable names — and never as a
    // credential: a route's `token_env` is listed in [runtime].env by the
    // manifest, so the key already arrives under the name the agent's own
    // code reads.
    routeEnv: (route) => routeFacts(route),
    command({ manifest, name, runId, trigger, prompt, binary, route }) {
      const rt = manifest.runtime;
      // The run's facts arrive as environment, not argv: a prompt is a
      // paragraph, and a paragraph in /proc/<pid>/cmdline is a paragraph every
      // user on the box can read. Nothing here is a secret; the credential
      // arrives by the same route every other adapter's does, from the caller.
      return {
        file: binary,
        args: [LANGGRAPH_SHIM],
        env: {
          EPITO_AGENT: name,
          EPITO_RUN_ID: runId,
          EPITO_TRIGGER: trigger ?? "",
          EPITO_MODEL: route?.model ?? rt.model,
          EPITO_MAX_TURNS: String(rt.max_turns ?? 100),
          EPITO_CHARTER: rt.entry,
          EPITO_PROMPT: prompt,
          ...(rt.graph ? { EPITO_GRAPH: rt.graph } : {}),
        },
      };
    },
  },
};

export const ADAPTER_NAMES = Object.keys(ADAPTERS);
export const DEFAULT_ADAPTER = "claude";

// The sentence an unknown adapter gets, in one place so `epito validate` and a
// run that reached the box with a manifest validate never saw say the same
// thing.
export function unknownAdapter(value) {
  const list = ADAPTER_NAMES.map((n) => `"${n}" (${ADAPTERS[n].describe})`).join("; ");
  return `[runtime].adapter "${value}" is not a kind of agent epito can host — it hosts ${list}. Fix: name one of those, or leave the field out to get "claude".`;
}

// The adapter a manifest names, or the default. Throws in the product's voice:
// this is reached by a run on a box, where a manifest may predate the
// validator that would have caught it.
export function adapterFor(manifest) {
  const asked = manifest?.runtime?.adapter ?? DEFAULT_ADAPTER;
  const adapter = ADAPTERS[asked];
  if (!adapter) {
    const err = new Error(`${manifest?.agent?.name ?? "this agent"}: ${unknownAdapter(asked)}`);
    err.stage = "adapter";
    err.permanent = true;
    throw err;
  }
  return { name: asked, ...adapter };
}
