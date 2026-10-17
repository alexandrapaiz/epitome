# OKRs, Q4 2026 (Oct-Dec)

Maintained by the OKR seat (`prompts/okr-agent.md`). This revision
supersedes the draft at PR #35 (`epitome-okr/2026-09-30-window`,
opened 2026-09-30T03:54Z, still unmerged): zero commits landed on
`main` between that run and this one (`main`'s tip was already 232f759
when #35 opened), so every grade below is identical to #35's. This run
re-ran the evidence itself rather than trusting the prior draft's
prose — `cli/` unit suite (85/85, re-run this session after `npm
install`), every `grep`/`ls`/`gh`/`npm view` check #35 cites — and adds
one thing #35 could not have known: three engineer PRs opened *after*
#35 (today, #36 and #37; yesterday, #33) sit on exactly the gaps this
document names. They are graded at 0.0 anyway, because they are
unmerged, but they change what "next" means more than anything else in
this document. See "What would move the needle next" at the end.

Closing #35 as superseded by this PR, with that reason, so the repo
does not carry two drafts racing to create the same file (the
duplicate-draft failure L-E10 names for code applies equally to a
doc nobody merged yet).

## If you only read one section, read this one

Nine key results, three graded above 0.5, six graded 0.0 with a named
reason. The one item that should worry the owner most is not a zero,
it is which zero: **O2 KR1, the passport**, still has not one line of
code anywhere in this repo, eleven days after the owner signed the
mission and named it her favorite portability proposal. ADR-12's own
tripwire calls it the thing that "must be visible before their next
credential release, not after." Everything else zeroed here is a
sequencing question this org is actively working through (see below).
This one is a clock the company does not control, and it has had zero
engineering hours of any kind.

| Objective | KR | Tag | Grade | One line |
|---|---|---|---|---|
| O1 wedge exists | KR1 mint + deploy | Committed | **0.5** | minting is real and tested; `deploy` still prints "platform in progress" on `main` — but the provisioning half is a tested, unmerged PR away (#36) |
| O1 wedge exists | KR2 alexandria migrated | Committed | **0.0** | not started, three unchecked backlog lines |
| O1 wedge exists | KR3 15-min benchmark | Aspirational | **0.0** | no `docs/benchmark/` directory exists |
| O2 moat | KR1 passport | Committed | **0.0** | no passport code anywhere in the repo, 11 days after signing |
| O2 moat | KR2 foreign framework, own `[bot]` | Committed | **0.85** | shipped, tested against real LangGraph, in `main` |
| O2 moat | KR3 one manifest, two chat backends | Aspirational | **0.1** | Slack is a one-way webhook, not an identity |
| O3 demand counted | KR1 three HQ seats upgraded | Committed | **0.0\*** | *no evidence this repo can see, not a claim it didn't happen |
| O3 demand counted | KR2 five non-owner users | Aspirational | **0.0** | no `docs/users.md` |
| O3 demand counted | KR3 npm-installable | Committed | **0.0** | `epito` 404s on the npm registry; packaging is a tested, unmerged PR away (#33) |

The evidence rule, from the charter: shipped files, closed cards, and
run logs, never claims. Where that rule produces an uncomfortable
grade next to real, finished-looking engineering work sitting in an
open PR, the discomfort is deliberate — a KR does not move until the
work is on `main`, no matter how done it looks in a diff.

## Mission (held, never edited here)

> Give every agent, whoever built it, a self its owner holds and every
> platform honors.

Signed by the owner 2026-09-20 (ADR-14), `docs/vision.md` §0. This
seat holds this line and grades against it. It never edits it.

## Q4 2026 objectives

(Adopted unchanged from the all-hands counsel at
`docs/allhands/2026-09-20-okr.md`, the only Q4 objective set this repo
has ever proposed. New objectives only at quarter turns per the
charter — Q4 just turned, and nothing has surfaced that would justify
swapping one of the three out, so they carry forward as-is.)

### O1. An agent minted from one file acts on GitHub as itself (the wedge exists)

**KR1, Committed, grade 0.5.** "`epito deploy` provisions a GitHub App
principal and `epito token` returns a short-lived token that is never
written to disk."

Shipped half: `cli/src/lib/identity.js` signs a short-lived RS256 JWT
as the App, exchanges it for an installation token scoped to exactly
`[identity].scopes` via `SCOPE_MAP`, hands the token back in memory
only. `cli/src/token.js` exposes `epito token <name>`.
`cli/test/unit.mjs` passes 85/85 (re-run this session, this box, after
`npm install` — the first attempt failed on a missing
`@temporalio/client` module, which is a clean-checkout install gap,
not a code defect; `npm install` then 85/85 clean). PR #24 (merged
2026-09-29) additionally shows 158 smoke-test assertions of this mint
running end to end on the Temporal engine.

Not-shipped half: `cli/src/index.js` line 34 reads, verbatim, on
`main` right now: `epito deploy        provision the agent (not yet:
platform in progress)`. Nothing provisions. An operator creates the
GitHub App by hand today.

**Named reason for below 1.0, unchanged from #35:** the KR bundles two
verbs, "provisions" and "mints"; only the second shipped.

**What's new since #35:** PR #36 (opened today, DRAFT, unmerged) is a
tested implementation of exactly the missing half — `epito deploy`
builds the App manifest from `[identity].scopes`, serves the one
local-click callback, writes `.epito/principals.json` +
`.epito/keys/<agent>.pem`, and is idempotent on redeploy (spec rule 4).
Its own PR body shows `test/all.sh --strict` green across 5 suites
(363 assertions total) and a full dry-run/create/redeploy/mint
transcript against a stubbed GitHub. It also proposes ADR-20 (ratifies
app-per-agent over a shared App) — proposed, not ratified; merging the
PR ratifies it. None of this moves the grade above, because none of it
is on `main`. It is the single most relevant fact this document can
report about where KR1 actually stands.

**KR2, Committed, grade 0.0.** "One alexandria seat runs on epito.me
and its ADR-27 hand-wiring is deleted." `docs/backlog.md` lines 39-44
list all three dogfood-migration steps unchecked. No PR here touches
the alexandria repo. No evidence, grade 0.0.

**KR3, Aspirational, grade 0.0.** "Fresh clone to first commit-as-bot
in under 15 minutes, evidenced by a timed run log under
`docs/benchmark/`." Directory does not exist. No evidence, grade 0.0.

### O2. One self crosses walls, demonstrated, not claimed (the moat)

**KR1, Committed, grade 0.0.** "The passport prototype." A repo-wide
case-insensitive search for `passport` across every source file
matches only prose in `docs/decisions.md`, `docs/vision.md`,
`docs/ideas.md`, and the all-hands market notes — zero source files,
zero `agent-card.json`, zero verify script. No evidence, grade 0.0.
Unchanged from #35, eleven days after the owner named it her favorite
of four portability proposals.

**KR2, Committed, grade 0.85.** "One agent we did not write acts on
GitHub as its own `[bot]` through `epito token` with zero changes to
its own code." Shipped: ADR-17 specifies the adapter contract;
`cli/adapters/langgraph_run.py` is a stdlib-only Python shim that reads
the agent's own `langgraph.json` unmodified. The repo's smoke suite
reports this suite as skipped on this box (no `langgraph`-importable
Python here), same gap #35 hit; the unit coverage and the merged PR
#24 transcript stand as evidence regardless.

**Named reason for below 1.0, unchanged:** the full proof lives in a
merged PR body (#24), not as a standing artifact in the tree, and
neither this run nor #35 could independently re-execute the live smoke
pass for lack of a local `langgraph` install.

**KR3, Aspirational, grade 0.1.** "The same manifest posts as itself on
two chat platforms." `cli/src/lib/slack.js` only posts, over an
incoming webhook — a notification line, not a bot-user principal
(ADR-7's own definition of the target: "bot user as the principal,
workspace OAuth install"). One backend, not two.

### O3. Someone other than the owner runs an agent on it (demand is counted, not asserted)

**KR1, Committed, grade 0.0\*.** "Three Alexandra Systems HQ seats
upgraded to real principals." `gh api repos/alexandrapaiz/alexandra-systems`
still 404s under this run's token, same as #35 found. The asterisk
still matters: unreachable, not confirmed-absent. This gap has now
persisted across two OKR runs with no change — worth the owner's
attention as an access decision, not a re-ask.

**KR2, Aspirational, grade 0.0.** "Five agents deployed by people who
are not the owner." `docs/users.md` does not exist. No evidence, grade
0.0.

**KR3, Committed, grade 0.0.** "`epito` and the MCP server installable
by a stranger." `git tag -l` and `gh release list` both empty.
`npm view epito version` still 404s (registry has an unrelated
`epitome` package at 0.6.2). No MCP server code under `cli/src`. No
evidence, grade 0.0.

**What's new since #35:** PR #33 ("Ship the CLI to npm," opened
2026-09-30, DRAFT, unmerged) packages the CLI to a 148 KB tarball and
proves it installs clean into an empty prefix — the packaging half of
this KR. It does not touch the MCP server (still unstarted anywhere in
the tree) or cut a release tag. Landing it would not clear this KR by
itself, but it is the first unblocked move toward it.

## Benchmark (the mission's proxies)

| Proxy | Reading today |
|---|---|
| Minutes from `epito init` to first commit-as-bot | Unmeasured, no `docs/benchmark/` run log |
| Count of agents minted by non-owners (HQ seats excluded) | 0, no `docs/users.md` |
| Platforms one agent is verified on through its passport | 0, no passport exists to verify anything |
| Lines of ADR-27 plumbing deleted from alexandria | 0, migration unstarted |

All four still read zero, unchanged across both OKR runs this quarter
despite real engineering (ADR-15 through ADR-20: the Temporal engine,
the board, LangGraph, tracing, the router, and now deploy
provisioning) happening around them. Carrying forward #35's proposed
fifth proxy, since the owner has not yet ruled on it either way: count
of non-epito agent frameworks proven, with a real minted credential,
to act on an outside platform as themselves. Reading today: still
**1** (LangGraph). It remains the only number in this document that
has moved all quarter.

## Drift, stated bluntly

1. **The passport is still the single most owner-flagged item with
   the least work, and the gap has now been reported twice.** A finding
   that recurs unchanged across two OKR runs with no engineering
   response is no longer a sequencing note, it is the register defect
   L-A4 names for repeated corrections, pointed at a KR instead of a
   correction. This document cannot fix the sequencing; it can only
   keep saying, in the same words, that the item with an external clock
   on it has had zero hours for eleven days.
2. **O1 KR2 and all of O3 still have zero engineering hours**, while
   five more ADRs' worth of runtime and identity-provisioning work
   (ADR-15 through ADR-20) landed or is in flight around them. This
   remains owner-directed sequencing, not seat drift — nobody built the
   wrong thing — but the roadmap actually being built for two straight
   OKR cycles is still not the one these OKRs describe.
3. **Not drift, a correction worth noting:** #35 flagged the
   five-times-duplicated identity-mint build as an open risk. PM's own
   hill update (PR #34, 2026-09-30) shows it resolved: the four
   duplicate PRs are closed, the correct implementation is on `main`,
   and the engineer charter now carries L-E10 ("survey the open PRs
   before you build") as a bound rule. PR #36's body is itself an
   example of that rule working — it opens with a PR survey before
   writing a line of code. The mechanism the prior drift note asked for
   now exists and is visibly in use.
4. **New, process-level:** as of this run, the repo carries seven open
   draft PRs (#28, #30, #31, #32, #33, #36, #37 — this document's own
   predecessor #35 makes eight before it's closed), several of them
   containing finished, tested work directly relevant to O1 and O3.
   This is exactly the queue-depth pattern L-X7 names: a correct fix
   that never ships is a measurement of the bottleneck, not a to-do.
   PR #36 in particular is a tested answer to the single highest-value
   open KR gap (O1 KR1's missing provisioning half) sitting unmerged
   the same day it was opened. This document does not recommend merge
   order — that is the owner's and PM's call — but the OKR seat's job
   is to say plainly that the fastest path to moving O1 KR1's grade is
   a merge decision, not a build.
5. **No mission drift found.** Every shipped artifact graded above
   (the mint, the LangGraph adapter, the router, the board) and every
   unmerged artifact described above (deploy provisioning, npm
   packaging) reads as identity-and-runtime work inside the envelope
   ADR-10 draws. The gap in this document is coverage, sequencing, and
   now a merge queue, not direction.

## What would move the needle next

Not a recommendation to build anything new — the opposite. Three open
PRs already contain tested, unmerged answers to three of this
document's named gaps:

- **PR #36**, merged, moves O1 KR1 from 0.5 toward ~0.9 (provisioning
  shipped; only the dogfood-migration half of the wedge would remain
  unproven).
- **PR #33**, merged, is a step toward O3 KR3 (packaging done; a tagged
  release and the MCP server would still be missing).
- Neither PR touches the passport (O2 KR1) or the dogfood migration
  (O1 KR2) at all — those two remain genuinely unbuilt, not merely
  unmerged, and are where new engineering hours would move a grade
  that no amount of merging the current queue will touch.

## For whoever reads this next

The rule this document runs on, unchanged: **a KR without a file, a
merged PR, or a run log behind it is a 0.0, no matter how finished the
work looks in an open diff.** Before writing a grade, find the
artifact on `main` — a path that exists, a PR number that merged, a
test you ran yourself. A PR sitting open with green tests and a full
transcript is evidence that the work is ready, not evidence that it
shipped. If you can't find it on `main`, the grade is 0.0 and the
reason is "no evidence," in those words.
