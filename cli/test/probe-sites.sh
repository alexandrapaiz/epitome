#!/usr/bin/env bash
# Every converted site in smoke-doctor.sh, made to fail — because a gate nobody
# has seen fail is a wish.
#
#   bash test/probe-sites.sh              # from cli/: baseline, then one run per site
#   bash test/probe-sites.sh --list       # the sites it would mutate, and how
#   bash test/probe-sites.sh --site 7     # one site, by the number --list gives it
#   bash test/probe-sites.sh --helpers    # the three helper definitions only
#
# The quiet-pipe conversion changed how 31 assertions in test/smoke-doctor.sh
# read their haystack. A conversion that reads right and asserts nothing looks
# exactly like a conversion that works: both print `ok`. So each converted site
# gets its needle replaced with one that must change the verdict —
#
#   a positive site   `said_in "$X" 'needle'`      -> a sentence no output holds
#   a negated site    `! said_in "$X" 'needle'`    -> the empty pattern, which
#                                                     every haystack matches
#
# — and the suite is run with that one site mutated and nothing else. A site
# whose label does not turn FAIL is a gate that is not reading: either the
# needle is unreachable (see line 250, whose `||` short-circuits past its own
# second half) or the assertion is inert.
#
# It is slow on purpose: one full suite run per site, ~2m45s each on this box,
# because the question is what the GATE prints and the gate only exists inside
# a run. Rows are printed as each run finishes, so a probe that is killed
# half-way still leaves the half it measured.
#
# The three helper definitions are measured differently, because mutating a
# needle in a definition that 100 assertions share says nothing: each is forced
# never to match and then always to match, and the blast radius is how many
# verdicts moved — the measurement of how many assertions really route through
# it, rather than a count of how many look as if they do.
set -uo pipefail
CLI="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SUITE="$CLI/test/smoke-doctor.sh"
MUTANT="$CLI/test/.probe-sites-mutant.sh"   # dot-prefixed: test/*.sh must not see it
WORK="${TMPDIR:-/tmp}/epito-probe-sites-$$"
NEVER='zz-no-sentence-this-product-prints-zz'

MODE=all; ONE=""
while [ $# -gt 0 ]; do case "$1" in
  --list) MODE=list ;;
  --helpers) MODE=helpers ;;
  --at-once) MODE=atonce ;;
  --site) MODE=one; ONE="${2:-}"; shift ;;
  *) printf 'test/probe-sites.sh: unknown option "%s". There are five: --list, --site N, --at-once, --helpers, or none.\n' "$1"; exit 2 ;;
esac; shift; done

mkdir -p "$WORK"
cleanup() { rm -f "$MUTANT"; [ -n "${PROBE_KEEP:-}" ] && printf '\nkept: %s\n' "$WORK" || rm -rf "$WORK"; }
trap cleanup EXIT

# Every said_in occurrence that is a call site: not the definition, not a
# comment. Occurrences and not lines — two lines in this suite carry two each,
# and a per-line walk would leave one of each pair unmeasured. The label is the
# nearest `check "..."` at or above the site, which is where the two-line
# checks keep theirs.
sites() {
  awk '
    /^[[:space:]]*#/ { next }
    /^said_in\(\)/   { next }
    match($0, /check[[:space:]]+"/) { lab=$0; sub(/^[^"]*"/, "", lab); sub(/".*$/, "", lab); labline=NR }
    {
      rest=$0; k=0
      while (match(rest, /said_in[ \t]+[\\]["][\\][$][A-Za-z_][A-Za-z0-9_]*[\\]["][ \t]+/)) {
        pre = substr(rest, 1, RSTART-1)
        k++
        neg = (pre ~ /![ \t]*$/) ? "negated" : "positive"
        after = substr(rest, RSTART+RLENGTH)
        if (substr(after,1,1) == "\047") { e=index(substr(after,2),"\047"); needle=substr(after,1,e+1) }
        else { match(after, /^[^ \t"]+/); needle=substr(after, RSTART, RLENGTH) }
        printf "%d\t%d\t%s\t%s\t%s\n", NR, k, neg, needle, lab
        rest = after
      }
    }
  ' "$SUITE"
}

# The k-th occurrence on line L, needle replaced, everything else byte-identical.
mutate_site() {   # line, occurrence, replacement, source (default the suite)
  awk -v L="$1" -v J="$2" -v REPL="$3" '
    NR != L { print; next }
    {
      rest=$0; outp=""; k=0
      while (match(rest, /said_in[ \t]+[\\]["][\\][$][A-Za-z_][A-Za-z0-9_]*[\\]["][ \t]+/)) {
        k++
        outp = outp substr(rest, 1, RSTART+RLENGTH-1)
        after = substr(rest, RSTART+RLENGTH)
        if (substr(after,1,1) == "\047") { e=index(substr(after,2),"\047"); nlen=e+1 }
        else { match(after, /^[^ \t"]+/); nlen=RLENGTH }
        if (k == J) { print outp REPL substr(after, nlen+1); next }
        outp = outp substr(after, 1, nlen)
        rest = substr(after, nlen+1)
      }
      print
    }
  ' "${4:-$SUITE}"
}

verdicts() { grep -E '^  (ok|FAIL) ' "$1"; }
label_verdict() { awk -v lab="$2" 'match($0, /^  (ok|FAIL)  */) { if (substr($0, RLENGTH+1) == lab) { print $1; exit } }' "$1"; }

if [ "$MODE" = list ]; then
  printf '\n== the sites test/probe-sites.sh would mutate, and the needle each one gets\n\n'
  n=0
  while IFS="$(printf '\t')" read -r line occ neg needle lab; do
    n=$((n+1))
    if [ "$neg" = negated ]; then repl="''  (every haystack matches)"; else repl="'$NEVER'"; fi
    printf '  site %-3d line %-4s occ %s  %-8s %s\n' "$n" "$line" "$occ" "$neg" "$lab"
    printf '            %s  ->  %s\n' "$needle" "$repl"
  done < <(sites)
  printf '\n  %d call-site occurrences, plus 3 helper definitions (--helpers)\n' "$n"
  exit 0
fi

printf '\n== every converted site in smoke-doctor.sh, made to fail\n'
printf '   box: load%s\n' "$(uptime | sed 's/.*load average/ average/')"

BASE="$WORK/baseline.txt"
if [ -n "${PROBE_SITES_BASELINE:-}" ]; then
  cp "$PROBE_SITES_BASELINE" "$BASE"
  printf '   baseline: %s, as given\n' "$PROBE_SITES_BASELINE"
else
  printf '   baseline: running the suite unmutated once...\n'
  bash "$SUITE" > "$BASE" 2>&1 || true
fi
printf '   baseline: %s\n\n' "$(tail -1 "$BASE")"

run_mutant() {  # $1 label-under-test ("" for the helper runs), $2 row prefix
  local lab="$1" prefix="$2" log="$WORK/run-$RANDOM.txt" moved=0 bv mv
  bash "$MUTANT" > "$log" 2>&1 || true
  moved="$(diff <(verdicts "$BASE") <(verdicts "$log") | grep -c '^[<>]' || true)"
  if [ -n "$lab" ]; then
    bv="$(label_verdict "$BASE" "$lab")"; mv="$(label_verdict "$log" "$lab")"
    printf '%s %-4s -> %-4s  %s\n' "$prefix" "${bv:-absent}" "${mv:-absent}" "$lab"
    if [ "${bv:-}" = ok ] && [ "${mv:-}" = FAIL ]; then
      [ "$moved" -gt 2 ] && printf '           and %s other verdict lines moved too — read %s\n' "$((moved/2 - 1))" "$log"
      return 0
    fi
    printf '           THE GATE DID NOT TURN. Its needle is not being read: %s\n' "$log"
    return 1
  fi
  # a helper run: the blast radius is how many verdicts moved at all
  printf '%s %s of %s verdicts moved\n' "$prefix" "$((moved/2))" "$(verdicts "$BASE" | wc -l)"
  diff <(verdicts "$BASE") <(verdicts "$log") | grep '^>' | sed 's/^> /           /' > "$WORK/moved.txt" || true
  return 0
}

fails=0; n=0
if [ "$MODE" = atonce ]; then
  # Every site mutated in one copy, one run. It is not a substitute for the
  # per-site runs — a label that turns here could in principle have been turned
  # by another site's mutation — but it bounds that: if exactly as many verdict
  # lines move as there are mutated labels, and each site's own label is one of
  # them, then no mutation reached past its own assertion.
  cp "$SUITE" "$WORK/stacked.sh"
  while IFS="$(printf '\t')" read -r line occ neg needle lab; do
    n=$((n+1))
    if [ "$neg" = negated ]; then repl="''"; else repl="'$NEVER'"; fi
    mutate_site "$line" "$occ" "$repl" "$WORK/stacked.sh" > "$WORK/stacked.next" && mv "$WORK/stacked.next" "$WORK/stacked.sh"
  done < <(sites)
  cp "$WORK/stacked.sh" "$MUTANT"
  printf '  all %s sites mutated at once, in one copy; running it...\n\n' "$n"
  LOG="$WORK/at-once.txt"
  bash "$MUTANT" > "$LOG" 2>&1 || true
  i=0
  while IFS="$(printf '\t')" read -r line occ neg needle lab; do
    i=$((i+1))
    bv="$(label_verdict "$BASE" "$lab")"; mv="$(label_verdict "$LOG" "$lab")"
    printf '  site %-3d line %-4s %-8s %-4s -> %-4s  %s\n' "$i" "$line" "$neg" "${bv:-absent}" "${mv:-absent}" "$lab"
    if [ "${bv:-}" != ok ] || [ "${mv:-}" != FAIL ]; then
      printf '           THE GATE DID NOT TURN. Its needle is not being read.\n'
      fails=$((fails+1))
    fi
  done < <(sites)
  moved="$(diff <(verdicts "$BASE") <(verdicts "$LOG") | grep -c '^[<>]' || true)"
  printf '\n  %s verdict lines moved in all, for %s mutated sites on %s labels\n' "$((moved/2))" "$n" "$(sites | cut -f5 | sort -u | wc -l)"
  printf '  %s\n' "$(tail -1 "$LOG")"
  diff <(verdicts "$BASE") <(verdicts "$LOG") | grep '^>' | sed 's/^> /    /'
fi

if [ "$MODE" = all ] || [ "$MODE" = one ]; then
  while IFS="$(printf '\t')" read -r line occ neg needle lab; do
    n=$((n+1))
    [ "$MODE" = one ] && [ "$n" != "$ONE" ] && continue
    if [ "$neg" = negated ]; then repl="''"; else repl="'$NEVER'"; fi
    mutate_site "$line" "$occ" "$repl" > "$MUTANT"
    cmp -s "$MUTANT" "$SUITE" && { printf '  site %-3d line %-4s MUTATION DID NOT APPLY\n' "$n" "$line"; fails=$((fails+1)); continue; }
    run_mutant "$lab" "$(printf '  site %-3d line %-4s %-8s' "$n" "$line" "$neg")" || fails=$((fails+1))
  done < <(sites)
fi

if [ "$MODE" = all ] || [ "$MODE" = helpers ]; then
  printf '\n  the three helper definitions: forced, not re-needled, because the count of call\n'
  printf '  sites a helper has is not the count of verdicts that depend on it\n'
  for h in said saidf said_in; do
    for dir in never always; do
      case "$dir" in
        never)  body="{ return 1; }" ;;
        always) body="{ return 0; }" ;;
      esac
      sed "s|^$h() {.*|$h() $body|" "$SUITE" > "$MUTANT"
      cmp -s "$MUTANT" "$SUITE" && { printf '  helper %-8s %-6s MUTATION DID NOT APPLY\n' "$h" "$dir"; fails=$((fails+1)); continue; }
      run_mutant "" "$(printf '  helper %-8s forced to %-6s:' "$h" "$dir")"
    done
  done
fi

printf '\n-----------------------------------------------\n'
if [ "$fails" = 0 ]; then
  printf 'probe-sites: every site measured turned its own gate FAIL\n'
else
  printf 'probe-sites: %d site(s) did not turn. Each one is a gate that asserts nothing — say so wherever this is cited.\n' "$fails"
  exit 1
fi
