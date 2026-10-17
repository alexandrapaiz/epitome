#!/usr/bin/env bash
# The stranger path: is the README a guide somebody with only the package can
# follow? — cycle-2 bet "the stranger MVP", step 3 (the README walk-through)
# and step 4 (a gate so the claim cannot go stale silently).
#
#   bash test/stranger.sh        # from cli/  (also: npm run stranger-check)
#
# What a stranger has, exactly: `npm i -g epito` and the README that npm shows
# on the package page. No checkout of this repository, no issue tracker, no
# Slack, no docs/ directory, no decision log. Every other suite here runs from
# the checkout, which is why none of them can see the three ways that promise
# breaks:
#
#   1. the README prints a manifest that does not validate. A reader copies the
#      file off the front page, runs the command the next line tells them to
#      run, and is refused by the product on its own example. Found by this
#      script on its first run: the headline agent.toml had no
#      [runtime].entry, required since v0.1.
#   2. the README names a command, a flag or an install line that the package
#      does not have. Prose and code drift apart quietly; a flag that was
#      renamed leaves a README sentence that is now a lie, and nothing fails.
#   3. a user-facing line points at something only this repository holds — a
#      path like docs/deploy/README.md, or a decision by its number ("ADR-19")
#      — so the fix it names is one the reader cannot reach. The owner's rule
#      for everything she reads is the same rule: name a decision by what it
#      decides, never by its code; the codes stay inside the repo. `epito
#      --help` broke it four times on the front door.
#
# So this suite reads the README out of the TARBALL (what npm would serve) and
# drives the INSTALLED binary (what npm would install), from a working
# directory outside this repository. Nothing here touches the network except
# `npm install` of a local tarball, nothing touches an account, and no command
# that could reach GitHub is run without --dry-run.
set -uo pipefail

CLI="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT="${TMPDIR:-/tmp}/epito-stranger-$$"
PREFIX="$ROOT/prefix"; WORK="$ROOT/work"; TGZ_DIR="$ROOT/tgz"; PKG="$ROOT/unpacked"
E="$PREFIX/bin/epito"

pass=0; fail=0
ok()   { pass=$((pass+1)); printf '  ok   %s\n' "$1"; }
bad()  { fail=$((fail+1)); printf '  FAIL %s\n' "$1"; }
check(){ if eval "$2"; then ok "$1"; else bad "$1"; fi; }
step() { printf '\n== %s\n' "$1"; }

# Output is data: it goes to a file and every assertion greps the file. (The
# reason is pack.sh's — `epito token --dry-run` prints $EPITO_APP_ID_<NAME> and
# a <port> placeholder, which a `check` that interpolated output would hand to
# the shell to expand.)
OUT="$ROOT/out.txt"
RC=0
run_epito() { (cd "${CWD:-$WORK}" && "$E" "$@") >"$OUT" 2>&1; RC=$?; }
said()   { grep -q "$1" "$OUT"; }
shows()  { sed 's/^/      /' "$OUT" | head "${1:--3}"; }

cleanup() { rm -rf "$ROOT"; }
trap cleanup EXIT

mkdir -p "$PREFIX" "$WORK" "$TGZ_DIR" "$PKG"

# This suite is the other half of `prepublishOnly`, and the same thing was
# wrong with it: npm exports `npm_config_dry_run=true` into every lifecycle
# script, so under `npm publish --dry-run` the pack below wrote nothing and the
# whole stranger gate said SKIPPED and exited 0 — a page checked against
# nothing, on the command anybody careful runs first. test/pack.sh carries the
# long version of the note, the measurement, and the assertion that pins it;
# the rule is the same here. The flag leaves this suite's environment entirely
# (the pack AND the install of that tarball both inherited it), and a pack or
# an install that fails anyway refuses while this suite is a gate, and skips
# when a person ran it on a box whose npm is broken.
GATE=0
[ "${npm_command:-}" = "publish" ] && GATE=1
case "${npm_lifecycle_event:-}" in prepublishOnly|prepublish|prepare) GATE=1 ;; esac
unset npm_config_dry_run

nothing_to_check() {
  if [ "$GATE" = 1 ]; then
    printf 'stranger: FAILED — %s\n' "$1"
    printf '      This run IS the publish gate (npm_command=%s, npm_lifecycle_event=%s), so\n' \
      "${npm_command:-?}" "${npm_lifecycle_event:-?}"
    printf '      a page checked against nothing must stop the publish rather than pass it.\n'
    printf '      Fix: run `bash test/stranger.sh` on its own and fix what it says, then publish.\n'
    exit 1
  fi
  echo "stranger: SKIPPED — $1; nothing could be asserted"
  exit 0
}

# ------------------------------------------- 0. the package, as npm serves it
step "0: pack and install — the stranger's two artifacts, the README and the binary"
if ! (cd "$CLI" && npm pack --pack-destination "$TGZ_DIR") >"$ROOT/pack.log" 2>&1; then
  sed 's/^/       /' "$ROOT/pack.log" | tail -15
  nothing_to_check "\`npm pack\` failed in $CLI"
fi
TGZ="$(ls "$TGZ_DIR"/*.tgz 2>/dev/null | head -1)"
if [ -z "$TGZ" ]; then
  nothing_to_check "npm pack wrote no tarball"
fi
tar xzf "$TGZ" -C "$PKG"
README="$PKG/package/README.md"
PKGJSON="$PKG/package/package.json"
if [ ! -f "$README" ]; then
  echo "       (pack.sh asserts this too: \"a README ships — the npm page is not blank\".)"
  nothing_to_check "the tarball carries no README, so there is no guide to check"
fi
if ! (cd "$ROOT" && npm install -g --prefix "$PREFIX" "$TGZ") >"$ROOT/install.log" 2>&1; then
  sed 's/^/       /' "$ROOT/install.log" | tail -15
  nothing_to_check "installing the tarball failed"
fi
# The package's own name, read from the tarball rather than from this script:
# the install line on the front page has to be the line that installs THIS.
NAME="$(node -e 'console.log(JSON.parse(require("fs").readFileSync(process.argv[1],"utf8")).name)' "$PKGJSON")"

check "the README npm would show is in the tarball"  "[ -s '$README' ]"
check "the \`epito\` a stranger would run is installed" "[ -x '$E' ]"
printf '  README: %s lines, read from the tarball; binary: %s\n' \
  "$(wc -l < "$README" | tr -d ' ')" "$E"

# What this suite cannot prove, said out loud rather than implied. Everything
# below checks the package THIS tree would publish; whether anybody can
# actually install it is one `npm publish` away and that step is the owner's
# (an npm account for the name, and NPM_TOKEN). A green run here while the
# registry has no `epito` means the page is followable, not that it is
# reachable — exactly the distinction the cycle-2 pitch rests on, so it is
# printed every time and asserted never: a suite must not fail because of a
# registry it has no business reaching.
PUBLISHED="$(npm view "$NAME" version 2>/dev/null | tail -1)"
if [ -n "$PUBLISHED" ]; then
  printf '  the registry has %s@%s — a stranger can install this today\n' "$NAME" "$PUBLISHED"
else
  printf '  NOTE: the registry has no `%s` (or could not be reached from here), so this\n' "$NAME"
  printf '        suite proves the page against the package this tree WOULD publish, not\n'
  printf '        against one anybody can install. Publishing is owner-only.\n'
fi

# The commands and aliases the installed CLI admits to having. Both sides of
# every assertion below come out of the shipped package: the README is checked
# against the binary beside it, never against a list kept in this file, because
# a list kept here goes stale in the same silence the README does.
"$E" --help > "$ROOT/help.txt" 2>&1
grep -oE '^  epito [a-z][a-z-]*' "$ROOT/help.txt" | awk '{print $2}' | sort -u > "$ROOT/cmds.txt"
grep -oE 'alias: epito [a-z][a-z-]*' "$ROOT/help.txt" | awk '{print $3}' | sort -u >> "$ROOT/cmds.txt"
sort -u -o "$ROOT/cmds.txt" "$ROOT/cmds.txt"
check "the installed CLI lists its own commands, so the README has something to be checked against" \
  "[ $(wc -l < "$ROOT/cmds.txt") -ge 10 ]"

# Every option each of those commands takes, in the command's own words. The
# refusal of an unknown option prints the real list, and it prints it BEFORE
# the command does anything — which is the property pack.sh pins ("reaches no
# network and no key"), and the reason this is safe to run for `deploy`.
: > "$ROOT/flags.txt"
while read -r c; do
  "$E" "$c" --epito-stranger-gate-no-such-option >"$ROOT/opt-$c.txt" 2>&1
  grep -oE '^  --[a-z][a-z-]*' "$ROOT/opt-$c.txt" | tr -d ' ' | sort -u > "$ROOT/flags-$c.txt"
  sed "s/^/$c /" "$ROOT/flags-$c.txt" >> "$ROOT/flags.txt"
done < "$ROOT/cmds.txt"
awk '{print $2}' "$ROOT/flags.txt" | sort -u > "$ROOT/flags-any.txt"

# And the options that belong to no command: `epito --version` is written on
# the page exactly that way, with a dash where the command goes, so the two
# readers above both miss it — the command reader wants `epito <word>` and the
# option reader has no command to attribute it to. Without this the page could
# promise a top-level flag the binary does not have, which is the one class of
# README lie section 2 exists to catch. They come out of the help text the same
# way the commands do, and each one is RUN, because a flag the help lists and
# the dispatcher never reaches is the same lie one step further in.
grep -oE '^  epito --[a-z][a-z-]*' "$ROOT/help.txt" | awk '{print $2}' | sort -u > "$ROOT/top-flags.txt"
cat "$ROOT/top-flags.txt" >> "$ROOT/flags-any.txt"
sort -u -o "$ROOT/flags-any.txt" "$ROOT/flags-any.txt"
printf '  the binary admits to %s commands, %s distinct options, and %s before any command (%s)\n' \
  "$(wc -l < "$ROOT/cmds.txt" | tr -d ' ')" "$(grep -c . "$ROOT/flags-any.txt" | tr -d ' ')" \
  "$(grep -c . "$ROOT/top-flags.txt" | tr -d ' ')" "$(tr '\n' ' ' < "$ROOT/top-flags.txt" | sed 's/ $//')"
dead_top=""
while read -r f; do
  [ -n "$f" ] || continue
  run_epito "$f" || true
  [ "$RC" = 0 ] || dead_top="$dead_top $f"
done < "$ROOT/top-flags.txt"
check "every top-level flag the help lists is one the binary answers" \
  "[ -z '$dead_top' ] || { printf '       the help lists%s and the dispatcher refuses it\n' '$dead_top'; false; }"

# ------------------------------------- 1. the manifests the README prints
step "1: every manifest the README prints validates — it is a file people copy"
blocks=0
mkdir -p "$ROOT/blocks"
awk -v dir="$ROOT/blocks" '
  /^```toml/ { n++; f = 1; next }
  /^```/     { f = 0; next }
  f          { print >> (dir "/block-" n ".toml") }
' "$README"
for b in "$ROOT/blocks"/block-*.toml; do
  [ -f "$b" ] || continue
  # A catalogue of fields is not a file to copy and is not asserted as one;
  # the spec document says so about its own. A block with [agent] in it is
  # presenting itself as a whole manifest, which is the thing a reader copies.
  grep -q '^\[agent\]' "$b" || continue
  blocks=$((blocks+1))
  d="$ROOT/copy-$blocks"; mkdir -p "$d"
  cp "$b" "$d/agent.toml"
  CWD="$d" run_epito validate; shows -4
  check "the README's manifest #$blocks validates from the installed binary, exit 0" \
    "[ $RC = 0 ] && said '✓'"
  # And it validates for the runtime too, if it sets [runtime].repo — a front
  # page that prints a manifest and then `epito deploy` under it is promising
  # the deploy will take this file.
  if grep -q '^repo *=' "$d/agent.toml"; then
    CWD="$d" run_epito validate --for-runtime; shows -4
    check "...and the runtime would take it: it sets [runtime].repo, so the page's \`epito deploy\` is true" \
      "[ $RC = 0 ]"
  fi
done
check "the README prints at least one copyable manifest" "[ $blocks -ge 1 ]"

# --------------------------------- 2. the commands and options it names
step "2: every command and option the README names, the package has"
# `epito <word>` as the README actually writes it: anywhere inside a code
# block, and inside a code span everywhere else. The distinction is not
# pedantry — the prose line "None of them touches the executable / epito
# spawns" starts a line with the word, and a first draft of this script
# reported `epito spawns` as a command the package was missing. Prose is prose;
# a claim about a command is made in code.
awk '
  /^```/ { fence = !fence; next }
  {
    if (fence) { line = $0 } else { line = ""; n = split($0, part, "`"); for (i = 2; i <= n; i += 2) line = line " " part[i] }
    while (match(line, /epito [a-z][a-z-]*/)) {
      print substr(line, RSTART + 6, RLENGTH - 6)
      line = substr(line, RSTART + RLENGTH)
    }
  }
' "$README" | sort -u > "$ROOT/readme-cmds.txt"
unknown_cmds=""
while read -r c; do
  [ -n "$c" ] || continue
  grep -qx "$c" "$ROOT/cmds.txt" || unknown_cmds="$unknown_cmds $c"
done < "$ROOT/readme-cmds.txt"
printf '  the README names: %s\n' "$(tr '\n' ' ' < "$ROOT/readme-cmds.txt")"
check "no command on the page is missing from the package" \
  "[ -z '$unknown_cmds' ] || { printf '       the README names epito%s, which the installed CLI does not have\n' '$unknown_cmds'; false; }"

# Options, attributed to the command they are written beside. A token stream
# per line: `epito X` sets the command, `--y` after it belongs to X, and a line
# that names a flag with no command before it (most of the prose) is checked
# against every option the package has instead.
awk '
  { cur = "" }
  {
    n = split($0, t, /[[:space:]]+/)
    for (i = 1; i <= n; i++) {
      tok = t[i]
      gsub(/[`",.;:()]/, "", tok)
      if (tok == "epito" && i < n) {
        nxt = t[i+1]; gsub(/[`",.;:()]/, "", nxt)
        if (nxt ~ /^[a-z][a-z-]*$/) cur = nxt
        continue
      }
      if (tok ~ /^--[a-z][a-z-][a-z-]+$/) print (cur == "" ? "-" : cur), tok
    }
  }
' "$README" | sort -u > "$ROOT/readme-flags.txt"
bad_flags=""
while read -r c f; do
  [ -n "$f" ] || continue
  if [ "$c" = "-" ]; then
    grep -qx -- "$f" "$ROOT/flags-any.txt" || bad_flags="$bad_flags $f"
  else
    # A flag written beside a command the package does not know is already
    # reported above; do not report it twice.
    grep -qx "$c" "$ROOT/cmds.txt" || continue
    grep -qx -- "$f" "$ROOT/flags-$c.txt" || bad_flags="$bad_flags $c/$f"
  fi
done < "$ROOT/readme-flags.txt"
printf '  %s option mentions, %s of them beside a named command\n' \
  "$(wc -l < "$ROOT/readme-flags.txt" | tr -d ' ')" \
  "$(grep -cv '^- ' "$ROOT/readme-flags.txt" | tr -d ' ')"
check "every option the README names is one its command takes" \
  "[ -z '$bad_flags' ] || { printf '       not an option of the command it is written beside:%s\n' '$bad_flags'; false; }"

# The other direction, for the one table the page speaks for in full. Checking
# that everything on the page exists in the package catches a rename; it does
# not catch the page going quiet about something the package GREW, and that is
# the way this README actually went stale: spec v0.2 added a third way to wake
# an agent (`[trigger].subscriptions`, the bus) and the page kept saying there
# were two, in the headline manifest and again in "What it gives an agent".
#
# It is asserted for `[trigger]` and not for all four tables because the page
# makes a different promise about each. `[runtime]` it covers by example and
# sends you to the spec for the rest; `[trigger]` it enumerates — "cron ...
# and/or webhook" — which is a claim to be complete, and the headline sentence
# ("identity + trigger + runtime") is why a reader believes it. A field this
# table gains and the page does not mention is a reader who cannot know their
# agent could have been woken.
#
# The catalogue comes out of the binary, like everything else here: the
# validator prints the whole table when it refuses a misspelling, so a
# misspelled field is how the package is asked what fields it has.
step "2b: every way the package can wake an agent is on the page"
CAT="$ROOT/catalogue"; mkdir -p "$CAT"
cat > "$CAT/agent.toml" <<'TOML'
[agent]
name = "catalogue"
description = "One misspelled trigger field, so the binary prints the table it knows."
[identity]
scopes = ["github:contents"]
[trigger]
cron = "0 6 * * *"
zzqq = true
[runtime]
entry = "prompts/catalogue.md"
model = "claude-sonnet-5"
TOML
CWD="$CAT" run_epito validate
sed -n 's/.*\[trigger\] is: \([^.]*\)\..*/\1/p' "$OUT" | tr -d ' ' | tr ',' '\n' | grep -v '^$' | sort -u > "$ROOT/trigger-fields.txt"
printf '  the package wakes an agent by: %s\n' "$(tr '\n' ' ' < "$ROOT/trigger-fields.txt")"
# If the refusal ever stops printing the catalogue, this suite must say it
# asserted nothing about the page rather than tick a check it did not make.
check "the binary names the fields its [trigger] has, so the page can be checked against them" \
  "[ $(wc -l < "$ROOT/trigger-fields.txt") -ge 2 ]"
missing_fields=""
while read -r f; do
  [ -n "$f" ] || continue
  grep -q "$f" "$README" || missing_fields="$missing_fields $f"
done < "$ROOT/trigger-fields.txt"
check "every [trigger] field the package has is named on the page" \
  "[ -z '$missing_fields' ] || { printf '       the package reads [trigger]%s and the README never says so\n' '$missing_fields'; false; }"

# ------------------------------------------- 3. the install lines are true
step "3: the install lines on the page install this package"
check "the front page's install line names the package itself" \
  "grep -qE 'npm i(nstall)? -g (.*[[:space:]])?$NAME([[:space:]]|$)' '$README'"
# The engine is an optional peer, and the README is the only place the install
# line for it exists. A fifth peer added to package.json with no README edit
# would leave a line that installs three quarters of an engine.
node -e '
  const fs = require("fs");
  const pkg = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
  const readme = fs.readFileSync(process.argv[2], "utf8");
  const optional = Object.entries(pkg.peerDependenciesMeta || {})
    .filter(([, v]) => v && v.optional).map(([k]) => k);
  const missing = optional.filter((p) => !readme.includes(p));
  console.log(optional.length ? `optional peers: ${optional.length}` : "no optional peers");
  console.log(missing.length ? `MISSING: ${missing.join(" ")}` : "all named in the README");
' "$PKGJSON" "$README" > "$OUT" 2>&1
shows -2
check "every optional peer package.json declares is named in the README" "! said '^MISSING'"

# --------------------------- 4. no user-facing line points where a stranger cannot go
step "4: nothing user-facing names a decision by its code or a path only this repo holds"
# The rule, in the owner's words: name a decision by what it decides, never by
# its number. It binds everything she reads, and the npm page and `epito
# --help` are read by everyone else too. The same line is also simply broken
# for a reader with no checkout: "see ADR-16 (docs/decisions.md)" names a fix
# with no page to find it, which is the one thing `epito validate`'s error bar
# forbids.
#
# A path this repository holds may be named when it comes with WHERE this
# repository is — that is a reference a reader can follow; a bare path is not.
codes() { grep -nE 'ADR-[0-9]+|\bL-[0-9]+|\bincident [0-9]+' "$1"; }
# The locator is looked for in the line's NEIGHBOURHOOD, not on the line: prose
# wraps, and "`deploy/provision-host.sh` in / [this repository](https://...)"
# across two lines is a perfectly good reference that a line-at-a-time rule
# would have called a violation — which it did, on this script's own second
# run. `prompts/` is excluded where it is the READER's charter path (the
# scaffold writes prompts/<name>.md into their repository, not ours).
bare_paths() {
  awk '
    { line[NR] = $0 }
    END {
      for (i = 1; i <= NR; i++) {
        if (line[i] !~ /(docs|spec|deploy|cli)\/[A-Za-z0-9._\/-]+\.(md|sh|yml|json)/) continue
        near = line[i-1] " " line[i] " " line[i+1]
        if (near ~ /github\.com/) continue
        printf "%d:%s\n", i, line[i]
      }
    }
  ' "$1"
}
for surface in "$README:the npm page" "$ROOT/help.txt:epito --help"; do
  f="${surface%%:*}"; label="${surface##*:}"
  c="$(codes "$f" || true)"; p="$(bare_paths "$f" || true)"
  check "$label names no decision by its code" \
    "[ -z \"\$(codes '$f' || true)\" ] || { codes '$f' | sed 's/^/       /'; false; }"
  check "$label names no path without saying where this repository is" \
    "[ -z \"\$(bare_paths '$f' || true)\" ] || { bare_paths '$f' | sed 's/^/       /'; false; }"
done
# The refusals too: a message naming the fix is exactly where an unreachable
# reference costs most, and the engine-missing and env-template lines are the
# two a stranger meets first.
cat "$ROOT"/opt-*.txt > "$ROOT/refusals.txt"
CWD="$WORK" run_epito init stranger >/dev/null 2>&1
CWD="$WORK" run_epito run . ; cat "$OUT" >> "$ROOT/refusals.txt"
CWD="$WORK" run_epito env . ; cat "$OUT" >> "$ROOT/refusals.txt"
check "the refusals a stranger meets name no decision by its code" \
  "[ -z \"\$(codes '$ROOT/refusals.txt' || true)\" ] || { codes '$ROOT/refusals.txt' | sed 's/^/       /'; false; }"
check "...and no path without saying where this repository is" \
  "[ -z \"\$(bare_paths '$ROOT/refusals.txt' || true)\" ] || { bare_paths '$ROOT/refusals.txt' | sed 's/^/       /'; false; }"

# ------------------------------- 5. the walk-through itself, in the page's order
step "5: the page's own sequence, run from the installed binary with no checkout in reach"
# This is the README's quickstart block, in order, from a directory that is not
# in this repository and has no git origin — the state a reader is in. `epito
# deploy` is the one line that cannot be run as printed (it opens a browser and
# creates a real App on a real account), so it runs with the --dry-run the same
# page documents, which reaches neither.
WALK="$ROOT/walk"; mkdir -p "$WALK"
# The page's first two lines are the install and `epito --version`, which is
# what everybody types to find out whether the install took. It used to answer
# `unknown command "--version"` — a sentence that reads as a broken install
# rather than a missing flag — so the walk starts where the reader does.
CWD="$WALK" run_epito --version; shows -1
check "\`epito --version\` answers, as the page's second line says it does" "[ $RC = 0 ]"
check "...with the version npm would serve, not a number kept in the source" \
  "said \"\$(node -e 'console.log(JSON.parse(require(\"fs\").readFileSync(process.argv[1],\"utf8\")).version)' '$PKGJSON')\""
check "...and the manifest spec that version enforces, which the page also names" \
  "said 'manifest spec v'"
CWD="$WALK" run_epito init historian; shows -3
check "\`epito init historian\` works outside this repository, exit 0" \
  "[ $RC = 0 ] && [ -f '$WALK/agent.toml' ]"
check "...and scaffolds the charter the manifest points at" \
  "[ -f '$WALK/prompts/historian.md' ]"
CWD="$WALK" run_epito validate; shows -4
check "\`epito validate\` ticks the scaffold, exit 0" "[ $RC = 0 ] && said '✓'"
check "...and, with no git origin here, says what the runtime still needs" \
  "said 'not ready to run' && said 'repo = \"owner/name\"'"
# The page says the fix in those words; a reader applies it and moves on.
printf 'repo = "acme/roster"\n' >> "$WALK/agent.toml"
CWD="$WALK" run_epito validate
check "...and the note is gone once the reader applies the fix the page prints" \
  "[ $RC = 0 ] && ! said 'not ready to run'"
CWD="$WALK" run_epito deploy --dry-run; shows -3
check "\`epito deploy --dry-run\` accepts the scaffold" "[ $RC = 0 ] && said 'would deploy'"
check "...asking GitHub for exactly the scopes the manifest declares" \
  "said 'contents' && ! said 'admin'"
CWD="$WALK" run_epito token historian . --dry-run; shows -3
check "\`epito token --dry-run\` says what it would mint, touching no key" "[ $RC = 0 ]"
CWD="$WALK" run_epito audit; shows -2
check "\`epito audit\` answers in a directory with no ledger yet, exit 0" "[ $RC = 0 ]"
CWD="$WALK" run_epito run .; shows -3
check "\`epito run\` — the one command that needs the engine — refuses in epito's voice" \
  "[ $RC = 1 ] && said '^epito:' && ! said 'ERR_MODULE_NOT_FOUND'"
check "...naming the package and the install line the page also names" \
  "said '@temporalio/' && said 'Fix: npm i -g @temporalio/'"

printf '\nstranger: %d ok, %d failed\n' "$pass" "$fail"
[ "$fail" = 0 ] || exit 1
