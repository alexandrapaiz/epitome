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
# It needs nothing: no engine, no network, no account, no credential. That is
# the card. `epito run <dir> --dry-run` was the only command that read a roster
# whole and it connects to Temporal first, so an operator with five manifests
# and no box had no way to hear "yes" (docs/ideas.md raised it twice while the
# real roster was being written).
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
set -uo pipefail

CLI="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="${TMPDIR:-/tmp}/epito-validate-smoke-$$"
E="node $CLI/src/index.js"

pass=0; fail=0
ok()   { pass=$((pass+1)); printf '  ok   %s\n' "$1"; }
bad()  { fail=$((fail+1)); printf '  FAIL %s\n' "$1"; }
check(){ if eval "$2"; then ok "$1"; else bad "$1"; fi; }
step() { printf '\n== %s\n' "$1"; }
cleanup() { if [ -n "${EPITO_SMOKE_KEEP:-}" ]; then printf '\nkept: %s\n' "$TMP"; else rm -rf "$TMP"; fi; }
trap cleanup EXIT
mkdir -p "$TMP"

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
check "it counts the manifests"                 "printf '%s' \"\$OUT\" | grep -q '3 of 3 manifests are agents'"
check "it separates cronned from presence-only" "printf '%s' \"\$OUT\" | grep -q '2 on a cron, 1 presence-only (charlie)'"
check "it names the presence-only seat"          "printf '%s' \"\$OUT\" | grep -q 'presence-only (charlie)'"
check "it says the roster would not be refused" "printf '%s' \"\$OUT\" | grep -q 'nothing here .epito run .* would refuse'"
check "a clean roster says nothing on stderr"   "[ -z \"\$ERR\" ]"
# A roster beside or above the cwd relativises to a ladder of ".." — harder to
# read and harder to paste than the path it came from. $CLEAN is under TMPDIR
# and this runs from cli/, so a naive relative() would print ../../../tmp/...
AWAY="$(cd "$CLI" && $E validate "$CLEAN" 2>&1)"
check "a roster outside the cwd is named, not laddered" "! printf '%s' \"\$AWAY\" | grep -q '\.\./'"
check "...and it is still the same verdict"             "printf '%s' \"\$AWAY\" | grep -q '3 of 3 manifests are agents'"
check "...and it needed no engine to say it"    "! printf '%s' \"\$OUT\" | grep -qi 'temporal'"

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
check "it names the refused file by path"        "printf '%s' \"\$OUT\" | grep -q 'delta/agent.toml — '"
check "it counts the refusal against the roster" "printf '%s' \"\$OUT\" | grep -q '1 of 4 manifests refused'"
check "it says why a roster is all-or-nothing"   "printf '%s' \"\$OUT\" | grep -q 'a roster runs whole or not at all'"
check "the three good seats are still reported"  "[ \$(printf '%s\n' \"\$OUT\" | grep -c '^✓ ') -eq 3 ]"
check "every problem in the bad one is named"    "[ \$(printf '%s\n' \"\$OUT\" | grep -c '    ✗ ') -ge 4 ]"
check "the bad cron is named as a schedule"      "printf '%s' \"\$OUT\" | grep -q 'is not a schedule the runtime can register'"
# Only the ✓/! rows are padded, so only they may set the column. A refused
# manifest is named by its PATH, and letting that path set the width pushed
# every good seat's description most of the way across the terminal — the
# longest seat name here is "charlie" (7), so a padded ✓ row is at most
# "✓ " + 7 + 2 = 11 characters before its description starts.
COL="$(printf '%s\n' "$OUT" | grep -E '^✓ ' | head -1 | awk '{ i = index($0, "identity"); print i }')"
check "a long refused path does not set the column" "[ \"\$COL\" -le 12 ]"

step "4. two manifests, one [agent].name — spec rule 4"
DUP="$TMP/dup"; mkdir -p "$DUP"
seat "$DUP/first"  twin "$REPO"
seat "$DUP/second" twin "$REPO"
OUT="$($E validate "$DUP" 2>&1)"; RC=$?
check "a duplicate name refuses the roster"      "[ $RC -eq 1 ]"
check "it names the rule in the spec's words"    "printf '%s' \"\$OUT\" | grep -q 'one manifest, one principal'"
check "it names the file that claimed it first"  "printf '%s' \"\$OUT\" | grep -q 'first/agent.toml'"
check "the first copy is not itself refused"     "printf '%s' \"\$OUT\" | grep -q '1 of 2 manifests refused'"
# A refusal, not a note: no --for-runtime needed to hear that two seats are
# asking for one identity.
OUT="$($E validate "$DUP" 2>&1)"
check "it refuses without --for-runtime"         "printf '%s' \"\$OUT\" | grep -q 'manifests refused'"

step "5. the severity split: no [runtime].repo is a note by default, an error strictly"
NR="$TMP/notready"; mkdir -p "$NR"
seat "$NR/echo" echo ""          # valid v0.1, and `epito run` would refuse it
seat "$NR/foxtrot" foxtrot "$REPO"
OUT="$($E validate "$NR" 2>&1)"; RC=$?
check "a valid-but-not-ready roster exits 0"     "[ $RC -eq 0 ]"
check "the seat is marked ! and not ✗"           "printf '%s' \"\$OUT\" | grep -q '^! echo '"
check "it is still called a valid manifest"      "printf '%s' \"\$OUT\" | grep -q 'valid, not ready to run'"
check "the note carries a fix"                   "printf '%s' \"\$OUT\" | grep -q 'Fix: add repo = \"owner/name\"'"
# The fix is an instruction, so it has to name the file the way the reader
# would type it. findManifests returns absolute paths, and before `as` was
# threaded through checkManifest the fix for a seat in agents/okr named a path
# nobody had typed.
NROUT="$(cd "$TMP" && $E validate notready 2>&1)"
check "the fix names the path as typed"          "printf '%s' \"\$NROUT\" | grep -q 'in notready/echo/agent.toml'"
check "...not an absolute path nobody typed"     "! printf '%s' \"\$NROUT\" | grep -q 'Fix: add repo.*in /'"
check "it points at the flag that is stricter"   "printf '%s' \"\$OUT\" | grep -q -- '--for-runtime. to make those an error'"
OUT="$($E validate "$NR" --for-runtime 2>&1)"; RC=$?
check "--for-runtime makes the same note fail"   "[ $RC -eq 1 ]"
check "...and says it is the runtime's question" "printf '%s' \"\$OUT\" | grep -q 'whether the runtime would accept this roster, and it would not'"
check "...and counts the seats that are not"     "printf '%s' \"\$OUT\" | grep -q '1 of 2 seats is not ready to run'"

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
  before="$(cd "$d" && find . | sort | md5sum 2>/dev/null || true)"
  $E validate "$d" >/dev/null 2>&1
  $E validate "$d" --for-runtime >/dev/null 2>&1
  after="$(cd "$d" && find . | sort | md5sum 2>/dev/null || true)"
  check "$(basename "$d"): no file created or removed" "[ \"\$before\" = \"\$after\" ]"
  check "$(basename "$d"): no .epito/ appeared"        "[ ! -e \"$d/.epito\" ]"
done
check "nor in the directory validate was run from"     "[ ! -e .epito ]"

step "9. the arguments it does not take, and the ones it does"
OUT="$($E validate "$TMP/nope-not-here" 2>&1)"; RC=$?
check "a path that does not exist exits 1"       "[ $RC -eq 1 ]"
check "...and names both forms it does take"     "printf '%s' \"\$OUT\" | grep -q 'a directory of manifests (the whole roster) or one agent.toml'"
mkdir -p "$TMP/vacant"
OUT="$($E validate "$TMP/vacant" 2>&1)"; RC=$?
check "an empty directory exits 1"               "[ $RC -eq 1 ]"
check "...and says an empty roster has nothing"  "printf '%s' \"\$OUT\" | grep -q 'an empty roster has nothing to validate'"
check "...with the fix a vibecoder can act on"   "printf '%s' \"\$OUT\" | grep -q 'epito init <name>'"
OUT="$($E validate "$CLEAN/alpha/agent.toml" 2>&1)"; RC=$?
check "a named manifest file validates, exit 0"  "[ $RC -eq 0 ] && printf '%s' \"\$OUT\" | grep -q '✓ alpha is an agent'"
OUT="$(cd "$TMP/vacant" && $E validate 2>&1)"; RC=$?
check "no manifest in the cwd still says init"   "[ $RC -eq 1 ] && printf '%s' \"\$OUT\" | grep -q 'no agent.toml here'"
check "...and now also names the roster form"    "printf '%s' \"\$OUT\" | grep -q 'epito validate <dir>'"
OUT="$($E validate "$CLEAN" --for-runtimes 2>&1)"; RC=$?
check "a misspelled flag is refused, not ignored" "[ $RC -eq 1 ] && printf '%s' \"\$OUT\" | grep -q 'Did you mean --for-runtime'"

# ---------------------------------------------------------------------------
printf '\n%d ok, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ] || exit 1
