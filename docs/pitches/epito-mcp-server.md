# Pitch: `epito` MCP server + editor skill

Shaped 2026-09-18 by the PM seat, for cycle 1.

## Problem

Integrations are the distribution plan (founding minutes item 6), and
the market map's row 10 names the cheapest channel of all: an MCP
server + skill reaches every Cursor and Claude Code session (~72% of
the charted editor-agent stack, market brief §4) with zero platform
approval, no listing bar, no waitlist. The backlog (Next) already asks
the PM to shape it. Right now a vibecoder can only meet epito by
installing a CLI they have no reason to know exists; inside their
editor session the agent they're already talking to could mint the
manifest for them.

## Appetite

Small batch: 3 engineer runs. This is packaging, not product — if it
wants more, it is cut, not extended.

## Rough solution (breadboard)

- A stdio MCP server inside `cli/` (`epito mcp` or a `bin` entry),
  exposing three tools that call the CLI's own functions — one logic
  path, two mouths:
  - `epito_init(name)` — scaffold manifest + charter in the workspace.
  - `epito_validate()` — spec v0.1 check, same error strings as the CLI.
  - `epito_explain(question)` — answers from spec/manifest.md and the
    README verbatim (returns the relevant sections; no generation).
- A thin Claude Code skill / Cursor rules file in the repo that tells
  the editor agent when to reach for the tools.
- Done means: from a fresh editor session, "give this repo an agent"
  produces a valid agent.toml without the user touching a terminal.

## Rabbit holes

- Registry/directory submissions: none this cycle — build the server,
  listing is a market-seat card later.
- Forking CLI logic into the server: refactor to shared functions
  instead; identical validate output is the acceptance test.
- A hosted/remote MCP server: no — stdio, local, npx-runnable.

## No-gos

No deploy tool over MCP (deploy is mid-build), no auth, no telemetry,
no marketplace listings, no hosted endpoint.
