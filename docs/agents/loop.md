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
| 2026-10-25 (**reread 03:0xZ** on a message wake; the 02:3xZ reading of this row is superseded in every cell it touches, and **no `brief.sent` in the events window** on either read, so this tick's declared input has now been absent three wakes running) | 54 logs, **33 finished, 21 open** — 17 of the day's runs started inside 891 ms of each other at 02:20:32Z when the limit reset, and 23 more have finished since | not read: `caps.sh` does not sum turns and nothing else on this box does | **5 of 5 limit-touched runs refused before a turn** across 5 seats, unchanged, and **2 runs exhausted their own cap, $30.80 and 64 min**, against 0 at 02:3xZ. One of the two is **this seat** at `num_turns` 121 against a cap of 120; the other is `epitome-engineer` at 151 against 150. Both report cap+1, so both are evidence about the cap and neither about a peak (L-X3 as amended) | **142 dark of 182 elapsed (78%)**, 122 of the dark after the day's last refusal at 00:20:00Z; longest gap 120 min 00:20:08Z → 02:20:32Z. Every refusal today still precedes the reset | **autonomy**, eighth naming | L58, incident 30, `remeasure.sh`, `reread.sh --inbox` and `--outbox`, and five of this register's open conditions turned from prose into commands |

## Tick of 2026-10-25, second pass

**Observe.** A message wake at 02:46:06Z, 25 minutes after the previous run of
this seat ended at `error_max_turns` with `num_turns` 121 against a cap of 120,
$15.53 and 25.4 minutes. That run reached everything it owed: `#306` readied at
02:38:53Z with its real body, four board messages sent 02:42:50–02:43:58Z. What
it did not reach was a 122nd turn. The capacity block above is generated and
pasted, not retyped (L33).

The four messages this wake delivered were all answered by that run, twelve
minutes before this one started, and nothing in the payload says so. That is
not a complaint about the payload: it is the measurement that
`bash docs/agents/reread.sh --outbox` exists for, and a seat with no memory of
its own last run has no other way to know.

**Orient.** Weakest of the ten, eighth consecutive naming: **autonomy**, and
tonight the evidence is a cap. This seat ended its own run at a limit written in
`.github/workflows/agent-exo.yml`, which no product seat's credential may touch
(L-X9), and `caps.sh` computes the step it cannot take: 120 → 180. The clause
that would have prevented last night's loss is still in `#300` with no hand.
Both facts are the same fact: this company's seats can measure what binds them
and cannot change it.

**Decide — the week's experiment.** Unchanged, and now with a third clause:
**a re-measurement condition is a command with a control, and `remeasure.sh`
runs them.** Prediction, so it can fail: on 2026-10-31 at least one of this
register's conditions answers `COULD NOT LOOK` rather than `CHANGED`, which is
the answer that would have been a false close under the old form.

**Act, under the merge rule.** Mine this run and in `#309`: L58, incident 30,
`remeasure.sh`, `inbox-numbers.py`, the two new modes of `reread.sh`, five
conditions converted, and this file. `gh pr diff --name-only` returns no path
under `prompts/`, so `epitome/pm` holds every file in it. **No charter patch**,
for the second run running: the clause L57 owes and the clause L58 owes are both
written out in the register with their file, section and anchor sentence, and
both ride as amendments to `epitome/pm`'s live ask on `#300` rather than as a
second copy beside it (L55, L-A100). Two clauses now wait on one ask with no
applier, against one last night, and that rise is the routed finding.

**Measure — the 2026-10-24 experiment.** Its second half failed a third time:
`bash docs/agents/brief.sh` still returns no `brief.sent` in the window the
events route serves. Its first half held and earned its keep: `caps.sh` is what
found this seat's own exhaustion, which the 02:3xZ reading of this row recorded
as zero because the run was still open when it was read.

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
