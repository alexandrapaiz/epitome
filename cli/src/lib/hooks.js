// The daemon's ingress: node:http, four POST routes, one shared secret.
//
//   POST /hooks/<name>     an event wakes an agent (body = payload, uninterpreted)
//   POST /message/<name>   {"text": "..."} speaks to an agent in its held session
//   POST /window/open      {"scope": "...", "text": "..."} opens work windows
//   POST /window/close     {"scope": "..."} closes them
//   GET  /healthz
//
// The compare is constant-time (crypto.timingSafeEqual over equal-length
// digests) so a wrong secret leaks nothing about how wrong it is. Hook bodies
// are read (capped) but not interpreted: an event is a wake-up, and the
// agent's charter decides what to do with it. Message and window bodies ARE
// interpreted — they are JSON with a text field — and a malformed one is
// refused by name, in the product's voice, not swallowed.
import { createServer } from "node:http";
import { createHash, timingSafeEqual } from "node:crypto";

const MAX_BODY = 64 * 1024;
const NAME = "[a-z0-9-]{1,40}";

const ROUTES = [
  { route: "hook", method: "POST", re: new RegExp(`^/hooks/(${NAME})$`) },
  { route: "message", method: "POST", re: new RegExp(`^/message/(${NAME})$`) },
  { route: "window.open", method: "POST", re: /^\/window\/open$/ },
  { route: "window.close", method: "POST", re: /^\/window\/close$/ },
];

const ROUTE_LIST = "POST /hooks/<name>, POST /message/<name>, POST /window/open, POST /window/close, GET /healthz";

export function secretsMatch(given, expected) {
  if (typeof given !== "string" || typeof expected !== "string" || !expected) return false;
  const a = createHash("sha256").update(given).digest();
  const b = createHash("sha256").update(expected).digest();
  return timingSafeEqual(a, b);
}

// Parse a JSON body into an object, or return the error the caller should see.
export function parseJsonBody(raw, route) {
  if (!raw.trim()) return { error: `${route} needs a JSON body — send {"text": "..."} with content-type application/json` };
  let obj;
  try { obj = JSON.parse(raw); } catch (e) { return { error: `${route} body is not JSON: ${e.message}` }; }
  if (obj === null || typeof obj !== "object" || Array.isArray(obj)) return { error: `${route} body must be a JSON object, got ${Array.isArray(obj) ? "an array" : typeof obj}` };
  return { body: obj };
}

// onRequest({ route, name, raw, json }) -> { status, body } | Promise thereof.
// Returns the server.
// `onHealth` lets the caller say more than "this process is up". In epitod v1
// the interesting question is whether the ENGINE is reachable, because an
// ingress that answers 200 while Temporal is down is a liveness check that
// lies. It stays secret-free: a health probe that needs a credential is a
// health probe nobody wires up.
export function startHookServer({ port, host = "0.0.0.0", secret, onRequest, onHealth, log = console.log }) {
  const server = createServer((req, res) => {
    const reply = (status, obj) => { res.writeHead(status, { "content-type": "application/json" }); res.end(JSON.stringify(obj) + "\n"); };
    const url = (req.url ?? "").split("?")[0];
    if (url === "/healthz") {
      if (!onHealth) return reply(200, { ok: true });
      return Promise.resolve()
        .then(() => onHealth())
        .then((h) => reply(h.ok ? 200 : 503, h))
        .catch((e) => reply(503, { ok: false, error: e.message }));
    }
    const hit = ROUTES.map((r) => ({ ...r, m: r.re.exec(url) })).find((r) => r.m);
    if (!hit) return reply(404, { error: `not found: the routes are ${ROUTE_LIST}` });
    if (req.method !== hit.method) return reply(405, { error: `${url} is ${hit.method} only` });
    if (!secret) return reply(503, { error: "EPITO_HOOK_SECRET is not set on the daemon, so the ingress is closed" });
    if (!secretsMatch(req.headers["x-epito-secret"], secret)) return reply(401, { error: "x-epito-secret header missing or wrong" });
    const chunks = []; let size = 0;
    req.on("data", (c) => { size += c.length; if (size <= MAX_BODY) chunks.push(c); });
    req.on("end", async () => {
      if (size > MAX_BODY) return reply(413, { error: `body over ${MAX_BODY} bytes` });
      const raw = Buffer.concat(chunks).toString("utf8");
      let json = null;
      if (hit.route !== "hook") {
        // /window/* may be called bare; /message/<name> may not.
        const needsBody = hit.route === "message";
        if (needsBody || raw.trim()) {
          const parsed = parseJsonBody(raw, url);
          if (parsed.error) return reply(400, { error: parsed.error });
          json = parsed.body;
        } else json = {};
      }
      try {
        const out = await onRequest({ route: hit.route, name: hit.m[1] ?? null, raw, json });
        reply(out.status, out.body);
      } catch (e) { reply(500, { error: e.message }); }
    });
  });
  server.listen(port, host, () => log(`ingress listening on http://${host}:${port} (${ROUTE_LIST})`));
  return server;
}
