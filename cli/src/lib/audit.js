// The product's own record: one file, .epito/audit.jsonl in the process's
// working directory, append-only, one JSON object per line, never rewritten.
//
// epitod v0 also kept .epito/state.json, a roster snapshot the daemon rewrote
// on every state transition and `epito ps` read back. v1 retires it: Temporal
// knows what is scheduled, what is running and what a window is holding, and
// `epito ps` asks Temporal (src/temporal/ps.js). A second copy of that truth
// in a file is a second copy that can be wrong.
//
// audit.jsonl stays, and stays engine-agnostic (law 8 of the design). It is
// the record in the PRODUCT's vocabulary — seats, runs, windows, sessions —
// and it must still be readable if Temporal is ever replaced. Both epitod
// processes append to it, from one working directory: O_APPEND writes of a
// single line under the pipe-buffer size do not interleave on Linux, which is
// the whole reason a line is one line.
import { appendFileSync, mkdirSync } from "node:fs";
import { join } from "node:path";

export const EPITO_DIR = ".epito";
export const AUDIT_PATH = join(EPITO_DIR, "audit.jsonl");

export function ensureDir() { mkdirSync(join(EPITO_DIR, "logs"), { recursive: true }); }

export function appendAudit(entry) {
  ensureDir();
  appendFileSync(AUDIT_PATH, JSON.stringify({ ts: new Date().toISOString(), ...entry }) + "\n");
}
