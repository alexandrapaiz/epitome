#!/usr/bin/env bash
# Did the host record what this seat's runs actually shipped?
#
# WHY THIS EXISTS. A run's footer in /srv/asc/state/.epito/logs carries four
# fields — exit, pr, session, turns. Three are read out of named fields of the
# executor's result object. The fourth, `pr=`, is read by matching a URL in the
# executor's stdout, and under `--output-format json` that stdout is one result
# object printed at exit, so the only place a pull request URL can appear is
# inside the agent's own closing prose. `pr=` therefore answers "did the
# closing summary paste a full URL", which is a question about writing style,
# and it is structurally `-` for every run that was refused or cut off, because
# those write no closing prose at all. The same variable is what the host sends
# the board as `pr_url` and as the sentence "no pull request."
#
# The act leaves a better record than the narrator does: a pull request on this
# repository whose head branch carries this seat's prefix, opened inside the
# run's own window. That is what this script reads, and it reports the
# disagreement rather than the count, because the count is already in loop.md.
#
# Three answers and not two (L41): 0 agree, 1 a disagreement to report,
# 2 could not look. A missing log directory is the third and never the first.
set -uo pipefail

D=${1:-$(date -u +%F)}
SEAT=${2:-epitome-exo}
REPO=${3:-alexandrapaiz/epitome}
LOGS=${EPITO_LOGS:-/srv/asc/state/.epito/logs}

[ -d "$LOGS/$SEAT" ] || { echo "could not look: no $LOGS/$SEAT (not on the host)"; exit 2; }
command -v gh >/dev/null || { echo "could not look: no gh on PATH"; exit 2; }

prs=$(gh pr list --repo "$REPO" --state all --limit 100 \
        --json number,createdAt,headRefName \
        --jq ".[] | select(.headRefName | startswith(\"$SEAT/\")) | \"\(.createdAt)\t\(.number)\"" 2>/dev/null) \
  || { echo "could not look: gh refused $REPO"; exit 2; }

logs=$(ls "$LOGS/$SEAT/$D"*.log 2>/dev/null) || true
[ -n "$logs" ] && [ -n "$prs" ] || { echo "could not look: no runs on $D, or no branches named $SEAT/"; exit 2; }

echo "shipped.sh: $SEAT on $REPO, $D, read $(date -u +%FT%TZ)"
printf '%-22s %-7s %-6s %-9s %-9s %s\n' RUN TURNS EXIT 'FOOTER' 'ACTUAL' VERDICT

rows=""; disagree=0; total=0
for f in $logs; do
  base=$(basename "$f"); stamp=${base%%Z-*}
  # the filename is the start instant with - for : and .
  start=$(printf '%s' "$stamp" | sed -E 's/T([0-9]{2})-([0-9]{2})-([0-9]{2})-([0-9]{3})$/T\1:\2:\3.\4/')Z
  dur=$(grep -oE '"duration_ms":[0-9]+' "$f" | tail -1 | cut -d: -f2)
  grep -q '^# exit=' "$f" || continue          # still running: nothing to judge yet
  total=$((total+1))
  foot=$(grep -oE '^# exit=[^ ]+ pr=[^ ]+' "$f" | tail -1)
  exitc=$(printf '%s' "$foot" | sed -E 's/^# exit=([^ ]+).*/\1/')
  turns=$(grep -oE 'turns=[^ ]+$' "$f" | tail -1 | cut -d= -f2)
  footpr=$(printf '%s' "$foot" | sed -E 's/.*pr=//' | grep -oE '[0-9]+$' || true)
  # the window: start, plus the run's own duration, plus two minutes of skew
  endsec=$(( $(date -u -d "$start" +%s) + ${dur:-0}/1000 + 120 ))
  actual=$(printf '%s\n' "$prs" | while IFS=$'\t' read -r at n; do
             s=$(date -u -d "$at" +%s)
             [ "$s" -ge "$(date -u -d "$start" +%s)" ] && [ "$s" -le "$endsec" ] && echo "$n"
           done | tail -1)
  if [ "${footpr:-}" = "${actual:-}" ]; then v=agree; else v=DISAGREE; disagree=$((disagree+1)); fi
  printf '%-22s %-7s %-6s %-9s %-9s %s\n' "${stamp#*T}" "$turns" "$exitc" "${footpr:--}" "${actual:--}" "$v"
  rows="$rows{\"run\":\"$start\",\"turns\":\"$turns\",\"exit\":\"$exitc\",\"footer_pr\":\"${footpr:--}\",\"actual_pr\":\"${actual:--}\",\"verdict\":\"$v\"},"
done

[ "$total" -gt 0 ] || { echo "could not look: no finished runs on $D"; exit 2; }

echo
echo '```data'
echo "{\"instrument\":\"docs/agents/shipped.sh\",\"seat\":\"$SEAT\",\"repo\":\"$REPO\",\"date\":\"$D\","
echo " \"read_at\":\"$(date -u +%FT%TZ)\",\"finished_runs\":$total,\"footer_disagreed\":$disagree,"
echo " \"runs\":[${rows%,}]}"
echo '```'
echo
echo "$disagree of $total finished runs: the footer and the repository disagree."
[ "$disagree" -eq 0 ] && exit 0 || exit 1
