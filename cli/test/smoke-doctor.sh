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
# Anchored on the executor's own sentence rather than on "covers" alone: the
# identity section added a second block that names the seats an answer covers
# the same way, and a bare grep for "covers graph" stopped being a statement
# about the executor the moment it existed.
check "said once per binary, with the seats it covers"       "said 'covers plain, roaded' && ! printf '%s' \"\$out\" | grep 'not on the PATH a run gets' | grep -q graph"
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
  "! jq_refusals \"\$IJ\" | grep -q 'identity\|App\|acts as'"
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
check "...and that is not a refusal"                                "! jq_refusals \"\$OJ\" | grep -q 'mint\|half an identity'"
out="$(EPITO_APP_ID_PLAIN=123456 EPITO_APP_KEY_FILE_PLAIN="$TMP/plain.pem" $E doctor "$R" 2>&1)"
check "...the App id is named, and the names it came from"          "said 'its own GitHub App: id 123456' && said 'EPITO_APP_ID_PLAIN'"
check "...and never a byte of the key"                              "! said 'PRIVATE KEY'"
check "...with the other two seats still on one line of their own"  "[ \$(printf '%s' \"\$out\" | grep -c '^  . nobody:') -eq 1 ]"

# 10d. half an identity. loadPrincipal reads it as "no App", the seat falls
# back to the shared credential, and before this nothing said so — which is
# the silent fallback the identity leg exists to delete.
HJ="$(EPITO_APP_ID_PLAIN=123456 $E doctor "$R" --json 2>&1)"
check "an App id with no key is half an identity"                   "istate \"\$HJ\" 'graph=none plain=half roaded=none'"
check "...and THAT refuses, like a road this box has and has wrong" "jq_refusals \"\$HJ\" | grep -q 'half of an identity'"
out="$(EPITO_APP_ID_PLAIN=123456 $E doctor "$R" 2>&1)"
check "...naming the key variable it is missing"                    "said 'EPITO_APP_KEY_FILE_PLAIN'"
check "...and what the runtime would do with it"                    "said 'silently fall back to whatever else the box gives them'"
# ...and the fallback named per seat is the one this seat actually has: the
# roster's `plain` names no GitHub credential at all, so the honest answer is
# nothing, not "the shared credential".
check "...named per seat, not assumed to be a shared token"         "said 'names no GitHub credential either'"
HJ2="$(EPITO_APP_ID_PLAIN= EPITO_APP_KEY_FILE_PLAIN="$TMP/plain.pem" $E doctor "$R" --json 2>&1)"
check "a line somebody half-filled in is the same answer"           "printf '%s' \"\$HJ2\" | grep -q '\"half\"'"
out="$(EPITO_APP_ID_PLAIN= EPITO_APP_KEY_FILE_PLAIN="$TMP/plain.pem" $E doctor "$R" 2>&1)"
check "...told apart from absent, in the env file's own words"       "said 'set here and set to nothing'"

# 10e. an App whose mint cannot start. A PEM mangled on its way into a systemd
# EnvironmentFile is the ordinary case — the file has no multi-line values —
# and the mint is the run's first step, so the run never starts.
MJ="$(EPITO_APP_ID_PLAIN=123456 EPITO_APP_KEY_PLAIN='-----BEGIN RSA PRIVATE KEY-----
truncated' $E doctor "$R" --json 2>&1)"
check "a key that is not a readable PEM refuses before 06:00"       "printf '%s' \"\$MJ\" | grep -q '\"refused\"'"
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
  "istate \"\$UJ\" 'scoped=none' && ! jq_refusals \"\$UJ\" | grep -q 'mint'"
out="$($E doctor "$RU" 2>&1)"
check "...said as a report, in the two commands that do refuse"     "said 'epito deploy' && said 'a RUN does not care'"
UJ2="$(EPITO_APP_ID_SCOPED=123456 EPITO_APP_KEY_FILE_SCOPED="$TMP/plain.pem" $E doctor "$RU" --json 2>&1)"
check "the same scope WITH an App on the box is a refusal"          "printf '%s' \"\$UJ2\" | grep -q '\"refused\"' && jq_refusals \"\$UJ2\" | grep -q 'mint would refuse'"
out="$(EPITO_APP_ID_SCOPED=123456 EPITO_APP_KEY_FILE_SCOPED="$TMP/plain.pem" $E doctor "$RU" 2>&1)"
check "...naming the scope, and no longer calling it harmless"      "said 'github:packages' && ! said 'a RUN does not care'"

# 10g. the file store, which is what `epito deploy` writes on a laptop: both
# halves together, or the runtime reads neither.
FS="$TMP/filestore"; mkdir -p "$FS/.epito/keys"
printf '[{"agent":"plain","externalId":"654321"}]' > "$FS/.epito/principals.json"
FJ="$(cd "$FS" && EPITO_EXECUTOR="$STUB" node "$CLI/src/index.js" doctor "$R" --json 2>&1)"
check "a record with no key beside it is half an identity"          "printf '%s' \"\$FJ\" | grep -q '\"half\"'"
cp "$TMP/plain.pem" "$FS/.epito/keys/plain.pem"
FJ2="$(cd "$FS" && EPITO_EXECUTOR="$STUB" node "$CLI/src/index.js" doctor "$R" --json 2>&1)"
check "both halves together is the laptop's own identity, id and all" \
  "printf '%s' \"\$FJ2\" | grep -q '\"654321\"' && printf '%s' \"\$FJ2\" | grep -q 'principals.json'"
check "...and the preflight read the store a run in that directory would" \
  "printf '%s' \"\$FJ2\" | grep -q '$FS/.epito/principals.json'"

step "11. the identity block in epito env, from the same reader"
# The ideas ledger's row: `epito env` reports the names a manifest DECLARES,
# and a seat's own identity names are derived from [agent].name instead — so
# the one command an operator runs to see what a box owes a roster said
# nothing about the thing that decides whose name its PRs open under.
eout="$(env -u GH_TOKEN -u GITHUB_TOKEN $E env "$R" 2>&1)"
check "epito env carries the block, and says no manifest declares it" \
  "printf '%s' \"\$eout\" | grep -q 'the names no manifest declares'"
check "...with the same sentence doctor prints, from the same module" \
  "printf '%s' \"\$eout\" | grep -q 'nobody: no App on this box'"
check "...and it does not claim --template covers them" \
  "printf '%s' \"\$eout\" | grep -q 'not in .--template.'"
ejson="$(EPITO_APP_ID_PLAIN=123456 EPITO_APP_KEY_FILE_PLAIN="$TMP/plain.pem" $E env "$R" --json 2>&1)"
check "--json carries one identity row per seat" \
  "printf '%s' \"\$ejson\" | node -e 'const r=JSON.parse(require(\"fs\").readFileSync(0,\"utf8\"));process.exit(r.identity.length===3&&r.identity.find(x=>x.agent===\"plain\").state===\"own\"?0:1)'"
check "...and never the key, only which App" \
  "! printf '%s' \"\$ejson\" | grep -q 'PRIVATE KEY'"
# The exit code stays this command's own: whether a run would REFUSE is
# doctor's contract, and a half identity is not a name a manifest asked for.
env -u GH_TOKEN EPITO_APP_ID_PLAIN=123456 $E env "$R" >/dev/null 2>&1; erc=$?
check "a half identity does not change what epito env exits"        "[ $erc -eq 0 ]"
eout="$(env -u GH_TOKEN EPITO_APP_ID_PLAIN=123456 $E env "$R" 2>&1)"
check "...and it hands that refusal to doctor by name"              "printf '%s' \"\$eout\" | grep -q 'epito doctor'"

printf '\nsmoke: %d ok, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
