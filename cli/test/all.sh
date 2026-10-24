#!/usr/bin/env bash
# Every suite this repository has, in one command.
#
#   bash test/all.sh                 # from cli/  (also: npm test)
#   bash test/all.sh --strict        # a suite that could not run is a failure
#   bash test/all.sh --with-prereqs  # install what the suites need, then run
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
PREREQS=0
for a in "$@"; do
  case "$a" in
    --strict) STRICT=1 ;;
    --with-prereqs) PREREQS=1 ;;
    *) cat <<EOF
test/all.sh: unknown option "$a". There are two:

  --strict         a suite that could not run is a failure (exit 1, not 0)
  --with-prereqs   install the Temporal CLI, nats-server and a langgraph venv
                   first, and start one dev server for the length of the run, so
                   that no suite is incomplete merely because this box is cold

EOF
       exit 2 ;;
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

# ---- the locale, pinned -----------------------------------------------------
# Six assertions in this run read a padded column and grep for ✓ and !, and in a
# non-UTF-8 locale `awk`'s index() counts the three bytes of ✓ as three columns
# and `grep '[✓!]'` becomes a bracket of bytes. The product's own output is
# byte-identical either way, so a failure here is the box talking, not the code —
# and the cold re-verification of a stack is the one place a phantom failure
# costs most. (Reported on 2026-10-06 against a box with LANG unset; it does not
# reproduce under GNU grep, which is exactly why it must not be left to chance —
# the next cold box is as likely to be a Mac, where PR #69's six harness fixes
# came from.)
#
# Pinning a literal C.UTF-8 would be the one-liner and it would be wrong: macOS
# has no C.UTF-8, and setting a locale the box does not have makes tools fall
# back to C — the thing this is trying to avoid. So: keep a UTF-8 locale if this
# shell already has one, else take the first one the box admits to having, else
# say so and carry on, because an un-pinnable locale is a fact about the machine
# and not a reason to refuse to test anything.
pin_locale() {
  case "${LC_ALL:-${LC_CTYPE:-${LANG:-}}}" in
    *UTF-8|*utf8|*UTF8) return 0 ;;
  esac
  local have
  for have in C.UTF-8 C.utf8 en_US.UTF-8; do
    if locale -a 2>/dev/null | grep -qixF "$have"; then
      export LC_ALL="$have"
      return 0
    fi
  done
  cat <<EOF
test/all.sh: this shell has no UTF-8 locale (LC_ALL/LC_CTYPE/LANG) and this box
offers none of C.UTF-8, C.utf8 or en_US.UTF-8, so six assertions that read a
column of ✓ and ! are reading bytes rather than characters.

  Everything still runs. If something fails only in those six, generate a UTF-8
  locale (Debian/Ubuntu: sudo locale-gen C.UTF-8) and run this again before
  believing it.

EOF
}
pin_locale

# ---- the prerequisites, on request ------------------------------------------
# Four suites are permanently incomplete on any box nobody has prepared by
# hand: smoke-temporal unrun, smoke-bus unrun, smoke-roster partial,
# smoke-langgraph partial. The install is three downloads and under a minute
# (measured, 2026-10-07 and 2026-10-17, cold
# GitHub runner), and smoke-roster additionally wants an engine ALREADY
# answering — the one thing test/prereqs.sh deliberately does not leave running.
#
# This still detects nothing. prereqs.sh writes down where it put things and
# this sources that file; whether a suite can run stays the suite's own
# question, as the note at the top says.
if [ "$PREREQS" = 1 ]; then
  PREREQS_DIR="${EPITO_PREREQS_DIR:-${TMPDIR:-/tmp}/epito-prereqs}"
  printf '\n\033[1m== prerequisites\033[0m\n'
  if ! bash "$CLI/test/prereqs.sh" "$PREREQS_DIR" 2>&1 | sed 's/^/  /'; then
    echo "test/all.sh: --with-prereqs could not install everything (above). Running"
    echo "anyway — the suites that are still missing something will say so themselves."
  fi
  # shellcheck disable=SC1090
  [ -f "$PREREQS_DIR/env.sh" ] && . "$PREREQS_DIR/env.sh"

  # One engine for the whole run, on a port nobody else is using. smoke-temporal
  # starts its own regardless (its assertions need a namespace it owns); this one
  # exists for smoke-roster's planning section, which asks whether something is
  # already answering and is the only suite that cannot start what it needs.
  if [ -n "${TEMPORAL_BIN:-}" ] && [ -x "${TEMPORAL_BIN}" ]; then
    ENGINE_PORT="${EPITO_TEST_ENGINE_PORT:-17233}"
    ENGINE_LOG="$LOGS/shared-engine.log"
    "$TEMPORAL_BIN" server start-dev --headless --port "$ENGINE_PORT" \
      --namespace epito-all >"$ENGINE_LOG" 2>&1 &
    ENGINE_PID=$!
    # Reap it, do not just signal it: `kill` returns before the engine is gone,
    # so a caller that checks for a leftover dev server the instant all.sh exits
    # finds one and is right to complain. `wait` on our own child makes "this
    # left nothing running" true at exit rather than a moment after.
    stop_engine() { [ -n "${ENGINE_PID:-}" ] || return 0; kill "$ENGINE_PID" 2>/dev/null; wait "$ENGINE_PID" 2>/dev/null; ENGINE_PID=""; }
    trap 'stop_engine; [ "$KEEP" = 1 ] && echo "full output kept in $LOGS" || rm -rf "$LOGS"' EXIT
    for _ in $(seq 1 40); do
      if node -e 'const n=require("net"),s=n.connect({host:"127.0.0.1",port:Number(process.argv[1])});s.on("connect",()=>{s.end();process.exit(0)});s.on("error",()=>process.exit(1));' "$ENGINE_PORT" 2>/dev/null; then
        break
      fi
      sleep 0.25
    done
    if kill -0 "$ENGINE_PID" 2>/dev/null; then
      export TEMPORAL_ADDRESS="127.0.0.1:$ENGINE_PORT" TEMPORAL_NAMESPACE=epito-all
      echo "  engine: temporal server start-dev on $TEMPORAL_ADDRESS, namespace epito-all"
    else
      echo "  engine: it did not stay up, so smoke-roster will skip its planning section."
      tail -3 "$ENGINE_LOG" | sed 's/^/    /'
      ENGINE_PID=""
    fi
  fi
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
  # The prefixes the shell suites print their tally under. A suite missing from
  # this list reports as `unrun` with 0 assertions counted, which is the exact
  # false negative the diagnostic below was written for — test/stranger.sh hit
  # it on its first run through here.
  tally="$(grep -Eo '^(smoke|provision|pack|stranger): [0-9]+ ok, [0-9]+ failed' "$log" | tail -1)"
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

run_suite "unit"            node --test "$CLI/test/unit.mjs" "$CLI/test/unit-deploy.mjs" "$CLI/test/unit-audit.mjs" "$CLI/test/unit-bus.mjs" "$CLI/test/unit-cloudflare.mjs" "$CLI/test/unit-runreport.mjs" "$CLI/test/unit-envfile.mjs"
run_suite "smoke-deploy"    bash "$CLI/test/smoke-deploy.sh"
run_suite "smoke-cloudflare" bash "$CLI/test/smoke-cloudflare.sh"
run_suite "smoke-validate"  bash "$CLI/test/smoke-validate.sh"
run_suite "smoke-doctor"    bash "$CLI/test/smoke-doctor.sh"
run_suite "smoke-roster"    bash "$CLI/test/smoke-roster.sh"
run_suite "smoke-temporal"  bash "$CLI/test/smoke-temporal.sh"
run_suite "smoke-bus"       bash "$CLI/test/smoke-bus.sh"
run_suite "smoke-langgraph" bash "$CLI/test/smoke-langgraph.sh"
run_suite "provision-host"  bash "$ROOT/deploy/test-provision.sh"
run_suite "pack"            bash "$CLI/test/pack.sh"
run_suite "stranger"        bash "$CLI/test/stranger.sh"

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
