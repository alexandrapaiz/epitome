# Backlog

Cards are readable, self-sufficient, and name a seat. Anyone adds;
the PM alone prioritizes. Seeded by the owner and chair, founding night.

## Now

- [ ] **Lessons register: owner-facing lines name decisions, never a
  code** — owner, 2026-09-27, verbatim: "i dont want to see adrs, for
  me its just random codes. id rather have good descriptions." And:
  "In everything she reads — your Slack bullets, PR opening bullets,
  the board — name a decision by what it decides, never by its
  number. No 'ADR-', no 'L-', no 'Incident N' in owner-facing lines;
  the codes stay inside the repo." This pass carried forward the scrub
  of the PM's own owner-facing artifacts (cycle files, betting memo,
  pitches) and still cannot bind the rule to every other seat or patch
  its own charter — that's a lesson entry plus charter diffs, which is
  ExO's job. Binds at minimum: pm, market, engineer (PR bodies,
  allhands minutes), exo and chair (any deck or briefing). Seat: exo.
- [x] Owner-directed (2026-09-20): runtime v0 resident — presence for epitod per docs/pitches/runtime-v0-resident.md. **Shipped 2026-09-24**: slice 1 (PR #4, epitod v0) + slice 2 (PR #6, held sessions/mailbox/windows/Slack/host) both merged; `deploy/provision-host.sh` hardened by four owner commits since against a real Oracle host (iptables vendor rule, HOME path, GH_TOKEN ordering, closing-hint text). Not independently verified from the repo: the pitch's full "done when" (HQ's pm manifest actually resident on the VM, a held window, a Slack post) — code and smoke tests exist, a live run does not show in this repo.

- [x] **Manifest spec v0.1 frozen** — spec/manifest.md reviewed against
  the three alexandria seat shapes (daily builder, weekly writer,
  event-driven responder); every field either earns its place or goes.
  Seat: engineer. **Merged 2026-10-05**: the engineer composed its whole
  open chain into one branch, verified it green from a cold machine a
  second time, and the PM merged that single branch under the merge
  authority the owner granted that morning. This card's build was one
  commit inside that chain; the validator now refuses a key the spec
  does not define.
- [x] **`epito init` + `epito validate` error polish** — errors a
  vibecoder can act on; `epito me` alias. Seat: engineer. Landed in the
  same 2026-10-05 chain merge: `epito validate --for-runtime` now names
  what the runtime will still refuse instead of ticking a readiness
  check that `run --dry-run` then contradicts. Continued 2026-10-06
  (PR #72, cooldown run): the Temporal-engine caveat now names a path
  that exists on a machine the reader actually has.
- [x] **Ship the CLI to npm** under the epitomes name once init/validate
  are stable. Seat: engineer. Packaging landed in the same chain merge:
  the packed tarball installs clean into an empty prefix at 148 KB. The
  actual `npm publish` under the owner's account is still hers to run;
  that step is not code.
- [x] **`epito deploy` v0, GitHub target** — provision a GitHub App
  principal from [identity].scopes, store nothing personal, mint
  short-lived tokens per run, wire [trigger].cron to the runtime, write
  the audit log. The hard card; split before building. Seat: engineer.
  **Landed 2026-10-05** in the same chain merge: `cli/src/deploy.js`,
  the roster reader, and the audit-log reader now exist on main.
  Continued 2026-10-06 (PR #71, cooldown run): the reconcile loop that
  wires `[trigger].cron` to the runtime. Not independently verified
  from this repo: a live `epito deploy` run against a real GitHub App
  on the owner's host — the code and its test suites exist; a
  completed live run does not show here, same gap as the
  resident-runtime card above.
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
  epito.me. Seat: engineer + owner. *Code-side risk closed this pass
  (PR #84, merged under Tier B): a box provisioned from
  `deploy/provision-host.sh` was silently losing roster secrets
  because the hand-copied env list had drifted from the manifests;
  `epito env` now generates that list from the roster itself and
  refuses a name that is set to nothing instead of running silently
  short. Carries #82's two road-naming commits forward (#82 closed,
  superseded, nothing lost). What's left is not code: one real
  alexandria seat actually running on the owner's box.*
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
  2026-09-18 (docs/market.md §3, "Positioning and pricing"). ADR-13's
  buyer-2 (agent-maker/platform tier) pricing and the "as customer"
  maker-map column shipped in rev 4, 2026-10-02 (docs/market.md,
  "ADR-13: the agent-maker-as-customer column, and pricing buyer 2
  separately") — usage-based per-mint/per-verify pricing recommended,
  owner has not yet ruled one word on it.*
- [x] **Second integration verdict: Linear REJECTED** (owner,
  2026-09-18 — ADR-6: integrations are surfaces, never dependencies).
  Market re-justifies the ranking under ADR-6 in the 10-02 map
  refresh; owner rules again on the new recommendation. Seat: market.
  *Done in rev 4, 2026-10-02 (docs/market.md, "Standing recommendation,
  re-justified under ADR-6 (rev 4)"): Slack reaffirmed under all four
  laws, no change to the pick.*
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
- [ ] **LINEAR_API_KEY repo secret** (personal API key from Linear
  settings) + name the Linear team/workspace the PM mirrors to (ADR-5).
  Optional until the PM's first run; the seat skips the mirror cleanly
  without it. *Still absent as of 2026-10-06 — this run skipped the
  mirror per charter.*
- [x] `claude setup-token` → CLAUDE_CODE_OAUTH_TOKEN repo secret, when
  ready to stand up seats. Present and working: pm/okr/exo/market/engineer
  all run on schedule (5 workflows in .github/workflows/).
- [ ] Decide public vs. private repo before any seats run on schedule
  (public = unlimited Actions minutes, per the playbook). *Seats are
  running on schedule now (line above) — this decision is overdue, not
  just pending.*
- [ ] **Bet cycle 1's close** — PR #54 carries the retro and the trial
  scorecard the ADR-5 cycle-2 review reads; merging it is the owner's
  call, not the PM's, because grading the trial is hers. Still clean
  and mergeable as of this pass (2026-10-09), unchanged for four days
  running (one rebase in between, 2026-10-08, after this file's own
  edit collided with it — resolved that pass, clean since). No
  technical blocker; this is purely her reading and her grade.
- [ ] **Bet cycle 2** — PR #67 carries the betting memo; per this
  charter the owner bets by merging it, so it waits on her hand even
  though it is clean and reviewed. *Open since 2026-10-05. Cooldown
  closed 2026-10-06; this pass (2026-10-09) is the third full day with
  cycle 2 still not bet. The engineer's only work in that gap is one
  still-open draft (#87, a preflight check), for lack of a cycle to
  point it at.*
- [ ] **Rebase the deck-archiving PR** — PR #52 went conflicting
  against main and also touches `.github/workflows/`, a surface
  product seats hand to the centralizer rather than editing; it needs
  a rebase from whichever seat opened it, not a merge from here. *Open
  since 2026-10-05, still conflicting as of 2026-10-09 (four days).*
- [x] ~~Two ExO drafts, a week old and still conflicting~~ — the exo
  seat answered last pass's handoff: #26 is closed, folded into #80;
  #32 is still open and conflicting but is now the thing #80 is
  actively deciding, not a silently stale draft, so it's left with exo
  to finish rather than re-flagged. #80 is itself still a draft
  ("work in progress" in its own body) — worth a look again if it is
  still unmoved next pass.
- [ ] **Two OKR runs graded the same quarter independently** — #39 and
  #53 each write `docs/okrs.md` from a clean baseline four days apart,
  neither aware of the other (#39 cites and closes an *older* duplicate,
  #35, but #53 opened after #39 and says the file "never existed").
  Same nine grades either way since nothing on main changed the
  evidence, but the repo should not carry two drafts racing to create
  one file a second time. Handed off to the okr seat 2026-10-07 to
  close one as superseded; still both open as of 2026-10-09, two
  passes with no action. Renewed this pass as a board handoff, with
  the one fact that decides it: #39's own body shows it checked
  `gh pr list` before building and found the older #35; #53's body
  says the file "never existed," which was never true once #35 (and
  then #39) existed. #53 is the one to close. Seat: okr.
- [ ] **Three register entries and three charter-patch diffs from the
  2026-10-05 drift review** (PR #50, merged this pass) — the lessons
  and the drift note are now on main; the three patches
  (`docs/agents/patches/2026-10-05-*.diff`) are offered, not applied.
  Applying a patch to `prompts/` is Tier C — the owner's or ExO's
  charter-patch flow, not a backlog card the PM closes itself. Seat:
  owner or exo, decision: apply, amend, or refuse each diff.
- [ ] **This charter's "Linear (the board)" section is stale and needs
  a patch** (flagged by an earlier pass, still true). The board the
  standard and this repo actually use now is the shared company board
  (`BOARD_API_URL`/`BOARD_RUNTIME_TOKEN`), not Linear; this pass read
  and wrote it successfully again. Not mine to self-apply — charters
  are owner- or exo-edited only. Seat: pm (flagged), decision: owner
  or exo.
- [x] ~~This seat's own knowledge-surface pull requests cannot land
  themselves~~ — resolved a third time now: #73, #74 and #77 each
  carried real backlog edits, each got asked for by name, and each got
  merged by HQ's PM or a chair, inside a pass or two of the ask
  landing every time. The ask route is proven three times over; the
  only live risk is this seat forgetting to use it.
- [x] **PR #51 closed, superseded.** The engineer's own composing run
  (PR #75) found that #51's branch is 1,096 lines behind main — merging
  it would have deleted most of `docs/standards/pm.md`,
  `prompts/exo-agent.md`, and other content that landed in the
  2026-10-05 chain merge after #51 was opened. Verified independently
  (`git diff origin/main` against the PR's head) before closing rather
  than taking the engineer's word for it. Seat: pm, closed 2026-10-06.
- [x] **Engineer's composed stack landed.** PR #78 carried #75's tip
  forward (ready, not draft), closed the five PRs it contained
  (#51 already closed; #65, #69, #71, #72, #75 closed as superseded
  with a comment naming #78 on each), and added the fix that makes the
  green claim reproducible on a machine nobody prepared by hand: a
  prereqs installer for the Temporal CLI and langgraph, a shared dev
  server across suites, a docker-daemon probe that tells the daemon's
  own error apart from a missing binary, and a locale pin for the ✓/!
  columns six assertions read. **Merged 2026-10-07 under Tier B**:
  clean against main, no checks defined, diff limited to `cli/`, the
  test harness, `docs/ideas.md` and `docs/prfaq/`, no Tier C path, not
  this seat's own PR. The engineer seat now has zero open PRs. Seat:
  engineer.
