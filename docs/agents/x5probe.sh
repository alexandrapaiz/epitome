#!/usr/bin/env bash
# Are the four L-X5 checker findings this product reported to HQ still live?
#
#   bash docs/agents/x5probe.sh [--checker PATH]   four probes, then a data block
#   bash docs/agents/x5probe.sh --self-test        the probes' own negatives
#
# Exit 0 every finding is FIXED upstream, 1 at least one is still LIVE, 2 could
# not look (L41).
#
# WHY THIS EXISTS. On 2026-11-02 epitome/engineer vendored HQ's
# `tools/check-secret-print.py` byte for byte, registered it as a PreToolUse
# hook, and reported four defects in it to this seat to route to HQ. A vendored
# file is not patched here, so all four sit in `tools/secret-print-baseline.txt`
# as accepted findings, and that file's own header carries the instruction this
# script exists to serve: "WHEN HQ FIXES ONE, DELETE ITS ENTRIES: a stale
# exemption for a bug that is gone hides the next real finding on the same
# line."
#
# Nothing was going to run that instruction. The baseline is read by a hook, the
# hook denies nothing it accepts, and a seat with no memory does not re-measure
# an exemption it did not write. So the exemptions would have outlived the bugs
# silently, and the next real X5-PRINT on any `printf ... "$pass"` line in this
# repository would have been swallowed by an entry kept for a bug HQ had fixed.
# That is the detector half of L-X1 as amended: a repair without something that
# notices leaves the future exactly as exposed as it was.
#
# WHAT IT DOES NOT CLAIM. It does not say the checker is safe and it is not a
# scan. It asks four yes/no questions about four known defects, and a FIXED
# answer is an instruction to delete that defect's baseline entries and re-run
# the scan, never on its own a reason to trust the line.
set -uo pipefail
cd "$(git rev-parse --show-toplevel)" || { echo "could not look: not in a git repository" >&2; exit 2; }

CHECKER=${X5PROBE_CHECKER:-tools/check-secret-print.py}
# Emptied before the flag is read, which is what the three other seat tools
# that hold their self-test in a variable already do (owed.sh:49,
# pointers.sh:83, drafts.sh:66). Here it is not a convention, it is the thing
# that stops this file forking without bound: the self-test below re-invokes
# this script, so a `SELFTEST=1` inherited from the ENVIRONMENT selects the
# self-test in the child as well, and in its child. Measured by running
# `SELFTEST=1 bash docs/agents/x5probe.sh` once on 2026-11-02: it reached a
# thousand processes and load average 1091 on this box before it was killed.
# `--self-test` never did this, because a flag is not inherited -- which is
# why the usage line above documents the flag and this line makes it the only
# way in.
SELFTEST=
while [ $# -gt 0 ]; do
  case "$1" in
    --checker) CHECKER=$2; shift 2 ;;
    --self-test) SELFTEST=1; shift ;;
    *) echo "could not look: unknown argument $1" >&2; exit 2 ;;
  esac
done

# `--command` and `--hook` are the two modes that take input from outside the
# repository, which is what makes every probe below independent of this
# checkout's own files.
ask_command() {            # 0 = the checker DENIES this command, 1 = allows
  python3 "$CHECKER" --command "$1" >/dev/null 2>&1
  [ $? -eq 1 ]
}

ask_hook() {               # 0 = the checker DENIES this edit, 1 = allows
  # Three steps rather than one pipeline, because the last stage used to be
  # `| grep -q`: quiet grep exits on its first match, the checker whose pipe it
  # just closed dies writing into it, and `pipefail` carries that death as the
  # verdict -- so this probe could report ALLOWED for an edit the checker
  # DENIED. `cli/test/shapes.sh` caught it the day after this file landed
  # (#388) and it is the one site that put that gate in the red on `main`.
  local payload verdict
  payload="$(python3 - "$1" "$2" <<'PY'
import json, sys
print(json.dumps({"tool_name": "Write",
                  "tool_input": {"file_path": sys.argv[1], "content": sys.argv[2]}}))
PY
)"
  verdict="$(printf '%s\n' "$payload" | python3 "$CHECKER" --hook 2>/dev/null)"
  grep -q '"permissionDecision": "deny"' <<<"$verdict"
}

# The self-test is a negative control, not a smoke test. Every probe above
# reports LIVE today, so a probe hard-wired to say LIVE would pass the real run
# and prove nothing. So a stub checker is built that behaves the way a FIXED
# upstream would, and the probes are run against it: four FIXED and exit 0. A
# detector nobody has seen answer the other way is a second thing written down
# (L-X1 as amended).
if [ "$SELFTEST" = 1 ]; then
  tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
  cat > "$tmp/fixed.py" <<'STUB'
import json, re, sys
argv = sys.argv[1:]
def deny(reason):
    print(json.dumps({"hookSpecificOutput": {
        "hookEventName": "PreToolUse", "permissionDecision": "deny",
        "permissionDecisionReason": reason}}))
if "--hook" in argv:
    payload = json.loads(sys.stdin.read() or "{}")
    path = (payload.get("tool_input") or {}).get("file_path") or ""
    # F4 fixed: an edit to a file that is not executed is not a print.
    if path.endswith((".md", ".txt")):
        print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse"}}))
    else:
        deny("would print")
    sys.exit(0)
if "--command" in argv:
    cmd = argv[argv.index("--command") + 1]
    # F1 fixed: `:?` is denied only when something writes it.
    if re.search(r"\$\{[A-Za-z_]+:\?", cmd):
        sys.exit(1 if re.match(r"\s*(echo|printf|cat|tee)\b", cmd) else 0)
    # F2 fixed: a bare `pass` is a counter, not a credential.
    if re.search(r'"\$pass"', cmd):
        sys.exit(0)
    # F3 fixed: an environment dump is caught piped OR redirected.
    if re.match(r"\s*(env|printenv|set)\b", cmd) and re.search(r"[|>]", cmd):
        sys.exit(1)
    sys.exit(0)
sys.exit(0)
STUB
  echo "== negative control: the probes against a stub that behaves as FIXED =="
  # `env -u SELFTEST` as well as the emptying above: the child is the half
  # that must not re-enter this branch, and saying so at the call site is what
  # a reader of this line needs to see.
  env -u SELFTEST X5PROBE_CHECKER="$tmp/fixed.py" bash "$0" --checker "$tmp/fixed.py" > "$tmp/out" 2>&1
  rc=$?
  sed -n '/^  F[0-9]/p' "$tmp/out" | sed 's/^/  /'
  n=$(grep -c 'FIXED' "$tmp/out")
  if [ "$rc" = 0 ] && [ "$n" -ge 4 ]; then
    echo "  ok    four FIXED and exit 0 against the stub — the probes can answer both ways"
    exit 0
  fi
  echo "  FAIL  want exit 0 and four FIXED, got exit $rc and $n FIXED line(s)"
  sed 's/^/        /' "$tmp/out"
  exit 1
fi

[ -f "$CHECKER" ] || { echo "could not look: no checker at $CHECKER" >&2; exit 2; }
python3 "$CHECKER" --command 'true' >/dev/null 2>&1
case $? in 0|1) ;; *) echo "could not look: $CHECKER does not answer --command" >&2; exit 2 ;; esac

# The four findings, each as the one line that decides it. A probe states which
# answer means LIVE, because for two of these the defect is a denial and for
# one it is an allowance, and a reader cannot infer the direction (L-A50).
live=0; fixed=0; rows=""
record() {                 # name  verdict  note
  rows="${rows}${1}|${2}|${3}
"
  printf '  %-8s %-5s %s\n' "$1" "$2" "$3"
  [ "$2" = LIVE ] && live=$((live+1)) || fixed=$((fixed+1))
}

echo "== four findings reported to HQ on 2026-11-02, re-asked of $CHECKER =="

# F1. `${V:?word}` is the presence assertion, not the `${V:-word}` trap. On a
# set variable it does expand to the value, so the fix is not to exempt `:?`
# everywhere — `echo "${V:?x}"` prints the token and must stay denied. The
# distinguishing fact is the command the expansion feeds, which X5-PRINT
# already models and X5-DEFAULT does not.
if ask_command ': "${BOARD_RUNTIME_TOKEN:?BOARD_RUNTIME_TOKEN is not set}"'; then
  record F1 LIVE "X5-DEFAULT still denies \`:?\` fed to the no-op \`:\` (10 sites here)"
else
  if ask_command 'echo "${BOARD_RUNTIME_TOKEN:?unset}"'; then
    record F1 FIXED "\`:?\` to \`:\` allowed, \`:?\` to \`echo\` still denied — delete the X5-DEFAULT baseline entry"
  else
    record F1 LIVE "\`:?\` now allowed even inside \`echo\`, which is a leak rather than a fix"
  fi
fi

# F2. `pass` is matched because the name rule reads the whole word PASS as
# PASSWORD. The suffix-exclusion list that already spares _COUNT and _LEN is
# the shape of the fix; `pass_total` is matched too, so TOTAL is missing from
# that list as well.
if ask_command 'printf "%d ok, %d failed\n" "$pass" "$fail"'; then
  record F2 LIVE "the name rule still reads a pass counter as a credential (12 sites here)"
else
  record F2 FIXED "pass counter allowed — delete the six X5-PRINT baseline entries"
fi

# F3. The checker's own --help says a bare `env` or `set` "piped or redirected"
# is caught. The pipe denies; the redirect allows. The redirect is the broader
# leak of the two, because it persists every secret to a file.
if ask_command 'env > /tmp/x5probe-env.txt'; then
  record F3 FIXED "a redirected environment dump is caught, as --help already claimed"
else
  if ask_command 'env | grep TOKEN'; then
    record F3 LIVE "X5-ENVDUMP catches the pipe and misses the redirect, which --help claims it catches"
  else
    record F3 LIVE "X5-ENVDUMP catches neither form"
  fi
fi

# F4. The file scan skips markdown on purpose, because the registers quote
# these shapes. The hook's edit path has no such exemption, so a full-file
# write of the register carrying L-X5 is denied. Markdown is not the right
# predicate: the two other files this denies are a `.txt` and a README, and
# both exist to carry the rule.
REG='standards/lessons.md'
IDIOM='  echo "EXO_TOKEN set: ${EXO_TOKEN:+yes}${EXO_TOKEN:-NO}" | sed "s/gh[pous]_[A-Za-z0-9]*/REDACTED/"'
if ask_hook "docs/$REG" "The trap to know by name is:
$IDIOM
which expands to the value whenever the variable is set."; then
  record F4 LIVE "the edit path still denies a full-file write of the register that carries L-X5"
else
  record F4 FIXED "the register can be re-vendored through the hook — re-check the baseline and README writes too"
fi

echo
echo '```data'
echo "probe: docs/agents/x5probe.sh"
echo "checker: $CHECKER"
echo "checker_sha: $(git hash-object "$CHECKER" 2>/dev/null | cut -c1-8)"
echo "read_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "findings_live: $live"
echo "findings_fixed: $fixed"
printf '%s' "$rows" | while IFS='|' read -r n v note; do
  [ -n "$n" ] || continue
  echo "$n: $v — $note"
done
echo '```'

[ "$live" = 0 ] && exit 0
exit 1
