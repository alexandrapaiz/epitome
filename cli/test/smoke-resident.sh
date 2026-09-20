#!/usr/bin/env bash
# Smoke test for the resident runtime (docs/pitches/runtime-v0-resident.md).
# It spends no tokens and touches no network: the executor is
# test/stub-executor.mjs, "github.com" is rewritten to a local bare repo with
# git's url.<base>.insteadOf, and "Slack" is test/slack-sink.mjs on localhost.
#
#   bash test/smoke-resident.sh          # from cli/
#
# It asserts, in order: a window opens and fires each agent in scope once; the
# executor's session_id is held; a message resumes THAT session in the same
# clone; Slack gets one line per run for the agent that listed the webhook and
# nothing for the one that didn't; `epito ps` shows the window and session;
# closing by hand discards the session and deletes the clone; a message with
# no window falls back to a fresh run; a window expires on its own clock.
set -euo pipefail

CLI="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT="${TMPDIR:-/tmp}/epito-smoke-$$"
ORIGIN="$ROOT/origin"; ROSTER="$ROOT/agents"; STATE="$ROOT/state"; STUB="$ROOT/stub"
PORT="${EPITO_TEST_PORT:-47471}"; SLACK_PORT="${EPITO_TEST_SLACK_PORT:-47472}"
SECRET="smoke-secret-not-a-real-one"
SLACK_LOG="$ROOT/slack.log"
pass=0; fail=0
ok()   { pass=$((pass+1)); printf '  ok   %s\n' "$1"; }
bad()  { fail=$((fail+1)); printf '  FAIL %s\n' "$1"; }
check(){ if eval "$2"; then ok "$1"; else bad "$1"; fi; }
step() { printf '\n== %s\n' "$1"; }

cleanup() {
  [ -n "${DAEMON_PID:-}" ] && kill "$DAEMON_PID" 2>/dev/null || true
  [ -n "${SINK_PID:-}" ] && kill "$SINK_PID" 2>/dev/null || true
  sleep 0.6
  rm -rf "$ROOT"
}
trap cleanup EXIT

mkdir -p "$ORIGIN" "$ROSTER/pm" "$ROSTER/okr" "$ROSTER/ghost" "$STATE" "$STUB"

step "fixture: a local repo standing in for github.com/acme/roster"
seed="$ROOT/seed"
mkdir -p "$seed/prompts"
printf '# pm\n\nYou are pm. One run: open a draft PR.\n' > "$seed/prompts/pm.md"
printf '# okr\n\nYou are okr. One run: open a draft PR.\n' > "$seed/prompts/okr.md"
# ghost's manifest points at prompts/ghost.md, which this repo does not have:
# the runtime must refuse that run rather than improvise a prompt.
git -c init.defaultBranch=main init -q "$seed"
git -C "$seed" add -A
git -C "$seed" -c user.name=smoke -c user.email=smoke@epito.me commit -qm "charters"
git clone -q --bare "$seed" "$ORIGIN/acme/roster.git"
# Every https://github.com/... the daemon clones resolves here instead.
export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0="url.file://$ORIGIN/.insteadOf" GIT_CONFIG_VALUE_0="https://github.com/"
echo "  origin: $ORIGIN/acme/roster.git"

for a in pm okr ghost; do
  slack_env=""
  [ "$a" = pm ] && slack_env=', "SLACK_WEBHOOK_URL"'
  cat > "$ROSTER/$a/agent.toml" <<TOML
[agent]
name = "$a"
description = "Smoke-test seat: the stub executor answers for it."

[identity]
scopes = ["github:contents", "github:pull_requests"]

[trigger]
cron = "0 6 * * *"

[runtime]
model = "claude-sonnet-5"
entry = "prompts/$a.md"
repo = "acme/roster"
max_turns = 5
env = ["EPITO_STUB_DIR"$slack_env]
TOML
done

step "start: slack sink, then the daemon with the stub executor"
node "$CLI/test/slack-sink.mjs" "$SLACK_PORT" "$SLACK_LOG" & SINK_PID=$!
cd "$STATE"
export EPITO_HOOK_SECRET="$SECRET" EPITO_PORT="$PORT" EPITO_STUB_DIR="$STUB" \
       EPITO_EXECUTOR="$CLI/test/stub-executor.mjs" EPITO_WINDOW_MS=600000 \
       SLACK_WEBHOOK_URL="http://127.0.0.1:$SLACK_PORT/hook"
node "$CLI/src/index.js" run "$ROSTER" > "$ROOT/daemon.log" 2>&1 & DAEMON_PID=$!
for _ in $(seq 1 50); do curl -fs "http://127.0.0.1:$PORT/healthz" >/dev/null 2>&1 && break; sleep 0.2; done
curl -fs "http://127.0.0.1:$PORT/healthz" >/dev/null || { echo "daemon never came up"; cat "$ROOT/daemon.log"; exit 1; }
echo "  epitod up on $PORT (pid $DAEMON_PID)"

post() { curl -s -o "$ROOT/body.json" -w '%{http_code}' -X POST -H "x-epito-secret: $SECRET" -H 'content-type: application/json' --data "$2" "http://127.0.0.1:$PORT$1"; }
body() { cat "$ROOT/body.json"; }

step "auth: the ingress refuses a wrong secret and an unknown agent"
code=$(curl -s -o /dev/null -w '%{http_code}' -X POST -H "x-epito-secret: wrong" "http://127.0.0.1:$PORT/message/pm" --data '{"text":"hi"}')
check "wrong secret -> 401" "[ '$code' = 401 ]"
code=$(post /message/nobody '{"text":"hi"}'); echo "  $(body)"
check "unknown agent -> 404 naming the roster" "[ '$code' = 404 ] && grep -q 'it hosts: ' '$ROOT/body.json'"
code=$(post /message/pm '{"text":"   "}'); echo "  $(body)"
check "empty message -> 400 with the fix in it" "[ '$code' = 400 ] && grep -q 'nothing to answer' '$ROOT/body.json'"
code=$(post /window/open '{"scope":"nope"}'); echo "  $(body)"
check "bad scope -> 400 listing the roster" "[ '$code' = 400 ] && grep -q 'scope names no agent' '$ROOT/body.json'"

step "1+4: POST /window/open {scope:all} opens a window on both seats and fires each once"
code=$(post /window/open '{"scope":"all","text":"Agenda: cycle 1 hill check."}'); echo "  $code $(body)"
node "$CLI/test/wait-for.mjs" runs pm 1
node "$CLI/test/wait-for.mjs" runs okr 1
node "$CLI/test/wait-for.mjs" runs ghost 1
check "a window opened on every seat in scope" "[ \$(grep -c '\"action\":\"window.open\"' .epito/audit.jsonl) = 3 ]"
check "each seat ran exactly once" "[ \$(grep -c '\"action\":\"run.end\"' .epito/audit.jsonl) = 3 ]"
check "the window instruction reached the executor" "grep -q 'synchronous mode' \"$STUB\"/*.jsonl"
check "the agenda reached the executor" "grep -q 'cycle 1 hill check' \"$STUB\"/*.jsonl"
check "a session is held for the two seats that ran" "[ \$(grep -c '\"action\":\"session.hold\"' .epito/audit.jsonl) = 2 ]"
check "the seat with no charter refused, by name" "grep -q '\"agent\":\"ghost\",\"action\":\"run.end\",\"trigger\":\"window\",\"model\":\"claude-sonnet-5\",\"exit\":\"charter-missing\"' .epito/audit.jsonl"
check "a refused run holds no session, even with its window open" "node -e 'const a=JSON.parse(require(\"fs\").readFileSync(\".epito/state.json\",\"utf8\")).agents.ghost;process.exit(a.window&&a.session===null?0:1)'"
check "and leaves no clone behind" "[ \$(ls -d \${TMPDIR:-/tmp}/epito-ghost-* 2>/dev/null | wc -l) = 0 ]"
SESSION=$(node -e 'const s=require("fs").readFileSync(".epito/state.json","utf8");console.log(JSON.parse(s).agents.pm.session.id)')
echo "  pm session: $SESSION"
check "the PR the run opened was parsed" "grep -q '\"pr\":\"https://github.com/alexandrapaiz/epitome/pull/999\"' .epito/audit.jsonl"

step "2: POST /message/pm continues THAT session (--resume), in the same clone"
code=$(post /message/pm '{"text":"Which PR did you open?"}'); echo "  $code $(body)"
check "the ingress reports the held session" "grep -q '\"held\":true' '$ROOT/body.json'"
node "$CLI/test/wait-for.mjs" runs pm 2
check "the run resumed the held id" "grep -q '\"action\":\"run.start\",\"trigger\":\"message\",\"model\":\"claude-sonnet-5\",\"resume\":\"$SESSION\"' .epito/audit.jsonl"
check "the transcript has two turns in one session" "[ \$(wc -l < \"$STUB/$SESSION.jsonl\") = 2 ]"
check "the second turn was a resume" "grep -q '\"resumed\":true' \"$STUB/$SESSION.jsonl\""
check "both turns ran in the same clone" "[ \$(node -e 'const l=require(\"fs\").readFileSync(process.argv[1],\"utf8\").trim().split(\"\\n\").map(JSON.parse);console.log(new Set(l.map(x=>x.cwd)).size)' \"$STUB/$SESSION.jsonl\") = 1 ]"
check "the agent answered in context (it names its own PR)" "grep -q 'my PR is still' .epito/logs/pm/*message*.log"
check "turns were recorded" "grep -q '\"turns\":2' .epito/audit.jsonl"

step "3: Slack got one line per run, and only for the seat that listed the webhook"
sleep 0.5; sed 's/^/  slack> /' "$SLACK_LOG"
check "two lines for pm (window run + message)" "[ \$(wc -l < '$SLACK_LOG') = 2 ]"
check "the line names agent, trigger, turns, duration, PR" "grep -q '^pm · message · 2 turns · .*s · https://github.com/alexandrapaiz/epitome/pull/999$' '$SLACK_LOG'"
check "okr posted nothing (no SLACK_WEBHOOK_URL in its [runtime].env)" "! grep -q '^okr' '$SLACK_LOG'"
check "the post is audited" "[ \$(grep -c '\"action\":\"slack.post\",\"posted\":true' .epito/audit.jsonl) = 2 ]"

step "epito ps shows the window and the held session"
node "$CLI/src/index.js" ps | sed 's/^/  /'
check "ps prints the held session" "node '$CLI/src/index.js' ps | grep -q \"\${SESSION:0:8}\""

step "window close by hand: the session is discarded and the clone deleted"
code=$(post /window/close '{"scope":"pm"}'); echo "  $code $(body)"
check "close reports the discarded session" "grep -q '\"session\":\"$SESSION\"' '$ROOT/body.json'"
check "pm has no window or session" "node -e 'const a=JSON.parse(require(\"fs\").readFileSync(\".epito/state.json\",\"utf8\")).agents.pm;process.exit(a.window===null&&a.session===null?0:1)'"
check "no epito clone left behind for pm" "[ \$(ls -d \${TMPDIR:-/tmp}/epito-pm-* 2>/dev/null | wc -l) = 0 ]"

step "2 (fallback): a message with no window held starts a fresh run"
code=$(post /message/pm '{"text":"no window: treat me as an event"}'); echo "  $code $(body)"
check "the ingress says so, with the fix" "grep -q 'open a window first' '$ROOT/body.json'"
node "$CLI/test/wait-for.mjs" runs pm 3
check "it ran without a resume" "[ \$(grep -c '\"trigger\":\"message\",\"model\":\"claude-sonnet-5\",\"window\":false' .epito/audit.jsonl) = 1 ]"
check "the message text reached the fresh run as payload" "grep -rq 'treat me as an event' \"$STUB\""

step "the CLI wrappers speak to the same ingress"
node "$CLI/src/index.js" window open okr | sed 's/^/  /'
node "$CLI/src/index.js" message okr "what did you open?" | sed 's/^/  /'
node "$CLI/test/wait-for.mjs" runs okr 2
check "epito message resumed okr's held session" "node '$CLI/src/index.js' message okr 'again' | grep -q 'in held session'"
node "$CLI/test/wait-for.mjs" runs okr 3
node "$CLI/src/index.js" window close okr | sed 's/^/  /'
check "epito window close discarded okr's session" "node -e 'const a=JSON.parse(require(\"fs\").readFileSync(\".epito/state.json\",\"utf8\")).agents.okr;process.exit(a.window===null&&a.session===null?0:1)'"
check "a wrong secret is refused in the client's voice too" "(EPITO_HOOK_SECRET=wrong node '$CLI/src/index.js' message okr hi 2>&1 || true) | grep -q 'x-epito-secret header missing or wrong'"
check "no daemon at the port is named, with the fix" "(EPITO_PORT=1 node '$CLI/src/index.js' message okr hi 2>&1 || true) | grep -q 'is EPITO_PORT right'"

step "3 (windows expire on the clock): open pm with a 3s window"
code=$(post /window/open '{"scope":"pm","ttl_ms":3000}'); echo "  $code $(body)"
node "$CLI/test/wait-for.mjs" runs pm 4
node "$CLI/test/wait-for.mjs" closed pm 20000
check "the window closed itself" "grep -q '\"action\":\"window.close\",\"reason\":\"expired\"' .epito/audit.jsonl"
check "the expired session was discarded" "node -e 'const a=JSON.parse(require(\"fs\").readFileSync(\".epito/state.json\",\"utf8\")).agents.pm;process.exit(a.session===null?0:1)'"

step "audit trail"
sed 's/^/  /' .epito/audit.jsonl

printf '\n%s\n' "-----------------------------------------------"
printf 'smoke: %d ok, %d failed\n' "$pass" "$fail"
[ "$fail" = 0 ] || exit 1
