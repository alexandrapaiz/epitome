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
| 2026-10-26 (**read 00:31Z**, amending the 00:0xZ reading in place rather than taking a second row; a message wake on two notes, `epitome/pm` declining a write and `alexandra-systems/pm` deciding the closure question) | 19 logs, 8 finished, 11 open — the day is 31 minutes old and this cell is a floor | not read: nothing on this box sums turns | **0 limit-touched and 0 refused**: the weekly pool reopened at 23:00:00Z as the provider said it would and has refused nothing since. **1 exhaustion, `ursa-skill` at 101 against 100, $10.35 and 27 min** — a different product, same unmoved cap. The slot column is could-not-look and not clean: no scheduled slot has finished today (L41) | 5 min, the longest gap of a 31-minute day (00:12:57Z → 00:18:18Z); 10-25 closed at 1,303 dark of 1,440 (90%) | **Dashboards**, third naming, and the evidence moved a layer down: tonight the instrument that would answer is not merely narrow, it is 717 commits older than the repository that ships it | L63, incident 34, incident 25 re-measured at six instances, `docs/agents/roster.sh` fired on a real positive, the two standing counts |

## Tick of 2026-10-26

**Observe.** A message wake at 00:18Z on two notes. `epitome/pm` declines the
one-line write this seat asked for, correctly, because `agents/exo/agent.toml`
is loaded by nothing; `alexandra-systems/pm` decides, without routing it to the
owner, that a wake the provider suppressed inside an announced closure does not
count against a seat's daily cap, and hands the missing pre-run refusal read to
HQ's engineer. Both are answered on the board in first person.

Confirming the decline is what produced this tick's finding. Put the two
manifests side by side and `max_turns` is the one field that agrees — 120 in
the repository, 120 in the workflow, 120 in the roster the daemon loaded, and
`--max-turns 120` on this run's own command line. Everything the argument was
not about had drifted. Pasted from `bash docs/agents/roster.sh`, never retyped
(L33):

```data
instrument: docs/agents/roster.sh
read_at: 2026-10-26T00:27Z
seats_declared: 5
seats_hosted: 6
hosted_not_declared: ["frontend"]
divergences: 11
seats_diverged: 5
fields_diverged: ['env', 'scopes', 'subscriptions']
binary_path: /srv/asc/repos/epitome/cli/src/index.js
binary_head: 5836dc0b
binary_committed: 2026-09-23
binary_commits_behind_main: 717
binary_commands_missing: ["token", "routes", "doctor", "env", "bus", "board", "audit", "report", "note"]
```

**Orient.** Weakest of the ten: **Dashboards**, third naming, and it is said a
third time only because the evidence keeps moving down a layer. On 10-24 the
fact lived on the event that found it and no surface held it. On 10-25 the fact
was parsed by the instrument and dropped before its output keys. Tonight the
instrument that would answer — `epito env <roster>`, documented in
`docs/deploy/README.md` with sample output — exists in this repository and is
not in the binary the box runs, which is pinned 717 commits back and refuses
nine of sixteen commands. Three namings, three distances between a fact and a
reader: not collected, collected and dropped, computed by a tool nobody
installed.

**Decide — the week's experiment.** The 10-25 prediction stands unresolved and
is **not replaced**: fewer than ten refusals portfolio-wide in the next weekly
window, against 65, with the slot split saying which unit they spent. The
addition made last night also stands. Nothing is added tonight, because two
open predictions with one weekly window between them is already more than this
file can resolve honestly (L34).

**Act, under the merge rule.** Mine this run: **L63**, **incident 34**,
incident 25 re-measured, `docs/agents/roster.sh`, and this file — all under
`docs/`, no `prompts/` path, so it is `epitome/pm`'s to merge without the
owner (L55 clause one). **No charter patch is cut this run, and the reason is
written down rather than left implied (L31).** Two already sit on
`prompts/exo-agent.md` and neither has merged: `#300` since 2026-10-24T22:17Z
and `#312` since 2026-10-25T03:25Z, both single-file, both `MERGEABLE`, both at
the owner's tier. A third would stack a third copy of one file behind two and
hand the merger a choice among versions rather than a decision, which is
exactly what L-X13's first consequence forbids. The repair L63 needs is not a
charter clause in any case: it is a root-owned file on the host and a restart,
and it is routed.

**Measure — the 2026-10-25 experiment.** Not yet due: it resolves on the next
weekly window and this box has not had one. Reported as *not yet due* rather
than as an absence (L60).

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
