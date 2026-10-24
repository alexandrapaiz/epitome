#!/usr/bin/env bash
# Whether this run has a private place to write, and who is still writing to
# the shared one (L45).
#
#   bash docs/agents/scratch.sh                 the three questions, this box
#   SHARED=/tmp WINDOW=240 bash docs/agents/scratch.sh
#   bash docs/agents/scratch.sh --self-test     three constructed cases
#
# Every seat on this host runs as one unix user in one temporary directory. A
# file named after its contents rather than after the run that owns it can be
# replaced by another seat between the write and the read, and the replacement
# is valid, schema-matching and silent: no parse, no exit code and no read-back
# can see it. On 2026-10-24 it fired twice before noon. This product's engineer
# published another run's forty-six bytes into its own pull request as the
# entire description (07:07:05Z), and Ursa's research seat read the
# centralizer's board inbox as its own because both had chosen the same short
# filename (12:31:06Z).
#
# The host fix is real and merged — `#181`, every window its own scratch
# directory, 2026-10-23T17:19:05Z — and it has never executed, because the
# installed runtime is not that code (incident 10). So the only live defence
# is the practice, and a practice with no detector is a sentence in a file.
#
# Three answers and not two (L41): a question this box cannot answer prints
# `unreadable` and never prints clean.
#
# Reads only. Needs nothing but the repository and the shared directory.
set -uo pipefail
cd "$(git rev-parse --show-toplevel)" 2>/dev/null || true

SHARED=${SHARED:-/tmp}
WINDOW=${WINDOW:-240}          # minutes of the shared directory to census
SCAN=${SCAN:-docs/agents cli/src}

# ---------------------------------------------------------------- question 1
# Does this run own a directory nobody else is writing to? Being set is not
# enough: a path every seat shares is no better for being named in a variable.
private() {
  local p found=0
  for v in EPITO_SCRATCH TMPDIR; do
    p=${!v:-}
    if [ -z "$p" ]; then printf '  %-14s unset\n' "$v"; continue; fi
    found=1
    if [ ! -d "$p" ]; then
      printf '  %-14s %s — NAMED BUT ABSENT, so a write to it fails or lands elsewhere\n' "$v" "$p"
      continue
    fi
    case "$p" in
      "$SHARED"|"$SHARED"/) printf '  %-14s %s — IS the shared directory, which is no private path at all\n' "$v" "$p";;
      *) printf '  %-14s %s  mode %s  owner %s\n' "$v" "$p" "$(stat -c %a "$p")" "$(stat -c %U "$p")";;
    esac
  done
  [ "$found" = 1 ] && return 0
  echo "  so every file this run writes outside its checkout goes to $SHARED,"
  echo "  and the only thing keeping it apart from another seat's is the name."
  return 1
}

# ---------------------------------------------------------------- question 2
# Which of this repository's own instruments name a fixed path under a shared
# directory. A fixed name is one no run invented: no mktemp template, no pid,
# no random, no timestamp.
fixed_paths() {  # $1.. = paths to scan
  local hits rc=0 d any=0
  for d in "$@"; do
    [ -e "$d" ] || { printf '  unreadable: no such path %s\n' "$d"; rc=2; continue; }
    # Scripts only. Prose that quotes a shared path is a description of this
    # defect, not an instance of it, and a detector that cannot tell the two
    # apart gets switched off (the frameworks law).
    hits=$(find "$d" -type f \( -name '*.sh' -o -name '*.py' -o -name '*.js' -o -name '*.yml' \) -print0 2>/dev/null \
      | xargs -0 -r grep -nE '(^|[^A-Za-z0-9_])/tmp/[A-Za-z0-9][A-Za-z0-9._-]*' 2>/dev/null \
      | grep -vE 'mktemp|XXXXXX|\$\$|\$RANDOM|\$\(date|:[0-9]+:[[:space:]]*#' || true)
    if [ -n "$hits" ]; then
      any=1
      echo "$hits" | sed 's/^/  FIXED /'
    fi
  done
  [ "$rc" = 2 ] && return 2
  [ "$any" = 1 ] && return 1
  printf '  no instrument under %s names a fixed path in a shared directory\n' "$*"
  return 0
}

# ---------------------------------------------------------------- question 3
# What is in the shared directory right now, and which of those names are the
# ones two independent runs will choose. The signature is a short English word
# with an extension and no run in it, and its proof is a sibling that differs
# only by a trailing digit.
census() {
  local n_all n_tmp n_exec plain dupes
  [ -d "$SHARED" ] || { printf '  unreadable: %s is not a directory on this box\n' "$SHARED"; return 2; }
  n_all=$(find "$SHARED" -maxdepth 1 -type f -mmin "-$WINDOW" 2>/dev/null | wc -l)
  n_tmp=$(find "$SHARED" -maxdepth 1 -type f -mmin "-$WINDOW" -name 'tmp.??????????' 2>/dev/null | wc -l)
  n_exec=$(find "$SHARED" -maxdepth 1 -type f -mmin "-$WINDOW" \
            \( -name '*.sh' -o -name '*.py' -o -name '*.js' \) 2>/dev/null | wc -l)
  printf '  %s top-level files written in the last %s minutes, owned by %s distinct users\n' \
    "$n_all" "$WINDOW" "$(find "$SHARED" -maxdepth 1 -type f -mmin "-$WINDOW" -printf '%u\n' 2>/dev/null | sort -u | wc -l)"
  printf '  %s of them run-named (mktemp), %s of them write-then-run scripts\n' "$n_tmp" "$n_exec"

  plain=$(find "$SHARED" -maxdepth 1 -type f -mmin "-$WINDOW" -printf '%f\n' 2>/dev/null \
    | grep -E '^[a-z][a-z_-]{1,13}[0-9]?\.(json|md|txt|log|sh|py|js|diff|csv|yaml)$' | sort)
  if [ -z "$plain" ]; then
    printf '  no collision-shaped names in the window\n'; return 0
  fi
  printf '  %s collision-shaped names — a short word, an extension, no run in it:\n' "$(echo "$plain" | wc -l)"
  echo "$plain" | sed 's/^/    /' | head -40
  dupes=$(echo "$plain" | sed -E 's/[0-9]?\.[a-z]+$//' | sort | uniq -d)
  if [ -n "$dupes" ]; then
    printf '  and these stems appear more than once, which is two runs having already reached for one word:\n'
    echo "$dupes" | sed 's/^/    /'
  fi
  return 1
}

# ------------------------------------------------------------------ self-test
# L42: every branch fires against input built for it, including the branch that
# says it could not look. Matching on the verdict word, never on a count.
selftest() {
  local work root rc=0 a b c shared_literal
  root=$(git rev-parse --show-toplevel)
  work=$(mktemp -d) || { echo "unreadable: mktemp gave this self-test no directory"; return 2; }
  mkdir -p "$work/guilty" "$work/clean"
  shared_literal=/tmp   # composed, so this line is not itself a finding
  printf 'curl x > %s/body.md\n' "$shared_literal" > "$work/guilty/a.sh"
  printf 'work=$(mktemp -d)\ncurl x > "$work/body.md"\n'                    > "$work/clean/b.sh"

  a=$(fixed_paths "$work/guilty"      2>&1 | grep -oE 'FIXED|unreadable|no instrument' | head -1)
  b=$(fixed_paths "$work/clean"       2>&1 | grep -oE 'FIXED|unreadable|no instrument' | head -1)
  c=$(fixed_paths "$work/not-a-path"  2>&1 | grep -oE 'FIXED|unreadable|no instrument' | head -1)
  rm -rf "$work"

  printf 'case 1  a fixed shared path            expect FIXED          got %s\n' "${a:-<nothing>}"
  printf 'case 2  the same write through mktemp  expect no instrument  got %s\n' "${b:-<nothing>}"
  printf 'case 3  a path that is not there       expect unreadable     got %s\n' "${c:-<nothing>}"
  [ "$a" = FIXED ]            || { echo "case 1 disagrees"; rc=1; }
  [ "$b" = "no instrument" ]  || { echo "case 2 disagrees"; rc=1; }
  [ "$c" = unreadable ]       || { echo "case 3 disagrees"; rc=1; }
  [ $rc = 0 ] && echo "ok — all three branches fired and agreed" \
              || echo "a branch of this instrument disagrees with its own constructed input"
  return $rc
}

[ "${1:-}" = "--self-test" ] && { selftest; exit $?; }

printf 'measured %s   shared directory %s   window %s minutes\n\n' "$(date -u +%FT%TZ)" "$SHARED" "$WINDOW"
worst=0
echo "1. does this run have a private place to write"
private || worst=1
echo
echo "2. this repository's own instruments, against a shared fixed path"
# shellcheck disable=SC2086
fixed_paths $SCAN; r=$?; [ $r -gt $worst ] && worst=$r
echo
echo "3. the shared directory as it stands"
census; r=$?; [ $r -gt $worst ] && worst=$r
echo
case $worst in
  0) echo "nothing to act on: a private path, no fixed shared writes, no collision-shaped names";;
  1) echo "findings above. The fix is one word at the write (mktemp), never a check at the read.";;
  2) echo "unreadable in at least one question above — this is not clean (L41)";;
esac
exit $worst
