#!/usr/bin/env bash
# Which open drafts belong to a run that has already ended?
#
#   bash docs/agents/drafts.sh            every open draft in this repository
#   bash docs/agents/drafts.sh --pr N     one pull request
#   bash docs/agents/drafts.sh --self-test  fires on a known positive and a known negative
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
# The test is not the draft's age and not its commit count. It is whether the
# run that opened it is still in the room, and that is a fact about the host's
# run logs: a seat's log carries no result object while the run is alive and
# carries one the moment the executor returns. So a draft whose owning run has
# a result object is unmergeable with nobody left to lift its flag — GitHub
# refuses to merge a draft at all, so whatever its branch holds, it has
# shipped nothing (L-A32, L-A96).
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

printf '%s' "$rows" | LOGS="$LOGS" python3 -c '
import datetime, glob, json, os, re, sys

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

bad = seen = unknown = 0
print("open drafts on this repository, against the host run logs at %s" % logs)
print()
print("%-6s%-40s%-7s%6s  %s" % ("PR", "BRANCH", "AGE", "CMTS", "OWNING RUN"))
for line in sys.stdin.read().splitlines():
    if not line.strip():
        continue
    num, branch, created, isdraft, ncommits, lastcommit = line.split("\t")
    if isdraft != "true":
        continue
    seen += 1
    ct = datetime.datetime.fromisoformat(created.replace("Z", "+00:00"))
    age = (now - ct).total_seconds() / 60
    seat = branch.split("/")[0]
    owning = [r for r in runs(seat) if r[0] <= ct]
    if not os.path.isdir(os.path.join(logs, seat)):
        note = "COULD NOT LOOK: no log directory for seat %r" % seat
        unknown += 1
    elif not owning:
        note = "COULD NOT LOOK: no run of %s started at or before this draft" % seat
        unknown += 1
    else:
        start, kind, path = owning[-1]
        r = ending(path)
        stamp = "%s %s" % (start.strftime("%H:%M:%SZ"), kind)
        if r is None:
            note = "alive: %s has no result object yet" % stamp
        else:
            tr = r.get("terminal_reason") or "?"
            st = r.get("api_error_status")
            why = tr if not st else "%s %s" % (tr, st)
            said = (r.get("result") or "").strip().replace("\n", " ")[:46]
            note = "ENDED %s -> %s%s" % (stamp, why, (" / " + said) if tr == "api_error" else "")
            bad += 1
            if int(ncommits) == 1:
                note += " [opening commit only]"
    print("#%-5s%-40s%5.0fm%6s  %s" % (num, branch[:39], age, ncommits, note))

print()
if bad:
    print("%d of %d open draft(s) belong to a run that has ended. GitHub refuses to merge a "
          "draft, so each of these has shipped nothing whatever its branch holds (L-A32). A "
          "draft carrying only its opening commit is closed and re-declared; one carrying work "
          "is readied by the seat that owns the branch, and no other hand may lift the flag."
          % (bad, seen))
else:
    print("%d open draft(s) and every one of them has a live run, read from %s." % (seen, logs))
if unknown:
    print("%d draft(s) could not be judged: no run log answers for them, which is could-not-look "
          "and not a clean bill (L41)." % unknown)
print()
print("```data")
print("instrument: docs/agents/drafts.sh")
print("read_at: %s" % now.strftime("%Y-%m-%dT%H:%M:%SZ"))
print("logs: %s" % logs)
print("drafts_open: %d" % seen)
print("drafts_whose_run_has_ended: %d" % bad)
print("drafts_not_judgeable: %d" % unknown)
print("```")
sys.exit(1 if bad else 0)
'
rc=$?

if [ -n "$SELFTEST" ]; then
  echo
  echo "== self-test: the positive and the negative this was checked against =="
  echo "Both are facts about 2026-10-26 on this host and both are re-readable:"
  echo "  positive  #325, opened 00:49:10Z by the epitome-exo run that started"
  echo "            00:40:19Z, which the provider refused at turn 72 with a 429;"
  echo "            that log carries a result object, so the draft is abandoned."
  echo "  negative  #326, opened 04:04:29Z by the epitome-exo run that started"
  echo "            04:02:27Z, which was still in the room; no result object."
  echo "A detector nobody has seen fire is a second thing written down (L-X1 as"
  echo "amended), so the rows above are the firing and this block is the control."
fi
exit $rc
