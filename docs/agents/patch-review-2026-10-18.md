# The content of the fourteen under the owner's clock, read line by line

The project manager filed the owner ask at 2026-10-18T18:33Z and named, in
the note that woke this run, the one thing it had not done:

> I have not reviewed the content of the fourteen patches line by line, only
> their route. If any of them turns out to need a second look before her clock
> clears, that is still worth raising, and I would rather you catch it than
> the clock alone decide it.

So this is that read, taken at 19:05Z, with twenty-three and a half hours
left on the clock. The route file beside this one (`routes.md`) answers "does
this need her hand"; this file answers "does this patch say what it means to
say, and will it be in the charter when she stops speaking".

**The short version.** Fourteen of fourteen are well-formed, in their
charter's own voice, one rule each, and every register entry they cite
exists. The content is not the problem. **The set is**: each of the fifteen
applies to this tree alone, and applied as the set her ask asks for, nine
land and five refuse — and which five depends on the order. One patch needs
a second look on its own account, one duty lands on a file that is full
today, and the fourteen cannot be applied to `main` as `main` stands.

## 1. The set does not apply, and the three tools disagree about it

Measured in a throwaway worktree of the tree the fourteen travel in
(`epitome-exo/2026-10-18-message-12`, the head of the stack that carries
seven of the fifteen diffs and both scripts two of them name):

| what was run | result |
|---|---|
| `git apply --check <patch>`, each of the fifteen alone | 15 of 15 apply |
| `git apply --check` on all fifteen at once | **exit 0 — "applies"** |
| `git apply` on all fifteen at once | **exit 1 on the fourth**, and two charters left half-written (23 insertions on disk) |
| `git apply`, one at a time, in the ask's own order | **9 of 14**; refused: `a-defect-is-not-an-idea`, `the-capacity-line`, `a-fix-is-shipped-when-it-is-on-main`, `the-number-comes-from-the-queue`, `a-decline-names-its-condition` |
| `git apply`, one at a time, in the reverse of that order | **9 of 14**, and a *different* five: `a-fix-is-shipped-when-it-is-on-main`, `a-pass-is-not-a-pull-request`, `the-capacity-line`, `two-standing-counts`, `check-the-register` |
| `patch -p1 -F3`, one at a time, in the ask's order | 14 of 14 "ok", five of them **with fuzz** |

The cause is not a defect in any one diff. Fourteen of the fifteen insert at
four shared anchors — the incidents bullet in the ExO charter (four of them),
the "New ideas found while building" bullet in the engineer's (two), the
Output clause in the PM's (two), and the paragraph before `## Output` (one) —
and each diff was written against the *unpatched* charter, so the first one
at an anchor consumes the trailing context the next one needs. No ordering
fixes it: two patches anchored on the same before-and-after context can never
both apply cleanly, whichever goes first.

**The fuzzy row is the dangerous one.** `patch -F3` reports fourteen of
fourteen applied, and five of them land where their own diffs do not say. One
of those five, `the-number-comes-from-the-queue`, lands *inside another
bullet's sentence*: the ExO charter's first bullet comes out as

```
- **docs/agents/lessons.md updated.** Extract the real pattern from the
- **One branch per seat, and the number comes from the queue.** Start
  ... (ten lines) ...
  correction, not the surface: the triggering quote (verbatim, dated),
```

That is the state the clock resolves to if whoever holds the far end of it
reaches for the tool that gets all fourteen in.

**What this run did about it.** Re-anchored the five that collide, against
the sequence rather than against the original file, and recorded the sequence
in `docs/agents/patches/ORDER`. Nothing in the subject of her ask moved: the
136 added lines across the fourteen are a byte-identical multiset before and
after, the only line any of them removes is the one line
`a-fix-is-shipped-when-it-is-on-main` removes by design, and each re-anchored
file says in its own preamble that only its context moved. Verified: all
fifteen now apply in `ORDER`'s order with plain `git apply` and no fuzz, the
fifteenth — the one that waits for her word — applying last and unchanged, so
it can still be refused on its own. The resulting charters were read section
by section: every bullet is in the list its diff names, and no sentence is
spliced.

**The instrument that should have caught this said the opposite.**
`docs/agents/check.sh`, this seat's own pre-flight, has carried a line since
14:22Z claiming to check the patches "alone and as a set". Its set check was
`git apply --check docs/agents/patches/*.diff`, which writes nothing, checks
each patch against the unmodified file, and therefore cannot see a sibling
collision at all. It printed `applies` at 18:58Z today, four hours after the
ask was filed from a table it had blessed. It now applies the set for real,
one at a time, in `ORDER`, in a scratch worktree, and names which patches
need their predecessors.

## 2. One patch worth a second look on its own account

`2026-10-18-pm-a-decline-names-its-condition`, which routes as `silence`
because it "constrains, grants nothing", contains this clause:

> The merge rule's tier is read off `gh pr diff --name-only`, never off what
> the pull request is about: a file that proposes a charter change is a
> knowledge surface, and only a path under `prompts/` is the owner's.

The outcome it argues for is right — a patch file is not Tier C, and the PM
has in fact merged one today. But "knowledge surface" is §10's **Tier A**
vocabulary, and Tier A is *self*-merge, enumerated: `docs/sprints/`,
`docs/agents/` (org-chart, pending, frameworks, lessons, incidents), grooming
edits to `docs/ideas.md`, `docs/finance/`, and `standards/lessons.md` for the
centralizer only. `docs/agents/patches/` is not in that list. Read strictly,
the clause lets a seat self-merge its own charter-patch pull request as Tier
A, which skips Tier B's first condition — "it is not the PM's own PR". That
is a widening of a seat's own merge authority, which is the one route §22
says never proceeds on silence (L25).

I am not asserting that is what it means; I wrote it, and I meant Tier B. I
am saying the sentence can be read the other way by a fresh seat, and the
reading it permits is the only kind of change the clock it is riding may not
carry. The repair is one clause — "is Tier B, not the owner's" instead of "is
a knowledge surface" — and it is not mine to make under her clock, which is
why it is raised here and to the project manager rather than edited.

## 3. One duty lands on a file that is full today

`2026-10-18-exo-the-capacity-line` obliges this seat to write one row per tick
into `docs/agents/loop.md`. That file declares its own ceiling in its own
text — "**This file has a ceiling** … 160 lines" — and it is 160 lines today,
with one row in the table. So the first tick after the patch applies has to
collapse rows or cut the file, which is exactly what the file's own two kill
conditions say to do. Not a defect; a duty whose first execution is a cut, and
better known before the clock clears than discovered by the run that trips it.

## 4. The fourteen are not applicable to `main` as `main` stands

Two dependencies, both checkable:

- **Six of the fourteen cite register entries `main` does not have.** `main`
  holds L1–L18 and Incidents 1–8. The patches cite L19 (`a-deferral-is-a-merge`),
  L20 (`a-fix-is-shipped-when-it-is-on-main`), L21 (`a-decline-names-its-condition`),
  L22 (`the-installed-runtime`), L23 (`the-number-comes-from-the-queue`) and
  L24 (`the-order-is-measured-at-publication`). Applied to `main` today, six
  charters would point at entries nobody can read — the shape of incident 7.
- **Two of them oblige scripts `main` does not have.** `the-number-comes-from-the-queue`
  obliges `bash docs/agents/check.sh` and `the-order-is-measured-at-publication`
  obliges `bash docs/agents/order.sh`. Both files exist only on the stack that
  carries L19–L27.

So the order is: the stack lands, then the fourteen apply. Both halves are in
the same three pull requests, which is an argument for merging them and not an
obstacle to it.

## 5. The fourteen, one row each

Content verdict only. "Voice" means it reads as the charter's own sentences;
"one rule" means a fresh-context seat could act on it without this file.

| # | patch | charter | what it binds | citations resolve | verdict |
|---|---|---|---|---|---|
| 1 | check-the-register | engineer | check the PR body against the lesson register before readying; name decisions by what they decide | L14 ✓ | sound. Its claim that the PM and market charters "already require" this is true — both name `docs/agents/lessons.md` as a pre-ship check |
| 2 | landing-has-a-stop | engineer | one landing attempt per stack, with the containment test spelled out | L13 ✓ | sound |
| 3 | two-standing-counts | exo | two counts every run, as observations, never proposals | — | sound; the clause about chains is live today, three of this seat's own pull requests being one |
| 4 | a-defect-is-not-an-idea | engineer | a named general case is work, handed to the PM in the same run | L15 ✓, incident 5 ✓ | sound. Re-anchored; lands as the last bullet of the Standards list rather than the fourth, which is the only freedom the repair took |
| 5 | a-patch-leaves-with-a-clock | exo | the run that writes a patch gets a clock onto it | L16 ✓ | sound, and now partly historical: L27 moved the patch into the charter, so "it" is the pull request. Reads correctly either way |
| 6 | the-capacity-line | exo | one row per tick in loop.md, and the capacity number may never be missing | L18 ✓, incident 8 ✓ | sound; see §3 — the file is at its ceiling today |
| 7 | the-loops-local-half | exo | the daily tick, what it observes, and where it sends it | — | sound; the clock and the event name are the host's and were not re-verified here |
| 8 | a-pass-is-not-a-pull-request | pm | the output unit is a change, not a waking | L16 ✓ | sound |
| 9 | the-installed-runtime | engineer | a fixture is copied not quoted; name the artifact the host runs and its distance | L22 ✓, incident 10 ✓ | sound. Carries two dated measurements inside permanent text ("hundreds of commits behind … since September"); dated, so it will read as history rather than as a claim |
| 10 | a-fix-is-shipped-when-it-is-on-main | exo | an entry whose fix is not on `main` says where it is, and is re-measured | L20 ✓ | sound. Re-anchored: it edits a line two other patches insert after |
| 11 | the-number-comes-from-the-queue | exo | branch from your own newest PR, run check.sh, renumber here | L23 ✓ | sound, and confirmed from outside this seat today: the project manager agreed at 18:35Z that the register's numbering comes from this seat |
| 12 | the-order-is-measured-at-publication | exo | generate the order last, print the head you measured | L24 ✓ | sound |
| 13 | a-decline-names-its-condition | pm | name the numbered condition behind every decline | L21 ✓ | **second look** — see §2 |
| 14 | a-deferral-is-a-merge | pm | test the merge before deferring onto it | L19 ✓ | sound; `git merge-tree --write-tree`, the command it obliges, runs on this box (git 2.43.0) |

The fifteenth, `the-standard-is-the-charter`, was not read here beyond
checking that it still applies last: it widens the PM's own authority, HQ's
project manager has already asked the owner for it in her own words, and it
is not in this clock.
