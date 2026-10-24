#!/usr/bin/env bash
# Smoke test for `epito doctor` — the preflight whose whole promise is that it
# refuses exactly when a run on this box would refuse, and names the piece.
#
#   bash test/smoke-doctor.sh            # from cli/
#
# It spends nothing and reaches no provider: the executor under test is
# test/stub-executor.mjs, the same stand-in the runtime suites spawn, plus two
# deliberately broken ones this suite writes, and api.github.com is
# test/github-stub.mjs on loopback — which verifies the App JWT epito signs
# against a throwaway public key, so section 12 tests the real credential and
# not a mock of one. The one prerequisite it cannot stand in for is an engine — doctor's last section asks whether Temporal is
# answering, and a box with none is a box where a run genuinely would refuse —
# so the sections that need an engine skip and say so, and everything else
# still runs.
#
# What it proves:
#
#   1. a roster whose every piece is in place reports five ✓ rows and exits 0
#   2. the executor section is the new one, and it is the one that catches what
#      nothing caught before: a binary that is not on the PATH a RUN gets, and
#      a binary that is there and will not start under the environment a run
#      gives it — each exiting 1, each naming the fix, each said ONCE per
#      binary with the seats it covers rather than once per seat
#   3. a name this box holds and holds empty exits 1; a name it does not hold
#      at all is a report and exits 0 (`[runtime].env` is the list the runtime
#      injects FROM, and doctor does not guess which names a seat needs)
#   4. a seat with no open road on this box exits 1 and says which keys would
#      open one
#   5. the engine section tells a TCP connect apart from a Temporal server when
#      the engine client is installed: a port that answers and is not Temporal
#      exits 1, and so does the right server with the wrong namespace
#   6. --deep runs ONE turn per road and not one per seat, reads the executor's
#      own refusal back verbatim, and says which seats each call stood in for
#   7. --json carries the same verdict the text does, and a misspelled flag is
#      refused by name
#   8. it writes nothing: no .epito/, no ledger line, nothing on the engine
#   9. who each seat acts as on this box: its own App, a person's shared
#      credential, nobody, or half an identity — and which of those exit 1
#  9b. the bus row: which seats `[trigger].subscriptions` wakes, whether this
#      box names a stream for them at all, and that a seat with no other
#      trigger on a box with no stream is reported and never refused
#  10. and whether GitHub HAS that App, which is the one question no offline
#      check can answer: installed where it would mint, an id this box names
#      that GitHub does not have, a grant short of [identity].scopes, and a
#      GitHub this box cannot reach — four refusals and one report, one
#      request per (App, repo), and none of it without --deep
set -uo pipefail

CLI="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="${TMPDIR:-/tmp}/epito-doctor-smoke-$$"
E="node $CLI/src/index.js"
STUB="$CLI/test/stub-executor.mjs"

pass=0; fail=0
ok()   { pass=$((pass+1)); printf '  ok   %s\n' "$1"; }
bad()  { fail=$((fail+1)); printf '  FAIL %s\n' "$1"; }
check(){ if eval "$2"; then ok "$1"; else bad "$1"; fi; }
step() { printf '\n== %s\n' "$1"; }
cleanup() { if [ -n "${EPITO_SMOKE_KEEP:-}" ]; then printf '\nkept: %s\n' "$TMP"; else rm -rf "$TMP"; fi; }
trap cleanup EXIT
mkdir -p "$TMP"

# The roster under test, written here rather than committed: three seats that
# differ in the ways doctor reads — a seat on [runtime].model alone, a seat
# whose road needs a key, and a LangGraph seat, which is the one adapter that
# cannot have a one-turn probe.
R="$TMP/roster"
mkdir -p "$R/plain" "$R/roaded" "$R/graph"
cat > "$R/plain/agent.toml" <<'EOF'
[agent]
name = "plain"
description = "A seat with no route declared: [runtime].model is its only road."
[identity]
scopes = ["github:contents"]
[trigger]
cron = "0 6 * * *"
[runtime]
model = "claude-sonnet-5"
entry = "prompts/plain.md"
repo = "acme/box"
env = ["DOCTOR_SMOKE_HELD"]
EOF
cat > "$R/roaded/agent.toml" <<'EOF'
[agent]
name = "roaded"
description = "A seat that declares a gateway and a subscription behind it."
[identity]
scopes = ["github:contents"]
[trigger]
cron = "0 7 * * *"
[runtime]
model = "claude-sonnet-5"
entry = "prompts/roaded.md"
repo = "acme/box"
env = ["DOCTOR_SMOKE_KEY"]

[[runtime.route]]
name = "gateway"
model = "kimi-k2"
token_env = "DOCTOR_SMOKE_KEY"

[[runtime.route]]
name = "subscription"
model = "claude-sonnet-5"
EOF
cat > "$R/graph/agent.toml" <<'EOF'
[agent]
name = "graph"
description = "A LangGraph seat: its graph lives in its own repository."
[identity]
scopes = ["github:contents"]
[trigger]
cron = "0 8 * * *"
[runtime]
adapter = "langgraph"
model = "gpt-4o-mini"
entry = "prompts/graph.md"
repo = "acme/graph"
EOF

# Every invocation below runs with this: the stub as the executor, one held
# name, and the gateway's key set so `roaded` has an open road.
export EPITO_EXECUTOR="$STUB"
export DOCTOR_SMOKE_HELD="held"
export DOCTOR_SMOKE_KEY="a-key-nobody-will-call"
export EPITO_STUB_DIR="$TMP/stub"

# Is there an engine? doctor's fifth section is about the box, and a box with
# no engine is one where `epito run` refuses — which is the right answer and
# not a test failure. The suite asks once and says so.
ENGINE_ADDR="${TEMPORAL_ADDRESS:-127.0.0.1:7233}"
engine_up() {
  node -e 'const n=require("net"),a=process.argv[1],i=a.lastIndexOf(":"),s=n.connect({host:a.slice(0,i),port:Number(a.slice(i+1))});s.setTimeout(500);s.on("connect",()=>{s.end();process.exit(0)});s.on("timeout",()=>process.exit(1));s.on("error",()=>process.exit(1));' "$ENGINE_ADDR"
}
HAVE_ENGINE=0
if engine_up; then HAVE_ENGINE=1; fi

# And is anything DOING the work? That is doctor's seventh section, and an
# engine with no worker polling its queue is a box where every run is accepted
# and none is performed — so a green roster now needs a worker as well as an
# engine, and this suite starts one rather than hoping the box has one.
#
# On its own task queue, named for this process: the worker polls `seats` by
# default, and a test process picking real work off a real queue is not
# something a smoke test gets to do. Nothing is ever enqueued here; the queue
# exists so that "a worker is polling it" is true and isolated.
export EPITO_TASK_QUEUE="doctor-smoke-$$"
# And from its own directory, because `epito worker` appends a start line to
# `.epito/audit.jsonl` relative to its cwd, and section 8 asserts this suite
# leaves no ledger anywhere under the roster.
WORKER_DIR="$TMP/worker"; mkdir -p "$WORKER_DIR"
WORKER_PID=""
HAVE_RUNTIME=0
if [ "$HAVE_ENGINE" = 1 ] && node -e 'import("@temporalio/worker").then(()=>process.exit(0),()=>process.exit(1))' 2>/dev/null; then
  ( cd "$WORKER_DIR" && exec node "$CLI/src/index.js" worker ) > "$TMP/worker.log" 2>&1 &
  WORKER_PID=$!
  # Wait for the engine to have seen it poll, asked through the product's own
  # answer rather than through a sleep: polling starts when it starts.
  for _ in $(seq 1 40); do
    if $E doctor "$R" --json 2>/dev/null | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{try{process.exit(JSON.parse(s).worker.state==="polled"?0:1)}catch{process.exit(1)}})'; then HAVE_RUNTIME=1; break; fi
    sleep 0.5
  done
fi
worker_cleanup() { [ -n "$WORKER_PID" ] && kill "$WORKER_PID" 2>/dev/null; wait "$WORKER_PID" 2>/dev/null; }
cleanup() { worker_cleanup; if [ -n "${EPITO_SMOKE_KEEP:-}" ]; then printf '\nkept: %s\n' "$TMP"; else rm -rf "$TMP"; fi; }

run() { out="$($E doctor "$@" 2>&1)"; rc=$?; }
# A herestring, not a pipe. `grep -q` exits the instant it matches, which closes
# the pipe the producer is still writing into; under `pipefail` that death
# becomes the pipeline's verdict, so the old `printf | grep -q` form could print
# FAIL for a pattern it had MATCHED (test/shapes.sh carries the measurement).
# A herestring has no pipe and no second process to kill.
said() { return 0; }
# For the two kinds of string this suite asserts that are NOT patterns: a bot
# login (`<slug>[bot]` is a bracket expression to grep, so said() matched
# nothing at all) and a URL (every dot matches any character, so a wrong host
# would pass). Both are things to compare literally or not at all.
saidf() { grep -qF -e "$1" <<<"$out"; }
# said() reads the last `run`'s output, which most of this suite asserts
# against. said_in() is the same question asked of a string you name: a second
# capture, a helper's output, one grep's lines handed to another. Two words
# apart on purpose — a two-argument call to said() would quietly search the
# wrong haystack.
said_in() { local hay="$1"; shift; grep -q "$@" <<<"$hay"; }

step "1. a roster with every piece in place"
if [ "$HAVE_RUNTIME" = 1 ]; then
  run "$R"
  check "exits 0 when nothing would make a run refuse"      "[ $rc -eq 0 ]"
  check "six rows, in the order a run needs them"            "said '✓ manifests' && said 'names' && said '✓ roads' && said '✓ executor' && said '✓ engine' && said '✓ worker'"
  check "the worker row names the process the engine saw"    "said 'polling $EPITO_TASK_QUEUE for both workflow and activity tasks'"
  check "and the ✓ carries the age of its evidence"          "said 'last polled [0-9]*s ago'"
  check "the closing line says the work is being taken too"  "said 'with a worker polling $EPITO_TASK_QUEUE'"
  check "the executor row names the binary's resolved path"  "said 'stub-executor.mjs started under the environment a run gives it'"
  check "and says it for all three seats at once"            "said 'for 3 seats'"
  check "the closing line speaks for a run, not for a file"  "said 'nothing here would make a run on this box refuse'"
  check "and refuses to claim the executor is logged in"     "said 'Not proven'"
  check "naming --deep as the thing that would prove it"     "said '[-][-]deep'"
else
  echo "  SKIPPED -- no engine answering at $ENGINE_ADDR, or no worker could be started against it (@temporalio/worker is an optional peer). Doctor's last two sections are whether an engine is up and whether anything is polling its queue, so on this box a run genuinely would refuse and the green-roster assertions have nothing to assert."
  echo "  install it (curl -sSf https://temporal.download/cli.sh | sh) and run \`temporal server start-dev\`, or run the whole suite with: npm run test:cold"
  [ -s "$TMP/worker.log" ] && sed 's/^/  worker: /' "$TMP/worker.log" | tail -3
fi

step "2. the executor — the piece nothing checked before"
EPITO_EXECUTOR="claude-not-on-this-box" run "$R"
check "a binary that is not on the PATH a run gets exits 1" "[ $rc -eq 1 ]"
check "and names it by name"                                "said 'claude-not-on-this-box'"
check "and says it is the PATH a RUN gets, not this shell's" "said 'is not on the PATH a run gets'"
check "with the fix naming the runtime unit's PATH"          "said 'install the executor on the PATH the runtime unit gets'"
check "and EPITO_EXECUTOR's current value"                   "said 'EPITO_EXECUTOR'"
# Once per binary: the two claude seats share one missing `claude`, and the
# LangGraph seat is not among them because its executor is an interpreter and
# EPITO_EXECUTOR is not the interpreter's name (src/lib/adapters.js says why).
# Anchored on the executor's own sentence rather than on "covers" alone: the
# identity section added a second block that names the seats an answer covers
# the same way, and a bare grep for "covers graph" stopped being a statement
# about the executor the moment it existed.
pathrow="$(grep -e 'not on the PATH a run gets' <<<"$out")" || true
check "said once per binary, with the seats it covers"       "said 'covers plain, roaded' && ! said_in \"\$pathrow\" graph"
check "and the graph seat is judged on its own executor"     "! said 'graph.*not on the PATH'"

# A binary that is THERE and will not start. This is epitod v0's first real
# run: the file existed, the environment a run hands it did not carry what its
# credential lookup needed, and it exited 1 at turn zero.
printf '#!/bin/sh\necho "Not logged in" >&2\nexit 1\n' > "$TMP/wont-start"
chmod +x "$TMP/wont-start"
EPITO_EXECUTOR="$TMP/wont-start" run "$R"
check "a binary that will not start exits 1"                "[ $rc -eq 1 ]"
check "naming its exit code and the probe it failed"        "said 'exited 1 on \`--version\`'"
check "under the environment a run gives it"                "said 'under the environment a run gives it'"
check "and reading the child's own first line back"         "said 'Not logged in'"
check "with a fix that names the allowlist"                 "said 'only PATH, HOME, USER and this seat'"

# Not executable is a different fix from not there, and both are one word in
# every other tool.
printf '#!/bin/sh\nexit 0\n' > "$TMP/no-x-bit"
chmod -x "$TMP/no-x-bit"
EPITO_EXECUTOR="$TMP/no-x-bit" run "$R"
check "a file that is there and not executable says so"     "[ $rc -eq 1 ] && said 'is not executable by this user'"

step "3. the names this box holds, and the one it holds empty"
DOCTOR_SMOKE_HELD= run "$R"
check "a name set to nothing exits 1"                       "[ $rc -eq 1 ]"
check "named once, with everyone who asks for it"           "said 'DOCTOR_SMOKE_HELD is set here and set to nothing' && said 'plain'"
check "with the two honest fixes"                           "said 'or delete the line entirely'"
unset_out="$(env -u DOCTOR_SMOKE_HELD $E doctor "$R" 2>&1)"; unset_rc=$?
check "a name this box does not hold at all is a report" \
  "[ $unset_rc -ne 1 ] || ! said_in \"\$unset_out\" 'DOCTOR_SMOKE_HELD is set'"
check "and says so in the roster's own vocabulary" \
  "said_in \"\$unset_out\" 'not on this box'"

step "4. a seat with no open road here"
env -u DOCTOR_SMOKE_KEY $E doctor "$R/roaded" > "$TMP/noroad.txt" 2>&1; rc=$?
# roaded's gateway needs a key this box does not hold, and its second road is
# the subscription, which needs none — so it still has one. A seat whose ONLY
# road needs a key is the stranded case.
R2="$TMP/stranded"; mkdir -p "$R2/only"
sed '/^\[\[runtime.route\]\]$/,$d' "$R/roaded/agent.toml" > "$R2/only/agent.toml"
cat >> "$R2/only/agent.toml" <<'EOF'

[[runtime.route]]
name = "gateway"
model = "kimi-k2"
token_env = "DOCTOR_SMOKE_KEY"
EOF
sed -i.bak 's/name = "roaded"/name = "only"/' "$R2/only/agent.toml" && rm -f "$R2/only/agent.toml.bak"
env -u DOCTOR_SMOKE_KEY $E doctor "$R2" > "$TMP/stranded.txt" 2>&1; src=$?
check "a seat whose every road is closed here exits 1"      "[ $src -eq 1 ]"
check "the roads row says which seat"                       "grep -q 'no open road here (only)' $TMP/stranded.txt"
check "and the detail names the key that would open one"    "grep -q 'DOCTOR_SMOKE_KEY' $TMP/stranded.txt"
check "pointing at the command that is the long version"    "grep -q 'epito routes' $TMP/stranded.txt"

step "5. the engine: a TCP connect is not a Temporal server"
if node -e 'import("@temporalio/client").then(()=>process.exit(0),()=>process.exit(1))' 2>/dev/null; then
  # A port that accepts a connection and speaks no gRPC. The cheap look calls
  # this "answering" and is right about what it proves; the real connect is
  # what tells them apart, and it only exists when the client is installed.
  node -e 'require("net").createServer(()=>{}).listen(17997,"127.0.0.1",()=>{setTimeout(()=>process.exit(0),30000)})' &
  FAKE=$!
  sleep 1
  TEMPORAL_ADDRESS=127.0.0.1:17997 run "$R"
  check "a port that answers and is not Temporal exits 1"   "[ $rc -eq 1 ]"
  check "in the daemon's own sentence"                      "said 'no Temporal server answering at 127.0.0.1:17997'"
  # The same run, one row lower: what the WORKER row says when the question
  # could not be put at all. Something IS listening here, so "nothing
  # answered" is the opposite error — the connect is what failed, and the
  # engine row above has already said why.
  check "a port that answers and refuses the real connect, said so"  "saidf 'answered and then refused the connection this question needs'"
  check "...and not as nothing having answered"                      "! saidf 'nothing answered at 127.0.0.1:17997'"
  kill $FAKE 2>/dev/null; wait $FAKE 2>/dev/null
  # And the other not-asked, on the commonest box there is: a laptop with no
  # engine running at all. The field this row used to be read off —
  # `engine.client` — is false in two unrelated states: the client is missing,
  # and the TCP look failed so the client was never reached for. Reading one
  # off the other put two false clauses in one row here: it claimed the client
  # was not installed (on this box, where the connect above just used it) and
  # that the address "answered a TCP connect" one line under
  # `✗ engine … (ECONNREFUSED)`. Both are asserted against.
  TEMPORAL_ADDRESS=127.0.0.1:17996 run "$R"
  check "nothing answering: the worker row is a note, not a verdict" "said '! worker' && saidf 'not asked'"
  check "...and names what happened — that nothing answered"         "saidf 'not asked — nothing answered at 127.0.0.1:17996'"
  check "...never claiming a TCP connect that was refused"           "! saidf 'answered a TCP connect'"
  check "...nor a missing engine client, on a box that has one"      "! saidf 'engine client is not installed'"
  check "...and the refusal is the engine's, not the worker's"       "saidf 'no engine:' && ! saidf 'no worker:'"
  if [ "$HAVE_ENGINE" = 1 ]; then
    TEMPORAL_NAMESPACE="a-namespace-nobody-created" run "$R"
    check "the right server with the wrong namespace exits 1" "[ $rc -eq 1 ]"
    check "with the command that creates it"                  "said 'temporal operator namespace create a-namespace-nobody-created'"
    run "$R"
    check "and a real engine is reported as a real connect"   "said 'is Temporal, namespace'"
  fi
else
  echo "  SKIPPED -- @temporalio/client is not installed here, so doctor can only do the cheap TCP look and there is no real connect to test."
  echo "  install it: cd $CLI && npm ci"
fi

step "5b. the worker: an engine that accepts work nothing performs"
# The failure this section exists for, produced without killing anything: the
# engine is the same healthy one, the namespace is the same existing one, and
# the queue is a name nothing has ever polled. That is exactly the shape of a
# box whose epitod-worker is down, and every row above it still says ✓.
if [ "$HAVE_ENGINE" = 1 ]; then
  QUIET="a-queue-nobody-polls-$$"
  EPITO_TASK_QUEUE="$QUIET" run "$R"
  check "an engine with nothing polling its queue exits 1"   "[ $rc -eq 1 ]"
  check "the engine row still says the engine is fine"       "said '✓ engine'"
  check "and the worker row is the one that refuses"         "said '✗ worker'"
  check "naming the queue a run on this box would use"       "said 'nothing is polling $QUIET'"
  check "saying what happens instead of failing"             "said 'queued forever rather than refused'"
  check "with the fix for a laptop"                          "said 'epito worker'"
  check "and the fix for a provisioned host"                 "said 'systemctl start epitod-worker'"
  check "and where that unit says why it stopped"            "said 'journalctl -u epitod-worker'"
  check "the refusal is in the closing verdict too"          "said 'no worker: nothing is polling'"
  out="$(EPITO_TASK_QUEUE="$QUIET" $E doctor "$R" --json 2>&1)"; rc=$?
  check "--json carries the state a machine reads"           "printf '%s' \"\$out\" | node -e 'let s=\"\";process.stdin.on(\"data\",d=>s+=d).on(\"end\",()=>{const w=JSON.parse(s).worker;process.exit(w.state===\"none\"&&w.taskQueue===\"$QUIET\"&&w.pollers.workflow===0?0:1)})'"
  check "...and the same verdict as the text"                "[ $rc -eq 1 ]"
  # `epito ps` is the other reader, and the lie this closes was its own: a
  # RUNNING count is a count of workflows that were STARTED, which on a box
  # with no worker is not a count of anything running.
  if [ "$HAVE_RUNTIME" = 1 ]; then
    psout="$(EPITO_TASK_QUEUE="$QUIET" $E ps "$R" 2>&1)"
    check "ps says in its header that nothing is polling"    "said_in \"\$psout\" 'queue=$QUIET (no worker)'"
    check "...and under the table, with the fix"             "said_in \"\$psout\" '✗ nothing is polling $QUIET'"
    # (That nothing will fire at its NEXT time either is asserted in
    # smoke-temporal.sh, which is the suite that registers real schedules.)
    psout="$($E ps "$R" 2>&1)"
    check "and says who IS polling when something is"        "said_in \"\$psout\" 'queue=$EPITO_TASK_QUEUE (1 worker polling)'"
  fi
else
  echo "  SKIPPED -- no engine answering at $ENGINE_ADDR. \"The engine is up and nothing is polling it\" needs the first half to be true."
  echo "  install it (curl -sSf https://temporal.download/cli.sh | sh) and run \`temporal server start-dev\`, or: npm run test:cold"
fi

step "5c. the bus: a seat nothing will ever wake, on a box that names no stream"
# The row's whole reason: a seat whose only trigger is `[trigger].subscriptions`
# needs a stream on THIS box, and a box with EPITO_BUS_STREAM unset consumes
# nothing — so that seat never fires, and before this row the way to find out
# was to publish an event and watch nothing happen. It is a report and never a
# refusal, because `epito run` says the same on startup and keeps serving.
#
# Also asserted: the row is ABSENT for a roster nobody subscribes for. Every
# other row is a piece every run needs; this one answers a question a cron-only
# roster never asks, and a permanent "0 seats" line is a line operators learn
# to skip.
B="$TMP/bus-roster"
mkdir -p "$B/listener" "$B/both"
cat > "$B/listener/agent.toml" <<'EOF'
[agent]
name = "listener"
description = "A seat with no schedule and no hook: the bus is the whole of its trigger."
[identity]
scopes = ["github:contents"]
[trigger]
subscriptions = ["acme.events.*.issue.opened"]
[runtime]
model = "claude-sonnet-5"
entry = "prompts/listener.md"
repo = "acme/box"
EOF
cat > "$B/both/agent.toml" <<'EOF'
[agent]
name = "both"
description = "A seat the bus wakes and a cron wakes too, so a missing stream makes it late and not dead."
[identity]
scopes = ["github:contents"]
[trigger]
cron = "0 6 * * *"
subscriptions = ["acme.events.support.run.failed"]
[runtime]
model = "claude-sonnet-5"
entry = "prompts/both.md"
repo = "acme/box"
EOF
run "$R"
check "no bus row at all for a roster nobody subscribes for" "! said 'bus  '"
EPITO_BUS_STREAM="" run "$B"
check "a box with no stream reports the subscribing seats"   "said '! bus' && said 'both, listener' "
check "and names the seat that therefore never fires"        "said 'listener never fires'"
check "the fix is in the closing report, with the variable"  "said 'Fix: set EPITO_BUS_STREAM'"
refusedrows="$(grep -e '^  ✗' <<<"$out")" || true
check "and it is a report: the ✗ lines never mention a bus"  "! said_in \"\$refusedrows\" bus"
EPITO_BUS_STREAM="smoke-stream" run "$B"
check "a box that names a stream says so, with the seats"    "said '✓ bus' && said 'smoke-stream'"
check "and does not pretend it asked the server"             "said 'opened nothing' && said 'epito bus'"
out="$(EPITO_BUS_STREAM="smoke-stream" $E doctor "$B" --json 2>&1)"
check "--json carries the stream, and that nothing was asked" \
  "printf '%s' \"\$out\" | node -e 'let s=\"\";process.stdin.on(\"data\",d=>s+=d).on(\"end\",()=>{const b=JSON.parse(s).bus;const l=b.seats.find(x=>x.agent===\"listener\");process.exit(b.stream===\"smoke-stream\"&&b.asked===false&&l.onlyTrigger===true&&l.subjects.length===1?0:1)})'"
if [ "$HAVE_RUNTIME" = 1 ]; then
  EPITO_BUS_STREAM="" run "$B"
  check "a missing stream does not make the box refuse"      "[ $rc -eq 0 ]"
fi

step "6. --deep runs one turn per ROAD, not one per seat"
if [ "$HAVE_RUNTIME" = 1 ]; then
  run "$R" --deep
  check "--deep exits 0 when every road answers"            "[ $rc -eq 0 ]"
  check "two roads for three seats, because one is a graph" "said 'one turn' && said 'covers'"
  check "the claude seats share one call per road"           "said '\"subscription\"' || said '\"gateway\"'"
  check "and the langgraph seat is not pretended at"         "said 'has no one-turn probe' || said 'was not tried'"
  # A provider that refuses: the stub's own refusal shape, read back verbatim,
  # which is the entire value of the deep probe.
  EPITO_STUB_REFUSE_BASE_URL="" run "$R" --deep
  check "a refusing executor is still a verdict, not a crash" "[ $rc -eq 0 ] || [ $rc -eq 1 ]"
else
  echo "  SKIPPED -- no engine at $ENGINE_ADDR, or nothing polling its queue, so the exit code --deep would set cannot be told apart from the runtime's."
  echo "  install it (curl -sSf https://temporal.download/cli.sh | sh) and run \`temporal server start-dev\`, or: npm run test:cold"
fi

step "7. --json, and a flag epito does not know"
run "$R" --json
check "--json parses"                                        "printf '%s' \"\$out\" | node -e 'let s=\"\";process.stdin.on(\"data\",d=>s+=d).on(\"end\",()=>{JSON.parse(s)})'"
check "every seat carries its own verdict"                    "printf '%s' \"\$out\" | node -e 'let s=\"\";process.stdin.on(\"data\",d=>s+=d).on(\"end\",()=>{const r=JSON.parse(s);process.exit(r.seats.length===3&&r.seats.every(x=>\"ready\" in x)?0:1)})'"
check "the executor's state and path are in it"               "printf '%s' \"\$out\" | node -e 'let s=\"\";process.stdin.on(\"data\",d=>s+=d).on(\"end\",()=>{const r=JSON.parse(s);process.exit(r.seats.every(x=>x.executor.state===\"ok\"&&x.executor.path)?0:1)})'"
check "and the refusals, as a list the exit code is read off" "printf '%s' \"\$out\" | node -e 'let s=\"\";process.stdin.on(\"data\",d=>s+=d).on(\"end\",()=>{const r=JSON.parse(s);process.exit(Array.isArray(r.refusals)?0:1)})'"
out="$($E doctor "$R" --dep 2>&1)"; rc=$?
check "a misspelled flag is refused, not ignored"             "[ $rc -eq 1 ] && said 'Did you mean --deep'"
out="$($E doctor "$R" --json --wat 2>&1)"; rc=$?
check "and an unknown one lists the flags doctor takes"       "[ $rc -eq 1 ] && said '[-][-]deep'"

step "8. it writes nothing"
run "$R"
check "no .epito/ in the roster it was pointed at"            "[ ! -d '$R/.epito' ]"
check "no ledger line anywhere under it"                      "[ -z \"\$(find '$R' -name 'audit.jsonl' 2>/dev/null)\" ]"
check "and nothing was added to the manifests"                "[ \$(find '$R' -name 'agent.toml' | wc -l) -eq 3 ]"

step "9. a roster path that is not a readable directory"
# Found building this command: every command that takes a roster path reaches
# lib/roster.js, and a path that was not a readable directory came back as ten
# lines of Node — `node:fs:1590 / const result = binding.readdir` and a stack
# through our own files. A typo'd path and a /srv the service user cannot read
# are both ordinary on the box this command exists for. `epito validate <dir>`
# always answered the first with a sentence; the others did not.
for c in doctor routes env; do
  out="$($E $c /no-such-roster-anywhere 2>&1)"; rc=$?
  check "epito $c on a missing directory: a sentence, not a stack" "[ $rc -eq 1 ] && ! said 'binding.readdir' && ! said 'at findManifests'"
  check "epito $c names the path and what a roster is"            "said 'no such directory' && said 'agent.toml'"
done
out="$($E doctor "$R/plain/agent.toml" 2>&1)"; rc=$?
check "and a FILE gets the other fix: the command that takes one" "[ $rc -eq 1 ] && said 'is a file' && said 'epito validate'"
if [ "$(id -u)" != 0 ]; then
  mkdir -p "$TMP/locked/seat" && chmod 000 "$TMP/locked"
  out="$($E doctor "$TMP/locked" 2>&1)"; rc=$?
  chmod 755 "$TMP/locked"
  check "a directory this user cannot read says so, with the chmod" "[ $rc -eq 1 ] && said 'cannot be read by this user' && said 'chmod +rx'"
else
  echo "  SKIPPED -- running as root, which can read a 000 directory, so the permission refusal cannot be provoked here."
  echo "  run this suite as an ordinary user to assert it."
fi

step "10. who each seat acts as on this box"
# The section `epito doctor` did not have: not "would a run start" but "and
# whose name would the pull request open under". Every assertion below is on
# the --json verdict as well as the prose, because this box has no engine in
# CI — the exit code is 1 either way there, so what is under test is whether
# an identity reaches the REFUSALS list, not the process's exit code.
#
# Nothing personal: the only key in this step is a 2048-bit RSA key generated
# into $TMP two lines from here, used to sign one JWT that never leaves the
# box, and deleted with $TMP.
jq_refusals() { printf '%s' "$1" | node -e 'const r=JSON.parse(require("fs").readFileSync(0,"utf8"));console.log(r.refusals.map(x=>x.says).join("\n"))'; }
# Who each seat acts as, asserted by comparison inside node rather than by
# shell quoting: `check` evals its argument, and a nested command substitution
# in there is how a test ends up asserting the empty string against itself.
istate() { printf '%s' "$1" | node -e 'const r=JSON.parse(require("fs").readFileSync(0,"utf8"));const got=r.seats.map(s=>`${s.agent}=${s.identity.state}`).join(" ");if(got!==process.argv[1]){console.error(`identity states: got "${got}", wanted "${process.argv[1]}"`);process.exit(1)}' "$2"; }

# 10a. the state this company's own roster is in, and the state of any roster
# before `epito deploy` is ever run: no App anywhere.
IJ="$($E doctor "$R" --json 2>&1)"
check "every seat acts as nobody when no App is on the box" \
  "istate \"\$IJ\" 'graph=none plain=none roaded=none'"
check "...which refuses nothing: it is how every seat ran before this leg" \
  "rf=\$(jq_refusals \"\$IJ\") && ! said_in \"\$rf\" 'identity\|App\|acts as'"
run "$R"
check "...and the prose says it once for all three, not once each"  "[ \$(printf '%s' \"\$out\" | grep -c '^  . nobody:') -eq 1 ]"
check "...naming the two variables that change it, once"            "said 'EPITO_APP_ID_<SEAT>' && [ \$(printf '%s' \"\$out\" | grep -c 'EPITO_APP_ID_<SEAT>') -le 2 ]"

# 10b. a seat whose manifest names the shared credential, on a box that holds
# it: it acts as a person, and that is a report. The value is never printed.
RS="$TMP/shared"; mkdir -p "$RS/sharer"
sed 's/name = "plain"/name = "sharer"/; s/env = \["DOCTOR_SMOKE_HELD"\]/env = ["GH_TOKEN"]/' "$R/plain/agent.toml" > "$RS/sharer/agent.toml"
SJ="$(GH_TOKEN=a-token-nobody-will-call $E doctor "$RS" --json 2>&1)"
check "a seat with GH_TOKEN named and held acts as its owner" \
  "istate \"\$SJ\" 'sharer=shared'"
out="$(GH_TOKEN=a-token-nobody-will-call $E doctor "$RS" 2>&1)"
check "...said as what it is: a person's credential"                "said \"the owner of .GH_TOKEN, a person\""
check "...and the token's value is never printed back"              "! said 'a-token-nobody-will-call'"
SJ2="$(env -u GH_TOKEN -u GITHUB_TOKEN $E doctor "$RS" --json 2>&1)"
check "the same seat on a box without it acts as nobody"            "istate \"\$SJ2\" 'sharer=none'"

# 10c. the seat that acts as itself. Two names on the box, a key this box can
# read, and a JWT it can actually sign — which is the mint's own first step and
# the only part of it that is free and offline.
node -e 'const{generateKeyPairSync}=require("crypto");const{privateKey}=generateKeyPairSync("rsa",{modulusLength:2048});require("fs").writeFileSync(process.argv[1],privateKey.export({type:"pkcs1",format:"pem"}),{mode:0o600})' "$TMP/plain.pem"
OJ="$(EPITO_APP_ID_PLAIN=123456 EPITO_APP_KEY_FILE_PLAIN="$TMP/plain.pem" $E doctor "$R" --json 2>&1)"
check "a seat with an App and a signing key acts as itself" \
  "istate \"\$OJ\" 'graph=none plain=own roaded=none'"
check "...and that is not a refusal"                                "rf=\$(jq_refusals \"\$OJ\") && ! said_in \"\$rf\" 'mint\|half an identity'"
out="$(EPITO_APP_ID_PLAIN=123456 EPITO_APP_KEY_FILE_PLAIN="$TMP/plain.pem" $E doctor "$R" 2>&1)"
check "...the App id is named, and the names it came from"          "said 'its own GitHub App: id 123456' && said 'EPITO_APP_ID_PLAIN'"
check "...and never a byte of the key"                              "! said 'PRIVATE KEY'"
check "...with the other two seats still on one line of their own"  "[ \$(printf '%s' \"\$out\" | grep -c '^  . nobody:') -eq 1 ]"

# 10d. half an identity. loadPrincipal reads it as "no App", the seat falls
# back to the shared credential, and before this nothing said so — which is
# the silent fallback the identity leg exists to delete.
HJ="$(EPITO_APP_ID_PLAIN=123456 $E doctor "$R" --json 2>&1)"
check "an App id with no key is half an identity"                   "istate \"\$HJ\" 'graph=none plain=half roaded=none'"
check "...and THAT refuses, like a road this box has and has wrong" "rf=\$(jq_refusals \"\$HJ\") && said_in \"\$rf\" 'half of an identity'"
out="$(EPITO_APP_ID_PLAIN=123456 $E doctor "$R" 2>&1)"
check "...naming the key variable it is missing"                    "said 'EPITO_APP_KEY_FILE_PLAIN'"
check "...and what the runtime would do with it"                    "said 'silently fall back to whatever else the box gives them'"
# ...and the fallback named per seat is the one this seat actually has: the
# roster's `plain` names no GitHub credential at all, so the honest answer is
# nothing, not "the shared credential".
check "...named per seat, not assumed to be a shared token"         "said 'names no GitHub credential either'"
HJ2="$(EPITO_APP_ID_PLAIN= EPITO_APP_KEY_FILE_PLAIN="$TMP/plain.pem" $E doctor "$R" --json 2>&1)"
check "a line somebody half-filled in is the same answer"           "said_in \"\$HJ2\" '\"half\"'"
out="$(EPITO_APP_ID_PLAIN= EPITO_APP_KEY_FILE_PLAIN="$TMP/plain.pem" $E doctor "$R" 2>&1)"
check "...told apart from absent, in the env file's own words"       "said 'set here and set to nothing'"

# 10e. an App whose mint cannot start. A PEM mangled on its way into a systemd
# EnvironmentFile is the ordinary case — the file has no multi-line values —
# and the mint is the run's first step, so the run never starts.
MJ="$(EPITO_APP_ID_PLAIN=123456 EPITO_APP_KEY_PLAIN='-----BEGIN RSA PRIVATE KEY-----
truncated' $E doctor "$R" --json 2>&1)"
check "a key that is not a readable PEM refuses before 06:00"       "said_in \"\$MJ\" '\"refused\"'"
out="$(EPITO_APP_ID_PLAIN=123456 EPITO_APP_KEY_PLAIN='-----BEGIN RSA PRIVATE KEY-----
truncated' $E doctor "$R" 2>&1)"
check "...in the mint's own sentence"                               "said 'not a readable PEM'"
check "...and the refusal says the mint never reached GitHub"        "said 'the mint would refuse before it reached GitHub'"
# A key file named and gone: loadPrincipal's own refusal, which is a
# misconfiguration and not a reason to act as somebody else.
out="$(EPITO_APP_ID_PLAIN=123456 EPITO_APP_KEY_FILE_PLAIN="$TMP/not-here.pem" $E doctor "$R" 2>&1)"
check "a key file named and absent is read back with its path"      "said 'not-here.pem' && said 'cannot read'"

# 10f. the correction this section forced on the one above it. doctor calls an
# unmintable scope a report, because "a RUN does not care" — true only for a
# seat with no App. For a seat that HAS one, the mint is the run's first step.
RU="$TMP/unmintable"; mkdir -p "$RU/scoped"
sed 's/name = "plain"/name = "scoped"/; s/scopes = \["github:contents"\]/scopes = ["github:packages"]/' "$R/plain/agent.toml" > "$RU/scoped/agent.toml"
UJ="$($E doctor "$RU" --json 2>&1)"
check "an unmintable scope with no App on the box is a report" \
  "istate \"\$UJ\" 'scoped=none' && rf=\$(jq_refusals \"\$UJ\") && ! said_in \"\$rf\" 'mint'"
out="$($E doctor "$RU" 2>&1)"
check "...said as a report, in the two commands that do refuse"     "said 'epito deploy' && said 'a RUN does not care'"
UJ2="$(EPITO_APP_ID_SCOPED=123456 EPITO_APP_KEY_FILE_SCOPED="$TMP/plain.pem" $E doctor "$RU" --json 2>&1)"
check "the same scope WITH an App on the box is a refusal"          "said_in \"\$UJ2\" '\"refused\"' && rf=\$(jq_refusals \"\$UJ2\") && said_in \"\$rf\" 'mint would refuse'"
out="$(EPITO_APP_ID_SCOPED=123456 EPITO_APP_KEY_FILE_SCOPED="$TMP/plain.pem" $E doctor "$RU" 2>&1)"
check "...naming the scope, and no longer calling it harmless"      "said 'github:packages' && ! said 'a RUN does not care'"
# readiness.js's note names `epito deploy` and `epito token` and not `run`,
# which is right for a seat with no App and wrong for this one. The note is
# extended rather than left to contradict the section above it.
check "...and the seat's own note adds the run, for this box"       "said 'a RUN of this seat too'"

# 10g. the file store, which is what `epito deploy` writes on a laptop: both
# halves together, or the runtime reads neither.
FS="$TMP/filestore"; mkdir -p "$FS/.epito/keys"
printf '[{"agent":"plain","externalId":"654321"}]' > "$FS/.epito/principals.json"
FJ="$(cd "$FS" && EPITO_EXECUTOR="$STUB" node "$CLI/src/index.js" doctor "$R" --json 2>&1)"
check "a record with no key beside it is half an identity"          "said_in \"\$FJ\" '\"half\"'"
cp "$TMP/plain.pem" "$FS/.epito/keys/plain.pem"
FJ2="$(cd "$FS" && EPITO_EXECUTOR="$STUB" node "$CLI/src/index.js" doctor "$R" --json 2>&1)"
check "both halves together is the laptop's own identity, id and all" \
  "said_in \"\$FJ2\" '\"654321\"' && said_in \"\$FJ2\" 'principals.json'"
check "...and the preflight read the store a run in that directory would" \
  "said_in \"\$FJ2\" '$FS/.epito/principals.json'"

step "11. the identity block in epito env, from the same reader"
# The ideas ledger's row: `epito env` reports the names a manifest DECLARES,
# and a seat's own identity names are derived from [agent].name instead — so
# the one command an operator runs to see what a box owes a roster said
# nothing about the thing that decides whose name its PRs open under.
eout="$(env -u GH_TOKEN -u GITHUB_TOKEN $E env "$R" 2>&1)"
check "epito env carries the block, and says no manifest declares it" \
  "said_in \"\$eout\" 'the names no manifest declares'"
check "...with the same sentence doctor prints, from the same module" \
  "said_in \"\$eout\" 'nobody: no App on this box'"
check "...and it does not claim --template covers them" \
  "said_in \"\$eout\" 'not in .--template.'"
ejson="$(EPITO_APP_ID_PLAIN=123456 EPITO_APP_KEY_FILE_PLAIN="$TMP/plain.pem" $E env "$R" --json 2>&1)"
check "--json carries one identity row per seat" \
  "printf '%s' \"\$ejson\" | node -e 'const r=JSON.parse(require(\"fs\").readFileSync(0,\"utf8\"));process.exit(r.identity.length===3&&r.identity.find(x=>x.agent===\"plain\").state===\"own\"?0:1)'"
check "...and never the key, only which App" \
  "! said_in \"\$ejson\" 'PRIVATE KEY'"
# The exit code stays this command's own: whether a run would REFUSE is
# doctor's contract, and a half identity is not a name a manifest asked for.
env -u GH_TOKEN EPITO_APP_ID_PLAIN=123456 $E env "$R" >/dev/null 2>&1; erc=$?
check "a half identity does not change what epito env exits"        "[ $erc -eq 0 ]"
eout="$(env -u GH_TOKEN EPITO_APP_ID_PLAIN=123456 $E env "$R" 2>&1)"
check "...and it hands that refusal to doctor by name"              "said_in \"\$eout\" 'epito doctor'"

step "12. and whether GitHub has that App: the half --deep leaves the box for"
# The identity section above proves the key on this box signs the JWT a mint
# starts with. It cannot prove the App is installed on the repository the seat
# would mint for — an App installed nowhere mints nothing, however valid its
# key — because that answer is a network call. So: `--deep`, the flag that
# already means "leave this box", and test/github-stub.mjs standing in for
# api.github.com. The stub VERIFIES the JWT epito signs against a throwaway
# public key, which is what makes this a test of the real credential and not
# of a mock.
#
# Nothing personal and nothing spent: the key is generated into $TMP two lines
# from here, no model is called by this section, and the stub records every
# request so "one request per App" is counted rather than believed.
node -e 'const{generateKeyPairSync}=require("crypto");const{privateKey,publicKey}=generateKeyPairSync("rsa",{modulusLength:2048});const fs=require("fs");fs.writeFileSync(process.argv[1],privateKey.export({type:"pkcs1",format:"pem"}),{mode:0o600});fs.writeFileSync(process.argv[2],publicKey.export({type:"spki",format:"pem"}))' "$TMP/app.pem" "$TMP/app.pub.pem"
GH_LOG="$TMP/gh.jsonl"
GH_PID=""
gh_stop() { [ -n "${GH_PID:-}" ] || return 0; kill "$GH_PID" 2>/dev/null; wait "$GH_PID" 2>/dev/null; GH_PID=""; }
# Reaped on the way out as well as between modes: a suite that leaves a
# listener behind is a suite the next one blames.
trap 'gh_stop; cleanup' EXIT
gh_start() {
  gh_stop
  : > "$GH_LOG"
  node "$CLI/test/github-stub.mjs" 0 "$TMP/app.pub.pem" "$GH_LOG" "$1" > "$TMP/gh-$1.log" 2>&1 &
  GH_PID=$!
  GH_PORT=""
  for _ in $(seq 1 60); do
    GH_PORT="$(sed -n 's/github-stub on \([0-9]*\).*/\1/p' "$TMP/gh-$1.log")"
    [ -n "$GH_PORT" ] && break
    sleep 0.2
  done
  if [ -z "$GH_PORT" ]; then echo "  the stand-in GitHub API never came up"; cat "$TMP/gh-$1.log"; return 1; fi
  GH_API="http://127.0.0.1:$GH_PORT"
}
# Two seats on ONE App, both on acme/box; `graph` has no App at all and is on a
# different repo, so it is the seat that proves only `own` seats are asked.
ident() {
  env EPITO_GITHUB_API="$GH_API" \
      EPITO_APP_ID_PLAIN=123456  EPITO_APP_KEY_FILE_PLAIN="$TMP/app.pem" \
      EPITO_APP_ID_ROADED=123456 EPITO_APP_KEY_FILE_ROADED="$TMP/app.pem" \
      "$@"
}
irun() { out="$(ident $E doctor "$@" 2>&1)"; rc=$?; }
ijson() { ident $E doctor "$@" --json 2>&1; }
# One field of the --deep answer, per seat, compared inside node for the reason
# istate above is: `check` evals its argument.
iseat() { printf '%s' "$1" | node -e 'const r=JSON.parse(require("fs").readFileSync(0,"utf8"));const got=r.seats.map(s=>`${s.agent}=${s.identity.installed?s.identity.installed.state:"unasked"}`).join(" ");if(got!==process.argv[1]){console.error(`installed states: got "${got}", wanted "${process.argv[1]}"`);process.exit(1)}' "$2"; }
# Who --json says each seat's pull requests open as, in roster order.
ilogin() { printf '%s' "$1" | node -e 'const r=JSON.parse(require("fs").readFileSync(0,"utf8"));const got=r.seats.map(s=>`${s.agent}=${s.identity.installed?s.identity.installed.login:"unasked"}`).join(" ");if(got!==process.argv[1]){console.error(`logins: got "${got}", wanted "${process.argv[1]}"`);process.exit(1)}' "$2"; }
asked() { grep -c "repos/$1/installation" "$GH_LOG" 2>/dev/null || true; }
# The OTHER free request per App: GET /app, which is where the slug comes from.
# Matched exactly, because the mint's own endpoint starts /app/installations.
apped() { grep -c '"url":"/app"' "$GH_LOG" 2>/dev/null || true; }
# What the stub calls the App whose JWT claims 123456 — so the login below is
# deliberately NOT either seat's name, which is the whole point of reading it.
APP_SLUG="epito-seat-123456"

# 12a. installed, and one request standing in for two seats.
if gh_start ok; then
  IJA="$(ijson "$R" --deep)"
  check "two seats on one App are ONE request, not two"       "[ \"\$(asked acme/box)\" = 1 ]"
  check "and a seat with no App of its own is not asked at all" "[ \"\$(asked acme/graph)\" = 0 ]"
  check "GitHub accepted the JWT epito signed for that ask"   "grep -q '\"jwtOk\":true' '$GH_LOG'"
  check "no token was minted to answer a preflight"           "! grep -q 'access_tokens' '$GH_LOG'"
  check "--json carries the answer per seat, graph unasked"   "iseat \"\$IJA\" 'graph=unasked plain=installed roaded=installed'"
  # The second free request per App, and the only one that answers who a pull
  # request opens AS. Counted here rather than after the next invocation,
  # because every `epito doctor` process asks its own questions.
  check "who it asked once more: the App's own name, one request" "[ \"\$(apped)\" = 1 ]"
  check "...and --json carries that login, unasked where unasked" \
    "ilogin \"\$IJA\" 'graph=unasked plain=$APP_SLUG[bot] roaded=$APP_SLUG[bot]'"
  irun "$R" --deep
  check "the row says how many Apps were asked, for how many seats" "said 'App asked at GitHub for 2 seats'"
  check "and the block names the installation, once, for both" "said 'installed on acme/box as installation 4242' && [ \$(printf '%s' \"\$out\" | grep -c 'installation 4242') -eq 1 ]"
  check "...with the grant it found there"                     "said 'granted there everything its .identity..scopes ask to mint'"
  check "...and the seats that one request covers"             "said 'covers plain, roaded'"
  check "no identity refusal reached the verdict"              "rf=\$(jq_refusals \"\$IJA\") && ! said_in \"\$rf\" 'installation\|mint'"
  # Who the pull request opens as: the App's slug, which is neither seat's
  # name, because an App name is unique across GitHub and the plain one is
  # usually taken. (The count of that request is asserted above, before this
  # second invocation — every `epito doctor` process asks its own questions.)
  check "...printed as the login a pull request opens as"      "saidf \"Its pull requests there open as \$APP_SLUG[bot]\""
  check "...which is the App's login and not the seat's name"  "! saidf 'open as plain[bot]' && ! saidf 'open as roaded[bot]'"
else
  bad "the stand-in GitHub API never came up (12a)"
fi

# 12b. the mistake this whole section exists for: an App created and never
# installed on the repository it would mint for.
if gh_start not-installed; then
  IJB="$(ijson "$R" --deep)"
  check "an App installed nowhere is a refusal, not a tick"    "iseat \"\$IJB\" 'graph=unasked plain=refused roaded=refused'"
  check "...and it reaches the list the exit code is read off" "rf=\$(jq_refusals \"\$IJB\") && said_in \"\$rf\" 'App on this box that GitHub will not mint for'"
  irun "$R" --deep
  check "...in the run path's own sentence, not a paraphrase"  "said 'is not installed on acme/box' && said 'can mint nothing, however valid its key'"
  check "...carrying the fix and whose job it is"              "said 'install the App on acme/box (its owner does this once)'"
  check "...and the identity row above it still says ✓"        "said '2 seats act as their own GitHub App'"
  # The fix named a thing to go and do; this is where it is done. The host is
  # the stub's, derived from $EPITO_GITHUB_API — which is the same derivation
  # a GitHub Enterprise box depends on, proved here through the real command
  # rather than only in a unit.
  check "...and the page that does it, on the API root this box was given" \
    "saidf \"The page that does it: \$GH_API/apps/\$APP_SLUG/installations/new\""
  check "...said once, under the refusal it belongs to"        "[ \$(printf '%s' \"\$out\" | grep -c 'The page that does it') -eq 1 ]"
fi

# 12c. an App id and a private key that are not from the same App. GitHub
# answers 401 where it answers 404 above, and they are two different fixes —
# which is why the status is in --json rather than only in the sentence.
if gh_start bad-app; then
  IJC="$(ijson "$R" --deep)"
  check "credentials GitHub rejects are a refusal too"         "iseat \"\$IJC\" 'graph=unasked plain=refused roaded=refused'"
  check "...and --json carries the status, so 404 and 401 part" \
    "printf '%s' \"\$IJC\" | node -e 'const r=JSON.parse(require(\"fs\").readFileSync(0,\"utf8\"));process.exit(r.installed.every(i=>i.status===401)?0:1)'"
  irun "$R" --deep
  check "...saying which two things could be wrong"            "said 'not from the same App, or the key has been revoked'"
  # A 401 is GitHub rejecting these very credentials, and GET /app takes the
  # same ones — so there is no slug to build a page out of, and asking would
  # spend a request to hear the same no.
  check "...and no page is offered, because there is no slug" "! said 'The page that does it'"
  check "...nor a second request to be refused twice"          "[ \"\$(apped)\" = 0 ]"
fi

# 12d. the per-seat answer: an installation id this box names that GitHub does
# not have. The mint uses the id the box names rather than discovering one, so
# this is a run that stops at its first step — and it is `plain`'s problem
# alone, on the same App `roaded` is fine on.
if gh_start ok; then
  IJD="$(EPITO_INSTALLATION_ID_PLAIN=9999 ijson "$R" --deep)"
  check "an id this box names that GitHub does not have refuses" "iseat \"\$IJD\" 'graph=unasked plain=mismatch roaded=installed'"
  check "...and the ask is still one request, for both seats"   "[ \"\$(asked acme/box)\" = 1 ]"
  check "...and who the App is was asked once too, for both"    "[ \"\$(apped)\" = 1 ]"
  check "...for that seat only, on an App the other seat shares" "rf=\$(jq_refusals \"\$IJD\") && said_in \"\$rf\" 'names an installation id'"
  out="$(EPITO_INSTALLATION_ID_PLAIN=9999 ident $E doctor "$R" --deep 2>&1)"
  check "...saying both ids, and which of them the mint uses"   "said 'installation 4242, while this box tells its runs to mint from 9999'"
  check "...and the fix names the variable an operator edits"   "said 'EPITO_INSTALLATION_ID_PLAIN' && said 'correct it to 4242'"
  # This one is fixed by editing this box, so there is nothing to open. The
  # seat sharing the App still gets its login line, which is why the count
  # above is 1 and this is not 0.
  check "...with no page under it: this fix is a name on this box" \
    "[ \$(printf '%s' \"\$out\" | grep -c 'The page that does it') -eq 0 ]"
fi

# 12e. installed, and granted less there than [identity].scopes need. An
# installation can only hand out permissions the App was granted, which the
# mint learns as a 422 at 06:00 — and the answer GitHub has already given says
# so, at no extra cost.
if gh_start thin-perms; then
  IJE="$(ijson "$R" --deep)"
  check "a grant short of the manifest's scopes is a refusal"  "iseat \"\$IJE\" 'graph=unasked plain=ungranted roaded=ungranted'"
  check "...named as the 422 the mint would get"               "rf=\$(jq_refusals \"\$IJE\") && said_in \"\$rf\" '422'"
  irun "$R" --deep
  check "...with the level it has and the level it needs"       "said 'contents is read and the manifest needs write'"
  check "...and the fix names the grant, or the scope to drop"  "said 'grant the App contents:write' && said 'scopes are the ceiling'"
  check "...and 'the App's permissions page' is a page, not a hint" \
    "saidf \"The page that does it: \$GH_API/settings/apps/\$APP_SLUG/permissions\""
fi

# 12e'. the same shortfall on an App owned by an ORGANISATION. Not a second
# mode: an org-owned App's settings are not reachable under /settings/apps at
# all, so the owner GitHub names in GET /app is the half that decides the path,
# and a wrong URL here is a fix an operator cannot follow.
if STUB_APP_OWNER="acme:Organization" gh_start thin-perms; then
  irun "$R" --deep
  check "an org-owned App's permissions page is under the org" \
    "saidf \"The page that does it: \$GH_API/organizations/acme/settings/apps/\$APP_SLUG/permissions\""
  check "...and not under the user path, which does not exist for it" \
    "! saidf \"\$GH_API/settings/apps/\$APP_SLUG/permissions\""
fi

# 12f. the one answer that is a report: a GitHub this box cannot reach. The
# run path RETRIES that one (identity.js marks a mint failure permanent or not,
# because the clone activity retries), so a preflight must not call it a
# refusal — it would be the one lie in the section.
GH_API="http://127.0.0.1:1"
gh_stop
# Nothing can write to the log now, so it still holds the last mode's requests
# — and the counts below are about THIS invocation.
: > "$GH_LOG"
IJF="$(ijson "$R" --deep)"
check "a GitHub this box cannot reach is NOT a refusal"        "iseat \"\$IJF\" 'graph=unasked plain=unreachable roaded=unreachable'"
check "...and nothing about it reaches the refusals list"      "rf=\$(jq_refusals \"\$IJF\") && ! said_in \"\$rf\" 'installation\|will not mint'"
irun "$R" --deep
check "...said as a report, with why that line is drawn there" "said 'could not be checked at GitHub from this box' && said 'the kind of mint failure that passes'"
check "...and it does not cast doubt on what IS proven"        "said 'their key signs here'"
check "...and a GitHub with no route is not asked who the App is" "[ \"\$(apped)\" = 0 ]"

# 12g. and none of it happens without the flag.
: > "$GH_LOG"   # the count below is about THIS invocation, not the section's
out="$(ident $E doctor "$R" 2>&1)"; rc=$?
check "no --deep, no request: the preflight stays offline"      "[ \"\$(asked acme/box)\" = 0 ]"
check "...of either kind: who the App is is not asked either"   "[ \"\$(apped)\" = 0 ]"
if [ "$HAVE_RUNTIME" = 1 ]; then
  # The "not proven" line is in the ✓ half of the verdict, so a box with no
  # engine never reaches it — the same reason step 6 skips.
  check "...and the gap is named rather than ticked"            "said 'whether each App is installed on the repository it would mint for'"
  check "...with the price of each half said apart"             "said 'one free GET at GitHub per App'"
else
  echo "  SKIPPED -- no engine at $ENGINE_ADDR, or nothing polling its queue, so the verdict never reaches its ✓ half, where the \"not proven\" line lives."
  echo "  install it (curl -sSf https://temporal.download/cli.sh | sh) and run \`temporal server start-dev\`, or: npm run test:cold"
fi
# A roster with no App of its own is not told about a gap it does not have.
out="$(env -u GH_TOKEN -u GITHUB_TOKEN $E doctor "$R" 2>&1)"
check "a roster with no App is not offered that half at all"    "! said 'installed on the repository it would mint for'"

printf '\nsmoke: %d ok, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
