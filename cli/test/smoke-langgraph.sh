#!/usr/bin/env bash
# Smoke test for the langgraph adapter (ADR-17), against the real framework when
# it is installed and against a graph-shaped object when it is not. It spends no
# tokens, calls no model, and touches no network except a local OTLP sink.
#
#   bash test/smoke-langgraph.sh                     # from cli/
#   EPITO_PYTHON=/path/to/venv/bin/python bash test/smoke-langgraph.sh
#
# What it proves:
#
#   1. a LangGraph app runs UNMODIFIED — its own langgraph.json, its own
#      graph, no epito import anywhere in it
#   2. the run's facts reach the graph, and its steps come back as turns, its
#      last message as the result, its PR url read off stdout like any seat's
#   3. every node is a SPAN inside the run's trace (ADR-18), with no
#      OpenTelemetry package installed anywhere
#   4. every refusal names the rule, in the product's vocabulary, with the fix:
#      no langgraph.json, two graphs and no [runtime].graph, a graph that is
#      not there, a spec that is not <file>:<attr>, a file that is not there,
#      an attribute that is not there, a graph that raises
#
# The real-framework half is skipped, loudly, when langgraph is not importable:
# a machine without it is an unrun test, not a passing one.
set -uo pipefail

CLI="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SHIM="$CLI/adapters/langgraph_run.py"
ROOT="${TMPDIR:-/tmp}/epito-langgraph-$$"
SINK_PORT="${EPITO_TEST_OTLP_PORT:-47475}"
SPANS="$ROOT/spans.jsonl"
TRACE_ID="1234567890abcdef1234567890abcdef"
EXECUTE_SPAN="fedcba0987654321"
pass=0; fail=0
ok()   { pass=$((pass+1)); printf '  ok   %s\n' "$1"; }
bad()  { fail=$((fail+1)); printf '  FAIL %s\n' "$1"; }
check(){ if eval "$2"; then ok "$1"; else bad "$1"; printf '       output was: %s\n' "$(head -c 400 "$OUT" 2>/dev/null)"; fi; }
step() { printf '\n== %s\n' "$1"; }

cleanup() { kill ${SINK_PID:-} 2>/dev/null; [ -n "${EPITO_SMOKE_KEEP:-}" ] && printf '\nkept: %s\n' "$ROOT" || rm -rf "$ROOT"; }
trap cleanup EXIT
mkdir -p "$ROOT"
OUT="$ROOT/out.txt"

# One run of the shim, in a copy of a fixture, with the environment epito hands
# it. Named arguments would be nicer; this is the shape the adapter produces.
run_shim() { # <fixture-dir> <python> [extra env assignments…]
  local dir="$1" py="$2"; shift 2
  ( cd "$dir" && env "$@" "$py" "$SHIM" ) > "$OUT" 2>&1
  echo $?
}
result() { grep -E '^\{"session_id"' "$OUT" | tail -1; }
detail() { result | python3 -c 'import json,sys; print(json.loads(sys.stdin.read()).get("detail") or "")'; }

step "sink: a stand-in trace backend on 127.0.0.1:$SINK_PORT (Phoenix takes the same OTLP)"
node "$CLI/test/otlp-sink.mjs" "$SINK_PORT" "$SPANS" > "$ROOT/sink.log" 2>&1 & SINK_PID=$!
for _ in $(seq 1 60); do grep -q 'otlp sink on' "$ROOT/sink.log" && break; sleep 0.2; done
check "the sink is up" "grep -q 'otlp sink on $SINK_PORT' '$ROOT/sink.log'"

TRACED=(OTEL_EXPORTER_OTLP_ENDPOINT="http://127.0.0.1:$SINK_PORT" TRACEPARENT="00-$TRACE_ID-$EXECUTE_SPAN-01")
FACTS=(EPITO_AGENT=graphs EPITO_RUN_ID=run-graphs-1 EPITO_TRIGGER=cron EPITO_MODEL=claude-sonnet-5
       EPITO_CHARTER=prompts/graphs.md EPITO_MAX_TURNS=25 EPITO_STUB_ECHO_TOKEN=1
       GH_TOKEN=ghs_SMOKETOKEN000000000000000000000000)

# --- the framework, if this machine has it -------------------------------
PY_REAL="${EPITO_PYTHON:-python3}"
if ! "$PY_REAL" -c "import langgraph" >/dev/null 2>&1; then
  if [ -x /tmp/lgvenv/bin/python ] && /tmp/lgvenv/bin/python -c "import langgraph" >/dev/null 2>&1; then
    PY_REAL=/tmp/lgvenv/bin/python
  else
    PY_REAL=""
  fi
fi

if [ -n "$PY_REAL" ]; then
  step "1: a REAL LangGraph app runs as a seat — its own langgraph.json, unmodified"
  work="$ROOT/real"; cp -r "$CLI/test/fixtures/langgraph-real" "$work"
  mkdir -p "$work/prompts"; printf '# graphs\n\nYou are graphs. One run: open a draft PR.\n' > "$work/prompts/graphs.md"
  echo "  python: $PY_REAL ($("$PY_REAL" -c 'from importlib.metadata import version; print("langgraph", version("langgraph"))'))"
  rc=$(run_shim "$work" "$PY_REAL" "${FACTS[@]}" "${TRACED[@]}" EPITO_GRAPH=seat EPITO_PROMPT="You are the agent named graphs. Read prompts/graphs.md.")
  sed 's/^/  /' "$OUT"
  check "the graph ran, and the shim exited 0" "[ '$rc' = 0 ]"
  check "its steps are the run's turns, and its last message is the result" "result | grep -q '\"num_turns\": 2' && result | grep -q 'opened https://github.com/alexandrapaiz/epitome/pull/999'"
  check "the run's charter reached the graph, read from inside the clone" "grep -q 'charter prompts/graphs.md: # graphs' '$OUT'"
  check "so did the credential epito minted for this run" "grep -q 'GH_TOKEN=ghs_SMOKETOKEN000000000000000000000000' '$OUT'"
  check "and the trigger, so a graph can behave differently on a hook" "grep -q 'trigger cron' '$OUT'"

  step "1 (either spelling): langgraph.json may point at a compiled graph or a StateGraph"
  rc=$(run_shim "$work" "$PY_REAL" "${FACTS[@]}" EPITO_GRAPH=uncompiled EPITO_PROMPT="hello")
  check "an uncompiled StateGraph is compiled by the runtime, not by the author" "[ '$rc' = 0 ] && grep -q 'graph \"uncompiled\"' '$OUT' && result | grep -q '\"num_turns\": 2'"

  step "3: every node is a span in the RUN's trace, with no OpenTelemetry package installed"
  # In a file rather than inline: an assertion about nesting is worth reading,
  # and three levels of shell quoting is not.
  cat > "$ROOT/assert-nesting.py" <<'PYA'
import json, os, sys

spans = [json.loads(line) for line in open(sys.argv[1])]
trace_id, execute_span = sys.argv[2], sys.argv[3]
graph = [s for s in spans if s["name"].startswith("graph ")]
nodes = [s for s in spans if s["name"].startswith("node ")]
assert graph, "the graph filed no span at all"
assert graph[0]["traceId"] == trace_id, f'a span in the wrong trace: {graph[0]["traceId"]}'
assert graph[0]["parent"] == execute_span, f'the graph is not inside the run: {graph[0]["parent"]}'
assert [s["name"] for s in nodes] == ["node read_charter", "node open_pr"], nodes
assert all(s["parent"] == graph[0]["spanId"] for s in nodes), "a node is not under its graph"
assert all(s["service"] == "graphs" for s in spans), "the spans are the agent's work, not the runtime's"
print("   ", len(spans), "spans:", ", ".join(s["name"] for s in spans))
PYA
  check "the graph's span hangs off the run's execute span, and the nodes under it" "python3 '$ROOT/assert-nesting.py' '$SPANS' '$TRACE_ID' '$EXECUTE_SPAN'"
  check "and no span carries the run's credential" "! grep -qF 'ghs_SMOKETOKEN' '$SPANS'"

  step "4 (the graph's own failure): it raises, and the seat says so in one sentence"
  boom="$ROOT/boom"; cp -r "$CLI/test/fixtures/langgraph-real" "$boom"
  cat > "$boom/src/agent.py" <<'PYX'
from typing import Annotated, TypedDict
from langgraph.graph import END, START, StateGraph
from langgraph.graph.message import add_messages


class State(TypedDict):
    messages: Annotated[list, add_messages]


def node(state):
    raise RuntimeError("the agent's own bug, not the runtime's")


builder = StateGraph(State)
builder.add_node("node", node)
builder.add_edge(START, "node")
builder.add_edge("node", END)
graph = builder.compile()
PYX
  rc=$(run_shim "$boom" "$PY_REAL" "${FACTS[@]}" EPITO_GRAPH=seat EPITO_PROMPT="go")
  echo "  $(detail)"
  check "exit 3 is the graph raising, not the adapter refusing" "[ '$rc' = 3 ]"
  check "the reason is one sentence on the board, naming whose code it is" "detail | grep -q 'raised while running: RuntimeError' && detail | grep -q \"this is the agent's own code\""
else
  step "1: SKIPPED — langgraph is not importable by ${EPITO_PYTHON:-python3}"
  cat <<'MSG'
  The real-framework half of this test did not run. That is an unrun test, not
  a pass: it proves nothing about LangGraph on this machine.

    python3 -m venv /tmp/lgvenv && /tmp/lgvenv/bin/pip install langgraph
    EPITO_PYTHON=/tmp/lgvenv/bin/python bash test/smoke-langgraph.sh

  The duck-typed half below still runs, because the adapter imports nothing
  from the agent's language and so can be proved without the framework.
MSG
fi

step "2: the same contract, against a graph-shaped object and no framework at all"
stub="$ROOT/stub"; cp -r "$CLI/test/fixtures/langgraph-stub" "$stub"
rc=$(run_shim "$stub" python3 "${FACTS[@]}" "${TRACED[@]}" EPITO_PROMPT="You are the agent named graphs.")
sed 's/^/  /' "$OUT"
check "it runs with nothing installed: epito imports nothing from the agent's language" "[ '$rc' = 0 ] && result | grep -q '\"num_turns\": 2'"
check "one graph and no [runtime].graph is not ambiguous, so it just runs" "grep -q 'graph \"seat\" from ./src/agent.py:graph' '$OUT'"

step "4: every refusal names the rule, in the product's words, with the fix"
empty="$ROOT/empty"; mkdir -p "$empty"; echo "not a langgraph app" > "$empty/README.md"
rc=$(run_shim "$empty" python3 "${FACTS[@]}" EPITO_PROMPT=go); echo "  $(detail)"
check "no langgraph.json -> 2, and it offers the claude adapter as the alternative" "[ '$rc' = 2 ] && detail | grep -q 'looked for langgraph.json at the root' && detail | grep -q 'set \[runtime\].adapter = \"claude\"'"

two="$ROOT/two"; mkdir -p "$two/src"; cp "$CLI/test/fixtures/langgraph-stub/src/agent.py" "$two/src/"
printf '{"graphs": {"alpha": "./src/agent.py:graph", "beta": "./src/agent.py:graph"}}\n' > "$two/langgraph.json"
rc=$(run_shim "$two" python3 "${FACTS[@]}" EPITO_PROMPT=go); echo "  $(detail)"
check "two graphs and no [runtime].graph -> 2, naming both and one to pick" "[ '$rc' = 2 ] && detail | grep -q 'more than one graph (alpha, beta)' && detail | grep -q '\[runtime\].graph = \"alpha\"'"
rc=$(run_shim "$two" python3 "${FACTS[@]}" EPITO_GRAPH=gamma EPITO_PROMPT=go); echo "  $(detail)"
check "a [runtime].graph that is not in langgraph.json -> 2, listing what is" "[ '$rc' = 2 ] && detail | grep -q '\[runtime\].graph names \"gamma\"' && detail | grep -q 'declares alpha, beta'"

bad="$ROOT/bad"; mkdir -p "$bad"
printf '{"graphs": {"seat": "src/agent.py"}}\n' > "$bad/langgraph.json"
rc=$(run_shim "$bad" python3 "${FACTS[@]}" EPITO_PROMPT=go); echo "  $(detail)"
check "a spec that is not <file>:<attribute> -> 2, with the shape written out" "[ '$rc' = 2 ] && detail | grep -q 'which is not <file-or-module>:<attribute>'"

gone="$ROOT/gone"; mkdir -p "$gone"
printf '{"graphs": {"seat": "./src/nowhere.py:graph"}}\n' > "$gone/langgraph.json"
rc=$(run_shim "$gone" python3 "${FACTS[@]}" EPITO_PROMPT=go); echo "  $(detail)"
check "a file langgraph.json names but the repo does not have -> 2" "[ '$rc' = 2 ] && detail | grep -q 'that file is not in this repository'"

attr="$ROOT/attr"; mkdir -p "$attr/src"; cp "$CLI/test/fixtures/langgraph-stub/src/agent.py" "$attr/src/"
printf '{"graphs": {"seat": "./src/agent.py:workflow"}}\n' > "$attr/langgraph.json"
rc=$(run_shim "$attr" python3 "${FACTS[@]}" EPITO_PROMPT=go); echo "  $(detail)"
check "an attribute that is not there -> 2, listing what the file does export" "[ '$rc' = 2 ] && detail | grep -q 'has no \"workflow\" in it' && detail | grep -q 'Graph, graph'"

notgraph="$ROOT/notgraph"; mkdir -p "$notgraph/src"
printf 'graph = "this is a string, not a graph"\n' > "$notgraph/src/agent.py"
printf '{"graphs": {"seat": "./src/agent.py:graph"}}\n' > "$notgraph/langgraph.json"
rc=$(run_shim "$notgraph" python3 "${FACTS[@]}" EPITO_PROMPT=go); echo "  $(detail)"
check "an object that is not a graph -> 2, naming what it actually is" "[ '$rc' = 2 ] && detail | grep -q 'is a str, which is not a graph this runtime can run'"

raises="$ROOT/raises"; mkdir -p "$raises/src"
printf 'import nonexistent_dependency\ngraph = None\n' > "$raises/src/agent.py"
printf '{"graphs": {"seat": "./src/agent.py:graph"}}\n' > "$raises/langgraph.json"
rc=$(run_shim "$raises" python3 "${FACTS[@]}" EPITO_PROMPT=go); echo "  $(detail)"
check "a missing dependency -> 2, and says whose job installing it is" "[ '$rc' = 2 ] && detail | grep -q 'raised ModuleNotFoundError' && detail | grep -q 'the runtime runs it, it does not install it'"

step "3 (off means off): no endpoint, no spans, no complaint"
before=$(wc -l < "$SPANS" 2>/dev/null || echo 0)
rc=$(run_shim "$stub" python3 "${FACTS[@]}" EPITO_PROMPT=go)
after=$(wc -l < "$SPANS" 2>/dev/null || echo 0)
check "a run with no OTEL_EXPORTER_OTLP_ENDPOINT files nothing, and says nothing about it" "[ '$rc' = 0 ] && [ '$before' = '$after' ] && ! grep -q '# trace' '$OUT'"

printf '\n%s\n' "-----------------------------------------------"
printf 'smoke: %d ok, %d failed\n' "$pass" "$fail"
[ "$fail" = 0 ] || exit 1
