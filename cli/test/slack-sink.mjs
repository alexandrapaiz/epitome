#!/usr/bin/env node
// A local stand-in for a Slack incoming webhook: appends each post's text to
// a file, one line each, so the smoke test can read what the seat said.
//   node test/slack-sink.mjs <port> <outfile>
import { createServer } from "node:http";
import { appendFileSync } from "node:fs";

const [port, out] = process.argv.slice(2);
createServer((req, res) => {
  const chunks = [];
  req.on("data", (c) => chunks.push(c));
  req.on("end", () => {
    try { appendFileSync(out, JSON.parse(Buffer.concat(chunks).toString()).text + "\n"); } catch (e) { appendFileSync(out, `unparseable: ${e.message}\n`); }
    res.writeHead(200, { "content-type": "text/plain" });
    res.end("ok");
  });
}).listen(Number(port), "127.0.0.1", () => console.log(`slack sink on ${port} -> ${out}`));
