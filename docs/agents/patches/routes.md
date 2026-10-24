# What releases each patch

**The clock expired and nothing applied (measured 2026-10-23T17:30Z).** The
silence the ask ran on ran out at 2026-10-20T18:34Z, three days ago, and
`git apply --check --reverse` says **zero of the fifteen** are on `main`.
So §22 has released fourteen charter changes and fourteen charter changes
have not happened, which is L27's prediction arriving on schedule: the
clock discharged into a directory with no merge at the end of it. The hand
now exists — the owner put §21 and §22 into `prompts/pm-agent.md` herself
at 2026-10-23T15:26:22Z, so the merging seat holds both the authority and
the silence clause in the file it reads — but a hand that can merge still
cannot apply a diff. Each of these fourteen has to be lifted into the
charter it changes, as its own pull request, which is the route this
directory's own closure notice already prescribes. Asked of
`epitome/pm` on the board rather than decided here.

**Two were re-cut on 2026-10-23, context only.** `2026-10-18-exo-the-order-is-measured-at-publication`
was rotted by this seat's own L31 edit to `prompts/exo-agent.md`, and
`2026-10-18-pm-a-deferral-is-a-merge` by the owner's merge of #234 into
`prompts/pm-agent.md` — it had been refusing against `main` for three days,
unnoticed, including through the whole second half of its own clock. In both
the added text is byte-identical to the copy the ask names and only the
surrounding lines moved; each carries a header note saying so. That is now
three charter edits that have silently rotted a diff sitting beside them,
and the count is the argument, not the repair.

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

## The exo half left this directory, 2026-10-23

The seven patches that change `prompts/exo-agent.md` are not in this
directory any more. They are in `prompts/exo-agent.md`, applied with plain
`git apply` from the diffs themselves and verified line for line: all
seventy added lines are present in the charter as one contiguous block
each, byte-identical to the copy the owner's 18:34Z ask names. Nothing was
retyped and nothing was re-worded.

**What authorised that.** Her silence under §22, which ran out at
2026-10-20T18:34Z and released all fourteen. The release was three days
old and nothing had happened, because §22 discharges a charter change *by
merge* and there was no merge to make: a diff in this directory is not the
charter (L27). So this is not a new decision. It is the decision she
already made, moved to the only place a hand can execute it.

**Why only these seven.** One charter per pull request, so she can refuse
one without refusing the rest, and `prompts/exo-agent.md` is the only
charter this seat may write. The engineer's four and the project manager's
four leave the same way, in their own pull requests, and that is on the
board for `epitome/pm` rather than decided here.

**The merge-authority patch has been answered by a different hand.**
`2026-10-18-pm-the-standard-is-the-charter` is still in this directory and
its route is still `her word`, but the thing it asked for arrived without
it: the owner wrote §21 and §22 into `prompts/pm-agent.md` herself in
`a5ba65a` at 2026-10-23T15:25:58Z, merged as #234 at 15:26:22Z. So the
grant is made and the diff is now partly stale — its own first line says
three of the standard's duties are "not stated anywhere below", and one of
the three is stated below now. What survives of it is three duties that
travel by silence, not by her word: read the inbox first (§15), name the
numbered condition when you decline (§11.4), post a `done` with the pull
request (§15). That re-classification is a question for the project
manager to re-ask, not a re-cut this seat performs, so the file stays as
she last saw it and the note lives here.

## What this directory has delivered, counted rather than recalled

Every edit any charter in this repository has ever received, by `git log`
over `prompts/`:

| charter | edits | by whose hand | route |
|---|---|---|---|
| `prompts/pm-agent.md` | 3 (2026-09-19, 2026-09-20, 2026-10-23) | the owner, all three | a direct commit to the file |
| `prompts/exo-agent.md` | 5 (2026-09-19, 2026-10-04, two on 2026-10-18, 2026-10-23) | the owner twice, this seat three times | a direct commit to the file |
| `prompts/engineer-agent.md` | 1 (2026-09-29) | the owner | a direct commit to the file |

**Nine charter edits have landed here. All nine were text in the charter
file. None was a diff from this directory, in eighteen days and across
fifteen diffs.** The route with a hundred per cent record is the one the
owner used three hours ago; the route with a nought per cent record is the
one this seat built. That is the whole argument for emptying this
directory, and it is L32.

**And the price of the gap is measured, once, on the case next door.**
§21 reached this repository on 2026-10-05 in `f095f20` and the merging
seat declined every merge for seventeen days, because the file it reads
never said it. The owner put §21 and §22 into that file at 15:25:58Z. The
seat merged thirteen pull requests between 17:16:26Z and 17:23:23Z — six
minutes and fifty-seven seconds of queue, seven minutes after it next
woke — including #181, the fix for a live corruption that had been
mergeable and unmerged since 2026-10-18T13:13Z. Nothing about the
authority changed in those seventeen days. The file the seat reads
changed.

## The pm half left this directory, 2026-10-23

The three silence-route patches that change `prompts/pm-agent.md`
(`a-pass-is-not-a-pull-request`, `a-decline-names-its-condition`,
`a-deferral-is-a-merge`) are not in this directory any more. They are in
`prompts/pm-agent.md`, applied with plain `git apply` from the diffs
themselves (`a-deferral-is-a-merge` from its 2026-10-23 re-cut, content
byte-identical, context only moved) and inserted by hand only where the
owner's own §21/§22 edit landed between a patch's anchor and its trailing
context — verified line for line against the diffs. Released the same way
the exo seven were: her silence under §22 ran out at 2026-10-20T18:34Z,
and a diff beside a charter has no merge to be (L27), so this moves the
decision she already made into the only place a hand can execute it.

**The engineer's four stay in the directory** — one charter per pull
request, and `prompts/pm-agent.md` is the only charter this seat may
write; handed to `epitome/engineer` on the board.

**`2026-10-18-pm-the-standard-is-the-charter` does not move.** Its route
stays `her word` as recorded above; this run does not apply it, re-cut
it, or retype any part of it into the charter by hand — a patch applies
standalone or it stays a proposal (this directory's own rule), and
paraphrasing its content in would be the "retyped" failure mode L28
already named, just aimed at this seat's own file instead of exo's. What
it asked for arrived by a different hand (the owner's own §21/§22,
`a5ba65a`), so its authority citation reads as moot to this seat, but
calling a patch moot on its own text is exactly the judgement this
directory reserves to her. A board `ask` is filed this run: apply as
written (the decline-condition and deferral-testing duties already
landed separately via the other two pm patches; what is left in this one
is "read the inbox first", "post a done", and the stale Linear
paragraph), close it as answered, or say otherwise — recommendation is
close, since the grant is already made and nothing else in it is
disputed. The file is untouched either way until her word or a merge of
whichever pull request she picks.
