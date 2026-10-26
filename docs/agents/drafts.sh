#!/usr/bin/env bash
# Which open drafts has nobody left to lift the flag on?
#
#   bash docs/agents/drafts.sh            every open draft in this repository
#   bash docs/agents/drafts.sh --pr N     one pull request
#   bash docs/agents/drafts.sh --self-test  replays four real rows of 2026-10-26
#
# Exit 0 no abandoned draft, 1 at least one, 2 could not look (L41).
#
# WHY THIS EXISTS. `prompts/exo-agent.md` asks this seat for two standing
# counts every run, and the second one is "the drafts whose run has ended",
# with the charter's own reason: "a draft is legitimate only while its own run
# is alive, that rule binds the run that opened it, and a run that has ended
# cannot obey it, so this cadence is the only thing watching." A duty worded
# that way has been counted by hand every run since it was written, and
# L-A22 says the gate goes in the command rather than in the charter. This is
# the command.
#
# The test is not the draft's age and not its commit count. It is whether a
# hand is left that can lift the flag, and that is two facts rather than one
# (L74).
#
#   1. Did the run that opened the draft end?
#   2. Is a later run of the same seat on this branch right now? Seats are
#      woken many times a day and a later run inherits the branch. If the
#      newest run of that seat is still in the room, and the branch's newest
#      commit is at or after that run's start, that run is holding the branch.
#      It will ready its own draft (L71), and a wake sent into it races a hand
#      that is already there.
#
# Only a draft that fails both is abandoned. The remedy this count triggers is
# a wake of another seat, and a wake is an act against a live process, so the
# predicate under it has to be about who is present and not about who left
# (L74). The field that decides it -- the branch's newest commit -- was read by
# this script from its first day and discarded unused; two handoffs went out on
# 2026-10-26 claiming no hand was left, and `epitome/pm` refuted the second one
# in six minutes with a read this script could have done itself.
#
# WHAT WAS WRONG WITH BOTH HALVES UNTIL 2026-10-26T15:0xZ (L81, incident 44).
# Neither question is answerable from the executor's result object, and this
# script asked both of it. A run has two terminators: the object the executor
# prints at exit, and the `# exit=` footer `cli/src/lib/runner.js:780` writes
# after killing it. The first is written by every ending a run *chooses* and by
# no ending chosen *for* it, so a reader of it alone cannot see one killed run.
# At 14:54:52Z this script named `epitome-engineer`'s 23:02:09Z hook as the live
# hand on draft `#346`; the host had written `# exit=timeout` into that log at
# 00:02:10Z, fourteen hours and fifty-two minutes earlier, and
# `addressed.sh --liveness` said in the same minute that no run of that seat was
# alive. Worse, question 2's own test -- `last_commit >= live_start` -- gets
# *weaker* the longer a ghost ages, so the repair that added it this morning
# made this script more confident rather than more correct.
#
# The liveness read now lives in exactly one file, `docs/agents/liveness.py`
# (L-A143), which reads the outer writer's mark first and falls back to the
# declared wall clock for the runs nobody marked at all. Nothing in this
# script decides it any more.
#
# Reads only. `gh` for the pull requests, the host's logs for the runs.
set -uo pipefail
REPO=$(git rev-parse --show-toplevel 2>/dev/null || echo .)
cd "$REPO"
export REPO

LOGS=${EPITO_LOGS:-/srv/asc/state/.epito/logs}
ONE=
SELFTEST=
while [ $# -gt 0 ]; do
  case "$1" in
    --pr) ONE=${2:?--pr needs a number}; shift 2 ;;
    --logs) LOGS=${2:?--logs needs a path}; shift 2 ;;
    --self-test) SELFTEST=1; shift ;;
    --help|-h) sed -n '2,/^[^#]/p' "${BASH_SOURCE[0]}" | sed -n 's/^# \{0,1\}//p'; exit 0 ;;
    *) echo "drafts.sh: unknown argument $1" >&2; exit 2 ;;
  esac
done

# The predicate, written once and shared by the live read and the self-test,
# because a detector whose self-test exercises a second copy of its rule is a
# second thing written down (L-X1 as amended). `verdict` is this script's own;
# everything about whether a run ended comes from `liveness.py`, which has its
# own self-test and its own boundary controls.
read -r -d '' VERDICT <<'PY'
import datetime, os, sys
sys.path.insert(0, os.path.join(os.environ.get("REPO", "."), "docs", "agents"))
import liveness
from liveness import parse, ending, seat_runs, in_the_room

def verdict(opening_end, live_start, last_commit):
    """opening_end  when the run that opened the draft ended, by whichever
                    writer marked it, or None while that run is in the room.
       live_start   start of the newest run of that seat still in the room, or
                    None if no run of that seat is. A run the host killed is
                    not in the room however recently it was started.
       last_commit  committedDate of the branch newest commit.
       Returns one of: alive, held, abandoned."""
    if opening_end is None:
        return "alive"
    if live_start is not None and last_commit is not None and last_commit >= live_start:
        return "held"
    return "abandoned"
PY

python_prelude() { printf '%s\n' "$VERDICT"; }

if [ -n "$SELFTEST" ]; then
  echo "== self-test: four real rows of 2026-10-26, replayed through verdict() =="
  { python_prelude; cat <<'PY'
rows = [
    # pr, branch, opening run end, newest IN-THE-ROOM run start, branch newest
    # commit, expected, and what the forge did next, which is why each row is
    # evidence.
    ("#346", "epitome-engineer/2026-10-26-message-6",
     "2026-10-26T11:23:14Z", None, "2026-10-26T10:59:06Z",
     "abandoned",
     "the row this script got wrong for 4h17m: it had the seat's 23:02:09Z "
     "hook as the live hand, and the host had written exit=timeout into that "
     "log at 00:02:10Z. With the ghost gone no run of that seat is in the "
     "room, and the draft has had none since 11:23:14Z"),
    ("#332", "epitome-engineer/2026-10-26-message-4",
     "2026-10-26T06:24:01Z", "2026-10-26T09:02:46Z", "2026-10-26T09:04:45Z",
     "held",
     "read at 09:21:00Z and routed as abandoned at 09:26:58Z; epitome/pm "
     "declined the wake at 09:32:02Z; that live run readied the draft itself "
     "at 09:46:52Z, 47s before its own result object. The hand was real: "
     "liveness.py puts that run in the room at that minute"),
    ("#323", "epitome-engineer/2026-10-26-message-2",
     "2026-10-26T00:58:14Z", "2026-10-26T04:02:26Z", "2026-10-26T04:15:07Z",
     "held",
     "read at 04:17:29Z and routed as abandoned at 04:20:44Z, 79s after the "
     "live run commit this row names"),
    ("#320", "epitome-engineer/2026-10-26-message",
     "2026-10-26T00:21:20Z", "2026-10-26T04:02:26Z", "2026-10-26T00:04:48Z",
     "abandoned",
     "the negative control: same seat, same minute, same live run, and that "
     "run never touched this branch; closed and re-declared at 04:47:40Z"),
]
fails = 0
for pr, branch, end, live, commit, want, note in rows:
    got = verdict(parse(end), parse(live), parse(commit))
    ok = "ok  " if got == want else "FAIL"
    if got != want:
        fails += 1
    print("  %s %-5s %-40s want=%-9s got=%s" % (ok, pr, branch[:39], want, got))
    print("       %s" % note)
print()
print("The reader before L74 returned abandoned for all four, because it read "
      "only the first column.")
print("The reader before L81 returned held for the first, because it took a "
      "killed run as a live hand.")
print("%d of %d assertions failed." % (fails, len(rows)))
print()
print("liveness.py carries its own seven, including both boundary controls:")
raise SystemExit(1 if fails else 0)
PY
  } | python3
  rc=$?
  python3 docs/agents/liveness.py --self-test | sed 's/^/  /'
  rc2=$?
  exit $(( rc || rc2 ))
fi

command -v gh >/dev/null || { echo "drafts.sh: no gh, so this cannot look (L41)" >&2; exit 2; }
if [ ! -d "$LOGS" ]; then
  echo "drafts.sh: no run logs at $LOGS — this answers only where the host's logs are; could not look, not a clean bill (L41)" >&2
  exit 2
fi

# `gh pr view` per number rather than `gh pr list --json commits`: the list
# form walks every author node and the API refuses it on this repository with
# "requesting up to 1,000,000 possible nodes", which is a read that comes back
# as an error rather than as a short answer (L-A87).
if [ -n "$ONE" ]; then nums=$ONE
else nums=$(gh pr list --limit 200 --json number,isDraft --jq '.[]|select(.isDraft)|.number') || {
       echo "drafts.sh: could not list pull requests (L41)" >&2; exit 2; }
fi
[ -n "${nums:-}" ] || { echo "no open draft on this repository, read from gh at $(date -u +%FT%TZ)"; exit 0; }

rows=
for n in $nums; do
  v=$(gh pr view "$n" --json number,headRefName,createdAt,isDraft,commits \
        --jq '[.number,.headRefName,.createdAt,(.isDraft|tostring),(.commits|length),.commits[-1].committedDate]|@tsv') || {
      echo "drafts.sh: could not read pull request $n (L41)" >&2; exit 2; }
  rows="$rows$v"$'\n'
done

PROG=$(mktemp); trap 'rm -f "$PROG"' EXIT
{ python_prelude; cat <<'PY'
import os, sys

logs = os.environ["LOGS"]
now = datetime.datetime.now(datetime.timezone.utc)

# How a run's ending is described to the reader, per writer. The point of
# printing the writer is that a reader who disagrees can go and look at the
# same line this did (L-A112 asks for the bound to be visible rather than
# inferred from the classes).
def why_ended(r):
    if r["how"] == "result":
        st = (r["result"] or {}).get("api_error_status")
        tr = r["cause"] or "?"
        return tr if not st else "%s %s" % (tr, st)
    if r["how"] == "footer":
        return ("killed, exit=%s: the host wrote it at %s and the executor "
                "never reported" % (r["cause"], r["mtime"].strftime("%H:%M:%SZ")))
    if r["how"] == "lost":
        return ("LOST: neither writer left a mark and it is past its %g min wall "
                "clock, so there is no exit code behind this" % liveness.WALL_MIN)
    return "?"

bad = held = seen = unknown = alive = 0
print("open drafts on this repository, against the host run logs at %s" % logs)
print("A run is in the room only while neither writer has marked its ending and it is "
      "inside the %g+%g min bound declared at cli/src/temporal/env.js:10 (docs/agents/liveness.py)."
      % (liveness.WALL_MIN, liveness.GRACE_MIN))
print()
print("%-6s%-40s%-7s%6s  %s" % ("PR", "BRANCH", "AGE", "CMTS", "WHOSE HAND"))
for line in sys.stdin.read().splitlines():
    if not line.strip():
        continue
    num, branch, created, isdraft, ncommits, lastcommit = line.split("\t")
    if isdraft != "true":
        continue
    seen += 1
    ct = parse(created)
    lc = parse(lastcommit)
    age = (now - ct).total_seconds() / 60
    seat = branch.split("/")[0]
    if not os.path.isdir(os.path.join(logs, seat)):
        print("#%-5s%-40s%5.0fm%6s  COULD NOT LOOK: no log directory for seat %r"
              % (num, branch[:39], age, ncommits, seat))
        unknown += 1
        continue
    runs = seat_runs(logs, seat, now)
    owning = [r for r in runs if r["start"] <= ct]
    if not owning:
        print("#%-5s%-40s%5.0fm%6s  COULD NOT LOOK: no run of %s started at or before this draft"
              % (num, branch[:39], age, ncommits, seat))
        unknown += 1
        continue

    op = owning[-1]
    stamp = "%s %s" % (op["start"].strftime("%H:%M:%SZ"), op["trigger"])

    # The seat's newest run still in the room, which may be any run and is
    # usually not the one that opened the draft. A killed run is not one.
    live = in_the_room(runs)
    tag = verdict(op["ended_at"], None if live is None else live["start"], lc)

    if tag == "alive":
        note = "alive: %s has not ended by either writer's mark" % stamp
        # Counted, because for three hours it was not. A class that can be
        # non-zero and never appear in the data block reads as zero to every
        # reader the charter tells to paste the block rather than retype it
        # (L41, L-A34, L-A88, L33). On 2026-10-26T10:33:14Z this script printed
        # one row and `drafts_open: 1` over three zeros, and the one row was
        # the reading run's own draft.
        alive += 1
    elif tag == "held":
        note = ("HELD by %s %s, in the room and on this branch (newest commit %s); its own "
                "run to ready, not a wake" % (live["start"].strftime("%H:%M:%SZ"), live["trigger"],
                                              lc.strftime("%H:%M:%SZ") if lc else "?"))
        held += 1
    else:
        note = "ABANDONED %s -> %s" % (stamp, why_ended(op))
        if live is not None:
            note += " / a run of %s is in the room since %s but has not touched this branch" % (
                seat, live["start"].strftime("%H:%M:%SZ"))
        bad += 1
        if int(ncommits) == 1:
            note += " [opening commit only]"
    print("#%-5s%-40s%5.0fm%6s  %s" % (num, branch[:39], age, ncommits, note))

print()
if bad:
    print("%d of %d open draft(s) have no hand left. GitHub refuses to merge a "
          "draft, so each of these has shipped nothing whatever its branch holds (L-A32). A "
          "draft carrying only its opening commit is closed and re-declared; one carrying work "
          "is readied by the seat that owns the branch, and no other hand may lift the flag."
          % (bad, seen))
else:
    print("%d open draft(s) and not one of them is without a hand, read from %s." % (seen, logs))
if held:
    print("%d draft(s) whose opening run ended but whose branch a run of the same seat is "
          "working now: these are NOT routed as abandoned and no wake is asked for them, because "
          "a wake sent into a live run races the hand already there (L74)." % held)
if alive:
    print("%d draft(s) are held by their own opening run, which neither writer has marked an "
          "ending for: that is the one state in which the rule is being obeyed rather than "
          "broken, and it is the reading run's own draft whenever a run of this seat is reading."
          % alive)
if unknown:
    print("%d draft(s) could not be judged: no run log answers for them, which is could-not-look "
          "and not a clean bill (L41)." % unknown)
print()
print("```data")
print("instrument: docs/agents/drafts.sh")
print("read_at: %s" % now.strftime("%Y-%m-%dT%H:%M:%SZ"))
print("logs: %s" % logs)
print("liveness_reader: docs/agents/liveness.py")
print("bound_minutes: %g" % (liveness.WALL_MIN + liveness.GRACE_MIN))
print("drafts_open: %d" % seen)
print("drafts_with_no_hand_left: %d" % bad)
print("drafts_held_by_a_run_in_the_room: %d" % held)
print("drafts_held_by_their_own_opening_run: %d" % alive)
print("drafts_not_judgeable: %d" % unknown)
print("classes_sum_to_drafts_open: %s" % (bad + held + alive + unknown == seen))
print("```")
sys.exit(1 if bad else 0)
PY
} > "$PROG"
printf '%s' "$rows" | LOGS="$LOGS" REPO="$REPO" python3 "$PROG"
exit $?
