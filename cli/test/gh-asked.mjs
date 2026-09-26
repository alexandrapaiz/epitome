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
//
// Exits 0 when the claim holds, 1 with the reason on stderr when it does not.
// Empty evidence is a failure, not a pass: "no requests" must never read as
// "every request was fine".
import { readFileSync } from "node:fs";

const [what, logPath, a, b] = process.argv.slice(2);
const lines = readFileSync(logPath, "utf8").trim().split("\n").filter(Boolean).map((l) => JSON.parse(l));
const die = (why) => { console.error(why); process.exit(1); };

if (lines.length === 0) die(`${logPath} is empty: nothing asked GitHub for anything, so there is nothing to assert`);

if (what === "jwt") {
  const bad = lines.filter((r) => !r.jwtOk || r.iss !== a);
  if (bad.length) die(`${bad.length} of ${lines.length} requests did not carry a verified JWT from App ${a}: ${JSON.stringify(bad[0])}`);
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
} else die(`unknown claim "${what}" — try jwt or mint`);
