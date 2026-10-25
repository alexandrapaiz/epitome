#!/usr/bin/env bash
# Dark minutes, and how many of them fall after the day's last refusal (L42).
#
#   bash docs/agents/idle.sh [YYYY-MM-DD]      default: today, UTC
#   bash docs/agents/idle.sh --self-test       fire every branch on built input
#
# Every figure the loop ledger's capacity line carries counts what the day's
# outcomes cost: runs, turns, refusals, failures. None of them counts the
# capacity this company had and did not spend, and on 2026-10-24 that was the
# larger number by far — 493 dark minutes of 729 elapsed, 489 of them after
# 02:09:50Z, which is the last run a provider limit touched. The four seats
# that ran next all started on the same second, 06:20:00Z, which is a clock
# and not a retry: nothing in this system resumes a run the provider refused,
# so the resource returning is not an event anything here reacts to (L18).
#
# This is the instrument for that number and nothing else. It reads logs. The
# day's run count, turns and refusal classes stay in loop.md's own command,
# because two instruments printing one number is how the two disagree.
#
# A log's start is its filename and its end is its mtime, which is the last
# write and so is right for a finished run and an under-estimate for a live
# one. An under-estimate of a run's end over-states dark time, so the figure
# is a ceiling and is printed as one.
set -uo pipefail
cd "$(git rev-parse --show-toplevel)"

LOGS=${ASC_LOG_DIR:-/srv/asc/state/.epito/logs}

# L42 is this script's own lesson, so its branches do not ship unfired. Each
# of the three verdicts below is built here and asserted, because the branch
# an instrument has never been made to hit is the one that decides its answer
# on the day it hits.
if [ "${1:-}" = --self-test ]; then
  t=$(mktemp -d); trap 'rm -rf "$t"' EXIT
  mk() { mkdir -p "$t/$1"; printf '%s\n# exit=%s pr=- session=- turns=%s\n' "$3" "$4" "$5" \
         > "$t/$1/2026-01-01T$2Z-message.log"; touch -d "2026-01-01T${2:0:2}:${2:3:2}:${2:6:2}Z" "$t/$1/2026-01-01T$2Z-message.log"; }
  fail=0
  check() { if printf '%s' "$2" | grep -qF "$3"; then echo "  ok   $1"; else echo "  FAIL $1: wanted '$3' in: $2"; fail=1; fi; }

  mk a 00-00-00-000 'worked' 0 40
  out=$(ASC_LOG_DIR=$t bash "$0" 2026-01-01 2>&1)
  check "no limit all day says so" "$out" "no run a limit touched"

  mk b 01-00-00-000 '{"api_error_status":429}' 1 -
  out=$(ASC_LOG_DIR=$t bash "$0" 2026-01-01 2>&1)
  check "a refusal is found and dated" "$out" "01:00:00Z"
  check "dark after it is reported"    "$out" "dark after it"

  out=$(ASC_LOG_DIR=$t bash "$0" 2026-01-02 2>&1); rc=$?
  check "a day with no logs refuses to answer" "$out" "no run logs"
  [ $rc -ne 0 ] && echo "  ok   and exits non-zero ($rc)" || { echo "  FAIL it exited 0"; fail=1; }

  [ $fail = 0 ] && echo "self-test: all branches fired" || echo "self-test: FAILED"
  exit $fail
fi

D=${1:-$(date -u +%F)}
[ -d "$LOGS" ] || { echo "$LOGS is not a directory, so this run cannot read capacity at all" >&2; exit 2; }

python3 - "$LOGS" "$D" <<'PY'
import glob, os, re, sys, datetime as dt
logs_dir, D = sys.argv[1], sys.argv[2]
U = dt.timezone.utc
def start(f):
    m = re.match(r'(\d{4})-(\d\d)-(\d\d)T(\d\d)-(\d\d)-(\d\d)', os.path.basename(f))
    return dt.datetime(*map(int, m.groups()), tzinfo=U)
logs = sorted(glob.glob(os.path.join(logs_dir, f'*/{D}*.log')), key=start)
if not logs:
    print(f"no run logs for {D} under {logs_dir}: this is a could-not-look and not a quiet day (L41)")
    sys.exit(3)

LIMIT = re.compile(r'"api_error_status":(429|529)|hit your [a-z]+ limit|limit (reached|exceeded)')
ref   = [f for f in logs if LIMIT.search(open(f, errors='replace').read())]

day0 = dt.datetime.fromisoformat(D).replace(tzinfo=U)
end  = min(day0 + dt.timedelta(days=1), dt.datetime.now(U))
cur, gaps = day0, []
for f in logs:
    s = start(f)
    e = max(s, dt.datetime.fromtimestamp(os.path.getmtime(f), U))
    if s > cur: gaps.append((cur, s))
    cur = max(cur, e)
if cur < end: gaps.append((cur, end))

dark = sum((b - a).total_seconds() for a, b in gaps)
span = (end - day0).total_seconds()
print(f"{D}  {len(logs)} runs  dark {dark/60:.0f} min of {span/60:.0f} elapsed"
      f" ({dark/span*100:.0f}%, a ceiling: a live run's end is read as its last write)")

if ref:
    mark = max(start(f) for f in ref)
    seat = os.path.basename(os.path.dirname(max(ref, key=start)))
    after = sum((b - a).total_seconds() for a, b in gaps if b > mark)
    print(f"last run a limit touched  {mark:%H:%M:%S}Z  {seat}  ({len(ref)} runs touched one)")
    print(f"dark after it             {after/60:.0f} min"
          f"  ({after/dark*100:.0f}% of the day's dark)")
else:
    print("no run a limit touched today, so every dark minute below is idle"
          " capacity and not an outage")

for a, b in sorted(gaps, key=lambda g: g[0] - g[1])[:3]:
    woke = sorted({os.path.basename(os.path.dirname(f)) for f in logs
                   if abs((start(f) - b).total_seconds()) < 2})
    print(f"  {(b-a).total_seconds()/60:5.0f} min  {a:%H:%M:%S}Z → {b:%H:%M:%S}Z"
          + (f"  broken by {', '.join(woke)}" if woke else ""))
PY
