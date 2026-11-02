#!/usr/bin/env bash
# Does the manifest in this repository describe the seat the host is running?
# (L63, incident 25.)
#
#   bash docs/agents/roster.sh                  this product against this box
#   bash docs/agents/roster.sh --roster PATH    another box's loaded roster
#   bash docs/agents/roster.sh --company NAME   the roster subdirectory to read
#   bash docs/agents/roster.sh --agents PATH    another repository's manifests
#   bash docs/agents/roster.sh --self-test     the reachability verdict, both ways
#
# Exit 0 nothing diverged, 1 a field diverged OR the running binary is not
# reachable from `origin/main`, 2 could not look (L41).
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
# WHAT THIS SCRIPT USED TO LEAVE OUT, AND WHY THAT ROW IS HERE NOW (L83,
# incident 46). The first version printed `binary_commits_behind_main` and
# nothing else about the running clone, so it measured a distance and implied
# a repair: move the clone to `main`. On 2026-10-27 that repair would have
# been destructive. `/srv/asc/repos/epitome` was detached at a 2026-09-23
# commit, 890 behind `main` and 0 ahead of it, and carried 35 lines of
# UNCOMMITTED hand hotfixes in two files — among them the eighteen lines that
# POST every host run to the company board. Nothing on `main` does that from
# the resident-daemon path, so `git reset --hard origin/main` would have
# blinded every capacity instrument this company owns, and the behind-count
# this script printed could not say so, because uncommitted work is not a
# commit and `rev-list` will never count it.
#
# So the question is not how far behind the clone is. It is whether the
# artifact the box executes exists anywhere a ref can be moved to. Three rows
# answer that — the ref it is on, the commits it holds that `main` does not,
# and the paths dirty in its working tree — and a `no` on the last of them is
# a divergence with its own exit status, because it is the one field whose
# silence turns the obvious fix into an outage.
#
# Reads only: it invokes nothing that writes, and `epito help` is the single
# invocation it makes. No credential, no network.
set -uo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)"

ROSTER=${EPITO_ROSTER:-/srv/asc/roster}
COMPANY=${EPITO_COMPANY:-epitome}
AGENTS=agents
# --self-test fires the reachability verdict in BOTH directions against clones
# it builds, because a branch nobody has seen take the other value is a second
# thing written down (L-X1 as amended, L42). The positive is live on this box
# and needs no fixture; the NEGATIVE is the one this script had no way to show,
# so it is the one constructed here.
#
# The lever is `command -v epito`: the probe resolves the binary off PATH and
# then asks git about the directory it lands in. So a shim on PATH, pointing
# into a clone whose state we chose, exercises the real code path rather than a
# re-implementation of it.
self_test() {
  local t rc fail=0 out
  t=$(mktemp -d) || { echo "self-test: no scratch directory" >&2; return 2; }
  trap 'rm -rf "$t"' RETURN

  # A clean clone of this very checkout: nothing uncommitted, nothing ahead of
  # origin/main. Must read `reachable: yes` and must not be the reason for a 1.
  git clone --quiet --shared . "$t/clean" 2>/dev/null || { echo "self-test: clone failed" >&2; return 2; }
  git -C "$t/clean" remote set-url origin "$(git remote get-url origin)" 2>/dev/null
  git -C "$t/clean" fetch --quiet origin main 2>/dev/null
  git -C "$t/clean" checkout --quiet FETCH_HEAD 2>/dev/null
  # The shim has to RESOLVE INTO the clone, because the probe reads
  # `dirname $(readlink -f $(command -v epito))` and asks git about that
  # directory. Two consequences the first version of this fixture got wrong.
  #
  # It must be executable: `command -v` ignores a file that is not, and
  # `cli/src/index.js` is mode 644 in this repository — it is 755 only on the
  # box, by hand, which is itself one of the two dirty paths this check now
  # reports. Symlinking straight at the tracked file therefore found nothing
  # on PATH and the probe fell through to the real /usr/bin/epito, so the
  # "clean" case was measuring the box and failed for the right reason.
  #
  # And it must not itself dirty the clone, which rules out `chmod +x` on the
  # tracked file. So the stub is an UNTRACKED sibling — invisible to
  # `status --untracked-files=no`, which is the read under test — that execs
  # the real entry point, so `epito help` still answers for real.
  stub() {  # $1 = clone dir, $2 = bin dir
    mkdir -p "$2"
    printf '#!/bin/sh\nexec node "%s/cli/src/index.js" "$@"\n' "$1" > "$1/cli/src/.roster-selftest-epito"
    chmod +x "$1/cli/src/.roster-selftest-epito"
    ln -sf "$1/cli/src/.roster-selftest-epito" "$2/epito"
  }
  stub "$t/clean" "$t/bin-clean"

  # The same clone with one line of uncommitted work in a TRACKED file. Must
  # read `reachable: no` and must exit 1 on that ground.
  cp -a "$t/clean" "$t/dirty"
  printf '\n// self-test scratch\n' >> "$t/dirty/cli/src/index.js"
  stub "$t/dirty" "$t/bin-dirty"

  check() {  # $1 label, $2 PATH prefix, $3 expected reachable, $4 expected-in-exit
    out=$(PATH="$2:$PATH" bash "${BASH_SOURCE[0]}" 2>/dev/null); rc=$?
    local got; got=$(printf '%s\n' "$out" | sed -n 's/^binary_reachable_from_main: //p')
    if [ "$got" = "$3" ]; then printf 'ok   %-28s reachable=%s exit=%s\n' "$1" "$got" "$rc"
    else printf 'FAIL %-28s reachable=%s want=%s exit=%s\n' "$1" "${got:-<absent>}" "$3" "$rc"; fail=1; fi
  }
  check "clean clone" "$t/bin-clean" yes
  check "one uncommitted file"  "$t/bin-dirty" no

  # And the exit status, on the dirty case, with the rest of the object held
  # constant: both runs saw the same manifests and the same roster, so any
  # difference in exit between them is this clause and nothing else.
  PATH="$t/bin-clean:$PATH" bash "${BASH_SOURCE[0]}" >/dev/null 2>&1; local a=$?
  PATH="$t/bin-dirty:$PATH" bash "${BASH_SOURCE[0]}" >/dev/null 2>&1; local b=$?
  if [ "$b" = 1 ]; then printf 'ok   %-28s exit=1 (clean clone exited %s)\n' "dirty clone exits 1" "$a"
  else printf 'FAIL %-28s exit=%s want=1\n' "dirty clone exits 1" "$b"; fail=1; fi
  # NOTE on the clean run: this product's manifests diverge from the roster on
  # four fields today, so the clean run exits 1 as well, on THOSE grounds. The
  # assertion above is about the verdict row, which is the field under test;
  # the exit comparison is printed rather than asserted because this box
  # cannot currently supply an otherwise-clean object to assert against, and
  # saying so is cheaper than an assertion that would pass for a second reason
  # (L63 clause 2, this script's own rule).
  return $fail
}

while [ $# -gt 0 ]; do
  case "$1" in
    --roster)  ROSTER=${2:?--roster needs a path};  shift 2 ;;
    --company) COMPANY=${2:?--company needs a name}; shift 2 ;;
    --agents)  AGENTS=${2:?--agents needs a path};  shift 2 ;;
    --help|-h) sed -n '2,/^[^#]/p' "${BASH_SOURCE[0]}" | sed -n 's/^# \{0,1\}//p'; exit 0 ;;
    --self-test) self_test; exit $? ;;
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
BIN_REF=; BIN_AHEAD=; BIN_DIRTY=
BIN_FRAME=; BIN_MAIN=; BIN_MAIN_SHA=; BIN_ANCESTOR=; BIN_FRAME_SHALLOW=

# WHICH REPOSITORY ANSWERS THE DISTANCE. The first version asked this one, and
# gated the whole read on `git rev-parse --is-shallow-repository` with no `-C`
# — the shallowness of the *invoking* checkout, which is a fact about the clone
# the runtime handed this run and not a fact about the binary. Every resident
# run gets a shallow clone (16 commits on 2026-10-27), so the row read
# `could-not-look` on every run that mattered, and the self-test's clean case
# failed against its own fixture. The box only ever answered `no` by accident:
# `breach` falls out of the dirty-path list when the ahead-count is absent, and
# the executing clone has been dirty since 2026-09-23 (incident 46). A clean
# box would have been could-not-look and nobody would have known.
#
# Shallowness is also not what makes a count wrong — a CUT WALK is, and the two
# are not the same test. The fixture clone is shallow to one commit and answers
# 0/0 exactly. The executing clone is shallow to 883 and answers exactly too.
# This checkout is shallow in the way that matters: `git merge-base 5836dc0b
# 8ea243ca` returns nothing here, because the artifact predates the graft, and
# every count taken across that cut is a fabrication rather than a shortfall.
# Measured 2026-10-27, all three frames on this box, against incident 46's own
# reading of the clone from a frame with history:
#
#     frame               shallow  merge-base  behind  ahead  ancestor
#     this checkout       yes      (empty)     1       64     no      <- all wrong
#     /srv/asc/repos/...  yes      5836dc0b    883     0      yes     <- right
#
# A cut hides commits from `main`'s reachable set, so it UNDERSTATES behind and
# OVERSTATES ahead, and `ahead` is the field the destructive-repair warning is
# written off. The first version of this row would have told a reader that the
# box holds 64 commits `main` does not. It holds none.
#
# So: a frame answers only if it holds both endpoints AND `merge-base` finds a
# base, which is the one cheap question whose answer is a fact about the walk
# rather than about the clone. Candidates in order, the first that qualifies
# wins, and the frame that answered is printed — a count whose frame is unnamed
# cannot be refuted by the seat it describes (L24, L83).
bin_frame() {  # $1 = repository to count in; sets BIN_* on success
  local r=$1 m base
  git -C "$r" cat-file -e "${BIN_HEAD}^{commit}" 2>/dev/null || return 1
  for m in refs/remotes/origin/main refs/heads/main; do
    git -C "$r" rev-parse --verify --quiet "$m" >/dev/null 2>&1 || continue
    base=$(git -C "$r" merge-base "$BIN_HEAD" "$m" 2>/dev/null)
    [ -n "$base" ] || continue   # the walk is cut: this frame cannot answer
    BIN_FRAME=$r; BIN_MAIN=$m
    BIN_MAIN_SHA=$(git -C "$r" rev-parse "$m" 2>/dev/null)
    BIN_BEHIND=$(git -C "$r" rev-list --count "$BIN_HEAD..$m" 2>/dev/null)
    BIN_AHEAD=$(git -C "$r" rev-list --count "$m..$BIN_HEAD" 2>/dev/null)
    # Reachability direct, rather than inferred from the ahead-count: it is the
    # field the verdict row asserts, and inferring it from an absent count is
    # what read `could-not-look` on every shallow clone this runtime hands out.
    if git -C "$r" merge-base --is-ancestor "$BIN_HEAD" "$m" 2>/dev/null
      then BIN_ANCESTOR=yes; else BIN_ANCESTOR=no; fi
    [ "$(git -C "$r" rev-parse --is-shallow-repository 2>/dev/null)" = true ] \
      && BIN_FRAME_SHALLOW=yes || BIN_FRAME_SHALLOW=no
    return 0
  done
  return 1
}

if command -v epito >/dev/null 2>&1; then
  BIN_PATH=$(readlink -f "$(command -v epito)" 2>/dev/null)
  bindir=$(dirname "$BIN_PATH" 2>/dev/null)
  BIN_HEAD=$(git -C "$bindir" rev-parse HEAD 2>/dev/null)
  if [ -n "$BIN_HEAD" ]; then
    BIN_DATE=$(git -C "$bindir" show -s --format=%cI "$BIN_HEAD" 2>/dev/null)
    # This checkout first, because its `origin/main` was fetched minutes ago;
    # then the executing clone, which holds the artifact by construction but
    # whose `origin/main` is whatever it last fetched. Reading a stale main
    # would understate the distance, so the frame's own main sha is printed and
    # the staleness is computed against this checkout's rather than assumed.
    bin_frame . || bin_frame "$bindir" || \
      BIN_NOTE="no frame here can walk between ${BIN_HEAD:0:8} and a \`main\` ref — this checkout is grafted above the artifact and the executing clone has no \`main\` — so the distance is could-not-look, which is a reading and not a clean bill (L41)"
    # The ref it sits on, because a carve-out in a deploy path is usually
    # written as "that one is on its own branch" and nothing re-reads the
    # claim. `rev-parse --abbrev-ref` answers the literal `HEAD` when the
    # checkout is detached, which is what `provision-host.sh` leaves behind.
    BIN_REF=$(git -C "$bindir" rev-parse --abbrev-ref HEAD 2>/dev/null)
    # Uncommitted work in the executing clone. Read from the clone itself,
    # never from this one: `git status` here says nothing about the box.
    BIN_DIRTY=$(git -C "$bindir" status --porcelain --untracked-files=no 2>/dev/null \
                 | awk '{print $NF}' | paste -sd, -)
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
BIN_BEHIND="$BIN_BEHIND" BIN_MISSING="$BIN_MISSING" BIN_NOTE="$BIN_NOTE" \
BIN_REF="$BIN_REF" BIN_AHEAD="$BIN_AHEAD" BIN_DIRTY="$BIN_DIRTY" \
BIN_FRAME="$BIN_FRAME" BIN_MAIN="$BIN_MAIN" BIN_MAIN_SHA="$BIN_MAIN_SHA" \
BIN_ANCESTOR="$BIN_ANCESTOR" BIN_FRAME_SHALLOW="$BIN_FRAME_SHALLOW" \
HERE_MAIN_SHA="$(git rev-parse --verify --quiet refs/remotes/origin/main 2>/dev/null)" \
python3 - <<'PY'
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
bref = os.environ.get("BIN_REF","")
bahead = os.environ.get("BIN_AHEAD","")
bdirty = [x for x in os.environ.get("BIN_DIRTY","").split(",") if x]
bframe = os.environ.get("BIN_FRAME","")
bmain, bmainsha = os.environ.get("BIN_MAIN",""), os.environ.get("BIN_MAIN_SHA","")
banc = os.environ.get("BIN_ANCESTOR","")
bfshallow = os.environ.get("BIN_FRAME_SHALLOW","")
heremain = os.environ.get("HERE_MAIN_SHA","")
# The frame's `main` against the one this run fetched. A frame behind the true
# main understates every distance it reports, so the comparison is printed
# rather than trusted; when it differs the behind-count is a lower bound.
bstale = bool(bmainsha and heremain and bmainsha != heremain)
# Reachable means: a ref can be moved to this artifact. Ancestry answers the
# commit half directly — inferring it from an absent ahead-count is what read
# `could-not-look` on every shallow clone — and a dirty working tree makes it
# false on its own, which is the half no commit count can express.
breach = None
if bp and bh and (banc or bdirty):
    breach = not (bdirty or banc == "no")
if bn and not bp:
    print(f"the binary: {bn}")
elif bp:
    print(f"the binary that hosts these seats is {bp}")
    if bh:
        print(f"  checked out at {bh[:8]} ({bd[:10]}), "
              + (f"**{bb} commits behind `{bmain}`**" if bb else f"distance unknown — {bn}"))
        if bb and (bstale or bfshallow == "yes"):
            why = []
            if bstale:
                why.append(f"its {bmain} is {bmainsha[:8]} while this run fetched "
                           f"{heremain[:8]}")
            if bfshallow == "yes":
                why.append("it is shallow")
            print(f"  counted in `{bframe}` — {', and '.join(why)} — so {bb} is a LOWER "
                  f"BOUND on the distance and {bahead} is an UPPER BOUND on what it holds "
                  "alone. The frame found a merge-base, so the reachability verdict below "
                  "is a fact and only the two numbers are bounds")
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
    if bref:
        print(f"  its HEAD is on `{bref}`"
              + (" — detached, so it is on no branch of its own"
                 if bref == "HEAD" else ""))
    if breach is False:
        print( "  **and it is not reachable from `origin/main`**, so moving a ref there "
               "does not reproduce it:")
        if bahead.isdigit() and int(bahead) > 0:
            print(f"    {bahead} commit(s) it holds that `origin/main` does not"
                  + (" — an upper bound, from a shallow frame; diff before you believe it"
                     if bfshallow == "yes" else ""))
        if bdirty:
            print(f"    {len(bdirty)} file(s) uncommitted in its working tree: "
                  + ", ".join(bdirty))
        print( "    A `git reset --hard origin/main` on this clone deletes that work. "
               "Diff each path against `origin/main` and say which side has it before "
               "anyone routes an update; the behind-count above is the cheap direction "
               "and this is the one that makes the repair destructive (L83).")
    elif breach is True:
        print("  it is reachable from `origin/main`: nothing uncommitted, nothing ahead")
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
print(f"binary_ref: {bref or 'could-not-look'}")
print(f"binary_commits_behind_main: {bb or 'could-not-look'}")
print(f"binary_commits_ahead_main: {bahead if bahead != '' else 'could-not-look'}")
print(f"binary_distance_frame: {bframe or 'none-answered'}")
print(f"binary_distance_main_ref: {bmain or 'could-not-look'}")
print(f"binary_distance_main_sha: {bmainsha[:8] if bmainsha else 'could-not-look'}")
print(f"binary_distance_frame_shallow: {bfshallow or 'could-not-look'}")
print(f"binary_distance_frame_stale: {'yes' if bstale else ('no' if bmainsha and heremain else 'could-not-look')}")
print(f"binary_is_ancestor_of_main: {banc or 'could-not-look'}")
print(f"binary_uncommitted: {json.dumps(bdirty)}")
print(f"binary_reachable_from_main: "
      f"{'could-not-look' if breach is None else ('yes' if breach else 'no')}")
print(f"binary_commands_missing: {json.dumps(bm.split(',') if bm else [])}")
print("```")

# An unreproducible running artifact is a divergence of this check's object,
# not a footnote about it: it is the field whose silence turned the obvious
# repair into an outage (L83, incident 46).
sys.exit(1 if (findings or undeclared or absent or breach is False) else 0)
PY
