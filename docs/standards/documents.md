<!-- Vendored from alexandrapaiz/alexandra-systems standards/documents.md @ 721127d (2026-09-19). Deviations belong in docs/decisions.md. -->

# Standard: Owner-Facing Documents and Presentations

The document practice fixed by the owner across two products in two
days (epitome briefing and architecture corrections, 2026-09-18; Ursa
presentation correction, 2026-09-19: "i have the same dissatisfaction
with this presenattion"), with Ursa's CLAUDE.md as the worked
exemplar. A product adopts this by vendoring this file into its repo
(`docs/standards/documents.md`, with a header naming the source
commit) and pointing its seats' lesson registers at it. Deviations are
allowed per product and recorded in that product's decisions file.
Changes to this standard are HQ ADRs.

It governs shape and register for every document or presentation a
seat ships to the owner. Content requirements for engineering plans
and specs live in engineering-artifacts.md; when a document is one of
those, both standards apply and that one's six requirements are the
content bar.

## 1. The shape (the Ursa moves)

Every owner-facing document is built from these structural moves,
taken from the exemplar:

- **Orientation first.** The opening section is titled to be read
  first and gives the whole shape in roughly a page, so a reader who
  stops there still holds the structure. Comparisons go in tables,
  not paragraphs.
- **Priorities marked in words.** The document says which section
  matters most ("If you only internalize one section, make it this
  one") and flags the single most valuable item where one exists. A
  document that weights everything equally has not been finished.
- **Load-bearing constraints as numbered laws.** The rules the design
  must not route around appear as a short numbered list, labeled so
  ("do not design around these"), never scattered through prose.
- **Data at the literal level.** Names appear as they appear in code
  or on disk, as backtick literals (`survived_verbatim`, a real path,
  a real flag), never as summaries of what the names are like.
- **A closing section addressed to whoever works on it.** It names
  the central problem in one sentence and gives the design test to
  check every decision against.
- **Honest tensions stated plainly**, including the ones that argue
  against the product ("the software is explicitly not the moat").
  A document with no tension named has hidden one.

## 2. The register (the epitome lessons)

- **Mechanism is the spine.** Real files, commands, numbers, and
  tradeoffs with unknowns named as unknowns. Process vocabulary may
  annotate the mechanism, never stand in for it. The test: the owner
  could reconstruct what is being proposed from the artifact alone.
- **"Architecture" means system design.** Components, interfaces as
  code or schemas, data model, wire-level flows. Rollout and org
  material is a different document under a different title.
- **"Comprehensive" means an engineer could start.** Toolchain with
  reasons, dependency budget, testing strategy, threat model. Missing
  those, the document calls itself a sketch, not a plan.
- **House voice.** Plain sentences, transition words, no stylistic em
  dashes or semicolon joins, no flourish. Sell the product, never the
  recipe.

## 3. The pre-ship checklist

A seat runs this against any owner-facing document or presentation
before it ships. Every item is yes or the artifact does not ship.

1. Does the opening section give the whole shape in about a page,
   with comparisons as tables?
2. Could the owner reconstruct the actual proposal (what will exist,
   what it costs, what is uncertain) from this artifact alone?
3. Does the document say in words which section or item matters most?
4. Are the load-bearing constraints a numbered list labeled as rules
   the design must not route around?
5. Is every technical name a backtick literal as it appears in code
   or on disk, never a summary?
6. Is at least one honest tension stated plainly, including any that
   argues against the product?
7. Does a closing section address whoever works on it, naming the
   central problem and the design test?
8. Does the title match the content — architecture only over system
   design, comprehensive or plan only when an engineer could start
   from it (then engineering-artifacts.md applies in full)?
9. Is the prose in the house voice throughout?
10. If this is a presentation, does every slide or cell trace to a
    sentence in an underlying document that itself passes 1–9?

## 4. Enforcement

A checklist violation the owner has to catch herself is an ExO
trigger in that product; her words go to the ExO seat verbatim. The
ExO seat audits by checklist item, not by impression. A defect on
this standard recurring across products is an HQ ADR candidate, never
a per-product patch.
