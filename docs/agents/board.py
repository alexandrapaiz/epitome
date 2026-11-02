#!/usr/bin/env python3
"""Read a window of the board whole, or say which part of it you could not see.

  python3 docs/agents/board.py --hours 600 [--from-seat exo] [--kind ask]
  python3 docs/agents/board.py --self-test

WHY THIS EXISTS. One read of `/api/messages` answers with a page, and a page
has a limit: 500 rows at `since_hours=600` reach back to 2026-10-26T19:24Z and
stop, because this company writes more than 500 messages in six days. Every
instrument that asks the board one question and reads the answer as the window
is therefore answering about the newest slice of it, and the error has a
direction -- an item whose asks are older than the slice reads as an item
nobody ever asked about, which is the loudest possible wrong answer for a
reader looking for a hand that holds something (L86).

So the window is walked in slices, with `before_hours`, and a slice that fills
its own page is split rather than believed. What cannot be split below an hour
is *reported*: `fetch` returns the rows and the list of windows it could not
see whole, and a caller that ignores that list is making the same mistake one
level up. L77: the all-clear of an instrument is a statement about its input.
"""
import json
import os
import sys
import urllib.error
import urllib.request

LIMIT = 500


def _one(since, before, filters, limit=LIMIT):
    url, tok = os.environ.get("BOARD_API_URL"), os.environ.get("BOARD_RUNTIME_TOKEN")
    if not url or not tok:
        raise RuntimeError("BOARD_API_URL / BOARD_RUNTIME_TOKEN are not set")
    q = f"{url}/api/messages?since_hours={since}&before_hours={before}&limit={limit}&everyone=1"
    for k, v in (filters or {}).items():
        if v is not None:
            q += f"&{k}={v}"
    req = urllib.request.Request(q, headers={"Authorization": f"Bearer {tok}"})
    with urllib.request.urlopen(req, timeout=60) as r:
        page = json.load(r)
    if not isinstance(page, dict) or "messages" not in page:
        raise RuntimeError(f"the board answered something other than a page: "
                           f"{str(page)[:120]}")
    return page["messages"]


def fetch(hours, filters=None, slice_hours=24, read=_one):
    """(rows, blind) over the last `hours`. `blind` lists windows read partially.

    A window whose page fills is halved and re-read; a window of an hour that
    still fills is recorded in `blind` rather than silently truncated."""
    rows, blind, seen = [], [], set()

    def walk(since, before):
        got = read(since, before, filters)
        if len(got) >= LIMIT:
            if since - before <= 1:
                blind.append({"since_hours": since, "before_hours": before,
                              "rows": len(got)})
            else:
                mid = before + (since - before) // 2
                walk(since, mid)
                walk(mid, before)
                return
        for m in got:
            key = (m.get("ts"), m.get("from_seat"), m.get("subject"))
            if key not in seen:
                seen.add(key)
                rows.append(m)

    before = 0
    while before < hours:
        since = min(before + slice_hours, hours)
        walk(since, before)
        before = since
    rows.sort(key=lambda m: m.get("ts") or "", reverse=True)
    return rows, blind


def self_test():
    fail = 0

    def check(label, cond, detail=""):
        nonlocal fail
        print(f"  {'ok  ' if cond else 'FAIL'}  {label}" + ("" if cond else f"  {detail}"))
        if not cond:
            fail = 1

    # A fake board: one row per hour, so a slice's row count is its width.
    def fake(since, before, filters):
        return [{"ts": f"h{h:04d}", "from_seat": "x", "subject": "s"}
                for h in range(before, since)]

    rows, blind = fetch(10, slice_hours=24, read=fake)
    check("a window narrower than the slice is read whole", len(rows) == 10 and not blind,
          f"{len(rows)} rows, blind={blind}")

    rows, blind = fetch(100, slice_hours=24, read=fake)
    check("slices tile the window with no row twice", len(rows) == 100, len(rows))

    # A page that always fills: every split still fills, so every hour is blind.
    def saturated(since, before, filters):
        return [{"ts": f"x{i}-{since}-{before}", "from_seat": "x", "subject": "s"}
                for i in range(LIMIT)]

    rows, blind = fetch(4, slice_hours=4, read=saturated)
    check("a window that cannot be split small enough is reported, not believed",
          len(blind) == 4 and all(b["since_hours"] - b["before_hours"] == 1 for b in blind),
          f"blind={blind}")

    # One fat hour inside an otherwise quiet window: split finds it, keeps the rest.
    def one_fat_hour(since, before, filters):
        if before <= 5 < since:
            if since - before > 1:
                return [{"ts": "fat", "from_seat": "x", "subject": "s"}] * LIMIT
            return [{"ts": f"f{i}", "from_seat": "x", "subject": "s"} for i in range(LIMIT)]
        return [{"ts": f"q{h}", "from_seat": "x", "subject": "s"}
                for h in range(before, since)]

    rows, blind = fetch(24, slice_hours=24, read=one_fat_hour)
    check("the split isolates the fat hour and keeps the quiet ones",
          len(blind) == 1 and blind[0]["since_hours"] - blind[0]["before_hours"] == 1,
          f"blind={blind}")
    check("rows come back newest first", rows == sorted(rows, key=lambda m: m["ts"],
                                                        reverse=True))
    print("all verdicts agree" if not fail else "self-test FAILED")
    return fail


if __name__ == "__main__":
    argv = sys.argv[1:]
    if "--self-test" in argv:
        sys.exit(self_test())
    hours = int(argv[argv.index("--hours") + 1]) if "--hours" in argv else 72
    f = {}
    for name, key in (("--from-seat", "from_seat"), ("--from-company", "from_company"),
                      ("--to-seat", "to_seat"), ("--kind", "kind")):
        if name in argv:
            f[key] = argv[argv.index(name) + 1]
    try:
        rows, blind = fetch(hours, f)
    except (RuntimeError, urllib.error.URLError, OSError, ValueError) as e:
        print(f"could not look: {e}")
        sys.exit(2)
    print(f"{len(rows)} row(s) over {hours}h, filters {f or 'none'}")
    if rows:
        print(f"oldest {rows[-1].get('ts')}   newest {rows[0].get('ts')}")
    if blind:
        print(f"windows read only in part: {blind}")
    sys.exit(1 if blind else 0)
