#!/usr/bin/env bash
# Smoke test for the identity leg (cycle 1 bet 2): `epito token <name>` and
# the runtime's per-run injection. It spends nothing and touches no network:
# the App key is a throwaway RSA pair this script generates, "api.github.com"
# is test/github-stub.mjs on localhost (which verifies the JWT signature
# against that pair's public half — that is what proves the RS256 token epito
# hand-rolls is one GitHub would accept), "github.com" is a local bare repo
# via git's url.<base>.insteadOf, and the executor is test/stub-executor.mjs.
#
#   bash test/smoke-token.sh             # from cli/
#
# It asserts, in order: a mint asks for exactly the permissions the manifest's
# scopes map to, on exactly the manifest's repo; stdout is the token alone;
# the token reaches no file on disk; the audit line records the mint without
# it; the key can live in the environment or in .epito/keys; an unmapped scope
# fails before any network call; a missing principal, an uninstalled App, a
# corrupt key, a refused permission set and an unknown agent each fail with a
# message that names the rule and the fix; and the resident runtime injects a
# freshly minted token into the run it spawns.
set -euo pipefail

CLI="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT="${TMPDIR:-/tmp}/epito-token-smoke-$$"
ROSTER="$ROOT/agents"; STATE="$ROOT/state"; KEYS="$ROOT/keys"; ORIGIN="$ROOT/origin"
PORT="${EPITO_TEST_API_PORT:-47481}"
API="http://127.0.0.1:$PORT"
REQLOG="$ROOT/requests.jsonl"
pass=0; fail=0
ok()   { pass=$((pass+1)); printf '  ok   %s\n' "$1"; }
bad()  { fail=$((fail+1)); printf '  FAIL %s\n' "$1"; }
check(){ if eval "$2"; then ok "$1"; else bad "$1"; fi; }
step() { printf '\n== %s\n' "$1"; }

cleanup() { [ -n "${STUB_PID:-}" ] && kill "$STUB_PID" 2>/dev/null || true; rm -rf "$ROOT"; }
trap cleanup EXIT

mkdir -p "$ROSTER/pm" "$STATE" "$KEYS" "$ORIGIN"

step "fixture: a throwaway App key, a manifest, a local origin"
openssl genrsa -traditional -out "$KEYS/pm.pem" 2048 2>/dev/null || openssl genrsa -out "$KEYS/pm.pem" 2048 2>/dev/null
openssl rsa -in "$KEYS/pm.pem" -pubout -out "$KEYS/pm.pub.pem" 2>/dev/null
chmod 600 "$KEYS/pm.pem"
echo "  key: $KEYS/pm.pem (generated here, never a real App's)"

cat > "$ROSTER/pm/agent.toml" <<TOML
[agent]
name = "pm"
description = "Smoke-test seat for the identity leg."

[identity]
scopes = ["github:contents", "github:pull_requests"]

[trigger]
cron = "0 6 * * *"

[runtime]
model = "claude-sonnet-5"
entry = "prompts/pm.md"
repo = "acme/roster"
# GH_TOKEN is listed the pre-identity way, and deliberately holds a value that
# is not this agent's: the run must override it with the token it mints.
env = ["EPITO_STUB_DIR", "GH_TOKEN"]
TOML

seed="$ROOT/seed"; mkdir -p "$seed/prompts"
printf '# pm\n\nYou are pm. One run: open a draft PR.\n' > "$seed/prompts/pm.md"
git -c init.defaultBranch=main init -q "$seed"
git -C "$seed" add -A
git -C "$seed" -c user.name=smoke -c user.email=smoke@epito.me commit -qm charters
git clone -q --bare "$seed" "$ORIGIN/acme/roster.git"
export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0="url.file://$ORIGIN/.insteadOf" GIT_CONFIG_VALUE_0="https://github.com/"

# The two secrets a runtime box holds for this agent, per the env convention.
export EPITO_APP_ID_PM=123456
EPITO_APP_KEY_PM="$(cat "$KEYS/pm.pem")"; export EPITO_APP_KEY_PM
export EPITO_GITHUB_API="$API"

start_stub() { # $1 = mode
  [ -n "${STUB_PID:-}" ] && { kill "$STUB_PID" 2>/dev/null || true; sleep 0.3; }
  : > "$REQLOG"
  node "$CLI/test/github-stub.mjs" "$PORT" "$KEYS/pm.pub.pem" "$REQLOG" "$1" >/dev/null 2>&1 &
  STUB_PID=$!
  node "$CLI/test/wait-for.mjs" "$API/ping" 4000 >/dev/null 2>&1 || sleep 0.5
}

epito() { (cd "$STATE" && node "$CLI/src/index.js" "$@"); }

# The body of the access_tokens request the stub last received, verbatim.
mint_body() {
  node -e 'const fs=require("fs");const rs=fs.readFileSync(process.argv[1],"utf8").trim().split("\n").filter(Boolean).map(l=>JSON.parse(l));const m=rs.filter(r=>r.url.includes("access_tokens")).pop();process.stdout.write(m?m.body:"(no mint request)")' "$REQLOG"
}

step "mint: \`epito token pm\` against the stub API"
start_stub ok
set +e
OUT="$(epito token pm "$ROSTER" 2>"$ROOT/err.txt")"; RC=$?
set -e
ERR="$(cat "$ROOT/err.txt")"
printf '  $ epito token pm %s\n' "$ROSTER"
printf '  stdout: %s\n' "$OUT"
printf '  stderr: %s\n' "$ERR"
check "exits 0" "[ $RC -eq 0 ]"
check "stdout is the token and nothing else" '[ "$OUT" = "ghs_STUBTOKEN0000000000000000000000000000" ]'
check "stderr names permissions, repo, installation and expiry" 'echo "$ERR" | grep -q "contents:write, pull_requests:write on acme/roster, installation 4242, expires"'

step "the JWT the stub verified, and the mint request it received"
grep -c . "$REQLOG" >/dev/null
cat "$REQLOG" | sed 's/^/  /'
check "the App JWT verified against the App's public key" '[ "$(grep -c "\"jwtOk\":true" "$REQLOG")" -ge 2 ]'
check "signed as the App id from the environment" 'grep -q "\"iss\":\"123456\"" "$REQLOG"'
check "installation discovered from [runtime].repo" 'grep -q "/repos/acme/roster/installation" "$REQLOG"'
MINTBODY="$(mint_body)"
printf '  mint request body: %s\n' "$MINTBODY"
check "asked for exactly the manifest's scopes, mapped, and nothing more" \
  '[ "$MINTBODY" = "{\"permissions\":{\"contents\":\"write\",\"pull_requests\":\"write\"},\"repositories\":[\"roster\"]}" ]'

step "the audit line, and where the token is not"
sed 's/^/  /' "$STATE/.epito/audit.jsonl"
check "one mint line, with agent, scopes and permissions" 'grep -q "\"action\":\"mint\"" "$STATE/.epito/audit.jsonl" && grep -q "github:pull_requests" "$STATE/.epito/audit.jsonl"'
check "the audit line records the model that will act under it" 'grep -q "\"model\":\"claude-sonnet-5\"" "$STATE/.epito/audit.jsonl"'
check "the token is in no file under the working dir" '! grep -rq "ghs_STUBTOKEN" "$STATE"'

step "the other route: .epito/keys/<agent>.pem + principals.json"
mkdir -p "$STATE/.epito/keys"
cp "$KEYS/pm.pem" "$STATE/.epito/keys/pm.pem"; chmod 600 "$STATE/.epito/keys/pm.pem"
cat > "$STATE/.epito/principals.json" <<JSON
[{ "agent": "pm", "provider": "github-app", "externalId": "998877",
   "installations": [{ "repo": "acme/roster", "installationId": "4242" }],
   "createdAt": "2026-09-25T00:00:00Z" }]
JSON
start_stub ok
set +e
OUT2="$(env -u EPITO_APP_ID_PM -u EPITO_APP_KEY_PM bash -c "cd '$STATE' && node '$CLI/src/index.js' token pm '$ROSTER'" 2>"$ROOT/err2.txt")"; RC2=$?
set -e
printf '  stdout: %s\n' "$OUT2"
printf '  stderr: %s\n' "$(cat "$ROOT/err2.txt")"
check "mints with no App secret in the environment at all" "[ $RC2 -eq 0 ] && [ -n \"\$OUT2\" ]"
check "signs as the App id from principals.json" 'grep -q "\"iss\":\"998877\"" "$REQLOG"'
check "skips discovery when the principal records the installation" '! grep -q "/repos/acme/roster/installation" "$REQLOG"'
rm -rf "$STATE/.epito/keys" "$STATE/.epito/principals.json"

step "a key written with \\n escapes on one line (what an EnvironmentFile holds)"
start_stub ok
ESCAPED="$(node -e 'process.stdout.write(require("fs").readFileSync(process.argv[1],"utf8").replace(/\n/g,"\\n"))' "$KEYS/pm.pem")"
set +e
OUT3="$(EPITO_APP_KEY_PM="$ESCAPED" bash -c "cd '$STATE' && node '$CLI/src/index.js' token pm '$ROSTER'" 2>/dev/null)"; RC3=$?
set -e
check "mints from a one-line PEM, which is how deploy/provision-host.sh says to store it" "[ $RC3 -eq 0 ] && [ -n \"\$OUT3\" ]"

step "refusals: each names the rule broken and the fix"
try() { # $1 label, $2 grep, then the command
  local label="$1" want="$2"; shift 2
  set +e; local out; out="$("$@" 2>&1 >/dev/null)"; local rc=$?; set -e
  printf '  $ %s\n  %s\n' "$*" "$out"
  if [ $rc -ne 0 ] && echo "$out" | grep -q "$want"; then ok "$label"; else bad "$label (rc=$rc)"; fi
}

start_stub ok
: > "$REQLOG"
sed -i.bak 's/"github:pull_requests"/"github:pull_requests", "github:packages"/' "$ROSTER/pm/agent.toml"
try "an unmapped scope is refused, by name, with the mapped ones listed" \
  'cannot mint: "github:packages"' bash -c "cd '$STATE' && node '$CLI/src/index.js' token pm '$ROSTER'"
check "and it refused before calling GitHub at all" '[ ! -s "$REQLOG" ]'
mv "$ROSTER/pm/agent.toml.bak" "$ROSTER/pm/agent.toml"

try "an agent with no principal names both places a key can live" \
  'no principal in .epito/principals.json' \
  env -u EPITO_APP_ID_PM -u EPITO_APP_KEY_PM bash -c "cd '$STATE' && node '$CLI/src/index.js' token pm '$ROSTER'"

try "a key that is not a PEM says so, and says where the real one comes from" \
  'not a readable PEM' \
  env EPITO_APP_KEY_PM="-----BEGIN RSA PRIVATE KEY-----
notakey
-----END RSA PRIVATE KEY-----" bash -c "cd '$STATE' && node '$CLI/src/index.js' token pm '$ROSTER'"

try "an unknown agent lists the roster it looked at" \
  'no agent named "ghost"' bash -c "cd '$STATE' && node '$CLI/src/index.js' token ghost '$ROSTER'"

start_stub not-installed
try "an App that is not installed on the repo says who installs it" \
  'is not installed on acme/roster' bash -c "cd '$STATE' && node '$CLI/src/index.js' token pm '$ROSTER'"

start_stub bad-app
try "credentials GitHub rejects say which two things must match" \
  'not from the same App' bash -c "cd '$STATE' && node '$CLI/src/index.js' token pm '$ROSTER'"

start_stub refuse-perms
try "permissions the App was never granted name the grant to make" \
  'grant the App contents:write, pull_requests:write' bash -c "cd '$STATE' && node '$CLI/src/index.js' token pm '$ROSTER'"

step "the runtime injects a freshly minted token into the run it spawns"
start_stub ok
export EPITO_STUB_DIR="$ROOT/stub"
export GH_TOKEN="ghp_inherited_human_token_not_the_agents"
cat > "$ROOT/run-once.mjs" <<'MJS'
const { loadManifest } = await import(process.env.MANIFEST_LIB);
const { runAgent } = await import(process.env.RUNNER_PATH);
const { manifest } = loadManifest(process.env.MANIFEST_PATH);
const r = await runAgent({ agent: manifest, trigger: "cron", executor: process.env.EPITO_EXECUTOR, timeoutMs: 60000, log: (m) => console.error(m) });
console.log(JSON.stringify({ exit: r.exit, pr: r.pr, identity: r.identity }));
MJS
set +e
RUNOUT="$(cd "$STATE" && MANIFEST_PATH="$ROSTER/pm/agent.toml" RUNNER_PATH="$CLI/src/lib/runner.js" \
  MANIFEST_LIB="$CLI/src/lib/manifest.js" EPITO_EXECUTOR="$CLI/test/stub-executor.mjs" \
  node "$ROOT/run-once.mjs" 2>"$ROOT/run-err.txt")"
set -e
printf '  %s\n' "$RUNOUT"
printf '  %s\n' "$(cat "$ROOT/run-err.txt")"
TRANSCRIPT="$(find "$ROOT/stub" -name '*.jsonl' 2>/dev/null | head -1)"
printf '  transcript: %s\n' "$(cat "$TRANSCRIPT" 2>/dev/null | head -c 400)"
check "the run completed and opened its PR" 'echo "$RUNOUT" | grep -q "\"exit\":0" && echo "$RUNOUT" | grep -q "/pull/999"'
check "the run reports the identity it acted under" 'echo "$RUNOUT" | grep -q "\"installation\":\"4242\"" || echo "$RUNOUT" | grep -q "\"installation\":4242"'
check "the minted token reached the agent process as GH_TOKEN" 'grep -q "\"gh_token_prefix\":\"ghs_STUB\"" "$TRANSCRIPT"'
check "GITHUB_TOKEN carries the same credential" 'grep -q "\"github_token_matches\":true" "$TRANSCRIPT"'
check "the agent's own token outranks the GH_TOKEN it inherited" '! grep -q "ghp_inhe" "$TRANSCRIPT"'
check "the run's mint is on the audit trail, token-free" '[ "$(grep -c "\"action\":\"mint\"" "$STATE/.epito/audit.jsonl")" -ge 3 ] && ! grep -q "ghs_STUBTOKEN" "$STATE/.epito/audit.jsonl"'

step "a principal that cannot mint fails the run — it never falls back to a human's token"
start_stub bad-app
set +e
FAILOUT="$(cd "$STATE" && MANIFEST_PATH="$ROSTER/pm/agent.toml" RUNNER_PATH="$CLI/src/lib/runner.js" \
  MANIFEST_LIB="$CLI/src/lib/manifest.js" EPITO_EXECUTOR="$CLI/test/stub-executor.mjs" \
  node "$ROOT/run-once.mjs" 2>&1)"
set -e
printf '  %s\n' "$FAILOUT"
check "the run stops at the mint and says why" 'echo "$FAILOUT" | grep -q "\"exit\":\"mint\"" && echo "$FAILOUT" | grep -q "not from the same App"'

printf '\n== %d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
