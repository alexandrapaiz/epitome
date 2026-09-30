# Cycle 1 amendment 2 — owner re-bets again, 2026-09-26 synchronous session

The first amendment (2026-09-21-cycle-1-amendment.md) re-bet cycle 1 to
the resident runtime and a reduced identity slice. Five days later the
owner opened a synchronous work window and, relayed by the chair and
staged by the PM in a dispatch queue (PR #12), gave the engineer seat
four priorities in her own order. The engineer built all four, stacked,
as one branch chain. This file was drafted 2026-09-28 (PR #22, then
unmerged) because the cycle file is the board, and a board that still
showed only amendment 1's bets while four more had shipped as draft PRs
was exactly the "high-level-only board" this charter forbids. This
2026-09-30 revision closes it out: the stack landed.

## The bets (amended again, in the owner's order) — status 2026-09-30

**1. epitod v1 on Temporal** — the runtime engine, self-hosted on the
company host; `epitod` becomes its face (owner directive 2026-09-25,
recorded as a press-release-first design in
docs/prfaq/epitod-v1-temporal.md). Supersedes epitod v0's hand-rolled
scheduler/mutex/retry code from amendment 1's bet 1 — a port, not a
parallel track. Built as PR #11, then #14 → #15 → #16 → #17 → #21
stacked on top. **Merged**: PR #24 (2026-09-30, `engineer/2026-09-29-
land-the-stack`) merged main into the tip of the chain and landed the
whole thing in one merge commit, closing #11/#14/#15/#16/#17/#21 as
reachable from main. Smoke evidence from #24 itself: 300 assertions
across four suites (unit, smoke-temporal, smoke-langgraph,
provision-host), all green, on a box with Temporal 1.9.1 and LangGraph
1.2.12 installed.

**2. Identity, natively on the v1 engine** — the per-run mint moves
inside Temporal's execute activity, then the clone itself mints and
commits as the bot. This is amendment 1's bet 2, rehomed to the new
engine. Built as PR #14 (stacked on #11) and #15 (stacked on #14).
**Merged** via #24, same as above; `cli/src/token.js` and the identity
mint inside `cli/src/temporal/activities.js` are on main now.

**3. The board** — an owned task manager, replacing the Linear mirror
this charter still names (the Shape Up-vs-Scrum trial's Linear mirror
is being superseded here, not completed — its own charter patch is
still ExO's to propose, not self-applied). Built as PR #16 (stacked on
#15). **Merged** via #24; `cli/src/board.js` and `cli/src/routes.js`
are on main. Note for the record: the board shipped without its
Working Backwards PR/FAQ ever merging — a draft
(`docs/prfaq/task-board-v0.md`) was written in PR #12 (2026-09-26,
still open) but the board was built and landed before that draft was
reviewed. The draft is now stale on its own speculative points (it asks
which storage engine to use; the shipped system settled that question
in code, and `docs/standards/pm.md` §14, vendored 2026-09-27, documents
the live API). Recommend closing #12 rather than merging a PR/FAQ that
describes a system already superseded by what actually shipped — noted
here so the retro grades this gap honestly rather than losing it.

**4. LangGraph adapter with tracing** — a seat that is not a Claude
session, runs visible in a trace backend. Built as PR #17 (stacked on
#16). **Merged** via #24; `cli/adapters/langgraph_run.py` and
`cli/src/lib/trace.js` (hand-rolled OTLP, not the OpenTelemetry SDK —
decided and reasoned in `docs/decisions.md`) are on main. A further,
separate PR (#25, chair, open, unmerged as of this run) adds a Langfuse
destination for every seat workflow's own trace — additive to this bet,
not part of it.

**5. The router** — a seat declares its roads, the runtime takes the
detour. Built as PR #21 (stacked on #17). **Merged** via #24;
`cli/src/lib/router.js` is on main. Own-model hosting (vLLM) was named
and dropped the same session; it was never a bet.

## Why this was a bet-swap, not a circuit-breaker failure

This charter's rule is that anything urgent goes to the owner as a
proposed bet-swap, her call alone. That call was made in the room, by
the owner herself — the PM's job was only to record it where the board
lives instead of leaving it scattered across a dispatch queue and five
PR descriptions. Nothing here was smuggled past the betting table; the
table moved to a synchronous window that night.

## The standing risk this amendment named (2026-09-28) — now retired

**A six-PR-deep unmerged stack.** Retired: PR #24 landed it at the tip
in one merge, 2026-09-30T01:55:51Z UTC.

**The identity slice built five times.** Amendment 1's bet 2
(`epito token`) was independently implemented against the superseded v0
engine three separate times (#9, #10, #20) and correctly, inside the v1
stack, a fourth and fifth time (#14, #15) — the fifth (#23) opened
2026-09-29, a day *after* this file's first draft (#22) had already
named the duplication in an unmerged PR nothing else read. All four
main-based duplicates (#9, #10, #20, #23) are now **closed, not
merged** — the owner closed them by hand between 2026-09-30T01:55:53Z
and 01:58:11Z, immediately after merging #24. Retired as a standing
risk, but the mechanism that produced it (a card that reads "not done"
until a branch reaches main, with no run ever surveying open PRs before
building) is now Incident 2 in `docs/agents/incidents.md` — filed by
the exo seat, PR #26, draft and unratified as of this run. That PR also
proposes two lessons (L9, L10, both `portable: yes`) and three
unratified charter patches, including one for this seat: draw hill
positions from `gh pr list --state all` (number, title, state,
baseRefName) rather than from cards, and report a branch chain deeper
than two as one queue named by its members' states. This run's survey
above already follows that practice in substance — every bet's status
here is cited by PR number and merge event, not read off a backlog
card — without self-ratifying the patch, which stays the owner's or
ExO's to apply to `prompts/pm-agent.md`.

## What's open now that the stack has landed (survey at this run, 2026-09-30)

- **PR #25** (chair, `chair/langfuse-traces`, open, not draft) — Langfuse
  as a trace destination for every seat workflow. Additive to bet 4,
  outside the five named bets.
- **PR #26** (exo, `exo/2026-09-30-duplicate-build-incident`, draft) —
  Incident 2 write-up, lessons L9/L10, and three unratified charter
  patches (pm, okr, exo). Not this seat's to ratify.
- **PR #28** (engineer, `engineer/2026-09-30-freeze-manifest-v0-1`,
  draft) — the next Now backlog card (manifest spec v0.1 freeze), taken
  up correctly: its own PR body records a PR survey that found both
  amendments' bets already built and merged, and with two days left in
  the cycle it took the next groomed card rather than opening new bet
  scope. Not a bet; the backlog item predates cycle 1.
- **PR #29** (chair, `chair/pm-merges`, open, not draft) — decision 041,
  proposing this seat gain conditional merge authority plus failed-run
  triage duties. Unmerged. This charter's rule that the PM never merges
  its own PR is absolute regardless of that proposal until the owner
  merges it; noted here, not acted on.

## What the cooldown retro (2026-10-05/06) should grade against

Not amendment 1's bets alone, and not amendment 2's five bets in
isolation either. Score three things: amendment 1 (shipped, then
superseded, itself a form of waste worth naming), amendment 2 (shipped,
landed four days after the stack finished building — the lag itself
is the finding, see Incident 2), and the process gap the lag caused
(five duplicate builds of one card, a board that read the wrong bets
for six days, a PR/FAQ that shipped after its feature). The next
betting table (cycle 2, after cooldown) should also decide the MCP
server (never bet this cycle, still queued unchanged) and whatever the
owner rules on PR #26's proposed lessons and patches.
