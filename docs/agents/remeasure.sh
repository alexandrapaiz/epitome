#!/usr/bin/env bash
# L20 obliges this seat to re-measure every incident whose fix is not on
# `main`, every run. Until 2026-10-25 those conditions were sentences in
# prose describing a read, and one of them was wrong in a way that read as
# good news.
#
#   bash docs/agents/remeasure.sh            every condition in incidents.md
#   bash docs/agents/remeasure.sh 29 27      only these incidents
#   bash docs/agents/remeasure.sh --coverage  which open incidents it cannot measure
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
#   means   open
#   ```
#
# A block with no control is refused, not run. That is the defect itself.
#
# `means` is optional and defaults to `open`: the probe fires while the
# incident is open, so HOLDS is bad news and CHANGED is a candidate close.
# `means healthy` inverts the words and not the exit codes, because one
# condition in this register was already written that way — incident 30's
# probe fires when its instrument still passes — and for two days this script
# printed "still open: the probe found what keeps it open" over a probe whose
# author meant the fix was working. Two opposite states wearing one word is
# L-A50, and only the prose beside the block could tell them apart.
#
# WHY THE DEFAULT MODE NOW ENUMERATES THE REGISTER AND NOT ITS OWN BLOCKS.
# L20's population is "every incident whose fix is not on `main`". This
# script's population was "every incident carrying a ```remeasure block",
# because that is what `blocks` can see, and the two were never compared.
# On 2026-10-26T10:47:20Z the no-argument run printed seven conditions, all
# HOLDS, and the line "every condition holds: no incident here is a candidate
# for closing" with exit 0. The register had **35** entries at that moment and
# **14** of them said in their own Status field that their fix was not on
# `main`. Four of those fourteen carried a condition. So the duty was
# discharged for four incidents, reported as discharged for all of them, and
# the ten it never looked at were not failures of the probe — they were never
# in the population, which is the one error an exit code cannot carry.
#
# An instrument whose population comes from its own input format can only be
# complete by accident, and the accident reads as good news. So the default
# mode asks the register who is open, compares that set against the set it can
# execute, and the difference is a named class with its own exit status
# (L-A47, L-A88, L-A134). `--coverage` is that half alone.
#
# THE HONEST LIMIT, stated because this file has twice been read as broader
# than it is. Open-ness is read off the entry's own `**Status:` field, which
# is a claim by the seat that wrote it and not a measurement of `main`
# (L-A52). An entry that says closed and is not is outside this gate; what is
# inside it is an entry that says open and has nothing that could tell. An
# entry with no Status field at all is `not_judgeable` and never all-clear,
# because L-A28 makes that field the only thing distinguishing the two.
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
    inb && /^(probe|control|means)[ \t]+/   {
      key=$1; sub(/^(probe|control|means)[ \t]+/,"");
      printf "%s\t%s\t%s\n", n, key, $0; next }
  ' "$FILE"
}

# Every `## Incident N` heading in the register, with the Status field that
# decides whether L20 owes it a re-measurement. The field wraps, so it is read
# to its closing `**` across up to four lines and never as one line (incident
# 30's whole cause).
population() {  # prints "incident<TAB>open|closed|unjudgeable<TAB>status text"
  awk '
    /^## Incident [0-9]+/ {
      if (n != "") emit()
      n=$3; sub(/[^0-9]/,"",n); st=""; acc=0; next
    }
    n != "" && acc == 0 && /\*\*Status/ {
      line=$0
      sub(/^.*\*\*Status/, "", line)
      sub(/^[:.]*[ \t]*/, "", line)
      st=line; acc=1
      if (st ~ /\*\*/) { sub(/\*\*.*$/, "", st); acc=2 }
      next
    }
    n != "" && acc == 1 {
      st = st " " $0
      if (st ~ /\*\*/) { sub(/\*\*.*$/, "", st); acc=2 }
      if (++w >= 4) acc=2
      next
    }
    END { if (n != "") emit() }
    function emit() {
      gsub(/[ \t]+/, " ", st); sub(/^ /, "", st); sub(/ $/, "", st)
      printf "%s\t%s\n", n, st
      n=""; st=""; w=0; acc=0
    }
  ' "$FILE" | while IFS=$'\t' read -r n st; do
      printf '%s\t%s\t%s\n' "$n" "$(classify "$st")" "$st"
    done
}

# An entry is in L20's population when its own field says the fix is not on
# `main`. One open half is enough: "closed on the register, open on the
# charter clause" is open, which is the specimen this classifier exists for.
classify() {  # $1 = status text
  local s; s=$(printf '%s' "$1" | tr 'A-Z' 'a-z')
  [ -z "$s" ] && { echo unjudgeable; return; }
  case "$s" in
    *open*|*"not in this tree"*|*"not on \`main\`"*|*"not on main"*|*"fix written"*|*"is in no tree"*|*"in no tree"*)
      echo open; return ;;
  esac
  case "$s" in
    *closed*|*shipped*) echo closed; return ;;
  esac
  echo unjudgeable
}

# The second half of the answer: of the incidents L20 owes a re-measurement,
# how many can this script actually measure. Printed as a `data` block because
# a count this charter tells a reader to paste must not need retyping (L33).
coverage() {
  local pop with without unjudge n cls st have
  pop=$(population)
  with=""; without=""; unjudge=""
  # The incident numbers that carry an executable condition, read once. This was
  # `blocks | cut -f1 | grep -qx` per incident: one quiet-pipe site, and one awk
  # pass over the whole register for every open incident in the loop.
  have=$(blocks | cut -f1 | sort -un)
  while IFS=$'\t' read -r n cls st; do
    [ -z "$n" ] && continue
    case "$cls" in
      open)        if grep -qx "$n" <<<"$have"; then with="$with $n"; else without="$without $n"; fi ;;
      unjudgeable) unjudge="$unjudge $n" ;;
    esac
  done <<< "$pop"
  local total; total=$(printf '%s\n' "$pop" | grep -c . )
  local c_with c_without c_unjudge
  c_with=$(printf '%s' "$with" | wc -w); c_without=$(printf '%s' "$without" | wc -w)
  c_unjudge=$(printf '%s' "$unjudge" | wc -w)
  printf '```data\n'
  printf 'instrument: docs/agents/remeasure.sh --coverage\n'
  printf 'read_at: %s\n' "$(date -u +%FT%TZ)"
  printf 'register: %s\n' "$FILE"
  printf 'incidents_in_register: %s\n' "$total"
  printf 'conditions_executable: %s\n' "$(grep -c . <<<"$have")"
  printf 'open_by_their_own_status: %s\n' "$((c_with + c_without))"
  printf 'open_with_a_condition: [%s]\n' "$(echo $with | tr ' ' ',')"
  printf 'open_without_a_condition: [%s]\n' "$(echo $without | tr ' ' ',')"
  printf 'no_status_field_so_not_judgeable: [%s]\n' "$(echo $unjudge | tr ' ' ',')"
  printf '```\n'
  if [ "$c_without" -gt 0 ] || [ "$c_unjudge" -gt 0 ]; then
    [ "$c_without" -gt 0 ] && printf '  %s incident(s) say their fix is not on `main` and carry nothing that could tell:%s\n' "$c_without" "$without"
    [ "$c_unjudge" -gt 0 ] && printf '  %s incident(s) carry no Status field, so L20 cannot be asked about them at all:%s\n' "$c_unjudge" "$unjudge"
    printf 'the population is wider than the conditions, so this run is not an all-clear\n'
    return 2
  fi
  printf 'every open incident carries a condition: the conditions below are the whole duty\n'
  return 0
}

one() {  # $1 = incident number
  local n=$1 probe control means rc_c rc_p out
  probe=$(blocks | awk -F'\t' -v n="$n" '$1==n && $2=="probe"   {print $3; exit}')
  control=$(blocks | awk -F'\t' -v n="$n" '$1==n && $2=="control" {print $3; exit}')
  # A condition's polarity is the author's, and before 2026-10-26 it lived in
  # a paragraph beside the block. Incident 30's probe fires when its fix is
  # *working*, and this script printed "still open: the probe found what keeps
  # it open" over it for two days. Two opposite states under one word is
  # L-A50, and the field is the fix.
  means=$(blocks | awk -F'\t' -v n="$n" '$1==n && $2=="means" {print $3; exit}')
  case "${means:-open}" in
    open|healthy) means=${means:-open} ;;
    *) printf '  incident %-3s REFUSED  means must be `open` or `healthy`, not %s\n' "$n" "$means"; return 2 ;;
  esac
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
    if [ "$means" = healthy ]; then
      printf '  incident %-3s HOLDS    the fix is still working, so there is nothing to reopen\n' "$n"
    else
      printf '  incident %-3s HOLDS    still open: the probe found what keeps it open\n' "$n"
    fi
    printf '      probe:   %s\n' "$probe"
    return 0
  fi
  if [ "$means" = healthy ]; then
    printf '  incident %-3s REOPENED the fix stopped working: the control held and the probe did not\n' "$n"
  else
    printf '  incident %-3s CHANGED  candidate close, and a close is a human read: the control held and the probe did not\n' "$n"
  fi
  printf '      probe:   %s\n' "$probe"
  return 1
}

run() {
  local want=("$@") nums rc=0 r whole=0 cov=0
  if [ ${#want[@]} -eq 0 ]; then
    whole=1
    mapfile -t nums < <(blocks | cut -f1 | sort -un)
  else
    nums=("${want[@]}")
  fi
  printf 're-measured %s against %s\n' "$(date -u +%FT%TZ)" "$FILE"
  # The scope comes before the verdicts, because a reader who sees seven
  # HOLDS and then a scope line has already formed the answer.
  if [ "$whole" = 1 ]; then coverage; cov=$?; fi
  if [ ${#nums[@]} -eq 0 ]; then
    echo "  no executable condition in $FILE — every one of them is still prose, which is L58"
    return 2
  fi
  for n in "${nums[@]}"; do one "$n"; r=$?; [ $r -gt $rc ] && rc=$r; done
  case $rc in
    0) echo "every condition that exists holds: none of them is a candidate for closing" ;;
    1) echo "at least one condition moved: read those by hand before closing or reopening anything" ;;
    2) echo "at least one condition could not be looked at, which is never a close" ;;
  esac
  # A verdict over four of fourteen is not a verdict over the duty, so the
  # wider population wins the exit status (L-A88: the summary names the class).
  if [ "$cov" -gt 0 ]; then
    echo "and the conditions are not the duty: see open_without_a_condition above"
    [ "$cov" -gt "$rc" ] && rc=$cov
  fi
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
probe   s=\$(sentences $t/charter.md); grep -qi "run last turn" <<<"\$s"
control s=\$(sentences $t/charter.md); grep -qi "one PR per run" <<<"\$s"
\`\`\`
EOF
  check() { if grep -qF "$3" <<<"$2"; then echo "  ok   $1"; else echo "  FAIL $1: wanted '$3' in: $2"; fail=1; fi; }
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
  check "a set is as unclosed as its worst member" "$out" "at least one condition moved"
  FILE="$t/empty.md"; : > "$t/empty.md"
  out=$(run); rc=$?
  check "a register with no executable condition says so" "$out" "still prose"
  [ $rc = 2 ] || { echo "  FAIL exit for a prose-only register: $rc"; fail=1; }

  # The population half, built from the four real shapes of 2026-10-26: an
  # open entry with a condition, an open entry with none, an entry whose
  # status declares one half closed and one half open, a declared-closed
  # entry with no condition which must NOT be a finding, and an entry with no
  # Status field at all.
  cat > "$t/pop.md" <<EOF
## Incident 1
**Status: open.** No fix is in this tree.
\`\`\`remeasure 1
probe   true
control true
\`\`\`
## Incident 2
**Status: open, and the repair is not in this tree.** Nothing here can tell.
## Incident 3
**Status: closed on the register, open on the charter
clause.** The wrapped specimen.
## Incident 4
**Status: closed 2026-10-26T05:3xZ, on \`main\`.** Done.
## Incident 5
This entry never wrote a status line at all.
EOF
  FILE="$t/pop.md"
  out=$(coverage); rc=$?
  check "an open incident with a condition is covered" "$out" "open_with_a_condition: [1]"
  check "an open incident with no condition is the finding" "$out" "open_without_a_condition: [2,3]"
  check "a status wrapped across lines is read to its closing bold" "$out" "open_by_their_own_status: 3"
  check "a declared-closed entry with no condition is not a finding" "$out" "no_status_field_so_not_judgeable: [5]"
  check "the population is the register and not the blocks" "$out" "incidents_in_register: 5"
  check "a wider population is never an all-clear" "$out" "not an all-clear"
  [ $rc = 2 ] || { echo "  FAIL exit for an uncovered population: $rc"; fail=1; }
  [ "$(classify "closed 2026-10-26, on \`main\`")" = closed ] || { echo "  FAIL a plain close reads as closed"; fail=1; }
  [ "$(classify "")" = unjudgeable ] || { echo "  FAIL an absent status reads as unjudgeable"; fail=1; }
  out=$(run); rc=$?
  check "the whole-register run folds the population into its own exit" "$out" "not the duty"
  [ $rc = 2 ] || { echo "  FAIL exit for a holding probe over a short population: $rc"; fail=1; }

  # Polarity, built from incident 30, the one condition in the real register
  # written the other way round.
  cat > "$t/polarity.md" <<EOF
## Incident 1
**Status: open.**
\`\`\`remeasure 1
probe   true
control true
means   healthy
\`\`\`
## Incident 2
**Status: open.**
\`\`\`remeasure 2
probe   false
control true
means   healthy
\`\`\`
## Incident 3
**Status: open.**
\`\`\`remeasure 3
probe   true
control true
means   sideways
\`\`\`
EOF
  FILE="$t/polarity.md"
  out=$(run 1); rc=$?
  check "a healthy-polarity probe that fires has nothing to reopen" "$out" "nothing to reopen"
  [ $rc = 0 ] || { echo "  FAIL exit for a healthy probe that fires: $rc"; fail=1; }
  out=$(run 2); rc=$?
  check "a healthy-polarity probe that stops firing is a reopening" "$out" "REOPENED"
  [ $rc = 1 ] || { echo "  FAIL exit for a healthy probe gone silent: $rc"; fail=1; }
  check "a reopening is not reported as a candidate close" "$out" "reopening anything"
  out=$(run 3); rc=$?
  check "an unknown polarity is refused rather than guessed" "$out" "REFUSED"
  [ $rc = 2 ] || { echo "  FAIL exit for an unknown polarity: $rc"; fail=1; }

  # The false-positive control that decides whether anyone keeps this: a
  # register whose every open entry carries a condition must be silent.
  cat > "$t/full.md" <<EOF
## Incident 1
**Status: open.** No fix is in this tree.
\`\`\`remeasure 1
probe   true
control true
\`\`\`
## Incident 2
**Status: closed, on \`main\`.** Done.
EOF
  FILE="$t/full.md"
  out=$(coverage); rc=$?
  check "a fully covered register says the conditions are the whole duty" "$out" "the whole duty"
  [ $rc = 0 ] || { echo "  FAIL a covered population must be clean: $rc"; fail=1; }
  [ $fail = 0 ] && echo "self-test: all verdicts fired" || echo "self-test FAILED"
  return $fail
}

case "${1:-}" in
  --self-test) selftest ;;
  --coverage)  coverage ;;
  --help|-h)   sed -n '2,45p' "$0" ;;
  *)           run "$@" ;;
esac
