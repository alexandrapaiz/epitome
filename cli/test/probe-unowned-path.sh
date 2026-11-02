#!/usr/bin/env bash
# The two ways a path stops belonging to the run that writes through it, each
# run for real against a throwaway repository, and the exit code each one
# reports while doing it.
#
#   bash test/probe-unowned-path.sh          both cases, with their verdicts
#
# This exists because the shape test/shapes.sh gates on is not arguable from
# the text of a command: every command in both cases below does exactly what it
# was told, and every one of them succeeds. The fault is in what the path was,
# and the only way to show that is to run it and read what is left.
#
# CASE 1 — the empty path. `git -C ""` is not a refusal. It operates on the
# CURRENT directory and exits zero. So a scratch directory that was never
# created, held in a variable nothing checked, turns every `git -C "$D" <write>`
# in the file into the same write against the caller's own checkout.
#
#   D=$(mktemp -d)            # the box is full; this fails
#   git -C "$D" branch -m x   # renames the CALLER's branch, exit 0, no output
#
# `set -u` cannot see it: the assignment leaves D set, to the empty string.
# `set -e` would, and none of the twenty-nine instruments this gate scans uses
# it — they are `set -uo pipefail`, which is the right choice for a reader that
# must report rather than die, and is why the check has to be written.
#
# CASE 2 — the fixed shared name. Several seats run on this box at once by
# design, so two runs choosing one name under /tmp is the expected case and not
# the unlucky one. The second write replaces the first; the reader that follows
# gets bytes of the right schema belonging to someone else, and nothing in the
# sequence can tell.
#
# Reads and writes only inside directories it makes itself.
set -uo pipefail
SHARED=${TMPDIR:-/tmp}
pass=0; fail=0
ok()  { pass=$((pass+1)); printf '  ok   %s\n' "$1"; }
bad() { fail=$((fail+1)); printf '  FAIL %s\n' "$1"; }

W=$(mktemp -d) || { printf 'could not look: mktemp gave this probe no directory\n' >&2; exit 2; }
trap 'rm -rf "$W"' EXIT

printf '\n== case 1: a write through a path a failed mktemp left empty\n'
git init -q "$W/caller"
git -C "$W/caller" config user.email probe@epito.me
git -C "$W/caller" config user.name probe
printf 'x\n' > "$W/caller/f"
git -C "$W/caller" add f
git -C "$W/caller" commit -qm first
git -C "$W/caller" branch -m precious
before=$(git -C "$W/caller" rev-parse --abbrev-ref HEAD)

# The failed mktemp, caused rather than simulated: a TMPDIR that is not there
# is the same refusal a full device gives, and it leaves the variable the same
# way. Measured on this box: rc 1, D set, length 0, script still running.
D=$(TMPDIR="$W/absent" mktemp -d 2>/dev/null)
rc_assign=$?
[ -z "$D" ] && ok "a refused mktemp leaves the variable SET and empty (rc $rc_assign), so set -u is silent" \
            || bad "this box's mktemp did not fail the way the fault needs; the rest of case 1 proves nothing"

# The write the instruments make, with that variable as its only isolation. Run
# from inside the caller, which is where a pre-flight runs from.
( cd "$W/caller" && git -C "$D" branch -m renamed-by-an-empty-path )
rc_write=$?
after=$(git -C "$W/caller" rev-parse --abbrev-ref HEAD)

[ "$rc_write" = 0 ] \
  && ok "git -C '' branch -m reported SUCCESS (rc 0) and printed nothing" \
  || bad "git -C '' branch -m exited $rc_write here, so this box refuses what the fault needs"
[ "$after" != "$before" ] \
  && ok "and it renamed the CALLER's branch: $before -> $after" \
  || bad "the caller's branch survived ($after), so git -C '' did not mean 'here' on this box"

printf '\n== case 2: two runs, one fixed name under the shared directory\n'
# Composed from a variable so that this file is not itself a finding of the
# gate it measures for — the same trick docs/agents/scratch.sh uses.
NAME=pr-body.md
A="$SHARED/$NAME.probe-a"   # stands in for the shared fixed name, without
B="$SHARED/$NAME.probe-a"   # taking a name a real run might be holding
rm -f "$A"
printf 'the twelve-thousand-character body seat A spent its run writing\n' > "$A"
first=$(wc -c < "$A")
printf 'seat B, 46 bytes, naming its own checkout\n' > "$B"
second=$(wc -c < "$A")
read_back=$(cat "$A")
rm -f "$A"

[ "$second" != "$first" ] \
  && ok "seat B's write replaced seat A's file: $first bytes became $second, rc 0 at every step" \
  || bad "the second write did not replace the first, so this box does not show the fault"
case "$read_back" in
  *"seat B"*) ok "and A's own read-back succeeds, returning B's sentence: nothing in the sequence can tell" ;;
  *)          bad "A read back something that was neither seat's line, which is a different fault" ;;
esac

printf '\n-----------------------------------------------\n'
printf 'probe-unowned-path: %d ok, %d failed\n' "$pass" "$fail"
printf 'git: %s\n' "$(git --version)"
[ "$fail" = 0 ] || exit 1
