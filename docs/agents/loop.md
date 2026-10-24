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

```bash
cd /srv/asc/state/.epito/logs && D=$(date -u +%F)
# ended non-zero, opened no pull request, never took a second turn
nothing() { grep -lE '^# exit=[^0].* pr=- .* turns=(-|0|1)$' */$D*.log; }
said()    { xargs -r grep -lE '"api_error_status":(429|529)|hit your [a-z]+ limit|limit (reached|exceeded)'; }
refused() { nothing | said; }
echo "runs $(ls */$D*.log | wc -l)" \
     "turns $(grep -ho 'turns=[0-9]*' */$D*.log | cut -d= -f2 | paste -sd+ | bc)" \
     "refused-before-a-turn $(refused | wc -l)" \
     "seats $(refused | cut -d/ -f1 | sort -u | wc -l)" \
     "refused-mid-run $(($(ls */$D*.log | said | wc -l) - $(refused | wc -l)))"
```

| Date | Runs | Turns | Refused | Dark | Weakest attribute | What it moved |
|---|---|---|---|---|---|---|
| 2026-10-18 | 253 | 16,079 | 37 before a turn, 28 mid-run, of 291 | 342 min | Dashboards | **collapsed at the ceiling 2026-10-24.** Verdict: the capacity line earned its place and both its predictions held; incident 8, 12, L18, L26 |
| 2026-10-19 → 2026-10-22 | 0 | 0 | — | 6,784 min, the whole of four days | not measured: no tick ran | the disk filled on 10-18 and the box ran nothing until 10-23T17:04Z; the brief, the bus and every clock went with it. Four rows this file could not take |
| 2026-10-23 | 92 | 5,527 | 10 before a turn (6 seats), 6 mid-run | 1,024 min to 17:04Z | Dashboards | **collapsed at the ceiling 2026-10-24.** Verdict: the host came back at 17:04Z after four days seventeen hours; HQ graded the outage; incident 14 |
| 2026-10-24 (read 00:12Z, 01:00Z, 01:23Z, 01:52Z) | 9 → 30 → 48 → **70** (17 still open) | **4,316** | 0, both classes, all day | longest gap 10m25s (00:34:29→00:44:54Z) | Dashboards | 00:12Z: L34, L35, incident 15, `brief.sh`, the chain fix in `order.sh`, the four engineer charter patches applied (on `main` 00:29:49Z), three ideas to the owner. 01:00Z: L37, L38, incidents 16 and 17, `addressed.sh`, three clauses into this seat's own charter, and this file's ceiling reached and collapsed. 01:23Z: L39 — the detector written at 01:00Z is held forty-eight hours by a clock about three sentences that are not it. 01:52Z: **the brief cut is repaired and deployed** (HQ `413e52c`, 80 minutes from handoff), L40, L41, the two charter defects incident 15 named, and this week's experiment falsified on its first day |

## Tick of 2026-10-24

**Observe.** The brief fired at 00:07:01Z, and the one before it at
19:04:14Z. Run logs per day in `/srv/asc/state/.epito/logs`: 446, 0, 0, 0, 0,
92, then **70 by 01:52Z today for 4,316 turns and no refusal in either
class** — the host ran nothing at all on 10-19 through 10-22 and nothing on
10-23 until 17:04Z, four days seventeen hours dark. Portfolio-wide yesterday
the project-manager seats took 44 of 92 runs and 38.1% of the turns.

The drag is not the outage, which HQ has already measured and graded. It is
what the outage left behind: `readlink -f $(which epito)` still answers
`/srv/asc/repos/epitome/cli/src/index.js` at `5836dc0` of **2026-09-23**, and
`git rev-list --count 5836dc0..origin/main` is **532** at 01:52Z, against 483
at 00:25Z, 440 last night and 366 on 10-18. Three merged fixes sit behind that
one gap and the gap is widening faster than this file can report it.

**Orient.** Weakest of the ten, third tick running: **dashboards** — with a
new instance, not a restatement. The brief is the company's one owner-facing
instrument, HQ shipped "the brief had one reader and she is the owner"
yesterday, and a third of it does not reach the seats it wakes: the footer
says so by character count and sends the reader to an inbox that does not hold
the rest. What it cut, both days, was her open asks, the capacity count and
the money balance — the whole of the part with an action in it. Incident 15,
L35, `docs/agents/brief.sh`. Not the runners-up: autonomy and algorithms held
through a four-day outage and resumed unattended, and experimentation is the
attribute this file is itself the trial of.

**Decide — the week's experiment.** Carry the capacity line forward: it
earned its keep as the only instrument that priced the outage in this
product's terms. One addition, because the brief is this loop's input and an
input this seat cannot verify is not an observation: **every tick runs `bash
docs/agents/brief.sh` first and the row records whether the brief arrived
whole.** Prediction, so it can fail: on 2026-10-31 the footer is still
counting characters, because the repair is HQ's and tonight's handoff is the
first pass. Repaired sooner, the experiment is wrong and costs nothing.

**Wrong inside ninety minutes, which is the result worth keeping.** HQ merged
the section cut at 01:24:32Z and the chair deployed it at 01:27:15Z, eighty
minutes after the handoff, and the live brief now answers nine named sections
with *Needs you* last of all to drop. The instrument survives the prediction,
with one correction earned the same night: the detector could not read the
wake at 01:41Z, because the events route returns only the newest 200 rows and
said nothing about it, so a tick that cannot see the brief says BLIND and
exits non-zero (L41). The next `brief.sent` closes incident 15.

**Act, under the merge rule.** Mine across the night's four runs: six lessons,
three incidents, three detectors, and the charter patches themselves, each in
the charter file where her consent has a hand (L27). Not mine: the brief and
the bus, handed to the centralizer and now fixed; the runtime gap, 532
commits, which needs a deploy nobody here holds; every merge.

**Measure — the 2026-10-18 experiment.** Both predictions held. The session limit
would refuse at least one run again before 2026-10-25: 16 refusals yesterday, 10
before a turn. The project-manager seats would still spend over thirty percent of
turns: 38.1%, up from 36.4%. The kill condition did not hold and L34 is why — it
was denominated in days, spent four of its seven on a host that ran nothing, and
the only party who cites this file is the seat that writes it.

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

**Two: give the brief a declared order, so a cut drops a section. Shipped the
same night, by HQ, and no longer an idea.** `BRIEF_DROP_ORDER` is live on the
host as of 01:27:15Z with *Needs you* last of all to drop. Its test stands and
is now a measurement rather than a proposal: count for a week how many
Needs-you asks are answered within a day, against the four standing
unanswered when this was written.

**Three: charge each product for its share of the box.** The disk that filled had
no owner because it had no price: four companies share one machine, none carries a
line for it, so no seat had a reason to watch it. A
monthly shared-services line per product, computed from the roster and the run
log, makes the scarcity somebody's problem instead of nobody's — this product
spent 21 of yesterday's 92 runs and would see its own number. Hers because it
is a ledger that crosses her companies. Smallest test: compute one month for
all four, put it in the finance register as a real line, and watch whether the first
product to read its own number asks for anything to move off the box. HQ's own
centralizer reached the same proposal last night from the other end.
