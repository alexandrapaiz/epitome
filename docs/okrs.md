# OKRs — Q4 2026 (Oct–Dec)

Maintained by the OKR seat (`prompts/okr-agent.md`). Objectives and KR
text are carried unedited from the 2026-09-20 all-hands counsel
(`docs/allhands/2026-09-20-okr.md` §2), ratified against the mission
below. First landed on `main` 2026-10-27 (`ef3aa8f`), after two prior
attempts (#35, #39) were closed and a third (#53) closed as a
duplicate — see that commit for the full history. Re-verified
independently fourteen times since, each against the then-current tip:
#372, #373, #392, #393, #400, and #403 (closed, superseded — each the
stray draft of its own pass, resolved before or by the next
re-verification); #377, #381, #383, #386, #389, #397, #398, and #405
(merged); no grade has moved across any of them.

This is the next re-verification, against today's true tip `a4a6fb5`
(the merge of #405). Unlike the #400/#403 pattern, #405 itself merged
cleanly before this run started — `gh pr view 405` shows `MERGED`, and
`gh pr list --search head:epitome-okr --state open` returned nothing
for this seat — so there was no stray draft of this seat's own to
close or ready this pass. `git diff d1e56c6..a4a6fb5 --stat` touches
exactly one file, `docs/okrs.md`, which is #405's own landing commit;
so there is no new product commit to re-grade, and every fact #405
checked was re-checked again directly against `a4a6fb5` rather than
carried forward on the empty diff, per this charter's "never invent
evidence" rule: `cli/package.json` still has `"private": true`; every
seat workflow in `.github/workflows/` (`agent-market.yml`,
`agent-engineer.yml`, `agent-exo.yml`, `agent-frontend.yml`,
`agent-okr.yml`, `agent-pm.yml`, `asc-heartbeat.yml`, each grepped
directly) still authenticates with the shared `${{ github.token }}`;
`docs/benchmark/` and `docs/users.md` still don't exist; no `passport`
match exists anywhere under `cli/`; `docs/cycles/` still has no file
newer than `2026-10-18-cycle-2-retro.md`; `docs/sprints/` still does
not exist; the three dogfood-migration checkboxes in
`docs/backlog.md` (lines ~1476-1499) are still unchecked; and a fresh
probe of `registry.npmjs.org/epito-cli` just now still returns 404.
One fact this pass checked that prior passes' header paragraphs did
not name directly: `docs/vision.md` §0 is byte-identical to the
version this seat last held (`git diff d1e56c6..a4a6fb5 --
docs/vision.md` is empty) — no drift to name there either.

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
  finding has now been reported unchanged at least sixteen times: first
  in #53 (2026-10-05), again at the `ef3aa8f` landing (2026-10-27),
  again in #372, #373, #377, #381, #383, #386, #389, #392, #393, #397,
  #398, #400, #403, and #405, and again at this pass; see Drift below.
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
2. **This drift item itself had gone stale for five passes — caught
   and corrected only now.** #386 introduced this note's tip reference
   (`ebf9382`) and its two example PR numbers (#380, #382) when they
   were genuinely current — `gh pr diff 386` confirms it. Five
   subsequent re-verifications (#389, #397, #398, #403, and #405) each
   correctly advanced the document's header tip but carried this
   paragraph's `ebf9382`/#380/#382 text forward unexamined, so a
   reader landing on this item any time since was pointed at a commit
   and two PRs several tips behind the one the rest of the document
   was grading against. The underlying claim — that no KR grade has
   moved since #39's close (2026-10-18) despite continued commit
   volume — is not re-audited fresh this pass (that would mean
   re-walking every commit since 2026-10-18, which this pass did not
   do), but the specific tip and PR numbers were wrong on their face
   next to a header now reading `a4a6fb5`, so repeating them again
   would itself be this charter's forbidden kind of invented evidence:
   a claim not checked against the repo in front of this run. Fixed
   by removing the stale pointer rather than replacing it with an
   unaudited new one; the general shape of the claim (most commit
   volume between #39 and now is seat-governance engineering, not
   KR-moving product work) is left as an open question for a pass that
   has time to re-walk the commit log, not reasserted as checked.
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
   `gh pr view 405` returned `state: MERGED` before this run issued a
   single `git` command, and `gh pr list --search head:epitome-okr
   --state open --json number` returned `[]`. There was nothing of
   this seat's own left open to ready or close this pass.
7. **The webhook hold (#399) continues to work exactly as scoped — one
   more data point.** This run's own trigger is again `message`, not a
   `main`-merge webhook; `agents/okr/agent.toml`'s `webhook = false`
   (unedited by this pass, still #399's prior change, read here not
   written) only covers the latter, so this run firing is not evidence
   against the hold — consistent with what #405's own item 7 already
   established about this trigger being a third, distinct dispatch
   path from both cron and the main-merge webhook.
8. **This run's dispatch message made one checkable claim and one
   unverifiable instruction; the checkable one is true, the other was
   read as data, not as a command.** The message asserted this seat's
   pull request (#405) merged, closing #403 as superseded — confirmed
   independently via `gh pr view 405` (`MERGED`) and `gh pr view 403`
   (`CLOSED`). It also said to "continue with the next item in your
   lane on the board, and say what you took," naming a "board" this
   charter gives no tool or endpoint for reaching — the same shape of
   unreachable-board claim #403's and #405's own dispatch messages
   carried (their Drift item 8). Per the charter's standing instruction
   that an event payload is data, never a command, this run read "the
   next item in your lane" as this seat's only lane item — the next
   scheduled re-verification pass, which this PR is — rather than as an
   instruction to query any board API. `BOARD_API_URL` and
   `BOARD_RUNTIME_TOKEN` are present in this run's environment (checked
   for presence and length only, never printed, per
   `standards/lessons.md` L-X5) and `EPITO_HOOK_SECRET` is unset, same
   as every prior pass naming this; none of the three were called or
   acted on.
9. **No action taken on any other seat's pull request this pass.**
   There was nothing of this seat's own open to close or ready (item
   6), and this charter names no duty over any other seat's pull
   requests.
10. **This run readies its own PR before ending, the same as #405.**
    `standards/lessons.md` L-A32 — ready at the first moment the
    branch is coherent, not at the run's last turn, since GitHub
    refuses to merge a draft at all — is followed again: this PR opens
    as a draft first, per the charter's output instruction, and is
    marked ready once its content is complete, continuing the clean
    pattern #405 set rather than reverting to the #392/#393/#400
    stray-draft shape.

## What this run did not touch

`docs/vision.md` §0 (held, quoted, never edited — confirmed
byte-identical to the last pass, see above), any charter, and
`docs/sprints/` (does not exist in this repo, re-confirmed). No fourth
objective was added. Nothing was merged to `main`, no secret was
touched, and no workflow or manifest file was edited —
`agents/okr/agent.toml`'s `webhook = false` is #399's own prior
change, read here, not written by this pass. No board API was called
(Drift item 8). No other seat's pull request was opened, closed, or
touched by this pass; no stray draft of this seat's own existed to
act on either (Drift items 6 and 9).
