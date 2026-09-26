#!/usr/bin/env bash
# Smoke test for epitod v1 on Temporal (docs/prfaq/epitod-v1-temporal.md).
# It spends no tokens and touches no network: the engine is a local
# `temporal server start-dev`, the executor is test/stub-executor.mjs,
# "github.com" is rewritten to a local bare repo with git's
# url.<base>.insteadOf, and "Slack" is two test/slack-sink.mjs on localhost.
#
#   bash test/smoke-temporal.sh          # from cli/
#
# It proves the three things the owner's directive names, plus the behavior v0
# had that must not regress:
#
#   1. a SCHEDULE fires a run           (a real clock tick, not a hand trigger)
#   2. a WINDOW holds a session and a message RESUMES it in the same clone
#   3. `epito ps` reads TEMPORAL        (schedules, running workflows, queries)
#   + reconcile is idempotent, and deletes the schedule of a seat that loses
#     its cron; per-agent Slack routing sends each seat's line to its own
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
NS="epito-smoke"
SECRET="smoke-secret-not-a-real-one"
SLACK_HQ="$ROOT/slack-hq.log"; SLACK_PRODUCT="$ROOT/slack-product.log"
pass=0; fail=0
ok()   { pass=$((pass+1)); printf '  ok   %s\n' "$1"; }
bad()  { fail=$((fail+1)); printf '  FAIL %s\n' "$1"; }
check(){ if eval "$2"; then ok "$1"; else bad "$1"; fi; }
# Assert the audit log holds N lines matching a JSON pattern. Matching by
# predicate, not by substring: a substring match on a serialized object is an
# assertion about key order, which is not a promise this runtime makes.
audit(){ label="$1"; shift; if node "$CLI/test/audit-has.mjs" "$@" >/dev/null 2>&1; then ok "$label"; else bad "$label"; node "$CLI/test/audit-has.mjs" "$@" 2>&1 | sed 's/^/       /'; fi; }
step() { printf '\n== %s\n' "$1"; }

cleanup() {
  for pid in ${INGRESS_PID:-} ${WORKER_PID:-} ${SINK1_PID:-} ${SINK2_PID:-} ${SERVER_PID:-}; do
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
for a in clock pm okr; do printf '# %s\n\nYou are %s. One run: open a draft PR.\n' "$a" "$a" > "$seed/prompts/$a.md"; done
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
    if [ -n "$3" ]; then
      printf 'slack_webhook_env = "%s"\n' "$3"
      printf 'env = ["EPITO_STUB_DIR", "%s"]\n' "$3"
    else
      printf 'env = ["EPITO_STUB_DIR"]\n'
    fi
  } > "$ROSTER/$1/agent.toml"
}
write_manifest clock "* * * * *" "SLACK_WEBHOOK_URL"
write_manifest pm    ""          "SLACK_WEBHOOK_URL"
write_manifest okr   ""          "SLACK_WEBHOOK_URL_EPITOME"   # per-agent routing: its own channel
write_manifest ghost ""          ""
echo "  clock (cron * * * * *), pm, okr (own webhook), ghost (no charter)"

step "every manifest still passes \`epito validate\` — spec v0.1 stays compatible"
for a in clock pm okr ghost; do
  out=$(cd "$ROSTER/$a" && node "$CLI/src/index.js" validate 2>&1); rc=$?
  check "validate $a: $out" "[ $rc = 0 ]"
done

step "start: two slack sinks, the worker, then the reconciler + ingress"
node "$CLI/test/slack-sink.mjs" "$SLACK_HQ_PORT" "$SLACK_HQ" > "$ROOT/sink1.log" 2>&1 & SINK1_PID=$!
node "$CLI/test/slack-sink.mjs" "$SLACK_PRODUCT_PORT" "$SLACK_PRODUCT" > "$ROOT/sink2.log" 2>&1 & SINK2_PID=$!
cd "$STATE"
export TEMPORAL_ADDRESS="127.0.0.1:$GRPC_PORT" TEMPORAL_NAMESPACE="$NS" \
       EPITO_HOOK_SECRET="$SECRET" EPITO_PORT="$PORT" EPITO_STUB_DIR="$STUB" \
       EPITO_EXECUTOR="$CLI/test/stub-executor.mjs" EPITO_WINDOW_MS=600000 \
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
check "the presence-only seats are named as such" "grep -qF 'presence-only (no [trigger].cron, so no schedule): ghost, okr, pm' '$ROOT/ingress.log'"
check "the schedule is seat:clock, in UTC, with its model and repo" "grep -qF '+ seat:clock  * * * * * UTC  claude-sonnet-5  acme/roster' '$ROOT/ingress.log'"
check "temporal itself lists it" "'$TEMPORAL_BIN' schedule list --address 127.0.0.1:$GRPC_PORT --namespace $NS 2>/dev/null | grep -q seat:clock"
audit "the audit log records the registration" '{"agent":"clock","action":"schedule.create","schedule":"seat:clock"}'
check "/healthz reports the engine it depends on" "curl -fs http://127.0.0.1:$PORT/healthz | grep -q '\"temporal\":\"127.0.0.1:$GRPC_PORT\"'"

post() { curl -s -o "$ROOT/body.json" -w '%{http_code}' -X POST -H "x-epito-secret: $SECRET" -H 'content-type: application/json' --data "$2" "http://127.0.0.1:$PORT$1"; }
body() { cat "$ROOT/body.json"; }

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
check "and the clone it ran in is gone" "[ \$(ls -d \${TMPDIR:-/tmp}/epito-clock-* 2>/dev/null | wc -l) = 0 ]"
# Schedule listing is eventually consistent by Temporal's own documentation, so
# a pause is a thing to wait for rather than to read once.
for _ in $(seq 1 40); do node "$CLI/src/index.js" ps 2>/dev/null | grep clock | grep -q paused && break; sleep 0.5; done
check "epito ps shows the schedule as paused, read from the engine" "node '$CLI/src/index.js' ps | grep clock | grep -q paused"

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

step "3: \`epito ps\` reads TEMPORAL — schedules, running workflows, and the window's own answer"
node "$CLI/src/index.js" ps "$ROSTER" | sed 's/^/  /'
PS=$(node "$CLI/src/index.js" ps "$ROSTER")
check "ps names the engine it read" "printf '%s' \"\$PS\" | grep -q 'epitod on 127.0.0.1:$GRPC_PORT namespace=$NS queue=seats'"
check "ps shows clock's cron and its next fire, from the schedule" "printf '%s' \"\$PS\" | grep -E 'clock .*\* \* \* \* \*' | grep -qE '[0-9]{4}-[0-9]{2}-[0-9]{2}T'"
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
check "no clone was left behind for ghost" "[ \$(ls -d \${TMPDIR:-/tmp}/epito-ghost-* 2>/dev/null | wc -l) = 0 ]"
node "$CLI/test/wait-for.mjs" closed ghost
audit "and the window did not stay open with nothing in it" '{"agent":"ghost","action":"window.close","reason":"the opening run failed, so there is no session to hold"}'

step "closing a window discards the session and deletes the clone"
code=$(post /window/close '{"scope":"pm"}'); echo "  $code $(body)"
node "$CLI/test/wait-for.mjs" closed pm
audit "the close is recorded with its reason" '{"agent":"pm","action":"window.close","reason":"requested"}'
check "no clone left behind for pm" "[ \$(ls -d \${TMPDIR:-/tmp}/epito-pm-* 2>/dev/null | wc -l) = 0 ]"

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

step "audit trail (the product's own record, engine-agnostic)"
sed 's/^/  /' .epito/audit.jsonl

printf '\n%s\n' "-----------------------------------------------"
printf 'smoke: %d ok, %d failed\n' "$pass" "$fail"
[ "$fail" = 0 ] || exit 1
