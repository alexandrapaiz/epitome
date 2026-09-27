#!/usr/bin/env python3
"""Run one LangGraph app once, as one epito run (ADR-17).

epito hosts the agent you already have, so this shim reads the file LangGraph
authors already write -- `langgraph.json` at the root of the agent's repository
-- resolves the graph it names, and streams it once with this run's prompt.
The agent's repository is unchanged: nothing here asks it to import epito.

Standard library only, on purpose: it runs inside whatever interpreter the
agent's own dependencies live in, and a shim that needed packages of its own
would be a shim that can break the agent it is hosting.

What epito hands in (all environment, never argv -- a prompt is a paragraph,
and a paragraph in /proc/<pid>/cmdline is readable by every user on the box):

    EPITO_AGENT      the seat's name              EPITO_MODEL      [runtime].model
    EPITO_RUN_ID     this run's id                EPITO_MAX_TURNS  recursion limit
    EPITO_TRIGGER    cron | hook | message | …    EPITO_CHARTER    [runtime].entry
    EPITO_PROMPT     the run's prompt             EPITO_GRAPH      [runtime].graph (optional)

plus the run's own credentials (GH_TOKEN/GITHUB_TOKEN, minted for this run) and
the trace context (TRACEPARENT, OTEL_EXPORTER_OTLP_ENDPOINT), which is how the
node spans below land inside the run's own trace with no OpenTelemetry package
installed anywhere (ADR-18).

What it prints: the graph's output as it goes, and one last JSON object, which
is the result contract every epito adapter speaks:

    {"session_id": null, "num_turns": <steps>, "result": "<last message>"}

Exit codes: 0 ran; 2 the adapter refused before the graph started (a message
saying which rule and the fix is on stderr AND in `detail` of the JSON, so it
reaches the board in words); 3 the graph itself raised.
"""
import json
import os
import sys
import time
import urllib.request
from importlib import util as import_util

REFUSED, RAISED = 2, 3


def out(line=""):
    print(line, flush=True)


def refuse(sentence, code=REFUSED, steps=0):
    """Fail in the product's voice: the rule, in epito's vocabulary, with the fix."""
    agent = os.environ.get("EPITO_AGENT", "this agent")
    text = f"{agent}: {sentence}"
    out(json.dumps({"session_id": None, "num_turns": steps, "result": None, "detail": text}))
    print(text, file=sys.stderr, flush=True)
    sys.exit(code)


# --- spans ----------------------------------------------------------------
# The adapter drives the stream, so it knows where one node ends and the next
# begins: that is why a LangGraph run is traceable here with no instrumentation
# library on the agent's side. Spans are buffered and posted once, at the end,
# in one request -- a run that is killed mid-graph loses its spans, and losing
# spans is the correct thing to lose.
class Trace:
    def __init__(self, env):
        self.spans = []
        self.endpoint = (env.get("OTEL_EXPORTER_OTLP_TRACES_ENDPOINT", "").strip()
                         or (env.get("OTEL_EXPORTER_OTLP_ENDPOINT", "").strip().rstrip("/") + "/v1/traces"
                             if env.get("OTEL_EXPORTER_OTLP_ENDPOINT", "").strip() else ""))
        parent = env.get("TRACEPARENT", "").split("-")
        self.trace_id = parent[1] if len(parent) >= 4 and len(parent[1]) == 32 else None
        self.parent_id = parent[2] if len(parent) >= 4 and len(parent[2]) == 16 else None
        self.agent = env.get("EPITO_AGENT")
        self.run_id = env.get("EPITO_RUN_ID")

    @property
    def on(self):
        return bool(self.endpoint and self.trace_id)

    def new_id(self):
        """An id handed out before the span exists, so children can name their parent."""
        return os.urandom(8).hex() if self.on else None

    def span(self, name, start_ns, end_ns, parent_id=None, attrs=None, error=None, span_id=None):
        if not self.on:
            return None
        span_id = span_id or os.urandom(8).hex()
        self.spans.append({
            "traceId": self.trace_id,
            "spanId": span_id,
            "parentSpanId": parent_id or self.parent_id,
            "name": name,
            "kind": 1,
            "startTimeUnixNano": str(start_ns),
            "endTimeUnixNano": str(end_ns),
            "attributes": [
                {"key": k, "value": {"intValue": str(v)} if isinstance(v, int) and not isinstance(v, bool)
                 else {"boolValue": v} if isinstance(v, bool) else {"stringValue": str(v)}}
                for k, v in (attrs or {}).items() if v is not None
            ],
            "status": {"code": 2, "message": str(error)} if error else {"code": 1},
        })
        return span_id

    def flush(self):
        if not self.on or not self.spans:
            return
        body = json.dumps({"resourceSpans": [{
            "resource": {"attributes": [
                {"key": "service.name", "value": {"stringValue": self.agent or "epito-agent"}},
                {"key": "epito.agent", "value": {"stringValue": self.agent or ""}},
                {"key": "epito.run_id", "value": {"stringValue": self.run_id or ""}},
            ]},
            "scopeSpans": [{"scope": {"name": "epito.langgraph"}, "spans": self.spans}],
        }]}).encode()
        req = urllib.request.Request(self.endpoint, data=body,
                                     headers={"content-type": "application/json"}, method="POST")
        try:
            urllib.request.urlopen(req, timeout=2).read()
            out(f"# trace: {len(self.spans)} span(s) -> {self.endpoint}")
        except Exception as e:                                     # never fail a run for a span
            out(f"# trace: the run stands, but {len(self.spans)} span(s) did not reach {self.endpoint} ({e})")


# --- the graph the manifest asked for -------------------------------------
def read_config():
    if not os.path.exists("langgraph.json"):
        refuse('[runtime].adapter is "langgraph", so this run looked for langgraph.json at the root of '
               "the agent's repository and found none. Fix: commit the langgraph.json your app already "
               'needs to run (LangGraph writes one for you), or set [runtime].adapter = "claude".')
    try:
        cfg = json.loads(open("langgraph.json", encoding="utf-8").read())
    except Exception as e:
        refuse(f"langgraph.json is not readable JSON ({e}). Fix: it is LangGraph's own file — "
               '{"dependencies": ["."], "graphs": {"agent": "./src/agent.py:graph"}}.')
    graphs = cfg.get("graphs") if isinstance(cfg, dict) else None
    if not isinstance(graphs, dict) or not graphs:
        refuse('langgraph.json declares no graphs, so there is nothing for this seat to run. '
               'Fix: add a "graphs" object naming at least one, e.g. '
               '{"graphs": {"agent": "./src/agent.py:graph"}}.')
    return graphs


def pick(graphs):
    asked = os.environ.get("EPITO_GRAPH")
    names = ", ".join(sorted(graphs))
    if asked:
        if asked not in graphs:
            refuse(f'[runtime].graph names "{asked}", and this app\'s langgraph.json declares {names}. '
                   f"Fix: set [runtime].graph to one of those, or rename the graph in langgraph.json.")
        return asked, graphs[asked]
    if len(graphs) > 1:
        refuse(f"this app declares more than one graph ({names}) and the manifest does not say which one "
               f'this seat is. Fix: set [runtime].graph = "{sorted(graphs)[0]}" (or another of them) in agent.toml.')
    only = next(iter(graphs))
    return only, graphs[only]


def load(name, spec):
    """`./src/agent.py:graph` or `package.module:graph`, LangGraph's own two spellings."""
    if not isinstance(spec, str) or ":" not in spec:
        refuse(f'langgraph.json points graph "{name}" at "{spec}", which is not '
               '<file-or-module>:<attribute>. Fix: e.g. "./src/agent.py:graph".')
    where, _, attr = spec.rpartition(":")
    sys.path.insert(0, os.getcwd())
    try:
        if where.endswith(".py") or where.startswith("."):
            path = os.path.abspath(where)
            if not os.path.exists(path):
                refuse(f'langgraph.json points graph "{name}" at "{where}", and that file is not in this '
                       "repository. Fix: correct the path in langgraph.json, or commit the file.")
            module_spec = import_util.spec_from_file_location(f"epito_graph_{name}", path)
            module = import_util.module_from_spec(module_spec)
            module_spec.loader.exec_module(module)
        else:
            module = __import__(where, fromlist=["*"])
    except SystemExit:
        raise
    except BaseException as e:
        refuse(f'importing graph "{name}" from "{where}" raised {type(e).__name__}: {e}. Fix: this is the '
               "agent's own code and its own dependencies — the runtime runs it, it does not install it "
               "(`pip install -e .` in the image the seat runs in).")
    if not hasattr(module, attr):
        have = ", ".join(sorted(k for k in vars(module) if not k.startswith("_"))) or "nothing public"
        refuse(f'"{where}" has no "{attr}" in it (it has: {have}). Fix: name the attribute langgraph.json '
               "points at, or export it.")
    obj = getattr(module, attr)
    if callable(obj) and not hasattr(obj, "stream") and not hasattr(obj, "invoke") and not hasattr(obj, "compile"):
        obj = obj()                                   # LangGraph also allows a factory
    if hasattr(obj, "compile") and not hasattr(obj, "stream"):
        obj = obj.compile()                           # an uncompiled StateGraph
    if not hasattr(obj, "stream") and not hasattr(obj, "invoke"):
        refuse(f'"{spec}" is a {type(obj).__name__}, which is not a graph this runtime can run: it has '
               "neither .stream() nor .invoke(). Fix: point langgraph.json at the compiled graph (or at the "
               "StateGraph, which this runtime compiles for you).")
    return obj


# --- the run --------------------------------------------------------------
def last_message(update):
    """The text a human would read, out of whatever the last node returned."""
    if isinstance(update, dict):
        for key in ("messages", "output", "result", "answer"):
            value = update.get(key)
            if isinstance(value, list) and value:
                value = value[-1]
            if value is None:
                continue
            return getattr(value, "content", None) or (value.get("content") if isinstance(value, dict) else None) or str(value)
    return None if update is None else str(update)


def main():
    env = os.environ
    prompt = env.get("EPITO_PROMPT", "")
    if not prompt.strip():
        refuse("this run arrived with no prompt, so there is nothing to ask the graph. This is an epito "
               "bug, not a manifest error: report it with the run id.")
    trace = Trace(env)
    graphs = read_config()
    name, spec = pick(graphs)
    out(f"# epito: langgraph adapter — graph \"{name}\" from {spec}")
    graph = load(name, spec)

    payload = {"messages": [{"role": "user", "content": prompt}]}
    config = {"configurable": {"thread_id": env.get("EPITO_RUN_ID", "epito")},
              "recursion_limit": int(env.get("EPITO_MAX_TURNS") or 100)}

    started = time.time_ns()
    graph_span = trace.new_id()        # the nodes' parent, named before it has an end time
    steps, result, failure = 0, None, None
    try:
        if hasattr(graph, "stream"):
            for chunk in graph.stream(payload, config, stream_mode="updates"):
                step_started = time.time_ns()
                for node, update in (chunk or {}).items():
                    steps += 1
                    text = last_message(update)
                    if text:
                        result = text
                    out(f"· {node}: {text if text else '(no message)'}")
                    trace.span(f"node {node}", step_started, time.time_ns(), parent_id=graph_span,
                               attrs={"epito.node": node, "epito.step": steps})
        else:
            state = graph.invoke(payload, config)
            steps = 1
            result = last_message(state)
            out(f"· {result}")
    except BaseException as e:                                     # the graph's own failure, named
        failure = f"{type(e).__name__}: {e}"
        expected = ""
        getter = getattr(graph, "get_input_jsonschema", None)
        if callable(getter):
            try:
                keys = ", ".join(sorted((getter() or {}).get("properties", {})))
                expected = f' This graph\'s input schema takes: {keys}.' if keys else ""
            except BaseException:
                expected = ""
        trace.span(f"graph {name}", started, time.time_ns(), span_id=graph_span,
                   attrs={"epito.graph": name, "epito.steps": steps}, error=failure)
        trace.flush()
        refuse(f'graph "{name}" raised while running: {failure}.{expected} Fix: this is the agent\'s own '
               f"code — run it the way its README says, then let the seat run it.", code=RAISED, steps=steps)

    # The graph span last, because only now does it have an end: OTLP has no
    # span update, so a span is posted once, complete.
    end = time.time_ns()
    trace.span(f"graph {name}", started, end, span_id=graph_span,
               attrs={"epito.graph": name, "epito.steps": steps})
    trace.flush()

    out(f"# epito: graph \"{name}\" ran {steps} step(s) in {(end - started) // 1_000_000}ms")
    out(json.dumps({"session_id": None, "num_turns": steps, "result": result}))


if __name__ == "__main__":
    main()
