#!/usr/bin/env bash
# Which open drafts has nobody left to lift the flag on?
#
#   bash docs/agents/drafts.sh            every open draft in this repository
#   bash docs/agents/drafts.sh --pr N     one pull request
#   bash docs/agents/drafts.sh --self-test  replays three real rows of 2026-10-26
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
#   1. Did the run that opened the draft end? A seat's log carries no result
#      object while the run is alive and carries one the moment the executor
#      returns, so the opening run's log answers this and nothing else does.
#
#   2. Is a later run of the same seat on this branch right now? Seats are
#      woken many times a day and a later run inherits the branch. If the
#      newest run of that seat has no result object yet, and the branch's
#      newest commit is at or after that run's start, that run is holding the
#      branch. It will ready its own draft (L71), and a wake sent into it
#      races a hand that is already there.
#
# Only a draft that fails both is abandoned. The remedy this count triggers is
# a wake of another seat, and a wake is an act against a live process, so the
# predicate under it has to be about who is present and not about who left
# (L74). The field that decides it -- the branch's newest commit -- was read by
# this script from its first day and discarded unused; two handoffs went out on
# 2026-10-26 claiming no hand was left, and `epitome/pm` refuted the second one
# in six minutes with a read this script could have done itself.
#
# Reads only. `gh` for the pull requests, the host's logs for the runs.
set -uo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)"

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
# second thing written down (L-X1 as amended).
read -r -d '' VERDICT <<'PY'
import datetime

def parse(s):
    return None if not s else datetime.datetime.fromisoformat(s.replace("Z", "+00:00"))

def verdict(opening_end, live_start, last_commit):
    """opening_end  when the run that opened the draft wrote its result object,
                    or None while that run is still in the room.
       live_start   start of the seat newest run that has no result object yet,
                    or None if no run of that seat is open.
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
  echo "== self-test: three rows of 2026-10-26, replayed through verdict() =="
  { python_prelude; cat <<'PY'
rows = [
    # pr, branch, opening run end, newest open run start, branch newest commit,
    # expected, and what the forge did next, which is why each row is evidence.
    ("#332", "epitome-engineer/2026-10-26-message-4",
     "2026-10-26T06:24:01Z", "2026-10-26T09:02:46Z", "2026-10-26T09:04:45Z",
     "held",
     "read at 09:21:00Z and routed as abandoned at 09:26:58Z; epitome/pm "
     "declined the wake at 09:32:02Z; that live run readied the draft itself "
     "at 09:46:52Z, 47s before its own result object"),
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
print("The reader this replaces returned abandoned for all three, because it "
      "read only the first column.")
print("%d of %d assertions failed." % (fails, len(rows)))
raise SystemExit(1 if fails else 0)
PY
  } | python3
  exit $?
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
import glob, json, os, re, sys

logs = os.environ["LOGS"]
RESULT = re.compile(r"\{\"duration_api_ms\".*?\"type\":\"result\".*?\}", re.S)
NAME = re.compile(r"(\d{4}-\d\d-\d\d)T(\d\d)-(\d\d)-(\d\d)-\d{3}Z-(.+)\.log")
now = datetime.datetime.now(datetime.timezone.utc)

def runs(seat):
    out = []
    for p in glob.glob(os.path.join(logs, seat, "*.log")):
        m = NAME.match(os.path.basename(p))
        if not m:
            continue
        start = datetime.datetime.fromisoformat(
            "%sT%s:%s:%s+00:00" % (m.group(1), m.group(2), m.group(3), m.group(4)))
        out.append((start, m.group(5), p))
    return sorted(out)

def ending(path):
    # The class of an ending comes from the result object FIELDS and from
    # nothing else in the file. The run text includes `result`, which is the
    # run final report -- for this seat, a report that quotes refusal
    # sentences -- so a search over the file reads the seat own words about a
    # refusal as a refusal (L65).
    text = open(path, errors="replace").read()
    m = RESULT.search(text)
    if not m:
        return None
    try:
        r = json.loads(m.group(0))
    except ValueError:
        return {"terminal_reason": "unparsable result object"}
    return r

def ended_at(path):
    # The result object carries a duration and no wall-clock stamp, so the
    # moment it appeared is the file mtime. That is the one fact on disk that
    # says when the run left the room.
    return datetime.datetime.fromtimestamp(os.path.getmtime(path), datetime.timezone.utc)

bad = held = seen = unknown = alive = 0
print("open drafts on this repository, against the host run logs at %s" % logs)
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
    seat_runs = runs(seat)
    owning = [r for r in seat_runs if r[0] <= ct]
    if not os.path.isdir(os.path.join(logs, seat)):
        print("#%-5s%-40s%5.0fm%6s  COULD NOT LOOK: no log directory for seat %r"
              % (num, branch[:39], age, ncommits, seat))
        unknown += 1
        continue
    if not owning:
        print("#%-5s%-40s%5.0fm%6s  COULD NOT LOOK: no run of %s started at or before this draft"
              % (num, branch[:39], age, ncommits, seat))
        unknown += 1
        continue

    start, kind, path = owning[-1]
    r = ending(path)
    stamp = "%s %s" % (start.strftime("%H:%M:%SZ"), kind)

    # The seat newest run with no result object, which may be any run and is
    # usually not the one that opened the draft.
    live = None
    for s, k, p in seat_runs:
        if ending(p) is None:
            live = (s, k)
    tag = verdict(None if r is None else ended_at(path),
                  None if live is None else live[0],
                  lc)

    if tag == "alive":
        note = "alive: %s has no result object yet" % stamp
        # Counted, because for three hours it was not. A class that can be
        # non-zero and never appear in the data block reads as zero to every
        # reader the charter tells to paste the block rather than retype it
        # (L41, L-A34, L-A88, L33). On 2026-10-26T10:33:14Z this script printed
        # one row and `drafts_open: 1` over three zeros, and the one row was
        # the reading run's own draft.
        alive += 1
    elif tag == "held":
        note = ("HELD by %s %s, live and on this branch (newest commit %s); its own "
                "run to ready, not a wake" % (live[0].strftime("%H:%M:%SZ"), live[1],
                                              lc.strftime("%H:%M:%SZ") if lc else "?"))
        held += 1
    else:
        tr = r.get("terminal_reason") or "?"
        st = r.get("api_error_status")
        why = tr if not st else "%s %s" % (tr, st)
        said = (r.get("result") or "").strip().replace("\n", " ")[:46]
        note = "ABANDONED %s -> %s%s" % (stamp, why, (" / " + said) if tr == "api_error" else "")
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
    print("%d draft(s) whose opening run ended but whose branch a live run of the same seat is "
          "working now: these are NOT routed as abandoned and no wake is asked for them, because "
          "a wake sent into a live run races the hand already there (L74)." % held)
if alive:
    print("%d draft(s) are held by their own opening run, which has not written a result object "
          "yet: that is the one state in which the rule is being obeyed rather than broken, and "
          "it is the reading run's own draft whenever a run of this seat is reading." % alive)
if unknown:
    print("%d draft(s) could not be judged: no run log answers for them, which is could-not-look "
          "and not a clean bill (L41)." % unknown)
print()
print("```data")
print("instrument: docs/agents/drafts.sh")
print("read_at: %s" % now.strftime("%Y-%m-%dT%H:%M:%SZ"))
print("logs: %s" % logs)
print("drafts_open: %d" % seen)
print("drafts_with_no_hand_left: %d" % bad)
print("drafts_held_by_a_live_run_of_their_seat: %d" % held)
print("drafts_held_by_their_own_opening_run: %d" % alive)
print("drafts_not_judgeable: %d" % unknown)
print("classes_sum_to_drafts_open: %s" % (bad + held + alive + unknown == seen))
print("```")
sys.exit(1 if bad else 0)
PY
} > "$PROG"
printf '%s' "$rows" | LOGS="$LOGS" python3 "$PROG"
exit $?
