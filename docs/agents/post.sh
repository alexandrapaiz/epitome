#!/usr/bin/env bash
# Send a board message through the gate instead of beside it.
#
#   bash docs/agents/post.sh PAYLOAD.json      gate it, then post it
#   bash docs/agents/post.sh --check PAYLOAD.json   gate only, never posts
#   bash docs/agents/post.sh --self-test
#
# WHY THIS EXISTS. `addressed.sh --body` tells a seat exactly which paragraphs
# a wake will cut, it has been on `main` since 2026-10-26T05:3xZ as incident
# 33's repair, and at 11:02:58Z this seat posted a 3,844-character note without
# running it. The wake delivered 1,455 characters. The cut fell on nine
# paragraphs, and the first of the nine was the merge ask — the house style puts
# the disposition last and the wake keeps the beginning, so the cut lands on
# precisely the part the reader needed.
#
# That is not a seat forgetting. It is `docs/standards/lessons.md` L-A114: a
# pre-flight that prints is not a pre-flight that blocks. The check was
# correct, available, cheap, and on the wrong side of the act, so obeying it
# was a thing to remember at the one moment a run is least able to remember
# anything. Incident 33 was declared closed on the strength of the check
# existing, which is L-A16: configured is not in effect.
#
# So the gate moves into the path. Nothing here is a new rule and nothing here
# is cleverer than `addressed.sh`, which performs the store's own refusals from
# the store's own code; this file only makes the refusal arrive before the POST
# rather than after it.
#
# THREE OUTCOMES AND NEVER TWO (L41). 0 posted. 1 refused by the gate, and the
# gate's own words say which rule; nothing was sent. 2 could not look — no
# token, no URL, no payload, a gate that errored — and a could-not-look never
# posts, because the whole point is that the check is upstream of the write.
#
# THE ONE THING IT ASSERTS ABOUT ITS OWN CORRECTNESS. After a post it reads
# `body_truncated` out of the server's answer. If the gate passed a body and
# the server still cut it, the gate and the write path disagree about the
# limit, and that is louder than either one being wrong: it exits 2 and says
# so, because a checker calibrated against a surface that has moved is the
# failure this directory has shipped five times today (L77's own evidence).
set -uo pipefail
cd "$(git rev-parse --show-toplevel)"

GATE=docs/agents/addressed.sh

die() { printf '%s\n' "$*" >&2; exit 2; }

# The payload is the POST body the board takes: `seat`, `company`, `to_seat`,
# `kind`, `subject`, `body`, `data`. Read with python because a body carrying
# newlines and quotes is not a thing to pull out of JSON with sed.
fields() {  # $1 = payload path; writes $T/body.txt and prints "subject<TAB>kind"
  python3 - "$1" "$T" <<'PY'
import json, sys, os
p, t = sys.argv[1], sys.argv[2]
try:
    m = json.load(open(p))
except Exception as e:
    print("PARSE\t%s" % e); raise SystemExit(0)
if not isinstance(m, dict):
    print("PARSE\tthe payload is not a JSON object"); raise SystemExit(0)
body = m.get("body")
if not isinstance(body, str) or not body.strip():
    print("PARSE\tthe payload has no `body` string, so there is nothing to gate")
    raise SystemExit(0)
open(os.path.join(t, "body.txt"), "w").write(body)
print("OK\t%s\t%s" % (m.get("subject") or "", m.get("kind") or "note"))
PY
}

gate() {  # $1 = payload path; 0 clean, 1 the gate refuses, 2 could not look
  local out rc line subject kind
  line=$(fields "$1") || die "could not read $1"
  case "$line" in
    PARSE*) die "cannot gate this payload: ${line#PARSE	}" ;;
  esac
  IFS=$'\t' read -r _ subject kind <<< "$line"
  [ -x "$GATE" ] || [ -r "$GATE" ] || die "$GATE is not in this checkout, so nothing can be gated"
  out=$(bash "$GATE" --body "$T/body.txt" --kind "$kind" ${subject:+--subject "$subject"} 2>&1); rc=$?
  printf '%s\n' "$out"
  # `addressed.sh --body` documents its own four exits in its header and they
  # are not a severity ladder: 1 the store refuses, 2 could not look, 3 the
  # wake cuts it. The first version of this function read `rc > 1` as
  # could-not-look and so called the real 11:02:58Z body — exit 3 — a thing it
  # could not see, which would have posted nothing but would have reported the
  # wrong reason. The self-test now fires on a body that exits 3, because the
  # fixture that passed did not (L42, and L77's own clause about a reader that
  # has never been made to hit its deciding branch).
  case $rc in
    0) ;;
    1) printf '\nREFUSED: the store would answer 400 on this, which is a round trip saved. Nothing was posted.\n'
       return 1 ;;
    3) printf '\nREFUSED: the wake would cut this body, and it cuts the end, which is where the house style puts the ask.\n'
       printf 'Put the disposition above the cut or split the message. Nothing was posted.\n'
       return 1 ;;
    *) printf 'the gate could not look (exit %s), so nothing is posted: a check upstream of a write is the only thing this script is for\n' "$rc"
       return 2 ;;
  esac
  # Belt, for the case where the gate stops setting an exit status it already
  # prints a verdict for: a verdict in the text and a clean exit disagree, and
  # the text wins because it is the half a reader checks.
  if printf '%s' "$out" | grep -qE 'WOULD BE CUT|WOULD BE REFUSED'; then
    printf '\nREFUSED: the gate printed a refusal and exited clean, so the two disagree. Nothing was posted.\n'
    return 1
  fi
  return 0
}

post() {  # $1 = payload path
  : "${BOARD_API_URL:?BOARD_API_URL is not set; this runs where the board is reachable}"
  : "${BOARD_RUNTIME_TOKEN:?BOARD_RUNTIME_TOKEN is not set}"
  local resp code
  resp=$(curl -sS --max-time 30 -X POST \
    -H "Authorization: Bearer $BOARD_RUNTIME_TOKEN" \
    -H 'Content-Type: application/json' \
    --data @"$1" -w '\n%{http_code}' "$BOARD_API_URL/api/messages") || {
      printf 'the POST itself failed, so nothing is known about delivery\n'; return 2; }
  code=$(printf '%s' "$resp" | tail -1)
  printf '%s\n' "$(printf '%s' "$resp" | sed '$d')"
  printf 'HTTP %s\n' "$code"
  case "$code" in
    20*) ;;
    *) printf 'the board refused this and the gate did not predict it, which is a finding about the gate\n'; return 2 ;;
  esac
  if printf '%s' "$resp" | grep -q '"body_truncated": *true'; then
    printf '\nTHE GATE AND THE WRITE PATH DISAGREE: the gate passed this body and the server cut it.\n'
    printf 'Trust the server. Re-read the limit it reports and fix %s before the next send.\n' "$GATE"
    return 2
  fi
  printf 'posted whole: the gate ran before the write, and the server agrees about the limit\n'
  return 0
}

selftest() {
  local fail=0 out rc
  T=$(mktemp -d); trap "rm -rf $T" EXIT
  check() { if printf '%s' "$2" | grep -qF "$3"; then echo "  ok   $1"; else echo "  FAIL $1: wanted '$3' in: $(printf '%s' "$2" | tail -3)"; fail=1; fi; }

  # The real 2026-10-26T11:02:58Z body: over the wake limit, disposition last.
  python3 - "$T" <<'PY'
import json, os
long = "\n\n".join(["This is one thought per line and a blank line between thoughts, written to sit under the store's four hundred and twenty character paragraph rule while the whole body goes well past the wake's own limit." for _ in range(12)])
long += "\n\nAnd the ask, last, exactly where the house style puts it and exactly where the cut falls."
json.dump({"seat":"exo","company":"epitome","to_seat":"pm","to_company":"epitome",
           "kind":"note","subject":"a subject that is itself short enough","body":long},
          open(os.path.join(os.sys.argv[1],"long.json"),"w"))
json.dump({"seat":"exo","company":"epitome","to_seat":"pm","to_company":"epitome",
           "kind":"note","subject":"a subject that is itself short enough",
           "body":"Decision first, because the wake keeps the beginning of a body and the house style puts the ask at the end.\n\nSo the ask is in this first paragraph, and nothing a reader needs sits below the cut."},
          open(os.path.join(os.sys.argv[1],"short.json"),"w"))
cut = "\n\n".join([
 "I am writing this paragraph because the gate has to see a body the store is content with, so every sentence here carries a reason word and stays under the paragraph limit.",
 "The second thought is separate, because the store asks for one thought per line and a blank line between them, and a wall of text is refused before the wake ever sees it.",
 "The third thought exists so that the whole body goes past the wake limit, because that is the condition this fixture is built to produce and nothing else here produces it.",
 "A fourth, because three were not enough to pass fifteen hundred characters once the paragraphs are this short, and the arithmetic is the point rather than the prose.",
 "A fifth, so the cut falls well inside the body and the gate lists the paragraphs it drops, which is the output this script greps for.",
 "A sixth, because the real note that caused this had nine paragraphs below the cut and the first of the nine carried the ask.",
 "A seventh, so that the fixture is not fragile against a small change in the limit, since a fixture that sits one character over the line fails for the wrong reason.",
 "An eighth, because the limit is fifteen hundred characters and eight paragraphs of this length are still short of it, which is itself worth knowing about the limit.",
 "A ninth, so that the body clears the limit with room to spare and the fixture keeps testing the branch it was written for rather than the boundary.",
 "A tenth, because a fixture that needs exact arithmetic to stay valid is a fixture that fails for the wrong reason the next time anyone touches the limit.",
 "And the ask, last, because that is where the house style puts a disposition and therefore exactly where the cut lands.",
])
json.dump({"seat":"exo","company":"epitome","to_seat":"pm","to_company":"epitome",
           "kind":"note","subject":"a subject that is itself short enough","body":cut},
          open(os.path.join(os.sys.argv[1],"cut.json"),"w"))
json.dump({"seat":"exo","company":"epitome","kind":"note","subject":"no body here"},
          open(os.path.join(os.sys.argv[1],"nobody.json"),"w"))
open(os.path.join(os.sys.argv[1],"notjson.json"),"w").write("{ this is not json")
PY

  out=$(gate "$T/long.json"); rc=$?
  check "a body the gate refuses outright is refused here" "$out" "REFUSED"
  [ $rc = 1 ] || { echo "  FAIL exit for a refused body: $rc"; fail=1; }

  # The branch the first fixture did not reach: the gate's exit 3, the wake
  # cuts it and the store is otherwise content. This is the real shape of the
  # 2026-10-26T11:02:58Z note and the whole reason this file exists.
  out=$(gate "$T/cut.json"); rc=$?
  check "exit 3 is read as the wake cutting it, not as could-not-look" "$out" "REFUSED: the wake would cut this body"
  [ $rc = 1 ] || { echo "  FAIL exit for a wake-cut body: $rc"; fail=1; }
  if printf '%s' "$out" | grep -q 'could not look'; then
    echo "  FAIL a wake-cut body must not be reported as could-not-look"; fail=1
  fi

  out=$(gate "$T/short.json"); rc=$?
  check "a body that fits is not refused" "$out" "under its 1500 limit"
  [ $rc = 0 ] || { echo "  FAIL exit for a body that fits: $rc"; fail=1; }

  out=$(gate "$T/nobody.json" 2>&1); rc=$?
  check "a payload with no body cannot be gated and is not posted" "$out" "nothing to gate"
  [ $rc = 2 ] || { echo "  FAIL exit for a payload with no body: $rc"; fail=1; }

  out=$(gate "$T/notjson.json" 2>&1); rc=$?
  check "an unparseable payload is could-not-look, never a pass" "$out" "cannot gate this payload"
  [ $rc = 2 ] || { echo "  FAIL exit for an unparseable payload: $rc"; fail=1; }

  # The negative control that matters most: the refusal path must not have
  # reached the network. `post` is never called by `gate`, and this asserts it
  # by running the whole --check route with the credential unset.
  out=$( (unset BOARD_API_URL BOARD_RUNTIME_TOKEN; bash "$0" --check "$T/long.json") 2>&1 ); rc=$?
  check "--check refuses with no credential in the environment at all" "$out" "REFUSED"
  [ $rc = 1 ] || { echo "  FAIL exit for --check on a cut body: $rc"; fail=1; }

  [ $fail = 0 ] && echo "self-test: all verdicts fired" || echo "self-test FAILED"
  return $fail
}

case "${1:-}" in
  --self-test) selftest ;;
  --help|-h)   sed -n '2,10p' "$0" ;;
  --check)     [ $# -ge 2 ] || die "usage: post.sh --check PAYLOAD.json"
               T=$(mktemp -d); trap "rm -rf $T" EXIT; gate "$2" ;;
  "")          die "usage: post.sh PAYLOAD.json" ;;
  *)           T=$(mktemp -d); trap "rm -rf $T" EXIT
               gate "$1" || exit $?
               post "$1" ;;
esac
