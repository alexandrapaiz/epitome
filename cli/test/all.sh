#!/usr/bin/env bash
# Every suite this repository has, in one command.
#
#   bash test/all.sh            # from cli/  (also: npm test)
#   bash test/all.sh --strict   # a suite that could not run is a failure
#
# Why this exists. Each suite already refuses to lie about itself: with no
# `temporal` binary, no docker, or no langgraph importable, it says SKIPPED and
# exits 0, because "a machine without the binary is not a failing test, it is
# an unrun one." That is right for one suite and wrong for a run of all four —
# a plain loop reports success on a box where nothing actually ran, and that is
# how a six-PR stack reached 2026-09-29 without anyone having seen it work
# composed. So this reports three outcomes rather than two:
#
#   ok       the suite ran and passed
#   FAILED   the suite ran and failed
#   unrun    the prerequisite is missing — nothing was asserted
#   partial  it ran, but a section of it skipped itself
#
# It never second-guesses a suite's prerequisites. An earlier draft of this
# script kept its own copy of "is langgraph importable" and got it wrong — the
# suite has a fallback the copy did not know about, so a fully-run suite was
# labelled partial. The suite is the only thing that knows whether the suite
# ran; this reads that off its output and does no detection of its own.
set -uo pipefail

CLI="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT="$(cd "$CLI/.." && pwd)"
LOGS="${TMPDIR:-/tmp}/epito-test-all-$$"
STRICT=0
KEEP=0
for a in "$@"; do
  case "$a" in
    --strict) STRICT=1 ;;
    *) echo "test/all.sh: unknown option \"$a\" — the only option is --strict (a suite that could not run is a failure)"; exit 2 ;;
  esac
done
mkdir -p "$LOGS"
trap '[ "$KEEP" = 1 ] && echo "full output kept in $LOGS" || rm -rf "$LOGS"' EXIT

# One prerequisite is this repository's own, and every suite needs it. Without
# node_modules the unit suite does not skip itself politely — it dies with a
# fourteen-line ERR_MODULE_NOT_FOUND naming a path inside src/, and the first
# thing anyone does with that is read it as a broken checkout. The suites are
# allowed to report their own missing binaries; this one is ours to catch.
if [ ! -d "$CLI/node_modules/smol-toml" ]; then
  cat <<EOF
test/all.sh: this checkout has no dependencies installed, so no suite can run.

  cd $CLI && npm ci

Everything else a suite needs, the suite names itself when it skips.
EOF
  exit 2
fi

names=(); results=(); counts=(); notes=()

# What a skip notice looks like, anchored. Every suite announces one at the
# start of a line, bare or behind a short prefix: "pack: SKIPPED — ...",
# "  == 4: SKIPPED — ...", "  SKIPPED -- ...", "test-provision: needs docker
# (skipping)".
#
# Anchored because it used to be a bare `grep -qE 'SKIPPED|skipping'` over the
# whole log, and the first suite to use the word in prose — an assertion label
# reading "names the presence-only seat instead of silently skipping it" —
# came out `partial` with 60 ok, 0 failed and an empty reason. A harness that
# exists so a run cannot claim more than it proved must not claim less either:
# a false partial teaches people to ignore the column.
SKIP_RE='^[[:space:]]*([^:]*:[[:space:]]*)?SKIPPED|[(]skipping[)]'

# The fix, in the suite's own words. Every suite prints guidance under its skip
# notice — an install line, a venv recipe, an engine to start — and that text is
# the only place the fix exists. all.sh used to surface it for `unrun` suites
# only, by grepping for the literal string "install it:"; smoke-roster's
# guidance reads "install it (curl ...) and run `temporal server start-dev`",
# with no colon, so it matched nothing and a `partial` suite named a missing
# prerequisite while withholding the one line that fixes it. That is exactly
# the bar `epito validate` sets for the product's own errors — name the rule
# broken, with the fix in the message — missed by the harness that enforces it.
#
# So: print whatever the suite wrote between its skip notice and its next piece
# of structure, and detect nothing. Same rule as the rest of this script — the
# suite is the only thing that knows what it needs, and it already said so.
guidance() {
  awk -v re="$SKIP_RE" '
    !seen { if ($0 ~ re) seen = 1; next }
    $0 ~ /^[[:space:]]*(==|ok[[:space:]]|FAIL|not ok|#|[0-9]+ ok,)/ { exit }
    { buf[++n] = $0; if (n >= 10) exit }
    END {
      for (i = 1; i <= n; i++) if (buf[i] ~ /[^[:space:]]/) last = i
      for (i = 1; i <= last; i++) print buf[i]
    }
  ' "$1" | sed -e '/[^[:space:]]/s/^/     /'
}

# Run one suite and let it classify itself.
#   FAILED  non-zero exit
#   unrun   exit 0 and no tally line: it skipped before asserting anything
#   partial exit 0, a tally, and a SKIPPED section inside it
#   ok      exit 0, a tally, nothing skipped
run_suite() {
  local name="$1"; shift
  local log="$LOGS/$name.log"
  printf '\n\033[1m== %s\033[0m\n' "$name"
  "$@" > "$log" 2>&1
  local rc=$? tally="" note="" result
  tally="$(grep -Eo '^(smoke|provision|pack): [0-9]+ ok, [0-9]+ failed' "$log" | tail -1)"
  if [ -z "$tally" ]; then
    local p f
    p="$(grep -Eo '^# pass [0-9]+' "$log" | tail -1 | grep -Eo '[0-9]+')"
    f="$(grep -Eo '^# fail [0-9]+' "$log" | tail -1 | grep -Eo '[0-9]+')"
    [ -n "${p:-}" ] && tally="unit: ${p} ok, ${f:-0} failed"
  fi
  tally="${tally#*: }"

  if [ "$rc" != 0 ]; then
    result=FAILED
    printf '  FAIL %s (exit %d)\n' "${tally:-see below}" "$rc"
    # The failing assertions first: a suite prints hundreds of lines and the
    # two that matter are never the last forty.
    grep -nE '^[[:space:]]*(FAIL|not ok)' "$log" | sed 's/^/  | /'
    printf '  | ---- last 20 lines ----\n'
    tail -20 "$log" | sed 's/^/  | /'
    KEEP=1
  elif [ -z "$tally" ]; then
    result=unrun
    note="$(grep -m1 -E "$SKIP_RE" "$log" | sed 's/^[[:space:]]*//')"
    # A suite that asserted plenty and spelled its tally line without the
    # prefix this function greps for looks exactly like a suite that skipped.
    # smoke-validate.sh did precisely that on its first run through all.sh —
    # 59 assertions, reported as "nothing asserted" — so when there is no skip
    # notice and an un-prefixed tally IS in the log, say which it was.
    if [ -z "$note" ] && grep -qE '^[0-9]+ ok, [0-9]+ failed' "$log"; then
      note="it printed a tally without the \`smoke:\` prefix run_suite greps for, so its assertions were not counted: $(grep -Eo '^[0-9]+ ok, [0-9]+ failed' "$log" | tail -1)"
    fi
    printf '  unrun  %s\n' "${note:-it asserted nothing and said nothing about why}"
    guidance "$log"
    KEEP=1
  elif grep -qE "$SKIP_RE" "$log"; then
    result=partial
    note="$(grep -m1 -E "$SKIP_RE" "$log" | sed 's/^[[:space:]]*//')"
    printf '  ok     %s — but: %s\n' "$tally" "$note"
    guidance "$log"
    KEEP=1
  else
    result=ok
    printf '  ok     %s\n' "$tally"
  fi
  names+=("$name"); results+=("$result"); counts+=("${tally:-nothing asserted}"); notes+=("$note")
}

run_suite "unit"            node --test "$CLI/test/unit.mjs" "$CLI/test/unit-deploy.mjs" "$CLI/test/unit-audit.mjs"
run_suite "smoke-deploy"    bash "$CLI/test/smoke-deploy.sh"
run_suite "smoke-validate"  bash "$CLI/test/smoke-validate.sh"
run_suite "smoke-roster"    bash "$CLI/test/smoke-roster.sh"
run_suite "smoke-temporal"  bash "$CLI/test/smoke-temporal.sh"
run_suite "smoke-langgraph" bash "$CLI/test/smoke-langgraph.sh"
run_suite "provision-host"  bash "$ROOT/deploy/test-provision.sh"
run_suite "pack"            bash "$CLI/test/pack.sh"

printf '\n%s\n' "-----------------------------------------------"
failed=0; incomplete=0
for i in "${!names[@]}"; do
  case "${results[$i]}" in
    FAILED)  failed=$((failed+1));     c='\033[31m' ;;
    unrun)   incomplete=$((incomplete+1)); c='\033[33m' ;;
    partial) incomplete=$((incomplete+1)); c='\033[33m' ;;
    *)       c='\033[32m' ;;
  esac
  printf "  ${c}%-8s\033[0m %-16s %s\n" "${results[$i]}" "${names[$i]}" "${counts[$i]}"
  [ -n "${notes[$i]}" ] && [ "${results[$i]}" != FAILED ] && printf '           %s\n' "${notes[$i]}"
done
printf '\n'

if [ "$failed" -gt 0 ]; then
  printf 'test/all.sh: %d suite(s) failed.\n' "$failed"
  exit 1
fi
if [ "$incomplete" -gt 0 ]; then
  printf 'test/all.sh: everything that ran passed, but %d suite(s) did not fully run here.\n' "$incomplete"
  printf 'That is a partial build, not a green one. Each suite above prints its own\n'
  printf 'fix under the == section where it ran. Install what those name, or say so out\n'
  printf 'loud when you report the result. --strict makes this exit 1.\n'
  [ "$STRICT" = 1 ] && exit 1
  exit 0
fi
printf 'test/all.sh: every suite ran, and every suite passed.\n'
exit 0
