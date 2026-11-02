# Cycle 2 retro + trial scorecard — written at cooldown, 2026-11-01

Cycle 2 ran 2026-10-18 to 2026-10-31. Cooldown is 2026-11-01/02, named in
the betting memo and in docs/cycles/2026-10-18-cycle-2.md. This file is
written on cooldown day 1, on time, unlike cycle 1's retro.

Per ADR-5, the owner's review of Shape Up against alexandria's Scrum
happens at the end of cycle 2. This is that review's evidence file. It
does not render the verdict; ADR-5 reserves that for the owner.

Evidence method: `gh pr list --state all --search "head:epitome-pm/"`
filtered to the cycle-2 date window, `registry.npmjs.org` probed
directly rather than trusted from an earlier pass's reading, and the
pitch, betting memo, and PR/FAQ read against the actual state of
`cli/package.json` and the npm registry today, not against what any
plan file claims.

## What was bet, and what shipped

One bet, the owner's direct MVP override: **mvp-stranger-npm-v0**
(docs/pitches/mvp-stranger-npm-v0.md), small batch, 3 engineer runs,
four scopes.

**2-3 (README verified) and 2-4 (a regression gate) shipped clean.**
#131, composed with the rest in #135, both merged; the gate's own
correctness bug was found and fixed in #136. Nothing contested here.

**2-1 (publish) is engineering-complete and not shipped.** The
`epito-cli` rename, the publish runbook (docs/deploy/npm-publish.md),
and the fixed `prepublishOnly` gate all merged (#246, joined by the
unrelated #242). Checked again today: `cli/package.json` on `main`
still reads `"name": "epito-cli"`, `"license": "UNLICENSED"`, no
`LICENSE` file in the repo, and no `.github/workflows/*.yml` references
`npm` or `NPM_TOKEN`. Probed the registry directly rather than trust
the last recorded reading: `registry.npmjs.org/epito-cli`, `/epito`,
`/epitome-cli`, `/epito-agents`, `/epito-mint` all answer 404 at this
pass, same as every probe since 2026-10-24T21:23Z. Two `NPM_TOKEN`
windows have now died unused (the first 2026-10-24T19:26:26Z; a second
token was asked for and nothing in the backlog or the registry shows
it was ever minted or spent). Zero of the three things the PR/FAQ's own
internal FAQ named as "what has to be true for this to work" are true
today, the same zero as when that document was written 2026-10-18.

**2-2 (one real deploy end to end) never happened.** The browser-click
ask to the owner has been open since 2026-10-16T18:28Z, 15 days before
this retro, with no reply recorded anywhere in the backlog or the
board.

## Circuit breaker verdict

Rule 2 sends unfinished *building* back to raw material at the cycle's
close. The 2026-10-26 pass already read the evidence and made the call
in writing, in docs/cycles/2026-10-18-cycle-2.md: there is no building
left in either open scope. 2-1 has had zero lines of code outstanding
since 2026-10-24T00:53:34Z; 2-2 has had zero lines of code outstanding
since the pitch was written 2026-10-16. Both are pure waits on an
owner/chair account or secret action, which section 22 of the vendored
PM standard puts in the one category that never proceeds on silence
regardless of a cycle clock.

This retro affirms that call rather than re-deciding it: 2-1 and 2-2
carry forward unchanged, as the same two named owner/chair actions, on
the backlog and into whichever file opens cycle 3. They are not
re-shaped into a fresh pitch. Shaping one would manufacture
solution-uncertainty that does not exist in either scope, which is
exactly the failure mode rule 2 exists to prevent, not produce. This is
a deliberate, named exception to "never rolls over silently," made
silently-free by being written here with its reasoning, not by being
quiet about it.

## Grading against the PR/FAQ (Working Backwards)

docs/prfaq/mvp-stranger-npm-v0.md's press release claims: "Today
epito.me published `epito-cli` to the npm registry." That sentence is
false today, 14 days after it was drafted. Its own internal FAQ named
the three things that had to become true first — the package actually
on the registry, the deploy flow proven once against a real account,
and the licence word resolved before the first publish makes it
permanent — and said explicitly that shipping the release before all
three land "would be shipping a release that reads as something that
already happened and has not." That is exactly the state this retro
finds: the release has not shipped, and it was right not to, because
none of the three preconditions cleared.

The press release is not revised by this retro. Nothing in the two
weeks since it was written changed the facts it was written to track;
it still correctly names what would have to be true, and grading
against it is what caught, in writing, that the gap is unchanged
rather than narrowed.

## Trial scorecard — cycle 2 (the owner's binding review point, ADR-5)

**Ceremony cost.** 82 pull requests opened under `epitome-pm/*` branch
names within the cycle-2 window (2026-10-18 through today), counted
directly rather than estimated: 30 merged, 50 closed, 2 still open
(#304 and #363, both withheld by the PM's-own-PR rule or a Tier C
path). Most of the 50 closures are message-passes that produced no
merge and no cycle-machinery change ("nothing in this charter's lane
moved," repeated across a dozen of them on 2026-10-18 alone). The
charter itself names the proximate cause, from inside this same cycle:
"Twenty passes in nine hours opened twenty-four pull requests on
2026-10-18, eighteen of them still open and sixteen unmergeable behind
the first." That sentence is not a hypothetical drawn from this retro;
it is the charter's own record of a day inside cycle 2, and the
charter was amended mid-cycle specifically to stop it (one pull request
per change to the cycle machinery, not one per waking). The fix
landed; this retro cannot yet say by how much it worked, because
counting cleanly resumed only in the back half of the cycle.

**Quality of what shipped.** Two of four scopes shipped clean, directly
checkable against named, merged pull requests, exactly the way cycle
1's retro asked for. The other two are engineering-complete and
equally checkable, but the bet's own success criterion, a stranger
running `npm i -g epito-cli`, is false today. That is not a quality
defect in what the engineer built; every piece that was the engineer's
to build is merged and green. It is a bet whose actual finish line sat
behind two human actions that never happened, and Shape Up's hill-chart
discipline is the thing that caught and said so, in writing, repeatedly,
across six weekly and hook passes, rather than letting a plan file go
stale the way cycle 1's did for six days.

**What she'd rather read Monday.** Not this seat's call; ADR-5 reserves
it for the owner. The honest material: a fixed appetite correctly
refused to manufacture a fresh pitch for either stuck scope, which is
rule 1 and rule 2 working as designed. But the thing that actually
blocked the MVP for 15 days running was never a shaping problem or an
engineering problem on either framework's own terms; it was two
single-click human actions sitting unanswered in a queue. Neither
Shape Up nor Scrum fixes that by itself. Where the two frameworks
genuinely differ this cycle is ceremony: 82 artifacts for one two-week
bet is a volume a weekly Scrum cadence (one ceremony PR a week, per
alexandria's own charter) would not have produced structurally,
whatever else it would have cost. That is the sharpest comparison this
seat can make without inventing alexandria's own numbers, which live in
a different repository this seat does not hold.

**One concrete process improvement.** The mid-cycle amendment (one pull
request per cycle-machinery change, not one per waking) is itself the
thing to grade at cycle 3's retro: if the ceremony count does not drop
materially once a full cycle runs entirely under it, that is a finding
against Shape Up's ceremony promise independent of anything fixed this
cycle, and it should be written as plainly as this cycle's 82 is
written here.

## Linear

`LINEAR_API_KEY` probed this run: absent from the environment. Linear
mirror skipped, unchanged from every prior probe this trial.

## Standing asks carried into cooldown, unchanged

- **A fresh `NPM_TOKEN` and the publish itself**, under `epito-cli`
  (name already decided and merged). Seat: chair or owner.
- **One real GitHub App approval, in the owner's browser, once.** Open
  since 2026-10-16T18:28Z. Seat: owner.
- **The licence word** for `cli/package.json`, asked 2026-10-18,
  unresolved; it becomes unfixable the moment the first publish
  happens, so it should land before, not after, a fresh token is spent.
  Seat: owner.

None of the three is re-flagged urgent here; nothing about any of them
is new since the last pass that checked. They carry forward as the
same three named actions, not as a fresh pitch.
