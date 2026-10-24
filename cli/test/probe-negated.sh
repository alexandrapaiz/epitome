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
# The haystack below is what a doctor run that died mid-write leaves — a
# truncated document — because that is the shape the fault itself produces.
# The helper is copied out of test/smoke-doctor.sh and kept copied: if it
# changes there, this probe should be re-run against the new one.
#
# This file deliberately carries one occurrence of the shape, because
# exhibiting it is the subject. test/shapes.sh allows it exactly one.
set -uo pipefail

jq_refusals() { printf '%s' "$1" | node -e 'const r=JSON.parse(require("fs").readFileSync(0,"utf8"));console.log(r.refusals.map(x=>x.says).join("\n"))'; }
said_in() { local hay="$1"; shift; grep -q "$@" <<<"$hay"; }

TRUNC='{"seats":[{"agent":"plain","identity":{"state":"own"}}],"refu'

printf '\n== a negated gate whose reader died, both ways of writing it\n\n'
jq_refusals "$TRUNC" >/dev/null 2>&1
printf '  the reader, asked directly: jq_refusals on a truncated document exits %d\n\n' $?

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
