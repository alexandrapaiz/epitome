#!/usr/bin/env node
// The two outside worlds an edge run touches, stubbed on one loopback port:
// GitHub (where the agent's App is installed and its charter lives) and a
// model endpoint that speaks the Anthropic messages API.
//
// It exists so that `wrangler dev` can run the REAL bundle, in the REAL
// Workers runtime, end to end, on a machine that holds no Cloudflare account,
// no GitHub App and no model key — which is the only honest way to prove the
// worker before the one step that is the owner's.
//
//   node test/cloudflare-stub.mjs [port]
//
// It checks what it is asked for as it answers, and prints each request, so
// the transcript is the assertion: the JWT it was handed, the permissions the
// mint asked for, the repository it asked for them on.
import { createServer } from "node:http";
import { createVerify } from "node:crypto";

const port = Number(process.argv[2] ?? 8788);
const publicKey = process.env.STUB_APP_PUBLIC_KEY ?? null;

const CHARTER = `# edge-demo

You are edge-demo. You read the company board each morning and say, in one
line, the one thing that moved.
`;

const json = (res, status, body) => {
  res.writeHead(status, { "content-type": "application/json" });
  res.end(JSON.stringify(body));
};

const server = createServer((req, res) => {
  let body = "";
  req.on("data", (c) => { body += c; });
  req.on("end", () => {
    const auth = req.headers.authorization ?? "";
    const note = [];

    // The agent's own identity, checked rather than assumed: the JWT the
    // Worker signed must verify against the App's public key, or this is not
    // the App talking.
    if (publicKey && /^Bearer ey/.test(auth)) {
      const [h, p, sig] = auth.slice(7).split(".");
      const v = createVerify("RSA-SHA256");
      v.update(`${h}.${p}`);
      const ok = v.verify(publicKey, Buffer.from(sig.replace(/-/g, "+").replace(/_/g, "/"), "base64"));
      const claims = JSON.parse(Buffer.from(p, "base64url").toString());
      note.push(ok ? `JWT verifies as App ${claims.iss}, ${claims.exp - claims.iat}s long` : "JWT DOES NOT VERIFY");
    }

    if (req.url.endsWith("/installation")) {
      console.log(`stub: GET ${req.url} — ${note.join("; ")}`);
      return json(res, 200, { id: 4242, app_id: 1234567 });
    }
    if (req.url.endsWith("/access_tokens")) {
      const asked = JSON.parse(body || "{}");
      console.log(`stub: POST ${req.url} — ${note.join("; ")}; asked for ${JSON.stringify(asked.permissions)} on ${JSON.stringify(asked.repositories)}`);
      return json(res, 200, { token: "ghs_STUBTOKEN", expires_at: new Date(Date.now() + 3600e3).toISOString() });
    }
    if (req.url.includes("/contents/")) {
      console.log(`stub: GET ${req.url} — with ${auth.startsWith("Bearer ghs_") ? "the minted installation token" : `UNEXPECTED credential (${auth.slice(0, 12)}…)`}`);
      res.writeHead(200, { "content-type": "text/plain" });
      return res.end(CHARTER);
    }
    if (req.url.endsWith("/v1/messages")) {
      const asked = JSON.parse(body || "{}");
      const charterArrived = String(asked.messages?.[0]?.content ?? "").includes("You are edge-demo");
      console.log(`stub: POST ${req.url} — model ${asked.model}, charter ${charterArrived ? "arrived" : "DID NOT ARRIVE"}, auth ${req.headers.authorization ? "bearer" : req.headers["x-api-key"] ? "x-api-key" : "NONE"}`);
      return json(res, 200, {
        content: [{ type: "text", text: "The one thing that moved: the Cloudflare target now packs a manifest into a Worker that mints its own token." }],
        usage: { input_tokens: 120, output_tokens: 28 },
      });
    }
    console.log(`stub: ${req.method} ${req.url} — nothing here answers that`);
    json(res, 404, { message: "Not Found" });
  });
});

server.listen(port, "127.0.0.1", () => console.log(`stub: GitHub and a model, on http://127.0.0.1:${port}`));
