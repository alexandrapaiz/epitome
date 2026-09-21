<!-- vendored-from: standards/lessons.md @ 9605e550a39742ea583ea93a796c1e49e05fd578 -->
> **Vendored copy — do not edit here.** Source of truth is
> `alexandrapaiz/alexandra-systems` `standards/lessons.md` at commit `9605e55`,
> vendored 2026-09-21. Changes to a company standard are HQ
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
  work.)
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
