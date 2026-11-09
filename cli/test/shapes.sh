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
# Every wrong verdict there is PIPESTATUS `141 0`: grep MATCHED and exited 0,
# and the producer was killed writing the rest. `141` is not the only signature,
# which matters for anyone diagnosing one of these by eye: a producer that
# handles SIGPIPE itself reports its own exit code instead of dying of it. A
# `python3` producer is the case in this repository, and it reads `1 0` —
# BrokenPipeError, exit 1 — which is indistinguishable from "the pattern was
# not there". Measured at 100 of 100 asks with 200 KB still to write after the
# needle, and 0 of 100 with 100 bytes, which is the same POSITION race as above
# and not a second fault. So the race is not about the buffer at
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
# Counts re-read on `main` at 2026-10-26 09:2xZ, after smoke-doctor.sh's
# conversion (#292) landed: 37 sites in eight files, which is 9 in the three
# named probe exemptions below, 23 in smoke-langgraph.sh (19), smoke-bus.sh (2)
# and pack.sh (2), and 5 in the two deploy scripts --
# deploy/test-provision.sh (4) and deploy/provision-host.sh (1), which the
# board card asked to land last and separately, because a false failure in the
# middle of provisioning a box is worse than a false failure in a test. The
# first 23 are this branch's base (#332) and the last 5 are this branch, so
# the two directories this file scans are converted down to the 9 exemptions
# and the allowance table below holds nothing else. 37 less 23 less 5 is 9,
# and that is what this gate prints.
#
# docs/agents/ joins this table's scope on this branch and leaves it with
# nothing: the sixteen sites the widening found in eight of those twenty-one
# files are converted in the same diff, so the table is back to its three
# named exemptions. Eleven of the sixteen were LIVE and five were LATENT, and
# the difference is one measured fact rather than a judgement: `pipefail` does
# not cross `bash -c` (measured, 200 asks each -- a matching pipeline that
# reported failure 200 of 200 times in the parent reported it 0 of 200 inside
# `bash -c`). So a site in a file's own shell misfires today, and a site
# inside a `bash -c` string misfires the day its runner turns pipefail on.
# Both are converted: this scan cannot tell them apart, and the latent five
# include the fixture in remeasure.sh that a seat copies when it writes a
# real probe.
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
# What the widening is worth, measured rather than argued: composing this
# branch against trunk six hours after its conversions, this scan read 86 ok
# and 2 FAILED, and both failures were new on main. post.sh arrived at
# 11:08:04Z with four -- including a belt that FAILS OPEN, where a false
# pipeline failure reads as "no refusal was printed" and the board message
# goes out (measured on the real captured surface: 1018 bytes, needle at 528,
# 3 of 500 wrong, every one PIPESTATUS `141 0`). And remeasure.sh grew one
# back at 10:52:34Z, eight minutes after the commit here that converted that
# file. Five new sites in a directory nobody scanned, in six hours. That is
# the standing cost this gate is for, and nothing on main could have caught
# either one, because this is the only reader that looks there.
#
# Converted and therefore absent, allowed none: smoke-validate.sh,
# smoke-temporal.sh, smoke-roster.sh, all.sh, smoke-deploy.sh, smoke-doctor.sh,
# smoke-langgraph.sh, smoke-bus.sh, pack.sh, both deploy scripts, and now the
# nine seat tools -- brief.sh, check.sh, clocks.sh, idle.sh, mergeable.sh,
# post.sh, remeasure.sh, reread.sh, stage.sh -- every file this gate scans
# except the three probes. A number may only be
# lowered by a branch that can see
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

# What this prints is now what the repository holds, which it was not until
# this branch. FILES was cli/test/ and deploy/ only -- twenty files -- while
# docs/agents/ held twenty-one more, the tools the seats run to DECIDE things,
# and not one of them had ever been scanned. A gate that says "every" while
# reading half is how a blind spot gets read as a clean bill of health, so the
# glob is all three directories and the allowance below carries the sites that
# widening found.
printf '\n== cli/test/, deploy/ and docs/agents/, scanned for the quiet-pipe shape\n'
FILES="$( (cd "$ROOT" && ls cli/test/*.sh deploy/*.sh docs/agents/*.sh 2>/dev/null) )"
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
# is FOR. Everything else UNDER THE TWO DIRECTORIES THIS FILE SCANS is
# converted as of this branch -- which is not the same claim as the repository,
# and the difference is the board card named in the banner below --
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

  b = $0; gsub(/[0-9]*>&[0-9-]/, "", b); gsub(/&&/, "", b)
  gsub(/"[^"]*"/, "", b); gsub(/\047[^\047]*\047/, "", b)
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

printf '\n== the same files, scanned for a start that waits on a fixed log name\n'
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


# ---------------------------------------------------------------------------
# The third shape: a write through a path this run does not own.
#
# `git -C ""` is not a refusal. It operates on the CURRENT directory and exits
# zero, printing nothing. Measured on this box, git 2.43.0, against a throwaway
# repository — cli/test/probe-unowned-path.sh runs it:
#
#   branch before: precious
#   git -C "" branch -m renamed-by-an-empty-path   ->  rc 0, no output
#   branch after : renamed-by-an-empty-path
#
# So the only thing standing between a scratch-directory write and the caller's
# own checkout is that the variable holding the path is not empty. `mktemp -d`
# fails — a full device is the ordinary cause, and this box stood at 507M free
# of 45G at 07:35Z — and an unchecked failure leaves the variable SET, to the
# empty string. `set -u` cannot see that, and none of the instruments this file
# scans uses `set -e`: they are `set -uo pipefail`, which is the right choice
# for a reader that must report rather than die, and is exactly why the check
# has to be written by hand.
#
# It fired. At 07:35:24Z on 2026-11-02, inside a pre-flight run from the
# repository root, `mergeable.sh --self-test` renamed the branch of the run
# that called it to `trunk` and destroyed it, created `parent`, `child` and
# `rogue` beside it, and moved HEAD. The tool exited 1 — it reported the
# failure AFTER writing in the caller's repository. Four commits survived
# because they had been pushed (incident 69).
#
# THE SECOND SPELLING IS THE SAME DEFECT. Three hours later the same run lost
# its pull request body: it had written 12312 characters to a fixed name under
# the shared temp directory, another seat's run wrote 46 bytes of its own to
# that name, and the forge published the 46 bytes and reported success. Several
# seats run on this box as one unix user by design, so two runs reaching for
# one name is the expected case and not the unlucky one. `mktemp` is therefore
# not a convenience for uniqueness; it is the only thing that makes a path
# belong to one run. An unchecked `mktemp` and a hardcoded shared path are one
# fault with two spellings, and this scan counts them into one number.
#
# WHAT IS COUNTED IS THE LINE SOMEBODY HAS TO CHANGE, which is why the number
# below is not the one that was handed to this seat. The measurement routed
# here was 40 writing `git -C "$var"` calls across six files taking an
# unchecked variable as their only isolation, and that count is right and this
# scan prints it — but 20 of the 40 are in one file and one guarded assignment
# fixes all 20. A ceiling on uses charges a file for having many callers of a
# single missing line, and then falls by 20 for one commit, which makes the
# number unreadable as progress. So the ceiling is on the assignment, and the
# uses it feeds are printed beside it as the blast radius, because that is what
# makes a line urgent rather than untidy.
#
# WHAT IS NOT COUNTED, with the reason, because a gate with a long accepted
# list is a gate nobody reads (that is this file's own lesson, one section up):
#
#   - A READ of a shared path. Running another seat's cached binary or parsing
#     its leftover JSON is a real fault with a different fix, and
#     docs/agents/scratch.sh already censuses it with `--self-test` behind it.
#     This scan is about the write that DESTROYS.
#   - A shared path in prose, in a captured fixture, or in a specimen handed to
#     a checker to see whether it gets caught. All three are descriptions of
#     this defect rather than instances, and a scan that cannot tell them apart
#     gets switched off. They are excluded by WHERE THE BYTES GO rather than by
#     a list of forgiven lines: a redirect is a finding only when its `>` sits
#     outside every quote on the line and outside any heredoc body. That is
#     what drops `x5probe.sh:181` — `ask_command 'env > /tmp/x5probe-env.txt'`,
#     a string passed to the credential checker as `--command` and never run —
#     and `post.sh:560`, a real board reply pasted whole inside a multi-line
#     double-quoted fixture, and `smoke-langgraph.sh:159`, two lines of advice
#     telling a reader what to type.
#   - A name a run invented. `mktemp`, `XXXXXX`, `$$`, `$RANDOM`, `$(date` and
#     `$BASHPID` anywhere in a path's resolution make it this run's, which is
#     the whole rule this scan exists to write down.
#
# A target held in a variable is resolved back through that variable's
# assignments, so `LIVE=${BRIEF_LIVE:-/tmp/brief-live.json}` and the
# `curl ... > "$LIVE"` four lines later are one finding reported at the write.
#
# THE HOLES, named here rather than left to be found. A test that appears
# anywhere in the file counts as the guard for an assignment, and this scan
# cannot tell a test that runs BEFORE the write from one that runs after it —
# so a file that checks its scratch directory too late reads clean. And a
# target assembled across lines, or reached through two variables, is invisible
# to the resolution above. Both are the forgiving direction, which is the wrong
# one for a gate; they are the price of a count a reader will still act on.
#
# The fix at a call site is one line, and it is the same line every time:
#
#   -  tmp=$(mktemp -d)
#   +  tmp=$(mktemp -d) || { echo "could not look: no scratch directory" >&2; return 2; }
#
# and, for the second spelling, a directory this run made rather than a name it
# chose:
#
#   -  LIVE=${BRIEF_LIVE:-/tmp/brief-live.json}
#   +  LIVE=${BRIEF_LIVE:-$RUNDIR/live.json}      # RUNDIR=$(mktemp -d) || exit 2
UNOWNED="
docs/agents/addressed.sh 2
docs/agents/brief.sh 3
docs/agents/caps.sh 6
docs/agents/check.sh 2
docs/agents/clocks.sh 2
docs/agents/doors.sh 1
docs/agents/drafts.sh 1
docs/agents/executing.sh 2
docs/agents/idle.sh 1
docs/agents/mergeable.sh 2
docs/agents/order.sh 1
docs/agents/owed.sh 7
docs/agents/pointers.sh 1
docs/agents/post.sh 3
docs/agents/remeasure.sh 1
docs/agents/reread.sh 2
docs/agents/reverted.sh 1
docs/agents/scratch.sh 1
docs/agents/stage.sh 1
docs/agents/x5probe.sh 1
"
# Counted on `main` at 2026-11-02, dc971e2: 41 sites in 20 files, every one of
# them under `docs/agents/`, and 8 writing `git -C` calls still standing behind
# an unchecked assignment. Both numbers were higher when this scan was written
# six hours earlier -- 44 sites and 44 writing calls -- and the difference is
# the repair for incident 69 landing on main while this branch was open:
# `mergeable.sh`, `reverted.sh` and `doors.sh` guarded their scratch
# directories, which took 36 of the 44 writing calls out at three lines. Those
# three rows are lowered here rather than left stale, because this branch can
# see the conversion land: it is in this branch's own merge-base.
#
# `cli/test/` and `deploy/` hold none, and the two reasons are different. The
# two this scan found in its own lane -- a scratch directory unchecked in
# `cli/test/selftests.sh`, which inits a repository under it and then runs
# every instrument against that with `git -C`, and one in
# `cli/test/probe-readers.sh` -- are guarded in this same diff, so both files
# are absent from this table and allowed none. `deploy/` was clean already:
# `test-provision.sh:297` does write `cat > /tmp/hash.env`, and that line sits
# inside a `<<\047IN_CONTAINER\047` heredoc that runs in a throwaway docker
# container, where /tmp belongs to the container and to nothing else on this
# box. It is excluded by the heredoc rule below rather than by a forgiven line,
# which is the distinction this whole section turns on.
#
# The loudest row left is the second spelling, and it is live in a tool every
# seat on this box runs: `docs/agents/brief.sh:69` and `:70` curl the board
# into `/tmp/brief-live.json` and `/tmp/brief-events.json` -- fixed names under
# the shared directory -- and an embedded python reads them back four lines
# later. Two concurrent runs of `brief.sh` read each other. That is the fault
# that took a pull request body at 07:07Z, still standing, and it is a
# behaviour change to a shared instrument rather than a guard, so it is a row
# in docs/backlog.md and handed to the project manager rather than a rider on
# this gate.
#
# A ceiling that is too HIGH costs one advisory line; a ceiling lowered for a
# conversion that has not landed fails this gate on main. The stale direction
# is the safe one, and this table will trail by a pass for the same reason the
# two above it do.
#
# A number may never rise. If one has to, the pull request says why.
unowned() {
  [ -f "$ROOT/$1" ] || return 0
  awk '
# Is any token in t one a run invented, rather than one a seat typed?
function invented(t) {
  return (t ~ /mktemp/ || t ~ /XXXXXX/ || t ~ /\$\$/ || t ~ /\$RANDOM/ ||
          t ~ /\$\(date/ || t ~ /\$BASHPID/ || t ~ /\$EPOCHSECONDS/)
}
# Does t name a fixed place in the directory every seat on this box shares?
function shared(t) {
  return (t ~ /^\/tmp\// || t ~ /^\$\{?TMPDIR\}?\// || t ~ /^"?\$\{TMPDIR[:-]/)
}
# Resolve a redirect target to a shared literal, directly or through one
# variable. Returns the literal, or "" when it is not a shared fixed path.
function resolve(p,   v, k, vals, j) {
  if (shared(p)) return invented(p) ? "" : p
  if (p !~ /^\$\{?[A-Za-z_][A-Za-z0-9_]*\}?(\/|$)/) return ""
  v = p; sub(/^\$\{?/, "", v); sub(/[}\/].*$/, "", v)
  if (!(v in assign)) return ""
  k = split(assign[v], vals, "\n")
  for (j = 1; j <= k; j++)
    if (vals[j] != "" && shared(vals[j]) && !invented(vals[j])) return vals[j]
  return ""
}
{
  raw = $0

  # ----- heredoc bodies are not code this file runs -------------------------
  if (hd != "") { if (raw ~ ("^[ \t]*" hd "[ \t]*$")) hd = ""; next }
  if (match(raw, /<<-?[ \t]*\047?"?[A-Za-z_][A-Za-z0-9_]*\047?"?[ \t]*$/)) {
    hd = substr(raw, RSTART, RLENGTH); gsub(/[<\047" \t-]/, "", hd)
  }

  # ----- one walk, two readings of the line --------------------------------
  # `code` has every quoted span blanked, because a `>` inside quotes is a
  # character in a string and not a redirect this file performs — that is what
  # drops a specimen handed to a checker. `txt` keeps the quotes and stops at
  # an unquoted `#`, because the variable names everything else matches on live
  # inside them. Quote state is per line, deliberately: a shell line that opens
  # a string and closes it on the next is rare here, and carrying the state
  # across lines means one unbalanced apostrophe blanks the rest of the file.
  # Nothing is lost by it — the three specimens this scan must not report are
  # excluded because they are not redirects at all, or are quoted on one line.
  code = ""; txt = ""; ins = 0; ind = 0
  for (i = 1; i <= length(raw); i++) {
    c = substr(raw, i, 1)
    if (c == "\\" && !ins) { code = code "  "; txt = txt c substr(raw, i+1, 1); i++; continue }
    if (c == "\047" && !ind) { ins = !ins; code = code " "; txt = txt c; continue }
    if (c == "\"" && !ins) { ind = !ind; code = code " "; txt = txt c; continue }
    if (!ins && !ind && c == "#" && (i == 1 || substr(raw, i-1, 1) ~ /[ \t;]/)) break
    code = code ((ins || ind) ? " " : c)
    txt = txt c
  }
  if (txt ~ /^[ \t]*$/) next
  cl++        # the ordinal of this line among the lines that are CODE. The
              # window below is measured in these rather than in line numbers,
              # so that writing the reason for a check above it instead of
              # beside it cannot push the check out of its own window.

  # ----- what each variable is ever assigned -------------------------------
  s = txt
  while (match(s, /[A-Za-z_][A-Za-z0-9_]*=[^ \t;|&)]+/)) {
    t = substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH)
    eq = index(t, "="); n = substr(t, 1, eq - 1); val = substr(t, eq + 1)
    gsub(/^"|"$/, "", val)
    if (val ~ /^\$\{[A-Za-z_][A-Za-z0-9_]*:?-/) sub(/^\$\{[A-Za-z_][A-Za-z0-9_]*:?-/, "", val)
    sub(/\}$/, "", val)
    assign[n] = assign[n] "\n" val
  }

  # ----- spelling one: a scratch directory nothing checked -----------------
  s = txt
  while (match(s, /[A-Za-z_][A-Za-z0-9_]*="?\$\(mktemp/)) {
    t = substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH)
    eq = index(t, "="); v = substr(t, 1, eq - 1)
    mkvar[v] = 1
    mk[++nmk] = v "\t" NR "\t" cl
    # A same-line `||` that LEAVES is the check. `|| v=` is not one: it makes
    # the emptiness explicit and hands the problem to a test, which has to be
    # there — `pointers.sh:112` and `roster.sh:264` both write it that way and
    # both test on the very next line.
    if (txt ~ /\|\|/ && txt ~ /(exit|return)([ \t]|$|;|\})/) left[v "\t" NR] = 1
  }
  # An emptiness or directory test on a variable, recorded WITH ITS LINE. The
  # line matters: eight of these instruments reuse the name `tmp` for every
  # scratch directory they make, so a test keyed by name alone lets one
  # guarded assignment forgive every unguarded one in the same file. Measured:
  # addressed.sh reads 0 under that rule and 2 under this one.
  s = txt
  while (match(s, /\[\[?[ \t]+-[nzd][ \t]+"?\$\{?[A-Za-z_][A-Za-z0-9_]*\}?/)) {
    t = substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH)
    sub(/.*\$\{?/, "", t); sub(/[}"].*/, "", t); tested[t "\t" cl] = 1
  }
  if (match(txt, /\$\{[A-Za-z_][A-Za-z0-9_]*:\?/)) {
    t = substr(txt, RSTART + 2); sub(/:\?.*/, "", t); tested[t "\t" cl] = 1
  }

  # ----- the blast radius: a writing git -C through such a variable --------
  s = txt
  WR = "add|am|apply|branch|checkout|cherry-pick|clean|clone|commit|config|fetch|gc|init|merge|mv|notes|prune|pull|push|rebase|remote|replace|reset|restore|rm|stash|switch|symbolic-ref|tag|update-ref|worktree"
  while (match(s, /git[ \t]+-C[ \t]+"?\$\{?[A-Za-z_][A-Za-z0-9_]*\}?[^ \t]*[ \t]+[a-z-]+/)) {
    t = substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH)
    v = t; sub(/.*git[ \t]+-C[ \t]+"?\$\{?/, "", v); sub(/[}"\/ \t].*/, "", v)
    cmd = t; sub(/^.*[ \t]/, "", cmd)
    if (cmd ~ ("^(" WR ")$")) { writes[v]++; if (!(v in firstwrite)) firstwrite[v] = NR }
  }

  # ----- spelling two: a write into a name no run invented -----------------
  # Redirects only, and only those whose `>` is outside every quote.
  for (i = 1; i <= length(code); i++) {
    if (substr(code, i, 1) != ">") continue
    if (substr(code, i-1, 1) ~ /[0-9>&-]/) continue
    j = i; while (substr(code, j, 1) == ">") j++
    while (substr(txt, j, 1) ~ /[ \t]/) j++
    # The target is read out of `txt` and not out of `code`, at the index
    # `code` found the redirect at: the two are kept the same length on
    # purpose, and a target like `> "$LIVE"` is entirely inside the quotes
    # `code` blanked. The `>` decides from `code`, the name from `txt`.
    tgt = ""
    while (j <= length(txt) && substr(txt, j, 1) !~ /[ \t|&;)<]/) { tgt = tgt substr(txt, j, 1); j++ }
    gsub(/"/, "", tgt)
    if (tgt == "" || tgt ~ /^\/dev\//) continue
    lit = resolve(tgt)
    if (lit != "") { sh[++nsh] = NR "\t" tgt "\t" lit }
    i = j
  }
}
END {
  for (k = 1; k <= nmk; k++) {
    split(mk[k], a, "\t"); v = a[1]; ln = a[2]; cn = a[3]
    if ((v "\t" ln) in left) continue
    guarded = 0
    for (d = 0; d <= 3; d++) if ((v "\t" (cn + d)) in tested) guarded = 1
    if (guarded) continue
    n = (v in writes) ? writes[v] : 0
    if (n > 0)
      printf "%s\tmktemp\t$%s is the only isolation for %d writing git -C call(s), the first at :%d\n", ln, v, n, firstwrite[v]
    else
      printf "%s\tmktemp\t$%s is a scratch path nothing checks, so an empty one means \"here\"\n", ln, v
  }
  for (k = 1; k <= nsh; k++) {
    split(sh[k], a, "\t")
    if (a[2] == a[3]) printf "%s\tshared\ta write into %s, a name another seat picks too\n", a[1], a[3]
    else printf "%s\tshared\ta write into %s, which resolves to %s\n", a[1], a[2], a[3]
  }
}
' "$ROOT/$1"
}

printf '\n== the same files, scanned for a write through a path this run does not own\n'
for f in $FILES; do
  sites="$(unowned "$f")"
  n="$(printf '%s' "$sites" | grep -c . )"
  allowed="$(printf '%s\n' "$UNOWNED" | awk -v f="$f" '$1==f {print $2}')"
  allowed="${allowed:-0}"
  if [ "$n" -gt "$allowed" ]; then
    bad "$f writes through $n path(s) this run does not own, and this gate allows it $allowed"
    printf '       An empty path is not nowhere, it is HERE: `git -C ""` works on the current\n'
    printf '       directory and exits 0. A fixed name under a shared directory is the same\n'
    printf '       fault spelled differently — another seat picks it too, and wins.\n'
    printf '       Fix: `tmp=$(mktemp -d) || { echo "could not look: no scratch directory" >&2; return 2; }`\n'
    printf '       and write under a directory this run made, never a name it chose.\n'
    printf '%s\n' "$sites" | while IFS="$(printf '\t')" read -r ln kind why; do
      [ -n "$ln" ] || continue
      printf '       %s:%s  %s\n' "$f" "$ln" "$why"
    done
  elif [ "$n" -lt "$allowed" ]; then
    ok "$f writes through $n — its allowance of $allowed is stale now, lower it to $n"
  elif [ "$n" = 0 ]; then
    ok "$f has none"
  else
    ok "$f carries $n, its allowance, unchanged"
  fi
  [ "$LIST" = 1 ] && [ "$n" != 0 ] && printf '%s\n' "$sites" | sed 's/^/       /'
done

printf '\n-----------------------------------------------\n'
printf 'shapes: %d ok, %d failed\n' "$pass" "$fail"
[ "$fail" = 0 ] || exit 1
