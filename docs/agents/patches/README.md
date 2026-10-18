# Charter patches

**Closed to new patches, 2026-10-18 (L27), and fourteen now, not
fifteen.** The fourteen diffs here stay where they are — the owner's own
ask of 18:34Z is running on all fourteen until 2026-10-20T18:34Z, and
pulling one out from under her clock would be a second fault. Nothing new is written here. A lesson that needs
a charter to bind is now written *into the charter file*, in the pull
request that carries the lesson, one charter per pull request, because the
silence rule discharges a charter change by merge and a diff beside the
charter has no merge to be. Everything below describes the route as it
was, and is kept because these fourteen still travel it.

**One of the fifteen left on 2026-10-18T19:35Z**, and it is the one the
register had already named as the sentence holding this company's merge
queue shut: `2026-10-18-pm-the-standard-is-the-charter` (incident 11).
Its words are in `prompts/pm-agent.md` now, byte-identical, in the pull
request that carries L30. It was the only patch here whose route was
*her word* rather than her silence, so nothing was pulled out from under
a running clock; what it gained is a hand at the far end of HQ's ask.
The fourteen that remain are exactly the fourteen under the 18:34Z
clock.

A file here is a *proposal*, never a change. It is a unified diff against
a charter in `prompts/`, written by the ExO seat when a lesson has to
live in a charter to bind, and it takes effect only when the owner
applies it. Merging the pull request that adds one changes no charter:
the paths in that diff decide its merge tier (knowledge surface), and
the charter the diff names is untouched until her hand moves (L21).

Two rules this directory is held to.

**Every patch is checked before its pull request opens.** Not by hand,
and not by remembering this paragraph: `bash docs/agents/check.sh`, from
a full clone, which runs the command the owner will run.

A patch `git apply` refuses is not a proposal, it is a file. On
2026-10-18 one of the eight on `main` answered `corrupt patch at line 27`
and had already travelled into an ask to the owner. One hour after this
rule was written here, the next run of this seat shipped a patch that
answered `corrupt patch at line 29` — a hunk header claiming six old
lines over four — which is the same failure after the rule existed, and
is why the rule is now a command and this paragraph is only its reason
(L4, L23). Build the hunk from the file, never count it.

**A patch applies standalone.** Each is written against `main` as it
stands, so she may apply them in any order and skip any one of them. A
patch that needs another applied first says so in a note above the diff
*and* still applies on its own; the set is checked in sequence too,
because `git apply` is strict about context and a set that lands
individually can still refuse as a set.

**The state of the queue is readable from here.** A patch stays in this
directory after the owner applies it — `git apply --check --reverse`
answering cleanly is what "applied" looks like, and the ExO's run says
which are still waiting and for how long.

**Every patch records which door releases it.** The company standard
puts a charter edit behind the silence rule (§22) and a grant of a
seat's own authority behind the owner's word (§21, §22's exception), and
which of the two a patch is decides whether a clock can run on it at
all. `routes.md` in this directory holds the route for every patch, the
reason for it, and the count by route — because "fifteen waiting" read as
one blocked queue for fourteen days, and the true shape was fourteen
that nobody had started a clock on and one correctly waiting for a
person (L25). A patch with no route recorded is not ready to be asked
for.
