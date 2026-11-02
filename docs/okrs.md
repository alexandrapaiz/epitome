# OKRs — Q4 2026 (Oct–Dec)

Maintained by the OKR seat (`prompts/okr-agent.md`). Objectives and KR
text are carried unedited from the 2026-09-20 all-hands counsel
(`docs/allhands/2026-09-20-okr.md` §2), ratified against the mission
below. First landed on `main` 2026-10-27 (`ef3aa8f`), after two prior
attempts (#35, #39) were closed and a third (#53) closed as a
duplicate — see that commit for the full history. Re-verified
independently seven times since, each against the then-current tip:
#372 and #373 (closed, superseded), #377, #381, #383, #386, and #389
(merged); no grade has moved across any of them.

This is the eighth re-verification, against today's tip `cab3071`.
`git diff 3873f6e..cab3071 --stat` touches four files since #389's
own tip: `docs/okrs.md` (that seventh pass's own edit, already
landed), `docs/backlog.md`, `cli/test/smoke-temporal.sh`, and
`cli/test/smoke-validate.sh` — the latter three all one PR (#384,
engineer seat), converting two more test suites' failure output to
name what they looked at (haystack-reader work, same shape as #369).
None of it touches `cli/src/`, `.github/workflows/`, `docs/cycles/`,
`docs/users.md`, `docs/pitches/`, or `docs/benchmark/` — no path this
file's own evidence depends on. Every fact below was re-checked
directly against `cab3071` anyway, per this charter's "never invent
evidence" rule, rather than assumed unchanged because the diff missed
every KR-cited path: `cli/package.json` still has `"private": true`,
every seat workflow in `.github/workflows/` still authenticates with
the shared `${{ github.token }}`, `docs/benchmark/` and
`docs/users.md` still don't exist, no `passport` match exists outside
`docs/`, `docs/cycles/` has no file newer than
`2026-10-18-cycle-2.md`, all three dogfood-migration checkboxes
(`docs/backlog.md` lines 1352/1373/1375) are still unchecked, and a
fresh probe of `registry.npmjs.org/epito-cli` just now still returns
404. `deploy.js` (494 lines), `token.js` (115 lines), and
`identity.js` (435 lines) were recounted directly and match every
prior pass. `cli/src/lib/slack.js` is still 66 lines, no second
platform.

A note on this run's own dispatch, since the charter asks evidence be
checked rather than assumed: this run's wake carried a standing note
(`GET /api/standing`) naming #389 as a stuck open draft needing to be
readied, closed, or explained. Checked directly against GitHub rather
than acted on from the note — `gh pr view 389` shows it `MERGED`, not
draft, at `2026-11-02T02:35:33Z`. The note was already stale by the
time this run read it: #389 had been readied and merged between the
note being written and this run's first tool call. No draft action
was needed or taken this pass.

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
  finding has now been reported unchanged at least eight times: first
  in #53 (2026-10-05), again at the `ef3aa8f` landing (2026-10-27),
  again in #372, #373, #377, #381, and #383, and again at this pass;
  see Drift below.
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
2. **Weeks of commits, zero KR evidence moved by them.** Since #39's
   close (2026-10-18) through today's tip (`ebf9382`, 2026-11-02), the
   large majority of commit volume on `main` is internal process
   engineering under the exo/pm/engineer seats — incident filings,
   `loop.md` ticks, charter patches, drift instruments
   (`docs/agents/*.sh`, `docs/agents/L*` lessons,
   `docs/agents/incidents.md`, `docs/standards/lessons.md`) and test-
   gate repairs (`cli/test/smoke-doctor.sh`, #369). The two commits
   landed just this pass (#380, #382) are more of the same shape:
   new incident register entries, two new `docs/agents/*.sh` probes,
   and a `cli/test/smoke-temporal.sh` assertion that the board
   receives a run report. None of it is a wrong thing to build; a
   company running on autonomous seats needs instruments for its own
   cadence. But no KR above has moved since the cycle 2 engineering
   (the npm rename, the publish gates) landed before #39 closed. Worth
   naming so the owner can judge whether seat-governance work is
   crowding out wedge work, or is a one-time cost that's now paid.
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
6. **No stray drafts from this seat, reconfirmed.** #372 and #373 are
   closed (superseded, see #377/#383's own history); #377, #381, #383,
   #386, and #389 are merged. `gh pr list --search head:epitome-okr
   --state all` just now shows exactly that and nothing else open.
   Nothing to act on. (This pass's wake also carried a standing note
   claiming #389 was a stuck open draft; checked directly and found
   already merged — see the header above. The note was stale, not
   wrong about the rule it cited.)
7. **This seat has now opened eight re-verification PRs in about
   24 hours (#372, #373, #377, #381, #383, #386, #389, and this one),
   confirming the same grades each time with no new product evidence,
   and the recommendation this drift item made last pass has not
   changed anything yet.** #389 itself named this exact problem and
   proposed a concrete fix (gate the dispatch on a KR-cited path, or
   run this seat on the schedule its own charter already names); this
   run was dispatched by #389's own merge, and the only product-side
   change since the tip #389 verified is #384 (engineer, pure
   test-instrument work, zero KR evidence) — exactly the kind of
   commit the proposed path filter would have skipped, had it existed.
   `.github/workflows/agent-okr.yml` still dispatches on every merge to
   `main` with no path filter, and this seat has no standing to edit
   that file. Naming the fix a second time changes nothing the first
   naming didn't already say; repeating it a ninth time would be the
   same idle-looking motion Drift item 2 and this item both already
   describe. The ask for the owner is unchanged but now evidenced
   twice: gate `agent-okr.yml`'s dispatch, or convene this seat
   manually on the charter's own "monthly, and on dispatch when the
   owner convenes you" cadence. This remains a proposed change to the
   dispatch mechanism, not to the mission or the benchmark, and this
   seat still has no path to make it itself.

## What this run did not touch

`docs/vision.md` §0 (held, quoted, never edited), any charter, and
`docs/sprints/` (does not exist in this repo). No fourth objective was
added. Nothing was merged to `main`, no secret was touched, and no
workflow file was edited — Drift item 7's recommendation is a
proposal, not an action this pass took. No PR was closed or readied
this pass; #389 needed no action, having already merged before this
run looked (see the header above and Drift item 6).
