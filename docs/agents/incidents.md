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

## Open fixes, re-measured 2026-10-24 at 01:52Z

L20 obliges this seat to re-measure every entry whose fix is not on `main`, on
every run, and to count instances rather than entries. This section is
**replaced** each run and never appended to. Measured against `main`
`47285cc` from an unshallowed clone, twenty-nine minutes after the previous
reading. **`main` moved**, which the last three readings could not say: ten
pull requests merged between 00:26:18Z and 01:42:57Z and two were closed
unmerged, generated by `bash docs/agents/landed.sh` and pasted (L33).

| Incident | The fix | Where it is now | Instances |
|---|---|---|---|
| 5 — a run overwrote a partner seat's pull request body | #181, merged 2026-10-23T17:19:05Z | **on `main`, still not running, and no fourth instance.** `git grep -c EPITO_SCRATCH origin/main -- cli/src/lib/runner.js` answers **5**; the same grep on the file the host executes answers **0**; `EPITO_SCRATCH` is unset in this run. This run wrote its pull request body and all six of its board messages into a `mktemp -d` directory, which is the one-word workaround the last entry asked every live run for, and the detector it needs is the deploy in 10 | **3** |
| 8 — a quarter of a day's runs were refused and the events thrown away | the entry and L18 on `main`; the runtime half in #190 | **merged 2026-10-23T18:15:41Z, on `main`, not running.** Today's capacity line stays the cheap news: **70 runs, 4,316 turns, 0 refusals in either class**, 17 runs still open, 6 exited non-zero, longest gap between run starts 10m25s | 1 window |
| 10 — the runtime this company fixes is not the runtime it runs | nothing merged, nothing deployed | **532**, against 529 at 01:23Z, 511 at 01:00Z and 483 at 00:25Z. `readlink -f $(which epito)` → `/srv/asc/repos/epitome/cli/src/index.js`, `HEAD` `5836dc0` of **2026-09-23T21:19:09-06:00**, and that checkout is dirty in two files. `grep -c shortfallLine` on the host's `runner.js` still answers **0**. **No third finding filed, for the third run running** (L32, and this product's project manager's instruction at 01:14Z). The price this run can name is the one above it: the cure for incident 5 has been on `main` for eight and a half hours and the box has never run it | 3, and 1 undelivered instruction |
| 11 — the merging seat's charter has never said it merges | `prompts/pm-agent.md`, merged by the owner in #234 at 2026-10-23T15:26:22Z | **fixed, and now measurably so.** The seat merged ten pull requests tonight and carried a seventh file to `main` in a pull request of its own eleven minutes after being asked for it. The queue is 8 open, 5 of them independent decisions | 17 days, 1 charter |
| 12 — ten runs recorded as opening nothing | `ba763c7`, merged in #169 at 2026-10-18T08:17Z | **on `main` and not on the box**, six days on. Same blocker as 10, no second fix needed | 10 runs |
| 13 — the host filled to zero bytes mid-run | nothing shipped | **holding.** `df -h /` answers **26 GB of 45 used, 19 GB free** at 01:52Z, unchanged from 01:23Z. `/tmp` now holds **34** of this seat's and its partners' run clones. The fix belongs in `cli/src/run.js`, the engineer's surface, and would not run on the box either until 10 clears | 1 fired |
| 14 — a not-landing finding declined because its prose and its data named different sets | `docs/agents/landed.sh` and a charter patch | **closed on `main` in `ca62947`, holding under test.** Every number in this section and in tonight's five board messages is pasted from `landed.sh`, `order.sh` or `brief.sh` output | 1, +1 of the class |
| 15 — a third of the brief never reaches the seats it wakes | HQ `#379`, merged 01:24:32Z as `413e52c`, deployed to the host 01:27:15Z | **repaired upstream and deployed, eighty minutes after the handoff, and verified from here only in part.** `GET /api/brief` answers **nine named sections** and two composed lines now end in an ellipsis where four ended mid-word at 00:12Z. The marker on a real wake is **unverified**, because no `brief.sent` has fired since 00:07:01Z and the events route returns only the newest 200 rows — 58 minutes tonight — which is L41 and this run's own detector defect. **Closed when the next `brief.sent` makes `brief.sh` print "the cut is BY SECTION" with names.** Two more instances of the mechanism tonight, both on messages and both recoverable because that marker's pointer resolves: the centralizer's own `done` reached this seat as 1,486 of 2,271 characters and this seat read the rest in its inbox, and 17 of the 19 messages this seat posted today were over the wake | 2 briefs, 8 addressees each, +19 messages |
| 16 — a three-item handoff lost one of its two hands to a possessive | L37, the clause in `prompts/exo-agent.md`, and `docs/agents/addressed.sh` | **the detector is one merge from `main` on its own** — `epitome/pm` filed `#259` carrying it alone, `MERGEABLE`, ready, based on `main`, byte-identical to the copy on `#255` (`md5 48452e6c`). The charter clause is still in `#255` under her clock. **No second instance:** the audit at 01:43Z reads 18 distinct bodies from this seat today and still exactly one sent unchanged to more than one company, the 00:46:32Z original, and tonight's six bodies were run through `--body` before posting and passed | 1, 2nd of 14's class |
| 17 — a draft closed eighty-three seconds into its own seat's live run | L38, the second standing count in `prompts/exo-agent.md`, `addressed.sh --liveness` | **not on `main`, and the remaining exposure is now one ready pull request wide** rather than a clock: `#259` carries the instrument alone. **No second instance:** nothing has been closed unmerged since `#132` at 00:48:13Z. The hand that caused it has said in writing it will re-read a seat's newest run log before closing a pull request once that file is on `main` | 1 |

**The patch directory.** `bash docs/agents/check.sh` at 01:36Z: **5 of the 8 in
`ORDER` are already text in the charter they change**, **3 still apply**, all
three the project manager's, unchanged for three readings. All-time: **12 of 15
are text in the file they change, 3 of 15 remain diffs only, 0 of 15 have ever
merged as a diff.** The four stale engineer `.diff` files stay where they are
on this product's project manager's word at 00:48:55Z and 01:14:06Z.

**The queue, generated rather than typed, at 01:47:04Z against `main`
`47285cc` (L24).** **8 open**, 7 land in one pass, 1 needs a hand (`#261`,
conflicting in `prompts/engineer-agent.md`) —

`#250 · #253 · #255 · #256 · #258 · #259 · #260`

and **3 of the 8 are links in one chain**: `#253` inside `#255` inside `#258`
inside `#260`, all four this seat's. **Eight open is five independent
decisions for a merger.** Six open at 01:23Z and eight now, with ten merged in
between, so the arrival rate and the merge rate are both real tonight and
neither is the story the queue count tells on its own.

**One ordering fact the merger needs, measured and not reasoned.** `#259`
carries `docs/agents/addressed.sh` alone to `main`; this run edited that same
file on `#260` to add the wake-limit check. `git merge-tree --write-tree` on
this branch against `#259`'s head `d5f3abc6` **exits 1** on that one path,
because to `git` it is an addition against an addition; the same test between
`#255` and `#259` exits 0, because those two copies are byte-identical. So if
`#259` lands before `#255`, `#260` stops on one file and the resolution is to
take `#260`'s copy, which is `#259`'s blob plus the check. If the stack lands
first, nothing conflicts at all. Handed to `epitome/pm` with both orders.

**The second standing count: drafts whose run has ended. One, read at 01:48:12Z
from the footer and not from a date (L38).** `bash docs/agents/addressed.sh
--liveness` on every seat holding an open pull request:

| seat | pull request | newest run log | alive |
|---|---|---|---|
| `epitome-engineer` | `#250` **draft** | `2026-10-24T01-46-16-370Z` | **open** — but not the run that opened the draft at 2026-10-23T23:50:17Z, which has ended |
| `epitome-pm` | `#256` ready, `#259` ready | `2026-10-24T01-44-18-798Z` | open; the flag this seat named at 01:30Z is cleared |
| `epitome-market` | `#257` merged 01:42:57Z | `2026-10-24T01-42-59-749Z` | closed |
| `exo-centralizer` | `#261` ready | `2026-10-24T01-24-34-031Z` | open |
| `epitome-exo` | `#260` draft | `2026-10-24T01-33-39-751Z` | **open**: this run, readied before its last turn |

So `#250` is the one: opened last night, first in tonight's merge sequence,
and GitHub will refuse it while the flag is set. A run of that seat is alive
now, so this run named it to `epitome/engineer` directly at 01:51Z, because
clearing a draft is the author's act and no other seat can do it (L38). An
observation and not a proposal: the merge gate is the owner's.

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

## The two standing counts, 2026-10-24 12:15Z

Observations, never proposals: the merge gate is the owner's by design.

**The queue as she sees it, generated and not typed, measured at 12:15:29Z
against `main` `bac47cd` by `bash docs/agents/order.sh` (L24).** **11 open**,
oldest `#253` at **11 h 37 m**, 9 land in one pass, 2 need a hand — `#261` on
`prompts/engineer-agent.md` and `#269` on `docs/backlog.md`. The sequence:

`#253 · #255 · #258 · #260 · #265 · #267 · #270 · #271 · #272`

**Five of the 11 are one chain, so 11 open is 7 independent decisions.**
`#253` inside `#255` inside `#258` inside `#260`, and `#271` on top of
`#260`'s branch by its base rather than by containment, because `#260`'s head
moved at 12:06:31Z when `#264` merged into it and `#271` had already branched.
`order.sh` tests containment and so counts four links where a merger faces
five; the generated line and this sentence disagree, and the sentence is the
one with the base in it.

**The ordering fact, test-merged for real in throwaway worktrees at 12:15:29Z
and not reasoned about.** Both orders conflict, and they do not cost the same.
Chain first, then `#261`: one conflict, `prompts/engineer-agent.md`, a
both-sides keep. `#261` first, then the chain: **all five links** conflict on
that same file, and two of them also on `docs/agents/addressed.sh`. `#261`
alone onto `main` is clean, which is what makes the order a choice rather than
a blocker. Handed to `epitome/pm` at 12:17:46Z with both orders and the head
each was measured at.

**Drafts whose run has ended: none, read at 12:16:30Z from the footer and not
from a date (L38).** `bash docs/agents/addressed.sh --liveness` on every seat
holding an open pull request — `epitome-engineer` `11-46-07Z`,
`epitome-exo` `12-01-20Z`, `epitome-pm` `12-13-37Z`, `epitome-market`
`12-11-17Z`, `exo-centralizer` `11-59-00Z` — returns **open** for all five, no
`# exit=` footer on any of them. The two open drafts are `#270`, opened three
minutes into its seat's still-live run, and `#271`, this one.

**What this count caught this morning, and what happened to it.** At 01:48:12Z
the same count read one orphan. At 12:01Z the bus carried a different one to
this seat as the only thing that remembered it: `#264`, this seat's own, a
draft for ten hours with one complete commit in it and a body promising work
that run never did. It was not nothing, so the answer was to ready it rather
than close it. **Readied 12:03Z, body corrected to say what it actually held
and what it did not, merged by another hand at 12:06:31Z** — three and a half
minutes. The count is the only mechanism watching for this, and it is the
second time in twelve hours that it has moved something; both times the thing
it found belonged to the seat that runs the count.

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
