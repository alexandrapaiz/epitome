#!/usr/bin/env python3
"""Is the L-X5 credential guard registered, and is it registered correctly?

    python3 tools/tests/test-hook-wiring.py

WHAT THIS TESTS, AND WHAT IT DELIBERATELY DOES NOT

`tools/check-secret-print.py` is a vendored copy of HQ's checker and HQ owns
its logic and its own tests. This file tests the one thing that is this
product's: the WIRING. Every payload below is sent to the command string read
out of `.claude/settings.json`, never to a command retyped here, because the
thing that can be wrong is the registration and a test that retypes the
command cannot see a registration that is wrong.

So it asserts four properties, in the order they can hurt:

1. REGISTERED AND RESOLVABLE. `.claude/settings.json` names a `PreToolUse`
   hook, and the interpreter and script it names resolve from a seat's own
   checkout. docs/standards/lessons.md L-A16: configured is not in effect.
2. IT FAILS OPEN. Garbage on stdin, no payload, the wrong shape — every one
   allows, and exits 0. A guard that breaks the harness is worse than what it
   guards, so a guard that cannot read its input must get out of the way.
3. IT REFUSES THE SHAPES THAT HAVE ACTUALLY HAPPENED HERE, including the one
   that put two credentials into a transcript on 2026-11-02.
4. IT ALLOWS THE FORMS L-X5 ASKS FOR, and does not cover a tool surface on
   which it would refuse this repository's own committed code. That last one
   is not a nicety: L-X5's safe snippet is only learnable if the guard that
   teaches it is still installed, and a guard that denies the engineer seat's
   ordinary work is uninstalled by the first seat it blocks.

exit 0 = the wiring holds    1 = a property above is broken    2 = could not look
"""

import json
import os
import shlex
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SETTINGS = os.path.join(ROOT, ".claude", "settings.json")

# The tools whose payload carries a file's new content rather than a command.
# The matcher must not cover these; property 4 says why.
FILE_TOOLS = ("Write", "Edit", "MultiEdit", "NotebookEdit")

pass_ = fail = 0


def check(label, want, got, detail=""):
    global pass_, fail
    if want == got:
        pass_ += 1
        print(f"  ok   {label}")
    else:
        fail += 1
        print(f"  FAIL {label}")
        print(f"       wanted: {want}")
        print(f"       got:    {got}")
        if detail:
            for line in detail.splitlines()[:4]:
                print(f"       | {line}")


def cannot_look(rule, fix):
    print(f"test-hook-wiring: {rule}", file=sys.stderr)
    print(f"\n  {fix}\n", file=sys.stderr)
    sys.exit(2)


# ---------------------------------------------------------------- property 1
if not os.path.exists(SETTINGS):
    cannot_look(
        "this product registers no pre-execution credential check, and "
        "docs/standards/lessons.md L-X5 requires one: a rule whose violation is a "
        "single shell idiom must be enforced by something that reads the command.",
        "create .claude/settings.json with a PreToolUse hook naming "
        "tools/check-secret-print.py --hook",
    )

try:
    settings = json.loads(open(SETTINGS).read())
except Exception as exc:
    cannot_look(
        f".claude/settings.json is not readable JSON, so no hook is registered "
        f"however the file reads: {exc}",
        "fix the JSON; `python3 -m json.tool .claude/settings.json` names the line",
    )

entries = (settings.get("hooks") or {}).get("PreToolUse") or []
if not entries:
    cannot_look(
        ".claude/settings.json has no PreToolUse hook, so nothing reads a command "
        "before it runs (L-X5's closing clause).",
        'add hooks.PreToolUse with matcher "Bash" and the checker as a command hook',
    )

print("== 1. registered, and the path resolves from this checkout")
entry = entries[0]
matcher = entry.get("matcher", "")
hooks = entry.get("hooks") or []
command = hooks[0].get("command", "") if hooks else ""

check("a PreToolUse hook is registered", True, bool(command), command)
check("it is a command hook", "command", hooks[0].get("type") if hooks else None)
check("it has a timeout, so a slow guard cannot hang a turn",
      True, isinstance(hooks[0].get("timeout"), int) if hooks else False)

# Resolve the command the way the harness will: CLAUDE_PROJECT_DIR is the
# seat's own checkout. We set it to this one and expand, so a path that only
# works on the box that wrote it fails here.
env = dict(os.environ, CLAUDE_PROJECT_DIR=ROOT)
resolved = os.path.expandvars(command.replace("${CLAUDE_PROJECT_DIR:-.}", ROOT))
argv = shlex.split(resolved)
check("the hook names an absolute-resolvable script", True,
      any(os.path.exists(a) for a in argv[1:]),
      f"nothing in {argv[1:]} exists; the vendored copy belongs at tools/check-secret-print.py")
check("the matcher covers Bash, which is the surface L-X5 names",
      True, "Bash" in matcher, f"matcher={matcher!r}")
for tool in FILE_TOOLS:
    check(f"the matcher does not cover {tool} (property 4)",
          False, tool in matcher, f"matcher={matcher!r}")


def ask(payload, raw=None):
    """Send one PreToolUse payload to the registered command. Returns
    (exit code, decision, reason, stderr)."""
    body = raw if raw is not None else json.dumps(payload)
    p = subprocess.run(argv, input=body, capture_output=True, text=True,
                       env=env, cwd=ROOT, timeout=30)
    spec, reason = {}, ""
    if p.stdout.strip():
        try:
            spec = (json.loads(p.stdout) or {}).get("hookSpecificOutput") or {}
            reason = spec.get("permissionDecisionReason") or ""
        except Exception:
            return p.returncode, "unparseable", p.stdout[:200], p.stderr
    return p.returncode, spec.get("permissionDecision", "allow"), reason, p.stderr


def case(label, want, payload=None, raw=None, secret=None):
    """One payload. `secret` is a fake value that must appear in no output:
    the guard decides from names and shape, never from a value."""
    rc, decision, reason, err = ask(payload, raw)
    detail = f"reason: {reason[:200]}\nstderr: {err.strip()[:200]}"
    check(label, (want, 0), (decision, rc), detail)
    if secret is not None:
        global pass_, fail
        if secret in reason or secret in err:
            fail += 1
            print(f"  FAIL {label}: the guard echoed the value it was deciding about")
        else:
            pass_ += 1
            print(f"  ok   {label}: nothing it printed contains the value")


def bash(cmd):
    return {"tool_name": "Bash", "tool_input": {"command": cmd}}


# ---------------------------------------------------------------- property 2
print("\n== 2. it fails open: a guard that cannot look gets out of the way")
case("stdin is not JSON", "allow", raw="not json, not even close")
case("stdin is empty", "allow", raw="")
case("the payload has no tool_input", "allow", {"tool_name": "Bash"})
case("the payload is the wrong JSON type", "allow", [])
case("the payload is an unknown tool", "allow",
     {"tool_name": "SomeToolFromTheFuture", "tool_input": {"x": 1}})

# ---------------------------------------------------------------- property 3
print("\n== 3. it refuses the shapes that have printed a credential here")
# Each of these is a recorded incident, not an invented example. None is ever
# executed: they are strings handed to a checker, which is the whole point of
# a check that runs before the command does.
case("the `:-` trap (Incident 4, and 2026-11-02's own two credentials)", "deny",
     bash('echo "BOARD_RUNTIME_TOKEN set: ${BOARD_RUNTIME_TOKEN:+yes}'
          '${BOARD_RUNTIME_TOKEN:-NO}"'))
case("prefix-guessing redaction (Incident 3: the pattern missed github_pat_)", "deny",
     bash("""echo "$EXO_TOKEN" | sed 's/gh[pous]_[A-Za-z0-9]*/REDACTED/'"""))
case("a client told to transcribe its own request (Incident 21, curl -sv)", "deny",
     bash('curl -sv -H "Authorization: Bearer $BOARD_RUNTIME_TOKEN" "$BOARD_API_URL/api/standing"'))
case("tracing with a credential in scope (Incident 18, set -x)", "deny",
     bash('set -x; curl -H "Authorization: Bearer $BOARD_RUNTIME_TOKEN" "$BOARD_API_URL/api/standing"'))
case("an unanchored names-only read (Incident 20, sed 's/=.*//')", "deny",
     bash("""env | grep -iE 'board|api' | sed 's/=.*//'"""))
case("the whole environment, piped", "deny", bash("env | grep -i token"))
case("this product's own non-credential-worded secret, which needs --name",
     "deny", bash('echo "$CALLMEBOT_PHONE"'))

# The guard must decide from the NAME, never from the value. Give it a real
# fake value in the environment and assert the value reaches neither stream.
FAKE = "github_pat_11NOTAREALTOKEN_000000000000000000"
env["EXO_TOKEN"] = FAKE
case("it never reads the value it is deciding about", "deny",
     bash('echo "$EXO_TOKEN"'), secret=FAKE)
del env["EXO_TOKEN"]

# ---------------------------------------------------------------- property 4
print("\n== 4. it allows the forms the rule asks for, and this seat's own work")
case("L-X5's safe snippet, copied verbatim from the register", "allow",
     bash("printf 'T present: %s length: %s\\n' "
          '"${BOARD_RUNTIME_TOKEN:+yes}" "${#BOARD_RUNTIME_TOKEN}"'))
case("a presence test", "allow", bash('[ -n "$BOARD_RUNTIME_TOKEN" ] || exit 1'))
case("using the credential in a header, which is what it is for", "allow",
     bash('curl -s -H "Authorization: Bearer $BOARD_RUNTIME_TOKEN" '
          '"$BOARD_API_URL/api/standing?company=epitome&seat=engineer"'))
case("curl -i: the RESPONSE headers, which carry no bearer", "allow",
     bash('curl -i -H "Authorization: Bearer $BOARD_RUNTIME_TOKEN" "$BOARD_API_URL/api/standing"'))
case("moving a credential into another name", "allow",
     bash('GH_TOKEN="$BOARD_RUNTIME_TOKEN" gh api /user'))
case("this repo's own board helper, invoked the way every seat invokes it",
     "allow", bash("bash docs/agents/post.sh --check /tmp/payload.json"))
case("the gate every seat runs before posting", "allow",
     bash("bash docs/agents/addressed.sh --body /tmp/body.md"))
case("set -euo pipefail, which turns no tracing on", "allow",
     bash("set -euo pipefail; node test/unit.mjs"))
case("this seat's ordinary work: running a suite", "allow",
     bash("cd cli && bash test/all.sh"))
case("this seat's ordinary work: opening its own pull request", "allow",
     bash('gh pr create --draft --title "x" --body "y"'))

# ---------------------------------------------------- the known upstream gap
# This section asserts a DEFECT, on purpose, because a defect reported with no
# detector is a defect nobody notices getting fixed (L-X1 as amended, read the
# other way round). X5-ENVDUMP's own --help says it covers a bare `env` "piped
# or redirected somewhere". Measured on the vendored copy at HQ 9b0e9e4, it
# covers the pipe and not the redirect:
#
#     env | grep -i token   deny        env > /tmp/d.txt    allow
#     env | sort            deny        env >> /tmp/d.txt   allow
#     env | tee /tmp/d.txt  deny        set > /tmp/d.txt    allow
#
# A redirect is the cheaper way to do the same thing and the whole environment
# is every secret at once, so this is coverage the help claims and the code
# does not have. It is handed to the exo seat, which owns the vendoring route
# to HQ, with this measurement.
#
# WHEN THIS SECTION FAILS, HQ HAS FIXED IT. Delete the section, re-vendor
# tools/check-secret-print.py, and move the redirect case up into section 3.
print("\n== 5. the upstream gap this installation knows it has")
case("a redirect of the whole environment is NOT caught (HQ 9b0e9e4)",
     "allow", bash("env > /tmp/dump.txt"))
case("...nor is `set` redirected", "allow", bash("set > /tmp/dump.txt"))

print(f"\nhook-wiring: {pass_} ok, {fail} failed")
sys.exit(1 if fail else 0)
