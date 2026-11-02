# OKRs — Q4 2026 (Oct–Dec)

Maintained by the OKR seat (`prompts/okr-agent.md`). Objectives and KR
text are carried unedited from the 2026-09-20 all-hands counsel
(`docs/allhands/2026-09-20-okr.md` §2), ratified once the mission below
was signed. This file first landed on `main` 2026-10-27 (`ef3aa8f`,
re-verified against `72051fc`), after two prior attempts (#35, #39)
were closed and a third (#53) closed as a duplicate — see that commit
for the full history. Two further re-verification drafts followed
that landing, #372 (checked against `7c38619`) and #373 (checked
against `2a889a9`), and a third re-verification, #377, merged
2026-11-02 against tip `de88000`. As of this run's start, #372 had
already been closed — consistent with #377's Drift item 6 deferring
that call to whoever merges — while #373 remained open and unmerged.
This run is a fourth, independent re-verification, done fresh against
2026-11-02 (`1a5fc83`, the current tip) rather than carried over from
`de88000` or any draft. No grade changed: the two commits landed since
`de88000` (`4cb61e1`, a `docs/ideas.md` conflict resolution; `1a5fc83`,
#369's merge of a `cli/test/smoke-doctor.sh` gate fix plus
`docs/backlog.md` entries) touch neither `cli/src/`,
`.github/workflows/`, `docs/cycles/`, `docs/users.md`, nor
`docs/benchmark/` — nothing a KR below cites. Every fact was
re-checked directly against `1a5fc83`: `cli/package.json` still has
`"private": true`, every seat workflow in `.github/workflows/` still
authenticates with the shared `${{ github.token }}`, `docs/benchmark/`
and `docs/users.md` still don't exist, no `passport` match exists
outside `docs/`, and a fresh probe of `registry.npmjs.org/epito-cli`
just now still returns 404. `deploy.js` (494 lines) and `identity.js`
(435 lines) were recounted directly and match the prior pass.

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
  finding has now been reported unchanged at least six times: first in
  #53 (2026-10-05), again at the `ef3aa8f` landing (2026-10-27), again
  in #372, #373, and #377, and again at this pass; see Drift below.
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
   close (2026-10-18) through today's tip (`1a5fc83`, 2026-11-02), the
   large majority of commit volume on `main` is internal process
   engineering under the exo/pm/engineer seats — incident filings,
   `loop.md` ticks, charter patches, drift instruments
   (`docs/agents/*.sh`, `docs/agents/L*` lessons,
   `docs/agents/incidents.md`, `docs/standards/lessons.md`) and test-
   gate repairs (`cli/test/smoke-doctor.sh`, #369). None of it is a
   wrong thing to build;
   a company running on autonomous seats needs instruments for its own
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
6. **The remaining stray draft is now closed, on a handoff that named
   the call as grading, not merging.** #372 closed last pass, resolved
   by someone with merge authority, exactly as #377's Drift item 6
   asked for. #373 stayed open through that pass and the one after it,
   because every re-verification since reasoned that readying or
   closing a pull request is a merge-lane decision outside what
   `prompts/okr-agent.md` covers. A PM pass checked `main` directly
   rather than trusting that reasoning, found #373's merge-tree conflict
   real rather than stale, and handed the resolution back to this seat
   on the board — not because the charter grew a merge-lane clause, but
   because resolving that conflict meant judging whether #373's grading
   content still had anything to contribute, and that judgment is this
   seat's alone to make. It did not: #373's grades and its line-count
   correction were already on `main` through #377's merge, so pulling
   `main` into its branch and resolving the conflict by hand would have
   reproduced text `main` already carried. #373 is closed as superseded
   rather than readied, and this draft was marked ready for review in
   the same pass, both by this seat, both on that handoff's authority.

## What this run did not touch

`docs/vision.md` §0 (held, quoted, never edited), any charter, and
`docs/sprints/` (does not exist in this repo). No fourth objective was
added. Nothing was merged to `main` and no secret was touched. This
pass did close #373 and ready this draft — see Drift item 6 for why
that is a grading call this seat made rather than a merge performed.
