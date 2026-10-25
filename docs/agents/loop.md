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
| 2026-10-24 (read 00:12Z, 12 min into the day; reread 16:35Z on the capacity-return wake; reread 17:04Z on a three-note wake; **reread 17:3xZ** on the merge of #283; **reread 21:4xZ** on a second capacity-return wake; **reread 22:1xZ** on a message wake from this product's project manager; **reread 22:2xZ** on three wakes at once — #294's merge, this product's project manager handing the charter re-cut back, and HQ's project manager routing the cap finding to HQ's engineer) ; **reread 22:5xZ** on two wakes — #298's merge and this product's project manager declining to merge #300 because one of its four files was this seat's own charter| 9 so far → 252 finished, 23 open → 253 of 276 → 272 of 291 → 337 of 365 → 376 of 398 → **386 finished of 413**  → **402 finished of 429, 27 open**| — → 16,001 → 17,876 → 19,416 → 23,195 → 25,884 → **27,165** (the 5 logs reading `turns=-` no longer break the sum; the pattern is anchored to digits)  → not re-read this tick: `caps.sh` reports runs, cost and minutes and not the turn sum, so 27,165 stands as a 22:2xZ reading and this tick does not restate it (L-A34 — the vantage point is named rather than the number carried)| 0 → 13 before a turn (11 seats), 27 mid-run → **28 before a turn (16 seats), 44 mid-run, and a third class this file had never counted: 21 runs exhausted their own turn cap, 9 seats, 4 companies, $238.22 and 530 min, 14.7% of the day's $1,623.25** → 27 exhausted, 10 seats → **29 exhausted on 10 seats, $346.04 and 752 min that bought nothing**, 5 of them this seat's at cap 120 for $65.05 — the class L51 named fired twice more in the 35 minutes while HQ's project manager was routing it, which is the re-measurement a shipped fix owes (L-X1 as amended)  → **72 refused before a turn across 25 seats** (read off `caps.sh`'s REFUSED column, which `idle.sh` corroborates at 72 runs touching a limit), and **31 exhausted on 10 seats, $368.01 and 802 min that bought nothing** — two more exhaustions and $21.97 in the 30 minutes since the last reread, 5 of the 31 this seat's at cap 120 for $65.05| — → **250 min from 02:09Z** longest, and 645 dark of 1,020 elapsed (63%) → **648 of 1,053 (62%)**, summed over every gap by interval union, longest 250 min from 02:09:56Z; this seat 155 min from its 13:49Z refusal, of which 5 after capacity returned at 16:20Z, against 121 on 10-18; at 21:4xZ **815 dark of 1,300 (63%)**, same longest gap, and this seat 171 min from its 18:25Z refusal of which **0 after capacity returned at 21:20Z** — the retry queue woke it inside ten seconds; at 22:1xZ 814 dark of 1,330 (61%), same longest gap; at 22:2xZ **813 dark of 1,343 (61%)**, 168 min of it after the day's last refusal at 18:33:01Z (21% of the dark), longest gap still 250 min from 02:09:56Z  → at 22:5xZ **812 dark of 1,365 (59%)**, longest gap still 250 min from 02:09:56Z, and **167 min of it after the day's last refusal at 18:33:01Z (21% of the dark)**| Dashboards ×4 → **autonomy**: the fourth naming was the test and it discriminated, because the day's largest unpriced loss is seats unable to change the one number that ends their own runs  → **autonomy**, and the fifth naming adds the second instance of its own shape: this seat cannot raise the cap that ends its runs and cannot start the clock that releases its own charter, because both writes are in files no product seat's credential may touch| L34, L35, incident 15, `brief.sh`, the chain fix in `order.sh`, the four engineer charter patches applied, three ideas to the owner; reread adds L47, incident 23 and `shipped.sh` — incident 12's defect fired 54 times in 110 runs across eight seats while its fix sat merged and undeployed; **second reread adds L48 and `reread.sh`**, and #283 merged at 16:52:43Z so the first reread's work is on `main`; **third reread adds L50, incident 24 and `offmain.sh`**, and carries eleven lessons, seven incidents and five detectors off the charter chain and onto a branch based on `main` — they were law nowhere for 4h42m and L36 for the whole day; **fourth reread adds L51, incident 25 and `caps.sh`**, the partition fix in `doors.sh` (the queue count was 11 of 12), the amendment L50 owed to the one-pull-request ceiling, and `offmain.sh` now reports nothing of this register off `main`; **fifth reread adds L52, L53, incident 26, `clocks.sh` and `addressed.sh --can`** — no silence clock has ever run in this company, because `expires_at` is unsettable on an ask, so the clock the fourth reread deferred to and the clock L50 now owes on a deferred patch are both unstartable; **sixth reread adds L54 and `addressed.sh --inbox`** — the inbox read every charter opens with returns 100 rows at a limit of 100, 93 of them addressed to no seat, because `everyone` defaults to true and `0` is the only false it honours, and the exo charter is re-cut onto `main` as one charter alone after this product's project manager declined to carry it ; **seventh reread adds L55 and the split epitome/pm's refusal was right about** — #300 carried four files, three of them in the project manager's own hand, and its body named them as excluded from the owner's clock, which the merger read and could not act on because an exclusion in prose has no click; #300 now carries `prompts/exo-agent.md` alone and #301 carries the register off `main`, and the charter clause that produced the bundle is replaced by the one that prevents it. Incident 26 re-measured at 22:4xZ: **39 prose clocks, 0 carrying `expires_at`**, against 36 and 0 at 22:0xZ, with the writer unchanged at HQ `6d08115` — a rise while the writer stands still, which is a second instance of the class and not three new entries|

## Tick of 2026-10-24

**Observe** (reread 21:3xZ, no brief behind this wake — `brief.sh` reports no
`brief.sent` in the events window, so this tick's declared input was absent and
the row says so rather than inferring it). The day finished with **365 logs,
337 finished runs, 23,195 turns** portfolio-wide and $1,623.25 of model spend.
Refusals: 28 before a turn across 16 seats, 44 mid-run. **And a third class
this file had never counted: 21 runs ended at their own turn cap**, nine seats
in four companies, $238.22 and 530 minutes, three of them this seat at 121
against a cap of 120.

The drag is unchanged and is now measured against a working deploy rather than
against a date. `python3 /srv/asc/hq/tools/check-host-deploy.py` prints HQ's
two checkouts `current … at c38a83c` and this product's `runtime` row
`stale … 5836dc0`, **624 commits behind**, against 588 at 17:36Z and 366 on
10-18. The chair deployed HQ to this host ten times between 16:53Z and 21:36Z.
Six open-fix rows wait on one `systemctl restart epitod`, and the window for
it has been asked for and unanswered since 17:10:54Z.

**Orient.** Weakest of the ten, fourth reading of the day and **the attribute
changes**: not dashboards but **autonomy**. Dashboards earned the naming while
the brief was cutting a third of itself; that repair is HQ's and is moving.
What this reread found is a company whose seats cannot change the one number
that ends their own runs. Twenty-one runs died at a cap, nine seats, no cap
stepped, and the instrument the company's rule names for it reads a surface
the seats left — and the step is two files, one of which no product seat's
credential may write. That is autonomy measured the only way it can be: by
what a seat can fix about itself without a hand.

**Decide — the week's experiment.** Keep the capacity line and widen it by one
class: **every tick runs `bash docs/agents/caps.sh` and the row carries
exhaustions beside refusals.** Prediction, so it can fail: on 2026-10-31 the
portfolio still shows exhaustions at exactly cap+1 on at least three seats,
because raising a cap here needs a workflow write and a daemon restart and
neither has a standing hand. Fewer than three, the experiment is wrong and the
walls were softer than measured. The 2026-10-24 experiment stands and is
measured below.

**Act, under the merge rule.** Mine this run and in this pull request: L51, the
amendment to L50, incident 25, `docs/agents/caps.sh`, the partition fix in
`doors.sh`, the fixed capacity command and this file. Not mine: the cap step
needs a workflow write, the restart needs a window, and both go to the project
managers. **No charter patch**, for the reason the pull request gives.

**Measure — the 2026-10-24 experiment.** It predicted that on 2026-10-31 the
brief's footer would still count characters, and that each tick would first run
`brief.sh`. The second half ran tonight and returned "no `brief.sent` in the
window the events route returned" — the input this loop declares is not there
on a hook wake, which is a finding about the experiment's own instrument and is
recorded in the row rather than smoothed over. The 2026-10-18 experiment's two
predictions both held and are retired.

## The three ideas for the owner, 2026-10-24

Sent to her on the board under the subject Ideas. Each is one paragraph and
the smallest test that would prove it wrong.

**One: sell the off-host watcher, built with our own tool.** We just spent
four days seventeen hours dark on a box carrying the board, the bus, the
database and every clock, and what eventually noticed was a person looking at
a disk. Every agent company being built this year has that same box. HQ has
already derived the threshold — fourteen hours, zero false positives against
1,365 recorded gaps — and `epito` already mints the identity and the trigger
such a watcher needs, so this is not a new product, it is the first thing
`epito` would be used to build in public. Her decision, because it changes
what the MVP is for. Smallest test: stand one up against our own host on
somebody else's clock for a week, publish its readings at a public address,
and count whether one outside operator asks for their own.

**Two: give the brief a declared order, so a cut drops a section.** The brief
is her one surface and a third of it is cut before anyone reads it, asks first
out the door. The repair is a product decision and not an engineering one:
declare the brief's sections and the order in which they survive a shortened
window — asks, money, capacity, then shipped — and tell every reader which
sections it did not get rather than how many characters. Hers because the
order states what she wants to know first. Smallest test: reorder the brief,
change nothing else, and count for a week how many Needs-you asks are answered
within a day against the four standing unanswered tonight.

**Three: charge each product for its share of the box.** The disk that filled
had no owner because it had no price: four companies share one machine and
none of them carries a line for it, so no seat had a reason to watch it. A
monthly shared-services line per product, computed from the roster and the run
log, makes the scarcity somebody's problem instead of nobody's — this product
spent 21 of yesterday's 92 runs and would see its own number. Hers because it
is a ledger that crosses her companies. Smallest test: compute one month for
all four, put it in the finance register as a real line, and watch whether the
first product to read its own number asks for anything to move off the box.
(HQ's centralizer reached the same proposal last night from the other end.)

<!-- run 2026-10-25-hook: vehicle opened before the work (L-E3, L-A97). -->
