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

**Re-measured 2026-10-18T19:37Z, and the fix is now in the file.** The rate
held exactly as this entry predicted it would. Twenty-one passes of that seat
between 13:09:09Z and 19:33Z, one every eighteen minutes, each opening a pull
request and merging nothing; nine of the twenty-one are still open and twelve
were closed by later passes of the same seat. The queue went from 33 open pull
requests at 13:56Z to **43 at 19:37Z**, of which **19 land in one sequence with
no conflict and have no merger**. The two most recent declines name the reason
in its widest form yet — #231: the charter "grants the PM seat no merge
authority over other seats' pull requests" — which is the same faithful reading
this entry recorded at 13:09Z, six hours on.

What changed in this run is the carrier, not the words: the twelve lines of
`2026-10-18-pm-the-standard-is-the-charter` are now in `prompts/pm-agent.md`
itself, applied byte-identically with `git apply` from the diff, and the diff
is gone from `docs/agents/patches/`. It was the only one of the fifteen whose
route was her word rather than her silence (`routes.md`), so no running clock
was disturbed — the fourteen under the owner's 18:34Z ask are untouched and
`check.sh` confirms all fourteen still apply in `ORDER`'s sequence. HQ's ask of
13:53Z now has a merge at its far end instead of a hand this company does not
hold. **Still not shipped:** the merge itself, which no seat here may perform,
and the five other charters with no pointer to their role standard. Both stay
with `alexandra-systems/pm` on the open handoff. Lesson produced, and it is not
about the charter gap: **L30**, on applying a new route to the case already
stuck on it before applying it to your own file.

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

## Incident 13 — 2026-10-18 — The host filled to zero bytes mid-run, and 403 run clones nobody removes are what filled it

**Facts.** At 19:33:27Z this host's root filesystem, which is also `/tmp`, had
**57 MB free of 45 GB**. Three minutes later it had none: three tool calls in
this run failed with `ENOSPC`, one of them a `df` that could not write its own
output. `/tmp` held **403 directories named `epito-<seat>-<suffix>`**, the
per-run clone the runtime makes for a seat before its first turn, totalling
951 MB with the largest single one at 716 MB; **93 of the 403 had not been
written to in over six hours**. Removing the stale clones of this seat's own
earlier runs today — and only this seat's, matched by name and older than
ninety minutes — returned **2.0 GB** and the run continued.

**Impact.** A full box fails every seat on it, not the seat that filled it:
four companies' runs share this disk. In this run the cost was three lost tool
calls and a measurement taken twice. Nothing here is attributable to a seat:
every run on this host leaves a clone behind by design, and the runtime is the
only actor that could remove one.

**Root cause, in the system, and it is two mechanisms.** First, the runtime
clones the repository per run into `/tmp` and never removes the clone when the
run ends — a run's working directory outlives the run, and nothing on the box
sweeps them. Second, and this one is this register's own: `docs/agents/check.sh`
unshallows the clone it runs in, by design and correctly ("could not unshallow
— refusing rather than answering wrongly"), so every run of *this* seat
converts its shallow clone into a full one before it writes a line. The two
multiply: a seat that must have the whole history to answer honestly is the
seat whose leftovers are largest, and 2.0 GB of this box's pressure was this
seat's own dead clones.

**Fix shipped here, and what is not.** This entry, and the reclamation above,
which is a measurement and not a fix — tomorrow's runs will rebuild it. Not
shipped: the sweep. The clone is made before any seat's first turn, by the
runtime (`cli/src/run.js`), which is the engineer's surface and not this
seat's; a seat that deletes another seat's clone cannot tell a finished run
from a running one, which is why this run deleted only its own. Routed with
the not-landing handoff to `alexandra-systems/pm`, because it is one box under
four companies and the fix belongs where the clone is made.

**Not the same defect as incidents 5 and 9**, though it is the third entry on
the shared-`/tmp` axis. Those are collisions — two runs writing one path. This
is capacity, and #181, the unmerged fix for the collision class, would not have
prevented it: every window having its own scratch directory does not make
anything remove the directory afterwards.

**Lesson produced.** None. The rule is already L20's ("a fix is shipped when it
is on `main`") plus a sweep nobody has written; an entry here that said "clean
up after yourself" would be process rather than a rule a fresh-context seat can
apply.

## Open fixes, re-measured 2026-10-18 at 14:45Z

L20 obliges this seat to re-measure every entry whose fix is not on `main`, on
every run, and to count instances rather than entries. This section is
**replaced** each run and never appended to, so the register does not grow a row
per pass. Measured against `main` `2c8d56c` from an unshallowed clone.

| Incident | The fix | Where it is now | Instances |
|---|---|---|---|
| 5 — a run overwrote a partner seat's pull request body | #181 `77f94045`, also an ancestor of #190 | **ready, clean against `main`, still not on `main`** — two hours after it became mergeable. `ls -d /tmp/epito-* \| wc -l` answers **405** in this window, against 387 at 14:25Z, 166 at 14:04Z and 87 at 13:03Z. Neither `TMPDIR` nor `EPITO_SCRATCH` is set in this run either | 2 |
| 8 — a quarter of the day's runs were refused and the events thrown away | the entry and L18 are now on #211; the runtime half on #190 `37fa45de` | #190 is out of draft and green, and **it is not in the merge sequence**: it is contained whole by #186, a draft of the same seat, so a merger walking the queue in order merges #186 and #190 vanishes. Either #186 clears its flag and takes both, or #190 is merged before it. The refusal column at HQ still has no writer in this repository | 1 window, 0 since 14:00Z |
| 9 — the same shared path overwrote a board reply's references | same as 5 | same as 5 | 2 on the defect, 1 on the landing path |
| 10 — the runtime this company fixes is not the runtime it runs | nothing merged | **worse by one commit and now with a daily price.** `readlink -f $(which epito)` → `/srv/asc/repos/epitome/cli/src/index.js` at `5836dc0` of 2026-09-23, two files still hand-edited in place; `git rev-list --count 5836dc0..origin/main` = **366**. Incident 12 is what one of those 366 commits was worth in the two days it sat undeployed: ten misrecorded runs, eight of them after it merged | 2 |
| 11 — the merging seat's charter has never said it merges | the `pm-the-standard-is-the-charter` patch on #211, and an owner ask filed by HQ's project manager at 13:53Z | unchanged, and the shape of the queue is now the measurement: **30 of this repository's 37 open pull requests belong to that one seat**, every one a pass that read the queue and declined. This seat is down to two | 10+ passes, 1 charter |
| 12 — ten runs recorded as opening nothing | `ba763c7`, merged in #169 at 08:17Z | **on `main` and not on the box.** Same blocker as 10; no second fix is needed and no new patch is proposed for it | 10 runs, 5 triage passes |

**What this seat did to its own half of the queue this run.** It had six pull
requests open and now has two. #211 was test-merged against #192, #195, #197,
#204 and #208 one at a time in a throwaway worktree; each produced a tree
byte-identical to #211's, so all five were closed with that measurement on them.
#211 itself was a draft carrying a placeholder body, because the run that opened
it was killed at its turn cap before it could write one — incident 12's own
first row. It is out of draft with a real body now. Six pull requests claiming
one tree was this seat's contribution to exactly the queue it keeps measuring.

**The instrument dropped a line rather than printing it, which is the same
defect one scope down.** `order.sh` skipped any pull request already contained
by one merged above it, silently, so it printed 36 where `gh pr list` returns 37
and **#190 appeared nowhere** — the branch its author had, forty minutes
earlier, asked a merger to take. A reader could not tell a covered pull request
from one the instrument never saw. It now prints `covered already in #186` and
counts it, and the printed total matches `gh pr list` again. A record that omits
what it cannot classify is incident 12's mechanism with a different field in it.

**The queue, generated at 14:44Z against `main` `2c8d56c` (L24).** 37 open,
**17 land in one sequence with no conflict**, one covered, 19 needing a hand —

`#132 · #181 · #184 · #186 · #187 · #191 · #194 · #196 · #198 · #210 · #211 ·
#212 · #213 · #214 · #215 · #217 · #218`

Of the 19 that do not, **18 conflict in `docs/backlog.md` and nothing else**,
one of those also in `docs/ideas.md`, and #209 in a cycle file. Eleven of the
seventeen in the sequence are drafts, which no merger but their author can
clear. The not-landing half went to `alexandra-systems/pm` as this seat's
charter requires, with the order and the one decision only the owner can take,
rather than becoming a thirteenth entry here (L21).
