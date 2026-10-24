#!/usr/bin/env bash
# What this branch would put back that main has already taken out (L44).
#
#   bash docs/agents/reverted.sh                 this branch against origin/main
#   BASE=origin/main REF=pull/271 bash docs/agents/reverted.sh
#   bash docs/agents/reverted.sh --self-test     three constructed cases
#
# A revert takes text off main. It does not take that text off any branch that
# was built on top of it, and nothing in a pull request's own diff mentions
# it: the link above a reverted link still carries every line, so merging the
# chain restores what was reverted, silently, and the diff a reviewer reads
# looks like somebody else's old work rather than a restoration.
#
# On 2026-10-24 that went live here. The merging seat merged `#253` at
# 12:39:01Z and `#261` at 12:40:15Z, then reverted both at 12:44 because
# another pass of the same seat had already put the prior question to the
# owner: whether a charter file can clear on her silence at all. Four links of
# one chain sit on top of `#253` and every one of them still carries the
# paragraph the revert removed. Whichever merges next re-lands it while her
# answer is still outstanding, which is the opposite of what the revert was
# for, and no instrument in this repository could see it.
#
# This is what order.sh and mergeable.sh cannot tell you. A restoration is not
# a conflict: git has no reason to complain, because the branch's version is a
# clean descendant of the state before the revert.
#
# Needs a full clone. Reads only.
set -uo pipefail
cd "$(git rev-parse --show-toplevel)"
BASE=${BASE:-origin/main}
REF=${REF:-HEAD}

if [ "$(git rev-parse --is-shallow-repository)" = true ]; then
  echo "this clone is shallow, which makes every answer below wrong; unshallowing" >&2
  git fetch -q --unshallow origin 2>/dev/null || {
    echo "could not unshallow — refusing rather than answering wrongly" >&2; exit 2; }
fi

# Three answers and not two (L41). "no reverts in the window" is not "clean".
scan() {  # scan <base> <ref>; prints findings, returns 0 none / 1 restores / 2 could-not-look
  local base=$1 ref=$2 rc=0 any=0 reverts
  git rev-parse --verify -q "$base" >/dev/null || { echo "unreadable: no such ref $base"; return 2; }
  git rev-parse --verify -q "$ref"  >/dev/null || { echo "unreadable: no such ref $ref";  return 2; }
  reverts=$(git log "$base" --grep='^Revert "' --format='%H %h %ad %s' --date=format:'%m-%d %H:%M')
  if [ -z "$reverts" ]; then
    echo "no revert commit on $base in this history — nothing for this check to be about"
    return 0
  fi
  while IFS= read -r line; do
    local sha=${line%% *} rest=${line#* }
    local tmp; tmp=$(mktemp)
    # The paths the revert touched, and the lines it took away.
    local paths; paths=$(git show --format= --name-only "$sha")
    for path in $paths; do
      git show --format= "$sha" -- "$path" 2>/dev/null \
        | sed -n 's/^-\([^-].*\)$/\1/p' | awk 'length($0)>24' | sort -u > "$tmp"
      [ -s "$tmp" ] || continue
      git show "$ref:$path" > "$tmp.ref" 2>/dev/null || continue
      local n; n=$(grep -cxF -f "$tmp" "$tmp.ref" 2>/dev/null || true)
      if [ "${n:-0}" -gt 0 ]; then
        [ $any = 0 ] && { printf 'RESTORES — %s still carries text %s took off %s\n\n' "$ref" "a revert" "$base"; any=1; }
        printf '  %s  %s\n' "$rest" ""
        printf '    %-40s %s of its removed lines are present on this branch\n' "$path" "$n"
        grep -xF -f "$tmp" "$tmp.ref" | head -2 | sed 's/^/      | /'
        rc=1
      fi
      rm -f "$tmp.ref"
    done
    rm -f "$tmp"
  done <<< "$reverts"
  [ $rc = 0 ] && echo "this branch restores nothing that $base has reverted"
  return $rc
}

selftest() {
  local work root rc=0 a b c
  root=$(pwd); work=$(mktemp -d)
  git init -q "$work"; git -C "$work" config user.email x@x; git -C "$work" config user.name x
  printf 'keep\n' > "$work/f"; git -C "$work" add f; git -C "$work" commit -q -m base
  git -C "$work" branch -M trunk
  # trunk adds a paragraph, a branch is cut from it, then trunk reverts.
  printf 'keep\na paragraph long enough to be worth checking for\n' > "$work/f"
  git -C "$work" add f; git -C "$work" commit -q -m addition
  git -C "$work" checkout -q -b carrier
  printf 'own work that is also long enough to be a line\n' >> "$work/f"
  git -C "$work" add f; git -C "$work" commit -q -m carries
  git -C "$work" checkout -q trunk
  git -C "$work" revert -q --no-edit HEAD~0 >/dev/null 2>&1 || git -C "$work" revert --no-edit HEAD >/dev/null
  # and a branch cut AFTER the revert, which restores nothing.
  git -C "$work" checkout -q -b innocent
  printf 'something else entirely, also past the length floor\n' >> "$work/f"
  git -C "$work" add f; git -C "$work" commit -q -m innocent

  # The verdict is the scan's own line, never the header: the header is
  # present in all three cases and matching on it passes every case for the
  # wrong reason, which is how the first draft of this self-test reported
  # three disagreements against a working instrument (L42 again, same hour).
  cd "$work"
  verdict() { BASE=trunk REF=$1 bash "$root/docs/agents/reverted.sh" 2>&1 \
    | grep -E '^(RESTORES|unreadable|no revert commit|this branch restores nothing)' | head -1; }
  a=$(verdict carrier); b=$(verdict innocent); c=$(verdict no-such-ref-at-all)
  cd "$root"; rm -rf "$work"

  printf 'case 1  a branch cut before the revert  expect RESTORES          got %s\n' "${a:0:34}"
  printf 'case 2  a branch cut after the revert   expect restores nothing  got %s\n' "${b:0:34}"
  printf 'case 3  a ref that is not there         expect unreadable        got %s\n' "${c:0:34}"
  case "$a" in RESTORES*) ;; *) echo "case 1 disagrees"; rc=1;; esac
  case "$b" in *"restores nothing"*) ;; *) echo "case 2 disagrees"; rc=1;; esac
  case "$c" in unreadable*) ;; *) echo "case 3 disagrees"; rc=1;; esac
  [ $rc = 0 ] && echo "ok — all three branches fired and agreed" \
              || echo "a branch of this instrument disagrees with its own constructed input"
  return $rc
}

[ "${1:-}" = "--self-test" ] && { selftest; exit $?; }

git fetch -q origin main 2>/dev/null
printf 'measured %s   %s %s   against %s %s\n\n' "$(date -u +%FT%TZ)" \
  "$REF" "$(git rev-parse --short "$REF" 2>/dev/null)" "$BASE" "$(git rev-parse --short "$BASE" 2>/dev/null)"
scan "$BASE" "$REF"
