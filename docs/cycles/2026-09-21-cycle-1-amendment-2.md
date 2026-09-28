# Cycle 1 amendment 2 — owner re-bets again, 2026-09-26 synchronous session

The first amendment (2026-09-21-cycle-1-amendment.md) re-bet cycle 1 to
the resident runtime and a reduced identity slice. Five days later the
owner opened a synchronous work window (pm.md §11.4 / L-P7: "when im on
we all work synchronous... pms should be directing") and, relayed by
the chair and staged by the PM in a dispatch queue (PR #12), gave the
engineer seat four priorities in her own order. The engineer has since
built all four, stacked, as one branch chain. This file exists because
the cycle file is the board, and a board that still shows only
amendment 1's bets while four more have shipped as draft PRs is exactly
the "high-level-only board" this charter forbids.

## The bets (amended again, in the owner's order)

**1. epitod v1 on Temporal** — the runtime engine, self-hosted on the
company host; `epitod` becomes its face (HQ ADR-036, recorded as a
press-release-first design in docs/prfaq/epitod-v1-temporal.md once
that PR merges). Supersedes epitod v0's hand-rolled scheduler/mutex/
retry code from amendment 1's bet 1 — a port, not a parallel track.
PR #11 (`engineer/2026-09-26-epitod-v1-temporal`), draft, unmerged.

**2. Identity, natively on the v1 engine** — the per-run mint moves
inside Temporal's execute activity, then the clone itself mints and
commits as the bot. This is amendment 1's bet 2, rehomed to the new
engine rather than the old one. PR #14 (stacked on #11) and PR #15
(stacked on #14), both draft, unmerged.

**3. The board** — an owned task manager (Working Backwards PR/FAQ:
docs/prfaq/task-board-v0.md once merged), replacing the Linear mirror
this charter still names (ADR-5's trial is superseded here, not
completed; the ExO/charter-patch is flagged below, not self-applied).
PR #16 (stacked on #15), draft, unmerged.

**4. LangGraph adapter with tracing** — a seat that is not a Claude
session, runs visible in Phoenix. PR #17 (stacked on #16), draft,
unmerged.

**5. The router** — a seat declares its roads, the runtime takes the
detour. PR #21 (stacked on #17), draft, unmerged. Own-model hosting
(vLLM) was named and dropped the same session; it is not a bet.

## Why this is a bet-swap, not a circuit-breaker failure

ADR-5's rule is "anything urgent goes to the owner as a proposed
bet-swap, her call alone." That call was already made, in the room, by
the owner herself — the PM's job here is only to record it where the
board lives instead of leaving it scattered across a dispatch queue and
five PR descriptions. Nothing here is being smuggled past the betting
table; the table just moved to a synchronous window this time.

## Standing risk this amendment adds (2026-09-28)

**A six-PR-deep unmerged stack.** #11 → #14 → #15 → #16 → #17 → #21,
each retargeting to main "as the stack merges." Nothing in the chain
has merged yet as of this run. The longer it stays unmerged, the more
any one conflict or review comment ripples through five downstream
branches. This is an engineering risk to flag, not a PM fix — named
here so the retro can grade it honestly.

**The identity slice was independently built four times.** Amendment
1's bet 2 (`epito token`) shipped as three separate main-based PRs
against the now-superseded v0 engine — #9 (2026-09-24), #10
(2026-09-25, which says outright "#9 should be closed, this one
carried forward"), and #20 (2026-09-28, opened without apparently
checking #9/#10 were already open) — and a fourth time, correctly
placed, inside the v1 stack (#14/#15). That is three engineer runs'
worth of duplicated work on a feature whose target architecture had
already moved. Recommend to the owner: close #9 per #10's own text;
decide #10 vs. #20 (or drop both if #14/#15 fully supersede them once
Temporal merges, which the identity-slice pitch's intent — the runtime
mints the token — would suggest they do).

## What the cooldown retro (2026-10-05/06) should grade against

Not amendment 1's bets alone. The owner's four 2026-09-26 priorities
are what engineer time actually went to all week; grading the retro
only against "did epitod-v0-resident + token ship" would call this a
quiet week when five draft PRs and a full engine swap say otherwise.
The retro should score both: amendment 1 (shipped, then superseded)
and this amendment (in flight, unmerged, real).
