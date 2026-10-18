#!/usr/bin/env bash
# The merge order, measured at the moment it is published (L24).
#
#   bash docs/agents/order.sh          immediately before you write the order down
#
# This seat has published a merge order by hand three times today, and the
# third one was wrong before it was sent: one of its two "mutually exclusive"
# pull requests had swallowed the other eight minutes earlier, and the clause
# that said so had been carried forward from a measurement taken ten minutes
# before it was typed. A hand-carried ordering is a fact about other people's
# branches, and other people's branches move while you write.
#
# So the order is generated, not typed, and every line prints the head it was
# measured at. A reader who can see the sha can tell in one glance whether the
# order still describes the queue; a seat whose branch is misdescribed can
# refute it with one `git rev-parse` instead of a paragraph.
#
# What it does: walks every open pull request oldest first, test-merging each
# one onto the running result in a throwaway worktree. The ones that apply
# clean, in that order, are a sequence a merger can perform with no judgement.
# Needs a full clone and gh.
set -uo pipefail
cd "$(git rev-parse --show-toplevel)"
BASE=${BASE:-origin/main}

git fetch -q origin main 'refs/pull/*/head:refs/remotes/pull/*' 2>/dev/null
printf 'measured %s against %s %s\n\n' "$(date -u +%FT%TZ)" "$BASE" "$(git rev-parse --short "$BASE")"

mapfile -t rows < <(gh pr list --state open --limit 200 \
  --json number,isDraft,headRefOid,title --jq \
  '.[] | [.number, (if .isDraft then "draft" else "ready" end), .headRefOid[0:8], .title] | @tsv' \
  | sort -n)

work=$(mktemp -d); trap 'git worktree remove -f "$work" >/dev/null 2>&1; rm -rf "$work"' EXIT
git worktree add -q --detach "$work" "$BASE" || { echo "no worktree"; exit 2; }

seq_nums=(); blocked=()
for row in "${rows[@]}"; do
  IFS=$'\t' read -r n draft sha title <<<"$row"
  git -C "$work" merge-base --is-ancestor "pull/$n" HEAD >/dev/null 2>&1 && continue
  if git -C "$work" merge --no-edit -q "pull/$n" >/dev/null 2>&1; then
    seq_nums+=("$n")
    printf '%-6s %-5s %-9s takes   %s\n' "#$n" "$draft" "$sha" "${title:0:58}"
  else
    files=$(git -C "$work" diff --name-only --diff-filter=U 2>/dev/null | tr '\n' ' ')
    git -C "$work" merge --abort >/dev/null 2>&1
    blocked+=("$n")
    printf '%-6s %-5s %-9s blocked %s\n' "#$n" "$draft" "$sha" "${files:-conflicts}"
  fi
done

printf '\nthe sequence, in order: '
printf '#%s ' "${seq_nums[@]}"; printf '\n%d of %d land in one pass; %d need a hand\n' \
  "${#seq_nums[@]}" "$((${#seq_nums[@]} + ${#blocked[@]}))" "${#blocked[@]}"
printf 'drafts in the sequence cannot be merged by anyone but their author — clear the flag first\n'
