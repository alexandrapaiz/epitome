#!/usr/bin/env bash
# The L-X5 credential scan for THIS repository, as a thing that runs.
#
#   bash tools/scan-secret-print.sh              scan, honouring the baseline
#   bash tools/scan-secret-print.sh --raw        scan with the baseline off
#   bash tools/scan-secret-print.sh --list       print the surfaces, scan nothing
#   bash tools/scan-secret-print.sh --self-test  the three answers, on built input
#
# Exit 0 nothing unaccepted, 1 at least one finding, 2 could not look (L41).
#
# WHY THIS EXISTS. Until now this invocation was a COMMENT at the top of
# `tools/secret-print-baseline.txt`, printed beside the claim that the scan
# exits 0. The exo seat copied the line on 2026-11-02 and got 34 findings and
# exit 1, because the printed command omitted `--baseline`. The claim was true
# and the command next to it did not produce it, and nothing could have noticed:
# a command in a comment is read by people and run by nothing.
#
# That is `docs/standards/lessons.md` L-A114 one step further out. A pre-flight
# that prints is not a pre-flight that blocks; a *documented command* that
# nothing executes is not a documented command, it is prose about one. So the
# invocation moves into a file, the wiring test runs that file, and the baseline
# header and `.claude/README.md` point here instead of retyping it. A CI gate —
# which is a workflow, and not this seat's to write — is now one line: this one.
#
# WHY THE SURFACES COME FROM `git ls-files` AND NOT FROM A GLOB LIST. The same
# pass found the hand-written list two sites short of the trunk on the day it
# was written: `docs/agents/stage.sh` prints an assertion tally like every other
# suite here, and the baseline's globs named `cli/test/*.sh` and `deploy/*.sh`,
# so the file was scanned and its findings were accepted nowhere. A list of
# directories somebody maintains is a list that goes stale the next time
# somebody adds a directory. The tracked file set does not.
#
# It also closes a hole neither of us had looked for. The old list covered the
# shell and the workflows and skipped `cli/src/` entirely — 57 files, the whole
# product — and that is where this repository's one genuine credential print
# lives: `runner.js` writes a git credential helper, whose contract with git IS
# to print the credential on a pipe git owns. The scan that was reported as
# green over this repository had never looked at the product.
set -uo pipefail
cd "$(git rev-parse --show-toplevel)" 2>/dev/null || {
  echo "could not look: tools/scan-secret-print.sh reads the tracked file set, so it must run inside this git repository" >&2
  exit 2
}

CHECKER=tools/check-secret-print.py
BASELINE=tools/secret-print-baseline.txt

# The two names this product's secrets carry that no credential word covers.
# `CALLMEBOT_PHONE` and the `PHONE` it is exposed as are the owner's phone
# number: nothing personal enters this repository's output, and the checker's
# name rule cannot know that from the name alone.
NAMES=(--name CALLMEBOT_PHONE --name PHONE)

# Every tracked file the checker can read as code. An extension list rather
# than "every tracked file", because the checker scans text line by line and a
# register quoting the idioms it forbids is not a surface that runs.
EXT='\.(sh|bash|py|yml|yaml|js|mjs|cjs|ts)$'

surfaces() { git ls-files -z | tr '\0' '\n' | grep -E "$EXT"; }

RAW=0
case "${1:-}" in
  --raw)  RAW=1 ;;
  --list) surfaces; exit 0 ;;
  --self-test) ;;
  "") ;;
  *) echo "could not look: tools/scan-secret-print.sh takes --raw, --list or --self-test, not $1" >&2; exit 2 ;;
esac

if [ "${1:-}" = --self-test ]; then
  # A negative control, not a smoke test. The real run answers 0 today, so a
  # script hard-wired to exit 0 would pass it and prove nothing. So: a built
  # tree with one planted leak (1), the same tree with that leak accepted (0),
  # and a run with the checker removed (2).
  fail=0
  say() { if [ "$1" = 0 ]; then printf '  ok    %s\n' "$2"; else printf '  FAIL  %s — %s\n' "$2" "$3"; fail=1; fi; }
  tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
  ( cd "$tmp" && git init -q . && mkdir -p tools )
  cp "$CHECKER" "$tmp/tools/"
  cp tools/scan-secret-print.sh "$tmp/tools/"
  printf '#!/usr/bin/env bash\necho "the key is $DEPLOY_SECRET_KEY"\n' > "$tmp/leak.sh"
  : > "$tmp/tools/secret-print-baseline.txt"
  ( cd "$tmp" && git add -A >/dev/null 2>&1 )
  out=$( cd "$tmp" && bash tools/scan-secret-print.sh 2>&1 ); code=$?
  say "$([ "$code" = 1 ] && echo 0 || echo 1)" "a planted leak exits 1" "exit $code: $out"
  case "$out" in *leak.sh*) say 0 "...and names the file it is in" ;;
                 *) say 1 "...and names the file it is in" "$out" ;; esac
  printf 'leak.sh | X5-PRINT | echo "the key is $DEPLOY_SECRET_KEY"\n' > "$tmp/tools/secret-print-baseline.txt"
  out=$( cd "$tmp" && bash tools/scan-secret-print.sh 2>&1 ); code=$?
  say "$([ "$code" = 0 ] && echo 0 || echo 1)" "the same leak, accepted in the baseline, exits 0" "exit $code: $out"
  rm -f "$tmp/tools/check-secret-print.py"
  out=$( cd "$tmp" && bash tools/scan-secret-print.sh 2>&1 ); code=$?
  say "$([ "$code" = 2 ] && echo 0 || echo 1)" "no checker is could-not-look, never agreement" "exit $code: $out"
  case "$out" in *"could not look"*) say 0 "...and says so in those words" ;;
                 *) say 1 "...and says so in those words" "$out" ;; esac
  [ "$fail" = 0 ] && echo "self-test: all verdicts agree" || echo "self-test FAILED"
  exit "$fail"
fi

[ -f "$CHECKER" ] || {
  echo "could not look: $CHECKER is not in this checkout, so nothing scanned the tree. Fix: re-vendor it from alexandrapaiz/alexandra-systems tools/check-secret-print.py (see .claude/README.md)" >&2
  exit 2
}

args=("${NAMES[@]}")
if [ "$RAW" = 0 ]; then
  [ -f "$BASELINE" ] || {
    echo "could not look: $BASELINE is not in this checkout, and scanning without it reports every accepted finding as new. Fix: restore the baseline, or pass --raw if you meant to see all of them" >&2
    exit 2
  }
  args+=(--baseline "$BASELINE")
fi

mapfile -t files < <(surfaces)
[ "${#files[@]}" -gt 0 ] || {
  echo "could not look: no tracked file matched the scanned extensions, which cannot be right for this repository" >&2
  exit 2
}

python3 "$CHECKER" "${args[@]}" "${files[@]}"
code=$?
if [ "$code" = 0 ]; then
  printf 'secret-print scan: %d tracked file(s), nothing unaccepted.\n' "${#files[@]}"
elif [ "$code" = 1 ]; then
  printf '\nsecret-print scan: %d tracked file(s). Each finding above is either a real print — rewrite it — or one this product accepts, which goes in %s with a written reason, never as a silent skip.\n' "${#files[@]}" "$BASELINE" >&2
fi
exit "$code"
