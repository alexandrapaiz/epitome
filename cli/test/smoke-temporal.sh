#!/usr/bin/env bash
# Smoke test for epitod v1 on Temporal (docs/prfaq/epitod-v1-temporal.md).
# It spends no tokens and touches no network: the engine is a local
# `temporal server start-dev`, the executor is test/stub-executor.mjs,
# "github.com" is rewritten to a local bare repo with git's
# url.<base>.insteadOf, "Slack" is two test/slack-sink.mjs on localhost, and
# "api.github.com" is test/github-stub.mjs, which verifies the App JWT epito
# signs against a throwaway public key this script generates — so the mint is
# proved against a real signature check, not against a yes-man.
#
#   bash test/smoke-temporal.sh          # from cli/
#
# It proves the three things the owner's directive names, plus the behavior v0
# had that must not regress:
#
#   1. a SCHEDULE fires a run           (a real clock tick, not a hand trigger)
#   2. a WINDOW holds a session and a message RESUMES it in the same clone
#   3. `epito ps` reads TEMPORAL        (schedules, running workflows, queries)
#   4. a run MINTS ITS OWN IDENTITY     (cycle 1 bet 2: the token reaches the
#                                        child, the log does not get it, and an
#                                        agent that cannot mint does not run)
#   5. every run LANDS ON THE BOARD      (the owner's priority 1: one place
#                                        that says what the seats have been
#                                        doing, including a seat that runs in
#                                        GitHub Actions and not on this engine,
#                                        and a shape no seat can widen)
#   6. a seat is NOT ONLY A CLAUDE SESSION (owner priority 3: a LangGraph app
#                                        runs as a seat through its own
#                                        langgraph.json, unmodified, and mints,
#                                        clones, records and posts through the
#                                        same code every other seat uses)
#   7. a run is ONE TRACE                (ADR-18: run -> clone / mint /
#                                        execute -> the agent's own steps, at
#                                        an OTLP endpoint, with no token in it)
#   + reconcile is idempotent after a create AND after an update, and deletes
#     the schedule of a seat that loses its cron; per-agent Slack routing sends each seat's line to its own
#     webhook; a seat with no charter refuses loudly and leaves no clone; the
#     ingress refuses a wrong secret, an unknown agent, an empty message and a
#     bad scope, by name.
#
# If the `temporal` CLI is not installed this exits 0 after saying so: a
# machine without the binary is not a failing test, it is an unrun one.
set -uo pipefail

CLI="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

TEMPORAL_BIN="${TEMPORAL_BIN:-}"
if [ -z "$TEMPORAL_BIN" ]; then
  if command -v temporal >/dev/null 2>&1; then TEMPORAL_BIN="$(command -v temporal)"
  elif [ -x "$HOME/.temporalio/bin/temporal" ]; then TEMPORAL_BIN="$HOME/.temporalio/bin/temporal"
  fi
fi
if [ -z "$TEMPORAL_BIN" ]; then
  cat <<'MSG'
smoke: SKIPPED — the `temporal` CLI is not on PATH, and this test needs a local
engine to be a test of anything. epitod v1 runs on Temporal, so there is no
in-process stand-in to fall back to.

  install it:  curl -sSf https://temporal.download/cli.sh | sh
  then:        PATH="$PATH:$HOME/.temporalio/bin" bash test/smoke-temporal.sh

Nothing was asserted. Treat this run as no evidence, not as a pass.
MSG
  exit 0
fi

ROOT="${TMPDIR:-/tmp}/epito-smoke-$$"
ORIGIN="$ROOT/origin"; ROSTER="$ROOT/agents"; STATE="$ROOT/state"; STUB="$ROOT/stub"
PORT="${EPITO_TEST_PORT:-47471}"
SLACK_HQ_PORT="${EPITO_TEST_SLACK_PORT:-47472}"
SLACK_PRODUCT_PORT="${EPITO_TEST_SLACK2_PORT:-47473}"
GRPC_PORT="${EPITO_TEST_TEMPORAL_PORT:-47811}"
GH_PORT="${EPITO_TEST_GITHUB_PORT:-47474}"
OTLP_PORT="${EPITO_TEST_OTLP_PORT:-47476}"
# Two endpoints that stand in for an open provider (ADR-19). Nothing listens on
# either: the stub executor decides what a route does by reading the endpoint it
# was pointed at, which is how one process can be a provider that refuses and a
# provider that works.
OPEN_REFUSES="http://127.0.0.1:47477/anthropic"
OPEN_WORKS="http://127.0.0.1:47478/anthropic"
OPEN_KEY="open-route-key-not-a-real-one"
NS="epito-smoke"
SECRET="smoke-secret-not-a-real-one"
SLACK_HQ="$ROOT/slack-hq.log"; SLACK_PRODUCT="$ROOT/slack-product.log"
GH_LOG="$ROOT/github-requests.jsonl"
SPANS="$ROOT/spans.jsonl"
# The credential the box has today, and which an agent's own must beat.
SHARED_TOKEN="shared-operator-token-not-a-real-one"
STUB_TOKEN="ghs_STUBTOKEN0000000000000000000000000000"
pass=0; fail=0
ok()   { pass=$((pass+1)); printf '  ok   %s\n' "$1"; }
bad()  { fail=$((fail+1)); printf '  FAIL %s\n' "$1"; }
check(){ if eval "$2"; then ok "$1"; else bad "$1"; fi; }
# Assert the audit log holds N lines matching a JSON pattern. Matching by
# predicate, not by substring: a substring match on a serialized object is an
# assertion about key order, which is not a promise this runtime makes.
audit(){ label="$1"; shift; if node "$CLI/test/audit-has.mjs" "$@" >/dev/null 2>&1; then ok "$label"; else bad "$label"; node "$CLI/test/audit-has.mjs" "$@" 2>&1 | sed 's/^/       /'; fi; }
# The absence of a line is an assertion too: "this seat minted nothing" is half
# of what the identity slice promises.
none(){ n=$(node "$CLI/test/audit-has.mjs" --count "$2"); if [ "$n" = 0 ]; then ok "$1"; else bad "$1 (found $n)"; fi; }
step() { printf '\n== %s\n' "$1"; }
# "The clone is gone" is an assertion about an activity that runs AFTER the run
# the test just watched finish: `cleanup` is its own Temporal activity, so the
# directory disappears a moment later, not at run.end. Asserting it immediately
# is a race the test wins on an idle box and loses under load (found running
# every suite in one pass: test/all.sh). Poll instead — an assertion with a
# deadline is still an assertion, and a stale directory fails it just the same.
gone() {
  local label="$1" glob="$2" deadline=$((SECONDS + 15))
  while [ "$SECONDS" -lt "$deadline" ]; do
    [ "$(ls -d $glob 2>/dev/null | wc -l)" = 0 ] && { ok "$label"; return; }
    sleep 0.25
  done
  bad "$label (still there after 15s: $(ls -d $glob 2>/dev/null | tr '\n' ' '))"
}

cleanup() {
  for pid in ${INGRESS_PID:-} ${WORKER_PID:-} ${SINK1_PID:-} ${SINK2_PID:-} ${GH_PID:-} ${OTLP_PID:-} ${SERVER_PID:-}; do
    kill "$pid" 2>/dev/null
  done
  sleep 1
  for pid in ${SERVER_PID:-}; do kill -9 "$pid" 2>/dev/null; done
  if [ -n "${EPITO_SMOKE_KEEP:-}" ]; then printf '\nkept for inspection: %s\n' "$ROOT"; else rm -rf "$ROOT"; fi
}
trap cleanup EXIT

mkdir -p "$ORIGIN" "$ROSTER" "$STATE" "$STUB"

step "engine: temporal server start-dev on 127.0.0.1:$GRPC_PORT, namespace $NS"
"$TEMPORAL_BIN" server start-dev --headless --port "$GRPC_PORT" --namespace "$NS" \
  --db-filename "$ROOT/temporal.sqlite" --log-level error > "$ROOT/temporal.log" 2>&1 &
SERVER_PID=$!
# Cluster health goes SERVING before the namespace is registered, so wait for
# the namespace: it is what both epitod processes actually need.
for _ in $(seq 1 120); do "$TEMPORAL_BIN" operator namespace describe -n "$NS" --address "127.0.0.1:$GRPC_PORT" >/dev/null 2>&1 && break; sleep 0.5; done
"$TEMPORAL_BIN" operator namespace describe -n "$NS" --address "127.0.0.1:$GRPC_PORT" >/dev/null 2>&1 || { echo "the dev server never registered namespace $NS"; cat "$ROOT/temporal.log"; exit 1; }
echo "  $("$TEMPORAL_BIN" --version | head -1)"

step "fixture: a local repo standing in for github.com/acme/roster"
seed="$ROOT/seed"; mkdir -p "$seed/prompts"
for a in clock pm okr badkey graphs routed cheap; do printf '# %s\n\nYou are %s. One run: open a draft PR.\n' "$a" "$a" > "$seed/prompts/$a.md"; done
# The same repository also holds a LangGraph app, because one of the seats in
# this roster is one (owner priority 3, ADR-17). Which fixture stands in for it
# depends on whether this machine has the framework: `langgraph-real` is two
# nodes of real LangGraph, `langgraph-stub` is a graph-shaped object that needs
# nothing installed. Both declare a graph named "seat", so the manifest below is
# the same either way.
LG_PYTHON="${EPITO_PYTHON:-}"
if [ -n "$LG_PYTHON" ] && ! "$LG_PYTHON" -c 'import langgraph' >/dev/null 2>&1; then LG_PYTHON=""; fi
if [ -z "$LG_PYTHON" ]; then
  if python3 -c 'import langgraph' >/dev/null 2>&1; then LG_PYTHON=python3
  elif [ -x /tmp/lgvenv/bin/python ] && /tmp/lgvenv/bin/python -c 'import langgraph' >/dev/null 2>&1; then LG_PYTHON=/tmp/lgvenv/bin/python
  fi
fi
if [ -n "$LG_PYTHON" ]; then
  cp -r "$CLI/test/fixtures/langgraph-real/." "$seed/"
  LG_KIND="the real framework ($("$LG_PYTHON" -c 'from importlib.metadata import version; print("langgraph", version("langgraph"))'))"
else
  cp -r "$CLI/test/fixtures/langgraph-stub/." "$seed/"
  LG_PYTHON=python3
  LG_KIND="a graph-shaped object — langgraph is not installed, so this proves the CONTRACT and not the framework (see test/smoke-langgraph.sh)"
fi
# ghost's manifest points at prompts/ghost.md, which this repo does not have:
# the runtime must refuse that run rather than improvise a prompt.
git -c init.defaultBranch=main init -q "$seed"
git -C "$seed" add -A
git -C "$seed" -c user.name=smoke -c user.email=smoke@epito.me commit -qm "charters"
git clone -q --bare "$seed" "$ORIGIN/acme/roster.git"
# Every https://github.com/... the worker clones resolves here instead.
export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0="url.file://$ORIGIN/.insteadOf" GIT_CONFIG_VALUE_0="https://github.com/"
echo "  origin: $ORIGIN/acme/roster.git"

step "roster: one seat on a cron, two presence-only, one with no charter"
write_manifest() { # name cron slack_env
  mkdir -p "$ROSTER/$1"
  {
    printf '[agent]\nname = "%s"\ndescription = "Smoke-test seat: the stub executor answers for it."\n\n' "$1"
    printf '[identity]\nscopes = ["github:contents", "github:pull_requests"]\n\n'
    printf '[trigger]\n'
    if [ -n "$2" ]; then printf 'cron = "%s"\n' "$2"; else printf 'webhook = true\n'; fi
    printf '\n[runtime]\nmodel = "claude-sonnet-5"\nentry = "prompts/%s.md"\nrepo = "acme/roster"\nmax_turns = 5\n' "$1"
    # GH_TOKEN is listed on purpose: it is the shared credential a box has
    # today, and the identity slice's claim is that an agent's OWN token beats
    # it. EPITO_STUB_ECHO_TOKEN makes the stub print which one it got.
    if [ -n "$3" ]; then
      printf 'slack_webhook_env = "%s"\n' "$3"
      printf 'env = ["EPITO_STUB_DIR", "EPITO_STUB_ECHO_TOKEN", "GH_TOKEN", "%s"]\n' "$3"
    else
      printf 'env = ["EPITO_STUB_DIR", "EPITO_STUB_ECHO_TOKEN", "GH_TOKEN"]\n'
    fi
  } > "$ROSTER/$1/agent.toml"
}
# The langgraph seat is written by hand: it is the one manifest in this roster
# that is not a claude agent, and the two fields that make it one are the point.
write_langgraph_manifest() {
  mkdir -p "$ROSTER/graphs"
  cat > "$ROSTER/graphs/agent.toml" <<'TOML'
[agent]
name = "graphs"
description = "Smoke-test seat: a LangGraph app, hosted unmodified through its own langgraph.json."

[identity]
scopes = ["github:contents", "github:pull_requests"]

[trigger]
webhook = true

[runtime]
model = "claude-sonnet-5"
entry = "prompts/graphs.md"
repo = "acme/roster"
adapter = "langgraph"
graph = "seat"
max_turns = 25
env = ["EPITO_STUB_DIR", "EPITO_STUB_ECHO_TOKEN", "GH_TOKEN"]
TOML
}

# The two seats that declare more than one road to a model (ADR-19). Written
# by hand for the same reason the langgraph one is: the fields that make them
# what they are is the whole point of the section that reads them.
write_routed_manifests() {
  mkdir -p "$ROSTER/routed" "$ROSTER/cheap"
  cat > "$ROSTER/routed/agent.toml" <<TOML
[agent]
name = "routed"
description = "Smoke-test seat: an open road that refuses, and the subscription behind it."

[identity]
scopes = ["github:contents", "github:pull_requests"]

[trigger]
webhook = true

[runtime]
model = "claude-sonnet-5"
entry = "prompts/routed.md"
repo = "acme/roster"
max_turns = 5
env = ["EPITO_STUB_DIR", "EPITO_STUB_ECHO_TOKEN", "GH_TOKEN", "OPEN_ROUTE_KEY", "EPITO_STUB_REFUSE_BASE_URL", "EPITO_STUB_ECHO_ROUTE"]

[[runtime.route]]
name = "open"
model = "kimi-k2-turbo-preview"
base_url = "$OPEN_REFUSES"
token_env = "OPEN_ROUTE_KEY"
concurrency = 1

[[runtime.route]]
name = "subscription"
model = "claude-sonnet-5"
TOML
  cat > "$ROSTER/cheap/agent.toml" <<TOML
[agent]
name = "cheap"
description = "Smoke-test seat: a road whose key this box does not hold, an open road that works, and the floor."

[identity]
scopes = ["github:contents", "github:pull_requests"]

[trigger]
webhook = true

[runtime]
model = "claude-sonnet-5"
entry = "prompts/cheap.md"
repo = "acme/roster"
max_turns = 5
env = ["EPITO_STUB_DIR", "EPITO_STUB_ECHO_TOKEN", "GH_TOKEN", "OPEN_ROUTE_KEY", "ABSENT_ROUTE_KEY", "EPITO_STUB_ECHO_ROUTE"]

[[runtime.route]]
name = "premium"
model = "a-model-this-box-cannot-reach"
base_url = "https://api.example.invalid/anthropic"
token_env = "ABSENT_ROUTE_KEY"

[[runtime.route]]
name = "open"
model = "kimi-k2-turbo-preview"
base_url = "$OPEN_WORKS"
token_env = "OPEN_ROUTE_KEY"
concurrency = 1

[[runtime.route]]
name = "subscription"
model = "claude-sonnet-5"
TOML
}

write_manifest clock "* * * * *" "SLACK_WEBHOOK_URL"
write_manifest pm    ""          "SLACK_WEBHOOK_URL"
write_manifest okr   ""          "SLACK_WEBHOOK_URL_EPITOME"   # per-agent routing: its own channel
write_manifest ghost ""          ""
write_manifest badkey ""         ""
write_langgraph_manifest
write_routed_manifests
echo "  clock (cron * * * * *), pm (its own GitHub App), okr (own webhook), ghost (no charter), badkey (an App it cannot sign with)"
echo "  graphs (adapter = \"langgraph\", its own App too) — standing in for it: $LG_KIND"
echo "  routed (open road refuses -> subscription), cheap (a closed road, then an open one that works)"

step "every manifest still passes \`epito validate\` — spec v0.1 stays compatible"
for a in clock pm okr ghost badkey graphs routed cheap; do
  out=$(cd "$ROSTER/$a" && node "$CLI/src/index.js" validate 2>&1); rc=$?
  check "validate $a: $out" "[ $rc = 0 ]"
done
check "and validate names an adapter that is not the default, so a reader knows" "(cd '$ROSTER/graphs' && node '$CLI/src/index.js' validate) | grep -q 'a langgraph agent'"

step "identity fixture: one throwaway RSA App for pm, and a stand-in api.github.com"
# Generated here and thrown away with $ROOT: nothing personal ever enters a
# fixture (the engineer charter's rule), and the stub verifies the signature
# against the public half, so the JWT epito hand-builds is checked for real.
node -e '
const { generateKeyPairSync } = require("node:crypto"); const { writeFileSync } = require("node:fs");
const { privateKey, publicKey } = generateKeyPairSync("rsa", { modulusLength: 2048 });
writeFileSync(process.argv[1], privateKey.export({ type: "pkcs1", format: "pem" }));
writeFileSync(process.argv[2], publicKey.export({ type: "spki", format: "pem" }));
' "$ROOT/pm-app.pem" "$ROOT/pm-app.pub.pem"
chmod 600 "$ROOT/pm-app.pem"
node "$CLI/test/github-stub.mjs" "$GH_PORT" "$ROOT/pm-app.pub.pem" "$GH_LOG" ok > "$ROOT/github-stub.log" 2>&1 & GH_PID=$!
for _ in $(seq 1 60); do grep -q 'github-stub on' "$ROOT/github-stub.log" && break; sleep 0.2; done
check "the stand-in GitHub API is up" "grep -q 'github-stub on $GH_PORT (ok)' '$ROOT/github-stub.log'"
echo "  pm: App 1234, key $ROOT/pm-app.pem (2048-bit, thrown away with this run)"
echo "  badkey: App 99, and a key that is not a PEM — the refusal path"

step "start: two slack sinks, a trace backend, the worker, then the reconciler + ingress"
node "$CLI/test/slack-sink.mjs" "$SLACK_HQ_PORT" "$SLACK_HQ" > "$ROOT/sink1.log" 2>&1 & SINK1_PID=$!
node "$CLI/test/slack-sink.mjs" "$SLACK_PRODUCT_PORT" "$SLACK_PRODUCT" > "$ROOT/sink2.log" 2>&1 & SINK2_PID=$!
# Phoenix, Jaeger and Tempo all take OTLP over HTTP; this takes the same thing
# and writes one line per span, so the test asserts against the protocol rather
# than against a product (ADR-18).
node "$CLI/test/otlp-sink.mjs" "$OTLP_PORT" "$SPANS" > "$ROOT/otlp.log" 2>&1 & OTLP_PID=$!
for _ in $(seq 1 60); do grep -q 'otlp sink on' "$ROOT/otlp.log" && break; sleep 0.2; done
cd "$STATE"
export TEMPORAL_ADDRESS="127.0.0.1:$GRPC_PORT" TEMPORAL_NAMESPACE="$NS" \
       EPITO_HOOK_SECRET="$SECRET" EPITO_PORT="$PORT" EPITO_STUB_DIR="$STUB" \
       EPITO_EXECUTOR="$CLI/test/stub-executor.mjs" EPITO_WINDOW_MS=600000 \
       EPITO_STUB_ECHO_TOKEN=1 GH_TOKEN="$SHARED_TOKEN" \
       EPITO_GITHUB_API="http://127.0.0.1:$GH_PORT" \
       EPITO_APP_ID_PM=1234 EPITO_APP_KEY_PM="$(cat "$ROOT/pm-app.pem")" \
       EPITO_APP_ID_BADKEY=99 EPITO_APP_KEY_BADKEY="this is not a pem, and no amount of retrying will make it one" \
       EPITO_APP_ID_GRAPHS=4321 EPITO_APP_KEY_GRAPHS="$(cat "$ROOT/pm-app.pem")" \
       EPITO_PYTHON="$LG_PYTHON" \
       OPEN_ROUTE_KEY="$OPEN_KEY" EPITO_STUB_REFUSE_BASE_URL="$OPEN_REFUSES" EPITO_STUB_ECHO_ROUTE=1 \
       OTEL_EXPORTER_OTLP_ENDPOINT="http://127.0.0.1:$OTLP_PORT" \
       SLACK_WEBHOOK_URL="http://127.0.0.1:$SLACK_HQ_PORT/hook" \
       SLACK_WEBHOOK_URL_EPITOME="http://127.0.0.1:$SLACK_PRODUCT_PORT/hook"
node "$CLI/src/index.js" worker > "$ROOT/worker.log" 2>&1 & WORKER_PID=$!
for _ in $(seq 1 100); do grep -q 'state: .RUNNING' "$ROOT/worker.log" && break; sleep 0.3; done
check "the worker is polling the seats queue" "grep -q 'epito worker: 127.0.0.1:$GRPC_PORT namespace=$NS queue=seats' '$ROOT/worker.log'"

node "$CLI/src/index.js" run "$ROSTER" > "$ROOT/ingress.log" 2>&1 & INGRESS_PID=$!
for _ in $(seq 1 100); do curl -fs "http://127.0.0.1:$PORT/healthz" >/dev/null 2>&1 && break; sleep 0.3; done
curl -fs "http://127.0.0.1:$PORT/healthz" >/dev/null || { echo "the ingress never came up"; cat "$ROOT/ingress.log"; exit 1; }
sed 's/^/  /' "$ROOT/ingress.log"

step "1: reconcile registered ONE schedule — the three presence-only seats got none"
check "one schedule created, nothing else" "grep -q 'reconciled: 1 created, 0 updated, 0 deleted, 0 unchanged' '$ROOT/ingress.log'"
check "the presence-only seats are named as such" "grep -qF 'presence-only (no [trigger].cron, so no schedule): badkey, cheap, ghost, graphs, okr, pm, routed' '$ROOT/ingress.log'"
check "the schedule is seat:clock, in UTC, with its model and repo" "grep -qF '+ seat:clock  * * * * * UTC  claude-sonnet-5  acme/roster' '$ROOT/ingress.log'"
check "temporal itself lists it" "'$TEMPORAL_BIN' schedule list --address 127.0.0.1:$GRPC_PORT --namespace $NS 2>/dev/null | grep -q seat:clock"
audit "the audit log records the registration" '{"agent":"clock","action":"schedule.create","schedule":"seat:clock"}'
check "/healthz reports the engine it depends on" "curl -fs http://127.0.0.1:$PORT/healthz | grep -q '\"temporal\":\"127.0.0.1:$GRPC_PORT\"'"
# Read the schedule back through `epito ps` while it is still live: a paused
# schedule is asserted separately, after the fire.
node "$CLI/src/index.js" ps "$ROSTER" | sed 's/^/  /'
check "epito ps shows clock's cron, its next fire, and a healthy schedule" "node '$CLI/src/index.js' ps '$ROSTER' | grep clock | grep -qE '\* \* \* \* \* +[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}Z +ok'"

post() { curl -s -o "$ROOT/body.json" -w '%{http_code}' -X POST -H "x-epito-secret: $SECRET" -H 'content-type: application/json' --data "$2" "http://127.0.0.1:$PORT$1"; }
get()  { curl -s -o "$ROOT/body.json" -w '%{http_code}' -H "x-epito-secret: $SECRET" "http://127.0.0.1:$PORT$1"; }
body() { cat "$ROOT/body.json"; }
# The board is a file the fold reads, so "is it on the board" is a question
# about `epito board --json`, asked the way an owner's script would ask it.
board(){ node "$CLI/src/index.js" board --json --limit 200; }

step "the ingress still refuses what it refused in v0, by name"
code=$(curl -s -o /dev/null -w '%{http_code}' -X POST -H "x-epito-secret: wrong" "http://127.0.0.1:$PORT/message/pm" --data '{"text":"hi"}')
check "wrong secret -> 401" "[ '$code' = 401 ]"
code=$(post /message/nobody '{"text":"hi"}'); echo "  $(body)"
check "unknown agent -> 404 naming the roster" "[ '$code' = 404 ] && grep -q 'it hosts: ' '$ROOT/body.json'"
code=$(post /message/pm '{"text":"   "}'); echo "  $(body)"
check "empty message -> 400 with the fix in it" "[ '$code' = 400 ] && grep -q 'nothing to answer' '$ROOT/body.json'"
code=$(post /window/open '{"scope":"nope"}'); echo "  $(body)"
check "bad scope -> 400 listing the roster" "[ '$code' = 400 ] && grep -q 'scope names no agent' '$ROOT/body.json'"

step "1 (the point): the SCHEDULE fires a run on its own clock — waiting for the minute to turn"
node "$CLI/test/wait-for.mjs" runs clock 1 95000 || { echo "no scheduled run inside 95s"; tail -40 "$ROOT/worker.log"; }
audit "the scheduled run ended, on trigger cron" '{"agent":"clock","action":"run.end","trigger":"cron","exit":0}'
audit "it recorded its model, its turns, and the PR it opened" '{"agent":"clock","action":"run.end","model":"claude-sonnet-5","turns":1,"pr":"https://github.com/alexandrapaiz/epitome/pull/999"}'
# clock has no App of its own, so the identity slice must be invisible to it.
check "a seat with no App ran on the shared credential, exactly as before" "grep -q 'GH_TOKEN=$SHARED_TOKEN' .epito/logs/clock/*.log"
none "and it minted nothing" '{"agent":"clock","action":"mint"}'
check "nobody started it by hand: the workflow id carries the scheduled time" "'$TEMPORAL_BIN' workflow list --address 127.0.0.1:$GRPC_PORT --namespace $NS 2>/dev/null | grep -qE 'run:clock-[0-9]{4}-[0-9]{2}-[0-9]{2}T'"
# Every-minute is a test fixture, not a seat anyone would write. Pause it now
# so the rest of the run is not racing a fresh clone every 60 seconds.
# Driven with the stock `temporal` CLI on purpose: seat:clock is an ordinary
# Temporal schedule, so the standard tools operate it, and that is the point.
"$TEMPORAL_BIN" schedule toggle --schedule-id seat:clock --pause \
  --reason "smoke test: one fire is the evidence" \
  --address "127.0.0.1:$GRPC_PORT" --namespace "$NS" 2>&1 | sed 's/^/  temporal> /'
node "$CLI/test/wait-for.mjs" runs clock 1
sleep 1
gone "and the clone it ran in is gone" "${TMPDIR:-/tmp}/epito-clock-*"
# Schedule listing is eventually consistent by Temporal's own documentation, so
# a pause is a thing to wait for rather than to read once.
for _ in $(seq 1 40); do node "$CLI/src/index.js" ps 2>/dev/null | grep clock | grep -q paused && break; sleep 0.5; done
check "epito ps shows the schedule as paused, read from the engine" "node '$CLI/src/index.js' ps | grep clock | grep -q paused"
check "and a paused seat advertises no next fire" "node '$CLI/src/index.js' ps | grep clock | grep -qvE '[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}Z +paused'"

step "2: a WINDOW holds a session, and a message resumes THAT session in the same clone"
code=$(post /window/open '{"scope":"pm","text":"Agenda: cycle 2 hill check."}'); echo "  $code $(body)"
node "$CLI/test/wait-for.mjs" runs pm 1
node "$CLI/test/wait-for.mjs" action pm session.hold 1
audit "the window opened and fired the seat once" '{"agent":"pm","action":"window.open"}' 1
check "the window instruction reached the executor" "grep -q 'synchronous mode' \"$STUB\"/*.jsonl"
check "the agenda reached the executor" "grep -q 'cycle 2 hill check' \"$STUB\"/*.jsonl"
SESSION=$(node -e 'const l=require("fs").readFileSync(".epito/audit.jsonl","utf8").trim().split("\n").map(JSON.parse);const h=l.filter(e=>e.agent==="pm"&&e.action==="session.hold").pop();console.log(h?h.session:"")')
echo "  pm session: $SESSION"
check "a session id is held for pm" "[ -n '$SESSION' ]"

code=$(post /message/pm "{\"text\":\"Which PR did you open?\"}"); echo "  $code $(body)"
check "the ingress delivered it into the held session" "grep -q '\"held\":true' '$ROOT/body.json' && grep -q '\"session\":\"$SESSION\"' '$ROOT/body.json'"
node "$CLI/test/wait-for.mjs" runs pm 2
check "the transcript has two turns in ONE session" "[ \$(wc -l < \"$STUB/$SESSION.jsonl\") = 2 ]"
check "the second turn was a --resume" "grep -q '\"resumed\":true' \"$STUB/$SESSION.jsonl\""
check "both turns ran in the SAME clone" "[ \$(node -e 'const l=require(\"fs\").readFileSync(process.argv[1],\"utf8\").trim().split(\"\\n\").map(JSON.parse);console.log(new Set(l.map(x=>x.cwd)).size)' \"$STUB/$SESSION.jsonl\") = 1 ]"
check "the agent answered in context (it names its own PR)" "grep -q 'my PR is still' .epito/logs/pm/*.log"

step "4: IDENTITY — pm's runs minted their own credential, and the log never saw it"
# Three mints for two runs, and that is the design: law 7 forbids a token
# crossing an activity boundary, so the clone and the run each ask for their
# own. The resumed run borrows the open window's clone, so it mints once.
audit "every pm mint carries everything about the credential except the credential" '{"agent":"pm","action":"mint","provider":"github-app","installation":"4242","repo":"acme/roster"}' 3
audit "the permissions minted are exactly what [identity].scopes maps to" '{"agent":"pm","action":"mint","permissions":{"contents":"write","pull_requests":"write"}}' 3
audit "the fresh run minted once for its clone" '{"agent":"pm","action":"mint","phase":"clone"}' 1
audit "and once for the run itself — both runs, including the resumed one" '{"agent":"pm","action":"mint","phase":"run"}' 2
check "no audit line anywhere contains a token" "! grep -q '$STUB_TOKEN' .epito/audit.jsonl"
check "the child was handed the MINTED token, not the shared one" "grep -q 'GH_TOKEN=\[redacted' .epito/logs/pm/*.log"
check "and the run log holds no copy of it, though the child printed one" "! grep -q '$STUB_TOKEN' .epito/logs/pm/*.log"
check "the shared GH_TOKEN never reached pm's run" "! grep -q '$SHARED_TOKEN' .epito/logs/pm/*.log"
check "the log says which identity won, by name" "grep -qF 'GH_TOKEN from [runtime].env is overridden' .epito/logs/pm/*.log"
printf '  github stub saw:\n'; sed 's/^/    /' "$GH_LOG"
check "GitHub verified the JWT epito signed, against the App's public key" "node '$CLI/test/gh-asked.mjs' jwt '$GH_LOG' 1234"
check "every mint asked for those permissions on THAT ONE repository" "node '$CLI/test/gh-asked.mjs' mint '$GH_LOG' contents:write,pull_requests:write roster"

step "4 (the clone): the git clone in front of the run is the agent's too"
# The box's own helper (deploy/provision-host.sh wires it to the roster-wide
# human GH_TOKEN) is reset for the clone of a seat that has an App. Proved
# against a server that demands the credential in cli/test/unit.mjs — "the
# clone authenticates as the agent, over the box's own helper"; here the claim
# is that the runtime actually takes that path, and says which one it took.
check "pm's clone ran on pm's own minted token" "grep -qF \"clone credential: this run's own minted token\" .epito/logs/pm/*.log"
check "and the clone log holds no copy of it" "! grep -q '$STUB_TOKEN' .epito/logs/pm/*.log"
check "a seat with no App clones exactly as it did before the slice" "grep -qF 'clone credential: this machine' .epito/logs/clock/*.log"
none "and clock still minted nothing, for the clone either" '{"agent":"clock","action":"mint"}'

step "4 (the commits): a PR that opens as the bot, with commits GitHub links to it"
check "GET /app was asked as the App and GET /users as the INSTALLATION" "node '$CLI/test/gh-asked.mjs' bot '$GH_LOG' 'epito-seat-1234[bot]'"
audit "the audit line records the address the commits were authored with" '{"agent":"pm","action":"mint","commit":{"name":"epito-seat-1234[bot]","email":"99001+epito-seat-1234[bot]@users.noreply.github.com"}}' 3
check "pm's run committed as the App's own bot user" "grep -qF 'commits authored as epito-seat-1234[bot] <99001+epito-seat-1234[bot]@users.noreply.github.com>' .epito/logs/pm/*.log"
check "and the log says why that address is the one that links" "grep -qF 'GitHub links every commit in the PR to the agent' .epito/logs/pm/*.log"
check "a seat with no App keeps the old convention, and is told it links to nothing" "grep -qF 'commits authored as clock <clock@agents.epito.me>' .epito/logs/clock/*.log && grep -qF 'links to no account' .epito/logs/clock/*.log"

step "4 (no silent fallback): an agent that HAS an App and cannot mint does not run"
code=$(post /window/open '{"scope":"badkey"}'); echo "  $code $(body)"
node "$CLI/test/wait-for.mjs" action badkey run.end 1
audit "the run ended at the mint, and is recorded as such" '{"agent":"badkey","action":"run.end","trigger":"window","exit":"mint"}'
audit "the refusal is recorded in the product voice, not as \"Activity task failed\"" '{"agent":"badkey","action":"run.end","detail":"~this run has an identity it could not mint, so it did not start"}'
audit "and the key it choked on is described, never printed" '{"agent":"badkey","action":"run.end","detail":"~not a readable PEM"}'
check "no token was handed to it instead" "! ls .epito/logs/badkey/*.log >/dev/null 2>&1 || ! grep -q 'GH_TOKEN=$SHARED_TOKEN' .epito/logs/badkey/*.log"
gone "and no clone was left behind" "${TMPDIR:-/tmp}/epito-badkey-*"
node "$CLI/test/wait-for.mjs" closed badkey

step "4 (the CLI): \`epito token <name>\` is the same mint, on stdout"
TOKEN_OUT=$(node "$CLI/src/index.js" token pm "$ROSTER" 2> "$ROOT/token.err"); rc=$?
printf '  stdout> %s\n  stderr> %s\n' "$TOKEN_OUT" "$(cat "$ROOT/token.err")"
check "it exits 0 and stdout is the token ALONE, so \$(epito token pm) works" "[ $rc = 0 ] && [ \"$TOKEN_OUT\" = '$STUB_TOKEN' ]"
check "the human summary went to stderr, naming installation and expiry" "grep -q 'minted for pm' '$ROOT/token.err' && grep -q 'installation 4242' '$ROOT/token.err'"
check "and it hands back the commit address, so a scripted \`gh pr create\` can match it" "grep -qF 'GIT_AUTHOR_EMAIL=\"99001+epito-seat-1234[bot]@users.noreply.github.com\"' '$ROOT/token.err'"
check "stderr holds no token either" "! grep -q '$STUB_TOKEN' '$ROOT/token.err'"
node "$CLI/src/index.js" token pm "$ROSTER" --dry-run | sed 's/^/  /'
check "--dry-run says what it would ask for, with no request to GitHub" "before=\$(wc -l < '$GH_LOG'); node '$CLI/src/index.js' token pm '$ROSTER' --dry-run | grep -q 'pull_requests: write' && [ \$(wc -l < '$GH_LOG') = \$before ]"
out=$(node "$CLI/src/index.js" token okr "$ROSTER" 2>&1 || true); echo "  $out"
check "an agent with no App is told so, with the two env names to set" "printf '%s' \"\$out\" | grep -q 'EPITO_APP_ID_OKR' && printf '%s' \"\$out\" | grep -q 'EPITO_APP_KEY_OKR'"
out=$(node "$CLI/src/index.js" token nobody "$ROSTER" 2>&1 || true); echo "  $out"
check "an unknown agent is told the roster it searched" "printf '%s' \"\$out\" | grep -q 'the roster there is'"

step "3: \`epito ps\` reads TEMPORAL — schedules, running workflows, and the window's own answer"
node "$CLI/src/index.js" ps "$ROSTER" | sed 's/^/  /'
PS=$(node "$CLI/src/index.js" ps "$ROSTER")
check "ps names the engine it read" "printf '%s' \"\$PS\" | grep -q 'epitod on 127.0.0.1:$GRPC_PORT namespace=$NS queue=seats'"
check "ps still shows clock's cron, and that its schedule is paused" "printf '%s' \"\$PS\" | grep clock | grep -qE '\* \* \* \* \* +- +paused'"
check "ps shows pm's open window, queried from the window workflow" "printf '%s' \"\$PS\" | grep pm | grep -q 'left'"
check "ps shows the held session's first eight characters" "printf '%s' \"\$PS\" | grep -q \"\${SESSION:0:8}\""
check "ps read no state.json, because there is none" "[ ! -e .epito/state.json ]"

step "8: per-agent Slack routing — okr posts to ITS webhook, pm posts to #hq"
code=$(post /window/open '{"scope":"okr"}'); echo "  $code $(body)"
node "$CLI/test/wait-for.mjs" runs okr 1
sleep 0.8
printf '  hq sink>      %s\n' "$(tr '\n' '|' < "$SLACK_HQ")"
printf '  product sink> %s\n' "$(tr '\n' '|' < "$SLACK_PRODUCT")"
check "okr's line went to SLACK_WEBHOOK_URL_EPITOME only" "grep -q '^okr' '$SLACK_PRODUCT' && ! grep -q '^okr' '$SLACK_HQ'"
check "pm's and clock's lines went to SLACK_WEBHOOK_URL" "grep -q '^pm' '$SLACK_HQ' && grep -q '^clock' '$SLACK_HQ' && ! grep -q '^pm' '$SLACK_PRODUCT'"
check "the line still reads as a status board" "grep -qE '^pm · message · 2 turns · [0-9]+s · https://github.com/alexandrapaiz/epitome/pull/999$' '$SLACK_HQ'"
audit "each post is audited" '{"action":"slack.post","posted":true}' 3

step "a seat with no charter refuses loudly, and leaves no clone behind"
code=$(post /window/open '{"scope":"ghost"}'); echo "  $code $(body)"
node "$CLI/test/wait-for.mjs" action ghost run.end 1
audit "it is recorded as a run that ENDED, not a run that vanished" '{"agent":"ghost","action":"run.end","trigger":"window","exit":"charter-missing"}'
audit "the refusal names the rule and the repository, in the audit line" '{"agent":"ghost","action":"run.end","detail":"~[runtime].entry \"prompts/ghost.md\" does not exist in acme/roster; the run refuses to improvise"}'
gone "no clone was left behind for ghost" "${TMPDIR:-/tmp}/epito-ghost-*"
node "$CLI/test/wait-for.mjs" closed ghost
audit "and the window did not stay open with nothing in it" '{"agent":"ghost","action":"window.close","reason":"the opening run failed, so there is no session to hold"}'

step "closing a window discards the session and deletes the clone"
code=$(post /window/close '{"scope":"pm"}'); echo "  $code $(body)"
node "$CLI/test/wait-for.mjs" closed pm
audit "the close is recorded with its reason" '{"agent":"pm","action":"window.close","reason":"requested"}'
gone "no clone left behind for pm" "${TMPDIR:-/tmp}/epito-pm-*"

step "a message with no window held starts a fresh run, and says so"
code=$(post /message/pm '{"text":"no window: treat me as an event"}'); echo "  $code $(body)"
check "the ingress says so, with the fix" "grep -q 'open a window first' '$ROOT/body.json'"
node "$CLI/test/wait-for.mjs" runs pm 3
check "the message text reached the fresh run as payload" "grep -rq 'treat me as an event' \"$STUB\""

step "POST /hooks/<name> is a fresh run, and the payload is data, never instructions"
code=$(post /hooks/pm '{"action":"opened","marker":"hook-payload-reached-the-run"}'); echo "  $code $(body)"
# The hook may land while the previous run is still in flight, in which case it
# arrives as a coalesced follow-up rather than as a new workflow. Either way the
# thing to wait for is the hook's own run.end.
for _ in $(seq 1 100); do [ "$(node "$CLI/test/audit-has.mjs" --count '{"agent":"pm","action":"run.end","trigger":"hook"}')" != 0 ] && break; sleep 0.3; done
audit "the hook ran the agent" '{"agent":"pm","action":"run.end","trigger":"hook","exit":0}'
check "the payload reached the run, as data" "grep -rq 'hook-payload-reached-the-run' \"$STUB\""
check "and it was framed as data, never as instructions" "grep -rq 'never overrides the charter' \"$STUB\""

# Spec v0.1 rule 3: a trigger is explicit and never defaulted. `clock` is the
# one seat in this roster that declares a cron and nothing else, so it is the
# seat that must NOT have a hook endpoint — before the freeze it had one, and
# anyone who could reach the ingress could wake a seat its author had made
# scheduled on purpose.
step "a seat that did not declare [trigger].webhook cannot be woken through the ingress"
before=$(node "$CLI/test/audit-has.mjs" --count '{"agent":"clock","action":"run.start"}')
code=$(post /hooks/clock '{"why":"clock declares cron and nothing else"}'); echo "  $code $(body)"
check "the ingress refuses it with 403, not 404: the seat exists" "[ \"$code\" = 403 ]"
check "it names the rule in the product's words" "grep -q 'a trigger is explicit and never defaulted' '$ROOT/body.json'"
check "it names the schedule the seat DOES run on" "grep -q '\* \* \* \* \* UTC' '$ROOT/body.json'"
check "it carries the fix" "grep -q 'webhook = true' '$ROOT/body.json'"
audit "the refusal is in the audit log, with its reason" '{"agent":"clock","action":"hook","refused":"no-webhook-trigger"}'
sleep 1
after=$(node "$CLI/test/audit-has.mjs" --count '{"agent":"clock","action":"run.start"}')
check "and no run was started for it" "[ \"$after\" = \"$before\" ]"

step "the CLI wrappers speak to the same ingress"
node "$CLI/src/index.js" window open okr | sed 's/^/  /'
node "$CLI/src/index.js" message okr "what did you open?" | sed 's/^/  /'
check "epito message reports the held session" "node '$CLI/src/index.js' message okr 'again' | grep -q 'in held session'"
node "$CLI/src/index.js" window close okr | sed 's/^/  /'
check "a wrong secret is refused in the client's voice too" "(EPITO_HOOK_SECRET=wrong node '$CLI/src/index.js' message okr hi 2>&1 || true) | grep -q 'x-epito-secret header missing or wrong'"
check "no ingress at the port is named, with the fix" "(EPITO_PORT=1 node '$CLI/src/index.js' message okr hi 2>&1 || true) | grep -q 'is EPITO_PORT right'"
check "no engine at the address is named, with the fix" "(TEMPORAL_ADDRESS=127.0.0.1:1 node '$CLI/src/index.js' ps 2>&1 || true) | grep -q 'temporal server start-dev'"

step "1 (idempotence): reconciling again changes nothing"
node "$CLI/src/index.js" run "$ROSTER" --dry-run > "$ROOT/dry.log" 2>&1
sed 's/^/  /' "$ROOT/dry.log"
check "a second reconcile would create, update and delete nothing" "grep -q '1 unchanged' '$ROOT/dry.log' && ! grep -qE 'would (create|update|delete)' '$ROOT/dry.log'"

step "1 (idempotence after an UPDATE): the second reconcile is the one that lies"
# The step above proves reconcile converges after a CREATE, which is the easy
# half: the shape it compares against was written by the create it just did.
# Nothing proved the update path, and the update path did not converge. Found
# 2026-10-06 by running this suite against a real engine for the first time:
#
#   `epito run` stored the shape it registered in the schedule's MEMO, and read
#   it back from there to decide what changed. `handle.update()` accepts a memo
#   in its return value and Temporal's UpdateSchedule RPC has no memo field, so
#   the SDK drops it silently. The memo therefore keeps the CREATE-time shape
#   for the life of the schedule. Consequences, both real:
#     - every later reconcile re-issued the same update, forever: "0 updated"
#       never happened again, and each restart wrote another schedule.update
#       line into the ledger describing a change that had already landed.
#     - `epito ps` printed the memo's stale cron in a column next to a NEXT
#       computed from the live one, so the same row contradicted itself.
#
# The shape is now read from the schedule's action args — the manifest snapshot
# the engine will actually run, which `handle.update()` does rewrite. Note the
# cron cannot be read back from spec: Temporal normalizes a cron expression into
# a structured calendar and `spec.cronExpressions` comes back undefined.
write_manifest clock "*/2 * * * *" "SLACK_WEBHOOK_URL"   # was "* * * * *"
node "$CLI/src/index.js" run "$ROSTER" --dry-run > "$ROOT/dry-upd.log" 2>&1
sed 's/^/  /' "$ROOT/dry-upd.log"
check "a changed cron is seen as an update, with the NEW cron named" "grep -qF 'would update seat:clock (*/2 * * * * UTC)' '$ROOT/dry-upd.log'"
kill -HUP "$INGRESS_PID"; sleep 2
check "SIGHUP applied it as exactly one update" "grep -q 'reconciled: 0 created, 1 updated, 0 deleted, 0 unchanged' '$ROOT/ingress.log'"
check "the update names the field that changed, not \"(re-registered)\"" "grep -qF '~ seat:clock  changed: cron' '$ROOT/ingress.log'"
# Temporal does not store the cron string: it normalizes the expression into a
# structured calendar, which is why the shape cannot be read back from the spec
# and why "*/2" appears here as the range "0-59/2".
check "the engine really took it" "'$TEMPORAL_BIN' schedule describe --schedule-id seat:clock --address 127.0.0.1:$GRPC_PORT --namespace $NS 2>/dev/null | grep -qF '0-59/2'"
# The regression, in one assertion: reconcile a third time and nothing is left
# to do. Before the fix this printed "would update seat:clock" every time it
# was ever run again.
node "$CLI/src/index.js" run "$ROSTER" --dry-run > "$ROOT/dry-upd2.log" 2>&1
sed 's/^/  /' "$ROOT/dry-upd2.log"
check "reconcile CONVERGES: the next one would change nothing" "grep -q '1 unchanged' '$ROOT/dry-upd2.log' && ! grep -qE 'would (create|update|delete)' '$ROOT/dry-upd2.log'"
check "epito ps reads the cron the engine holds, not the one it was born with" "node '$CLI/src/index.js' ps '$ROSTER' | grep -E '^clock' | grep -qF '*/2 * * * *'"

step "1 (the other direction): a seat that loses its cron loses its schedule"
write_manifest clock "" "SLACK_WEBHOOK_URL"        # presence-only from now on
kill -HUP "$INGRESS_PID"; sleep 2
check "SIGHUP re-read the roster and deleted the schedule" "grep -qF -e '- seat:clock  (no manifest with a [trigger].cron behind it any more)' '$ROOT/ingress.log'"
check "temporal has no seat schedules left" "! '$TEMPORAL_BIN' schedule list --address 127.0.0.1:$GRPC_PORT --namespace $NS 2>/dev/null | grep -q seat:clock"
audit "the deletion is in the audit log too" '{"agent":"clock","action":"schedule.delete","schedule":"seat:clock"}'

step "the runs outlive the ingress: restart it and the engine is unchanged"
kill -TERM "$INGRESS_PID"; wait "$INGRESS_PID" 2>/dev/null
node "$CLI/src/index.js" run "$ROSTER" > "$ROOT/ingress2.log" 2>&1 & INGRESS_PID=$!
for _ in $(seq 1 100); do curl -fs "http://127.0.0.1:$PORT/healthz" >/dev/null 2>&1 && break; sleep 0.3; done
check "the fresh ingress reconciled to the same state" "grep -q 'reconciled: 0 created, 0 updated, 0 deleted, 0 unchanged' '$ROOT/ingress2.log'"
check "every run that ever started also ended" "node -e '
const l=require(\"fs\").readFileSync(\".epito/audit.jsonl\",\"utf8\").trim().split(\"\n\").map(JSON.parse);
const s=l.filter(e=>e.action===\"run.start\").length, e=l.filter(e=>e.action===\"run.end\").length;
console.log(\`    run.start=\${s} run.end=\${e}\`); process.exit(e>=s?0:1)'"

step "5: THE BOARD — every run that happened is on it, in the owner's words"
node "$CLI/src/index.js" board --limit 8 | sed 's/^/  /'
check "the seats that ran are on the board, with their run counts" "board | node -e '
const b=JSON.parse(require(\"fs\").readFileSync(0,\"utf8\"));
const seats=Object.fromEntries(b.seats.map(s=>[s.name,s.runs]));
console.log(\"    seats:\", JSON.stringify(seats));
process.exit(seats.pm>=3 && seats.clock>=1 && seats.ghost>=1 && seats.badkey>=1 ? 0 : 1)'"
check "a scheduled run reads as a scheduled run: trigger cron, outcome ok" "board | grep -q '\"trigger\": \"cron\"' && board | node -e '
const b=JSON.parse(require(\"fs\").readFileSync(0,\"utf8\"));
process.exit(b.recent.some(e=>e.agent===\"clock\"&&e.trigger===\"cron\"&&e.outcome===\"ok\"&&e.source===\"epitod\")?0:1)'"
# The board is where you find out WHY a seat is not working, which is the
# question the Slack line and `gh run list` both answer badly.
check "a seat that could not mint is on the board as \"mint\", with the reason" "board | node -e '
const b=JSON.parse(require(\"fs\").readFileSync(0,\"utf8\"));
const e=b.recent.find(x=>x.agent===\"badkey\");
console.log(\"   \", e.outcome, \"—\", (e.detail||\"\").slice(0,72)+\"…\");
process.exit(e.outcome===\"mint\" && /not a readable PEM/.test(e.detail||\"\")?0:1)'"
check "a run that refused for a missing charter says so on the board too" "board | node -e '
const b=JSON.parse(require(\"fs\").readFileSync(0,\"utf8\"));
process.exit(b.recent.some(e=>e.agent===\"ghost\"&&e.outcome===\"charter-missing\")?0:1)'"
check "the PR a run opened is on the board, so the owner reads one place" "board | grep -q 'alexandrapaiz/epitome/pull/999'"
check "no board entry anywhere contains a token" "! grep -qF '$STUB_TOKEN' .epito/board.jsonl && ! grep -qF '$SHARED_TOKEN' .epito/board.jsonl"
check "the board files a run ONCE: no duplicate survived the retried record" "board | node -e '
const b=JSON.parse(require(\"fs\").readFileSync(0,\"utf8\"));
const ids=b.recent.filter(e=>e.runId).map(e=>e.runId);
process.exit(new Set(ids).size===ids.length?0:1)'"

step "5 (the point of one board): a seat this runtime has never hosted files a report"
# market runs in GitHub Actions, not on epitod, and is not in this roster. Its
# report still belongs on the same board — that is what makes it ONE board.
node "$CLI/src/index.js" report market --trigger cron --outcome ok --turns 9 --seconds 412 --pr "https://github.com/alexandrapaiz/epitome/pull/1000" 2>&1 | sed 's/^/  /'
check "it is on the board, from a seat with no workflow on this engine" "board | node -e '
const b=JSON.parse(require(\"fs\").readFileSync(0,\"utf8\"));
const e=b.recent.find(x=>x.agent===\"market\");
process.exit(e && e.turns===9 && e.seconds===412 && e.source===\"cli\"?0:1)'"
node "$CLI/src/index.js" note pm "cycle 1 closes 2026-10-02; bet 2 is on the stack" 2>&1 | sed 's/^/  /'
check "a note is a line about the work, not a run" "board | node -e '
const b=JSON.parse(require(\"fs\").readFileSync(0,\"utf8\"));
const e=b.recent.find(x=>x.kind===\"note\");
process.exit(e && /bet 2 is on the stack/.test(e.text) && b.seats.find(s=>s.name===\"pm\").notes===1?0:1)'"

step "5 (seats cannot create views): the board refuses a column a seat invented"
code=$(post /board '{"agent":"pm","trigger":"cron","priority":"P1","epic":"identity"}'); echo "  $code $(body)"
check "an invented field -> 400 naming both fields and the shape that exists" "[ '$code' = 400 ] && grep -q 'the board has one shape' '$ROOT/body.json' && grep -q 'priority' '$ROOT/body.json' && grep -q 'epic' '$ROOT/body.json' && grep -q 'it holds agent, trigger, runId' '$ROOT/body.json'"
code=$(post /board '{"kind":"view","agent":"pm","name":"my runs"}'); echo "  $code $(body)"
check "a new KIND -> 400: it holds runs and notes" "[ '$code' = 400 ] && grep -q 'it holds run and note entries' '$ROOT/body.json'"
code=$(post /board '{"kind":"note","agent":"pm"}'); echo "  $code $(body)"
check "a note with no words -> 400 with the fix in it" "[ '$code' = 400 ] && grep -q 'an empty note puts nothing on the board' '$ROOT/body.json'"
check "and none of the three reached the board" "! grep -q 'priority' .epito/board.jsonl && ! grep -q '\"view\"' .epito/board.jsonl"

step "5 (reading it from anywhere): GET /board, over the same door and the same secret"
code=$(get "/board?format=text&limit=3"); printf '  %s
' "$code"; sed 's/^/  /' "$ROOT/body.json"
check "?format=text is the table a terminal wants, not JSON in a string" "[ '$code' = 200 ] && grep -q '^the board — ' '$ROOT/body.json' && grep -q 'SEAT  *RUNS' '$ROOT/body.json'"
code=$(get "/board?agent=market"); check "?agent filters to one seat" "[ '$code' = 200 ] && grep -q '\"market\"' '$ROOT/body.json' && ! grep -q '\"ghost\"' '$ROOT/body.json'"
code=$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:$PORT/board")
check "and it is not open to the world: no secret -> 401" "[ '$code' = 401 ]"
code=$(curl -s -o "$ROOT/body.json" -w '%{http_code}' -X PUT -H "x-epito-secret: $SECRET" "http://127.0.0.1:$PORT/board")
check "a wrong method says which methods /board takes" "[ '$code' = 405 ] && grep -q 'POST and GET only' '$ROOT/body.json'"

step "6: A SEAT THAT IS NOT A CLAUDE SESSION — a LangGraph app, hosted unmodified"
# Owner priority 3. graphs is a langgraph seat: same ingress, same mint, same
# board, same audit log, and a completely different agent inside (ADR-17).
code=$(post /hooks/graphs '{"event":"smoke","payload":{"why":"the langgraph adapter"}}'); echo "  $code $(body)"
node "$CLI/test/wait-for.mjs" runs graphs 1 120000 || { echo "the langgraph seat never ran"; tail -30 "$ROOT/worker.log"; }
sed 's/^/  /' .epito/logs/graphs/*.log
audit "it ran, and the audit line names the adapter that ran it" '{"agent":"graphs","action":"run.end","adapter":"langgraph","exit":0}'
audit "the graph's steps came back as the run's turns" '{"agent":"graphs","action":"run.end","turns":2}'
check "the runtime spawned python with the shim, not claude with its flags" "grep -qE 'adapter=langgraph command=.*python' .epito/logs/graphs/*.log"
check "the charter reached the graph, read from inside the clone" "grep -qE 'charter.prompts/graphs.md' .epito/logs/graphs/*.log"
check "and the hook's payload reached it as data" "grep -q 'the langgraph adapter' .epito/logs/graphs/*.log"
# ADR-17 consequence 3: identity is the agent's App, not its framework.
audit "a langgraph seat mints its own identity, through the same code" '{"agent":"graphs","action":"mint","provider":"github-app","installation":"4242"}'
check "its own token reached the graph, and the log kept none of it" "grep -q 'GH_TOKEN=\[redacted' .epito/logs/graphs/*.log && ! grep -qF '$STUB_TOKEN' .epito/logs/graphs/*.log"
check "its commits are the bot's, exactly as a claude seat's are" "grep -qE 'commits authored as epito-seat-4321\[bot\] <99001\+epito-seat-4321\[bot\]@users.noreply.github.com>' .epito/logs/graphs/*.log"
check "it is on the board like any other seat" "board | node -e '
const b=JSON.parse(require(\"fs\").readFileSync(0,\"utf8\"));
const e=b.recent.find(x=>x.agent===\"graphs\");
console.log(\"   \", e.agent, e.trigger, e.outcome, e.turns+\" turns\", e.pr||\"-\");
process.exit(e && e.outcome===\"ok\" && e.turns===2 ? 0 : 1)'"
gone "and the clone it ran in is gone" "${TMPDIR:-/tmp}/epito-graphs-*"

step "6 (presence, honestly): a window over a seat whose agent holds no session"
code=$(post /window/open '{"scope":"graphs","text":"Anything to report?"}'); echo "  $code $(body)"
node "$CLI/test/wait-for.mjs" runs graphs 2 120000
none "no session is held for it: the langgraph adapter has none to hold" '{"agent":"graphs","action":"session.hold"}'
code=$(post /message/graphs '{"text":"And now?"}'); echo "  $code $(body)"
node "$CLI/test/wait-for.mjs" runs graphs 3 120000
audit "a message to it still runs the seat — three runs, none of them resumed" '{"agent":"graphs","action":"run.end"}' 3
none "and nothing pretended to resume a conversation" '{"agent":"graphs","action":"run.end","resume":"*"}'
code=$(post /window/close '{"scope":"graphs"}'); echo "  $code $(body)"
node "$CLI/test/wait-for.mjs" closed graphs 60000
gone "the window closed and took the clone with it" "${TMPDIR:-/tmp}/epito-graphs-*"

step "7: A RUN IS ONE TRACE — run -> clone / mint / execute -> the agent's own steps"
check "the worker says on its first lines where its spans go" "grep -q 'epito worker: traces -> http://127.0.0.1:$OTLP_PORT/v1/traces' '$ROOT/worker.log'"
# The tree is the evidence, so it is printed once and then asserted on.
tree() { node "$CLI/test/trace-shape.mjs" "$SPANS" "$@" > "$ROOT/trace.txt" 2> "$ROOT/trace.err"; rc=$?; sed 's/^/  /' "$ROOT/trace.txt"; [ $rc = 0 ] || sed 's/^/       /' "$ROOT/trace.err"; return $rc; }
check "the scheduled run is a trace: a root, its clone, its execute" "tree clock"
check "a seat with an App also files its two mints, with installation and expiry" "tree pm --minted"
check "and the agent's OWN steps are inside the run's trace, not beside it" "tree graphs --minted --agent-spans 3"
check "a refusal is an ERROR span carrying the sentence, not a silent gap" "node -e '
const fs=require(\"fs\");
const spans=fs.readFileSync(\"$SPANS\",\"utf8\").trim().split(\"\\n\").map(JSON.parse);
const bad=spans.filter(s=>s.status===2);
const mint=bad.find(s=>/not a readable PEM/.test(s.message||\"\"));
const charter=bad.find(s=>/does not exist in acme\/roster/.test(s.message||\"\"));
console.log(\"   \", bad.length, \"error spans;\", (mint?\"badkey mint\":\"\"), (charter?\"+ ghost charter\":\"\"));
process.exit(mint && charter ? 0 : 1)'"
check "no span anywhere carries a credential" "! grep -qF '$STUB_TOKEN' '$SPANS' && ! grep -qF '$SHARED_TOKEN' '$SPANS'"
check "every span in the file belongs to a run of this company's seats" "node -e '
const fs=require(\"fs\");
const spans=fs.readFileSync(\"$SPANS\",\"utf8\").trim().split(\"\\n\").map(JSON.parse);
const services=[...new Set(spans.map(s=>s.service))].sort();
console.log(\"   \", spans.length, \"spans from\", services.join(\", \"));
process.exit(services.every(x=>[\"epito\",\"clock\",\"pm\",\"okr\",\"ghost\",\"badkey\",\"graphs\",\"routed\",\"cheap\"].includes(x))?0:1)'"

step "9: THE ROUTER — a seat declares its roads, and the runtime takes the detour"
# What HQ does by hand in fifteen workflows: try the open provider, fall back
# to the subscription when it refuses (L-E7). Here the runtime does it, once,
# and every seat gets it — including the two that are not Claude sessions.
node "$CLI/src/index.js" routes "$ROSTER" | sed 's/^/  /'
check "epito routes says which road each seat takes ON THIS MACHINE" "node '$CLI/src/index.js' routes '$ROSTER' | grep -q 'routed (claude) — takes open'"
check "and names the road that is closed here, and why" "node '$CLI/src/index.js' routes '$ROSTER' | grep -qF 'premium: a-model-this-box-cannot-reach' && node '$CLI/src/index.js' routes '$ROSTER' | grep -q 'closed: ABSENT_ROUTE_KEY is not set'"
check "a box without the key sees the floor instead — the same manifests, a different machine" "env -u OPEN_ROUTE_KEY node '$CLI/src/index.js' routes '$ROSTER' | grep -q 'cheap (claude) — takes subscription'"
check "no route line ever prints a key" "! node '$CLI/src/index.js' routes '$ROSTER' | grep -qF '$OPEN_KEY'"

code=$(post /hooks/routed '{"why":"the open road refuses this one"}'); echo "  $code $(body)"
node "$CLI/test/wait-for.mjs" runs routed 1 120000
audit "the open road refused at turn one, and the ledger says so by name" '{"agent":"routed","action":"route.refused","route":"open","model":"kimi-k2-turbo-preview","turns":1,"exit":"1"}'
audit "the run took the next road, and the ledger says which one and after what" '{"agent":"routed","action":"route.taken","route":"subscription"}'
audit "the run ended ok — a provider that refused cost the run nothing" '{"agent":"routed","action":"run.end","exit":0,"pr":"https://github.com/alexandrapaiz/epitome/pull/999"}'
audit "and the run is recorded under the model that RAN, not the one it tried first" '{"agent":"routed","action":"run.end","model":"claude-sonnet-5"}'
check "the run log shows the detour in words" "grep -q 'did not start the run .*taking the next road, \"subscription\"' .epito/logs/routed/*.log"
check "the road's key is scrubbed out of the log, named rather than printed" "grep -q 'key=\[redacted: the key for route open\]' .epito/logs/routed/*.log"
check "and it appears nowhere in the log at all" "! grep -qF '$OPEN_KEY' .epito/logs/routed/*.log"

code=$(post /hooks/cheap '{"why":"this one takes the open road"}'); echo "  $code $(body)"
node "$CLI/test/wait-for.mjs" runs cheap 1 120000
check "a road whose key this box does not hold is skipped, not attempted" "grep -q 'route \"premium\" (a-model-this-box-cannot-reach) skipped: ABSENT_ROUTE_KEY is not set on this machine' .epito/logs/cheap/*.log"
none "a skipped road is not a refusal: nothing was tried and nothing failed" '{"agent":"cheap","action":"route.refused","route":"premium"}'
audit "the open road worked, so the run ran on it" '{"agent":"cheap","action":"run.end","exit":0,"model":"kimi-k2-turbo-preview"}'
check "the child really was pointed at the open provider, with the open model" "grep -qF 'endpoint=$OPEN_WORKS' .epito/logs/cheap/*.log"
check "the board says the model that ran, which is the question an owner asks" "board | node -e '
const rows=JSON.parse(require(\"fs\").readFileSync(0,\"utf8\")).recent.filter(r=>r.agent===\"cheap\"&&r.kind===\"run\");
console.log(\"   \", rows.map(r=>[r.agent,r.model,r.outcome].join(\" \")).join(\"; \"));
process.exit(rows.length && rows.every(r=>r.model===\"kimi-k2-turbo-preview\")?0:1)'"
check "every road a run tried is a span inside its execute, refusals included" "node -e '
const fs=require(\"fs\");
const spans=fs.readFileSync(\"$SPANS\",\"utf8\").trim().split(\"\\n\").map(JSON.parse);
const of=(a)=>spans.filter(s=>(s.attrs||{})[\"epito.agent\"]===a);
const roads=of(\"routed\").filter(s=>s.name.indexOf(\"route \")===0);
const execute=of(\"routed\").find(s=>s.name===\"execute\");
console.log(\"   \", roads.map(s=>s.name+\"=\"+(s.attrs||{})[\"epito.outcome\"]+\" under \"+(s.parent===(execute||{}).spanId?\"execute\":\"?\")).join(\"; \"));
const refused=roads.find(s=>s.name===\"route open\"&&(s.attrs||{})[\"epito.outcome\"]===\"refused\"&&s.status===2);
const taken=roads.find(s=>s.name===\"route subscription\"&&(s.attrs||{})[\"epito.outcome\"]===\"ok\");
const nested=roads.every(s=>execute&&s.parent===execute.spanId&&s.traceId===execute.traceId);
process.exit(refused && taken && nested ? 0 : 1)'"
check "the execute span names the road the run ended up on, not the one it asked for" "node -e '
const fs=require(\"fs\");
const spans=fs.readFileSync(\"$SPANS\",\"utf8\").trim().split(\"\\n\").map(JSON.parse);
const ex=spans.find(s=>s.name===\"execute\"&&(s.attrs||{})[\"epito.agent\"]===\"routed\");
console.log(\"   \", (ex.attrs||{})[\"epito.route\"], (ex.attrs||{})[\"epito.model\"]);
process.exit((ex.attrs||{})[\"epito.route\"]===\"subscription\"&&(ex.attrs||{})[\"epito.model\"]===\"claude-sonnet-5\"?0:1)'"
check "no span carries a route's key either" "! grep -qF '$OPEN_KEY' '$SPANS'"

step "board (the file behind it)"
sed 's/^/  /' .epito/board.jsonl

step "audit trail (the product's own record, engine-agnostic)"
sed 's/^/  /' .epito/audit.jsonl

printf '\n%s\n' "-----------------------------------------------"
printf 'smoke: %d ok, %d failed\n' "$pass" "$fail"
[ "$fail" = 0 ] || exit 1
