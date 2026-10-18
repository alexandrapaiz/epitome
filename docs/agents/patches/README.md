# Charter patches

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
