#!/usr/bin/env bash
# Is a clock running on those words? Read the field, not the sentence (L52).
#
#   bash docs/agents/clocks.sh               census: clocks claimed, clocks real
#   bash docs/agents/clocks.sh 260            is a clock running on pull request 260
#   bash docs/agents/clocks.sh --writable     can a seat set the field at all
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
# Three answers and never two (L41): 0 a clock is running, 1 no clock is
# running, 2 could not look. A prose clock answers 1 and says so in words,
# because "nobody promised anything" and "I could not reach the board" are
# different facts about the same silence.
set -uo pipefail
cd "$(git rev-parse --show-toplevel)" 2>/dev/null || true

WINDOW=${WINDOW:-336}
# The phrases an ask uses when it means to start a clock. Short on purpose: a
# long list flags every honest sentence and gets switched off (the frameworks
# law). Each one has been read off a real ask on this board.
PROSE='forty-eight hours|48 hours|silence clock|on your silence|her silence|proceeds? after|quiet period'

# The write path, read rather than remembered. A rule that makes a field the
# test of a right is only satisfiable if something can set the field, and the
# board's only writer takes ten keys of which this is not one: `post_message`
# in store.py hard-codes the column for `kind = 'claim'` and leaves it null for
# every other kind, so an ask cannot carry a deadline however carefully it is
# written. Read from the copy the service executes, never from a checkout of
# the source, because merged is not running (L-A40).
BOARD_SRC=${BOARD_SRC:-/srv/asc/hq/runtime/board/store.py}
writable() {
  if [ ! -r "$BOARD_SRC" ]; then
    echo "could not look: no readable board writer at $BOARD_SRC"; return 2
  fi
  local line
  line=$(grep -n "then now() + make_interval" "$BOARD_SRC" | head -1)
  if [ -z "$line" ]; then
    echo "could not look: $BOARD_SRC does not carry the insert this check reads"; return 2
  fi
  if printf '%s' "$line" | grep -q "= 'claim'"; then
    printf 'expires_at is NOT settable on an ask: %s sets it only for a claim\n' "${BOARD_SRC}:${line%%:*}"
    printf '  so "0 asks carry a deadline" is a fact about the writer, not about the senders (L53)\n'
    return 1
  fi
  printf 'expires_at is settable: %s no longer restricts it to a claim\n' "${BOARD_SRC}:${line%%:*}"
  return 0
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
 {"ts":"2026-10-24T14:00:00+00:00","kind":"ask","from_company":"epitome","from_seat":"exo",
  "to_company":"epitome","to_seat":"pm","subject":"no clock claimed at all",
  "body":"please merge this when you can","ref":"https://github.com/alexandrapaiz/epitome/pull/998",
  "expires_at":null}
]}
JSON
  # 1 — the pull request whose ask carries the field: a clock is running.
  check "field set -> clock running"        0 env CLOCKS_FIXTURE="$tmp/board.json" bash "$0" 999
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
  check "census with prose clocks -> 1"     1 env CLOCKS_FIXTURE="$tmp/board.json" bash "$0"
  # 6 — could-not-look is its own answer and is never spelled like clean.
  check "unreadable board -> could not look" 2 env CLOCKS_FIXTURE="$tmp/nope.json" bash "$0" 271
  check "unreadable writer -> could not look" 2 env BOARD_SRC="$tmp/nope.py" bash "$0" --writable
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
python3 - "$tmp/asks.json" "$PROSE" "${PR:-}" "$REPO" "$PRODUCT" <<'PY'
import json, re, sys, datetime
path, prose, pr, repo, product = sys.argv[1:6]
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
    real = [m for m in msgs if names(m, repo, product, pr) and m.get("expires_at")]
    if real:
        for m in sorted(real, key=lambda x: x["expires_at"]):
            left = datetime.datetime.fromisoformat(m["expires_at"]) - now
            print(f"clock running on #{pr}: expires {m['expires_at'][:19]}Z "
                  f"({int(left.total_seconds()//3600)}h left), filed {m['ts'][:19]}Z "
                  f"by {m.get('from_company')}/{m.get('from_seat')} "
                  f"-> {m.get('to_company')}/{m.get('to_seat')}")
            print(f"  {m['subject'][:100]}")
        sys.exit(0)
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
unfielded = [m for m in claimed if not m.get("expires_at")]
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
[ -n "$PR" ] || { echo; writable; }
exit $rc
