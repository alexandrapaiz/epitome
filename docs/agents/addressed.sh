#!/usr/bin/env bash
# Two checks the night of 2026-10-24 paid for, so they stopped being lessons
# and became a command (L37, L38; L-X1 as amended — a repair without a
# detector leaves the future as exposed as it was).
#
#   bash docs/agents/addressed.sh --audit [since]   every message this seat sent
#   bash docs/agents/addressed.sh --body FILE ...   bodies you are about to post
#   bash docs/agents/addressed.sh --liveness SEAT   is a run of that seat open now
#   bash docs/agents/addressed.sh --can SEAT FILE... may that seat write these files
#   bash docs/agents/addressed.sh --can-self-test
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
# 3. Whether the seat you are about to ask may perform the act at all, read
#    from its charter rather than inferred from what the work is about. L40
#    already said a seat's writable surface is a fact about that seat's charter;
#    on 2026-10-24T21:44:14Z this seat asked epitome/pm to cut a branch editing
#    two files under prompts/ and was declined six minutes later by a sentence
#    that had been in prompts/pm-agent.md the whole time. A second instance of
#    a rule already in the register is a register defect (L4), so the rule
#    stopped being a sentence to remember and became this.
#
# 2. Whether a seat is running, read from the footer and not from a date.
#    A liveness claim about another seat perishes when you send it, because a
#    message to a seat is delivered by starting a run of that seat (L38). This
#    answers at the moment it is called, which is the only moment it is true.
#
# Needs BOARD_API_URL and BOARD_RUNTIME_TOKEN for --audit. Reads only.
set -uo pipefail
cd "$(git rev-parse --show-toplevel)" 2>/dev/null || true

# The referents. Every one of these is a word whose meaning is fixed by where
# the reader sits, not by where the writer sits. Deliberately short: a long
# list flags every honest sentence and gets switched off (the frameworks law).
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

liveness() {  # $1 = seat directory name under the host's log root
  local root=${EPITO_LOGS:-/srv/asc/state/.epito/logs} seat=$1 newest open=0
  if [ ! -d "$root/$seat" ]; then
    echo "$seat: no log directory at $root/$seat — this box cannot answer"; return 2
  fi
  newest=$(ls -t "$root/$seat"/*.log 2>/dev/null | head -1)
  [ -z "$newest" ] && { echo "$seat: no runs ever recorded"; return 1; }
  grep -q '^# exit=' "$newest" || open=1
  printf '%s: newest run %s — %s\n' "$seat" "$(basename "$newest" .log)" \
    "$([ $open = 1 ] && echo 'OPEN, no # exit= footer: a run of this seat is alive right now' \
                     || echo 'closed, footer present: no run of this seat is alive')"
  [ $open = 1 ] && return 1 || return 0
}

# May that seat write that file? Answered from its charter, read as sentences
# and not as lines. A charter wraps its prose, so the prohibition that cost
# this seat a round trip tonight has its verb on one line and its object on the
# next — "Never edit vision.md §0, okrs.md gradings, or / other seats'
# charters" — and a line-oriented grep sees neither half. Same defect as
# L-X5's seventh shape: the record is a sentence and the reader assumed a line.
#
# Three answers (L41). 0 nothing in the charter fences this surface, 1 the
# charter fences it in its own words or a credential does, 2 could not look.
# Charter silence about a surface a token decides is not permission (L-X9).
sentences() {  # $1 = file; prints one sentence per line
  tr '\n' ' ' < "$1" | sed -E 's/[[:space:]]+/ /g; s/([.!?]) /\1\n/g'
}

surface_words() {  # $1 = path; the words a charter uses to fence it
  case "$1" in
    prompts/*)             echo 'charter|instruction file|prompts/' ;;
    .github/workflows/*)   echo 'workflow' ;;
    docs/standards/*)      echo 'standard' ;;
    vision.md|*/vision.md) echo 'vision\.md' ;;
    okrs.md|*/okrs.md)     echo 'okrs\.md' ;;
    *)                     echo '' ;;
  esac
}

can() {  # $1 = seat, $2 = path
  local seat=$1 path=$2 charter words hits
  charter="prompts/$1-agent.md"
  if [ ! -r "$charter" ]; then
    printf '  COULD NOT LOOK  %-26s %s: no charter at %s, so this checkout cannot answer for it\n' \
      "$path" "$seat" "$charter"; return 2
  fi
  words=$(surface_words "$path")
  if [ -z "$words" ]; then
    printf '  no rule   %-26s %s: not a surface any charter here fences by name\n' "$path" "$seat"
    return 0
  fi
  # A seat editing its own charter is a different question from this one: these
  # charters fence *other* seats' charters, and widening a seat's own authority
  # is the owner's by the silence rule. Name which question it is.
  if [ "$path" = "$charter" ]; then
    printf '  OWN       %-26s %s: its own charter, so the bar is the silence rule and the owner\n' \
      "$path" "$seat"; return 0
  fi
  hits=$(sentences "$charter" \
         | grep -iE "$words" \
         | grep -iE "never|do not|is hers|are hers|the owner's" \
         | head -2)
  if [ -n "$hits" ]; then
    printf '  FORBIDDEN %-26s %s fences this surface in its own words:\n' "$path" "$seat"
    echo "$hits" | cut -c1-190 | sed "s|^|    $charter: |"
    return 1
  fi
  case "$path" in
    .github/workflows/*)
      printf '  TOKEN     %-26s %s: charter silent, and this surface is decided by the credential rather than the charter (L-X9) — probe by write\n' \
        "$path" "$seat"; return 1 ;;
  esac
  printf '  may write %-26s %s: no sentence in its charter fences this surface\n' "$path" "$seat"
  return 0
}

case "${1:-}" in
--can-self-test)
  # Every branch of `--can` fired against an input, because a branch nothing
  # has ever hit decides the answer on the day it hits (L42). The fixture is a
  # throwaway charter so the test does not move when a real one does.
  tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT; rc=0
  mkdir -p "$tmp/prompts"
  # The wrap is deliberate: the prohibition's verb and object land on
  # different lines, which is the case a line-oriented reader misses.
  cat > "$tmp/prompts/fixture-agent.md" <<'MD'
## What you never do

Never write product code. Never edit vision.md §0, okrs.md gradings, or
other seats' charters. Never shape a pitch that violates ADR-1.
MD
  check() { # $1 label $2 want $3.. argv
    local label=$1 want=$2; shift 2
    ( cd "$tmp" && bash "$OLDPWD/docs/agents/addressed.sh" "$@" ) >"$tmp/out" 2>&1
    local got=$?
    if [ "$got" = "$want" ]; then printf '  ok    %-42s exit %s\n' "$label" "$got"
    else printf '  FAIL  %-42s want %s got %s\n' "$label" "$want" "$got"; sed 's/^/        /' "$tmp/out"; rc=1; fi
  }
  check "wrapped prohibition is found"  1 --can fixture prompts/other-agent.md
  check "its own charter is not this question" 0 --can fixture prompts/fixture-agent.md
  check "unfenced surface passes"       0 --can fixture docs/agents/lessons.md
  check "workflow is the token's, not the charter's" 1 --can fixture .github/workflows/a.yml
  check "no charter is could-not-look"  2 --can nosuchseat prompts/other-agent.md
  check "too few arguments"             2 --can fixture
  exit $rc ;;

--can)
  # Run this before writing a handoff that asks a seat to touch a file. A
  # decline costs two runs and a day and arrives looking like caution, so it is
  # cheaper to be refused here (L40 as amended).
  shift
  [ $# -ge 2 ] || { echo "usage: addressed.sh --can SEAT FILE [FILE...]" >&2; exit 2; }
  seat=$1; shift; rc=0
  printf 'may %s write these, read from prompts/%s-agent.md in this checkout\n' "$seat" "$seat"
  for f in "$@"; do can "$seat" "$f"; v=$?; [ $v -gt $rc ] && rc=$v; done
  [ $rc = 1 ] && echo "  -> do not ask this seat for this act; route it to the hand its charter leaves standing (L40)"
  exit $rc ;;

--liveness)
  shift; rc=0; for s in "$@"; do liveness "$s" || rc=1; done; exit $rc ;;

--body)
  # The real test needs the conjunction, so give it every body of the set you
  # are about to post — one file per addressee. Identical files are the defect;
  # a referent in a body that is going to one company only is advisory.
  shift; rc=0; n=$#
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
