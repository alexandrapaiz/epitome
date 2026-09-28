#!/usr/bin/env node
// A local stand-in for api.github.com's App endpoints, so the token smoke test
// can prove the whole mint without a network, a real App, or a real key.
// It is deliberately strict where GitHub is strict: it verifies the RS256
// signature on the App JWT with the test's public key, refuses a request for
// more permission than the installation was granted (422, as GitHub does),
// and 404s a repository the App is not installed on.
//
//   node test/github-sink.mjs <port> <public-key.pem> <log.jsonl> '<granted-json>'
//
// <granted-json> is the installation's grant, e.g.
// {"contents":"write","pull_requests":"write","metadata":"read"}.
// Every request is appended to <log.jsonl> so the test can assert on exactly
// what epito asked for.
import { createServer } from "node:http";
import { createVerify } from "node:crypto";
import { appendFileSync, readFileSync } from "node:fs";
import { randomBytes } from "node:crypto";

const [port, pubPath, logPath, grantedJson] = process.argv.slice(2);
const pub = readFileSync(pubPath, "utf8");
const granted = JSON.parse(grantedJson);
const RANK = { read: 1, write: 2, admin: 3 };

const record = (o) => appendFileSync(logPath, JSON.stringify(o) + "\n");

function checkJwt(auth) {
  const m = /^Bearer (\S+)$/.exec(auth ?? "");
  if (!m) return { error: "no bearer" };
  const [h, p, sig] = m[1].split(".");
  if (!sig) return { error: "not three parts" };
  const v = createVerify("RSA-SHA256");
  v.update(`${h}.${p}`);
  if (!v.verify(pub, Buffer.from(sig, "base64url"))) return { error: "bad signature" };
  const claims = JSON.parse(Buffer.from(p, "base64url").toString("utf8"));
  const now = Math.floor(Date.now() / 1000);
  if (claims.exp <= now) return { error: "expired" };
  if (claims.iat > now + 60) return { error: "issued in the future" };
  if (claims.exp - claims.iat > 601) return { error: "longer than GitHub's 10 minutes" };
  return { claims };
}

createServer((req, res) => {
  const chunks = [];
  req.on("data", (c) => chunks.push(c));
  req.on("end", () => {
    const body = Buffer.concat(chunks).toString();
    const send = (status, obj) => { res.writeHead(status, { "content-type": "application/json" }); res.end(JSON.stringify(obj)); };
    const { claims, error } = checkJwt(req.headers.authorization);
    record({ method: req.method, url: req.url, iss: claims?.iss ?? null, jwt: error ?? "ok", body: body ? JSON.parse(body) : null });
    if (error) return send(401, { message: `A JSON web token could not be decoded (${error})` });

    let m = /^\/repos\/([^/]+)\/([^/]+)\/installation$/.exec(req.url);
    if (m && req.method === "GET") {
      // The App is installed on everything except the repository named
      // "unowned", which is how the test reaches GitHub's 404.
      if (m[2] === "unowned") return send(404, { message: "Not Found" });
      return send(200, { id: 424242, app_id: Number(claims.iss) || claims.iss });
    }

    m = /^\/app\/installations\/(\d+)\/access_tokens$/.exec(req.url);
    if (m && req.method === "POST") {
      const asked = JSON.parse(body || "{}").permissions ?? {};
      const over = Object.entries(asked).filter(([k, v]) => (RANK[v] ?? 9) > (RANK[granted[k]] ?? 0));
      if (over.length) return send(422, { message: `The permissions requested are not granted to this installation: ${over.map(([k, v]) => `${k}:${v}`).join(", ")}` });
      return send(201, {
        token: `ghs_smoke_${randomBytes(12).toString("hex")}`,
        expires_at: new Date(Date.now() + 3600_000).toISOString(),
        permissions: asked,
        repository_selection: "selected",
        repositories: (JSON.parse(body || "{}").repositories ?? []).map((r) => ({ name: r, full_name: `acme/${r}` })),
      });
    }

    send(404, { message: `no route ${req.method} ${req.url}` });
  });
}).listen(Number(port), "127.0.0.1", () => console.log(`github sink on ${port} -> ${logPath}`));
