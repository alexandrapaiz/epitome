#!/usr/bin/env bash
# What did my window hold while a limit was refusing me? (L78, incident 42.)
#
#   bash docs/agents/owed.sh                 this seat, today
#   bash docs/agents/owed.sh --seat pm       another seat of this product
#   bash docs/agents/owed.sh --days 2        a window
#   bash docs/agents/owed.sh --self-test     fire every verdict on built input
#
# WHY THIS EXISTS. The capacity retry works. On 2026-10-26 the 2pm session
# window refused 44 runs on 16 seats and at 14:03:06Z the retry woke exactly
# those 16 seats — set difference empty both ways — three minutes after the
# reset the provider had named. What its payload carries is the resource:
#
#   "capacity returned: the provider limit that refused your last run has
#    reset, and nothing else would have woken you until your next scheduled
#    window. Do the one run your charter describes."
#
# It names the run it is resuming and not what that run was woken to do. On
# 2026-10-26 the run it was resuming for this seat was the learning loop's
# daily tick: `asc-brief.timer` fired 12:01:53Z, the board emitted `brief.sent`
# 12:01:57.918Z, the bus woke eight seats — four exo, four pm, one pair per
# product — and all eight were refused at turn 1. The recovered run reads
# "capacity returned", does the generic thing its charter says, and the duty
# the window held is done by nobody. A run is fungible; the next message
# re-delivers the work. A duty is not: it is tied to an event that does not
# fire twice.
#
# So this answers the one question the payload does not: between the first
# refusal and now, what fired that I owe a duty to, and did a run of mine
# survive it. It is the seat side of L78 clause 2 — the hand side is one line
# in a payload composed in `runtime/`, which is HQ's and routed, not built here.
#
# Three answers and never two (L41). 0: nothing of this seat's was refused, or
# everything refused has since been served. 1: something is owed, named. 2:
# could not look — no logs, no board, or a manifest this script cannot read —
# which is never reported as 0.
#
# Reads only. Needs the host's logs; BOARD_API_URL and BOARD_RUNTIME_TOKEN for
# the event half, which degrades to could-not-look without them rather than to
# a clean bill (L-A80).
set -uo pipefail

LOGS=${EPITO_LOGS:-/srv/asc/state/.epito/logs}
ROSTER=${EPITO_ROSTER:-/srv/asc/roster}
PRODUCT=${EPITO_PRODUCT:-epitome}
SEAT=exo
DAYS=1
EVENTS=
SELFTEST=

while [ $# -gt 0 ]; do
  case "$1" in
    --seat) SEAT=${2:?--seat needs a name}; shift 2 ;;
    --days) DAYS=${2:?--days needs a number}; shift 2 ;;
    --logs) LOGS=${2:?--logs needs a path}; shift 2 ;;
    --roster) ROSTER=${2:?--roster needs a path}; shift 2 ;;
    --events) EVENTS=${2:?--events needs a file}; shift 2 ;;
    --self-test) SELFTEST=1; shift ;;
    --help|-h) sed -n '2,/^[^#]/p' "${BASH_SOURCE[0]}" | sed -n 's/^# \{0,1\}//p'; exit 0 ;;
    *) echo "owed.sh: unknown argument $1" >&2; exit 2 ;;
  esac
done

# L42: a verdict that has never fired is not a detector, and the cases below
# are built rather than looked for, because a host that is currently healthy
# contains none of them and an absence read as a pass is the bug this file is
# about. Every fixture is the shape of a thing that actually happened.
if [ "$SELFTEST" = 1 ]; then
  ok=1; day=$(date -u +%F)
  mk() { # mk DIR SEAT TS TRIGGER TERMINAL TURNS
    mkdir -p "$1/$2"
    printf '%s\n' "{\"duration_api_ms\":1,\"type\":\"result\",\"subtype\":\"success\",\"terminal_reason\":\"$5\",\"num_turns\":$6,\"total_cost_usd\":0,\"duration_ms\":1000,\"api_error_status\":${7:-0},\"result\":\"${8:-done}\"}" \
      > "$1/$2/${day}T$3-000Z-$4.log"
  }
  ev() { printf '{"events":[{"ts":"%sT%s+00:00","type":"brief.sent","payload":{}}]}' "$day" "$1"; }

  # 1. The real positive: a brief wake refused at turn 1 and nothing since.
  a=$(mktemp -d); mk "$a" epitome-exo 12-01-59 message api_error 1 429 "You've hit your session limit"
  ev 12:01:57 > "$a/events.json"
  out=$(bash "${BASH_SOURCE[0]}" --logs "$a" --events "$a/events.json" --roster /nonexistent 2>&1); rc=$?
  [ "$rc" = 1 ] || { echo "owed.sh --self-test: a refused brief wake with nothing since is owed — expected 1, got $rc" >&2; ok=0; }
  case "$out" in *"brief.sent"*owed*|*owed*"brief.sent"*) ;; *)
    echo "owed.sh --self-test: expected the brief.sent event named as owed" >&2; ok=0 ;; esac

  # 2. The negative that matters most: the same refusal, and a later run of
  #    this seat that finished. The duty was served late and nothing is owed.
  #    Without this case the script would report every past refusal forever.
  b=$(mktemp -d); mk "$b" epitome-exo 12-01-59 message api_error 1 429 "You've hit your session limit"
  mk "$b" epitome-exo 14-03-07 hook completed 90
  ev 12:01:57 > "$b/events.json"
  out=$(bash "${BASH_SOURCE[0]}" --logs "$b" --events "$b/events.json" --roster /nonexistent 2>&1); rc=$?
  [ "$rc" = 0 ] || { echo "owed.sh --self-test: a later finished run serves it — expected 0, got $rc" >&2; ok=0; }

  # 3. A refused scheduled slot is owed even when a later run finished, because
  #    a slot is not re-delivered by a message and the period is gone. This is
  #    the case that separates this script from "was the seat refused lately".
  c=$(mktemp -d); mk "$c" epitome-exo 12-00-08 cron api_error 1 429 "You've hit your session limit"
  mk "$c" epitome-exo 14-03-07 hook completed 90
  out=$(bash "${BASH_SOURCE[0]}" --logs "$c" --events /dev/null --roster /nonexistent 2>&1); rc=$?
  [ "$rc" = 1 ] || { echo "owed.sh --self-test: a refused slot is not served by a later message — expected 1, got $rc" >&2; ok=0; }
  case "$out" in *cadence*) ;; *) echo "owed.sh --self-test: expected the slot named as a lost cadence" >&2; ok=0 ;; esac

  # 4. Could-not-look, twice over, and neither reads as a clean bill (L-A80).
  d=$(mktemp -d)
  out=$(bash "${BASH_SOURCE[0]}" --logs "$d/absent" --events /dev/null --roster /nonexistent 2>&1); rc=$?
  [ "$rc" = 2 ] || { echo "owed.sh --self-test: no log directory is could-not-look — expected 2, got $rc" >&2; ok=0; }
  e=$(mktemp -d); mk "$e" epitome-exo 12-01-59 message api_error 1 429 "limit"
  out=$(bash "${BASH_SOURCE[0]}" --logs "$e" --events "$e/absent.json" --roster /nonexistent 2>&1); rc=$?
  case "$out" in *"could not look"*) ;; *)
    echo "owed.sh --self-test: no event source must say could not look" >&2; ok=0 ;; esac

  rm -rf "$a" "$b" "$c" "$d" "$e"
  [ "$ok" = 1 ] && { echo "owed.sh --self-test: all verdicts fired"; exit 0; }
  exit 1
fi

if [ ! -d "$LOGS" ]; then
  echo "owed.sh: no run logs at $LOGS — this runs where the host's logs are; could not look" >&2
  exit 2
fi

# The event half. Fetched unless injected. A fetch that fails is said out loud
# and degrades the event verdict to could-not-look; it never silently becomes
# "no duty was owed", which is the whole failure this file exists for.
EVENT_NOTE=
if [ -z "$EVENTS" ]; then
  EVENTS=$(mktemp)
  if [ -n "${BOARD_API_URL:-}" ] && [ -n "${BOARD_RUNTIME_TOKEN:-}" ]; then
    curl -sf -m 20 -H "Authorization: Bearer $BOARD_RUNTIME_TOKEN" \
      "$BOARD_API_URL/api/events?type=brief.sent&limit=50" > "$EVENTS" 2>/dev/null \
      || EVENT_NOTE="the board did not answer"
  else
    EVENT_NOTE="BOARD_API_URL or BOARD_RUNTIME_TOKEN is not in this run's environment"
  fi
fi

SEAT="$SEAT" DAYS="$DAYS" LOGS="$LOGS" ROSTER="$ROSTER" PRODUCT="$PRODUCT" \
EVENTS="$EVENTS" EVENT_NOTE="$EVENT_NOTE" python3 - <<'PY'
import datetime, glob, json, os, re, sys

logs = os.environ["LOGS"]; days = int(os.environ["DAYS"])
seat = os.environ["SEAT"]; product = os.environ["PRODUCT"]
roster = os.environ["ROSTER"]; events_path = os.environ["EVENTS"]
event_note = os.environ["EVENT_NOTE"]

host_seat = seat if seat.startswith(product + "-") else product + "-" + seat
today = datetime.datetime.now(datetime.timezone.utc)
window = [(today.date() - datetime.timedelta(days=i)).isoformat() for i in range(days)]

# The class of an ending is in the result object's own fields and never in the
# text of the log around it: this seat's final reports quote refusals verbatim,
# so a text search reads a run that documented one as a run that hit one (L64).
RESULT = re.compile(r'^\{"duration_api_ms".*"type":"result".*\}$', re.M)

runs = []
for day in window:
    for path in glob.glob(os.path.join(logs, host_seat, day + "*.log")):
        base = os.path.basename(path)
        found = RESULT.findall(open(path, errors="replace").read())
        rec = None
        if found:
            try: rec = json.loads(found[-1])
            except ValueError: rec = None
        stamp = base[:24].replace("T", " ")
        trigger = re.sub(r"\.log$", "", base).rsplit("-", 1)[-1]
        runs.append({"base": base, "ts": base[:24], "trigger": trigger, "rec": rec})
runs.sort(key=lambda r: r["ts"])

if not runs:
    print(f"owed.sh: no run logs for {host_seat} over {window[-1]}..{window[0]} under {logs} "
          f"— could not look, not a clean bill")
    sys.exit(2)

def refused(rec):
    if not rec: return False
    return rec.get("terminal_reason") == "api_error" or rec.get("api_error_status") in (429, 529)

def finished_ok(rec):
    return bool(rec) and rec.get("terminal_reason") in ("completed", "max_turns")

def parse_log(stamp):
    """`2026-10-26T12-01-59-494Z` -> epoch seconds. The executor writes the
    whole stamp with dashes, so this is not a dateutil shape and is parsed
    once, here, rather than guessed at each use."""
    m = re.match(r"(\d{4})-(\d{2})-(\d{2})T(\d{2})-(\d{2})-(\d{2})", stamp)
    if not m:
        return None
    y, mo, d, h, mi, se = (int(x) for x in m.groups())
    return datetime.datetime(y, mo, d, h, mi, se, tzinfo=datetime.timezone.utc).timestamp()

def parse_event(ts):
    """The board's ISO stamp, already stripped of its offset."""
    try:
        return datetime.datetime.fromisoformat(ts).replace(
            tzinfo=datetime.timezone.utc).timestamp()
    except ValueError:
        return None

refusals = [r for r in runs if refused(r["rec"])]
# "Served since" is deliberately coarse: any later run of this seat that
# reached a turn is evidence somebody was in the room after the refusal. It is
# the right test for a message wake, whose work the next message re-delivers,
# and the wrong one for a slot, which is handled separately below.
def served_after(ts):
    return [r for r in runs if r["ts"] > ts and finished_ok(r["rec"])]

# The seat's own declared slots, read from the manifest rather than remembered.
cron_spec = None
mf = os.path.join(roster, product, seat.split("-")[-1], "agent.toml")
if os.path.isfile(mf):
    m = re.search(r"^cron\s*=\s*\"([^\"]+)\"", open(mf).read(), re.M)
    cron_spec = m.group(1) if m else "none declared"
else:
    cron_spec = None

brief_events = []
if events_path and not os.path.isfile(events_path):
    event_note = event_note or f"the event source {events_path} is not a readable file"
elif os.path.isfile(events_path) and os.path.getsize(events_path):
    try:
        for e in json.load(open(events_path)).get("events", []):
            ts = (e.get("ts") or "").replace("+00:00", "")
            if ts[:10] in window:
                brief_events.append(ts)
    except ValueError:
        event_note = event_note or "the event source is not JSON this script can read"
elif not event_note:
    event_note = "no event source was given"
brief_events.sort()

print(f"owed.sh for {host_seat} over {window[-1]}..{window[0]}, read at "
      f"{today.strftime('%Y-%m-%dT%H:%M:%SZ')} from {logs}")
print()
print(f"{len(runs)} run(s), {len(refusals)} of them refused by a limit.")

owed_events, owed_slots = [], []

# 1. A duty-bearing EVENT that fired within two minutes of a refused run of
#    this seat. Two minutes because the bus fans out in seconds — the eight
#    brief wakes of 2026-10-26 landed between 12:01:58.266Z and 12:02:10.286Z,
#    five seconds after the event — and the trigger field in a log's name says
#    `message` for every one of them, so time is the only join this box offers.
#    Named as a correlation and not as a causal claim, because that is what it
#    is (L-A62).
for ts in brief_events:
    ev_s = parse_event(ts)
    if ev_s is None:
        continue
    near = [r for r in refusals
            if parse_log(r["ts"]) is not None and 0 <= parse_log(r["ts"]) - ev_s <= 120]
    if not near:
        continue
    later = served_after(near[-1]["ts"])
    owed_events.append((ts, near, later))
    verdict = ("SERVED LATE by " + later[0]["base"]) if later \
        else "OWED — no run of this seat has finished since"
    print(f"  brief.sent {ts}Z -> {len(near)} refused wake(s) within 120s: {verdict}")

# 2. A refused SLOT. A message wake refused costs hours, because the next
#    message re-delivers the work; a slot refused costs this seat's whole
#    cadence for its period, and no later message is that slot (L62, L79). So
#    a refused slot is owed even when something finished afterwards.
for r in refusals:
    if r["trigger"] == "cron":
        owed_slots.append(r)
        print(f"  slot {r['ts'].rstrip('Z')}Z refused at turn {r['rec'].get('num_turns')} — a lost cadence, "
              f"declared cron {cron_spec or 'unreadable'}; no message wake is this slot")

if event_note:
    print(f"  brief.sent: could not look — {event_note}. This is not a reading that nothing "
          f"was owed (L-A80).")
elif not brief_events:
    print("  brief.sent: the board holds no event of this type in the window. This store keeps "
          "one such event against a brief that fires daily, so an empty read is weaker evidence "
          "than it looks and is reported as what it is (L41).")

print()
if owed_events or owed_slots:
    print(f"{len(owed_events)} duty-bearing event(s) and {len(owed_slots)} scheduled slot(s) of this "
          f"seat met a limit. The retry re-delivers the run and not the window (L78), so none of "
          f"these is re-attempted by the mechanism that recovered you: do the duty or say on the "
          f"board that it was lost and by whose window.")
else:
    print("Nothing of this seat's duty-bearing wakes is outstanding in this window.")

print()
print("```data")
print(f"instrument: docs/agents/owed.sh")
print(f"read_at: {today.strftime('%Y-%m-%dT%H:%M:%SZ')}")
print(f"seat: {host_seat}")
print(f"window: {window[-1]}..{window[0]}")
print(f"runs: {len(runs)}")
print(f"runs_refused_by_a_limit: {len(refusals)}")
print(f"declared_cron: {cron_spec if cron_spec else 'manifest not readable from here'}")
print(f"brief_events_in_window: {len(brief_events)}")
print(f"brief_events_whose_wake_was_refused: {len(owed_events)}")
print(f"brief_events_still_owed: {sum(1 for _, _, later in owed_events if not later)}")
print(f"slots_refused: {len(owed_slots)}")
print(f"event_half: {'could-not-look: ' + event_note if event_note else 'read'}")
print("```")

sys.exit(1 if (owed_slots or any(not later for _, _, later in owed_events)) else 0)
PY
