// A git smart-HTTP server that demands one exact credential, for proving what
// `epito` hands to `git` — not what it meant to hand it.
//
//   node test/git-http-stub.mjs <port> <repos-dir> <expected-password> <log.jsonl>
//
// It answers the two routes `git clone` over https actually uses, and refuses
// both with 401 unless the request carries
// `Authorization: Basic base64("x-access-token:<expected-password>")`. Every
// attempt, authorized or not, is appended to the log as
// {route, user, password, ok} — so a test can assert WHICH credential git
// offered, which is the only way to tell "the agent's own token" from "the
// box's human token" from the outside.
//
// Spends nothing, reaches nobody: `git upload-pack` runs against a local bare
// repo and the socket is on 127.0.0.1.
import { createServer } from "node:http";
import { spawn } from "node:child_process";
import { appendFileSync } from "node:fs";
import { join, resolve } from "node:path";

const [port, reposDir, expected, logPath] = process.argv.slice(2);
const record = (o) => appendFileSync(logPath, JSON.stringify(o) + "\n");

// git's pkt-line framing: a 4-hex length that counts itself.
const pkt = (s) => Buffer.from((s.length + 4).toString(16).padStart(4, "0") + s);
const FLUSH = Buffer.from("0000");

function credential(req) {
  const m = /^Basic (.+)$/.exec(req.headers.authorization ?? "");
  if (!m) return null;
  const [user, ...rest] = Buffer.from(m[1], "base64").toString().split(":");
  return { user, password: rest.join(":") };
}

// A path is only ever joined onto the repos dir after the join is checked to
// land inside it: this is a test server, but it is still a server.
function repoPath(name) {
  const abs = resolve(join(reposDir, name));
  return abs.startsWith(resolve(reposDir)) ? abs : null;
}

createServer((req, res) => {
  const chunks = [];
  req.on("data", (d) => chunks.push(d));
  req.on("end", () => {
    const [path, query] = req.url.split("?");
    const cred = credential(req);
    const advertise = /^\/(.+?)\/info\/refs$/.exec(path);
    const fetchRpc = /^\/(.+?)\/git-upload-pack$/.exec(path);
    const route = advertise ? "info/refs" : fetchRpc ? "git-upload-pack" : path;
    const ok = !!cred && cred.user === "x-access-token" && cred.password === expected;
    record({ route, user: cred?.user ?? null, password: cred?.password ?? null, ok });

    if (!ok) {
      // The WWW-Authenticate header is what makes git ask a credential helper
      // at all, so the whole point of the test depends on sending it.
      res.writeHead(401, { "www-authenticate": 'Basic realm="git"' });
      return res.end("this repository wants the agent's own token\n");
    }

    const repo = repoPath(advertise?.[1] ?? fetchRpc?.[1] ?? "");
    if (!repo) { res.writeHead(400); return res.end("no such repo\n"); }

    if (advertise && query === "service=git-upload-pack") {
      res.writeHead(200, { "content-type": "application/x-git-upload-pack-advertisement", "cache-control": "no-cache" });
      res.write(Buffer.concat([pkt("# service=git-upload-pack\n"), FLUSH]));
      const p = spawn("git", ["upload-pack", "--stateless-rpc", "--advertise-refs", repo]);
      p.stdout.pipe(res);
      p.stderr.on("data", () => {});
      return;
    }
    if (fetchRpc && req.method === "POST") {
      res.writeHead(200, { "content-type": "application/x-git-upload-pack-result", "cache-control": "no-cache" });
      const p = spawn("git", ["upload-pack", "--stateless-rpc", repo]);
      p.stdin.end(Buffer.concat(chunks));
      p.stdout.pipe(res);
      p.stderr.on("data", () => {});
      return;
    }
    res.writeHead(404);
    res.end("no route\n");
  });
}).listen(Number(port), "127.0.0.1", function () {
  // The BOUND port, not the asked-for one: a caller passing 0 reads the real
  // one back off this line rather than racing another test for a fixed port.
  console.log(`git-http-stub on ${this.address().port}`);
});
