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

## L9 — An open pull request is work; an open card is not evidence that nobody built it

**Trigger (2026-09-29)**, the owner's directive after the cycle-1 stack
was landed by hand: "report the cause and system to ExO, including HQ."
The artifact behind it: the identity/token card was independently built
five times (#9, #10, #20, #14/#15, #23) while every copy's own run read
the same untouched card.

**Rule.** Every seat run starts from a fresh clone of `main`, where
in-flight work is invisible and every card looks exactly as the last run
left it. So the card is not the state of the work — the pull request
list is. Before building anything, read it: `gh pr list --state open`
for work in flight, and `gh pr list --state all --search "<the thing>"`
for work already done and closed. If your card is already built in an
open PR, you do not build a second copy: you extend that branch, or you
write the one paragraph that proposes closing it as superseded and stop.
Both are complete runs. If the built work is unmerged and stacked,
landing it beats adding to it. Name the PRs you checked in your PR body;
a run that skipped the check and duplicated work is a failed run even
when its code is good.

Second half, and the part that makes this structural rather than a
reminder: **this applies to your own seat's previous runs.** The PM
named this exact duplication in #22 on 09-28 and the fifth copy opened
on 09-29, because the naming was itself in an open pull request that no
later run read. A finding that lives only in an unmerged PR has not been
reported to anyone.

**Binds:** every seat that builds or writes to a file it owns —
engineer, pm, market, okr, exo. In charter as of 2026-09-29 for the
engineer only (prompts/engineer-agent.md, commit e36da5b); proposed for
pm, okr and exo in docs/agents/patches/.

*Full record: epitome incident 2. Portfolio rule: the chair filed this
same rule at HQ on 2026-09-29 and called it **L-E7**, but `L-E7` in the
copy vendored here (`775ce36`, 2026-09-28) is the open-routing rule, and
this rule is not in that copy at all. So the cross-reference is to the
rule's text, not to its number, until the next lessons sync settles it —
incident 2's ID note has the detail.*

portable: yes

## L10 — Status is read from the merge queue, not from the board; a stack deeper than two is a queue, not progress

**Trigger (2026-09-29)**, same directive. The artifact: five bets
rendered as five hills moving downhill while they were in fact one
six-deep chain of unmerged PRs (`#11 → #14 → #15 → #16 → #17 → #21`)
with a single exit, unmerged for four days, and the first composed run
of the chain — on the day it landed — found three real defects.

**Rule.** Any seat reporting status derives it from `gh pr list`, not
from cards: what is open, what is merged, and what each open PR targets.
Cards record intent, and intent is what a stalled queue looks like from
the inside. A rule that names an inference without naming the command
that performs it is advice, not mechanism, so the command belongs in the
charter.

The concrete test this produces: **read the `baseRefName` of every open
PR.** Any chain deeper than two — a PR targeting a PR targeting a PR —
is flagged in the report as a queue with one exit and a named landing
order, never drawn as parallel progress. Its true position is the
position of its least-finished member, because nothing in it ships until
the tip merges. Corollary from the same evidence: work that has never
run composed with what it stacks on has an unknown position, not a
downhill one.

Third clause, tooling: **a stacked PR does not auto-close when its
commits land.** GitHub marks a PR merged only when its own base branch
receives the merge, so a chain landed at the tip leaves every member
recording as open-then-closed-unmerged. Whoever lands a stack closes its
members in the same pass, naming the merge commit that carries them, and
whoever counts open PRs treats a chain as one unit of work. Ten manual
closes by the owner inside two and a half minutes on 2026-09-30 is what
skipping this costs.

**Binds:** pm (hill charts, duplication checks, the cooldown
scorecard); okr, whose gradings read repo evidence and would score
five built-but-unmerged bets 0.0; engineer, for the landing pass.
Proposed as charter diffs in docs/agents/patches/, unratified.

*Full record: epitome incident 2, RC-2 and RC-3. No HQ counterpart
yet: this one is new, and is marked portable as a candidate for the next
harvest. For completeness on the case file's other citation — the rule
it calls **L-E6** (a fallback step needs `continue-on-error`, a no-ship
tripwire counts commits rather than remote branches, a paid route stays
behind a variable) is **L-E8** in the vendored copy, it binds the
engineer seat on workflow mechanics, and it is ratified here unchanged;
it is from the same batch as L9 but has nothing to do with stack depth.*

portable: yes

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

