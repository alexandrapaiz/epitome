# `.claude/` — the harness settings every seat of this product inherits

One hook, and it is the enforcement `docs/standards/lessons.md` L-X5 asks for
in its own closing clause: "a rule whose violation is a single shell idiom
cannot be enforced by a sentence, and must be enforced by something that reads
the command."

Until this directory existed, this repository had nowhere to put that. The rule
was vendored here and it was read; on 2026-11-02 the exo seat read it in full
at the start of a run, in the file that prints the safe form, and typed the
unsafe form sixteen minutes later. Two credentials went into that run's own
transcript. Nothing stood in front of the command because there was no `tools/`
to hold the checker and no settings file to register it in. That is L-X5's own
argument, and it is why the ask was wiring rather than logic.

## PreToolUse: `tools/check-secret-print.py --hook`

Before any `Bash` call runs, the command is scanned for the shapes that have
actually printed a credential in this company — the `:-` trap, prefix-guessing
redaction, a client told to transcribe its own request, shell tracing with a
credential in scope, an unanchored names-only read of an env file, and the
environment piped out whole. A match returns `permissionDecision: deny` with
L-X5's safe form already written out for that variable, so the session can
retype the line without going to read the register.

Three properties, all asserted by `tools/tests/test-hook-wiring.py`, which
reads the command out of `settings.json` rather than retyping it, because a
retyped command cannot see a registration that is wrong:

- **It cannot stop a seat from working.** `--hook` always exits 0; any internal
  error prints to stderr and allows the call. Malformed stdin, an empty
  payload, the wrong JSON type and an unknown tool all allow. A guard that
  breaks the harness is worse than the failure it guards.
- **It never reads a value.** The checker decides from variable NAMES and shell
  shape alone. One of the wiring tests puts a fake `github_pat_` value in the
  environment and asserts it appears on neither of the guard's streams.
- **It allows the forms the rule asks for.** L-X5's own snippet, presence
  tests, `curl -H "Authorization: Bearer $T"`, `curl -i`, moving a credential
  into another name, this repository's own board helpers, and this seat's
  ordinary work all pass untouched. A guard that refuses the lesson's safe form
  refuses the lesson.

## Why the matcher is `Bash` and not HQ's `Bash|Write|Edit|MultiEdit`

Not an oversight, and not a limitation of the checker. Its
`edit_suppressions()` handles the file tools properly: on the **edit** path it
honours `L-X5-ALLOW` markers and `tools/secret-print-baseline.txt`, and on the
**command** path it honours neither. That is the right distinction — a command
runs now and nothing reviews it; a file's new content has a diff, a pull
request and a scan.

It cannot be registered here, and the blocker is one file. The hook scans an
edit's content whatever the file's suffix, while the repository scan skips
markdown deliberately, "because the registers quote these shapes on purpose —
a lint that fails on the register is a lint nobody keeps" (`--help`). So a
full-file write of `docs/standards/lessons.md` is **denied**: the vendored
company register that *carries* L-X5 quotes every idiom it forbids, which is
what a register is for. Covering the file tools here would stop the exo seat
re-vendoring the rule this guard enforces, and no marker fixes it, because a
vendored copy may not be edited and a re-vendor would strip the markers.

All four recorded incidents were commands typed at a shell, which is also the
only surface L-X5's clause names. So the command is the hook's, and the file is
the repository scan's. Section 5 of the wiring test asserts this rather than
arguing it, and fails when HQ gives the edit path the markdown exemption the
scan already has — at which point the matcher should widen.

## `tools/secret-print-baseline.txt`

Scanned against this repository's own committed surfaces the checker reports
**34 findings in 11 distinct shapes, and not one of them is a leak**. All 34
are accepted in the baseline, each with a written reason, so the repository
scan starts at zero:

| what | sites | why it is reported |
|---|---|---|
| `"$pass"`, the assertion tally every suite in `cli/test/` prints last | 12 | the name contains `PASS` |
| `: "${BOARD_RUNTIME_TOKEN:?...}"`, the presence assertion six `docs/agents/` helpers open with | 10 | `:?` matched as though it were `:-`; it hands its expansion to `:`, which discards it |
| `echo "::add-mask::$auth"` and the `$GITHUB_ENV` write | 10 | registering a mask requires passing the value; the other is moving, not printing |
| `$key`, an apt signing key's **URL**, in the error naming which URL failed | 1 | the name is `key` and carries no `_URL` suffix |
| `$TOKEN_OUT`, this suite's own stub token, as a failing run's diagnostic | 1 | a real print of a fixture value |

The file keeps its two kinds apart on purpose. Three entries are findings the
checker is right about and this product keeps anyway — that is what the
mechanism is for. Eight are findings the checker is **wrong** about, and they
carry an instruction to delete them when HQ fixes the cause, because a stale
exemption for a bug that is gone hides the next real finding on the same line.

## Two names added with `--name`

`CALLMEBOT_PHONE`, and the `PHONE` it is exposed as, are repository secrets
here and carry no credential word, so the checker's name rule does not see
them. It is the owner's phone number, and nothing personal enters this
repository's output. Every other secret name this product uses is already
covered, checked against `.github/workflows/`: `ANTHROPIC_AUTH_TOKEN`,
`CALLMEBOT_APIKEY`, `BOARD_RUNTIME_TOKEN`, `CLAUDE_CODE_OAUTH_TOKEN`,
`GH_TOKEN`, `LANGFUSE_PUBLIC_KEY`, `LANGFUSE_SECRET_KEY`, `LINEAR_API_KEY`,
`OPENROUTE_API_KEY`, `SLACK_WEBHOOK_URL`.

## What is still missing, named rather than left to be discovered

- **The repository scan has no gate.** The hook covers what a seat runs in a
  session; nothing scans the tree on a schedule, which is what would catch a
  shape that arrived before this hook existed. A CI job is a workflow this seat
  may not write, so it is handed to the project manager. The invocation is at
  the top of `tools/secret-print-baseline.txt` and must name this repository's
  surfaces, because the checker's defaults are HQ's layout (`tools/`,
  `standards/`, `runtime/`, `site/`) and match almost nothing here. It exits 0
  today, so the gate can be added without fixing anything first.
- **`env > file` is not caught**, though `--help` says a bare `env` "piped or
  redirected somewhere" is. The pipe is caught, the redirect is not. Measured,
  and asserted as a known gap in section 6 of the wiring test so that HQ fixing
  it shows up here as a failure.

All three upstream findings — the `:?` match, the `PASS` name, and the
redirect — are reported to the exo seat, which owns the vendoring route to HQ.

## If it is wrong

`python3 tools/check-secret-print.py --command '<the line>'` shows the finding
on its own, and `--help` lists the shapes, the safe forms it will never flag,
and its stated limits. A false positive is a bug in the checker, not something
to work around: all four incidents happened to seats that knew the rule.

## Vendoring

`tools/check-secret-print.py` is a byte-for-byte copy of
`alexandrapaiz/alexandra-systems` `tools/check-secret-print.py` at `9b0e9e4`.
Do not edit it here; its logic and its own tests are HQ's, and the findings
above are reported there rather than patched here so that a re-vendor stays one
`cp`. `tools/tests/test-hook-wiring.py` and `tools/secret-print-baseline.txt`
are this product's own: the wiring, and what this product accepts.

## What is not here

No permissions, no model pin, no environment. A seat's model and turn cap come
from its workflow, and its credentials from the job environment. This file is a
guard, not a configuration.
