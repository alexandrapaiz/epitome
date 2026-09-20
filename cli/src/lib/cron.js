// A 5-field cron matcher (minute hour day-of-month month day-of-week), UTC.
// Hand-rolled: the dependency budget in docs/architecture.md says epitod
// targets zero runtime deps, and the grammar we honor (numbers, *, ranges,
// steps, lists) fits in one screen. Names (JAN, MON) are not supported;
// spec/manifest.md says "5-field cron" and numbers are the portable subset.

// Expand one field into a Set of allowed integers within [min, max].
function expandField(field, min, max, name) {
  const allowed = new Set();
  for (const part of field.split(",")) {
    const m = /^(\*|\d+)(?:-(\d+))?(?:\/(\d+))?$/.exec(part);
    if (!m) throw new Error(`cron ${name} field "${part}" is not a number, *, range, step, or list`);
    const [, base, rangeEnd, stepStr] = m;
    const step = stepStr ? Number(stepStr) : 1;
    if (step < 1) throw new Error(`cron ${name} step must be >= 1, got ${step}`);
    let lo, hi;
    if (base === "*") { lo = min; hi = max; }
    else { lo = Number(base); hi = rangeEnd !== undefined ? Number(rangeEnd) : (stepStr ? max : lo); }
    if (lo < min || hi > max || lo > hi) throw new Error(`cron ${name} "${part}" is outside ${min}-${max}`);
    for (let v = lo; v <= hi; v += step) allowed.add(v);
  }
  return allowed;
}

// Parse "m h dom mon dow" into a matcher object. Throws on bad input.
export function parseCron(expr) {
  const fields = String(expr).trim().split(/\s+/);
  if (fields.length !== 5) throw new Error(`cron "${expr}" must have 5 fields, got ${fields.length}`);
  const [mi, h, dom, mon, dow] = fields;
  const spec = {
    minute: expandField(mi, 0, 59, "minute"),
    hour: expandField(h, 0, 23, "hour"),
    dom: expandField(dom, 1, 31, "day-of-month"),
    month: expandField(mon, 1, 12, "month"),
    dow: expandField(dow, 0, 7, "day-of-week"),
    // POSIX: when both dom and dow are restricted, a date matches if EITHER does.
    domStar: dom === "*", dowStar: dow === "*",
  };
  if (spec.dow.has(7)) spec.dow.add(0); // 7 == Sunday, same as 0
  return spec;
}

// Does this UTC minute match? `date` is any Date; seconds are ignored.
export function cronMatches(spec, date) {
  if (!spec.minute.has(date.getUTCMinutes())) return false;
  if (!spec.hour.has(date.getUTCHours())) return false;
  if (!spec.month.has(date.getUTCMonth() + 1)) return false;
  const domOk = spec.dom.has(date.getUTCDate());
  const dowOk = spec.dow.has(date.getUTCDay());
  if (spec.domStar && spec.dowStar) return true;
  if (spec.domStar) return dowOk;
  if (spec.dowStar) return domOk;
  return domOk || dowOk;
}

// Next matching minute strictly after `from`, scanning minute by minute
// (bounded at 366 days so an impossible schedule like "0 0 31 2 *" returns null).
export function nextCronFire(spec, from = new Date()) {
  const t = new Date(from);
  t.setUTCSeconds(0, 0);
  t.setUTCMinutes(t.getUTCMinutes() + 1);
  for (let i = 0; i < 366 * 24 * 60; i++) {
    if (cronMatches(spec, t)) return t;
    t.setUTCMinutes(t.getUTCMinutes() + 1);
  }
  return null;
}
