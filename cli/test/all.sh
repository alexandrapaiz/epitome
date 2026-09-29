#!/usr/bin/env bash
# Every suite this repository has, in one command.
#
#   bash test/all.sh            # from cli/
#   bash test/all.sh --strict   # a suite that could not run is a failure
#
# Why this exists. Each suite below already refuses to lie about itself: with
# no `temporal` binary, no docker, or no langgraph importable, it says so and
# exits 0, because "a machine without the binary is not a failing test, it is
# an unrun one." That is right for one suite and wrong for a run of all four —
# a loop over them reports success on a box where nothing actually ran, and
# that is how a six-PR stack reached 2026-09-29 without anyone having seen it
# work composed. So this script asks each suite's prerequisite itself, BEFORE
# running it, and reports three outcomes rather than two:
#
#   ok      the suite ran and passed
#   FAILED  the suite ran and failed
#   unrun   the prerequisite is missing — the summary says which, and how to
#           install it, and --strict makes it an exit code
#
# It installs nothing. Everything it needs is either already on the box or
# named in the summary with the one command that gets it.
set -uo pipefail

CLI="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT="$(cd "$CLI/.." && pwd)"
LOGS="${TMPDIR:-/tmp}/epito-test-all-$$"
STRICT=0
for a in "$@"; do
  case "$a" in
    --strict) STRICT=1 ;;
    *) echo "test/all.sh: unknown option \"$a\" — the only option is --strict (a suite that could not run is a failure)"; exit 2 ;;
  esac
done
mkdir -p "$LOGS"
trap 'if [ "${KEEP_LOGS:-0}" = 1 ]; then echo "logs kept in $LOGS"; else rm -rf "$LOGS"; fi' EXIT

names=(); results=(); counts=(); notes=()
record() { names+=("$1"); results+=("$2"); counts+=("$3"); notes+=("$4"); }

# Run one suite, capture its output, read its own tally back out of it. Each
# suite prints a final "<word>: N ok, M failed" line; node --test prints
# "# pass N" / "# fail N". Whatever the tally says, the exit code decides.
run_suite() {
  local name="$1"; shift
  local log="$LOGS/$name.log"
  printf '\n\033[1m== %s\033[0m\n' "$name"
  "$@" > "$log" 2>&1
  local rc=$?
  local tally
  tally="$(grep -Eo '^(smoke|provision): [0-9]+ ok, [0-9]+ failed' "$log" | tail -1)"
  if [ -z "$tally" ]; then
    local p f
    p="$(grep -Eo '^# pass [0-9]+' "$log" | tail -1 | grep -Eo '[0-9]+')"
    f="$(grep -Eo '^# fail [0-9]+' "$log" | tail -1 | grep -Eo '[0-9]+')"
    [ -n "${p:-}" ] && tally="${p} ok, ${f:-0} failed"
  fi
  tally="${tally#*: }"
  if [ "$rc" = 0 ]; then
    printf '  ok   %s\n' "${tally:-passed}"
    record "$name" ok "${tally:-passed}" ""
  else
    printf '  FAIL %s (exit %d)\n' "${tally:-see below}" "$rc"
    # The failing assertions first — a suite prints hundreds of lines and the
    # two that matter are never the last forty.
    grep -nE '^\s*(FAIL|not ok)' "$log" | sed 's/^/  | /'
    printf '  | ---- last 20 lines ----\n'
    tail -20 "$log" | sed 's/^/  | /'
    printf '  | full output: %s\n' "$log"
    record "$name" FAILED "${tally:-exit $rc}" ""
  fi
}

skip_suite() { printf '\n\033[1m== %s\033[0m\n  unrun  %s\n' "$1" "$2"; record "$1" unrun "-" "$2"; }

# --- 1. unit ---------------------------------------------------------------
run_suite "unit" node --test "$CLI/test/unit.mjs"

# --- 2. the runtime, on a real engine --------------------------------------
# The suite finds the binary the same three ways; ask before running so a
# missing one is reported as unrun instead of as a pass.
temporal_bin="${TEMPORAL_BIN:-}"
if [ -z "$temporal_bin" ]; then
  if command -v temporal >/dev/null 2>&1; then temporal_bin="$(command -v temporal)"
  elif [ -x "$HOME/.temporalio/bin/temporal" ]; then temporal_bin="$HOME/.temporalio/bin/temporal"; fi
fi
if [ -n "$temporal_bin" ]; then
  TEMPORAL_BIN="$temporal_bin" run_suite "smoke-temporal" bash "$CLI/test/smoke-temporal.sh"
else
  skip_suite "smoke-temporal" "no \`temporal\` binary: curl -sSf https://temporal.download/cli.sh | sh"
fi

# --- 3. the langgraph adapter ----------------------------------------------
# This one has two halves and only the framework half needs python+langgraph,
# so it always runs; the summary says which half it was.
py="${EPITO_PYTHON:-python3}"
if command -v "$py" >/dev/null 2>&1 && "$py" -c "import langgraph" >/dev/null 2>&1; then
  EPITO_PYTHON="$py" run_suite "smoke-langgraph" bash "$CLI/test/smoke-langgraph.sh"
else
  run_suite "smoke-langgraph" bash "$CLI/test/smoke-langgraph.sh"
  i=$((${#names[@]} - 1))
  [ "${results[$i]}" = ok ] && results[$i]="partial" \
    && notes[$i]="the framework half did not run: python3 -m venv /tmp/lgvenv && /tmp/lgvenv/bin/pip install langgraph && EPITO_PYTHON=/tmp/lgvenv/bin/python bash test/all.sh"
fi

# --- 4. the deploy path ----------------------------------------------------
if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  run_suite "provision-host" bash "$ROOT/deploy/test-provision.sh"
else
  skip_suite "provision-host" "no usable docker: it runs the real provision script in an ubuntu:24.04 container"
fi

# --- summary ---------------------------------------------------------------
printf '\n%s\n' "-----------------------------------------------"
failed=0; unrun=0
for i in "${!names[@]}"; do
  case "${results[$i]}" in
    FAILED) failed=$((failed+1)); c='\033[31m' ;;
    unrun)  unrun=$((unrun+1));   c='\033[33m' ;;
    partial) unrun=$((unrun+1));  c='\033[33m' ;;
    *) c='\033[32m' ;;
  esac
  printf "  ${c}%-8s\033[0m %-16s %s\n" "${results[$i]}" "${names[$i]}" "${counts[$i]}"
  [ -n "${notes[$i]}" ] && printf '           %s\n' "${notes[$i]}"
done
printf '\n'

if [ "$failed" -gt 0 ]; then
  KEEP_LOGS=1
  printf 'test/all.sh: %d suite(s) failed.\n' "$failed"
  exit 1
fi
if [ "$unrun" -gt 0 ]; then
  printf 'test/all.sh: everything that ran passed, but %d suite(s) could not run on this box.\n' "$unrun"
  printf 'That is not a green build — it is a partial one. Install what each line names, or\n'
  printf 'say so out loud when you report the result. --strict makes this exit 1.\n'
  [ "$STRICT" = 1 ] && exit 1
  exit 0
fi
printf 'test/all.sh: every suite ran, and every suite passed.\n'
exit 0
