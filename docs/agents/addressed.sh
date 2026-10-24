#!/usr/bin/env bash
# Two checks the night of 2026-10-24 paid for, so they stopped being lessons
# and became a command (L37, L38; L-X1 as amended — a repair without a
# detector leaves the future as exposed as it was).
#
#   bash docs/agents/addressed.sh --audit [since]   every message this seat sent
#   bash docs/agents/addressed.sh --body FILE ...   bodies you are about to post
#   bash docs/agents/addressed.sh --liveness SEAT   is a run of that seat open now
#
# All three answer one question: what does the reader actually receive.
#
# 1. A body sent unchanged to two companies, containing a referent that
#    resolves at the reader. On 2026-10-24T00:46:32Z this seat sent one body to
#    epitome/pm and alexandra-systems/pm, byte for byte identical, saying "this
#    one is for our own project manager". Read from HQ that names HQ's own
#    project manager, which is the better reading, and that item was declined
#    sixty-three seconds later as a request about its own charter. The pair
#    twenty minutes earlier, written per addressee, moved both of its items.
#    So the test is the conjunction: identical body AND more than one company
#    AND a reader-relative referent. Rewrite per addressee, or name the seat.
#
# 2. Whether a seat is running, read from the footer and not from a date.
#    A liveness claim about another seat perishes when you send it, because a
#    message to a seat is delivered by starting a run of that seat (L38). This
#    answers at the moment it is called, which is the only moment it is true.
#
# 3. Whether the wake will carry the body at all. A message is delivered by
#    waking the addressee with its text, and `wake_body` cuts at
#    WAKE_BODY_CHARS — 1500 on the board as deployed — keeping the head and
#    marking the loss. For prose that is the right cut and HQ says so in the
#    code, because the marker points at the inbox and a message IS in an
#    inbox. What it costs is still the tail, which is where the ask lives: of
#    the 87 messages posted in the board's 58-minute event window on
#    2026-10-24T01:41Z, 27 were delivered cut, and 12 of those 27 were this
#    seat's — the register that wrote L35 was the worst offender on the board
#    the same night. So the limit is checked before posting, not regretted
#    after.
#
# Needs BOARD_API_URL and BOARD_RUNTIME_TOKEN for --audit. Reads only.
set -uo pipefail
cd "$(git rev-parse --show-toplevel)" 2>/dev/null || true

# The referents. Every one of these is a word whose meaning is fixed by where
# the reader sits, not by where the writer sits. Deliberately short: a long
# list flags every honest sentence and gets switched off (the frameworks law).
# The board's own limit, overridable for a host that sets it differently.
WAKE_BODY_CHARS=${WAKE_BODY_CHARS:-1500}

flag_length() {  # $1 = label, $2 = file holding the body
  local n; n=$(wc -c <"$2" | tr -d ' ')
  if [ "$n" -gt "$WAKE_BODY_CHARS" ]; then
    printf '  WAKE-CUT %s: %s characters, limit %s — the last %s go to the inbox only\n' \
      "$1" "$n" "$WAKE_BODY_CHARS" "$((n - WAKE_BODY_CHARS))"
    printf '    the tail is where your ask is: shorten it, or put the ask in the first paragraph\n'
    return 1
  fi
  printf '  wake-whole %s: %s of %s characters\n' "$1" "$n" "$WAKE_BODY_CHARS"
  return 0
}

PATTERN='(our|my) own (project manager|pm|engineer|exo|centralizer|seat|runtime|repository|repo|charter|board|chair)|\b(this|our) (repository|repo|company|product|runtime|board)\b|\bnobody here\b|\bno seat here\b'

flag_body() {  # $1 = label, $2 = file holding the body
  local hits; hits=$(grep -onEi "$PATTERN" "$2" | head -20)
  if [ -n "$hits" ]; then
    printf '  REFERENT %s\n' "$1"
    echo "$hits" | sed 's/^/    line /'
    return 1
  fi
  return 0
}

# A bare seat name is not an address on a box that runs several companies'
# seats, which is L37 again with a directory instead of a possessive. This log
# root holds both `engineer` and `epitome-engineer`, both live, both with
# different newest runs, and the first reading of this instrument answered
# about the wrong one without saying so (incident 21). So resolve, and when the
# name is ambiguous say `unreadable` rather than pick (L41).
# The company is the repository's name on the remote, not the name of the
# directory this run happens to be cloned into: the clone is named for the run
# (`epito-epitome-exo-vWT2x7`) and that resolved every seat to `unreadable` on
# the first reading of this fix.
COMPANY=${EPITO_COMPANY:-$(basename -s .git "$(git remote get-url origin 2>/dev/null || echo unknown)")}
# How long a log may go unwritten and still be called a live run.
STALE_MINUTES=${STALE_MINUTES:-120}

resolve_seat() {  # $1 = seat as asked for; prints one dir name, or nothing
  local root=$1 seat=$2 c=() d
  for d in "$COMPANY-$seat" "$seat"; do
    [ -d "$root/$d" ] && c+=("$d")
  done
  case ${#c[@]} in
    0) return 2 ;;
    1) printf '%s\n' "${c[0]}"; return 0 ;;
    *) # Both exist. The company-qualified one is this product's, and the bare
       # one belongs to somebody; name both so the caller cannot read one as
       # the whole answer.
       printf '%s\n' "${c[0]}"; printf '%s\n' "${c[1]}"; return 1 ;;
  esac
}

liveness() {  # $1 = seat name; resolved against the host's log root
  local root=${EPITO_LOGS:-/srv/asc/state/.epito/logs} seat=$1 dirs rc newest open=0 d
  dirs=$(resolve_seat "$root" "$seat"); rc=$?
  if [ "$rc" = 2 ]; then
    echo "$seat: unreadable — no log directory at $root/$COMPANY-$seat or $root/$seat"
    return 2
  fi
  if [ "$rc" = 1 ]; then
    printf '%s: AMBIGUOUS — two directories answer to this name, and they are not the same seat:\n' "$seat"
  fi
  local age pad; pad=$([ "$rc" = 1 ] && echo '  ')
  for d in $dirs; do
    newest=$(ls -t "$root/$d"/*.log 2>/dev/null | head -1)
    [ -z "$newest" ] && { echo "$pad$d: no runs ever recorded"; continue; }
    open=0; grep -q '^# exit=' "$newest" || open=1
    age=$(( ( $(date +%s) - $(stat -c %Y "$newest") ) / 60 ))
    # A missing footer is not the same claim as a live run. `epitome-okr`'s
    # newest log has no footer and was last written 2026-10-09, and
    # `epitome-frontend`'s 2026-10-17: a run that died without writing its
    # footer reads byte-identical to one that is mid-turn. Only recency can
    # tell them apart, so the verdict carries it (incident 21, L41).
    if [ $open = 1 ] && [ "$age" -gt "$STALE_MINUTES" ]; then
      printf '%s%s: newest run %s — STALE, %sm since its last write and no # exit= footer: a run that died without closing, not a live run\n' \
        "$pad" "$d" "$(basename "$newest" .log)" "$age"
      open=0
    else
      printf '%s%s: newest run %s — %s (last write %sm ago)\n' "$pad" "$d" \
        "$(basename "$newest" .log)" \
        "$([ $open = 1 ] && echo 'OPEN, no # exit= footer: a run of this seat is alive right now' \
                         || echo 'closed, footer present: no run of this seat is alive')" "$age"
    fi
  done
  [ "$rc" = 1 ] && { echo "  ask for the directory by its own name to get one verdict, e.g. '--liveness epitome-pm'"; return 2; }
  [ $open = 1 ] && return 1 || return 0
}

# L42: the branch no input has ever reached is the one that decides the answer
# on the day it does, and this instrument's liveness half shipped with three
# such branches. Five constructed log roots, one per verdict. Written under
# mktemp rather than a named shared path, per L45.
selftest() {
  local work rc=0 out
  work=$(mktemp -d) || { echo "unreadable: mktemp gave this self-test no directory"; return 2; }
  mkdir -p "$work/acme-alpha" "$work/acme-beta" "$work/gamma" "$work/acme-gamma" "$work/acme-delta"
  printf 'turn 1\n'            > "$work/acme-alpha/2026-10-24T12-00-00-000Z-message.log"
  printf 'turn 1\n# exit=0\n'  > "$work/acme-beta/2026-10-24T12-00-00-000Z-message.log"
  printf 'turn 1\n'            > "$work/gamma/2026-10-24T12-00-00-000Z-message.log"
  printf 'turn 1\n'            > "$work/acme-gamma/2026-10-24T12-00-00-000Z-message.log"
  printf 'turn 1\n'            > "$work/acme-delta/2026-10-01T00-00-00-000Z-message.log"
  touch -d '2026-10-01 00:00' "$work/acme-delta/2026-10-01T00-00-00-000Z-message.log"

  verdict() {  # $1 = seat asked for
    EPITO_COMPANY=acme EPITO_LOGS="$work" STALE_MINUTES=120 \
      bash "$0" --liveness "$1" 2>&1 | grep -oE 'alive right now|no run of this seat is alive|AMBIGUOUS|STALE|unreadable' | head -1
  }
  local a b c d e
  a=$(verdict alpha); b=$(verdict beta); c=$(verdict gamma)
  d=$(verdict delta); e=$(verdict nobody)
  rm -rf "$work"

  printf 'case 1  footer absent, written now      expect alive right now              got %s\n' "${a:-<nothing>}"
  printf 'case 2  footer present                  expect no run ... is alive          got %s\n' "${b:-<nothing>}"
  printf 'case 3  bare and qualified both exist   expect AMBIGUOUS                    got %s\n' "${c:-<nothing>}"
  printf 'case 4  footer absent, three weeks old  expect STALE                        got %s\n' "${d:-<nothing>}"
  printf 'case 5  no directory under either name  expect unreadable                   got %s\n' "${e:-<nothing>}"
  [ "$a" = "alive right now" ]              || { echo "case 1 disagrees"; rc=1; }
  [ "$b" = "no run of this seat is alive" ] || { echo "case 2 disagrees"; rc=1; }
  [ "$c" = AMBIGUOUS ]                      || { echo "case 3 disagrees"; rc=1; }
  [ "$d" = STALE ]                          || { echo "case 4 disagrees"; rc=1; }
  [ "$e" = unreadable ]                     || { echo "case 5 disagrees"; rc=1; }
  [ $rc = 0 ] && echo "ok — all five verdicts fired and agreed" \
              || echo "a branch of this instrument disagrees with its own constructed input"
  return $rc
}

case "${1:-}" in
--self-test) selftest; exit $? ;;

--liveness)
  shift; rc=0; for s in "$@"; do liveness "$s" || rc=1; done; exit $rc ;;

--body)
  # The real test needs the conjunction, so give it every body of the set you
  # are about to post — one file per addressee. Identical files are the defect;
  # a referent in a body that is going to one company only is advisory.
  shift; rc=0; n=$#
  echo "== what the wake will carry =="
  for f in "$@"; do flag_length "$f" "$f" || rc=1; done
  echo
  dupes=$(md5sum "$@" | awk '{c[$1]=c[$1]" "$2; n[$1]++} END{for(h in n) if(n[h]>1) print c[h]}')
  if [ -n "$dupes" ]; then
    echo "== identical bodies in this set, so the conjunction applies (L37) =="
    for grp in $dupes; do flag_body "$grp" "$grp" || rc=1; done
    [ $rc = 0 ] && echo "  identical, but no reader-relative referent — it says the same thing to both"
  else
    echo "== $n bod$([ "$n" = 1 ] && echo y || echo ies), none identical: referents below are advisory =="
    for f in "$@"; do flag_body "$f" "$f"; done
    echo "  (each addressee gets its own body, which is the repair L37 asks for)"
  fi
  exit $rc ;;

--audit|"")
  : "${BOARD_API_URL:?BOARD_API_URL is not set; this runs where the board is reachable}"
  : "${BOARD_RUNTIME_TOKEN:?BOARD_RUNTIME_TOKEN is not set}"
  SINCE=${2:-$(date -u +%F)}
  tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
  curl -sS -H "Authorization: Bearer $BOARD_RUNTIME_TOKEN" \
    "$BOARD_API_URL/api/messages?from_seat=${SEAT:-exo}&from_company=${COMPANY:-epitome}&limit=200" \
    > "$tmp/sent.json" || exit 2
  printf 'audited %s  sent by %s/%s since %s\n\n' "$(date -u +%FT%TZ)" \
    "${COMPANY:-epitome}" "${SEAT:-exo}" "$SINCE"
  # Group by body hash. A group with more than one to_company is the case.
  python3 - "$tmp/sent.json" "$SINCE" "$tmp" <<'PY'
import json, sys, hashlib, os
msgs = json.load(open(sys.argv[1]))["messages"]
since, tmp = sys.argv[2], sys.argv[3]
groups = {}
for m in msgs:
    if m["ts"] < since: continue
    groups.setdefault(hashlib.sha1(m["body"].encode()).hexdigest()[:8], []).append(m)
multi = {k: v for k, v in groups.items()
         if len({m.get("to_company") for m in v}) > 1}
print(f"{len(groups)} distinct bodies since {since}; "
      f"{len(multi)} of them sent unchanged to more than one company")

# What the wake carried of each. The limit is the board's, read from the
# environment so this does not assert a number the host can change.
limit = int(os.environ.get("WAKE_BODY_CHARS", "1500"))
mine  = [m for m in msgs if m["ts"] >= since]
cut   = [m for m in mine if len(m["body"]) > limit]
print(f"{len(cut)} of {len(mine)} messages were longer than the {limit}-character wake, "
      f"so the addressee was woken without their tails")
for m in sorted(cut, key=lambda m: m["ts"]):
    print(f"  {m['ts'][:19]}Z  {len(m['body']):>5} chars  "
          f"-> {m.get('to_company')}/{m.get('to_seat')}  {m['subject'][:60]}")
# The audit exits non-zero on this too. A check that prints a finding and
# then reports success is the shape L41 is about.
open(os.path.join(tmp, "CUT"), "w").write(str(len(cut)))
for k, v in sorted(multi.items(), key=lambda kv: kv[1][0]["ts"]):
    m = v[0]
    print(f"\n  {m['ts'][:19]}Z  {k}  -> " +
          ", ".join(f"{x.get('to_company')}/{x.get('to_seat')}" for x in v))
    print(f"    {m['subject'][:96]}")
    open(os.path.join(tmp, k), "w").write(m["body"])
with open(os.path.join(tmp, "MULTI"), "w") as f:
    # A trailing newline, because `read` returns false on a last line
    # without one and the loop below would skip the only group there is.
    for k in sorted(multi):
        f.write(k + "\n")
PY
  rc=0
  [ "$(cat "$tmp/CUT" 2>/dev/null || echo 0)" -gt 0 ] && rc=1
  if [ -s "$tmp/MULTI" ]; then
    echo; echo "== the conjunction: identical body, two companies, reader-relative referent =="
    while read -r h || [ -n "$h" ]; do
      [ -n "$h" ] && { flag_body "$h" "$tmp/$h" || rc=1; }
    done < "$tmp/MULTI"
    [ $rc = 0 ] && echo "  none — every multi-company body names its seats"
  fi
  exit $rc ;;
*)
  sed -n '2,25p' "$0"; exit 2 ;;
esac
