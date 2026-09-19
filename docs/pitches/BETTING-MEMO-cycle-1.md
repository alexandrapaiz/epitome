# Betting memo — cycle 1 (2026-09-21 → 2026-10-02)

Written 2026-09-18 by the PM seat. This cycle the bet is delegated to
the PM (founding minutes item 8): the bets below are placed, not
proposed. The memo still exists so the format future cycles will use is
on record from day one, and so the owner has one page to veto from.

## Pitches considered

| Pitch | Appetite | Bet? |
|-------|----------|------|
| deploy-identity-v0 | Big batch (full cycle) | **Yes** |
| epito-mcp-server | Small batch (3 runs) | **Yes** |
| runtime-v0-actions | Small batch (3 runs) | No |

## Bets placed

1. **deploy-identity-v0.** The credentialed-principal leg is the wedge:
   the market brief shows Cloudflare and Anthropic each one feature
   away on every leg *except* this one, and all six demand quotes end
   in a hand-built GitHub App. Everything downstream — runtime, dogfood,
   launch post — queues behind it, so it gets the full appetite.
2. **epito-mcp-server.** Distribution is the plan (minutes item 6) and
   this is its cheapest expression: no listing bar, no waitlist,
   reaches ~72% of the editor-agent stack. It only repackages code
   that already ships, so it cannot contend with bet 1 for unknowns —
   a good pairing of one risky bet with one sure one.

## Not bet, and why that's fine

- **runtime-v0-actions** depends on bet 1's output. One engineer seat
  plus a dependency chain equals a manufactured rollover; the circuit
  breaker forbids exactly that. It is shaped, sits as raw material, and
  gets re-bet in cycle 2 with the dependency resolved. Nothing on the
  owner's timeline (dogfood, launch) assumed runtime in cycle 1.
- **Everything in backlog Later** (teams, convening, repository):
  ADR-1 wedge rule; not shaped, per the charter these stay untouched.

## What the owner can veto

- Either bet: edit or revert docs/cycles/2026-09-21-cycle-1.md; the PM
  reshapes around the edit.
- The route decision inside bet 1 (App-per-agent vs shared App) lands
  in decisions.md by end of week 1 — a one-line objection there redirects
  it mid-cycle without a bet change.
- Swapping runtime-v0-actions in for the MCP server is coherent if the
  owner prefers wedge depth over distribution this cycle; the PM's
  reasoning against it is the dependency, not the pitch's worth.

Linear mirror: skipped this run — no LINEAR_API_KEY yet (owner-only
backlog item); the repo remains the source of truth.
