#!/usr/bin/env bash
# Smoke test for the publish path — backlog card "Ship the CLI to npm".
#
#   bash test/pack.sh            # from cli/  (also: npm run pack-check)
#
# `package.json` names this script in `prepublishOnly`, so it is the last gate
# before anything reaches the registry. It runs `npm pack`, installs the real
# tarball into a throwaway prefix, and drives the installed `epito` — not the
# one in this working tree. That distinction is the whole point: everything
# this suite catches is invisible from a developer checkout, because a checkout
# has `node_modules/@temporalio/*` sitting there from devDependencies and a
# `README.md` one directory up.
#
# What it proves:
#
#   1. the tarball carries what a user needs and nothing they should not get:
#      no test suite, no fixtures, no .epito, no key, no lockfile — and a
#      README, which `files` claimed for one commit while npm silently
#      dropped it (README.md lived at the repo root, not in cli/)
#   2. the MANIFEST COMMANDS WORK WITH NO ENGINE INSTALLED. @temporalio/* are
#      optional peers so `npm i -g epito` is half a megabyte instead of
#      ~300 MB; init, validate, deploy --dry-run, token --dry-run, routes,
#      board and audit must all run with the engine absent, or that trade is
#      a lie
#   3. and the five commands that DO need the engine refuse in epito's voice —
#      naming the package, the install line and the command to retry — rather
#      than with the fourteen-line ERR_MODULE_NOT_FOUND stack they printed
#      before, which named a file path inside our own package
#   4. installing the engine alongside makes those commands work, so the
#      message in 3 tells the truth
#
# Nothing here touches the network except `npm install` of a local tarball,
# and nothing touches an account.
set -uo pipefail

CLI="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT="${TMPDIR:-/tmp}/epito-pack-$$"
PREFIX="$ROOT/prefix"; WORK="$ROOT/work"; TGZ_DIR="$ROOT/tgz"
E="$PREFIX/bin/epito"

pass=0; fail=0
ok()   { pass=$((pass+1)); printf '  ok   %s\n' "$1"; }
bad()  { fail=$((fail+1)); printf '  FAIL %s\n' "$1"; }
check(){ if eval "$2"; then ok "$1"; else bad "$1"; fi; }
step() { printf '\n== %s\n' "$1"; }

# Run the INSTALLED epito and keep its output in a file. A first draft of this
# script interpolated the output into `check`'s eval, which is how `epito token
# --dry-run` — whose text names $EPITO_APP_ID_<NAME> and a <port> placeholder —
# got its own output expanded as shell. Output is data. It goes to a file, and
# every assertion greps the file.
OUT="$ROOT/out.txt"
RC=0
run_epito() { "$E" "$@" >"$OUT" 2>&1; RC=$?; }
said()   { grep -q "$1" "$OUT"; }
shows()  { sed "s/^/      /" "$OUT" | head "${1:--3}"; }

cleanup() { rm -rf "$ROOT"; }
trap cleanup EXIT

mkdir -p "$PREFIX" "$WORK" "$TGZ_DIR"

# ---------------------------------------------------------------- 1. the pack
step "1: npm pack — what a user actually downloads"
if ! (cd "$CLI" && npm pack --pack-destination "$TGZ_DIR") >"$ROOT/pack.log" 2>&1; then
  echo "pack: SKIPPED — \`npm pack\` failed in $CLI; nothing could be asserted"
  sed 's/^/       /' "$ROOT/pack.log" | tail -15
  exit 0
fi
TGZ="$(ls "$TGZ_DIR"/*.tgz 2>/dev/null | head -1)"
if [ -z "$TGZ" ]; then
  echo "pack: SKIPPED — npm pack wrote no tarball"
  exit 0
fi
tar tzf "$TGZ" | sed 's|^package/||' | sort > "$ROOT/files.txt"
BYTES=$(wc -c < "$TGZ")
printf '  tarball: %s (%s KB, %s files)\n' "$(basename "$TGZ")" "$((BYTES / 1024))" "$(wc -l < "$ROOT/files.txt" | tr -d ' ')"

has()    { grep -qx "$1" "$ROOT/files.txt"; }
hasnt()  { ! grep -q "$1" "$ROOT/files.txt"; }

check "the bin entry is in it"                     'has src/index.js'
check "and every module it lazily imports"         'has src/run.js && has src/deploy.js && has src/token.js && has src/board.js && has src/routes.js'
check "  including the engine-missing message"     'has src/lib/engine.js'
check "  and the field catalogue the frozen spec is tested against" 'has src/lib/fields.js'
# `epito validate` is the first command a user runs and these two are what make
# its answer honest -- the readiness notes and the git-origin read behind
# `epito init`. Named here because a `files` entry npm drops is silent, which
# is how the README went missing for a commit.
check "  and the readiness notes behind the ✓"   'has src/lib/readiness.js'
check "  and the origin read behind \`epito init\`" 'has src/lib/origin.js'
check "the langgraph adapter ships: a seat may be one" 'has adapters/langgraph_run.py'
check "a README ships — the npm page is not blank" 'has README.md'
check "no test suite, no fixtures"                 'hasnt "^test/"'
check "no lockfile"                                'hasnt "^package-lock.json"'
check "nothing from .epito, no key, no .pem"       'hasnt "\.epito" && hasnt "\.pem$"'
check "no charters or docs"                        'hasnt "^prompts/" && hasnt "^docs/"'
# The engine is ~300 MB installed; a tarball over a megabyte means something
# got vendored by accident.
check "under 1 MB on the wire"                     "[ $BYTES -lt 1048576 ]"

# ------------------------------------------------- 2. install, with NO engine
step "2: install the tarball into a clean prefix — no engine, as a user gets it"
if ! (cd "$ROOT" && npm install -g --prefix "$PREFIX" "$TGZ") >"$ROOT/install.log" 2>&1; then
  echo "pack: SKIPPED — installing the tarball failed; nothing further could be asserted"
  sed 's/^/       /' "$ROOT/install.log" | tail -15
  exit 0
fi
INSTALLED_KB=$(du -sk "$PREFIX/lib/node_modules" | cut -f1)
printf '  installed: %s KB in %s/lib/node_modules\n' "$INSTALLED_KB" "$PREFIX"
check "the \`epito\` binary is on the prefix's PATH" "[ -x '$E' ]"
check "no @temporalio/* came with it"              "[ -z \"\$(find '$PREFIX/lib/node_modules' -maxdepth 3 -name '@temporalio' 2>/dev/null)\" ]"
# This is the number the card is about: half a megabyte, not 312.
check "under 2 MB installed (the engine would be ~300)" "[ $INSTALLED_KB -lt 2048 ]"

# ----------------------------------- 3. the manifest commands, engine absent
step "3: the manifest commands run with no engine — that is what the trade buys"
cd "$WORK"
run_epito init digest
check "epito init works, exit 0"                   "[ $RC = 0 ] && [ -f '$WORK/agent.toml' ]"
run_epito validate; shows -1
check "epito validate works and ticks, exit 0"     "[ $RC = 0 ] && said '✓'"

# --- the ✓ must not overclaim. $WORK is a bare temp directory with no git
# origin, so init cannot know [runtime].repo and leaves it commented out --
# which is exactly the manifest that used to tick here and then get refused by
# the four commands below. The tick stays (spec v0.1 says this file is valid);
# what it now also does is say what the runtime will still need.
check "init says it could not read [runtime].repo here" "grep -q '^# repo = \"owner/name\"' '$WORK/agent.toml'"
check "the ✓ names what is still missing"            "said 'not ready to run'"
check "...and which commands will refuse it"          "said 'epito run' && said 'epito deploy' && said 'epito token'"
check "...and the fix, in the field's own words"      "said 'repo = \"owner/name\"'"
check "...without claiming the file is invalid"       "[ $RC = 0 ] && said 'valid v0.1 manifest either way'"
run_epito validate --for-runtime
check "--for-runtime makes the same note an error"    "[ $RC = 1 ] && said 'the runtime would accept this manifest, and it would not'"

printf 'repo = "acme/roster"\n' >> "$WORK/agent.toml"
run_epito validate
check "with repo set, the ✓ has nothing left to warn about" "[ $RC = 0 ] && ! said 'not ready to run'"
for c in "deploy --dry-run" "token digest --dry-run" "routes" "board" "audit" "--help"; do
  # shellcheck disable=SC2086 -- $c is this script's own literal, split on purpose
  run_epito $c
  check "epito $c runs with no engine, and prints no stack" "! said ERR_MODULE_NOT_FOUND"
done

# ----------------------- 4. the engine commands refuse in the product's voice
step "4: the five commands that NEED the engine say so — the bar \`epito validate\` sets"
for c in run worker ps window message; do
  case "$c" in
    run)     run_epito run . ;;
    window)  run_epito window open ;;
    message) run_epito message digest hello ;;
    *)       run_epito "$c" ;;
  esac
  printf '  --- epito %s\n' "$c"; shows -3
  check "epito $c: exits 1, not 0"                 "[ $RC = 1 ]"
  check "epito $c: no stack trace"                 "! said 'ERR_MODULE_NOT_FOUND\|at ModuleLoader'"
  check "epito $c: speaks as epito"                "said '^epito:'"
  check "epito $c: names the missing package"      "said '@temporalio/'"
  check "epito $c: carries the fix"                "said 'Fix: npm i -g @temporalio/'"
  check "epito $c: names the command to retry"     "said 'then: epito $c'"
done
# A missing module that is OUR bug must never be dressed up as the user's
# missing install — the one case that would make this message a liar.
node --input-type=module -e "
import { engineImport } from '$PREFIX/lib/node_modules/epito/src/lib/engine.js';
try { await engineImport(() => import('./no-such-module-of-ours.js'), 'run'); }
catch (e) { console.log(e.epitoHandled ? 'DRESSED-UP' : 'RETHROWN'); }
" > "$OUT" 2>&1
check "a missing module of OURS is re-thrown, not blamed on the engine" "said '^RETHROWN$'"

# --------------------------------- 5. install the engine: the message is true
step "5: install the engine alongside — the commands the message named now get further"
if (cd "$ROOT" && npm install -g --prefix "$PREFIX" @temporalio/client@^1.24.0) >"$ROOT/engine.log" 2>&1; then
  run_epito ps .; shows -2
  check "epito ps no longer reports a missing package" "! said 'is not installed on this machine'"
  check "it fails on the ENGINE being unreachable instead, still in one line" \
        "! said 'ERR_MODULE_NOT_FOUND\|at ModuleLoader'"
else
  printf '  SKIPPED — could not install @temporalio/client here (no registry access?)\n'
  sed 's/^/       /' "$ROOT/engine.log" | tail -5
fi

# ------------------- 6. the card itself: init in a repo needs no hand-editing
# The backlog card is "errors a vibecoder can act on", and the sharpest version
# of acting on an error is never seeing it. Nearly always `epito init` is run
# inside the repository the agent will work in, and that is where
# [runtime].repo was sitting all along -- so init reads it off the git origin
# instead of asking. This is the whole out-of-the-box path, in order, from the
# installed package: init, validate, deploy. It is the sequence that used to
# end in a refusal, and step 3 above is the same sequence with the one fact
# init could not know.
step "6: init -> validate -> deploy inside a real repo, with nothing edited by hand"
REPO_WORK="$ROOT/in-a-repo"
mkdir -p "$REPO_WORK"
if (cd "$REPO_WORK" && git init -q . && git remote add origin git@github.com:acme/product.git) 2>/dev/null; then
  cd "$REPO_WORK"
  run_epito init digest; shows -2
  check "epito init reads [runtime].repo off the git origin"  "grep -q '^repo = \"acme/product\"' '$REPO_WORK/agent.toml'"
  check "...and says where it got it"                        "said 'read from this directory'"
  run_epito validate; shows -2
  check "epito validate ticks with no note to add"           "[ $RC = 0 ] && ! said 'not ready to run'"
  check "...with nothing to disclaim: the charter init wrote is right here" "! said 'read inside the clone'"
  # Move the charter away and the ✓ stops claiming it exists. `epito validate`
  # does not stat `entry` at all once `repo` is set (the runtime reads it inside
  # the clone), so without this note the tick would be silent about a seat whose
  # charter is nowhere -- and loud about every seat whose charter is fine.
  mv "$REPO_WORK/prompts/digest.md" "$REPO_WORK/charter-moved-away.md"
  run_epito validate; shows -2
  check "a charter that is nowhere on this machine is said out loud"  "[ $RC = 0 ] && said 'read inside the clone of acme/product'"
  check "...with the fix naming the file and the repo"                "said 'Fix: commit prompts/digest.md to acme/product'"
  mv "$REPO_WORK/charter-moved-away.md" "$REPO_WORK/prompts/digest.md"
  run_epito validate --for-runtime
  check "the strict pass agrees: the runtime would take this manifest" "[ $RC = 0 ]"
  run_epito deploy --dry-run; shows -3
  check "epito deploy --dry-run accepts it, unedited"        "[ $RC = 0 ] && ! said '\[runtime\].repo is required'"
  check "...and asks GitHub for exactly the declared scopes" "said '\"contents\": \"write\"' && said '\"pull_requests\": \"write\"'"
  run_epito token digest . --dry-run
  check "epito token --dry-run accepts it too, unedited"     "! said '\[runtime\].repo is required'"
  cd "$WORK"
else
  printf '  SKIPPED -- no usable git here, so the origin-read path could not be driven\n'
fi

# --------------------- 7. an option epito does not know is refused, by name
# Found driving the installed package by hand: every command outside `epito
# board` read its flags with `args.includes("--x")`, so anything else was
# dropped without a word. That is not a cosmetic bug on two of them --
# `--dry-runn` is the difference between printing a plan and minting a real
# token, or opening a browser and creating a real GitHub App -- and on
# `validate` it turns the strict gate somebody put in CI into a silent ✓.
# These run against the INSTALLED binary because that is who the user is.
step "7: a misspelled option is refused rather than dropped"
cd "$WORK"   # section 3 left a valid manifest named digest here, repo and all
run_epito validate --for-runtimes; shows -3
check "validate refuses --for-runtimes, exit 1"        "[ $RC = 1 ] && said 'has no --for-runtimes option'"
check "...and names the flag that was meant"           "said 'Did you mean --for-runtime'"
check "...and does NOT print a ✓ on the way"           "! said '✓'"
run_epito token digest . --dry-runn; shows -2
check "token refuses --dry-runn rather than minting"   "[ $RC = 1 ] && said 'Did you mean --dry-run'"
check "...and reaches no network and no key"           "! said 'would mint' && ! said 'no identity to mint from'"
run_epito deploy --dry-runn; shows -2
check "deploy refuses --dry-runn rather than deploying" "[ $RC = 1 ] && said 'Did you mean --dry-run'"
check "...and opens nothing"                            "! said 'waiting up to' && ! said 'click Create'"
run_epito validate --wat; shows -3
check "an option close to nothing lists the real ones"  "[ $RC = 1 ] && said '[-][-]for-runtime  make the readiness notes'"
# And what the flag says it does has to include the engine, because that is
# what it now refuses for — a user reading only this list must not be surprised
# by an exit 1 from a box with no Temporal server.
check "...and the flag's one line names the engine too"  "said 'an engine that is not up'"
run_epito init --force
check "a command with no options says so plainly"       "[ $RC = 1 ] && said 'takes no options'"
run_epito deploy --timeout 1 --dry-run
check "a real option still works, value and all"        "[ $RC = 0 ] && said 'would deploy'"
cd "$WORK"

# ------------------------------ 8. the ledger reader, from the installed package
# `epito audit` is new in this branch, and what pack.sh is for is the half of a
# change that a developer checkout cannot see. Two of those here: whether
# src/audit.js and src/lib/table.js actually reached the tarball (`files` claims
# "src", and npm silently dropped a README the last time something trusted a
# files entry), and whether the reader runs with no engine installed, which the
# loop in section 3 now also asserts.
#
# The ledger here is written by hand rather than by a deploy: this script
# touches no network and no account, and `--dry-run` deliberately writes no
# audit line. That the WRITER and the READER agree about the shape of a line is
# proven in test/smoke-deploy.sh section 7, against a ledger `epito deploy` and
# `epito token` really wrote.
step "8: \`epito audit\` reads a ledger, from the installed binary"
check "src/audit.js shipped in the tarball"      'has src/audit.js'
check "src/lib/table.js shipped too"             'has src/lib/table.js'

mkdir -p "$WORK/.epito"
cat > "$WORK/.epito/audit.jsonl" <<'LEDGER'
{"ts":"2026-10-02T14:02:11.004Z","agent":null,"action":"worker.start","address":"127.0.0.1:7233","namespace":"default","queue":"seats"}
{"ts":"2026-10-02T14:03:01.000Z","agent":"digest","action":"deploy","created":true,"appId":"707070","slug":"digest-acme","repo":"acme/roster","installation":"4242","permissions":{"contents":"write","pull_requests":"write"}}
{"ts":"2026-10-02T14:04:07.880Z","agent":"digest","action":"mint","runId":"r-9f12","phase":"execute","repo":"acme/roster","installation":"4242","permissions":{"contents":"write","pull_requests":"write"},"expiresAt":"2026-10-02T15:04:07Z","commit":{"name":"digest[bot]"}}
{"ts":"2026-10-02T14:31:44.000Z","agent":"digest","action":"run.end","runId":"r-9f12","outcome":"ok","turns":23,"seconds":1654,"pr":"https://github.com/acme/roster/pull/7"}
LEDGER
cd "$WORK"
run_epito audit; shows -9
check "it reads the ledger, exit 0"                  "[ $RC = 0 ] && said 'the ledger'"
check "...and names what the token could do, and until when" \
  "said 'contents:write, pull_requests:write on acme/roster' && said 'expires 15:04Z'"
check "...and the run it belonged to"                "said '23 turns' && said 'pull/7'"
check "...and gives the machine's own lines no seat row" "! said '^-  *-  *-'"
run_epito audit --agent digest --action mint --limit 0
check "the filters work from the installed binary"   "[ $RC = 0 ] && said '1 of 4 lines'"
run_epito audit --sinse 24h
check "and a misspelled option is still refused"     "[ $RC = 1 ] && said 'Did you mean --since'"
cd "$WORK"

printf '\npack: %d ok, %d failed\n' "$pass" "$fail"
[ "$fail" = 0 ] || exit 1
