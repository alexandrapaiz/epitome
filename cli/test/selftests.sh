#!/usr/bin/env bash
# A self-test's exit code is a statement about its own assertions and nothing
# else. This is the gate for that, over the seats' own decision tools.
#
#   bash test/selftests.sh          # from cli/
#   bash test/selftests.sh --list   # every tool's two verdicts, including the green ones
#   bash test/selftests.sh --only stage.sh
#
# WHY THIS EXISTS. `docs/agents/` holds eighteen tools that advertise
# `--self-test`, and a seat runs one to answer a single question: *does this
# instrument work*. Two of them answered a different question instead, one
# directory and one day apart:
#
#   pointers.sh   ended its self-test `exit $rc`, where $rc is the real scan's.
#                 The scan legitimately answers 1 while six of seven charters
#                 do not name the vendored register, so the self-test reported
#                 1 with every expectation in it satisfied — and the
#                 expectations were only PRINTED, never scored, so nothing in
#                 it could have failed anyway.
#   stage.sh      handed stages 1 and 2 the live clone. On a shallow clone, the
#                 only kind a seat gets, stage 1 is could-not-look, the first
#                 gap moves from `installed` to `written`, and the tool printed
#                 `self-test FAILED` while behaving exactly as designed. The
#                 same box answered 11 ok / 1 FAIL at 00:10Z on 2026-11-02 and
#                 11 ok / 0 FAIL an hour later, because something unshallowed
#                 the clone in between.
#
# Both are fixed. The general case is not a third card: it is this file. A seat
# that reads FAILED from a working instrument distrusts the instrument, and the
# next thing it distrusts is the answer the instrument gave it about a pull
# request.
#
# TWO QUESTIONS PER TOOL, BOTH BEHAVIOURAL — this reads no source and guesses
# at no idiom, because the directory has several and none of them is wrong:
#
#   1. does the exit code agree with the tool's own scoreboard
#      A run that printed no FAIL row must exit 0; a run that printed FAIL rows
#      must not. A self-test that prints FAIL and exits 0 is the dangerous
#      direction: it is believed.
#   2. does the verdict move with the checkout
#      The same self-test is run twice — here, and inside a throwaway
#      one-commit repository this gate builds — and the exit code must be the
#      same both times. A self-test that builds its own fixture cannot tell the
#      difference. One that reads the repository it happens to be standing in
#      answers about that repository, which is question 1 in a different
#      costume.
#
# THE LEDGER, below, holds the tools that fail question 2 today, with what each
# one answered when it was measured. It is not an exemption: a ledgered tool is
# asserted to move EXACTLY as recorded, so a row goes red when the tool changes
# in either direction, and the row is deleted when the tool is fixed. A tool
# absent from the ledger is allowed no movement at all. Rows only ever leave.
set -uo pipefail
CLI="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT="$(cd "$CLI/.." && pwd)"
TOOLS="$ROOT/docs/agents"
LIST=0
ONLY=
while [ $# -gt 0 ]; do
  case "$1" in
    --list) LIST=1; shift ;;
    --only) ONLY=${2:?--only needs a tool name, e.g. --only stage.sh}; shift 2 ;;
    *) printf 'test/selftests.sh: unknown option "%s". There are two: --list, and --only <tool.sh>.\n' "$1"; exit 2 ;;
  esac
done

# tool.sh|rc here|rc elsewhere|what moves, measured
# Measured 2026-11-02 00:2xZ on this branch, one run of each tool in each place.
# Five of eighteen. Two more were in this table an hour ago and are not now,
# which is what a row leaving looks like: pointers.sh and stage.sh.
LEDGER='
drafts.sh|0|1|its self-test ends on the scan`s own verdict, so a repository with no drafts in it reads as a failing instrument
offmain.sh|0|2|the same shape, and the second checkout has no `origin`, which the scan reports as could-not-look (exit 2) over whatever its assertions said
reverted.sh|0|1|the same shape again, on a scan that answers about reverted commits this other repository does not have
post.sh|0|1|eight of its assertions read files of THIS repository as their fixtures, so they fail wherever the repository is not
roster.sh|0|1|three of its assertions read this repository`s own roster as their fixture
'

WORK="$(mktemp -d "${TMPDIR:-/tmp}/epito-selftests-XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
ELSEWHERE="$WORK/elsewhere"
mkdir -p "$ELSEWHERE"
git init -q -b main "$ELSEWHERE"
git -C "$ELSEWHERE" config user.email selftests@epito.me
git -C "$ELSEWHERE" config user.name 'test/selftests.sh'
printf 'a repository that is not this one\n' > "$ELSEWHERE/README.md"
git -C "$ELSEWHERE" add -A
git -C "$ELSEWHERE" commit -qm 'one commit, so this is a repository and not a bare directory'

ok=0; failed=0; unrun=0; asked=0
pass() { printf '  ok   %s\n' "$1"; ok=$((ok + 1)); }
bad()  {
  printf '  FAIL %s\n' "$1"
  [ -n "${2:-}" ] && sed 's/^/       /' <<<"$2"
  failed=$((failed + 1))
}
# The ledger row for a tool, read without a pipe into a reader that exits early.
ledger_row() {
  local l
  while IFS= read -r l; do
    case "$l" in "$1|"*) printf '%s\n' "$l"; return 0 ;; esac
  done <<<"$LEDGER"
  return 1
}
fails_in() {  # how many FAIL rows a self-test printed
  local n=0 l
  while IFS= read -r l; do
    case "$l" in *FAIL*) n=$((n + 1)) ;; esac
  done <<<"$1"
  printf '%s\n' "$n"
}

printf '\n== every --self-test in docs/agents/, twice: here, and in a repository that is not this one\n\n'

for f in "$TOOLS"/*.sh; do
  b=$(basename "$f")
  [ -n "$ONLY" ] && [ "$b" != "$ONLY" ] && continue
  grep -qF -- '--self-test' "$f" || continue
  asked=$((asked + 1))

  here=$( cd "$ROOT" && timeout 180 bash "$f" --self-test 2>&1 ); rc_here=$?
  away=$( cd "$ELSEWHERE" && timeout 180 bash "$f" --self-test 2>&1 ); rc_away=$?
  fh=$(fails_in "$here"); fa=$(fails_in "$away")

  if [ "$rc_here" = 124 ] || [ "$rc_away" = 124 ]; then
    printf '  unrun %s — its self-test did not finish inside 180s, so nothing here was asserted about it\n' "$b"
    unrun=$((unrun + 1))
    continue
  fi

  # 1. the exit code against the tool's own scoreboard, in both checkouts.
  for where in here away; do
    if [ "$where" = here ]; then rc=$rc_here; n=$fh; txt=$here; label="in this repository"
    else rc=$rc_away; n=$fa; txt=$away; label="in a repository that is not this one"; fi
    if [ "$n" -gt 0 ] && [ "$rc" = 0 ]; then
      bad "$b: $n of its own assertions FAILED $label and it exited 0 — a false green is believed" \
        "$(grep -E 'FAIL' <<<"$txt" | head -3)"
    elif [ "$n" = 0 ] && [ "$rc" != 0 ] && [ "$where" = here ]; then
      bad "$b: nothing in it failed $label and it exited $rc — the exit code is reporting something other than its assertions" \
        "$(tail -3 <<<"$txt")"
    else
      [ "$LIST" = 1 ] && printf '  ok   %s: exit %s agrees with %s FAIL row(s) %s\n' "$b" "$rc" "$n" "$label"
      ok=$((ok + 1))
    fi
  done

  # 2. the verdict against the checkout it was run in.
  if row=$(ledger_row "$b"); then
    IFS='|' read -r _ want_here want_away why <<<"$row"
    if [ "$rc_here" = "$want_here" ] && [ "$rc_away" = "$want_away" ]; then
      printf '  known %s: exit %s here, %s elsewhere — %s\n' "$b" "$rc_here" "$rc_away" "$why"
      ok=$((ok + 1))
    else
      bad "$b: the ledger says exit $want_here here and $want_away elsewhere; it answered $rc_here and $rc_away" \
        "The ledger is a measurement, not an exemption. If this tool was fixed, delete its row. If it moved some other way, say which."
    fi
  elif [ "$rc_here" = "$rc_away" ]; then
    [ "$LIST" = 1 ] && printf '  ok   %s: exit %s in both checkouts\n' "$b" "$rc_here"
    ok=$((ok + 1))
  else
    # The failing rows first when there are any: the last three lines of a
    # self-test are its tally, and a reader handed the tally has to run the
    # thing again to see what moved.
    evidence=$(grep -E 'FAIL' <<<"$away" | head -3)
    [ -n "$evidence" ] || evidence=$(tail -3 <<<"$away")
    bad "$b: exit $rc_here here and $rc_away in a repository that is not this one — its verdict is a property of the checkout, not of its own assertions" \
      "$evidence
Build what it reads (docs/agents/stage.sh --self-test is the worked example), or
add a row to the ledger in this file with both numbers and what moves."
  fi
done

# A run that asked nothing must not read like a run that found nothing wrong —
# which is this gate's own subject: `--only typo.sh` printed `0 ok, 0 failed`
# and exited 0, an instrument answering a question nobody put to it.
if [ "$asked" = 0 ]; then
  printf '\ntest/selftests.sh: nothing was asserted. '
  if [ -n "$ONLY" ]; then
    printf 'No tool in docs/agents/ is named "%s" and advertises --self-test.\n' "$ONLY"
  else
    printf 'No tool in %s advertises --self-test at all.\n' "$TOOLS"
  fi
  printf '\nThe ones that do:\n\n'
  for f in "$TOOLS"/*.sh; do
    grep -qF -- '--self-test' "$f" && printf '  %s\n' "$(basename "$f")"
  done
  printf '\nDrop --only to ask all of them.\n'
  exit 2
fi

printf '\nselftests: %d ok, %d failed' "$ok" "$failed"
[ "$unrun" -gt 0 ] && printf ', %d unrun' "$unrun"
printf '\n'
[ "$failed" = 0 ] || exit 1
exit 0
