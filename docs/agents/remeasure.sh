#!/usr/bin/env bash
# L20 obliges this seat to re-measure every incident whose fix is not on
# `main`, every run. Until 2026-10-25 those conditions were sentences in
# prose describing a read, and one of them was wrong in a way that read as
# good news.
#
#   bash docs/agents/remeasure.sh            every condition in incidents.md
#   bash docs/agents/remeasure.sh 29 27      only these incidents
#   bash docs/agents/remeasure.sh --self-test
#
# WHY THIS EXISTS. Incident 29 wrote its own re-measurement condition as:
# "the next run of this seat reads prompts/exo-agent.md on main for the words
# *last turn*. If they are gone, this closes." The next run ran it:
#
#   $ git grep -n "last turn" origin/main -- prompts/exo-agent.md
#   $ echo $?
#   1
#
# The words are there. `prompts/exo-agent.md` on `main` wraps them across
# lines 172 and 173 — "readied before the run's last / turn**" — so a
# line-oriented grep cannot see them and answers *not found* about a clause
# that is present. Read as written, that condition closes an open incident
# and resets its instance count to zero while its cause stands untouched.
# This seat had already paid for this exact defect once: `addressed.sh`'s
# `can()` reads charters as sentences for the same reason, shipped 2026-10-24,
# with the reason in a comment above it. A second instance of a rule already
# in the register is a register defect (L4), so the condition stopped being a
# sentence and became this.
#
# THE MECHANISM. Every condition carries a control as well as a probe: one
# assertion known to hold at the moment the condition was written, over the
# same bytes, through the same read unit. A probe that reports *gone* while
# its control also reports *gone* has not measured the world, it has measured
# its own reach — and that is the only difference between the two answers a
# register reader cannot otherwise tell apart. Three answers and never two
# (L41): holds, changed, could-not-look. Could-not-look is never a close.
#
# THE FORMAT, in docs/agents/incidents.md, one fenced block per incident:
#
#   ```remeasure 29
#   # open while this holds: main still schedules readying at the last turn
#   probe   sentences origin/main:prompts/exo-agent.md | grep -qi "last turn"
#   control sentences origin/main:prompts/exo-agent.md | grep -qi "one pr per run"
#   ```
#
# A block with no control is refused, not run. That is the defect itself.
set -uo pipefail
cd "$(git rev-parse --show-toplevel)"

FILE=${REMEASURE_FILE:-docs/agents/incidents.md}

# The read unit that cost incident 29 its condition. A charter wraps its
# prose, so the fact is a sentence and never a line. Takes a path or a
# `rev:path`, so a condition can read `main` from a branch without checkout.
sentences() {
  local src=$1 body
  case "$src" in
    *:*) body=$(git show "$src" 2>/dev/null) || return 2 ;;
    *)   body=$(cat "$src" 2>/dev/null) || return 2 ;;
  esac
  printf '%s' "$body" | tr '\n' ' ' | sed -E 's/[[:space:]]+/ /g; s/([.!?]) /\1\n/g'
}
export -f sentences 2>/dev/null || true

blocks() {  # prints "incident<TAB>key<TAB>command" for every condition in $FILE
  awk '
    /^```remeasure[ \t]+[0-9]+[ \t]*$/ { n=$2; sub(/[^0-9]*/,"",n); inb=1; next }
    inb && /^```[ \t]*$/              { inb=0; next }
    inb && /^(probe|control)[ \t]+/   {
      key=$1; sub(/^(probe|control)[ \t]+/,"");
      printf "%s\t%s\t%s\n", n, key, $0; next }
  ' "$FILE"
}

one() {  # $1 = incident number
  local n=$1 probe control rc_c rc_p out
  probe=$(blocks | awk -F'\t' -v n="$n" '$1==n && $2=="probe"   {print $3; exit}')
  control=$(blocks | awk -F'\t' -v n="$n" '$1==n && $2=="control" {print $3; exit}')
  if [ -z "$probe" ]; then
    printf '  incident %-3s REFUSED  no probe in %s\n' "$n" "$FILE"; return 2
  fi
  if [ -z "$control" ]; then
    printf '  incident %-3s REFUSED  a probe with no control cannot tell "gone" from "I cannot see it" — this is the defect L58 names, not a condition\n' "$n"
    return 2
  fi
  out=$(bash -c "$(declare -f sentences); $control" 2>&1); rc_c=$?
  if [ $rc_c -ne 0 ]; then
    printf '  incident %-3s COULD NOT LOOK  the control failed (exit %s), so the probe would have measured its own reach\n' "$n" "$rc_c"
    printf '      control: %s\n' "$control"
    [ -n "$out" ] && printf '      said: %s\n' "$(printf '%s' "$out" | head -1 | cut -c1-120)"
    return 2
  fi
  out=$(bash -c "$(declare -f sentences); $probe" 2>&1); rc_p=$?
  if [ $rc_p -eq 0 ]; then
    printf '  incident %-3s HOLDS    still open: the probe found what keeps it open\n' "$n"
    printf '      probe:   %s\n' "$probe"
    return 0
  fi
  printf '  incident %-3s CHANGED  candidate close, and a close is a human read: the control held and the probe did not\n' "$n"
  printf '      probe:   %s\n' "$probe"
  return 1
}

run() {
  local want=("$@") nums rc=0 r
  if [ ${#want[@]} -eq 0 ]; then
    mapfile -t nums < <(blocks | cut -f1 | sort -un)
  else
    nums=("${want[@]}")
  fi
  printf 're-measured %s against %s\n' "$(date -u +%FT%TZ)" "$FILE"
  if [ ${#nums[@]} -eq 0 ]; then
    echo "  no executable condition in $FILE — every one of them is still prose, which is L58"
    return 2
  fi
  for n in "${nums[@]}"; do one "$n"; r=$?; [ $r -gt $rc ] && rc=$r; done
  case $rc in
    0) echo "every condition holds: no incident here is a candidate for closing" ;;
    1) echo "at least one condition changed: read those by hand before closing anything" ;;
    2) echo "at least one condition could not be looked at, which is never a close" ;;
  esac
  return $rc
}

# L42: the branch an instrument has never been made to hit is the one that
# decides its answer on the day it hits. All four verdicts are built here, and
# the third one is built from the real 2026-10-25 positive.
selftest() {
  local t fail=0 out rc
  t=$(mktemp -d); trap "rm -rf $t" EXIT
  printf 'wrapped prose: one PR per run, opened as a draft and readied before the run last\nturn: so a line grep sees neither half.\n' > "$t/charter.md"
  cat > "$t/incidents.md" <<EOF
## Incident 1
\`\`\`remeasure 1
probe   grep -qi "wrapped prose" $t/charter.md
control grep -qi "line grep" $t/charter.md
\`\`\`
## Incident 2
\`\`\`remeasure 2
probe   grep -qi "a string that is not there" $t/charter.md
control grep -qi "line grep" $t/charter.md
\`\`\`
## Incident 3 — the real 2026-10-25 positive: a line grep over a wrapped sentence
\`\`\`remeasure 3
probe   grep -qi "run last turn" $t/charter.md
control grep -qi "one PR per run, opened as a draft and readied before the run last turn" $t/charter.md
\`\`\`
## Incident 4
\`\`\`remeasure 4
probe   true
\`\`\`
## Incident 5 — the same wrapped file read as sentences
\`\`\`remeasure 5
probe   sentences $t/charter.md | grep -qi "run last turn"
control sentences $t/charter.md | grep -qi "one PR per run"
\`\`\`
EOF
  check() { if printf '%s' "$2" | grep -qF "$3"; then echo "  ok   $1"; else echo "  FAIL $1: wanted '$3' in: $2"; fail=1; fi; }
  FILE="$t/incidents.md"
  out=$(run 1); rc=$?
  check "a probe that fires is the incident still open" "$out" "HOLDS"
  [ $rc = 0 ] || { echo "  FAIL exit for a holding probe: $rc"; fail=1; }
  out=$(run 2); rc=$?
  check "probe gone, control held, is a candidate close" "$out" "CHANGED"
  [ $rc = 1 ] || { echo "  FAIL exit for a changed probe: $rc"; fail=1; }
  out=$(run 3); rc=$?
  check "the wrapped-sentence positive is could-not-look, not a close" "$out" "COULD NOT LOOK"
  [ $rc = 2 ] || { echo "  FAIL exit for a failed control: $rc"; fail=1; }
  out=$(run 4); rc=$?
  check "a probe with no control is refused" "$out" "REFUSED"
  [ $rc = 2 ] || { echo "  FAIL exit for a controlless probe: $rc"; fail=1; }
  out=$(run 5); rc=$?
  check "the same bytes read as sentences find the clause" "$out" "HOLDS"
  out=$(run 1 2); rc=$?
  check "a set is as unclosed as its worst member" "$out" "at least one condition changed"
  FILE="$t/empty.md"; : > "$t/empty.md"
  out=$(run); rc=$?
  check "a register with no executable condition says so" "$out" "still prose"
  [ $rc = 2 ] || { echo "  FAIL exit for a prose-only register: $rc"; fail=1; }
  [ $fail = 0 ] && echo "self-test: all verdicts fired" || echo "self-test FAILED"
  return $fail
}

case "${1:-}" in
  --self-test) selftest ;;
  --help|-h)   sed -n '2,45p' "$0" ;;
  *)           run "$@" ;;
esac
