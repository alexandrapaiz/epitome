#!/usr/bin/env bash
# Smoke test for `epito doctor` — the preflight whose whole promise is that it
# refuses exactly when a run on this box would refuse, and names the piece.
#
#   bash test/smoke-doctor.sh            # from cli/
#
# It spends nothing and reaches no provider: the executor under test is
# test/stub-executor.mjs, the same stand-in the runtime suites spawn, plus two
# deliberately broken ones this suite writes. The one prerequisite it cannot
# stand in for is an engine — doctor's last section asks whether Temporal is
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

run() { out="$($E doctor "$@" 2>&1)"; rc=$?; }
said() { printf '%s' "$out" | grep -q -e "$1"; }

step "1. a roster with every piece in place"
if [ "$HAVE_ENGINE" = 1 ]; then
  run "$R"
  check "exits 0 when nothing would make a run refuse"      "[ $rc -eq 0 ]"
  check "five rows, in the order a run needs them"           "said '✓ manifests' && said 'names' && said '✓ roads' && said '✓ executor' && said '✓ engine'"
  check "the executor row names the binary's resolved path"  "said 'stub-executor.mjs started under the environment a run gives it'"
  check "and says it for all three seats at once"            "said 'for 3 seats'"
  check "the closing line speaks for a run, not for a file"  "said 'nothing here would make a run on this box refuse'"
  check "and refuses to claim the executor is logged in"     "said 'Not proven'"
  check "naming --deep as the thing that would prove it"     "said '[-][-]deep'"
else
  echo "  SKIPPED -- no engine is answering at $ENGINE_ADDR, and doctor's last section is whether one is: on this box a run genuinely would refuse, so the green-roster assertions have nothing to assert."
  echo "  install it (curl -sSf https://temporal.download/cli.sh | sh) and run \`temporal server start-dev\`, or run the whole suite with: npm run test:cold"
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
check "said once per binary, with the seats it covers"       "said 'covers plain, roaded' && ! said 'covers graph'"
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
  "[ $unset_rc -ne 1 ] || ! printf '%s' \"\$unset_out\" | grep -q 'DOCTOR_SMOKE_HELD is set'"
check "and says so in the roster's own vocabulary" \
  "printf '%s' \"\$unset_out\" | grep -q 'not on this box'"

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
  kill $FAKE 2>/dev/null; wait $FAKE 2>/dev/null
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

step "6. --deep runs one turn per ROAD, not one per seat"
if [ "$HAVE_ENGINE" = 1 ]; then
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
  echo "  SKIPPED -- no engine at $ENGINE_ADDR, so the exit code --deep would set cannot be told apart from the engine's."
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

printf '\nsmoke: %d ok, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
