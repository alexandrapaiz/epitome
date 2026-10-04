# The roster: epito.me's own seats

Five `agent.toml` files, one per seat this company runs. This is the dogfood
(docs/backlog.md, "Now" → dogfood migration): the product describing its own
org instead of 150 lines of YAML per seat.

```bash
epito validate agents          # is this roster good — no engine needed to answer
epito routes agents            # which road each seat takes on THIS box
epito run agents --dry-run     # what the runtime would register, and nothing else
epito ps agents                # the roster, read back from the engine
```

The first two need nothing but the files. The last two connect to Temporal
first and refuse by name when it is not answering — which is why `epito
validate agents` leads: it is the question you can ask standing anywhere,
and its closing line tells you whether the other two would work from here
(ADR-24).

Each file was translated **field by field** from the workflow beside it, and
`cli/test/smoke-roster.sh` asserts the translation has not drifted — a
manifest that no longer matches the `--model` and `--max-turns` its workflow
passes is a dogfood that proves nothing.

| Seat | Schedule | Model | Turn cap | Translated from |
|---|---|---|---|---|
| `engineer` | `46 11,23 * * *` | claude-opus-5 | 150 | `agent-engineer.yml` |
| `pm` | `0 12 * * 1` | claude-sonnet-5 | 100 | `agent-pm.yml` |
| `market` | `0 12 * * 5` | claude-sonnet-5 | 100 | `agent-market.yml` |
| `okr` | `0 12 1 * *` | claude-sonnet-5 | 80 | `agent-okr.yml` |
| `exo` | none — presence only | claude-opus-5 | 120 | `agent-exo.yml` |

## Three things the translation had to decide

**Two crons became one.** The engineer's workflow carries two `- cron:`
entries, 11:46 and 23:46 UTC (owner directive 2026-09-24: engineers run twice
a day). That is one schedule written twice; cron's hour field takes a list, so
the manifest says `46 11,23 * * *`. `epito run --dry-run` registers one
schedule for it, which is what Actions does too.

**`workflow_dispatch` became `webhook = true`.** Every one of the five
workflows can be fired by hand as well as by its clock, and on the runtime the
thing that fires a seat by hand is the ingress: `POST /hooks/<name>`. So four
seats carry both triggers and `exo` carries only the second — its `schedule:`
block is commented out in its workflow ("uncomment only after a supervised
smoke run"), and its owner's standing instruction is "exo agent should launch
whenever i fine tune", which is an event and not a clock.

That makes this roster the first real answer to one of the spec's open
questions — *whether `[trigger]` combinations compose, "which v0.1 permits and
no shape yet uses"*. They compose, and four of this company's five seats need
them to: a seat that is both scheduled and hand-pokeable is the ordinary case,
not an exotic one.

**`env` lists only what a charter actually reads.** The workflows hand
`BOARD_API_URL` and `BOARD_RUNTIME_TOKEN` to all five seats; only `pm` lists
them, because the board API is in the PM standard that only the PM charter
reads (docs/standards/pm.md), and only `pm` lists `LINEAR_API_KEY`. Copying
every name into every manifest would make `env` a record of what Actions
happens to inject rather than of what the agent needs, and rule 2's spirit —
the ceiling is declared, and widening it is a diff — is worth more than the
convenience.

## What did not translate, and why that is a finding and not an omission

**The open road.** `pm`, `market` and `okr` each have a second, cheaper road
in Actions: `ANTHROPIC_BASE_URL` set from the `OPENROUTE_BASE_URL` secret,
gated on the `OPEN_ROUTING` repo variable. `[[runtime.route]]` is exactly the
field for that — except `base_url` is a **literal URL**, and this company
holds its endpoint as a secret. There is no `base_url_env`, so the road cannot
be written here without putting a value in git that is deliberately not in
git. The three manifests therefore declare one road each, which is honest
about what they can express and not about what the seats do.

This is now an open question in `spec/manifest.md` rather than a field
invented on the spot: v0.1 is frozen, and the freeze's whole point is that new
fields go through a question and a spec change before code.

Worth recording beside it: the Actions gate is a **manual variable** a human
flips, and its comment says why — "every Kimi attempt so far has died at turn
one (2026-09-21 x2, 2026-09-24 epitome pm) and each doomed attempt burned ~3
minutes before the Claude fallback took over." ADR-19's rule is *fall back
only when the attempt ended with no pull request and at most one turn*, which
is that failure exactly. The runtime would have taken the detour by itself.

**The tripwire and the Slack post.** Both workflows' trailing steps are the
runtime's own job on epitod: it files each run's report to the board and posts
the one-line window itself (`slack_webhook_env`, `epito board`). Nothing in a
manifest replaces them because nothing has to.

## These files do not retire the workflows

`.github/workflows/agent-*.yml` are still what runs these five seats today,
and this directory changes nothing about that. The roster is step 1 of the
dogfood — the seats *described* — and it is deliberately separable from step 2,
deleting the hand-wiring, which cannot happen until a box is actually running
them (docs/backlog.md; ADR-23).
