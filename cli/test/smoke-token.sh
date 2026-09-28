#!/usr/bin/env bash
# Smoke test for `epito token <name>` (cycle 1 bet 2, the identity slice).
# It spends no tokens, touches no network, and uses no real credential: the
# App key is an RSA keypair generated here and thrown away, "api.github.com"
# is test/github-sink.mjs on localhost, and the executor is the same stub the
# resident smoke uses.
#
#   bash test/smoke-token.sh             # from cli/
#
# It asserts, in order: a manifest mints a token scoped to exactly the
# permissions [identity].scopes maps to and to one repository; the App key can
# come from the environment or from .epito/apps/<name>.json, and a
# world-readable key file is refused; a scope with no GitHub permission behind
# it is refused by `epito validate` and by the mint, in the same words; an App
# that is not installed, and an installation narrower than the manifest, each
# fail with the fix in the message; the token never lands in the audit log; and
# a run of the resident runtime hands the agent that token — redacting it from
# the run log even when the agent echoes it.
set -euo pipefail

CLI="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT="${TMPDIR:-/tmp}/epito-token-smoke-$$"
ORIGIN="$ROOT/origin"; ROSTER="$ROOT/agents"; STATE="$ROOT/state"; STUB="$ROOT/stub"
GH_PORT="${EPITO_TEST_GH_PORT:-47481}"; PORT="${EPITO_TEST_PORT:-47482}"
SECRET="token-smoke-secret-not-a-real-one"
GH_LOG="$ROOT/github.jsonl"
pass=0; fail=0
ok()   { pass=$((pass+1)); printf '  ok   %s\n' "$1"; }
bad()  { fail=$((fail+1)); printf '  FAIL %s\n' "$1"; }
check(){ if eval "$2"; then ok "$1"; else bad "$1"; fi; }
# `epito <...> 2>&1 >/dev/null` into a file: the error strings are product
# prose full of quotes and parens, so they are grepped from disk and never
# interpolated into a shell word.
ERR="$ROOT/err.txt"
errs()  { : > "$ERR"; ( "$@" ) 2>> "$ERR" >/dev/null || true; sed 's/^/  /' "$ERR"; }
said()  { check "$1" "grep -qF \"$2\" \"$ERR\""; }
step() { printf '\n== %s\n' "$1"; }

cleanup() {
  [ -n "${DAEMON_PID:-}" ] && kill "$DAEMON_PID" 2>/dev/null || true
  [ -n "${GH_PID:-}" ] && kill "$GH_PID" 2>/dev/null || true
  sleep 0.4
  rm -rf "$ROOT"
}
trap cleanup EXIT

mkdir -p "$ORIGIN" "$ROSTER/pm" "$ROSTER/okr" "$ROSTER/stray" "$ROSTER/greedy" "$ROSTER/plain" "$STATE" "$STUB"

step "fixture: an RSA keypair standing in for the App's private key"
openssl genrsa -out "$ROOT/app.key" 2048 2>/dev/null
openssl rsa -in "$ROOT/app.key" -pubout -out "$ROOT/app.pub" 2>/dev/null
echo "  key: $ROOT/app.key (generated here, never leaves $ROOT)"

step "fixture: a local repo standing in for github.com/acme/roster"
seed="$ROOT/seed"; mkdir -p "$seed/prompts"
for a in pm okr stray greedy plain; do printf '# %s\n\nYou are %s. One run: open a draft PR.\n' "$a" "$a" > "$seed/prompts/$a.md"; done
git -c init.defaultBranch=main init -q "$seed"
git -C "$seed" add -A
git -C "$seed" -c user.name=smoke -c user.email=smoke@epito.me commit -qm charters
git clone -q --bare "$seed" "$ORIGIN/acme/roster.git"
export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0="url.file://$ORIGIN/.insteadOf" GIT_CONFIG_VALUE_0="https://github.com/"

# pm and okr ask for what the installation grants; greedy asks for issues,
# which it does not; stray's repository has no installation at all.
manifest() {
  cat > "$ROSTER/$1/agent.toml" <<TOML
[agent]
name = "$1"
description = "Smoke-test seat: the stub executor answers for it."

[identity]
scopes = [$2]

[trigger]
cron = "0 6 * * *"

[runtime]
model = "claude-sonnet-5"
entry = "prompts/$1.md"
repo = "$3"
max_turns = 5
env = ["EPITO_STUB_DIR", "EPITO_STUB_ECHO_TOKEN"]
TOML
}
manifest pm     '"github:contents", "github:pull_requests"' acme/roster
manifest okr    '"github:contents"'                         acme/roster
manifest stray  '"github:contents"'                         acme/unowned
manifest greedy '"github:contents", "github:issues"'        acme/roster
manifest plain  '"github:contents"'                         acme/roster

step "start: the github sink, granting contents+pull_requests and NOT issues"
node "$CLI/test/github-sink.mjs" "$GH_PORT" "$ROOT/app.pub" "$GH_LOG" \
  '{"contents":"write","pull_requests":"write","metadata":"read"}' & GH_PID=$!
for _ in $(seq 1 50); do curl -fs -o /dev/null "http://127.0.0.1:$GH_PORT/" && break; sleep 0.2; done
echo "  sink up on $GH_PORT"

cd "$STATE"
export EPITO_GITHUB_API="http://127.0.0.1:$GH_PORT"
epito() { node "$CLI/src/index.js" "$@"; }

step "no principal: an agent with no App says so, and says where it looked"
errs epito token pm --dir "$ROSTER"
said "refused, naming the environment it looked in" "EPITO_APP_ID_PM + EPITO_APP_KEY_PM"
said "and the file it looked for"                   ".epito/apps/pm.json"

step "half a principal: an id with no key is a mistake, not a fallback"
EPITO_APP_ID_PM=111 errs epito token pm --dir "$ROSTER"
said "refused, naming the missing half" "Set EPITO_APP_KEY_PM"

step "mint: pm, App key from the environment"
export EPITO_APP_ID_PM=111 EPITO_APP_KEY_PM="$(cat "$ROOT/app.key")"
tok=$(epito token pm --dir "$ROSTER" 2> "$ROOT/pm.err"); sed 's/^/  /' "$ROOT/pm.err"
check "a token came back on stdout" "[[ '$tok' == ghs_smoke_* ]]"
check "the summary names repo, permissions, expiry, installation" \
  "grep -q 'acme/roster' '$ROOT/pm.err' && grep -q 'contents:write' '$ROOT/pm.err' && grep -q 'pull_requests:write' '$ROOT/pm.err' && grep -q 'installation 424242' '$ROOT/pm.err'"
asked=$(grep access_tokens "$GH_LOG" | tail -1)
echo "  asked: $asked"
check "asked for exactly the mapped permissions, plus metadata:read" \
  "node -e 'const b=JSON.parse(process.argv[1]).body; const p=b.permissions; process.exit(JSON.stringify(Object.keys(p).sort())===JSON.stringify([\"contents\",\"metadata\",\"pull_requests\"]) && p.contents===\"write\" && p.pull_requests===\"write\" && p.metadata===\"read\" ? 0 : 1)' \"\$asked\""
check "scoped to the one repository the manifest names" \
  "node -e 'const b=JSON.parse(process.argv[1]).body; process.exit(JSON.stringify(b.repositories)===JSON.stringify([\"roster\"])?0:1)' \"\$asked\""
check "the App JWT verified against the App key" "grep -q '\"jwt\":\"ok\"' '$GH_LOG'"

step "the audit line records the mint and not the token"
sed 's/^/  /' .epito/audit.jsonl
check "one token.mint line for pm" "[ \$(grep -c '\"action\":\"token.mint\"' .epito/audit.jsonl) = 1 ]"
check "it names scopes, permissions, installation and expiry" \
  "grep -q '\"permissions\":\"contents:write, metadata:read, pull_requests:write\"' .epito/audit.jsonl && grep -q '\"installation\":424242' .epito/audit.jsonl"
check "the token itself is nowhere in the audit log" "! grep -q '$tok' .epito/audit.jsonl"

step "mint: okr, App key from .epito/apps/okr.json"
mkdir -p .epito/apps
node -e 'const fs=require("fs");fs.writeFileSync(".epito/apps/okr.json",JSON.stringify({app_id:222,private_key:fs.readFileSync(process.argv[1],"utf8")}))' "$ROOT/app.key"
chmod 644 .epito/apps/okr.json
errs epito token okr --dir "$ROSTER"
said "a world-readable key file is refused, with the chmod in the message" "chmod 600 .epito/apps/okr.json"
chmod 600 .epito/apps/okr.json
tok2=$(epito token okr --dir "$ROSTER" 2> "$ROOT/okr.err"); sed 's/^/  /' "$ROOT/okr.err"
check "the file route mints" "[[ '$tok2' == ghs_smoke_* ]]"
check "and asks only for what okr declares" \
  "node -e 'const b=JSON.parse(process.argv[1]).body; process.exit(JSON.stringify(Object.keys(b.permissions).sort())===JSON.stringify([\"contents\",\"metadata\"])?0:1)' \"\$(grep access_tokens '$GH_LOG' | tail -1)\""
check "the two tokens are different credentials" "[ '$tok' != '$tok2' ]"

step "base64 is an accepted form of the key (what an EnvironmentFile can hold)"
tok3=$(EPITO_APP_KEY_PM="$(base64 -w0 < "$ROOT/app.key")" epito token pm --dir "$ROSTER" 2>/dev/null)
check "base64 PEM mints" "[[ '$tok3' == ghs_smoke_* ]]"
EPITO_APP_KEY_PM="not-a-key" errs epito token pm --dir "$ROSTER"
said "a non-key says what a key looks like" "BEGIN RSA PRIVATE KEY"
said "and where to get one"                 "Developer settings"

step "the App is not installed on the repository the manifest names"
EPITO_APP_ID_STRAY=111 EPITO_APP_KEY_STRAY="$(cat "$ROOT/app.key")" errs epito token stray --dir "$ROSTER"
said "404 becomes the repository's own name, not 'Not Found'" "not installed on acme/unowned"
said "and the fix is where to click"                          "Install App"

step "the manifest is the ceiling, not the floor: an installation that grants less"
EPITO_APP_ID_GREEDY=111 EPITO_APP_KEY_GREEDY="$(cat "$ROOT/app.key")" errs epito token greedy --dir "$ROSTER"
said "422 names the permission that was refused" "issues:write"
said "and both ways out"                         "narrow [identity].scopes"
check "the refusal is audited too" "grep -q '\"action\":\"token.refused\"' .epito/audit.jsonl"

step "a scope with no GitHub permission behind it: validate and the mint agree"
mkdir -p "$ROOT/unmapped/prompts"
printf '# x\n' > "$ROOT/unmapped/prompts/x.md"
cat > "$ROOT/unmapped/agent.toml" <<'TOML'
[agent]
name = "x"
description = "Declares a scope epito cannot map."

[identity]
scopes = ["github:contents", "github:packages"]

[trigger]
cron = "0 6 * * *"

[runtime]
model = "claude-sonnet-5"
entry = "prompts/x.md"
repo = "acme/roster"
TOML
: > "$ERR"; (cd "$ROOT/unmapped" && node "$CLI/src/index.js" validate) >> "$ERR" 2>&1 || true; sed 's/^/  /' "$ERR"
said "validate refuses it"          "names no GitHub permission"
said "and lists what it does map"   "github:pull_requests"
EPITO_APP_ID_X=111 EPITO_APP_KEY_X="$(cat "$ROOT/app.key")" errs epito token x --dir "$ROOT/unmapped"
said "the mint refuses it in the same words" "names no GitHub permission"

step "an unknown name lists the roster it looked in"
errs epito token nobody --dir "$ROSTER"
said "named the roster" "this roster: greedy, okr, plain, pm, stray"

step "the run gets the token: epitod mints before it clones"
before=$(grep -c access_tokens "$GH_LOG")
export EPITO_HOOK_SECRET="$SECRET" EPITO_PORT="$PORT" EPITO_STUB_DIR="$STUB" \
       EPITO_EXECUTOR="$CLI/test/stub-executor.mjs" EPITO_STUB_ECHO_TOKEN=1
# okr keeps its file-based principal; pm keeps its env one; stray and greedy
# leave the roster for this part so the daemon's runs are the two that mint.
rm -rf "$ROSTER/stray" "$ROSTER/greedy"
node "$CLI/src/index.js" run "$ROSTER" > "$ROOT/daemon.log" 2>&1 & DAEMON_PID=$!
for _ in $(seq 1 50); do curl -fs "http://127.0.0.1:$PORT/healthz" >/dev/null 2>&1 && break; sleep 0.2; done
curl -fs "http://127.0.0.1:$PORT/healthz" >/dev/null || { echo "daemon never came up"; cat "$ROOT/daemon.log"; exit 1; }
curl -s -o /dev/null -X POST -H "x-epito-secret: $SECRET" -H 'content-type: application/json' \
  --data '{}' "http://127.0.0.1:$PORT/hooks/pm"
node "$CLI/test/wait-for.mjs" runs pm 1

after=$(grep -c access_tokens "$GH_LOG")
check "the run minted its own token" "[ \$((after - before)) = 1 ]"
runtok=$(node -e 'const j=JSON.parse(process.argv[1]);process.stdout.write(j.body.token??"")' "$(grep access_tokens "$GH_LOG" | tail -1)" 2>/dev/null || true)
seen=$(node -e '
const fs=require("fs"),p=require("path");
const d=process.argv[1];
for (const f of fs.readdirSync(d)) for (const l of fs.readFileSync(p.join(d,f),"utf8").trim().split("\n"))
  { const o=JSON.parse(l); if (o.env?.GH_TOKEN) { process.stdout.write(o.env.GH_TOKEN); process.exit(0); } }
' "$STUB")
echo "  the agent's process saw GH_TOKEN=${seen:0:14}…"
check "the child was handed a minted token as GH_TOKEN" "[[ '$seen' == ghs_smoke_* ]]"
check "and GITHUB_TOKEN with it" "node -e 'const fs=require(\"fs\"),p=require(\"path\");const d=process.argv[1];let ok=false;for(const f of fs.readdirSync(d))for(const l of fs.readFileSync(p.join(d,f),\"utf8\").trim().split(\"\n\")){const o=JSON.parse(l);if(o.env?.GITHUB_TOKEN===o.env?.GH_TOKEN&&o.env?.GH_TOKEN)ok=true;}process.exit(ok?0:1)' '$STUB'"
check "and the git credential helper that turns it into a push" \
  "node -e 'const fs=require(\"fs\"),p=require(\"path\");const d=process.argv[1];let ok=false;for(const f of fs.readdirSync(d))for(const l of fs.readFileSync(p.join(d,f),\"utf8\").trim().split(\"\n\")){const o=JSON.parse(l);if((o.env?.names??[]).includes(\"GIT_CONFIG_COUNT\"))ok=true;}process.exit(ok?0:1)' '$STUB'"

step "the run log names the identity and redacts the credential"
runlog=$(ls -t .epito/logs/pm/*.log | head -1)
grep -E '^# (identity|epito run)' "$runlog" | sed 's/^/  /'
check "the log says which installation the run worked as" "grep -q '# identity: pm as installation 424242' '$runlog'"
check "the agent echoed its token and the log shows a redaction" "grep -q 'my token is \*\*\*epito-token\*\*\*' '$runlog'"
check "the token is not in the log" "[ -z '$runtok' ] || ! grep -q '$runtok' '$runlog'"
check "nor anywhere under .epito/" "[ -z '$runtok' ] || ! grep -rq '$runtok' .epito/"

step "an agent with no principal runs exactly as it did before this slice"
curl -s -o /dev/null -X POST -H "x-epito-secret: $SECRET" -H 'content-type: application/json' \
  --data '{}' "http://127.0.0.1:$PORT/hooks/plain"
node "$CLI/test/wait-for.mjs" runs plain 1
plainlog=$(ls -t .epito/logs/plain/*.log | head -1)
grep '^# identity' "$plainlog" | sed 's/^/  /'
check "the run succeeded"                       "grep -q '\"agent\":\"plain\",\"action\":\"run.end\",\"trigger\":\"hook\",\"model\":\"claude-sonnet-5\",\"exit\":0' .epito/audit.jsonl"
check "it minted nothing"                       "! grep -q '\"agent\":\"plain\",\"action\":\"token' .epito/audit.jsonl"
check "and the log states the fallback plainly" "grep -q 'no principal for plain' '$plainlog'"
check "so the child got no GH_TOKEN" \
  "node -e 'const fs=require(\"fs\"),p=require(\"path\");const d=process.argv[1];let bad=false;for(const f of fs.readdirSync(d))for(const l of fs.readFileSync(p.join(d,f),\"utf8\").trim().split(\"\n\")){const o=JSON.parse(l);if(/named \"plain\"/.test(o.prompt)&&o.env?.GH_TOKEN)bad=true;}process.exit(bad?1:0)' '$STUB'"

step "audit trail"
sed 's/^/  /' .epito/audit.jsonl

printf '\n%s\n' "-----------------------------------------------"
printf 'smoke: %d ok, %d failed\n' "$pass" "$fail"
[ "$fail" = 0 ] || exit 1
