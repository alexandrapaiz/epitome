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

# Directories only: the roster directory also holds agents/README.md, and a
# plain `ls` made this suite assert that README.md has an agent.toml. A glob
# rather than `find -printf`, which is GNU-only and this repository's other
# suites run on macOS too.
SEATS=""
for d in "$AGENTS"/*/; do [ -d "$d" ] || continue; SEATS="$SEATS$(basename "$d") "; done
[ -n "${SEATS// /}" ] || { echo "smoke: SKIPPED — agents/ holds no seat directories"; exit 0; }

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
# `sed -i` with no suffix is GNU-only: BSD sed reads the next argument as the
# backup suffix and the file as the script, and says `invalid command code f`.
# Every in-place edit in this harness uses the one form both accept.
sed -i.bak 's|repo = "acme/other"|repo = "acme/unrelated"|' "$TMP/repo/agents/ghost/agent.toml" \
  && rm -f "$TMP/repo/agents/ghost/agent.toml.bak"
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
# What this step needs is a server ANSWERING, which is not what the guard used
# to ask. It asked whether the `temporal` CLI was on PATH — so installing the
# prerequisite the skip notice names, without then starting a server, turned
# this suite from honestly `partial` into `FAILED` on a codebase that was
# fine: four assertions about a plan that was never printed, because `epito
# run` had already refused with "no Temporal server answering at
# 127.0.0.1:7233". A harness that cannot claim more than it proved must not
# claim a failure it did not see either. One TCP connect, no new dependency,
# and it reads TEMPORAL_ADDRESS the same way `epito run` does.
engine_answers() {
  node -e '
    const net = require("node:net");
    const at = (process.env.TEMPORAL_ADDRESS || "127.0.0.1:7233").split(":");
    const s = net.connect({ host: at[0], port: Number(at[1] || 7233) });
    const no = () => { s.destroy(); process.exit(1); };
    s.setTimeout(2000);
    s.on("connect", () => { s.destroy(); process.exit(0); });
    s.on("error", no);
    s.on("timeout", no);
  ' >/dev/null 2>&1
}
if ! engine_answers; then
  echo "  == 4: SKIPPED — no engine to plan against: nothing is answering at ${TEMPORAL_ADDRESS:-127.0.0.1:7233}"
  echo "     install it (curl -sSf https://temporal.download/cli.sh | sh) and run \`temporal server start-dev\`"
else
  # A copy, because the assertion is about what a dry run WRITES and the real
  # directory is a git checkout somebody is working in.
  cp -r "$AGENTS" "$TMP/agents"
  dout="$(cd "$TMP" && $E run agents --dry-run 2>&1)"; drc=$?
  check "the dry run exits 0 (it used to exit 1: unknown command \"run\")" "[ $drc -eq 0 ]"
  check "it does NOT print the unknown-command error" "! printf '%s' \"\$dout\" | grep -q 'unknown command'"
  # Every cron'd seat is accounted for, as a create OR as already-registered.
  # This used to demand four "would create" lines, which quietly assumed the
  # engine at TEMPORAL_ADDRESS was empty. It is not empty anywhere this matters:
  # on the company host epitod holds this very roster, so the suite reported
  # FAILED for a correct product -- found 2026-10-06 running it right after
  # `epito run agents` against a live engine. "Planned" is the property; which
  # side of the diff a seat lands on is the engine's state, not the roster's.
  planned=$(printf '%s' "$dout" | grep -c 'would create seat:')
  settled=$(printf '%s' "$dout" | grep -oE '[0-9]+ unchanged' | grep -oE '[0-9]+' | tail -1)
  check "it plans a schedule for every seat with a cron (created ${planned:-0} + already registered ${settled:-0} = 4)" "[ \$(( ${planned:-0} + ${settled:-0} )) -eq 4 ]"
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

step "6. the roster has one command that says yes, and it needs no engine"
# Step 1 above is what an operator had to do before this existed: a shell loop,
# one `cd` per seat. This is the same question asked once. It is the half of
# dogfood step 1 that does not need the box — "is my roster good" answered
# without a Temporal server, which `epito run agents --dry-run` in step 4
# cannot do (it connects first, which is why step 4 is inside a skip guard and
# this is not).
#
# The engine half of the verdict depends on this box, so it is asserted against
# this box, both ways. `engine_answers` above is this suite's OWN probe and
# stays that way: checking the command's engine line with the command's engine
# probe would assert that a function agrees with itself.
vout="$($E validate "$AGENTS" 2>"$TMP/validate.err")"; vrc=$?
verr="$(cat "$TMP/validate.err")"
check "epito validate agents exits 0 on the real roster" "[ $vrc -eq 0 ]"
check "it says nothing on stderr when the roster is clean" "[ -z \"\$verr\" ]"
# This used to assert the output never said "temporal" or "7233", which read as
# "no engine required" and was the reason the ✓ below could claim `epito run`
# would refuse nothing on a box where `epito run` refused in one line. The
# invariant worth holding is that it ANSWERS, in full, whatever the box is
# doing — the counts and the per-seat lines below are that assertion, and they
# run unconditionally.
check "it answers whether or not this box has an engine" "[ $vrc -eq 0 ]"
nseats=$(printf '%s ' $SEATS | wc -w | tr -d ' ')
check "it counts every seat in agents/" "printf '%s' \"\$vout\" | grep -q '$nseats of $nseats manifests are agents'"
for s in $SEATS; do
  # `(✓|!)`, not `[✓!]`: a bracket expression holding a multibyte character is
  # matched byte by byte by BSD grep and by any grep in a non-UTF-8 locale, so
  # the three bytes of ✓ could never be the one character the class asks for.
  # Alternation compares the same bytes either way.
  check "it reports $s by name" "printf '%s\n' \"\$vout\" | grep -qE '^(✓|!) $s +identity'"
done
check "it names the presence-only seat as presence-only" "printf '%s' \"\$vout\" | grep -q 'presence-only (exo)'"
# The claim the strict gate makes: it asks exactly what `epito run <dir>` asks.
# `epito run` asks about the engine FIRST — before it reads a manifest — so the
# gate has to, and the verdict differs by box. Both branches are assertions;
# neither is a skip, because whichever box this is, the command has a right
# answer for it.
svout="$($E validate "$AGENTS" --for-runtime 2>&1)"; svrc=$?
check "...and reports the same seats under --for-runtime" "printf '%s' \"\$svout\" | grep -q '$nseats of $nseats manifests are agents'"
if engine_answers; then
  check "with an engine up, it says run would refuse nothing here" "printf '%s' \"\$vout\" | grep -q 'nothing here .epito run'"
  check "...and names the engine it looked at" "printf '%s' \"\$vout\" | grep -q \"${TEMPORAL_ADDRESS:-127.0.0.1:7233} is answering\""
  check "...and the strict gate passes on the real roster too" "[ $svrc -eq 0 ]"
else
  # The case every previous run of this suite was in, and the one the ✓ got
  # wrong: five good manifests, no engine, and a tick that spoke for `epito
  # run` without asking it. Step 4 above skipped for exactly this reason, four
  # steps earlier, in the same run.
  check "with no engine, it does not claim run would refuse nothing" "! printf '%s' \"\$vout\" | grep -q 'nothing here .epito run .* would refuse'"
  check "...it says the manifests are ready and the engine is not" "printf '%s' \"\$vout\" | grep -q 'every manifest is ready; the engine is not'"
  check "...and carries the fix for the half that is missing" "printf '%s' \"\$vout\" | grep -q 'temporal server start-dev'"
  check "...and the strict gate refuses, because \`epito run\` would" "[ $svrc -eq 1 ]"
  check "...naming the engine and not the files as the problem" "printf '%s' \"\$svout\" | grep -q 'The manifests are not the problem'"
fi
# Each seat reads identically whether asked one at a time or as a roster. The
# single-manifest wording is the wording that already shipped, so this is the
# acceptance test for factoring `epito validate` out of src/index.js.
for s in $SEATS; do
  single="$(cd "$AGENTS/$s" && $E validate 2>&1 | sed -n "s/^✓ $s is an agent: //p")"
  fromroster="$(printf '%s\n' "$vout" | sed -n "s/^✓ $s  *//p")"
  check "$s reads the same one-at-a-time as in the roster" "[ -n \"\$single\" ] && [ \"\$single\" = \"\$fromroster\" ]"
done
check "validate created no .epito/ in the repository" "[ ! -e '$ROOT/.epito' ]"
# agents/README.md is in that directory and is not a seat. findManifests looks
# for the filename, so it cannot be fooled — but the count above is what would
# have caught it, and this suite has already been bitten once by `ls`.
check "the roster count ignores agents/README.md" "[ -f '$AGENTS/README.md' ] && printf '%s' \"\$vout\" | grep -q '$nseats of $nseats manifests'"

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
