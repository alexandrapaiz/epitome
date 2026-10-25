#!/usr/bin/env bash
# Two checks the night of 2026-10-24 paid for, so they stopped being lessons
# and became a command (L37, L38; L-X1 as amended — a repair without a
# detector leaves the future as exposed as it was).
#
#   bash docs/agents/addressed.sh --audit [since]   every message this seat sent
#   bash docs/agents/addressed.sh --body FILE ...   bodies you are about to post
#   bash docs/agents/addressed.sh --liveness SEAT   is a run of that seat open now
#                                                   (bare name resolved against this
#                                                   product's prefix; ambiguous refused)
#   bash docs/agents/addressed.sh --inbox [SEAT]    your own inbox, default off
#   bash docs/agents/addressed.sh --can SEAT FILE... may that seat write these files
#   bash docs/agents/addressed.sh --can-self-test
#   bash docs/agents/addressed.sh --limits [hours] [believed]
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
# 4. Whether the limit a seat is writing to exists. Three times on 2026-10-24
#    `epitome/pm` sent this seat a message and then sent it again, shorter, within
#    half a minute, twice saying the board had cut it at 1500 characters. Measured:
#    the store held all three whole at 1875, 1695 and 1631 characters, the longest
#    body in the window is 2271, and nothing in it sits at 1490-1500. The cut was
#    the wake payload, downstream of the store, and it declares its own cut in
#    band. So the belief cost 1,535 characters of this company's own reasoning,
#    deleted by its senders to evade a limit that was never there, while the real
#    cut went on happening where neither of them was looking (L56, incident 28).
#
#    And the write path does constrain a body — on a different axis, by refusing
#    rather than by truncating. Probed at 23:18Z against the store this box runs:
#    a code or pull request number in the prose is a 400 naming the token, and a
#    paragraph over 420 characters is a 400 naming the number. Both are stated in
#    the refusal, with the seat still in the room. A store that refuses cannot
#    produce a pile-up, so the accepted-body reading below answers the
#    truncation question and only that one; the paragraph check is what answers
#    the other (L-A50, L-A72).
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

# This box carries every company's seats in one flat directory, so a bare
# `engineer` or `pm` is a real directory belonging to somebody else. Resolving
# it by "whichever name happens to exist" is how incident 21 happened, and the
# repair that run shipped taught the *caller* to pass a prefix rather than
# teaching this function to refuse an ambiguous one — so on 2026-10-25 a bare
# `engineer` still answered about HQ's engineer, confidently, and a bare
# `market` answered "this box cannot answer" while `epitome-market` sat in the
# same root. Four answers and never two (L41), and the ambiguity is a refusal
# rather than a pick: `docs/standards/lessons.md` L-A56's third clause says a
# shared name is not an address, and five companies hold a seat called `exo`.
# The prefix comes from the remote rather than from a literal, so a fork of
# this repository resolves against its own name.
product_prefix() {
  local url; url=$(git config --get remote.origin.url 2>/dev/null) || true
  url=${url%.git}; url=${url##*/}
  printf '%s' "${url:-epitome}" | tr '[:upper:]' '[:lower:]'
}

resolve_seat() {  # $1 = name as the caller wrote it; prints the directory or fails
  local root=$1 name=$2 pre; pre=$(product_prefix)
  case "$name" in
    */*) echo "addressed.sh: $name is not a seat name" >&2; return 2 ;;
    *-*) [ -d "$root/$name" ] && { printf '%s' "$name"; return 0; }
         echo "$name: no log directory at $root/$name — this box cannot answer"; return 2 ;;
  esac
  local bare=0 mine=0
  [ -d "$root/$name" ] && bare=1
  [ -d "$root/$pre-$name" ] && mine=1
  if [ $bare = 1 ] && [ $mine = 1 ]; then
    echo "$name: AMBIGUOUS — both $root/$name and $root/$pre-$name exist on this box, and they are two companies' seats. Say which: $pre-$name for this product's, $name for the other (L-A56, incident 21)"
    return 2
  fi
  [ $mine = 1 ] && { printf '%s' "$pre-$name"; return 0; }
  if [ $bare = 1 ]; then
    echo "$name: $root/$name exists and is NOT this product's seat — this product's would be $pre-$name, which is absent. Answering about $name would be answering about another company (L-A56, incident 21)"
    return 2
  fi
  echo "$name: no log directory at $root/$name or $root/$pre-$name — this box cannot answer"
  return 2
}

liveness() {  # $1 = seat name, bare or prefixed; resolved, never guessed
  local root=${EPITO_LOGS:-/srv/asc/state/.epito/logs} seat newest open=0
  seat=$(resolve_seat "$root" "$1") || { [ -n "$seat" ] && echo "$seat"; return 2; }
  if [ "$seat" != "$1" ]; then
    printf '%s: resolved to %s, the seat of this product on this box\n' "$1" "$seat"
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

# A seat's own inbox, read honestly. Two reads of the same window: one with
# the broadcast default off, one with it on. The board's message read takes
# `everyone`, it defaults to true, and `0` is the only spelling of false it
# honours — `false`, `False`, `no` and `off` are all accepted and read as
# true — so the documented read mixes the portfolio's broadcast feed into one
# page with this seat's own messages, and the rows the limit drops are the
# addressed ones (L54).
#
# Three answers, never two (L41): 0 read whole, 1 the default-on read was cut
# where the honest one was not, 2 could not look or the honest page itself came
# back at its limit, which is a floor on an inbox and not a reading of one
# (L-A87).
inbox_report() {  # $1 = honest page, $2 = default-on page, $3 = seat, $4 = company, $5 = hours
  INBOX_SEAT=$3 INBOX_COMPANY=$4 INBOX_HOURS=$5 python3 - "$1" "$2" <<'INNER_PY'
import json, os, sys
seat, company = os.environ["INBOX_SEAT"], os.environ["INBOX_COMPANY"]
hours = os.environ["INBOX_HOURS"]


def read(path):
    try:
        d = json.load(open(path))
    except Exception as e:                       # noqa: BLE001
        print(f"  COULD NOT LOOK  {path}: {e}")
        sys.exit(2)
    if "messages" not in d:                      # the route answered, with a refusal
        print(f"  COULD NOT LOOK  {path}: {str(d)[:160]}")
        sys.exit(2)
    return d


honest, default = read(sys.argv[1]), read(sys.argv[2])
mine, rows = honest["messages"], default["messages"]
addressed = [m for m in rows if m.get("to_seat")]
broadcast = [m for m in rows if not m.get("to_seat")]
print(f"inbox {company}/{seat} over {hours}h, broadcast default off: "
      f"{len(mine)} message(s), saturated={honest.get('saturated')}")
print(f"  same window with the default on: {len(rows)} row(s), "
      f"saturated={default.get('saturated')} — {len(addressed)} addressed, "
      f"{len(broadcast)} addressed to no seat")
rc = 0
if honest.get("saturated"):
    print(f"  SATURATED  the honest page came back at its limit of "
          f"{honest.get('limit')}, so it is a floor on this inbox and not a "
          f"reading of it: page it with before_hours (L-A87)")
    rc = 2
elif default.get("saturated"):
    print(f"  CUT  the default-on read filled its page and this one did not, "
          f"which is L54 exactly: {len(broadcast)} of its {len(rows)} rows are "
          f"addressed to no seat, and what a full page drops is the rest of "
          f"your own")
    rc = 1
else:
    print("  both reads came back whole; the default cost nothing in this window")
for m in mine:
    print(f"  {(m.get('kind') or '?'):<8} "
          f"{m.get('from_company')}/{m.get('from_seat')}  "
          f"{(m.get('subject') or '')[:80]}")
sys.exit(rc)
INNER_PY
}

# Is the limit real, and who is paying for it. One read, two answers, because
# both come off the same page: the longest body the store actually holds, and
# the re-sends that happened because somebody believed a shorter one.
#
# A clamp shows itself as a pile-up: a store that truncates at N has many
# bodies at exactly N and none above it. A store that does not has a smooth
# tail and a maximum wherever the longest writer stopped. So the test is not
# "did anything reach N", it is "is there a pile-up at N, and is the maximum
# above it" — the second half is what refutes a believed limit, and the first
# half is what finds a real one nobody has written down yet.
#
# The re-send signature is a conjunction, and it has to be: the first cut of
# this check asked only for the same sender inside a short window with a shorter
# second body, and it returned eight pairs of which three were real. The other
# five were a seat posting two different messages in one pass, which is ordinary
# traffic, and a check that calls those a defect is a check nobody leaves on
# (L-A44, L-A50, and the frameworks law). So the second message must also *say*
# it is a repair — a subject that repeats the first one, or one that names itself
# a correction, an amendment, a cut or a decision stated first. All three real
# pairs of 2026-10-24 carry one of those and none of the five do.
#
# Three answers (L41). 0 no clamp visible and the believed limit is refuted,
# 1 a pile-up at one length or a re-send in the window, 2 could not look.
limits_report() {  # $1 = page of messages, $2 = believed limit, $3 = window seconds
  LIM_BELIEVED=$2 LIM_GAP=${3:-180} python3 - "$1" <<'INNER_PY'
import json, os, re, sys
from datetime import datetime

believed = int(os.environ["LIM_BELIEVED"])
gap = int(os.environ["LIM_GAP"])

try:
    doc = json.load(open(sys.argv[1]))
except Exception as e:                                   # noqa: BLE001
    print(f"  COULD NOT LOOK  {sys.argv[1]}: {e}")
    sys.exit(2)
if "messages" not in doc:
    print(f"  COULD NOT LOOK  {sys.argv[1]}: {str(doc)[:160]}")
    sys.exit(2)

msgs = [m for m in doc["messages"] if isinstance(m.get("body"), str)]
if not msgs:
    print("  COULD NOT LOOK  the page came back with no body on it, which is a "
          "floor on this window and not a reading of it (L-A80)")
    sys.exit(2)

lens = sorted(len(m["body"]) for m in msgs)
longest = max(msgs, key=lambda m: len(m["body"]))
rc = 0
print(f"{len(msgs)} bod(ies) read from the store, longest {lens[-1]} characters")
print(f"  longest  {longest['ts'][:19]}Z  "
      f"{longest.get('from_company')}/{longest.get('from_seat')}  "
      f"{(longest.get('subject') or '')[:60]}")

# A pile-up is more than one body within two characters of the same length,
# with nothing above it. Two is enough: a store that clamps cannot produce a
# third value above the clamp, so the absence above is what carries the claim.
pile = [n for n in set(lens)
        if sum(1 for m in lens if abs(m - n) <= 2) >= 3 and max(lens) <= n + 2]
if pile:
    n = min(pile)
    print(f"  CLAMP    {sum(1 for m in lens if abs(m - n) <= 2)} bodies within two "
          f"characters of {n} and nothing above it: the store clamps here, and "
          f"that is the number to write to")
    rc = 1
else:
    at = sum(1 for n in lens if believed - 10 <= n <= believed)
    verdict = ("REFUTED" if lens[-1] > believed else "no body in this window "
               f"reached {believed}, so it is untested here")
    print(f"  no clamp: {at} bod(ies) within ten characters of the believed "
          f"limit {believed}, and the longest is {lens[-1]}")
    if lens[-1] > believed:
        print(f"  {verdict}  a body above {believed} is in the store whole, so a "
              f"seat trimming to {believed} is paying for a limit that is not here")
    else:
        print(f"  UNTESTED {verdict}: post one longer before you believe it")
        rc = 1

# The other axis, and the one that is real: the store refuses rather than
# truncates, so nothing above its ceiling is ever in the page above. Read the
# ceiling off the writer this box runs rather than off a memory of it (L-A72),
# and check it against the longest paragraph that was actually accepted — a
# guard nothing has ever bounced is a guard nobody has measured.
GUARD = "/srv/asc/hq/runtime/board/store.py"
ceiling = None
try:
    for line in open(GUARD):
        if line.startswith("MAX_PARAGRAPH"):
            ceiling = int(line.split("=")[1].strip())
            break
except OSError:
    pass


def paragraphs(body):
    out = []
    for para in re.split(r"\n\s*\n|\n(?=[-*\u2022] )", body):
        out.append(para.strip())
    return out


widest, widest_m = 0, None
for m in msgs:
    for para in paragraphs(m["body"]):
        if len(para) > widest:
            widest, widest_m = len(para), m
if ceiling is None:
    print(f"  COULD NOT LOOK  no {GUARD} on this box, so the paragraph ceiling "
          f"is unread here; the widest paragraph accepted in this window is {widest}")
    rc = max(rc, 2)
else:
    print(f"  paragraph ceiling {ceiling}, read off the writer this box runs, "
          f"and the widest paragraph in the page is {widest}")
    if widest > ceiling:
        print(f"  CONTRADICTION  a paragraph above the ceiling is in the store, so "
              f"the ceiling read is stale or not the writer this board uses")
        rc = max(rc, 1)
    else:
        print(f"  the store refuses rather than truncates: nothing above {ceiling} "
              f"can be in this page, so the no-clamp reading above is about total "
              f"length and not about what the write path will take")

# Re-sends: same sender, inside the window, second one shorter.
def when(m):
    return datetime.fromisoformat(m["ts"].replace("Z", "+00:00"))

bysender = {}
for m in msgs:
    bysender.setdefault((m.get("from_company"), m.get("from_seat")), []).append(m)
REPAIR = ("correction", "corrected", "correcting", "amendment", "amended",
          "decision first", "decision-first", "cut off", "truncat", "re-send",
          "resend", "sent again", "here it is again")


def declares_repair(a, b):
    """Does b say it is a repair of a, rather than merely follow it?"""
    sb = (b.get("subject") or "").lower()
    if any(w in sb for w in REPAIR):
        return "names itself a repair"
    sa = (a.get("subject") or "").lower()
    # Shared wording, measured on words long enough to mean something. An
    # identical subject is the strongest form of this and lands here too.
    wa = {w for w in sa.replace(",", " ").replace(";", " ").split() if len(w) > 4}
    wb = {w for w in sb.replace(",", " ").replace(";", " ").split() if len(w) > 4}
    shared = wa & wb
    if len(shared) >= 4:
        return f"repeats {len(shared)} words of the first subject"
    return ""


pairs, lost = [], 0
for who, ms in bysender.items():
    ms.sort(key=when)
    for a, b in zip(ms, ms[1:]):
        if not (0 <= (when(b) - when(a)).total_seconds() <= gap):
            continue
        if len(b["body"]) >= len(a["body"]):
            continue
        why = declares_repair(a, b)
        if not why:
            continue
        pairs.append((who, a, b, why)); lost += len(a["body"]) - len(b["body"])
if pairs:
    print(f"  RE-SENT  {len(pairs)} pair(s) inside {gap}s with the second body "
          f"shorter, {lost} characters deleted by their own senders:")
    for (co, seat), a, b, why in sorted(pairs, key=lambda p: p[1]["ts"]):
        print(f"    {a['ts'][:19]}Z {co}/{seat}  {len(a['body'])} -> "
              f"{len(b['body'])} ({len(a['body']) - len(b['body'])} lost) — {why}")
        print(f"      first   {(a.get('subject') or '')[:72]}")
        print(f"      again   {(b.get('subject') or '')[:72]}")
    print("  -> the cut these repair is downstream of the store and names itself "
          "in band; put the disposition in the first sentence instead (L56)")
    rc = 1
else:
    print(f"  no re-send pair in this window: nobody sent the same thing twice "
          f"inside {gap}s")
sys.exit(rc)
INNER_PY
}

inbox() {  # $1 = seat, $2 = company, $3 = hours, $4 = limit
  local seat=$1 company=$2 hours=$3 limit=$4 tmp q
  : "${BOARD_API_URL:?BOARD_API_URL is not set; this runs where the board is reachable}"
  : "${BOARD_RUNTIME_TOKEN:?BOARD_RUNTIME_TOKEN is not set}"
  # mktemp failing and the caller not checking it is how a tool answers from
  # state it never wrote (L-A71).
  tmp=$(mktemp -d) || { echo "  COULD NOT LOOK  no scratch directory" >&2; return 2; }
  q="to_seat=$seat&to_company=$company&since_hours=$hours&limit=$limit"
  curl -sS -H "Authorization: Bearer $BOARD_RUNTIME_TOKEN" \
    "$BOARD_API_URL/api/messages?$q&everyone=0" > "$tmp/honest.json" \
    || { echo "  COULD NOT LOOK  the board did not answer" >&2; rm -rf "$tmp"; return 2; }
  curl -sS -H "Authorization: Bearer $BOARD_RUNTIME_TOKEN" \
    "$BOARD_API_URL/api/messages?$q" > "$tmp/default.json" \
    || { echo "  COULD NOT LOOK  the board did not answer" >&2; rm -rf "$tmp"; return 2; }
  inbox_report "$tmp/honest.json" "$tmp/default.json" "$seat" "$company" "$hours"
  local rc=$?; rm -rf "$tmp"; return $rc
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

--limits)
  # Run this before you trim a body to fit a number you did not measure. The
  # answer is about the store this box talks to, not about the wake that
  # delivered your payload: those are two cuts in two hands (L56).
  shift
  : "${BOARD_API_URL:?BOARD_API_URL is not set; this runs where the board is reachable}"
  : "${BOARD_RUNTIME_TOKEN:?BOARD_RUNTIME_TOKEN is not set}"
  hours=${1:-48}; believed=${2:-1500}
  tmp=$(mktemp -d) || { echo "  COULD NOT LOOK  no scratch directory" >&2; exit 2; }
  trap 'rm -rf "$tmp"' EXIT
  printf 'bodies in the store over %sh, against a believed limit of %s, read %s\n' \
    "$hours" "$believed" "$(date -u +%FT%TZ)"
  curl -sS -H "Authorization: Bearer $BOARD_RUNTIME_TOKEN" \
    "$BOARD_API_URL/api/messages?to_seat=${SEAT:-exo}&to_company=${COMPANY:-epitome}&since_hours=$hours&limit=200&everyone=0" \
    > "$tmp/page.json" \
    || { echo "  COULD NOT LOOK  the board did not answer" >&2; exit 2; }
  limits_report "$tmp/page.json" "$believed" 180
  exit $? ;;

--limits-self-test)
  # Every branch fired against a built page (L42): a real clamp, a refuted
  # belief, an untested window, a re-send pair, and two unreadable pages.
  tmp=$(mktemp -d) || exit 2; trap 'rm -rf "$tmp"' EXIT; rc=0
  page() {  # $1 = file, then LEN:OFFSET_SECONDS triples as LEN@SECONDS
    PG_SPEC="$2" python3 -c '
import json, os, sys
from datetime import datetime, timedelta, timezone
# One row per LEN@SECONDS[:subject-with-dashes] token.
base = datetime(2026, 10, 24, 12, 0, 0, tzinfo=timezone.utc)
rows = []
for i, spec in enumerate(os.environ["PG_SPEC"].split()):
    head, _, subj = spec.partition(":")
    n, secs = head.split("@")
    # Paragraph-shaped, because the store refuses a block over its ceiling and
    # a fixture of one long run would make every page a contradiction.
    want, chunks = int(n), []
    while want > 0:
        take = min(want, 400)
        chunks.append("x" * take); want -= take
    rows.append({"ts": (base + timedelta(seconds=int(secs))).isoformat(),
                 "from_company": "epitome", "from_seat": "pm",
                 "subject": subj.replace("-", " ") if subj else f"body {i}",
                 "body": "\n\n".join(chunks)})
json.dump({"messages": rows}, open(sys.argv[1], "w"))' "$1"
  }
  check() {  # $1 label $2 want $3 file $4 believed
    limits_report "$3" "${4:-1500}" 180 > "$tmp/out" 2>&1
    local got=$?
    if [ "$got" = "$2" ]; then printf '  ok    %-46s exit %s\n' "$1" "$got"
    else printf '  FAIL  %-46s want %s got %s\n' "$1" "$2" "$got"
         sed 's/^/        /' "$tmp/out"; rc=1; fi
  }
  # A real clamp: three bodies at the limit and nothing above it.
  page "$tmp/clamp" "1500@0 1500@40 1499@80 900@120"
  check "a pile-up with nothing above it is a clamp" 1 "$tmp/clamp"
  # Tonight's real shape: a smooth tail, a maximum above the belief, no pair.
  page "$tmp/refuted" "1875@0 1631@600 2271@1200 443@1800 514@2400"
  check "a maximum above the belief refutes it" 0 "$tmp/refuted"
  # Nothing in the window got near the belief, so the belief is untested.
  page "$tmp/untested" "200@0 300@600 400@1200"
  check "no body near the belief is untested, not clear" 1 "$tmp/untested"
  # The re-send, as it really arrived: the second subject names itself.
  page "$tmp/resend" "1875@0:the-chain-waits-with-everything-else 1351@23:Correction-decision-first-the-chain-waits 2400@600:something-else-entirely"
  check "second subject names itself a repair" 1 "$tmp/resend"
  # The other real form: the same subject twice.
  page "$tmp/same" "1695@0:your-merge-order-measurement-checked-out-and-I-undid 1164@11:your-merge-order-measurement-checked-out-and-I-undid 900@600:unrelated"
  check "the same subject twice is a re-send" 1 "$tmp/same"
  # The five false positives of the first cut: two different messages, one pass.
  page "$tmp/traffic" "1040@0:triage-of-a-capped-engineer-run 804@18:message-pass-market-and-the-engineer 2400@600:unrelated"
  check "two messages in one pass is ordinary traffic" 0 "$tmp/traffic"
  # Shorter and self-declared but far apart is not a repair of that message.
  page "$tmp/apart" "1875@0:the-chain-waits 1351@3600:Correction-the-chain-waits 2400@7200:unrelated"
  check "a repair outside the window is not this pair" 0 "$tmp/apart"
  # A page holding a paragraph above the ceiling: either the ceiling read is
  # stale or this is not the writer that board uses. Built by hand, because the
  # fixture above cannot produce it on purpose.
  python3 -c '
import json, sys
json.dump({"messages": [{"ts": "2026-10-24T12:00:00+00:00", "from_company": "epitome",
                         "from_seat": "pm", "subject": "one long block",
                         "body": "y" * 900}]}, open(sys.argv[1], "w"))' "$tmp/wide"
  check "a paragraph above the ceiling contradicts it" 1 "$tmp/wide"
  printf '{"error": "no such filter"}' > "$tmp/refusal"
  check "a refusal is could-not-look, not empty" 2 "$tmp/refusal"
  printf '{"messages": []}' > "$tmp/empty"
  check "an empty page is a floor, not a reading" 2 "$tmp/empty"
  exit $rc ;;

--inbox)
  # Read your own inbox before you answer your wake: the payload says what
  # happened and the board says what was said (L-A61).
  shift
  inbox "${1:-${SEAT:-exo}}" "${2:-${COMPANY:-epitome}}" "${3:-48}" "${4:-100}"
  exit $? ;;

--inbox-self-test)
  # Every branch fired against a built page, because a branch nothing has ever
  # hit decides the answer on the day it hits (L42, L-X1 as amended). The
  # fixture is the shape measured on 2026-10-24T23:0xZ: 100 rows at a limit of
  # 100, 8 of them addressed and 92 to no seat.
  tmp=$(mktemp -d) || exit 2; trap 'rm -rf "$tmp"' EXIT; rc=0
  page() {  # $1 = file, $2 = addressed count, $3 = broadcast count, $4 = limit
    PG_A=$2 PG_B=$3 PG_L=$4 python3 -c '
import json, os, sys
a, b, lim = int(os.environ["PG_A"]), int(os.environ["PG_B"]), int(os.environ["PG_L"])
rows = [{"kind": "done", "from_company": "Ursa", "from_seat": "pm",
         "subject": "a broadcast nobody addressed", "to_seat": None,
         "to_company": None} for _ in range(b)]
rows += [{"kind": "note", "from_company": "epitome", "from_seat": "pm",
          "subject": "addressed to this seat by name", "to_seat": "exo",
          "to_company": "epitome"} for _ in range(a)]
rows = rows[:lim]
json.dump({"messages": rows, "limit": lim, "saturated": len(rows) >= lim},
          open(sys.argv[1], "w"))' "$1"
  }
  check() {  # $1 = label, $2 = want exit, $3 = honest file, $4 = default file
    inbox_report "$3" "$4" exo epitome 48 > "$tmp/out" 2>&1
    local got=$?
    if [ "$got" = "$2" ]; then printf '  ok    %-46s exit %s\n' "$1" "$got"
    else printf '  FAIL  %-46s want %s got %s\n' "$1" "$2" "$got"
         sed 's/^/        /' "$tmp/out"; rc=1; fi
  }
  # The real positive: tonight's page, and the honest read of the same window.
  page "$tmp/h1" 8 0 100; page "$tmp/d1" 8 92 100
  check "default-on page cut, honest one whole" 1 "$tmp/h1" "$tmp/d1"
  # Neither cut: the window where the default costs nothing.
  page "$tmp/h2" 8 0 100; page "$tmp/d2" 8 40 100
  check "neither read filled its page" 0 "$tmp/h2" "$tmp/d2"
  # The honest page itself at its limit is a floor, not a reading.
  page "$tmp/h3" 100 0 100; page "$tmp/d3" 100 0 100
  check "honest page at its own limit" 2 "$tmp/h3" "$tmp/d3"
  # And a read that answered something other than a page.
  printf '{"error": "no such filter: everyone"}' > "$tmp/h4"
  check "a refusal is could-not-look, not empty" 2 "$tmp/h4" "$tmp/d2"
  printf 'not json at all' > "$tmp/h5"
  check "unparseable page is could-not-look" 2 "$tmp/h5" "$tmp/d2"
  exit $rc ;;


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
