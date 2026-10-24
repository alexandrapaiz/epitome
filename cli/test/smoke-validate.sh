#!/usr/bin/env bash
# Smoke test for `epito validate` — the single manifest AND the whole roster.
#
#   bash test/smoke-validate.sh          # from cli/
#
# Why a suite of its own. smoke-roster.sh runs against this company's five real
# seats, which is the stronger evidence and is exactly why it cannot cover this:
# the real roster is clean. Every interesting thing about a roster validator is
# what it does to a roster that is NOT — one refused manifest among four good
# ones, two seats claiming one name, a seat that is valid and not yet runnable —
# and those have to be built to be seen.
#
# It needs no engine, no network, no account and no credential. That is the
# card. `epito run <dir> --dry-run` was the only command that read a roster
# whole and it connects to Temporal first, so an operator with five manifests
# and no box had no way to hear "yes" (docs/ideas.md raised it twice while the
# real roster was being written).
#
# What it does bind is one loopback TCP port, as a stand-in for an engine. The
# command now LOOKS at TEMPORAL_ADDRESS (a bare connect, no engine package) so
# that its closing ✓ stops speaking for `epito run` without having asked, and a
# suite whose verdicts depended on whether the machine running it happened to
# have Temporal up would assert nothing reliably. Pinning the address at a stub
# for sections 1-9 is what keeps "exit 1" in those sections mean the manifest
# rule they are about. Section 10 is the engine itself, both states, named.
#
# The stub is deliberately NOT a Temporal server, and section 10 asserts the
# wording that makes that honest: a TCP connect proves "something is answering",
# which is what the command claims, and not that the engine is healthy.
#
# What it proves:
#
#   1. a clean roster passes whole, names every seat, and says so on stdout
#   2. the roster form and the single-manifest form describe the same file in
#      the same words — one `shape()`, so a seat cannot read two ways
#   3. one refused manifest refuses the roster (exit 1) without hiding the
#      seats that are fine
#   4. two manifests claiming one [agent].name is refused — spec rule 4, and a
#      rule no single manifest can break
#   5. the deliberate severity split: a seat with no [runtime].repo is a NOTE
#      by default (spec v0.1 blesses it) and an ERROR under --for-runtime
#   6. EVERY rule in ROSTER_RULES — the ones `epito run` refuses a roster for —
#      makes `epito validate --for-runtime` exit 1. A rule with no fixture here
#      FAILS this suite rather than passing silently.
#   7. a refused roster puts nothing on stdout, so `epito validate <dir>
#      >/dev/null` in a CI step shows exactly the problems
#   8. validate never writes: no .epito/, no file of any kind, on any path
#   9. and `epito init`, the command before it: two filesystem conditions that
#      used to be a Node stack, and a name it quietly changed
#  10. the severity split spec v0.2 added: a key the catalogue does not define
#      is WARNED in [agent] and [trigger] and still REFUSED in [identity] and
#      [runtime], said in both forms, with the count in the closing verdict.
#      Its fixture is two real lines out of a foreign roster, not two we wrote
set -uo pipefail

CLI="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="${TMPDIR:-/tmp}/epito-validate-smoke-$$"
E="node $CLI/src/index.js"

pass=0; fail=0
ok()   { pass=$((pass+1)); printf '  ok   %s\n' "$1"; }
bad()  { fail=$((fail+1)); printf '  FAIL %s\n' "$1"; }
check(){ if eval "$2"; then ok "$1"; else bad "$1"; fi; }
# `said <captured output> [grep flags] <pattern>` — the one way this suite
# looks inside a command's output, and it contains no pipe. That is the whole
# point of it.
#
# Every check here used to read `printf '%s' "$OUT" | grep -q '<pattern>'`, and
# that shape reports FAILURE on a pattern it MATCHED. `grep -q` exits the
# instant it matches; the `printf` whose pipe it just closed dies of SIGPIPE
# (141); and `set -o pipefail`, two lines below, makes the pipeline's status
# that 141 rather than grep's 0. Measured on this box, with four node processes
# as background load: 8 false failures in 3000 invocations of one such grep,
# `PIPESTATUS=[0]` every time — grep had matched. At 71 of them per run that is
# a gate crying wolf about once in five runs, and a gate nobody believes is not
# a gate. A herestring has no pipe and no second process to kill.
said() { local hay="$1"; shift; grep -q "$@" <<<"$hay"; }
step() { printf '\n== %s\n' "$1"; }
STUB_PID=""
cleanup() {
  [ -n "$STUB_PID" ] && kill "$STUB_PID" 2>/dev/null
  if [ -n "${EPITO_SMOKE_KEEP:-}" ]; then printf '\nkept: %s\n' "$TMP"; else rm -rf "$TMP"; fi
}
trap cleanup EXIT
mkdir -p "$TMP"

# A socket that accepts and does nothing, standing in for the engine on an
# ephemeral port. Sections 1-9 are about manifests, so the engine is held
# constant and present; section 10 varies it on purpose.
node -e 'const s=require("net").createServer();s.listen(0,"127.0.0.1",()=>require("fs").writeFileSync(process.argv[1],String(s.address().port)));' "$TMP/stub-port" &
STUB_PID=$!
for _ in $(seq 1 60); do [ -s "$TMP/stub-port" ] && break; sleep 0.05; done
STUB_PORT="$(cat "$TMP/stub-port" 2>/dev/null)"
if [ -z "$STUB_PORT" ]; then
  echo "smoke: SKIPPED — could not bind a loopback port to stand in for the engine."
  echo "     This suite pins TEMPORAL_ADDRESS at a stub so that an exit 1 in"
  echo "     sections 1-9 means the manifest rule under test and not a missing"
  echo "     engine. Nothing was asserted. Treat this as no evidence, not a pass."
  exit 0
fi
# Every section below runs against the stub unless it says otherwise.
export TEMPORAL_ADDRESS="127.0.0.1:$STUB_PORT"
# The dead address every "no engine" case uses: loopback port 1 refuses
# immediately, so these cases cost a refusal and not a timeout.
DEAD="127.0.0.1:1"

# A seat, written out: $1 dir, $2 name, $3 extra [runtime] lines. The charter is
# written beside the manifest so a fixture seat is ready to run by default and
# each case has to break exactly the one thing it is about.
seat() {
  mkdir -p "$1/prompts"
  printf '# %s\n\nYour charter.\n' "$2" > "$1/prompts/$2.md"
  { printf '[agent]\nname = "%s"\ndescription = "A fixture seat for the roster validator."\n\n' "$2"
    printf '[identity]\nscopes = ["github:contents", "github:pull_requests"]\n\n'
    printf '[trigger]\ncron = "0 6 * * *"\n\n'
    printf '[runtime]\nmodel = "claude-sonnet-5"\nentry = "prompts/%s.md"\n' "$2"
    printf '%s\n' "$3"
  } > "$1/agent.toml"
}
REPO='repo = "acme/product"'

# ---------------------------------------------------------------------------
step "1. a clean roster of three seats passes whole"
CLEAN="$TMP/clean"
for s in alpha bravo charlie; do seat "$CLEAN/$s" "$s" "$REPO"; done
# charlie is presence-only: no [trigger].cron, webhook instead. The count of
# cronned vs presence-only seats is the line an operator reads to confirm the
# seat they meant to leave event-driven has no schedule.
sed -i.bak 's/^cron = "0 6 \* \* \*"$/webhook = true/' "$CLEAN/charlie/agent.toml" && rm -f "$CLEAN/charlie/agent.toml.bak"

OUT="$($E validate "$CLEAN" 2>"$TMP/clean.err")"; RC=$?
ERR="$(cat "$TMP/clean.err")"
check "a clean roster exits 0"                  "[ $RC -eq 0 ]"
check "it names all three seats"                "[ \$(printf '%s\n' \"\$OUT\" | grep -c '^✓ ') -eq 4 ]"
check "it counts the manifests"                 "said \"\$OUT\" '3 of 3 manifests are agents'"
check "it separates cronned from presence-only" "said \"\$OUT\" '2 on a cron, 1 presence-only (charlie)'"
check "it names the presence-only seat"          "said \"\$OUT\" 'presence-only (charlie)'"
check "it says the roster would not be refused" "said \"\$OUT\" 'nothing here .epito run .* would refuse'"
check "...and names the engine it checked"      "said \"\$OUT\" \"$TEMPORAL_ADDRESS is answering\""
check "a clean roster says nothing on stderr"   "[ -z \"\$ERR\" ]"
# A roster beside or above the cwd relativises to a ladder of ".." — harder to
# read and harder to paste than the path it came from. $CLEAN is under TMPDIR
# and this runs from cli/, so a naive relative() would print ../../../tmp/...
AWAY="$(cd "$CLI" && $E validate "$CLEAN" 2>&1)"
check "a roster outside the cwd is named, not laddered" "! said \"\$AWAY\" '\.\./'"
check "...and it is still the same verdict"             "said \"\$AWAY\" '3 of 3 manifests are agents'"
# This used to assert that the output never said the word "temporal", which
# read as "no engine required" and was in fact what let the ✓ claim `epito run`
# would refuse nothing on a box where `epito run` refused in one line. The
# invariant worth holding is the real one: the command ANSWERS THE MANIFEST
# QUESTION IN FULL, exit 0, with nothing answering anywhere — which is the
# operator with five manifests and no box, and is section 10's first case.
# That it needs no engine PACKAGE installed is test/pack.sh's assertion, and
# that the module it reads the address through imports nothing is unit.mjs's.
NOENG="$(TEMPORAL_ADDRESS=$DEAD $E validate "$CLEAN" 2>&1)"; RC=$?
check "with no engine at all it still exits 0"  "[ $RC -eq 0 ]"
check "...and still validates every manifest"   "said \"\$NOENG\" '3 of 3 manifests are agents'"

step "2. the roster form and the single-manifest form describe a seat identically"
# One shape() for both, so a seat cannot read two ways depending on which
# command you asked. This is the acceptance test for factoring validate out of
# index.js: the single-manifest wording is the wording that already shipped.
for s in alpha charlie; do
  single="$(cd "$CLEAN/$s" && $E validate 2>&1 | sed -n "s/^✓ $s is an agent: //p")"
  from_roster="$($E validate "$CLEAN" 2>&1 | sed -n "s/^✓ $s  *//p")"
  check "$s reads the same from both forms"  "[ -n \"\$single\" ] && [ \"\$single\" = \"\$from_roster\" ]"
done

step "3. one refused manifest refuses the roster, without hiding the good seats"
BAD="$TMP/badseat"; cp -R "$CLEAN" "$BAD"
mkdir -p "$BAD/delta"
cat > "$BAD/delta/agent.toml" <<'T'
[agent]
name = "Delta Seat"
[identity]
scopes = []
[trigger]
cron = "0 99 * * *"
[runtime]
entry = "prompts/delta.md"
repo = "acme/product"
T
OUT="$($E validate "$BAD" 2>&1)"; RC=$?
check "a roster with one bad manifest exits 1"   "[ $RC -eq 1 ]"
check "it names the refused file by path"        "said \"\$OUT\" 'delta/agent.toml — '"
check "it counts the refusal against the roster" "said \"\$OUT\" '1 of 4 manifests refused'"
check "it says why a roster is all-or-nothing"   "said \"\$OUT\" 'a roster runs whole or not at all'"
check "the three good seats are still reported"  "[ \$(printf '%s\n' \"\$OUT\" | grep -c '^✓ ') -eq 3 ]"
check "every problem in the bad one is named"    "[ \$(printf '%s\n' \"\$OUT\" | grep -c '    ✗ ') -ge 4 ]"
check "the bad cron is named as a schedule"      "said \"\$OUT\" 'is not a schedule the runtime can register'"
# Only the ✓/! rows are padded, so only they may set the column. A refused
# manifest is named by its PATH, and letting that path set the width pushed
# every good seat's description most of the way across the terminal — the
# longest seat name here is "charlie" (7), so a padded ✓ row is at most
# "✓ " + 7 + 2 = 11 characters before its description starts.
# Measured after the marker, and the marker's two characters added back: awk's
# index() counts bytes, not characters, on BSD awk and in any non-UTF-8 locale,
# and the ✓ is three of them — so a correctly padded table read as 14 wide on
# macOS and as 12 on a Linux box with LANG set. The ASCII part is the same
# number either way.
COL="$(printf '%s\n' "$OUT" | grep -E '^✓ ' | head -1 | awk '{ sub(/^✓ /, ""); print index($0, "identity") + 2 }')"
check "a long refused path does not set the column" "[ \"\$COL\" -le 12 ]"

step "4. two manifests, one [agent].name — spec rule 4"
DUP="$TMP/dup"; mkdir -p "$DUP"
seat "$DUP/first"  twin "$REPO"
seat "$DUP/second" twin "$REPO"
OUT="$($E validate "$DUP" 2>&1)"; RC=$?
check "a duplicate name refuses the roster"      "[ $RC -eq 1 ]"
check "it names the rule in the spec's words"    "said \"\$OUT\" 'one manifest, one principal'"
check "it names the file that claimed it first"  "said \"\$OUT\" 'first/agent.toml'"
check "the first copy is not itself refused"     "said \"\$OUT\" '1 of 2 manifests refused'"
# A refusal, not a note: no --for-runtime needed to hear that two seats are
# asking for one identity.
OUT="$($E validate "$DUP" 2>&1)"
check "it refuses without --for-runtime"         "said \"\$OUT\" 'manifests refused'"

step "5. the severity split: no [runtime].repo is a note by default, an error strictly"
NR="$TMP/notready"; mkdir -p "$NR"
seat "$NR/echo" echo ""          # valid v0.1, and `epito run` would refuse it
seat "$NR/foxtrot" foxtrot "$REPO"
OUT="$($E validate "$NR" 2>&1)"; RC=$?
check "a valid-but-not-ready roster exits 0"     "[ $RC -eq 0 ]"
check "the seat is marked ! and not ✗"           "said \"\$OUT\" '^! echo '"
check "it is still called a valid manifest"      "said \"\$OUT\" 'valid, not ready to run'"
check "the note carries a fix"                   "said \"\$OUT\" 'Fix: add repo = \"owner/name\"'"
# The fix is an instruction, so it has to name the file the way the reader
# would type it. findManifests returns absolute paths, and before `as` was
# threaded through checkManifest the fix for a seat in agents/okr named a path
# nobody had typed.
NROUT="$(cd "$TMP" && $E validate notready 2>&1)"
check "the fix names the path as typed"          "said \"\$NROUT\" 'in notready/echo/agent.toml'"
check "...not an absolute path nobody typed"     "! said \"\$NROUT\" 'Fix: add repo.*in /'"
check "it points at the flag that is stricter"   "said \"\$OUT\" -- '--for-runtime. to make those an error'"
OUT="$($E validate "$NR" --for-runtime 2>&1)"; RC=$?
check "--for-runtime makes the same note fail"   "[ $RC -eq 1 ]"
check "...and says it is the runtime's question" "said \"\$OUT\" 'whether the runtime would accept this roster, and it would not'"
check "...and counts the seats that are not"     "said \"\$OUT\" '1 of 2 seats is not ready to run'"

step "6. every roster rule \`epito run\` refuses, \`validate --for-runtime\` refuses too"
# ROSTER_RULES is the enumeration src/lib/roster.js exports. A rule that arrives
# there with no fixture in this loop lands in the *) arm and FAILS, which is the
# whole point: the alternative is a rule `epito run` refuses and `epito validate
# --for-runtime` passes, and then the strict gate is a lie.
RULES="$(cd "$CLI" && node -e 'import("./src/lib/roster.js").then(m => console.log(m.ROSTER_RULES.join(" ")))' 2>/dev/null)"
if [ -z "$RULES" ]; then
  bad "ROSTER_RULES could not be read from src/lib/roster.js"
else
  ok "ROSTER_RULES reads as: $RULES"
  for rule in $RULES; do
    case "$rule" in
      repo) d="$NR" ;;
      name) d="$DUP" ;;
      *) bad "roster rule \"$rule\" has no fixture in smoke-validate.sh, so nothing checks that \`epito validate --for-runtime\` refuses it the way \`epito run\` does"; continue ;;
    esac
    $E validate "$d" --for-runtime >/dev/null 2>&1
    check "rule \"$rule\": validate --for-runtime exits 1" "[ $? -eq 1 ]"
  done
fi

step "7. a refused roster puts nothing on stdout"
SOUT="$($E validate "$BAD" 2>/dev/null)"
check "stdout is empty when the roster is refused" "[ -z \"\$SOUT\" ]"
SOUT="$($E validate "$NR" --for-runtime 2>/dev/null)"
check "...and when --for-runtime is what refused"  "[ -z \"\$SOUT\" ]"
SOUT="$($E validate "$CLEAN" 2>/dev/null)"
check "a clean roster's report IS on stdout"       "[ -n \"\$SOUT\" ]"

step "8. validate writes nothing, anywhere, on any path"
# The promise `epito run --dry-run` broke by appending four lines to an
# append-only ledger for schedules it never created (docs/ideas.md). A
# validator has even less business writing than a dry run does.
for d in "$CLEAN" "$BAD" "$DUP" "$NR"; do
  # The listing itself, not a digest of it: macOS has `md5`, not `md5sum`, and
  # `|| true` turned that into two empty strings comparing equal — an assertion
  # about files that would have passed whatever validate wrote. It is also the
  # cheaper failure to read, because it prints the file that appeared.
  before="$(cd "$d" && find . | sort)"
  $E validate "$d" >/dev/null 2>&1
  $E validate "$d" --for-runtime >/dev/null 2>&1
  after="$(cd "$d" && find . | sort)"
  check "$(basename "$d"): no file created or removed" "[ \"\$before\" = \"\$after\" ]"
  check "$(basename "$d"): no .epito/ appeared"        "[ ! -e \"$d/.epito\" ]"
done
check "nor in the directory validate was run from"     "[ ! -e .epito ]"

step "9. the arguments it does not take, and the ones it does"
OUT="$($E validate "$TMP/nope-not-here" 2>&1)"; RC=$?
check "a path that does not exist exits 1"       "[ $RC -eq 1 ]"
check "...and names both forms it does take"     "said \"\$OUT\" 'a directory of manifests (the whole roster) or one agent.toml'"
mkdir -p "$TMP/vacant"
OUT="$($E validate "$TMP/vacant" 2>&1)"; RC=$?
check "an empty directory exits 1"               "[ $RC -eq 1 ]"
check "...and says an empty roster has nothing"  "said \"\$OUT\" 'an empty roster has nothing to validate'"
check "...with the fix a vibecoder can act on"   "said \"\$OUT\" 'epito init <name>'"
OUT="$($E validate "$CLEAN/alpha/agent.toml" 2>&1)"; RC=$?
check "a named manifest file validates, exit 0"  "[ $RC -eq 0 ] && said \"\$OUT\" '✓ alpha is an agent'"
OUT="$(cd "$TMP/vacant" && $E validate 2>&1)"; RC=$?
check "no manifest in the cwd still says init"   "[ $RC -eq 1 ] && said \"\$OUT\" 'no agent.toml here'"
check "...and now also names the roster form"    "said \"\$OUT\" 'epito validate <dir>'"
OUT="$($E validate "$CLEAN" --for-runtimes 2>&1)"; RC=$?
check "a misspelled flag is refused, not ignored" "[ $RC -eq 1 ] && said \"\$OUT\" 'Did you mean --for-runtime'"

step "10. the engine is the other half of \"ready to run\""
# The defect this section exists for. `epito validate agents --for-runtime`
# ticked five seats and said "there is nothing here \`epito run agents\` would
# refuse" on a box where \`epito run agents --dry-run\` refused in one line,
# before it read a manifest, because nothing was answering at 127.0.0.1:7233.
# That is the failure src/lib/readiness.js was written to remove, one level up.

# a. files good, engine down: exit 0 (the manifests ARE fine) and say so
OUT="$(TEMPORAL_ADDRESS=$DEAD $E validate "$CLEAN" 2>&1)"; RC=$?
check "a clean roster with no engine exits 0"       "[ $RC -eq 0 ]"
check "it does not claim run would refuse nothing"  "! said \"\$OUT\" 'nothing here .epito run .* would refuse'"
check "it says the manifests are ready"             "said \"\$OUT\" 'every manifest is ready; the engine is not'"
check "it names the address nothing answered at"    "said \"\$OUT\" \"nothing is answering at $DEAD\""
check "it names what run would do about it"         "said \"\$OUT\" 'refuses before it reads a seat'"
check "the fix is the command a laptop can run"     "said \"\$OUT\" 'temporal server start-dev'"
# A fix is only a fix if the reader has it. The sentence used to name HQ's
# runtime/temporal/install.sh, which is in neither this repository nor
# \`npm i -g epito-cli\`.
check "the fix names no file the reader lacks"      "! said \"\$OUT\" 'runtime/temporal/install.sh'"

# b. files good, engine up: the old sentence, now earned
OUT="$($E validate "$CLEAN" 2>&1)"
check "with something answering, run would refuse nothing" "said \"\$OUT\" 'nothing here .epito run .* would refuse'"
# What a TCP connect proves is that something accepted a connection. The stub
# behind $TEMPORAL_ADDRESS is not a Temporal server, and the wording has to stay
# true of it: \`epito run\` still does the real connect and the real namespace
# check, and still refuses an engine that answers and is the wrong one.
check "...and claims only that the address answers"        "said \"\$OUT\" 'is answering'"
check "...not that the engine is healthy or correct"       "! said \"\$OUT\" -iE 'engine is (up|healthy|running)'"

# c. --for-runtime is the flag whose whole contract is "what would run refuse"
OUT="$(TEMPORAL_ADDRESS=$DEAD $E validate "$CLEAN" --for-runtime 2>&1)"; RC=$?
check "--for-runtime with no engine exits 1"        "[ $RC -eq 1 ]"
check "...and says there is no runtime to accept it" "said \"\$OUT\" 'there is no runtime'"
# And it must not leave the operator thinking their files are broken: the
# manifests are the half a roster validator can answer with no box, and that
# user is who the command was built for.
check "...and says the manifests are not the problem" "said \"\$OUT\" 'The manifests are not the problem'"
check "...and names the form that answers that half"  "said \"\$OUT\" 'without --for-runtime says so'"
SOUT="$(TEMPORAL_ADDRESS=$DEAD $E validate "$CLEAN" --for-runtime 2>/dev/null)"
check "...and a refusal for the engine is on stderr too" "[ -z \"\$SOUT\" ]"
OUT="$($E validate "$CLEAN" --for-runtime 2>&1)"; RC=$?
check "--for-runtime with an engine answering exits 0" "[ $RC -eq 0 ]"

# d. both halves wrong: an operator hears both before they start
OUT="$(TEMPORAL_ADDRESS=$DEAD $E validate "$NR" --for-runtime 2>&1)"; RC=$?
check "a not-ready seat AND no engine exits 1"      "[ $RC -eq 1 ]"
check "...and names the seat that is not ready"     "said \"\$OUT\" '1 of 2 seats is not ready to run'"
check "...and the engine in the same breath"        "said \"\$OUT\" 'There is also no runtime to accept it'"
OUT="$(TEMPORAL_ADDRESS=$DEAD $E validate "$NR" 2>&1)"; RC=$?
check "without the flag that is still exit 0"       "[ $RC -eq 0 ]"
check "...and both halves are still said"           "said \"\$OUT\" 'the engine is not up either'"

# e. a malformed TEMPORAL_ADDRESS is a wrong variable, not a dead network
OUT="$(TEMPORAL_ADDRESS=garbage $E validate "$CLEAN" 2>&1)"; RC=$?
check "a malformed address still exits 0"           "[ $RC -eq 0 ]"
check "...and is reported as the variable it is"    "said \"\$OUT\" 'TEMPORAL_ADDRESS is \"garbage\", which is not a host:port address'"
check "...not as an engine that failed to answer"   "! said \"\$OUT\" 'nothing is answering at garbage'"
check "...and the fix names the fallback"           "said \"\$OUT\" 'unsetting it falls back to 127.0.0.1:7233'"

# f. the single-manifest form claims nothing about a roster or an engine, so it
#    must not have grown an engine line: it never promised one.
OUT="$(cd "$CLEAN/alpha" && TEMPORAL_ADDRESS=$DEAD $E validate 2>&1)"; RC=$?
check "one manifest with no engine exits 0"         "[ $RC -eq 0 ]"
check "...and says nothing about an engine"         "! said \"\$OUT\" -i 'temporal\|answering'"

step "11. \`epito init\`, the command before this one"
# The card is "init + validate error polish", and init is the first command
# anyone runs. It answered two ordinary filesystem conditions with a Node
# stack: a directory it could not write, and a `prompts` that was already a
# file. The second is the worse one, because init wrote agent.toml BEFORE it
# discovered it, so the reader got fourteen lines of EEXIST and a half-minted
# directory behind them.
I="$TMP/init"; mkdir -p "$I"

# a. a FILE where prompts/ goes: one sentence, and nothing written
mkdir -p "$I/prompts-is-a-file" && printf 'x' > "$I/prompts-is-a-file/prompts"
OUT="$(cd "$I/prompts-is-a-file" && $E init digest 2>&1)"; RC=$?
check "a file named prompts refuses, exit 1"        "[ $RC -eq 1 ]"
check "...naming the file and where the charter goes" "said \"\$OUT\" 'a FILE named prompts is already here'"
check "...with the fix in the message"              "said \"\$OUT\" 'Fix: rename or remove ./prompts'"
check "...and never a Node stack"                   "! said \"\$OUT\" 'at mkdirSync\|node:fs'"
check "...and it says nothing was written"          "said \"\$OUT\" 'Nothing was written'"
check "...which is true: no agent.toml"             "[ ! -e \"$I/prompts-is-a-file/agent.toml\" ]"
check "...and no .gitignore"                        "[ ! -e \"$I/prompts-is-a-file/.gitignore\" ]"

# b. a directory this user cannot write. Skipped as root, which can write it.
mkdir -p "$I/readonly" && chmod 500 "$I/readonly"
if [ "$(id -u)" -eq 0 ]; then
  printf '  skip an unwritable directory: this user is root and can write it anyway\n'
else
  OUT="$(cd "$I/readonly" && $E init digest 2>&1)"; RC=$?
  check "an unwritable directory refuses, exit 1"   "[ $RC -eq 1 ]"
  check "...naming the directory"                   "said \"\$OUT\" 'is not writable by this user'"
  check "...with a command the reader can run"      "said \"\$OUT\" 'mkdir ~/digest'"
  check "...and never a Node stack"                 "! said \"\$OUT\" 'at writeFileSync\|node:fs'"
fi
chmod 700 "$I/readonly"

# c. the name. Lower-casing is the one thing init does to what it was handed,
#    and it used to do it in silence.
mkdir -p "$I/cased"
OUT="$(cd "$I/cased" && $E init Historian 2>&1)"; RC=$?
check "a name with capitals still mints, exit 0"    "[ $RC -eq 0 ]"
check "...as the lower-case name"                   "grep -q 'name = \"historian\"' \"$I/cased/agent.toml\""
check "...and says so, rather than silently"        "said \"\$OUT\" 'the name was lower-cased'"
mkdir -p "$I/spaced"
OUT="$(cd "$I/spaced" && $E init 'My Agent!' 2>&1)"; RC=$?
check "a name with spaces refuses, exit 1"          "[ $RC -eq 1 ]"
check "...naming the rule in words, not a regex"    "said \"\$OUT\" 'lower-case letters, digits and hyphens'"
check "...and offering the name it would have"      "said \"\$OUT\" 'Fix: .epito init my-agent.'"
check "...and nothing was minted"                   "[ ! -e \"$I/spaced/agent.toml\" ]"
OUT="$(cd "$I/spaced" && $E init '!!!' 2>&1)"
check "a name with nothing to rescue offers no guess" "! said \"\$OUT\" 'Fix: .epito init'"
check "...and says what a name may be instead"      "said \"\$OUT\" 'Fix: pick a name'"

# d. twice in one directory: spec rule, one manifest one agent, plus the fix
OUT="$(cd "$I/cased" && $E init 2>&1)"; RC=$?
check "init twice refuses, exit 1"                  "[ $RC -eq 1 ]"
check "...on the rule: one manifest, one agent"     "said \"\$OUT\" 'one manifest, one agent'"
check "...and says what to do with the one here"    "said \"\$OUT\" 'epito validate. checks the one that is here'"

# e. and the alias says its own name back, not init's
mkdir -p "$I/alias"
OUT="$(cd "$I/alias" && $E me 'Bad Name' 2>&1)"
check "\`epito me\` refuses as \`epito me\`"          "said \"\$OUT\" 'Fix: .epito me bad-name.'"

step "12. a key the spec does not define: warned in two tables, refused in two"
# The lines below are not written for this suite. They are the two rows that
# cost alexandrapaiz/alexandra-systems' 41-manifest host roster its whole run
# on 2026-10-24, copied verbatim out of that roster's own files
# (test/fixtures/foreign-keys.json names the paths and line numbers). Both are
# ordinary words that look like fields epito might have, which is why their
# author wrote them and why a fixture invented here would have missed them.
#
# A roster runs whole or not at all, so one refusal was 41 manifests refused.
FK="$TMP/foreign"
seat "$FK/golf" golf "$REPO"
seat "$FK/hotel" hotel "$REPO"
# `status = "on"` into [agent] and `clock = "..."` into [trigger] of one seat.
node -e '
  const fs = require("fs"), f = process.argv[1];
  const rows = JSON.parse(fs.readFileSync(process.argv[2], "utf8")).keys;
  const at = (t) => rows.find((r) => r.table === t).line;
  fs.writeFileSync(f, fs.readFileSync(f, "utf8")
    .replace(/^(description = .*)$/m, `$1\n${at("agent")}`)
    .replace(/^(cron = .*)$/m, `$1\n${at("trigger")}`));
' "$FK/hotel/agent.toml" "$CLI/test/fixtures/foreign-keys.json"
check "the fixture lines are the ones in the file"  "grep -q '^status = \"on\"' \"\$FK/hotel/agent.toml\" && grep -q '^clock = ' \"\$FK/hotel/agent.toml\""

OUT="$($E validate "$FK" 2>&1)"; RC=$?
check "the roster is no longer refused over them"   "[ $RC -eq 0 ]"
check "...and the seat keeps its tick"              "said \"\$OUT\" '^✓ hotel '"
check "the [agent] key is named, by table and key"  "said \"\$OUT\" '⚠ .agent..status is not a field'"
check "the [trigger] key is named too"              "said \"\$OUT\" '⚠ .trigger..clock is not a field'"
check "...and says why it is not a refusal"         "said \"\$OUT\" 'warning, not a refusal'"
check "...with a fix the reader can act on"         "said \"\$OUT\" '⚠ .*Fix: drop the line'"
check "...and the spec version to check"            "said \"\$OUT\" \"v0.2's .agent. is: description, name\""
# A warning is not the old silence, and the count is what makes the ✓ and the
# ⚠ one verdict: `epito validate <dir> | tail` is how a forty-seat roster is
# read, and the per-seat lines have scrolled off by then.
check "the closing verdict counts them"             "said \"\$OUT\" '⚠ 2 keys in 1 manifest (hotel)'"
check "...and still blesses all of them"            "said \"\$OUT\" '✓ 2 of 2 manifests are agents'"

# The other half of the split, and the reason it is a split and not a
# loosening: a table whose fields mean something specific when ABSENT cannot
# afford an unread key — `max_turn = 50` ticked and then ran 120 turns.
RF="$TMP/foreign-runtime"
seat "$RF/india" india "$REPO"$'\n''status = "on"'
OUT="$($E validate "$RF" 2>&1)"; RC=$?
check "the same key in [runtime] is still refused"  "[ $RC -eq 1 ]"
check "...as a refusal, not a warning"              "said \"\$OUT\" '✗ .runtime..status is not a field'"
check "...and never as both"                        "! said \"\$OUT\" '⚠ .runtime..status'"

# The single-manifest form says the same thing in the same words, which is the
# rule section 2 holds the ✓ to, applied to the ⚠.
OUT="$(cd "$FK/hotel" && $E validate 2>&1)"; RC=$?
check "one manifest: exit 0 with the key warned"    "[ $RC -eq 0 ]"
check "...the same sentence as the roster form"     "said \"\$OUT\" '⚠ .agent..status is not a field'"
check "...and it says how many it saw"              "said \"\$OUT\" '2 keys here are not in spec v0.2'"

# ---------------------------------------------------------------------------
# The "smoke:" prefix is what test/all.sh greps for to tally a suite
# (run_suite's `tally=` line). Without it this suite ran 59 assertions and
# all.sh reported "unrun — nothing asserted", which is the harness being
# right: it cannot tell a suite that skipped from one that used a prefix it
# does not know. all.sh now says so when it happens.
printf '\nsmoke: %d ok, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ] || exit 1
