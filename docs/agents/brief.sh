#!/usr/bin/env bash
# What the wake did not carry of the brief (L35, incident 15).
#
#   bash docs/agents/brief.sh          compare the newest brief.sent against the brief itself
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

: "${BOARD_API_URL:?BOARD_API_URL is not set; this runs where the board is reachable}"
: "${BOARD_RUNTIME_TOKEN:?BOARD_RUNTIME_TOKEN is not set}"

auth=(-H "Authorization: Bearer $BOARD_RUNTIME_TOKEN")
printf 'BOARD_API_URL present: %s length: %s\n' "${BOARD_API_URL:+yes}" "${#BOARD_API_URL}"
printf 'BOARD_RUNTIME_TOKEN present: %s length: %s\n\n' "${BOARD_RUNTIME_TOKEN:+yes}" "${#BOARD_RUNTIME_TOKEN}"

curl -sS "${auth[@]}" "$BOARD_API_URL/api/brief"              > /tmp/brief-live.json || exit 1
curl -sS "${auth[@]}" "$BOARD_API_URL/api/events?limit=400"   > /tmp/brief-events.json || exit 1

python3 - "$@" <<'PY'
import json, re, sys

live = json.load(open('/tmp/brief-live.json')).get('text', '')
evs  = json.load(open('/tmp/brief-events.json'))['events']
sent = [e for e in evs if e['type'] == 'brief.sent']

if not sent:
    print('no brief.sent in the window the events route returned; nothing to compare')
    sys.exit(0)

e    = sent[0]
text = e['payload'].get('text', '')
i    = text.find('[This wake carries')
head, foot = (text[:i], text[i:]) if i >= 0 else (text, '')
m    = re.search(r'carries (\d+) of (\d+)', foot)

print(f"newest brief.sent  {e['ts']}")
print(f"  stored payload   {len(text)} chars  (brief {len(head)} + truncation footer {len(foot)})")
print(f"  footer claims    {m.group(1)} of {m.group(2)} delivered" if m else "  no truncation footer")
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
