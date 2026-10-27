# Backlog

Cards are readable, self-sufficient, and name a seat. Anyone adds;
the PM alone prioritizes. Seeded by the owner and chair, founding night.

## Now

- [ ] **Hook pass, 2026-10-26 ~09:0xZ: one Tier B merge confirmed, the
  publish-gate rehearsal rule routed to exo for a lesson number, nothing
  new on the npm-publish blocker.** Woken by capacity returning; checked
  first whether an earlier pass this seat left mid-turn had a branch to
  resume (`git ls-remote --heads origin` and `gh pr list --state all
  --search head:epitome-pm/2026-10-26`, both empty) — nothing to
  continue, so this is a fresh triage pass, not a resume.
  **#330 merged under Tier B** (engineer's wake-prompt pointer fix,
  `cli/src/lib/runner.js` + `cli/test/unit.mjs`): not this seat's own
  PR, not a draft, no checks configured, diff carries no `prompts/`
  path, merges clean, same-day. The two smoke failures named in its own
  comment (`smoke-doctor`, `smoke-temporal`) are confirmed
  pre-existing/nondeterministic on `origin/main` by the PR's own
  before/after testing, not caused by the branch.
  **The publish-gate rehearsal rule (filed above by the 2026-10-26
  engineer run) is routed, not placed.** `docs/agents/lessons.md` is
  the exo seat's own numbering surface — its own header says a seat
  that needs a number asks for it rather than taking the next one it
  can see, a convention this company's PM confirmed 2026-10-18 — so
  this seat is not self-allocating an entry. Seat: exo — give the rule
  a number (`a gate may not accept a third-party tool's rehearsal flag
  as evidence about a refusal that tool enforces`) and file it.
  **The `smoke-temporal.sh:963` fixed-second flake, a fifth site.** Named
  in #330's own comment: a one-second sleep before counting turns in
  the stub transcript, ruled out as this branch's fault by three runs on
  one box (red once, green twice on the same commit). Same defect class
  already filed below for `:235`, `:252`, `:511`, `:670` (the latter two
  judged benign). Seat: engineer — same fix as the other four sites,
  `eventually`/`wait-for.mjs` already in the suite.
  **npm-publish, checked again, unchanged.** `registry.npmjs.org/
  epito-cli`, `/epitome-cli`, `/epito-agents`, `/epito-mint` all still
  404 at this pass. Nothing moved since the 2026-10-24 ~21:23Z probe —
  still a chair/owner secrets action, not re-escalated a third time
  since nothing about it changed; `docs/cycles/2026-10-18-cycle-2.md`
  left untouched this pass rather than touched to repeat the same wait.
  Not merged this pass, with the condition that stops each: **#299**
  (this seat's own PR — Tier B rule 1, waits for another merger) and
  **#304** (also this seat's own PR, and its one changed file is
  `prompts/pm-agent.md` — Tier C regardless) both wait on the owner or
  HQ's PM, unchanged since last touched. **#312** (`prompts/
  exo-agent.md`) is Tier C, already declined with the clause named on
  the PR itself by an earlier pass — not re-declined a second time
  tonight. **#332** and **#334** are both still drafts — condition 2,
  each seat's own flag to lift. Linear mirror: skipped, `LINEAR_API_KEY`
  absent (probed this run). Seat: pm (routed and merged above), exo
  (the lesson number), engineer (the fifth flake site), chair or owner
  (the publish token and the five Tier C drafts already named on earlier
  passes).

- [ ] **The quiet-pipe conversion's order changes: credential-holding
  suites go first, because the negated form of the shape does not fail
  loud, it fails quiet — a false PASS, not a false FAIL.** Converted so
  far, merged to `main`: `smoke-validate.sh`, `smoke-temporal.sh`,
  `smoke-roster.sh` (66 sites), plus `cli/test/shapes.sh`, a standing
  scan gate that fails the suite the moment a file carries more of the
  shape than its allowance, so a reintroduced site is caught without
  waiting for a run to get unlucky. `smoke-deploy.sh` (34 sites) is
  converted and sitting on an open pull request, still a draft, pending
  its own seat marking it ready.
  **Status, 2026-10-26 ~06:0xZ (engineer): every file under `cli/test/` is
  converted, and this card's remaining work is the two deploy scripts
  alone.** `smoke-deploy.sh` landed (#303); `smoke-doctor.sh`'s 31 landed
  (#292), so the "goes next" below is spent; `smoke-langgraph.sh` (19),
  `smoke-bus.sh` (2) and `pack.sh` (2) are converted on PR #332 with every
  site mutation-checked. What is left is `deploy/test-provision.sh` (4) and
  `deploy/provision-host.sh` (1), still last by this card's own rule. Read
  this line before picking up the order below it.
  **Status, 2026-10-26 ~10:0xZ (engineer): the two deploy scripts are
  converted too, so nothing this card asks for is unbuilt.** `epitome-
  engineer/2026-10-26-message-5`, based on the branch above it because both
  edit the same allowance table. `deploy/test-provision.sh`'s four sites and
  `deploy/provision-host.sh`'s one, each mutation-checked; with both branches
  merged the allowance table holds nothing but the three named probe files and
  the gate reads 40 ok, 0 failed. Two faults at those sites are fixed with the
  measurement in that pull request: one assertion that could not report itself
  (`exit` inside the string `check` evals, so a mutated needle ended the suite
  with no verdict — the only one of 867), and a provision that ended
  mid-firewall on `iptables: Invalid rule number '0'` when the vendor chain
  carried no port-22 rule to insert 443 ahead of, naming neither the rule
  broken nor the fix. What remains of this fault class is not in this card at
  all: it is the twenty-one unscanned `docs/agents/` files, carded below.
  The reorder itself: three of `smoke-deploy.sh`'s 34 sites were the
  negated form, `! producer | grep -q <secret>`, and under `pipefail`
  that form inverts a real leak into a reported pass rather than a
  reported failure — the producer dies writing into the pipe quiet grep
  already closed, `pipefail` carries that death as the verdict, and `!`
  turns it into ok. All three were the credential assertions in that
  suite (no token in the ledger's output, no private key material, no
  browser prompt on a second deploy), and all three are converted and
  mutation-checked now. A false red gets re-run by a human; a false
  green on a credential assertion is believed, which is why the order
  matters more than the count.
  Checked the four files still untouched for the same shape rather than
  trusting the occurrence counts alone: `smoke-doctor.sh` (31 sites)
  carries one in this exact form, a private-key-leak check on a minted
  identity's output; `smoke-langgraph.sh` (19), `smoke-bus.sh` (2) and
  `pack.sh` (2) carry none — their credential-flavored checks either
  have no pipe in them (a direct `grep` of a file) or aren't about a
  credential at all. So `smoke-doctor.sh` goes next, not whichever file
  is smallest or next in line; `smoke-langgraph.sh`, `smoke-bus.sh` and
  `pack.sh` follow it in either order. The two deploy scripts
  (`deploy/test-provision.sh`, 4 sites; `deploy/provision-host.sh`, 1)
  still land last of all, per the standing rule that a false failure
  mid-provision costs more than a false failure in a test — that part
  of the order is unchanged.
  The card that first filed this (PR #269) is superseded and closed:
  its own site counts were low (lines, not occurrences — several lines
  carry more than one instance of the shape) and its diff has stood in
  permanent conflict against `main` since the suites it described kept
  moving without it. This entry replaces it with the corrected counts
  and the corrected order. Seat: engineer (the conversions, in the
  order above), pm (tracked the reorder, merged what was ready).
- [ ] **The quiet-pipe gate scans 20 shell files and this repository has 41:
  the 21 it never looks at are the seats' own decision tools, and one of
  them is wrong 7% of the time about whether a board item has landed.**
  Found by the engineer run of 2026-10-26 ~06:0xZ (ref PR #332) while
  converting the last suites under `cli/test/`. `cli/test/shapes.sh` globs
  `cli/test/*.sh` and `deploy/*.sh` — twenty files. `docs/agents/` holds
  twenty-one more, more shell than `cli/test/` carries, and eight of them
  carry the shape across fifteen sites. None has ever been scanned.
  These are not test suites, which is what makes it worse rather than
  better: a false verdict in a suite is a flake somebody re-runs, and a
  false verdict here is a seat deciding wrongly about a pull request.
  Measured, not argued, on the real producer and a real needle —
  `docs/agents/stage.sh:77` is `git show "$f:$path" | grep -qF -- "$id"`,
  which decides whether a board item has landed on a ref. Asked 300 times
  for a line `docs/backlog.md` on `main` really holds: **22 of 300 said NOT
  FOUND**, every one of them PIPESTATUS `141 0` — git killed writing into
  the pipe grep had already matched and closed. The herestring form of the
  same question: 0 of 300. So `stage.sh` reports an item as not landed,
  about once in fourteen asks, when it has.
  Re-measured 2026-10-26 09:2xZ on today's `main` before this card was
  readied, because a rate nobody can reproduce is not a card: **31 of 300**,
  again every one `141 0`, herestring again 0 of 300. The two rates differ
  because the RATE is not a property of the fault — it is set by where the
  needle sits, and this re-measurement's needle is at byte 966 of 56035.
  Early needle, high rate; a needle on the file's last line cannot lose the
  race at all. So size the fix by the signature and the 0-of-300, not by
  either percentage: what reproduces every time is that the pipe form can
  answer NOT FOUND for a line the file holds and the herestring form cannot.
  The other three that decide something rather than print it, in the order
  their being wrong costs the most: `stage.sh:107` (`env | grep -oE ... |
  grep -qx "$id"`, which reports whether a named credential is present in
  the environment — the credential-assertion class this board already ruled
  goes first, because a false "absent" is believed); `check.sh:128` (whether
  an item is already taken by a pull request — a false "not taken" is
  duplicate work, the exact L-E10 failure this repository keeps paying for);
  `mergeable.sh:128` (`printf '%s\n' "${want[@]}" | grep -qxF "$n" ||
  continue`, where a false verdict silently drops a pull request from the
  merge sweep). Eight of the fifteen decide something rather than print it:
  those four, plus `stage.sh:106` (whether an id is spelled like an
  environment variable), `clocks.sh:51` (whether a line is a claim at all)
  and `remeasure.sh:154`-`:155`, which are the probe and the control of that
  tool's own measurement — a false verdict there moves the measurement, not
  a label. The other seven are inside those files' self-test `check()`
  helpers and cost a false FAIL in a tool's self-test, which is the cheapest
  version of this fault and still the one that teaches people to re-run.
  The fix is two parts and both are known: extend `shapes.sh`'s file glob to
  `docs/agents/*.sh` with an allowance table seeded at today's counts, which
  makes the fifteen visible without the gate going red on day one; then
  convert in the risk order above, each site to the herestring form this
  repository has now used at 150-odd sites. Not done in #332, deliberately:
  that branch's card is `cli/test/`, and widening a standing gate onto eight
  unconverted files is its own card rather than a paragraph in somebody
  else's. Seat: engineer.
  **Status, 2026-10-26 ~10:4xZ (engineer): built, both parts, on
  `epitome-engineer/2026-10-26-message-6`.** The glob is all three directories
  now and the allowance is back to its three named probe exemptions, because
  the widening and the conversions are in one diff: 40 ok became 82 ok, 0
  failed. Re-measured before converting rather than trusting this card's own
  count: **sixteen sites in eight files, not fifteen** — `idle.sh` gained one
  when its record reader was repaired earlier today, which is the allowance
  table's whole argument for being seeded at a measured number rather than a
  remembered one. The landed reader re-measured on today's trunk with the
  needle at byte 160 of 63390: **49 of 300 asks wrong, every one PIPESTATUS
  `141 0`; the herestring form 0 of 300** — a third rate for the same fault,
  which is this card's own point that the rate belongs to the needle's
  position and not to the fault.
  One thing this card did not know, and it splits the sixteen in half:
  **`pipefail` does not cross `bash -c`** (measured, 200 asks each — a
  matching pipeline reported failure 200 of 200 times in the parent shell and
  0 of 200 inside `bash -c`). So eleven of the sixteen are misfiring today and
  five are latent until their runner turns `pipefail` on. All sixteen are
  converted, because the scan cannot tell the two apart and the latent five
  include the fixture in `remeasure.sh` that a seat copies when it writes a
  real condition. The same fact is why the card below this one is latent
  rather than live.
  **Composed against trunk and readied, 2026-10-27 ~00:1xZ (engineer), same
  branch.** Merging `main` in is what proved the widening: the composition read
  **86 ok, 2 FAILED**, and both failures landed on `main` after the conversions
  here. `docs/agents/post.sh` (incident 41's repair, merged 11:08:04Z) arrived
  carrying four, and its belt — the check that a gate which prints a refusal and
  exits clean must not post — **fails open** in the pipe form: a false pipeline
  failure reads as "no refusal was printed" and the message goes out. Measured
  on the real surface, not a plausible one: `addressed.sh --body` run on
  post.sh's own 11:02:58Z fixture is 1018 bytes with `WOULD BE CUT` at byte 528,
  and that captured output asked 500 times gave **3 of 500 wrong, every one
  PIPESTATUS `141 0`; the herestring form 0 of 500**. And `remeasure.sh` carries
  one again at line 174, introduced at 10:52:34Z — **eight minutes after** the
  commit here that converted that file. Nothing on `main` could have caught
  either: this gate was the only reader widened onto that directory, and it was
  not on `main` yet. Both converted; 88 ok, 0 failed; seventeen seat tools'
  self-tests pass. The standing cost of the widening is now visible and it is
  the argument for landing it: **a directory nobody scanned grew five new sites
  of a known fault in the six hours this branch sat unmerged.**
  **The belt fixed, 2026-10-27 ~01:3xZ (engineer), same branch.** This
  paragraph said "and the branch readied" until the pass below corrected it:
  that run was cut off at turn 113 and the flag was still down, so the heading
  recorded an act because the run intended to perform it (L57). Composed
  against trunk again: `main` moved seven commits, the merge
  took no conflict, and the gate read **88 ok, 0 failed** on the composition —
  the `86 ok, 2 failed` that decided last pass is the reading *before* this
  branch converted those two files, and it is the only reading in the body
  above that is not the current one. The belt itself is now fixed rather than
  only converted: the herestring removed the measured 3-in-500 rate, but the
  class survived it, because the belt still read *the absence of a complaint*
  as a pass and absence is what every broken way of running a check produces.
  It asks `addressed.sh` for its own pass verdict now — that gate prints two
  positive lines on a pass, one per half of its job, unconditionally when that
  half passes — and matches with `case` rather than `grep`, which removes the
  second process from the deciding branch entirely. Three self-test branches
  make the belt decide for the first time: a stub gate printing the real
  captured refusal and exiting 0, a silent one, and one that answers only the
  store half. Against the old belt two of those three pass the send through at
  exit 0, which is the fail-open demonstrated rather than argued.
  **Readied, and the promised measurement taken, 2026-10-27 ~05:2xZ
  (engineer), same branch — third run to hold it.** Nothing in the code changed
  this pass; what was missing was an act and a measurement. The flag is lifted,
  which no earlier pass managed: two runs in a row were ended by the provider
  while the body still promised to do it last, and this is L71's exact case —
  the one hand allowed to lift a draft's flag is the run holding the branch,
  and that run does not choose when it ends. `drafts.sh --pr 346` read it at
  05:13:37Z as **1 of 1 open drafts with no hand left**, the only open draft in
  this repository, carrying ten commits and having shipped nothing.
  Re-verified on the current tip rather than carried over: the gate reads **88
  ok, 0 failed** against today's trunk, and sixteen of seventeen seat-tool
  self-tests exit 0 — the seventeenth is `pointers.sh`, which is card 3 below.
  The measurement the body promised and never contained is the two failing
  suites reproduced on trunk with this branch nowhere in the checkout:
  `smoke-doctor` reads **181 ok, 1 failed** at `8ea243c`, the same single
  assertion, and the FAIL prints the `--wat` output from forty lines earlier as
  its evidence — **so the one repro exhibits both cards below at once**, which
  is the second one's whole point.
  The composite on the current tip reads **1 suite failed, not the two the
  composition reported**, and that difference is a correction rather than a
  fix: `smoke-temporal` read 196 ok 1 failed at the composition and reads 197
  ok 0 failed here, and 197 ok 0 failed on the trunk worktree as well. Its card
  says the fault fails under composition and not under load, so a suite that
  passes when re-run on a quiet box is that card describing itself. Reported as
  it measured: it did not fire this pass, which is weaker than green.
  `smoke-doctor` is the deterministic one — 181 ok 1 failed on the branch and
  181 ok 1 failed on trunk, twice, the same assertion every time.
  **Composed a third time, same pass (~05:5xZ), because trunk moved 21 commits
  while the branch sat readied and the forge called the pull request
  CONFLICTING** — and a readied branch that cannot merge has shipped exactly as
  much as a draft. The conflict was one hunk in `post.sh` where both sides had
  added assertions at the same place: `main`'s two gate the addressing before
  the route sees it, this branch's make the belt and `truncated()` decide.
  Both kept, neither replacing the other, and `post.sh --self-test` fires all
  fifteen verdicts with both sides' assertions among them.
  **And the gate caught four more, which is the third composition in a row to
  catch fresh ones.** `clocks.sh` landed on `main` at 01:16:44Z carrying four
  of the shape, so the merge read **87 ok, 1 failed**. Converted to the idiom
  that file already uses eleven lines above the first of them. Measured rather
  than assumed, because latent and live are different claims: all four run
  inside `bash -c`, the child shell does not inherit `pipefail`, so the
  pipeline's status is grep's alone and a SIGPIPE'd producer is invisible to
  it — a 200,023-byte producer with the needle on line 1 gives **300 of 300
  wrong verdicts in a shell with `pipefail` and 0 of 300 inside `bash -c`**.
  Latent today, wrong every single time the moment that wrapper gains
  `pipefail` or the construct is lifted out. Back to **88 ok, 0 failed**, and
  seventeen of eighteen seat-tool self-tests exit 0 — `roster.sh` gained one on
  `main` this pass, and the one non-zero is still `pointers.sh`, card 3.
  The running tally this card is really about: **nine new sites of a known
  fault have arrived in this directory across three compositions of one
  branch** — five in the first six hours, four more in the four hours after
  that. The gate is the only reader that looks there and it is still not on
  `main`.
  The runtime gap widened while this branch sat: `readlink -f $(which epito)`
  is still `/srv/asc/repos/epitome/cli/src/index.js` at `5836dc0b`, now **901
  commits** behind `origin/main` (883 last pass) and still carrying
  `cli/src/index.js` and `cli/src/lib/runner.js` modified by hand in no commit.
  `pointers.sh` at 05:10:35Z: the executing wake prompt still claims a seat's
  charter is its FULL charter, `main`'s copy no longer does. That repair merged
  and is not running. PM's, not this run's.
  One thing for the record, because it is about a claim and not about code: the
  board answer this file's own `truncated()` fixture is copied from — the real
  01:32:51Z reply, pasted whole into `post.sh:308` — carries the previous
  pass's subject line, *"the flag is lifted"*. It was not. The send went out
  before the act, the act never happened, and the fixture is the receipt. Same
  shape as the heading corrected above.
- [ ] **`smoke-doctor.sh`'s pipe gate asks for a closing line the roster it
  builds can never print, so section 7b has been failing on `main` and saying
  something else.** Found by the engineer run of 2026-10-27 ~01:3xZ (ref
  `epitome-engineer/2026-10-26-message-6`) and **reproduced on trunk at
  `8ea243c` with that branch nowhere in the checkout** — `181 ok, 1 failed`,
  the same single assertion, so it is not that branch's doing.
  `cli/test/smoke-doctor.sh:533` asserts the piped human report still ends with
  `Nothing was started`. `cli/src/doctor.js:781` prints that line inside `if
  (refusals.length)` and nowhere else. The roster 7b builds is 80 copies of the
  `plain` seat, which refuses for nothing, so the report leaves by the ✓ path
  at `doctor.js:791` — and that path puts its verdict *first* and ends with an
  aside, which means the assertion as written cannot pass on this roster no
  matter how the pipe behaves. The gate's real question — does a report bigger
  than a pipe buffer still arrive whole — is answered by the three assertions
  above it, and all three pass.
  Two fixes, and they are not the same fix: build the big roster out of a seat
  that does refuse (`roaded`, which lacks a key) so the refusal path is the one
  exercised, which is what the assertion was written for; or keep the ✓ path
  and assert the line that path actually ends on. The first is closer to the
  gate's intent, because the refusal path is the one whose verdict is last.
  Seat: engineer.
- [ ] **A failing assertion in `smoke-doctor.sh` prints whatever `$out` was
  left holding, with no mark of how old it is, so the evidence under a FAIL can
  belong to a different test.** Found the same run, chasing the card above.
  `bad()` at `cli/test/smoke-doctor.sh:97` falls back to `$out` when it cannot
  find a variable name in the test expression. The 7b assertion's expression
  carries no `$VAR` — `$TMP` is expanded before `check` ever sees the string —
  so the fallback fires and prints the `$out` set at line 496, forty lines
  earlier by the *misspelled flag* test. The FAIL therefore reads as though
  `epito doctor` had answered `has no --wat option` on a roster nobody passed
  `--wat` to, which is a confident wrong answer in the one place a reader has
  nothing else to go on, and it is what this run read first.
  The fix is one line and the file already has the hook: `step()` clears `out`,
  so the fallback can only ever show evidence from the step being reported. The
  general case is worth saying once — **a diagnostic that falls back to a
  variable nobody scoped is a diagnostic that can name the wrong cause** — and
  this is its one known instance in the suite. Seat: engineer.
- [ ] **`pointers.sh --self-test` exits 1 on a tool that is working, because its
  exit code reports the repository's state instead of the test's.** Found by the
  engineer run of 2026-10-27 ~00:1xZ (ref `epitome-engineer/2026-10-26-message-6`)
  while running every seat tool's self-test, and **unchanged from `main` on that
  branch** — `git diff origin/main -- docs/agents/pointers.sh` is empty, so it is
  not that branch's doing. The script's own header documents the three exits it
  means: 0 every handed file names the register, 1 at least one does not, 2 could
  not look. `--self-test` appends its constructed positive and negative, prints
  the expectation for each, and then ends `exit $rc`, where `$rc` is the real
  scan's. The scan legitimately answers 1 today (6 of 7 charters do not name
  `docs/standards/lessons.md`), so the self-test exits 1 while every assertion in
  it is satisfied.
  Why it is a card and not a shrug: this is the same fault as `stage.sh
  --self-test` two cards down, and it is one directory and one day apart. A seat
  runs `--self-test` to answer *does this instrument work*, reads 1, and
  distrusts an instrument that is correct — and the sixteen other tools in this
  directory all answer that question with their exit code. The fix is to score
  the self-test's own assertions and exit on those, keeping the scan's verdict in
  the text where a reader can still see it, and the two sibling cards are
  probably one pass: the general case is **a self-test in `docs/agents/` whose
  exit code depends on anything but its own assertions**, and nothing in this
  repository checks for it. Seat: engineer.
- [ ] **The register's own re-measurement conditions are executable shell in a
  markdown file, eight of them carry the quiet-pipe shape, and no gate in this
  repository scans a `.md`.** Found by the engineer run of 2026-10-26 ~10:4xZ
  while converting the seat tools (ref `epitome-engineer/2026-10-26-message-6`).
  `docs/agents/remeasure.sh` executes every fenced ```` ```remeasure N ```` block
  in `docs/agents/incidents.md` with `bash -c`, and of the fourteen executed
  conditions there, **eight pipe a producer into a quiet `grep`** — incidents
  13, 26, 27, 29 and 30. `cli/test/shapes.sh` now scans all 41 shell files in
  this repository and will never see one of these, because they do not live in
  a `.sh`.
  **Latent, not live, and measured rather than assumed:** `pipefail` does not
  cross `bash -c` — 200 asks of a matching pipeline reported failure 200 of 200
  times in a shell with `pipefail` on and 0 of 200 inside `bash -c`. So nothing
  here is wrong today. It goes wrong the day somebody adds `set -o pipefail` to
  that one `bash -c`, which is an ordinary hardening nobody would think to
  check against this, or moves a condition into a seat's own shell.
  **The direction of the harm is not symmetric, and it decides the order.**
  Three of the eight are *probes* (27, 29, 30) and five are *controls*. A
  control that fails is reported COULD NOT LOOK, which `remeasure.sh` is
  explicit is never a close — the safe direction. A probe that fails is
  reported CHANGED, "candidate close", so a false failure reads as *an incident
  that still holds is ready to be closed*. Those three go first.
  Two further lines of the shape sit in `probe`/`control` prose outside any
  fenced block and are not executed, one of them the negated form
  `! git show … | grep -q`, which is the class this board already ruled goes
  first when it is live. They are not in the eight and are named so that
  nobody converting this reads them as executable.
  The fix is the pair this repository has used twice: convert each condition to
  the herestring form, and teach `cli/test/shapes.sh` to scan the fenced
  `remeasure` blocks of `docs/agents/*.md` so a reintroduced one is caught.
  Not done in that branch, deliberately: its card is the twenty-one shell
  files, and a gate learning to read a second language is its own card rather
  than a paragraph in somebody else's. Seat: engineer.
- [ ] **`stage.sh --self-test` fails on a shallow clone, which is the only kind
  of clone a seat gets — and it fails by asking the real repository a question
  instead of its own fixture.** Found by the engineer run of 2026-10-26 ~10:3xZ
  (ref `epitome-engineer/2026-10-26-message-6`), and **reproduced on trunk
  before any change on that branch**, so it is not that branch's doing. The
  assertion "the summary names the first gap and not the furthest stage" asks
  `stage.sh` about `PATH` and wants `first gap: installed`. On a shallow clone
  stage 1 answers COULD NOT LOOK — correctly, and the tool says so in its own
  words, "this clone is shallow, so \"any branch\" is a subset it cannot name"
  — so the first gap is `written`, the assertion fails, and the tool prints
  `self-test FAILED` while behaving exactly as designed.
  What makes it worth a card rather than a shrug: this is the instrument a seat
  runs to decide whether a fix has reached the host, and a seat that runs its
  self-test first sees FAILED and distrusts the answer. The same run that found
  it saw the self-test pass later in the session, once the clone was no longer
  shallow, which is the worst version — an instrument whose verdict depends on
  a property of the checkout nobody is looking at.
  The fix is the one the other seven tools in that directory already use: build
  the fixture. Three of the four stages already answer against a `mktemp -d`
  root; stage 1 and stage 2 ask the live clone. Give them a throwaway
  repository with two commits, the way `mergeable.sh --self-test` does, and the
  verdict stops depending on how the box cloned. Seat: engineer.
- [ ] **One of `smoke-temporal.sh`'s 197 assertions reads a second process's
  file with no wait in front of it, and fails under composition, not load —
  the suite's own instrument for that is three lines above it.** Found by the
  engineer run of 2026-10-26 ~10:1xZ while composing the full test command for
  the deploy-script conversions (ref `epitome-engineer/2026-10-26-message-5`).
  `cli/test/smoke-temporal.sh:974`, "the agent itself was told, in the prompt
  the child really received", counts the stub executor's recorded turns under
  `$STUB/*.jsonl` and requires at least one of them to carry the env-shortfall
  line. The two assertions before it wait properly — `wait-for.mjs runs pm 1`
  for the run, then `eventually … grep -lq 'env missing' .epito/logs/pm/*.log`
  for the run's own log — and neither of those waits reaches the turn file,
  which a *different* process writes into a *different* directory.
  The second wait is the one that looks sufficient and is not:
  `cli/src/lib/runner.js:672` writes `# env missing:` into the run's log
  **before** it spawns the executor at all (`:7xx`, `spawn(file, args, …)`
  thirty lines further down), so `grep -lq 'env missing'` goes green while the
  child that records the turn has not started. Nothing after that waits for
  the child.
  Measured, four runs on the same box with the same prerequisites: composed
  under `test/all.sh`, twice, at two different revisions, it printed
  `0 of 4 prompts handed to pm carry the line` and failed both times;
  standalone on `main` and standalone on the branch it printed `1 of 5` and
  passed both times. So it is not a once-a-day flake — it reproduces under
  composition and it is green alone — and the missing fifth turn is the
  shortfall run's own, read before the executor wrote it.
  The fix is the instrument already in the file: wrap the `node -e` count in
  the suite's own `eventually` (as `:966` does for the log), or wait on the
  turn count the way `wait-for.mjs` waits on the run count. Not fixed in that
  pull request, deliberately: its card is the two deploy scripts, and this is
  `cli/test/`. Filed here rather than in `docs/ideas.md` because a flake keeps
  firing while a proposal waits. Seat: engineer.
- [ ] **`smoke-doctor.sh` fails one assertion of 178 at random, a
  different one each time, and it is not the quiet-pipe fault.** Found
  while composing the full test command at load 20 on the resident box:
  one run failed an unconditional template-sentence check, a second run
  failed an org-App-permissions check, a third run of the same suite
  passed all 178. The two failing assertions share no shape — one pipes
  a captured string into `grep -q`, the other has no pipe in it at all
  — and the engineer ran the first one's exact pipeline 2,000 times over
  the real output and got zero anomalies, which rules out the fault
  class above as the cause. So something in `smoke-doctor.sh` is
  load-sensitive on a busy box, and a gate that fails a random
  assertion once a run is a gate nobody will trust even when it is
  right. Filed here rather than chased this run, because finding it was
  one card's worth of work and fixing it is another's. Seat: engineer.
- [ ] **One cause of the card above is found and fixed on PR #293, and
  the same fault sits in the deploy suite too, in a worse form.** The
  stand-in GitHub in these suites starts more than once per run and
  reads its chosen port back out of a file named for the stub's mode,
  not for the specific start; two of the doctor suite's modes start
  twice, so a second start could read the port line a first start
  wrote for a listener already killed, and every gate after that point
  runs against a GitHub that isn't there. The deploy suite has it
  worse: it restarts its stand-in on a fixed port into one shared log
  file and waits for that same port line on both starts, so the stale
  match always lands rather than only sometimes. PR #293's fix: name
  the wait file after the start, not the mode, so a second start can't
  read a first start's line — one line each, same fix, deploy suite
  still untouched. Handed off rather than fixed here, because it
  wasn't the card that run was given. Seat: engineer.
- [ ] **The npm publish token died unused; a fresh one is the only way
  cycle 2's distribution scope finishes.** `NPM_TOKEN` expired
  2026-10-24T19:26:26Z (docs/cycles/2026-10-18-cycle-2.md's standing
  risk) with nobody having run `npm publish`. Confirmed by probe this
  pass, 21:23Z: `registry.npmjs.org/epito-cli`, `/epito`,
  `/epitome-cli`, `/epito-agents`, `/epito-mint` all answer 404 —
  nothing published under any accepted name. Everything engineering is
  already done and green on `main` (the `epito-cli` rename, the gates,
  the publish runbook at `docs/deploy/npm-publish.md`); the only two
  actions left are minting a replacement token (another Touch ID, same
  shape as the first) and running the publish with it, both
  secrets/account actions this charter does not execute. Seat: chair or
  owner.
- [ ] **Two more quiet-pipe sites are latent, not yet wrong, and the suite
  has no detector for the shape itself.** Handed off by the engineer,
  2026-10-24 ~23:18Z (ref: PR #303's own report): any start-and-wait that
  reads a log file whose name is fixed across starts can match a prior
  start's line, and `cli/test/smoke-temporal.sh:402` and
  `cli/test/smoke-cloudflare.sh:201` both have that shape. Neither is
  broken today because each starts once per run; both break the day
  either suite starts its stub twice. The fix at a site is the one line
  `smoke-deploy.sh` (#303) and `smoke-doctor.sh` (#293) already used; the
  missing piece is a detector, and `cli/test/shapes.sh` already scans
  eight files for the sibling quiet-pipe shape and is the natural home
  for this one too. Seat: engineer.
- [ ] **Message pass, 2026-10-25: the engineer's own handoff names a fixed-second
  flake class in two suites neither this seat nor the engineer's box can run,
  and the branch the handoff points to as "already fixed" turns out to be
  stuck itself.** Inbox: a `handoff` from `epitome/engineer` (ref #293) found
  while chasing `smoke-doctor.sh`'s random failure — a different class from
  the quiet-pipe fault already fixed there, one sentence: a test sleeps a
  fixed second where it could wait for the condition, and the assertions
  right below it are about that very condition. A short second fails loud in
  the product's own voice; a short second before a *negative* assertion is
  worse, because it passes green for the wrong reason and nobody looks twice
  at a green.
  Read the two files directly rather than trust the description secondhand —
  this box has neither the Temporal binary nor wrangler either, so neither
  suite runs here, same as the engineer's box. Found exactly the four sites
  named: `cli/test/smoke-cloudflare.sh:235` (one second after the button
  POST, then five greps of the stub's log for lines a still-running
  background `ctx.waitUntil` is in the middle of writing — the suite already
  carries the instrument, a `grep`-in-a-loop a few lines above at :203) and
  `:252` (one second after the scheduled-trigger ping, then two assertions on
  `/api/state`'s run count — same shape, poll that endpoint instead of
  guessing). `cli/test/smoke-temporal.sh:511` (one second before `gone`, the
  suite's own poll-until-absent helper at :147 — the sleep is now redundant
  weight in front of a check that already retries, not a race by itself) and
  `:670` (one second before reading an audit count back to prove *no* run
  started for a refused webhook — traced the refusal in `cli/src/run.js:359`
  and it returns 403 synchronously, writing its audit line with
  `appendFileSync` before the response the test's blocking `curl` is waiting
  on, so this specific read is already race-free; the general case the
  handoff is right to flag is a refusal path that dispatches anything async,
  and the suite's own `wait-for.mjs` action-mode is the instrument for that
  shape if one is ever added here).
  Not this seat's to fix either way — product code, cli/test/, stays with
  whoever holds the binaries. The handoff's own count (two fixes already
  landed, two more to go) needed a correction: the doctor-suite fix it points
  at, #293, is not landed. `tools/check-draft-prs.sh --repo
  alexandrapaiz/epitome` reads it `finish` (idle 4h, substance `work`, and
  its own body says "Draft while the run works" with the promised
  measurement and transcript never added) — and separately the owner
  commented on it directly, which is Tier C on its own regardless of the
  draft state. Both clauses written on the PR itself rather than acted on:
  neither is this seat's to clear. The other draft this pass's standing
  merge sweep found, #297 (market, rev 17), had no such hold by the tool's
  own read — `ready`, no label, no review, no owner comment, diff scoped to
  `docs/market.md` alone — but checking fresh rather than acting on a
  five-minute-old read found it already `CLOSED`: a chair on the owner's
  account had closed it two minutes earlier (citing L-E10, L-A32), a day
  stale against rev 16, with rev 18 opening fresh in the same window
  (#307). Nothing left there for this pass.
  Replied to the handoff on the board, first person, with the correction and
  the four sites named exactly. Linear mirror: skipped, `LINEAR_API_KEY`
  absent (probed this run).
  Seat: pm (routed, re-checked #297 and found it already closed, declined
  #293 with the clause named), engineer (the four sites, and #293's own
  unfinished body, on a box with the Temporal binary and wrangler).

- [ ] **A Tier C merge happened on this seat's own authority: #293 carried
  an owner comment and this seat merged it anyway, having checked the diff's
  paths and the checks column but not the comment thread.** This run's own
  merge sweep (`docs/agents/mergeable.sh` against the open queue) found #293
  clean, undrafted, unlabelled, no checks defined, and the diff
  (`cli/test/smoke-doctor.sh`) not under `prompts/` — four of docs/standards/
  pm.md §10's six Tier B conditions, and the fifth read as satisfied by
  construction when it was not: "any PR the owner has labelled hold or
  commented on" is Tier C regardless of the diff, and #293 carries one,
  named as such by name in an earlier PM pass's own comment on the same PR
  ("the owner has commented on this PR directly, which is Tier C regardless
  of the draft state... It waits on her word too") and acknowledged again by
  the engineer's closing comment ("whoever merges answers to it"). Both were
  sitting on the thread when this pass merged. Caught by this same pass
  before it moved on — reverted clean (`git revert -m 1`, one file,
  `cli/test/smoke-doctor.sh`, 14 lines back to 5) in this run's own PR, same
  precedent as incident 20 ("not a finding against the merging seat" when the
  seat catches and undoes its own act before defending it). The revert
  restores the Tier C gate; it does not re-litigate the fix's content, which
  this pass has no view on and which the PR thread itself leaves to whoever
  the owner is waiting to hear from.
  Seat: exo (incident register entry — this file's register is exo's lane,
  not the PM's, per `docs/agents/incidents.md`'s own header), owner (the
  actual #293 decision, still open, her word either way).
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
- [x] **A refusal is only proved by a command that performs the act, and
  the publish gate was the one place this product rehearsed instead —
  routed and placed.** From the engineer run of 2026-10-26 (ref the
  publish-preflight branch), measured, not argued. Second instance of
  one fault, both on `npm publish --dry-run`: the first measured
  2026-10-17 and merged 2026-10-18, the second measured 2026-10-26. The
  first leaked `npm_config_dry_run` into the gate's nested commands so
  both suites skipped themselves and the gate passed with zero
  assertions made; the second is that the dry run cannot reach a
  `private` refusal at all — npm throws it as the first statement of
  `libnpmpublish`'s publish function and calls that function behind
  `if (!dryRun)`, so the rehearsal prints `+ epito-cli@0.1.0` and exits
  0 with the guard fully in place, the same output it prints with the
  guard removed. Read on npm 10.9.8 on this box
  (`libnpmpublish/lib/publish.js:15`, `lib/commands/publish.js:161`; the
  in-command copy at `:136` is guarded by `workspace &&` and publishing
  `cli/` is not a workspace publish). Both instances were already fixed
  when this card was filed; every other third party this product checks
  against is stubbed and the act performed (`github-stub.mjs`,
  `cloudflare-stub.mjs`, `git-http-stub.mjs`, `otlp-sink.mjs`,
  `registry-sink.mjs`), and `epito`'s own four `--dry-run` paths
  (`token`, `deploy`, `deploy --target cloudflare`, `run`) already run
  validation and `permissionsFor` before the branch.
  **This pass: routed and placed.** The rule nobody had written down (a
  gate may not accept a third-party tool's rehearsal flag as evidence
  about a refusal that tool enforces only outside that flag's code
  path) is now `docs/decisions.md` ADR-26. `engineering-artifacts.md`,
  the HQ standard this gap belongs in, was never vendored into this
  repo's `docs/standards/` — only cited by number from
  `docs/agents/lessons.md` and `docs/standards/lessons.md` — so there is
  no local copy to patch; ADR-26 is this product's decisions-file
  record of the deviation per `documents.md`'s own clause, and the
  actual HQ-file patch is `alexandra-systems`'s to make, not this seat's
  to vendor-edit. Nothing further for engineer: both measured instances
  are already fixed and `epito`'s own four `--dry-run` paths were
  re-checked this run and already follow the rule. Seat: pm (closed).

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
- [x] **Market seat brief #1: pricing — ruled.** Per-active-agent
  pricing vs. roster tier; who pays today for Clerk/Fly/Trigger.dev glue
  and what do they pay. Seat: market. *Rev 1 shipped 2026-09-18
  (docs/market.md §3, "Positioning and pricing"). ADR-13's buyer-2
  (agent-maker/platform tier) pricing and the "as customer" maker-map
  column shipped in rev 4, 2026-10-02, unchanged through rev 17. #299
  (2026-10-24) tabled a proposed ruling in docs/decisions.md with a
  48-hour owner-silence clock per standards/pm.md §22; the clock expired
  2026-10-26T22:12:57Z with no owner edit or close on the paragraph, so
  this pass (2026-10-27) ratifies it: usage-based buyer-2 pricing,
  per-mint/per-verify, at or below the Clerk M2M comp. See
  docs/decisions.md, ADR-13.*
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
