#!/usr/bin/env bash
# The four stages one fix passes through, and which hand owns each gap (L46).
#
#   bash docs/agents/stage.sh <identifier> [path]   where a fix has reached
#   bash docs/agents/stage.sh --self-test           fire every verdict on built input
#
# A defect's fix is written, then merged, then installed, then in effect, and
# those are four acts held by four different hands. Nothing in this company
# reads them apart, so a tracker takes a bundled item's least-advanced stage
# and reports it for the whole thing — which is how, on 2026-10-24, the
# private-scratch-directory fix was handed to an engineer as work to build at
# 13:10:23Z, five days after it was written and twenty hours after it merged,
# while the act actually owed was an install no seat holds (incident 22).
#
# Four verdicts and never two (L41): a stage reached, a stage not reached, and
# could-not-look, which must not be spelled like either. Exit 0 when the
# identifier is in effect, 1 when a gap is named, 3 when a stage could not be
# read at all.
#
# It never prints a value, only whether a name is present and how long it is
# (L-X5), and the environment read is anchored to the start of a record
# because a line is not a record (L-X5's seventh shape).
set -uo pipefail
cd "$(git rev-parse --show-toplevel)" 2>/dev/null || true

INSTALLED_ROOT=${EPITO_INSTALLED_ROOT:-}
MAIN_REF=${STAGE_MAIN_REF:-origin/main}

resolve_installed() {
  # L-A70: the copy you reached is the path you resolved, so resolve it and
  # print it. A bare `epito` on PATH may be a shim, a symlink or a checkout.
  # A root handed in is still a claim, so check it rather than echoing it: a
  # path that does not exist must come back as could-not-look and not as a
  # missing install, because those two name different acts (L41).
  if [ -n "$INSTALLED_ROOT" ]; then
    [ -f "$INSTALLED_ROOT/package.json" ] && { echo "$INSTALLED_ROOT"; return 0; }
    return 1
  fi
  local bin; bin=$(command -v epito 2>/dev/null) || return 1
  bin=$(realpath "$bin" 2>/dev/null) || return 1
  local d; d=$(dirname "$bin")
  while [ "$d" != / ]; do
    [ -f "$d/package.json" ] && { echo "$d"; return 0; }
    d=$(dirname "$d")
  done
  return 1
}

stage_report() {
  local id=$1 path=${2:-} rc=0 reached=none firstgap= gapact=
  printf 'measured %s   identifier %s%s\n\n' "$(date -u +%FT%TZ)" "$id" \
    "${path:+   path $path}"

  # 1. written — the oldest commit in this clone that introduced it. A clone
  # that cannot see other branches answers about main alone, and says so.
  printf '1. written\n'
  local shallow; shallow=$(git rev-parse --is-shallow-repository 2>/dev/null || echo unknown)
  if [ "$shallow" = true ]; then
    printf '   COULD NOT LOOK  this clone is shallow, so "any branch" is a subset it cannot name\n'
    rc=3; firstgap=written; gapact="read it in a full clone: git fetch --unshallow"
  else
    local w; w=$(git log --all --reverse --format='%cI %h' -S"$id" ${path:+-- "$path"} 2>/dev/null | head -1)
    if [ -n "$w" ]; then printf '   REACHED  first introduced %s\n' "$w"; reached=written
    else printf '   NOT REACHED  no commit on any ref in this clone introduces it — the act owed is to write it\n'
      rc=1; [ -z "$firstgap" ] && { firstgap=written; gapact="write it"; }; fi
  fi

  # 2. merged — on the ref that governs, by first parent, which is the commit
  # a merge actually made (L-X13: the merge is the distribution).
  printf '2. merged (%s)\n' "$MAIN_REF"
  if ! git rev-parse --verify -q "$MAIN_REF" >/dev/null; then
    printf '   COULD NOT LOOK  %s is not in this clone; fetch it rather than answering\n' "$MAIN_REF"
    rc=3; [ -z "$firstgap" ] && { firstgap=merged; gapact="fetch $MAIN_REF, then ask again"; }
  else
    local on=0; local f; local blob
    for f in $(git log --first-parent --format=%H "$MAIN_REF" | head -600); do
      # The herestring, not a pipe: `git show | grep -qF` answered NOT FOUND
      # for a line main really holds 22 times in 300 asks, then 31 in 300 on a
      # re-measure, every one of them PIPESTATUS `141 0` -- grep matched and
      # exited, and git died writing the rest into the closed pipe. Under
      # `pipefail` that death is the verdict. The herestring form: 0 of 300.
      if [ -n "$path" ]; then
        blob=$(git show "$f:$path" 2>/dev/null)
        grep -qF -- "$id" <<<"$blob" && { on=1; land=$f; continue; }
      else git grep -qF -- "$id" "$f" >/dev/null 2>&1 && { on=1; land=$f; continue; }; fi
      break
    done
    if [ "$on" = 1 ]; then
      printf '   REACHED  landed in %s\n' "$(git log -1 --format='%cI %h %s' "$land" | cut -c1-100)"; reached=merged
    else
      printf '   NOT REACHED  not on %s — the act owed is a merge, and that hand is a project manager or a chair\n' "$MAIN_REF"
      rc=1; [ -z "$firstgap" ] && { firstgap=merged; gapact="merge it (a project manager or a chair)"; }
    fi
  fi

  # 3. installed — the copy the box executes, which is not the copy you edit
  # (incident 10). An unresolvable install is could-not-look, never clean.
  printf '3. installed\n'
  local root; if root=$(resolve_installed); then
    local n; n=$(grep -rlF -- "$id" "$root" 2>/dev/null | wc -l)
    printf '   root %s   built %s\n' "$root" "$(date -u -r "$root/package.json" +%FT%TZ 2>/dev/null || echo unknown)"
    if [ "$n" -gt 0 ]; then printf '   REACHED  %s file(s) under that root carry it\n' "$n"; reached=installed
    else printf '   NOT REACHED  the installed copy does not carry it — the act owed is an install, and no seat holds it (incident 5)\n'
      rc=1; [ -z "$firstgap" ] && { firstgap=installed; gapact="install it on the host (a chair, per incident 5)"; }; fi
  else
    printf '   COULD NOT LOOK  no installed copy resolved; set EPITO_INSTALLED_ROOT to answer\n'
    rc=3; [ -z "$firstgap" ] && { firstgap=installed; gapact="name the installed root, then ask again"; }
  fi

  # 4. in effect — observable from inside a run. Only an environment-variable
  # shaped identifier can be answered here; anything else says so (L41).
  printf '4. in effect (this run)\n'
  if grep -qE '^[A-Z][A-Z0-9_]*$' <<<"$id"; then
    # The credential-assertion class, which this repository's own card ruled
    # goes first: a false ABSENT about a credential that IS present is believed.
    # `env | grep -oE | tr -d = | grep -qx` closed the pipe on `tr`, which
    # closed it on `grep -oE`, which closed it on `env`; one herestring at the
    # end leaves only full-consumers upstream, which cannot be killed early.
    local names; names=$(env | grep -oE '^[A-Za-z_][A-Za-z0-9_]*=' | tr -d =)
    if grep -qx "$id" <<<"$names"; then
      printf '   REACHED  %s is present in this run\n' "$id"
      reached="in effect"
    else
      printf '   NOT REACHED  %s is absent from this run, so whatever is installed is not reaching the seat\n' "$id"
      rc=1; [ -z "$firstgap" ] && { firstgap="in effect"; gapact="restart the thing that builds a run's environment"; }
    fi
  else
    printf '   COULD NOT LOOK  %s is not an environment-variable name, so this run cannot observe it; name the observable instead\n' "$id"
    [ "$rc" = 0 ] && rc=3
    [ -z "$firstgap" ] && { firstgap="in effect"; gapact="name an observable this run can read"; }
  fi

  # The furthest stage reached is the flattering number and the first gap is
  # the useful one, because a later stage can pass for a reason unrelated to
  # this fix. Print the gap, and print every stage above it as still owed.
  printf '\n'
  if [ -n "$firstgap" ]; then
    printf 'first gap: %s — %s\n' "$firstgap" "$gapact"
    printf 'stages reached before it: %s\n' "$reached"
  else
    printf 'no gap: in effect in this run\n'
  fi
  return $rc
}

if [ "${1:-}" = --self-test ]; then
  # L42: the branch an instrument has never been made to hit is the one that
  # decides its answer on the day it hits. Each verdict below is built.
  t=$(mktemp -d); trap 'rm -rf "$t"' EXIT; fail=0
  check() { if grep -qF "$3" <<<"$2"; then echo "  ok   $1"
            else echo "  FAIL $1: wanted '$3' in:"; printf '%s\n' "$2" | sed 's/^/        /'; fail=1; fi; }

  mkdir -p "$t/pkg"; printf '{"name":"stub"}\n' > "$t/pkg/package.json"

  out=$(EPITO_INSTALLED_ROOT=$t/pkg bash "$0" ZZ_NO_SUCH_IDENTIFIER_ZZ 2>&1); rc=$?
  check "an identifier nobody wrote is NOT REACHED at written" "$out" "1. written"$'\n'"   NOT REACHED"
  check "an absent install says the act owed is an install" "$out" "the act owed is an install"
  check "an absent env var says it is not reaching the seat" "$out" "is absent from this run"
  check "a gap exits 1" "rc=$rc" "rc=1"

  printf 'ZZ_NO_SUCH_IDENTIFIER_ZZ\n' > "$t/pkg/carries.txt"
  out=$(EPITO_INSTALLED_ROOT=$t/pkg bash "$0" ZZ_NO_SUCH_IDENTIFIER_ZZ 2>&1)
  check "an install that carries it is REACHED" "$out" "file(s) under that root carry it"

  out=$(EPITO_INSTALLED_ROOT=$t/pkg bash "$0" 'some phrase' 2>&1); rc=$?
  check "a non-env identifier cannot be observed in a run" "$out" "4. in effect (this run)"$'\n'"   COULD NOT LOOK"
  check "could-not-look exits 3 and not 0" "rc=$rc" "rc=1"

  out=$(EPITO_INSTALLED_ROOT=$t/nope bash "$0" PATH 2>&1)
  check "an unresolvable install is COULD NOT LOOK, not clean" "$out" "no installed copy resolved"
  check "the summary names the first gap and not the furthest stage" "$out" "first gap: installed"
  check "a name present in this run is REACHED" "$out" "is present in this run"

  out=$(STAGE_MAIN_REF=refs/heads/no-such-ref EPITO_INSTALLED_ROOT=$t/pkg bash "$0" PATH 2>&1)
  check "a missing governing ref is COULD NOT LOOK" "$out" "is not in this clone"

  [ $fail = 0 ] && echo "all verdicts agree" || echo "self-test FAILED"
  exit $fail
fi

[ -z "${1:-}" ] && { sed -n '2,20p' "$0"; exit 2; }
stage_report "$1" "${2:-}"
