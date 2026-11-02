#!/usr/bin/env bash
# The four stages one fix passes through, and which hand owns each gap (L46).
#
#   bash docs/agents/stage.sh <identifier> [path]   where a fix has reached
#   bash docs/agents/stage.sh --self-test           fire every verdict on built input
#
# `--self-test` builds the repository it reads as well as the install root, so
# its verdict is about this tool and never about the checkout it is run in: a
# seat gets a shallow clone, and the first version of this self-test read FAILED
# on one because stage 1 could not answer "any branch" there. It exits 0 when
# every assertion holds and 1 when one does not, which is not the 0/1/3 contract
# below — that one is the tool's answer about an identifier, not about itself.
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
# Resolved before the `cd` below, and before any case that runs this file
# again from inside a fixture repository: `$0` is whatever the caller typed,
# so a relative one stops naming this script the moment the cwd moves.
SELF=$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || echo "$0")
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
  # decides its answer on the day it hits. Each verdict below is built — and
  # BUILT means built, including the repository. The first version of this
  # block handed stages 1 and 2 the live clone, which made its verdict a
  # property of how the box happened to clone: on a shallow clone, the only
  # kind a seat gets, stage 1 is could-not-look, the first gap is `written`
  # instead of `installed`, and the tool printed `self-test FAILED` while
  # behaving exactly as designed. A seat runs a self-test to ask whether the
  # instrument works; it must answer that and nothing else.
  t=$(mktemp -d); trap 'rm -rf "$t"' EXIT; fail=0; pass=0
  check_rc() {  # what it asserts, the exit code seen, the exit code owed
    # Numbers compared as numbers. The first version asked `check "rc=$rc"` for
    # the string `rc=1`, which `rc=127` satisfies — and 127 is "command not
    # found", so the assertion that this tool exits right passed loudest in the
    # one case where the tool had not run at all (seen in this run, 1 ok of 19
    # while every report read `No such file or directory`).
    if [ "$2" = "$3" ]; then printf '  ok   %s\n' "$1"; pass=$((pass + 1))
    else printf '  FAIL %s\n       wanted exit %s, got exit %s\n' "$1" "$3" "$2"; fail=$((fail + 1)); fi
  }
  check() {  # what it asserts, the text, the needle
    # `[[ == ]]` and not `grep -qF`: a needle with a newline in it is a LIST of
    # patterns to grep -F, matched independently, so `"1. written"\n"   NOT
    # REACHED"` was satisfied by stage 3's NOT REACHED and said nothing about
    # stage 1 at all. Measured: 2 of 2 asks matched a fixture where the two
    # lines are four lines apart. Bash's own match has no such semantics.
    if [[ $2 == *"$3"* ]]; then printf '  ok   %s\n' "$1"; pass=$((pass + 1))
    else
      printf '  FAIL %s\n       wanted, adjacent: %s\n       in:\n' "$1" "${3//$'\n'/ ⏎ }"
      sed 's/^/       | /' <<<"$2"
      fail=$((fail + 1))
    fi
  }

  # The repository the four stages read, built: two commits on a `main` ref and
  # one identifier that exists only on a side branch, so `written` and `merged`
  # can disagree the way they do in life. `git log --all` sees the side branch;
  # the governing ref does not.
  repo=$t/repo
  git init -q -b main "$repo"
  git -C "$repo" config user.email self-test@epito.me
  git -C "$repo" config user.name 'stage.sh self-test'
  # The third identifier is env-var shaped and exported into the asks below, so
  # the case where the ONLY gap is the install can be built here instead of
  # borrowed from the checkout. `PATH` used to play that part: it reads as
  # written and merged in this repository because commits mention it, which is
  # a fact about this repository and not about the tool.
  printf 'ZZ_FIXTURE_MERGED_ZZ and a fixture phrase, with ZZ_STAGE_SELFTEST_ZZ beside them\n' > "$repo/on-main.txt"
  git -C "$repo" add -A; git -C "$repo" commit -qm 'the fixture main carries two identifiers'
  git -C "$repo" checkout -q -b side
  printf 'ZZ_FIXTURE_WRITTEN_ZZ\n' > "$repo/on-side.txt"
  git -C "$repo" add -A; git -C "$repo" commit -qm 'written, not merged'
  git -C "$repo" checkout -q main
  # The shallow clone of it, which is the condition that broke this block. A
  # built input now, not an accident of the box.
  git clone -q --depth 1 --no-local "file://$repo" "$t/shallow" 2>/dev/null
  ask() {  # the stage report, from inside the fixture repository
    local dir=$1; shift
    ( cd "$dir" && STAGE_MAIN_REF=${STAGE_MAIN_REF:-refs/heads/main} "$@" ) 2>&1
  }

  mkdir -p "$t/pkg"; printf '{"name":"stub"}\n' > "$t/pkg/package.json"

  out=$(ask "$repo" env EPITO_INSTALLED_ROOT="$t/pkg" bash "$SELF" ZZ_NO_SUCH_IDENTIFIER_ZZ); rc=$?
  check "an identifier nobody wrote is NOT REACHED at written" "$out" "1. written"$'\n'"   NOT REACHED"
  check "an identifier nobody merged is NOT REACHED at merged, and names the hand" "$out" \
    "2. merged (refs/heads/main)"$'\n'"   NOT REACHED  not on refs/heads/main — the act owed is a merge"
  check "an absent install says the act owed is an install" "$out" "the act owed is an install"
  check "an absent env var says it is not reaching the seat" "$out" "is absent from this run"
  check_rc "a gap exits 1" "$rc" 1

  out=$(ask "$repo" env EPITO_INSTALLED_ROOT="$t/pkg" bash "$SELF" ZZ_FIXTURE_WRITTEN_ZZ)
  check "written on a branch and nowhere else is REACHED at written" "$out" "1. written"$'\n'"   REACHED"
  check "...and still NOT REACHED at merged, which is the whole point of reading them apart" \
    "$out" "2. merged (refs/heads/main)"$'\n'"   NOT REACHED"
  check "...so the first gap is the merge and the hand is named" "$out" \
    "first gap: merged — merge it (a project manager or a chair)"

  out=$(ask "$repo" env EPITO_INSTALLED_ROOT="$t/pkg" bash "$SELF" ZZ_FIXTURE_MERGED_ZZ)
  check "an identifier on the governing ref is REACHED at merged" "$out" \
    "2. merged (refs/heads/main)"$'\n'"   REACHED  landed in"

  printf 'ZZ_NO_SUCH_IDENTIFIER_ZZ\n' > "$t/pkg/carries.txt"
  out=$(ask "$repo" env EPITO_INSTALLED_ROOT="$t/pkg" bash "$SELF" ZZ_NO_SUCH_IDENTIFIER_ZZ)
  check "an install that carries it is REACHED" "$out" "file(s) under that root carry it"

  # Three stages reached and the fourth unobservable: the documented exit 3,
  # which no case in this block could reach before, because a gap at written or
  # merged had already made it 1.
  printf 'a fixture phrase\n' > "$t/pkg/carries.txt"
  out=$(ask "$repo" env EPITO_INSTALLED_ROOT="$t/pkg" bash "$SELF" 'a fixture phrase'); rc=$?
  check "a non-env identifier cannot be observed in a run" "$out" \
    "4. in effect (this run)"$'\n'"   COULD NOT LOOK"
  check_rc "could-not-look exits 3 and not 0" "$rc" 3
  check "...and could-not-look is not spelled like a gap or like clean (L41)" "$out" \
    "first gap: in effect — name an observable this run can read"

  out=$(ask "$repo" env ZZ_STAGE_SELFTEST_ZZ=1 EPITO_INSTALLED_ROOT="$t/nope" bash "$SELF" ZZ_STAGE_SELFTEST_ZZ)
  check "an unresolvable install is COULD NOT LOOK, not clean" "$out" "no installed copy resolved"
  check "the summary names the first gap and not the furthest stage" "$out" "first gap: installed"
  check "...and the hand for that gap is the one incident 5 says holds no seat" "$out" \
    "name the installed root, then ask again"
  check "a name present in this run is REACHED" "$out" "is present in this run"

  out=$(ask "$repo" env ZZ_STAGE_SELFTEST_ZZ=1 STAGE_MAIN_REF=refs/heads/no-such-ref \
    EPITO_INSTALLED_ROOT="$t/pkg" bash "$SELF" ZZ_STAGE_SELFTEST_ZZ)
  check "a missing governing ref is COULD NOT LOOK" "$out" "is not in this clone"

  # The shallow clone, asked the same question: the tool must say what it cannot
  # see and name the fix, and it must not call that a gap in the work.
  if [ -d "$t/shallow/.git" ]; then
    out=$(ask "$t/shallow" env EPITO_INSTALLED_ROOT="$t/pkg" bash "$SELF" ZZ_FIXTURE_MERGED_ZZ)
    check "a shallow clone cannot answer 'any branch' and says so (L41)" "$out" \
      "1. written"$'\n'"   COULD NOT LOOK  this clone is shallow"
    check "...and names the fix in the message, not just the rule" "$out" "git fetch --unshallow"
  else
    printf '  SKIP a shallow clone could not be made here, so that branch is unasked\n'
  fi

  if [ "$fail" = 0 ]; then printf 'self-test: %d ok, 0 failed — all verdicts agree\n' "$pass"
  else printf 'self-test FAILED: %d ok, %d failed — this tool is wrong about built input.\nFix the tool, or the expectation if the contract moved.\n' "$pass" "$fail"; fi
  exit $(( fail > 0 ))
fi

[ -z "${1:-}" ] && { sed -n '2,20p' "$0"; exit 2; }
stage_report "$1" "${2:-}"
