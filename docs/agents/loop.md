# Learning-loop ledger

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
only thing that refuses a run.** On 2026-10-18 "session limit" matched 67 logs
and 37 were refused before a turn, so those two have been separate since; it
was still a line about one refuser. On 2026-10-24 the cap refused 21 runs
portfolio-wide, $238.22, 14.7% of the day's spend, and nothing here had a
column for it (L51, incident 25).

**The class comes out of the result object's `terminal_reason`, and this file
no longer carries a command of its own to read it (L64).** It used to hold a
`grep` over the whole log, which is how it found refusals at all: `subtype` is
`success` on all 323 provider refusals in this host's history and cannot carry
the class. But a log holds `result`, the run's own final report, so a search
over the file reads a seat writing *about* a refusal as a seat that hit one —
`epitome-exo/2026-10-18T13-07-01-011Z`, 98 turns, $8.19, `completed`, counted
as refused for documenting incident 8. Two reads of one thing is a coin flip
on which this file trusts, so there is one:

`bash docs/agents/caps.sh` is that read — per seat, with the cap, the cost, the
step L-X3 asks for, the trigger split L62 asks for, and a named count of the
logs whose text says *limit* and whose fields say *finished work*.

| Date | Runs | Turns | Refused | Dark | Weakest attribute | What it moved |
|---|---|---|---|---|---|---|
| 2026-10-18 (read 12:06Z) | 253 | 16,079 | 65 (25.7%) — reread 13:30Z by the class test: 37 before a turn (13 seats), 28 mid-run, of 291 runs | 342 min, 121 of them after capacity returned | Dashboards | incident 8, L18, the capacity experiment, three ideas to the owner; reread 14:50Z — incident 12 and L26, and five of this seat's six open pull requests closed as folded into the sixth |
| 2026-10-19 → 2026-10-22 | 0 | 0 | — | 6,784 min, the whole of four days | not measured: no tick ran | the disk filled on 10-18 and the box ran nothing until 10-23T17:04Z; the brief, the bus and every clock went with it. Four rows this file could not take |
| 2026-10-23 (read 00:12Z on 10-24) | 92 | 5,527 | 10 before a turn (6 seats), 6 mid-run | 1,024 min to 17:04Z, then 237 min 19:09→23:06Z | Dashboards | HQ's centralizer ran the loop on the outage; this seat's half is the row above and incident 14 |
| 2026-10-24 (**final, read 2026-10-25T02:3xZ**, after eight rereads through the day; the per-reread trail is in `#305` and is not carried here, because this file's ceiling is 160 lines and a closed day is one reading) | 469 logs, **457 finished**, 12 without a result object | 27,165 as a 22:2xZ reading, not restated: `caps.sh` reports runs, cost and minutes and not the turn sum (L-A34) | **105 runs a limit touched across 23 seats, of which 47 never took a second turn across 18 seats**, and **32 runs exhausted their own cap on 10 seats, $378.29 and 825 min that bought nothing**. Last night's cell said *72 refused before a turn across 25 seats*: 72 was `caps.sh`'s REFUSED column at 23:0xZ, which counts every finished run a limit touched and never reads turns, so the number was the wrong class under the wrong label and both halves were wrong. `caps.sh` now prints REFUSED and BEFORE as separate columns (L33) | 813 dark of 1,383 at 23:0xZ, the last reading taken; longest gap 250 min from 02:09:56Z | **autonomy**, sixth and final naming | L34-L56, incidents 15-28, nine detectors, three ideas to her. The last of it, L56 and incident 28, reached no `main` that day: see the row below |
| 2026-10-25 (**read 23:5xZ** on a wake from this product's project manager, amending the 23:0xZ reading in place rather than taking a second row, because this file's ceiling is a row a day; every cell of the 02:3xZ and 03:0xZ readings is superseded, including the `brief.sent` claim, which was false both times) | 175 logs, **155 finished, 20 open**, against 147 and 131 at 23:0xZ | not read: `caps.sh` does not sum turns and nothing else on this box does | **70 limit-touched runs across 21 seats, of which 53 never took a second turn across 16 seats**, and **5 runs exhausted their own cap, $63.32 and 141 min**, two of them this seat at 121 against 120 — and that cap is `agents/exo/agent.toml:30` in this repository, not the workflow the register named. The class under all of it is one **weekly** limit, first printed at 03:00:04Z by `engineer` and naming its own reset — *resets 11pm (UTC)* — and **65 runs on 21 seats were refused by it between 03:00:04Z and 18:20:00Z, 64 of them started after the provider had already said in writing when it comes back** (L59, incident 32). **Both sides of the reset, which is what this line owes: 42 runs started at or after 23:00:00Z and not one met a limit**, and the 70 and the 53 above have not moved across 28 further logs. **Closed and re-read 2026-10-26T00:08Z: 70 and 53 stand across 194 logs, and the cell was still denominated in the wrong unit.** 11 of the 13 finished scheduled slots were refused (14 fired; 2 completed, 1 still open), against 59 of 143 message wakes and 0 of 30 hooks; ten of the eleven were waiting on the 23:00:00Z weekly reset. A wake refused loses hours and a slot refused loses that seat's whole cadence for its period, so the *42 runs after the reset met no limit* above reads as a recovered day on the day eleven cadences were spent (L62). | **closed: 1,303 dark of 1,440 (90%)**, re-read 00:0xZ against 1,307 of 1,384 at 23:5xZ — the elapsed denominator was the day so far and is now the day; longest gap 285 min 06:20:10Z → 11:05:03Z, then 280 min 18:20:09Z → 23:00:07Z broken by `exo-centralizer`; only 280 min of the dark falls after the last refusal, so today inverts 10-24: the waste was in front of the reset, not behind it | **Dashboards**, displacing autonomy's four namings: autonomy's evidence was a cap this seat may not raise, and today's is a fact this company computed 65 times and stored nowhere | L59, L60, incident 32, one charter patch pushed to `#312`, the three standing counts; then on the project manager's wake **L61, incident 33 and a body gate that performs the write path**, the market draft readied by the seat that owned it ten minutes after being asked, and the cap step routed rather than taken |
| 2026-10-26 (**read 04:16Z** on a capacity-return hook, amending the 00:31Z reading in place rather than taking a second row) | 67 logs, 53 finished, 14 open | not read: `caps.sh` does not sum turns and nothing else on this box does | **24 limit-touched across 16 seats, 10 of them before a second turn, $55.67 of the day's $193.86** — one **session** limit, first printed at 00:26:27Z by `exo-centralizer` naming its own reset (*resets 4am (UTC)*), and **24 of the 33 runs started between then and 00:58:57Z were refused, 23 of them after that sentence was already in a log** (incident 35). The 00:31Z cell said *0 limit-touched and 0 refused* and was marked a floor; the floor was 24. Every refusal was a `message` wake: **0 slots and 0 hooks refused** (L62). **6 exhaustions, 5 seats, $60.47 and 150 min**, one of them this seat at 121 against 120 — the step I routed last night has not moved and I am running under the same cap. **Both sides of the reset: 16 seats woken at 04:02:2xZ, not one met a limit.** And the counts above are the first ones this file has taken from the result object's own fields rather than from a search over the log text, which was reading this register's prose about refusals as refusals (L64) | **183 min dark, 00:58:57Z → 04:02:26Z**, of 182 dark minutes in a 256-minute day (71%); **only 2.4 min of it after the 04:00:00Z reset**, so the mechanism built for incident 8 held and the waste was all in front of the reset | **Dashboards**, fourth naming: the company-wide instrument behind the brief's own capacity line calls a 98-turn exit-0 run refused because that run documented refusals | L64, incident 35, `docs/agents/drafts.sh` fired on three real positives and one real negative, `caps.sh` repaired, this file's duplicate read deleted, the two standing counts; then on a merge wake **L66, incident 36 and `docs/agents/pointers.sh`** — the charter-pointer count L-A90 has asked for since 2026-10-24T17:17Z stands at 1 of 7; then on a second merge wake **L67**, incident 36 re-measured at its eighth working run, and the two checkers that were reading prose to answer a question only an act can settle — `clocks.sh --writable` now probes by write and `addressed.sh --can` reads the prohibition surface. **The first clock-bearing ask this board has carried: 0 of 169 before 05:10Z, 3 after**, and the wake-template line routed at 04:50:48Z was taken by `epitome/engineer` in `#330` five minutes later |

## Tick of 2026-10-26

**Read 05:1xZ, on the second message wake of the day. This section is
overwritten each tick rather than appended to, by this file's own ceiling, so
the 00:31Z, 04:16Z and 04:4xZ workings are superseded by what stands below and
are recoverable from `#322`, `#326` and `#328`. The table row above is the
day's record and it is amended in place.**

**Observe.** Three wakes, all three carrying one instruction: a capacity-return
hook at 04:02:27Z, then the merge of `#326` at 04:27:12Z, then the merge of
`#328` at 04:56:38Z, which is this one. The capacity read is not re-taken: 24
limit-touched and 10 refused before a turn stood unmoved across two readings
this morning, 19 further logs apart, and a third reading of the same hour is
not an observation.

**The capacity read, pasted from `bash docs/agents/caps.sh` and not retyped (L33):**

```data
measured_at: 2026-10-26T04:28:32Z
window: 2026-10-26..2026-10-26
logs_read: 72
runs_finished: 60
runs_open_or_without_a_result: 12
limit_touched: 24
limit_touched_seats: 16
refused_before_a_turn: 10
refused_before_a_turn_seats: 7
exhausted: 6
exhausted_seats: 5
exhausted_cost_usd: 60.47
exhausted_minutes: 150
refusal_signature_in_text_only: 0
hook_attempted: 9
hook_refused: 0
message_attempted: 51
message_refused: 24
```

**Orient.** Weakest of the ten: **Dashboards**, fourth naming, and the subject
has moved from the brief's capacity line to this seat's own checkers. Three
instruments that answer an authority or capability question by reading the text
that governs it, all three wrong, all three wrong in the direction that reports
nothing needs to change: the merging seat's charter naming a superseded command
with `main` baked in as a literal; `clocks.sh --writable` reading a `coalesce`
default as a restriction, and so telling every reader that 46 dead prose clocks
were the board's fault rather than the senders'; `addressed.sh --can` fencing
this seat out of the one file its charter exists to patch, on a sentence in
which `whenever` matched `never`, while clearing the one seat forbidden to write
anything at all. Four of its seven verdicts were right and every one of the four
was a row no duty hangs on. **A dashboard that is wrong is further from a reader
than one that is missing, and a dashboard whose errors all point at "fine" is
further still.**

**Decide — the week's experiment.** Both open predictions stand and nothing is
added (L34). The 10-25 one, fewer than ten refusals portfolio-wide in the next
*weekly* window against 65, is still unresolved: this morning's was a session
limit and does not resolve it.

**Act, under the merge rule.** Mine this run: **L67**, the re-measurement of
**incident 36**, and the two repaired checkers — all under `docs/`, no
`prompts/` path, so `epitome/pm`'s to merge without the owner (L55 clause one).
**No charter patch is cut and the reason is not a convenience.** The patch owed
is `prompts/pm-agent.md` line 82, `#304` is the live single-file vehicle for
that file and `epitome/pm` filed it, so the amendment rides from its author and
not from here (this charter's "When a clock is running on words"). What this run
did instead is the thing nobody had done in two days: put the deferral under a
real `expires_at`. **0 of 169 asks on this board carried that field before
05:10Z; 3 carry it now**, and `bash docs/agents/clocks.sh 304` reads 48 h left.

**Measure — the two things I routed before this wake.**
One **moved**: `#328` handed the wake-template line to `epitome/engineer` at
04:50:48Z, and `#330` is that seat's branch, opened 04:55Z. First time this file
has been able to say a routed item moved inside the hour.
One **did not**: the cap step 120 → 180. This run is still `--max-turns 120`.
And the charter patch is at its eighth working run unapplied — 14 runs of this
seat since the deferral, 5 refused, 5 capped, 3 completed.

**The kill condition, counted because nothing else counts it.** Over 200 hours
and 300 board rows, seven messages cite `loop.md`; one is `epitome/pm` to this
seat, so the clause has not fired. The other six are mine and do not count.

## The week's ideas for the owner — sent 2026-10-24, none owed this tick

One a week is the duty and three went to her on the board under the subject
Ideas on 2026-10-24, each a paragraph with the smallest test that would prove
it wrong. They are **not re-stated here**: the board holds them whole, in the
words she was sent, and a paraphrase in this file would be a second version of
the same proposal with no clock and no reader (L33, and this file's ceiling).
Their subjects, so a later run can find them: *sell the off-host watcher, built
with our own tool*; *give the brief a declared order, so a cut drops a section
rather than a tail*; *charge each product for its share of the box*. The third
is the one tonight's disk reading argues for on its own evidence.
