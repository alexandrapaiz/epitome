#!/usr/bin/env python3
# vendored-from: alexandrapaiz/alexandra-systems tools/check-secret-print.py @ 6ff45e0bdcef8f74e3efddb5b30bfab4e0787e89
# vendored-from: do not edit here. standards/secrets.md §5 makes the tool and
# vendored-from: the hook registration part of the invariant; re-vendor with HQ's
# vendored-from: tools/install-secret-hook.py.
"""Does this command print a secret? Asked before the command runs.

    tools/check-secret-print.py --command 'echo "$EXO_TOKEN"'
    tools/check-secret-print.py tools/check-actions-reach.sh
    tools/check-secret-print.py                 # the executable surfaces
    tools/check-secret-print.py --hook          # Claude Code PreToolUse, stdin JSON

WHY THIS IS A PROGRAM AND NOT A PARAGRAPH

standards/lessons.md L-X5 ("secrets: presence and length, never the value")
is written, carries its safe snippet verbatim, and is vendored into five
repositories. It has been violated four times, by two seats, on two
credentials, with the rule open in the editor at the time:

  Incident 3   2026-09-19  EXO_TOKEN            prefix-guessing `sed`
  Incident 4   2026-09-20  EXO_TOKEN            ${VAR:-NO}, one day after L-X5
  Incident 15  2026-10-12  EXO_TOKEN            both at once (PR #158)
  (unnumbered) 2026-10-12  BOARD_RUNTIME_TOKEN  ${VAR:-NO}, same day, HQ's PM

L-X5's closing clause is this file's specification: "a rule whose violation
is a single shell idiom cannot be enforced by a sentence, and must be
enforced by something that reads the command." Incident 15's corrective
action 2 names the mechanism: a pre-execution check on the seat's own shell.
So this runs in three places, cheapest first:

  --hook       before the command runs, as a PreToolUse hook (.claude/settings.json)
  file scan    in CI, over the repository's executable surfaces
  --command    by hand, when a seat is unsure about a line it is about to type

WHAT IT LOOKS FOR

  X5-DEFAULT   ${<SECRET>:-anything} or ${<SECRET>-anything}, written here
               with the placeholder brackets L-X5 and Incident 15 use so
               that this file does not trip its own scan. The trap L-X5 names
               by name: it reads as "print a placeholder instead" and it
               expands to the variable's VALUE whenever the variable is set,
               which is the case every secret check runs in.
  X5-PRINT     a value expansion of a secret-named variable ("$SECRET",
               "${SECRET}", "${SECRET:-}", "${!name}") inside a command that
               writes to output: echo, printf, cat, tee, sed, awk, jq, ...
  X5-REDACT    a redaction filter: a substitution whose pattern guesses at
               credential prefixes (`gh[pous]_`, `ghp_`, `sk-`, `xox...`) or
               whose replacement is a mask (REDACTED, ***). Redaction is not
               a safety layer, it is a guess about a format, and in Incidents
               3 and 15 the guess missed `github_pat_`, the prefix the PAT
               actually used.
  X5-ENVDUMP   `printenv SECRET`, or a bare `env` / `set` piped or redirected
               somewhere. The whole environment is every secret at once.
  X5-TRACE     shell tracing turned on (`set -x`, `set -o xtrace`, `set -eux`,
               an interpreter invoked `-x`) while a secret is in scope. The
               tracer echoes the command the shell is about to run with every
               expansion already done, so the safe header form
               (`-H "Authorization: Bearer $T"`) prints the token anyway.
               Incident 18: HQ's PM traced four board writes, every one of
               them in the safe form, and `BOARD_RUNTIME_TOKEN` appeared in
               full four times. The checker was correct about the command and
               silent about the flag.
  X5-ENVNAMES  a names-only read of an env file by a filter that is not
               anchored to the start of a line: `cut -d= -f1`,
               `awk -F= '{print $1}'`, `sed 's/=.*//'`. It reads as "names
               only", and it is, for every value that fits on one line. A
               multi-line value's continuation lines carry no `=` at all, so
               the filter passes them through verbatim. Incident 20: this
               seat ran `cut -d= -f1 /srv/asc/env.infisical` to list 45 names
               and printed four lines of `NPM_RECOVERY_CODES` with them.
  X5-VERBOSE   an HTTP client asked to echo the request it is making, on a
               line that expands a secret: `curl -v`, `-sv`, `--trace*`,
               `wget --debug`, `httpie -v`. The credential is not in the
               output because anything printed it — it is in the output
               because the client was told to transcribe its own request
               headers, and `> Authorization: Bearer <value>` is one of them.
               This file named it as a limit it could not see until
               2026-10-23, when the centralizer seat did it to its own
               session transcript diagnosing a dead board route, with this
               checker installed as a hook and the hook correctly silent: the
               line it read was the allowed form, `curl -H "Authorization:
               Bearer $T"`, with one extra letter on an earlier flag.

WHAT IT MUST NEVER FLAG, because these are the forms the rule asks for

  printf 'T present: %s length: %s\n' "${T:+yes}" "${#T}"   L-X5's own snippet
  [ -n "$T" ] / [ -z "$T" ] / test -n "$T"                  presence tests
  V="$T" / export V="$T" / GH_TOKEN="$T" gh api ...         moving, not printing
  curl -H "Authorization: Bearer $T"                        using the credential
  set -euo pipefail / set -a / set +x                       no tracing turned on
  grep -oE '^[A-Za-z_][A-Za-z0-9_]*=' f | tr -d =           names, anchored
  cut -d= -f2-                                              a value read, which
                                                            the author knows
  curl -s / -f / -i / --fail-with-body                     -i prints the
                                                           RESPONSE headers;
                                                           only the request
                                                           carries the bearer

tools/check-actions-reach.sh is the repository's reference for all four of
those shapes and is a standing false-positive test case for this checker
(tools/tests/test_secret_print.py).

WHICH NAMES COUNT AS SECRET

The company's own names (EXO_TOKEN, BOARD_RUNTIME_TOKEN, PROJECTS_TOKEN,
CLAUDE_CODE_OAUTH_TOKEN, OPENROUTE_API_KEY, SLACK_WEBHOOK_URL, ...) plus any
name with a credential word in it (TOKEN, SECRET, KEY, PASSWORD, PAT,
WEBHOOK, CREDENTIAL, COOKIE), minus names whose last word says they hold a
label rather than a value (_NAME, _PATH, _FILE, _ID, _DIR, _URL, _LENGTH).
`--name X` adds one; `--list-names` prints the built-in set.

WHAT THE DEFAULT SCAN COVERS

`tools/`, `standards/`, `runtime/`, `.github/workflows/` and `site/`, by
suffix (.sh .bash .zsh .yml .yaml .py) plus anything with a `#!` line: the
files that run. Markdown is scanned only when named on the command line,
because the registers quote these shapes on purpose — `docs/agents/incidents.md`
and `standards/lessons.md` are where the four incidents are written down, and
a lint that fails on the register is a lint nobody keeps. Pointing it at them
is still worth doing once: it finds both recorded commands in the prose.

LIMITS, stated so they are not mistaken for coverage

It reads text, not a shell. X5-TRACE asks whether a secret is in scope in the
same text, so `set -x` in one file and the credential in a function it sources
is missed. X5-ENVNAMES recognises an env file by its path or by `--format=dotenv`,
so a dotenv stream given some other name is missed. It does not expand
`${!indirect}` to a name, does
not follow a value into a variable that is not secret-named (`v="$T"; echo
"$v"` is missed), does not read heredoc bodies as commands, and does not know
which flags of a client it has never heard of transcribe a request. It is a
habit interrupter for the five shapes that have actually happened here, not a
proof of safety.

SUPPRESSION, IN TWO FORMS, BOTH OF WHICH LEAVE A REASON BEHIND

A line, or the line above it, carrying `L-X5-ALLOW` with a reason is skipped
in file scans. `--no-allow` ignores the markers, which is how the markers get
audited. For findings the checker is right about and the company keeps
anyway, `--baseline tools/secret-print-baseline.txt` holds them one per line
with the reason in the file's own comments. A marker on the line that opens a
``` fence covers that whole block, which is the form a register needs.

Neither form applies to a COMMAND: one about to run has no reviewer. Both
apply to an EDIT, which the diff and the repository scan still see, and an
edit to prose (.md, .markdown, .rst) or to a checker's own `*baseline.txt` is
not denied at all — the file scan already holds that markdown is quoted on
purpose, and until 2026-11-02 the hook held the opposite, which denied the
register that carries this rule, the standard that explains the guard, and the
guard's own exemptions file.

usage:
  tools/check-secret-print.py [FILE...] [--quiet] [--json] [--no-allow]
                              [--baseline FILE] [--show-accepted]
  tools/check-secret-print.py --command 'STRING'
  tools/check-secret-print.py --hook
  tools/check-secret-print.py --list-names
  tools/check-secret-print.py --name MY_OWN_SECRET [FILE...]

exit 0 = nothing found    1 = findings    2 = could not run
         --hook always exits 0 and answers in JSON, so a broken guard can
         never be the thing that stops a seat from working.
"""
import fnmatch
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# The company's own credential names, from .github/workflows/*.yml `secrets.`
# references and tools/check-actions-reach.sh's candidate list. Names only:
# this file never reads a value, including the values of these.
KNOWN_SECRET_NAMES = {
    "ACTIONS_RUNTIME_TOKEN",
    "ANTHROPIC_API_KEY",
    "BOARD_RUNTIME_TOKEN",
    "CLAUDE_CODE_OAUTH_TOKEN",
    "DEFAULT_WORKFLOW_TOKEN",
    "EXO_TOKEN",
    "GH_TOKEN",
    "GITHUB_TOKEN",
    "INFISICAL_TOKEN",
    "KIMI_API_KEY",
    "OPENROUTE_API_KEY",
    "OPENROUTER_API_KEY",
    "PROJECTS_TOKEN",
    "SLACK_WEBHOOK_URL",
}

# A name with one of these words in it holds a credential.
SECRET_WORDS = {
    "TOKEN", "TOKENS", "SECRET", "SECRETS", "PASSWORD", "PASSWD", "PASS",
    "KEY", "APIKEY", "PAT", "WEBHOOK", "CREDENTIAL", "CREDENTIALS",
    "COOKIE", "BEARER", "AUTH",
}

# ...unless its last word says it holds a label, a location or a count. The
# known names above win over this list, which is why SLACK_WEBHOOK_URL is a
# secret and BOARD_API_URL is not.
LABEL_SUFFIXES = {
    "NAME", "NAMES", "PATH", "FILE", "DIR", "ID", "IDS", "URL", "URI",
    "PREFIX", "SUFFIX", "LEN", "LENGTH", "COUNT", "SET", "TYPE", "KIND",
    "SOCK", "ALGO", "FORMAT",
}

# Commands that put their arguments where someone can read them.
PRINTERS = {
    "echo", "printf", "print", "cat", "tee", "head", "tail", "sed", "awk",
    "jq", "tr", "cut", "paste", "sort", "uniq", "grep", "egrep", "fgrep",
    "logger", "say", "write", "yq", "xxd", "base64", "od", "hexdump",
}

# Words that stand in front of the real command word.
LEADING_SKIP = {
    "if", "then", "else", "elif", "fi", "do", "done", "while", "until",
    "for", "in", "case", "esac", "{", "}", "(", ")", "!", "time", "sudo",
    "command", "exec", "eval", "nohup", "-", "&&", "||", "|", ";",
}

ASSIGN = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*=")
YAML_KEY = re.compile(r"^-?\s*[A-Za-z_][A-Za-z0-9_-]*:$")

# `${...}` is parsed rather than matched, because the fallback chain
# `${A:-${B:-}}` (tools/open-manifest-prs.sh, with two real token names)
# has a nested brace, and a naive `[^}]*` reads its default as `${B:-`.
BRACE_START = re.compile(r"\$\{(?!\{)")
NAME_THEN_OP = re.compile(r"^(!?)([A-Za-z_][A-Za-z0-9_]*)(:?[-+?=]|)")
# A default that is only other expansions is a fallback chain, not a
# placeholder: `${A:-$B}` means "A, or else B", and nothing is being printed.
EXPANSION_ONLY = re.compile(r"\$\{[^}]*\}|\$\(.*?\)|\$[A-Za-z_][A-Za-z0-9_]*|\s")
# `$VAR` with no braces at all.
BARE_EXPANSION = re.compile(r"\$([A-Za-z_][A-Za-z0-9_]*)")
# `${{ secrets.X }}` is Actions injecting a value into the environment, which
# is how a secret is supposed to arrive. Not a print.
ACTIONS_INJECTION = re.compile(r"\$\{\{\s*secrets\.")

# One substitution, any common delimiter, pattern and replacement separate.
SUBSTITUTION = re.compile(
    r"\bs(?P<d>[/|,#:!@])"
    r"(?P<pat>(?:\\.|(?!(?P=d)).)*)(?P=d)"
    r"(?P<rep>(?:\\.|(?!(?P=d)).)*)(?P=d)"
)
# The prefixes a redaction filter guesses at, including the bracket form
# Incident 15 used (`gh[pous]_`), and the one both guesses missed.
CREDENTIAL_PREFIX = re.compile(
    r"gh\[[A-Za-z]*\]_|gh[pousr]_|github_pat_|\bsk-|\bsk_live|xox[abprs]"
    r"|AKIA|glpat-|ya29\."
)
MASK = re.compile(r"^\s*(?:\\?[\"']?)(?:REDACTED|redacted|MASKED|masked|HIDDEN"
                  r"|hidden|\*{3,}|X{3,}|x{3,}|<[^>]*redact[^>]*>)")
FILTER_COMMAND = re.compile(r"\b(sed|awk|perl|gawk|ruby|python3?)\b")

# The environment is every secret at once. `env` and `set` are only a dump
# when they are the command word and their output goes somewhere.
DUMP_VERBS = {"printenv", "env", "set", "export"}

# X5-TRACE: the shell's own tracer prints the command it is about to run with
# every expansion already done, so it defeats the safe form rather than the
# unsafe one. `set -x`, `set -ex`, `set -euxo pipefail`, `set -o xtrace`, and
# an interpreter invoked with the flag. `set +x` turns it off and is never a
# finding, which is why the dash is required.
TRACE_ON = re.compile(
    r"(?:^|[;&|(]|\s)set\s+-[A-Za-z]*x[A-Za-z]*(?:\s|;|$)"
    r"|(?:^|[;&|(]|\s)set\s+-o\s+xtrace\b"
    r"|(?:^|[;&|(]|\s)(?:ba|z|k|da)?sh\s+(?:-[A-Za-z]*x[A-Za-z]*(?:\s|;|$)"
    r"|-o\s+xtrace\b)"
)
# A secret is in scope when the text expands one by name, or when it sources
# the environment file that holds all of them. Either is enough for a tracer
# to echo a credential.
ENV_FILE_SOURCED = re.compile(
    r"(?:^|[;&|(]|\s)(?:\.|source)\s+[\"']?(?:[^\s\"';|&]*/)?"
    r"(?:\.env|env|env\.[A-Za-z0-9_.-]+|[A-Za-z0-9_.-]+\.env)[\"']?(?:\s|;|$)"
)

# X5-ENVNAMES: a names-only read of dotenv text that is not anchored to the
# start of a line. Three parts, all three required: the text is dotenv, the
# filter splits on `=`, and it keeps only what is left of the first one.
DOTENV_SOURCE = re.compile(
    r"--format=dotenv|\bdotenv\b"
    r"|/\.?env(?:\.[A-Za-z0-9_-]+)?(?:$|[\s\"';|&])"
    r"|(?:^|[\s\"'=|&;])\.env(?:$|[\s\"';|&])"
    r"|[A-Za-z0-9_-]+\.env(?:$|[\s\"';|&])"
)
EQUALS_SEPARATOR = re.compile(r"-d\s*[\"']?=[\"']?|-F\s*[\"']?=[\"']?")
FIRST_FIELD_ONLY = re.compile(r"-f\s*[\"']?1[\"']?(?:$|[\s\"';|&])"
                              r"|print\s+\$1(?:$|[\s,;}])")
# `sed 's/=.*//'` is both halves at once: it splits on the first `=` and keeps
# the left side, and a line with no `=` comes out whole.
STRIP_FROM_EQUALS = re.compile(r"s(?P<d>[/|,#:!@])=\.\*\$?(?P=d)(?P=d)")

# A bare word on the traced line itself: `bash -x tools/secrets.sh get
# EXO_TOKEN` hands a credential to a script it is tracing, and the name is
# the only thing in the text that says so.
WORD = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")
# Clients that transcribe their own request when asked, and the flags that ask.
# Per client, because the flag that does it is not the same letter twice:
# curl's `-v` prints `> Authorization: ...`, wget's `-v` prints nothing of the
# sort and its `--debug` does, and httpie's `-v` prints the whole request.
# `-i` is deliberately absent everywhere: it prints the RESPONSE headers, and
# the bearer is only ever in the request.
#
# (longflags, the short letter that may arrive clustered)
VERBOSE_CLIENTS = {
    "curl": ({"--verbose", "--trace", "--trace-ascii", "--trace-all",
              "--trace-config", "--libcurl"}, "v"),
    "wget": ({"--debug"}, "d"),
    "http": ({"--verbose", "--all"}, "v"),
    "https": ({"--verbose", "--all"}, "v"),
    "httpie": ({"--verbose", "--all"}, "v"),
}
CLUSTERED_SHORT = re.compile(r"^-[A-Za-z]+$")

ALLOW_MARKER = re.compile(r"L-X5-ALLOW")

# A heredoc body is data, not commands. `cat <<\'EOF\'` expands nothing at all
# (a quoted delimiter is the shell's own "take this literally"), and the body
# of an unquoted one only reaches a reader when the command it feeds prints.
# Without this, writing a file whose text happens to contain a flagged line —
# a baseline entry, a test case, a lesson quoting the idiom — reads as running
# that line. It denied three of this seat's own commands on 2026-10-18.
HEREDOC_OPEN = re.compile(r"<<(?P<dash>-?)\s*(?P<q>[\'\"]?)"
                          r"(?P<delim>[A-Za-z_][A-Za-z0-9_]*)(?P=q)")

SAFE_FORM = ("printf '%s present: %%s length: %%s\\n' "
             '"${%s:+yes}" "${#%s}"')

SCAN_DIRS = ("tools", "standards", "runtime", ".github/workflows", "site")
SCAN_SUFFIXES = (".sh", ".bash", ".zsh", ".yml", ".yaml", ".py")

# THE FILE SCAN AND THE HOOK DISAGREED ABOUT MARKDOWN, AND THE HOOK WON
# (2026-11-02, re-measured by epitome's exo and routed here by the PM).
#
# `default_targets()` above decides this question one way and says why: a
# markdown file is read only when a caller names it, "because the registers
# quote these shapes on purpose". The hook decided it the other way, because
# it had no predicate at all — every edit was read as a command. The cost is
# the one no checker should be able to impose: the register that CARRIES L-X5,
# the standard that EXPLAINS the guard, and the guard's OWN exemptions file
# were each denied by their own entries, so the next hand that amends L-X5 is
# stopped by the rule that entry documents. Measured on this box before the
# fix, with the shape a register entry actually has (a fenced block):
#
#   standards/lessons.md             Edit  -> deny
#   standards/secrets.md             Edit  -> deny
#   tools/secret-print-baseline.txt  Edit  -> deny
#
# A prose file is quoted, not run: nothing executes a sentence, and this rule
# flags the EXPANSION of a secret-named variable rather than a literal value,
# so a denial here cannot be protecting a credential. What it was protecting
# against was somebody writing a runnable file, and that is a suffix question.
#
# Two things keep this narrow. It is the EDIT path only -- a `Bash` command
# that writes prose is still a command, still unreviewed, still denied. And
# the register stays scannable: `tools/check-secret-print.py standards/lessons.md`
# reads it exactly as before, which is the audit this exemption answers to.
PROSE_SUFFIXES = (".md", ".markdown", ".rst")
# A checker's exemptions register is a list of the shapes it accepts, so every
# line in it is the idiom by construction. `tools/secret-print-baseline.txt` is
# this guard's; the suffix rule is written once for all of this repository's
# `*-baseline.txt` files rather than as one hardcoded path, because the next
# checker's baseline would otherwise arrive with the same defect.
EXEMPTION_REGISTER = "baseline.txt"


def quotes_rather_than_runs(path):
    """Is an edit to this path a quotation rather than a command?

    True for prose and for a checker's own exemptions register; False for
    everything the file scan reads, and for a path this cannot recognise --
    an unknown suffix stays guarded, because the failure that matters is the
    one where a new runnable file slips through.
    """
    name = os.path.basename(str(path or "")).lower()
    return name.endswith(PROSE_SUFFIXES) or name.endswith(EXEMPTION_REGISTER)


class Finding:
    def __init__(self, code, name, why, line_no, line, path=None):
        self.code = code
        self.name = name
        self.why = why
        self.line_no = line_no
        self.line = line.rstrip("\n")
        self.path = path

    @property
    def fix(self):
        if self.code in ("X5-DEFAULT", "X5-PRINT", "X5-ENVDUMP") and self.name:
            return SAFE_FORM % (self.name, self.name, self.name)
        if self.code == "X5-VERBOSE":
            return ("drop the verbose flag: the client transcribes the request "
                    "headers it sent, and the credential is one of them. Read "
                    "the status and the body instead, e.g. "
                    "`-o /tmp/out.json -w '%{http_code}\\n'`")
        if self.code == "X5-REDACT":
            return ("drop the filter; report presence and length instead: "
                    + (SAFE_FORM % ("TOKEN", "TOKEN", "TOKEN")))
        if self.code == "X5-TRACE":
            return ("drop the -x, or fence the credential: `set +x` before the "
                    "command and `set -x` after it")
        if self.code == "X5-ENVNAMES":
            return ("anchor the read to the start of a line, so a multi-line "
                    "value's continuation lines cannot match: "
                    "grep -oE '^[A-Za-z_][A-Za-z0-9_]*=' FILE | tr -d =")
        return ""

    def as_dict(self):
        return {"code": self.code, "name": self.name, "why": self.why,
                "path": rel(self.path) if self.path else None,
                "line": self.line_no,
                "source": self.line.strip(), "fix": self.fix}

    def render(self, where):
        head = f"{where}:{self.line_no}: {self.code}  {self.why}"
        body = f"    {self.line.strip()}"
        out = [head, body]
        if self.fix:
            out.append(f"    fix: {self.fix}")
        return "\n".join(out)


def is_secret_name(name, extra=()):
    """Names only. This never looks at a value, including to decide this."""
    upper = name.upper()
    if upper in KNOWN_SECRET_NAMES or upper in {e.upper() for e in extra}:
        return True
    words = upper.split("_")
    if not any(w in SECRET_WORDS for w in words):
        return False
    if words[-1] in LABEL_SUFFIXES:
        return False
    return True


class Expansion:
    """One `${...}`, parsed: which variable, which operator, what default."""

    def __init__(self, name, op, default, indirect, text):
        self.name = name
        self.op = op                  # '', ':-', '-', ':+', '+', ':=', ':?'
        self.default = default
        self.indirect = indirect      # ${!name}
        self.text = text

    @property
    def yields_value(self):
        """Can this expansion put the variable's value on the line?

        `${V:+yes}` and `${#V}` cannot, which is why L-X5's safe form is built
        out of them. Everything else can.
        """
        return self.op not in (":+", "+")

    @property
    def is_placeholder_default(self):
        """`${V:-NO}`: a default that is a literal, so the author believed the
        expansion would print the literal. It prints the value instead."""
        if self.op not in (":-", "-", ":=", ":?"):
            return False
        return EXPANSION_ONLY.sub("", self.default) != ""


def literal_spans(text):
    """Character ranges the shell does not expand: everything inside a pair of
    single quotes, when those quotes are not themselves inside double quotes.

    `grep 'mask::$<SECRET>' file` expands nothing — the pattern is one
    literal word — and the first version of this checker denied exactly that
    command as an X5-PRINT, in this seat's own run on 2026-10-18. The
    converse matters as much: inside double quotes a single quote is an
    ordinary character, so `echo "it's $<SECRET>"` still expands and still
    prints, and must still be a finding. (Placeholder brackets here for the
    reason the rest of this file uses them: so the file does not trip its own
    scan.)
    """
    spans, quote, start = [], "", 0
    for i, ch in enumerate(text):
        if quote == "'":
            if ch == "'":
                spans.append((start, i))
                quote = ""
        elif quote == '"':
            if ch == '"':
                quote = ""
        elif ch == "'":
            quote, start = "'", i
        elif ch == '"':
            quote = '"'
    if quote == "'":                              # unterminated: to end of line
        spans.append((start, len(text)))
    return spans


def expansions(text, skip_literal=False):
    """Every `${...}` on the line, with balanced braces. Also `$VAR`.

    With `skip_literal`, expansions inside single quotes are left out, which
    is what the shell does with them. The X5-DEFAULT rule deliberately does
    not pass it: the `:-` trap is the wrong thing to write down even in a
    quoted example, because the next reader copies it out of the quotes.
    """
    out = []
    literal = literal_spans(text) if skip_literal else []

    def inside_literal(at):
        return any(lo < at < hi for lo, hi in literal)

    def escaped(at):
        """A backslash before the `$` suppresses the expansion, in a heredoc
        and inside double quotes alike. `runtime/board/install.sh`'s help text
        prints the variable's name on purpose this way, and the first version
        of the heredoc rule read it as printing the value."""
        n = 0
        while at - n - 1 >= 0 and text[at - n - 1] == "\\":
            n += 1
        return n % 2 == 1

    for m in BRACE_START.finditer(text):
        i = m.end()
        depth = 1
        while i < len(text) and depth:
            if text[i] == "{":
                depth += 1
            elif text[i] == "}":
                depth -= 1
                if not depth:
                    break
            i += 1
        inner = text[m.end():i]
        if inner.startswith("#"):
            continue                              # ${#V}: a length, never a value
        if inside_literal(m.start()) or escaped(m.start()):
            continue
        nm = NAME_THEN_OP.match(inner)
        if not nm:
            continue
        indirect, name, op = nm.group(1) == "!", nm.group(2), nm.group(3)
        out.append(Expansion(name, op, inner[nm.end():], indirect,
                             text[m.start():i + 1]))
    for m in BARE_EXPANSION.finditer(text):
        if inside_literal(m.start()) or escaped(m.start()):
            continue
        out.append(Expansion(m.group(1), "", "", False, m.group(0)))
    return out


def split_quoted(text, separators):
    """Split on unquoted separators, keeping each piece's trailing separator.

    Quote-aware, because `rows="$rows|set|$x"` is one assignment and not a
    `set` being piped (tools/check-actions-reach.sh:123 said otherwise for the
    first draft of this file). The cost is the stated limit: a command inside
    a quoted string, as in a `git credential.helper` one-liner or `bash -c`,
    is not read as a command.
    """
    out, cur, quote = [], [], ""
    for ch in text:
        if quote:
            cur.append(ch)
            if ch == quote:
                quote = ""
        elif ch in "'\"":
            quote = ch
            cur.append(ch)
        elif ch in separators:
            out.append(("".join(cur), ch))
            cur = []
        else:
            cur.append(ch)
    out.append(("".join(cur), ""))
    return out


def segments(text):
    """One line as (command text, the separator that ended it) pairs."""
    return split_quoted(text, ";&|\n")


def tokens(segment):
    """Words, with a quoted string counting as one word."""
    return [t for t, _ in split_quoted(segment, " \t") if t.strip()]


def command_word(segment):
    """The command a segment actually runs, past `if`, `sudo` and assignments."""
    for tok in tokens(segment):
        bare = tok.strip("\"'`()")
        if not bare:
            continue
        if bare in LEADING_SKIP or YAML_KEY.match(tok):
            continue
        if ASSIGN.match(bare):
            continue
        if bare.startswith("-"):
            continue
        return os.path.basename(bare)
    return ""


def heredoc_bodies(text):
    """Line number -> (the command the body feeds, does the shell expand it).

    Only openers outside single quotes count, so a `<<` inside a pattern is
    not read as one. Several heredocs on one command line are served in the
    order they were opened, which is the order the shell reads them in.
    """
    bodies, pending, current = {}, [], None
    for i, line in enumerate(text.splitlines(), start=1):
        if current is not None:
            delim, dash, owner, expands = current
            closed = (line.strip() if dash else line.rstrip("\n")) == delim
            if closed:
                current = pending.pop(0) if pending else None
                continue
            bodies[i] = (owner, expands)
            continue
        literal = literal_spans(line)
        owner = command_word(segments(line)[0][0])
        for m in HEREDOC_OPEN.finditer(line):
            if any(lo < m.start() < hi for lo, hi in literal):
                continue
            opened = (m.group("delim"), bool(m.group("dash")), owner,
                      m.group("q") == "")
            if current is None:
                current = opened
            else:
                pending.append(opened)
    return bodies


def scan_text(text, extra=(), line_offset=0):
    """The whole detector. Text in, findings out; no side effects, no values."""
    findings = []
    bodies = heredoc_bodies(text)
    # X5-TRACE needs one fact about the whole text rather than the line: is
    # there a credential here for the tracer to echo? Either the text names one
    # by expanding it, or it sources the environment file that holds all of
    # them. Without this the rule would flag every `set -ex` in the repository.
    secret_in_scope = bool(ENV_FILE_SOURCED.search(text)) or any(
        is_secret_name(exp.name, extra)
        for exp in expansions(text) if not exp.indirect)
    for n, line in enumerate(text.splitlines(), start=1):
        i = n + line_offset
        # `${{ secrets.X }}` is YAML interpolation, not a shell expansion.
        line_for_shell = ACTIONS_INJECTION.sub("${{ ", line)

        if n in bodies:
            owner, expands = bodies[n]
            if not expands:
                continue                          # <<\'EOF\': literal, by the shell
            if owner in PRINTERS:
                for exp in expansions(line_for_shell, skip_literal=True):
                    if (exp.yields_value and is_secret_name(exp.name, extra)
                            and not exp.is_placeholder_default):
                        findings.append(Finding(
                            "X5-PRINT", exp.name,
                            f"`{owner}` is reading a heredoc that expands "
                            f"{exp.name} to its value, and writes it where it "
                            f"can be read",
                            i, line))
            # The trap is still the trap inside a heredoc, printed or not.
            for exp in expansions(line_for_shell):
                if (not exp.indirect and is_secret_name(exp.name, extra)
                        and exp.is_placeholder_default):
                    findings.append(Finding(
                        "X5-DEFAULT", exp.name,
                        f"{exp.text} expands to {exp.name}'s value whenever "
                        f"{exp.name} is set, which is the case a secret check "
                        f"runs in",
                        i, line))
            continue

        # X5-DEFAULT: the named trap, wherever it appears. A literal default is
        # wrong even in a test (`[ -n "${T:-NO}" ]` is always true), so this
        # one does not ask whether the line prints.
        for exp in expansions(line_for_shell):
            if exp.indirect or not is_secret_name(exp.name, extra):
                continue
            if exp.is_placeholder_default:
                findings.append(Finding(
                    "X5-DEFAULT", exp.name,
                    f"{exp.text} expands to {exp.name}'s value whenever "
                    f"{exp.name} is set, which is the case a secret check "
                    f"runs in",
                    i, line))

        segs = segments(line_for_shell)
        for seg, sep in segs:
            cmd = command_word(seg)

            # X5-PRINT: a value expansion inside something that writes output.
            if cmd in PRINTERS:
                for exp in expansions(seg, skip_literal=True):
                    if exp.indirect:
                        findings.append(Finding(
                            "X5-PRINT", "",
                            f"`{cmd}` prints an indirect expansion "
                            f"({exp.text}), whose target this checker cannot "
                            f"resolve; it may be a credential",
                            i, line))
                    elif (exp.yields_value
                          and is_secret_name(exp.name, extra)
                          and not exp.is_placeholder_default):
                        findings.append(Finding(
                            "X5-PRINT", exp.name,
                            f"`{cmd}` writes its arguments where they can be "
                            f"read, and {exp.name} is expanded to its value "
                            f"here",
                            i, line))

            # X5-VERBOSE: the client was told to transcribe its own request,
            # and the request carries the credential.
            if cmd in VERBOSE_CLIENTS:
                longs, short = VERBOSE_CLIENTS[cmd]
                words = [w.strip("\"'") for w in tokens(seg)[1:]]
                asked = any(w in longs or any(w.startswith(l + "=") for l in longs)
                            for w in words) or any(
                    CLUSTERED_SHORT.match(w) and short in w[1:] for w in words)
                if asked:
                    for exp in expansions(seg, skip_literal=True):
                        if (exp.yields_value
                                and is_secret_name(exp.name, extra)
                                and not exp.is_placeholder_default):
                            findings.append(Finding(
                                "X5-VERBOSE", exp.name,
                                f"`{cmd}` was asked to print the request it "
                                f"sends, and {exp.name} is expanded into that "
                                f"request here, so the value is transcribed "
                                f"into the output",
                                i, line))

            # X5-ENVDUMP: the environment is every secret at once.
            if cmd in DUMP_VERBS:
                words = [w.strip("\"'") for w in tokens(seg)[1:]]
                if cmd == "printenv":
                    for w in words:
                        if not w.startswith("-") and is_secret_name(w, extra):
                            findings.append(Finding(
                                "X5-ENVDUMP", w,
                                f"`printenv {w}` prints the value", i, line))
                elif (words in ([], ["-p"])) and (sep == "|" or ">" in seg):
                    # A bare `env`, `set` or `export -p` whose output is going
                    # somewhere. `set -a` and `set -euo pipefail` carry flags
                    # and dump nothing, which is most of runtime/.
                    findings.append(Finding(
                        "X5-ENVDUMP", "",
                        f"a bare `{cmd}` sent somewhere dumps every variable "
                        f"in the environment, secrets included", i, line))

        # X5-TRACE: the tracer prints what the shell is about to run, with
        # every expansion already done, so it defeats the safe form. Incident
        # 18: four board writes, all four in the header form, the token in
        # full four times.
        if TRACE_ON.search(line_for_shell) and (
                secret_in_scope
                or any(is_secret_name(w, extra) for w in
                       WORD.findall(line_for_shell))):
            findings.append(Finding(
                "X5-TRACE", "",
                "shell tracing is turned on here and a credential is in "
                "scope: the tracer echoes each command with its expansions "
                "already performed, so even the safe header form prints the "
                "value",
                i, line))

        # X5-ENVNAMES: a names-only read of dotenv text that is not anchored
        # to the start of a line. It is names-only for every value that fits
        # on one line, and a multi-line value's continuation lines carry no
        # `=`, so the filter passes them through whole.
        if DOTENV_SOURCE.search(line_for_shell) and (
                STRIP_FROM_EQUALS.search(line_for_shell)
                or (EQUALS_SEPARATOR.search(line_for_shell)
                    and FIRST_FIELD_ONLY.search(line_for_shell))):
            findings.append(Finding(
                "X5-ENVNAMES", "",
                "this reads an env file for its names, but the filter is not "
                "anchored to the start of a line: every continuation line of "
                "a multi-line value has no `=` and comes through verbatim",
                i, line))

        # X5-REDACT: redaction is a guess about a format, not a safety layer.
        if FILTER_COMMAND.search(line_for_shell):
            for m in SUBSTITUTION.finditer(line_for_shell):
                pat, rep = m.group("pat"), m.group("rep")
                if CREDENTIAL_PREFIX.search(pat):
                    findings.append(Finding(
                        "X5-REDACT", "",
                        "this redaction pattern guesses at credential "
                        "prefixes; Incidents 3 and 15 both guessed and both "
                        "missed `github_pat_`, the prefix the PAT used",
                        i, line))
                elif MASK.match(rep):
                    findings.append(Finding(
                        "X5-REDACT", "",
                        "a redaction filter is not a safety layer (L-X5): the "
                        "value has already reached the pipeline it is being "
                        "masked in",
                        i, line))
    return findings


FENCE = re.compile(r"^\s*(```|~~~)")


def allowed_lines(text):
    """Line numbers suppressed by a marker on themselves or the line above.

    A marker also covers the fenced block that OPENS on the line it covers
    (2026-11-02). Without that, the marker was unusable in exactly the files
    that most need it: a register quotes a shape inside a ``` block, so the
    fence line sits between the marker and the idiom, and a reader who put the
    marker where the documentation says to put it still got a denial. Measured
    before the fix -- marker, fence, idiom: deny; marker, idiom: allow. One
    marker with one reason now covers the block it introduces, which is also
    the only form that works when the quotation is more than one line long.
    """
    allowed = set()
    lines = text.splitlines()
    for i, line in enumerate(lines, start=1):
        if not ALLOW_MARKER.search(line):
            continue
        allowed.add(i)
        allowed.add(i + 1)
        # The covered line opens a fence: carry the marker to its close, or to
        # the end of the text if the hunk being written stops inside a block.
        if i < len(lines) and FENCE.match(lines[i]):
            for j in range(i + 2, len(lines) + 1):
                allowed.add(j)
                if FENCE.match(lines[j - 1]):
                    break
    return allowed


def scan_file(path, extra=(), honour_allow=True):
    try:
        with open(path, "r", encoding="utf-8", errors="replace") as fh:
            text = fh.read()
    except OSError as exc:
        print(f"check-secret-print.py: cannot read {path}: {exc}",
              file=sys.stderr)
        return None
    findings = scan_text(text, extra)
    if honour_allow:
        skip = allowed_lines(text)
        findings = [f for f in findings if f.line_no not in skip]
    for f in findings:
        f.path = path
    return findings


def rel(path):
    """Repo-relative where that is shorter and stable, as given otherwise: a
    file outside the tree reads better as the path the caller typed."""
    try:
        out = os.path.relpath(os.path.abspath(path), ROOT)
    except ValueError:
        return path
    return path if out.startswith("..") else out


def finding_key(f):
    """What a baseline entry matches on: the file, the code and the line's own
    text. Deliberately not the line number, which moves when anything above it
    is edited and would turn every baseline into a lie after one commit."""
    return f"{rel(f.path or '<command>')} | {f.code} | {f.line.strip()}"


def baseline_accepts(entries, f):
    """Is this finding accepted by the baseline? The code and the line's own
    text must match exactly; the path is a shell glob, so one entry can accept
    a line that a generator writes into every file it generates. A path with
    no wildcard in it matches exactly, which is what every entry written
    before globs existed means."""
    path, code, text = rel(f.path or "<command>"), f.code, f.line.strip()
    for e_path, e_code, e_text in entries:
        if e_code == code and e_text == text and fnmatch.fnmatch(path, e_path):
            return True
    return False


def load_baseline(path):
    """Accepted findings, one per line, as `path | CODE | source`, where the
    path may be a shell glob. Comment lines carry the reason each one is
    accepted and are the point of the file: an exemption nobody wrote a
    reason for is not reviewable. A source line that itself contains a `|`
    survives, because only the first two separators are structural."""
    entries = []
    with open(path, "r", encoding="utf-8") as fh:
        for line in fh:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            parts = line.split("|", 2)
            if len(parts) != 3:
                continue
            entries.append(tuple(part.strip() for part in parts))
    return entries


def default_targets():
    out = []
    for d in SCAN_DIRS:
        base = os.path.join(ROOT, d)
        if not os.path.isdir(base):
            continue
        for dirpath, dirnames, filenames in os.walk(base):
            dirnames[:] = [n for n in dirnames
                           if n not in (".git", "node_modules", "__pycache__",
                                        ".venv", "dist", "build")]
            for name in sorted(filenames):
                p = os.path.join(dirpath, name)
                if name.endswith(SCAN_SUFFIXES):
                    out.append(p)
                elif "." not in name and is_script(p):
                    out.append(p)
    return out


def is_script(path):
    try:
        with open(path, "rb") as fh:
            return fh.read(2) == b"#!"
    except OSError:
        return False


HOOK_FIELDS = {
    "Bash": ("command",),
    "Write": ("content",),
    "Edit": ("new_string",),
    "NotebookEdit": ("new_source",),
}


def hook_text(payload):
    """Every string in a PreToolUse payload that is about to become a command
    or a file. Unknown tools contribute nothing and are allowed."""
    tool = payload.get("tool_name", "")
    data = payload.get("tool_input") or {}
    parts = []
    for field in HOOK_FIELDS.get(tool, ()):
        value = data.get(field)
        if isinstance(value, str):
            parts.append(value)
    for edit in data.get("edits") or []:          # MultiEdit
        if isinstance(edit, dict) and isinstance(edit.get("new_string"), str):
            parts.append(edit["new_string"])
    return "\n".join(parts)


FILE_TOOLS = ("Write", "Edit", "MultiEdit", "NotebookEdit")
DEFAULT_BASELINE = os.path.join(ROOT, "tools", "secret-print-baseline.txt")


def edit_suppressions(findings, text, target):
    """Drop what an edit is allowed to write: a line carrying an `L-X5-ALLOW`
    marker (or sitting under one) and a line the baseline already accepts for
    the file being written.

    A command and an edit are different risks. A command runs now, in this
    session, and nothing reviews it — so nothing suppresses it. An edit writes
    text that only matters when something later runs the file, which is what
    the repository scan in CI checks, with these two suppressions and the
    reason each one carries. Without this, the two mechanisms that exist to
    accept a finding could not be used: writing a baseline entry, a test case
    or a lesson that quotes the idiom was denied as if the idiom were running.
    """
    allowed = allowed_lines(text)
    kept = [f for f in findings if f.line_no not in allowed]
    try:
        entries = load_baseline(DEFAULT_BASELINE)
    except OSError:
        return kept                               # no baseline is not an excuse
    out = []
    for f in kept:
        f.path = target
        if not baseline_accepts(entries, f):
            out.append(f)
    return out


def run_hook(extra=()):
    """Answer a Claude Code PreToolUse hook. Never raises, never exits non-zero:
    a guard that breaks the session is worse than the failure it guards."""
    decision = None
    try:
        payload = json.loads(sys.stdin.read() or "{}")
        text = hook_text(payload)
        findings = scan_text(text, extra)
        tool = payload.get("tool_name", "")
        target = (payload.get("tool_input") or {}).get("file_path")
        if findings and tool in FILE_TOOLS and isinstance(target, str):
            if quotes_rather_than_runs(target):
                # Prose and exemptions registers: the scan's own predicate,
                # applied where it was missing. See PROSE_SUFFIXES.
                findings = []
            else:
                findings = edit_suppressions(findings, text, target)
        if findings:
            what = "edit would write a line that prints" if (
                tool in FILE_TOOLS) else "command would print"
            lines = [
                f"This {what} a secret's value, which is "
                "standards/lessons.md L-X5 and four recorded incidents "
                "(3, 4, 15, and the unnumbered BOARD_RUNTIME_TOKEN one).",
                "",
            ]
            for f in findings:
                lines.append(f"  {f.code}  {f.why}")
                if f.fix:
                    lines.append(f"  fix: {f.fix}")
            lines += [
                "",
                "A secret check needs presence and length and nothing else. "
                "Masking in Actions does not help: the value still passes "
                "through this session's context.",
                "Rewrite it. If this is a false positive, say so to the "
                "owner rather than working around the guard.",
                "An edit that has to carry the shape — a baseline entry, a "
                "test case, a lesson quoting the idiom — carries an "
                "L-X5-ALLOW marker with its reason, or a line in "
                "tools/secret-print-baseline.txt. A marker above a ``` fence "
                "covers the whole block, and an edit to prose (.md, .rst) or "
                "to a checker's own *baseline.txt is never denied here.",
            ]
            decision = "\n".join(lines)
    except Exception as exc:                       # noqa: BLE001 - see docstring
        print(f"check-secret-print.py: hook could not run: {exc}",
              file=sys.stderr)
    out = {"hookSpecificOutput": {"hookEventName": "PreToolUse"}}
    if decision:
        out["hookSpecificOutput"]["permissionDecision"] = "deny"
        out["hookSpecificOutput"]["permissionDecisionReason"] = decision
    print(json.dumps(out))
    return 0


def main(argv):
    extra, files = [], []
    command = None
    baseline_path = None
    quiet = as_json = hook = no_allow = show_accepted = False
    i = 0
    while i < len(argv):
        arg = argv[i]
        if arg in ("-h", "--help"):
            print(__doc__.strip())
            return 0
        elif arg == "--command":
            i += 1
            if i >= len(argv):
                print("--command needs a string", file=sys.stderr)
                return 2
            command = argv[i]
        elif arg == "--hook":
            hook = True
        elif arg == "--name":
            i += 1
            if i >= len(argv):
                print("--name needs a variable name", file=sys.stderr)
                return 2
            extra.append(argv[i])
        elif arg == "--list-names":
            for n in sorted(KNOWN_SECRET_NAMES):
                print(n)
            print("")
            print("plus any name containing: " + ", ".join(sorted(SECRET_WORDS)))
            print("unless it ends in: " + ", ".join(sorted(LABEL_SUFFIXES)))
            return 0
        elif arg == "--quiet":
            quiet = True
        elif arg == "--json":
            as_json = True
        elif arg == "--no-allow":
            no_allow = True
        elif arg == "--baseline":
            i += 1
            if i >= len(argv):
                print("--baseline needs a file", file=sys.stderr)
                return 2
            baseline_path = argv[i]
        elif arg == "--show-accepted":
            show_accepted = True
        elif arg.startswith("-"):
            print(f"check-secret-print.py: unknown argument {arg}",
                  file=sys.stderr)
            return 2
        else:
            files.append(arg)
        i += 1

    if hook:
        return run_hook(extra)

    if command is not None:
        findings = scan_text(command, extra)
        for f in findings:
            f.path = "<command>"
        where = "<command>"
    else:
        targets = files or default_targets()
        findings = []
        for path in targets:
            got = scan_file(path, extra, honour_allow=not no_allow)
            if got is None:
                return 2
            findings.extend(got)
        where = None

    accepted = []
    if baseline_path:
        try:
            keys = load_baseline(baseline_path)
        except OSError as exc:
            print(f"cannot read baseline {baseline_path}: {exc}",
                  file=sys.stderr)
            return 2
        kept = []
        for f in findings:
            (accepted if baseline_accepts(keys, f) else kept).append(f)
        findings = kept
        if show_accepted and not as_json:
            # In --json the accepted set is a field, so printing it here too
            # would put plain text in front of the document.
            for f in accepted:
                print(f"accepted  {finding_key(f)}")

    if as_json:
        print(json.dumps({"findings": [f.as_dict() for f in findings],
                          "accepted": [finding_key(f) for f in accepted],
                          "clean": not findings}, indent=2))
        return 1 if findings else 0

    if not findings:
        if not quiet:
            scope = where or f"{len(files) or len(default_targets())} files"
            extra_note = (f", {len(accepted)} accepted by {baseline_path}"
                          if accepted else "")
            print(f"no L-X5 shape found ({scope}{extra_note})")
        return 0

    for f in findings:
        print(f.render(rel(f.path) if f.path and f.path != "<command>"
                       else (f.path or where)))
    print("")
    print(f"{len(findings)} finding(s). standards/lessons.md L-X5: a seat "
          f"checks that a secret exists and never prints the value.")
    return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
