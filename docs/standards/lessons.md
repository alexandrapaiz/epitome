<!-- vendored-from: standards/lessons.md @ 775ce369c76dc04b45d0aa19e6fdf45969e13718 -->
> **Vendored copy — do not edit here.** Source of truth is
> `alexandrapaiz/alexandra-systems` `standards/lessons.md` at commit `775ce36`,
> vendored 2026-09-28. Changes to a company standard are HQ
> ADRs (standards/README.md). Deviations for this product belong in this
> repo's own decisions file, not in this copy.
<!-- end vendored header -->

# Company Lessons Register

The owner's corrections, generalized into standing law and distributed
to every product. Maintained ONLY by the exo centralizer
(prompts/exo-centralizer.md); products receive it as a vendored copy at
`docs/standards/lessons.md` via autonomous sync PRs. Every seat in
every product reads its role's section before working. Sources: each
product's `docs/agents/lessons.md` entries marked `portable: yes`, and,
for products that keep no such file, the `portable`-shaped rulings in
`docs/agents/learning-log.md` and `docs/agents/incidents.md`. Rule IDs
are permanent once distributed: a renumbering is recorded here with its
old ID, never done silently.

Format: rule, then provenance (product, date, owner's words where
captured).

**Where a new lesson goes, and who issues its ID.** The centralizer is
not the only author who reaches this file. Between harvests the owner
and the chair land rulings here directly, which is correct, because a
ruling should not wait a week for a seat to run. What cannot work is
those entries picking their own rule ID. Between 2026-09-23 and
2026-09-25 four such commits added five entries, and two of them reused
IDs that were already live in five repositories (see L-A18, which now
carries this as its second source). A counter in a file is not an
allocator when more than one author can write between merges.

So: **anyone may append to the inbox at the bottom of this file, and only
the centralizer issues a rule ID.** An inbox entry needs a title, a
date, the role or roles it binds, and the rule in plain sentences. No
`L-` identifier. The next harvest generalizes it, gives it an ID, files
it under its role section, and empties the inbox. Nothing in the inbox
is law yet, and nothing cites an inbox entry, so nothing breaks when the
ID it eventually gets is not the one its author would have chosen.

## any (all seats, all products)

- **L-A1 — Mechanism over marketing-speak.** Explain by naming the
  actual mechanism; never gloss. (epitome L1, 2026-09-18: owner
  rejected marketing language in technical artifacts.)
- **L-A2 — "Architecture" means system design.** When the owner asks
  for architecture, she means components, data flow, and boundaries,
  not vision prose. (epitome L2, 2026-09-18.)
- **L-A3 — "Comprehensive" means an engineer could start from it.**
  A comprehensive document is one a fresh engineer could execute
  without asking questions. (epitome L3, 2026-09-18.)
- **L-A4 — A repeated correction is a register defect.** If the owner
  corrects the same thing twice, the failure belongs to this register
  and the charter that failed to bind it, not to the artifact.
  (epitome L4, 2026-09-18.)
- **L-A5 — House voice in owner-facing prose.** Plain sentences,
  transition words, no stylistic em dashes, no semicolon joins, no
  flourish. (alexandria house rule; owner-set, portfolio-wide.)
- **L-A6 — Judge a run by its artifacts, never its conclusion.**
  (alexandria incidents 8 and 11.)
- **L-A7 — Exemplar first, feedback loop second.** When the owner has
  approved an artifact of the same genre anywhere in the portfolio, a
  new artifact starts from reading that exemplar in full, before the
  first draft; iterating on described feedback converges on the
  description, never on what she approved. The known exemplar for
  plans and their decks: Ursa docs/design/product-plan.md and
  docs/presentations/product-plan/. (epitome incident 1, 2026-09-19:
  "highly dissatisfied with the presentation still we will abandon for
  now. ursa did a much better job" — five revisions each fixed the
  named gap and the artifact was abandoned anyway.)
- **L-A8 — Presentations: seat-authored content, alexandria register,
  direction at the end.** A presentation belongs to the seat whose
  work it presents: that seat authors the content document in Copy /
  Speaker notes / Visual direction form and the chair renders, never
  authors. Copy is one declarative statement or one real quote per
  slide, jargon-free (ADR numbers, tier names, protocol verbs live in
  notes only), sources cited in notes by file-line or link,
  confidence levels carried into the Copy; the deck ends with
  recommendations the owner can accept or reject one by one. The
  named portfolio exemplar for presentations is alexandria
  docs/sales/pitch-deck.md — the durable rule is render the exemplar
  the owner loves, because this is the fourth register correction and
  each prior fix encoded the previous failure instead of that
  exemplar. (epitome L8, 2026-09-19: "i am big fan of alexandria
  presentations, i hate almost all presentations by epitome"; full
  verbatim quote in epitome L8; codified in documents.md §2b and
  checklist items 10-12.)
- **L-A9 — Recording a rule is not enforcing it.** A ruling written to
  a register changes nothing by itself. Whoever produces an artifact
  checks it against the governing register line by line before the
  artifact reaches the owner, and that check is the first gate in the
  producing seat's own grading, never a later review step. (alexandria
  incident 20, 2026-09-19: a heading ruling was recorded in
  docs/voice/taste.md the same hour it was given, the next sample
  still printed the banned framework labels, and the owner had to
  repeat herself with "AGAIN". Companion to L-A4 and L-X1: L-A4 names
  the repeat as a register defect, L-X1 closes the loop in the tree,
  and this rule places the check before delivery.)
- **L-A10 — One file, one owning charter.** Every file a seat writes
  names exactly one owning charter. When two seats need the same file,
  it is split by named section with an owner recorded in both charters.
  A seat that finds itself in contested territory yields and files the
  conflict rather than winning the race. (Atelier L3, 2026-09-19,
  `portable: yes`: prompts/pm-agent.md and prompts/exo-agent.md both
  told their seat to write docs/agents/pending.md and both seats did so
  within the same hour of their first runs.)
- **L-A11 — A defect that recurs across products belongs to HQ.**
  L-A4 makes a repeated correction a register defect inside one
  product. One level up: when the same defect appears in a second
  product, the fix is owed to this register and to the standard it
  governs, not to the second product's copy. Fixing it per product a
  second time is the same failure L-A4 names. (epitome L5, 2026-09-19,
  owner on a presentation carrying a defect already corrected in Ursa:
  "i believe alexandra sys. company should be doing agent hqs because i
  have the same dissatisfaction with this presenattion." This rule is
  the centralizer's own reason for existing, and HQ incident 1 is the
  case where its absence cost her the same correction twice.)
- **L-A12 — Verify location before asserting it.** Where a thing is
  deployed, stored, or logged in is checked by looking (a listing, a
  screenshot, an API call), never inferred from memory or elimination.
  (HQ ADR-018 correction, 2026-09-19: the chair stated the alexandria
  site was on the Columbia Vercel account. It was not. Renumbered from
  L-A9 on 2026-09-20: two different rules had been given that ID.)
- **L-A13 — All hands on deck in synchronous mode.** Owner, 2026-09-20:
  "I want all hands on deck during synchronous sessions... working on
  a cloud or VM not necessarily on my device, but I want them working
  when I am." Rule: a chair session with the owner begins with the
  all-hands dispatch (tools/all-hands.sh) for the scope she is working
  in, seats run on cloud runners, and the chair converts her words
  into follow-up dispatches. standards/operating-modes.md. (Renumbered from
  L-A10 on 2026-09-20, and moved out of the marketing section it was
  filed under by mistake.)
- **L-A14 — A rule that forbids an outcome ships the safe form beside
  it.** A prohibition tells a seat what not to do and leaves it to
  invent the mechanics, and the obvious-looking invention is often the
  forbidden thing. Every register rule that bans an outcome carries the
  literal command, snippet, or procedure that achieves the goal safely,
  so following the rule is copying rather than composing. (HQ incident
  4, 2026-09-20: L-X5 banned printing a secret's value on 2026-09-19,
  was read and believed by the next run, and that run printed the token
  anyway, because `${VAR:-default}` expands to the value whenever the
  variable is set. The rule had no snippet. It has one now.)
- **L-A15 — Formatting instructions govern rendering, never the
  content floor.** A brief that asks for terse slides, bare-noun
  titles, or a short table changes how an artifact is presented and
  cannot lower what it must contain. A presentation is a view of the
  deliverable, never a substitute for it, so the content requirements
  in the governing standard survive every instruction about form,
  including one from the chair or the owner's own shorthand. A seat
  given a formatting brief that would breach the content floor ships
  both: the artifact at full depth, and the requested view of it.
  (Ursa incident 3, 2026-09-18/19: the engineer seat had a real plan
  in docs/design/product-plan.md, the chair's brief commissioned
  2-to-3-word titles and terse cells, the rendered deck dropped every
  interface, path and command, and the owner rejected it as "just
  buzzwords and it's not a plan". Companion to L-A8, which governs who
  authors a presentation, and this one governs what a brief can take
  away.)

- **L-A16 — Configured is not in effect.** A capability counts as live
  only when a run log, a listing, or a response proves it served a real
  turn. Configuration states intent, and the gap between intent and
  effect is silent by construction, because a well-built fallback makes
  the run succeed anyway. A decision that is accepted but not active is
  recorded as dormant in the product's decisions file, with what would
  turn it on. Silence does not close the gap. (Atelier incident I2,
  2026-09-19: commit 89bbf8e routed the pm seat to an open model, run
  35463415653 skipped the open-routed step because `OPENROUTE_API_KEY`
  was unset, the Claude fallback served the run, and the log's
  `modelUsage` showed `claude-haiku-4-5-20251001` and `claude-sonnet-5`.
  Reading the workflow alone would have told you the seat ran on an open
  model. Companion to L-A12, which checks location by looking, and to
  L-X3, which asserts models from run logs.)
- **L-A17 — A failure whose diagnosis took more than a minute gets an
  entry.** L-A4 covers the correction that repeats. This one covers the
  first occurrence that was diagnosed and fixed so fast it felt too
  small to write down, which is the kind that gets rediscovered. The
  entry is owed whether or not the failure repeats, and whether or not
  it is already fixed in the tree. A fix that lives only in one
  session's memory is a fix the org has not learned. Writing it down
  costs five minutes once and rediscovering it costs a run. (alexandria,
  2026-09-19, the containerization postmortem: the chair diagnosed and
  fixed two environment-migration failures between 01:54 and 02:14 UTC,
  shipped on, and recorded neither, and the owner asked for them to be
  registered properly.)
- **L-A18 — An identifier comes from the register's own tail, and a
  register that cites a record contains it.** Two integrity failures,
  both cheap to prevent and expensive to find later. First, a seat
  appending to a register reads its tail and takes the next free
  identifier, because a reused ID is two rules answering to one name
  with no way to tell which a charter meant. A collision already
  shipped is repaired by renumbering the newer entry, with the old ID
  recorded in the survivor, never silently. Second, a rule cites only
  records reachable where it says they are. A citation pointing into an
  unmerged branch reads as evidence and is not one. (Ursa learning log,
  2026-09-19, which flagged its Incident 3 colliding with the inherited
  "Incident 3, the ship-first rule" and asked for a rename before a
  third collision. The same defect at HQ in the same week: L-A9 was
  issued three times, and HQ's incident register runs 1, 2, 3, 5 while
  L-A14 cites incident 4, whose record is still sitting in unmerged HQ
  PR #15. Two products, one defect, so the fix is owed here under
  L-A11.)

  **Amended 2026-09-28, and this half matters more than the half above.**
  Reading the tail is the right instruction and it is not sufficient,
  because two seats reading the same tail at the same time take the same
  number. The org keeps two kinds of identifier and had been treating
  them the same. An id read only by the run that wrote it may be
  sequential. **An id that other artifacts cite has to be allocatable
  without coordination, because the seats cannot coordinate by
  construction: they never message each other and each one sees a
  different snapshot of the repository.** A sequential counter in a file
  is not an allocator under those conditions, it is a collision
  generator, and it fires on every window where two authors register
  something between merges. The form that needs no allocator is
  `INC-YYYY-MM-DD-slug`, or any scheme whose uniqueness comes from the
  date and the subject rather than from a count. Identifiers already
  issued are permanent, and the scheme changes for new ones only. Where a
  central register must keep a short sequential ID because charters cite
  it, as this file does, the fix is instead to make one author the only
  issuer and give everyone else an unnumbered inbox, per the preamble.

  **Third clause: an identifier cited across repositories carries its
  legislature.** This company has two bodies that number things and both
  are cited as bare numbers. alexandria's own ADRs stop at 32 and HQ
  numbers ADR-033, and a reader of "ADR-15" in a product repo cannot tell
  which one is meant. Cite `HQ ADR-015` or `alexandria ADR-15`, never
  the number alone, in any file that is read from more than one repo.
  (Second source for all three clauses: alexandria incident 29,
  2026-09-24, where the exo seat and the chair wrote incidents 23 and 24
  for different events three days apart, both correct when written. The
  file then turned out to already hold two 19s, two 20s and two 22s from
  three earlier merges that nobody had registered. Third source, HQ's
  own, 2026-09-28: HQ's incident register now runs 1, 2, 3, 4, 5, 6, 3,
  4, 5 and this register had shipped `L-K3` and `L-E6` twice each to
  three products. The "where to look next" the alexandria entry left for
  its successor was the ADR numbering, and it was right.)
- **L-A19 — A status line is not communication.** The owner's window
  into a company cannot be one line per run with a link, because she
  reads that as silence. A report is prose and it opens the pull
  request. A PM speaks in the first person about what it plans, what it
  dispatched and what it needs answered, and the channel carries
  traffic in both directions. The test is not whether a message was
  sent. It is whether the owner would call what happened a
  conversation. (HQ, 2026-09-26, the owner on the Slack run reports.
  **Renumbered from L-V1 on 2026-09-28**, which used a section prefix
  no section owns. The rule is unchanged and no file anywhere cited the
  old ID.)
- **L-A20 — A parent decision governs, and it does not take effect
  silently.** HQ decides for the portfolio and a product does not get
  to refuse. Precedence is not the problem, and a veto in the subsidiary
  would be the wrong fix. What the subsidiary is owed is notice, and
  notice has a definition. One, an HQ decision that changes anything
  inside a product lands with a record inside that product: a vendored
  copy, or one entry in the product's own decisions file naming the HQ
  ADR, the local files it changes and the local law it touches. A
  commit subject is not a record, because nothing reads commit
  subjects. Two, where the decision overrides a local law, the override
  is written into that local law's own file, not into a changelog.
  Three, and this is the clause to keep if the rest is cut, **a local
  law's preconditions survive an override unless the override names
  them.** A safety clause that can be dropped by not being mentioned
  is not a clause. Four, the seats whose behaviour changes are told in
  their charter or in a file their charter already reads. Five, the
  relay runs both ways: a subsidiary's incident that is evidence about
  a parent decision goes up. None of this is an approval step and none
  of it lets a product delay anything. Every obligation is to write
  something down where the seats already look. (alexandria incident 23
  and docs/agents/cross-repo-law.md, 2026-09-24, owner-ordered: HQ
  ADR-015 routed four alexandria seats to an open model by direct
  commit to that repo's workflows. alexandria's routing law requires a
  golden-set comparison before any seat changes model. The comparison
  was not overruled, it was not seen, because the decision was made
  where the law was not visible and the only record inside the product
  was a commit subject. Both PM runs then failed and the seat that owns
  the routing register found out three days later by reading its own
  file on schedule. alexandria offered the rule upward as a candidate
  for the standards set, and this is HQ accepting it. The four propagation
  shapes are in that file, and the dangerous one is the direct commit,
  dangerous in proportion to how cleanly it is made.)
- **L-A21 — A gate is judged by what it can see, and a gate that saw
  nothing is a failure rather than a quiet pass.** Two ways a gate
  reports success while protecting nothing, and both were live in the
  same week. First, **its scope is narrower than its subject**: a law
  can fire on schedule, pass its own audit, and miss, because it is
  pointed at the wrong place. The test to run on every gate is
  concrete. Name one change that would break what this gate governs,
  then ask whether the gate would have *seen* that change, not whether
  it would have fired on it. Second, **it ran against no input**: a
  check that examined nothing and a check that examined everything and
  found nothing look identical from outside, and by default every tool
  reports them the same way. A run that collected fewer items than the
  last run is a failure, not a quieter success, and every gate is
  tested against an artifact known to fail it before the gate is
  trusted. (alexandria, 2026-09-24, two incidents. The scope half:
  docs/agents/runtime-changes.md made smoke-testing law, but its "what
  counts as a runtime change" list was written the week the org
  containerized, the exo and engineer audits that enforce it diffed
  `.github/` only, and a provider swap lands in `pipeline/`, so the
  largest runtime change the org makes was invisible to both gates, and
  every cell of that register's row was accurate. The blind-pass half:
  INC-2026-09-24-test-suite-ran-zero-tests, where a pytest collection
  error stopped the suite at zero tests run and reported it as `1
  error` on one line, hiding a test that had been failing for an
  unrecoverable length of time. The CI-shaped path was green because it
  ran the files one at a time and nothing ever ran the suite. Same
  asymmetry under alexandria incident 32, where a quality gate returned
  `0 blocking` on an issue it could not parse.)
- **L-A22 — The gate goes in the command, not in the charter.** A rule
  enforced by a sentence in a charter is enforced at the reliability of
  a model reading a file. A rule enforced by a link in a command is
  enforced at the reliability of a shell. When a law has failed to fire
  once, writing it more clearly is not the fix. The fix is to find the
  command that already runs and add the check to it, as another link in
  the `&&` chain, so there is no way to forget it and no charter text
  involved. Where that is impossible, say so plainly and record the
  rule as enforced at the reliability of reading. (alexandria,
  2026-09-24, the fourth occurrence of L-A9 in one week and the entry's
  own closing sentence: of ten rows in that product's register map,
  nine are enforced by charter text and one by an `&&` chain the chair
  runs before a deploy, and the one enforced by the chain is the one
  that has never broken. The press's chain already asked whether the
  request fits and whether the model exists. The question it was
  missing, does one real call work, is one more link.)
- **L-A23 — A prohibition must not quote the banned specimen where the
  work is written.** L-A14 says a rule forbidding an outcome ships the
  safe form beside it. This is the other half, and it is the one that
  bites: read the instruction from the position of whoever obeys it,
  and **if the nearest quoted example at that position is the thing
  being banned, the prohibition is a supply.** Rejected specimens are
  worth keeping, and in this company they are the product of whole
  sessions of the owner's corrections, but they belong in the gate
  that reads the output, never in the prompt, checklist or charter
  section next to the blank where the work goes. State the rule
  positively at the point of writing and hold the specimens at the
  point of reading. (alexandria
  INC-2026-09-24-prohibition-supplies-the-string, 2026-09-24: a banned
  internal framework name was printed verbatim as a subscriber-facing
  heading for the third time. The rule was recorded in five places and
  a gate asking the right question was running. A sixth recording, the
  prohibition itself quoting the four banned names inside the heading
  prompt, was working against the other five, and the unpatched
  generator had produced the correct heading eleven hours earlier.)
- **L-A24 — Health is measured on the thing the company ships, and
  where a scheduler and an artifact disagree the artifact wins.** Every
  run-health duty written from a seat's point of view reads `gh run
  list`, which covers the agent workflows and none of the products. A
  cron, a static deploy, a hosted server and a scheduled job are all
  outside it, so the org can be green everywhere and shipping nothing.
  Two consequences. First, when hunting for unowned duties, **grep the
  charters for the vocabulary of what the org sells, not only for the
  vocabulary of the duty.** "Run health" finds an owner instantly.
  "Issue", "digest" and "reader" in a monitoring sense find nobody.
  Second, availability checks, fallback lists and failure alarms all
  tell you a run failed and none of them tells you a run never
  happened. Only an outside observer reading the artifact catches the
  missing run, because a scheduler reports its own intentions.
  (alexandria incident 24, 2026-09-24: the weekly press failed three
  times in five days, the owner found out from her own inbox three days
  late, and every health report the org produced that week was
  accurate. The Modal app left no log at all for 2026-09-21, and a job
  that never starts cannot notify anybody. Confirmed the same evening
  in the other direction: every GitHub Actions run on 2026-09-24 was
  green while the press failed four times, so `gh run list` was
  accurate and useless. Guardrails: alexandria
  docs/agents/delivery-health.md.)
- **L-A25 — A register of rejections cannot converge, so taste needs a
  positive specification.** A taste register made almost entirely of
  "no" improves the work every round and never closes the distance to
  shipping, and that is arithmetic rather than taste: each rejection
  removes one candidate from an unbounded space. Before a seat drafts
  against a taste register, one artifact has to exist saying what the
  thing is *for* and what it is worth to the person receiving it, and
  that artifact carries the owner's approval. Two supporting rules from
  the same failure. Drafting happens in a file, never in chat, because
  a round that leaves no file cannot be read by the next round.
  And the record is appended one line per candidate while the session
  is live, because a session written up afterwards loses the exact
  sentences she rejected, which were the whole point of recording it.
  (alexandria incident 27 and the 2026-09-21 exo entry, from the
  owner's site-copy session of 2026-09-20: eight rounds, twenty-two
  candidates, four approved lines, the register moving from explanatory
  to selling to quiet to friendly to flat without converging. Her
  diagnosis of the last round: "its describing the mechanism not what
  it delivers. or the value to a builder", and "no mention of a growing
  self mantaining corpus, nothing. thats my point." Roughly forty
  rulings sat in that product's taste register and nearly all were
  rejections, and nothing in the repository said what the product was worth
  to a builder. Two of the eight rounds have no recoverable candidate
  text at all. Process: alexandria docs/agents/copy-pipeline.md.)

## engineer

- **L-E0 — The bar is Omarchy or higher.** Owner, 2026-09-20: "high
  grade engineering level. omarchy standard of engineering or higher."
  Rule: opinionated defaults with escape hatches; one command to a
  working state; consistency across every surface; agents as
  first-class citizens of anything we build (they can read its state,
  diagnose it, extend it); professional maintenance. A deliverable
  that would embarrass Omarchy's maintainers is not done. The bar does
  not bend to the audience. Owner again on epitome, 2026-09-20: "epito
  isnt supposed to be only vibecoders at the loveable level. i want a
  true piece of engineering... most porgrammers today are vibecoders. i
  want something on the level of omarchy." So "vibecoder-friendly"
  names who the product is for, which is most programmers now, and
  never a lower standard of what it is. Every abstraction is
  explainable by pointing at the real mechanism beneath it, specs are
  written to be implemented by someone else, and first-run ease is the
  output of craft rather than of omission. Binds engineer and pm seats
  portfolio-wide, and most sharply when a product is described as being
  for vibecoders or indie builders. (Two sources, one rule: HQ
  vision.md §0, 2026-09-20, and epitome vision §0b with ADR-14,
  2026-09-20. The epitome half was filed at HQ on 2026-09-20 as a
  second L-A9, an ID already spent twice. Merged here and that
  duplicate retired, per L-A18. It had reached no product, so no
  vendored copy carried it.)

- **L-E1 — No UI annotations.** Never append explanatory subtitles to
  headings in her interfaces: bare nouns, units in note slots.
  (owner law, portfolio-wide, predates the company.)
- **L-E2 — Real files, real commands, real tradeoffs.** Technical
  artifacts show actual paths, commands, and the tradeoff taken, never
  process-speak. (owner correction pattern, 2026-09.)
- **L-E3 — Ship first, then work.** Draft PR in the first turns, commit
  as you go; a died run must still ship its partial work. (alexandria
  incident 3; encoded in standards/workflow-template.yml.)
- **L-E4 — Systems architecture covers the full stack, and the
  connective stack is part of it.** A product's systems architecture
  means "actually everything from infrastructure to data storage to
  cloud to containers," with actual named tooling proposals, and it
  includes distribution, because "distribution is a part of
  engineering": the integrations (Vercel, Supabase, Clerk, Linear,
  Claude, OpenAI, and the rest of the stack) are mapped as both system
  components and distribution surfaces — the stack you build on is
  the stack you distribute through. Full requirements:
  standards/engineering-artifacts.md items 7 and 8. (Owner fine-tune,
  taught once pre-HQ, re-taught 2026-09-19 on epitome; full verbatim
  quote in engineering-artifacts.md provenance and epitome L6; HQ
  incident 1.)
- **L-E5 — A plan is grounded in one real case with real numbers.**
  What separates the approved Ursa plan from the abandoned epito one,
  beyond the standard's letter: a single real dogfood case threaded
  through every section, actual payloads from a real run ("no
  invented figure"), verbatim user quotes as evidence, a "Done when
  <observable event>" condition on every milestone, and diagrams
  specified node by node with typed edge labels. Schemas with no
  filled example and phases with no done-condition read as marketing
  no matter how many tables surround them. (Ursa
  docs/design/product-plan.md §4/§5/§11 vs epitome
  docs/architecture.md, 2026-09-19; the abandoned artifact literally
  missed engineering-artifacts.md requirements 1 and 3 — the standard
  needed adherence, not amendment.)
- **L-E6 — A quality law that inflates a runtime input is measured
  against the runtime budget.** When one seat authors the text a
  pipeline feeds to a model (a prompt, a template, an editorial
  standard) and another seat runs that pipeline, the two share a limit
  that neither owns by default: the authored text plus a worst-case
  payload must fit the runtime model's request limit with margin, and
  that fit is measured in CI or at deploy, never assumed. A merge that
  improves quality and breaks the press is a failed merge. (alexandria
  incident 22, 2026-09-19: a day of editorial work grew
  prompts/digest.md from 223 to 509 lines, the next autonomous
  generator run got 413 Payload Too Large from Groq, and no issue was
  written. The writer seat set the rules, the engineer seat ran them,
  and the shared constraint had no owner.)
- **L-E7 — Open routing is best-effort; the subscription is the
  floor.** A seat workflow's open-routed step carries
  `continue-on-error: true` and an `id`, and the Claude step runs when
  that step did not succeed. Never let a cheap provider's concurrency
  ceiling cost a run. A cheap provider with a concurrency ceiling is a
  single-lane road: serialize the traffic company-wide, or build the
  detour into every driver. We could not serialize across
  repositories, so every workflow carries the detour. Corollary worth
  memorizing as a fingerprint: a run that ends `is_error` at about one
  turn and about three minutes on an open model is this failure until
  proven otherwise, so check what else was running. (HQ incident 4,
  2026-09-21 and 2026-09-24: three Kimi-routed PM runs across two
  repositories died at turn one, only ever with another Kimi run in
  progress, and the provider's own words in the 09-24 alarm were "request
  reached max organization concurrency: 1". Fixed in all 15 routed
  workflows across five repos. **Renumbered from L-K3 on 2026-09-28**:
  that ID was already live as the marketing rule on public copy, and
  had been distributed to three products twice over. The rule is
  unchanged and no file anywhere cited the old ID.)
- **L-E8 — A fallback step needs `continue-on-error`, and a no-ship
  tripwire counts commits rather than remote branches.** Three defects,
  one failed run. First, a "try the open route, fall back to Claude"
  pair only works when the first step carries `continue-on-error: true`
  and an `id`. Without them the job dies at the failed step, the
  fallback is skipped, and the seat produces nothing while both paths
  look configured. Second, a tripwire that tests `git branch -r
  --contains HEAD` passes trivially when the run never branched,
  because HEAD is still `origin/<base>`, so it must count commits ahead of
  the base branch, exclude the base from the pushed check, and fail a
  run that made no commit, no seat branch and no PR. Third,
  operational: keep a paid route behind a repo variable
  (`OPEN_ROUTING`), never behind the presence of its secret, so
  switching it off costs a flag rather than deleting a key. Binds
  engineer seats and anyone editing the workflow template. (epitome pm
  run 35956231272, 2026-09-24, where four consecutive Kimi attempts
  each burned about three minutes before falling back; epitome and HQ
  workflow commits 2026-09-25; HQ incident 4. **Renumbered from L-E6 on
  2026-09-28**, which was already live as the quality-law-versus-
  runtime-budget rule above and had been distributed to three products
  twice over. The rule is unchanged and no file anywhere cited the old
  ID. Note the overlap with L-E7, which is the same first defect stated
  as policy. This rule is the implementation, and its second and third
  clauses are its own.)
- **L-E9 — Connecting a repo to a host is finished when one build has
  run end to end, and the metered unit is counted first.** Two
  questions before the connection is called done. Does a real build
  complete, verified by watching one rather than by the host reporting
  the repository as connected, because a wrong root directory or a wrong
  framework guess fails in seconds and the live site keeps serving the
  last good deployment, so nothing looks down. And what does this host
  actually meter. A free tier's unit of consumption is rarely the one
  you think about, an agent company produces that unit at a rate no
  human team does, and the branch that ships should be the only branch
  connected. One more reading rule for both: a failure email that
  repeats on every push is one bug, not many, so count distinct causes
  before counting mails. (HQ incidents 3 and 5 of 2026-09-20 through
  2026-09-25, both against alexandria's Vercel project and both
  portable by their own registers. The first: root directory left at
  `.` when the Next.js app lives in `site/`, so every git-triggered
  build failed for six seconds for three days, five production builds
  and every seat branch's preview, and the owner read the resulting
  mail as "lots of failed runs throughout the companies". The second:
  the Hobby plan creates a deployment per push per branch and allows
  100 a day, and a 16-PR merge pass on top of a day of seat-branch
  pushes crossed the line at 04:55Z, after which every deployment
  including production was refused for 24 hours. Fixed by disabling
  branch deploys and firing a deploy hook only on pushes to `main` that
  touch the site.)

- *Pending harvest: the owner reports substantial engineer corrections
  in Ursa chair sessions not yet captured in any register (partially
  harvested: Incident 3 → engineering-artifacts.md, L-E4, L-E5). First
  centralizer task: finish the harvest with the owner.*

## pm

- **L-P1 — Product outranks plumbing.** When triage competes, the
  product-facing item wins; plumbing serves shipping. (alexandria
  incident 12 / ADR-26.)
- **L-P2 — Respect lived-in documents.** Where a product already has a
  working planning artifact (Atelier's SPRINTS.md), the seat adopts its
  format and voice; the standard bends, recorded as a deviation.
  (Atelier bootstrap, 2026-09-19.)

- **L-P3 — The PM seat must relieve the owner, not just run
  ceremonies.** Owner, 2026-09-19: "pm feels quite dormant across all
  the projects. im basically doing its job in the creative direction
  and synchronous agent guidance aspect." Rule: a PM seat's output is
  measured by owner relief — it prepares direction as choices (decision
  memos, options with a recommendation, briefs before she has to
  think), and it carries synchronous-mode guidance of working agents
  (orientation notes, mid-sprint steering) rather than leaving that to
  the owner by default. Async ceremonies alone do not discharge the
  seat. (Portfolio-wide observation; charters due for revision against
  this rule.) Owner again, 2026-09-20: "I felt the PMs were very
  underactive in the synchronous sessions. But it might just be that I
  have no visibility on what's going on since there's no like chat
  place." The visibility feed is the instrument that tests which it is;
  in synchronous mode the PM is the owner's operating partner
  (operating-modes.md).

- **L-P4 — Purchases wait on the worthiness gate.** Spending queues
  behind the owner's judgment that the product has earned it, carried
  as a dependency chain, never as a dated task. No seat schedules her
  money. (Atelier L1, 2026-09-19: "the $99 waits for the product to
  earn it".)

- **L-P5 — Working Backwards is a PM duty, not a suggestion.** Owner,
  2026-09-20: "i want pm agents to all implement that." Rule: nothing
  larger than a sprint item enters a sprint until its PR/FAQ
  (docs/prfaq/<slug>.md: launch-day press release, customer FAQ,
  internal FAQ) exists and the owner has merged it; if the press
  release is not compelling, revise the document, not the roadmap.
  Full procedure: standards/pm.md §2c.
- **L-P6 — Presence is a cadence, not a duty.** Between a seat's runs
  the owner is the only actor present, so every gap in the schedule
  lands on her. A PM that runs daily, reads state and dispatches
  against written criteria removes that default. A PM that runs weekly
  cannot, no matter what its charter says it does. The second half is
  about how this was found. The premise that had blocked daily
  dispatch, "a run's token cannot start a run", was a misreading of
  the rule, and it had been designed around rather than tested. **Test
  the mechanism with a two-line probe before designing around a
  limitation.** (HQ, 2026-09-23, the dispatch probe and ADR-033. The
  cadence half is L-X6 stated from the PM's side, and the probe half is
  the new part.)
- **L-P7 — In sync mode the PM directs and the owner steers through
  it.** A rule written to stop two dispatchers racing, "never dispatch
  while the owner is present", made every PM passive at exactly the
  moment the owner was there, and she ended up prompting seats herself.
  Sync mode means the chair opens the PM windows first, relays her
  words to the PMs as agenda and as messages, and the PMs dispatch
  under their ceilings. The chair's job in sync mode is to direct the
  PMs, not the seats. Binds pm and chair. (HQ, 2026-09-26; pm.md §11.4
  as amended, and standards/operating-modes.md. Companion to L-A13,
  which says what synchronous mode is, and to L-P3, which says the PM
  seat exists to relieve her.)

## okr

- **L-O1 — A declared scope is scored by a real query from a real user,
  and the portfolio supplies the first ones.** Coverage measured against
  internal counts measures the pipeline, not the promise. The score that
  counts is what a genuine user with a genuine question got back, and in
  this portfolio the nearest genuine user is a sibling product's seat. A
  failure of that kind enters the next grading as a named baseline case,
  not as a support ticket. Detection that worked only because the owner
  relayed it is a detection failure, the same finding L-R1 names for
  research territory. (alexandria incident 21, 2026-09-19,
  owner-reported: an epitome session ran two semantic searches over the
  claim corpus for agent identity, portability and credential security,
  all inside scope alexandria had declared on 2026-09-18, got a best
  match of 0.69 on unrelated papers, recorded "alexandria: searched, not
  useful for this" and went to plain web research instead. The owner:
  "remember the okr mission. we are not achieving it.")

## mba

- **L-M1 — Frameworks are applied with real inputs or not at all.** A
  canvas of adjectives is a failed artifact; every cell carries a fact
  or an explicit unknown with how to find out. (Chair, from the owner's
  documents and engineering-artifact standards, 2026-09-20.)
- **L-M2 — Hold the canon and the owner's Austrian lens together.**
  Apply the framework, then say where subjective value, entrepreneurial
  discovery, dispersed knowledge, or uncertainty changes the answer.
  (Owner worldview, standing.)

- **L-M3 — Decks are consulting-grade or not shipped.** Ghost deck
  first; answer on page one in SCR form; MECE reasons; action titles
  that read as the storyline; a source under every number; the
  six-question pre-ship test in the PR (standards/consulting-decks.md).
  (Owner directive 2026-09-20: "pulling from standards like mckinsey
  or bcg.")

- **L-M4 — The MBA seat is a voice in the room, never the verdict.**
  Owner, 2026-09-20: "mba is not final authority, it is merely a voice
  in the room. i am cautious with mbas due to outdatedness, but may
  still be usefull sometimes." Rule: nothing the seat writes binds a
  decision; dissent is recorded, never obeyed. For every framework
  applied, name which of its assumptions are stale for an AI-native,
  agent-run, one-owner company; when canon and the company's record
  disagree, the record wins.

## yc

- **L-Y1 — A voice in the room, never the verdict.** Same ceiling as
  the MBA seat (L-M4). Dissent recorded, not obeyed.
- **L-Y2 — Name the canon's blind spots every time.** Survivorship
  bias, Silicon Valley provincialism, venture-path assumptions: say
  which YC rule applies to a bootstrapped one-owner company in
  Guatemala and which does not, and why. (Chair, 2026-09-20.)
- **L-Y3 — Honest take, never programmed disagreement.** Owner,
  2026-09-20: "it shouldnt be programmed to challenge though. just give
  its honest take, even if it disagrees." Rule: the YC seat states
  where it lands on each MBA case and why; agreement is a finding,
  manufactured contrarianism is a defect. Applies symmetrically to the
  MBA seat's response.

## distribution

- **L-D1 — Distribution is a business angle for every product.** Owner,
  2026-09-20: "for all my products, I want a business angle to be
  distribution. Especially in the coding spaces." Rule: every product's
  distribution map exists and ranks GitHub discoverability, MCP
  presence on Claude and Codex, and the vibe-coding stack first;
  zero-listing-bar shelves ship before anything needing approval.
- **L-D2 — Prepare, never submit.** Listings, directory submissions,
  awesome-list PRs, launch posts: prepared to the last field; the owner
  submits. Agents never create accounts, post, or contact anyone.

- **L-D3 — Agents go where agents are allowed to live.** Owner,
  2026-09-20: "all apps that have a place for 'apps' or agentic or any
  integration, we can work agents in." Rule: the shelves registry
  carries agent shelves (platforms where an agent can be a principal),
  ranked with evidence; epitome-minted agents and company seats are
  the deployments. LangGraph is a runtime target and a shelf, not the
  org layer for seats (a seat is an employee, not a flowchart).

## marketing

- **L-K1 — Publishing is the owner's authority until she grants it.**
  Three modes (prepare-only, scheduled-with-approval,
  autonomous-within-merged-campaign); the default is prepare-only.
- **L-K2 — Real product surfaces only.** No fabricated screenshots or
  invented numbers in any post; the house voice holds on TikTok.

- **L-K3 — Public copy is plain, serious, and sells the outcome.** Four
  rules from the owner's line-by-line verdicts on the alexandria site,
  binding on every seat that writes public-surface copy, which includes
  the writer, frontend, marketing and sales seats. One, plain short
  sentences. Her words: "avoid sentence structures with lots of commas".
  Two, the register is serious. Cute asides, diminutives and colon-led
  constructions read as "millenial/condescending/unserious/vibecoded"
  and are rejected on sight. Three, "no more technical. we want to
  sell": public copy states the outcome and does not explain the
  mechanism. Four, every line reaches her in chat before it is set on
  the surface, and a taste ruling is dated, so the newest verdict
  governs even when it reverses an approval she gave the day before.
  The scope boundary matters: this rule governs public sales surfaces
  only. Inside technical and owner-facing artifacts L-A1 and L-E2 still
  hold, and there the mechanism is the deliverable. (alexandria
  docs/voice/taste.md, round-one site verdicts recorded 2026-09-20:
  three lines approved, five rejected with reasons, including the
  reversal of "One library, two readers." which she had approved on
  2026-09-19.)

## exo

- **L-X1 — Implement, don't archive.** An incident is closed when the
  fix is in the tree, never when it is written down. (alexandria
  incident 13.)
- **L-X2 — Secret first, schedules last.** No cron until the seat
  passes a supervised dispatch with a verified token. (Ursa incident 1:
  scheduled seats with an invalid token produced 0 successful runs.)
- **L-X3 — Caps from evidence, and only from representative
  evidence.** Turn caps at 2× highest observed `num_turns`, floor 100;
  models asserted from run logs' `modelUsage`, never from config
  intent. The evidence only counts when the run executed the seat's
  full duties. A smoke run's `num_turns` shows that the plumbing works
  and nothing more, so it never lowers a cap; until a representative
  run exists the cap stands untouched and the PR says plainly that it
  rests on no evidence yet. (alexandria incidents 9 and 10 for the
  rule; Atelier L2, 2026-09-19, `portable: yes`, for the
  qualification: run 35463415653 was a pm smoke run reporting
  `num_turns` 13, and applying the rule literally would have cut pm and
  exo from 120 to the floor on the strength of a run that did no pm
  work. Amended 2026-09-28 with the symmetric clause the rule was
  missing: **a run that failed for any reason other than hitting the
  cap contributes nothing to the table, in either direction.** The
  first clause covers a run censored high by the cap. Nothing covered a
  run censored low by dying early, and alexandria's two PM failures at
  turn 1 and turn 30 would have argued for cutting a cap of 300 to the
  floor. Same amendment, third source: a seat's first measurement is
  its least reliable one, and a seat whose peak drifts upward between
  the monthly review and a duty-growth trigger is measured by neither.
  alexandria's writer went from 53 to 80 turns in a day when it started
  running daily, against a cap of 150 nobody had noticed was low. And
  the trap for this seat specifically: the 2026-09-21 run queued a PM
  cap raise on the grounds that the seat's duties had grown, which is a
  feeling rather than a measurement and is the exact thing this rule
  forbids. The next run caught it.)
- **L-X4 — Reach is proven by a write, never by a read.** A credential
  check that only reads proves nothing, because public repositories
  read anonymously and a token with no grant at all returns the same
  200. Reach is verified by a write the seat then undoes: create a
  throwaway ref at the default branch head and delete it, never
  touching a protected branch. A repository that reads but does not
  write is recorded as unreachable. (HQ incident 2, 2026-09-19: the
  first centralizer run read three portfolio repos successfully with a
  token that had `pull: false, push: false` on all three, and the
  supervised re-run reproduced it as a negative control, where
  atelier-app returned `main` to a read and 403 to a write on the same
  token in the same job.)
- **L-X5 — Secrets: presence and length, never the value.** A seat
  checks that a secret exists with `${VAR:+set}` and `${#VAR}` and
  never prints, echoes, or pipes the value, including through a
  redaction filter. Redaction is not a safety layer, it is a guess
  about a format. (HQ incident 3, 2026-09-19: the centralizer printed
  `EXO_TOKEN` into its own run log because its `sed` pattern covered
  `ghp_` and the classic prefixes but not the fine-grained
  `github_pat_` this PAT uses. The check it actually wanted never
  needed the value.) **The safe form, copied verbatim** (L-A14):

  ```bash
  printf 'TOKEN present: %s length: %s\n' "${TOKEN:+yes}" "${#TOKEN}"
  ```

  The trap to know by name is `${TOKEN:-default}`. It reads as "print
  a placeholder instead" and it expands to the variable's **value**
  whenever the variable is set, which is exactly the case a secret
  check runs in. Use `${TOKEN:+yes}`, which expands to the literal
  `yes` and never to the value. (HQ incident 4, 2026-09-20: the rule
  above, read and believed, did not stop the next run printing the
  same token, because the rule was a prohibition with no snippet.)

- **L-X6 — The cadence test: a duty is owned only when the seat's
  cadence is shorter than the duty's trigger rate.** Put the trigger
  rate and the assignee's cron side by side. If the cron is slower,
  the duty is not owned by that seat, it is being performed by whoever
  is present, and in this company the only continuous process is the
  owner. Two consequences bind every seat that assigns work. First,
  charter edits raise the ceiling on what a seat does when it runs and
  only cron edits change how often it is there, so a duty added to a
  weekly seat to fix a daily problem is not a fix. Second, a cadence
  gap reads as *covered* in every audit, which makes it strictly worse
  than an unowned row that at least reads as open, so every
  unowned-duty audit carries a cadence column and runs this test before
  calling anything owned. (alexandria incident 22 and the "presence
  gradient" entry in its learning log, 2026-09-19: the PM's cron was
  weekly in a company whose state changed every forty minutes, the seat
  gained four duties in forty-eight hours, and on a ten-hour working
  day there were twenty-five agent runs, fifteen pull requests, and
  zero PM runs. The owner: "right now i feel like im doing the PMs job,
  i want the pm to be proactive." This is the mechanism under L-P3: the
  PM seat was not underperforming, it was not there. Applying the test
  to alexandria's own register the hour it was written found two more
  gaps, one of them against the exo seat itself.)
- **L-X7 — A correct fix that never ships is a measurement of the
  bottleneck, not a to-do.** When a fix is written out, ready to apply,
  read every run, and still unapplied across three runs because only
  the owner can apply it and it is never the most urgent item in her
  queue, the honest record is the queue depth, not a fourth request.
  Record the occurrence, state plainly how long the org has run without
  the thing, and escalate the bottleneck rather than the item. Any org
  fix that is genuinely valuable but never the most urgent will never
  ship while the queue drains through one pair of hands. (alexandria,
  2026-09-19, the register's own unpaid debt: a no-ship tripwire queued
  2026-09-18 outlived three exo runs while the owner spent two days
  hand-applying OIDC, permission mode, model routing, twelve caps, two
  timeouts, container config, and a new seat's workflow. Companion to
  L-X1, which says a fix is closed only in the tree: this one says what
  to do when the tree is not reachable from the seat.)

  **Amended 2026-09-28 with the cost nobody had named.** Queue depth is
  not a tidiness problem. **It is what turns independent work into
  conflicting work.** Seats branch from different snapshots and never
  message each other, so every day a branch waits is another day it can
  collide with a branch it cannot see, and the collisions land in
  exactly the shared files the org uses to coordinate: registers,
  incident numbers, decision logs. Report queue depth as a number with
  its oldest item's age, beside the conflicts it has already caused,
  and report it as an observation rather than a proposal, because the
  merge gate is the owner's by design and loosening it is her call and
  nobody else's. (alexandria, 2026-09-24: eighteen pull requests open,
  the oldest six days old, exactly one PR merged since 2026-09-21 and
  it was the chair's, while every chair PR in the log had merged within
  hours. The incident-numbering collision of L-A18 happened because
  four seats wrote into one register across six days of unmerged
  branches, so the second cost is visible in the first.)

- **L-X8 — A runtime change is smoke-tested before it reaches a seat
  doing real work.** Every change to the ground a seat stands on, which
  means the container, the runner, the image, the permission mode, the
  token, the model route or the workflow shape, is fired on purpose on a
  throwaway branch and watched, before any scheduled seat executes under
  it. The class this catches is the one where the agent and its charter
  are both correct and the ground under them moved, so no amount of
  charter review finds it. The method costs a few red runs nobody
  depended on. Skipping it costs a scheduled seat dying on a stderr line
  nobody is watching for, and sitting dead until someone reads the log.
  (alexandria, 2026-09-19, the Stage 1 containerization: two deliberate
  smoke tests caught that Claude Code refuses
  `--dangerously-skip-permissions` under uid 0, and that the container
  user must match the host's uid 1001 to write the Actions runner's own
  state files, for a total cost of two red runs and one 12-turn
  verification. The owner asked whether this should be standing law and
  the recorded answer was yes. Procedure: alexandria
  docs/agents/runtime-changes.md.)

  **Amended 2026-09-28, because the law existed and did not fire.**
  Two corrections, both about scope. First, **a provider or model
  change is a runtime change**, and integration properties are not in
  anyone's documentation but are all in one real call: reasoning models
  think before they write and spend the output reservation doing it,
  long calls need long timeouts, long calls must not hold a database
  transaction open, and a provider swap rewrites owner-facing prose.
  Second, **a product is a runtime**. The list in the original rule was
  written the week alexandria containerized, so it names containers,
  runners, images, permission modes, tokens and workflow shapes, and a
  reader applying it honestly concludes it does not cover a cron, a
  static deploy or a hosted server. It covers them now. The
  consequence for the audits that enforce this rule: they read the
  directory where providers actually live, not only `.github/`. And the
  smoke test is a link in the deploy command, per L-A22, not a sentence
  in a charter. (alexandria, 2026-09-24 second cycle: ADR-32 moved the
  press's single writing call to a new provider straight onto the real
  Monday path, and it failed four times in one evening: no content,
  then a 300s client timeout, then Neon killing a read transaction left
  open across a multi-minute call so a written issue could not be
  saved, then an alarm subject the owner rejected on taste. The chair
  fixed each in minutes and the owner found each one from her inbox.
  This is L-A21's scope half with a price attached.)
- **L-X9 — A seat's lane is bounded by its token, not by its charter.**
  Where the two disagree the token wins, and it wins silently until
  something tries to write. So a charter that names a lane names the
  credential that reaches it, and a seat that cannot reach part of its
  own lane files that as an incident rather than shipping a quiet
  workaround. Where the boundary is deliberate, it is recorded as
  deliberate, with the reason. (HQ incident 5, 2026-09-20: the engineer
  seat found nine HQ seat workflows missing the visibility post step
  that an ADR recorded as shipped, fixed all of it, and could not push,
  because the Actions `GITHUB_TOKEN` is never granted the `workflows`
  scope and the workflow `permissions:` block has no key with which to
  grant it. The charter had named the company's machinery as that seat's
  lane, so the collision was waiting from the first day. The fix shipped
  as a tool the owner runs, which is the round trip the design existed
  to avoid. Companion to L-X4, which proves reach by a write.)
- **L-X10 — One rule, one owning document, and the dispatch prompt
  defers to the charter.** L-A10 gives every file one owning charter.
  One level up, every rule has one owning document, and when a rule
  appears in both a charter and the dispatch prompt that launches the
  seat, the prompt wins silently, because the seat reads it first. That
  makes a duplicated rule a coin flip on which file a seat happens to
  trust. A workflow prompt therefore states no rule the charter owns and
  points at the charter instead. The safe form for the commonest case,
  copied verbatim (L-A14):

  ```
  Within your first turns, create a branch named by your charter's
  branch convention and open a DRAFT pull request with
  `gh pr create --draft`, committing into it as you work — a died
  run must still ship its partial work.
  ```

  (Atelier incident I3, 2026-09-19: the pm charter fixed the branch
  convention at `pm/sprint-YYYY-MM-DD`, the workflow prompt said
  `pm/YYYY-MM-DD-slug`, and PR #1 branched
  `pm/2026-09-19-pending-tracker`. The branch name is the cheap
  instance. Any rule landing in only one of the two binds or fails to
  bind by accident. HQ's own standards/workflow-template.yml still
  carried the hardcoded branch line at the time of this harvest, which
  is the same defect one level up.)
- **L-X11 — Every seat's charter is two files, and no run had ever
  diffed them.** There is the charter in `prompts/`, which the seat can
  read and often edit, and there is the inline `prompt:` block in the
  workflow, which the seat usually cannot edit and which arrives last
  and closest. Where the two contradict each other, expect the workflow
  block to win, because it is nearer the model's attention. So a
  charter edit is not a duty performed, and any audit of what a seat is
  instructed to do reads both files or it has read half the charter.
  The sweep is per seat and mechanical: diff the two, list every
  instruction present in one and absent or contradicted in the other.
  (alexandria, 2026-09-21: the owner's ruling of 2026-09-19 gave site
  copy to the writer seat, the exo run corrected `prompts/writer-agent
  .md` accordingly, and `.github/workflows/agent-writer.yml` line 40
  still told the seat "Never edit taste.md, charters, site copy,
  pipeline code, sprints, or skills". The corrected charter was inert.
  One contradiction confirmed out of twelve seats, because the run that
  found it judged fixing one worth more than finding a second. Note
  L-X9: the seat that most needs this sweep is usually the seat whose
  token cannot fix what it finds.)
- **L-X12 — The owner-as-seat audit: count what reached her, because
  no other audit can see it.** Every audit this company runs measures a
  seat against its charter, or a charter set against a duty. None of
  them can see work the owner did herself, so a duty that falls to
  whoever is present reads as covered in every report, and the only
  continuous process in this company is her. The detector is a number
  and it belongs in the exo run's standing observations: **how many
  rounds of one artifact reached the owner before it converged.** One
  is a healthy probe. Two is a pattern. Eight is a missing seat. Run
  the same count on dispatches by author, where a list whose every entry
  names the owner says the dispatching seat is not there, and on
  failures by reporter, where a failure the owner reported first is a
  detection failure rather than an input. (alexandria, 2026-09-21,
  generalizing two of its own incidents that turned out to be one: on
  2026-09-19 the PM was asleep and she said "right now i feel like im
  doing the PMs job". On 2026-09-20 the writer was forbidden from site
  copy by its workflow prompt and she drafted eight rounds herself. In
  both cases every seat obeyed its charter and no audit failed.
  Enforced there at prompts/exo-agent.md §3e. Companions: L-X6 gives
  the cadence test that predicts the gap, L-P3 says the PM seat exists
  to close it, and this rule measures whether it did.)

## security

- **L-S1 — Raw records are private by default, and a visibility flip is
  a data review.** Transcripts, session captures, trial records, and
  anything carrying the owner's verbatim prompts or absolute local
  paths live in a private repository. Nothing generated from a record
  ships to a public surface before a redaction pass and the owner's
  per-record sign-off. Making a repository public is not a settings
  change, it is a review: the data already in the history is the thing
  being published, and history outlives the file. (Ursa incident 2,
  2026-09-18: the bootstrap commit carried trial records with
  unredacted owner prompts and a machine username onto a repo that was
  then made public by ADR-001, found by the security seat about a day
  later. The fix cost a git-filter-repo history rewrite across every
  branch, and unreferenced commits stay SHA-addressable until GitHub's
  own garbage collection, so the exposure could be reduced and not
  undone.)
- **L-S2 — Every upstream is compromisable, and the threat model says
  what we pull and how we would know.** For each upstream a product
  depends on, the security artifact answers two questions in writing:
  what do we pull from it, and how would we know if it had been
  tampered with. An upstream is not trusted because it is large.
  (alexandria incident 19, 2026-09-19: the pipeline consumes Hugging
  Face daily and mounts an HF model cache, and HF production systems
  were compromised in the 2026 agent-escape event during the same
  window the pipeline was being built. Nobody had written down what the
  dependency was until the owner reported the event.)

## research

- **L-R1 — The model's knowledge cutoff is an org-wide blind spot, so
  something must watch the live world.** Seats verify vendor
  documentation but no charter says to look at what has happened, and a
  seat cannot know about an event that postdates its training. Any seat
  owning a live territory runs an explicit ecosystem-events check
  against the live web for its declared coverage areas, every run, and
  a territory with no such check is uncovered no matter how many feeds
  it reads. Owner-reported news about your own declared territory is a
  detection failure, not an input. (alexandria incident 19, 2026-09-19:
  the defining agent-infrastructure event of the year sat squarely
  inside the digest's declared coverage, the corpus held none of it
  because postmortem literature enters no arXiv category, and the owner
  had to report it herself. Catalog: the research role's canonical
  charter carries this check.)

## inbox — lessons awaiting an ID

Anyone may append here between harvests: the owner, the chair, any
seat. Nothing in this section is law and nothing cites it. The
centralizer generalizes each entry at the next harvest, gives it a rule
ID, files it under its role section, and deletes it from here. Format:
a title, the date, the role or roles it binds, and the rule in plain
sentences. **No `L-` identifier.** See the preamble and L-A18 for why
a second author picking IDs is a collision generator rather than a
convenience.

*Empty as of 2026-09-28. The five entries that were here (presence is
a cadence, open routing is best-effort, sync mode, a status line is not
communication, and the continue-on-error tripwire pair) are now
L-P6, L-E7, L-P7, L-A19 and L-E8 in their own sections.*
