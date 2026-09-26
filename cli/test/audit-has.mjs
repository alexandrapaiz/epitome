#!/usr/bin/env node
// Test helper: assert .epito/audit.jsonl contains lines matching a pattern.
// Matching by JSON predicate rather than by substring, because a substring
// match against a serialized object is really an assertion about key ORDER,
// and key order is not a promise this runtime makes.
//
//   node test/audit-has.mjs '{"agent":"pm","action":"run.end","trigger":"hook"}'
//   node test/audit-has.mjs '{"action":"slack.post","posted":true}' 3
//   node test/audit-has.mjs --count '{"agent":"clock"}'     # print, never fail
//
// A value of true in the pattern means "this key is present and truthy"; a
// string value beginning with "~" is a substring match on that field; an
// object value is compared by shape, so a nested `permissions` can be asserted
// without asserting its key order either.
import { readFileSync, existsSync } from "node:fs";

const args = process.argv.slice(2);
const countOnly = args[0] === "--count";
const [patternRaw, minRaw] = countOnly ? args.slice(1) : args;
const pattern = JSON.parse(patternRaw);
const min = Number(minRaw) || 1;

const lines = existsSync(".epito/audit.jsonl")
  ? readFileSync(".epito/audit.jsonl", "utf8").trim().split("\n").filter(Boolean)
      .flatMap((l) => { try { return [JSON.parse(l)]; } catch { return []; } })
  : [];

const matches = (line) => Object.entries(pattern).every(([k, want]) => {
  const got = line[k];
  if (want === true) return Boolean(got);
  if (typeof want === "string" && want.startsWith("~")) return typeof got === "string" && got.includes(want.slice(1));
  if (want && typeof want === "object") {
    if (!got || typeof got !== "object") return false;
    const w = Object.entries(want), g = Object.entries(got);
    return w.length === g.length && w.every(([k, v]) => got[k] === v);
  }
  return got === want;
});

const hits = lines.filter(matches);
if (countOnly) { console.log(hits.length); process.exit(0); }
if (hits.length >= min) process.exit(0);
console.error(`audit-has: wanted ${min} line(s) matching ${patternRaw}, found ${hits.length} in ${lines.length} audit lines`);
for (const l of lines.slice(-8)) console.error(`  last> ${JSON.stringify(l)}`);
process.exit(1);
