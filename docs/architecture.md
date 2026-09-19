# Architecture (proposed, 2026-09-18)

Status: chair's draft on the owner's questions ("how do we build the
product? any proposed architectures?" and "integrate Omarchy into our
stack"). Becomes an ADR when the engineer's route spike (EPI-4) lands
and the owner signs. Nothing here changes cycle 1's bets.

## The organizing idea

The product definition IS the plugin architecture. An agent is
identity + trigger + runtime (ADR-2); the codebase is one core plus
three provider seams, one per leg. Every integration on the market
seat's map — GitHub, Linear, Vercel, Supabase, Omarchy — is a backend
behind exactly one seam, never a special case in core.

## Components

- **agent.toml** — the only source of truth (spec/manifest.md).
  Publishable by construction; nothing personal, ever.
- **@epito/core** — parse, validate, orchestrate. Born in bet 2's
  scope 2a refactor (EPI-10). Mouths call core; core calls providers.
- **Provider interfaces** (kept deliberately small):
  - IdentityProvider: `mint(manifest) → principal`,
    `token(principal) → short-lived credential`, `revoke(principal)`,
    `audit(entry)`. v1: GitHub App (bet 1, route per EPI-4's ADR).
    Next: Linear app-user (pending owner verdict), then per the map.
  - TriggerProvider: `wire(trigger, runtime)`. v1: GitHub Actions
    `schedule:` cron. Next: systemd timers (local), webhook via the
    phase-3 ingress; event subscriptions per platform.
  - RuntimeProvider: `run(manifest, credential)`. v1: the Actions
    runner (ephemeral, $0). Next: systemd unit / rootless container
    (local). Later: hosted containers.
- **Mouths**: `epito` CLI; MCP server (bet 2); roster web UI (phase 3).
- **State**: `.epito/` (keys 0600, audit.jsonl) locally; hosted roster
  DB only in phase 3.

## Phases

1. **Local-first, bring-your-own-cloud** (cycles 1-2, already bet).
   No servers of ours. GitHub App + Actions + local audit. Free;
   the phase is itself distribution.
2. **The local daemon — `epitod`** (post cycle 2, shape as a pitch).
   A supervisor on the user's machine: manifest → systemd user unit +
   timer, body in a rootless container or DynamicUser, roster served
   locally. OS-level identity mirrors platform identity: the same
   someone in `ps` and in the GitHub commit log.
   **Omarchy integration lives here** (owner's directive 2026-09-18,
   ideas ledger: accepted): first target distro because its thesis is
   agents driving the desktop and its gap is exactly ours (its ten
   pre-wired agent CLIs all act as the human). Channel: `epito` on the
   AUR (zero bar, CLI + MCP), then the curated-defaults pitch to the
   Omarchy project. Watch-item stands: if Omarchy ships OS-level agent
   identity itself, re-rank.
3. **Hosted control plane** (the business). Roster + teams + shared
   audit (the paid tier per pricing rev 1), webhook ingress (public
   URL per agent), token-mint service, eventually the marketplace
   (manifests distributed as principals, ADR-2 as the admission bar).
   Deliberately last: phases 1-2 prove demand with zero infra of ours.

## Properties to preserve (the moat framing)

- Local-first and account-sovereign: everything in phases 1-2 runs on
  the user's machine and accounts. The hosted plane sells convenience,
  never captivity. This is the positioning against every enterprise
  identity vendor on the map.
- The manifest stays publishable; secrets stay in `.epito/` or the
  platform's vault. No exceptions, or the marketplace dies in advance.
- Core never grows platform-specific branches; if an integration can't
  fit a seam, the seam is wrong — fix the interface, record the ADR.

## Open questions (for the engineer and the betting table)

- EPI-4 decides App-per-agent vs shared App; that choice shapes
  IdentityProvider's `mint` contract. Due 09-25.
- Does TriggerProvider own webhook ingress in phase 2 (a relay) or
  does webhook wait for phase 3? Leaning: wait.
- `epitod` process model: systemd DynamicUser vs per-agent real users
  vs rootless podman — decide inside the phase-2 pitch, not before.
