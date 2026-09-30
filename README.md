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
epito board     # what the seats have been doing: every run, one place
epito report    # file a run report on the board from anywhere
epito token     # mint one agent's own short-lived GitHub token
epito routes    # which model road each seat takes on this machine
epito deploy    # give the agent its own identity on GitHub: its App, its key,
                # its installation  (--dry-run says what it would create)
```

`epito deploy` is the one that makes an agent *someone*:

```bash
epito deploy              # the agent here; `epito deploy <name> <dir>` for a roster
epito deploy --dry-run    # the exact App manifest it would send, no browser, no network
```

It builds a GitHub App from the manifest — the permissions are
`[identity].scopes` mapped by the same table every mint uses, so the App
cannot be created wider than the file — serves one local page for the
single click GitHub requires of a human, and keeps the private key it
gets back in `.epito/keys/<name>.pem` at 0600, gitignored, on your
machine. Then install the App on the repository and run it again: a
second deploy never creates a second App, it records the installation
(spec rule 4, one manifest one principal). After that `epito token
<name>` mints, and the agent's pull requests open as `<name>[bot]`. The
route — its own App per agent, not one shared epito App — is ADR-20.

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

And it runs the agent you already have:

- **Any agent, unmodified** — `[runtime].adapter` says which kind of
  agent a seat is. A LangGraph app runs through the `langgraph.json` its
  author already wrote: nothing is added to its repository, nothing is
  imported from epito, and it gets the same minted identity, the same
  board entry and the same audit line as any other seat. epito links no
  framework and takes no dependency to do it — an adapter is a process it
  spawns and the JSON it prints. See ADR-17.
- **Whichever model is open today** — `[[runtime.route]]` names the roads
  to a model, in order, and a run takes the first one that starts it: the
  cheap provider first, the subscription behind it. A road whose key this
  machine does not hold is skipped, so the same roster runs anywhere; a
  provider that refuses at turn one costs the run nothing; a run that
  reached turn nine is never started again somewhere else. `epito routes`
  says which road each seat takes on this box, and the board records the
  model that actually ran. See ADR-19.
- **Runs you can see inside** — set `OTEL_EXPORTER_OTLP_ENDPOINT` (a
  Phoenix on the box, Jaeger, Tempo, anything that takes OTLP) and every
  run files one trace: the run, its clone, each credential it minted, the
  agent itself, and whatever the agent emits inside that. No span ever
  carries a token, and tracing can never fail a run. See ADR-18.

And one place that says what all of them have been doing:

- **The board** — every run a seat makes files its own report: the
  trigger, the outcome, the turns, the PR, and when a run refused, the
  sentence saying why. `epito board` reads it; `epito report` files onto
  it from a seat running anywhere, including one still in GitHub
  Actions. It has one shape and a seat cannot widen it. The store is an
  append-only event log beside the audit ledger — no database, no SaaS
  board, nothing to keep in sync. See ADR-16.

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
- `cli/adapters/` — one file per agent kind epito can host (`langgraph_run.py`)
- `deploy/` — `provision-host.sh`: one always-on host for the runtime
- `docs/` — vision, decisions (ADRs), backlog, ideas ledger, press release
- `prompts/` — seat charters (this company is itself run as an agent org)
