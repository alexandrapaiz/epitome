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
# A seat needs its company in its own field, not folded into the seat name
# with a slash. `resolve_recipient` in the store refuses both by name, and
# this gate ran `addressed.sh --body` without ever looking at either one, so
# two handoffs passed it tonight and still came back 400 from the route.
to_seat = (m.get("to_seat") or "").strip()
if "/" in to_seat:
    print("PARSE\t`to_seat` is %r, which has a slash in it — a seat name is "
          "not an address; put the company in `to_company`" % to_seat)
    raise SystemExit(0)
if to_seat and to_seat.lower() not in ("owner", "chair") and not to_seat.lower().startswith("chair:"):
    to_company = m.get("to_company")
    if not isinstance(to_company, str) or not to_company.strip():
        print("PARSE\tthe payload addresses `to_seat` %r with no `to_company` — "
              "the store refuses this by name: \"a message to %r needs a company\""
              % (to_seat, to_seat))
        raise SystemExit(0)
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
  # THE BELT, and it is the only thing this file asserts about the gate it just
  # ran. A clean exit is one of two halves of the gate's answer and the text is
  # the other, so this reads the text and refuses to call the two one.
  #
  # It asks for the gate's own pass verdict rather than for the absence of a
  # complaint, because absence is what every broken way of running a check
  # produces. `addressed.sh` prints exactly two positive lines on a pass — one
  # per half of its own job, the store's refusals and the wake's limit — and it
  # prints them unconditionally when that half passes, so their absence is not
  # a wording difference, it is the gate not having answered. A gate that dies
  # after writing half its output, a gate whose verdict wording moved, a gate
  # that prints nothing and exits 0: all three arrive here as silence, and
  # silence is not a pass.
  #
  # Matched with `case` and not with `grep`, deliberately. A `grep` in this
  # branch decides a send with a process that has its own failure modes: a
  # false non-zero from one reads as *no refusal was printed* and the message
  # goes out, which is this gate's own defect class pointed at itself. The
  # measurement is in this branch's pull request — 3 of 500 asks wrong on the
  # real 1018-byte refusal, every one `141 0`, the producer dying on SIGPIPE
  # while grep exits 0. `case` is the shell itself: no second process, no exit
  # status, nothing to misread.
  local refused='' saw_store='' saw_wake=''
  case "$out" in *'WOULD BE REFUSED'*) refused="the store's own refusal" ;; esac
  case "$out" in *'WOULD BE CUT'*) refused="${refused:+$refused, and }the wake's cut" ;; esac
  case "$out" in *"the store's refusals pass"*) saw_store=yes ;; esac
  case "$out" in *'the wake carries all'*) saw_wake=yes ;; esac
  if [ -n "$refused" ]; then
    printf '\nREFUSED: the gate printed %s and exited clean, so the two disagree.\n' "$refused"
    printf 'The text wins, because it is the half a reader checks. Nothing was posted.\n'
    return 1
  fi
  if [ -z "$saw_store" ] || [ -z "$saw_wake" ]; then
    printf '\nCOULD NOT LOOK: the gate exited clean without printing the verdict it prints on every pass'
    [ -n "$saw_store" ] || printf ', and the store half is the one missing'
    [ -n "$saw_wake" ] || printf ', and the wake half is the one missing'
    printf '.\n'
    printf 'A pass is a verdict in the text, never a quiet exit, so nothing was posted. Run %s --body yourself:\n' "$GATE"
    printf 'either it has stopped answering on this box, or its pass wording moved and this belt needs the new words.\n'
    return 2
  fi
  return 0
}

# Did the server say it cut the body? Same class as the belt, and the same
# reason for `case` over `grep`: a false failure from a second process here
# would report a body the server cut as posted whole, and this is the one
# assertion this file makes about its own correctness. Whitespace is flattened
# first so the answer does not depend on how the server spaces its JSON, which
# the old pattern's ` *` only half covered — a newline between the colon and
# the value read as not truncated. Lifted out of `post` because `post` needs a
# live board and a reachable one, and this needs neither to be asked.
truncated() {  # $1 = the server's answer; 0 it says it cut the body, 1 it does not
  local flat=${1//[$' \t\r\n']/}
  case "$flat" in *'"body_truncated":true'*) return 0 ;; esac
  return 1
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
  if truncated "$resp"; then
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
  check() { case "$2" in *"$3"*) echo "  ok   $1" ;; *) echo "  FAIL $1: wanted '$3' in: $(tail -3 <<<"$2")"; fail=1 ;; esac; }

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
json.dump({"seat":"exo","company":"epitome","to_seat":"epitome/pm","kind":"handoff",
           "subject":"a slash folded into the seat name","body":"one short paragraph, well under the limit."},
          open(os.path.join(os.sys.argv[1],"slash.json"),"w"))
json.dump({"seat":"exo","company":"epitome","to_seat":"pm","kind":"handoff",
           "subject":"a seat with no company of its own","body":"one short paragraph, well under the limit."},
          open(os.path.join(os.sys.argv[1],"nocompany.json"),"w"))
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
  case "$out" in *'could not look'*)
    echo "  FAIL a wake-cut body must not be reported as could-not-look"; fail=1 ;;
  esac

  out=$(gate "$T/short.json"); rc=$?
  check "a body that fits is not refused" "$out" "under its 1500 limit"
  [ $rc = 0 ] || { echo "  FAIL exit for a body that fits: $rc"; fail=1; }

  out=$(gate "$T/nobody.json" 2>&1); rc=$?
  check "a payload with no body cannot be gated and is not posted" "$out" "nothing to gate"
  [ $rc = 2 ] || { echo "  FAIL exit for a payload with no body: $rc"; fail=1; }

  out=$(gate "$T/notjson.json" 2>&1); rc=$?
  check "an unparseable payload is could-not-look, never a pass" "$out" "cannot gate this payload"
  [ $rc = 2 ] || { echo "  FAIL exit for an unparseable payload: $rc"; fail=1; }

  out=$(gate "$T/slash.json" 2>&1); rc=$?
  check "a slash in to_seat is refused before the route sees it" "$out" "is not an address"
  [ $rc = 2 ] || { echo "  FAIL exit for a slash in the seat name: $rc"; fail=1; }

  out=$(gate "$T/nocompany.json" 2>&1); rc=$?
  check "to_seat with no to_company is refused before the route sees it" "$out" "needs a company"
  [ $rc = 2 ] || { echo "  FAIL exit for an addressee with no company: $rc"; fail=1; }
  # ---- the belt's own branches, which until this run had never fired -------
  # The belt is the one assertion this file makes about the gate it runs, and
  # nothing here had ever made it decide anything: every fixture above reaches
  # it with a gate that agreed with its own exit status. These three make it
  # decide, by standing in a gate that does not.
  #
  # The text is copied, not written. It is the output
  # `docs/agents/addressed.sh --body` really produced on this box on
  # 2026-10-27 for the 1700-character fixture body above — the shape of the
  # real 2026-10-26T11:02:58Z note, whose cut fell on the ask — captured whole
  # and pasted. What changes in each stub is the exit status and how much of
  # that output arrives, because those are the two ways a gate lies.
  local real_gate_out gate_was=$GATE
  real_gate_out="== 1 body, none identical: referents below are advisory ==
  (each addressee gets its own body, which is the repair L37 asks for)
== what the write path will do, performed by /srv/asc/hq/runtime/board/store.py and /srv/asc/hq/runtime/board/api.py ==
  /tmp/tmp.tcQYsViGcX/cut-body.txt
  NOT CHECKED       the data field, which the store also refuses on: a data.files that is not a list of paths is a 400 this check cannot see from a body file
  the store's refusals pass, every one this check can reach, performed by its own code
  WOULD BE CUT      the wake carries 1425 of 1700 characters, limit 1500; 2 paragraph(s) are not delivered
                    - A tenth, because a fixture that needs exact arithmetic to stay valid is a fixture that f
                    - And the ask, last, because that is where the house style puts a disposition and therefor
                    the reader is told to fetch the rest from the board, which costs them a call they may not make: put the ask above the cut, or split the message"

  # 1. A verdict in the text, a clean exit: the case the belt was written for.
  { printf '#!/usr/bin/env bash\ncat <<%s\n%s\n%s\nexit 0\n' "'EOGATE'" "$real_gate_out" EOGATE; } > "$T/stub-clean-exit.sh"
  GATE="$T/stub-clean-exit.sh"
  out=$(gate "$T/short.json" 2>&1); rc=$?
  check "a refusal in the text with a clean exit is refused, not posted" "$out" "REFUSED: the gate printed"
  check "the refusal names which half refused" "$out" "the wake's cut"
  [ $rc = 1 ] || { echo "  FAIL exit for a printed refusal and a clean exit: $rc"; fail=1; }

  # 2. Silence and a clean exit: the direction the old belt read as a pass,
  # which is the whole fault. A gate that prints nothing has not answered.
  printf '#!/usr/bin/env bash\nexit 0\n' > "$T/stub-silent.sh"
  GATE="$T/stub-silent.sh"
  out=$(gate "$T/short.json" 2>&1); rc=$?
  check "a silent gate with a clean exit is could-not-look, never a pass" "$out" "COULD NOT LOOK"
  [ $rc = 2 ] || { echo "  FAIL exit for a silent gate: $rc"; fail=1; }
  # `posted whole` is printed by `post` and by nothing else, so its absence is
  # the assertion that the refusal path never reached the network.
  case "$out" in *'posted whole'*) echo "  FAIL a silent gate must not report a post"; fail=1 ;; esac

  # 3. Half the output and a clean exit — a gate that died after the store
  # half, which is exactly what a SIGPIPE'd producer leaves behind. The store
  # half passed and the wake half never answered, and the belt must say which.
  { printf '#!/usr/bin/env bash\ncat <<%s\n%s\n%s\nexit 0\n' "'EOGATE'" \
      "$(printf '%s\n' "$real_gate_out" | sed -n '1,6p')" EOGATE; } > "$T/stub-half.sh"
  GATE="$T/stub-half.sh"
  out=$(gate "$T/short.json" 2>&1); rc=$?
  check "a gate that answered one half of its job is could-not-look" "$out" "the wake half is the one missing"
  [ $rc = 2 ] || { echo "  FAIL exit for a half-answered gate: $rc"; fail=1; }
  GATE=$gate_was

  # ---- the claim this file makes about its own correctness ----------------
  # The answer below is the real one the board returned at 2026-10-27T01:32:51Z
  # to the send this run made through this very script, pasted whole. The
  # `false` case is therefore a real surface and not a plausible one.
  #
  # The `true` case is that same answer with the one value flipped, and it is
  # the only input here that is not copied: producing a real truncated answer
  # means deliberately posting an over-limit body to the live board, which is
  # the act this whole file exists to prevent. Said plainly rather than left
  # for a reader to assume.
  local real_answer
  real_answer='{"id": "703fb6f3-1ccd-4130-a576-ca517a804179", "ts": "2026-10-27T01:32:51.155675+00:00", "from_seat": "engineer", "from_company": "epitome", "to_seat": "pm", "to_company": "epitome", "kind": "done", "surface": null, "subject": "The belt asks for a verdict now, the flag is lifted, and the trunk reading that decided your pass was the one before the conversions", "ref": null, "expires_at": null, "body_chars": 1336, "body_delivered": 1336, "body_truncated": false, "wake_limit": 1500}'
  truncated "$real_answer" \
    && { echo "  FAIL the server's real answer says false and must not read as a cut"; fail=1; } \
    || echo "  ok   the server's own answer, untouched, reads as not truncated"
  truncated "${real_answer/\"body_truncated\": false/\"body_truncated\": true}" \
    && echo "  ok   the same answer with the one value flipped reads as a cut" \
    || { echo "  FAIL a truncated answer must be read as one"; fail=1; }
  # The spacing the old pattern only half covered: ` *` never crossed a
  # newline, so a server that wrapped its JSON there read as not truncated.
  truncated "${real_answer/\"body_truncated\": false/\"body_truncated\":
      true}" \
    && echo "  ok   and it reads the same across a line break in the answer" \
    || { echo "  FAIL whitespace in the answer must not decide this"; fail=1; }

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
