#!/usr/bin/env node
// A stand-in for api.github.com in the token smoke test: no network, no
// account, no real App. It is strict where it matters — it verifies the App
// JWT's signature, issuer and expiry against the test key, and it refuses
// permissions the "App" was not granted — so the test proves the mint is
// correct rather than proving the CLI can call fetch.
//
//   node test/stub-github.mjs <port> <private-key.pem> <log.jsonl>
//
// Fixture: App id 7, slug "epito-pm", installed on acme/roster (installation
// 42) and nowhere else, granted contents+pull_requests+metadata but NOT
// issues. Tokens it issues are fake by construction ("ghs_stub-..."); the log
// records only their sha256 prefix, because the rule under test is that a
// token is never written down.
import { createServer } from "node:http";
import { readFileSync, appendFileSync } from "node:fs";
import { createVerify, createPublicKey, createHash, randomUUID } from "node:crypto";

const [port, keyPath, logPath] = process.argv.slice(2);
const pub = createPublicKey(readFileSync(keyPath, "utf8"));
const fp = (v) => createHash("sha256").update(v).digest("hex").slice(0, 12);
const note = (o) => appendFileSync(logPath, JSON.stringify(o) + "\n");

const GRANTED = { contents: "write", pull_requests: "write", metadata: "read" };
const INSTALLED = { "acme/roster": { id: 42, app_id: 7, app_slug: "epito-pm" } };
const issued = new Set();

function checkJwt(header) {
  const m = /^Bearer (.+)$/.exec(header ?? "");
  if (!m) return { ok: false, why: "no bearer" };
  const [h, p, s] = m[1].split(".");
  if (!s) return { ok: false, why: "not a jwt" };
  const v = createVerify("RSA-SHA256");
  v.update(`${h}.${p}`);
  if (!v.verify(pub, Buffer.from(s, "base64url"))) return { ok: false, why: "bad signature" };
  const claims = JSON.parse(Buffer.from(p, "base64url").toString("utf8"));
  const now = Math.floor(Date.now() / 1000);
  if (claims.iss !== "7") return { ok: false, why: `iss ${claims.iss} is not this App` };
  if (claims.exp <= now) return { ok: false, why: "expired" };
  if (claims.exp - claims.iat > 600) return { ok: false, why: "longer than GitHub's 10-minute maximum" };
  return { ok: true, claims };
}

createServer((req, res) => {
  let body = "";
  req.on("data", (d) => (body += d));
  req.on("end", () => {
    const send = (code, obj, extra = {}) => {
      note({ method: req.method, path: req.url, status: code, ...extra });
      res.writeHead(code, { "content-type": "application/json" });
      res.end(JSON.stringify(obj));
    };
    const auth = req.headers.authorization;

    let m = /^\/repos\/([^/]+\/[^/]+)\/installation$/.exec(req.url);
    if (m && req.method === "GET") {
      const jwt = checkJwt(auth);
      if (!jwt.ok) return send(401, { message: `bad JWT: ${jwt.why}` }, { jwt: jwt.why });
      const inst = INSTALLED[m[1]];
      if (!inst) return send(404, { message: "Not Found" }, { jwt: "verified", repo: m[1] });
      return send(200, inst, { jwt: "verified", repo: m[1] });
    }

    m = /^\/app\/installations\/(\d+)\/access_tokens$/.exec(req.url);
    if (m && req.method === "POST") {
      const jwt = checkJwt(auth);
      if (!jwt.ok) return send(401, { message: `bad JWT: ${jwt.why}` }, { jwt: jwt.why });
      const asked = JSON.parse(body || "{}");
      const over = Object.keys(asked.permissions ?? {}).filter((k) => !(k in GRANTED));
      if (over.length) {
        return send(422, { message: `The permissions requested are not granted to this installation: ${over.join(", ")}` },
          { jwt: "verified", asked: asked.permissions, refused: over });
      }
      const token = `ghs_stub-${randomUUID()}`;
      issued.add(token);
      return send(201, {
        token, expires_at: new Date(Date.now() + 3600_000).toISOString(),
        permissions: asked.permissions, repositories: asked.repositories,
      }, { jwt: "verified", asked: asked.permissions, repositories: asked.repositories, token_fingerprint: fp(token) });
    }

    if (req.url === "/users/epito-pm%5Bbot%5D" && req.method === "GET") {
      const tok = /^Bearer (.+)$/.exec(auth ?? "")?.[1];
      if (!tok || !issued.has(tok)) return send(401, { message: "Bad credentials" }, { with: "not an issued token" });
      return send(200, { login: "epito-pm[bot]", id: 555, type: "Bot" }, { with: "the minted token", token_fingerprint: fp(tok) });
    }

    send(404, { message: "stub-github: no route" });
  });
}).listen(Number(port), "127.0.0.1", () => console.error(`stub-github on ${port}`));
