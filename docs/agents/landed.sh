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
set -o pipefail
if ! rows=$(gh pr list --state closed --limit 300 \
      --json number,state,mergedAt,closedAt,headRefName,title \
    | jq -r --arg since "$since" '
        [ .[]
          | {n: .number,
             outcome: (if .mergedAt then "merged" else "closed" end),
             at: (.mergedAt // .closedAt),
             ref: .headRefName, title: .title}
          | select(.at != null and .at >= $since) ]
        | sort_by(.at)
        | .[] | [.n, .outcome, .at, .ref, .title] | @tsv')
then
  echo "the query failed, so this run has no answer — refusing rather than printing a zero" >&2
  exit 2
fi

merged=(); closed=(); first=""; last=""
while IFS=$'\t' read -r n outcome at ref title; do
  [ -z "${n:-}" ] && continue
  printf '#%-5s %-6s %s  %-44s %s\n' "$n" "$outcome" "${at:11}" "${ref:0:44}" "${title:0:40}"
  if [ "$outcome" = merged ]; then
    merged+=("$n"); [ -z "$first" ] && first=$at; last=$at
  else
    closed+=("$n")
  fi
done <<<"$rows"

open_now=$(gh pr list --state open --limit 300 --json number --jq 'length')
span=0
if [ -n "$first" ]; then
  span=$(( $(date -u -d "$last" +%s) - $(date -u -d "$first" +%s) ))
fi

printf '\n%d merged, %d closed unmerged, %d open now\n' \
  "${#merged[@]}" "${#closed[@]}" "$open_now"
if [ "${#merged[@]}" -gt 1 ]; then
  printf 'the merges span %02d:%02d:%02d, %s to %s — a span, not a latency\n' \
    $((span/3600)) $((span%3600/60)) $((span%60)) "${first:11}" "${last:11}"
elif [ "${#merged[@]}" -eq 0 ]; then
  printf 'nothing merged in this window; say the window when you say that\n'
fi

# The paste block. A claim about the queue leaves this seat as these keys and
# not as a sentence: every list is labelled with the outcome it is a list of,
# so no reader has to guess which set a number belongs to.
json_list() { local a=("$@"); printf '['; local i; for i in "${!a[@]}"; do
  [ "$i" -gt 0 ] && printf ','; printf '%s' "${a[$i]}"; done; printf ']'; }
printf '\ndata, for the message that carries this (paste it; do not retype it):\n'
printf '{"measured_at":"%s","main":"%s","window_from":"%s","merged":%s,"closed_unmerged":%s,"merged_span_seconds":%d,"merged_first":"%s","merged_last":"%s","open_now":%s}\n' \
  "$now" "$(git rev-parse --short origin/main)" "$since" \
  "$(json_list "${merged[@]}")" "$(json_list "${closed[@]}")" \
  "$span" "${first:-}" "${last:-}" "$open_now"
