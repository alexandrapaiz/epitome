# epito

**An agent is identity + trigger + runtime. `epito` mints all three from one file.**

```bash
npm i -g epito
```

Half a megabyte installed. The engine is not in it — see *The engine is
optional* below.

## The whole agent

```toml
# agent.toml
[agent]
name = "historian"
description = "Writes the daily digest of what changed and why."

[identity]
scopes = ["github:contents", "github:pull_requests"]

[trigger]
cron = "0 6 * * *"        # and/or: webhook = true, to be woken by an event

[runtime]
repo = "acme/roster"
model = "claude-sonnet-5"
max_turns = 40
```

```bash
epito init historian   # scaffold agent.toml and a charter (alias: epito me)
epito validate         # check it against manifest spec v0.1
epito deploy           # give it its own GitHub App: its identity, its key
epito token historian  # mint its own short-lived token, scoped to the manifest
epito run ./roster     # put every agent.toml under ./roster on the runtime
```

`epito validate` is the contract: a field the spec does not define is
refused by name, with the fix in the message, because a manifest that
validates with a tick and then behaves differently is the bug its author
cannot debug.

Which is why the tick also says what it did **not** promise. A few rules
belong to the commands downstream rather than to the validator —
`[runtime].repo` is optional to the spec and required by `epito run`,
`epito deploy` and `epito token`; a scope outside the mapped set fails at
the mint, not here — so `epito validate` names those commands and the fix
instead of leaving you to meet them one at a time:

```
✓ historian is an agent: identity (2 scopes), trigger, runtime

historian is valid, and not ready to run:

  ! [runtime].repo is unset, so `epito run`, `epito ps <dir>`, `epito deploy`
    and `epito token` will refuse this manifest: the runtime clones owner/name
    fresh for every run, and a minted token is scoped to exactly one repository.
    Fix: add repo = "owner/name" to [runtime] in agent.toml.
```

That is a note, not an error: the file is a valid v0.1 manifest and the
exit code stays 0. `epito validate --for-runtime` turns the notes into an
error, for CI that would rather fail here than at 06:00. And in the normal
case you will not see it at all — run `epito init` inside the repository
the agent will work in and it reads `[runtime].repo` off the git origin
(ADR-21).

## What it gives an agent

- **Identity** — its own GitHub App, created from `[identity].scopes` and
  never wider than the file. Short-lived tokens minted per run, an
  append-only audit line for each, the private key at `0600` on your
  machine and never in the repo. Its pull requests open as `<name>[bot]`,
  not as you.
- **Trigger** — `[trigger].cron` becomes a real schedule; `webhook = true`
  lets the ingress wake it. A trigger is explicit and never defaulted: a
  seat that did not ask to be woken by the ingress is not woken by it.
- **Runtime** — a process that outlives the machine it started on, on
  self-hosted Temporal. A reboot mid-run no longer loses the run.

It runs the agent you already have: `[runtime].adapter = "langgraph"` runs
a LangGraph app through the `langgraph.json` its author already wrote,
unmodified — nothing added to its repository, nothing imported from epito.

## The engine is optional

The manifest commands — `init`, `validate`, `deploy`, `token`, `board`,
`report`, `note`, `routes` — need nothing but this package. They are the
whole CLI for most people, so `npm i -g epito` does not drag in Temporal's
~300 MB of prebuilt core.

The two runtime processes and the roster reader do need it:

```bash
npm i -g @temporalio/client @temporalio/worker @temporalio/activity @temporalio/workflow
```

Run one of them without it and `epito` says so in a sentence, naming the
package and the install line — never a stack trace. On a runtime box you do
not do this by hand; `deploy/provision-host.sh` installs the engine with the
CLI.

## Spec and source

The manifest is law and it is frozen at v0.1: four tables, a fixed field
catalogue, and a validator that is tested against the spec document itself
so the two cannot drift.

- Spec: [`spec/manifest.md`](https://github.com/alexandrapaiz/epitome/blob/main/spec/manifest.md)
- Source, decisions and design notes: <https://github.com/alexandrapaiz/epitome>

Requires Node >= 18.
