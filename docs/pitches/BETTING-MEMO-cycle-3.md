# Betting memo — cycle 3

Written 2026-11-09 by the PM seat. This is the first PM run since
2026-11-02; cycle 2 closed 2026-10-31, cooldown was 2026-11-01/02, and
this is the next scheduled weekly run (the charter runs weekly and on
dispatch), landing seven days into cooldown with no bet placed yet.
Nothing in that gap is a finding against either framework: the open
PM-authored PRs from 2026-11-02 (prompts/pm-agent.md edits, a
decisions.md ADR, a tools/ re-vendor) are all Tier C or this seat's own
Tier B PRs, which correctly wait on the owner or HQ's PM rather than on
this seat, per section 10.

## Pitches considered

| Pitch | Appetite | Bet? |
|-------|----------|------|
| manifest-v0.3-agent-spec (new, shaped today) | Small batch (3 runs) | **Recommended yes** |
| slack-identity-v0 (re-entering, shaped 2026-10-05) | Big batch (full cycle) | **Recommended yes** |
| passport-v0-github (re-entering, shaped 2026-10-05) | Small batch (3 runs) | **Recommended yes** |
| epito-mcp-server (carried from cycle 1) | Small batch (3 runs) | No — fifth time, unchanged reasoning |

## The bet

All three, following the owner's own sequencing ruling (ADR-25,
2026-10-16): "After the MVP bet… The PM shapes this as the first pitch
of cycle 3, with the Slack identity and the passport." That sentence
named this exact set in advance, before cycle 2 was even bet, so this
memo is confirming her own stated plan rather than proposing a new
one.

1. **manifest-v0.3-agent-spec** (docs/pitches/manifest-v0.3-agent-spec.md,
   shaped today). Five new optional manifest tables — autonomy,
   memory, escalation, eval, telemetry — covering the five agent-spec
   properties ADR-25 left unassigned after striking *human owner*.
   Small batch: the owner's own ADR already settled the design
   questions, so this is spec plumbing and validator wiring, not new
   design risk.
2. **slack-identity-v0** (docs/pitches/slack-identity-v0.md, shaped
   2026-10-05, declined cycle 2 on timing by the owner's direct MVP
   override, not on the merits). Epito's second identity platform —
   a per-agent Slack App via `apps.manifest.create`, the same
   app-manifest shape the GitHub leg already proved (ADR-20, merged
   PR #48). The cycle's one genuinely risky bet: a second platform's
   OAuth mechanics, discovered rather than assumed.
3. **passport-v0-github** (docs/pitches/passport-v0-github.md, shaped
   2026-10-05, same cycle-2 decline). The owner's own favorite
   portability proposal (ADR-10): a signed card proving a GitHub
   identity is the same agent, using the GitHub App key that already
   exists. Scoped to one platform deliberately — its own pitch already
   says Slack joins the card's `identities` array "in a later pass
   once slack-identity-v0 lands, bet fresh rather than assumed," so
   betting it alongside slack-identity-v0 this cycle creates no
   dependency between the two; each stands on its own.

All three are mutually independent — checked, not assumed: neither
re-entering pitch names the other as a precondition, and the new
manifest pitch touches `spec/manifest.md` and the validator, a
surface neither of the other two reads or writes. So this is not the
dependency-chain shape rule 1's circuit breaker exists to forbid; it
is three parallel bets, the same shape cycle 1 ran (one big batch, one
small batch) with one additional small batch on top.

**The one real risk, named plainly rather than smoothed over: three
bets is more surface than cycle 1's two for one engineer seat.** None
of the three blocks any other, so there is no manufactured rollover
risk — but there is a capacity question this memo cannot answer from
the repository alone, because it is about the engineer's actual
throughput this cycle, not about any pitch's shape. If it runs long,
the cut order is scope-level, per each pitch's own rabbit-holes
section, and never time: manifest-v0.3's eval and escalation tables
cut first (named in its own pitch), then slack-identity-v0's
MessagingProvider generalization (ship Slack-only, generalize later),
passport-v0-github's own no-gos are already minimal enough that
cutting it whole, not partially, is the honest move if it has to give.
Nothing here cuts by extending the appetite; that is rule 1.

## Not bet, and why

- **epito-mcp-server.** Fifth cycle in a row declined, same reasoning
  every prior memo gave: it has no unknowns, so it never needs to win
  a contest for the engineer's attention it was never designed to
  need, and that argument does not weaken just because the contest
  this cycle is three bets instead of one. The MVP's distribution gap
  it was originally passed over for is also still open — `npm view
  epito-cli` still answers 404 as of the cycle-2 retro's last check,
  so "nobody can `npm install` the base CLI" remains true today, not
  as a reason to keep declining it forever, but as the same reason
  cycle 2's memo gave, unchanged.
- **Everything in backlog Later** (Teams, Convening, the agent
  repository), Omarchy, and LangChain/portability proposal A: ADR-1's
  wedge-first rule, untouched, same as every prior memo.

## Standing asks, carried forward, unrelated to this bet

These are owner/chair account-and-secret actions per section 22, not
engineering, and nothing about this cycle's bet touches them — carried
forward exactly as the cycle-2 retro (PR #367) left them, not
re-flagged, because nothing new has changed any of the three since
that retro was written:

1. A fresh `NPM_TOKEN` and the `npm publish` itself, under the already-
   decided name `epito-cli`. Two tokens have now died unused.
2. One real GitHub App approval, in the owner's browser, once — open
   since 2026-10-16, now 24 days.
3. The `cli/package.json` license word, unresolved since 2026-10-18 —
   it becomes unfixable the moment the first publish happens, so it
   should land before a third token is spent, not after.

## What the owner can veto

- The bet itself: edit or revert this file, or merge it and edit the
  cycle-3 file (opened by this seat once this memo merges, per the
  same watch-note pattern cycle 2 used) directly.
- Betting fewer than three, or sequencing rather than parallelizing
  them, is coherent if she reads the capacity risk above differently
  than this memo does — the case for all three at once is her own
  stated sequence, not a claim about engineer throughput this memo
  can verify.
- Swapping epito-mcp-server back in: coherent once the npm publish
  gap closes, since that was always the stated reason, not a
  permanent one.

Linear mirror: skipped. `LINEAR_API_KEY` probed this run, absent from
the environment, unchanged from every prior probe this trial.

Cycle dates: if this memo merges, or ages 48 hours in silence per
section 22 (this is an engineering-scope recommendation sequencing
already named by the owner's own ADR, not money, accounts, secrets,
or this seat's authority, so the silence default applies), cycle 3
opens on this memo's merge date and runs two weeks, cooldown the two
days after.
