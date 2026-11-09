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
# 4. This branch's NAME is free across every pull request this repository has
#    ever had, and not just across the live remote -- the same allocation that
#    check 2 performs for an identifier, for the same reason (L106). Added
#    2026-11-02 by the run whose own branch collided with a pull request that
#    had merged six hours earlier and taken its name out of existence.
#
# 5. The two gates that read docs/agents/ -- cli/test/shapes.sh whole, and
#    cli/test/selftests.sh over the tools THIS branch changed. Added
#    2026-11-02 after three of this seat's own tools landed on main red
#    through those two gates in one morning, each found by another seat,
#    because nothing in this seat's path ran either one (L-A22).
#
# 6. Every command this repository's own documents print names a script this
#    checkout has, run with the interpreter its shebang names, under a flag it
#    actually dispatches on. Added 2026-11-08 after a seat copied a printed
#    invocation and got 40 findings under a sentence claiming exit 0 — a
#    command in a document is read by people and run by nothing.
#
# Needs a full clone (git clone --depth 1 makes check 2 silently empty) and gh.
set -uo pipefail
cd "$(git rev-parse --show-toplevel)"
fail=0
# A herestring, never `producer | grep -q`: quiet grep exits on the match, the
# producer dies writing into the closed pipe, and `pipefail` reports the match
# as a failure (cli/test/shapes.sh, 442 of 500 wrong at 64 KiB).
said() { local h=$1; shift; grep -q "$@" <<<"$h"; }

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
echo "== identifiers free across main, every open pull request, and every orphan =="
git fetch -q origin main 'refs/pull/*/head:refs/remotes/pull/*' 2>/dev/null
# A pre-flight check answers about the state you are about to push, and this
# one asked `HEAD`. On 2026-10-24 at 17:3xZ it printed thirteen identifiers as
# free and said nothing whatever about the two the run had written minutes
# earlier and not yet committed, which reads exactly like a clean answer about
# them (L41: a could-not-look must never be spelled like a clean). So `WORK`
# reads the working tree, which is what the next commit will contain and is
# identical to `HEAD` once it is committed.
#
# AND THE POPULATION WAS WRONG, WHICH IS A SEPARATE DEFECT FROM THE REF
# (L108). The scan below read `gh pr list --state open`, and a pull request the
# forge closed is not open. At 2026-11-02T08:44:35Z #417 merged; at 08:44:37Z
# the forge closed #418, unmerged, because #417's head branch — #418's base —
# was deleted on merge. #418 carried `L107` and `Incident 69` in seven commits
# on a branch that still existed, and for the 429 seconds until `epitome/pm`
# re-opened the same head as #424 this very check answered **free** for both
# identifiers. Nothing was wrong with how it read a ref; it was asking the
# wrong set of refs.
#
# So the population is open pull requests PLUS closed-and-never-merged ones
# whose head branch is still on `origin`, which is exactly the set somebody is
# about to recreate — #424 was recreated seven minutes later. A closed pull
# request whose branch is also gone carries no text anybody can land, and is
# correctly out of scope.
#
# THE TWO OUTCOMES ARE NOT ONE OUTCOME (L-A44, L-A50). A live open pull request
# holding your identifier is a collision, and the remedy is to renumber here. An
# orphan holding it is not: the orphan's text is older, it is the one a merger
# will take, and renumbering around it ratifies the orphaning. So the label says
# which, and names the remedy that does not destroy the other seat's entry.
scan_prs=""; orphans=""
if command -v gh >/dev/null; then
  scan_prs=$(gh pr list --state open --limit 200 --json number --jq '.[].number' 2>/dev/null)
  # `--state closed` includes merged, so the filter is `mergedAt == null`. The
  # window is the newest 200 closed pull requests, and that scope is part of
  # the answer (L-A47): an orphan older than that has had its branch deleted by
  # every housekeeping pass this repository runs, which is what takes it out.
  live=$(git ls-remote --heads origin 2>/dev/null | sed 's|.*refs/heads/||')
  if [ -n "$live" ]; then
    orphans=$(gh pr list --state closed --limit 200 \
                --json number,mergedAt,headRefName \
                --jq '.[] | select(.mergedAt == null) | "\(.number) \(.headRefName)"' 2>/dev/null \
              | while read -r onum oref; do
                  grep -qxF "$oref" <<<"$live" && printf '%s\n' "$onum"
                done)
  else
    echo "  could not look at orphans: origin would not list its heads (L41)"
  fi
  # The count and not the list. Forty-five orphans were in scope the first time
  # this ran, and a forty-five-number line every run is the kind of noise that
  # teaches a reader to skip the section it is in; the numbers are printed where
  # they mean something, which is on a clash.
  if [ -n "$orphans" ]; then
    printf '  scope: %s open pull request(s) and %s orphan(s) — closed, never merged, branch still on origin\n' \
      "$(printf '%s\n' $scan_prs | grep -c .)" "$(printf '%s\n' $orphans | grep -c .)"
  fi
else
  echo "  could not look: no gh, so only main is in scope (L41)"
fi
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
    clash=""; orphaned=""
    for pr in $scan_prs $orphans; do
      git merge-base --is-ancestor "pull/$pr" HEAD 2>/dev/null && continue   # already mine
      # Herestring, not a pipe: `taken ... | grep -qxF` can report NOT TAKEN
      # for an id the branch really carries, and a false "not taken" here is
      # the duplicate-build failure this repository keeps paying for.
      prids=$(taken "pull/$pr" "$path" "$rx")
      if grep -qxF "$id" <<<"$prids"; then
        this=$(grep -F "## $id " "$path"          | head -1)
        that=$(git show "pull/$pr:$path"  | grep -F "## $id " | head -1)
        [ "$this" = "$that" ] && continue   # same entry, carried by a sibling branch
        if grep -qxF "$pr" <<<"$orphans"; then orphaned="$orphaned #$pr"
        else clash="$clash #$pr"; fi
      fi
    done
    # Both lines when both are true, because the two remedies are different and
    # a reader shown only the louder one acts on half the finding (L-A88: a
    # summary line names every class it counted).
    if [ -n "$clash" ]; then
      printf '%-28s %-14s TAKEN by%s — renumber here (L23)\n' "$path" "$id" "$clash"; fail=1
    fi
    if [ -n "$orphaned" ]; then
      printf '%-28s %-14s ORPHANED on%s — closed unmerged, branch alive\n' "$path" "$id" "$orphaned"
      printf '%-28s %-14s   that entry is older than yours and is the one a merger takes:\n' "" ""
      printf '%-28s %-14s   recreate it against `main` and renumber HERE, or carry its head\n' "" ""
      printf '%-28s %-14s   in. Renumbering around it silently ratifies the orphaning (L108).\n' "" ""
      fail=1
    fi
    if [ -z "$clash" ] && [ -z "$orphaned" ]; then
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
echo "== this seat's live asks on one reserved path compose with each other =="
# THE FIRST CHECK IN THIS FILE CLAIMS THIS GROUND AND CANNOT SEE IT (L109).
# `docs/agents/patches/ORDER` holds five diffs, all of them for the engineer's
# and the project manager's charters, and the charter's own rule is why: L27
# forbids this seat a patch in a file beside the charter, because "a diff that
# is not in the file it changes has no click to be". So every charter proposal
# this seat makes lives in a pull request, and the gate that exists to refuse
# "a charter patch `git apply` will not take" is pointed at the one directory
# the charter forbids putting them in. Not a stale check — a check aimed away
# from its subject, which reads as an all-clear (L77, L-A21).
#
# WHAT WAS THERE WHEN IT WAS FINALLY ASKED, 2026-11-02T08:49Z. Three live asks
# on `prompts/exo-agent.md`: #300 from 2026-10-24, #312 from 2026-10-25, #396
# from this morning. Each applies to `origin/main` alone. **#300 and #312 do
# not compose, in either order** — `#300` then `#312` fails at line 94, `#312`
# then `#300` fails at line 102 — so the owner may merge either and the second
# one she reaches will conflict, nine days after the first was written, with
# nothing in this repository having said so. #396 composes with both.
#
# WHY A PAIR AND NOT THE WHOLE SEQUENCE. There is no ORDER file for pull
# requests and this seat does not get to invent the merge order of the owner's
# own queue. A pair is the smallest claim that is true regardless of what she
# merges: if two asks cannot both land, that is a fact about the two of them
# and about no sequence. Reported as an observation, because the merge gate is
# hers by design.
if ! command -v gh >/dev/null; then
  echo "  could not look: no gh, so the queue cannot be read (L41)"
elif ! git rev-parse --verify -q origin/main >/dev/null; then
  echo "  could not look: no origin/main to compose against (L41)"
else
  # The source is a named ref and the report prints which one (L-X16): a
  # composition measured against the invoker's working tree is unfalsifiable.
  echo "  composing against origin/main at $(git rev-parse --short origin/main)"
  # AND IT REFUSES ONLY WHAT THIS BRANCH CAN FIX. A pair of asks that cannot
  # both land is a fact about the owner's queue, and the charter is explicit
  # that this seat reports such things as observations and never as proposals
  # because the merge gate is hers by design. A gate that fails every future
  # branch of this seat over #300 x #312 until she merges one of them is a gate
  # this seat learns to route around (L-A56, L-A160, and L-X5's own warning
  # about a guard that punishes the compliant form). So: a non-composing pair
  # containing THIS branch's pull request refuses, because the branch in hand
  # can act on it. Any other pair is printed as an observation and the exit code
  # is left alone.
  self=$(gh pr list --head "$(git rev-parse --abbrev-ref HEAD)" --state open \
           --limit 5 --json number --jq '.[].number' 2>/dev/null | tr '\n' ' ')
  [ -n "$self" ] && echo "  this branch is#$(printf '%s' "${self% }" | sed 's/ / #/g'), so a pair naming it refuses and the rest are observations"
  pairs=$(gh pr list --state open --limit 200 --json number,files 2>/dev/null \
          | python3 -c '
import json, sys, itertools, collections
by = collections.defaultdict(list)
for p in json.load(sys.stdin):
    for f in p.get("files") or []:
        if f["path"].startswith("prompts/"):
            by[f["path"]].append(p["number"])
for path in sorted(by):
    ns = sorted(set(by[path]))
    for a, b in itertools.combinations(ns, 2):
        print("%s\t%s\t%s" % (path, a, b))
')
  if [ -z "$pairs" ]; then
    echo "  no reserved path carries two live asks, so there is nothing to compose"
  else
    cw=$(mktemp -d) || { echo "  could not look: no scratch directory (L107)" >&2; cw=""; }
    if [ -z "$cw" ]; then
      fail=1
    elif ! git worktree add -q --detach "$cw" origin/main 2>/dev/null; then
      echo "  could not look: no scratch worktree at origin/main (L41)"
      rmdir "$cw" 2>/dev/null
    else
      # A pair is tested in both orders, because `git apply` is not symmetric:
      # the first patch moves the context the second one is anchored to, so an
      # ask can be landable before a sibling and refuse after it.
      while IFS=$'\t' read -r cpath a b; do
        [ -z "$cpath" ] && continue
        pa="$cw/.ask-$a.patch"; pb="$cw/.ask-$b.patch"
        git diff "origin/main...pull/$a" -- "$cpath" > "$pa" 2>/dev/null
        git diff "origin/main...pull/$b" -- "$cpath" > "$pb" 2>/dev/null
        if [ ! -s "$pa" ] || [ ! -s "$pb" ]; then
          printf '  %s  #%s x #%s  could not look: a pull ref would not resolve (L41)\n' \
            "$cpath" "$a" "$b"
          continue
        fi
        bad=""
        for ord in "$a $b" "$b $a"; do
          set -- $ord
          git -C "$cw" checkout -q -- . 2>/dev/null
          if git -C "$cw" apply "$cw/.ask-$1.patch" 2>/dev/null \
             && git -C "$cw" apply --check "$cw/.ask-$2.patch" 2>/dev/null; then :
          else bad="$bad #$1-then-#$2"; fi
        done
        git -C "$cw" checkout -q -- . 2>/dev/null
        if [ -n "$bad" ]; then
          # `case` and not `grep -qw ... || grep -qw ...`: `cli/test/shapes.sh`
          # counts the `||` in that form as a quiet pipe, which it is not —
          # there is no writer on the left of a logical-or whose status could be
          # masked, and the right-hand side is the herestring that gate's own
          # fix text prescribes. Reported to `epitome/engineer`, whose surface
          # `cli/test/` is; a glob on a space-padded list is the cheaper form
          # here anyway.
          if case " $self " in *" $a "*|*" $b "*) true ;; *) false ;; esac; then
            printf '  %s  #%s x #%s  DOES NOT COMPOSE:%s — and one of them is THIS branch\n' \
              "$cpath" "$a" "$b" "$bad"
            fail=1
          else
            printf '  %s  #%s x #%s  does not compose:%s — observation, neither is this branch\n' \
              "$cpath" "$a" "$b" "$bad"
          fi
          noncompose=1
        else
          printf '  %s  #%s x #%s  compose, both orders\n' "$cpath" "$a" "$b"
        fi
      done <<<"$pairs"
      if [ "${noncompose:-0}" = 1 ]; then
        echo "  A pair that does not compose is one ask the owner cannot merge second, and"
        echo "  this seat may not pick her order. Say it in the body and route it; never"
        echo "  rebase another run's ask to suit this one (L29: the clock consents to the"
        echo "  words the ask showed her)."
      fi
      git worktree remove --force "$cw" 2>/dev/null
    fi
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
echo "== this branch's NAME has never carried another pull request =="
# Check 2 above allocates an identifier from the whole queue rather than from
# main, on the ground that a number free on main is duplicated by the time
# anyone merges. A branch name is allocated the same way and nothing was doing
# it (L106). L-A59 deletes a head branch on merge, so the name goes free on the
# remote; a run told to suffix its branch "if it exists" tests the live remote
# and takes a name a merged pull request already has. 59 of this repository's
# 416 pull requests sat under a reused name on 2026-11-02, 23 names, every
# seat, and this check was written by the run that did it to itself.
#
# WHY IT MATTERS WHEN THE BRANCH ITSELF IS GONE: `origin/<name>` is the key
# L24's refutation clause hands a reader -- "the eight characters of the head
# you measured it at, so a seat you have described wrongly can refute you with
# one git rev-parse". That rev-parse answers about whichever pull request the
# clone fetched last and says nothing about the other one.
#
# ONE REMEDY, AND THE SECOND ONE IS A TRAP THIS CHECK'S AUTHOR WALKED INTO.
# The first draft of these lines said a branch with an open pull request on it
# could be renamed through the forge, `gh api -X POST .../branches/{b}/rename`,
# on the documented behaviour that open pull requests follow a renamed branch.
# Performed on `epitome-exo/2026-11-02-message` at 2026-11-02T07:33Z it
# renamed the branch to `-17` and **closed `#415`**: `.head.ref` still read the
# old name, `.state` read `closed`, and the pull request was not retargeted.
# Same class as the base-deletion defect `epitome/pm` named an hour earlier,
# arriving through the rename door. So:
#
#   before the push      git branch -m <name>-<n+1>, and this is the whole fix
#   after a pull request is open   do NOT rename. The name is spent. Carry
#                        number@sha in every reference (L106) and let the next
#                        run's copy of this check refuse the name. If the pull
#                        request carries only the commit that opened it, the
#                        charter's own clause applies -- close it and re-declare
#                        what it owed -- which is what this run did, once, after
#                        the forge had already closed it.
#
# A gate may not print as its remedy an act that destroys the work (L103's
# shape: the remedy a gate names is part of the gate).
if ! command -v gh >/dev/null; then
  echo "  could not decide: no gh, so the full queue cannot be read (L41)"
else
  nbranch=$(git rev-parse --abbrev-ref HEAD)
  if [ "$nbranch" = HEAD ] || [ "$nbranch" = main ]; then
    echo "  not on a seat branch ($nbranch), so there is no name to allocate"
  elif ! allprs=$(gh pr list --state all --limit 500 \
        --json number,headRefName,headRefOid,state,createdAt 2>/dev/null); then
    echo "  could not decide: could not list pull requests (L41)"
  else
    taken=$(BRANCH="$nbranch" python3 -c '
import json, os, sys
prs = json.load(sys.stdin)
b = os.environ["BRANCH"]
for p in sorted((p for p in prs if p["headRefName"] == b), key=lambda p: p["createdAt"]):
    print("%s\t%s\t%s\t%s" % (p["number"], p["state"], p["headRefOid"][:8], p["createdAt"]))
' <<<"$allprs")
    n=$(printf '%s' "$taken" | grep -c . || true)
    if [ "$n" -le 1 ]; then
      echo "  $nbranch has carried $n pull request(s), so the name is still a key"
      [ "$n" = 1 ] && printf '%s\n' "$taken" | awk '{printf "    #%-5s %-7s %s  created %s\n", $1, $2, $3, $4}'
    else
      echo "  REFUSES: $nbranch has carried $n pull requests --"
      printf '%s\n' "$taken" | awk '{printf "    #%-5s %-7s %s  created %s\n", $1, $2, $3, $4}'
      echo "  Nothing pushed yet:  git branch -m <name>-<n+1>  — and that is the whole fix."
      echo "  A pull request already OPEN on it: do not rename. A forge-side rename"
      echo "  closed #415 at 07:33Z on 2026-11-02 rather than retargeting it. The name"
      echo "  is spent: carry number@sha in every reference (L106) and let the next"
      echo "  run's copy of this check refuse the name."
      fail=1
    fi
  fi
fi

echo
echo "== the two gates over the tools this branch changed, run here and elsewhere =="
# WHY THIS IS IN THE PRE-FLIGHT AND NOT IN A CHARTER SENTENCE (L-A22, L-A9).
# Both gates existed, both were correct, and three of this seat's own tools
# landed on `main` red through them inside one morning:
#
#   00:22:50Z  cli/test/selftests.sh lands -- every self-testing tool in
#              docs/agents/, run twice, here and in a repository that is not
#              this one
#   00:46:12Z  executing.sh lands, 24 minutes later, failing it: its negative
#              fixture dirtied a path out of THIS layout
#   05:34:54Z  route.sh lands with two quiet-pipe sites, failing
#              cli/test/shapes.sh, which had been reading docs/agents/ since
#              2026-10-26
#   06:13:48Z  caps.sh lands failing selftests.sh: it read its own sibling
#              through the cwd's git toplevel
#
# Every one was found and reported by another seat -- the engineer, then this
# company's project manager re-finding it hours later and handing it back --
# and nothing in this seat's own path had looked. `grep -l pull_request
# .github/workflows/*.yml` is empty: this repository runs nothing on a pull
# request, so the only reader of either gate is `cli/test/all.sh`, the full
# suite, which this seat does not run and should not have to.
#
# SCOPE IS THE CHANGED FILES, deliberately. selftests.sh over all eighteen
# tools runs each of them twice under a 180s timeout, which is tens of minutes;
# over the one or two files a branch touched it is seconds, and it is the only
# scope at which an answer is about this branch at all. shapes.sh is whole-tree
# and runs in milliseconds, so it is taken entire.
if [ ! -d cli/test ]; then
  echo "  could not look: no cli/test in this checkout (L41)"
elif ! base=$(git merge-base HEAD origin/main 2>/dev/null); then
  echo "  could not look: no merge base with origin/main, so the changed set is unknown (L41)"
else
  if out=$(cd cli && bash test/shapes.sh 2>&1); then
    echo "  ok      shapes.sh: $(sed -n 's/^shapes: //p' <<<"$out")"
  else
    echo "  REFUSES shapes.sh:"
    grep -E '^[[:space:]]*FAIL' <<<"$out" | sed 's/^/    /'
    fail=1
  fi
  changed=$(git diff --name-only "$base" HEAD -- docs/agents/ | grep -E '[.]sh$' || true)
  if [ -z "$changed" ]; then
    echo "  none    this branch changes no docs/agents/*.sh, so selftests.sh has nothing to ask"
  else
    # WHETHER A TOOL HAS A SELF-TEST IS NOT ASKED HERE. The first draft of
    # these lines decided it with selftests.sh's own idiom, a fixed-string
    # grep for the flag against the file -- and that spelled the flag out in
    # THIS file, so selftests.sh discovered check.sh as a self-testing tool,
    # ran the whole of it with the flag ignored, timed out at 180s and
    # reported `0 ok, 0 failed, 1 unrun` forever, in a gate this seat does not
    # own. Two faults in one line. A duplicated discovery rule is a second
    # definition of the population (L-A143); and that gate reads comments, so
    # writing the specimen down is joining the population it defines -- L-A23
    # for a prohibition, here for a census, and the flag is therefore not
    # spelled anywhere in this file, including in this sentence.
    # So the gate is asked instead: it exits 2 and says so when no tool of
    # that name advertises the flag, which is the one authority on it.
    for f in $changed; do
      b=$(basename "$f")
      [ -f "$f" ] || { printf '  gone    %-16s deleted by this branch\n' "$b"; continue; }
      out=$(cd cli && timeout 900 bash test/selftests.sh --only "$b" 2>&1); v=$?
      tally=$(sed -n 's/^selftests: //p' <<<"$out")
      case "$v" in
        0) if said "$out" 'unrun'; then
             # An unrun asserted nothing, which is could-not-look and not a
             # pass (L41). Printed as its own row rather than counted as ok.
             printf '  unrun   %-16s %s — its self-test did not finish, so nothing was asserted\n' "$b" "$tally"
           else
             printf '  ok      %-16s %s\n' "$b" "$tally"
           fi ;;
        2) printf '  none    %-16s the gate asserts nothing about it: %s\n' "$b" \
                  "$(grep -m1 'advertises' <<<"$out" | sed 's/^[[:space:]]*//')" ;;
        *) printf '  REFUSES %-16s %s\n' "$b" "$tally"
           grep -E '^[[:space:]]*FAIL' <<<"$out" | sed 's/^/    /'
           fail=1 ;;
      esac
    done
  fi
fi


# ---------------------------------------------------------------- 6
# Every command this repository's own documents print, against the scripts they
# name. Added 2026-11-08, from docs/backlog.md's own card: a seat copied a
# printed invocation out of a file header on 2026-11-02 and got 40 findings
# under a sentence claiming exit 0, because the printed line omitted a flag.
# Nothing could have noticed -- a command in a document is read by people and
# run by nothing. It found two on main the day it landed, one of them this
# register's own: an incident named a detector for its class that exits 2 and
# prints a usage header, so every seat that took its word ran nothing.
#
# WHOLE-TREE AND NOT THIS BRANCH'S DIFF, unlike check 5's selftests scope. A
# printed command goes stale when the SCRIPT moves, which is a change in a file
# the document does not mention -- scoping the scan to the diff would have
# missed both of the two it found. It reads tracked text and runs in under a
# second, so there is nothing to buy by narrowing it.
echo
echo "6. every printed command, against the script it names"
if ! command -v python3 >/dev/null 2>&1; then
  echo "  could not look: no python3 on this box, so nothing read the printed commands (L41)"
elif [ ! -f tools/check-printed-commands.py ]; then
  echo "  could not look: tools/check-printed-commands.py is not in this checkout (L41)"
else
  if out=$(python3 tools/check-printed-commands.py 2>&1); then
    echo "  ok      $(sed -n 's/^printed-commands: //p' <<<"$out")"
  else
    echo "  REFUSES printed-commands:"
    sed 's/^/    /' <<<"$out"
    fail=1
  fi
fi

echo
[ $fail -eq 0 ] && echo "ok" || echo "something above refuses — fix it before the pull request opens"
exit $fail
