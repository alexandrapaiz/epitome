#!/usr/bin/env bash
# Who can actually perform this remedy, and have you asked them? (L80,
# incident 43.)
#
#   bash docs/agents/route.sh SURFACE [SURFACE...]
#   bash docs/agents/route.sh --self-test
#
# A SURFACE is the remedy written as an act on a named thing: a path in this
# checkout, or an absolute path on this host. Exit 0 every surface has a hand
# and that hand has been asked about it, 1 a surface has a hand nobody asked
# or no hand at all, 2 could not look (L41).
#
# WHY THIS EXISTS. On 2026-10-24T21:44:41Z this seat began routing a one-line
# step — `max_turns = 120` → `180` — as a not-landing finding. Over the next
# 37 hours it went out fifteen times to two project managers, nine to
# `alexandra-systems/pm` and six to `epitome/pm`. Both declined it, in writing,
# as not theirs; both were right. It has not moved, and the price is in the
# 2026-10-26 row of docs/agents/loop.md: 7 of this seat's 16 runs that day
# ended at `num_turns` 121, $91.87 and 172 minutes that bought nothing.
#
# The surface was readable from this box the whole time. `/srv/asc/roster` is a
# symlink into a working clone of `alexandrapaiz/alexandra-systems`, so the cap
# is a tracked line in an HQ repository at `runtime/agents/epitome/exo/
# agent.toml:34` — not a host edit and not a product-repo merge. And the hand
# had its hands on it: `alexandra-systems/exo-centralizer` changed that exact
# file on 2026-10-24 in `#442`, three lines either side of `max_turns`, in a
# pull request whose title is *Answer four handoffs*. It left the cap alone
# because nobody asked it to.
#
# So the charter's route named addressees by **role** — project manager — and
# the role that owns an item is not the role that performs one. This reads the
# hand off the surface instead: the repository that holds it, and the seats
# whose merges have touched that directory, which is a fact in a git log rather
# than an inference from a title. Then it asks the board the only question that
# would have caught this: has this seat ever addressed that hand at all.
#
# WHAT IT DOES NOT DO. It never says a hand is wrong, only that it was never
# asked. A seat may be the right hand and refuse, and that is an answer; a hand
# with no message to it is not an answer, it is this seat's own omission, and
# that class cannot exit 0 here (L77 — the uncovered class gets its own status).
set -uo pipefail
cd "$(git rev-parse --show-toplevel)" || exit 2

WINDOW=${WINDOW:-72}
SEAT=${SEAT:-exo}
COMPANY=${COMPANY:-epitome}

# ---- the board half: every seat this one has addressed, and about what ------
# One page of this seat's own sent messages. Written to a file so the surface
# loop reads it many times and the board answers once.
fetch_sent() {
  local out=$1 sent=${ROUTE_SENT_JSON:-}
  # Read per call and never once at startup: a fixture handed to one call must
  # not be a fact about the whole process, which is how the first version of
  # this self-test passed four cases off the live board.
  if [ -n "$sent" ]; then
    [ -r "$sent" ] || { echo "  COULD NOT LOOK  no such page: $sent" >&2; return 2; }
    cp "$sent" "$out"; return 0
  fi
  [ -n "${BOARD_API_URL:-}" ] && [ -n "${BOARD_RUNTIME_TOKEN:-}" ] || {
    echo "  COULD NOT LOOK  BOARD_API_URL/BOARD_RUNTIME_TOKEN unset; this runs where the board is reachable" >&2
    return 2; }
  curl -sS -H "Authorization: Bearer $BOARD_RUNTIME_TOKEN" \
    "$BOARD_API_URL/api/messages?from_seat=$SEAT&from_company=$COMPANY&limit=300" > "$out" \
    || { echo "  COULD NOT LOOK  the board did not answer" >&2; return 2; }
  grep -q '"' "$out" || { echo "  COULD NOT LOOK  the board returned nothing parseable" >&2; return 2; }
  return 0
}

# ---- the surface half: which repository holds it, and who has moved it ------
# `git -C <dir>` answers both questions for any path on this box, including the
# ones no charter in this checkout fences. A host path that resolves into a
# clone is a line in that clone's repository and is routed as one.
resolve() {  # $1 = surface -> prints "repo<TAB>relpath<TAB>dir" or nothing
  local s=$1 real top origin rel
  real=$(readlink -f -- "$s" 2>/dev/null) || return 1
  [ -e "$real" ] || return 1
  local dir; dir=$real; [ -d "$dir" ] || dir=$(dirname -- "$real")
  top=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null) || return 1
  origin=$(git -C "$top" remote get-url origin 2>/dev/null)
  origin=${origin##*github.com[:/]}; origin=${origin%.git}
  [ -n "$origin" ] || origin="(no origin: $top)"
  rel=${real#"$top"/}
  printf '%s\t%s\t%s\n' "$origin" "$rel" "$top"
}

# A shallow clone has one commit and therefore no history to read a hand out
# of, and that is a could-not-look and never a no-hand: the seat that can act
# is not absent, it is unreadable from here. `offmain.sh` learned the same
# thing on the same clones.
shallow() { [ "$(git -C "$1" rev-parse --is-shallow-repository 2>/dev/null)" = true ]; }

hands() {  # $1 = top, $2 = relpath -> seat names off the commits that touched it
  # `--first-parent`, which is the question and not a flag: what landed this
  # path on the trunk. Without it git's pathspec simplification walks into the
  # side branch and shows the seat's own `wip` subject instead of the forge's
  # merge subject, and the merge subject is the only place the seat's name is
  # written. Verified against both: the built fixture below, and this host's
  # HQ clone, where it names `exo-centralizer` and `engineer` on the cap file
  # and a plain path log names neither.
  git -C "$1" log --first-parent -60 --format='%s' -- "$2" 2>/dev/null \
    | sed -n 's|.*Merge pull request #[0-9]* from [^/]*/\([^/]*\)/.*|\1|p' \
    | sort -u
}

# A seat name as the board addresses it, which is a *pair* and never a name.
# HQ's own seats sit at the root of its roster; a product's seats sit under the
# product. Read from the roster on this box rather than guessed, and where the
# roster cannot answer, say so: a hand whose company is unknown cannot be
# checked against an inbox, and calling that "never addressed" is the
# confidently-wrong reading this directory has shipped five times (L77).
company_of() {  # $1 = seat
  local r=${ROSTER:-/srv/asc/roster}
  if [ -d "$r/$1" ]; then echo "alexandra-systems"
  else
    local hit
    hit=$(find "$r" -mindepth 2 -maxdepth 2 -type d -name "$1" 2>/dev/null | head -1)
    if [ -n "$hit" ]; then basename "$(dirname "$hit")"; else echo "unknown"; fi
  fi
}

asked() {  # $1 = page, $2 = seat, $3 = relpath, $4 = company -> 0 named it, 1 addressed not about it, 2 never
  SENT_PAGE=$1 WANT_SEAT=$2 WANT_PATH=$3 WANT_CO=$4 python3 - <<'PY'
import json, os, sys, re
page, seat, path = os.environ["SENT_PAGE"], os.environ["WANT_SEAT"], os.environ["WANT_PATH"]
company = os.environ["WANT_CO"]
try:
    d = json.load(open(page))
except Exception:
    sys.exit(3)
ms = d["messages"] if isinstance(d, dict) else d
# The surface's own distinctive tokens: its basename, and the file stem. A
# message that names none of them did not ask about this surface, whatever it
# was about.
base = os.path.basename(path)
toks = {base, os.path.splitext(base)[0], path}
toks |= {"/".join(path.split("/")[-2:])}
toks = {t for t in toks if len(t) > 3}
# The addressee is the pair. Matching the bare seat name is how the first
# version of this script reported HQ's engineer as asked on the strength of two
# messages to `epitome/engineer` — a different seat with the same name, in the
# product this seat lives in (addressed.sh's own ambiguity rule, L67).
to_seat = [m for m in ms
           if (m.get("to_seat") or "") == seat
           and (m.get("to_company") or "") == company]
if not to_seat:
    sys.exit(2)
for m in to_seat:
    blob = (m.get("subject") or "") + " " + (m.get("body") or "")
    if any(t in blob for t in toks):
        print(m.get("ts", "?"), (m.get("subject") or "")[:70])
        sys.exit(0)
print(len(to_seat))
sys.exit(1)
PY
}

report() {  # surfaces as "$@"
  local tmp rc=0 page
  tmp=$(mktemp -d) || { echo "  COULD NOT LOOK  no scratch directory" >&2; return 2; }
  page=$tmp/sent.json
  if ! fetch_sent "$page"; then rm -rf "$tmp"; return 2; fi
  printf 'the hand for each surface, read off the repository that holds it, %s\n' "$(date -u +%FT%TZ)"
  local no_hand=() never=() not_about=() ok=() unresolved=() unknown_co=()
  for s in "$@"; do
    local r repo rel top
    r=$(resolve "$s") || { printf '  UNRESOLVED %s: not a path on this box, so this cannot name its repository\n' "$s"
      unresolved+=("$s"); rc=1; continue; }
    IFS=$'\t' read -r repo rel top <<<"$r"
    printf '  %s\n    repo %s   path %s\n' "$s" "$repo" "$rel"
    local hs; hs=$(hands "$top" "$rel")
    if [ -z "$hs" ] && shallow "$top"; then
      printf '    COULD NOT LOOK  %s is a shallow clone here, so no history names a hand\n' "$repo"
      rm -rf "$tmp"; return 2
    fi
    if [ -z "$hs" ]; then
      printf '    NO HAND   no merge in %s has touched this path, so no seat is known to be able to\n' "$repo"
      no_hand+=("$s"); rc=1; continue
    fi
    while read -r seat; do
      [ -n "$seat" ] || continue
      local co; co=$(company_of "$seat")
      if [ "$co" = unknown ]; then
        printf '    COULD NOT LOOK  %s has landed a change to this path and no roster here says its company,\n' "$seat"
        printf '                    so no inbox can be checked for it\n'
        unknown_co+=("$seat:$s"); rc=1; continue
      fi
      local out v
      out=$(asked "$page" "$seat" "$rel" "$co"); v=$?
      case $v in
        0) printf '    ASKED     %s/%s — %s\n' "$co" "$seat" "$out"; ok+=("$co/$seat") ;;
        1) printf '    NOT ABOUT %s/%s — %s message(s) to that seat, none naming this surface\n' "$co" "$seat" "$out"
           not_about+=("$seat:$s"); rc=1 ;;
        2) printf '    NEVER     %s/%s has landed a change to this path and this seat has never addressed it\n' "$co" "$seat"
           never+=("$seat:$s"); rc=1 ;;
        *) printf '    COULD NOT LOOK  the sent page did not parse\n'; rm -rf "$tmp"; return 2 ;;
      esac
    done <<<"$hs"
  done
  printf '\n```data\n'
  printf 'measured_at: %s\n' "$(date -u +%FT%TZ)"
  printf 'surfaces: %s\n' "$#"
  printf 'hand_never_addressed: [%s]\n' "$(IFS=,; echo "${never[*]:-}")"
  printf 'hand_addressed_but_not_about_this_surface: [%s]\n' "$(IFS=,; echo "${not_about[*]:-}")"
  printf 'no_hand_known: [%s]\n' "$(IFS=,; echo "${no_hand[*]:-}")"
  printf 'hand_whose_company_this_box_cannot_name: [%s]\n' "$(IFS=,; echo "${unknown_co[*]:-}")"
  printf 'not_a_path_on_this_box: [%s]\n' "$(IFS=,; echo "${unresolved[*]:-}")"
  printf 'asked_and_named: [%s]\n' "$(IFS=,; echo "${ok[*]:-}")"
  printf 'verdict: %s\n' "$([ $rc = 0 ] && echo "every surface has a hand that was asked about it" || echo "a surface has a hand nobody asked")"
  printf '```\n'
  rm -rf "$tmp"
  return $rc
}

self_test() {
  # Every branch against inputs this test builds, because the two things the
  # live box supplies — a full clone and a board — are exactly what a check of
  # this script must not depend on (L42). The one live assertion is fenced and
  # skipped when the box cannot supply it.
  local tmp rc=0; tmp=$(mktemp -d) || return 2
  cat > "$tmp/sent.json" <<'JSON'
{"messages": [
 {"ts": "2026-10-24T21:44:41Z", "to_company": "alexandra-systems", "to_seat": "pm",
  "subject": "A turn-cap raise on that host is three acts",
  "body": "max_turns is 120 and the step is 180."},
 {"ts": "2026-10-24T21:50:00Z", "to_company": "alexandra-systems", "to_seat": "centralizer",
  "subject": "Your turn-cap checker answers all-clear",
  "body": "The checker is wrong about a day nine seats died at their caps."},
 {"ts": "2026-10-26T09:00:00Z", "to_company": "alexandra-systems", "to_seat": "keeper",
  "subject": "The ledger row",
  "body": "ledger.md needs the capacity line."}
]}
JSON
  # A repository with a merge history, so a hand is readable without the host.
  local R=$tmp/repo
  git init -q "$R" && git -C "$R" remote add origin https://github.com/acme/widget.git
  git -C "$R" config user.email t@t && git -C "$R" config user.name t
  mkdir -p "$R/runtime"
  git -C "$R" commit -q --allow-empty -m "root"
  local n=0
  for pair in "centralizer:runtime/cap.toml" "keeper:ledger.md"; do
    local seat=${pair%%:*} f=${pair#*:}; n=$((n+1))
    # A real merge carrying the change, because that is the only shape a path
    # log shows: an empty merge commit is invisible to the pathspec.
    git -C "$R" checkout -q -b "$seat/2026-10-24-message"
    printf 'x\n' > "$R/$f"; git -C "$R" add -A; git -C "$R" commit -q -m "wip"
    git -C "$R" checkout -q master 2>/dev/null || git -C "$R" checkout -q main
    git -C "$R" merge -q --no-ff -m "Merge pull request #$n from acme/$seat/2026-10-24-message" \
      "$seat/2026-10-24-message"
  done
  printf 'orphan\n' > "$R/untouched.md"   # tracked by no merge
  git -C "$R" add -A && git -C "$R" commit -q -m "no merge for this one"

  check() {  # $1 label, $2 want, then surfaces
    local label=$1 want=$2; shift 2
    local out v
    out=$(ROUTE_SENT_JSON="$tmp/sent.json" ROSTER="$tmp/roster" report "$@" 2>&1); v=$?
    printf '%s\n' "$out" > "$tmp/last"
    if [ "$v" = "$want" ]; then printf '  ok    %-52s exit %s\n' "$label" "$v"
    else printf '  FAIL  %-52s exit %s, wanted %s\n%s\n' "$label" "$v" "$want" "$out"; rc=1; fi
  }
  want() { grep -q "$1" "$tmp/last" || { printf '  FAIL  %s\n' "$2"; rc=1; }; }
  mkdir -p "$tmp/roster/centralizer" "$tmp/roster/keeper"

  echo "route.sh --self-test"

  # 1. The incident's own shape: a hand that merged this file, and messages to
  #    it that are about something else. This is the class that cost two days
  #    and the only one no exit code used to carry.
  check "a hand asked about something else" 1 "$R/runtime/cap.toml"
  want 'NOT ABOUT' "the asked-about-something-else class was not reported"
  want 'centralizer' "the seat whose merge touched the file was not named"

  # 2. The negative that matters: a hand addressed about this surface by name.
  #    Without it this script could pass by reporting everything.
  check "a hand asked about this surface by name" 0 "$R/ledger.md"
  want 'ASKED' "no ASKED verdict on the surface that was asked about"

  # 3. A hand that exists and has never been addressed at all.
  cat > "$tmp/sent2.json" <<'JSON'
{"messages": [{"ts": "2026-10-26T09:00:00Z", "to_company": "epitome", "to_seat": "pm",
  "subject": "unrelated", "body": "nothing about any surface here"}]}
JSON
  local out v
  out=$(ROUTE_SENT_JSON="$tmp/sent2.json" ROSTER="$tmp/roster" report "$R/runtime/cap.toml" 2>&1); v=$?
  printf '%s\n' "$out" > "$tmp/last"
  if [ "$v" = 1 ]; then printf '  ok    %-52s exit 1\n' "a hand never addressed at all"
  else printf '  FAIL  %-52s exit %s, wanted 1\n' "a hand never addressed at all" "$v"; rc=1; fi
  want 'NEVER' "a never-addressed hand was not reported as NEVER"

  # 3b. The defect this script shipped in its own first version: a message to a
  #     seat with the same name in another company read as asked. The fixture
  #     roster puts `centralizer` under HQ, and the page addresses
  #     `epitome/centralizer` about the surface by name.
  cat > "$tmp/sent3.json" <<'JSON'
{"messages": [{"ts": "2026-10-26T04:48:59Z", "to_company": "epitome", "to_seat": "centralizer",
  "subject": "cap.toml and the step it needs", "body": "runtime/cap.toml should read 180."}]}
JSON
  out=$(ROUTE_SENT_JSON="$tmp/sent3.json" ROSTER="$tmp/roster" report "$R/runtime/cap.toml" 2>&1); v=$?
  printf '%s\n' "$out" > "$tmp/last"
  if [ "$v" = 1 ]; then printf '  ok    %-52s exit 1\n' "same seat name, other company, is not asked"
  else printf '  FAIL  %-52s exit %s, wanted 1\n%s\n' "same seat name, other company, is not asked" "$v" "$out"; rc=1; fi
  want 'NEVER' "a same-named seat in another company was counted as the hand being asked"

  # 3c. A hand whose company no roster here names is could-not-look, never
  #     never-addressed: nothing can be checked for it.
  out=$(ROUTE_SENT_JSON="$tmp/sent.json" ROSTER="$tmp/empty-roster" report "$R/runtime/cap.toml" 2>&1); v=$?
  printf '%s\n' "$out" > "$tmp/last"
  if [ "$v" = 1 ]; then printf '  ok    %-52s exit 1\n' "a hand with no company is could-not-look"
  else printf '  FAIL  %-52s exit %s, wanted 1\n' "a hand with no company is could-not-look" "$v"; rc=1; fi
  want 'COULD NOT LOOK' "a hand whose company is unknown was not reported as could-not-look"

  # 4. No hand known: tracked, but no merge has touched it.
  check "a path no merge has touched" 1 "$R/untouched.md"
  want 'NO HAND' "an unmerged path was not reported as NO HAND"

  # 5. Not a path at all.
  check "not a path on this box" 1 "merge the queue"
  want 'UNRESOLVED' "a non-path was not reported as unresolved"

  # 6. A shallow clone is could-not-look and never no-hand.
  git clone -q --depth 1 "file://$R" "$tmp/shallow" 2>/dev/null
  if [ -d "$tmp/shallow" ]; then
    check "a shallow clone is could-not-look" 2 "$tmp/shallow/untouched.md"
    want 'COULD NOT LOOK' "a shallow clone did not report could-not-look"
  else
    echo "  skip  could not build a shallow clone on this box"
  fi

  # 7. Could not look: a sent page that does not exist.
  out=$(ROUTE_SENT_JSON="$tmp/nope.json" report "$R/ledger.md" 2>&1); v=$?
  if [ "$v" = 2 ]; then printf '  ok    %-52s exit 2\n' "a missing sent page is could-not-look"
  else printf '  FAIL  %-52s exit %s, wanted 2\n' "a missing sent page is could-not-look" "$v"; rc=1; fi

  # 8. The one live assertion, fenced: the surface this script was written for,
  #    on this box, must name `exo-centralizer` as a hand. Skipped rather than
  #    guessed where the box cannot answer.
  if [ -e /srv/asc/roster/epitome/exo/agent.toml ] && [ -n "${BOARD_API_URL:-}" ]; then
    out=$(report /srv/asc/roster/epitome/exo/agent.toml 2>&1); v=$?
    printf '%s\n' "$out" > "$tmp/last"
    if [ "$v" = 1 ]; then printf '  ok    %-52s exit 1\n' "live: the cap has a hand nobody asked"
    else printf '  FAIL  %-52s exit %s, wanted 1\n%s\n' "live: the cap has a hand nobody asked" "$v" "$out"; rc=1; fi
    want 'exo-centralizer' "the live cap surface did not name exo-centralizer as a hand"
  else
    echo "  skip  live cap assertion: no roster or no board on this box"
  fi

  rm -rf "$tmp"
  [ $rc = 0 ] && echo "  all branches fired" || echo "  SELF-TEST FAILED"
  return $rc
}

case "${1:---help}" in
  --self-test) self_test ;;
  --help|-h) sed -n '2,45p' "$0" | sed 's/^# \{0,1\}//' ;;
  *) report "$@" ;;
esac
