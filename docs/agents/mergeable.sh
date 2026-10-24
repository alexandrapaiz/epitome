#!/usr/bin/env bash
# Is this pull request mergeable — into the base it will actually merge into?
# (L43, incident 19.)
#
#   bash docs/agents/mergeable.sh            every open pull request
#   bash docs/agents/mergeable.sh 264 271     only these
#   bash docs/agents/mergeable.sh --self-test three constructed cases, one per verdict
#
# docs/agents/order.sh answers "what can a merger take to main, and in what
# order". docs/agents/landed.sh answers "what left the queue". Neither answers
# the question GitHub asks when somebody clicks merge on one pull request,
# which is whether that head applies to *its own base ref* — and for a stacked
# branch that base is not main.
#
# On 2026-10-24 that gap cost five hours and thirteen minutes. Pull request
# #264's base was `epitome-exo/2026-10-24-message-4`. Two passes of the merging
# seat decided it against main instead, by hand, and the command they wrote
# down says so: `git merge-tree --write-tree origin/main origin/epitome-exo/
# 2026-10-24-message-5`. Against main there is a real add/add conflict in this
# directory's own addressed.sh; against the actual base there is none. The
# branch was declined at 06:53:01Z, re-measured at 07:04Z with the same wrong
# base and the same answer, and merged clean at 12:06:31Z once somebody ran it
# against message-4.
#
# The part worth building a command for is why re-measurement did not catch it.
# A conflict found against the wrong base is usually a TRUE fact about a
# DIFFERENT merge — that file does collide when the whole chain reaches main —
# so it reproduces exactly, reads as confirmation, and the instruction it
# produces is worse than idle: "resolve the addressed.sh conflict" on a branch
# whose merge does not touch addressed.sh means editing away from main's copy
# rather than toward it.
#
# So every verdict here prints the base it was measured against and that base's
# head, both answers when they differ, and never one without the other. Needs a
# full clone and gh.
set -uo pipefail
cd "$(git rev-parse --show-toplevel)"
MAIN=${MAIN:-origin/main}

# Same reason as order.sh: in a shallow clone merge-tree answers confidently
# and wrongly, and every run of this seat starts from one.
if [ "$(git rev-parse --is-shallow-repository)" = true ]; then
  echo "this clone is shallow, which makes every answer below wrong; unshallowing" >&2
  git fetch -q --unshallow origin 2>/dev/null || {
    echo "could not unshallow — refusing rather than answering wrongly" >&2; exit 2; }
fi

# Three answers and not two (L41): clean, conflict, and could-not-look, and the
# third is spelled so it can never be mistaken for the first.
verdict() {  # verdict <base-ref> <head-ref>; echoes "clean" | "CONFLICT <files>" | "unreadable <why>"
  local base=$1 head=$2 out
  git rev-parse --verify -q "$base" >/dev/null || { echo "unreadable no such ref $base"; return 2; }
  git rev-parse --verify -q "$head" >/dev/null || { echo "unreadable no such ref $head"; return 2; }
  if out=$(git merge-tree --write-tree "$base" "$head" 2>&1); then
    echo clean; return 0
  fi
  local files
  files=$(echo "$out" | sed -nE 's/^CONFLICT \(.*\): Merge conflict in (.*)$/\1/p' | sort -u | tr '\n' ' ')
  [ -z "$files" ] && files=$(echo "$out" | sed -nE 's/^CONFLICT \((.*)\).*/\1/p' | sort -u | tr '\n' ' ')
  echo "CONFLICT ${files:-unnamed}"; return 1
}

selftest() {
  # L42: the branch an instrument has never been made to hit is the one that
  # decides its answer on the day it hits. Three verdicts, three constructed
  # inputs, built here rather than borrowed from the queue, so this passes or
  # fails the same way on any clone.
  local work root rc=0
  root=$(pwd); work=$(mktemp -d)
  git init -q "$work"; git -C "$work" config user.email x@x; git -C "$work" config user.name x
  echo base > "$work/f"; git -C "$work" add f; git -C "$work" commit -q -m base
  git -C "$work" branch -M trunk
  # A stack: parent diverges from trunk in one file, child adds an untouched one.
  git -C "$work" checkout -q -b parent
  echo parent-side > "$work/shared"; git -C "$work" add shared; git -C "$work" commit -q -m parent
  git -C "$work" checkout -q -b child
  echo child > "$work/own"; git -C "$work" add own; git -C "$work" commit -q -m child
  # trunk independently grows a different version of the same shared file.
  git -C "$work" checkout -q trunk
  echo trunk-side > "$work/shared"; git -C "$work" add shared; git -C "$work" commit -q -m trunk
  # And a branch that genuinely conflicts with its own base. The base has to
  # move AFTER the branch leaves it, or the merge is a fast-forward and comes
  # back clean — which is how the first draft of this self-test disagreed with
  # a correct instrument, and is the whole reason L42 asks for constructed
  # inputs rather than remembered ones.
  git -C "$work" checkout -q -b rogue parent
  echo rogue-side > "$work/shared"; git -C "$work" add shared; git -C "$work" commit -q -m rogue
  git -C "$work" checkout -q parent
  echo parent-moved > "$work/shared"; git -C "$work" add shared; git -C "$work" commit -q -m parent-moves

  cd "$work"
  local a b c d
  a=$(verdict parent child)                 # clean onto its own base
  b=$(verdict trunk  child)                 # the #264 case: conflicts with main only
  c=$(verdict parent rogue)                 # conflicts with its own base
  d=$(verdict parent no-such-branch-here)   # could-not-look
  cd "$root"
  rm -rf "$work"

  printf 'case 1  child onto its own base      expect clean           got %s\n' "$a"
  printf 'case 2  child onto trunk             expect CONFLICT shared got %s\n' "$b"
  printf 'case 3  rogue onto its own base      expect CONFLICT shared got %s\n' "$c"
  printf 'case 4  a base ref that is not there expect unreadable      got %s\n' "$d"
  [ "$a" = clean ]                 || { echo "case 1 disagrees"; rc=1; }
  [ "$b" = "CONFLICT shared " ]    || { echo "case 2 disagrees"; rc=1; }
  [ "$c" = "CONFLICT shared " ]    || { echo "case 3 disagrees"; rc=1; }
  case "$d" in unreadable*) ;; *) echo "case 4 disagrees"; rc=1;; esac
  [ $rc = 0 ] && echo "ok — all four branches fired and agreed" \
              || echo "a branch of this instrument disagrees with its own constructed input"
  return $rc
}

[ "${1:-}" = "--self-test" ] && { selftest; exit $?; }

git fetch -q origin main '+refs/heads/*:refs/remotes/origin/*' 2>/dev/null
printf 'measured %s   main %s %s\n\n' "$(date -u +%FT%TZ)" "$MAIN" "$(git rev-parse --short "$MAIN")"

want=("$@")
mapfile -t rows < <(gh pr list --state open --limit 200 \
  --json number,isDraft,headRefOid,baseRefName,title --jq \
  '.[] | [.number, (if .isDraft then "draft" else "ready" end), .headRefOid[0:8], .baseRefName, .title] | @tsv' \
  | sort -n)

stacked=0; blocked_own=0; rc=0
for row in "${rows[@]}"; do
  IFS=$'\t' read -r n draft sha baseref title <<<"$row"
  if [ ${#want[@]} -gt 0 ]; then
    printf '%s\n' "${want[@]}" | grep -qxF "$n" || continue
  fi
  git fetch -q origin "refs/pull/$n/head:refs/remotes/pull/$n" 2>/dev/null
  base="origin/$baseref"
  basesha=$(git rev-parse --short "$base" 2>/dev/null || echo "????????")
  own=$(verdict "$base" "pull/$n"); ownrc=$?
  printf '#%-5s %-5s head %s   base %-44s %s\n' "$n" "$draft" "$sha" "$baseref@$basesha" "$own"
  [ $ownrc = 1 ] && blocked_own=$((blocked_own+1))
  [ $ownrc = 2 ] && rc=2
  if [ "$baseref" != main ]; then
    stacked=$((stacked+1))
    tomain=$(verdict "$MAIN" "pull/$n")
    printf '%6s %-5s %s\n' "" "" "onto main instead: $tomain — a later step's question, not this one's"
    if [ "$own" = clean ] && [ "${tomain%% *}" = CONFLICT ]; then
      printf '%6s %-5s %s\n' "" "" "this is incident 19's exact shape: clean where it merges, conflicted where it does not merge yet"
    fi
  fi
  printf '%6s       %s\n' "" "${title:0:72}"
done

printf '\n%d measured; %d do not target main, so main is the wrong base for them; %d conflict with the base they actually merge into\n' \
  "${#rows[@]}" "$stacked" "$blocked_own"
printf 'a verdict without its base is not a verdict — quote both columns or neither\n'
exit $rc
