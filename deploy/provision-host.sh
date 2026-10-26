#!/usr/bin/env bash
# Provision one always-on host for epitod — the runtime that holds agents
# between triggers (epitod v1, docs/prfaq/epitod-v1-temporal.md).
#
# epitod v1 runs on Temporal, self-hosted. This script does NOT install the
# Temporal server, and nothing in this repository does yet: the engine is a
# server, it is installed separately, and docs/deploy/README.md ("Temporal
# server + UI") is where the two ways to get one are written down. Bring it up
# first, or run this and fill in TEMPORAL_ADDRESS afterwards -- the units below
# wait for a server they can reach and say so when they cannot.
#
# Target: Ubuntu 24.04 LTS, arm64, an Oracle Cloud Always Free A1 instance
# (4 OCPU / 24 GB is the free ceiling; epitod is idle between runs and the
# executor is the only thing that ever gets busy). Nothing here is Oracle-
# specific: any Ubuntu 24.04 box with a public address works, which is the
# point — ADR-6 forbids depending on one provider.
#
# Run it over SSH, as many times as you like; every step checks before it
# acts and no step overwrites a secret:
#
#   ssh ubuntu@host 'sudo bash -s' -- --domain epitod.example.com \
#       --email ops@example.com --roster alexandrapaiz/alexandra-systems --roster-subdir runtime/agents < deploy/provision-host.sh
#
# What you get:
#   user seats           the unprivileged principal every agent run is
#   /srv/asc/repos       epito's source and the roster repo
#   /srv/asc/roster      -> the directory of agent.toml files epitod hosts
#   /srv/asc/state       epitod's working dir: .epito/{audit.jsonl,board.jsonl,logs}
#   /srv/asc/env         the runtime's secrets, 0600 seats:seats
#   epitod.service       reconcile the roster onto Temporal + serve the ingress
#   epitod-worker.service  the process that actually runs seats (task queue
#                        `seats`); separate so reloading the roster cannot
#                        interrupt a seat that is mid-run
#   Caddy                TLS in front of 127.0.0.1:4747 (the ingress has one
#                        shared secret; TLS is what keeps it off the wire)
#   ufw 22/443, fail2ban
#   epitod-health.timer  daily `epito ps` posted to Slack: health and keepalive
set -euo pipefail

DOMAIN=""; EMAIL=""; ROSTER_REPO=""; ROSTER_SUBDIR=""
EPITO_REPO="${EPITO_REPO:-alexandrapaiz/epitome}"; EPITO_REF=""
SEATS_USER="seats"; BASE="/srv/asc"; PORT="4747"; SKIP_CADDY=0; TASK_QUEUE="seats"

usage() {
  sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'
  cat <<USAGE

Options:
  --domain <fqdn>      hostname Caddy serves the ingress on (TLS via ACME)
  --email <addr>       ACME account email for certificate notices
  --roster <owner/rp>  repository of agent manifests to clone into $BASE/repos
  --roster-subdir <d>  directory inside that repo holding the agent.toml files
  --epito-repo <o/r>   epito source (default: $EPITO_REPO)
  --epito-ref <ref>    branch or tag of the epito source to install
  --user <name>        the unprivileged seat user (default: $SEATS_USER)
  --port <n>           epitod's local port behind Caddy (default: $PORT)
  --no-caddy           skip Caddy; the ingress stays on localhost only
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    --domain) DOMAIN="$2"; shift 2;;
    --email) EMAIL="$2"; shift 2;;
    --roster) ROSTER_REPO="$2"; shift 2;;
    --roster-subdir) ROSTER_SUBDIR="$2"; shift 2;;
    --epito-repo) EPITO_REPO="$2"; shift 2;;
    --epito-ref) EPITO_REF="$2"; shift 2;;
    --user) SEATS_USER="$2"; shift 2;;
    --port) PORT="$2"; shift 2;;
    --no-caddy) SKIP_CADDY=1; shift;;
    -h|--help) usage; exit 0;;
    *) echo "provision-host: unknown option \"$1\" — run with --help for the list" >&2; exit 2;;
  esac
done

[ "$(id -u)" = 0 ] || { echo "provision-host: run me as root (ssh host 'sudo bash -s' < this file)" >&2; exit 1; }
. /etc/os-release 2>/dev/null || true
[ "${ID:-}" = ubuntu ] || echo "provision-host: this is written for Ubuntu 24.04; ${ID:-unknown} ${VERSION_ID:-} may need adjusting" >&2
if [ "$SKIP_CADDY" = 0 ] && [ -z "$DOMAIN" ]; then
  echo "provision-host: --domain is required to put TLS in front of the ingress (or pass --no-caddy to keep it on localhost)" >&2; exit 2
fi

say() { printf '\n== %s\n' "$*"; }

# Add a third-party apt repository, keyring first. A failed download stops the
# script by name: half a repository is worse than none.
add_apt_repo() { # <name> <key-url> <list-line>
  local name="$1" key="$2" line="$3" ring="/etc/apt/keyrings/$1.gpg"
  install -d -m 0755 /etc/apt/keyrings
  if ! curl -fsSL "$key" | gpg --dearmor -o "$ring.tmp"; then
    echo "provision-host: could not fetch the $name signing key from $key — this host needs outbound https before it can install $name" >&2
    rm -f "$ring.tmp"; exit 1
  fi
  mv "$ring.tmp" "$ring"; chmod a+r "$ring"
  echo "$line" | sed "s|^deb |deb [signed-by=$ring] |" > "/etc/apt/sources.list.d/$name.list"
  apt-get update -qq
}
export DEBIAN_FRONTEND=noninteractive

say "packages: git, curl, ufw, fail2ban, jq"
apt-get update -qq
apt-get install -y -qq git curl ca-certificates gnupg ufw fail2ban jq >/dev/null

say "node 22 (NodeSource, arm64)"
if ! command -v node >/dev/null || [ "$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo 0)" -lt 22 ]; then
  add_apt_repo nodesource https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key "deb https://deb.nodesource.com/node_22.x nodistro main"
  apt-get install -y -qq nodejs >/dev/null
fi
echo "  node $(node -v), npm $(npm -v)"

say "gh (GitHub CLI)"
if ! command -v gh >/dev/null; then
  add_apt_repo github-cli https://cli.github.com/packages/githubcli-archive-keyring.gpg "deb https://cli.github.com/packages stable main"
  apt-get install -y -qq gh >/dev/null
fi
echo "  $(gh --version | head -1)"

say "the executor: @anthropic-ai/claude-code"
npm install -g --silent @anthropic-ai/claude-code >/dev/null
echo "  claude $(claude --version 2>/dev/null || echo '(installed)')"

say "user $SEATS_USER and $BASE"
id -u "$SEATS_USER" >/dev/null 2>&1 || useradd --system --create-home --home-dir "/home/$SEATS_USER" --shell /usr/sbin/nologin "$SEATS_USER"
install -d -m 0755 -o "$SEATS_USER" -g "$SEATS_USER" "$BASE" "$BASE/repos" "$BASE/state"
install -d -m 0700 -o "$SEATS_USER" -g "$SEATS_USER" "$BASE/home"
# Where a per-agent GitHub App private key goes. 0700, so a .pem dropped here
# is unreadable by anyone but the runtime even if its own mode is wrong.
install -d -m 0700 -o "$SEATS_USER" -g "$SEATS_USER" "$BASE/keys"
# HOME for the daemon and every run is $BASE/home, not /home/$SEATS_USER: the
# claude executor writes its config and held sessions under HOME, and the unit
# below mounts /home read-only (ProtectHome) while $BASE is the only writable path.
# Runs clone into a private /tmp (see epitod.service, PrivateTmp=yes).

say "secrets: $BASE/env"
if [ -f "$BASE/env" ]; then
  echo "  $BASE/env exists — left untouched (this script never overwrites a secret)"
else
  umask 077
  cat > "$BASE/env" <<ENV
# epitod's environment. 0600 $SEATS_USER:$SEATS_USER. One KEY=value per line,
# no quotes, no export. Everything an agent may see must ALSO be named in that
# agent's [runtime].env — the manifest names it, this file holds it.
EPITO_HOOK_SECRET=$(openssl rand -hex 24)
EPITO_PORT=$PORT
# The engine. Self-hosted Temporal on loopback, installed separately -- see
# docs/deploy/README.md ("Temporal server + UI"). Never Temporal Cloud.
TEMPORAL_ADDRESS=127.0.0.1:7233
TEMPORAL_NAMESPACE=asc
EPITO_TASK_QUEUE=seats
CLAUDE_CODE_OAUTH_TOKEN=replace-me
GH_TOKEN=replace-me
# The default webhook, which is #hq, and also what the daily health post below
# uses. A seat that wants its own channel names a different variable in
# [runtime].slack_webhook_env and it is added here.
SLACK_WEBHOOK_URL=replace-me
#
# THE SEATS' OWN NAMES ARE NOT LISTED HERE, on purpose. They are in the
# manifests -- [runtime].env, plus a route's token_env and base_url_env -- and
# this file used to carry a hand-copied subset of them, which had already
# drifted: three names agents/pm/agent.toml asks for (BOARD_API_URL,
# BOARD_RUNTIME_TOKEN, LINEAR_API_KEY) were never in here, so that seat would
# have run on this box, green, and filed nothing to the board. The runtime
# injects only the names the box holds, so a missing one is silent by design.
# The list is generated from the roster now, and the step after the roster
# clone prints it for this box:
#
#   epito env $BASE/roster             every name the roster asks for, and
#                                      which of them this box holds
#   epito env $BASE/roster --template  the same names as lines for THIS file,
#                                      commented, values blank
# Per-agent identity (optional; docs/deploy/README.md, "Giving an agent its own
# identity"). Two lines per agent, its [agent].name uppercased with - as _.
# When they are here, every run of that agent mints its own short-lived tokens
# -- one for the clone, one for the run -- clones and pushes as itself, commits
# as its own bot user, and opens its PRs as <name>[bot] instead of as
# GH_TOKEN's owner; when they are not, nothing changes. A key is a .pem at $BASE/keys/<agent>.pem, 0600, seats-
# owned -- an EnvironmentFile has no multi-line values, which is exactly the
# problem the FILE form exists to avoid.
#   EPITO_APP_ID_PM=123456
#   EPITO_APP_KEY_FILE_PM=$BASE/keys/pm.pem
ENV
  chown "$SEATS_USER:$SEATS_USER" "$BASE/env"; chmod 0600 "$BASE/env"
  umask 022
  echo "  wrote $BASE/env with a fresh EPITO_HOOK_SECRET; fill in the three replace-me lines"
  echo "  the SEATS' names are not in it yet: \`epito env $BASE/roster --template\` prints them from the roster (the step below says which are missing)"
  echo "  $BASE/keys/ is where a per-agent GitHub App .pem goes (0600); no agent needs one to run"
  echo "  TEMPORAL_ADDRESS=127.0.0.1:7233 TEMPORAL_NAMESPACE=asc assumed: change them if the engine is elsewhere"
fi

# The env file is NOT a shell script, and the box learned that the expensive
# way: this company's resident host ran for eighteen hours with its daily
# health post dead, because one value in $BASE/env was a password hash, a hash
# begins with `$`, and the health script read the file with `set -a; . file`.
# systemd reads an EnvironmentFile literally -- so epitod itself was fine the
# whole time -- while a shell sourcing the same bytes expands `$2b` to nothing,
# splits a value with a space and runs the tail of it as a command, and will
# happily run a `` ` `` or a `$(...)` that arrives inside a secret. Three
# different wrongs, all silent, from a file every unit on the box reads.
#
# So the box gets a reader that has systemd's semantics instead of the shell's,
# installed as a file rather than copied into each caller: this script, the
# generated health script, and anything an operator writes next all read the
# file one way. `cli/src/lib/envfile.js` is the same parse in the product, and
# `epito env --file` is how you ask whether a file on a box is safe to read
# this way -- the suite cross-checks the two against one fixture so they cannot
# drift apart.
#
# What it implements, from systemd.exec(5): KEY=value per line, leading
# whitespace ignored, `#` and `;` comments ignored, one layer of matching
# quotes stripped (the form HQ's own `requote` leaves behind), and NO
# expansion of anything. What it deliberately does not: the trailing-backslash
# continuation, because `epito env --template` never writes one and a value
# that needs one cannot live in this file anyway.
say "the env-file reader every script on this box shares"
install -d -m 0755 /usr/local/lib
cat > /usr/local/lib/epito-envfile.sh <<'ENVLIB'
#!/usr/bin/env bash
# systemd EnvironmentFile semantics, in a shell. Installed by
# deploy/provision-host.sh; the same parse lives in cli/src/lib/envfile.js.
#
# NEVER source an EnvironmentFile with `.` or `source`: a value starting with
# `$`, or holding a space, a backtick or a `$(...)`, reaches the shell as code
# or as the wrong value, and nothing says so. Use these two instead:
#
#   . /usr/local/lib/epito-envfile.sh
#   load_env_file /srv/asc/env                  # export every name in it
#   v="$(env_file_value /srv/asc/env GH_TOKEN)" # just one, no exports
#
# Both are pure parameter expansion: no eval, no subshell interpreting the
# value, so a value is only ever data here.

# One line -> name and value, with systemd's rules. Prints nothing; sets
# __ENVFILE_NAME and __ENVFILE_VALUE, and returns 1 for a line that is not an
# assignment (blank, comment, or a name a shell could not hold anyway).
__envfile_parse_line() {
  local line="$1" name value
  line="${line#"${line%%[![:space:]]*}"}"
  case "$line" in ''|'#'*|';'*) return 1;; esac
  case "$line" in *=*) ;; *) return 1;; esac
  name="${line%%=*}"
  value="${line#*=}"
  case "$name" in ''|[0-9]*|*[!A-Za-z0-9_]*) return 1;; esac
  case "$value" in
    '"'*'"') value="${value#\"}"; value="${value%\"}";;
    "'"*"'") value="${value#\'}"; value="${value%\'}";;
  esac
  __ENVFILE_NAME="$name"; __ENVFILE_VALUE="$value"
}

# Export every name an EnvironmentFile holds, the way the units get them.
load_env_file() { # <path>
  local line
  if [ ! -r "${1:-}" ]; then
    echo "epito-envfile: cannot read ${1:-<no path given>} — load_env_file takes the path of an env file this box holds (the one the units name in EnvironmentFile=). Fix: pass that path, or create the file first." >&2
    return 1
  fi
  while IFS= read -r line || [ -n "$line" ]; do
    __envfile_parse_line "$line" || continue
    export "$__ENVFILE_NAME=$__ENVFILE_VALUE"
  done < "$1"
  unset __ENVFILE_NAME __ENVFILE_VALUE
}

# One value on stdout, exported nowhere. Last assignment wins, which is what
# systemd does with a name written twice. Empty output for a name the file does
# not hold AND for a name it holds as empty -- the caller that needs those two
# apart should ask `epito env --file <path>`, which says which it is by name.
env_file_value() { # <path> <name>
  local line found=""
  [ -r "${1:-}" ] || return 1
  while IFS= read -r line || [ -n "$line" ]; do
    __envfile_parse_line "$line" || continue
    [ "$__ENVFILE_NAME" = "${2:-}" ] && found="$__ENVFILE_VALUE"
  done < "$1"
  unset __ENVFILE_NAME __ENVFILE_VALUE
  printf '%s' "$found"
}
ENVLIB
chmod 0644 /usr/local/lib/epito-envfile.sh
# shellcheck source=/dev/null
. /usr/local/lib/epito-envfile.sh
echo "  /usr/local/lib/epito-envfile.sh — load_env_file and env_file_value, systemd's rules not the shell's"

# git asks gh, and gh reads GH_TOKEN from the environment. This is the box's
# shared credential and it is the FALLBACK, not the default: a seat that has a
# GitHub App below clones on its own minted token, with this helper list reset
# for that one `git` invocation so the shared credential cannot win by having
# been configured first (cli/src/lib/runner.js, gitEnvFor). It is still needed
# for the clones this script makes, and for every seat that has no App yet.
# --system, not --global: the service runs with HOME=$BASE/home, so a per-user
# gitconfig under /home/$SEATS_USER would never be read.
git config --system credential."https://github.com".helper '!gh auth git-credential'
git config --system --replace-all safe.directory "*" || true
# The clones below are of private repositories: they need GH_TOKEN from
# $BASE/env. It is read here, handed to the seat user's git through the
# environment only (never an argument, never printed), and the run stops by
# name if it is still the placeholder.
# Read with the shared reader, not `sed`: a `sed -n 's/^GH_TOKEN=//p'` keeps
# whatever quoting the line has, so the moment anyone quotes that file -- which
# is exactly what HQ's own `tools/host.sh requote` does to make the file safe
# for the shells that were sourcing it -- every clone below authenticates with
# a token that has two extra bytes on it and fails as "bad credentials".
GH_TOKEN="$(env_file_value "$BASE/env" GH_TOKEN)"
[ "$GH_TOKEN" = replace-me ] && GH_TOKEN=""
[ -n "$GH_TOKEN" ] || echo "  (no GH_TOKEN in $BASE/env yet: a private repository will refuse to clone below, and this script will say so)"
export GH_TOKEN GIT_TERMINAL_PROMPT=0
sgit() { sudo -u "$SEATS_USER" --preserve-env=GH_TOKEN,GIT_TERMINAL_PROMPT git "$@"; }
need_token() { echo "provision-host: cloning $1 failed — it is private and GH_TOKEN in $BASE/env is not set. Put the seats' GitHub token there (one line, GH_TOKEN=..., file 0600) and run me again; everything above is already done." >&2; exit 1; }

say "epito from $EPITO_REPO"
EPITO_SRC="$BASE/repos/epitome"
if [ -d "$EPITO_SRC/.git" ]; then
  sgit -C "$EPITO_SRC" fetch --quiet --depth 1 origin "${EPITO_REF:-HEAD}"
  sgit -C "$EPITO_SRC" checkout --quiet FETCH_HEAD
else
  sgit clone --quiet --depth 1 ${EPITO_REF:+--branch "$EPITO_REF"} "https://github.com/$EPITO_REPO.git" "$EPITO_SRC" || need_token "$EPITO_REPO"
fi
(cd "$EPITO_SRC/cli" && npm ci --silent --omit=dev >/dev/null && npm install -g --silent . >/dev/null)
echo "  $(command -v epito) installed"

# The engine, by name, because the CLI no longer brings it. cli/package.json
# declares @temporalio/* as OPTIONAL peer dependencies so that `npm i -g epito-cli`
# is half a megabyte instead of ~300 MB for the people who only write
# manifests — which means the `npm ci --omit=dev` above installs everything
# EXCEPT the one thing this host exists to run. `epito run` and `epito worker`
# are this box's entire job; without these four they start, print the
# install line, and exit 1.
#
# This list and cli/package.json's peerDependencies are one list, kept so by
# a unit assertion ("the runtime box installs every engine peer") rather than
# by anyone remembering to edit both.
ENGINE_PKGS="@temporalio/client@^1.24.0 @temporalio/worker@^1.24.0 @temporalio/activity@^1.24.0 @temporalio/workflow@^1.24.0"
# shellcheck disable=SC2086 -- the list is this script's own literal, split on purpose
npm install -g --silent $ENGINE_PKGS >/dev/null
echo "  engine: @temporalio/{client,worker,activity,workflow}"

say "roster"
ROSTER_DIR="$BASE/roster"
if [ -n "$ROSTER_REPO" ]; then
  RDIR="$BASE/repos/$(basename "$ROSTER_REPO")"
  if [ -d "$RDIR/.git" ]; then sgit -C "$RDIR" pull --quiet --ff-only
  else sgit clone --quiet --depth 1 "https://github.com/$ROSTER_REPO.git" "$RDIR" || need_token "$ROSTER_REPO"; fi
  ln -sfn "$RDIR${ROSTER_SUBDIR:+/$ROSTER_SUBDIR}" "$ROSTER_DIR"
  echo "  $ROSTER_DIR -> $RDIR${ROSTER_SUBDIR:+/$ROSTER_SUBDIR}"
else
  install -d -m 0755 -o "$SEATS_USER" -g "$SEATS_USER" "$ROSTER_DIR"
  echo "  $ROSTER_DIR (empty — put one directory per agent, each with an agent.toml, in it)"
fi
unset GH_TOKEN

# What the ROSTER asks of this box, read from the manifests this box is holding
# rather than from a list written in this script. The two used to be separate
# lists and they drifted (see $BASE/env above): the runtime injects only the
# names the box has, so a seat short of one runs, exits 0, and quietly does
# less -- no refusal anywhere, because nothing in a manifest says which names a
# seat cannot work without.
#
# Run with $BASE/env loaded, in a subshell, because the question is what the
# UNITS will hold, not what this provisioning shell holds. `epito env` reads
# the environment for presence and prints no value, ever -- names only, which
# is the whole reason it is safe to run here and paste the output anywhere.
# Not through sudo: this reads manifests and writes nothing, and sudo's
# secure_path would drop the environment the question is about.
#
# Never fatal: a half-filled env line is worth a sentence on the screen, not an
# aborted provision of a box that is otherwise finished. `set -e` is on.
say "what this roster asks of this box"
if [ -n "$(find -L "$ROSTER_DIR/" -name agent.toml -print -quit 2>/dev/null)" ]; then
  ( load_env_file "$BASE/env"; epito env "$ROSTER_DIR" ) || true
  # And the file itself, read the way the units read it: which of its lines a
  # shell would have read differently. This is the check that would have caught
  # the eighteen-hour outage above on the day the hash was written, not a day
  # and a half later.
  epito env --file "$BASE/env" || true
  echo "  add any name above that this box should hold to $BASE/env, then: systemctl restart epitod-worker epitod"
  echo "  \`epito env $ROSTER_DIR --template\` prints those lines ready to paste (it comments out the names already set, so pasting cannot blank one)"
else
  echo "  no agent.toml under $ROSTER_DIR yet -- run \`epito env $ROSTER_DIR\` once the roster is in place"
fi

say "infisical agent (optional: it renders $BASE/env for you)"
if ! command -v infisical >/dev/null; then
  curl -fsSL https://artifacts-us-east-1.infisical.com/infisical-cli/setup.deb.sh | bash >/dev/null 2>&1 || echo "  (infisical repo unreachable; skipping — $BASE/env by hand still works)"
  apt-get install -y -qq infisical >/dev/null 2>&1 || true
fi
if command -v infisical >/dev/null && [ ! -f /etc/infisical-agent.yaml ]; then
  cat > /etc/infisical-agent.yaml <<'YAML'
# Fill in projectId and environment, then:
#   printf '%s' '<machine-identity-client-id>' > /etc/infisical-client-id
#   printf '%s' '<machine-identity-client-secret>' > /etc/infisical-client-secret
#   chmod 0600 /etc/infisical-client-*; systemctl enable --now infisical-agent
# The agent re-renders /srv/asc/env and restarts epitod when a secret rotates.
infisical:
  address: "https://app.infisical.com"
auth:
  type: "universal-auth"
  config:
    client-id: "/etc/infisical-client-id"
    client-secret: "/etc/infisical-client-secret"
    remove_client_secret_on_read: false
sinks:
  - type: "file"
    config:
      path: "/etc/infisical-agent-token"
templates:
  - base64-template-content: ""
    source-path: /etc/infisical-env.tpl
    destination-path: /srv/asc/env
    config:
      polling-interval: 300s
      execute:
        command: systemctl restart epitod
YAML
  cat > /etc/infisical-env.tpl <<'TPL'
{{- with secret "PROJECT_ID" "prod" "/" }}
{{- range . }}
{{ .Key }}={{ .Value }}
{{- end }}
{{- end }}
TPL
  chmod 0600 /etc/infisical-agent.yaml /etc/infisical-env.tpl
  cat > /etc/systemd/system/infisical-agent.service <<UNIT
[Unit]
Description=Infisical agent - renders /srv/asc/env for epitod
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/bin/infisical agent --config /etc/infisical-agent.yaml
Restart=always
RestartSec=10
UMask=0077

[Install]
WantedBy=multi-user.target
UNIT
  echo "  wrote /etc/infisical-agent.yaml (not enabled: it needs a project id and a machine identity)"
else
  echo "  already configured or unavailable — skipping"
fi

say "epitod-worker.service (the process that runs seats)"
cat > /etc/systemd/system/epitod-worker.service <<UNIT
# epitod v1 worker. Polls the \`$TASK_QUEUE\` task queue on Temporal and runs the
# activities: clone the seat's repository, spawn the executor in it, append the
# audit line, post the Slack line. This is the ONLY process that sees a secret
# value: Temporal persists every workflow argument in plain text, so the
# manifests carry secret NAMES and this unit's environment carries the values.
[Unit]
Description=epitod v1 worker - runs seats off the Temporal task queue
After=network-online.target docker.service
Wants=network-online.target

[Service]
Type=simple
User=$SEATS_USER
Group=$SEATS_USER
WorkingDirectory=$BASE/state
EnvironmentFile=$BASE/env
Environment=HOME=$BASE/home
Environment=EPITO_TASK_QUEUE=$TASK_QUEUE
ExecStart=/usr/bin/env epito worker
Restart=always
RestartSec=5
# Runs write clones under \$TMPDIR; give the unit its own so cleanup is local.
# This isolates the unit from the rest of the box and not the seats from each
# other — every window here is one user in one private /tmp — so each window
# also owns a scratch directory beside its clone, and a run's own \$TMPDIR
# points there (src/lib/runner.js). Without that second layer a file one run
# named itself was readable and writable by every other run in this unit.
PrivateTmp=yes
NoNewPrivileges=yes
ProtectSystem=full
ProtectHome=read-only
ReadWritePaths=$BASE
# A seat run is minutes to an hour, and \`epito worker\` drains on SIGTERM: it
# stops taking new work and lets what is in flight finish.
KillMode=mixed
TimeoutStopSec=300

[Install]
WantedBy=multi-user.target
UNIT

say "epitod.service (reconcile the roster, then serve the ingress)"
cat > /etc/systemd/system/epitod.service <<UNIT
# epitod v1: reconcile + ingress. It makes Temporal's schedules match the
# roster (one schedule per [trigger].cron, id seat:<name>) and serves the
# ingress. It does NOT execute seats — epitod-worker.service does, and the
# split is the point: \`systemctl reload epitod\` picks up a roster change
# without interrupting a seat that is mid-run.
[Unit]
Description=epitod v1 - reconcile the roster onto Temporal, and serve the ingress
After=network-online.target docker.service epitod-worker.service
Wants=network-online.target

[Service]
Type=simple
User=$SEATS_USER
Group=$SEATS_USER
WorkingDirectory=$BASE/state
EnvironmentFile=$BASE/env
Environment=EPITO_PORT=$PORT
Environment=HOME=$BASE/home
ExecStart=/usr/bin/env epito run $ROSTER_DIR
# SIGHUP re-reads the roster and reconciles, without dropping the ingress.
ExecReload=/bin/kill -HUP \$MAINPID
Restart=always
RestartSec=5
PrivateTmp=yes
NoNewPrivileges=yes
ProtectSystem=full
ProtectHome=read-only
ReadWritePaths=$BASE
KillMode=mixed
TimeoutStopSec=30

[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload
systemctl enable --quiet epitod-worker
systemctl enable --quiet epitod
echo "  both enabled (start them once $BASE/env is filled in and Temporal is up:"
echo "   systemctl restart epitod-worker epitod)"

say "daily health: epito ps to Slack (also the keepalive Oracle wants to see)"
cat > /usr/local/bin/epitod-health <<HEALTH
#!/usr/bin/env bash
# One post a day: is epitod alive, and what does its roster look like. Also
# the traffic that keeps an Always Free instance from being reclaimed as idle.
set -uo pipefail
# NOT \`set -a; . $BASE/env\`, which is what this line was and what killed this
# unit for eighteen hours: the file is a systemd EnvironmentFile, one of its
# values was a password hash, and a hash begins with a dollar sign. This reader
# has systemd's rules (/usr/local/lib/epito-envfile.sh).
. /usr/local/lib/epito-envfile.sh
load_env_file $BASE/env
state="\$(cd $BASE/state && epito ps 2>&1 || true)"
# BOTH units, because only one of them does the work: epitod registers the
# schedules and serves the ingress, epitod-worker executes the seats. A post
# that said "epitod is active" over a dead worker was a green line about a box
# running nothing -- \`epito ps\` now says so in its own header too, and this is
# the half that is true even when the engine cannot be reached to ask. (Those
# two backticks are escaped: an unquoted heredoc RUNS a backtick, so until this
# line was fixed every provision ran \`epito ps\` in the provisioning shell and
# spliced its stdout -- nothing, since it exits 1 outside a state directory --
# into this comment, while its stderr landed in the provision log. The same
# mistake as the one this unit's env line was fixed for: text one reader takes
# literally and another executes.)
active="\$(systemctl is-active epitod) / worker \$(systemctl is-active epitod-worker)"
[ "\${SLACK_WEBHOOK_URL:-replace-me}" = "replace-me" ] && { echo "\$state"; exit 0; }
payload=\$(jq -Rn --arg a "\$active" --arg s "\$(cat <<<"\$state")" '{text: ("epitod on \$(hostname) is " + \$a + "\n\`\`\`\n" + \$s + "\n\`\`\`")}')
curl -fsS -X POST -H 'content-type: application/json' --data "\$payload" "\$SLACK_WEBHOOK_URL" >/dev/null
HEALTH
chmod 0755 /usr/local/bin/epitod-health
cat > /etc/systemd/system/epitod-health.service <<UNIT
[Unit]
Description=epitod daily health post
[Service]
Type=oneshot
User=$SEATS_USER
Environment=HOME=$BASE/home
ExecStart=/usr/local/bin/epitod-health
UNIT
cat > /etc/systemd/system/epitod-health.timer <<'UNIT'
[Unit]
Description=epitod daily health post
[Timer]
OnCalendar=*-*-* 07:00:00 UTC
Persistent=true
[Install]
WantedBy=timers.target
UNIT
systemctl daemon-reload && systemctl enable --quiet --now epitod-health.timer
echo "  epitod-health.timer enabled (07:00 UTC)"

if [ "$SKIP_CADDY" = 0 ]; then
  say "caddy: TLS in front of 127.0.0.1:$PORT"
  if ! command -v caddy >/dev/null; then
    add_apt_repo caddy-stable https://dl.cloudsmith.io/public/caddy/stable/gpg.key \
      "deb https://dl.cloudsmith.io/public/caddy/stable/deb/debian any-version main"
    apt-get install -y -qq caddy >/dev/null
  fi
  install -d -m 0755 /etc/caddy
  cat > /etc/caddy/Caddyfile <<CADDY
{
	${EMAIL:+email $EMAIL}
	# Port 80 stays shut (ufw allows 22 and 443 only), so certificates are
	# issued over TLS-ALPN on 443 and no plaintext listener exists at all.
	auto_https disable_redirects
}

$DOMAIN {
	tls {
		issuer acme {
			disable_http_challenge
		}
	}
	# The ingress authenticates with x-epito-secret; TLS is what stops that
	# header travelling in the clear. epitod itself never sees the internet.
	reverse_proxy 127.0.0.1:$PORT
}
CADDY
  systemctl enable --quiet --now caddy && systemctl reload caddy || systemctl restart caddy
  echo "  https://$DOMAIN -> 127.0.0.1:$PORT"
fi

say "firewall and fail2ban"
ufw allow 22/tcp >/dev/null
if [ "$SKIP_CADDY" = 0 ]; then ufw allow 443/tcp >/dev/null; fi
ufw --force enable >/dev/null
# Oracle's Ubuntu images ship a vendor iptables chain that ACCEPTs 22 and then
# REJECTs everything, ahead of ufw's chains — so ufw's 443 rule never sees a
# packet. Insert an ACCEPT for 443 right after the vendor's 22 rule (mirroring
# it, not removing it) and persist, so Caddy is reachable after a reboot too.
if [ "$SKIP_CADDY" = 0 ]; then
  # One snapshot of the chain, read twice with no pipe, in place of two
  # `iptables -S INPUT` calls piped into readers. The first pipe was into
  # quiet grep, which can report no match for a line it DID match
  # (cli/test/shapes.sh's header carries the rate and the signature): that
  # verdict decides this whole block, so losing the race leaves a box whose
  # 443 is shadowed by the vendor REJECT and silently prints nothing about it.
  # The second pipe fed `cut` into `head -1`, which closes the pipe early
  # under `pipefail` — the same race on the line that picks the position.
  INPUT_RULES="$(iptables -S INPUT 2>/dev/null || true)"
  if grep -q -- '-j REJECT --reject-with icmp-host-prohibited' <<<"$INPUT_RULES"; then
    # awk rather than `grep -n | cut -d: -f1 | head -1`: one process, nothing
    # to orphan, the same answer — the first matching line's number, or empty.
    AT="$(awk '/--dport 22 -j ACCEPT/ {print NR; exit}' <<<"$INPUT_RULES")"
    if [ -z "$AT" ]; then
      # Empty used to reach `iptables -I INPUT "$(( ))"`, which is `0`, and
      # iptables answers `Invalid rule number '0'` with status 2 — so
      # `set -e` ended the provision here, mid-firewall, on a usage error
      # that names neither the rule broken nor the fix. Say both and carry on:
      # fail2ban and the closing instructions are still worth having.
      echo "provision-host: the vendor iptables chain is here (its REJECT is in INPUT) but no '--dport 22 -j ACCEPT' rule is, so there is no position to insert 443 ahead of the REJECT" >&2
      echo "provision-host: 443 is left to ufw alone, which this chain shadows — https://$DOMAIN will not answer until an ACCEPT sits above the REJECT. Insert and persist it, then re-run this script:" >&2
      echo "provision-host:   iptables -I INPUT 1 -p tcp -m state --state NEW -m tcp --dport 443 -j ACCEPT" >&2
      echo "provision-host:   netfilter-persistent save    # or: iptables-save > /etc/iptables/rules.v4" >&2
    else
      iptables -C INPUT -p tcp -m state --state NEW -m tcp --dport 443 -j ACCEPT 2>/dev/null \
        || iptables -I INPUT "$AT" -p tcp -m state --state NEW -m tcp --dport 443 -j ACCEPT
      if command -v netfilter-persistent >/dev/null; then netfilter-persistent save >/dev/null 2>&1; else install -d /etc/iptables && iptables-save > /etc/iptables/rules.v4; fi
      echo "  vendor iptables chain found (Oracle image): 443 ACCEPT inserted ahead of its REJECT and persisted"
    fi
  fi
fi
install -d -m 0755 /etc/fail2ban/jail.d
cat > /etc/fail2ban/jail.d/epitod.local <<'JAIL'
[sshd]
enabled = true
maxretry = 5
bantime = 1h
JAIL
systemctl enable --quiet --now fail2ban && systemctl restart fail2ban
ufw status | sed 's/^/  /'

say "done"
cat <<NEXT
  1. the engine: nothing here installed it, and the units in step 3 will not
     start without it. Both ways to get one are in docs/deploy/README.md
     ("Temporal server + UI") in this repository; the short one is
       temporal server start-dev --ip 127.0.0.1 --port 7233 --ui-port 8080 \\
           --namespace asc --db-filename /var/lib/temporal/temporal.db
     given a unit of its own so it survives a reboot. Then check it, and that
     the namespace exists:
       temporal operator cluster health --address 127.0.0.1:7233
       temporal operator namespace describe -n asc --address 127.0.0.1:7233
     If the namespace is missing: temporal operator namespace create asc
     If you used docker compose instead, publish on 127.0.0.1 explicitly:
     docker writes its own iptables chain and ufw's 22/443 does not cover it.
  2. fill in $BASE/env — the box's own three first (CLAUDE_CODE_OAUTH_TOKEN,
     GH_TOKEN, SLACK_WEBHOOK_URL), or point the Infisical agent at your project
     and let it render the file. Then the SEATS' names, which are not those
     three and are not in this script: they are in the manifests, and
       epito env $ROSTER_DIR              says which this box is short of
       epito env $ROSTER_DIR --template   prints them as lines for that file
     A name the box does not hold is dropped silently into every run of the
     seat that asked for it, so this is the step with no error message.
  3. put the roster in $ROSTER_DIR (one directory per agent, each an agent.toml
     with [runtime].repo set), then start the worker first and the ingress second:
       systemctl restart epitod-worker
       systemctl restart epitod
     A seat with no [trigger].cron registers no schedule, so a presence-only
     roster starts quiet on purpose. Adding a cron later needs no restart:
       systemctl reload epitod
  4. watch it: journalctl -u epitod-worker -u epitod -f
     the roster:  sudo -u $SEATS_USER sh -c 'cd $BASE/state && epito ps $ROSTER_DIR'
     the board:   sudo -u $SEATS_USER sh -c 'cd $BASE/state && epito board'
     the history: ssh -L 8080:127.0.0.1:8080 this-host, then open localhost:8080
  5. speak to it (the secret is in $BASE/env):
     curl -X POST -H "x-epito-secret: \$EPITO_HOOK_SECRET" $([ -n "$DOMAIN" ] && echo "https://$DOMAIN" || echo "http://127.0.0.1:$PORT")/window/open -d '{"scope":"all"}'
NEXT
