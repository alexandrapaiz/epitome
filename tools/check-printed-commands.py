#!/usr/bin/env python3
# A command printed in a document is read by people and run by nothing.
#
#   python3 tools/check-printed-commands.py             scan; 1 if anything is stale
#   python3 tools/check-printed-commands.py --census    the population, scan nothing
#   python3 tools/check-printed-commands.py --self-test the verdicts, on built input
#   python3 tools/check-printed-commands.py --gate      both, with a tally a suite reads
#
# Exit 0 nothing stale, 1 at least one finding, 2 could not look (L41).
#
# WHY THIS EXISTS. `tools/secret-print-baseline.txt` printed the credential
# scan's invocation in its header, directly under the sentence "it exits 0
# today". A seat copied that line on 2026-11-02 and got 40 findings and exit 1,
# because the printed command omitted `--baseline`; with the flag added it
# still exited 1, because the printed glob list had never covered two of the
# surfaces. Two independent errors in the one line a CI gate was going to be
# written from, and nothing in this repository could have noticed either.
#
# That instance was fixed by moving the invocation into `tools/
# scan-secret-print.sh` and having a test run the file. This is the general
# case, which `docs/backlog.md` named and did not build: `git ls-files '*.md'`
# carries twenty-odd invocations of this repository's own scripts, with flags,
# and **no way to tell which of them are still true.** A seat copies one and
# finds out.
#
# WHAT THIS DECIDES, AND WHAT IT DOES NOT. Three facts about a printed command
# are decidable without running it, and all three are how these go stale:
#
#   1. the script it names is in this checkout at all
#   2. the interpreter it is run with is the one the script's shebang names
#   3. the flag it passes is one the script actually dispatches on
#
# Whether the *output* a document claims is still the output is not decidable
# here, and this does not pretend to decide it. That stays the per-document
# pass `docs/backlog.md` asks for. What this closes is the cheaper half: a
# command that would be refused by the script it names cannot have produced the
# block under it, whatever that block says.
#
# WHY A DOCUMENT UNDER docs/standards/ IS NOT SCANNED. Those files are vendored
# from HQ (`.claude/README.md`), and the tools they print — `tools/autonomy.py`,
# `tools/check-run-ran.py`, `tools/next-rule-id.py` — live in HQ's tree, not
# this one. Scanning them here reports three findings that are true of this
# checkout and false of the document, which is worse than not looking. The
# census prints the count it skipped, so the exclusion is visible rather than
# quiet.
#
# WHY AN UNDECIDABLE FLAG IS NOT A FINDING. Reading a dispatcher out of shell
# is a heuristic, and a gate that accuses wrongly is a gate somebody turns off.
# So a script this reader cannot find ANY dispatched flag in is reported as
# undecidable, by name, and never as stale: zero accepted flags is this
# reader's failure, not the document's. Those counts are in the census too.

import os
import re
import subprocess
import sys
import tempfile
import shutil

# Where this repository's own runnable things live. A path outside these is
# somebody else's tree — `/srv/asc/hq/tools/capacity-retry.py` is quoted in a
# register here and is not ours to check.
OURS = ("docs/agents/", "tools/", "cli/", "deploy/", "scripts/")

# Vendored from HQ: the document's subject is HQ's checkout. See the header.
VENDORED = ("docs/standards/",)

INTERPRETERS = ("bash", "sh", "python3", "python", "node")

# `bash docs/agents/caps.sh --days 2` — the interpreter, the script, the rest.
# The tail stops at a backtick, pipe, closing paren or quote, because these
# lines are written inside markdown spans and fenced blocks.
INVOCATION = re.compile(
    r"\b(" + "|".join(INTERPRETERS) + r")\s+"
    r"((?:\./|/)?(?:[A-Za-z0-9_.\-]+/)+[A-Za-z0-9_.\-]+\.(?:sh|bash|py|mjs|js))"
    r"((?:[ \t]+(?:--?[A-Za-z0-9][A-Za-z0-9_-]*|[^\s`|)'\"<>]+))*)"
)

SHEBANG_FAMILY = {
    "bash": "sh", "sh": "sh", "zsh": "sh",
    "python3": "py", "python": "py",
    "node": "js",
}
EXT_FAMILY = {
    ".sh": "sh", ".bash": "sh",
    ".py": "py",
    ".mjs": "js", ".js": "js",
}


def could_not_look(rule, fix):
    print(f"could not look: {rule}\nFix: {fix}", file=sys.stderr)
    sys.exit(2)


def tracked(root, pattern):
    out = subprocess.run(["git", "-C", root, "ls-files", "-z", pattern],
                         capture_output=True, text=True)
    if out.returncode != 0:
        could_not_look(
            "tools/check-printed-commands.py reads the tracked file set, so it "
            "must run inside this git repository",
            "run it from a checkout of this repository, not from a copy of the file")
    return [p for p in out.stdout.split("\0") if p]


def read(path):
    with open(path, encoding="utf-8", errors="replace") as fh:
        return fh.read()


def family_of_shebang(line):
    if not line.startswith("#!"):
        return None
    word = line.split("/")[-1].split()[0] if line.strip() else ""
    # `#!/usr/bin/env python3` — the interpreter is the argument, not `env`.
    if word == "env":
        parts = line.split()
        word = parts[1].split("/")[-1] if len(parts) > 1 else ""
    return SHEBANG_FAMILY.get(word)


def accepted_flags(src, path):
    """Every long flag the script dispatches on, by the forms this repository
    actually writes. Returns a set; an EMPTY set means undecidable, not none."""
    flags = set()
    if path.endswith((".py",)):
        # argparse, and the hand-rolled sys.argv readers beside it.
        flags |= set(re.findall(r"""add_argument\(\s*['"](--[A-Za-z0-9][\w-]*)""", src))
        flags |= set(re.findall(r"""['"](--[A-Za-z0-9][\w-]*)['"]\s*(?:in|==|,|\))""", src))
        flags |= set(re.findall(r"""(?:==|!=)\s*['"](--[A-Za-z0-9][\w-]*)['"]""", src))
        flags |= set(re.findall(r"""startswith\(\s*['"](--[A-Za-z0-9][\w-]*)""", src))
    else:
        # A `case` arm, at any indentation, alone or in an alternation, and
        # with or without a `"")` empty-argument sibling:
        #   --raw)            --coverage|--self-test)       --audit|"")
        for arm in re.findall(r"^[ \t]*((?:(?:--[A-Za-z0-9][\w-]*|\"\"|\*)\|)*"
                              r"--[A-Za-z0-9][\w-]*(?:\|(?:--[A-Za-z0-9][\w-]*|\"\"|\*))*)\)",
                              src, re.M):
            flags |= {w for w in arm.split("|") if w.startswith("--")}
        # The one-flag scripts, which test $1 directly rather than dispatch:
        #   if [ "${1:-}" = "--self-test" ];    if [ "${1:-}" = --self-test ]
        flags |= set(re.findall(r"""=\s*["']?(--[A-Za-z0-9][\w-]*)["']?[ \t]*\]""", src))
        # A `for a in "$@"` loop's arms are already covered by the case form.
    return flags


def usage_flags(src, path):
    """The flags the script's own usage header prints for itself. The header is
    the comment block at the top, up to the first line that is not a comment."""
    own = os.path.basename(path)
    flags, lines = set(), []
    for line in src.splitlines()[1:]:          # [1:] skips the shebang
        if not line.startswith("#"):
            break
        lines.append(line)
    for line in lines:
        for m in INVOCATION.finditer(line):
            if os.path.basename(m.group(2)) != own:
                continue          # it is printing somebody else's command
            flags |= {w for w in m.group(3).split() if w.startswith("--")}
    return flags


def scan(root):
    """(findings, census). A finding is a printed command this checkout would
    refuse. The census is every number a reader needs to judge the findings."""
    findings = []
    census = {"documents": 0, "invocations": 0, "sites": 0, "vendored_skipped": 0,
              "foreign_skipped": 0, "undecidable": set(), "scripts_checked": set(),
              "headers": 0, "header_undecidable": set(), "subcommand": set()}
    cache = {}

    def script_facts(rel):
        if rel not in cache:
            full = os.path.join(root, rel)
            if not os.path.exists(full):
                cache[rel] = None
            else:
                src = read(full)
                first = src.splitlines()[0] if src else ""
                cache[rel] = (src, family_of_shebang(first),
                              accepted_flags(src, rel))
        return cache[rel]

    # ---- direction one: a document printing a command ----------------------
    for doc in tracked(root, "*.md"):
        if doc.startswith(VENDORED):
            census["vendored_skipped"] += 1
            continue
        census["documents"] += 1
        seen = set()
        for lineno, line in enumerate(read(os.path.join(root, doc)).splitlines(), 1):
            for m in INVOCATION.finditer(line):
                interp, rel, rest = m.group(1), m.group(2), m.group(3)
                rel = rel[2:] if rel.startswith("./") else rel
                if not rel.startswith(OURS):
                    census["foreign_skipped"] += 1
                    continue
                census["sites"] += 1
                flags = [w for w in rest.split() if w.startswith("--")]
                key = (interp, rel, tuple(flags))
                if key not in seen:
                    seen.add(key)
                    census["invocations"] += 1
                where = f"{doc}:{lineno}"
                printed = f"{interp} {rel}{(' ' + ' '.join(flags)) if flags else ''}"
                facts = script_facts(rel)
                if facts is None:
                    findings.append((where, printed, "names a script this checkout does not have",
                                     f"restore {rel}, or correct the path the document prints"))
                    continue
                _, family, accepted = facts
                census["scripts_checked"].add(rel)
                # The interpreter the document types, against the one the file
                # says it is. Running a python source under `bash` does not
                # fail cleanly: bash executes each line as a shell command.
                typed = SHEBANG_FAMILY.get(interp)
                if family and typed and family != typed:
                    runs = {"py": "python3", "sh": "bash", "js": "node"}[family]
                    findings.append((
                        where, printed,
                        f"runs {rel} with {interp}, and that file's own shebang names {family}",
                        f"print it the way it runs: {runs} {rel}"
                        + (" — bash executes each line of a python source as a shell command"
                           if family == "py" else "")))
                    continue
                # ONLY THE FIRST WORD, and only when it is a flag. That is
                # exactly what a `case "${1:-}"` dispatcher sees, and it is the
                # whole of what this reader can honestly decide. A positional
                # first word means a subcommand owns everything after it:
                # `node cli/src/index.js deploy pm agents --port 7788` parses
                # `--port` inside the deploy module, and an earlier draft of
                # this reader accused that line on the strength of index.js's
                # top-level dispatch. A gate that accuses wrongly gets turned
                # off, so a subcommand form is undecidable here, by name.
                words = rest.split()
                if not words or not words[0].startswith("--"):
                    if words:
                        census["subcommand"].add(rel)
                    continue
                if not accepted:
                    census["undecidable"].add(rel)
                    continue
                flag = words[0]
                if flag not in accepted:
                    stem = flag.strip("-")[:4]
                    near = ", ".join(sorted(f for f in accepted if stem and stem in f)[:3])
                    findings.append((
                        where, printed,
                        f"passes {flag}, which {rel} does not dispatch on",
                        f"the flags it takes: {' '.join(sorted(accepted))}"
                        + (f" — did it mean {near}?" if near else "")))

    # ---- direction two: a script printing its own command ------------------
    for rel in tracked(root, "docs/agents/*") + tracked(root, "tools/*"):
        if not rel.endswith((".sh", ".py")):
            continue
        facts = script_facts(rel)
        if facts is None:
            continue
        src, _, accepted = facts
        printed_flags = usage_flags(src, rel)
        if not printed_flags:
            continue
        census["headers"] += 1
        if not accepted:
            census["header_undecidable"].add(rel)
            continue
        for flag in sorted(printed_flags - accepted):
            findings.append((
                f"{rel}:usage", f"its own header prints {flag}",
                f"{rel} documents {flag} for itself and does not dispatch on it",
                f"the flags it takes: {' '.join(sorted(accepted))}"))

    return findings, census


def report(findings, census):
    for where, printed, rule, fix in findings:
        print(f"STALE {where}")
        print(f"      `{printed}`")
        print(f"      {rule}.")
        print(f"      Fix: {fix}")
    n = len(findings)
    tally = (f"printed-commands: {census['invocations']} distinct invocation(s) of "
             f"{len(census['scripts_checked'])} script(s) across {census['sites']} site(s) in "
             f"{census['documents']} document(s), plus {census['headers']} usage header(s)")
    if n == 0:
        print(f"{tally} — every one of them names a command this checkout would run.")
        return 0
    print()
    print(f"{tally}; {n} stale.")
    print("A command in a document is read by people and run by nothing (L-A114, one")
    print("step out). Each finding above is a line somebody will copy: correct it, or")
    print("move the invocation into a file and have the document name the file.")
    return 1


def census_report(census):
    print(f"documents scanned           {census['documents']}")
    print(f"  vendored, not scanned     {census['vendored_skipped']}  (docs/standards/, HQ's tree)")
    print(f"invocation sites            {census['sites']}")
    print(f"  distinct invocations      {census['invocations']}")
    print(f"  scripts named             {len(census['scripts_checked'])}")
    print(f"  outside this repository   {census['foreign_skipped']}  (not ours to check)")
    print(f"usage headers with flags    {census['headers']}")
    print(f"subcommand form, undecided  {len(census['subcommand'])}"
          + (f"  {' '.join(sorted(census['subcommand']))}" if census['subcommand'] else ""))
    print(f"undecidable, invocations    {len(census['undecidable'])}"
          + (f"  {' '.join(sorted(census['undecidable']))}" if census['undecidable'] else ""))
    print(f"undecidable, headers        {len(census['header_undecidable'])}"
          + (f"  {' '.join(sorted(census['header_undecidable']))}" if census['header_undecidable'] else ""))


# --------------------------------------------------------------- the self-test
# A negative control, not a smoke test. The real tree answers 0 after this
# branch's fixes, so a reader hard-wired to find nothing would pass a smoke
# test and prove nothing. Every case below is built: a planted document in a
# planted repository, one fault per case, and three things that must stay quiet.
PLANTED = {
    "docs/agents/one.sh": """#!/usr/bin/env bash
case "${1:-}" in
--real) echo yes ;;
--also|--too) echo yes ;;
*) exit 2 ;;
esac
""",
    "docs/agents/two.py": """#!/usr/bin/env python3
import sys
if "--census" in sys.argv: print("x")
""",
    "docs/agents/mystery.sh": """#!/usr/bin/env bash
# no dispatcher this reader can read
eval "$@"
""",
    "docs/agents/honest.sh": """#!/usr/bin/env bash
#   bash docs/agents/honest.sh --real   does the thing
case "${1:-}" in
--real) echo yes ;;
esac
""",
    "docs/agents/liar.sh": """#!/usr/bin/env bash
#   bash docs/agents/liar.sh --gone   does the thing
case "${1:-}" in
--real) echo yes ;;
esac
""",
    "doc.md": """
Stale, a flag it does not take: `bash docs/agents/one.sh --nope`
Stale, the wrong interpreter: `bash docs/agents/two.py --census`
Stale, a script that is not here: `bash docs/agents/ghost.sh --x`
Quiet, a real flag: `bash docs/agents/one.sh --real`
Quiet, a real flag in an alternation: `bash docs/agents/one.sh --too`
Quiet, no dispatcher this reader can read: `bash docs/agents/mystery.sh --anything`
Quiet, not our tree: `python3 /srv/asc/hq/tools/elsewhere.py --flag`
Quiet, a subcommand owns the flag: `bash docs/agents/one.sh send --nope`
""",
    "docs/standards/vendored.md": """
Quiet, vendored: `bash docs/agents/one.sh --nope`
""",
}


def self_test():
    fails = []

    def check(label, cond, detail=""):
        if cond:
            print(f"  ok    {label}")
        else:
            print(f"  FAIL  {label}" + (f" — {detail}" if detail else ""))
            fails.append(label)

    tmp = tempfile.mkdtemp(prefix="printed-commands-selftest-")
    try:
        for rel, body in PLANTED.items():
            full = os.path.join(tmp, rel)
            os.makedirs(os.path.dirname(full), exist_ok=True)
            with open(full, "w", encoding="utf-8") as fh:
                fh.write(body)
        subprocess.run(["git", "-C", tmp, "init", "-q"], check=True)
        subprocess.run(["git", "-C", tmp, "add", "-A"], check=True,
                       capture_output=True)

        findings, census = scan(tmp)
        got = {(w, r) for w, _, r, _ in findings}
        blob = "\n".join(f"{w} {r}" for w, _, r, _ in findings)

        check("a flag the script does not dispatch on is stale",
              any(w == "doc.md:2" and "--nope" in r for w, r in got), blob)
        check("a python script printed under bash is stale",
              any(w == "doc.md:3" and "shebang" in r for w, r in got), blob)
        check("a script this checkout does not have is stale",
              any(w == "doc.md:4" and "does not have" in r for w, r in got), blob)
        check("a real flag is quiet", "doc.md:5" not in {w for w, _ in got}, blob)
        check("a real flag inside an alternation is quiet",
              "doc.md:6" not in {w for w, _ in got}, blob)
        check("a script with no readable dispatcher is NOT accused",
              "doc.md:7" not in {w for w, _ in got}, blob)
        check("...and is named as undecidable instead",
              "docs/agents/mystery.sh" in census["undecidable"], census["undecidable"])
        check("a flag behind a subcommand is NOT accused",
              "doc.md:9" not in {w for w, _ in got}, blob)
        check("...and the script is named as a subcommand form instead",
              "docs/agents/one.sh" in census["subcommand"], census["subcommand"])
        check("a path outside this repository is quiet",
              "doc.md:8" not in {w for w, _ in got}, blob)
        check("...and is counted as skipped", census["foreign_skipped"] == 1,
              census["foreign_skipped"])
        check("a vendored document is not scanned",
              not any(w.startswith("docs/standards/") for w, _ in got), blob)
        check("...and is counted as skipped", census["vendored_skipped"] == 1,
              census["vendored_skipped"])
        check("a usage header printing a flag its own script lacks is stale",
              any(w == "docs/agents/liar.sh:usage" for w, _ in got), blob)
        check("a usage header printing a flag its own script has is quiet",
              "docs/agents/honest.sh:usage" not in {w for w, _ in got}, blob)

        # The exit code is the contract every caller reads, so assert it.
        check("findings mean exit 1", report(findings, census) == 1)
        empty = ({}, {"documents": 0, "invocations": 0, "sites": 0,
                      "vendored_skipped": 0, "foreign_skipped": 0,
                      "undecidable": set(), "scripts_checked": set(),
                      "headers": 0, "header_undecidable": set(),
                      "subcommand": set()})
        check("no findings mean exit 0", report([], empty[1]) == 0)
    finally:
        shutil.rmtree(tmp, ignore_errors=True)

    if fails:
        print(f"self-test FAILED: {len(fails)} verdict(s) wrong")
        return 1
    print("self-test: every verdict agrees")
    return 0


def gate(root):
    """What a suite runs: the negative control first, then the tree, under one
    tally in the shape `cli/test/all.sh` reads. The control comes first on
    purpose — a reader that has stopped finding anything reports a clean tree,
    and that is the direction this whole file exists to catch."""
    print("== the verdicts, on built input")
    control = self_test()
    print()
    print("== this checkout")
    findings, census = scan(root)
    stale = report(findings, census)
    ok = census["invocations"] + census["headers"] - len(findings)
    bad = len(findings) + (1 if control else 0)
    print()
    if control:
        print("the reader's own self-test failed above, so the scan's answer is "
              "not evidence of anything")
    print(f"printed-commands: {ok} ok, {bad} failed")
    return 1 if bad else 0


def main(argv):
    mode = argv[1] if len(argv) > 1 else ""
    if mode == "--self-test":
        return self_test()
    if mode not in ("", "--census", "--gate"):
        could_not_look(
            f"tools/check-printed-commands.py takes --census, --self-test or --gate, not {mode}",
            "run it with no argument to scan, --census for the population, "
            "--self-test for the verdicts, --gate for both under one tally")
    root = subprocess.run(["git", "rev-parse", "--show-toplevel"],
                          capture_output=True, text=True).stdout.strip()
    if not root:
        could_not_look(
            "tools/check-printed-commands.py reads the tracked file set, so it "
            "must run inside this git repository",
            "run it from a checkout of this repository")
    if mode == "--gate":
        return gate(root)
    findings, census = scan(root)
    if mode == "--census":
        census_report(census)
        return 0
    return report(findings, census)


if __name__ == "__main__":
    sys.exit(main(sys.argv))
