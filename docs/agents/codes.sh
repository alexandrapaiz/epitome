#!/usr/bin/env bash
# Does the sentence still stand with the code deleted? (L14, L65.)
#
#   bash docs/agents/codes.sh --pr N              a pull request's title and opening
#   bash docs/agents/codes.sh --branch [NAME]     the open pull request on a branch
#   bash docs/agents/codes.sh --title TEXT [--body FILE]
#                                                 text you have not posted yet
#   bash docs/agents/codes.sh --audit [limit]     every pull request, by seat, with
#                                                 the denominator, ending in a data block
#   bash docs/agents/codes.sh --self-test         fires on a known positive
#
# Exit 0 clean, 1 a code is in a place the owner reads, 2 could not look (L41).
#
# WHY THIS EXISTS. The rule is not new and it is not local. The owner ruled on
# 2026-09-27, verbatim: "i dont want to see adrs, for me its just random codes.
# id rather have good descriptions." It is law in two vendored company
# standards — `docs/standards/documents.md:134` for anything she reads, and
# `docs/standards/pm.md:544` for a board item — and in this product's own
# register as L14, which named the surface: a pull request description is the
# owner-facing artifact this org has most of.
#
# The board enforces it with a machine. `addressed.sh` records the write path's
# own answer: a code or a pull request number in the prose of a board message
# is a 400 naming the token, refused with the seat still in the room. GitHub
# refuses nothing. So the one surface the register itself calls the one she
# reads most is the one surface with no gate on it, and the measurement says
# exactly that: across 323 pull requests, 29 titles carry a register code and
# 51 carry a pull request number, every one of them accepted silently.
#
# And the rate is not discipline. It tracks how numbered a seat's own subject
# matter is, which is why a clause has never moved it (L65): `epitome-engineer`
# is 0 of 33 titles and was 0 of 27 before the clause naming the pull request
# body landed in its charter on 2026-10-24, so its clean record is not that
# clause working. `epitome-exo` is 15 of 52, because every run of that seat
# produces a numbered register entry and the title wants to name it. So
# `--audit` prints the denominator beside every rate: a register that reads a
# clean seat as a working clause has measured the cost of the rule to that
# seat and called it obedience.
#
# Reads only. `gh` for --pr/--branch/--audit; nothing for --title.
set -uo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)"

# Two classes, because each seat fails its own and a single count hides which.
# A register code is an L/ADR/incident identifier. A reference is a pull
# request number. Both are "random codes" to the reader; they are not the same
# habit, and the repair for one is not the repair for the other.
REGEX_REGISTER='\b(L-?[AEXP]?[0-9]+|ADR-[0-9]+|[Ii]ncident [0-9]+)\b'
REGEX_REFERENCE='#[0-9]+'

# The first paragraph, not the whole body. The rule reaches as far as what she
# reads before deciding whether to keep reading, and the standard says a code
# may sit in parentheses at the end of a line further down. A heading is not a
# paragraph: a body opening with "## What was learned" has its first sentence
# in the block after it.
first_para() {
  python3 -c '
import sys
for para in sys.stdin.read().strip().split("\n\n"):
    t = para.strip()
    if t and not t.lstrip().startswith("#"):
        print(t); break
'
}

# L14's own test, performed rather than remembered: delete the codes and print
# what is left, so the reader judges the sentence instead of the count.
verdict() {  # verdict <label> <text>; sets rc=1 on a hit
  local label=$1 text=$2 hits stripped
  hits=$(grep -oE "$REGEX_REGISTER|$REGEX_REFERENCE" <<<"$text" | sort -u | paste -sd' ')
  if [ -z "$hits" ]; then
    printf '  %-16s clean\n' "$label"; return 0
  fi
  stripped=$(sed -E "s/$REGEX_REGISTER//g; s/$REGEX_REFERENCE//g; s/\([,;: ]*\)//g; s/  +/ /g; s/^[ ,:;—-]+//" <<<"$text")
  printf '  %-16s CARRIES %s\n' "$label" "$hits"
  printf '    as she reads it: %s\n' "$(cut -c1-300 <<<"$stripped")"
  printf '    if that sentence no longer stands on its own, the sentence is what to rewrite, not the code\n'
  rc=1
}

mode=${1:---branch}
rc=0

case "$mode" in
  --pr|--branch)
    command -v gh >/dev/null || { echo "no gh, so this cannot look (L41)" >&2; exit 2; }
    if [ "$mode" = --pr ]; then
      num=${2:?--pr needs a number}
    else
      br=${2:-$(git rev-parse --abbrev-ref HEAD)}
      num=$(gh pr list --head "$br" --state open --limit 1 --json number --jq '.[0].number' 2>/dev/null)
      [ -n "$num" ] && [ "$num" != null ] || {
        echo "no open pull request on $br, so there is no title to read yet (L41)"; exit 2; }
    fi
    json=$(gh pr view "$num" --json title,body 2>/dev/null) || {
      echo "could not read pull request $num (L41)" >&2; exit 2; }
    title=$(jq -r .title <<<"$json")
    body=$(jq -r .body <<<"$json" | first_para)
    echo "pull request $num, the two places she reads before deciding to keep reading"
    verdict title "$title"
    verdict "first paragraph" "$body"
    ;;

  --title)
    title=${2:?--title needs text}
    echo "text not yet posted"
    verdict title "$title"
    if [ "${3:-}" = --body ]; then
      [ -r "${4:-}" ] || { echo "cannot read ${4:-<none>} (L41)" >&2; exit 2; }
      verdict "first paragraph" "$(first_para < "$4")"
    fi
    ;;

  --audit)
    command -v gh >/dev/null || { echo "no gh, so this cannot look (L41)" >&2; exit 2; }
    limit=${2:-400}
    gh pr list --state all --limit "$limit" --json number,title,body,headRefName \
      > /tmp/codes-audit.$$.json 2>/dev/null || {
        echo "could not list pull requests (L41)" >&2; exit 2; }
    REGEX_REGISTER="$REGEX_REGISTER" REGEX_REFERENCE="$REGEX_REFERENCE" \
    python3 - /tmp/codes-audit.$$.json <<'PY'
import json, re, sys, os
from collections import Counter
prs = json.load(open(sys.argv[1]))
reg = re.compile(os.environ['REGEX_REGISTER'].replace(r'\b', r'\b'))
ref = re.compile(os.environ['REGEX_REFERENCE'])
def first_para(b):
    for p in (b or '').strip().split('\n\n'):
        t = p.strip()
        if t and not t.lstrip().startswith('#'): return t
    return ''
def seat(p):
    h = p['headRefName']
    return h.split('/')[0] if '/' in h else h
n, tr, pr_, tf = Counter(), Counter(), Counter(), Counter()
for p in prs:
    s = seat(p); n[s] += 1
    if reg.search(p['title']): tr[s] += 1
    if reg.search(first_para(p['body'])): pr_[s] += 1
    if ref.search(p['title']): tf[s] += 1
print(f"{'seat':22} {'PRs':>4} {'register code in title':>23} {'in 1st para':>16} {'a #N in title':>16}")
def pct(a, b): return f"{a:>4} ({100*a//b:>3}%)" if b else "   - "
for s, c in n.most_common():
    print(f"{s:22} {c:>4} {pct(tr[s],c):>23} {pct(pr_[s],c):>16} {pct(tf[s],c):>16}")
tot = sum(n.values())
print(f"{'ALL':22} {tot:>4} {pct(sum(tr.values()),tot):>23} {pct(sum(pr_.values()),tot):>16} {pct(sum(tf.values()),tot):>16}")
print()
print("```data")
print("instrument: docs/agents/codes.sh --audit")
print(f"pull_requests_read: {tot}")
print(f"register_code_in_title: {sum(tr.values())}")
print(f"register_code_in_first_paragraph: {sum(pr_.values())}")
print(f"reference_in_title: {sum(tf.values())}")
worst = sorted(((100*tr[s]//c, s, tr[s], c) for s, c in n.items() if c >= 10), reverse=True)
print("rate_by_seat_titles: " + json.dumps({s: f"{a}/{c}" for _, s, a, c in worst}))
print("```")
PY
    rm -f /tmp/codes-audit.$$.json
    ;;

  --self-test)
    # A detector nobody has seen fire is a second thing written down
    # (L-X1 as amended), so the positive is a real title this seat shipped.
    echo "positive — the title of this seat's own pull request 322:"
    out=$(bash "$0" --title "L63 and the roster the host actually loaded: the cap was the one field that had not drifted" 2>&1); p=$?
    sed 's/^/  /' <<<"$out"
    echo "negative — the same finding named by what it decides:"
    out2=$(bash "$0" --title "The roster the host actually loaded: the cap was the one field that had not drifted" 2>&1); q=$?
    sed 's/^/  /' <<<"$out2"
    if [ $p -eq 1 ] && [ $q -eq 0 ]; then echo; echo "fires on the positive, silent on the negative"
    else echo; echo "SELF-TEST FAILED: positive=$p (want 1) negative=$q (want 0)"; rc=1; fi
    ;;

  *) sed -n '2,12p' "$0"; exit 2 ;;
esac

echo
[ $rc -eq 0 ] && echo "ok" || echo "a code is sitting where she reads first — rewrite the sentence, then re-run"
exit $rc
