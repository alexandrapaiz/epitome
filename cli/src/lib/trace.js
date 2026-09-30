// One trace per run, over OTLP/HTTP+JSON, with no OpenTelemetry package in
// the dependency list (ADR-18).
//
//   run        the root, filed by the `record` activity when the run ends
//   ├ clone    filed by the `clone` activity
//   └ execute  filed by the `execute` activity
//     └ …      whatever the agent itself emits, nested by TRACEPARENT
//
// Three separate activity invocations file those spans. They never share
// memory, may run on different hosts, and are retried independently — so the
// ids are DERIVED FROM THE RUN ID by SHA-256 rather than generated:
// `spanIdFor(runId, "execute")` is the same sixteen bytes in every process
// that asks, forever. That is the whole reason this file exists instead of
// `@opentelemetry/sdk-node`: with generated ids, a trace context would have to
// be threaded through Temporal's persisted workflow inputs, and law 7 makes
// every such input a row in a database that outlives the run.
//
// Tracing is off unless the operator sets OTEL_EXPORTER_OTLP_ENDPOINT — the
// standard variable, so pointing epitod at a Phoenix on the box is the setting
// a Phoenix user already knows. Off means nothing: no spans, no warning, no
// behaviour change anywhere in a run.
//
// Nothing here may ever fail a run (ADR-18, consequence 1): the run already
// happened, and a ledger that argues with the run is worse than one with a
// hole in it. Every export is best-effort with a short timeout, and a failure
// is one log line.
import { createHash } from "node:crypto";
import { redactor } from "./redact.js";

const EXPORT_TIMEOUT_MS = 2_000;
const SERVICE = "epito";

// OTLP's own numbers, written down so no magic integer appears below.
const SPAN_KIND_INTERNAL = 1;
const STATUS_OK = 1;
const STATUS_ERROR = 2;

// --- where spans go -------------------------------------------------------

// The standard says OTEL_EXPORTER_OTLP_TRACES_ENDPOINT is a complete URL and
// OTEL_EXPORTER_OTLP_ENDPOINT is a base the signal's path is appended to.
// Honouring both is four lines and means an operator who already traces
// something else on this box does not have to learn our spelling.
export function traceConfig(env = process.env) {
  const specific = (env.OTEL_EXPORTER_OTLP_TRACES_ENDPOINT ?? "").trim();
  const base = (env.OTEL_EXPORTER_OTLP_ENDPOINT ?? "").trim();
  const url = specific || (base ? `${base.replace(/\/+$/, "")}/v1/traces` : "");
  if (!url) return null;
  return {
    url,
    headers: parseHeaders(env.OTEL_EXPORTER_OTLP_HEADERS),
    service: (env.OTEL_SERVICE_NAME ?? "").trim() || SERVICE,
  };
}

// W3C-ish `k=v,k2=v2`, the encoding the OTel spec gives this variable. A value
// here is usually an api key, which is why it is never handed to a child
// process (ADR-18, consequence 2).
export function parseHeaders(raw) {
  const out = {};
  for (const pair of String(raw ?? "").split(",")) {
    const at = pair.indexOf("=");
    if (at <= 0) continue;
    const k = pair.slice(0, at).trim();
    const v = pair.slice(at + 1).trim();
    if (k) out[k] = decodeURIComponent(v);
  }
  return out;
}

// --- the ids --------------------------------------------------------------

const hex = (s, bytes) => createHash("sha256").update(s).digest("hex").slice(0, bytes * 2);

export const traceIdFor = (runId) => hex(`epito:trace:${runId}`, 16);
export const spanIdFor = (runId, phase) => hex(`epito:span:${runId}:${phase}`, 8);

// The header a child process uses to nest its spans under ours: version 00,
// our trace, the span it is running inside, sampled.
export function traceparentFor(runId, phase = "execute") {
  return `00-${traceIdFor(runId)}-${spanIdFor(runId, phase)}-01`;
}

// --- what a child run is told ---------------------------------------------

// The environment that makes an agent's own instrumentation land in the same
// trace as the run that started it — openinference, LangSmith's OTel exporter,
// the langgraph shim's node spans, anything that reads the standard variables.
// No epito import on the agent's side, and deliberately no
// OTEL_EXPORTER_OTLP_HEADERS: that value carries an api key on every hosted
// backend, and law 6 says a run sees only the secrets its manifest names (a
// seat that needs authenticated export lists it in [runtime].env like any
// other secret).
//
// OTEL_SERVICE_NAME is the AGENT's name, not epito's: the spans inside a run
// are the agent's work, and an owner looking at Phoenix wants to see the seat.
export function childTraceEnv({ runId, agent, trigger, phase = "execute", env = process.env } = {}) {
  const cfg = traceConfig(env);
  if (!cfg || !runId) return {};
  const attrs = [
    `epito.agent=${agent ?? "unknown"}`,
    `epito.run_id=${runId}`,
    trigger ? `epito.trigger=${trigger}` : null,
  ].filter(Boolean);
  // An operator's own resource attributes are not ours to drop.
  const existing = (env.OTEL_RESOURCE_ATTRIBUTES ?? "").trim();
  const base = (env.OTEL_EXPORTER_OTLP_ENDPOINT ?? "").trim();
  return {
    TRACEPARENT: traceparentFor(runId, phase),
    // Both spellings, and the specific one always: an operator who set only
    // OTEL_EXPORTER_OTLP_TRACES_ENDPOINT (a complete URL) would otherwise hand
    // the child a base to append "/v1/traces" to a second time.
    ...(base ? { OTEL_EXPORTER_OTLP_ENDPOINT: base } : {}),
    OTEL_EXPORTER_OTLP_TRACES_ENDPOINT: cfg.url,
    OTEL_SERVICE_NAME: agent ?? cfg.service,
    OTEL_RESOURCE_ATTRIBUTES: existing ? `${existing},${attrs.join(",")}` : attrs.join(","),
  };
}

// --- the payload ----------------------------------------------------------

// OTLP/JSON's attribute encoding: every value is tagged by type, and the
// integer types travel as strings because JSON numbers are doubles. A null or
// undefined attribute is dropped rather than sent as an empty string — a span
// that says `pr: ""` reads as a run that opened a PR with no address.
export function attributes(obj = {}, scrub = String) {
  const out = [];
  for (const [key, raw] of Object.entries(obj)) {
    if (raw === null || raw === undefined) continue;
    let value;
    if (typeof raw === "string") value = { stringValue: scrub(raw) };
    else if (typeof raw === "boolean") value = { boolValue: raw };
    else if (typeof raw === "number") value = Number.isInteger(raw) ? { intValue: String(raw) } : { doubleValue: raw };
    else if (Array.isArray(raw)) {
      value = { arrayValue: { values: raw.filter((v) => v !== null && v !== undefined)
        .map((v) => (Number.isInteger(v) ? { intValue: String(v) } : { stringValue: scrub(String(v)) })) } };
    }
    else value = { stringValue: scrub(String(raw)) };
    out.push({ key, value });
  }
  return out;
}

const nanos = (ms) => `${BigInt(Math.round(ms))* 1_000_000n}`;

// One span. `parent` is a phase name, not an id: a caller should never have to
// know how an id is made to say "this happened inside the run".
export function span({ runId, name, phase, parent = null, startMs, endMs, attrs = {}, error = null, scrub = String }) {
  return {
    traceId: traceIdFor(runId),
    spanId: spanIdFor(runId, phase),
    ...(parent ? { parentSpanId: spanIdFor(runId, parent) } : {}),
    name,
    kind: SPAN_KIND_INTERNAL,
    startTimeUnixNano: nanos(startMs),
    endTimeUnixNano: nanos(endMs),
    attributes: attributes(attrs, scrub),
    status: error ? { code: STATUS_ERROR, message: scrub(String(error)) } : { code: STATUS_OK },
  };
}

export function payload(spans, { service = SERVICE, version = "0.1.0" } = {}) {
  return {
    resourceSpans: [{
      resource: { attributes: attributes({ "service.name": service, "service.version": version }) },
      scopeSpans: [{ scope: { name: "epito", version }, spans }],
    }],
  };
}

// --- the export -----------------------------------------------------------

let quiet = false;   // one complaint per process, not one per run

// Best-effort, awaited (an activity that returned before its span left the
// process would lose it on the next deploy), and incapable of throwing.
export async function emit(spans, { env = process.env, log = console.error, redact = [] } = {}) {
  const cfg = traceConfig(env);
  if (!cfg) return { sent: false, reason: "no endpoint" };
  if (!spans?.length) return { sent: false, reason: "nothing to send" };
  // The whole body goes through the scrubber, not each attribute: a span is a
  // store we do not own and cannot delete from (ADR-18, consequence 3), so the
  // guarantee wanted here is "no token in this request" rather than "no token
  // in the attributes I remembered to scrub".
  const scrub = redactor(redact);
  const body = scrub(JSON.stringify(payload(spans, { service: cfg.service })));
  try {
    const res = await fetch(cfg.url, {
      method: "POST",
      headers: { "content-type": "application/json", ...cfg.headers },
      body,
      signal: AbortSignal.timeout(EXPORT_TIMEOUT_MS),
    });
    if (!res.ok) {
      if (!quiet) { quiet = true; log(`epito: the run is recorded, but the trace endpoint answered ${res.status} (${cfg.url})`); }
      return { sent: false, reason: `http ${res.status}` };
    }
    return { sent: true };
  } catch (e) {
    if (!quiet) { quiet = true; log(`epito: the run is recorded, but its trace did not reach ${cfg.url} (${scrub(e.message)})`); }
    return { sent: false, reason: e.message };
  }
}

// The one-line summary a run log carries, so an operator reading a transcript
// can tell whether this run was traced without going to look.
export function traceNote({ runId, env = process.env } = {}) {
  const cfg = traceConfig(env);
  if (!cfg) return "# trace: off (no OTEL_EXPORTER_OTLP_ENDPOINT on this runtime)";
  return `# trace: ${traceIdFor(runId)} -> ${cfg.url}${Object.keys(cfg.headers).length ? " (with authentication headers, which the agent is not given)" : ""}`;
}

// Test seam: the "complain once" latch is process-wide on purpose, and a test
// that exercises two failures needs to clear it.
export function resetQuiet() { quiet = false; }
