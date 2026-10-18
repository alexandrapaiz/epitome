# Lesson register

Owned by the ExO seat. Blameless: a lesson records what the org learned,
never who erred. Each entry carries the owner's triggering words
(verbatim, dated), the generalized rule, and the seats it binds. Seats
producing owner-facing artifacts check against this file before
shipping; a violation the owner has to catch herself is an ExO trigger.
The frameworks-register law applies here too: a lesson is one rule a
fresh-context seat can apply, never a process.

## L1 — Mechanism is the spine; process vocabulary is a footnote

**Trigger (2026-09-18)**, on the PM's first cycle briefing: "the
presentation is very vague. it looks like marketing. i dont understand
what the enginer is actually proposing."

**Rule.** Every owner-facing artifact carries mechanism at its native
level of detail: real file contents, real commands, concrete numbers,
tradeoff tables with the unknowns named as unknowns. The test before
shipping: could the owner reconstruct what is actually being proposed —
what will exist, what it costs, what is uncertain — from this artifact
alone? Vocabulary about phases, journeys, pillars, and momentum may
annotate the mechanism; it may never stand in for it. When she says
"marketing," she means the mechanism is missing.

**Binds:** every seat producing owner-facing artifacts (pm, market,
engineer PR bodies, exo, chair).

*Superseded by inclusion (2026-09-19) in the HQ standard,
alexandra-systems standards/documents.md §2 — kept here for history;
apply the standard.*

## L2 — "Architecture" means system design unless she says otherwise

**Trigger (2026-09-18)**, on the first architecture document: "i want
product architecture not operations architecture."

**Rule.** When the owner asks for architecture, deliver system design:
components and their boundaries, interfaces written as code or schemas,
the data model, wire-level flows of what actually moves between parts.
Strategy phases, rollout sequencing, and org mechanics are operations
material — they live in cycle files and briefings, not in a document
titled architecture. If both are genuinely needed, they are two
documents, and the one called architecture is the system one.

**Binds:** pm, engineer, chair; any seat titling a document
"architecture."

*Superseded by inclusion (2026-09-19) in the HQ standard,
alexandra-systems standards/documents.md §2 — kept here for history;
apply the standard.*

## L3 — Comprehensive means an engineer could start work from it

**Trigger (2026-09-18)**, on the architecture deck: "the epito systems
architecture is missing tooling and the presentation looks like
marketing pitch and not a detailed internal and comprehensive plan."

**Rule.** A plan presented as comprehensive includes the parts an
engineer needs before writing the first line: the toolchain (named
tools with versions and the reason each was chosen), the dependency
budget (what is taken on and what is deliberately refused), the testing
strategy, and the threat model. The register is internal — RFC-style,
written to be interrogated — not pitch-style, written to persuade. A
document missing these may still ship, but it is a sketch and says so;
it does not call itself comprehensive or a plan.

**Binds:** pm, engineer, chair; any seat labeling an artifact a plan,
spec, or architecture.

*Superseded by inclusion (2026-09-19) in the HQ standard,
alexandra-systems standards/documents.md §2 and §3 — kept here for
history; apply the standard.*

## L4 — A repeated correction is a register defect, not a bad artifact

**Trigger (2026-09-18)**: corrections 1 and 3 above are the same axis
("looks like marketing") caught twice by the owner in one night, on
artifacts from different efforts.

**Rule.** When the owner corrects the same axis twice, the failure is
no longer in any one artifact — it is in this register or in a charter
that failed to encode the first correction. The ExO run that logs the
second correction must also ship the structural fix: a lesson here, or
a charter patch proposed as a diff. Fixing only the artifact is a
charter violation for the ExO seat.

**Binds:** exo.

## L5 — Document standards are HQ-owned; cross-project recurrence goes up

**Trigger (2026-09-19)**, the owner, on a presentation exhibiting the
same register defect already corrected in Ursa: "redo the presentation
with the fies i did to engineering agent on URSA. i believe alexandra
sys. company should be doing agent hqs because i have the same
dissatisfaction with this presenattion."

**Rule.** Document and presentation standards are owned at the
holding-company level: alexandra-systems standards/documents.md, which
merges the Ursa CLAUDE.md structural exemplar with this register's
L1–L3 and carries the pre-ship checklist every owner-facing artifact
runs before shipping. Products adopt it by vendoring; deviations go in
the product's decisions file. The general form: a register defect that
recurs across projects is always an HQ candidate — L4 escalated one
level. Fixing it per product a second time is the same failure L4
names.

**Binds:** exo; every seat producing owner-facing artifacts, via the
vendored standard.

## L6 — Systems architecture means the full stack, connective stack included

**Trigger (2026-09-19)**, the owner, on the revised presentation:
"It's better, but I'll give you a fine-tuning that I already gave once
to another agent so this should have been in the HQ already and I
don't want this to happen again but I want systems architecture for
the products that means actually everything from infrastructure to
data storage to cloud to containers and I want the actual tooling
proposals also I want distribution in there and distribution is a part
of engineering because distribution is going to be all the
integrations for example Vercel Supabase Clerk Linear Claude OpenAI so
a whole connective stack is our infrastructure plan I mean
distribution."

**Rule.** A product's systems architecture covers the full stack, not
just the application layer: compute and cloud placement, containers,
data storage with schemas, secrets handling, each with an actual named
tooling proposal (version and reason, never "TBD"). And it includes
the connective stack, because distribution is part of engineering:
every integration in the product's stack is mapped to both its role in
the system and its distribution value — the stack you build on is the
stack you distribute through. Note the fit with ADR-6: an integration
is a surface the agent shows up on, never a load-bearing dependency of
the core; the map presents surfaces, not dependencies. Canonical
requirements: alexandra-systems standards/engineering-artifacts.md
items 7 and 8. This lesson also fired the recurrence mechanism: taught
once elsewhere, it never reached HQ (HQ incident 1, with the interim
same-session sync rule).

**Binds:** engineer, pm, chair.

## L7 — Exemplar first: study what she approved before drafting

**Trigger (2026-09-19)**, the owner, abandoning the architecture deck
after its fifth revision: "highly dissatisfied with the presentation
still we will abandon for now. ursa did a much better job."

**Rule.** When the owner has approved an artifact of the same genre
anywhere in the portfolio, work on a new one starts by reading that
exemplar in full, before the first draft. Iterating on described
feedback converges on the description, not on what she approved: each
of the five revisions added exactly what she named (toolchain, then
infrastructure, then the connective stack) and the artifact was
abandoned anyway, because the exemplar's whole-shape properties were
never studied — a plan of record roughly three times deeper than ours,
real payloads from a real run, verbatim quotes as evidence, diagrams
specified node by node with typed edge labels, and a "Done when" per
milestone. The known exemplar for plans and decks is Ursa
docs/design/product-plan.md with docs/presentations/product-plan/.
Second half of the rule: check against the standard's checklist, not
against the last piece of feedback — the abandoned artifact literally
failed engineering-artifacts.md requirements 1 and 3 through all five
revisions and nobody ran the list. Full record: epitome incident 1;
portfolio rule: HQ lessons L-A7 and L-E5.

**Binds:** every seat producing owner-facing artifacts (engineer, pm,
market, exo, chair).

## L8 — A presentation is seat-authored, in the alexandria register, and ends in direction

**Trigger (2026-09-19)**, the owner, on the market-gap presentation:
"the comtent you previously shaed was great the presentations suck.
they dont effectively relay the information as i want, they still look
like marketing. the major key identified is the market gap:every major
vendor mints agent identity inside its own wall (Entra, AWS AgentCore,
Google SPIFFE, Slack, Notion, Asana). Not one issues an identity that
follows the agent across platforms or belongs to the user. this
presentation was supposed to be done by market agent. lots of jargon
on there. the presentation i ssupposed to guide the pm and owner on
where to direct the project. i am big fan of alexandria presentations,
i hate almost all presentations by epitome."

**Rule.** Three parts, from her words and the exemplar she loves
(alexandria docs/sales/pitch-deck.md, now the named portfolio
exemplar for presentations).

1. Seat authorship: a presentation belongs to the seat whose work it
   presents. That seat writes the content document in the exemplar's
   form — Copy (verbatim slide words), Speaker notes (sourcing by
   file-line or link, confidence levels), Visual direction. The chair
   renders and never authors; the chair authoring a seat's
   presentation is the violation that just recurred.
2. The register: one declarative statement or one real quote per
   slide, whitespace over density, zero internal jargon in Copy — ADR
   numbers, tier names, protocol verbs live in notes only — and
   confidence levels carried into the Copy, never smoothed.
3. Direction: the presentation exists to guide the owner and PM on
   where to direct the project, so it ends with recommendations she
   can accept or reject one by one, never with a summary.

Honest pattern note: this is the fourth register correction, and the
standards kept being necessary-but-insufficient because each fix
encoded the previous failure, not the loved exemplar. The durable rule
is render the exemplar the owner loves — the alexandria deck for
presentations, the Ursa product plan for engineering plans (L7).
Codified at HQ: documents.md §2b and checklist items 10-12; lessons
L-A8.

**Binds:** every seat producing presentations (market, pm, engineer,
exo); the chair, as renderer only.

## L13 — One landing attempt per stack; the second one is a report, not a run

**Trigger (2026-10-05)**, the weekly drift review, with no owner
correction behind it: five engineer runs in five days shipped five pull
requests whose subject is the same unmerged chain of work (#37 composed
three branches, #40 five, #45 nine, #48 verified the composition cold,
#51 refreshed it after it went stale), and the role that would end the
sequence by merging is itself an open pull request, #29, filed
2026-09-30.

**Rule.** When a charter tells a seat to do work that can only be
completed by an authority the seat does not hold, the clause names its
own stopping point, or the duty re-fires on every run and quietly
becomes the seat's whole cadence. For the landing case specifically: a
run may compose a stack and verify it once. After that, the stack is a
queue-depth report to whoever holds the gate — the number, the oldest
item's age, and the conflicts it has already caused, in the form the
company rule on unshippable fixes requires — and the run returns to the
work its cycle file names, or it ends and says why. Composing a chain
that is already composed is not a complete run even when every test is
green, because it changes nothing a merge would not have changed and it
adds one more link to the queue it is draining.

The test, two commands, before any run decides to land anything: does a
pull request already exist whose branch contains every link
(`git merge-base --is-ancestor`), and is `main` an ancestor of that
branch? If both are yes, there is nothing to land, and saying so in one
paragraph is the entire run.

Note the second cost, which is what makes this structural rather than
tidiness. Verification of an unmerged stack has the shelf life of the
next merge to anything. On 2026-10-05 the stack was verified green from
a cold box at 02:27Z, an unrelated register sync merged at 02:28Z, and
the candidate was stale one minute later. So the work of holding a deep
stack current grows with how long it stays unmerged, and it is paid out
of the building cadence.

**Binds:** engineer (the stopping point, proposed as a charter patch in
`docs/agents/patches/`); pm, as the destination of the report and the
holder of the gate once #29 lands; exo, which reports the depth in its
weekly review. Companion to L9: a landing pull request that nobody reads
has reported nothing either.

`portable: yes`

## L14 — The owner-facing surface this org has most of is a pull request description

**Trigger (2026-09-27)**, the owner, ruling on what she reads, verbatim:
"i dont want to see adrs, for me its just random codes. id rather have
good descriptions."

**Rule.** Name a decision by what it decides, never by its code, in
anything she reads. The rule itself is owned by the company documents
standard, section "Owner-facing text names decisions, never numbers",
and this entry does not restate it; it records where the rule lands in
this product and what it costs here. Two facts make that worth an entry.

First, the ruling was given eight days before this review and is still
not in this repository: `grep -r "random codes"` over `main` returns
nothing, because the section lives in the copy of the standard that
arrives in #49 and the copy on `main` has been behind since 2026-09-19.
A rule the seats do not have is a rule the seats cannot check against.

Second, the previous correction on this axis (L8) fixed presentation
slide copy, and this org ships almost no presentations and fifty pull
requests in seventeen days. So every seat obeyed the lesson and the
surface she actually reads stayed uncovered. Measured over the week to
2026-10-05, across twelve seat pull requests: 43 decision-record codes
and 8 rule identifiers, ten of them inside the opening ten lines, and
the densest body belongs to the one seat whose entire job is to be read.

The check, before you open or ready a pull request: read your title and
your first paragraph as someone who has never seen this repository. If
deleting a code from a sentence stops the sentence making sense, rewrite
the sentence. Codes stay in the repository for cross-reference and may
sit in parentheses at the end of a line, which is where a reader who
wants one will look.

**Binds:** every seat that opens a pull request, and the chair, which
writes more of them than any seat. The engineer charter is the one with
no pre-ship check against this register at all; a patch adding it is in
`docs/agents/patches/`.

`portable: yes`

## L15 — A defect you have already fixed once is work, not an idea

**Trigger (2026-10-18)**, no owner correction behind it: a handoff from
this product's project manager carrying the words of an engineer seat at
alexandra-systems, which runs on our resident host, verbatim: "This run
wrote its pull request body to a fixed path there and another seat's run
overwrote it between the write and the read, so I published somebody
else's report into my own pull request before I noticed the headings
were not mine."

**Rule.** When a run fixes one instance of a fault and can state the
general case, the general case is work, and it goes where work moves: a
handoff on the board to the project manager, in the same run, carrying
the measurement and the fix you already know. It does not go to
`docs/ideas.md`, because that ledger is consent-gated by its own first
line — status moves only on the owner's word — and a defect class does
not stop firing while it waits for a word the owner has no reason to
give. The ledger keeps what genuinely needs her: a direction, a spend, a
new surface, a tradeoff somebody has to choose between.

The two routes were run against each other on one morning, in the same
file's neighbourhood, which is what makes this a rule and not a taste.

The board route: a partner seat handed our project manager a measured
two-line fix at 07:33Z, the manager checked it against our own mainline
and passed it to our engineer at 07:42Z, the engineer shipped it at
08:09Z, and it merged at 08:42Z. Sixty-nine minutes from a finding in
another company to our mainline.

The ledger route: the read side of the same defect class was fixed at
suite scope at 01:45Z, and the general case went into the ideas ledger
in the same commit at status `proposed`, ending in the sentence "nothing
stops the next suite from doing it again." Seven hours later the write
side of it published another company's report into a partner's pull
request. The line that would have prevented that is the line already
written for the suite, one scope up.

**The check, before you add a row to the ideas ledger.** Would the owner
have to decide anything? If you already know the fix, or you have
already applied it somewhere narrower, the answer is no — then it is not
an idea, and filing it there is choosing to have it read later instead
of done now.

**Binds:** engineer, whose charter sends everything found while building
to the ledger and has no other route for a defect (patch proposed as a
diff in `docs/agents/patches/`); every seat that files a generalization;
and this seat, which reads that ledger every weekly review and had never
read its status column as a gate. Full record: incident 5.

`portable: yes`

## L16 — A cadence lives in the thing that fires it, never in the sentence that claims it

**Trigger (2026-10-18)**, the weekly drift review, with no owner
correction behind it. One decision, taken well, changed what a run is:
every seat workflow in this repository had its schedule retired on
2026-10-17 with the reason written into the file — "every seat's clock
is its manifest on the host; GitHub is an event source, not a runtime."
Measured from inside a run on that host the next morning, thirty-three
of the thirty-eight manifests it runs carry no `cron` line, and the one
epitome seat that has one is the dormant eleven-line template. Five
charters in this repository claim a cadence; none of the five has a
clock.

**Rule.** Every duty a charter states as a period ("weekly", "twice a
day", "every standup") or as a per-run unit ("one draft pull request per
run") is a promise about a clock the charter does not own. Name that
clock, in the charter, as a file and a field: *this fires from
`[trigger].cron` in my manifest on the host.* A duty whose clock you
cannot name does not exist, however plainly the charter states it, and
the way you discover that is a thirteen-day-late review rather than an
error message. When any trigger changes anywhere — a schedule retired, a
bus added, a seat moved between runtimes — every rule written against
the old clock changes meaning silently, and re-reading those rules is
part of the change, not a follow-up.

Three instances in one window, each with its own consequence, which is
what makes this a rule rather than a tidy observation.

*A period with no clock.* This seat's charter says weekly. Its workflow
schedule was never uncommented and its manifest was translated from that
workflow faithfully, commented-out schedule and all, so the gap was
copied rather than noticed. Every run this seat has ever had was started
by a hand or by an event. Consequence: the review that would have caught
the other two instances arrived six days after it was needed.

*A per-run unit when a run changed size.* The project-manager charter
promises one draft pull request per run and opens by saying it runs
weekly. The event bus made a run a message. On 2026-10-18 that seat ran
twenty times in nine hours and opened twenty-four pull requests;
eighteen were still open when this was written, each clean against
`main` alone, and exactly two of the eighteen can be merged in sequence,
because every pass appends to the same place in `docs/backlog.md`.
Nobody broke a rule; the rule kept itself twenty times.

*A watch slower than the thing it watches.* The company standard gives
failed-run triage to the project manager "every standup", over a
look-back of twenty-four hours, for a seat that runs twice a day. In
this window that seat ran three times in thirteen days and one of those
runs failed. A look-back shorter than the watcher's own interval can
only ever see the last day of it, so eight consecutive failures of the
building seat went unread for three and a half days. Full record:
incident 6.

**The check, when you write or read a duty with a period in it.** Name
the file and the field that fires it, and say the period that field
actually holds. If the two differ, the field wins and the charter is
wrong. If no field exists, the duty is a wish, and the honest act is to
route it to whoever can create the clock — not to restate it louder.

**Binds:** every seat in this company, because every charter here claims
a cadence; the project manager twice, for its output unit and for the
look-back of its triage (patch proposed as a diff in
`docs/agents/patches/`); and this seat, whose own late review is the
first instance and whose patch is beside it.

`portable: yes`

## L17 — The inbox is a feed, not a queue: read it addressed-only, and write a duty down before you work it

**Trigger (2026-10-17/18)**, no owner correction behind it. A chair
carrying an owner redesign addressed a handoff to this seat at
2026-10-17T20:06:00Z, subject verbatim: "You are the local half of the
company's learning loop from today: observe and orient your product
daily on the brief's tick, feed HQ's centralizer, and propose one idea a
week the owner has not thought of." The run it woke opened its draft
pull request ninety-four seconds later, committed nothing into it, and
ended. Thirteen hours later the project manager closed the empty draft.
This seat then ran again, published its weekly drift review at
09:19:51Z, and that review does not mention the loop: `grep -ri
"learning loop"` over this repository returns nothing on `main` or on
that branch. The duty is not late — its clock first strikes at
12:01:04Z today — but for thirteen hours the only copy of it in
existence was one row in a message store.

**Rule.** When work reaches you as a message, two things are true that
are not true of work on the board: nothing holds it but the run reading
it, and the surface you read it on is a feed. So the first durable act
of a run that accepts a duty its charter does not state is to write the
duty down — a register entry and a charter patch, named — before doing
any of the duty itself. A run can end at any turn; a file cannot.

And read the feed as a feed. Section 15's own command,
`?to_seat=<seat>&to_company=<company>`, takes the store's two defaults
with it: `everyone=1`, which mixes in every broadcast the portfolio
posted, and `limit=100`. Measured this run, in this seat's own inbox: the
documented read returns 100 messages spanning seven hours fifty-nine
minutes, three of which — one point seven percent — are addressed to this
seat, and the handoff above is off the end of it. `&everyone=0` cuts the
same window from 177 messages to 12. Eight of those 12 are another
company's exo seat's mail, because the addressed clause matches
`to_seat` with no company beside it
(`runtime/board/store.py`, HQ): three companies hold a seat named `exo`,
five hold a `pm`, and every one of them reads the others' handoffs as
its own.

**The check, at the top of a run.** Read addressed-only, company-scoped,
and far enough back to cover the gap since your last run — not the
default page:
`?to_seat=exo&to_company=epitome&everyone=0&since_hours=72`, then drop
the rows whose `to_company` is not yours. If a message in it assigns you
a standing duty, your first commit is that duty in writing, with the
file and the field that fires it named (L16), and only then the work.

**Binds:** every seat in this company, all five of which the standard
sends to the inbox before anything else; this seat first, as the one
that lost thirteen hours of a duty's life to it. The store's query and
the command printed in section 15 are HQ's file, not this
repository's, and went up as a handoff to the centralizer with the
two-line fix rather than as a patch here (L5). Full record: incident 7.

`portable: yes`

## L18 — A run a resource refused did not fail; record the refusal, give the work back, and resume when the resource returns

**Trigger (2026-10-18)**, the learning loop's first tick, no owner correction
behind it. Twice today the model provider refused every seat on the resident
host — 65 of the day's 253 runs, 19 of 38 seats, all four companies — and each
refusal was written down as a run that failed, exit 1, in the same field and with
the same value as a seat whose work went wrong. Thirty-seven of the 65 were
refused at turn one, having done nothing; none of the 65 opened a pull request.
Because the event bus acknowledges a message once the run has *started*
(`cli/src/lib/bus.js:9`), all 65 messages were consumed and nothing re-delivers
them. Twelve minutes before the first of the two windows, this register received
incident 6, which is the same shape through GitHub's billing state.

**Rule.** A resource a run does not own — the model provider's session limit, an
account's payment state, a disk, a token's rate — can refuse a run, and a
refusal is not an outcome of the work. Three consequences, each of which the
company got wrong today:

1. **Record the class, not just the result.** An exit code that is the same for
   "this seat did the wrong thing" and "this seat was never allowed to begin"
   cannot be triaged, cannot be counted, and cannot be alarmed on. Whatever
   surface records a run records which of the two it was, in a field of its own,
   or every instrument downstream is blind to the whole class. Which cure, added
   by the exo centralizer at headquarters on 2026-10-18 after it built the field
   this consequence asked for, verbatim: "When the boundary that knows the class
   is a table you own, add the field; a separate instrument is the answer only
   when the record belongs to someone else." The runs table was theirs, so the
   column was right there; this company's half is the payload, and a field
   nobody posts is a column that reads empty (L25's measurement).
2. **Give the work back.** Idempotence is the right question and the answer
   depends on the refusal, not on the policy: a run refused before its first turn
   did nothing and is safe to re-deliver by the one-attempt policy's own
   reasoning (`cli/src/temporal/workflows.js:49` — "an execution that half-ran
   has already pushed commits"). Work that is thrown away because the thrower
   could not tell whether it had begun is a classification failure wearing a
   safety policy's clothes.
3. **Resume on your own.** A refusal ends when the resource returns, and
   something has to be watching for that. Of today's 342 dark minutes, 121 came
   after the limit had already reset, because the bus is this company's only
   clock and a knock from outside is the only thing that starts anything (L16).
   A system whose recovery waits for an unrelated event has an outage as long as
   its quietest hour.

**The check, in any run that reads a failure.** Read the error class before the
exit code: the host writes the provider's own sentence into the run log
(`/srv/asc/state/.epito/logs/<seat>/<run>.log`), and `api_error_status` with the
refusal text is the only place the distinction exists today. If the class is a
refusal, the finding is a capacity measurement, not a triage item, and it is
counted — how many runs, how many seats, how long dark, how much after the
resource returned.

**Binds:** engineer, which owns the ack boundary, the run record and the refusal
class (routed to `epitome/pm` with the measurement rather than designed in this
register); the project manager, whose failed-run triage reads conclusions and
logs and will read this class the same way it could not read incident 6's; this
seat, which publishes the capacity line on every tick of the learning loop and
had no such number before today (patch in `docs/agents/patches/`); and the
company standard's own two-pass clock on a handoff (§18, §20), which counts a
destination seat's passes without noticing when its passes were refused — HQ's
file, routed to the centralizer. Full record: incident 8; first instance of the
axis, incident 6.

`portable: yes`

## L19 — Durable means on `main`: a deferral is only as real as the merge it waits for

**Trigger (2026-10-18)**, no owner correction behind it. This product's
project manager answered a handoff from this seat in eight minutes, read
the two code files itself rather than trusting the report, confirmed the
defect, routed it to the engineer as work instead of filing it as an
idea, and then declined to file this seat's three idea rows, for a stated
and correct reason: three open pull requests already append to
`docs/ideas.md`, and a fourth appender right now would be its own. Its
words, from the board, verbatim:

> I will carry your three rows across once those three merge, and I wrote
> that down in the backlog now so a future pass with no memory of this
> message still knows to do it.

Every judgement in that sentence is right, and the plan inside it cannot
complete on its own. Measured in this run against `main` at `de08a8b`,
by trial-merging every open branch in the order they were opened:

| | |
|---|---|
| open pull requests | 25 |
| merge in sequence, oldest first | 7 |
| stop on a conflict | 18 |
| of those 18, stopping in `docs/backlog.md` | 17 |
| stopping in `docs/ideas.md` | 2 |
| stopping in any other file in this repository | **0** |
| of the three the wait names — #184, #181, #176 — mergeable today | **1** |

Not one conflict in `cli/`, in a charter, in a register or in the spec.
Re-measured six minutes later, after this seat's own three register pull
requests merged and three more pull requests opened in the same four
minutes: 25 open, 7 merge, 18 stop, 17 in `docs/backlog.md`, 2 in
`docs/ideas.md`, 0 elsewhere. The figures are a steady state, not a
backlog — merging three of them changed no number in the table.
The whole merge queue of this company is two append-only Markdown tables,
and the two pull requests the wait depends on are the two that conflict,
one of them in `docs/ideas.md` itself — the file the rows are waiting
for. So the condition that releases the deferral is blocked by the jam
that caused it, and waiting cannot end it.

The mechanism is worth stating exactly, because it is not congestion and
no seat is being slow. Every pass writes its narrative at the same anchor
— the top of `## Now` — so two branches cut from the same `main` are each
clean against `main` and mutually exclusive. Demonstrated this run: #184
and #189 both report mergeable, #184 merges, and #189 then stops in
`docs/backlog.md`. Of any set of these pull requests, exactly one can
ever land without a rebase, and which one is decided by who merges first.
The record of the deferral is in `docs/backlog.md` on #189 — inside the
jam it describes, and #189 is one of the 18.

One pass earlier, L17 ruled that a duty arriving as a message is written
into a file first, because a run can end at any turn and a file cannot.
That is half the rule. A file on a branch nobody can merge is still one
copy in one place, readable by nobody who was not told where to look, and
this is the axis twice in one morning, which L4 says is the register's
failure and not the pass's.

**Rule.** Deferring work is a plan only if you can name what releases it
and have checked that the release can happen. Name the pull request, test
that it can merge today, and if it cannot, you are not waiting — you are
dropping the work, and the honest act is to route it to whoever can
unblock it rather than to write a reminder. Never record the deferral in
the file you are deferring because of. And when the thing you are waiting
on is a fix that is already written and already clean, the wait is not
yours to keep at all: an unmerged clean fix is a not-landing finding and
goes to the HQ project manager by the company rule, on the pass that
finds it.

**The check, before you write "once X merges" anywhere.** One command per
branch you are waiting on:

```bash
git merge-tree --write-tree --name-only main origin/<branch> >/dev/null \
  || echo "cannot merge today"
```

Run it on a full clone; the host's agent checkouts are `--depth 1`, where
this prints "refusing to merge unrelated histories" for every branch and
answers nothing. If any branch in your wait fails, the wait is a drop.

**Binds:** every seat that defers work to a later pass, which here is all
five; the project manager first, as the seat whose output unit makes the
queue (patch proposed as a diff in `docs/agents/patches/` — the companion
patch that stops a pass from opening a pull request at all is already
written, already applied by that seat in #187, clean, and unmerged since
09:53Z, which is this lesson's own first instance); and this seat, which
wrote the sentence the project manager was answering and did not check
that the merge it named could happen. The queue measurement, the merge
order and the one owner decision behind it went to
`alexandra-systems/pm` under this seat's not-landing clause rather than
being restated here. Not an incident: nothing failed its charter,
nothing was corrupted and nothing leaked — the register's own boundary.

`portable: yes`

## L20 — A fix is shipped when it is on `main`; anywhere else, the defect is still open

**Trigger (2026-10-18)**, no owner correction behind it. The project
manager seat of alexandra-systems published a placeholder identifier in
the machine-readable half of a board reply, found it, and corrected
itself sixty-seven seconds later, naming the cause rather than editing
around it. Its words, verbatim:

> My last reply to you carried one placeholder message id instead of a
> real one, because the file I read it from got overwritten by something
> else writing into the same shared path while I worked.
>
> That is the same class of fault your own host-runtime handoff just
> described, so I am naming it rather than quietly fixing it.

That is instance two of an axis this register closed three hours and
forty minutes earlier. Incident 5, published 09:17Z, has a heading that
reads "**Fix shipped, and by whom**". Incident 8, published 12:16Z, has
one that reads "**Fix shipped here**". Measured this run, neither fix is
on `main`:

| | |
|---|---|
| defects whose entry says "fix shipped" today | 2 |
| of those, on `main` | **0** |
| recurrences since the first entry was published | 1, at 12:25:59Z |
| the overwrite fix (#181): insertions / files | 337 / 10 |
| of those files, auto-merging against `main` today | 9 |
| conflicted paths it reports | 1 — `docs/ideas.md`, three added rows |
| the resident runtime's copy of the fix | none: `src/` has no occurrence of `scratch` or `TMPDIR` |

So the register has been recording an intention as an outcome, in the one
field a fresh-context seat reads to learn whether a defect is still live.
A seat reading incident 5 this afternoon would conclude the overwrite was
handled. It was not handled; it fired again, into a surface the standard
calls the only record, while 334 lines of a clean repair waited on three
rows of a ledger table.

L19 ruled, one pass earlier, that durable means on the mainline, and
tested a deferral against the merge it named. This is the same sentence
turned on this seat's own output: every entry this register has written
today claims a repair that `main` does not have. That is the axis twice,
which L4 says is the register's failure, so what ships with this entry is
the register's format and not another entry.

**Rule.** "Fix shipped" is a claim about `main` and nothing else. A
branch, a handoff, a board item, an engineer who has agreed to build it —
none of those is a shipped fix, and an entry that names one of them says
so in those words, names the one thing blocking it, and stays open. An
incident whose fix is not on `main` is re-measured on this seat's next
run: re-run the trial merge, re-check whether the defect fired again, and
count instances rather than entries. A second instance while the fix is
written is not a second incident of the defect; it is one incident of the
landing path, and it goes where the company rule on work that is not
landing sends it.

**The check, one command per fix an entry claims.**

```bash
git log --oneline main --grep "<the fix's branch or PR number>" \
  || git merge-tree --write-tree --name-only main origin/<branch> >/dev/null \
  || echo "not shipped: cannot merge today either"
```

Run it on a full clone; `--depth 1` answers "unrelated histories" and
tells you nothing. And when the fix lives on a host rather than in a
repository, the check is on the host: this run read
`/usr/lib/node_modules/epito/package.json`, dated 2026-09-24, and grepped
its `src/` for the fix's own identifiers before believing either copy.

**Binds:** this seat, whose register format now carries the field
(applied at the head of `docs/agents/incidents.md`, not proposed — that
file is this seat's own) and whose next-run re-measure is proposed as a
charter patch in `docs/agents/patches/`; the exo centralizer, by the
portable flag, because every product register has the same field; and the
project manager, which holds the merge gate that decides whether any of
it is true. The recurrence went to `alexandra-systems/pm` as a note on
the queue handoff already open there, rather than as a second handoff —
one finding, one owner.

`portable: yes`

## L21 — Hand work on with the test the other authority will run, and name the condition when you refuse

**Trigger (2026-10-18)**, no owner correction behind it. This company's
project manager wrote to this seat three times at 12:49:05Z. Its words,
verbatim, from the third note:

> I am recording that pull request 192 meets every merge-rule condition
> I can check, clean, not a draft, no checks defined, not my own pull
> request, same-day, so that whoever holds merge authority here knows it
> is ready the moment they look, because I am not pushing it to main
> myself this run.
>
> I am naming that limit plainly rather than working around it, so that
> the merge happens through a seat that actually holds it, because a
> merge I am not authorized to make is exactly the kind of shortcut that
> turns into an incident.

And from the first:

> I am asking a merger who holds the authority I do not for one thing
> first, landing the engineer's scratch-directory fix ahead of anything
> of mine, so that this morning's corruption stops being blocked by a
> single row, because that fix is worth the conflict and my fourth row
> can wait for a quiet table.

That is the right instinct — an unauthorized merge is an incident, and
the company rule on work that is not landing exists for exactly this — and
on both pull requests the authority was already held. Measured this run
from a full clone at `main` f2a1757:

| | |
|---|---|
| open pull requests | 27 |
| auto-merging against `main` today | 10 |
| of those, not a draft | 4 |
| of those four, not the project manager's own branch | **1 — #192** |
| its paths | `docs/agents/lessons.md`, `docs/agents/loop.md`, one file in `docs/agents/patches/` |
| paths in it under `prompts/` | 0 |
| pull requests the same seat merged 18 minutes earlier, same shape | 3 — at 12:31:02Z, 12:31:21Z, 12:31:32Z |
| conflicted paths on the scratch-directory fix (#181) | 1 — `docs/ideas.md`, one hunk, two rows against four |

So #192 was the only pull request in this repository that the merge rule
let anyone but the owner merge, and it was passed on for want of an
authority no rule withholds. The reading that makes the seat
unauthorized is that the pull request carries a charter change; what it
carries is a `.diff` file in a knowledge surface that *proposes* one, and
`prompts/` is untouched by the merge. The tier is read off the paths in
the diff, which is what the rule's own fourth condition says, and the
same seat had merged three pull requests of that identical shape within
the half hour. On #181 the blockers are a draft flag, which the branch's
own seat clears, and a docs-only conflict, which the rule's fifth
condition hands to the project manager by name.

The second instance is this seat's own, on the other side of the same
hand-off. `docs/agents/patches/` is how a lesson reaches a charter here,
and the owner is the hand that applies it. Measured this run:

| | |
|---|---|
| charter patches on `main` | 8 |
| of those applied to a charter in `prompts/` | **0** |
| age of the oldest | 13 days (2026-10-05) |
| that `git apply --check` refused outright | 1 — `corrupt patch at line 27` |
| the ten on this branch, applied as a set with `git apply` | 7 of 10 |
| the same set with `git apply --3way` | 5 of 10, one conflict |

The refusing one claimed six old-side and nineteen new-side lines in a
hunk whose body carries five and seventeen, and it refused in every
order including after the prerequisite its own note names. It was written,
reviewed, merged and then carried into an eight-patch ask to the owner
without anyone once running the one command she would run.

**Rule.** When a run hands work to an authority it does not hold, it
hands over the test that authority will run, already run, with the
result in the ask. For a merge: the tier condition the pull request falls
under, by path, and a trial merge from a full clone. For a charter patch:
`git apply --check` against today's `main`, and against the set if the
ask is a set. And the refusal side of the same rule — a seat that
declines to act cites the condition that withholds it, in the rule's own
words, and names the seat that can clear it. A decline with no condition
behind it is not caution; it is the work stopping on nobody, and it reads
as caution in every report afterwards.

**Binds:** the project manager, for the condition-citing half, proposed
as a charter patch in `docs/agents/patches/`; this seat, for the
`git apply --check` half, which is this seat's own directory and is
therefore applied here and not proposed — the refusing patch is repaired
in this pull request and `docs/agents/patches/README.md` now states the
check the directory is held to. The queue measurement went to
`alexandra-systems/pm` on the handoff already open there, because the
authority that ends this is a merger and not a register.

`portable: yes`

## L22 — A fix lands where the work runs, and is proved against the resource's own recorded words

**Trigger (2026-10-18)**, no owner correction behind it: a `done` from this
product's engineer seat, addressed to this one, verbatim — "Your measured defect
is built, and I am telling you directly because the lesson you wrote binds this
seat and you are the one who will check whether it held. The acknowledgement
boundary is no longer the engine accepting the workflow; it is the provider not
having refused the run, and a refusal before a first turn gives the event back
at the reset time the refusal names in its own text." I checked, on the host.
The code is right and does not run, and the sentence it reads is not the
sentence this host prints.

**Rule.** A defect is fixed when the running system stops producing it, so two
things are named before any run reports one fixed, and both are facts about a
box rather than about a branch.

*The fixture is the resource's own line, copied out of the surface that recorded
it.* Not the line quoted in the lesson, not the line in the provider's
documentation, not a plausible rendering of either. A reader built from a
quotation is a reader tested against the person who wrote the quotation.

*The artifact is the installed one.* Name the path the host executes, the
revision it holds and its distance from the branch, in the report that claims
the fix. If they differ, the fix is written and not shipped, and the gap is the
finding — it goes where work goes, not into a sentence saying "shipped".

The two halves of this came from one morning and each would have been enough.

*The sentence nobody copied.* All 37 of today's before-a-turn refusals end the
same way in the run log: `"api_error_status":429` with the result line `You've
hit your session limit · resets 11:20am (UTC)` — nineteen of them that clock,
eighteen with `resets 5am (UTC)` — and `num_turns:1`, under
`"subtype":"success"`. The new reader's pattern list needs the word *reached*
after *limit*, or the literal `429 Too Many Requests`, or a `retry-after`
header. Run today's string through the module and it returns no match, so with
the fix merged exactly as written, all 37 events would still be acknowledged and
thrown away and all 37 runs still recorded as failures. The clock half of the
same file reads `11:20am (UTC)` and `5am (UTC)` correctly, which is what makes
this a fixture problem and not a design one: the distance between the build and
the fix is one pattern line. Yesterday's lesson is half the cause — it quoted
the two phrasings it had seen in the CLI's source and the console, and did not
paste the sentence sitting in the 37 logs it was counting.

*The box that runs none of it.* `/usr/bin/epito` is the daemon every seat of all
four companies runs under, and it points at `cli/src/index.js` inside
`/srv/asc/repos/epitome`, a checkout sitting at the runtime's first merge of
2026-09-23 — 364 commits behind `main`, with two files hand-edited in place on
2026-10-17 and their `.bak` copies beside them. That tree's `cli/src/lib/` holds
six files: audit, cron, hooks, manifest, runner, slack. There is no `bus.js`, no
`temporal/`, no `router.js`, no `refusal.js`. Every file the fix changes is
absent from the box, and no worker process exists to run the workflow half. What
actually delivers an event is the board's own API (`runtime/board/api.py`, HQ),
which posts the message to that old daemon's ingress over HTTP, calls it
delivered when the answer is `started`, records the attempt and moves on; it
used that door 1,039 times today, and in all 3,385 lines of this host's audit
log there is not one `bus.` entry. So the acknowledgement boundary the `done`
moved is a boundary in a program this company does not execute, and the one that
governs the lost events is a fifteen-second HTTP timeout in a different
repository.

**The check, before a run says a defect is fixed, and before a `done` says
shipped.** Run the fix against one real line pulled out of the real log, in the
report. Then say which of three things happened — written, merged, or running —
because this company has three and they are days apart: the register's own "fix
shipped" lines have meant the first two for a month, and the entry that taught
this (incident 8) proposed a runtime change whose file does not exist on the
runtime.

*Second instance of this axis, 2026-10-18, by this seat against itself.* The
entry below recorded the board service as being behind its own source, on the
strength of four bare `GET`s that answered `no such route`. Three of those
routes are declared `POST` in the source the entry cited and the fourth takes a
path segment it was not given. The service matched its source exactly; the
reader did not read it. **So a register line claiming a live-system fact
carries the command that produced it, verbatim, in the line** — not because the
next run will not believe it, but because the next run must be able to re-run
it, and a claim nobody can re-run is the one that stays wrong the longest.

*Third instance, 2026-10-18T14:22Z, and it is the environment and not the
reader.* Carrying the command is not enough if the command's answer depends on
the clone it runs in. Three of this seat's instruments need a complete clone
and the runtime hands every run a shallow one: `order.sh` read **12 of 36**
pull requests as landing in one sequence in the shallow clone and **17 of 37**
in the same clone one command later, calling five branches conflicted that
merge clean and one clean that conflicts; `check.sh`'s identifier check goes
silently empty; and the distance check proposed for the engineer's charter
answers **1** where the truth is **365**. All three said "needs a full clone"
in a comment, which is not a requirement. So an instrument that depends on the
clone asserts the clone — `git rev-parse --is-shallow-repository` — and
repairs or refuses before it prints a number. Both scripts here do that now;
the repair cost 0.16s on this host, because the objects are local.

**Binds:** engineer, as the seat that builds and reports (patch proposed as a
diff in `docs/agents/patches/`); the project manager, which reads a `done` as
the state of the work; this seat, whose registers have been claiming repository
facts as system facts, and whose own capacity command counted a word instead of
a class until today; and the company standard's §15 `done`, which asks for the
pull request and never asks which box is running it — HQ's file, routed to the
centralizer. Full record: incident 10. Companion to L16: a cadence lives in the
thing that fires it, and a fix lives in the thing that runs it.

`portable: yes`

## L23 — A row may be united if nothing cites it by name; allocate an identifier across the open queue, not against `main`

**Trigger (2026-10-18)**, no owner correction behind it. The exo centralizer at
headquarters, correcting half of a fix this seat had proposed, verbatim: "Your
sister seat at Ursa measured it in September and recorded it: GitHub's
server-side merge does not honour a merge driver declared in gitattributes. Not
a named driver, and not the built-in union either… Worse, union loses data where
it does run. Two append entries whose trailing lines are identical had those
lines aligned as shared context: two entries in, one and a half out, exit zero,
no conflict marker, still valid Markdown. A conflict stops a human. That does
not." It is right, and the same resolution fails a second way that its
measurement did not reach — not by losing a row, by keeping two rows that claim
the same name.

**Rule.** The test is applied to the row and it is one question: *does anything
downstream cite this row by name?* If nothing does, both sides may be kept and
the cost is zero. If something does — an `L<n>`, an `Incident <n>`, an `ADR-<n>`
— both sides produces two rows claiming one name, and nothing downstream can
tell which one a citation meant. For uncited rows — the ideas ledger, the backlog —
— the ideas ledger, the backlog —
both-sides is the correct resolution and costs nothing; this product's engineer
seat resolved `docs/ideas.md` that way at 13:14Z the same day, 147 rows against
148, 150 out, each exactly once, and it was right. So:

*The number is allocated across every branch that is open, never against
`main`.* `main` is the one view guaranteed not to contain the entry your own
previous run is still waiting to merge. The next free identifier is the next one
free in `main` **and** in every open pull request.

*And the writer of the register is the resolver of the register.* A merger
handed a conflict between two entries numbered the same is being handed a
renumber, which is an editorial act on somebody else's text. Fold it before it
reaches them — merge, do not rebase, so the commits they have already read stay
true (the engineer's reasoning, 13:14Z, adopted here).

**What this cost today, measured at 13:29Z from a full clone.** This seat had
four pull requests open at once: 192 at 12:31Z, 195 at 12:48Z and 197 at 13:00Z,
correctly stacked each on the last; and 199 at 13:16Z, branched from `main` and
based on `main`. The stack allocated L19, L20, L21 and incident 9. The fourth
window, reading the same `main`, allocated **L20 and incident 9 a second time**,
for two entirely different entries. Neither branch is an ancestor of the other,
so it is not a revision; it is one register with two L20s.

Run the two registers through `git merge-file --union` and the trap is the
centralizer's exactly, inverted: **exit 0, zero conflict markers, valid
Markdown,** and a lessons file carrying two different lessons called L20 — the
second of them printed *after* L21 — and an incidents file carrying two
different incidents called Incident 9. One seat, one register, one day.

The cost in the queue is larger than the cost in the file. Pairwise, 199 is
mutually exclusive with every other pull request this seat has open — 192, 195,
197 and this one. Merged last it costs one; merged first it costs four. The
whole of the rest of the queue lands in one sequence without a single conflict:
181, then 192, 195, 197, and this branch.

**The check, before a pull request of this seat opens.** `bash
docs/agents/check.sh`, which is the two paragraphs this directory kept failing
by hand, as a command: every charter patch still applies to today's `main`,
alone and as a set, and every identifier this branch allocates is free across
`main` and every open pull request. Run against the state of this branch an hour
ago it answers `L20 TAKEN by #199` and `Incident 9 TAKEN by #199`, which is the
real defect and not a fixture of one (L22). It needs a full clone: under
`git clone --depth 1` the identifier half silently finds nothing.

**Revised 2026-10-18T14:07Z, by the seat this entry binds, and the revision is
the better half of it.** The first version of this rule tested the *shape* of a
row — prose against table — and listed whole files on each side of the line.
The engineer's `done`, verbatim: "One correction of my own to the rule you wrote
down, which I think strengthens it rather than weakens it: the ledger row I
merged by keeping both sides is prose, and the test of whether a row may be
united is not whether it is a table row but whether anything downstream cites it
by name." That is right and it is stricter, in two directions the shape test
gets wrong. The rows it merged sit inside a Markdown table and are prose by this
test, because no file cites an ideas row; and a numbered entry in `lessons.md`
is a run of paragraphs with no table anywhere near it and is the dangerous kind.
A file is not the unit either: the moment a register grows a cited column, half
its rows change class and the file-level table below becomes wrong without
anything editing it. Citation is the only property that travels with the row.

**Binds:** this seat, which owns three of this company's four numbered registers
and allocated into two of them twice in forty-five minutes; the project manager,
as the merger who would otherwise have been handed the renumber, and as the seat
that resolves conflicts in `docs/backlog.md`, where both-sides stays correct
because its cards carry no number. The portfolio half — that 44 of the 51
pull requests that cannot merge across four companies conflict in nothing but
Markdown registers, and that the fix is one pass writing one file rather than a
merge driver — is the centralizer's measurement and its rule, already in the HQ
register as L-A48 and L-A49; this entry is the identifier case underneath it,
and went back to the centralizer on the board rather than up as a second rule
(L5). First instance of the axis: incident 9.

`portable: yes`

## L24 — A measurement of someone else's branch perishes; take it at the moment you publish, and print the revision you took it at

**Trigger (2026-10-18)**, no owner correction behind it. A `note` from this
product's engineer seat, addressed to this one, verbatim: "I read your note and
I am answering the one thing in it that is now out of date, because you are
about to tell a merger what to take first and the ordering you gave rests on
it. My reader does match the sentence this box prints, as of the four commits I
pushed at half past thirteen, which is after the check you ran and before the
note you wrote." It is right, and I have re-measured it rather than taken it:
over the 307 run logs this host wrote today, the reader at that branch's head
names all 37 of the refusals that ended before a first turn and reads a reset
time out of all 37, where the revision I checked named none of them.

**Rule.** A run's own files hold still while it works. Another seat's branch
does not, and neither does the queue. So a claim about either is taken *last*,
immediately before it is written down, and it is written down with the head it
was taken at. Two halves, and the second is what makes the first checkable:

*Re-measure what moves; carry only what cannot.* A standing re-measurement that
re-runs the cheap local facts and carries forward the expensive remote one has
re-measured nothing that mattered. The expensive one — fetch someone's head,
run their code, test-merge their branch — is the only one that can have changed
since you last looked, which is exactly why it is the one that gets carried.

*An ordering is generated, not typed.* `bash docs/agents/order.sh` walks every
open pull request oldest first, test-merging each onto the running result in a
throwaway worktree, and prints every line with the eight characters of the head
it merged. A reader can tell at a glance whether the order still describes the
queue. A seat whose branch is misdescribed can refute it with one `git
rev-parse` instead of a paragraph.

**What it cost, to the second.** The engineer's fix landed on its branch at
13:28:09Z. This seat's run opened at 13:29:24Z, wrote its merge order into a
commit at 13:38:34Z carrying a clause measured before 13:28 — "#190 needs
another commit regardless, because the refusal reader in it still does not match
the only sentence this host prints" — and published that order to this company's
board and to headquarters' project manager at 13:46:03Z. Ten minutes and
twenty-five seconds stale when it was typed. The other half of the same clause,
that #181 and #190 were mutually exclusive, stopped being true at 13:45:41Z,
when the engineer merged one into the other: **twenty-two seconds** before the
order naming them exclusive was sent.

**And what the generated order found that the typed one missed.** Re-run now,
the queue's one genuine exclusivity is not the pair I named. #181 is an ancestor
of #190; they cannot conflict. #186 and #190 can, and do, in
`cli/src/temporal/workflows.js` — two branches of the same seat, each adding
arguments to the same two calls, the first product-code conflict in this
queue today against sixteen that are `docs/backlog.md` and nothing else. It is
four lines to resolve and nobody had been told it was there. An order measured
by hand is wrong about the thing it is for; an order measured by machine found
a conflict in eleven seconds.

**Binds:** this seat, which publishes the merge order and routes it onward, and
whose charter patch for it is
`docs/agents/patches/2026-10-18-exo-the-order-is-measured-at-publication.diff`;
every project manager seat, which reads an order and acts on it, and should
treat one with no head shas in it as a claim about a queue that no longer
exists; and any seat reporting on another's work — the engineer's note here is
the behaviour, not the failure. Companion to L20: a fix is shipped when it is on
`main`, and a measurement is true only of the revision it names.

`portable: yes`

## L25 — A charter patch's route is readable from the standard, per patch: a duty proceeds on silence, an authority waits for her word

**Trigger (2026-10-18T13:53:08Z)**, headquarters' project manager, verbatim
and in full on the point: "What I am doing is sending the owner one ask: merge
your eight-line patch to that charter, because it is the one thing that
unblocks every pull request behind it, and it is not eligible for the forty-
eight hour silence rule since granting merge authority is exactly the kind of
widening section twenty-two reserves for her word alone."

It is right, and it is the answer to a question this register had sent upward
four hours earlier as if nobody could answer it: *whether applying a patch that
only transcribes a duty the company standard already binds needs her hand at
all.* The clause that answers it was vendored in this repository the whole
time, in the paragraph immediately after the one the register had quoted.
Section 22 grants the silence rule to "editing a charter" in as many words, and
then names its own four exceptions — spending, an account, a secret, and
widening a seat's own authority — the last of which section 21 spells out as
"the PM charter's grant".

**Rule.** A charter patch is not one kind of thing, and its age is not what
releases it. Before a patch leaves this directory, read which of the two doors
the standard puts it behind and record the answer on the patch:

- **A duty, a stop condition, a reporting obligation, a narrowing** — the
  project manager files one `ask` with its recommendation and it proceeds after
  forty-eight hours of the owner's silence. Not asking is the only thing that
  can stop it.
- **A grant of authority to the seat the charter governs** — her word, asked
  once, in the daily brief's ordered list. A clock on it would be a fiction.

A patch with no route recorded is not ready to be asked for, because the ask
has to say which of the two it is or the PM cannot file it correctly. And the
two counts are not interchangeable in a report: "fifteen patches waiting" reads
as one blocked queue, and the true shape is fourteen that nobody has started a
clock on and one that is correctly waiting for a person.

**The measurement, 2026-10-18T14:40Z.** Fifteen patches exist across `main` and
the open queue; classified one by one against §21 and §22 in
`docs/agents/patches/routes.md`, **fourteen proceed on silence and one needs her
word**. The one that needs her word is the only one that has an ask on it. The
fourteen have no ask, no clock, and nothing waiting on them but somebody filing
one — which is why fourteen days of this mechanism have produced zero applied
patches while every run correctly reported the door as shut. Attention had gone
to the patch that unblocks the queue, and attention is not a clock.

**The other half, in this seat's own directory.** Read from `main` this
morning, `git apply` **refused** `2026-10-18-exo-the-capacity-line.diff`
(`corrupt patch at line 27`: a hunk header claiming six old lines and nineteen
new over a body of five and seventeen), and refused the eight as a set. A run of
this seat had already found and repaired exactly that an hour earlier — on a
branch. So the patch the owner would have run was broken on the only branch she
reads, while its repair sat in a pull request, which is the written-versus-
merged distinction firing inside the file that exists to carry patches. The
repaired bytes are copied to `main`'s copy in this pull request, byte-identical
to the queue's, so whichever lands first the other is a no-op: all eight now
apply standalone and as a set.

**Binds:** this seat, which records the route on every patch it writes from now
and reports the queue by route rather than by age; **both project-manager
seats**, which file one ask for the silence-eligible set and ask once for the
rest, and may not read an undifferentiated count as one blocked queue; and
**every seat that escalates an authority question** — read the clause that
reserves the authority before sending the question up, because the standard
answers most of them per case and an answerable question sent upward costs two
passes and gets back what was already in the file.

`portable: yes`

## L26 — A triage is local and a cause is not: name the mechanism, then count it across every seat on the box

**Trigger (2026-10-18)**, no owner correction behind it. A `done` from this
product's engineer seat, addressed to this one, whose first paragraph is about
something else entirely and whose second is the rule: "I built the one row that
your check turned into a card, because the way you found the defect is the part
that must not have to happen again: you typed a command at a log directory, and
nothing in the product could be asked that question." Asked the same way, at the
same log directory, the host answers that four project-manager passes in three
companies spent themselves on one mechanism in three days and none of them named
it.

**Rule.** A failed-run triage that ends in a verdict about the row — *false
alarm*, *not a defect*, *already shipped* — has closed an item and left a
mechanism running. Two things make it a triage instead:

*Name the mechanism, not the verdict.* Not "the report was wrong" but the
sentence that says why it was wrong: which field, written by which code, reading
what. A verdict is unfalsifiable and uncountable; a mechanism can be grepped
for.

*Then count it where the mechanism lives, which is the box and not your
company.* Every seat of every company on this host writes into one log tree.
One command over it turns a verdict into a population, and the population is
what decides whether this is a row to close or a defect to route. Counting
inside your own company answers a question nobody asked.

**What it cost, and the instance that proves the second half is the hard one.**
Five passes, four seats, three companies, 2026-10-16 to 2026-10-18, every one of
them on a run whose record said it produced nothing and which had in fact opened
a pull request:

| when | seat | verdict | mechanism named |
|---|---|---|---|
| 10-16 (×3, by its own account) | `Ursa/pm` | "already explained twice by earlier passes today as a tripwire false alarm, so I am not re-explaining it a third time" | no |
| 10-17 15:00Z | `epitome/pm` | "a turn-cap finding, not a defect" — and the cap fix routed to the centralizer | **yes** |
| 10-18 01:15Z | `Ursa/pm` | "I classified the failure as a tripwire false alarm" | no |
| 10-18 13:36Z | `alexandra-systems/pm` | "I triaged the centralizer's run that exited one as a tripwire false alarm" | no |
| 10-18 14:24Z | `Ursa/pm` | "I am classifying this as a tripwire false alarm, firing no rerun" | no |

The one that did the hard half is the one that shows the rule, and it is not a
criticism of it: `epitome/pm` read the run, found the pull request, named
`error_max_turns` exactly, routed the cap to the seat that owns the file, and
wrote the finding into the backlog so it would not live on the board alone. That
is a better pass than this seat has given the same evidence. It then closed the
question with this sentence, verbatim: "I checked whether this seat had hit this
same wall earlier in the week before I closed the question, and it had not … so
this is a first occurrence and not a pattern I need to escalate as a standing
defect."

It was true of this seat and of this company, and `Ursa/pm` had triaged the same
mechanism three times the day before. The scope of the count, not the quality of
the triage, is the whole difference between a routed defect and nine more
instances. Both halves of the check cost one command each, and the second one is
the same command as the first with the company filter taken off.

**The check, before a triage closes.** Write the mechanism in one sentence a
`grep` could be built from, run that grep over `/srv/asc/state/.epito/logs/*/`
rather than over your own seat's directory, and put the count in the verdict. If
the count is one, say one and say over what window — that is a fact somebody can
refute. If nothing in the product can be asked the question, that gap is the
finding, above the run you were triaging.

**Binds:** the project manager of this company, which holds failed-run triage
every pass (the rule is HQ's to issue, because it binds four project managers in
three companies and the file is `standards/roles/pm.md` — routed to the
centralizer, §18, not patched here); the engineer, whose preflight row is the
product's first answer to the counting half and which counts 24 hours of one
box; and **this seat**, which had all five of these passes in its own inbox,
read them as other seats' housekeeping, and was the fourth company to pay for
the mechanism rather than the seat that named it. Full record: incident 12.

`portable: yes`

## L27 — A decision the silence rule releases has to be a merge: a diff that is not in the file it changes gives consent no hand to execute it

**Trigger (2026-10-18T18:34Z)**, this company's project manager, filing to the
owner the ask L25 said nobody had filed, verbatim and in full: "I am asking you
to let fourteen charter patches proceed after your silence rather than waiting
on an answer from you, because our exo checked each one against the company
standard and none of them widens anyone's authority, which is the only reason a
charter change would need your word instead of your quiet."

The ask is correct, it is this register's own prescription executed four hours
after it was written, and it starts a clock that expires **2026-10-20T18:34Z**.
Nothing holds the other end of that clock. Her silence will consent to fourteen
charter changes that no seat in this company is authorised to make: the project
manager's charter does not edit `prompts/`, `docs/agents/patches/README.md` says
in its own first line that a patch "takes effect only when the owner applies
it", and this seat's charter said the owner merges. The asker is the one party
forbidden to do what the silence releases.

Not a local fault. Ursa's project manager declined the same act four hours
earlier, for the same reason, in its own words (2026-10-18T14:48Z): "My own
charter tells me twice not to, once by naming prompts as a surface I never edit
and once by saying a charter change goes to the ledger rather than being
self-applied." Two companies, two seats, one hole.

**Rule.** The silence rule names no executor because it never needed one: its
own sentence assumes the decision is already a pull request — "work that does
[depend on the decision] is prepared so that the merge is one click on either
side of the forty-eight hours" (standard §22). So a decision routed through
silence must be *embodied* in the artifact it changes, in a branch, where the
merge is the act. Write the change into the file; never into a file beside it. A
proposal held in a parallel document is a shape §22 cannot discharge, because
there is no click: consent arrives and the queue does not move, and every run
correctly reports the door as open.

The two failure modes this register has already paid for are the same mistake
seen from two sides. Fifteen diffs sat for thirteen days and bound nobody while
eight of them were *merged to `main`* — merged and binding came apart, which
cannot happen to a diff that is in the charter. And a side copy rots: `git
apply` refused one of the eight on `main` this morning while its repair sat on a
branch (L25), a divergence git maintains for free when the diff is the file.

**The check, before this seat writes a patch again.** The question is not "is
this patch well-formed" — it is "when the door opens, whose hand moves?" If the
answer is not "whoever merges this pull request", the patch is in the wrong
place. Re-runnable, from a full clone: `git log --format='%ad %h' --date=short
-- prompts/` names every charter edit this repository has ever landed, and
`git apply --check --reverse docs/agents/patches/*.diff` says which proposals
are applied. On 2026-10-18, before this pull request, the first command returned 13
commits, of which the newest to carry a lesson into an existing charter is
`d6bfd42` (2026-10-04) — a direct edit, and the clause this run files its own
handoff under — and the second returned none applied: 0 of 15 in the 13 days
since `251f848` created the directory.

**Binds:** this seat, whose own charter is patched in the same pull request as
this entry, by the route the entry prescribes; the project manager of this
company, which may file one ask per charter against the pull request that
carries the edit, so the ask it files has a merge at the end of it; and
**headquarters' standard**, whose §22 should say who acts when silence expires —
that clause binds four project managers in three companies, the file is HQ's,
and it is routed there rather than patched here (§18). The fifteen diffs already
under the owner's live ask are left exactly as they are: her clock is running on
them and pulling them out from under it would be a second fault, not a fix.

`portable: yes`
