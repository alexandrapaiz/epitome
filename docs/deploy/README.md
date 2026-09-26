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
.epito/logs/<agent>/*.log stdout+stderr of every run
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
| `EPITO_EXECUTOR` | `claude` | the binary the `execute` activity spawns |
| `CLAUDE_CODE_OAUTH_TOKEN` / `ANTHROPIC_API_KEY` | — | the executor's auth, only if a manifest lists it |
| `GH_TOKEN` | — | the roster-wide credential: the worker clones with it, and a seat that has no App of its own pushes and opens PRs with it |
| `EPITO_APP_ID_<NAME>` | — | one agent's own GitHub App, so its PRs open as `<name>[bot]` — see below |
| `EPITO_APP_KEY_FILE_<NAME>` | — | path to that App's `.pem` (0600). Preferred: an `EnvironmentFile` has no multi-line values |
| `EPITO_APP_KEY_<NAME>` | — | the PEM inline instead, newlines written `\n` |
| `EPITO_INSTALLATION_ID_<NAME>` | — | optional: skip the installation lookup when you already know the id |
| `EPITO_GITHUB_API` | `https://api.github.com` | where tokens are minted; for GitHub Enterprise, and for the smoke test's local stub |
| `SLACK_WEBHOOK_URL` | — | the default webhook, which is `#hq` |
| `SLACK_WEBHOOK_URL_<PRODUCT>` | — | a per-seat webhook, named by that seat's `[runtime].slack_webhook_env` |

Only the **worker** needs the secret values. Temporal persists every workflow
argument in plain text, so the manifests carry secret *names* and the worker's
own environment carries the values. Both units still read the same
`EnvironmentFile` on the company host, because one file is easier to rotate
than two, but nothing in the design requires the ingress to hold a token.

## Giving an agent its own identity

Without this, every seat on the box pushes with the same `GH_TOKEN` and every
PR is opened by whoever owns it. With it, a seat is a principal: its PR opens
as `<name>[bot]`, and its reach is exactly `[identity].scopes` on exactly
`[runtime].repo`, for one hour at a time.

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

- **Per run, never stored.** Each run mints its own token inside the `execute`
  activity and forgets it. It reaches the run as `GH_TOKEN`/`GITHUB_TOKEN` in
  the child's environment and is written nowhere: not the clone, not the run
  log (which scrubs it, because `gh` echoes what it was handed), and not
  Temporal — an activity that *returned* a token would be an activity that
  filed it in the engine's database in plain text. `.epito/audit.jsonl` records
  every mint — agent, scopes, permissions, installation, expiry — and never
  the token.
- **The minted token wins.** If `[runtime].env` also names `GH_TOKEN`, the
  agent's own credential is used instead, and the run log says so by name.
- **No silent fallback.** An agent with no App runs on the shared `GH_TOKEN`
  exactly as it did before. An agent that *has* one and cannot mint stops, and
  the run is recorded `exit=mint` with the reason. A PR opened by the wrong
  identity is worse than a PR not opened.

The commits inside those PRs are a separate question and are **not** solved
here: the git author is still `<name>@agents.epito.me`, which GitHub cannot
link to the App without the bot user's own id. See `docs/ideas.md`.

## The ingress

| route | what it does |
|---|---|
| `POST /hooks/<name>` | an event wakes the agent: starts `SeatRun`, or delivers a `followUp` to the run already going |
| `POST /message/<name>` `{"text"}` | speaks to the agent inside the session its window holds; with no window open it falls back to a fresh run carrying the text, and says so |
| `POST /window/open` `{"scope"?, "text"?, "ttl_ms"?}` | starts `SeatWindow` on every agent in scope and fires each once with the synchronous instruction plus your agenda — this is the all-hands call. A window already open has its deadline moved |
| `POST /window/close` `{"scope"?}` | signals the window closed; the held session and its clone are discarded |
| `GET /healthz` | liveness, no secret. It answers 503 when the **engine** is unreachable, because an ingress that says 200 while Temporal is down is a health check that lies |

`scope` is `"all"` (or absent) or a comma-separated list of `[agent].name`
values. Two thin CLI wrappers POST the same routes to the ingress this shell
can see, so nobody has to hand-write a curl with a secret in it:

```sh
epito window open all "Agenda: cycle 2 hill check."
epito message pm "which PR did you open?"
epito window close pm
```

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
```

The smoke test spends no tokens and touches no network: the executor is a stub,
`github.com` is rewritten to a local bare repo, and Slack is two local sinks.
It proves a schedule fires a run on its own clock, a window holds a session and
a message resumes it in the same clone, and `epito ps` reads Temporal. Without
the `temporal` CLI installed it exits 0 after saying so — that is an unrun
test, not a passing one.
