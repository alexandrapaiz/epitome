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
#
# AND THE DISTANCE IS NOT THE FINDING, WHICH IS WHAT THIS FILE GOT WRONG FIRST
# (L104). Every reading this instrument had produced was a distance — 336 on
# 2026-10-18, 440, 578, 620, 652, 952, 1032, 1079 — and a distance presumes its
# own remedy: that the far end can be reached by moving along it. Four readings
# went out with `git pull --ff-only && systemctl restart epitod` printed beside
# the number, and nobody asked whether that command runs. So this now reads the
# precondition of its own remedy before it reports the size of the gap, and
# says which of three things the gap is:
#
#   behind, and a fast-forward away        the act is a deploy, and it is root's
#   behind, and the clone cannot see main  the act is a clone repair first
#   behind, and skipped on purpose         the act is re-reading somebody's
#                                          recorded reason, and the addressee
#                                          is whoever owns that decision
#
# The third is the one no distance can express and the one that was true here:
# a continuous deployer has run on this box every three minutes since
# 2026-10-23, it succeeds, and its own text declares this checkout exempt. An
# exclusion is correct forever to every reader who finds the reason sound, and
# nothing re-measures the reason, so the premise is read out loud here beside
# the number it has been suppressing (L-A123: a check that reads only current
# state cannot tell nobody-did-this from somebody-deliberately-undid-this, and
# the two have opposite next moves).
#
# Everything below is READ-ONLY against that checkout. No fetch, no checkout,
# no pull: it is another hand's working tree with uncommitted work in it, and
# an instrument that repairs what it measures has destroyed the evidence a
# decision needs (L-A55's second exception).
set -uo pipefail
cd "$(git rev-parse --show-toplevel)" || { echo "could not look: not in a git repository" >&2; exit 2; }

HOSTREPO=${EXECUTING_HOSTREPO:-/srv/asc/repos/epitome}
BIN=${EXECUTING_BIN:-/usr/bin/epito}
MAIN=${EXECUTING_MAIN:-main}
# The continuous deployer, by path rather than by name, because the question
# "who would carry a merge to that checkout" is answered by the script that
# runs and not by the one a register remembers. Overridable so the self-test
# can hand it a deployer that excludes a fixture and one that does not.
DEPLOYER=${EXECUTING_DEPLOYER:-/srv/asc/hq/tools/host/asc-deploy.sh}

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
  #
  # THE FILE IS CHOSEN FROM THE CLONE, NOT NAMED. This line read
  # `>> "$tmp/clean/cli/src/lib/runner.js"` until 2026-11-02, a path out of
  # THIS repository's layout, and a redirect into a directory that does not
  # exist fails without stopping the script -- so in any other repository the
  # append printed one line to stderr, changed nothing, and the two assertions
  # below then measured the fixture's absence instead of this instrument:
  # `one uncommitted line -> behind` wanted 1 and got 0, and
  # `the text is in no commit` wanted 0 and got 1. Both read as this script
  # being broken. Found by cli/test/selftests.sh, whose whole second question
  # is whether a verdict moves with the checkout, and which is the only reader
  # that could have found it, because here the path exists.
  #
  # Nothing in this instrument cares WHICH file is dirty -- it walks
  # `git ls-files` of the checkout and compares each blob to `$MAIN:`'s -- so
  # the fixture asks the clone what it has. And the build is checked, because a
  # fixture that failed to build is not a subject that failed (L41): a self-test
  # whose setup fails silently reports the setup's failure in the subject's name.
  victim=$(git -C "$tmp/clean" ls-files | head -1)
  [ -n "$victim" ] && printf '\n// not any commit\n' >> "$tmp/clean/$victim" \
    || { echo "could not look: the clean clone has no tracked file to dirty" >&2; exit 2; }
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

  # The reachability half (L104). Four cases, each built: a clone that can see
  # main, one whose refspec is pinned to a branch that is not main, a deployer
  # that names the checkout, and one that does not. The point of testing these
  # is that all four look identical in the distance, which is the whole finding.
  if git clone -q --no-local --no-hardlinks --branch "$MAIN" . "$tmp/reach" 2>/dev/null \
     && back=$(git -C "$tmp/reach" rev-parse "$MAIN~5" 2>/dev/null) \
     && git -C "$tmp/reach" checkout -q --detach "$back" 2>/dev/null; then
    # Inlined rather than wrapped in a helper: a function defined here is not
    # in scope inside `bash -c`, and the first version of these cases failed
    # six for six on `say: command not found` — which is this file's own
    # L41 in miniature, since a fixture that cannot run looks exactly like a
    # fixture whose subject is broken.
    say='out=$(env EXECUTING_HOSTREPO="$1" EXECUTING_BIN="$1/cli/src/index.js" EXECUTING_DEPLOYER="$2" bash "$3" 2>&1); '
    : > "$tmp/dep-silent"
    printf '# What it never touches: %s, for a reason\n' "$tmp/reach" > "$tmp/dep-names"

    check "a wildcard refspec -> reaches every branch"  0 \
          bash -c "$say"'grep -q "executing_refspec_reach: reaches every branch" <<<"$out"' _ "$tmp/reach" "$tmp/dep-silent" "$0"
    check "a detached clean checkout -> ff would land"  0 \
          bash -c "$say"'grep -q "executing_fast_forward: a fast-forward would land" <<<"$out"' _ "$tmp/reach" "$tmp/dep-silent" "$0"
    check "a deployer that is silent -> excludes: no"   0 \
          bash -c "$say"'grep -q "deployer_excludes_this_checkout: no" <<<"$out"' _ "$tmp/reach" "$tmp/dep-silent" "$0"
    check "a deployer that names it -> excludes: yes"   0 \
          bash -c "$say"'grep -q "deployer_excludes_this_checkout: yes" <<<"$out"' _ "$tmp/reach" "$tmp/dep-names" "$0"
    check "and the exclusion's own reason is printed"   0 \
          bash -c "$say"'grep -q "for a reason" <<<"$out"' _ "$tmp/reach" "$tmp/dep-names" "$0"
    # The pinned case, which is the one that fetches nothing and exits 0 doing
    # it. Set on a copy so the cases above keep their wildcard.
    if git clone -q --no-local --no-hardlinks --branch "$MAIN" . "$tmp/pinned" 2>/dev/null; then
      git -C "$tmp/pinned" config --replace-all remote.origin.fetch \
          '+refs/heads/some-deleted-branch:refs/remotes/origin/some-deleted-branch' 2>/dev/null
      check "a refspec pinned off main -> repair first" 0 \
            bash -c 'out=$(env EXECUTING_HOSTREPO="$1" EXECUTING_BIN="$1/cli/src/index.js" \
                               EXECUTING_DEPLOYER=/nonexistent bash "$2" 2>&1)
                     grep -q "executing_refspec_reach: PINNED" <<<"$out" \
                     && grep -q "the_act: repair the clone first" <<<"$out"' _ "$tmp/pinned" "$0"
    fi
    # A deployer this box cannot read is a could-not-look about the hand, never
    # a clean "nothing excludes it" (L41).
    check "an unreadable deployer says unknown, not no" 0 \
          bash -c "$say"'grep -q "deployer_readable: no" <<<"$out" \
                         && grep -q "deployer_excludes_this_checkout: unknown" <<<"$out"' _ "$tmp/reach" /definitely/not/here "$0"
  else
    printf '  SKIP  %-46s could not build the reachability fixture\n' "reachability cases"
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
echo "== can that checkout be reached at all, and does anything carry a merge to it =="
echo "  The precondition of this instrument's own remedy, read before the size of"
echo "  the gap, because a distance only names an act when the far end is reachable."

# Read-only, every one of them. `git config --get` and `rev-parse` do not write,
# and FETCH_HEAD's mtime is the cheapest honest answer to "when did a fetch last
# succeed here" — it is written by every fetch that brings anything down and by
# nothing else.
RSPEC=$(git -C "$HOSTREPO" config --get-all remote.origin.fetch 2>/dev/null | tr '\n' ' ')
RURL=$(git -C "$HOSTREPO" config --get remote.origin.url 2>/dev/null)
HBRANCH=$(git -C "$HOSTREPO" rev-parse --abbrev-ref HEAD 2>/dev/null)
[ "$HBRANCH" = HEAD ] && HBRANCH="(detached)"
HOSTMAIN=$(git -C "$HOSTREPO" rev-parse --verify --quiet "origin/$MAIN" 2>/dev/null)
FETCHAT=$(date -u -r "$HOSTREPO/.git/FETCH_HEAD" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo none)

# Three questions, separately, because a clone can fail one and pass the others
# and the repair differs for each (the shape HQ's own check-host-deploy.py
# already takes). One: does the refspec reach `main` at all — a refspec pinned
# to one branch fetches nothing else and exits 0 doing it, which is L-A59's
# merged-branch fault arriving on a deployment checkout. Two: has a fetch in
# fact succeeded, and when. Three: would a fast-forward land, which asks whether
# HEAD is an ancestor of the main that checkout itself holds.
case "$RSPEC" in
  *"refs/heads/*"*)                 SPECREACH="reaches every branch" ;;
  *"refs/heads/$MAIN:"*)            SPECREACH="reaches $MAIN only, which is enough" ;;
  "")                               SPECREACH="NO refspec configured" ;;
  *)                                SPECREACH="PINNED to something other than $MAIN: $RSPEC" ;;
esac
if [ -n "$HOSTMAIN" ] && git -C "$HOSTREPO" merge-base --is-ancestor "$HEAD" "$HOSTMAIN" 2>/dev/null; then
  FF="a fast-forward would land"
elif [ -n "$HOSTMAIN" ]; then
  FF="NOT a fast-forward: that checkout's HEAD is not an ancestor of the $MAIN it holds"
else
  FF="cannot say: that checkout holds no origin/$MAIN to fast-forward to"
fi
printf '  %-22s %s\n' "origin" "${RURL:-none}"
printf '  %-22s %s\n' "refspec" "$SPECREACH"
printf '  %-22s %s\n' "HEAD is on" "$HBRANCH"
printf '  %-22s %s\n' "its own origin/$MAIN" "${HOSTMAIN:0:8}${HOSTMAIN:+ }${HOSTMAIN:+(}${FETCHAT}${HOSTMAIN:+ last fetch)}"
printf '  %-22s %s\n' "fast-forward" "$FF"

# And the hand. A deployer that exists, runs, and names this checkout in an
# exclusion is the whole explanation of a growing distance, and its reason is
# the thing to re-read rather than the number.
# `unknown`, not `no`. The first version of this block initialised it to `no`
# and left it there when the deployer could not be read, so a box where this
# instrument cannot see the deploy path reported that nothing excludes the
# checkout — a could-not-look spelled exactly like a clean (L41, L105). Caught
# by the self-test case below rather than by reading, which is the only reason
# it is not in this file's first merge.
SKIP=unknown; SKIPWHY=""
if [ -r "$DEPLOYER" ]; then
  if grep -qF "$HOSTREPO" "$DEPLOYER" 2>/dev/null; then
    SKIP=yes
    SKIPWHY=$(grep -F "$HOSTREPO" "$DEPLOYER" | head -1 | sed 's/^[[:space:]]*#\{0,1\}[[:space:]]*//' | cut -c1-150)
    printf '  %-22s %s\n' "deployer" "$DEPLOYER names this checkout"
    printf '  %-22s %s\n' "its stated reason" "$SKIPWHY"
    echo "  An exclusion is read once and believed forever. Re-read that reason against"
    echo "  the four readings above before treating the distance as a scheduling problem."
  else
    SKIP=no
    printf '  %-22s %s\n' "deployer" "$DEPLOYER does not name this checkout either way"
  fi
else
  printf '  %-22s %s\n' "deployer" "not readable here: $DEPLOYER"
  echo "  So this section cannot say whether anything carries a merge to that"
  echo "  checkout. That is not the same as nothing carrying one."
fi

# The verdict this section exists to produce, in the three words that route to
# three different hands (L-A41: a finding that names one hand names every hand).
case "$SPECREACH:$FF" in
  NO*|PINNED*)                      ACT="repair the clone first — the fetch cannot see $MAIN" ;;
  *":a fast-forward would land")    ACT="a fast-forward and a restart, and that hand is root's" ;;
  *)                                ACT="a decision before a deploy — the two lineages have parted" ;;
esac
# A fast-forward that CAN land and a fast-forward git will PERFORM are two
# things: `git merge --ff-only` refuses while a tracked file differs in the
# working tree, and the files that differ here are the ones no commit holds. So
# the hand-patch count moves the act rather than sitting in a field below it,
# because the reassuring half is the half a reader acts on first.
if [ "${nocommit:-0}" -gt 0 ] && [ "$FF" = "a fast-forward would land" ]; then
  ACT="$nocommit file(s) in that working tree are text no commit holds, so the fast-forward is blocked until somebody rules on them; after that, a fast-forward and a restart, and that hand is root's"
fi
[ "$SKIP" = yes ] && ACT="$ACT. AND re-read the deployer's exclusion above, which is why nothing has"
[ "$SKIP" = unknown ] && ACT="$ACT. Whether any deployer carries this checkout could not be read here, so the act above may already be somebody's"
printf '  %-22s %s\n' "the act" "$ACT"

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
echo "executing_refspec_reach: $SPECREACH"
echo "executing_head_is_on: $HBRANCH"
echo "executing_own_origin_main: ${HOSTMAIN:0:8}"
echo "executing_last_successful_fetch: $FETCHAT"
echo "executing_fast_forward: $FF"
echo "deployer_read: $DEPLOYER"
echo "deployer_readable: $([ -r "$DEPLOYER" ] && echo yes || echo no)"
echo "deployer_excludes_this_checkout: $SKIP"
echo "the_act: $ACT"
echo '```'

[ "$dirty" = 0 ] && [ "$behind" = 0 ] && exit 0
exit 1
