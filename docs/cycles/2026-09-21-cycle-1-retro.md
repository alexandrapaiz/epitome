# Cycle 1 retro + trial scorecard — written at cooldown, 2026-10-05

Cycle 1 ran 2026-09-21 → 2026-10-02. Cooldown is 2026-10-05/06 (named in
docs/cycles/2026-09-21-cycle-1.md). This file is late by the calendar
(cooldown day 1, not day 0) because no PM run happened between
2026-09-30 and today — a gap named honestly below, not smoothed over.

Evidence method: the same one the engineer's cooldown PR used on this
same day — `gh pr list --state all`, then `git merge-base --is-ancestor`
across the open branches, then reading main's actual file tree, not the
plan files, for what the product can do today. Where the plan files
(this one included, before today) disagreed with that evidence, the
plan files were wrong and are corrected below.

## What was bet, and what shipped

The owner re-bet the day before the cycle opened (recorded in
docs/cycles/2026-09-21-cycle-1-amendment.md): the resident runtime,
`epito run <dir>`, as bet 1 (big batch), and the identity slice reduced
to per-run token minting as bet 2 (small batch). The MCP server, bet in
the original betting memo, was dropped back to raw material the same
day — the right call in hindsight: it never contended with the runtime
for the cycle's one engineer seat.

**Bet 1 shipped, then grew.** `epito run` landed in two slices inside
the cycle (held sessions, the mailbox, window open/close, Slack
posting, the host script). Five days before close, the owner redirected
the runtime's engine: resident-but-fragile hand-rolled scheduling became
a self-hosted durable-execution engine underneath the same `epitod`
face, recorded in docs/decisions.md. That rebuild, plus three riders
that rode in beside it — a real board instead of a plan file, a way to
host an agent that isn't a Claude session at all, and a seat declaring
which provider "roads" it can take so the runtime can detour around a
dead one — landed together five days before the cycle closed. Verified
today: `cli/src/temporal/`, `cli/src/lib/router.js`,
`cli/src/lib/adapters.js`, and `cli/src/board.js` are all on `main`.
This was never re-bet through a fresh pitch; it rode in as bet 1's own
scope, which is defensible (the owner redirected it personally, in the
room) but means the hill chart below is reconstructing a decision this
file should have recorded the week it happened and did not.

**Bet 2 shipped, on the fourth or fifth attempt.** The reduced
token-minting slice was independently built five separate times across
five different runs before one of them landed — a defect named and
fixed by the exo seat's incident register, not by this seat catching it
first. The correct implementation (`cli/src/token.js`,
`cli/src/lib/identity.js`) is on `main`. Minted tokens are injected into
a run so its PR opens as `<agent>[bot]`, which is the bet's whole point
and is demonstrated in the smoke suite, not just claimed.

**Circuit breaker: not triggered.** Both bets closed inside the
appetite — by 2026-09-30, three days before the 2026-10-02 deadline.
Nothing here needed a cut, a swap, or a rollover decision. On the one
mechanism Shape Up exists to test (fixed appetite, variable scope, no
silent rollover), cycle 1 is a clean pass.

## What the plan files got wrong, corrected here

- **docs/cycles/2026-09-21-cycle-1.md** stopped updating 2026-09-24,
  six days before the cycle actually closed. It still describes bet 1
  as a hand-rolled resident process with an open route question; the
  route was chosen, built, superseded by the durable-engine rebuild, and
  merged, and the file never said so. Corrected in that file today,
  alongside this one.
- **docs/backlog.md**'s deploy/identity card still reads "no code for
  it in cli/src as of 2026-09-24." Untrue since 2026-09-30. Corrected
  today with the merge evidence.
- Neither gap was a seat hiding progress. It is a cadence gap: the
  runtime kept running (and kept shipping) every day; this seat did
  not run between 2026-09-30 and 2026-10-05.

## The finding that matters more than either bet

Nothing shipped on `main` since 2026-09-30 except two lesson-register
syncs. Everything else since then is sitting open, and the pile is not
small:

| Seat | Open, unmerged, oldest first | Age today |
|---|---|---|
| engineer | #28, #33, #36, #37, #38, #40, #41, #43, #44, #45, #46, #48 | 6 days → same-day |
| market | #42 (map refresh) | 3 days |
| okr | #39 (quarterly grading — `docs/okrs.md` itself has never once landed on `main`) | 4 days |
| chair | #25 (tracing), #29 (a decision proposing this seat gain merge authority) | 5 days |
| pm (this seat) | #18, #30, #34 | 8, 5, 5 days |

The twelve open engineer PRs are not twelve competing proposals. They
are one linear chain — verified today with `git merge-base
--is-ancestor` across every branch, not taken on the engineer's word —
with nothing left to land and no rebase needed: 55 files, +6,058/-544,
five new decisions recorded (a per-agent GitHub App created by the
app-manifest flow instead of by hand; `validate` naming what the
runtime will still refuse rather than passing silently; the audit
ledger staying read-only from the CLI instead of becoming a second
board; the company's own roster living in `agents/` beside the
workflows rather than replacing them; and a validator refusing to speak
for a command it was never asked about). The whole stack was run
test-green from a cold machine before that PR was opened: 724
assertions across eight suites, zero skipped, exit 0. The open question
sitting at the tip is not whether it compiles. It is whether it merges,
and that decision is the owner's, not this seat's — no self-merge grant
is held here (the decision that would create one is itself in the open
pile above), so this run does not merge it. It only names, in one
place, that the decision is the single highest-leverage thing available
this cooldown.

This is not a Shape Up problem or a Scrum problem; a merge queue backs
up under either framework. It belongs in the scorecard below only
because the trial's own terms ask what this seat would rather have her
read on a Monday, and "the stack is verified and waiting" is a better
Monday sentence than a sprint burndown would have produced from the
same facts, since nothing in Scrum's point-counting would have forced
the same-day verification this seat's hill-chart habit does.

## Seat hygiene, done in this run

A company-wide rule synced into this repo today (the new entry on
authority held and not exercised piling up, in the lesson register the
exo seat maintains) named this seat's own 2026-09-27 draft as one of
its sources. Acting on it, same run:

- **Closed #34** (this seat's 2026-09-30 hill update): superseded in
  full by this file and by today's edit to
  `docs/cycles/2026-09-21-cycle-1.md`, which supersede it with more
  current evidence.
- **Marked #18 ready for review** (this seat's 2026-09-27 draft
  scrubbing bare decision-codes from owner-facing files): the content
  was complete eight days ago; a draft is only legitimate while its own
  run is still going, and that run ended over a week ago.
- **Left #30 open**: it tracks a real, still-unfixed gap (failed-run
  triage blocked on a missing permissions scope), not a superseded
  draft.

## Trial scorecard — cycle 1 (one data point; the owner's binding
review is end of cycle 2, per the decision that set up this trial)

**Ceremony cost.** Roughly eight PM-seat runs touched cycle 1 start to
cooldown (an opening memo, a same-day re-bet record, a mid-cycle
ceremony-lite update, a reality-check, two standups, a hill update, and
this retro) across twelve calendar days, plus a four-day gap with no PM
run at all. No run this cycle took more than one sitting to produce its
PR. The honest comparison this seat can make without inventing a
number: that is not obviously cheaper than a weekly Scrum retro plus
planning would have cost, because this trial also paid for two
re-bets, two broken ceremony files, and a four-day silent gap that a
fixed weekly cadence would not have had room for.

**Quality of what shipped.** Both bets shipped working, tested code
inside the appetite, with hill-chart text that (when actually kept
current, which it was not for the second half of the cycle) is directly
checkable against named PRs rather than a point estimate. The method
this run used to find the real state of the world — reading merged
commits and verified branch composition instead of trusting any plan
file, this one included — is the thing worth keeping regardless of
which framework wins.

**What she'd rather read Monday.** Not this seat's call to make; it is
exactly the question the owner set this trial up to answer, and the
honest material for her to answer it with is: a fixed appetite that
produced two on-time, uncontested bet closures, against a ceremony file
that went stale for six of twelve days and a cooldown retro that is
itself three days late. Both facts are true at once.

**One concrete process improvement.** When this seat's cooldown run
finds a verified, test-green composed branch sitting open, it names a
merge recommendation in the same run it finds it, instead of filing the
observation and waiting for the next ceremony — which is what today's
run did, and what last cycle's hill update (#34, five days ago) did
not, and that gap is why the recommendation above is three days later
than it should have been.
