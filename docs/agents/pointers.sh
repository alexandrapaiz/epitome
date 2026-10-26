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
# It reads the first file at the revision the host EXECUTES as well as the one
# on `main`, because those are not the same text. The launcher is resolved
# through `command -v epito` rather than guessed, since the tool you ran is the
# copy you reached (L-A70) and a declaration in a repository is not a fact about
# the running system (L-A72).
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

ROSTER="$ROSTER" COMPANY="$COMPANY" ALL="$ALL" LAUNCHER="$LAUNCHER" python3 -c '
import os, re, sys, glob, datetime

roster, company = os.environ["ROSTER"], os.environ["COMPANY"]
every, launcher = bool(os.environ.get("ALL")), os.environ.get("LAUNCHER") or ""
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

# ---- file one: the wake prompt, read at both revisions that exist for it.
def prompt_template(path):
    try:
        src = open(path, errors="replace").read()
    except OSError as e:
        return None, "could not read: %s" % e
    m = re.search(r"export function buildPrompt\b.*?\n}", src, re.S)
    if not m:
        return None, "no buildPrompt in %s" % path
    return m.group(0), ""

copies, first_rows, couldnot = [], [], 0
copies.append(("executing", launcher) if launcher else ("executing", ""))
copies.append(("on main", "cli/src/lib/runner.js"))
print("== file one, the wake prompt every seat reads before its charter ==")
for label, path in copies:
    if not path:
        print("  %-10s could not look: `command -v epito` resolved to no lib/runner.js (L41)" % label)
        couldnot += 1
        continue
    body, why = prompt_template(path)
    if body is None:
        print("  %-10s could not look: %s (L41)" % (label, why)); couldnot += 1; continue
    v, note = verdict(body, "")
    full = "and asserts the charter is FULL" if "full charter" in body else ""
    print("  %-10s %-9s %s  %s %s" % (label, v, path, note, full))
    first_rows.append((label, path, v, bool(full)))

# ---- file two: the charter at each seat`s entry, plus any charter with no
# manifest, because a parser counts what it could not attach (L-A91).
seats, sources = {}, {}
dirs = sorted(glob.glob(os.path.join(roster, "*"))) if every else [os.path.join(roster, company)]
for d in dirs:
    co = os.path.basename(d)
    for m in sorted(glob.glob(os.path.join(d, "*", "agent.toml"))):
        seat = os.path.basename(os.path.dirname(m))
        try:
            t = open(m, errors="replace").read()
        except OSError:
            continue
        e = re.search(r"^\s*entry\s*=\s*\"([^\"]+)\"", t, re.M)
        r = re.search(r"^\s*repo\s*=\s*\"([^\"]+)\"", t, re.M)
        seats[(co, seat)] = (e.group(1) if e else "", r.group(1) if r else "")
        sources[(co, seat)] = "host manifest"
if not seats:
    print("\n  could not look: no manifest under %s (L41)" % roster); couldnot += 1
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
    elif co != company and not every:
        continue
    elif not os.path.exists(entry):
        v, note = "ELSEWHERE", "not in this checkout: %s" % (_repo or "unknown repo")
    else:
        v, note = verdict(open(entry, errors="replace").read(), seat)
    counts[v] = counts.get(v, 0) + 1
    rows.append((co, seat, entry, v))
    print("%-10s %-10s %-26s %-9s %s  %s" % (co, seat, entry[:26], v, src, note))

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
  tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
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
  printf 'export function buildPrompt({ name }) {\n  return [`Read ${name} - it is your full charter`].join("\\n");\n}\n' \
    > "$tmp/cli/src/lib/runner.js"
  cp "${BASH_SOURCE[0]}" "$tmp/pointers.sh"
  ( cd "$tmp" && git init -q . && git add -A >/dev/null 2>&1
    EPITO_ROSTER="$tmp/nothing-here" EPITO_LAUNCHER="$tmp/cli/src/lib/runner.js" \
      bash pointers.sh --company self 2>&1 | sed 's/^/  /' )
  echo "  expected: good PASS, bad OWN-ONLY, the wake prompt SILENT with a full-charter claim,"
  echo "  and the roster read reported as could-not-look rather than as zero seats (L41)."
fi
exit $rc
