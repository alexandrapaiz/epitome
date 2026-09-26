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
epito init      # scaffold an agent (alias: `epito me`)
epito validate  # check the manifest
epito run       # put a roster on the runtime: a schedule per trigger, plus the ingress
epito worker    # do the work: run seats off the queue
epito ps        # the roster, read from the runtime
epito token     # mint one agent's own short-lived GitHub token
epito deploy    # mint identity, wire trigger, start runtime  (platform, WIP)
```

What the platform provisions on deploy, so you never do:

- **Identity** — a real principal: non-personal, scoped, revocable
  credentials; short-lived tokens minted per run; an audit log; one-click
  revoke. The agent shows up in GitHub, Asana, Vercel, your database as
  *itself*, never as you.
- **Trigger** — cron, webhook, and event subscriptions. Agents are
  autonomous and triggered, not prompted. (If it only runs when prompted
  inside someone else's identity, it's a skill, not an agent.)
- **Runtime** — a process that outlives the machine it started on.
  epitod runs on Temporal, self-hosted, for nothing: a schedule per
  manifest, a run as a workflow with its retries declared, and a work
  window you can speak into while it is open. A reboot mid-run no longer
  loses the run. See docs/prfaq/epitod-v1-temporal.md.

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
- `cli/` — the `epito` CLI
- `deploy/` — `provision-host.sh`: one always-on host for the runtime
- `docs/` — vision, decisions (ADRs), backlog, ideas ledger, press release
- `prompts/` — seat charters (this company is itself run as an agent org)
