#!/usr/bin/env bash
# Smoke test for THIS repository's own roster — agents/<seat>/agent.toml, the
# five seats epito.me actually runs (backlog card "dogfood migration, step 1").
#
#   bash test/smoke-roster.sh            # from cli/
#
# Every other suite runs against fixtures this repository wrote to be run
# against. This one runs against the real thing, and that is the entire point:
# the three frozen shapes in test/fixtures/shapes are synthetic, they live
# beside the manifest they name, and all three were written by the same people
# who wrote the validator. The company's own roster is none of those — its
# manifests sit in subdirectories, its charters sit at the repository root,
# and the values in it were decided in YAML a year of runs ago. Pointing the
# product at it is how the three bugs in this branch's first commit were
# found, and this suite is what keeps them found.
#
# It spends nothing and touches no account. Temporal is the only prerequisite
# it cannot stand in for (`epito run` talks to the engine before it decides
# anything), so without it the roster assertions that need an engine skip and
# say so, and the rest still run.
#
# What it proves:
#
#   1. every manifest in agents/ is a valid v0.1 manifest, and the strict gate
#      (`--for-runtime`) passes too: nothing in the real roster relies on the
#      validator's permissive half
#   2. the ✓ is CLEAN — no note telling a seat to commit a charter that is
#      already committed (the roster layout bug), and the note still fires for
#      a charter that really is absent
#   3. the roster loads WHOLE: `epito routes` names all five, and the names,
#      models and max_turns match the workflow each was translated from
#   4. `epito run agents --dry-run` plans four schedules and one presence-only
#      seat, EXITS 0, and writes NOTHING — not to the engine, not to the ledger
#   5. `epito token` and `epito deploy` agree with the manifests about scopes,
#      and refuse cleanly with no identity on the machine
set -uo pipefail

CLI="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT="$(cd "$CLI/.." && pwd)"
AGENTS="$ROOT/agents"
TMP="${TMPDIR:-/tmp}/epito-roster-smoke-$$"
E="node $CLI/src/index.js"

pass=0; fail=0
ok()   { pass=$((pass+1)); printf '  ok   %s\n' "$1"; }
bad()  { fail=$((fail+1)); printf '  FAIL %s\n' "$1"; }
check(){ if eval "$2"; then ok "$1"; else bad "$1"; fi; }
step() { printf '\n== %s\n' "$1"; }
cleanup() { if [ -n "${EPITO_SMOKE_KEEP:-}" ]; then printf '\nkept: %s\n' "$TMP"; else rm -rf "$TMP"; fi; }
trap cleanup EXIT
mkdir -p "$TMP"

if [ ! -d "$AGENTS" ]; then
  echo "smoke: SKIPPED — there is no agents/ directory in this checkout, so there is no roster to run"
  exit 0
fi

SEATS="$(ls "$AGENTS" | sort | tr '\n' ' ')"

step "1. every seat in the real roster is a valid v0.1 manifest, strictly"
for s in $SEATS; do
  [ -f "$AGENTS/$s/agent.toml" ] || { bad "$s has an agent.toml"; continue; }
  out="$(cd "$AGENTS/$s" && $E validate 2>&1)"; rc=$?
  check "$s validates (exit 0)" "[ $rc -eq 0 ]"
  check "$s is an agent, not a skill" "printf '%s' \"\$(printf '%s' '$out')\" | grep -q '✓ $s is an agent'"
  sout="$(cd "$AGENTS/$s" && $E validate --for-runtime 2>&1)"; src=$?
  check "$s passes the strict gate --for-runtime" "[ $src -eq 0 ]"
  [ -n "$sout" ] || true
done

step "2. the ✓ is clean: no note about a charter that IS committed"
for s in $SEATS; do
  out="$(cd "$AGENTS/$s" && $E validate 2>&1)"
  # The bug this replaces: `entry` is a path inside `repo`, the manifest is in
  # agents/<seat>/, and the charter is at the repository root — so the note
  # fired on all five correctly configured seats.
  check "$s: validate says nothing about committing its charter" "! printf '%s' \"\$out\" | grep -q 'before the first run'"
  entry="$(grep -E '^entry' "$AGENTS/$s/agent.toml" | sed -E 's/.*\"(.*)\".*/\1/')"
  check "$s: and its charter $entry really is in this repository" "[ -f '$ROOT/$entry' ]"
done

step "2b. and the note still fires for a charter that really is absent"
# Same shape as a roster seat — manifest in a subdirectory, charter named at
# the repository root — except the charter was never committed. If this stops
# firing, the fix above has become a blindfold.
mkdir -p "$TMP/repo/agents/ghost" && (cd "$TMP/repo" && git init -q . && git remote add origin https://github.com/acme/other.git)
cat > "$TMP/repo/agents/ghost/agent.toml" <<'EOF'
[agent]
name = "ghost"
description = "A seat whose charter was never committed."
[identity]
scopes = ["github:contents"]
[trigger]
cron = "0 6 * * *"
[runtime]
model = "claude-sonnet-5"
entry = "prompts/ghost.md"
repo = "acme/other"
EOF
gout="$(cd "$TMP/repo/agents/ghost" && $E validate 2>&1)"
check "a charter absent from the whole repo is still named" "printf '%s' \"\$gout\" | grep -q 'commit prompts/ghost.md to acme/other'"
mkdir -p "$TMP/repo/prompts" && echo charter > "$TMP/repo/prompts/ghost.md"
gout2="$(cd "$TMP/repo/agents/ghost" && $E validate 2>&1)"
check "committing it at the repo root silences the note" "! printf '%s' \"\$gout2\" | grep -q 'before the first run'"
sed -i 's|repo = "acme/other"|repo = "acme/unrelated"|' "$TMP/repo/agents/ghost/agent.toml"
gout3="$(cd "$TMP/repo/agents/ghost" && $E validate 2>&1)"
check "a charter in a repo the manifest does NOT name is not evidence" "printf '%s' \"\$gout3\" | grep -q 'commit prompts/ghost.md to acme/unrelated'"

step "3. the roster loads whole, and matches the workflows it came from"
rout="$($E routes "$AGENTS" 2>&1)"; rrc=$?
check "epito routes reads the whole roster (exit 0)" "[ $rrc -eq 0 ]"
for s in $SEATS; do
  check "routes names $s" "printf '%s' \"\$rout\" | grep -q '^$s '"
done
# Translation fidelity: the model and the turn cap in each manifest are the
# ones its workflow passes to --model / --max-turns. A manifest that drifted
# from the workflow it replaces is a dogfood that proves nothing.
wf() { grep -o -- "--max-turns [0-9]*" "$ROOT/.github/workflows/agent-$1.yml" | head -1 | awk '{print $2}'; }
for s in $SEATS; do
  w="$(wf "$s")"; m="$(grep -E '^max_turns' "$AGENTS/$s/agent.toml" | grep -o '[0-9]*' || true)"
  if [ -n "$w" ]; then check "$s max_turns=$m matches its workflow's --max-turns $w" "[ \"$m\" = \"$w\" ]"; fi
done
check "the engineer's two workflow crons are one expression here" "grep -q '46 11,23 \* \* \*' '$AGENTS/engineer/agent.toml'"
check "exo has no cron (its workflow's schedule block is commented out)" "! grep -qE '^cron' '$AGENTS/exo/agent.toml'"
check "exo is still triggerable: webhook = true" "grep -q 'webhook = true' '$AGENTS/exo/agent.toml'"

step "4. epito run agents --dry-run: plans, exits 0, writes nothing"
if ! command -v temporal >/dev/null 2>&1 && [ -z "${TEMPORAL_ADDRESS:-}" ]; then
  echo "  == 4: SKIPPED — no engine to plan against: the \`temporal\` CLI is not on PATH and TEMPORAL_ADDRESS is unset"
  echo "     install it (curl -sSf https://temporal.download/cli.sh | sh) and run \`temporal server start-dev\`"
else
  # A copy, because the assertion is about what a dry run WRITES and the real
  # directory is a git checkout somebody is working in.
  cp -r "$AGENTS" "$TMP/agents"
  dout="$(cd "$TMP" && $E run agents --dry-run 2>&1)"; drc=$?
  check "the dry run exits 0 (it used to exit 1: unknown command \"run\")" "[ $drc -eq 0 ]"
  check "it does NOT print the unknown-command error" "! printf '%s' \"\$dout\" | grep -q 'unknown command'"
  check "it plans a schedule for every seat with a cron" "[ \"\$(printf '%s' \"\$dout\" | grep -c 'would create seat:')\" = 4 ]"
  check "and names the presence-only seat instead of silently skipping it" "printf '%s' \"\$dout\" | grep -q 'presence-only (no \[trigger\].cron, so no schedule): exo'"
  check "it says in words that it wrote nothing" "printf '%s' \"\$dout\" | grep -q 'dry run: nothing was registered'"
  # The bug: four `schedule.create` lines in an append-only ledger, for four
  # schedules that were never created. Nothing can correct that file.
  check "no ledger was written by a dry run" "[ ! -e '$TMP/.epito/audit.jsonl' ]"
  check "no .epito/ at all was created by a dry run" "[ ! -d '$TMP/.epito' ]"
fi

step "5. token and deploy agree with the manifests, and refuse cleanly"
tout="$(cd "$TMP" && $E token pm "$AGENTS/pm" --dry-run 2>&1)"; trc=$?
check "token --dry-run on the real pm manifest exits 0" "[ $trc -eq 0 ]"
check "it maps the pm seat's three scopes, issues included" "printf '%s' \"\$tout\" | grep -q 'issues: write'"
check "and says there is no App on this machine rather than inventing one" "printf '%s' \"\$tout\" | grep -q 'no App on this machine yet'"
check "the other seats do not get issues: write" "! (cd '$TMP' && $E token market '$AGENTS/market' --dry-run 2>&1) | grep -q 'issues: write'"
pout="$(cd "$TMP" && $E deploy pm "$AGENTS/pm" --dry-run 2>&1)"; prc=$?
check "deploy --dry-run on the real pm manifest exits 0" "[ $prc -eq 0 ]"
check "it would install on the repository the manifest names" "printf '%s' \"\$pout\" | grep -q 'installed on alexandrapaiz/epitome'"
check "the App name is derived from the manifest, not invented" "printf '%s' \"\$pout\" | grep -q 'pm-alexandrapaiz'"
check "deploy wrote no ledger either, being a dry run" "[ ! -e '$TMP/.epito/audit.jsonl' ]"

step "rule 1: nothing personal in the roster"
# The manifests are published with the repository. A credential in one would
# be a leak, and `epito validate`'s tripwires only know three shapes.
check "no private key material anywhere in agents/" "! grep -rqE 'BEGIN [A-Z ]*PRIVATE KEY' '$AGENTS'"
check "no github token shapes" "! grep -rqE 'gh[pousr]_[A-Za-z0-9]{20,}' '$AGENTS'"
check "no api key shapes" "! grep -rqE 'sk-[A-Za-z0-9_-]{20,}|AKIA[0-9A-Z]{16}' '$AGENTS'"

# The "smoke:" prefix is what test/all.sh greps for to tally a suite
# (run_suite in test/all.sh); without it this suite reports "nothing asserted".
printf '\nsmoke: %d ok, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
