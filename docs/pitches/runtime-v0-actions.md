# Pitch: runtime v0 on GitHub Actions

> Superseded 2026-09-20 by runtime-v0-resident.md (owner-directed: the
> runtime is resident epitod on an always-on host, not Actions). Kept
> for the record; the Actions runtime remains HQ's async heartbeat.

Shaped 2026-09-18 by the PM seat. NOT bet for cycle 1 (depends on the
identity slice landing first — see BETTING-MEMO-cycle-1.md).

## Problem

An agent is autonomous and resident, not prompted (ADR-2); today a
validated manifest has no way to wake. The backlog (Now) calls for
runtime v0 on GitHub Actions — the $0 substrate the target users
already run (alexandria's eleven seats all live there). Without this
leg there is no dogfood migration and no launch post (vision, backlog).

## Appetite

Small batch: 3 engineer runs. It is mostly generation and glue once
the identity slice exists; if it swells past that, the pitch was wrong
and goes back to shaping.

## Rough solution (breadboard)

- `epito deploy` (same command, second phase) emits
  `.github/workflows/epito-<name>.yml`:
  - `schedule:` from `[trigger].cron`, plus `workflow_dispatch` for
    manual smoke runs.
  - The job mints a short-lived installation token via the agent's App
    identity (from the identity slice), never a personal token.
  - Runs the model named in `[runtime].model` against
    `[runtime].entry` with `max_turns`; commits/PRs land attributed to
    the agent's own badge.
  - Secrets named in `[runtime].env` are referenced as repo secrets by
    name; values never touch the manifest.
- Persistence, honestly stated: v0 residency is repo-as-state (the
  agent's files outlive every run); the containerized image is the
  backlog's explicit second step, not this pitch.

## Rabbit holes

- Actions cron drift and delays: document it, don't engineer around it.
- Chasing "real" container persistence: out — repo-as-state is v0.
- Workflow-template configurability: generate one opinionated file;
  no options matrix.

## No-gos

No webhook or event triggers (cron only), no non-Actions substrate, no
containerized image, no multi-agent roster orchestration.
