#!/usr/bin/env python3
"""Is that run still in the room? Read the ending from whoever wrote it.

  python3 docs/agents/liveness.py --seat SEAT     that seat's newest run, open or ended
  python3 docs/agents/liveness.py --census        every log on this box, by terminator
  python3 docs/agents/liveness.py --self-test     seven real rows of 2026-10-26

Exit 0 the seat has no run in the room, 1 it has one, 2 could not look (L41).

WHY THIS EXISTS, AND WHY IT IS ONE FILE

Three readers on this box answer "is a run of that seat alive", and on
2026-10-26T14:54Z two of them disagreed about the same seat in the same
minute. `docs/agents/addressed.sh --liveness epitome-engineer` said *no run of
this seat is alive*. `docs/agents/drafts.sh` said draft `#346` was **HELD by a
23:02:09Z hook, live and on this branch**. The host had written
`# exit=timeout` into that run's log at 00:02:10Z, fourteen hours and
fifty-two minutes earlier.

The cause is not a staleness bound, which is where `docs/standards/lessons.md`
L-A112 would send a reader, and the bound is the second half of this file
rather than the first. It is that **a run has two terminators, written by two
different writers, and the instrument read the inner one.**

  * `cli/src/lib/runner.js` spawns the executor with `--output-format json`,
    which prints one object at exit and nothing before it. That object is the
    run's own account of itself, and it carries everything worth having:
    `num_turns`, `terminal_reason`, `api_error_status`, cost.
  * The same file, line 748, arms `setTimeout(... killGroup(child), timeoutMs)`
    and line 780 writes `# exit=${timedOut ? "timeout" : code ?? signal}`.

So the executor's mark is written by every ending the run *chooses* and by no
ending chosen *for* it, which is L-A112's second half exactly — and the host's
footer is written by the hand that does the choosing. **The record of a killing
is written by the killer.** An instrument that reads only the inner mark
therefore cannot see one single killed run, and the population it cannot see is
not a remainder: on this box, measured by `--census`, 39 logs carry the host's
footer with no result object behind it, 27 of them `exit=143` and 12
`exit=timeout`.

The sting, and the reason this is a rule and not a patch. `drafts.sh` asks two
questions: did the opening run end, and is a later run of the same seat on this
branch *now*. The second was added on 2026-10-26 as L74's repair, to stop this
seat routing a draft as abandoned while a hand was on it. Its test is
`last_commit >= live_start`. A ghost's `live_start` recedes into the past, so
that test gets **weaker every hour the ghost ages**, and against a ghost from
last night it passes for every commit on every branch that seat will ever push.
The 10:59:06Z commit it cited on `#346` was made eleven hours after the run it
credited was killed. A freshness test anchored to an unbounded start is not a
weak test, it is a tautology that looks like a measurement, and the repair that
added it made the instrument more confident rather than more correct.

THE BOUND, FOR THE RUNS NOBODY LEFT A MARK ON

321 logs on this box carry neither mark. They cluster on the days the host
itself died — 10-05, 10-17, 10-18, 10-23, 10-24 — so nothing was left running
to write anything, and for those a clock is the only separator there is, which
is L-A112 as written. The bound is **declared and not chosen**:
`cli/src/temporal/env.js:19` reads `EPITO_RUN_TIMEOUT_MS` and falls back to
`DEFAULT_RUN_TIMEOUT_MS`, fixed one line above at `60 * 60 * 1000`, and nothing
in `/srv/asc/env` sets that variable. The measurement agrees to a tenth of a
minute: across 1,666 logs that carry both marks the longest-lived run is 60.0
minutes, p99 is 50.3, and all twelve `exit=timeout` runs were killed at a span
of 60.0 to 60.2. The split in the no-mark class is not a judgement call either
— 17 of the 338 started in the last thirty minutes and the next oldest is
3,349 minutes, a hole of two and a third days with nothing in it.

Past the bound the answer is **lost** and says so in words: there is no exit
code, no turn count and no cause behind it, so nobody is dispatched at the
number (L-A112, L-X14).

Reads only. Needs the host's log directory; `EPITO_LOGS` overrides it.
"""

import datetime
import glob
import json
import os
import re
import sys

# The declared maximum lifetime, from `cli/src/temporal/env.js:10`, plus grace
# for the kill and the footer write. A bound this file chose for itself would be
# this file's opinion; this one is the runtime's own declaration and moves when
# it moves (L-A112, L-A143 — the value lives in exactly one file and this is a
# pointer at it, not a second copy of it).
WALL_MIN = 60.0
GRACE_MIN = 5.0

RESULT = re.compile(r'\{"duration_api_ms".*?"type":"result".*?\}', re.S)
FOOTER = re.compile(r"^# exit=(\S+)", re.M)
NAME = re.compile(r"(\d{4}-\d\d-\d\d)T(\d\d)-(\d\d)-(\d\d)-\d{3}Z-(.+)\.log")


def parse(s):
    return None if not s else datetime.datetime.fromisoformat(str(s).replace("Z", "+00:00"))


def ending(text, start, mtime, now, wall_min=WALL_MIN, grace_min=GRACE_MIN):
    """Did this run end, who says so, and what did they say?

    text    the log file's whole contents
    start   the run's start, from its filename
    mtime   the log's last write, which is when its last writer finished
    now     the moment of the reading

    Returns (ended_at, how, cause, result).

      how="result"  the executor's own object is there. `cause` is its
                    terminal_reason and `result` is the parsed object.
      how="footer"  only the host's footer is there, so the executor was killed
                    before it could report. `cause` is the footer's own word.
      how="lost"    neither mark, and past the declared wall clock. `cause` is
                    None, because nothing wrote one: lost is not failed.
      how=None      neither mark, inside the wall clock. Still in the room, and
                    `ended_at` is None.

    Four answers and never two (L41). The order is the point: outer writer
    first, because the inner one cannot describe its own killing.
    """
    foot = FOOTER.search(text)
    m = RESULT.search(text)
    obj = None
    if m:
        try:
            obj = json.loads(m.group(0))
        except ValueError:
            obj = {"terminal_reason": "unparsable result object"}
    if obj is not None:
        cause = obj.get("terminal_reason") or (foot.group(1) if foot else None)
        return mtime, "result", cause, obj
    if foot:
        # The host wrote this and the executor did not, so the run was killed.
        # mtime is the moment the footer was written, which is the kill.
        return mtime, "footer", foot.group(1), None
    age = (now - start).total_seconds() / 60.0
    if age > wall_min + grace_min:
        return start + datetime.timedelta(minutes=wall_min), "lost", None, None
    return None, None, None, None


def read(path, now):
    """One log, by the only three facts on disk: its name, its text, its mtime."""
    base = os.path.basename(path)
    m = NAME.match(base)
    if not m:
        return None
    start = datetime.datetime.fromisoformat(
        "%sT%s:%s:%s+00:00" % (m.group(1), m.group(2), m.group(3), m.group(4)))
    text = open(path, errors="replace").read()
    mtime = datetime.datetime.fromtimestamp(os.path.getmtime(path), datetime.timezone.utc)
    ended_at, how, cause, obj = ending(text, start, mtime, now)
    return {"path": path, "seat": os.path.basename(os.path.dirname(path)),
            "start": start, "trigger": m.group(5), "mtime": mtime,
            "ended_at": ended_at, "how": how, "cause": cause, "result": obj}


def seat_runs(logs, seat, now):
    out = [read(p, now) for p in glob.glob(os.path.join(logs, seat, "*.log"))]
    return sorted([r for r in out if r], key=lambda r: r["start"])


def in_the_room(runs):
    """The newest run with no ending at all, or None. This is the one field
    another instrument may treat as a live hand, and `how is None` is the whole
    of the test — a `footer` or a `lost` run is not a hand."""
    open_ = [r for r in runs if r["how"] is None]
    return open_[-1] if open_ else None


# ---------------------------------------------------------------- self-test

def self_test():
    now = parse("2026-10-26T14:54:52Z")

    def row(label, text, start, mtime, want_how, want_cause, note, nowish=now):
        got_at, got_how, got_cause, _ = ending(text, parse(start), parse(mtime), nowish)
        ok = got_how == want_how and got_cause == want_cause
        print("  %s %-34s want=%-7s got=%-7s cause=%s" %
              ("ok  " if ok else "FAIL", label, want_how, str(got_how), got_cause))
        print("       %s" % note)
        return 0 if ok else 1

    GHOST = (
        "# epito run epitome-engineer 2026-10-25T23-02-09-389Z-hook\n"
        "# trigger=hook model=claude-opus-5\n$ claude -p <prompt>\n---\n\n---\n"
        "# exit=timeout pr=- session=- turns=-\n")
    TRAILERED = (
        "# epito run epitome-engineer 2026-10-26T14-08-07-422Z-hook\n"
        '{"duration_api_ms":717000,"is_error":true,"num_turns":31,'
        '"subtype":"success","api_error_status":529,"terminal_reason":"api_error",'
        '"result":"API Error: 529 Overloaded.","type":"result","duration_ms":717944}\n'
        "\n---\n# exit=1 pr=- session=4cf1009d turns=31\n")
    BARE = ("# epito run epitome-engineer 2026-10-05T23-29-11-986Z-message\n"
            "# trigger=message model=claude-opus-5\n$ claude -p <prompt>\n")

    print("== self-test: seven real rows of 2026-10-26, through ending() ==")
    fails = 0
    fails += row(
        "the ghost on #346", GHOST, "2026-10-25T23:02:09Z", "2026-10-26T00:02:10Z",
        "footer", "timeout",
        "the host killed it at its wall clock and said so; drafts.sh called it "
        "live for 14h52m and named it as the hand on an open draft")
    fails += row(
        "a run that reported itself", TRAILERED, "2026-10-26T14:08:07Z",
        "2026-10-26T14:20:04Z", "result", "api_error",
        "the executor's own object is richer than the footer, so it wins when "
        "it is there: this is the 529 at turn 31 and the footer only says 1")
    fails += row(
        "no mark, 5 minutes old", BARE, "2026-10-26T14:49:52Z", "2026-10-26T14:49:52Z",
        None, None,
        "the one state in which nothing has ended: inside the declared wall "
        "clock with neither writer's mark")
    fails += row(
        "no mark, 64.9 minutes old", BARE, "2026-10-26T13:49:58Z", "2026-10-26T13:49:58Z",
        None, None,
        "the boundary control below the bound: 60 declared + 5 grace, so this "
        "is still in the room and the next row is not")
    fails += row(
        "no mark, 65.1 minutes old", BARE, "2026-10-26T13:49:46Z", "2026-10-26T13:49:46Z",
        "lost", None,
        "the boundary control above the bound, twelve seconds later: lost, with "
        "no cause, because nothing wrote one (L-X14 — nobody is dispatched here)")
    fails += row(
        "no mark, 20.6 days old", BARE, "2026-10-05T23:29:11Z", "2026-10-05T23:29:12Z",
        "lost", None,
        "a real one: the host died under it on 10-05, so no writer survived to "
        "mark either end. 321 logs on this box are this class")

    # The row that matters to the caller, and the one that fails against the
    # reader this file replaces: the ghost excluded flips #346's verdict.
    def verdict(opening_end, live_start, last_commit):
        if opening_end is None:
            return "alive"
        if live_start is not None and last_commit is not None and last_commit >= live_start:
            return "held"
        return "abandoned"

    ghost_at, ghost_how, _, _ = ending(GHOST, parse("2026-10-25T23:02:09Z"),
                                       parse("2026-10-26T00:02:10Z"), now)
    live = None if ghost_how is not None else parse("2026-10-25T23:02:09Z")
    got = verdict(parse("2026-10-26T11:23:14Z"), live, parse("2026-10-26T10:59:06Z"))
    ok = got == "abandoned"
    fails += 0 if ok else 1
    print("  %s %-34s want=%-7s got=%s" %
          ("ok  " if ok else "FAIL", "#346 with the ghost excluded", "abandoned", got))
    print("       the assertion that fails against the shipped reader: it had "
          "the ghost as the live hand and")
    print("       answered held, because a 10:59:06Z commit is at or after a "
          "23:02:09Z start however dead it is")

    print()
    print("%d of 7 assertions failed." % fails)
    return 1 if fails else 0


# ------------------------------------------------------------------ census

def census(logs, now):
    both = foot_only = res_only = 0
    lost = []
    room = []
    causes = {}
    for p in glob.glob(os.path.join(logs, "*", "*.log")):
        r = read(p, now)
        if not r:
            continue
        text = open(p, errors="replace").read()
        has_f = bool(FOOTER.search(text))
        has_r = bool(RESULT.search(text))
        if has_f and has_r:
            both += 1
        elif has_f:
            foot_only += 1
            causes[r["cause"]] = causes.get(r["cause"], 0) + 1
        elif has_r:
            res_only += 1
        elif r["how"] == "lost":
            lost.append(r)
        else:
            room.append(r)
    total = both + foot_only + res_only + len(lost) + len(room)
    print("every run log on this box at %s, by which writer marked its ending"
          % now.strftime("%Y-%m-%dT%H:%M:%SZ"))
    print("  both marks (the executor reported and the host logged it)  %5d" % both)
    print("  the host's footer only — the executor was killed first     %5d" % foot_only)
    for c, n in sorted(causes.items(), key=lambda kv: -kv[1]):
        print("      exit=%-10s %5d" % (c, n))
    print("  the executor's object only                                 %5d" % res_only)
    print("  neither mark, past the %g+%g min bound: LOST               %5d"
          % (WALL_MIN, GRACE_MIN, len(lost)))
    print("  neither mark, inside the bound: still in the room          %5d" % len(room))
    print()
    print("A reader of the executor's object alone calls %d of these live; a reader of "
          "the host's\nfooter alone calls %d live; this file calls %d live, which is the "
          "number of runs\nactually in the room." % (foot_only + len(lost) + len(room),
                                                     len(lost) + len(room), len(room)))
    print()
    print("```data")
    print("instrument: docs/agents/liveness.py --census")
    print("read_at: %s" % now.strftime("%Y-%m-%dT%H:%M:%SZ"))
    print("logs: %s" % logs)
    print("logs_total: %d" % total)
    print("ended_both_marks: %d" % both)
    print("ended_host_footer_only: %d" % foot_only)
    print("ended_executor_object_only: %d" % res_only)
    print("lost_no_mark_past_bound: %d" % len(lost))
    print("in_the_room: %d" % len(room))
    print("bound_minutes: %g" % (WALL_MIN + GRACE_MIN))
    print("bound_declared_at: cli/src/temporal/env.js:10")
    print("classes_sum_to_total: %s" % (total == both + foot_only + res_only + len(lost) + len(room)))
    print("```")
    return 0


def main(argv):
    logs = os.environ.get("EPITO_LOGS", "/srv/asc/state/.epito/logs")
    now = datetime.datetime.now(datetime.timezone.utc)
    if "--self-test" in argv:
        return self_test()
    if not os.path.isdir(logs):
        print("liveness.py: no run logs at %s — could not look, not a clean bill (L41)"
              % logs, file=sys.stderr)
        return 2
    if "--census" in argv:
        return census(logs, now)
    if "--seat" in argv:
        seat = argv[argv.index("--seat") + 1]
        if not os.path.isdir(os.path.join(logs, seat)):
            print("liveness.py: no log directory at %s/%s — this box cannot answer (L41)"
                  % (logs, seat), file=sys.stderr)
            return 2
        runs = seat_runs(logs, seat, now)
        if not runs:
            print("%s: no runs ever recorded" % seat)
            return 0
        live = in_the_room(runs)
        newest = runs[-1]
        for r in runs[-1:] if live is None else sorted({id(live): live, id(newest): newest}.values(),
                                                       key=lambda r: r["start"]):
            print("%s: %s %s — %s" % (
                seat, r["start"].strftime("%FT%TZ"), r["trigger"],
                {"result": "ended, the executor reported: %s" % r["cause"],
                 "footer": "ENDED, killed: the host wrote exit=%s at %s and the executor never "
                           "reported" % (r["cause"], r["mtime"].strftime("%H:%M:%SZ")),
                 "lost": "LOST: no mark from either writer and %.0f min past its %g min wall "
                         "clock, so there is no exit code and no turn count behind it"
                         % ((now - r["start"]).total_seconds() / 60 - WALL_MIN, WALL_MIN),
                 None: "IN THE ROOM: no mark from either writer, %.0f min old against a %g min "
                       "wall clock" % ((now - r["start"]).total_seconds() / 60, WALL_MIN),
                 }[r["how"]]))
        print("%s: %s" % (seat, "a run of this seat is in the room right now"
                          if live else "no run of this seat is in the room"))
        return 1 if live else 0
    print(__doc__.strip().split("\n\nWHY")[0])
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
