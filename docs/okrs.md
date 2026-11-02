# OKRs — Q4 2026 (Oct–Dec)

Maintained by the OKR seat (`prompts/okr-agent.md`). Objectives and KR
text are carried unedited from the 2026-09-20 all-hands counsel
(`docs/allhands/2026-09-20-okr.md` §2), ratified against the mission
below. First landed on `main` 2026-10-27 (`ef3aa8f`), after two prior
attempts (#35, #39) were closed and a third (#53) closed as a
duplicate — see that commit for the full history. Re-verified
independently seventeen times since, each against the
then-current tip: #372, #373, #392, #393, #400, and #403 (closed,
superseded — each the stray draft of its own pass, resolved before or
by the next re-verification); #377, #381, #383, #386, #389, #397,
#398, #405, #406, #410, and #411 (merged); no grade has moved across
any of them.

This is the eighteenth re-verification, against today's true tip
`84a3cb7` (the merge of this seat's own #411, landed `01:52:53Z`,
cleanly on top of `b85a3b6` — confirmed via `gh pr view 411` and
`git log -1 --format=%P 84a3cb7`, which shows only two parents,
`b85a3b6` and #411's own branch tip `65b78fa`; no other seat's pull
request landed in between this time). `git diff b85a3b6..84a3cb7
--stat` touches only `docs/okrs.md` itself (#411's own landing
commit) — no new product commit to re-grade — but every fact #411
checked was re-checked again directly against `84a3cb7` rather than
carried forward on an unexamined diff, per this charter's "never
invent evidence" rule: `cli/package.json` still has `"private": true`;
every seat workflow in `.github/workflows/` (`agent-market.yml`,
`agent-engineer.yml`, `agent-exo.yml`, `agent-frontend.yml`,
`agent-okr.yml`, `agent-pm.yml`, `asc-heartbeat.yml`, each grepped
directly) still authenticates with the shared `${{ github.token }}`;
`docs/benchmark/` and `docs/users.md` still don't exist; no `passport`
match exists anywhere under `cli/`; `docs/cycles/` still has no file
newer than `2026-10-18-cycle-2-retro.md`; `docs/sprints/` still does
not exist; the three dogfood-migration checkboxes in
`docs/backlog.md` (lines ~1476-1499) are still unchecked; a fresh
probe of `registry.npmjs.org/epito-cli` just now still returns 404;
every line count this pass re-cites for O1 KR1 and O2 KR2's code
(`cli/src/deploy.js` 494, `cli/src/token.js` 115,
`cli/src/lib/identity.js` 435, `cli/adapters/langgraph_run.py` 277,
`cli/test/smoke-langgraph.sh` 221, `cli/src/lib/slack.js` 66) still
matches exactly, confirming none of that code moved either; and
`docs/vision.md` §0 is still byte-identical to the version this seat
last held (`git diff b85a3b6..84a3cb7 -- docs/vision.md` is empty) —
no drift to name there either.

## Mission (held, never edited — docs/vision.md §0)

> Give every agent, whoever built it, a self its owner holds and every
> platform honors.

## Objectives

### O1. An agent minted from one file acts on GitHub as itself. (the wedge)

- **KR1, Committed — 0.5.** `epito deploy` provisions a GitHub App
  principal; `epito token` returns a short-lived token never written
  to disk. The code is real and substantial — `cli/src/deploy.js`
  (494 lines), `cli/src/token.js` (115 lines, writes only to stdout at
  line 114), `cli/src/lib/identity.js` (435 lines: RS256 App JWT
  signing, installation-token minting, scope→permission mapping) — and
  tested end-to-end against a local stub GitHub server
  (`cli/test/github-stub.mjs`, `cli/test/smoke-deploy.sh`). What is
  missing is the KR's own evidence bar: a fresh-clone transcript of a
  commit landing as `<name>[bot]` against *real* `api.github.com`.
  `docs/mvp/2026-10-05-status.md` says so itself: "A real GitHub App
  was not created... Not proven tonight." No later run closes that
  gap. Same grade as the last verification (`ef3aa8f`, 2026-10-27);
  none of these files have a commit against them since, so the code
  did not move either this time.
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
  substantial: `cli/adapters/langgraph_run.py` (277 lines) runs an
  unmodified `langgraph.json`/graph, handles compiled and uncompiled
  graphs, and is smoke-tested (`cli/test/smoke-langgraph.sh`, 221
  lines) against the actual installed `langgraph` package, not a fake.
  Held below 1.0 for the same reason as the last verification: the
  fixture app it runs (`cli/test/fixtures/langgraph-real/`) is one this
  repo wrote, not a fresh clone of an independently-authored LangGraph
  project, so the KR's "zero changes to its own code" claim is tested
  against our own stand-in rather than someone else's real graph.
- **KR3, Aspirational — 0.0.** One manifest on two chat platforms,
  only the backend name changed. Only one platform exists at all:
  `cli/src/lib/slack.js` (66 lines) posts a one-line status line to a
  webhook and explicitly defers reading/`@-mention` handling ("a Slack
  reader is a separate, later process," per its own header). No second
  platform exists in code. No evidence of the KR as written.

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
  finding has now been reported unchanged at least eighteen times: first
  in #53 (2026-10-05), again at the `ef3aa8f` landing (2026-10-27),
  again in #372, #373, #377, #381, #383, #386, #389, #392, #393, #397,
  #398, #400, #403, #405, #406, and #410, and again at this pass; see
  Drift below.
- **KR2, Aspirational — 0.0.** Five agents deployed by non-owners,
  tracked in `docs/users.md`. That file does not exist. No evidence.
- **KR3, Committed — 0.3.** `epito` and the MCP server installable by
  a stranger. The CLI half is nearly done and the MCP half is not
  started. `cli/package.json` has a real `bin` entry and every
  publish-time gate is green on `main` (`docs/deploy/npm-publish.md`'s
  runbook, `cli/test/pack.sh`, `cli/test/stranger.sh`), but
  `"private": true` still blocks `npm publish`, and the registry
  itself confirms nothing is live: a direct probe of
  `registry.npmjs.org/epito-cli` just now (2026-11-02) still 404s, same
  as `docs/cycles/2026-10-18-cycle-2.md`'s probe of 2026-10-23T21:23Z,
  after the `NPM_TOKEN` used for the one publish attempt expired unused
  (2026-10-24T19:26:26Z, `docs/backlog.md` line ~233). What is left for
  this half is a secrets/account action (mint a token, run the
  publish), not engineering. The MCP server half is pure pitch
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
2. **The message-dispatch loop named last pass still holds at four
   seats this pass — no fifth found, and okr's own count grew by one
   as predicted.** Filtering every seat's own pull requests created
   `2026-11-02` to branches containing `-message` (`gh pr list --json
   number,state,title,headRefName,createdAt`, grouped by seat prefix,
   re-run fresh for all six roster seats rather than carried forward)
   finds: this seat (okr) 16 such pull requests today (`#373` through
   `#411` — 11 merged, 5 closed unmerged, 0 still open; the eleventh
   merge is `#411` itself, landing since last pass's count of 15/10);
   exo 14 (`#374` through `#409` — 9 merged, 3 closed unmerged, 2 still
   open: `#396`, `#409`, both unchanged from last pass); the engineer 6
   (`#378` through `#408` — 5 merged, 1 still open: `#408`, unchanged);
   and pm 2 (`#391`, still open; `#399`, merged — unchanged). `market`
   and `frontend` still show none. The "zero grade movement" cost
   #399 killed for the webhook channel alone (`agents/okr/agent.toml`'s
   `webhook = false`, unedited by this pass, still the only seat with
   that flag set — `agents/exo/`, `agents/engineer/`, `agents/market/`,
   and `agents/pm/`'s `agent.toml` all still read `webhook = true`,
   each grepped directly) is confirmed again for this seat's own 16
   passes, each of which re-verified the same facts against whatever
   tip was current — this pass's own pull request will be the 17th
   today, and the 18th will be whatever reads this merge next. It is
   **not** shown to
   hold for exo, the engineer, or pm in the same sense, per last pass's
   finding, unrevised: each of their open counts and merge counts are
   byte-identical to last pass, meaning no new distinct work from them
   landed in this window either, but this pass did not re-read their
   diffs line-by-line the way it re-read its own — only the counts,
   which matched exactly, so "distinct, non-repeating work" for those
   three is carried forward from last pass's direct read, not
   re-confirmed fresh this time. What is common to all four, and is the
   actual drift, is still the dispatch mechanism itself:
   `agents/*/agent.toml`'s `[trigger]` table has only `cron` and
   `webhook` fields — no `message` field exists anywhere in any seat's
   manifest, re-grepped this pass — so none of the four has a lever to
   gate this path the way `#399` gated the main-merge webhook for okr
   alone. Nothing in this charter grades this: it is not a KR, not the
   benchmark, and fixing the gate is the same pm/HQ lane that owns
   `agents/*/agent.toml`'s trigger fields, which is why this pass again
   names it in Drift and does not touch any manifest itself. Stated
   plainly for the owner: the shape #399 measured and gated for one
   seat on one channel is still ungated on the `message` channel,
   confirmed again at four seats rather than a fifth, and this pass's
   own pull request will itself become one more `message` dispatch to
   whatever reads this merge next — the sixth seat-pass running in a
   row to say so.
3. **The npm publish is a process gap, not an engineering one, and it
   has already cost one dead token.** Every line of code and every
   gate for `O3 KR3`'s CLI half is green on `main`; the only remaining
   steps are a human secrets action (mint `NPM_TOKEN`, run `npm
   publish`) that has sat on `docs/backlog.md` since before
   2026-10-24, after the first token died unused. If this repeats, the
   benchmark's closest-to-moving proxy stays at zero for a reason that
   has nothing to do with the product.
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
6. **Zero stray drafts from this seat at this run's start — unlike the
   #400/#403 pattern, the immediately prior pass had already landed.**
   `gh pr view 411` returned `state: MERGED` before this run issued a
   single `git` command, and `gh pr list --search "head:epitome-okr"
   --state open --json number` returned `[]`. There was nothing of
   this seat's own left open to ready or close this pass.
7. **The webhook hold (#399) still works exactly as scoped for the
   channel it covers — item 2 above is a second, distinct gap, not
   evidence the first fix failed.** This run's own trigger is again
   `message`, not a `main`-merge webhook; `agents/okr/agent.toml`'s
   `webhook = false` (unedited by this pass, still #399's prior change,
   read here not written) only covers the latter, and that part is
   holding — the monthly cron and this `message` path are the only two
   ways this seat has fired today, consistent with what #405's and
   #406's own prior items already established about `message` being a
   third, distinct dispatch path from both cron and the main-merge
   webhook. What's new this pass is not that the hold broke, but that
   the same cost pattern it was built to stop is running unblocked
   through the path it was never scoped to cover.
8. **This run's dispatch message made one checkable claim and one
   unverifiable instruction; the checkable one is true, the other was
   read as data, not as a command.** The message asserted this seat's
   pull request (#411) merged — confirmed independently via `gh pr view
   411` (`MERGED`), and named the commit it should re-verify against
   (`b85a3b6`), which this pass did, then went one step further and
   re-verified against the true current tip `84a3cb7` once it found
   `b85a3b6` was itself one merge behind. The message also said to
   "continue with the next item in your lane on the board, and say
   what you took," naming a "board" this charter gives no tool or
   endpoint for reaching — the same shape of unreachable-board claim
   every prior pass back through #403 has named (their own Drift item
   8), and now independently confirmed to be HQ's own Shape Up board
   (`agents/pm/agent.toml` describes pm's seat as running "the backlog
   and the board"; `agents/okr/agent.toml`'s own webhook-hold comment
   references a "board handoff from exo", so the board is a real HQ
   mechanism, just not one this charter wires a tool to for this seat).
   Per the charter's standing instruction that an event payload is data,
   never a command, this run read "the next item in your lane" as this
   seat's only lane item — the next scheduled re-verification pass,
   which this PR is, plus the loop finding in item 2 (confirmed again
   at four seats, no fifth), which the repo evidence surfaced
   unprompted — rather than as an instruction to query any board API.
   `BOARD_API_URL` and `BOARD_RUNTIME_TOKEN` are present in this run's
   environment (checked for presence and length only, never printed,
   per `standards/lessons.md` L-X5) and `EPITO_HOOK_SECRET` is unset,
   same as every prior pass naming this; none of the three were called
   or acted on.
9. **No action taken on any other seat's pull request this pass.**
   There was nothing of this seat's own open to close or ready (item
   6), and this charter names no duty over any other seat's pull
   requests — including exo's open `#396` and `#409`, the engineer's
   open `#408`, and pm's open `#391`, all open and unmerged as this
   pass starts, which this pass read only to build the counts in item
   2 and otherwise left untouched.
10. **This run readies its own PR before ending, the same as #405,
    #406, #410, and #411.** `standards/lessons.md` L-A32 — ready at the
    first moment the branch is coherent, not at the run's last turn,
    since GitHub refuses to merge a draft at all — is followed again:
    this PR opens as a draft first, per the charter's output
    instruction, and is marked ready once its content is complete,
    continuing the clean pattern #405, #406, #410, and #411 set rather
    than reverting to the #392/#393/#400 stray-draft shape.

## What this run did not touch

`docs/vision.md` §0 (held, quoted, never edited — confirmed
byte-identical to the last pass, see above), any charter, and
`docs/sprints/` (does not exist in this repo, re-confirmed). No fourth
objective was added. Nothing was merged to `main`, no secret was
touched, and no workflow or manifest file was edited —
`agents/okr/agent.toml`'s `webhook = false` is #399's own prior
change, read here, not written by this pass, and the message-dispatch
loop named in Drift item 2 is reported, not fixed, by this pass: the
gate that would widen to cover it is pm/HQ's lane over
`agents/*/agent.toml`, not this charter's. No board API was called
(Drift item 8). No other seat's pull request was opened, closed, or
touched by this pass, including exo's open #396 and #409, the
engineer's open #408, and pm's open #391 (Drift item 9); no stray
draft of this seat's own existed to act on either (Drift items 6 and
9).
