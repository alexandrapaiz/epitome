# Deploying epitod v1

epitod v1 is **two processes and one engine** (the design:
docs/prfaq/epitod-v1-temporal.md).

| Process | What it does | systemd |
|---|---|---|
| `epito run <roster>` | makes Temporal's schedules match the roster, then serves the ingress as a thin client | `epitod.service` |
| `epito worker` | polls the `seats` task queue and does the work: clone, execute, record, notify | `epitod-worker.service` |
| Temporal server + UI | the engine. Self-hosted, `temporalio/auto-setup` on `127.0.0.1:7233` and `temporalio/ui` on `127.0.0.1:8080`, on the host's Postgres | docker, via HQ `runtime/temporal/install.sh` |

Two units and not one, deliberately: reloading the roster must not interrupt a
seat that is mid-run, and with the worker in its own unit it does not.
`systemctl reload epitod` is safe at any time.

Both epitod processes need four things on PATH: `node` (>= 18), `git`, `gh`,
and `claude` (the executor the `execute` activity spawns). Everything the
product writes goes under `.epito/` in the working directory, which **both
processes must share** so there is one ledger:

```
.epito/audit.jsonl        one JSON line per event, append-only
.epito/board.jsonl        run reports, folded by `epito board`
.epito/logs/<agent>/*.log stdout+stderr of every run
```

Read the ledger with `epito audit`, in that directory — what each agent's
token was allowed to do, on which repository, until when, and every run and
refused road beside it. `--agent`, `--action mint`, `--since 24h` and `--json`
narrow it; there is no way to write through the command (ADR-22). On the host
that means:

```bash
cd /srv/asc/state && epito audit --since 24h
```

There is no `.epito/state.json` any more. `epito ps` asks Temporal, because
a second copy of what is running is a second copy that can be wrong.

## Environment

| name | default | meaning |
|---|---|---|
| `TEMPORAL_ADDRESS` | `127.0.0.1:7233` | the engine's gRPC endpoint |
| `TEMPORAL_NAMESPACE` | `default` | the namespace; the company host sets `asc` |
| `EPITO_TASK_QUEUE` | `seats` | the queue the worker polls and the schedules target |
| `EPITO_HOOK_SECRET` | — | shared secret for every POST route (header `x-epito-secret`); the ingress answers 503 until set |
| `EPITO_PORT` | `4747` | ingress port |
| `EPITO_WINDOW_MS` | `14400000` | how long a work window stays open (4h) |
| `EPITO_RUN_TIMEOUT_MS` | `3600000` | per-run cap: the `execute` activity's timeout and the workflow's run timeout |
| `EPITO_MAX_CONCURRENT_RUNS` | `4` | how many seat runs one worker will hold at once |
| `EPITO_EXECUTOR` | `claude` | the binary the `execute` activity spawns **for a claude seat** |
| `EPITO_PYTHON` | `python3` | the interpreter a **langgraph** seat runs in — the one with that agent's own dependencies installed (a venv path is normal) |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | — | where run traces go, e.g. `http://127.0.0.1:6006` for a Phoenix on the box. Unset = no tracing, and no complaint about it |
| `OTEL_EXPORTER_OTLP_TRACES_ENDPOINT` | — | the full URL instead, when it is not `<base>/v1/traces` |
| `OTEL_EXPORTER_OTLP_HEADERS` | — | `k=v,k2=v2` auth for a hosted backend. **Never given to a run** — list it in `[runtime].env` if a seat's own agent must export too |
| `CLAUDE_CODE_OAUTH_TOKEN` / `ANTHROPIC_API_KEY` | — | the executor's auth, only if a manifest lists it |
| `GH_TOKEN` | — | the roster-wide credential: the worker clones with it, and a seat that has no App of its own pushes and opens PRs with it |
| `EPITO_APP_ID_<NAME>` | — | one agent's own GitHub App, so its PRs open as `<name>[bot]` — see below |
| `EPITO_APP_KEY_FILE_<NAME>` | — | path to that App's `.pem` (0600). Preferred: an `EnvironmentFile` has no multi-line values |
| `EPITO_APP_KEY_<NAME>` | — | the PEM inline instead, newlines written `\n` |
| `EPITO_INSTALLATION_ID_<NAME>` | — | optional: skip the installation lookup when you already know the id |
| `EPITO_GITHUB_API` | `https://api.github.com` | where tokens are minted; for GitHub Enterprise, and for the smoke test's local stub |
| `SLACK_WEBHOOK_URL` | — | the default webhook, which is `#hq` |
| `SLACK_WEBHOOK_URL_<PRODUCT>` | — | a per-seat webhook, named by that seat's `[runtime].slack_webhook_env` |
| *(a route's key)* | — | the key named by a seat's `[[runtime.route]].token_env`, e.g. `MOONSHOT_API_KEY`. Its presence is what opens that road on this box; absent means the road is skipped and the run takes the next one |

Only the **worker** needs the secret values. Temporal persists every workflow
argument in plain text, so the manifests carry secret *names* and the worker's
own environment carries the values. Both units still read the same
`EnvironmentFile` on the company host, because one file is easier to rotate
than two, but nothing in the design requires the ingress to hold a token.

## Giving an agent its own identity

Without this, every seat on the box clones and pushes with the same
`GH_TOKEN`, and every PR is opened by whoever owns it. With it, a seat is a
principal: it clones as itself, its commits are authored by its own bot user,
its PR opens as `<name>[bot]`, and its reach is exactly `[identity].scopes` on
exactly `[runtime].repo`, for one hour at a time.

Once per agent, by hand — the one-click creation flow is `epito deploy`, which
is not built yet:

1. GitHub → Settings → Developer settings → GitHub Apps → **New GitHub App**.
   Name it for the agent; App names are globally unique on GitHub, so expect
   to add a suffix.
2. Give it the repository permissions the agent's scopes map to. `epito token
   <name> --dry-run` prints exactly that list and asks GitHub nothing. Nothing
   more than that list: the App's own permissions are the outer ceiling, and
   the manifest can only narrow them.
3. **Install** it on the agent's `[runtime].repo` alone (Only select
   repositories). An App installed nowhere mints nothing, however valid its
   key — and the mint says exactly that if you skip this.
4. Generate a private key. GitHub downloads the `.pem` once.
5. Put the id and the key on the box, in the same `EnvironmentFile` the units
   already read:

```sh
install -m 600 -o seats -g seats ~/Downloads/pm.2026-09-26.private-key.pem /srv/asc/keys/pm.pem
printf 'EPITO_APP_ID_PM=1234567\nEPITO_APP_KEY_FILE_PM=/srv/asc/keys/pm.pem\n' >> /srv/asc/env
systemctl restart epitod-worker        # the WORKER mints; the ingress never sees a key
```

`<NAME>` is `[agent].name` upper-cased with `-` as `_`: the agent
`daily-builder` reads `EPITO_APP_ID_DAILY_BUILDER`. Then prove it before a
schedule depends on it:

```sh
epito token pm /srv/asc/agents --dry-run   # the mapping only: no network, no key
epito token pm /srv/asc/agents             # the real mint; the token is stdout, alone
```

Three rules the runtime keeps, each asserted in `cli/test/smoke-temporal.sh`:

- **Per run, never stored.** A run mints its own tokens and forgets them. They
  reach the run as `GH_TOKEN`/`GITHUB_TOKEN` in the child's environment, and
  git gets one through an inline credential helper reading an environment
  variable — never an argument, because `/proc/<pid>/cmdline` is world-
  readable, and never `.git/config`, because that outlives the run. They are
  written nowhere else: not the run log (which scrubs them, because `gh` and
  `git` both echo what they were handed), and not Temporal — an activity that
  *returned* a token would be an activity that filed it in the engine's
  database in plain text. `.epito/audit.jsonl` records every mint — agent,
  scopes, permissions, installation, expiry, and which half of the run asked —
  and never the token.

  **Two mints per fresh run**, and that is the design rather than an
  oversight. The same rule that keeps a token out of the engine's database
  keeps it from travelling between the `clone` activity and the `execute`
  activity, so each asks for its own; `phase` in the audit line says which.
  A run that resumes a held window borrows that window's clone and mints once.
- **The minted token wins.** If `[runtime].env` also names `GH_TOKEN`, the
  agent's own credential is used instead, and the run log says so by name.
- **No silent fallback.** An agent with no App runs on the shared `GH_TOKEN`
  exactly as it did before — clone included. An agent that *has* one and
  cannot mint stops, and the run is recorded `exit=mint` with the reason. A PR
  opened by the wrong identity is worse than a PR not opened.

### What the box's own `GH_TOKEN` is still for

`provision-host.sh` installs a system-wide credential helper —
`credential.https://github.com.helper = !gh auth git-credential` — and `gh`
answers it with the `GH_TOKEN` in `/srv/asc/env`. A seat that has an App no
longer uses it: for that seat's clone the helper list is **reset** for the one
`git` invocation, so the box's credential cannot win by having been configured
first, and the agent's own token is the only one git can offer.

It is still needed for two things, so do not delete it yet:

- **provisioning itself** — `provision-host.sh` clones the roster and the seat
  repos before any agent exists to mint for them;
- **every seat that has no App.** Give all of them one and the line becomes
  dead weight; until then it is the fallback, honestly.

### The commits inside the PR

An installation token opens the PR as `<name>[bot]` and does nothing at all
for the commits inside it: GitHub links a commit to an account by the author's
email and by nothing else. So the mint also reads the App's slug (`GET /app`,
as the App) and its bot user's numeric id (`GET /users/<slug>[bot]`, as the
installation) and the run commits as

```
<bot user id>+<slug>[bot]@users.noreply.github.com
```

which is the address that links. `epito token <name>` prints it on stderr in
the form you would paste, for scripting a `gh pr create` by hand.

This one degrades rather than refuses. If GitHub will not describe the App,
the run says so and falls back to `<name>@agents.epito.me` — an address that
belongs to no account. "No silent fallback" is a rule about acting as the
wrong *principal*; an unlinked commit is still the agent, only less legibly,
and losing a whole run over an avatar is the wrong trade. The audit line
records `commit: null` in that case rather than a guess.

## A seat that is not a Claude session

`[runtime].adapter` says which kind of agent a seat is (ADR-17, spec v0.1
in-band). Two exist:

| adapter | what the runtime spawns | holds a session |
|---|---|---|
| `claude` (default) | `claude -p <prompt> --permission-mode bypassPermissions --model … --output-format json` | yes — windows and `POST /message` continue a conversation |
| `langgraph` | `$EPITO_PYTHON cli/adapters/langgraph_run.py`, in the clone | no — a follow-up message runs the seat again with the message as its prompt |

A langgraph seat's manifest is an ordinary manifest with two more fields:

```toml
[runtime]
model = "claude-sonnet-5"        # still required: what the agent's own nodes call
entry = "prompts/researcher.md"  # still the charter, and the graph is handed its path
repo = "acme/researcher"
adapter = "langgraph"
graph = "agent"                  # which graph in the app's own langgraph.json
env = ["OPENAI_API_KEY"]         # whatever the agent's own code reads, by NAME
```

**Nothing is added to the agent's repository.** epito reads the
`langgraph.json` LangGraph authors already write — `{"graphs": {"agent":
"./src/agent.py:graph"}}` — imports the object it names (a compiled graph, a
`StateGraph`, or a factory returning either), and streams it once. What the
graph receives:

| variable | what it is |
|---|---|
| `EPITO_PROMPT` | the run's prompt, handed to the graph as `{"messages": [{"role": "user", "content": …}]}` |
| `EPITO_AGENT` / `EPITO_RUN_ID` / `EPITO_TRIGGER` | the seat, the run, and how it was woken |
| `EPITO_CHARTER` | `[runtime].entry`, a path inside the clone the graph may read |
| `EPITO_MODEL` / `EPITO_MAX_TURNS` | the manifest's model, and the graph's recursion limit |
| `GH_TOKEN` / `GITHUB_TOKEN` | the credential **minted for this run**, if the seat has an App — so a graph's own tool calls act as `<name>[bot]` with no epito import |
| `TRACEPARENT` / `OTEL_*` | the run's trace, so the graph's steps appear inside it |

What the shim prints back is the result contract every adapter speaks — one
JSON object, `{"session_id", "num_turns", "result", "detail"}` — and its exit
code says who failed: **0** ran, **2** the adapter refused before the graph
started (no `langgraph.json`, an ambiguous `[runtime].graph`, an import that
raised), **3** the graph itself raised. Both non-zero cases put the sentence
explaining them on the board, not only in the log.

The interpreter is the box's business, not the manifest's. Install the agent's
own dependencies wherever you like and point `EPITO_PYTHON` at it:

```sh
python3 -m venv /srv/asc/venvs/researcher
/srv/asc/venvs/researcher/bin/pip install -e /srv/asc/agents/researcher   # the agent's own deps
# in the EnvironmentFile:
EPITO_PYTHON=/srv/asc/venvs/researcher/bin/python
```

One caveat worth knowing before you migrate a seat: `EPITO_PYTHON` is
per-worker, not per-seat, so two langgraph seats with incompatible dependency
sets need two workers today (`EPITO_TASK_QUEUE` differs, and each manifest's
schedule targets the queue its worker polls). One interpreter per box is
enough until it isn't.

## Which model a seat actually runs on

A seat can declare more than one road to a model (ADR-19):

```toml
[runtime]
model = "claude-sonnet-5"
env = ["CLAUDE_CODE_OAUTH_TOKEN", "MOONSHOT_API_KEY"]

[[runtime.route]]
name = "open"
model = "kimi-k2-turbo-preview"
base_url = "https://api.moonshot.ai/anthropic"
token_env = "MOONSHOT_API_KEY"
concurrency = 1

[[runtime.route]]
name = "subscription"
model = "claude-sonnet-5"
```

The runtime tries them in order and the run takes the first road that starts
it. This is the open-routing pattern every HQ workflow hand-wires — the open
provider first, the subscription behind it — done once, in the runtime, for
every seat.

**On this box, not in the manifest.** `MOONSHOT_API_KEY` has to be in the
worker's environment for the `open` road to be open here. It is not, on a
laptop? Then that road is skipped, the run goes to `subscription`, and the run
log says which and why. That is the point: one roster, many boxes.

```
$ epito routes /srv/asc/runtime/agents
pm (claude) — takes open
  → open: kimi-k2-turbo-preview at https://api.moonshot.ai/anthropic [key $MOONSHOT_API_KEY], 1 at a time
    subscription: claude-sonnet-5 on this machine's own executor login
okr (claude) — takes subscription
  ✗ open: kimi-k2-turbo-preview at https://api.moonshot.ai/anthropic [key $MOONSHOT_API_KEY] — closed: MOONSHOT_API_KEY is not set on this machine
  → subscription: claude-sonnet-5 on this machine's own executor login
```

It exits non-zero when a seat has no open road at all, so it is worth a line in
a deploy check. It prints no key, ever — only names.

**What a fallback costs, and what it may not do.** The next road is taken only
when the attempt opened no PR and reached at most one turn: a run that never
started. A run that failed at turn nine keeps its failure — the runtime never
starts a half-finished run somewhere else. `concurrency` serializes this
worker's runs on one road, which is what a prepaid tier allowing one request at
a time needs; two worker hosts are two counters.

**Reading it back.** `route.refused` and `route.taken` lines in
`.epito/audit.jsonl`, one span per road under the run's `execute`, and the
board's `model` column is the model that *ran*:

```
$ epito board --agent pm --limit 3
18:56  pm  cron  ok  kimi-k2-turbo-preview  1 turn  https://github.com/…/pull/41
```

## Seeing inside a run

Set `OTEL_EXPORTER_OTLP_ENDPOINT` and every run files a trace (ADR-18). One
trace per run, and its shape is the run:

```
run <agent>                      the whole run: trigger, model, adapter, outcome, PR
├ clone                          the repository, at the ref
│ └ mint                         installation, permissions, expiry — never the token
└ execute                        the agent itself: adapter, turns, PR, session held, route
  ├ mint                         the run's own credential (law 7: two mints, one per activity)
  ├ route <name>                 one per road tried: its model, and whether it refused
  └ …                            whatever the AGENT emits: for a langgraph seat, its
                                 graph and one span per node
```

Phoenix takes OTLP on `http://127.0.0.1:6006` by default, so on the company
host that is the whole configuration:

```sh
# in the EnvironmentFile both units read
OTEL_EXPORTER_OTLP_ENDPOINT=http://127.0.0.1:6006
```

`epito worker` says on its first lines where its spans go, or that they go
nowhere, so "is this box traced" is a thing to read rather than infer:

```
epito worker: traces -> http://127.0.0.1:6006/v1/traces
epito worker: traces off (set OTEL_EXPORTER_OTLP_ENDPOINT to see inside a run)
```

Three properties worth knowing:

- **Tracing can never fail a run.** A refused endpoint is one log line. The run
  is recorded in `.epito/audit.jsonl` and on the board either way.
- **A span never carries a credential.** Whole payloads go through the same
  scrubber the run logs use, because a trace backend is a store you cannot
  delete from later.
- **An agent's spans are the agent's.** epito hands the child `TRACEPARENT` and
  the endpoint and nothing else; anything already instrumented (openinference,
  LangSmith's OTel exporter) nests under `execute` with no epito import. It is
  NOT handed `OTEL_EXPORTER_OTLP_HEADERS`: on every hosted backend that value is
  an api key, and a run sees only the secrets its manifest names.

## The ingress

| route | what it does |
|---|---|
| `POST /hooks/<name>` | an event wakes the agent: starts `SeatRun`, or delivers a `followUp` to the run already going |
| `POST /message/<name>` `{"text"}` | speaks to the agent inside the session its window holds; with no window open it falls back to a fresh run carrying the text, and says so |
| `POST /window/open` `{"scope"?, "text"?, "ttl_ms"?}` | starts `SeatWindow` on every agent in scope and fires each once with the synchronous instruction plus your agenda — this is the all-hands call. A window already open has its deadline moved |
| `POST /window/close` `{"scope"?}` | signals the window closed; the held session and its clone are discarded |
| `POST /board` | a seat files a run report (or a note) on the board. Not gated by the roster: a seat running somewhere else entirely has a report to file too |
| `GET /board` | the board back out — JSON, or `?format=text` for the table. `?agent=`, `?kind=`, `?limit=` narrow it |
| `GET /healthz` | liveness, no secret. It answers 503 when the **engine** is unreachable, because an ingress that says 200 while Temporal is down is a health check that lies |

`scope` is `"all"` (or absent) or a comma-separated list of `[agent].name`
values. Two thin CLI wrappers POST the same routes to the ingress this shell
can see, so nobody has to hand-write a curl with a secret in it:

```sh
epito window open all "Agenda: cycle 2 hill check."
epito message pm "which PR did you open?"
epito window close pm
```

## The board

Every run a seat makes on this runtime files its own report, from the same
activity that writes the audit line. `epito board` reads it — no engine, no
secret, just the file:

```sh
cd /srv/asc/state && epito board            # the last 20, and a row per seat
epito board --agent pm --limit 50
epito board --kind note --json
```

```
the board — 6 seats, 12 entries since 2026-09-27 02:00Z

SEAT    RUNS  FAILED  NOTES  LAST               OUTCOME          TURNS  LAST PR
badkey  1     1       -      2026-09-27 02:00Z  mint             -      -
clock   1     -       -      2026-09-27 02:00Z  ok               1      …/pull/999
ghost   1     1       -      2026-09-27 02:00Z  charter-missing  -      -
market  1     -       -      2026-09-27 02:00Z  ok               9      …/pull/1000
```

The store is `.epito/board.jsonl` in the runtime's working directory — the
same directory as `audit.jsonl`, and for the same reasons (ADR-16). Two files
because they answer two questions: the audit log is the forensic record, the
board is what the owner reads.

### A seat that does not run on epitod

Most seats in this company are still GitHub Actions jobs. They belong on the
same board — a board that only knows the migrated seats is useless for exactly
as long as the migration takes. One line at the end of a seat's job files its
report over the ingress:

```sh
epito report "$SEAT" --trigger cron --outcome ok \
  --turns "$TURNS" --seconds "$SECONDS" --pr "$PR_URL"
```

It needs `EPITO_HOST` (e.g. `https://epito.example`) and `EPITO_HOOK_SECRET`
in the job's environment, and nothing else — no engine, no Temporal, no
checkout of this repo beyond the CLI. `epito note <name> "..."` puts a line on
the board that is not a run.

**Adding that line to `.github/workflows/agent-*.yml` is the owner's to make:**
the engineer seat never edits workflows, so this ships as the command and the
two variable names, not as a committed workflow change.

### Why a field you invent is refused

The board has one shape, and `POST /board` answers 400 to a field that is not
in it, naming the field and the shape that exists. That is the owner's "seats
cannot create views" — a board that grows a column whenever a seat wants one
is a board that means something different depending on which seat wrote to it
last. Widening it is a change to `KINDS` in `cli/src/lib/board.js`, in a PR,
with a reason.

## Schedules: what `epito run` actually does

```sh
epito run /srv/asc/roster --dry-run     # print the schedule changes and stop
epito run /srv/asc/roster               # reconcile, then serve the ingress
systemctl reload epitod                 # SIGHUP: re-read the roster, reconcile again
```

The desired state is a pure function of the roster, so this is idempotent:

- a manifest with `[trigger].cron` gets one schedule, id `seat:<name>`, the
  expression in **UTC**, overlap policy `BUFFER_ONE` (a fire arriving while the
  seat is still running is coalesced into a single follow-up, never dropped and
  never stacked);
- a manifest **without** `[trigger].cron` gets no schedule. A presence-only
  roster starts quiet on purpose;
- a seat that loses its cron, or leaves the roster, loses its schedule;
- a schedule whose id is not `seat:<name>` is left alone. It was not registered
  by epito, so it is not epito's to delete.

Every create, update and delete is a line in `audit.jsonl` as well as a change
on the engine. The schedule's payload is the **manifest snapshot**, which is
why changing a seat's model or entry is an update rather than a no-op, and why
it is safe to persist: a manifest is publishable by design.

Because `seat:<name>` is an ordinary Temporal schedule, the stock tools operate
it:

```sh
temporal schedule describe --schedule-id seat:engineer
temporal schedule toggle   --schedule-id seat:engineer --pause --reason "cooldown"
temporal schedule trigger  --schedule-id seat:engineer     # fire it now, by hand
```

## Presence: what a window actually holds

Between triggers an agent is nothing — a fresh clone, a fresh context. A
**window** is the exception, and in v1 it is a workflow rather than a `Map` in
somebody's memory:

- `SeatWindow` opens, fires the seat once as a child `SeatRun`, and holds two
  things from that run: the executor's `session_id` and **the clone it ran in**
  (the executor stores a conversation per project directory, so a resumed run
  must return to the same directory);
- a `message` signal runs another child `SeatRun` with `--resume` in that same
  clone;
- `close`, the TTL timer, or a terminated workflow all end the same way: the
  clone is deleted and a `window.close` line is appended. The `cleanup`
  activity runs non-cancellable, so this happens even on the way out.

Nothing else survives. The PRs are the record (ADR-2). `epito ps` shows the
window's remaining time and the held session's first eight characters by
**querying the window workflow**, which is the thing that knows.

One worker host, in v1: a window holds a filesystem path, so the child run
must land on the host that made the clone. A second host needs host-pinned task
queues.

## Local, with no host at all

```sh
# the engine
temporal server start-dev --namespace epito            # 127.0.0.1:7233, UI on 8233

# the runtime
cd cli && npm ci && npm link                           # puts `epito` on PATH
mkdir -p ~/epito/agents/smoke ~/epito/state
cd ~/epito/state
export TEMPORAL_ADDRESS=127.0.0.1:7233 TEMPORAL_NAMESPACE=epito
export EPITO_HOOK_SECRET=$(openssl rand -hex 16)
epito worker &                                         # one shell
epito run ~/epito/agents                               # another
epito ps ~/epito/agents                                # a third
```

## An always-on host, in one command (Ubuntu 24.04 arm64)

Install the engine first, then the runtime. `deploy/provision-host.sh`
provisions everything except the engine — the target is an Oracle Cloud Always
Free A1 instance, but nothing in it is Oracle-specific:

```sh
# 1. the engine (HQ's script; docker, loopback only, on the host's Postgres)
ssh ubuntu@host 'sudo bash -s' < runtime/temporal/install.sh     # alexandra-systems

# 2. the runtime
ssh ubuntu@host 'sudo bash -s' -- --domain epitod.example.com \
    --email ops@example.com --roster alexandrapaiz/alexandra-systems \
    --roster-subdir runtime/agents < deploy/provision-host.sh

# 3. start the worker first, the ingress second
ssh ubuntu@host 'sudo systemctl restart epitod-worker && sudo systemctl restart epitod'
ssh ubuntu@host 'journalctl -u epitod-worker -u epitod -f'
```

It installs Node 22, `gh`, `git` and the `claude` executor; creates the
unprivileged user `seats` and `/srv/asc/{repos,roster,state,env}`; writes both
units (`Restart=always`, secrets from `/srv/asc/env` at 0600, `TEMPORAL_ADDRESS`
and `TEMPORAL_NAMESPACE` among them); puts Caddy in front with TLS on 443 and
no plaintext listener at all; enables ufw (22/443) and fail2ban; and adds a
daily `epito ps` posted to Slack, which doubles as the keepalive an Always Free
instance wants to see. It is idempotent and it never overwrites a secret.

`bash deploy/test-provision.sh` exercises it in a throwaway container with the
package managers and init system stubbed, and asserts on what it wrote.

The Temporal UI is on `127.0.0.1:8080` and stays there. Workflow history shows
prompts, so reach it over a tunnel and never publish it:

```sh
ssh -L 8080:127.0.0.1:8080 ubuntu@host     # then open localhost:8080
```

## Docker anywhere

One image, run twice. Both containers need the same state volume so there is
one audit log, and both need to reach the engine.

```sh
docker build -t epitod .
docker run -d --name epitod-worker --restart always --network host \
  -v epito_state:/var/lib/epito \
  -e TEMPORAL_ADDRESS=127.0.0.1:7233 -e TEMPORAL_NAMESPACE=asc \
  -e CLAUDE_CODE_OAUTH_TOKEN=... -e GH_TOKEN=... epitod worker
docker run -d --name epitod --restart always --network host \
  -v "$PWD/agents:/agents:ro" -v epito_state:/var/lib/epito \
  -e TEMPORAL_ADDRESS=127.0.0.1:7233 -e TEMPORAL_NAMESPACE=asc \
  -e EPITO_HOOK_SECRET=... epitod run /agents
docker exec epitod epito ps
```

## Testing what you deployed

```sh
cd cli
node --test test/unit.mjs              # the reconcile diff and the validator, no server
bash test/smoke-temporal.sh            # the whole runtime against a local dev server
bash test/smoke-langgraph.sh           # the langgraph adapter, against the real framework
```

The smoke tests spend no tokens and touch no network: the executor is a stub,
`github.com` is rewritten to a local bare repo, Slack is two local sinks, and
the trace backend is `test/otlp-sink.mjs`. `smoke-temporal.sh` proves a schedule
fires a run on its own clock, a window holds a session and a message resumes it
in the same clone, `epito ps` reads Temporal, a run mints its own identity,
every run lands on the board, a LangGraph seat runs beside the claude ones, and
each run files one trace. Without the `temporal` CLI installed it exits 0 after
saying so — that is an unrun test, not a passing one.

`smoke-langgraph.sh` is the adapter on its own, including every refusal it can
produce. It runs against real LangGraph when the interpreter has it:

```sh
python3 -m venv /tmp/lgvenv && /tmp/lgvenv/bin/pip install langgraph
EPITO_PYTHON=/tmp/lgvenv/bin/python bash test/smoke-langgraph.sh
```

Without it, the framework half skips loudly and the duck-typed half still runs
— the adapter imports nothing from the agent's language, so most of it can be
proved with no framework installed at all.
