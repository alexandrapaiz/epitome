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
| `EPITO_HOOK_SECRET` | shared secret for `POST /hooks/<name>` (header `x-epito-secret`); hooks answer 503 until set |
| `EPITO_PORT` | hook server port, default 4747 |
| `EPITO_EXECUTOR` | the binary spawned per run, default `claude`; `echo` is the stub for smoke tests |
| `EPITO_RUN_TIMEOUT_MS` | per-run cap, default 3600000 (60 min) |
| `CLAUDE_CODE_OAUTH_TOKEN` / `ANTHROPIC_API_KEY` | the executor's auth, only if a manifest lists it |
| `GH_TOKEN` | clone/push/`gh pr create` for now (bet 2 replaces it with a per-agent App token) |

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
