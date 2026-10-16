# Betting memo — cycle 2 (rewritten 2026-10-16, overrides the 2026-10-05 draft)

Written 2026-10-05 by the PM seat, then superseded today by a direct
owner ruling, relayed by the chair: "we need our product to work, we
need an MVP." The 2026-10-05 draft recommended betting slack-identity-v0
and passport-v0-github. The owner's own sentence is not a veto of that
draft's reasoning on the merits; it is a different question answered
first. This file replaces that draft rather than amending around it, so
there is one current memo, not two disagreeing.

Cycle 1 closed today (its retro + trial scorecard merged as PR #54)
under section 22's silence rule: the decision had waited 11 days past
the 48 hours the standard allows, both bets shipped inside appetite per
that file's own merge evidence, and the owner ruled that a dependency
on her must not halt the system. This memo is cycle 2's bet, proposed
the same way the charter still asks for: the PM proposes, the owner's
merge is the bet — and, per the same section 22, if 48 hours pass in
silence, it proceeds as recommended, because the whole point of
today's ruling is that this memo must not become a third waiting
decision.

## Pitches considered

| Pitch | Appetite | Bet? |
|-------|----------|------|
| mvp-stranger-npm-v0 (new, shaped today) | Small batch (3 runs) | **Recommended yes** |
| slack-identity-v0 | Big batch (full cycle) | **No — declined this cycle, owner override** |
| passport-v0-github | Small batch (3 runs) | **No — declined this cycle, owner override** |
| epito-mcp-server (carried from cycle 1) | Small batch (3 runs) | No — fourth time, unchanged reasoning |

## The bet

**mvp-stranger-npm-v0.** The owner's own words name the bet precisely:
a stranger runs `init`, `validate`, `deploy` and `run` and gets an
agent with its own GitHub App identity, a trigger and a runtime, from
one manifest — CLI installed from npm, the README the only guide. Every
mechanism this needs is already on `main` and tested green (`cli/test/
pack.sh`: 104 of 104 assertions today, the same evidence checked for
this memo). What is missing is not product: it is that the package has
never reached the npm registry (`npm view epito` returns `404`, checked
today) and that the deploy flow has never been proven end to end
against a real GitHub account, only in dry runs and a mocked smoke
test. Full pitch: docs/pitches/mvp-stranger-npm-v0.md.

Small batch, deliberately: this is not new engineering risk the way
cycle 1's identity slice or a Slack integration would be. It is
publishing something that is already built, proving it once for real,
and verifying the README is sufficient on its own — three runs, cut
rather than extended if any scope wants more.

## What the stranger can run today, reported so the owner can read one
line and know the gap

Checked this run, from a scratch directory with the current `cli/`
installed (not yet from the published package, because there is no
published package):

- `epito init` — works, no network, no owner dependency.
- `epito validate` — works, no network, no owner dependency.
- `epito deploy` — mechanically complete and tested (`--dry-run` prints
  the exact App GitHub would create); the real, non-dry path opens a
  browser the *stranger* approves for their *own* account, so it has
  no owner dependency either — it has simply never been run for real
  against a live GitHub account, only dry-run and mocked.
- `epito run` — mechanically complete against a Temporal engine; the
  README already documents `temporal server start-dev` as the
  no-owner, self-hosted path.

So mechanically, all four already work, with zero owner dependency in
the deploy and run paths themselves. The one fact that makes all four
unreachable by an actual stranger today is that the CLI is not on the
npm registry, which is not a code gap — it is the one item below.

## What needs the owner's hand, named once, asked once

Two things, both already posted to her as a board `ask` from this same
run, not re-litigated here:

1. **`NPM_TOKEN`** in Infisical, so `npm publish` can run from `cli/`.
   Nothing else in the publish path is blocked on anything else — the
   pack suite already proves the tarball is correct.
2. **One real GitHub App approval, in her browser, once** — proving
   the deploy mechanism end to end against a live account, for one of
   HQ's own seats. Not a blocker for a stranger's own deploy (they
   click through their own App on their own account), but the proof
   this MVP claim should rest on before calling the loop proven rather
   than merely tested.

Per section 22, neither item proceeds on silence (spending nothing,
but one is a secret and the other widens nothing, so both still wait
for her word deliberately) — these two are exactly the kind the
standard says keep waiting for her regardless. Naming them once, in
this memo and in the board ask, is the whole point of asking for
exactly those and nothing else: the rest of the pitch does not wait on
either.

## Not bet, and why that is not the same reasoning as 2026-10-05

- **slack-identity-v0** and **passport-v0-github** were both
  recommended **yes** in the superseded 2026-10-05 draft, on their own
  merits (ADR-7, ADR-9/10/11/12, the owner's own stated fondness for
  the passport concept). None of that reasoning was wrong; it answered
  a different question than the one asked today. The owner's override
  is explicit that the product needs to work before it needs a second
  identity platform or a cross-platform claim — both pitches stay
  shaped, as raw material, first in line for cycle 3 once the MVP's
  door is actually open. Declined on timing, not on worth.
- **epito-mcp-server.** Fourth cycle in a row it would be passed over,
  unchanged from the reasoning the 2026-10-05 draft already gave: no
  unknowns, so it never loses a contest for the engineer's attention
  it was never designed to need to win, and today's override makes
  that contest even more lopsided, not less. Still named rather than
  quietly dropped.
- **Everything in backlog Later** (teams, convening, the agent
  repository), Omarchy, and Proposal A (LangChain couplings, deferred
  to cycle 3 by the owner's own 2026-09-20 ruling): unchanged, ADR-1's
  wedge rule, untouched.

## What the owner can veto

- The bet itself: edit or revert this file, or merge it and edit
  docs/cycles/2026-10-18-cycle-2.md (opened by the PM once this memo
  merges or 48 hours pass in silence) directly.
- Betting Slack or the passport instead of, or alongside, the MVP
  pitch: coherent if she would rather the strategic bet proceed in
  parallel with the publish-and-prove work, since the MVP pitch is a
  3-run small batch and does not need the engineer's whole cycle. The
  case against doing both is capacity, not worth, and is hers to
  overrule in either direction.
- Either owner-only item above: she can act on each independently: the
  npm token unblocks publish by itself; the App approval unblocks the
  live-proof scope by itself. Neither waits on the other.

Linear mirror: skipped. `LINEAR_API_KEY` probed this run — absent from
the environment (not merely empty), unchanged from every prior PM run
that has checked.

Cycle dates: if this memo merges or ages 48 hours in silence, cycle 2
opens 2026-10-18 and runs to 2026-10-31 (two weeks), cooldown
2026-11-01/02. The 12-day gap from cycle 1's close to this open is the
11 days this decision waited plus the one day this rewrite took; not
smoothed over, not this seat's to shorten further.
