"""A graph-shaped object with no LangGraph installed.

The adapter is duck-typed on purpose (ADR-17: epito imports nothing from the
agent's language), so this fixture proves the whole spawn contract — the
langgraph.json resolution, the prompt, the node spans, the result contract —
on a machine with no pip install. cli/test/fixtures/langgraph-real is the same
shape against the real framework.
"""
import os


class Graph:
    def stream(self, payload, config=None, stream_mode="updates"):
        prompt = payload["messages"][-1]["content"]
        yield {"read_charter": {"messages": [{"role": "assistant", "content":
                f"charter={os.environ.get('EPITO_CHARTER')} trigger={os.environ.get('EPITO_TRIGGER')}"}]}}
        yield {"open_pr": {"messages": [{"role": "assistant", "content":
                f"{os.environ.get('EPITO_STUB_PR', 'https://github.com/acme/roster/pull/777')} "
                f"(thread {config['configurable']['thread_id']}, {len(prompt)} chars of prompt, "
                f"token={(os.environ.get('GH_TOKEN') or 'none')})"}]}}


graph = Graph()
