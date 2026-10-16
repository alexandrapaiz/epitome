// A NATS client, in one file, over node:net.
//
// Why not the official library. `npm i -g epito` is 148 KB and the test suite
// asserts it (cli/test/pack.sh); Temporal is an optional peer dependency for
// exactly that reason, and a box that wants the engine installs it. The bus is
// different in kind: it is how a seat is WOKEN, so a runtime that cannot reach
// the bus until somebody runs a second install is a runtime whose events sit
// in a stream nobody reads. The wire protocol is nine verbs of line-oriented
// text and JetStream is request/reply over it, which is less code than the
// refusal message explaining that the client is missing would be.
//
// What this does NOT do, deliberately: TLS, authentication beyond a token or
// user/password in the URL, reconnect with buffered publishes, clustering,
// key/value, object store. The bus epito consumes is on the same host as the
// runtime (ADR-16's log is local too), and each of those is a feature to add
// when a box needs it rather than a thousand lines carried by every install.
import { createConnection } from "node:net";
import { randomBytes } from "node:crypto";

const CRLF = "\r\n";
const inbox = () => `_INBOX.${randomBytes(12).toString("hex")}`;

// nats://[user:pass@]host[:port] — the one form a box writes in an env file.
export function parseBusUrl(url) {
  const m = /^(?:nats:\/\/)?(?:([^@/]*)@)?([^:/?#]+)(?::(\d+))?\/?$/.exec(String(url).trim());
  if (!m) return { error: `EPITO_BUS_URL is "${url}", which is not a bus address — the form is nats://host:port, e.g. nats://127.0.0.1:4222. Fix: set EPITO_BUS_URL to that, or unset it to take the default.` };
  const [, auth, host, port] = m;
  const creds = auth ? auth.split(":") : [];
  return { host, port: Number(port) || 4222, user: creds[0] || null, pass: creds[1] ?? null };
}

// Headers arrive and leave as the protocol writes them: a version line, then
// `Key: Value` lines. A status (404 No Messages, 408 Request Timeout, 503 no
// responders) rides on the version line itself, which is how a pull request
// that found nothing is told apart from one that found a message with no body.
function parseHeaders(raw) {
  const lines = raw.split(CRLF);
  const first = lines.shift() ?? "";
  const status = /^NATS\/1\.0\s+(\d{3})(?:\s+(.*))?$/.exec(first);
  const headers = {};
  for (const line of lines) {
    if (!line) continue;
    const i = line.indexOf(":");
    if (i > 0) headers[line.slice(0, i).trim()] = line.slice(i + 1).trim();
  }
  return { headers, status: status ? Number(status[1]) : null, statusText: status?.[2] ?? null };
}

export function encodeHeaders(headers) {
  const lines = [`NATS/1.0`];
  for (const [k, v] of Object.entries(headers)) lines.push(`${k}: ${v}`);
  return `${lines.join(CRLF)}${CRLF}${CRLF}`;
}

// `$JS.ACK.<stream>.<consumer>.<delivered>.<stream seq>.<consumer seq>.<ts>.<pending>`
// with two extra tokens in front when the server runs with a domain. Counted
// from the end rather than the start, so a domain does not shift the fields
// this runtime reads — `delivered` is the one that says "this event has been
// tried before", which is the whole evidence that redelivery works.
export function parseAckSubject(reply) {
  const t = String(reply ?? "").split(".");
  if (t.length < 9 || t[0] !== "$JS" || t[1] !== "ACK") return null;
  const base = t.length === 9 ? 2 : 4;
  return {
    stream: t[base], consumer: t[base + 1],
    delivered: Number(t[base + 2]), streamSeq: Number(t[base + 3]), consumerSeq: Number(t[base + 4]),
    pending: Number(t[base + 6]),
  };
}

class Bus {
  constructor(socket, { url }) {
    this.socket = socket;
    this.url = url;
    this.buf = Buffer.alloc(0);
    this.subs = new Map();          // sid -> handler
    this.sid = 0;
    this.info = null;
    this.closed = false;
    this.error = null;
    socket.on("data", (d) => this.#onData(d));
    socket.on("error", (e) => { this.error = e; });
    socket.on("close", () => { this.closed = true; });
  }

  send(line) { if (!this.closed) this.socket.write(line); }

  // The wire is text with byte-counted payloads, so a frame may arrive in
  // pieces and two frames may arrive in one read. Everything hangs off that:
  // the parser consumes whole frames only and leaves the remainder alone.
  #onData(chunk) {
    this.buf = this.buf.length ? Buffer.concat([this.buf, chunk]) : chunk;
    for (;;) {
      const end = this.buf.indexOf(CRLF);
      if (end === -1) return;
      const line = this.buf.subarray(0, end).toString("utf8");
      const verb = line.split(" ", 1)[0].toUpperCase();

      if (verb === "MSG" || verb === "HMSG") {
        const parts = line.split(/\s+/);
        const hdrLen = verb === "HMSG" ? Number(parts[parts.length - 2]) : 0;
        const total = Number(parts[parts.length - 1]);
        const start = end + 2;
        if (this.buf.length < start + total + 2) return;      // payload not all here yet
        const frame = this.buf.subarray(start, start + total);
        this.buf = this.buf.subarray(start + total + 2);
        const [, subject, sid, maybeReply] = parts;
        const reply = verb === "HMSG"
          ? (parts.length === 6 ? maybeReply : null)
          : (parts.length === 5 ? maybeReply : null);
        const { headers, status, statusText } = hdrLen
          ? parseHeaders(frame.subarray(0, hdrLen).toString("utf8").replace(/\r\n\r\n$/, ""))
          : { headers: {}, status: null, statusText: null };
        const handler = this.subs.get(sid);
        if (handler) handler({ subject, reply, headers, status, statusText, data: frame.subarray(hdrLen).toString("utf8") });
        continue;
      }

      this.buf = this.buf.subarray(end + 2);
      if (verb === "PING") { this.send(`PONG${CRLF}`); continue; }
      if (verb === "INFO") { try { this.info = JSON.parse(line.slice(5)); } catch { /* an INFO we cannot read is not fatal */ } continue; }
      if (verb === "-ERR") { this.error = new Error(line.slice(5).replace(/^'|'$/g, "")); continue; }
      // +OK and PONG need nothing: this client is not verbose and pings on a
      // deadline of its own.
    }
  }

  subscribe(subject, handler) {
    const sid = String(++this.sid);
    this.subs.set(sid, handler);
    this.send(`SUB ${subject} ${sid}${CRLF}`);
    return { sid, unsubscribe: () => { this.subs.delete(sid); this.send(`UNSUB ${sid}${CRLF}`); } };
  }

  publish(subject, payload = "", { reply = "", headers = null } = {}) {
    const body = Buffer.from(payload, "utf8");
    if (headers) {
      const h = Buffer.from(encodeHeaders(headers), "utf8");
      this.send(`HPUB ${subject} ${reply} ${h.length} ${h.length + body.length}${CRLF}`);
      this.socket.write(Buffer.concat([h, body, Buffer.from(CRLF)]));
      return;
    }
    this.send(`PUB ${subject} ${reply} ${body.length}${CRLF}`);
    this.socket.write(Buffer.concat([body, Buffer.from(CRLF)]));
  }

  // One request, one reply, one deadline. `no_responders` is on in CONNECT, so
  // a subject nothing is listening on comes back as a 503 status rather than as
  // a timeout — that is the difference between "JetStream is not enabled on
  // this server" and "the server is slow", and an operator should not have to
  // wait out a timeout to learn which.
  request(subject, payload = "", { timeoutMs = 5000 } = {}) {
    return new Promise((resolve, reject) => {
      const box = inbox();
      const sub = this.subscribe(box, (msg) => { clearTimeout(timer); sub.unsubscribe(); resolve(msg); });
      const timer = setTimeout(() => {
        sub.unsubscribe();
        reject(new Error(`the bus at ${this.url} did not answer ${subject} within ${timeoutMs}ms`));
      }, timeoutMs);
      this.publish(subject, payload, { reply: box });
    });
  }

  // The JetStream API is request/reply with JSON both ways, and its errors are
  // a field in the reply rather than a transport failure. They are turned into
  // thrown Errors carrying the server's own code, so a caller can tell "no
  // such stream" (10059) from "overlapping filter subjects" (10136) without
  // matching on prose.
  async api(path, body = {}, { timeoutMs = 5000 } = {}) {
    const msg = await this.request(`$JS.API.${path}`, JSON.stringify(body), { timeoutMs });
    if (msg.status === 503) {
      const e = new Error(`JetStream is not answering on the bus at ${this.url} — the server is up and the stream API is not. Fix: start nats-server with -js (or jetstream {} in its config), which is what makes a stream durable.`);
      e.jetstream = false;
      throw e;
    }
    let out;
    try { out = JSON.parse(msg.data); }
    catch { throw new Error(`the bus answered ${path} with something that is not JSON: ${msg.data.slice(0, 120)}`); }
    if (out.error) {
      const e = new Error(out.error.description ?? `${path} refused (${out.error.err_code})`);
      e.code = out.error.err_code;
      e.status = out.error.code;
      throw e;
    }
    return out;
  }

  // A pull consumer's fetch: ask for up to `batch`, wait no longer than
  // `expiresMs`, and hand back what came. The status messages are the protocol
  // saying "nothing for you" (404) and "your request expired" (408); both mean
  // an empty batch, and neither is an error.
  fetch({ stream, consumer, batch = 1, expiresMs = 20000 }) {
    return new Promise((resolve, reject) => {
      const box = inbox();
      const msgs = [];
      const done = () => { clearTimeout(timer); sub.unsubscribe(); resolve(msgs); };
      const sub = this.subscribe(box, (msg) => {
        if (msg.status === 404 || msg.status === 408 || msg.status === 409) return done();
        if (msg.status && msg.status >= 400) { clearTimeout(timer); sub.unsubscribe(); return reject(new Error(`the bus refused the pull (${msg.status} ${msg.statusText ?? ""})`.trim())); }
        msgs.push({ ...msg, meta: parseAckSubject(msg.reply) });
        if (msgs.length >= batch) done();
      });
      // The deadline is the server's expiry plus a second: if the server's
      // 408 is lost, the fetch still ends rather than wedging the seat's loop.
      const timer = setTimeout(done, expiresMs + 1000);
      this.publish(`$JS.API.CONSUMER.MSG.NEXT.${stream}.${consumer}`, JSON.stringify({ batch, expires: expiresMs * 1e6 }), { reply: box });
    });
  }

  ack(msg) { if (msg.reply) this.publish(msg.reply, ""); }
  // `-NAK {"delay": ns}`: do not give it to me again just yet. The delay is
  // what keeps a seat whose runs cannot start (a dead engine, say) from
  // spinning the same event through the loop as fast as the socket allows,
  // while still redelivering it until a run takes it.
  nak(msg, delayMs = 0) { if (msg.reply) this.publish(msg.reply, delayMs > 0 ? `-NAK ${JSON.stringify({ delay: delayMs * 1e6 })}` : "-NAK"); }

  close() { this.closed = true; try { this.socket.end(); this.socket.destroy(); } catch { /* already gone */ } }
}

// Connect, handshake, and prove it with a PING. Everything that can go wrong
// here is an ordinary operating condition on the box the runtime runs on — the
// server is down, the address is wrong, the port belongs to something else —
// so each comes back as one sentence naming the fix, never a stack.
export function connectBus({ url, name = "epito", timeoutMs = 3000 } = {}) {
  const parsed = parseBusUrl(url);
  if (parsed.error) return Promise.reject(Object.assign(new Error(parsed.error), { epitoHandled: true }));
  return new Promise((resolve, reject) => {
    const socket = createConnection({ host: parsed.host, port: parsed.port });
    socket.setNoDelay(true);
    const fail = (msg) => { socket.destroy(); reject(Object.assign(new Error(msg), { epitoHandled: true })); };
    const timer = setTimeout(() => fail(`nothing answered the bus handshake at ${url} within ${timeoutMs}ms — a port that accepts a connection and never speaks NATS is usually something else listening there. Fix: check EPITO_BUS_URL, and \`nats --server ${url} server check connection\` if the nats CLI is on this box.`), timeoutMs);
    socket.once("error", (e) => {
      clearTimeout(timer);
      fail(e.code === "ECONNREFUSED"
        ? `nothing is answering the bus at ${url} — the runtime consumes events from it, so a seat whose only trigger is a subscription will not be woken until it is back. Fix: start nats-server on that address (with JetStream enabled), or point EPITO_BUS_URL at the one this box should use.`
        : `the bus at ${url} could not be reached (${e.code ?? e.message}).`);
    });
    socket.once("connect", () => {
      const bus = new Bus(socket, { url });
      // INFO arrives unprompted; CONNECT answers it. `headers: true` is what
      // makes a pull request's 404/408 legible, and `no_responders: true` is
      // what makes a missing JetStream immediate instead of a timeout.
      const opts = { verbose: false, pedantic: false, tls_required: false, name, lang: "node", version: "epito", protocol: 1, headers: true, no_responders: true };
      if (parsed.user) { opts.user = parsed.user; if (parsed.pass !== null) opts.pass = parsed.pass; }
      if (parsed.user && parsed.pass === null) { delete opts.user; opts.auth_token = parsed.user; }
      bus.send(`CONNECT ${JSON.stringify(opts)}${CRLF}`);
      bus.request("$JS.API.INFO", "", { timeoutMs }).then(
        () => { clearTimeout(timer); if (bus.error) return fail(`the bus at ${url} refused this client: ${bus.error.message}`); resolve(bus); },
        (e) => { clearTimeout(timer); fail(bus.error ? `the bus at ${url} refused this client: ${bus.error.message}` : e.message); },
      );
    });
  });
}
