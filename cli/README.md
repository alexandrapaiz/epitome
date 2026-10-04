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
epito audit            # read the ledger: what was granted, to whom, until when
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

Given a directory it checks the whole roster, and the last line is the
only one that speaks for `epito run` — so it is the one line that looks:

```
✓ 5 of 5 manifests are agents: 4 on a cron, 1 presence-only (exo)
  every one is ready to run, and 127.0.0.1:7233 is answering: there is
  nothing here `epito run agents` would refuse
```

```
✓ 5 of 5 manifests are agents: 4 on a cron, 1 presence-only (exo)
  every manifest is ready; the engine is not: nothing is answering at
  127.0.0.1:7233 (ECONNREFUSED), so `epito run agents` refuses before it
  reads a seat
    Fix: run `temporal server start-dev` for a local engine, or set
    TEMPORAL_ADDRESS ...
```

Still exit 0 in both: your manifests are the question a roster validator
can answer with no box, and they are good. `--for-runtime` is what makes
the second one exit 1, because that is the flag that asks whether the
runtime would accept this roster, and in the second case there is no
runtime (ADR-24).

## What it gives an agent

- **Identity** — its own GitHub App, created from `[identity].scopes` and
  never wider than the file. Short-lived tokens minted per run, an
  append-only audit line for each, the private key at `0600` on your
  machine and never in the repo. Its pull requests open as `<name>[bot]`,
  not as you. `epito audit` reads that record back.
- **Trigger** — `[trigger].cron` becomes a real schedule; `webhook = true`
  lets the ingress wake it. A trigger is explicit and never defaulted: a
  seat that did not ask to be woken by the ingress is not woken by it.
- **Runtime** — a process that outlives the machine it started on, on
  self-hosted Temporal. A reboot mid-run no longer loses the run.

It runs the agent you already have: `[runtime].adapter = "langgraph"` runs
a LangGraph app through the `langgraph.json` its author already wrote,
unmodified — nothing added to its repository, nothing imported from epito.

## The record

Every App created, every token minted and what it was allowed to do, every
run, every road refused: one append-only line each in `.epito/audit.jsonl`,
written by the thing that did the work and by nothing else. `epito audit`
reads it back.

```
$ epito audit --limit 2
the ledger — 2 seats, 133 lines, 2026-10-02 06:00Z → 14:31Z   (.epito/audit.jsonl)

SEAT       MINTS  DEPLOYS  RUNS  FAILED  REFUSED  APP     REPO          PERMISSIONS NOW                      LAST MINT
digest     30     1        30    1       2        707071  acme/product  contents:write                       2026-10-02 13:48Z
historian  13     1        13    -       -        707070  acme/roster   contents:write, pull_requests:write  2026-10-02 14:04Z

14:04Z  historian  mint     contents:write, pull_requests:write on acme/roster, installation 4242, expires 15:04Z, for the execute, as historian[bot]
14:31Z  historian  run.end  ok, 23 turns, 1654s, https://github.com/acme/roster/pull/7

1 line names no seat: the runtime's own (the worker and the ingress starting and stopping, a reconcile)
showing the last 2 of 133 matching — `--limit 0` for all of them
```

`--agent`, `--action`, `--since 24h`, `--limit 0` and `--json` narrow it.
There is no way to write through this command: a ledger a hand can append to
from outside is not a ledger (ADR-22). The token itself is never in it — not
the audit line, not the log, not a file.

The **board** is the other question. `epito board` is "what have the seats
been doing": run reports, folded for whoever is reading, including reports
filed with `epito report` by seats running somewhere else entirely. The
ledger is "what exactly happened".

## The engine is optional

The manifest commands — `init`, `validate`, `deploy`, `token`, `board`,
`audit`, `report`, `note`, `routes` — need nothing but this package. They are the
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

Those four packages are the engine **client**. The engine itself is a
**server**, and it is a third thing: `temporal server start-dev` on a
laptop, or a self-hosted Temporal brought up before epitod on a runtime
host (docs/deploy/README.md). `epito run`, `epito worker` and `epito ps`
all refuse by name when it is not answering, and `epito validate <dir>`
tells you before you get there.

## Spec and source

The manifest is law and it is frozen at v0.1: four tables, a fixed field
catalogue, and a validator that is tested against the spec document itself
so the two cannot drift.

- Spec: [`spec/manifest.md`](https://github.com/alexandrapaiz/epitome/blob/main/spec/manifest.md)
- Source, decisions and design notes: <https://github.com/alexandrapaiz/epitome>

Requires Node >= 18.
