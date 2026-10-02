// The board's three commands.
//
//   epito board                 read it, here, from .epito/board.jsonl
//   epito report <name> ...     file a run report onto it, from anywhere
//   epito note <name> "..."     put a line on it that is not a run
//
// Reading is local and writing is remote, which looks asymmetric and is not:
// the board file lives beside the runtime that writes most of it, so `epito
// board` on the host needs no engine, no server and no secret — it is `cat`
// with columns. A seat filing a report is usually somewhere else entirely
// (a GitHub Actions runner, a laptop), so it goes through the ingress, which
// already has the one door and the one secret. Anyone remote who wants to
// READ it asks the same door: `curl -H "x-epito-secret: …" …/board?format=text`.
import { parseFlags } from "./lib/flags.js";
import { readBoard, foldBoard, renderBoard, BOARD_PATH, KINDS } from "./lib/board.js";

const die = (msg) => { console.error(`epito: ${msg}`); process.exit(1); };

// --flag value, --flag=value, and bare --flag. Unknown flags are refused by
// name rather than ignored: a report filed with a misspelled --outcome that
// silently became "ok" is worse than one that did not file. That rule now
// applies to every command, so the implementation lives in lib/flags.js and
// this re-export keeps board.js's callers (and its tests) spelling it the way
// they always did.
export { parseFlags } from "./lib/flags.js";

export async function boardCmd(argv) {
  const { flags, rest, error } = parseFlags(argv, [
    { name: "agent", does: "only this agent's entries" },
    { name: "limit", does: "how many to show (default 20)" },
    { name: "kind", does: `only ${Object.keys(KINDS).join(" or ")} entries` },
    { name: "json", does: "the fold as JSON" },
  ], "board");
  if (error) die(error);
  if (rest.length) die(`board takes options, not arguments — \`epito board --agent ${rest[0]}\` is what you meant`);
  if (flags.kind && !KINDS[flags.kind]) die(`the board holds ${Object.keys(KINDS).join(" and ")} entries, not "${flags.kind}"`);

  const { events, unreadable, exists } = readBoard();
  if (!exists) {
    console.log(`no board here: ${BOARD_PATH} does not exist in ${process.cwd()}.`);
    console.log(`the board is written where the runtime runs — on the host that is /srv/asc/state, and \`epito run\` names the path on its first line.`);
    process.exit(0);
  }
  const fold = foldBoard(events, {
    agent: flags.agent && typeof flags.agent === "string" ? flags.agent : null,
    kind: typeof flags.kind === "string" ? flags.kind : null,
    limit: Number(flags.limit) > 0 ? Number(flags.limit) : 20,
  });
  if (flags.json) { console.log(JSON.stringify({ ...fold, unreadable, path: BOARD_PATH }, null, 2)); process.exit(0); }
  console.log(renderBoard(fold, { unreadable }));
  process.exit(0);
}

export async function reportCmd(argv) {
  const { flags, rest, error } = parseFlags(argv, [
    { name: "trigger", does: "what woke the run" },
    { name: "outcome", does: "how it ended" },
    { name: "pr", does: "the pull request it opened" },
    { name: "turns", does: "how many turns it took" },
    { name: "seconds", does: "how long it ran" },
    { name: "detail", does: "one line of what happened" },
    { name: "model", does: "which model ran it" },
    { name: "run-id", does: "the runtime's id for the run" },
  ], "report");
  if (error) die(error);
  const name = rest[0];
  if (!name) die(`report needs the agent it is about — \`epito report <name> --outcome ok --pr <url>\``);
  const body = {
    kind: "run", agent: name,
    trigger: flags.trigger ?? "manual",
    outcome: flags.outcome ?? "ok",
    pr: flags.pr, turns: flags.turns, seconds: flags.seconds,
    detail: flags.detail ?? (rest.slice(1).join(" ") || undefined),
    model: flags.model, runId: flags["run-id"],
    source: "cli",
  };
  for (const k of Object.keys(body)) if (body[k] === undefined || body[k] === true) delete body[k];
  const { callIngress } = await import("./run.js");
  const out = await callIngress("/board", body);
  const f = out.filed;
  console.error(`epito: filed on the board — ${f.agent} · ${f.trigger} · ${f.outcome}${f.pr ? ` · ${f.pr}` : ""}`);
  process.exit(0);
}

export async function noteCmd(argv) {
  const { flags, rest, error } = parseFlags(argv, [{ name: "url", does: "a link the note points at" }], "note");
  if (error) die(error);
  const name = rest[0];
  const text = rest.slice(1).join(" ");
  if (!name || !text) die(`note needs an agent and words — \`epito note pm "bet 2 is on the stack; cycle 1 closes 10-02"\``);
  const { callIngress } = await import("./run.js");
  const out = await callIngress("/board", { kind: "note", agent: name, text, ...(typeof flags.url === "string" ? { url: flags.url } : {}), source: "cli" });
  console.error(`epito: noted on the board — ${out.filed.agent}: ${out.filed.text}`);
  process.exit(0);
}
