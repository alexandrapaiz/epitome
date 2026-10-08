// What a roster asks of the BOX it runs on: every variable its manifests name,
// and whether this machine holds it.
//
// The runtime injects into a run "the names listed in [runtime].env (values
// read from the worker's own environment)" — and only those it has:
//
//     for (const k of rt.env ?? []) if (process.env[k] !== undefined) ...
//
// A name the box does not hold is dropped there, silently, and the run goes
// ahead without it. That is the right behaviour — a roster is portable, and
// `LINEAR_API_KEY` genuinely is optional to the seat that names it — but it
// means a box can be short of a name the agent actually needs and nothing
// anywhere says so. The seat runs, exits 0, and simply does less than it was
// built to do.
//
// This company already paid for that. `agents/pm/agent.toml` names
// BOARD_API_URL and BOARD_RUNTIME_TOKEN; `deploy/provision-host.sh` writes an
// env file that holds neither, because that file is a second, hand-maintained
// copy of the roster's names and the two drifted the moment the roster grew.
// The PM seat on a freshly provisioned box would run, green, and file nothing
// to the board — and the board is where an owner looks to see that the seats
// ran.
//
// So the names stop being written twice. They are IN the manifests; this is
// the reader, and `epito env` is the operator's view of it. Same shape as
// `epito routes`, for the same reason: which model a seat runs on and which
// secrets it sees are both facts about a box, unanswerable from the manifests
// alone, and each deserves a command rather than a guess.
//
// It reads the environment for PRESENCE and never prints a value — the rule
// the audit log, the run log and `epito routes` all keep (spec rule 1 is about
// the manifest; this is the same promise where the values actually are).
import { routesFor } from "./router.js";
import { webhookName } from "./slack.js";

// Set, and set to nothing. A third state, and the one the env file invites:
// `KEY=` in a systemd EnvironmentFile is a name the box HOLDS whose value is
// the empty string, so the runtime injects it, the agent reads it, and the
// request it builds out of it fails somewhere far away from here. It is the
// env-file twin of a `base_url_env` that does not hold a URL (spec v0.2), and
// it gets the same treatment: louder than absent, because absent is a choice
// and this is a line somebody half-filled in.
export const HELD = "held";
export const EMPTY = "empty";
export const ABSENT = "absent";

export const holding = (name, env = process.env) =>
  env[name] === undefined ? ABSENT : env[name] === "" ? EMPTY : HELD;

// What a name is TO a seat, in the seat's own vocabulary. A name with no
// special job is read by the agent itself and nothing here can say more about
// it than that; the three that do have a job are worth naming, because "the
// key for route open" tells an operator which command to go read next.
function rolesOf(manifest) {
  const roles = new Map();
  const hook = webhookName(manifest);
  if (hook) roles.set(hook, "the one-line post after every run");
  // Routes last: a name that is both a webhook and a road's credential is a
  // manifest nobody should write, and the road is the more specific fact.
  for (const r of routesFor(manifest)) {
    if (r.baseUrlEnv) roles.set(r.baseUrlEnv, `the endpoint for route "${r.name}"`);
    if (r.tokenEnv) roles.set(r.tokenEnv, `the key for route "${r.name}"`);
  }
  return roles;
}

// Every name a seat's manifest asks the box to hold. `[runtime].env` is the
// list the runtime injects from; a route's `token_env` and `base_url_env` are
// required to appear in it (the validator refuses otherwise), and they are
// unioned in anyway rather than trusted — this function is read by an operator
// standing in front of a box, and a name missing from this list because of a
// validator rule somewhere else is a name they will not put in the file.
export function namesFor(manifest) {
  const rt = manifest?.runtime ?? {};
  const declared = Array.isArray(rt.env) ? rt.env.filter((n) => typeof n === "string" && n) : [];
  const out = [...declared];
  for (const r of routesFor(manifest)) {
    for (const n of [r.baseUrlEnv, r.tokenEnv]) if (n && !out.includes(n)) out.push(n);
  }
  return out;
}

// The whole report, pure, from a roster and an environment.
//
// Returns { names, seats, missing, empty }:
//   names  one row per distinct variable, alphabetical — who asks for it, what
//          it is to each of them, and what this box is doing about it
//   seats  one row per seat, in roster order, with the names it is short of
//
// Alphabetical rather than roster order for `names` because the thing being
// produced from it is a file of KEY=value lines, which is read by eye.
export function rosterEnv(roster, env = process.env) {
  const names = new Map();
  const seats = [];
  for (const [agent, entry] of roster) {
    const manifest = entry?.manifest ?? entry;
    const roles = rolesOf(manifest);
    const asked = namesFor(manifest);
    for (const name of asked) {
      if (!names.has(name)) names.set(name, { name, state: holding(name, env), uses: [] });
      const row = names.get(name);
      if (!row.uses.some((u) => u.agent === agent)) row.uses.push({ agent, role: roles.get(name) ?? null });
    }
    const short = asked.filter((n) => holding(n, env) !== HELD);
    seats.push({
      agent,
      asked,
      held: asked.filter((n) => holding(n, env) === HELD),
      missing: asked.filter((n) => holding(n, env) === ABSENT),
      empty: asked.filter((n) => holding(n, env) === EMPTY),
      short,
    });
  }
  const rows = [...names.values()].sort((a, b) => a.name.localeCompare(b.name));
  return {
    names: rows,
    seats,
    missing: rows.filter((r) => r.state === ABSENT),
    empty: rows.filter((r) => r.state === EMPTY),
  };
}

// Who asks for a name, and what it is to them. Collapsed when every seat means
// the same thing by it, which is the ordinary case and the readable one — five
// seats and one webhook is one line, not five. Shared by the report and the
// template so a name cannot be explained two ways in one terminal.
export function askers(uses) {
  const roles = new Set(uses.map((u) => u.role ?? ""));
  if (roles.size === 1) {
    const role = uses[0].role;
    return `${uses.map((u) => u.agent).join(", ")}${role ? ` (${role})` : ""}`;
  }
  return uses.map((u) => (u.role ? `${u.agent} (${u.role})` : u.agent)).join(", ");
}

// The env file, generated instead of remembered: one commented line per name,
// naming the seats that ask for it and what it is to them.
//
// A name this box already holds comes out COMMENTED, and says why. The file
// this is pasted into is the one place a box's secrets live, and a template
// that blanked a working value because somebody pasted it twice would be this
// command causing the outage it exists to prevent — the same rule
// provision-host.sh keeps when it finds an env file already there.
export function envTemplate(report, { dir = "the roster" } = {}) {
  const lines = [
    `# Every variable the roster at ${dir} names, as env-file lines: one`,
    "# KEY=value per line, no quotes, no export (a systemd EnvironmentFile takes",
    "# nothing else). Generated by `epito env --template` from the manifests",
    "# themselves, so this list cannot drift from the roster the way a",
    "# hand-kept one does.",
    "#",
    "# A name this box does not hold is NOT injected into the run, and the agent",
    "# runs anyway, without it. A name set to an empty value IS injected, empty.",
    "",
  ];
  for (const row of report.names) {
    lines.push(`# ${askers(row.uses)}`);
    lines.push(row.state === HELD
      ? `# ${row.name}=   # already set on this box; left commented so pasting this cannot blank it`
      : `${row.name}=`);
    lines.push("");
  }
  return lines.join("\n");
}
