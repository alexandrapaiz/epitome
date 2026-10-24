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
where anybody would look for it anyway. That prediction was wrong by five times:
the ceiling arrived on **2026-10-24** at exactly 160 lines, six days in, because
what grew was the two sections said to be overwritten and not the table. So the
collapse triggers on the ceiling and not the calendar — at 160 lines the oldest
rows collapse into their verdicts until the file fits (L34, the clause beside the
one it was written for). Two kill conditions, both default to cutting: if a daily row ever needs
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

A refusal is read as a class and never as a word. Grepping for "session limit"
counts three things as one — refused before a turn, refused after an hour of
real work, and a run that succeeded and wrote a sentence about the outage; on
2026-10-18 the word matched 67 logs and 37 were the first kind. Only the first
is safe to hand back to the sender, so the line carries both numbers apart, and
the test for "it did nothing" is the footer, not the prose.

The exit field is not always a code. `exit=timeout` is a fourth class, and its
footer reads `turns=-`, so the first version of this command — `turns=[0-9]*`,
a pattern that matches zero digits — fed `bc` an empty term the first day a
timeout existed, and `bc` wrote a syntax error to stderr while `echo` printed a
well-formed line with the field blank. The one number this file may never be
missing went missing silently on 2026-10-24, which is L42. So the digits are
required, the unreadable footers are counted rather than skipped, and the total
is checked before it is printed.

```bash
cd /srv/asc/state/.epito/logs && D=$(date -u +%F)
# ended non-zero or timed out, opened no pull request, never took a second turn
nothing() { grep -lE '^# exit=([^0]|timeout).* pr=- .* turns=(-|0|1)$' */$D*.log; }
said()    { xargs -r grep -lE '"api_error_status":(429|529)|hit your [a-z]+ limit|limit (reached|exceeded)'; }
refused() { nothing | said; }
turns=$(grep -ho 'turns=[0-9][0-9]*' */$D*.log | cut -d= -f2 | paste -sd+ | bc)
echo "runs $(ls */$D*.log | wc -l)" \
     "turns ${turns:?empty, and this is the one number this line may not be missing}" \
     "turns-unreadable $(grep -lE 'turns=[^0-9]' */$D*.log | wc -l)" \
     "open $(for f in */$D*.log; do grep -q '^# exit=' $f || echo x; done | wc -l)" \
     "refused-before-a-turn $(refused | wc -l)" \
     "seats $(refused | cut -d/ -f1 | sort -u | wc -l)" \
     "refused-mid-run $(($(ls */$D*.log | said | wc -l) - $(refused | wc -l)))"
```

And one figure the line never carried, added 2026-10-24 as this week's
experiment: **dark minutes that fall after the last run a limit touched.** Every
number above counts what the day's outcomes cost. None counts the capacity the
company had and did not spend. `bash docs/agents/idle.sh` prints it.

| Date | Runs | Turns | Refused | Dark | Weakest attribute | What it moved |
|---|---|---|---|---|---|---|
| 2026-10-18 | 253 | 16,079 | 37 before a turn, 28 mid-run, of 291 | 342 min | Dashboards | **collapsed at the ceiling 2026-10-24.** Verdict: the capacity line earned its place and both its predictions held; incident 8, 12, L18, L26 |
| 2026-10-19 → 2026-10-22 | 0 | 0 | — | 6,784 min, the whole of four days | not measured: no tick ran | the disk filled on 10-18 and the box ran nothing until 10-23T17:04Z; the brief, the bus and every clock went with it. Four rows this file could not take |
| 2026-10-23 | 92 | 5,527 | 10 before a turn (6 seats), 6 mid-run | 1,024 min to 17:04Z | Dashboards | **collapsed at the ceiling 2026-10-24.** Verdict: the host came back at 17:04Z after four days seventeen hours; HQ graded the outage; incident 14 |
| 2026-10-24 (read 00:12Z, 01:00Z, 01:23Z, 01:52Z, **12:06Z**) | 9 → 30 → 48 → 70 → **154** (20 open) | **9,898** | 4 before a turn (4 seats), 14 mid-run, all 18 inside 01:31→02:10Z | **494 min of 730 elapsed (68%), 490 of them after the last refusal** | **Autonomy** | 00:12Z: L34, L35, incident 15, `brief.sh`, the chain fix in `order.sh`, the four engineer charter patches applied (on `main` 00:29:49Z), three ideas to the owner. 01:00Z: L37, L38, incidents 16 and 17, `addressed.sh`, three charter clauses, this file collapsed at its ceiling. 01:23Z: L39. 01:52Z: the brief cut repaired and deployed (HQ `413e52c`, 80 minutes), L40, L41, two charter defects patched. **12:06Z: incident 15's brief half closed on a real positive; incident 18 and L42 on the two instruments that were wrong on their first untested branch; `idle.sh`; the capacity line's missing number; #264 readied** |

## Tick of 2026-10-24, 12:06Z

**Observe.** `brief.sent` fired at 12:01:19Z and `bash docs/agents/brief.sh`
ran before the brief was read, which is this week's experiment, and it paid on
first use. The cut is **by section for the first time** — 6 of 9 delivered,
dropping Shipped, Products and Decided in your name, keeping Needs you,
Capacity, Failures, Money and Board — so HQ's 01:27:15Z deploy works and
incident 15's brief half closes. The detector could not read the dropped names:
its pattern was `\\.` for `\.` and could never match anything (incident 18, L42).

154 runs for 9,898 turns, 20 open, 18 runs a limit touched, 4 of them before a
turn, and **all 18 inside the 39 minutes 01:31→02:10Z**. This product took 37
and 1,692 turns; project-manager seats across four companies took 68 runs and
3,729 turns, 38.0% of the day against 38.1% yesterday.

The drag is not the refusals. It is **494 dark minutes of 730 elapsed, 68% of
the day, and 490 of them after 02:09:50Z, the last run a limit touched** —
`bash docs/agents/idle.sh`, written this run. The two long gaps are 250 min
(02:09→06:20) and 237 min (07:07→11:05), and the first thing to run after the
longer one was four project-manager seats starting on the same second,
06:20:00Z. The same signature is on 10-18: 241 min after that day's last
refusal, gaps broken at 06:20:00Z and 18:20:00Z by the same four seats. Work
does not resume when the resource returns. It resumes when a twice-daily
window opens, and the second-order drag is still the runtime gap:
`readlink -f $(which epito)` is `5836dc0` of 2026-09-23 and
`git rev-list --count 5836dc0..origin/main` is **550**, against 532 at 01:52Z
and 366 on 10-18.

**Orient.** The weakest of the ten moves off dashboards for the first time in
four ticks, and it moves because dashboards was repaired: **Autonomy**. The
evidence is one sentence — eighteen runs were refused capacity, the capacity
came back, and nothing in this company noticed. Not one of the eighteen was
retried; the only mechanism that resumes work is a clock at 06:20Z and 18:20Z,
and 99% of today's dark time sits behind it. Algorithms is the arguable
alternative, since what is missing is a rule that reacts to a returning
resource, and what decides it for autonomy is that no hand was waiting either:
the work was handed back as L18 requires and then nobody came for it.

**Decide — the week's experiment.** The capacity line takes a figure it has
never carried: **dark minutes after the day's last refusal**, from
`docs/agents/idle.sh`. Every other number this company keeps counts what the
day's outcomes cost; this is the first that counts the capacity it had and did
not spend. Prediction, so it can fail: through 2026-10-31 the figure stays
above 200 minutes on every tick, and **every gap longer than two hours ends at
06:20:00Z or 18:20:00Z**. One long gap broken by a retry of a refused run
falsifies it, and then autonomy was not the drag.

**Act, under the merge rule.** Mine, in this run's pull request: L42, incident
18, incident 15's closing status, the two instrument repairs, `idle.sh` with
its branches fired against built input, and the charter patch L-X1 earns.
Readying `#264`, which the bus reported orphaned, was this run's first act. Not
mine, and all three in one handoff to two addressees: the retry and the window
doing the resuming are HQ's runtime, the 550-commit deploy is nobody's here,
and every merge is hers or a project manager's.

**Measure — the experiment declared at 01:52Z.** It made every tick run
`brief.sh` first and predicted the footer would still be counting characters on
10-31. **The prediction was wrong inside ninety minutes and the instrument was
right**: running it first is the only reason this run knew the section cut had
gone live, that the wake carried six sections and not the seven HQ predicted,
and that the detector was broken. Keep the instrument, retire the prediction,
and note what being wrong cost: nothing. The 10-18 experiment's two predictions
held again today — a limit refused runs (18), and the project-manager seats
spent over thirty percent of turns (38.0%).

## The ideas for the owner

The week's three went to her at 00:4xZ today and are not re-sent: re-sending an
unanswered idea adds to her queue and not to her information. One of them,
giving the brief a declared order, **shipped the same night**, so it is a
measurement now rather than a proposal — count for a week how many Needs-you
asks are answered within a day, against the four standing unanswered when it
was written. The other two stand. No fourth is added, because the one thing
this tick learned that she would want is a number and not a proposal:
**this company paid for 730 minutes of capacity today and used 236.**
