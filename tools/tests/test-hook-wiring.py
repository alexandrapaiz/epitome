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

So it asserts these properties, in the order they can hurt:

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
5. THE REPOSITORY SCAN RUNS AND IS GREEN, and the documents name the script
   rather than printing an invocation. The hook covers what a seat is about to
   run; the scan covers what is already committed, which is the only thing that
   catches a shape that arrived before the hook existed. It is asserted here
   because the invocation used to be a comment, and a command in a comment
   drifted from the sentence beside it until the two disagreed by exit code.
6. WHAT COVERING THE FILE TOOLS WOULD COST, as a measured list of files rather
   than an argument, so the day HQ changes the edit path the acts this
   installation would lose are printed instead of re-reasoned.

exit 0 = the wiring holds    1 = a property above is broken    2 = could not look
"""

import json
import re
import os
import shlex
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SETTINGS = os.path.join(ROOT, ".claude", "settings.json")
BASELINE = os.path.join(ROOT, "tools", "secret-print-baseline.txt")
SCAN = os.path.join(ROOT, "tools", "scan-secret-print.sh")
README = os.path.join(ROOT, ".claude", "README.md")

# The tools whose payload carries a file's new content rather than a command.
# The matcher must not cover these; section 5 is the measurement that says why.
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
    check(f"the matcher does not cover {tool} (section 5 says why)",
          False, tool in matcher, f"matcher={matcher!r}")
check("the baseline the repository scan will read is in place",
      True, os.path.exists(BASELINE),
      "tools/secret-print-baseline.txt holds this product's accepted findings")
check("the repository scan is a script and not a comment (section 6 runs it)",
      True, os.path.exists(SCAN),
      "tools/scan-secret-print.sh is the scan; a printed invocation drifts from "
      "the claim beside it, which is how this product shipped a header whose "
      "command gave exit 1 under the sentence saying it gives exit 0")


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


def write(path, content):
    return {"tool_name": "Write", "tool_input": {"file_path": path, "content": content}}


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
          '${BOARD_RUNTIME_TOKEN:-NO}"'))  # L-X5-ALLOW: a test case for this shape; a string, never executed
case("prefix-guessing redaction (Incident 3: the pattern missed github_pat_)", "deny",
     bash("""echo "$EXO_TOKEN" | sed 's/gh[pous]_[A-Za-z0-9]*/REDACTED/'"""))  # L-X5-ALLOW: a test case for this shape; a string, never executed
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

# ---------------------------------------------------------------- property 5
# WHY THE MATCHER STOPS AT `Bash`, asserted rather than argued.
#
# HQ registers the file tools too, and the checker supports them properly: its
# edit_suppressions() honours `L-X5-ALLOW` markers and tools/secret-print-
# baseline.txt on the edit path while deliberately honouring neither on the
# command path, which is the right distinction — a command runs now and nothing
# reviews it; a file's new content has a diff, a pull request and a scan.
#
# It cannot be registered here. A full-file write of docs/standards/lessons.md
# is denied: the vendored company register that CARRIES L-X5 quotes every idiom
# it forbids, which is what a register is for. Covering the file tools here
# would stop the exo seat re-vendoring the rule this guard enforces, and no
# marker fixes it, because a vendored copy may not be edited and a re-vendor
# would strip the markers.
#
# THE PREDICATE IS NOT THE SUFFIX, and this comment said it was until the deny
# set was measured instead of reasoned about. "The repository scan skips
# markdown on purpose" (--help) is true and is no use here: on main at ebf9382,
# writing each of eighteen real files back at the hook denied six, and only two
# of the six were markdown. The others were a `.txt` — this product's own
# baseline, the file an exemption is WRITTEN IN — two `.sh` seat tools, and
# `cli/src/lib/runner.js`, product source, where the one genuine credential
# print in this repository lives. A markdown exemption would have unblocked the
# register and left the baseline, the detector and the CLI denied, so it was
# never the condition to wait for.
#
# Three of those six are allowed now, and section 8 asserts it: this branch
# accepted their lines in the baseline, which the edit path honours. That is
# the mechanism, and it reduces the problem to the three files no entry can
# reach — the vendored register, the vendored checker, and the baseline itself,
# whose entries ARE the quotations, which is why a full-file write of it is
# refused by eleven findings that are all its own accepted lines. The
# mechanism therefore gets harder to use in exact proportion to how much it
# has been used, and that is the shape of the thing to hand HQ.
#
# All four recorded incidents were commands typed at a shell, which is also the
# only surface L-X5's clause names, so the command path is where the coverage
# is. The rest belongs to the repository scan, which section 6 runs, and the
# CI gate that runs it on a schedule is a workflow and so the PM's.
#
# WHEN THIS SECTION FAILS, HQ HAS FIXED IT: honour `L-X5-ALLOW` markers and the
# baseline for a vendored file on the edit path — or whatever the fix is, read
# section 7's measurement before widening the matcher, because the number it
# prints is the list of acts this installation would be taking away.
print("\n== 5. why the matcher stops at Bash: the register cannot be rewritten")


def write(path, content):
    return {"tool_name": "Write",
            "tool_input": {"file_path": path, "content": content}}


LESSONS = os.path.join(ROOT, "docs", "standards", "lessons.md")
if os.path.exists(LESSONS):
    case("re-vendoring the register that carries L-X5 would be denied",
         "deny", write("docs/standards/lessons.md", open(LESSONS).read()))
else:
    print("  ok   (no vendored register in this checkout to test against)")
    pass_ += 1

# This file is allowed, and that is the other half of the point: its five
# shape-carrying lines each carry an `L-X5-ALLOW` marker with a reason, so the
# suppression mechanism demonstrably works on the edit path. It is the vendored
# register that cannot use it, because a vendored copy may not be edited.
case("this very test file IS writable: its markers carry their reasons",
     "allow", write("tools/tests/test-hook-wiring.py",
                    open(os.path.abspath(__file__)).read()))
case("the shapes themselves are still refused as commands, which is the point",
     "deny", bash('echo "t: ${BOARD_RUNTIME_TOKEN:-none}"'))  # L-X5-ALLOW: a test case for this shape; a string, never executed

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
print("\n== 6. the upstream gap this installation knows it has")
case("a redirect of the whole environment is NOT caught (HQ 9b0e9e4)",
     "allow", bash("env > /tmp/dump.txt"))
case("...nor is `set` redirected", "allow", bash("set > /tmp/dump.txt"))
# Of the two, the redirect is the worse one and the help claims both. A pipe
# shows matching lines in a transcript somebody has to read; a redirect writes
# every variable in the environment to a file on disk, under a name chosen by
# whoever typed it, where nothing expires it. Reported to HQ in that order.

# ---------------------------------------------------------------- property 7
# THE SCAN RUNS, AND IT IS THE SCAN THE DOCUMENTS NAME.
#
# This is the half of the guard the hook does not cover: the hook reads what a
# seat is about to run, and the scan reads what is already committed, which is
# the only thing that can catch a shape that arrived before the hook existed.
#
# It is asserted here because of how it failed. The invocation used to be a
# COMMENT at the top of the baseline, printed beside the sentence "it exits 0
# today, so the gate can be added without fixing anything first". The exo seat
# copied that line on 2026-11-02 and got 40 findings and exit 1, because the
# printed command omitted `--baseline`; and with the flag added it was still
# exit 1, because the printed glob list had never covered `docs/agents/stage.sh`
# or any of `cli/src/`. Both halves of the claim were wrong and neither could
# have been noticed, because a command in a comment is run by nothing.
#
# So the two assertions are: the scan exits 0, and no document in this
# directory prints a checker invocation a reader could copy instead.
print("\n== 7. the repository scan, run rather than quoted")

scan = subprocess.run(["bash", SCAN], capture_output=True, text=True, cwd=ROOT, timeout=300)
check("tools/scan-secret-print.sh exits 0 over the committed tree",
      0, scan.returncode,
      f"{scan.stdout.strip()[-600:]}\n{scan.stderr.strip()[-600:]}\n"
      "each finding is either a real print — rewrite it — or one this product "
      "accepts, which goes in tools/secret-print-baseline.txt with a reason")
check("...and says how much it looked at, so a green scan of nothing is visible",
      True, "tracked file(s)" in scan.stdout, scan.stdout[-300:])

scan_self = subprocess.run(["bash", SCAN, "--self-test"], capture_output=True,
                           text=True, cwd=ROOT, timeout=300)
check("the scan's own three answers fire on built input", 0, scan_self.returncode,
      scan_self.stdout.strip()[-600:])

# The copyable-command check. `python3 tools/check-secret-print.py` followed by
# a path is an invocation; the same string followed by `--command` or `--help`
# is a one-liner for inspecting a single line, which is what .claude/README.md
# tells a seat to run when it thinks the guard is wrong, and that one does not
# drift because it takes no surfaces and no baseline.
INVOCATION = re.compile(
    r"check-secret-print\.py(?!\s*(?:--command|--help|--hook|`|$))[^\n]*", re.M)
for path, label in ((BASELINE, "tools/secret-print-baseline.txt"),
                    (README, ".claude/README.md")):
    if not os.path.exists(path):
        continue
    hits = [m.group(0).strip() for m in INVOCATION.finditer(open(path).read())]
    check(f"{label} names the script instead of printing an invocation",
          [], hits,
          "a printed invocation is a command nothing executes, so it drifts "
          "from the claim next to it; say `bash tools/scan-secret-print.sh`")

# ---------------------------------------------------------------- property 8
# WHAT COVERING THE FILE TOOLS WOULD COST, as a number rather than an argument.
# Section 5 says the matcher stops at Bash; this is the measurement it rests
# on, and it is here so that the day HQ changes the edit path, the list of acts
# that would be taken away is printed rather than re-reasoned.
#
# These are real files in this checkout, written back at the hook unchanged, so
# every denial below is an edit somebody would have to make to maintain this
# guard and could not.
print("\n== 8. the edit-path deny set, measured on this checkout")

DENIED = {
    "docs/standards/lessons.md": "the vendored register that CARRIES L-X5, quoting every idiom it forbids",
    ".claude/README.md": "the document that explains the guard, quoting what it refuses",
    "tools/secret-print-baseline.txt": "the file an exemption is written IN: its own entries are the quotations, so it is the one file the baseline cannot unblock",
}
# These three were denied on main at ebf9382 and are allowed here, and the
# difference is not a change to the checker: it is the three baseline entries
# this branch added. That is the suppression mechanism working on the edit
# path, and it is asserted rather than described because it is the reason the
# deny set is three files and not six.
UNBLOCKED = {
    "docs/agents/x5probe.sh": "the detector's probe inputs, accepted as KIND THREE",
    "docs/agents/stage.sh": "the seat tool's assertion tally, accepted with the other 12",
    "cli/src/lib/runner.js": "the git credential helper, accepted as KIND ONE",
}
ALLOWED = ("docs/backlog.md", "README.md", "docs/agents/lessons.md",
           "prompts/engineer-agent.md", "cli/test/smoke-temporal.sh",
           "docs/agents/post.sh", "docs/agents/addressed.sh", "docs/agents/board.py",
           ".claude/settings.json", "cli/src/lib/runreport.js",
           "deploy/provision-host.sh", "tools/tests/test-hook-wiring.py",
           "tools/scan-secret-print.sh")

for rel, why in DENIED.items():
    p = os.path.join(ROOT, rel)
    if not os.path.exists(p):
        print(f"  ok   (no {rel} in this checkout)")
        pass_ += 1
        continue
    case(f"a full-file write of {rel} is denied — {why}", "deny",
         write(rel, open(p, encoding="utf-8", errors="replace").read()))
for rel, why in UNBLOCKED.items():
    p = os.path.join(ROOT, rel)
    if not os.path.exists(p):
        continue
    case(f"{rel} is writable BECAUSE of a baseline entry — {why}", "allow",
         write(rel, open(p, encoding="utf-8", errors="replace").read()))
for rel in ALLOWED:
    p = os.path.join(ROOT, rel)
    if not os.path.exists(p):
        continue
    case(f"...and {rel} needed no entry at all", "allow",
         write(rel, open(p, encoding="utf-8", errors="replace").read()))

print(f"\nhook-wiring: {pass_} ok, {fail} failed")
sys.exit(1 if fail else 0)
