#!/usr/bin/env bash
# The shapes a gate in this repository may not have. One scan, no prerequisites,
# runs in milliseconds, and it exists because the fault it looks for cannot be
# caught by running the suites: a suite carrying it passes.
#
#   bash test/shapes.sh            # from cli/
#   bash test/shapes.sh --list     # print every site it finds, converted or not
#
# Two scans, one summary. The second is at the bottom of this file, with its own
# note: a start that waits on a log file it did not create is the fault it looks
# for, and it is the same kind of fault — a gate that reads the wrong thing and
# says ok.
#
# The first shape: `<producer> | grep -q '<pattern>'` under `set -o pipefail`. Quiet
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
# producer was killed writing the rest. `141` is not the only signature, which
# matters for anyone diagnosing one of these by eye: a producer that handles
# SIGPIPE itself reports its own exit code instead. smoke-langgraph.sh's
# `detail` is `python3`, and that one reads `1 0` — BrokenPipeError, exit 1 —
# which is indistinguishable from "the pattern was not there". Measured on this
# branch at 161 of 200 asks. So the race is not about the buffer at
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
# Counts re-read on `main` at 2026-10-26 05:5xZ, after smoke-doctor.sh's
# conversion (#292) landed: 26 sites in six files, less the 23 in
# smoke-langgraph.sh (19), smoke-bus.sh (2) and pack.sh (2) that this branch
# converts. What is left after this branch is the two deploy scripts and
# nothing else -- deploy/test-provision.sh (4) and deploy/provision-host.sh
# (1), which the board card asks to land last and separately, because a false
# failure in the middle of provisioning a box is worse than a false failure in
# a test. Every suite under cli/test/ is converted as of this branch; the three
# probe files below are the shape on purpose and say so.
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
# smoke-temporal.sh, smoke-roster.sh, all.sh, smoke-deploy.sh, smoke-doctor.sh,
# and smoke-langgraph.sh, smoke-bus.sh and pack.sh here. A number may only be lowered by a branch that can see
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
deploy/test-provision.sh 4
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

# ---------------------------------------------------------------------------
# The second shape, and the reason this file stopped being about one: a
# start-and-wait that reads a log file whose name is fixed across starts.
#
#   node test/github-stub.mjs ... > "$ROOT/github-stub.log" 2>&1 &
#   for _ in $(seq 1 60); do grep -q 'github-stub on' "$ROOT/github-stub.log" && break; ...
#
# The `>` truncates that file in the FORKED CHILD; the wait's reader runs in
# the parent. Whenever the parent gets there first, the file still holds what
# the previous start of the same name wrote -- a port, a listener, an "on
# http://..." -- so the wait returns before this start has bound anything, and
# every assertion after it is made against a service that is not there.
#
# Measured, not argued: smoke-deploy.sh starts its stand-in GitHub twice on one
# fixed port and took the dead port whenever the parent won (#303), and
# smoke-doctor.sh did the same across the two modes it starts twice -- 12d
# printed six FAILs at load 18 while 12a, the first start of the same mode,
# passed (#293). test/probe-stub-restart.sh is that race run both ways: the
# ports are the kernel's pick out of the ephemeral range, so two starts
# agreeing by chance is about 1 in 28000 and a match is a stale read.
#
# The fix is the NAME. A file this start created cannot hold a previous
# start's line:
#
#   GH_STARTS=$((GH_STARTS+1)); GH_STUB_LOG="$ROOT/github-stub-$GH_STARTS.log"
#
# A per-start counter is the only thing this scan accepts, deliberately. A
# hand-written number -- `ingress.log` beside `ingress2.log`, which is how
# smoke-temporal.sh tells its two ingress starts apart -- is discipline, and it
# holds exactly until somebody copies the block. A truncation in the parent
# (`: > "$f"`) closes the race against a start that is already dead and not
# against one still writing at its old offset. Only the counter makes a stale
# read impossible rather than unlikely, and only the counter is visible to a
# scan: it is the difference between a file that happens to be unique today and
# a name that cannot repeat.
#
# What this does NOT report, because it is sound: a wait that asks the SERVICE
# rather than its log. smoke-bus.sh connects a socket, smoke-cloudflare.sh
# curls wrangler on its port, smoke-doctor.sh asks `epito doctor` whether the
# worker has polled, smoke-temporal.sh asks the engine for its namespace. Those
# four start into a fixed log name too and none of them is listed below: the
# fault needs the wait to be reading the file.
WAIT_EXEMPT="
cli/test/probe-stub-restart.sh 1
"
# One exemption, named rather than hidden, the way the allowance above names
# its three: probe-stub-restart.sh takes the log path as an argument and runs
# the stale shape and the per-start shape the same number of times to compare
# them, so a generic `> "$2"` with a wait that reads `"$2"` is what that file
# is FOR. Everything else in this repository is converted as of this branch,
# the fix is one line, and so a new site here is a mistake rather than a cost
# somebody has not paid yet -- which is why this table counts one file and not
# a column of ceilings.

# The scan. Two passes over one file: collect, then decide in END.
#
# A site is a background command whose stdout goes into a file, plus a line
# inside a loop that reads THAT path with grep/sed/awk/tail/head/cat. It is
# sound when the path text carries a per-start counter -- a variable V the file
# increments with `V=$((V+1))` -- either written into the name directly or
# through one variable whose every assignment carries it.
#
# All three spellings of a redirect into a file count -- `>`, `>>` and `&>`.
# An append never truncates at all, so a wait reading one is stale by
# construction rather than by a lost race; there is no such site here, and the
# scan takes it anyway so that adding one is not a way through.
#
# Backgrounding is read by removing `2>&1`, `1>&2` and `&&` from the line and
# asking whether an `&` survives. That is a heuristic and it is a safe one: a
# line has to ALSO redirect stdout into a file and ALSO have a loop reading
# that same path before anything is reported.
#
# Comment lines are skipped, which is the opposite of what the scan above does
# with its three exemptions, and for a reason rather than by inconsistency:
# this shape takes two lines to write down, so the note at the top of this
# section quotes it in full, and a scan that counted sentences about the fault
# could not be documented without exempting its own documentation. A
# commented-out start does not run; the quiet-pipe scan counts its comments
# because a stray `-q` in a sentence there is an accident, not a definition.
waitsites() {
  [ -f "$ROOT/$1" ] || return 0
  awk '
function has_counter(t,   c) {
  for (c in counter) if (index(t, "$" c) || index(t, "${" c)) return 1
  return 0
}
/^[ \t]*#/ { next }
{
  src[NR] = $0

  s = $0
  while (match(s, /[A-Za-z_][A-Za-z0-9_]*=\$\(\([ ]*[A-Za-z_][A-Za-z0-9_]*[ ]*\+[ ]*1[ ]*\)\)/)) {
    t = substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH)
    eq = index(t, "="); n = substr(t, 1, eq - 1)
    if (index(t, "((" n) || index(t, "(( " n)) counter[n] = 1
  }

  s = $0
  while (match(s, /[A-Za-z_][A-Za-z0-9_]*="[^"]*"/)) {
    t = substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH)
    eq = index(t, "="); n = substr(t, 1, eq - 1)
    assign[n] = assign[n] "\n" substr(t, eq + 2, length(t) - eq - 2)
  }

  one = ($0 ~ /(^|[ \t;])(for|while)[ \t].*;[ \t]*do[ \t].*;[ \t]*done/)
  inloop[NR] = (depth > 0 || one)
  if (!one) {
    if ($0 ~ /(^|[ \t;])(for|while)[ \t]/ && $0 ~ /(;[ \t]*do([ \t]|$)|[ \t]do[ \t]*$)/) depth++
    else if ($0 ~ /^[ \t]*done([ \t]|$|;)/) { depth--; if (depth < 0) depth = 0 }
  }

  b = $0; gsub(/2>&1/, "", b); gsub(/1>&2/, "", b); gsub(/&&/, "", b)
  if (b ~ /&/) {
    s = $0
    while (match(s, /[^0-9>]>>?[ \t]*"?[^ \t">|&)]+"?/)) {
      t = substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH)
      sub(/^[^>]*>>?[ \t]*/, "", t); gsub(/"/, "", t)
      if (t ~ /^\/dev\// || t == "") continue
      if (!(t in startline)) { startline[t] = NR; order[++starts] = t }
    }
  }
}
END {
  for (i = 1; i <= starts; i++) {
    p = order[i]
    sound = has_counter(p)
    if (!sound && p ~ /^\$\{?[A-Za-z_][A-Za-z0-9_]*\}?$/) {
      v = p; gsub(/[$\{\}]/, "", v)
      if (v in assign) {
        k = split(assign[v], vals, "\n"); any = 0; bare = 0
        for (j = 1; j <= k; j++) if (vals[j] != "") { any = 1; if (!has_counter(vals[j])) bare = 1 }
        sound = (any && !bare)
      }
    }
    if (sound) continue
    for (ln = 1; ln <= NR; ln++) {
      if (!inloop[ln]) continue
      if (!index(src[ln], "\"" p "\"")) continue
      if (src[ln] !~ /(grep|sed|awk|tail|head|cat)[ \t]/) continue
      printf "%d\t%s\t%d\n", startline[p], p, ln
      break
    }
  }
}
' "$ROOT/$1"
}

printf '\n== the same gates, scanned for a start that waits on a fixed log name\n'
for f in $FILES; do
  sites="$(waitsites "$f")"
  n="$(printf '%s' "$sites" | grep -c . )"
  exempt="$(printf '%s\n' "$WAIT_EXEMPT" | awk -v f="$f" '$1==f {print $2}')"
  exempt="${exempt:-0}"
  if [ "$n" -gt "$exempt" ]; then
    bad "$f starts $n service(s) into a log name that cannot tell two starts apart"
    printf '       A wait that greps a fixed log name can match the line the PREVIOUS\n'
    printf '       start wrote, and return before this one has bound anything.\n'
    printf '       Fix: name the file after the start — `N=$((N+1));\n'
    printf '       LOG="$ROOT/thing-$N.log"` — or wait on the service instead of its log.\n'
    printf '%s\n' "$sites" | while IFS="$(printf '\t')" read -r sl path wl; do
      [ -n "$sl" ] || continue
      printf '       %s:%s starts into %s, and :%s waits by reading it\n' "$f" "$sl" "$path" "$wl"
    done
  elif [ "$n" -lt "$exempt" ]; then
    ok "$f has $n — its exemption of $exempt is stale now, lower it to $n"
  elif [ "$n" = 0 ]; then
    ok "$f has none"
  else
    ok "$f has $n, its named exemption, unchanged"
  fi
  if [ "$LIST" = 1 ] && [ "$n" != 0 ]; then
    printf '%s\n' "$sites" | sed 's/^/       /'
  fi
done

printf '\n-----------------------------------------------\n'
printf 'shapes: %d ok, %d failed\n' "$pass" "$fail"
[ "$fail" = 0 ] || exit 1
