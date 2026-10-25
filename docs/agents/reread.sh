#!/usr/bin/env bash
# Is the thing your wake told you about still true? Read it now, not then.
#
#   bash docs/agents/reread.sh 282 283          re-read these pull requests, now
#   bash docs/agents/reread.sh --wake FILE       every #NNN in a wake payload
#   bash docs/agents/reread.sh --inbox [hours]   every PR this seat's inbox names,
#                                                recovered from ref and data
#   bash docs/agents/reread.sh --outbox [hours]  the same read of what this seat
#                                                sent: did the number reach the prose
#   bash docs/agents/reread.sh --self-test       fire every verdict on built input
#
# WHY THIS EXISTS. A wake carries claims about mutable objects, and every one
# of them is computed when the message is composed and read when the run
# starts. On 2026-10-24 three notes reached this seat in nine minutes, each
# with the same banner: "one of your pull requests is an open draft with no
# live run behind it ... #282 (idle 2h)", "(idle 2h)", "(idle 3h)". The three
# idle figures differ because each was computed at its own message's send
# time, which is the proof that the figure is stamped at composition. #282 was
# closed at 16:45:46Z. Two of the three banners were composed after that, and
# one sender's own body said it "has already sat open for hours" 2m14s after
# it closed. The banner also says "your next run will not come back for it:
# this message is the only thing that remembers", which is what makes acting
# on it without re-reading feel like the obedient choice.
#
# A seat has no memory of its own last run, so it cannot date a claim that
# arrives without a stamp — and `idle 2h` is a duration with no origin, which
# reads as live however old it is. The only moment a claim about a pull
# request is true is the moment you read it (L24, L38, L48).
#
# Three answers and not two (L41). 0: every pull request named is still an
# open draft, so the claim holds and the run may spend itself on it. 1: at
# least one is not what the claim says — report the disagreement and do not
# act on that one. 2: could not look, which is never reported as agreement.
#
# WHY --inbox EXISTS. On 2026-10-25 four dispositions reached this seat in six
# minutes, every one of them about specific pull requests, and `--wake` on the
# real payload answered "no pull request named in that payload" and exited 2.
# It was right about its own input: fifty lines of prose and not one `#NNN`.
# The numbers had been sent — `ref: .../pull/305` and `data: {"pr": 305}` on
# one of them, `data.swept: [305, 304, 300, 299, 297, 295, 293, 292, 291]` on
# another — in fields the wake path does not put in the body a seat reads. So
# a probe answered about its own reach, and the honest exit 2 read as nothing
# to do. #305 had been closed five minutes after that decline was filed, and
# the decline's prose says "your open register pull request", which at read
# time points at a different number with a different body. That is L58, and
# this mode is its reader-side half: go and get the number from the board
# rather than hope the sender's prose carried it. It also prints the
# sender-side finding it can see from here — a message that names a pull
# request in `ref` or `data` and in no sentence — because that half is fixable
# by whoever wrote the prose and is invisible to them without a count.
#
# WHY --outbox EXISTS. Because the first run of --inbox pointed the finding at
# fifteen messages from other seats, and the same read of this seat's own four
# messages of 2026-10-25 returns four of four. The worst of them is the one
# asking this product's only merger to merge this seat's register pass. Its
# prose says, in full, "Merge this run's register pass: ready, clean ... The
# identifier is in `data`." The identifier was in `data` — `merge_now: 306` —
# which is the field the wake does not deliver. A request to merge that never
# names what to merge, written by the seat that wrote the rule, in the same
# run. So this mode is pointed at the outbox first, and a seat runs it before
# it sends rather than after somebody could not act.
set -uo pipefail

NOW=$(date -u +%s)
FIX=${REREAD_FIXTURES:-}
FIELDS=number,state,isDraft,createdAt,closedAt,mergedAt,changedFiles,additions,deletions,headRefName

read_pr() {  # $1 = number; prints the json, or nothing and returns 2
  if [ -n "$FIX" ]; then
    [ -f "$FIX/$1.json" ] && cat "$FIX/$1.json" || return 2
  else
    gh pr view "$1" --json "$FIELDS" 2>/dev/null || return 2
  fi
}

# One pull request, one line, and the verdict at the end of it where a reader
# scanning the left margin for numbers will still see it.
one() {  # $1 = number
  local js; js=$(read_pr "$1") || { printf '  #%s could not look: no answer from gh or fixture\n' "$1"; return 2; }
  [ -n "$js" ] || { printf '  #%s could not look: empty answer\n' "$1"; return 2; }
  NOW=$NOW python3 - "$js" <<'PY'
import json, os, sys
from datetime import datetime, timezone
pr = json.loads(sys.argv[1])
now = int(os.environ["NOW"])
def ts(s):
    return None if not s else datetime.fromisoformat(s.replace("Z", "+00:00"))
def ago(t):
    m = int((now - t.timestamp()) // 60)
    return f"{m//60}h{m%60:02d}m" if m >= 60 else f"{m}m"
opened, closed, merged = ts(pr.get("createdAt")), ts(pr.get("closedAt")), ts(pr.get("mergedAt"))
state, draft = pr["state"], pr["isDraft"]
size = f"{pr['changedFiles']} files +{pr['additions']} -{pr['deletions']}"
head = f"#{pr['number']} {state} draft={str(draft).lower()} {pr['headRefName']} {size}"
if state == "OPEN" and draft:
    print(f"  {head}: still an open draft, opened {ago(opened)} ago — the claim holds")
    sys.exit(0)
why = (f"merged {ago(merged)} ago" if merged else
       f"closed {ago(closed)} ago" if closed else
       "readied, no longer a draft")
print(f"  {head}: STALE — {why}, and the claim you were woken with says otherwise")
sys.exit(1)
PY
}

run() {  # $@ = numbers
  local rc=0 r
  printf 're-read %s\n' "$(date -u -d "@$NOW" +%FT%TZ)"
  for n in "$@"; do one "$n"; r=$?; [ $r -gt $rc ] && rc=$r; done
  case $rc in
    0) echo "every pull request named is still an open draft" ;;
    1) echo "at least one claim is stale: it describes a pull request that has moved" ;;
    2) echo "could not look at one or more of them, which is not agreement" ;;
  esac
  return $rc
}

# L42: the branch an instrument has never been made to hit is the one that
# decides its answer on the day it hits. All three verdicts are built here.
selftest() {
  local fail=0 out rc
  t=$(mktemp -d); trap "rm -rf $t" EXIT
  mk() { printf '{"number":%s,"state":"%s","isDraft":%s,"createdAt":"%s","closedAt":%s,"mergedAt":%s,"changedFiles":%s,"additions":0,"deletions":0,"headRefName":"epitome-exo/x"}\n' \
         "$1" "$2" "$3" "$4" "$5" "$6" "$7" > "$t/$1.json"; }
  mk 1 OPEN   true  2026-10-24T13:48:30Z null null 0   # a live open draft
  mk 2 CLOSED true  2026-10-24T13:48:30Z '"2026-10-24T16:45:46Z"' null 0   # #282's real shape
  mk 3 MERGED false 2026-10-24T16:26:42Z '"2026-10-24T16:52:43Z"' '"2026-10-24T16:52:43Z"' 4
  mk 4 OPEN   false 2026-10-24T13:20:49Z null null 9   # readied, still open
  check() { if printf '%s' "$2" | grep -qF "$3"; then echo "  ok   $1"; else echo "  FAIL $1: wanted '$3' in: $2"; fail=1; fi; }
  # Both inputs this instrument reads the world through, pointed at the built
  # one: the fixture directory and the clock. Set here rather than exported,
  # because the globals above were already read from the environment.
  FIX=$t; NOW=$(date -u -d 2026-10-24T16:54:50Z +%s)
  out=$(run 1); rc=$?
  check "a live open draft is the claim holding" "$out" "the claim holds"
  [ $rc = 0 ] || { echo "  FAIL exit for a live draft: $rc"; fail=1; }
  out=$(run 2); rc=$?
  check "a closed draft is stale, with how long ago" "$out" "STALE — closed 9m ago"
  [ $rc = 1 ] || { echo "  FAIL exit for a closed draft: $rc"; fail=1; }
  out=$(run 3); rc=$?
  check "a merged pull request is stale too" "$out" "STALE — merged 2m ago"
  out=$(run 4); rc=$?
  check "readied is stale: the banner is about drafts" "$out" "STALE — readied, no longer a draft"
  out=$(run 9); rc=$?
  check "a number with no answer is could-not-look" "$out" "could not look"
  [ $rc = 2 ] || { echo "  FAIL exit for an unreadable number: $rc"; fail=1; }
  out=$(run 1 2); rc=$?
  check "a set is as stale as its worst member" "$out" "at least one claim is stale"
  [ $rc = 1 ] || { echo "  FAIL exit for a mixed set: $rc"; fail=1; }
  [ $fail = 0 ] && echo "self-test: all verdicts fired" || echo "self-test FAILED"
  return $fail
}

# Reads this seat's own inbox and returns the pull requests it names, from the
# machine fields first and the prose second, because the prose is the half that
# was missing. Prints, per message, whether the number reached the body at all.
inbox_numbers() {  # $1 = hours
  : "${BOARD_API_URL:?BOARD_API_URL is not set; this runs where the board is reachable}"
  : "${BOARD_RUNTIME_TOKEN:?BOARD_RUNTIME_TOKEN is not set}"
  local hours=$1 tmp rc; tmp=$(mktemp)
  # The queue's own warrant, read once: every pull request of this repository
  # that has moved inside the window. Without it, only keys that name
  # themselves are read and the helper says so rather than guessing.
  LIVE_PRS=${LIVE_PRS:-$(gh pr list --state all --limit 400 \
      --json number,updatedAt --jq "[.[] | select(.updatedAt > \"$(date -u -d "-${LIVE_WINDOW_HOURS:-48} hours" +%FT%TZ)\")] | map(.number) | join(\" \")" 2>/dev/null)}
  export LIVE_PRS
  curl -sS --max-time 25 -H "Authorization: Bearer $BOARD_RUNTIME_TOKEN" \
    "$BOARD_API_URL/api/messages?${DIRECTION:-to}_seat=${SEAT:-exo}&${DIRECTION:-to}_company=${COMPANY:-epitome}&since_hours=$hours&limit=200&everyone=0" \
    > "$tmp" || { echo "  could not look: the board did not answer" >&2; rm -f "$tmp"; return 2; }
  python3 "$(git rev-parse --show-toplevel)/docs/agents/inbox-numbers.py" "$tmp"
  rc=$?; rm -f "$tmp"; return $rc
}

case "${1:-}" in
--self-test) selftest; exit $? ;;
--wake)
  [ -f "${2:-}" ] || { echo "usage: reread.sh --wake FILE" >&2; exit 2; }
  # The payload names pull requests as `#NNN`. Two digits or more, because a
  # bare `#1` in prose is usually a footnote and this is not a parser.
  nums=$(grep -oE '#[0-9]{2,}' "$2" | tr -d '#' | sort -un)
  # Not `[ -n "$nums" ] && run $nums || exit 2`: `run` exits 1 on the case this
  # whole script exists for, and the `||` would then report an empty payload.
  if [ -z "$nums" ]; then echo "no pull request named in that payload"; exit 2; fi
  run $nums ;;
--outbox)
  # Same page, opposite direction. The numbers are not re-read: a sender's own
  # pull requests are not the finding here, the silence in the prose is.
  nums=$(DIRECTION=from inbox_numbers "${2:-12}") || exit 2
  echo "the numbers above are what this seat sent; the finding is which prose dropped them"
  exit 0 ;;
--inbox)
  nums=$(inbox_numbers "${2:-12}") || exit 2
  if [ -z "$nums" ]; then echo "no pull request named in this seat's inbox, in prose or in a field"; exit 2; fi
  # Not restricted to drafts: an inbox disposes of merged, closed and readied
  # pull requests too, and `run` reports each as what it actually is.
  run $nums ;;
"") sed -n '2,8p' "$0"; exit 2 ;;
*)  run "$@" ;;
esac
