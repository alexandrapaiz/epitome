#!/usr/bin/env node
// A local stand-in for the COMPANY board's `POST /api/runs` — the endpoint
// behind the owner's Runs tab. Appends one JSON line per request, so the smoke
// test can read which runs were filed, under which company, and with what.
//
//   node test/board-sink.mjs <port> <outfile> [status]
//
// WHY THIS EXISTS. `cli/src/lib/runreport.js` and the `record` activity have
// filed host runs to the company board since 2026-10-18, and `unit-runreport.mjs`
// asserts that module against a server of its own. What nothing asserted is the
// WIRING: that a run performed by this runtime — in particular a run inside a
// window, which reaches `record` through a SeatRun child of SeatWindow — arrives
// there at all. This suite already starts a real engine, opens real windows and
// reads the audit log and the local board; it set no BOARD_API_URL, so the whole
// company-board path was dark in the one test that drives the real thing.
//
// That gap had a cost. On 2026-11-02 a seat reading the trunk concluded the run
// report existed "only in the Temporal activity path" and that pulling the host's
// stale CLI checkout would therefore trade away the Runs tab for every host window
// run. It would not: SeatWindow runs each run as a SeatRun child and SeatRun
// records every one. But that answer took reading four files to reach and nothing
// in the repository could say it, so a pull that was never blocked sat for six
// days. A question an owner asks about her own product should be a test.
//
// It records the AUTHORIZATION header beside the body on purpose: the token
// belongs in the header and must not be in the payload, and a sink that threw
// the header away could not tell the difference.
import { createServer } from "node:http";
import { appendFileSync } from "node:fs";

const [port, out, status = "200"] = process.argv.slice(2);
createServer((req, res) => {
  const chunks = [];
  req.on("data", (c) => chunks.push(c));
  req.on("end", () => {
    const raw = Buffer.concat(chunks).toString();
    let body = null, unparseable = null;
    try { body = JSON.parse(raw || "{}"); } catch (e) { unparseable = e.message; }
    appendFileSync(out, JSON.stringify({
      method: req.method, url: req.url, auth: req.headers.authorization ?? null,
      ...(unparseable ? { unparseable, raw } : { body }),
    }) + "\n");
    res.writeHead(Number(status), { "content-type": "application/json" });
    res.end("{}");
  });
}).listen(Number(port), "127.0.0.1", () => console.log(`board sink on ${port} -> ${out}`));
