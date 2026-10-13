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

## Incident 2 — 2026-10-12/13 — Scheduled runs dying before a runner is assigned

**What happened.** Three scheduled runs failed within the same signature
across two six-hour passes: `pm-agent` run
[38305248719](https://github.com/alexandrapaiz/epitome/actions/runs/38305248719)
(2026-10-12 20:35:50 UTC) and `engineer-agent` run
[38304103670](https://github.com/alexandrapaiz/epitome/actions/runs/38304103670)
(2026-10-12 20:25:18 UTC) both completed in 2-3 seconds with an empty
`steps` array and `runner_id: 0`. Each was rerun once
(`gh run rerun --failed`), and each rerun attempt failed the identical
way at 2026-10-13 00:22-00:24 UTC. A third, independent occurrence —
`engineer-agent` run
[38343913575](https://github.com/alexandrapaiz/epitome/actions/runs/38343913575)
(2026-10-13 03:54:37 UTC), a fresh scheduled dispatch, not a rerun —
died the same way. No rerun was attempted against this third one, per
the standard's own rule that two identical failures in a row are the
incident rather than a reason to try a third time.

**Impact.** Two different seats' scheduled dispatches lost entirely —
neither run ever reached a model turn, so no work was attempted and
none was lost, but the schedule itself did not execute three times
running. `gh api repos/alexandrapaiz/epitome/actions/permissions`
answers 403 to this repository's token, so the cause cannot be
confirmed from inside the repo: it reads as something above either
workflow (a runner-capacity limit, a spend ceiling, or an
organization-level policy), not a defect in one seat's file, because
two unrelated workflows failed the same way within ten minutes of each
other and a third failed the same way again hours later.

**Root cause.** Not yet determined from this repository's own
credentials. Handed to `alexandra-systems/exo-centralizer` as a board
handoff on 2026-10-13 00:25 UTC, still unanswered as of the pass that
re-files this entry (2026-10-13 12:22 UTC).

**The fix shipped.** None yet; this is a standing handoff, not a
closed loop. No further reruns are warranted against this signature
until the cause is known.

**Lesson.** Pending the centralizer's answer; filed as a lesson once
the cause is confirmed rather than guessed.
