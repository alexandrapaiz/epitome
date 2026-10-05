# Betting memo — cycle 2 (2026-10-07 → 2026-10-18, proposed dates)

Written 2026-10-05 by the PM seat, at cooldown, per
docs/briefings/2026-09-18-cycle-1-briefing.md §2 ("cycle-2 betting
memo due 10-05"). From cycle 2 the standard flow applies
(prompts/pm-agent.md, ADR-5): this memo proposes, the owner bets by
merging. Cooldown is 2026-10-05/06. If this merges on schedule, cycle
2 opens 2026-10-07 and runs two weeks to 2026-10-18, cooldown
2026-10-19/20. The dates are this seat's proposal, not yet a
commitment.

Raw material: docs/decisions.md (ADR-7, ADR-9, ADR-10, ADR-11,
ADR-12), docs/design/portability-proposals.md (the chair's four
proposals), docs/allhands/2026-09-20-strategy.md (owner rulings
R1 through R5), and the cycle-1 retro (docs/cycles/2026-09-21-cycle-1-retro.md,
this seat's own prior PR, still open) for what already shipped
underneath these bets without being asked for.

## Pitches considered

| Pitch | Appetite | Bet? |
|-------|----------|------|
| slack-identity-v0 | Big batch (full cycle) | **Recommended yes** |
| passport-v0-github | Small batch (3 runs) | **Recommended yes** |
| epito-mcp-server (carried from cycle 1, unchanged) | Small batch (3 runs) | **Recommended no, third time** |

## Bets recommended

1. **slack-identity-v0.** ADR-7 named Slack integration #2 the day
   before cycle 1 opened and explicitly deferred its pitch to cycle 2.
   ADR-11 names HQ's own seats as the first consumer, upgrading from
   the post-only webhook (`cli/src/lib/slack.js`) they run on today to
   a real, @-mentionable principal. The risk is genuine (Slack's
   app-manifest and OAuth mechanics are unverified, the same kind of
   unknown cycle 1's GitHub leg carried), but the pattern is proven
   once already: ADR-20 shipped the app-manifest flow, callback
   handling, and token minting for GitHub in cycle 1, on `main` as of
   today. One platform's unknowns, not two. Full appetite because
   it's this cycle's one real risk, the same shape as cycle 1's bet 1.

2. **passport-v0-github.** The owner's own favorite proposal (ADR-10:
   "I like the concept of an agent passport"), pulled forward in
   priority by her own ruling, and now cheap: it signs a claim with a
   GitHub App key that ADR-20 already put on disk for every deployed
   agent. Scoped to GitHub only, deliberately. The two-platform proof
   market wants depends on bet 1 landing, and betting a dependent
   pitch is exactly what cycle 1's circuit breaker exists to forbid
   (it declined runtime-v0-actions for the same reason). Pairs with
   bet 1 the way cycle 1 paired a risky big batch with a sure small
   one, except this small batch is strategically distinctive rather
   than merely safe.

## Not bet, and why that is not clean this time

- **epito-mcp-server.** Shaped 2026-09-18, bet in the original
  cycle-1 memo, then dropped the same week by the owner's runtime
  re-bet (amendment, 2026-09-20) with the note "moves to cycle 2
  unchanged." This is now the second cycle in a row it would be
  passed over. The honest case against betting it a third time: it
  only repackages code that already ships (no unknowns, no strategic
  signal pulling it forward the way ADR-10 pulls the passport), while
  Slack and the passport both carry direct owner rulings naming them
  ahead of it. The honest case against declining it again: "no
  unknowns" is exactly why it never loses a contest for the engineer
  seat's attention, which means it can keep losing indefinitely
  unless someone bets it on its own merits instead of leftover
  capacity. Flagged for the owner rather than decided quietly. See
  "what you can veto" below.
- **Proposal A (`epito token` framework couplings, langchain-epito,
  the n8n node).** The chair's own portability doc (2026-09-19)
  recommended it ship alongside the Slack work. The owner's later
  strategy all-hands (2026-09-20) superseded that with a direct
  ruling: "cycle 3 is the LangChain package." Following the more
  recent, more deliberated source over the earlier draft.
- **Proposal C (the adapter runtime, bring-your-own-agent).** Nothing
  to bet here. It already shipped. It rode into cycle 1's bet 1 as
  one of three riders when the owner redirected the runtime
  mid-cycle (the retro's honest finding: this happened without a
  fresh pitch, which is defensible given the owner was in the room,
  but should have been named in a hill update the week it happened
  and wasn't). Recorded as ADR-17, live in `cli/src/lib/adapters.js`.
  Nothing to re-bet. Noted here so the betting table reflects what's
  actually left undone, not what the original four-proposal list
  still implies is open.
- **Omarchy integration** (ideas ledger, 2026-09-18, accepted by the
  owner: "lets integrate omarchy into our stack." docs/architecture.md
  §"OS" names it explicitly for "the cycle-2 betting table"). Not
  shaped this cycle, named rather than dropped: docs/architecture.md
  itself describes the integration as a package installing "epito +
  epitod + the MCP server," which makes it a bet with a real
  dependency on the MCP server shipping first, the exact
  dependency-chain problem bet 2 was scoped to avoid this same memo.
  With only one big batch and one small batch of appetite this cycle,
  both already spoken for, Omarchy queues behind whichever cycle bets
  the MCP server. Stays in the backlog, raw material, not re-shaped
  on a cycle it has no realistic appetite room in.
- **Everything in backlog Later** (teams, convening, the agent
  repository): ADR-1's wedge rule, unshaped, untouched, same as every
  prior cycle.

## What the owner can veto

- Either bet: edit or revert this file before merging, or merge it
  and edit docs/cycles/2026-10-07-cycle-2.md (opened by the PM once
  this memo merges) directly. The PM reshapes around either edit.
- **Betting the MCP server a third time, instead of or alongside the
  passport**: coherent if the owner would rather bank a sure,
  finished distribution channel than a strategic prototype this
  cycle. The case against it above is about pattern, not worth. It
  is a genuinely good pitch that keeps losing a popularity contest it
  was never designed to need to win.
- Dates: the 2026-10-07 start assumes this memo merges inside
  cooldown (by 10-06). A later merge shifts the start, not the
  two-week length.

## Standing items this memo does not re-litigate

- The cycle-1 retro and trial scorecard (docs/cycles/2026-09-21-cycle-1-retro.md,
  PR #54) is a separate, already-written PR from this same seat,
  still open and waiting on another merger (Tier B rule 1: a PM's own
  PR waits for the owner or HQ's PM). This memo doesn't duplicate it.
- The engineer's cycle-1 merge-candidate stack (PR #48) merged to
  `main` today (2026-10-05, per the separate Tier B merge pass, PR
  #66). This memo's evidence above already reads `main` post-merge,
  not the stale pre-merge state docs/backlog.md still shows as of
  this PR. That backlog reconciliation is Tier B housekeeping, not a
  betting decision, and is left to whichever PM pass next touches
  docs/backlog.md.

Linear mirror: skipped. `LINEAR_API_KEY` is present as an env entry
but empty, the same absent-in-practice state every PM run has
reported since 2026-09-24. The `gh project`-equivalent for Linear
would be: a new issue per bet (slack-identity-v0, passport-v0-github)
in team epitome / project epito, each carrying this pitch's appetite
and rough-solution summary, plus a comment on the existing
MCP-server issue recording the third pass-over and its reasoning. No
issue for the adapter runtime: it is already closed, by shipping.
