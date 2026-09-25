# epito.me

**An agent is identity + trigger + runtime. We mint all three from one file.**

Vibecoders already build agents. What they can't build alone is everything an
agent needs to be *someone*: its own credentials instead of the owner's
personal tokens, a trigger that wakes it without a prompt, and a container
that outlives a chat session. Today that means duct-taping an identity
product made for humans, a cron service, and a sandbox that dies at midnight,
then threading personal API keys through all three.

epito.me collapses that into one manifest and one command.

```toml
# agent.toml — the whole agent
[agent]
name = "historian"
description = "Writes the daily digest of what changed and why."

[identity]
scopes = ["github:contents", "github:pull_requests"]

[trigger]
cron = "0 6 * * *"        # or: on = ["issue.opened"], or: webhook = true

[runtime]
model = "claude-sonnet-5"
entry = "prompts/historian.md"
```

```bash
epito init         # scaffold an agent (alias: `epito me`)
epito validate     # check the manifest
epito run agents/  # the resident runtime: host a directory of manifests
epito token pm     # mint one short-lived credential for one agent
epito deploy       # mint identity, wire trigger, start runtime  (platform, WIP)
```

### `epito token <name>` — the agent's own credential

An agent with a GitHub App of its own gets a token minted for each run,
bounded by its manifest and by nothing else: the permissions come from
`[identity].scopes`, the repository from `[runtime].repo`, and both are
re-read on every mint, so a token can never carry a permission the (diffable,
reviewable) manifest does not declare.

```bash
$ epito token pm agents/
epito: minted for pm — contents:write, pull_requests:write on acme/roster, installation 4242, expires 2026-09-25T03:03:38Z
ghs_...
```

stdout is the token and nothing else, so a shell can use it directly:

```bash
GH_TOKEN="$(epito token pm agents/)" gh pr create --draft ...
```

`epito run` does this itself, once per run, and hands the result to the agent
process as `GH_TOKEN`/`GITHUB_TOKEN` — which is how a run's commits and pull
request come from `pm[bot]` rather than from you. Agents with no App of their
own keep running on the secrets their manifest names.

The App id and private key live in one of two places, never in the manifest:

| where | what | who uses it |
| --- | --- | --- |
| `$EPITO_APP_ID_<NAME>`, `$EPITO_APP_KEY_<NAME>` | the two secrets, uppercased agent name, `-` → `_` | a runtime box (systemd `EnvironmentFile`) |
| `.epito/principals.json` + `.epito/keys/<name>.pem` (0600) | the record and the key on disk | a laptop; what `epito deploy` will write |

The token itself is written nowhere: not the audit log, not the run log, not a
cache. `.epito/audit.jsonl` gets one line per mint — agent, scopes, granted
permissions, repository, installation, expiry, and the model that acted under
it — and never the credential.

What the platform provisions on deploy, so you never do:

- **Identity** — a real principal: non-personal, scoped, revocable
  credentials; short-lived tokens minted per run; an audit log; one-click
  revoke. The agent shows up in GitHub, Asana, Vercel, your database as
  *itself*, never as you.
- **Trigger** — cron, webhook, and event subscriptions. Agents are
  autonomous and triggered, not prompted. (If it only runs when prompted
  inside someone else's identity, it's a skill, not an agent.)
- **Runtime** — a container that persists. Agents live outside their
  sandboxes.

## Who it's for

Solo builders and small teams running real agent orgs on their own
subscriptions — the people currently pasting personal PATs into workflow
secrets. The seed case: [alexandria](https://github.com/alexandrapaiz/alexandria),
an eleven-seat agent company whose seats all acted as their owner's GitHub
identity until ADR-27 forced a hand-built version of exactly this product.

## What comes later (features, not pillars)

Teams and convening (a roster is accumulated manifests; a meeting is a
roster with minutes), and the crowdsourced agent repository — hire the
generic market agent the way you `npm install`, except what you install is
a principal you grant scopes to.

## Repository layout

- `spec/manifest.md` — the agent.toml spec (v0.1)
- `cli/` — the `epito` CLI (`cli/test/smoke-*.sh`: the smoke tests, which
  spend nothing and touch no network)
- `deploy/` — `provision-host.sh`: one always-on host for the runtime
- `docs/` — vision, decisions (ADRs), backlog, ideas ledger, press release
- `prompts/` — seat charters (this company is itself run as an agent org)
