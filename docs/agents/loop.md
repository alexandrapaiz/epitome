# Learning-loop ledger

This seat's half of the company learning loop (owner directive, 2026-10-17,
carried here as a handoff on the board; the standard's own text for it is not
yet vendored into this repository — incident 7). The clock is
`asc-brief.timer` on the host, 12:01 UTC daily: the board emits the brief and
the bus wakes this seat.

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
more than one line, and if a week passes with no decision, handoff or merge
anywhere citing a line of this file. Either one ends the file, and the cut is
logged as a lesson against this seat.

## The daily line

Runs, turns and refusals are read from the host's own run logs
(`/srv/asc/state/.epito/logs/*/<date>*.log`), portfolio-wide, because the
capacity is one pool and this product shares it with three others. "Dark" is the
longest stretch of the day with no run of any seat. The row is read at the tick
and says so; a day's counts keep moving after it.

```bash
cd /srv/asc/state/.epito/logs && D=$(date -u +%F)
echo "runs $(ls */$D*.log | wc -l)" \
     "turns $(grep -ho 'turns=[0-9]*' */$D*.log | cut -d= -f2 | paste -sd+ | bc)" \
     "refused $(grep -l 'session limit' */$D*.log | wc -l)" \
     "seats $(grep -l 'session limit' */$D*.log | cut -d/ -f1 | sort -u | wc -l)"
```

| Date | Runs | Turns | Refused | Dark | Weakest attribute | What it moved |
|---|---|---|---|---|---|---|
| 2026-10-18 (read 12:06Z) | 253 | 16,079 | 65 (25.7%) | 342 min, 121 of them after capacity returned | Dashboards | incident 8, L18, the capacity experiment, three ideas to the owner |

## Tick of 2026-10-18 — the first

**Observe.** 253 runs on the host today across 38 seats and four companies,
16,079 turns between them. Sixty-five of the 253 were refused outright by the
model provider's session limit, in two windows (01:57–02:42Z and 09:29–09:57Z),
and every refusal was recorded as a run that failed. Thirty-seven did not get
past turn one. None of the 65 opened a pull request, and nothing re-delivers the
messages they consumed. This product's own share: 34 project-manager runs for
1,292 turns, 10 engineer runs for 575, 4 of this seat for 265; 11 of its 48 runs
refused. Across the portfolio, the project-manager seats are 123 of the 253 runs
and 36.4% of the turns. Full record: incident 8.

**Orient.** Of the growth model's ten attributes — the purpose, then staff on
demand, community, algorithms, leveraged assets and engagement, then interfaces,
dashboards, experimentation, autonomy and social technologies — the weakest here
today is **dashboards**, and today is the first day that is demonstrable rather
than arguable. The company lost a quarter of its runs and five and a half hours
and no surface said so: the board records a run's exit code and uses the same
value for refused and failed, the brief that went out at noon counted eight
shipped items and no run at all, the one daily instrument whose subject is the
host has been in `failed` since 07:00Z, and the number that mattered existed only
in the footers of 253 log files. Not the runners-up, and why: algorithms and
autonomy are this company's strength — 253 unattended runs is the evidence —
and experimentation is weak but instrumented, with one trial on the frameworks
register, one scorecard written at cycle 1's cooldown and a binding review the
owner set for the end of cycle 2, which opened today.

**Decide — the week's experiment.** Publish one number daily and see whether it
changes a decision. The number is the capacity line in the table above, computed
from the host's own logs by the command named with it, and it is deliberately not
a new framework: the frameworks register permits one trial at a time and Shape Up
holds that slot until the end of cycle 2. The prediction, so that the experiment
can fail: the session limit will refuse at least one run again before 2026-10-25,
and the project-manager seats will still be the largest spender of turns at over
thirty percent. Kill condition, by default: if on 2026-10-25 no decision, handoff
or merge anywhere cites a line of this file, the file is cut and the cut is the
lesson. Ceremony cost, measured: the whole line took four shell commands this
tick and is the only thing in it that will repeat.

**Act, under the merge rule.** Company standard §21 makes merges the project
managers' and the chairs', so what this tick does itself is what it owns — the
registers, this file, and a charter patch for its own charter — and everything
with another owner left by the route that owner reads. The runtime change behind
incident 8 went to `epitome/pm` for the engineer seat with the measurement
attached; the capacity decision only the owner can make went to
`alexandra-systems/pm` under this seat's not-landing clause; the brief's missing
numbers and the pass clock on a handoff went to HQ's centralizer, whose files
they are. None of it waits on this seat's own hand.

**Measure — the previous experiment.** There was none; this is the first tick.
What there was to measure instead is what this seat routed this morning, which
its charter requires it to read back: the stale runtime on the host, handed to
`alexandra-systems/pm` at 09:07Z, and the clockless roster with the dead health
post, handed to the same seat in the drift review. Neither has an item on HQ's
board. The pre-existing item for the runtime upgrade sits in HQ's backlog,
created yesterday, assigned to a chair. I am not escalating either one, because
the reason they did not move is the finding above: of HQ's project manager's nine
runs after 09:07Z, one completed and eight were refused by the same limit, seven
of them at turn one. The standard gives a handoff two passes before the
destination has failed it, and today the passes did not exist.

## The three ideas for the owner, 2026-10-18

Sent to her on the board under the subject Ideas. They are not in
`docs/ideas.md` yet on purpose: three open pull requests already append to that
table, and a fourth appender is exactly the conflict the ledger contract tells a
seat to prevent, so the rows are asked of this product's project manager once its
own three have merged.

**One: sell the capacity meter.** This product's whole business is running other
people's agents, and today it produced the one number no agent platform shows its
operator — turns spent per seat per day, runs refused, minutes dark — by
accident, in log footers, and threw it away. Her decision is whether the MVP's
scope grows by one surface. Smallest test: publish this single table at a public
address for one week from the host's own logs, and count whether she opens it
more than once and whether the three partner companies' project managers cite it.

**Two: give every seat a turn budget in its manifest.** Thirty-six percent of the
portfolio's capacity goes to project-management passes and eighteen of this
repository's twenty-two open pull requests are one seat's bookkeeping from one
day. A budget per seat, visible in the brief, makes the scarcity the seat's own
problem instead of a charter's: a seat that spends its day on passes has less
left for work. Her decision, because a budget changes what a seat may do and §21
reserves a seat's own authority to her. Smallest test: budget one seat — this
product's project manager — for one week at its own median, and count passes and
merges against this week's.

**Three: declare an order of precedence among the four companies.** All four
share one session limit, so a quiet company's bookkeeping pass can take a loud
company's build dark, which is what happened at 09:29Z today. The bus already
carries a company on every event, so the host could hold the lower-priority
company's work when capacity runs short and spend what is left on the company
whose day it is. Her decision because nobody else can rank her own companies.
Smallest test: declare the order for one week and count the refusals the
last-ranked company takes against today's 65.
