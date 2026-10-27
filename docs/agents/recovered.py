#!/usr/bin/env python3
"""How much of the dark after an announced reset was the recovery declining to fire.

    python3 docs/agents/recovered.py                 today, every seat on this host
    python3 docs/agents/recovered.py --days 2        a window
    python3 docs/agents/recovered.py --day 2026-10-26
    python3 docs/agents/recovered.py --self-test     fire every branch on built input

WHY THIS EXISTS, AND WHY `caps.sh` AND `idle.sh` BOTH MISS IT. This directory
already counts two things about a refused day. `caps.sh` counts refusals by
class and by trigger; `idle.sh` counts dark minutes and how many fall after the
day's last limit-touched run. Between them they answer *the provider refused us*
and *nothing asked for capacity once it came back* — and on 2026-10-26 the truth
was neither. Something did ask. `tools/capacity-retry.py` evaluated this host
every five minutes from 19:03Z, had nine seats whose logs met every one of its
conditions, and woke none of them, because its own safety cap was spent. The
charter's capacity line calls for "how much of that was after the resource came
back"; that number was 14 minutes for the day and it was true and it was not the
story. 993 seat-minutes were owed a wake that the mechanism built for exactly
this hole declined to send (L82, incident 45).

So the number this prints is a third class, and it is the one with a hand behind
it: **post-reset idle that a working recovery mechanism had already decided not
to close.** Idle nobody asked for is a missing mechanism. Idle the mechanism
refused is a tuned mechanism, tuned wrong, and the two take different fixes.

WHAT IT READS, AND THE ONE THING IT DOES NOT DO. Run logs, and HQ's claim file
if it is present. It does not import `capacity-retry.py` and does not re-run its
decision: that tool lives in `alexandra-systems`, no seat of this product may
write it, and a reader that re-implements the thing it audits agrees with itself
by construction (L-A47's shape). It reads the three facts that are on this box
either way — a refusal's announced reset, the seat's next run, and how many
claims the seat had already spent that UTC day — and it reports the arithmetic
between them. Where the claim file is missing it says so and prints the waits
without the cap column, which is could-not-look on one column and not a clean
bill on the rest (L41).

THE CAP COLUMN IS A RECONSTRUCTION AND SAYS SO. `max_per_day` defaults to 3 and
is the tool's default, not a reading of how the timer was invoked; the claim
file records the refused run's own filename and not the instant the claim was
written, so "claims already spent that day" is counted from claims whose refused
run started earlier that UTC day. Both are stated in band rather than implied,
because the one thing worse than not having this number is narrating it (L33).

Reads only. No credential, no network.
"""
import argparse
import glob
import json
import os
import re
import sys
from datetime import datetime, timedelta, timezone

LOGS = os.environ.get("EPITO_LOGS", "/srv/asc/state/.epito/logs")
CLAIMS = os.environ.get("EPITO_RETRY_STATE", "/srv/asc/state/.epito/capacity-retry.json")
DEFAULT_MAX_PER_DAY = 3
LOG_RE = re.compile(r"^(\d{4}-\d{2}-\d{2})T(\d{2})-(\d{2})-(\d{2})-\d{3}Z-(\w+)\.log$")
RESET_RE = re.compile(r"resets (\d{1,2})(?::(\d{2}))?\s*(am|pm)", re.I)


def parse_reset(text, start):
    """The provider's own sentence, as an instant. `resets 7pm (UTC)` on a run
    that started at 15:26Z is 19:00Z the same day; `resets 4am` on a run that
    started at 23:50Z is 04:00Z the next one. The roll-forward is the whole
    reason this is a function and not a regex at the call site."""
    m = RESET_RE.search(text or "")
    if not m:
        return None
    hour = int(m.group(1)) % 12
    if m.group(3).lower() == "pm":
        hour += 12
    minute = int(m.group(2) or 0)
    at = start.replace(hour=hour, minute=minute, second=0, microsecond=0)
    if at < start:
        at += timedelta(days=1)
    return at


def read_runs(root, days):
    runs = []
    for day in days:
        for path in glob.glob(os.path.join(root, "*", day + "T*.log")):
            m = LOG_RE.match(os.path.basename(path))
            if not m:
                continue
            start = datetime(int(m.group(1)[:4]), int(m.group(1)[5:7]), int(m.group(1)[8:10]),
                             int(m.group(2)), int(m.group(3)), int(m.group(4)),
                             tzinfo=timezone.utc)
            result = None
            with open(path, errors="replace") as fh:
                for line in fh:
                    # Parsed and then asked what it is, never matched as a
                    # substring: `"type":"result"` and `"type": "result"` are
                    # the same object and a reader that only accepts the
                    # host's current spacing is a reader that silently reads
                    # nothing the day the writer reformats (L-A80).
                    if not line.startswith("{"):
                        continue
                    try:
                        obj = json.loads(line)
                    except ValueError:
                        continue
                    if obj.get("type") == "result":
                        result = obj
            runs.append({
                "agent": os.path.basename(os.path.dirname(path)),
                "run": os.path.basename(path),
                "start": start,
                "trigger": m.group(5),
                "result": result,
            })
    runs.sort(key=lambda r: r["start"])
    return runs


def refusals(runs):
    """A refusal is read from the result object's fields and never from the
    log's prose: `subtype` says success on every provider refusal this host has
    recorded, and a seat that documents a refusal writes the sentence into its
    own final report (L64, caps.sh's note)."""
    out = []
    for r in runs:
        res = r["result"]
        if not res or res.get("api_error_status") != 429:
            continue
        reset = parse_reset(str(res.get("result", "")), r["start"])
        if reset is None:
            continue                     # a 429 with no announced reset: nothing to wait for
        out.append(dict(r, reset=reset, turns=res.get("num_turns")))
    return out


def claim_start(name):
    """A claim is a run's log filename, so it carries the instant of the run it
    claims — which is the nearest thing on this box to when the claim was
    written, the claim file itself recording no timestamps."""
    m = LOG_RE.match(name)
    if not m:
        return None
    return datetime(int(m.group(1)[:4]), int(m.group(1)[5:7]), int(m.group(1)[8:10]),
                    int(m.group(2)), int(m.group(3)), int(m.group(4)), tzinfo=timezone.utc)


def analyse(runs, claims, max_per_day, now):
    """Per seat: its last announced reset in the window, and what happened next.

    `waited` is minutes from the reset to the seat's next run of any trigger —
    the figure a reader compares across seats — and is None while no such run
    exists, which is a seat still waiting and not a zero."""
    by_agent = {}
    for r in runs:
        by_agent.setdefault(r["agent"], []).append(r)
    rows = []
    for ref in refusals(runs):
        later = [r for r in by_agent[ref["agent"]] if r["start"] > ref["start"]]
        nxt = next((r for r in later if r["start"] >= ref["reset"]), None)
        # Condition 4's shape: a run that started after the refusal and before
        # the reset already served the seat, so the reset owed it nothing.
        if any(r["start"] < ref["reset"] for r in later):
            continue
        spent = None
        if claims is not None:
            # Claims already spent AT THE MOMENT THIS RESET PASSED, which is
            # not the same set as the day's claims: the claim file is keyed by
            # the refused run's own filename, so a claim for a refusal later
            # in the day was not yet written when this one came due. Counting
            # the day's whole list reads the 03:00Z window through the 19:00Z
            # one and calls a seat capped that the retry recovered in three
            # minutes.
            day = ref["reset"].strftime("%Y-%m-%d")
            spent = len([c for c in claims.get(ref["agent"], [])
                         if c.startswith(day) and c != ref["run"]
                         and claim_start(c) is not None
                         and claim_start(c) < ref["reset"]])
        rows.append({
            "agent": ref["agent"],
            "refused_at": ref["start"],
            "turns": ref["turns"],
            "reset": ref["reset"],
            "next_run": nxt["start"] if nxt else None,
            "next_trigger": nxt["trigger"] if nxt else None,
            "waited": int((nxt["start"] - ref["reset"]).total_seconds() // 60) if nxt else None,
            "claims_spent_that_day": spent,
            "capped": None if spent is None else spent >= max_per_day,
        })
    rows.sort(key=lambda r: -(r["waited"] if r["waited"] is not None else 10 ** 6))
    return rows


def windows_per_day(runs):
    """Distinct announced reset hours per UTC day. This is the denominator the
    cap is sized against, and the only reason the cap ever binds."""
    out = {}
    for ref in refusals(runs):
        out.setdefault(ref["start"].strftime("%Y-%m-%d"), set()).add(
            ref["reset"].strftime("%H:%MZ"))
    return {k: sorted(v) for k, v in sorted(out.items())}


def report(rows, windows, claims_path, max_per_day, now, days, out=sys.stdout):
    p = lambda s="": print(s, file=out)
    p("post-reset waits on this host, read at %s over %s"
      % (now.strftime("%Y-%m-%dT%H:%M:%SZ"), ", ".join(days)))
    p("A wait is minutes from the provider's OWN announced reset to the seat's next run of "
      "any trigger. The cap column is a reconstruction: max_per_day=%d is "
      "`capacity-retry.py`'s default and not a reading of how the timer was invoked."
      % max_per_day)
    p()
    if not rows:
        p("recovered.py: no refusal in this window announced a reset it then had to wait on — "
          "could not look, not a clean bill")
        return 2
    p("%-22s%-22s%5s  %-22s%8s%7s  %s"
      % ("SEAT", "REFUSED", "TURN", "NEXT RUN", "WAITED", "SPENT", "NOTE"))
    total = capped_total = 0
    capped_rows = 0
    for r in rows:
        waited = "still" if r["waited"] is None else str(r["waited"]) + "m"
        note = ""
        if r["capped"]:
            note = "the retry's daily cap was spent before this reset passed"
            capped_rows += 1
            capped_total += r["waited"] or 0
        elif r["capped"] is False:
            note = "under the cap; recovered by %s" % (r["next_trigger"] or "nothing yet")
        else:
            note = "claim file unreadable — cap not judged"
        total += r["waited"] or 0
        p("%-22s%-22s%5s  %-22s%8s%7s  %s"
          % (r["agent"], r["refused_at"].strftime("%Y-%m-%dT%H:%M:%SZ"), r["turns"],
             r["next_run"].strftime("%Y-%m-%dT%H:%M:%SZ") if r["next_run"] else "-",
             waited, "-" if r["claims_spent_that_day"] is None else r["claims_spent_that_day"],
             note))
    p()
    for day, hours in windows.items():
        flag = "  <-- more windows than the cap has wakes" if len(hours) > max_per_day else ""
        p("%s: %d announced reset window(s) %s%s" % (day, len(hours), hours, flag))
    p()
    p("%d seat(s) waited past an announced reset, %d seat-minutes in all (%.1f seat-hours). "
      "%d of them were past the retry's daily cap at the moment their reset passed, carrying "
      "%d of those minutes."
      % (len(rows), total, total / 60.0, capped_rows, capped_total))
    if claims_path:
        p("claims read from %s" % claims_path)
    p()
    p("```data")
    p("instrument: docs/agents/recovered.py")
    p("read_at: %s" % now.strftime("%Y-%m-%dT%H:%M:%SZ"))
    p("window: %s" % ",".join(days))
    p("max_per_day_assumed: %d" % max_per_day)
    p("seats_waiting_past_a_reset: %d" % len(rows))
    p("seat_minutes_past_a_reset: %d" % total)
    p("seats_past_the_cap: %d" % capped_rows)
    p("seat_minutes_past_the_cap: %d" % capped_total)
    p("days_with_more_windows_than_wakes: %d"
      % len([d for d, h in windows.items() if len(h) > max_per_day]))
    p("claims_readable: %s" % bool(claims_path))
    p("```")
    return 1 if capped_rows else 0


# L42: a reader whose correctness was argued is not a detector. These fixtures
# are built rather than looked for, because a test that cannot run on a quiet
# day is an absence read as a pass.
def self_test():
    import tempfile
    ok = True

    def fail(msg):
        nonlocal ok
        print("recovered.py --self-test: " + msg, file=sys.stderr)
        ok = False

    # 1. The reset sentence, including the roll-forward past midnight.
    base = datetime(2026, 10, 26, 15, 26, 14, tzinfo=timezone.utc)
    if parse_reset("You've hit your session limit · resets 7pm (UTC)", base) != \
            datetime(2026, 10, 26, 19, 0, tzinfo=timezone.utc):
        fail("`resets 7pm` on a 15:26Z run is 19:00Z the same day")
    late = datetime(2026, 10, 26, 23, 50, tzinfo=timezone.utc)
    if parse_reset("resets 4am (UTC)", late) != datetime(2026, 10, 27, 4, 0, tzinfo=timezone.utc):
        fail("`resets 4am` on a 23:50Z run rolls to the next day")
    if parse_reset("resets 11:20am (UTC)", base) != \
            datetime(2026, 10, 26, 11, 20, tzinfo=timezone.utc) + timedelta(days=1):
        fail("a reset with minutes parses, and rolls when it is already past")
    if parse_reset("the provider was overloaded", base) is not None:
        fail("a 429 with no announced reset is not a wait")

    root = tempfile.mkdtemp()

    def write(agent, stamp, trigger, result=None):
        d = os.path.join(root, agent)
        os.makedirs(d, exist_ok=True)
        path = os.path.join(d, "%s-%s.log" % (stamp, trigger))
        with open(path, "w") as fh:
            fh.write("# epito run %s %s-%s\n---\n" % (agent, stamp, trigger))
            if result:
                fh.write(json.dumps(result) + "\n")
        return os.path.basename(path)

    refused = {"type": "result", "subtype": "success", "api_error_status": 429,
               "num_turns": 50, "terminal_reason": "api_error",
               "result": "You've hit your session limit · resets 7pm (UTC)"}
    done = {"type": "result", "subtype": "success", "terminal_reason": "completed",
            "num_turns": 12}

    # capped: three claims already spent that UTC day, and the seat sits five hours.
    capped_run = write("capped-seat", "2026-10-26T15-26-14-031Z", "message", refused)
    write("capped-seat", "2026-10-27T00-03-53-048Z", "hook", done)
    # under the cap: one claim spent, recovered 20 minutes after the reset.
    free_run = write("free-seat", "2026-10-26T15-27-13-910Z", "message", refused)
    write("free-seat", "2026-10-26T19-20-00-000Z", "message", done)
    # served before the reset: owed nothing, must not appear at all.
    write("served-seat", "2026-10-26T15-29-18-256Z", "message", refused)
    write("served-seat", "2026-10-26T16-00-00-000Z", "message", done)
    # still waiting: a wait with no next run is `still`, never 0.
    write("waiting-seat", "2026-10-26T15-30-24-051Z", "message", refused)

    claims = {
        "capped-seat": ["2026-10-26T00-58-03-159Z-message.log",
                        "2026-10-26T06-22-11-122Z-message.log",
                        "2026-10-26T12-01-59-494Z-message.log", capped_run],
        # Two claims before this reset and two after it. A reader that counts
        # the day's whole list calls this seat capped; it was recovered in
        # twenty minutes and it was never capped.
        "free-seat": ["2026-10-26T06-03-16-268Z-message.log", free_run,
                      "2026-10-26T20-00-00-000Z-message.log",
                      "2026-10-26T22-00-00-000Z-message.log"],
    }
    now = datetime(2026, 10, 27, 0, 10, tzinfo=timezone.utc)
    runs = read_runs(root, ["2026-10-26", "2026-10-27"])
    rows = analyse(runs, claims, DEFAULT_MAX_PER_DAY, now)
    seen = {r["agent"]: r for r in rows}

    if "served-seat" in seen:
        fail("a seat whose own run started between the refusal and the reset is owed nothing")
    if sorted(seen) != ["capped-seat", "free-seat", "waiting-seat"]:
        fail("expected exactly the three waiting seats, got %s" % sorted(seen))
    if seen.get("capped-seat", {}).get("waited") != 303:
        fail("19:00Z -> 00:03:53Z is 303 minutes, got %r" % seen.get("capped-seat", {}).get("waited"))
    if seen.get("capped-seat", {}).get("capped") is not True:
        fail("three claims spent that day against a cap of three is capped")
    if seen.get("capped-seat", {}).get("claims_spent_that_day") != 3:
        fail("the run's own claim is not one of the claims spent before it")
    if seen.get("free-seat", {}).get("capped") is not False:
        fail("one claim spent BEFORE this reset against a cap of three is not capped")
    if seen.get("free-seat", {}).get("claims_spent_that_day") != 1:
        fail("claims for refusals later in the day were not yet written when this reset "
             "passed, got %r" % seen.get("free-seat", {}).get("claims_spent_that_day"))
    if seen.get("free-seat", {}).get("waited") != 20:
        fail("19:00Z -> 19:20Z is 20 minutes")
    if seen.get("waiting-seat", {}).get("waited") is not None:
        fail("a seat with no run after its reset is still waiting, not 0 minutes")
    if rows[0]["agent"] != "waiting-seat":
        fail("a seat still waiting sorts above every finite wait")

    # The cap column is the one thing that can be unreadable, and an unreadable
    # claim file must cost that column and nothing else.
    blind = analyse(runs, None, DEFAULT_MAX_PER_DAY, now)
    if len(blind) != 3 or any(r["capped"] is not None for r in blind):
        fail("no claim file: the waits still print and the cap column is not judged")

    windows = windows_per_day(runs)
    if windows.get("2026-10-26") != ["19:00Z"]:
        fail("one announced reset hour on the fixture day, got %r" % windows.get("2026-10-26"))

    import io
    buf = io.StringIO()
    rc = report(rows, windows, "fixture", DEFAULT_MAX_PER_DAY, now, ["2026-10-26"], out=buf)
    if rc != 1:
        fail("a capped seat exits 1 so a timer can act on it, got %r" % rc)
    if "the retry's daily cap was spent before this reset passed" not in buf.getvalue():
        fail("the capped row names the cap in band")
    empty = report([], {}, "fixture", DEFAULT_MAX_PER_DAY, now, ["2026-10-26"], out=io.StringIO())
    if empty != 2:
        fail("nothing to look at exits 2 — could not look, not a clean bill, got %r" % empty)

    if ok:
        print("recovered.py --self-test: all assertions pass")
    return 0 if ok else 1


def main():
    ap = argparse.ArgumentParser(add_help=True)
    ap.add_argument("--days", type=int, default=1)
    ap.add_argument("--day")
    ap.add_argument("--root", default=LOGS)
    ap.add_argument("--state", default=CLAIMS)
    ap.add_argument("--max-per-day", type=int, default=DEFAULT_MAX_PER_DAY)
    ap.add_argument("--self-test", action="store_true")
    args = ap.parse_args()
    if args.self_test:
        return self_test()

    now = datetime.now(timezone.utc)
    if args.day:
        days = [args.day]
    else:
        days = sorted({(now - timedelta(days=i)).strftime("%Y-%m-%d")
                       for i in range(args.days)})
    if not os.path.isdir(args.root):
        print("recovered.py: no run logs at %s — this runs where the host's logs are; "
              "could not look" % args.root, file=sys.stderr)
        return 2
    claims, claims_path = None, None
    try:
        with open(args.state) as fh:
            claims, claims_path = json.load(fh), args.state
    except (OSError, ValueError):
        print("recovered.py: %s is not readable — the waits below are still true and the "
              "cap column is could-not-look" % args.state, file=sys.stderr)

    runs = read_runs(args.root, days)
    rows = analyse(runs, claims, args.max_per_day, now)
    return report(rows, windows_per_day(runs), claims_path, args.max_per_day, now, days)


if __name__ == "__main__":
    sys.exit(main())
