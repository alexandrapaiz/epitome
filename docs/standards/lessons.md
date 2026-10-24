<!-- vendored-from: standards/lessons.md @ c2705bc33965f2969f6093232ce634c44510a2b1 -->
> **Vendored copy — do not edit here.** Source of truth is
> `alexandrapaiz/alexandra-systems` `standards/lessons.md` at commit `c2705bc`,
> vendored 2026-10-24. Changes to a company standard are HQ
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

  **Amended 2026-10-05, for the case where the register is a gate.**
  When a rule's wrong answer is itself an incident, the rule is a
  command that returns a verdict, never a paragraph a seat reads from
  memory once per run. A memoryless seat recalling a clause under turn
  pressure is the weakest reader the company has, and the clause it is
  recalling is the one the company chose to put a penalty behind. The
  test that a gate is real: name the command, and say what its exit
  status means. (HQ, 2026-10-04: standards/pm.md §10 granted every seat
  the right to merge its own pull request when every changed file is a
  knowledge surface, told the seat to verify that with
  `gh pr diff --name-only`, and declared that a Tier A merge whose diff
  crossed the line is an incident that suspends that seat's self-merge
  right. Nothing in `tools/` computed it for two weeks. When the
  engineer finally did, in `tools/check-tier.sh`, the check immediately
  established two facts no amount of careful reading had surfaced:
  §10's grant cleared none of the 31 open pull requests, and two of
  §10's own named surfaces — `docs/ideas.md` and `docs/finance/` —
  cannot be decided from file names at all, so the `--name-only` ritual
  the standard prescribed was the wrong instrument for its own rule.
  The seat's own words for it: "the company put a gate on its only
  self-service merge path, made a wrong answer an incident, and then
  implemented the gate as a seat reading a paragraph from memory once
  per run." Note the direction a real gate is built in: fail-closed, so
  a false Tier B costs one merge of waiting and a false Tier A costs an
  incident, and the cheap error is the one the tool is allowed to make.)
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

  **Built 2026-10-18, for the decisions register first (HQ engineer).** The
  inbox this amendment asked for is `docs/decisions/inbox/`: a seat writes
  one file per decision, `YYYY-MM-DD-slug.md`, with no number anywhere, and
  whoever merges runs `tools/adr.py issue --apply` on the mainline, where
  there is one author and one snapshot. `tools/adr.py check` fails on a
  duplicate number, on a heading that does not parse, on a conflict marker
  left in the register and — with `--require-issued`, which is what the
  mainline asserts — on an inbox that still holds anything, so forgetting to
  issue is loud rather than silent. The five numbers this repository had
  already issued twice stay as they are, on this clause's own instruction,
  and `tools/adr-baseline.txt` records for each one which entry each live
  citation means, which is the first time that ambiguity was resolvable by a
  reader rather than merely visible. The cost of the old scheme, measured the
  day the inbox was built: five ambiguous numbers, and three of the eight
  unmergeable pull requests in the queue conflicting *only* on the position
  of an append — including the one carrying that week's sprint goal, held
  five days. A register the whole company appends to needs this; the two that
  still do not have it, `docs/agents/incidents.md` and this file, are the
  same defect waiting.

  **Amended 2026-10-23, HQ centralizer: a register whose rows come in two
  kinds needs its key unique across both kinds, and a duplicate there
  stops a queue rather than only confusing a reader.** The growth ledger
  in `docs/architecture/agentic-system.md` holds week-summary rows keyed
  `2026-W43` and per-run rows keyed `2026-W43 (message run 14, PR #313)`.
  One per-run row took the bare week as its key, so the register held two
  rows answering to one name, and the consequence was not ambiguity. It
  was that `tools/merge-register.py` refuses an entry merge when one side
  already holds a key twice, by design and correctly, since it cannot
  tell an edited row from a disagreement. That one key therefore made the
  automated resolver refuse **every** branch conflicting in the
  most-conflicted file in the repository, and the branch it was refusing
  carried a gate fix that had been open five days. So a register's key
  rule covers every kind of row it admits, and the test of a key is
  whether the register's own merge tool accepts the file, which is a
  command rather than a reading. The deeper repair for this particular
  register is already proposed twice in `docs/ideas.md`: make the ledger
  heading-keyed so two appends merge without a human.

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

  **Fourth clause, 2026-10-11: the allocator must work in the checkout
  the seat actually gets, and a checkout it cannot read is not a clean
  one.** This register's own header named an allocator
  (`tools/check-registry-ids.sh`) for ten days that has never existed on
  `main`, because the pull request carrying it was closed unmerged, so
  every author in that window was back to reading the tail. The allocator
  that does exist, `tools/check-queue-ids.sh`, then answered "no
  identifier is claimed twice across the queue" and exited 0 over the
  whole open queue in this seat's own checkout, while two identifiers were
  taken and one of them was this seat's. Both causes were the checkout and
  neither was the logic: the runtime clones at depth 1, so `git merge-base`
  finds no common commit and the comparison was skipped for every ref; and
  the clone is single-branch, so every `origin/<branch>` but the base is
  absent or frozen at whenever somebody last fetched it by hand. **So a
  check names the refs it could not read and exits on its own code,
  because "I could not look" and "nothing is wrong" are different answers
  and only one of them is safe to act on.** A tool that fetches what it
  was told to compare, and deepens a shallow clone before comparing, is
  doing its own job rather than inheriting somebody's environment. (HQ
  incident 14, 2026-10-11, measured: 0 findings and exit 0 before,
  2 findings in the same checkout after `git fetch --unshallow`, nothing
  else changed. The collision was caught instead by another seat in a
  deeper checkout and reached the author a day later through a pull
  request comment and a handoff. Alexandria's `harness-engineering` skill
  carries the general form from the literature — "a bare 'failed' is the
  worst feedback a harness can give", Environments as Scaffold, arxiv
  2609.08404, with feedback consistency named as a hard boundary rather
  than a nicety — and this was its inverse, a bare "fine". Related: L-E11
  on a guard reporting the smallest true thing, and L-X7 on a fix that
  reaches nothing that runs, which is what the closed pull request made of
  the allocator.)
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
- **L-A26 — A grant written as a list of names decays into a grant for
  one thing, so write the property the list was an application of.** An
  authority that enumerates paths, directories or filenames is correct
  on the day it is written and wrong on the day the company adds a
  seat, and it is wrong silently, because the enumeration keeps
  answering confidently about the world it was written in. State the
  property that made the listed items safe, name the exceptions with
  the reason beside each one, and give the property a command that
  tests it (L-A9 as amended). Two sources, one rule, and the second is
  this register's own distribution.

  *Source one, the grant that cleared nothing.* standards/pm.md §10 had
  granted Tier A self-merge to a list of directories since ADR-011. The
  list was drawn from the surfaces the PM and the exo centralizer
  happen to write, and the company then added the okr, mba, yc,
  distribution and marketing seats and a generated company view.
  `tools/check-tier.sh --open` over all 31 open pull requests on
  2026-10-04 answered Tier A for exactly one, a one-line stub. Four of
  the refusals were 100% dated analysis — okr #71, mba #69, yc #68,
  distribution #70, with zero code, charter, workflow, standard, site
  or spend anywhere in their diffs — and every one of them missed on a
  directory name alone. A fifth gap was quieter: `tools/sync-company.sh`
  had been committing `docs/company/` straight to `main` citing "§10
  Tier A" since 2026-09-20 and §10 never named that directory, so the
  practice was right and the citation was fiction. The replacement is a
  property: inside `docs/`, a knowledge surface is a file whose only
  effect is what a reader knows — nothing executes from it, no money
  moves, no authority changes, no customer reads it — with the Tier B
  exceptions named and reasoned (HQ PR #88 and PR #90, ADR-051).

  *Source two, measured on this seat.* The exo centralizer's own grant
  names two filenames: `standards/lessons.md` here and
  `docs/standards/lessons.md` in a product. Every vendored standard is
  the same class of artifact, produced by the same command, verified by
  the same diff, distributed by the same seat in the same pull request
  shape. On 2026-10-05 a drift check across the five portfolio repos
  returned: `lessons.md` current in 5 of 5, and of the eleven other
  vendored copies, zero current — `pm.md` behind in all five (four by
  six days, asc-router by fifteen and 127 lines), `documents.md` behind
  in epitome and asc-router, `model-routing.md` behind in asc-router.
  Same seat, same tool, same week, same mechanical one-file diff. The
  only variable is which filename the grant happens to name. A
  distribution duty granted per filename is performed for one file and
  recorded as performed for the duty.
- **L-A27 — An authority held and not exercised costs exactly what no
  authority costs, and it shows up as a pile.** A grant is not a
  property of a seat, it is something a run does. A run that could
  self-merge and does not, or that opens a draft and ends without
  readying it, hands the owner an artifact she cannot act on — GitHub
  refuses to merge a draft at all — and no later run comes back for it,
  because the seat has no memory. So three clauses bind every seat.
  **Exercise it or say why:** a run holding a self-merge grant either
  merges every qualifying artifact or writes in the pull request which
  clause stopped it, so the next reader sees a decision instead of a
  gap. **Close what you supersede:** a recurring ceremony artifact
  replaces its predecessor, so the run that writes the new one closes
  the old pull request in the same run rather than leaving a fifth to
  pile on. **A draft is legitimate only while its own run is alive:**
  the run that opened it readies it or states in it why it stays a
  draft. Where this rule and a fail-closed gate disagree, the gate
  wins — a tool that answers Tier B when it cannot prove Tier A has
  given the right answer, and this rule asks for the reason to be
  written down, never for the verdict to be overridden. (Three sources,
  2026-09-26 through 2026-10-04. Ursa's PM self-merged its standups as
  Tier A in #12, #17 and #23, stopped with #37 for no reason it
  recorded, and #37, #45, #60 and #67 then sat open and unclosed across
  four days, each one's own description saying it superseded the one
  before it, until the 2026-10-04 run closed all four. Ursa's frontend
  commented "superseded by #65" on #15, #35 and #51 on 2026-10-01 and
  left all three open. At HQ on 2026-10-02 the engineer's new
  `tools/check-draft-prs.sh` found that nine of the ten open drafts had
  no live run behind them, idle from twelve hours to six days against a
  longest declared seat timeout of sixty minutes, and **five of the
  nine carried finished reports**; the standup closed the PM's #39 and
  #46 the same day. One of the nine was this seat's own #49, finished
  on 2026-09-28 and still a draft a week later. The second cost is a
  measurement error that compounds: every standup's open-pull-request
  count was overstated by five, so the queue depth the org reports is
  not the queue depth it has.)
- **L-A28 — A promotion between two registers is recorded on both
  sides.** When an entry in one register becomes a rule in another —
  a product lesson into this file, a finding into an ADR, a ruling into
  a standard — the source entry records the identifier it became and
  the date, and the destination records its source. One side is not
  enough, because the side that was not written is the side a later
  reader consults. The corollary binds anything generated: a view that
  can read only one of the two sides states that limit in its own words
  instead of asserting the conclusion it cannot reach. (Two instances,
  one week, both in this company's own machinery.
  `docs/company/lessons-portable.md`, regenerated daily, listed
  atelier-app's L1, L2 and L3 on 2026-10-04 under the heading "3
  awaiting harvest" and the sentence "a lesson still listed here has
  not been promoted yet". All three became law as L-P4, L-X3 and L-A10
  on 2026-09-19, the same day atelier's seat wrote them, in commits
  2efaa93 and 08e67e4, and all three are cited by name in this file
  with atelier as the source. The view was still calling them
  unharvested fifteen days later.
  The generator reads the product side only, the product entries record
  no rule ID, so neither side could answer the question the view
  claimed to answer, and the first act of this harvest was re-deriving
  by grep what a marker would have stated. Second instance, same
  generator, stated honestly by it: `docs/company/incidents.md` reports
  57 incident entries carrying no status marker, so it cannot say which
  are open — which makes the companion duty explicit, that an incident
  register entry carries an explicit `**Status:** open` or
  `**Status:** closed` line. Note which instance is the better
  behaviour: the incidents view says what it cannot see, and the
  lessons view asserts what it cannot see.)
- **L-A29 — A rule that is not on main is not a rule, and announcing
  one teaches the seats to distrust the channel.** Authority text lives
  in exactly one place: the standard, the decisions file or the charter,
  on `main`, in the repository that owns it. Until it is there, a rule
  may be proposed, drafted, discussed and announced, but it does not
  bind anyone and nothing may be built on it. Four clauses bind every
  author, seat and chair alike. **Announce the pull request, never the
  rule:** a message that tells seats to act differently carries the
  merged commit, or it carries the pull request number and says plainly
  that it is not law yet. **Never vendor unmerged text:** a vendored
  copy is a copy of `main` at a named commit and of nothing else, and a
  copy that cites a decision number the source repository does not have
  is a fork wearing a standard's name. **A seat that checks and declines
  is right:** a seat that reads a message, checks the source of truth,
  finds the cited text absent and declines has performed the rule, not
  broken it, and the defect belongs to the announcement. **The cost is
  the channel, not the run:** a seat that is wrong once about whether a
  message carries authority discounts every later message, so the price
  of announcing early is paid by messages that had nothing wrong with
  them. (Two sources, both 2026-10-05, both from the same night. First:
  `chair:epitome` and `chair:hq-console` announced the seat-creation
  authority of PM standard §§16-19 and decision 046 over the event bus;
  the bus delivered through both doors, and both PM seats it woke
  declined. HQ's PM checked `main`, found no §§16-19 and no decision
  046, and declined so that nothing it did rested on text that is only
  on the `chair/board-messages` branch. That is the correct behaviour,
  recorded here as such. epitome's PM filed the message as a thing for
  the owner to rule on, because its vendored `docs/standards/pm.md` is
  pinned at HQ `6acf9f4` and still carried the sentence "Seats never
  message each other." Second, and the sharper one: alexandria's vendored
  `docs/standards/pm.md` was edited on 2026-09-30 in commit `f16df04`,
  "PMs own merges and failed-run triage (HQ decision 041, vendored)",
  which gave its PM a three-tier autonomy model and a Tier B merge
  grant. For the next five days HQ `main` had no decision 041 and no
  three-tier §10; that text lived only on HQ pull requests #60 and #73.
  One product's PM merged under an authority the company had not
  granted, from a copy that also cross-referenced a "board §15" absent
  from its own file. What settles the rule is how it ended: the owner
  merged #60 on 2026-10-05, at 03:5x, in the same hour this run was
  measuring the drift it caused. The grant is law now, and alexandria
  was right about where the company was going. It was still wrong about
  where the company was, and nothing in the process produced the
  ratification — it arrived by the owner's hand, by coincidence of
  timing, five days after a product began acting on it. A rule that
  happens to be ratified later was still not a rule in the interval, and
  the interval is where the merges happened. Third-order: the handoff
  that produced this rule, `chair:epitome` to this seat, was itself
  correct, because it named the pull request and not the rule.
  Related: L-A28 on recording a promotion on both sides, and L-A18 on a
  second author allocating identifiers.)

- **L-A30 — A commit is not work until it is pushed, so commit and push
  in one command.**
  Every seat, every repository: `git commit ... && git push` is one tool
  call, and a turn never ends with a commit that no remote ref contains.
  The reason is that the sandbox is the only place that commit exists,
  and the seat is the only actor that can still move it.
  Nothing in the harness runs between the model's last turn and
  teardown, so every guard the company owns fires after the work is
  already gone.
  Two clauses come with it, and they bind whoever edits the end-of-run
  check — `tools/no-ship-tripwire.sh`, on every seat that vendors it —
  rather than the seat.
  **A guard that can only report should be made to repair first**: an
  end-of-run check that finds commits on no remote pushes them to a
  rescue branch named for the seat and the run, says where they went,
  and fails only if the rescue itself fails.
  **A run's own account is its black box**, so the first-person done on
  the board is posted after the last push and names the head SHA it
  left on the remote, because the transcript does not survive the run
  and the done is what a later reader actually has.
  (HQ incident 14, run 37259867006, 2026-10-05. The seat shipped draft
  PR #102 sixteen minutes in and pushed its second commit at 03:52:15,
  then committed once more and ended of its own accord at 03:52:52 —
  118 turns of 150, `is_error: false`, clean tree, no timeout. The
  tripwire read the repository one second later and reported the whole
  run as lost. Its work was not lost and is on the remote; the content
  of that one trailing commit is, and it is unrecoverable. The timeline
  was reconstructable only because the seat had posted a done on the
  board at 03:50:50, since the action hides the transcript
  (`show_full_output: false`, no artifact) and the tripwire writes its
  three facts to a job summary no API serves. Companion to L-E3, which
  says ship first and is the rule this run obeyed for its deliverable
  and broke for its last commit, and to L-E11, which owns the
  measurement half of the same incident.)
- **L-A31 — Ask whether the check ran before you ask what you broke, and
  answer a fault that is not yours once.** A red check is not evidence
  that the branch it names is broken. The first question is whether a
  runner ever took the job, and it has a cheap answer:
  `tools/check-run-ran.py <run-id|url|--branch X>`, where zero recorded
  steps means no runner started the work. Four clauses. **A run that
  never started is machinery, not your branch:** do not read the diff
  for a cause, do not rewrite code to chase it, and do not report it as
  a test failure, because every minute spent on it is spent on a fault
  no change to that branch can reach. **One cause gets one answer:** the
  seat that owns the broken machinery says once, on the board, what the
  fault is and what it blocks, and routes the single owner decision if
  the fix is hers. Every other seat the same fault wakes closes its own
  wake by pointing at that answer and does not re-derive it. **Say
  plainly that you could not clear it:** a seat blocked by machinery
  reports the block, not progress, and an unclearable red is left red
  with its explanation attached rather than papered over. **And the same
  defect points the other way:** a local suite pass is not a green
  check, so when the merge rule asks for green, do not quote one as the
  other. Report "no check ran" as its own answer, distinct from green
  and from red, which is the rule ADR-053 already states and this is its
  second occurrence. (HQ, 2026-10-13 to 2026-10-18, incident 16, whose
  own entry deferred this lesson until a second occurrence and is closed
  with it. The cause was a billing block on a private repository's
  Actions minutes, which only the owner can clear, and the lesson is not
  about billing. It is about what the other seats did with the red.
  Measured over every run in the window rather than sampled: of the 163
  runs in HQ that concluded `failure` between 2026-10-13T15:00Z and
  2026-10-18T01:12Z, 163 recorded zero steps and none was a real
  failure, and `main` alone carried 98 of them. The engineer seat was
  woken eleven times in one window by four of its own branches and said
  it on the board in the words that name the rule: "All eleven are the
  same thing, and none of them is about the branch it names. Each job
  starts, finishes two seconds later having run no step at all, and
  leaves an empty log." It also did the right thing with it, making the
  bus say it once instead of eleven times. The counter-case, from the
  first day of the same outage: one pull request was merged quoting a
  local suite pass as the merge rule's green-checks condition, and the
  check on that merge commit failed three seconds later having run
  nothing. Both halves are one confusion between a check that passed and
  a check that happened. Companion to L-A6, which says judge a run by
  its artifacts and never its conclusion, and of which this is the
  mechanical case: a run with no artifacts at all has no conclusion to
  read.)

- **L-A32 — A run is over when its artifact is reachable, not when it is
  written.** Readying the pull request is the last step of the work, not
  an administrative afterthought: GitHub refuses to merge a draft at
  all, so a run that ends with a draft has shipped nothing whatever its
  branch contains, and the seat's next run has no memory and will not
  come back for it.
  Four clauses.
  **Finish by readying.** `gh pr ready` before the run's last turn, or
  the run did not deliver. An advisory take, a recommendation, a
  measurement: unreadied, none of them has been made.
  **An unfinished branch is declared on the board, in the run's own
  done, naming what remains and what the next run should do.** The board
  is this company's durable surface and a branch is not a checkpoint.
  Saying "I will finish this next week" inside a pull request describes
  an intention to a reader who does not exist.
  **A draft that carries only the note which opened it is not
  unfinished work, it is nothing.** Close it and re-declare what is owed
  on the board. `tools/check-draft-prs.sh` answers which is which from
  the branch rather than the description, and `asc drafts` reports it.
  **Judge a seat on what landed.** A seat whose register, scorecard or
  report counts open drafts as output is measuring intention. Counting
  them is how this went unseen for eleven days.
  (Two seats found this independently in one week and a third was the
  worst case of it. yc handoff to the centralizer, 2026-10-18, routing
  it here rather than writing the register itself: "an advisory seat's
  run is not finished when the artifact is written but when the pull
  request carrying it is marked ready", with the mba seat's own words
  from its merged PR 93, "a recommendation inside an unreadied draft is
  not a recommendation". yc's own record: of its last three takes one
  was readied and moved the mba seat's position, and two sat in drafts
  closed as stale. Its handoff asked whether the pattern held beyond the
  two advisors, and it does, worse: of the 14 drafts open at HQ on
  2026-10-18, 13 had no live run and 10 carried nothing but their
  opening commit — 6 of those 10 this centralizer's, across 11 days,
  two days after the chair told this seat to land or close its own five.
  epitome's exo draft #142 changed zero files. alexandria's exo draft
  #331 held 1,480 lines nobody could merge. The field agrees on the
  mechanism: durability moved up the stack and resumption is the
  orchestrator's explicit, externally stored responsibility — MCP
  removed sessions and stream resumability in revision 2026-07-28,
  LangGraph ships checkpointers as separately versioned packages, the
  OpenAI Agents SDK leads its session docs with resuming interrupted
  runs; three independent primary sources, alexandria
  `docs/research/briefs/2026-09-19-orchestration.md` §1.2. A draft used
  as an implicit checkpoint is the pattern all three abandoned.)

- **L-A33 — A sweep is point-in-time, so it must come back for what was
  merely pending.** A merger, a dispatcher or a checker that walks a list
  once sorts it into done and refused, and silently drops the third
  state: in flight. An item whose check is still running at the moment
  of the sweep is not red and is not merged, nothing in the sweep's
  report distinguishes it from a refusal, and no later pass returns for
  it — so it keeps its own staleness and waits for an accident. So a
  sweep reports pending as its own state, re-reads anything pending
  before it finishes, and when it cannot wait, names the item and the
  one command that finishes it. "I swept" is not "the list is empty".
  (alexandra-systems, 2026-10-18, measured in one morning. A
  distribution sweep at 06:41Z took three vendored copies whose checks
  read `CLEAN` and skipped the fourth, atelier-app #22, because it was
  `UNSTABLE` — one test *pending*, not failing. Its check passed
  fourteen seconds later. Nothing came back for it; the copy stayed
  stale for twenty-one minutes and was merged at 07:02:54Z only because
  the same seat happened to be woken for something else and had the item
  on its own next-run list. One repository in four, for want of a second
  look. The merger's-side twin of L-A32, where the seat's own artifact
  is unreachable at the moment it matters, and of L-A18's fourth clause,
  where "I could not look" is reported as "nothing is wrong" — a
  pending check is the same unread answer wearing a merge queue's
  clothes.)

- **L-A34 — An absence measured from one vantage point is not a fact
  about the world.** "None", "unobtainable", "not taken", "nothing ran",
  "no such file": every one of those is a reading, and a reading has a
  vantage point. So a seat that writes an absence names where it looked
  and who could still see the thing — the surface or command used, and
  the one party with a wider view — or it does not write the absence at
  all. The cost is asymmetric, which is why this is law and not taste: a
  wrongly reported presence invites the next reader to check it, and a
  wrongly reported absence closes the question for everyone after.
  (Three instances in one week across three seats, same mechanism,
  different subjects; routed to this register by HQ's mba seat on
  2026-10-18 as a handoff rather than written locally, with its own
  error named first: "an absence measured from one vantage point is not
  a fact about the world". One, mba run 5 wrote a product's usage
  numbers were "none, and they are unobtainable by construction" after
  a cold browser load, when the product's own front page prints them
  and the owner can read them in ten seconds; found by the yc seat,
  corrected in #249. Two, the same seat graded a recommendation "not
  taken" that had been taken in full five days earlier, from a surface
  that could not have shown it. Three, this seat's own: 163 red checks
  were each true as a reading and meaningless as a fact, because no
  surface distinguished a failing job from a job no runner ever took.
  Companions: L-A18's fourth clause is this rule for a *program* — a
  check names the refs it could not read and exits on its own code —
  and L-A31 is the special case where the absent thing is a run. This
  entry is the general form for a seat's own prose, where there is no
  exit code to carry the doubt and the sentence has to carry it
  instead.
  **Amended 2026-10-18 by the seat that wrote it, after a second
  instance this register's own author produced.** Three clauses, none
  of them a new rule.
  *A bounded count is an absence claim about its complement.* The five
  phrases above are all absences, so a seat writing "four seats are
  deaf" matches none of them and never knows it is standing inside this
  rule — and the half that broke is the unwritten half, "and no other
  seat is". So naming the command is not enough: the other places the
  thing could live are named too. Measured the same day in three tools
  of this company's own: a bus census whose universe was the routing
  table and therefore produced neither a row nor a not-read for the one
  subcompany missing from it; a staged-workflow check that knew one
  staging convention of the portfolio's two; and a shell guard whose
  three hand-written exclusions failed twice in one morning, the second
  time on the pull-request triage that had just finished describing the
  first.
  *Read the mechanism, not a caveat on the surface.* The move worth
  copying from the second instance is not a hedge added to the count:
  it is that the reader went to the dispatcher the trigger is a trigger
  for. A surface is nearly always a proxy for a mechanism that can be
  read directly, and reading it is cheaper than qualifying the proxy.
  *The asymmetry has an exception.* A wrongly reported presence invites
  the next reader to check it — unless both readers stand on the same
  surface, in which case two readings are one reading with two names
  and downstream they read as two sources, which is worse than the
  single reading they are.)

- **L-A35 — A decision that moves a mechanism carries the checkers that
  read it, in the same pass and into every repository that vendored
  one.** Moving a thing is not done when the thing works somewhere else;
  it is done when every program that audits it knows where to look.
  Until then the checker is not silent, which would at least be honest —
  it reports confident findings about a world that no longer exists, and
  those findings cost more than no checker at all, because they are
  mixed in with the real ones and they train every reader to skip the
  category. So the pull request that moves a mechanism updates the
  checks that read it, runs them across every repository in the
  portfolio table, and treats a vendored copy of a check as part of the
  mechanism rather than as somebody else's file. (alexandra-systems and
  four product repositories, 2026-10-18, measured and then measured
  again because the first reading was wrong. Decisions 049 and 056 moved
  every seat's clock off GitHub Actions and onto the host on 2026-10-16
  and 2026-10-17: the crons were commented out of the workflows and
  carried into `runtime/agents/<seat>/agent.toml`, which is real and is
  working. `tools/check-manifest.sh` was not carried, and it knows only
  GitHub's scheduler, so it reported **35 findings across five
  repositories — HQ 5, alexandria 10, Ursa 10, epitome 6, atelier-app
  4 — of which 33 say "cadence declared but the workflow has no live
  cron" and most of those are false**: the seat's clock exists, on the
  host, in a file the check does not read. This register's first draft of
  this entry asserted the opposite, that 33 manifests were stale, and
  proposed to "fix" HQ's by blanking five true declarations to
  `dispatch-only`; that edit was written, measured against the host's
  own manifests, found to assert three falsehoods, and reverted inside
  the same run. The cost of the real version is larger than the cost of
  the false one. Two genuine drifts were hiding inside the 33 — HQ's
  engineer declaring weekly while its host clock fires twice a day, and
  HQ's okr declaring monthly while its host clock fires weekly on Sunday
  — and nobody could see them through the noise. HQ's copy also makes
  the manifest step of `tools-tests` fail on `main` alone, so every pull
  request at HQ inherits a red no branch caused, and on 2026-10-18 HQ's
  PM held two pull requests on it in one pass while an earlier pass that
  day had merged through the identical finding. The cure was written on
  2026-10-16 — the engineer's open pull request teaches the check all
  three places a clock can live and corrects the engineer drift — and it
  has been open ever since, behind the same queue. And the half nobody
  owns: the four product copies of that checker are **vendored tools**,
  and this company distributes vendored *standards* only, so when the
  fix merges at HQ there is no pass that carries it to the four
  repositories whose own test suites run the stale copy. Companion to
  L-X15, where a company-wide fix takes every repository as an argument,
  and to L-X16, where the source of a distributed copy is the law and
  not a draft; both of those are about the file that is distributed, and
  this one is about the checker that reads it.
  **Correction, 2026-10-18, same day, by the three product PMs this rule
  was handed to and then by this register's own search:** the sentence
  above about "the four product copies of that checker" is false. There
  are no product copies. `tools/check-manifest.sh` exists at HQ only;
  Ursa's, epitome's and alexandria's PMs each looked for it in their own
  repository before acting, each found nothing, and each said so, and a
  code search finds zero hits for the filename in all four product
  repositories and no script anywhere in them that reads `company.yaml`
  at all. The 35 findings were produced by HQ's single copy reading the
  four manifests from HQ. So the distribution gap this rule names is
  real but a different shape: there is nothing downstream to update,
  because the check is central and can only ever run centrally, and the
  defect was asking four PMs to run a file that was never in their
  hands. That ask is now its own rule, L-A38. The rest of this entry
  stands as measured.)

- **L-A58 — A credential's permission is proved by a write, and
  `permissions.admin` is not a permission.** The `permissions` block the
  GitHub API returns on a repository is a fact about the *account's* role
  there, not about the scopes of the credential asking, so a
  fine-grained token can read `admin: true` on five repositories and be
  refused every write to all five. Before a seat reports that it *could
  have* done something with the authority it holds, it runs the smallest
  real call and reads the status code. (alexandra-systems, 2026-10-18.
  HQ's yc seat handed up a harness finding and wrote, correctly in good
  faith, "my own token reports admin on all four repositories, so I
  could have flipped the setting in one command before writing any of
  this, and I did not" — the restraint was right and the capability
  claim was wrong. This register ran the call: `PATCH
  /repos/alexandrapaiz/<repo>` with `delete_branch_on_merge=true`
  returned **403 "Resource not accessible by personal access token"**
  for both `EXO_TOKEN` and the runner's own token, on all five
  repositories, while `.permissions.admin` read `true` on all five. The
  setting is therefore an owner action and not a seat action, which is
  the opposite of what the handoff believed and changes who the item is
  routed to. Second instance of Incident 2's rule — reach is proved by
  a write probe, never by a read — on a new surface: repository
  settings rather than the Actions API. The cheap version of this rule
  is one sentence: a 403 is information and an `admin: true` is a
  rumour.)
  (**Renumbered from L-A36 to L-A58 on 2026-10-18**, because this
  register published two different lessons under L-A36 for six hours and
  both were vendored into five repositories. The 07:52 entry was already
  on `main` when this one was written at 08:31; this branch had been cut
  before that and allocated from a tail that no longer existed, which is
  the collision L-A60 is about. The older entry keeps the number, by L-A18:
  the side that renumbers is the side that has not been cited longest. A
  citation of L-A36 written before this repair means this entry when it
  glosses it as the credential rule — a permission is proved by a
  write.)

- **L-A59 — A merged branch does not survive its merge.** A ref left
  behind after its pull request merges becomes an ancestor of the
  default branch, so the next push onto that name is a clean
  fast-forward that needs no force, and every `paths:`-filtered workflow
  compares against the *old* head and therefore fires on every file the
  default branch gained in between. The reds that result are statements
  about `main` wearing a branch's name, and each one wakes a seat that
  reads it as its own. So: every merge deletes its head branch
  (`gh pr merge --delete-branch`, or the repository's
  `delete_branch_on_merge`), and stranded refs are pruned rather than
  left to accumulate. (alexandra-systems and four product repositories,
  2026-10-18, measured by HQ's yc seat over every path-filtered run
  rather than a sample: of 72 such runs on seat branches since the
  Actions block began, **43 were not justified by any path in the branch
  they name**, against 52 of 348 in the three weeks before. What changed
  was not billing but rhythm — nine runs of one seat in a day, each
  named from the same `<seat>/<date>-<trigger>` template, so a dormant
  hazard became a frequent one. The mechanism is proven narrowly, for a
  fast-forward onto a merged and undeleted ref, and the same seat
  recorded the counter-observation that a later merge-commit push onto
  the same branch fired nothing. At the time of writing **345 of the
  portfolio's 638 remote branches were already-merged refs still
  sitting there**: HQ 169 of 235, alexandria 67, epitome 76, Ursa 29,
  atelier-app 4. All 345 were deleted by `tools/prune-merged-branches.sh
  --apply`, which refuses to touch a ref that is not an ancestor of the
  default branch, is the default branch, is protected by name, is the
  head *or the base* of an open pull request, or whose pull request list
  it could not read. Nothing is lost: the commits are on `main` and
  GitHub still offers the ref back by name from the merged pull request.
  The preventive half, the repository setting, was false on all five
  repositories and is an owner action per L-A58.)
  (**Renumbered from L-A37 to L-A59 on 2026-10-18**, because this
  register published two different lessons under L-A37 for six hours and
  both were vendored into five repositories. The 07:52 entry was already
  on `main` when this one was written at 08:31; this branch had been cut
  before that and allocated from a tail that no longer existed, which is
  the collision L-A60 is about. The older entry keeps the number, by L-A18:
  the side that renumbers is the side that has not been cited longest. A
  citation of L-A37 written before this repair means this entry when it
  glosses it as the stranded-branch rule — a merged branch does not
  survive its merge.)

- **L-A38 — An instruction to run a check names the repository the
  check lives in, and a seat does not ask another company to run a file
  it has not verified is in their hands.** Cross-repository instructions
  are written from a checkout, and the writer's `tools/` is not the
  reader's `tools/`. Name the repository, and either give the command
  that proves the file is there or say plainly that it must be vendored
  first. (alexandra-systems, 2026-10-18, this register's own error
  against three product PMs in one pass. A handoff and then its own
  correction both named "`tools/check-manifest.sh`, vendored in your own
  repository, so that you can run it yourself". The file is at HQ only.
  Ursa's PM: "I could not have run the checker even before your
  correction arrived, not because I declined to, but because there is
  nothing here to run." All three PMs spent a search proving an absence
  and all three reported it back, which is three passes bought by one
  unchecked possessive. The same error is corrected in L-A35's
  provenance, where the false belief originated. Companion to L-A34: an
  absence is a fact about where the reader stands, and so is a presence.)

- **L-A39 — A freshness check that tests for presence answers a
  different question.** When the rule is "compare against what governs
  now", code that asks "is the ref/file/view *there*" passes in exactly
  the case that matters — the stale copy is present — and returns the
  false all-clear. Test for current: re-read, re-fetch, compare the
  stamp, and let the read's own failure be the finding. (HQ, 2026-10-18,
  found by the engineer seat reviewing this register's own distribution
  tool. `resolve_source` fetched HQ's source ref only when the ref was
  missing, and under the runtime's `--single-branch` clone
  `refs/remotes/origin/main` is the one ref that is never missing and
  always frozen at clone time, so a four-hour run read a `main` hours
  old and reported every vendored copy current against it. Reproduced in
  a fixture before the fix and after: a rule that lands on `main` after
  the clone is read as "1 of 1 current" by the old code and `STALE` by
  the new. Same family as L-A18's fourth clause — a check that cannot
  read what it compares must say so — and the inverse of L-A34: here the
  surface answered confidently *because* it never looked again.)

- **L-A40 — Merged is not running, and the check compares what is
  deployed against `HEAD`.** A change that merges into a repository is
  not in effect until the system that runs it reports the new version,
  and nothing in a pull request's green state says so. Every pipeline
  that executes a file — a prompt, a view, a vendored copy, a workflow,
  a host unit — records the identity of the version it is actually
  running, and the check compares that identity against `HEAD` rather
  than asking whether the merge happened. (alexandria, 2026-10-12, taken
  from that product's research brief rather than from a `portable: yes`
  lesson, because the library keeps its rulings in the brief and the
  register: `docs/research/briefs/2026-10-12.md` §7, incident
  `INC-2026-10-12-meta-review-proposal-merged-never-deployed`. A
  meta-review's triage prompt merged on 2026-10-05 and was never
  deployed; the pipeline kept running `ea61cbc` of 2026-09-29 and wrote
  **8,861 triage rows against the old prompt** before anybody noticed,
  and the brief records that "the org has now inferred this state by
  hand six times". Their own fix is the generalizable part: `triage` and
  `interpret` record prompt shas, so comparing those against `HEAD` is
  the check — and the deploy gate was, meanwhile, refusing to deploy the
  cure for the outage it was in. HQ has the same shape in three places
  on 2026-10-18: `docs/company/`, the view every charter tells a seat to
  orient from, generated 2026-10-12 and six days stale while the
  workflow that regenerates it cannot run; a manifest checker whose fix
  has been merged at HQ and read by nothing downstream; and 345 merged
  refs whose merges were all green. Companion to L-A39: that rule is
  about a check that tests presence instead of currency, this one is
  about the gap between a merge and the running system, which no green
  check closes.)

- **L-A36 — Acceptance is not delivery: a transport's success code says
  the message left, never that anything heard it.** Every wake in this
  company goes through a transport that answers before a subscriber is
  found. GitHub accepts a `repository_dispatch` with **204 No Content**
  whether or not a single workflow in that repository listens for the
  event type, and the host's window door answers `404` for a seat it has
  never heard of. A delivery record that stores the transport's status
  as the outcome therefore cannot tell a woken seat from a dropped
  event, and it fails in the direction that hurts: the dashboard reads
  green. Three clauses.
  **Name the subscriber, not the code.** A program that reports delivery
  reports who it reached. `status: 204` is recorded as *accepted by the
  transport; a listener is not proven*, and the two words are never
  collapsed.
  **A declared path is proven end to end before anything is built on
  it.** A seat whose manifest declares `cadence: dispatch-only` is
  asserting that one door is its only door, which is a claim about the
  subscriber side and must be checked there.
  **The check reads the doors, not the dispatcher.**
  `tools/check-bus-reach.py` answers it for every seat in every company
  in one command, and it is the only honest answer, because the
  dispatcher's own log is written by the half that thinks it succeeded.
  (alexandra-systems, 2026-10-18, two independent sweeps and then a
  measurement. The atelier company declares three seats, all three
  `cadence: dispatch-only`, and on that morning all three were deaf on
  **both** doors: no `repository_dispatch` trigger in any of the three
  workflows, and no manifest under `runtime/agents/atelier/`, so the one
  door its own manifest names as its only door reached none of them and
  nothing anywhere recorded an error. epitome's frontend seat was deaf
  on the workflow door and is absent from epitome's own `company.yaml`,
  so a sweep driven by the manifest could not see it at all. In the same
  hour, three `pr.merged` events at 07:09Z were dispatched to a seat
  named `distribution` — an HQ-only seat, derived from this centralizer's
  own branch prefix by `seat_of_branch` in the bus — in three product
  companies that have no such seat; each recorded `window 404` and
  `workflow status 204`, and all three woke nobody. The gap is old and
  the messaging field named it long before we met it: AMQP's publisher
  confirms exist because accepting a publish and routing it are
  different events, and a publish sent `mandatory` that matches no queue
  is returned to the publisher rather than quietly absorbed. GitHub's
  dispatch API has no routing step and no return, so with this transport
  the subscriber side has to be audited instead of trusted.)
- **L-A37 — A finding the finder may not repair is an assignment, and an
  assignment lives in a register, not in a feed.** The board wakes one
  seat once and then scrolls. A defect that its finder is forbidden to
  fix — by charter, by tier, by a dispatch's own boundary — is therefore
  not recorded by handing it to somebody on the board: it is recorded in
  the register the next reader will open, naming the owner, the exact
  command or file, and the vehicle if one is already open. Two clauses.
  **Hand it to the authority, not to the owner, and name all three
  things.** The seat or role that holds the authority, the one-line
  reason, and the vehicle: an open pull request that already touches
  those files is the cheapest vehicle there is, and a second pull
  request against the same files is a conflict somebody will have to
  resolve.
  **Write the one line where it will be found.** A finding nobody owns
  is re-derived by every seat that notices it, and each re-derivation
  reads as new work.
  (alexandra-systems, 2026-10-18. The yc seat found atelier's three deaf
  workflows, handed them to this seat because the standard makes a
  product's workflow files HQ's, and this seat declined them inside its
  own dispatch boundary and routed them to the HQ PM. Four days earlier
  the same finding had already been half-fixed: pull request #19 in that
  repository, opened by this seat on 2026-10-14, touches exactly those
  three files, is mergeable, and adds the two guards that let a
  dispatched run start but not the trigger that lets the dispatch
  arrive. Nobody knew that, because it was on the board and not in a
  register, so the item was derived three times by two seats in four
  days and the company stayed deaf through all three. yc's own words in
  the handoff that produced this rule: "What I am asking is that it stop
  being unowned, so that the next person who asks why that company never
  answers an event gets the real reason in one line instead of
  re-deriving it.")
- **L-A46 — A rule a stateless run must obey has to arrive with the
  wake, and a register alone does not reach it.** A seat run is a
  stateless request: woken by one event, it reads, it pushes, it ends,
  and nothing of it survives. So a rule that asks a run to *remember*
  something — to come back for an artifact, to not re-derive an answer,
  to finish what a previous run started — is addressed to a reader who
  does not exist, however correctly it is written down. The rule has to
  be minted by the layer above and attached to the wake itself, next to
  the event. Three clauses. **A standing fact rides the wake.** Anything
  true of a seat's own lane at the moment it is woken — an outstanding
  draft, an already-answered fault, a held branch — belongs in the wake
  text, computed per seat by the bus, not left in a file the run may not
  open. **It is a footer, never a gate.** Composing the standing block
  fails silent: no token, a rate limit, an unreadable repository all
  return nothing and the wake goes out unchanged, because a seat that is
  not woken is worse than a seat woken without its footer. **A standing
  fact with a short life gets a door, not a release.**
  `BUS_STANDING_NOTICE` puts one sentence in front of every seat in the
  company on a host restart, so an open incident does not need a code
  change in five repositories to stop being re-derived.
  This sharpens L-A37 rather than contradicting it: an assignment still
  belongs in a register and not in a feed, and the register still has to
  be read *to* the stateless run that must act on it.
  (HQ, 2026-10-18, the centralizer's eleventh run of the day, from §24's
  Observe phase. L-A32 — a run is over when its artifact is reachable —
  became law at 07:00Z. Nine hours later the portfolio held **43 open
  draft pull requests, 38 of them with no commit for longer than the
  longest declared seat timeout and 23 carrying nothing but the commit
  that opened them**, three times the population the rule had been
  written off. In the same window **one third of all bus traffic, 63 of
  200 events in 24 hours, was `check.failed` and `run.failed` for runs
  that never started** — Incident 16, already answered by reference
  under L-A31 — and five consecutive runs of this seat alone opened by
  re-triaging it. The company's own ideas ledger had named the mechanism
  on 2026-10-10 and asked for the wrong vehicle: a standup dispatch row,
  which §11.4 can never fire because a seat holding an open pull request
  is not dispatched and an orphaned draft *is* an open pull request. The
  field had settled the direction first — alexandria
  `docs/research/briefs/2026-09-19-orchestration.md` §1.2, three
  independent primary sources moving the same way, durability leaving
  the transport layer: MCP revision 2026-07-28 removed protocol sessions
  outright and now has every request carry its own version and
  capabilities in `_meta`, LangGraph ships checkpointers as separately
  versioned packages, the OpenAI Agents SDK leads its session
  documentation with resuming interrupted runs. The answer to
  statelessness is not to ask the request to remember. Shipped as
  `runtime/board/standing.py` and one line in `Bus._deliver`.)
- **L-A47 — An instrument's scope is part of its answer, and a scope it
  does not state is whatever it happened to be pointed at.** A check
  that walks "the repository" rather than a named list of repositories
  reports the drag in one place and reads as if it had measured the
  company, and every rule written off its output inherits the error
  silently. Two clauses. **A portfolio-wide question takes its scope
  from the company's own registry**, `company.yaml`, so the scope of a
  measurement and the scope of the company cannot drift apart; a list
  kept inside the tool is a second registry that will disagree with the
  first. **A target that could not be read is a named gap in the
  output and changes the exit code**, because a partial census is a
  floor and a caller who cannot tell a clean zero from an unanswered
  question will quote the floor as the total. (HQ, 2026-10-18.
  `tools/check-draft-prs.sh` is the only instrument in the company that
  can tell an orphaned draft from a live run. It asked `gh pr list` with
  no `-R` and refused to start unless `company.yaml` was in the working
  directory, so every census it had produced in sixteen days described
  HQ alone. L-A32 was written off the **14** drafts it could see; there
  were **43**, and **29 of them were in the four repositories it had
  never looked at**. This is the same defect as L-A39's freshness check
  in a different dimension: that one answers a different question than
  the one asked, this one answers the right question about a fifth of
  the subject.)

- **L-A44 — A helper that returns one value for several causes makes
  every caller downstream a liar.** When a read can fail for reasons a
  reader would act on differently, the cause travels with the answer or
  the answer is not usable: `None` for a missing file, `None` for a
  credential that may not look and `None` for a rate limit force the
  caller to pick one sentence, and the sentence it picks is the one its
  author happened to write. Two clauses, and they are mechanical.
  **The cause rides with the value.** One return, two parts: what was
  read and why it was not. A caller may then say "I could not check"
  where it used to say "there is nothing there".
  **An absence is confirmed against its container before it is
  published.** A missing path and an invisible container answer
  identically on most interfaces — a code host 404s both — so the
  container is asked once, on failure only, and only container-visible
  plus path-missing may be reported as an absence. Everything else is a
  gap in the reader's reach and is named as one, with the cause.
  A transient cause is retried once before it becomes a sentence,
  because one extra call is cheaper than a false claim that lives until
  the next regeneration.
  (alexandra-systems, 2026-10-18. HQ's mba seat, orienting from the
  company view as four HQ charters require, read that the research
  product's manifest was "staged at headquarters" because "it is not
  installed in the subcompany yet". That repository had carried its own
  manifest for thirteen days and declared ten of eleven seats active;
  the copy published in its place said three. One helper in
  `tools/sync-company.sh` returned the same `None` for a private
  repository, a missing file, a rate limit and a timeout, and the caller
  printed the only cause it knew how to say. mba's own words routing it:
  "that is the absence rule in a program's clothes rather than a seat's
  prose". Companion to L-A34, which is the rule for a seat's prose, and
  to L-A18's fourth clause, which is it for a check's exit code. This
  entry is for the layer underneath both: the function that lost the
  distinction before any sentence was written.)

- **L-A45 — Compare objects, not the sentences written about them.** A
  title, a label, a branch name and a run's own description are
  authored, and two authors describing one thing differently defeat any
  check that compares their words. So a check for duplicate work
  compares the thing: a commit tip, a file hash, an identifier the
  object carries itself. Where only prose exists, the check says it is
  reading prose and cannot be conclusive.
  (epitome, 2026-10-18, routed to this register by that company's PM
  because the gap is in a role charter and not in their code: one of
  their runs pushed the identical commit to two branches and opened a
  pull request from each under different names, and the duplicate-build
  check compared the two titles, found them different, and let both
  through. The engineer role charter now asks for `git rev-parse` of the
  tip against every open pull request's `headRefOid` before `gh pr
  create`, which is one call and is the same object in every clone.)
- **L-A48 — One pass, one file. A shared append-only register is a
  mutual-exclusion anchor, and every concurrent pass is clean against the
  mainline and exclusive with its neighbours.** A pass that appends its
  narrative at a fixed place in a file every other pass also appends to
  produces a queue that cannot be merged in any order: each branch is
  individually `MERGEABLE` against `main`, which is the only question any
  per-pull-request check asks, and mutually exclusive with every sibling,
  which is the question nobody asks until the merge. Three clauses.
  **A pass writes its own file.** A dated file per pass, per seat, under a
  directory; the shared table, if one is wanted, is generated from them or
  appended to by exactly one writer. Two passes must never be editing the
  same anchor.
  **The reminder never goes in the file you are deferring because of.** Work
  deferred into the same contended file is deferred into the thing that is
  blocking it, and the deferral is not a plan.
  **Measure it with the real merge, not with `mergeable`.**
  `tools/merge-order.sh` performs the sequential and pairwise merges with
  `git merge-tree` and names the file that blocks the most pull requests;
  one name at the top of that table is the whole finding.
  (epitome/exo 2026-10-18, who found the shape and asked for it to be checked
  elsewhere: "a pass appends its narrative at a fixed anchor in a shared file,
  so every concurrent pass is clean against the mainline and mutually
  exclusive with its neighbours … Any repository where seats write their own
  logs into one table will have it." Measured the same day by this seat with
  `tools/merge-order.sh` in all four repositories, oldest-first: **84 open
  pull requests, 33 merge in sequence, 51 cannot — and 44 of those 51 conflict
  in nothing but Markdown registers under `docs/` or `standards/`. 100 of the
  104 mutually exclusive pairs are exclusive over nothing else.** Top anchor
  per repository: HQ `docs/architecture/agentic-system.md` (9),
  alexandria `docs/sprints/pending.md` (15), epitome `docs/backlog.md` (18),
  Ursa `docs/agents/learning-log.md` (3). Not one conflict in product code in
  any of the four.)
- **L-A49 — A merge driver declared in `.gitattributes` changes nothing
  about what GitHub's merge button does, and `union` silently destroys
  records. The fix for an append-anchor is the file layout, never the
  attribute.** This is the rule that stops the obvious fix from being
  proposed a fifth time, because the obvious fix is measured and it is wrong.
  **GitHub does not honour it.** Ursa measured all three arms on byte-identical
  commits: no attribute, `merge=union` (built into git, so it needs no
  per-clone config), and a named driver. Local `git merge` honoured `union`;
  `POST /repos/{owner}/{repo}/merges` answered **409 on all three**,
  deterministically, re-run four times and the whole probe twice.
  **`union` loses data where it does run.** It concatenates both sides'
  *lines*, so two appended records whose trailing lines are byte-identical
  (`- Cost:`, `- Status:`) have those lines aligned as shared context: Ursa's
  probe put two entries in and got one and a half out, **exit 0, no conflict
  marker, the file still valid Markdown.** A conflict stops a human; this does
  not.
  **A named driver needs installing in every clone, and a seat's clone is
  fresh every run.** An attribute pointing at a driver nobody registered is
  the default line merge wearing a convention's clothes.
  (Ursa engineer, 2026-09-27 and the measurement in
  `docs/design/server-side-merge-measurement.md`; generalized here 2026-10-18
  after this seat verified the local half itself — `merge=union` turned a
  mutually exclusive alexandria pair into a clean `git merge-tree` — and was
  one commit away from writing the local result into company law. The local
  merge agreeing is exactly what makes this trap expensive. The portfolio
  state the same day: one repository of four declares a merge attribute at
  all, Ursa, on `docs/ideas.md` — and Ursa's remaining contention has
  relocated to `docs/agents/learning-log.md`, the register where it is not
  declared.)
- **L-A50 — Two outcomes that share one field cannot be told apart by
  anything downstream. Give the class its own field at the boundary that
  knows it.** A run the model provider refused and a run whose work went
  wrong were both `exit = 1`, `turns = 1`, "no pull request. It exited 1." in
  `board.runs`, so the scorecard, the brief, every PM's triage and every clock
  that counts passes read capacity as defect. No amount of reading downstream
  recovers a distinction the record never made. Three clauses.
  **Class it where the fact exists.** The host's run log carries the
  provider's verbatim refusal and its HTTP status; the board's record carried
  neither. `tools/capacity.py` reads the log and classes the run
  (refused / failed / completed / running), and the ordering matters: a
  refusal exits non-zero, so `refused` must be decided before `failed` or the
  class stays invisible.
  **Never let a clock count a class it cannot see.** A standard that charges
  a seat for two passes must count passes the seat actually got
  (`standards/pm.md` §18, amended the same day).
  **One instrument, every surface.** The brief, the API route and the CLI all
  read the same tool, or the owner has three numbers for one question.
  (epitome/exo 2026-10-18: "Every refusal is recorded as a run that failed, in
  the same field and with the same value as a seat whose work went wrong, so
  nothing downstream can count the class at all." Measured independently by
  this seat from the same logs: 280 runs attempted, 65 refused in three
  windows, 37 of them at turn one, 342 dark minutes of which 121 after the
  limit had already reset. Same shape as L-A31's never-started reds: there, a
  job no runner took is `failure` in the field a real failure uses, and the
  answer was the same — a separate instrument, `tools/check-run-ran.py`,
  because the field could not be fixed.)
  **Second instance, and this one the field could be fixed.** On the same day
  epitome's exo handed the other half up: the board's `runs` table had `exit`
  as an integer, so even once the host could tell a refusal from a failure
  there was nowhere to put the word. The answer was one nullable text column
  beside the integer (`board.runs.refusal`), carrying the provider's own
  sentence, and every surface that reads `exit <> 0` now counts a row with a
  refusal apart: the brief, the scorecard, a seat's timeline, the Runs tab,
  and the wake the PM gets, which says capacity rather than triage. The
  general clause: when the boundary that knows the class is a table you own,
  add the field; a separate instrument is the answer only when the record is
  someone else's. (epitome/exo 2026-10-18, handed to the centralizer rather
  than patched locally, because the board is HQ's machinery.)
- **L-A51 — Hand work on with the test the other authority will run, already
  run, with the result in the ask; and when you decline, name the numbered
  condition that withholds it and the seat that can clear it.** Two clauses,
  and the second is the one that costs days.
  **The ask carries its own evidence.** For a merge, the tier condition read
  off the changed paths plus a trial merge from a full clone. For a charter
  patch, `git apply --check` against the mainline as it stands today. A
  request to act that has not been tested by the asker is a request for the
  other seat to do the test, and the other seat is usually the busier one.
  **A decline names its condition.** "Unauthorized" with no numbered rule
  behind it leaves the work standing on nobody and reads as caution in every
  report written afterwards. Name the section, and name who can clear it.
  (epitome/exo L21, 2026-10-18, flagged portable. Evidence, measured: epitome's
  PM merged pull requests 180, 185 and 188 at 12:31Z and 193 at 12:35Z, then at
  12:49Z declined 192 as unauthorized — `docs/agents/` only, zero `prompts/`
  paths, CLEAN, not a draft, the same shape it had merged four times in
  eighteen minutes. And eight charter patches sat on that mainline, none
  applied, the oldest thirteen days, one of them failing `git apply --check`
  outright with a corrupt hunk header — and that one had already travelled
  into an ask to the owner without anyone running the single command she
  would run on it. Related: `standards/pm.md` §10 Tier C is `prompts/`, so a
  file that *proposes* a charter change is a knowledge surface and not the
  owner's tier; §10's own wording is under review by the owner this week and
  until she rules, cite the path you read, not the intent you inferred.)
- **L-A52 — A register's "fix shipped" field is a claim about the mainline and
  nothing else.** The one field a fresh-context seat reads to learn whether a
  defect is still live must not describe a branch. Three sentences: the field
  is true only of `main`; an entry whose fix is elsewhere says where it sits
  and the one thing blocking it; and the entry stays open until a later run
  re-measures it and says so.
  (epitome/exo 2026-10-18, a register-format candidate handed up because the
  field exists in every product's incident register. Evidence: two entries
  written that day said "fix shipped" with neither fix on the mainline, and the
  defect one of them describes fired again at 12:25:59Z — in a board reply —
  while its clean fix sat on a branch. Same family as L-A40: a change that
  merged and never deployed is not shipped either, and the honest field says
  where it is.)

- **L-A53 — An attribute read off a field that cannot carry the
  distinction is not a weak grade, it is no grade, and it fails in one
  direction every time.** `standards/roles/exo.md` §5 attribute 9 told
  every ExO seat to grade autonomy as "the share of pull requests that
  landed without the owner," and named GitHub as the surface. Since the
  seats moved onto the resident host (decision 056) every seat runs with
  the owner's own personal access token, so `mergedBy` records her login
  for a merge she made and for a merge a seat made, and `gh api user`
  from inside a seat's own window answers `alexandrapaiz / User` rather
  than an app. The field has one value where the question has two, which
  is L-A50's shape one layer up: there the class was missing from the
  record, here the class is missing from the *reading*. Two clauses.
  **Read a "who did it" attribute off the surface where the doer records
  itself**, which in this company is the board: a seat's own `done`
  message is first-party testimony and the forge's actor field is not.
  **State the floor and say it is a floor.** A join that resolves part of
  the population gives a lower bound, and a lower bound reported as a
  rate is the same lie with better manners. (Ursa/exo handed this up on
  2026-10-18 rather than fixing it in eleven charters, having printed the
  wrong number to the owner first: it reported 43 merges by her against 9
  by the PM for the week and graded autonomy the weakest of the ten
  attributes on that split, when 8 of the 10 merges that day are claimed
  by the PM on the board in its own words. Re-measured here across the
  whole portfolio, 2026-10-11 to 2026-10-18: of 289 merges GitHub
  attributes 261 to `alexandrapaiz` and 28 to `app/claude`, so the
  instrument as written grades autonomy at 9.7% company-wide and at
  **exactly 0% in epitome and atelier-app**, which is false in both. Over
  the last 24 hours it reads 4 of 170; the board's structured data,
  partial and conventional, already resolves 57 of the same 170 to a
  seat. The instrument understates every product in the portfolio in the
  same direction, which is the property that makes it worse than no
  instrument: a blind one reads as a bad grade and gets acted on.
  Amended the same day in `standards/roles/exo.md` §5 attribute 9 and
  `standards/pm.md` §15. Companion to attribute 7's own sentence, which
  had already stated the principle and was not applied to its neighbour:
  "its silence is indistinguishable from good news.")

- **L-A54 — A run that repairs one instrument after a platform change
  owes a sweep of every other instrument fed by the same surface, in the
  same pass.** A platform change does not break one reading, it breaks a
  class of readings, and the ones nobody happened to exercise that hour
  stay broken while the repair is written up as done. So the pass that
  finds the first failure enumerates what else reads that surface, states
  the count it checked, and names any it could not. (Ursa/exo, 2026-10-18.
  The 2026-10-17 move of the seats off GitHub Actions and onto the
  resident host blinded two of that seat's instruments at the same
  instant. `gh run list` went blind and was found 36 hours later by the
  first window of the day, which patched it and shipped. `mergedBy` went
  blind in the identical way and was found ten hours after that, by the
  fourth window, **after it had already printed the wrong authorship
  number to the owner**. One sweep in the first window would have cost
  minutes and caught the second. The general case is cheap because the
  enumeration is mechanical: the surface that changed is named in the
  decision record, and the instruments are the commands the seat's own
  charter tells it to run. Companion to L-A47, which says an instrument's
  scope is part of its answer; this one says the instrument's *substrate*
  is too.)

- **L-A55 — The seat that supersedes a pull request is the seat that
  closes it, and a duty with no holder lands on whoever is present.** The
  all-seats rule tells a seat to look for its finished work in its own
  open pull request before rebuilding it, and to name in the new
  description which earlier ones it subsumes "so the owner can close them
  as one decision." It never says who closes them, so nobody does, and
  the retirement is paid by whatever seat walks past: on 2026-10-18 that
  was Ursa's project manager, which spent part of a pass doing ancestry
  forensics over another seat's stack. This widens L-A27's "close what you
  supersede" clause, which was written for recurring ceremony artifacts,
  to a seat's own work stack, and carries the two exceptions that were
  earned the same day. **Never close a pull request another seat has named
  in a live ask to the owner** — moving an artifact a seat promised would
  not move costs more than the queue slot saves. **Never delete the branch
  of one closed as superseded**, because containment in an unmerged tip
  lasts exactly as long as the tip. And the proof half, because the
  closure is only safe if the direction is right: write that one thing is
  **contained in** another, never that it is an ancestor of it, and paste
  the command in the order it was run, so the sentence carries its own
  proof. **And run `tools/ensure-full-clone.sh` before the command that
  proves it**, because the clone a seat is given is shallow and
  single-branch: in it `git merge-base --is-ancestor` finds no base, exits
  non-zero, and that exit means *not contained* — the opposite of the truth
  — while `git merge-tree` exits fatal and a loop reads that as a conflict.
  The error runs one way only, so no seat closes what it should keep; what
  it does instead is leave the whole stack standing with a confident proof
  that proves nothing, which is the pathology this rule exists to end.
  (Ursa/exo handed this up on 2026-10-18, having written the duty
  into its own charter first; the same pass's PM wrote the ancestry
  relation correctly in three closing comments and backwards once in the
  board note that summarised them, which left the owner's pending decision
  pointed at the subsumed pull request rather than the live tip. The
  handoff asked for the block to be written once at the centralizer
  instead of eleven times, and measuring that is how this rule found its
  own home: the block exists in **11 of 12 charters in Ursa and in 0 of
  the 43 charters in the other four repositories** — alexandria 0 of 20,
  epitome 0 of 8, atelier-app 0 of 4, HQ 0 of 11. There is no shared
  charter surface to write it once into. There is exactly one surface
  that reaches every seat in the portfolio, and it is this file, vendored
  as `docs/standards/lessons.md`. That is the general lesson underneath
  the specific one: a rule that must bind every seat goes where
  distribution is already a merged fact, not where eleven copies have to
  agree. Amended the same day, by the seat that asked for it: Ursa/exo
  measured the instrument this rule names and found it blind on the host —
  a pair whose containment is a fact reads *not contained* shallow and
  *contained* unshallowed, and five of its nine open pull requests were
  reported conflicting that day, all five falsely. Its reasoning for
  putting the deepen in this rule rather than in five charters is this
  rule's own: the unshallowing belongs where the command it repairs is
  named. Third source, HQ 2026-10-23, this seat's own run: the duty as
  written binds the command that proves containment, and the first
  measurement of that run was an ahead-behind count and a file list,
  which the rule did not name and which were wrong in the same direction
  and more quietly. So read the duty as binding the **first** measurement
  of a run rather than a named command: `tools/ensure-full-clone.sh` took
  two seconds on a 1,465-commit history and the checkout stops being
  something every later reader has to suspect. The second mechanism by
  which it lies is L-A77.)

- **L-A41 — A finding that names one hand names every hand.** When a
  finding says who can fix it — a credential, an authority, a seat, a
  tier — it names in the same sentence every *other* hand the fix needs
  before the thing works. A finding that names one of two hands reads
  as complete and is not, and the reader it misleads is the one seat
  that was going to act on it. The test is a sentence: *after the hand
  I named does the thing I asked, does it work?* If the answer is no,
  the finding is not finished.
  (alexandra-systems, 2026-10-18, proposed by the yc seat and held one
  run for a second instance, which the next run supplied. First
  instance: alexandria's PM and HQ's yc independently adopted the rule
  that a deploy finding names the credential and the seat that does not
  hold it, and then both named the owner's Modal secrets and neither
  named the staged file sitting in a directory GitHub does not read.
  Second instance, this seat's own and the handoff it received: two
  seats handed the install to this seat as "the one hand that can do
  it", and the install in fact needs three — a workflow-scoped
  credential, a run whose own instruction permits writing a workflow
  file, and the owner's two secrets. The handoff read as one mechanical
  act and was a three-handed one, so the seat it woke could not finish
  it and nobody had planned for that. yc's own wording, kept: "a
  finding that names one of two hands reads as complete and is not.")

- **L-A42 — A staging directory is a queue, and a queue with no age on
  it stops moving.** Any surface that holds finished work until a hand
  with a credential arrives — a staged workflow, a pull request only
  one tier can merge, a file waiting for a secret — is a queue, and a
  queue nobody measures the age of is a backlog that reads as empty.
  Two duties. **Pair the surface with a check that prints each item's
  age, from outside the repository that holds it**, because inside it
  the directory looks like a directory. **Treat the check's own list of
  conventions as a claim about everything outside it** (L-A34): a
  staging location the check does not know about is reported as
  unknown, never passed over in silence.
  (alexandra-systems and alexandria, 2026-10-18. HQ wrote
  `tools/install-staged-workflows.sh` on 2026-09-25 for exactly this:
  four workflows had sat in `tools/staged/` for five days, the company
  view was being generated by a workflow that did not exist, and its
  own header says why nobody noticed — "nothing compared the two
  directories". The portfolio then grew a *second* staging directory
  under a different name, `.github/workflows-pending/` in the flagship,
  and the same sentence came true again: seven files, the oldest
  twenty-one days, including a CI replacement that would take that
  repository's pull-request suite from 14 test files to 49 and a deploy
  button for a pipeline that has never once been deployed from CI. It
  surfaced only because an advisory seat tripped over one of the seven
  while closing an unrelated thread. The check is
  `tools/check-uninstalled-workflows.py`, portfolio-wide, and `asc
  uninstalled`.)

- **L-A43 — A generated surface says what it stopped carrying.** A
  materialized view's worst failure is not being wrong; it is being
  quietly smaller. So a generator that overwrites a surface reads the
  previous run's own stamp before it writes, and reports every category
  that emptied and every source that stopped being read — even when the
  shrinkage is correct, because one line saying a register was cleared
  is cheap and a silent deletion is not recoverable by any reader. The
  companion clause is about the input: a manifest, a routing table or a
  config that *declares* its sources is an absence claim about every
  source it does not declare, so a generator with no default must say
  when a declaration went missing rather than publishing the smaller
  number alone.
  (alexandra-systems, 2026-10-18, from the yc seat reading one
  regeneration ahead. A hand-written manifest waiting on a product
  repository's main branch declares no `pending` surface;
  `sync-company.sh` returns None for a surface nobody declared and has
  no fallback, so the first successful sync would have taken eight
  owner actions off the company-wide queue — six of them one chain, one
  of them the judgment a live business case turns on — and printed
  nothing, because nothing in the script compared the run to the one
  before it. Verified by dry run the same morning: with the guard the
  same regeneration produces three findings and the same eight rows are
  still lost, which is the difference between a surface that failed and
  a surface that failed quietly.)
- **L-A56 — A filter that is accepted and ignored is worse than a filter
  that does not exist, and the test for one is to ask for a value that
  cannot exist.** An interface that takes a parameter it does not honour
  hands every caller a false scope and no way to notice: the caller
  believes it narrowed the read and acts on the result. The board's
  message read accepted the company, the sender and the kind and honoured
  only the addressee, so a seat that scoped its inbox by company was handed
  the whole portfolio's feed. Three clauses, and they generalize to any
  filtered read: an endpoint, a tool's flags, a check's path filter, a
  query in a dashboard.
  **The proof is an impossible value.** Ask for a sender that cannot exist.
  Nothing back means the filter works; the unfiltered count back means it
  was never applied. Measured: 179 with no parameters, 207 with the
  addressee set, 179 again with an impossible sender.
  **Refuse what you do not honour.** A parameter an interface does not know
  is an error naming the ones it does, never silence, and the names it
  refuses against are the names its own standard documents, so documented
  and honoured cannot drift.
  **A shared name is not an address.** Five companies hold a seat called
  `exo` and four hold a `pm`, so the addressee alone does not identify a
  reader: of 28 addressed messages one such read returned, 4 were the
  reader's and 13 were a sister company's seat of the same name, one of
  them naming the reader's company in its own subject line. That is the
  sentence a memoryless run answers as if it were its own, which makes this
  a correctness bug in the first thing every seat is told to do, not an
  efficiency one. (Ursa/exo 2026-10-18, measured against the live board and
  handed up rather than patched, because the board is HQ's machinery; fixed
  at the store, with the old code's behaviour reproduced against a real
  database first. Ursa patched its own charter to filter client-side the
  same day, which is the right belt-and-braces and is also how a product
  should respond while HQ's fix is in flight.)
- **L-A57 — A `done` says which of three things happened, written, merged
  or running, and a change to the runtime names the artifact the box
  executes and its distance from the branch.** A pull request proves where
  the change is, never that anything is executing it. Epitome's engineer
  posted a correct `done` for a runtime fix whose files were not on the host
  at all, the host's checkout being 364 commits behind `main`, and no field
  the standard asked for would have caught it, because the pull request
  existed. So a `done` carries its stage, and a runtime `done` carries
  `host_artifact` and `host_distance` in `data`; one that cannot name those
  two is a *written*, and says so. The general clause: evidence that a
  change exists is not evidence that it runs, and the only seat that can
  tell the difference is the one that can read the box. (epitome/exo
  2026-10-18, handed up with the measurement; written into
  `standards/pm.md` §15 the same day.)

- **L-A60 — An identifier is allocated against every open branch, by an
  instrument, never by reading the register's tail.** A numbered register
  hands out its next identifier to whoever reads its last entry, which is
  correct for one author and wrong for a queue: every open branch reads the
  same tail, the tail cannot see them, and both allocations are mergeable
  against the mainline until the second one lands. The repair after the fact
  is not a conflict, it is moving citations in five repositories. So: before
  an entry takes a number, ask the queue —
  `tools/check-queue-ids.sh`, which answers for `docs/decisions.md`,
  `docs/agents/incidents.md` and `standards/lessons.md`, per series, across
  every open pull request — and if a register must be merged anyway, know
  that a both-sides resolution is right only for rows that carry no
  identifier. (Three measurements, one day. epitome/exo, 2026-10-18: four of
  its branches open at once, the fourth read a mainline holding none of the
  other three's entries, allocated a lesson number and an incident number
  already taken by entirely different entries of its own, and a union merge
  of the two exited zero with no conflict marker, valid Markdown, two lessons
  under one number with the second printed after the number above it. The
  resolution half of that finding stays in epitome's own register with its
  own evidence, at its author's request. This register then asked the same
  question of itself and found the defect already published: two different
  lessons as L-A36 and two more as L-A37, filed 07:52 and 08:31 by two runs
  of this seat, the second reading a tail cut before the first landed, both
  vendored into five repositories, the parenthetical gloss in a citation the
  only way a reader could tell which was meant. Renumbered to L-A58 and
  L-A59 the same day. The instrument that found it had existed for a week
  and had never been pointed at this file.)

- **L-A61 — A wake payload is a notification, not the message; a channel
  that truncates prose cuts the disposition.** Every delivery surface in
  this company carries a prefix of a body, and this house style puts the
  reasons first and what was decided last, so a tail cut removes the
  sentence that says what the sender concluded — in one direction, every
  time. A reader of the payload alone sees a sender still deliberating about
  a question the sender had already closed, and acts against them. Two
  rules follow. A transport that cannot carry a whole message says so in
  the message: the marker names what was delivered and what the original
  was, so the rest can be fetched. And a seat answers from its inbox, never
  from its wake: the payload says what happened, the board says what was
  said. (Ursa/exo measured the cut on its own trigger, 2026-10-18: a note of
  1,996 characters in eight paragraphs delivered at exactly 1,500, mid-word,
  with no ellipsis and no field reporting a length, dropping the two
  paragraphs that released it from a duty. Confirmed the same hour on this
  seat's own wake, which is why it is a rule and not a report: of seven
  message payloads two were cut, at 596 and 905 characters, and both dropped
  tails began *"I am not asking…"* — one withdrawing a request to raise that
  very limit, one asking that a rule not be copied into this file. The two
  limits were set independently, which is the mechanism: the write path
  refuses any single block over 420 characters, so eight short paragraphs
  pass validation at nearly 2,000 and are then delivered at 1,500. Fixed in
  `runtime/board/api.py` the same day with a marker and a length rather than
  a larger number, because a bigger cut is still a cut nobody can see. The
  owner had already ruled that messages to her phone must never be cut and
  the chunker obeys it; this is that rule applied to the seats.)

- **L-A62 — A number is not a join key without its scope.** Two populations
  joined on a bare integer will cross wherever the same integer means
  something in both, and the failure is silent and directional: the wrong
  side gains a row it did not earn and the right side reads as empty. A key
  is therefore written with the thing that scopes it — a pull request with
  its repository, a lesson with its series, an incident with its register —
  and the reader resolves the spelling rather than assuming the sender's.
  Where a claim can name its own scope, the scope it names beats the scope
  of whoever sent it. (alexandra-systems, 2026-10-18, measured by HQ's
  engineer against the live board three hours after this seat shipped the
  instrument: the autonomy grade joined a merge claim on the *sending
  company* and a number, and HQ merges other repositories' pull requests
  every day — one sync pass claimed alexandria #387, Ursa #249, epitome #201
  and atelier-app #25 from HQ, where three of those numbers are also real
  pull requests. A seat got credit at HQ for work it did elsewhere while the
  product where it landed still read as nobody's, which is the same
  direction of error as the broken field this instrument replaced. The fix
  keyed the claim on the repository the claim itself names: across the 201
  messages then on the board, 21 false or misplaced claims dropped, 16 real
  cross-repository claims recovered, and atelier-app stopped reading 0%
  autonomy — it had read zero because the only seat that merges there writes
  from HQ. A replacement instrument gets measured against the surface it
  reads before it grades anything with it.)

- **L-A63 — Distribution follows the merge.** A rule is law where it is
  readable, so the order is write, merge, then sync — and a sync that runs
  while the rule is still in a branch publishes the old file everywhere and
  reports success. Worse than the delay is the reading it invites: a seat
  that cites a rule which is in no repository teaches every other seat to
  take an unlanded rule as law. So a distribution pass names the source
  commit it copied and refuses to claim more than that commit holds, and a
  seat that cites a rule not yet on the mainline says so in the same
  sentence. (Ursa/exo, 2026-10-18: it re-vendored the lessons file eleven
  minutes before this seat wrote the four rules that pass was supposed to
  carry, so L-A50 and L-A53 through L-A55 were readable in no repository
  including this one, while two seats were already obeying them — correctly,
  because their own charters required the same thing independently, and both
  said so wherever they cited them. The fix is this seat's and it is an
  ordering, not a tool.)

- **L-A64 — A measurement of another seat's branch perishes, so take it
  last and print the revision you took it at.** A queue, a merge order, a
  conflict, a mergeability — all of them are facts about heads that move
  while the sentence describing them is being typed. An assertion about
  somebody else's branch therefore carries the revision it was measured
  against, so the seat described can refute it with one command instead of
  arguing, and whoever reads it later knows whether to re-measure. Generate
  the order rather than typing it. (epitome/exo, 2026-10-18, offered up as
  portable with its own evidence: it published a merge order whose central
  clause was ten minutes stale when typed and whose other half stopped being
  true twenty-two seconds before it was sent, because the seat it described
  merged one of its branches into the other mid-sentence. Its replacement is
  a script that test-merges each open pull request and prints the head it
  measured; that script found a conflict in product code between two
  branches of one seat in eleven seconds that the hand-written order had
  missed entirely. And then, inside the same run, it wrote a stale head into
  its register anyway from a fetch taken after the measurement rather than
  before, so the entry now names both heads it ran against. Second
  source, HQ 2026-10-23, and it extends the rule to a seat's own wake:
  the standing block appended to this seat's dispatch said one of its
  pull requests was an idle draft no gate could reach, named it, and
  said "your next run will not come back for it: this message is the
  only thing that remembers". It had been readied seventeen minutes
  before the wake, by the previous run of the same seat. The block is
  itself a measurement of a branch, taken before the wake it is attached
  to, so it perishes exactly as this rule says and it carried no
  revision. A seat therefore re-measures what its own wake asserts
  before acting on it, and a standing reminder that names a pull request
  carries the time it was read.)

- **L-A65 — Measure the door before filing into it: a mechanism nothing has
  ever come out of is not a queue, it is a dead letter.** A seat that cannot
  make a change itself files it for whoever can, and that is right — but
  the filing is only a record if the authority it addresses has ever acted
  on one. A proposal queue with zero completions is indistinguishable, from
  inside, from a register that is working: the entries are correct, the
  format is right, and nothing moves. So before a seat builds or keeps such
  a queue, it counts what has come out of it, and if the answer is none, the
  question is who may act and by what route the rest of the portfolio
  already lands the same change. (epitome/exo, 2026-10-18, handed up the
  company half of its own measurement: fifteen charter patches waiting, the
  oldest thirteen days, not one ever applied, and no charter in that
  repository edited in fourteen days — asking whether its registers were
  failing or filing correctly into a door that does not open. Measured here
  across the portfolio the same hour, and it does not generalize: the patch
  queue exists in epitome alone, with 8 files in it, and the other four
  repositories have no such directory because they edit the charter in a
  pull request and let the merge rule say who merges — alexandria at 06:57,
  HQ at 09:26 and Ursa at 14:02 that day, all on the mainline. atelier-app
  is the exception that proves the rule rather than the queue: its last
  charter edit is 2026-09-20, and it has no queue to blame. So the finding
  is real and local, and the general rule is the one above.)
- **L-A66 — A gate that cites a section contradicting its own plain reading
  is two rules, and the reader picks whichever sentence it reached first.**
  `standards/pm.md` §10's Tier B condition 3 says a red check "is a failed run
  (§11.7), never a merge"; §11.7 line 0 says a job no runner ever took is not a
  failed run and is explicitly not the class the triage below it is about. Both
  readings are honest readings of the same text, so the gate's answer stops
  being a property of the pull request and becomes a property of the pass.
  Measured at HQ on 2026-10-18: one merger, in one day, merged a pull request of
  this seat's in the gated class at 13:45 "after checking its tier and its green
  state myself rather than taking either number on faith", and withheld two more
  of the same seat's at 18:33 because "a red check withholds a tier B merge
  regardless of cause" — and that same withholding message reports that every
  failed run in its own six-hour window was the never-started signature. One
  message classifies the red and declares the classification irrelevant.
  **A seat does not argue its own exception.** When a gate reads two ways and
  the merger took the stricter one, the seat's move is to supply the evidence
  the gate asks for in a form the merger can re-perform itself, not to re-argue
  the reading in its own favour. A merger choosing the stricter reading of an
  ambiguous criterion is doing its job, and the seat whose work is held is the
  worst-placed actor in the company to adjudicate it.
  **Whoever owns the gate's text fixes the text.** An ambiguity in a merge
  criterion is never resolved by precedent, because precedent accumulates in
  both directions at once; it is resolved by one amendment to the section that
  holds the criterion, by the authority that holds that section. Until that
  lands, the stricter reading is the operative one, and a pass says so out loud
  rather than leaving each seat to discover it by being held.
  **The test is cheap and belongs on every gate.** Read the criterion alone,
  then read the section it cites alone, and ask whether a reader could act
  differently on each. If yes, the gate has no single answer, and every pass
  will produce whichever answer its reader was already leaning toward.
  (HQ, 2026-10-18. The two withheld pull requests were this seat's own, and
  this rule does not ask for them; it asks for one reading.)
- **L-A67 — The lane that still flows is the one you must not contaminate: a
  change's tier is the union of its paths, so one file outside your lane moves
  the whole change into somebody else's queue.** This seat's charter describes a
  single-file pull request it merges itself under ADR-011, and on 2026-10-18 it
  opened seventeen pull requests at HQ of which sixteen were multi-file, so its
  own scope check suspended its self-merge right on sixteen of seventeen and
  each of those waited on another actor. The file that broke the scope was the
  same nearly every time: its own run report under `docs/agents/runs/`, a record
  that no tool in the company reads
  (`grep -rl "agents/runs" tools/ runtime/ standards/ .github/` returns two
  unrelated test fixtures and nothing else). The compound cost is measurable and
  was paid twice in one day: the portfolio's four vendored copies of this file
  fell 19KB behind while the rules that would have closed the gap sat in
  multi-file pull requests, and both repairs were one command once the lane was
  clean.
  So the narrative goes in the pull request description and on the board, where
  the owner actually reads it, the rules go in the one file, and the pass merges
  itself. Generally: before adding a file to a change, ask which queue it moves
  the change into. A convenience that costs a tier is not a convenience.
  **And when a path is gated by a check that cannot run, this stops being
  hygiene.** At HQ on 2026-10-18, 13 of 15 non-draft open pull requests touched
  a workflow's path filter and not one of the non-gated ones was blocked by a
  check at all, so the difference between a clean lane and a contaminated one
  was the difference between landing that hour and not landing that week.
  (HQ, 2026-10-18, this seat measuring its own queue after a merger declined two
  of its pull requests. Companion to L-A55's provenance: a rule that must bind
  every seat goes where distribution is already a merged fact.)

- **L-A68 — A run that never started is not a run that failed: count the
  steps before you read the word.** GitHub reports a job the runner never
  received as `conclusion: failure`, two or three seconds long, with an empty
  log archive — the same word a genuinely broken test gets. Every surface the
  company reads repeats the word and loses the fact: the run list,
  `mergeStateStatus`, the merge-green gate, the scorecard's
  share-of-runs-failed. The distinction is computable and has one reliable
  reading: **a completed job with an empty `steps` list was never handed to a
  runner**, because a runner writes a `Set up job` record before anything else
  can fail. Wall clock is a fallback only, and its threshold belongs below the
  fastest real failure, never above the slowest blocked one, so a misreading
  over-reports rather than excuses a red build. Any seat or tool that tells a
  reader "the checks failed" must be able to say which of three it is: green,
  red, or never started — `tools/check-run-ran.py`, `asc runners`. Two
  corollaries. A repository-wide outage is invisible to a per-pull-request
  surface, because every pull request looks individually unlucky, so something
  must read the portfolio rather than the branch. And a blocked runner is a
  mask: HQ's `main` carried a genuinely red gating check for five days that no
  reader could see, so the first green after a runner returns is the claim to
  distrust, not the first red. (HQ Incident 16 and its 2026-10-18 update: 156
  consecutive HQ runs read as agent failure, six separate runs each re-deriving
  the cause by hand. Appended to this file's inbox on 2026-10-18 naming the
  engineer and the pm; filed under `any` because the rule as written binds
  every reader of a check, and on 2026-10-18 it was four seats in one evening —
  HQ's frontend, HQ's yc and this seat twice — each answering the same three
  reds by reference.)
- **L-A69 — A check that does not perform the act cannot answer for the act.**
  Verify a set by applying it for real, one step at a time, in an order written
  down beside it, into a copy you throw away. epitome's pre-flight check
  claimed to verify fourteen charter patches alone and as a set, and asked the
  version-control tool for a dry run of all of them at once. A dry run writes
  nothing, so every patch was checked against the unmodified file: two patches
  inserting at the same place both passed, and the real application failed on
  the fourth and left the file half-written. Measured in a throwaway worktree
  on 2026-10-18: `--check` over fifteen patches exits 0, the real run exits 1
  on the fourth having already written 23 insertions into two files, one at a
  time in the recommended order lands 9 of 14, reversed it lands 9 of 14 but a
  different five. **The sharp edge is the forgiving tool, because it is the one
  that succeeds**: a fuzzy patcher reported 14 of 14 with five placed where
  their own diffs did not say, spliced one charter bullet into another bullet's
  sentence, and exited zero. A tick that cannot fail where the real command
  fails is not a tick, it is a second opinion from a different question.
  (epitome L28, 2026-10-18, portable, handed up by that product's ExO rather
  than patched into its vendored copy; their own product sells three commands
  whose promise is exactly this, one of them a validator whose contract already
  says a tick must not promise what the command downstream refuses.)
- **L-A70 — The tool you ran is the copy you reached: resolve the path, and
  never read a tool from a checkout nobody pulls.** Two halves of one fault,
  both measured in Ursa on 2026-10-18 and both invisible to an existence sweep,
  because an absent tool fails loudly and a present one answers. First, a tool
  carrying another repository's layout answers about files it never opened:
  `tools/check-queue-ids.sh` named `standards/lessons.md`, which exists at HQ
  and in none of the four products — the vendored copy is
  `docs/standards/lessons.md` — and printed "no open ref adds an identifier",
  which reads exactly like a clean register. So a tool resolves its inputs
  against the repository it is running in, and says so out loud when one is not
  there; one resolution step in the tool beats five patched copies. Second, a
  tool read from a host path answers from whenever that path was last pulled.
  The same script, same clone, same minute: the copy in the resident host's
  checkout of HQ called all seven of Ursa's open pull requests unmergeable and
  the copy on HQ's `main` called all seven clean, because that checkout was
  twenty-seven hours and 557 commits behind with 66 files under `tools/`
  changed in the gap. **Fetch the blob from `main`, one call per file, rather
  than naming a host path** — and a charter that names a host path is the
  defect, not the window that obeyed it. The second half is why `standards/pm.md`
  §15's *written, merged, running* distinction is about every tool and not only
  about the runtime. (Ursa, 2026-10-18, two notes and a handoff from that
  product's ExO; same host measurement independently from HQ's mba seat the
  same evening, which traced the board's sister-company inbox reads to the same
  stale copy.)
- **L-A71 — An environment that cannot hold the answer will answer anyway: a
  full disk is a correctness fault, not an operations nuisance.** On 2026-10-18
  the resident host's root filesystem reached zero bytes free while ~26 seats'
  windows ran on it, and the failure mode was not that work stopped. Work
  continued and lied. Measured in this seat's own run, every item first-hand:
  a 30-test suite reported 30 failures with the disk full and 30 passes with
  `TMPDIR` moved to a filesystem with room, nothing else changed, so a seat
  reading either answer cannot tell the box from its own diff. A heredoc
  creating a new test file was refused mid-write, leaving the file at zero
  bytes; `git add` staged it and `git commit` took it, and a test file of zero
  bytes collects zero tests and a suite that collects zero tests says OK.
  `mktemp -d` failed, the calling script did not check it, `$TMP` was the empty
  string, and every `$TMP/file` became `/file` — refused by permission rather
  than by space, after which the tool answered from state it had never written.
  Every command's stdout was discarded with `ENOSPC` while the command itself
  succeeded, which is a seat reasoning from blank output. So: **a seat whose
  writes or whose command output are failing stops reasoning and says where it
  is**, every script that makes a scratch directory checks that it got one
  (`mktemp -d || die`), and capacity on a box that runs the whole company's
  seats is an owner-visible number rather than something each run rediscovers
  by hand. The reclaimable share is mostly stale: ~3.5GB of finished runs'
  worktrees, virtualenvs, clones and caches under `/tmp` and in the seats'
  home, none of it owned by anything still running. (HQ, 2026-10-18, this
  seat's own run, which spent roughly a third of itself on this; Ursa's
  frontend seat measured the same box falling 228MB → 23MB → 0 in the same
  twenty minutes, reported two of its own writes refused and the board's
  database unreachable for reads as well as writes, and recorded it in its pull
  request precisely because the board could not be the record.)

- **L-A72 — A declaration in the repository is not a fact about the running
  system.** A schema file, a staged workflow, a vendored copy, a manifest: each
  states what should be true of something outside git, and nothing is true of
  that thing until a comparison says so. So a seat that lands such a
  declaration also lands the comparison that runs, on a schedule, without
  anyone remembering it — and until that comparison exists the declaration is
  a plan, and no report may count it as shipped.
  Measured, 2026-10-23. `runtime/board/schema.sql` declared `board.runs.branch`
  and `board.runs.refusal`; the live table had neither, because both arrive by
  `alter table ... add column if not exists` and the only reader of that file
  is `runtime/board/install.sh`. The consequences, each verified first-hand
  against the database rather than inferred: **every `POST /api/runs` in the
  portfolio refused for four days and twenty-one hours** — the insert names
  `branch`, so not one run report from any seat in any company was recorded
  between 2026-10-18 19:54Z and this run — and `GET /api/board/<company>` and
  `GET /api/work/<company>/<seat>` answering 503 for all five companies, which
  is every kanban and every seat's lane. The database was reachable the whole
  time. It was four days behind the code. Re-applying the file took one
  command and closed all of it.
  The company had already learned this shape once, in the other direction, and
  written the mechanism down: `tools/staged/README.md` exists because four
  workflows sat staged and uninstalled for five days and "nothing said so,
  because nothing compared the two directories". A header is not a mechanism
  there and an idempotent migration is not a mechanism here. The comparison is
  `tools/check-db-schema.py`, over every schema this repository ships, naming
  the exact DDL in the finding. It exits 2 rather than clean when it cannot
  look — including on a schema file it cannot parse, which was its own first
  version's bug — because a tool that could not read is not a clean bill
  (L-A68, and `tools/company-checks-note.py`'s own argument).
  (alexandra-systems, 2026-10-23, this seat's run, diagnosed from the live
  catalog. Second source: alexandra-systems, 2026-09-25, the staged-workflow
  wall and `tools/install-staged-workflows.sh`.)

- **L-A73 — One sentence for every cause names none.** A handler that answers
  the same way whatever went wrong converts a diagnosis into a guess, and the
  guess is load-bearing: it is what every reader will believe. So the catch-all
  sentence on a surface says what the handler actually knows — which operation
  failed, on what, and what the process still holds — and never asserts a cause
  it did not establish.
  The board's four read routes answered every unexpected exception with "the
  board's database is unreachable". For five days that sentence was the only
  symptom of a schema four days behind, and it was false in the one way that
  costs most: it named a healthy component as the fault and pointed every
  reader away from the live one. The neighbouring routes answering normally
  from the same connection were the evidence that contradicted it, and reading
  them took one minute — which is the test to apply to any such sentence
  before writing it down. Companion to L-A34: a cause asserted from a handler
  that did not look is an absence measured from one vantage point.
  (alexandra-systems, 2026-10-23, this seat's run.)

- **L-A74 — A surface iterates nothing it did not shape.** A field a seat
  fills in freely is fine to store and fine to print. The moment a renderer
  walks it — a list it draws one row per entry of, a dict it reads keys from —
  it has a shape, and that shape is a contract with every seat that will ever
  write it. Two things follow, and the rule is both: the read takes the shape
  it can use and drops the rest, so no one seat's field can take the surface
  down; and the write refuses the other shape then and there, while the seat
  is still in the room and can be told, which is the only moment the telling
  is cheap.
  Measured, 2026-10-23. The board's message `data` is deliberately free-form,
  and `GET /api/work/<company>/<seat>` iterates `data["files"]`. Ten messages
  from four seats wrote it as a count — `files: 9`, which is what the name
  invites — and iterating an integer raised `TypeError` outside every guard on
  the route, so the server closed the connection with no status and no body
  at all. **Four seats' lane pages answered nothing for five days, each on the
  strength of its own message**: this seat's among them, which is how it was
  found. The store validated the prose of the same message strictly enough to
  refuse a stray pull-request number, and validated the field a renderer walks
  not at all.
  The third clause is where it was cheapest of all: a surface that cannot
  render must still answer. The weave sat outside the route's `except`, so the
  page could not even report its own failure, while the function one line
  above it carried a docstring promising that "any GitHub failure is an empty
  list and a log line, never a failed page". A promise one caller keeps is not
  a property.
  (alexandra-systems, 2026-10-23, this seat's run. The seats whose own messages
  did it: HQ's yc, mba and exo-centralizer, and epitome's engineer.)

- **L-A75 — One read over several sources gives each source its own
  failure boundary, its own named status, and a number that is absent
  rather than zero.** When a surface gathers from more than one place, a
  single failure boundary around all of them means the first refusal
  decides the whole answer, and what it reports is the shape of a
  company that did nothing. Measured at HQ on 2026-10-23: `GET
  /api/scorecard`, the first instrument this company's learning loop is
  told to read, answered `200` with zero weeks for five days. Langfuse
  had been removed on 2026-10-23 for filling the host's only disk,
  `CLICKHOUSE_PASSWORD` still named it, the connection was refused, and
  because every source sat inside one `try` the exception jumped past
  both of the board's own queries and `weeks` was never assigned. The
  board's Postgres was healthy throughout and held 246 messages from the
  previous 168 hours, every one of them a column the scorecard claims to
  report. The reason was in an `error` field, and the one consumer, the
  owner's ExO tab, returns early on an empty `weeks`, so the curve was
  not wrong, it was absent, which reads as a tab still loading. So: each
  source is read in its own boundary and reports `ok`, `absent` or
  `unreachable` **by name**; a column carries which source it came from,
  so a reader can tell a gap from a measured zero; a reading taken while
  a source was down is cached briefly rather than for the full window;
  and a surface with no reachable source at all fails loudly instead of
  serving a flat week, because nothing read is a failure to look and not
  a finding about the company. A source that was deliberately removed is
  `absent` and not a fault, or every surface carries a permanent warning
  about a settled decision. (HQ, 2026-10-23, this seat's own run, which
  was woken to measure throughput and found its own instrument blank.
  Second source, the same shape one step further in and in the same
  process: the board's message read takes an addressee, a sender and a
  kind, and `everyone` adds the broadcast notes to an addressee's inbox.
  Asked with a kind and no addressee, `everyone` was the only term left
  in the addressee clause, so it stopped adding and started excluding.
  `?kind=handoff&since_hours=168` answered **0 handoffs in the week**
  while two handoffs from 119 hours earlier sat in this seat's own
  inbox, and 0 is the number from which a reader concludes that nothing
  is stuck. A default that widens a narrowed read must not be able to
  become the only thing a read is narrowed to.)

- **L-A76 — Removing a component is not finished until every reader of
  it has been told.** A removal is recorded where the decision lives and
  the readers are elsewhere, so the component goes on being mandatory to
  everything that still names it, and each reader fails in its own way
  at its own time. Langfuse was removed from the resident host on
  2026-10-23, correctly, with its reason, and written into the
  architecture register the same day. What was not done is the list of
  things that read it: the scorecard, which still treated the trace
  store as a required source and lost the whole instrument to it
  (L-A75); the seats' tracing environment; and a Caddy route to a port
  with nothing behind it. So: the act of removing something includes
  enumerating its readers by search, not by memory, and either
  re-pointing each one or making each one treat the thing as optional
  and say so. The register entry that records the removal names that
  list, and a reader left pointing at the gone thing is an open item
  with an owner rather than a sentence in a run report. (HQ,
  2026-10-23. The removal's own register entry did name what was left
  over, "what still points at Langfuse ... is the engineer's to retire
  or re-home", and the scorecard was not in that list, which is the
  argument for enumerating by search: the hand-written list was
  incomplete in the one place that mattered most.)

- **L-A77 — A failed command inside a substitution does not fail the
  command it was building, it silently builds a different one.** A
  measurement assembled by interpolating one command's output into
  another is two commands with no boundary between them, and the shell
  hands the second a shorter argument list rather than an error. The
  second command then answers a question nobody asked, confidently and
  in the right format. Measured in this seat's own run on 2026-10-23: a
  depth-1 checkout made `git merge-base origin/main origin/<branch>`
  print nothing and exit non-zero, so `git diff --stat $(git merge-base
  ...) origin/<branch>` became `git diff --stat origin/<branch>`, which
  is a diff of the **working tree** against that branch. It printed 71
  files and 6,692 insertions, it looked entirely plausible, and it was
  read far enough to draw a wrong conclusion about another seat's branch
  before the file this run had just created appeared in it as an
  addition, which is impossible and is what gave the fault away. The
  true reading was 7 files. So: a substitution whose emptiness would
  change the meaning of the command is checked before it is used, or the
  two are not written as one line. `set -u` does not catch this, because
  nothing is unset. The tell is an answer that is plausible, so the
  guard cannot be vigilance. (HQ, 2026-10-23, this seat's own run. The
  checkout fault itself is L-A40's, and this is the second mechanism by
  which it lies: L-A40 binds the commands that prove containment, and
  this one was an ahead-behind count and a file list, which no rule had
  named. Both are repaired by `tools/ensure-full-clone.sh` before the
  first measurement rather than before a particular command, which took
  two seconds in this run and would have saved the wrong conclusion
  entirely.)
- **L-A78 — A message is not a notification.** Writing an alarm into an
  inbox is delivery only when something outside that inbox opens it. A
  surface a seat writes to becomes a channel when a clock the surface
  does not own wakes the addressee, and not before. So an alarm names
  the clock that will open it, and a channel whose only reader is a
  seat that runs on the thing being reported is not a channel at all.
  (alexandra-systems, 2026-10-18 to 2026-10-23, this seat's run on the
  outage of Incident 19. Within four minutes of the host's disk reaching
  zero, two seats wrote the fault down correctly and in the right words.
  HQ's engineer posted an `ask` to the owner at 19:51:17Z: "The host
  filled up tonight, the board stopped accepting writes, and the three
  fixes are all yours", with the measurement attached. HQ's frontend
  posted a `handoff` to this seat at 19:54:38Z: "The resident host has no
  disk left, it took the board down, and half of it is invisible to a
  seat". Both rows went into `board.messages` and were readable the whole
  time. The first run of either addressee that could read them started
  2026-10-23 17:17:17Z, **117.4 hours later**. Tonight, with the clock
  alive, messages of those same two kinds were read in 0.1 to 0.4 hours.
  So the loop did not miss the signal. It held the signal, in writing,
  addressed to it by name, and had no clock to open the envelope.
  Companion to L-A79, which is about where the instrument runs, and to
  Incident 19's third layer, which is about the surface it runs on.)
- **L-A79 — A watcher that shares a fate with what it watches is not a
  watcher, and its own silence has to be the alarm.** An instrument that
  reports a surface's health runs on a different machine and a different
  clock from that surface, and it is built so that the absence of its
  report is itself an alarm rather than something a human has to notice.
  A poll that speaks only when it sees trouble cannot speak about the
  trouble that stops it running, and a one-shot alarm that latches a
  down state spends itself on whichever cause fires first, which is the
  cheap cause and not the expensive one. (alexandra-systems, Incident 19.
  Every watcher the company had ran on the host it was watching, and the
  board is both the bus and the only place a report can go, so the one
  fault that most needed reporting was the only fault that could not
  report itself. The repair is ADR-059, a heartbeat on GitHub's clock in
  a public product repository, which shares no failure with the host,
  reads the board's health every thirty minutes and telephones the owner.
  Graded in the same run that wrote this rule, because a fix is a
  hypothesis until it is read: the heartbeat asserts on the health
  route's `ok` field and on the host's disk, it records a down state in a
  repository variable so that it speaks once, and nothing expires that
  record. Therefore a credential that drifts out of step produces the
  same signal as a dead company, and the latch spends the single alarm
  on the false one, after which the real outage is silent. The two
  conditions it still needs are named in the improvements register for
  the week of 2026-10-19.)
- **L-A80 — A read that succeeds with nothing in it is not a reading.** A
  liveness check asserts on content and on the age of the newest item,
  never on a status code and never on the absence of an exception. A
  surface that answers successfully and empty cannot be told apart from
  a healthy and empty world, and every reader will take the second
  reading, because that is the one that asks nothing of them. So a zero
  states which of the two it is, and an instrument that cannot tell them
  apart does not ship as an instrument. (Two sources, thirty-four days
  apart, and the second cost five days because the first was never
  generalized. One, alexandria, 2026-09-19,
  `docs/research/briefs/2026-09-19-b.md` under "A dead feed that passes a
  liveness check": `spiffe/spiffe/releases.atom` returns HTTP 200 with
  zero entries, because that repository carries the specification and
  cuts no releases, and that product's incident 21 had recorded those
  feeds as "all verified live", which is exactly what a status-code check
  reports. Two, alexandra-systems, 2026-10-23: `GET /api/scorecard`, the
  first instrument this seat's own charter tells it to read, answers HTTP
  200 with `weeks: []` and `error: "<urlopen error [Errno 111]
  Connection refused>"`, and has answered an empty eight weeks since
  Langfuse was removed. It answered that way through the five dark days
  and it still answers that way tonight, while `GET /api/health` says
  `ok: true`. This register reached the same rule independently as L-A75
  on 2026-10-23, by paying for it, when the portfolio had held it since
  2026-09-19. That gap is Incident 21, and under L-A4 it is this
  register's defect rather than the library's.)
- **L-A81 — A shared resource with no budget and no watch is an outage
  with a date on it, and the first resource to budget is the one the
  reporting surface runs on.** Every resource that more than one
  component draws on gets a declared ceiling and a reading before the
  component that draws on it is installed. This binds bytes on a disk
  and wakes in an hour alike, because they are one fault seen from two
  ends. A component whose purpose is to observe the system is held to it
  most strictly, since an observability stack with no ceiling becomes the
  failure it was installed to report. (alexandra-systems, Incident 19,
  which proposes this rule in its own closing line and leaves the writing
  to this seat. One container's log reached 14G on a 45G disk because
  Docker's default `json-file` driver sets no `max-size`, Postgres hit
  `PANIC: could not write to file ... No space left on device`, and the
  container in the error loop was `langfuse-clickhouse-1`, which is the
  observability stack. The company measured merges per run, hours to
  main, runs that shipped nothing and tool errors per run, and did not
  measure the one resource whose exhaustion stops all four. The wake side
  of the same fault, in the same hour: 200 bus events between 18:49Z and
  19:54Z on 2026-10-18 with 172 of them inside one hour, and on the board
  88 messages in that window of which 67 were directed at a named seat,
  and 37 runs started across 8 seats, under a wake design with no
  ceiling. The owner's standing condition, 2026-10-23: Langfuse stays
  stopped until it is rebuilt with a disk budget.)
- **L-A82 — A company that cannot tell whether its own seats ran this
  week has no cadence.** Every company reads the liveness of its own
  seats on a surface it can reach without the machine that holds their
  clocks: the hour of the last completed run per seat, against that
  seat's declared cadence. A seat silent past its cadence is an incident
  in that company's own register, raised by that company. A company whose
  only evidence that it is alive is that nobody has complained is not
  running, it is unobserved. (alexandra-systems and the whole portfolio,
  2026-10-18 to 2026-10-23. Decision 056 moved every seat's clock onto
  the host roster, which made one disk the single point of failure for
  four companies' cadence at once, and nothing downstream of that
  decision gave a company a reading of its own. Measured from
  `board.runs`: alexandria dark 117.6 hours, Ursa 117.5, epitome 117.5,
  alexandra-systems 117.4, and zero runs in any of the four in between.
  Merges across the five repositories: 230 on 2026-10-18, then zero on
  each of 2026-10-19, 20, 21 and 22, then 45 on 2026-10-23. No product
  raised it, because no product had a reading of its own seats, and the
  first report of any kind came from the owner asking how it was going.
  The company view this seat's own harvest reads first,
  `docs/company/lessons-portable.md` and `docs/company/incidents.md`, was
  generated 2026-10-18 08:19Z and was five days stale on arrival for the
  same reason, which is L-A40's shape inside the harvest's own
  instrument.)
- **L-A83 — A rolling window with a hole in it is not a window.** Any
  number reported over a period states the period's active time as well
  as its span, and a period that contains a known outage either excludes
  the dark hours and says so, or is reported as unreadable. A seat that
  reports it as a plain week-over-week delta is making the two errors
  that both favour the easy reading: the outage reads as a quiet week and
  the recovery reads as a collapse, and in neither case does the number
  ask anything of its reader. (alexandra-systems, 2026-10-23, this seat's
  run on the outage. Tonight `python3 tools/autonomy.py --days 7` reports
  a portfolio autonomy floor of **38.7% of 323 merges, 61% unresolved**,
  against the restated baseline of 42.0% of 305 with 58% unresolved that
  the improvements register set for 2026-10-25. The 168 hours that number
  spans contain **115.5 consecutive hours, 69% of the window, in which no
  merge was possible in any repository**, and 281 of the 323 merges
  landed on just two of the seven days, 236 on 2026-10-18 and 45 on
  2026-10-23. So the delta is not small, it is undefined. Nine entries in
  the improvements register for the week of 2026-10-12 carry a next
  measure dated 2026-10-25 and every one of them would be taken across
  that hole. The same fault in the opposite direction is L-A80's second
  source: the console's weekly curve returned early on an empty list of
  weeks and drew nothing, and five days of blankness read as a page still
  loading.)

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
  proven otherwise, so check what else was running. (HQ incident 8,
  2026-09-21 and 2026-09-24, cited as incident 4 until this
  correction: three Kimi-routed PM runs across two
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
  workflow commits 2026-09-25; HQ incident 8, cited as incident 4 until
  this correction. **Renumbered from L-E6 on
  2026-09-28**, which was already live as the quality-law-versus-
  runtime-budget rule above and had been distributed to three products
  twice over. The rule is unchanged and no file anywhere cited the old
  ID. Note the overlap with L-E7, which is the same first defect stated
  as policy. This rule is the implementation, and its second and third
  clauses are its own. **Amended 2026-09-30** with the clause that made
  the difference between a written rule and a fixed fleet: each of the
  three defects is testable in one `grep`, so the drift check owns them,
  and a workflow rule that `tools/check-seat-workflows.sh` does not test
  should be read as undistributed no matter how many registers carry it.
  Evidence for the amendment is the register's own failure. Five days
  after this rule was written and distributed to every product, the
  centralizer counted the live workflows: the commit-counting tripwire
  had reached HQ's nine seats and epitome's five and no others, so 26
  workflows across alexandria, Ursa and atelier-app still ran the
  `git branch -r --contains HEAD` form that epitome run 35956231272
  proved passes a run that shipped nothing, and the checker reported all
  of them conforming because it only tested that a step named "No-ship
  tripwire" existed. L-A9 in the engineer's own territory.)
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

- **L-E10 — An open card is not evidence that nobody built it, so a
  builder surveys the pull requests before it writes code.** Every
  autonomous run starts from `main` with no memory, and `main` is the
  one place where work that is built but unmerged is invisible. A
  backlog card therefore says only that the work has not *landed*; it
  says nothing about whether it has been *done*. Before writing a line
  of code a builder seat runs `gh pr list --state open` and
  `gh pr list --state closed --search '<the feature in words>'`, reads
  the hits whose scope overlaps its own, and then picks one of three
  moves in the open: extend the existing branch, propose closing it
  with a reason, or land the stack. Writing a sixth implementation is
  never one of the three. The survey belongs in the PR description as
  named numbers, because a survey nobody can see is indistinguishable
  from a survey nobody ran (L-E5's grounding rule applied to prior art,
  and requirement 9 of engineering-artifacts.md is its artifact form).
  PM corollary, which is the half that lets this recur: a hill or a
  dispatch drawn from a card rather than from `gh pr list` hides the
  duplication it then commissions, so a dispatch whose evidence is a
  sprint item carries the PR survey in the instruction, and a seat
  sitting behind a stack of its own open PRs is told to land the stack
  rather than to build again. Binds every builder seat (engineer,
  frontend, skill, and any seat that commits code) and every PM.
  (epitome cycle 1 bet 2, 2026-09-22 through 2026-09-29: `epito token`
  was built six times in five attempts — PRs #9, #10, #14, #15, #20,
  #23 — every one of them closed and **not one merged**, while a
  six-deep unmerged stack sat in the repo and the card stayed open. So
  the cost was not only five wasted builds, it was a feature the
  company paid for six times and shipped zero times. Reported to HQ by
  the chair on the owner's directive of 2026-09-29, "report the cause
  and system to ExO, including HQ"; epitome's own register entry is in
  flight at epitome#26. The shape is not epitome's alone: HQ carried 13
  open PRs and 19 unmerged seat branches on the day this rule was
  written, which is the same invisible inventory one repository up.)

- **L-E11 — A run's success is measured against state captured before
  it ran, never re-derived from the end state afterwards.** A check
  that asks at teardown "is there a branch, a commit ahead, a pull
  request" is asking about the wreckage, and the cleanest possible run
  leaves the least wreckage. Capture the facts the question needs in a
  step that executes *before* the agent — the base SHA, the list of
  remote branches — and at the end compare: the base branch advanced,
  or a new seat-prefixed remote branch exists. Two clauses come with
  it. **A false failure is a defect, not a transient**, so it is
  triaged and never re-run, because re-running it spends a seat's
  budget to reproduce a measurement error. And **a tripwire that fires
  hardest on the best runs is worse than no tripwire**, because the org
  learns to read its colour instead of its message, and the cost lands
  on the true failures it was built for. (HQ, 2026-09-27 through
  2026-10-02: the no-ship tripwire false-failed six times by the PM
  standup's own count, across two seats and two mechanisms. Five are
  identifiable in the record — PR #44 on 2026-09-27, PR #51 on
  2026-09-28, the exo centralizer's run 36657936104 on 2026-09-30, the
  PM's run 36600822137 on 2026-09-29, and the 2026-10-01 scheduled PM
  run that shipped and self-merged PR #80 and was then marked as having
  produced nothing. The mechanism, read
  line by line out of `standards/workflow-template.yml` rather than
  inferred from the failure mark: after a Tier A self-merge `HEAD`
  never leaves `main`, so `commits` against `origin/main` is zero; the
  consumed seat branch is deleted, so the pushed-branch check is empty;
  and `gh pr list --head main` finds nothing because no pull request
  ever had head branch literally `main`. All three of the tripwire's
  shipped-ness signals read empty on the single cleanest ship path the
  company has. The fix is PR #75, written 2026-09-30, unmerged as of
  this harvest — which makes this rule's own evidence an instance of
  L-X7. Companion to L-E8, which fixed the tripwire's arithmetic; this
  one fixes where it reads from.
  **Amended 2026-10-05** with a seventh instance and the cost of
  leaving the fix open.
  HQ run 37259867006 pushed a seat branch, opened draft PR #102, then
  committed once more and ended normally, and the tripwire reported
  "this run made commits that were never pushed, so the work dies with
  the sandbox" on a run whose work was on the remote.
  This rule's own prescribed signal passes that run correctly, because
  `exo/harness-preflight-2026-10-05` did not exist when the run began,
  so the cost of PR #75 sitting open for five days is measurable: a
  24-hour triage cycle spent on a loss that had not happened, a handoff
  written to carry it, and a seat blocked from re-dispatch by its own
  failed run.
  The amendment adds one measurement clause.
  **A guard reports the smallest true thing, not the largest alarming
  one**: "a trailing commit was orphaned" and "this run shipped
  nothing" are different findings, and a check that cannot tell them
  apart should say which signals it read rather than assert the worse
  one.
  Also: print the facts you judged on to the log, not only to the job
  summary, because no API serves a job summary and a verdict nobody can
  re-read is a verdict nobody can correct.
  (HQ incident 14, 2026-10-05.))

- **L-E12 — A read-only intention must be read-only in the flags.** A
  measurement that runs inside a directory somebody else is standing in
  may only ask questions. The flags that look like thrift are the ones
  that write: `git fetch --depth=N` into a complete repository writes
  `.git/shallow` and leaves it shallow for every later reader, a
  checkout moves their HEAD, a reset moves their work. Fetch into a
  scratch tree, or read the blob out of `FETCH_HEAD`, and if cheapness
  is genuinely needed pick the flag that does not rewrite the caller's
  history (`--filter=blob:none`). (HQ, 2026-10-18, engineer review of
  this register's own distribution tool, which fetched `--depth=1` into
  each of four checkouts named by `--repos-dir` in order to measure
  them, five lines below its own comment that "a measurement that moves
  their HEAD is a measurement that breaks the thing it measured". The
  same shallow-clone fault had cost six HQ passes their first turns that
  morning, and this loop would have manufactured it in four more
  repositories. Verified by the reviewer on a throwaway server:
  `shallow=false` before the fetch, `shallow=true` after. Now pinned by
  a test that a caller's complete checkout is still complete after a
  `--check` run.)

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

- **L-P8 — When a check cannot run anywhere, the merger picks one policy for
  the whole gated class and applies it to every pull request in the pass.** Two
  policies are defensible — withhold everything in the class until the
  infrastructure returns, or accept a re-performed local run as the evidence —
  and the damage is in alternating between them, because a seat cannot tell an
  unlucky pass from a rule and will read the same gate as a coin flip. Say which
  policy the pass is on, in the pass's own report.
  **The class is computable, not a judgement.** A pull request is in it when its
  diff matches a workflow's path filter — at HQ on 2026-10-18 that is `tools/**`,
  `runtime/graphs/**`, `runtime/memory/**`, `.github/workflows/**`,
  `tools/staged/**` and `standards/workflow-template.yml` — and
  `python3 tools/check-run-ran.py --branch <branch>` answers in one call whether
  the red is the never-started kind. Measured: 500 of 500 failing runs at HQ
  since 2026-10-13T15:00Z never started and not one succeeded; 13 of 15
  non-draft open pull requests were in the class; 4 of those merged clean and
  were held by nothing else.
  **Hold by the class and report the count, never one pull request at a time.**
  A pass that withholds names the policy and how many it held under it, so the
  cost reaches the owner as one number she can act on rather than as a series of
  individual seats being unlucky — which is how a five-day infrastructure block
  stayed a seat-by-seat triage line instead of a queue-wide one.
  **And evidence a merger can re-perform beats evidence it must believe.** The
  form is the command and its exit code, not the adjective: `python3
  tools/check-pr-green.py <pr>` builds the real three-way merge and runs this
  repository's own suites against it, which is better evidence than a forge
  check on a branch tip that the merge will not ship — and for `runtime/board/**`
  it is strictly stronger, because that suite has no workflow file at HQ at all,
  so the forge has never checked it. A seat that posts the adjective is making a
  claim; a seat that posts the command is handing over a check. Binds pm and
  chair, and every seat whose work is held by one.
  (HQ, 2026-10-18, measured on this seat's own two withheld pull requests and
  the queue around them. The companion to L-A66, which is the same defect from
  the held seat's side.)

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

  **Amended 2026-10-05: in the tree is half of it, and the other half
  is a detector.** A fix that only repairs the damage protects the past
  and leaves the future exactly as exposed as it was, so an incident is
  closed when the repair is in the tree *and* something in the tree
  would notice the same thing happening again. The detector is checked
  against a real positive before the incident is called closed, because
  a detector nobody has seen fire is a second thing written down. And
  the entry carries an explicit status line, per L-A28, or no register
  reader can tell a closed incident from an open one. (Ursa incident 2,
  2026-09-18, fixed entirely as history surgery with
  `git-filter-repo`: the purge protected every commit that existed and
  nothing was added that would notice the same strings re-entering
  through a new file. The same class of string re-entered through a new
  file the next day, which is Ursa incident 4. Companion to L-E8 as
  amended, where a workflow rule the drift check does not test reads as
  undistributed no matter how many registers carry it, and to L-A9,
  where a gate that is not a command is not a gate.)
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

  **Amended 2026-10-12: a cap that binds destroys the evidence that
  would correct it, so exhaustion is itself the evidence.** The rule
  above reads `num_turns` out of completed runs and doubles the peak.
  When a run is cut off at the cap, the `num_turns` it reports is the
  cap plus one — a censored observation, not the seat's peak — so the
  2x rule has nothing true to multiply and silently re-certifies the
  cap that caused the failure. Three clauses close it. **One: an
  `error_max_turns` exit is a finding about the cap, not about the
  run.** **Two: the response to exhaustion is a defined step up, not a
  measurement** — raise by half again, and repeat on the next
  exhaustion, until a run finishes inside the cap and a real peak
  exists, at which point the 2x rule governs again. **Three: repeated
  exhaustion by one seat inside one week is a defect to report, not
  noise** — it is the only signal in the system that a seat's duties
  outgrew its budget, and it is invisible unless something counts it.
  That something is `tools/check-turn-caps.sh`, which reads every seat
  workflow's cap across the portfolio and counts exhaustions against
  it; the rule is no longer a thing a seat must remember to measure.
  (Portfolio-wide, week of 2026-10-05: **eight of the fourteen failed
  seat runs ended at `error_max_turns`**, across six seats in three
  products — Ursa's engineer three times at a cap of 120 on 10-07,
  10-08 and 10-11, Ursa's security at 100, Ursa's skill at 100, Ursa's
  frontend at 250, alexandria's writer at 150 on both 10-04 and 10-09,
  and HQ's engineer at 120. Every one reported `num_turns` of exactly
  cap+1. Two of the eight — Ursa's security on 10-11 and alexandria's
  writer on 10-09 — had already made commits they never reached a push
  for, so the cap did not only end those runs, it destroyed their work,
  which is L-A30's failure arriving through a door L-A30 does not
  watch. Found by hand, by downloading thirty-one log archives, because
  nothing in the company counted it; see L-X14.)
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

  **Third occurrence, 2026-10-12, and it is the reason this entry now
  ends in a requirement rather than advice.** The first command of this
  harvest was

  ```bash
  echo "EXO_TOKEN set: ${EXO_TOKEN:+yes}${EXO_TOKEN:-NO}" | sed 's/gh[pous]_[A-Za-z0-9]*/REDACTED/'
  ```

  which is both named traps at once: the `${VAR:-NO}` expansion this
  rule calls out by name, wrapped in the prefix-guessing `sed` of
  Incident 3, whose pattern again does not cover `github_pat_`. Same
  seat, same credential, same two mistakes, twenty-three days after
  writing the rule against them, with the snippet Incident 4 added
  sitting four lines above in the file the seat had open. Masking in
  Actions means the rendered log shows `***`; the value still passed
  through the model's context, and the ceiling on that claim is the
  same honest one as before.

  **So the clause this rule was missing: a rule whose violation is a
  single shell idiom cannot be enforced by a sentence, and must be
  enforced by something that reads the command.** Three occurrences is
  no longer a seat's carelessness, it is evidence about the enforcement
  mechanism: prose in a register loses to a one-line habit every time,
  because the habit is typed before the register is consulted. The
  requirement is a pre-execution check on the seat's own shell — a
  hook that refuses a command containing `${<SECRET>:-` or `${<SECRET>-`
  or a bare expansion of a known secret name — and until one exists,
  every occurrence of this failure is the harness's, not the run's.
  Companion to L-X1 as amended, where an incident is closed only when
  something in the tree would notice it happening again, and to L-E8 as
  amended, where a rule the drift check cannot test reads as
  undistributed however many registers carry it. (alexandra-systems,
  2026-10-12. The register entry is Incident 15 and it is in this
  harvest's companion pull request, not on `main` at the moment this
  rule merges; L-A29 forbids citing an unmerged entry as though it had
  landed, so the provenance here is the date and the seat, and the
  number becomes citable when the owner merges it.)

  **Fifth occurrence, 2026-10-23, and the shape is a flag rather than an
  idiom.** Diagnosing a board route that closed the connection without a
  status, this seat reached for `curl -sv` to see whether the server answered
  at all. curl's `-v` transcribes the request it sent, and the request carried
  `Authorization: Bearer <value>`, so the board's runtime token went into the
  run's own transcript. The guard was installed and was correctly silent: what
  it read was this rule's explicitly allowed form, `curl -H "Authorization:
  Bearer $T"`, with one extra letter on an earlier flag. `tools/check-secret-print.py`
  had named this as a limit it could not see. It can: the client is the command
  word and the flag is on the line. So the rule gains a clause and the checker
  a fifth shape, `X5-VERBOSE`, per client because the flag is not the same
  letter twice — curl's `-v` and `--trace*` do it, `wget`'s `-v` does not and
  its `--debug` does, httpie's `-v` does; `-i` and `--include` never do,
  because they print the response and the credential only ever goes out.
  **The clause: a credential is printed by asking a client to describe itself,
  not only by printing it.** Any flag that makes a tool transcribe its own
  request is a print statement for every header in it. The generalization past
  curl is the part worth carrying: the same is true of a client's debug
  logging, of a proxy's access log with headers on, and of any dump of a
  request object. And the second-order rule, which is why this is written here
  rather than only in the checker: **a stated limit of a guard is a finding
  waiting for a date.** This file had written down exactly what it could not
  see, in the file itself, and the thing it could not see is what happened. A
  limit a guard declares is the next incident's description, so it is closed
  when it is cheap or it is scheduled, never left standing as documentation.
  (alexandra-systems, 2026-10-23, this seat's own run and its own credential.
  The token is named for rotation in that run's handoff, because a rotation is
  the owner's to do and a value that reached a transcript is spent.)

  **The sixth shape: shell tracing prints the safe form and not the
  unsafe one** (Incident 18, 2026-10-18, this seat's own run and the
  board's runtime token; the checker's `X5-TRACE`). `set -x` makes the
  shell echo each command after expansion, so the one form this rule
  asks for, a credential passed as `"$TOKEN"` and never written out,
  becomes the one form that is printed, in full, by a line the author did
  not write. **The clause: a credential in scope and a trace flag in the
  same shell are a print statement, and the trace is the thing to fence
  rather than the command.** `set +x` before the call and `set -x` after
  it, which is also the checker's own suggested fix. The cruel part, and
  the reason this is a clause of its own rather than a note, is the
  direction of it: every other shape in this rule is punished for writing
  a value down, and this one punishes the author who refused to. (Written
  2026-10-23, owed since 2026-10-18. It waited five days because the
  company was dark for five days, which is the register's own line item
  in the cost of Incident 19, and the reason L-A82 asks a company to be
  able to read whether its own seats ran.)

  **The seventh shape: a names-only read is only names-only if it is
  anchored** (Incident 20, 2026-10-23, HQ's engineer, and the checker's
  `X5-ENVNAMES`). Listing what a secret store holds is a legitimate and
  routine act, and the idiom everyone reaches for splits each line on its
  separator and keeps what is left of it: `cut -d= -f1`,
  `awk -F= '{print $1}'`, `sed 's/=.*//'`. That is safe for a file whose
  every record fits on one line, and silently wrong for any other,
  because a multi-line value's continuation lines carry no separator at
  all and the filter passes them through verbatim. One such read of the
  host's rendered environment file listed 45 names and printed four lines
  of a five-line value among them. **The clause: a read that claims to
  show only names anchors its match to the start of a record, and what
  starts a record is defined by the file's format rather than by what a
  line looks like.** The generalization past this one file is the part
  worth carrying, because the assumption lives in every tool that treats
  a line as a record, and a certificate, a private key, a JSON blob and a
  bcrypt hash with a newline in it all defeat a line-oriented reader the
  same way and without complaint. The safe form is no longer than the
  unsafe one, which is the only reason to expect anyone to use it, and it
  is the checker's own suggested fix rather than a second wording of it:
  `grep -oE '^[A-Za-z_][A-Za-z0-9_]*=' FILE | tr -d =`. (Incident 20
  proposed this rule to this register and left the writing to this seat.
  It arrives as a shape under L-X5 rather than with an identifier of its
  own because it is the same rule about the same act, reached by a seventh
  route. The checker had the shape within hours of the incident and this
  text has it the same evening, which is the latency this register is
  designed for and is worth stating because the shape above it waited
  five days for the lights to come back.)

  **The enforcement now exists, so the clause above is a pointer rather
  than a request** (2026-10-17, sprint 2026-10-12 item 1).
  `tools/check-secret-print.py` reads a command, a file, or a
  `PreToolUse` payload and names seven shapes, which is the count as of
  2026-10-23 and is read off the checker rather than remembered:
  `X5-DEFAULT`, the `${<SECRET>:-literal}` expansion above; `X5-PRINT`, a
  value expansion inside `echo`, `printf`, `sed` or any other command
  that writes; `X5-REDACT`, a filter that guesses at credential prefixes
  or masks them, which is Incident 3's mistake rather than its fix;
  `X5-ENVDUMP`, `printenv` on a secret or a bare `env` piped somewhere;
  `X5-TRACE`, the sixth clause above; `X5-ENVNAMES`, the seventh clause
  above; and `X5-VERBOSE`, the fifth clause above, a client asked to
  describe its own request. The count is written here with the date it
  was read off the checker rather than remembered, because this prose has
  twice been behind the instrument that enforces it and the reader of the
  prose cannot tell: `X5-TRACE` and `X5-ENVNAMES` landed in the checker
  at 2026-10-23 17:32Z and are given their clauses in this same evening's
  harvest, and `X5-VERBOSE` landed at 18:20Z with its clause in the same
  commit, which is the pattern to copy. So the next author to add a shape
  adds it here in the same commit, and anyone comparing the two reads the
  checker as the authority on what is enforced.
  It decides from variable NAMES and shell shape alone and never reads a
  value. HQ registers it as a `PreToolUse` hook in `.claude/settings.json`,
  so the refusal arrives before the command runs, with this rule's safe
  form already written out for that variable; a seat outside Claude Code
  is covered by the same checker run over the repository in CI
  (`tools/tests/test_secret_print.py`). Three things a seat adopting this
  should know. The guard fails open: an internal error allows the call,
  because a guard that breaks the harness is worse than the failure it
  guards. The forms this rule asks for are tested as false-positive
  cases, which is the half that decides whether anyone keeps it
  (`[ -n "$T" ]`, `${#T}`, `${T:+yes}`, `${A:-$B}` as a fallback chain,
  a credential in an `Authorization` header). And a finding the company
  decides to keep goes in a baseline file with the reason written down,
  not into a silenced check. The honest limit: it reads text, not a
  shell, so a command inside a quoted string or a value copied into a
  variable with an innocent name is outside it. It stops the habit, which
  is what four occurrences showed was the thing to stop.

  **A command and an edit are different risks, and the guard treats them
  differently (2026-10-18).** A command runs now, in this session, and
  nothing reviews it before it does, so nothing suppresses it: a marker
  or a baseline line on a command is ignored. An edit writes text that
  only matters when something later runs the file, and it has two
  reviewers the command does not have — the diff, and the repository scan
  in CI — so an edit honours a marker with a reason and a baseline line
  for that path. This is not a softening. It is the only reason the
  baseline and the counter-example tests can be maintained at all: a
  guard that refuses every edit quoting the idiom refuses the lesson that
  teaches it, and it refused this seat three times on the day it was
  fixed. The same day's other correction: what the shell does not expand
  is not a print — inside single quotes, after a backslash, or in a
  heredoc with a quoted delimiter — and a guard that calls a read-only
  `grep` a leak is a guard a seat learns to route around.

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

  **Second instance, with its cost in hours, 2026-10-05.** PR #75, the
  fix for the no-ship tripwire's false failures, was written
  2026-09-30 and was still open five days later.
  In those five days the tripwire failed a seventh run that had
  shipped, HQ run 37259867006, and the bill for that one arrived
  itemized: the PM's 24-hour failure triage spent a cycle on a loss
  that had not happened, a handoff was written to carry it, the seat
  was blocked from re-dispatch by its own failed run, and the
  investigation that read the truth out of the logs took a second run
  of a second seat.
  So the number to report for an unapplied fix is not only how long it
  has waited. It is what the unfixed thing did while it waited, because
  that is the figure that makes a queue a cost rather than a list.
  (HQ incident 14, 2026-10-05.)

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

  **Second source, 2026-10-12, and it inverts the conclusion for one
  seat.** The wall above was recorded as structural — "a seat cannot
  write under `.github/workflows/`" — and `tools/staged/` plus
  `tools/install-staged-workflows.sh` were built around it, with a
  README that counts what the wait cost: four workflows staged for five
  days, so the company view was generated by a workflow that did not
  exist, the daily brief never ran, and the repository had no CI at
  all. The wall is not structural. It is credential-shaped. The
  engineer's credential is a GitHub App installation token, which is
  refused that write whatever `permissions:` says; the exo
  centralizer's credential is the owner's fine-grained PAT and it
  carries the workflow scope. Probed by write on 2026-10-12 — branch
  `exo/workflow-write-probe` at HQ, one workflow file, pushed clean,
  branch deleted, confirmed gone — which is L-X4's method applied to a
  lane rather than to a repository. So the rule gains a duty: **when a
  seat's token walls it out of its own lane, name the credential that
  is not walled before building machinery around the wall**, and where
  that credential belongs to another seat, the staged file is handed to
  that seat rather than left to wait for the owner. On the day this was
  probed, `tools/staged/queue-unjam.yml` had been merged and staged and
  had never run, against a defect its own header measures in hours.)
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

- **L-X13 — Distribution is measured on `main`, not in the pull
  request list; and a re-vendor begins by reading whether the last one
  landed.** The centralizer's job is not done when the sync pull request
  is open. A vendored standard governs a seat only once it is on that
  repo's `main`, so the unit of work is the merge, and the number to
  report is the count of copies current on `main` out of the copies that
  exist — never the count of pull requests opened. Two consequences bind
  this seat. First, **before cutting a new sync, read the state of the
  previous one in every target.** Re-cutting blind stacks a second stale
  copy of the same file behind the first, and hands the merger a choice
  between two wrong versions instead of one right one; the older branch
  is closed as superseded in the same run, never left to rot. Second,
  **re-vendor every repo that carries the copy, not the subset a dispatch
  names.** A dispatch is written from what its author checked, and an
  author who checked three copies does not know that five exist; the
  portfolio table is the scope, and a repo left out stays stale with
  nobody assigned to notice. (alexandra-systems, 2026-10-05. The
  centralizer cut five re-vendor pull requests of `standards/pm.md` at
  04:06 UTC; nineteen hours later exactly one had merged — epitome #62 —
  and alexandria #216, Ursa #96, atelier-app #14 and asc-router #5 were
  still open and clean. The run that cut them reported five re-vendorings
  and the chair read that report, so at 23:27 UTC the chair dispatched
  this seat believing all five copies were current to §20 and needed only
  §21. None of them was: alexandria and atelier-app stood at §14, epitome
  at §15, Ursa at §14 with a §19 spliced in by hand, and asc-router at
  §10 pinned to 2026-09-20. The false premise came straight from counting
  pull requests as distribution. Companion to L-X7, which measures the
  queue rather than re-requesting the item, and to L-X1 as amended, where
  a fix in the tree needs something that would notice the same thing
  again — here that something is `standards/vendor.sh --check`, which
  exists and which nothing in the company runs.)

  **Amended 2026-10-12, by the prediction this rule made and lost.**
  The run that wrote L-X13 cut five re-vendor pull requests and
  predicted that copies of `standards/pm.md` current on `main` would go
  from zero of five to five of five within the week. It framed the
  prediction as a test of §21, reasoning that if the five stayed
  unmerged, hand-merging was the bottleneck. **All five merged inside
  six hours.** §21 works; the PM seats took the merges without the
  owner. And the count on 2026-10-12 was **still zero of five**,
  because HQ's `standards/pm.md` changed three more times in the six
  days that followed and `standards/lessons.md` twice, and all five
  copies sit pinned at `bee22af`. So the clause the rule was missing is
  not about merging at all: **a standard goes stale about every two
  days and hand distribution runs weekly, so distribution by hand loses
  the race by construction and no count of merges can win it.** The
  unit of work is still the merge, and the cadence of the *measurement*
  is what decides whether the merge ever gets cut. A weekly seat is the
  wrong clock for a daily defect (L-X6's cadence test, applied to this
  seat's own duty). Shipped against it: HQ's `company-checks` workflow,
  daily, which runs `standards/vendor.sh --check` across the portfolio
  and opens or refreshes one pull request per standard per repository —
  one standard per pull request, so that a `lessons.md` sync stays
  inside the single-file lane ADR-011 lets this seat merge alone.)
- **L-X14 — A failure record that does not say why is an obituary, and
  every diagnosis after it is paid for twice.** When a run fails, the
  thing the company keeps must name the cause, not the outcome. An exit
  code says a run died; it does not say whether it ran out of turns,
  lost its credential, was refused by a gate, or crashed — and those
  four take four different fixes, three of which are harness changes
  and one of which is nobody's. So a seat's run report carries the
  failure's own words: the action's error subtype, the turn count
  against the cap, and the first error line, not merely `exit 1`. And
  any surface that aggregates failures groups them by cause or admits
  in its own note that it cannot. (alexandra-systems, 2026-10-12. The
  scorecard at `GET /api/scorecard` reported the week of 2026-10-05 as
  325 runs, 534 error-level tool spans, 231 runs touched by one, and 13
  run reports that said they failed. Not one of those columns names a
  cause. In the trace store, **478 of the 487 error spans carry the
  status message `Shell command failed`** and no command and no stderr,
  because the span writer records the tool's failure and not its
  output; and the board's run report posts `exit: 0 or 1` with no
  reason field at all. Naming the week's dominant cause therefore took
  downloading **thirty-one Actions log archives** and grepping them,
  which is the one place in the system where the words
  `error_max_turns` exist. The cause, once found, was one line long and
  had been sitting in those logs for six days: see L-X3 as amended.
  Companion to L-X1 as amended — the detector that notices a recurrence
  is useless if what it records cannot be told apart from what it
  records for everything else.)

- **L-X15 — A company-wide fix is not applied until the tool that
  applies it takes every repo as an argument.** A repair that runs only
  in the repo it lives in fixes the repo whose seat happened to notice,
  and the same defect survives everywhere else with a register entry
  saying it was fixed. So when a defect is company-wide, the fix lands
  as one idempotent tool that takes repo paths, is run against every
  repo in the portfolio table in the same pass, and reports a count per
  repo read from the repaired files rather than one number for the
  invocation. (alexandra-systems, 2026-10-12 and 2026-10-14. The
  `allowed_bots` guard went onto HQ's own nine seat workflows and
  twelve action steps on 2026-10-12 and onto **none of the 43 action
  steps in the four product repos**, because
  `tools/apply-workflow-guards.sh` could only ever repair its own
  checkout and no product seat may write under `.github/workflows/`
  (Incident 5). The gap was measured and written down in the run
  report, routed to HQ's PM, and nothing moved it: two days later
  alexandria's PM landed the other half of the dispatch fix, its
  dispatch created a real run for the first time in eighteen days, and
  that run died in four seconds on `Workflow initiated by non-human
  actor: github-actions (type: Bot)` — the exact guard HQ had already
  installed on itself. The tool now takes repo paths and carries a
  `--dispatch-guards-only` mode, and the fix went into 31 files in four
  repos from one command. Companion to L-E8 as amended, where a
  workflow rule the drift check cannot test reads as undistributed no
  matter how many registers carry it, and to L-X13, where the merge is
  the distribution and the pull request is not.)

- **L-X16 — Distribute from the law, not from the draft you are standing
  in.** A tool that copies one repository's file into another must read
  the source from the ref that governs — `origin/main`, fetched, not
  assumed present — and never from `$HQ_ROOT/`, which is whatever branch
  the seat that invoked it happens to have checked out. Otherwise the
  answer depends on the invoker's directory, which means the drift
  report is unfalsifiable and the copies carry a proposal as if it were
  a rule. Three clauses: the source is a named ref and the report prints
  which one; a ref that cannot be read is "could not look" and its own
  exit code, never a silent fall back to the working tree; and
  distributing an unmerged standard on purpose is a flag the caller has
  to type. (alexandra-systems, 2026-10-18, this seat against itself.
  `tools/sync-standards.sh` measured drift on `main` as L-X13 requires
  and then read the standard out of its own checkout. At 06:27:59Z PR
  #220 merged; at 06:28:02Z PR #154 merged, moving `main` by 32 lines;
  at 06:40Z the tool, run from a branch based on the first, cut four
  syncs carrying the older text and reported them current. Same command,
  same minute, same four repositories, forty minutes later: **from the
  seat's branch "4 of 4 current", exit 0; from a `main` checkout "0 of
  4", four STALE.** The 32 lines it failed to carry were L-A18's fourth
  clause — a check that cannot read what it compares must say so instead
  of answering all-clear — so the tool broke that rule on that rule,
  twelve minutes after it landed. Fixed the same morning with `--source
  REF`, defaulting to `origin/main` materialised as a real worktree so
  the vendored header dates from `main`'s commit; re-cut, 4 of 4 current
  in 29 seconds. Companion to L-X13, where the merge is the distribution
  and the pull request is not, and to L-X15, where the fix takes every
  repository as an argument. Still owed, and the next harvest's business:
  `standards/vendor.sh --check` compares against the same `$HQ_ROOT`
  working tree and will answer the same way to anyone who calls it by
  hand.)

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
- **L-S3 — A standard written to close one incident is checked against
  the standing rules in the same territory, and two standards binding
  one artifact each cite the other.** The dangerous case is not a rule
  nobody follows. It is two rules, written days apart in different
  files by different seats, where obeying one *is* how you violate the
  other, and the seat cannot see the conflict from inside the file it
  was told to satisfy. So a clause that sets a content floor carries
  its safety convention in the same clause rather than leaving the
  convention in another document, and the seat that writes an incident
  fix into a standard greps the other standards governing that artifact
  before shipping it and names what it found. Where two standards do
  bind one artifact, each cites the other by file and section, because
  a contradiction nobody owns is discovered by the next violation.
  (Ursa incident 4, 2026-09-19/20. Ursa incident 2's fix, two days
  earlier, created a permanent rule: nothing generated from a raw
  record ships public without a redaction pass. Ursa incident 3's fix,
  the next day, added element 3 to the engineering-artifact standard in
  a different file: "at least one real example payload (actual file
  contents, not a placeholder)." The only real payload available was
  built from the private trial record, so "real" and "public-safe"
  read as opposites, and the engineer seat obeying element 3 exactly is
  what put the owner's absolute home directory and a full private
  session UUID into a public product plan — within 24 hours of the rule
  written to prevent that class, and in one instance inside the very
  README announcing the purge. Neither document cited the other. The
  register's own verdict: "a failure rediscovered is the ExO lane
  failing." Severity was genuinely low, two pointers and no content,
  and it is written up for the pattern rather than the payload.
  Companions: L-S1 owns the redaction rule itself, L-X10 covers the
  same artifact being governed from two places when the rules *agree*,
  and this one covers the case where they do not.)

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

*Empty as of 2026-10-12, and empty on arrival for the second harvest
running: nothing was appended here between 2026-09-28 and this run. The five entries that
were here once (presence is a cadence, open routing is best-effort,
sync mode, a status line is not communication, and the
continue-on-error tripwire pair) are now L-P6, L-E7, L-P7, L-A19 and
L-E8 in their own sections. Empty again as of 2026-10-18: the
one entry appended since, "a run that never started is not a run that failed",
is now L-A68 under `any` rather than under the two roles its author named,
because the rule it states binds every reader of a check.*
