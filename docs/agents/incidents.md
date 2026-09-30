# Incident register

Owned by the ExO seat. Blameless by construction: an incident entry
names what happened, what the org learned, and what changed — never a
seat at fault. An incident is a run that failed its charter, corrupted
state, or leaked something; owner quality feedback on a shipped
artifact is NOT an incident — it is lesson material and goes to
docs/agents/lessons.md.

One addition to that definition, on HQ L-X9's authority (2026-09-30): a
duty a seat cannot reach with the credential it was given is an incident
too, even when the run that hit the wall failed nothing and reported it
correctly. The unit of failure there is the distribution path that handed
out the duty without the reach, never the run that found the wall.

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

## Incident 3 — 2026-09-30 — The PM was given failed-run triage, and its token cannot list runs

*(Incident 2 is the entry in flight in PR #26, read before this one was
written and not renumbered.)*

**What happened.** Decision 041, vendored into this repo by PR #29, gives
the PM seat §11.7: triage this company's failed runs of the last 24
hours, every run, starting with `gh run list --status failure`. The duty
reached the seat on 2026-09-30 through a board message and a dispatch.
PM run 36661147282 (2026-09-30T02:43Z, `workflow_dispatch`) attempted it
and got 403 from `gh run list` and from
`gh api repos/.../actions/{runs,workflows}` on all four tokens present
in the job environment. The cause is not a token: the `permissions:`
block of `.github/workflows/agent-pm.yml` grants `contents: write`,
`pull-requests: write`, `id-token: write` and has no `actions:` key at
all. The run recorded this in the body of PR #30 and stopped, which was
correct and is not the failure here.

**Impact.** The triage duty did not run on the day it was assigned.
`workflow_dispatch` needs the same scope, so §11.3 dispatch is blocked
by the same gap — one missing key holding three of the duties decision
041 hands the PM. And nothing outside an unmerged PR body knew: the
entry you are reading exists because a different seat, woken by a
different launcher, could run the command.

**The triage itself, performed from this run's lane.** Zero failed runs
in the last 24 hours; zero in the last six days. The only failed run in
this repository's history is 35956231272 (2026-09-24T04:34Z, pm-agent),
which is the run HQ's L-E8 was written from and was fixed 2026-09-25.
The blocked queue was empty. That belongs in the record because it sizes
the fix honestly: merging #29 restores a duty with no backlog, and
unblocks rerun and dispatch, which do have work.

**Root cause in the system.** Three parts, none of them a seat.

1. A duty was distributed by a standard while the credential that
   performs it lives in a file the receiving seat may not edit — Tier C
   by §10, and the board's claim-before-edit rule sends workflow fixes
   to `alexandra-systems/exo-centralizer`. Nothing in the distribution
   path checks the two together. This is HQ L-X9 exactly: a seat's lane
   is bounded by its token, not by its charter, and it wins silently
   until something tries.
2. The gap is general, not the PM's. None of this repository's five seat
   workflows carries an `actions:` key, so no seat can read the repo's
   own run history from the Actions lane. `for f in
   .github/workflows/agent-*.yml; do grep -c 'actions:' $f; done` → five
   zeroes.
3. The same seat can read runs from the other lane. This ExO run listed
   every run in the repository's history with the same `gh` command,
   because the resident runtime hands it a host PAT rather than a
   workflow token. A seat's reach depends on which launcher woke it,
   which is L11.

A fourth thing is worth recording without blame attached: §11.7 as
written states "The PM workflow carries `actions: write` for the rerun."
The standard and the permission ship in the same pull request, #29,
which is the right construction. The gap was the hours between the duty
arriving at the seat and that PR merging.

**Fix.** Not shipped by this run, and it cannot be: `actions: write` is
already written and waiting in PR #29, which is Tier C and the owner's
merge alone. Per L-X7 the honest record is the queue rather than a
second request, so: #29 was 1.5 hours old when this was written and is
blocking nothing that has work in it. That is a young fix, not a
bottleneck, and this entry says so rather than inflating it. The
standing queue number is separate and is in the run's PR body.

**Lessons.** HQ L-X9 (the authority for filing this at all, and for the
definition added to this register's preamble above); L11 here (reach
follows the launcher); L-X7 for the reporting form.
