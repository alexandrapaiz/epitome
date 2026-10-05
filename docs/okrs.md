# OKRs

Held by the OKR seat. Graded only from repo evidence — never from
claims, intent, or in-flight work. A KR with no evidence is 0.0 with
"no evidence" written next to it, even if the work is underway.
Mission: docs/vision.md §0 (signed 2026-09-20, ADR-14). This seat holds
the mission; it never edits it.

First instantiation of this file: no prior docs/okrs.md existed in the
repo or its history. The three objectives below are the OKR seat's
2026-09-20 all-hands counsel (docs/allhands/2026-09-20-okr.md §2),
carried forward unedited now that Q4 has turned and the mission it was
conditioned on is signed. Graded here for the first time, 2026-10-05.

## O1. An agent minted from one file acts on GitHub as itself (the wedge)

- **KR1, Committed — 0.5.** `epito deploy` provisions a GitHub App
  principal, and `epito token` returns a short-lived token never
  written to disk.
  Evidence: `epito token` is real — `cli/src/token.js` +
  `cli/src/lib/identity.js` sign an RS256 App JWT, mint a scoped
  installation token, and append an audit line that records the mint
  and never the token; covered by unit tests (`cli/test/unit.mjs`,
  `github-stub.mjs`, `git-http-stub.mjs`) and used in production-shaped
  form by the LangGraph adapter (see O2 KR2). But `epito deploy` is
  still a stub (`cli/src/index.js:172`: `die("deploy is what the
  platform does, and the platform is in progress...")`) — the
  App-creation half of this KR does not exist; `loadPrincipal` reads a
  principal that something else put on disk, it never mints one.
  `identity.js`'s own comment calls the App-per-agent-vs-shared-App
  choice ("EPI-4") still open. No fresh-clone transcript of a real
  (non-stubbed) commit landing as `<name>[bot]` exists in the repo.
  Reason below 1.0: owner re-bet cycle 1 to the resident runtime first
  (`docs/cycles/2026-09-21-cycle-1-amendment.md`); the token-minting
  slice landed after that, the App-provisioning slice (deploy's step 1)
  never got engineer time this cycle.

- **KR2, Committed — 0.0, no evidence.** One alexandria seat runs on
  epito.me and its ADR-27 hand-wiring is deleted.
  Evidence: `docs/backlog.md` "Dogfood migration" steps 1-3 are all
  still unchecked. No merged alexandria PR referencing this is named
  anywhere in the repo.
  Reason: never started this cycle; the amendment re-bet engineer time
  to the resident runtime and then to the Temporal rewrite instead.

- **KR3, Aspirational — 0.0, no evidence.** Fresh clone to first
  commit-as-bot in under 15 minutes, evidence a timed run log under
  `docs/benchmark/`.
  Evidence: `docs/benchmark/` does not exist. Aspirational KRs are
  healthy at 0.7; this one has never been attempted, timed, or logged,
  even though `epito token` (KR1) now makes the run timeable.

## O2. One self crosses walls, demonstrated, not claimed (the moat)

- **KR1, Committed — 0.0, no evidence.** The passport prototype: a
  third party, given only the agent-card URL, verifies that a GitHub
  `[bot]` and a Slack bot user are one agent.
  Evidence: exists only as prose — `docs/design/portability-proposals.md`
  Proposal B. No signed card, no verify script, no code anywhere in
  the repo named card/passport/verify.
  Reason: not bet in cycle 1 (identity work this cycle was the
  token-minting slice only, per the amendment); the passport is
  explicitly cycle-2 scope per the all-hands counsel's recommendation 2.

- **KR2, Committed — 0.6.** One agent epito did not write (LangGraph,
  n8n, or OpenClaw) acts on GitHub as its own `[bot]` through `epito
  token` with zero changes to its own code.
  Evidence: real and substantial. `cli/adapters/langgraph_run.py` is a
  standard-library-only shim that runs a LangGraph app's own unmodified
  `langgraph.json`/graph and receives, per its own header comment, "the
  run's own credentials (GH_TOKEN/GITHUB_TOKEN, minted for this run)" —
  i.e. wired to the KR1 mint path. `cli/test/smoke-langgraph.sh`
  explicitly proves the app runs "UNMODIFIED — its own langgraph.json,
  its own graph, no epito import anywhere in it," against the real
  framework when installed (ADR-17, ADR-18). What's missing is the
  KR's named evidence bar — "a transcript in a fresh clone" against
  real GitHub, not a local smoke fixture.
  Reason below 1.0: the mechanism and the test coverage exist; the
  fresh-clone, real-GitHub transcript does not.

- **KR3, Aspirational — 0.0, no evidence.** The same manifest posts as
  itself on two chat platforms with only the backend name changed.
  Evidence: the only Slack integration in the repo is a webhook that
  posts run-report *notifications* (`.github/workflows/agent-*.yml`,
  "Post run report" step) — visibility for the owner, not an agent
  identity on Slack. There is no second chat platform at all.

## O3. Someone other than the owner runs an agent on it (demand, counted)

- **KR1, Committed — 0.0, no evidence.** Three Alexandra Systems HQ
  seats upgraded to real principals that can be @-mentioned.
  Evidence: none in this repo. A concrete counter-signal, not just an
  absence: this repo's own five seat workflows
  (`.github/workflows/agent-{okr,pm,exo,market,engineer}.yml`,
  including the one that ran this grading) still authenticate with the
  shared `GH_TOKEN: ${{ github.token }}` — a GitHub Actions token, not
  a minted per-agent principal. The identity slice this seat is
  grading is not yet dogfooded on the seats grading it.
  Reason: HQ's own upgrade was never scheduled this cycle; the
  resident-runtime amendment took the engineer seat's time instead.

- **KR2, Aspirational — 0.0, no evidence.** Five agents deployed by
  people who are not the owner, evidence a `docs/users.md` ledger.
  Evidence: `docs/users.md` does not exist.

- **KR3, Committed — 0.0, no evidence.** `epito` and the MCP server
  installable by a stranger, evidence a tagged npm release, an
  `npx`-runnable server, and the editor-skill smoke demo transcript.
  Evidence: no git tags in the repo; `cli/package.json` still reads
  `"version": "0.1.0"` with no publish record. No MCP server code
  exists beyond `docs/pitches/epito-mcp-server.md` — the cycle-1 hill
  chart for it reads "problem-side ▲ | CLI logic not yet factored for
  a second caller."
  Reason: explicitly deferred — the cycle-1 amendment states "Not bet
  this cycle: the MCP server (moves to cycle 2 unchanged; it was the
  sure bet, and the owner's pain is elsewhere)."

## Benchmark

The mission's measurable proxies. This seat maintains them; it never
proposes changing the mission, only the yardstick. Carried from the
2026-09-20 all-hands counsel, read fresh against today's repo:

1. **Minutes from `epito init` to first commit-as-bot.** No run log
   exists (`docs/benchmark/` absent) — still unmeasured. Unlike
   2026-09-20, the blocker is no longer "the mechanism doesn't exist":
   `epito token` works end-to-end now. Nothing but running the clock
   stands between this proxy and a real number.
2. **Count of agents minted by non-owners** (HQ seats do not count).
   0 — no `docs/users.md`, no external mint on record.
3. **Platforms one agent is verified on through its passport.** 0 — no
   passport code exists, only the proposal.
4. **Lines of ADR-27 plumbing deleted from alexandria.** 0 — the
   dogfood migration (O1 KR2) has not started.

All four proxies still read zero, same as the 2026-09-20 baseline,
despite real engineering landing elsewhere this cycle (the resident
runtime, the board, the router, OTel tracing, the LangGraph adapter).
No proposed change to the proxies themselves this run — they still
measure the right things; what moved is the *distance* to the first
one, not its reading.
