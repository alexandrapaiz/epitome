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
      if taken "pull/$pr" "$path" "$rx" | grep -qxF "$id"; then
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
[ $fail -eq 0 ] && echo "ok" || echo "something above refuses — fix it before the pull request opens"
exit $fail
