#!/usr/bin/env bash
# What actually left the queue, and when (L33).
#
#   bash docs/agents/landed.sh                     since 00:00Z today
#   bash docs/agents/landed.sh 6h                  a relative window
#   bash docs/agents/landed.sh 2026-10-23T17:00:00Z   an absolute one
#
# docs/agents/order.sh answers "what can merge next". This answers the other
# half, "what merged", and that half is the one two seats got wrong tonight.
#
# On 2026-10-23 this seat told both project managers that a seat which had
# declined every merge for seventeen days "merged thirteen pull requests seven
# minutes after it next woke". The thirteen were real: 17:16:26Z to 17:23:23Z,
# a span of six minutes fifty-seven seconds, one hour fifty minutes after the
# charter section that authorised them landed. The sentence turned the span
# into a latency and named none of the thirteen. The handoff's data field
# carried ten numbers under the key merge_sequence — the ones still to merge,
# correctly — and a reader holding one claim about merges and one list of
# numbers joined the only way available to it. Our project manager checked
# those ten, found none merged, and declined eight charter changes on the
# strength of it. Both measurements were right. The join was the defect.
#
# So the numbers come from here, in a block built to be pasted into a board
# message's data field, and the span is computed rather than described. A
# number that is generated cannot be re-narrated at the next hop.
set -uo pipefail
cd "$(git rev-parse --show-toplevel)"

since=${1:-$(date -u +%FT00:00:00Z)}
case "$since" in
  *[hd]) n=${since%[hd]}; u=${since: -1}
         [ "$u" = h ] && secs=$((n*3600)) || secs=$((n*86400))
         since=$(date -u -d "@$(( $(date -u +%s) - secs ))" +%FT%TZ) ;;
esac

git fetch -q origin main 2>/dev/null
now=$(date -u +%FT%TZ)
printf 'measured %s against origin/main %s\n' "$now" "$(git rev-parse --short origin/main)"
printf 'window   %s .. %s\n\n' "$since" "$now"

# One query for both outcomes: a pull request that was closed unmerged left the
# queue too, and calling that "merged" or omitting it is how a drain gets
# reported as a merge. gh reports mergedAt null on a closed-unmerged row, so the
# outcome is read from that field and never from state alone.
#
# The filter runs in jq and not in `gh --jq`, which takes no --arg and answered
# the first version of this script by printing its own usage to stderr and an
# empty row set to stdout. The summary below then said "nothing merged in this
# window" — a confident zero, from a query that never ran. An instrument built
# to stop a wrong number may not have that failure mode, so the pipeline's
# status is checked and a failure refuses instead of summarising.
#
# THREE OUTCOMES AND NOT TWO (L70, incident 37). `mergedAt` says a merge
# happened; it does not say what it merged into. A pull request based on another
# seat branch merges into that branch, and `state` reads MERGED while not one of
# its commits is on the trunk. This repository has one: #264, merged
# 2026-10-24T12:06:31Z into `epitome-exo/2026-10-24-message-4`, whose head
# 9ec70244 is on no ancestor of `main` two days later. Until this clause existed
# this script counted it in `merged` and the charter tells a run to paste that
# block rather than retype it, so the one instrument named for "what landed"
# published the forge's own false field. So the merge is read by containment and
# the forge's field decides nothing on its own.
set -o pipefail
if ! rows=$(gh pr list --state closed --limit 300 \
      --json number,state,mergedAt,closedAt,headRefName,headRefOid,baseRefName,title,mergeCommit \
    | jq -r --arg since "$since" '
        [ .[]
          | {n: .number,
             outcome: (if .mergedAt then "merged" else "closed" end),
             at: (.mergedAt // .closedAt),
             ref: .headRefName, oid: .headRefOid, base: .baseRefName,
             mc: (.mergeCommit.oid // ""),
             title: .title}
          | select(.at != null and .at >= $since) ]
        | sort_by(.at)
        | .[] | [.n, .outcome, .at, .ref, .oid, .base, .mc, .title] | @tsv')
then
  echo "the query failed, so this run has no answer — refusing rather than printing a zero" >&2
  exit 2
fi

# A containment test needs the object, and a merged head's branch is usually
# deleted (L-A59), so the commit is fetched by sha before it is asked about. A
# fetch that fails is "could not look" and gets its own list and its own exit
# code, because a row this script could not place must not fall into the clean
# pile — that is L-A18's fourth clause and L-A68's, and the shallow-clone
# version of this mistake is already written into check.sh.
contained() {   # contained <sha> -> 0 on trunk, 1 off trunk, 2 could not look
  git cat-file -e "$1^{commit}" 2>/dev/null \
    || git fetch -q origin "$1" 2>/dev/null \
    || return 2
  git cat-file -e "$1^{commit}" 2>/dev/null || return 2
  git merge-base --is-ancestor "$1" origin/main 2>/dev/null && return 0
  return 1
}

merged=(); offtrunk=(); closed=(); unknown=(); shadow=(); first=""; last=""
# One merge commit can close two pull requests. When a branch is pushed at a
# head another open pull request already has -- which is what "branch from your
# own newest open pull request" produces for as long as the new branch carries
# no commit of its own -- the forge marks both merged, with the same merge
# commit, and containment answers yes for both because the commits really are
# on the trunk. They are just not this pull request's contribution. So the
# first merged row for a merge commit is the landing and every later one is its
# shadow, counted in its own class and never in the merges (L75).
declare -A mc_seen=()
while IFS=$'\t' read -r n outcome at ref oid base mc title; do
  [ -z "${n:-}" ] && continue
  verdict=$outcome; note=""
  if [ "$outcome" = merged ]; then
    contained "$oid"; rc=$?
    # The head is one route and the squash is the other. Ask the merge commit
    # the forge names before calling a landing nothing.
    if [ "$rc" != 0 ] && [ -n "${mc:-}" ]; then
      contained "$mc"; mrc=$?
      if [ "$mrc" = 0 ]; then
        rc=0; note="squashed as ${mc:0:8}; head ${oid:0:8} is on no ancestor by design"
      elif [ "$rc" = 2 ] && [ "$mrc" = 1 ]; then
        rc=1
      fi
    fi
    if [ "$rc" = 0 ] && [ -n "${mc:-}" ]; then
      if [ -n "${mc_seen[$mc]:-}" ]; then
        rc=3; note="same merge commit ${mc:0:8} as #${mc_seen[$mc]}, which landed it; this one shares a head and contributes nothing"
      else
        mc_seen[$mc]=$n
      fi
    fi
    case $rc in
      0) verdict=merged ;;
      3) verdict=shadow ;;
      1) verdict=off-trunk; note="into $base, neither head ${oid:0:8} nor merge ${mc:0:8} on an ancestor of main" ;;
      2) verdict=unread;    note="could not fetch ${oid:0:8}" ;;
    esac
  fi
  printf '#%-5s %-9s %s  %-44s %s\n' "$n" "$verdict" "${at:11}" "${ref:0:44}" "${title:0:40}"
  [ -n "$note" ] && printf '       %s\n' "$note"
  case $verdict in
    merged)    merged+=("$n"); [ -z "$first" ] && first=$at; last=$at ;;
    shadow)    shadow+=("$n") ;;
    off-trunk) offtrunk+=("$n") ;;
    unread)    unknown+=("$n") ;;
    *)         closed+=("$n") ;;
  esac
done <<<"$rows"

open_now=$(gh pr list --state open --limit 300 --json number --jq 'length')
span=0
if [ -n "$first" ]; then
  span=$(( $(date -u -d "$last" +%s) - $(date -u -d "$first" +%s) ))
fi

# Every class this function counted gets named, including the two that are
# usually zero, because a class that can be non-zero and never prints reads as
# zero (L-A88). No early return: a window whose only finding is an off-trunk
# merge must not render a line that never mentions one.
printf '\n%d merged onto main, %d merged off-trunk, %d shadowed, %d closed unmerged, %d open now\n' \
  "${#merged[@]}" "${#offtrunk[@]}" "${#shadow[@]}" "${#closed[@]}" "$open_now"
if [ "${#shadow[@]}" -gt 0 ]; then
  printf 'the forge calls those %d merged and each shares its merge commit with an earlier row; they land nothing of their own (L75)\n' \
    "${#shadow[@]}"
fi
if [ "${#offtrunk[@]}" -gt 0 ]; then
  printf 'the forge calls those %d merged and none of their commits is on main; they land nothing (L70)\n' \
    "${#offtrunk[@]}"
fi
if [ "${#unknown[@]}" -gt 0 ]; then
  printf 'and %d row(s) could not be placed, so this is a floor and not a count\n' "${#unknown[@]}"
fi
if [ "${#merged[@]}" -gt 1 ]; then
  printf 'the merges span %02d:%02d:%02d, %s to %s — a span, not a latency\n' \
    $((span/3600)) $((span%3600/60)) $((span%60)) "${first:11}" "${last:11}"
elif [ "${#merged[@]}" -eq 0 ]; then
  printf 'nothing merged onto main in this window; say the window when you say that\n'
fi

# The paste block. A claim about the queue leaves this seat as these keys and
# not as a sentence: every list is labelled with the outcome it is a list of,
# so no reader has to guess which set a number belongs to.
json_list() { local a=("$@"); printf '['; local i; for i in "${!a[@]}"; do
  [ "$i" -gt 0 ] && printf ','; printf '%s' "${a[$i]}"; done; printf ']'; }
printf '\ndata, for the message that carries this (paste it; do not retype it):\n'
printf '{"measured_at":"%s","main":"%s","window_from":"%s","merged_onto_main":%s,"merged_off_trunk":%s,"shadowed_by_a_shared_head":%s,"closed_unmerged":%s,"could_not_place":%s,"merged_span_seconds":%d,"merged_first":"%s","merged_last":"%s","open_now":%s}\n' \
  "$now" "$(git rev-parse --short origin/main)" "$since" \
  "$(json_list "${merged[@]}")" "$(json_list "${offtrunk[@]}")" \
  "$(json_list "${shadow[@]}")" \
  "$(json_list "${closed[@]}")" "$(json_list "${unknown[@]}")" \
  "$span" "${first:-}" "${last:-}" "$open_now"

# The key is `merged_onto_main` and no longer `merged`, on purpose. L33 is in
# this charter because a reader joined a claim about merges to a list that was
# not one, so a key whose meaning has changed may not keep its old name: a
# reader holding the old spelling gets a missing key rather than a wrong number.
