#!/usr/bin/env bash
# How many of the open pull requests can a merger of `main` actually take?
#
#   bash docs/agents/doors.sh         immediately before you publish the count
#
# WHY THIS EXISTS, and why it is not `order.sh`. That script answers "what
# lands in one pass", by test-merging the queue oldest first onto a running
# result. This one answers a different question about the same queue: for each
# open pull request, is there a door — a base that is `main`, and a merge that
# applies without a hand. The two answers are not the same and the standing
# count this seat publishes has been the first one wearing the second one's
# name.
#
# Measured 2026-10-24: seven of this seat's open pull requests are one stack.
# Six of them are based on a sibling branch rather than on `main`, so a merger
# of `main` cannot take them at all; the stack has exactly one door, its tip.
# And every link of it, the tip included, conflicts with `main` in the two
# register files — `docs/agents/incidents.md` and `docs/agents/loop.md` — and
# has conflicted since before any of today's merges, which is checkable by
# re-running this against an older base. Four published counts that day said
# "N open, M independent decisions, oldest X hours" and not one of them said
# that the one door needed a hand, although `order.sh` printed `blocked` for
# every line (L49).
#
# A door is: base is the branch you are merging into, AND the merge applies
# with no conflict at the revision printed, AND nothing else holds it.
# Containment is read by ancestry, not by reading titles.
#
# "Nothing else holds it" is L-A96, which this script did not have on its first
# run and which is not in this product's vendored copy of the register: a ready
# pull request held on an unanswered review comment is as unmergeable as a
# draft, and worse, because the draft looks wrong to a reader and the ready one
# looks finished. So the question is "could this merge right now, and whose act
# unblocks it", never "is this a draft". `reviewDecision` is read for that.
#
# Ends in a `data` block to paste rather than retype (L33).
set -uo pipefail
cd "$(git rev-parse --show-toplevel)"
BASE=${BASE:-origin/main}
TARGET=${TARGET:-main}   # the branch a merger is merging into

if [ "$(git rev-parse --is-shallow-repository)" = true ]; then
  echo "this clone is shallow, which makes every answer below wrong; unshallowing" >&2
  git fetch -q --unshallow origin 2>/dev/null || {
    echo "could not unshallow — refusing rather than answering wrongly" >&2; exit 2; }
fi
command -v gh >/dev/null || { echo "could not look: no gh on PATH" >&2; exit 2; }
git fetch -q origin "$TARGET" 'refs/pull/*/head:refs/remotes/pull/*' 2>/dev/null

head_sha=$(git rev-parse --short "$BASE")
printf 'measured %s against %s %s, for a merger of %s\n\n' \
  "$(date -u +%FT%TZ)" "$BASE" "$head_sha" "$TARGET"

prs=$(gh pr list --state open --limit 100 \
      --json number,baseRefName,headRefName,isDraft,createdAt,reviewDecision \
      --jq '.[] | [.number,.baseRefName,.headRefName,(.isDraft|tostring),.createdAt,
            (.reviewDecision // "none")] | @tsv' | sort -n)
[ -n "$prs" ] || { echo "no open pull requests"; exit 0; }

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
: > "$tmp/rows"
while IFS=$'\t' read -r n base head draft created review; do
  sha=$(git rev-parse --short "refs/remotes/pull/$n" 2>/dev/null || echo "????????")
  # Contained: some other open pull request has this one as an ancestor.
  inside=""
  while IFS=$'\t' read -r m _ _ _ _ _; do
    [ "$m" = "$n" ] && continue
    git merge-base --is-ancestor "refs/remotes/pull/$n" "refs/remotes/pull/$m" 2>/dev/null \
      && inside="$inside #$m"
  done <<< "$prs"
  # Clean: a real merge in a throwaway worktree, because --check style answers
  # differ from the merge (L28).
  w=$(mktemp -d); git worktree add -q --detach "$w" "$BASE" 2>/dev/null
  if git -C "$w" merge --no-commit --no-ff "refs/remotes/pull/$n" >/dev/null 2>&1; then
    conflict=""
  else
    conflict=$(git -C "$w" diff --name-only --diff-filter=U | tr '\n' ' ')
  fi
  git -C "$w" merge --abort 2>/dev/null; git worktree remove --force "$w" 2>/dev/null
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$n" "$base" "$sha" "$draft" "$created" "${inside# }" "$conflict" "$review" >> "$tmp/rows"
done <<< "$prs"

python3 - "$tmp/rows" "$TARGET" "$head_sha" <<'PY'
import sys
rows = [l.rstrip("\n").split("\t") for l in open(sys.argv[1]) if l.strip()]
target, head = sys.argv[2], sys.argv[3]
doors, handed, contained, drafts, held = [], [], [], [], []
for n, base, sha, draft, created, inside, conflict, review in rows:
    at_target = base == target
    mark = []
    if not at_target: mark.append(f"base={base} — not addressed to {target}")
    if conflict.strip(): mark.append("needs a hand: " + conflict.strip())
    if draft == "true": mark.append("draft — no gate can reach it")
    if review == "CHANGES_REQUESTED":
        mark.append("held on a review: an answer from its author unblocks it (L-A96)")
    if inside: mark.append(f"contained in{' ' + inside}")
    print(f"  #{n} {sha} " + ("; ".join(mark) if mark else "a door: based on "
          f"{target} and merges clean"))
    # A draft is never a door, whatever its base and however clean it merges:
    # GitHub refuses to merge one at all (L-A32). The first version of this
    # script counted three drafts among four doors while its own rows said "no
    # gate can reach it" three lines above, which is the defect L49 is about,
    # committed by the instrument written for L49.
    if draft == "true": drafts.append(n)
    elif review == "CHANGES_REQUESTED": held.append(n)
    elif inside: contained.append(n)
    elif at_target and not conflict.strip(): doors.append(n)
    elif at_target: handed.append(n)
print()
door_word = "door" if len(doors) == 1 else "doors"
print(f"  {len(rows)} open; {len(doors)} {door_word} a merger of {target} can take "
      f"as they stand; {len(handed)} addressed to {target} but needing a hand first; "
      f"{len(contained)} contained in another; {len(drafts)} drafts no gate can "
      f"reach; {len(held)} held on a review")
print()
print("```data")
print(f"measured_at: {__import__('datetime').datetime.now(__import__('datetime').timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')}")
print(f"base: {target} {head}")
print(f"open: {len(rows)}")
print(f"doors: [{', '.join('#'+d for d in doors)}]")
print(f"needs_a_hand: [{', '.join('#'+d for d in handed)}]")
print(f"contained_in_another: [{', '.join('#'+d for d in contained)}]")
print(f"drafts_no_gate: [{', '.join('#'+d for d in drafts)}]")
print(f"held_on_review: [{', '.join('#'+d for d in held)}]")
print("```")
PY
