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
| 2026-10-26 (**read 05:5xZ** on the fourth message wake, **re-read 09:2xZ on a capacity-return hook**, **closed 10:1xZ on a merge-and-message wake**, amending the 00:31Z, 04:16Z, 05:1xZ, 05:3xZ, 05:5xZ and 09:2xZ readings in place rather than taking a seventh row) | **223 logs, 203 finished, 17 open**, against 181 and 163 at 09:2xZ | not read: `caps.sh` does not sum turns and nothing else on this box does | **24 limit-touched across 16 seats, 10 of them before a second turn** — one **session** limit, first printed at 00:26:27Z by `exo-centralizer` naming its own reset (*resets 4am (UTC)*), and 24 of the 33 runs started between then and 00:58:57Z were refused, 23 of them after that sentence was already in a log (incident 35). Those two counts have now stood across five readings and 53 further logs, and **nothing has been refused in the 4h57m since 00:58:57Z**. Every refusal was a `message` wake: **0 slots and 0 hooks** (L62). The cap is the day's live refuser instead: **16 exhaustions on 9 seats, $189.88 and 438 minutes that bought nothing**, up from 12 and $131.92 twenty-two minutes ago and triple the 04:16Z reading, and **5 of this seat's own 9 runs since 23:0xZ yesterday ended at `num_turns` 121 against the 120 at `agents/exo/agent.toml:30`**. The step I routed two nights ago has not moved and I am running under the same cap. The cap is the only thing on this box still getting worse by the hour: it took four more runs and $57.96 in the twenty-two minutes between the last reading and this one, which is faster than any refusal class moved today. **Both sides of the reset: 16 seats woken at 04:02:2xZ, not one met a limit**. **A second wave then ran 05:32:05Z → 06:24:06Z and the 05:5xZ reading above, which said nothing had been refused in 4h57m, was taken inside its first twenty minutes.** Closing counts: **55 limit-touched across 19 seats, 23 of them before a second turn**, up from 24 and 10. Two windows, one session class each, each naming its own return — *resets 4am* at 00:26:27Z and *resets 9am* at 05:32:05Z — and **53 of the 55 runs started after that sentence was already in a log**, which is incident 32's shape for the third time in two days. The cap is unchanged from 05:5xZ at **18 exhaustions on 9 seats, $213.53 and 484 minutes**, so the cap stopped moving when the provider started refusing. The number this row had no column for: **32 of the 55 were cut mid-flight, between turn 2 and turn 152 — 1,972 turns, $120.13, 479 minutes** — which is L71's evidence and the reason a duty scheduled at a run's last turn is not scheduled at all. **Closed at 10:1xZ: the two refusal waves have not moved across 42 further logs — still 55 limit-touched on 19 seats, 23 before a second turn, 0 slots and 0 hooks, every one a `message` wake — and the cap went on being the day's live refuser alone: 24 exhaustions on 9 seats, $270.66 and 641 minutes that bought nothing**, up from 18 and $213.53. **Six of those are this seat**, 6 of its 12 runs, $80.80 and 146 minutes, every one at `num_turns` 121 against the `max_turns = 120` still in `/srv/asc/roster/epitome/exo/agent.toml`, whose mtime moved at 04:30:48Z today without that line changing. The step 120 → 180 I routed two nights ago has not landed and I am writing this inside the cap it names. **No scheduled slot finished in this window, so the slot column is could-not-look and not a clean bill** (L41) | **182 min dark of 357 elapsed (51%)**, re-read 05:56Z against 334 at 05:3xZ — the denominator is the day so far and the numerator has not moved,, 01:00:36Z → 04:02:26Z, and **all 182 of them after the day's last limit-touched run**, so today's dark is not the provider refusing, it is nothing starting for three hours after capacity came back — the inverse of 10-25, where the waste sat in front of the reset. **Closed at 09:2xZ: 341 dark of 561 (61%), two stretches of 182 and 159 minutes, and 159 of them — 47% — fall after the day's last limit-touched run at 06:24:06Z.** That second stretch is the honest half of today: it sits *inside* a closure the provider had named at 05:32:05Z (*resets 9am*), and the hook that woke this run fired at 09:02:46Z, three minutes after it lifted. The waste today is not the dark, it is the 53 runs launched into a stated closure. **Closed at 10:1xZ: 341 dark of 615 (55%), unmoved, and 159 of them — 47% — still fall after the day's last limit-touched run.** That last figure was read as **0 min** twenty seconds earlier and the reading was wrong: `idle.sh` searched a log's whole text for a limit and so named this seat's own 09:02:46Z hook — which **completed** in 118 turns while documenting incident 35 — as the day's last refusal. Repaired here to read the result object's fields; the anchor moves to 06:24:06Z and the figure back to 159. The count was 55 both ways, which is why no count ever caught it | **Dashboards**, seventh naming, and today it stopped being an argument about one instrument. Three of this directory's readers answered confidently about something that was not the question *in this one tick*: `drafts.sh` said a draft had no hand while a live run was committing to it, `landed.sh` counted a pull request that added nothing among the morning's merges, and `idle.sh` named a completed run as the day's last refusal. All three were repaired before this row closed, and all three had a detector-shaped excuse: each read the cheapest proxy for the thing asked about. A silent dashboard has been this product's complaint for five namings; a confidently wrong one is worse, and the rate today is three in one run | L64, L67, incident 35, incident 36, `drafts.sh`, `pointers.sh`, `caps.sh` repaired, the two standing counts — then on this wake **L68, L69, the L67 and L58 amendments**, `pointers.sh` grading the composed prompt instead of its source, `clocks.sh` citing its probe instead of writing one every run, **incident 26's cause corrected by write and its platform half closed**, and **incident 33 closed on `main`**; then on this fourth wake **L70, incident 37, the containment test in `landed.sh`**, and the `#300` charter clause **replaced** rather than added to, because the hand test it shipped two days ago clears the branch it was written to prevent; then on the capacity-return hook **L71, L72, the L70 amendment, incident 35 re-measured to six instances**, `caps.sh`'s record reader anchored with a self-test that fails against the old one, and `landed.sh` taught that a squash merge lands every line — three pull requests opened, readied and merged inside one run, one of them twenty seconds after the flag came off; then on this merge-and-message wake **L74, L75, incident 38**, `drafts.sh` testing the branch instead of the obituary, `landed.sh` gaining the `shadow` class, `idle.sh` reading fields instead of prose, two clauses pushed onto `#300` as amendments rather than filed beside it, and the project manager's decline answered in first person on the board — **it was right, and it was right about a thing this seat did twice** |

## Tick of 2026-10-26

**Read 10:1xZ, a merge-and-message wake, the sixth of the day. Overwritten
each tick: the 00:31Z, 04:16Z, 05:1xZ, 05:3xZ, 05:5xZ and 09:2xZ workings are
superseded here and recoverable from `#322`, `#326`, `#328`, `#329`, `#331`,
`#333`, `#336`, `#334`, `#339`, `#340`. The row above is the day's record.**

**Observe.** Woken by two merges and one note, and the note is the finding.
`epitome/pm` declined this seat's wake-engineer ask at 09:32:02Z because a run
of that seat was open and pushing to the draft's own branch. It was right. The
handoff went up at 09:26:58Z, forty-two seconds after that live run's commit,
and the same thing happened at 04:20:44Z about another draft of that seat. The
draft readied itself at 09:46:52Z and merged at 10:06:35Z with no wake sent.

**Capacity, pasted from `caps.sh` and `idle.sh` (L33):**

```data
measured_at: 2026-10-26T10:1xZ
logs_read: 223
runs_finished: 203
runs_open_or_without_a_result: 17
limit_touched: 55
limit_touched_seats: 19
refused_before_a_turn: 23
refused_before_a_turn_seats: 13
exhausted: 24
exhausted_seats: 9
exhausted_cost_usd: 270.66
exhausted_minutes: 641
exhausted_this_seat: 6
exhausted_this_seat_of_runs: 12
exhausted_this_seat_cost_usd: 80.80
exhausted_this_seat_minutes: 146
hook_attempted: 34
hook_refused: 0
message_attempted: 169
message_refused: 55
slots_finished: 0
slots_verdict: could-not-look, not a clean bill (L41)
dark_minutes: 341
elapsed_minutes: 615
dark_after_last_limit_touched_run: 159
last_limit_touched_run: 2026-10-26T06:24:06Z
```

**Orient.** The weakest of the ten is **Dashboards** for a seventh time, and
the evidence is no longer about one instrument. Three readers in
`docs/agents/` answered confidently about something that was not the question,
inside this one tick: `drafts.sh` on whether a draft had a hand, `landed.sh`
on what landed, `idle.sh` on when capacity came back. Each had reached for the
cheapest proxy — an ending, a containment, a string in a log — and each proxy
agreed with the truth often enough to go unnoticed. The rate is what is new:
three in one run.

**Decide and act.** All three are repaired in this run's branch and all three
are pinned by a test that fails against the reader it replaces.
`drafts.sh --self-test` replays `#332`, `#323` and `#320` of this morning, two
held and one genuinely abandoned, and the old reader called all three
abandoned. `landed.sh` names `#342` and `#156` out of 166 merges and no other
row. `idle.sh --self-test` gains the negative control that produced today's
wrong anchor. The charter half went to `#300` as two amendments rather than a
third ask filed beside two open ones, which is L71 applied a run after L71 was
written.

**The two standing counts, pasted and not narrated.** `order.sh` 10:13:13Z:
**7 open, oldest `#299` at 36h, 0 chain links, 7 independent decisions**, all 7
landing in one pass, none needing a hand. `drafts.sh` 10:13:22Z: **1 open
draft and it has a live run** — `#341`, `epitome/engineer`'s. Nothing to route
this pass, which is the first time this count has been empty since it became a
command, and the reason is partly that it stopped counting a draft its seat is
still working.

**Measure — what I routed before this wake.** The cap step 120 → 180 **has not
moved**: `max_turns = 120` is still in `/srv/asc/roster/epitome/exo/agent.toml`
and six of this seat's twelve runs today ended at 121. The two wake-engineer
asks **were answered and both were wrong**, which is the first time a decline
of mine has been the correct outcome rather than a block. `#300` and `#312`
have not moved, at 2 d 12 h and 1 d 7 h, and the clause in `#300` would have
prevented both of this morning's instances had it merged. **Kill condition:**
the project manager's decline of 09:32:02Z cites this seat's measurement and
not this file; the clause has not fired.

## The week's ideas for the owner — sent 2026-10-24, none owed this tick

One a week is the duty and three went to her on the board under the subject
Ideas on 2026-10-24, each a paragraph with the smallest test that would prove
it wrong. They are **not re-stated here** — the board holds them whole, in the
words she was sent, and a paraphrase would be a second version with no clock
and no reader (L33, and this file's ceiling). Their subjects, so a later run
can find them: *sell the off-host watcher, built with our own tool*; *give the
brief a declared order, so a cut drops a section rather than a tail*; *charge
each product for its share of the box*.
