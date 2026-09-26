#!/usr/bin/env node
// Reads test/github-stub.mjs's request log and answers the two questions the
// identity slice has to be right about, so smoke-temporal.sh can ask them
// without a paragraph of nested shell quoting:
//
//   node test/gh-asked.mjs jwt <log> <appId>     every request carried a JWT
//                                                the stub VERIFIED, issued by
//                                                that App and nobody else
//   node test/gh-asked.mjs mint <log> <perms> <repo>
//                                                every access-token request
//                                                asked for exactly <perms>
//                                                (k:v,k:v) on exactly <repo>
//   node test/gh-asked.mjs bot <log> <login>     the commit identity was read
//                                                the way GitHub requires it:
//                                                GET /app as the App, then
//                                                GET /users/<login> as the
//                                                INSTALLATION, and accepted
//
// Exits 0 when the claim holds, 1 with the reason on stderr when it does not.
// Empty evidence is a failure, not a pass: "no requests" must never read as
// "every request was fine".
import { readFileSync } from "node:fs";

const [what, logPath, a, b] = process.argv.slice(2);
const lines = readFileSync(logPath, "utf8").trim().split("\n").filter(Boolean).map((l) => JSON.parse(l));
const die = (why) => { console.error(why); process.exit(1); };

if (lines.length === 0) die(`${logPath} is empty: nothing asked GitHub for anything, so there is nothing to assert`);

// GET /users/<login> authenticates as the installation, not as the App —
// GitHub rejects an App JWT there — so it is not evidence for or against the
// JWT claim. Every OTHER request epito makes is made as the App.
const asApp = lines.filter((r) => !/^\/users\//.test(r.url));

if (what === "jwt") {
  if (asApp.length === 0) die(`${logPath} holds no request made as the App, so there is nothing to assert`);
  const bad = asApp.filter((r) => !r.jwtOk || r.iss !== a);
  if (bad.length) die(`${bad.length} of ${asApp.length} App requests did not carry a verified JWT from App ${a}: ${JSON.stringify(bad[0])}`);
} else if (what === "mint") {
  const want = Object.fromEntries(a.split(",").map((p) => p.split(":")));
  const mints = lines.filter((r) => /access_tokens/.test(r.url));
  if (mints.length === 0) die("no access-token request was made at all");
  for (const m of mints) {
    const body = JSON.parse(m.body ?? "{}");
    const got = body.permissions ?? {};
    const same = Object.keys(want).length === Object.keys(got).length && Object.entries(want).every(([k, v]) => got[k] === v);
    if (!same) die(`a mint asked for ${JSON.stringify(got)}, not ${JSON.stringify(want)} — the manifest is the ceiling`);
    if (JSON.stringify(body.repositories) !== JSON.stringify([b])) die(`a mint asked for repositories ${JSON.stringify(body.repositories)}, not ["${b}"] — a token is scoped to one repository`);
  }
} else if (what === "bot") {
  const app = lines.filter((r) => r.url === "/app");
  if (app.length === 0) die("nothing asked GET /app, so the bot user was never identified and the commits cannot be the agent's");
  if (app.some((r) => !r.jwtOk)) die("GET /app was made without a verified App JWT");
  const users = lines.filter((r) => r.url === `/users/${encodeURIComponent(a)}`);
  if (users.length === 0) die(`nothing asked GET /users/${a}; the looked-up logins were: ${lines.filter((r) => /^\/users\//.test(r.url)).map((r) => r.url).join(", ") || "(none)"}`);
  const refused = users.filter((r) => r.why !== null);
  if (refused.length) die(`GET /users/${a} was made with the wrong credential (${refused[0].why}) — that endpoint takes the installation token, not the App JWT`);
} else die(`unknown claim "${what}" — try jwt, mint or bot`);
