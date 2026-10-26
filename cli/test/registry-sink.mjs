#!/usr/bin/env node
// A local stand-in for the npm registry, for one purpose: to be able to say
// whether a publish REACHED a registry at all. Appends one line per request —
// method, path, body bytes — and answers every one of them with a 500.
//   node test/registry-sink.mjs <port> <outfile>
//
// The 500 is deliberate and is not laziness. A sink that answered 201 would
// leave "published epito-cli@0.1.0" in a test log, and the one thing this
// product cannot afford is a run that believes it published. A 500 cannot be
// mistaken for a publish by npm or by a reader, and the fact under test —
// did a request arrive — is recorded before the status is chosen.
//
// npm retries a 5xx, so one publish lands as three identical PUTs. That is
// npm's own retry policy and not three attempts by the caller; the assertion
// reads "at least one", never "exactly one".
import { createServer } from "node:http";
import { appendFileSync, writeFileSync } from "node:fs";

const [port, out] = process.argv.slice(2);
// Created empty up front, so "no requests arrived" reads as an empty file
// rather than a missing one. A caller cannot tell those apart, and this
// suite's whole question is whether nothing happened.
writeFileSync(out, "");
createServer((req, res) => {
  const chunks = [];
  req.on("data", (c) => chunks.push(c));
  req.on("end", () => {
    appendFileSync(out, `${req.method} ${req.url} ${Buffer.concat(chunks).length}\n`);
    res.writeHead(500, { "content-type": "application/json" });
    res.end('{"error":"recording sink; nothing is stored here"}');
  });
}).listen(Number(port), "127.0.0.1", () => console.log(`registry sink on ${port} -> ${out}`));
