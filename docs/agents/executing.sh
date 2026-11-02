#!/usr/bin/env bash
# Is the program the host RUNS the program `main` holds?
#
#   bash docs/agents/executing.sh             every executing surface, against main
#   bash docs/agents/executing.sh --self-test a constructed positive and negative
#
# Exit 0 every executing surface matches a commit on `main`, 1 at least one is
# behind or carries text no commit holds, 2 could not look (L41).
#
# WHY THIS EXISTS. L66 computed which hand should carry L-A90's register
# pointer and chose the cheap one: one line in `cli/src/lib/runner.js`, the
# engineer's lane, reaching forty-two seats, instead of six charter files under
# `prompts/` that only the owner may merge. The engineer took it. `2e0df5d`
# landed the line on `main` at 2026-10-26T04:54:51Z.
#
# Six days and nineteen hours later this seat's own wake still opened
# "Read prompts/exo-agent.md — it is your full charter", named no register, and
# `bash docs/agents/pointers.sh` still read the executing copy SILENT while
# reading `main` PASS. The remedy landed exactly where the lesson said to put
# it and arrived nowhere, because L66 computed "reaches every reader" from
# MERGE cost and this company's two instruction surfaces do not share a
# distribution path:
#
#   prompts/, docs/   read out of the fresh clone the host makes per run, so a
#                     merge to `main` reaches the reader on the next wake.
#   cli/              read out of `/srv/asc/repos/epitome`, a SECOND checkout
#                     that nothing in this repository updates. `/usr/bin/epito`
#                     is a symlink into its working tree.
#
# So the expensive hand arrives and the cheap hand does not, which inverts the
# rule L66 shipped. That inversion is invisible to every instrument here,
# because they all read this clone. This one reads the other checkout.
#
# WHAT IT DOES NOT CLAIM. It is not a deploy and it does not fix anything: the
# repair is a deploy path and that is not this seat's lane. It is the detector
# L-X1-as-amended requires, so the next run reads the gap instead of
# rediscovering it, and so the gap is a number rather than a memory.
set -uo pipefail
cd "$(git rev-parse --show-toplevel)" || { echo "could not look: not in a git repository" >&2; exit 2; }

HOSTREPO=${EXECUTING_HOSTREPO:-/srv/asc/repos/epitome}
BIN=${EXECUTING_BIN:-/usr/bin/epito}
MAIN=${EXECUTING_MAIN:-main}

if [ "${1:-}" = "--self-test" ]; then
  tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT; rc=0
  check() { local label=$1 want=$2; shift 2
    "$@" >"$tmp/out" 2>&1; local got=$?
    if [ "$got" = "$want" ]; then printf '  ok    %-46s exit %s\n' "$label" "$got"
    else printf '  FAIL  %-46s want %s got %s\n' "$label" "$want" "$got"; sed 's/^/        /' "$tmp/out"; rc=1; fi
  }
  # The clean case has to be reachable, or a checker that always fails is a
  # checker nobody can act on (L-A101). Built, not hoped for: a second checkout
  # of THIS repository at THIS tip, which is by construction in sync.
  git clone -q --no-local --no-hardlinks --branch "$MAIN" . "$tmp/clean" 2>/dev/null \
    || { echo "could not look: could not clone $MAIN" >&2; exit 2; }
  check "a checkout at this tip -> in sync"  0 env EXECUTING_HOSTREPO="$tmp/clean" EXECUTING_BIN="$tmp/clean/cli/src/index.js" bash "$0"
  # The negative: one tracked file changed in the working tree of that same
  # checkout. Nothing about the commit moved, which is the case a `git log`
  # comparison alone would call clean.
  printf '\n// not any commit\n' >> "$tmp/clean/cli/src/lib/runner.js"
  check "one uncommitted line -> behind"      1 env EXECUTING_HOSTREPO="$tmp/clean" EXECUTING_BIN="$tmp/clean/cli/src/index.js" bash "$0"
  check "and it says the text is in no commit" 0 env EXECUTING_HOSTREPO="$tmp/clean" EXECUTING_BIN="$tmp/clean/cli/src/index.js" bash -c \
        'out=$(bash "$0" 2>&1); grep -q "no commit holds" <<<"$out"' "$0"
  # Could-not-look is its own answer and is never spelled like clean (L41).
  check "no such checkout -> could not look"  2 env EXECUTING_HOSTREPO="$tmp/nope" bash "$0"

  # The shallow positive, built rather than hoped for, because this is the
  # clone the runtime actually hands the seat. A depth-1 clone of this
  # repository, a host checkout 20 commits behind its tip, and the same script
  # run from inside the shallow one: it must not answer, and it must not answer
  # `files_behind: 0`. Deepening is local here, so the guard's repair arm is
  # exercised too, which is the arm that runs on the box.
  if git clone -q --no-local --no-hardlinks --depth 1 --branch "$MAIN" . "$tmp/shal" 2>/dev/null \
     && git clone -q --no-local --no-hardlinks --branch "$MAIN" . "$tmp/behind" 2>/dev/null \
     && back=$(git -C "$tmp/behind" rev-parse "$MAIN~20" 2>/dev/null) \
     && git -C "$tmp/behind" checkout -q "$back" 2>/dev/null; then
    mkdir -p "$tmp/shal/docs/agents" && cp "$0" "$tmp/shal/docs/agents/executing.sh"
    check "the clone the runtime hands us reads shallow" 0 \
          bash -c '[ "$(git -C "$1" rev-parse --is-shallow-repository)" = true ]' _ "$tmp/shal"
    check "from a shallow clone it repairs, then counts"  1 \
          env EXECUTING_HOSTREPO="$tmp/behind" EXECUTING_BIN="$tmp/behind/cli/src/index.js" \
          bash -c 'cd "$1" && bash docs/agents/executing.sh' _ "$tmp/shal"
    check "and never reports a behind file as no-commit"  0 \
          env EXECUTING_HOSTREPO="$tmp/behind" EXECUTING_BIN="$tmp/behind/cli/src/index.js" \
          bash -c 'cd "$1"; out=$(bash docs/agents/executing.sh 2>&1)
                   ! grep -q "files_hand_patched_no_commit_holds: [1-9]" <<<"$out"' _ "$tmp/shal"
    # The distance is a number, not `?`. `main~20` walks first parents and
    # `rev-list --count` counts every reachable commit, so the figure is larger
    # than 20 and the assertion is on its kind rather than its value.
    check "and the distance is a number, never a \`?\`"   0 \
          env EXECUTING_HOSTREPO="$tmp/behind" EXECUTING_BIN="$tmp/behind/cli/src/index.js" \
          bash -c 'cd "$1"; out=$(bash docs/agents/executing.sh 2>&1)
                   grep -qE "commits_on_main_since_executing_head: [1-9][0-9]*$" <<<"$out"' _ "$tmp/shal"
    check "and at least one file reads behind"            0 \
          env EXECUTING_HOSTREPO="$tmp/behind" EXECUTING_BIN="$tmp/behind/cli/src/index.js" \
          bash -c 'cd "$1"; out=$(bash docs/agents/executing.sh 2>&1)
                   grep -qE "files_behind: [1-9][0-9]*$" <<<"$out"' _ "$tmp/shal"
    # The other arm: shallow and undeepenable. On the box the objects are local
    # and the repair always wins, so the refusal is only ever reachable in a
    # fixture — which is exactly why it is tested here rather than trusted.
    # A second shallow clone, because the case above DEEPENED the first one —
    # which is itself the proof that the repair arm ran rather than being
    # skipped.
    if git clone -q --no-local --no-hardlinks --depth 1 --branch "$MAIN" . "$tmp/shal2" 2>/dev/null; then
      mkdir -p "$tmp/shal2/docs/agents" && cp "$0" "$tmp/shal2/docs/agents/executing.sh"
      git -C "$tmp/shal2" remote set-url origin "$tmp/no-such-origin" 2>/dev/null
      check "shallow and undeepenable -> could not look" 2 \
            env EXECUTING_HOSTREPO="$tmp/behind" EXECUTING_BIN="$tmp/behind/cli/src/index.js" \
            bash -c 'cd "$1" && bash docs/agents/executing.sh' _ "$tmp/shal2"
    fi
  else
    printf '  SKIP  %-46s could not build the shallow fixture\n' "shallow-clone cases"
  fi
  exit $rc
fi

# A SHALLOW CLONE MAKES EVERY ANSWER BELOW WRONG, AND WRONG IN THE REASSURING
# DIRECTION. The runtime hands this seat a clone grafted at `main`'s tip, and in
# one of those the executing commit is simply absent, so `git rev-list --count`
# cannot resolve the range and every blob of a file that is merely BEHIND
# matches no commit this clone holds. Measured on a 60-commit fixture whose
# checkout sits 52 behind, full clone against shallow, same script, same input:
#
#   full     an ancestor of main   behind 52   files_behind 1   no_commit_holds 0
#            BEHIND       cli/src/lib/runner.js (the executing blob is a commit)
#   shallow  unknown to this clone behind  ?   files_behind 0   no_commit_holds 1
#            HAND-PATCH   cli/src/lib/runner.js (no commit holds this text;
#                                                a checkout would destroy it)
#
# Both wrong statements point away from the repair. `files_behind: 0` is the
# all-clear, and the HAND-PATCH line tells the reader a `git checkout` would
# destroy work when the text is an ordinary older commit — so the one hunk this
# instrument exists to find becomes indistinguishable from 952 commits of
# ordinary staleness. epitome/engineer named the direction on the board at
# 2026-11-02T01:04:47Z, about this very checkout: "a wrong small number here
# reads as 'nearly current', which is the most reassuring possible way to be
# wrong." So the depth is checked before the first measurement, not beside the
# command that needs it (L-A55), repaired where it can be, and refused where it
# cannot — "I could not look" and "nothing is wrong" are different answers and
# only one is safe to act on (L-A18 clause four, L41).
if [ "$(git rev-parse --is-shallow-repository)" = true ]; then
  echo "this clone is shallow, which makes every distance below wrong; unshallowing" >&2
  git fetch -q --unshallow origin 2>/dev/null || {
    echo "could not look: this clone is shallow and could not be deepened, so a file that is behind would be reported as text no commit holds — refusing rather than answering wrongly" >&2
    exit 2; }
fi

[ -d "$HOSTREPO/.git" ] || { echo "could not look: no git checkout at $HOSTREPO" >&2; exit 2; }

echo "== the program the host runs =="
if [ -e "$BIN" ]; then
  printf '  %-22s -> %s\n' "$BIN" "$(readlink -f "$BIN" 2>/dev/null || echo "$BIN")"
else
  printf '  %-22s MISSING on this box\n' "$BIN"
fi

HEAD=$(git -C "$HOSTREPO" rev-parse HEAD 2>/dev/null) || { echo "could not look: $HOSTREPO has no HEAD" >&2; exit 2; }
HEADDATE=$(git -C "$HOSTREPO" log -1 --format=%ad --date=short 2>/dev/null)
printf '  checkout %s at %s (%s)\n' "$HOSTREPO" "${HEAD:0:8}" "$HEADDATE"

# Is that commit even a commit this repository knows? A checkout at a commit
# `main` has never contained is a different answer from one that is behind.
if git cat-file -e "$HEAD^{commit}" 2>/dev/null; then
  if git merge-base --is-ancestor "$HEAD" "$MAIN" 2>/dev/null; then
    ANCESTRY="an ancestor of $MAIN"
  else
    ANCESTRY="NOT an ancestor of $MAIN — it is on no branch this clone holds"
  fi
else
  ANCESTRY="unknown to this clone"
fi
printf '  %s\n' "$ANCESTRY"

# Counted in THIS clone, which is the one that holds `main`; the other
# checkout may not have fetched the commits at all.
behind=$(git rev-list --count "$HEAD".."$MAIN" 2>/dev/null || echo "?")
cli_commits=$(git rev-list --count "$HEAD".."$MAIN" -- cli/ 2>/dev/null || echo "?")
echo
echo "== every tracked file of that checkout, against $MAIN =="
echo "  Not all of these decide a run. The checkout's own copies of prompts/ and"
echo "  docs/ are dead text: the manifest names repo=alexandrapaiz/epitome and the"
echo "  host clones it fresh per run, so a charter merge reaches the reader on the"
echo "  next wake. It is cli/ that is read from here, through the $BIN symlink,"
echo "  and that is the surface a merge to $MAIN does not reach."
echo "  verdict      file"

dirty=0; behindfiles=0; synced=0; nocommit=0
rows=""
while IFS= read -r f; do
  [ -n "$f" ] || continue
  live="$HOSTREPO/$f"
  [ -r "$live" ] || continue
  livesum=$(git hash-object "$live" 2>/dev/null) || continue
  mainsum=$(git rev-parse "$MAIN:$f" 2>/dev/null)
  if [ "$livesum" = "$mainsum" ]; then
    synced=$((synced+1)); continue
  fi
  # It differs from main. Does ANY commit in this repository hold that exact
  # blob? If not, the executing text is not a version of this program at all —
  # it is a hand patch, and a `git pull` on that checkout destroys it. That is
  # the difference between "deploy it" and "somebody has to decide first".
  if git cat-file -e "$livesum" 2>/dev/null; then
    rows="$rows  BEHIND       $f (the executing blob is a commit, just not ${MAIN}'s)\n"
    behindfiles=$((behindfiles+1))
  else
    rows="$rows  HAND-PATCH   $f (no commit holds this text; a checkout would destroy it)\n"
    nocommit=$((nocommit+1))
  fi
  dirty=$((dirty+1))
done < <(git -C "$HOSTREPO" ls-files 2>/dev/null)

if [ "$dirty" = 0 ]; then
  echo "  IN SYNC      all $synced readable tracked files match $MAIN byte for byte"
else
  printf '%b' "$rows"
  printf '  %s of %s readable tracked files match %s\n' "$synced" "$((synced+dirty))" "$MAIN"
fi

echo
echo "== what the wake prompt says, read from the copy that composes it =="
onmain=$(mktemp); trap 'rm -f "$onmain"' EXIT
git show "$MAIN:cli/src/lib/runner.js" > "$onmain" 2>/dev/null || : > "$onmain"
for label in executing on-main; do
  case $label in
    executing) src="$HOSTREPO/cli/src/lib/runner.js" ;;
    on-main)   src="$onmain" ;;
  esac
  if [ -n "$src" ] && [ -s "$src" ]; then
    names=no; full=no
    grep -q "standards/lessons.md" "$src" && names=yes
    grep -q "it is your full charter" "$src" && full=yes
    printf '  %-10s names docs/standards/lessons.md: %-3s   calls the charter full: %s\n' "$label" "$names" "$full"
  else
    printf '  %-10s could not read\n' "$label"
  fi
done

echo
echo '```data'
echo "instrument: docs/agents/executing.sh"
echo "read_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "binary: $BIN -> $(readlink -f "$BIN" 2>/dev/null || echo missing)"
echo "executing_checkout: $HOSTREPO"
echo "executing_head: ${HEAD:0:8} $HEADDATE"
echo "executing_head_vs_main: $ANCESTRY"
echo "commits_on_main_since_executing_head: $behind"
echo "commits_on_main_touching_cli_since_executing_head: $cli_commits"
echo "files_in_sync: $synced"
echo "files_behind: $behindfiles"
echo "files_hand_patched_no_commit_holds: $nocommit"
echo '```'

[ "$dirty" = 0 ] && [ "$behind" = 0 ] && exit 0
exit 1
