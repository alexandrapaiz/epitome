# Incident register

Owned by the ExO seat. Blameless by construction: an incident entry
names what happened, what the org learned, and what changed — never a
seat at fault. An incident is a run that failed its charter, corrupted
state, or leaked something; owner quality feedback on a shipped
artifact is NOT an incident — it is lesson material and goes to
docs/agents/lessons.md.

Format per entry: date, what happened (facts only), impact, root cause
in the system (charter gap, missing lesson, tooling), the fix shipped,
where that fix currently is, and the lesson it produced (link). "Fix
shipped" is a claim about `main` and nothing else: a fix on a branch, in
a handoff or on a board item is named as such, with the one thing
blocking it, and the entry stays open until this seat's next run
re-measures it (L20). The current measurement of every open fix is the
last section of this file, replaced each run; an entry's own fix-location
line carries the time it was written and is history after that.

## 2026-09-18 — Founding-night note (not an incident)

The org's first three owner corrections — the cycle briefing ("looks
like marketing"), the architecture document ("product architecture not
operations architecture"), and the architecture deck ("missing tooling
... not a detailed internal and comprehensive plan") — were quality
feedback on live-convened work, not failures: no charter was violated,
no state corrupted, nothing leaked. All three were absorbed as lessons
L1–L3 in docs/agents/lessons.md, with L4 capturing the repeat pattern.
Recorded here so the register's first entry marks the boundary:
correction is fuel, incident is breakage.

## Incident 1 — 2026-09-19 — Architecture deck abandoned after five revisions

**What happened.** The epito architecture presentation was revised
five times on successive owner corrections and then abandoned. Owner's
words, verbatim: "highly dissatisfied with the presentation still we
will abandon for now. ursa did a much better job."

**Impact.** The cycle's architecture artifact has no owner sign-off;
five revisions of chair time spent; the owner's confidence in
owner-facing artifacts from this org lowered against Ursa's.

**Root cause hypothesis (blameless).** Feedback-loop iteration beat
exemplar study. Each revision patched exactly the gap the owner named
(rev 3 added toolchain, dependency budget, testing, threat model; rev
4 added infrastructure and the connective stack) without ever reading
the artifact she had already approved in the same genre: Ursa
docs/design/product-plan.md and its rendered deck, the Incident-3 redo
that satisfied the engineering-artifact standard. Iterating on
described feedback converges on the description; studying the exemplar
would have shown the whole shape at once. Concretely, the abandoned
docs/architecture.md (231 lines) never met two requirements the
668-line exemplar meets literally: no diagram specified node by node
and edge by edge (engineering-artifacts.md req 1; exemplar §11 gives
three), and no real example payload anywhere — no filled agent.toml,
no sample principals.json record (req 3; the exemplar embeds real
trial JSON, "no invented figure"). Milestone done-conditions and
literal command blocks were also thinner than the exemplar's §4b and
§5. The check each revision ran was "did I add what she named," never
"does this pass the standard's checklist" or "does this look like the
artifact she approved."

**Corrective action.** Any owner-facing artifact in a genre the owner
has previously approved anywhere in the portfolio STARTS from reading
that approved exemplar in full, before the first draft. Centralized as
HQ standards/lessons.md L-A7 (interim rule, HQ incident 1); lesson L7
here.

**Standards verdict.** No standard patched: engineering-artifacts.md
already forbade what shipped (reqs 1 and 3 unmet), and documents.md
was written mid-sequence. The failure was execution and
exemplar-blindness, not a gap in the law.

## Incident 5 — 2026-10-18 — A second run overwrote a partner seat's pull request body

**Numbering.** Incidents 2 and 3 were written into #26 and #32 and
incident 4 was reserved for #32; all three pull requests were closed
unmerged on 2026-09-30, so those entries never reached this register and
`docs/agents/drift-2026-10-05.md` still refers to them by number. This
run renumbers nothing and takes the next free number.

**What happened.** An engineer seat of alexandra-systems runs on this
product's resident host, as the first customer of runtime v0. On
2026-10-18 it wrote its run's pull request body to a fixed path under
the system temporary directory, another run on the same host wrote the
same path between that write and the read back, and the seat published
the other run's report as its own pull request description. Its words to
our project manager on the board at 08:45:51Z, verbatim and in full:

> Every seat your runtime opens on this host shares one temporary
> directory, because the windows run as the same user in the same
> namespace.
>
> This run wrote its pull request body to a fixed path there and another
> seat's run overwrote it between the write and the read, so I published
> somebody else's report into my own pull request before I noticed the
> headings were not mine.

The seat corrected its own body before this entry was written, so the
record of the corruption is that note rather than the artifact, and this
entry quotes the note instead of reconstructing what it said.

**Measured from inside a window on the same host, this run.** `TMPDIR`
is unset in the environment a run sees. `/tmp` held 29 directories named
`epito-<seat>-<random>`, the run clones of seats of two companies at
once — this product's pm, engineer and exo beside alexandra-systems' pm,
engineer, mba and exo-centralizer — every one of them owned by the same
uid 997 `seats` and mode 0700. 0700 is the protection against another
user on the box; between two runs of the same user it is no protection
at all, because they are the same user.

**Impact.** A pull request description in another company's repository
carried a third party's report, published, until its author read the
headings. That surface is the one this org's own register calls the one
the owner reads most of (L14). The corruption crossed a company
boundary: the design is ours, the state it corrupted was a partner's.
The same class had already been found seven hours earlier on the read
side, inside our own test suite, where `smoke-temporal` asserted "no
clone left behind for pm" by globbing the system temporary directory and
failed on three live clones of the resident pm seat —
`cli/test/smoke-temporal.sh:156` says so in the file, including the
general form: "an assertion that reads someone else's state is wrong
whether or not it writes."

**Root cause in the system, two scopes.**

*Tooling.* The isolation this runtime has is real and is set at the
wrong boundary. Each systemd unit gets its own `/tmp`
(`deploy/provision-host.sh:364`, `PrivateTmp=yes`, commented "give the
unit its own so cleanup is local"), and each run's clone is made with
`mkdtempSync` under a per-seat prefix (`cli/src/lib/runner.js:332` and
`:352`). So the runtime isolates the directory the runtime creates, at
the boundary of the unit and the user — and the unit of collision is the
run. A path the run itself picks is shared by every run in the unit,
because the allowlist that builds a run's environment
(`cli/src/lib/runenv.js:26`) hands over `PATH`, `HOME` and `USER` plus
the names the manifest asks for, and `TMPDIR` is not one of them;
nothing else in `cli/` sets it. Worth keeping separate when the fix is
built: `HOME` is shared across runs deliberately, because the executor's
held sessions live under it (`deploy/provision-host.sh:131`), so the fix
belongs to the scratch path and not to `HOME`.

*Routing, which is why the first instance did not prevent the second.*
The read-side instance was fixed at suite scope in commit `600d080` at
01:45:48Z, with `export TMPDIR="$ROOT/tmp"` — the same one line, one
scope narrower than the runner needs it. The same commit wrote the
general case into `docs/ideas.md` at status `proposed`, ending "nothing
stops the next suite from doing it again." That ledger's own header says
status moves only on the owner's word. Seven hours later the write-side
instance published another company's report. A known defect class with a
known one-line fix was waiting on consent, in a ledger, while it fired.

**Fix shipped, and by whom.** The product fix — a private scratch
directory per window, named in the environment the run sees — is the
engineer seat's, handed over by our project manager on the board at
08:57Z with the partner's request and measurement attached. It is not
this seat's to build and this entry does not claim it. What this run
ships is the entry, lesson L15, and the charter patch L15 needs to bind,
`docs/agents/patches/2026-10-18-engineer-a-defect-is-not-an-idea.diff`.

**What the code fix will not reach.** This host does not run `main`.
Read in this run: `/usr/lib/node_modules/epito/package.json` is dated
2026-09-24, its `src/lib/runner.js` is 200 lines against 719 on `main`,
and line 131 still clones at depth 1 — the defect that merged fixed at
08:42:47Z today. Both copies declare version 0.1.0, so no surface tells
them apart. By the partner seat's own account, upgrading the package and
reloading the daemon is a chair's act and not a seat's, which means no
seat's hand can carry any of this to the machine where the corruption
happened. Routed as a handoff to `alexandra-systems/pm` under the
not-landing clause of this seat's charter, with the measurement and the
one decision the owner would be asked.

**Fix location, re-measured 2026-10-18 at 12:45Z (L20).** Not on `main`.
The code fix is pull request 181, opened 10:36Z: 337 insertions across 10
files, nine of which auto-merge against `main` at `f2a1757`, stopping on
three added rows in `docs/ideas.md` and on no other path. The delivery of
it to the host is HQ board item `f38156f4`. The defect fired a second
time at 12:25:59Z while both were open — incident 9.

**Lesson produced.** L15 in `docs/agents/lessons.md`.

**Re-measurement, as a command (L58).** Open while `EPITO_SCRATCH` is absent
from the file the daemon actually executes.

```remeasure 5
probe   test -r /srv/asc/repos/epitome/cli/src/lib/runner.js && ! grep -q EPITO_SCRATCH /srv/asc/repos/epitome/cli/src/lib/runner.js
control grep -qE "module.exports|export " /srv/asc/repos/epitome/cli/src/lib/runner.js
```

## Incident 6 — 2026-10-12 to 2026-10-16 — The building seat did not start for three and a half days, and nobody read why

**What happened.** Between 2026-10-12T20:25Z and 2026-10-16T01:41Z, nine
scheduled runs of this company failed: eight of the engineer seat and
one of the project manager. Every one of them failed in three to five
seconds with zero steps executed. The runs are 38304103670,
38305248719, 38343913575, 38447241753, 38499668570, 38593912693,
38667959433, 38762870877 and 38836464924, and the cause is the same
sentence on each, read this run from the job's check-run annotation,
verbatim:

> The job was not started because recent account payments have failed or
> your spending limit needs to be increased. Please check the 'Billing &
> plans' section in your settings

Two engineer runs on 2026-10-16T15:32Z and 2026-10-17T01:34Z completed
normally, so the block cleared on its own before anyone recorded that it
had been there. The failure on 2026-10-17T14:25Z is unrelated: that run
worked for twenty-seven minutes and exhausted its hundred-and-fifty-turn
cap, and the project manager triaged it correctly two passes later.

**Impact.** The company's only building seat was stopped for three and a
half days, across eight of its scheduled runs, during the window in
which a cycle was waiting to open. Nothing on the board, in the queue or
in any pull request said so. The project manager's pass note of
2026-10-18 reports "none in the last six hours" and names the turn-cap
run as "the one real failure in the last 24h", which was true of the
twenty-four hours it looked at.

**Root cause in the system, two parts, neither of them a seat.**

*The read step is blind to this class.* The company standard's triage
procedure says to read each failure with `gh run view <id> --log-failed`
and the model trace. A job that never started wrote no log: that command
returns `log not found` for all nine, while successful runs of the same
two days return eighty kilobytes each, so this is not log retention. The
only place the explanation exists is
`GET /repos/{owner}/{repo}/check-runs/{job}/annotations`, which no
charter and no standard names. A procedure that reads conclusions and
logs can see that a run failed and can never see that the account was
blocked.

*The watch is slower than what it watches.* The same procedure runs
"every standup" with a twenty-four-hour look-back, against a seat that
runs twice a day. Its escalation rule — "two failures in a row on one
seat is an incident, not a third try" — was satisfied four times over,
and the count was never computed, because the triage that computes it
ran three times in thirteen days and one of those runs was itself
blocked by the same billing failure. A look-back shorter than the
watcher's own interval cannot see its own escalation condition. That is
lesson L16's third instance.

**Fix shipped, and what is not this seat's.** This run ships the entry,
lesson L16 and the triage patch beside it
(`docs/agents/patches/2026-10-18-pm-a-pass-is-not-a-pull-request.diff`
carries the output unit; the look-back and the annotation read belong to
the company standard's section 11.7, which is HQ's file and not this
repository's, and went up as a note to the centralizer rather than as a
patch here).

The billing state itself is the owner's and nothing else's: company
standard section 22 says spending never proceeds on her silence. It is
in the handoff to `alexandra-systems/pm` as the single decision to put
in front of her, with the measurement, because the same block will stop
every seat the bus wakes through GitHub and will again leave no log when
it does.

**Lesson produced.** L16 in `docs/agents/lessons.md`.

## Incident 7 — 2026-10-17 to 2026-10-18 — A standing duty the owner assigned lived for thirteen hours in one message row and nowhere else

**What happened.** At 2026-10-17T20:06:00Z a chair carrying the owner's
redesign of the learning loop addressed a handoff to this seat on the
board, and to the exo seat of alexandria and of Ursa in the same second.
Its last line names what it is: "The vendored standard carries section
twenty-four when the centralizer re-vendors it; until then this handoff
is your charter's delta." The run it woke opened pull request 142 as a
draft ninety-four seconds later, with a body that says "Draft opened at
the start of the run so the work ships even if the run dies", committed
one commit that changed no file, and ended. The project manager closed
the empty draft at 2026-10-18T09:17:12Z, thirteen hours and nine minutes
later, and said so on the board rather than filing it as anything.

**Impact.** An owner directive that makes this seat half of the
company's learning loop was, for those thirteen hours, in no charter, no
register, no board item and no file of this repository: `grep -ri
"learning loop"` over `main` returns nothing. This seat ran again in
that window — the weekly drift review published at 09:19:51Z — and that
review does not mention the loop, because the run that wrote it read the
inbox the way the standard documents it and the handoff was off the end
of the page (L17). Of 56 pull requests this repository has closed
unmerged, 142 is the only one with zero changed files, so the residue
was visible and cheap to clear; the duty behind it was not visible at
all.

The duty itself is not late. `asc-brief.timer` on the host is enabled
and active, it last fired at 2026-10-17T12:00:58Z — eight hours before
the redesign — and fires next at 2026-10-18T12:01:04Z, which is the
loop's first tick for this seat. The board's API emits `brief.sent` when
the brief goes out and targets HQ's centralizer and the exo seat of
alexandria, Ursa and epitome; delivery is the window door
(`POST /message/epitome-exo`) and, failing that, a repository dispatch
of type `asc.exo`, which `.github/workflows/agent-exo.yml` accepts. The
clock and both doors exist. What did not exist was any record of what to
do when it strikes.

**Root cause in the system, three parts, none of them a seat.**

*A run's only durable surface is its pull request.* The dispatch every
seat on this host reads is built in `cli/src/lib/runner.js:149` and says
to open the pull request draft-first, before anything else that takes
time. That is the right instruction and it is incomplete: it makes the
first artifact of every run a container, and a run that ends before it
commits leaves the container and loses the content. Nothing in the
dispatch, and nothing in this seat's charter, says that the duty a run
accepted should be written down before it is worked.

*The inbox read loses what is addressed to you.* Full measurement in
L17: the read the company standard prints returns the newest hundred
messages of the whole portfolio, just under eight hours at this volume,
of which one point seven percent were this seat's; `everyone=0` cuts the
same window to twelve, eight of which belong to another company's exo
seat because the store matches `to_seat` without its company.

*The standard this repository holds is two owner directives behind.*
HQ's `standards/pm.md` carries section 23 (2026-10-17) and section 24
(2026-10-18), the loop's own text; the copy vendored here stops at
section 22. So the one place a fresh run would have found the duty
described was absent, which is what the handoff's last line anticipated.

**Fix shipped.** This run writes the delta into this repository where a
fresh-context run will read it: lesson L17, this entry, and the charter
patch `docs/agents/patches/2026-10-18-exo-the-loops-local-half.diff`,
which adds the tick to this seat's own charter with the clock, the two
doors and the output named. The patch is the owner's to apply; it went
to the project manager as an ask under the silence rule (standard
section 22) in the same run, with the two patches already waiting.

**What is not this seat's.** The store's query and the command printed
in section 15, and the re-vendor that would bring sections 23 and 24
here, are HQ's files. Both went up as a handoff to
`alexandra-systems/exo-centralizer`, which owns the standards and leads
this loop, with the two-line fix and this measurement attached.

**Lesson produced.** L17 in `docs/agents/lessons.md`.

## Incident 8 — 2026-10-18 — A quarter of the day's runs were refused by a limit the runtime cannot see, and the events were thrown away

**What happened.** Twice today every seat on the resident host — thirty-eight
manifests across four companies — was refused by the model provider's session
limit, and each refusal was recorded as a run that failed. The provider's own
words, from the result line of a refused run
(`/srv/asc/state/.epito/logs/pm/2026-10-18T09-55-31-705Z-message.log`),
verbatim:

> You've hit your session limit · resets 11:20am (UTC)

Measured this run over all 253 run logs the host wrote today:

| | |
|---|---|
| runs attempted | 253 |
| refused by the session limit | **65 (25.7%)** |
| of those, refused at turn 1 — no work done, no commit, no pull request | 37 |
| refused mid-run, between 5 and 129 turns in | 28 |
| of all 65, how many had opened a pull request | **0** |
| seats affected | 19 of 38, in every one of the four companies |

Two windows, not one. The first refusal came at 01:57:06Z and the last of that
window at 02:42:07Z, 36 runs across 19 seats, against a limit that reset at
05:00Z. The second began at 09:29:39Z and ended at 09:56:51Z, 29 runs across 11
seats, against the limit that reset at 11:20Z. Nothing ran between 02:42:07Z and
06:20:00Z, and nothing ran between 09:56:51Z and 12:01:08Z, which is this seat's
own brief tick: 342 dark minutes in the day's first twelve hours.

**Impact, in two parts that have different causes.**

*The work was lost, not delayed.* `cli/src/lib/bus.js` acknowledges an event the
moment the seat's run has started, and says so in the file at line 9: "acknowledge
an event only once the seat's run has STARTED." A session-limit refusal arrives
inside a run that started, so `bus.ack(msg)` fires on line 223 and the event is
gone from the stream. The branch below it is the one that would have saved them —
`bus.nak(msg, cfg.nakDelayMs)`, reached only when the start itself throws, with
the log line "the event is NOT acknowledged and comes back." Sixty-five messages
the bus delivered were therefore consumed by runs that did nothing, and no
mechanism anywhere re-delivers them. Thirty-seven of the sixty-five did not get
past turn one.

*Then the company did not restart itself.* The first limit reset at 05:00Z and
the first run after it was at 06:20:00Z; the second reset at 11:20Z and the first
run after it was at 12:01:08Z. So 121 of the 342 dark minutes were not the
limit's doing at all: capacity had returned and nothing fired, because since
2026-10-17 the bus is this company's only clock and thirty-three of the
thirty-eight manifests carry no `cron` (L16, drift review of 2026-10-18 §1). A
capacity outage therefore ends when something external happens to knock, not when
the capacity comes back.

**Root cause in the system, three parts, none of them a seat.**

*The runtime has no notion of its own capacity.* `grep -rn "session limit\|429"`
over `cli/src` returns nothing. The one-attempt policy on the execute activity is
deliberate and correct for what it was written against —
`cli/src/temporal/workflows.js:49`, with the reason in the comment above it: "an
execution that half-ran has already pushed commits and may have opened a PR, so
replaying it is worse than failing." That reasoning holds for a run that did
work. It does not describe a run the provider refused at turn one, and the
runtime has no way to tell the two apart, so it applies the stricter rule to
both. Today that cost 37 refusals that were safe to re-deliver by the policy's
own test, and none of the 65 had opened a pull request.

*No instrument reports capacity.* The board's run record carries `exit`, and an
exit of 1 is the same value for a seat whose work failed and a seat that was
never allowed to begin. The daily brief that went out at 12:01Z — the artifact
the owner reads daily, and the thing that woke this run — counted eight shipped
items, four products and four decisions, and contains no run count, no failure
count and no mention of either outage. The one daily instrument whose subject is
the shape of the host, `epitod-health.timer`, has been in `failed` since 07:00Z
(drift review §6). The number that would have shown this — turns spent per seat
per day — exists today only in the footer of each run's log file, and totalling
it by hand is how this entry was written.

*The escalation route presumes the actor can run.* Company standard §20 sends
every not-landing finding to `alexandra-systems/pm`, and §18 gives that seat two
passes before the handoff counts as its own failure. This seat handed that seat
two findings this morning, at 09:07Z and in the drift review. Of HQ's project
manager's nine runs after 09:07Z, one completed; the other eight were refused by
this limit, seven of them at turn one. The standard's clock counts passes and
nothing in it notices that the passes were not available.

**Fix shipped here, and what is not this seat's.** This entry, lesson L18, the
first tick of the learning loop in `docs/agents/loop.md` with the capacity line
in it, and the charter patch that makes the line a standing duty of this seat
(`docs/agents/patches/2026-10-18-exo-the-capacity-line.diff`). The runtime change
— classify a provider refusal as a start failure, nak it, and take the nak delay
from the reset time the refusal already carries — is the engineer seat's, and
went to `epitome/pm` on the board with this measurement rather than being
designed here. The brief's missing numbers and the §18 pass clock are HQ's files
and went to `alexandra-systems/exo-centralizer`. The limit itself is a plan the
owner holds, and the single decision only she can make is named in the handoff to
`alexandra-systems/pm` under this seat's not-landing clause; company standard §22
says spending never proceeds on her silence.

**Relationship to incident 6, which is why this is a lesson and not a repair.**
Incident 6 was written into this register at 09:17Z today: nine runs blocked by a
GitHub billing state, three and a half days of a building seat lost, no log and
no instrument, discovered by a review thirteen days late. Twelve minutes later
the same shape fired through a different mechanism and took four companies down.
Two instances of one axis is the condition L4 names, so what ships here is the
generalization, not another repair of one mechanism.

**Fix location, re-measured 2026-10-18 at 12:45Z (L20).** Not on `main`.
This entry, L18 and the loop's first tick are on pull request 192, clean
against `main` and unmerged; the runtime half is the engineer seat's pull
request 190, opened 12:30:29Z, 231 lines in one new file, clean against
`main`, still a draft. The instrument is HQ board item `c0015ed7`, In
progress. The session-limit decision is in the owner ask headquarters'
project manager filed, and spending does not proceed on her silence.

**Lesson produced.** L18 in `docs/agents/lessons.md`.

## Incident 9 — 2026-10-18 — The same shared path overwrote a board reply's references, while the fix for it waited on three lines of a Markdown table

**What happened.** At 12:25:59Z the project manager seat of
alexandra-systems answered three handoffs from this seat in one message
on the board. Its `data.in_reply_to` carried two entries:
`0acec696-3218-49c8-a722-430fe0a07c4d`, which is this seat's capacity
handoff of 12:14:11Z, and `0414aaaa-0000-0000-0000-000000000000`, which
is not an identifier of anything. The third handoff was not referenced at
all. Sixty-seven seconds later, at 12:27:06Z, that seat corrected itself
on the board rather than letting it stand, and named the cause in its own
words, verbatim and in full:

> My last reply to you carried one placeholder message id instead of a
> real one, because the file I read it from got overwritten by something
> else writing into the same shared path while I worked.
>
> That is the same class of fault your own host-runtime handoff just
> described, so I am naming it rather than quietly fixing it.
>
> The three messages I was answering are your runtime handoff, your
> roster handoff, and your capacity handoff, and nothing about which
> items or asks I filed changes.

The correction's `data` names three identifiers, and all three resolve in
the store, checked this run: `ab791e37` is this seat's runtime handoff of
09:07:08Z, `4f475ae4` its roster handoff of 09:33:53Z, `0acec696` its
capacity handoff of 12:14:11Z. So the prose repair is complete and
correct.

**Impact.** Nothing in any repository was corrupted this time, and no
decision changed: the correction confirms the items filed and the asks
sent are unaffected, and this run verified each of them independently
(board items `f38156f4` commented, `d8052eb7` and `c0015ed7` both In
progress). What is corrupted is the board, which company standard §15
calls "the only record". That section also splits the record in two — "a
person reads the body and understands what is happening and why; a
machine reads the data and knows where" — and the store appends
corrections rather than rewriting messages, so the machine-readable half
of the link from that reply to the work it answers is permanently one
real identifier, one that resolves to nothing, and one omission. Only the
prose carries the repair, and only for a reader who finds the second
message.

**Root cause in the system.** The same one incident 5 names, unchanged.
Measured from inside this seat's own window while writing this entry,
four hours after incident 5 was published: `TMPDIR` unset,
`EPITO_SCRATCH` unset, and `/tmp` holding 85 `epito-*` entries, 69 of
them at mode 0700 and every one of them owned by uid `seats`. 0700 is the
boundary against another user on the box; between two runs of the same
user it is no boundary at all. This run had no private scratch path to
write to either.

**Why the first instance did not prevent the second, measured.** The fix
is written, it is good, and it is not on `main`. Pull request 181 adds a
scratch directory per window — `scratchDirFor()` returns the clone's
sibling at `<clone>.scratch`, mode 0700, named to the run as `TMPDIR` and
`EPITO_SCRATCH` — across 337 insertions in 10 files. Trial-merged against
`main` at `f2a1757` this run, nine of those ten files auto-merge; the
tenth is `docs/ideas.md`, and it is the only conflicted path the merge
reports. Three added rows of a ledger table hold 334 lines of a fix for a
defect that fired twice in one morning.

The host has already seen that fix work. `/tmp` holds twelve
`epito-<seat>-<id>.scratch` directories at mode 0700, created between
09:29:01Z and 09:37:06Z and none since — the branch's own naming, run
from a clone. No window gets it, because the resident runtime is not that
code: `/usr/lib/node_modules/epito/package.json` is dated 2026-09-24, its
`src/lib/runner.js` is 200 lines against 725 on `main`, it has no
`runenv.js` at all, and `grep -rl "scratch\|TMPDIR\|EPITO_SCRATCH"` over
its `src/` returns nothing. So the machine has watched the repair succeed
in a test window and has no path by which a run receives it. That gap is
HQ board item `f38156f4`, filed before this seat's handoff landed, with an
engineer pull request open against it.

**Fix shipped.** Nothing of the code is this seat's and this entry claims
none of it. What ships here is this entry, lesson L20, the one-line
format change at the head of this register that L20 requires, and the
charter patch beside it
(`docs/agents/patches/2026-10-18-exo-a-fix-is-shipped-when-it-is-on-main.diff`).

**Fix location, by the rule this entry introduces.** Not on `main`. The
code fix is pull request 181, blocked on three rows in `docs/ideas.md` and
on nothing else; the delivery of it to this host is HQ item `f38156f4`.
Both were already routed under this seat's not-landing clause — the queue
measurement and the merge order went to `alexandra-systems/pm` at
12:34:58Z, and the runtime gap at 09:07:08Z — so this run adds the
recurrence to that handoff rather than opening a second one. Next run
re-measures both and counts instance three if there is one.

**No fault.** The seat that published the wrong identifier found it,
named it as the known class rather than quietly editing around it, and
repaired it in sixty-seven seconds. That is the behaviour this register
exists to make safe.

**Lesson produced.** L20 in `docs/agents/lessons.md`. First instance of
the axis: incident 5.

## Incident 10 — 2026-10-18 — The runtime this company fixes is not the runtime it runs

**What happened, in the order it was found.** At 13:03:48Z this product's
engineer seat posted a `done` to this seat on the board, saying the defect
measured in incident 8 was built: the acknowledgement boundary moved, a refusal
before a first turn gives the event back at the reset time the provider named,
and a refused run is recorded as refused rather than failed. The reference is
pull request 190, opened at 12:30:29Z and still a draft. The code is 828 added
lines across sixteen files, with a live section in the bus suite against a real
`nats-server` and eighteen new unit assertions; read on its own terms it does
what the handoff asked for, including the part incident 8 did not think of — a
bad key and an expired token deliberately left out of the refusal class, because
an operator has to fix those and a column whose meaning is "later" would be
lying about them.

Then two checks on the host, which is where the 65 refusals of that morning were
counted.

*The reader does not match the host's sentence.* Every one of today's
before-a-turn refusals ends its log the same way: `"api_error_status":429`, the
result line `You've hit your session limit · resets 11:20am (UTC)` (nineteen of
them; eighteen more with `resets 5am (UTC)`), `"num_turns":1`, and — disarmingly
— `"subtype":"success"`. `cli/src/lib/refusal.js` matches on "usage limit
reached", "session limit exceeded", `limit reached · resets`, a `retry-after`
header, a `rate_limit_error` type, or the literal `429 Too Many Requests`.
Today's string is none of those: the word after `limit` is `·`, not `reached`,
and the 429 is a JSON field rather than a status line. Running the module from
the branch against both of today's sentences returns `NO MATCH` for each. Its
clock reader, asked directly, turns `11:20am (UTC)` into `2026-10-18T11:20:00Z`
and `5am (UTC)` into `2026-10-19T05:00:00Z`, both correct — so the gap between
built and working is one pattern line, and the `nothing-happened` guard in front
of it (no pull request, no second turn) is already right.

*The host does not run the file.* `/usr/bin/epito` resolves to
`cli/src/index.js` inside `/srv/asc/repos/epitome`, and that checkout is at
`5836dc0`, the runtime's first merge, dated 2026-09-23 — 364 commits behind
`main` at `f2a1757`. Its `cli/src/lib/` holds six files: audit, cron, hooks,
manifest, runner, slack. No `bus.js`, no `temporal/`, no `router.js`, no
`refusal.js`; `epitod.service` has been up since 2026-10-17 21:13:37Z and there
is no worker process. Two files in that tree are modified in place, with `.bak`
copies beside them in `/srv/asc/state`, and the modifications are four
hand-patches signed in their own comments by the HQ chair: 2026-09-30, tracing
attributes per seat and company; 2026-10-05, a run report posted to the board's
`/api/runs` so host runs appear beside Actions runs; 2026-10-17, a write to a
closed log descriptor that "took the whole daemon down, with every other seat's
window in it"; 2026-10-17, pipe-error and uncaught-exception handlers for the
same reason.

**Impact.** Three things, and the third is the one that outlives today.

*The fix for incident 8 would not have fired.* Merged exactly as written, with
the host as it stands, all 37 of today's before-a-turn refusals would still be
read as plain failures and their events still thrown away, for both reasons at
once: the pattern misses the sentence, and the file is not on the box.

*The class still cannot reach the owner's board.* The surface she reads gets its
host runs from the 2026-10-05 hand-patch, which posts `exit: exitCode` as a
number (124 for a timeout, otherwise the child's code), and `board.runs.exit` in
HQ's schema is an `int`. The word "refused" has nowhere to go in that table. The
refused column pull request 190 adds is in `cli/src/lib/board.js`, which renders
the local `.epito/board.jsonl` on a host that does not execute it.

*Every "fix shipped" line in these registers has been a claim about a
repository.* This register has written five of them this month. The ones whose
fix is a document — a lesson, a charter patch, a standard — were true when they
merged. The ones whose fix is runtime code were not: they described a file in a
branch while the box ran a September copy with four hand-patches. The register
did not distinguish the two, because this seat never looked at the box.

**Root cause in the system, three parts, none of them a seat.**

*Nothing names the installed artifact.* No charter, standard or register entry
in this company asks what revision the host is running, and no instrument
reports it: `epito doctor` reads manifests and routes, the daily brief counts
merges, the board counts runs. The one number that would have surfaced this —
the distance between `/usr/bin/epito` and `main` — is one command long and
nobody's duty.

*A fixture was quoted rather than copied.* Incident 8 named the place the
refusal text lives (`api_error_status` in the run log) and then quoted the two
phrasings it had seen elsewhere instead of pasting the one sitting in the 37
logs it counted. The build was faithful to the lesson, which is the failure: a
lesson that carries an example instead of the recorded line hands its reader a
plausible fixture and no way to know it is wrong.

*Deploying is nobody's clause.* Four production faults were fixed on the box by
hand by a chair, each with a dated comment, none of them in a repository and
none of them in a register until this entry. The seat that builds has no deploy
step in its charter, the seat that merges has no deploy step either, and the
runtime belongs to HQ, so the gap sits exactly where no charter looks — which is
the same shape as L16's missing clocks and incident 7's duty that lived in one
message row.

**Fix shipped here, and what is explicitly not.** This entry; lesson L22; the
daily capacity command in `docs/agents/loop.md` corrected to test the class
instead of grepping the word, with today's row reread as 37 before a turn and 28
mid-run rather than 65 of one kind; and the charter patch binding the building
seat to the installed artifact and to one real log line as its fixture
(`docs/agents/patches/2026-10-18-engineer-the-installed-runtime.diff`).

Not this seat's, and routed rather than designed: the pattern line itself and
the question of which runtime is the real one went to `epitome/engineer` as a
reply on the board with the exact string, and to `alexandra-systems/pm` as the
not-landing finding this seat's charter requires, with the measurement, the
order and the one decision only the owner can take — whether the resident host
is to run the repository's runtime at all, since a September copy with four
hand-patches is a working answer and the four hundred commits are the other one.
The `int` on `board.runs.exit` and the §15 `done` that asks for a pull request
and never asks which box is running it are HQ's files and went to the
centralizer.

**Lesson produced.** L22 in `docs/agents/lessons.md`. First instance of the same
axis: incident 8, whose own fix is the evidence here.

## Incident 11 — 2026-10-18 — Three passes of the merging seat declined to merge, correctly, because the file that instructs it has never said it merges

**What happened.** The engineer opened #181 at 09:25:15Z, the fix for the
shared-scratch corruption that overwrote a partner seat's pull request body on
this host (incidents 5 and 9). At 13:13:14Z it merged `main` into the branch,
resolved the one conflicted hunk and cleared the draft flag, and the pull
request has read `MERGEABLE / CLEAN`, not a draft, ever since. It is the fix for
a defect that is still producing: `/tmp` on this host held 85 `epito-*` entries
at 12:45Z, 87 at 13:03Z and **107 at 13:38Z**.

Three passes of this company's project manager ran after it was ready — #198 at
13:09:09Z, #200 at 13:17:20Z, #202 at 13:21:45Z — and each declined to merge
anything, read no inbox and posted nothing to the board. Each said why, in its
own pull request body, and each said the same thing. From #202, verbatim: the
event's asks are "not in `prompts/pm-agent.md`, which this run was told is its
full charter: it names pitches, cycles, the betting memo, the retro, and a
Linear mirror — no merge authority, no board/inbox protocol, no run-report
duty."

**Impact.** 34 open pull requests in this repository. Performing the merges
rather than reading the field, 15 of them land in one sequence with no conflict
at all. None of the 15 has a merger. The oldest is 48 days old; #192 has been
clean and ready for 67 minutes; the fix for a live corruption has been ready for
25 minutes and open for four hours.

**Root cause, in the system.** The three passes read their charter correctly.
`prompts/pm-agent.md` is 89 lines, last changed on 2026-09-20 — 28 days, by this
company's own clock the oldest unexamined instruction it has. The word `inbox`
does not occur in it. Its section headed "the board" is a Linear mirror through
`LINEAR_API_KEY`, a surface this repository's own `cli/src/lib/board.js` records
as having "never once had a working API key" — so the one board the charter
names is the one the company stopped using, and the board it actually runs on is
absent.

Everything the three passes were asked to do is in the company standard rather
than in the charter: the inbox read before anything else and the `done` on ship
(`docs/standards/pm.md` §15), the dispatch criteria and the merge rule (§11.3,
§11.4), the two-pass clock on a handoff (§18, §20). §16 of that same standard,
written 2026-09-30, says how the two are meant to meet: "A product's
`prompts/<role>-agent.md` is therefore short: it names the role charter it
follows and states the company's standing assignment." Measured across this
repository's seven charters, **one names its role standard** — `frontend`,
written 2026-10-17, the only one written after §16 existed. The other six,
including this seat's own, predate it and point at nothing.

So this is not a regression and nothing broke today. It is a 28-day-old gap that
only became visible when some passes of the same seat read the standard and
later ones read only the charter: the same seat merged this seat's three-pull-
request stack at 12:32Z and declined at 13:09Z, and both readings were faithful
to what each was given. The unit of failure is the charter.

**Fix shipped here, and what is not.** This entry; a charter patch for the
owner's hand
(`docs/agents/patches/2026-10-18-pm-the-standard-is-the-charter.diff`), which
adds the pointer §16 asks for and names the three duties the standard already
binds this seat to — eight lines, no new rule invented here. Not shipped and
routed instead: the merge itself, and the five other charters with no pointer.
Both went to `alexandra-systems/pm` as the not-landing finding this seat's
charter requires, with the full merge order and the one owner decision, because
`standards/roles/` is the centralizer's by §16 and a merge is a merger's.

**Re-measured 13:56Z, thirteen minutes later: three has become seven.** #203 at
13:27Z, #205 at 13:31Z, #206 at 13:40Z and #207 at 13:49Z all declined for the
same reason, and each cites the ones before it — #207, verbatim: "same
conclusion six times running today, for six different messages, which is itself
the finding below." Seven passes between 13:09Z and 13:49Z, one every six
minutes, each a run that read its charter correctly and could not act.

**And each decline opens a pull request.** Of the 33 open pull requests on this
repository at 13:56Z, **25 are passes of this one seat**, and 17 of the 18 that
cannot merge are passes conflicting with each other in `docs/backlog.md` and
nothing else. So the missing sentence does not merely stop work; it converts
each attempt into another row of the queue that the missing sentence is also
the reason nobody clears. That is the loop, and it closes only from the charter
end. The rate will hold until the patch above is in the file, because nothing
else in the loop changes. (One thing did move: #207 closed six stale drafts of
its own, which is the first reduction in this queue's size today.)

**Lesson produced.** None. This is L16 a third time — a duty that lives in a
sentence claiming it rather than in the thing that fires it — and the frameworks
register's law says a fourth entry on one axis is the register failing, not the
org learning. First instances: incident 7 and L16.

## Incident 12 — 2026-10-16 to 2026-10-18 — Ten runs recorded as opening nothing had each opened a pull request, and the fix for it merged six hours before eight of them

**Facts.** A run on this host ends with one line in its log and one row in the
daemon's state: `# exit=<n> pr=<url|-> session=<id> turns=<n>`. Over 2026-10-17
and 2026-10-18, ten runs across four seats and three companies ended with
`exit=1 pr=-`. Asked of GitHub instead — which pull requests did this repository
open on a branch with this seat's prefix, between this run's start and its end —
the answer is ten runs, ten pull requests, one each, every one inside the run's
own window:

| seat | started | ran | turns | recorded | actually opened |
|---|---|---|---|---|---|
| `ursa-engineer` | 10-18 00:27:28Z | 34 min | 121 | `pr=-` | Ursa #226 |
| `ursa-engineer` | 10-18 02:04:39Z | 29 min | 121 | `pr=-` | Ursa #232 |
| `engineer` (HQ) | 10-18 08:50:52Z | 58 min | 201 | `pr=-` | alexandra-systems #281 |
| `exo-centralizer` | 10-18 09:07:22Z | 41 min | 151 | `pr=-` | alexandra-systems #284 |
| `pm` (HQ) | 10-18 12:28:06Z | 41 min | 141 | `pr=-` | alexandra-systems #295 |
| `engineer` (HQ) | 10-18 12:30:19Z | 36 min | 201 | `pr=-` | alexandra-systems #294 |
| `exo-centralizer` | 10-18 12:37:41Z | 33 min | 151 | `pr=-` | alexandra-systems #296 |
| `ursa-skill` | 10-18 14:03:56Z | 14 min | 101 | `pr=-` | Ursa #256 |
| **`epitome-exo`** | **10-18 14:07:05Z** | **20 min** | **121** | **`pr=-`** | **epitome #211** |
| `ursa-skill` | 10-18 14:18:10Z | 12 min | 101 | `pr=-` | Ursa #258 |

Five hours and eighteen minutes of run time, ten pull requests, recorded as ten
runs that produced nothing. The command that produced the right-hand column is
the one the runtime's own `main` already runs; it is at the bottom of this entry
and anybody can re-run it (L22).

**Impact.** Three kinds, and the third is the expensive one.

*The record is wrong where the company reads it.* `exit=1 pr=-` is what the
daily brief, the board's runs panel, the scorecard and every failed-run tripwire
see. A capped run is indistinguishable in that record from a run that crashed at
turn one.

*The work is left in an unreadable state by its own author.* A run that ends at
its cap ends between two statements. This seat's own 14:07Z run is the clean
case: it opened #211 at 14:09:35Z with the placeholder body every seat is told
to open with, pushed six commits — the whole fold of #192, #195, #197, #204 and
#208, measured in this run as adding nothing to it — and was killed at turn 121
of 120 before it could write the body or clear the draft flag. Cost $9.95. What
it left is a draft pull request saying "Body rewritten before this leaves draft"
and a run record saying no pull request exists. Nobody but the next run of the
same seat could tell the difference between that and an empty placeholder.

*Four more passes were spent re-deriving it.* Two project managers triaged two
of these ten by hand on 2026-10-18 within 48 minutes of each other, at two
companies, each reaching the correct conclusion for its own row and naming no
mechanism; a third had done the same on 2026-10-16 and again at 01:15Z on
10-18. The full count and the rule are L26.

**Root cause, in the system and not in a seat.** Three facts compose it, and
each is correct on its own.

1. The runner spawns the executor with `--output-format json`, so the child
   prints nothing at all until it ends, and then prints one object.
2. That object carries the run's pull request only inside its `result` string —
   `"result":"Run complete. PR #208 (https://github.com/…/pull/208) is open…"`.
   A run that ends `"subtype":"error_max_turns"` has no `result` key: it has
   `errors`. Verified by `grep -c '"result":"'` over the logs — `1` for a clean
   run of this seat at 13:47Z, `0` for its capped run at 14:07Z and `0` for HQ's
   engineer at 12:30Z.
3. The build installed on this host reads the pull request from exactly one
   place: `const prs = tail.match(PR_URL_RE)` over the last 64 KB of what the
   child printed (`/srv/asc/repos/epitome/cli/src/lib/runner.js:178`).

So the address is not truncated away. **It is never printed**, and the field
that would have held it is read from the printing. No seat did anything wrong in
any of the ten runs.

**The fix is already merged, and that is the finding.** `main` replaced that
read on 2026-10-18 in commit `ba763c7`, titled *"A run's pull request is asked
of GitHub, not read out of a 64 KB tail"*, merged in #169 at 08:17Z: the runner
now calls `pullRequestForRun({ repo, prefix, token, since })` and writes a
`# pull request: …` line saying which it found and on what branch. **Eight of
the ten runs above started after that merge.** `grep -c '# pull request:'` over
every run log this host wrote on 2026-10-18 answers **0**, because
`readlink -f $(which epito)` is `/srv/asc/repos/epitome/cli/src/index.js`, a
checkout at `5836dc0` of 2026-09-23 with two files hand-edited in place — **366
commits behind `main`** as of this run, one further than when incident 10
measured it. Second instance of L22's second half, and the first one with a
number on what the distance costs per day.

**One correction owed to the branch that holds the fix, which strengthens it.**
The fix has two halves: tracking every address the child prints across the whole
stream, and asking GitHub. Its own comment explains both by saying the address
"is printed early and the window keeps only the end." Against this executor that
is not what happens — the address is never printed on a capped run, so the
stream-tracking half returns nothing and the whole of the repair is carried by
the GitHub ask. The half that works is the half that asks a system outside the
run. Worth saying because the next person to simplify that function will delete
the right half.

**Fix shipped by this run.** None in code: the runner is the engineer's file and
the deployment of the box is HQ's, and both routes are already open. What
shipped here is L26 (the triage rule, routed to the centralizer because it binds
four project managers), the correction above to the engineer on the board, this
entry, and the not-landing half to `alexandra-systems/pm`, which is the only
thing that moves 366 commits.

**Re-run the measurement.**

```bash
cd /srv/asc/state/.epito/logs
grep -l '"subtype":"error_max_turns"' */2026-10-1[78]*.log   # the ten runs
grep -h '^# exit=' $(grep -l '"subtype":"error_max_turns"' */2026-10-1[78]*.log)
gh pr list -R alexandrapaiz/<repo> --state all --limit 400    --json number,headRefName,createdAt    --jq '.[] | select(.headRefName | startswith("<seat>/"))'
```

**Lessons:** L26 (new, the triage rule); L22, second instance of *the artifact
is the installed one*; L20, which is why this is an incident and not a note —
the fix is on `main` and the defect is open.

## Incident 13 — 2026-10-18 — The host filled to zero bytes mid-run, and what a run leaves behind is not the directory, it is the history this seat's own check unshallows

**Facts.** At 19:33:27Z this host's root filesystem, which is also `/tmp`, had
**57 MB free of 45 GB**. Three minutes later it had none: three tool calls in
this run failed with `ENOSPC`, one of them a `df` that could not write its own
output, and twice more in the following twenty minutes a measurement could not
be written down. Removing the stale clones of this seat's own earlier runs
today — matched by name, older than ninety minutes — returned **2.0 GB** and
the run continued.

**What it is not.** `/tmp` held **403 directories named `epito-<seat>-<suffix>`**,
the per-run clone the runtime makes for a seat before its first turn, and the
obvious reading is that 403 abandoned clones filled the disk. They did not.
Swept at 19:50Z — every one that was not the working directory of a live
process and had not been written to for two hours — **297 of them came to
2.0 MB between them**. They are empty husks. The whole of `/tmp` is 1.0 GB
after that sweep, on a 45 GB disk with 44 GB used.

**What it is.** The 2.0 GB this seat reclaimed was about ninety of its own
clones with their full history in them, and the reason they had full history is
this register's own instrument: `docs/agents/check.sh` unshallows the clone it
runs in, by design and correctly — "could not unshallow — refusing rather than
answering wrongly" — because every answer it gives in a shallow clone is wrong
(L23, measured 14:22Z). So a seat that must hold the whole history to answer
honestly is the seat whose leftovers are an order of magnitude larger than
anyone's, and nothing on the box removes them. The largest single directory in
`/tmp` at 19:33Z was 716 MB and belonged to another company's engineer, so the
mechanism is not local to this seat — only its size is.

**The part this seat cannot see, named rather than guessed.** `du` run as the
`seats` user accounts for **19.6 GB of the 44 GB** in use; the rest is in paths
this user cannot read, and no deleted-but-open file explains it (six such files
on the box, 0 MB). So the sweep that matters may well be outside `/tmp`
entirely, and finding it needs a user this seat is not.

**Impact.** A full box fails every seat on it, not the seat that filled it:
fourteen run directories were live across four companies when it filled. In
this run the cost was five lost tool calls, two measurements taken twice, and
the publication-time merge-order re-measurement this seat's own L24 requires,
which could not be run a second time and is therefore reported at 19:37Z.

**Fix shipped here, and what is not.** This entry, and two sweeps that are
measurements rather than fixes — tomorrow's runs rebuild both. Not shipped: the
sweep itself. The clone is made before any seat's first turn by the runtime
(`cli/src/run.js`), the engineer's surface, and a seat cannot tell a finished
run from a running one except by reading `/proc`, which is what this run did
rather than trusting an age. Routed with the not-landing handoff to
`alexandra-systems/pm`: it is one box under four companies, the fix belongs
where the clone is made, and part of the space is behind a permission this seat
does not hold.

**Disclosed plainly, because it touched other seats' directories.** The 19:50Z
sweep removed 297 finished runs' directories belonging to seats in four
companies. None was the working directory of a live process; the single
non-live directory younger than two hours was left alone; nothing with content
was removed beyond this seat's own. Every one of those runs had pushed whatever
it produced to GitHub before its directory went quiet.

**Not the same defect as incidents 5 and 9**, though it is the third entry on
the shared-`/tmp` axis. Those are collisions — two runs writing one path. This
is capacity, and #181, the unmerged fix for the collision class, would not have
prevented it: giving every window its own scratch directory does not make
anything remove the directory afterwards.

**Lesson produced.** None, and deliberately: the rule would be "clean up after
yourself", which is process rather than something a fresh-context seat can
apply, and the one applicable rule already exists (L20 — a fix is shipped when
it is on `main`, and no sweep is written anywhere yet).

**Re-measured 2026-10-23T17:45Z, on the run that carried this entry forward.**
#181 merged at 2026-10-23T17:19:05Z, so the collision fix named above is on
`main` now; the capacity defect this entry is about is not, and nothing on the
box removes a finished run's clone yet. `/tmp` on the box this run holds is a
fresh clone again, so the sweep is still owed and still the engineer's, where
the clone is made.

**Re-measurement, as a command (L58).** Open while the root filesystem is at or
above sixty percent, which is where the 2026-10-18 reading sat before it filled.

```remeasure 13
probe   test "$(df --output=pcent / | tr -dc 0-9)" -ge 60
control df --output=pcent / | grep -q '%'
```

## Incident 14 — 2026-10-23 — A correct not-landing finding was declined because its prose counted one set of pull requests and its data field named another

**Facts.** At 17:49:34Z this seat posted the same `handoff` to
`alexandra-systems/pm` and to this company's project manager, reporting that
the owner's silence rule released fourteen charter changes on
2026-10-20T18:34:00Z, that seven were applied to this seat's own charter in
that run, and that the remaining eight — the engineer's four and the project
manager's four — had nowhere to be a merge. The handoff's prose carried one
further measurement, offered as the portable finding: "the seat merged thirteen
pull requests seven minutes after it next woke". Its `data` field carried one
list of pull requests, under the key `merge_sequence`: `[132, 186, 187, 191,
215, 230, 235, 237, 238, 240]`, the ten that `order.sh` had found land in one
pass at 17:47Z — the ten *still to merge*.

At 18:03:05Z the project manager replied that it had run `gh pr view` on all
ten and that none was merged, and declined to apply the eight charter patches
on a measurement that did not match GitHub.

**Both measurements were true.** Re-measured at 18:08Z with
`docs/agents/landed.sh`: thirteen pull requests merged between 17:16:26Z and
17:23:23Z — `#223 #218 #211 #236 #229 #181 #228 #184 #196 #198 #209 #227 #233`
— a span of 00:06:57, one hour fifty minutes four seconds after `#234` wrote
sections 21 and 22 into `prompts/pm-agent.md` at 15:26:22Z. And none of the ten
in `merge_sequence` is merged, because a merge sequence is a list of pull
requests that have not merged. Neither number was wrong. The message named the
thirteen nowhere, so the only list of pull requests in it was the one that
could only refute it.

**Impact.** Eight charter changes this company decided three days ago are still
unapplied: four in `prompts/engineer-agent.md`, four in `prompts/pm-agent.md`,
released by the owner's silence on 2026-10-20T18:34:00Z and sitting in
`docs/agents/patches/`. One project-manager pass spent thirteen minutes
reaching a correct refusal. The queue did not move on the item the handoff was
filed for, which is the third consecutive pass in which it has not.

**Root cause in the system.** Two gaps, both tooling and neither a seat's:

*No instrument answered "what left the queue".* `docs/agents/order.sh` answers
what can merge next and prints the revision it measured at, which is why the
ten numbers were generated and correctly labelled in this register. There was
no equivalent for merge history, so the thirteen were typed from a timestamp
range in a `reasoning` field, and a typed number arrived as prose instead of as
an identifier a reader could check.

*The board message's shape does not force a claim to carry its set.* §15 says
identifiers go in `data` and evidence in `reasoning`. It does not say that a
claim counting pull requests must put *those* pull requests in `data`, so one
message held a count of thirteen and a list of ten under a key naming a
different relation, and the reader's only available join was the wrong one.

**The fix shipped.** `docs/agents/landed.sh`, on this branch: it splits closed
pull requests by `mergedAt` into merged and closed-unmerged, prints each with
its timestamp, computes the span of the merges rather than describing it, and
emits a one-line `data` block to be pasted into a board message and not
retyped. Its first version printed a confident "0 merged" from a query that had
failed, so it now checks the pipeline status and refuses instead of
summarising. The charter patch that makes this seat use it is in
`prompts/exo-agent.md` on this branch, in the paragraph L24 already put there.

**Where that fix is, written 2026-10-23 at 18:20Z.** On branch
`epitome-exo/2026-10-23-message-3`, pull request #243, which targets #240's
branch and merges after #237 and #240. Not on `main`. The one thing blocking
it is the two merges above it in that stack.

**The refutation perished the same way, and that is the register's finding not
the seat's.** The reply states a check at 18:00Z and that "every one of them is
still open". `#215` closed at 17:57:00Z and `#186` at 17:57:03Z, three minutes
before; `#191` closed at 18:03:49Z, forty-four seconds after the reply posted,
by that seat's own hand in the same seventeen-branch recovery the reply
describes. That recovery is confirmed exactly: seventeen of its branches closed
between 18:03:14Z and 18:03:57Z — `#155 #157 #158 #161 #162 #166 #167 #168
#170 #172 #173 #179 #189 #191 #219 #225 #231`. This is L24's axis a second
time, from a different seat, which by L4 is why this entry ships an instrument
and not a reminder.

**Lesson.** L33 — a number travels as a labelled identifier or it does not
travel. Companion to L24 (when to measure, and print the revision) and to
incident 11, which priced the merging seat's seventeen silent days that the
declined handoff was reporting.

## Incident 15 — 2026-10-24 — A third of the daily brief was cut from every wake that carried it, and the footer sent the reader to a surface that does not hold the rest

**Status: closed 2026-10-24T12:06Z on the re-measurement this entry named**,
with the detector half carried out to incident 18 because it is a different
defect in a different repository's tree. See the closing paragraph below.

**Facts.** At 2026-10-24T00:07:01Z the board emitted `brief.sent` and the bus
delivered it to eight addressees — the ExO seats of all four companies, by
window, with the workflow door skipped because the window took it. The
delivered text ended in a footer:

> [This wake carries 1264 of 1835 characters of the message and stops here.
> The part not delivered is its tail, which is where the sender's disposition
> lives — what they decided, what they are asking of you, what they are no
> longer asking. Read the whole message in your inbox on the board before you
> answer it.]

The 571 characters not delivered, recovered this run from `GET /api/brief`:
the **Needs you** block — four asks only the owner can clear, including
"Modal has hit its spend limit, so alexandria's pipeline and press cannot
run until you rai…" and "The npm publish needs your word on the licence
before the token dies tomorrow" — then **Capacity: 10 runs today, 0 of them
finished**, then **Money: Kimi has $40.38 left on the prepaid balance**, then
the board's address.

What survived the cut was the eight-line list of work already shipped, which
the same brief says is already open on the Deliverables tab.

**The pointer does not resolve.** The brief is not a row in `board.messages`.
It is a `brief.sent` event whose stored payload is the cut copy plus the
footer — 1576 characters against the brief's 1835 — so the event does not
hold the tail either. `GET /api/messages?to_seat=exo&to_company=epitome`
returned 130 messages this run and none of them is the brief. The surface
that holds the whole of it is `GET /api/brief`, which the footer does not
name. A seat that obeys the footer looks in the one place the tail is not.

**Impact, and the measurement that makes it a count rather than an anecdote.**
Both `brief.sent` events the events route returns carry the same 310-character
footer and the same shape: 1296 of 1946 on 2026-10-23T19:04:14Z, 1264 of 1835
on 2026-10-24T00:07:01Z. A third of the brief, twice, to eight addressees each
time. Four of those addressees are ExO seats whose charters open by observing
the brief, including this one: `prompts/exo-agent.md` makes the brief this
seat's tick, and the one number the loop ledger "may never be missing" is
capacity — which is in the part that was cut, both days.

One layer down, the brief's own fields are clipped at their widths mid-word
with no ellipsis: `• epitome: A refused run did not fail… — and \`epito doc`,
"and the token is f", "until you rai", "one of them had brok". Four of the
nine composed fields in today's brief end mid-word.

**Root cause in the system.** The cut is taken by character count from the
front of a document whose own order puts summary first and asks last, so the
cut is by position and the document's importance runs the other way. Nothing
in the mechanism knows the brief has sections, so nothing can drop one. And
the footer's recovery instruction is a sentence rather than an address, so it
was never tested by executing it; had it named a route, the route's absence
would have been visible the first time anyone followed it.

**Where the fix is: on `main`, deployed, eighty minutes after the handoff.**
Not in this tree and not this seat's to write — the brief generator and the bus
are HQ's runtime (`runtime/board/`, pm standard §15). Handed to
`alexandra-systems/exo-centralizer` at 00:24:47Z with the measurement, the
recovered tail, and the two shapes the repair needed: cut by section against a
declared precedence, and name the route by its address. Both shipped, neither
as a bigger character limit, which that seat says in writing it declined to
take because "a bigger number is still a cut nobody can see". HQ `#379`
merged at **01:24:32Z** as `413e52c`, and the chair deployed `413e52c` to the
host at **01:27:15Z**. `runtime/board/api.py` now carries
`compose_brief_sections`, a `BRIEF_DROP_ORDER` that nothing else reads — render
order stays the owner's and lives in the composer — with *Needs you* ranked
last of all to drop, a `BRIEF_MARKER` that names the dropped sections, and
`clip()` for the mid-word half, whose docstring cites this seat's measurement.

**What is verified from here and what is not.** `bash docs/agents/brief.sh` at
01:45Z against the live host: `GET /api/brief` answers **nine named
sections** — Header, Shipped, Products, Decided in your name, Needs you,
Capacity, Failures, Money, Board — where this morning it answered text only,
and **two composed lines now end in an ellipsis** where four ended mid-word.
The section-marker branch of the detector is **unverified against a live
wake**, because no `brief.sent` has fired since 00:07:01Z and the one that
did is outside the only window the events route will return (L41). Its parsing
is checked against the marker as the deployed board renders it, which is a
format test and not a positive. **The re-measurement that closes this entry is
the next `brief.sent`:** the detector must print "the cut is BY SECTION" with
names, or this is open again. Per HQ's own measurement on this morning's
brief, the old cut carried 1,370 characters and lost Needs you, Capacity,
Failures, Money and Board; the new one carries 1,444, keeps seven of nine, and
drops Shipped and Products by name — the two the brief itself says are already
open on another tab.

**The detector, which is the half of L-X1 that is in this tree.**
`bash docs/agents/brief.sh` reads the newest `brief.sent` and the live brief,
prints the footer's arithmetic against both lengths, prints the characters the
wake did not carry, and lists the composed lines that end mid-word. It is
checked against a real positive: the 572 characters quoted above are its
output on this run, not a worked example. It does not repair anything. It
makes the loss visible on the morning it happens, to the seat whose first
input it is.

**Two defects this found in this seat's own charter, written down rather than
patched, which L31 permits and requires saying.** `prompts/exo-agent.md`
asserts "the clock is `asc-brief.timer` on the host, 12:01 UTC daily"; the
only two `brief.sent` events on record fired at 19:04:14Z and 00:07:01Z, so
the charter claims a cadence instead of naming the thing that holds it, which
is L16 against this seat's own file. And the charter makes the brief this
seat's tick without ever telling it to check that the brief arrived whole,
which is the whole of this incident. **Why not patched here:** this pull
request already contains one charter, `prompts/engineer-agent.md`, carrying
four changes the owner's silence released on 2026-10-20T18:34Z and that have
waited four days for a hand; adding a second charter to it would make her
refuse both to refuse either. The engineer's four had a clock that has already
run out and these two have none, so the released decision took the slot. **Next
run's first act**, before the tick: write both into `prompts/exo-agent.md` as
its own pull request and file the ask that starts their forty-eight hours.
**Done 2026-10-24T01:40Z**, first commit of `#260`: the charter now names the
thing that fires the tick instead of asserting 12:01 UTC, and makes `bash
docs/agents/brief.sh` the tick's first act. The ask for the clock is in this
run's message to `epitome/pm`.
`docs/agents/loop.md` carries the corrected clock sentence already, so the
ledger is not asserting it in the meantime.

**The re-measurement that closes this, taken on the first wake that could
take it.** `brief.sent` fired at **2026-10-24T12:01:19Z** and `bash
docs/agents/brief.sh` ran as this tick's first act. The condition written above
was that the detector must print "the cut is BY SECTION" with names. Half of it
was met and the half that failed was the detector's, not the brief's:

- **Met.** `the cut is BY SECTION: 6 of 9 delivered`. The stored payload is
  1,126 characters, 821 of brief and 305 of marker, against 1,576 and a
  character-count footer this morning. The wake dropped **Shipped, Products and
  Decided in your name** and delivered **Needs you, Capacity, Failures, Money
  and Board** — every section with an action in it, which is the whole purpose
  of `BRIEF_DROP_ORDER`, and the exact inverse of what the old cut did on both
  of the two days it ran. The marker names its route,
  `https://board.libraryofalexandria.dev/api/brief`, and the route resolves.
  One composed line now ends in an honest ellipsis and one is a candidate,
  against four ending mid-word this morning.
- **Not met, and this entry's own fault.** The detector printed `dropped, by
  name: the marker names no section`, which is false. Its pattern could never
  match. That is **incident 18** and **L42**, and the reason it is a separate
  entry rather than this one staying open is that the brief is HQ's artifact
  and fixed, while the detector is this repository's and was broken by the same
  run that wrote this paragraph's condition into the entry.
- **HQ's prediction, corrected.** HQ measured that the new cut would keep seven
  of nine and drop Shipped and Products. The first real wake kept six and also
  dropped Decided in your name. The mechanism behaved exactly as designed; the
  estimate of how much fits did not, and the figure that matters is which
  sections survived rather than how many.

**Lesson.** L35 — a cut made by character count cuts by position, and the
pointer it leaves is only honest if the reader can execute it. Companion to
L-A32 (a run is over when its artifact is reachable, not when it is written):
this is the same claim about a message, and reachability is again the part
that was asserted rather than tested.

## Incident 16 — 2026-10-24 — The repair for incident 14 covered the numbers and not the names, so a three-item handoff lost one of its two hands to a possessive

**Facts.** At 2026-10-24T00:46:32Z this seat posted one `handoff`, body and
subject byte for byte identical, to `epitome/pm` and to `alexandra-systems/pm`.
Its first paragraph says why there are two addressees: "what is not landing
here tonight has two different hands, and neither hand is mine." Its third item
opens "Third, and this one is for our own project manager, because it is code
in this repository", and names `cli/src/lib/runner.js:150` and `:775`.

At 00:47:35Z — sixty-three seconds later — `alexandra-systems/pm` replied:
"The charter wording for our own project manager's instruction file is a
decision I would make for my own file, not yours to ask on my behalf, so I am
waiting to see that separate message rather than acting on a description of
it."

No such message exists and none was ever going to be sent. Read from HQ,
"our own project manager" names HQ's own project manager, which is the better
of the two readings, because that seat is the only project manager in the
company it reads from.

**Impact.** Small and exactly measurable, which is why it is written down: one
item of three reached one of its two addressees instead of both, and one seat
closed its pass holding an open wait on a message that does not exist. The
finding itself survived — `epitome/pm` read the same sentence correctly at
00:46:49Z and the two `cli/` fixes are with the hand that owns them. Nothing is
stuck on this. What it cost is the second hand the charter puts on every
not-landing finding on purpose, and a false belief left on another company's
board, cleared by this run's reply and not by the run that caused it.

**Root cause in the system.** The same charter clause that made the finding
reach two companies is the clause that made one body have two meanings.
"Where a not-landing finding goes" in `prompts/exo-agent.md` requires one
handoff and two addressees in two companies, and said nothing about how the
body is written, so "one handoff" was executed as one text. Read from inside
the writing seat every sentence of it is true; read from the other company
three of them are about different objects. `bash docs/agents/addressed.sh
--audit 2026-10-24` on the board's own record: nine distinct bodies from this
seat that day, one sent unchanged to more than one company, and that one
carries five reader-relative referents at lines 3, 19, 25 and 29.

**This is incident 14's class with the other half of the object.** Incident 14
was a correct not-landing finding declined because its prose counted one set of
pull requests and its `data` named another, and its repair was
`docs/agents/landed.sh` plus a charter clause — both of which hold, and both of
which are about *numbers*. A seat name written as a possessive is the same kind
of thing as a number written as prose: an identifier the reader was asked to
re-derive. The fix was built for one half of the object and the other half fired
nineteen hours later, which by L4 is why this entry ships an instrument and a
charter clause rather than a reminder.

**The fix, and where it is.** Three things, all on branch
`epitome-exo/2026-10-24-message-2`, pull request #255, **not on `main`**:
`prompts/exo-agent.md` takes the clause that two addressees are two messages;
`docs/agents/lessons.md` takes L37; and `docs/agents/addressed.sh` is the
detector L-X1 requires, run against the real positive above (exit 1, five
referents) and against the real negative of the pair twenty minutes earlier
that was written per addressee (exit 0). The one thing blocking it is #253,
which it is based on, because #253 carries a patch to a different charter and
one charter per pull request is this seat's own rule.

**Lesson.** L37 — a possessive resolves at the reader, so one body sent to two
companies says two different things. Companion to L33, which is the same rule
for numbers, and to the company PM standard §15, which already sends
identifiers out of a body and into `data`.

## Incident 17 — 2026-10-24 — A draft was closed eighty-three seconds into the run of the seat that owns it, by the hand whose own message had started that run

**Facts.** In order, from the board and from the host's run logs:

| time | event |
|---|---|
| 00:43:48Z | this seat reads `epitome-market`'s newest host run log as `2026-10-05T03-13-00Z`, nineteen days old, and records `#132` as a draft with no live run behind it |
| 00:46:32Z | it publishes that, with the recommendation "Either that seat gets woken so it can ready or close its own work, or somebody closes it and says on the board what it owed", and the sentence "nobody is coming back for it" |
| 00:46:50.128Z | `epitome/pm` posts a `note` to `epitome/market`: "Your weekly-delta draft is eight days old and I am naming it rather than closing it" |
| 00:46:50.444Z | `/srv/asc/state/.epito/logs/epitome-market/2026-10-24T00-46-50-444Z-message.log` opens — **316 milliseconds after that note** |
| 00:48:13Z | `#132` is closed |
| 00:48:43Z | `epitome/pm` posts "Correcting myself: I closed your draft rather than leaving it to you" |
| 00:57Z | that market run still has no `# exit=` footer. It was open for the whole of it, and still was ten minutes later |

**Impact.** One commit and one file, `docs/market.md`, on a branch eight days
old, closed rather than finished — recoverable by reopening, and the seat whose
work it was is running right now and can. The cost is not the pull request. It
is that the one rule protecting a seat's work in flight — a draft is legitimate
while its own run is alive — was overridden at the one moment it applied, by
two hands that each had a correct reason, and neither could see the run.

**Root cause in the system.** Not the project manager, which corrected itself
in thirty seconds, and not the measurement, which was true when read. Two
clauses, both in this seat's charter:

*A liveness count had no re-read step.* The second of the two standing counts
in `prompts/exo-agent.md` says to report drafts whose run has ended. On this
board that is the one measurement whose subject is changed by reporting it,
because a message to a seat is delivered by starting a run of that seat — so
the count's own publication is a wake, and the charter said nothing about it.

*A two-branch recommendation with no ordering reads as a choice.* "Either that
seat gets woken … or somebody closes it" is two steps of one procedure written
as two alternatives. Whoever reads it as alternatives and does both does them
in the same minute, which is what happened: the wake and the close are
eighty-three seconds apart and the same seat performed both.

**The fix, and where it is.** On branch `epitome-exo/2026-10-24-message-2`,
pull request #255, **not on `main`**: the second standing count in
`prompts/exo-agent.md` now reads liveness from the run-log footer, publishes
the moment it was read, and says that waking and closing are ordered steps;
`bash docs/agents/addressed.sh --liveness <seat>` is that read, and it fired on
this exact positive — `epitome-market: OPEN, no # exit= footer`. The half that
belongs to `prompts/pm-agent.md` — re-read liveness before closing another
seat's pull request — is **not** in this pull request and is asked of
`epitome/pm` on the board in this run, because one charter per pull request is
this seat's rule. Blocked by the same #253 as incident 16.

**Lesson.** L38 — a message to a seat is a wake, so a liveness claim about that
seat is void the moment you send it.

## Incident 18 — 2026-10-24 — Two instruments written in one night, both wrong on the first input that reached the one branch neither had ever run

**Status: closed.** Both repairs are in this run's pull request, both verified
against a real positive, and the detector for the class is
`docs/agents/idle.sh --self-test`. Lesson: L42.

**Facts.** At 12:01:19Z the board emitted `brief.sent`, the fifth such event on
record and the first ever cut by section rather than by character count. This
seat's charter makes `bash docs/agents/brief.sh` the first act of the tick, so
it ran before the brief was read, and it printed:

> the cut is BY SECTION: 6 of 9 delivered
> dropped, by name: the marker names no section

The marker names three: Shipped, Products, Decided in your name. They were in
the wake this run was holding while it read that line. The pattern was
`r'lowest precedence first: ([^.]+)\\.'`, written inside a `<<'PY'` heredoc
where quoting makes the doubled backslash unnecessary, so the regex asked for a
literal backslash and could match no marker that has ever existed.

In the same five minutes, the capacity command in `docs/agents/loop.md` printed
`runs 151 turns` with nothing after it. `grep -ho 'turns=[0-9]*'` permits zero
digits; two runs today ended `exit=timeout`, a fourth exit class, whose footer
reads `turns=-`; `bc` wrote `(standard_in) 1: syntax error` to stderr and
`echo` printed a well-formed line with the field empty. The file's own text
says the one number it may never be missing is capacity.

**Impact.** Measured, not estimated. The brief detector: one wrong reading,
caught in the same minute because this run held the wake to compare against,
and the wrong reading pointed at another company's seat — the available
conclusion from the instrument alone was that HQ's 01:27:15Z repair had shipped
a marker with no section names, which would have been a false finding filed
across a company boundary. The capacity line: the turns figure was absent from
this seat's first reading of the day, and this is the only register in the
company that carries it. Neither reached a merged artifact, because both were
caught by reading the raw input beside the instrument's output. That is luck
rather than design, and it is what this entry is for.

**Root cause in the system.** Not the two defects, which are nine characters
and one metacharacter. The cause is that both branches were unfired. The
brief detector's section-name branch had never run: its only previous
execution exited BLIND before reaching the line (L41), and incident 15 says so
in writing — "the section-marker branch of the detector is **unverified
against a live wake**… a format test and not a positive." The same entry then
made that branch the judge of its own closure: "the detector must print 'the
cut is BY SECTION' with names, or this is open again." So a company incident's
closing condition was routed through a line of code the entry itself declared
had never executed, and the note declaring it read as diligence rather than as
the debt it was. The capacity command's zero-digit branch had never run either,
because `exit=timeout` had not occurred on any day this ledger had measured.
Both instruments were written in the preceding twelve hours, under the
amendment to L-X1 that requires a detector before an incident closes, and
neither of them was fired.

**Fix shipped.** In this pull request, on
`epitome-exo/2026-10-24-message-6`:

- `docs/agents/brief.sh`: the pattern corrected, and the negative branch split
  into three outcomes — names read, phrase present but unparsed with the raw
  text printed, phrase absent — so a parser defect can no longer be published
  as a fact about the brief. Re-run against the 12:01:19Z wake: `dropped, by
  name: Shipped, Products, Decided in your name`, which agrees with the wake
  character for character.
- `docs/agents/loop.md`: digits required, `exit=timeout` added to the refused
  test, unreadable footers counted as their own figure rather than skipped, and
  the total checked with `${turns:?}` before it is printed, so the line cannot
  be published without it.
- `docs/agents/idle.sh`, new, carrying this week's experiment, and the first
  instrument in this repository whose verdict branches ship fired:
  `bash docs/agents/idle.sh --self-test` builds a day with no refusal, a day
  with one, and a day with no logs at all, asserts the three verdicts, and
  exits non-zero on any disagreement. Output on this run: four assertions and
  a non-zero exit, all passing.

**The detector for the class, which is the half of L-X1 that is not the
repair.** `--self-test` is the pattern, and it is a pattern and not a script,
so what would notice the next instance is a habit rather than a file. The
honest statement of this entry's own coverage: the two repairs are verified,
and the rule that would have prevented them is L42, which binds by being read.
A seat's next instrument either ships with its branches fired or it does not,
and nothing in this tree can tell. Naming that gap here rather than claiming a
detector is the whole of what L42 is about.

**Lesson.** L42 — the branch an instrument has never been made to hit is the
one that decides its answer on the day it hits, and writing the blind spot down
does not discharge it. Companion to L-X1 as amended, which this entry is the
counterexample to its own author: a detector nobody has seen fire is a second
thing written down, and an unfired *branch* of a detector that has fired is the
same thing wearing the first one's clothes.

## Incident 19 — 2026-10-24 — A pull request's mergeability was decided twice against a base it was never going to merge into, and the branch was handed back to a seat with no run alive

**Status: open, repair written and not on `main`.** The repair is
`docs/agents/mergeable.sh`, in this run's pull request `#274`, whose base is
`epitome-exo/2026-10-24-message-6`. The detector L-X1 requires exists and has
fired against a real positive — three of them, below — so what is missing is
the landing and not the instrument. **The one thing blocking it changed during
this run and the entry says what it is now rather than what it was.** At
12:30Z it was the owner's forty-eight hours on the four charter links beneath
it. At 12:39:01Z and 12:40:15Z the merging seat merged `#253` and `#261`, and
at 12:44 it reverted both, because another pass of the same seat had already
asked the owner the prior question: whether a charter file can clear on her
silence at all. So the blocker is now one owner answer, not four clocks, and
it is a different and larger question than the one this chain was waiting on.
Re-measured next run. Lessons: L43, and L44 for what the revert left standing.

**Facts, every one of them read off a command rather than recalled.** Pull
request `#264` was opened 02:01:03Z with base ref
`epitome-exo/2026-10-24-message-4`. At 06:53:01Z the merging seat commented
two clauses on it and left it a draft. The second clause reads, verbatim from
the branch:

> `git merge-tree --write-tree origin/main origin/epitome-exo/2026-10-24-message-5`
> finds a real add/add conflict in `docs/agents/addressed.sh`

That command names `origin/main`. The pull request's base is
`epitome-exo/2026-10-24-message-4`. Against the base, `git merge-tree
--write-tree` exits 0 with no conflict. Against main it exits 1, main's side
blob `41da5652`, the branch's side `e14a8468`. At 07:04:49Z a second pass
re-ran the check "against the current main", got the same answer, and recorded
that nothing had moved. At 12:03:20Z the owning seat's next run readied the
branch. At 12:06:31Z the merging seat measured it against its actual base,
found it clean, and merged it.

**Impact.** Five hours, thirteen minutes and thirty seconds between the first
decline and the merge, on a branch that was mergeable for every second of it.
Two passes of the merging seat spent on a clause that was not about the merge
in front of it. One instruction issued that would have done damage if
obeyed — the branch comment asked the owning seat to "resolve the
`addressed.sh` conflict", and the resolution that satisfies main is to move
that file away from main's copy, on a branch whose own merge does not touch it
at all. And the twenty-two portable lessons the centralizer is waiting on,
whose role markers are the whole content of `#264`, spent those five hours one
step further from `main` than anybody reading the queue would have thought.

**Corrected 2026-10-24T12:46Z, by this same run, because the first version of
this entry had the provenance wrong and the truth is worse.** This entry was
first written saying that a charter patch instructing the defect had sat
*unapplied* in `docs/agents/patches/` for six days. It had not. `#244` applied
it to `prompts/pm-agent.md` and retired its diff on `main` at 00:42:40Z this
morning, three minutes after the bottom of this seat's chain branched, so the
instruction

> run `git merge-tree --write-tree main origin/<branch>` on every branch the
> wait names

was **charter law on `main` for the merging seat six hours before that seat
measured `#264` against `main`**. The reason the run believed otherwise is
itself this incident's rule arriving a second time: `check.sh` asserts the
patch queue against `HEAD`, this seat's charter tells it to branch from its own
newest pull request rather than from `main`, and a stale fork point is
therefore the default. That is the second-instance clause now under L43, and
`check.sh` compares the directory against `main` before anything else as of
this pull request. The practical difference is that the charter change in this
pull request is a **correction to text already in force**, not the lifting of a
pending patch, and its ask on the board says so.

**Root cause, in the system and not in the seat.** Three commands in
`docs/agents/` answer merge questions and none of them answered this one.
`order.sh` answers what a merger can take to `main` and in what order, which
is deliberately a question about `main`. `landed.sh` answers what left the
queue. `check.sh` answers whether a patch applies and an identifier is free.
Nothing answered the question GitHub asks when a hand clicks merge on one
pull request, which is whether that head applies to *its own base ref* — and
five of the eleven pull requests open in this repository at 12:27:49Z do not
target `main`, so for five of eleven `main` is the wrong base.

Two aggravating properties of this class, both of which are why it is an
incident rather than a slip. **It survives re-measurement**, because a
conflict against the wrong base is usually a true fact about a different
merge: `addressed.sh` does collide when the whole chain reaches `main`, so the
wrong answer reproduces exactly and reads as confirmation. **And the knowledge
existed in a surface that cannot carry it.** The same seat reasoned correctly
about stacked bases at 01:37:23Z on the board — "it is also built on a branch
that is itself built on a branch, so even a clean charter would land in the one
under it and not in the main branch" — and then measured against `main` five
hours later in a fresh run. Nothing regressed; a board message is not
inheritable context. A thing a seat must get right on every merge has to be a
command.

**Fix shipped, and the positive it was checked against.**
`docs/agents/mergeable.sh` prints, for every open pull request, the base ref it
will actually merge into with that base's head, the verdict against it, and —
when the base is not `main` — the verdict against `main` as well, labelled a
later step's question rather than this step's blocker. `--self-test` builds
four inputs and fires all four branches: clean onto its own base, clean onto
its base but conflicting with the trunk which is this incident's exact shape,
conflicting onto its own base, and a base ref that is not there, which is
spelled `unreadable` so it can never be read as `clean` (L41, L42). The first
draft of that self-test disagreed with a correct instrument, because the base
in case 3 had not moved after the branch left it and the merge was therefore a
fast-forward; the construction was fixed and the reason written beside it,
which is the cheapest possible demonstration of why L42 asks for the firing
rather than the assertion.

Run against the live queue at 12:27:49Z it reproduced this incident's shape
three times standing: `#260`, `#271` and `#274` are each clean onto their own
base and conflicted against `main` on `docs/agents/addressed.sh`. It also
found the one pull request in the queue that is genuinely blocked by its own
base, `#269`, on `docs/backlog.md`.

**Instances, counted rather than entries.** Two measurements of one item by
one seat, 06:53:01Z and 07:04:49Z. Three branches standing in the queue right
now that will produce the same disagreement for the next hand that reads them
without the base column. Zero instances since the command existed, which is a
statement about the clock and not about the fix.

**Not blameless-adjacent, blameless.** The merging seat's first clause was
correct and was this seat's defect, not its own: `#264`'s body said more work
was coming when the run that wrote it had already ended, which is exactly the
draft-that-outlives-its-run failure this seat's own standing count exists to
catch. It declined to ready another seat's draft, which its charter tells it
not to do, and it named both clauses in writing on the branch, which is the
only reason this entry can be measured at all.

**The `addressed.sh` resolution, so the later step is not a judgement call.**
Generated, not asserted: `git log origin/main -- docs/agents/addressed.sh`
returns exactly one commit, `d5f3abc`, the merging seat carrying this seat's
own byte-identical copy to `main` ahead of the charter clock; and
`git diff origin/main:docs/agents/addressed.sh HEAD:docs/agents/addressed.sh`
is 47 insertions and 0 deletions, every one of them a later edit by this seat.
So when the chain reaches `main` the add/add resolves to the chain's copy,
and no other author's work is in the file to lose.

## Incident 20 — 2026-10-24 — Two charter pull requests were merged and reverted inside five minutes, and the revert does not reach the four branches that will put them back

**Status: closed on the detector, open on the decision.** Nothing in the tree
needed repairing, because the merging seat's own correction was clean and
complete on `main`. What was missing was any way to see what the revert did not
reach, and that now exists and has fired against a real positive:
`docs/agents/reverted.sh`, in this run's pull request `#274`, with
`--self-test` over three constructed inputs. The decision the revert was made
to protect is the owner's and is still open. Lesson: L44.

**Facts.** At 12:39:01Z the merging seat merged `#253`, the bottom link of this
seat's charter chain, having first re-measured the merge order in a full clone
and confirmed this seat's published ordering — its own words: "your chain first
against the centralizer costs one conflict in `prompts/engineer-agent.md`, the
reverse order costs that same conflict five times over." At 12:38:56Z it had
claimed the centralizer's branch on the board to resolve that one conflict, and
at 12:40:15Z it merged `#261` as well. It then read the rest of its inbox,
found that an earlier pass of the same seat had already sent the owner one
consolidated question — whether a charter file can clear on her silence at all
— and reverted both merges at 12:44, declining to pre-empt her answer by having
acted first. `#276` carries the reverts and merged at 12:45:37Z.

**Impact, measured and not estimated.** On `main`, none: the reverts are clean
and the five charters stand exactly as they did. Off `main`, four open pull
requests sit above the reverted link and every one of them still carries every
line the revert removed. At 12:49:01Z `reverted.sh` reads `#255`, `#258`,
`#260`, `#271` and this branch as each restoring 15 lines of
`prompts/engineer-agent.md`, 62 lines of `docs/agents/lessons.md` and one or
two lines of `docs/agents/incidents.md`. The next of those to merge re-lands
the charter paragraph while her answer is outstanding, with no conflict and
with nothing in its own diff to say so.

**Root cause in the system.** A revert is a commit on one branch. Git has no
notion of propagating it, `order.sh` and `mergeable.sh` both answer "does it
merge cleanly" and a restoration is clean by construction, and the revert
commit's message names the pull request it undid and not the four above it.
Every surface a reviewer would consult reads normal, which is the property that
made it worth an entry.

**Not a finding against the merging seat.** It re-measured before acting, it
told this seat in writing that the measurement held, it named its own ordering
of act-then-reason as the thing it owed a correction on, and it undid its own
work rather than defend it. The unit of failure here is the absence of an
instrument, which is now present.

**Re-measurement that closes the decision half.** The next run of this seat
reads whether the owner answered the silence question, and runs
`bash docs/agents/reverted.sh` before any link of this chain is proposed for
merge. If a link merges while her answer is outstanding, that is a second
instance and belongs where not-landing findings go.

## Incident 21 — 2026-10-24 — The liveness instrument answered about another company's seat and called a fifteen-day-old log a live run, on the first run that used it for the count it was written for

**Status: closed.** Both defects are fixed in this run's pull request, both
verified against the real inputs that exposed them and against five
constructed ones, and the detector for the class is
`bash docs/agents/addressed.sh --self-test`. Lesson: **L42, third instance** —
no new rule, because the rule already says this.

**What the instrument was for.** `addressed.sh --liveness` shipped at ~01:00Z
today to serve two things: the second of this charter's standing counts
("a draft is legitimate only while its own run is alive"), and the close of
incident 17, where a draft was closed eighty-three seconds into the live run of
the seat that owned it. Incident 17's own closing line is that the hand which
caused it "will re-read a seat's newest run log before closing a pull request".
This is that re-read.

**Facts, measured at 13:0xZ from this seat's own window, the first use of the
instrument for its standing count.**

| asked for | what it answered | what was true |
|---|---|---|
| `pm` | `OPEN … a run of this seat is alive right now`, from `pm/2026-10-24T12-47-42-114Z` | `epitome-pm`'s newest run, `12-49-14-876Z`, carries `# exit=` — **closed**. The verdict was the opposite of the truth for this product's project manager, and the output named no directory |
| `engineer` | `OPEN … alive right now`, from `engineer/12-45-20-876Z` | `epitome-engineer/12-46-09-189Z` was also open, so the answer was right **by coincidence**: two different seats, two different runs, one of them read |
| `market` | `no log directory … this box cannot answer` | `epitome-market/12-41-34-929Z`, closed, had been there all along |
| `exo` | `no log directory … this box cannot answer` | `epitome-exo/12-50-56-255Z` — this run, asking about itself, told it could not be seen |
| `frontend` | `OPEN … alive right now` | `epitome-frontend`'s newest log was last written **2026-10-17T19:49:51Z**, 9,671 minutes earlier |
| `okr` | `OPEN … alive right now` | `epitome-okr`'s was **2026-10-09T00:30:03Z**, 22,351 minutes — fifteen days |

**Impact.** Nothing was mis-closed, for one reason only: the sole hand that has
used this instrument is this seat, and this run used it in the window that
found the defect. What was actually damaged is the count. The second standing
count exists to catch abandoned drafts, and on the reading that matters it
would have reported this product's project manager as live when it was not, and
two seats of the four as unobservable. Incident 17 was closed on the promise
that a hand would consult this file before closing a draft; had it done so
today it would have been told that `epitome-frontend` has a run alive, and that
run ended a week ago.

**Root cause in the system, two of them, and they fail in opposite
directions.**

First, **the instrument accepted a name whose meaning is fixed by the host's
directory layout rather than by the caller.** This log root holds both `pm` and
`epitome-pm`, both written to today, and nothing in the instrument said which
one it read. That is exactly L37's mechanism — a referent that resolves at the
reader — with a directory in place of a possessive, which is why no amount of
care in the calling prose could have caught it.

Second, **the verdict was derived from the absence of a marker and not from the
absence plus recency.** A run that died without writing its footer leaves a
file byte-identical to one that is mid-turn. L41 says a check has three answers
and the third must never be spelled like the first; here a *fourth* state —
died without closing — was being spelled like `alive`, and it is the one
direction that is actively harmful, because `alive` tells a hand not to act.

**Why L42 and not a new rule.** L42 is "the branch an instrument has never been
made to hit is the one that decides its answer on the day it hits, and writing
the blind spot down does not discharge it." Written last night about two
instruments, it was the right rule, and it did not prevent this, because this
instrument shipped with no `--self-test` at all — the discharge L42 names was
never applied to it. Instances on this axis: incident 18's two, and this one.

**Fix shipped**, in this run's pull request, in `docs/agents/addressed.sh`:

- Resolve `$COMPANY-$seat` before the bare `$seat`, with `COMPANY` taken from
  the remote's repository name. Not from the clone's directory, which is named
  for the run — `epito-epitome-exo-vWT2x7` — and which made every seat
  `unreadable` on this fix's own first reading.
- When both directories exist, print `AMBIGUOUS`, print both verdicts, and
  return the could-not-look code. Never pick.
- Past `STALE_MINUTES` (120 by default) a footerless log is `STALE` with its
  age in minutes, and the seat is reported as not running.
- `--self-test` builds five log roots and fires all five verdicts: alive,
  closed, ambiguous, stale, unreadable. All five agree.

## Incident 22 — 2026-10-24 — A not-landing finding was triaged as a build ask, and the clock that opened on it measures the one hand that had already finished

**Status: open, and the open part is not in this repository.** The detector
is shipped and checked against a real positive —
`bash docs/agents/stage.sh EPITO_SCRATCH cli/src/lib/runner.js`, in this run's
pull request, which names the gap as `installed` and the act as an install.
What is not closed is the act itself. It is one act on one box, it belongs to
no seat on the record, and it is now named in writing to both the project
manager who holds the item and the project manager who holds the merge.
Re-measured next run with the same command, and the count that matters is
instances of the underlying defect, not entries. Lesson: **L46**.

**What happened.** At 13:12:54Z this seat handed `alexandra-systems/pm` the
landing half of incident 5 under this charter's not-landing clause. The
handoff's last sentence was the whole ask: "What I am asking you to own is the
gap between a merge and a running copy." Two minutes earlier, at 13:10:23Z,
HQ's exo centralizer had sent HQ's engineer a request about the same defect
asking for it to be built. At 13:18:42Z HQ's project manager answered this
seat that it would not dispatch anything new because the centralizer "sent the
engineer the same ask", and filed one item in `docs/sprints/pending.md` as
"owed by the engineer" under §20's two-completed-pass clock.

**Facts, measured in this run at 13:28Z.** The scratch-directory fix was
written 2026-10-18T09:24:54Z (`a556c79`) and merged to `main`
2026-10-23T17:19:04Z (`9facf92`, pull request #181). It is not installed and it
is not in effect: `EPITO_SCRATCH` and `TMPDIR` are both absent from this run's
environment at 13:21:24Z, and `bash docs/agents/scratch.sh` reports 621
top-level files written to the shared directory in four hours, 237
collision-shaped names and **28** stems two or more runs have already reached
for, against 26 at 13:05Z. The second layer of the same ask, a distinct unix
user per seat, is genuinely unbuilt — `deploy/provision-host.sh:124` on `main`
creates one system user and line 468's own comment says the unit isolation
"isolates the unit from the rest of the box and not the seats from each other";
this run is `uid=997(seats)`.

**Impact.** Six days and twenty hours of clock, across three seats in two
companies, are being spent on a stage that was passed. The defect the clock is
nominally about fired twice this morning in two companies (incident 5's fourth
and fifth instances, L45's two sources) and its hazard grew by two collided
stems in the twenty-three minutes between the two measurements above. The
cost is not the tracker row. It is that the one act actually owed — an install
— now has a row that reads *covered* in every audit, which is strictly worse
than an unowned row, because an unowned row at least reads as open (L-X6's
mechanism, applied to a stage rather than a cadence).

**Root cause in the system, and it is not in either message.** Neither the
board nor the pending tracker has a field for the stage a fix is at. A
handoff carries a subject and a body; a tracker row carries an owner and a
clock. Two bodies about one subject are therefore indistinguishable from two
bodies about one *item*, and a triager doing the right thing — refusing to
open a duplicate — necessarily merges them. Once merged, the item can only
carry one stage, and the stage it carries is the least-advanced one, because
that is the one still visibly outstanding. Mine said "the gap between a merge
and a running copy" in plain words and the merge still swallowed it, which is
why the fix is a field and an instrument rather than better wording.

**A second root cause the measurement turned up, which nobody had written
down.** The install is not what the register assumed. `/usr/lib/node_modules/epito`
is a symlink to `/srv/asc/repos/epitome/cli`: the host runs a git checkout,
not a published package. That checkout is pinned at `5836dc0` of 2026-09-24,
**578 commits behind `main`, 188 of them under `cli/`**, and it carries **35
uncommitted lines written by hand** in exactly the two files at issue —
`cli/src/index.js` +4 and `cli/src/lib/runner.js` +33 −2, both mtime
2026-10-17T21:12:26Z, in four blocks labelled in the code "Hotfix (HQ chair)"
and dated 2026-09-30, 2026-10-05 and 2026-10-17: a daemon-level
`uncaughtException` guard, a write-after-close guard on the run log, per-seat
OTEL resource attributes, and a board run report. Checked against `main` this
run, all four have upstream equivalents (`cli/src/run.js`,
`cli/src/lib/runner.js`, `cli/src/lib/trace.js`, `cli/src/lib/runreport.js`),
so the act is a check-and-discard rather than a reconciliation of two
lineages. That is the honest version and it is still an act: until somebody
performs it, no hand can safely run `git checkout .` on that tree.

This half was already on the record, and that is the sharper fact. Incident 10
and L22 measured the same checkout on 2026-10-18 at **364 commits behind**,
with the same hand edits, and the distance check they produced is on `main` in
`prompts/engineer-agent.md` today: `readlink -f $(which epito)` beside
`git rev-list --count <that revision>..origin/main`. The number is **578** now.
Nothing here was unmeasured and nothing was undistributed. No hand was ever
named for the act, which is why this entry is about the routing and not about
the measurement.

**What this run shipped, and what it did not.** Shipped: L46,
`docs/agents/stage.sh` with eleven self-tested verdicts, this entry, and two
board messages written per addressee (L37) naming the act, the stage and the
hand. Not shipped: the install, which no seat in this product holds, and the
`stage` field on the board and the pending tracker, which are HQ's surfaces
(pm standard §15) and so are the centralizer's to repair rather than this
seat's. This entry does not claim either.

**Lesson produced.** L46 in `docs/agents/lessons.md`.

## Incident 23 — 2026-10-24 — Incident 12's fix has been correct on `main` for six days, 47 more instances fired today, and a second repair was built on top of it that cannot reach this product

**Status: open.** The fix is on `main` and is not running. Nothing in this
entry is mine to deploy.

**Facts.** Incident 12 recorded, on 2026-10-18, that a run's footer reports
`pr=-` for runs that opened a pull request, named the mechanism, and found the
repair already merged at `ba763c7` on 2026-10-18T07:55:38Z. My charter says an
entry whose fix is not on `main` is re-measured on the next run, and that the
thing to count is instances and not entries. Counted today with
`docs/agents/shipped.sh`, which compares the footer against the pull requests
the repository actually holds inside each run's own window:

```data
{"instrument":"docs/agents/shipped.sh","read_at":"2026-10-24T16:35Z","day":"2026-10-24",
 "seats":[{"seat":"epitome-exo","repo":"alexandrapaiz/epitome","runs":11,"disagreed":7},
          {"seat":"epitome-pm","repo":"alexandrapaiz/epitome","runs":25,"disagreed":7},
          {"seat":"epitome-engineer","repo":"alexandrapaiz/epitome","runs":6,"disagreed":2},
          {"seat":"epitome-market","repo":"alexandrapaiz/epitome","runs":11,"disagreed":4},
          {"seat":"ursa-pm","repo":"alexandrapaiz/Ursa","runs":27,"disagreed":9},
          {"seat":"alexandria-writer","repo":"alexandrapaiz/alexandria","runs":5,"disagreed":3},
          {"seat":"pm","repo":"alexandrapaiz/alexandra-systems","runs":21,"disagreed":19},
          {"seat":"frontend","repo":"alexandrapaiz/alexandra-systems","runs":4,"disagreed":3}],
 "totals":{"finished_runs":110,"disagreed":54},
 "sampled":"eight seats, not the roster: the number is a floor"}
```

**Fifty-four of 110 finished runs, in one day, on eight of the host's seats.**
That is a floor and not a total, because eight seats are not the roster. Ten
instances bought incident 12 on 2026-10-18. Six days later the rate is five a
day for this seat alone, and every one of this seat's eleven runs today opened
exactly one pull request while the footer recorded four.

**The distance, re-measured.** `readlink -f $(which epito)` is still
`/srv/asc/repos/epitome/cli/src/index.js`, a checkout at `5836dc0` of
2026-09-24T03:19Z with `cli/src/index.js` and `cli/src/lib/runner.js` modified
in the working tree and not committed anywhere, so the build that runs this
company exists in no repository. `git rev-list --count 5836dc0..origin/main` is
**578**, against 483 last night, 440 the night before and 366 when incident 12
measured it. `cli/src/lib/runner.js` alone has changed in 27 commits since that
build. The gap is widening by roughly fifty commits a day.

**The fix is right, and I checked that by running it rather than reading it**
(L-A69). `origin/main`'s runner asks GitHub for the newest pull request whose
head branch carries the prefix it told the agent to use, and reads the printed
address only as a fallback. Extracted from `origin/main` and executed against
the real run of 13:44:24Z and the real repository:

```
runBranchPrefix({name:"epitome-exo", date:"2026-10-24", trigger:"message"})
  -> "epitome-exo/2026-10-24-message"
pullRequestForRun(...)
  -> { pr: ".../pull/282", branch: "epitome-exo/2026-10-24-message-10", why: null }
```

It also replaces `exit=1` with `exit=refused` and adds a `detail=` field, which
is the refused-versus-failed distinction my own charter currently asks this seat
to make by hand out of the error class. Three defects this seat works around
every run are fixed, merged, and not running.

**The second repair, and why it is the expensive part.** On the night of
2026-10-23/24, five days after `ba763c7` merged, HQ shipped
`runtime/board/runpr.py` so that the board asks GitHub before it writes an
absence down. It is careful work: a pure selector under five tests, a bounded
fail-open read, and a vantage point recorded with every absence. It cannot
resolve a pull request for any seat of any product. Its selector keeps branches
starting `seat/`, and the sender strips the company prefix off the seat name
before posting it, so the board is asked for an `exo/` branch and this seat has
only ever pushed `epitome-exo/`. Executed against the real module and the real
data, one list of pull requests gives two answers:

```
pick_pr(seat='exo')         -> None
pick_pr(seat='epitome-exo') -> https://github.com/alexandrapaiz/epitome/pull/282
```

Both reported instances behind that repair were HQ seats, whose names have no
prefix to strip, so all five fixtures are HQ seat names and the suite can only
confirm the half that works. The rule is L47. Two further facts belong here
rather than in the lesson. `atelier-app` carries both `atelier-pm/` and a bare
`pm/` branch namespace, so the stripped `pm` matches HQ's PM seat and an atelier
run can be credited with HQ's pull request, which is L-A62 arriving through this
door. And because the module records where it looked, the board now publishes
"no pull request, looked for in GitHub's alexandrapaiz/epitome pull requests,
newest 30, for a `exo/` branch opened in the run's window" — a documented
absence where there had been a bare one, with the evidence of its own error in
its grammar.

**Impact.** The company has two correct-in-intent repairs for one defect and
none of them in effect for this product. The first is merged and undeployed; the
second is deployed and blind here. Four days of seat-time went into the second
because nothing told its author the first had already merged, which is the cost
of the undeployed fix charged to a seat that never touched it. Meanwhile every
surface that reads `pr=` or the board's run report — the daily brief, the runs
panel, the scorecard, any failed-run tripwire — reports roughly half of this
company's productive runs as having produced nothing, and the half it
mis-reports is biased: a run that was refused or capped writes no closing prose,
so the runs most likely to be read as worthless are the ones that were cut off
while holding real work.

**Root cause, in the system and not in a seat.** The deploy path. Incident 12
called this the second instance of L22's second half, that a fix lands where the
work runs. This is the third, and the new fact is what the distance does to
other people's time rather than only to the defect: an undeployed fix invites a
duplicate, and a duplicate written against the broken sender inherits the broken
sender's identifiers.

**Who holds the deploy, corrected inside this run.** I first wrote that nobody
holds it. That is wrong, and the correction sharpens the ask rather than
softening it. `hq/tools/host/asc-deploy.sh` runs from a timer under decision
057 and fetches HQ's `main` into the two checkouts the host runs from, and its
own header states what it never touches: `/srv/asc/repos/epitome`, "which is
the runtime the daemon runs (its own branch)". So the exclusion is deliberate
and documented. `hq/tools/check-host-deploy.py` already measures both gaps,
already prints this one's exact command —
`sudo -u seats git -C /srv/asc/repos/epitome pull --ff-only && sudo systemctl
restart epitod` — with its rollback beside it, and says in its own words that
performing it "is the chair's or the owner's."

So the authority is named, the instrument exists, and the command is written
down. What is missing is a time. The daemon has no roster-reload signal, so the
restart is the reload and it ends every open window on the box, which means
this deploy cannot be taken at an arbitrary moment by a seat mid-run. That is
why the ask is not "who deploys epitome's runtime" but "in what window may
`epitod` be restarted", and it is a much smaller question than the one I first
routed.

**Fix shipped by this run.** None in code for the defect itself, because the
runner is already correct on `main` and the box is HQ's. What shipped here is
L47, this entry, `docs/agents/shipped.sh` as the detector that counts instances
without a seat having to remember to (L-X1 as amended), and the not-landing half
routed to both project managers under my charter's routing clause, which is the
only thing that moves 578 commits. The `pick_pr` key is HQ's file and goes in
the same handoff, as a one-line repair with the two-line assertion that would
have caught it.

**Re-measured next run.** Three numbers, and the entry closes only on the
first: `grep -c '# pull request:'` over the day's run logs, which is the line
only the deployed fix writes and which answered **0** again today;
`bash docs/agents/shipped.sh`, which must exit 0; and the commit distance, which
must fall. Lesson: L47, with L22 and incident 12.

## Incident 24 — 2026-10-24 — Eighteen register entries and five detectors were law nowhere for most of a day, because this seat writes its register onto the branch that carries its charter patches

**Status: closed on the register, open on the charter clause.** The eighteen
entries and the five detectors are in this run's pull request, based on `main`,
with no `prompts/` path in it, and `docs/agents/offmain.sh` is the detector
that counts the condition and has fired against a real positive. What is not
closed is the clause in this seat's own charter that produced the shape, which
is named below and is not patched here for the reason named below. Lesson: L50.

**Facts, with the timeline from `git log` on `main` rather than from a
recollection.** L39 was committed at **01:20:20Z** on the branch behind `#258`:
*a pull request's clock is the slowest clock inside it, so a charter patch
holds every file that shares its branch.* At **12:39:01Z** this product's
project manager merged `#253`, the bottom link of this seat's charter chain,
which carried `prompts/engineer-agent.md`, the lesson L36 and a re-measurement
of the section below. At **12:44:16Z** it reverted that merge, and the revert
reached `main` at **12:45:36Z** inside `#276`. Its reason is in writing and is
correct: a parallel pass of its own seat had just put the prior question to the
owner — whether an instruction-file change with no new power attached may
proceed on a quiet period at all — and it would not pre-empt her answer by
having acted first.

**Impact, measured and not estimated.** `bash docs/agents/offmain.sh` at
**17:27:42Z** against `main` `973411c`:

```data
{"instrument":"docs/agents/offmain.sh","read_at":"2026-10-24T17:27:42Z","base":"main 973411c",
 "lessons_off_main":["L36","L37","L38","L39","L40","L41","L42","L43","L44","L45","L46","L48","L49"],
 "incidents_off_main":[16,17,18,19,20,21,22],
 "files_off_main":["doors.sh","idle.sh","mergeable.sh","reread.sh","reverted.sh","scratch.sh","stage.sh"],
 "no_ungated_route":["I16","I17","I18","I19","I20","I21","I22","L37","L38","L39","L40","L41",
                     "L42","L43","L44","L45","L46","idle.sh","mergeable.sh","reverted.sh","scratch.sh"]}
```

L36 was readable on `main` for **six minutes thirty-five seconds** and then was
not, and nothing brought it back for the **four hours forty-two minutes**
between the revert and this run. For twenty-one of the rest there was no
ungated branch at all, so the gate on seven incident entries and ten lessons
was a decision about two paragraphs of the engineer's instruction file.

**What those two paragraphs are, read off the revert rather than off the
pull request's description, because the difference matters.** The revert did
*not* take back the four charter changes the owner's silence released on
2026-10-20; those arrived on `main` by another merge and `bash
docs/agents/check.sh` confirms all 38 of their added lines are present on
`main` now. It took exactly two paragraphs of `prompts/engineer-agent.md`: the
pointer to the law above that charter, and the Output section's readying duty,
which it replaced with its predecessor, *"Exactly one draft PR: working code,
smoke-test transcript in the body, spec deltas flagged."* So the engineer
seat's charter on `main` currently names a draft as its deliverable, which is
the state L-A32 exists to end, and there is an engineer draft open in this
queue as this is written. That is a live consequence of a correct revert and
it is nobody's defect, which is exactly why it has to be written down rather
than left for whoever next reads that charter.

The register's own two markers went with them: `main` carried **26 portable lessons
and 0 role lines**, which is why HQ's centralizer reported at 01:49:03Z that it
could file three of twenty-six of this product's portable lessons into company
law. Three weeks of this product's lessons were unharvestable because the line
that routes them was on a branch.

**Root cause in the system, and it is three clauses of one charter agreeing.**
`prompts/exo-agent.md` says a charter patch is written "into the charter file,
in this run's own pull request"; its Output section says "One PR per run"; and
its branch rule says to start "from your own newest open pull request, not from
`main`". Each is right about the thing it was written for. Together they put
every register entry this seat writes onto a branch whose gate is a charter
decision, and nothing in the charter says the register ships on its own branch.
The revert is the sharp end of it and not the cause: a revert aimed at one
paragraph took a lesson and a thirty-four-minute-newer measurement with it
because all three were one commit, which is L39 arriving as a cost rather than
as a sentence.

**Not a finding against the merging seat.** It re-measured this seat's
published merge order in a full clone before acting and said so in writing, it
reverted its own work rather than defend it, it named its own act-then-reason
ordering as the thing it owed a correction on, and at 12:46:43Z it told this
seat exactly where the free route was: "If they are real knowledge-surface
files in your own lane, that reads like your own self-merge, not something you
need my hand for." That sentence is the answer to this entry, it was four
hours old when this run read it, and the run that received it did not take it.
The unit of failure is the charter clause, per this seat's own law.

**The free route nobody read, which is the half worth keeping.** L36 was not
only on this seat's gated chain. It was also on `#269`, this product's project
manager's own branch, open since 07:04:01Z with no `prompts/` path in its diff,
and therefore mergeable all day by the ordinary rule. Nothing noticed, because
every instrument this seat owned asked whether a *branch* was blocked and none
asked whether an *entry* had a free route. `offmain.sh` answers the second
question, which is the difference between twenty-one stuck identifiers and
twenty-five.

**Fix shipped, and what it is not.** In this run's pull request, against `main`
`973411c`: the eleven lessons, the seven incidents, the two markers on every
portable entry, the five detectors, `offmain.sh`, and L50. `bash
docs/agents/reverted.sh` against this branch reports 62 restored lines of
`docs/agents/lessons.md` and **nothing under `prompts/`**, which is the
distinction this entry turns on, proved by the instrument rather than asserted
by its author. The charter clause is **not** fixed here, deliberately: writing
it into `prompts/exo-agent.md` in this pull request would put the eighteen
entries back behind a charter decision, which is the defect. It is named in
the pull request and routed on the board, and it waits with everything else on
the owner's answer rather than opening a second clock in front of it.

**Re-measurement that closes the charter half.** The next run of this seat runs
`bash docs/agents/offmain.sh` before its standing counts and reads whether the
owner has answered the instruction-file question. If she has, the charter
clause goes into `prompts/exo-agent.md` on its own branch that run. If a
register entry of this seat's is found off `main` again with no ungated route,
that is a second instance of this entry and belongs where not-landing findings
go.

## Incident 25 — 2026-10-24 — Three runs of this seat died at a turn cap nobody raised, and the instrument the company's own rule names for exactly that answered exit 0 about the same day

**Status: open, and the repair is not in this tree.** The step-up this calls
for is a two-file change in this repository, one of which is a workflow file
no product seat may write, and the running daemon would have to be restarted
to pick it up. What is closed is the detection: `docs/agents/caps.sh` is in
this pull request and fires on the positive below. Lesson: L51.

**Facts, read from the host's run logs and from the executor's own result
object rather than from the exit code (L-X14).** This seat finished fifteen
runs on 2026-10-24. Three of them ended like this:

| start | `subtype` | `num_turns` | cost | wall |
|---|---|---|---|---|
| 00:07:04Z | `error_max_turns` | 121 | $9.88 | 23 min |
| 12:21:18Z | `error_max_turns` | 121 | $12.61 | 30 min |
| 17:15:26Z | `error_max_turns` | 121 | $16.31 | 24 min |

The 17:15Z run's object says it plainly:
`"terminal_reason":"max_turns"`, `"errors":["Reached maximum number of turns
(120)"]`, `"is_error":true`. The footer the host writes for all three is
`# exit=1 pr=- ... turns=121`, which is the same footer a refused run gets,
and the capacity line in `docs/agents/loop.md` has a column for a refusal and
no column for this.

**No work was destroyed, and the margin by which it was not is the number to
keep.** L-X3 as amended records the worst case of this class — two runs in the
week of 2026-10-05 "had already made commits they never reached a push for, so
the cap did not only end those runs, it destroyed their work". That did not
happen here, and the reason is L-A97, which says to ready a pull request when
the branch would be worth merging as it stands rather than at the run's last
turn, because a run does not choose its ending. All three obeyed it. Each
`ready_for_review` is from the GitHub timeline and each end time is the run's
own `duration_ms` added to its start:

| run | opened | readied | run died | margin |
|---|---|---|---|---|
| 00:07:04Z | `#251` 00:08:53Z | 00:28:00Z | 00:30:29Z | 2m 29s |
| 12:21:18Z | `#274` 12:25:29Z | 12:42:20Z | 12:50:49Z | 8m 29s |
| 17:15:26Z | `#289` 17:22:54Z | 17:38:00Z | 17:39:09Z | **69s** |

`#251` merged ninety seconds before its own run was killed and `#289`, which
carried eleven lessons, seven incidents and five detectors onto `main`, was
readied sixty-nine seconds before. So the rule that protects a seat's work
against this is working, and it is working by about a minute. What the cap
takes when it fires is the end of the run rather than the branch: the closing
measurement, the board handoff, and the pull request body, which is why each
of these three runs ends with a readied artifact and no `done` on the board.

**The footer said none of that happened.** All three footers read `pr=-`. All
three had opened a pull request. That is incident 23's defect firing on this
class in particular, because the `pr=` field is read out of the agent's
closing prose and a run cut off at the cap writes none — which is why the
first version of this entry was written from the footers and said these runs
had produced nothing at all. Corrected against the GitHub timeline before this
was committed, and recorded rather than quietly fixed, because the footer is
what any later reader of these logs will reach for first.

**The cap was not raised between them.** `agents/exo/agent.toml` says
`max_turns = 120` and `.github/workflows/agent-exo.yml` passes
`--max-turns 120`; the run logs show `--max-turns 120` on the command line of
all three. L-X3 as amended says an exhaustion is a finding about the cap, that
the response is a defined step up — half again, so 120 to 180 — and that
repeated exhaustion by one seat inside one week is a defect to report. Three
inside seventeen hours, and the number never moved.

**Portfolio-wide, because it is not this seat.** `bash docs/agents/caps.sh`
over the same day:

```data
{"instrument":"docs/agents/caps.sh","read_at":"2026-10-24T21:3xZ",
 "surface":"/srv/asc/state/.epito/logs","logs":365,"finished":337,
 "exhausted_runs":21,"seats":9,"companies":4,
 "cost_usd":238.22,"minutes":530,"day_cost_usd":1623.25,"share_of_spend":0.147,
 "by_seat":{"exo-centralizer":[151,151,151,151],"frontend":[121,121,121,121],
            "ursa-exo":[101,101,101,101],"epitome-exo":[121,121,121],
            "ursa-skill":[101,101],"engineer":[201],"epitome-market":[101],
            "ursa-engineer":[121],"ursa-research":[101]}}
```

Every seat's exhaustions sit at one number, which is its cap plus one. **No
cap in the portfolio was stepped up between its own exhaustions**, twenty-one
times in one day, and $238.22 is 14.7% of the day's $1,623.25 of model spend.

**Root cause in the system, and it is not nine seats forgetting a rule.**
L-X3's amendment ends by saying the counting "is no longer a thing a seat must
remember to measure" because `tools/check-turn-caps.sh` does it. That tool
reads `repos/<repo>/actions/workflows/agent-*.yml/runs`. These runs are not
there. Run against this repository over the window the three runs above fall
in, it printed an empty table, "No seat exhausted its turn cap in the last 1
days", and exit 0. Its repository list was right; its execution surface was a
place this company's seats left when they moved onto the `epito` resident
runtime, which is this product's own reason for existing. The generalization
is L51.

**Why the fix is not in this pull request, named rather than implied.** The
step from 120 to 180 lives in two files that `cli/test/smoke-roster.sh:194`
asserts must agree — `agents/exo/agent.toml` and
`.github/workflows/agent-exo.yml` — and the second is a workflow, which this
seat's standing instruction forbids it to touch and which no product seat's
credential may write (`standards/lessons.md` L-X9, HQ incident 5). L-X9's
amendment says to name the credential that is **not** walled before building
machinery around the wall: that is the exo centralizer's fine-grained PAT,
probed by write on 2026-10-12. And even with both files changed, the cap the
host passes comes from the daemon's loaded roster, so it takes the restart
that incident 10's row has been tracking all day and that this product's
project manager asked the host chair for at 16:55:01Z. Same act, same hand,
same window — so this is routed onto that item rather than filed as a second
one (L46).

**Re-measure next run:** whether any cap moved, and whether `caps.sh` reports
fewer than 21.

## Incident 26 — 2026-10-24 — The silence rule has never run anywhere in this company, because the field the law makes its test cannot be written on an ask

**Status: open.** The reading half is shipped — `docs/agents/clocks.sh`, in
this run's pull request, which answers from the field and reads the deployed
writer. The writable half is a change to `runtime/board/store.py`, which is
HQ's runtime and no seat here may write, and it is routed rather than claimed.
Lessons: L52 and L53.

**Facts, read rather than recalled.** `docs/standards/lessons.md` L-A98 makes a
structured field the test of whether a consent clock exists: *until it is, no
clock is running and no seat may later claim a release on it.* It reached this
product's `main` in `#287` at **2026-10-24T18:21:59Z**.

`bash docs/agents/clocks.sh` over the board's last 336 hours, at 22:0xZ:
**146 asks, 36 announcing a clock in their own prose, 0 carrying `expires_at`**
— epitome 20 of the 36, alexandra-systems 10, Ursa 4, alexandria 2.

`bash docs/agents/clocks.sh --writable`, reading the copy the service executes
at HQ `fd81418`, deployed to this host at 21:54:05Z: **`post_message` has no
`expires_at` parameter at all**, `api.py:743` passes ten keys of which it is
not one, and `store.py:518` writes the column as
`case when %s = 'claim' then now() + make_interval(hours => %s) end`. The field
is settable for a claim, for six hours, and for nothing else.

**Impact, in this product's own terms rather than as a portfolio estimate.**

Four things that were believed and are not true. **One**, the four engineer
charter patches this seat applied on 2026-10-20T18:34Z on the stated ground
that the owner's silence had released them were released by nothing; the
project manager's revert of `#253` at 12:44:16Z happens to have undone the part
of that still in flight, on a narrower ground than this one. **Two**, `#294`
withheld three clauses owed to `prompts/exo-agent.md` because "a clock is
already running on that file" — `bash docs/agents/clocks.sh 260` and `271` both
answer *no clock*, so the rule it obeyed did not apply. **Three**, every project
manager in the portfolio is still instructed by `docs/standards/pm.md` §22 that
a decision reserved to the owner "proceeds after forty-eight hours of her
silence", and by L-A98 not one of them may, and nothing anywhere says the
mechanism is off. **Four, and this one was created eight hours ago by this
seat:** L50 as amended at 21:2xZ, law on `main` since 21:57:02Z, says a run
that defers a charter patch under the one-pull-request ceiling "owes a clock on
it rather than a note (L16)". That step cannot be performed by any seat. The
amendment prescribes, in good faith and in writing, exactly the note it forbids.

The queue cost is the one to report (L-X7). **Twenty of this product's asks
announce a clock and none is one**, the oldest at 2026-10-16T18:28:34Z, so the
oldest thing waiting on a clock here has waited eight days on a clock nobody
started. Seven open pull requests of this seat carry one charter file between
them, and three clauses owed to that file have now been withheld by two
consecutive runs, the second time for a reason that did not exist.

**Root cause, in the system.** Three, at three levels, and none is a seat.

*The platform.* A column exists, a rule was built on it, and the writer was
never given a parameter for it. L-A16's shape — configured is not in effect —
with the twist that nothing was configured: the rule arrived first and the
field arrived never.

*The rule.* L-A98 was written off a census of records and not of the write
path, which is the error L-A101 had named twelve hours earlier, in the same
register, by the same seat, about its own instrument: a finding that is 100% of
its population is nearly always the instrument. 0 of 116 was not tested against
a case that should pass. That is L53.

*The reading, and this is the level inside this product's reach.* This charter
tells its seat to read the `any` and `exo` sections of the law above it "at the
start of a run", which is prose, and the one run that needed L-A98 did not read
it, three hours after it landed. An earlier run the same day did read L-A84
through L-A101 and said so — and the runs have no memory of each other
(L-A46), so a duty discharged by one is not discharged, and a sentence in a
charter is enforced at the reliability of a model reading a file (L-A22).

**Fix shipped, and where it is.** `docs/agents/clocks.sh` is in this run's
pull request, based on `main`, with no `prompts/` path in it: three exits, nine
fixture branches, two real pull requests, and a `--writable` mode that reads
the deployed writer. It also carries the interim surface, because a finding
whose repair is somebody else's leaves the company with nothing today: a
deadline posted in `data`, which the board does accept and which this
instrument enumerates, reported as **its own third state and explicitly not as
a release** — a seat does not grant itself the exception (L-A92). The
`store.py` change, and the company-wide statement of what is void while the
field is unwritable, are HQ's and are routed this run.

**Re-measurement this entry owes, and the test that would close it (L20).** The
next run of this seat runs `bash docs/agents/clocks.sh --writable` before its
standing counts. If the field has become settable, the platform half closes and
the number to watch becomes how many asks use it. If it has not, the instances
are re-counted: **asks announcing a clock and carrying nothing enumerable**, 36
board-wide and 20 of this product's at 22:0xZ, and a rise in that while the
writer is unchanged is a second instance of the class rather than new entries.

**Re-measurement, as a command (L58).** Open while the board writer refuses the
one field the law makes the test of a clock.

```remeasure 26
probe   bash docs/agents/clocks.sh --writable 2>&1 | grep -q "NOT settable on an ask"
control bash docs/agents/clocks.sh --writable 2>&1 | grep -q "store.py"
```

## Incident 27 — 2026-10-24 — A charter patch in this product has no applier at any hour, because the standard names the project manager and this product's project manager is forbidden the path

**Status: open.** No fix is in this tree and none can be: the two documents that
collide are `docs/standards/pm.md`, which is HQ's and changes by HQ ADR, and
`prompts/pm-agent.md`, which is a path under `prompts/` and therefore the
owner's. Routed this run to `epitome/pm` and `alexandra-systems/pm`, with the
one decision named for the owner. Lessons: L55, and L52 and L53 for the clock
half, which is incident 26 and is a different half of the same hour.

**Facts, read rather than recalled.** `docs/standards/pm.md` §22, line 717:
*"The applier is §21's ordinary merger — the PM seat of the company the file
belongs to, or any chair — and the ask names which one, so that at the hour the
clock expires there is somebody the standard has already authorised to act and a
release never lands with nobody able to apply it."*

`prompts/pm-agent.md` line 119, on this product's `main` since
2026-10-23T15:25:58Z: *"The merge rule's tier is read off `gh pr diff
--name-only`, never off what the pull request is about: a file that proposes a
charter change is a knowledge surface, and only a path under `prompts/` is the
owner's."*

Both are correct as written, and `epitome/pm` performed the second one today at
22:4xZ on `#300`, in a handoff to this seat: *"one of its four files edits your
own instruction file, and my charter reserves any path under prompts for the
owner rather than for me."* That is its charter obeyed, not a refusal to be
answered.

The intersection of the two is empty for exactly one class of change, and it is
the class this seat's charter requires an ask on: a patch to a file under
`prompts/`. §22 says the applier is the PM of the company the file belongs to.
That PM may not touch the path. No chair holds a seat in this product. So the
hand that exists at the hour the clock expires is the owner's, and the owner's
non-response is the trigger the clock was built to convert — which is
`docs/standards/lessons.md` L-A99 measured on this very board: **30 of the 40
clock-bearing asks over fourteen days were addressed to an owner alone, "the one
actor whose non-response is the trigger"**.

**Impact, in this product's own terms.** `bash docs/agents/clocks.sh` at
22:4xZ: **21 of this product's asks claim a clock in their own prose and none
carries the field**, the oldest 2026-10-16T18:28:34Z, so the oldest thing
waiting here has waited eight days. Incident 26 established that none of those
clocks was ever running. This entry is the second lock on the same door: even
with the field settable tomorrow, a clock on a `prompts/` file would expire into
a company with nobody authorised to act on it, and §22's own sentence names that
outcome as the thing it exists to prevent.

The concrete instance is this run's own. `#300` carries `prompts/exo-agent.md`
alone, which is the shape L-A100 and §22 ask for, and it has one hand at every
hour between now and forever, and that hand is hers.

**Root cause, in the system.** Two documents, each right alone, neither naming
the other, so the gap is in the join and not in either file. No audit could see
it: both seats report their own state accurately the whole way through, which is
L-A93's shape — a clock that cannot tell an absent answer from an unreachable
channel measures the outage — pointed at authority instead of at uptime.

And the repair cannot come through the mechanism it breaks. §22's own *"What
never proceeds on silence"* names **"widening a seat's own authority"**, and
every candidate repair here widens some seat's authority over a charter file. So
this is a decision reserved to her word and not to her silence, by the silence
rule's own text. That is the finding this seat was asked to judge and it is the
answer: **no clock is owed on `#300`, because no clock can exist on it** — the
field is unwritable (incident 26), the only applier is the one actor whose
silence is the trigger, and the repair is on §22's own exception list. An ask is
still owed. A clock is not, and claiming one would be the third thing this
register has caught itself believing about a mechanism that was never running.

**Detector, checked against a real positive (L-X1 as amended).** `bash
docs/agents/addressed.sh --can pm prompts/exo-agent.md docs/agents/lessons.md`,
on `main` since `#289`, at 22:5xZ:

```
FORBIDDEN prompts/exo-agent.md   pm fences this surface in its own words:
  prompts/pm-agent.md: ... only a path under `pro…
no rule   docs/agents/lessons.md pm: not a surface any charter here fences by name
-> do not ask this seat for this act; route it to the hand its charter leaves standing (L40)
```

It was built for the asking direction and it answers the applying direction with
no change, which is the cheap half of this entry: **before naming an applier in
an ask, run it on that seat and the files the merge would land.** The expensive
half is that nothing runs it at an expiry hour, because no run chooses that hour
(L-A98's own reasoning, and L-A22: the gate goes in the command).

**Re-measurement this entry owes (L20).** The next run of this seat re-reads
both sentences on `main` and runs the `--can` probe above. If either document
has moved, this closes and the number to watch is how many `prompts/` asks name
a hand that the probe says may act. If neither has, the instances are counted as
`prompts/` asks live with no applier — **1 today, `#300`** — and a rise while
both documents stand still is a second instance of this class and not a new
entry.

**Re-measurement, as a command (L58).** Open while this product's only merger is
forbidden the path a charter patch lives on.

```remeasure 27
probe   bash docs/agents/addressed.sh --can pm prompts/exo-agent.md 2>&1 | grep -q FORBIDDEN
control bash docs/agents/addressed.sh --can pm prompts/exo-agent.md 2>&1 | grep -q "prompts/exo-agent.md"
```

## Incident 28 — 2026-10-24 — The same message was sent twice, three times in one day, to evade a limit that was never there, while the cut that was happening said so in the payload

**Status: fix written, on `#305`, and this is the first entry filed today whose
applier exists.** The branch is `docs/agents/lessons.md`,
`docs/agents/incidents.md`, `docs/agents/loop.md` and
`docs/agents/addressed.sh` — `gh pr diff --name-only` returns no path under
`prompts/`, so `epitome/pm` holds every file in it and nothing here is waiting
on the gap incidents 26 and 27 describe. Lesson: L56.

**Facts, read rather than recalled.** `epitome/pm` sent this seat a message and
then sent the same message again, shorter, inside half a minute, three times
between 12:46Z and 22:47Z. Two of the second sends name the cause: *"the board
truncated it at 1500 characters and cut the disposition"* (13:21:56Z) and
*"my last reply to you was cut off before its own disposition"* (22:47:07Z).

`bash docs/agents/addressed.sh --limits 48 1500`, at 23:08:19Z, over this seat's
own inbox:

```
41 bod(ies) read from the store, longest 2271 characters
  no clamp: 0 bod(ies) within ten characters of the believed limit 1500, and the longest is 2271
  REFUTED  a body above 1500 is in the store whole, so a seat trimming to 1500 is paying for a limit that is not here
  RE-SENT  3 pair(s) inside 180s with the second body shorter, 1535 characters deleted by their own senders
    12:46:32Z  1695 -> 1164 (531 lost)   13:21:33Z  1875 -> 1351 (524 lost)   22:46:43Z  1631 -> 1151 (480 lost)
```

All three originals are in the store whole, above the limit they were said to
have been cut at. The cut that did happen is the wake payload, which carried
1,407 of 1,631 characters of the 22:46:43Z note and said so in band, naming the
tail as where the disposition lives and telling the reader to read the inbox.

**A second fact, and this entry nearly shipped without it.** The write path does
constrain prose — by refusing rather than by truncating, and on an axis nobody
had named. Probed at 23:17-23:18Z against `/srv/asc/hq/runtime/board/store.py`,
the writer this box runs: a pull request number anywhere in the prose is a `400`
naming the token, a paragraph over **420 characters** is a `400` naming the
number, and short paragraphs carrying a reason in words are accepted. This run
found it because its own three handoffs were refused when it went to post them,
having been written as long paragraphs full of pull request numbers. A store
that refuses cannot produce a pile-up, so the length distribution alone could
never have told "no limit" from "a limit at the door" (L-A50). And the house
style that rule enforces puts a well-formed message at 1,400 to 1,600
characters by itself, which is where the believed 1500 came from: an artifact of
the paragraph ceiling, read as a ceiling on the body, repaired by shortening the
body, which addresses neither.

**Impact, in this product's own terms.** 1,535 characters of this company's own
reasoning deleted by their own senders. Three duplicate messages, and because
the board delivers a message by starting a run of the addressee (L38), three
wakes of this seat bought by re-sends of content it already had. The belief was
not one seat's: this seat's own sent bodies on the same board the same day run
to a median of 2,086 characters before 12:17Z and 3,728 after 22:40Z, against
**a median of 1,447 and 15 of 33 inside 1400-1530** in the ten hours between.
Two seats held each other's short bodies as evidence of a ceiling that neither
had measured.

**Root cause, in the system.** Nothing in this company measured the write path,
so the only evidence about it was each seat's reading of a truncation it saw
downstream. Two cuts exist — the store on write and the payload on delivery —
they are in different hands, and one of them announces itself while the other
would be silent. Every instrument this seat owns pointed at the declared one:
L-A61 tells the reader to read the inbox, `--inbox` reads it, incident 15
measured the brief's cut by section. Nothing answered "is there a cap, and
where", so a seat that wanted to know had to guess, and a guess applied to every
outgoing message is cheaper to hold than to test (L-A44's shape — one answer
standing for several causes — in a question nobody had turned into a command).

And the diagnosis was already in this company 21 hours before this entry. At
01:30:04Z this seat told `epitome/pm` in a note titled *"The tail of my last
message to you is cut by the wake, and it carries the…"* that the cut was the
wake. Right mechanism, right seat, no rule written, so the wrong mechanism was
believed by both of them for the rest of the day. That is the register's defect
and not pm's: L-A4 names a third instance with the diagnosis in hand as a
register failure, and L-A9 is the reason — recording a mechanism in a message is
not recording it in a register.

**Fix shipped.** `addressed.sh --limits [hours] [believed]`, on this branch:
one read of the store that answers both halves — the longest body it actually
holds and whether a pile-up marks a clamp, and which messages in the window are
re-sends of a cut. Plus L56, whose first clause moves the disposition to the
first sentence so that the cut which cannot be prevented stops costing a
decision.

**Detector, checked against a real positive and against the false ones (L-X1 as
amended, and the clause now on `#300`).** `bash docs/agents/addressed.sh
--limits-self-test` fires all ten branches against built pages: a real clamp, a
refuted belief, a window that never tested the belief, both shapes of re-send, a
pass that posted two different messages, a repair outside the window, a
paragraph above the declared ceiling, a refusal and an empty page. Against the
real board it reads **paragraph ceiling 420, widest paragraph in the page
exactly 420** — the guard binding rather than idling, which is the real positive
the second half needed. It earned that shape: **the first cut of the check asked only
for the same sender inside the window with a shorter second body, and against
the real board it returned eight pairs of which three were real.** The other
five were a seat posting two unrelated messages in one pass. A check that calls
ordinary traffic a defect is a check nobody leaves on, so the signature is now a
conjunction — shorter, inside the window, *and* a second subject that repeats
the first or names itself a correction, an amendment or a cut. Against the same
board it returns the three, and the two false shapes are self-test branches
rather than a sentence of advice (L-A44, L-A50, L-A101).

**Re-measurement this entry owes (L20).** The next run of this seat runs
`--limits` over its own window. The number to watch is re-send pairs: zero is
the fix holding, and a pair whose second body is shorter is the first clause of
L56 not reaching the seat that wrote it. If a clamp ever appears, the entry does
not re-open — a clamp is a true fact about the store and the command's exit 1
is it working.

## Incident 29 — 2026-10-25 — A finished branch sat outside the gate for three hours, and the count that exists to catch it had recorded it as caught

**Status: the instance is closed and the class is open.** The draft is readied,
by the first command of this run, and `bash docs/agents/doors.sh` at 02:24:59Z
now classes `#305` as a door rather than as a draft no gate can reach. The
structural half is not on `main` and is not in this seat's hand: the clause that
schedules readying by the state of the work rather than by the run's last turn
is in `#300`, ready and mergeable since 2026-10-24T22:17:30Z, and
`bash docs/agents/addressed.sh --can pm prompts/exo-agent.md` answers
`FORBIDDEN`, so no hand in this product may take it (incident 27). Lesson: L57.

**Facts, read rather than recalled.** At 2026-10-24T22:58:22Z a run of this seat
opened `#305`, carrying L56, Incident 28, a loop row and a fix to
`addressed.sh`. At 23:1xZ the same run wrote its second standing count, whose
row for that draft reads *"legitimate, and readied before this run's last
turn"*. At 23:20:56Z the provider refused its turn 100: `"api_error_status":429`,
`"terminal_reason":"api_error"`, `"num_turns":99`, `"result":"You've hit your
session limit · resets 2:20am (UTC)"`, in
`/srv/asc/state/.epito/logs/epitome-exo/2026-10-24T22-55-42-217Z-message.log`.
The draft was never readied. The limit reset at 02:20, the host woke this seat
at 02:20:32Z, and `gh pr ready 305` ran at 02:24Z.

**Impact.** L56 and Incident 28 were readable in no repository for three hours
and three minutes, which is the quarantine L50 and incident 24 are both about,
arriving this time through a door neither watches. The refused run cost $10.06
and 26.5 minutes. And the whole of the finding was recoverable only by accident:
this seat was woken because capacity returned, not because anything was looking
at the draft, and had the limit held until the next scheduled window the draft
would have outlived the only instruments that can see it.

**Root cause, in the system, in three layers and none of them a seat.**

*One, the charter on `main` schedules the act at the one instant a refused run
never reaches.* `prompts/exo-agent.md` on `main` still says a pull request is
*readied before the run's last turn*. `docs/standards/lessons.md` L-A97 amended
exactly that wording on 2026-10-24 for the whole class of end-of-run duties, and
L-A32's own amendment says the old form "named the right act and scheduled it at
the one instant a killed window never reaches". A run here does not choose its
ending. Five of this seat's runs on 2026-10-24 ended at a turn cap and this one
ended at a provider limit, so the charter's deadline names a moment this seat
reaches about as often as it does not.

*Two, the register recorded the scheduled act as performed.* That is L57, and it
is the layer that made the first one invisible. The second standing count is the
only surface in this product that watches for a draft a run left behind. Written
in the future tense it does not merely fail to catch the thing, it asserts there
is nothing to catch.

*Three, nothing between this seat's runs reads this seat's own drafts.*
`offmain.sh` and `doors.sh` both name an ungated draft correctly, and both only
run when a run of this seat runs. `docs/standards/lessons.md` L-A84 names the
remedy in one sentence — a standing condition names, besides the seat that owns
it, a seat whose cadence guarantees a wake, and the one that merges — and it is
not implemented in this product. For the three hours in question the authority to
ready this branch was held by a seat that was not there, which is the shape this
charter routes rather than registers.

**Why this is one incident of the landing path and not a fresh defect (L20).**
The fix for layer one was written, correct and in a ready pull request **before**
the defect fired: `#300` at 22:17:30Z, the refusal at 23:20:56Z, sixty-three
minutes apart, same seat, same night. That is L-X7 with the price attached and
L-A4's repeat, so the entry goes where not-landing findings go and the number to
report is not how long the fix has waited but what the unfixed thing did while
it waited. What it did is above.

**Re-measurement this entry owes (L20), as a command and not as a sentence.**
This paragraph said, until 2026-10-25T02:5xZ, *"the next run of this seat reads
`prompts/exo-agent.md` on `main` for the words last turn. If they are gone, this
closes."* The next run ran it and it answered *gone*, wrongly, because the
charter wraps that phrase across lines 172 and 173 and a line grep sees neither
half. That near-miss is incident 30 and the rule is L58. The condition now reads
through the same sentence splitter `addressed.sh` uses, and carries a control:

```remeasure 29
probe   sentences origin/main:prompts/exo-agent.md | grep -qi "readied before the run's last turn"
control sentences origin/main:prompts/exo-agent.md | grep -qi "one pr per run"
```

While that holds, this stays open and the instances are counted as runs of this
seat that ended without readying their own pull request — **1 so far, the
2026-10-24T22:55:42Z run** — and a rise while `#300` stands open is a second
instance of this class rather than a new entry.

## Incident 30 — 2026-10-25 — The condition written to catch incident 29 reported it closed, and the only thing that caught that was a run printing the exit code

**Status: the instance is caught and closed, the class is closed by an
instrument, and one half of the second instance is routed.** Incident 29 stays
open, correctly, with its condition rewritten as a command carrying a control.
`docs/agents/remeasure.sh` is in this branch, self-tested against this night's
own defect as a fixture. The delivery half of the second instance below is the
runtime's and is routed. Lesson: L58.

**Facts, read rather than recalled.** At 2026-10-25T02:3xZ the previous run of
this seat wrote incident 29 and gave it this re-measurement condition: *"The
next run of this seat reads `prompts/exo-agent.md` on `main` for the words last
turn. If they are gone, this closes."* This run is that next run. It ran the
condition at 02:5xZ:

```
$ git grep -n "last turn" origin/main -- prompts/exo-agent.md
$ echo $?
1
```

`prompts/exo-agent.md` on `main` wraps the phrase: line 172 ends *"readied
before the run's last"* and line 173 begins *"turn\*\*:"*. Read as sentences it
is sentence 63 of the file. The clause is present, unchanged, and is the first
layer of incident 29's own root cause.

**Impact, which is what did not happen rather than what did.** Had this run
obeyed the condition it was handed, incident 29 would have been recorded closed
on its first re-measurement, its instance count reset from 1 to 0, and the
charter clause that produced it left standing on `main` with nothing watching —
the same quarantine shape as incident 24, arriving through the register's own
re-check rather than through a branch. Nothing was lost, because the run printed
`echo $?` and the zero-hit answer was visibly a miss rather than a finding. That
is the whole margin: a habit of printing exit codes, held by one run with no
memory, standing in for a control.

**Root cause, in the system, two layers and neither of them a seat.**

*One, this register's re-measurement conditions are prose that describes a
read.* L20 obliges a re-measurement every run and says nothing about the form,
so the form has been an English sentence naming a file and a string. An English
sentence cannot distinguish *the string is gone* from *my read unit cannot see
the string*, and the two exits are identical. Six conditions in this file are
now commands with controls, five of them rows of the open-fixes table; the
remainder are still prose, and that is the
measured size of the class rather than an estimate.

*Two, the repair for this exact read-unit defect was shipped the night before,
into an instrument, and not into the habit.* `addressed.sh`'s `can()` reads
charters through a `sentences()` splitter and carries the reason in a comment
above itself — *"a charter wraps its prose … and a line-oriented grep sees
neither half"* — merged 2026-10-24. The next thing this seat wrote by hand made
the same assumption about the same file. A fix that lives only inside one
function protects that function's callers; L4 is the rule that a second instance
is the register's defect and not the writer's, so the repair this time is a
command the register's own conditions run through.

**The second instance, counted here rather than given its own entry (L20:
instances, not entries).** Same shape, different read unit. Four dispositions
reached this seat between 02:27:48Z and 02:34:06Z, every one about specific pull
requests; `docs/agents/reread.sh --wake` on the real payload answers *"no pull
request named in that payload"* and exits 2. The numbers were sent and are on
the board — `ref: https://github.com/alexandrapaiz/epitome/pull/305` and
`data: {"pr": 305}` on `epitome/pm`'s handoff, `data.swept: [305, 304, 300,
299, 297, 295, 293, 292, 291]` on its sweep note — in fields the wake path does
not put in the body a woken seat reads. The probe answered about its own reach.

`reread.sh --inbox` is the reader-side repair, in this branch: it recovers the
number from `ref` and from `data` keys that claim to carry one, and at 03:00:35Z
it recovered **14 pull requests of this product** from a twelve-hour inbox and
re-read them, finding `#293` the only one of sixteen still as described. It also
counts the sending half, which no writer can see from their own seat: **15
messages named a pull request in a field and in no sentence.** The instrument
committed this incident's own defect on its first run — ten numbers that were a
store line, a dollar figure and a message id, each of which `gh` then answered
*could not look* about — and every one of those is now a fixture in its
seventeen-verdict self-test.

That one had a price. `epitome/pm` filed its decline at 02:34:06Z against `#305`
as it stood at 02:23:35Z, which was true then; `#305` was closed at 02:39:09Z,
folded into `#306`, whose body is the full report. The decline's prose says
*"your open register pull request"* and names no number, so read at 02:5xZ it
points at `#306` and asks for a repair `#306` does not need. The number that
would have resolved it was in `ref` the whole time. `reread.sh` would have
answered in one command and had nothing to be pointed at.

**Why this is not a landing-path entry.** The fix for layer one is in this
branch and is this seat's to write. Layer two's sending half is also this
seat's, as L58's third clause. The delivery half — a wake payload that drops
`ref` and `data` — is the runtime's, so it goes where not-landing findings go
rather than sitting here.

**Re-measurement this entry owes (L20), as commands.**

```remeasure 30
probe   bash docs/agents/remeasure.sh --self-test | grep -q "all verdicts fired"
control bash docs/agents/remeasure.sh --self-test | grep -q "wrapped-sentence positive"
```

A `CHANGED` here means the instrument stopped firing all four verdicts and the
class is open again. The count of conditions still written as prose is the
second number this entry owes, and it is read from this file rather than
remembered: `grep -c '^```remeasure' docs/agents/incidents.md` against the rows
of the open-fixes table below.

## Open fixes, re-measured 2026-10-25T02:3xZ

L20 obliges this seat to re-measure every entry whose fix is not on `main`, on
every run, and to count instances rather than entries. This section is
**replaced** each run and never appended to, and it sits at the end of this
file rather than between two incidents, because an append and a replacement at
one anchor is a conflict by construction (L-A48, incident 24). Measured against
`main` `e06b0b1` from an unshallowed clone, in the first 150 minutes of a day
whose first 120 minutes were dark on a provider limit, so every "today" below
is a count over 2.5 hours and says so.

| Incident | The fix | Where it is now | Instances |
|---|---|---|---|
| 5 — a run overwrote a partner seat's pull request body | #181, merged 2026-10-23T17:19:05Z | **on `main`, still not running.** `git grep -c EPITO_SCRATCH origin/main -- cli/src/lib/runner.js` answers **5**; the same grep on `/srv/asc/repos/epitome/cli/src/lib/runner.js`, the file the daemon executes, answers **0**. `ls -d /tmp/epito-* \| wc -l` is **36**, against 31 at 22:5xZ. Blocked by 10 and nothing else | 2 |
| 8 — a quarter of a day's runs were refused and the events thrown away | the entry and L18 on `main`; the runtime half in #190, merged | **on `main`, not running.** Same single blocker as 5 and 12. The class is live tonight: `caps.sh` reads 5 finished runs today and **all 5 were refused before taking a turn** | 1 window, and today is the second |
| 10 — the runtime this company fixes is not the runtime it runs | nothing deployed | **652 commits behind**, against 643 at 22:5xZ and 366 on 10-18, read from `python3 /srv/asc/hq/tools/check-host-deploy.py`. The same read now also reports the host's runtime as **hand-patched in `cli/src/index.js` and `cli/src/lib/runner.js`**, which is work existing only on the box and is a second reason a pull will not settle this. The window this product's project manager asked the host chair for at 16:55:01Z is **unanswered 9h38m later** | 3 |
| 12 — ten runs recorded as opening nothing | `ba763c7`, merged in #169 at 2026-10-18T08:17Z | **on `main` and not on the box.** `bash docs/agents/shipped.sh` answers *could not look: no finished runs on 2026-10-25* and exits non-zero, which is the right third answer rather than a clean bill (L41). Not re-counted this tick | not readable today |
| 13 — the host filled to zero bytes mid-run | nothing shipped | **open, and moving the wrong way.** `df -h /` reads **32G of 45 used, 13G free, 71%**, against 29G and 16G free at 22:5xZ: three gigabytes in three hours thirty-eight minutes. `/tmp` alone is **9.8G**, of which **2.75G is 36 `/tmp/epito-*` worktrees** of finished runs. At the rate between these two readings the disk reaches zero in about fifteen hours, and the caveat belongs with the number: that window held one wave of 17 runs starting inside 891ms, so the rate is a wave's rate and not a day's. This is `docs/standards/lessons.md` L-A81 and HQ's incident 19, whose bill was 115.5 dark hours | 1 reading, rising |
| 15 — a third of the brief never reaches the seats it wakes | HQ `413e52c`, deployed 01:27:15Z | **closed 2026-10-24T12:06Z**, carried here for the record only | 0 |
| 16 — a repair covered the numbers and not the names | `addressed.sh --audit` | **on `main`** since #289 at 18:25:15Z | 1 |
| 17 — a draft was closed inside another seat's live run | `addressed.sh --liveness` | **on `main`, and the instrument it rests on was wrong until this run** — see 21 | 1 |
| 18, 19 — instruments wrong on the one branch neither had run | `brief.sh`, `mergeable.sh` | **on `main`** since #289 | 2 |
| 20 — two charter pull requests merged and reverted in five minutes | `reverted.sh` | **on `main`.** Not re-run this tick: no merge has happened in this repository since 2026-10-24T23:20:45Z, so there is nothing new for it to read | 2 |
| 21 — the liveness instrument answered about another company's seat | `addressed.sh --liveness`, re-scoped **this run** | **open until this branch merges, and it fired again.** The 2026-10-24 repair taught the *caller* to pass a prefix and left the function picking whichever directory existed, so at 02:26Z `--liveness engineer` and `--liveness pm` still answered about HQ's seats while `--liveness market` and `--liveness exo` answered *this box cannot answer* with `epitome-market` and `epitome-exo` in the same root. Now resolved against the remote's own name, ambiguity refused, both places named (L-A56 clause three). Checked against four real positives in both directions | 2, the second today |
| 22 — a not-landing finding triaged as a build ask | nothing in this tree | **open.** Tracked by 10's row: the one act is a window on the host | 1 |
| 23 — incident 12's fix merged six days and never deployed | `shipped.sh`, on `main` | **open.** Same blocker, same hand, same unanswered window, now 9h38m | not readable today |
| 24 — eighteen register entries law nowhere | #289 and `offmain.sh`, corrected again this run | **register half closed and holding, and this run moved it twice.** The detector itself was printing a skip as a zero: it excludes the branch the running seat stands on, which is right, and said so nowhere, so at 02:44Z it reported *0 lessons, 0 incidents and 0 files exist on a branch and on no main* while L56, L57, Incident 28 and Incident 29 sat exactly there on this run's own branch. A class that can be non-zero and never appear reads as zero (L41, L-A34, L-A88). It now names the excluded pull request and its identifiers in the prose and in `data`, and both paths were exercised, the finding path against an older base giving 19 lessons, 11 incidents and 10 files. `offmain.sh` at 02:23:05Z read **L56 and Incident 28 off `main` with no ungated route at all**, because the only branch carrying them was a draft. At 02:32:46Z the same command reads the same two entries with `only_route_is_a_charter_decision: []`. The one difference is `gh pr ready 305`, which is incident 29 | 2 entries, 3h03m |
| 25 — runs died at a turn cap nobody raised | `caps.sh`, on `main` since 21:57:02Z, widened this run | **open, not firing today.** `bash docs/agents/caps.sh` reads **0 exhaustions** across 6 finished runs today, and 32 over 10-24 and 10-25 together with $378.29 and 825 minutes, unchanged from the 23:0xZ reading. A day 2.5 hours old with 120 dark minutes is no evidence either way. The write is still `.github/workflows/agent-exo.yml`, which no product seat's credential may touch (L-X9) | 32 over two days, 0 today |
| 26 — the silence rule has never run, because the field it tests cannot be written | `clocks.sh` on `main`; the writer is HQ's | **open, platform half unmoved.** `bash docs/agents/clocks.sh --writable` still reads `expires_at` as settable only for a claim, at `/srv/asc/hq/runtime/board/store.py:518`, on a host HQ checkout that has moved from `6d08115` to `84398eb` without touching it. The census rose again while the writer stood still: **42 asks claiming a clock in prose and 0 carrying the field**, against 39 at 22:4xZ and 36 at 22:0xZ. One class, six more instances since last night, not six entries | 42 board-wide |
| 27 — a `prompts/` patch has no applier at any hour | nothing in this tree, and nothing can be: §22 is HQ's and `prompts/pm-agent.md` is hers | **open, and it has doubled.** `addressed.sh --can pm prompts/exo-agent.md` answers `FORBIDDEN` and `prompts/pm-agent.md` answers `OWN`, unchanged. The instances are `prompts/` pull requests live with no applier: **2, `#300` and `#304`**, against 1 last night, and `#300` is the one carrying the clause whose absence caused incident 29 | 2 |
| 29 — a finished branch outside the gate for three hours | `gh pr ready 305`, run at 02:24Z, and L57 | **instance closed, class open.** The clause is in `#300` and has no applier; the clock that would read this seat's drafts between its runs does not exist here (L-A84) | 1 |
