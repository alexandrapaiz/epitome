#!/usr/bin/env bash
# Does every file a seat is actually handed name the law above it?
#
#   bash docs/agents/pointers.sh              this product's seats, both files each
#   bash docs/agents/pointers.sh --all        every seat the host runs, all companies
#   bash docs/agents/pointers.sh --self-test  a constructed positive and negative
#
# Exit 0 every handed file names the register, 1 at least one does not,
# 2 could not look (L41).
#
# WHY THIS EXISTS. `docs/standards/lessons.md` L-A90 says a law binds where the
# seat reads and not where the register keeps it: "a standard distributed into a
# repository is not distributed until the file each seat is actually handed names
# it by path and says which sections bind that seat, and a charter that points at
# the product's own lessons file has not pointed at the company's: the sentence
# reads the same and the file is a different one." That rule was offered up by
# this seat and it has been law here since the vendored register landed, and for
# the whole of that time nobody has counted the files.
#
# The count is not one number, because a seat here is handed TWO files (L-X11),
# and the one it reads FIRST is not the charter. It is the wake prompt this
# product's own runtime composes — `buildPrompt` in `cli/src/lib/runner.js` —
# which arrives nearest the model's attention and therefore wins where the two
# disagree (L-X10). So this reads both, per seat, and never one without the
# other: an audit that reads only `prompts/` has read half of every charter it
# graded.
#
# It reads the first file at the revision the host EXECUTES, the one on `main`,
# and the one in this checkout, because those are three different texts and a
# branch under review is exactly the case where they differ. The launcher is
# resolved through `command -v epito` rather than guessed, since the tool you ran
# is the copy you reached (L-A70) and a declaration in a repository is not a fact
# about the running system (L-A72). `main` is the blob from `origin/main` in a
# throwaway worktree, not the file in this working tree: the first version of
# this script labelled the checkout "on main", which is right on `main` and
# wrong on every branch, including every branch that changes the prompt.
#
# THE GRADE IS ON THE COMPOSED PROMPT, NOT ON THE SOURCE OF THE FUNCTION THAT
# COMPOSES IT. `buildPrompt` is imported and called, and what a seat is handed
# is what gets read. The first version grepped the function's whole body,
# comments included, which is L67 clause one — a capability or a claim is
# settled by the smallest real act, never by reading the text that governs it —
# and this seat shipped it four days after writing that clause. The cost landed
# on somebody else: `epitome/engineer` reported on 2026-10-26 that its own
# commit explaining why the completeness claim was being deleted tripped this
# detector, because the explanation had to quote the phrase, and it had to
# reword the comment and then write *"the phrase itself is kept out of this
# comment on purpose"* into the runtime to keep this script quiet. A detector
# that makes another seat's file unwritable is charging rent on prose. The
# source read survives as a HINT that decides nothing, printed beside the
# verdict, because the difference between the two is the finding.
#
# The heuristic, stated so a reader can falsify it rather than trust it: a
# handed file PASSES when it contains the literal string
# `docs/standards/lessons.md` and, within the 800 characters that follow it,
# some word about which parts bind — `section`, `binds`, or the seat's own role
# name. It is OWN-ONLY when it names `docs/agents/lessons.md` and not the
# vendored path, which is the case L-A90 says is why nobody noticed. It is
# PATH-ONLY when the path is there and nothing says which sections. A heuristic
# can be wrong in both directions and this one says which rows it decided by
# proximity, so a false pass is findable.
#
# `EPITO_LAUNCHER` overrides the resolved launcher path, which is how the
# self-test reaches a constructed one instead of the host's.
#
# `--all` walks every seat the host runs and refuses to grade any whose manifest
# declares a repository other than this checkout: a same-named charter here is
# not that repository`s charter, and reading it would be a confident finding
# about a world this seat cannot see (L-A12, L-A38). Those rows read ELSEWHERE
# and are counted apart, so the denominator never silently becomes the portfolio.
#
# Reads only.
set -uo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)"

ROSTER=${EPITO_ROSTER:-/srv/asc/roster}
COMPANY=${EPITO_COMPANY:-epitome}
ALL=
SELFTEST=
while [ $# -gt 0 ]; do
  case "$1" in
    --all) ALL=1; shift ;;
    --company) COMPANY=${2:?--company needs a name}; shift 2 ;;
    --roster) ROSTER=${2:?--roster needs a path}; shift 2 ;;
    --self-test) SELFTEST=1; shift ;;
    --help|-h) sed -n '2,/^[^#]/p' "${BASH_SOURCE[0]}" | sed -n 's/^# \{0,1\}//p'; exit 0 ;;
    *) echo "pointers.sh: unknown argument $1" >&2; exit 2 ;;
  esac
done

LAUNCHER=${EPITO_LAUNCHER:-}
if [ -z "$LAUNCHER" ] && command -v epito >/dev/null; then
  ep=$(readlink -f "$(command -v epito)")
  cand="$(dirname "$ep")/lib/runner.js"
  [ -f "$cand" ] && LAUNCHER=$cand
fi

HERE=$(git remote get-url origin 2>/dev/null | sed -E 's#(git@github.com:|https://github.com/)##; s#\.git$##')

# `main` is a ref, not whatever this working tree happens to hold. The blob
# alone will not do: runner.js imports nine siblings, so the copy has to sit in
# a tree that has them, and a throwaway worktree is the cheapest one that does.
# If it cannot be made, the row reads could-not-look rather than quietly
# grading this branch and calling it `main` (L-A34, L41).
MAIN_RUNNER=
MAIN_WT=
if git rev-parse --verify -q origin/main >/dev/null; then
  MAIN_WT=$(mktemp -d) || MAIN_WT=
  if [ -n "$MAIN_WT" ] && git worktree add -q --detach "$MAIN_WT" origin/main 2>/dev/null; then
    [ -f "$MAIN_WT/cli/src/lib/runner.js" ] && MAIN_RUNNER=$MAIN_WT/cli/src/lib/runner.js
  else
    MAIN_WT=
  fi
fi
cleanup() {
  [ -n "$MAIN_WT" ] && git worktree remove --force "$MAIN_WT" >/dev/null 2>&1
  [ -n "$MAIN_WT" ] && rm -rf "$MAIN_WT"
  return 0
}
trap cleanup EXIT

ROSTER="$ROSTER" COMPANY="$COMPANY" ALL="$ALL" LAUNCHER="$LAUNCHER" HERE="$HERE" \
  MAIN_RUNNER="$MAIN_RUNNER" python3 -c '
import os, re, sys, glob, json, subprocess, datetime

roster, company = os.environ["ROSTER"], os.environ["COMPANY"]
every, launcher = bool(os.environ.get("ALL")), os.environ.get("LAUNCHER") or ""
here = os.environ.get("HERE") or ""
VENDORED, OWN = "docs/standards/lessons.md", "docs/agents/lessons.md"
now = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

def verdict(text, role):
    if VENDORED in text:
        at = text.index(VENDORED)
        near = text[at:at + 800].lower()
        if "section" in near or "binds" in near or (role and role.lower() in near):
            return "PASS", ""
        return "PATH-ONLY", "names the file and not which sections bind this seat"
    if OWN in text:
        return "OWN-ONLY", "names %s, which reads the same and is a different file" % OWN
    return "SILENT", "names no lessons register at all"

# ---- file one: the wake prompt, COMPOSED by the function that composes it for
# a real run, at each of the three revisions that exist for it. Grading the
# source of `buildPrompt` grades its comments too, which is the defect L67
# clause one names and which another seat paid for; so the function is called.
def compose(path):
    """The prompt as a seat receives it, or (None, why nobody can know)."""
    if not path:
        return None, "no path to a runner.js"
    if not os.path.exists(path):
        return None, "no such file: %s" % path
    js = ("import { buildPrompt } from %s;\n"
          "process.stdout.write(buildPrompt({ name: \"pointers-probe\","
          " entry: \"prompts/pointers-probe-agent.md\", trigger: \"message\","
          " date: \"1970-01-01\" }));") % json.dumps("file://" + os.path.abspath(path))
    try:
        p = subprocess.run(["node", "--input-type=module", "-e", js],
                           capture_output=True, text=True, timeout=60)
    except (OSError, subprocess.SubprocessError) as e:
        return None, "node would not run: %s" % e
    if p.returncode != 0 or not p.stdout.strip():
        last = [l for l in (p.stderr or "").strip().splitlines() if l.strip()]
        return None, "node refused it: %s" % (last[-1][:110] if last else "no output")
    return p.stdout, ""


def source_hint(path):
    """What a reader of the FUNCTION would conclude. Decides nothing."""
    try:
        src = open(path, errors="replace").read()
    except OSError:
        return "unreadable"
    m = re.search(r"export function buildPrompt\b.*?\n}", src, re.S)
    body = m.group(0) if m else src
    return "%s/%s" % (verdict(body, "")[0], "full" if "full charter" in body else "no-full")


copies, first_rows, couldnot = [], [], 0
copies.append(("executing", launcher))
copies.append(("on main", os.environ.get("MAIN_RUNNER") or ""))
copies.append(("this tree", "cli/src/lib/runner.js"))
print("== file one, the wake prompt every seat reads before its charter ==")
print("  (composed by calling buildPrompt; the hint is what reading its source would say)")
for label, path in copies:
    body, why = compose(path)
    if body is None:
        if label == "executing" and not path:
            why = "`command -v epito` resolved to no lib/runner.js"
        if label == "on main" and not path:
            why = "`git worktree add origin/main` did not give one"
        print("  %-10s could not look: %s (L41)" % (label, why)); couldnot += 1; continue
    v, note = verdict(body, "")
    full = "and asserts the charter is FULL" if "full charter" in body else ""
    print("  %-10s %-9s %-52s hint=%-14s %s %s"
          % (label, v, path if len(path) < 52 else "..." + path[-49:],
             source_hint(path), note, full))
    first_rows.append((label, path, v, bool(full)))

# ---- file two: the charter at each seat`s entry, plus any charter with no
# manifest, because a parser counts what it could not attach (L-A91).
# This roster holds two conventions and an instrument that knows one of them
# reports the other as nothing: <roster>/<company>/<seat>/agent.toml for a
# product seat and <roster>/<seat>/agent.toml for a headquarters seat. Both are
# accepted, and a manifest that parses but names no entry is counted rather than
# dropped (L-A91).
seats, sources, skipped = {}, {}, []
found = []
if every:
    found += [(os.path.basename(os.path.dirname(m)), m)
              for m in sorted(glob.glob(os.path.join(roster, "*", "agent.toml")))]
    found += [(m.split(os.sep)[-3], m)
              for m in sorted(glob.glob(os.path.join(roster, "*", "*", "agent.toml")))]
else:
    found += [(company, m)
              for m in sorted(glob.glob(os.path.join(roster, company, "*", "agent.toml")))]
    found += [(company, m) for m in sorted(glob.glob(os.path.join(roster, company, "agent.toml")))]
for co, m in found:
    seat = os.path.basename(os.path.dirname(m))
    if seat == co: seat = co
    try:
        t = open(m, errors="replace").read()
    except OSError as e:
        skipped.append("%s: %s" % (m, e)); continue
    ent = re.search(r"^\s*entry\s*=\s*\"([^\"]+)\"", t, re.M)
    rep = re.search(r"^\s*repo\s*=\s*\"([^\"]+)\"", t, re.M)
    nm = re.search(r"^\s*name\s*=\s*\"([^\"]+)\"", t, re.M)
    if nm and seat == co: seat = nm.group(1)
    seats[(co, seat)] = (ent.group(1) if ent else "", rep.group(1) if rep else "")
    sources[(co, seat)] = "host manifest"
if not seats:
    print("\n  could not look: no manifest under %s, by either convention (L41)" % roster)
    couldnot += 1
for m in sorted(glob.glob("agents/*/agent.toml")):
    seat = os.path.basename(os.path.dirname(m))
    if (company, seat) in seats: continue
    t = open(m, errors="replace").read()
    e = re.search(r"^\s*entry\s*=\s*\"([^\"]+)\"", t, re.M)
    seats[(company, seat)] = (e.group(1) if e else "", "")
    sources[(company, seat)] = "repo manifest"
for p in sorted(glob.glob("prompts/*-agent.md")):
    seat = os.path.basename(p)[:-len("-agent.md")]
    if (company, seat) in seats: continue
    seats[(company, seat)] = (p, "")
    sources[(company, seat)] = "charter, no manifest"

print()
print("== file two, the charter each manifest names ==")
print("%-10s %-10s %-26s %-9s %s" % ("company", "seat", "entry", "verdict", "read from"))
counts, rows = {}, []
for (co, seat) in sorted(seats):
    entry, _repo = seats[(co, seat)]
    src = sources[(co, seat)]
    if not entry:
        v, note = "NO-ENTRY", "the manifest names no charter file"
    elif _repo and here and _repo.lower() != here.lower():
        # A same-named file in THIS checkout is not that repository`s charter.
        # Grading it from here would be a confident finding about a world that
        # is not in this seat`s hands (L-A12, L-A38).
        v, note = "ELSEWHERE", "%s, not in this checkout" % _repo
    elif not os.path.exists(entry):
        v, note = "ELSEWHERE", "%s: no such file here" % (_repo or "repo not declared")
    else:
        v, note = verdict(open(entry, errors="replace").read(), seat)
    counts[v] = counts.get(v, 0) + 1
    rows.append((co, seat, entry, v))
    print("%-10s %-10s %-26s %-9s %s  %s" % (co, seat, entry[:26], v, src, note))

# ---- what the pointer costs, per seat, because a pointer is an instruction to
# read and the reading is paid once per wake. `epitome/engineer` named the
# sharp end of it on 2026-10-26, declining to special-case it in the runtime
# and declining for the right reason (L-A26: an exception written as a list of
# names decays): "the canary charter says to list the files in docs and exit,
# nothing else, and it is now sent through a 274 kB register first." This
# prints the number instead of arguing about the exception, for every seat
# rather than the one absurd row, because the canary is not the expensive case
# — every working seat pays the same `any` section.
print()
print("== what the pointer costs each seat per wake ==")
cost_rows = []
try:
    reg = open(VENDORED, errors="replace").read()
except OSError as e:
    print("  could not look: %s (L41)" % e); couldnot += 1; reg = ""
if reg:
    secs, name = {}, None
    for line in reg.splitlines(True):
        if line.startswith("## "):
            name = line[3:].strip().split(" (")[0].split(" \u2014")[0].strip()
            secs[name] = ""
        elif name:
            secs[name] += line
    anyb = len(secs.get("any", ""))
    print("  %-10s %-9s %-9s %-9s %s" % ("seat", "any", "its own", "charter", "register/charter"))
    for (co, seat) in sorted(seats):
        if co != company: continue
        entry = seats[(co, seat)][0]
        own = len(secs.get(seat, ""))
        ch = os.path.getsize(entry) if entry and os.path.exists(entry) else 0
        ratio = ("%dx" % round((anyb + own) / ch)) if ch else "n/a"
        print("  %-10s %-9d %-9d %-9d %s" % (seat, anyb, own, ch, ratio))
        cost_rows.append((seat, anyb, own, ch))
    print("  The `any` section alone is %d bytes, ~%d tokens at four bytes a token," % (anyb, anyb // 4))
    print("  read before the charter on every wake of every seat in the portfolio.")

clean = counts.get("PASS", 0)
total = sum(counts.values())
print()
print("%d of %d charter(s) read name %s and say which sections bind the seat." % (clean, total, VENDORED))
for k in ("OWN-ONLY", "PATH-ONLY", "SILENT", "NO-ENTRY", "ELSEWHERE"):
    if counts.get(k):
        print("  %-9s %d" % (k, counts[k]))
if any(r[3] for r in first_rows):
    print()
    print("And the file they all read first tells them the charter is their FULL charter, which")
    print("is a claim about completeness rather than an omission: a seat that believes it has")
    print("read the whole of its instructions does not go looking for the law above them.")
print()
print("```data")
print("instrument: docs/agents/pointers.sh")
print("read_at: %s" % now)
print("register: %s" % VENDORED)
print("wake_prompt_copies_read: %d" % len(first_rows))
for label, path, v, full in first_rows:
    print("wake_prompt_%s: %s %s full_charter_claim=%s" % (label.replace(" ", "_"), v, path, str(full).lower()))
print("charters_read: %d" % total)
print("charters_naming_the_register: %d" % clean)
for k in ("OWN-ONLY", "PATH-ONLY", "SILENT", "NO-ENTRY", "ELSEWHERE"):
    print("charters_%s: %d" % (k.lower().replace("-", "_"), counts.get(k, 0)))
for seat, anyb, own, ch in cost_rows:
    print("pointer_cost_%s: any=%d role=%d charter=%d" % (seat, anyb, own, ch))
print("manifests_unreadable: %d" % len(skipped))
print("could_not_look: %d" % couldnot)
print("```")
bad = total - clean + sum(1 for _l, _p, v, _f in first_rows if v != "PASS")
if couldnot and not total:
    sys.exit(2)
sys.exit(1 if bad else 0)
'
rc=$?

if [ -n "$SELFTEST" ]; then
  echo
  echo "== self-test: can the clean case be reached at all (L-A101) =="
  tmp=$(mktemp -d); trap 'cleanup; rm -rf "$tmp"' EXIT
  mkdir -p "$tmp/prompts" "$tmp/agents/good" "$tmp/agents/bad" "$tmp/cli/src/lib"
  cat > "$tmp/prompts/good-agent.md" <<'EOF'
The law above this charter is `docs/standards/lessons.md`, whose any and
good sections bind this seat before its own lessons do.
EOF
  cat > "$tmp/prompts/bad-agent.md" <<'EOF'
Check your work against docs/agents/lessons.md before you ready the branch.
EOF
  printf '[runtime]\nentry = "prompts/good-agent.md"\n' > "$tmp/agents/good/agent.toml"
  printf '[runtime]\nentry = "prompts/bad-agent.md"\n'  > "$tmp/agents/bad/agent.toml"
  cp "${BASH_SOURCE[0]}" "$tmp/pointers.sh"

  # Case one, the negative control: the composed prompt names no register and
  # does claim completeness. Both the act and the source agree, which is the
  # case that was never in doubt.
  printf 'export function buildPrompt({ name }) {\n  return [`Read ${name} - it is your full charter`].join("\\n");\n}\n' \
    > "$tmp/cli/src/lib/runner.js"
  ( cd "$tmp" && git init -q . && git add -A >/dev/null 2>&1
    EPITO_ROSTER="$tmp/nothing-here" EPITO_LAUNCHER="$tmp/cli/src/lib/runner.js" \
      bash pointers.sh --company self 2>&1 | sed -n '1,6p' | sed 's/^/  /' )
  echo "  expected: the wake prompt SILENT with a full-charter claim, hint SILENT/full,"
  echo "  and both the main row and the roster read reported as could-not-look (L41)."

  # Case two, the real positive for the repair, reduced from the commit that
  # found it (epitome-engineer 2e0df5d, 2026-10-26): the comment above the
  # prompt quotes the completeness claim in order to explain deleting it, and
  # names the register too. Reading the function says PASS/full. The prompt a
  # seat is handed says PASS and makes no such claim. The verdict column must
  # follow the act and the hint column must show the disagreement, or this
  # detector is charging another seat rent on its own comments.
  cat > "$tmp/cli/src/lib/runner.js" <<'EOF'
export function buildPrompt({ name }) {
  return [
    // The adjective this line used to carry, "it is your full charter", is
    // gone: the next line names a register that binds over the charter, so a
    // claim of completeness was an argument against looking further.
    `Read ${name} - it is your charter`,
    `Above it sits docs/standards/lessons.md: read the any section and the section for your role.`,
  ].join("\n");
}
EOF
  ( cd "$tmp" && git add -A >/dev/null 2>&1
    EPITO_ROSTER="$tmp/nothing-here" EPITO_LAUNCHER="$tmp/cli/src/lib/runner.js" \
      bash pointers.sh --company self 2>&1 | sed -n '3p' | sed 's/^/  /' )
  echo "  expected: PASS with hint=PASS/full — the verdict from calling the function,"
  echo "  the hint showing what the first version of this script reported instead."
fi
exit $rc
