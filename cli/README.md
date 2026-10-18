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

Three other surfaces say the same thing from the same reader, so a box cannot
be described two ways:

```
$ epito run agents --dry-run
… 1 of 5 seats runs here short of a name its manifest asks this box to hold:
…   ! pm: BOARD_API_URL is not available to its runs; LINEAR_API_KEY arrives empty
…   a name this box does not hold is dropped from the run's environment and the
    seat runs without it: `epito env agents` is the whole report
```

said before it connects to the engine (the box most likely to be
half-provisioned is the one whose engine is not up yet), and said again by the
live `epito run` at startup so it lands in the journal. It reports and never
refuses, including for a name set to nothing: the real `epito run` injects that
empty value and runs the seat, and a rehearsal that refused what the thing it
rehearses accepts would be the wrong lie about a box.

The run's own log keeps its line (`# env missing: BOARD_RUNTIME_TOKEN is not
available to this run; LINEAR_API_KEY arrives empty`), and — the party that was
never told — the **agent** gets one line in the charter preamble naming what
this box did not have. Two names stay out of that line on purpose: a credential
the run minted for itself is not a name the box is short of, and a road's
`token_env` is a closed road, which the route lines in the same log already name
before the run takes the next road.

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
! identity   1 seat acts as its own GitHub App, 4 seats have no GitHub identity in their runs
✓ executor   /usr/local/bin/claude started under the environment a run gives it, for 5 seats
✗ engine     nothing is answering at 127.0.0.1:7233 (ECONNREFUSED)
! worker     not asked — nothing answered at 127.0.0.1:7233, so "is a worker polling seats" has no answer from here

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

The **worker** section is the only one that asks whether a run is *performed*
rather than accepted. Everything above it can be ✓ on a box where nothing ever
runs: accepting work and doing it are two processes (`epitod` registers the
schedules and serves the ingress, `epitod-worker` executes the seats), so a
dead worker leaves an engine that goes on taking schedules and starting runs
nothing picks up. The engine is asked directly — it knows who is polling —
which costs nothing and leaves this box no further than the engine:

```
✓ engine     127.0.0.1:7233 is Temporal, namespace "asc" exists (a real connect: the engine client is installed here)
✗ worker     nothing is polling seats — the engine accepts a schedule and starts a run, and no
             process picks the work up, so a run on this box is queued forever rather than
             refused. The engine still remembers a worker on this queue (1983@box, last polled
             4m ago), which it forgets about five minutes after one stops — so this one stopped
             rather than never started. Waiting on the queue right now: 2 tasks to decide what
             happens next, the oldest waiting for 6m.
```

Three things it will not get wrong. A poller is a **memory, not a socket** —
the engine keeps the last pollers it saw for about five minutes, so the ✓
prints how long ago the poll was and a record older than two minutes reads as
a worker that *stopped*, which is a different fix from one that was never
started. That age is printed in **seconds while it is inside the window and
minutes once it is outside**, so the unit alone says which side of the line a
record is on — a ✓ that reported `last polled 2m ago` would be a tick and its
own disproof in one sentence. A **workflow** task waiting more than a minute with a poller still
listed is the one state a poller count alone reports as ✓, and it exits 1: a
workflow task is a decision, dispatched in milliseconds wherever anything is
really polling, so a queue of them means a worker that is listed and wedged.
An **activity** backlog is the opposite — a seat run is a whole process and
the worker runs a few at a time (`EPITO_MAX_CONCURRENT_RUNS`), so runs waiting
for a slot are the runtime working as designed; that is reported, because "why
has my seat not started" deserves the answer, and it is never a refusal.
`--json` carries `worker.state` (`polled` / `stalled` / `half` / `none` /
`unasked`), the poller counts per half, and what is waiting. `unasked` is a
box that could not be asked, which is never the same as fine.

`epito ps` reads the same answer, because the lie it closes was ps's own: a
`RUNNING` count is a count of workflows that were *started*, which on a box
with no worker is not a count of anything running.

```
$ epito ps agents
epitod on 127.0.0.1:7233 namespace=asc queue=seats (no worker)
SEAT  CRON       NEXT              SCHEDULE  RUNNING         WINDOW  …
pm    0 12 * * 1 2026-10-13T12:00Z ok        1 (no worker)   -       …

✗ nothing is polling seats — … Fix: start one: `epito worker` on this box, or
  `systemctl start epitod-worker` on a host provisioned by deploy/provision-host.sh …
  The one seat with a NEXT time above will not run at it either: the engine will start
  the run and nothing will pick it up.
```

The **identity** section answers the other question a box decides: not whether
a run would start but whose name its pull request would open under. It reads
the run path's own credential lookup, so it cannot predict a seat the runtime
would not run, and it has five answers:

```
identity, per answer
  ✓ its own GitHub App: id 1234567, from $EPITO_APP_ID_PM/$EPITO_APP_KEY_FILE_PM — covers pm
  ✗ half an identity, which the runtime reads as none: $EPITO_APP_ID_OKR is set
    here and neither $EPITO_APP_KEY_FILE_OKR nor $EPITO_APP_KEY_OKR is — an App
    id alone signs nothing — covers okr
  ! nobody: no App on this box, and [runtime].env names neither GH_TOKEN nor
    GITHUB_TOKEN, so a run's child gets no GitHub credential at all — covers
    engineer, exo, market
```

`half` and an App whose mint could not start — an unreadable key file, a PEM
that is not one, a key that is not RSA, a scope this spec cannot mint, an App
with no `[runtime].repo` to scope a token to — exit 1, for the reason a road
this box *has* and has wrong exits 1: the box holds this one and holds it
wrong, and a seat that silently falls back to a human's credential is the one
outcome the operator who set those names did not ask for. The App check is free
and offline: it signs a throwaway JWT, which is the mint's own first step, and
it reaches no network.

And the one thing that check cannot reach, because an App installed nowhere
mints nothing however valid its key: whether GitHub *has* that App on the
repository the seat would mint for. That answer is a network call — the mint's
own next step — so it rides `--deep`, the flag that already means "leave this
box", and unlike the one-turn probe beside it, it costs nothing: two `GET`s
per App — the installation on `[runtime].repo`, and `/app`, which is who that
App is — no token minted, no ledger line, however many seats share it.

```
✓ installed  1 App asked at GitHub for 2 seats, every one installed on the repository it would mint for

installed, per App
  ✓ its own GitHub App, installed on acme/box as installation 4242, which is
    the id its runs discover from [runtime].repo, since nothing on this box
    names one, and granted there everything its [identity].scopes ask to mint
    — covers pm, okr
      Its pull requests there open as asc-pm[bot], which is this App's own
      login: usually the seat's name, and whatever GitHub actually gave the
      App when it was created.
```

That last line is the second thing `/app` buys, and it is the only place this
product can tell the truth about it. An App name is unique across the whole of
GitHub, so a seat called `pm` whose plain name was taken is the App `asc-pm`
and opens its pull requests as `asc-pm[bot]` — every other sentence here says
`<name>[bot]`, which is the usual case and not a promise anything can keep.
`--json` carries it as `seats[].identity.installed.login`, null where GitHub
was not asked or did not answer, never a guess.

The first thing it buys is a page. A refusal in this product names a fix, and
the two fixes here that are not a file to edit or a name to set are *install
this App* and *grant it this permission* — both of them a page on GitHub that
the operator otherwise goes and finds:

```
  ✗ an App this box cannot mint with: this agent's GitHub App is not installed
    on acme/box — an App with no installation there can mint nothing, however
    valid its key. Fix: install the App on acme/box (its owner does this
    once), then mint again. — covers pm, okr
      The page that does it: https://github.com/apps/asc-pm/installations/new
```

The page is where it is, not where github.com would be: a box pointed at a
GitHub Enterprise host by `$EPITO_GITHUB_API` gets its own host's pages, since
its App does not exist on github.com at all. And a permission is granted under
whoever *owns* the App, which is why `/app` is read for its owner and not only
its slug — an org-owned App is not reachable under `/settings/apps` at all.
Neither link is offered when there is nothing to build one from: GitHub
answering 401 means the App id and the key are not from the same App, and those
same credentials cannot read `/app` either, so that refusal stays the sentence
it was.

Four of its five answers exit 1 — an App installed nowhere, an installation id
*this box* names that GitHub does not have (the mint uses the id the box names
rather than discovering one, so GitHub refuses it), a grant short of what
`[identity].scopes` map to (an installation can only hand out permissions the
App was granted, which the mint learns as a 422), and credentials GitHub
rejects outright — three of the four now carry the page that fixes them. The
fifth is a report: a GitHub this box could not reach is
the kind of mint failure that *passes*, and the run path retries it. That line
is not redrawn here — `src/lib/identity.js` marks a mint failure `permanent`
or not, because the clone activity retries, and the preflight reads that flag
rather than deciding by status code.

`nobody` and `the owner of $GH_TOKEN` are reports, not refusals. They are how
every seat ran before the identity leg existed, and `epito env <roster>` prints
the same block under the names a manifest *does* declare — those two variables
are derived from `[agent].name` rather than named by any manifest, which is
why no command saw them before.

## What it gives an agent

- **Identity** — its own GitHub App, created from `[identity].scopes` and
  never wider than the file. Short-lived tokens minted per run, an
  append-only audit line for each, the private key at `0600` on your
  machine and never in the repo. Its pull requests open as the App's own
  login — usually `<name>[bot]`, and `epito doctor <roster> --deep` reads the
  real one — not as you. `epito audit` reads that record back.
- **Trigger** — `[trigger].cron` becomes a real schedule; `webhook = true`
  lets the ingress wake it. A trigger is explicit and never defaulted: a
  seat that did not ask to be woken by the ingress is not woken by it.
- **Runtime** — a process that outlives the machine it started on, on
  self-hosted Temporal. A reboot mid-run no longer loses the run.

It runs the agent you already have: `[runtime].adapter = "langgraph"` runs
a LangGraph app through the `langgraph.json` its author already wrote,
unmodified — nothing added to its repository, nothing imported from epito.

## The same manifest, on Cloudflare

A box is one place an agent can live. `epito deploy <name> --target cloudflare`
packs the same file — unchanged, no new field — as a Worker that **is** the
agent:

```
$ epito deploy historian agents/historian --target cloudflare
historian is packed for Cloudflare — 4 files in .epito/cloudflare/historian:

  Worker:   epito-historian
  schedule: 0 6 * * * (UTC), from [trigger].cron
  state:    one Durable Object, addressed by "historian" — a redeploy keeps its runs
  page:     GET / — the agent, its last run, and a button that triggers it
  key:      .epito/keys/historian.pkcs8.pem — the PKCS#8 copy of this agent's
            App key (0600); the Workers runtime reads no other form

the part that is yours, not epito's — it spends your Cloudflare account:

  cd .epito/cloudflare/historian
  npx wrangler deploy
  wrangler secret put EPITO_TRIGGER_SECRET   # the one door
  ...
```

The Worker signs its own JWT as the agent's own App and mints its own
installation token, scoped to exactly what `[identity].scopes` maps to on
exactly the repository `[runtime].repo` names — the same ceiling, enforced in
the same place, on a runtime with no filesystem. It reads its charter out of
that repository on every run, so an edge seat is never running a stale copy
of itself.

Two things to know before you reach for it. An **edge run is one turn**: it
mints, reads the charter, asks the model once and records the answer; it does
not clone, commit or open a pull request, because a Worker has no git and no
disk — and the page says so on every run rather than letting it read as the
full seat. And on a box the last road in a route chain is your Claude
subscription, which a Worker cannot hold, so the floor on the edge is
`$ANTHROPIC_API_KEY`.

`wrangler deploy` is the one command epito does not run for you. It spends
your Cloudflare account, the same reason creating a GitHub App is your click
and not a tool's.

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
