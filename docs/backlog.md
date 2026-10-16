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
  epito.me. Seat: engineer + owner. *Code-side risk closed 2026-10-08
  (PR #84, merged under Tier B): a box provisioned from
  `deploy/provision-host.sh` was silently losing roster secrets
  because the hand-copied env list had drifted from the manifests;
  `epito env` now generates that list from the roster itself and
  refuses a name that is set to nothing instead of running silently
  short. Carries #82's two road-naming commits forward (#82 closed,
  superseded, nothing lost). Extended 2026-10-09 (PR #89, merged under
  Tier B): `epito doctor` now answers whether a seat on this box has a
  GitHub identity of its own or falls back to a shared credential —
  run against this company's own five seats, the answer is that none
  of them do, which is the exact gap step 1 is about. Whose credential
  a seat acts as is named in `docs/ideas.md` as three options and left
  there for the owner, not decided inside a run. Extended again
  2026-10-10 (PR #97, merged under Tier B): `epito doctor --deep` now
  reads the App's own slug and owner from GitHub, so a refusal that used
  to name a fix with no page to find it now prints the actual
  installation or permissions page to visit. What's left is still not
  code: one real alexandria seat actually running on the owner's box,
  now also waiting on that credential decision.*
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
  and mergeable as of this pass (2026-10-16), unchanged for ten days
  running since cooldown closed (2026-10-06). No technical blocker;
  this is purely her reading and her grade.
- [ ] **Bet cycle 2** — PR #67 carries the betting memo; per this
  charter the owner bets by merging it, so it waits on her hand even
  though it is clean and reviewed. *Open since 2026-10-05, now eleven
  days unbet. The engineer keeps spending its runs on ordinary
  backlog work for lack of a cycle to point it at, when it can run at
  all: it has not completed a run since 2026-10-12 (nine straight
  failures through this pass, same dead-runner shape each time). That
  register entry is `docs/agents/incidents.md`'s to write, not this
  file's or this seat's own merge to make — handed off to this
  repo's exo seat this pass, since the file's own header names it the
  owner and no entry exists there yet for a defect four days old.*
- [ ] **Rebase the deck-archiving PR** — PR #52 went conflicting
  against main and also touches `.github/workflows/`, a surface
  product seats hand to the centralizer rather than editing; it needs
  a rebase from whichever seat opened it, not a merge from here. *Open
  since 2026-10-05, still conflicting as of 2026-10-16 (eleven days).*
- [x] ~~Two ExO drafts, a week old and still conflicting~~ — #26 closed,
  folded into #80 the exo seat opened to decide what the other, #32,
  still held. #80 itself sat three days as an unfinished "work in
  progress" draft with no further commits, so this pass closed #32
  outright (idle 10 days, conflicting since the day it opened, and the
  seat meant to carry its content forward never did) rather than
  re-flag it a third time. #80 stays open; worth a look if it is still
  unmoved next pass.
- [x] **Two OKR runs graded the same quarter independently — resolved.**
  #39 and #53 each wrote `docs/okrs.md` from a clean baseline, neither
  aware of the other; #53 was the one carrying no new fact over #39
  (its body said the file "never existed," which was never true once
  #35, then #39, existed), so a PM pass closed #53 outright under the
  merge authority this repository grants. #39 is still open and still
  draft — it needs the okr seat or the owner to ready and merge it;
  the okr seat's next scheduled run is 2026-11-01. Seat: okr or owner.
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
- [x] **This seat's own knowledge-surface pull requests cannot land
  themselves — resolved.** The ask route to HQ's PM worked six times
  running (#73, #74, #77, #79, #85, #88), then broke on #90 and #90's
  successor #91 with a 404 reading this repo at all. HQ's PM answered
  the renewed ask 2026-10-09 17:27 UTC with that diagnosis and handed
  #91 to the owner per standards/pm.md §10. Later the same evening
  (2026-10-09 18:30 UTC) HQ's PM checked its own access again rather
  than trusting the one-run finding, found it could in fact reach this
  repo, and merged #92 itself — the route is confirmed working again,
  not just diagnosed. Whatever was wrong was transient or scoped to
  that one run; no further owner action needed on this specific gap.
  Seat: pm, closed 2026-10-10.
- [x] **The same ask route, renewed for this seat's six-hour-pass
  reports — resolved again.** #120 and its successor #121 (both docs-
  only, `docs/backlog.md` alone) merged together 2026-10-15 12:23 UTC,
  the owner's own merge this time rather than HQ's pm. Seat: pm, closed
  2026-10-15.
- [ ] **The same gap, twice over in one six-hour window.** The
  2026-10-16 00:20 pass opened #122 and the 06:20 pass opened #123,
  each editing this same entry independently because neither pass's
  branch could see the other's still-open PR — both cut from the same
  point on main. This pass closed #122 as superseded by #123 (its edit
  carried forward everything #122's did, plus more), so the queue
  carries one redundant report instead of two. #123 is still open with
  nobody able to merge it but HQ's pm or the owner; renewed the ask to
  `alexandra-systems/pm` again this pass, alongside this pass's own
  report. Seat: pm (flagged), decision: HQ's pm or the owner. Worth a
  fix if a third pass lands in the same window again: the ask route
  works, but two passes racing the same file in under six hours is the
  shape L-E10 already named.
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
