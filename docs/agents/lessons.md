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
