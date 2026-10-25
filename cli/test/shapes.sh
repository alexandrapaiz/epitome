#!/usr/bin/env bash
# The shapes a gate in this repository may not have. One scan, no prerequisites,
# runs in milliseconds, and it exists because the fault it looks for cannot be
# caught by running the suites: a suite carrying it passes.
#
#   bash test/shapes.sh            # from cli/
#   bash test/shapes.sh --list     # print every site it finds, converted or not
#
# The shape: `<producer> | grep -q '<pattern>'` under `set -o pipefail`. Quiet
# grep exits the instant it matches; the producer whose pipe it just closed dies
# writing into it; and `pipefail` makes the pipeline's status that death rather
# than grep's own 0. So the gate can print FAIL for a pattern it MATCHED.
#
# Measured on 2026-10-24, reading PIPESTATUS before anything else reads `$?`
# (any simple command, `st=$?` included, overwrites PIPESTATUS with its own
# one-element status, and that `[0]` reads the same for a real failure as for a
# false one). With the real binaries, at load 22, by the producer's output size:
#
#   1 KiB, 16 KiB, 64 KiB   0 false failures in 20 invocations each
#   256 KiB, 1 MiB          20 of 20, every time — curl exits 23, node exits 1
#
# Read then as a 64 KiB threshold: below the pipe buffer the write lands in the
# buffer, the producer exits, and grep can close nothing. That reading is wrong,
# and twenty invocations per size is why it survived. Re-measured the same day
# with 500 asks per cell and a `printf` producer, which is what the suites use
# (test/probe-readers.sh, at load 13-16):
#
#   1 KiB    needle on line 1    1 of 500 wrong      needle on the last line  0 of 500
#   8 KiB    needle on line 1    8 of 500 wrong      needle on the last line  0 of 500
#   64 KiB   needle on line 1  442 of 500 wrong      needle on the last line  0 of 500
#
# Every wrong verdict is PIPESTATUS `141 0`: grep MATCHED and exited 0, and the
# producer was killed writing the rest. So the race is not about the buffer at
# all — it is about whether grep can match before the producer has finished
# writing, which the needle's POSITION decides and the output's size only makes
# more likely. A needle on the last line cannot lose the race; a needle in a
# report's first rows loses it about once in a hundred asks at a kilobyte.
#
# What follows is that the remaining sites in the allowance below are not
# latent. They are misfiring now, at a rate low enough to read as a flake —
# docs/ideas.md's row on assertions that cannot run is this, and smoke-doctor.sh
# had one failure per run for three runs before its conversion. The allowance
# may only ever go down, and output grows: the shape does not get better.
#
# The fix at a call site is a herestring, which has no pipe and no second
# process to kill:
#
#   -  printf '%s' "$OUT" | grep -q 'pattern'
#   +  said "$OUT" 'pattern'          # said() { local h=$1; shift; grep -q "$@" <<<"$h"; }
set -uo pipefail
CLI="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT="$(cd "$CLI/.." && pwd)"
LIST=0
for a in "$@"; do case "$a" in
  --list) LIST=1 ;;
  *) printf 'test/shapes.sh: unknown option "%s". There is one: --list, which prints every site it finds.\n' "$a"; exit 2 ;;
esac; done

# A pipe into grep whose option tokens carry a quiet flag. The option run stops
# at the first token that is not an option, which is why `| grep -c "x" ) -eq 4`
# does not match: `-eq` is not reachable from `grep` through options alone.
SHAPE='\|[[:space:]]*grep[[:space:]]+((-[A-Za-z]+|--[a-z-]+)[[:space:]]+)*(-[A-Za-z]*q[A-Za-z]*|--quiet|--silent)([[:space:]]|$)'

# The allowance: what each file still carries, and the ceiling it may not pass.
# A file absent from this list is allowed none. Lower a number when you convert
# a suite; there is no reason for one to rise, and a rise is what this fails on.
# Counts re-read on `main` at 2026-10-25 02:4xZ, after the deploy suite's
# conversion and the recalibration that followed it: 57 sites in six files,
# less the 31 in smoke-doctor.sh that this branch converts. What is left after
# this branch is smoke-langgraph.sh (19), smoke-bus.sh (2), pack.sh (2) and the
# two deploy scripts (5), which the board card asks to land last and separately
# -- a false failure in the middle of provisioning a box is worse than a false
# failure in a test.
#
# Three lines here are not allowances but exemptions, and they are named rather
# than hidden: probe-pipefail.sh carries five of the shape, probe-negated.sh
# two, and probe-readers.sh two, because exhibiting it IS what those three
# files are for -- the third one asks the removed reader and the two
# replacement readers the same captured bytes, and then asks the removed one
# again at three output sizes and two needle positions, so it spells the shape
# twice. Of probe-negated's two, one is executed and one is the `printf` that
# labels it for the reader -- this scan cannot tell a gate from a sentence
# about a gate, and inventing a comment convention to hide the second would
# make the count a matter of formatting. Both are counted so that neither file
# can quietly grow one more.
#
# Converted and therefore absent, allowed none: smoke-validate.sh,
# smoke-temporal.sh, smoke-roster.sh, all.sh, smoke-deploy.sh, and
# smoke-doctor.sh here. A number may only be lowered by a branch that can see
# its conversion land: a number that is too HIGH costs one advisory line, and a
# number lowered for a conversion that does not land fails this gate on main.
# The stale direction is the safe one, so this file will always trail a merge
# by a pass; what follows is that whoever converts the next suite lowers its
# predecessor's too, which is what main's own 22:5xZ pass did for the roster
# and deploy suites and what this one does for the doctor's.
ALLOWED="
cli/test/probe-pipefail.sh 5
cli/test/probe-negated.sh 2
cli/test/probe-readers.sh 2
cli/test/smoke-langgraph.sh 19
deploy/test-provision.sh 4
cli/test/smoke-bus.sh 2
cli/test/pack.sh 2
deploy/provision-host.sh 1
"

pass=0; fail=0
ok()  { pass=$((pass+1)); printf '  ok   %s\n' "$1"; }
bad() { fail=$((fail+1)); printf '  FAIL %s\n' "$1"; }

# Every non-comment site in one file. Occurrences, not lines: three of the
# worst sites in this repository put two or three of the shape on one line, and
# a per-line count misses them — the card that started this work said 58 for
# smoke-roster.sh where the real number is 66, for exactly that reason.
lines() { [ -f "$ROOT/$1" ] && grep -nE "$SHAPE" "$ROOT/$1" | grep -vE '^[0-9]+:[[:space:]]*#'; true; }
count() { lines "$1" | grep -oE "$SHAPE" | wc -l; }

printf '\n== every shell gate in this repository, scanned for the quiet-pipe shape\n'
FILES="$( (cd "$ROOT" && ls cli/test/*.sh deploy/*.sh 2>/dev/null) )"
for f in $FILES; do
  n="$(count "$f")"
  allowed="$(printf '%s\n' "$ALLOWED" | awk -v f="$f" '$1==f {print $2}')"
  allowed="${allowed:-0}"
  if [ "$n" -gt "$allowed" ]; then
    bad "$f carries $n of the quiet-pipe shape, and this gate allows it $allowed"
    printf '       A gate that pipes into `grep -q` can print FAIL for a pattern it matched.\n'
    printf '       Fix: capture the output and match a herestring — `said "$OUT" '"'"'pattern'"'"'` —\n'
    printf '       or, if this really is a new allowance, raise the number for %s\n' "$f"
    printf '       in test/shapes.sh and say in the pull request why it rose.\n'
    lines "$f" | sed 's/^/       /' | head -8
  elif [ "$n" -lt "$allowed" ]; then
    # Advisory, never a failure: a conversion landing is the good case, and a
    # gate that goes red when somebody fixes a suite is a gate people switch off.
    ok "$f carries $n — its allowance of $allowed is stale now, lower it to $n"
  elif [ "$n" = 0 ]; then
    ok "$f has none"
  else
    ok "$f carries $n, its allowance, unchanged"
  fi
  [ "$LIST" = 1 ] && [ "$n" != 0 ] && lines "$f" | sed 's/^/       /'
done

printf '\n-----------------------------------------------\n'
printf 'shapes: %d ok, %d failed\n' "$pass" "$fail"
[ "$fail" = 0 ] || exit 1
