#!/usr/bin/env bash
# What the wake did not carry of the brief (L35, incident 15).
#
#   bash docs/agents/brief.sh          compare the newest brief.sent against the brief itself
#
# The daily brief is this seat's first input: the learning loop's tick opens
# by observing the brief, so an input this seat cannot verify is not an
# observation. On 2026-10-24 the wake that carried it said "this wake carries
# 1264 of 1835 characters of the message and stops here", and the 571
# characters it stopped before were the four asks only the owner can clear,
# the capacity count, the money balance and the board's address — the whole
# tail, cut by position because the cut was made by character count and the
# brief puts its summary first and its asks last. The footer then told the
# reader to find the rest "in your inbox on the board", where a brief has
# never been: it is a `brief.sent` event whose stored payload is the
# already-cut copy.
#
# That is repaired in HQ's runtime as of 413e52c, deployed 2026-10-24T01:27Z:
# the brief composes as nine named sections, the wake drops whole sections
# against `BRIEF_DROP_ORDER` lowest-precedence first, and the marker names the
# dropped sections and gives the address of `GET /api/brief`, which composes
# and returns and sends nothing. So this script's job changed from showing a
# loss to checking which cut is live, and it says which marker it found.
#
# Two things it is careful about, both of them lessons this file has paid for.
#
# It never reports a reading when it could not take one (L41). `GET
# /api/events` honours `since_hours` only — `limit` is accepted and ignored,
# and the store caps every answer at the newest 200 rows — so on a busy night
# the window is under an hour and a once-a-day event is simply not in it. The
# first version asked for `?limit=400`, believed it, and printed "nothing to
# compare" on a run that had seen nothing at all. Now a run that cannot see
# the brief says BLIND, prints the window it actually searched, and exits 3.
#
# And it writes under its own directory, never a bare name in /tmp, because
# the host still shares one temporary directory between every run on the box
# and this seat has already published another company's text as its own pull
# request body that way (incident 5, fired again 2026-10-24T01:29Z).
#
# Needs BOARD_API_URL and BOARD_RUNTIME_TOKEN. Reads only.
set -uo pipefail

: "${BOARD_API_URL:?BOARD_API_URL is not set; this runs where the board is reachable}"
: "${BOARD_RUNTIME_TOKEN:?BOARD_RUNTIME_TOKEN is not set}"

auth=(-H "Authorization: Bearer $BOARD_RUNTIME_TOKEN")
printf 'BOARD_API_URL present: %s length: %s\n' "${BOARD_API_URL:+yes}" "${#BOARD_API_URL}"
printf 'BOARD_RUNTIME_TOKEN present: %s length: %s\n\n' "${BOARD_RUNTIME_TOKEN:+yes}" "${#BOARD_RUNTIME_TOKEN}"

work=$(mktemp -d); trap 'rm -rf "$work"' EXIT
curl -sS "${auth[@]}" "$BOARD_API_URL/api/brief"                 > "$work/live.json"   || exit 2
curl -sS "${auth[@]}" "$BOARD_API_URL/api/events?since_hours=24" > "$work/events.json" || exit 2

python3 - "$work" <<'PY'
import json, os, re, sys

work = sys.argv[1]
live_doc = json.load(open(os.path.join(work, 'live.json')))
live     = live_doc.get('text', '')
sections = live_doc.get('sections') or []
evs      = json.load(open(os.path.join(work, 'events.json')))['events']
sent     = [e for e in evs if e['type'] == 'brief.sent']

# The live brief first, because this route always answers and the event feed
# does not. Anything printed under here is true even on a blind run.
print(f"live GET /api/brief  {len(live)} chars"
      + (f", {len(sections)} named sections: " + ", ".join(sections) if sections else
         ", and it returns no section list: this host predates 413e52c"))
# One layer down from the wake: each composed field is clipped to a width.
# A clip that ends in an ellipsis is honest and is reported as such; a long
# line that ends in neither punctuation nor an ellipsis is a candidate and is
# named as a candidate, because this script cannot tell a clipped phrase from
# a title that simply has no full stop, and a detector that overstates its
# coverage is worse than one that declares its edge (L35).
honest = [l for l in live.split('\n') if l.rstrip().endswith('\u2026')]
maybe  = [l for l in live.split('\n')
          if l.startswith('\u2022') and len(l) >= 120
          and not l.rstrip().endswith(('.', '!', '?', '\u2026'))]
print(f"  {len(honest)} composed line(s) end in an ellipsis, which is the clip helper saying so")
for l in honest:
    print('   | \u2026' + l[-44:])
print(f"  {len(maybe)} long line(s) end in neither punctuation nor an ellipsis (candidates only)")
for l in maybe:
    print('   ? \u2026' + l[-44:])

if not sent:
    print(f"\nBLIND: no brief.sent in the window this run could search."
          f"\n  the events route honours since_hours only and the store caps at 200 rows;"
          f"\n  it returned {len(evs)} events,"
          f" {evs[-1]['ts'][:19]}Z → {evs[0]['ts'][:19]}Z." if evs else
          "\nBLIND: the events route returned nothing at all.")
    print("  so this run does not know what the last wake carried, and says so"
          "\n  rather than reporting a clean reading (L41).")
    sys.exit(3)

e    = sent[0]
text = e['payload'].get('text', '')
i    = min([j for j in (text.find('[This wake carries'),) if j >= 0] or [-1])
head, foot = (text[:i], text[i:]) if i >= 0 else (text, '')
print(f"\nnewest brief.sent  {e['ts']}")
print(f"  stored payload   {len(text)} chars  (brief {len(head)} + marker {len(foot)})")

by_section = re.search(r"carries (\d+) of the brief's (\d+) sections", foot)
by_chars   = re.search(r'carries (\d+) of (\d+) characters', foot)
if by_section:
    url = re.search(r'whole of it is at (\S+?)[,\]]', foot)
    print(f"  the cut is BY SECTION: {by_section.group(1)} of {by_section.group(2)} delivered")
    # Three outcomes here and not two. The marker may name the dropped
    # sections, or carry no such phrase, or carry it in a shape this parser
    # misses — and the first version of this branch printed the same sentence
    # for the last two, so a parser defect was published as a fact about the
    # brief. It shipped with `\\.` for `\.` inside a quoted heredoc, where the
    # doubling buys nothing, and that pattern cannot match any marker ever
    # written; its only earlier run exited BLIND before reaching this line, so
    # no real positive had tested it (L42, L-X1).
    phrase = 'lowest precedence first:'
    names  = re.search(re.escape(phrase) + r' ([^.]+)\.', foot)
    if names:
        print(f"  dropped, by name: {names.group(1)}")
    elif phrase in foot:
        print(f"  dropped, by name: PARSE FAILED — the marker carries"
              f" '{phrase}' and this script could not read it; raw:")
        print('   | ' + foot[foot.find(phrase):][:160])
    else:
        print("  dropped, by name: the marker carries no"
              f" '{phrase}' phrase at all")
    print(f"  the marker's address: {url.group(1) if url else 'NONE — the pointer is a gesture again'}")
elif by_chars:
    print(f"  the cut is BY CHARACTER COUNT: {by_chars.group(1)} of {by_chars.group(2)} delivered")
    print("  this is incident 15's defect, live on this host: position is not importance")
else:
    print("  no truncation marker: the wake carried the whole brief")

stem = head.rstrip('\n')
if stem and live.startswith(stem):
    tail = live[len(stem):]
    print(f"\n  CUT: {len(tail)} characters the wake did not carry, recovered from GET /api/brief:")
    for line in tail.strip().split('\n'):
        if line.strip():
            print('   | ' + line)
elif stem and foot:
    print('\n  the live brief is no longer the one that was sent (it regenerates on read);')
    print('  what the wake carried cannot be diffed against it this run.')
PY
