#!/usr/bin/env bash
# Which seats died at their own turn cap, on the surface the seats actually
# run on (L51, incident 25).
#
#   bash docs/agents/caps.sh              today, every seat on this host
#   bash docs/agents/caps.sh --days 7     a window
#   bash docs/agents/caps.sh --seat exo   one seat of this product
#   bash docs/agents/caps.sh --self-test  fire the record reader on built logs
#
# WHY THIS EXISTS, AND WHY IT IS NOT A SECOND COPY OF HQ's TOOL. The company
# already has `tools/check-turn-caps.sh` in alexandra-systems, and
# `standards/lessons.md` L-X3 as amended says it is the reason exhaustion is
# "no longer a thing a seat must remember to measure". It reads
# `repos/<repo>/actions/workflows/agent-*.yml/runs`. The seats left Actions:
# on 2026-10-24 this host finished 336 seat runs and this repository's Actions
# ran one workflow, `asc-heartbeat`. Run against this repository over the day
# this seat hit the cap three times, it printed an empty table and
# "No seat exhausted its turn cap in the last 1 days", exit 0 — the real
# negative this script was checked against. The repository list was right. The
# execution surface was not, and nothing in the output said which it had read.
#
# So this reads the host's own run logs, which is where this company's runs
# are. Three things it does that the exit code of a run cannot.
#
# 1. **A cause, not an outcome** (L-X14). A refused run, an exhausted run and
#    a crashed run all carry `exit=1`. This splits them by `terminal_reason`,
#    which is the field that says which happened: `subtype` reads "success" on
#    every one of the 323 provider refusals in this host's history, and the
#    text of a log is not evidence about its own run, because the log carries
#    the run's final report and this seat's final reports quote refusals
#    (L64).
# 2. **A zero is not a clean bill** (L-A80, L-A47 clause two applied to runs
#    rather than to repositories). Reading no runs exits 2 and says so. HQ's
#    tool does `[ -n "$runs" ] || continue`, so a seat whose runs moved
#    elsewhere is skipped silently and the summary line counts it as fine.
# 3. **The step, per L-X3 as amended.** A cap that binds censors the very
#    measurement that would correct it: the run reports cap+1, so there is no
#    peak to double. The response is a defined step up — half again — and the
#    cap for this product's seats is read out of `agents/<seat>/agent.toml`
#    rather than remembered.
# 4. **A killing, which the killed run cannot report** (L102, incident 67).
#    Everything above is read out of the result object the executor prints at
#    exit, so a run the host killed first is in none of it. Until 2026-11-02
#    those runs shared one number with the runs still working, called "still
#    open or without a result object", and the two take opposite acts: one
#    reports in a few minutes, the other never will and its wake is spent. On
#    the day this was written that number was 37, and it was 15 and 22. All
#    fifteen were `message` wakes killed at the declared wall clock, five of
#    them had posted to the board inside their hour, and `message_refused: 0`
#    read as a clean bill on the channel that lost them. The footer and the
#    bound are read from `docs/agents/liveness.py`, which owns both.
#
# Reads only. No credential, no network.
set -uo pipefail

LOGS=${EPITO_LOGS:-/srv/asc/state/.epito/logs}
DAYS=1
SEAT=

# L42: a reader whose correctness was argued is not a detector. The two
# fixtures below are the ones the repair of 2026-10-26 is for, and they are
# built here rather than looked for, because this host's logs do not contain
# the case yet and a test that cannot run is an absence read as a pass.
if [ "${1:-}" = "--self-test" ]; then
  day=$(date -u +%F); ok=1
  a=$(mktemp -d); mkdir -p "$a/epitome-exo"
  # 1. A log that writes a result object down and then ends in its own. The
  #    quoted one says completed at 98 turns -- it is incident 8's, the exact
  #    text L64 was written for -- and the run's own says a limit refused it.
  {
    printf '%s\n' '{"duration_api_ms":1,"type":"result","subtype":"success","terminal_reason":"completed","num_turns":98,"total_cost_usd":8.19,"duration_ms":60000}'
    printf '%s\n' '{"duration_api_ms":2,"type":"result","subtype":"success","api_error_status":429,"terminal_reason":"api_error","num_turns":78,"total_cost_usd":6.17,"duration_ms":1033349}'
  } > "$a/epitome-exo/${day}T06-04-46-651Z-message.log"
  out=$(bash "${BASH_SOURCE[0]}" --logs "$a" 2>&1)
  for want in 'runs_finished: 1' 'limit_touched: 1' 'refused_before_a_turn: 0'; do
    case "$out" in *"$want"*) ;; *) echo "caps.sh --self-test: last record wins — expected '$want'" >&2; ok=0 ;; esac
  done
  # 2. A log that only quotes one, mid-line, and has no record of its own.
  #    That is not a finished run, and the answer is could-not-look (exit 2),
  #    never a count of one.
  b=$(mktemp -d); mkdir -p "$b/epitome-exo"
  printf '%s\n' 'documenting it here: {"duration_api_ms":1,"type":"result","terminal_reason":"completed","num_turns":5}' \
    > "$b/epitome-exo/${day}T07-00-00-000Z-message.log"
  out=$(bash "${BASH_SOURCE[0]}" --logs "$b" 2>&1); rc=$?
  [ "$rc" = 2 ] || { echo "caps.sh --self-test: a quoted record is not a finished run — expected exit 2, got $rc" >&2; ok=0; }
  case "$out" in *"none carried a finished run"*) ;; *) echo "caps.sh --self-test: expected the could-not-look sentence" >&2; ok=0 ;; esac
  # 3. An api_error that is not a limit. This is the real 2026-10-26 record
  #    from seat `pm`: terminal_reason api_error, no api_error_status, and a
  #    content refusal in `result`. It must leave the limit counts at zero.
  c=$(mktemp -d); mkdir -p "$c/epitome-exo"
  printf '%s\n' '{"duration_api_ms":1,"type":"result","subtype":"success","terminal_reason":"api_error","num_turns":2,"total_cost_usd":0.1,"duration_ms":60000,"result":"API Error: Sonnet 5 cant help with this. Start a new session to continue."}' \
    > "$c/epitome-exo/${day}T06-10-22-059Z-message.log"
  out=$(bash "${BASH_SOURCE[0]}" --logs "$c" 2>&1)
  for want in 'limit_touched: 0' 'refused_before_a_turn: 0' 'api_error_that_is_not_a_limit: 1'; do
    case "$out" in *"$want"*) ;; *) echo "caps.sh --self-test: an api error is not a limit — expected '$want'" >&2; ok=0 ;; esac
  done
  # 4. A run that COMPLETED and whose own final report quotes a refusal. This
  #    is the real shape of `epitome-exo/2026-10-26T09-02-46-416Z-hook`, 118
  #    turns, which documented incident 35 and so carries the provider's
  #    sentence inside `result`. It is finished work and must leave the limit
  #    counts at zero however much of a refusal its prose contains (L64).
  d=$(mktemp -d); mkdir -p "$d/epitome-exo"
  printf '%s\n' '{"duration_api_ms":1,"type":"result","subtype":"success","terminal_reason":"completed","num_turns":118,"total_cost_usd":10.0,"duration_ms":1524000,"result":"Charter read, run complete. The run at 06:04:46Z was cut: Youve hit your session limit · resets 9am (UTC)."}' \
    > "$d/epitome-exo/${day}T09-02-46-416Z-hook.log"
  out=$(bash "${BASH_SOURCE[0]}" --logs "$d" 2>&1)
  for want in 'limit_touched: 0' 'hook_refused: 0' 'refusal_signature_in_text_only: 1'; do
    case "$out" in *"$want"*) ;; *) echo "caps.sh --self-test: a report that quotes a refusal is not one — expected '$want'" >&2; ok=0 ;; esac
  done
  # 5. A 529 overload. Status is set, so the field test alone would call it a
  #    quota refusal; it is not one, and the difference decides whether the
  #    company's retry can ever wake the seat. Real record, `epitome-engineer`
  #    2026-10-26T14-08-07-422Z, turn 31.
  e=$(mktemp -d); mkdir -p "$e/epitome-exo"
  printf '%s\n' '{"duration_api_ms":1,"type":"result","subtype":"success","terminal_reason":"api_error","api_error_status":529,"num_turns":31,"total_cost_usd":2.5,"duration_ms":600000,"result":"API Error: 529 Overloaded. This is a server-side issue, usually temporary."}' \
    > "$e/epitome-exo/${day}T14-08-07-422Z-hook.log"
  out=$(bash "${BASH_SOURCE[0]}" --logs "$e" 2>&1)
  for want in 'limit_touched: 0' 'overloaded_529_no_reset_to_wait_for: 1' 'hook_refused: 0'; do
    case "$out" in *"$want"*) ;; *) echo "caps.sh --self-test: an overload is not a quota — expected '$want'" >&2; ok=0 ;; esac
  done
  # 6. The class with no record of its own (L102, incident 67). Three logs in
  #    one directory: a run that reported, a run the host killed at its wall
  #    clock with nothing behind the footer, and a run started a moment ago
  #    with neither mark. Before 2026-11-02 the last two were one number called
  #    "still open or without a result object", and the two take opposite acts:
  #    one will report in a few minutes, the other never will and its wake is
  #    spent. The killed row is the shape of all fifteen of 2026-11-02 — the
  #    host's footer, no result object, a `message` trigger.
  f=$(mktemp -d); mkdir -p "$f/epitome-exo"
  printf '%s\n' '{"duration_api_ms":1,"type":"result","subtype":"success","terminal_reason":"completed","num_turns":40,"total_cost_usd":3.0,"duration_ms":600000}' \
    > "$f/epitome-exo/${day}T00-10-00-000Z-message.log"
  printf '%s\n' '# epito run epitome-exo' '# trigger=message' '---' '' '---' \
                '# exit=timeout pr=- session=- turns=-' \
    > "$f/epitome-exo/${day}T01-00-00-000Z-message.log"
  printf '%s\n' '# epito run epitome-exo' '# trigger=message' '$ claude -p <prompt>' \
    > "$f/epitome-exo/$(date -u +%Y-%m-%dT%H-%M-%S)-000Z-message.log"
  # One finished slot, so the slot/wake sentence fires and both its
  # denominators are under test rather than only the data keys.
  printf '%s\n' '{"duration_api_ms":1,"type":"result","subtype":"success","terminal_reason":"completed","num_turns":12,"total_cost_usd":1.0,"duration_ms":300000}' \
    > "$f/epitome-exo/${day}T00-20-00-000Z-cron.log"
  out=$(bash "${BASH_SOURCE[0]}" --logs "$f" 2>&1)
  for want in 'runs_finished: 2' 'runs_killed_before_a_result: 1' 'runs_in_the_room: 1' \
              'runs_unmarked_unplaceable: 0' 'message_attempted: 3' \
              'message_killed_before_a_result: 1' 'limit_touched: 0'; do
    case "$out" in *"$want"*) ;; *) echo "caps.sh --self-test: a killed run is not an open one — expected '$want'" >&2; ok=0 ;; esac
  done
  # And the denominator: a wake the host spent is a wake, whether or not it
  # reported, so `attempted` counts launches and never reports.
  case "$out" in *"0 of 1 scheduled slot(s) were refused, against 0 of 3 message wake(s)"*) ;; *) echo "caps.sh --self-test: the wake denominator must be launches, not reports" >&2; ok=0 ;; esac
  rm -rf "$a" "$b" "$c" "$d" "$e" "$f"
  [ "$ok" = 1 ] && echo "caps.sh --self-test: all six fixtures pass" && exit 0
  exit 1
fi

while [ $# -gt 0 ]; do
  case "$1" in
    --days) DAYS=${2:?--days needs a number}; shift 2 ;;
    --seat) SEAT=${2:?--seat needs a name}; shift 2 ;;
    --logs) LOGS=${2:?--logs needs a path}; shift 2 ;;
    --help|-h) sed -n '2,/^[^#]/p' "${BASH_SOURCE[0]}" | sed -n 's/^# \{0,1\}//p'; exit 0 ;;
    *) echo "caps.sh: unknown argument $1" >&2; exit 2 ;;
  esac
done

if [ ! -d "$LOGS" ]; then
  echo "caps.sh: no run logs at $LOGS — this runs where the host's logs are; could not look" >&2
  exit 2
fi

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo .)

DAYS="$DAYS" SEAT="$SEAT" LOGS="$LOGS" ROOT="$ROOT" python3 - <<'PY'
import glob, json, os, re, sys, datetime, collections

logs = os.environ["LOGS"]; days = int(os.environ["DAYS"])
seat_filter = os.environ["SEAT"] or None; root = os.environ["ROOT"]

today = datetime.datetime.now(datetime.timezone.utc).date()
window = [(today - datetime.timedelta(days=i)).isoformat() for i in range(days)]

# The cap each of this product's seats is actually RUN under.
#
# This block used to read `agents/<seat>/agent.toml` alone, on the stated
# ground that "two files carry it and smoke-roster.sh asserts they agree, so
# reading either is reading both". Both halves were wrong by 2026-10-26.
# `cli/test/smoke-roster.sh:193` compares the manifest to the *workflow*, and
# `docs/agents/roster.sh:31` already said that check "has never fired"; the
# file the executor reads is neither of them. It is the host roster at
# /srv/asc/roster/<product>/<seat>/agent.toml, which `cli/src/lib/adapters.js`
# turns into `--max-turns`. At 20:05:56Z on 2026-10-26 HQ raised exo there from
# 120 to 180 and engineer from 150 to 225, at this seat's ask, and this
# repository's manifests still read 120 and 150 — so the CAP column named a
# number no run on this box had been executed under for four hours, and the
# step sentence recommended a step that had already been taken (L82, incident
# 45; L-X11, incident 9).
#
# So: the roster first, because it is the surface the run happens on, with the
# manifest as the fallback and the disagreement printed rather than resolved.
# A reader that silently picks one of two live numbers is the thing being fixed
# here, so this one says which it read.
PRODUCT = "epitome"
ROSTER = os.environ.get("EPITO_ROSTER", "/srv/asc/roster")


def _cap(path):
    try:
        m = re.search(r"^max_turns\s*=\s*(\d+)", open(path).read(), re.M)
    except OSError:
        return None
    return int(m.group(1)) if m else None


caps, cap_src, cap_split = {}, {}, []
for f in glob.glob(os.path.join(root, "agents", "*", "agent.toml")):
    name = os.path.basename(os.path.dirname(f))
    declared = _cap(f)
    executed = _cap(os.path.join(ROSTER, PRODUCT, name, "agent.toml"))
    chosen = executed if executed is not None else declared
    if chosen is None:
        continue
    # Keyed by the host's seat name, which carries the product prefix.
    # A bare `engineer` or `pm` on this host is another company's seat,
    # and attributing this repository's cap to it is the same name
    # collision that made the board's resolver answer for the wrong
    # product (incident 23). Those seats report their cap as `-` and the
    # step is read off the censored num_turns instead.
    caps[PRODUCT + "-" + name] = chosen
    cap_src[PRODUCT + "-" + name] = "roster" if executed is not None else "manifest"
    if declared is not None and executed is not None and declared != executed:
        cap_split.append((PRODUCT + "-" + name, declared, executed))

# The result object is a RECORD the executor writes on a line of its own, so
# the pattern is anchored to one and the LAST of them is taken. It used to be
# unanchored, dot-all, first-match -- which is the prose reader L64 removed,
# left standing one line below the comment that says it was removed. Nothing
# in this host's 1,881 logs quotes a result object yet, so the two reads agree
# on every one of them today; the register's own habit of pasting generated
# blocks into prose is what makes that a latency and not a safety margin, and
# `alexandra-systems/exo-centralizer` hit the same class in its port of this
# repair on 2026-10-26, from the other direction -- its splitter found no
# record and fell back to the prose read (L72).
RESULT = re.compile(r'^\{"duration_api_ms".*"type":"result".*\}$', re.M)
LIMIT  = re.compile(r'hit your [a-z]+ limit|"api_error_status":(?:429|529)|limit (?:reached|exceeded)')

# THE CLASS WITH NO RECORD OF ITS OWN (L102, incident 67). Until 2026-11-02
# every log with no result object behind it was one number, `unparsed`, printed
# as "still open or without a result object". That is two states with opposite
# remedies under one name, which is L-A44 in this script's own output and the
# same defect this file fixed for refusals and for 529s. A run still in the room
# will report its own numbers in a few minutes and must not be counted as a
# loss. A run the host killed will never report anything: its wake is spent, its
# cost and turns are unknowable, and the only mark on it was written by the
# killer. On the day this was written the two were 20 and 15.
#
# The bound and the footer are not re-declared here. `docs/agents/liveness.py`
# owns both — it is the file whose subject is which writer marked an ending, it
# reads the wall clock off `cli/src/temporal/env.js` rather than choosing one,
# and a second copy of either value in this file is the thing L-A143 forbids.
# What is NOT borrowed from it is the result-object test: this file's `RESULT`
# is anchored to a record because of L64, and the two were allowed to disagree
# about one log until 2026-11-02, when `liveness.py` took the same anchor.
import importlib.util as _ilu
_lv_path = os.path.join(root, "docs", "agents", "liveness.py")
try:
    _spec = _ilu.spec_from_file_location("_liveness", _lv_path)
    _lv = _ilu.module_from_spec(_spec)
    _spec.loader.exec_module(_lv)
    FOOTER, WALL_MIN, GRACE_MIN = _lv.FOOTER, _lv.WALL_MIN, _lv.GRACE_MIN
except Exception as e:
    # A could-not-look, never a guess at the bound (L41). Without the bound this
    # script can still tell a killed run from an open one whenever the host left
    # a footer, and it says plainly which half it lost.
    FOOTER, WALL_MIN, GRACE_MIN = re.compile(r"^# exit=(\S+)", re.M), None, None
    print(f"caps.sh: could not read the wall clock from {_lv_path} ({e}) — a log "
          f"with neither mark is reported as unmarked rather than placed, because "
          f"the bound is that file's to declare and not this one's to assume.")

NAME = re.compile(r"(\d{4}-\d\d-\d\d)T(\d\d)-(\d\d)-(\d\d)-\d{3}Z-(.+)\.log")
now = datetime.datetime.now(datetime.timezone.utc)

seats = collections.defaultdict(lambda: collections.defaultdict(list))
text_only = []
not_a_limit = []
overloaded = []
by_trigger = collections.defaultdict(lambda: collections.defaultdict(int))
attempted = collections.defaultdict(int)       # every log, finished or not
killed = []                                    # (seat, file, trigger, footer word, minutes)
in_room = []                                   # (seat, file, trigger, minutes so far)
unmarked = []                                  # neither writer's mark, and no bound to place it
files = unparsed = 0
for day in window:
    for path in glob.glob(os.path.join(logs, "*", day + "*.log")):
        s = os.path.basename(os.path.dirname(path))
        if seat_filter and s != seat_filter and s != "epitome-" + seat_filter:
            continue
        files += 1
        base = os.path.basename(path)
        # The trigger is read for every log and not only for finished ones.
        # `<trig>_attempted` used to be the count of FINISHED runs with that
        # trigger, which is the one thing its name does not say: on 2026-11-02
        # it printed `message_attempted: 219` on a day the host launched 234
        # message wakes and killed 15 of them at the wall clock, so the key the
        # charter's capacity duty reads as "how many runs the host attempted"
        # was short by exactly the class that bought nothing (L-A107, L-A88).
        trig = re.sub(r"\.log$", "", base).rsplit("-", 1)[-1]
        attempted[trig] += 1
        text = open(path, errors="replace").read()
        found = RESULT.findall(text)
        m = found[-1] if found else None
        if not m:
            # No result object. Which of the three it is comes from the outer
            # writer, because the executor cannot describe its own killing.
            unparsed += 1
            foot = FOOTER.search(text)
            nm = NAME.match(base)
            start = (datetime.datetime.fromisoformat(
                "%sT%s:%s:%s+00:00" % nm.group(1, 2, 3, 4)) if nm else None)
            span = ((os.path.getmtime(path) - start.timestamp()) / 60.0
                    if start else 0.0)
            if foot:
                killed.append((s, base, trig, foot.group(1), span))
            elif start is not None and WALL_MIN is not None and \
                    (now - start).total_seconds() / 60.0 > WALL_MIN + GRACE_MIN:
                # Past the declared wall clock with no mark from either writer:
                # nothing wrote a cause, so nobody is dispatched at it (L-X14).
                killed.append((s, base, trig, "lost", (now - start).total_seconds() / 60.0))
            elif start is not None and WALL_MIN is not None:
                in_room.append((s, base, trig, (now - start).total_seconds() / 60.0))
            else:
                unmarked.append((s, base, trig))
            continue
        try:
            r = json.loads(m)
        except ValueError:
            unparsed += 1
            unmarked.append((s, base, trig))
            continue
        sub = r.get("subtype") or "?"
        # The class of an ending is in the result object's own fields, and the
        # file around it is not one of them. `subtype` is "success" on all 323
        # provider refusals in this host's history, so it cannot carry the
        # class; `terminal_reason` splits completed / api_error / max_turns and
        # is read here. The text search this replaced matched anywhere in the
        # log, and the log contains `result` -- the run's own final report --
        # so a run of this seat that merely wrote the refusal sentence down was
        # counted as refused: `epitome-exo/2026-10-18T13-07-01-011Z`, 98 turns,
        # $8.19, terminal_reason completed, documenting incident 8 (L64).
        # The discriminator is ONE field and no prose, including the result
        # object's own `result`. Over all 1,633 finished runs in this host's
        # history, `api_error_status in (429,529)` is exactly coextensive with
        # the 397 limit refusals; reading `result` as well adds nothing but the
        # trap L64 removed, and adding it back caught both of the two completed
        # runs whose final report quotes a refusal — one of them this seat's own
        # 09:02:46Z hook, 118 turns, which was briefly counted as the day's
        # first refused hook inside the run that wrote this comment.
        if r.get("api_error_status") == 429:
            sub = "refused"
        elif r.get("api_error_status") == 529:
            # An overload is not a quota. 429 says "you may not", 529 says "I
            # cannot right now", and the difference is operational: a 429
            # announces its own reset hour, which is the single fact the
            # company's retry is built on (`capacity-retry.py` condition 2
            # requires an announced reset), and a 529 announces nothing. So a
            # 529-refused run is owed a wake that mechanism will never send.
            # One such run exists in this host's 1,900 logs — `epitome-engineer`
            # 2026-10-26T14-08-07-422Z, a hook, cut at turn 31 — and it arrived
            # five minutes after the retry recovered sixteen seats, inside the
            # run that split this class out. HQ's `capacity.py:refused_by`
            # classes it `refused` on `terminal_reason` alone, so it reaches the
            # brief as one of the day's provider refusals (incident 42).
            sub = "overloaded"
            overloaded.append(os.path.basename(path))
        elif r.get("terminal_reason") == "api_error":
            # An api_error that carries no limit status and no limit sentence is
            # not a capacity refusal, and a column named for limits may not hold
            # it (L-A88). 2026-10-26T06-10-22-059Z, seat `pm`, turn 2: "Sonnet 5
            # can't help with this" with no `api_error_status` at all. Reading
            # terminal_reason alone put it among that day's 99 limit-touched runs
            # and the brief told the owner the provider had refused it.
            sub = "api_error_not_a_limit"
            not_a_limit.append(os.path.basename(path))
        elif LIMIT.search(text):
            # Named rather than dropped (L-A88): this is a log whose text says
            # limit and whose fields say the run finished its work.
            text_only.append(os.path.basename(path))
        seats[s][sub].append((os.path.basename(path), r.get("num_turns"),
                              r.get("total_cost_usd") or 0.0, (r.get("duration_ms") or 0) / 60000.0))
        # The trigger is the filename's own last field -- `...Z-cron.log`,
        # `-message.log`, `-hook.log` -- and it is the one thing on this box
        # that says which UNIT a refusal spent. A message wake refused loses
        # hours, because the next message re-delivers the work; a cron slot
        # refused loses the whole of that seat's cadence for its period, and
        # three of 2026-10-25's eleven refused slots were their seat's only
        # slot of the week. HQ's `tools/capacity.py` has parsed this field
        # since it was written (line 264) and prints it in none of its 24
        # output keys, so two seats measured the split by hand on one night
        # and the brief has never carried it (L62).
        by_trigger[trig][sub] += 1

finished = sum(len(v) for d in seats.values() for v in d.values())
if files == 0:
    print(f"caps.sh: no run logs under {logs} for {window[-1]}..{window[0]} — could not look, not a clean bill")
    sys.exit(2)
if finished == 0:
    print(f"caps.sh: {files} log(s) read and none carried a finished run — could not look, not a clean bill")
    sys.exit(2)

print(f"read {files} log(s) over {window[-1]}..{window[0]} from {logs}: "
      f"{finished} finished, {len(killed)} killed before the executor reported, "
      f"{len(in_room)} still in the room"
      + (f", {len(unmarked)} unmarked and unplaceable" if unmarked else ""))
print()
print(f"{'SEAT':<22}{'CAP':>5}{'RUNS':>6}{'EXHAUST':>9}{'REFUSED':>9}{'BEFORE':>7}{'$ BURNT':>9}{'MIN':>6}  NOTE")

findings = 0
caps_answered = 0
tot_c = tot_m = 0.0
tot_e = tot_r = tot_b = tot_runs = 0
rf_seats, bf_seats = set(), set()
for s in sorted(seats):
    d = seats[s]
    ex = d.get("error_max_turns", [])
    rf = d.get("refused", [])
    # REFUSED is every finished run a limit touched. BEFORE is the subset that
    # never took a second turn. They are different facts and the register has
    # twice printed one under the other's name (L33), so the instrument prints
    # both and the prose quotes these labels rather than inventing one.
    bf = [x for x in rf if (x[1] or 0) <= 1]
    runs = sum(len(v) for v in d.values())
    cost = sum(x[2] for x in ex); mins = sum(x[3] for x in ex)
    cap = caps.get(s)
    note = ""
    if ex:
        findings += 1
        tot_e += len(ex); tot_c += cost; tot_m += mins
        turns = sorted({x[1] for x in ex})
        # The cap these runs HIT, which is `num_turns - 1` and not whatever the
        # cap is now. This used to prefer the declared cap, which was the same
        # number for as long as a cap never moved inside a window. One moved on
        # 2026-10-26 at 20:05:56Z and the line then read `8x at num_turns 121 —
        # step 180 -> 270`: eight runs that died at 120 proposing a second step
        # off the raise they had already earned. A step is read off the
        # evidence, and the cap in force is a separate fact about whether the
        # evidence has been answered (L-X3 as amended, L82).
        hit = turns[0] - 1 if turns and turns[0] else None
        step = int(hit * 3 / 2) if hit else None
        note = (f"EXHAUSTED {len(ex)}x at num_turns {','.join(str(t) for t in turns)} — "
                f"peak censored; step {hit} -> {step} (L-X3)")
        if cap is not None and hit is not None and cap > hit:
            caps_answered += 1
            note += (f"; ALREADY ANSWERED — the cap in force is {cap}, raised after these "
                     f"runs, so this is evidence about {hit} and not an open ask")
        elif cap is not None and hit is not None and cap != hit:
            note += (f"; the cap in force is {cap}, so these runs did not die at it")
        if cap is None:
            note += "; cap not declared in this repo's agents/"
        elif cap_src.get(s) == "manifest":
            note += "; cap read from this repo's agents/, not from the host roster"
    print(f"{s:<22}{(cap if cap is not None else '-')!s:>5}{runs:>6}{len(ex):>9}{len(rf):>9}"
          f"{len(bf):>7}{cost:>9.2f}{mins:>6.0f}  {note}")
    tot_r += len(rf); tot_b += len(bf); tot_runs += runs
    if rf: rf_seats.add(s)
    if bf: bf_seats.add(s)

print()
if findings:
    print(f"{tot_e} run(s) on {findings} seat(s) ended at their cap: ${tot_c:.2f} and {tot_m:.0f} minutes "
          f"bought nothing. Every one of them reports num_turns = cap + 1, so none of them is evidence "
          f"of a peak and all of them are evidence about the cap (L-X3 as amended).")
else:
    print(f"No seat exhausted its cap over {window[-1]}..{window[0]}, read from {finished} finished runs.")

if cap_split:
    # Not resolved here. A seat may not write the roster and the roster is what
    # ran, so the CAP column above is the roster's number and this line is the
    # repository saying something else — which is a finding about distribution
    # and not a choice this instrument gets to make (L-X11, L-X13).
    print(f"{len(cap_split)} seat(s) are run under a cap this repository does not declare. "
          f"The CAP column above is the host roster at {ROSTER}/{PRODUCT}/<seat>/agent.toml, "
          f"which `cli/src/lib/adapters.js` turns into `--max-turns`; agents/<seat>/agent.toml "
          f"says otherwise and nothing in this repository compares the two: "
          + ", ".join(f"{s} declares {d}, runs at {e}" for s, d, e in sorted(cap_split)))

if text_only:
    print(f"{len(text_only)} log(s) carry a refusal signature in their text and in none of their "
          f"result object's fields, and are counted above as what they are — finished work. "
          f"The signature is in the run's own final report, which is the one place a seat that "
          f"documents refusals is guaranteed to write one (L64): {', '.join(sorted(text_only))}.")
if overloaded:
    print(f"{len(overloaded)} finished run(s) ended `api_error` with status 529 — the provider "
          f"overloaded, not a quota — so they are NOT in the limit counts below. A 529 announces "
          f"no reset hour, and an announced reset is the one fact the company's retry acts on, so "
          f"these are owed a wake nothing will send: {', '.join(sorted(overloaded))}.")
if not_a_limit:
    print(f"{len(not_a_limit)} finished run(s) ended `api_error` with no limit status and no limit "
          f"sentence of their own, so they are NOT in the limit counts below — an api error is not "
          f"a capacity refusal and a column named for limits may not hold one (L-A88): "
          f"{', '.join(sorted(not_a_limit))}.")
print(f"{tot_r} finished run(s) on {len(rf_seats)} seat(s) were touched by a provider limit, "
      f"of which {tot_b} on {len(bf_seats)} seat(s) never took a second turn. "
      f"A limit-touched run and a refused-before-a-turn run are different facts and this is "
      f"both of them; quote the label, never the other one's name (L33).")

# A recovery is reported in the unit that was lost (L62 clause 2). The retry
# this company built wakes a refused seat when the announced reset passes, and
# it recovers hours: a seat woken with a message sentence does the work that
# message carried and never the scheduled run. So a line that counts only runs
# and minutes reads a day as recovered on the day its cadences were spent.
slots = by_trigger.get("cron", {})
slot_ref = slots.get("refused", 0)
# The denominator is what the host LAUNCHED with that trigger, not what
# reported. A run killed before it reported was still a slot or a wake spent,
# and leaving it out of the denominator makes the refusal rate read low by
# exactly the class that bought nothing.
slot_all = attempted.get("cron", 0)
if slot_all:
    print(f"{slot_ref} of {slot_all} scheduled slot(s) were refused, against "
          f"{by_trigger['message'].get('refused', 0)} of {attempted.get('message', 0)} "
          f"message wake(s). A slot fires once per period and is the whole of that seat's "
          f"cadence for it, so these are not the same loss and only this line says which "
          f"one the day took (L62).")
else:
    print("No scheduled slot finished in this window, so the slot column is "
          "could-not-look and not a clean bill (L41).")

# The kills, in the unit they were paid in. Every line above this one is read
# out of a result object, so a run that never wrote one is absent from all of
# them — and absent from a refusal count reads as a channel that was fine.
if killed:
    byt = collections.Counter(k[2] for k in killed)
    byw = collections.Counter(k[3] for k in killed)
    mins = sum(k[4] for k in killed)
    print(f"{len(killed)} run(s) the host killed before the executor reported: "
          + ", ".join(f"{n} {w}" for w, n in sorted(byw.items(), key=lambda x: -x[1]))
          + ", by trigger "
          + ", ".join(f"{n} {t}" for t, n in sorted(byt.items(), key=lambda x: -x[1]))
          + f", {mins:.0f} minutes of wall clock between them. None of these is in any "
          f"count above, because every one of those is read out of a result object and "
          f"these have none: no turns, no cost, no cause, and a wake that is spent "
          f"whatever the run had done by the time it died (L102). A killed run is not a "
          f"refused run and is not a run still working — the three take opposite acts and "
          f"the first two are invisible to a reader that counts only what reported.")
    for s_, b_, t_, w_, mn in sorted(killed, key=lambda k: -k[4])[:8]:
        print(f"    {s_:<22} {b_}  exit={w_} at {mn:.1f} min")
    if len(killed) > 8:
        print(f"    ... and {len(killed) - 8} more")
else:
    print("No run in this window was killed before the executor reported, read from the "
          "host's own footer and not from the absence of a result object (L102).")
print()
print("```data")
print(f"measured_at: {datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')}")
print(f"window: {window[-1]}..{window[0]}")
print(f"logs_read: {files}")
print(f"runs_finished: {finished}")
print(f"runs_open_or_without_a_result: {unparsed}")
print(f"runs_killed_before_a_result: {len(killed)}")
print(f"runs_killed_minutes: {sum(k[4] for k in killed):.0f}")
print(f"runs_in_the_room: {len(in_room)}")
print(f"runs_unmarked_unplaceable: {len(unmarked)}")
print(f"wall_clock_bound_minutes: {('%g' % (WALL_MIN + GRACE_MIN)) if WALL_MIN is not None else 'could-not-look'}")
print(f"wall_clock_bound_declared_at: docs/agents/liveness.py")
print(f"limit_touched: {tot_r}")
print(f"limit_touched_seats: {len(rf_seats)}")
print(f"refused_before_a_turn: {tot_b}")
print(f"refused_before_a_turn_seats: {len(bf_seats)}")
print(f"exhausted: {tot_e}")
print(f"exhausted_seats: {findings}")
print(f"exhausted_cost_usd: {tot_c:.2f}")
print(f"exhausted_minutes: {tot_m:.0f}")
print(f"caps_read_from_roster: {sum(1 for v in cap_src.values() if v == 'roster')}")
print(f"caps_repo_disagrees_with_roster: {len(cap_split)}")
print(f"cap_findings_already_answered_by_a_raise: {caps_answered}")
print(f"refusal_signature_in_text_only: {len(text_only)}")
print(f"api_error_that_is_not_a_limit: {len(not_a_limit)}")
print(f"overloaded_529_no_reset_to_wait_for: {len(overloaded)}")
kt = collections.Counter(k[2] for k in killed)
for trig in sorted(set(attempted) | set(by_trigger)):
    d = by_trigger[trig]
    print(f"{trig}_attempted: {attempted.get(trig, 0)}")
    print(f"{trig}_finished: {sum(d.values())}")
    print(f"{trig}_refused: {d.get('refused', 0)}")
    print(f"{trig}_killed_before_a_result: {kt.get(trig, 0)}")
print("```")
sys.exit(1 if findings else 0)
PY
