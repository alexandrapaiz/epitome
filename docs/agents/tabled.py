#!/usr/bin/env python3
"""Does the pull request an ask points at carry the file the ask tabled? (L90.)

  python3 docs/agents/tabled.py                audit this seat's asks in a window
  python3 docs/agents/tabled.py --hours 400    a wider window
  python3 docs/agents/tabled.py --pr 357       one pull request, every ask naming it
  python3 docs/agents/tabled.py --self-test    fire every verdict on built input

WHY THIS EXISTS. `docs/standards/pm.md` section 22 says an ask has to *carry*
its change -- "an open pull request against the file the clock releases ... and
not a proposal parked in a side folder" -- and its 2026-10-24 paragraph names
the check: `gh pr diff --name-only` against the tabled list. That check is
written for the applier, at the hour a clock expires. Nothing runs it when the
ask is filed, and nothing runs it again when the named pull request merges.

On 2026-10-27T00:58:29Z this seat asked `epitome/pm` for forty-eight hours on
one clause of its own charter, tabling `prompts/exo-agent.md` and naming
`357`. `357` merged at 05:08:49Z carrying four files, none of them under
`prompts/`. So the ask was answered by a merge that landed none of what it
tabled, the clause L84 requires at `prompts/exo-agent.md:91` is still unwritten
six days later, and the charter still orders a row in a file the same pull
request closed. Nothing reported anything: the ask is satisfied-looking from
the board, the merge is clean from the forge, and the gap exists only in the
join nobody computed.

FOUR VERDICTS AND NEVER TWO (L41). 0 every tabled file is carried by its ref.
1 a tabled file is missing from the ref -- and a missing file on a *merged* ref
is named LOST rather than NOT CARRIED, because those are two different acts
owed: one is a push, the other is a new ask on a new pull request. 2 could not
look -- no `gh`, no board, or a window with no ask in it, which is a floor and
not a clean bill (L77). 3 the ref carries a file the ask never tabled, which is
section 22's own retarget-or-split case: silence would release more than it was
shown.

The direction of this instrument's error, stated because no reader can infer
it: it reads the tabled list out of `data.files`, so an ask that tabled its
files in prose alone reads as UNTABLED and not as clean (L-A9's fail-closed
direction). An ask with no `data.files` is counted in its own class and never
in the carried one.
"""
import json
import os
import subprocess
import sys
import urllib.error
import urllib.request

PR_KEYS = ("pr", "pull_request", "pull_request_number", "pr_number")


def fetch_asks(hours):
    """Every ask this seat sent in the window, newest first, with blind windows.

    Paged through docs/agents/board.py, because one page of the board reaches
    about six days back and an ask older than the page reads as an ask that was
    never filed (L86)."""
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import board
    seat = os.environ.get("SEAT", "exo")
    company = os.environ.get("COMPANY", "epitome")
    return board.fetch(hours, {"from_seat": seat, "from_company": company})


def pr_facts(number):
    """(files, state, merged_at) for a pull request. Raises when gh cannot answer."""
    out = subprocess.run(
        ["gh", "pr", "view", str(number), "--json", "files,state,mergedAt"],
        capture_output=True, text=True, timeout=120)
    if out.returncode != 0:
        raise RuntimeError(f"gh could not read #{number}: "
                           f"{out.stderr.strip()[:120]}")
    j = json.loads(out.stdout)
    return ({f["path"] for f in j.get("files") or []},
            j.get("state", "UNKNOWN"), j.get("mergedAt"))


def ref_of(data):
    for k in PR_KEYS:
        v = data.get(k)
        if isinstance(v, int):
            return v
        if isinstance(v, str) and v.strip().lstrip("#").isdigit():
            return int(v.strip().lstrip("#"))
    return None


def tabled_of(data):
    v = data.get("files")
    if isinstance(v, list) and all(isinstance(x, str) for x in v):
        return set(v)
    if isinstance(data.get("file"), str):
        return {data["file"]}
    return None


def report(asks, blind, only_pr=None, facts=pr_facts):
    rows, cls = [], {"carried": 0, "not_carried": 0, "lost": 0,
                     "exceeds": 0, "untabled": 0, "unreadable": 0}
    for m in asks:
        if m.get("kind") != "ask":
            continue
        data = m.get("data") or {}
        ref = ref_of(data)
        if ref is None or (only_pr is not None and ref != only_pr):
            continue
        tabled = tabled_of(data)
        row = {"ts": m.get("ts"), "ref": ref, "subject": m.get("subject"),
               "to": f"{m.get('to_company')}/{m.get('to_seat')}"}
        if tabled is None:
            row["verdict"] = "UNTABLED"
            row["why"] = ("the ask names a pull request and tables no file list, "
                          "so nothing can check what its silence would release")
            cls["untabled"] += 1
            rows.append(row)
            continue
        try:
            carried, state, merged = facts(ref)
        except Exception as e:  # a ref this clone cannot read is its own class
            row["verdict"] = "COULD NOT LOOK"
            row["why"] = str(e)
            cls["unreadable"] += 1
            rows.append(row)
            continue
        missing = sorted(tabled - carried)
        extra = sorted(carried - tabled)
        row.update(tabled=sorted(tabled), carried=sorted(carried),
                   missing=missing, extra=extra, state=state, merged_at=merged)
        if missing and state == "MERGED":
            row["verdict"] = "LOST"
            row["why"] = ("the ref merged without the tabled file, so the clock is "
                          "gone and the change is unwritten — the act owed is a new "
                          "pull request carrying it and a new ask")
            cls["lost"] += 1
        elif missing:
            row["verdict"] = "NOT CARRIED"
            row["why"] = ("the ref is open and does not carry the tabled file — the "
                          "act owed is a push to that branch, before the clock fires")
            cls["not_carried"] += 1
        elif extra:
            row["verdict"] = "EXCEEDS"
            row["why"] = ("the ref carries a file the ask never tabled; silence "
                          "releases only the tabled list (section 22), so retarget, "
                          "split, or re-ask with the true list")
            cls["exceeds"] += 1
        else:
            row["verdict"] = "CARRIED"
            cls["carried"] += 1
        rows.append(row)

    print(f"asks naming a pull request: {len(rows)}"
          + (f"   filtered to #{only_pr}" if only_pr else ""))
    for r in rows:
        print(f"  {r['verdict']:<14} #{r['ref']}  {r['ts']}  -> {r['to']}")
        print(f"    {str(r.get('subject'))[:96]}")
        if r.get("missing"):
            print(f"    tabled and NOT carried: {', '.join(r['missing'])}"
                  f"   (ref {r.get('state')})")
        if r.get("extra"):
            print(f"    carried and never tabled: {', '.join(r['extra'])}")
        print(f"    {r['why']}" if r.get("why") else "")

    if not rows:
        print("no ask in this window names a pull request: that is a floor, not a "
              "clean bill (L41, L77) — widen --hours before reading it as clean")
        rc = 2
    elif cls["lost"] or cls["not_carried"]:
        rc = 1
    elif cls["exceeds"]:
        rc = 3
    elif cls["unreadable"] or cls["untabled"] or blind:
        rc = 2
    else:
        rc = 0

    print("\n```data")
    print("instrument: docs/agents/tabled.py")
    print(f"asks_naming_a_pull_request: {len(rows)}")
    print(f"windows_read_only_in_part: {len(blind)}")
    for k in ("carried", "not_carried", "lost", "exceeds", "untabled", "unreadable"):
        print(f"{k}: {cls[k]}")
    print(f"tabled_list_read_from: data.files (prose tables read as UNTABLED)")
    print(f"exit: {rc}")
    print("```")
    return rc


def self_test():
    """Every verdict on built input, including the real positive of 2026-10-27."""
    fixture_files = {
        357: ({"docs/agents/incidents.md", "docs/agents/lessons.md",
               "docs/agents/loop.md", "docs/agents/roster.sh"}, "MERGED",
              "2026-10-27T05:08:49Z"),
        312: ({"prompts/exo-agent.md"}, "OPEN", None),
        400: ({"docs/agents/lessons.md"}, "OPEN", None),
        401: ({"a.md", "b.md"}, "OPEN", None),
    }

    def facts(n):
        if n not in fixture_files:
            raise RuntimeError("no such pull request in the fixture")
        return fixture_files[n]

    def ask(ref, files=None, extra=None):
        d = {"pr": ref}
        if files is not None:
            d["files"] = files
        if extra:
            d.update(extra)
        return {"kind": "ask", "ts": "2026-10-27T00:58:29Z", "subject": "built",
                "to_company": "epitome", "to_seat": "pm", "data": d}

    fail = 0

    def check(label, asks, want, only_pr=None):
        nonlocal fail
        import io
        buf, old = io.StringIO(), sys.stdout
        sys.stdout = buf
        try:
            got = report(asks, (), only_pr, facts)
        finally:
            sys.stdout = old
        if got == want:
            print(f"  ok    {label:<58} exit {got}")
        else:
            print(f"  FAIL  {label:<58} want {want} got {got}")
            print("\n".join("        " + l for l in buf.getvalue().splitlines()))
            fail = 1
        return buf.getvalue()

    out = check("the real positive: 357 tabled a charter it never carried",
                [ask(357, ["prompts/exo-agent.md"])], 1)
    assert "LOST" in out, out
    assert "prompts/exo-agent.md" in out, out
    check("an open ref missing a tabled file is a push, not a loss",
          [ask(312, ["prompts/exo-agent.md", "docs/agents/lessons.md"])], 1)
    check("a ref carrying exactly its tabled list is clean",
          [ask(312, ["prompts/exo-agent.md"])], 0)
    check("a ref carrying a file nobody tabled is section 22's split case",
          [ask(401, ["a.md"])], 3)
    check("an ask that tables nothing is not counted as carried",
          [ask(400)], 2)
    check("a ref this clone cannot read is its own class",
          [ask(999, ["x.md"])], 2)
    check("an empty window is a floor and not a clean bill", [], 2)
    check("a non-ask in the window is not judged",
          [{"kind": "note", "data": {"pr": 357, "files": ["prompts/exo-agent.md"]}}], 2)
    check("the single-file spelling `file` tables as well as `files`",
          [ask(312, None, {"file": "prompts/exo-agent.md"})], 0)
    check("--pr filters to one ref and keeps the floor honest",
          [ask(357, ["prompts/exo-agent.md"]), ask(312, ["prompts/exo-agent.md"])],
          0, only_pr=312)
    print("all verdicts agree" if not fail else "self-test FAILED")
    return fail


def main(argv):
    if "--self-test" in argv:
        return self_test()
    hours, only_pr = 400, None
    if "--hours" in argv:
        hours = int(argv[argv.index("--hours") + 1])
    if "--pr" in argv:
        only_pr = int(argv[argv.index("--pr") + 1].lstrip("#"))
    try:
        asks, blind = fetch_asks(hours)
    except (RuntimeError, urllib.error.URLError, OSError, ValueError) as e:
        print(f"could not look: {e}")
        return 2
    return report(asks, blind, only_pr)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
