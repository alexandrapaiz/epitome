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
#   1. every manifest in agents/ is a valid manifest against the current spec,
#      and the strict gate
#      (`--for-runtime`) passes too: nothing in the real roster relies on the
#      validator's permissive half
#   2. the ✓ is CLEAN — no note telling a seat to commit a charter that is
#      already committed (the roster layout bug), and the note still fires for
#      a charter that really is absent
#   3. the roster loads WHOLE: `epito routes` names all five, and the names,
#      models, max_turns and ROUTE CHAINS match the workflow each was
#      translated from — including that the endpoint a seat holds as a secret
#      is read back by name and never printed
#   4. `epito run agents --dry-run` plans four schedules and one presence-only
#      seat, EXITS 0, and writes NOTHING — not to the engine, not to the ledger
#   5. `epito token` and `epito deploy` agree with the manifests about scopes,
#      and refuse cleanly with no identity on the machine
#   6. `epito validate agents` is the one command that says yes with no engine
#   7. `epito env agents` says what this roster asks of the BOX — every name,
#      who asks for it, which of them are here — and the three things a box
#      can be doing about a name, including the one that refuses
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

# The repository's own .epito/, as it stood before this suite ran a command.
#
# Three assertions below say that a read-only command wrote nothing into the
# checkout, and they used to say it as `[ ! -e "$ROOT/.epito" ]` — which is a
# fact about the box, not about the command. Anybody who has ever run `epito
# worker`, `epito ps` or `epito report` from the repository root has that
# directory, and it is gitignored, so `git status` does not show it to them.
# On that box this suite printed three failures naming `epito validate`, `epito
# env` and `epito doctor` for a directory none of them touched. It cost an
# engineer run on 2026-10-12 the time to work out that the red was the box
# talking — the same false-failure class as the locale note in test/all.sh, and
# the same answer: measure what the assertion means. It means this command did
# not write here.
epito_fingerprint() {
  [ -e "$ROOT/.epito" ] || { echo absent; return 0; }
  find "$ROOT/.epito" -print 2>/dev/null | sort | while IFS= read -r f; do
    if [ -f "$f" ]; then printf '%s %s\n' "$f" "$(wc -c <"$f" | tr -d ' ')"; else printf '%s dir\n' "$f"; fi
  done
}
EPITO_BEFORE="$(epito_fingerprint)"
untouched() { [ "$(epito_fingerprint)" = "$EPITO_BEFORE" ]; }
if [ "$EPITO_BEFORE" = absent ]; then
  WROTE_NOTHING="wrote no .epito/ into the repository"
else
  WROTE_NOTHING="left the .epito/ this checkout already had exactly as it was"
  printf 'note: this checkout already has a .epito/ (something was run from %s by hand).\n' "$ROOT"
  printf '      The three "wrote nothing into the repository" assertions below therefore\n'
  printf '      assert it is UNCHANGED rather than absent, which is what they mean.\n'
fi

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

step "1. every seat in the real roster is a valid manifest, strictly"
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
# The open road, which is the one thing this roster could not express until
# spec v0.2 (agents/README.md, "the open road"). A seat whose workflow has an
# open-routed step must declare the chain, and a seat whose workflow has none
# must not have invented one — the asymmetry is the translation, and a dogfood
# that drifted from the YAML it replaces proves nothing.
for s in $SEATS; do
  wf="$ROOT/.github/workflows/agent-$s.yml"
  [ -f "$wf" ] || continue
  if grep -q 'ANTHROPIC_BASE_URL' "$wf"; then
    check "$s declares the open road its workflow takes" \
      "grep -q 'base_url_env = \"OPENROUTE_BASE_URL\"' '$AGENTS/$s/agent.toml'"
    check "$s names the key, not the key's value" \
      "grep -q 'token_env = \"OPENROUTE_API_KEY\"' '$AGENTS/$s/agent.toml'"
    check "$s injects both names, so both can resolve on a box" \
      "grep -E '^env =' '$AGENTS/$s/agent.toml' | grep -q 'OPENROUTE_BASE_URL' && grep -E '^env =' '$AGENTS/$s/agent.toml' | grep -q 'OPENROUTE_API_KEY'"
    wfmodel="$(grep -o "OPENROUTE_MODEL || '[^']*'" "$wf" | head -1 | sed "s/.*'\(.*\)'/\1/")"
    if [ -n "$wfmodel" ]; then
      check "$s's open road is the model its workflow defaults to ($wfmodel)" \
        "grep -q 'model = \"$wfmodel\"' '$AGENTS/$s/agent.toml'"
    fi
    check "$s keeps the subscription under it as the floor" \
      "grep -q 'name = \"subscription\"' '$AGENTS/$s/agent.toml'"
  else
    check "$s declares no route chain, because its workflow has no second road" \
      "! grep -q 'runtime.route' '$AGENTS/$s/agent.toml'"
  fi
done

# The promise of naming an endpoint instead of writing it: the command that
# reads the roster back on a box prints the NAME even when the box holds the
# value. If this ever prints the URL, the field bought nothing.
#
# Written with plain if/then rather than `check`, because these conditions grep
# for a literal `$OPENROUTE_BASE_URL` and `check` evals its argument — a `$` in
# an eval'd string is a variable, and under `set -u` the first draft of this
# died with "OPENROUTE_BASE_URL: unbound variable" while testing that the
# product prints that exact text.
routed_seat=""
for s in $SEATS; do
  if grep -q 'base_url_env' "$AGENTS/$s/agent.toml"; then routed_seat="$s"; break; fi
done
if [ -n "$routed_seat" ]; then
  SECRET_URL="https://gw-smoke-$$.invalid/anthropic"
  export OPENROUTE_API_KEY="sk-smoke-$$"

  OPENROUTE_BASE_URL="$SECRET_URL" $E routes "$AGENTS" >"$TMP/routes-set.txt" 2>&1
  rsrc=$?
  if [ $rsrc -eq 0 ] && grep -q "^$routed_seat .* takes open" "$TMP/routes-set.txt"
    then ok   "with both secrets on the box, $routed_seat takes the open road (exit 0)"
    else bad  "with both secrets on the box, $routed_seat takes the open road (exit 0) [exit $rsrc]"
  fi
  if grep -qF 'at $OPENROUTE_BASE_URL' "$TMP/routes-set.txt" && ! grep -qF "$SECRET_URL" "$TMP/routes-set.txt"
    then ok   'the endpoint is read back as $OPENROUTE_BASE_URL, never as its value'
    else bad  'the endpoint is read back as $OPENROUTE_BASE_URL, never as its value'
  fi

  # The third outcome: set, and set wrong. The seat still runs on the floor, and
  # `epito routes` is the one place that refuses, so the typo is not silent.
  OPENROUTE_BASE_URL="gw-smoke-$$.invalid" $E routes "$AGENTS" >"$TMP/routes-bad.txt" 2>&1
  rbrc=$?
  if [ $rbrc -eq 1 ]
    then ok  "an endpoint set to a non-URL exits 1 rather than falling through in silence"
    else bad "an endpoint set to a non-URL exits 1 rather than falling through in silence [exit $rbrc]"
  fi
  if grep -q 'configured and configured wrongly' "$TMP/routes-bad.txt" \
     && grep -q 'Fix: set OPENROUTE_BASE_URL' "$TMP/routes-bad.txt"
    then ok  "...and the refusal names the variable and the fix"
    else bad "...and the refusal names the variable and the fix"
  fi
  if grep -q "^$routed_seat .* takes subscription" "$TMP/routes-bad.txt"
    then ok  "...while the seat still has a road, so nothing stops running"
    else bad "...while the seat still has a road, so nothing stops running"
  fi
  if ! grep -qF "gw-smoke-$$.invalid" "$TMP/routes-bad.txt"
    then ok  "...and even the wrong value is not printed back"
    else bad "...and even the wrong value is not printed back"
  fi
  # Blank is the third outcome's quieter half, and the one an env file invites:
  # `OPENROUTE_API_KEY=` with nothing after it. It closes the road exactly like
  # an absent key and it is NOT the same box, so it does not get the same
  # sentence — `epito env` calls it "set and set to nothing" and this has to
  # agree with it.
  OPENROUTE_API_KEY="" OPENROUTE_BASE_URL="$SECRET_URL" $E routes "$AGENTS" >"$TMP/routes-blank.txt" 2>&1
  rblrc=$?
  if [ $rblrc -eq 1 ] && grep -q 'holds nothing' "$TMP/routes-blank.txt"
    then ok  "a key set to nothing is a line to fix, not a road this box never had"
    else bad "a key set to nothing is a line to fix, not a road this box never had [exit $rblrc]"
  fi
  if ! grep -q 'OPENROUTE_API_KEY is not set on this machine' "$TMP/routes-blank.txt"
    then ok  "...and is never described as unset, which is a different box"
    else bad "...and is never described as unset, which is a different box"
  fi
  unset OPENROUTE_API_KEY
fi

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
  echo "     install it (curl -sSf https://temporal.download/cli.sh | sh) and run \`temporal server start-dev\`,"
  echo "     or let the harness do both: bash test/all.sh --with-prereqs"
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
check "validate $WROTE_NOTHING" "untouched"
# agents/README.md is in that directory and is not a seat. findManifests looks
# for the filename, so it cannot be fooled — but the count above is what would
# have caught it, and this suite has already been bitten once by `ls`.
check "the roster count ignores agents/README.md" "[ -f '$AGENTS/README.md' ] && printf '%s' \"\$vout\" | grep -q '$nseats of $nseats manifests'"

step "7. what this roster asks of the BOX, and what a box short of a name does"
# The other side of step 3. `epito routes` says which model each seat gets
# here; this says what else each seat gets here — and the answer on this
# company's own roster was the card: three names agents/pm/agent.toml asks for
# were in no line of deploy/provision-host.sh, so the PM seat on a fresh box
# would have run, green, and filed nothing to the board.
#
# Run in a scrubbed environment (`env -i`), because the suite has to assert on
# what a BARE box does and this one is a CI runner that really does hold some
# of these names. PATH and HOME are what node itself needs; nothing else is
# inherited, so every name below is genuinely absent.
BARE="env -i PATH=$PATH HOME=$TMP"
# The union of every name the manifests ask for, read out of the files rather
# than typed here: a name added to a manifest tomorrow is a name this loop
# checks tomorrow.
NAMES="$(sed -nE 's/^env = \[(.*)\]$/\1/p' "$AGENTS"/*/agent.toml | tr -d '" ' | tr ',' '\n' | sort -u)"
check "the roster declares at least one name for the box to hold" "[ -n \"\$NAMES\" ]"

eout="$($BARE node "$CLI/src/index.js" env "$AGENTS" 2>&1)"; erc=$?
check "epito env reads the whole roster (exit 0 on a box that holds none of it)" "[ $erc -eq 0 ]"
for n in $NAMES; do
  check "it names $n, and says this box does not have it" \
    "printf '%s' \"\$eout\" | grep -q '$n .*not set here'"
done
check "it says who asks for each name" "printf '%s' \"\$eout\" | grep -q 'engineer, exo, market, okr, pm'"
check "a road's halves are named as a road's halves" "printf '%s' \"\$eout\" | grep -q 'the key for route \"open\"'"
check "it refuses to guess which are required" "printf '%s' \"\$eout\" | grep -q 'does not guess'"
check "and points at the command that opens or closes a road" "printf '%s' \"\$eout\" | grep -q 'epito routes'"
check "every seat short of a name is named, with its count" "printf '%s' \"\$eout\" | grep -q '! pm runs here with 0 of'"

# --complete is the operator asserting what the manifest cannot say.
$BARE node "$CLI/src/index.js" env "$AGENTS" --complete >"$TMP/env-complete.txt" 2>&1
ecrc=$?
check "--complete refuses a box short of a name (exit 1)" "[ $ecrc -eq 1 ]"
check "...and the refusal lists them and names the template" \
  "grep -q 'does not: BOARD_API_URL' '$TMP/env-complete.txt' && grep -q -- '--template' '$TMP/env-complete.txt'"

# The generated env file IS the fix, and it has to cover every name the
# manifests ask for — that coverage is the whole reason the hand-kept list in
# provision-host.sh could go away.
tmpl="$($BARE node "$CLI/src/index.js" env "$AGENTS" --template 2>&1)"
for n in $NAMES; do
  check "--template writes a line for $n" "printf '%s' \"\$tmpl\" | grep -q '^$n='"
done
check "--template says what it is and where it goes" "printf '%s' \"\$tmpl\" | grep -q 'systemd EnvironmentFile'"

# A box that holds everything, and a box that holds a name set to nothing.
FULL="env -i PATH=$PATH HOME=$TMP"
for n in $NAMES; do FULL="$FULL $n=smoke-value-$$"; done
fout="$($FULL node "$CLI/src/index.js" env "$AGENTS" 2>&1)"; frc=$?
check "a box that holds every name is told so (exit 0)" "[ $frc -eq 0 ]"
check "...in one line, naming the runtime's own names as not counted" \
  "printf '%s' \"\$fout\" | grep -q 'holds every name' && printf '%s' \"\$fout\" | grep -q 'CLAUDE_CODE_OAUTH_TOKEN'"
check "...and no value it read is printed back" "! printf '%s' \"\$fout\" | grep -q 'smoke-value-$$'"
check "a held name is commented out in the template, so pasting cannot blank it" \
  "$FULL node '$CLI/src/index.js' env '$AGENTS' --template | grep -q '^# SLACK_WEBHOOK_URL='"

# Set, and set to nothing: the env-file line somebody half filled in. The box
# HAS this one and has it wrong, so it refuses — the same split `epito routes`
# makes between a road this box never had and a road it has wrong.
eout2="$($BARE SLACK_WEBHOOK_URL= node "$CLI/src/index.js" env "$AGENTS" 2>&1)"; e2rc=$?
check "a name set to nothing exits 1 rather than reading as absent" "[ $e2rc -eq 1 ]"
check "...and a seat's line tells an empty name apart from an absent one" \
  "printf '%s' \"\$eout2\" | grep -q 'SLACK_WEBHOOK_URL arrives empty'"
check "...named, with both ways to fix it" \
  "printf '%s' \"\$eout2\" | grep -q 'set and set to nothing (SLACK_WEBHOOK_URL)' && printf '%s' \"\$eout2\" | grep -q 'delete the line entirely'"

ejson="$($BARE node "$CLI/src/index.js" env "$AGENTS" --json 2>&1)"
check "--json is JSON, with a row per name and a row per seat" \
  "printf '%s' \"\$ejson\" | node -e 'const r=JSON.parse(require(\"fs\").readFileSync(0,\"utf8\")); process.exit(r.names.length>0 && r.seats.length===$nseats && r.missing.length===r.names.length ? 0 : 1)'"
check "epito env $WROTE_NOTHING" "untouched"

step '8. would a run of THIS roster start on this box? (epito doctor)' 
# The dogfood question, asked by the product about the product's own seats.
# Run bare for the same reason step 7 is: this is a CI runner that holds some
# of these names, and the assertions have to be about what a box does, not
# about what this box happens to have. So they are written to hold either way
# — whether or not this machine has an executor or an engine — because the
# facts under test are that every seat is reported, that a missing NAME is not
# a refusal, and that nothing is written.
dout="$($BARE node "$CLI/src/index.js" doctor "$AGENTS" 2>&1)"; drc=$?
check "epito doctor reads the whole roster"            "printf '%s' \"\$dout\" | grep -q '$nseats seats, checked in the order a run needs them'"
check "...with a row for each of the five things a run needs" \
  "printf '%s' \"\$dout\" | grep -q 'manifests' && printf '%s' \"\$dout\" | grep -q 'names' && printf '%s' \"\$dout\" | grep -q 'roads' && printf '%s' \"\$dout\" | grep -q 'executor' && printf '%s' \"\$dout\" | grep -q 'engine'"
check "...and the manifests of the real roster pass"   "printf '%s' \"\$dout\" | grep -q '✓ manifests'"
check "...and never a stack, whatever the box lacks"   "! printf '%s' \"\$dout\" | grep -q 'at findManifests\|ERR_MODULE_NOT_FOUND\|node:internal'"
check "it either says a run would start, or says which piece is missing" \
  "printf '%s' \"\$dout\" | grep -q 'nothing here would make a run on this box refuse\|a run on this box would refuse'"

djson="$($BARE node "$CLI/src/index.js" doctor "$AGENTS" --json 2>&1)"
check "--json carries one verdict per seat and a refusals list" \
  "printf '%s' \"\$djson\" | node -e 'const r=JSON.parse(require(\"fs\").readFileSync(0,\"utf8\")); process.exit(r.seats.length===$nseats && Array.isArray(r.refusals) && r.seats.every(s=>s.executor&&typeof s.ready===\"boolean\") ? 0 : 1)'"
# The rule the whole command rests on: a name this box does not hold is a
# report, not a refusal. On a bare box every name this roster asks for is
# absent, and not one of them may appear as a reason a run would refuse.
check "a bare box is short of every name, and that refuses nothing" \
  "printf '%s' \"\$djson\" | node -e 'const r=JSON.parse(require(\"fs\").readFileSync(0,\"utf8\")); const names=r.seats.flatMap(s=>s.names.missing); process.exit(names.length>0 && !r.refusals.some(x=>/set to nothing|not set/.test(x.says)) ? 0 : 1)'"
check "and doctor $WROTE_NOTHING" "untouched"
# And the question this product is FOR, asked of its own seats: who does each
# one act as on a box? The answer today is nobody — no seat in this roster has
# a GitHub App anywhere, and not one of them names GH_TOKEN in [runtime].env,
# so a run's child gets no GitHub credential at all. That is a true report
# about this roster and not a defect in the command, which is why it is
# asserted rather than fixed here: giving a seat an App is two names on a box
# and a card nobody has run yet.
check "doctor says who each seat acts as, for all $nseats" \
  "printf '%s' \"\$djson\" | node -e 'const r=JSON.parse(require(\"fs\").readFileSync(0,\"utf8\")); process.exit(r.seats.length===$nseats && r.seats.every(s=>s.identity && s.identity.state) ? 0 : 1)'"
check "...and on a bare box that answer is nobody, for every one of them" \
  "printf '%s' \"\$djson\" | node -e 'const r=JSON.parse(require(\"fs\").readFileSync(0,\"utf8\")); process.exit(r.seats.every(s=>s.identity.state===\"none\") ? 0 : 1)'"
check "...which is a report, not a reason a run would refuse" \
  "printf '%s' \"\$djson\" | node -e 'const r=JSON.parse(require(\"fs\").readFileSync(0,\"utf8\")); process.exit(r.refusals.some(x=>/identity|mint/.test(x.says)) ? 1 : 0)'"
check "...and no seat's identity row carries a key, only which App" \
  "! printf '%s' \"\$djson\" | grep -q 'PRIVATE KEY'"
# The same reader, from `epito env`: the names no manifest declares.
check "epito env carries the identity block for this roster too" \
  "printf '%s' \"\$eout\" | grep -q 'the names no manifest declares'"


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
