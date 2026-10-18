// A refusal is not a failure: the provider said "not now", and said when.
//
// The difference matters to three surfaces at once, and until today none of
// them could tell the two apart. On 2026-10-18 the host attempted 253 runs
// across four companies and a model provider refused 65 of them in two
// windows; 37 were refused before their first turn and did nothing at all,
// and not one of the 65 opened a pull request. Every one of those runs was
// recorded with the same shape as a run whose code was broken, and — because
// the bus acknowledges an event the moment a run has STARTED — every one of
// them threw its event away (docs/agents/incidents.md, exo's entry 8).
//
// So this file answers one question, in one place, for the run log, the
// board and the bus: did a resource refuse this run, and when does it come
// back? Three rules hold it honest.
//
//   It reads the provider's own words. A refusal names its reset time in its
//   own text — `Claude AI usage limit reached|1760760000` from the CLI, a
//   `retry-after` from a gateway, "your limit will reset at 5am (UTC)" in
//   prose — so the delay before a retry is READ rather than guessed. The
//   fixed fifteen-second NAK the bus had is what left 121 of the day's 342
//   dark minutes on the floor after capacity was already back.
//
//   It only ever looks at a run that produced nothing. The caller checks
//   that first (src/lib/runner.js): no pull request, no second turn. An
//   agent is perfectly capable of printing the words "usage limit reached"
//   while doing its job, and a run that did its job is not a refusal no
//   matter what it printed.
//
//   It says what it does not know. A refusal with no reset time in it gets a
//   floor and a backoff, not an invented clock.
//
// Deliberately NOT a refusal here: a bad key, an expired token, a missing
// login. Those are a box an operator has to fix, the run will be refused
// again on the next delivery just as fast, and calling them "capacity" would
// put a permanent condition in a column whose whole meaning is "later". They
// stay ordinary failures until someone measures that they should not.

// A reset the provider named is the delay; these bound it. The floor exists
// because a reset time that has already passed (a clock a minute out, a run
// that sat in a queue) must not come back instantly and spin; the ceiling
// because no refusal this runtime has seen is worth holding an event for
// longer than a working day's quarter, and an event held longer than the
// stream's own retention is an event lost twice.
export const MIN_REFUSAL_NAK_MS = 60_000;
export const MAX_REFUSAL_NAK_MS = 6 * 60 * 60_000;
// A moment past the named reset: coming back on the exact second a limit
// lifts is how you earn a second refusal for free.
export const RESET_GRACE_MS = 15_000;
// What an unnamed reset is worth, by what refused. Multiplied by the delivery
// count, so a billing state nobody is awake to fix backs off instead of
// knocking every ten minutes for three days — which is the shape the nine
// runs blocked for three and a half days actually had.
export const FLOOR_MS = {
  limit: 10 * 60_000,       // a usage window, reset time not printed
  rate: 60_000,             // requests per minute; it is back almost at once
  overloaded: 60_000,       // the provider is busy, not out
  balance: 30 * 60_000,     // a human has to top it up
};
export const MAX_BACKOFF_STEPS = 6;

const clamp = (ms, lo, hi) => Math.min(Math.max(Math.round(ms), lo), hi);

// --- reading the moment out of the words ----------------------------------

// Everything a provider writes a reset time as, in one function, because the
// alternative is four regexes in four call sites that disagree by an hour.
// Returns an ISO string or null; null is a fine answer and the caller has a
// floor for it.
//
// A bare clock ("5am", "15:00") carries no zone, and the executor prints it
// in the zone of the box the run happened on — which is this box. So a bare
// clock is read as local time and the NEXT occurrence of it, which is what
// "resets at 5am" means at 9pm. A clock that names UTC is read as UTC.
export function parseResetMoment(raw, { now = Date.now() } = {}) {
  if (raw === null || raw === undefined) return null;
  const text = String(raw).trim();
  if (!text) return null;

  // Epoch, the shape the Claude CLI prints after the pipe. Ten digits is
  // seconds, thirteen is milliseconds; anything else is not a timestamp.
  const epoch = /^(\d{10}|\d{13})$/.exec(text);
  if (epoch) {
    const ms = epoch[1].length === 10 ? Number(epoch[1]) * 1000 : Number(epoch[1]);
    return new Date(ms).toISOString();
  }

  // A full timestamp, written by a gateway that speaks HTTP headers.
  if (/^\d{4}-\d{2}-\d{2}[T ]/.test(text)) {
    const ms = Date.parse(text);
    if (Number.isFinite(ms)) return new Date(ms).toISOString();
  }

  // "in 45 minutes", "try again in 90s" — and the same thing with the "in"
  // already eaten by the phrase that handed us this fragment ("resets in 2
  // hours" arrives here as "2 hours"). Abbreviations are only read behind an
  // explicit "in": a bare "2 h" is rare and a bare "5 am" is not, and the
  // clock rule below must keep the second one.
  const relative = /\bin\s+(\d+(?:\.\d+)?)\s*(seconds?|secs?|s|minutes?|mins?|m|hours?|hrs?|h)\b/i.exec(text)
    ?? /^(\d+(?:\.\d+)?)\s*(seconds?|secs?|minutes?|mins?|hours?|hrs?)\b/i.exec(text);
  if (relative) {
    const n = Number(relative[1]);
    const unit = relative[2].toLowerCase();
    const mult = unit.startsWith("s") ? 1000 : unit.startsWith("m") ? 60_000 : 3_600_000;
    return new Date(now + n * mult).toISOString();
  }

  // A clock: 5am, 5:30 pm, 15:00, each optionally naming UTC or GMT.
  const clock = /\b(\d{1,2})(?::(\d{2}))?\s*(am|pm)?\s*\(?\s*(utc|gmt|z)?\s*\)?/i.exec(text);
  if (clock) {
    let hour = Number(clock[1]);
    const minute = Number(clock[2] ?? 0);
    const meridiem = clock[3]?.toLowerCase() ?? null;
    const utc = Boolean(clock[4]);
    if (meridiem === "pm" && hour < 12) hour += 12;
    if (meridiem === "am" && hour === 12) hour = 0;
    if (hour > 23 || minute > 59) return null;
    return nextClock({ hour, minute, utc, now });
  }
  return null;
}

// The next moment the clock reads hour:minute, strictly after `now`. Written
// by adding days to a Date rather than by arithmetic on milliseconds, so a
// local clock that crosses a daylight-saving boundary lands on the hour a
// person would have said, not an hour either side of it.
function nextClock({ hour, minute, utc, now }) {
  const at = new Date(now);
  if (utc) at.setUTCHours(hour, minute, 0, 0);
  else at.setHours(hour, minute, 0, 0);
  if (at.getTime() <= now) at.setDate(at.getDate() + 1);
  return at.toISOString();
}

// --- reading the refusal out of the run -----------------------------------

// Ordered most specific first: the first pattern that matches is the answer,
// because "usage limit reached, resets at 5am" is also a line with the word
// "limit" in it and the generic rule would throw the clock away.
//
// `when` names the capture group that holds the reset time, if the shape has
// one. `kind` is the word the board and the run log use.
const PATTERNS = [
  // The Claude CLI's own machine-readable line: the words, a pipe, an epoch.
  { kind: "limit", re: /((?:claude\s+ai\s+)?(?:usage|session|weekly|\d+-hour)\s+limit\s+reached)\s*[|:]\s*(\d{10,13})/i, when: 2 },
  // The same thing in prose, from the CLI and from the console.
  { kind: "limit", re: /((?:usage|session|weekly|rate|\d+-hour)\s+limit\s+(?:reached|exceeded)[^\n]{0,120}?reset[s]?(?:\s+at|\s+on|\s+in)?\s+([^\n.;)]{1,40}))/i, when: 2 },
  { kind: "limit", re: /((?:usage|session|weekly|\d+-hour)\s+limit\s+(?:reached|exceeded))/i },
  { kind: "limit", re: /(limit\s+reached\s*[·∙|]\s*resets?\s+([^\n.;)]{1,40}))/i, when: 2 },
  // A gateway answering 429. The header is the reset time when it is there.
  { kind: "rate", re: /(rate[_ ]limit[_ ]?(?:error|exceeded)[^\n]{0,200}?retry-?after["':=\s]+(\d{1,6}))/i, when: 2, seconds: true },
  { kind: "rate", re: /(retry-?after["':=\s]+(\d{1,6}))/i, when: 2, seconds: true },
  { kind: "rate", re: /(anthropic-ratelimit-[a-z-]*reset["':=\s]+([0-9T:+Z.-]{10,40}))/i, when: 2 },
  { kind: "rate", re: /("type"\s*:\s*"rate_limit_error"|\b429\s+too\s+many\s+requests\b)/i },
  { kind: "overloaded", re: /("type"\s*:\s*"overloaded_error"|\b529\b[^\n]{0,40}overloaded|\boverloaded_error\b)/i },
  { kind: "balance", re: /(credit\s+balance\s+is\s+too\s+low|insufficient[_ ]quota|billing[_ ](?:hard[_ ])?limit\s+reached)/i },
];

// -> { kind, says, resetAt, floorMs } or null.
//
// `says` is the provider's own sentence, one line, trimmed to something a
// board column can hold. It is quoted back to the operator deliberately: the
// one instrument this incident proved we lacked is a surface that repeats
// what the resource actually said, instead of an exit code.
export function readRefusal(text, { now = Date.now() } = {}) {
  if (typeof text !== "string" || !text) return null;
  // The end of the run is where the refusal is; a megabyte of transcript in
  // front of it is somebody else's work and costs a regex pass per pattern.
  const tail = text.length > 16_384 ? text.slice(-16_384) : text;
  for (const p of PATTERNS) {
    const m = p.re.exec(tail);
    if (!m) continue;
    const raw = p.when ? m[p.when] : null;
    const resetAt = raw === null || raw === undefined
      ? null
      : p.seconds
        ? new Date(now + Number(raw) * 1000).toISOString()
        : parseResetMoment(raw, { now });
    return {
      kind: p.kind,
      says: oneLine(m[1] ?? m[0]),
      resetAt,
      floorMs: FLOOR_MS[p.kind] ?? FLOOR_MS.limit,
    };
  }
  return null;
}

const oneLine = (s) => String(s).replace(/\s+/g, " ").trim().slice(0, 200);

// --- what the runtime does about it ---------------------------------------

// How long to hold the event back. The reset the refusal named, plus a
// moment; failing that, the floor for what refused, backed off by how many
// times this event has already come round.
export function refusalNakMs(refusal, { now = Date.now(), delivery = 1 } = {}) {
  if (!refusal) return null;
  if (refusal.resetAt) {
    const ms = Date.parse(refusal.resetAt);
    if (Number.isFinite(ms)) return clamp(ms - now + RESET_GRACE_MS, MIN_REFUSAL_NAK_MS, MAX_REFUSAL_NAK_MS);
  }
  const steps = Math.min(Math.max(Number(delivery) || 1, 1), MAX_BACKOFF_STEPS);
  return clamp((refusal.floorMs ?? FLOOR_MS.limit) * steps, MIN_REFUSAL_NAK_MS, MAX_REFUSAL_NAK_MS);
}

const WHAT = {
  limit: "a usage limit",
  rate: "a rate limit",
  overloaded: "the provider being overloaded",
  balance: "a credit balance too low to run",
};

// One sentence, in the product's vocabulary, naming what refused, when it
// said it comes back, and what the runtime did about it — the bar `epito
// validate` sets: the rule broken, and the fix, in the message.
export function refusalSays(name, refusal, { delayMs = null, resentAt = null } = {}) {
  const what = WHAT[refusal.kind] ?? "a resource";
  const when = refusal.resetAt
    ? `it says it resets at ${refusal.resetAt}`
    : `it named no reset time, so the wait is this runtime's floor for ${what}`;
  const back = delayMs === null
    ? ""
    : `; the event is NOT acknowledged and comes back ${resentAt ? `at ${resentAt}` : `in ${humanMs(delayMs)}`}`;
  return `${name}: the run did not start — ${what} refused it before a first turn, saying "${refusal.says}", and ${when}${back}`;
}

export function humanMs(ms) {
  if (ms < 90_000) return `${Math.round(ms / 1000)}s`;
  if (ms < 90 * 60_000) return `${Math.round(ms / 60_000)}m`;
  const h = ms / 3_600_000;
  return `${h % 1 === 0 ? h : h.toFixed(1)}h`;
}
