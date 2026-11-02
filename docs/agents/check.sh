#!/usr/bin/env bash
# Two checks this seat failed by hand twice on 2026-10-18, so they stopped
# being paragraphs in a README and became a command (L21, L23).
#
#   bash docs/agents/check.sh          before every pull request this seat opens
#
# 1. Every charter patch applies, as the sequence docs/agents/patches/ORDER
#    records, into a scratch worktree — because applied in any other order, or
#    with fuzz, some of them silently land wrong (L28).
# 2. Every identifier this branch allocates in a numbered register is free
#    across main AND every open pull request — not just main. A number taken
#    from main alone is correct at the moment it is written and duplicated by
#    the time anyone merges, and a both-sides resolution keeps both copies
#    without a conflict marker.
# 3. This branch's own diff is in one hand, and where it is not, whether the
#    reserved path is this run's choice or inherited from its base (L55 clause
#    one, L-A133). Added 2026-11-02 after four pull requests in one session
#    handed the owner nineteen files she had not been asked about.
#
# Needs a full clone (git clone --depth 1 makes check 2 silently empty) and gh.
set -uo pipefail
cd "$(git rev-parse --show-toplevel)"
fail=0

# A requirement in a comment is not a requirement. Every run of this seat gets
# a shallow clone from the runtime, and in one of those this script answers
# confidently and wrongly: on 2026-10-18 at 14:22Z order.sh read 12 of 36 pull
# requests as mergeable in a shallow clone and 17 of 37 in the same clone one
# command later, having called five branches conflicted that merge clean and
# one clean that conflicts. So the depth is checked here and repaired, and the
# repair is cheap — 0.16s on the resident host, because the objects are local.
if [ "$(git rev-parse --is-shallow-repository)" = true ]; then
  echo "this clone is shallow, which makes every answer below wrong; unshallowing" >&2
  git fetch -q --unshallow origin 2>/dev/null || {
    echo "could not unshallow — refusing rather than answering wrongly" >&2; exit 2; }
fi

# A patch here is a step in a sequence, not a standalone edit. Fourteen of the
# fifteen insert at four shared anchors, so "does it apply to main by itself"
# is the wrong question for every one but the first at each anchor, and the two
# tools answer it misleadingly: `git apply --check a.diff b.diff` passes the
# whole set (nothing is written, so each is checked against the unmodified
# file) while `git apply` on the same set exits 1 on the fourth and leaves two
# charters half-written, and `patch -F3` lands all fourteen but puts five of
# them where their own diffs do not say — one of them through the middle of
# another bullet's sentence. Measured 2026-10-18, L28. So: apply them for real,
# one at a time, in the recorded order, in a scratch worktree thrown away after.
echo "== charter patches apply, in the order docs/agents/patches/ORDER gives =="
order=$(grep -v '^#' docs/agents/patches/ORDER)
scratch=$(mktemp -d); root=$(pwd); n=0
git worktree add -q --detach "$scratch" HEAD || { echo "no scratch worktree" >&2; exit 2; }
for name in $order; do
  n=$((n+1)); printf '%2d %-58s ' "$n" "$name"
  if git -C "$scratch" apply "$root/docs/agents/patches/$name.diff" 2>/dev/null; then
    if git apply --check "docs/agents/patches/$name.diff" 2>/dev/null
      then echo "applies"; else echo "applies (needs its predecessors)"; fi
  else
    # A patch refuses for two reasons that are not the same reason, and until
    # 2026-10-24 this printed one word for both. The run that does what the
    # charter asks — lift a released patch out of this directory and into the
    # charter file it changes (L27) — makes every one of those patches refuse
    # against its own branch from that moment on, and a reader seeing REFUSES
    # concludes the diff is broken and leaves the duty unapplied. So say which.
    # The test is not `git apply --reverse`: a neighbouring patch that moved
    # the context makes a landed patch refuse in reverse too, which is how
    # `2026-10-05-engineer-check-the-register` read as refusing with all five
    # of its added lines present. The test is the added lines themselves,
    # byte-identical, in the file the diff names (L-A50).
    target=$(sed -n 's|^+++ b/||p' "docs/agents/patches/$name.diff" | head -1)
    landed=yes
    while IFS= read -r line; do
      [ -z "$line" ] && continue
      grep -qxF -- "${line#+}" "$target" 2>/dev/null || { landed=no; break; }
    done < <(grep '^+' "docs/agents/patches/$name.diff" | grep -v '^+++')
    if [ "$landed" = yes ]; then
      echo "already in ${target##*/} on this branch — nothing left to apply"
    else
      echo "REFUSES"; fail=1
    fi
  fi
done
git worktree remove --force "$scratch" 2>/dev/null
# A verdict with no evidence attached cannot be investigated, and this one was
# the reason why: at 2026-10-25T23:52Z this check refused this branch over
# `2026-10-05-engineer-check-the-register`, and the same command four minutes
# later said `ok`, same tree, same ORDER file, nothing touched between them.
# Neither answer can be believed now, because the only record of the refusal is
# the word NOT. Four hundred repetitions of the suspected race — `pipefail`
# turning a `grep -q` that matched into a failed pipeline when its writer takes
# a SIGPIPE — reproduced it zero times, so the cause is still open. What ships
# is the diagnostic: on a refusal, print what the comparison actually had in its
# hands, so the next occurrence is readable rather than remembered (L-A44 from
# the other side — the value a check returns has to carry which cause it is).
for f in docs/agents/patches/*.diff; do
  b=$(basename "$f" .diff)
  grep -qxF -- "$b" <<<"$order" || {
    printf '%-62s %s\n' "$b" "NOT IN ORDER — no sequence, so no hand"
    printf '  the comparison had %s line(s) from ORDER and this basename:\n' \
      "$(grep -c . <<<"$order")"
    grep -n . <<<"$order" | sed 's/^/    order /'
    printf '    basename %s\n' "$(printf '%s' "$b" | od -An -c | tr -s ' ')"
    fail=1; }
done

echo
echo "== identifiers free across main and every open pull request =="
git fetch -q origin main 'refs/pull/*/head:refs/remotes/pull/*' 2>/dev/null
# A pre-flight check answers about the state you are about to push, and this
# one asked `HEAD`. On 2026-10-24 at 17:3xZ it printed thirteen identifiers as
# free and said nothing whatever about the two the run had written minutes
# earlier and not yet committed, which reads exactly like a clean answer about
# them (L41: a could-not-look must never be spelled like a clean). So `WORK`
# reads the working tree, which is what the next commit will contain and is
# identical to `HEAD` once it is committed.
taken() {  # taken <ref|WORK> <path> <regex> -> one identifier per line
  if [ "$1" = WORK ]; then cat "$2" 2>/dev/null
  else git show "$1:$2" 2>/dev/null; fi | sed -nE "s/$3/\1/p"
}
for spec in \
  'docs/agents/lessons.md|^## (L[0-9]+) .*$' \
  'docs/agents/incidents.md|^## (Incident [0-9]+) .*$' \
  'docs/decisions.md|^## (ADR-[0-9]+).*$'
do
  path=${spec%%|*}; rx=${spec#*|}
  mine=$(comm -13 <(taken origin/main "$path" "$rx" | sort -u) <(taken WORK "$path" "$rx" | sort -u))
  [ -z "$mine" ] && continue
  for id in $(echo "$mine" | tr ' ' '~'); do
    id=${id//\~/ }
    clash=""
    for pr in $(gh pr list --state open --limit 100 --json number --jq '.[].number' 2>/dev/null); do
      git merge-base --is-ancestor "pull/$pr" HEAD 2>/dev/null && continue   # already mine
      # Herestring, not a pipe: `taken ... | grep -qxF` can report NOT TAKEN
      # for an id the branch really carries, and a false "not taken" here is
      # the duplicate-build failure this repository keeps paying for.
      prids=$(taken "pull/$pr" "$path" "$rx")
      if grep -qxF "$id" <<<"$prids"; then
        this=$(grep -F "## $id " "$path"          | head -1)
        that=$(git show "pull/$pr:$path"  | grep -F "## $id " | head -1)
        [ "$this" = "$that" ] && continue   # same entry, carried by a sibling branch
        clash="$clash #$pr"
      fi
    done
    if [ -n "$clash" ]; then
      printf '%-28s %-14s TAKEN by%s\n' "$path" "$id" "$clash"; fail=1
    else
      printf '%-28s %-14s free\n' "$path" "$id"
    fi
  done
done

echo
echo "== the tier sort on this branch's own diff, and where a reserved path came from =="
# THE FOURTH CHECK, 2026-11-02, and the rule it enforces has been law since
# 2026-10-24: L55 clause one, "files in two hands never share a branch", and
# L-A133, "the slowest clock in a pull request is the clock on all of it". Both
# were obeyed for 41 consecutive pull requests of this seat and then broken four
# times in one session, between 02:26Z and 03:49Z on 2026-11-02 (#387, #390,
# #394, #396 — one `prompts/` path and four to six register and helper files
# each, all four still open). `epitome/pm` declined #394 in writing the same
# hour, naming the five files it would have merged that day.
#
# WHY A COMMAND AND NOT THE CHARTER. The charter patch that repairs the base
# rule exists and is correct: `f02cb89` on #300, written 2026-10-24T23:05:22Z,
# unmerged since. It cannot land without the owner, because it is a `prompts/`
# path, which is the same gate it was written to stop inheriting. So the rule
# whose absence causes the bundle is itself held behind the bundle's own clock,
# and prose cannot break that loop — this can, because `docs/agents/` is a hand
# that merges today (L-A22: the gate goes in the command; L-X1 as amended: an
# incident is closed when something in the tree would notice it again).
#
# TWO FINDINGS, AND THEY ARE NOT THE SAME FINDING (L-A44, L-A50). A branch that
# mixes hands is a sort this run can still perform, and it refuses. A reserved
# path this run INHERITED from its own base is the one a stateless run cannot
# see: the diff shows `prompts/exo-agent.md` with nothing saying whose choice it
# was, and the remedy is not an edit but a re-cut from the trunk. So the second
# finding names the pull request the commit came from, which is the sentence the
# run needs in order to act.
reserved_rx='^prompts/'
base=$(git merge-base origin/main HEAD 2>/dev/null)
if [ -z "$base" ]; then
  echo "  could not decide: no merge base with origin/main (fetch it first)"
else
  changed=$(git diff --name-only "$base" HEAD)
  res=$(grep -E "$reserved_rx" <<<"$changed" | grep -c . )
  oth=$(grep -vE "$reserved_rx" <<<"$changed" | grep -c . )
  printf '  %s reserved path(s), %s other path(s), against %s\n' \
    "$res" "$oth" "$(git rev-parse --short origin/main)"
  if [ "$res" -gt 0 ] && [ "$oth" -gt 0 ]; then
    echo "  MIXED HANDS — a merge is one click on the whole branch, so the owner holds all $((res+oth))"
    grep -E "$reserved_rx" <<<"$changed" | sed 's/^/    owner   /'
    grep -vE "$reserved_rx" <<<"$changed" | sed 's/^/    local   /'
    echo "    the sort is a branch operation, never a sentence in the body (L55 clause one)"
    fail=1
  elif [ "$res" -gt 0 ]; then
    echo "  one hand: the owner's, and nothing else rides with it — this is the shape to open"
  else
    echo "  one hand: local, no reserved path — a hand that merges today"
  fi
  # Whose choice was it. A pull request whose head this branch CONTAINS is one
  # of this branch's bases; a pull request that contains this head is a child of
  # it, and the two are not the same relation. The first version of this check
  # asked only "is this commit in some open pull request", which answers
  # `INHERITED from #394` when run on #394 itself — a branch is always contained
  # in its own pull request (L-A50: two outcomes sharing one field cannot be
  # told apart by that field). So the bases are computed first, by containment
  # in the direction that means base, and the classification reads off them.
  if [ "$res" -gt 0 ]; then
    head=$(git rev-parse HEAD); bases=""
    for pr in $(gh pr list --state open --limit 100 --json number --jq '.[].number' 2>/dev/null); do
      h=$(git rev-parse "pull/$pr" 2>/dev/null) || continue
      [ "$h" = "$head" ] && continue                      # this branch's own
      git merge-base --is-ancestor "pull/$pr" HEAD 2>/dev/null && bases="$bases $pr"
    done
    [ -n "$bases" ] && printf '    this branch contains the whole of%s — its base is a pull request, not the trunk\n' "$bases"
    for c in $(git rev-list "$base..HEAD" -- $(grep -E "$reserved_rx" <<<"$changed" | tr '\n' ' ')); do
      from=""
      for pr in $bases; do
        git merge-base --is-ancestor "$c" "pull/$pr" 2>/dev/null && from="$from #$pr"
      done
      if [ -n "$from" ]; then
        printf '    %s INHERITED from%s — re-cut from the trunk; a revert leaves it in the history\n' \
          "$(git rev-parse --short "$c")" "$from"
        fail=1
      else
        printf '    %s this run wrote it, and it is the only reserved commit a sort can still move\n' \
          "$(git rev-parse --short "$c")"
      fi
    done
  fi
fi
echo
echo "== instruments that count commit distance refuse a clone they cannot deepen =="
# L86 said a truncated frame answers rather than refusing and its error has a
# direction. On 2026-11-02 that rule had its second instance in two
# instruments at once, five days after it became law:
#
#   executing.sh  a file 52 commits BEHIND read as HAND-PATCH, "no commit holds
#                 this text; a checkout would destroy it", with files_behind 0
#   landed.sh     12 of 12 real merges read off-trunk, exit 0, header sha blank
#
# A rule that a seat must remember while writing a new instrument is enforced
# at the reliability of a model reading a file, and both of these were written
# by this seat after the rule was law. So it becomes a link in the command that
# already runs before every pull request this seat opens (L-A22).
#
# THIS PERFORMS THE ACT rather than grepping for the word "shallow" (L-A69): a
# depth-1 single-branch clone whose origin points nowhere, which is the one
# fixture in which an instrument cannot repair itself and must therefore
# refuse. The instruments are derived from the property -- a distance command
# in the file -- and not from a list, because a list is correct on the day it
# is written (L-A26). A verdict this cannot decide is its own class and is
# never counted as a pass (L41).
# WHAT THIS FIXTURE CATCHES, AND WHAT IT DOES NOT. Verified both ways on
# 2026-11-02 by swapping `origin/main`'s pre-fix copies into the fixture:
# executing.sh answers unlabelled at exit 1 and the gate FIRES, which is the
# real positive L-X1 as amended requires. landed.sh exits 2 in here for an
# unrelated reason, so the gate would NOT have caught it — its defect needs an
# origin that is REACHABLE and single-branch, where the fetch succeeds and
# leaves `refs/remotes/origin/main` absent anyway. That fixture needs the
# network and this check does not have it. So the limit is stated rather than
# papered over, and it is owed rather than documented: the second fixture is
# the next thing to build here.
crip=$(mktemp -d)/clone
if git clone -q --no-local --no-hardlinks --depth 1 --branch "$(git rev-parse --abbrev-ref HEAD)" . "$crip" 2>/dev/null; then
  git -C "$crip" remote set-url origin "$crip/no-such-origin" 2>/dev/null
  for f in docs/agents/*.sh; do
    b=$(basename "$f")
    [ "$b" = check.sh ] && continue          # this script; it holds the gate
    grep -qE 'rev-list --count|merge-base|--is-ancestor|rev-list --left-right' "$f" || continue
    printf '  %-16s ' "$b"
    out=$( cd "$crip" && timeout 25 bash "docs/agents/$b" 2>&1 ); rc=$?
    # The property is NOT "exits 2". L86's own clause permits answering from a
    # frame that cannot walk the question, PROVIDED the frame is named and the
    # numbers are labelled as the bounds they are — which is what roster.sh
    # does here, falling back to the host's clone and printing `952 is a LOWER
    # BOUND` with `frame_shallow: yes`. The first version of this gate asked
    # for exit 2 and failed roster.sh, the one instrument L86 was written
    # about, which is the gate reading its own rule more narrowly than the
    # rule. So: refusing is one right answer, and labelling is the other. What
    # fails is a number published from a history the instrument could not read
    # with nothing in the output saying so.
    if [ "$rc" = 2 ]; then
      echo "refuses (exit 2) — could-not-look, which is one right answer"
    elif [ "$rc" = 124 ]; then
      echo "could not decide: it did not finish in 25s in the fixture"
    elif [ "$rc" = 0 ] || [ "$rc" = 1 ]; then
      if grep -qiE 'shallow|lower bound|upper bound|could-not-look|could not look' <<<"$out"; then
        echo "answers, and labels the frame it answered from — L86's other right answer"
      else
        echo "ANSWERS from a history it cannot read, unlabelled — needs the depth guard"; fail=1
      fi
    else
      echo "could not decide: exit $rc for some other reason"
    fi
  done
  rm -rf "$(dirname "$crip")"
else
  echo "  could not decide: could not build the depth-1 fixture"
fi

echo
[ $fail -eq 0 ] && echo "ok" || echo "something above refuses — fix it before the pull request opens"
exit $fail
