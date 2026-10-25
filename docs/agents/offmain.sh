#!/usr/bin/env bash
# What this seat has written that no seat can read: register entries and
# instruments that exist on a branch and on no `main` (L50).
#
#   bash docs/agents/offmain.sh        every run, before the standing counts
#
# WHY THIS EXISTS. A register is the only memory a stateless seat has. Every
# run of every seat here starts from a fresh clone of `main` and reads
# `docs/agents/lessons.md` cold, so an entry on a branch is not a rule that is
# late, it is a rule that does not exist for the one reader it was written for.
#
# Measured 2026-10-24 at 17:2xZ, which is the real positive this was checked
# against. `main` held lessons L1 to L35 and then L47; **L36 through L46 were
# on no `main` at all**, with incidents 16 through 22 and five detector
# commands — `idle.sh`, `mergeable.sh`, `reverted.sh`, `scratch.sh`,
# `stage.sh`. Every one of them sat on a branch stacked behind a charter patch
# the owner has an open question about, so the gate on eighteen register
# entries was a decision about five lines of somebody else's instruction file.
#
# The expensive part is the self-reference, and it is why this is a command
# rather than a paragraph. **L39 already said this would happen** — a pull
# request's clock is the slowest clock inside it, so a charter patch holds
# every file that shares its branch. It was written at 01:20Z on one of those
# branches. Eleven hours later L36 was merged inside a charter pull request,
# reverted with it five minutes later, and was gone for the rest of the day.
# A rule inside the quarantine cannot end the quarantine; only a count can,
# because a count is the one thing a fresh run can read off `main` in a second.
#
# What it reports, per open pull request: the identifiers that branch adds to
# `docs/agents/lessons.md` and `docs/agents/incidents.md` and the files it adds
# under `docs/agents/`, both measured against `main` — and then the thing that
# decides how long they wait, which is whether that branch's diff touches
# `prompts/`. A register entry on a charter branch is gated by a charter
# decision and nothing in its own text says so.
#
# Scope is this repository's own open queue, read from `gh`, so it is an
# absence claim about nothing else (L-A34). A branch nobody has opened a pull
# request for is outside it and is named as outside it.
#
# Three answers and not two (L41): 0 nothing of this seat's is off `main`,
# 1 findings, 2 could not look. Ends in a `data` block to paste (L33).
set -uo pipefail
cd "$(git rev-parse --show-toplevel)"
BASE=${BASE:-origin/main}
SEAT=${SEAT:-epitome-exo}

# A requirement in a comment is not a requirement. The runtime hands this seat
# a depth-1 single-branch clone, in which `git merge-base` finds no base, a
# substitution of it silently builds a different command, and every answer
# below is wrong in a plausible direction (L-A77, incident 13).
if [ "$(git rev-parse --is-shallow-repository)" = true ]; then
  echo "this clone is shallow, which makes every answer below wrong; unshallowing" >&2
  git fetch -q --unshallow origin 2>/dev/null || {
    echo "could not unshallow — refusing rather than answering wrongly" >&2; exit 2; }
fi
command -v gh >/dev/null || { echo "could not look: no gh on PATH" >&2; exit 2; }
git fetch -q origin main 'refs/pull/*/head:refs/remotes/pull/*' 2>/dev/null \
  || { echo "could not look: the fetch of main and the pull refs failed" >&2; exit 2; }
git rev-parse --verify -q "$BASE" >/dev/null \
  || { echo "could not look: no such base $BASE" >&2; exit 2; }

base_sha=$(git rev-parse --short "$BASE")
self_sha=$(git rev-parse --short HEAD)
printf 'measured %s against %s %s, from HEAD %s\n\n' \
  "$(date -u +%FT%TZ)" "$BASE" "$base_sha" "$self_sha"

prs=$(gh pr list --state open --limit 100 \
        --json number,headRefName,baseRefName,isDraft --jq \
        '.[] | [.number,.headRefName,.baseRefName,(.isDraft|tostring)] | @tsv' 2>/dev/null | sort -n) \
  || { echo "could not look: gh refused the pull request list" >&2; exit 2; }
[ -n "$prs" ] || { echo "no open pull requests, so nothing of this seat's is off $BASE"; exit 0; }

ids_on() {  # $1 = ref, prints "L<n>" and "I<n>" one per line
  git show "$1:docs/agents/lessons.md" 2>/dev/null \
    | sed -n 's/^## L\([0-9]\+\) .*/L\1/p'
  git show "$1:docs/agents/incidents.md" 2>/dev/null \
    | sed -n 's/^## Incident \([0-9]\+\) .*/I\1/p'
}
files_on() { git ls-tree --name-only "$1" docs/agents/ 2>/dev/null; }

tmp=$(mktemp -d) || { echo "could not look: no scratch directory" >&2; exit 2; }
trap 'rm -rf "$tmp"' EXIT
ids_on "$BASE"   | sort -u > "$tmp/base-ids"
files_on "$BASE" | sort -u > "$tmp/base-files"

: > "$tmp/rows"
while IFS=$'\t' read -r n head base draft; do
  ref="refs/remotes/pull/$n"
  git rev-parse --verify -q "$ref" >/dev/null || { printf '%s\tUNREAD\t\t\t\t\n' "$n" >> "$tmp/rows"; continue; }
  sha=$(git rev-parse --short "$ref")
  ids_on   "$ref" | sort -u > "$tmp/ids"
  files_on "$ref" | sort -u > "$tmp/files"
  new_ids=$(comm -13 "$tmp/base-ids" "$tmp/ids" | tr '\n' ' ')
  new_files=$(comm -13 "$tmp/base-files" "$tmp/files" | sed 's|docs/agents/||' | tr '\n' ' ')
  # The gate. A merge-base diff, never a two-dot one: a two-dot reading calls
  # every file main gained since the branch was cut part of the branch (L43).
  mb=$(git merge-base "$BASE" "$ref" 2>/dev/null) || mb=""
  if [ -n "$mb" ]; then
    charter=$(git diff --name-only "$mb" "$ref" -- prompts/ 2>/dev/null | tr '\n' ' ')
  else
    charter="UNREAD"
  fi
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$n" "$sha" "$head" "$draft" "${new_ids% }" "${new_files% }" \
    | sed "s|\$|\t${charter% }|" >> "$tmp/rows"
done <<< "$prs"

python3 - "$tmp/rows" "$base_sha" "$self_sha" <<'PY'
import sys, datetime
rows = [l.rstrip("\n").split("\t") for l in open(sys.argv[1]) if l.strip()]
base, self_sha = sys.argv[2], sys.argv[3]

# A thing is gated only if EVERY branch carrying it is gated. The first version
# of this script put each identifier into whichever bucket its last branch fell
# in, and so reported four things as waiting on a charter decision while they
# sat on an ungated branch of their own. That is the same error as counting a
# stack's links as separate decisions: the question is whether a free route
# exists, not whether a blocked one does.
carriers, unread, mine = {}, [], {}
for r in rows:
    if len(r) < 7:
        unread.append(r[0]); continue
    n, sha, head, draft, ids, files, charter = r[:7]
    if sha == self_sha:
        # This run's own branch is the repair and not the finding, so it is
        # excluded from the counts. It is NOT excluded from the page. Skipping
        # it silently made the summary line read "0 lessons, 0 incidents and 0
        # files exist on a branch and on no main" on 2026-10-25 while four
        # entries of this run's own sat exactly there, which is a skip spelled
        # like a clean bill (L41, L-A34, L-A88). A class that can be non-zero
        # and never appear reads as zero.
        mine[n] = (sha, [i for i in ids.split() if i],
                   [f for f in files.split() if f], draft == "true")
        continue
    gate = []
    if charter and charter != "UNREAD": gate.append("charter: " + charter)
    if charter == "UNREAD": gate.append("gate unread: no merge base in this clone")
    if draft == "true": gate.append("draft — no gate can reach it (L-A32)")
    items = [i for i in ids.split() if i] + ["f:" + f for f in files.split() if f]
    if not items: continue
    print(f"  #{n} {sha} {head}")
    if ids.strip():   print("      adds, on no main: " + ids.strip())
    if files.strip(): print("      files, on no main: " + files.strip())
    print("      gated by: " + ("; ".join(gate) if gate else
          "nothing in prompts/ — a knowledge surface, needing no charter decision"))
    for it in items:
        carriers.setdefault(it, []).append((n, bool(gate)))

def free(it):   return any(not g for _, g in carriers[it])
print()
ids_all  = [k for k in carriers if not k.startswith("f:")]
files_all = [k[2:] for k in carriers if k.startswith("f:")]
lessons = sorted((k for k in ids_all if k.startswith("L")), key=lambda s: int(s[1:]))
incs    = sorted((k for k in ids_all if k.startswith("I")), key=lambda s: int(s[1:]))
gated   = sorted(k for k in carriers if not free(k))
print(f"  {len(lessons)} lessons, {len(incs)} incidents and {len(files_all)} files under "
      f"docs/agents/ exist on another branch and on no main.")
if mine:
    own_i = sorted({i for _, ids, _, _ in mine.values() for i in ids})
    own_f = sorted({f.replace("docs/agents/", "") for _, _, fs, _ in mine.values() for f in fs})
    bits = []
    if own_i: bits.append(" ".join(own_i))
    if own_f: bits.append(" ".join(own_f))
    print(f"  Excluded from that count, and not a finding: {', '.join('#'+n for n in sorted(mine))}, "
          f"this run's own branch, carrying {' and '.join(bits) if bits else 'nothing'}. "
          f"It is off main too, and it is off main because it is being written.")
print(f"  Of those, {len(gated)} have no ungated branch carrying them at all, so the thing "
      f"they are waiting for is a charter decision and not a merger.")
if unread:
    print(f"  Could not read the head of: {', '.join('#'+u for u in unread)} — a gap in this "
          f"reading and not a clean answer (L-A18).")
print()
print("```data")
print("measured_at: " + datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"))
print(f"base: main {base}")
print("lessons_off_main: [" + ", ".join(lessons) + "]")
print("incidents_off_main: [" + ", ".join("Incident " + i[1:] for i in incs) + "]")
print("files_off_main: [" + ", ".join(sorted(files_all)) + "]")
print("only_route_is_a_charter_decision: [" + ", ".join(
      (k[2:] if k.startswith("f:") else k) for k in gated) + "]")
print("unreadable_heads: [" + ", ".join("#" + u for u in unread) + "]")
own_ids = sorted({i for _, ids, _, _ in mine.values() for i in ids})
own_files = sorted({f for _, _, fs, _ in mine.values() for f in fs})
print("on_this_runs_own_branch_excluded: [" + ", ".join("#" + n for n in sorted(mine)) + "]")
print("excluded_ids: [" + ", ".join(own_ids) + "]")
print("excluded_files: [" + ", ".join(f.replace("docs/agents/", "") for f in own_files) + "]")
print("```")
sys.exit(1 if (carriers or unread) else 0)
PY
