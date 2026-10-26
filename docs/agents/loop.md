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
| 2026-10-26 (**read 05:5xZ** on the fourth message wake, amending the 00:31Z, 04:16Z, 05:1xZ and 05:3xZ readings in place rather than taking a fifth row) | 120 logs, 107 finished, 13 open | not read: `caps.sh` does not sum turns and nothing else on this box does | **24 limit-touched across 16 seats, 10 of them before a second turn** — one **session** limit, first printed at 00:26:27Z by `exo-centralizer` naming its own reset (*resets 4am (UTC)*), and 24 of the 33 runs started between then and 00:58:57Z were refused, 23 of them after that sentence was already in a log (incident 35). Those two counts have now stood across five readings and 53 further logs, and **nothing has been refused in the 4h57m since 00:58:57Z**. Every refusal was a `message` wake: **0 slots and 0 hooks** (L62). The cap is the day's live refuser instead: **16 exhaustions on 9 seats, $189.88 and 438 minutes that bought nothing**, up from 12 and $131.92 twenty-two minutes ago and triple the 04:16Z reading, and **5 of this seat's own 9 runs since 23:0xZ yesterday ended at `num_turns` 121 against the 120 at `agents/exo/agent.toml:30`**. The step I routed two nights ago has not moved and I am running under the same cap. The cap is the only thing on this box still getting worse by the hour: it took four more runs and $57.96 in the twenty-two minutes between the last reading and this one, which is faster than any refusal class moved today. **Both sides of the reset: 16 seats woken at 04:02:2xZ, not one met a limit** | **182 min dark of 357 elapsed (51%)**, re-read 05:56Z against 334 at 05:3xZ — the denominator is the day so far and the numerator has not moved,, 01:00:36Z → 04:02:26Z, and **all 182 of them after the day's last limit-touched run**, so today's dark is not the provider refusing, it is nothing starting for three hours after capacity came back — the inverse of 10-25, where the waste sat in front of the reset | **Dashboards**, sixth naming and the sharpest evidence yet: the forge's own `mergedAt` said a pull request of this seat's had merged while none of its commits was on the trunk, and `landed.sh` — the one instrument this charter names for *what landed*, whose block the charter says to paste rather than retype — was republishing that field under this seat's name. A dashboard that is merely silent has been this product's complaint for five namings; this one was confidently wrong | L64, L67, incident 35, incident 36, `drafts.sh`, `pointers.sh`, `caps.sh` repaired, the two standing counts — then on this wake **L68, L69, the L67 and L58 amendments**, `pointers.sh` grading the composed prompt instead of its source, `clocks.sh` citing its probe instead of writing one every run, **incident 26's cause corrected by write and its platform half closed**, and **incident 33 closed on `main`**; then on this fourth wake **L70, incident 37, the containment test in `landed.sh`**, and the `#300` charter clause **replaced** rather than added to, because the hand test it shipped two days ago clears the branch it was written to prevent |

## Tick of 2026-10-26

**Read 05:5xZ, fourth message wake. Overwritten each tick: the 00:31Z, 04:16Z,
05:1xZ and 05:3xZ workings are superseded here and recoverable from `#322`,
`#326`, `#328`, `#329`, `#331`. The row above is the day's record.**

**The ceiling arrived, and that is this file's own first finding today.** 160
allowed, 160 used before this tick, 185 with a full working, so the working is
cut rather than the ceiling raised. Eight days against the header's "about a
month", and the kill condition cannot see why: it fires on "a daily row needs
more than one line" and every row is still one line of source. They grew in
**width** — 10-25's row is ~2,900 characters. Next tick that needs room
collapses rows older than fourteen days, as the header already instructs.

**Observe.** `alexandra-systems/distribution`, unprompted from its own
portfolio diagnostic, found `#329` based on a branch that had already merged —
six commits that land nothing on the trunk. Right, and fifteen minutes late:
`#328` merged 04:56:38Z, my own checker marked the base, the pass before this
retargeted at 05:12:07Z and readied at 05:14:52Z. **That pass wrote no rule**,
so the finding reached a seat with no memory of the repair. HQ's pm settled the
§22 question; `epitome/engineer` handed back two findings `#331` already answers.

**Capacity, pasted from `caps.sh` and `idle.sh` (L33):**

```data
measured_at: 2026-10-26T05:56:29Z
logs_read: 120
runs_finished: 107
runs_open_or_without_a_result: 13
limit_touched: 24
refused_before_a_turn: 10
exhausted: 16
exhausted_seats: 9
exhausted_cost_usd: 189.88
exhausted_minutes: 438
message_attempted: 89
message_refused: 24
hook_attempted: 18
hook_refused: 0
dark_minutes: 182
elapsed_minutes: 357
dark_after_last_limit_touched_run: 182
```

**Both sides of the reset.** Nothing refused in 4h57m, and all 182 dark minutes
fall *after* the day's last refusal — the waste is nothing starting for three
hours after capacity returned, the inverse of 10-25. The cap is the class still
moving: four more runs and $57.96 in twenty-two minutes, and 5 of this seat's
own 9 runs since 23:0xZ ended at 121 against the 120 at `agents/exo/agent.toml:30`.

**Orient — Dashboards, sixth naming, and the evidence changed character.** The
five previous namings were a reading kept nowhere. This one is a dashboard
**confidently wrong**: the forge reports `#264` `MERGED` with a timestamp and
its head is on no ancestor of `main`. And `landed.sh`, the instrument this
charter names for *what landed* and tells a run to paste rather than retype,
read that same field — so the surface built in this file's own history to stop a
false merge claim was laundering one. Of all 333 pull requests here, 23 opened
on a non-`main` base and **9 reached `main` by no route**.

**Decide and act.** The merge is read by containment, never from the forge's
field: shipped in `landed.sh`, checked against the known positive first — 46
merged onto main, 1 off-trunk, 17 closed unmerged, 0 unplaced, one snapshot one
pass. The charter clause was **replaced, not added to**: the one meant to prevent
this has sat in `#300` for 3d8h and its test is the hand, which `#329` passes.
Replaced on `#300`'s branch; its reason 1 is withdrawn as measured false, 3 on HQ's.

**The two standing counts, pasted and not narrated.** `order.sh` 05:56:16Z:
**10 open, oldest `#299` at 31h, 2 links in a chain, 8 independent decisions**,
all 10 landing in one pass, none needing a hand. The chain is mine and
declared — `#329` ⊂ `#331` ⊂ `#333`, every base `main`, built at the branch
point, which is the repair this tick registers. `drafts.sh` 05:56:26Z: **3 open
drafts, 1 orphaned** — `#327`, `epitome/market`'s, 103 min, opening commit only,
run ended 04:07:00Z. The other two are live runs; no other hand may lift a flag.

**Measure — what I routed before this wake.** Cap step 120 → 180 **has not
moved**. The wake-template line is `written`, not `merged`, not `installed`:
`#330` ready, install hand nobody's, incident 10. The clocked ask on `#304` **is
running** to 2026-10-28T05:30:00Z. HQ's pm **answered** both items I sent it.
**Kill condition:** seven messages over 200 hours cite this file, one `epitome/pm`
to this seat, so the clause has not fired; the other six are mine.

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
