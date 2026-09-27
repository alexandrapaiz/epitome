// Secret-scrubbing, in its own module because three things need it and one of
// them (trace.js) is imported BY the file it used to live in.
//
// epito prints no token, but run logs capture everything a subprocess prints,
// and `git` and `gh` both have error paths that echo the credential they were
// handed. Every secret given here is replaced on its way out. Honest limit: a
// secret split across two read boundaries slips through, so this is the second
// line of defence, not the first. The 8-character floor keeps an empty or
// absurd entry from redacting a log into confetti.
export function redactor(secrets = []) {
  const real = secrets.filter((x) => typeof x === "string" && x.length >= 8);
  if (real.length === 0) return String;
  return (s) => {
    let out = String(s);
    for (const secret of real) out = out.split(secret).join("[redacted: this run's token]");
    return out;
  };
}
