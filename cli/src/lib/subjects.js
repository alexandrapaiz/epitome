// The grammar of a bus subject, and the one question a pair of them raises.
//
// `[trigger].subscriptions` is a list of NATS subject filters, and the
// validator refuses a bad one for the same reason it parses a cron expression
// rather than counting its fields: the server would refuse it at startup, on a
// box, at whatever hour the runtime happened to restart — and the author who
// can fix it is reading `epito validate` right now (spec v0.2, "Subscriptions:
// which events wake this seat").
//
// This module holds no client and knows nothing about a connection, so the
// manifest validator can import it without the manifest commands gaining a
// socket. Same rule src/temporal/env.js follows for the engine.

// A token is anything but a dot, a space and the two wildcards; the wildcards
// are tokens in their own right, never characters inside one. `>` is the tail
// and may only be last — "asc.>.posted" is the mistake this catches, and it is
// the one everybody makes once.
const TOKEN_RE = /^[^.\s*>]+$/;

export function subjectErrors(subject, where) {
  const say = (msg) => [`${where} ${msg}`];
  if (typeof subject !== "string" || !subject.length) {
    return say(`must be a subject, got ${subject === undefined ? "nothing" : JSON.stringify(subject)} — a subscription is the subject the bus publishes on, e.g. "asc.events.*.message.posted". Fix: write the subject as a string, or drop the entry.`);
  }
  if (/[\s]/.test(subject)) {
    return say(`"${subject}" has whitespace in it, and a subject has none — it is dot-separated tokens. Fix: "${subject.replace(/\s+/g, "")}", if that is what you meant.`);
  }
  const tokens = subject.split(".");
  if (tokens.some((t) => t === "")) {
    return say(`"${subject}" has an empty token — a subject is tokens separated by single dots, and a leading, trailing or doubled dot leaves one of them with nothing in it. Fix: "${tokens.filter(Boolean).join(".")}".`);
  }
  const tail = tokens.indexOf(">");
  if (tail !== -1 && tail !== tokens.length - 1) {
    return say(`"${subject}" puts ">" in the middle, and ">" means "every token from here to the end", so nothing may follow it. Fix: "${tokens.slice(0, tail + 1).join(".")}" to take everything under that prefix, or "*" for exactly one token: "${tokens.map((t) => (t === ">" ? "*" : t)).join(".")}".`);
  }
  const bad = tokens.find((t) => t !== "*" && t !== ">" && !TOKEN_RE.test(t));
  if (bad !== undefined) {
    return say(`"${subject}" has a token the bus cannot carry ("${bad}") — "*" and ">" are whole tokens, never characters inside one. Fix: make the wildcard its own token, e.g. "${tokens.map((t) => (t === bad ? "*" : t)).join(".")}".`);
  }
  return [];
}

// Do two filters have any subject in common? A consumer may not hold two
// filters that do (the server refuses the pair), and a roster is the place
// where somebody writes `asc.events.>` under a line that already says
// `asc.events.asc.message.posted` and cannot see why the seat stopped waking.
export function subjectsOverlap(a, b) {
  const A = a.split("."), B = b.split(".");
  for (let i = 0; ; i++) {
    const x = A[i], y = B[i];
    if (x === undefined && y === undefined) return true;      // same length, every token matched
    if (x === ">") return B.length > i;                        // ">" swallows the rest, if there is a rest
    if (y === ">") return A.length > i;
    if (x === undefined || y === undefined) return false;      // one ran out: different depths
    if (x === "*" || y === "*" || x === y) continue;
    return false;
  }
}

// Does a concrete subject match a filter? Used to say which seat an event woke
// and to tell a subscription that can never fire from one that simply has not.
export const subjectMatches = (filter, subject) => subjectsOverlap(filter, subject);
