# Pitch: `epito deploy` v0 — the identity slice

Shaped 2026-09-18 by the PM seat, for cycle 1.

## Problem

The backlog's hardest card (`epito deploy` v0, docs/backlog.md Now) says
"split before building." This is the split: identity first, trigger
wiring second (see runtime-v0-actions.md, shaped but not bet). Evidence
the identity leg is the wedge: every demand quote in docs/market.md §2
ends in a hand-built GitHub App ("my PAT and SSH key are off the machine
entirely" — dev.to, 2026-03-15), best practice has converged on exactly
our mechanism (Zylos, 2026-09-02), and alexandria ADR-27 is our own n=1.
The founding minutes (item 2) say the product is the primitive; the
primitive's differentiating leg — the one Cloudflare and Anthropic each
lack (market brief §1) — is the agent as a credentialed principal.
Today `epito deploy` prints "platform in progress" (cli/src/index.js).

## Appetite

Big batch: the full cycle (2026-09-21 → 2026-10-02). If it runs long,
scope is cut (audit log first, scope-mapping breadth second), never the
core mint.

## Rough solution (breadboard)

- `epito deploy` → runs validate → identity step:
  1. **Mint the principal.** Preferred route: GitHub's app-manifest
     flow — the CLI opens a one-click App-creation page pre-filled from
     `[identity].scopes`, catches the callback on a one-shot localhost
     listener, receives the App's credentials. The agent gets its own
     name, avatar, and commit attribution. Fallback route if the flow
     fights us: one epito-owned App with per-repo installations
     (agents share a bot badge — worse story, simpler build). Decide by
     end of week 1 and record which in decisions.md.
  2. **Store nothing personal.** App id + private key land in a local
     `.epito/` dir (0600, gitignored by init); the manifest stays
     publishable, per spec rule 1.
  3. **Mint per run.** A token subcommand (or internal call) exchanges
     the App key for a short-lived installation token scoped by the
     manifest.
  4. **Map scopes.** `[identity].scopes` → fine-grained App
     permissions; only the scopes the three alexandria seat shapes need
     (contents, pull_requests, issues); anything unmapped fails loudly.
  5. **Audit.** Append-only JSONL: every mint, its scopes, its
     timestamp.
- Done means: a manifest deploys, the agent exists on GitHub as itself,
  a token mints, the audit line appears, and `epito deploy` run twice
  updates rather than duplicates (spec rule 4).

## Rabbit holes

- The app-manifest callback: keep it a one-shot local listener; do NOT
  build a hosted redirect service this cycle.
- Scope-mapping table sprawl: three seat shapes' scopes only; the full
  grammar is a v0.2 spec question.
- Token caching/refresh cleverness: mint per run, throw away, done.
- App naming collisions on GitHub: pick a suffix convention, don't
  design a namespace system.

## No-gos

No trigger wiring, no runtime, no non-GitHub platform, no hosted
epito.me backend, no npm publish gate. Identity only.
