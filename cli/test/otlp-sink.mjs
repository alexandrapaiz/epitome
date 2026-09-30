#!/usr/bin/env node
// A local stand-in for a trace backend (Phoenix, Jaeger, Tempo — they all take
// OTLP/HTTP): appends one line per span to a file, flattened to the four
// things a test asserts about, so the smoke test never needs what the box has.
//   node test/otlp-sink.mjs <port> <outfile>
import { createServer } from "node:http";
import { appendFileSync } from "node:fs";

const [port, out] = process.argv.slice(2);
createServer((req, res) => {
  const chunks = [];
  req.on("data", (c) => chunks.push(c));
  req.on("end", () => {
    try {
      const body = JSON.parse(Buffer.concat(chunks).toString());
      for (const rs of body.resourceSpans ?? []) {
        const resource = Object.fromEntries((rs.resource?.attributes ?? []).map((a) => [a.key, a.value?.stringValue ?? ""]));
        for (const ss of rs.scopeSpans ?? []) {
          for (const s of ss.spans ?? []) {
            appendFileSync(out, JSON.stringify({
              traceId: s.traceId, spanId: s.spanId, parent: s.parentSpanId ?? null, name: s.name,
              service: resource["service.name"] ?? null, scope: ss.scope?.name ?? null,
              status: s.status?.code ?? 0, message: s.status?.message ?? null,
              startNs: s.startTimeUnixNano, endNs: s.endTimeUnixNano,
              attrs: Object.fromEntries((s.attributes ?? []).map((a) => [a.key,
                a.value?.stringValue ?? a.value?.intValue ?? a.value?.boolValue ?? a.value?.doubleValue ?? null])),
            }) + "\n");
          }
        }
      }
      res.writeHead(200, { "content-type": "application/json" }).end("{}");
    } catch (e) {
      appendFileSync(out, `unparseable: ${e.message}\n`);
      res.writeHead(400).end();
    }
  });
}).listen(Number(port), "127.0.0.1", () => console.log(`otlp sink on ${port} -> ${out}`));
