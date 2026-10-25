# Helper for `reread.sh --inbox`. Kept as a file rather than a heredoc because
# a heredoc inside a heredoc is how this edit failed the first time.
#
#   python3 docs/agents/inbox-numbers.py PAGE.json
#   python3 docs/agents/inbox-numbers.py --self-test
#
# Two outputs, and they go to different streams on purpose. stdout is the set
# of pull request numbers this seat's inbox disposes of, for reread.sh to read
# back. stderr is the sender-side finding of L58: every message that named a
# pull request in `ref` or `data` and in no sentence of its body, which is the
# half the writer can fix and cannot see.
#
# THE READ UNIT, which this file got wrong once before it got it right. The
# first version scanned `json.dumps(data)` for any three- or four-digit run.
# Against the real page that returned #368 and #518 from
# `{"board_store_line": 518, "exhausted_cost_usd": 368.01}`, #4240 from a
# message id, and #9951 from a timestamp — ten numbers that are not pull
# requests, each of which `gh` then answered "could not look" about. That is
# L58's own defect committed by L58's own instrument: a probe reporting about
# its own reach. A number is a pull request here only when the key carrying it
# claims to carry one — either because its name contains `pr` or `pull`, or
# because it is on the short list below of keys this board has actually been
# observed using for pull requests. An unclaimed key is never guessed, and the
# count of numbers refused for that reason is printed, so an allowlist going
# stale is a visible number rather than a silent miss (L41's third answer).
#
# AND A NUMBER IS NOT AN ADDRESS ACROSS REPOSITORIES. Five companies share
# this board and each has its own queue, so `{"pr": 417}` from
# `alexandra-systems/exo-centralizer` is HQ's 417 and `gh pr view 417` here
# answers about whatever this repository's 417 happens to be, or nothing. That
# is L-A56's third clause and incident 21's shape. The board already says
# which queue when it knows: `{"source_pr": {"epitome": 294},
# "local_evidence_pr": {"alexandra-systems": 434}}`. So a dict under a
# pull-request key is read as company-to-number and only this company's entry
# is taken; a bare number is attributed to the sender's own company and
# refused by name when that is not this one.
import json, re, sys

MINE = "epitome"  # set from read_page; the queue this checkout can read

KEY = re.compile(r"(^|_)(pr|prs|pull|pulls|pull_request|pull_requests)(_|$)|pr$|^pr")
# Observed on this board, 2026-10-24 and 2026-10-25, carrying pull requests
# under a name that does not say "pr". Add by observation, never by guess.
NAMED = {"swept", "declined", "merged", "closed_unmerged", "merge_sequence",
         "folded", "links_in_a_chain", "doors_by_base", "needs_a_hand",
         "drafts_no_gate", "held_on_review"}
REFUSED = []    # (key, numbers) a key nothing claimed; printed, never counted in
ELSEWHERE = []  # (company, numbers) another company's queue; printed, never looked up


def claims(key):
    k = key.lower()
    return bool(KEY.search(k)) or k in NAMED


def _ints(v):
    if isinstance(v, bool):
        return []
    if isinstance(v, int):
        return [v]
    if isinstance(v, str) and v.isdigit():
        return [int(v)]
    if isinstance(v, list):
        return [n for x in v for n in _ints(x)]
    if isinstance(v, dict):
        out = [int(k) for k in v if isinstance(k, str) and k.isdigit()]
        for x in v.values():
            out += _ints(x)
        return out
    return []


def _by_company(v):
    """A dict under a pull-request key is company-to-number, when its keys are
    names rather than numbers. Returns {company: {numbers}} or None."""
    if not isinstance(v, dict) or not v:
        return None
    if any(isinstance(k, str) and k.isdigit() for k in v):
        return None
    return {k: {n for n in _ints(x) if 1 <= n <= 99999} for k, x in v.items()}


def from_data(obj, company):
    """Numbers under a key that says it carries pull requests, scoped to the
    queue this checkout can actually read, and no others."""
    found = set()
    if isinstance(obj, dict):
        for k, v in obj.items():
            if isinstance(k, str) and claims(k):
                scoped = _by_company(v)
                if scoped is not None:
                    for co, ns in scoped.items():
                        if co == MINE:
                            found |= ns
                        elif ns:
                            ELSEWHERE.append((co, sorted(ns)))
                    continue
                ns = {n for n in _ints(v) if 1 <= n <= 99999}
                if ns:
                    (found.__ior__(ns) if company == MINE else
                     ELSEWHERE.append((company, sorted(ns))))
            else:
                loose = [n for n in _ints(v) if 100 <= n <= 9999]
                if loose and isinstance(k, str):
                    REFUSED.append((k, sorted(set(loose))))
            found |= from_data(v, company)
    elif isinstance(obj, list):
        for x in obj:
            found |= from_data(x, company)
    return found


def from_ref(ref, repo):
    """A ref carries owner/repo, so it says which queue outright."""
    found = set()
    for owner, name, n in re.findall(r"github\.com/([^/]+)/([^/]+)/pull/(\d+)", ref or ""):
        if repo is None or name.lower() == repo.lower():
            found.add(int(n))
        else:
            ELSEWHERE.append(("%s/%s" % (owner, name), [int(n)]))
    return found


def read_page(path, company=None, repo=None):
    global MINE
    MINE = company if company is not None else MINE
    doc = json.load(open(path))
    if "messages" not in doc:
        raise KeyError("the route answered without a messages key")
    nums, silent = set(), []
    for m in doc["messages"]:
        body = m.get("body") or ""
        in_body = {int(n) for n in re.findall(r"#(\d{2,})", body)}
        machine = (from_ref(m.get("ref"), repo)
                   | from_data(m.get("data"), m.get("from_company") or ""))
        nums |= in_body | machine
        only_machine = machine - in_body
        if only_machine:
            silent.append((m.get("ts"),
                           "%s/%s" % (m.get("from_company") or "", m.get("from_seat") or ""),
                           sorted(only_machine),
                           (m.get("subject") or "")[:58]))
    return nums, silent


# L42: every branch built here, including the ten false positives the first
# version produced, taken verbatim from the 2026-10-25T02:3xZ page.
def selftest():
    fail = 0

    def check(name, got, want):
        nonlocal fail
        if got == want:
            print("  ok   %s" % name)
        else:
            print("  FAIL %s: got %r wanted %r" % (name, got, want))
            fail = 1

    global MINE
    MINE = "epitome"
    me, them = "epitome", "alexandra-systems"
    check("a ref names the pull request and its repository",
          from_ref("https://github.com/alexandrapaiz/epitome/pull/305", "epitome"), {305})
    check("a ref into another repository is somebody else's queue",
          (from_ref("https://github.com/x/alexandria/pull/9", "epitome"),
           [c for c, _ in ELSEWHERE if c == "x/alexandria"]), (set(), ["x/alexandria"]))
    check("no ref names nothing", from_ref(None, "epitome"), set())
    check("data.pr from this company", from_data({"pr": 305}, me), {305})
    check("data.pr from another company is not looked up here",
          (from_data({"pr": 417}, them), [n for c, ns in ELSEWHERE if c == them for n in ns]),
          (set(), [417]))
    check("a company-to-number dict takes only this company's entry",
          from_data({"source_pr": {"epitome": 294}, "local_evidence_pr": {"alexandra-systems": 434}}, them),
          {294})
    check("data.swept, a list under a pr-ish key",
          from_data({"swept": [305, 304, 300], "linear": "skipped_no_key"}, me), {305, 304, 300})
    check("declined, whose keys are the numbers, is a named carrier",
          from_data({"declined": {"291": "x", "292": "y"}}, me), {291, 292})
    check("a key nothing claims yields nothing, and is recorded as refused",
          (from_data({"board_store_line": 518}, me),
           [k for k, _ in REFUSED if k == "board_store_line"]), (set(), ["board_store_line"]))
    check("charter_pr and register_pr", from_data({"charter_pr": 304, "register_pr": 305}, me), {304, 305})
    check("backlog_card_added_on_pr", from_data({"backlog_card_added_on_pr": 295}, me), {295})
    check("a store line and a dollar figure are not pull requests",
          from_data({"board_store_line": 518, "exhausted_cost_usd": 368.01}, me), set())
    check("a message id is not a pull request",
          from_data({"source_ref": "6f1c8095-aa19-4240-b052-76910ef9b3f6"}, me), set())
    check("a year in data is not a pull request", from_data({"since": "2026-10-24"}, me), set())
    check("prs, nested", from_data({"a": {"prs": ["271", 274]}}, me), {271, 274})

    page = {"messages": [
        {"ts": "t1", "from_company": "epitome", "from_seat": "pm", "subject": "s",
         "ref": "https://github.com/alexandrapaiz/epitome/pull/305", "data": {"pr": 305},
         "body": "I am declining to merge your open register pull request."},
        {"ts": "t2", "from_company": "epitome", "from_seat": "pm", "subject": "s",
         "ref": None, "data": {"swept": [291]}, "body": "I swept #291 and said so."},
    ]}
    import tempfile, os
    fd, p = tempfile.mkstemp(suffix=".json")
    os.write(fd, json.dumps(page).encode())
    os.close(fd)
    nums, silent = read_page(p, "epitome", "epitome")
    os.unlink(p)
    check("both messages' numbers recovered", nums, {305, 291})
    check("only the one whose prose dropped the number is flagged",
          [(s[0], s[2]) for s in silent], [("t1", [305])])
    print("self-test: all verdicts fired" if not fail else "self-test FAILED")
    return fail


if __name__ == "__main__":
    if sys.argv[1:2] == ["--self-test"]:
        sys.exit(selftest())
    try:
        import os
        nums, silent = read_page(sys.argv[1],
                                 os.environ.get("COMPANY", "epitome"),
                                 os.environ.get("REPO", "epitome"))
    except Exception as e:
        print("  could not look: the board's answer did not read: %s" % e, file=sys.stderr)
        sys.exit(2)
    if ELSEWHERE:
        agg = {}
        for c, ns in ELSEWHERE:
            agg.setdefault(c, set()).update(ns)
        print("  another queue, named and not looked up here (L-A56): %s"
              % "; ".join("%s #%s" % (c, ",#".join(str(n) for n in sorted(v)))
                          for c, v in sorted(agg.items())), file=sys.stderr)
    if REFUSED:
        seen = sorted({k for k, _ in REFUSED})
        print("  refused %d value(s) under %d key(s) no name claims as pull requests: %s"
              % (sum(len(v) for _, v in REFUSED), len(seen), ", ".join(seen)), file=sys.stderr)
    if silent:
        print("  NAMED IN A FIELD AND IN NO SENTENCE (L58, sender half): %d message(s)" % len(silent),
              file=sys.stderr)
        for ts, who, ns, subj in silent:
            print("    %s %-24s #%s  %s" % (ts, who, ",#".join(str(n) for n in ns), subj),
                  file=sys.stderr)
    print(" ".join(str(n) for n in sorted(nums)))
