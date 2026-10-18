# `epito deploy --target cloudflare` — an agent that lives on the edge

Status: **prototype, in progress** (owner ask, 2026-10-18; due Wednesday's
brief, 2026-10-21). This file is written as it is built; the sections marked
*not yet* are the honest gaps.

## What the owner asked for

> `epito deploy` takes one of our manifests and produces an agent on
> Cloudflare with its own identity, a schedule that fires, state that
> survives, and a page showing the agent, its last run and a button that
> triggers it.

Done means she opens a link and triggers an agent herself.

## The shape

The resident runtime (`epito run` + `epito worker` + Temporal) is a box you
own. Cloudflare is the other end of the same promise: nothing to provision,
nothing to keep alive, and the agent still has an identity, a schedule and a
memory. One manifest reaches both, which is the claim this prototype is here
to test.

Four things the ask names, and what each one is on Cloudflare:

| the ask | on the resident runtime | on Cloudflare |
| --- | --- | --- |
| its own identity | the agent's GitHub App, key in `.epito/keys/` | the same App — the key is a Worker secret, and the Worker signs its own JWT and mints its own installation token per run |
| a schedule that fires | `epito run` registers a Temporal schedule from `[trigger].cron` | `triggers.crons` in the generated `wrangler.jsonc`, the same five fields |
| state that survives | the engine's history, `.epito/board.jsonl` | one Durable Object per agent, holding the run log |
| a page | the ingress on the host | the Worker's own `GET /` |

Nothing in the manifest changes. That is the point worth proving: the spec
never said "GitHub Actions" or "Temporal" or "a box", so a second target
should need no new field — and if it does, the field is a finding about the
spec and not a convenience.

## Status of this run

See the pull request this file arrived in.
