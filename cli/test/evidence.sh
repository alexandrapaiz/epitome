#!/usr/bin/env bash
# What a failing assertion says it looked at. One copy, sourced by the suites.
#
#   . "$CLI/test/evidence.sh"          # after the suite defines ok() and fail
#   bash test/evidence.sh --self-test  # from cli/ — the reader against planted faults
#
# WHY THIS IS A FILE AND NOT A SEVENTH COPY. `FAIL <label>` names the claim and
# never the output the claim was made against, so the only way to learn which
# of six rows was missing is to run the suite again and hope to be unlucky in
# the same place. `smoke-doctor.sh` paid three runs of archaeology for that and
# then wrote the fix; `smoke-temporal.sh`, `smoke-validate.sh` and
# `smoke-roster.sh` each received a copy of it. Measured on `main` at 11ce0f8,
# before this file existed: four copies, three generations, and the two middle
# ones byte-identical (0.999 by character ratio — the same 57 lines twice).
# Only the newest keeps the VALUE of a haystack whose NAME says it may hold a
# credential off the screen; the oldest has no such check. Six suites were
# still blind, so the per-file lift would have ended at nine copies with the
# credential rule in three of them. This is the newest generation, once.
#
# WHAT A SUITE MUST PROVIDE, and this file checks rather than assumes:
#   - `fail`, the counter `bad` increments, and `ok <label>`
#   - optionally `EVIDENCE_FALLBACK`, the NAME of the variable holding the last
#     command's output. Suites that capture every command into one `out` and
#     clear it per step set `EVIDENCE_FALLBACK=out`; suites that capture a
#     different variable per command must NOT, because the fallback would then
#     print some other section's document under this assertion — which is the
#     wrong-cause fault #369 fixed in `smoke-doctor.sh`'s 7b gate, and the
#     reason `smoke-roster.sh`'s generation dropped the fallback entirely.
#
# Three readers, in the order the answer is most likely to be the document:
#   1. a `$NAME` in the UNEVALUATED expression whose value holds a newline
#   2. a haystack named by the caller as a third argument — a variable name or
#      a path — which is how an exit-code assertion (`[ $rc -eq 0 ]`, where the
#      caller expanded `$rc` to a digit before `check` ever saw it) names the
#      output whose exit code it is about
#   3. any token of the expression that is a readable file, which is how an
#      assertion written `grep -q '<needle>' '$DIR/x.log'` names its haystack:
#      the caller expanded `$DIR`, so no `$NAME` survives to here at all
# A `$NAME` with no newline in it is a seat name, a count or a path, and it is
# printed as the note it is rather than as a document.
#
# A SUITE HELPER that already holds the haystack as a value — `has <label>
# <captured> <needle>`, where the needle match happens in the shell and no
# expression survives — names it the third way, through bash's own dynamic
# scoping: a `local captured="$2"` in the helper is in scope inside `bad`, so
# the helper passes the NAME `captured` and the reader resolves it. That is
# deliberate rather than incidental, and it is written here because it looks
# like a bug to anyone who reads bash as lexically scoped.

EVIDENCE_LINES="${EPITO_SMOKE_EVIDENCE_LINES:-24}"

# Print one haystack under a failing gate. Both ends rather than a tail: a
# report is 6 KB and the row an assertion is about sits in the verdict table
# near the TOP, so a tail shows per-seat asides about nothing the test asked.
# The count between the ends is what tells a reader to re-run with
# EPITO_SMOKE_EVIDENCE_LINES set.
evidence() {
  local heading="$1" body="$2"
  # An empty haystack is an answer — a command that printed nothing is usually
  # THE answer — but it is not a document, and `mapfile` on it gives a
  # one-element array that would read as `all 1 lines` and a blank.
  [ -n "$body" ] || { printf '       %s is empty\n' "$heading"; return 0; }
  local -a lines=(); mapfile -t lines <<<"$body"
  local n=${#lines[@]} head_n=$((EVIDENCE_LINES / 2)) i
  if [ "$n" -le "$EVIDENCE_LINES" ]; then
    printf '       %s, %s bytes, all %s lines:\n' "$heading" "${#body}" "$n"
    for ((i = 0; i < n; i++)); do printf '       | %s\n' "${lines[i]}"; done
    return 0
  fi
  local tail_n=$((EVIDENCE_LINES - head_n))
  printf '       %s, %s bytes, first %s and last %s of %s lines:\n' \
    "$heading" "${#body}" "$head_n" "$tail_n" "$n"
  for ((i = 0; i < head_n; i++)); do printf '       | %s\n' "${lines[i]}"; done
  printf '       | … %s lines elided; EPITO_SMOKE_EVIDENCE_LINES raises this …\n' \
    "$((n - EVIDENCE_LINES))"
  for ((i = n - tail_n; i < n; i++)); do printf '       | %s\n' "${lines[i]}"; done
}

# A one-line haystack is printed whole UNLESS its name says it may hold a
# credential, in which case what is printed is the presence-and-length form
# L-X5 asks for. A failing assertion is the one place a suite prints a value
# nobody chose to print, by name, out of this process's own environment, and
# `tools/check-secret-print.py` reports the line because it cannot resolve an
# indirect expansion to tell whether this one is safe. The words are the
# checker's own list, and its label-suffix exemption is deliberately not
# copied: a haystack named `$KEY_FILE` losing its path from a FAIL line costs
# a reader one `echo`, and the other direction costs a credential.
may_hold_credential() {
  local n w
  n=$(printf '%s' "$1" | tr '[:lower:]' '[:upper:]')
  for w in TOKEN TOKENS SECRET SECRETS PASSWORD PASSWD PASS KEY APIKEY PAT \
           WEBHOOK CREDENTIAL CREDENTIALS COOKIE BEARER AUTH; do
    case "_${n}_" in *_"$w"_*) return 0 ;; esac
  done
  return 1
}

# Resolve `$NAME` and `${NAME}` inside one token of the expression, by
# substitution and never by `eval`: the reader is handed a test that just
# failed, and a reader that EXECUTES it to find out what it looked at can run
# anything the suite could. Needed because a call site written in SINGLE quotes
# hands `check` its paths unexpanded — `grep -q x "$ROOT/bundle/agent.js"`
# arrives with `$ROOT` still in it, so the file branch below saw a token that
# names nothing readable. All four of the per-suite copies had this hole and
# none of them showed it, because the suites they were written for quote their
# call sites the other way and arrive with the path already expanded.
expand_names() {
  local tok="$1" name val
  while [[ "$tok" =~ [$]\{?([A-Za-z_][A-Za-z0-9_]*)\}? ]]; do
    name="${BASH_REMATCH[1]}"; val="${!name:-}"
    # An unset name resolves to nothing, which is what the shell would have
    # done; a name whose value holds a newline is a document and not a path,
    # and substituting it would build a token no file ever matches.
    [ "${val#*$'\n'}" = "$val" ] || return 1
    tok="${tok//"${BASH_REMATCH[0]}"/"$val"}"
  done
  printf '%s' "$tok"
}

# `bad <label> [unevaluated test] [haystack ...]`
bad()  {
  fail=$((fail+1)); printf '  FAIL %s\n' "$1"
  shift
  [ $# -gt 0 ] || return 0
  local test="$1"; shift
  [ -z "$test" ] || printf '       the test: %s\n' "$test"
  local rest="$test" name val w seen shown_any=0
  local -a notes=() docs=() files=() cfiles=()
  # Matched in the shell, not through `grep ... | head -1`: that is a producer
  # piped into a reader that exits on its first line, the shape this
  # repository has spent a week converting out of every suite in here, and the
  # failure path is the last place to introduce one.
  while [[ "$rest" =~ [$]\{?([A-Za-z_][A-Za-z0-9_]*) ]]; do
    name="${BASH_REMATCH[1]}"; rest="${rest#*"${BASH_REMATCH[0]}"}"
    val="${!name:-}"; [ -n "$val" ] || continue
    if [ "${val#*$'\n'}" != "$val" ]; then
      seen=""; for w in ${docs[@]+"${docs[@]}"}; do [ "$w" = "$name" ] && seen=1; done
      [ -n "$seen" ] || docs+=("$name")
    else
      seen=""; for w in ${notes[@]+"${notes[@]}"}; do [ "$w" = "$name" ] && seen=1; done
      [ -n "$seen" ] || notes+=("$name")
    fi
  done
  for name in ${notes[@]+"${notes[@]}"}; do
    val="${!name}"
    if may_hold_credential "$name"; then
      printf '       $%s is set, %s characters — its name says it may be a credential, so this line prints presence and length and never the value (L-X5)\n' "$name" "${#val}"
    else
      printf '       $%s is %s\n' "$name" "$val"
    fi
    shown_any=1
  done
  # The caller's own haystacks, after the expression's because an assertion
  # that names a document in its test is about that document; a third argument
  # is for the assertions whose document was expanded away before `check` ever
  # saw the string.
  for w in "$@"; do
    if [[ "$w" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] && [ -v "$w" ]; then
      # Declared and empty is kept rather than skipped: `[ -z "$verr" ]`
      # failing means stderr had something, and an assertion that a command
      # printed nothing wants "it printed nothing" said out loud when that is
      # what happened.
      docs+=("$w")
    elif [ -f "$w" ] && [ -r "$w" ]; then
      cfiles+=("$w")
    else
      printf '       %s: named as this assertion'"'"'s haystack, and there is nothing there to read\n' "$w"
      shown_any=1
    fi
  done
  local shown=0
  # Two, because the assertions that compare one document against another are
  # unreadable with one of them.
  for name in ${docs[@]+"${docs[@]}"}; do
    val="${!name:-}"
    if may_hold_credential "$name" && [ -n "$val" ] && [ "${val#*$'\n'}" = "$val" ]; then
      printf '       $%s is set, %s characters — its name says it may be a credential, so this line prints presence and length and never the value (L-X5)\n' "$name" "${#val}"
    else
      evidence "\$$name" "$val"
    fi
    shown=$((shown+1)); [ "$shown" = 2 ] && return 0
  done
  for w in ${cfiles[@]+"${cfiles[@]}"}; do
    evidence "$w" "$(cat -- "$w")"
    shown=$((shown+1)); [ "$shown" = 2 ] && return 0
  done
  # The expression's own tokens, with its quoting flattened — and only when
  # nothing above answered. A needle that happens to look like a path is not a
  # risk, because only a token that names a readable file is kept; a file that
  # is merely MENTIONED beside a document is, which is why this never fills the
  # second slot.
  if [ "$shown" -eq 0 ]; then
    local blob="${test//[\'\"]/ }"; blob="${blob//$'\n'/ }"
    local -a words=(); read -ra words <<<"$blob"
    local tok
    for w in ${words[@]+"${words[@]}"}; do
      case "$w" in *'$'*) tok="$(expand_names "$w")" || continue; [ -n "$tok" ] || continue ;; *) tok="$w" ;; esac
      { [ -f "$tok" ] || [ -d "$tok" ]; } && [ -r "$tok" ] || continue
      seen=""; for name in ${files[@]+"${files[@]}"}; do [ "$name" = "$tok" ] && seen=1; done
      [ -n "$seen" ] || files+=("$tok")
    done
    for w in ${files[@]+"${files[@]}"}; do
      # A directory is read as its listing. An assertion that says a dry run
      # created no `.epito/` at all answers, when it fails, with which paths
      # are in it — a `cat` of a directory is an error message and
      # `(names no document)` is a shrug.
      if [ -d "$w" ]; then evidence "$w/ (listing)" "$(find "$w" -print 2>/dev/null | sort)"
      else evidence "$w" "$(cat -- "$w")"; fi
      shown=$((shown+1)); [ "$shown" = 2 ] && return 0
    done
  fi
  # The suite's own last-command variable, by NAME, and only for the suites
  # that keep one and clear it per step. Opt-in for the reason in the header.
  if [ "$shown" -eq 0 ] && [ -n "${EVIDENCE_FALLBACK:-}" ]; then
    val="${!EVIDENCE_FALLBACK:-}"
    # Two kinds of suite keep a last-command variable, and they are opposite.
    # One holds the output; the other holds the PATH the output was written to,
    # because a suite whose assertions grep a file does that so no captured
    # text ever reaches `eval` (pack.sh's reason: `epito token --dry-run`
    # prints `$EPITO_APP_ID_<NAME>` and a `<port>` placeholder, which a `check`
    # that interpolated its output would hand to the shell to expand). Printing
    # the second as though it were the first gives a reader one line of path
    # where the document should be, so the file is read.
    if [ -n "$val" ] && [ "${val#*$'\n'}" = "$val" ] && [ -f "$val" ] && [ -r "$val" ]; then
      evidence "$val" "$(cat -- "$val")"; shown=$((shown+1))
    elif [ -n "$val" ]; then
      evidence "\$$EVIDENCE_FALLBACK" "$val"; shown=$((shown+1))
    fi
  fi
  # A single-line haystack printed as a note above IS the answer, so the line
  # below fires only when nothing at all was said — which is honest.
  [ "$shown" -gt 0 ] || [ "$shown_any" = 1 ] \
    || printf '       (this assertion names no document; what it looked at is in the test above)\n'
}

# `check <label> <unevaluated test> [haystack ...]` — the test reaches `bad`
# unevaluated, which is the whole point: `check` is handed a string, so the
# `$NAME`s in it survive to the failure path.
check(){ local t="$2"; if eval "$t"; then ok "$1"; else bad "$@"; fi; }

# ---- the reader's own negative control -------------------------------------
# A reader that prints nothing passes every suite. So this file is runnable,
# and what it runs is one planted fault per branch of `bad`, plus the five
# things that must NOT happen: a credential printed, a fallback fired in a
# suite that keeps none, another section's document under this assertion, an
# `ok` that prints evidence, and a verdict that disagrees with the exit code.
#
#   bash test/evidence.sh --self-test
#
# Asserted with bash's own `[[ == ]]` and never `grep -F`: a needle with a
# newline in it is a PATTERN LIST to `grep -F`, so a two-line assertion
# becomes an OR pretending to be an AND (docs/backlog.md's own card for it).
[ "${BASH_SOURCE[0]}" = "${0}" ] || return 0
case "${1:-}" in
  --self-test) ;;
  *) printf 'test/evidence.sh: this file is sourced by the suites. To run its own checks:\n\n  bash test/evidence.sh --self-test\n' >&2; exit 2 ;;
esac

t_ok=0; t_bad=0
want()    { if [[ "$2" == *"$3"* ]]; then printf '  ok    %s\n' "$1"; t_ok=$((t_ok+1));
            else printf '  FAIL  %s\n         wanted: %s\n         got:\n%s\n' "$1" "$3" "$(printf '%s\n' "$2" | sed 's/^/           /')"; t_bad=$((t_bad+1)); fi; }
wantnot() { if [[ "$2" != *"$3"* ]]; then printf '  ok    %s\n' "$1"; t_ok=$((t_ok+1));
            else printf '  FAIL  %s\n         must not carry: %s\n         got:\n%s\n' "$1" "$3" "$(printf '%s\n' "$2" | sed 's/^/           /')"; t_bad=$((t_bad+1)); fi; }

# The suite side of the contract, as small as a suite can be.
pass=0; fail=0
ok() { pass=$((pass+1)); printf '  ok   %s\n' "$1"; }
SELF="${TMPDIR:-/tmp}/epito-evidence-selftest-$$"
mkdir -p "$SELF/adir"
printf 'first\nsecond\nthird\n' > "$SELF/report.log"
printf 'a\nb\n' > "$SELF/adir/inner.txt"

DOC=$'verdict: no\nrow one\nrow two'
ONELINE='7788'
GH_TOKEN='ghs_abcdefghijklmnopqrstuvwxyz'
LONG="$(for i in $(seq 1 40); do printf 'line %s\n' "$i"; done)"
EMPTY=''
LAST=$'the last command said this\nand this'

out="$(bad 'a label' 'said "$DOC" verdict' 2>&1)"
want 'the unevaluated test is printed'            "$out" 'the test: said "$DOC" verdict'
want 'a multi-line $NAME is read as the document' "$out" '$DOC, 27 bytes, all 3 lines:'
want '...and its lines are quoted, not summarised' "$out" '| verdict: no'

out="$(bad 'a label' '[ "$ONELINE" = 80 ]' 2>&1)"
want 'a one-line $NAME is a note, not a document'  "$out" '$ONELINE is 7788'
wantnot '...and is not framed as a document'       "$out" 'all 1 lines'

out="$(bad 'a label' 'curl -H "$GH_TOKEN" /x' 2>&1)"
want 'a credential-named $NAME prints its length'  "$out" '$GH_TOKEN is set, 30 characters'
wantnot '...and never its value'                   "$out" 'ghs_abcdefghijklmnopqrstuvwxyz'

out="$(bad 'a label' '[ $rc -eq 0 ]' GH_TOKEN 2>&1)"
want 'a credential named as a HAYSTACK is redacted too' "$out" '$GH_TOKEN is set, 30 characters'
wantnot '...which the per-suite copies did not do'      "$out" 'ghs_abcdefghijklmnopqrstuvwxyz'

out="$(bad 'a label' '[ $rc -eq 0 ]' DOC 2>&1)"
want "a caller's third argument names the document" "$out" '$DOC, 27 bytes, all 3 lines:'

out="$(bad 'a label' '[ $rc -eq 0 ]' EMPTY 2>&1)"
want 'a haystack that is empty says so'             "$out" '$EMPTY is empty'

out="$(bad 'a label' "grep -q needle '$SELF/report.log'" 2>&1)"
want 'a readable file in the expression is read'     "$out" "$SELF/report.log, 18 bytes, all 3 lines:"
want '...and printed'                                "$out" '| second'

SELFDIR="$SELF"
out="$(bad 'a label' 'grep -q needle "$SELFDIR/report.log"' 2>&1)"
want 'a path still carrying $NAME is resolved, not skipped' "$out" "$SELF/report.log, 18 bytes, all 3 lines:"
wantnot '...and the expression is never evaluated to find it' "$out" 'the test: grep -q needle /'

out="$(bad 'a label' "[ ! -d '$SELF/adir' ]" 2>&1)"
want 'a directory is read as its listing'            "$out" "$SELF/adir/ (listing)"
want '...naming what is in it'                       "$out" "| $SELF/adir/inner.txt"

out="$(bad 'a label' '[ 1 = 2 ]' "$SELF/nothing-here" 2>&1)"
want 'a haystack that is not there is named as absent' "$out" 'nothing-here: named as this assertion'"'"'s haystack, and there is nothing there to read'

out="$(bad 'a label' '[ 1 = 2 ]' 2>&1)"
want 'an assertion naming no document says that'     "$out" '(this assertion names no document'
wantnot '...and does not reach for a variable nobody scoped' "$out" '$LAST'

out="$(bad 'a label' 'said "$LONG" nope' 2>&1)"
want 'a long document is printed from both ends'     "$out" 'first 12 and last 12 of 40 lines:'
want '...with the count between them'                "$out" '| … 16 lines elided'
want '...the head'                                   "$out" '| line 1'
want '...and the tail'                               "$out" '| line 40'

EVIDENCE_FALLBACK=LAST
out="$(bad 'a label' '[ 1 = 2 ]' 2>&1)"
want 'a suite that keeps a last-command variable gets it' "$out" '$LAST, 35 bytes, all 2 lines:'
EVIDENCE_FALLBACK=OUTFILE; OUTFILE="$SELF/report.log"
out="$(bad 'a label' '[ 1 = 2 ]' 2>&1)"
want 'a suite whose variable holds a PATH gets the file, not the path' "$out" "$SELF/report.log, 18 bytes, all 3 lines:"
wantnot '...and not one line of path where the document goes'          "$out" '$OUTFILE is'
EVIDENCE_FALLBACK=

# The two things the caller actually reads.
fail=0; out="$(check 'a true test' '[ 1 = 1 ]' 2>&1)"
want 'check calls ok on a test that passes'          "$out" 'ok   a true test'
wantnot '...and prints no evidence under a pass'     "$out" 'the test:'
[ "$fail" = 0 ] && { printf '  ok    ...and leaves the fail counter alone\n'; t_ok=$((t_ok+1)); } \
                || { printf '  FAIL  a passing check moved the fail counter to %s\n' "$fail"; t_bad=$((t_bad+1)); }

fail=0; out="$(check 'a false test' 'said "$DOC" absent' 2>&1; printf 'fail=%s' "$fail")"
want 'check hands the test to bad unevaluated'       "$out" 'the test: said "$DOC" absent'
want '...and counts the failure'                     "$out" 'fail=1'

rm -rf "$SELF"
printf '\nevidence: %s ok, %s failed\n' "$t_ok" "$t_bad"
[ "$t_bad" = 0 ] || exit 1
