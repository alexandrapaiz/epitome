# Pitch: SlackProvider — epito's second identity platform

Shaped 2026-10-05 by the PM seat, for cycle 2.

## Problem

ADR-7 (owner, 2026-09-19: "yes i love slack for agents") accepted
Slack as integration #2 and named its shape: a per-agent App via
`apps.manifest.create`, bot user as the principal, OAuth install,
scope grammar `slack:chat.write`. ADR-9 generalizes it further. Slack
is the FIRST MessagingProvider, not the only one, so the manifest's
messaging scope grammar should name the family, not hardcode Slack
(proposal D, docs/design/portability-proposals.md). ADR-11 names the
consumer: HQ's own seats, today posting into Slack as a bare webhook
with a name and an emoji (`cli/src/lib/slack.js`, built in cycle 1 as
part of epitod v0), upgrade to a real, @-mentionable principal.
"Chat is visibility, git is collaboration," and the upgrade is this
pitch, not a new coordination channel (ADR-11 item 2 is a design
constraint here: post as yourself, be @-mentioned, thread a reply, no
agent-to-agent chat protocol).

This is not a cold start. `epito deploy`'s GitHub leg (ADR-20, merged
to `main` in PR #48, 2026-10-05) already proved the whole shape once:
app-manifest flow, one-shot localhost callback, `.epito/` storage,
per-run token minting (`cli/src/lib/identity.js`, `cli/src/token.js`).
Slack's own app-manifest API (`apps.manifest.create`) is structurally
the same flow (ADR-7 says so directly). The unknown is not the
pattern. It is Slack's specific mechanics: OAuth install vs. the
GitHub callback's installation step, bot-token vs. installation-token
lifetime, and what `slack:chat.write` maps to in Slack's own scope
list.

## Appetite

Big batch: the full cycle. This is the cycle's one genuinely risky
bet, a second platform's app-creation flow discovered rather than
assumed, the same shape cycle 1's identity bet took. If it runs long,
cut in this order: the MessagingProvider generalization (proposal D's
abstraction layer) first (ship Slack-only and generalize the interface
in a later pass), then scope-grammar breadth, never the core
mint-and-post loop.

## Rough solution (breadboard)

- `epito deploy --platform slack <name>` (or an existing `deploy`
  flag) runs a provider-shaped parallel to the GitHub leg:
  1. **Mint the principal.** `apps.manifest.create` pre-filled from
     `[identity].scopes` with `slack:*` entries. OAuth install flow
     (Slack's redirect, not GitHub's one-shot localhost listener,
     confirm whether Slack's flow tolerates a local redirect URI or
     needs a registered one. This is the spike's first question).
     The bot user token is the principal.
  2. **Store nothing personal.** The bot token lands beside the
     existing GitHub App credentials in `.epito/`, same 0600 contract.
  3. **Mint or refresh per run.** Slack bot tokens are long-lived by
     default, unlike GitHub's 1h installation tokens. Name this
     difference explicitly in decisions.md rather than force-fitting
     GitHub's refresh model onto a platform that doesn't need it.
  4. **Scope map.** `slack:chat.write` (post) and
     `slack:app_mentions:read` (receive an @-mention) are the minimum
     viable for ADR-11's contract. Unmapped scopes fail loudly, same
     rule as the GitHub provider.
  5. **MessagingProvider interface** (proposal D): the same three
     verbs (post, be @-mentioned, thread a reply) defined once, Slack
     as the first and only implementation this cycle. Discord,
     WhatsApp, and WeChat stay named in the interface's doc comment as
     future siblings, not built.
  6. **Dogfood the upgrade.** One HQ seat (pm or exo, whichever has
     the simplest existing webhook wiring) moves from `slack.js`'s
     post-only webhook to the real principal, @-mentionable, in a
     thread.
- Done means: a manifest with `[identity].scopes` including a Slack
  scope deploys, the agent exists in the HQ Slack workspace as itself
  (not a generic webhook name), it can be @-mentioned and reply in
  thread, and one real HQ seat is running on the upgraded path.

## Rabbit holes

- Slack's OAuth redirect mechanics: timebox the spike to confirm
  whether a local listener works or a stable redirect URI must be
  pre-registered. If the latter, that is a real complication, named
  in decisions.md the day it's found, not quietly worked around.
- Full MessagingProvider abstraction for platforms not yet
  integrated: no. One interface, one implementation, three verbs.
  Discord, WhatsApp, and WeChat stay research-only (market seat's
  queue, per ADR-7's addendum).
- Slack's Events API or Socket Mode for receiving @-mentions: build
  the minimum that satisfies "be @-mentioned, thread a reply." Do not
  build a general event-routing layer. If that minimum needs a
  resident listener beyond what epitod already runs, name the gap
  rather than closing it with a new service this cycle.
- Workspace-app review and distribution: no. Single-workspace (HQ's)
  app only. Multi-workspace OAuth distribution is a later card, per
  ADR-7's note that unlisted per-workspace install is already
  self-serve.

## No-gos

No Discord, WhatsApp, or WeChat implementation. No agent-to-agent chat
protocol (ADR-11 item 2). No hosted OAuth redirect service: reuse or
extend the GitHub leg's one-shot pattern if Slack's flow allows it. If
it doesn't, that finding itself is the deliverable to report, not a
service to stand up around it. No passport or identity-binding work
(separate pitch, passport-v0-github.md): this pitch mints a principal,
it doesn't prove two principals are the same agent.
