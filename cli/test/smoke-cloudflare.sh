#!/usr/bin/env bash
# Smoke test for `epito deploy --target cloudflare` — the owner's ask of
# 2026-10-18: one manifest, one agent on Cloudflare, with its own identity, a
# schedule that fires, state that survives, and a page with a button.
#
#   bash test/smoke-cloudflare.sh            # from cli/
#
# It spends nothing and touches no account. Two sections:
#
#   1. THE COMMAND, always. What it writes, what it refuses, and the two
#      properties a generated bundle has to have — byte-identical for the
#      same manifest (rule 4), and carrying no secret VALUE (rule 1).
#
#   2. THE WORKER IN WORKERD, when wrangler is here. The bundle is deployed
#      into a real local Workers runtime and driven end to end against one
#      stub standing in for GitHub and the model: the door refuses, the page
#      renders, the button mints the agent's own token and records a run, the
#      schedule fires the same run, and the runs survive the runtime being
#      killed and restarted. `test/prereqs.sh` installs wrangler; without it
#      this section says SKIPPED and the unit suite's fake-Durable-Object
#      harness (test/unit-cloudflare.mjs) is what covers the same ground.
set -uo pipefail

CLI="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT="${TMPDIR:-/tmp}/epito-cf-smoke-$$"
SEAT="$CLI/test/fixtures/cloudflare/edge-demo"
PORT="${EPITO_TEST_CF_PORT:-48791}"
STUB_PORT="${EPITO_TEST_CF_STUB_PORT:-48792}"
STUB_STARTS=0
INSPECT="${EPITO_TEST_CF_INSPECTOR_PORT:-48793}"
KEY="door-key-for-this-smoke-test"
E="node $CLI/src/index.js"

pass=0; fail=0
ok()   { pass=$((pass+1)); printf '  ok   %s\n' "$1"; }
bad()  { fail=$((fail+1)); printf '  FAIL %s\n' "$1"; }
check(){ if eval "$2"; then ok "$1"; else bad "$1"; fi; }
# The substring test happens in this shell, not down a pipe. `printf | grep -qF`
# forks twice per assertion, and when either half of that pipeline cannot run,
# its non-zero status is indistinguishable from "the string is not there" — so
# the harness reports a defect in the product it never actually looked for.
# That is not hypothetical: inside test/all.sh on 2026-10-23 this suite failed
# "the page names the agent and its description" (needle `edge-demo`) and
# passed, two lines later and against the same captured page, "the page carries
# the button" (needle `Run edge-demo now`) — which contains the needle that had
# just been declared missing. Run on its own the same suite was 54/54 twice.
# A quoted pattern inside `case` is a literal substring match with no
# subprocess at all: no dash is an option, no `*` or `[` in a needle is a glob,
# and there is nothing transient left to mistake for an absence. (L-A34: an
# absence is a reading, and this harness now only reports the one it took.)
has()  { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1" ;; esac; }
hasnt(){ case "$2" in *"$3"*) bad "$1" ;; *) ok "$1" ;; esac; }
step() { printf '\n== %s\n' "$1"; }

cleanup() {
  for pid in ${DEV_PID:-} ${STUB_PID:-}; do kill "$pid" 2>/dev/null; wait "$pid" 2>/dev/null; done
  if [ -n "${EPITO_SMOKE_KEEP:-}" ]; then printf '\nkept for inspection: %s\n' "$ROOT"; else rm -rf "$ROOT"; fi
}
trap cleanup EXIT
mkdir -p "$ROOT"

# ---------------------------------------------------------------------------
step "1. --dry-run says what it would deploy, and writes nothing"
# ---------------------------------------------------------------------------
cd "$ROOT"
DRY="$($E deploy edge-demo "$SEAT" --target cloudflare --out "$ROOT/bundle" --dry-run 2>&1)"
has "it names the Worker it would create"                   "$DRY" "epito-edge-demo"
has "it names the schedule, and says where it came from"    "$DRY" "*/5 * * * * (UTC), from [trigger].cron"
has "it names the state that survives"                      "$DRY" "Durable Object"
has "it names the page and the button"                      "$DRY" "a button that triggers it"
has "it names the identity it would mint with"              "$DRY" "its own GitHub App, minting github:contents on acme/edge-demo"
has "it lists the secrets by NAME, never a value"           "$DRY" "names only, never values"
has "it says plainly that nothing happened"                 "$DRY" "no account was touched"
check "and nothing was written"                        '[ ! -d "$ROOT/bundle" ]' 

# ---------------------------------------------------------------------------
step "2. what it refuses, before it writes anything"
# ---------------------------------------------------------------------------
# Whole manifests, not edits to one: a seat that cannot go to the edge is a
# different seat, and appending a line to the fixture lands it in whichever
# table happens to be last.
seat() { # dir, extra [runtime] lines, extra tables
  mkdir -p "$ROOT/$1"
  cat > "$ROOT/$1/agent.toml" <<EOF
[agent]
name = "$1"
description = "A seat written for one assertion in test/smoke-cloudflare.sh."

[identity]
scopes = ["github:contents"]

[trigger]
cron = "0 6 * * *"
webhook = true

[runtime]
model = "claude-sonnet-5"
entry = "prompts/$1.md"
${2:-repo = "acme/$1"}
EOF
}

seat lg-seat 'repo = "acme/lg"
adapter = "langgraph"
graph = "agent"'
LG="$($E deploy lg-seat "$ROOT/lg-seat" --target cloudflare --out "$ROOT/lgout" 2>&1)"
has "a langgraph seat is refused: a Worker spawns no processes"  "$LG" "spawns no processes"
has "  and is told which runtime does run it"                    "$LG" "deploy this seat to the resident runtime"
check "  and nothing was written"                                '[ ! -d "$ROOT/lgout" ]'

seat norepo 'max_turns = 10'
# With no repo AND no charter on disk, `epito validate` refuses first and the
# Cloudflare-specific rule never gets a turn. The charter here makes this an
# ordinary Actions-era manifest — valid, and still not deployable to an edge
# that reads its charter out of a repository.
mkdir -p "$ROOT/norepo/prompts" && printf '# norepo\n' > "$ROOT/norepo/prompts/norepo.md"
NR="$($E deploy norepo "$ROOT/norepo" --target cloudflare --out "$ROOT/nrout" 2>&1)"
has "no [runtime].repo is refused, because the charter is read out of it"  "$NR" "[runtime].repo is required"
has "  with the fix in the message"                                        "$NR" 'Fix: add repo = "owner/name"'
check "  and nothing was written"                                          '[ ! -d "$ROOT/nrout" ]'

BT="$($E deploy edge-demo "$SEAT" --target fly 2>&1)"
has "an unknown --target names the two that exist"  "$BT" '--target takes "github" or "cloudflare"'
has "  and shows the command for each"              "$BT" "epito deploy edge-demo --target cloudflare"
UO="$($E deploy edge-demo "$SEAT" --targett cloudflare 2>&1)"
has "a misspelled option is refused rather than dropped"  "$UO" "targett"

# ---------------------------------------------------------------------------
step "3. the bundle it writes"
# ---------------------------------------------------------------------------
OUT="$($E deploy edge-demo "$SEAT" --target cloudflare --out "$ROOT/bundle" 2>&1)"
for f in wrangler.jsonc agent.js worker.mjs README.md; do
  check "it wrote $f" "[ -s '$ROOT/bundle/$f' ]"
done
check "the config is JSON a tool can read"            'node -e "JSON.parse(require(\"fs\").readFileSync(\"$ROOT/bundle/wrangler.jsonc\",\"utf8\"))"'
check "the schedule in it is the one the manifest wrote, verbatim" 'node -e "const c=JSON.parse(require(\"fs\").readFileSync(\"$ROOT/bundle/wrangler.jsonc\",\"utf8\")); process.exit(c.triggers.crons[0]===\"*/5 * * * *\"?0:1)"'
check "it declares the Durable Object the worker binds" 'node -e "const c=JSON.parse(require(\"fs\").readFileSync(\"$ROOT/bundle/wrangler.jsonc\",\"utf8\")); process.exit(c.durable_objects.bindings[0].name===\"RUNS\"&&c.migrations[0].new_sqlite_classes[0]===\"AgentRuns\"?0:1)"'
check "the permissions compiled in are the manifests scopes, mapped" 'grep -q "\"contents\": \"write\"" "$ROOT/bundle/agent.js"' 
has "the output names the one command that belongs to the operator"   "$OUT" "npx wrangler deploy"
has "  and says why that one is not epitos to run"                    "$OUT" "spends your Cloudflare account"
has "  and gives the link to send, with the door key on it"           "$OUT" "workers.dev/?key="
has "the ledger recorded the pack"                                    "$($E audit --action deploy 2>/dev/null)" "epito-edge-demo"

# Rule 1, asserted on the bytes: the generator runs in a process holding both
# of this seat's secrets and must reach for neither.
STUB_BASE_URL="https://gateway.invalid.example/anthropic" STUB_API_KEY="sk-NOTAREALKEY" \
  $E deploy edge-demo "$SEAT" --target cloudflare --out "$ROOT/bundle2" >/dev/null 2>&1
check "no secret VALUE reached a generated file -- rule 1 survives generation" \
  '! grep -rqF -e "NOTAREALKEY" -e "gateway.invalid.example" "$ROOT/bundle2"'
check "but the NAMES are all there, or nobody knows what to set" \
  'grep -qF "STUB_API_KEY" "$ROOT/bundle2/README.md" && grep -qF "STUB_BASE_URL" "$ROOT/bundle2/README.md"'
check "the same manifest packs byte-identically twice -- rule 4, one agent" \
  'diff -r "$ROOT/bundle" "$ROOT/bundle2" >/dev/null'

# ---------------------------------------------------------------------------
step "4. the worker, in a real Workers runtime"
# ---------------------------------------------------------------------------
# Resolve wrangler without installing one: $EPITO_WRANGLER, then the prereqs
# cache, then PATH, then this checkout's node_modules. `npx wrangler` is
# deliberately NOT in that list — a suite that silently downloads 100 MB mid-run
# is a suite that fails differently on a plane.
WRANGLER=""
for candidate in \
  "${EPITO_WRANGLER:-}" \
  "${EPITO_PREREQS_DIR:-${TMPDIR:-/tmp}/epito-prereqs}/wrangler/node_modules/.bin/wrangler" \
  "$(command -v wrangler 2>/dev/null)" \
  "$CLI/node_modules/.bin/wrangler"; do
  [ -n "$candidate" ] && [ -x "$candidate" ] && { WRANGLER="$candidate"; break; }
done

if [ -z "$WRANGLER" ]; then
  cat <<EOF
  SKIPPED — no wrangler on this machine, so the bundle was never put in front of
  the runtime it is for. Nothing in this section was asserted.

    bash test/prereqs.sh        # installs it beside the Temporal CLI
    bash test/all.sh --with-prereqs

  What still ran: the generator above, and test/unit-cloudflare.mjs, which
  imports this same worker.mjs and drives it against a fake Durable Object.
EOF
else
  printf '  using %s (%s)\n' "$WRANGLER" "$("$WRANGLER" --version 2>&1 | tail -1)"
  cp -r "$ROOT/bundle" "$ROOT/dev"
  node -e '
    const { generateKeyPairSync } = require("node:crypto"); const fs = require("node:fs");
    // Thrown away with $ROOT. Nothing personal enters a fixture.
    const { privateKey, publicKey } = generateKeyPairSync("rsa", { modulusLength: 2048,
      publicKeyEncoding: { type: "spki", format: "pem" }, privateKeyEncoding: { type: "pkcs8", format: "pem" } });
    fs.writeFileSync(process.argv[2], publicKey);
    fs.writeFileSync(process.argv[1], [
      `EPITO_TRIGGER_SECRET=${JSON.stringify(process.argv[3])}`,
      `EPITO_APP_ID="1234567"`,
      `EPITO_APP_KEY=${JSON.stringify(privateKey)}`,
      `EPITO_GITHUB_API="http://127.0.0.1:${process.argv[4]}"`,
      `STUB_BASE_URL="http://127.0.0.1:${process.argv[4]}"`,
      `STUB_API_KEY="sk-stub-TESTONLY"`, "",
    ].join("\n"));
  ' "$ROOT/dev/.dev.vars" "$ROOT/app.pub.pem" "$KEY" "$STUB_PORT"

  # The log is named for the START, not for the stub. The wait below greps it
  # for the listening line, and `>` truncates in the forked child while the
  # grep runs in the parent: under one fixed name, a second start reads the
  # line the first one wrote and leaves the loop before anything is bound.
  # One start today, so this is the latent half of test/shapes.sh's second
  # scan -- the name is what keeps the second start honest rather than a note
  # asking whoever adds it to remember.
  STUB_STARTS=$((STUB_STARTS+1)); STUB_LOG="$ROOT/stub-$STUB_STARTS.log"
  STUB_APP_PUBLIC_KEY="$(cat "$ROOT/app.pub.pem")" \
    node "$CLI/test/cloudflare-stub.mjs" "$STUB_PORT" > "$STUB_LOG" 2>&1 &
  STUB_PID=$!
  for _ in $(seq 1 50); do grep -q "on http://127.0.0.1:$STUB_PORT" "$STUB_LOG" 2>/dev/null && break; sleep 0.2; done

  start_dev() {
    (cd "$ROOT/dev" && "$WRANGLER" dev --port "$PORT" --inspector-port "$INSPECT" > "$ROOT/wrangler.log" 2>&1 &)
    for _ in $(seq 1 120); do
      curl -s -o /dev/null "http://127.0.0.1:$PORT/" 2>/dev/null && return 0
      sleep 0.5
    done
    return 1
  }
  stop_dev() { pkill -f "dev --port $PORT" 2>/dev/null; sleep 2; }

  if ! start_dev; then
    bad "wrangler dev never came up on $PORT"
    tail -15 "$ROOT/wrangler.log" | sed 's/^/       /'
  else
    ok "the generated bundle boots in workerd with no edits"

    check "a request with no key is refused 401, naming the link form" \
      '[ "$(curl -s -o /dev/null -w %{http_code} "http://127.0.0.1:'"$PORT"'/")" = 401 ]'
    check "a request with the wrong key is refused 403" \
      '[ "$(curl -s -o /dev/null -w %{http_code} "http://127.0.0.1:'"$PORT"'/?key=nope")" = 403 ]'
    check "the header form opens the same door as the link form" \
      '[ "$(curl -s -o /dev/null -w %{http_code} -H "x-epito-secret: '"$KEY"'" "http://127.0.0.1:'"$PORT"'/")" = 200 ]'

    PAGE="$(curl -s "http://127.0.0.1:$PORT/?key=$KEY")"
    has "the page names the agent and its description"     "$PAGE" "edge-demo"
    has "the page says it has never run, before it has"    "$PAGE" "never run here"
    has "the page carries the button"                      "$PAGE" "Run edge-demo now"

    CODE="$(curl -s -o "$ROOT/post.out" -w %{http_code} -X POST -H 'accept: text/html' "http://127.0.0.1:$PORT/runs?key=$KEY")"
    check "pressing the button sends a browser back to the page"  '[ "'"$CODE"'" = 303 ]'
    sleep 1
    check "the agent signed a JWT as its OWN App, and it verified"  'grep -q "JWT verifies as App 1234567" "$STUB_LOG"'
    check "  for no longer than GitHub allows"                      'grep -q "600s long" "$STUB_LOG"'
    check "  and asked for exactly the manifests scopes, on exactly its repo" \
      'grep -qF "asked for {\"contents\":\"write\"} on [\"edge-demo\"]" "$STUB_LOG"' 
    check "it read its charter with the MINTED token, not with the JWT" \
      'grep -q "with the minted installation token" "$STUB_LOG"'
    check "and the charter is what reached the model"               'grep -q "charter arrived" "$STUB_LOG"'

    AFTER="$(curl -s "http://127.0.0.1:$PORT/?key=$KEY")"
    has   "the page now shows the run, and that it succeeded"  "$AFTER" ">ok<"
    has   "  what the agent actually said"                     "$AFTER" "The one thing that moved"
    has   "  and that one turn is one turn, against the cap the manifest declares" "$AFTER" "1 of 20"
    hasnt "no minted token reaches the page"                   "$AFTER" "ghs_"
    hasnt "no model key reaches the page"                      "$AFTER" "sk-stub"

    curl -s -o /dev/null "http://127.0.0.1:$PORT/cdn-cgi/local/scheduled?cron=*/5+*+*+*+*"
    sleep 1
    SCHED="$(curl -s "http://127.0.0.1:$PORT/api/state?key=$KEY")"
    has "the schedule fires the same run the button does"  "$SCHED" '"trigger": "cron"'
    has "  and the store counted both"                     "$SCHED" '"count": 2' 

    stop_dev
    if start_dev; then
      SURVIVED="$(curl -s "http://127.0.0.1:$PORT/?key=$KEY")"
      has "state survives the runtime dying: the runs are still there" "$SURVIVED" "2 total"
      has "  including what the agent said on the first one"           "$SURVIVED" "The one thing that moved"
    else
      bad "wrangler dev did not come back up for the state-survives check"
    fi
    stop_dev
  fi
fi

printf '\nsmoke: %d ok, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ] || exit 1
