# Backlog

Cards are readable, self-sufficient, and name a seat. Anyone adds;
the PM alone prioritizes. Seeded by the owner and chair, founding night.

## Now

- [ ] **Owner-directed (2026-09-26, synchronous session): four
  priorities, in order** — 1) the task manager/board replacing Linear
  (own store; seats cannot create views; run reports live on the
  board; docs/prfaq/task-board-v0.md), 2) Temporal as the runtime
  engine (HQ ADR-036; server live on the host) — **already in flight**,
  PR #11, 3) the LangGraph implementation with tracing (Phoenix
  installed), 4) the router. Own-model hosting (vLLM) is dropped —
  not a card, a closed question. Seat: engineer, one at a time
  (WIP limit already in force per the hard-stop on dispatching a seat
  whose last PR is still open).

- [x] Owner-directed (2026-09-20): runtime v0 resident — presence for epitod per docs/pitches/runtime-v0-resident.md. **Shipped 2026-09-24**: slice 1 (PR #4, epitod v0) + slice 2 (PR #6, held sessions/mailbox/windows/Slack/host) both merged; `deploy/provision-host.sh` hardened by four owner commits since against a real Oracle host (iptables vendor rule, HOME path, GH_TOKEN ordering, closing-hint text). Not independently verified from the repo: the pitch's full "done when" (HQ's pm manifest actually resident on the VM, a held window, a Slack post) — code and smoke tests exist, a live run does not show in this repo.

- [ ] **Manifest spec v0.1 frozen** — spec/manifest.md reviewed against
  the three alexandria seat shapes (daily builder, weekly writer,
  event-driven responder); every field either earns its place or goes.
  Seat: engineer. (Draft shipped founding night.)
- [ ] **`epito init` + `epito validate` error polish** — errors a
  vibecoder can act on; `epito me` alias. Seat: engineer. (v0 shipped
  founding night.)
- [ ] **Ship the CLI to npm** under the epitomes name once init/validate
  are stable. Seat: engineer.
- [ ] **`epito deploy` v0, GitHub target** — provision a GitHub App
  principal from [identity].scopes, store nothing personal, mint
  short-lived tokens per run, wire [trigger].cron to the runtime, write
  the audit log. The hard card; split before building. Seat: engineer.
  *Split done; identity slice bet in cycle 1
  (docs/pitches/deploy-identity-v0.md, docs/cycles/2026-09-21-cycle-1.md),
  then reduced by the owner's 2026-09-20 amendment to just the
  token-minting slice the runtime consumes (`epito token <name>`).
  As of 2026-09-24: no code for it in cli/src — zero visible engineer
  time this cycle, which ends 2026-10-02.*
- [x] ~~Runtime v0, reshaped as bring-your-own-agent (owner ruling R4)~~
  — overtaken by events: the owner didn't wait for a cycle-2 rewrite,
  she re-bet cycle 1 to the resident runtime directly (the amendment,
  2026-09-20). `docs/pitches/runtime-v0-actions.md` is marked
  superseded by runtime-v0-resident.md, not rewritten — see below.
- [x] ~~Runtime v0 (original shape, GitHub Actions)~~ — superseded, not
  re-bet: `docs/pitches/runtime-v0-actions.md` now heads itself
  "Superseded 2026-09-20 by runtime-v0-resident.md"; the Actions
  runtime lives on only as HQ's own async heartbeat (its seats still
  run as Actions jobs, per .github/workflows/agent-*.yml).
- [ ] **Dogfood migration, step 1** — one alexandria seat runs on
  epito.me. Seat: engineer + owner.
- [ ] **Dogfood migration, step 2** — delete that seat's ADR-27
  hand-wiring from alexandria. Seat: engineer.
- [ ] **Dogfood migration, step 3** — write the before/after; this is
  the launch post. Seat: engineer + owner.

## Next

- [x] **OKR seat stood up** (playbook order: purpose before planning) —
  mission → objectives + benchmark. Seat: okr. `.github/workflows/agent-okr.yml`
  live, docs/allhands/2026-09-20-okr.md shipped.
- [x] **PM/COO seat on schedule** — cycles, board, this backlog;
  `.github/workflows/agent-pm.yml` live (this run is one of its firings).
  Seat: pm.
- [x] **ExO seat** — incident register live before the builders multiply.
  `.github/workflows/agent-exo.yml` live; docs/agents/incidents.md and
  lessons.md exist; PRs #2, #7 are its lesson syncs. Seat: exo.
- [ ] **Market seat brief #1: pricing** — per-active-agent pricing vs.
  roster tier; who pays today for Clerk/Fly/Trigger.dev glue and what do
  they pay. Before any public pricing. Seat: market. *Rev 1 shipped
  2026-09-18 (docs/market.md §3, "Positioning and pricing"). Rev 2 still
  open: ADR-13 (2026-09-20) requires pricing buyer 2 (the agent-maker/
  platform tier) separately from the roster tiers — not yet done.*
- [x] **Second integration verdict: Linear REJECTED** (owner,
  2026-09-18 — ADR-6: integrations are surfaces, never dependencies).
  Market re-justifies the ranking under ADR-6 in the 10-02 map
  refresh; owner rules again on the new recommendation. Seat: market.
- [ ] **`epito` MCP server + Claude Code/Cursor skill** — the market
  map's near-zero-cost distribution side-bet: reach every editor
  session. *Shaped and bet in cycle 1 (docs/pitches/epito-mcp-server.md,
  docs/cycles/2026-09-21-cycle-1.md).* Seat: engineer.

## Later (features that emerge from accumulated manifests)

- [ ] Teams: shared roster, shared audit, org controls (the paid tier).
- [ ] Convening: meetings as rosters with minutes; identity visible in
  the room.
- [ ] The agent repository: publish/install manifests as principals;
  ADR-2's three-part test as the admission bar.

## Owner-only (secrets, money, accounts)

- [ ] Register **epito.me** (verified available 2026-09-18; a few
  dollars; .me is Montenegro's registry — dictionary-adjacent names can
  be premium-priced, confirm at checkout).
- [ ] **Make the repo public before the passport ships** (owner ruling R3, 2026-09-20). Timing: at the passport's first publish. Prereq: security seat audits history for anything personal; the manifest rule (nothing personal in files) has held since founding, verify it.
- [x] ~~LINEAR_API_KEY repo secret~~ — **superseded, 2026-09-26**: owner
  directive tonight (synchronous session, priority 1 of four) replaces
  Linear with an owned task manager/board (own store; seats cannot
  create views; run reports live on the board). See
  docs/prfaq/task-board-v0.md. No owner action needed on the Linear
  key; ADR-5's Linear-mirror clause is superseded pending that build.
- [x] `claude setup-token` → CLAUDE_CODE_OAUTH_TOKEN repo secret, when
  ready to stand up seats. Present and working: pm/okr/exo/market/engineer
  all run on schedule (5 workflows in .github/workflows/).
- [ ] Decide public vs. private repo before any seats run on schedule
  (public = unlimited Actions minutes, per the playbook). *Seats are
  running on schedule now (line above) — this decision is overdue, not
  just pending.*
