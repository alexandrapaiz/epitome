#!/usr/bin/env bash
# Is a clock running on those words? Read the field, not the sentence (L52).
#
#   bash docs/agents/clocks.sh               census: clocks claimed, clocks real
#   bash docs/agents/clocks.sh 260            is a clock running on pull request 260
#   bash docs/agents/clocks.sh --writable     can a seat set the field at all
#                                             (POSTS one self-addressed ask — this
#                                              is the only subcommand that writes)
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

fetch() {  # $1 = destination file
  : "${BOARD_API_URL:?BOARD_API_URL is not set; this runs where the board is reachable}"
  : "${BOARD_RUNTIME_TOKEN:?BOARD_RUNTIME_TOKEN is not set}"
  curl -sS -H "Authorization: Bearer $BOARD_RUNTIME_TOKEN" \
    "$BOARD_API_URL/api/messages?kind=ask&since_hours=$WINDOW&limit=500&format=json" > "$1"
}

case "${1:-}" in
--writable) writable; exit $? ;;

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
  "expires_at":"2000-01-01T00:00:00+00:00"}
]}
JSON
  # 1 — the field alone is not a declared clock any more: #999's ask carries
  #     the field and names an applier, and no ask on it ever reached an
  #     owner, so §22's second party is missing and it answers 4 (L85).
  check "field set, owner never shown -> 4" 4 env CLOCKS_FIXTURE="$tmp/board.json" bash "$0" 999
  check "and it says which place is missing" 0 env CLOCKS_FIXTURE="$tmp/board.json" bash -c \
        'bash "$0" 999 2>&1 | grep -q "ever reached an owner"' "$0"
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
        'bash "$0" 260 2>&1 | grep -q "1 ask(s) name it"' "$0"
  # 4b — another repository's #271 is not this repository's #271 (L-A18).
  check "foreign repo #271 is not ours"      0 env CLOCKS_FIXTURE="$tmp/board.json" bash -c \
        'bash "$0" 271 2>&1 | grep -q "^no clock on #271: 1 ask(s) name it"' "$0"
  # 5 — the census exits non-zero while any claimed clock lacks its field,
  #     because a census that finds 44 breaches and exits 0 is not a gate.
  # 4c — a deadline written the one way a seat can write it is neither a clock
  #      in the law's field nor nothing, so it gets its own exit.
  check "deadline in data -> enumerable, not law" 3 env CLOCKS_FIXTURE="$tmp/board.json" bash "$0" 997
  # 4d — all three places, over two messages, which is the only shape that has
  #      ever fired in this company (L85).
  check "owner half + applier half -> running"  0 env CLOCKS_FIXTURE="$tmp/board.json" bash "$0" 996
  check "and it names the applier it was told to" 0 env CLOCKS_FIXTURE="$tmp/board.json" bash -c \
        'bash "$0" 996 2>&1 | grep -q "all three places"' "$0"
  # 4e — a clock filed over the item's own declared refusal releases nothing,
  #      and the refusal is read from the field rather than the prose (L85).
  check "clock over silence_proceeds:false -> 4" 4 env CLOCKS_FIXTURE="$tmp/board.json" bash "$0" 995
  check "and it quotes the field that refused"   0 env CLOCKS_FIXTURE="$tmp/board.json" bash -c \
        'bash "$0" 995 2>&1 | grep -q "silence_proceeds"' "$0"
  # 4f — expired is its own answer: the hour a clock exists for is the hour it
  #      passes, and `running (-3h left)` was the old reading of exactly this.
  check "declared and expired -> 5"             5 env CLOCKS_FIXTURE="$tmp/board.json" bash "$0" 994
  check "and it refuses to call that running"    0 env CLOCKS_FIXTURE="$tmp/board.json" bash -c \
        'bash "$0" 994 2>&1 | grep -q "^EXPIRED on #994"' "$0"
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
        'bash "$0" --writable 2>&1 | grep -q "cited, not re-probed"' "$0"
  exit $rc ;;
esac

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
if [ -n "${CLOCKS_FIXTURE:-}" ]; then
  [ -r "$CLOCKS_FIXTURE" ] || { echo "could not look: no board fixture at $CLOCKS_FIXTURE" >&2; exit 2; }
  cp "$CLOCKS_FIXTURE" "$tmp/asks.json"
else
  fetch "$tmp/asks.json" || { echo "could not look: the board did not answer" >&2; exit 2; }
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
python3 - "$tmp/asks.json" "$PROSE" "${PR:-}" "$REPO" "$PRODUCT" "$PR_STATE" <<'PY'
import json, re, sys, datetime
path, prose, pr, repo, product, pr_state = sys.argv[1:7]
try:
    msgs = json.load(open(path))["messages"]
except Exception as why:
    print(f"could not look: {path} is not a board answer ({why})"); sys.exit(2)
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

    def refuses_silence(m):
        """The item's own author declaring that silence releases nothing.

        A field, because prose is advisory and the field decides (L-A45,
        L-A98). This is the state L85 is about: an item with no clock is a gap
        or a refusal, and only the first is a thing to fix."""
        d = m.get("data") or {}
        return isinstance(d, dict) and d.get("silence_proceeds") is False

    named = [m for m in msgs if names(m, repo, product, pr)]
    real = [m for m in named if m.get("expires_at")]
    if real:
        newest = sorted(real, key=lambda x: x["expires_at"])[-1]
        exp = datetime.datetime.fromisoformat(newest["expires_at"])
        left = exp - now
        hours = left.total_seconds() / 3600
        told = [m for m in named if applier_recipient(m)]
        shown = [m for m in named if is_owner(m)]
        refused = [m for m in named if refuses_silence(m)]
        for m in sorted(real, key=lambda x: x["expires_at"]):
            print(f"#{pr} carries the field: expires {m['expires_at'][:19]}Z, "
                  f"filed {m['ts'][:19]}Z by {m.get('from_company')}/{m.get('from_seat')} "
                  f"-> {m.get('to_company')}/{m.get('to_seat')}")
            print(f"  {m['subject'][:100]}")

        missing = []
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
        if not shown:
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
            sys.exit(4)

        if hours < 0:
            print(f"EXPIRED on #{pr}: the hour passed {abs(int(hours))}h ago "
                  f"({newest['expires_at'][:19]}Z) and this file cannot tell you whether "
                  f"anybody acted — ask the pull request, not the board.")
            print(f"  the applier §22 authorised: " + ", ".join(
                f"{m.get('to_company')}/{m.get('to_seat')}" for m in told))
            sys.exit(5)

        vehicle = {"OPEN": "open", "?": "NOT CHECKED — no forge read, so this place is"
                                        " unconfirmed rather than clear"}.get(pr_state, pr_state)
        print(f"clock running on #{pr}: expires {newest['expires_at'][:19]}Z "
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
by = {}
for m in claimed:
    by[m.get("from_company")] = by.get(m.get("from_company"), 0) + 1
for c, n in sorted(by.items(), key=lambda kv: -kv[1]):
    print(f"    {n:3d}  {c}")
def _dd(m):
    d = m.get("data") or {}
    if not isinstance(d, dict): return None
    for k in ("expires_at", "clock_expires_at", "deadline"):
        if isinstance(d.get(k), str) and len(d[k]) >= 10: return d[k]
    return None
enumerable = [m for m in claimed if not m.get("expires_at") and _dd(m)]
print(f"  {len(enumerable)} carry a deadline in `data`, the only form a seat can write (L53)")
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
