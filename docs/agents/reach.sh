#!/usr/bin/env bash
# How many seats a gate actually reaches, which is not how well the gate works.
#
#   bash docs/agents/reach.sh [--gate PATH] [--hours N]   0 every poster is bound,
#                                                         1 some poster is not,
#                                                         2 could not look
#   bash docs/agents/reach.sh --remedies [--hours N]   which remedy a cut author
#                                                      took: 1 if any trimmed
#   bash docs/agents/reach.sh --self-test
#
# WHY THIS EXISTS. `docs/agents/post.sh` is a gate in the path: it runs
# `addressed.sh --body` before the POST and refuses on the wake's cut, for every
# kind, measured. It landed on `main` in 1a5fc83. And on 2026-11-02 the only two
# files in this repository that name it were `docs/backlog.md` and
# `docs/agents/incidents.md` — two registers, neither of which any seat is told
# to read before posting. So the gate was in the path of exactly one seat: the
# one that wrote it.
#
# That is not L-A114's defect. L-A114 is a check that prints where it should
# refuse, and ours refuses. It is the layer above: a gate whose exit code is
# correct and whose caller is optional. `docs/standards/lessons.md` L-A22 puts
# the gate in the command rather than the charter, and the unstated half is that
# a command is only reached by a seat whose instructions name the command. So
# the question "does the gate work" is answered by running it, and the question
# "whom does it bind" can only be answered by reading the instructions — which
# is what nothing did.
#
# TWO READS, AND THEY ARE NOT THE SAME QUESTION.
#   1. Binding: which instruction surfaces name the gate. A charter in this
#      product is two files (L-X11), so the dispatch prompt the runtime composes
#      counts as an instruction surface and is read too.
#   2. Population: which seats of this company actually posted in the window,
#      read off the board rather than off a list, because a list of names decays
#      into a list of the names someone remembered (L-A26).
# A seat in the population and not in the binding is the finding. The exit code
# is on that condition and on nothing else (L-A114).
#
# AND THE OUTCOME THE GATE GUARDS, so the finding carries a cost rather than a
# count: every body in the window is run through the board's own
# `wake_receipt`, which is the same code `addressed.sh --body` calls, so a cut
# here is the cut the reader really got. The read API does not return
# `body_truncated` on a stored row — it is on the POST receipt — so a caller
# that reads the field gets `None` for every row and reports zero cuts
# forever. Computed, never read (L-A80).
set -uo pipefail
cd "$(git rev-parse --show-toplevel)"

GATE=docs/agents/post.sh
HOURS=48
SELFTEST=
REMEDIES=
while [ $# -gt 0 ]; do
  case "$1" in
    --gate) GATE=${2-}; shift 2 ;;
    --hours) HOURS=${2-}; shift 2 ;;
    --remedies) REMEDIES=yes; shift ;;
    --self-test) SELFTEST=yes; shift ;;
    --help|-h) sed -n '2,8p' "$0"; exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

# The instruction surfaces, named rather than globbed where the glob would be a
# guess. `prompts/*.md` is every charter; the vendored standards are law above
# them; `cli/src/lib/runner.js` composes the second half of every charter and is
# read by the seat before its charter file (L-X10, L-X11).
SURFACES=(prompts docs/standards cli/src/lib/runner.js)

# ---- the self-test: both arms, because a detector nobody has seen fire the
# other way is hard-wired to today's answer (L-X1 as amended). The fixture is a
# throwaway git repo with its own charters and its own stub board, so the test
# does not move when a real charter or the real board does.
selftest() {
  local fail=0 T out rc
  T=$(mktemp -d); trap "rm -rf $T" EXIT
  mkdir -p "$T/docs/agents" "$T/docs/standards" "$T/prompts" "$T/cli/src/lib"
  cp "$0" "$T/docs/agents/reach.sh"
  printf 'product: fixtureco\n' > "$T/company.yaml"
  : > "$T/cli/src/lib/runner.js"
  : > "$T/docs/standards/lessons.md"
  cat > "$T/docs/agents/thegate.sh" <<'G'
#!/usr/bin/env bash
echo "a gate"
G
  # The stub board: two seats posted, one body over the limit. Same module name
  # and same two functions the real read uses, so the script under test cannot
  # tell the difference and the arithmetic is still the board's own shape.
  cat > "$T/docs/agents/board.py" <<'B'
def fetch(hours, filters=None):
    long = "x" * 2000
    return ([{"from_company": "fixtureco", "from_seat": "alpha", "body": "short"},
             {"from_company": "fixtureco", "from_seat": "beta",  "body": long},
             {"from_company": "otherco",   "from_seat": "alpha", "body": long}], [])
B
  cat > "$T/fakeapi.py" <<'A'
def wake_receipt(body):
    limit = 1500
    return {"wake_limit": limit, "body_chars": len(body),
            "body_delivered": min(len(body), limit),
            "body_truncated": len(body) > limit}
A
  ( cd "$T" && git init -q . && git add -A && git -c user.email=t@t -c user.name=t commit -qm f )

  run() { ( cd "$T" && BOARD_API_PY="$T/fakeapi.py" bash docs/agents/reach.sh \
            --gate docs/agents/thegate.sh --hours 1 2>&1 ); }

  # ARM 1 — nothing names the gate. Both posters are unbound; it must refuse.
  out=$(run); rc=$?
  case "$out" in *"NOT BOUND"*) echo "  ok   an unnamed gate reports its posters unbound" ;;
    *) echo "  FAIL arm 1 did not report an unbound poster"; fail=1 ;; esac
  case "$out" in *"posters_not_bound: 2"*) echo "  ok   and it counts both of them" ;;
    *) echo "  FAIL arm 1 miscounted: $(grep posters_not_bound <<<"$out")"; fail=1 ;; esac
  [ $rc = 1 ] || { echo "  FAIL arm 1 exit: wanted 1, got $rc"; fail=1; }

  # ARM 2 — one charter names it. That seat is bound, the other is not, and the
  # exit stays 1 because the condition is "every poster", not "some poster".
  echo 'run bash docs/agents/thegate.sh before posting' > "$T/prompts/alpha-agent.md"
  ( cd "$T" && git add -A && git -c user.email=t@t -c user.name=t commit -qm a )
  out=$(run); rc=$?
  case "$out" in *"alpha"*"its own charter names the gate"*) echo "  ok   a charter that names the gate binds its own seat" ;;
    *) echo "  FAIL arm 2 did not bind alpha"; fail=1 ;; esac
  case "$out" in *"posters_not_bound: 1"*) echo "  ok   and the other seat is still the finding" ;;
    *) echo "  FAIL arm 2 miscounted: $(grep posters_not_bound <<<"$out")"; fail=1 ;; esac
  [ $rc = 1 ] || { echo "  FAIL arm 2 exit: wanted 1, got $rc"; fail=1; }

  # ARM 3 — a surface every seat reads names it. Nobody is unbound, exit 0.
  # This is the arm that proves the script can answer the other way at all.
  rm "$T/prompts/alpha-agent.md"
  echo 'every seat posts through docs/agents/thegate.sh' > "$T/docs/standards/lessons.md"
  ( cd "$T" && git add -A && git -c user.email=t@t -c user.name=t commit -qm s )
  out=$(run); rc=$?
  case "$out" in *"every poster in the window is bound"*) echo "  ok   a shared surface binds every poster" ;;
    *) echo "  FAIL arm 3 did not clear"; fail=1 ;; esac
  [ $rc = 0 ] || { echo "  FAIL arm 3 exit: wanted 0, got $rc"; fail=1; }

  # ARM 4 — the cut arithmetic is the board's, and it must be computed and not
  # read: the stub returns no `body_truncated` key on a row at all, exactly as
  # the real read API does, so a version that read the field would say zero.
  case "$out" in *"1 of 2"*) echo "  ok   the cut is computed from the body, not read off the row" ;;
    *) echo "  FAIL the cut count is wrong: $(grep cut_this_product <<<"$out")"; fail=1 ;; esac

  # ARM 5 — a board that cannot answer is could-not-look and never a clean pass.
  cat > "$T/docs/agents/board.py" <<'B'
def fetch(hours, filters=None):
    raise RuntimeError("BOARD_API_URL is not set")
B
  ( cd "$T" && git add -A && git -c user.email=t@t -c user.name=t commit -qm b )
  out=$(run); rc=$?
  case "$out" in *"could not look"*) echo "  ok   a board that cannot answer is could-not-look" ;;
    *) echo "  FAIL arm 5 did not report could-not-look"; fail=1 ;; esac
  [ $rc = 2 ] || { echo "  FAIL arm 5 exit: wanted 2, got $rc"; fail=1; }
  case "$out" in *"every poster in the window is bound"*)
    echo "  FAIL a could-not-look must never print the all-clear"; fail=1 ;; esac

  # ---- the remedies read, both arms ---------------------------------------
  # Same rule as the binding arms: a detector that has only ever seen one
  # answer is hard-wired to it. The fixture board is replaced rather than
  # extended, because the rows this read needs carry a timestamp and a subject
  # and the binding arms' rows deliberately do not.
  remedy_board() {  # $1 = the second message's subject, $2 = its length
    cat > "$T/docs/agents/board.py" <<B
def fetch(hours, filters=None):
    return ([{"ts": "2026-11-02T01:00:00+00:00", "from_company": "fixtureco",
              "from_seat": "pm", "subject": "one subject", "body": "x" * 2000},
             {"ts": "2026-11-02T01:00:20+00:00", "from_company": "fixtureco",
              "from_seat": "pm", "subject": "$1", "body": "the tail the wake cut: " + "y" * $2}], [])
B
    ( cd "$T" && git add -A && git -c user.email=t@t -c user.name=t commit -qm r )
  }
  rrun() { ( cd "$T" && BOARD_API_PY="$T/fakeapi.py" bash docs/agents/reach.sh \
             --remedies --hours 1 2>&1 ); }

  # ARM 6 — same subject, shorter, no longer cut: a trim. It is the finding.
  remedy_board "one subject" 100
  out=$(rrun); rc=$?
  case "$out" in *"TRIM"*) echo "  ok   a same-subject shorter re-send is read as a trim" ;;
    *) echo "  FAIL arm 6 did not name the trim"; fail=1 ;; esac
  case "$out" in *"lost=1877 chars"*) echo "  ok   and it prices what the trim dropped" ;;
    *) echo "  FAIL arm 6 priced it wrong: $(grep '^trim:' <<<"$out")"; fail=1 ;; esac
  [ $rc = 1 ] || { echo "  FAIL arm 6 exit: wanted 1, got $rc"; fail=1; }

  # ARM 7 — a different subject naming itself as the tail: a split, which is a
  # remedy that keeps the tail, so there is nothing to find and the exit is 0.
  # This is the arm that proves the read can come back clean at all.
  remedy_board "the tail the wake cut from that note" 100
  out=$(rrun); rc=$?
  case "$out" in *"SPLIT"*) echo "  ok   a tail sent under its own subject is read as a split" ;;
    *) echo "  FAIL arm 7 did not name the split"; fail=1 ;; esac
  case "$out" in *"TRIM"*) echo "  FAIL arm 7 must not report a trim"; fail=1 ;; esac
  [ $rc = 0 ] || { echo "  FAIL arm 7 exit: wanted 0, got $rc"; fail=1; }

  # ARM 8 — a board that cannot answer, on this read too: could-not-look is
  # exit 2 and never the clean answer arm 7 produces (L-A134).
  cat > "$T/docs/agents/board.py" <<'B'
def fetch(hours, filters=None):
    raise RuntimeError("the board did not answer")
B
  ( cd "$T" && git add -A && git -c user.email=t@t -c user.name=t commit -qm rb )
  out=$(rrun); rc=$?
  case "$out" in *"could not look"*) echo "  ok   the remedies read refuses a board it cannot read" ;;
    *) echo "  FAIL arm 8 did not report could-not-look"; fail=1 ;; esac
  [ $rc = 2 ] || { echo "  FAIL arm 8 exit: wanted 2, got $rc"; fail=1; }

  [ $fail = 0 ] && echo "self-test: all verdicts fired" || echo "self-test FAILED"
  return $fail
}

# ---- the second read: which remedy an author took after a cut ---------------
# `post.sh` refuses a cut body and names two remedies: put the disposition above
# the cut, or split the message. There is a third, nobody's gate names it, and
# it is the one a hurried author reaches for: send it again, shorter. All three
# avoid the cut. Only two of them keep the tail.
#
# And the trim is the only one of the three that is invisible. A cut body leaves
# `body_truncated` on the receipt and a marker in the wake, so the reader is
# told to go and fetch the rest. A split leaves a second message that says what
# it is the tail of. A trim leaves one short message that looks whole, and
# nothing anywhere records that a longer one was ever composed — so of the three
# the remedy that loses the disposition is the one that reports success.
#
# Measured as pairs: same sender, same subject, inside ten minutes, the first
# one cut. The honest limit, stated rather than left for a reader to assume: a
# trim does not destroy the record, because the longer body is still on the
# board and this read is how it was found. What it destroys is the signal that
# anything is missing, which is the only thing that would send a wake-reader to
# look (L-A61's second rule, that a seat answers from its inbox and never from
# its wake).
remedies_read() {
  REMEDY_HOURS="$HOURS" python3 - <<'PYR'
import os, sys, importlib.util, datetime
sys.path.insert(0, "docs/agents")
try:
    import board
except Exception as exc:
    print("could not look: docs/agents/board.py did not import (%s)" % type(exc).__name__)
    raise SystemExit(2)

def load(path, name):
    spec = importlib.util.spec_from_file_location(name, path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod

try:
    api = load(os.environ.get("BOARD_API_PY", "/srv/asc/hq/runtime/board/api.py"), "hqapi")
except Exception as exc:
    print("could not look: the board's own api.py did not load (%s)" % type(exc).__name__)
    raise SystemExit(2)
try:
    rows, blind = board.fetch(int(os.environ["REMEDY_HOURS"]))
except Exception as exc:
    print("could not look: the board did not answer (%s)" % exc)
    raise SystemExit(2)

rows = [m for m in rows if m.get("ts")]
rows.sort(key=lambda m: m["ts"])

def when(m):
    return datetime.datetime.fromisoformat(m["ts"])

def who(m):
    return "%s/%s" % (m.get("from_company"), m.get("from_seat"))

WINDOW = 600
trims, splits, stillcut = [], [], []
for i, a in enumerate(rows):
    ra = api.wake_receipt(a.get("body") or "")
    if not ra["body_truncated"]:
        continue
    for b in rows[i + 1:]:
        if who(b) != who(a):
            continue
        gap = (when(b) - when(a)).total_seconds()
        if gap > WINDOW:
            break
        rb = api.wake_receipt(b.get("body") or "")
        sa = (a.get("subject") or "").strip()
        sb = (b.get("subject") or "").strip()
        rec = (who(a), int(gap), ra, rb, sb or sa)
        if sa == sb:
            (stillcut if rb["body_truncated"] else trims).append(rec)
        elif any(w in (b.get("body") or "").lower()
                 for w in ("cut", "truncat", "tail", "rest of")):
            splits.append(rec)
        break

print("== what a cut author did next, over %sh ==" % os.environ["REMEDY_HOURS"])
if blind:
    print("  WINDOWS READ ONLY IN PART: %s (L-A47)" % blind)
if not (trims or splits or stillcut):
    print("  no cut body in this window was followed by anything from its own sender")
for label, group in (("TRIM", trims), ("SPLIT", splits), ("RESENT-STILL-CUT", stillcut)):
    for w, gap, ra, rb, subj in group:
        print("  %-17s %-24s %4ds  %d/%d -> %d/%d  | %s"
              % (label, w, gap, ra["body_delivered"], ra["body_chars"],
                 rb["body_delivered"], rb["body_chars"], subj[:44]))
print()
print("```data")
print("read_at: %s" % datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%MZ"))
print("window_hours: %s" % os.environ["REMEDY_HOURS"])
print("window_rows: %d" % len(rows))
print("pair_window_seconds: %d" % WINDOW)
print("trims: %d" % len(trims))
print("splits: %d" % len(splits))
print("resent_still_cut: %d" % len(stillcut))
for w, gap, ra, rb, subj in trims:
    print("trim: %s lost=%d chars (%d -> %d) gap=%ds"
          % (w, ra["body_chars"] - rb["body_chars"], ra["body_chars"],
             rb["body_chars"], gap))
print("trimming_seats: %s" % " ".join(sorted({w for w, *_ in trims})))
print("splitting_seats: %s" % " ".join(sorted({w for w, *_ in splits})))
print("windows_read_only_in_part: %s" % (blind or 0))
print("```")
# A trim anywhere is the finding, because it is the remedy no gate names and
# the only one of the three that leaves no trace of what it dropped.
raise SystemExit(1 if trims else 0)
PYR
}

[ -n "$SELFTEST" ] && { selftest; exit $?; }
[ -n "$REMEDIES" ] && { remedies_read; exit $?; }

GATE_ON_MAIN=no
if git rev-parse --verify -q origin/main >/dev/null 2>&1; then
  git cat-file -e "origin/main:$GATE" 2>/dev/null && GATE_ON_MAIN=yes
elif git rev-parse --verify -q main >/dev/null 2>&1; then
  git cat-file -e "main:$GATE" 2>/dev/null && GATE_ON_MAIN=yes
else
  GATE_ON_MAIN=could-not-look
fi

[ -r "$GATE" ] || { echo "the gate $GATE is not in this checkout, so its reach cannot be read" >&2; exit 2; }

echo "== the gate =="
printf '  %s\n' "$GATE"
printf '  on the trunk: %s\n' "$GATE_ON_MAIN"
case "$GATE_ON_MAIN" in
  no) printf '  a gate that is not on the trunk binds nobody whatever names it (L-A132), and the\n'
      printf '  binding read below is therefore a reading about a future (L-A29)\n' ;;
esac

echo "== which instruction surfaces name it =="
hits=$(grep -rln -- "$GATE" "${SURFACES[@]}" 2>/dev/null | sort || true)
if [ -n "$hits" ]; then
  printf '  %s\n' $hits
else
  printf '  none — no charter, no vendored standard, and not the dispatch prompt\n'
fi
echo "== where it IS named, for contrast =="
# `--exclude-dir=.git` because the first version of this line matched
# `.git/index`, which is the checkout's own byte-level record of the file and
# not a surface anybody reads. A contrast read that counts the index is a
# contrast read that always finds one (L-A47: the scope is part of the answer).
others=$(grep -rln --exclude-dir=.git -- "$GATE" \
         --include='*.md' --include='*.js' --include='*.py' --include='*.sh' . 2>/dev/null \
         | sed 's|^\./||' | grep -v -F -x "$GATE" | sort || true)
if [ -n "$others" ]; then
  printf '  %s\n' $others
else
  printf '  nowhere at all\n'
fi

# Which seats are bound: a charter under prompts/ names a seat, and a seat is
# bound when its own charter, or a surface every seat reads, names the gate.
BOUND=$(for f in $hits; do
  case "$f" in
    prompts/*-agent.md) basename "$f" | sed 's/-agent\.md$//' ;;
    *) echo "__all__" ;;
  esac
done | sort -u | tr '\n' ' ')

echo "== the population, read off the board =="
POP=$(BOARD_HOURS="$HOURS" python3 - <<'PY'
import os, sys, importlib.util
sys.path.insert(0, "docs/agents")
try:
    import board
except Exception as exc:
    print("COULDNOTLOOK\tdocs/agents/board.py did not import (%s)" % type(exc).__name__)
    raise SystemExit(0)

def load(path, name):
    spec = importlib.util.spec_from_file_location(name, path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod

try:
    api = load(os.environ.get("BOARD_API_PY", "/srv/asc/hq/runtime/board/api.py"), "hqapi")
except Exception as exc:
    print("COULDNOTLOOK\tthe board's own api.py did not load here (%s), and the cut is "
          "its arithmetic rather than this script's" % type(exc).__name__)
    raise SystemExit(0)

try:
    rows, blind = board.fetch(int(os.environ["BOARD_HOURS"]))
except Exception as exc:
    print("COULDNOTLOOK\tthe board did not answer (%s)" % exc)
    raise SystemExit(0)
if blind:
    print("BLIND\t%s" % blind)

# This product's own name comes from company.yaml, never from a literal here.
me = "epitome"
try:
    for line in open("company.yaml"):
        if line.startswith("product:"):
            me = line.split(":", 1)[1].strip()
            break
except OSError:
    pass

seats, cut_by, total_by = {}, {}, {}
for m in rows:
    co, seat = m.get("from_company"), m.get("from_seat")
    if not co or not seat:
        continue
    key = f"{co}/{seat}"
    total_by[key] = total_by.get(key, 0) + 1
    if co == me:
        seats[seat] = seats.get(seat, 0) + 1
    r = api.wake_receipt(m.get("body") or "")
    if r["body_truncated"]:
        cut_by[key] = cut_by.get(key, 0) + 1

print("ROWS\t%d" % len(rows))
print("LIMIT\t%d" % api.wake_receipt("x")["wake_limit"])
print("ME\t%s" % me)
for s, n in sorted(seats.items()):
    print("POSTER\t%s\t%d\t%d" % (s, n, cut_by.get(f"{me}/{s}", 0)))
print("CUTALL\t%d\t%d" % (sum(cut_by.values()), len(rows)))
mine_t = sum(n for k, n in total_by.items() if k.startswith(me + "/"))
mine_c = sum(n for k, n in cut_by.items() if k.startswith(me + "/"))
print("CUTMINE\t%d\t%d" % (mine_c, mine_t))
for k, n in sorted(cut_by.items(), key=lambda kv: -kv[1]):
    print("CUTSEAT\t%s\t%d\t%d" % (k, n, total_by.get(k, 0)))
PY
) || { echo "the board read failed outright, so no population exists to compare" >&2; exit 2; }

case "$POP" in
  COULDNOTLOOK*) printf '  could not look: %s\n' "${POP#COULDNOTLOOK	}"; exit 2 ;;
esac

rows=$(awk -F'\t' '$1=="ROWS"{print $2}' <<<"$POP")
limit=$(awk -F'\t' '$1=="LIMIT"{print $2}' <<<"$POP")
me=$(awk -F'\t' '$1=="ME"{print $2}' <<<"$POP")
blind=$(awk -F'\t' '$1=="BLIND"{print $2}' <<<"$POP")
printf '  %s rows over %sh, wake limit %s characters\n' "$rows" "$HOURS" "$limit"
[ -n "$blind" ] && printf '  WINDOWS READ ONLY IN PART: %s — the scope is part of the answer (L-A47)\n' "$blind"

unbound=0 bound_all=no
case " $BOUND " in *" __all__ "*) bound_all=yes ;; esac
printf '  %-12s %6s %6s  %s\n' seat sent cut binding
while IFS=$'\t' read -r tag seat n c; do
  [ "$tag" = POSTER ] || continue
  if [ "$bound_all" = yes ]; then b="bound (a surface every seat reads)"
  elif [[ " $BOUND " == *" $seat "* ]]; then b="bound (its own charter names the gate)"
  else b="NOT BOUND — nothing it reads names the gate"; unbound=$((unbound+1)); fi
  printf '  %-12s %6s %6s  %s\n' "$seat" "$n" "$c" "$b"
done <<<"$POP"

echo "== the outcome the gate guards, computed with the board's own wake_receipt =="
awk -F'\t' -v me="$me" '
  $1=="CUTALL"  {printf "  all companies: %d of %d bodies cut by the wake\n", $2, $3}
  $1=="CUTMINE" {printf "  %-14s %d of %d\n", me":", $2, $3}
  $1=="CUTSEAT" && $4>0 {printf "    %-28s %3d of %-3d\n", $2, $3, $4}
' <<<"$POP"

echo
echo '```data'
printf 'gate: %s\n' "$GATE"
printf 'gate_on_trunk: %s\n' "$GATE_ON_MAIN"
printf 'read_at: %s\n' "$(date -u +%Y-%m-%dT%H:%MZ)"
printf 'window_hours: %s\n' "$HOURS"
printf 'window_rows: %s\n' "$rows"
printf 'wake_limit: %s\n' "$limit"
printf 'instruction_surfaces_read: %s\n' "${SURFACES[*]}"
# One line per key. The first version printed `$others` raw and a multi-file
# answer put a bare path on its own line inside the block, which is a `data`
# block that does not parse — the one failure mode of pasting a generated set
# rather than retyping it (L33).
printf 'instruction_surfaces_naming_it: %s\n' "$(echo ${hits:-none} | tr '\n' ' ')"
printf 'any_file_naming_it: %s\n' "$(echo ${others:-none} | tr '\n' ' ')"
awk -F'\t' '$1=="POSTER"{printf "poster_%s: sent=%s cut=%s\n", $2, $3, $4}' <<<"$POP"
awk -F'\t' '$1=="CUTALL"{printf "cut_all_companies: %s of %s\n", $2, $3}
            $1=="CUTMINE"{printf "cut_this_product: %s of %s\n", $2, $3}' <<<"$POP"
printf 'posters_not_bound: %s\n' "$unbound"
printf 'windows_read_only_in_part: %s\n' "${blind:-0}"
echo '```'

if [ "$unbound" -gt 0 ]; then
  echo
  printf 'REFUSED: %s seat(s) of %s posted in this window and nothing they read names %s.\n' \
    "$unbound" "$me" "$GATE"
  printf 'A gate with a correct exit code and an optional caller is in the path of its author alone.\n'
  exit 1
fi
echo
printf 'every poster in the window is bound by %s\n' "$GATE"
exit 0
