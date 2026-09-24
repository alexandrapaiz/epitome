# Cycle 1 amendment — owner re-bet, 2026-09-20 (day before open)

Owner: "there isn't anything to give agents a consistent runtime...
a consistent runtime that isn't just a cron. So we need to start
building because I need this product." Observed at HQ
(alexandra-systems): every seat is an Actions job — fresh VM per run,
cron or hand-dispatch only, no process between runs, nothing can
receive an event. The catalog names epito's deploy as its first
customer. The felt pain is the runtime leg; cycle 1 re-bets to it.

## Bets (amended)

**Bet 1 — epitod v0: the resident runtime, hosting one HQ seat.**
Big batch. `epito run <dir>` is a long-lived process that loads every
`agent.toml` in a directory and, per agent: fires its `[trigger].cron`
from an internal scheduler, exposes `POST /hooks/<name>` for events,
and on either trigger executes one run — a fresh worktree of the
seat's repo, the charter prompt, headless `claude -p` on the manifest's
model (ADR-8), draft PR opened as the run's identity, an audit line
appended. Ships as a Dockerfile plus a systemd unit so it runs on any
box (first target: one small cloud machine; the unit file makes a VPS
equally valid; ADR-6 forbids depending on either). Honors R4: the
first agent it runs is an HQ seat we already have, unmodified — BYO
agent from day one. Identity for v0 = the existing secrets the seat
uses today; the GitHub-App principal is bet 2's slice and plugs into
the same run path.
Done when: one HQ seat runs on a cloud machine from its manifest,
woken once by cron and once by a webhook, and each wake opens a
draft PR — with no Actions job involved.

**Bet 2 — deploy-identity-v0, reduced to the slice the runtime
consumes.** Small batch: `epito token <name>` minting a short-lived
installation token from a per-agent App key held as a secret on the
runtime box, injected into bet 1's run so the PR opens as
`<name>[bot]`. EPI-4's spike (App-per-agent vs shared) proceeds
inside it; both routes measured, owner rules on evidence (R2).

**Not bet this cycle:** the MCP server (moves to cycle 2 unchanged;
it was the sure bet, and the owner's pain is elsewhere).

Appetite unchanged: 2026-09-21 → 2026-10-02. Circuit breaker
unchanged. Betting delegated per the founding minutes; this
amendment is the owner's own re-bet, recorded by the chair.

## Hill update — 2026-09-20 evening (chair, from PR #4)

- **Bet 1, epitod v0**: `solution known, building ▼ | slice 1 shipped
  as PR #4 (+738/-48, zero new deps), smoke-tested with the real
  claude executor: cron fire, 401 on wrong secret, hook coalescing,
  clean shutdown` — next: slice 2, one HQ seat on a cloud machine.
  Unknowns to retire on the machine: headless auth via
  CLAUDE_CODE_OAUTH_TOKEN on Alpine, Dockerfile build, unit start.
- **Bet 2, identity slice**: `problem-side ▲ | not started; EPI-4 spike
  measures both App routes` — unchanged.
- Manifest v0.1 gains two proposed fields in-band: `[runtime].repo`
  (required by the resident runtime) and `[runtime].ref` (optional).
  Owner ratifies by merging PR #4.
