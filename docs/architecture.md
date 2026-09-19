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

## Data model

```ts
Manifest   = agent.toml, parsed                    // publishable, never secret
Principal  = { agent, provider: "github-app",
               externalId,                          // App id
               installations: [{repo, installationId}],
               createdAt }                          // NEVER contains secrets
Credential = { token, expiresAt, scopes }           // in-memory only, never persisted
AuditEntry = { ts, agent, action: "deploy"|"mint"|"revoke",
               scopes, provider }                   // append-only
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

## epitod — the local daemon (phase 2; the Omarchy surface)

- Watches a manifests directory; per manifest, generates a systemd
  user unit (`ExecStart=epito run <name>`, `DynamicUser=yes` or a
  rootless podman container) and a timer translated from
  `[trigger].cron`.
- journald is the runtime log; an adapter appends audit entries.
- `epito ps` renders the roster from systemctl state.
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

## Sequencing (the one ops paragraph)

Phase 1 = bets 1-2 as bet (GitHub providers, local store). Phase 2 =
epitod + systemd providers + AUR package; PM shapes it as a pitch for
the cycle-2 betting table (owner accepted the Omarchy integration,
ideas ledger 2026-09-18). Phase 3 = control plane; not before demand
is proven. Properties preserved throughout: manifests publishable,
secrets never in manifests, local-first modes keep working when the
hosted plane exists.
