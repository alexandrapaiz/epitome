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
#
# A row records FOUR numbers and not two, because the sentence above was false
# while it recorded two. post.sh was ledgered on 2026-11-02 with a row whose
# prose says "eight of the assertions"; it was changed five times in the days
# after, and on 2026-11-09 the same self-test prints EIGHTEEN FAIL rows in the
# other checkout. Both exit codes were unmoved, so the row stayed green and
# this gate had no opinion about a ledgered tool's failure count more than
# doubling. The scoreboard is the thing a ledgered tool is being watched for.
set -uo pipefail
CLI="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT="$(cd "$CLI/.." && pwd)"
TOOLS="$ROOT/docs/agents"
LIST=0
ONLY=
# Per tool, per checkout. Measured 2026-11-09 rather than guessed: the slowest
# self-test in the directory is executing.sh at 4m12s — seventeen assertions,
# no sleeps, real clones and fetches each time — and the cap it was handed was
# 180s, so it was `unrun` in every run of this gate there has ever been. 420
# leaves it 2m38s of headroom on the box it was measured on. Overridable so the
# refusal above can be PERFORMED and not just described — `CAP=1 bash
# test/selftests.sh --only idle.sh` is the command that proves it fails.
CAP=${CAP:-420}
while [ $# -gt 0 ]; do
  case "$1" in
    --list) LIST=1; shift ;;
    --only) ONLY=${2:?--only needs a tool name, e.g. --only stage.sh}; shift 2 ;;
    *) printf 'test/selftests.sh: unknown option "%s". There are two: --list, and --only <tool.sh>.\n' "$1"; exit 2 ;;
  esac
done

# tool.sh|rc here|rc elsewhere|FAIL rows here|FAIL rows elsewhere|what moves
# Measured 2026-11-02 00:2xZ, one run of each tool in each place: five of
# eighteen. Re-measured 2026-11-09, and three of the five left — drafts.sh,
# offmain.sh, reverted.sh — which is what a row leaving looks like. Two more
# left the same way a week earlier: pointers.sh and stage.sh.
#
# All three of those rows named the WRONG CAUSE, which is why the fix was three
# fixes and not one. None of the three ended on the scan's verdict. drafts.sh
# resolved its sibling `liveness.py` through `git rev-parse --show-toplevel`
# and died on ModuleNotFoundError with none of its own assertions run;
# reverted.sh re-invoked itself through the same toplevel, so all three of its
# constructed cases read an empty verdict from a file that was not there; and
# offmain.sh ran four of the scan's preconditions — the unshallow, `gh`, the
# fetch of main and the pull refs, the base ref — before the mode dispatch, so
# it exited 2 with nine of nine satisfied and none printed. A row in this
# table is a measurement of the EXIT CODES and is trustworthy as that; its
# fourth field is a reading of a cause and the next hand should re-derive it.
LEDGER='
post.sh|0|1|0|18|the assertions read files of THIS repository as their fixtures, so they fail wherever the repository is not. Eighteen of them, re-counted 2026-11-09; the row that landed 2026-11-02 said eight and could not have noticed the difference
roster.sh|1|1|3|3|re-measured 2026-11-09: 1 in BOTH checkouts, and its three assertions now FAIL here too. The probe it re-invokes refuses with could-not-look (exit 2) because this box holds no /srv/asc/roster/epitome, so the field under test, binary_reachable_from_main, is never printed for any of the three to read. This row read 0 here on 2026-11-02, when the box did hold it. Nothing in the tool changed; what it reads did — the exact drift its own card predicted
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
  # Anchored the way test/all.sh anchors it, so a tally line reading
  # `self-test FAILED: 19 ok, 1 failed` is not counted as a nineteenth failing
  # assertion. A count that is off by one is a count nobody trusts twice.
  local n=0 l
  while IFS= read -r l; do
    [[ $l =~ ^[[:space:]]*(FAIL|not\ ok)([[:space:]]|$) ]] && n=$((n + 1))
  done <<<"$1"
  printf '%s\n' "$n"
}

printf '\n== every --self-test in docs/agents/, twice: here, and in a repository that is not this one\n\n'

for f in "$TOOLS"/*.sh; do
  b=$(basename "$f")
  [ -n "$ONLY" ] && [ "$b" != "$ONLY" ] && continue
  grep -qF -- '--self-test' "$f" || continue
  asked=$((asked + 1))

  here=$( cd "$ROOT" && timeout "$CAP" bash "$f" --self-test 2>&1 ); rc_here=$?
  away=$( cd "$ELSEWHERE" && timeout "$CAP" bash "$f" --self-test 2>&1 ); rc_away=$?
  fh=$(fails_in "$here"); fa=$(fails_in "$away")

  # A tool this gate could not finish reading is a tool this gate knows nothing
  # about, and that is the one thing the file's own rule below forbids: "a run
  # that asked nothing must not read like a run that found nothing wrong". It
  # read like one anyway — `unrun` has its own counter, printed after the
  # verdict, and nothing in the exit code. executing.sh timed out here on every
  # run from the day this gate landed, so seventeen assertions about the single
  # reader of the host's distance from main were never once checked by it.
  if [ "$rc_here" = 124 ] || [ "$rc_away" = 124 ]; then
    bad "$b: its self-test did not finish inside ${CAP}s, so nothing here was asserted about it" \
      "A gate that cannot read a tool has no opinion about it, and no opinion must not
read as no finding. Either the tool got slower than $CAP seconds or it hangs;
measure it (\`time bash docs/agents/$b --self-test\`) and say which."
    unrun=$((unrun + 1))
    continue
  fi

  # 1. the exit code against the tool's own scoreboard, in both checkouts.
  for where in here away; do
    if [ "$where" = here ]; then rc=$rc_here; n=$fh; txt=$here; label="in this repository"
    else rc=$rc_away; n=$fa; txt=$away; label="in a repository that is not this one"; fi
    if [ "$n" -gt 0 ] && [ "$rc" = 0 ]; then
      bad "$b: $n of its own assertions FAILED $label and it exited 0 — a false green is believed" \
        "$(grep -E '^[[:space:]]*(FAIL|not ok)' <<<"$txt" | head -3)"
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
    IFS='|' read -r _ want_here want_away wantf_here wantf_away why <<<"$row"
    if [ "$rc_here" = "$want_here" ] && [ "$rc_away" = "$want_away" ] \
       && [ "$fh" = "$wantf_here" ] && [ "$fa" = "$wantf_away" ]; then
      printf '  known %s: exit %s here with %s FAIL row(s), %s elsewhere with %s — %s\n' \
        "$b" "$rc_here" "$fh" "$rc_away" "$fa" "$why"
      ok=$((ok + 1))
    else
      bad "$b: the ledger says exit $want_here/$want_away with $wantf_here/$wantf_away FAIL rows (here/elsewhere); it answered $rc_here/$rc_away with $fh/$fa" \
        "The ledger is a measurement, not an exemption. If this tool was fixed, delete its
row. If it moved some other way, re-measure all four numbers and say which moved —
a row that records only the exit codes is how post.sh's failure count went from
eight to eighteen with this gate reading green."
    fi
  elif [ "$rc_here" = "$rc_away" ]; then
    [ "$LIST" = 1 ] && printf '  ok   %s: exit %s in both checkouts\n' "$b" "$rc_here"
    ok=$((ok + 1))
  else
    # The failing rows first when there are any: the last three lines of a
    # self-test are its tally, and a reader handed the tally has to run the
    # thing again to see what moved.
    evidence=$(grep -E '^[[:space:]]*(FAIL|not ok)' <<<"$away" | head -3)
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
