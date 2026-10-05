// Secret-scrubbing, in its own module because three things need it and one of
// them (trace.js) is imported BY the file it used to live in.
//
// epito prints no token, but run logs capture everything a subprocess prints,
// and `git` and `gh` both have error paths that echo the credential they were
// handed. Every secret given here is replaced on its way out. Honest limit: a
// secret split across two read boundaries slips through, so this is the second
// line of defence, not the first. The 8-character floor keeps an empty or
// absurd entry from redacting a log into confetti.
// A secret is either a string or { value, as } — `as` being what the log says
// stood there. A run now carries more than one kind (the minted token, and the
// key of whichever road it took), and "[redacted]" twice over tells an
// operator reading a failure less than naming which credential it was.
export function redactor(secrets = []) {
  const real = secrets
    .map((x) => (typeof x === "string" ? { value: x, as: "this run's token" } : x))
    .filter((x) => typeof x?.value === "string" && x.value.length >= 8);
  if (real.length === 0) return String;
  return (s) => {
    let out = String(s);
    for (const { value, as } of real) out = out.split(value).join(`[redacted: ${as ?? "this run's token"}]`);
    return out;
  };
}
