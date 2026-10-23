// The run report, on the COMPANY board — the owner's Runs tab, which until now
// only ever showed runs that happened on a GitHub runner.
//
// Two boards, and they are not rivals. `lib/board.js` is the product's own
// board, a file on the box, which works on a laptop with nothing configured
// and is what a stranger gets. This is an integration: when the box holds
// `BOARD_API_URL` and `BOARD_RUNTIME_TOKEN`, the same run is also filed to the
// company board's `POST /api/runs`, which is where an owner running several
// companies looks. Absent either name, nothing here happens and nothing says
// anything — a stranger does not have a company board and must not be told
// about one.
//
// The endpoint is HQ's, specified in its `runtime/board/README.md` integration
// note addressed to this seat: `company` and `seat` required, `run_url` the
// idempotency key, and — the line that decides the shape of this whole file —
// "a run report is not worth failing a run over". So every function here is
// best-effort, short-deadline, and incapable of throwing. The same rule the
// trace exporter keeps (ADR-18, consequence 1), for the same reason: the run
// already happened, and a ledger that argues with the run is worse than one
// with a hole in it.
import { pathToFileURL } from "node:url";
import { runLogPath } from "./runner.js";

const POST_TIMEOUT_MS = 10_000;

// Both names or neither. A URL with no token is a request the board answers
// 401 to, every run, forever; a token with no URL has nowhere to go. Saying
// "half-configured" once at startup is `epito doctor`'s job (it reads this),
// and filing nothing is this one's.
export function boardApi(env = process.env) {
  const url = (env.BOARD_API_URL ?? "").trim().replace(/\/+$/, "");
  const token = (env.BOARD_RUNTIME_TOKEN ?? "").trim();
  if (!url || !token) {
    return { configured: false, url: url || null, half: Boolean(url) !== Boolean(token) };
  }
  return { configured: true, url, token, half: false };
}

// The address of this run, which is also the board's idempotency key. A
// retried `record` activity (it is retried, up to five times) must file the
// same row rather than a second one, so this is DERIVED from the run id and
// never from a clock.
//
// On a GitHub runner the natural value is the Actions run page. A resident
// host has no such page, and inventing an https URL that answers nothing would
// be worse than being honest: the default is the `file:` URL of this run's own
// log, which is the artifact an operator on that box actually wants. A host
// that publishes its logs sets EPITO_RUN_URL_BASE and gets clickable rows.
export function runUrlFor({ agent, runId, env = process.env } = {}) {
  if (!agent || !runId) return null;
  const base = (env.EPITO_RUN_URL_BASE ?? "").trim().replace(/\/+$/, "");
  if (base) return `${base}/${encodeURIComponent(agent)}/${encodeURIComponent(runId)}`;
  return pathToFileURL(runLogPath(agent, runId)).href;
}

// The one line a row shows. The board renders this text, so it is written in
// the product's vocabulary and says the same words `epito board` says: the
// outcome is "ok" or the name of the stage that stopped the run, never an exit
// code an owner would have to look up.
export function reportLine({ agent, trigger, outcome, turns, seconds, pr, detail }) {
  const head = ["epitod", agent, trigger || null, outcome].filter(Boolean).join(" · ");
  const tail = [
    turns != null ? `${turns} turn${turns === 1 ? "" : "s"}` : null,
    seconds != null ? `${seconds}s` : null,
    pr || null,
    outcome !== "ok" ? detail || null : null,
  ].filter(Boolean).join(" · ");
  return tail ? `${head}\n${tail}` : head;
}

// The body, pure, so a test can assert the wire shape without a server. Same
// field names the seat workflows already POST from Actions, because one board
// row should not have two spellings depending on where the run happened.
export function runReportBody({
  company, agent, repo = null, trigger = null, runId = null, model = null,
  outcome = "ok", turns = null, seconds = null, pr = null, detail = null,
  startedAt = null, endedAt = null, runUrl = null,
}) {
  return {
    company,
    seat: agent,
    repo,
    trigger,
    started_at: startedAt ?? null,
    ended_at: endedAt ?? new Date().toISOString(),
    model,
    // The board's `exit` is an integer, and its row text is where the stage
    // name lives. Both, rather than either: the number is what a Runs tab
    // filters on and the word is what tells you which stage stopped it.
    exit: outcome === "ok" ? 0 : 1,
    pr_url: pr || null,
    run_url: runUrl,
    report: reportLine({ agent, trigger, outcome, turns, seconds, pr, detail }),
    item_ids: [],
  };
}

// What the board said, as one sentence, for the three answers HQ's note calls
// out by name and for everything else. Never thrown, only logged: the caller
// has already recorded the run twice (the audit log and the local board) and
// this is the integration, not the record.
export function answerSays(status, { url, body = "" } = {}) {
  const snippet = String(body ?? "").trim().slice(0, 200);
  if (status >= 200 && status < 300) return null;
  if (status === 400) {
    return `the company board refused this run report as malformed (400)${snippet ? `: ${snippet}` : ""}. Fix: this is epito's own payload, so it is a bug here rather than on the box — the run itself is recorded in the audit log and on \`epito board\``;
  }
  if (status === 401) {
    return `the company board did not accept BOARD_RUNTIME_TOKEN (401), so this run is not on the Runs tab. Fix: the token on this box is wrong or expired — set BOARD_RUNTIME_TOKEN to the runtime token for ${url} and restart the worker`;
  }
  if (status === 503) {
    return `the company board is not taking run reports right now (503), so this run is not on the Runs tab. Nothing to fix here: the run is recorded in the audit log and on \`epito board\`, and the next run files itself`;
  }
  return `the company board answered ${status} to this run report, so this run is not on the Runs tab${snippet ? ` (${snippet})` : ""}`;
}

// Best-effort, awaited, incapable of throwing. Awaited for the reason the span
// exporter is: an activity that returned before its request left the process
// would lose it on the next deploy.
export async function postRunReport(body, { env = process.env, log = console.error, fetchImpl = fetch } = {}) {
  const api = boardApi(env);
  if (!api.configured) return { filed: false, reason: "no company board on this box" };
  if (!body?.company || !body?.seat) {
    return { filed: false, reason: "no company name, so there is nothing to file under" };
  }
  const url = `${api.url}/api/runs`;
  try {
    const res = await fetchImpl(url, {
      method: "POST",
      headers: { "content-type": "application/json", authorization: `Bearer ${api.token}` },
      body: JSON.stringify(body),
      signal: AbortSignal.timeout(POST_TIMEOUT_MS),
    });
    const text = res.ok ? "" : await res.text().catch(() => "");
    const says = answerSays(res.status, { url: api.url, body: text });
    if (says) { log(`epito: the run is recorded, but ${says}`); return { filed: false, status: res.status, reason: says }; }
    return { filed: true, status: res.status };
  } catch (e) {
    const reason = `the company board at ${api.url} did not answer (${e.message}), so this run is not on the Runs tab`;
    log(`epito: the run is recorded, but ${reason}`);
    return { filed: false, reason };
  }
}
