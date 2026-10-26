#!/usr/bin/env bash
# Does the manifest in this repository describe the seat the host is running?
# (L63, incident 25.)
#
#   bash docs/agents/roster.sh                  this product against this box
#   bash docs/agents/roster.sh --roster PATH    another box's loaded roster
#   bash docs/agents/roster.sh --company NAME   the roster subdirectory to read
#   bash docs/agents/roster.sh --agents PATH    another repository's manifests
#
# Exit 0 nothing diverged, 1 a field diverged, 2 could not look (L41).
#
# WHY THIS EXISTS. `agents/<seat>/agent.toml` is this product's own dogfood:
# it is the manifest `epito validate` reads and the thing the CLI exists to
# run. It is not what runs this company's seats. `epitod` loads
# `/srv/asc/roster/<company>/<seat>/agent.toml` — a second, root-owned copy,
# cloned onto the box and read once at start with no watcher
# (deploy/provision-host.sh:27; docs/ideas.md row 23 has the reload as
# `proposed`). Nothing in this repository has ever opened that copy.
#
# The check this repository does have compares the wrong two files.
# `cli/test/smoke-roster.sh:194` asserts each manifest's `max_turns` equals
# its workflow's `--max-turns`, calling a drift between them "a dogfood that
# proves nothing". Both of those files are inert: the five `agent-*.yml`
# workflows have not run since the seats moved onto the resident runtime
# (incident 25 — on 2026-10-24 this host finished 336 seat runs and this
# repository's Actions ran only `asc-heartbeat`, and the same was true for
# every run in the two days to 2026-10-26). So the one fidelity test here
# compares two copies that do not execute, and the copy that does executes
# unread. Its green is a statement about neither.
#
# Which is also why it has never fired. `max_turns` and `model` are the two
# fields it compares and the two that still agree across all three copies;
# `env`, `subscriptions` and `scopes` are not compared by anything and have
# diverged on every seat of this product.
#
# Reads only: it invokes nothing that writes, and `epito help` is the single
# invocation it makes. No credential, no network.
set -uo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)"

ROSTER=${EPITO_ROSTER:-/srv/asc/roster}
COMPANY=${EPITO_COMPANY:-epitome}
AGENTS=agents
while [ $# -gt 0 ]; do
  case "$1" in
    --roster)  ROSTER=${2:?--roster needs a path};  shift 2 ;;
    --company) COMPANY=${2:?--company needs a name}; shift 2 ;;
    --agents)  AGENTS=${2:?--agents needs a path};  shift 2 ;;
    --help|-h) sed -n '2,/^[^#]/p' "${BASH_SOURCE[0]}" | sed -n 's/^# \{0,1\}//p'; exit 0 ;;
    *) echo "roster.sh: unknown argument $1" >&2; exit 2 ;;
  esac
done

# A zero because you looked somewhere empty is not a clean bill (L-A80, L41).
[ -d "$AGENTS" ] || { echo "roster.sh: no manifests at $AGENTS — could not look" >&2; exit 2; }
[ -d "$ROSTER/$COMPANY" ] || {
  echo "roster.sh: no loaded roster at $ROSTER/$COMPANY — this runs on the box that" >&2
  echo "           hosts the seats; from anywhere else the answer is could-not-look" >&2
  echo "           and never all-clear (L41, L-X16)." >&2; exit 2; }

# The third copy, and the one with the most behind it. `epito` is the binary
# that hosts every seat, and on this box it resolves into a clone of this same
# repository rather than into a package — so "does this repository describe the
# runtime" has an answer in `git`, and it is cheap enough that leaving it out
# would make this script a guard with a stated blind spot (L-X5's seventh
# clause: a limit a guard declares is the next incident's description).
BIN_PATH=; BIN_HEAD=; BIN_DATE=; BIN_BEHIND=; BIN_MISSING=; BIN_NOTE=
if command -v epito >/dev/null 2>&1; then
  BIN_PATH=$(readlink -f "$(command -v epito)" 2>/dev/null)
  bindir=$(dirname "$BIN_PATH" 2>/dev/null)
  BIN_HEAD=$(git -C "$bindir" rev-parse HEAD 2>/dev/null)
  if [ -n "$BIN_HEAD" ]; then
    BIN_DATE=$(git -C "$bindir" show -s --format=%cI "$BIN_HEAD" 2>/dev/null)
    # Counted in this checkout, which is the one with the history; a shallow
    # clone answers wrongly rather than not at all, so it says so (L41).
    if [ "$(git rev-parse --is-shallow-repository)" = true ]; then
      BIN_NOTE="this clone is shallow, so the distance is could-not-look"
    else
      BIN_BEHIND=$(git rev-list --count "$BIN_HEAD..origin/main" 2>/dev/null)
    fi
  fi
  # Which commands this repository ships that the running binary does not list.
  # Asked of the binary rather than read off its source, because the source on
  # disk here is not the source it was started from (L-A16: configured is not
  # in effect).
  #
  # `epito help` is read ONCE and parsed. The obvious probe — invoking each
  # command with `--help` and looking for "unknown command" — is what the first
  # version of this script did, and it is not read-only: `epito init --help`
  # takes `--help` as the new agent's NAME and scaffolds `agent.toml` and
  # `prompts/--help.md` into the working tree. It did exactly that in this
  # repository on 2026-10-26 while the header three lines up said "Reads only"
  # (L63's own clause turned on its author: the claim was never compared
  # against the act). A probe that must not change anything does not invoke
  # the thing it is probing.
  helptxt=$(mktemp) || helptxt=
  if [ -n "$helptxt" ]; then
    epito help > "$helptxt" 2>&1 || true
    for c in validate run ps window token routes doctor env bus board audit report note message deploy init; do
      grep -qE "(^|[^a-z-])epito $c([^a-z-]|\$)" "$helptxt" || BIN_MISSING="$BIN_MISSING${BIN_MISSING:+,}$c"
    done
    rm -f "$helptxt"
  else
    BIN_NOTE="no scratch directory, so the command list is could-not-look"
  fi
else
  BIN_NOTE="no epito on PATH; could not look"
fi

AGENTS="$AGENTS" ROSTER="$ROSTER" COMPANY="$COMPANY" \
BIN_PATH="$BIN_PATH" BIN_HEAD="$BIN_HEAD" BIN_DATE="$BIN_DATE" \
BIN_BEHIND="$BIN_BEHIND" BIN_MISSING="$BIN_MISSING" BIN_NOTE="$BIN_NOTE" python3 - <<'PY'
import os, re, sys, json, datetime

agents, roster, company = os.environ["AGENTS"], os.environ["ROSTER"], os.environ["COMPANY"]

def strip_comment(v):
    # A value's trailing `# ...` is the host copy's provenance note, not part
    # of the value: the two cron lines are byte-identical until one carries
    # "carried from the GitHub schedule on 2026-10-17" after it.
    out, q = [], None
    for ch in v:
        if q:
            out.append(ch)
            if ch == q: q = None
        elif ch in "\"'":
            q = ch; out.append(ch)
        elif ch == "#":
            break
        else:
            out.append(ch)
    return "".join(out).strip()

KEYS = ["model", "max_turns", "entry", "repo", "cron", "webhook",
        "subscriptions", "scopes", "env", "name"]

def read(path):
    try: text = open(path).read()
    except OSError: return None
    d = {}
    for k in KEYS:
        m = re.search(r"^\s*%s\s*=\s*(.+)$" % re.escape(k), text, re.M)
        if m: d[k] = strip_comment(m.group(1))
    return d

def listval(v):
    if v is None: return None
    try: return [str(x) for x in json.loads(v.replace("'", '"'))]
    except Exception: return None

# What a divergence in each field costs, so the report ranks by consequence
# rather than by alphabet. `name` is the one field that differs on purpose:
# the host namespaces every seat by company because one box holds four
# products, and that reason is written here rather than left as a silent
# skip (L62 clause 1 — a field dropped on purpose says why).
GOVERNS = {
 "model":        "the model the run is billed for",
 "max_turns":    "the cap that ends the run",
 "entry":        "the charter the run reads",
 "repo":         "the repository the run writes to",
 "cron":         "when, or whether, the seat wakes on a clock",
 "webhook":      "whether the ingress may wake the seat",
 "subscriptions":"which board events wake the seat",
 "scopes":       "what the seat is allowed to reach",
 "env":          "which names resolve inside the run",
}

declared = sorted(d for d in os.listdir(agents) if os.path.isfile(f"{agents}/{d}/agent.toml"))
try:
    hosted = sorted(d for d in os.listdir(f"{roster}/{company}")
                    if os.path.isfile(f"{roster}/{company}/{d}/agent.toml"))
except OSError:
    print(f"roster.sh: cannot list {roster}/{company} — could not look", file=sys.stderr)
    sys.exit(2)

# Both directions, because the set is two claims and not one. A seat declared
# here and not hosted is a manifest for nobody; a seat hosted and not declared
# here is a seat running against this repository that this repository does not
# describe, and that one is invisible to any walk of `agents/` — which is the
# shape of the first version of this script (L41: the answer a check cannot
# reach must not be spelled like the answer it can).
seats = declared
undeclared = [s for s in hosted if s not in declared]
rows, absent, findings, expected = [], [], 0, 0

for s in seats:
    a = read(f"{agents}/{s}/agent.toml")
    hp = f"{roster}/{company}/{s}/agent.toml"
    b = read(hp)
    if b is None:
        absent.append(s)
        continue
    for k in KEYS:
        va, vb = a.get(k), b.get(k)
        if va == vb: continue
        if k == "name":
            expected += 1
            continue
        la, lb = listval(va), listval(vb)
        extra = short = None
        if la is not None and lb is not None:
            extra = [x for x in la if x not in lb]   # claimed here, absent there
            short = [x for x in lb if x not in la]   # granted there, unclaimed here
        findings += 1
        rows.append({"seat": s, "field": k, "governs": GOVERNS.get(k, ""),
                     "repo": va, "host": vb, "claimed_not_granted": extra,
                     "granted_not_claimed": short})

print(f"read {len(seats)} manifest(s) under {agents}/ against the roster "
      f"{roster}/{company}/ that this box loaded")
print()
if absent:
    print(f"  DECLARED, NOT HOSTED  {len(absent)} seat(s) have a manifest here and "
          f"none in the loaded roster: {', '.join(absent)}")
    print()
if undeclared:
    print(f"  HOSTED, NOT DECLARED  {len(undeclared)} seat(s) run on this box against "
          f"this repository and have no manifest here: {', '.join(undeclared)}")
    print( "        Nothing in `agents/` describes them, so `epito validate`, "
           "cli/test/smoke-roster.sh and every audit that walks this directory "
           "read a smaller company than the one running.")
    print()

if not rows:
    print("no field diverged. Every manifest in this repository describes the seat "
          "the host loaded.")
else:
    order = {k: i for i, k in enumerate(KEYS)}
    for r in sorted(rows, key=lambda r: (order[r["field"]], r["seat"])):
        print(f"  {r['seat']}/{r['field']} — {r['governs']}")
        print(f"      here  {str(r['repo'])[:92]}")
        print(f"      host  {str(r['host'])[:92]}")
        if r["claimed_not_granted"]:
            print(f"      ONLY HERE  {', '.join(r['claimed_not_granted'])}")
            print( "        claimed by the manifest and absent from the running seat, "
                   "which is the dangerous direction: a reader answers yes and the "
                   "runtime answers no (L-X9).")
        if r["granted_not_claimed"]:
            print(f"      ONLY HOST  {', '.join(r['granted_not_claimed'])}")
            print( "        the running seat has it and this repository does not say so, "
                   "so the manifest understates the seat and an audit of blast radius "
                   "reading it is reading a smaller seat than the one that runs.")
        print()

print(f"{findings} divergence(s) on {len(set(r['seat'] for r in rows))} of {len(seats)} "
      f"declared seat(s); {len(undeclared)} hosted seat(s) are not declared here at "
      f"all; {expected} `name` difference(s) not counted, because the host "
      f"namespaces every seat by company and one box holds four products.")
print("`max_turns` and `model` are the only fields cli/test/smoke-roster.sh:194 "
      "compares, and it compares them against the workflow rather than against "
      "this roster, so none of the above is visible to any check in this repository.")

print()
bp, bh = os.environ.get("BIN_PATH",""), os.environ.get("BIN_HEAD","")
bd, bb = os.environ.get("BIN_DATE",""), os.environ.get("BIN_BEHIND","")
bm, bn = os.environ.get("BIN_MISSING",""), os.environ.get("BIN_NOTE","")
if bn and not bp:
    print(f"the binary: {bn}")
elif bp:
    print(f"the binary that hosts these seats is {bp}")
    if bh:
        print(f"  checked out at {bh[:8]} ({bd[:10]}), "
              + (f"**{bb} commits behind origin/main**" if bb else f"distance unknown — {bn}"))
    else:
        print(f"  not a git checkout, so its revision is could-not-look{(' — ' + bn) if bn else ''}")
    if bm:
        miss = bm.split(",")
        print(f"  it refuses {len(miss)} of the 16 commands this repository ships: {', '.join(miss)}")
        print( "  `env` and `doctor` are in that list, and docs/deploy/README.md documents "
               "both — with sample output — as the way to ask this box whether a run would "
               "start and which names it holds. The documented instrument for the question "
               "above is not in the binary the box runs.")
    else:
        print("  it answers every command this repository ships")
print()
print("```data")
print(f"instrument: docs/agents/roster.sh")
print(f"read_at: {datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%dT%H:%MZ')}")
print(f"manifests: {agents}/")
print(f"roster: {roster}/{company}/")
print(f"seats_declared: {len(declared)}")
print(f"seats_hosted: {len(hosted)}")
print(f"declared_not_hosted: {json.dumps(absent)}")
print(f"hosted_not_declared: {json.dumps(undeclared)}")
print(f"divergences: {findings}")
print(f"seats_diverged: {len(set(r['seat'] for r in rows))}")
print(f"fields_diverged: {sorted(set(r['field'] for r in rows))}")
print(f"name_differences_expected: {expected}")
print(f"binary_path: {bp or 'not found'}")
print(f"binary_head: {bh[:8] if bh else 'could-not-look'}")
print(f"binary_committed: {bd[:10] if bd else 'could-not-look'}")
print(f"binary_commits_behind_main: {bb or 'could-not-look'}")
print(f"binary_commands_missing: {json.dumps(bm.split(',') if bm else [])}")
print("```")

sys.exit(1 if (findings or undeclared or absent) else 0)
PY
