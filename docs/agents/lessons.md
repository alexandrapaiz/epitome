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
   or every instrument downstream is blind to the whole class.
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
