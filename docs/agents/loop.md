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
| 2026-10-25 (read 02:3xZ on a hook wake whose payload says the limit that refused the last run has reset; **no `brief.sent` in the events window**, so this tick's declared input was again absent and the row says so) | 27 logs, **10 finished, 17 open** — 17 of them started inside 891 ms of each other at 02:20:32Z, when the limit reset | not read: `caps.sh` does not sum turns and nothing else on this box does | **5 of the 5 finished runs a limit touched were refused before taking a turn**, 5 seats, 0 exhaustions. The data block is below and is generated, not narrated | **142 of 149 elapsed minutes dark (95%, a ceiling)**, 120 of them one unbroken gap 00:20:08Z -> 02:20:32Z. The five refusals are 00:06Z and 00:20Z, so every refusal today preceded the reset and none followed it | **autonomy**, seventh naming, and this time against this seat itself | `gh pr ready 305` as the run's first command, L57, incident 29, the name-resolution fix in `addressed.sh` and the class split in `caps.sh` |

## Tick of 2026-10-25

**Observe.** A hook woke this seat at 02:20:32Z with the payload *"capacity
returned: the provider limit that refused your last run has reset"*. It was
right about the refusal and about nothing else being due. The previous run had
been refused at turn 99 at 23:20:56Z — `"api_error_status":429`,
`"result":"You've hit your session limit · resets 2:20am (UTC)"`, $10.06 and
26.5 minutes — and it had left `#305` a draft after writing in this file that
it had readied it. That is L57 and incident 29, and it is the whole of what
this tick found.

```data
measured_at: 2026-10-25T02:29:25Z
window: 2026-10-25..2026-10-25
logs_read: 24
runs_finished: 6
runs_open_or_without_a_result: 18
limit_touched: 5
limit_touched_seats: 5
refused_before_a_turn: 5
refused_before_a_turn_seats: 5
exhausted: 0
exhausted_seats: 0
dark_minutes: 142
elapsed_minutes: 149
longest_dark_gap_minutes: 120
longest_dark_gap: 00:20:08Z -> 02:20:32Z
```

Pasted from `bash docs/agents/caps.sh` and `bash docs/agents/idle.sh`, not
retyped (L33). The disk is the other reading and it is the one that matters
beyond today: `df -h /` is **32G of 45 used, 13G free, 71%**, against 29G and
16G free three hours thirty-eight minutes earlier, with `/tmp` at 9.8G of which
2.75G is 36 worktrees of runs that have finished. HQ's incident 19 cost this
portfolio 115.5 dark hours on that same disk reaching zero.

**Orient.** Weakest of the ten, and the attribute does not change from
yesterday: **autonomy**. Yesterday it was named against credentials — a seat
that cannot raise the cap that ends its own runs. Tonight it is sharper and it
is not about a credential at all. The clause that would have prevented
tonight's loss was written by this seat, correctly, sixty-three minutes before
the loss, into a pull request that is ready, mergeable, one file, and that no
hand in this product may touch. A company whose seats can diagnose themselves
and cannot bind themselves is not short of insight.

**Decide — the week's experiment.** Unchanged, and now with a second clause:
every tick runs `bash docs/agents/caps.sh` and the row carries exhaustions
beside refusals, **and quotes the instrument's own column names rather than a
phrase of its own**. Prediction, so it can fail: on 2026-10-31 the portfolio
still shows exhaustions at exactly cap+1 on at least three seats.

**Act, under the merge rule.** Mine this run and in this pull request: L57,
incident 29, the name resolution in `addressed.sh`, the class split in
`caps.sh`, and this file. `gh pr diff --name-only` returns no path under
`prompts/`, so `epitome/pm` holds every file in it. **No charter patch**: the
one this run would have written is already in `#300`, word for word, and a
second copy beside it would substitute words the ask did not show her (L55,
L-A100).

**Measure — the 2026-10-24 experiment.** Its second half ran again and failed
again: `bash docs/agents/brief.sh` returns no `brief.sent` in the window the
events route serves, so the input this loop declares has now been absent on two
consecutive hook wakes. That is a finding about the experiment's instrument and
it is recorded rather than smoothed over.

**The ceiling, enforced against this seat.** This file declares 160 lines and
says only the table grows. `#305` took it to **248**, by appending the three
standing counts, which this file never asked for and the charter never put
here. The counts are observations for the owner, so they belong where she reads
them: this run's pull request body and the board. They are not in this file,
and that is the cut the frameworks law asks for rather than a sentence about
discipline.


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
