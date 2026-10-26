#!/usr/bin/env bash
# What the wake did not carry of the brief (L35, incident 15).
#
#   bash docs/agents/brief.sh          compare the newest brief.sent against the brief itself
#   bash docs/agents/brief.sh --self-test  fire all four answers on built input
#
# The daily brief is this seat's first input: the learning loop's tick opens
# by observing what the brief says. On 2026-10-24 the wake that carried it
# said "this wake carries 1264 of 1835 characters of the message and stops
# here", and the 571 characters it stopped before were the four asks only the
# owner can clear, the capacity count, the money balance and the board's
# address — the whole tail, cut by position because the cut was made by
# character count and the brief puts its summary first and its asks last.
#
# The footer told the reader to find the rest "in your inbox on the board".
# There is no such message: the brief is a `brief.sent` event, its stored
# payload is the already-cut copy, and the only surface holding the whole of
# it is GET /api/brief, which the footer does not name. So a reader who obeys
# the footer finds nothing and concludes the tail is gone.
#
# This script is the standing answer: it prints what was cut, from the route
# that has it. It does not repair the truncation — the brief and the bus are
# HQ's (pm standard §15) — it makes the loss visible on the day it happens,
# which is what L-X1 means by a detector.
#
# Needs BOARD_API_URL and BOARD_RUNTIME_TOKEN. Reads only.
set -uo pipefail

if [ "${1:-}" = "--self-test" ]; then
  # L42: a branch that has never run is not a detector. Each of the four
  # answers below is built here and asserted, so the one that cost this
  # register three rows — not-yet-due printed as nothing — cannot ship unfired.
  d=$(mktemp -d); ok=1
  printf '{"text":"x"}' > "$d/live.json"
  printf '{"events":[]}' > "$d/none.json"
  printf '{"events":[{"type":"brief.sent","ts":"%s","payload":{"text":"x"}}]}' \
    "$(date -u +%FT%H:%M:%S+00:00)" > "$d/one.json"
  fire() { # name expected-exit expected-word events schedule
    out=$(BRIEF_FIXTURES=1 BRIEF_LIVE="$d/live.json" BRIEF_EVENTS="$4" \
          BRIEF_SCHEDULE="$5" BOARD_API_URL=x BOARD_RUNTIME_TOKEN=x \
          bash "$0" 2>&1); got=$?
    if [ "$got" = "$2" ] && grep -q "$3" <<<"$out"; then
      printf '  %-14s exit %s, says %-14s ok\n' "$1" "$got" "$3"
    else
      printf '  %-14s exit %s (wanted %s), said: %s\n' "$1" "$got" "$2" "$(printf '%s' "$out" | head -1)"; ok=0
    fi
  }
  # 23:59 UTC is a schedule no read before midnight can have reached, and
  # 00:00 UTC is one every read has.
  fire not-yet-due    1 "NOT YET DUE"    "$d/none.json" "OnCalendar=*-*-* 23:59:00 UTC"
  fire absent-and-due 3 "ABSENT AND DUE" "$d/none.json" "OnCalendar=*-*-* 00:00:00 UTC"
  fire could-not-look 2 "COULD NOT LOOK" "$d/none.json" ""
  fire present        0 "newest brief"   "$d/one.json"  "OnCalendar=*-*-* 12:00:00 UTC"
  rm -rf "$d"
  [ "$ok" = 1 ] && { echo "all four answers fired"; exit 0; } || { echo "a branch did not fire"; exit 1; }
fi

: "${BOARD_API_URL:?BOARD_API_URL is not set; this runs where the board is reachable}"
: "${BOARD_RUNTIME_TOKEN:?BOARD_RUNTIME_TOKEN is not set}"

auth=(-H "Authorization: Bearer $BOARD_RUNTIME_TOKEN")
printf 'BOARD_API_URL present: %s length: %s\n' "${BOARD_API_URL:+yes}" "${#BOARD_API_URL}"
printf 'BOARD_RUNTIME_TOKEN present: %s length: %s\n\n' "${BOARD_RUNTIME_TOKEN:+yes}" "${#BOARD_RUNTIME_TOKEN}"

LIVE=${BRIEF_LIVE:-/tmp/brief-live.json}
EVENTS=${BRIEF_EVENTS:-/tmp/brief-events.json}
export LIVE EVENTS
if [ "${BRIEF_FIXTURES:-0}" != 1 ]; then
  curl -sS "${auth[@]}" "$BOARD_API_URL/api/brief"            > "$LIVE"   || exit 1
  curl -sS "${auth[@]}" "$BOARD_API_URL/api/events?limit=400" > "$EVENTS" || exit 1
fi

# The brief's own clock, so an absence can be told from a lead time (L60). The
# timer is the authority and is readable unprivileged; the events history is
# the fallback for a box where it is not; neither is could-not-look.
: "${BRIEF_SCHEDULE=$(systemctl show asc-brief.timer -p TimersCalendar 2>/dev/null \
                       | grep -oE 'OnCalendar=[^;]*' | head -1)}"
export BRIEF_SCHEDULE

python3 - "$@" <<'PY'
import json, os, re, sys
from datetime import datetime, timezone

live = json.load(open(os.environ['LIVE'])).get('text', '')
evs  = json.load(open(os.environ['EVENTS']))['events']
sent = [e for e in evs if e['type'] == 'brief.sent']

# Present, not-yet-due, due-and-absent, could-not-look: four answers, because
# printing nothing for the third is what made three loop rows report a missing
# input for a day that had not reached the input's own hour (L60, L41, L-A80).
def brief_hour():
    """(hour, minute, source) the brief is due at in UTC, or None."""
    m = re.search(r'(\d{1,2}):(\d{2})(?::\d{2})?\s*UTC', os.environ.get('BRIEF_SCHEDULE', ''))
    if m:
        return int(m.group(1)), int(m.group(2)), 'asc-brief.timer'
    past = [e for e in evs if e['type'] == 'brief.sent']
    if past:
        t = datetime.fromisoformat(past[0]['ts'])
        return t.hour, t.minute, f"the newest brief.sent on record, {past[0]['ts']}"
    return None

if not sent:
    due = brief_hour()
    if due is None:
        print('COULD NOT LOOK: no brief.sent in the window and no schedule to compare it to')
        print('  asc-brief.timer is unreadable here and the events route carries no brief.sent')
        sys.exit(2)
    h, mi, src = due
    now = datetime.now(timezone.utc)
    today = now.replace(hour=h, minute=mi, second=0, microsecond=0)
    if now < today:
        print(f'NOT YET DUE: no brief.sent, and today\'s is not owed until '
              f'{today.strftime("%Y-%m-%dT%H:%M:%SZ")} ({src})')
        print(f'  read at {now.strftime("%Y-%m-%dT%H:%M:%SZ")}, '
              f'{int((today - now).total_seconds() // 60)} minutes early — this is not a finding')
        sys.exit(1)
    print(f'ABSENT AND DUE: no brief.sent in the window, and today\'s was owed at '
          f'{today.strftime("%Y-%m-%dT%H:%M:%SZ")} ({src})')
    print(f'  read at {now.strftime("%Y-%m-%dT%H:%M:%SZ")}, '
          f'{int((now - today).total_seconds() // 60)} minutes after its own clock — this is a finding')
    sys.exit(3)

e    = sent[0]
text = e['payload'].get('text', '')
i    = text.find('[This wake carries')
head, foot = (text[:i], text[i:]) if i >= 0 else (text, '')
# The footer has changed shape since this reader was written: it used to count
# characters ("carries 1264 of 1835 characters") and now counts sections
# ("carries 7 of the brief's 10 sections", then names the ones it dropped). A
# reader that recognises less than its input contains answers "no truncation
# footer" about a footer that is right there, which is refusal.js's original
# defect in a second file (L60 clause two).
m    = (re.search(r'carries (\d+) of (?:the brief.s )?(\d+) (characters|sections)', foot)
        or re.search(r'carries (\d+) of (\d+)', foot))
dropped = re.search(r'Not delivered[^:]*:\s*([^.\]]+)', foot)

print(f"newest brief.sent  {e['ts']}")
print(f"  stored payload   {len(text)} chars  (brief {len(head)} + truncation footer {len(foot)})")
if m:
    unit = m.group(3) if m.lastindex and m.lastindex >= 3 else 'characters'
    print(f"  footer claims    {m.group(1)} of {m.group(2)} {unit} delivered")
    if dropped:
        print(f"  footer says cut  {dropped.group(1).strip()}")
elif foot:
    print(f"  footer present   {len(foot)} chars, in a shape this reader does not count:")
    print('   | ' + foot.strip().split('\n')[0][:110])
else:
    print("  no truncation footer")
print(f"  live /api/brief  {len(live)} chars")

stem = head.rstrip('\n')
if stem and live.startswith(stem):
    tail = live[len(stem):]
    print(f"\n  CUT: {len(tail)} characters the wake did not carry, recovered from GET /api/brief:")
    for line in tail.strip().split('\n'):
        if line.strip():
            print('   | ' + line)
elif stem:
    print('\n  the live brief is no longer the one that was sent (it regenerates on read);')
    print('  what the wake carried cannot be diffed against it this run.')

# The other cut, one layer down: every field the brief composes is itself
# clipped to a width, mid-word, with no ellipsis to say so.
clipped = [l for l in live.split('\n')
           if l.startswith('•') and len(l) >= 120 and not l.rstrip().endswith(('.', '!', '?'))]
if clipped:
    print(f"\n  {len(clipped)} of the brief's own lines end mid-word at their field width:")
    for l in clipped:
        print('   | …' + l[-40:])
PY
