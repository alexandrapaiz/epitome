#!/usr/bin/env bash
# Smoke test for the bus: `epito bus`, and the consume loop, against a real
# nats-server this script starts and throws away.
#
#   bash test/smoke-bus.sh        # from cli/
#
# What it proves, and why none of it is provable in the unit suite. The NATS
# client in src/lib/nats.js is written here, byte by byte, because the package
# that claims half a megabyte installed does not get to take a dependency for
# one protocol. unit-bus.mjs holds it to a stand-in server written by the same
# hand on the same day — which proves the code is self-consistent and nothing
# about the wire. So:
#
#   1. the handshake, the JetStream API, the pull, the ack and the -NAK, each
#      against a server that did not read our mock (test/bus-live.mjs)
#   2. an event is acknowledged only once a run has STARTED, and an event whose
#      run refuses comes back — the whole promise of [trigger].subscriptions
#   3. `epito bus <roster>` reads a real stream and a real consumer back: what
#      is waiting, what was handed to a run that has not started, what a run
#      refused, and which seat has no consumer because nothing has served it
#   4. and the three refusals an operator actually meets — no stream named on
#      this box, no stream by that name on the bus, and no bus answering —
#      each naming the fix, because this is the surface `epito validate`'s
#      error bar binds hardest.
#
# The one prerequisite is the `nats-server` binary (7 MB). With none on the
# box this suite SKIPS and says so: an unrun test is not a pass, and the
# harness counts it as unrun rather than green.
set -uo pipefail

CLI="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="${TMPDIR:-/tmp}/epito-bus-smoke-$$"
E="node $CLI/src/index.js"

pass=0; fail=0
ok()   { pass=$((pass+1)); printf '  ok   %s\n' "$1"; }
bad()  { fail=$((fail+1)); printf '  FAIL %s\n' "$1"; }
check(){ if eval "$2"; then ok "$1"; else bad "$1"; fi; }
step() { printf '\n== %s\n' "$1"; }

# ---- the binary ------------------------------------------------------------
# $NATS_BIN, then the PATH, then where test/prereqs.sh puts it. Same order and
# same manners as smoke-temporal.sh's search for `temporal`.
PREREQS="${EPITO_PREREQS_DIR:-${TMPDIR:-/tmp}/epito-prereqs}"
NATS="${NATS_BIN:-}"
[ -z "$NATS" ] && NATS="$(command -v nats-server 2>/dev/null)"
if [ -z "$NATS" ]; then
  NATS="$(find "$PREREQS/nats" -name nats-server -type f -perm -u+x 2>/dev/null | head -1)"
fi
if [ -z "$NATS" ] || [ ! -x "$NATS" ]; then
  cat <<EOF
smoke: SKIPPED — no \`nats-server\` on this box, and the bus is the one thing here
   that cannot be stood in for: the client is hand-written, so a mock of the
   server proves only that it agrees with itself.

     all of it at once:  bash test/all.sh --with-prereqs
     or by hand:         bash test/prereqs.sh    (it fetches the pinned release)
     or your own:        NATS_BIN=/path/to/nats-server bash test/smoke-bus.sh

   Nothing was asserted. Treat this run as no evidence, not as a pass.
EOF
  exit 0
fi

mkdir -p "$TMP/store"
PORT="$(node -e 'const s=require("net").createServer();s.listen(0,"127.0.0.1",()=>{console.log(s.address().port);s.close()})')"
URL="nats://127.0.0.1:$PORT"
STREAM="epito-smoke-$$"

"$NATS" -js -p "$PORT" -a 127.0.0.1 -sd "$TMP/store" > "$TMP/nats.log" 2>&1 &
NATS_PID=$!
cleanup() {
  [ -n "${NATS_PID:-}" ] && kill "$NATS_PID" 2>/dev/null
  wait "$NATS_PID" 2>/dev/null
  if [ -n "${EPITO_SMOKE_KEEP:-}" ]; then printf '\nkept: %s\n' "$TMP"; else rm -rf "$TMP"; fi
}
trap cleanup EXIT

# Up, asked rather than slept for.
UP=0
for _ in $(seq 1 60); do
  if node -e 'const n=require("net"),s=n.connect({host:"127.0.0.1",port:Number(process.argv[1])});s.on("connect",()=>{s.end();process.exit(0)});s.on("error",()=>process.exit(1));' "$PORT"; then UP=1; break; fi
  sleep 0.2
done
if [ "$UP" != 1 ]; then
  echo "smoke: SKIPPED — \`$NATS\` did not come up on $PORT within 12s; nothing could be asserted."
  sed 's/^/       /' "$TMP/nats.log" | tail -10
  exit 0
fi
printf 'nats-server %s on %s, JetStream store in %s\n' "$("$NATS" --version 2>&1 | head -1 | awk '{print $NF}')" "$URL" "$TMP/store"

# ---- 1. the protocol, the reconcile, the ack --------------------------------
step "1. the client against a server it did not write (test/bus-live.mjs)"
node "$CLI/test/bus-live.mjs" "$URL" "$STREAM" > "$TMP/live.txt" 2>&1
sed -n '2,$p' "$TMP/live.txt" | grep -v '^bus-live:' | sed '/^$/d'
pass=$((pass + $(grep -c '^  ok   ' "$TMP/live.txt")))
fail=$((fail + $(grep -c '^  FAIL ' "$TMP/live.txt")))

# ---- 2. the command an operator runs ----------------------------------------
step "2. \`epito bus\` reads a real stream and a real consumer back"
R="$TMP/roster"
mkdir -p "$R/listener" "$R/quiet"
cat > "$R/listener/agent.toml" <<EOF
[agent]
name = "listener"
description = "A seat the bus wakes: no cron, no hook, one subject."
[identity]
scopes = ["github:contents"]
[trigger]
subscriptions = ["smoke.events.*.issue.opened"]
[runtime]
model = "claude-sonnet-5"
entry = "prompts/listener.md"
repo = "acme/box"
EOF
cat > "$R/quiet/agent.toml" <<EOF
[agent]
name = "quiet"
description = "A seat that subscribes and has never been served by a running epito run."
[identity]
scopes = ["github:contents"]
[trigger]
cron = "0 6 * * *"
subscriptions = ["smoke.events.support.run.failed"]
[runtime]
model = "claude-sonnet-5"
entry = "prompts/quiet.md"
repo = "acme/box"
EOF

export EPITO_BUS_URL="$URL"
export EPITO_BUS_STREAM="$STREAM"
export EPITO_BUS_GROUP="smoke"

# The stream, one consumer for `listener` only, and one event waiting on it:
# the state a box is in between `epito run` creating consumers and a worker
# taking what arrived. Built through the product's own reconcile, so this
# section reads back what the runtime would actually have written.
cat > "$TMP/setup.mjs" <<MJS
// Written here rather than committed: it is three lines of the product's own
// library, and it lives in \$TMP, so it imports by absolute path.
import { connectBus } from "file://$CLI/src/lib/nats.js";
import { reconcileConsumers } from "file://$CLI/src/lib/bus.js";
const [,, url, stream, group] = process.argv;
const bus = await connectBus({ url });
await bus.api(\`STREAM.CREATE.\${stream}\`, { name: stream, subjects: ["smoke.events.>"], storage: "memory" });
await reconcileConsumers({ bus, cfg: { url, stream, group, ackWaitMs: 30000, batch: 1 }, seats: [{ name: "listener", subjects: ["smoke.events.*.issue.opened"] }] });
bus.publish("smoke.events.acme.issue.opened", JSON.stringify({ type: "issue.opened" }));
await new Promise((r) => setTimeout(r, 200));
bus.close();
MJS
node "$TMP/setup.mjs" "$URL" "$STREAM" "$EPITO_BUS_GROUP" > "$TMP/setup.log" 2>&1 || { echo "  FAIL could not set the stream up: $(tail -3 "$TMP/setup.log")"; fail=$((fail+1)); }

out="$($E bus "$R" 2>&1)"; rc=$?
printf '%s\n' "$out" | sed 's/^/      /'
said() { printf '%s' "$out" | grep -q -e "$1"; }
check "it names the bus, the stream and what the stream holds"  "said 'stream $STREAM' && said '1 message held'"
check "the subscribing seats are both there, with their subjects" "said 'listener' && said 'quiet' && said 'smoke.events.support.run.failed'"
check "the seat with a consumer shows the event waiting for it"  "printf '%s' \"\$out\" | grep -E 'listener .*smoke-listener .*1' | grep -q ."
check "the seat nothing has served says so, rather than showing a zero" "said 'none yet'"
check "...and says what creates one, in the words of the command that does" "said 'never been served by a running .epito run'"
check "it exits 0: an event waiting is the system working, not a fault"  "[ $rc -eq 0 ]"

out="$($E bus "$R" --json 2>&1)"
check "--json carries the same answer for a machine" \
  "printf '%s' \"\$out\" | node -e 'let s=\"\";process.stdin.on(\"data\",d=>s+=d).on(\"end\",()=>{const r=JSON.parse(s);const l=r.seats.find(x=>x.agent===\"listener\"),q=r.seats.find(x=>x.agent===\"quiet\");process.exit(r.stream===\"$STREAM\"&&l.exists===true&&l.waiting===1&&q.exists===false?0:1)})'"

# A subject the stream cannot carry: the seat is waiting for a bell nobody
# will ring, and only the server knows what the stream carries.
mkdir -p "$R/elsewhere"
cat > "$R/elsewhere/agent.toml" <<EOF
[agent]
name = "elsewhere"
description = "A seat subscribed to a subject this stream does not carry."
[identity]
scopes = ["github:contents"]
[trigger]
subscriptions = ["other.bus.entirely"]
[runtime]
model = "claude-sonnet-5"
entry = "prompts/elsewhere.md"
repo = "acme/box"
EOF
out="$($E bus "$R" 2>&1)"; rc=$?
check "a subscription the stream can never deliver is a refusal, named"  "[ $rc -eq 1 ] && said 'can never deliver' && said 'other.bus.entirely'"
check "...with both fixes: the manifest, or the stream"                  "said 'correct the subject in the manifest, or widen the stream'"
rm -rf "$R/elsewhere"

step "3. the three refusals an operator meets"
out="$(EPITO_BUS_STREAM= $E bus "$R" 2>&1)"; rc=$?
check "no stream named on this box: exit 1, naming the seats"       "[ $rc -eq 1 ] && said 'EPITO_BUS_STREAM is not set' && said 'listener'"
check "...and saying a run keeps serving anyway"                    "said 'keeps serving'"
out="$(EPITO_BUS_STREAM=not-a-stream $E bus "$R" 2>&1)"; rc=$?
check "no stream by that name on the bus: exit 1, with the subjects" "[ $rc -eq 1 ] && said 'has no stream named not-a-stream' && said 'smoke.events'"
out="$(EPITO_BUS_URL=nats://127.0.0.1:1 $E bus "$R" 2>&1)"; rc=$?
check "no bus answering: exit 1, naming what it costs and the fix"   "[ $rc -eq 1 ] && said 'nothing is answering the bus' && said 'Fix:'"

step "4. doctor's bus row, against a box that really has one"
out="$($E doctor "$R" 2>&1)"
check "the row says the stream this box names, for the seats that need it" "said '. bus' && said '$STREAM' && said 'listener'"
check "and it opened no connection to say it"                             "said 'opened nothing'"

printf '\nsmoke: %d ok, %d failed\n' "$pass" "$fail"
[ "$fail" = 0 ] || exit 1
