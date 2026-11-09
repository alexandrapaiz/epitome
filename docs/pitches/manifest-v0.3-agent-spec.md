# Pitch: Manifest v0.3 — the agent-spec layer

Shaped 2026-11-09 by the PM seat, for cycle 3.

## Problem

ADR-25 (owner, 2026-10-16) ruled that epito owns the agent-spec layer:
every agent-defining property a platform would otherwise bury inside
its own wall belongs in one publishable file, the manifest. The owner
handed over a table of nine properties, struck *human owner* (the
identity leg already proves it — ADR-20's App-per-agent flow names the
account the App was created on, and a field that repeats that can
lie), and left eight. Three already live in `agent.toml` today
(spec/manifest.md): Purpose (`[agent].description`), Permission
envelope (`[identity].scopes`, the ceiling per rule 2), and Reusability
(rule 1, a publishable manifest). Five do not exist anywhere: Autonomy
tier, Memory boundary, Escalation rules, Eval suite, Telemetry.

ADR-25 names its own sequence explicitly: "After the MVP bet… The PM
shapes this as the first pitch of cycle 3, with the Slack identity and
the passport, because a spec that covers the eight properties is what
makes the passport worth signing." This pitch is that first pitch.
Cycle 2's own MVP work is engineering-complete (cycle-2 retro,
2026-11-01); the npm publish and the browser-click deploy proof are
pure owner/chair waits per section 22 and do not block this bet — they
are unrelated surfaces, not a dependency chain.

ADR-25 also already did the hard design work: which eight, what each
one means, and that telemetry rides OpenTelemetry's own conventions
rather than inventing a schema (`OTEL_*`, the same variables every HQ
seat already runs under, per `[runtime].env`'s existing pattern). What
is left is naming the five missing tables' fields, wiring the
validator, and documenting them — field names and defaults are
explicitly the engineer's own call, proposed in the same PR as the
code that reads them (ADR-25: "the spec changes with the code").

## Appetite

Small batch: 3 engineer runs. The owner's own ADR already settled the
hard questions (which properties, what telemetry format, that human
owner is struck); this bet is spec plumbing and validator wiring, not
new design. If it wants more than that, cut rather than extend: eval
suite and escalation-rules tables first (newest, least depended-on by
anything else this cycle), autonomy tier and memory boundary second,
telemetry's `[telemetry]` table last to cut, since it is the one piece
of this pitch the passport pitch's own "spec question is a fresh
pitch" line (passport-v0-github.md) does not already name as deferred.

## Rough solution (breadboard)

Five new optional TOML tables, each following v0.1/v0.2's own pattern
(explicit, never defaulted; `epito validate` refuses an unknown key,
so each table is additive and v0.1/v0.2 manifests stay valid with none
of them present):

- `[autonomy]` — tier taken alone vs. escalated, naming this company's
  own three tiers (ADR-011, `docs/standards/pm.md` §10: self-merge,
  PM-merge, owner-merge) as the spec's first worked instance of the
  property, not a new vocabulary invented for this file.
- `[memory]` — what the runtime keeps between runs, for how long, and
  where. Modeled on the seat notebook and scoped recall HQ already
  runs its own seats under; this table names the convention, it does
  not build a new store.
- `[escalation]` — to whom, and on what. A person, another agent, or
  the board are the three targets this company's own practice already
  uses (pm.md §11.3's dispatch criteria, the board's `to_seat`/`kind`
  shape); the table names which of the three and under what condition.
- `[eval]` — the suite that grades the agent, the same shape
  `[runtime].entry` already uses to name a charter: a path, read, not
  interpreted by this pitch.
- `[telemetry]` — exporter, endpoint name, retention, in
  OpenTelemetry's own words (ADR-25 item 2). Today `[runtime].env`
  names `OTEL_*` variables by hand with nothing declaring what they
  mean; this table is the declaration, still backed by the same
  environment variables, never a new trace schema.
- `epito validate` extended to parse and report on each table when
  present (absent is valid, per the additive rule above); done means a
  manifest declaring all five validates clean, and a manifest
  declaring a malformed one of them refuses with the same
  vibecoder-grade error strings the rest of the spec already uses.
- `spec/manifest.md`'s field catalogue gains five entries in the
  existing format (one TOML block, one comment block, same page).

## Rabbit holes

- An eval harness, an escalation router, or a memory store: no. This
  pitch is the five tables and the validator that reads them. What
  consumes a `[memory]` table's declared retention, or what actually
  routes an `[escalation]` hit, is later work this pitch explicitly
  does not build — naming the gap in decisions.md is the deliverable,
  not closing it.
- Retrofitting HQ's own ~40-manifest roster to declare the new tables:
  no, that is a rollout card for whichever pass wants it once v0.3
  ships, not this pitch's scope.
- A `[telemetry]` table that invents its own exporter format: no —
  OpenTelemetry's own words only, per ADR-25 item 2, explicitly.
- Autonomy-tier *enforcement* in the runtime (refusing an action a
  declared tier doesn't permit): no. The field is declared and
  validated; enforcing it against a real run is a different pitch,
  once there is a real caller for the field.

## No-gos

No marketplace or catalog UI consuming Reusability's "where else this
manifest runs" (ADR-25's own words: "the marketplace's precondition" —
deferred under ADR-1's wedge-first rule, same as every prior cycle's
Later bucket). No retrofitting the HQ roster. No new telemetry
schema. No enforcement engine for autonomy, memory, or escalation —
declaration only, this cycle.
