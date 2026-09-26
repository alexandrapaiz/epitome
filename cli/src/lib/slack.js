// The seat's one line to Slack after every run. It posts; it never reads
// (the pitch's rabbit hole: a Slack reader is a separate, later process).
//
// An agent opts in by listing SLACK_WEBHOOK_URL under [runtime].env — the
// same rule that governs every other secret name: the manifest names it, the
// runtime's environment holds the value, and an agent that doesn't list it
// gets no post. No dependency: node's global fetch does it.
//
// Per-agent routing: [runtime].slack_webhook_env names a DIFFERENT webhook
// secret, so a product seat can post to its own channel while the default
// SLACK_WEBHOOK_URL keeps going to #hq. The validator already refuses a
// slack_webhook_env that isn't also listed under [runtime].env, which is what
// makes "the manifest names every secret it can see" stay true here.
//
// The line reads like a status board, not a paragraph:
//   pm · message · 3 turns · 12s · https://github.com/owner/repo/pull/6

const TIMEOUT_MS = 10_000;

export function formatLine({ agent, trigger, turns, pr, durationMs, exit }) {
  const secs = durationMs != null ? `${Math.max(1, Math.round(durationMs / 1000))}s` : null;
  const failed = exit !== 0 && exit !== null && exit !== undefined;
  const parts = [
    agent,
    trigger,
    turns != null ? `${turns} turn${turns === 1 ? "" : "s"}` : null,
    secs,
    failed ? `exit ${exit}` : null,
    pr || null,
  ].filter(Boolean);
  return `${failed ? "⚠️ " : ""}${parts.join(" · ")}`;
}

// Returns { posted: true } or { posted: false, reason }. Never throws: a Slack
// outage must not take a run down with it.
// The secret name this agent's line goes to, or null if it opted out.
export function webhookName(manifest) {
  const names = manifest?.runtime?.env ?? [];
  if (!Array.isArray(names)) return null;
  const routed = manifest?.runtime?.slack_webhook_env;
  if (typeof routed === "string" && routed) return names.includes(routed) ? routed : null;
  return names.includes("SLACK_WEBHOOK_URL") ? "SLACK_WEBHOOK_URL" : null;
}

export async function postToSlack({ agent, manifest, env = process.env, fetchImpl = globalThis.fetch, ...line }) {
  const name = webhookName(manifest);
  if (!name) return { posted: false, reason: "not listed in [runtime].env" };
  const url = env[name];
  if (!url) return { posted: false, reason: `${name} is listed in [runtime].env but unset in the runtime's environment` };
  const text = formatLine({ agent, ...line });
  const ac = new AbortController();
  const timer = setTimeout(() => ac.abort(), TIMEOUT_MS);
  try {
    const res = await fetchImpl(url, { method: "POST", headers: { "content-type": "application/json" }, body: JSON.stringify({ text }), signal: ac.signal });
    if (!res.ok) return { posted: false, reason: `slack answered ${res.status}`, text };
    return { posted: true, text };
  } catch (e) {
    return { posted: false, reason: e.name === "AbortError" ? `slack did not answer in ${TIMEOUT_MS}ms` : e.message, text };
  } finally { clearTimeout(timer); }
}
