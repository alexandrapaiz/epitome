"""A real LangGraph app, of the shape epito hosts: it was not written for epito.

Two nodes and no model call, so the test costs nothing and needs no key — what
is being proved is that the runtime runs a LangGraph graph, mints its identity,
and traces its nodes, not that an LLM answers.

`graph` is compiled and `builder` is not: langgraph.json declares both, because
the adapter accepts either (a StateGraph is compiled by the shim) and a smoke
test should prove both spellings.
"""
import os
from typing import Annotated, TypedDict

from langgraph.graph import END, START, StateGraph
from langgraph.graph.message import add_messages


class State(TypedDict):
    messages: Annotated[list, add_messages]


def read_charter(state: State) -> dict:
    charter = os.environ.get("EPITO_CHARTER", "(none)")
    body = open(charter, encoding="utf-8").read().strip().splitlines()[0] if os.path.exists(charter) else "(missing)"
    prompt = getattr(state["messages"][0], "content", "")
    # What the run was woken with, as the graph received it: a real seat would
    # act on this, and a test needs to be able to read that it arrived.
    tail = prompt.split("Event payload for this run")[-1].strip().replace("\n", " ")[:120] if "Event payload" in prompt else "(no payload)"
    return {"messages": [{"role": "assistant", "content":
        f"charter {charter}: {body} | prompt {len(prompt)} chars | payload: {tail}"}]}


def open_pr(state: State) -> dict:
    # A real seat would call `gh` with the token epito minted for this run. This
    # one says what it was handed, which is what the test needs to read — and
    # only when a test asked (EPITO_STUB_ECHO_TOKEN), because a fixture that
    # prints $GH_TOKEN unasked is a footgun on a box that has a real one.
    token = (os.environ.get("GH_TOKEN", "none") if os.environ.get("EPITO_STUB_ECHO_TOKEN")
             else ("(set, not echoed)" if os.environ.get("GH_TOKEN") else "none"))
    pr = os.environ.get("EPITO_STUB_PR", "https://github.com/alexandrapaiz/epitome/pull/999")
    return {"messages": [{"role": "assistant", "content":
        f"opened {pr} as {os.environ.get('EPITO_AGENT')} (trigger {os.environ.get('EPITO_TRIGGER')}, "
        f"GH_TOKEN={token}, {len(state['messages'])} message(s) in)"}]}


builder = StateGraph(State)
builder.add_node("read_charter", read_charter)
builder.add_node("open_pr", open_pr)
builder.add_edge(START, "read_charter")
builder.add_edge("read_charter", "open_pr")
builder.add_edge("open_pr", END)

graph = builder.compile()
