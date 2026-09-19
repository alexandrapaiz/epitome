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
client library). providers/systemd + epitod: none targeted (unit files
written directly, systemctl exec'd). Control plane: hono + pg
proposed, decided at the phase-3 pitch.

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
- **Phase 2 (epitod).** Compute: the user's machine, systemd user
  units + timers. Containers: rootless podman 5.x, one OCI image per
  agent, base image on GHCR (docker rejected: root daemon);
  DynamicUser as the no-container fallback. Data: local store +
  journald with an adapter into audit.jsonl. Secrets proposal: OS
  keychain (libsecret / macOS Keychain) replaces bare PEM files.
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
| Models | Anthropic Claude, OpenAI | `[runtime].model` is provider-agnostic; owner's key as a named secret in `[runtime].env`; gateway option phase 3 | model-agnostic = every lab's users addressable |
| Editors | Claude Code, Cursor | MCP server + skill (bet 2) | zero-listing-bar channel |
| OS | Omarchy / Arch | epitod + systemd providers (phase 2) | AUR package; curated-defaults pitch |

Constraint 1 governs every row: a surface or a swappable backend,
never a load-bearing dependency.

## Sequencing (the one ops paragraph)

Phase 1 = bets 1-2 as bet (GitHub providers, local store). Phase 2 =
epitod + systemd providers + AUR package; PM shapes it as a pitch for
the cycle-2 betting table (owner accepted the Omarchy integration,
ideas ledger 2026-09-18). Phase 3 = control plane; not before demand
is proven. Properties preserved throughout: manifests publishable,
secrets never in manifests, local-first modes keep working when the
hosted plane exists.
