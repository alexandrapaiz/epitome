// `epito routes [dir]` — which road each seat would take on THIS machine.
//
// The router's promise is that a roster is portable: the same manifests run
// on a box that holds a Moonshot key and on one that does not, and only the
// second goes straight to the subscription (ADR-19). The cost of that promise
// is that "which model is my company actually running on" stops being
// readable from the manifests alone. This command is the answer: the chain a
// seat declared, and next to each road whether it is open here and why not.
//
// It reads the env for PRESENCE and never prints a value — the same rule the
// audit log follows.
import { loadRoster } from "./lib/roster.js";
import { routesFor, liveRoutes, DEFAULT_ROUTE } from "./lib/router.js";

export async function routesCmd(args = []) {
  const dir = args.find((a) => !a.startsWith("-")) ?? ".";
  const json = args.includes("--json");
  const roster = loadRoster(dir);

  const report = [];
  for (const [name, { manifest }] of roster) {
    const declared = routesFor(manifest);
    const { live, skipped } = liveRoutes(declared, process.env);
    const closed = new Map(skipped.map((s) => [s.route.name, s.reason]));
    report.push({
      agent: name,
      adapter: manifest.runtime.adapter ?? "claude",
      takes: live[0]?.name ?? null,
      routes: declared.map((r) => ({
        name: r.name, model: r.model, endpoint: r.baseUrl ?? null,
        key: r.tokenEnv ?? null, concurrency: r.concurrency ?? null,
        open: !closed.has(r.name), closed: closed.get(r.name) ?? null,
      })),
    });
  }

  if (json) { console.log(JSON.stringify(report, null, 2)); return; }

  for (const seat of report) {
    const takes = seat.takes ? `takes ${seat.takes}` : "NO OPEN ROUTE — this seat cannot run here";
    console.log(`${seat.agent} (${seat.adapter}) — ${takes}`);
    for (const r of seat.routes) {
      const mark = !r.open ? "✗" : r.name === seat.takes ? "→" : " ";
      const where = r.endpoint ? ` at ${r.endpoint}` : " on this machine's own executor login";
      const lane = r.concurrency ? `, ${r.concurrency} at a time` : "";
      const why = r.open ? "" : ` — closed: ${r.closed}`;
      const key = r.key ? ` [key $${r.key}]` : "";
      console.log(`  ${mark} ${r.name === DEFAULT_ROUTE ? "(no routes declared)" : r.name}: ${r.model}${where}${key}${lane}${why}`);
    }
  }
  const stranded = report.filter((s) => !s.takes);
  if (stranded.length) {
    console.error(`\nepito: ${stranded.length} seat${stranded.length > 1 ? "s have" : " has"} no open route on this machine (${stranded.map((s) => s.agent).join(", ")}) — set one of the keys named above, or give ${stranded.length > 1 ? "them" : "it"} a final route that needs none`);
    process.exit(1);
  }
}
