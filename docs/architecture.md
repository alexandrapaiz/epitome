# Product architecture (proposed, 2026-09-18, rev 2)

Status: chair's draft, rewritten on the owner's correction ("product
architecture, not operations architecture"). Becomes an ADR when
EPI-4's route spike lands and the owner signs. Sequencing note at the
end is the only ops content.

## Organizing rule

The agent definition (ADR-2) is the plugin architecture: one core,
three provider interfaces — one per leg. Platforms exist only behind
the interfaces; core never grows a platform branch. If an integration
can't fit a seam, the seam is wrong: fix the interface, record an ADR.

## Components

```
packages/
  core/        @epito/core — manifest parse/validate (spec v0.1),
               provider registry, orchestration, audit writer
  providers/
    github/    IdentityProvider(App) + TriggerProvider(Actions cron)
               + RuntimeProvider(Actions job)          [v1, bet 1]
    systemd/   TriggerProvider(timers) + RuntimeProvider(units)
                                                       [phase 2]
    <next>/    second identity target — Linear rejected (ADR-6);
               market re-justifies the ranking 10-02, owner rules
  cli/         epito — thin mouth: argv → core, no logic
  mcp/         stdio MCP server — thin mouth: tools → core  [bet 2]
  epitod/      local daemon                             [phase 2]
```

The scope 2a refactor (EPI-10) is the birth of core: init/validate
logic leaves cli/src/index.js for packages/core.

## Provider interfaces (the whole contract)

```ts
interface IdentityProvider {
  mint(m: Manifest): Promise<Principal>     // idempotent on (provider, agent.name) — spec rule 4
  token(p: Principal): Promise<Credential>  // short-lived, scoped to m.identity.scopes
  revoke(p: Principal): Promise<void>
}
interface TriggerProvider { wire(m: Manifest, p: Principal): Promise<TriggerBinding> }
interface RuntimeProvider { materialize(m: Manifest, p: Principal): Promise<RuntimeSpec> }
```

EPI-4's route decision (App-per-agent vs shared App) shapes `mint`'s
internals and the Principal record; the interface above survives
either answer — that is deliberate.

Inside the runtime leg the model is routable (ADR-8): the agent IS
the identity, `[runtime].model` names today's brain, manifest v0.2
may take a routing policy in its place, and no provider, mapping, or
roster surface ever keys on the model. The audit line records which
model executed under the identity.

## Data model

```ts
Manifest   = agent.toml, parsed                    // publishable, never secret
Principal  = { agent, provider: "github-app",
               externalId,                          // App id
               installations: [{repo, installationId}],
               createdAt }                          // NEVER contains secrets
Credential = { token, expiresAt, scopes }           // in-memory only, never persisted
AuditEntry = { ts, agent, action: "deploy"|"mint"|"revoke",
               scopes, provider, model }            // append-only; model
               // = which brain executed, per ADR-8 (identity acts,
               // model is recorded)
```

On-disk store, three files at three trust levels:

```
.epito/
  principals.json     # Principal records — safe to read aloud
  keys/<agent>.pem    # 0600, one per principal, gitignored
  audit.jsonl         # append-only
```

## Flow: `epito deploy` (bet 1)

1. Parse + validate agent.toml (refuse anything spec v0.1 refuses).
2. IdentityProvider.mint: start one-shot localhost listener → POST the
   pre-filled app manifest to GitHub → human clicks Create (the one
   click) → redirect returns a temporary code →
   `POST /app-manifests/{code}/conversions` → App id + private key →
   persist to `.epito/` (0600).
3. Open the App install URL for the target repo; capture the
   installation id into principals.json.
4. TriggerProvider.wire + RuntimeProvider.materialize: emit
   `.github/workflows/agent-<name>.yml` — cron from `[trigger]`, job
   begins with `epito token <name>`.
5. Append the audit line. Re-deploy updates the same principal
   (idempotence on name), never duplicates.

## Flow: per run (`epito token <name>`)

1. Load `keys/<agent>.pem`; sign a 10-minute JWT (`iss` = App id).
2. `POST /app/installations/{id}/access_tokens` with exactly the
   manifest's permissions → installation token (~1 h).
3. Hand the token to the agent process via env; never write it to
   disk. Append the audit line.
4. Commits/PRs attribute to `<name>[bot]`. Revoke = uninstall the App
   (GitHub refuses all future mints) + delete local keys.

## epitod — the runtime (shipped; the Omarchy surface)

Rev 2, 2026-09-26: epitod v1 replaced the hand-built middle with a
durable-execution engine. The full design is
docs/prfaq/epitod-v1-temporal.md; the shape in five lines:

- **Temporal, self-hosted, is the engine. epitod is the face.** No
  Temporal word reaches a product-facing string.
- `[trigger].cron` becomes one Temporal **Schedule** per manifest, id
  `seat:<name>`, UTC, overlap `BUFFER_ONE`. `epito run <roster>`
  reconciles them to match the roster and is idempotent.
- A run is the workflow **`SeatRun`** over four activities — `clone`,
  `execute`, `record`, `notify` — each with its `RetryPolicy` and
  timeout declared at the call site. `execute` is `maximumAttempts: 1`,
  because an execution that half-ran has already pushed commits.
- Presence is the workflow **`SeatWindow`**, holding the executor's
  `session_id` and the clone path, driven by `message` / `close` /
  `refresh` signals and a TTL timer.
- One systemd unit reconciles and serves the ingress
  (`epitod.service`); a second does the work on task queue `seats`
  (`epitod-worker.service`). `epito ps` reads the engine —
  `.epito/state.json` is retired. `.epito/audit.jsonl` stays as the
  product's own append-only record, and must remain readable if the
  engine is ever replaced.

The earlier phase-2 plan for this layer — a systemd user unit and timer
generated per manifest, journald as the log, `epito ps` from systemctl
state — is superseded. It was a second scheduler, and the whole point of
v1 is that we stopped writing those. What survives from it is the
packaging idea: epitod plus the CLI plus the MCP server as one
installable thing, which is still the Omarchy channel.
- OS-level identity mirrors platform identity: the same someone in
  `ps` and in the commit log.
- Omarchy integration = a package (AUR first) installing epito +
  epitod + the MCP server. Nothing bespoke: the systemd provider pair
  IS the integration. Process-model choice (DynamicUser vs real users
  vs podman) is decided inside the phase-2 pitch.

## Control plane (phase 3, only when it earns its existence)

Four services over one Postgres; clients reach it through the SAME
provider interfaces (hosted mode is a provider swap, not a rewrite —
the architectural test that the seams are right):

- **api** — roster, orgs, grants (CRUD; the paid tier's surface)
- **mint** — App private keys move from `.epito/` to a KMS; tokens
  issued via API; per-org rate/scope policy
- **ingress** — per-agent public webhook URLs; dispatches
  `webhook = true` triggers to runtimes
- **audit** — the shared, queryable trail teams pay for

DB spine: orgs → agents (manifest snapshots) → principals → grants →
audit. The marketplace (later) distributes manifests as principals
with ADR-2's triad test as the admission bar.

## Toolchain (rev 3, per owner feedback: name the tools)

TypeScript 5.x strict on Node ≥22 LTS, ESM only; pnpm workspaces (no
turborepo — ceremony exceeds the work at this size); tsc project
references; vitest + undici MockAgent; biome for lint+format (one
tool); GitHub Actions CI (matrix: Node 22/24, ubuntu+macos);
changesets → npm with provenance. cli/src/index.js converts to TS
inside scope 2a under the byte-identical acceptance test.

**Dependency budget** (a new runtime dep = a justification line in the
PR body, or rejected; lockfile committed): core: smol-toml only (zod
rejected — the hand-rolled validator's error voice is product
surface). cli: none. mcp: @modelcontextprotocol/sdk. providers/github:
jose (RS256; native fetch, no octokit — four endpoints don't earn a
client library). providers/systemd: none targeted (unit files
written directly, systemctl exec'd). Control plane: hono + pg
proposed, decided at the phase-3 pitch.

**epitod's budget changed, and this is the justification line** (epitod
v1, 2026-09-26; the full argument is docs/prfaq/epitod-v1-temporal.md,
ratified by merging that PR): `@temporalio/client`, `@temporalio/worker`,
`@temporalio/workflow`, `@temporalio/activity`, and an operated Temporal
server. "None targeted" bought a 364-line `cli/src/run.js` that was a
scheduler, a per-seat mutex, a retry loop and a crash-recovery story
written badly, and whose worst defect was silent: a run in flight when
the box rebooted was simply gone, with nothing in the system aware it had
existed. Those four things are a workflow engine. The deps are accepted
because the part we stopped writing is the part that is hardest to get
right and least differentiating, and because the engine is a surface we
can leave under constraint 1 — the manifests, the activities and
`audit.jsonl` are engine-agnostic by construction. Temporal Cloud is
rejected permanently: a vendor in the runtime path, and a per-action
bill.

**The router took nothing either** (2026-09-28, ADR-19): routing a run to
another provider is two environment variables and a different `--model`,
which is what fifteen hand-written workflow steps across the company
already prove. A gateway (LiteLLM, OpenRouter) would have been a second
service in the runtime path to buy what a table in the manifest buys, so
it stays available as one route's `base_url` and nothing more.

**The adapter and tracing legs took nothing** (2026-09-27, ADR-17 and
ADR-18; this line exists because the budget rule requires one either
way). Hosting a LangGraph app added no dependency because an adapter is a
subprocess and a result contract, not an SDK: `cli/adapters/langgraph_run.py`
is stdlib-only Python and runs in the AGENT's interpreter, where the
framework already lives. Tracing added none because the OpenTelemetry
Node SDK is six packages, a provider and a background flush whose
lifetime fights an activity's, where what epito needs is three spans per
run with ids two processes can derive from the run id —
`cli/src/lib/trace.js` is that, over `fetch`. Both remain replaceable in
one file if the trade changes: adopt the SDK when a process epito did not
spawn has to be given a trace context.

## Testing strategy

Unit: validator golden fixtures, every error string asserted verbatim.
Integration: mint/token/revoke against MockAgent'd GitHub API incl.
failure paths (expired code, missing installation). Regression: CLI
byte-identical diff during 2a, then retired. E2E: real deploy to a
scratch account, transcript pasted in the PR (charter rule) before any
provider change merges. No coverage worship; a bug found later becomes
a fixture the same day (ExO logs the lesson).

## Threat model

agent.toml leaked → nothing (publishable by design; tripwires reject
pasted credentials). principals.json leaked → metadata only. PEM
stolen → act as that ONE agent until revoke (0600, gitignored at init,
revoke = uninstall; OS-keychain on backlog). Token exfiltrated → ≤1 h,
that agent's scopes only (env-only handoff, never-log, never disk).
npm supply chain → dependency budget + lockfile + provenance.
Temporal's database holds every workflow and activity argument in plain
text → no secret value may be one; the manifest (publishable by design)
is what crosses that boundary, and the worker reads values from its own
environment. Self-hosted Temporal's gRPC endpoint has no mTLS → bound to
loopback behind ufw 22/443, so reaching it means already being on the
box, and mTLS is the fix when a second worker host exists. The Temporal
UI shows history, which shows prompts → loopback only, reached by SSH
tunnel, never published.
Webhook forgery (phase 3) → per-agent signing secret at ingress.
Owner's credentials → structurally absent; that's the product.
Standing rule: a control in this table absent from the code is an
incident (security seat's biweekly sweep audits it).

## Infrastructure, end to end (rev 4, owner fine-tune 2026-09-19)

Per phase — compute, containers, data storage, secrets — with named
proposals, never TBDs:

- **Phase 1 (now).** Compute: GitHub Actions runners, ephemeral, on
  the user's account. Containers: none; the runner image is the
  environment. Data: `.epito/` three-trust-level store (principals
  .json, keys/, audit.jsonl). Secrets: PEM 0600 local; GitHub repo
  secrets carry `[runtime].env` names.
- **Phase 2 (epitod, shipped).** Compute: one always-on host (Oracle
  Always Free A1 today, any Ubuntu box by design), two systemd system
  units as the unprivileged user `seats`. Engine: Temporal self-hosted
  in two containers (`temporalio/auto-setup`, `temporalio/ui`) on the
  host's Postgres, bound to loopback. Installed separately from epito and
  by nothing epito ships yet — docs/deploy/README.md ("Temporal server +
  UI") carries the two routes; which one epito adopts as its own
  installer is an open proposal in docs/ideas.md. Data: `.epito/audit.jsonl` plus
  Temporal's own workflow history (retention is a namespace setting; 30
  days is the starting value for 36 seats). Secrets: `/srv/asc/env` at
  0600, optionally rendered by an Infisical agent; secret values are
  held by the worker process only, never by a workflow argument.
  Containers per agent (rootless podman, one OCI image per agent) is
  still unbuilt and still the right next isolation step; a seat run is
  a process under `PrivateTmp=yes` today. Secrets proposal for phase 3
  unchanged: OS keychain replaces bare PEM files.
- **Phase 3 (plane).** Compute: Vercel functions for api + ingress;
  agent runtimes STAY user-side (hosted runners a later paid option).
  Containers: the same per-agent OCI images from GHCR. Data: Supabase
  Postgres 16 — orgs → agents (manifest snapshots) → principals →
  grants → audit; chosen over bare Neon because it buys the OAuth 2.1
  server (a future per-agent database IdentityProvider) and catalog
  distribution, while remaining plain Postgres and therefore
  swappable under constraint 1. Secrets: App keys to a KMS — AWS KMS
  proposed, libsodium-sealed columns the fallback, decided at the
  phase-3 pitch. Local mode keeps working regardless (constraint 4).
- **Cost shape:** phases 1-2 cost the company zero by design; the
  first infrastructure bill arrives with phase 3, after demand.

## The connective stack — distribution is engineering (owner doctrine)

Owner's words (2026-09-19): "distribution is a part of engineering...
a whole connective stack is our infrastructure plan I mean
distribution." The stack we build on is the stack we distribute
through; every layer is chosen twice, once as infrastructure and once
as a channel:

| Layer | Tool | Role in the system | Distribution value |
|---|---|---|---|
| Cloud | Vercel | phase-3 control plane (api + ingress) | Marketplace AI-agents listing |
| Data | Supabase Postgres | phase-3 DB; OAuth 2.1 → future per-agent DB identity | partner catalog at revenue |
| Human auth | Clerk | control-plane sign-in for owners/orgs (humans only — agents use OUR identity layer) | vibecoder auth default, template ecosystem |
| Work surfaces | GitHub, Linear | IdentityProvider targets (App; app-user pending ADR-6 re-rank) | agents demo the product in-situ, as themselves |
| Models | Anthropic Claude, OpenAI, any Anthropic-API-compatible provider (Moonshot first) | `[runtime].model`, and `[[runtime.route]]` names the roads in order: a run takes the first one open on this box, and falls back only while the agent has done nothing (ADR-19). A gateway is one route's `base_url`, never a dependency | model-agnostic = every lab's users addressable, and the cheap road is the runtime's job rather than every workflow's |
| Editors | Claude Code, Cursor | MCP server + skill (bet 2) | zero-listing-bar channel |
| Agent frameworks | LangGraph (first; n8n, OpenClaw next) | `[runtime].adapter` hosts one unmodified, through its own `langgraph.json` (ADR-17) | the largest installed base of agents that have no identity — and a surface, since epito links none of it |
| Tracing | OTLP (Phoenix, Jaeger, Tempo, LangSmith) | `OTEL_EXPORTER_OTLP_ENDPOINT`: one trace per run, the agent's own steps inside it (ADR-18) | a surface by construction — the protocol is the integration, so every backend is already supported |
| Runtime engine | Temporal (self-hosted) | epitod v1's durable execution: schedules, `SeatRun`, `SeatWindow` | a swappable backend, never a channel — the one row chosen ONCE, as infrastructure only |
| OS | Omarchy / Arch | epitod + systemd providers (phase 2) | AUR package; curated-defaults pitch |

Constraint 1 governs every row: a surface or a swappable backend,
never a load-bearing dependency. The engine row is the honest exception
to the "chosen twice" rule and is marked as such: it buys no
distribution at all. It earns its place on mechanism alone, and the test
that it stayed swappable is that `audit.jsonl` and the activities carry
no Temporal type.

## Sequencing (the one ops paragraph)

Phase 1 = bets 1-2 as bet (GitHub providers, local store). Phase 2 =
epitod + systemd providers + AUR package; PM shapes it as a pitch for
the cycle-2 betting table (owner accepted the Omarchy integration,
ideas ledger 2026-09-18). Phase 3 = control plane; not before demand
is proven. Properties preserved throughout: manifests publishable,
secrets never in manifests, local-first modes keep working when the
hosted plane exists.
