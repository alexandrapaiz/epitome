# Backlog

Cards are readable, self-sufficient, and name a seat. Anyone adds;
the PM alone prioritizes. Seeded by the owner and chair, founding night.

## Now (the wedge)

- [ ] **Manifest spec v0.1 frozen** — spec/manifest.md reviewed against
  the three alexandria seat shapes (daily builder, weekly writer,
  event-driven responder); every field either earns its place or goes.
  Seat: engineer. (Draft shipped founding night.)
- [ ] **`epito init` + `epito validate` polished** — errors a vibecoder
  can act on; `epito me` alias; ship to npm under the epitomes name once
  stable. Seat: engineer. (v0 shipped founding night.)
- [ ] **`epito deploy` v0, GitHub target** — provision a GitHub App
  principal from [identity].scopes, store nothing personal, mint
  short-lived tokens per run, wire [trigger].cron to the runtime, write
  the audit log. The hard card; split before building. Seat: engineer.
- [ ] **Runtime v0** — one container per agent that survives sessions and
  wakes on the trigger; start on GitHub Actions (the $0 stack the target
  users already have), containerized image as the second step. Seat:
  engineer.
- [ ] **Dogfood migration** — one alexandria seat runs on epito.me;
  delete its ADR-27 hand-wiring; write the before/after. This is the
  launch post. Seat: engineer + owner.

## Next

- [ ] **OKR seat stood up** (playbook order: purpose before planning) —
  mission → objectives + benchmark. Seat: okr. Owner prerequisite:
  CLAUDE_CODE_OAUTH_TOKEN secret.
- [ ] **PM/COO seat** — sprints, board, this backlog. Seat: pm.
- [ ] **ExO seat** — incident register live before the builders multiply.
  Seat: exo.
- [ ] **Market seat brief #1: pricing** — per-active-agent pricing vs.
  roster tier; who pays today for Clerk/Fly/Trigger.dev glue and what do
  they pay. Before any public pricing. Seat: market.
- [ ] **Second integration: owner's verdict pending** — the market
  seat's standing recommendation (docs/market.md, 2026-09-18) is
  **Linear** (agents are first-class "app users" there; directory
  distribution; dogfoods ADR-5), runners-up Vercel then Supabase. One
  word from the owner accepts or rejects. Seat: market → owner.
- [ ] **`epito` MCP server + Claude Code/Cursor skill** — the market
  map's near-zero-cost distribution side-bet: reach every editor
  session. Shape as a pitch. Seat: pm.

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
- [ ] **LINEAR_API_KEY repo secret** (personal API key from Linear
  settings) + name the Linear team/workspace the PM mirrors to (ADR-5).
  Optional until the PM's first run; the seat skips the mirror cleanly
  without it.
- [ ] `claude setup-token` → CLAUDE_CODE_OAUTH_TOKEN repo secret, when
  ready to stand up seats.
- [ ] Decide public vs. private repo before any seats run on schedule
  (public = unlimited Actions minutes, per the playbook).
