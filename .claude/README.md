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

Two halves, and they cover different things. The **hook** reads a command
before it runs, which is the only moment a typed shell line can be stopped. The
**scan** — `bash tools/scan-secret-print.sh` — reads what is already committed,
which is the only thing that catches a shape that arrived before the hook
existed. Both are asserted by `tools/tests/test-hook-wiring.py`, and the scan
is a script rather than a documented invocation because the documented
invocation drifted from the claim printed next to it within a day.

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

It cannot be registered here, and the measured reason is three files. A
full-file write of `docs/standards/lessons.md` is **denied**: the vendored
company register that *carries* L-X5 quotes every idiom it forbids, which is
what a register is for. Covering the file tools here would stop the exo seat
re-vendoring the rule this guard enforces, and no marker fixes it, because a
vendored copy may not be edited and a re-vendor would strip the markers.

**It is not a markdown problem, and this section said it was.** The earlier
version of this paragraph reasoned from the scan's own markdown exemption —
"because the registers quote these shapes on purpose" (`--help`) — and the
deny set does not line up with it. Writing eighteen real files of this
repository back at the hook, on `main` at `ebf9382`, six were denied and only
two were markdown: the other four were a `.txt` (this product's own baseline),
two `.sh` seat tools, and `cli/src/lib/runner.js`, product source. A markdown
exemption on the edit path would have unblocked the register and left the
baseline, the detector and the CLI refused.

Three of those six are allowed now, and the fix was not upstream: this
repository accepted their lines in `tools/secret-print-baseline.txt`, which the
edit path honours. What remains is the set no entry can reach — the vendored
register, the vendored checker, and the baseline itself, whose entries *are*
the quotations. A full-file write of the baseline is refused by **eleven**
findings and every one of them is one of its own accepted lines, so the
mechanism gets harder to use in exact proportion to how much it has been used.
That, rather than a suffix rule, is the thing to hand HQ.

All four recorded incidents were commands typed at a shell, which is also the
only surface L-X5's clause names. So the command is the hook's, and the file is
the repository scan's. Sections 5 and 8 of the wiring test assert this rather
than arguing it: section 8 prints the deny set from this checkout, so the day
the edit path changes, the list of acts this installation would lose is
measured instead of re-reasoned.

## The scan: `bash tools/scan-secret-print.sh`

One command, and it is a file rather than a line in a comment. Run it; it reads
every tracked file this checker can read as code, honours the baseline, and
answers 0, 1 or 2.

```
$ bash tools/scan-secret-print.sh
no L-X5 shape found (146 files, 41 accepted by tools/secret-print-baseline.txt)
secret-print scan: 146 tracked file(s), nothing unaccepted.
```

**It used to be a comment, and the comment was wrong twice.** This section
previously pointed at an invocation printed at the top of the baseline, under
the sentence "it exits 0 today". Copied, that line gave **40 findings and exit
1**, because it omitted `--baseline`. Added the flag and it still gave **exit
1**, because its hand-written glob list had never covered `docs/agents/stage.sh`
— two sites of a shape it had itself counted twelve of — nor any of `cli/src/`,
the whole product. A command in a comment is read by people and run by nothing,
so neither error could be noticed by anything but a reader copying it. That is
why the surfaces now come from `git ls-files` and why section 7 of the wiring
test executes this script.

## `tools/secret-print-baseline.txt`

Over the 146 tracked files the checker reports **41 findings in 13 distinct
source lines, and not one of them is a leak**. All 41 are accepted in the
baseline, each with a written reason, so the scan starts at zero:

| what | sites | why it is reported |
|---|---|---|
| `"$pass"`, the assertion tally the suites and one seat tool print last | 14 | the name contains `PASS` |
| `: "${BOARD_RUNTIME_TOKEN:?...}"`, the presence assertion five `docs/agents/` helpers open with | 10 | `:?` matched as though it were `:-`; it hands its expansion to `:`, which discards it |
| `echo "::add-mask::$auth"` and the `$GITHUB_ENV` write | 10 | registering a mask requires passing the value; the other is moving, not printing |
| the probe inputs in `docs/agents/x5probe.sh`, single-quoted and never run | 4 | the checker reads text, and a detector has to carry the shape it asks about |
| the git credential helper in `cli/src/lib/runner.js` | 1 | it prints the token to git, because that is a credential helper's contract |
| `$key`, an apt signing key's **URL**, in the error naming which URL failed | 1 | the name is `key` and carries no `_URL` suffix |
| `$TOKEN_OUT`, this suite's own stub token, as a failing run's diagnostic | 1 | a real print of a fixture value |

The file keeps three kinds apart on purpose. **Kind one** is findings the
checker is right about and this product keeps anyway — that is what the
mechanism is for, and the credential helper is the clearest case: there is no
form of a git credential helper that does not print the credential. **Kind two**
is findings the checker is wrong about, which carry an instruction to delete
them when HQ fixes the cause, because a stale exemption for a bug that is gone
hides the next real finding on the same line; `docs/agents/x5probe.sh` asks each
of them as a question so a fix upstream is noticed here. **Kind three** is a
line that is a quotation in a file whose job is to quote — the probe's own
inputs — which is neither of the other two and has a shorter life than either,
because a probe goes when the bug it measures goes.

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

- **The scan has no gate.** The hook covers what a seat runs in a session;
  nothing runs the scan on a schedule, which is what would catch a shape that
  arrived before this hook existed. A CI job is a workflow this seat may not
  write, so it is handed to the project manager, and the gate is now one line —
  `bash tools/scan-secret-print.sh` — rather than an invocation to copy out of
  a comment. That matters: the copyable version was wrong in two different ways
  at once, and the gate would have been written from it. The script exits 0
  today, so the gate can be added without fixing anything first.
- **`env > file` is not caught**, though `--help` says a bare `env` "piped or
  redirected somewhere" is. The pipe is caught, the redirect is not. Measured,
  and asserted as a known gap in section 6 of the wiring test so that HQ fixing
  it shows up here as a failure. **Of the two the redirect is the worse one**,
  which is the order it was reported in: a pipe shows matching lines in a
  transcript somebody has to read, and a redirect writes every variable in the
  environment to a file on disk, named by whoever typed it, that nothing expires.

Four upstream findings are reported to the exo seat, which owns the vendoring
route to HQ, and `docs/agents/x5probe.sh` asks each of them as a question so a
fix upstream is noticed here rather than leaving an exemption standing over a
bug that is gone. Two of the four are not what the first report of them said:

- **The `:?` match.** The fix is **not** an exemption for the form. Fed to the
  no-op `:` the expansion prints nothing; fed to `echo` it prints the value in
  full, which the exo seat proved in a shell on a dummy value, so a blanket
  exemption would open a real leak. What distinguishes the two is the command
  the expansion feeds, which X5-PRINT already models and X5-DEFAULT does not.
- **The `PASS` name**, 14 sites in 13 files. Unchanged, and the shape of the fix
  is the exclusion-suffix rule that already spares `_COUNT` and `_LEN`.
- **The redirect**, above.
- **The edit path and the baseline.** Not a false positive: a full-file write of
  `tools/secret-print-baseline.txt` is refused by eleven findings, every one of
  them a quotation of one of its own accepted entries. There is no marker that
  helps, because the entries are the quotations, so the exemption mechanism
  becomes unmaintainable in exact proportion to how much it is used.

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
