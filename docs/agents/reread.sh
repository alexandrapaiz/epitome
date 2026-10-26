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

# The merge half of a wake, which is the other thing a payload asserts about a
# number. Verified the same way and reported with the same three outcomes,
# because a false "it is on main" sends a run looking for work that is not
# there (L73).
one_merged() {  # $1 = number
  local js; js=$(read_pr "$1") || { printf '  #%s could not look: no answer from gh or fixture\n' "$1"; return 2; }
  [ -n "$js" ] || { printf '  #%s could not look: empty answer\n' "$1"; return 2; }
  NOW=$NOW python3 - "$js" <<'PY'
import json, os, sys
from datetime import datetime, timezone
pr = json.loads(sys.argv[1]); now = int(os.environ["NOW"])
def ts(s): return None if not s else datetime.fromisoformat(s.replace("Z", "+00:00"))
def ago(t):
    m = int((now - t.timestamp()) // 60)
    return f"{m//60}h{m%60:02d}m" if m >= 60 else f"{m}m"
merged = ts(pr.get("mergedAt"))
head = f"#{pr['number']} {pr['state']} draft={str(pr['isDraft']).lower()} {pr['headRefName']}"
if merged:
    print(f"  {head}: merged {ago(merged)} ago — the merge claim holds")
    sys.exit(0)
print(f"  {head}: STALE — the wake says merged and it is not; nothing of it is on main")
sys.exit(1)
PY
}

# A re-read reads the claim, not only the object (L73). The first version of
# `--wake` collected every `#NNN` in the payload and ran the draft verdict on
# all of them, so it reported a disagreement with a claim the payload never
# made: on 2026-10-26 this seat's wake carried three numbers and exactly one
# draft claim, and the instrument called two of the three STALE for having
# merged, which is what the same payload's other half had just announced
# correctly. A number inherits the claim of the line it appears on, and a
# number on no claim-bearing line is reported as not re-read rather than
# re-read against a claim chosen for it.
wake() {  # $1 = payload file
  local tmp rc=0 r drafts merged bare
  tmp=$(mktemp) || { echo "  could not look: no scratch file" >&2; return 2; }
  # One pass over the payload in paragraph mode, because a wake is assembled
  # out of blocks and not out of sentences: the standing banner is one block
  # whatever its line wrapping, and an event's `/pull/NNN` link lands in a
  # sentence of its own after the prose that makes the claim.
  awk 'BEGIN{RS=""} {
      claim = "none"
      low = tolower($0)
      if (low ~ /open draft|is a draft|still a draft|idle [0-9]+ *h|no live run/) claim = "draft"
      else if (low ~ /merged|is on main|landed on main/)                         claim = "merged"
      # A claim has one subject, and it is the referent the sender gave it. A
      # block that carries a `/pull/NNN` link is about that number; every other
      # number in it is a citation, not a second subject. Without this, "the
      # correction #336 merged without: L71 is already written in #300"
      # asserts a merge about `#300`, which is open, and the instrument
      # publishes a disagreement with a claim nobody made.
      rest = $0; subject = ""
      if (match($0, /\/pull\/[0-9]+/)) subject = substr($0, RSTART + 6, RLENGTH - 6)
      while (match(rest, /#[0-9][0-9]+/)) {
        num = substr(rest, RSTART + 1, RLENGTH - 1)
        print (subject == "" || num == subject) ? claim : "none", num
        rest = substr(rest, RSTART + RLENGTH)
      }
      if (subject != "") print claim, subject
    }' "$1" | sort -u > "$tmp"
  # A number claimed a draft is read as a draft even if another sentence also
  # mentions it: the draft claim is the one that asks the run to act.
  drafts=$(awk '$1=="draft"{print $2}' "$tmp" | sort -un)
  merged=$(awk '$1=="merged"{print $2}' "$tmp" | sort -un)
  merged=$(comm -23 <(printf '%s\n' $merged | sort -u) <(printf '%s\n' $drafts | sort -u) | tr '\n' ' ')
  bare=$(comm -23 <(awk '$1=="none"{print $2}' "$tmp" | sort -u) \
                  <(printf '%s\n%s\n' "$drafts" "$merged" | tr ' ' '\n' | grep -E '^[0-9]+$' | sort -u) | tr '\n' ' ')
  rm -f "$tmp"
  printf 're-read %s\n' "$(date -u -d "@$NOW" +%FT%TZ)"
  if [ -z "${drafts// }" ] && [ -z "${merged// }" ] && [ -z "${bare// }" ]; then
    echo "no pull request named in that payload"; return 2
  fi
  for n in $drafts; do echo "  claim: still an open draft"; one "$n"; r=$?; [ $r -gt $rc ] && rc=$r; done
  for n in $merged; do echo "  claim: merged"; one_merged "$n"; r=$?; [ $r -gt $rc ] && rc=$r; done
  for n in $bare; do
    printf '  #%s named in the payload under no claim — not re-read, because this\n' "$n"
    printf '      instrument answers about a claim and the payload makes none about it\n'
  done
  printf 'claims in that payload: %s draft, %s merge, %s number(s) under no claim\n' \
    "$(printf '%s\n' $drafts | grep -c . || true)" \
    "$(printf '%s\n' $merged | grep -c . || true)" \
    "$(printf '%s\n' $bare   | grep -c . || true)"
  case $rc in
    0) echo "every claim that payload makes still holds" ;;
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
  # Two digits or more, because `--wake` reads `#NNN` and deliberately ignores
  # a one-digit `#N` in prose. A single-digit fixture tests a path no payload
  # takes (L-A157's shape: a double that cannot speak the real input).
  mk 12 CLOSED true  2026-10-24T13:48:30Z '"2026-10-24T16:45:46Z"' null 0
  mk 13 MERGED false 2026-10-24T16:26:42Z '"2026-10-24T16:52:43Z"' '"2026-10-24T16:52:43Z"' 4
  mk 14 OPEN   false 2026-10-24T13:20:49Z null null 9
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

  # The claim half (L73), built out of the real shape of the 2026-10-26 wake:
  # two merge events with their own `/pull/NNN` links, one standing draft
  # banner naming a number by hand, and a third number cited inside one of the
  # event blocks. Three numbers, two claims, one citation.
  printf '%s\n' \
    "Event: your pull request merged: L71 and L72. https://x/pull/13" "" \
    "Standing in your lane: one of your pull requests is an open draft with no live run behind it: #12 epitome-exo/x (idle 3h). Ready it, or close it." "" \
    "Event: your pull request merged: the correction #13 merged without L71's clause, already written in #14. https://x/pull/12" \
    > "$t/wake.txt"
  out=$(wake "$t/wake.txt"); rc=$?
  check "the draft claim is read as a draft"      "$out" "claim: still an open draft"
  check "the banner's number is the stale one"    "$out" "#12 CLOSED"
  check "a merge claim that holds says so"        "$out" "#13 MERGED draft=false epitome-exo/x: merged 2m ago — the merge claim holds"
  check "a cited number is not re-read"           "$out" "#14 named in the payload under no claim"
  check "the claim census is printed"             "$out" "claims in that payload: 1 draft, 1 merge, 1 number(s) under no claim"
  [ $rc = 1 ] || { echo "  FAIL exit for a stale draft claim in a wake: $rc"; fail=1; }
  # The verdict the old reader could never print: a merge announcement that is
  # not true. `#4` is open, so asserting it merged is the stale half.
  printf '%s\n' "Event: your pull request merged: anything. https://x/pull/14" > "$t/wake2.txt"
  out=$(wake "$t/wake2.txt"); rc=$?
  check "a false merge claim is stale, not silence" "$out" "the wake says merged and it is not"
  [ $rc = 1 ] || { echo "  FAIL exit for a false merge claim: $rc"; fail=1; }
  printf '%s\n' "Event: nothing happened and no number is named." > "$t/wake3.txt"
  out=$(wake "$t/wake3.txt"); rc=$?
  check "an empty payload is could-not-look" "$out" "no pull request named in that payload"
  [ $rc = 2 ] || { echo "  FAIL exit for an empty payload: $rc"; fail=1; }

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
  # The payload names pull requests as `#NNN`, two digits or more because a
  # bare `#1` in prose is usually a footnote and this is not a parser — and
  # each one is read against the claim its own sentence makes, never against
  # the one claim this instrument was built for (L73).
  wake "$2" ;;
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
