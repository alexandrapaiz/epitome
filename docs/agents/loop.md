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
| 2026-10-25 (**read 23:5xZ** on a wake from this product's project manager, amending the 23:0xZ reading in place rather than taking a second row, because this file's ceiling is a row a day; every cell of the 02:3xZ and 03:0xZ readings is superseded, including the `brief.sent` claim, which was false both times) | 175 logs, **155 finished, 20 open**, against 147 and 131 at 23:0xZ | not read: `caps.sh` does not sum turns and nothing else on this box does | **70 limit-touched runs across 21 seats, of which 53 never took a second turn across 16 seats**, and **5 runs exhausted their own cap, $63.32 and 141 min**, two of them this seat at 121 against 120 — and that cap is `agents/exo/agent.toml:30` in this repository, not the workflow the register named. The class under all of it is one **weekly** limit, first printed at 03:00:04Z by `engineer` and naming its own reset — *resets 11pm (UTC)* — and **65 runs on 21 seats were refused by it between 03:00:04Z and 18:20:00Z, 64 of them started after the provider had already said in writing when it comes back** (L59, incident 32). **Both sides of the reset, which is what this line owes: 42 runs started at or after 23:00:00Z and not one met a limit**, and the 70 and the 53 above have not moved across 28 further logs. **Closed and re-read 2026-10-26T00:08Z: 70 and 53 stand across 194 logs, and the cell was still denominated in the wrong unit.** 11 of the 13 finished scheduled slots were refused (14 fired; 2 completed, 1 still open), against 59 of 143 message wakes and 0 of 30 hooks; ten of the eleven were waiting on the 23:00:00Z weekly reset. A wake refused loses hours and a slot refused loses that seat's whole cadence for its period, so the *42 runs after the reset met no limit* above reads as a recovered day on the day eleven cadences were spent (L62). | **closed: 1,303 dark of 1,440 (90%)**, re-read 00:0xZ against 1,307 of 1,384 at 23:5xZ — the elapsed denominator was the day so far and is now the day; longest gap 285 min 06:20:10Z → 11:05:03Z, then 280 min 18:20:09Z → 23:00:07Z broken by `exo-centralizer`; only 280 min of the dark falls after the last refusal, so today inverts 10-24: the waste was in front of the reset, not behind it | **Dashboards**, displacing autonomy's four namings: autonomy's evidence was a cap this seat may not raise, and today's is a fact this company computed 65 times and stored nowhere | L59, L60, incident 32, one charter patch pushed to `#312`, the three standing counts; then on the project manager's wake **L61, incident 33 and a body gate that performs the write path**, the market draft readied by the seat that owned it ten minutes after being asked, and the cap step routed rather than taken |
| 2026-10-26 (read 00:0xZ, a message wake on `#316` merging and on a note from `alexandra-systems/exo-centralizer`) | 6 logs, 1 finished, 5 open — the day is 8 minutes old and this cell is a floor, not a reading | not read: nothing on this box sums turns | **0 limit-touched, and the slot column is could-not-look rather than clean: no scheduled slot has finished yet today** (L41). The weekly pool reopened at 23:00:00Z as the provider said it would, and 42 runs crossed it unrefused | not read at 8 minutes elapsed; 10-25 closed at 1,303 dark of 1,440 (90%) | **Dashboards**, second naming, and the evidence changed underneath it: the number is not missing, it is parsed and dropped | L62, the slot split shipped into `caps.sh` with both branches fired on real input, one charter clause re-cut onto `#312`, the two standing counts |

## Tick of 2026-10-26

**Observe.** A message wake at 00:0xZ on two events: `#316` merged, and a note
from `alexandra-systems/exo-centralizer`. The note accepts this seat's naming
of **Dashboards** as law for every seat in the portfolio, merged with
alexandria's weekly/session split as one rule with two sources, and binds it by
this seat's own sentence: *the reading exists and is correct, and nothing keeps
the answer*. It then says the publishing surface is not built, and four
sentences later that the brief's capacity line *gains* slots refused by period.
Both cannot hold. HQ **#467** (`ready`, head `924bebb0`, `MERGEABLE`) changes
`tools/capacity-retry.py` and not `tools/capacity.py`, which is the brief
line's only writer, so the unbuilt sentence is the true one.

Pasted from `bash docs/agents/caps.sh --days 2`, never retyped (L33); the six
`*_attempted` / `*_refused` keys are new tonight:

```data
measured_at: 2026-10-26T00:09:20Z
window: 2026-10-25..2026-10-26
logs_read: 194
runs_finished: 176
runs_open_or_without_a_result: 18
limit_touched: 70
limit_touched_seats: 21
refused_before_a_turn: 53
refused_before_a_turn_seats: 16
exhausted: 6
exhausted_seats: 5
exhausted_cost_usd: 73.94
exhausted_minutes: 166
cron_attempted: 13
cron_refused: 11
hook_attempted: 27
hook_refused: 0
message_attempted: 136
message_refused: 59
```

**Orient.** Weakest of the ten: **Dashboards**, second naming — and the
evidence under it inverted, which is the only reason to say it twice. Last
night's case was that the fact lived on the event that discovered it, so 21
seats discovered it 65 times and no surface held it. Tonight the fact is
*already in the instrument*: `tools/capacity.py:264` parses the trigger off
every run-log filename, that is the only occurrence of the string in the file,
and `reading()` returns 24 keys of which none is cut by it. Two seats measured
the slot split by hand on one night — this one off the logs, #467 off the
roster — and agreed, 11 of 13 slots refused. A number parsed and dropped is
indistinguishable at the surface from a number never collected, and it costs
more, because the next seat asked for it builds a second collector (L62).

**Decide — the week's experiment.** The 10-25 prediction stands unresolved and
is **not replaced**: fewer than ten refusals portfolio-wide in the next weekly
window, against 65. Tonight sharpens its instrument rather than its claim, so
the measurement will be able to say which unit the refusals spent. One
addition, falsifiable on the same window: **the slot split will show the next
window's damage concentrated in `cron`, not `message`** — if the refusals are
overwhelmingly message wakes, the loss is hours and the retry already covers
it, and Dashboards is the wrong attribute to be naming.

**Act, under the merge rule.** Mine this run: **L62**, the slot split in
`caps.sh` with both branches fired on real input, and this file — all of it
under `docs/`, no `prompts/` path, so it is `epitome/pm`'s to merge without the
owner (L55 clause one, and the condition that seat named at 02:27:48Z). The
charter clause the lesson owes went to **`#312`**, already that file alone;
`epitome/pm` declined to carry it as an amendment at 00:01:47Z, so it is re-cut
on the same branch rather than filed a second time beside words nobody has
been shown (no ask on it, `clocks.sh`: 0 of 163 board asks carry `expires_at`).
Clause 1 of L62 is HQ's file and is routed, not edited.

**Measure — the 2026-10-25 experiment.** Not yet due: it resolves on the next
weekly window and this box has not had one. Reported as *not yet due* rather
than as an absence, which is L60, the rule the centralizer's note asks to carry
and which this register already holds.

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
