#!/usr/bin/env bash
# Three readers, one captured output: which half of a flaky assertion moves.
#
#   bash test/probe-readers.sh                    # from cli/: all three loops
#   bash test/probe-readers.sh --sizes            # the third loop only, no engine
#   READERS_FIXED=4000 READERS_FRESH=40 bash test/probe-readers.sh
#
# docs/ideas.md carries a row for a family of intermittent failures in this
# repository's suites: an assertion reports the product broken, the assertion
# above it reads the same captured output and passes, and the suite run alone
# on the same commit is green. Its author could not establish which half moved
# — the PRODUCT not printing the sentence, or the READER not seeing it — and
# that is the whole question, because one of those is a bug in epito and the
# other is a bug in a test helper.
#
# smoke-doctor.sh's instance of the family is section 5's worker row, which has
# failed once per run on this box for three runs, a different assertion each
# time. This probe takes that section's own scenario — a port that accepts a
# TCP connection and speaks no gRPC, so the engine row refuses and the worker
# row reports the question it could not put — and asks three readers the same
# bytes:
#
#   the pipe        printf '%s' "$out" | grep -qF -e "$N"     the shape before
#   the herestring  grep -qF -e "$N" <<<"$out"                the shape after
#   bash itself     [[ $out == *"$N"* ]]                       no fork at all
#
# Three loops, because they answer different halves. The FIXED loop asks all
# three of one capture, over and over: every disagreement there is a reader's,
# since the bytes cannot change. The FRESH loop runs the product again for each
# iteration: a capture that no reader finds the sentence in is the product's own
# variation, and it prints the row it got instead.
#
# This file deliberately carries the pipe shape, because comparing it is the
# subject; test/shapes.sh allows it exactly what it has.
set -uo pipefail
CLI="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROSTER="$CLI/../agents"
MODE=all
for a in "$@"; do case "$a" in
  --sizes) MODE=sizes ;;
  *) printf 'test/probe-readers.sh: unknown option "%s". There is one: --sizes.\n' "$a"; exit 2 ;;
esac; done
FIXED="${READERS_FIXED:-2000}"
FRESH="${READERS_FRESH:-20}"
N='answered and then refused the connection this question needs'
WORK="$(mktemp -d "${TMPDIR:-/tmp}/epito-probe-readers-XXXXXX")"
FAKE=""
cleanup() { [ -n "$FAKE" ] && kill "$FAKE" 2>/dev/null; rm -rf "$WORK"; }
trap cleanup EXIT

printf '\n== three readers, one captured output: which half of the flake moves\n\n'

if [ "$MODE" != sizes ] && ! node -e 'import("@temporalio/client").then(()=>process.exit(0),()=>process.exit(1))' 2>/dev/null; then
  printf '  SKIPPED -- @temporalio/client is not installed here, so the real connect this\n'
  printf '  scenario needs never happens and the row under test is never printed.\n'
  printf '  Run `npm ci` in %s first.\n' "$CLI"
  exit 0
fi

sizes_loop() {
  # Where the threshold really is. A producer that is a shell builtin writes
  # through stdio, whose buffer is 4 KiB here — not the 64 KiB of the pipe — so
  # any output past 4 KiB takes a SECOND write, and the second write is the one
  # that lands on a pipe quiet grep has already closed. The needle goes on the
  # first line, which is where a report's own verdict usually is.
  local asks="${READERS_ASKS:-200}" sizes="${READERS_SIZES:-1024 2048 4096 4300 8192 65536}"
  local size payload wrong i ps rc s
  printf '\n  loop 3 — what the pipe reader is actually wrong about, %s asks each cell\n' "$asks"
  printf '    (the producer is `printf`, a builtin, as in the suites; `first` puts the needle on\n'
  printf '     line 1 and `last` on the final line, which is the only other thing that changes)\n'
  local where
  for size in $sizes; do
   for where in first last; do
    if [ "$where" = first ]; then
      payload="$N"$'\n'"$(yes 'the same line of filler a real report prints' | head -c "$size")"
    else
      payload="$(yes 'the same line of filler a real report prints' | head -c "$size")"$'\n'"$N"
    fi
    wrong=0; i=0; : > "$WORK/sizes-ps.txt"
    while [ "$i" -lt "$asks" ]; do
      i=$((i+1))
      printf '%s' "$payload" | grep -qF -e "$N"
      ps="${PIPESTATUS[*]}"; rc=0; for s in $ps; do [ "$s" != 0 ] && rc=$s; done
      [ "$rc" != 0 ] && { wrong=$((wrong+1)); printf '%s\n' "$ps" >> "$WORK/sizes-ps.txt"; }
    done
    printf '    %6s bytes  needle %-5s %4s/%s wrong   PIPESTATUS %s\n' \
      "$(printf '%s' "$payload" | wc -c)" "$where" "$wrong" "$asks" \
      "$(sort "$WORK/sizes-ps.txt" | uniq -c | tr -s ' \n' ' ' | sed 's/^ //;s/ $//')"
    : > "$WORK/sizes-ps.txt"
   done
  done
}

if [ "$MODE" = sizes ]; then
  printf '  the needle: %s\n' "$N"
  printf '  the box:   load%s\n' "$(uptime | sed 's/.*load average/ average/')"
  sizes_loop
  printf '\n-----------------------------------------------\n'
  printf 'probe-readers: read which cells have a non-zero count beside them. That is where this\n'
  printf "repository's remaining pipe sites stop being latent, and it is not only 64 KiB.\n"
  exit 0
fi

# A port that accepts a connection and speaks no gRPC — section 5's own
# scenario, on a port the kernel hands out rather than a fixed one, so this can
# run beside a suite that is using section 5's.
node -e 'const s=require("net").createServer(()=>{});s.listen(0,"127.0.0.1",()=>{require("fs").writeFileSync(process.argv[1],String(s.address().port))})' "$WORK/port" &
FAKE=$!
for _ in 1 2 3 4 5 6 7 8 9 10; do [ -s "$WORK/port" ] && break; sleep 0.3; done
PORT="$(cat "$WORK/port" 2>/dev/null)"
if [ -z "$PORT" ]; then printf '  the stand-in port never came up, so there is nothing to ask about\n'; exit 1; fi

capture() { TEMPORAL_ADDRESS="127.0.0.1:$PORT" node "$CLI/src/index.js" doctor "$ROSTER" 2>&1; }

# Each reader reports its own status AND, for the pipe, the status of both
# halves of the pipeline. PIPESTATUS is read before anything else runs, because
# any simple command overwrites it with its own one-element status — and `[0]`
# for a producer that died writing into a closed pipe reads nothing like `[1]`
# for a grep that genuinely did not match. Which of those happens is the whole
# question a false non-match raises, so it is recorded rather than inferred.
pipe_reader() {
  local ps rc=0 s
  printf '%s' "$1" 2>>"$WORK/pipe.err" | grep -qF -e "$N" 2>>"$WORK/grep.err"
  ps="${PIPESTATUS[*]}"
  for s in $ps; do [ "$s" != 0 ] && rc=$s; done
  PIPE_PS="$ps"
  return "$rc"
}
here_reader()  { grep -qF -e "$N" <<<"$1" 2>>"$WORK/here.err"; }
bash_reader()  { [[ $1 == *"$N"* ]]; }

printf '  the needle: %s\n' "$N"
printf '  the box:   load%s\n\n' "$(uptime | sed 's/.*load average/ average/')"

out="$(capture)"
printf '  loop 1 — one capture of %s bytes, asked %s times by each reader\n' "$(printf '%s' "$out" | wc -c)" "$FIXED"
printf '    the row it is about, as the product printed it:\n'
printf '      %s\n' "$(grep -F "$N" <<<"$out" | head -1 | cut -c1-120)"
p=0; h=0; b=0; pipefalse=0; convdis=0
: > "$WORK/pipestatus.txt"
i=0
while [ "$i" -lt "$FIXED" ]; do
  i=$((i+1))
  pipe_reader "$out" && rp=1 || rp=0
  here_reader "$out" && rh=1 || rh=0
  bash_reader "$out" && rb=1 || rb=0
  p=$((p+rp)); h=$((h+rh)); b=$((b+rb))
  # The bytes cannot have changed, so bash's own match is the ground truth.
  if [ "$rb" = 1 ] && [ "$rp" = 0 ]; then
    pipefalse=$((pipefalse+1))
    printf '%s\n' "$PIPE_PS" >> "$WORK/pipestatus.txt"
    [ "$pipefalse" = 1 ] && printf '    the pipe reader said NO at iteration %s, on bytes it matched before and after\n' "$i"
  fi
  [ "$rh" != "$rb" ] && convdis=$((convdis+1))
done
printf '    pipe        %s/%s matched\n' "$p" "$FIXED"
printf '    herestring  %s/%s matched\n' "$h" "$FIXED"
printf '    bash        %s/%s matched\n' "$b" "$FIXED"
if [ "$pipefalse" -gt 0 ]; then
  printf '    the pipe reader was wrong %s times in %s, and PIPESTATUS says which half failed:\n' "$pipefalse" "$FIXED"
  sort "$WORK/pipestatus.txt" | uniq -c | sed 's/^/      /'
  printf '      ("141 0" is the producer killed by SIGPIPE on a pipe grep had already closed;\n'
  printf '       "0 1" would be grep itself not matching bytes that contain the needle)\n'
  [ -s "$WORK/grep.err" ] && { printf '      what grep said on stderr:\n'; sort "$WORK/grep.err" | uniq -c | sed 's/^/        /'; }
  [ -s "$WORK/pipe.err" ] && { printf '      what the producer said on stderr:\n'; sort "$WORK/pipe.err" | uniq -c | sed 's/^/        /'; }
fi

printf '\n  loop 2 — %s fresh runs of the product, three readers each\n' "$FRESH"
fp=0; fh=0; fb=0; fpipefalse=0; fconvdis=0; missing=0
i=0
while [ "$i" -lt "$FRESH" ]; do
  i=$((i+1))
  o="$(capture)"
  pipe_reader "$o" && rp=1 || rp=0
  here_reader "$o" && rh=1 || rh=0
  bash_reader "$o" && rb=1 || rb=0
  fp=$((fp+rp)); fh=$((fh+rh)); fb=$((fb+rb))
  if [ "$rb" = 1 ] && [ "$rp" = 0 ]; then
    fpipefalse=$((fpipefalse+1))
    printf '    run %-3s the pipe reader said NO (PIPESTATUS %s) on a capture that holds the sentence\n' "$i" "$PIPE_PS"
  fi
  if [ "$rh" != "$rb" ]; then
    fconvdis=$((fconvdis+1))
    printf '    run %-3s herestring and bash DISAGREED: herestring=%s bash=%s (%s bytes)\n' "$i" "$rh" "$rb" "$(printf '%s' "$o" | wc -c)"
    printf '%s' "$o" > "$WORK/disagreed-$i.txt"
  fi
  if [ "$rb" = 0 ]; then
    missing=$((missing+1))
    printf '    run %-3s the sentence is NOT in this capture — the worker row said:\n' "$i"
    printf '      %s\n' "$(grep -E 'worker' <<<"$o" | head -1 | cut -c1-120)"
    printf '%s' "$o" > "$WORK/missing-$i.txt"
  fi
done
printf '    pipe %s/%s, herestring %s/%s, bash %s/%s matched\n' "$fp" "$FRESH" "$fh" "$FRESH" "$fb" "$FRESH"
printf '    captures the product did not print the sentence in: %s of %s\n' "$missing" "$FRESH"
printf '  the box:   load%s\n' "$(uptime | sed 's/.*load average/ average/')"

sizes_loop

printf '\n-----------------------------------------------\n'
printf 'probe-readers: the product printed the sentence in %s of %s fresh runs.\n' "$fb" "$FRESH"
printf 'probe-readers: the PIPE reader was wrong %s times in %s asks of bytes that hold it.\n' "$((pipefalse+fpipefalse))" "$((FIXED+FRESH))"
printf 'probe-readers: the CONVERTED readers disagreed with each other %s times in %s.\n' "$((convdis+fconvdis))" "$((FIXED+FRESH))"
if [ "$((convdis+fconvdis))" != 0 ]; then
  printf 'probe-readers: that last number is the one that must be 0. It is not, so the shape this\n'
  printf 'suite was converted TO is not reliable either, and the captures are kept beside this run.\n'
  exit 1
fi
if [ "$((pipefalse+fpipefalse))" = 0 ]; then
  printf 'probe-readers: no reader was wrong on this box, at this load, in this many asks. That is\n'
  printf 'not the same as the shape being safe — say the load and the count wherever this is cited.\n'
else
  printf 'probe-readers: so the flake family in docs/ideas.md has its answer for this assertion —\n'
  printf 'the READER, not the product, and only the reader the conversion removed.\n'
fi
exit 0
