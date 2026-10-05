// `epito audit` — read the ledger back.
//
// The record of what this machine's epito actually did: every App created,
// every token minted and what it was allowed to do, every run, every road
// refused, every restart. Written by six code paths since PR #4 (deploy,
// token, run's ingress, the worker, and the clone/execute activities) and,
// until this command, readable only with `cat`.
//
// Local, like `epito board`: the ledger lives beside the runtime that writes
// most of it, so this needs no engine, no server and no secret. Unlike the
// board, nothing writes to it from here — there is no `epito audit --add`
// and there must not be. A ledger a hand can append to from the outside is
// not a ledger, and the one thing an audit log sells is that every line in it
// was put there by the thing that did the work.
import { parseFlags } from "./lib/flags.js";
import { readAudit, foldAudit, renderAudit, parseSince, actionMatches, ACTIONS, AUDIT_PATH } from "./lib/audit.js";
import { NAME_RE } from "./lib/manifest.js";

const die = (msg) => { console.error(`epito: ${msg}`); process.exit(1); };

export async function auditCmd(argv) {
  const { flags, rest, error } = parseFlags(argv, [
    { name: "agent", does: "only this agent's lines" },
    { name: "action", does: `only this kind of line (${ACTIONS.slice(0, 4).join(", ")}, …); a prefix matches its family` },
    { name: "since", does: "only lines newer than this (24h, 30m, 7d, or 2026-10-02)" },
    { name: "limit", does: "how many to show (default 20; 0 for all)" },
    { name: "json", does: "the matching lines and the fold as JSON" },
  ], "audit");
  if (error) die(error);
  // `epito audit pm` is what a hand types, and it means --agent pm. Taking it
  // is cheaper than refusing it, and it is unambiguous: the ledger has exactly
  // one kind of positional subject, which is a seat.
  if (rest.length > 1) {
    die(`\`epito audit\` reads one agent's lines or everything's — it was given ${rest.length} names (${rest.join(", ")}). Fix: \`epito audit ${rest[0]}\`, or drop the names for the whole ledger.`);
  }
  const agentArg = typeof flags.agent === "string" ? flags.agent : rest[0] ?? null;
  if (agentArg !== null && !NAME_RE.test(agentArg)) {
    die(`"${agentArg}" is not an agent name — a name is [a-z0-9-], 1-40 chars, the same name its agent.toml carries. Fix: \`epito audit --agent <name>\`.`);
  }

  // An --action nothing ever writes is a filter that would print nothing and
  // say nothing about why. Refuse it by name, with the list, the way an
  // unknown option is refused (lib/flags.js).
  let action = null;
  if (flags.action !== undefined) {
    if (typeof flags.action !== "string") die(`--action needs a value: the kind of line to show. Fix: \`epito audit --action mint\`.`);
    action = flags.action;
    if (!ACTIONS.some((a) => a === action || actionMatches(a, action))) {
      die(`nothing in the ledger is a "${action}" — epito writes these actions:\n`
        + ACTIONS.map((a) => `  ${a}`).join("\n")
        + `\nA prefix matches its family, so \`--action run\` is run.start and run.end. Fix: \`epito audit --action mint\`.`);
    }
  }

  let since = null;
  if (flags.since !== undefined) {
    const s = parseSince(flags.since === true ? "" : flags.since);
    if (s.error) die(s.error);
    since = s.at;
  }

  // 0 means all, which is why this is not `Number(x) > 0 ? … : 20` the way
  // board's is: there `--limit 0` silently means 20, and on a ledger somebody
  // is reading to the end that is the wrong answer.
  let limit = 20;
  if (flags.limit !== undefined) {
    const n = Number(flags.limit === true ? NaN : flags.limit);
    if (!Number.isInteger(n) || n < 0) die(`--limit is a whole number of lines, 0 for all of them, got ${JSON.stringify(flags.limit)}. Fix: \`epito audit --limit 50\`.`);
    limit = n;
  }

  const { lines, unreadable, exists } = readAudit();
  if (!exists) {
    console.log(`no ledger here: ${AUDIT_PATH} does not exist in ${process.cwd()}.`);
    console.log(`it is written where the work happens — \`epito deploy\` and \`epito token\` write it in the directory they are run in, and the runtime writes it beside the board (\`epito run\` names both paths on its first line).`);
    process.exit(0);
  }

  const fold = foldAudit(lines, { agent: agentArg, action, since, limit });
  if (flags.json) {
    // The same shape as `epito board --json`: the fold, plus where it was read
    // from and how much of it could not be. `recent` is the matching lines
    // themselves, so --limit 0 --json is the whole filtered ledger.
    console.log(JSON.stringify({ ...fold, unreadable, path: AUDIT_PATH }, null, 2));
    process.exit(0);
  }
  console.log(renderAudit(fold, {
    unreadable,
    filters: { agent: agentArg, action, since: flags.since === undefined ? null : since },
  }));
  process.exit(0);
}
