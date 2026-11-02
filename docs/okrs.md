# OKRs — Q4 2026 (Oct–Dec)

Maintained by the OKR seat (`prompts/okr-agent.md`). Objectives and KR
text are carried unedited from the 2026-09-20 all-hands counsel
(`docs/allhands/2026-09-20-okr.md` §2), ratified against the mission
below. First landed on `main` 2026-10-27 (`ef3aa8f`), after two prior
attempts (#35, #39) were closed and a third (#53) closed as a
duplicate — see that commit for the full history. Re-verified
independently twenty times since, each against the then-current tip:
#372, #373, #392, #393, #400, #403, and #414 (closed, superseded —
each the stray draft of its own pass, resolved before or by the next
re-verification); #377, #381, #383, #386, #389, #397, #398, #405,
#406, #410, #411, #412, and #416 (merged); no grade has moved across
any of them.

This is the twenty-first re-verification, against today's true tip
`30053c4` (the merge of this seat's own #416, landed `08:44:41Z`,
cleanly on top of `eba9d62`). `git diff eba9d62..30053c4 --stat`
touches 16 files, most of it the engineer's atomic-write hardening
(new `cli/src/lib/atomic.js`, 176 lines, plus its own 298-line test)
threaded into `cli/src/deploy.js` and `cli/src/index.js` — real code
movement for the first time in several passes, but every fact this
charter grades was re-checked directly against `30053c4` rather than
carried forward on the diff's shape: `cli/package.json` still has
`"private": true`; every seat workflow in `.github/workflows/`
(`agent-market.yml`, `agent-engineer.yml`, `agent-exo.yml`,
`agent-frontend.yml`, `agent-okr.yml`, `agent-pm.yml`,
`asc-heartbeat.yml`, each grepped directly) still authenticates with
the shared `${{ github.token }}`; `docs/benchmark/` and
`docs/users.md` still don't exist; no `passport` match exists anywhere
under `cli/`; `docs/cycles/` still has no file newer than
`2026-10-18-cycle-2-retro.md`; `docs/sprints/` still does not exist;
the three dogfood-migration checkboxes in `docs/backlog.md` (lines
1476, 1497, 1499) are still unchecked; a fresh probe of
`registry.npmjs.org/epito-cli` just now still returns 404; `identity.js`
and `token.js` are byte-identical to the last verification (`git diff
eba9d62..30053c4 -- cli/src/lib/identity.js cli/src/token.js` is
empty) and `cli/adapters/langgraph_run.py` (277 lines),
`cli/test/smoke-langgraph.sh` (221 lines), and `cli/src/lib/slack.js`
(66 lines) all still match the line counts every prior pass has cited;
and `docs/vision.md` §0 is still byte-identical to the version this
seat last held (`git diff eba9d62..30053c4 -- docs/vision.md` is
empty) — no drift to name there either.

**New this pass:** `cli/src/deploy.js` moved for the first time since
`ef3aa8f` (494 → 514 lines) — see O1 KR1 below for why that does not
change its grade — and `docs/backlog.md` now records a second
`NPM_TOKEN` window dying unused (line 23: "Two `NPM_TOKEN` windows have
now died unused"), see Drift item 3. This seat had zero open pull
requests when this run started (`gh pr list --search
"head:epitome-okr" --state open` returned `[]`), the first clean start
in three passes running (#412 and #414 both needed a stray closed out
from under them).

## Mission (held, never edited — docs/vision.md §0)

> Give every agent, whoever built it, a self its owner holds and every
> platform honors.

## Objectives

### O1. An agent minted from one file acts on GitHub as itself. (the wedge)

- **KR1, Committed — 0.5.** `epito deploy` provisions a GitHub App
  principal; `epito token` returns a short-lived token never written
  to disk. The code is real and substantial — `cli/src/deploy.js`
  (514 lines, up from 494 this pass), `cli/src/token.js` (115 lines,
  unchanged, writes only to stdout), `cli/src/lib/identity.js` (435
  lines, unchanged: RS256 App JWT signing, installation-token minting,
  scope→permission mapping) — and tested end-to-end against a local
  stub GitHub server (`cli/test/github-stub.mjs`,
  `cli/test/smoke-deploy.sh`, both still present). What moved this pass
  is reliability, not proof: the engineer's new `cli/src/lib/atomic.js`
  (`writeFileAtomic`) now backs the principals store and the GitHub
  App private-key write in `deploy.js`, so a disk-full mid-deploy can
  no longer truncate either file. That closes a real crash-safety gap
  but is orthogonal to this KR's own evidence bar: a fresh-clone
  transcript of a commit landing as `<name>[bot]` against *real*
  `api.github.com`. `docs/mvp/2026-10-05-status.md` still says "A real
  GitHub App was not created... Not proven tonight," and no later run
  closes that gap. Same grade as every prior verification.
- **KR2, Committed — 0.0.** One alexandria seat runs on epito.me and
  its ADR-27 hand-wiring is deleted. `docs/backlog.md`'s own three
  dogfood-migration cards (step 1 run it, step 2 delete the
  hand-wiring, step 3 write the before/after) are all still unchecked.
  **Named reason:** the owner's cycle 2 override bet the npm
  distribution MVP (`docs/pitches/BETTING-MEMO-cycle-2.md`) ahead of
  this migration — the same re-sequencing #39 already named for O1/O3,
  still in force six weeks later.
- **KR3, Aspirational — 0.0.** Fresh clone to first commit-as-bot in
  under 15 minutes, logged under `docs/benchmark/`. That directory
  does not exist anywhere in the repo. No evidence.

### O2. One self crosses walls, demonstrated, not claimed. (the moat)

- **KR1, Committed — 0.0.** The passport prototype (signed card, verify
  script, one agent proven the same `[bot]` + Slack user). Zero code:
  no `passport` subcommand in `cli/src/index.js`, no match for
  "passport" anywhere outside `docs/`. **Named reason:** owner override,
  not neglect — `docs/cycles/2026-10-18-cycle-2.md` records
  `passport-v0-github` declined for cycle 2 "not on the merits" by the
  owner's direct MVP call, the second cycle running it has been
  declined this way.
- **KR2, Committed — 0.6.** One agent epito did not write acts on
  GitHub through `epito token` with zero code changes. Real and
  substantial: `cli/adapters/langgraph_run.py` (277 lines, unchanged)
  runs an unmodified `langgraph.json`/graph, handles compiled and
  uncompiled graphs, and is smoke-tested (`cli/test/smoke-langgraph.sh`,
  221 lines, unchanged) against the actual installed `langgraph`
  package, not a fake. Held below 1.0 for the same reason as every
  prior verification: the fixture app it runs
  (`cli/test/fixtures/langgraph-real/`) is one this repo wrote, not a
  fresh clone of an independently-authored LangGraph project, so the
  KR's "zero changes to its own code" claim is tested against our own
  stand-in rather than someone else's real graph.
- **KR3, Aspirational — 0.0.** One manifest on two chat platforms,
  only the backend name changed. Only one platform exists at all:
  `cli/src/lib/slack.js` (66 lines, unchanged) posts a one-line status
  line to a webhook and explicitly defers reading/`@-mention` handling
  ("a Slack reader is a separate, later process," per its own header).
  No second platform exists in code. No evidence of the KR as written.

### O3. Someone other than the owner runs an agent on it. (demand is counted, not asserted)

- **KR1, Committed — 0.0.** Three Alexandra Systems HQ seats upgraded
  to real per-agent principals. Checked directly: every seat workflow
  in `.github/workflows/` (`agent-engineer.yml`, `agent-exo.yml`,
  `agent-market.yml`, `agent-okr.yml`, `agent-pm.yml`, plus
  `agent-frontend.yml` and `asc-heartbeat.yml`) still authenticates
  with the shared `GH_TOKEN: ${{ github.token }}`; none reference a
  minted per-agent credential. **Named reason:** no cycle has bet this
  work — cycle 1 bet the resident runtime, cycle 2 bet npm
  distribution — so it has sat unscheduled rather than refused. This
  finding has now been reported unchanged at least twenty-one times:
  first in #53 (2026-10-05), again at the `ef3aa8f` landing
  (2026-10-27), again in #372, #373, #377, #381, #383, #386, #389,
  #392, #393, #397, #398, #400, #403, #405, #406, #410, #411, #412,
  #414 (closed without landing, but the finding was re-checked and
  re-stated in its body before closure, so it counts), and #416, and
  again at this pass; see Drift below.
- **KR2, Aspirational — 0.0.** Five agents deployed by non-owners,
  tracked in `docs/users.md`. That file does not exist. No evidence.
- **KR3, Committed — 0.3.** `epito` and the MCP server installable by
  a stranger. The CLI half is nearly done and the MCP half is not
  started. `cli/package.json` has a real `bin` entry and every
  publish-time gate is green on `main` (`docs/deploy/npm-publish.md`'s
  runbook, `cli/test/pack.sh`, `cli/test/stranger.sh`), but
  `"private": true` still blocks `npm publish`, and the registry
  itself confirms nothing is live: a direct probe of
  `registry.npmjs.org/epito-cli` just now (2026-11-02) still 404s.
  What is left for this half is a secrets/account action (mint a
  token, run the publish), not engineering — and that action has now
  missed twice: `docs/backlog.md` (line 23) records a **second**
  `NPM_TOKEN` window dying unused since the first expired unused
  2026-10-24T19:26:26Z. The MCP server half is pure pitch
  (`docs/pitches/epito-mcp-server.md`); it has been declined for a
  cycle bet four times running, most recently in cycle 2, each time by
  owner override rather than on the merits.

## Benchmark (the mission's proxies)

Unchanged from the 2026-09-20 baseline and every re-verification since
— no change proposed to the proxies, only to what they currently read:

| Proxy | Reading |
|---|---|
| Minutes, `epito init` → first commit-as-bot | 0 — mechanically measurable the moment a real GitHub App deploy runs (O1 KR1's gap); nothing but running the clock stands in the way |
| Agents minted by non-owners (HQ seats don't count) | 0 (O3 KR2) |
| Platforms one agent is verified on via its passport | 0 — no passport code exists yet (O2 KR1) |
| Lines of ADR-27 plumbing deleted from alexandria | 0 (O1 KR2) |

All four still read zero, six weeks after the baseline reading and
unchanged across every re-verification since, including this one. The
one proxy nearest to moving is the first: the code it depends on
(`epito deploy`/`epito token`) is complete and tested, so the number is
one real deploy away rather than one build away.

## Drift (stated plainly, for the owner to rule on)

1. **HQ still does not dogfood its own identity product — reported
   again, unchanged.** O3 KR1's finding (shared `github.token`
   everywhere, no minted per-agent principal anywhere in
   `.github/workflows/`) is identical to what #53 named four weeks ago
   and what every re-verification since, including this one, has
   confirmed again. The mission's first sentence is
   "give every agent... a self its owner holds"; by that sentence,
   every seat writing to this repo, including this one, still runs as
   a generic Actions identity, not a self of its own. Not new drift,
   but worth repeating now that the gap has gone two OKR cycles with
   no cycle bet touching it.
2. **The message-dispatch loop named every pass since #405 still holds
   at four seats, and its volume keeps growing.** Filtering every
   seat's own pull requests created `2026-11-02` to branches
   containing `-message` (`gh pr list --search "created:2026-11-02"
   --state all --json number,state,headRefName,createdAt --limit 300`,
   grouped by seat prefix, re-run fresh for all six roster seats rather
   than carried forward — the default `gh` page size of 30 silently
   truncated an earlier attempt at this count, worth naming so the next
   pass doesn't repeat it) finds: this seat (okr) 19 such pull requests
   today (13 merged — `#377` through `#416` — 6 closed unmerged, 0
   still open; grew by one merge, `#416`, since last pass's 18/12/6/0);
   exo 18 (`#374` through `#422` — 11 merged, 5 closed unmerged, 2
   still open: `#396` and a new `#422`, up from last pass's 14/9/3/2);
   the engineer 8 (`#378` through `#419` — 7 merged, 0 closed, 1 still
   open: a new `#421`, up from last pass's 6/5/0/1); and pm 4 (`#391`
   still open, `#399` merged, `#413` still open, and a new `#420` still
   open, up from last pass's 3/1/0/2). `market` and `frontend` still
   show none, re-checked directly. What is common to all four, and is
   still the actual drift, is the dispatch mechanism itself:
   `agents/*/agent.toml`'s `[trigger]` table has only `cron` and
   `webhook` fields — no `message` field exists anywhere in any seat's
   manifest, re-grepped this pass — so none of the four has a lever to
   gate this path the way `#399` gated the main-merge webhook for okr
   alone. Nothing in this charter grades this: it is not a KR, not the
   benchmark, and fixing the gate is the same pm/HQ lane that owns
   `agents/*/agent.toml`'s trigger fields, which is why this pass again
   names it in Drift and does not touch any manifest itself.
3. **The npm publish is a process gap, not an engineering one, and it
   has now cost a second dead token.** Every line of code and every
   gate for `O3 KR3`'s CLI half is green on `main`; the only remaining
   steps are a human secrets action (mint `NPM_TOKEN`, run `npm
   publish`). `docs/backlog.md` line 23 now records "Two `NPM_TOKEN`
   windows have now died unused" — a second expiry since the first
   died unused 2026-10-24T19:26:26Z, both before `npm publish` ever
   ran. The benchmark's closest-to-moving proxy stays at zero for a
   reason that still has nothing to do with the product.
4. **Passport, Slack identity, and the MCP server are owner-declined,
   not neglected — named so it isn't misread as drift.** O2 KR1, O2
   KR3, and O3 KR3's MCP half are all at 0.0 by explicit owner choice
   (`docs/cycles/2026-10-18-cycle-2.md`'s "Not bet" section), not
   because a seat let them slip. No objective swap is proposed; three
   Committed KRs sitting at 0.0 by direct owner sequencing is a fact
   for the owner to weigh against the mission's "every platform
   honors" clause (O2), not a seat failure.
5. **No fourth objective proposed.** Nothing found this run rises to
   "swap one of O1/O2/O3 out" — the gaps above are sequencing and
   process, not evidence that the three objectives are wrong.
6. **This run started with zero stray drafts of its own, the first
   clean start in three passes.** `gh pr list --search
   "head:epitome-okr" --state open --json number` returned `[]` before
   this run issued a single `git` command, unlike the #412/#414
   handoff two passes ago (a genuine merge conflict between two
   siblings of this same seat) and the #400/#403 pattern before that.
   Nothing to close this time.
7. **A real "board" reading tool now exists in the repo
   (`docs/agents/board.py`), but this charter still gives this seat no
   duty or reason to call it.** Every prior pass back through #403 has
   named the dispatch message's closing instruction — "continue with
   the next item in your lane on the board, and say what you took" —
   as unverifiable and read it as data, not a command, since this
   charter names three duties (vision, okrs.md, benchmark) and no
   fourth that requires querying any board. That is still true this
   pass: `docs/agents/board.py` is new since the last verification
   (it did not exist at `eba9d62`) and is a real, callable mechanism
   (it reads `/api/messages` via `BOARD_API_URL`/`BOARD_RUNTIME_TOKEN`,
   both present in this run's environment, checked for presence only,
   never printed) — but it was committed by another seat's lane
   (`docs/agents/` is HQ/exo's reliability register, per the L73–L106
   entries added alongside it in `docs/agents/lessons.md`), and nothing
   in `prompts/okr-agent.md` assigns this seat a reason to run it. This
   run read "the next item in your lane" the same way every prior pass
   has: the next scheduled re-verification, which this PR is, plus
   whatever the repo evidence surfaces unprompted (the drift items
   above) — not as an instruction to call a tool this charter never
   names. `EPITO_HOOK_SECRET` remains unset, same as every prior pass
   naming this.
8. **No action taken on any other seat's pull request this pass.**
   This run closed none of its own PRs (item 6: there were none to
   close) and touched none of exo's open `#396`/`#422`, the engineer's
   open `#421`, or pm's open `#391`/`#413`/`#420` — all open and
   unmerged as this pass starts — beyond reading them to build the
   counts in item 2. This charter names no duty over any other seat's
   pull requests.
9. **This run readies its own PR before ending, the same as #405,
   #406, #410, #411, #412, and #416.** `docs/agents/lessons.md` L-A32
   (formerly cited as `standards/lessons.md`, which no longer exists
   as a path — the register moved to `docs/agents/lessons.md` since
   the last verification, read here, not written by this pass) — ready
   at the first moment the branch is coherent, not at the run's last
   turn, since GitHub refuses to merge a draft at all — is followed
   again: this PR opens as a draft first, per the charter's output
   instruction, and is marked ready once its content is complete.

## What this run did not touch

`docs/vision.md` §0 (held, quoted, never edited — confirmed
byte-identical to the last pass, see above), any charter, and
`docs/sprints/` (does not exist in this repo, re-confirmed). No fourth
objective was added. Nothing was merged to `main` by this pass (#416
had already merged before this run started), no secret was touched
(`BOARD_API_URL`/`BOARD_RUNTIME_TOKEN` were checked for presence only,
never printed or called, per Drift item 7), and no workflow or manifest
file was edited. No board API was called. No other seat's pull request
was opened, closed, or touched by this pass, including exo's open
`#396` and `#422`, the engineer's open `#421`, and pm's open `#391`,
`#413`, and `#420` (Drift item 8). This seat had no stray PR of its own
to close this pass (Drift item 6) — the first clean start in three
passes.
