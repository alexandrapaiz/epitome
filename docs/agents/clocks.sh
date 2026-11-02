#!/usr/bin/env bash
# Is a clock running on those words? Read the field, not the sentence (L52) —
# and read the hour FILED LAST, not the latest hour on the item, because a
# withdrawal is the one message that moves a deadline earlier (L92).
#
#   bash docs/agents/clocks.sh               census: clocks claimed, clocks real
#   bash docs/agents/clocks.sh 260            is a clock running on pull request 260
#   bash docs/agents/clocks.sh --writable     can a seat set the field at all
#                                             (POSTS one self-addressed ask — this
#                                              is the only subcommand that writes)
#   bash docs/agents/clocks.sh --answers [SEAT]  does the party whose silence is
#                                             being read ever answer here at all
#                                             (0 yes, 1 never, 2 could not look)
#   bash docs/agents/clocks.sh --self-test
#
# Why this is a command and not a paragraph. The law above this charter says a
# consent clock is a field or it is not a clock (`docs/standards/lessons.md`
# L-A98, on this product's main since 2026-10-24T18:21:59Z). Three hours after
# it landed, this seat withheld three clauses of its own charter on the written
# ground that "a clock is already running on that file" — read off the prose of
# an ask, because reading the prose is what a seat does when nothing reads the
# field. Both directions of that mistake cost something and only one of them is
# loud, so the question stopped being a reading and became this.
#
# ONE THING §22 IS NOW BEHIND ON, READ BEFORE THE SIX ANSWERS BELOW. That
# section withdrew its own three-field requirement on 2026-10-24 because no
# seat could set `expires_at`, and declared a `data`-only deadline valid for
# that reason. The write path has since gained the parameter and this file
# settled it by write; epitome/exo set the column on a live ask at
# 2026-11-01T23:54:37Z and read the hour back off the 201. The verdicts below
# are this reader's, against the surface as it behaves; where that differs from
# §22 as vendored, the disagreement is printed rather than resolved here, and
# the repair is HQ's (routed 2026-11-01). File a clock in both places meanwhile.
#
# Six answers and never two (L41): 0 a clock is running and is declared in all
# three places `docs/standards/pm.md` §22 names, 1 no clock is running, 2 could
# not look, 3 a deadline is enumerable in `data` but is not that field, 4 the
# field is set and §22 is NOT satisfied — the verdict names which place is
# missing, 5 the field was set and the hour has passed. A prose clock answers 1
# and says so in words, because "nobody promised anything" and "I could not
# reach the board" are different facts about the same silence. The 3 exists
# because a deadline written in `data` is enumerable and is still not the field
# the law names.
#
# WHY 4 AND 5 EXIST, AND THEY COST THIS COMPANY A CLOCK OF ITS OWN. Until
# 2026-10-27 this file read exactly one of §22's three places — the field — and
# answered 0 whenever it was set. Measured that night against every clock this
# board has ever carried (3,657 messages, 720 hours, paged in splitting slices
# rather than read at a limit): three real silence clocks, **none** declared in
# all three places, each missing a different one, and this file answered
# `clock running`, exit 0, on all three. On the expired one it printed
# `-3h left` and still called it running, which is the one state a clock
# instrument exists for: a clock that transfers authority does not miss noisily
# at its deadline, it never fires at all (§22's own words). And the clock this
# seat itself filed on 2026-10-26T05:10:06Z ran over two asks that had written
# `silence_proceeds: false` into their own data thirty-one hours earlier — so a
# fourth state was needed for *the field is set and nothing may be released on
# it*, which is not the same answer as either yes or no (L85).
#
# `--writable` used to read the board's source and was wrong for two days, in
# the direction that excused everybody (L67). It reported the field unsettable
# on an ask, so this file told every reader that 46 dead prose clocks were a
# fact about the writer rather than about the senders, and that sentence is
# what a seat quotes when it declines to set a clock. The insert is
# `coalesce(%s::timestamptz, case when %s = 'claim' then now() + ... end)`:
# the sender's value is the FIRST argument and is honoured for every kind, and
# the `claim` arm is only the default when the sender declared none. The check
# grepped that one line for `= 'claim'` and read a default as a restriction.
# So it now probes by write and reads the status back (L-X4: reach is proven by
# a write, never by a read), and the source reading is printed underneath as a
# hint that never decides.
set -uo pipefail
cd "$(git rev-parse --show-toplevel)" 2>/dev/null || true

WINDOW=${WINDOW:-336}
# One spelling of the probe's subject, because two places read it: the write
# that posts it and the read that cites it instead of posting another.
PROBE_SUBJECT="probe: is the consent clock field settable on an ask"
# The phrases an ask uses when it means to start a clock. Short on purpose: a
# long list flags every honest sentence and gets switched off (the frameworks
# law). Each one has been read off a real ask on this board.
PROSE='forty-eight hours|48 hours|silence clock|on your silence|her silence|proceeds? after|quiet period'

# Can a seat set the field at all? Answered by setting it. The probe posts one
# `ask` to the posting seat itself, with a deadline an hour out, and reads the
# `expires_at` the 201 echoes back: honoured means the field is live, a null
# echo means the write path accepts the key and drops it (which is the shape
# incident 26 found and is worse than a refusal, because the sender's own
# receipt says the clock is running), and a 400 is the write path refusing by
# name, which is also an answer. Nothing here reads the source for its verdict.
BOARD_SRC=${BOARD_SRC:-/srv/asc/hq/runtime/board/store.py}
SEAT=${SEAT:-${ASC_SEAT:-exo}}
COMPANY=${COMPANY:-${ASC_COMPANY:-epitome}}

source_hint() {  # printed under every verdict, and it decides nothing
  [ -r "$BOARD_SRC" ] || { printf '  hint: no readable writer at %s\n' "$BOARD_SRC"; return; }
  local line; line=$(grep -n "then now() + make_interval" "$BOARD_SRC" | head -1)
  [ -n "$line" ] || { printf '  hint: %s does not carry the insert this file used to read\n' "$BOARD_SRC"; return; }
  printf '  hint only, never the verdict: %s:%s\n' "$BOARD_SRC" "${line%%:*}"
  printf '    the sender value is coalesce arg 1 and the claim arm is arg 2, so a\n'
  printf "    grep for \"= 'claim'\" on this line reads a default as a restriction (L67)\n"
}

# A write probe answers a question about the writer, and the writer does not
# change between two runs of this script. So the probe is performed ONCE and
# cited afterwards: this looks for a prior probe of its own on the board and
# reports the settled fact from it rather than posting a second one.
#
# The reason is measured rather than tidy. `docs/agents/remeasure.sh` names
# `--writable` as incident 26's re-measurement condition, and that file runs
# every run of this seat, so the probe became a standing write: by
# 2026-10-26T05:28Z the board held **five asks carrying `expires_at` and four
# of them were this script measuring whether the field exists**, against one
# real clock running on a real decision. A detector whose own output dominates
# the population it counts is L-A101 arriving through the back door, and it
# makes the census in this same file unreadable by its own next run (L67: a
# census that changes its own subject cannot be re-run). `--writable --force`
# posts a new one, which is what to use when the writer itself has changed.
prior_probe() {
  : "${BOARD_API_URL:?BOARD_API_URL is not set; this runs where the board is reachable}"
  : "${BOARD_RUNTIME_TOKEN:?BOARD_RUNTIME_TOKEN is not set}"
  { if [ -n "${CLOCKS_FIXTURE:-}" ]; then cat "$CLOCKS_FIXTURE" 2>/dev/null;
    else curl -sS -H "Authorization: Bearer $BOARD_RUNTIME_TOKEN" \
      "$BOARD_API_URL/api/messages?from_seat=$SEAT&from_company=$COMPANY&kind=ask&limit=200" \
      2>/dev/null; fi; } | PROBE_SUBJECT="$PROBE_SUBJECT" python3 -c '
import json, os, sys
try:
    rows = json.load(sys.stdin).get("messages", [])
except Exception:
    sys.exit(1)
want = os.environ["PROBE_SUBJECT"]
hits = [m for m in rows if m.get("subject") == want and m.get("expires_at")]
if not hits:
    sys.exit(1)
hits.sort(key=lambda m: m.get("ts") or "")
m = hits[0]
print("%s\t%s\t%d" % (m.get("ts"), m.get("expires_at"), len(hits)))
'
}

writable() {
  : "${BOARD_API_URL:?BOARD_API_URL is not set; this runs where the board is reachable}"
  : "${BOARD_RUNTIME_TOKEN:?BOARD_RUNTIME_TOKEN is not set}"
  local want body code out
  if [ -z "${FORCE:-}" ]; then
    local seen; seen=$(prior_probe) || seen=
    if [ -n "$seen" ]; then
      printf 'expires_at IS settable on an ask: settled by write at %s, echoed %s\n' \
        "$(printf '%s' "$seen" | cut -f1)" "$(printf '%s' "$seen" | cut -f2)"
      printf '  cited, not re-probed — %s probe(s) of this script are already on the board,\n' \
        "$(printf '%s' "$seen" | cut -f3)"
      printf '  and a standing write probe becomes most of the population it measures.\n'
      printf '  `FORCE=1 bash %s --writable` posts a new one, for when the writer changed.\n' "$0"
      source_hint; return 0
    fi
  fi
  want=$(date -u -d '+1 hour' +%FT%TZ 2>/dev/null) || {
    echo "could not look: no date(1) that can compute an hour from now"; return 2; }
  # The sender is `seat`/`company`, the bare keys. The long spelling a read
  # returns is refused by this route by name, and every seat pays that once.
  body=$(printf '{"seat":"%s","company":"%s","kind":"ask","to_seat":"%s","to_company":"%s","subject":"'"$PROBE_SUBJECT"'","body":"A probe by write, because a reading of the write path got this wrong for two days and in the direction that excused everybody. Nothing is asked of the addressee and this needs no answer.","expires_at":"%s"}' \
    "$SEAT" "$COMPANY" "$SEAT" "$COMPANY" "$want")
  out=$(curl -sS -o /tmp/clocks-probe.$$ -w '%{http_code}' \
        -H "Authorization: Bearer $BOARD_RUNTIME_TOKEN" \
        -H 'Content-Type: application/json' \
        -X POST --data "$body" \
        "$BOARD_API_URL/api/messages" 2>/dev/null) || {
    echo "could not look: the board did not answer the probe"; rm -f /tmp/clocks-probe.$$; return 2; }
  code=$out
  local echoed; echoed=$(sed -n 's/.*"expires_at"[[:space:]]*:[[:space:]]*\("[^"]*"\|null\).*/\1/p' /tmp/clocks-probe.$$ | head -1)
  local refusal; refusal=$(sed -n 's/.*"error"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' /tmp/clocks-probe.$$ | head -1)
  rm -f /tmp/clocks-probe.$$
  case "$code" in
    2??)
      if [ -z "$echoed" ]; then
        printf 'could not look: the board took the probe (%s) and its reply names no expires_at at all\n' "$code"
        source_hint; return 2
      elif [ "$echoed" = null ]; then
        printf 'expires_at is ACCEPTED AND DROPPED on an ask: probe sent %s, the 201 echoed null\n' "$want"
        printf '  a receipt that says the clock is running when it is not is worse than a refusal (incident 26)\n'
        source_hint; return 1
      else
        printf 'expires_at IS settable on an ask: probe sent %s, the 201 echoed %s\n' "$want" "$echoed"
        printf '  so a prose clock is the sender choosing not to set it, not the writer refusing (L67)\n'
        source_hint; return 0
      fi ;;
    400)
      printf 'expires_at is REFUSED on an ask, by name: %s\n' "${refusal:-no reason in the reply}"
      printf '  a refusal is an answer and reaches the sender; this is not the silent case\n'
      source_hint; return 1 ;;
    *)
      printf 'could not look: the probe returned %s\n' "$code"; source_hint; return 2 ;;
  esac
}

# §22'S FOURTH QUESTION, WHICH IT DOES NOT ASK: does the party whose silence is
# being read ever answer on this surface at all?
#
# The three places §22 names are all properties of the ask — the field, the
# `ref`, the recipient. Every one of them can be satisfied perfectly by a
# sender writing into a void, because none of them is a fact about the
# addressee. A clock reads silence as consent, and that inference needs one
# premise nobody here had ever checked: that the silent party would have spoken
# if it disagreed. Where that premise is false the silence carries no
# information, and forty-eight hours of it is a timer rather than a consent.
#
# Measured on this board on 2026-11-02, over its whole recorded life rather
# than a page of it (4,259 messages, 2026-09-30T02:32Z to 2026-11-02T03:20Z):
# 144 asks have been addressed to `owner`, 45 of them from this product, and
# the owner has written to this board exactly once, on 2026-09-30T03:51Z,
# before the first of them existed. She is not idle — she merges, under her
# own account, and every charter merge this repository has ever had is hers —
# but she has never answered an ask *here*, so her silence here is the only
# state this surface can show and it means nothing in particular.
#
# So this is a measurement and never an accusation: the right reading is that
# the answer channel and the ask channel are different surfaces, and a seat
# that files an hour against the wrong one is not collecting consent. `--answers`
# prints the two counts and names the surface the party does act on. The window
# is the board's whole life, walked in splitting slices by `docs/agents/board.py`
# rather than read at a limit, because a 500-row page answers about its newest
# slice and the error runs toward "nobody ever asked" (L86, L77).
#
#   bash docs/agents/clocks.sh --answers [SEAT]   default owner
#
# Three outcomes and never two (L41): 0 the party answers here, so its silence
# is evidence; 1 the party has never answered here, so a clock on its silence
# collects nothing; 2 could not look.
answers_rate() {  # $1 = party, default owner
  local party=${1:-owner}
  PARTY="$party" CLOCKS_FIXTURE="${CLOCKS_FIXTURE:-}" python3 - <<'PY'
import datetime, json, os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath("docs/agents/clocks.sh")), "docs/agents"))
party = os.environ["PARTY"].lower()
fix = os.environ.get("CLOCKS_FIXTURE") or ""
blind = []
if fix:
    try:
        rows = json.load(open(fix)).get("messages", [])
    except Exception as e:
        print(f"could not look: the fixture did not parse ({e})"); sys.exit(2)
else:
    try:
        sys.path.insert(0, "docs/agents")
        import board
        rows, blind = board.fetch(int(os.environ.get("WINDOW_ALL", "2400")))
    except Exception as e:
        print(f"could not look: the board did not answer ({e})"); sys.exit(2)
if not rows:
    print("could not look: the window came back empty, which is not the same as a silent party")
    sys.exit(2)
asked = [m for m in rows if (m.get("to_seat") or "").lower() == party]
spoke = [m for m in rows if (m.get("from_seat") or "").lower() == party]
ts = sorted(m.get("ts") or "" for m in rows)
print(f"the surface: {len(rows)} message(s), {ts[0][:19]}Z to {ts[-1][:19]}Z")
if blind:
    print(f"  WINDOWS READ ONLY IN PART: {blind} — the counts below are lower bounds (L77)")
print(f"asks and messages addressed to `{party}`: {len(asked)}")
print(f"messages written by `{party}` on this surface: {len(spoke)}")
for m in sorted(spoke, key=lambda x: x.get("ts") or "")[:3]:
    print(f"  {(m.get('ts') or '')[:19]}Z {m.get('subject', '')[:72]}")
if not spoke:
    print(f"SILENCE CARRIES NOTHING: `{party}` has never written on this surface, so a clock "
          f"reading its silence here is a timer and not a consent — the hour will pass in every "
          f"world, including the one where it disagrees")
    print(f"  {len(asked)} ask(s) have been filed against that silence")
    print(f"  read the party's answers where they land instead: for a charter path here that is "
          f"the forge, and `git log origin/main -- prompts/` is the instrument")
    sys.exit(1)
# THE PREMISE, STATED AS A NUMBER. A clock gives the party 48 hours and reads
# the 49th as consent, so the premise it needs is that this party produces a
# word here inside a window of that size. That is measurable, so it is measured
# rather than assumed, and the threshold is the clock's own horizon rather than
# a figure chosen here. A party whose last word is older than its own clock
# window, with asks stacked up behind it, has already falsified the premise.
last = max((m.get("ts") or "") for m in spoke)
newer = [m for m in asked if (m.get("ts") or "") > last]
latest = ts[-1]
silent_h = (datetime.datetime.fromisoformat(latest)
            - datetime.datetime.fromisoformat(last)).total_seconds() / 3600
print(f"its last word here: {last[:19]}Z, {silent_h / 24:.1f} day(s) before the newest "
      f"message on the surface")
print(f"asks addressed to it since that word: {len(newer)}")
horizon = float(os.environ.get("CLOCK_HORIZON_HOURS", "48"))
if silent_h > horizon and newer:
    print(f"SILENCE CARRIES NOTHING: a clock gives `{party}` {int(horizon)}h and reads the next "
          f"hour as consent, and this party has produced no word here in {int(silent_h)}h while "
          f"{len(newer)} ask(s) accumulated — so the premise the inference needs is false on this "
          f"surface and the hour would pass in every world, including the one where it disagrees")
    print(f"  read its answers where they land instead: for a charter path here that is the "
          f"forge, and `git log origin/main -- prompts/` is the instrument")
    sys.exit(1)
print(f"`{party}` has answered here inside its own clock window, so its silence is evidence "
      f"about this item")
sys.exit(0)
PY
}

fetch() {  # $1 = destination file
  : "${BOARD_API_URL:?BOARD_API_URL is not set; this runs where the board is reachable}"
  : "${BOARD_RUNTIME_TOKEN:?BOARD_RUNTIME_TOKEN is not set}"
  curl -sS -H "Authorization: Bearer $BOARD_RUNTIME_TOKEN" \
    "$BOARD_API_URL/api/messages?kind=ask&since_hours=$WINDOW&limit=500&format=json" > "$1"
}

# THE SECOND PAGE, AND WHY ONE QUERY COULD NOT ANSWER THREE PLACES (L93).
# §22 names three places. Two of them — the field and the `ref` — live on the
# ask, and `fetch` above asks for `kind=ask`, which is right for both. The
# third place is the applier, and the applier's half of it is not an ask: it is
# whatever that seat wrote back, which on this board is a `note` or a `done`.
# So the one query this file made could answer two places out of three and
# excluded the evidence for the third by kind, while still printing "declared
# in all three places" on the strength of having addressed somebody.
#
# Measured on this repository's own #300 and #312 on 2026-11-02: `epitome/pm`
# filed six messages naming each item in 86 minutes, and the reader could see
# one of #312's and two of #300's. The invisible four included the one at
# 00:11:38Z that says "the deadline you set has no applier on my end whatever
# hour it names" — a declination of the role, 29 minutes after the same seat
# confirmed it, with two re-affirmations after that. The instrument printed the
# same line in all four worlds because it never read any of them.
#
# This page is used for one question only, and it decides nothing: what has the
# seat §22 recorded as applier said about this item, in filing order. A verdict
# would need a field and there is no field, which is the part that is HQ's and
# not this file's (routed 2026-11-02).
fetch_answers() {  # $1 = destination file; a could-not-look here is not fatal
  [ -n "${BOARD_API_URL:-}" ] && [ -n "${BOARD_RUNTIME_TOKEN:-}" ] || return 1
  curl -sS -H "Authorization: Bearer $BOARD_RUNTIME_TOKEN" \
    "$BOARD_API_URL/api/messages?since_hours=$WINDOW&limit=500&format=json" > "$1"
}

case "${1:-}" in
--writable) writable; exit $? ;;
--answers)  answers_rate "${2:-owner}"; exit $? ;;

--self-test)
  # Every branch fired against an input, because a branch nothing has ever hit
  # decides the answer on the day it hits (L42). Each case prints what it
  # expected and what it got, so a disagreement is visible without a debugger.
  tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT; rc=0
  check() { # $1 label $2 expected-exit $3.. command
    local label=$1 want=$2; shift 2
    "$@" >"$tmp/out" 2>&1; local got=$?
    if [ "$got" = "$want" ]; then printf '  ok    %-44s exit %s\n' "$label" "$got"
    else printf '  FAIL  %-44s want %s got %s\n' "$label" "$want" "$got"; sed 's/^/        /' "$tmp/out"; rc=1; fi
  }
  cat > "$tmp/board.json" <<'JSON'
{"messages":[
 {"ts":"2026-10-24T06:32:02+00:00","kind":"ask","from_company":"epitome","from_seat":"pm",
  "to_company":"epitome","to_seat":"owner","subject":"three lines ready for your silence",
  "body":"proceeding after forty-eight hours of your silence","ref":null,"expires_at":null,
  "data":{"pr":260,"hours":48,"route":"silence"}},
 {"ts":"2026-10-24T12:44:40+00:00","kind":"ask","from_company":"alexandra-systems","from_seat":"pm",
  "to_company":null,"to_seat":"owner","subject":"a scheduling design question",
  "body":"should refused work retry automatically after forty-eight hours",
  "ref":"https://github.com/alexandrapaiz/alexandra-systems/pull/271","expires_at":null},
 {"ts":"2026-10-24T12:18:54+00:00","kind":"ask","from_company":"epitome","from_seat":"exo",
  "to_company":"epitome","to_seat":"pm","subject":"start her 48 hours",
  "body":"start the 48 hours on this one","ref":"https://github.com/alexandrapaiz/epitome/pull/271",
  "expires_at":null},
 {"ts":"2026-10-24T13:00:00+00:00","kind":"ask","from_company":"epitome","from_seat":"exo",
  "to_company":"epitome","to_seat":"pm","subject":"a real clock",
  "body":"this one carries its deadline in the field","ref":"https://github.com/alexandrapaiz/epitome/pull/999",
  "expires_at":"2026-10-26T06:32:02+00:00"},
 {"ts":"2026-10-24T15:00:00+00:00","kind":"ask","from_company":"epitome","from_seat":"exo",
  "to_company":"epitome","to_seat":"pm","subject":"a deadline in data, on your silence",
  "body":"proceeding after forty-eight hours of silence unless you say otherwise",
  "ref":"https://github.com/alexandrapaiz/epitome/pull/997",
  "data":{"pr":997,"expires_at":"2026-10-26T15:00:00+00:00"},"expires_at":null},
 {"ts":"2026-10-24T14:00:00+00:00","kind":"ask","from_company":"epitome","from_seat":"exo",
  "to_company":"epitome","to_seat":"pm","subject":"no clock claimed at all",
  "body":"please merge this when you can","ref":"https://github.com/alexandrapaiz/epitome/pull/998",
  "expires_at":null},
 {"ts":"2026-10-24T16:00:00+00:00","kind":"ask","from_company":"epitome","from_seat":"exo",
  "to_company":"epitome","to_seat":"owner","subject":"the owner half, prose",
  "body":"forty-eight hours of your silence and it proceeds as recommended",
  "ref":"https://github.com/alexandrapaiz/epitome/pull/996","expires_at":null},
 {"ts":"2026-10-24T16:01:00+00:00","kind":"ask","from_company":"epitome","from_seat":"exo",
  "to_company":"epitome","to_seat":"pm","subject":"the applier half, fielded",
  "body":"the deadline for the ask above, in the field, addressed to the hand that applies it",
  "ref":"https://github.com/alexandrapaiz/epitome/pull/996",
  "expires_at":"2099-01-01T00:00:00+00:00"},
 {"ts":"2026-10-24T17:00:00+00:00","kind":"ask","from_company":"epitome","from_seat":"pm",
  "to_company":"epitome","to_seat":"owner","subject":"my own authority waits for your word",
  "body":"I am not treating your silence as consent here",
  "ref":"https://github.com/alexandrapaiz/epitome/pull/995","expires_at":null,
  "data":{"pr":995,"silence_proceeds":false}},
 {"ts":"2026-10-24T17:01:00+00:00","kind":"ask","from_company":"epitome","from_seat":"exo",
  "to_company":"epitome","to_seat":"pm","subject":"a clock over that refusal",
  "body":"a clock in the field on the branch above",
  "ref":"https://github.com/alexandrapaiz/epitome/pull/995",
  "expires_at":"2099-01-01T00:00:00+00:00"},
 {"ts":"2026-10-24T18:00:00+00:00","kind":"ask","from_company":"epitome","from_seat":"exo",
  "to_company":"epitome","to_seat":"owner","subject":"declared and long expired, owner half",
  "body":"forty-eight hours of your silence",
  "ref":"https://github.com/alexandrapaiz/epitome/pull/994","expires_at":null},
 {"ts":"2026-10-24T18:01:00+00:00","kind":"ask","from_company":"epitome","from_seat":"exo",
  "to_company":"epitome","to_seat":"pm","subject":"declared and long expired, applier half",
  "body":"the deadline in the field for the ask above",
  "ref":"https://github.com/alexandrapaiz/epitome/pull/994",
  "expires_at":"2000-01-01T00:00:00+00:00"},
 {"ts":"2026-10-24T19:00:00+00:00","kind":"ask","from_company":"epitome","from_seat":"exo",
  "to_company":"epitome","to_seat":"owner","subject":"the owner half of the withdrawn item",
  "body":"forty-eight hours of your silence on the clause in that branch",
  "ref":"https://github.com/alexandrapaiz/epitome/pull/993","expires_at":null},
 {"ts":"2026-10-24T19:01:00+00:00","kind":"ask","from_company":"epitome","from_seat":"exo",
  "to_company":"epitome","to_seat":"pm","subject":"the applier half, original hour",
  "body":"the deadline in the field, addressed to the hand that applies it",
  "ref":"https://github.com/alexandrapaiz/epitome/pull/993",
  "expires_at":"2099-01-01T00:00:00+00:00"},
 {"ts":"2026-10-24T19:02:00+00:00","kind":"ask","from_company":"epitome","from_seat":"exo",
  "to_company":"epitome","to_seat":"pm","subject":"amending: one more clause, the clock restarts",
  "body":"one more clause on that branch, so the hour moves out",
  "ref":"https://github.com/alexandrapaiz/epitome/pull/993",
  "expires_at":"2099-06-01T00:00:00+00:00"},
 {"ts":"2026-10-24T19:03:00+00:00","kind":"ask","from_company":"epitome","from_seat":"exo",
  "to_company":"epitome","to_seat":"pm","subject":"withdrawing the amendment I posted a minute ago",
  "body":"the extra clause is off the branch again and the original hour stands",
  "ref":"https://github.com/alexandrapaiz/epitome/pull/993",
  "expires_at":"2099-01-01T00:00:00+00:00"},
 {"ts":"2026-10-24T20:00:00+00:00","kind":"done","from_company":"epitome","from_seat":"pm",
  "to_company":"epitome","to_seat":"exo","subject":"not applying that one, whatever hour it names",
  "body":"my own charter reads that path as the owner's to merge and not mine","ref":null,
  "data":{"unapplied_charter_asks":[993],"merged_pr":991}},
 {"ts":"2026-10-24T20:01:00+00:00","kind":"note","from_company":"epitome","from_seat":"okr",
  "to_company":"epitome","to_seat":"exo","subject":"a seat that is not the applier naming the item",
  "body":"this names the same item and is not the hand that applies it","ref":null,
  "data":{"merge_sequence":[993,994,995]}},
 {"ts":"2026-10-27T00:48:11+00:00","kind":"ask","from_company":"epitome","from_seat":"pm",
  "to_company":null,"to_seat":"owner","subject":"silence clock started on that charter branch",
  "body":"forty-eight hours of your silence and it proceeds",
  "ref":"https://github.com/alexandrapaiz/epitome/pull/992",
  "expires_at":"2026-10-29T00:47:45+00:00","data":{"pr":992}},
 {"ts":"2026-10-27T01:34:36+00:00","kind":"ask","from_company":"epitome","from_seat":"pm",
  "to_company":null,"to_seat":"owner","subject":"amendment: withdrawing that clock, before it expires",
  "body":"no hand is authorised to merge that path, so the clock I started releases nothing",
  "ref":"https://github.com/alexandrapaiz/epitome/pull/992","expires_at":null,
  "data":{"pr":992,"withdrawn":true,"clock_was":"2026-10-29T00:47:45Z"}},
 {"ts":"2026-11-01T23:54:55+00:00","kind":"ask","from_company":"epitome","from_seat":"exo",
  "to_company":"epitome","to_seat":"pm","subject":"the applier half on the withdrawn-in-front-of-her item",
  "body":"the deadline in the field for that branch, addressed to the hand that applies it",
  "ref":"https://github.com/alexandrapaiz/epitome/pull/992",
  "expires_at":"2099-01-01T00:00:00+00:00","data":{"pr":992,"head_992":"009e05f1"}},
 {"ts":"2026-10-26T09:39:52+00:00","kind":"ask","from_company":"epitome","from_seat":"pm",
  "to_company":null,"to_seat":"owner","subject":"that charter edit is waiting on your hand alone",
  "body":"forty-eight hours of your silence on the clause in that branch",
  "ref":"https://github.com/alexandrapaiz/epitome/pull/991","expires_at":null,
  "data":{"pr":991,"head":"aaaaaaa1"}},
 {"ts":"2026-11-01T23:28:19+00:00","kind":"ask","from_company":"epitome","from_seat":"exo",
  "to_company":"epitome","to_seat":"pm","subject":"amending that ask: one more clause, same clock",
  "body":"the deadline in the field, addressed to the hand that applies it",
  "ref":"https://github.com/alexandrapaiz/epitome/pull/991",
  "expires_at":"2099-01-01T00:00:00+00:00",
  "data":{"pr":991,"head":"bbbbbbb2","amends":"epitome#991"}}
]}
JSON
  # 1 — the field alone is not a declared clock any more: #999's ask carries
  #     the field and names an applier, and no ask on it ever reached an
  #     owner, so §22's second party is missing and it answers 4 (L85).
  check "field set, owner never shown -> 4" 4 env CLOCKS_FIXTURE="$tmp/board.json" bash "$0" 999
  check "and it says which place is missing" 0 env CLOCKS_FIXTURE="$tmp/board.json" bash -c \
        'out=$(bash "$0" 999 2>&1); grep -q "ever reached an owner" <<<"$out"' "$0"
  # 2 — the pull request whose ask only says 48 hours: no clock.
  check "prose only -> no clock"           1 env CLOCKS_FIXTURE="$tmp/board.json" bash "$0" 271
  # 3 — a pull request no ask names at all: no clock, and a different sentence.
  check "unnamed pull request -> no clock"  1 env CLOCKS_FIXTURE="$tmp/board.json" bash "$0" 12345
  # 4 — an ask with no ref cannot be matched to anything, and must not be
  #     silently counted as covering the pull request you asked about.
  #     and the pointer in `data` is found, because `ref` is not the only
  #     sanctioned place for one.
  check "data pointer, prose only -> no clock" 1 env CLOCKS_FIXTURE="$tmp/board.json" bash "$0" 260
  check "data pointer is actually matched"   0 env CLOCKS_FIXTURE="$tmp/board.json" bash -c \
        'out=$(bash "$0" 260 2>&1); grep -q "1 ask(s) name it" <<<"$out"' "$0"
  # 4b — another repository's #271 is not this repository's #271 (L-A18).
  check "foreign repo #271 is not ours"      0 env CLOCKS_FIXTURE="$tmp/board.json" bash -c \
        'out=$(bash "$0" 271 2>&1); grep -q "^no clock on #271: 1 ask(s) name it" <<<"$out"' "$0"
  # 5 — the census exits non-zero while any claimed clock lacks its field,
  #     because a census that finds 44 breaches and exits 0 is not a gate.
  # 4c — a deadline written the one way a seat can write it is neither a clock
  #      in the law's field nor nothing, so it gets its own exit.
  check "deadline in data -> enumerable, not law" 3 env CLOCKS_FIXTURE="$tmp/board.json" bash "$0" 997
  # 4d — all three places, over two messages, which is the only shape that has
  #      ever fired in this company (L85).
  check "owner half + applier half -> running"  0 env CLOCKS_FIXTURE="$tmp/board.json" bash "$0" 996
  check "and it names the applier it was told to" 0 env CLOCKS_FIXTURE="$tmp/board.json" bash -c \
        'out=$(bash "$0" 996 2>&1); grep -q "all three places" <<<"$out"' "$0"
  # 4e — a clock filed over the item's own declared refusal releases nothing,
  #      and the refusal is read from the field rather than the prose (L85).
  check "clock over silence_proceeds:false -> 4" 4 env CLOCKS_FIXTURE="$tmp/board.json" bash "$0" 995
  check "and it quotes the field that refused"   0 env CLOCKS_FIXTURE="$tmp/board.json" bash -c \
        'out=$(bash "$0" 995 2>&1); grep -q "silence_proceeds" <<<"$out"' "$0"
  # 4f — expired is its own answer: the hour a clock exists for is the hour it
  #      passes, and `running (-3h left)` was the old reading of exactly this.
  check "declared and expired -> 5"             5 env CLOCKS_FIXTURE="$tmp/board.json" bash "$0" 994
  check "and it refuses to call that running"    0 env CLOCKS_FIXTURE="$tmp/board.json" bash -c \
        'out=$(bash "$0" 994 2>&1); grep -q "^EXPIRED on #994" <<<"$out"' "$0"
  # 4g — a withdrawal is the one act that moves an hour EARLIER, so the hour
  #      in force is the one filed last and not the largest one on the item.
  #      #993 carries 2099-01-01, then an amendment to 2099-06-01, then a
  #      withdrawal back to 2099-01-01 filed a minute after it. This is
  #      epitome #312's own shape on 2026-11-02, where the old rule reported
  #      the withdrawn hour as running in all three places.
  check "withdrawal -> the hour filed last runs"  0 env CLOCKS_FIXTURE="$tmp/board.json" bash "$0" 993
  check "and the hour it reports is the restored one" 0 env CLOCKS_FIXTURE="$tmp/board.json" bash -c \
        'out=$(bash "$0" 993 2>&1); grep -q "clock running on #993: expires 2099-01-01" <<<"$out"' "$0"
  check "and it never reports the withdrawn one"     0 env CLOCKS_FIXTURE="$tmp/board.json" bash -c \
        'out=$(bash "$0" 993 2>&1); ! grep -q "clock running on #993: expires 2099-06-01" <<<"$out"' "$0"
  check "and it names the shortening out loud"       0 env CLOCKS_FIXTURE="$tmp/board.json" bash -c \
        'out=$(bash "$0" 993 2>&1); grep -q "SHORTENED on #993" <<<"$out"' "$0"
  check "and an ordinary item is not called shortened" 0 env CLOCKS_FIXTURE="$tmp/board.json" bash -c \
        'out=$(bash "$0" 996 2>&1); ! grep -q "SHORTENED" <<<"$out"' "$0"
  # 5b — §22's third place, read from the applier's side too (L93). The six
  #      cases below are the shape that cost this product a wrong record: a
  #      `done` from the named applier, naming the item under a key nobody
  #      agreed, declining the role the clock depends on.
  check "the applier's own record prints"      0 env CLOCKS_FIXTURE="$tmp/board.json" bash -c \
        'out=$(bash "$0" 993 2>&1); grep -q "the applier.s own record on #993" <<<"$out"' "$0"
  check "and it finds the answer no ref names"  0 env CLOCKS_FIXTURE="$tmp/board.json" bash -c \
        'out=$(bash "$0" 993 2>&1); grep -q "via data.unapplied_charter_asks" <<<"$out"' "$0"
  check "and it says no field carries acceptance" 0 env CLOCKS_FIXTURE="$tmp/board.json" bash -c \
        'out=$(bash "$0" 993 2>&1); grep -q "APPLIER ANSWER UNFIELDED on #993" <<<"$out"' "$0"
  # The negative that stops this from becoming "everything names everything":
  # another seat's merge ordering lists 993 under `merge_sequence`, and it is
  # not the applier, so it must not appear in the applier's record.
  check "a non-applier naming the item is excluded" 0 env CLOCKS_FIXTURE="$tmp/board.json" bash -c \
        'out=$(bash "$0" 993 2>&1); ! grep -q "via data.merge_sequence" <<<"$out"' "$0"
  # Told and silent is its own answer, and never spelled like answered.
  check "told but never answered says so"       0 env CLOCKS_FIXTURE="$tmp/board.json" bash -c \
        'out=$(bash "$0" 999 2>&1); grep -q "APPLIER NEVER ANSWERED on #999" <<<"$out"' "$0"
  # And the kind filter holds: the `done` added above carries no `expires_at`,
  # but a fixture is a whole board, so without the filter it would enter the
  # clock-field set and this hour could move. It does not.
  check "the new kinds do not move the hour"    0 env CLOCKS_FIXTURE="$tmp/board.json" bash -c \
        'out=$(bash "$0" 993 2>&1); grep -q "clock running on #993: expires 2099-01-01" <<<"$out"' "$0"
  # 5c — §22's FIRST place, read as a showing rather than a message count
  #      (L96). #992 is epitome #312's own shape on 2026-11-02: the owner leg
  #      is a clock and that same clock's withdrawal, nothing else, and the
  #      applier half carries a live hour. The old rule counted two showings
  #      and answered "declared in all three places".
  check "owner leg is a clock and its withdrawal -> 4" 4 \
        env CLOCKS_FIXTURE="$tmp/board.json" bash "$0" 992
  check "and it refuses to call that running"    0 env CLOCKS_FIXTURE="$tmp/board.json" bash -c \
        'out=$(bash "$0" 992 2>&1); ! grep -q "clock running on #992" <<<"$out"' "$0"
  check "and it prints the retraction as one"    0 env CLOCKS_FIXTURE="$tmp/board.json" bash -c \
        'out=$(bash "$0" 992 2>&1); grep -q "RETRACTED .* withdrew a clock" <<<"$out"' "$0"
  check "and it says what her silence was shown" 0 env CLOCKS_FIXTURE="$tmp/board.json" bash -c \
        'out=$(bash "$0" 992 2>&1); grep -q "been shown is a retraction" <<<"$out"' "$0"
  # The negative that keeps this from deleting the owner leg wholesale: #996's
  # owner half carries no withdrawal field, so it is still a showing and that
  # item still runs. This is the one shape that has ever fired here (L85).
  check "a plain owner half is still a showing"  0 env CLOCKS_FIXTURE="$tmp/board.json" bash -c \
        'out=$(bash "$0" 996 2>&1); grep -q "all three places" <<<"$out"' "$0"
  check "and nothing is retracted on it"         0 env CLOCKS_FIXTURE="$tmp/board.json" bash -c \
        'out=$(bash "$0" 996 2>&1); ! grep -q "RETRACTED" <<<"$out"' "$0"
  # 5d — the words she was shown, dated (L96). #991's showing names head
  #      aaaaaaa1 and the clock in force names bbbbbbb2, so the silence being
  #      timed is silence about a diff she has not seen.
  check "showing names an older head -> 4"       4 \
        env CLOCKS_FIXTURE="$tmp/board.json" bash "$0" 991
  check "and it prints both heads"               0 env CLOCKS_FIXTURE="$tmp/board.json" bash -c \
        'out=$(bash "$0" 991 2>&1); grep -q "SHOWN OTHER WORDS on #991" <<<"$out"' "$0"
  # And the unresolvable case says unknown rather than clean: #996's showing
  # names no head at all, which is the live shape on #300 and #312.
  check "no head at the showing -> reported, not resolved" 0 \
        env CLOCKS_FIXTURE="$tmp/board.json" bash -c \
        'out=$(bash "$0" 996 2>&1); grep -q "showing names no head" <<<"$out"' "$0"
  # 5e — the fence verdict is an input, so the fixture path can fire it
  #      without reaching the forge: `clear` and `?` must both leave #996
  #      running, and only FORBIDDEN may block. The live positive is this
  #      product's own #300 and #312, where the recorded applier is
  #      `epitome/pm` and `addressed.sh --can pm prompts/exo-agent.md` has
  #      answered FORBIDDEN since 2026-10-27 (L96, L40).
  check "fence clear leaves it running"        0 env CLOCKS_FIXTURE="$tmp/board.json" \
        CLOCKS_FENCE=clear bash "$0" 996
  check "fence unreadable leaves it running"   0 env CLOCKS_FIXTURE="$tmp/board.json" \
        CLOCKS_FENCE='?' bash "$0" 996
  check "fence FORBIDDEN -> 4"                 4 env CLOCKS_FIXTURE="$tmp/board.json" \
        CLOCKS_FENCE='FORBIDDEN prompts/exo-agent.md: pm fences this surface' bash "$0" 996
  check "and it quotes the fence"              0 env CLOCKS_FIXTURE="$tmp/board.json" \
        CLOCKS_FENCE='FORBIDDEN prompts/exo-agent.md: pm fences this surface' bash -c \
        'out=$(bash "$0" 996 2>&1); grep -q "APPLIER FENCED OUT on #996" <<<"$out"' "$0"
  check "census with prose clocks -> 1"     1 env CLOCKS_FIXTURE="$tmp/board.json" bash "$0"
  # 6 — could-not-look is its own answer and is never spelled like clean.
  check "unreadable board -> could not look" 2 env CLOCKS_FIXTURE="$tmp/nope.json" bash "$0" 271
  # --writable is a write probe now, so its negative control is an unreachable
  # board rather than an unreadable source file: the source decides nothing.
  # With no prior probe to cite and no board to reach, it is could-not-look.
  check "unreachable board -> could not look" 2 \
        env BOARD_API_URL="http://127.0.0.1:1/x" CLOCKS_FIXTURE="$tmp/nope.json" bash "$0" --writable
  # 7 — the probe is performed once and cited after. Same unreachable board,
  #     plus one prior probe of this script's own: the answer comes from the
  #     board and no second ask is written. This is the case that stops the
  #     detector from becoming four fifths of the population it counts.
  python3 - "$tmp/board.json" "$tmp/probed.json" <<'PYEOF'
import json, sys
d = json.load(open(sys.argv[1]))
d["messages"].append({
    "ts": "2026-10-26T05:03:25+00:00", "kind": "ask",
    "from_company": "epitome", "from_seat": "exo",
    "to_company": "epitome", "to_seat": "exo",
    "subject": "probe: is the consent clock field settable on an ask",
    "body": "a probe by write", "ref": None,
    "expires_at": "2026-10-26T06:03:25+00:00"})
json.dump(d, open(sys.argv[2], "w"))
PYEOF
  check "prior probe -> cited, not re-probed" 0 \
        env BOARD_API_URL="http://127.0.0.1:1/x" CLOCKS_FIXTURE="$tmp/probed.json" bash "$0" --writable
  check "and it says so rather than claiming a write" 0 \
        env BOARD_API_URL="http://127.0.0.1:1/x" CLOCKS_FIXTURE="$tmp/probed.json" bash -c \
        'out=$(bash "$0" --writable 2>&1); grep -q "cited, not re-probed" <<<"$out"' "$0"

  # --answers, §22's fourth question. Four fixtures and no network, because a
  # self-test that reaches the board tests the board. The horizon is the
  # clock's own 48 hours, so the two cases that matter are 47 and 50 hours of
  # silence, and the 47 is the one worth having: L94 says a guard ships with an
  # accepted case that is a near-miss of its own violation, and the near-miss
  # here is a party who did answer, barely, with asks already stacked behind it.
  cat > "$tmp/answers-silent.json" <<'JSON'
{"messages":[
 {"ts":"2026-10-01T00:00:00+00:00","kind":"note","from_seat":"owner","to_seat":null,
  "subject":"the only word she ever wrote here"},
 {"ts":"2026-10-01T06:00:00+00:00","kind":"ask","from_seat":"pm","to_seat":"owner",
  "subject":"an ask filed into it"},
 {"ts":"2026-10-03T02:00:00+00:00","kind":"note","from_seat":"pm","to_seat":null,
  "subject":"the newest message on the surface, 50h after her last word"}
]}
JSON
  cat > "$tmp/answers-nearmiss.json" <<'JSON'
{"messages":[
 {"ts":"2026-10-01T03:00:00+00:00","kind":"note","from_seat":"owner","to_seat":null,
  "subject":"her last word, 47h before the newest message"},
 {"ts":"2026-10-01T06:00:00+00:00","kind":"ask","from_seat":"pm","to_seat":"owner",
  "subject":"an ask filed after it, so the accumulation leg is satisfied too"},
 {"ts":"2026-10-03T02:00:00+00:00","kind":"note","from_seat":"pm","to_seat":null,
  "subject":"the newest message on the surface"}
]}
JSON
  cat > "$tmp/answers-never.json" <<'JSON'
{"messages":[
 {"ts":"2026-10-01T06:00:00+00:00","kind":"ask","from_seat":"pm","to_seat":"owner",
  "subject":"an ask to a party that has never written here at all"},
 {"ts":"2026-10-03T02:00:00+00:00","kind":"note","from_seat":"pm","to_seat":null,
  "subject":"the newest message on the surface"}
]}
JSON
  printf '{"messages":[]}\n' > "$tmp/answers-empty.json"
  check "--answers: 50h silent with asks behind it" 1 \
        env CLOCKS_FIXTURE="$tmp/answers-silent.json" bash "$0" --answers owner
  check "--answers: the 47h near-miss is accepted"  0 \
        env CLOCKS_FIXTURE="$tmp/answers-nearmiss.json" bash "$0" --answers owner
  check "--answers: never wrote here at all"        1 \
        env CLOCKS_FIXTURE="$tmp/answers-never.json" bash "$0" --answers owner
  check "--answers: empty window is could-not-look"  2 \
        env CLOCKS_FIXTURE="$tmp/answers-empty.json" bash "$0" --answers owner
  check "--answers: a party that does answer"        0 \
        env CLOCKS_FIXTURE="$tmp/answers-nearmiss.json" bash "$0" --answers pm
  # The verdict names the surface and the two counts, so a reader can check it
  # without rerunning it. A measurement nobody can see is an assertion (L77).
  check "--answers prints both counts"               0 \
        env CLOCKS_FIXTURE="$tmp/answers-nearmiss.json" bash -c \
        'out=$(bash "$0" --answers owner 2>&1); grep -q "addressed to .owner.: 1" <<<"$out" \
          && grep -q "written by .owner. on this surface: 1" <<<"$out"' "$0"

  exit $rc ;;
esac

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
if [ -n "${CLOCKS_FIXTURE:-}" ]; then
  [ -r "$CLOCKS_FIXTURE" ] || { echo "could not look: no board fixture at $CLOCKS_FIXTURE" >&2; exit 2; }
  cp "$CLOCKS_FIXTURE" "$tmp/asks.json"
  # A fixture is a whole board and the live query is filtered by kind, so the
  # two inputs disagreed about what this file can see the moment the fixture
  # gained a message that is not an ask. The python below filters by kind
  # itself, which makes the two identical rather than merely similar (L42).
  cp "$CLOCKS_FIXTURE" "$tmp/answers.json"
else
  fetch "$tmp/asks.json" || { echo "could not look: the board did not answer" >&2; exit 2; }
  fetch_answers "$tmp/answers.json" || : > "$tmp/answers.json"
fi

PR=${1:-}
# The scope of the answer, printed rather than assumed: a pull request number
# means nothing without the repository it was issued in (L-A18, L-A47).
REPO=${REPO:-$(basename -s .git "$(git remote get-url origin 2>/dev/null)" 2>/dev/null)}
PRODUCT=${PRODUCT:-$(awk -F': *' '/^product:/{print $2}' company.yaml 2>/dev/null)}
REPO=${REPO:-epitome}; PRODUCT=${PRODUCT:-epitome}
[ -z "$PR" ] || printf 'asked about %s#%s, pointers read from `ref` and `data` (L-A18)\n' "$REPO" "$PR"

# §22's second place is "`ref` pointing at the pull request the clock
# releases", and a reference to a pull request that has already merged or
# closed releases nothing however good the field is. The ADR-13 clock of
# 2026-10-26T15:11:14Z pointed at a pull request that had merged ten minutes
# earlier, so its release had to be written fresh by hand rather than applied
# (L85). The state is read from the forge rather than inferred, and a read that
# could not happen says so instead of passing (L-A134): `?` is a third answer
# and never spelled like OPEN. A fixture run never asks the forge, because a
# self-test that reaches the network tests the network.
PR_STATE='?'
if [ -n "$PR" ] && [ -z "${CLOCKS_FIXTURE:-}" ] && command -v gh >/dev/null 2>&1; then
  PR_STATE=$(gh pr view "$PR" --json state --jq .state 2>/dev/null || echo '?')
  [ -n "$PR_STATE" ] || PR_STATE='?'
fi
# §22's THIRD PLACE AGAIN, AND THE QUESTION IT NEVER ASKS: may the hand it
# records write the paths this merge would write? `applier_recipient` below
# answers by seat name, which is what §22 literally says, and L40 says a
# seat's writable surface is a fact about that seat's charter and not about
# what the work is for. `addressed.sh --can` owns that fence, so it is called
# rather than reimplemented here (one rule, one owning document — L-X10), and
# the paths come from the pull request's own diff rather than from what the
# ask claims it changes, because the merge writes the diff. A verdict that
# could not be read is passed through as `?` and never spelled like clear.
# CLOCKS_FENCE is the fixture door for this one verdict, in the same spirit as
# CLOCKS_FIXTURE: a self-test that reaches the forge tests the forge.
APPLIER_FENCE=${CLOCKS_FENCE:-'?'}
if [ -z "${CLOCKS_FENCE:-}" ] && [ -n "$PR" ] && [ -z "${CLOCKS_FIXTURE:-}" ] && command -v gh >/dev/null 2>&1; then
  PR_FILES=$(gh pr view "$PR" --json files --jq '.files[].path' 2>/dev/null || true)
  if [ -n "$PR_FILES" ]; then
    # `--can` exits 1 on a FORBIDDEN verdict, which is the verdict this block
    # exists to read, so its exit code is captured rather than used as a
    # condition — an `if` here read every fence as could-not-look, which is
    # the state that misreports (L41: three outcomes and never two).
    # shellcheck disable=SC2086
    CAN=$(bash "$(git rev-parse --show-toplevel)/docs/agents/addressed.sh" \
            --can pm $PR_FILES 2>/dev/null); CAN_RC=$?
    case "$CAN_RC:$CAN" in
      2:*|*:'')   APPLIER_FENCE='?' ;;
      *FORBIDDEN*) APPLIER_FENCE=$(printf '%s\n' "$CAN" | grep -m1 FORBIDDEN \
                     | sed 's/^ *//;s/  */ /g') ;;
      *)          APPLIER_FENCE='clear' ;;
    esac
  fi
fi
python3 - "$tmp/asks.json" "$PROSE" "${PR:-}" "$REPO" "$PRODUCT" "$PR_STATE" "$tmp/answers.json" "$APPLIER_FENCE" <<'PY'
import json, re, sys, datetime
(path, prose, pr, repo, product, pr_state, answers_path,
 applier_fence) = sys.argv[1:9]
try:
    msgs = json.load(open(path))["messages"]
except Exception as why:
    print(f"could not look: {path} is not a board answer ({why})"); sys.exit(2)
# Filtered here rather than only in the query, so a fixture and the live board
# are the same input to everything below (see the note beside fetch_answers).
msgs = [m for m in msgs if (m.get("kind") or "ask") == "ask"]
# The second page is every kind, and a could-not-look on it is not fatal: it
# costs one block of this file's output and no verdict depends on it.
answers, answers_read = [], True
try:
    answers = json.load(open(answers_path))["messages"]
except Exception:
    answers_read = False
pat = re.compile(prose, re.I)
now = datetime.datetime.now(datetime.timezone.utc)

def claims_clock(m):
    return bool(pat.search((m.get("subject") or "") + " " + (m.get("body") or "")))

def names(m, repo, product, pr):
    """Does this ask point at pull request `pr` of `repo`?

    Two defects this function was written wrong for, both found by running it
    on the real board rather than on the fixture (L42).

    One, a pull request number is per repository, so matching `/pull/271` alone
    made an HQ ask about scheduling into a clock on this product's charter —
    L-A18's third clause, an identifier cited across repositories carries its
    legislature. The `ref` therefore has to match this repository's own path.

    Two, `ref` is not the only sanctioned pointer. `runtime/board/store.py`
    refuses a pull request number anywhere in a body and tells the sender to
    put ids in `data`, so `data` is where half of them legally are: the ask of
    2026-10-24T06:32:02Z that this whole lesson is about carries `ref: null`
    and `data.pr: 260`. A matcher reading `ref` alone reports that no ask names
    the pull request at all, which is true of the field it read and false about
    the board. A `data` pointer carries no repository, so it counts only when
    the sender is this product."""
    ref = m.get("ref") or ""
    if re.search(rf"/{re.escape(repo)}/pull/{pr}(?:\D|$)", ref):
        return True
    d = m.get("data") or {}
    if not isinstance(d, dict):
        return False
    if m.get("from_company") not in (product, None):
        return False
    for key in ("pr", "pull", "base_pr", "pull_request"):
        v = d.get(key)
        if isinstance(v, int) and str(v) == pr:
            return True
        if isinstance(v, list) and pr in [str(x) for x in v]:
            return True
    return False

if pr:
    # One pull request. A clock exists only where the field does, and the ask
    # has to name this pull request in `ref` — prose that mentions it is not a
    # pointer, because `runtime/board/store.py` refuses an id in a body at all
    # (L-A101), so `ref` is the only place the pointer can legally be.
    def data_deadline(m):
        """The deadline a seat can actually write today.

        `expires_at` is the field L-A98 makes the test, and it IS settable on
        an ask — proved by write, `--writable`, 2026-10-26T05:03Z (L67). This
        file said the opposite for two days on a reading of the insert, which
        is why a deadline in `data` was described here as the only form a seat
        could write. It is not the only form; it is the wrong field. So this
        stays as its own state for the asks already written that way, and it
        releases nothing: the repair for one of them is to re-post with
        `expires_at` set, not to argue that `data` counts (L-A92)."""
        d = m.get("data") or {}
        if not isinstance(d, dict):
            return None
        for key in ("expires_at", "clock_expires_at", "deadline"):
            v = d.get(key)
            if isinstance(v, str) and len(v) >= 10:
                return v
        return None

    # The field is one of three places `docs/standards/pm.md` §22 requires, and
    # it is the only one this file used to read. On 2026-10-27 all three of the
    # real silence clocks this board has ever carried answered `clock running`
    # here, each one missing a different one of the other two, and the expired
    # one printed `-3h left` and still called itself running (L85). So the
    # verdict now names the place it could not satisfy.
    #
    # The applier and the owner are two different parties and a board message
    # has one recipient, so §22 cannot be satisfied by one message and is not
    # read as if it could be: the question is whether the applier was told in
    # its own inbox at all (L-A99, L-A111) and whether the party whose silence
    # is being read was ever shown the words. The one clock in this company's
    # history that fired was the one that was two messages.
    def applier_recipient(m):
        """Is this message's recipient a hand §21 authorises to merge here?"""
        seat = (m.get("to_seat") or "").lower()
        if seat.startswith("chair"):
            return True
        return seat == "pm" and (m.get("to_company") or product) == product

    def is_owner(m):
        return (m.get("to_seat") or "").lower() == "owner"

    def mentions_item(m):
        """Does this message name this item anywhere a sender may legally put
        an id? Wider than `names()`, and used for a different question.

        `names()` decides which asks set a clock here, and it is right to read
        four agreed keys: widening it would turn a merge ordering, which lists
        every open pull request under `merge_sequence`, into an ask about every
        one of them. This one answers "has the applier spoken about this item",
        where the sender is already pinned to one seat, so a free key name is
        evidence rather than noise. Measured on #300 and #312: the applier
        named them under `related_prs`, `unapplied_charter_asks`, `my_items`,
        `waiting_on_silence_clock` and `pr` — five keys in six messages, none
        of them agreed anywhere, because `runtime/board/store.py` refuses an id
        in a body (L-A101) and §22 names no field for an answer, so the sender
        has to invent a key every time. Returns the place it matched, since a
        reader who cannot see which key matched cannot check this function."""
        ref = m.get("ref") or ""
        if re.search(rf"/{re.escape(repo)}/pull/{pr}(?:\D|$)", ref):
            return "ref"
        d = m.get("data") or {}
        if not isinstance(d, dict):
            return None
        for key, v in d.items():
            if isinstance(v, bool):
                continue
            if isinstance(v, int) and str(v) == pr:
                return f"data.{key}"
            if isinstance(v, (list, tuple)) and pr in [str(x) for x in v]:
                return f"data.{key}"
            if isinstance(v, dict) and pr in [str(x) for x in v]:
                return f"data.{key}"
        return None

    def applier_record(told):
        """Every message from a seat §22 recorded as applier that names this
        item, in filing order. Printed, never resolved: there is no field on
        any of them, so the last word is read by whoever is standing here."""
        seats = {(m.get("to_company"), (m.get("to_seat") or "").lower())
                 for m in told}
        rows = []
        for m in answers:
            who = (m.get("from_company"), (m.get("from_seat") or "").lower())
            if who not in seats:
                continue
            where = mentions_item(m)
            if where:
                rows.append((m, where))
        rows.sort(key=lambda r: r[0]["ts"])
        return seats, rows

    def refuses_silence(m):
        """The item's own author declaring that silence releases nothing.

        A field, because prose is advisory and the field decides (L-A45,
        L-A98). This is the state L85 is about: an item with no clock is a gap
        or a refusal, and only the first is a thing to fix."""
        d = m.get("data") or {}
        return isinstance(d, dict) and d.get("silence_proceeds") is False

    def withdraws_clock(m):
        """Is this message the retraction of a clock rather than the showing
        of one?

        Read from a field, for the same reason as `refuses_silence`: the prose
        of a withdrawal and the prose of a clock are the same sentences with
        one word changed, and the field is the only part of either that a
        reader cannot misread (L-A45, L-A98). Two field forms, both observed on
        this board: `withdrawn: true` with `clock_was` naming the hour it
        retracts, and `withdraws` carrying the message id it retracts.

        WHY THIS EXISTS, and it is the worst answer this file has given. On
        2026-11-02 the owner leg of epitome#312 consisted of exactly two
        messages: `epitome/pm` starting a clock at 2026-10-27T00:48:11Z, and
        `epitome/pm` withdrawing that same clock at 01:34:36Z on the ground
        that no hand is authorised to merge a `prompts/` path at all. Both are
        addressed to the owner and both name the item, so `is_owner` counted
        two showings, and this file answered `clock running on #312 ...
        declared in all three places §22 names`. **The retraction of a clock
        was read as the showing that validates it** — the strongest negative
        evidence an item can carry, scored as the positive.

        It is L92 one layer out. That lesson taught this file that a
        withdrawal is the one act that moves an hour earlier, and the test it
        installed reads `expires_at`; a withdrawal that carries `withdrawn:
        true` and no hour is outside the set that test looks at, so it governs
        nothing. A withdrawal is not only a smaller hour. It can be the
        removal of the clock, and then there is no hour to compare."""
        d = m.get("data") or {}
        if not isinstance(d, dict):
            return False
        return d.get("withdrawn") is True or bool(d.get("withdraws"))

    def head_in(m):
        """The head a message claims the item stood at, from the keys this
        product actually uses: `head`, `head_<pr>`, or `heads[<pr>]`. Returns
        None when the sender named none, which is the common case and is
        reported as unknown rather than as agreement (L-A134)."""
        d = m.get("data") or {}
        if not isinstance(d, dict):
            return None
        for key in ("head", f"head_{pr}", f"head{pr}"):
            v = d.get(key)
            if isinstance(v, str) and v:
                return v
        v = d.get("heads")
        if isinstance(v, dict):
            h = v.get(pr) or v.get(int(pr) if pr.isdigit() else pr)
            if isinstance(h, str) and h:
                return h
        return None

    named = [m for m in msgs if names(m, repo, product, pr)]
    real = [m for m in named if m.get("expires_at")]
    if real:
        # THE HOUR IS THE ONE FILED LAST, NEVER THE LATEST ONE FILED.
        # This line used to read `sorted(real, key=expires_at)[-1]` and call
        # the result `newest`, which is the whole defect in one word: it took
        # the largest hour on the item for the current one. Those agree for
        # every extension and disagree for exactly one act — a withdrawal,
        # which by construction moves a deadline EARLIER. So the one message
        # shape the field exists to carry was the one shape it could not
        # express, and the instrument reported the retracted hour as live.
        # Measured on this repository's own #312: five messages name a clock,
        # the last filed (2026-11-02T00:25:52Z) withdraws an amendment and
        # restores 2026-11-03T23:30:00Z, and this file answered
        # 2026-11-04T00:30:00Z "declared in all three places". The applier
        # read the same field two minutes twenty-seven seconds later and
        # wrote the withdrawn hour into its own report as standing.
        current = sorted(real, key=lambda x: x["ts"])[-1]
        superseded = [m for m in real
                      if m["ts"] < current["ts"]
                      and m["expires_at"] > current["expires_at"]]
        exp = datetime.datetime.fromisoformat(current["expires_at"])
        left = exp - now
        hours = left.total_seconds() / 3600
        told = [m for m in named if applier_recipient(m)]
        # THE OWNER LEG, WITH THE RETRACTIONS TAKEN OUT OF IT. `shown` used to
        # be every owner-addressed message naming the item, which counted a
        # withdrawal as a showing; see `withdraws_clock`. The two lists are
        # kept apart rather than merged, because "she was never shown this"
        # and "she was shown it and then told to disregard it" are different
        # states and only the second has something to print.
        owner_facing = [m for m in named if is_owner(m)]
        retracted = [m for m in owner_facing if withdraws_clock(m)]
        # A withdrawal takes its own showing with it, and that is the whole
        # point: dropping only the withdrawal leaves the clock it retracted
        # standing in `shown`, which is the answer this file already gave.
        # Matched by the id the withdrawal names, or failing that by the hour
        # it says it is retracting — both are fields, and a withdrawal that
        # names neither retracts nothing this reader can identify and so takes
        # nothing out (it still prints, below).
        def retracted_by(m):
            mid = m.get("id")
            hour = (m.get("expires_at") or "")[:19]
            for w in retracted:
                if w["ts"] <= m["ts"]:
                    continue
                d = w.get("data") or {}
                if not isinstance(d, dict):
                    continue
                if mid and mid in (d.get("withdraws"), d.get("amends")):
                    return w
                was = d.get("clock_was") or ""
                if hour and isinstance(was, str) and was[:19] == hour:
                    return w
            return None
        shown = [m for m in owner_facing
                 if not withdraws_clock(m) and not retracted_by(m)]
        refused = [m for m in named if refuses_silence(m)]
        # Filing order, so the last line printed is the one in force. Sorting
        # this list by hour put the withdrawal in the middle of its own item.
        for m in sorted(real, key=lambda x: x["ts"]):
            mark = "  (in force)" if m is current else ""
            print(f"#{pr} carries the field: expires {m['expires_at'][:19]}Z, "
                  f"filed {m['ts'][:19]}Z by {m.get('from_company')}/{m.get('from_seat')} "
                  f"-> {m.get('to_company')}/{m.get('to_seat')}{mark}")
            print(f"  {m['subject'][:100]}")
        if superseded:
            latest = sorted(superseded, key=lambda x: x["expires_at"])[-1]
            print(f"  SHORTENED on #{pr}: the hour filed last ({current['expires_at'][:19]}Z) "
                  f"is EARLIER than one filed before it ({latest['expires_at'][:19]}Z, "
                  f"{latest['ts'][:19]}Z). A later filing naming an earlier hour is a "
                  f"withdrawal or a shortening, and it governs: read the hour in force, "
                  f"not the longest one on the item.")

        # §22's THIRD PLACE, READ FROM BOTH SIDES (L93). `told` below answers
        # "was a hand addressed", which is what §22 literally asks for and all
        # this file used to read. It is half of the question: a hand that was
        # told and declined is not a hand, and this item is the case that
        # proved it. No verdict is taken from this block, because taking one
        # needs a field the standard does not define, and inventing the field
        # here would release or block live owner decisions on a reading of
        # prose (L-A45). So it is laid out in filing order and read.
        if not answers_read:
            print(f"  COULD NOT LOOK at the applier's own record on #{pr}: the second "
                  f"page did not come back, so this place is read as addressed-only, "
                  f"which is the state that misreports (L93)")
        elif told:
            seats, rows = applier_record(told)
            who = ", ".join(sorted(f"{c}/{s2}" for c, s2 in seats))
            if rows:
                print(f"  the applier's own record on #{pr}, in filing order "
                      f"({len(rows)} message(s) from {who}; §22 names no field for an "
                      f"answer, so these are read and not resolved):")
                # The tail, never the head. The operative line is the last one
                # and an unbounded list is a list that gets skipped (the
                # frameworks law), so the newest eight print and the rest are
                # counted. Eight is the longest real sequence this board has
                # carried on one item, measured 2026-11-02.
                if len(rows) > 8:
                    print(f"    ... {len(rows) - 8} earlier message(s) elided; the tail is "
                          f"what governs, so the newest eight print")
                    rows = rows[-8:]
                for m, where in rows:
                    print(f"    {m['ts'][:19]}Z {(m.get('kind') or '?'):<7} -> "
                          f"{m.get('to_company') or '-'}/{m.get('to_seat')}  via {where}")
                    print(f"      {(m.get('subject') or '')[:96]}")
                print(f"  APPLIER ANSWER UNFIELDED on #{pr}: none of those {len(rows)} carries "
                      f"a field saying whether that hand accepts, so the last line above is "
                      f"the applier's last word and reading it is this reader's own act, not "
                      f"this file's (L93)")
            else:
                print(f"  APPLIER NEVER ANSWERED on #{pr}: {who} was told, and names this "
                      f"item in none of the {len(answers)} message(s) this window holds, so "
                      f"the hand §22 records has not acknowledged the clock it is expected "
                      f"to apply (L93)")

        # §22's FIRST PLACE, READ AS A SHOWING AND NOT AS A MESSAGE COUNT.
        # Printed in filing order like the applier's record above, because
        # the two legs fail the same way: a reader who sees only a verdict
        # cannot tell a showing from its retraction.
        if retracted:
            for m in sorted(retracted, key=lambda x: x["ts"]):
                d = m.get("data") or {}
                was = d.get("clock_was") or d.get("withdraws") or "unstated"
                took = [x for x in owner_facing if retracted_by(x) is m]
                with_it = (f", and it takes the showing of "
                           + ", ".join(f"{x['ts'][:19]}Z" for x in took)
                           + " with it") if took else \
                          ", and this reader cannot tell which showing it retracts"
                print(f"  RETRACTED  {m['ts'][:19]}Z {m.get('from_company')}/"
                      f"{m.get('from_seat')} -> {m.get('to_company')}/{m.get('to_seat')} "
                      f"withdrew a clock in its own data (was: {was}){with_it}")
        stale_head = None
        if shown:
            last_shown = sorted(shown, key=lambda x: x["ts"])[-1]
            sh, ch = head_in(last_shown), head_in(current)
            print(f"  she was last shown this item at {last_shown['ts'][:19]}Z by "
                  f"{last_shown.get('from_company')}/{last_shown.get('from_seat')}; the "
                  f"words in force were filed {current['ts'][:19]}Z")
            if sh and ch and sh[:7] != ch[:7]:
                stale_head = (sh, ch)
                print(f"  SHOWN OTHER WORDS on #{pr}: the showing names head {sh[:8]} and "
                      f"the clock in force names head {ch[:8]}, so the silence being timed "
                      f"is silence about a diff she was not shown")
            elif not sh:
                print(f"  the showing names no head, so whether the diff moved under it "
                      f"cannot be read from the board: §22 names no field for the state an "
                      f"ask was shown at, and this one is reported rather than resolved "
                      f"(routed to HQ 2026-11-02, with the applier-answer field)")

        local_pm = any((m.get("to_seat") or "").lower() == "pm"
                       and (m.get("to_company") or product) == product for m in told)
        if local_pm and applier_fence.startswith("FORBIDDEN"):
            print(f"  APPLIER FENCED OUT on #{pr}: {applier_fence}")
            print(f"    §21 grants `{product}/pm` this merge and that seat's charter fences "
                  f"the path; this file reports the disagreement and takes the seat's own "
                  f"charter as what the seat will act on (L40)")

        missing = []
        if local_pm and applier_fence.startswith("FORBIDDEN"):
            missing.append(f"the hand §22 records is `{product}/pm`, §21 grants that seat "
                           f"every charter merge, and that seat's own charter fences a path "
                           f"in this diff (`addressed.sh --can`). The two disagree, the seat "
                           f"reads its own charter, and it has already withdrawn a clock on "
                           f"this file for exactly that reason, so the hour expires onto a "
                           f"hand that will not act — an authority nobody holds, which is "
                           f"routed and not waited on (L40, L96)")
        if stale_head:
            missing.append(f"the last showing names head {stale_head[0][:8]} and the clock "
                           f"in force names head {stale_head[1][:8]}: a clock consents to the "
                           f"words the ask showed her, so this one times silence about a diff "
                           f"she has not seen (L96) — re-show the item, from the hand that "
                           f"filed the ask, and let the clock restart on it")
        if refused:
            for m in refused:
                print(f"  REFUSED  {m['ts'][:19]}Z {m.get('from_company')}/{m.get('from_seat')}"
                      f" -> {m.get('to_company')}/{m.get('to_seat')} wrote"
                      f" `silence_proceeds: false` in its own data")
            missing.append("the item's own ask declares that silence releases nothing, so a "
                           "clock over it reverses a reservation rather than collecting consent "
                           "(L85) — withdraw it, or take the evidence to the hand that holds "
                           "the item (L-A66)")
        if not told:
            missing.append("no message names an applier §21 authorises to merge here: §22's "
                           "third place is the recipient field, and a clock expires at an hour "
                           "no run chose, so an applier nobody told is nobody woken")
        if not shown and retracted:
            missing.append("every owner-addressed message on this item withdraws a clock "
                           "rather than showing her one, so the only thing her silence has "
                           "been shown is a retraction and there is nothing for it to "
                           "consent to (L96)")
        elif not shown:
            missing.append("no ask on this item ever reached an owner, so the silence being "
                           "read as consent is the silence of a party never shown the words")
        if pr_state in ("MERGED", "CLOSED"):
            missing.append(f"the `ref` points at a pull request that is {pr_state.lower()}, so "
                           f"there is no merge left for the deadline to be: §22 asks the ask to "
                           f"carry its change, and a release here has to be written fresh rather "
                           f"than applied")
        if missing:
            print(f"NOT DECLARED on #{pr}: the field is set and §22 is not satisfied."
                  f" Nothing may be released on this.")
            for why in missing:
                print(f"  - {why}")
            if told:
                print(f"  told: " + ", ".join(
                    f"{m.get('to_company')}/{m.get('to_seat')} at {m['ts'][:19]}Z" for m in told))
            if shown:
                print(f"  shown her: " + ", ".join(f"{m['ts'][:19]}Z" for m in shown))
            if retracted:
                print(f"  withdrawn in front of her: " + ", ".join(
                    f"{m['ts'][:19]}Z" for m in sorted(retracted, key=lambda x: x["ts"])))
            sys.exit(4)

        if hours < 0:
            print(f"EXPIRED on #{pr}: the hour passed {abs(int(hours))}h ago "
                  f"({current['expires_at'][:19]}Z) and this file cannot tell you whether "
                  f"anybody acted — ask the pull request, not the board.")
            print(f"  the applier §22 authorised: " + ", ".join(
                f"{m.get('to_company')}/{m.get('to_seat')}" for m in told))
            sys.exit(5)

        vehicle = {"OPEN": "open", "?": "NOT CHECKED — no forge read, so this place is"
                                        " unconfirmed rather than clear"}.get(pr_state, pr_state)
        print(f"clock running on #{pr}: expires {current['expires_at'][:19]}Z "
              f"({int(hours)}h left), declared in all three places §22 names")
        print(f"  the pull request the `ref` releases: {vehicle}")
        print(f"  applier told: " + ", ".join(
            f"{m.get('to_company')}/{m.get('to_seat')} at {m['ts'][:19]}Z" for m in told))
        sys.exit(0)
    interim = [m for m in msgs
               if names(m, repo, product, pr) and not m.get("expires_at") and data_deadline(m)]
    if interim:
        for m in sorted(interim, key=data_deadline):
            when = data_deadline(m)
            print(f"enumerable clock on #{pr}, not law yet: deadline {when[:19]} in `data`,"
                  f" filed {m['ts'][:19]}Z by {m.get('from_company')}/{m.get('from_seat')}"
                  f" -> {m.get('to_company')}/{m.get('to_seat')}")
            print(f"  {m['subject'][:100]}")
        print("  `expires_at` is the field the law names and it IS settable on an ask —")
        print("  proved by write at 2026-10-26T05:03Z, `--writable` (L67). A deadline in")
        print("  `data` is enumerable and is still not that field, so it releases nothing.")
        sys.exit(3)

    claimed = [m for m in msgs if names(m, repo, product, pr) and claims_clock(m)]
    if claimed:
        print(f"no clock on #{pr}: {len(claimed)} ask(s) name it and mention a clock in prose,"
              f" and none carries the field")
        for m in sorted(claimed, key=lambda x: x["ts"]):
            print(f"  {m['ts'][:19]}Z {m.get('from_company')}/{m.get('from_seat')}"
                  f" -> {m.get('to_company')}/{m.get('to_seat')}: {m['subject'][:80]}")
        print("  nothing may be released on these, and nothing is protected by them (L52)")
        print("  this half of the reading is prose and cannot be conclusive about intent"
              " (L-A45) — the verdict above does not depend on it, because the field decides")
        sys.exit(1)
    print(f"no clock on #{pr}: no ask in the last window names it in `ref` or `data` at all")
    sys.exit(1)

# The census. Claimed against real, and the claimed-but-unfielded set is the
# finding — reported as a finding with its own exit code, because a check that
# prints breaches and exits 0 teaches every caller to ignore it (L-A9, L41).
claimed = [m for m in msgs if claims_clock(m)]
real = [m for m in msgs if m.get("expires_at")]
print(f"clocks on the board, last {len(msgs)} asks")
print(f"  {len(claimed)} asks claim a clock in their own prose")
print(f"  {len(real)} carry `expires_at`, the field the law makes the test (L-A98)")
# This breakdown counts `claimed`, the asks that claim a clock in their prose,
# and it used to print indented under the line above it — so a reader saw
# "11 carry the field" and then "26 epitome" and had one impossible pair of
# numbers to join. A sentence that counts names what it is a count of (L33).
by = {}
for m in claimed:
    by[m.get("from_company")] = by.get(m.get("from_company"), 0) + 1
print(f"  of the {len(claimed)} that claim one in prose, by company:")
for c, n in sorted(by.items(), key=lambda kv: -kv[1]):
    print(f"    {n:3d}  {c}")
def _dd(m):
    d = m.get("data") or {}
    if not isinstance(d, dict): return None
    for k in ("expires_at", "clock_expires_at", "deadline"):
        if isinstance(d.get(k), str) and len(d[k]) >= 10: return d[k]
    return None
enumerable = [m for m in claimed if not m.get("expires_at") and _dd(m)]
# This summary said "the only form a seat can write (L53)" until 2026-11-01,
# which this file's own `data_deadline` docstring had already corrected: the
# field IS settable on an ask, proved by write on 2026-10-26 (`--writable`,
# L67), so `data` is not the only form, it is the wrong one. One fact stated
# twice in one file, and the stale copy was the summary, which is the line a
# reader acts on. It cost two posts: the run that writes this correction filed
# both of its own charter clocks into `data` first, read this line back, and
# re-posted them with the field set. A value a reader can apply lives in
# exactly one place (L-A143).
print(f"  {len(enumerable)} carry a deadline in `data` only, which releases nothing by this"
      f" reader: the repair for each is to re-post with `expires_at` set (L67, L-A92)")
# And the one thing this reader must not do is let its own verdict stand as the
# company's. `docs/standards/pm.md` §22 withdrew the three-field requirement on
# 2026-10-24 on the ground that "no seat can set `expires_at`", and declared a
# `data`-only deadline valid for exactly that reason. The write path moved
# after that paragraph was written and the paragraph did not follow: `store.py`
# carries `parse_expires_at` and `post_message(expires_at=)`, this file settled
# it by write on 2026-10-26, and epitome/exo set the column on a live ask at
# 2026-11-01T23:54:37Z and read `2026-11-03T23:30:00+00:00` back off the 201.
# So on this one question the standard and the surface disagree, both readings
# are honest, and a seat whose clock is declared in one place only is relying
# on whichever its merger read first (L-A66). Until the paragraph is repaired
# the safe filing is both places, which costs nothing, and the direction of the
# risk is the standard's own: a clock that never fires does not miss noisily,
# it holds forever with everybody reporting compliance.
if enumerable:
    print("  NOTE: §22 says that form IS the valid one, on the ground that no seat can set"
          " the column; the store now takes it and this seat has set it, so the section is"
          " behind its own surface. File both until it is repaired; routed to HQ 2026-11-01.")
unfielded = [m for m in claimed if not m.get("expires_at") and not _dd(m)]
if unfielded:
    print(f"\n  {len(unfielded)} prose clocks, oldest first — each one releases nothing"
          f" and protects nothing:")
    for m in sorted(unfielded, key=lambda x: x["ts"])[:8]:
        print(f"    {m['ts'][:19]}Z {m.get('from_company')}/{m.get('from_seat')}"
              f" -> {m.get('to_company')}/{m.get('to_seat')}: {m['subject'][:70]}")
    if len(unfielded) > 8:
        print(f"    … and {len(unfielded) - 8} more")
    sys.exit(1)
sys.exit(0)
PY
rc=$?
# The census does NOT run the probe. `--writable` posts a message, and a read
# command with a write side effect is a trap: the first version of this called
# it from the census footer, so two of the three clock-bearing asks on the
# board at 05:1xZ were posted by this file reporting on how many there were.
# A census that changes its own subject cannot be re-run (L67's own clause one
# pointed the other way, and this is its cost when applied carelessly).
[ -n "$PR" ] || printf '\nwhether the field is settable at all was settled by write on 2026-10-26 and is\ncited rather than re-probed:\n  bash docs/agents/clocks.sh --writable   (writes nothing unless FORCE=1)\n'
exit $rc
