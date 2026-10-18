#!/usr/bin/env bash
# Two checks this seat failed by hand twice on 2026-10-18, so they stopped
# being paragraphs in a README and became a command (L21, L23).
#
#   bash docs/agents/check.sh          before every pull request this seat opens
#
# 1. Every charter patch still applies to today's main, alone and as a set.
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

echo "== charter patches apply to main =="
for f in docs/agents/patches/*.diff; do
  printf '%-62s ' "$(basename "$f")"
  if git apply --check "$f" 2>/dev/null; then echo applies; else echo REFUSES; fail=1; fi
done
printf '%-62s ' "the set, in sequence"
if git apply --check docs/agents/patches/*.diff 2>/dev/null; then echo applies; else echo REFUSES; fail=1; fi

echo
echo "== identifiers free across main and every open pull request =="
git fetch -q origin main 'refs/pull/*/head:refs/remotes/pull/*' 2>/dev/null
taken() {  # taken <ref> <path> <regex> -> one identifier per line
  git show "$1:$2" 2>/dev/null | sed -nE "s/$3/\1/p"
}
for spec in \
  'docs/agents/lessons.md|^## (L[0-9]+) .*$' \
  'docs/agents/incidents.md|^## (Incident [0-9]+) .*$' \
  'docs/decisions.md|^## (ADR-[0-9]+).*$'
do
  path=${spec%%|*}; rx=${spec#*|}
  mine=$(comm -13 <(taken origin/main "$path" "$rx" | sort -u) <(taken HEAD "$path" "$rx" | sort -u))
  [ -z "$mine" ] && continue
  for id in $(echo "$mine" | tr ' ' '~'); do
    id=${id//\~/ }
    clash=""
    for pr in $(gh pr list --state open --limit 100 --json number --jq '.[].number' 2>/dev/null); do
      git merge-base --is-ancestor "pull/$pr" HEAD 2>/dev/null && continue   # already mine
      if taken "pull/$pr" "$path" "$rx" | grep -qxF "$id"; then
        this=$(git show "HEAD:$path"      | grep -F "## $id " | head -1)
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
