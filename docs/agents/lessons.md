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

*IDs L9 and L10 are reserved: they are taken by the entries in flight in
PR #26 (an open PR is work; status is read from the merge queue). This
run read that PR before writing and numbered from 11 rather than
renumbering anything — the hazard #26's own exo patch was written for.*

## L11 — A seat's charter is three files, and the launcher wins

**Trigger (2026-09-30)**, the weekly drift review, with no owner
correction behind it: two branch conventions for the same seats are live
in this repository's own pull request list, and this seat is forbidden to
edit charters by one of its launchers and permitted by another.

**Rule.** Every seat here is instructed by three files, not two:
`prompts/<seat>-agent.md`, the inline `prompt:` block of
`.github/workflows/agent-<seat>.yml`, and `buildPrompt` in
`cli/src/lib/runner.js`, which is the dispatch the resident runtime
composes when it wakes a seat. The third is product code, which is why
no charter audit had read it. Where they disagree, expect the launcher
to win: the charter is a file the seat is told to go and read, the
launcher is the sentence it is already reading. So an audit of what a
seat is instructed to do reads all three or it has read a third of the
charter, and a rule the charter owns appears in none of the launchers —
they carry L-X10's pointer form and nothing else.

The two live divergences, both verifiable in one command each:

- **Branch convention.** `runner.js:71` builds `<agent-name>/<date>-<trigger>`,
  so the runtime's seats branch `epitome-pm/...`, `epitome-exo/...`;
  the five workflow prompts hardcode `<seat>/YYYY-MM-DD-slug`, so the
  Actions seats branch `pm/...`, `exo/...`. Both are in `gh pr list`
  today. No run has reported filtering by prefix, so the proven cost is
  narrower than it looks and worth stating exactly: a seat's own work is
  not findable by one pattern, and two of the three unread PM pull
  requests #26 names (#12, #18) sit on the prefix the other four do not.
- **The charter-edit prohibition.** The workflow prompt says "never edit
  charters"; `runner.js:72` says "never touch secrets or workflows" and
  does not mention charters. For this seat, whose central duty is
  charter patches, the two launchers give opposite answers about its own
  main job. The safe reading is the one both permit and §10 of the pm
  standard requires anyway — patches as reviewed diffs, never as edits —
  and that resolution was written in neither launcher nor this charter
  until the patch this run proposes.

**Binds:** exo (the three-file sweep is part of its drift review, per
the proposed patch); engineer, which owns `runner.js`; the exo
centralizer, which owns the workflow blocks. HQ L-X11 said the charter
is two files; this is the same rule with the product's own runtime
counted, and it generalizes to any product whose seats can be woken by
more than one launcher — which is epito's whole thesis.

`portable: yes`

## L12 — A commented-out cron is a cadence of zero, and it reads as a cadence

**Trigger (2026-09-30)**, the same drift review. `gh run list` over
this repository's entire history, against the cadence each charter
claims in its opening sentence:

| Seat | Charter says | `on:` block | Runs ever | Scheduled |
|---|---|---|---|---|
| engineer | daily | twice daily | 14 | 12 |
| pm | weekly | weekly, Mon | 5 | 1 |
| market | weekly (Friday) | weekly, Fri | 0 | 0 |
| okr | monthly | monthly, the 1st | 0 | 0 |
| exo | weekly on schedule | **commented out** | 1 | 0 |

**Rule.** Run the cadence test (L-X6) against the cron as *enabled*,
never against the cadence a charter claims, because a commented-out
schedule, a schedule correctly withheld pending the supervised smoke run
L-X2 requires, and a schedule whose first fire has not arrived yet all
present as "weekly" or "monthly" to every audit that reads a charter.
Read the `on:` block, then count the runs. Two corollaries this seat
proved on itself and on the seat below it:

- **A charter sentence is not a schedule.** This charter says "weekly on
  schedule"; the `schedule:` block in `agent-exo.yml` has never been
  uncommented, and §11.4 of the pm standard forbids the one seat that
  dispatches from waking this one ("never dispatch the exo seat — it
  audits you"). The seat's real trigger is the owner's attention, which
  is L-X12's own definition of a missing seat, and this run is the proof:
  it was triggered by a window.
- **The un-fired smoke run is a cadence item with an age, not a
  checklist item.** It is the only thing between a written schedule and
  a live one, so it is tracked the way queue depth is (L-X7). The okr
  seat is the cost: twelve days after founding, in a company running
  two-week cycles, its monthly cron had not yet fired once,
  `docs/okrs.md` did not exist, and two charters already forbade editing
  it. The file is being written tonight — by a window (#35), not by the
  schedule.

And the half that makes this actionable rather than clever: **only a
cron edit changes a cadence** (L-X6), crons live in workflow files,
those are Tier C and the centralizer's, so the output of this finding is
a named request to the owner and HQ, never a charter patch. A charter
patch against a cadence gap is the fix that cannot work.

**Binds:** exo, which runs the audit; and anyone writing a cadence into
a charter — the chair, the centralizer, the owner.

`portable: yes`
