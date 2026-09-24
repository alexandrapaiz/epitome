#!/usr/bin/env node
// A stand-in for api.github.com in the identity smoke test: no live account,
// no real App, no real token. It is not a mock that says yes — it verifies
// the RS256 signature on epito's App JWT against a throwaway public key, so
// a broken JWT fails the test the way GitHub would (401), and it enforces the
// App's own granted permissions as the outer ceiling (422), which is the rule
// spec/manifest.md calls "scopes are the ceiling".
//
//   node test/github-stub.mjs <port> <public-key.pem> <log-file>
//
//   EPITO_STUB_APPS    JSON: { "<appId>": { slug, installation, userId } }
//   EPITO_STUB_GRANTED JSON: { "<permission>": "read"|"write" } the App holds
//   EPITO_STUB_MISSING repo (owner/name) the App is NOT installed on
import { createServer } from "node:http";
import { createVerify } from "node:crypto";
import { readFileSync, appendFileSync, writeFileSync } from "node:fs";

const [portArg, keyPath, logPath] = process.argv.slice(2);
const publicKey = readFileSync(keyPath, "utf8");
const APPS = JSON.parse(process.env.EPITO_STUB_APPS || "{}");
const GRANTED = JSON.parse(process.env.EPITO_STUB_GRANTED || '{"contents":"write","pull_requests":"write","issues":"write","metadata":"read"}');
const MISSING = process.env.EPITO_STUB_MISSING || "";
const RANK = { read: 1, write: 2 };
writeFileSync(logPath, "");

// Returns the app record for a valid JWT, or a reason string for the refusal.
function verify(auth) {
  const jwt = (auth || "").replace(/^Bearer /, "");
  const [h, b, s] = jwt.split(".");
  if (!h || !b || !s) return { bad: "not a JWT" };
  const head = JSON.parse(Buffer.from(h, "base64url").toString());
  if (head.alg !== "RS256") return { bad: `alg ${head.alg}, expected RS256` };
  const v = createVerify("RSA-SHA256");
  v.update(`${h}.${b}`);
  v.end();
  if (!v.verify(publicKey, Buffer.from(s, "base64url"))) return { bad: "signature does not verify" };
  const body = JSON.parse(Buffer.from(b, "base64url").toString());
  const now = Math.floor(Date.now() / 1000);
  if (!(body.exp > now)) return { bad: "expired" };
  if (body.exp - body.iat > 600) return { bad: "lifetime over 10 minutes" };
  const app = APPS[String(body.iss)];
  if (!app) return { bad: `no App with id ${body.iss}` };
  return { app, appId: String(body.iss) };
}

let minted = 0;
createServer((req, res) => {
  let raw = "";
  req.on("data", (d) => (raw += d));
  req.on("end", () => {
    const send = (status, obj, note = "") => {
      appendFileSync(logPath, `${req.method} ${req.url} -> ${status}${note ? ` ${note}` : ""}\n`);
      res.writeHead(status, { "content-type": "application/json" });
      res.end(JSON.stringify(obj));
    };
    const { app, appId, bad } = verify(req.headers.authorization);
    if (bad) return send(401, { message: `stub: App JWT refused (${bad})` }, bad);

    let m;
    if ((m = req.url.match(/^\/repos\/([^/]+)\/([^/]+)\/installation$/))) {
      const repo = `${m[1]}/${m[2]}`;
      if (repo === MISSING) return send(404, { message: "Not Found" }, repo);
      return send(200, { id: app.installation, app_id: Number(appId), app_slug: app.slug, account: { login: m[1] } }, repo);
    }
    if ((m = req.url.match(/^\/users\/(.+)$/))) {
      const login = decodeURIComponent(m[1]);
      const hit = Object.values(APPS).find((a) => `${a.slug}[bot]` === login);
      if (!hit) return send(404, { message: "Not Found" }, login);
      return send(200, { id: hit.userId, login, type: "Bot" }, login);
    }
    if ((m = req.url.match(/^\/app\/installations\/(\d+)\/access_tokens$/)) && req.method === "POST") {
      if (Number(m[1]) !== app.installation) return send(404, { message: "Not Found" }, "wrong installation");
      const body = JSON.parse(raw || "{}");
      const asked = body.permissions ?? {};
      const over = Object.entries(asked).filter(([p, lvl]) => !GRANTED[p] || RANK[lvl] > RANK[GRANTED[p]]);
      if (over.length) {
        return send(422, { message: `The permissions requested are not granted to this installation: ${over.map(([p, l]) => `${p}:${l}`).join(", ")}` }, "over ceiling");
      }
      minted++;
      // Deterministic, so a test can name the exact credential it expects to
      // find in a run, and restarting this stub cannot change the answer.
      return send(201, {
        token: `ghs_stubtoken_${app.installation}`,
        expires_at: new Date(Date.now() + 3600_000).toISOString().replace(/\.\d+Z$/, "Z"),
        permissions: asked,
        repository_selection: "selected",
        repositories: (body.repositories ?? []).map((n) => ({ name: n })),
      }, `repos=${JSON.stringify(body.repositories)} permissions=${JSON.stringify(asked)}`);
    }
    return send(404, { message: "stub: no such route" });
  });
}).listen(Number(portArg), "127.0.0.1", () => process.stdout.write(`github-stub on ${portArg}\n`));
