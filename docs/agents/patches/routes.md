# What releases each patch

**The ask is filed (2026-10-18T18:34Z).** The fourteen this file classified
as `silence` now have the clock this file said nobody had started; it
expires 2026-10-20T18:34Z. What the ask does not have is a hand at its far
end — no seat in this company is authorised to apply a diff to a charter,
which is L27 and the reason this directory is closed to new patches.

A patch in this directory is a proposal, and until 2026-10-18 the only
thing anybody recorded about one was its age. Age is not what releases
it. The company standard releases it, and it releases two kinds of patch
by two different doors:

- **§22, the silence rule.** "A decision a charter reserves for the
  owner is proposed by the PM on the board as an `ask` addressed to her,
  with the PM's own recommendation, and proceeds as recommended after
  forty-eight hours of her silence… This covers closing and betting a
  cycle, **editing a charter**, changing a workflow, waking a dormant
  seat, and every other reservation a charter makes, in every company."
- **§22's own exception, repeated in §21.** "What never proceeds on
  silence. Spending money, opening an account, writing or rotating a
  secret, and **widening a seat's own authority**." §21: "Only a change
  to a seat's own authority (this section, section 10, section 19, **the
  PM charter's grant**)."

So the question "does this need her hand?" is answerable per patch, from
a file already vendored in this repository, and the answer decides
whether the patch can have a clock at all. **Every patch in this
directory records its route.** A patch with no route recorded is not
ready to be asked for.

`silence` — a duty, a stop condition, a reporting obligation, a
narrowing. The PM files one `ask` naming it and it proceeds after
forty-eight hours of silence.

`her word` — it widens a seat's own authority, spends, opens an account
or touches a secret. The PM asks once, in the daily brief's ordered
list, and nothing proceeds without her.

## The queue, 2026-10-18T14:40Z

Fifteen patches exist; `*` marks the seven that are not on `main` yet
and travel with the pull request named.

| patch | charter | route | why that route |
|---|---|---|---|
| 2026-10-05-engineer-check-the-register | engineer | silence | adds a duty: check the PR body against the register before readying |
| 2026-10-05-engineer-landing-has-a-stop | engineer | silence | adds a stop condition to landing; narrows, grants nothing |
| 2026-10-05-exo-two-standing-counts | exo | silence | adds two reporting duties, named in the patch as observations and never proposals |
| 2026-10-18-engineer-a-defect-is-not-an-idea | engineer | silence | routes a defect class as work; a duty |
| 2026-10-18-exo-a-patch-leaves-with-a-clock | exo | silence | obliges this seat to get a clock onto its own patch |
| 2026-10-18-exo-the-capacity-line | exo | silence | adds a file and one mandatory number to this seat's output |
| 2026-10-18-exo-the-loops-local-half | exo | silence | writes down a standing duty a chair already assigned (incident 7) |
| 2026-10-18-pm-a-pass-is-not-a-pull-request | pm | silence | changes the unit of an output clause; grants nothing |
| 2026-10-18-engineer-the-installed-runtime `*` | engineer | silence | adds a disclosure duty for runtime changes (#208) |
| 2026-10-18-exo-a-fix-is-shipped-when-it-is-on-main `*` | exo | silence | obliges a re-measurement of this seat's own entries (#208) |
| 2026-10-18-exo-the-number-comes-from-the-queue `*` | exo | silence | obliges a pre-flight check before this seat opens a PR (#204) |
| 2026-10-18-exo-the-order-is-measured-at-publication `*` | exo | silence | obliges a measurement to be taken last (#208) |
| 2026-10-18-pm-a-decline-names-its-condition `*` | pm | silence | obliges a decline to name its condition; constrains, grants nothing (#208) |
| 2026-10-18-pm-a-deferral-is-a-merge `*` | pm | silence | obliges a deferral to be tested before it is written (#208) |
| **2026-10-18-pm-the-standard-is-the-charter** `*` | pm | **her word** | grants merge authority by citation — §21 names "the PM charter's grant" as hers alone (#204) |

**Fourteen silence, one her word.** The one that needs her word is the
only one that has an ask on it: headquarters' project manager filed it
at 2026-10-18T13:53Z and said in the same note that it is "not eligible
for the forty-eight hour silence rule since granting merge authority is
exactly the kind of widening section twenty-two reserves for her word
alone." That is correct. The fourteen that would have proceeded without
her have no ask, no clock, and nothing waiting on them but somebody
filing one.

## The order, which is not a preference (added 2026-10-18T19:05Z)

A route says whether a patch can have a clock. It does not say whether the
set can be applied, and on 2026-10-18 those turned out to be different
questions: each of the fifteen applies to the tree alone, and applied as the
set the owner's ask asks for, **nine land and five refuse** — a different five
depending on the order, because fourteen of them insert at four shared
anchors and each was written against the unpatched charter.

So the sequence is recorded beside the routes, in
`docs/agents/patches/ORDER`, one patch per line, the one that waits for her
word last. All fifteen apply in that order with plain `git apply` and no
fuzz; `bash docs/agents/check.sh` applies them for real, in that order, in a
scratch worktree, and refuses if any of them does not land.

**This file's own rule, extended.** A patch with no route recorded is not
ready to be asked for; a *set* with no sequence recorded is not ready either,
because the ask says "apply all fourteen as written" and that sentence has to
resolve to something a hand can do. The line-by-line content review behind
this is `docs/agents/patch-review-2026-10-18.md`, and it names one patch
worth a second look before the clock clears (`pm-a-decline-names-its-condition`,
whose Tier-A vocabulary can be read as the one widening §22 does not release)
and two dependencies: six of the fourteen cite L19–L24, which are not on
`main`, and two oblige scripts that are not on `main` either.

## State, measured rather than remembered

"Applied" is what `git apply --check --reverse` answers cleanly. Run
over the eight on `main` at 2026-10-18T14:40Z: none is applied, and
`prompts/pm-agent.md` was last edited 2026-09-20T06:41:03Z, 28 days
ago. The last edit to any existing charter in this repository was
2026-10-05T03:37:43Z (`d6bfd42`, the not-landing clause in the ExO's own
charter) and it was a direct commit, not a patch from here. Zero of
fifteen have ever travelled this directory's own route.
