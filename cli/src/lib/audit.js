// The daemon's on-disk record, two files under .epito/ in its working dir
// (docs/architecture.md "Data model"): audit.jsonl is append-only, one JSON
// object per line, never rewritten; state.json is the current roster snapshot
// `epito ps` reads, replaced atomically (write temp, rename) so a reader never
// sees a half-written file.
import { appendFileSync, mkdirSync, writeFileSync, renameSync, readFileSync, existsSync } from "node:fs";
import { join } from "node:path";

export const EPITO_DIR = ".epito";
export const AUDIT_PATH = join(EPITO_DIR, "audit.jsonl");
export const STATE_PATH = join(EPITO_DIR, "state.json");

export function ensureDir() { mkdirSync(join(EPITO_DIR, "logs"), { recursive: true }); }

export function appendAudit(entry) {
  ensureDir();
  appendFileSync(AUDIT_PATH, JSON.stringify({ ts: new Date().toISOString(), ...entry }) + "\n");
}

export function writeState(state) {
  ensureDir();
  const tmp = STATE_PATH + ".tmp";
  writeFileSync(tmp, JSON.stringify(state, null, 2) + "\n");
  renameSync(tmp, STATE_PATH);
}

export function readState() {
  if (!existsSync(STATE_PATH)) return null;
  return JSON.parse(readFileSync(STATE_PATH, "utf8"));
}
