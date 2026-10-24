#!/usr/bin/env bash
# The measurement behind test/shapes.sh, kept so the next seat can re-run it
# rather than quote it.
#
#   bash test/probe-pipefail.sh            # from cli/
#
# The question: how often does `<producer> | grep -q <pattern>` under
# `set -o pipefail` report failure for a pattern it MATCHED?
#
# The method, and the method is the finding. PIPESTATUS must be read BEFORE
# anything else reads `$?`, because `st=$?` is itself a simple command and
# overwrites PIPESTATUS with its own one-element status:
#
#   $ printf 'MARKER\n' | grep -q MARKER; st=$?; echo "[${PIPESTATUS[*]}]"
#   [0]
#   $ printf 'MARKER\n' | grep -q MARKER; echo "[${PIPESTATUS[*]}]"
#   [0 0]
#   $ false | grep -q zzz; st=$?; echo "[${PIPESTATUS[*]}]"      # a REAL failure
#   [0]
#
# That `[0]` is identical for a real failure and a false one, so a probe reading
# `$?` first cannot tell them apart, and "PIPESTATUS=[0] every time, so grep had
# matched" is what it prints either way. A false failure here is read as:
# the LAST element is 0 (grep matched) and an earlier one is not (the producer
# died). Both from one read of the array.
set -uo pipefail
CLI="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
N=${1:-20}
PORT=${EPITO_PROBE_PORT:-47914}

# A local HTTP server that returns exactly N bytes, so `curl` is the real
# producer under test and the size is the variable.
node -e '
const http=require("http");
http.createServer((q,s)=>{const n=+(q.url.slice(1))||0;s.writeHead(200,{"content-type":"text/plain"});
  s.end("MARKER\n"+"x".repeat(Math.max(0,n-7)));}).listen('"$PORT"');' 2>/dev/null &
SRV=$!; trap 'kill $SRV 2>/dev/null' EXIT; sleep 1

printf '\n== false failures by the producer output size, %s invocations each, load %s\n\n' \
  "$N" "$(cut -d' ' -f1-3 /proc/loadavg)"
printf '  %-9s  %-28s  %-28s\n' "bytes" "curl -fs | grep -q MARKER" "node -e write | grep -q MARKER"
for n in 1024 16384 65536 262144 1048576; do
  cf=0; cc=""; nf=0; nc=""
  for ((i=0;i<N;i++)); do
    curl -fs "http://127.0.0.1:$PORT/$n" | grep -q MARKER
    p=("${PIPESTATUS[@]}")
    [ "${p[1]}" = 0 ] && [ "${p[0]}" != 0 ] && { cf=$((cf+1)); cc="${p[0]}"; }
  done
  for ((i=0;i<N;i++)); do
    node -e "process.stdout.write('MARKER\n'+'x'.repeat($n-7))" 2>/dev/null | grep -q MARKER
    p=("${PIPESTATUS[@]}")
    [ "${p[1]}" = 0 ] && [ "${p[0]}" != 0 ] && { nf=$((nf+1)); nc="${p[0]}"; }
  done
  printf '  %-9s  %-28s  %-28s\n' "$n" "$cf/$N false, producer exit ${cc:--}" \
    "$nf/$N false, producer exit ${nc:--}"
done

# And the shape as the suites actually write it, over output of the size a real
# `epito` command produces. This is the row that says the sites are latent.
OUT="$(cd "$CLI/.." && node "$CLI/src/index.js" validate agents 2>&1)"
f=0
for ((i=0;i<3000;i++)); do
  printf '%s' "$OUT" | grep -q 'manifests are agents'
  p=("${PIPESTATUS[@]}")
  [ "${p[1]}" = 0 ] && [ "${p[0]}" != 0 ] && f=$((f+1))
done
printf '\n  the suites own shape: printf of %s bytes of real `epito validate` output,\n' "${#OUT}"
printf '  3000 invocations at load %s: %s false failures\n\n' "$(cut -d' ' -f1 /proc/loadavg)" "$f"
