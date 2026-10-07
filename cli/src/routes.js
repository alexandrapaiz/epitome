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
// audit log follows. Since v0.2 that rule covers the ADDRESS too: a road that
// named its endpoint with `base_url_env` is printed as `$NAME`, because the
// whole reason a manifest names a variable is that the URL is the part you are
// not supposed to publish, and a command that resolved it onto a terminal
// would publish it to the first screen-share.
import { loadRoster } from "./lib/roster.js";
import { routesFor, liveRoutes, endpointLabel, DEFAULT_ROUTE } from "./lib/router.js";

export async function routesCmd(args = []) {
  const dir = args.find((a) => !a.startsWith("-")) ?? ".";
  const json = args.includes("--json");
  const roster = loadRoster(dir);

  const report = [];
  for (const [name, { manifest }] of roster) {
    const declared = routesFor(manifest);
    const { live, skipped } = liveRoutes(declared, process.env);
    const closed = new Map(skipped.map((s) => [s.route.name, s]));
    report.push({
      agent: name,
      adapter: manifest.runtime.adapter ?? "claude",
      takes: live[0]?.name ?? null,
      routes: declared.map((r) => ({
        name: r.name, model: r.model, endpoint: endpointLabel(r),
        key: r.tokenEnv ?? null, concurrency: r.concurrency ?? null,
        open: !closed.has(r.name), closed: closed.get(r.name)?.reason ?? null,
        misconfigured: closed.get(r.name)?.misconfigured ?? false,
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

  // A road this box never had is routing doing its job and exits 0. A road this
  // box HAS and has wrong is a setting somebody has to correct, and it is
  // invisible in the one outcome that matters — the seat still runs, on the
  // next road down, forever. This is the command an operator runs to ask what
  // their box does; refusing here is how the typo stops being silent.
  const broken = report.flatMap((s) => s.routes.filter((r) => r.misconfigured).map((r) => `${s.agent}/${r.name}`));
  if (broken.length) {
    console.error(`\nepito: ${plural(broken.length, "road")} on this machine ${broken.length > 1 ? "are" : "is"} configured and configured wrongly (${broken.join(", ")}) — ${broken.length > 1 ? "each seat falls" : "that seat falls"} through to the next road and runs, so nothing else would have told you. The ✗ ${broken.length > 1 ? "lines" : "line"} above ${broken.length > 1 ? "name" : "names"} the variable and the fix.`);
    process.exit(1);
  }
}

const plural = (n, word) => `${n} ${word}${n === 1 ? "" : "s"}`;
