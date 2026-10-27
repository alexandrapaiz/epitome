# Learning-loop ledger — **CLOSED 2026-10-27**

> This file is ended by its own second kill condition. The reading and the
> reason are in the last section; the table is kept as the record and takes
> no further rows. Everything below this line describes the file as it ran.

This seat's half of the company learning loop (owner directive, 2026-10-17,
carried here as a handoff on the board; the standard's own text for it is not
yet vendored into this repository — incident 7). The tick is whatever fires
it, never a time written here: the board emits `brief.sent` and the bus wakes
this seat. The two such events on record fired at 19:04:14Z and 00:07:01Z, so
the 12:01Z this file used to assert was a sentence claiming a cadence rather
than the thing holding it (L16). Each row records the time it was read at.

Each tick does five things — observe this product's numbers, orient them against
the growth model, decide the week's experiment, act on it under the merge rule,
and measure the previous experiment — and leaves three traces: a row in the
table below, the newest tick's working in the section under it, and whatever the
numbers earned in the lesson and incident registers.

**This file has a ceiling, because the frameworks register's law binds this seat
first: a framework must never consume more than the work it organizes.** 160
lines, and only one part of it grows: the table takes one row a day, while the
tick's working and the week's ideas are overwritten each time rather than
appended, because the detail of a tick belongs in the registers and on the board
where anybody would look for it anyway. At a row a day the ceiling arrives in
about a month, and then every row older than fourteen days collapses into its
verdict. Two kill conditions, both default to cutting: if a daily row ever needs
more than one line, and if **seven ticks** pass — not a week (L34) — with no
decision, handoff or merge **by another seat, a chair or the owner** citing a
line of this file. Counted from 2026-10-18; a citation by this seat does not
count. Either one ends the file, and the cut is logged as a lesson against
this seat.

## The daily line

Runs, turns and refusals are read from the host's own run logs
(`/srv/asc/state/.epito/logs/*/<date>*.log`), portfolio-wide, because the
capacity is one pool and this product shares it with three others. "Dark" is the
longest stretch of the day with no run of any seat. The row is read at the tick
and says so; a day's counts keep moving after it.

A refusal is read as a class and never as a word, and **the provider is not the
only thing that refuses a run** — the cap refuses too (L51, incident 25). The
class comes out of the result object's `terminal_reason` and this file carries
no command of its own to read it: `subtype` says `success` on all 323 provider
refusals in this host's history, and a text search reads a seat *documenting* a
refusal as a seat that hit one (L64). Three instruments, one read each, pasted
and never retyped: **`caps.sh`** for refusals by class, trigger and cap;
**`idle.sh`** for dark minutes and how many fall after the last refusal;
**`recovered.py`** for the minutes a seat waited past a reset that had already
passed, and whether the retry's own allowance was spent when it did (L82).

| Date | Runs | Turns | Refused | Dark | Weakest attribute | What it moved |
|---|---|---|---|---|---|---|
| 2026-10-18 (read 12:06Z) | 253 | 16,079 | 65 (25.7%) — reread 13:30Z by the class test: 37 before a turn (13 seats), 28 mid-run, of 291 runs | 342 min, 121 of them after capacity returned | Dashboards | incident 8, L18, the capacity experiment, three ideas to the owner; reread 14:50Z — incident 12 and L26, and five of this seat's six open pull requests closed as folded into the sixth |
| 2026-10-19 → 2026-10-22 | 0 | 0 | — | 6,784 min, the whole of four days | not measured: no tick ran | the disk filled on 10-18 and the box ran nothing until 10-23T17:04Z; the brief, the bus and every clock went with it. Four rows this file could not take |
| 2026-10-23 (read 00:12Z on 10-24) | 92 | 5,527 | 10 before a turn (6 seats), 6 mid-run | 1,024 min to 17:04Z, then 237 min 19:09→23:06Z | Dashboards | HQ's centralizer ran the loop on the outage; this seat's half is the row above and incident 14 |
| 2026-10-24 (**final, read 2026-10-25T02:3xZ**, after eight rereads through the day; the per-reread trail is in `#305` and is not carried here, because this file's ceiling is 160 lines and a closed day is one reading) | 469 logs, **457 finished**, 12 without a result object | 27,165 as a 22:2xZ reading, not restated: `caps.sh` reports runs, cost and minutes and not the turn sum (L-A34) | **105 runs a limit touched across 23 seats, of which 47 never took a second turn across 18 seats**, and **32 runs exhausted their own cap on 10 seats, $378.29 and 825 min that bought nothing**. Last night's cell said *72 refused before a turn across 25 seats*: 72 was `caps.sh`'s REFUSED column at 23:0xZ, which counts every finished run a limit touched and never reads turns, so the number was the wrong class under the wrong label and both halves were wrong. `caps.sh` now prints REFUSED and BEFORE as separate columns (L33) | 813 dark of 1,383 at 23:0xZ, the last reading taken; longest gap 250 min from 02:09:56Z | **autonomy**, sixth and final naming | L34-L56, incidents 15-28, nine detectors, three ideas to her. The last of it, L56 and incident 28, reached no `main` that day: see the row below |
| 2026-10-25 (**read 23:5xZ** on a wake from this product's project manager, amending the 23:0xZ reading in place rather than taking a second row, because this file's ceiling is a row a day; every cell of the 02:3xZ and 03:0xZ readings is superseded, including the `brief.sent` claim, which was false both times) | 175 logs, **155 finished, 20 open**, against 147 and 131 at 23:0xZ | not read: `caps.sh` does not sum turns and nothing else on this box does | **70 limit-touched runs across 21 seats, of which 53 never took a second turn across 16 seats**, and **5 runs exhausted their own cap, $63.32 and 141 min**, two of them this seat at 121 against 120 — and that cap is `agents/exo/agent.toml:30` in this repository, not the workflow the register named. The class under all of it is one **weekly** limit, first printed at 03:00:04Z by `engineer` and naming its own reset — *resets 11pm (UTC)* — and **65 runs on 21 seats were refused by it between 03:00:04Z and 18:20:00Z, 64 of them started after the provider had already said in writing when it comes back** (L59, incident 32). **Both sides of the reset, which is what this line owes: 42 runs started at or after 23:00:00Z and not one met a limit**, and the 70 and the 53 above have not moved across 28 further logs. **Closed and re-read 2026-10-26T00:08Z: 70 and 53 stand across 194 logs, and the cell was still denominated in the wrong unit.** 11 of the 13 finished scheduled slots were refused (14 fired; 2 completed, 1 still open), against 59 of 143 message wakes and 0 of 30 hooks; ten of the eleven were waiting on the 23:00:00Z weekly reset. A wake refused loses hours and a slot refused loses that seat's whole cadence for its period, so the *42 runs after the reset met no limit* above reads as a recovered day on the day eleven cadences were spent (L62). | **closed: 1,303 dark of 1,440 (90%)**, re-read 00:0xZ against 1,307 of 1,384 at 23:5xZ — the elapsed denominator was the day so far and is now the day; longest gap 285 min 06:20:10Z → 11:05:03Z, then 280 min 18:20:09Z → 23:00:07Z broken by `exo-centralizer`; only 280 min of the dark falls after the last refusal, so today inverts 10-24: the waste was in front of the reset, not behind it | **Dashboards**, displacing autonomy's four namings: autonomy's evidence was a cap this seat may not raise, and today's is a fact this company computed 65 times and stored nowhere | L59, L60, incident 32, one charter patch pushed to `#312`, the three standing counts; then on the project manager's wake **L61, incident 33 and a body gate that performs the write path**, the market draft readied by the seat that owned it ten minutes after being asked, and the cap step routed rather than taken |
| 2026-10-26 (**final, closed 2026-10-27T00:2xZ** on the capacity-return hook of the following day; ten readings through the day, superseded here, the trail recoverable from `#322`..`#353` — a closed day is one reading and this file's ceiling is 160 lines) | **475 logs, 470 finished, 5 without a result object** | not read: `caps.sh` does not sum turns and nothing else on this box does | **160 limit-touched across 22 seats, 90 of them before a second turn** — against the 98 and 56 the 15:0xZ reading closed on, because the day took a **fifth** session window after this seat stopped reading it. Five announced resets in one UTC day: 00:00Z, 04:00Z, 09:00Z, 14:00Z, 19:00Z, and that count is the whole of this tick's finding (L82). By trigger: **13 slots attempted and 12 refused**, 58 hooks and 0 refused, 404 message wakes and 148 refused (L62). The cap, the day's live refuser until 15:0xZ, closed at **50 exhaustions on 12 seats, $566.51 and 1,382 minutes**, 8 of them this seat at `num_turns` 121 — and **that is the last day it can be**: `exo-centralizer` committed 120 → 180 at 14:47:44Z and the roster took it at 20:05:56Z, so the eleven readings that watched this line not move are closed (incident 43) | **861 min of 1,440 (60%)**, three stretches of 182, 159 and 109 minutes; last limit-touched run 23:46:09Z and **only 14 minutes — 2% — fall after it**. That figure is true and this tick's finding is that it is not the story. `recovered.py` reads the day as **1,622 seat-minutes waited past a reset the provider had announced, 1,421 of them (88%) in the 12 waits where the retry's own daily cap was already spent** — idle something asked for and was refused, which neither `idle.sh` nor `caps.sh` has a column for | **Autonomy**, fourth naming | L64–L81, incidents 35–44, nine instruments; closing: the cap step landed by the route L80 named, 37 hours and fifteen misaddressed messages after it was first raised |
| 2026-10-27 (read 00:2xZ, the capacity-return hook that woke this seat 5 h 4 m after the reset it was waiting for; the day is 25 minutes old) | 25 logs, **0 finished** | — | **could-not-look, and not a clean bill**: `caps.sh` read 19 logs and none carried a finished run, which is the honest answer 25 minutes into a day and is printed as one (L41). Nothing has been refused yet | 7 min dark of 8 elapsed at 00:07Z, **no run a limit touched today**, so every dark minute so far is idle capacity and not an outage | **Autonomy**, fifth naming, and the evidence moves from the watcher to the recovery. The last three namings were about instruments that could not see. This one is a mechanism that saw correctly and was forbidden to act: nine seats met every condition `capacity-retry.py` has at 19:03:53Z and the allowance was three a day against a day with five windows. Six of the nine were back inside 26 minutes on board traffic they did not plan; the three that lost the evening were all three of `epitome`'s, the quietest inboxes on the box. A company recovers by being busy, and the product that is not busy does not recover | L82, incident 45, `docs/agents/recovered.py`; `caps.sh` reading the cap the host ran rather than the one this repository declares; incident 43 **closed**; `#354` closed and re-declared; the three standing counts |

## Closed 2026-10-27T00:5xZ by this file's own second kill condition

**The condition, as this file wrote it on 2026-10-18 and measured today.**
Seven ticks with no decision, handoff or merge **by another seat, a chair or
the owner** citing a line of this file, counted from 2026-10-18, a citation by
this seat not counting. Measured:

```data
instrument: git log --since=2026-10-18 -- docs/agents/loop.md; board /api/messages
read_at: 2026-10-27T00:56Z
tick_rows: 7
commits_to_this_file: 51
commits_by_another_author: 0
board_messages_scanned: 200 (240 h, every direction)
citations_by_another_seat: 0
ticks_elapsed: 11
ticks_the_law_allows: 7
```

**Eleven ticks, fifty-one commits, one author, and nobody.** The previous tick
named the cut owed and deferred it — *"named rather than taken, because that
law logs the cut as a lesson against this seat and this run's lesson is spent;
next run takes it or says why"* — and this is that next run. The deferral is
not available twice: the same axis deferred twice is what L4 calls a register
defect rather than a seat's omission, and the law's own words are *either one
ends the file*.

So it is ended here. **The table above stays as the record** — deleting the
evidence that a framework did not pay for itself would be the worse act, and
the seven rows are the only place some of those readings exist. What ends is
the growth: no further rows, no tick working, no week's ideas section. The
daily brief duty is untouched, because it was never this file: it is a board
message to `alexandra-systems/exo-centralizer` and it goes on.

**Where the capacity line goes, because the charter calls it the one number
this file may never be missing.** Into the place that is already read on every
run: the run's own pull request body and the board message that closes the
pass, pasted from `caps.sh`, `idle.sh` and `recovered.py` exactly as it was
pasted here. Nothing about the number changes; what changes is that it stops
being carried by a file with one reader. **The charter clause that still
points here is named verbatim in L84, with the file, the anchor and the hand
that applies it, and an ask is on the board so a clock runs on it.** Until
that clause moves, a run of this seat reads this section and does not reopen
the table (L50: the register is the memory a stateless seat has).

**Logged as a lesson against this seat, as the law requires: L84.** Not against
a reader who did not come. A framework earns its run-time or it is cut, and
this one asked eleven ticks of a seat to produce a number nobody else read.
