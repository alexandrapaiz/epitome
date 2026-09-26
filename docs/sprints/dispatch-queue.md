# Dispatch queue — 2026-09-26 (synchronous window)

Mode: **synchronous** (docs/standards/pm.md §11.4, L-P7). The chair
opened a work window; the owner is present and steering through this
seat rather than prompting seats herself. Ceilings still hold (three
PM dispatches/day, one per seat, ten/rolling week); read from
`gh run list`, not memory.

## What the standup read this run

- `gh run list --limit 30`: one engineer run **in progress**
  (36205589579, started 2026-09-26T00:38:30Z, branch
  `engineer/2026-09-26-epitod-v1-temporal`, still running at the time
  of this queue); all prior runs completed success.
- `gh pr list --state open`: #9, #10, #11 — all engineer, all draft.
  #11 is the newest and is the branch the in-progress run is building
  on (Temporal runtime engine, HQ ADR-036).
- No sprint/pending file exists in this repo (Shape Up, not Scrum);
  read docs/cycles/2026-09-21-cycle-1.md and its amendment instead.
- No rulings since the last PM run (PR #8, 2026-09-24) other than
  tonight's synchronous-session directive itself.
- Linear: no LINEAR_API_KEY, mirror skipped (moot — see below).

## Proposed entries

1. **Trigger:** owner directive tonight, priority 1 (task
   manager/board replacing Linear). **Cost of skipping:** the Working
   Backwards doc doesn't exist yet and nothing is plannable without it
   (company PM standard §2c). **Action taken this run, not a dispatch:**
   the PM wrote docs/prfaq/task-board-v0.md directly — this is PM work,
   not engineer work, so no `gh workflow run` was needed for it.
2. **Trigger:** owner directive tonight, priority 1 build, and
   priority 3 (LangGraph + tracing, Phoenix). **Cost of skipping:**
   they queue behind Temporal, which is correct — the owner's own
   priority order puts the board ahead of Temporal in her list, but
   Temporal was already mid-build before this window opened, and
   pulling the engineer off a running PR to start a second branch
   would violate the hard stop (never dispatch a seat whose last PR is
   open, unless told to build on that branch) and risks the exact
   concurrency failure this standard's own lesson names (L-K3, HQ
   Incident 4: two runs racing the same provider slot both died).
   **Exact dispatch command, queued, not yet fired:**
   `gh workflow run agent-engineer.yml -f owner_instructions='PR #11
   (Temporal, HQ ADR-036) is next: once it is ready for review, do not
   open a new branch — build on engineer/2026-09-26-epitod-v1-temporal
   until it closes. When it closes, the next scope in queue is the
   task manager/board (docs/prfaq/task-board-v0.md, owner priority 1,
   synchronous session 2026-09-26): own store, seats cannot create
   views, run reports live on the board. After that, LangGraph with
   tracing (Phoenix is installed) is priority 3, then the router is
   priority 4. Own-model hosting (vLLM) is dropped — do not pick it
   up. Evidence: docs/backlog.md "Now" (2026-09-26 entry),
   docs/prfaq/task-board-v0.md.'`
   **Not fired this run** because PR #11's run is still in progress;
   firing now would be a second engineer run before the first has
   shipped, exactly the pattern L-K3 warns against. Fire it the moment
   run 36205589579 completes (success or failure) — that is this
   session's next action once the chair's follow-up confirms or the
   run notification lands.
3. **Trigger:** none found. Market's last open item (ADR-13 pricing
   rev 2, docs/backlog.md "Next") and OKR's Q4 grading are real but
   nothing in tonight's session names them, and inventing a dispatch
   for them tonight would violate "never invent a judgment" — they
   stay on their existing cadence (market: Friday cron; OKR: monthly).

## Dispatched by the PM

None this run. Reason: the one seat capable of tonight's build
priorities (engineer) is already mid-run on the highest-priority item
that was already in flight (Temporal); dispatching a second run onto a
different branch violates the open-PR hard stop and the known
concurrency failure mode. This is a queue, not a stall — see proposed
entry 2 for the exact command staged to fire on completion.
