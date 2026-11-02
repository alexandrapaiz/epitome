#!/usr/bin/env python3
"""Which open items need a release path, and on whose written ground is each held? (L91.)

  python3 docs/agents/grounds.py              the queue's owner-reserved items
  python3 docs/agents/grounds.py --hours 600  a wider window of asks
  python3 docs/agents/grounds.py --self-test  fire every verdict on built input

WHY THIS EXISTS. `docs/standards/pm.md` section 21 lets the project manager or
any chair merge anything that meets the tiers, and section 22 converts the
owner's silence into consent for the few surfaces a charter reserves to her.
Both rules decide a single item, so every instrument this company has reads
one item at a time: `docs/agents/clocks.sh N` answers about #N, and this
seat's own census counts clocks claimed against clocks carried. Nothing reads
the join -- which open items are on a reserved surface at all, and which of
those have no live hand to release them.

That join is what a *correction to a ground* needs. On 2026-11-01T23:31:59Z
`epitome/pm` held three charter branches on the written ground that "no
silence clock applies to a charter". Ten minutes later, at 23:41:44Z, the same
seat corrected that reading -- section 22 lists editing a charter among the
things that proceed on silence -- and started a clock on two of the three. The
third was its own, #304, and it is the one no second reader was ever going to
raise: eight days open, its clock expired 2026-10-28T05:30Z, `silence_proceeds:
false` still in its own ask's data on the refuted ground. A reading was
corrected and the item the old reading had already decided stayed decided.

FOUR VERDICTS AND NEVER TWO (L41). 0 every reserved item has a live release
path. 1 a reserved item has none, and the line names the written ground and
the seat whose hand filed it -- that hand re-reads it, because nobody else
will. 2 could not look: no `gh`, no board, or no reserved item in the queue,
which is a floor and not a clean bill (L77). 3 a reserved item has a path that
is live but incomplete -- a clock with no applier named -- because a release
with nobody authorised to apply it is section 22's own named failure and it is
not the same thing as no clock at all.

The direction of this instrument's error, stated because no reader can infer
it: the reserved surface is a path list, so a reserved file this list does not
name reads as ordinary and NOT as reserved. It is built to under-report
holding, which is the direction that costs a reading rather than a branch; the
list is at RESERVED below and it is this file's own declaration, not a parse of
the standard.
"""
import json
import os
import subprocess
import sys
import urllib.error
import urllib.request

# The surfaces a charter reserves to the owner in this product. Everything else
# is an ordinary section 21 merge and needs no clock whatever.
RESERVED = ("prompts/", "docs/standards/", ".github/workflows/", "docs/decisions.md")
PR_KEYS = ("pr", "pull_request", "pull_request_number", "pr_number")


def board_asks(hours):
    """Every message in the window, walked in slices, with the blind windows.

    One page does not reach: 500 rows at `since_hours=600` stop six days back,
    and an item whose asks are older than the page reads as an item nobody
    asked about — which is this instrument's worst possible wrong answer. So it
    pages (docs/agents/board.py) and carries the part it could not see."""
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import board
    return board.fetch(hours)


def open_prs():
    out = subprocess.run(["gh", "pr", "list", "--state", "open", "--limit", "100",
                          "--json", "number,title,files,createdAt,author"],
                         capture_output=True, text=True, timeout=180)
    if out.returncode != 0:
        raise RuntimeError(f"gh could not list the queue: {out.stderr.strip()[:120]}")
    return json.loads(out.stdout)


def ref_of(data):
    for k in PR_KEYS:
        v = data.get(k)
        if isinstance(v, int):
            return v
        if isinstance(v, str) and v.strip().lstrip("#").isdigit():
            return int(v.strip().lstrip("#"))
    return None


def reserved_paths(files):
    return sorted(p for p in files if any(p.startswith(r) for r in RESERVED))


def judge(pr, msgs, now, blind=()):
    """One reserved item: its live path, or the ground that holds it."""
    clock, applier, refusal, expired = None, None, None, None
    for m in msgs:
        data = m.get("data") or {}
        if ref_of(data) != pr["number"]:
            continue
        who = f"{m.get('from_company')}/{m.get('from_seat')}"
        if data.get("silence_proceeds") is False:
            refusal = (who, m.get("ts"), "its own ask declares silence releases nothing")
        hour = m.get("expires_at") or data.get("deadline")
        if not hour:
            continue
        hour = str(hour).replace("+00:00", "Z")
        if hour > now:
            if clock is None or hour > clock[0]:
                clock = (hour, who, m.get("ts"))
            if data.get("applier"):
                applier = data["applier"]
        elif expired is None or hour > expired[0]:
            expired = (hour, who, m.get("ts"))
    if clock and refusal:
        # L85: a clock filed over a declared refusal manufactures consent. The
        # refusal is the older act and it is the one that decides.
        return ("HELD", f"a clock to {clock[0]} sits over a declared refusal by "
                        f"{refusal[0]} ({refusal[2]}) — one of the two is wrong, and "
                        f"the hand that re-reads it is {refusal[0]}'s", refusal[0])
    if clock and not applier:
        return ("NO APPLIER", f"clock to {clock[0]} filed by {clock[1]}, and no ask "
                              f"names who applies it at the hour", clock[1])
    if clock:
        return ("LIVE", f"clock to {clock[0]}, applier {applier}, filed by {clock[1]}",
                applier)
    if refusal:
        return ("HELD", f"{refusal[2]}, filed by {refusal[0]} at {refusal[1]} — that "
                        f"hand re-reads it, because no other seat will", refusal[0])
    if expired:
        return ("HELD", f"its only clock expired {expired[0]} (filed by {expired[1]}) "
                        f"and nothing replaced it", expired[1])
    if blind:
        # The one answer this instrument may not give from a partial window:
        # "nobody asked" is indistinguishable from "the ask is older than my
        # page", and only one of those is a finding (L86, L41).
        return ("COULD NOT LOOK", f"no ask in the window names this item, and "
                f"{len(blind)} window(s) came back in part, so silence here is "
                f"this reader's and not the board's", None)
    return ("HELD", "no ask on the board names this item at all, so no hand is "
                    "authorised to release it", None)


def report(prs, msgs, now, blind=()):
    rows = []
    for pr in prs:
        files = [f["path"] for f in pr.get("files") or []]
        res = reserved_paths(files)
        if not res:
            continue
        verdict, why, hand = judge(pr, msgs, now, blind)
        rows.append({"pr": pr["number"], "verdict": verdict, "why": why,
                     "hand": hand, "reserved": res, "age_from": pr.get("createdAt"),
                     "title": pr.get("title", "")})
    print(f"open items on an owner-reserved surface: {len(rows)}   "
          f"(queue of {len(prs)}, reserved list {', '.join(RESERVED)})")
    for r in sorted(rows, key=lambda r: r["age_from"] or ""):
        print(f"  {r['verdict']:<11} #{r['pr']}  opened {r['age_from']}  "
              f"{', '.join(r['reserved'])}")
        print(f"    {r['title'][:94]}")
        print(f"    {r['why']}")
    blind_rows = [r for r in rows if r["verdict"] == "COULD NOT LOOK"]
    held = [r for r in rows if r["verdict"] == "HELD"]
    noapp = [r for r in rows if r["verdict"] == "NO APPLIER"]
    if not rows:
        print("no open item touches a reserved surface: a floor, not a clean bill (L77)")
        rc = 2
    elif held:
        rc = 1
    elif noapp:
        rc = 3
    elif blind_rows:
        rc = 2
    else:
        rc = 0
    print("\n```data")
    print("instrument: docs/agents/grounds.py")
    print(f"read_at: {now}")
    print(f"queue_open: {len(prs)}")
    print(f"reserved_items: {len(rows)}")
    print(f"live_release_path: {len([r for r in rows if r['verdict'] == 'LIVE'])}")
    print(f"held_with_no_path: {len(held)}")
    print(f"clock_with_no_applier: {len(noapp)}")
    print(f"could_not_look: {len(blind_rows)}")
    print(f"windows_read_only_in_part: {len(blind)}")
    print(f"held_items: {[r['pr'] for r in held]}")
    print(f"hands_that_must_re_read: "
          f"{sorted({r['hand'] for r in held if r['hand']})}")
    print(f"exit: {rc}")
    print("```")
    return rc


def self_test():
    now = "2026-11-02T00:30:00Z"

    def pr(n, paths, created="2026-10-24T22:00:00Z"):
        return {"number": n, "title": "built", "createdAt": created,
                "files": [{"path": p} for p in paths]}

    def msg(n, who="epitome/pm", **data):
        c, s = who.split("/")
        return {"from_company": c, "from_seat": s, "ts": "2026-10-26T05:10:06Z",
                "kind": "ask", "data": dict(pr=n, **data)}

    fail = 0

    def check(label, prs, msgs, want):
        nonlocal fail
        import io
        buf, old = io.StringIO(), sys.stdout
        sys.stdout = buf
        try:
            got = report(prs, msgs, now)
        finally:
            sys.stdout = old
        if got == want:
            print(f"  ok    {label:<60} exit {got}")
        else:
            print(f"  FAIL  {label:<60} want {want} got {got}")
            print("\n".join("        " + l for l in buf.getvalue().splitlines()))
            fail = 1
        return buf.getvalue()

    check("an ordinary queue has no reserved item and says so",
          [pr(1, ["docs/agents/lessons.md"])], [], 2)
    out = check("the real positive: 304, expired clock over a declared refusal",
                [pr(304, ["prompts/pm-agent.md"])],
                [msg(304, deadline="2026-10-28T05:30:00Z"),
                 msg(304, silence_proceeds=False)], 1)
    assert "epitome/pm" in out and "re-reads" in out, out
    check("a live clock with an applier is the one clean state",
          [pr(300, ["prompts/exo-agent.md"])],
          [msg(300, who="epitome/exo", deadline="2026-11-03T23:30:00Z",
               applier="epitome/pm")], 0)
    check("a live clock naming no applier is its own verdict",
          [pr(300, ["prompts/exo-agent.md"])],
          [msg(300, who="epitome/exo", deadline="2026-11-03T23:30:00Z")], 3)
    check("a reserved item no ask names at all is held, with no hand to name",
          [pr(363, ["docs/standards/pm.md"])], [], 1)
    check("a clock filed over a declared refusal is held, not live (L85)",
          [pr(304, ["prompts/pm-agent.md"])],
          [msg(304, silence_proceeds=False),
           msg(304, who="epitome/exo", deadline="2026-11-03T23:30:00Z",
               applier="epitome/pm")], 1)
    check("a workflow file is reserved as well as a charter",
          [pr(9, [".github/workflows/seat.yml"])], [], 1)
    check("an ask about another pull request does not release this one",
          [pr(300, ["prompts/exo-agent.md"])],
          [msg(312, who="epitome/exo", deadline="2026-11-03T23:30:00Z",
               applier="epitome/pm")], 1)
    print("all verdicts agree" if not fail else "self-test FAILED")
    return fail


def main(argv):
    if "--self-test" in argv:
        return self_test()
    hours = 600
    if "--hours" in argv:
        hours = int(argv[argv.index("--hours") + 1])
    import datetime
    now = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    try:
        prs = open_prs()
        msgs, blind = board_asks(hours)
    except (RuntimeError, urllib.error.URLError, OSError, ValueError) as e:
        print(f"could not look: {e}")
        return 2
    return report(prs, msgs, now, blind)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
