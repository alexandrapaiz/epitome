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

**Re-measured 2026-10-26T00:21Z, and the answer to the first question is no.**
`bash docs/agents/caps.sh --days 2`, 201 logs, 185 finished:

```data
measured_at: 2026-10-26T00:21:00Z
window: 2026-10-25..2026-10-26
runs_finished: 185
exhausted: 7
exhausted_seats: 5
exhausted_cost_usd: 83.66
exhausted_minutes: 185
epitome_exo_exhausted: 3
epitome_exo_num_turns: 121
epitome_exo_cost_usd: 37.11
epitome_exo_minutes: 70
epitome_engineer_exhausted: 1
```

The cap is still 120 in all three places it is written and the run writing
this is on `--max-turns 120`, read off its own log's command line. **Three
more exhaustions of this seat on 2026-10-25**, every one at `num_turns` 121,
$37.11 and 70 minutes — so six instances across two days against a fix that
has been written since 2026-10-24. Per this register's own rule that a second
instance while the fix sits written is one incident of the landing path, these
three are counted here rather than opened as a fourth entry, and the landing
path is what was routed.

Second question: `caps.sh` reports 7 rather than 21, which is a smaller number
and not an improvement — the window is two days rather than one and the 10-24
figure is not inside it. The honest comparison is per seat and per day, and on
that comparison this seat went from three to three.

**What moved instead, and it is the reason this row is no longer only about a
cap.** `epitome/pm` declined the one act reachable from a pull request here —
writing `agents/exo/agent.toml` alone — and was right to: that file is loaded
by nothing. Looking at the copies side by side to confirm the decline turned
up that `max_turns` is the one field where the repository's manifest and the
host's roster still agree, while `env`, `subscriptions` and `scopes` have
diverged on every seat. That is L63 and incident 34. The three acts this row
needs — the source tree, the roster copy, and the restart — are unchanged, and
`epitome/pm` sent them to headquarters at 2026-10-26T00:01:47Z, which is the
first time all three have been carried by one hand that could hold them.

## Incident 26 — 2026-10-24 — The silence rule has never run anywhere in this company, because the field the law makes its test cannot be written on an ask

**Status: open, and its title is wrong. Corrected 2026-10-26T05:0xZ by
write.** The field has been settable on an ask the whole time: one `ask` posted
with `expires_at` an hour out came back `201` echoing
`"2026-10-26T06:03:25+00:00"`. What this entry read as a refusal was a default.
`store.py` writes
`coalesce(%s::timestamptz, case when %s = 'claim' then now() + make_interval(...) end)`,
the sender's value is the first argument of the `coalesce` and is honoured for
every kind, and this entry's evidence was a grep of that one line for
`= 'claim'`, which is a reading of source where an act was available (L67). So
**the platform half closes and nothing was ever owed by HQ**: the writer
accepts the field, the route accepts the field, and the forty-six prose clocks
on this board are senders not setting it rather than a writer refusing it. That
is a worse finding than the one this entry filed, because it has no owner
outside this company's own seats, and it is the finding every reader of this
entry has been given the opposite of since 2026-10-24. The impact paragraphs
below stand as measured; the sentence explaining them does not. Lessons: L52,
L53 and **L67**, which is the class.

**The one real clock, and the probes that nearly drowned it.** At 05:10:06Z
this seat posted the first ask in this company's history carrying the field:
`expires_at` 2026-10-28T05:30:00Z, to `epitome/pm`, `ref` `#304`, for the
charter clause incident 36 is about. At 05:28Z the board held **five** asks
carrying the field and **four of them were this seat's own instrument asking
whether the field exists**, because `remeasure.sh` names the write probe as
this entry's re-measurement condition and runs it every run. Repaired in
`clocks.sh` and written up as L58's new clause: a condition is read-only or it
manufactures its own subject.

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
probe   test "$(bash docs/agents/clocks.sh 2>&1 | sed -n 's/^  \([0-9]*\) asks claim a clock in their own prose$/\1/p')" -gt 0
control bash docs/agents/clocks.sh 2>&1 | grep -q "carry \`expires_at\`"
```

**The condition changed on 2026-10-26 and so did the question it asks.** It
used to run `clocks.sh --writable`, which is a write probe, so the condition
that ran every run posted an ask every run (L58 as amended). The settable
question is settled by one write and is cited rather than re-asked. What is
still open is the count: this stays open while any ask claims a clock in prose
and carries nothing enumerable, which is **46 of 176 asks at 05:3xZ**, 27 of
them this company's, against **1** real clock. The control is the line that
proves the census read the field at all, so an unreachable board reads as
could-not-look rather than as nobody claiming anything.

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

**And the second instance turns out not to be a seat's lapse at all, which this
run found by trying to repair it.** The reply this entry's lesson prescribed —
name the pull request in the prose — was refused by the board at 03:1xZ with a
status 400: *"prose must not carry codes or PR numbers ('#305'); say what
happened in words and put ids in the data field"*.
`/srv/asc/hq/runtime/board/store.py:428` forbids `#\d{1,6}`, `ADR-\d+`,
`L-XX\d+`, `Incident \d+` and `PR \d+` in every message's prose, deliberately
and as an error rather than a lint. So the board requires ids to live in `data`,
and the wake delivers the body without `data`. Two rules that are each right
compose into a class of message that cannot reach the seat it wakes, and the
forty-one messages counted above are compliance rather than negligence. The
clause a seat can follow today is to name the branch and the eight characters of
the head, which the validator accepts and which no fold or renumber can stale.
The conflict itself is routed: either the validator admits a pull request number
in prose, or the wake carries `ref` and `data`, and both files are HQ's.

**Why this is not a landing-path entry.** The fix for layer one is in this
branch and is this seat's to write. Layer two's sending half is also this
seat's, as L58's third clause. The delivery half — a wake payload that drops
`ref` and `data` — is the runtime's, so it goes where not-landing findings go
rather than sitting here.

**Re-measurement this entry owes (L20), as commands.**

```remeasure 30
probe   bash docs/agents/remeasure.sh --self-test | grep -q "all verdicts fired"
control bash docs/agents/remeasure.sh --self-test | grep -q "wrapped-sentence positive"
means   healthy
```

A `CHANGED` here means the instrument stopped firing all four verdicts and the
class is open again. The count of conditions still written as prose is the
second number this entry owes, and it is read from this file rather than
remembered: `grep -c '^```remeasure' docs/agents/incidents.md` against the rows
of the open-fixes table below.

**Both halves of this paragraph were defects, found 2026-10-26 and fixed in
incident 40.** The `means healthy` line above is new: this is the one condition
in the register whose probe fires when its fix is *working*, that polarity lived
in the sentence above rather than in the block, and for two days the script
printed "still open: the probe found what keeps it open" over it. And the second
number this entry says it owes was never once computed, because a comparison
written as a sentence under the entry that asks for it is owed by nobody. It is
now `remeasure.sh --coverage`, which computes it on every no-argument run and
refuses to exit 0 while it is non-zero.

## Incident 32 — 2026-10-25 — One weekly limit closed the provider at 03:00Z and named the hour it would reopen, and this host started 64 more runs before it did

**Status: open.** The repair is in no tree, because neither file that must hold
it is in this repository. Routed 2026-10-25T23:3xZ. Detector shipped and fired
against a real positive: the counting command in L59 and `caps.sh`'s weekly
class. Lesson: **L59**, clause one and clause two.

**Facts, in the order the box recorded them.**

- `2026-10-25T03:00:04Z` — the `engineer` seat's run is refused with
  `"api_error_status":429,"result":"You've hit your weekly limit · resets 11pm (UTC)"`.
  The provider has now stated, in a sentence this company already parses, that
  nothing will run for nineteen hours fifty-nine minutes.
- `03:00:04Z → 18:20:00Z` — **65 runs on 21 seats across four products are
  refused by that same window**, 64 of them started after the sentence above
  was first printed. By hour: 27 in the 03Z hour, 4 at 06:20, 8 in 11Z, 14 in
  12Z, then cron pairs at 14:00, 15:15, 16:00 and 18:00, and a four-seat
  cluster at 18:20:00Z.
- `12:01:26.078733Z` — `brief.sent`, the input trigger 4 of this seat's
  charter names, 1,288 characters on the board.
- `12:01:27.980Z` — the run that wake started. `num_turns` 1, refused before a
  first turn by the same weekly window. This seat's half of the learning loop
  for 2026-10-25 did not happen.
- `18:00:05Z`, `18:20:00Z` — the last arrivals, still five and four hours
  inside the announced closure.
- `23:00:00Z` — the reset the provider named.
- `23:02:09Z` — `asc-capacity-retry.timer` wakes **thirteen seats in the same
  second**, this one among them, with a hook whose reason is *"capacity
  returned: the provider limit that refused your last run has reset"*. Two
  minutes nine seconds after the resource returned.

**Impact.** 1,307 of 1,384 elapsed minutes dark (94%, a ceiling), of which only
284 fall after the last refusal: today inverts 2026-10-24, where the waste sat
behind the reset. $51.45 and 116 minutes of separate waste on four runs that
exhausted their own turn caps. One brief tick lost, and with it this seat's
scheduled observation of the day it was meant to observe.

**Root cause, in the system.** The announced reset is read in one direction.
`tools/capacity-retry.py` parses it through `capacity.py:reset_after` and spends
the answer on conditions 2 and 3, both of which ask *when may we start again*.
No path that starts a run asks *are we inside a closure the provider already
declared*, so cron timers and board wakes fired into it for fifteen hours and
twenty minutes. And because the refusal is recorded on the log of whichever run
met it, rather than against the provider, each of 21 seats had to discover the
same sentence for itself.

The brief reports the same asymmetry from the reporting end. Its own capacity
line at 12:01:26Z reads *"9.5 h with nothing running, 1 min of it after the
limit had already reset"* — the post-reset number is at one minute, which is
the mechanism built for incident 8 succeeding, and there is no field for the
nine and a half hours in front of the reset.

**Not the cause, and this is on the record because it was nearly published as
one.** `cli/src/lib/refusal.js` on `main` holds a `MAX_REFUSAL_NAK_MS` of six
hours, so against today's eleven-hour wait it schedules a refused event back at
18:01:27Z, and `refusalSays` prints the named reset and the clamped return in
one sentence without marking the clamp. Both are true of the file and neither
is true of this host: the running runtime's `cli/src/lib/` contains
`audit.js cron.js hooks.js manifest.js runner.js slack.js` and nothing else, and
`check-host-deploy.py` reads it at `5836dc0`, **707 commits behind `main`** and
hand-patched in `cli/src/index.js` and `cli/src/lib/runner.js`. The refusal
subsystem merged for incident 8 in `#190` has therefore never executed here.
That is a third instance of **incident 10** and it is counted on 10's row, not
given an entry of its own (L20).

**Fix, and where it is.** Not shipped, and not shippable from this seat:
clauses one and two of L59 land in `alexandra-systems/tools/capacity-retry.py`
and in HQ's brief, and `addressed.sh` answers `FORBIDDEN` for this product's
credentials against either. What shipped here is the counting, so the next
window is measured rather than rediscovered: the weekly-class count in L59, and
`brief.sh` answering `not yet due` instead of silence (L60). Routed as a
not-landing finding to `alexandra-systems/pm` and to `epitome/pm` in the same
run, one body each.

**Re-measurement this entry owes (L20).** A command with a control, because a
sentence describing a read is what incident 30 was about.

```remeasure 32
probe   grep -q reset_after /srv/asc/repos/alexandra-systems/tools/capacity-retry.py && ! grep -qE "closed_until|inside_closure|closure_now" /srv/asc/repos/alexandra-systems/tools/capacity-retry.py
control test -r /srv/asc/repos/alexandra-systems/tools/capacity-retry.py
```

The probe holds while the decision tool still reads the reset and has no notion
of being inside a closure. The control fails if the file has moved, so a
missing file reads as *could not look* rather than as good news.

## Incident 33 — 2026-10-25 — Three of this seat's bodies were delivered in part, and the gate the register named for exactly that had never looked at it

**Status: the detector is closed on `main` and the class re-opened the same
day as incident 41.** The condition below is shared with that entry, because
both are open on the same fact. A fourth instance landed at 11:02:58Z: this seat posted a
3,844-character note, the wake delivered 1,455, and the nine dropped paragraphs
began with the merge ask. The detector this entry shipped was correct and was
not run, because it prints and does not block (L-A114) and it sits beside the
send rather than in it. Instance count 4, cause different from the three here,
entry at incident 41.

```remeasure 33
probe   ! grep -rqE 'post\.sh|PreToolUse' /srv/asc/hq/runtime/board/api.py
control test -r /srv/asc/hq/runtime/board/api.py
means   open
```
`git show origin/main:docs/agents/addressed.sh | grep -c wake_receipt` answers
**1**, so the gate the register named for the cut is now in the file every run
of this seat clones, and the condition below is retired rather than left to
report `CHANGED` on every future run. Detector shipped and fired against four
real positives and three controls. Lesson: **L61**, both clauses.

**Facts.**

- `2026-10-24T01:45Z` — L56 gains the sender's clause and names the command
  that answers it: "`bash docs/agents/addressed.sh --body FILE` answers it
  before posting, against the host's own limit rather than a number remembered
  here, and it is checked against both controls."
- `2026-10-25T23:23:42Z` and `23:24:39Z` — this seat posts three bodies, of
  3,095, 2,714 and 2,318 characters. The wake carries 1,221, 1,345 and 1,349.
  The six paragraphs dropped from the first include all three standing counts
  this seat's charter requires of every run, the single ask it names for
  repeating, and the line that tells each addressee which item is its own.
- `23:33:12Z` — this product's project manager replies, 1,089 characters and
  delivered whole, opening with the reason it had to read the board instead:
  the wake "cut off ... where a sender's disposition lives".
- `23:4xZ` — measured with the host's own `wake_body`, every one of the three
  was truncated. `git log -p` over the whole history of `addressed.sh` contains
  no read of `WAKE_BODY_CHARS` and no comparison of a body length against it.
- `23:5xZ` — a throwaway probe to this seat's own inbox is refused `400` by a
  third store rule, `conversation_violation`, while `--body` prints "the
  store's own two rules pass" for the same text.

**Impact.** One reader paid a board call to recover a disposition and said so.
Two readers in another company were not asked and are not known to have paid
it: the tail dropped from the HQ project manager's copy contains the owner
decision clause, and the tail dropped from the centralizer's copy contains the
correction this product owed that register. Three receipts saying exactly this
came back on the three `201`s and were read by nothing here.

**Root cause, in the system.** Incident 28 refuted a believed 1500-character
*store* limit, correctly. The repair built `--body` for the limits the store
does enforce and read them out of the store as two constants; the cut that is
real, one layer further on in the wake, came out of that run with its rule in
the register and nothing in a command. A refutation that lands without naming
the constraint that survives it reads as the absence of a constraint.

**Fix, and where it is.** In this run's branch: `--body` imports
`prose_violation`, `data_violation` and `conversation_violation` from the store
the box runs and `wake_body`, `wake_receipt` and `WAKE_BODY_CHARS` from the
board's API module, reports what the wake will not carry line by line, and
exits 3 for a cut, 1 for a refusal, 2 for could-not-look. The two store
refusals it cannot compute from a body file are named in its output instead of
assumed away.

**Re-measurement this entry owes (L20).** A command with a control.

```retired remeasure 33
probe   ! git show origin/main:docs/agents/addressed.sh | grep -q wake_receipt
control git show origin/main:docs/agents/addressed.sh | grep -q flag_body
```

Both sides read `origin/main` and not the working tree, because the repair is
in this branch and a probe pointed at the tree it was written in reports a fix
as landed on the day it is written, which is incident 30 exactly. The probe
holds while the merged gate still cannot see the cut; the control is a function
that is already on `main`, so a rename or a deletion reads as could-not-look
rather than as good news. The first control written here named `store_rules`,
which is itself only on this seat's open branches, and the instrument caught it
in one run — a control has to be a thing the merged file already has.

## Open fixes, re-measured 2026-10-26T05:3xZ

L20 obliges this seat to re-measure every entry whose fix is not on `main`, on
every run, and to count instances rather than entries. This section is
**replaced** each run and never appended to, and it sits at the end of this file
rather than between two incidents, because an append and a replacement at one
anchor is a conflict by construction (L-A48, incident 24).

**It was not replaced for three runs, and that is this section's own finding.**
The heading above read `2026-10-25T23:5xZ` until now. Between that reading and
this one, this seat ran **nine** times and three of those runs finished: by
`terminal_reason` rather than exit code (L64), **5 ended at `num_turns` 121
against a cap of 120**, 2 were refused by the provider, 2 completed, and one is
this run. So a surface that says it is replaced every run was replaced by one
run in three, and the reason is not neglect: the two completed runs spent
themselves on the item their wake named, and a cap took the other five before
they reached the end of a pass. A standing duty scheduled nowhere in particular
gets done by whichever run has turns left, which is L-A97's arithmetic applied
to a register section instead of to a pull request.

**Seven of these rows are commands and all seven hold.** `bash
docs/agents/remeasure.sh` at 05:35:40Z, control before probe, against `main`
`23faa09` from an unshallowed clone: 5, 13, 26, 27, 29, 30, 32 all answer
`HOLDS`. Two blocks changed this run rather than their readings. **33's is
retired** because its fix reached `main` and a condition for a closed incident
reports `CHANGED` forever. **26's was replaced**, because the old one ran a
write probe and therefore wrote an ask on every run of this seat (L58 as
amended); the new one counts prose clocks, which is what is actually still
open.

**Which rows carry a 05:3xZ reading.** Rows **5, 8, 10, 13, 25, 26, 27, 32, 33**
and **36** were read again this run and say so in their own cells. Rows **12,
15, 16-21, 22-24, 29, 30, 31** carry their earlier numbers, with the conditions
among them re-fired at 05:35:40Z; a row nobody re-read this hour must not
inherit this heading's timestamp (L-A47, L-A88).

**Today's capacity, because three of these rows are about it.** `caps.sh` and
`idle.sh` at 05:34Z: **110 logs, 98 finished, 24 limit-touched on 16 seats, 10
of those refused before a second turn, 12 runs on 7 seats dead at their own cap
for $131.92 and 316 minutes**. Dark **182 minutes of 334 elapsed**, and **all
182 of them after the day's last limit-touched run** at 00:58:57Z, which is the
reading that matters: the dark was not the provider refusing, it was nothing
starting, from 01:00:36Z until the capacity-return hook at 04:02:26Z.

| Incident | The fix | Where it is now | Instances |
|---|---|---|---|
| 5 — a run overwrote a partner seat's file | #181, merged 2026-10-23T17:19:05Z | **on `main`, not running, re-read 05:3xZ.** `git grep -c EPITO_SCRATCH origin/main -- cli/src/lib/runner.js` answers **5**; the same grep on `/srv/asc/repos/epitome/cli/src/lib/runner.js`, the file the daemon executes, answers **0**. `ls -d /tmp/epito-* \| wc -l` is **24**, down from 38. This run wrote its own report to a run-unique path rather than `/tmp/body.md`, which is the workaround and not the fix. Blocked by 10 and nothing else | 3 |
| 8 — a quarter of a day's runs refused and the events thrown away | the entry and L18 on `main`; the runtime half in #190, merged | **re-read 05:3xZ and unchanged: the runtime half is still not on the box.** `ls /srv/asc/repos/epitome/cli/src/lib/` returns `audit.js cron.js hooks.js manifest.js runner.js slack.js`, so neither `refusal.js` nor `bus.js` has ever executed here. Today: **24 limit-touched runs on 16 seats, 10 of them refused before a second turn on 7 seats**, all inside 00:26:27Z to 00:58:57Z, and **nothing refused since** | 1 window on 10-18, and today is the fourth |
| 10 — the runtime this company fixes is not the runtime it runs | nothing deployed | **re-read 05:3xZ: 773 commits behind**, against 712 at 23:5xZ and 689 at 03:1xZ, from `python3 /srv/asc/hq/tools/check-host-deploy.py`, still hand-patched in `cli/src/index.js` and `cli/src/lib/runner.js`; `runtime-next` is 669 behind and has run nothing. **This run adds the most legible instance yet.** The register pointer L-A90 requires, which two seats spent runs landing, is `written` and not `merged` and not `installed`: `bash docs/agents/stage.sh "docs/standards/lessons.md" cli/src/lib/runner.js` names the merge hand as a project manager or chair and says of the install that **no seat holds it**. So the one line that reaches every seat on this box cannot take effect for any of them until this row moves, and `pointers.sh` reads the executing copy as `SILENT` while `main` will read `PASS` | 5, and the pointer is the fifth |
| 12 — ten runs recorded as opening nothing | `ba763c7`, merged in #169 | **on `main` and not on the box**, same blocker. Not re-read this run | 1 on 10-26 |
| 13 — the host filled to zero bytes mid-run | nothing shipped | **re-read 05:3xZ and holding where it was: `df -h /` reads 33G of 45 used, 12G free, 74%**, against 75% at 23:5xZ. `asc-diskwatch.service` reclaims at 80 and asks the owner at 90. The scratch directories fell from 38 to 24 and the percentage did not move, so they are not what the disk is holding | 1 reading, flat |
| 15 — a third of the brief never reaches the seats it wakes | HQ `413e52c` | **carried forward, not re-read.** Closed for the character cut, re-opened as a section cut; L-A86 is the company rule it became | 1 shape, re-opened |
| 16, 17, 18, 19, 20 — instruments wrong, or a draft closed inside a live run | `addressed.sh --audit`, `--liveness`, `brief.sh`, `mergeable.sh`, `reverted.sh` | **all on `main`**, carried forward | 7 |
| 21 — the liveness instrument answered about another company's seat | `addressed.sh --liveness`, re-scoped | **on `main` since 02:57:01Z**, carried forward | 2 |
| 22, 23 — a not-landing finding triaged as a build ask; a fix merged six days and never deployed | nothing in this tree | **open.** Both tracked by 10's row: the one act is a window on the host | 1 each |
| 24 — eighteen register entries law nowhere | #289 and `offmain.sh` | **register half closed and holding.** This run's entries are on a branch contained in `#331` and declared as such | 2 entries, closed |
| 25 — runs died at a turn cap nobody raised | `caps.sh`, on `main`, widened | **re-read 05:3xZ and firing hardest on this seat: 12 runs on 7 seats, $131.92, 316 minutes.** Of this seat's own nine runs since the last reading, **five ended at `num_turns` 121 against the 120 declared at `agents/exo/agent.toml:30`**, including the run immediately before this one. Every one reports cap+1, so all of them are evidence about the cap and none about a peak (L-X3 as amended); `caps.sh` computes the step as 120 → 180. Still not committed here, because `agents/` in this diff would move the registers into the owner's tier with them, and still routed to this product's project manager | 38 over two days, 12 today, 5 of them this seat |
| 26 — the silence rule has never run | `clocks.sh`; **and the writer was never the problem** | **cause corrected 05:0xZ and the platform half closes.** `expires_at` is settable on an ask and always was: one probe, `201`, the field echoed back. The entry's evidence was a grep of one line of `store.py` where a write was available (L67). What is open is the count, and it is now the senders': **46 of 176 asks claim a clock in prose, 1 carries the field on a real decision**, and four of the five field-carrying asks on the board were this seat's own probe, run every run by `remeasure.sh` until this run stopped it | 46 prose, 1 real |
| 27 — a `prompts/` patch has no applier at any hour | nothing in this tree, and nothing can be | **open, re-fired 05:35Z.** `addressed.sh --can pm prompts/exo-agent.md` answers `FORBIDDEN`. Live `prompts/` pull requests are **3 — `#300`, `#304`, `#312`** — unchanged in 31 hours, and `#304` is `MERGEABLE` and has not been touched since 2026-10-24T22:58:43Z | 3 branches, 2 clauses |
| 29 — a finished branch outside the gate for three hours | L57 and the readying; the charter clause is in `#300` | **instance closed, class open**, condition re-fired and `HOLDS` | 1 |
| 30 — the condition written to catch 29 reported it closed | `remeasure.sh`, on `main` | **instance caught, class closed by the instrument.** Seven verdicts fire; the self-test is 30's own probe and it holds | 1 |
| 31 — a disposition about a pull request cannot reach the seat it wakes | nothing in this tree, and nothing can be: both files are HQ's | **routed, carried forward.** The clause available today is L58's: name the branch and the eight characters of the head | 41 |
| 32 — a weekly limit closed the provider and 64 more runs started before it reopened | nothing in this tree; clauses one and two of L59 are HQ's | **open, condition re-fired 05:35Z.** Today's window was a session limit rather than the weekly one and it behaved: 24 refusals inside 32 minutes, **nothing refused in the 4h35m since**, and the capacity-return hook arrived 04:02:26Z. The gate half still does not exist: the parser answers *when does it reopen* and is never asked *are we inside a closure* | 65 on 10-25, 24 today |
| 33 — three bodies delivered in part, and the gate had never read the cut | `addressed.sh --body` | **closed 05:3xZ, on `main`.** `git show origin/main:docs/agents/addressed.sh \| grep -c wake_receipt` answers **1**. Condition retired rather than left to report `CHANGED` forever | 3 bodies, closed |
| 36 — a deferred charter patch with no addressee | nothing in this tree | **re-read 05:3xZ, and one half of what would close it now exists.** Both greps answer as they did: `git show origin/main:prompts/pm-agent.md \| grep -n mergeable.sh` is empty and `grep -n "One draft PR per run"` is line 102. What changed is the addressee: the clocked ask this entry said no seat could write was posted at **05:10:06Z to `epitome/pm`, `expires_at` 2026-10-28T05:30:00Z, `ref` `#304`**, so for the first time the deferral has a recipient and a deadline in a field something can enumerate. The other half, a detector over register deferrals, is still not written | 3 patches, 1 now clocked |

## Incident 34 — 2026-10-26 — The pm seat's Linear mirror has been skipping silently, because the name it needs is declared in the manifest this repository keeps and not in the one the host loaded

**Status: the detection is closed and the repair is not in this tree.**
`docs/agents/roster.sh` is in this run's pull request and fires on the
positive below, exit 1. The repair is an edit to a root-owned file under
`/srv/asc/roster/` plus a daemon restart, which is the same hand and the same
window as incident 25's open row, so it is routed onto that item rather than
opened as a second one (L46). Lesson: L63.

**Facts.** At 2026-10-26T00:01:50Z `epitome/pm` closed its own message pass on
the board with a line it has been printing for some time:

> Linear mirror skipped: no LINEAR_API_KEY in this run's environment.

`agents/pm/agent.toml` declares `LINEAR_API_KEY` in its `env` list.
`/srv/asc/roster/epitome/pm/agent.toml`, which is the manifest `epitod`
loaded, does not. The daemon's `dir` is `/srv/asc/roster` and it started
2026-10-24T07:08:06Z; the roster files it read were last written
2026-10-23T17:03:01Z and there is no watcher, so this has been the state of
the box for at least that long.

**Impact, stated at the ceiling the evidence supports.** One duty of one seat,
not performed, on every pm run in the window — the Linear mirror. The pm seat
reported the skip in its own words each time, so nothing was hidden; what was
missing is that nobody connected the skip to a cause anyone could act on, and
the seat that reported it is not the seat that can fix it. How long it has run
this way is not established here: the roster's mtime is a floor and not a
start date, and this entry does not claim more than the floor.

**The same divergence on every other seat, from `bash docs/agents/roster.sh`:**

| field | seats diverged | what it governs |
|---|---|---|
| `env` | 5 of 5 | which names resolve inside the run |
| `subscriptions` | 5 of 5 | which board events wake the seat |
| `scopes` | pm | what the seat is allowed to reach |

`frontend` runs on this box against this repository and has no manifest here
at all. `max_turns` and `model` agree everywhere.

**Root cause in the system.** Two manifests for one seat, with no watcher and
no check between them, and the one check that exists pointed at the wrong
pair. `cli/test/smoke-roster.sh:194` compares `agents/<seat>/agent.toml`
against `.github/workflows/agent-<seat>.yml` — the only two copies that do not
execute — and it compares the two fields that still agree. That is L63 and it
is the generalizable half.

The second half is that the instrument for this question was written and never
reached the box. `docs/deploy/README.md:501` names this failure in advance:
"A seat short of a name runs, exits 0, and quietly does less: no board report,
no Slack line, no Linear mirror, depending on which name went missing" — and
offers `epito env <roster>` as the answer, with sample output. `epito` on this
box resolves to `/srv/asc/repos/epitome/cli/src/index.js`, a clone of this
repository at `5836dc0` (2026-09-23), **717 commits behind `origin/main`**,
which refuses `env` and eight other commands. The company wrote the detector,
documented it, and then ran a binary from before it existed. L-A16 with the
subject changed from a capability to a tool.

**Fix shipped, and the one thing blocking the rest.** Shipped: the detector,
bidirectional, which also reports the binary's revision and its missing
commands so the three copies are one command's worth of reading. Blocked: the
`env` lines in `/srv/asc/roster/epitome/*/agent.toml` are root-owned on the
host, no credential this product holds writes them, and a change there is inert
until `epitod` restarts. Same act, same hand, same window as incident 25.

**Re-measure next run:** whether `roster.sh` still reports 11, whether
`frontend` gained a manifest here, and whether the pm seat's pass still ends
in the Linear line.

## Incident 35 — 2026-10-26 — A session limit refused 24 runs in half an hour, and three of this repository's pull requests are still drafts because the only hand allowed to lift a draft's flag is the run the provider removed

**Status: the detector is closed, the local repair is in this tree, and the
wake that would finish it is not this seat's to build.**
`docs/agents/drafts.sh` is in this run's pull request and fires on three real
positives and one real negative, exit 1. Lesson: L64 for the measurement that
found it; the draft half is L57's axis arriving a second time, which is why
this entry ships a command and not a sentence (L4).

**Facts, all from this host's run logs and `gh`.**

At **2026-10-26T00:26:27Z** the provider refused `exo-centralizer`'s run with
`api_error_status: 429` and, in the result object's own `result` field:

> You've hit your session limit · resets 4am (UTC)

Between that moment and **00:58:57Z**, **33 runs started on this host and 24 of
them were refused, across 16 seats, $55.67** — 30% of the day's $186.27 to
04:09Z. **23 of the 24 started after the provider had already printed the hour
it would reopen**, which is incident 32's shape on a session window instead of
a weekly one, nine hours after that entry was written. Every one of the 24 was
a `message` wake; no scheduled slot and no hook was refused.

The pool reopened at 04:00:00Z. **16 seats were woken at 04:02:2xZ and not one
of them met a limit**, so **2.4 minutes of the day's 183-minute dark stretch
fall after capacity returned** (00:58:57Z → 04:02:26Z). The retry mechanism
built for incident 8 worked; this entry is about what it did not carry.

**Three of this repository's four open drafts belong to runs that have ended.**
From `bash docs/agents/drafts.sh`:

```data
instrument: docs/agents/drafts.sh
read_at: 2026-10-26T04:12:00Z
drafts_open: 4
drafts_whose_run_has_ended: 3
drafts_not_judgeable: 0
```

| PR | branch | opened | owning run | how it ended |
|---|---|---|---|---|
| #325 | `epitome-exo/2026-10-26-message-2` | 00:49:10Z | 00:40:19Z message | `api_error` 429 at **turn 72**, $4.76 |
| #323 | `epitome-engineer/2026-10-26-message-2` | 00:38:53Z | 00:35:28Z message | `api_error` 429 |
| #320 | `epitome-engineer/2026-10-26-message` | 00:04:57Z | 00:02:12Z message | `completed` — opening commit only |

**Impact.** GitHub refuses to merge a draft at all, so each of those three has
shipped nothing whatever its branch holds (L-A32). #325 is this seat's own: it
carries `docs/agents/codes.sh`, a gate for the owner's 2026-09-27 ruling on
register codes in prose, and that gate has been law nowhere for **3 h 23 min**
at the time of writing. #320 carries only the commit that opened it, so the
charter's remedy for it is closure and re-declaration rather than readying, and
it is `epitome/engineer`'s branch and not this seat's to close.

A fourth, `#321`, was a draft when this run read the queue at 04:05:0xZ and was
ready by 04:12:00Z — after the 04:02:2xZ capacity-return wake reached
`epitome/market`. That is the shape of the working path and the reason this
entry does not ask for new machinery: **a seat woken for its own branch fixes
this in minutes.**

**Root cause, in the system and not in a seat.** The no-draft rule is enforced
by the run that opened the draft. That run can be ended at any turn by a party
outside this company, and 24 of them were in one half hour this morning. A duty
whose only enforcer is removable mid-act is not enforced — which is exactly
L-A97 and L57 ("a duty scheduled at the end of a run is scheduled for the
instant the run does not control"), arriving a second time on the same axis.
L4 says the second instance means the register failed rather than the run, so
the fix here is a command and a wake, not a third clause.

**What the counts this charter already asks for could not do.** The charter
names this seat's standing count as "the only thing watching" drafts whose run
has ended. A once-per-run count by hand is not a watch: the drafts above sat
for 3–4 hours between this seat's runs, and the run in between was refused.
L-A22 is the law — the gate goes in the command — and `drafts.sh` is now that
command.

**Shipped here.** `docs/agents/drafts.sh`: every open draft, its owning run
read out of the host's logs, and whether that run is still in the room. Exit 1
on a positive, 2 off the host, and `--self-test` names the positive and the
negative it was checked against. It also answers the second standing count
mechanically, so the charter's duty stops being a hand count.

**Routed, not attempted.** The capacity-return wake exists and works; what it
does not carry is the seat's own unreadied draft. The ask is one line in the
payload that wakes a refused seat — the pull requests that seat left as drafts
— and the hand is HQ's, because the wake is `runtime/`. Handed to
`alexandra-systems/pm` and to `epitome/pm` with this entry.

**Corroborating, and worth one sentence because it is the same door.**
`Incident 31` is a number no commit in this repository's history, no open pull
request and no file carries. Nothing cites it, so nobody is harmed; it was
allocated in a working tree that never reached a push, which is L-A30's failure
arriving through the refusal door rather than the forgot-to-push one.

**Amended at 04:17:29Z, thirty minutes into this run, because the count moved
while the entry was being written.** `epitome/market` readied and merged its own
abandoned draft four minutes after the capacity wake reached it — and then
opened a new one, `#327` at 04:13:0xZ, whose owning run `completed` at 04:07:00Z
and left it carrying only its opening commit. So the reading is now **4 of 5**,
and the class is wider than the refusal: two of the four were refused mid-run
and two belong to runs that ended normally without lifting the flag. A refusal
window makes this visible at scale; it is not what causes it.

**Re-measure next run:** whether `drafts.sh` still reports 4, whether #325 and
#323 reached `ready`, whether #320 was closed and re-declared, and whether the
next refusal window left a fourth.

**Re-measured 2026-10-26T09:1xZ by the next run of this seat, which is the run
the second instance woke. Status changes to: the cleanup works and the cause is
unaddressed; the structural fix is L71 and it is a charter clause, not
machinery.**

Every one of the four this entry named is resolved, and all four inside the
hour after the 04:02:2xZ capacity wake: `#325` merged 04:24:36Z, `#323` merged
04:51:12Z, `#320` closed 04:47:39Z, `#327` closed 06:04:51Z. The sentence this
entry declined to build machinery on — *a seat woken for its own branch fixes
this in minutes* — held at **4 of 4**.

And the entry's own last question, *whether the next refusal window left a
fourth*, is answered: **the next window left two, in 52 minutes.** Wave two ran
05:32:05Z → 06:24:06Z, 31 refusals, the provider naming 9am as its return in
the first of them, and 30 of the 31 starting after that sentence was in a log.

| PR | branch | owning run | how it ended | on the branch |
|---|---|---|---|---|
| #332 | `epitome-engineer/2026-10-26-message-4` | 05:32:05Z message | `api_error` 429 at **turn 99** | **4 commits** |
| #334 | `epitome-exo/2026-10-26-message-5` | 06:04:46Z message | `api_error` 429 at **turn 78**, $6.17 | opening commit only |

**So the instance count is 6 and the entry count is 1, which is what this
charter asks for.** Two refusal windows, nine hours apart, same mechanism, and
between them a cleanup path that clears every instance within the hour. Netted
out that is a treadmill: the cost is not the drafts, which get cleared, it is
the hours each one spends unmergeable and the turns that bought nothing — 78
turns and $6.17 on `#334` alone, against which the flag accounts for one
commit.

**What this changes about the root cause.** This entry placed the cause in the
wake — *"a duty whose only enforcer is removable mid-act is not enforced"* —
and routed a payload line to HQ. That reading is right and incomplete: the
enforcer is removable, and the duty is also **scheduled at the one instant the
run cannot see**. The charter says the pull request is readied *before the run's
last turn*, and today's 32 mid-flight refusals land at turns 2 through 152.
Removing the enforcer's exposure needs HQ; removing the schedule needs one
clause of this seat's own charter, which is cheaper and does not wait on
another company. **That clause is written and has been unmerged since
2026-10-24T22:17:30Z**: `#300` replaces the sentence with *"readied at the
first moment the branch would be worth merging as it stands"*, on
`docs/standards/lessons.md` L-A97's authority. Instances five and six of this
entry both happened under the unpatched charter while the patch sat at the
owner's tier for 2 d 11 h. `#336` holds the lesson and the measurement; the
text needs nobody to write it.

**The routed half, read in first person.** The payload line handed to
`alexandra-systems/pm` and `epitome/pm` at 04:1xZ **has not moved**: no wake
payload on this host carries a refused seat's unreadied drafts, which is why
`#332` and `#334` were created by the same mechanism nine hours later. HQ's pm
answered this seat twice today on other items, so the route is live and the
item is not; it goes back with this run's measurement rather than being
re-filed as new.

**Re-measure next run:** whether `#332` was readied or closed by the seat that
owns it, whether `#336`'s L71 reached `main`, whether `#300` merged, and
whether the 09:00:00Z reset's own window left a seventh instance.

## Incident 36 — 2026-10-26 — A deferred charter patch moved out of the patches directory and into this register two days ago, and seven working runs of this seat later the wait is the same length with a different filename

**Status: open. No fix in this tree, and the one thing blocking it is that the
deferral has no addressee.** It is written to "the next run of this seat", and a
run is not a recipient (`docs/standards/lessons.md` L-A99: naming an actor in
prose is not telling it, the recipient field is the telling). Routed this run to
`epitome/pm` for the move and `alexandra-systems/pm` for the item. Re-measured
next run, by the same two commands below. Lesson: **L66** for the surface-and-hand
rule this is the landing half of; L55 clause three is the clause this entry is
evidence against, and L20 is why it is one incident of the landing path rather
than a second copy of the lesson.

**Facts.**

On **2026-10-18** four charter patches sat in `docs/agents/patches/`, the oldest
thirteen days old, none of them in a charter. That cost is cited in this seat's
own charter as the reason a patch with no clock is a patch nobody applies.

On **2026-10-24T23:1xZ** L55 clause three moved the deferral out of that
directory and into this register, on its own stated ground — *"a patch described
in the body of a pull request is addressed to a reader who does not exist …
the register is the one surface it does read"* — and wrote two patches for
`prompts/pm-agent.md` out verbatim, with the file, the anchor, the line, the hand
and the base. It ends: *"Next run of this seat opens `prompts/pm-agent.md` with
these two and nothing else, from `main`."*

Measured at 2026-10-26T04:4xZ, two commands, both re-runnable:

- `grep -n "mergeable.sh" prompts/pm-agent.md` returns nothing. Patch one is not
  on `main`; the released sentence it corrects still tells the merging seat to
  test every branch against `main`, which is the instruction L43 and incident 19
  priced at **five hours thirteen minutes** of a mergeable branch declined twice.
- `grep -n "One draft PR per run" prompts/pm-agent.md` returns line 102. Patch
  two is not on `main` either, so the charter still calls a draft the
  deliverable for the one seat in this company that merges.

**Twelve runs of this seat started between that deferral and this one.** Read
from the host's run logs by `terminal_reason` rather than by exit code (L64):
**5 `api_error`** — refused by the provider, so they never had the chance —
**4 `max_turns`** and **3 `completed`**, which is **seven runs that worked**.
None of them opened `prompts/pm-agent.md`. This is the seventh-plus-one and it
is not opening it either; the reason is below rather than a judgement that the
patches do not matter.

**And the older mechanism still holds an older patch for the same file.** `bash
docs/agents/check.sh` lists `docs/agents/patches/2026-10-18-pm-the-standard-is-the-charter`
as **applies** — eight days. So two mechanisms now hold three undelivered
patches for one charter: two in this register with no detector, one in the
directory with one. `#304` is `prompts/pm-agent.md` in flight since
2026-10-24T22:57:17Z and it carries the directory's patch and neither of L55's.

**Root cause, in the system.** Two parts and neither is a seat.

One, **the deferral competes for a vehicle that the same clause allocates
elsewhere.** The dispatch prompt gives a run one opened pull request. L55 clause
three gives the register first claim on it, correctly, because the register is
this seat's only memory. A `prompts/` path cannot ride in that pull request,
because the slowest hand in a branch is the hand on all of it (L55 clause one),
and in this product a `prompts/` path is the owner's alone with no clock able to
expire into it (incident 27). So the vehicle a charter patch needs is the one
thing every run is instructed to spend before it could get there.

Two, **nothing enumerates a register deferral.** `check.sh` walks
`docs/agents/patches/ORDER` and answers *applies* or *already in the charter*
for every file there. Nothing walks this register for the same shape. The older
and worse mechanism is the only one of the two with a detector, which is why the
directory's patch is visible every run and L55's two are visible only to a reader
who happens to read down to clause three.

**Impact.** Three patches for one charter, written, read, unapplied; one of them
corrects an instruction already measured at five hours of a wrong merge verdict.
And the cost compounds in the direction L-A100 names: every day the decision
waits, the branch that carries it grows, so the oldest pending charter patch is
always the most expensive one to take.

**What would close it, and both halves are somebody else's.** Either the
deferral gets an addressee and a clock — a board ask with `expires_at` set,
which incident 26 found no seat can write — or register deferrals get the
detector the patches directory already has, which is a change to `check.sh` and
one more `&&` link rather than one more sentence (L-A22). This entry names both
rather than choosing, because choosing between them is the project manager's and
not this seat's.

**Re-measured 2026-10-26T05:0xZ, by the two commands this entry named, on the
next run of this seat as it asked. Still open. It did not move, and one of the
two things this entry said was impossible turns out to be possible.**

Both commands, re-run against `origin/main`:

- `git show origin/main:prompts/pm-agent.md | grep -n mergeable.sh` returns
  nothing. Patch one is not on `main`. The released sentence it corrects is at
  **line 82** and names `main` as a literal argument — `run `git merge-tree
  --write-tree main origin/<branch>` on every branch the wait names` — which is
  the instruction L43 and incident 19 priced at five hours thirteen minutes.
- `grep -n "One draft PR per run"` returns line 102. Patch two is not on `main`
  either.

**The instance count, not the entry count.** Since the deferral was written at
2026-10-24T23:1xZ, **14** runs of this seat have started, classed from the
result object's `terminal_reason` and never from an exit code (L64): **5
`api_error`**, so refused and never given the chance, **5 `max_turns`**, **3
`completed`**, and this one. That is **eight runs that worked**, against the
seven this entry counted twenty minutes earlier, and none of the eight opened
`prompts/pm-agent.md`. The run immediately before this one is the clearest case
and it is not carelessness: it hit `max_turns` at 04:25:11Z having opened
`#328`, so it ended inside the cap rather than at a decision.

**Did the defect fire again? No, and the zero is about the queue rather than
about the instruction — which is the thing this entry must not be read as
saying.** Measured rather than assumed: **10 of the 80 pull requests created in
this repository since 2026-10-24 target a branch other than `main`**, one in
eight, so the population is live. But since the board item was filed at
2026-10-24T12:41:14Z, no stacked pull request of another seat has stayed open
long enough to need a verdict. `#271`, `#274` and `#279` lived until 22:50:2xZ
that day and were closed as a dead chain rather than judged; `#314` lived **58
seconds** and `#324` **53 seconds**; and the only one open now is this run's own
`#329`, at thirteen minutes. Zero opportunities, therefore zero instances. A
later reader must not take that as evidence the released sentence is safe
(L-A80: a read that succeeds with nothing in it is not a reading).

**The correction this run owes to its own root cause.** This entry's closing
paragraph says the deferral could get "a board ask with `expires_at` set, which
incident 26 found no seat can write". **That is false, and it was false when
written.** `bash docs/agents/clocks.sh --writable` settled it by write at
2026-10-26T05:03Z: one `ask` with a deadline an hour out, and the 201 echoed
`"2026-10-26T06:03:25+00:00"` back. The field has been settable the whole time.
What incident 26 found, and what `clocks.sh` then encoded, was a *reading* of
the board's insert that mistook a default for a restriction — the sender's value
is the first argument of a `coalesce` and the `claim` arm is only the fallback.
So this entry ruled out the cheaper of its own two closures on an instrument's
false negative, which is L67 and is why L67 is the lesson this entry links to
rather than L66.

**So the first of the two closures is taken this run, and it is the one that
needed no new machinery.** The deferral now has an addressee that can apply and
a deadline in the field the law names, posted at 05:2xZ with `expires_at` set
and `ref` pointing at the vehicle. The second closure — a detector that
enumerates a register-held deferral the way `check.sh` already enumerates
`docs/agents/patches/ORDER` — is still owed and is still not this seat's to
choose, but it is now the backstop rather than the only route.

**Status: still open.** The fix is not on `main`. Where it sits: the patch text
is in `docs/agents/lessons.md` under L55 clause three, verbatim with its anchor,
line, hand and base; the live single-file vehicle for that file is `#304`, ready
since 2026-10-24T22:57:17Z, trial-merged clean against `main 23faa09` at
2026-10-26T05:07:16Z by `bash docs/agents/mergeable.sh 304`. **The one thing
blocking it** is no longer the absence of a clock: it is that `#304` carries a
different patch for the same file, so adding these two is an amendment to
somebody else's ask and rides from its author, not from here (this charter's
"When a clock is running on words"). Re-measured next run by the same two
commands, plus whether the clock posted this run expired and what happened at
its expiry.

**Re-measurement this entry owes (L20), as commands.** Written 2026-10-26 by
incident 40's repair, which found this entry in the class of open entries with
nothing that could tell.

```remeasure 36
probe   ! sentences origin/main:prompts/pm-agent.md | grep -qi "mergeable.sh"
control sentences origin/main:prompts/pm-agent.md | grep -qi "One draft PR per run"
means   open
```

A `CHANGED` here means the pm charter on `main` carries the deferred patch and
the two-day wait this entry measures is over.

## Incident 37 — 2026-10-26 — A pull request this forge calls merged put its commits on a dead seat branch and none on the trunk, and the instrument this charter names for *what landed* was reading the forge's field

**Status: the detector is closed and on this run's branch; the clause that
prevents the cause is written and not on `main`.** The repair that matters is
one line of `docs/agents/landed.sh`, in this run's pull request, fired against a
real positive before this was written. The preventive half is a charter clause
sitting in `#300`, open and unmerged at the owner's tier since
2026-10-24T22:17:30Z — and the version in `#300` **would not have caught the
instance below**, which is why this entry is the landing path's and not a second
copy of the lesson (L20). Lesson: **L70**. Re-measured next run by the two
commands in the facts.

**Facts.**

`#264`, this seat's own, opened 2026-10-24T02:01Z with base
`epitome-exo/2026-10-24-message-4` and merged **2026-10-24T12:06:31Z**. The
forge reports it `MERGED`. Two commands, both re-runnable:

- `gh pr view 264 --json state,mergedAt,baseRefName,headRefOid` → `MERGED`,
  `2026-10-24T12:06:31Z`, base `epitome-exo/2026-10-24-message-4`, head
  `9ec70244`.
- `git merge-base --is-ancestor 9ec70244 origin/main` → **non-zero**, against
  `main` at `23faa09`, from an unshallowed clone. The base branch is still on
  the remote at `c573dc56` and is on no ancestor of `main` either.

So its single file and 39 lines went onto a branch nobody merged again.

**Impact, stated at its true size and no larger.** The 39 lines reached `main`
two days later on a different branch, so **no text was lost**. What was lost is
the ability to tell: for two days the forge's own fields said merged, `state`
said `MERGED`, `mergedAt` carried a timestamp, and the only reading that
disagreed was a containment test nothing in this repository ran. The same shape
in a window where the sibling branch had not carried the text would have been a
silent loss, and nothing would have reported it then either.

**Root cause, in the system and not in a seat, two layers.**

One, the charter. `prompts/exo-agent.md` says "Start from your own newest open
pull request, not from `main`", and a run obeying it with `--base` instead of
with the branch point builds exactly `#264`. Nine of this repository's 23
non-`main`-based pull requests reached `main` by no route; eight of the 23 are
`epitome/engineer`'s, so the sentence is not the only source but it is this
seat's.

Two, the instrument. `docs/agents/landed.sh` existed precisely to stop a wrong
merge claim — its own header records this seat telling two project managers a
false merge story on 2026-10-23 — and it computed `outcome` from `mergedAt`
alone. The charter tells a run to **paste** its `data` block rather than retype
it, on L33's authority, so the one surface built to make a merge number
unre-narratable was publishing the forge's false field with this seat's name on
it. A generated number is only as honest as its generator.

**Fix shipped.** `landed.sh` now reads the merge by containment and reports
three outcomes with a fourth for what it could not place. Control, one snapshot
and one pass (L68), window from 2026-10-24T11:00:00Z: **46 merged onto main, 1
off-trunk — `#264` — 17 closed unmerged, 0 could not be placed.** Before the
change the same row set gives 47 merged and no off-trunk class at all. The clean
case is reachable at 46 of 47, so the check is not measuring its own assumption
(L-A101). The `merged` key is renamed `merged_onto_main`, so a reader holding
the old spelling gets a missing key instead of a wrong number.

**The detector's own limit, declared rather than left for the next incident.**
This reads what left the queue. The sibling hazard — a child still open whose
base ref was deleted — is in the open queue and is `mergeable.sh`'s, which
already prints each base and marks the one not targeting `main`; that is the
checker that caught `#329` at 05:12Z today. Neither instrument reads the other's
population, and this entry says so rather than claiming coverage.

**Re-measurement this entry owes (L20), as commands.** Written 2026-10-26 by
incident 40's repair.

```remeasure 37
probe   ! sentences origin/main:prompts/exo-agent.md | grep -qi "Containment does the stacking"
control sentences origin/main:prompts/exo-agent.md | grep -qi "One branch per seat"
means   open
```

A `CHANGED` here means `#300` merged and the preventive clause is law. The
detector half is already on `main` and is not what this probe reads: this entry
is open on the clause alone, so the probe asks about the clause alone.

## Incident 38 — 2026-10-26 — This run's own pull request was closed as merged three minutes after it opened, by the merge of the pull request it was told to branch from, and the instrument repaired eight hours earlier counted it as a landing

**Status: both repairs are in the tree on this run's branch, each fired against
a real positive before this was written; the preventive clause is a charter
patch and is not on `main`.** Lessons: **L75** for the cause, **L70** for the
instrument it reopens. Re-measured next run by the two commands in the facts.

**Facts, all re-readable.**

This run opened `#342` as a draft at 2026-10-26T09:54:57Z, within its first
turns, as this charter's Output section requires. Its branch,
`epitome-exo/2026-10-26-message-8`, was cut from `#340`'s head because this
charter says *"Start from your own newest open pull request, not from `main`"*,
and it was pushed before it carried a commit of its own. Both branches
therefore named one commit.

- `gh pr view 340 --json headRefOid,mergedAt,mergeCommit` → `7309e4ad`,
  `2026-10-26T09:58:05Z`, `01218f60`.
- `gh pr view 342 --json headRefOid,mergedAt,mergeCommit` → `7309e4ad`,
  `2026-10-26T09:58:07Z`, `01218f60`.

One merge commit, two pull requests, two seconds apart. `#342` lived 190
seconds and contributed nothing. A merged pull request cannot be reopened, so
this run's work moved to `#343`, cut from `main` and carrying a commit before
it was pushed.

**Impact, at its true size and no larger.** No text was lost: `#342` held only
the commit it inherited, which merged on `#340` as intended. What was lost is
three minutes and a pull request number, and — the part that would not have
announced itself — the run's own body. This charter says the body is the
report; `#342`'s body was the report of a run still in progress, and it is now
attached to a closed pull request nobody will read, on a branch nobody will
merge again. A run that died in those three minutes would have left its draft
*marked merged*, which reads from every surface in this company as work that
shipped. That is the version of this to be afraid of, and nothing in the tree
would have caught it before today.

**Root cause, in the system and not in a seat, two layers.**

One, the charter, and it is two correct rules whose conjunction is the defect.
*Open the draft first, before anything else that takes time* exists because a
run that dies must still ship its partial work (L-A32, L71). *Branch from your
own newest open pull request* exists because `main` is the one view guaranteed
not to hold the entry the last run is waiting to merge. Obeyed together they
guarantee a window — from the push to the first commit — in which this run's
pull request is a duplicate of another one and dies when it merges. The window
is as long as the run's first piece of work, and in this repository a parent
merges in minutes: `#340` merged nine minutes and twenty-four seconds after it
was opened.

Two, the instrument. `docs/agents/landed.sh` was repaired this morning on
`#338` to stop reading the forge's `merged` field and to test containment in
the trunk instead (L70, incident 37, merged 09:28:59Z). Containment answers
**yes** for a shadow, because `7309e4ad` genuinely is an ancestor of `main`. So
twenty-nine minutes after that repair landed, the instrument named in this
charter for *what landed* reported **7 merged onto main** for the morning, of
which one added nothing. Same instrument, same morning, same class of false
merge claim, through the second of its two doors.

**Instances, not entries (L20).** Two in the 166 merges this repository has
recorded. `#342` today, and `#156` on 2026-10-18, which merged one second after
`#153` on merge commit `639f8caf` because `#153` was the stack that contained
it. The first went uncounted for eight days, by every instrument, including the
queue count this charter asks for every run.

**Fix shipped.**

- `docs/agents/landed.sh` gains a `shadow` class: the first merged row for a
  merge commit is the landing and every later one is counted apart and never in
  the merges. Fired before this was written — the morning window now reads **6
  merged onto main, 1 shadowed**, and across all 166 merges it names `#342` and
  `#156` and no other row.
- `docs/agents/drafts.sh` is the other instrument that reads a draft's standing
  and it is repaired in the same pull request for a different defect (L74).
- The preventive clause — **commit before you push** — is a charter patch and
  is flagged as the owner's to merge or refuse. It is four words of behaviour
  and needs no instrument, which is the reason it is worth the clause: the
  detector above catches the shadow after it exists, and this stops it being
  made.

**What is not fixed here.** The underlying conjunction stands: a branch cut
from an open pull request still inherits that pull request's fate in every
other way, and `#343` is based on `main` only because `#340` merged while this
run was writing. The charter clause this entry carries narrows the defect to
the one window that costs a pull request; it does not settle whether branching
from an open pull request is right, which `#300` has been asking since
2026-10-24T22:17:30Z and which is still the owner's.

**Re-measurement this entry owes (L20), as commands.** Written 2026-10-26 by
incident 40's repair.

```remeasure 38
probe   ! sentences origin/main:prompts/exo-agent.md | grep -qi "open the pull request against"
control sentences origin/main:prompts/exo-agent.md | grep -qi "One branch per seat"
means   open
```

A `CHANGED` here means `#300` merged. Both repairs reached `main` with `#343`
and `#344`, so nothing in this probe is about them.

## Incident 39 — 2026-10-26 — Two runs of this seat opened five pull requests in fifty-four minutes, and three of the five exist only because the merger answered faster than the run could finish

**Status: closed on the detector and on the register, open on the charter
clause.** `offmain.sh --here` and `drafts.sh` are both on `main`; L75 and L76
are both on `main`; clause 2 of L76 is behaviour and binds nowhere until the
owner merges `#312`, which has been open since 2026-10-25T03:25:52Z. This line
was missing when the entry was written an hour before, and its absence is the
`not_judgeable` class of incident 40 — written by the seat that owns both the
field and the rule requiring it, in the same morning (L-A28, L-X1 as amended).

**This entry was asked for by name, which is why it leads.** `epitome/pm`, on
the board at 09:58:50Z, verbatim: *"there is a merge-timing hazard here that
deserves its own write-up alongside the register rows that were promised and
not delivered."* It was right about the hazard and it is the hazard's third
instance that this entry is written from.

**The handoff's other half, re-read rather than taken** (L24, L38, L48: the
only moment a claim about a pull request is true is the moment you read it).
The three rows it named as promised and missing were a second lesson, an
incident entry and a loop row. Two of the three were on `main` fifteen minutes
after that message was composed — `L74` and `Incident 38`, carried by `#343`,
merged 10:13:53Z — and the loop row reached `main` at 10:27:26Z with `#344`,
three minutes before this entry was written. So the handoff is answered by
measurement on two of three items and by this entry on the third, and nothing
about it was wrong when it was sent.

**The facts, and every row is a timeline event rather than a field.**

| pull request | opened | flag off | merged | flag off → merged | why it exists |
|---|---|---|---|---|---|
| `#339` | 09:33:38Z | 09:43:05Z | 09:45:24Z | **2m19s** | the run's own work |
| `#340` | 09:48:41Z | 09:48:45Z | 09:58:05Z | 9m20s | to carry `L73`, committed 09:46:27Z onto `#339`'s branch 63s after it merged |
| `#342` | 09:54:57Z | never | 09:58:07Z | — | cut from `#340`'s head and pushed before it had a commit; closed as merged by `#340`'s merge, carrying nothing (L75) |
| `#343` | 10:03:37Z | 10:11:46Z | 10:13:53Z | **2m07s** | the next run's own work |
| `#344` | 10:19:42Z | **opened not a draft** | 10:27:26Z | 7m44s (from opening) | to carry three commits made 10:15:45Z–10:17:11Z onto `#343`'s branch, up to 3m18s after it merged — and it is a **second pull request on that same branch**, `epitome-exo/2026-10-26-message-9`, which L-A59's delete-on-merge had already removed and the push re-created |

Three of the five — `#340`, `#342`, `#344` — carry no work that was not already
written when they were opened. One of the three carried nothing at all. The
third did not even cut a branch: it re-pushed the one the merge had just
deleted and opened a second pull request on the same name, so
`epitome-exo/2026-10-26-message-9` now answers for two pull requests and every
instrument keyed on a branch name has to pick one — which `landed.sh` printed
plainly at 10:35:13Z, two rows with one branch. By the
fifth the run had stopped using the draft stage altogether, which is the
clearest evidence in the table that the flag itself had become the thing to
avoid: `#344` has no `ready_for_review` event in its timeline because it was
opened straight into the merge queue.

**The impact is on the one number this charter publishes for the owner.** Her
queue count reads pull requests, and the charter's first standing count already
corrects it for stacks — *"a linear stack is one decision presented as many"*.
These are not a stack. `#340`, `#343` and `#344` each targeted `main`, each
merged on its own, and each is a separate click. One run's output arrived at
the merge button as three decisions with nothing to mark them as one, and no
clause in this charter tells the count to say so.

**Root cause, in the system, and the merger is not in it.** `epitome/pm` is
doing exactly what its standard tells it to (§20: the item is held until the
queue moves), and the queue moved. The defect is a conjunction of three charter
clauses that are each correct and were each written for a different failure:

1. **Lift the flag at the first artifact** (L71), because a run cut by the
   provider leaves a draft and a draft ships nothing. Written this morning from
   two instances that cost 78 and 72 turns.
2. **Keep working after it** — the Output section's own words, and `#312`'s
   pending amendment makes it explicit: *"the body is the report, so it is
   written at the same first moment the flag is lifted and rewritten as the run
   learns more."*
3. **One pull request per run**, the dispatch's ceiling.

Nothing in the three says where a commit goes when it is made after the flag
came off, and that is the whole gap. The answer is forced by arithmetic the
charter never states: **the flag is a trigger on somebody else's clock, and
today that clock is shorter than the work.** Measured across every pull request
merged in this repository today that has a `ready_for_review` event:

```data
instrument: gh api repos/alexandrapaiz/epitome/issues/<n>/timeline, gh pr list --state merged
read_at: 2026-10-26T10:3xZ
merged_today_with_a_ready_event: 24
median_flag_off_to_merged_all_seats_seconds: 546
fastest_today_seconds: 5
slowest_today_seconds: 124208
this_seats_pull_requests_of_those: 15
this_seats_median_seconds: 292
this_seats_under_180s: 6
since_capacity_returned_0905Z_this_seat: 6
since_capacity_returned_median_seconds: 135
since_capacity_returned_gaps_seconds: [76, 127, 131, 139, 353, 560]
runs_of_this_seat_in_the_window: 2
window: 2026-10-26T09:33:38Z..10:27:26Z
pull_requests_opened_in_window: 5
exist_only_because_of_merge_timing: 3
carrying_nothing_at_all: 1
commits_made_after_their_own_branch_merged: 4
longest_such_commit_after_its_merge: 3m18s
pull_requests_sharing_one_branch_name: 2 — #343 and #344, epitome-exo/2026-10-26-message-9
that_branch_on_the_remote_now: deleted, twice, by L-A59
```

A run of this seat lasts tens of minutes. Half of this seat's pull requests
today were merged inside five minutes of the flag coming off, and in the hour
after capacity returned the median was **135 seconds**. Under that distribution
clauses 1 and 2 together guarantee the orphan; they do not risk it.

**Fix shipped, and it is in three parts with three different hands.**

- `docs/agents/offmain.sh --here`, in this entry's own pull request. The
  default mode walks the open queue and excludes this run's own branch, so the
  merged-under-you case was outside its population twice over. The new mode
  asks about `HEAD`: the pull request's state, the draft flag, and containment
  in `main`, with the readied-and-open row returning a **finding** rather than
  a note because that is the only moment at which cutting the next branch costs
  nothing. Nine verdicts in `--self-test`, including the two zero-commit rows a
  first draft of it described wrongly.
- **L76**, the rule a fresh-context run applies without having seen any of
  this: the next commit after the flag comes off goes on a new branch, cut
  before the commit is made.
- **The charter clause**, which is the only part that binds, and it is **not on
  `main` and not in this pull request**. It rides as an amendment to `#312`,
  this seat's own open ask, which already carries the Output section's
  flag-and-body material — because filing a fourth proposal beside three open
  ones is the thing L71 caught this seat doing a run ago (L29, L27).

**Where the fix is, rather than the word shipped.** Two of the three parts are
in `#345` and on no `main` yet; the clause that binds is in `#312`, open since
2026-10-25T03:25:52Z. **The one thing blocking it is that no hand in this
repository but the owner's may merge under `prompts/`**, which is the same
blocker as incidents 36 and 38 and the same one `alexandra-systems/exo-centralizer`
has already routed to HQ's project manager as work that is not landing. Counted
as instances and not entries (L20): three instances in fifty-four minutes —
`#339`'s orphan, `#342`'s shadow, `#343`'s orphan — and all three fell after L71 was on
`main` at 09:15:28Z, so the rule being missing is not what let them through.
That is what makes this the landing path's and not a new rule's. The next run of this seat re-measures `#312` and says in first person
whether it moved.

**Lessons linked.** L76 (new, the rule), L71 (the clause that makes the flag
early), L75 (the shadow, which is this hazard's degenerate case — a recovery
branch pushed before it carried a commit), L70 clause 1 (why the recovery
branch targets `main` and therefore counts as its own decision), L20 (a second
instance while the fix sits written is an incident of the landing path),
incident 38 (the same morning, the same conjunction, narrowed by one window).

**What is not fixed here, and this run paid it knowingly.** L76 clause 2 and
the dispatch's one-pull-request ceiling cannot both be satisfied by a run with
more than one artifact. Obeying clause 2 means a second pull request for the
second artifact; obeying the ceiling means there is none; so the only remaining
way to keep the flag and the commits apart is to lift the flag when there is
nothing left to commit — which is L71 exactly inverted. This run chose that,
deliberately, and held the draft from 10:21Z to 10:4xZ with six commits in it
and `offmain.sh --here` reading `ok` on every one, accepting L71's risk that a
provider cut would have left a draft and shipped nothing. **That is a decision
about this seat's dispatch and not about its charter, so it is not this entry's
to settle:** the ceiling is in the runtime's composed prompt, which L-X11 says
is the charter's second file and the one that wins. `#312`'s clause three asks
the owner for the charter half. The dispatch half — whether a run that readies
per artifact may open a pull request per artifact — is the single owner
decision to ask if everything else fails, and it goes in the handoff with this
measurement.

**Re-measurement this entry owes (L20), as commands.** Written 2026-10-26, in
the same run as the entry, because the entry was in incident 40's own
`no_status_field` class an hour after it was written.

```remeasure 39
probe   ! sentences origin/main:prompts/exo-agent.md | grep -qi "cut from the readied head"
control sentences origin/main:prompts/exo-agent.md | grep -qi "One branch per seat"
means   open
```

A `CHANGED` here means `#312` merged and clause 2 of L76 binds a run rather
than describing one.

## Incident 40 — 2026-10-26 — The instrument this charter names for re-measuring open incidents reported all-clear over four of fourteen, because its population was the fences it could parse

**Status: the repair is in this tree and fired against the real positive
before this was written; the register debt it exposed is open and counted.**
`docs/agents/remeasure.sh` enumerates the register rather than its own fences,
names two classes that cannot exit 0, and carries 19 verdicts in
`--self-test`. The fourteen entries with no Status field are open, named below
with the date they were named, and now counted on every run.

**Facts.** The first command of this run, 2026-10-26T10:47:20Z:

```data
instrument: docs/agents/remeasure.sh
read_at: 2026-10-26T10:47:20Z
conditions_printed: 7
verdicts: 7 HOLDS, 0 CHANGED, 0 COULD NOT LOOK
final_line: "every condition holds: no incident here is a candidate for closing"
exit: 0
```

The same file, read for the population the duty actually names, at
2026-10-26T10:50:27Z:

```data
instrument: docs/agents/remeasure.sh --coverage
read_at: 2026-10-26T10:50:27Z
register: docs/agents/incidents.md
incidents_in_register: 35
conditions_executable: 7
open_by_their_own_status: 15
open_with_a_condition: [26,27,29,32]
open_without_a_condition: [19,20,22,23,24,25,28,34,36,37,38]
no_status_field_so_not_judgeable: [1,5,6,7,8,9,10,11,12,13,14,16,17,39]
exit: 2
```

**Impact.** L20 is the clause that makes an unlanded fix a measurement rather
than a note, and it is discharged by this instrument on every run of this
seat. For the two days since the instrument shipped, eleven open incidents
were neither measured nor reported as unmeasured. Three of those eleven are
this seat's own from this morning — 34, 37 and 38 — so the entries most likely
to be live were the ones the instrument was least likely to carry, because a
condition is written by the run that has time left and today's runs did not.
Nothing was lost that is unrecoverable: the eleven are all still open and
nothing was wrongly closed, so the cost is two days of a duty reported as
performed, and the exit 0 that reported it.

**Root cause, in the system.** The script's `blocks()` function is both its
parser and its census. It greps for ```remeasure fences and the set it returns
is the set it then iterates, so "no fence" and "nothing to measure" are the
same state inside it and the second one is the one the exit code reports. The
duty's own population is a different set living in a different place — the
`**Status:` field of each entry — and no line of the script had ever read that
field. Two populations, never joined, and the smaller one owning the verdict.

**The aggravating fact, and the one that makes this an incident rather than a
lesson alone.** Incident 30 named this exact comparison as a number it owed,
in prose, on 2026-10-25, with the command written out. Seven working runs of
this seat later it had never been computed once. A comparison written as a
sentence under the entry that asks for it is owed by nobody, which is L-A9 and
L-A22 landing on the seat that keeps the register — and by L4 a rule already in
the register failing a second time is the register's defect, so this run shipped
the structural fix rather than a third sentence.

**Fix shipped, and the real positive it fired against.** `remeasure.sh` gains
`population()`, `classify()` and `coverage()`; the no-argument run prints the
scope **before** the verdicts, because a reader who sees seven HOLDS and then a
scope line has already formed the answer; and the population's exit status
outranks the verdicts'. Fired against the real register above: exit 2, eleven
and fourteen named. Three self-test cases are the controls that decide whether
anyone keeps it — a fully covered register must say so and exit 0, a
declared-closed entry carrying no condition must not be a finding, and a Status
field wrapped across two lines with one closed half and one open half reads as
open, which is the shape incident 20 and incident 24 are written in.

**Second defect, same file, same shape, found while fixing the first.** A
condition's polarity lived in the prose beside the block. `means open|healthy`
is now a field; an unknown value is refused; a healthy probe going silent
prints `REOPENED` and never a candidate close. Incident 30's block carries
`means healthy` and now reads "the fix is still working, so there is nothing to
reopen".

**The state at the end of the run that found it, so the next run compares
objects rather than sentences (L-A45).**

```data
instrument: docs/agents/remeasure.sh --coverage
read_at: 2026-10-26T10:55:21Z
incidents_in_register: 36
conditions_executable: 12
open_by_their_own_status: 17
open_with_a_condition: [26,27,29,32,36,37,38,39,40]
open_without_a_condition: [19,20,22,23,24,25,28,34]
no_status_field_so_not_judgeable: [1,5,6,7,8,9,10,11,12,13,14,16,17]
exit: 2
```

Conditions went from 7 to 12 in this run: 36, 37, 38 and 39 are this seat's own
entries of today and this morning, every one of them open on a charter clause
reaching `main`, so each probe reads `origin/main:prompts/` for the clause's own
words and each control reads a sentence known present in the same file. All four
fire `HOLDS`, which means all four are genuinely open rather than unreadable.
The eight that remain are 19 through 34, written across five weeks in contexts
this run did not reconstruct.

**Owed, with its reason and the date it was named (L-A145).** Thirteen entries
carry no Status field, named 2026-10-26, all of them from 2026-09-18 to
2026-10-24. This run did not backfill them, and the reason is
that it will not guess at thirteen historical states under turn pressure to
turn a gate green: a wrong `closed` is worse than an honest
`not_judgeable`, because it removes the entry from the population permanently
and silently, which is this entry's own defect committed deliberately. Incident
39's line was added this run because that entry is this morning's and its state
is known. The remaining thirteen are a backfill job for a run with turns to
spend, and the count is in the `data` block of every no-argument run until it
is zero.

**A third instance was already written in this register, one entry above.**
Incident 38 closes with "Neither instrument reads the other's population, and
this entry says so rather than claiming coverage" — the same defect, named
honestly, in the same file, five hours before this one was found. Three
statements of one axis and no instrument changed is what L4 calls a register
defect, and it is why this run shipped a population reader instead of a fourth
sentence.

**Also owed, and not claimed as done.** Five other instruments in
`docs/agents/` choose their own population the same way — `drafts.sh`,
`order.sh`, `doors.sh`, `caps.sh`, `clocks.sh`. This run checked none of them
against the duty each answers for. L77 names them; no instance is claimed.

**Re-measurement this entry owes (L20), as commands.**

```remeasure 40
probe   bash docs/agents/remeasure.sh --coverage | grep -q "not an all-clear"
control bash docs/agents/remeasure.sh --coverage | grep -q "incidents_in_register"
means   open
```

A `CHANGED` here means every open incident in the register now carries a
condition and the backfill above is done. The control fails if the coverage
reader itself stopped answering, which is the only way this probe's silence
could be a lie.

**Lesson:** L77.

## Incident 41 — 2026-10-26 — The wake cut this run's own note at the paragraph carrying its ask, and the check that prints exactly that had been on `main` for six hours

**Status: the instance is closed and the class is open.** The repair is in this
tree and fired against the real positive — the body that caused it — before this
was written: `docs/agents/post.sh` runs the gate and refuses the POST, so the
check is upstream of the write rather than beside it. Incident 33's own detector
is unchanged and still correct; what was wrong was its position. The class stays
open because nothing compels a seat to use the cheaper path, which is the last
section of this entry. This line was reworded in the run that wrote it, because
the coverage reader of incident 40 read its first draft as carrying no readable
status at all — the entry's own author being the first person the new gate
refused.

**Facts.** At 2026-10-26T11:02:58Z this seat posted a note to `epitome/pm` and
the board's own answer carried the verdict:

```data
message: 147117ee-536e-4000-aa10-4104aba3b079
posted_at: 2026-10-26T11:02:58Z
body_chars: 3844
body_delivered: 1455
body_truncated: true
wake_limit: 1500
paragraphs_not_delivered: 9
first_paragraph_below_the_cut: the merge ask, naming the branch and the head
gate_available_since: 2026-10-26T05:3xZ, on `main`, as incident 33's repair
gate_run_before_sending: no
```

Run afterwards on the same bytes, `bash docs/agents/addressed.sh --body` named
all nine dropped paragraphs and ended "put the ask above the cut, or split the
message", exit 3. It would have said that before the send, in two seconds, for
nothing.

**Impact.** The reader this note was for is this product's only merger, and the
paragraph it needed — the branch, the head, and the fact that the pull request
is `docs/`-only and so inside its own tier — was the first thing below the cut.
The repair was a second message, disposition first, 1,365 characters, gated
before it went. That is two messages where one was intended, which is the
nearest this run came to incident 28's shape, and the distinction worth keeping
is that incident 28's limit was never there while this one is stated in the
payload and the platform's own notice says to split.

**Root cause, in the system.** The gate prints and does not block
(`docs/standards/lessons.md` L-A114), and it lives beside the act rather than in
it, so obeying it is a thing a run must remember at the one moment it is least
able to remember anything. Incident 33 was declared closed on the strength of
the detector existing, which is L-A16: configured is not in effect. Both halves
were already law, which is why this entry ships a path rather than a reminder.

**Fix shipped.** `docs/agents/post.sh` takes the POST payload, extracts the
body and subject, runs `addressed.sh --body` with the payload's own `kind`, and
posts only on a clean verdict. Three outcomes and never two (L41): posted,
refused with the gate's own words and nothing sent, or could-not-look which
also never posts. Six verdicts in `--self-test`, and one of them exists because
the first version of this file got the gate's exit codes wrong: `addressed.sh
--body` documents 1 as the store refusing, 2 as could-not-look and **3 as the
wake cutting it**, and reading `rc > 1` as could-not-look called the real
11:02:58Z body a thing it could not see. The fixture that passed had exited 1 on
a different rule, so the deciding branch was never hit — which is L77's own
clause arriving inside L77's own run, two hours later, in a file written to
repair a different instance of it. The self-test now carries a fixture that
exits 3 and an assertion that the words "could not look" do **not** appear.

**And one thing it asserts about itself.** After a successful post it reads
`body_truncated` out of the server's answer, and a `true` there — the gate
passing a body the server still cut — exits 2 and says the gate and the write
path disagree about the limit. A checker calibrated against a surface that has
moved is the failure this directory shipped five times today, so the one place
it can be caught cheaply is the round trip it already makes.

**What is not fixed.** Nothing requires a seat to use `post.sh` instead of
`curl`. The real enforcement is a `PreToolUse` hook on the shell, which is how
HQ enforces L-X5's secret shapes, and that is the runtime's to register rather
than this repository's. Named here rather than claimed: until a hook refuses a
bare POST to `/api/messages`, this is a cheaper path and not a gate, and the
honest status of the class is open even though this instance is closed.

**Re-measurement this entry owes (L20), as commands.**

```remeasure 41
probe   ! grep -rqE 'post\.sh|PreToolUse' /srv/asc/hq/runtime/board/api.py
control test -r /srv/asc/hq/runtime/board/api.py
means   open
```

A `CHANGED` here means the write path itself knows about a gate, which is the
only thing that would close the class. The control fails if that file stops
being readable from this seat, in which case the probe would be measuring its
own reach rather than the world (L58).

**Lessons:** `docs/standards/lessons.md` L-A114 for the gate that prints
instead of blocking, L-A16 for a detector counted as in effect, and L77 for the
self-test fixture that never reached the branch it was written for.

## Incident 42 — 2026-10-26 — The daily brief woke all eight halves of the company's learning loop into a closure the provider had named 105 minutes earlier, every one of them died at turn one, and the retry that recovered the runs recovered none of the duties

**Status: open.** The detector is shipped and fired against the real positive
before this was written — `bash docs/agents/owed.sh` names this seat's own lost
tick, exit 1, six verdicts in `--self-test`. The repair is in no tree this seat
can write to: clause one of L78 is one line in a payload composed in
`alexandra-systems` `runtime/`, and `addressed.sh --can` answers `FORBIDDEN`
there. Routed with this entry. Lesson: **L78**, and **L79** for the cadence half.

**Facts, in the order the box recorded them.**

- `10:16:11Z` — `ursa-frontend`'s run is refused at turn 232 with
  `"api_error_status":429` and, in the result object's own `result` field,
  *"You've hit your session limit · resets 2pm (UTC)"*. The provider has now
  stated in a sentence this company parses that nothing will run for 3 h 44 m.
- `10:16:11Z → 12:20:01Z` — **44 runs on 16 seats are refused by that window,
  43 of them started after the sentence above was already in a log.** 33 never
  took a second turn; the other 11 were cut mid-flight between turns 2 and 232,
  **826 turns, $62.00 and 230 minutes that bought nothing.**
- `11:05:07Z → 12:06:08Z` — **all seven of the day's scheduled slots fire into
  the closure and all seven are refused.** One of them, `epitome/pm`'s
  `0 12 * * 1`, is a weekly slot: that seat's entire scheduled cadence for the
  week was spent at 12:00:08Z in four tenths of a second, and its next firing
  is 2026-11-02T12:00Z.
- `12:01:53Z` — `asc-brief.timer` fires (`systemctl show asc-brief.timer -p
  LastTriggerUSec`).
- `12:01:57.918423Z` — the board emits `brief.sent`, 1,219 characters stored
  against 2,343 live, its own footer saying 6 of 9 sections were delivered and
  naming *Shipped, Products, Decided in your name* as cut.
- `12:01:58.266Z → 12:02:10.286Z` — the bus wakes **eight seats**:
  `exo-centralizer`, `alexandria-exo`, `ursa-exo`, `epitome-exo`,
  `epitome-pm`, `alexandria-pm`, `ursa-pm`, `pm`. Four exo seats and four pm
  seats, one pair per product. **All eight are refused. Every one at turn 1,
  `num_turns` 1, $0.** Nobody observed, nobody oriented, and no product sent
  the centralizer the facts the company-wide decision is made on.
- `14:00:00Z` — the reset the provider named.
- `14:03:06Z` — `asc-capacity-retry.timer` wakes **sixteen seats**, and they
  are exactly the sixteen the window refused, set difference empty in both
  directions. Three minutes. Its payload, verbatim: *"capacity returned: the
  provider limit that refused your last run has reset, and nothing else would
  have woken you until your next scheduled window. Do the one run your charter
  describes."*
- `14:17:17Z` — `bash docs/agents/owed.sh` on this seat:
  `brief_events_whose_wake_was_refused: 1`, `brief_events_still_owed: 1`.

```data
instrument: the result record of every log under /srv/asc/state/.epito/logs, plus systemctl and the board
read_at: 2026-10-26T14:1xZ
brief_timer_fired: 2026-10-26T12:01:53Z
brief_sent_event: 2026-10-26T12:01:57.918423Z
brief_wakes_delivered: 8
brief_wakes_refused: 8
brief_wakes_that_took_a_second_turn: 0
products_whose_exo_half_ran_the_tick: 0
products_whose_pm_half_ran_the_tick: 0
closure_announced_at: 2026-10-26T10:16:11Z
minutes_from_announcement_to_fan_out: 105
wave_3_refused: 44
wave_3_refused_after_the_announcement: 43
wave_3_cut_mid_flight: 11
wave_3_mid_flight_turns: 826
wave_3_mid_flight_cost_usd: 62.00
wave_3_mid_flight_minutes: 230
slots_fired: 7
slots_refused: 7
weekly_slots_lost: 1
retry_fired: 2026-10-26T14:03:06Z
retry_seats_woken: 16
seats_refused_but_not_woken: 0
seats_woken_but_not_refused: 0
payloads_naming_the_duty_the_window_held: 0
```

**Impact.** The learning loop is the mechanism by which this company turns a
day's facts into law, and on 2026-10-26 it ran in zero of four products
because one twelve-second fan-out landed inside a stated closure. This is the
**second consecutive day** it has been lost — incident 32 records
2026-10-25T12:01:27.980Z, one seat, turn 1 — and the first on which it was lost
for all eight halves at once. Nothing reported it: the brief's own capacity
section that day read *"7.4 h with nothing running, 8 min of it after the limit
had already reset"*, a sentence about a recovered day, and the brief cannot
report its own loss because the brief is the thing that was lost. Separately,
30 runs on 10 seats exhausted their turn caps for **$332.13 and 803 minutes**,
and the brief told the owner those were *"30 run(s) ran and failed; the PMs
handled them."*

**Root cause, in the system, and it is two different causes that this entry
keeps apart.**

The first is incident 32's and is unchanged: no path that *starts* a run asks
whether the provider has already declared the pool closed, so timers and bus
fan-outs fire into it. `capacity-retry.py` parses the named reset through
`capacity.py:reset_after` and spends the answer only on *when may we start
again*. That is incident 32's row and today is its next window, counted there.

The second is this entry's own and is new. The retry recovers a **run**. A run
is fungible — the next message re-delivers the work — and the retry's
seat-selection proves the mechanism knows precisely which runs it is recovering.
A **duty** is not fungible: it is tied to an event that does not fire twice, and
the payload that resumes the seat names the resource and not the window. So the
recovered run reads *capacity returned*, does the general thing its charter
says, and the specific thing the window held is performed by nobody and
reported by nothing. The information needed to say otherwise exists at the
moment the payload is composed, because the payload already identifies the run
it is resuming.

**And the substance survived, which is what makes this cheap to fix.**
`GET /api/brief` served the whole brief to this run at 14:0xZ, so the duty was
performable two hours late by one HTTP call, and this run performed it. What
did **not** survive is the words the wake carried: `bash docs/agents/brief.sh`
printed *"the live brief is no longer the one that was sent (it regenerates on
read); what the wake carried cannot be diffed against it this run"* — the
second day running it has had to say that (L35, incident 15). A duty whose
input regenerates can be re-performed and cannot be audited.

**Fix, and where it is.** The hand side is not shippable from this seat and is
named rather than attempted: one line in the capacity-retry payload carrying
what fired in the interval and went unserved. The seat side shipped here:
`docs/agents/owed.sh` answers, for a seat and a window, which of its
duty-bearing wakes a limit refused, whether any later run served them, and
which scheduled slots were lost outright — because a slot is never re-served by
a message. Six verdicts in `--self-test`, every fixture built rather than
looked for, including the two negatives that stop it reporting every past
refusal forever: a refusal served by a later finished run is **not** owed, and
an `api_error` that is not a limit is not a refusal.

**One thing this entry corrected in its own instruments while writing itself.**
Splitting that non-limit `api_error` out of the limit count was done by reading
the result object's own `result` field for a limit sentence — which is the prose
read L64 removed, and it caught both of the two completed runs in this host's
1,633-record history whose final report *quotes* a refusal, one of them this
seat's own 09:02:46Z hook at 118 turns, printing it as the day's first refused
hook. The discriminator is now the single field `api_error_status in (429,529)`,
which is exactly coextensive with the 397 real refusals, and `caps.sh`
fixture 4 fails against the version this paragraph describes. Today's count is
therefore **98 limit-touched and one api error that was not a limit**, not 99.

**Re-measurement this entry owes (L20), as commands.**

```remeasure 42
probe   grep -q reset_after /srv/asc/repos/alexandra-systems/tools/capacity-retry.py && ! grep -qE "owed|unserved|window_held|lost_duty" /srv/asc/repos/alexandra-systems/tools/capacity-retry.py
control test -r /srv/asc/repos/alexandra-systems/tools/capacity-retry.py
means   open
```

A `CHANGED` here means the payload that resumes a refused seat has learned to
name what the window held, which is the only thing that closes this. The
control fails if that file stops being readable from this seat, in which case
the probe would be measuring its own reach and not the world (L58).

**Re-measure next run:** whether the 2026-10-27 brief tick was delivered to a
seat that could take it; whether `owed.sh` reports anything owed on a day with
no refusal window, which is the negative it has not yet seen in the wild; and
whether `epitome/pm`'s weekly slot is still the only weekly cadence this host
has lost.

**Lessons:** **L78** for the recovery that restores runs and not duties, **L79**
for the cadence counted in started runs rather than configured triggers,
`docs/standards/lessons.md` **L-A130** whose third part this amends, **L-X6**
whose test this widens, and **L62** for the unit a recovery is credited in.
