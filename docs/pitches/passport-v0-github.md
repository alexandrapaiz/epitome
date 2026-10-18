# Pitch: Passport v0 — the GitHub-only prototype

Shaped 2026-10-05 by the PM seat, for cycle 2.

## Problem

Proposal B in docs/design/portability-proposals.md, the agent
passport, is the owner's own favorite ("already adopted... I like
the concept of an agent passport," ADR-10) and the company's
distinctive claim, not a feature request. No walled vendor (Entra,
AWS AgentCore, Google SPIFFE, Slack, Notion, Asana, the market gap
slide) can answer "is this Slack bot the same agent as this GitHub
bot?" because none of them try to. ADR-10 pulls B's prototype forward
in priority ahead of the other three portability proposals.

The prototype is cheaper today than when it was shaped (2026-09-19)
because its dependency shipped underneath it without being asked for.
ADR-20's app-manifest flow (merged to `main`, PR #48, 2026-10-05)
already gives every agent its own GitHub App identity and private key
(`cli/src/lib/identity.js`). The passport doesn't mint anything new.
It signs a claim with a key that already exists.

The two-platform proof (GitHub plus Slack, the version market wants
publicly visible by mid-October) depends on the Slack identity leg,
which is this cycle's other bet (slack-identity-v0.md) and isn't
guaranteed to land by week 1. Rather than make the passport wait on
Slack again, the same dependency-chain mistake the circuit breaker
exists to forbid (cycle 1 declined runtime-v0-actions for exactly
this reason), this pitch is scoped to GitHub alone. One real
platform, proven, beats a two-platform promise that slips to cycle 3
if Slack runs long.

## Appetite

Small batch: 3 engineer runs. A single-platform prototype for one
agent, not a shipped spec. If it wants more than that, it's cut, not
extended. The two-platform proof and the manifest v0.2 spec treatment
are explicitly out of scope and named below.

## Rough solution (breadboard)

- `epito passport <name>`, for one deployed agent (one with an
  existing `.epito/` principal from the GitHub leg):
  1. Build the card payload per proposal B's illustrative shape:
     `name`, `manifest` (pointer to the repo's `agent.toml`),
     `identities: [{platform: "github", id: "<name>-epito[bot]",
     proof: <link to a commit or App-owned URL the App actually
     authored>}]`.
  2. Sign the card with the agent's existing GitHub App private key
     (already on disk in `.epito/`, per ADR-20, no new key material).
  3. Serve or write the card at `/.well-known/agent-card.json`
     (A2A's own path, per market §5). For v0, writing the file next
     to the manifest and documenting how to serve it is enough. A
     hosted endpoint is explicitly not required this cycle (no-gos).
- `epito passport verify <card-url-or-path>`, the third-party side:
  fetches or reads the card, checks the signature against the App's
  published key (GitHub Apps expose a JWKS-equivalent via their own
  API), and confirms the `proof` link actually resolves to something
  the named App authored.
- Done means: a third party, given only the card (file or URL), can
  cryptographically confirm it was signed by the agent's own key and
  that the GitHub identity it names is real, demonstrated end to end
  for one real HQ agent, with a transcript. Same evidence standard as
  cycle 1's bets.

## Rabbit holes

- Two-platform proof: no. One platform (GitHub), proven, is this
  cycle's whole claim. Slack joins the card's `identities` array in a
  later pass once slack-identity-v0 lands, bet fresh rather than
  assumed.
- A hosted `/.well-known/` endpoint, TLS, a public domain: no. Write
  the file, document how an operator serves it (even `python -m
  http.server` is enough to demonstrate "done when"), and stop. The
  owner's R3 ruling (repo public before the passport ships) governs
  publishing the mechanism, not this cycle's prototype.
- Manifest v0.2 spec changes to formalize the card format: no. This
  is a prototype for one agent, not a spec amendment. If it works,
  the spec question is a fresh pitch.
- JWKS infrastructure, key rotation, revocation: no. One key, the one
  that already exists, used as-is.

## No-gos

No Slack or any second platform in the card. No public launch, press
release, or write-up (market's "visible by mid-October" ask is a
separate decision once this prototype proves the mechanism, and per
Working Backwards, docs/prfaq/<slug>.md gets written and merged
before that launch, not before this prototype). No manifest spec
change. No hosted endpoint.
