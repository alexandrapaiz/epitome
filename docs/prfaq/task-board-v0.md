# The board: an owned task manager, replacing Linear (draft v0, 2026-09-26)

Written before planning, per the company PM standard (docs/standards/pm.md
§2c, L-P5). Owner directive tonight (2026-09-26, synchronous session,
relayed by the chair), priority 1 of four: "the task manager/board that
replaces Linear (own store; seats cannot create views; run reports live
on the board)." No HQ ADR number was given verbatim for this one in the
session; it is recorded here as **ADR-037 (pending vendoring)** per the
chair's numbering, and the PM does not invent the number's content beyond
what was said.

---

**epito.me's seats get a board that is ours: no Linear key, no external
view to keep in sync, and no PM writing prose descriptions that drift
from what actually ran.**

Since ADR-5, this seat has mirrored bets and hills to Linear as a
convenience the owner glances at. It has never once had a working
LINEAR_API_KEY (docs/backlog.md, owner-only, still absent as of
2026-09-24) — every run has skipped the mirror. The board replaces that
dependency with a store this company owns: bets, scopes, and their hill
lines live in a table the PM and engineer both write to, and every
seat's run appends its report there directly instead of a human (or the
PM) transcribing it after the fact. Seats read the board; only the PM
writes structure to it (bets, scopes) — **seats cannot create views**,
so the board stays one shape, decided in the repo, not fragmented by
whichever seat last opened it.

## FAQ (what must be true to build this)

- **Q: What does "own store" mean concretely?** A durable store this
  company controls (candidates: a table in the Temporal-adjacent
  Postgres already planned for HQ ADR-036's runtime engine, or a flat
  file under version control the same way docs/cycles/ already is
  today) — not a third-party SaaS product, and not a second Linear.
  The exact storage engine is an engineering decision the engineer
  seat makes and records as a route ADR, the same pattern bet 1a used
  for the GitHub App route (docs/decisions.md).
- **Q: Why "seats cannot create views"?** The recurring failure mode
  this forecloses is a board that means something different depending
  on which seat last touched it — the same failure this repo's own
  Shape Up scopes rule guards against for the cycle file ("a bet
  without scopes is not plannable," prompts/pm-agent.md). One shape,
  PM-owned, seats populate it, nobody forks it.
- **Q: What does "run reports live on the board" replace?** Today, a
  seat's run report is a PR body plus, when `SLACK_WEBHOOK_URL` is
  configured, an optional Slack line (the "Post run report" step in
  every `.github/workflows/agent-*.yml`). The board becomes the
  durable, queryable home for that report — what ran, what shipped,
  what's still open — so the owner (or the exo audit) reads one place
  instead of reconstructing it from `gh pr list` and `gh run list` by
  hand, which is exactly what this run's standup step had to do
  (docs/standards/pm.md §11.2).
- **Q: Does this replace the cycle files and hill charts (ADR-5)?** No.
  Shape Up's mechanism (docs/cycles/, docs/pitches/) is still on trial
  until the cycle-2 review; the board is the rendering surface for that
  mechanism plus the run-report stream, not a second source of truth.
  The repo stays authoritative (playbook's board rule, restated in
  ADR-5); the board is what Linear was supposed to be and never
  reliably was.
- **Q: What's deliberately not in v0?** Multi-tenant permissions,
  seat-authored views, a UI beyond what's needed to glance at the
  current cycle and the last N run reports, and any integration with
  Linear itself (it is being replaced, not bridged).
- **Q: What happens to the LINEAR_API_KEY backlog item?** It is
  superseded, not completed — docs/backlog.md updated this run to say
  so. No owner action needed on the Linear key once this ships.
- **Q: Who builds it?** The engineer seat, sequenced behind the
  Temporal runtime engine currently in flight (PR #11) per the owner's
  stated priority order tonight (board, then Temporal — already
  building — then LangGraph+tracing, then the router). Practically:
  Temporal lands first because it is already mid-run; the board is
  next in the engineer's queue the moment PR #11 closes.
