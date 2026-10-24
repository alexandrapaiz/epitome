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

git fetch -q origin main 'refs/pull/*/head:refs/remotes/pull/*' 2>/dev/null
printf 'measured %s against %s %s\n\n' "$(date -u +%FT%TZ)" "$BASE" "$(git rev-parse --short "$BASE")"

mapfile -t rows < <(gh pr list --state open --limit 200 \
  --json number,isDraft,headRefOid,title --jq \
  '.[] | [.number, (if .isDraft then "draft" else "ready" end), .headRefOid[0:8], .title] | @tsv' \
  | sort -n)

work=$(mktemp -d); trap 'git worktree remove -f "$work" >/dev/null 2>&1; rm -rf "$work"' EXIT
git worktree add -q --detach "$work" "$BASE" || { echo "no worktree"; exit 2; }

seq_nums=(); blocked=(); covered=(); all_nums=()
for row in "${rows[@]}"; do
  IFS=$'\t' read -r n draft sha title <<<"$row"
  all_nums+=("$n")
  # Already contained by something merged above it — say so rather than
  # skipping the line. A silently dropped row makes the printed count differ
  # from `gh pr list` with nothing to explain it, and a reader cannot tell a
  # covered pull request from one the instrument never saw. On 2026-10-18 this
  # dropped #190 — out of draft, green, and the one its author had just asked a
  # merger to take — because #186, a draft of the same seat, contains it.
  if git -C "$work" merge-base --is-ancestor "pull/$n" HEAD >/dev/null 2>&1; then
    covered+=("$n")
    by=$(for m in "${seq_nums[@]}"; do
           git -C "$work" merge-base --is-ancestor "pull/$n" "pull/$m" >/dev/null 2>&1 \
             && { echo "#$m"; break; }
         done)
    printf '%-6s %-5s %-9s covered already in %s\n' "#$n" "$draft" "$sha" "${by:-the sequence above}"
    continue
  fi
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
printf '#%s ' "${seq_nums[@]}"; printf '\n%d of %d land in one pass; %d need a hand; %d already covered by one above\n' \
  "${#seq_nums[@]}" "$((${#seq_nums[@]} + ${#blocked[@]} + ${#covered[@]}))" \
  "${#blocked[@]}" "${#covered[@]}"
printf 'drafts in the sequence cannot be merged by anyone but their author — clear the flag first\n'

# The chains, which the walk above cannot see. `covered` only fires when
# something ALREADY MERGED into the running composite contains a later row,
# so it catches a chain written oldest-last and misses the one every seat
# here actually writes: today's branch started from yesterday's, so the
# container is the NEWER number and the walk meets the contained one first,
# merges it clean, and prints it as an independent decision. On 2026-10-24
# this script reported "0 already covered by one above" for a queue in which
# #250 contained #242 and #246 and #251 contained #243 and #249 — four of
# nine rows were links, and the count the owner reads was high by four.
# That is the exact figure this seat's charter requires it to report, so the
# instrument answering 0 for it was the whole defect (L34's companion case).
# Containment is symmetric to look up and cheap: ask it both ways, once.
printf '\n'
chain_links=0
for n in "${all_nums[@]}"; do
  inside=$(for m in "${all_nums[@]}"; do
             [ "$m" = "$n" ] && continue
             git -C "$work" merge-base --is-ancestor "pull/$n" "pull/$m" >/dev/null 2>&1 \
               && { echo "$m"; break; }
           done)
  if [ -n "$inside" ]; then
    chain_links=$((chain_links + 1))
    printf '#%-5s is already contained in #%s — merging #%s merges it too\n' "$n" "$inside" "$inside"
  fi
done
printf '%d open; %d of them are links in a chain; %d independent decisions for a merger\n' \
  "${#all_nums[@]}" "$chain_links" "$(( ${#all_nums[@]} - chain_links ))"

# The set, generated, so the prose that cites it never re-derives it (L33).
# `merge_sequence` and not `merged`: a merge sequence is by construction a list
# of things that have not merged, so a reader who confuses the two is reading a
# claim about merges off a list that can only refute one. `landed.sh` owns
# `merged`; this owns the order, the blocked, and the links.
printf '\ndata, for the message that carries this (paste it; do not retype it):\n'
json_list() { local first=1 n; printf '['; for n in "$@"; do [ $first = 1 ] || printf ','; printf '%s' "$n"; first=0; done; printf ']'; }
printf '{"measured_at":"%s","main":"%s","merge_sequence":' "$(date -u +%FT%TZ)" "$(git -C "$work" rev-parse --short origin/main)"
json_list "${seq_nums[@]}"
printf ',"blocked":'; json_list "${blocked[@]}"
printf ',"heads":{'
first=1
for n in "${all_nums[@]}"; do
  [ $first = 1 ] || printf ','
  printf '"%s":"%s"' "$n" "$(git -C "$work" rev-parse --short=8 "pull/$n" 2>/dev/null)"
  first=0
done
printf '},"open_now":%d,"chain_links":%d,"independent_decisions":%d}\n' \
  "${#all_nums[@]}" "$chain_links" "$(( ${#all_nums[@]} - chain_links ))"
