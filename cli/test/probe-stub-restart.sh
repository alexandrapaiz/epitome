#!/usr/bin/env bash
# Why `smoke-doctor.sh` failed a different assertion at random on a busy box:
# the stand-in GitHub API's port, read out of the previous stub's log.
#
#   bash test/probe-stub-restart.sh [rounds]     # from cli/, default 40
#
# smoke-doctor.sh starts its stand-in GitHub seven times and reads the port
# that stub chose out of the file its stdout was redirected into. That file
# used to be named for the stub's MODE:
#
#   node test/github-stub.mjs 0 ... "$1" > "$TMP/gh-$1.log" 2>&1 &
#   for _ in $(seq 1 60); do GH_PORT="$(sed -n 's/github-stub on \([0-9]*\).*/\1/p' "$TMP/gh-$1.log")" ...
#
# Two of the seven modes are started twice -- `ok` at 12a and 12d,
# `thin-perms` at 12e and 12e' -- so on the second start that file already
# held a port line: the one the previous, now-killed stub printed. `>`
# truncates it in the forked child and the `sed` runs in the parent. When the
# parent wins, it takes the dead port, leaves the wait loop immediately, and
# every assertion in the section is made against a GitHub that is not
# listening.
#
# This probe runs both shapes of that wait, the same number of times, and
# reports how often each one came back holding the killed stub's port. The
# port is the kernel's pick out of the ephemeral range, so two starts agreeing
# by chance is about 1 in 28000: a match is a stale read, not a coincidence.
set -uo pipefail
CLI="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="${TMPDIR:-/tmp}/epito-stub-restart-probe-$$"
mkdir -p "$TMP"
GH_PID=""
gh_stop() { [ -n "${GH_PID:-}" ] || return 0; kill "$GH_PID" 2>/dev/null; wait "$GH_PID" 2>/dev/null; GH_PID=""; }
trap 'gh_stop; rm -rf "$TMP"' EXIT
node -e 'const{generateKeyPairSync}=require("crypto");const{publicKey}=generateKeyPairSync("rsa",{modulusLength:2048});require("fs").writeFileSync(process.argv[1],publicKey.export({type:"spki",format:"pem"}))' "$TMP/app.pub.pem"
GH_LOG="$TMP/gh.jsonl"

# The wait loop, copied out of smoke-doctor.sh rather than paraphrased: the
# race is in this sequence, so a description of it would prove nothing about
# the suite. Both shapes differ in one thing only -- what the file is named.
start_and_wait() { # <mode> <logfile>
  gh_stop
  : > "$GH_LOG"
  node "$CLI/test/github-stub.mjs" 0 "$TMP/app.pub.pem" "$GH_LOG" "$1" > "$2" 2>&1 &
  GH_PID=$!
  GH_PORT=""
  for _ in $(seq 1 60); do
    GH_PORT="$(sed -n 's/github-stub on \([0-9]*\).*/\1/p' "$2" 2>/dev/null)"
    [ -n "$GH_PORT" ] && break
    sleep 0.2
  done
  [ -n "$GH_PORT" ]
}
answers() { node -e 'const n=require("net"),s=n.connect({host:"127.0.0.1",port:Number(process.argv[1])});s.setTimeout(1000);s.on("connect",()=>{s.end();process.exit(0)});s.on("timeout",()=>process.exit(1));s.on("error",()=>process.exit(1))' "$1"; }

ROUNDS="${1:-40}"
STARTS=0
# One round is one mode started twice, which is what 12a/12d and 12e/12e' are.
round() { # <shape> -> prints the verdict, returns 1 on a stale read
  local shape="$1" first second log
  for n in 1 2; do
    case "$shape" in
      mode)  log="$TMP/gh-ok.log" ;;                              # the old name
      start) STARTS=$((STARTS+1)); log="$TMP/gh-$STARTS-ok.log" ;; # the new one
    esac
    start_and_wait ok "$log" || { printf 'the stub never came up at all'; return 0; }
    [ "$n" = 1 ] && first="$GH_PORT" || second="$GH_PORT"
  done
  if [ "$first" = "$second" ]; then
    if answers "$second"; then printf 'STALE (%s twice, still listening)' "$second"
    else printf 'STALE (%s twice, and nothing is listening on it)' "$second"; fi
    return 1
  fi
  printf 'fresh (%s then %s)' "$first" "$second"
}

printf '\n== the second start of a mode, %s rounds of each shape, load %s\n' \
  "$ROUNDS" "$(cut -d' ' -f1 /proc/loadavg)"
declare -A stale=([mode]=0 [start]=0)
for shape in mode start; do
  case "$shape" in
    mode)  printf '\n  the old shape: the wait file is named for the MODE\n' ;;
    start) printf '\n  this shape: the wait file is named for the START\n' ;;
  esac
  for i in $(seq 1 "$ROUNDS"); do
    v="$(round "$shape")" || stale[$shape]=$(( ${stale[$shape]} + 1 ))
    printf '    round %2s: %s\n' "$i" "$v"
  done
done
gh_stop

printf '\n-----------------------------------------------\n'
printf 'named for the mode:  %s stale of %s rounds\n' "${stale[mode]}" "$ROUNDS"
printf 'named for the start: %s stale of %s rounds\n' "${stale[start]}" "$ROUNDS"
if [ "${stale[start]}" -gt 0 ]; then
  printf 'probe-stub-restart: the conversion did NOT close it -- a per-start name\n'
  printf 'read a stale port, which should not be reachable. Read this again.\n'
  exit 1
fi
if [ "${stale[mode]}" -gt 0 ]; then
  printf 'probe-stub-restart: the fault reproduces in the old shape and the\n'
  printf 'conversion closes it. Nothing but one start ever writes one file now,\n'
  printf 'so the stale read is impossible rather than unlikely.\n'
  exit 0
fi
printf 'probe-stub-restart: no stale read in either shape this time. It is a\n'
printf 'race, not a certainty -- a quiet box can run hundreds of rounds clean,\n'
printf 'and the old shape needs the parent to beat a fork. Try more rounds, or\n'
printf 'a busier box: the run that found it was at load 18.\n'
