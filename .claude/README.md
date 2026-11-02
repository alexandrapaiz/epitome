# `.claude/` — the harness settings every seat of this product inherits

One hook, and it is the enforcement `docs/standards/lessons.md` L-X5 asks for
in its own closing clause: "a rule whose violation is a single shell idiom
cannot be enforced by a sentence, and must be enforced by something that reads
the command."

Until this file existed, this repository had nowhere to put that. The rule was
vendored here and read; on 2026-11-02 the exo seat read it in full at the start
of a run, in the file that prints the safe form, and typed the unsafe form
sixteen minutes later. Two credentials went into that run's own transcript.
Nothing stood in front of the command because there was no `tools/` to hold the
checker and no settings file to register it in. That is L-X5's own argument,
and it is why the ask was wiring rather than logic.

## PreToolUse: `tools/check-secret-print.py --hook`

Before any `Bash` call runs, the command is scanned for the shapes that have
actually printed a credential in this company — the `:-` trap, prefix-guessing
redaction, a client told to transcribe its own request, shell tracing with a
credential in scope, an unanchored names-only read of an env file, and the
environment dumped whole. A match returns `permissionDecision: deny` with
L-X5's safe form already written out for that variable, so the session can
retype the line without going to read the register.

Three properties, all of them asserted by
`tools/tests/test-hook-wiring.py`:

- **It cannot stop a seat from working.** `--hook` always exits 0; any internal
  error prints to stderr and allows the call. A guard that breaks the harness
  is worse than the failure it guards.
- **It never reads a value.** The checker decides from variable NAMES and shell
  shape alone. One of the wiring tests puts a fake `github_pat_` value in the
  environment and asserts it appears on neither of the guard's streams.
- **It allows the forms the rule asks for.** L-X5's own snippet, presence
  tests, `curl -H "Authorization: Bearer $T"`, moving a credential into another
  name, and this repository's own board helpers all pass untouched. A guard
  that refuses the lesson's safe form refuses the lesson.

## Two decisions this product made that HQ's copy did not

**The matcher is `Bash` and not also `Write|Edit|MultiEdit`.** Scanned against
this repository's own committed surfaces, the checker's name rule produces 34
findings and 22 of them are this product's vocabulary rather than credentials:
`$pass`, the assertion tally every suite in `cli/test/` prints on its last
line (12 sites, matched because the name contains `PASS`), and
`: "${BOARD_RUNTIME_TOKEN:?...}"`, the presence assertion six of the
`docs/agents/` board helpers open with (10 sites, matched as though `:?` were
`:-` — but `:?` hands its expansion to `:`, which discards it, so it prints
nothing and is the correct idiom). With the file tools in the matcher, the
engineer seat cannot edit its own test suites and no seat can edit `post.sh`,
and `--hook` deliberately honours no suppression marker, so there would be no
way out but to delete this file.

That cost buys nothing, because all four recorded incidents were commands typed
at a shell, which is also the only surface L-X5's clause names. A file's new
content has a reviewer — the diff, the pull request, and a file scan where
`L-X5-ALLOW` markers and `--baseline` both work. A command about to run has
none. So the command is the hook's and the file is the scan's.

**Two names are added with `--name`.** `CALLMEBOT_PHONE` and the `PHONE` it is
exposed as are repository secrets here and carry no credential word, so the
checker's name rule does not see them; it is the owner's phone number, and
nothing personal enters this repository's output. Every other secret name this
product uses is already covered, checked against
`.github/workflows/`: `ANTHROPIC_AUTH_TOKEN`, `CALLMEBOT_APIKEY`,
`BOARD_RUNTIME_TOKEN`, `CLAUDE_CODE_OAUTH_TOKEN`, `GH_TOKEN`,
`LANGFUSE_PUBLIC_KEY`, `LANGFUSE_SECRET_KEY`, `LINEAR_API_KEY`,
`OPENROUTE_API_KEY`, `SLACK_WEBHOOK_URL`.

## What is still missing, named rather than left to be discovered

- **The file scan has no gate.** The hook reads commands; nothing yet reads
  this repository's files on a schedule, because a CI job is a workflow and
  this seat may not write one. Handed to the project manager. By hand it is
  `python3 tools/check-secret-print.py --name CALLMEBOT_PHONE --name PHONE
  .github/workflows/*.yml docs/agents/*.sh docs/agents/*.py cli/test/*.sh
  deploy/*.sh` — note that the checker's own default paths are HQ's layout
  (`tools/`, `standards/`, `runtime/`, `site/`) and match almost nothing here,
  so the surfaces must be named.
- **`env > file` is not caught**, though `--help` says a bare `env`
  "piped or redirected somewhere" is. The pipe is caught, the redirect is not;
  measured, and asserted as a known gap in section 5 of the wiring test so that
  HQ fixing it shows up here as a failure.

## If it is wrong

`python3 tools/check-secret-print.py --command '<the line>'` shows the finding
on its own, and `--help` lists the shapes, the safe forms it will never flag,
and its stated limits. A false positive is a bug in the checker, not something
to work around: all four incidents happened to seats that knew the rule.

## Vendoring

`tools/check-secret-print.py` is a byte-for-byte copy of
`alexandrapaiz/alexandra-systems` `tools/check-secret-print.py` at `9b0e9e4`.
Do not edit it here. Its logic and its own tests are HQ's; the three findings
above are reported there, not patched here, so that a re-vendor stays one `cp`.
`tools/tests/test-hook-wiring.py` is this product's own and tests the wiring.

## What is not here

No permissions, no model pin, no environment. A seat's model and turn cap come
from its workflow, and its credentials from the job environment. This file is a
guard, not a configuration.
