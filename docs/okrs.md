# OKRs, Q4 2026 (Oct-Dec)

Maintained by the OKR seat (`prompts/okr-agent.md`). This is the first
`docs/okrs.md` this repo has ever recorded: the all-hands counsel at
`docs/allhands/2026-09-20-okr.md` proposed a mission and a Q4 objective
set on founding week, the owner signed the mission the same day
(ADR-14), and no seat ever turned the proposal into a graded, living
document until this run, at the actual quarter turn. This run adopts
that proposal's three objectives as Q4's, unchanged in shape, and
grades all nine key results against what is actually in the repo
today, ten days later.

## If you only read one section, read this one

Nine key results, three graded above 0.5, six graded 0.0 with a named
reason. The one item that should worry the owner most is not a zero,
it is which zero: **O2 KR1, the passport**, has not one line of code
anywhere in this repo, and ADR-12's own tripwire calls it the thing
that "must be visible before their next credential release, not
after." Everything else zeroed here is a sequencing question. This one
is a clock the company does not control.

| Objective | KR | Tag | Grade | One line |
|---|---|---|---|---|
| O1 wedge exists | KR1 mint + deploy | Committed | **0.5** | minting is real and tested, `deploy` still doesn't provision the App |
| O1 wedge exists | KR2 alexandria migrated | Committed | **0.0** | not started, three unchecked backlog lines |
| O1 wedge exists | KR3 15-min benchmark | Aspirational | **0.0** | no `docs/benchmark/` directory exists |
| O2 moat | KR1 passport | Committed | **0.0** | no passport code anywhere in the repo |
| O2 moat | KR2 foreign framework, own `[bot]` | Committed | **0.85** | shipped, tested against real LangGraph, in `main` |
| O2 moat | KR3 one manifest, two chat backends | Aspirational | **0.1** | Slack is a one-way webhook, not an identity |
| O3 demand counted | KR1 three HQ seats upgraded | Committed | **0.0*** | *no evidence this repo can see, not a claim it didn't happen |
| O3 demand counted | KR2 five non-owner users | Aspirational | **0.0** | no `docs/users.md` |
| O3 demand counted | KR3 npm-installable | Committed | **0.0** | `epito` returns 404 on the npm registry, no MCP server code |

The evidence rule this seat runs on, from the charter: shipped files,
closed cards, and run logs, never claims. Where that rule produces an
uncomfortable grade next to real engineering effort (O1 KR2, all of
O3), the discomfort is the point. It means the last ten days of work,
real as it was, did not point at the KRs that were supposed to prove
the mission.

## Mission (held, never edited here)

> Give every agent, whoever built it, a self its owner holds and every
> platform honors.

Signed by the owner 2026-09-20, `docs/vision.md` §0. This seat holds
this line and grades against it. It never edits it.

## Q4 2026 objectives

### O1. An agent minted from one file acts on GitHub as itself (the wedge exists)

**KR1, Committed, grade 0.5.** "`epito deploy` provisions a GitHub App
principal and `epito token` returns a short-lived token that is never
written to disk."

Evidence for the half that shipped: `cli/src/lib/identity.js` signs a
short-lived RS256 JWT as the App, exchanges it for an installation
token scoped to exactly `[identity].scopes` via `SCOPE_MAP`, and hands
the token back in memory only, never to disk. `cli/src/token.js`
exposes it as `epito token <name>`. `cli/test/unit.mjs` passes 85/85
assertions covering the mint, the scope-to-permission mapping, and the
retry/permanent-failure distinction (`npm test` in `cli/`, re-run by
this seat this run). PR #24 (merged 2026-09-29) additionally shows 158
smoke-test assertions of this mint running end to end on the Temporal
engine.

Evidence for the half that has not shipped: "provisions" is the verb
in the KR, and nothing provisions. `identity.js`'s own header comment
says `.epito/principals.json` and `.epito/keys/<agent>.pem` are files
"`epito deploy` ... reads", meaning an operator creates the GitHub App
by hand today (the deploy README lists five manual steps), and cycle
1's own scope 1a/1b ("Route spike + ADR", "Principal provisioning")
was split out and never built, confirmed both by the open idea in
`docs/ideas.md` ("`epito deploy` creates the App instead of an operator
creating it by hand ... was never built") and by `docs/backlog.md`'s
own line: "As of 2026-09-24: no code for it in `cli/src`."

**Named reason for below 1.0:** the KR bundles two things
("provisions" and "mints") that turned out to be separable, and only
the second shipped. Grade reflects that split rather than rounding up
because the harder half is missing.

**KR2, Committed, grade 0.0.** "One alexandria seat runs on epito.me
and its ADR-27 hand-wiring is deleted." `docs/backlog.md` lines 39-44
list all three dogfood-migration steps unchecked. No PR in this repo
touches the alexandria repo. No evidence, grade 0.0.

**KR3, Aspirational, grade 0.0.** "Fresh clone to first commit-as-bot
in under 15 minutes, evidenced by a timed run log under
`docs/benchmark/`." That directory does not exist. No evidence, grade
0.0. (Aspirational KRs are healthy at 0.7. This one has not been
attempted at all, which is a different thing than attempted and
short.)

### O2. One self crosses walls, demonstrated, not claimed (the moat)

**KR1, Committed, grade 0.0.** "The passport prototype: a third party,
given only the agent-card URL, verifies that a GitHub `[bot]` and a
Slack bot user are one agent." A repo-wide search for `passport` across
every source file returns nothing. No `agent-card.json`, no verify
script, no signed card. No evidence, grade 0.0. This is also the KR
ADR-10 and ADR-12 both name as owner-favored and time-sensitive
("already adopted... I like the concept of an agent passport";
ADR-12's tripwire: "the outdo arm must be visible before their next
credential release, not after"). Ten days in, it is invisible.

**KR2, Committed, grade 0.85.** "One agent we did not write (LangGraph,
n8n, or OpenClaw) acts on GitHub as its own `[bot]` through `epito
token` with zero changes to its own code." This shipped. ADR-17
specifies the adapter contract. `cli/adapters/langgraph_run.py` is a
stdlib-only Python shim that reads the agent's own `langgraph.json`
unmodified and drives it once. PR #24's smoke-langgraph run (22
assertions, re-verified as passing in this run's own `npm test`, though
this box lacks a `langgraph`-importable Python so the live smoke pass
itself was not re-executed here, only the surrounding unit suite) shows
specifically: "the run's charter reached the graph, read from inside
the clone" and "so did the credential epito minted for this run", with
"an uncompiled StateGraph is compiled by the runtime, not by the
author" confirming the framework's own file was never touched. This is
the strongest, most literal evidence-to-KR match in the whole document.

**Named reason for below 1.0:** the transcript that proves this lives
in a merged PR body (#24), not as a standing artifact in the repo tree
the way the KR's evidence line ("transcript in a fresh clone")
describes, and this run could not re-execute the live smoke pass
itself for lack of a local `langgraph` install. The code and the unit
coverage are real. A fully independent re-run by this seat is not.

**KR3, Aspirational, grade 0.1.** "The same manifest posts as itself on
two chat platforms with only the backend name changed." `cli/src/lib/slack.js`
exists, but by its own header comment it "posts; it never reads" over
an incoming webhook URL named in `[runtime].env`. That is a
notification line, not a bot-user principal (ADR-7's own description:
"bot user as the principal, workspace OAuth install"), and there is
exactly one backend, not two. Some scaffolding exists (the
`slack_webhook_env` per-agent routing), which is why this reads 0.1 and
not 0.0, but the KR describes an identity crossing platforms and what
shipped is a webhook.

### O3. Someone other than the owner runs an agent on it (demand is counted, not asserted)

**KR1, Committed, grade 0.0\*.** "Three Alexandra Systems HQ seats
upgraded to real principals that can be @-mentioned." Evidence for this
KR was always specified to live in the HQ repo (its manifests,
`audit.jsonl` lines), not this one. This seat has no read access to
that repo from this environment (`gh api repos/alexandra-systems`
returns 404 under this token). **The asterisk matters: this 0.0 is "no
evidence reachable from here," not "confirmed not done."** If the OKR
seat is meant to grade this KR at all, it needs either read access to
the HQ repo or a copy of the relevant evidence mirrored into this one.
Today it has neither, and that gap is itself worth the owner's
attention since it makes this KR ungradeable by design.

**KR2, Aspirational, grade 0.0.** "Five agents deployed by people who
are not the owner, evidenced by `docs/users.md`." That file does not
exist. No evidence, grade 0.0.

**KR3, Committed, grade 0.0.** "`epito` and the MCP server installable
by a stranger: tagged npm release, `npx`-runnable server, editor-skill
smoke demo transcript." `git tag -l` and `gh release list` both return
nothing. `npm view epito version` 404s (the registry has an unrelated
package called `epitome` at 0.6.2, not this product). A repo-wide
search for `mcp` under `cli/src` returns nothing: the MCP server itself
was never started, despite being shaped and bet in cycle 1
(`docs/pitches/epito-mcp-server.md`). No evidence, grade 0.0.

## Benchmark (the mission's proxies)

The four proxies the all-hands counsel set on founding night, re-read
today:

| Proxy | Reading today |
|---|---|
| Minutes from `epito init` to first commit-as-bot | Unmeasured, no `docs/benchmark/` run log |
| Count of agents minted by non-owners (HQ seats excluded) | 0, no `docs/users.md` |
| Platforms one agent is verified on through its passport | 0, no passport exists to verify anything |
| Lines of ADR-27 plumbing deleted from alexandria | 0, migration unstarted |

All four still read zero, exactly as the founding counsel logged them
ten days ago. That flat line is itself a finding: real engineering
happened in those ten days (ADR-15 through ADR-19: the Temporal engine,
the board, the LangGraph adapter, tracing, the router), and none of it
moves a single one of these four numbers, because none of the four was
built to measure runtime or portability engineering, only the wedge
and the dogfood proof.

**Proposed fifth proxy, this seat's to propose, the owner's to accept
or reject:** count of agent frameworks the company did not write that
have been proven, with a real minted credential, to act on an outside
platform as themselves. Reading today: **1** (LangGraph, O2 KR2 above).
This is the one number in the whole document that moved this cycle,
and the current four proxies have no way to say so.

## Drift, stated bluntly

1. **The passport is the single most owner-flagged item with the least
   work.** ADR-10 records the owner's favorite among four portability
   proposals and ADR-12 turns it into a standing, pre-authorized,
   out-of-cycle escalation the moment LangChain ships a competing
   mechanism. Ten days on, `passport` matches nothing in this repo. This
   is not a mission drift (nobody built the wrong thing), it is a
   priority-inversion risk: the item with a external clock on it got zero
   hours while five ADRs of runtime engineering happened around it.
2. **O1 KR2 and all of O3 have had zero engineering hours while the
   runtime got rebuilt underneath them.** ADR-15 through ADR-19 (Temporal,
   the board, LangGraph, tracing, the router) were all owner-directed at
   the 2026-09-26 synchronous session, so none of this is a seat acting
   off-mission. But it means the roadmap that actually got built for ten
   days is not the roadmap these OKRs describe, and nobody has said so in
   writing until this run. The dogfood migration (O1 KR2) is explicitly
   "the launch post" per `docs/vision.md`'s origin section. It has three
   unchecked backlog lines and no code.
3. **Not drift, but adjacent and worth naming once:** the identity/token
   slice this document grades in O1 KR1 was independently built five
   times (PRs #9, #10, #20, #14/#15, #23) before the engineer seat's PR #24
   landed one working copy. The ExO seat's incident register and lessons
   already own that failure and its fix (an in-flight-work check, filed in
   `docs/ideas.md`). This document does not re-grade it, it only notes that
   the KR1 grade above is the final, landed artifact, not the churn that
   preceded it.
4. **No mission drift found.** Every shipped artifact graded above (the
   mint, the LangGraph adapter, the router, the board) reads as
   identity-and-runtime work inside the envelope ADR-10 draws, not as an
   opinion on any agent's insides. The gap in this document is coverage
   and sequencing, not direction.

## For whoever reads this next

The central problem this document exists to keep visible: **a KR without
a file, a merged PR, or a run log behind it is a 0.0, no matter how much
real work surrounds it.** That rule produced uncomfortable grades next to
real ten-day effort, on purpose. The design test for the next OKR run is
the same one this run used: before writing a grade, find the artifact: a
path that exists, a PR number that merged, a test that passed when you ran
it yourself. If you cannot find it, the grade is 0.0 and the reason is
"no evidence," in those words.
