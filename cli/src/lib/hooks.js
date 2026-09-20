// The webhook ingress: node:http, one route family, one shared secret.
// POST /hooks/<name> with header `x-epito-secret: <EPITO_HOOK_SECRET>`.
// The compare is constant-time (crypto.timingSafeEqual over equal-length
// digests) so a wrong secret leaks nothing about how wrong it is. Bodies are
// read (capped) but not interpreted in v0: an event is a wake-up, and the
// agent's charter decides what to do with it.
import { createServer } from "node:http";
import { createHash, timingSafeEqual } from "node:crypto";

const MAX_BODY = 64 * 1024;

export function secretsMatch(given, expected) {
  if (typeof given !== "string" || typeof expected !== "string" || !expected) return false;
  const a = createHash("sha256").update(given).digest();
  const b = createHash("sha256").update(expected).digest();
  return timingSafeEqual(a, b);
}

// onHook(name, body) -> { status, body } | Promise thereof. Returns the server.
export function startHookServer({ port, host = "0.0.0.0", secret, onHook, log = console.log }) {
  const server = createServer((req, res) => {
    const reply = (status, obj) => { res.writeHead(status, { "content-type": "application/json" }); res.end(JSON.stringify(obj) + "\n"); };
    const m = /^\/hooks\/([a-z0-9-]{1,40})$/.exec(req.url ?? "");
    if (req.url === "/healthz") return reply(200, { ok: true });
    if (!m) return reply(404, { error: "not found: the only routes are POST /hooks/<name> and GET /healthz" });
    if (req.method !== "POST") return reply(405, { error: "hooks are POST only" });
    if (!secret) return reply(503, { error: "EPITO_HOOK_SECRET is not set on the daemon, so hooks are closed" });
    if (!secretsMatch(req.headers["x-epito-secret"], secret)) return reply(401, { error: "x-epito-secret header missing or wrong" });
    const chunks = []; let size = 0;
    req.on("data", (c) => { size += c.length; if (size <= MAX_BODY) chunks.push(c); });
    req.on("end", async () => {
      if (size > MAX_BODY) return reply(413, { error: `body over ${MAX_BODY} bytes` });
      try {
        const out = await onHook(m[1], Buffer.concat(chunks).toString("utf8"));
        reply(out.status, out.body);
      } catch (e) { reply(500, { error: e.message }); }
    });
  });
  server.listen(port, host, () => log(`hooks listening on http://${host}:${port}/hooks/<name>`));
  return server;
}
