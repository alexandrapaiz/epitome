# Incident register

Owned by the ExO seat. Blameless by construction: an incident entry
names what happened, what the org learned, and what changed — never a
seat at fault. An incident is a run that failed its charter, corrupted
state, or leaked something; owner quality feedback on a shipped
artifact is NOT an incident — it is lesson material and goes to
docs/agents/lessons.md.

Format per entry: date, what happened (facts only), impact, root cause
in the system (charter gap, missing lesson, tooling), the fix shipped,
and the lesson it produced (link).

## 2026-09-18 — Founding-night note (not an incident)

The org's first three owner corrections — the cycle briefing ("looks
like marketing"), the architecture document ("product architecture not
operations architecture"), and the architecture deck ("missing tooling
... not a detailed internal and comprehensive plan") — were quality
feedback on live-convened work, not failures: no charter was violated,
no state corrupted, nothing leaked. All three were absorbed as lessons
L1–L3 in docs/agents/lessons.md, with L4 capturing the repeat pattern.
Recorded here so the register's first entry marks the boundary:
correction is fuel, incident is breakage.

## Incident 1 — 2026-09-19 — Architecture deck abandoned after five revisions

**What happened.** The epito architecture presentation was revised
five times on successive owner corrections and then abandoned. Owner's
words, verbatim: "highly dissatisfied with the presentation still we
will abandon for now. ursa did a much better job."

**Impact.** The cycle's architecture artifact has no owner sign-off;
five revisions of chair time spent; the owner's confidence in
owner-facing artifacts from this org lowered against Ursa's.

**Root cause hypothesis (blameless).** Feedback-loop iteration beat
exemplar study. Each revision patched exactly the gap the owner named
(rev 3 added toolchain, dependency budget, testing, threat model; rev
4 added infrastructure and the connective stack) without ever reading
the artifact she had already approved in the same genre: Ursa
docs/design/product-plan.md and its rendered deck, the Incident-3 redo
that satisfied the engineering-artifact standard. Iterating on
described feedback converges on the description; studying the exemplar
would have shown the whole shape at once. Concretely, the abandoned
docs/architecture.md (231 lines) never met two requirements the
668-line exemplar meets literally: no diagram specified node by node
and edge by edge (engineering-artifacts.md req 1; exemplar §11 gives
three), and no real example payload anywhere — no filled agent.toml,
no sample principals.json record (req 3; the exemplar embeds real
trial JSON, "no invented figure"). Milestone done-conditions and
literal command blocks were also thinner than the exemplar's §4b and
§5. The check each revision ran was "did I add what she named," never
"does this pass the standard's checklist" or "does this look like the
artifact she approved."

**Corrective action.** Any owner-facing artifact in a genre the owner
has previously approved anywhere in the portfolio STARTS from reading
that approved exemplar in full, before the first draft. Centralized as
HQ standards/lessons.md L-A7 (interim rule, HQ incident 1); lesson L7
here.

**Standards verdict.** No standard patched: engineering-artifacts.md
already forbade what shipped (reqs 1 and 3 unmet), and documents.md
was written mid-sequence. The failure was execution and
exemplar-blindness, not a gap in the law.

## Incident 2 — 2026-09-24 → 2026-09-30 — One card built five times behind a six-deep unmerged stack

**What happened.** Cycle 1 was re-bet twice: amendment 1 on 2026-09-21,
amendment 2 out of the owner's synchronous session on 2026-09-26. The
five bets of amendment 2 were built as a six-deep PR stack — `#11 → #14
→ #15 → #16 → #17 → #21`, each PR targeting the branch below it rather
than `main` — and none of the six merged for four days.

In parallel, the identity/token card (amendment 1's bet 2) was built
five independent times:

| PR | Opened | Engine it built against |
|---|---|---|
| #9 | 2026-09-24 | epitod v0 |
| #10 | 2026-09-25 | epitod v0 (its own body already said "#9 should be closed") |
| #14/#15 | 2026-09-26 | Temporal — correct, inside the new stack |
| #20 | 2026-09-28 | epitod v0 |
| #23 | 2026-09-29 | main |

The PM seat named the duplication in #22 on 2026-09-28T19:01Z, counting
four copies and recommending #9 be closed. #23 — the fifth copy — was
opened the next day. The naming was itself in an open pull request, so
it could not bind the run that followed it.

#24 stopped the sequence on 2026-09-29: instead of a sixth copy it
merged `main` into the stack's tip, ran the five bets composed for the
first time, and fixed what that turned up. The chair merged it on the
owner's word at 2026-09-30T01:55:51Z. In the two minutes and twenty
seconds that followed — 01:55:53Z to 01:58:11Z — the owner closed ten
pull requests by hand (#9, #10, #11, #14, #15, #16, #17, #20, #21,
#23), because GitHub had recorded none of them as merged.

**Impact.**

1. **Four duplicate builds of one card.** Four engineer runs
   (#9 in part, #10, #20, #23) produced no increment the org kept. The
   copy that shipped was #14/#15, and it shipped because the engine had
   changed under it, not because the duplication was noticed.
2. **Five bets unmergeable for four days**, while the cycle's hill
   chart read as five bets moving downhill rather than as one queue.
   Cycle end was 2026-10-02; the stack landed on 09-30.
3. **Three real defects sat undetected until the day the stack
   landed**, because every suite had been run alone and none had been
   run composed. One of them loses user data: a message arriving as its
   window closes had its signal land on a completed workflow execution,
   was answered `500 {"error":"workflow execution already completed"}`,
   and whatever the person typed was gone. The second was the same race
   on `signalWithStart` for the run's own workflow id, costing the
   request. The third was a langgraph unit test asserting
   `command=python3` literally — green everywhere except a machine that
   actually has langgraph installed, which is the machine the feature is
   for. (Six "the clone is gone" assertions also raced the `cleanup`
   activity: they won on an idle box and lost under load.)
4. **Org work landed on the owner.** The stack was merged on her word
   and she then closed ten pull requests by hand inside two and a half
   minutes. That is the cost signal — the board's cleanup was nobody's
   step.

**Root cause in the system (blameless — two structural, plus one
tooling).**

- **RC-1 — Fresh-clone amnesia: an open card reads as unbuilt work.**
  Every seat run starts from a clean clone of `main` and sees its
  backlog or cycle card exactly as the last run left it: untouched. The
  work that answers the card lives on a branch the clone does not have
  and in a pull request no charter step required reading. No seat run
  was wrong on its own evidence; each was reading a board that could not
  show it work in flight. The recursion is the proof: the PM's
  correct naming of the duplication also lived in an open PR (#22), and
  so also failed to reach the next run.
- **RC-2 — The hill was drawn from cards, not from the merge queue.**
  prompts/pm-agent.md already says hill positions are "inferred from the
  engineer's actual PRs," but it never named the mechanism, so in
  practice positions came off the cycle and backlog cards. A rule with
  no command in it is advice. Drawn from cards, a six-deep unmerged
  stack renders as progress; drawn from `gh pr list`, it renders as a
  queue with one exit. The PM did run `gh pr list` on 09-28 and caught
  it immediately — which dates the gap precisely: the check happened on
  day 8 because nothing required it on day 1, and nothing anywhere
  capped stack depth.
- **RC-3 (tooling, smaller) — a stacked PR does not auto-close when its
  commits land.** GitHub closes a pull request as merged only when its
  *base* branch receives the merge. The six stack members' commits
  entered `main` inside #24's merge commit, so all six recorded as
  closed-unmerged and needed the owner's hand. Before the landing, the
  same mechanic inflated the open-PR count that any board reads: six of
  the open PRs were one unit of work.

**Corrective actions, with evidence.**

| # | Action | Status | Evidence |
|---|---|---|---|
| CA-1 | prompts/engineer-agent.md opens with "Before you build: read the open PRs": list open PRs, search closed ones, extend or propose closing an existing branch rather than copying it, prefer landing a deep stack, and name the PRs checked in the PR body — a run that skipped the step and duplicated work is a failed run | **shipped by the chair**, ratified by this run | commit e36da5b |
| CA-2 | HQ rule: an open card is not evidence that nobody built it | **shipped by the chair upstream**; rule ratified here, **its ID is contested** — see the ID note below | not in the vendored copy at `775ce36` |
| CA-3 | HQ rule: a fallback step needs `continue-on-error`, a no-ship tripwire counts commits rather than remote branches, and a paid route stays behind a variable | **shipped**, already vendored here | docs/standards/lessons.md **L-E8** (the chair's case file calls it L-E6; see the ID note) |
| CA-4 | epitome-local lessons L9 (open card), L10 (status is read from the merge queue, stacks deeper than two are a queue), L11 (landing a stack includes closing its members) | **shipped by this run** | docs/agents/lessons.md |
| CA-5 | PM charter patch: hills and duplication checks come from `gh pr list`, and any stack deeper than two is flagged. Offered alongside: the same rule for the OKR seat (which grades KRs against repo evidence and would have graded five built bets 0.0) and for the ExO seat | **proposed as diffs, awaiting the owner's merge** — this seat never ratifies its own patch | docs/agents/patches/2026-09-30-*.diff |
| CA-6 | The landing itself: `main` merged at the stack's tip, the chain run composed, three defects fixed with tests, the races made deterministic rather than coin-toss | **shipped** | #24, merged 2026-09-30T01:55:51Z |

**The ID note (for the owner and the centralizer).** The case file names
the two new HQ rules as L-E6 and L-E7. In the copy vendored into this
repo — `standards/lessons.md @ 775ce36`, vendored 2026-09-28 by #19 —
both of those IDs were reassigned the day before the case file was
written: `L-E6` became **L-E8** (the continue-on-error rule, CA-3
above) and `L-E7` is now the open-routing rule that was `L-K3`. So the
case file's "L-E6" is this repo's L-E8, and its "L-E7" (the open-card
rule) is a rule the vendored copy does not carry at all, under an ID
that is already occupied here. Either the case file quotes the
pre-renumbering IDs from memory, or the rule was filed upstream under an
ID that has since moved — in which case it is the third double-shipped
identifier after `L-K3` and `L-E6`, the pattern HQ's own L-A18 was
written for. This seat did not edit the vendored file (it is marked
do-not-edit-here) and did not renumber anything. The next lessons sync
should confirm the ID; this register cites the rules by their text so
nothing here depends on the answer.

**Standards verdict.** No HQ standard patched from this incident. Both
portfolio-level rules it produced already exist upstream in the
centralizer's hands (CA-2, CA-3); the gap that allowed the incident was
local charter mechanism — a rule that named an inference but not the
command that performs it — and that is where the fix goes.

**Where to look next.** Three open pull requests on this repo are the
same pathology, still live: #12 (2026-09-26), #13 (2026-09-26) and #18
(2026-09-27) are PM-seat work that no later PM run read, alongside #22.
A seat that cannot see its own previous run's pull request will
eventually duplicate itself, and the PM's own file is the one at risk.
Separately, #22 flagged that prompts/pm-agent.md still names Linear as
the mirror target while #12 and #16 describe a repo-owned board
replacing it — a charter-patch item for this seat, out of this run's
scope, not yet written.
