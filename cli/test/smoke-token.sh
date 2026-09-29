#!/usr/bin/env bash
# Smoke test for the mint (cycle 1 bet 2): `epito token <name>` and the
# identity a run is handed. It spends nothing and touches no network — the
# GitHub API is test/stub-github.mjs on localhost (it verifies the App JWT for
# real), the App key is generated here and thrown away, "github.com" is a local
# bare repo, and the executor is test/stub-executor.mjs.
#
#   bash test/smoke-token.sh          # from cli/
#
# It asserts, in order: a token mints and lands on stdout alone; the audit
# records the mint without the token; the token appears nowhere on disk; every
# refusal names the rule and the fix (no principal, unmapped scope, unusable
# key, App not installed, App cannot grant the scope); a run is handed its own
# token and commits as the bot; and an identity that fails stops the run
# instead of falling back to the owner's token.
set -euo pipefail

CLI="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT="${TMPDIR:-/tmp}/epito-token-smoke-$$"
ORIGIN="$ROOT/origin"; ROSTER="$ROOT/agents"; STATE="$ROOT/state"; STUB="$ROOT/stub"
PORT="${EPITO_TEST_API_PORT:-47481}"
GHLOG="$ROOT/github.jsonl"
pass=0; fail=0
ok()   { pass=$((pass+1)); printf '  ok   %s\n' "$1"; }
bad()  { fail=$((fail+1)); printf '  FAIL %s\n' "$1"; }
check(){ if eval "$2"; then ok "$1"; else bad "$1"; fi; }
step() { printf '\n== %s\n' "$1"; }
fingerprint() { node -e 'process.stdout.write(require("node:crypto").createHash("sha256").update(process.argv[1]).digest("hex").slice(0,12))' "$1"; }

cleanup() { [ -n "${API_PID:-}" ] && kill "$API_PID" 2>/dev/null || true; sleep 0.3; rm -rf "$ROOT"; }
trap cleanup EXIT

mkdir -p "$ORIGIN" "$STATE" "$STUB" "$GHLOG" 2>/dev/null || true
rmdir "$GHLOG" 2>/dev/null || true
mkdir -p "$ROSTER"/{pm,ghost,packages,stray,nosy}
: > "$GHLOG"

step "fixture: a throwaway App key, a stub api.github.com, a local origin"
node -e '
const { generateKeyPairSync } = require("node:crypto");
const { privateKey } = generateKeyPairSync("rsa", { modulusLength: 2048 });
require("node:fs").writeFileSync(process.argv[1], privateKey.export({ type: "pkcs1", format: "pem" }));
' "$ROOT/app.pem"
chmod 600 "$ROOT/app.pem"
echo "  key: $ROOT/app.pem (generated now, deleted on exit — nothing personal, spec rule 1)"
node "$CLI/test/stub-github.mjs" "$PORT" "$ROOT/app.pem" "$GHLOG" 2>/dev/null & API_PID=$!
for _ in $(seq 1 50); do curl -fs -o /dev/null "http://127.0.0.1:$PORT/healthz" && break; sleep 0.1; done
echo "  stub github on $PORT: App 7 'epito-pm', installed on acme/roster (42), granted contents+pull_requests+metadata"

seed="$ROOT/seed"; mkdir -p "$seed/prompts"
printf '# pm\n\nYou are pm. One run: open a draft PR.\n' > "$seed/prompts/pm.md"
git -c init.defaultBranch=main init -q "$seed"
git -C "$seed" add -A
git -C "$seed" -c user.name=smoke -c user.email=smoke@epito.me commit -qm charters
git clone -q --bare "$seed" "$ORIGIN/acme/roster.git"
export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0="url.file://$ORIGIN/.insteadOf" GIT_CONFIG_VALUE_0="https://github.com/"

manifest() { # name, repo, scopes
  cat > "$ROSTER/$1/agent.toml" <<TOML
[agent]
name = "$1"
description = "Smoke-test seat for the mint."

[identity]
scopes = [$3]

[trigger]
cron = "0 6 * * *"

[runtime]
model = "claude-sonnet-5"
entry = "prompts/pm.md"
repo = "$2"
max_turns = 5
env = ["EPITO_STUB_DIR"]
TOML
}
manifest pm       acme/roster      '"github:contents", "github:pull_requests"'
manifest ghost    acme/roster      '"github:contents"'
manifest packages acme/roster      '"github:contents", "github:packages"'
manifest stray    acme/uninstalled '"github:contents"'
manifest nosy     acme/roster      '"github:contents", "github:issues"'

cd "$STATE"
export GITHUB_API_URL="http://127.0.0.1:$PORT"
KEY="$(cat "$ROOT/app.pem")"
# Every seat but `ghost` has a principal on this box.
for a in PM PACKAGES STRAY NOSY; do export "EPITO_APP_ID_$a=7"; export "EPITO_APP_PRIVATE_KEY_$a=$KEY"; done

step "1: epito token pm mints, and prints the token on stdout and nothing else"
set +e
TOKEN="$(node "$CLI/src/index.js" token pm "$ROSTER" 2>"$ROOT/pm.err")"; rc=$?
set -e
cat "$ROOT/pm.err" | sed 's/^/  | /'
check "exit 0" "[ $rc = 0 ]"
check "stdout is one line, the token" "[ \$(printf '%s' \"\$TOKEN\" | wc -l) = 0 ] && case \"\$TOKEN\" in ghs_stub-*) true;; *) false;; esac"
check "stderr names the bot, the repo and the permissions" "grep -q 'minted for pm: epito-pm\[bot\] on acme/roster (contents:write, pull_requests:write)' '$ROOT/pm.err'"
check "stderr names the expiry" "grep -q 'expires 20' '$ROOT/pm.err'"
check "the App JWT verified against the App key" "grep -q '\"jwt\":\"verified\"' '$GHLOG'"
check "the mint asked for exactly the mapped permissions" "grep -q '\"asked\":{\"contents\":\"write\",\"pull_requests\":\"write\"}' '$GHLOG'"
check "the token is scoped to one repository" "grep -q '\"repositories\":\[\"roster\"\]' '$GHLOG'"
check "GitHub issued the token this run printed" "grep -q '\"token_fingerprint\":\"$(fingerprint "$TOKEN")\"' '$GHLOG'"

step "2: the mint is recorded, the token is not"
tail -1 .epito/audit.jsonl | sed 's/^/  | /'
check "audit has token.mint with app, installation and expiry" "grep -q '\"action\":\"token.mint\",\"via\":\"cli\",\"repo\":\"acme/roster\"' .epito/audit.jsonl && grep -q '\"installation\":42' .epito/audit.jsonl"
check "the token appears in NO file under the test root" "! grep -rqF \"\$TOKEN\" '$ROOT'"

step "3: every refusal names the rule broken and the fix"
try() { set +e; node "$CLI/src/index.js" token "$1" "$ROSTER" >"$ROOT/$1.out" 2>"$ROOT/$1.err"; echo $?; set -e; }
rc=$(try ghost); sed 's/^/  | /' "$ROOT/ghost.err"
check "no principal: names the env vars and the fallback" "[ '$rc' = 1 ] && grep -q 'EPITO_APP_ID_GHOST is unset' '$ROOT/ghost.err' && grep -q 'EPITO_APP_PRIVATE_KEY_GHOST' '$ROOT/ghost.err'"
rc=$(try packages); sed 's/^/  | /' "$ROOT/packages.err"
check "unmapped scope: names the mapped set, mints nothing" "[ '$rc' = 1 ] && grep -q 'scope \"github:packages\" has no GitHub App permission in spec v0.1' '$ROOT/packages.err'"
rc=$(try stray); sed 's/^/  | /' "$ROOT/stray.err"
check "App not installed: says where to install it" "[ '$rc' = 1 ] && grep -q \"App is not installed on acme/uninstalled\" '$ROOT/stray.err'"
rc=$(try nosy); sed 's/^/  | /' "$ROOT/nosy.err"
check "App cannot grant the scope: scopes are the ceiling, the App is the wall" "[ '$rc' = 1 ] && grep -q 'cannot grant what \[identity\].scopes asks for' '$ROOT/nosy.err'"
( export EPITO_APP_PRIVATE_KEY_PM="not a key at all"
  set +e; node "$CLI/src/index.js" token pm "$ROSTER" >/dev/null 2>"$ROOT/badkey.err"; echo "  rc=$?" ; set -e
  sed 's/^/  | /' "$ROOT/badkey.err" )
check "unusable key: names the variable and what belongs in it" "grep -q 'EPITO_APP_PRIVATE_KEY_PM is not a private key' '$ROOT/badkey.err'"
rc=$(try nobody 2>/dev/null || true); sed 's/^/  | /' "$ROOT/nobody.err"
check "unknown agent: lists the roster" "grep -q 'no agent named \"nobody\"' '$ROOT/nobody.err' && grep -q 'ghost, nosy, packages, pm, stray' '$ROOT/nobody.err'"
check "every failed mint is audited (5), and none of them wrote a token" "[ \$(grep -c '\"action\":\"token.fail\"' .epito/audit.jsonl) = 5 ] && ! grep -q 'ghs_' .epito/audit.jsonl"

step "4: a run is handed its own identity (clone -> mint -> executor)"
export EPITO_EXECUTOR="$CLI/test/stub-executor.mjs" EPITO_STUB_DIR="$STUB"
node "$CLI/test/run-once.mjs" "$ROSTER/pm/agent.toml" cron > "$ROOT/run.json" 2> "$ROOT/run.err"
sed 's/^/  | /' "$ROOT/run.err"
RUNTOKEN_FP=$(node -e 'const l=require("fs").readFileSync(process.argv[1],"utf8").trim().split("\n").map(JSON.parse);console.log(l[l.length-1].gh_token_fingerprint)' "$STUB"/*.jsonl)
echo "  the executor saw GH_TOKEN fingerprint $RUNTOKEN_FP"
check "the run minted its own token" "grep -q '\"agent\":\"pm\",\"action\":\"token.mint\",\"via\":\"run\"' .epito/audit.jsonl"
check "GitHub issued exactly the token the executor got" "grep -q '\"token_fingerprint\":\"$RUNTOKEN_FP\"' '$GHLOG'"
check "GITHUB_TOKEN carries the same identity" "node -e 'const l=require(\"fs\").readFileSync(process.argv[1],\"utf8\").trim().split(\"\n\").map(JSON.parse).pop();process.exit(l.gh_token_fingerprint===l.github_token_fingerprint?0:1)' \"\$(ls $STUB/*.jsonl | head -1)\""
check "the run commits as the bot, not as the owner" "node -e 'const l=require(\"fs\").readFileSync(process.argv[1],\"utf8\").trim().split(\"\n\").map(JSON.parse).pop();process.exit(l.git_author===\"epito-pm[bot] <555+epito-pm[bot]@users.noreply.github.com>\"?0:1)' \"\$(ls $STUB/*.jsonl | head -1)\""
check "the run result names the identity it wore" "grep -q '\"identity\":{\"login\":\"epito-pm\[bot\]\"' '$ROOT/run.json'"
check "the run log records the mint by fingerprint-free summary only" "grep -q '# identity: minted epito-pm\[bot\] installation=42' .epito/logs/pm/*.log"
check "no run log contains a token" "! grep -rq 'ghs_stub-' .epito/"

step "5: a principal that cannot mint stops the run — no silent fallback"
( export EPITO_APP_PRIVATE_KEY_PM="not a key at all"
  node "$CLI/test/run-once.mjs" "$ROSTER/pm/agent.toml" cron > "$ROOT/run2.json" 2> "$ROOT/run2.err" || true
  sed 's/^/  | /' "$ROOT/run2.err" )
check "the run ends as exit=identity" "grep -q '\"exit\":\"identity\"' '$ROOT/run2.json'"
check "the executor was never spawned a second time" "[ \$(ls $STUB/*.jsonl | wc -l) = 1 ]"
check "and the failure is audited" "grep -q '\"action\":\"token.fail\",\"via\":\"run\"' .epito/audit.jsonl"

step "6: a box with no principal for an agent runs exactly as before"
node "$CLI/test/run-once.mjs" "$ROSTER/ghost/agent.toml" cron > "$ROOT/run3.json" 2> "$ROOT/run3.err" || true
sed 's/^/  | /' "$ROOT/run3.err"
check "the run happens, with no identity attached" "grep -q '\"exit\":0' '$ROOT/run3.json' && grep -q '\"identity\":null' '$ROOT/run3.json'"
check "and git identity falls back to the agent's name" "grep -q 'ghost <ghost@agents.epito.me>' \"$STUB\"/*.jsonl"

printf '\n== %d passed, %d failed\n' "$pass" "$fail"
[ "$fail" = 0 ]
