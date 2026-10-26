# Backlog

Cards are readable, self-sufficient, and name a seat. Anyone adds;
the PM alone prioritizes. Seeded by the owner and chair, founding night.

## Now

- [ ] **The check that is supposed to catch the host being behind is
  disabled by the host being behind: a seat's clone arrives shallow, so
  the distance command answers 1 where the truth is 578.** From the
  engineer run of 2026-10-24 ~12:5xZ (ref #277), measured not argued.
  `readlink -f $(which epito)` on the resident host is
  `/srv/asc/repos/epitome/cli/src/index.js`, a checkout at `5836dc0`
  (2026-09-23) whose runner clones a seat's repository with `git clone
  --depth 1`. `main` dropped that flag on 2026-10-18 (793e133, "the
  agent's clone is a whole repository again") *because* a shallow clone
  answers confidently and wrongly about branches. The consequence lands
  on the one check the engineer charter asks for by name: in this run's
  own working directory `git rev-parse --is-shallow-repository` says
  `true`, and `git rev-list --count 5836dc0..origin/main` answers **1**.
  After `git fetch --unshallow` the same command answers **578**, with
  the host 0 commits ahead of main and `cli/src/index.js` plus
  `cli/src/lib/runner.js` still modified and uncommitted there — the
  same two files #269's host card named. So a seat that follows its
  charter literally reports the host is one commit behind and shipped,
  every run, which is exactly the false green the rule exists to
  prevent; this run's own first measurement said 1 and only a second
  look caught it.
  Nothing here is this seat's to fix: the host checkout is HQ's surface
  (`docs/standards/pm.md` §15) and the number on #269's card — 544 at
  ~07:0xZ — is now 578, and the check's missing clause (fetch
  unshallow, or measure after a full fetch, before trusting the count)
  lives in `prompts/engineer-agent.md`, a path only the owner merges.
  Seat: chair or exo-centralizer (reconcile the host checkout, which
  closes both halves at once — a current host clones whole again), owner
  (the one clause in the engineer charter), pm (route, and carry the
  corrected number).
- [ ] **Message pass, 2026-10-24 ~06:4xZ: #266 (the stale npm-install-line
  doc fix) confirmed on main; the real blocker it fixed text about — the
  publish itself — still has not run, and two orphaned drafts named in
  this dispatch got the merge-or-close call the evidence actually
  supports, not the one the dispatch assumed.** Triggered by #266
  merging. Re-checked the standing risk first: `registry.npmjs.org/
  epito-cli` still answers 404 at this pass (~06:49Z), `NPM_TOKEN` dies
  **2026-10-24T19:26:26Z**, about 12.6h out — unchanged from the last
  pass's figure, still seat: chair or owner, not re-asked a second time
  this pass since nothing about it moved.
  Then the two drafts the dispatch named, **#262** (market) and **#264**
  (exo), both idle since ~02:0xZ. The dispatch described
  `tools/check-draft-prs.sh --repo alexandrapaiz/epitome` as if it were
  vendored here — it is not (checked `git log --all` on the path, no
  history, no file in this tree) — so this pass ran the real tool from
  its actual location (`/srv/asc/hq/tools/check-draft-prs.sh`) against
  this repo rather than trust the dispatch's description of what it
  would say. Both came back `finish` (idle 4-5h, substance `work`), not
  `ready`: a draft a seat marks "will be readied before the run's last
  turn" and never does is mid-work by the tool's own disposition rule,
  not a merge candidate, so Tier B condition 2 (not a draft) is the
  clause withholding both and merging either on sight would have been
  the tool's own warned-against case — shipping half a change.
  Read both bodies and diffs directly rather than stopping at the
  verdict: **#262**'s report ("## What this run took" / "## Three most
  important changes," docs/market.md only, no self-declared in-progress
  marker, an explicit note on what it deliberately did *not* redo and
  why) reads as a finished rev9, two headings short of the tool's
  three-heading floor and nothing else against it — `git merge-tree`
  against `origin/main` resolves clean. Readied and merged under Tier B
  (not this seat's own PR, no Tier C path, clean, same-day). The
  heading-count floor undercounting a genuinely finished report by one
  heading is worth a tuning note to whoever maintains the tool
  (exo-centralizer/HQ, since it is not vendored into this repo for this
  seat to patch itself) — flagged here, not fixed here.
  **#264** is the opposite case and the tool reads it exactly right: its
  own body says "Draft while the run works... More to follow in this
  branch," an explicit in-progress marker, and `git merge-tree` against
  `origin/main` finds a real add/add conflict in `docs/agents/
  addressed.sh` (the file #259 already carried to main and #260 also
  touches) — a code conflict, not a docs-only one, so Tier B condition 5
  sends it back to the owning seat rather than this one resolving it.
  Declined; commented on #264 naming both clauses. Seat: epitome-exo —
  finish the run (commit the rest, `gh pr ready`) or close it and say
  what it owed; the conflict in `addressed.sh` either way.
  The five other open drafts this pass surveyed (#253, #255, #258, #260,
  #261) each carry a `prompts/` path in `gh pr diff --name-only`, which
  keeps every one Tier C regardless of content — unchanged since the
  last pass, still the owner's, not re-asked a second time tonight.
  Linear mirror: skipped, `LINEAR_API_KEY` absent (probed this run).
  Seat: pm (triage, one Tier B merge, one decline with the clause
  named), epitome-exo (#264), chair or owner (the publish, the five
  Tier C drafts).

- [ ] **Message pass, 2026-10-24 ~00:5xZ: the epito-cli rename merged,
  the publish still has not run, and the token's clock is now the
  whole ask.** Triggered by the exo seat's board message pointing at
  its own report (#253: incidents re-measured, a charter patch to
  `prompts/engineer-agent.md` offered for the owner's merge). Reading
  it turned up two of this product's own drafts with no live run
  behind them — `tools/check-draft-prs.sh --repo alexandrapaiz/epitome`
  read both as `ready` (idle 5-6h, substantive reports) — so this seat
  readied and merged both under Tier B (docs/standards/pm.md §21):
  **#246** (the `epito-cli` rename, the `name-check` probe tool, the
  publish runbook) and **#242** (the host env loader's `$`-prefixed
  value, unrelated to this bet). The only conflict, additive rows in
  `docs/ideas.md` once #246 landed first, was docs-only and resolved
  in the merge commit. `cli/package.json` reads `"epito-cli"` on `main`
  now; the binary name `epito` is unchanged. #253 itself: declined,
  Tier C (`prompts/` is the owner's regardless of what the patch does,
  per §21's own text) — it waits on her word, not on 48 hours of
  silence. Cycle-2's file (docs/cycles/2026-10-18-cycle-2.md) has the
  hill update. **What is left is not engineering**: run the real
  `npm publish` from `cli/` under the name now in the tree, with
  `NPM_TOKEN` already in Infisical and this repo's Actions secrets —
  before it dies **2026-10-24T19:26:26Z**, about 18.5h from this pass.
  Seat: chair or owner (the live publish, a secrets/account action this
  charter does not execute); pm (recorded here, will re-check next run
  whether the card is still open).

- [ ] **Message pass, 2026-10-23 ~18:3x UTC, corrected ~18:5xZ: the
  licence word this pass flagged as tonight's npm blocker was never the
  real one — the engineer ran the actual publish and npm refused the
  package name instead, and this seat has now decided it.** Inbox,
  first read: a `handoff` from `alexandra-systems/chair:hq-console`
  saying the host was dark 2026-10-18→2026-10-23 so the real
  `npm publish` never ran and `NPM_TOKEN` dies 2026-10-24. This pass's
  own first answer raised `cli/package.json`'s `"license": "UNLICENSED"`
  to the owner as an urgent ask — wrong in kind: npm's name check runs
  before it ever validates the body a licence field lives in, so that
  field was never tested. Second read, a `handoff` from
  `epitome/engineer` (18:50Z, ref `#246`): the real publish returned
  `403 Package name too similar to existing packages exit,pino`.
  Unscoped `epito` is refused permanently (two edits from `exit` and
  `pino`, does not clear with time); `epitome` is already published by
  someone else, which also rules out `epito.me` and `epito-me`.
  Accepted by probe, nothing published: `epito-cli`, `epitome-cli`,
  `epito-agents`, `epito-mint`, `@alexandrapaiz/epito`. The engineer
  handed the name call to this seat rather than re-filing it owner-only
  (`"That call is yours"`) and separately asked the owner the same
  question, non-urgent. Per standards/pm.md §22 a package name is not
  money, accounts, secrets, or this seat's own authority, and the
  token's real deadline — `2026-10-24T19:26:26Z`, ~24.5h from this pass
  — is shorter than the 48-hour silence default anyway, so this seat
  decided rather than let the scope sit un-owned: **`epito-cli`**,
  the engineer's own recommendation, needing no browser action and
  keeping the `epito` binary name unchanged. The owner can still
  overrule it before the rename merges. The licence question
  (docs/ideas.md, 2026-10-18) stands as her call, unreassigned, but is
  not blocking tonight's clock and does not get a second urgent ping
  over a correction. Replied on the board, first person, to both
  handoffs; updated cycle-2's standing risk and 2-1 hill with the
  corrected picture. Next: engineer adds the three-line rename to
  `#246` and clears draft; this seat merges it on sight (§21); then the
  chair or owner runs the publish with the token that exists. Linear
  mirror: skipped, `LINEAR_API_KEY` absent (probed this run). Seat: pm
  (decided, corrected), engineer (`#246`'s rename), chair or owner
  (holding the token to run the publish).
- [ ] **Loosen the manifest validator's unknown-key refusal for `[agent]`
  and `[trigger]`, or add the two fields alexandra-systems' roster
  needs.** (engineer) `alexandra-systems/engineer` asked on the board
  2026-10-23: `epito validate` refuses their whole roster over two keys
  it does not recognize — a seat on/off switch and a host-timer-path
  field, both load-bearing in their own standard. Their own fallback,
  which I'm endorsing as the direction rather than templating the field
  names myself: treat an unrecognized key in those two tables as a
  warning, not a refusal, until the names are settled. Field naming
  stays the engineer's call, proposed in the same PR as the code that
  reads it, per `spec/manifest.md`'s own frozen-fields process (open
  question, then spec, then code, never two at once). They are not
  blocked meanwhile — they read their own manifests with their own
  checks — so no date on this one.

- [ ] **Message pass, 2026-10-18 ~09:4x UTC: HQ engineer's dogfood ask
  on the resident runtime answered, two of its three claims checked
  and one corrected, cycle 2's file opened for real closing two
  duplicate drafts of itself.** Inbox: an `ask` from
  `alexandra-systems/engineer` reported our product's hand-patched
  runtime copy on the resident host carries a fix `main` lacks — a
  guard against writing to an already-closed log descriptor, which
  took their whole daemon down one night — and, in passing, claimed
  `main` also lacks per-seat tracing attributes and the board run
  report. Checked all three against `cli/src/lib/runner.js` and
  `trace.js` myself rather than taking the ask at face value: the
  closed-descriptor claim is real and unfixed, filed as a new
  `docs/ideas.md` entry and handed to `engineer`/`epitome` (this
  charter never writes product code); the tracing claim is wrong —
  `childTraceEnv` is wired into `runner.js` already — and I said so on
  the board; the run-report claim is already tracked, this ledger's
  own proposed idea on `POST $BOARD_API_URL/api/runs`, nothing new to
  file. Replied to the asking seat in first person with all three.
  Separately, found this seat had opened `docs/cycles/
  2026-10-18-cycle-2.md` twice already today (#159, #178), neither run
  aware of the other, and #159's hill chart was stale against the
  #130/#131/#135/#136 chain that merged to `main` at 08:42 UTC after
  #159 was written. Closed both with a comment naming this PR as the
  one that lands, and opened the file fresh off current `main`. Asked
  `pm`/`alexandra-systems` to merge this PR under the established
  route, since a PM's own Tier B PR is not this seat's to merge.
  Linear mirror: skipped, `LINEAR_API_KEY` absent from the environment
  (probed this run).
- [ ] **Message pass, 2026-10-18 09:29 UTC: the same engineer run and
  the same pull request (#175) this pass was dispatched to review had
  already been merged under the merge rule by the pass immediately
  before it (#182) — closed that loop rather than redoing it, and
  caught one inaccurate claim on the way.** The event naming "the
  engineer seat's run finished" and "PR #175 opened" pointed at work
  this seat had already done: `gh pr view 175` showed `MERGED` at
  09:22:43 UTC, and the board's own inbox carried #182's `done` message
  recording the merge commit and the reason. Re-verified rather than
  trusted — `gh pr diff --name-only`, `mergeStateStatus`, the pasted
  suite evidence — and found nothing left to redo. #182 itself was
  still sitting open as a draft (docs/backlog.md only, a knowledge
  surface), so this pass marked it ready and merged it
  (`613d3ba`), which is the actual queue-moving act this pass
  performed. #182's own PR body claimed "`docs/backlog.md` records the
  decision" about where a board-report's `company` field comes from
  (`company.yaml`'s own `product` field) — checked that claim against
  the merged diff and it is not true of #182; the decision text lives
  in PR #178 (still open, still draft, bundled with opening cycle 2,
  held for the owner's bet-ratification, not merged). Filing the
  correction here rather than letting a false "already recorded" claim
  stand uncorrected. Because the `company.yaml`-product-field decision
  does not touch the frozen manifest spec (it is a roster-level choice,
  not a new `agent.toml` key), it does not need to wait on #178's
  cycle-2 ratification to take effect — handed to `engineer`/`epitome`
  on the board as its own handoff, independent of #178, so the
  board-report-card build (`docs/ideas.md`, "Low to build, one spec
  decision first") is unblocked now rather than waiting on an unrelated
  bet. Linear mirror: skipped, `LINEAR_API_KEY` absent from the
  environment (probed this run).
- [ ] **Message pass, 2026-10-18 09:25 UTC: the engineer's recomposed
  draft merged on a fully green suite; the exo incident patch needed
  no second look.** Inbox, read fresh: the exo patch logging the
  shared-`/tmp` incident and lesson L15 (PR #177) was already merged
  and answered by the pass before this one, so checking it against the
  merge rule myself turned up nothing left to do — its diff was three
  knowledge-surface paths, clean, and correctly closed. The one new
  item was the engineer's correction to its own earlier board note:
  PR #171 had landed on `main` mid-run, so it merged `main` into its
  draft, resolved two trivial conflicts (an import line two branches
  had both touched, two append-only rows in `docs/ideas.md`), and
  reran the whole suite rather than leaving a stale report for this
  seat to act on. Checked that claim rather than taking it on trust:
  `gh pr diff --name-only` showed only `cli/` files and
  `docs/ideas.md`, no workflow, no secret, no charter; `mergeStateStatus`
  was `CLEAN`; no checks are defined on the branch, and the suite
  evidence pasted into the PR body showed both reds it had warned
  about gone (the docker-less skip now an honest partial, the
  shared-host clone-glob assertion not tripping this run). That clears
  the merge rule, so it was marked ready and merged with a normal merge
  commit. Replied to the correction on the board in first person with
  the reason. Nothing failed this pass that needed a triage line.
  Linear mirror: skipped, `LINEAR_API_KEY` absent from the environment
  (probed this run).
- [ ] **Message pass, 2026-10-18 00:22 UTC: `NPM_TOKEN` has landed, so
  the cycle-2 MVP is down to two waits instead of three, and the
  Cloudflare spike the owner asked for directly got handed to the
  engineer.** Inbox: one handoff since the last pass's 18:27 UTC note
  carried real news — the chair reports the owner created the npm
  account `alexandrapaiz` and the publish token is now in Infisical
  and this repository's Actions secrets as `NPM_TOKEN`, capped at
  seven days and dead 2026-10-24. The merge-chain handoff that
  preceded it (#130/#131/#135/#136) was already answered last pass
  (#139): still unmerged, still clean, still not this charter's to
  merge. Failed runs: none in the last six hours (`gh run list
  --status failure` since 2026-10-17 18:23 UTC is empty); the one
  real failure in the last 24h (14:25 UTC, turn-cap) was triaged two
  passes ago and needs no second look. Tier B queue walked fresh,
  nothing merged: same gap as every pass since the charter trim —
  this seat's current charter names no merge authority, so the chain,
  #132, and #67 are left exactly where the last several passes left
  them. What waits on her hand, one line each:
  - **One GitHub App approval in her browser**, once, for an HQ seat —
    proves the deploy mechanism end to end. Asked 2026-10-16 18:28
    UTC, no reply yet, still open.
  - **PR #67, the cycle-2 betting memo** — her merge places the bet;
    absent that it proceeds on 48 hours of silence from its last push
    (2026-10-16 14:40 UTC), which clears 2026-10-18 14:40 UTC, later
    today and not yet.
  - **Merging #130→#131→#135→#136 and then actually running `npm
    publish`** — both wait on the chair (merge rights under section
    21) or the owner; neither is product code or a merge this seat's
    charter lets it execute, and the seven-day token clock makes this
    the one that is actually urgent now.
  A separate, unrelated ask landed on the board too: the owner wants a
  Cloudflare deploy prototype by Wednesday's brief (2026-10-21). That
  is build work, not cycle machinery, so it was hung off a board
  handoff to the engineer rather than folded into this charter's
  pitches or cycles. Seat: pm (triage, report, route), chair/owner
  (the merge and the publish), engineer (the Cloudflare prototype).
- [ ] **Six-hour pass, 2026-10-17 18:23 UTC: nothing moved since the
  last pass closed three and a half hours ago, so this entry names
  that rather than repeating it.** Inbox: nothing addressed to
  `pm`/`epitome` since the 15:00 UTC ask about PR #137, which
  `alexandra-systems/pm` has since merged (confirmed on GitHub,
  `mergedAt` 18:22:26 UTC, though no `done` message has posted for it
  yet). Failed runs: none since the one at 14:25 UTC already triaged
  below — no new runs to classify. Tier B queue walked fresh,
  nothing new to merge: #136/#135/#131 are one complete draft stack
  (the engineer's own, per #136's body), #132 and #130 are other
  seats' own drafts still in progress, and #67 is this seat's own
  pull request (the cycle-2 bet), which the own-PR rule and the bet
  mechanism both send to her hand, not mine. What still waits on her,
  unchanged and not re-asked this pass because nothing about any of
  the three has changed since yesterday:
  - **`NPM_TOKEN` in Infisical** (or her word that it exists) — blocks
    the only thing left between a built CLI and a stranger installing
    it from npm. Asked 2026-10-16 18:28 UTC; no reply yet.
  - **One GitHub App approval in her browser**, once, for an HQ seat —
    proves the deploy mechanism end to end against a live account.
    Same ask, same timestamp, no reply yet.
  - **PR #67, the cycle-2 betting memo** — her merge places the bet;
    absent that, it proceeds on 48 hours of silence from when it was
    rewritten (2026-10-16 ~18:28 UTC), which has not elapsed as of
    this pass and clears sometime tomorrow afternoon, not today. Seat:
    pm (triage and report), owner (the three waits above).
- [ ] **Engineer's turn-cap exhaustion today is a cap finding, not a
  defect — handed to HQ.** The scheduled `agent-engineer` run at
  2026-10-17 14:25 UTC
  (https://github.com/alexandrapaiz/epitome/actions/runs/39040671379)
  ended `error_max_turns` at 151 turns against the workflow's cap of
  150, but it had already pushed and opened PR #136 complete: clean
  `git status`, 148 new assertions (the npm publish gate and package-page
  checks), every break-then-revert transcript included, nothing left
  uncommitted. Per standards/lessons.md L-X3 (amended 2026-10-12), an
  `error_max_turns` exit is a finding about the cap, not about the run,
  so this triages as no rerun — the work already shipped and a rerun
  would just spend another ~$12 to risk the same cap again on cleanup
  turns. Checked whether this is the "repeated exhaustion inside one
  week" defect L-X3 also names: the five failures 2026-10-12 through
  2026-10-16 on this same workflow were the now-resolved dead-runner
  billing wall, each dying in 2-3 seconds before the agent ever started
  — not a turn exhaustion — so this is the seat's first cap exhaustion
  this week and the plain step-up applies. `.github/workflows/` is
  HQ's surface, not a product seat's, so the fix (raise
  `agent-engineer.yml`'s `--max-turns` from 150 to 225, half again,
  per L-X3's defined step-up) is handed to
  `alexandra-systems/exo-centralizer` rather than edited here. Seat:
  pm (triage), exo-centralizer (fix).
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
- [ ] **A refusal is only proved by a command that performs the act, and
  the publish gate was the one place this product rehearsed instead.**
  From the engineer run of 2026-10-26 (ref the publish-preflight branch),
  measured, not argued. Second instance of one fault in nine days, both
  on `npm publish --dry-run`: the first leaked `npm_config_dry_run` into
  the gate's nested commands so both suites skipped themselves and the
  gate passed with zero assertions made; the second is that the dry run
  cannot reach a `private` refusal at all — npm throws it as the first
  statement of `libnpmpublish`'s publish function and calls that function
  behind `if (!dryRun)`, so the rehearsal prints `+ epito-cli@0.1.0` and
  exits 0 with the guard fully in place, the same output it prints with
  the guard removed. Read on npm 10.9.8 on this box
  (`libnpmpublish/lib/publish.js:15`, `lib/commands/publish.js:161`; the
  in-command copy at `:136` is guarded by `workspace &&` and publishing
  `cli/` is not a workspace publish).
  **Both instances are fixed and the general case is already the house
  pattern everywhere else**, which is what makes this a card and not a
  warning. Every other third party this product checks against is stubbed
  and the act performed — `github-stub.mjs`, `cloudflare-stub.mjs`,
  `git-http-stub.mjs`, `otlp-sink.mjs`, and now `registry-sink.mjs` for
  the registry. And `epito`'s own four `--dry-run` paths (`token`,
  `deploy`, `deploy --target cloudflare`, `run`) are all written the right
  way around: validation and `permissionsFor` run *before* the branch and
  each one names the refusal the real path would give, so our own commands
  do not carry the fault. Checked this run, all four.
  What is left is not a fix, it is a rule nobody wrote down: **a gate may
  not accept a third-party tool's rehearsal flag as evidence about a
  refusal that tool enforces.** The publish gate was the only one that
  did, and it was the gate whose act is the one irreversible act this
  product takes. Worth a line in the engineering standard, and the
  question of where is the PM's. Seat: pm (route and place the rule),
  then engineer if it wants an assertion anywhere else.

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

- [ ] ~~Register **epito.me** (verified available 2026-09-18; a few
  dollars)~~ — **wrong on both clauses, struck 2026-10-18.** HQ's MBA
  seat ran `whois epito.me` this run and found it registered since
  2025-10-11 (Dynadot), nameservers pointed at Atom, resolving
  `https://epito.me/` to a domain-sale listing — it was never
  available and was already a year old the day this card said
  "verified available." The fallback already in hand: the name a
  stranger actually types is `epito` (the binary and the npm package),
  and `https://registry.npmjs.org/epito` returns 404 — that name is
  free. The question this card should have asked instead: does the
  `.me` domain matter enough to pay a brokered price for a pre-revenue
  product, or is `epito` the product's name and `epito.me` just a line
  in a press release nobody outside the company has read. Asked on the
  board as a real decision (not re-filed as a repo-secret card, since
  it is a purchase and the account are hers alone either way).
  **The fallback named above is also gone, found 2026-10-23.** "The
  name a stranger actually types is `epito` … that name is free" was
  true of `GET /epito` and false of publishing it: the real
  `npm publish` came back 403, *Package name too similar to existing
  packages exit,pino*. npm's typosquat filter will not issue the name,
  and a 404 on the registry only ever meant nobody holds it. So the
  product has neither `epito.me` the domain nor `epito` the package,
  and the name decision below is the live one.
- [x] **One word: the name `epito` ships to npm under.** Opened
  2026-10-23 by the engineer seat, after the real publish was refused.
  **Answered the same evening, 19:01Z — and not by the owner.** The PM
  decided it under its own authority (`epito-cli`, board message
  `45bd82be`): a package name is not money, not an account, not a
  secret and not a widening of the PM's authority, so pm.md §22 never
  reserved it for her, and the token's clock (19:26Z on the 24th) is
  shorter than the 48-hour silence rule it would otherwise have waited
  out. **She can still overrule it in one word until the rename
  merges**, which is the only reason this card is answered rather than
  struck. What is left in this section is not the name: it is whoever
  holds `NPM_TOKEN` running the publish. The record of why, below, is
  kept as it was written.
  Nothing is missing from the host or from Infisical — `NPM_TOKEN` is
  there by that name, it authenticates as `alexandrapaiz`, it carries
  package-write on all packages, and it dies **2026-10-24T19:26:26Z**
  (19:26 UTC, not midnight). A replacement token would not help: the
  blocker is the name, and the filter does not clear with time.
  Unscoped `epito` is permanently refused (too similar to `exit`,
  `pino`); `epitome` is published already by someone else; `epito.me`
  and `epito-me` both collapse onto `epitome` and are refused too.
  Accepted, verified by probe that publishes nothing (`npm run
  name-check -- <candidate>`): **`epito-cli`**, `epitome-cli`,
  `epito-agents`, `epito-mint`, `@alexandrapaiz/epito`, and any
  `@<org>/epito` once an org exists. The engineer's recommendation is
  `epito-cli` — it needs nothing from her browser, and the word a
  stranger types twenty times a day is `epito` (the binary, unchanged)
  rather than the install line they type once. A company scope
  (`@epitome/epito`) is the alternative and costs one browser action to
  create the npm org, the same shape as scope 2-2's deploy click.
  Everything else is ready: the rename is committed on `#246` — five
  lines, not the three measured first, because the earlier measurement
  reverted without an `npm install` and so never saw
  `package-lock.json`'s two copies of the name — green on both gates
  under the new name (`pack` 119/0, `stranger` 33/0, including inside
  `npm publish --dry-run`), and `docs/deploy/npm-publish.md` holds the
  exact command sequence from step 2 on.
- [ ] **Make the repo public before the passport ships** (owner ruling R3, 2026-09-20). Timing: at the passport's first publish. Prereq: security seat audits history for anything personal; the manifest rule (nothing personal in files) has held since founding, verify it.
- [ ] **LINEAR_API_KEY repo secret** (personal API key from Linear
  settings) + name the Linear team/workspace the PM mirrors to (ADR-5).
  Optional until the PM's first run; the seat skips the mirror cleanly
  without it. *Still absent as of 2026-10-06 — this run skipped the
  mirror per charter.*
- [x] `claude setup-token` → CLAUDE_CODE_OAUTH_TOKEN repo secret, when
  ready to stand up seats. Present and working: pm/okr/exo/market/engineer
  all run on schedule (5 workflows in .github/workflows/).
- [x] Decide public vs. private repo before any seats run on schedule
  (public = unlimited Actions minutes, per the playbook). Decided
  2026-10-16: the owner made this repository public (chair's history
  scan found no secret bodies first), and the runner that had been
  dead since the 13th ran successfully again the same afternoon
  (engineer-agent, 15:32 UTC) — the billing wall named in every prior
  pass's failed-run triage is gone.
- [x] **Cycle 1 closed, 2026-10-16.** PR #54 (the retro + trial
  scorecard) had waited 11 days past the 48 hours section 22's silence
  rule allows, clean and mergeable the whole time; merged under that
  rule today with the PM's own recommendation, since both bets'
  evidence (merged commits) already showed them shipped inside
  appetite. The ADR-5 trial review itself is still the owner's to
  grade; this entry tracks the merge, not the grade.
- [x] **Bet cycle 2 — placed.** PR #67 merged 2026-10-18T02:12:53Z,
  betting mvp-stranger-npm-v0 per the owner's direct MVP override.
  `docs/cycles/2026-10-18-cycle-2.md` opened this pass, superseding two
  earlier drafts of itself (#159, #178 — see the message-pass entry
  above) that opened it independently within the same hour without
  seeing each other. Three of the bet's four scopes are merged to
  `main` (08:42 UTC, the #130/#131/#135/#136 chain); what is left is
  not engineering — the real `npm publish` and one human GitHub App
  click, both named in the cycle file with the publish token's
  2026-10-24 expiry as the standing risk.
- [x] **The deck-archiving PR, closed.** PR #52 sat conflicting against
  main for twelve days with zero commits or comments since it opened
  2026-10-05, and it also touches `.github/workflows/`, a surface
  product seats hand to the centralizer rather than editing — two
  passes flagged the rebase it needed and neither moved it, which is
  the idle-and-undecided state section 10's own closing rule exists
  for. Closed 2026-10-17 with a comment naming what reopens it: a
  fresh branch off current main, with the workflow-file change split
  out to a handoff for the centralizer instead of carried in the same
  diff. Seat: chair, closed by pm.
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
  reports — resolved again.** #119 (one pass's report) closed itself,
  superseded, before ever being merged by anyone, and its successor
  #120 sat open for six hours on the same gap: a docs-only PR
  (`docs/backlog.md` alone) this seat wrote about itself, so Tier A's
  self-merge list doesn't cover it and Tier B's own-PR rule sends it to
  another merger. Both #120 and its own successor #121 merged
  2026-10-15 12:23 UTC, within six hours of the renewed ask, same
  account that cleared the gap in its first occurrence (#92). The route
  keeps working each time it's asked; nothing here needs a standing
  fix. Seat: pm, closed 2026-10-16.
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
