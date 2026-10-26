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
  rm -rf "$a" "$b" "$c" "$d"
  [ "$ok" = 1 ] && echo "caps.sh --self-test: all four fixtures pass" && exit 0
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

# The cap this product declares for each of its own seats. Two files carry it
# and smoke-roster.sh asserts they agree, so reading either is reading both;
# the manifest is the one a product seat may write (L-X9).
caps = {}
for f in glob.glob(os.path.join(root, "agents", "*", "agent.toml")):
    name = os.path.basename(os.path.dirname(f))
    m = re.search(r"^max_turns\s*=\s*(\d+)", open(f).read(), re.M)
    if m:
        # Keyed by the host's seat name, which carries the product prefix.
        # A bare `engineer` or `pm` on this host is another company's seat,
        # and attributing this repository's cap to it is the same name
        # collision that made the board's resolver answer for the wrong
        # product (incident 23). Those seats report their cap as `-` and the
        # step is read off the censored num_turns instead.
        caps["epitome-" + name] = int(m.group(1))

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

seats = collections.defaultdict(lambda: collections.defaultdict(list))
text_only = []
not_a_limit = []
by_trigger = collections.defaultdict(lambda: collections.defaultdict(int))
files = unparsed = 0
for day in window:
    for path in glob.glob(os.path.join(logs, "*", day + "*.log")):
        s = os.path.basename(os.path.dirname(path))
        if seat_filter and s != seat_filter and s != "epitome-" + seat_filter:
            continue
        files += 1
        text = open(path, errors="replace").read()
        found = RESULT.findall(text)
        m = found[-1] if found else None
        if not m:
            # No result object: the run is still open, or it died before the
            # executor returned one. Either way it is not a finished run and
            # it is counted as unparsed rather than as a success.
            unparsed += 1
            continue
        try:
            r = json.loads(m)
        except ValueError:
            unparsed += 1
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
        if r.get("api_error_status") in (429, 529):
            sub = "refused"
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
        trig = re.sub(r"\.log$", "", os.path.basename(path)).rsplit("-", 1)[-1]
        by_trigger[trig][sub] += 1

finished = sum(len(v) for d in seats.values() for v in d.values())
if files == 0:
    print(f"caps.sh: no run logs under {logs} for {window[-1]}..{window[0]} — could not look, not a clean bill")
    sys.exit(2)
if finished == 0:
    print(f"caps.sh: {files} log(s) read and none carried a finished run — could not look, not a clean bill")
    sys.exit(2)

print(f"read {files} log(s) over {window[-1]}..{window[0]} from {logs}: "
      f"{finished} finished, {unparsed} still open or without a result object")
print()
print(f"{'SEAT':<22}{'CAP':>5}{'RUNS':>6}{'EXHAUST':>9}{'REFUSED':>9}{'BEFORE':>7}{'$ BURNT':>9}{'MIN':>6}  NOTE")

findings = 0
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
        seen = cap if cap is not None else (turns[0] - 1 if turns and turns[0] else None)
        step = int(seen * 3 / 2) if seen else None
        note = (f"EXHAUSTED {len(ex)}x at num_turns {','.join(str(t) for t in turns)} — "
                f"peak censored; step {seen} -> {step} (L-X3)")
        if cap is None:
            note += "; cap not declared in this repo's agents/"
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

if text_only:
    print(f"{len(text_only)} log(s) carry a refusal signature in their text and in none of their "
          f"result object's fields, and are counted above as what they are — finished work. "
          f"The signature is in the run's own final report, which is the one place a seat that "
          f"documents refusals is guaranteed to write one (L64): {', '.join(sorted(text_only))}.")
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
slot_all = sum(slots.values())
if slot_all:
    print(f"{slot_ref} of {slot_all} scheduled slot(s) were refused, against "
          f"{by_trigger['message'].get('refused', 0)} of {sum(by_trigger['message'].values())} "
          f"message wake(s). A slot fires once per period and is the whole of that seat's "
          f"cadence for it, so these are not the same loss and only this line says which "
          f"one the day took (L62).")
else:
    print("No scheduled slot finished in this window, so the slot column is "
          "could-not-look and not a clean bill (L41).")
print()
print("```data")
print(f"measured_at: {datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')}")
print(f"window: {window[-1]}..{window[0]}")
print(f"logs_read: {files}")
print(f"runs_finished: {finished}")
print(f"runs_open_or_without_a_result: {unparsed}")
print(f"limit_touched: {tot_r}")
print(f"limit_touched_seats: {len(rf_seats)}")
print(f"refused_before_a_turn: {tot_b}")
print(f"refused_before_a_turn_seats: {len(bf_seats)}")
print(f"exhausted: {tot_e}")
print(f"exhausted_seats: {findings}")
print(f"exhausted_cost_usd: {tot_c:.2f}")
print(f"exhausted_minutes: {tot_m:.0f}")
print(f"refusal_signature_in_text_only: {len(text_only)}")
print(f"api_error_that_is_not_a_limit: {len(not_a_limit)}")
for trig in sorted(by_trigger):
    d = by_trigger[trig]
    print(f"{trig}_attempted: {sum(d.values())}")
    print(f"{trig}_refused: {d.get('refused', 0)}")
print("```")
sys.exit(1 if findings else 0)
PY
