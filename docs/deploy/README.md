# Deploying epitod v0

`epito run <dir>` is one process. It needs four things on PATH: `node`
(>= 18), `git`, `gh`, and `claude` (the executor it spawns per run). It
reads secrets from its own environment and passes each run only the names
that run's `agent.toml` lists under `[runtime].env`. Everything it writes
goes under `.epito/` in its working directory:

```
.epito/audit.jsonl        one JSON line per event, append-only
.epito/state.json         the roster snapshot `epito ps` prints
.epito/logs/<agent>/*.log stdout+stderr of every run
```

Environment the daemon reads:

| name | meaning |
|---|---|
| `EPITO_HOOK_SECRET` | shared secret for every POST route (header `x-epito-secret`); the ingress answers 503 until set |
| `EPITO_PORT` | ingress port, default 4747 |
| `EPITO_WINDOW_MS` | how long a work window stays open, default 14400000 (4h) |
| `EPITO_EXECUTOR` | the binary spawned per run, default `claude`; `echo` is the stub for smoke tests |
| `EPITO_RUN_TIMEOUT_MS` | per-run cap, default 3600000 (60 min) |
| `CLAUDE_CODE_OAUTH_TOKEN` / `ANTHROPIC_API_KEY` | the executor's auth, only if a manifest lists it |
| `GH_TOKEN` | clone/push/`gh pr create` for now (bet 2 replaces it with a per-agent App token) |
| `SLACK_WEBHOOK_URL` | where the one-line post after each run goes, for agents that list it |

## The ingress

| route | what it does |
|---|---|
| `POST /hooks/<name>` | an event wakes the agent; the body is payload, never instructions |
| `POST /message/<name>` `{"text"}` | speaks to the agent inside the session its window holds; with no window open it falls back to a fresh run carrying the text |
| `POST /window/open` `{"scope"?, "text"?, "ttl_ms"?}` | opens a work window (4h default) on every agent in scope and fires each once with the synchronous instruction plus your agenda — this is the all-hands call |
| `POST /window/close` `{"scope"?}` | closes them; the held session id and its clone are discarded |
| `GET /healthz` | liveness, no secret |

`scope` is `"all"` (or absent) or a comma-separated list of `[agent].name`
values. Two thin CLI wrappers POST the same routes to the daemon this shell
can see, so nobody has to hand-write a curl with a secret in it:

```sh
epito window open all "Agenda: cycle 1 hill check."
epito message pm "which PR did you open?"
epito window close pm
```

## Presence: what a window actually holds

Between triggers an agent is nothing — a fresh clone, a fresh context. A
**window** is the exception, and it is deliberately small:

- opening one fires the agent once; the executor's `session_id` from that
  run is kept, along with **the clone it ran in** (the executor stores a
  conversation per project directory, so a resumed run must return to the
  same directory);
- `POST /message/<name>` continues that conversation with `--resume`;
- closing the window — by hand, by the 4h clock, or by the daemon stopping —
  discards the id and deletes the clone.

Nothing else survives. The PRs are the record (ADR-2); `epito ps` shows the
window's remaining time and the held session's first eight characters, and
`.epito/audit.jsonl` carries `window.open`, `window.refresh`, `window.close`,
`session.hold`, `session.lost` and `slack.post` lines.

The roster directory holds one folder per agent with an `agent.toml`
(see spec/manifest.md; `[runtime].repo` is required by `epito run`).

## Local (no deploy)

```sh
cd cli && npm ci && npm link            # puts `epito` on PATH
mkdir -p ~/epito/agents/smoke ~/epito/state
cp ../smoke/agent.toml ~/epito/agents/smoke/   # or write one
cd ~/epito/state
EPITO_HOOK_SECRET=$(openssl rand -hex 16) epito run ~/epito/agents
# in another shell, same directory:
epito ps
curl -s -X POST -H "x-epito-secret: $EPITO_HOOK_SECRET" localhost:4747/hooks/smoke
tail -f .epito/audit.jsonl
```

## Fly Machine (first cloud target)

Nothing here touches an account; run it yourself. The Dockerfile at the
repo root is the image; the roster is baked in by copying `agents/` next
to it or mounted from a volume.

```sh
# one time
fly launch --no-deploy --name epitod --dockerfile Dockerfile --internal-port 4747 --vm-size shared-cpu-1x
fly volumes create epito_state --size 1
fly secrets set EPITO_HOOK_SECRET=$(openssl rand -hex 16) CLAUDE_CODE_OAUTH_TOKEN=... GH_TOKEN=...
# fly.toml: add
#   [mounts]
#   source = "epito_state"
#   destination = "/var/lib/epito"
#   [[services]]  (or http_service) internal_port = 4747
# roster: COPY agents/ /agents in a one-line Dockerfile layer, or `fly ssh sftp` them onto the volume
fly deploy
fly logs
fly ssh console -C "epito ps"      # WorkingDirectory is /var/lib/epito, where state.json lives
curl -X POST -H "x-epito-secret: ..." https://epitod.fly.dev/hooks/<name>
```

## An always-on host, in one command (Ubuntu 24.04 arm64)

`deploy/provision-host.sh` provisions the whole box — the target is an
Oracle Cloud Always Free A1 instance, but nothing in it is Oracle-specific:

```sh
ssh ubuntu@host 'sudo bash -s' -- --domain epitod.example.com \
    --email ops@example.com --roster alexandra-systems/runtime < deploy/provision-host.sh
```

It installs Node 22, `gh`, `git` and the `claude` executor; creates the
unprivileged user `seats` and `/srv/asc/{repos,roster,state,env}`; writes
`epitod.service` (Restart=always, secrets from `/srv/asc/env` at 0600);
puts Caddy in front with TLS on 443 and no plaintext listener at all;
enables ufw (22/443) and fail2ban; and adds a daily `epito ps` posted to
Slack, which doubles as the keepalive an Always Free instance wants to see.
It is idempotent and it never overwrites a secret — re-run it to upgrade.
Optionally it drops an Infisical agent config that renders `/srv/asc/env`
and restarts epitod when a secret rotates.

`bash deploy/test-provision.sh` exercises it in a throwaway container with
the package managers and init system stubbed, and asserts on what it wrote.

## Any VPS (systemd user unit)

```sh
# on the box, as the user that will run agents
sudo apt install -y git gh nodejs npm      # node >= 18
npm install -g @anthropic-ai/claude-code
git clone https://github.com/alexandrapaiz/epitome && cd epitome/cli && npm ci && npm link
mkdir -p ~/epito/agents ~/epito/state ~/.config/systemd/user
cp ../docs/deploy/epitod.service ~/.config/systemd/user/
sudo install -d -m 0700 /etc/epito
sudo sh -c 'printf "EPITO_HOOK_SECRET=%s\nCLAUDE_CODE_OAUTH_TOKEN=...\nGH_TOKEN=...\n" "$(openssl rand -hex 16)" > /etc/epito/env' && sudo chmod 0600 /etc/epito/env
gh auth setup-git                          # git asks gh (which reads GH_TOKEN) for credentials
sudo loginctl enable-linger "$USER"        # user units survive logout
systemctl --user daemon-reload && systemctl --user enable --now epitod
journalctl --user -u epitod -f
(cd ~/epito/state && epito ps)
```

To expose hooks put a reverse proxy with TLS in front of 4747 (caddy:
`reverse_proxy localhost:4747`) or keep them on a private network; the
shared secret is the only auth in v0.

## Docker anywhere

```sh
docker build -t epitod .
docker run -d --name epitod --restart always -p 4747:4747 \
  -v "$PWD/agents:/agents:ro" -v epito_state:/var/lib/epito \
  -e EPITO_HOOK_SECRET=... -e CLAUDE_CODE_OAUTH_TOKEN=... -e GH_TOKEN=... epitod
docker exec epitod epito ps
```
