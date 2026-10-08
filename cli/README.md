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
epito validate         # check it against manifest spec v0.2
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

That is a note, not an error: the file is a valid v0.2 manifest and the
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

## What this box owes the roster

A manifest names the secrets a seat sees — `[runtime].env`, plus a road's
`token_env` and `base_url_env` — and never their values (spec rule 1). The
runtime injects the ones the box it is running on actually holds, which is
what makes one roster portable across boxes, and is silent: a seat short of
a name runs, exits 0, and quietly does less.

`epito env` is that question, per box, the way `epito routes` is the same
question about which model each seat reaches:

```
$ epito env agents
roster agents — 6 names the manifests ask this box to hold, and it holds 1

✓ SLACK_WEBHOOK_URL    held here — engineer, exo, market, okr, pm (the one-line post after every run)
— BOARD_API_URL        not set here — pm
— BOARD_RUNTIME_TOKEN  not set here — pm
— LINEAR_API_KEY       not set here — pm
— OPENROUTE_API_KEY    not set here — market, okr, pm (the key for route "open")
— OPENROUTE_BASE_URL   not set here — market, okr, pm (the endpoint for route "open")

! pm runs here with 1 of 6 names: BOARD_API_URL, BOARD_RUNTIME_TOKEN, … are not available to its runs
```

Exit 0: nothing in a manifest says which of those names a seat cannot work
without, so this reports and does not guess. `--complete` is where you assert
that this box should hold all of them, for a deploy check; `--template` prints
the env file those names belong in, one commented `KEY=` per name, and comments
out the ones already set so pasting it cannot blank a working value. A name
that *is* set and set to nothing exits 1 either way — the box has that one and
has it wrong.

It reads the environment for presence and prints no value, ever.

## Would a run on this box start?

Four of this CLI's commands each answer a quarter of that: `epito validate
<dir>` reads the manifests, `epito routes` says which model road each seat
takes here, `epito env` says which names this box holds, and `validate
--for-runtime` adds a look at the engine. None of them touches the executable
epito spawns — which is what ended the runtime's first real run on a real host
at turn zero with `Not logged in`, because the environment a run hands its
child is an allowlist (`PATH`, `HOME`, `USER`, plus `[runtime].env`) and the
executor's credential lookup needed a name the allowlist did not carry.

`epito doctor` is the preflight, with one contract: **exit 1 if a run on this
box would refuse, and name the piece.**

```
$ epito doctor agents
roster agents on this box — 5 seats, checked in the order a run needs them

✓ manifests  5 of 5 manifests load and pass spec v0.2
! names      6 names asked for, 2 held, 4 not set here
✗ roads      1 seat has no open road here (market)
✓ executor   /usr/local/bin/claude started under the environment a run gives it, for 5 seats
✗ engine     nothing is answering at 127.0.0.1:7233 (ECONNREFUSED)

epito: a run on this box would refuse — 2 reasons:
  ✗ no open road on this box — market
  ✗ no engine: nothing is answering at 127.0.0.1:7233 (ECONNREFUSED). Fix: …
```

The executor section is the one that is new, and it is the only one that spawns
anything: it resolves the binary on the PATH a **run** gets and starts it under
the environment a **run** gives it. It is free, offline and instant — and for
exactly that reason it proves the file starts and nothing about the account
behind it, which it says rather than implies. `--deep` is the half that proves
credentials: one real turn per *road* (five seats sharing one key cost one
call), with the executor's own refusal read back verbatim. It costs a model
call, which is why it is a flag.

A name this box does not hold at all is a report and exits 0; a name it holds
and holds empty exits 1. That is the same split `epito env` makes, for the same
reason — nothing in a manifest says which names a seat cannot work without.

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
`audit`, `report`, `note`, `routes`, `env` — need nothing but this package. They are the
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

The manifest is law. v0.1 froze it — four tables, a fixed field catalogue,
and a validator that is tested against the spec document itself so the two
cannot drift — and v0.2 opened with exactly one optional field, so every
manifest that validated before validates now.

- Spec: [`spec/manifest.md`](https://github.com/alexandrapaiz/epitome/blob/main/spec/manifest.md)
- Source, decisions and design notes: <https://github.com/alexandrapaiz/epitome>

Requires Node >= 18.
