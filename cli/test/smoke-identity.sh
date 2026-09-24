#!/usr/bin/env bash
# Smoke test for the identity slice (cycle 1 bet 2): the agent as a
# credentialed principal. It spends no tokens, touches no live account and
# creates no real GitHub App: the key pair is generated here and thrown away,
# "api.github.com" is test/github-stub.mjs (which verifies the RS256 signature
# rather than rubber-stamping it), and the executor is test/stub-executor.mjs.
#
#   bash test/smoke-identity.sh          # from cli/
#
# It asserts, in order: the scope map refuses what it cannot map, by name;
# half a principal is an error, not a silent fallback; --dry-run answers with
# no network; a real mint produces a token on stdout ALONE with the summary on
# stderr; the audit line records the mint and never the token; the App's own
# permissions are the outer ceiling (422); an App not installed on the repo
# says which repo and how to fix it; and — the slice's whole point — a run
# started by the daemon carries the minted token into the executor and commits
# as <slug>[bot], while an agent with no principal runs exactly as before.
set -euo pipefail

CLI="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT="${TMPDIR:-/tmp}/epito-identity-$$"
ORIGIN="$ROOT/origin"; ROSTER="$ROOT/agents"; STATE="$ROOT/state"; STUB="$ROOT/stub"
API_PORT="${EPITO_TEST_API_PORT:-47481}"; PORT="${EPITO_TEST_PORT2:-47482}"
SECRET="identity-smoke-secret-not-a-real-one"
APILOG="$ROOT/api.log"
pass=0; fail=0
ok()   { pass=$((pass+1)); printf '  ok   %s\n' "$1"; }
bad()  { fail=$((fail+1)); printf '  FAIL %s\n' "$1"; }
check(){ if eval "$2"; then ok "$1"; else bad "$1"; fi; }
step() { printf '\n== %s\n' "$1"; }

cleanup() {
  [ -n "${DAEMON_PID:-}" ] && kill "$DAEMON_PID" 2>/dev/null || true
  [ -n "${API_PID:-}" ] && kill "$API_PID" 2>/dev/null || true
  sleep 0.4
  rm -rf "$ROOT"
}
trap cleanup EXIT

mkdir -p "$ORIGIN" "$ROSTER/pm" "$ROSTER/okr" "$ROSTER/stray" "$STATE" "$STUB" "$ROOT/keys"

step "fixture: a throwaway RSA key pair (never a real App key) and a local origin"
node -e '
  const { generateKeyPairSync } = require("node:crypto");
  const { writeFileSync } = require("node:fs");
  const { privateKey, publicKey } = generateKeyPairSync("rsa", { modulusLength: 2048,
    privateKeyEncoding: { type: "pkcs1", format: "pem" }, publicKeyEncoding: { type: "spki", format: "pem" } });
  writeFileSync(process.argv[1], privateKey, { mode: 0o600 });
  writeFileSync(process.argv[2], publicKey);
' "$ROOT/keys/pm.pem" "$ROOT/keys/pm.pub"
echo "  key: $ROOT/keys/pm.pem (generated now, deleted on exit)"

seed="$ROOT/seed"; mkdir -p "$seed/prompts"
printf '# pm\n\nYou are pm. One run: open a draft PR.\n' > "$seed/prompts/pm.md"
printf '# okr\n\nYou are okr. One run: open a draft PR.\n' > "$seed/prompts/okr.md"
git -c init.defaultBranch=main init -q "$seed"
git -C "$seed" add -A
git -C "$seed" -c user.name=smoke -c user.email=smoke@epito.me commit -qm charters
git clone -q --bare "$seed" "$ORIGIN/acme/roster.git"
export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0="url.file://$ORIGIN/.insteadOf" GIT_CONFIG_VALUE_0="https://github.com/"

# pm has a principal; okr deliberately does not (the v0 fallback); stray
# declares a scope epito cannot map.
for a in pm okr; do
  cat > "$ROSTER/$a/agent.toml" <<TOML
[agent]
name = "$a"
description = "Identity smoke seat: the stub executor answers for it."

[identity]
scopes = ["github:contents", "github:pull_requests", "github:issues.read"]

[trigger]
cron = "0 6 * * *"

[runtime]
model = "claude-sonnet-5"
entry = "prompts/$a.md"
repo = "acme/roster"
max_turns = 5
env = ["EPITO_STUB_DIR", "GH_TOKEN"]
TOML
done
sed 's/"github:issues.read"/"github:packages", "slack:post"/' "$ROSTER/pm/agent.toml" | sed 's/name = "pm"/name = "stray"/;s|prompts/pm.md|prompts/pm.md|' > "$ROSTER/stray/agent.toml"

step "start: the GitHub API stub (it verifies the JWT, it does not trust it)"
export EPITO_STUB_APPS='{"1234":{"slug":"epito-pm","installation":424242,"userId":90210}}'
node "$CLI/test/github-stub.mjs" "$API_PORT" "$ROOT/keys/pm.pub" "$APILOG" & API_PID=$!
for _ in $(seq 1 50); do curl -s -o /dev/null "http://127.0.0.1:$API_PORT/" && break; sleep 0.2; done
export EPITO_GITHUB_API="http://127.0.0.1:$API_PORT"
cd "$STATE"
epito() { node "$CLI/src/index.js" "$@"; }

step "the scope map is the ceiling: an unmappable scope refuses, by name"
out=$(epito token stray "$ROSTER" 2>&1 || true); echo "$out" | sed 's/^/  /'
check "names both unmapped scopes" "grep -q 'github:packages' <<<\"\$out\" && grep -q 'slack:post' <<<\"\$out\""
check "says what v0.1 does map, and the .read suffix" "grep -q 'github:contents' <<<\"\$out\" && grep -q '.read for read-only' <<<\"\$out\""
check "exits non-zero" "! epito token stray '$ROSTER' >/dev/null 2>&1"

step "half a principal is an error, never a silent fallback to the shared token"
out=$(EPITO_APP_ID_PM=1234 epito token pm "$ROSTER" 2>&1 || true); echo "$out" | sed 's/^/  /'
check "names the key variable and the .pem alternative" "grep -q 'EPITO_APP_KEY_PM' <<<\"\$out\" && grep -q 'EPITO_APP_KEY_FILE_PM' <<<\"\$out\""
check "says why it refuses rather than falling back" "grep -q 'worse than no PR' <<<\"\$out\""
out=$(EPITO_APP_ID_PM=epito-pm EPITO_APP_KEY_FILE_PM="$ROOT/keys/pm.pem" epito token pm "$ROSTER" 2>&1 || true); echo "$out" | sed 's/^/  /'
check "a slug where the numeric id belongs is caught before any network call" "grep -q 'numeric id' <<<\"\$out\""
out=$(EPITO_APP_ID_PM=1234 EPITO_APP_KEY_PM="not a pem" epito token pm "$ROSTER" 2>&1 || true); echo "$out" | sed 's/^/  /'
check "a key that is not a PEM is named as such" "grep -q 'not a PEM private key' <<<\"\$out\""

step "--dry-run: what would this mint? No network, no secret"
out=$(epito token pm "$ROSTER" --dry-run 2>&1 || true); echo "$out" | sed 's/^/  /'
check "shows the mapped permissions" "grep -q 'contents: write' <<<\"\$out\" && grep -q 'pull_requests: write' <<<\"\$out\" && grep -q 'issues: read' <<<\"\$out\""
check "metadata is named explicitly, not left implicit" "grep -q 'metadata: read' <<<\"\$out\""
check "says no principal is on this box yet, and which variables to set" "grep -q 'EPITO_APP_ID_PM' <<<\"\$out\""
check "asked GitHub nothing (no installation lookup, no mint)" "! grep -q 'installation' '$APILOG'"

step "the mint: token on stdout ALONE, the human summary on stderr"
export EPITO_APP_ID_PM=1234 EPITO_APP_KEY_FILE_PM="$ROOT/keys/pm.pem"
TOKEN=$(epito token pm "$ROSTER" 2>"$ROOT/mint.err")
sed 's/^/  stderr> /' "$ROOT/mint.err"
check "stdout is the token and nothing else" "[ '$TOKEN' = 'ghs_stubtoken_424242' ]"
check "stderr names the bot, the repo, the app and the installation" "grep -q 'minted for epito-pm\[bot\] on acme/roster (app 1234, installation 424242)' '$ROOT/mint.err'"
check "stderr shows the granted permissions and the expiry" "grep -q 'contents: write' '$ROOT/mint.err' && grep -q 'expires 20' '$ROOT/mint.err'"
check "GitHub was asked for exactly one repository" "grep -q 'repos=\[\"roster\"\]' '$APILOG'"
check "and for exactly the mapped permissions" "grep -q 'permissions={\"contents\":\"write\",\"pull_requests\":\"write\",\"issues\":\"read\",\"metadata\":\"read\"}' '$APILOG'"
sed 's/^/  api> /' "$APILOG"

step "the audit records the mint and never the token"
sed 's/^/  /' .epito/audit.jsonl
check "one token.mint line" "[ \$(grep -c '\"action\":\"token.mint\"' .epito/audit.jsonl) = 1 ]"
check "it names the scopes, the app, the installation, the expiry and the bot" "grep -q '\"as\":\"epito-pm\[bot\]\"' .epito/audit.jsonl && grep -q '\"installation\":424242' .epito/audit.jsonl"
check "the token itself appears in NO file under .epito/" "! grep -rq 'ghs_stubtoken' .epito/"

step "the App's own permissions are the outer ceiling (GitHub says 422)"
out=$(EPITO_STUB_GRANTED='{"contents":"read","metadata":"read"}' bash -c '
  kill '"$API_PID"' 2>/dev/null; sleep 0.3
  node "'"$CLI"'/test/github-stub.mjs" '"$API_PORT"' "'"$ROOT"'/keys/pm.pub" "'"$APILOG"'.422" &
  sleep 0.6
  node "'"$CLI"'/src/index.js" token pm "'"$ROSTER"'" 2>&1 || true
  kill %1 2>/dev/null' ); echo "$out" | sed 's/^/  /'
check "the refusal quotes GitHub and names both ways out" "grep -q 'not granted' <<<\"\$out\" && grep -q 'narrow \[identity\].scopes' <<<\"\$out\""
node "$CLI/test/github-stub.mjs" "$API_PORT" "$ROOT/keys/pm.pub" "$APILOG" & API_PID=$!
sleep 0.6

step "an App not installed on the repo says which repo, and how to fix it"
out=$(EPITO_STUB_MISSING=acme/roster bash -c '
  kill '"$API_PID"' 2>/dev/null; sleep 0.3
  EPITO_STUB_MISSING=acme/roster node "'"$CLI"'/test/github-stub.mjs" '"$API_PORT"' "'"$ROOT"'/keys/pm.pub" "'"$APILOG"'.404" &
  sleep 0.6
  node "'"$CLI"'/src/index.js" token pm "'"$ROSTER"'" 2>&1 || true
  kill %1 2>/dev/null'); echo "$out" | sed 's/^/  /'
check "it names the repository and the install path" "grep -q 'not installed on acme/roster' <<<\"\$out\" && grep -q 'Only select repositories' <<<\"\$out\""
node "$CLI/test/github-stub.mjs" "$API_PORT" "$ROOT/keys/pm.pub" "$APILOG" & API_PID=$!
sleep 0.6

step "the point of the slice: a run carries the agent's own credential"
rm -rf "$ROSTER/stray"
export EPITO_HOOK_SECRET="$SECRET" EPITO_PORT="$PORT" EPITO_STUB_DIR="$STUB" \
       EPITO_EXECUTOR="$CLI/test/stub-executor.mjs" GH_TOKEN="shared-box-token-not-a-real-one"
node "$CLI/src/index.js" run "$ROSTER" > "$ROOT/daemon.log" 2>&1 & DAEMON_PID=$!
for _ in $(seq 1 60); do curl -fs "http://127.0.0.1:$PORT/healthz" >/dev/null 2>&1 && break; sleep 0.2; done
curl -fs "http://127.0.0.1:$PORT/healthz" >/dev/null || { echo "daemon never came up"; cat "$ROOT/daemon.log"; exit 1; }
post() { curl -s -o "$ROOT/body.json" -w '%{http_code}' -X POST -H "x-epito-secret: $SECRET" -H 'content-type: application/json' --data "$2" "http://127.0.0.1:$PORT$1"; }
echo "  $(post /hooks/pm '{"marker":"identity"}') pm"
echo "  $(post /hooks/okr '{"marker":"identity"}') okr"
node "$CLI/test/wait-for.mjs" runs pm 1
node "$CLI/test/wait-for.mjs" runs okr 1

MINTED=$(grep '"agent":"pm","action":"token.mint"' .epito/audit.jsonl | tail -1)
echo "  $MINTED"
# The executor records a fingerprint of the credential it was handed, never
# the credential: compare hashes, not secrets.
fp() { node -e 'const{createHash}=require("node:crypto");console.log(createHash("sha256").update(process.argv[1]).digest("hex").slice(0,12))' "$1"; }
# Which transcript belongs to which agent: the prompt names it (the quotes
# are JSON-escaped in the file, so ask node rather than fight grep).
pick() { node -e '
  const fs = require("fs"), p = require("path");
  const [dir, name, marker] = process.argv.slice(1);
  for (const f of fs.readdirSync(dir)) {
    const file = p.join(dir, f);
    const lines = fs.readFileSync(file, "utf8").trim().split("\n").filter(Boolean).map(JSON.parse);
    if (lines.some((l) => l.prompt.includes(`named "${name}"`) && l.prompt.includes(marker))) { console.log(file); process.exit(0); }
  }
  process.exit(1);' "$STUB" "$1" "$2"; }
PM_RUN=$(pick pm '"marker":"identity"')
OKR_RUN=$(pick okr '"marker":"identity"')
sed 's/^/  pm run> /' <<<"$(node -e 'const j=JSON.parse(require("fs").readFileSync(process.argv[1],"utf8").trim());console.log(JSON.stringify({gh_token:j.gh_token,author:j.author,author_email:j.author_email}))' "$PM_RUN")"
sed 's/^/  okr run> /' <<<"$(node -e 'const j=JSON.parse(require("fs").readFileSync(process.argv[1],"utf8").trim());console.log(JSON.stringify({gh_token:j.gh_token,author:j.author,author_email:j.author_email}))' "$OKR_RUN")"

check "pm's run minted its own token before it cloned" "[ \$(grep -c '\"action\":\"token.mint\",\"trigger\":\"hook\"' .epito/audit.jsonl) = 1 ]"
check "the executor got the minted token, not the box's shared one" "grep -q '\"gh_token\":\"$(fp ghs_stubtoken_424242)\"' '$PM_RUN'"
check "GITHUB_TOKEN carries the same credential (gh reads either)" "grep -q '\"github_token\":\"$(fp ghs_stubtoken_424242)\"' '$PM_RUN'"
check "the minted token overrode GH_TOKEN from [runtime].env" "! grep -q '\"gh_token\":\"$(fp shared-box-token-not-a-real-one)\"' '$PM_RUN'"
check "and the run says so in its log" "grep -q 'has its own App principal' .epito/logs/pm/*.log"
check "pm commits as the bot GitHub links back to the App" "grep -q '\"author\":\"epito-pm\[bot\]\",\"author_email\":\"90210+epito-pm\[bot\]@users.noreply.github.com\"' '$PM_RUN'"
check "okr, with no principal, ran on the shared token exactly as before" "grep -q '\"gh_token\":\"$(fp shared-box-token-not-a-real-one)\"' '$OKR_RUN'"
check "okr commits under the v0 address, unchanged" "grep -q '\"author\":\"okr\",\"author_email\":\"okr@agents.epito.me\"' '$OKR_RUN'"
check "okr's log says which identity it ran on, without failing" "grep -q 'no App principal on this box for okr' .epito/logs/okr/*.log"
check "no token reached any log on disk" "! grep -rq 'ghs_stubtoken' .epito/logs/"
check "both runs finished cleanly" "[ \$(grep -c '\"action\":\"run.end\",\"trigger\":\"hook\",\"model\":\"claude-sonnet-5\",\"exit\":0' .epito/audit.jsonl) = 2 ]"

step "a principal that cannot mint refuses the run — it does not fall back"
kill "$API_PID" 2>/dev/null || true; sleep 0.4
echo "  $(post /hooks/pm '{"marker":"api-down"}') pm (API stub stopped)"
node "$CLI/test/wait-for.mjs" runs pm 2
check "the run ended as an identity failure" "grep -q '\"agent\":\"pm\",\"action\":\"run.end\",\"trigger\":\"hook\",\"model\":\"claude-sonnet-5\",\"exit\":\"identity\"' .epito/audit.jsonl"
check "the refusal is audited with its reason" "grep -q '\"action\":\"token.refused\"' .epito/audit.jsonl"
check "it never reached the executor" "! grep -rq 'api-down' \"$STUB\""
grep '"action":"token.refused"' .epito/audit.jsonl | tail -1 | cut -c1-240 | sed 's/^/  /'

step "audit trail"
sed 's/^/  /' .epito/audit.jsonl

printf '\n%s\n' "-----------------------------------------------"
printf 'identity smoke: %d ok, %d failed\n' "$pass" "$fail"
[ "$fail" = 0 ] || exit 1
