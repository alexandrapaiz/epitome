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
manifest that no longer matches the `--max-turns`, the model or the route chain
its workflow passes is a dogfood that proves nothing.

| Seat | Schedule | Road(s) to a model | Turn cap | Translated from |
|---|---|---|---|---|
| `engineer` | `46 11,23 * * *` | claude-opus-5 | 150 | `agent-engineer.yml` |
| `pm` | `0 12 * * 1` | kimi-k2.7-code → claude-sonnet-5 | 100 | `agent-pm.yml` |
| `market` | `0 12 * * 5` | kimi-k2.7-code → claude-sonnet-5 | 100 | `agent-market.yml` |
| `okr` | `0 12 1 * *` | kimi-k2.7-code → claude-sonnet-5 | 80 | `agent-okr.yml` |
| `exo` | none — presence only | claude-opus-5 | 120 | `agent-exo.yml` |

The arrow is a route chain: the cheap road first, the subscription under it,
tried in that order (ADR-19). Three seats have one; two do not, because their
workflows do not either.

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
not an exotic one. It has since answered a second, in the other direction: the
open road below is a question this roster could not stop asking until the spec
grew a field for it.

**`env` lists only what a charter actually reads.** The workflows hand
`BOARD_API_URL` and `BOARD_RUNTIME_TOKEN` to all five seats; only `pm` lists
them, because the board API is in the PM standard that only the PM charter
reads (docs/standards/pm.md), and only `pm` lists `LINEAR_API_KEY`. Copying
every name into every manifest would make `env` a record of what Actions
happens to inject rather than of what the agent needs, and rule 2's spirit —
the ceiling is declared, and widening it is a diff — is worth more than the
convenience.

## The open road: the finding that became a field

**This was the one thing the roster could not say, and now it says it.**
`pm`, `market` and `okr` each have a second, cheaper road in Actions:
`ANTHROPIC_BASE_URL` set from the `OPENROUTE_BASE_URL` secret, gated on the
`OPEN_ROUTING` repo variable. `[[runtime.route]]` was exactly the field for it
— except `base_url` was a **literal URL**, and this company holds its endpoint
as a secret, so writing the road here meant putting in git the one value that
is deliberately not in git. The three manifests declared one road each and said
so in a comment, which was honest about what they could express and not about
what the seats do.

That is what an open question is for. It was recorded in `spec/manifest.md` on
the day of the freeze, this roster is what proved it needed answering, and
**spec v0.2 answered it on 2026-10-07 with one field, `base_url_env`** — a
name, beside `token_env`, under the same rule. The three manifests now carry
the road they actually take, and `epito routes` is what reads it back per box.
The whole path, question → evidence → spec change → code, is the freeze's
process working rather than a field invented on the spot.

**Two things in those workflows still do not translate, and neither is a
missing field.**

`vars.OPEN_ROUTING` is a **manual kill switch** a human flips, and its comment
says why — "every Kimi attempt so far has died at turn one (2026-09-21 x2,
2026-09-24 epitome pm) and each doomed attempt burned ~3 minutes before the
Claude fallback took over." ADR-19's rule is *fall back only when the attempt
ended with no pull request and at most one turn*, which is that failure
exactly: the runtime would have taken the detour by itself, which is the point
of it being in the runtime. On a box the switch is removing the key, and a road
whose credential is absent is skipped by rule, out loud, in the run log — so
the gate exists and is not a field.

`vars.OPENROUTE_MODEL || 'kimi-k2.7-code'` is an **override with a default**.
The manifests write the default, because which model a seat runs on is the
thing a manifest is for and an override is a box talking. A company that wants
the other model changes three files and the change is a diff — which is rule
2's spirit applied to the model the way it already applies to scopes.

**The tripwire and the Slack post**, for completeness: both workflows'
trailing steps are the runtime's own job on epitod: it files each run's report to the board and posts
the one-line window itself (`slack_webhook_env`, `epito board`). Nothing in a
manifest replaces them because nothing has to.

## These files do not retire the workflows

`.github/workflows/agent-*.yml` are still what runs these five seats today,
and this directory changes nothing about that. The roster is step 1 of the
dogfood — the seats *described* — and it is deliberately separable from step 2,
deleting the hand-wiring, which cannot happen until a box is actually running
them (docs/backlog.md; ADR-23).
