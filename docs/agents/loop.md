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
column for it (L51, incident 25). Classes come from the result object's own
`subtype`, never the exit code, and the `turns=` sum is anchored to digits:
a footer reading `turns=-` made the old pattern emit an empty field and `bc`
a syntax error on stderr, which reads as untidiness rather than a gap.

```bash
cd /srv/asc/state/.epito/logs && D=$(date -u +%F)
# ended non-zero, opened no pull request, never took a second turn
nothing() { grep -lE '^# exit=[^0].* pr=- .* turns=(-|0|1)$' */$D*.log; }
said()    { xargs -r grep -lE '"api_error_status":(429|529)|hit your [a-z]+ limit|limit (reached|exceeded)'; }
refused() { nothing | said; }
echo "runs $(ls */$D*.log | wc -l)" \
     "turns $(grep -ho 'turns=[0-9][0-9]*' */$D*.log | cut -d= -f2 | paste -sd+ | bc)" \
     "refused-before-a-turn $(refused | wc -l)" \
     "seats $(refused | cut -d/ -f1 | sort -u | wc -l)" \
     "refused-mid-run $(($(ls */$D*.log | said | wc -l) - $(refused | wc -l)))" \
     "exhausted $(grep -l '"subtype":"error_max_turns"' */$D*.log | wc -l)"
```

`bash docs/agents/caps.sh` is the same read per seat, with the cap, the cost and the step L-X3 asks for.

| Date | Runs | Turns | Refused | Dark | Weakest attribute | What it moved |
|---|---|---|---|---|---|---|
| 2026-10-18 (read 12:06Z) | 253 | 16,079 | 65 (25.7%) — reread 13:30Z by the class test: 37 before a turn (13 seats), 28 mid-run, of 291 runs | 342 min, 121 of them after capacity returned | Dashboards | incident 8, L18, the capacity experiment, three ideas to the owner; reread 14:50Z — incident 12 and L26, and five of this seat's six open pull requests closed as folded into the sixth |
| 2026-10-19 → 2026-10-22 | 0 | 0 | — | 6,784 min, the whole of four days | not measured: no tick ran | the disk filled on 10-18 and the box ran nothing until 10-23T17:04Z; the brief, the bus and every clock went with it. Four rows this file could not take |
| 2026-10-23 (read 00:12Z on 10-24) | 92 | 5,527 | 10 before a turn (6 seats), 6 mid-run | 1,024 min to 17:04Z, then 237 min 19:09→23:06Z | Dashboards | HQ's centralizer ran the loop on the outage; this seat's half is the row above and incident 14 |
| 2026-10-24 (**final, read 2026-10-25T02:3xZ**, after eight rereads through the day; the per-reread trail is in `#305` and is not carried here, because this file's ceiling is 160 lines and a closed day is one reading) | 469 logs, **457 finished**, 12 without a result object | 27,165 as a 22:2xZ reading, not restated: `caps.sh` reports runs, cost and minutes and not the turn sum (L-A34) | **105 runs a limit touched across 23 seats, of which 47 never took a second turn across 18 seats**, and **32 runs exhausted their own cap on 10 seats, $378.29 and 825 min that bought nothing**. Last night's cell said *72 refused before a turn across 25 seats*: 72 was `caps.sh`'s REFUSED column at 23:0xZ, which counts every finished run a limit touched and never reads turns, so the number was the wrong class under the wrong label and both halves were wrong. `caps.sh` now prints REFUSED and BEFORE as separate columns (L33) | 813 dark of 1,383 at 23:0xZ, the last reading taken; longest gap 250 min from 02:09:56Z | **autonomy**, sixth and final naming | L34-L56, incidents 15-28, nine detectors, three ideas to her. The last of it, L56 and incident 28, reached no `main` that day: see the row below |
| 2026-10-25 (**final, read 23:0xZ** on a capacity-returned hook; every cell of the 02:3xZ and 03:0xZ readings is superseded, including the `brief.sent` claim, which was false both times) | 147 logs, **131 finished, 16 open** | not read: `caps.sh` does not sum turns and nothing else on this box does | **70 limit-touched runs across 21 seats, of which 53 never took a second turn across 16 seats**, and **4 runs exhausted their own cap, $51.45 and 116 min**. The class under all of it is one **weekly** limit, first printed at 03:00:04Z by `engineer` and naming its own reset — *resets 11pm (UTC)* — and **65 runs on 21 seats were refused by it between 03:00:04Z and 18:20:00Z, 64 of them started after the provider had already said in writing when it comes back** (L59, incident 32) | **1,307 dark of 1,384 elapsed (94%, a ceiling)**; longest gap 285 min 06:20:10Z → 11:05:03Z; only 284 min of the dark falls after the last refusal, so today inverts 10-24: the waste was in front of the reset, not behind it | **Dashboards**, displacing autonomy's four namings: autonomy's evidence was a cap this seat may not raise, and today's is a fact this company computed 65 times and stored nowhere | L59, L60, incident 32, one charter patch pushed to `#312`, and the three standing counts |

## Tick of 2026-10-25, final pass

**Observe.** A capacity-returned hook at 23:02:09Z, in the same second as
twelve other seats. The run it refers to was the **daily brief** —
`asc-brief.timer`'s 12:01Z tick, the input trigger 4 of the charter names.
`brief.sent` is on the board at 12:01:26.078733Z; the run it woke started 1.9
seconds later and was refused before its first turn. So the loop's declared
input was not absent today: it arrived on time and a provider ate it. The two
earlier readings of this row called it absent for a third consecutive wake and
both were taken before 12:01Z. An input with a clock cannot be reported
missing by a window that has not reached its clock, and `brief.sh` printed
nothing rather than *not yet due* (L60).

Pasted from `bash docs/agents/caps.sh` and `bash docs/agents/idle.sh`, never
retyped (L33):

```data
measured_at: 2026-10-25T23:04:00Z
window: 2026-10-25..2026-10-25
logs_read: 147
runs_finished: 131
runs_open_or_without_a_result: 16
limit_touched: 70
limit_touched_seats: 21
refused_before_a_turn: 53
refused_before_a_turn_seats: 16
exhausted: 4
exhausted_seats: 4
exhausted_cost_usd: 51.45
exhausted_minutes: 116
dark_minutes: 1307
elapsed_minutes: 1384
longest_dark_gap_minutes: 285
longest_dark_gap: 06:20:10Z -> 11:05:03Z
last_limit_touched_run: 18:20:00Z
dark_after_last_refusal_minutes: 284
weekly_limit_refusals: 65
weekly_limit_refusal_seats: 21
weekly_limit_first_named: 2026-10-25T03:00:04Z
weekly_limit_named_reset: 2026-10-25T23:00:00Z
weekly_limit_refusals_after_it_was_named: 64
```

**Orient.** Weakest of the ten: **Dashboards**, and it displaces four
consecutive namings of autonomy on better evidence. `cli/src/lib/refusal.js`
read today's sentence correctly — I ran it against the real log line and it
returns `resetAt 2026-10-25T23:00:00.000Z` — and then `refusalNakMs` clamped
the hold to its 6h ceiling and scheduled my event's return for 18:01:27Z,
four hours fifty-eight minutes before the provider said it comes back. The
reading is right and nothing keeps it: the fact lives on the event that
discovered it, so 21 seats discovered it 65 times and the box has no surface
that says *the weekly pool is closed until 23:00Z*. That is `L-A81` — a
shared resource with no budget and no watch — and the charter's capacity
line counts refusals, which is a reading of the outage after it happens.

**Decide — the week's experiment.** Replaces the 10-24 one. New prediction, so
it can fail: **the next weekly-limit window on this box produces fewer than ten
refusals portfolio-wide**, against 65 today. If the ceiling on holding an event
is right — and its own comment gives a real reason, stream retention — then what
must change is what *starts* a run, not how long an event waits.

**Act, under the merge rule.** Mine this run and in `#316`: L59, L60, L37's
amendment, incident 32, four new answers in `brief.sh`, the store's own two
rules now applied by `addressed.sh --body`, and this file — based on `main`
with no `prompts/` path in it, because every file in it is `epitome/pm`'s hand
(L55 clause one). The charter patch L59 owes went to **`#312`**, already
`prompts/exo-agent.md` alone and already at the owner's tier, which is L55
clause two rather than a second opening; `clocks.sh` reports 0 of 159 board
asks carrying `expires_at`, so no clock was disturbed. Routed to
`alexandra-systems/pm`, `epitome/pm` and the centralizer, one body each.

**Measure — the 2026-10-24 experiment.** First half: `caps.sh` and
`remeasure.sh` both earned their keep again. Second half, the `brief.sent`
absence, is **withdrawn, not failed**: the event exists and the three
measurements that could not see it were taken before its clock.

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
