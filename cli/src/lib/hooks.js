// The daemon's ingress: node:http, four POST routes, one shared secret.
//
//   POST /hooks/<name>     an event wakes an agent (body = payload, uninterpreted)
//   POST /message/<name>   {"text": "..."} speaks to an agent in its held session
//   POST /window/open      {"scope": "...", "text": "..."} opens work windows
//   POST /window/close     {"scope": "..."} closes them
//   POST /board            a seat files a run report or a note on the board
//   GET  /board            the board (JSON, or ?format=text for the table)
//   GET  /healthz
//
// The compare is constant-time (crypto.timingSafeEqual over equal-length
// digests) so a wrong secret leaks nothing about how wrong it is. Hook bodies
// are read (capped) but not interpreted: an event is a wake-up, and the
// agent's charter decides what to do with it. Message and window bodies ARE
// interpreted — they are JSON with a text field — and a malformed one is
// refused by name, in the product's voice, not swallowed.
import { createServer } from "node:http";
import { inRepo } from "./where.js";
import { createHash, timingSafeEqual } from "node:crypto";

const MAX_BODY = 64 * 1024;
const NAME = "[a-z0-9-]{1,40}";

const ROUTES = [
  { route: "hook", method: "POST", re: new RegExp(`^/hooks/(${NAME})$`) },
  { route: "message", method: "POST", re: new RegExp(`^/message/(${NAME})$`) },
  { route: "window.open", method: "POST", re: /^\/window\/open$/ },
  { route: "window.close", method: "POST", re: /^\/window\/close$/ },
  // The board is the one path that answers to two methods: a seat anywhere
  // files onto it, and anyone with the secret reads it back.
  { route: "board.write", method: "POST", re: /^\/board$/ },
  { route: "board.read", method: "GET", re: /^\/board$/ },
];

const ROUTE_LIST = "POST /hooks/<name>, POST /message/<name>, POST /window/open, POST /window/close, POST /board, GET /board, GET /healthz";

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
    // Matched on path FIRST, then on method, so /board can be two routes and a
    // wrong method still says which methods the path takes rather than 404ing.
    const onPath = ROUTES.map((r) => ({ ...r, m: r.re.exec(url) })).filter((r) => r.m);
    if (!onPath.length) return reply(404, { error: `not found: the routes are ${ROUTE_LIST}` });
    const hit = onPath.find((r) => r.method === req.method);
    if (!hit) return reply(405, { error: `${url} is ${onPath.map((r) => r.method).join(" and ")} only` });
    if (!secret) return reply(503, { error: "EPITO_HOOK_SECRET is not set on the daemon, so the ingress is closed" });
    if (!secretsMatch(req.headers["x-epito-secret"], secret)) return reply(401, { error: "x-epito-secret header missing or wrong" });
    const chunks = []; let size = 0;
    req.on("data", (c) => { size += c.length; if (size <= MAX_BODY) chunks.push(c); });
    req.on("end", async () => {
      if (size > MAX_BODY) return reply(413, { error: `body over ${MAX_BODY} bytes` });
      const raw = Buffer.concat(chunks).toString("utf8");
      let json = null;
      if (hit.route !== "hook" && hit.method !== "GET") {
        // /window/* may be called bare; /message/<name> and /board may not.
        const needsBody = hit.route === "message" || hit.route === "board.write";
        if (needsBody || raw.trim()) {
          const parsed = parseJsonBody(raw, url);
          if (parsed.error) return reply(400, { error: parsed.error });
          json = parsed.body;
        } else json = {};
      }
      const query = Object.fromEntries(new URL(req.url ?? "/", "http://ingress").searchParams);
      try {
        const out = await onRequest({ route: hit.route, name: hit.m[1] ?? null, raw, json, query });
        // A route may answer with something that is not JSON — `GET
        // /board?format=text` is a table meant for a terminal, and wrapping it
        // in a JSON string would make `curl` print escape sequences.
        if (out.text !== undefined) {
          res.writeHead(out.status, { "content-type": "text/plain; charset=utf-8" });
          return res.end(out.text.endsWith("\n") ? out.text : out.text + "\n");
        }
        reply(out.status, out.body);
      } catch (e) { reply(500, { error: e.message }); }
    });
  });
  // A port that is already taken is the normal way `epito run` is run twice,
  // and it used to end the process with fourteen lines of Node stack trace
  // headed "Emitted 'error' event on Server instance" -- below the bar every
  // other error in this product is held to, and `epito deploy` already clears
  // it for the same condition on its own listener.
  //
  // It also lands at the worst moment: the reconcile is finished by the time
  // the ingress binds, so the engine HAS been changed and the operator is
  // staring at a crash. On the host that matters twice over, because
  // epitod.service is already holding this port, so the hand-run `epito run`
  // of the deploy instructions is exactly the command that hits this.
  server.on("error", (e) => {
    if (e.code === "EADDRINUSE") {
      console.error(`epito: the roster is on the engine, but the ingress could not start: something is already listening on ${host}:${port}.

That is usually epitod itself: \`systemctl status epitod\` (the reconcile above
already landed, so a running epitod needs \`systemctl reload epitod\`, not a
second one). Fix: stop it, or give this one its own port with EPITO_PORT.`);
    } else if (e.code === "EACCES") {
      console.error(`epito: the ingress may not listen on ${host}:${port} (${e.code}) — a port below 1024 needs root. Fix: set EPITO_PORT to a port above 1024 and put Caddy in front of it, which is what ${inRepo("deploy/provision-host.sh")} does.`);
    } else {
      console.error(`epito: the ingress could not listen on ${host}:${port} (${e.code ?? e.message})`);
    }
    process.exit(1);
  });
  server.listen(port, host, () => log(`ingress listening on http://${host}:${port} (${ROUTE_LIST})`));
  return server;
}
