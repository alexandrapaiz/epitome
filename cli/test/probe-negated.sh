#!/usr/bin/env bash
# The second half of the quiet-pipe fault, measured rather than quoted.
#
#   bash test/probe-negated.sh            # from cli/
#
# test/probe-pipefail.sh measures the half everyone found first: a POSITIVE
# gate, `producer | grep -q pattern`, printing FAIL for a pattern it matched,
# because quiet grep exits on its first match and the producer dies writing
# into the pipe it just closed. That one fires only above the 64 KiB pipe
# buffer, and the suites write hundreds of bytes.
#
# A NEGATED gate — `! producer | grep -q pattern` — has a second way to be
# wrong, and this one needs no buffer and no race: if the PRODUCER fails, the
# pipeline's status is its failure, and `!` turns that failure into success. The
# gate prints `ok`, having read nothing at all. Every reason a reader can fail
# counts: bad input, a missing binary, a thrown exception.
#
# smoke-doctor.sh had five of those reading `jq_refusals`, a helper that parses
# `epito doctor --json` in node and throws on anything that is not a document.
# So the assertion "no identity refusal reached the verdict" passed in exactly
# two cases: no refusal reached it, and the refusals were never read.
#
# The input is not written here. It is this product's own `--json`, taken live
# from the roster in this repository and cut off mid-document, because a
# producer killed mid-write is what leaves a truncated document and a reader
# written against invented input proves nothing about the real one. The helper
# below is copied out of test/smoke-doctor.sh and kept copied: if it changes
# there, re-run this.
#
# This file deliberately carries the shape, because exhibiting it is the
# subject. test/shapes.sh allows it exactly what it has — one executed, and one
# inside the `printf` that labels it for the reader.
set -uo pipefail
CLI="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROSTER="$CLI/../agents"

jq_refusals() { printf '%s' "$1" | node -e 'const r=JSON.parse(require("fs").readFileSync(0,"utf8"));console.log(r.refusals.map(x=>x.says).join("\n"))'; }
said_in() { local hay="$1"; shift; grep -q "$@" <<<"$hay"; }

printf '\n== a negated gate whose reader died, both ways of writing it\n\n'

FULL="$(node "$CLI/src/index.js" doctor "$ROSTER" --json 2>&1)" || true
if ! printf '%s' "$FULL" | node -e 'const s=require("fs").readFileSync(0,"utf8");JSON.parse(s)' 2>/dev/null; then
  printf '  SKIPPED -- `epito doctor --json` did not return a document on this box, so there is\n'
  printf '  nothing real to truncate. Run `npm ci` in %s first.\n' "$CLI"
  printf '  what it said: %s\n' "$(printf '%s' "$FULL" | head -2 | tr '\n' ' ')"
  exit 0
fi
# Cut it where a write would have been cut: at a round number of bytes, mid-key.
TRUNC="$(printf '%s' "$FULL" | head -c 512)"
printf '  the input: %s bytes of real `epito doctor --json` on this repository'"'"'s own\n' "$(printf '%s' "$FULL" | wc -c)"
printf '  roster, cut to %s — the last line of it, as the reader receives it:\n' "$(printf '%s' "$TRUNC" | wc -c)"
printf '    %s\n\n' "$(printf '%s' "$TRUNC" | tail -1)"

jq_refusals "$TRUNC" >/dev/null 2>&1
printf '  the reader, asked directly: jq_refusals on that exits %d\n\n' $?

printf '  old shape:  ! jq_refusals "$X" | grep -q %s\n' "'installation\\|mint'"
if ! jq_refusals "$TRUNC" 2>/dev/null | grep -q 'installation\|mint'; then
  printf '    -> ok   no identity refusal reached the verdict   <-- WRONG, none was read\n'
  OLD=wrong
else
  printf '    -> FAIL no identity refusal reached the verdict\n'
  OLD=right
fi

printf '\n  this shape: rf=$(jq_refusals "$X") && ! said_in "$rf" %s\n' "'installation\\|mint'"
if rf=$(jq_refusals "$TRUNC" 2>/dev/null) && ! said_in "$rf" 'installation\|mint'; then
  printf '    -> ok   no identity refusal reached the verdict\n'
  NEW=wrong
else
  printf '    -> FAIL no identity refusal reached the verdict   <-- correct, the reader died\n'
  NEW=right
fi

printf '\n-----------------------------------------------\n'
if [ "$OLD" = wrong ] && [ "$NEW" = right ]; then
  printf 'probe-negated: the fault reproduces, and the conversion closes it\n'
else
  printf 'probe-negated: NOT what this box did — old=%s new=%s. Say so wherever this is cited.\n' "$OLD" "$NEW"
  exit 1
fi
