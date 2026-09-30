# Proposed charter patches

The ExO seat proposes charter changes as diffs and never merges its own.
Everything in this directory is **unratified**: the owner reads the diff,
and applying it is her decision, not this seat's.

Each file applies against the tree it was cut from:

```
git apply docs/agents/patches/<name>.diff
```

A patch is deleted from this directory once the owner has applied it (or
ruled against it), so a file sitting here is an open question.

## 2026-09-30 — incident 2, "read the open PRs" and its seat-by-seat verdict

Incident 2's first root cause is that every seat run starts from a fresh
clone of `main`, where work in flight is invisible. The dispatch asked
for the PM patch and for a ruling on whether other charters need the
same rule. They are not all the same rule — the fresh-clone blind spot
produces a different symptom in each seat, so each patch names its own.

| Seat | Verdict | Symptom the blind spot produces there |
|---|---|---|
| engineer | **already shipped** (commit e36da5b, by the chair; this run ratifies it) | builds a second copy of a card an open PR already answered — five times over |
| pm | **patch proposed**: `2026-09-30-pm-hills-from-the-pr-list.diff` | draws the hill from cards, so a six-deep unmerged stack reads as five bets moving downhill |
| okr | **patch proposed**: `2026-09-30-okr-evidence-includes-unmerged-prs.diff` | the same blind spot, the opposite error: its charter grades KRs against repo evidence and grades "no evidence" 0.0, so five bets that existed only in unmerged PRs would have been scored as never built |
| exo | **patch proposed**: `2026-09-30-exo-read-the-register-prs.diff` | two runs appending to the same register from separate clones produce duplicate rule IDs — the failure HQ's L-A18 exists for, and the reason this incident's own case file cites `L-E6`/`L-E7` one day after both were reassigned |
| market | **no patch.** It owns one living brief (docs/market.md) rewritten each week from outside sources; a stale open market PR costs a merge conflict, not a duplicated build, and it has never had two runs in flight. It inherits L9's "your own seat's previous runs" clause without new charter text. If the owner would rather the rule be uniform across seats, the exo diff's paragraph is the form to copy | — |
| smoke | **no patch.** It opens no PR, creates no branch and writes no file | — |
| chair | **no patch, and no charter file in this repo** — `prompts/` holds no chair charter. The chair is the seat that did read the PRs: #24 landed the stack rather than adding to it. Its one exposure in this incident is register-ID staleness, which the exo diff covers | — |
