#!/usr/bin/env bash
# Smoke test for `epito deploy` — the provisioning half of the identity leg
# (docs/pitches/deploy-identity-v0.md, backlog card "`epito deploy` v0").
#
#   bash test/smoke-deploy.sh            # from cli/
#
# It spends nothing, creates nothing on GitHub, and touches no account: the
# RSA App key is generated here and dies with the temp directory, and
# "api.github.com" is test/github-stub.mjs — the same stub the mint is tested
# against, now also answering POST /app-manifests/<code>/conversions. The
# browser is curl, which is honest: the browser's entire job in this flow is
# to GET one page and come back to one loopback URL.
#
# What it proves, in the order the operator lives it:
#
#   1. DRY RUN says what it would create, and touches nothing
#   2. it REFUSES BEFORE THE BROWSER — a scope with no mapping, a manifest
#      that does not validate, a missing [runtime].repo, an ambiguous roster
#   3. the CREATE path: the page is pre-filled from the manifest, a callback
#      with the wrong state is refused, the right one writes a 0600 key and a
#      principal record, and .gitignore learns about .epito/
#   4. an App installed NOWHERE says so, and says where to install it
#   5. DEPLOY TWICE updates one principal (spec rule 4) — no second App
#   6. and then `epito token` MINTS from what deploy wrote, which is the only
#      assertion that proves the two commands agree about where a key lives
#   7. and `epito audit` READS BACK the ledger those two just wrote — the only
#      assertion that proves the writer and the reader agree about the shape of
#      a line, which no unit test over a hand-written fixture can prove
set -uo pipefail

CLI="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT="${TMPDIR:-/tmp}/epito-deploy-smoke-$$"
WORK="$ROOT/work"; ALT="$ROOT/roster"
DPORT="${EPITO_TEST_DEPLOY_PORT:-47481}"
GH_PORT="${EPITO_TEST_GITHUB_PORT2:-47482}"
GH_LOG="$ROOT/github-requests.jsonl"
STUB_TOKEN="ghs_STUBTOKEN0000000000000000000000000000"
E="node $CLI/src/index.js"

pass=0; fail=0
ok()   { pass=$((pass+1)); printf '  ok   %s\n' "$1"; }
bad()  { fail=$((fail+1)); printf '  FAIL %s\n' "$1"; }
check(){ if eval "$2"; then ok "$1"; else bad "$1"; fi; }
audit(){ label="$1"; shift; if (cd "$WORK" && node "$CLI/test/audit-has.mjs" "$@") >/dev/null 2>&1; then ok "$label"; else bad "$label"; (cd "$WORK" && node "$CLI/test/audit-has.mjs" "$@") 2>&1 | sed 's/^/       /'; fi; }
step() { printf '\n== %s\n' "$1"; }

cleanup() {
  for pid in ${GH_PID:-} ${DEPLOY_PID:-}; do kill "$pid" 2>/dev/null; done
  if [ -n "${EPITO_SMOKE_KEEP:-}" ]; then printf '\nkept for inspection: %s\n' "$ROOT"; else rm -rf "$ROOT"; fi
}
trap cleanup EXIT

start_stub() { # mode
  node "$CLI/test/github-stub.mjs" "$GH_PORT" "$ROOT/app.pub.pem" "$GH_LOG" "$1" "$ROOT/app.pem" > "$ROOT/github-stub.log" 2>&1 &
  GH_PID=$!
  for _ in $(seq 1 60); do grep -q "github-stub on $GH_PORT" "$ROOT/github-stub.log" && return 0; sleep 0.2; done
  echo "the stand-in GitHub API never came up"; cat "$ROOT/github-stub.log"; exit 1
}
stop_stub() { kill "${GH_PID:-}" 2>/dev/null; wait "${GH_PID:-}" 2>/dev/null; GH_PID=""; }

mkdir -p "$WORK" "$ALT"

step "fixture: an agent, and one throwaway RSA key standing in for the App's"
# Generated here and thrown away with $ROOT: nothing personal ever enters a
# fixture (the engineer charter's rule). The stub hands the private half back
# from the conversion and verifies every later JWT against the public half, so
# the key deploy writes is checked by the same code path a real mint uses.
node -e '
const { generateKeyPairSync } = require("node:crypto"); const { writeFileSync } = require("node:fs");
const { privateKey, publicKey } = generateKeyPairSync("rsa", { modulusLength: 2048 });
writeFileSync(process.argv[1], privateKey.export({ type: "pkcs1", format: "pem" }));
writeFileSync(process.argv[2], publicKey.export({ type: "spki", format: "pem" }));
' "$ROOT/app.pem" "$ROOT/app.pub.pem"
(cd "$WORK" && $E init acme-bot >/dev/null)
python3 - "$WORK/agent.toml" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read().replace('[runtime]\n', '[runtime]\nrepo = "acme/roster"\n')
open(p, "w").write(s)
PY
check "the fixture manifest validates" "(cd '$WORK' && $E validate) | grep -q '✓ acme-bot is an agent'"

step "1. --dry-run: what it would create, without a browser and without a network"
DRY="$(cd "$WORK" && EPITO_GITHUB_API="http://127.0.0.1:1" $E deploy --dry-run 2>&1)"; rc=$?
printf '%s\n' "$DRY" | sed 's/^/     | /'
check "dry run exits 0 with nothing listening anywhere" "[ $rc = 0 ]"
check "it names the App it would create (name + owner, GitHub's 34-char cap)" "printf '%s' \"\$DRY\" | grep -q 'App name:    acme-bot-acme'"
check "the permissions come from the scopes, not from a form" "printf '%s' \"\$DRY\" | grep -q 'permissions: contents:write, pull_requests:write'"
check "it says where the key would land, and that it would be 0600" "printf '%s' \"\$DRY\" | grep -q '.epito/keys/acme-bot.pem (0600)'"
check "it prints the exact manifest it would hand GitHub" "printf '%s' \"\$DRY\" | grep -q '\"default_permissions\"'"
check "an App with no principal yet says so" "printf '%s' \"\$DRY\" | grep -q 'no principal for \"acme-bot\" on this machine yet'"
check "and it wrote no key" "[ ! -e '$WORK/.epito/keys/acme-bot.pem' ]"

step "2. the refusals that happen before a human is sent to a browser"
cp "$WORK/agent.toml" "$ROOT/agent.toml.good"
sed 's/"github:pull_requests"/"github:packages"/' "$ROOT/agent.toml.good" > "$WORK/agent.toml"
OUT="$(cd "$WORK" && $E deploy 2>&1)"; rc=$?
printf '%s\n' "$OUT" | sed 's/^/     | /'
check "a scope with no mapping refuses, exit 1" "[ $rc = 1 ]"
check "  and names the scope, the mapped set, and the fix" "printf '%s' \"\$OUT\" | grep -q '\"github:packages\"' && printf '%s' \"\$OUT\" | grep -q 'Fix: remove the scope'"

sed '/^model = /d' "$ROOT/agent.toml.good" > "$WORK/agent.toml"
OUT="$(cd "$WORK" && $E deploy 2>&1)"; rc=$?
check "a manifest that does not validate deploys nothing, exit 1" "[ $rc = 1 ]"
check "  and says why a broken manifest cannot make a principal" "printf '%s' \"\$OUT\" | grep -q 'an invalid manifest deploys nothing'"

sed '/^repo = /d' "$ROOT/agent.toml.good" > "$WORK/agent.toml"
OUT="$(cd "$WORK" && $E deploy 2>&1)"; rc=$?
check "no [runtime].repo refuses: an App is installed on a repository" "[ $rc = 1 ] && printf '%s' \"\$OUT\" | grep -q '\\[runtime\\].repo is required to deploy'"

cp "$ROOT/agent.toml.good" "$WORK/agent.toml"
mkdir -p "$ALT/one" "$ALT/two"
sed 's/^name = "acme-bot"/name = "one"/' "$ROOT/agent.toml.good" > "$ALT/one/agent.toml"
sed 's/^name = "acme-bot"/name = "two"/' "$ROOT/agent.toml.good" > "$ALT/two/agent.toml"
OUT="$(cd "$WORK" && $E deploy "" "$ALT" 2>&1)"; rc=$?
check "two manifests and no name refuses rather than guessing" "[ $rc = 1 ] && printf '%s' \"\$OUT\" | grep -q 'one manifest, one principal'"
check "  and names both, and the command that disambiguates" "printf '%s' \"\$OUT\" | grep -q 'one, two' && printf '%s' \"\$OUT\" | grep -q 'epito deploy <name>'"
OUT="$(cd "$WORK" && $E deploy nobody "$ALT" 2>&1)"; rc=$?
check "a name that is in no manifest refuses and reads out the roster" "[ $rc = 1 ] && printf '%s' \"\$OUT\" | grep -q 'the roster there is: one, two'"

step "3. the create path: one page, one callback, two files"
start_stub "not-installed"
ok "the stand-in GitHub API is up ($(head -1 "$ROOT/github-stub.log"))"
# An agent.toml can arrive at deploy without ever having been through `epito
# init` — written by hand, or older than the directory. Deploy is about to put
# a private key next to it, so this asserts the case where nothing has told the
# repo about .epito/ yet.
rm -f "$WORK/.gitignore"
(cd "$WORK" && EPITO_GITHUB_API="http://127.0.0.1:$GH_PORT" $E deploy --no-open --port "$DPORT" > "$ROOT/deploy1.log" 2>&1) &
DEPLOY_PID=$!
for _ in $(seq 1 100); do grep -q "waiting up to" "$ROOT/deploy1.log" && break; sleep 0.1; done
check "deploy is waiting, and said so with the URL to open" "grep -q 'http://127.0.0.1:$DPORT/' '$ROOT/deploy1.log'"
check "  it named the App and the permissions before sending anyone anywhere" "grep -q 'permissions: contents:write, pull_requests:write' '$ROOT/deploy1.log'"

curl -sS "http://127.0.0.1:$DPORT/" > "$ROOT/page.html"
STATE="$(sed -n 's/.*settings\/apps\/new?state=\([0-9a-f]*\)".*/\1/p' "$ROOT/page.html" | head -1)"
check "the page posts to GitHub's App-creation form, with a state" "[ ${#STATE} = 64 ]"
check "  pre-filled from the manifest: the permissions are in the form" "grep -q 'default_permissions' '$ROOT/page.html' && grep -q 'pull_requests' '$ROOT/page.html'"
check "  and the redirect comes back to this deploy's own loopback port" "grep -q 'redirect_url&quot;:&quot;http://127.0.0.1:$DPORT/callback' '$ROOT/page.html'"
check "  the App declares no webhook: it is an identity, not a subscription" "grep -q 'default_events&quot;:\[\]' '$ROOT/page.html' && ! grep -q 'hook_attributes' '$ROOT/page.html'"

CODE="$(curl -sS -o "$ROOT/wrong.html" -w '%{http_code}' "http://127.0.0.1:$DPORT/callback?code=abc123&state=deadbeef")"
check "a callback with the wrong state is refused (403), not obeyed" "[ '$CODE' = 403 ]"
check "  and says what was refused and that nothing was created" "grep -q 'state does not match' '$ROOT/wrong.html'"
check "  and the deploy is still waiting for the real one" "kill -0 $DEPLOY_PID 2>/dev/null"
check "  nothing was written by the refused callback" "[ ! -e '$WORK/.epito/keys/acme-bot.pem' ]"

curl -sS "http://127.0.0.1:$DPORT/callback?code=abc123&state=$STATE" > "$ROOT/done.html"
for _ in $(seq 1 100); do kill -0 $DEPLOY_PID 2>/dev/null || break; sleep 0.1; done
wait $DEPLOY_PID; rc=$?
DEPLOY_PID=""
sed 's/^/     | /' "$ROOT/deploy1.log"
check "the real callback completes the deploy, exit 0" "[ $rc = 0 ]"
check "the browser is told the App exists and where its key is" "grep -q 'Its key is on your machine' '$ROOT/done.html'"
check "the key landed at .epito/keys/acme-bot.pem" "[ -f '$WORK/.epito/keys/acme-bot.pem' ]"
check "  0600, because it IS the agent's identity" "[ \"\$(ls -l '$WORK/.epito/keys/acme-bot.pem' | cut -c1-10)\" = '-rw-------' ]"
check "  and it is byte-for-byte the key GitHub handed back" "diff -q '$ROOT/app.pem' '$WORK/.epito/keys/acme-bot.pem' >/dev/null"
check "the record names the App and holds no secret" "grep -q '\"externalId\": \"707070\"' '$WORK/.epito/principals.json' && ! grep -q 'PRIVATE KEY' '$WORK/.epito/principals.json'"
check "deploy taught .gitignore about .epito/ — a key just landed in this repo" "grep -q '^.epito/$' '$WORK/.gitignore'"
check "no token or key is anywhere in what deploy printed" "! grep -qi 'PRIVATE KEY\|client_secret' '$ROOT/deploy1.log'"
audit "the deploy is in the ledger: created, with its scopes and permissions" '{"agent":"acme-bot","action":"deploy","created":true,"appId":"707070","permissions":{"contents":"write","pull_requests":"write"}}'

step "4. an App installed nowhere says so, and says where to install it"
check "it does not pretend the agent can act yet" "grep -q 'has an identity but nowhere to act yet' '$ROOT/deploy1.log'"
check "  and gives the install URL for the repo the MANIFEST names" "grep -q 'install it on acme/roster:  https://github.com/apps/epito-seat-707070/installations/new' '$ROOT/deploy1.log'"
check "  and the next command, which is this same one" "grep -q 'epito deploy acme-bot.* again' '$ROOT/deploy1.log'"
check "  the ledger records the installation as absent, not as a guess" "(cd '$WORK' && node '$CLI/test/audit-has.mjs' '{\"action\":\"deploy\",\"installation\":null}')"

step "5. deploy twice updates one principal — spec rule 4, and the bug that would be a second App"
stop_stub
start_stub "ok"   # the human has now installed it, so the lookup answers
OUT="$(cd "$WORK" && EPITO_GITHUB_API="http://127.0.0.1:$GH_PORT" $E deploy 2>&1)"; rc=$?
printf '%s\n' "$OUT" | sed 's/^/     | /'
check "the second deploy exits 0" "[ $rc = 0 ]"
check "  and says plainly that it is updating, not creating" "printf '%s' \"\$OUT\" | grep -q 'it does not create a second'"
check "  it never opened a listener or asked for a browser" "! printf '%s' \"\$OUT\" | grep -q 'click Create'"
check "  exactly ONE App was ever converted, across both deploys" "[ \"\$(grep -c 'conversions' '$GH_LOG')\" = 1 ]"
check "  still one principal on this machine" "[ \"\$(node -e 'console.log(JSON.parse(require(\"fs\").readFileSync(\"$WORK/.epito/principals.json\")).principals.length)')\" = 1 ]"
check "  and it now records the installation, against the repo it is for" "grep -q '\"installationId\": \"4242\"' '$WORK/.epito/principals.json' && grep -q '\"repo\": \"acme/roster\"' '$WORK/.epito/principals.json'"
audit "the ledger has a second deploy line, created:false" '{"agent":"acme-bot","action":"deploy","created":false,"installation":"4242"}'

step "6. and then the mint: \`epito token\` uses exactly what deploy wrote"
TOK="$(cd "$WORK" && EPITO_GITHUB_API="http://127.0.0.1:$GH_PORT" $E token acme-bot 2>"$ROOT/token.err")"; rc=$?
sed 's/^/     | /' "$ROOT/token.err"
check "the mint succeeds against the deployed principal, exit 0" "[ $rc = 0 ]"
check "  stdout is the token and nothing else" "[ '$TOK' = '$STUB_TOKEN' ]"
check "  signed with the key deploy wrote — the stub verified the signature" "grep -q '\"jwtOk\":true' '$GH_LOG'"
check "  and epito found the principal in the file, not in the environment" "grep -q 'minted for acme-bot' '$ROOT/token.err'"
audit "the mint is in the same ledger as the deploy that made it possible" '{"agent":"acme-bot","action":"mint","repo":"acme/roster","installation":"4242"}'

step "7. \`epito audit\`: the ledger those two commands just wrote, read back"
# Every assertion above this point used test/audit-has.mjs, which reads the
# file with its own parser. This section reads it with the PRODUCT's, which is
# the only way to find out that the writer and the reader disagree about the
# shape of a line — the failure a unit test over a hand-written fixture cannot
# have, because the fixture was written by the same hand as the assertion.
LEDGER="$(cd "$WORK" && $E audit 2>&1)"; rc=$?
printf '%s\n' "$LEDGER" | sed 's/^/     | /'
check "it reads the real ledger, exit 0" "[ $rc = 0 ]"
check "  the seat has a row" "printf '%s' \"\$LEDGER\" | grep -q '^acme-bot'"
check "  2 deploys and 1 mint, counted" "printf '%s' \"\$LEDGER\" | grep -qE '^acme-bot +1 +2 '"
check "  the App id deploy created" "printf '%s' \"\$LEDGER\" | grep -q '707070'"
check "  the repo the manifest named" "printf '%s' \"\$LEDGER\" | grep -q 'acme/roster'"
check "  what the token was actually allowed to do" "printf '%s' \"\$LEDGER\" | grep -q 'contents:write, pull_requests:write'"
check "  the mint sentence says until when" "printf '%s' \"\$LEDGER\" | grep -qE 'mint .*installation 4242, expires [0-9]{2}:[0-9]{2}Z'"
check "  and the deploy that was not a second App" "printf '%s' \"\$LEDGER\" | grep -q 'recorded App 707070'"
# The assertion this command exists to be trusted on. The mint above returned a
# real (stub) token on stdout one step ago; the ledger it wrote must not contain
# it, and the reader must not print it. If this ever fails, `epito audit` is a
# credential leak with columns.
check "NO TOKEN in the ledger's output — not the one just minted" "! printf '%s' \"\$LEDGER\" | grep -q '$STUB_TOKEN'"
check "  nor any private key material" "! printf '%s' \"\$LEDGER\" | grep -qi 'PRIVATE KEY'"
check "  and the file itself never held the token either" "! grep -q '$STUB_TOKEN' '$WORK/.epito/audit.jsonl'"

check "--action mint shows the mint and says what it left out" \
  "(cd '$WORK' && $E audit --action mint) | grep -qE '1 of [0-9]+ lines'"
check "--action deploy counts both deploys" \
  "[ \"\$(cd '$WORK' && $E audit --action deploy --limit 0 | grep -c 'App 707070')\" = 2 ]"
check "--agent on a seat that is not in the ledger says so, exit 0" \
  "(cd '$WORK' && $E audit --agent nobody) | grep -q 'none of them this'"
check "--since 1h still has today's lines" "(cd '$WORK' && $E audit --since 1h) | grep -q 'acme-bot'"
check "--since 1970-01-01 has all of them" \
  "[ \"\$(cd '$WORK' && $E audit --since 1970-01-01 --limit 0 --json | node -e 'let s=\"\";process.stdin.on(\"data\",d=>s+=d).on(\"end\",()=>console.log(JSON.parse(s).matched))')\" = \"\$(grep -c . '$WORK/.epito/audit.jsonl')\" ]"
check "--json is machine-readable and names the path it read" \
  "(cd '$WORK' && $E audit --json) | node -e 'let s=\"\";process.stdin.on(\"data\",d=>s+=d).on(\"end\",()=>{const j=JSON.parse(s);if(j.path!==\".epito/audit.jsonl\")process.exit(1);if(!j.seats.length)process.exit(1)})'"

# A line written by a NEWER epito than the one reading it. Appended to the real
# ledger on purpose: the rule is that the reader must never hide a line, and
# the way that rule breaks is a future action silently vanishing.
printf '%s\n' '{"ts":"2026-10-02T23:59:00.000Z","agent":"acme-bot","action":"quota.exhausted","window":"5h"}' >> "$WORK/.epito/audit.jsonl"
printf '%s\n' '{"ts":"2026-10-02T23:59:01.000Z","agent":"acme-bot","action":"trunca' >> "$WORK/.epito/audit.jsonl"
FUTURE="$(cd "$WORK" && $E audit 2>&1)"
check "an action this epito never heard of still prints, with its fields" \
  "printf '%s' \"\$FUTURE\" | grep -q 'quota.exhausted  window=5h'"
check "a half-written line is counted, not fatal and not silent" \
  "printf '%s' \"\$FUTURE\" | grep -q '1 line in .epito/audit.jsonl could not be read as JSON and was skipped'"

check "a misspelled option is refused, not dropped" \
  "(cd '$WORK' && $E audit --agnet acme-bot 2>&1; [ \$? = 1 ]) | grep -q 'Did you mean --agent'"
check "an action nothing ever writes is refused with the list" \
  "(cd '$WORK' && $E audit --action mintt 2>&1; [ \$? = 1 ]) | grep -q 'nothing in the ledger is a \"mintt\"'"
check "a --since it cannot parse is refused with the forms" \
  "(cd '$WORK' && $E audit --since yesterday 2>&1; [ \$? = 1 ]) | grep -q 'It takes a window'"
check "no ledger in this directory is not an error — it says where one is written" \
  "(cd '$ALT' && $E audit) | grep -q 'it is written where the work happens'"

printf '\nsmoke: %d ok, %d failed\n' "$pass" "$fail"
[ "$fail" = 0 ] || exit 1
