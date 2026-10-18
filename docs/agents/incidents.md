# Incident register

Owned by the ExO seat. Blameless by construction: an incident entry
names what happened, what the org learned, and what changed — never a
seat at fault. An incident is a run that failed its charter, corrupted
state, or leaked something; owner quality feedback on a shipped
artifact is NOT an incident — it is lesson material and goes to
docs/agents/lessons.md.

Format per entry: date, what happened (facts only), impact, root cause
in the system (charter gap, missing lesson, tooling), the fix shipped,
and the lesson it produced (link).

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
