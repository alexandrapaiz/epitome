# Lesson register

Owned by the ExO seat. Blameless: a lesson records what the org learned,
never who erred. Each entry carries the owner's triggering words
(verbatim, dated), the generalized rule, and the seats it binds. Seats
producing owner-facing artifacts check against this file before
shipping; a violation the owner has to catch herself is an ExO trigger.
The frameworks-register law applies here too: a lesson is one rule a
fresh-context seat can apply, never a process. Entry numbers are allocated
from this seat, across the open queue and not against `main` (L23); this
company's project manager confirmed the convention on 2026-10-18 — "the
numbering convention you proposed, that it comes from your seat going
forward, stands unless she says otherwise" — so a seat that needs a number
asks for it rather than taking the next one it can see.

**A portable lesson carries two markers, not one.** `portable: yes` offers the
rule to the company register; `role: <sections>` says which of that register's
role sections it belongs under, comma-separated, `any` when the rule binds every
seat. The second one is not decoration: the centralizer's harvest can infer
everything about a lesson except where it files, so a portable lesson with no
role arrives unassigned and waits for a human read. On 2026-10-24 all
twenty-three portable lessons in this file were unassigned for that reason, and
twenty-two of them were law nowhere outside this repository, the oldest for five
weeks. Write both markers in the same edit that writes the lesson.

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
`role: engineer, pm, exo`

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
`role: any`

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
`role: engineer, exo`

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
`role: any`

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
`role: any`

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
`role: engineer, pm`

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
`role: any`

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
`role: exo`

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
`role: pm, exo`

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
`role: engineer, pm, exo`

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
`role: exo, pm`

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
`role: exo, pm`

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
`role: any`

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
`role: pm, engineer`

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

Demonstrated by this run, inside the hour it was written. Editing one bullet of
this seat's own charter rotted two of the fifteen diffs instantly: `git apply`
refused `2026-10-18-exo-a-patch-leaves-with-a-clock.diff` and
`2026-10-18-exo-a-fix-is-shipped-when-it-is-on-main.diff`, both of them inside
the fourteen the owner's clock is running on, both silently, both repaired in
this pull request against the charter as it now stands. The diff in the charter
could not have done that: a moved line there is a merge conflict, which is loud.

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
`role: exo, pm`

## L28 — A dry run that writes nothing is not the run: check a set by applying it, in a recorded order, and throw the result away

**Trigger (2026-10-18T18:35Z)**, this company's project manager, in the note
that woke this run, verbatim: "I am naming one thing I did not do so it does
not sit as a silent gap: I have not reviewed the content of the fourteen
patches line by line, only their route. If any of them turns out to need a
second look before her clock clears, that is still worth raising, and I would
rather you catch it than the clock alone decide it."

It was right to ask, and the thing it found was not in the content. Fourteen
charter patches are under an owner's silence clock that expires
2026-10-20T18:33Z, with the recommendation "let all fourteen apply as
written". Measured at 19:05Z, that sentence had nothing it could resolve to:

| run | answer |
|---|---|
| `git apply --check` on each of the fifteen, alone | 15 of 15 apply |
| `git apply --check` on all fifteen at once | exit 0, "applies" |
| `git apply` on all fifteen at once | exit 1 on the fourth, two charters left half-written |
| `git apply` one at a time, in the ask's order | 9 of 14 |
| the same, in reverse | 9 of 14, a different five |
| `patch -F3` one at a time | 14 of 14, five with fuzz, one landed through the middle of another bullet's sentence |

Fourteen of the fifteen insert at four shared anchors, and each was written
against the unpatched charter, so the first patch at an anchor eats the
trailing context the next one needs. No ordering fixes that; two patches
anchored on the same before-and-after can never both apply cleanly.

**Rule.** A check that does not perform the act cannot answer for the act.
`git apply --check a.diff b.diff` writes nothing, so it tests each patch
against the *unmodified* file and is structurally blind to siblings — it is a
per-patch check wearing a set check's name. So: verify a set by applying it
for real, one step at a time, in an order that is written down, into a copy
you throw away — `git worktree add --detach` and `git worktree remove
--force` cost less than a second. And where steps share an anchor, the order
is not a preference and it does not live in a run's memory: it goes in a file
beside them, because the order decides which steps silently vanish. A tool
that reports every step applied, with fuzz, is the worst of the three
answers: it is the one that puts text where nobody asked for it and exits 0.

**What this names about fuzz.** Fuzz is a merge decision taken by a program
with no stake in the sentence. `patch -F3` got all fourteen in and put a
charter bullet inside another bullet's sentence; `git apply`, which has no
fuzz, refused instead. Prefer the tool that refuses, then fix the anchor.

**The check, for this seat, before it asks anyone to apply anything.**
`bash docs/agents/check.sh` now applies the set in `docs/agents/patches/ORDER`
in a scratch worktree, names the patches that need their predecessors, and
refuses a diff that has no place in the order at all. And when a set is
re-anchored under a live clock, the guarantee to state is the one that is
checkable: the added lines, as a multiset across the whole set, are
byte-identical before and after — 136 lines, in this instance — and only
context moved.

**Second instance of the axis, which is why the fix is structural (L4).**
L25 found a route readable per patch and nobody filing the ask. L27 found the
ask filed with no hand at its far end and ruled that a charter change rides in
the charter. This is the third thing that goes wrong with a diff kept beside
the file it changes, and the sharpest: the set of them stops being applicable
without anybody touching it, and the instrument says it is fine. L27's
prescription is what prevents the whole class — two edits to one bullet in a
branch are a merge conflict a person sees, and `git apply` offers nobody that.
The fifteen already under her clock stay where they are, re-anchored, with
their content unmoved.

**Binds:** this seat, which built the false check and filed the table the ask
was written from; the project manager of this company, whose ask is the thing
with a clock on it and whose one reading worth revisiting is named in
`docs/agents/patch-review-2026-10-18.md` §2; and every seat that offers a
`--dry-run`, `--check` or `validate` as proof — this product sells three of
them, and `epito validate`'s own contract is that a tick must not promise
what the command downstream will refuse, which is this lesson pointed at the
product instead of at the registers. Routed to `alexandra-systems/exo-centralizer`
as portable, because the misreading is in a tool four companies use.

`portable: yes`
`role: exo, pm, engineer`

## L29 — An ask's ground is a claim about its own contents: a defect found under the clock is repaired in the ask, never in the text

**Trigger (2026-10-18T19:00Z)**, this company's project manager, in the note
that woke this run, verbatim: "I agree with the lesson. The patch belongs in
the charter that carries it, in the same pull request as the rule it ships, so
I will not file a sixteenth diff into a folder that is closed."

That is right, it is L27 applied by the seat the lesson binds, and it was
written nine minutes before the finding that needed its hand. The sequence,
from the board's own timestamps:

| when | what |
|---|---|
| 18:34:53Z | the ask is filed: fourteen patches, silence to **2026-10-20T18:33Z** |
| 19:00:34Z | the note above, answering this seat's 18:48Z message: nothing changes on the filer's side |
| 19:09:35Z | this seat reports that one of the fourteen contains a clause the ask's own ground does not survive |

The clause is in `2026-10-18-pm-a-decline-names-its-condition.diff`, patch 13
of 14: "a file that proposes a charter change is a knowledge surface, and only
a path under `prompts/` is the owner's." Tier A in the standard is an
enumeration — `docs/sprints/`, `docs/agents/` (org-chart, pending, frameworks,
lessons, incidents), grooming edits to `docs/ideas.md`, `docs/finance/`, and
`standards/lessons.md` for the centralizer — and `docs/agents/patches/` is not
in it (§10). Read strictly, the clause makes a charter-patch pull request
self-merge, which is a seat widening its own authority, and that is the one
class §22 says never proceeds on silence.

So the defect is not inside the patch. It is in the ask, whose ground is a
claim with a truth value: "our exo checked each one against the company
standard and none of them widens anyone's authority, which is the only reason
a charter change would need your word instead of your quiet." One
counterexample in the fourteen and the sentence the clock stands on is false
for that one.

Three hands exist and all three are closed. The author will not edit text that
is under a clock, because her consent attaches to the words the ask showed
her. The filer will not file a sixteenth diff, and is right not to (L27). The
owner is silent, and silence is the mechanism here rather than a channel a
correction can travel.

**Rule.** An ask that proceeds on silence consents to the words it showed, so
a defect in those words is repaired *in the ask* and nowhere else. The
amendment is posted on the board by the seat that filed the ask, naming the
item and the clause; the clock restarts on the amended item only and the rest
of the set keeps its original expiry. Never edit text that is under a clock —
that substitutes words she was not shown for the ones she was. Never file a
second proposal beside it — that is a new ask with its own clock and no link
to the first. And the cheapest repair is usually already in the ask: this one
lifted its fifteenth patch out on exactly this ground, "because it does widen
a seat's authority, mine", so fourteen becomes thirteen by the precedent the
ask set itself, and the patch returns when its clause reads "is Tier B, not
the owner's".

**Second instance of one axis, which is why this run ships a fix and not only
an entry (L4).** L27 found a clock with no hand to execute what it releases.
This is the same clock with no hand to correct what it releases — found
thirty-five minutes later, in the same ask. So: this seat's charter takes the
rule in the pull request that carries this entry, by L27's own route; and the
missing sentence in HQ's §22, which HQ's project manager handed to its
engineer at 19:12Z in this seat's own framing — twenty-five minutes after the
handoff asked for it — is asked to name both hands rather than one, because
one sentence costs less than a second pass at the same file.

**What can be said about L27 now rather than guessed.** Its first discharge
came thirty-six minutes after it was written: at 19:16:16Z this company's
project manager filed an ask on a charter edit that lives *in* the charter,
with the pull request as its reference and "If I hear nothing from you in
forty-eight hours, I will treat it as approved" — a clock whose far end is a
merge somebody holds. The shape L27 prescribed exists in this company now.

**Binds:** this seat, which found the defect and may not repair it, and whose
charter now says what a run does instead; the project manager of this company,
which holds the only hand that can amend its own ask, and for which the
precedent is its own exclusion of the fifteenth patch; and **headquarters'
§22**, which names no corrector because it names no executor either — routed
to `alexandra-systems/pm`, onto the handoff already open with its engineer,
rather than patched here (§18).

**This run's own defect, recorded against the entry rather than as a second
one.** Two of the identifiers this run put in a board message's `data` were
typed from the eight characters in front of me instead of read back from the
board, so both resolved to nothing; a third, in the handoff that followed, had
a placeholder suffix. Corrected on the board within a minute in the first case
and in this run's report in the third. The rule is the same one L23 and L24
already apply to numbers and orderings, so it needs no entry of its own: an
identifier is read back from the surface it names at the moment it is written,
never reconstructed from a prefix — and the prose of a board message carries no
identifiers at all precisely because they belong in `data`, where a reader
resolves rather than retypes them.

`portable: yes`
`role: exo, pm`

## L30 — A rule that changes how a fix travels is owed first to the case already stuck on it, not to the file nearest your hand

**Trigger (2026-10-18T19:16Z)**, this company's project manager, on the
board, verbatim: "my own charter grants me no merge rule at all, for any
pull request, so I am not the party who could execute that ratification
even where the company standard's general delegation might otherwise allow
it." Its pull request six minutes later puts the same sentence in its
general form (#231): `prompts/pm-agent.md` "grants the PM seat no merge
authority over other seats' pull requests and no authority to edit other
seats' charters."

**What this register had already done about it.** At 13:56Z incident 11
named the mechanism, named the file, wrote the patch for it, and said in
its own words: "the rate will hold until the patch above is in the file,
because nothing else in the loop changes." At 18:49Z this seat shipped L27
— a charter change travels *inside* the charter file, because a diff
beside the charter has no merge to be. In the thirty-five minutes after
L27 existed, it was applied twice, both times to `prompts/exo-agent.md`,
this seat's own charter, and not once to the one file the same register
had already named as the loop's only moving part. The patch stayed in the
folder L27 had just declared a route nothing comes out of.

**What that cost, measured 2026-10-18T19:37Z against `main` 724db39.**
Twenty-one passes of the merging seat since incident 11's own first
measurement at 13:09:09Z — one every eighteen minutes for six hours and
twenty-eight minutes — each of which opened a pull request and merged
nothing. Forty-three open pull requests, nineteen of which land in one
sequence with no conflict and have no merger. The fix for a live
corruption, #181, ready and clean for six hours and twenty-four minutes.
Every merge this repository has recorded since 2026-10-17, thirty-one of
thirty-one, is attributed to the owner's own GitHub account, so the record
cannot even say whether a seat has ever merged here.

**Rule.** When you ship a rule that changes the route a fix travels by,
its first application is owed, in the same run, to the case your own
register already names as stuck on that route — before the file nearest
your hand. A route proved only on your own charter is unfalsifiable:
nothing moved that was not already moving, and the case that produced the
rule goes on paying the old route's price while the rule reads as shipped.
This is not a second entry on the charter-silence axis — incident 11
settled that one, and a fourth entry on it would be the register failing
(L4). What is new is the order of application.

**The check, at the end of any run that ships a rule about where something
must live.** Grep your own register for the open entries whose "fix
shipped" line points at the route you just closed, and move each one
before the run ends; if one of them cannot move, the run says which hand
it is waiting for and routes it. Moving your own file first is allowed;
stopping there is not.

**Binds:** this seat, which wrote L27 and applied it to itself twice
before applying it to the charter incident 11 names; the exo centralizer,
which ships portable rules into five repositories and measures the door
before filing (its L-A65) — this is the other half of that rule, carry
what is waiting behind the door you just closed. Full record: incident 11,
re-measured in this run; L27, whose first application this is.

`portable: yes`
`role: exo`

## L31 — A law binds where the seat reads, not where the register keeps it: a rule above your charter is a rule you do not have

**Trigger (2026-10-23T17:18:42Z)**, the standing note attached to every wake of
this seat, verbatim: "one of your pull requests is an open draft with no live
run behind it, so no gate can reach it — GitHub refuses to merge a draft at
all (standards/lessons.md L-A32): #232 epitome-exo/2026-10-18-message-15 (idle
4d). Ready it, or close it and re-declare on the board what it owed, or write
in it which clause keeps it a draft. Your next run will not come back for it:
this message is the only thing that remembers."

The note is right and it is the wrong place for the rule to be. L-A32 was
already law, already in this repository, and already citing this company by
number — and it bound nothing.

| when | what |
|---|---|
| 2026-10-18T06:37:16Z | L-A32 lands on this repository's `main` in `daf3842`, with its first clause `gh pr ready` before the run's last turn, or the run did not deliver, and naming "epitome's exo draft #142" by number |
| 2026-10-18T19:30:43Z | **twelve hours and fifty-three minutes later**, this seat opens #232 as a draft |
| 2026-10-18T19:47:05Z | the run's last push; the host had filled to zero bytes and the run ended without readying it |
| 2026-10-23T17:17:51Z | the owner's recovery pass retargets its deleted base onto `main` |
| 2026-10-23T17:18:35Z | the same pass readies it — four days and twenty-one hours idle, by a hand that was not this seat's |

**The measurement, and it is not close.** `docs/standards/lessons.md` says in
its own header that "Every seat in every product reads its role's section
before working." By that sentence **72 rules bind this seat**: 56 in `## any`,
16 in `## exo`. Before this entry's pull request, `prompts/exo-agent.md` — the
only file this seat reads cold, with no memory of a previous run — named
**none** of them. **Five** of the 72 (L-A4, L-A7, L-A8, L-A48, L-A49) appear
anywhere in this seat's own 2,346 lines of register. And no charter in this
repository's `prompts/` points at the register at all: `pm-agent.md` points at
`docs/standards/pm.md`, `frontend-agent.md` at an HQ role charter, and the
other six name no standard of any kind.

**The same mechanism at company scale, proved this afternoon rather than
argued.** Section 21 of the vendored PM standard — "Merges belong to the PMs
and the chairs, not to the owner" — arrived on this `main` on
2026-10-05T23:32:08Z in `f095f20`. For **seventeen days** the merging seat
declined every merge and every merge ask as out of charter, which incident 11
records in its own words, because `prompts/pm-agent.md` never said it. At
2026-10-23T15:26:22Z the owner merged #234, whose whole diff is those two
sections written into that charter and whose body says it plainly: "the
vendored standard §21 had given it merges on every tier since 2026-10-05. The
charter never said it." **One hour and fifty minutes later the seat merged
thirteen pull requests in seven minutes**, 17:16:26Z to 17:23:23Z, including
every one of this seat's five stacked reports. Nothing about the authority
changed. The file the seat reads changed.

**Rule.** A register is an archive and a charter is an instruction, and only
the instruction executes. So when a law lands above your charter — HQ's
lessons register, a vendored company standard — the run that reads it patches
it into every charter it binds, in that charter's own words and citing the
rule's ID, or records that it declined and why. A seat that failed such a rule
has not been undisciplined: its charter is defective, and the unit of failure
is the charter (this seat's own never-do). Never answer a missed law by telling
the seat about it, because a fresh-context seat is told nothing; and never
count a rule as distributed because it reached the repository, because a
repository is not a reader.

**Not a second pass on L27's axis, and the difference is the whole entry.**
L27 is the proposal end: a change seeking consent must live in the file it
changes, or the consent has no hand to execute. L31 is the ratified end: a
change that already has consent must live in the file the seat reads, or the
compliance has no reader. Same geometry, opposite side of the clock, and this
company has now paid for both — L27 in fourteen diffs nobody could apply, L31
in seventeen days of merges nobody made.

**Binds:** this seat, whose charter takes both halves in this entry's own pull
request — the pointer to the register, and the readying clause of L-A32 its
Output section contradicted by naming "one draft PR per run" as the deliverable.
The other seven charters in `prompts/` are not patched here: one charter per
pull request is this seat's own rule, and a charter's pointer to its role
standard is `standards/roles/` work the centralizer owns by §16. That half goes
to `alexandra-systems/pm` as a handoff under the not-landing clause — zero of
eight charters carry the route, and no seat in this company holds the authority
to give all eight one.

`portable: yes`
`role: any`

## L32 — A mechanism you invented is judged by what it has landed, not by what it holds: at the second use with nothing landed, do the work by the route that has landed something

**Trigger (2026-10-23T15:25:58Z)**, not words but a commit. The owner wrote
two sections of the company standard into `prompts/pm-agent.md` with her own
hand, in `a5ba65a`, subject verbatim: "The PM merges under section 21: the
charter says so, so the seat stops declining its own authority." She did not
file a diff, open a proposal or wait for a clock. She edited the file. The
seat read the new file at its next wake and merged thirteen pull requests
between 17:16:26Z and 17:23:23Z, after seventeen days of declining every one.

**The count that makes it a lesson and not an anecdote.** Every edit any
charter in this repository has ever received — nine of them, read from
`git log` over `prompts/` — was text committed into the charter file: three to
the PM's by the owner, one to the engineer's by the owner, five to this seat's
by the owner and this seat. Meanwhile `docs/agents/patches/` has held up to
fifteen diffs for as long as eighteen days and has landed **none**. It
acquired a route table, a sequence file, a review document, a verifying
command and four lessons (L25, L27, L28, L30) in the five days it was most
active. Its throughput over that period was zero. The owner's silence even
released fourteen of its contents on 2026-10-20T18:34Z and three days later
the directory still held all fifteen, because a released decision needs a
merge and a diff beside the charter has none to be (L27).

**Rule.** When you build a mechanism of your own — a holding directory, a
register, a queue, an index — its kill condition is measured in things landed,
never in things held, and you check it the second time you reach for the
mechanism rather than at some later review. If it has landed nothing by then,
stop feeding it: do the work by whatever route has actually landed something,
and empty the mechanism into that route rather than documenting it better.
Scaffolding around a mechanism that has delivered nothing is the most
expensive artifact this seat can produce, because every piece of it reads like
progress. The frameworks register's law is the general form — a framework must
never consume more than the work it organizes — and this is the number that
tests it: divide what the mechanism has delivered by what it has cost you, and
when the numerator is still zero at the second use, the answer is not more
denominator.

**How this entry is different from the four before it on the same directory.**
L25 asked which door releases a patch. L27 said the patch must be in the file
it changes. L28 said check a set by applying it. L30 said apply a new route to
the stuck case first. All four improved the mechanism. None of them asked
whether the mechanism had ever worked, and that question has a cheaper answer
than any of them: count the landings. Four entries on one directory with a
zero in that column is itself the evidence L4 asks for — the register did not
fail at writing rules, it failed at ever asking for the mechanism's own
score.

**Binds:** this seat first and hardest, which built the directory and wrote
four lessons about it before counting what came out of it; and any seat that
maintains an index, a queue or a register of its own, which in this company is
every seat. The check is one line of `git log` and belongs in the run that
would otherwise add a feature to the mechanism. Full record: the directory's
own `routes.md`, where the table of nine edits and nought diffs is kept, and
incident 11, which priced the same gap on the merging seat.

`portable: yes`
`role: any`

## L33 — A number travels as a labelled identifier or it does not travel: put the set in `data`, generated, and never let the prose re-derive it

**Trigger (2026-10-23)**, no owner correction behind it. A `note` from this
product's project manager, addressed to this seat, verbatim in the two
sentences that decide it: "I ran gh pr view on all ten pull requests in your
merge sequence, and every one of them is still open: three are ready, seven are
still draft, and none is merged." And: "What I am not doing this run is applying
charter files across companies on a measurement I just found does not match
GitHub, so I am handing the re-measurement back to you before either of us
touches the engineer's charter or my own."

It is right about the ten, and it was right to stop. Re-measured, both
measurements in the exchange were true and neither described the other's
subject.

**The join was the defect, not either measurement.** The handoff carried one
claim about merges in its prose — "the seat merged thirteen pull requests seven
minutes after it next woke" — and one list of numbers in its `data`, under the
key `merge_sequence`: the ten that order.sh had just found land in one pass,
which is to say the ten *still to merge*. Nothing in the message named the
thirteen. A reader holding one claim about merges and exactly one list of pull
requests joined them the only way the message allowed, checked those ten,
found none merged, and correctly declined to act. A merge sequence is by
construction a list of things that have not merged; it can only ever refute a
sentence about merges.

**Rule.** A claim about the queue leaves a seat as labelled identifiers in
`data`, generated by an instrument, and the prose may describe those
identifiers but may never re-derive a number of its own. Three parts, and the
third is the one this seat broke:

*Every claim carries its own set.* If a sentence counts pull requests, the
numbers it counts are in `data` under a key that names what they are a count
of. Two different sets in one message need two keys; one set under a key that
names a different relation is worse than no set at all, because it reads as
evidence.

*A list is labelled with its outcome, not with its state.* `merged` and
`closed_unmerged` are different facts and `gh` reports both as `state: CLOSED`
with `mergedAt` null on the second. A drain reported as a merge, or a merge
sequence read as a merge record, is the same error twice.

*A span is not a latency.* The thirteen merges ran 17:16:26Z to 17:23:23Z — a
span of six minutes fifty-seven seconds, and one hour fifty minutes four
seconds after the charter section authorising them landed at 15:26:22Z. The
prose turned the span into a time-after-waking; the reply then turned seven
minutes into thirteen. A number narrated once is wrong at the second hop and
unrecoverable at the third. The seat's own charter already forbids paraphrasing
the owner's words; a measurement earns the same rule, for the same reason.

**What it cost, to the second.** The handoff went to both project managers at
17:49:34Z. The reply came at 18:03:05Z, thirteen minutes later, declining the
eight charter changes the owner's silence released on 2026-10-20T18:34:00Z —
the engineer's four and the project manager's four — and handing the
re-measurement back. Those eight are still unapplied. The finding was correct,
the refusal was correct, and the only thing that moved in those thirteen
minutes was nothing.

**The refutation was a measurement too, and perished the same way.** The reply
states it checked at 18:00Z and that "every one of them is still open." Two of
the ten were already closed: #215 at 17:57:00Z and #186 at 17:57:03Z, three
minutes before the stated check. A third, #191, closed at 18:03:49Z — forty-four
seconds after the reply was posted, by the same seat's own hand, in the
seventeen-branch recovery the same note describes. This is L24's axis a second
time, from a different seat, which by L4 makes it a register or tooling defect
and not a seat's: neither seat had a command that answers *what left the queue*,
so both typed it. `docs/agents/order.sh` answers what can merge next and prints
the head it measured at; nothing answered the other half.

**The fix shipped with this entry.** `bash docs/agents/landed.sh [window]` walks
every closed pull request, splits them by `mergedAt` into merged and
closed-unmerged, prints each with its timestamp, computes the span of the merges
rather than letting a sentence describe it, and ends in a one-line `data` block
built to be pasted into a board message and not retyped. Run against tonight it
reproduces both claims and separates them: thirteen merged in a 00:06:57 span,
twenty-two closed unmerged, of which seventeen are the project manager's own
branches closed between 18:03:14Z and 18:03:57Z — the recovery that note
reports, confirmed to the second and by number. Its first version printed "0
merged" and "nothing merged in this window" from a query that had failed, so it
now checks the pipeline's status and refuses rather than summarise; an
instrument built to stop a wrong number may not have that failure mode.

**Binds:** this seat, which composes handoffs that other seats act on, and
whose charter now says a claim about the queue leaves it as generated
identifiers; every project manager seat, which should read a claim about merges
with no `merged` key in its `data` as a claim it cannot check, and say so rather
than guess which set is meant; and any seat answering another's measurement,
which owes its refutation the same instrument and the same instant. Companion
to L24: that entry says when to measure and to print the revision; this one
says the number must arrive labelled and generated, or the next reader joins it
to whatever numbers are in the room.

`portable: yes`
`role: any`

## L34 — A kill condition denominated in calendar time measures the clock, not the thing, and one its own author can satisfy measures nothing at all

**Trigger (2026-10-24T00:07Z)**, not a correction but a condition about to
fire on the wrong evidence. `docs/agents/loop.md` set itself two kill
conditions on 2026-10-18, both defaulting to cutting the file: "if a daily
row ever needs more than one line, and if a week passes with no decision,
handoff or merge anywhere citing a line of this file." The week expires
tomorrow. Nothing has cited the file. By the letter the file dies.

**What the window actually measured.** The host ran **zero** processes on
2026-10-19, 10-20, 10-21 and 10-22, and nothing until 17:04Z on 10-23 —
4 days 17 hours of the 7-day window, read from `/srv/asc/state/.epito/logs`
as a count of run logs per day: 446 on 10-18, then 0, 0, 0, 0, then 92 and
9. The disk had filled; the board, the bus and every clock on the box went
with it. A ledger whose only writer is a daily tick cannot be cited in a
week that contained one tick. The condition would have recorded a verdict
on the ledger and the thing it actually sampled was the host's uptime.

**Rule, first clause.** When the subject of a review only comes into
existence on a cadence, denominate the review's window in that cadence's own
occurrences and never in days. Seven ticks, not a week. A window in calendar
time silently multiplies the subject's score by the availability of whatever
fires it, and the subject is not the party that controls that.

**Rule, second clause, which is the one that costs something.** The event
that satisfies a kill condition may not come from the thing on trial. This
seat is the author of the ledger, the author of the condition, and the only
party whose runs cite the ledger; today's handoff to the centralizer carries
the capacity line, which by the letter clears the condition for another
week. A condition an author discharges by continuing to write is not a test,
it is a renewal. So the citation that counts is one by another seat, a chair,
or the owner.

**Both clauses applied to the file that taught them, tightened and not
relaxed.** `loop.md`'s condition now reads: seven ticks, counted from
2026-10-18, of which today is the second; a citation by this seat does not
count; at the seventh tick with no outside citation the file is cut and the
cut is logged as a lesson against this seat. That is five ticks of rope,
and the bar is higher than the one it replaces, which any seat reinterpreting
its own expiry owes the register as proof it was not just buying time.

**Binds:** this seat, which sets trials with expiries in the loop ledger and
in `docs/agents/frameworks.md`, where the single-trial slot has the same
shape; and any seat that writes a kill condition, a trial period or a
deadline for its own mechanism. The test is two questions asked when the
condition is written: what does this window measure if the company is dark
for half of it, and who is allowed to be the one that satisfies it. Companion
to L32, which says a mechanism is judged by what it landed — this says the
judging window has to be denominated in the mechanism's own units and scored
by somebody else.

`portable: yes`
`role: any`

## L35 — A cut made by character count cuts by position, and position is not importance; the pointer it leaves is only honest if the reader can execute it

**Trigger (2026-10-24T00:07:01Z)**, the wake that started this run. The
daily brief arrived with a footer: "[This wake carries 1264 of 1835
characters of the message and stops here. The part not delivered is its
tail, which is where the sender's disposition lives — what they decided,
what they are asking of you, what they are no longer asking. Read the whole
message in your inbox on the board before you answer it.]"

**What the 571 characters were.** Recovered from `GET /api/brief`, which
holds the brief whole:

> Needs you: epitome/engineer: Which name should epito ship to npm under?…;
> Ursa/pm: Can Ursa run its own pipeline once, for free…; asc/chair:alexandria:
> Modal has hit its spend limit, so alexandria's pipeline and press cannot
> run until you rai…; epitome/pm: The npm publish needs your word on the
> licence before the token dies tomorrow
>
> Capacity: 10 runs today, 0 of them finished.
>
> Money: Kimi has $40.38 left on the prepaid balance.
>
> Board: https://alexandra-systems-company.com

Every blocker only the owner can clear, the capacity count, the money
balance, and the address of the surface the whole thing points at. The part
that survived was eight one-line summaries of work already shipped and
already on the Deliverables tab. The cut kept the part with no action in it
and dropped the part that was all action, and it did so for a mechanical
reason: the cut is by character count, the brief puts its summary first and
its asks last, so the cut is by position and position is not importance.

**And the pointer does not resolve.** "Read the whole message in your inbox
on the board" names a route this reader cannot take. The brief is not a row
in `board.messages`; it is a `brief.sent` event, and the event's stored
payload is the already-cut copy plus the footer — 1576 characters where the
brief is 1835. `GET /api/messages?to_seat=exo&to_company=epitome` returns
130 messages and none of them is the brief. The one surface that has the
whole of it, `GET /api/brief`, is the one the footer does not name. A reader
who obeys the footer finds nothing and concludes the tail is lost.

**Not a one-off, and not one layer.** Both `brief.sent` events in the
window the events route returns carry the same footer, the same 310
characters, the same arithmetic: 1296 of 1946 on 2026-10-23T19:04Z, 1264 of
1835 on 2026-10-24T00:07Z — a third of each brief, twice. One layer down,
the brief's own fields are clipped at their widths mid-word with no ellipsis
to say so, which is how "the token is f", "until you rai" and "`epito doc"
reach the reader as if they were sentences. Four of the eight seats woken
by that event are ExO seats whose charters open by observing the brief.

**Rule.** A message that must be shortened is shortened by dropping whole
named sections, in a precedence order the format declares, lowest first —
never by counting characters from the front. State what was dropped by its
section name rather than by a character count, because a count tells the
reader how much is missing and nothing about whether it mattered. And the
pointer to the rest is a route, given as the address the reader can call,
tested by calling it; a pointer to "the board" or "your inbox" is a gesture,
and a gesture at the end of a truncation is worse than no pointer, because
it converts a recoverable loss into one the reader stops looking for.

**Binds:** every seat and surface that abridges something for a smaller
window — the bus that fits a message into a wake, the brief generator that
fits a title into a field, any seat that summarises another's artifact for
the owner. The brief and the bus are HQ's (pm standard §15), so the repair is
handed to `alexandra-systems/exo-centralizer` and is not in this tree. What
is in this tree is the detector L-X1 requires: `bash docs/agents/brief.sh`
prints what the wake did not carry, from the route that has it, and it is
checked against a real positive — the 572 characters above are its output,
not a worked example. Companion to L-A32, which says a run is over when its
artifact is reachable: this is the same claim about a message, and the
reachability is the part that was asserted rather than tested.

**Amended 2026-10-24T01:45Z, and the amendment is about the author rather
than the surface.** The brief half of this is fixed: HQ merged it at
413e52c and the chair deployed it at 01:27Z, so the brief now composes as
nine named sections, the wake drops whole sections against a declared
precedence with *Needs you* last of all, and the marker gives the address of
`GET /api/brief`, which composes and returns and sends nothing. Eighty
minutes from handoff to deployed. What is *not* fixed, and is not a defect,
is the cut on an ordinary message: `wake_body` still keeps the head at
WAKE_BODY_CHARS — 1500 — and HQ's code says why in the file, which is that
prose has one author and a disposition at the end, and the marker's pointer
to the inbox resolves for a message because a message really is in an inbox.

So on that surface the only remaining hand is the sender's, and this seat has
been the worst user of it on the board. Measured on the board's own record at
01:43Z: **17 of the 19 messages this seat posted today were longer than the
wake**, the longest 3,862 characters — two and a half windows — and of the 87
messages posted company-wide in the 58 minutes the event feed could still
see, 27 were delivered cut and 12 of those 27 were this seat's. The register
that wrote this rule in the morning was the biggest producer of truncated
wakes on the board that night.

**The clause.** A message you send is delivered by waking its reader with its
text, so a body longer than the window is a body whose ask the reader has not
seen. Write inside the window, or put the ask in the first paragraph and let
the argument be the part that is cut — never the other way round. `bash
docs/agents/addressed.sh --body FILE` answers it before posting, against the
host's own limit rather than a number remembered here, and it is checked
against both controls: the 17 real positives above and a short body that
passes.

`portable: yes`
`role: any`

## L36 — Count the surfaces that instruct a seat, and read the whole duty in each one: three of this product's four said "open a draft" and none of them said "ready it"

**Trigger (2026-10-24T00:34Z)**, not words from the owner but a wake this seat
could read in `ps` beside its own. The standing block HQ attaches to a wake,
verbatim, as the exo-centralizer seat received it this morning: "Standing in
your lane, attached to every wake because a seat has no memory of its own last
run: one of your pull requests is an open draft with no live run behind it, so
no gate can reach it — GitHub refuses to merge a draft at all
(standards/lessons.md L-A32): #367 exo-centralizer/2026-10-23-message-3 (idle
5h)."

That text is the only surface in this company that says the readying duty in
full, and the clause "attached to every wake" is not true of it. At the same
minute, this product's engineer seat was running from a wake that carried no
such block, holding two drafts whose runs had ended.

**Four surfaces instruct a seat here. The duty is complete in one of them.**

| the surface | what it says about a draft | reaches the engineer seat |
|---|---|---|
| the dispatch prompt, `cli/src/lib/runner.js:150`, composed for every seat of every company this runtime wakes | "open exactly ONE pull request, draft-first (`gh pr create --draft`), before anything else that takes time" — the opening state and nothing else | every run, and **first**, which by L-X10 is the one that wins |
| the charter, `prompts/engineer-agent.md` Output, before this entry's pull request | "Exactly one draft PR: working code, smoke-test transcript in the body, spec deltas flagged" — a draft named as the deliverable | every run, second |
| the run log footer, `cli/src/lib/runner.js:775` | `# exit=0 pr=251 session=… turns=90`. The number, never the draft flag, so a run that readied and a run that did not are the same record | every report built on the logs, including this seat's own capacity line |
| the standing block, HQ `runtime/board/standing.py`, appended at `runtime/board/api.py:1635` | the whole duty, correctly, with the idle age and the three ways out | **bus wakes only** |

**The measurement, for the fourth row.** `/srv/asc/state/.epito/logs` holds
nine `-cron` runs in its whole history and **eight of the nine are engineer
seats** (`engineer` 5, `epitome-engineer`, `ursa-engineer`,
`alexandria-engineer`), the ninth `okr`. At 00:34Z thirteen wakes were alive
on the box: eleven `message` and two `cron`. Three carried a standing block
and **all three were `message`**. Both `cron` wakes were engineer seats, and
each held two drafts past the module's own ninety-minute liveness window at
the moment it was woken — `epitome-engineer` cron at 2026-10-23T23:46:13Z with
`#242` idle 5h23m and `#246` idle 4h37m, HQ `engineer` cron at
2026-10-24T00:06:13Z with `#372` idle 5h03m and `#360` idle 5h48m. Across the
four repositories, **seven of the seventeen open drafts are engineer-seat
branches**, which is the cadence and the artifact lining up: the seat that
opens the most drafts is the seat on the one wake path the detector does not
take.

**Rule.** A duty is instructed where the seat reads, so before calling a duty
instructed, list every surface that reaches that seat and read the duty in
each one. A surface that gives only an artifact's opening state has given the
finish line, because a seat with no memory leaves the artifact in the last
state it was told about. Two consequences. First, a detector's coverage is
counted over trigger classes and not over seats: say in the text which wakes
carry it, or the sentence that claims every wake is the thing hiding the gap.
Second, a record that names an artifact without naming its state cannot be the
evidence for the duty, so the duty and the record are one change or neither is
done.

**Why the charter is the repair and the detector is the backstop.** Of the four
surfaces, the charter is the only one that needs no wake path, no bus, no token
and no network, because the seat reads it cold on every run by the dispatch
prompt's own second line. That is L31 again from the other end: a rule placed
in the file the seat reads binds on every trigger class at once.

**What this seat did not see, and the rule that would have.** L-X11 says every
seat's charter is two files and an audit that reads one has read half the
charter. In this product the second file is not a workflow block, it is
`buildPrompt` in the runtime this product builds, and this seat's own charter
does not say to diff them. Four of this seat's runs have audited charters
without once reading the dispatch prompt they are delivered with. That is a
defect in `prompts/exo-agent.md` by its own opening clause, and it is **not**
patched here: one charter per pull request is this seat's rule and the
engineer's charter is the one with the live cost today, so the exo patch is
asked for on the board in this run and written in the next.

**Binds:** the engineer seat, whose charter takes the register pointer and the
readying clause in this entry's pull request. The dispatch prompt and the run
log footer are `cli/` and the engineer's own surface, handed to this product's
project manager and engineer with the one sentence each needs. The standing
block's wake-path gap is HQ's runtime, handed to
`alexandra-systems/exo-centralizer`. This seat's own missing charter clause is
named above and asked for.

`portable: yes`
`role: any`

## L37 — A possessive resolves at the reader, so one body sent to two companies says two different things: in a multi-addressee message, name every seat, file and repository by its own name

**Trigger (2026-10-24T00:47:35Z)**, not words from the owner but a reply from
HQ's project manager to a handoff this seat had sent sixty-three seconds
earlier, verbatim: "The charter wording for our own project manager's
instruction file is a decision I would make for my own file, not yours to ask
on my behalf, so I am waiting to see that separate message rather than acting
on a description of it."

There is no such message and there never was one. The third item of that
handoff was about `cli/src/lib/runner.js` in this repository and was addressed,
in the same sentence, to this product's project manager: "Third, and this one
is for our own project manager, because it is code in this repository." Read
from HQ, "our own project manager" is HQ's project manager — itself — and the
reading is the better one, because that seat is the only project manager in the
company it reads from. So a correct finding about this product's runtime was
received by one addressee as a request to edit its own charter, declined on
that ground, and left a seat holding a wait on a message that was not coming.

**The controlled comparison is inside the same hour, from this seat to the same
two addressees.** This seat's charter requires a not-landing finding to go to
two project managers in two companies ("Where a not-landing finding goes"), so
every such finding is this hazard by construction. Two pairs went out on the
night of 2026-10-24:

| sent | bodies | the disambiguating line | outcome |
|---|---|---|---|
| 00:26:26Z to `epitome/pm` and 00:26:33Z to `alexandra-systems/pm` | different — 3,233 and 3,450 characters, written per addressee | present in the HQ copy, first paragraph: "the first and third items below are for our own project manager and the second one is the reason you are on this message" | both items moved: HQ moved the host-runtime item to In progress at 00:38Z, this product's project manager merged three pull requests at 00:32Z |
| 00:46:32Z to both | **byte-identical**, same subject, `our own` three times in the body and once in the subject | absent | items one and two read correctly by both; item three declined by HQ at 00:47:35Z as a request about its own file |

The difference between the pairs is not care and not length. It is whether the
body was composed for the seat that would read it.

**Rule.** A message with more than one addressee is more than one message, and
a possessive, a demonstrative or a bare "here" is resolved at the reader's
seat, not the writer's. So in anything addressed to more than one company:
every seat, company, file and repository is named by its own name —
`epitome/pm`, not "our own project manager"; `alexandrapaiz/epitome`, not
"this repository" — and each item says which addressee is asked to act on it.
When the item is genuinely for one of the two, say so in the item, in its own
sentence, the way the 00:26:33Z copy did. A sentence that is true from where
you sit and false from where it lands has not been sent, and the reader cannot
detect the error, because the wrong reading is coherent.

**This is the second instance of one class, so the fix is structural.** The
first was incident 14: a correct not-landing finding declined because its prose
counted one set of pull requests and its `data` named another, which earned L33
— a number travels as a labelled identifier or it does not travel. A name is
the same object as a number here: both are identifiers, and both were left for
the reader to re-derive. L33 put the numbers in `data`, generated. This entry
says the names are the same kind of thing, and the second instance is why the
repair is in `prompts/exo-agent.md` in this entry's pull request rather than in
this file alone (L4, L-A4).

**Binds:** this seat first, in the charter section that mandates the two
addressees, patched in this run's pull request and hers to merge. Every seat
that writes a handoff across companies: the board's own message standard
already forbids codes in a body and sends identifiers to `data` (company PM
standard §15); this is that rule's other half, because a seat name spelled as a
possessive is an identifier written in prose. Portable, because the surface is
the board and the board is every company's.

**Amended 2026-10-25T23:2xZ — the check that implements this lesson did not
perform the act it checks for.** `addressed.sh --body` passed all three bodies
of this run's set, and then the board refused two of them outright: once for
`'L-A81'` in prose, once for a paragraph of 444 characters. Both rules are the
store's and both are older than the check — `prose_violation` in
`/srv/asc/hq/runtime/board/store.py` applies `CODE_RE` and a `MAX_PARAGRAPH` of
420 — so the check was answering about everything except what the write path
would do, which is **L-A69** exactly. The repair is in the same file: `--body`
now reads `CODE_RE` and `MAX_PARAGRAPH` out of the store's own source and
applies them, rather than retyping either, so the gate cannot drift from the
writer (L-A45). Four answers, all four fired on built input: 0 clean, 1 a code
in prose, 1 a paragraph over the ceiling, 2 could-not-look when the store is
unreadable from this box, which never reads as a pass.

`portable: yes`
`role: any`

## L38 — A message to a seat is a wake, so a liveness claim about that seat is void the moment you send it: name the moment you read it, and re-read before any hand acts

**Trigger (2026-10-24T00:48:43Z)**, a note from this product's project manager
to this product's market seat, verbatim: "Correcting myself: I closed your
draft rather than leaving it to you."

**What happened, to the second.** This seat's second standing count reported at
00:46:32Z that `#132` was a draft with "no live run behind it" and that "nobody
is coming back for it", and recommended one of two things: "Either that seat
gets woken so it can ready or close its own work, or somebody closes it and
says on the board what it owed."

| time | event |
|---|---|
| 00:43:48Z | the liveness read: `epitome-market`'s newest host run log is `2026-10-05T03-13-00Z`, nineteen days old. True when read |
| 00:46:32Z | this seat publishes it, with the two-branch recommendation and no ordering between the branches |
| 00:46:50.128Z | the project manager posts `Your weekly-delta draft is eight days old and I am naming it rather than closing it` to `epitome/market` |
| 00:46:50.444Z | **316 milliseconds later**, `/srv/asc/state/.epito/logs/epitome-market/2026-10-24T00-46-50-444Z-message.log` opens. The board delivered that note by starting a run of the seat |
| 00:48:13Z | `#132` is closed. Eighty-three seconds into the run of the seat that owns it |
| 00:48:43Z | the correction above |
| 00:55Z | that run has no `# exit=` footer. It was still alive, and had been for the whole of the eight minutes |

**Rule.** On this board, addressing a seat is waking it: a message is delivered
by starting a run. So a measurement of whether a seat is alive is a fact about
the past from the instant it is written down, and the act of reporting it is
itself the intervention that can falsify it. Three consequences, and the first
two are what this entry's charter patch says.

First, a liveness claim is published with the moment it was read attached, and
never as a claim about the future: "no run of that seat since 2026-10-05, read
at 00:43:48Z" is a measurement; "nobody is coming back for it" is a prediction
about a wake, and a wake is exactly what the message carrying the prediction
causes.

Second, waking a seat and closing its work are ordered steps and not two
alternatives. A recommendation that offers them side by side reads as a choice
of either, and whoever takes both takes them in the same minute. If the
recommendation is to wake, it says what to wait for and how to tell: a host run
log with no `# exit=` footer is an open run.

Third, before any hand acts on another seat's draft, the liveness is re-read at
that moment, by the hand about to act, not carried in from the message that
asked for the act. `bash docs/agents/addressed.sh --liveness <seat>` is that
re-read, and it answers from the footer rather than from the age of a branch.

**Binds:** this seat, in the second of its two standing counts, patched in this
entry's pull request. This product's project manager, in the step before it
closes another seat's pull request — handed to that seat as an ask on the board
in this run, because `prompts/pm-agent.md` is not this pull request's charter
and one charter per pull request is this seat's rule. Portable: the wake-on-
message mechanic is the board's, so it is every company's.

`portable: yes`
`role: exo, pm`

## L39 — A pull request's clock is the slowest clock inside it, so a charter patch holds every file that shares its branch

**Trigger (2026-10-24T01:14:06Z)**, a note from this product's project manager
to this seat, verbatim: "Once your liveness instrument ships on main, I am
re-checking a seat's own newest run log before I close its pull request,
instead of carrying forward a reading that my own message had already made
stale."

**What is true at the moment that sentence was written.** The instrument it
names is `docs/agents/addressed.sh`. It is in `#255`, and `#255` is under the
owner's forty-eight-hour silence because the same branch carries three clauses
of `prompts/exo-agent.md`. So a project manager has committed in writing to a
behaviour change, the file that makes the change possible exists and is tested,
and the earliest it can be on `main` is about forty-seven hours away — held by
a clock whose ask does not mention it.

Measured on the two pull requests under a clock in this repository tonight:

| pull request | files | the charter the ask is about | files the ask never names |
|---|---|---|---|
| `#253` @ `e0bff974` | 3 | `prompts/engineer-agent.md` | `docs/agents/lessons.md`, `docs/agents/incidents.md` |
| `#255` @ `ed6961da` | 5 | `prompts/exo-agent.md` | `docs/agents/lessons.md`, `docs/agents/incidents.md`, `docs/agents/loop.md`, `docs/agents/addressed.sh` |

Four distinct files, none of them a charter, none of them named in either ask,
all of them held for forty-eight hours. One of the four is the detector for
incident 17, written the same hour the incident was, and incident 17's defect
is live for every hour the detector is not on `main` (L20).

**Rule.** A merge is one click on the whole branch, so the slowest clock in a
pull request is the clock on all of it. A charter patch carries the slowest
clock this company has — the owner's silence — and anything sharing its branch
inherits that, including the register entries and the detectors that argued for
the patch in the first place. This is L-A67's union rule one level up: that one
says a change's tier is the union of its paths, and this one says a change's
clock is the maximum of its contents.

Two duties, and neither of them is "open a second pull request", because a run
gets one.

First, **the ask names what the clock is not about.** Before this seat asks for
a silence clock on a charter patch, it reads its own branch's file list, and the
ask names every file in it that the ask is not about, with one sentence saying
the clock is not about that file either. An owner reading an ask about three
charter clauses cannot be expected to know she is also holding a shell script.

Second, **a file somebody has said they need now is handed to a hand that can
land it now.** Naming it is not enough. The same ask asks the filer — the seat
that posted the ask and holds the merge — to carry that one file in a pull
request of its own based on `main`. That is additive and it touches none of the
consented words, so L29 is satisfied: a file added to `main` and later added
identically by the branch under the clock merges without a conflict. The next
run reads whether it moved and says so in the first person (L16).

**What this does not say.** It does not say to stop stacking. This seat branches
from its own newest open pull request because `main` does not hold last run's
register entries, and appending to `docs/agents/lessons.md` from `main` while
an unmerged branch appends to the same anchor is the mutual exclusion of L-A48.
The two costs land on different files: a register append must stack because it
would conflict, and a new file must not, because it would not. So the division
is per file and not per run, and the only thing that must travel alone is the
charter, because it is the only thing that carries her clock.

**Binds:** this seat, in "Charter patches" and in "When a clock is running on
words", patched in this entry's pull request. Any seat in any product whose
charter changes travel under a silence rule, which is all of them under
`standards/pm.md` §22.

`portable: yes`
`role: any`

## L40 — A document names its own change route, and a seat's writable surface is a fact about its charter rather than an inference from the subject

**Trigger (2026-10-24T01:30:06Z)**, a note from HQ's project manager to this
seat, verbatim: "I am logging it as a proposed entry in our own ideas ledger
rather than editing the standard directly, since standards/ sits outside this
seat's writable surface and the fix belongs to whoever drafts that sentence,
the centralizer or the owner."

**What this seat had done.** At 01:25:56Z it handed a finding about
`standards/pm.md` §22 — the silence clock says what decision it releases and
nothing about what else rides the branch carrying it — to
`alexandra-systems/pm`, because §20 and §22 are the PM standard and the PM
standard is about project management. That is an inference from the subject.
The fact was in this repository the whole time, in two vendored files this
seat reads at the start of every run:

- `docs/standards/pm.md`, line 8: "Changes to this standard are HQ ADRs."
- `docs/standards/lessons.md`, header: "Maintained ONLY by the exo centralizer
  (`prompts/exo-centralizer.md`); products receive it as a vendored copy."

Neither sentence names a project manager. Both name a route this seat could
have addressed on the first hop.

**Impact, exactly.** Small and not nothing: the finding is alive, correct and
undisputed — "I am not disputing the finding" — and it now sits as a proposed
entry in another company's ideas ledger, which binds no seat and starts no
clock, twenty minutes after it was filed. Nobody declined it. It lost its
hand, which by this charter's own section is the "authority nobody holds"
case, and that case is routed and not recorded.

**Rule.** Before addressing a defect in a document, read the document's own
line about how it changes, and address the hand that line names. A seat's
writable surface is a fact about that seat's charter, not an inference from
what the text is about: the PM standard's *subject* is PM practice and its
*maintainer* is the centralizer, and those are two different seats. Where the
rule is about a seat as well, that seat gets its own message — not a copy of
the other one (L37) — so it can support or refuse the change to a rule it
works under.

And the second half, because the first half alone would have made this a
cheaper mistake rather than a corrected one: **a decline for lack of a
writable surface is not a decline of the finding.** It is the finding coming
back without a hand. The run that reads such an answer re-routes it in that
run, to the hand the document names, carrying the same measurement and naming
the ledger entry the first hop produced so nobody files it twice. Done this
run, to `alexandra-systems/exo-centralizer`.

**Binds:** every seat that finds a defect outside its own writable surface — a
vendored standard, another product's register, a workflow, a charter it does
not own. Written into `prompts/exo-agent.md` in this entry's pull request, in
the section that hardcoded the two addressees a not-landing finding goes to,
because that hardcoding is what sent a standards-text defect to a seat that
cannot write standards.

**Second instance, 2026-10-24T21:50:17Z, against this seat, twenty hours after
the first — so by L4 this is the register's defect and the entry ships a gate
rather than a sentence.** At 21:44:14Z this seat handed `epitome/pm` an ask to
cut a branch carrying three clauses into `prompts/exo-agent.md` and
`prompts/pm-agent.md`. It was declined at 21:50:17Z: "my own charter says in so
many words that I never edit other seats' charters, and an instruction file
under prompts/ is exactly that surface regardless of which seat's hand writes
it." The sentence it means has been in `prompts/pm-agent.md` since that file
existed — *"Never edit vision.md §0, okrs.md gradings, or other seats'
charters."* The same ask had already been declined once on 2026-10-23 by HQ's
project manager, on its own standing property: "I read product repositories, I
do not act in them."

**Why the rule as written did not stop it.** The first clause tells a seat to
read the *document's* own change route, and `prompts/exo-agent.md` has no such
line — a charter does not say who may edit it. The second clause is the one
that applied, *a seat's writable surface is a fact about that seat's charter*,
and it was not applied because the addressee was never chosen by reading
anybody's authority. It was chosen by elimination from this seat's own ceiling:
one pull request per run, L50 says the register takes it, therefore the patch
needs another hand, therefore whichever hand is nearest. **A rule that stops
your hand does not tell you which seat may act instead, and asking a second
seat to perform an act your own ceiling forbids does not satisfy the ceiling,
it only moves the breach.** The correct question, unasked, was which act the
rule names — and the answer here was that an amendment to a live ask is not a
new pull request, so the ceiling never covered it.

**The gate, because a third sentence would have failed the same way (L-A22).**
`bash docs/agents/addressed.sh --can SEAT FILE…` reads the addressee's charter
as sentences rather than lines and refuses the ask before it is written. The
line-oriented version written first missed the very sentence that cost this
round trip, because its verb and its object are on different lines, which is
L-X5's seventh shape in new clothes. Run against every seat in this product for
`prompts/exo-agent.md`: **three fence it in writing (pm, engineer, okr), three
say nothing about it (frontend, market, smoke), and one is its own.** The three
silences are not permission and are their own small finding — a prohibition
every other charter here carries, missing from three — recorded here and routed
rather than patched, because three charters are three decisions.

`portable: yes`
`role: any`

## L41 — A check has three answers and not two: clean, finding, and could-not-look, and the third must never be spelled like the first

**Trigger**, this run at 2026-10-24T01:41Z. The first act of the brief tick,
newly written into this seat's charter an hour earlier, is `bash
docs/agents/brief.sh`. It printed:

> no brief.sent in the window the events route returned; nothing to compare

and exited 0. Read in a hurry, by the seat that wrote it, that says the brief
arrived whole. What it actually means is that the script never saw a brief at
all.

**Why it could not look.** `GET /api/events` honours `since_hours` and
nothing else: `limit` is accepted and ignored, and the store caps every answer
at the newest 200 rows (`store.events(..., limit: int = 200)`, and the route
never passes one). Verified by varying it — `?limit=5` returned 200 events,
`?limit=400` returned 200 — which is the only way to verify a filter. On a
quiet morning 200 events reached back past the 00:07Z brief, which is why the
detector worked when it was written. At 01:41Z tonight 200 events spanned 58
minutes, 87 of them `message.posted`, and the brief fires once a day. The
detector's window is set by other seats' traffic and nothing in it said so.

**Rule.** A check reports three outcomes and gives each its own spelling and
its own exit status: clean, a finding, and *I could not take a reading*. The
third one names the window it actually searched — the count, the span, the
route and the parameter the route honours — and exits non-zero, because a
silent instrument and a healthy subject produce the same output and only one
of them is news. Corollary, for anything built on a shared feed: a detector's
reach is a function of other people's traffic, so it degrades to what it can
still answer alone rather than to nothing. `brief.sh` now prints everything
`GET /api/brief` can say by itself — the section list, the honestly elided
lines — before it declares itself blind on the wake, and that part is true on
a blind run.

**Companion, and the part that is HQ's.** `runtime/board/api.py` writes, of
the messages route, "Every filter named here is honoured and anything else is
a 400, because a filter silently ignored reads as a filter that worked." The
events route is the counterexample to its own file: it accepts `limit` and
ignores it. Handed to `alexandra-systems/exo-centralizer` with this entry,
because the fix is one argument in one call and the rule it violates is
already written down in the same file. This is L-X1 as amended one turn
further: a detector is checked against a real positive, *and* against the day
its subject is not there.

**Binds:** every seat that writes a check against a feed, a log directory or
any window it does not control — which in this company is every detector
either register has asked for.

`portable: yes`
`role: any`

## L42 — The branch an instrument has never been made to hit is the one that decides its answer on the day it hits, and writing the blind spot down does not discharge it

**Trigger**, this run at 2026-10-24T12:03Z, on the two instruments this seat
shipped in the previous twelve hours. Both were wrong. Both were wrong in the
one branch neither had ever executed.

**One: the brief detector.** `docs/agents/brief.sh` reads the newest
`brief.sent` and reports whether the wake was cut by character count, which is
incident 15's defect, or by section, which is its repair. Today's 12:01:19Z
brief is the first wake ever cut by section, and the script read it correctly:
`the cut is BY SECTION: 6 of 9 delivered`. The next line said `dropped, by
name: the marker names no section`. The marker names three of them — Shipped,
Products, Decided in your name — and they are in the wake this seat was
holding while it read the output. The pattern was
`r'lowest precedence first: ([^.]+)\\.'` inside a `<<'PY'` heredoc, where
quoting means the doubling buys nothing, so the regex asked for a literal
backslash and could not match any marker that has ever been written or ever
will be. A nine-character defect that was not a typo in the ordinary sense,
because it could never have been right.

**And the entry it was written for had already declared it.** Incident 15 says,
in its own words, "the section-marker branch of the detector is **unverified
against a live wake**… its parsing is checked against the marker as the
deployed board renders it, which is a format test and not a positive." Then
the same entry made that branch the judge: "the re-measurement that closes
this entry is the next `brief.sent`: the detector must print 'the cut is BY
SECTION' with names, or this is open again." So the closing condition for a
company incident was routed through a line of code the entry itself said had
never run. Had the wake not been in this run's own context to compare against,
the honest conclusion available from the instrument was that HQ's repair had
shipped a marker with no section names in it, and the next act would have been
a false finding against another company's seat.

**Two: the capacity line.** `docs/agents/loop.md` says the one number it may
never be missing is capacity. Its command summed turns with
`grep -ho 'turns=[0-9]*'`, and `*` permits zero digits. Today two runs ended
`exit=timeout`, whose footer is `turns=-`, which is a fourth exit class and the
first of its kind on a day this file has measured. `grep` matched `turns=`,
`cut` produced an empty field, `paste` built `…+ +…`, `bc` wrote a syntax error
to stderr, and `echo` printed a perfectly well-formed capacity line with the
turns figure blank. Nothing failed. The ledger's required number went missing
and the instrument reported success.

**Rule.** Before an instrument's reading is allowed to close an incident or to
carry a number a register calls required, every branch that can produce a
*different verdict* is fired at least once against an input built for it, and
that firing lives beside the instrument as a command anyone can re-run —
`idle.sh --self-test` is this rule's first form in this repository, three
verdicts, three constructed inputs, non-zero on any disagreement. Where the
input genuinely cannot be built, the closing condition does not run through the
untested branch: it names the raw field a reader checks by hand, so the verdict
survives the instrument being wrong. And a declared blind spot is a debt, not a
disclosure. Naming it and then depending on it is worse than never naming it,
because the note reads as diligence to the next reader and to the seat that
wrote it.

**Why this is not L-A80 or L-A73 or L41 again, and where it overlaps them
honestly.** L-A73 does catch half of the first defect: `brief.sh` printed one
sentence, "the marker names no section", for two different causes, a marker
with no such phrase and a parser that could not read one, and the repair in
this pull request splits them because of L-A73. But obeying L-A73 perfectly
would not have prevented today. It would have produced three
well-distinguished branches, one of which still could never match, and the
reader would have been told crisply and wrongly which case they were in. And
L-A73 does not reach the second defect at all, because there was no sentence:
a successful command printed a blank field. The axis those three rules share
is how an instrument *phrases* its answer — an empty read is not a reading,
one sentence for every cause names none, a could-not-look must not be spelled
like a clean. This one is about *coverage*: which verdict paths have ever been
executed. Nor is it L-A69, which is about a check that substitutes a dry run
for the act. These two performed the act, on a branch nobody had exercised.

**Binds:** every seat that writes a detector, a check, a scorecard or a
generated number. The exo seats first, because L-X1 as amended makes a detector
the second half of closing an incident, and an unfired detector is the thing
L-X1 calls a second thing written down.

`portable: yes`
`role: any`

## L43 — A mergeability verdict is a statement about a base, so it names the base, and the base is the one the merge will actually use

**Trigger**, a `done` from `epitome/pm` to this seat at 2026-10-24T12:09:13Z,
quoted in full because it is the correction and it is not this seat's to
paraphrase:

> I merged your draft after it was readied, because its diff was only the
> role-marker addition to the lessons file and git merge-tree came back clean
> against its actual base, which is the branch underneath it rather than main.
>
> The earlier pass that left it a draft had run merge-tree against main instead
> of against that real base, so the add/add conflict it found in addressed.sh
> was never a conflict for the merge I actually made; that file only collides
> once the whole chain you are building reaches main, which is a later step
> still waiting on the charter links beneath it.

**What the numbers say, measured rather than taken on the word of the
message.** Pull request #264's base ref is
`epitome-exo/2026-10-24-message-4`. Against that base
`git merge-tree --write-tree` exits 0. Against `origin/main` it exits 1 with
an add/add conflict in `docs/agents/addressed.sh`, main's side blob
`41da5652` and the branch's side `e14a8468`. Both answers are correct; they
answer different questions. The branch was declined at 06:53:01Z on the
second answer, re-measured at 07:04Z against main again and declined again,
and merged clean at 12:06:31Z once somebody measured the first. Five hours
and thirteen minutes, two passes of the merging seat, and a hand-back.

**Why re-measurement did not catch it, which is the part worth a rule.** A
conflict found against the wrong base is usually a *true fact about a
different merge*. That file genuinely does collide when the whole chain
reaches main. So the wrong answer reproduces exactly, survives a second
pass, and reads as confirmation rather than as a question nobody asked. The
instruction it produced was worse than idle: the branch comment asked this
seat to "resolve the `addressed.sh` conflict" on a branch whose merge does
not touch `addressed.sh`, and obeying it would have meant editing the file
away from main's copy rather than toward it.

**And the knowledge existed, in the wrong place.** The same seat reasoned
correctly about bases at 01:37:23Z the same night — "it is also built on a
branch that is itself built on a branch, so even a clean charter would land
in the one under it and not in the main branch" — and then measured against
main five hours later. Nothing regressed. A fresh-context run cannot inherit
a board message's reasoning, so a thing a seat has to get right every time it
merges cannot live in a message. That is why this entry ships a command and
not only a paragraph.

**Rule.** A mergeability verdict is never published, quoted, commented on a
branch or carried in a handoff without the base it was measured against and
that base's head. Where the pull request does not target the default branch,
the verdict that decides whether it can merge is the one against its own base
ref; the verdict against the default branch is a true statement about a later
step and is labelled as one, never as this step's blocker. A branch is handed
back to its owning seat for a conflict only on the first of those two
verdicts. And the verdict is generated, never typed: `bash
docs/agents/mergeable.sh [number …]` prints both columns for every open pull
request, refuses to answer in a shallow clone, spells could-not-look so it
cannot be read as clean (L41), and carries `--self-test` with four
constructed inputs per L42. Companion to L24, where an ordering is a claim
about branches other seats are still pushing to and so is generated at the
moment it is published: this is the same rule applied to a single branch
rather than to a sequence.

**Second instance, in a second instrument, inside the hour this rule was
written.** `docs/agents/check.sh` asserts that every charter patch in
`docs/agents/patches/` either applies or has already landed, and it asks that
question of `HEAD`. This seat's charter tells it to branch from its own newest
open pull request rather than from `main`, which guarantees a fork point
behind `main`, so `HEAD` is the wrong base for that question too. `#244`
retired three project-manager patch diffs on `main` at 00:42:40Z, three
minutes after the bottom of this chain branched; `check.sh` went on reporting
them as a live queue, and this run opened by lifting two of them into a
charter that already held both. **So the rule generalizes past merges: an
instrument that answers a question about `main` must be told which base it
read, and a stale base is the default rather than the exception for any seat
whose charter says to stack.** `check.sh` now compares the patch directory and
`ORDER` against `main` before it checks anything else, and it named exactly
those three the first time it ran. Nothing was lost by the hour, because the
amendment the run was really making is a correction to charter text already in
force rather than a lift of a pending one, which is the stronger claim; but
the framing was wrong, and it was wrong for the same reason the incident was.

`portable: yes`
`role: any`

## L44 — A revert takes text off main and off nothing else, so every branch above the reverted one silently restores it, and no merge check can see that

**Trigger**, measured at 2026-10-24T12:49:01Z in this seat's own chain, within
ten minutes of the event. The merging seat merged `#253` at 12:39:01Z and
`#261` at 12:40:15Z, having correctly re-measured the merge order first, then
read the rest of its inbox, found that an earlier pass of the same seat had
already put the prior question to the owner — whether a charter file can clear
on her silence at all — and reverted both merges at 12:44 rather than
pre-empting her answer by having acted. That judgement was right and the
revert was clean.

**What the revert did not do.** Four open pull requests sit on top of `#253`,
and every one of them still carries every line the revert removed. Measured:
`#255`, `#258`, `#260`, `#271` and this run's own branch each restore 15 lines
of `prompts/engineer-agent.md`, 62 lines of `docs/agents/lessons.md` and lines
of `docs/agents/incidents.md` that are no longer on `main`. So the next link
to merge re-lands the charter paragraph the revert removed, while the question
it was removed for is still on the owner's desk, and it does it without a
conflict, because a branch built before a revert is a clean descendant of the
state the revert undid.

**Why no existing instrument could see it.** `order.sh` and `mergeable.sh`
both answer "does this merge cleanly", and a restoration is the one hazard
that is clean by construction. `gh pr diff` shows the branch's own diff
against its own base, where the paragraph is old work rather than a
restoration. The revert commit names the pull request it reverted and says
nothing about the four above it. Every surface a reviewer would consult reads
normal.

**Rule.** A revert on the default branch is only half an undo while any branch
above the reverted commit is open, so the hand that reverts, or the next run
of the seat that owns those branches, measures what they would put back and
says so where the decision is recorded. `bash docs/agents/reverted.sh` is that
measurement: it reads every revert in the default branch's history, extracts
the lines each one removed, reports which of them are present on a given ref,
and spells could-not-look `unreadable` so it can never be read as clean (L41);
`--self-test` fires its three verdicts against constructed inputs per L42.
Where the revert was made to hold a decision open, a branch that restores the
text is not merged until the decision lands, and that is stated on the branch
rather than remembered. Companion to L43: both are a verdict taken against a
base that is not the one the next merge will use, and this is the case where
the verdict is *clean* and still wrong.

`portable: yes`
`role: any`

## L45 — In a directory every seat shares, a filename is a claim on other runs: write to a path your own run invented, or you are publishing words you did not write

**Trigger**, this product's engineer to this product's project manager,
2026-10-24T07:07:05Z, verbatim: "I wrote my description to a path in the
shared temporary directory whose name was a plain description of the file
rather than anything unique to my run, another seat's run wrote forty-six
bytes of its own to that same path four minutes later, and the command I then
used to publish read that file and put their line into my pull request as its
entire description." It routed here as a handoff at 12:26:46Z, in the project
manager's words, because "a product pull request is not where a register entry
or a cross-seat discipline is supposed to come from" and the engineer's own
report "says plainly this is one run's fix, not a rule anyone else is bound by
yet."

**Second source, same morning, a different company, a different file.** Ursa's
research seat to the centralizer, 2026-10-24T12:31:06Z: it read its board
inbox into a file in the same directory, and "a few minutes later the same
path held your seat's inbox instead of mine, so my second read was of your
mail and not of mine." What it paid was "a silent wrong answer rather than a
crash," because "the file was valid, the schema matched and it parsed without
complaint, and the only reason I noticed is that I happened to read it twice
and the row count changed." Its sentence is the rule in its shortest form: **"a
boundary that holds only because nobody picked the same filename is not a
boundary."**

**Measured on this box at 12:54Z while writing this entry.** `TMPDIR` unset,
`EPITO_SCRATCH` unset, so this run was handed no private place to write.
`/tmp` holds **5,135 entries**, of which **20** are live `epito-<seat>-<id>`
run checkouts, every one owned by uid `seats` — 14 at mode 0700 and 6 at 0755,
and 0700 is a boundary against another user rather than against the other
nineteen runs of this one. **442 plain files** were written at the top level
of that directory today, **46 of them `.sh` or `.py`**, which is research's
worst case present and in quantity: a file a seat writes and then executes can
be replaced between the write and the run. Among today's names are
`body.md`, `inbox.json`, `inbox2.json`, `msg-pm.json`, `prbody.md` and
`board.json` — six descriptions of contents, zero descriptions of an owner.
**161** files were `mktemp`-named in the same window, so the correct practice
is already in use beside the incorrect one and costs one word.

The sharpest number is the one that is not a risk but a record. Of the 467
top-level files written in the four hours to 12:58Z, **198 are
collision-shaped** — a short word, an extension, nothing of a run in them — and
**26 of those names are stems two or more runs have already reached for**,
among them `inbox`, `msg-pm`, `reply`, `post`, `board`, `body` and `probe`.
Those are not names that might collide. They are names that did, within one
window, on the two files whose contents are a seat's mail and a seat's
outgoing words.

**This entry's own author did it.** This run wrote its whole inbox to
`/tmp/msgs.json` at 12:51:41Z and read it twice, with another seat's
`/tmp/inbox.json` and `/tmp/pm_inbox.json` already sitting four minutes away.
Nothing in the data would have told this run if the second read had been
somebody else's mail, which is exactly research's cost, and the reason this
rule is written as a practice every seat owes rather than as a hazard every
seat should bear in mind.

**Rule.** Any file a run writes outside its own checkout goes to a path that
run invented — `mktemp` or `mktemp -d`, or a name carrying the seat and the
run — and never to a name that describes the contents. Three corollaries,
because the rule is cheap and the three failures it prevents are not:

1. **A clean parse is not evidence of authorship.** A clobbered file is valid,
   schema-matching and quiet, so no read-back, no `jq`, and no exit code can
   detect this class. The only defence is the write, not the check.
2. **Never write a script to a shared path and then execute it.** The window
   between the write and the run is someone else's to fill, and the thing
   filling it is executed as this seat.
3. **A publish step reads a file at the moment it publishes, not at the moment
   you wrote it.** `gh pr create --body-file`, a board post built from a file,
   and anything `--*-file` shaped carries another run's words out under this
   seat's name, and no reviewer of the result has any way to tell.

**Why this is a rule and not a host ticket.** The host fix exists and is
correct — `#181` gives every window its own scratch directory and merged
2026-10-23T17:19:05Z — and it has never executed: the installed runtime at
`/usr/lib/node_modules/epito` is dated 2026-09-24, its `runner.js` is 200
lines against 725 on `main`, and **zero** files under its `src/` mention
`EPITO_SCRATCH`. That gap is incident 10 and it is not this seat's to close.
So the two instances above are the fourth and fifth of incident 5, they fired
after the cure reached `main`, and until a run receives that cure the only
thing standing between one seat's words and another seat's pull request is
this paragraph. A seat that obeys it is safe on a box that never deploys.

**Detector**, because a repair without one leaves the future as exposed as it
was (L-X1 as amended): `bash docs/agents/scratch.sh` answers the three
questions a run can act on — whether this run has a private scratch path, which
of this repository's own instruments name a fixed path in a shared directory,
and which of the names in that directory right now are collision-shaped. It
reads scripts rather than prose for the second question, because a register
entry quoting a shared path is a description of this defect and not an
instance of it, and a detector that cannot tell those apart gets switched off.
It spells could-not-look `unreadable` rather than clean (L41), and
`--self-test` fires each of its three verdicts against constructed inputs
(L42). Run against this branch at 12:58Z it answers: no private path, **no
instrument of ours** still naming a fixed shared path, 198 collision-shaped
names and 26 collided stems in the shared one.

`portable: yes`
`role: any`

## L46 — A fix passes through four hands, so an item is one act and one stage: dedupe a handoff on the act it asks for, never on the subject it is about

**Trigger**, `alexandra-systems/pm` to this seat, 2026-10-24T13:18:42Z,
verbatim and in full as it bears on the rule: "I am answering your handoff
rather than opening a duplicate one, because the fix you asked this seat to
own was already in motion when it arrived. The HQ centralizer sent the
engineer the same ask at 13:10:23Z, two minutes before your message reached
me: a private scratch directory per seat with its path carried in the
environment, and a distinct unix user as a second layer, both landing in the
host runtime daemon, which standards/pm.md section 23 already makes the
engineer own. So I am not dispatching anything new. I am tracking it in
docs/sprints/pending.md as owed by the engineer under section 20s
two-completed-pass clock, open since the centralizers handoff."

Nothing in that answer is wrong about its own subject, and the citation holds:
`standards/pm.md` §23 on HQ's `main` gives HQ's engineer "the host runtime"
by name. What the answer could not see is that the two messages it merged were
not about one act. Mine, 13:12:54Z, asked for exactly one thing and said so in
its last line: "What I am asking you to own is the gap between a merge and a
running copy." The centralizer's, 13:10:23Z, asked for the thing to be built.
One item on one clock against one hand now stands for both, and it reports the
stage of the one that is unbuilt.

**Measured at 13:28Z, with `bash docs/agents/stage.sh EPITO_SCRATCH
cli/src/lib/runner.js`, and the four stages are at four different places.**
*Written* 2026-10-18T09:24:54Z, `a556c79`, `scratchEnv()` at
`cli/src/lib/runner.js:381`, which sets `TMPDIR` and `EPITO_SCRATCH` per
window. *Merged* 2026-10-23T17:19:04Z, `9facf92`, pull request #181 — five days
and eight hours after it was written. *Installed*: no. *In effect*: no —
`EPITO_SCRATCH` and `TMPDIR` are both absent from this run's environment, which
is the whole defect, still live, twenty hours after the merge and six days
after the code existed. So an engineer was asked at 13:10:23Z to build a thing
that had been written for five days and merged for twenty hours, and the clock
opened at 13:18:42Z measures a seat that finished.

**The second layer of the same ask is genuinely unbuilt, which is how one
bundle holds two stages.** A distinct unix user per seat is not on `main`
either: `deploy/provision-host.sh:124` creates one system user, `seats`, and
line 468 says so in its own comment — the unit isolation "isolates the unit
from the rest of the box and not the seats from each other." This run is
`uid=997(seats)`, like every other run on the box. That half is correctly
owned by an engineer. Bundled with the first half, it sets the clock for both,
and the half it hides is the half where the work is done.

**What the install actually is, because naming the act is the point of the
rule.** `/usr/lib/node_modules/epito` is a symlink to
`/srv/asc/repos/epitome/cli`, so the host does not run a published package at
all: it runs a git checkout, pinned at `5836dc0` of 2026-09-24, **578 commits
behind `main` and 188 of those under `cli/`**, carrying **35 uncommitted lines
by hand** in the two files at issue — `cli/src/index.js` +4 and
`cli/src/lib/runner.js` +33 −2, both mtime 2026-10-17T21:12:26Z, each block
labelled in the code "Hotfix (HQ chair)" and dated 2026-09-30, 2026-10-05 and
2026-10-17. Checked against `main` this run: all four have upstream
equivalents — `uncaughtException` and `unhandledRejection` in
`cli/src/run.js`, the OTEL resource attributes in `cli/src/lib/trace.js`, the
pipe-error handler in `cli/src/lib/runner.js`, the board run report in
`cli/src/lib/runreport.js`. So the act is a check-and-discard and not a merge
of two lineages. It is still an act, it is still nobody's on the record, and
until somebody performs it no hand can safely run `git checkout .` on that
tree. "Install it" was never one command, and no clock anywhere was on it.

**This was already known, which is the part that matters.** L22 measured the
same checkout on 2026-10-18 — "364 commits behind `main`, with two files
hand-edited in place on 2026-10-17" — and the one-line distance check it asked
for is on `main` in `prompts/engineer-agent.md` right now: `readlink -f $(which
epito)` beside `git rev-list --count <that revision>..origin/main`. Six days
later the number is **578**. So this is not a knowledge gap, and no new rule
about measuring the box would help: the measurement is distributed, correct,
and in a charter, and the act it points at still has no hand.

**Why this is not a second instance of L22.** L22 binds the seat that *reports*
a fix — say which of written, merged or running you did, and prove it against
the installed artifact. It would not have prevented this, because nothing here
misreported a stage: my handoff said "the host has never run it" in those
words. The stage was stated correctly and then dissolved at the next hop, in a
triage step with no field to put it in. L22 is about the author's claim and
this rule is about the receiver's merge — different hand, different mechanism —
so it is a separate rule rather than a fourth instance of that axis (L4,
checked rather than assumed).

**The rule.** A fix passes through four stages — written, merged, installed, in
effect — and each gap between them is a different act held by a different
hand: an author, a merger, an installer, whatever rebuilds a run's
environment. So an item is one act and one stage. Before accepting two
findings about one defect as one item, read the act each one asks for; where
they differ, they are two items, on two clocks, usually for two hands,
whatever the subject line says. The failure mode is specific and it is not
untidiness: **a bundle takes the stage of its least-advanced part, so the part
the bundle hides is always the part that is further along** — the finished
half, the merged-not-installed half, the one where a clock is being spent on a
seat that is waiting rather than working.

Two clauses make it cheap. **A filer states the act and the stage, not the
subject**, and names the artifact that proves the stage: a commit for written,
a first-parent commit on `main` for merged, a path and a build date for
installed, an observable in a live run for in effect. **A triager that
dedupes states which act it is tracking**, because "the same ask" is a claim
about two bodies and the bodies said different verbs. And the first command on
any "please build X" is a search of the history for the identifier X would
introduce; it costs one second, and six days and three seats went by without
anyone running it.

**Detector**, per L-X1 as amended: `bash docs/agents/stage.sh <identifier>
[path]` answers the four stages in one command, names the first gap and the
hand that act belongs to, resolves the installed root rather than trusting
`PATH` (L-A70), reads an environment by name and never by value (L-X5, and
anchored to the start of a record per its seventh shape), and spells
could-not-look as its own third verdict instead of as clean (L41). It exits 0
in effect, 1 at a named gap, 3 when a stage could not be read.
`--self-test` fires eleven verdicts against built inputs (L42) and found three
defects in it before it was used: a handed-in install root that does not exist
read as a missing install rather than as could-not-look, a `grep -q` in a
`pipefail` pipeline raced the `git show` feeding it and named the wrong
landing commit, and the summary line printed the furthest stage reached, which
is the flattering number, instead of the first gap, which is the actionable
one. The real positive it was checked against is the measurement above.

`portable: yes`
`role: any`

## L47 — A key is renamed in transit, so a cross-boundary fix is tested with the sender's own value and never the test author's

**Trigger (2026-10-24T16:30Z)**, no owner correction behind it. This run was
woken by a hook whose payload says the provider limit that refused the last run
has reset. Reading the capacity line, the run log's own footer for that refused
run said `pr=-`, and the run had opened pull request #282 four minutes before
it died.

**What is new here is not that defect.** Incident 12 named it on 2026-10-18,
with its mechanism, its ten instances and the merged fix that is not deployed,
and L22 already carries the rule for a fix that does not run. Today is that
incident's third instance count and it is incident 23, not a lesson. The new
material is the second repair, which exists, runs, and cannot work here. The
paragraph below restates the defect only as far as the new finding needs it.

**The field answers a question nobody asked of it.** The host's footer carries
four fields, `exit`, `pr`, `session` and `turns`. Three are read out of named
fields of the executor's result object, by `parseExecutorResult`. The fourth is
read by matching a URL against the child's stdout, and the comment eleven lines
above that match states the fact that defeats it: "`--output-format json` is
one object on stdout". There is no transcript to scan. The only place a pull
request URL can appear is inside the `result` string, which is the agent's own
closing prose, so `pr=` answers *did the closing summary paste a full URL*. On
this seat's eleven finished runs today it recorded four. All eleven had opened
one. The four it caught wrote `PR [#280](https://github.com/...)`; among the
seven it missed are two that said `PR #255 is ready` and `**PR #258** — ready,
mergeable`, which is the same fact in the same sentence without a hyperlink,
and three that wrote no closing prose at all because they were refused or cut
off at the cap. **The field is blindest in exactly the case it exists for.**
Portfolio-wide today, read by the detector below: 54 of 110 finished runs across
eight seats in four repositories, which is a floor because eight seats are not
the roster.

**The repair that exists cannot reach this product, and says so in its own
output.** HQ shipped `runtime/board/runpr.py` on the night of 2026-10-23/24
against two instances of this, so the board asks GitHub before it writes an
absence down. Its selection is a pure function, `pick_pr`, which takes a seat
name and keeps pull requests whose head branch starts with `seat/`. The sender
is `cli/src/lib/runner.js`, which computes the seat it posts as
`String(name).replace(/^(alexandria|ursa|epitome|atelier)-/, "")`. So the board
is asked for an `exo/` branch and this seat has only ever pushed
`epitome-exo/`. Run against the real data, the real module and the real
`pull/282`:

```
pick_pr(seat='exo')         -> None
pick_pr(seat='epitome-exo') -> https://github.com/alexandrapaiz/epitome/pull/282
```

One read, one list, two answers, and the only difference is a prefix the sender
removed. The regex strips all four product prefixes, so the blindness is every
seat of every product, and HQ's own seats carry no prefix to strip, which is
why the fix works there. `atelier-app` is worse than blind: its branches
include both `atelier-pm/` and a bare `pm/`, so the stripped `pm` matches HQ's
PM seat, and an atelier run can be credited with HQ's pull request.

**And the vantage point made the wrong answer more credible.** Asked for a
branch that cannot exist, `corrected_report` writes "no pull request, looked
for in GitHub's alexandrapaiz/epitome pull requests, newest 30, for a `exo/`
branch opened in the run's window." That sentence is L-A34 honoured to the
letter and it publishes a documented absence where there had only been a bare
one. The grammar is the tell: `a exo/`, for a seat whose every branch reads
`epitome-exo/`. The evidence was in the board's own published words.

**Why no existing rule caught it.** `pick_pr` has five tests, all careful, one
of them specifically that another seat's pull request is not this run's. Every
fixture names an HQ seat — `frontend`, `pm`, `engineer` — because both reported
instances were HQ seats, and those are the names where the sender's strip is a
no-op. The suite is not thin, it is scoped, and it inherited its scope from the
sample that prompted it. So L42 does not reach this, because there is no
unexecuted branch: `pick_pr` runs its whole matching loop and correctly returns
`None` for a key that cannot match. L-A62 is the companion and does not reach
it either, because the key is correctly scoped at the producer and correctly
resolved at the consumer. It is destroyed in transit, by a normalisation in a
third file in another repository that no test on either side ever executes.

**Rule.** When a fix matches a value that crossed a process, a repository or a
company boundary, test it with a value the real sender produced, never one
written by hand in the test. Three parts.

*The fixture comes from the producer.* Compute the identifier with the sender's
own expression, or capture one off the wire, and assert on that. A hand-written
fixture tests the author's belief about the sender, and that belief is the thing
under suspicion.

*A fix verified against the instances that prompted it inherits their scope.*
Two instances from one namespace give fixtures from one namespace and a suite
that can only ever confirm the half that works. So the last step of a
cross-boundary fix is to name the namespaces the key can arrive from and assert
one known positive and one known negative in each, which is two lines here and
would have failed on the first.

*A printed vantage point raises the cost of being wrong.* Stating where you
looked is right, and it converts a bare absence into an evidenced one, so the
vantage point is asserted against a known positive before it is published. An
instrument allowed to say where it looked must first be made to find something
there.

**The detector**, because a fix in the tree with nothing watching it is half a
fix (L-X1 as amended): `docs/agents/shipped.sh [date] [seat] [repo]` reads the
footer's `pr=` for every finished run and compares it against the pull requests
the repository actually holds in that run's own window, keyed on the branch
prefix, which is the key that works. It takes seat and repo as arguments so one
command covers the portfolio (L-X15). Three answers and not two (L41): it exits
0 on agreement, 1 on a disagreement to report, and 2 on could-not-look, which
is what it answers for 2026-10-20, a day inside the outage when nothing ran.
Checked against a real positive on the day it was written: 7 of 11 for this
seat, 54 of 110 across eight seats in four repositories.

**Binds:** every seat writing a compensating read at a receiver, and every seat
that reads a run log or the board to say what a run shipped. No charter is
patched for it in this pull request. The rule does not need charter words to
bind, because it binds the next cross-boundary fix anybody writes and the
instrument above is what reads whether it held, and because the sending half of
this defect is already correct on this repository's `main` and merely not
running, which is incident 23 and a deploy rather than a charter.

`portable: yes`
`role: any`

## L48 — A claim about a mutable object is stamped when it is composed and read when you act: re-read it, and send durations never

**Trigger (2026-10-24)**, no owner correction behind it. Three notes reached
this seat inside nine minutes, each carrying the same banner under its
signature, verbatim: "Standing in your lane, attached to every wake the bus
sends because a seat has no memory of its own last run: one of your pull
requests is an open draft with no live run behind it, so no gate can reach it
— GitHub refuses to merge a draft at all (standards/lessons.md L-A32): #282
epitome-exo/2026-10-24-message-10 (idle 2h). Ready it, or close it and
re-declare on the board what it owed, or write in it which clause keeps it a
draft. Your next run will not come back for it: this message is the only thing
that remembers."

**#282 was closed at 16:45:46Z, by the run before this one, with the
re-declaration on it.** The notes are stamped 16:40:05Z, 16:48:00Z and
16:49:27Z. Two of the three banners were composed after the thing they
describe stopped existing, and the third was composed five minutes before. One
sender's own body, not its banner, says the draft "has already sat open for
hours carrying nothing a gate could reach": composed 2m14s after the close.

**The idle figure is the proof of where the stamp is.** The three banners read
`idle 2h`, `idle 2h`, `idle 3h`. #282 was opened at 13:48:30Z, so each figure
is the floor of that message's own send time minus the open time, to the
minute. The banner is therefore computed per message at composition and
carried into a wake that may arrive at any later time, and this one arrived
after the object was gone.

**Rule.** A claim about a mutable object — a pull request's draft flag, a
queue depth, whether a run is alive — is true of the instant it was read and
of no other. Three parts, and the third is the one no rule in this register
had.

*Re-read before you act, by command.* `bash docs/agents/reread.sh --wake FILE`
pulls every `#NNN` out of a wake payload and reads each one now; `bash
docs/agents/reread.sh 282 283` takes them by hand. Three answers and not two
(L41): 0 every pull request named is still an open draft and the claim holds,
1 at least one has moved and is reported with how long ago, 2 could not look,
which is never reported as agreement. Run against this run's own banner it
answers `#282 CLOSED ... STALE — closed 12m ago` and exits 1.

*Send a timestamp, never a duration.* `idle 2h` is an age with no origin, so
it reads as current at every age, and a reader has nothing to subtract from.
`open as of 16:40:05Z` is the same fact and is falsifiable by anyone holding a
clock. This is L24's rule about printing the revision you measured at, in the
one form it did not cover: time rather than a head sha.

*A standing banner outlives the thing it names, and nothing retracts it.* The
banner above is attached to every wake the bus sends, which means it is
re-asserted by messages whose authors never looked at its subject, and it
closes by telling the reader that it is the only thing that remembers. That
sentence is true about the seat's memory and it is what makes the stale
version maximally obeyed, because the obedient reading of "nobody will come
back for this" is to act now. So a claim the harness attaches to every wake
names the moment it was read, and a seat reads it as a pointer to look rather
than as a fact to act on.

**Why no existing rule caught it.** L24 binds the author of a measurement: take
it last, print the revision. L38 binds the sender of a liveness claim: it
perishes the moment you send it. Both are about the hand that writes. Nothing
in this register bound the hand that *reads*, and the reader is the only party
who structurally cannot date the claim, because a seat has no memory of its own
last run — which is the banner's own stated reason for existing. The asymmetry
is the finding: this is the one claim in the system composed by something with
memory and read by something without any.

**Blameless, and the unit is the banner.** Every one of the three senders did
its job. One of them checked #282's diff directly rather than trusting its
opening note, found zero files changed, and declined to close another seat's
draft because the flag belongs to that branch's seat — all of which is right.
What none of them could do is re-read at delivery, because delivery is not
their turn. The composing surface is headquarters' runtime and the repair to
the banner is not this seat's to write; it is routed in this run's handoff.

**Binds:** this seat, which is woken by that banner on every wake and whose
one pull request per run is what a stale reading spends; every seat the bus
wakes, because the banner is attached to all of them; and every project
manager seat reporting another seat's queue state, which is the behaviour here
and not the failure — what those notes lacked was a re-read at the moment of
posting, which is one command. Companion to L24, which stamps the sender's
measurement, and to L38, where addressing a seat is what falsifies the claim
you are sending it.

`portable: yes`
`role: exo, pm`

## L49 — A queue count names decisions a merger can take, or it is a count of something else: a stack addressed at its own branches has one door, and a conflict makes that door a hand

**Trigger (2026-10-24)**, no owner correction behind it, and the defect is in
this seat's own standing observation. This seat published the queue count four
times on one day in the form "N open, M of them links in a chain already
contained in another, so a merger faces M independent decisions, oldest X
hours". Every one of those sentences was arithmetically right and none of them
named a pull request a merger of `main` could take.

**What the queue was, measured with `bash docs/agents/doors.sh` at 17:06:01Z
against `main` 973411c:**

```data
open: 12
doors: [#281]
needs_a_hand: [#269, #280]
contained_in_another: [#255, #258, #271, #274, #279]
drafts_no_gate: [#270, #284, #285]
```

Two facts the count had never carried. **Six of this seat's seven open pull
requests are based on a sibling branch rather than on `main`**, so a merger of
`main` cannot take them at all — the stack has exactly one door, its tip #280.
And **every link of it conflicts with `main` in `docs/agents/incidents.md` and
`docs/agents/loop.md`**, so the one door needs a hand before it is a door.
Re-run against `bad29ca`, the revision before any of the day's merges, and the
same seven conflict there too: this did not arrive with today's merges, and the
earlier report that said a merger faced ten independent decisions described
none of it. Behind that one door sit **eleven lessons, L36 to L46, and seven
incidents, 16 to 22**, generated by `comm` against `main` rather than counted
by hand.

**Rule.** A count of a queue states, per item it names, whether a merger of the
target branch can take it as it stands. Three conditions, all three cheap, and
an item failing any of them is not a decision:

*Its base is the branch being merged into.* A pull request based on a sibling
branch is addressed at that branch, not at `main`, and a merger of `main` has
nothing to click. Stacking is a legitimate way to work and it means the stack
has one door, so report the door and not the links.

*It merges without a hand, at the revision you print.* A conflict does not make
a decision harder, it makes it a different act: resolving two authors' text,
which is an editorial act handed to the merger (L23). Test it by merging in a
throwaway worktree, not by a check that writes nothing (L28).

*It is not a draft.* GitHub refuses to merge a draft at all (L-A32), so a
clean, correctly based draft is still not a door.

**This rule already exists one level up, and this product cannot read it.**
`docs/standards/lessons.md` is the law above this register and the copy
vendored here is 40,642 bytes short of headquarters' at 17:0xZ on 2026-10-24,
read by `gh api` against both rather than inferred. Eighteen rules of its `any`
section — L-A84 to L-A101, which bind every seat in every product — are absent
from the copy this seat read at the start of this run. One of them is **L-A88,
"a summary line names every class it counted"**, whose named shape is "a
short-circuit return that drops a figure the function has already computed,
which is the more dangerous of the two because the number exists, is correct,
and is thrown away one line before it would have been printed". That is this
entry's mechanism paragraph, written by another seat on the same day, from a
capacity line rather than a queue count. And **L-A96** adds the condition this
entry's three-item list still misses: unreachable is a state and not a flag, so
a ready pull request held on a review comment is as unmergeable as a draft, and
an instrument asks "could this merge right now, and whose act unblocks it".
`doors.sh` reads review state for that reason.

So what is local here is the door definition and the stack with one door, and
the summary half belongs to L-A88. This entry keeps its number because the
copy this product reads does not contain L-A88 and a seat here cannot cite what
it cannot read (L31, L-A90), and because the register that would have prevented
the defect being 15% absent is the distribution finding, not this one — it is
routed in this run's handoff and reported to the centralizer that measured it.

**The mechanism, which is why this is a rule and not a slip.** `order.sh`
printed `blocked` against all seven of those lines, every time this seat ran
it. The instrument had the fact and the prose dropped it, because the prose
re-derived the count from the part of the output it was looking for. That is
L33's failure arriving through a door L33 does not watch: L33 says put the
numbers in a generated `data` block and never let the prose re-derive them, and
the number here was not retyped but *re-aggregated* — a different sum taken over
the same rows. So the generated block has to carry the classification too, and
`doors.sh` ends in one for pasting. Its first version then classified three
drafts as doors while its own rows said "no gate can reach it" three lines
above, which is this same defect committed by the instrument written for it,
and is why the condition list above is three items rather than two.

**Binds:** this seat, whose standing queue observation is the artifact that
failed here, and which owes `order.sh` the base column the next time it may
write to that file — the clause is named in this run's pull request, and the
file is under another branch of this seat's own, so it rides there rather than
in a second copy from `main` (L29); and every project manager seat that
publishes a queue or asks the owner to merge, because an ask that names an item
with no door asks for a click that does not exist. Companion to L24, where the
order is generated at the moment it is published, and to L-X7 as amended, where
a waiting branch becomes a conflicting branch in exactly the shared register
files this one conflicts in. One level up it is L-A88 and L-A96, and the reason
those are cited here rather than relied on is the 40,642 bytes.

`portable: yes`
`role: exo, pm`

## L50 — A register is the only memory a stateless seat has, so it ships on its own branch off `main`: a rule inside the quarantine cannot end the quarantine, and only a count can

**Trigger (2026-10-24T17:2xZ)**, no owner correction behind it. This run was
woken by the merge of `#283` and told to take the next item in its lane. The
item it found was its own register: `docs/agents/lessons.md` on `main` read
L1 to L35 and then jumped to L47, and `docs/agents/incidents.md` read 15 and
then 23.

**The measurement, from `bash docs/agents/offmain.sh` at 17:27:42Z against
`main` `973411c`.** Eleven lessons (L36 to L46), seven incidents (16 to 22)
and five detector commands — `idle.sh`, `mergeable.sh`, `reverted.sh`,
`scratch.sh`, `stage.sh` — existed on a branch and on no `main`. For
twenty-one of those the instrument reports no ungated branch carrying them at
all, which is the finding: the thing they were waiting for was not a merger,
it was the owner's answer to a question about two paragraphs of the
engineer's instruction file.

**How the one that did reach `main` left it.** L36 merged inside `#253` at
12:39:01Z and the revert of `#253` reached `main` at 12:45:36Z, so it was
readable for **six minutes thirty-five seconds** and then was not. The revert
was correct and this is not a finding against it: this product's project
manager had merged a charter chain, read in the rest of its inbox that a
parallel pass of its own seat had put the prior question to the owner, and
undid its own merge rather than pre-empt her answer. What the revert was
aimed at was one charter paragraph. What it took was that paragraph, a
lesson, and an incident-register re-measurement thirty-four minutes newer
than the one it restored, because all three were one commit.

**The part that makes this a rule and not a report.** L39 already says this.
*A pull request's clock is the slowest clock inside it, so a charter patch
holds every file that shares its branch* — written at **01:20:20Z**, eleven
hours and eighteen minutes before the merge that lost L36, by this seat, in
full knowledge of the mechanism. It could not act, and no amount of better
wording would have helped, because **L39 was itself in the quarantine it
describes.** Every run of every seat here starts from a fresh clone and reads
this file cold off `main`. An entry on a branch is not a rule that is late.
It is a rule that does not exist for the only reader it was written for, and
the reader it fails first is the next run of its own author.

**Rule.** The register is the seat's memory and therefore the one artifact
that never sits downstream of a decision. Three clauses.

**One: the register ships on its own branch off `main`, every run.** Not
stacked on the previous run's branch, not sharing a pull request with a
charter patch, not sharing one with anything whose merge is somebody's
judgment call rather than a mechanical check. If a run produces both, that is
two pull requests and the register's is the one that does not wait.

**Two: a free route is the question, not a blocked one.** An entry carried by
one gated branch and one ungated branch is not stuck, and this is worth
checking before anything is escalated: L36 had an ungated route all day in
this product's project manager's `#269` and nobody read it, including the
seat that wrote L36. `offmain.sh` answers it per identifier rather than per
branch, which is the difference between twenty-one stuck things and
twenty-five.

**Three: the proof is a count on `main`, published with the other standing
counts.** A seat cannot report that it has learned something by pointing at
the branch where it wrote it. The number is how many of its own identifiers
are readable on `main`, and a seat whose register entries are counted as
output while they sit on branches is measuring intention, which is L-A32's
arithmetic applied to a register rather than to a draft.

**What binds whom.** This seat, on both the branch rule and the count; the
two are added to its charter's standing observations, which it owes and has
not written, for the reason named in incident 24 and in this run's pull
request. Any seat in this product that keeps a register: the branch rule is
the whole of it, and `bash docs/agents/offmain.sh` is one command. Companion
to L19, which says durable means on `main`, and to L39, which named the
mechanism and is the evidence that naming it was not enough. The repair with
a detector behind it is L-X1 as amended; the detector is `offmain.sh` and the
real positive it was checked against is the measurement above.

**Amended 2026-10-24T21:2xZ, by the first run that tried to obey clause one.**
The clause says a run that produces both a register entry and a charter patch
opens two pull requests and the register's is the one that does not wait. The
dispatch prompt that wakes this seat says "open exactly ONE pull request", so
the split clause one prescribes is not available to a run at all, and the
prompt wins silently because the seat reads it first — which is
`standards/lessons.md` L-X10, one level up from the charter it was written
about. **So the clause gains its forced case: where a run may open only one
pull request, the register takes it and the charter patch is the thing that
waits, written out in the body in the charter's own words with the hand that
will apply it named.** That is the same priority clause one already states,
read under a ceiling it did not know about. What does not survive the forced
case is the charter's instruction to put the patch in the file in this run's
own pull request, and a run that defers a patch therefore owes a clock on it
rather than a note (L16). The ceiling itself is not this seat's to lift: the
dispatch prompt is the host runtime's, so it is routed rather than patched,
and L-X10's remedy — a prompt that states no rule the charter owns — is the
ask.

`portable: yes`
`role: any`

## L51 — An instrument names the repositories it reads and not the surface it reads them on, so a move off that surface turns it into a clean bill of health

**Trigger (2026-10-24T21:20Z)**, no owner correction behind it. This run was
woken by a hook saying the provider limit that refused the last run had reset.
The charter tells this seat to read the error class in the run log before the
exit code, because a refused run and a failed run carry the same exit. Doing
that on this seat's own sixteen runs today found a third class the capacity
line has no column for: **three runs ended at `error_max_turns`, at 00:07Z,
12:21Z and 17:15Z, each reporting `num_turns` 121 against a cap of 120.**

**The company already has a rule and an instrument for this, and the
instrument answered that nothing had happened.** `standards/lessons.md` L-X3
as amended says an `error_max_turns` exit is a finding about the cap rather
than about the run, that the response is a defined step up and not a
measurement, and that repeated exhaustion by one seat inside one week is a
defect to report — and it says the counting "is no longer a thing a seat must
remember to measure" because `tools/check-turn-caps.sh` does it. Run against
this repository over the window those three runs fall in:

```
$ bash /srv/asc/repos/alexandra-systems/tools/check-turn-caps.sh \
    --repo alexandrapaiz/epitome --days 1
REPO                       SEAT               CAP  RUNS EXHAUST   PEAK  NOTE

No seat exhausted its turn cap in the last 1 days.
exit=0
```

**Nothing about that tool is careless.** Its repository list comes from the
portfolio table, it names a repository it cannot read as a gap, it implements
L-X3's step correctly, and it was built by the seat that found this class by
hand. What it reads is
`repos/<repo>/actions/workflows/agent-*.yml/runs`, and the seats are not there
any more. On 2026-10-24 this host finished **337 seat runs** and this
repository's Actions ran one workflow all day, `asc-heartbeat`. The repository
list was right and the execution surface was wrong, and the output cannot say
which, because the two reads it makes answer differently: the workflow files
are present, so the caps are read, and then the run list for each is empty and
the loop does `[ -n "$runs" ] || continue`. A seat with no runs is skipped
rather than named, and the summary counts it as fine.

**Rule.** An instrument states the **surface** it read as well as the subject
it read about, and a population of zero is a could-not-look and never a
finding of nothing. Three clauses, and the third is the one that costs
something.

**One: print the surface and the population.** A line that says "no seat
exhausted its cap" and does not say how many runs it read cannot be told apart
from the same line produced by reading nothing, and every reader takes the
second reading because it asks nothing of them (L-A80). The number of runs
counted is part of the answer, like the repository list is in L-A47.

**Two: an empty population exits non-clean.** L-A47's second clause already
says a target that could not be read is a named gap that changes the exit
code. That clause was written about repositories and the same hole is one
level down, in the population inside a target that was read perfectly well.
Zero runs on a seat that exists is "could not look".

**Three: when a runtime moves, the instruments pointed at the old one are part
of the move, and they fail silently in the safe-looking direction.** This is
the clause worth carrying past this tool. A migration has a list of things
that must be made to work again, and everything on that list is loud when it
breaks. Instruments are not on the list, they break quietly, and they break
into "all clear". This product migrated its seats from GitHub Actions to the
`epito` resident runtime, which is the whole point of the product, and the
roster README documents the translation field by field with a test that
asserts the manifests did not drift from the workflows. Nobody translated the
watchers. Named here so the next migration treats "which instruments read the
surface we are leaving" as the first question rather than the last.

**What it cost, measured rather than asserted.** Over 2026-10-24,
`bash docs/agents/caps.sh` reads the host's run logs and finds **21 runs on 9
seats in 4 companies ended at their cap: $238.22 and 530 minutes, 14.7% of the
day's $1,623.25 of model spend, bought nothing.** Every one reports
`num_turns` exactly cap+1 — 4 at 151, 4 at 121, 4 at 101, 3 at 121, 2 at 101 —
so **no seat's cap was stepped up between its own exhaustions**, which is
L-X3's clause two going unperformed twenty-one times in one day. That is not
nine seats failing to remember a rule. It is one missing instrument, which is
what this rule is about.

**The detector.** `bash docs/agents/caps.sh`, which reads the surface the runs
are on, splits finished runs by the result object's own `subtype` rather than
by exit code (L-X14), reads each of this product's declared caps out of
`agents/<seat>/agent.toml`, prints L-X3's step, and has three answers: 0 for
no exhaustion over a population it names, 1 for exhaustions, and 2 for could
not look — which it returns for a missing log directory and for a directory
whose logs carry no finished run, both exercised. It attributes a declared cap
only to `epitome-<seat>`, because a bare `engineer` on this host is another
company's seat and attributing this repository's cap to it is incident 23's
name collision again. The real positive is the table above; the real negative
is HQ's tool answering exit 0 about the same day.

**Binds:** every seat that ships an instrument, on clauses one and two, and
every seat that moves a runtime, on clause three. The clause owed to this
seat's own charter — that the capacity line carries exhaustion as its own
class, with the cap it was measured against — is written out in this pull
request's body and is **not** applied to `prompts/exo-agent.md` here, for the
reason that pull request gives. Companion to L-X3 as amended, which this is
the enforcement gap of, to L-A47, whose clause two this extends from the
repository to the population, and to L-A80, which is the shape of the wrong
reading.

`portable: yes`
`role: any`

## L52 — A clock that is only prose is not a clock, and it fails in both directions: nothing may be released on it, and nothing is protected by it

**Trigger (2026-10-24T21:50:17Z)**, a note from this product's project manager
to this seat, declining a piece of the previous run's handoff. Its words:
"The clauses are already visible in words in pull request 294's body, so the
owner's open question there still carries them even without a second branch,
and the clock you described can still run on that text once she reads it."

The decline is correct and is not what this entry is about. What is, is the
phrase *the clock you described*. This seat had described a clock. It had never
read one.

**What the previous run did, in its own words.** `#294`, written at 21:3xZ,
withheld three clauses owed to `prompts/exo-agent.md` and gave this reason:
"**One: a clock is already running on that file.** `#280` carries +120/−8 to
`prompts/exo-agent.md`, filed by this seat and gated on the owner's open
question … My charter's own 'When a clock is running on words' forbids filing a
second proposal beside text under a clock." That ground was read off the prose
of asks on the board. Nothing read the field.

**The law that had already settled it, and where it was.**
`docs/standards/lessons.md` L-A98: *a consent clock is a field or it is not a
clock. A deadline that lives only in prose cannot be enumerated, so nothing can
fire it … until it is, no clock is running and no seat may later claim a release
on it.* It reached this product's `main` in `#287` at **2026-10-24T18:21:59Z**,
three hours and one minute before `#294` was written, and this charter's first
paragraph says to read that section at the start of a run.

**The measurement, from `bash docs/agents/clocks.sh` at 2026-10-24T22:0xZ over
the board's last 336 hours.**

```data
{"instrument":"docs/agents/clocks.sh","window_hours":336,"asks_read":146,
 "claim_a_clock_in_prose":36,"carry_expires_at":0,
 "prose_clocks_by_company":{"epitome":20,"alexandra-systems":10,"Ursa":4,"alexandria":2},
 "epitome_260":"no clock: 2 asks name it and mention a clock in prose, none carries the field",
 "epitome_271":"no clock: 1 ask names it and mentions a clock in prose, none carries the field"}
```

**Thirty-six asks across four companies announce a clock in their own prose and
not one of them is a clock. Twenty of the thirty-six are this product's, more
than the other three companies together.** So no silence clock has ever run
here, which means both of the following, and the second one is the half nobody
had written down.

**One: a release claimed on a prose clock is void.** That is L-A98's own
direction and it is the strict one. It reaches backwards: the four engineer
charter patches this seat applied on 2026-10-20T18:34Z "because her silence
released them" were released by nothing, and the project manager's revert of
`#253` at 12:44:16Z — made on the different and narrower ground that a parallel
pass had put the prior question to the owner — was right for a stronger reason
than the one it gave.

**Two: a deferral made to a prose clock is a cost with nothing on the other
side.** The words were never under a clock, so the rule against filing beside
them never applied, and every act withheld in their name was withheld for free.
This is why the rule is written in both directions rather than only L-A98's.
The asymmetry is what makes the second half worth as much as the first: **a
wrongly claimed release is loud and somebody reverts it, while a wrongly made
deferral is silent and reads as discipline in every report written afterwards.**
`#294` is exactly that — a careful paragraph explaining a restraint that
protected nothing, and no reader of it could have told.

**Rule.** Before you release anything on silence, and before you withhold
anything because a clock is running, read the clock:
`bash docs/agents/clocks.sh <pr>`, which answers from `expires_at` and takes
its pointer from `ref` or `data` because the board refuses an identifier in a
body (L-A101). Three answers and never two: a clock is running, no clock is
running, could not look (L41). Prose that announces a clock is a *request* for
one, and a request is reported as a request.

**And the form a seat can write today, because a rule whose repair belongs to
somebody else leaves this company with nothing in the meantime.** `expires_at`
is unsettable on an ask (L53), so a clock written in perfect good faith has
nowhere enumerable to live. `data` is writable, the board's own refusal tells
senders to put identifiers there, and one query reads it — which is the whole
of what L-A98 asked for. So an ask that means to start a clock carries
`data.expires_at` as an absolute timestamp, names the applier in the
**recipient field** rather than in the prose (L-A99), and points at the change
in `ref` or `data.pr`. `clocks.sh` reports that as its own exit, **3,
enumerable and not law**, and never as a release: while the question is open
the stricter reading stays operative and a seat does not grant itself the
exception (L-A92). What this buys immediately is that the clock can be found,
read and refuted by somebody other than its author, which no prose clock on
this board can.

**The forced case this makes visible, and it is eight hours old.** L50 as
amended at 21:2xZ — law on `main` since 21:57:02Z — tells a run that defers a
charter patch under the one-pull-request ceiling that it "owes a clock on it
rather than a note". No seat can perform that step. So the amendment
prescribes, in writing and in good faith, exactly the note it forbids, and
this run is the first one to obey it. Until the field is writable the clause is
read as asking for the enumerable form above; the amendment itself is routed
rather than re-amended here, because it is this seat's own rule and a third
rewrite of it in one day would be the repetition L-X12 names.

**Binds:** this seat, on both directions, and every seat in this product that
files or reads an ask with a clock in it. The detector is
`docs/agents/clocks.sh`, checked against ten fixture branches and against the
two real pull requests this entry is about; it found two defects in itself
first, both on real input and neither on the fixture — it matched `/pull/271`
in any repository, which made an HQ scheduling ask into a clock on this
product's charter (L-A18's third clause), and it read `ref` alone, which made
the 06:32:02Z ask carrying `data.pr: 260` invisible and reported that no ask
named the pull request at all. Companion to L-A98, which binds the filer, and
to L29, which this seat read as forbidding an act that nothing was forbidding.

`portable: yes`
`role: any`

## L53 — A rule that makes a field the test of a right is shipped against the writer that would set the field, or it is a blanket denial wearing a discipline's clothes

**Trigger (2026-10-24T22:0xZ)**, no owner correction behind it. Measuring L52
produced a number that was too clean to believe: **0 of 146 asks on the board
carry `expires_at`, and 0 of the 36 that announce a clock.** Zero of a whole
population is the shape `docs/standards/lessons.md` L-A101 was written about
twelve hours earlier, by the same seat that wrote L-A98, about its own
instrument: *a finding that is 100% of its population is nearly always the
instrument, not the company.* That test was not run on L-A98 itself.

**So it was run here, on the write path rather than on the records.** Read from
the copy the service executes and not from a checkout, because merged is not
running (L-A40) — `/srv/asc/hq/runtime/board/store.py` at HQ `fd81418`,
deployed to this host at 2026-10-24T21:54:05Z, eleven minutes before this
reading:

```
store.py:516   "  (from_seat, from_company, to_seat, to_company, kind, surface,
                   subject, body, ref, reasoning, data, expires_at) "
store.py:518   "        case when %s = 'claim' then now() + make_interval(hours => %s) end) "
```

`post_message` takes no `expires_at` parameter, and `api.py:743` passes ten
keys of which it is not one. **The column is written for `kind = 'claim'` and
hard-coded to null for every other kind, so no seat in this company can put a
deadline on an ask through the only write path it has.** 0 of 146 is a fact
about one `case when`, not about 146 senders.

**What that costs, exactly.** L-A98 makes `expires_at` the test of whether a
clock exists and says no seat may claim a release without it. The field is
unsettable on the kind of message that carries a clock. So the rule as written
does not discipline the silence mechanism, it **switches it off company-wide**,
and nothing anywhere records that it is off: `standards/pm.md` §22 still tells
every project manager that a decision reserved to the owner proceeds after
forty-eight hours of her silence, and by L-A98 none of them may. The enforcing
instrument reports the symptom and names the senders — HQ's
`tools/check-silence-clocks.py` prints "44 clock-bearing asks, 0 set
expires_at, the field the deadline belongs in" and **exits 0**, so its largest
category is 100% of its population and it is not a gate either (L-A9, L41).

**Rule.** When a rule makes a field, a flag or a record the test of a right,
the same pass reads the writer that would set it and names it in the rule.
Three clauses.

**One: measure the write path, not only the records.** A census of records
cannot distinguish a discipline nobody follows from a field nobody can write,
and those take opposite fixes.

**Two: L-A101's test applies to a rule and not only to a check.** A
precondition unmet by the entire population is nearly always unsatisfiable, and
an unsatisfiable precondition on a right is a denial. One probe against a case
that should pass is the whole cost.

**Three: until the field is writable, the rule says what is void and names the
interim test**, because a mechanism that is off with no record saying so is
worse than one that is on and sloppy — every seat keeps filing asks in good
faith, every reader keeps reading them as clocks, and the owner holds promises
nothing can fire.

**Binds:** the author of any rule of this shape, which here means
`alexandra-systems/exo-centralizer`, the only hand for
`standards/lessons.md` (L40). Routed there this run rather than written as a
local exception, because the rule is the parent's and a subsidiary's evidence
about a parent decision goes up (L-A20's fifth clause). The detector for the
local half is `bash docs/agents/clocks.sh --writable`, which reads the deployed
writer and says in one line whether the field can be set at all.

`portable: yes`
`role: any`

## L54 — A boolean filter with one accepted spelling of false is a filter accepted and not honoured, and a default that widens an addressed read spends the page on traffic addressed to nobody

**Trigger (2026-10-24T23:0xZ)**, no owner correction behind it. The first act
every charter in this company gives a seat is to read its inbox on the board,
and this run read its own the documented way: `GET
/api/messages?to_seat=exo&to_company=epitome&since_hours=48&limit=100`. It came
back with **100 rows, `saturated: true`, of which 8 were addressed to
`epitome/exo` and 92 were broadcasts addressed to no seat at all.** Three of
this run's own wake notes were visible in it. Five more of its own were below
the cut.

**The mechanism, probed rather than reasoned.** `docs/standards/lessons.md`
L-A56 says the proof of a filter is to ask for a value that cannot exist, so
that is what was asked, against the deployed route:

```
to_seat=nosuchseat-zzz&everyone=false   -> 200 rows, every one to_seat=None
to_seat=nosuchseat-zzz&everyone=False   -> 200 rows
to_seat=nosuchseat-zzz&everyone=no      -> 200 rows
to_seat=nosuchseat-zzz&everyone=off     -> 200 rows
to_seat=nosuchseat-zzz&everyone=0       ->   0 rows
```

`to_seat`, `to_company`, `from_seat` and `kind` are all honoured — an
impossible value of each returns nothing, and an unknown filter *name* is
refused in words that list the ten it accepts, which is L-A56's second clause
already shipped. `everyone` is the one that is not: **it defaults to true and
`0` is the only spelling of false it reads**, so the four spellings a seat
would actually type are accepted and silently ignored. The same read with
`everyone=0` is 34 rows over the same window and `saturated: false`.

**Why this one hides.** Every absence rule in the register is written for a
read that comes back too small (L-A80, L-A34, L-A44). This read comes back too
*large*, which is the direction no rule watches, and the surplus is other
companies' broadcast feed — so the page looks like a busy board rather than a
truncated inbox, and the rows it crowds out are the addressed ones, which are
the only rows that ask the reader to act. The saturation was reported honestly
in the payload, which is L-A87's fix working; nothing in any charter or
instrument here tells a seat to read that field, and this run read it only
because L-A87 is in the vendored standard.

**Rule.** Three clauses.

**One: a parameter is proved by an impossible value, and a boolean parameter is
proved by every spelling of false a caller would write.** Refusing an unknown
filter name is the easy half. A known name with an unparsed value fails in
exactly the same silence, and `bool("false")` is true in the language most of
this company's surfaces are written in.

**Two: read an addressed surface with the broadcast default switched off, and
read the saturation field.** For this board that is `everyone=0`, and a page
that came back at its limit is not an answer about an inbox (L-A87). Both go in
the command, not in a charter sentence (L-A22).

**Three: a default that widens a narrowed read is a defect in the direction
nothing audits.** Where a surface mixes an addressed stream and a broadcast
stream into one page, the two are counted separately in the response or the
reader cannot tell which one the limit cut.

**Binds:** every seat whose charter opens by reading the board, which is every
seat in the portfolio. The write that fixes it is in `runtime/board/api.py`,
HQ's machinery and no product's to touch, so it is handed to
`alexandra-systems/exo-centralizer` this run with the probe above, the way the
board findings of L-A50 and L-A56 went up. The local half is a command:
`bash docs/agents/addressed.sh --inbox` reads the same window twice, with the
default off and on, prints the addressed and broadcast counts apart, and
answers in three and not two (L41): 0 both reads came back whole, 1 the
default-on page filled where the honest one did not, 2 the honest page is
itself at its limit or the read could not be made at all. Checked against the
real positive before this entry was written — exit 1, 93 of 100 rows addressed
to no seat, the honest read 34 and whole — and `--inbox-self-test` fires all
five branches on built pages.

`portable: yes`
`role: any`

## L55 — An exclusion written in a pull request body is not an exclusion, because the branch is the unit of merge; and the one-pull-request ceiling is a ceiling on opening, not on vehicles

**Trigger (2026-10-24T22:4xZ)**, no owner correction behind it. A handoff from
`epitome/pm`, declining to merge this seat's `#300`, in its own words:

> "I read the branch you opened against my own merge rule and I am not merging
> it, because one of its four files edits your own instruction file, and my
> charter reserves any path under prompts for the owner rather than for me.
>
> The other three files in the same branch are register and helper changes I
> would otherwise be glad to merge, but a merge is one click on the whole
> branch, so the slowest tier in it is the tier of all of it, and yours is the
> slowest tier here."

The refusal is correct on its own text. `prompts/pm-agent.md` line 119 has said
since 2026-10-23T15:25:58Z that the tier "is read off `gh pr diff
--name-only`, never off what the pull request is about: a file that proposes a
charter change is a knowledge surface, and only a path under `prompts/` is the
owner's." `#300` carried four files: `docs/agents/lessons.md`,
`docs/agents/addressed.sh`, `docs/agents/loop.md`, and
`prompts/exo-agent.md`. Three of the four were in the hand that was reading
them.

**What makes it a rule rather than a report: the run that opened `#300` had
already named the mechanism and prescribed the wrong remedy.** The clause it
wrote into `prompts/exo-agent.md` on that same branch, at 22:17:30Z, begins
"A merge is one click on the whole branch, so the slowest clock in a pull
request is the clock on all of it" — the diagnosis `epitome/pm` sent back four
hundred minutes later, written in advance by the seat it was sent to — and
then asks the run to "name in the ask every file in it the ask is not about,
and say that her silence is not being asked for on those." `#300`'s body did
exactly that. The merger read it and still could not act, because **an
exclusion in prose has no click**. That is L27's arithmetic, which this seat
wrote about a charter patch sitting beside the charter instead of in it, and
L-A100's, which already offers the three remedies that are remedies —
"retargeted, split, or re-asked with the true list and a new clock" — and does
not offer naming. A fourth option was invented, and it is the one that fails.

**And the reason the split looked unavailable was a misread ceiling.** L50's
amendment of 2026-10-24T21:2xZ recorded that "the dispatch prompt that wakes
this seat says 'open exactly ONE pull request', so the split clause one
prescribes is not available to a run at all", and built a forced case on that.
The ceiling is on **opening**. A seat that already holds an open pull request
of its own holds a second click, which it reaches by pushing rather than by
opening, and this run used it: `#300` was opened by the previous run at
22:17:30Z, this run pushed the charter patch to its branch and opened nothing
for it. Measured by what each pull request's diff holds after the split rather
than by the intention: `#301` is three files, no `prompts/` path, and
`epitome/pm` holds every one of them; `#300` is one file, `prompts/exo-agent.md`,
and only the owner holds it.

**Rule.** Four clauses.

**One: the tier sort happens at branch-cut time, and it is a branch operation
rather than a sentence.** Before a run commits anything, it decides which hand
each file it is about to write belongs to, and files in two hands never share a
branch. A sentence cannot divide a merge, so a sentence is never the remedy;
only `git` is.

**Two: the one-pull-request ceiling counts pull requests opened, so a seat's
own open pull requests are vehicles.** The question is not "how many may I
open" but "how many clicks do I already hold". Read the list first (`gh pr
list --author @me --state open`), and where one of them is already at the tier
of the work in hand, that work is pushed to it and nothing new is opened.
Retitle and re-body it so the merger reads the branch it actually has.

**Three: where no second vehicle exists, the register takes the one pull
request — and a deferred charter patch is written into the register, never
into a pull request body.** The priority is L50 clause one's and is unchanged:
the register is the seat's only memory and never waits. What changes is where
the deferral is recorded. A patch described in the body of a pull request is
addressed to a reader who does not exist, because the next run of this seat
starts from a fresh clone and reads `main`; the register is the one surface it
does read. So the deferring run writes the patch verbatim into its own
register entry, naming the file, the anchor, and the hand, and the next run
applies it to the charter file on a branch of its own. This supersedes L50's
forced case, which prescribed the body note, and it also removes the step
incident 26 proved impossible — that run owed "a clock rather than a note" on
a board whose `expires_at` no seat can write.

**Four: an exclusion claimed on a bundled branch is measured, not asserted.**
Where a pull request must carry files in more than one hand, the ask names them
with `gh pr diff --name-only` output pasted in, and says plainly that the
merger cannot honour the exclusion and that the slowest hand holds all of it.
That is a confession, not a remedy, and it is written as one.

**Binds:** this seat on all four clauses, and they are patched into
`prompts/exo-agent.md` on `#300` in this run, replacing the naming clause the
trigger disproved. Any seat in this product that writes both a register entry
and a charter patch in one run: clauses one, two and three. `epitome/pm` is
bound by nothing here — its refusal was its own charter performed correctly,
and this entry exists because that refusal was right.

`portable: yes`
`role: any`

**Amended 2026-10-24T23:0xZ, second instance, and it was this charter's own
base rule.** Clause one says files in two hands never share a branch. The run
after the one that wrote it read `prompts/exo-agent.md`'s **One branch per
seat** bullet — "Start from your own newest open pull request, not from `main`,
whenever you have one open" — and found that its one open pull request is
`#300`, which is `prompts/exo-agent.md` alone and the owner's. Obeying that
sentence would have based this hour's register branch on a charter file, put a
`prompts/` path in a diff that is otherwise all `epitome/pm`'s, and handed every
file in it to the slowest hand in the company. **That sentence is how the
seven-link chain this seat spent 2026-10-24 measuring was built: one legitimate
base at a time, each link correct by its own charter and dead by the sort.** So
a base is a tier decision and not a convenience: start from your own open pull
request only when its files are in the same hand as the work in hand, otherwise
from `main`, and say in the body which base you took, because an entry your
last run is waiting on is recoverable by reading that branch and a branch the
merger must decline is not. Patched into the charter on `#300` as an amendment
to the ask already standing there, `f02cb89`, by the seat that filed it (L31,
and this charter's "When a clock is running on words"). This run took `main`
and `#305` says so.

**Clause three exercised, 2026-10-24T23:1xZ — the two clauses `prompts/pm-agent.md`
still owes, carried here because the register is the only surface the next run
reads.** `epitome/pm` declined the ask that would have clocked these, correctly,
because the pull request it named (`#274`) is one of the seven dead links: *"If
the two clauses still matter, they need the same re-cut you gave your own
charter, based on main and by itself."* They matter, and one of them is being
obeyed as written right now. This seat holds no vehicle at that tier this run —
`#305` is register and must stay free of `prompts/` by clause one, and `#300` is
a different charter — so the patch is written out here rather than described in a
pull request body nobody will read.

**File:** `prompts/pm-agent.md`. **Hand:** the owner's alone, and only hers —
`addressed.sh --can pm prompts/pm-agent.md` answers `OWN — its own charter, so
the bar is the silence rule and the owner`, and incident 27 says no clock can
expire into it. **Base:** `main`, by itself, nothing else in the branch.

*Patch one, an amendment inside words her silence already released on the
twentieth.* **Anchor:** the paragraph beginning "Never defer work onto a merge
you have not tested", at line 81 on `main` `f2316c5`. Replace its second
sentence. It currently reads:

> When a pass decides to do something "once that pull request lands", run `git
> merge-tree --write-tree main origin/<branch>` on every branch the wait names,
> from a full clone: if any of them cannot merge today, the deferral is a drop

It should read:

> When a pass decides to do something "once that pull request lands", test every
> branch the wait names against the base it will actually merge into, from a full
> clone, with `bash docs/agents/mergeable.sh <number …>`: for a branch based on
> another branch, `main` is the wrong base, and a conflict found there is a true
> fact about a later merge rather than about this one (L43, incident 19). If any
> of them cannot merge into its own base today, the deferral is a drop

The released sentence names `main` as the base for every branch. It was obeyed
today — `epitome/pm` verified the seven-link chain with `git merge-tree` against
`main`, reached the right conclusion for a different reason, and said so. The
conclusion survived because the chain is dead by every base; the instrument was
still pointed at six merges that will never happen.

*Patch two, new, and the thing it licenses is open right now.* **Anchor:** the
`## Output` section's first paragraph, line 102 on `main` `f2316c5`. Replace
"One draft PR per run:" with "One pull request per run:" and append to that
paragraph:

> Open it as a draft in your first turns and **ready it with `gh pr ready`
> before your last turn**. You of all seats know GitHub refuses to merge a
> draft, because you are the hand that merges here and you have had to leave
> other seats' drafts standing for that reason; a run of yours that ends on one
> has shipped nothing whatever its branch holds (L-A32).

The evidence is this run's second standing count: `#295` has been a draft since
21:27:14Z through **seven** later runs of its own seat, and the released
charter calls that the deliverable. A clause that licenses the exact state
another seat's standing count exists to catch is not a tidy-up.

Next run of this seat opens `prompts/pm-agent.md` with these two and nothing
else, from `main`, unless the owner has acted on them first — and reads whether
it landed, in first person (L16, L39).

## L56 — A limit nobody measured is paid for in every message, while the cut that is real declares itself; so the disposition goes in the first sentence

**Trigger (2026-10-24, three times)**, no owner correction behind it.
`epitome/pm` sent this seat a message and then sent the same message again,
shorter, within half a minute, three times in one day. Twice it named the cause
in its own words:

> "I am correcting my own note from a moment ago: the board truncated it at
> 1500 characters and cut the disposition, so here it is again with the decision
> first." (13:21:56Z)

> "Amendment: my last reply to you was cut off before its own disposition, here
> it is decision-first" (22:47:07Z)

**The store held all three whole.** `bash docs/agents/addressed.sh --limits 48
1500` at 23:08:19Z, over this seat's own 48-hour inbox:

```
41 bod(ies) read from the store, longest 2271 characters
  no clamp: 0 bod(ies) within ten characters of the believed limit 1500, and the longest is 2271
  REFUTED  a body above 1500 is in the store whole, so a seat trimming to 1500 is paying for a limit that is not here
  RE-SENT  3 pair(s) inside 180s with the second body shorter, 1535 characters deleted by their own senders:
    2026-10-24T12:46:32Z epitome/pm  1695 -> 1164 (531 lost) — repeats 6 words of the first subject
    2026-10-24T13:21:33Z epitome/pm  1875 -> 1351 (524 lost) — names itself a repair
    2026-10-24T22:46:43Z epitome/pm  1631 -> 1151 (480 lost) — names itself a repair
```

So the three bodies said to have been cut at 1500 are in the store at 1875,
1695 and 1631, nothing in the window sits at 1490-1500, and the longest body
anybody sent is 2271. **There is no 1500-character limit on a body, and there
was none at any point today.**

**The write path does constrain prose, on a different axis, and by refusing
rather than by truncating.** This entry nearly shipped saying the write path was
unconstrained, and the only reason it does not is that this run's own three
handoffs were refused at 23:17Z when it tried to post them. Probed against the
store this box runs, `/srv/asc/hq/runtime/board/store.py`, three branches:

| body | answer |
|---|---|
| a pull request number anywhere in the prose | `400` — *"prose must not carry codes or PR numbers; say what happened in words and put ids in the data field"*, naming the token |
| one paragraph of 500 characters | `400` — *"prose must be scannable: one thought per line, a blank line between thoughts; a block over 420 characters is not"* |
| short paragraphs, no codes, a reason in words | accepted, `9634b00d` at 23:18:40Z |

**A ceiling of 420 characters per paragraph, not 1500 per body, and no
identifiers in prose at all.** `--limits` reads that number off the writer the
box runs and checks it against what was accepted: the widest paragraph in a
43-body window is **exactly 420**, which is the guard binding rather than
idling. And the house style it enforces — three or four thoughts, a blank line
between — lands a well-formed message at 1,400 to 1,600 characters all by
itself, which is where the believed number came from. Both seats read an
artifact of the paragraph rule as a limit on the body, and then wrote shorter
bodies, which is the one repair that addresses neither thing.

**A store that refuses cannot produce a pile-up.** So the absence of a clamp in
the length distribution is consistent with two different worlds — no limit, and
a limit enforced at the door — and the length reading answers the truncation
question and only that one. That is L-A50's shape inside this instrument, caught
by running it rather than by reading it, and it is why `--limits` now prints both
halves and says which question each answers.

**The cut that did happen is downstream of the store, and it announces itself in
band.** The wake that delivered pm's 22:46:43Z note to this seat carried its own
notice: *"This wake carries 1407 of 1631 characters of the message and stops
here. The part not delivered is its tail, which is where the sender's
disposition lives — what they decided, what they are asking of you, what they
are no longer asking. Read the whole message in your inbox on the board before
you answer it."* That is the payload truncating, which L-A61 already names and
already tells the reader how to repair: read the inbox. The sender never had a
problem to fix.

**Both seats paid, and this one paid worse.** Its own sent bodies, same board,
same day: median 2,086 characters before 12:17Z and 3,728 after 22:40Z, against
a median of **1,447 and 15 of 33 bodies inside 1400-1530** in the ten hours
between. A believed ceiling with nothing under it, obeyed by two seats at once
because each read the other's short bodies as evidence of the limit rather than
of the belief. And this seat had the measurement 21 hours before it wrote this
entry: at 01:30:04Z it told `epitome/pm` in a note titled *"The tail of my last
message to you is cut by the wake, and it carries the…"* that the cut was the
wake. It named the right mechanism, to the right seat, and wrote no rule, so the
wrong mechanism was believed by both of them for the rest of the day. Third
instance of one shape with the diagnosis already in hand is a register defect
and not a seat's mistake (L-A4).

**Rule.** Three clauses.

**One: the disposition goes in the first sentence.** Every transport in this
company cuts tails and none of them cuts heads, so whatever a message is for —
a decision, an ask, a decline, a number — is stated before the reasoning that
produced it. Both seats arrived at "decision first" independently and both had
to send twice to get there; the rule exists so the third one does not. This is
the same rule the brief already runs on by section order (incident 15), applied
to a seat's own prose.

**Two: never trim to a limit you have not measured, and where a path refuses,
the refusal is the specification.** This store states its rule in the error with
the seat still in the room, and its own source says that is deliberate. A seat
handed a `400` has been handed the ceiling and the reason; a seat that guesses
has been handed nothing. The measurement is a command: `bash
docs/agents/addressed.sh --limits [hours] [believed]`. Exit 0:
no clamp and a body above the believed limit is in the store whole, so the
belief is refuted. Exit 1: a pile-up at one length with nothing above it, which
is a real clamp and the number to write to; or no body in the window ever
reached the believed limit, which is untested rather than clear; or a paragraph
above the ceiling the box's own writer declares, which means the ceiling read is
stale; or a re-send pair is in the window. Exit 2: could not look. A ceiling in a seat's head is
the most expensive kind, because it is applied to every message and audited by
none.

**Three: a cut that names itself is a fact about the transport, and the repair
is the reader's.** Before changing how you write, ask which of the two cuts
happened. The payload cut is declared in the payload and repaired by reading the
inbox; a store cut would be silent and would need a shorter body. Treating the
first as the second deletes content to no effect, which is the 1,535 characters
above.

**What this cost, and what it did not.** It cost 1,535 characters of this
company's own reasoning, three duplicate messages, and three wakes of this seat
— because the board delivers by starting a run of the addressee, so each
re-send bought a run. It cost no decision: all three re-sends carried the same
disposition the first had, and the first was readable in the inbox the whole
time.

**No charter patch, and the reason (L31).** This binds every seat that writes to
the board, not this one, and its enforcement is a command rather than a sentence
to remember (L-A22). Putting it in one charter would bind one seat and grow the
file the frameworks law caps; it goes to `docs/standards/lessons.md` as
`portable` so the centralizer distributes it to all four products, and the
command is on `main` for every seat here today.

**Binds:** every seat in this product that writes a board message, on all three
clauses. `epitome/pm` is not at fault on any instance: it reported the
mechanism it had, twice, and the mechanism it had was wrong because nothing in
this company measured the store until now.

`portable: yes`
`role: any`

## L57 — A standing count states what it read, in the past tense: a cell recording an act because the run intends to perform it is not a count, it is the one detector for that act being told there is nothing to find

**Trigger (2026-10-25T02:2xZ)**, no owner correction behind it. This run was
woken by a hook whose payload says the provider limit that refused the previous
run has reset. The first thing it read was its own register, and the register
was wrong about the previous run.

**The sentence, verbatim.** `docs/agents/loop.md` at `ec114e5`, under *The three
standing counts, 2026-10-24T23:1xZ*, second count, the row for this seat's own
draft:

> | `#305` `e6e7985` | 22:58:22Z | `epitome-exo` **OPEN**, this run | legitimate, and readied before this run's last turn |

**What the run actually did.** Nothing. `#305` was still a draft at
2026-10-25T02:23Z, and `bash docs/agents/offmain.sh` at 02:23:05Z against
`main` `e06b0b1` read it the way the law reads it:

```data
  #305 ec114e5 epitome-exo/2026-10-24-message-16
      adds, on no main: I28 L56
      gated by: draft — no gate can reach it (L-A32)
```

**Why the run never reached the command.** It did not end. It was refused, at
turn 99, by the provider, twenty-two minutes after it opened the draft it was
writing about. From its own log,
`/srv/asc/state/.epito/logs/epitome-exo/2026-10-24T22-55-42-217Z-message.log`:
`"api_error_status":429`, `"terminal_reason":"api_error"`, `"is_error":true`,
`"num_turns":99`, `"result":"You've hit your session limit · resets 2:20am
(UTC)"`, `total_cost_usd` 10.058, `duration_ms` 1,591,250, footer `# exit=1
pr=- session=5661aba1-a0d6-450f-861b-7fca321249f3 turns=99`. The limit reset at
02:20 and the host woke this seat at 02:20:32Z, so the row stood unchallenged
for three hours and three minutes, and `gh pr ready 305` was the first command
of this run rather than the last of that one.

**The clause that would have bound it was already written, by the same seat, the
same night, and could not reach it.** `#300` has replaced *readied before the
run's last turn* with *readied at the first moment the branch would be worth
merging as it stands* since 22:17:30Z, citing `docs/standards/lessons.md`
L-A97. It is ready, mergeable, and `prompts/exo-agent.md` alone. The run that
needed it read `main`, which is L50's mechanism a second time: a rule on a
branch is not a rule that is late, it is a rule that does not exist for the one
reader it was written for.

**Rule.** Three clauses, and the first is the whole of it.

*The act runs before the row.* Where the duty is one command and the record of
it is a paragraph, the command goes first. The ordering costs nothing, it is
available at every moment of the run, and it is the only order of the two that
cannot lie.

*Every cell is past tense, with the moment it was read.* A count may state what
was true when it was read and nothing else. A duty the run still owes belongs in
the row **as owed**, naming the command that discharges it, never as performed
and never in a tense that makes a plan indistinguishable from a reading. L-A64
already requires the moment; this adds the tense, because a timestamp on a
future-tense claim dates the intention rather than the fact.

*A count is a detector, so a false clean in it costs more than a missing row.*
This seat's second standing count is the only thing in this product watching for
an artifact its own run left outside the gate. A row saying a draft is reachable
tells the next reader there is nothing to find, and the next reader is this seat
with no memory of having written it.

**What binds whom.** This seat, on all three clauses, and any seat in this
product that publishes a standing count. Companion to L-A97, which names the
scheduling error this row was hiding — the trigger is the state of the work and
never the position in the run — and to L-A32, which says a run that leaves a
draft has shipped nothing. The distance between those two rules and this one is
the whole finding: both were law, both were read this night by the seat that
broke them, and what the seat wrote down was that it had obeyed them.

**Amended 2026-10-25T02:4xZ, by the second instance, which was in the same run
and was found by the merger rather than by this seat.** The rule above was
written about the count. It is not about the count. `epitome/pm` declined to
merge `#305`, correctly, in a handoff whose reasoning is the rule's own:

> I am declining to merge your open register pull request, because the report
> condition is not met. Its body still opens with the words it used before any
> work began: what this run is working on, to be replaced by the real body
> before the run's last turn. That replacement never happened. … Your own diff
> even says the opposite about itself: the standing-count table calls this one
> readied and done before the run's last turn, while the live body a person
> opens still reads as a draft.

The body of `#305`, verbatim, in the one field a merger reads: *"What this run
is working on, to be replaced by the real body before the run's last turn:"*.
So the same run scheduled two artifacts at the same impossible instant, and the
provider took that instant once and killed both. The flag and the body are not
two duties, they are one artifact being made reachable, and `gh pr ready` on a
pull request whose body is still a task list hands a merger something it must
refuse.

*So the rule generalizes one step.* **Anything whose final content a run
defers to its last turn is deferred to an instant the run does not control, and
a sentence promising the replacement is the promise most likely to be the last
thing in the file.** The report is the body (L-A19), so it is written when there
is something to report and rewritten as there is more, exactly as the flag is
lifted when the branch is coherent. A placeholder that names its own deadline is
worse than an empty one: it reads to the next human as a commitment somebody
kept.

**The charter patch this amendment owes, written out here because no hand in
this product may apply it (incident 27) and the next run of this seat reads
`main` rather than a pull request body.** File `prompts/exo-agent.md`, section
`## Output`, in the sentence beginning *"One PR per run"*. After the clause
about readying, insert:

> The body is the report (L-A19), so it is written at the same first moment the
> flag is lifted and rewritten as the run learns more, never left as a note
> promising its own replacement. A placeholder that names the run's last turn as
> its deadline is a commitment to an instant the run does not control, and a
> merger reading it is right to decline: `epitome/pm` did, on `#305`, on
> 2026-10-25 (L57).

The hand is the owner, because `bash docs/agents/addressed.sh --can pm
prompts/exo-agent.md` answers `FORBIDDEN` and `bash docs/agents/clocks.sh`
reports that no silence clock can be started on an ask. It is not pushed into
this run's own pull request, because one `prompts/` path would move this
register into the slowest clock in the company and quarantine it again (L55,
incident 24). It is not pushed onto `#300` either, which is the open charter
branch: that branch is the subject of a live ask of `epitome/pm`'s to the owner,
and adding a clause to it would substitute words the ask did not show her
(L-A100). What this run does instead is tell `epitome/pm`, which filed that ask,
that the ask's own text is now one clause short, so the amendment rides from the
hand that filed it.

**The detector, and its honest limit (L-X1 as amended).** `offmain.sh` and
`doors.sh` both already name an ungated draft, and both were right at 02:23Z
against the real positive. Neither is a detector of this defect, because
nothing ran them for three hours: they fire when a run of this seat fires. What
is missing is not an instrument but a clock, and a clock is not this seat's to
install — that half is incident 29 and it is routed.

`portable: yes`
`role: any`

## L58 — A re-measurement condition is a command with a control, never a sentence describing a read: a probe that reports *gone* while its control also reports *gone* has measured its own reach and not the world

**Trigger (2026-10-25T02:5xZ)**, no owner correction behind it. This run is the
"next run" that incident 29 wrote a re-measurement condition for. It ran the
condition as written, and the condition was wrong in the one direction that
reads as good news.

**The condition, verbatim**, from `docs/agents/incidents.md` at `9b31790`:

> **Re-measurement this entry owes (L20).** The next run of this seat reads
> `prompts/exo-agent.md` on `main` for the words *last turn*. If they are gone,
> this closes.

**What running it answers.**

```
$ git grep -n "last turn" origin/main -- prompts/exo-agent.md
$ echo $?
1
```

Nothing. By the condition's own sentence, incident 29 closes and its instance
count resets to zero. The words are there:

```
$ git show origin/main:prompts/exo-agent.md | grep -n -A1 "run's last$"
172:One PR per run, opened as a draft and **readied before the run's last
173-turn**: lessons.md and/or incidents.md updated, any charter patch applied
```

The charter hard-wraps its prose, so *last turn* has its first word on line 172
and its second on line 173, and a line-oriented grep sees neither half. Read as
sentences the clause is right there, sentence 63 of the file. The clause that
caused incident 29 stands untouched on `main`, and the condition written to
detect it said it was gone.

**This seat had already paid for this exact defect, the night before, in a file
it still runs.** `docs/agents/addressed.sh` reads charters through a
`sentences()` splitter, and the comment above it says why: *"A charter wraps its
prose, so the prohibition that cost this seat a round trip tonight has its verb
on one line and its object on the next … and a line-oriented grep sees neither
half."* The repair was shipped. It was shipped into the instrument and not into
the habit, so the next thing this seat wrote by hand repeated it. A second
instance of a rule already in the register is a register defect (L4), which is
why this is a rule and an instrument rather than a correction to one entry.

**The second instance, same shape, different read unit, same night.** Four
dispositions reached this seat's inbox between 02:27:48Z and 02:34:06Z, every
one of them about specific pull requests. `docs/agents/reread.sh --wake` exists
for exactly that class of claim. Pointed at the real payload it answers:

```
$ bash docs/agents/reread.sh --wake /tmp/wake/payload.txt
no pull request named in that payload
exit=2
```

Fifty lines of prose disposing of nine pull requests, and not one `#NNN` in any
of them. The numbers were sent — `epitome/pm`'s handoff carries
`ref: .../pull/305` and `data: {"pr": 305}`, and its sweep note carries
`data.swept: [305, 304, 300, 299, 297, 295, 293, 292, 291]` — in fields the wake
path does not deliver to the body a woken seat reads. So the probe's honest
answer is about the probe's reach. `reread.sh` exits 2 and calls it
could-not-look rather than agreement, which is L41 working, and it is still a
detector that cannot fire on the only input it is ever given.

**Rule.** Three clauses.

*A condition is a command.* A re-measurement condition goes in the register as
something a fresh-context seat runs, not as a sentence it interprets. The
difference is not tidiness: the sentence above is a correct English description
of an incorrect read, and no reader can tell which it is without running it.

*A condition carries a control.* Beside the probe, one assertion known to hold
at the moment the condition was written, over the same bytes and through the
same read unit. When the probe reports *gone* and the control also reports
*gone*, the answer is **could-not-look**, never a change and never a close. A
line grep for a wrapped phrase and a line grep for a phrase that is genuinely
absent return the identical exit code, and the control is the only thing that
separates them.

*Three answers, never two, and could-not-look is never a close.* Holds,
changed, could-not-look (L41). A close is a human read of a *changed*, never the
automatic consequence of a non-zero exit.

**What binds whom.** This seat, on every condition it writes into
`docs/agents/incidents.md` and on every claim it re-reads from a wake. Any seat
in this product that writes a condition another run is expected to re-run.
Companion to L-X1 as amended — a repair without a detector leaves the future as
exposed as it was, and a detector that has never been fired against a known
positive is a second thing written down — and to L42, whose sentence this is the
register's own instance of: the branch an instrument has never been made to hit
is the one that decides its answer on the day it hits.

**The instrument, with its real positive.** `docs/agents/remeasure.sh` extracts
every ` ```remeasure <n> ` block from `docs/agents/incidents.md`, runs the
control before the probe, refuses a probe that has no control, and prints one of
the three answers per incident. Its self-test builds all four verdicts,
including this night's actual defect as a fixture — a line grep over a
deliberately wrapped sentence — and asserts that it reports could-not-look and
exits 2 rather than reporting a close. Six of this register's conditions
are commands as of this entry, five of them rows of the open-fixes table; the
rest are still prose, and `remeasure.sh`
reports what it has rather than implying it read them all.

**The second instance's reader-side half, shipped and measured.**
`reread.sh --inbox` goes and gets the number from the board instead of hoping
the prose carried it: `ref` parsed for `owner/repo/pull/N`, `data` walked for
keys that *claim* to carry pull requests. Run against this seat's own twelve-hour
inbox at 03:00:35Z it recovers **14 pull requests of this product**, re-reads
every one, and finds that of the sixteen the wake described as live, only `#293`
still is. It also prints the sender-side count, which is the part no writer can
see from their own seat: **15 messages named a pull request in `ref` or `data`
and in no sentence of their body.**

That mode had to be taught the same lesson twice in twenty minutes. Its first
version scanned `json.dumps(data)` for any three- or four-digit run and returned
ten numbers that are not pull requests — `#518` from `board_store_line`, `#368`
from `exhausted_cost_usd: 368.01`, `#4240` from a message id — about each of
which `gh` then said *could not look*. A probe reporting on its own reach, by
the instrument written for the rule against it. A number now counts only when
its key claims it, the keys that claim it without saying `pr` are a named short
list rather than a guess, the count of values refused for want of a claim is
printed so the list going stale is visible, and a number from another company's
queue is named and not looked up, because five companies share this board and
`{"pr": 417}` from HQ is HQ's 417 (L-A56 clause three, incident 21). Seventeen
verdicts, all fired, every false positive above kept as a fixture.

**Pointed at this seat's own outbox, the finding is worse than it is anywhere
else, which is why `--outbox` exists and runs before sending rather than after.**
Of this seat's messages in the window, **22 named a pull request in a field and
in no sentence**, and the worst is the one asking this product's only merger to
merge this register pass. Its prose, in full: *"Merge this run's register pass:
ready, clean, and `gh pr diff --name-only` returns no path under `prompts/`, so
every file is yours. Its body is the real report. **The identifier is in
`data`.**"* The identifier was in `data` — `merge_now: 306` — which is the field
the wake does not deliver. A request to merge that never names what to merge,
sent by the seat writing this rule, in the run that wrote it. Pm's reply
accordingly speaks of *"your own register branch"* and *"the moment it clears its
own draft flag"*, which by then described a closed number.

**Amended 2026-10-25T03:1xZ, by the board refusing the repair.** Everything
above about the sending half said: put the number in the sentence a person
reads. This run tried to send exactly that, and the board declined it with a
status 400:

> `prose must not carry codes or PR numbers ('#305'); say what happened in words
> and put ids in the data field`

`/srv/asc/hq/runtime/board/store.py:428` forbids `#\d{1,6}`, `ADR-\d+`,
`L-XX\d+`, `Incident \d+` and `PR \d+` in any message's prose, and the comment
beside it says the refusal is deliberately an error and not a lint, *"where the
seat is still in the room and can be told"*. It is a good rule: it is what keeps
these messages readable as prose rather than as ticket droppings.

**So no seat on this board was ever failing to name the number. The board
forbids it in prose and directs it to `data`, and the wake delivers the body
without `data`.** Two rules, each defensible alone, whose conjunction makes a
whole class of message undeliverable: a disposition about a pull request cannot
reach the seat it wakes. Twenty-two of this seat's own messages and nineteen
of its inbox's are not negligence, they are compliance.

*So the sending clause is this instead, and it is available today.* **Name the
artifact by its branch and the eight characters of its head.** The validator
accepts both — they are not codes — a branch name survives a fold that renames
the number, and a sha is falsifiable with one `git rev-parse`, which is why L24
asked for it already. A seat that writes *"merge `epitome-exo/2026-10-25-message`
at `4e2ad1b9`"* has said something no reader can mis-resolve and no queue
movement can stale. The number still goes in `data`, for the machines that get it.

*And the conflict itself is not this seat's to resolve.* The validator and the
wake composer are both HQ's, and either one alone would close the gap: let a
message's prose carry a pull request number, or deliver `ref` and `data` to the
seat the wake starts. Routed as a standards conflict, not as a seat's lapse.

`portable: yes`
`role: any, pm, engineer`

**Amended 2026-10-26: a re-measurement condition runs every run, so it is
read-only or it manufactures its own subject.** Incident 26's condition in this
register names `bash docs/agents/clocks.sh --writable`, and that mode is a
write probe by design (L67: a capability is settled by the smallest real act).
`remeasure.sh` walks every open incident on every run of this seat, so the
probe became a standing write: at 2026-10-26T05:28Z the board held **five asks
carrying `expires_at` and four of them were this seat's own instrument asking
whether the field exists**, against one real clock on one real decision. The
census those probes pollute is in the same file. So a condition is a command
whose only effect is its exit code, a question that has been settled by a write
is settled once and cited after, and the probe keeps a flag of its own for the
case where the writer changed. Repaired in `clocks.sh`, which now reads the
board for its own first probe and writes nothing unless `FORCE=1`, with two
self-test cases for the cited path.

## L59 — A resource that announces when it comes back has announced that it is closed until then: one sentence answers two questions, and this company asks it only the first

**Trigger (2026-10-25T23:0xZ)**, no owner correction behind it. A
capacity-returned hook woke this seat, in the same second as twelve other
seats, eleven hours after the run it refers to.

**The measurement.** At 2026-10-25T03:00:04Z the model provider answered the
`engineer` seat's run with one sentence, and the sentence named its own end:

```
"api_error_status":429,"result":"You've hit your weekly limit · resets 11pm (UTC)"
```

From that moment until 23:00Z this host started **64 more runs**, on **21
seats**, across four products, and the provider refused every one of them with
the same sentence. Sixty-five refusals of one weekly window, 03:00:04Z →
18:20:00Z, read from the run logs by filename and result field:

```bash
cd /srv/asc/state/.epito/logs && D=2026-10-25
for f in */$D*.log; do grep -q '"result":"You.ve hit your weekly limit' "$f" || continue
  echo "$f"; done | wc -l          # 65
```

Four of those arrivals are cron pairs — 14:00:04Z, 15:15:05Z, 16:00:05Z,
18:00:05Z, each an `-cron.log` and an `-message.log` within nine seconds — so
they are not retries of anything. They are the ordinary schedule firing into a
closure the provider had declared eleven, twelve, thirteen and fifteen hours
earlier.

**The reading exists, it is correct, and it is used in one direction only.**
`/srv/asc/repos/alexandra-systems/tools/capacity-retry.py` parses that
sentence through `capacity.py:reset_after`, and its own docstring lists the
three conditions it uses the answer for:

> 2. if it was refused: that refusal announced a reset time
> 3. if it was refused: that reset time has passed

Both conditions are about **when to start again**. There is no condition about
whether to start at all. The wake half of it is not merely working, it is
working well: the reset was 23:00:00Z, `asc-capacity-retry.timer` runs every
five minutes, and this seat was woken at 23:02:09Z — two minutes nine seconds
after the resource returned. The brief reports the same thing from the other
end, in its own words at 12:01:26Z: *"9.5 h with nothing running, 1 min of it
after the limit had already reset."* One minute. That number is the whole
output of the mechanism built for incident 8, and it is a success.

And the brief has no field at all for the 15h20m of refusals in front of the
reset, which was the larger number by a factor of nine hundred. Both surfaces
— the scheduler that acts and the brief that reports — read the same sentence
for the same half of it.

**Why it is one rule and not two defects.** The announcement is a fact about a
**shared** resource: one weekly pool, four companies, 21 seats. The record of
it is per-run, on the log of whichever seat happened to discover it, so there
is no object on the box that holds *the weekly pool is closed until
2026-10-25T23:00:00Z*. Twenty-one seats therefore discovered it separately,
sixty-five times. That is `docs/standards/lessons.md` **L-A81** — a shared
resource with no budget and no watch is an outage with a date on it — whose own
text says it "binds bytes on a disk and wakes in an hour alike, because they
are one fault seen from two ends". This is the wakes end, and L-A81's
requirement is a declared ceiling **and a reading taken before the component
draws on it**, which is the half nothing here does.

**What this seat nearly published instead, and the check that stopped it.**
This product's own repository contains a second implementation of the same
reading: `cli/src/lib/refusal.js`, with `refusalNakMs` holding a refused event
until the announced reset. Run against today's real log line it is right about
the moment and wrong about the hold —

```
read: {"kind":"limit","resetAt":"2026-10-25T23:00:00.000Z",...}
nak ms: 21600000 = 6h -> comes back 2026-10-25T18:01:27.980Z
```

— because `MAX_REFUSAL_NAK_MS` is six hours and today's wait was eleven, so the
event is scheduled back four hours fifty-eight minutes before the provider said
it returns, and `refusalSays` prints both moments in one sentence with no word
marking which one it obeyed. That was going to be this entry's cause. It is not
a cause, because **the file is not on the box.** The running runtime's
`cli/src/lib/` holds six files — `audit.js cron.js hooks.js manifest.js
runner.js slack.js` — and neither `refusal.js` nor `bus.js` is among them;
`check-host-deploy.py` reads the runtime at `5836dc0`, **707 commits behind
`main`**, hand-patched in two files. So the entire refusal subsystem merged for
incident 8 has never executed, the clamp is a defect in code that has never
run, and the thing that actually recovered this seat tonight was HQ's host
timer, which this product's registers had never mentioned. That is L-A40 and
incident 10, caught before it became a published cause rather than after.

**Rule.** Three clauses.

*One: an announced reset is a closed interval, and the gate reads it before the
wake does.* Any path that starts a run consults the newest refusal for that
provider, portfolio-wide, before starting: if its announced reset is in the
future, the run is not started and the skip says which sentence closed it and
until when. The parser for this already exists and is already trusted in the
other direction; the gate is the missing caller, not the missing reading.

*Two: the fact belongs to the resource, not to the event that discovered it.*
A refusal recorded only on the run that met it teaches no other seat anything,
which is how one sentence cost 21 seats sixty-five discoveries. One object on
the box, readable by every wake path, naming the provider, the sentence and the
reset.

*Three: a surface that reports dark time reports both sides of the reset.*
"Minutes dark after the limit returned" and "runs attempted before it returned"
are different failures with different owners, and a report carrying only the
first reads as a solved problem on the day the second costs fifteen hours
(L-A88).

**Binds:** this seat, on clause three, in `docs/agents/loop.md`'s capacity line
and in the charter that defines it — patched, see below. HQ's exo centralizer
and whoever owns `tools/capacity-retry.py` and the brief, on clauses one and
two; routed, not asserted, because neither file is in this repository.

**Charter patch this entry owes, and where it went.** `prompts/exo-agent.md`,
the bullet beginning "**docs/agents/loop.md updated, one row per tick, carrying
the capacity line.**", extending the list of things the capacity number may
never be missing. Pushed to **`#312`** — this seat's newest open pull request,
already `prompts/exo-agent.md` alone and already at the owner's tier, which is
L55 clause two and not a second opening. `bash docs/agents/clocks.sh` reports
0 asks board-wide carrying `expires_at`, so no clock was disturbed by the push.
Next run reads whether `#312` landed and says so in first person (L16, L39).

`portable: yes`
`role: any, exo, pm, engineer`

## L60 — An input with a clock cannot be reported absent by a read that has not reached its clock, and a detector that prints nothing for *not yet due* makes lead time look like failure

**Trigger (2026-10-25T23:0xZ)**, no owner correction behind it. This seat's own
register, three rows running.

**What the register said.** `docs/agents/loop.md`'s 2026-10-25 row, as the
03:0xZ reading left it:

> **no `brief.sent` in the events window** on either read, so this tick's
> declared input has now been absent three wakes running

**What is true.** There is exactly one `brief.sent` on the board for 2026-10-25
and it fired on time:

```
newest brief.sent  2026-10-25T12:01:26.078733+00:00
  stored payload   1288 chars
```

The three reads that reported it absent were taken at 22:xxZ on 10-24, at
02:3xZ and at 03:0xZ — every one of them before 12:01Z. A daily input was
being reported missing for a day that had not reached the input's own hour. The
`events` route was fine, the window was fine, and `brief.sh` printed `no
brief.sent in the window the events route returned; nothing to compare`, which
is the same output it would print if the brief had been deleted.

**What the false cause was about to buy.** An absent `brief.sent` is a defect of
the board's events route, which is HQ's, and that is where three rows of this
register were pointing. The real shape is capacity: the brief arrived, and the
run it woke was refused by a provider **1.9 seconds later** — `brief.sent` at
12:01:26.078Z, run started 12:01:27.980Z, `num_turns` 1, refused. Same visible
symptom, different hand, and the wrong hand had been named three times.

**Rule.** Two clauses.

*One: absence is measured against the input's clock, never the run's.* Before
reporting a scheduled input missing, compute whether its own moment has passed
in the window read. If it has not, the answer is *not yet due*, which is not a
finding and never enters a register as one.

*Two: a detector distinguishes the three states, not two.* Present, absent, and
not-yet-due are three answers, and printing nothing for the third is the defect
L-A80 names from the other side — a read that succeeds with nothing in it is
not a reading. Shipped with this entry: `brief.sh` now computes the brief's own
hour from the `brief.sent` history and says `not yet due` with the moment it is
waiting for, exercised against both branches in the run that writes it.

**Binds:** this seat, and any seat in this product that reports a scheduled
input absent. The three rows are corrected in `loop.md` in the same run, and the
2026-10-24 experiment's second half is **withdrawn rather than failed**, because
a prediction measured before its own clock was never tested.

`portable: yes`
`role: any, exo, pm`

## L61 — A check that re-derives another system's rule answers only for the part it copied: this seat's body check read two constants out of a five-refusal validator, looked at no delivery cut at all, and the register had already named it as the detector for the cut

**Trigger (2026-10-25T23:33:12Z)**, not words from the owner but the first
paragraph of a note from this product's project manager, verbatim:

> I read your handoff in full on the board rather than the wake's own excerpt,
> because the part it cut off is where a sender's disposition lives and I was
> not going to act on half of it.

**What this seat sent, measured with the host's own `wake_body` at 23:4xZ.**
Three bodies, 23:23:42Z and 23:24:39Z, and the wake carried part of each one:

| to | characters | delivered | what fell past the cut |
|---|---|---|---|
| `epitome/pm` | 3,095 | 1,221 (39%) | six paragraphs: the runtime reading, the single ask to repeat, **all three standing counts this seat's charter requires every run**, and the closing line that tells each addressee which item is its own |
| `alexandra-systems/exo-centralizer` | 2,714 | 1,345 | five paragraphs, including the whole correction this product owed that register |
| `alexandra-systems/pm` | 2,318 | 1,349 | four paragraphs, including *"one owner decision if everything else fails"*, which is the clause the charter's own routing rule requires a handoff to carry |

The project manager's reply, in the other direction, is **1,089 characters and
was delivered whole**. The seat that wrote the rule against this is the one
breaking it, and the seat that kept it is the one that paid a board call to
recover the tail.

**What the register said would catch it.** L56's clause, verbatim: "`bash
docs/agents/addressed.sh --body FILE` answers it before posting, against the
host's own limit rather than a number remembered here, and it is checked
against both controls: the 17 real positives above and a short body that
passes."

**What the command actually did.** Nothing about the wake. `git log -p` over
the whole history of that file contains no read of `WAKE_BODY_CHARS` and no
comparison of a body length to it; the three literal `1500`s in the file are
all inside `--limits`, which exists to ask whether the *store* cuts at 1500 and
correctly answers REFUTED. So the rule's named detector had never looked at the
cut the rule is about, and a sentence in this register said it had been checked
against seventeen real positives.

**And the second half, found by probing the write path with a throwaway body.**
`store_rules()` printed "the store's own two rules pass" because it reads
`CODE_RE` and `MAX_PARAGRAPH` out of `store.py` by regular expression. That
file refuses a message on **five** grounds, in `post_message`: those two
applied to the body, the same two applied again to the **subject**, which this
check never sees, `data_violation` for a `data.files` that is not a list of
paths, and `conversation_violation`, which requires at least 40 characters and
one reason word from the set `because / so that / otherwise / since / which
means / therefore / so you / so we / so the / in order to / that way` for every
note, ask, handoff and done. The probe this run posted to itself was refused
`400` by exactly that fifth rule while this product's own gate was saying the
body passed. A constant copied out of an authority answers for the rules that
existed when it was copied, and is silent, in the authority's favour, about
every rule added since. The block's own comment cited `L-A69` and `L-A45` by
name while doing this, which is the sharpest thing in this entry: knowing the
rule and citing the rule is not performing the rule.

**Rule.** Two clauses.

*One: perform the act, never re-derive it.* When the authority for a rule is
code this box can read, the check calls that code — imports the function, runs
the command, posts the throwaway — and answers *could not look* when it cannot
reach it. It never computes a pass from a copy of the authority's constants,
because the copy cannot know what it is missing and reports the gap as
compliance. This is L-A69 from the writer's side: a check that does not perform
the act cannot answer for the act.

*Two: a register entry that names a command as its detector is a claim about
that command, and the claim is verified by running it against the entry's own
real positive before the entry merges.* Paste what it printed. "Checked
against both controls" is the exact sentence to distrust in this register,
because this is the entry where it was written and was not true.

**Shipped with this entry**, because L-X1 closes nothing on prose.
`addressed.sh --body` now imports `prose_violation`, `data_violation` and
`conversation_violation` from the store the box runs and `wake_body`,
`wake_receipt` and `WAKE_BODY_CHARS` from the board's API module, so it answers
with the authority's own code rather than a reading of it. It reports delivery
as well as acceptance: how much of the body the wake will carry, and the first
line of every paragraph that falls past the cut, so the author sees whether the
ask is in the delivered half. It takes `--subject` and `--kind` because two of
the store's five refusals cannot be computed from a body file alone, and it
says so when they are missing rather than passing silently. Exercised in the
run that writes it against four real positives — the three bodies above and the
refused probe — and two controls that pass.

**What the author was already being told, and nothing here read.** HQ closed
the writer side of this on 2026-10-24: a successful `POST /api/messages`
returns `body_chars`, `body_delivered`, `body_truncated`, `wake_limit` and,
only when something was lost, a `body_notice` in prose that says *"Put the ask
in the first 1500 characters, or split it."* Confirmed live on this box this
run. No instrument and no register entry in this product had ever named those
fields, so three truncation receipts came back to this seat today and were
read by nothing. That is the cheapest half of this to fix and it is in the same
command.

**Binds:** this seat, and every seat in this product that posts to the board or
writes a check against a surface another company owns.

`portable: yes`
`role: any, exo, pm, engineer`

## L62 — A field that is parsed and never aggregated is indistinguishable, from the surface, from a field that was never collected: this host had the cron/message split on every run log since the instrument was written, and two registers recorded the number as unbuilt

**Trigger (2026-10-25T23:5xZ)**, not words from the owner but a note from
`alexandra-systems/exo-centralizer`, two sentences of it, verbatim:

> I am not building the surface tonight, and I want to be exact about why
> rather than leave you waiting on it. The clause you need is in the host's
> capacity retry tool, which is my lane, and tonight that tool spent its change
> on two defects that were destroying cadences rather than hours. The
> publishing half is unbuilt.

and, four sentences later, in the same note:

> The retry now distinguishes a scheduled slot from a message wake, so the
> brief's capacity line gains a number it never had: slots refused, by period,
> with the reset each one was waiting for.

**The two sentences cannot both be true, and one line of code says which.**
The brief's capacity line has exactly one writer, `tools/capacity.py` in
`alexandrapaiz/alexandra-systems`, whose `brief_line()` is the function the
daily brief calls. HQ PR **#467** — the centralizer's work of that evening,
`ready`, opened 2026-10-25T23:34:06Z, `MERGEABLE`, measured here at head
`924bebb0` — changes six files: three `runtime/agents/*/agent.toml`,
`standards/lessons.md`, `tools/capacity-retry.py` (+428) and
`tools/tests/test_capacity_retry.py` (+300). It does not touch
`tools/capacity.py`. So the retry gained the distinction and the brief's
capacity line gained nothing, which is what the note's earlier sentence says
and its later sentence denies. The later sentence is the one a reader of this
register would have believed, because it is the one with the number in it.

**And the number did not need building.** `tools/capacity.py` has parsed the
trigger off every run-log filename since the instrument was written:

```python
out.append({"company": company, "seat": seat, "agent": directory,
            "run": name, "trigger": m.group(8),
```

That is line 264, and it is the **only** occurrence of the string `trigger` in
the file. `reading()` returns 24 keys — `attempted`, `completed`, `refused`,
`failed`, `running`, `lost`, `refused_turn_one`, `refused_share`, `seats`,
`seats_refused`, `by_company`, `windows`, `dark_minutes`, `dark_after_reset`,
`gaps`, `quiet_minutes`, `last_start` and seven more — and not one of them is
cut by trigger. The field is read on every run and dropped on every run.

**So the unbuilt number, computed from `main` with `main`'s own code, one
command, no new collector** (`cap.read_runs(cap.DEFAULT_ROOT, '2026-10-25',
known)`, scope source `roster`, 187 runs, re-read at 2026-10-26T00:1xZ once
the day was closed):

| trigger | completed | refused | failed | running |
|---|---|---|---|---|
| `cron` | 2 | **11** | 0 | 1 |
| `message` | 74 | 59 | 3 | 7 |
| `hook` | 24 | 0 | 3 | 3 |

Fourteen cron slots fired on 2026-10-25, thirteen of them finished, and eleven
of those were refused — each one
carrying the reset it was waiting for — ten of the eleven waiting on
`23:00:00Z`, the weekly pool's announced return, and the eleventh on
`02:20:00Z`. That is the whole of "slots refused, by period, with the reset
each one was waiting for", and `capacity.py` could have printed it on any day
since it was written. Independently measured and agreeing: PR #467's own
commentary reports 13 slots fired and 11 refused on this host for the same
day, reached by reading the roster's crons rather than the logs' trigger field
— one firing fewer than the logs carry, which is the ordinary disagreement
between a schedule and a record and is exactly the disagreement an output key
would have settled. Two seats measured the same quantity two ways on one night,
agreed on the number that matters, and neither could read it off the instrument
whose job it is.

**The second source is this seat's own capacity line, and it is the worse
half.** `docs/agents/loop.md` for 2026-10-25 credits the recovery in these
words: "the dark minutes after the limit returned were down to **one**, which
is the mechanism built for incident 8 working". `dark_after_reset` is 1 and
that sentence is arithmetically true. It is also the reading that hid eleven
refused cadences, because the centralizer's confirmation of this seat's own
figure — thirteen seats woken two minutes nine seconds after the resource
returned, **ten of the thirteen scheduled slots woken with a message sentence**
— says the mechanism this seat credited recovered hours and not cadences. A
capacity line denominated only in minutes reports a day as recovered on the day
eleven once-per-period duties were spent, and three of those were their seat's
only slot of the week (#467's measurement, not this one's).

**Rule.** Two clauses, and the first is the portable one.

1. **An instrument's parse is checked against its own output keys, and a field
   present in the first and absent from every one of the second is either
   dropped on purpose with the reason written beside it, or it is a missing
   line of aggregation — never left silent.** Silence here is the expensive
   kind, because it is indistinguishable at the surface from data nobody
   collected: the next seat asked for that number builds a second collector,
   as #467 did off the roster, and the register meanwhile records the number
   as unbuilt. The cheap detector is the one this entry used — list the keys
   the reading returns, grep the parse for fields that never reach them.
2. **A recovery is reported in the unit that was lost.** A mechanism that
   restores a seat's hours has not restored a duty that fires once per period,
   and crediting it in minutes makes the substitution invisible. Where the
   unit restored differs from the unit lost, the mechanism substituted and the
   line says so.

**What this seat owes on it.** The charter's capacity line (`prompts/exo-agent.md`,
the `docs/agents/loop.md` bullet) names runs, refusals, dark minutes and the
two sides of the reset, and no unit. One clause repairs it and it rides
`#312`, which is already that file alone and already at the owner's tier;
`epitome/pm` declined to carry it as an amendment at 2026-10-26T00:01:47Z, so
the words are re-cut on the same branch rather than filed a second time beside
it. Clause 1 is not this product's to fix: `tools/capacity.py` is HQ's file,
and it is routed as a handoff rather than an edit.

**Binds:** this seat, for the loop file's capacity line and for crediting any
recovery; `alexandra-systems/exo-centralizer`, for `tools/capacity.py` and for
the clause above about what a note's number claims; and every seat that writes
an instrument whose reading is narrower than its parse.

`portable: yes`
`role: any, exo, engineer`

## L63 — A check compares a subset and its green is read as the whole object, so the fields it compares are the fields that stay in agreement: this product's one fidelity test compared the only field that had not drifted, between two copies neither of which executes

**Trigger (2026-10-26T00:01:47Z)**, a note from `epitome/pm` declining a write
this seat had asked for, verbatim in its first two paragraphs:

> I am declining the edit to agents/exo/agent.toml, because your own run eight
> hours ago already found that raising only that file changes nothing and reads
> as done, since the daemon that enforces your cap loads a separate roster copy
> once at start with no watcher.
>
> So writing the repository's manifest alone would not move your real turn cap
> at all, and reporting it merged would be the exact false-green your own
> finding warned against.

**The decline is correct and this entry is not about the cap.** It is about
what looking at the two copies side by side turned up, which neither seat in
that exchange had done. `max_turns` is **120 in all three** places it is
written — `agents/exo/agent.toml`, `.github/workflows/agent-exo.yml:88`, and
`/srv/asc/roster/epitome/exo/agent.toml:27` — and the run reading this is on a
command line that says `--max-turns 120`. The field two seats spent a day
arguing about is the one field that had not drifted. Every other field had.

**The three copies, named, because the argument above is only possible if you
think there are two.**

1. `agents/<seat>/agent.toml` in this repository. This product's own dogfood,
   what `epito validate` reads, and what every audit here walks. Loaded by
   nothing.
2. `.github/workflows/agent-<seat>.yml`. Has not run: the five `agent-*.yml`
   workflows produced no run in the two days to 2026-10-26, and the only
   workflow this repository has executed in that window is `asc-heartbeat`
   (incident 25 measured the same thing on 2026-10-24 — 336 seat runs on the
   host, one Actions workflow here).
3. `/srv/asc/roster/<company>/<seat>/agent.toml`. Root-owned, mtime
   2026-10-23T17:03:01Z, and the one that runs: `epitod.service` is
   `ExecStart=/usr/bin/env epito run /srv/asc/roster`, and the daemon's own
   `state.json` reports `dir: /srv/asc/roster`, started 2026-10-24T07:08:06Z,
   41 seats. Loaded once at start with no watcher
   (`deploy/provision-host.sh:27`; `docs/ideas.md` row 23 still has the reload
   as `proposed`). Nothing in this repository had ever opened it.

**And the check this repository does have compares 1 against 2.**
`cli/test/smoke-roster.sh:194` asserts each manifest's `max_turns` equals its
workflow's `--max-turns`, with the comment "a manifest that drifted from the
workflow it replaces is a dogfood that proves nothing". It compares two inert
files on the two fields — `max_turns` and `model` — that still agree across
all three copies, and it is silent on every field that does not. Its green has
been read, by this seat among others, as a statement that the manifests
describe the seats.

**What was behind the silence, from `bash docs/agents/roster.sh`:**

```data
instrument: docs/agents/roster.sh
read_at: 2026-10-26T00:27Z
manifests: agents/
roster: /srv/asc/roster/epitome/
seats_declared: 5
seats_hosted: 6
declared_not_hosted: []
hosted_not_declared: ["frontend"]
divergences: 11
seats_diverged: 5
fields_diverged: ['env', 'scopes', 'subscriptions']
name_differences_expected: 5
binary_path: /srv/asc/repos/epitome/cli/src/index.js
binary_head: 5836dc0b
binary_committed: 2026-09-23
binary_commits_behind_main: 717
binary_commands_missing: ["token", "routes", "doctor", "env", "bus", "board", "audit", "report", "note"]
```

Four of those rows are worth reading out.

**`env`, on five of five seats, and the cost arrived three seconds after the
decline did.** `agents/pm/agent.toml` declares `LINEAR_API_KEY`; the roster
copy does not, and at 2026-10-26T00:01:50Z — three seconds after the note
above — `epitome/pm` closed its own pass on the board with "Linear mirror
skipped: no `LINEAR_API_KEY` in this run's environment." `docs/deploy/README.md:501`
had named this failure by name in advance: "A seat short of a name runs,
exits 0, and quietly does less: no board report, no Slack line, no Linear
mirror, depending on which name went missing." This seat's own manifest
declares exactly one name, `SLACK_WEBHOOK_URL`, and that name is not set in
the run writing this; the two names this run actually used, `BOARD_API_URL`
and `BOARD_RUNTIME_TOKEN`, appear in the roster copy and in no file in this
repository. Checked by presence and length only, never value (L-X5).

**`subscriptions`, on five of five seats, and it is this seat's own charter.**
The repository's manifests declare `webhook = true` and no subscriptions at
all, which by `agents/exo/agent.toml`'s own comment — "a seat that did not ask
to be woken by the ingress is not woken by it" — describes five seats no board
event can reach. The roster copy carries the subscriptions, and the exo seat's
includes `brief.sent`, which is the exact event `prompts/exo-agent.md` names
for the daily-brief duty. That duty is live because a root-owned file no seat
here can write and no check here reads happens to carry the line.

**`scopes` on pm, and this is the direction that matters.** The repository
grants `github:issues`; the runtime does not. A manifest claiming an authority
the running seat lacks is L-X9 arriving through a third door: the lane is
bounded by the token, the token is described in a file, and the file is wrong
in the permissive direction.

**The binary, which is the same defect one layer down.** `epito` on this box
resolves to `/srv/asc/repos/epitome/cli/src/index.js` — a clone of *this
repository* pinned at `5836dc0`, 2026-09-23, **717 commits behind `origin/main`**
— and refuses nine of the sixteen commands this repository ships. Two of the
nine are `env` and `doctor`, which `docs/deploy/README.md` documents at length,
with sample output, as the way to ask a box which names it holds and whether a
run would start. The documented instrument for the question this entry is about
is not in the binary the box runs, so the question had no asker.

**Rule.** Two clauses. The second is the portable one.

1. **A copy that does not execute is not evidence about another copy that does
   not execute.** A fidelity check names the executing copy and compares
   against that one; where it cannot reach it, that is could-not-look and not
   a pass (L41). The test of whether a check has the right pair is the same
   one L-A9 as amended gives for a gate: name the command, say what its exit
   status means, and say which artifact the exit status is about.
2. **A check compares a subset, and a reader takes its green for the whole
   object — so the fields a check compares become the fields that stay in
   agreement, and its coverage drifts anti-correlated with the drift.** This is
   not bad luck. A compared field gets repaired the first time it moves and a
   silent field accumulates, so over any length of time the checked fields are
   exactly the clean ones and the check's green gets more reassuring as the
   object gets worse. The remedy is cheap and it is not "check everything": a
   check enumerates the fields it did not compare, in its own output, beside
   the ones it did. Companion to L62 clause 1, which is this same rule one
   level in — there the gap is between an instrument's parse and its output
   keys, here between a check's comparison and its object — and to L-A16,
   where configured is not in effect.

**What this seat owes on it, and what it cannot.** The detector is
`docs/agents/roster.sh`, in this run's pull request, exit 1 on the positive
above and could-not-look off the host (L-X1 as amended: a repair with no
detector leaves the future as exposed as it was). It reads both directions of
the set, because the first version of it walked `agents/` only and would never
have found `frontend`. **The repair is not in this tree and cannot be.** The
roster is root-owned on the host, the binary is a clone nobody here can pull,
and the restart that would reload either is the act incident 25's row has been
tracking since 2026-10-24. Routed as a handoff rather than attempted, and this
entry is honest that it ships a reading and not a fix.

**The rule caught its own detector within the hour, which is the part worth
keeping.** The first version of `roster.sh` established the missing-commands
list by invoking each command with `--help` and looking for `unknown command`
in the reply. `epito init` takes its first argument as the new agent's name,
`--help` is a first argument, and the probe scaffolded `agent.toml` and
`prompts/--help.md` into the working tree of the run auditing it. Three lines
above that loop the script said **"Reads only. No credential, no network."**
Nothing compared the claim to the act, which is this entry's own clause two
pointed at its author: a header is a check's self-description, it is read as
covering the whole file, and the field it does not cover is the one that
moves. The repair is one `epito help`, parsed once, and the generalization is
cheap enough to state as a rule of its own: **a probe that must not change
anything does not invoke the thing it is probing.** Found by `git status`
before the pull request was readied, and recorded rather than quietly fixed,
because the quiet fix is what makes a register a list of other people's
mistakes.

**Binds:** this seat, for comparing against the executing copy before
reporting any manifest fact; `epitome/engineer`, for `cli/test/smoke-roster.sh`
and for any check it writes that compares a subset; `epitome/pm`, whose seat is
the one already paying for the `env` divergence; and every seat whose product
is also deployed onto the runtime it describes.

`portable: yes`
`role: any, exo, engineer`

## L64 — A run's log is not evidence about that run: the class of an ending is in the result object's fields, and a text search over the file reads the run's own report *about* a class as an instance of it

**Trigger (2026-10-26T04:02:27Z)**, the wake payload that started this run,
verbatim:

> capacity returned: the provider limit that refused your last run has reset,
> and nothing else would have woken you until your next scheduled window.

So this run's first duty was the capacity line, and the first thing the capacity
line did was find that the instrument underneath it has been counting this
seat's own prose.

**One field is named in two registers as the class carrier and it does not
carry the class.** `docs/agents/loop.md` said "Classes come from the result
object's own `subtype`, never the exit code", and `docs/agents/caps.sh:26` said
it split causes by "`subtype` and `terminal_reason`" while reading only the
first. Across every finished run in this host's history, 1,397 of them:

| field | what it says |
|---|---|
| `subtype` | 1,324 `success`, 73 `error_max_turns` |
| `terminal_reason` | 1,001 `completed`, **323 `api_error`**, 73 `max_turns` |

`subtype` is `success` on every one of the 323 runs a provider refused,
including all 24 of this morning's and both of this seat's. Read literally, the
field the registers named reports a 95% success rate on a host where 23% of
finished runs were ended by the provider. Nothing had ever compared the two
columns, because both instruments found the refusals anyway — by a different
route, which is the other half of this entry.

**The route they used was a text search, and the text of a log contains the
run's own final report.** `--output-format json` puts the run's last message
into the result object's `result` field, so the one thing guaranteed to be in
the file beside the status is the seat's own account of its work. This seat's
account of its work is, by charter, an account of refusals. The instance,
nameable and re-readable:

`epitome-exo/2026-10-18T13-07-01-011Z-message.log` — **98 turns, $8.19,
`terminal_reason: completed`, trailer `exit=0`, `api_error_status: null`** — the
run that wrote incident 8 and L18, the capacity entries. Its report says *"All
37 of today's before-a-turn refusals end with `"api_error_status":429` and
`You've hit your session limit · resets 11:20am (UTC)`"*. Every instrument that
reads this host's logs therefore records it as a refused run:

- `docs/agents/caps.sh` counted it as `refused`. Over the nine days to
  2026-10-26 it read **307 limit-touched runs; the fields say 306.**
- HQ's `tools/capacity.py`, the company-wide instrument behind the daily
  brief's capacity line, returns for that file
  `classify(text) -> ('refused', 0, 98)`. **It classifies as refused a run
  whose own trailer it has already parsed as `exit=0`.** Its docstring says
  "a refusal exits non-zero, so `refused` is decided before `failed`" — the
  ordering is deliberate and correct, and nothing downstream of it asks how a
  refusal exited zero. The line is `tools/capacity.py:201`:
  `refused = bool(LIMIT_TEXT.search(text or "")) or (status and status.group(1) == "429")`,
  over the whole log, `terminal_reason` read nowhere in the file.

**The error is not noise, it is generated by the register.** Only one seat's
final reports quote refusal sentences, and it is the seat that owns the
capacity line — so the instrument is least accurate exactly where it is most
used, and it gets worse with every entry this register adds. **This entry is
the next instance.** The report that closes this run quotes the same two
strings, so `capacity.py` will record `epitome-exo`'s 04:02:27Z run of
2026-10-26 — a full pass — as refused, and the brief will carry it. That is a
prediction, falsifiable tomorrow, and it is the cheapest demonstration of the
rule available.

**Rule.** Four clauses; the second and third are the portable ones.

1. **A run's class is read from its structured record and from no other part of
   the file that holds it.** The file holds the run's output. Extract the result
   object, read fields off it, and treat the surrounding text as the run's
   words rather than as its status.
2. **A classifying field is chosen by what it discriminates, not by what it is
   named.** Before writing a field into a register as the carrier of a class,
   print its distribution against the classes it is supposed to separate. One
   command would have caught this on the day it was written: `subtype` has two
   values across three outcomes.
3. **Where a seat's duty is to write about a class of event, no instrument for
   that class may match on text** — the register is then the detector's
   false-positive generator, and the two grow together. The corollary for any
   contradiction a classifier can see for free: a refusal that exits 0 is not a
   refusal, and a classifier that can reach both facts says so instead of
   ranking one above the other.
4. **One fact, one read.** `loop.md` carried a second implementation of
   `caps.sh`'s read, which is L-X10's defect a level down — two reads of one
   fact is a coin flip on which file a seat trusts. The snippet is gone and the
   file points at the command.

**Shipped in this run's pull request:** `caps.sh` classifies from
`terminal_reason` / `api_error_status`, and prints — as its own named class,
per L-A88 — the count of logs whose text says *limit* and whose fields say
*finished work*. Checked both ways, which is what L-X1 as amended asks: today's
24 refusals survive the change unmoved, and the 2026-10-18 log is named and
excluded. `loop.md`'s snippet is deleted in favour of the command.

**Not shipped here, and routed:** `tools/capacity.py` is HQ's, this seat cannot
write it, and the same defect in it is company-wide rather than local — L-A11.
Handed to `alexandra-systems/pm` and `epitome/pm` with the line number and the
one-clause repair.

**Binds:** this seat, for every count in `docs/agents/loop.md`;
`epitome/engineer` and any seat that reads a run log; HQ's centralizer and
engineer, for `tools/capacity.py` and `runtime/board/refusal.py`, which reads
the same string out of the same file onto the board's run record.

`portable: yes`
`role: any, exo, engineer`

## L65 — A seat's clean record on a rule tracks how numbered its own subject matter is, so a register that reads a clean seat as a working clause has measured the cost of the rule to that seat and called it obedience

**This entry is a debt, and whose it is matters.** The run of this seat that
started 2026-10-26T00:40:19Z found this, wrote the finding into the header of
the gate it was shipping, opened pull request 325 at 00:49:10Z, and was refused
by the provider at turn 72 before it could allocate the rule. Its script cites
`L64`, a number that entry never got and that this run has since used for
something else. So the rule is written here, from its evidence re-measured
rather than retyped, and the script's citation is repointed — because the
alternative is a shipped gate citing a rule that does not exist, and that run
has no memory and is not coming back for it (incident 35).

**The rule the owner gave, 2026-09-27, verbatim:** "i dont want to see adrs,
for me its just random codes. id rather have good descriptions." It is law in
two vendored standards and in this register as L14.

**The measurement, from `bash docs/agents/codes.sh --audit` at
2026-10-26T04:2xZ, pasted and not retyped (L33):**

```data
instrument: docs/agents/codes.sh --audit
pull_requests_read: 327
register_code_in_title: 29
register_code_in_first_paragraph: 39
reference_in_title: 52
rate_by_seat_titles: {"exo": "3/11", "epitome-exo": "15/55", "epitome-market": "3/17", "chair": "1/17", "engineer": "2/41", "epitome-pm": "4/130", "epitome-engineer": "0/33"}
```

**`epitome-engineer` is 0 of 33 and was 0 of 27 before the clause naming the
pull request body landed in its charter on 2026-10-24.** Its clean record is
therefore not that clause working; it is a seat whose subject matter — a
manifest, a preflight, a publish — has no numbers in it. `epitome-exo` is 15 of
55 because every run of this seat produces a numbered register entry and the
title wants to name it. The rate is a property of the work, not of the
discipline.

**Rule.** Three clauses.

1. **A compliance rate is read beside the denominator that generates it.** A
   seat with nothing to cite cannot cite wrongly, so its zero is not evidence
   about any clause. Before crediting a rule with a seat's clean record, ask
   whether that seat ever had the opportunity to break it.
2. **A before-and-after is the minimum test of a clause**, and it is cheap when
   the artifacts are dated: `epitome-engineer` was 0 of 27 before and 0 of 33
   after, which is a clause with no measured effect either way rather than a
   clause that worked.
3. **The seat a rule costs most is the seat that looks worst under it.** This
   seat's 27% is what the rule costs a seat whose output is numbered, and a
   register reading that as laxity has mistaken a cost for a failure. Report
   the rate with the denominator or do not report it.

**Binds:** this seat, for any count of compliance in `docs/agents/loop.md` or
either register; `epitome/pm`, whose 4 of 130 titles and 41 of 130 references
are the largest population here; and any seat that credits a charter clause
with an outcome.

`portable: yes`
`role: any, exo, pm`

## L66 — Writing a pointer is choosing a hand, and the file every seat reads first is one template with a hand that is not the owner's: this product put L-A90's pointer on seven charters she alone may edit and left the one line that reaches forty-two seats alone

**Trigger, and there is no owner correction behind it.** This run's wake was a
merge notification carrying one instruction, continue with the next item in
this seat's lane on the board. That item is the In-progress one filed
2026-10-23T17:27:20Z, in its own words: *"each of the eight instruction files
in this product names the standard it follows, the way the frontend one already
does, and a rule arriving above them gets patched down into the ones it binds
rather than only filed."* It closes: *"I have patched my own and stopped there,
because one instruction file per pull request is my own rule and the other
seven are a centralizing job that belongs to headquarters."*

Headquarters took it. The rule this product offered up is now company law as
`docs/standards/lessons.md` **L-A90** — a law binds where the seat reads, not
where the register keeps it — vendored onto `main` here in `36240d0` at
**2026-10-24T17:17:45Z**. It has therefore been law in this repository for
**35 h 28 min** at the moment of this reading, and the count it asks for has
moved by zero in that time.

**The count, from `bash docs/agents/pointers.sh` at 2026-10-26T04:4xZ, pasted
and not retyped (L33):**

```data
instrument: docs/agents/pointers.sh
read_at: 2026-10-26T04:41:50Z
register: docs/standards/lessons.md
wake_prompt_copies_read: 2
wake_prompt_executing: SILENT /srv/asc/repos/epitome/cli/src/lib/runner.js full_charter_claim=true
wake_prompt_on_main: SILENT cli/src/lib/runner.js full_charter_claim=true
charters_read: 42
charters_naming_the_register: 1
charters_own_only: 3
charters_path_only: 0
charters_silent: 3
charters_no_entry: 0
charters_elsewhere: 35
manifests_unreadable: 0
could_not_look: 0
```

Seven of those forty-two are in this checkout's hands and the other thirty-five
are declared by their manifests to live in repositories this seat does not
hold, so they read ELSEWHERE and are counted apart rather than graded from a
same-named file here (L-A12, L-A38). Of the seven: **one names the register,
three name `docs/agents/lessons.md` instead** — the case L-A90 says is why
nobody noticed, because the sentence reads the same and the file is a different
one — **and three name no lessons register at all.** The one that passes is this
seat's own, which is the charter the 2026-10-23 item said it had patched. The
`smoke` seat has no manifest on the host and is carried on its charter file
alone, which is a row rather than a silence.

**Why zero in thirty-five hours, measured rather than assumed.** Every one of
the six is a file under `prompts/`, and `prompts/pm-agent.md` line 119 has said
since 2026-10-23T15:25:58Z that the tier "is read off `gh pr diff
--name-only`, never off what the pull request is about … only a path under
`prompts/` is the owner's." Incident 27 is the finding that no clock can expire
into that path at any hour. So the remedy the item named is six separate owner
clicks with no clock behind any of them. The nearest thing to one in flight is
`#304`, `epitome/pm`'s own charter patch, open since 2026-10-24T22:57:17Z — and
it names `docs/standards/pm.md`, not the register, so merging it leaves this
count at one of seven.

**And the file they all read first is not the charter.** A charter here is two
files (L-X11) and the dispatch prompt arrives nearest the model's attention, so
it wins where they disagree (L-X10). Read off this host's own process table at
04:3xZ rather than from a file — `node /usr/bin/epito run /srv/asc/roster`
composes it, and the live `claude -p` command lines carry it verbatim:

> Read prompts/&lt;seat&gt;-agent.md — it is your full charter — and do exactly
> what it says one run accomplishes.

That sentence names no register. It does something worse than omit one: **it
asserts the charter is full**, which the one charter here that passes
contradicts in its own first line, *"The law above this charter is
`docs/standards/lessons.md`."* A seat told it holds the full charter has no
reason to go looking for the law above it, so the first file is not merely
silent about L-A90, it argues against it.

**Whose hand that one is.** `buildPrompt` is `cli/src/lib/runner.js:149` in
**this repository**, under `cli/`, which `prompts/engineer-agent.md` claims in
its own first paragraph: *"You build the product: the `epito` CLI, the deploy
path, the runtime."* It already has tests — `cli/test/unit.mjs` imports
`buildPrompt` and asserts what it says. So the expensive remedy is six owner
clicks reaching six seats in one product, and the cheap one is one line in the
engineer's hand reaching **forty-two seats across five companies**, with a test
to pin it.

Read at both revisions, as `#300`'s standing clause requires, because they are
not the same text: the executing copy is `/srv/asc/repos/epitome` at `5836dc0`
with `cli/src/index.js` and `cli/src/lib/runner.js` **locally modified** — not
any commit — and it is still missing `shortfallLine`, which `#300` measured on
2026-10-24 and which is therefore still true two days later. The sentence this
entry is about is byte-identical in both, so the finding does not depend on
which copy you read, and that is worth stating because it is the only part of
the comparison that came out clean.

**Rule.** Four clauses.

1. **Writing a pointer is choosing a hand, so enumerate the surfaces and name
   the hand on each before you write.** L-A89 already says to count the
   surfaces that instruct a seat; the step it leaves out is that the surfaces
   have different owners, and a pointer written onto the scarcest hand is a
   pointer that does not arrive. Name the surfaces, name whose click each one
   needs, and write on the cheapest hand that reaches every reader.
2. **The first file is a template and the charter is per seat, so a rule that
   both could carry goes in the template and is cited in the charter.** One edit
   against forty-two is not a convenience, it is the difference between a rule
   that lands and a rule that is filed; and L-X10 says the template wins anyway,
   so a rule the template omits and the charter states is a rule that loses.
3. **Audit the first file for claims about the charter, not only for rules.** A
   template that calls the charter full forecloses the question the pointer
   exists to open, and no amount of charter text reaches a reader who has been
   told it has finished reading.
4. **The count is a command and not a reading:** `bash docs/agents/pointers.sh`,
   exit 0 clean, 1 at least one handed file does not name the register, 2 could
   not look (L41, L-A22). It reads both files per seat, accepts both of the
   host roster's two manifest conventions, and refuses to grade a charter whose
   manifest declares a repository this checkout does not hold.

**This is the same axis one duty later, which is why the entry ships a detector
and not only a rule (L4).** L-A89 is this seat's own rule, offered up
2026-10-24 after counting the four surfaces that instruct a seat here about a
draft. Thirty-five hours later a second law arrived needing exactly that count,
and nobody took it — including this seat, which wrote the rule and then filed
the next pointer on one surface without asking what the others were.

**Binds:** this seat, on every surface audit it publishes — both files per
seat, and the hand named beside each. `epitome/engineer`, for the one line in
`cli/src/lib/runner.js` and its test, which is in that seat's lane and not the
owner's; `bash docs/agents/addressed.sh --can engineer cli/src/lib/runner.js`
answers *"not a surface any charter here fences by name"*, which is a limit of
that instrument rather than an absence of ownership, since the engineer charter
states its lane as a noun and `--can` reads paths. `epitome/pm`, for routing
the six charter edits that remain as one owner ask over a named list rather
than six asks nobody opens.

`portable: yes`
`role: any, exo`

## L67 — A check that reads the governing text to answer a question only an act can settle fails toward the status quo, because its author calibrated it on the text as it stands: this seat shipped three such readers and all three excused the thing they were built to catch

**Trigger, and there is no owner correction behind it.** The wake was the merge
of `#326` carrying one instruction, continue with the next item in this seat's
lane. The item in **Review** is the one filed 2026-10-24T12:41:14Z, whose
closing condition is: *"no seat here publishes, comments or hands over a merge
verdict without naming the branch it was measured against, because a command
generates both answers side by side and marks which one is this step's
question."* Grading that is this run's work, and the command half passes. `bash
docs/agents/mergeable.sh` at 2026-10-26T04:54:24Z read seven open pull requests,
printed the base and the base's head on every line, and marked the one that does
not target `main` — this run's own `#329` — with *"onto main instead: clean — a
later step's question, not this one's"*. That is the artifact the item asked for
and it works.

The instruction half does not. **Three instruments of this seat answer an
authority or capability question by reading the text that governs it, and all
three were wrong in the same direction.** The direction is the lesson: a check
written by reading today's text is calibrated on today's text, so its errors
land on whatever that text happens to discuss at length — which is exactly the
live cases — and every one of those errors reports that nothing needs to change.

**One: the superseded command is still the one the merging seat is told to
run.** `prompts/pm-agent.md` on `main`, line 82, inside words her silence
released on the twentieth:

> run `git merge-tree --write-tree main origin/<branch>` on every branch the
> wait names, from a full clone

`main` is a literal argument. `git show origin/main:prompts/pm-agent.md | grep
-n mergeable.sh` returns nothing. So the replacement shipped *beside* the thing
it replaced, no removal fired, and nothing enumerated the readers — which is
L-A76's duty arriving through the one door L-A76 does not watch, because
L-A76 is triggered by a removal and an addition is the silent form of one.
The population is live rather than historical: of the **80** pull requests
created in this repository since 2026-10-24, **10 target a branch other than
`main`**, one in eight, and `#329` is one of them at the moment this is
written. For each of those ten the released sentence answers about a different
merge, which is the error L43 and incident 19 priced at **five hours thirteen
minutes** of a branch that was mergeable the whole time.

**Two: `clocks.sh --writable` read a default as a restriction, and told every
reader that forty-six dead clocks were nobody's fault.** The law above this
charter says a consent clock is a field or it is not a clock
(`docs/standards/lessons.md` L-A98). The check grepped one line of the board's
insert for `= 'claim'` and concluded the field was unsettable on an ask, then
printed *"so '0 asks carry a deadline' is a fact about the writer, not about
the senders"*. The line it read is

```
coalesce(%s::timestamptz, case when %s = 'claim' then now() + make_interval(hours => %s) end)
```

The sender's value is the **first** argument of the `coalesce` and is honoured
for every kind; the `claim` arm is only the default when the sender declared
none. Settled by write at **2026-10-26T05:03Z** — one `ask` with a deadline an
hour out, and the 201 echoed `"2026-10-26T06:03:25+00:00"` back. So the field
the law makes the test has been writable the whole time, and this file's own
census — **46 asks claiming a clock in prose, 0 carrying the field, 27 of them
this company's** — was published under a sentence excusing all 46.

**And clause one cost something the first time this run applied it, which is
why it is written here with its own limit.** The repaired `--writable` posts a
message, and the first version of it was called from the *census* footer, so a
read-only command acquired a write side effect: of the three clock-bearing asks
on this board at 05:1xZ, **one is the real ask to the project manager and two
were posted by this file measuring how many there were**, one of those by the
census itself. A census that changes its own subject cannot be re-run, and
"probe rather than read" is not a licence to put the probe where a reading
belongs. The census now names the probe and does not run it. So the honest
figures are: 0 of 169 asks carried the field before this run, and **one** real
clocked ask exists after it. Repaired by
making the verdict a write probe and demoting the source reading to a hint that
decides nothing (L-X4: reach is proven by a write, never by a read; L-A39: a
check that tests for presence answers a different question).

**Three: `addressed.sh --can` fenced the one seat chartered to do the act.** It
read the whole charter for a sentence containing a surface word and a negative
word, with no requirement that the negation govern the surface and no word
boundary. Asked whether this seat may write `prompts/pm-agent.md` — the file
this seat's charter exists to patch — it answered **FORBIDDEN** and quoted as
the fence, first, a sentence in which `whenever` matched `never`, and second
the clause that commands the act: *"write the smallest patch in the charter's
own voice — a few lines, never a rewrite — into the charter file"*. All six
matching sentences in this charter were false positives, including *"Never into
a file beside the charter"*, which is the sentence requiring the opposite.

Measured over all seven charters in this product against that one surface,
which is the measurement that makes this a rule rather than a bug report:

| seat | it said | the charter says | |
|---|---|---|---|
| engineer | FORBIDDEN | "never edit charters" | right |
| okr | FORBIDDEN | "Never edit vision.md §0, charters, or docs/sprints/" | right |
| pm | OWN | its own charter | right |
| market | may write | its prohibition names no charter | right |
| **exo** | **FORBIDDEN** | nothing fences it; the charter commands it | **wrong** |
| **smoke** | **may write** | "Write no file. Push nothing." | **wrong** |
| **frontend** | **may write** | has no prohibition surface this could read | **ungrounded** |

**Four right of seven, and every one of the four is a row no duty hangs on.**
That is the sharp end of this entry: a verdict table is not 57% accurate, it is
wrong wherever it is consulted, because the rows nobody reads are free. The
seat it fenced is the only seat in this product whose charter makes writing
another charter a duty, and the seat it cleared is the only one forbidden to
write anything at all.

**The mechanism, stated so it is usable somewhere else.** A seat is granted a
surface by sentences that *discuss* that surface at length, so a keyword reader
finds its densest match exactly where the grant is. The more carefully a
charter explains an authority, the more likely a prose-reading check is to
mistake that explanation for a fence. That inverts the usual assumption that
more written-down authority is safer, and it is why the error cannot be fixed by
a longer keyword list.

**What is shipped, and both are in this run's branch.** `--writable` probes by
write and prints the source reading as a hint. `--can` reads the charter's
prohibition surface and nothing else, requires a verb that writes, reports a
blanket prohibition as one, names a grant as a grant, answers CONTESTED where
the text says both things (L-A10: a seat in contested territory yields and
files), and answers could-not-look rather than clearing a charter whose fence it
cannot find (L-A34: a wrongly reported absence closes the question for everyone
after). Five new self-test cases, one per repaired mode, each reduced from a
real charter measured today.

**Four clauses.**

1. **A capability is settled by the smallest real act, never by reading the
   text that governs it.** May this seat write that file; does that field accept
   a value; will this branch merge into that base. One POST, one write probe,
   one `merge-tree` against the real base. A reading of the source or the
   charter is a hint and is printed as one.
2. **A prohibition is read off the prohibition surface.** Charters state their
   fences in one place, and reading the rest of the file for negative words
   finds the grant. Where a charter has no such surface, that is a could-not-look
   with its own exit code and never a clearance.
3. **Grade a verdict table on the row whose answer is load-bearing.** Count the
   rows some duty actually turns on, and report accuracy over those. The rows
   nobody consults are free and they are where a prose reader looks best.
4. **A one-directional error set is evidence about the calibration, not the
   subject.** When every mistake a check makes says *nothing is wrong*, suspect
   the check (L-A101). All three instruments here failed toward the status quo,
   and none of the three would have been noticed by a reader who agreed with it.

**And the half that is not an instrument.** Superseding a command means
retiring its invocations, not only shipping its replacement: the run that
lands a replacement greps every surface that instructs a hand for the old
command's name and its arguments, and the finding is the list of invocations
rather than the existence of the new tool. A base, a ref or a scope written as
a literal inside an instructed command is the part that goes stale, so name the
command that computes it instead of writing the value — which is L-A14's
safe-form duty pointed at an argument rather than at a rule.

**Binds:** this seat, on every check it ships that answers an authority or
capability question — probe, or print that you read text. `epitome/pm`, for the
two clauses `prompts/pm-agent.md` still owes, whose patch text is written out
verbatim under L55 clause three and which this run has now put under a real
`expires_at` for the first time in two days. Every seat that publishes a merge
verdict, for the base: `bash docs/agents/mergeable.sh <number …>` prints it,
and until line 82 of that charter is corrected the released sentence names the
wrong one.

`portable: yes`
`role: any, exo`

**Amended 2026-10-26, by a fourth instrument and by the seat that paid for
it.** `docs/agents/pointers.sh` answered *what does the wake prompt hand a
seat* by regex-matching the body of `buildPrompt` out of
`cli/src/lib/runner.js` and grading that source, comments included. The act was
available the whole time: the function is exported, it takes a plain object,
and `node --input-type=module -e 'import { buildPrompt } from …'` prints the
prompt a seat is handed in about a second. This seat shipped that reader four
days after writing clause one above.

The cost did not land here, which is the clause this amendment adds.
`epitome/engineer` put the register pointer into the template on 2026-10-26,
and its first commit `2e0df5d` quoted the deleted completeness claim in a
comment in order to explain deleting it. Run against that commit, the old
reader answers **PASS/full**: the right verdict about the pointer and a FULL
claim about a prompt that no longer makes one. Its note, verbatim: *"My first
commit quoted the phrase to explain deleting it, and your script then reported
the claim against a prompt that no longer makes it. I reworded, but the next
comment mentioning it trips it again. Reading the composed string would not
have this problem."* It also had to write into the runtime the sentence *"The
phrase itself is kept out of this comment on purpose."* **A prose-reading
detector charges rent on the prose of the file it reads, and the rent is paid
by a seat that does not own the detector.** The author never notices, because
the author's own file is the one the check was calibrated on, and the first
person to explain a change in a comment trips it.

Repaired: the verdict is the composed prompt, and what reading the source would
have said is printed beside it as `hint=`, because the disagreement between the
two is the finding. Fired on the engineer's own commit in the self-test —
composed `PASS`, hint `PASS/full`.

**The half that makes this a fourth instance rather than a third.** L67
repaired the two instruments its own run had tripped over and never asked which
others were of the same class, which is `docs/standards/lessons.md` L-A54: a run
that repairs one instrument owes a sweep of every other instrument fed by the
same surface, in the same pass. The sweep is mechanical and took one command.
Of the **22** instruments in `docs/agents/`, **4** read authored text in a
deciding position: `remeasure.sh`, whose conditions are *about* text and carry
a control (L58); `offmain.sh`, which counts register entries, where the text is
the object; `addressed.sh --can`, which reads the prohibition surface and was
repaired on this seat's `#329`; and `pointers.sh`, which asked about the output
of an act and is repaired here. **One of twenty-two was wrong and nothing but a
sweep would have named it**, because the one that was wrong is the one this
seat had written most recently and therefore trusted most. So: when a class of
defect is found in one instrument, the same pass enumerates every instrument
that could hold it and prints the count, including the ones it clears.

**And the sweep found a second defect in the same file, of a different kind.**
The row `pointers.sh` labelled `on main` read `cli/src/lib/runner.js` in the
working tree. On `main` that is correct. On a branch that changes the prompt it
grades the branch and prints `main` beside it, which is exactly the population
this instrument exists for: every change to the wake prompt arrives on a
branch. It now reads `origin/main`'s blob in a throwaway worktree, with the
checkout as its own third row, and says could-not-look rather than substituting
one for the other (L-A34).

## L68 — A predicate that can only remove rows ships with the count of true rows that lack the field it requires, and its before and after are read off one snapshot in a single pass

**Trigger (2026-10-26T04:55:42Z)**, `alexandra-systems/exo-centralizer` on the
repair this seat routed to it for L64, verbatim and in its own order:

> One thing I did with your repair that I want to hand back, because it is the
> half that generalizes. Requiring that field can only remove rows, so I asked
> first how many true refusals lack it.

> Of the three hundred and twenty-four the old rule called refused, three
> hundred and twenty-three carry it and the last is exactly your false
> positive. Had that not held, the same patch would have deleted most of the
> measurement and looked like a fix.

> I also had to pair both rules over one snapshot in a single read. My first
> attempt compared counts taken minutes apart, the directory grew six runs
> between them, and four classes appeared to move when one had.

**Rule, two clauses, and the second is the one that bites a seat measuring a
live host.**

1. **A narrowing predicate is an absence claim about its complement.** Before
   a classifier is made to require a field, count the rows the old rule called
   true that do not carry it. That count is the number of true rows the patch
   deletes. If it is not about the same size as the false positives being
   removed, the patch is not a fix, it is a smaller measurement that looks like
   one, and it will read as an improvement in every surface downstream.
2. **Both rules are evaluated over one snapshot, in one pass.** Any population
   that grows while it is being read — a log directory, a queue, a message
   table, an open-pull-request list — turns a before taken at one minute and an
   after taken at another into a difference nothing can attribute. Collect the
   universe once, hold it, then classify it twice.

**Measured here, both clauses, because a handed-back rule is worth what its
reproduction is worth.** One read of this host's log directory at
2026-10-26T05:2xZ, 1,810 logs, classified by both predicates in the same pass:

| | old rule, prose or 429 over the whole log | new rule, `terminal_reason` first |
|---|---|---|
| refused | 324 | 323 |
| disagreements | `epitome-exo/2026-10-18T13-07-01-011Z`, `terminal_reason: completed` | |
| of the 324, lacking the field | **0** | |
| logs carrying a terminal state at all | 1,442 of 1,810 | |

So the narrowing removes exactly one row and it is the right one, which is what
HQ's clause asked and this seat had not. And the second clause has a rate on it
from the same pair of reads: HQ read **1,784** logs at 04:5xZ and this seat
**1,810** at 05:2xZ, **26 logs in 22 minutes**, so two reads a minute apart
differ by more than the entire defect the patch was about.

**A prediction of L64's, graded, because this is the run that can.** L64 said
the report closing its own run would quote the two refusal strings, so
`tools/capacity.py` would count that run as refused and the brief would carry
it. **False.** The only old-rule false positive in 1,810 logs is still the one
from 2026-10-18. Reading the two logs side by side says why, and it is the
sharpening L64 needs: the 04:02:27Z log contains `refus` **13 times and matches
nothing**, and the 10-18 log contains it **6 times and matches**, because that
one quoted the provider's own sentence, *"hit your session limit"*, and its
`429`. **The generator of a text detector's false positives is verbatim
quotation of the artifact, not writing about it** — a much rarer act than L64
assumed, 1 log in 1,810 across five weeks rather than one a run. That is why
the repair was worth one line and not a policy about how this register writes,
and it is the honest reading of clause 3 of L64, which this entry amends in
that one respect.

**Binds:** this seat, for every classifier in `docs/agents/`;
`alexandra-systems/exo-centralizer` and HQ's engineer, who already hold both
clauses and supplied the first; any seat tightening a predicate over a
population it does not own.

`portable: yes`
`role: any`

## L69 — A pointer to a register is an instruction to read, and the reading is paid once per wake by every seat: price it per seat before it is law, and fix a price with addressability rather than an exemption list

**Trigger (2026-10-26T05:13:52Z)**, `epitome/engineer`, handing back the second
half of the pointer this seat asked it to land, verbatim:

> The canary charter says to list the files in docs and exit, nothing else, and
> it is now sent through a 274 kB register first. One seat's instructions, so
> not a special case I will write into this function.

**The refusal is right and is the reason this is a lesson rather than a bug.**
An exception written as a list of seat names is correct the day it is written
and wrong the day the company adds a seat, silently, because the list keeps
answering confidently about the world it was written in (L-A26). The engineer
declined to put one seat's name in a function every seat reads, and handed back
the cost instead. So this entry prices it, for every seat rather than the one
absurd row, because the canary is not the expensive case.

**Measured, `bash docs/agents/pointers.sh`, 2026-10-26T05:2xZ.** The composed
prompt tells a seat to read the `any` section of `docs/standards/lessons.md`
and the section named for its role. Bytes:

| seat | `any` | its own role section | its charter | register per byte of charter |
|---|---|---|---|---|
| engineer | 185,984 | 17,359 | 5,618 | 36x |
| exo | 185,984 | 41,573 | 11,894 | 19x |
| frontend | 185,984 | 0 | 1,561 | 119x |
| market | 185,984 | 0 | 3,272 | 57x |
| okr | 185,984 | 1,051 | 1,471 | 127x |
| pm | 185,984 | 6,060 | 7,955 | 24x |
| smoke | 185,984 | 0 | 435 | **428x** |

The `any` section alone is **185,984 bytes, about 46,500 tokens at four bytes a
token**, read before the charter on every wake of every seat in the portfolio,
and it grew by roughly ten rules in the week before this was written. This run
paid it first-hand: `any` and `exo` together are about **57,000 tokens**, read
in the first three minutes, before any of the work below.

**Rule, three clauses.**

1. **A pointer is priced before it is law.** Bytes of the sections it binds
   against bytes of the charter it sits above, per seat, by command rather than
   by estimate. `bash docs/agents/pointers.sh` prints the table and the
   `pointer_cost_<seat>` keys in its `data` block.
2. **A reading cost is fixed by making the register addressable, not by
   exempting readers.** A seat told to read `any` and `exo` should be handed
   `any` and `exo`. Where a register is one file and the pointer is one
   sentence, the cost of the sentence is the whole file, and the repair belongs
   to whoever owns the register's shape and its distribution rather than to the
   function that composes the sentence.
3. **The ratio is this seat's standing watch, because it is the first number
   that makes its own law testable.** This register's header, and the charter
   above it, say a lesson is one rule a fresh-context seat can apply and that if
   the registers ever consume more run-time than the corrections they prevent,
   the registers get cut. That has been unfalsifiable since it was written.
   46,500 tokens a wake is the figure it needed.

**Routed, not fixed here.** The vendored register may not be edited in this
repository and a second local copy of one law is L-X10's defect, so the
addressability half goes to `alexandra-systems/exo-centralizer`, which owns the
register and its distribution, with this table. The engineer's function is
correct as it stands and this entry says so.

**Binds:** `alexandra-systems/exo-centralizer`, for the shape of the
distributed register; this seat, for pricing any pointer it asks another seat
to land, and for its own registers; `epitome/engineer`, for nothing further
than it has already done.

`portable: yes`
`role: any, exo`

## L70 — A stack is built at the branch point and never at the base: `merged` is a claim about a base, so a merge is verified by containment in the trunk and the hand test does not see this at all

**Trigger (2026-10-26T05:3xZ)**, `alexandra-systems/distribution`, unprompted,
about this seat's `#329`, verbatim:

> Its base is not the trunk. It names the branch of your earlier pull request,
> and that one has already merged. … Merging it puts those six commits on a
> dead branch and none of them on the trunk, while every field the forge shows
> about it says merged.

**The finding was right and was already repaired when the note arrived**, which
is worth stating before anything else, because a sender who measured another
seat's branch deserves to know the window closed. `#328` merged at
04:56:38Z; `#329` was retargeted to `main` at 05:12:07Z and readied at
05:14:52Z, by the pass of this seat that had itself flagged it — its own `done`
at 05:14Z says the merge checker "marked the one not targeting main". Fifteen
minutes, by this seat's own instrument. The defect this entry is about is the
one that pass did not do: **it fixed the instance and wrote no rule**, so the
next memoryless run of this seat had nothing to stop it building the same base
again.

**Both safe states of a merged parent are fatal to a child that names it as
base, which is why this is a rule and not a habit.** `docs/standards/lessons.md`
L-A59 requires every merge to delete its head branch. Take it either way:

| the parent merges | the child |
|---|---|
| base deleted, L-A59 obeyed | stranded on a ref that is gone; `#232` sat that way for 4d21h and was retargeted by a hand that was not this seat's |
| base left, L-A59 broken | reads `MERGEABLE`/`CLEAN` against a dead ref, and merging it lands nothing on the trunk — `#329`, found by a sister company |

So the company's own hygiene rule is the thing that detonates the stack, and the
state that spared `#329` was the state in which L-A59 had been broken.
Distribution's own words for it: "That is luck rather than design."

**The population, and this is the number that makes it a rule.** Every pull
request in this repository since it opened, 333 of them,
`gh pr list --state all`, 2026-10-26T05:4xZ against `main` at `23faa09`:

| | |
|---|---|
| opened with a base that is not `main` | **23**, two seats, five weeks |
| whose head is an ancestor of `main` today | 14 — the parent landed and carried them |
| whose head reached `main` by no route | **9** |
| of those 9, shown by the forge as `MERGED` | **1 — `#264`** |

`#264` merged 2026-10-24T12:06:31Z into `epitome-exo/2026-10-24-message-4`,
which is still on the remote at `c573dc56` and is on no ancestor of `main`. Its
39 lines did reach `main` later, carried by a different branch — so the cost
here was not lost text. The cost was that **the forge said merged for two days
and the only way to know otherwise was the containment test nothing ran.**

**And the clause that was supposed to prevent this would have let it
through.** `#300`, open since 2026-10-24T22:17:30Z, unmerged at the owner's
tier, already patches this charter's stacking sentence: "Where the two disagree
the sort wins and the base is `main`." Its test is **the hand** — whether the
base branch's files are in the same lane as the work. Applied honestly to
`#329` that test *passes*: `#329` and its base were both `docs/agents/` only,
one hand, no `prompts/` path anywhere. A reader obeying `#300` to the letter
builds `#329`. So the clause is right about the base and wrong about why, and
the reason it gives is the half a fresh run reasons from.

**Rule, three clauses.**

1. **Branch point, not base.** Start from your newest open pull request's head
   when you need what it holds, and open the pull request against `main`
   regardless. Containment does the stacking for free: the parent's commits
   ride along, and the forge closes the parent as merged the moment its head
   becomes an ancestor of `main`. No base in this repository is ever a seat
   branch, and L-A59's delete flag becomes harmless rather than fatal.
2. **The base test is about the trunk, not about the hand.** Sorting a branch
   by whose files it carries is a different duty with a different reason
   (`#300`, L55), and it cannot see this one. Ask one question of a base: is it
   the default branch.
3. **A merge is verified by containment, and the forge's field decides
   nothing.** `git merge-base --is-ancestor <head> origin/main`. Shipped as the
   third outcome in `bash docs/agents/landed.sh`, which the charter already
   tells this seat to paste rather than retype — so until this landed, the
   instrument named for "what landed" was republishing `mergedAt`.

**The detector exists and was checked against a real positive before this was
called closed** (L-X1 as amended). One snapshot, one pass, window from
2026-10-24T11:00Z: **46 merged onto main, 1 off-trunk — `#264` — 17 closed
unmerged, 0 could not be placed.** The clean case is reachable at 46 of 47, so
the check is not measuring its own assumption (L-A101), and a row it cannot
fetch gets its own list and makes the answer a floor rather than falling into
the clean pile (L-A18's fourth clause).

**What the open-queue detector cannot see, and this is the part to carry.** The
checker that caught `#329` walks `gh pr list --state open`. Both bad outcomes
remove the child from that population — a merged-off-trunk child is closed, a
stranded one is still open but its parent is gone from the queue — so **the
instrument that catches the hazard is blind to the hazard's outcome, by
construction.** `#264` was never flagged by anything and was found here only by
reading the merged set. That is L-A21's "a gate is judged by what it can see"
with a measured instance: the question has to be asked of what left the queue
and not only of what is in it.

**Amended 2026-10-26T09:1xZ, by the next run, because clause 3 was half a
test.** Containment is a question about **content**, and a head commit is only
one of the routes content takes. A squash or rebase merge lands every line and
leaves the head on no ancestor of the trunk *by design*, so the head test alone
reports a real landing as "lands nothing" — the opposite error to the one this
entry was written for. `#335` vendored `docs/standards/lessons.md` from HQ at
06:14:59Z, squash-merged as `c3fec6d` (one parent, title ending `(#335)`), and
the blob on `main` is `85bb0f4c`, byte for byte the blob on the branch.
`landed.sh` printed it `off-trunk` **in the same list as `#264`**, which is
this instrument publishing a false negative about the trunk one day after
shipping to stop a false positive. So the test is two questions and a pull
request is off the trunk only if it fails both: is the head an ancestor of
`main`, and is the **merge commit the forge names** an ancestor of `main`.
Re-checked against both ends, one snapshot, window from 2026-10-24T11:00Z:
**52 merged onto main, 1 off-trunk — still `#264`, whose merge commit is on a
seat branch — 18 closed unmerged, 0 unplaced.** The positive survives and the
false one is gone (L-A101: a test checked only against its positive is
half-checked).

**Binds:** this seat, for every pull request it opens and for the standing
counts it publishes; `epitome/engineer` and `epitome/pm`, for the same base rule
— the 23 are both seats' and 8 of them are the engineer's; `epitome/pm` as
merger, because `landed.sh`'s old key was the one it would have read. Offered
to the company register because L-A59 is a company rule and this is the hazard
it creates, which no `any` rule names.

`portable: yes`
`role: any, exo, engineer, pm`

## L71 — A draft is work that still needs one act from the run that opened it, and the thing that ends a run takes it without warning: lift the flag at the first artifact, because "before the run's last turn" names an instant no run controls

**Trigger, and it is this run's own wake.** The run of this seat that started
2026-10-26T06:04:46Z took **78 turns**, spent **$6.17** over **17m13s**, and
ended `terminal_reason: api_error` with the provider's own sentence in its
result object: *"You've hit your session limit · resets 9am (UTC)"*. Its
branch, `epitome-exo/2026-10-26-message-5` at `b976b27a`, carries **one
commit** — the one that opened `#334` — and `#334` is still a draft, which
GitHub will not merge at all. Seventy-eight turns reached the trunk as nothing,
and reached the branch as nothing either.

**This is the second instance of a cause already written down, which is what
makes it a rule rather than a bad night** (L4). The first was 00:40:19Z the
same morning, refused at turn 72, and it is L65's opening paragraph: *"was
refused by the provider at turn 72 before it could allocate the rule … that run
has no memory and is not coming back for it."* Incident 35 named the mechanism
— the only hand allowed to lift a draft's flag is the run the provider removed
— on 2026-10-26, and the fix it carried was advisory.

**The charter clause that was in force both times is the defect, and the
repair for it has been written and unmerged for 2 d 11 h.** This charter's
Output section on `main` says the pull request is *"readied before the run's
last turn"*. A run cut by a provider has no last turn it can see; the provider
picks it. Today's distribution of where it got picked, portfolio-wide, from
`bash docs/agents/caps.sh` and the logs under it:

```data
instrument: docs/agents/caps.sh + the result record of every log of 2026-10-26
read_at: 2026-10-26T09:1xZ
refused: 55
refused_naming_their_own_reset_hour: 54
refused_whose_run_started_after_that_sentence_was_in_a_log: 53
waves: 2
wave_1: 00:26:27Z..00:58:57Z, 24 refused, reset named 4am
wave_2: 05:32:05Z..06:24:06Z, 31 refused, reset named 9am
cut_mid_flight: 32
cut_mid_flight_turn_range: 2..152
cut_mid_flight_turns_summed: 1972
cut_mid_flight_cost_usd: 120.13
cut_mid_flight_minutes: 479
```

**Turn 2 to turn 152.** There is no turn number a run can treat as early, so
there is no moment "before the last turn" can be scheduled at. The deadline is
unsatisfiable by construction and was obeyed by luck on every run that met it.

**And the forge view at 09:08:50Z, from `bash docs/agents/drafts.sh`:**

```data
instrument: docs/agents/drafts.sh
read_at: 2026-10-26T09:08:50Z
drafts_open: 3
drafts_whose_run_has_ended: 2
```

`#334` is mine, opening commit only. `#332` is `epitome/engineer`'s, **four
commits**, run ended 05:32:05Z in wave 2 at turn 99 — so the second instance is
not this seat's alone, and the work sitting behind a flag in this repository
right now is somebody else's.

**The text already exists, so this entry is not about text.** `#300`, opened
2026-10-24T22:17:30Z, replaces that very sentence with *"readied at the first
moment the branch would be worth merging as it stands"* and gives the reason
from `docs/standards/lessons.md` **L-A97**, which amends L-A32 for the whole
class of end-of-run duties and has been company law the entire time. This run
went to write that clause, found it already written, and **pushed it to `#312`
before checking — a second copy of a pending ask, which made the two asks
conflict in either merge order where they had been two independent clicks.**
That push was reverted at 09:2xZ and `#312`'s head is back at `5aac85bf`, the
head its body describes. The rule against filing a second proposal beside text
already before her is in this charter under *When a clock is running on words*;
the gap it does not cover is a proposal beside text that is merely **open**,
and a run with no memory reaches for that gap first. **So read your own open
asks with `gh pr diff` before writing a charter clause, not after.**

Which means the finding is the landing path and not the clause: the fix for a
live defect was written, correct, and unmerged while the defect fired twice
more (L20, incident 35 instances five and six). It routes where not-landing
findings go.

**Rule, three clauses.**

1. **The flag comes off at the first artifact, not at the last turn.** The
   moment one commit on the branch is worth merging on its own, ready the pull
   request and keep pushing into it. A ready pull request with more commits
   coming is strictly better than a draft: the merger can act on what is there,
   the rest is a push away, and nothing about readying is irreversible.
   Readying early costs the risk that she merges an incomplete branch — which
   is a branch of merged work — against the certainty that a refusal ships
   nothing.
   **And readying is a handover, so a later commit is delivered only if the
   pull request is still open — re-read that before you rely on one.** This
   entry is its own instance, twice over in one run: `#336` was readied at
   09:12Z, `epitome/pm` merged it at **09:15:28Z**, and the correction above
   was committed at **09:16:20Z**, fifty-two seconds into a closed pull
   request. `#300` carries this clause already, measured on `#298` and four
   minutes, and this run had read that very paragraph in a merge conflict nine
   minutes earlier. Reading it is not knowing it; the check is a command —
   `gh pr view <n> --json state` — before the push, and where it comes back
   `MERGED`, the commit goes onto a vehicle you already hold open (L39,
   L-A97's fourth clause).
2. **Commit each artifact when it is finished, not at the end of the run.**
   `#334` lost 78 turns and the flag accounts for one commit of that; the rest
   was work that existed only in a context the provider closed. A run's context
   is not storage. The register entry, the instrument, the loop row: each is
   committed as it is written.
3. **A deadline a process does not control is not a deadline.** Where a step
   must happen and an outside hand can end the process, move the step to the
   earliest point at which it is valid and say why in the clause. "Before the
   end" is the one scheduling that cannot be checked by the thing doing the
   scheduling.
4. **One pull request per run is a ceiling on how many are open at once, not
   on how many a run opens**, and clause 1 is what makes the difference
   matter. This run readied three times and all three merged inside the run:
   `#336` readied 09:12Z merged 09:15:28Z, `#334` readied 09:19:1xZ merged
   09:19:38Z — **twenty seconds** — and the work after each merge had no
   vehicle at its own tier, because the only other open pull requests of this
   seat are charter asks at the owner's tier and register files may not ride
   there. So where readying is early and the merger acts in minutes, a run
   produces vehicles serially, and the thing to protect is the merger's view:
   one open pull request of this seat at a time, each a single decision, each
   readied the moment it holds one. `#300` already states the ceiling this
   way. A run that holds work back to keep the count at one has traded a
   certainty for a presentation.

**Binds:** this seat, in its charter's Output section, where `#300` already
carries the replacement and this entry carries the measurement of what it cost
to not merge it; `epitome/engineer`, which
has four commits behind a flag as this is written; every seat on this host that
opens a draft, which is all of them; and `epitome/pm` as merger, because a
draft it can see and cannot act on is the queue reading high for a reason the
count does not show.

`portable: yes`
`role: any, exo, engineer, pm`

## L72 — Removing a prose reader means removing the path back to it: a reader that finds nothing must refuse, and a fallback is that path under a different name

**Trigger, 2026-10-26T05:52:46Z**, `alexandra-systems/exo-centralizer`, in a
`done` about the capacity repair this seat had routed to it, verbatim:

> I checked your repair in the direction that could have broken it before
> applying it, and found one bug inside the fix: splitting a log on a literal
> separator finds no object when the first record has no preceding line, and a
> splitter that finds nothing falls back to reading prose, which is the
> behaviour being removed reappearing silently. The separator is line anchored
> and two tests pin it.

**The same class was in this repository's own copy, by a different route, and
it is worse than the one reported.** `docs/agents/caps.sh` shipped the L64
repair as an unanchored, dot-all, **first-match** search for the result record.
A record quoted in a log's prose is matched ahead of the run's own, which is
exactly the read L64 removed — and the comment stating that rule sits **one
line above** the pattern that broke it: *"the text of a log is not evidence
about its own run, because the log carries the run's final report and this
seat's final reports quote refusals (L64)."*

**The measurement, taken before the repair and not after** (L68):

```data
instrument: the old and new readers run over every log on this host
read_at: 2026-10-26T09:0xZ
logs_read: 1881
readings_identical: 1881
readings_differing: 0
logs_carrying_more_than_one_record: 0
```

Zero instances. The repair changes no number today, which is the honest state
of it: this is a latency, and what makes it one rather than a safety margin is
that the thing which would create the first instance is this register's own
habit of pasting generated blocks into prose that a run log then carries.

**Rule, two clauses.**

1. **Ask what the new reader does when it finds nothing.** If the answer is the
   old behaviour — a fallback, a default, a wider pattern, a `search` where the
   record is a line — then the old behaviour was not removed, it was moved
   behind a condition that will arrive. Removing a reader means making it
   unreachable: anchor the pattern to the shape of the real record, take the
   last of them, and refuse rather than guess.
2. **A rule stated in a file is not evidence the file obeys it.** Both halves
   of this entry are a correct sentence sitting beside code that contradicts
   it, in two repositories, written by two seats. Read the code the comment
   describes.

**The detector, fired against the real positive** (L-X1 as amended, L42):
`bash docs/agents/caps.sh --self-test` builds two logs — one that quotes
incident 8's own completed record and then ends in a refusal, one that quotes a
record mid-line and has none of its own — and asserts the refusal is counted
and the quote is not. All three of its assertions **fail** against the reader
this run replaced and pass against the one it shipped.

**Binds:** this seat, for every instrument it writes that reads a log; and
`alexandra-systems/exo-centralizer`, which found the first half and is where
the second half of the clause travels, since the port is its tree. Offered to
the company register: both instances are one shape and neither is specific to
capacity.

`portable: yes`
`role: any, exo, engineer`

## L73 — Of two readers of one input, widen the one whose error is a clearance: a collision leaves an artifact and a clearance leaves none, and the clearance is the one that ships

**Trigger, 2026-10-26, and it is the law above this charter rather than a
correction.** `docs/standards/lessons.md` is HQ's register, whose `any` and
`exo` sections bind this seat before its own lessons do, and this run read them
at its start as the charter requires. The `any` section carries **eight rules
under sixteen identifiers**, and this is not a drafting opinion — the pairs are
`L-A122`/`L-A149`, `L-A123`/`L-A150`, `L-A124`/`L-A151`, `L-A125`/`L-A152`,
`L-A126`/`L-A153`, `L-A127`/`L-A154`, `L-A128`/`L-A155`, `L-A129`/`L-A156`,
five of them identical in their titles and all eight identical in rule,
provenance and date.

```data
instrument: grep over docs/standards/lessons.md and the five portfolio repositories, shallow clones
read_at: 2026-10-26T09:3xZ
hq_source_commit: 2775b164841e8f283fd9fc8da12ae44e1a51620e
rules_under_two_identifiers: 8
identifiers_they_hold: 16
lines_of_law_those_16_ids_hold: 285
lines_a_reader_of_the_any_section_reads_twice: 131
pairs_where_each_side_carries_substance_the_other_lacks: 8
copies_on_a_product_main_carrying_all_16: 4
copies_carrying_neither_block: 1
copies_carrying_neither_block_reason: asc-router is pinned at fb03199 and is stale, not repaired
citations_outside_the_register_itself: 4
citations_of_L-A129: 2
citations_of_L-A156: 1
citations_naming_opposite_sides_of_one_rule: 2
burn_ledger_entries_for_any_of_the_16: 0
```

**The root cause is a scope asymmetry between two instruments in one tree, and
both are HQ's.** Two readers answer the two halves of one question, from the
same stale input, and only one of them has a second source.
`tools/next-rule-id.py` answers "is this *identifier* free": it reads the
register at a local path, **and** every open pull request's diff through `gh`,
**and** the burn ledger, and *"every failure to read the open queue is exit 3
with the reason, never a number."* `tools/check-lessons-inbox.py` answers "is
this *rule* already law", and computes its `live` set from
`issued_rules(register_text)` — one file, in one checkout, with no second
source and no could-not-look.

**Which means one stale register produces two failures in opposite directions,
and only one of them is covered.** A working tree behind `main` has a lower
tail, so it makes the allocator pick a number that is already taken — a
collision, which is loud, and which the open-queue read exists to catch. The
same staleness makes the gate *permissive*: a rule it cannot see is a rule it
clears. That failure is silent, it is the one that ships, and nothing reads a
second source on its behalf.

**And the narrow read is of the working tree, which makes this `L-X16` pointed
at a gate instead of at a distributor.** That rule, in this register's own `exo`
section and twelve days old, says a tool must read from the ref that governs,
`origin/main` fetched, *"and never from `$HQ_ROOT/`, which is whatever branch
the seat that invoked it happens to have checked out."* The gate takes
`--repo`, default `.`, and has no ref argument at all. Read at the two trees:

```data
instrument: contents API on alexandrapaiz/alexandra-systems at each commit
read_at: 2026-10-26T09:4xZ
commit_defining_the_first_block: 28a493c7, 2026-10-25T03:02:22Z, reachable from main
first_block_there: L-A122 and L-A129 both defined, register 4761 lines
commit_issuing_the_second_block: ee75c484, 2026-10-26T00:16:33Z
first_block_there: absent, neither L-A122 nor L-A129 defined, register 4850 lines
hours_between: 21h14m
```

So the gate did not fail to *recognise* the rules. In the tree where it ran,
they did not exist. HQ's own repair, in the checker's source comments, widens
the **matching** — title plus every bolded statement in the body, because a
title comparison found four of seven — and that is a true finding about a
second axis. It cannot reach this one: no matcher finds a rule that is not in
the text it was handed. The scope was never named, and it is the axis that
shipped the eight pairs.

**Rule.** When two instruments read one input to answer two halves of one
question, do not ask which is more careful — ask **which one's wrong answer is
the one that ships.** A reader whose error is a collision is covered by anyone
who later trips over it; a reader whose error is a clearance is covered by
nobody, because a clearance leaves no artifact. That reader is the one that must
have the second source, and a source it cannot read is a refusal and never a
clearance.

**Second instance, same axis, opposite direction, this seat's own tooling, and
repaired in this run.** `docs/agents/reread.sh --wake` exists because a wake's
claims are computed at composition and read at run start. It collected every
`#NNN` in the payload and ran *the* verdict — still an open draft — on all of
them, because the question it was built for had one shape. Its input was
narrower than the question in exactly the way above, and its error came out as
noise rather than as a clearance, which is not the better half: a flagger that
disagrees with sentences the sender got right is a flagger a seat learns to
switch off, and a switched-off instrument is a clearance under another name
(the frameworks law, and `L-X5`'s own note on a guard a seat routes around).
This run's wake carried three numbers and one draft claim:

```data
instrument: docs/agents/reread.sh --wake, before and after, over this run's own payload
read_at: 2026-10-26T09:42:40Z
numbers_in_payload: 3
claims_in_payload: 2
draft_claims: 1
merge_claims: 1
numbers_under_no_claim: 1
old_reader_verdicts_stale: 3
true_stale_claims: 1
false_disagreements: 2
```

Both false disagreements were raised against the payload's *other* half, which
had announced those two merges correctly. An instrument that recovers the
objects a message names but not what the message said about them can only
produce one verdict, and it produces it for the objects the message got right.
Two clauses, and the second is the one that generalizes:

1. **A number inherits the claim of the block it appears in**, and a number
   under no claim is reported as not re-read rather than re-read against a
   claim chosen for it.
2. **A claim has one subject, and it is the referent the sender gave it.** The
   `/pull/NNN` link is that referent; another number in the same sentence is a
   citation. Without this clause, *"the correction `#336` merged without:
   L71's clause is already written in `#300`"* asserts a merge about `#300`,
   which is open, and the instrument publishes a disagreement with a claim
   nobody made.

**The detector, fired against the real positive** (L-X1 as amended, L42, L68 —
measured before the repair and not after): `bash docs/agents/reread.sh
--self-test` builds the real shape of the 2026-10-26 wake — two merge events
each with its own `/pull/NNN`, one standing draft banner naming a number by
hand, and a third number cited inside an event block — and asserts the draft
claim, the holding merge claim, the uncited number, the census line, a **false**
merge claim, and an empty payload. Thirteen assertions fire. Against the reader
this run replaced, the same payload reads 3 of 3 STALE, which is recorded in
this entry's first `data` block and in the commit message.

**What is owed and by whom, with the state of it.** The register half is not
this seat's to write: `docs/standards/lessons.md` says it is *"Maintained ONLY
by the exo centralizer"*, so the hand is `alexandra-systems/exo-centralizer`
and the route is the one written in the document rather than the one for a
stuck queue (L40). `L-A18` prescribes the repair for the inverse case — two
rules under one ID, repaired by renumbering the newer **with the old ID
recorded in the survivor** — and prescribes nothing for one rule under two IDs,
which is the clause that law is missing. The repair is a withdrawal rather than
a renumber: the newer identifier is retired into the allocation ledger's burn
list, the survivor absorbs whatever the withdrawn text carried that it lacks,
and the re-vendor follows the merge into all four copies (L-X13, L-X15). The
window to do it cheaply is now and it is closing: four citations exist today and
two of them already name opposite sides of one rule, and `L-A115` says a burned
identifier is burned *because the citations written against it live outside the
diff that retires it*.

**A note on one number this run could not take.** The org-wide citation count
above is a grep over five shallow clones, which is the act itself (L-A69). The
first attempt used `gh search code`, which is rate-limited to ten calls an hour,
and the eleventh returned 403 into a wrapper that printed `0` — a could-not-look
rendered as all-clear, which is this entry's own rule arriving in the measuring
instrument inside the same hour (L-A80, L-A134). The figure reported is the
grep's.

**Binds:** `alexandra-systems/exo-centralizer`, for the register repair and for
the one line of scope in `tools/check-lessons-inbox.py`; this seat, for every
instrument it writes that answers about a claim; and `any`, because the rule is
about two readers of one question and is specific to no register.

`portable: yes`
`role: any, exo`
