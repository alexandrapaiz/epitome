#!/usr/bin/env bash
# Is this pull request mergeable — into the base it will actually merge into?
# (L43, incident 19.)
#
#   bash docs/agents/mergeable.sh            every open pull request
#   bash docs/agents/mergeable.sh 264 271     only these
#   bash docs/agents/mergeable.sh --verdict FILE   a verdict you are about to
#                                             publish: does it name the sha it
#                                             was measured against (L106)
#   bash docs/agents/mergeable.sh --names [limit] [--from FILE]
#                                             which branch names have carried
#                                             more than one pull request, and
#                                             whether an open one is under a
#                                             name already used (L106)
#   bash docs/agents/mergeable.sh --self-test every branch of all three modes
#
# docs/agents/order.sh answers "what can a merger take to main, and in what
# order". docs/agents/landed.sh answers "what left the queue". Neither answers
# the question GitHub asks when somebody clicks merge on one pull request,
# which is whether that head applies to *its own base ref* — and for a stacked
# branch that base is not main.
#
# On 2026-10-24 that gap cost five hours and thirteen minutes. Pull request
# #264's base was `epitome-exo/2026-10-24-message-4`. Two passes of the merging
# seat decided it against main instead, by hand, and the command they wrote
# down says so: `git merge-tree --write-tree origin/main origin/epitome-exo/
# 2026-10-24-message-5`. Against main there is a real add/add conflict in this
# directory's own addressed.sh; against the actual base there is none. The
# branch was declined at 06:53:01Z, re-measured at 07:04Z with the same wrong
# base and the same answer, and merged clean at 12:06:31Z once somebody ran it
# against message-4.
#
# The part worth building a command for is why re-measurement did not catch it.
# A conflict found against the wrong base is usually a TRUE fact about a
# DIFFERENT merge — that file does collide when the whole chain reaches main —
# so it reproduces exactly, reads as confirmation, and the instruction it
# produces is worse than idle: "resolve the addressed.sh conflict" on a branch
# whose merge does not touch addressed.sh means editing away from main's copy
# rather than toward it.
#
# So every verdict here prints the base it was measured against and that base's
# head, both answers when they differ, and never one without the other. Needs a
# full clone and gh.
#
# TWO THINGS THAT CAME BACK AFTER THAT (L106), AND BOTH ARE "A NAME IS NOT A
# KEY". L70 clause 1 retired the population this instrument was built for: no
# pull request here may open against a seat branch any more, and on
# 2026-11-02T07:18Z the sweep below printed `0 do not target main` across all
# nine open. The second column can no longer differ from the first. What the
# card that ordered this instrument actually asked for -- that no seat publish
# a merge verdict without naming what it was measured against -- is still
# false, and the reason is that `main` stopped being an answer the moment the
# queue started merging several times an hour.
#
#   --verdict  A verdict naming only the branch is unfalsifiable after the next
#              merge. 2026-11-02: `a clean merge-tree against main` was
#              published for #407 at 06:42:57Z, and main moved at 07:11:06Z and
#              again at 07:18:22Z. Nobody can now re-run that check. Over the
#              preceding 168 h, 28 board messages published a merge verdict
#              about a numbered pull request and 5 named any base at all. So
#              the claim carries the base's short sha or it is refused here.
#
#   --names    L-A59 deletes a head branch on merge, which frees the name, and
#              a run told to suffix its branch "if it exists" tests the live
#              remote, where a freed name does not exist. 59 of this
#              repository's 416 pull requests sit under a name an earlier pull
#              request already had, across every seat; two of the nine open at
#              07:18Z do, and one of those two is this entry's own. The key for
#              a branch is number@sha, and this mode prints what the name
#              alone cannot distinguish.
set -uo pipefail
cd "$(git rev-parse --show-toplevel)"
MAIN=${MAIN:-origin/main}

# Same reason as order.sh: in a shallow clone merge-tree answers confidently
# and wrongly, and every run of this seat starts from one.
if [ "$(git rev-parse --is-shallow-repository)" = true ]; then
  echo "this clone is shallow, which makes every answer below wrong; unshallowing" >&2
  git fetch -q --unshallow origin 2>/dev/null || {
    echo "could not unshallow — refusing rather than answering wrongly" >&2; exit 2; }
fi

# Three answers and not two (L41): clean, conflict, and could-not-look, and the
# third is spelled so it can never be mistaken for the first.
verdict() {  # verdict <base-ref> <head-ref>; echoes "clean" | "CONFLICT <files>" | "unreadable <why>"
  local base=$1 head=$2 out
  git rev-parse --verify -q "$base" >/dev/null || { echo "unreadable no such ref $base"; return 2; }
  git rev-parse --verify -q "$head" >/dev/null || { echo "unreadable no such ref $head"; return 2; }
  if out=$(git merge-tree --write-tree "$base" "$head" 2>&1); then
    echo clean; return 0
  fi
  local files
  files=$(echo "$out" | sed -nE 's/^CONFLICT \(.*\): Merge conflict in (.*)$/\1/p' | sort -u | tr '\n' ' ')
  [ -z "$files" ] && files=$(echo "$out" | sed -nE 's/^CONFLICT \((.*)\).*/\1/p' | sort -u | tr '\n' ' ')
  echo "CONFLICT ${files:-unnamed}"; return 1
}

# --verdict: a merge claim you are about to publish, read for the one thing that
# makes it checkable later. Three answers (L41): 0 every claim carries a base
# sha, 1 a claim does not, 2 could not look.
#
# The guard's own errors are the thing to watch (L94): the compliant form here
# is a pasted line of this script's output, which carries `base main@eba9d62`
# and passes by construction, and the form that must be allowed to carry the
# shape is a register entry quoting a bad verdict. That one carries the marker
# L106-ALLOW with its reason, the same idiom the secret guard uses, so the rule
# cannot make its own evidence unwritable.
SHA_RE='[0-9a-f]{7,40}'
verdict_text() {  # verdict_text <file>
  local f=$1 bad=0 n=0
  [ -r "$f" ] || { echo "cannot read ${f:-<none>} — could not look (L41)" >&2; return 2; }
  if grep -q 'L106-ALLOW' "$f"; then
    echo "L106-ALLOW present: this text is allowed to carry the shape, so no claim is judged"
    return 0
  fi
  # One claim per sentence, because a body mixes claims with everything else and
  # the base belongs to the claim rather than to the message.
  while IFS= read -r sentence; do
    [ -z "$sentence" ] && continue
    grep -qiE 'merge[sd]? clean|clean merge|merge-tree|mergeab|merge state|conflicts? (with|against)|CONFLICT' <<<"$sentence" || continue
    grep -qiE '(#|pull request )[0-9]{2,4}|this (branch|head)|the branch' <<<"$sentence" || continue
    n=$((n+1))
    if grep -qE "@$SHA_RE|\b$SHA_RE\b" <<<"$sentence"; then
      printf '  ok    %s\n' "${sentence:0:150}"
    else
      bad=$((bad+1))
      printf '  BASE? %s\n' "${sentence:0:150}"
    fi
  done < <(tr '\n' ' ' < "$f" | sed -E 's/([.!?]) +/\1\n/g')
  printf '%d merge claim(s); %d name no sha\n' "$n" "$bad"
  if [ "$bad" -gt 0 ]; then
    echo "a verdict names the sha it was measured against or it cannot be re-run:" >&2
    echo "  run  bash docs/agents/mergeable.sh <N>  and paste the base column, name@sha" >&2
    return 1
  fi
  return 0
}

# --names: which branch names have carried more than one pull request. Exit 1
# when an OPEN one is under a name an earlier pull request already used,
# because that is the state in which a `git rev-parse origin/<name>` run by a
# reader answers about the wrong pull request without saying so.
names_report() {  # names_report [limit] [file]
  local limit=${1:-500} src=${2:-}
  if [ -z "$src" ]; then
    command -v gh >/dev/null || { echo "no gh, so this cannot look (L41)" >&2; return 2; }
    src=$(mktemp)
    gh pr list --state all --limit "$limit" \
      --json number,headRefName,headRefOid,state,createdAt > "$src" 2>/dev/null || {
        echo "could not list pull requests — could not look (L41)" >&2; return 2; }
  fi
  python3 - "$src" <<'PY'
import json, sys, collections
prs = json.load(open(sys.argv[1]))
by = collections.defaultdict(list)
for p in prs:
    by[p["headRefName"]].append(p)
reused = {k: sorted(v, key=lambda p: p["createdAt"]) for k, v in by.items() if len(v) > 1}
live = []
for name, group in sorted(reused.items(), key=lambda kv: kv[1][0]["createdAt"]):
    print(name)
    for p in group:
        print("   #%-5s %-7s %s  created %s"
              % (p["number"], p["state"], p["headRefOid"][:8], p["createdAt"]))
        if p["state"] == "OPEN" and p is not group[0]:
            live.append(p["number"])
total = len(prs)
under = sum(len(v) for v in reused.values())
print()
print("%d pull request(s) read; %d name(s) carried more than one; %d pull request(s) "
      "sit under a reused name" % (total, len(reused), under))
print("%d of them are OPEN right now under a name an earlier pull request already had: %s"
      % (len(live), ", ".join("#%s" % n for n in live) or "none"))
print("the key for a branch is number@sha; `origin/<name>` answers about whichever "
      "one a clone fetched last")
print()
print("```data")
print("instrument: docs/agents/mergeable.sh --names")
print("pull_requests_read: %d" % total)
print("reused_names: %d" % len(reused))
print("pull_requests_under_a_reused_name: %d" % under)
print("open_under_a_reused_name: %d" % len(live))
print("open_under_a_reused_name_prs: %s" % (" ".join("#%s" % n for n in live) or "none"))
print("```")
sys.exit(1 if live else 0)
PY
}

selftest() {
  # L42: the branch an instrument has never been made to hit is the one that
  # decides its answer on the day it hits. Three verdicts, three constructed
  # inputs, built here rather than borrowed from the queue, so this passes or
  # fails the same way on any clone.
  local work root rc=0
  root=$(pwd); work=$(mktemp -d)
  git init -q "$work"; git -C "$work" config user.email x@x; git -C "$work" config user.name x
  echo base > "$work/f"; git -C "$work" add f; git -C "$work" commit -q -m base
  git -C "$work" branch -M trunk
  # A stack: parent diverges from trunk in one file, child adds an untouched one.
  git -C "$work" checkout -q -b parent
  echo parent-side > "$work/shared"; git -C "$work" add shared; git -C "$work" commit -q -m parent
  git -C "$work" checkout -q -b child
  echo child > "$work/own"; git -C "$work" add own; git -C "$work" commit -q -m child
  # trunk independently grows a different version of the same shared file.
  git -C "$work" checkout -q trunk
  echo trunk-side > "$work/shared"; git -C "$work" add shared; git -C "$work" commit -q -m trunk
  # And a branch that genuinely conflicts with its own base. The base has to
  # move AFTER the branch leaves it, or the merge is a fast-forward and comes
  # back clean — which is how the first draft of this self-test disagreed with
  # a correct instrument, and is the whole reason L42 asks for constructed
  # inputs rather than remembered ones.
  git -C "$work" checkout -q -b rogue parent
  echo rogue-side > "$work/shared"; git -C "$work" add shared; git -C "$work" commit -q -m rogue
  git -C "$work" checkout -q parent
  echo parent-moved > "$work/shared"; git -C "$work" add shared; git -C "$work" commit -q -m parent-moves

  cd "$work"
  local a b c d
  a=$(verdict parent child)                 # clean onto its own base
  b=$(verdict trunk  child)                 # the #264 case: conflicts with main only
  c=$(verdict parent rogue)                 # conflicts with its own base
  d=$(verdict parent no-such-branch-here)   # could-not-look
  cd "$root"
  rm -rf "$work"

  printf 'case 1  child onto its own base      expect clean           got %s\n' "$a"
  printf 'case 2  child onto trunk             expect CONFLICT shared got %s\n' "$b"
  printf 'case 3  rogue onto its own base      expect CONFLICT shared got %s\n' "$c"
  printf 'case 4  a base ref that is not there expect unreadable      got %s\n' "$d"
  [ "$a" = clean ]                 || { echo "case 1 disagrees"; rc=1; }
  [ "$b" = "CONFLICT shared " ]    || { echo "case 2 disagrees"; rc=1; }
  [ "$c" = "CONFLICT shared " ]    || { echo "case 3 disagrees"; rc=1; }
  case "$d" in unreadable*) ;; *) echo "case 4 disagrees"; rc=1;; esac
  # --verdict, on constructed bodies rather than remembered ones (L42). The
  # first is the real sentence published for #407 on 2026-11-02; the second is
  # the same sentence repaired; the third is the allowed form.
  local vd e1 e2 e3 e4
  vd=$(mktemp -d)
  printf 'I am merging pull request 407 now because every condition held: a clean merge-tree against main, and all three self-tests passing.\n' > "$vd/bare"
  printf 'I am merging pull request 407 now because every condition held: a clean merge-tree against main@eba9d62, and all three self-tests passing.\n' > "$vd/withsha"
  printf 'L106-ALLOW register entry quoting the refused form.\nThe seat published "a clean merge-tree against main" for pull request 407.\n' > "$vd/allowed"
  printf 'Nothing in the queue is mine today, so I am opening no pull request of my own.\n' > "$vd/noclaim"
  verdict_text "$vd/bare"    >/dev/null 2>&1; e1=$?
  verdict_text "$vd/withsha" >/dev/null 2>&1; e2=$?
  verdict_text "$vd/allowed" >/dev/null 2>&1; e3=$?
  verdict_text "$vd/noclaim" >/dev/null 2>&1; e4=$?
  printf 'case 5  a verdict naming only main     expect 1               got %s\n' "$e1"
  printf 'case 6  the same verdict with the sha  expect 0               got %s\n' "$e2"
  printf 'case 7  a register entry quoting it    expect 0               got %s\n' "$e3"
  printf 'case 8  a body making no merge claim   expect 0               got %s\n' "$e4"
  [ "$e1" = 1 ] || { echo "case 5 disagrees: a verdict with no sha was let through"; rc=1; }
  [ "$e2" = 0 ] || { echo "case 6 disagrees: the compliant form was refused (L94)"; rc=1; }
  [ "$e3" = 0 ] || { echo "case 7 disagrees: the rule made its own evidence unwritable (L94)"; rc=1; }
  [ "$e4" = 0 ] || { echo "case 8 disagrees: a body with no claim was judged"; rc=1; }

  # --names, on a constructed queue: one name twice with the second still open,
  # one name twice both resolved, one name once.
  local n1 n2
  cat > "$vd/queue.json" <<'JSON'
[{"number":374,"headRefName":"seat/day","headRefOid":"5ca60cac4d","state":"MERGED","createdAt":"2026-11-02T00:07:31Z"},
 {"number":415,"headRefName":"seat/day","headRefOid":"c134e1b53d","state":"OPEN","createdAt":"2026-11-02T07:17:50Z"},
 {"number":385,"headRefName":"seat/day-5","headRefOid":"7b3b343b09","state":"MERGED","createdAt":"2026-11-02T02:07:28Z"},
 {"number":387,"headRefName":"seat/day-5","headRefOid":"209aefb037","state":"CLOSED","createdAt":"2026-11-02T02:26:11Z"},
 {"number":400,"headRefName":"seat/other","headRefOid":"deadbeef01","state":"MERGED","createdAt":"2026-11-02T03:00:00Z"}]
JSON
  n1=$(names_report 0 "$vd/queue.json"); 
  names_report 0 "$vd/queue.json" >/dev/null 2>&1; n2=$?
  printf 'case 9  two names reused, one still open expect exit 1        got %s\n' "$n2"
  [ "$n2" = 1 ] && printf 'case 10 it names the open one           expect #415           got %s\n' \
      "$(grep -o 'open_under_a_reused_name_prs: .*' <<<"$n1")"
  [ "$n2" = 1 ] || { echo "case 9 disagrees: an open pull request under a reused name read clean"; rc=1; }
  grep -q 'reused_names: 2' <<<"$n1" || { echo "case 10 disagrees: the reused-name count is wrong"; rc=1; }
  grep -q 'open_under_a_reused_name_prs: #415' <<<"$n1" || { echo "case 10 disagrees: it did not name #415"; rc=1; }
  rm -rf "$vd"

  [ $rc = 0 ] && echo "ok — all ten branches fired and agreed" \
              || echo "a branch of this instrument disagrees with its own constructed input"
  return $rc
}

[ "${1:-}" = "--self-test" ] && { selftest; exit $?; }
[ "${1:-}" = "--verdict" ] && { verdict_text "${2:-}"; exit $?; }
if [ "${1:-}" = "--names" ]; then
  shift
  nlimit=500; nfrom=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --from) nfrom=${2:?--from needs a path}; shift 2 ;;
      *) nlimit=$1; shift ;;
    esac
  done
  names_report "$nlimit" "$nfrom"; exit $?
fi

git fetch -q origin main '+refs/heads/*:refs/remotes/origin/*' 2>/dev/null
printf 'measured %s   main %s %s\n\n' "$(date -u +%FT%TZ)" "$MAIN" "$(git rev-parse --short "$MAIN")"

want=("$@")
# Built once, matched as a herestring below: `printf '%s\n' "${want[@]}" |
# grep -qxF` can report a requested number as not requested, and this one
# `continue`s -- so the pull request drops out of the sweep silently.
wantlist=$(printf '%s\n' "${want[@]}")
mapfile -t rows < <(gh pr list --state open --limit 200 \
  --json number,isDraft,headRefOid,baseRefName,title --jq \
  '.[] | [.number, (if .isDraft then "draft" else "ready" end), .headRefOid[0:8], .baseRefName, .title] | @tsv' \
  | sort -n)

stacked=0; blocked_own=0; rc=0
for row in "${rows[@]}"; do
  IFS=$'\t' read -r n draft sha baseref title <<<"$row"
  if [ ${#want[@]} -gt 0 ]; then
    grep -qxF "$n" <<<"$wantlist" || continue
  fi
  git fetch -q origin "refs/pull/$n/head:refs/remotes/pull/$n" 2>/dev/null
  base="origin/$baseref"
  basesha=$(git rev-parse --short "$base" 2>/dev/null || echo "????????")
  own=$(verdict "$base" "pull/$n"); ownrc=$?
  printf '#%-5s %-5s head %s   base %-44s %s\n' "$n" "$draft" "$sha" "$baseref@$basesha" "$own"
  [ $ownrc = 1 ] && blocked_own=$((blocked_own+1))
  [ $ownrc = 2 ] && rc=2
  if [ "$baseref" != main ]; then
    stacked=$((stacked+1))
    tomain=$(verdict "$MAIN" "pull/$n")
    printf '%6s %-5s %s\n' "" "" "onto main instead: $tomain — a later step's question, not this one's"
    if [ "$own" = clean ] && [ "${tomain%% *}" = CONFLICT ]; then
      printf '%6s %-5s %s\n' "" "" "this is incident 19's exact shape: clean where it merges, conflicted where it does not merge yet"
    fi
  fi
  printf '%6s       %s\n' "" "${title:0:72}"
done

printf '\n%d measured; %d do not target main, so main is the wrong base for them; %d conflict with the base they actually merge into\n' \
  "${#rows[@]}" "$stacked" "$blocked_own"
printf 'a verdict without its base is not a verdict — quote both columns or neither\n'
exit $rc
