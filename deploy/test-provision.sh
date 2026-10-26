#!/usr/bin/env bash
# Exercises provision-host.sh without a host. It runs the real script inside a
# throwaway Ubuntu 24.04 container with the package managers, systemctl, ufw
# and the network installs stubbed, then asserts on what it *wrote*: the unit
# files, the Caddyfile, the health script, the secret file's mode — and runs
# it a second time to prove it is idempotent and never rewrites a secret.
#
#   bash deploy/test-provision.sh
#
# What this does not test: that apt, ACME and Oracle behave. Those need a real
# box, and the pitch's definition of done covers them with one.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Can this box become root at all? Three answers, not two, because only one of
# them makes `sudo systemctl start docker` the wrong thing to print:
#
#   yes          passwordless sudo answered, so the fix below is runnable here
#   interactive  sudo wants a password — runnable by the operator, just not by
#                this suite, which has no terminal to type into
#   no           sudo refused for a reason no password fixes: no binary, no
#                sudoers entry, or the kernel's `no new privileges` bit, which
#                makes sudo refuse before it ever reads sudoers. Found
#                2026-10-18 on the box that runs this company's own agents,
#                where this suite printed `sudo usermod -aG docker` at a
#                reader who cannot run sudo at all.
#
# Two globals rather than a return value: bash functions return a number, and
# the reason is a sentence docker's own stderr wrote.
ROOT_REACH=""
ROOT_SAID=""
probe_root() {
  local said
  said="$(sudo -n true 2>&1 || true)"
  if [ -z "$said" ]; then ROOT_REACH=yes; ROOT_SAID=""; return; fi
  ROOT_SAID="$(printf '%s\n' "$said" | head -1)"
  # A herestring, not a pipe into quiet grep: this line is not an assertion,
  # it DECIDES which of the three answers the reader gets, and quiet grep can
  # report "no match" for a string it matched (cli/test/shapes.sh's header has
  # the rate). A false no-match here tells an operator whose sudo only wants a
  # password that their box cannot become root at all, and prints the wrong fix.
  if grep -qiE 'password' <<<"$said"; then ROOT_REACH=interactive; return; fi
  ROOT_REACH=no
}

# The fix, in the product's own voice, for the box actually reading it. A pure
# function of the two facts above so the checks at the bottom can prove every
# case on a box that only has one of them — which is the whole difficulty with
# a skip path: it runs exactly where you are not.
fix_lines() {
  local reach="$1" said="$2" who="${USER:-$(id -un)}"
  case "$reach" in
    yes|interactive)
      echo "  start it:          sudo systemctl start docker"
      echo "  or join its group: sudo usermod -aG docker \"$who\" && newgrp docker"
      ;;
    *)
      echo "  and this box cannot become root either, so neither of those is your fix:"
      printf '    %s\n' "$said"
      echo
      echo "  so run this suite where a usable daemon already is: a box whose own user is"
      echo "  in the \`docker\` group, or CI, which starts one for the job."
      echo "  to make it run HERE, somebody who does have root on this box runs:"
      echo "    usermod -aG docker \"$who\"      # then \"$who\" logs in fresh"
      ;;
  esac
}

# The loop the last check below used to carry, as a function, for two reasons.
# The pipe into quiet grep is the one this card is about. The `|| exit 1` it
# also carried is the other: `check` runs its argument through `eval` inside an
# `if`, and `exit` is not caught by an `if` — so that check could not report
# itself. A mutated needle exited the suite with status 1 before `check`
# printed either verdict and before the tally line ran, which means the one
# assertion covering all three reach answers was unmutatable, and a conversion
# that left the `exit` in place could not have been proved live. `return 1`
# leaves the verdict where the other eight are. It is the only `exit` inside a
# check body in this repository: 867 `check` calls across cli/test/ and
# deploy/, one match.
every_case_names_a_fix() {
  local r
  for r in yes interactive no; do
    grep -qE 'docker|daemon' <<<"$(fix_lines "$r" x)" || return 1
  done
}

# The only assertions a box with no usable daemon can make: that the sentence
# it just printed is one its reader can act on. Before this, a docker-less box
# asserted NOTHING — `test/all.sh` called the suite `unrun`, which is honest
# about the container checks and silent about the skip path, and the skip path
# is the half that only ever runs on the machines nobody tests on.
#
# These are text checks on `fix_lines`, not another container: the fault they
# cover was a sentence, and a sentence is checkable anywhere.
skip_path_checks() {
  local pass=0 fail=0 out
  ok(){ pass=$((pass+1)); printf '  ok   %s\n' "$1"; }
  bad(){ fail=$((fail+1)); printf '  FAIL %s\n' "$1"; }
  check(){ if eval "$2"; then ok "$1"; else bad "$1"; fi; }

  echo
  echo "  == the skip path's own checks (what this box can still prove)"
  # Captured once and matched as a herestring, like the five below it: the two
  # lines this replaces piped `fix_lines` into quiet grep, and under `pipefail`
  # that pipeline can carry the producer's death instead of grep's match.
  local yes_out
  yes_out="$(fix_lines yes '')"
  check "a box with working sudo is told to start the daemon" \
    "grep -q 'sudo systemctl start docker' <<<\"\$yes_out\""
  check "and told the group fix, named for whoever is reading" \
    "grep -q 'usermod -aG docker \"${USER:-$(id -un)}\"' <<<\"\$yes_out\""
  check "sudo that only wants a password is still sudo, so the fix is unchanged" \
    "[ \"\$(fix_lines interactive 'sudo: a password is required')\" = \"\$(fix_lines yes '')\" ]"
  out="$(fix_lines no 'sudo: The \"no new privileges\" flag is set')"
  # Both root-needing fixes by name, not an anchored `sudo` — sudo's own
  # complaint is quoted in this branch and legitimately begins "sudo:", and an
  # anchor loose enough to miss that was also loose enough to miss
  # `  start it: sudo systemctl start docker` pasted back in mid-line, which is
  # exactly the regression this check exists to catch.
  check "a box that cannot become root is not told to run sudo" \
    "! grep -qE 'sudo (systemctl|usermod)' <<<\"\$out\""
  check "it is told why, in sudo's own words" \
    "grep -q 'no new privileges' <<<\"\$out\""
  check "and given a fix that does not need root on this box" \
    "grep -q 'run this suite where a usable daemon already is' <<<\"\$out\""
  check "plus the one somebody with root can run for it" \
    "grep -q 'usermod -aG docker' <<<\"\$out\""
  check "every case names a fix: no reach answer prints a bare complaint" \
    "every_case_names_a_fix"

  printf '\nprovision: %d ok, %d failed\n' "$pass" "$fail"
  # A skip is not a failure; a skip path that lies is. So the exit code is
  # about these checks only, and `test/all.sh` reads the tally above as the
  # suite's own count either way.
  [ "$fail" = 0 ] || exit 1
  exit 0
}

# Probe the daemon, not the binary. `command -v docker` passes on a box whose
# runtime user is not in the `docker` group, and then the first `docker run`
# dies on "permission denied … /var/run/docker.sock" — so test/all.sh prints
# FAILED for a box that has nothing wrong with it, which is the opposite of the
# "a machine without the binary is not a failing test, it is an unrun one"
# distinction this suite's skip line exists to make. `docker info` is the
# cheapest question that only a usable daemon can answer.
if ! docker info >/dev/null 2>&1; then
  echo "test-provision: needs docker (skipping)"
  if command -v docker >/dev/null 2>&1; then
    # The binary is here and the daemon is not reachable, which is a different
    # fix from "install docker" — and the only place the actual reason exists is
    # docker's own stderr. Carry it, rather than guessing which of the two it is.
    said="$(docker info 2>&1 || true)"
    # docker's own first line is the diagnosis ("ERROR: Cannot connect …",
    # "permission denied while trying to connect …"); the lines after it are
    # pretty-printer noise, so take the diagnosis and stop.
    #
    # Each grep carries its own `|| true`, and that is the whole point of the
    # three-step fallback: this file runs under `set -euo pipefail`, so a grep
    # that matches nothing exits 1, pipefail hands that 1 to the command
    # substitution, and `set -e` kills the script on the assignment — before
    # the `[ -n "$reason" ] ||` line that exists precisely to handle "no match"
    # ever runs. Found 2026-10-18 on a box whose docker daemon says "permission
    # denied while trying to connect" with no `ERROR` line: this suite exited 1
    # and test/all.sh printed FAILED for a machine with nothing wrong with it,
    # which is the exact outcome the skip above is written to prevent.
    reason="$(printf '%s\n' "$said" | grep -E '^ERROR' | head -1 || true)"
    [ -n "$reason" ] || reason="$(printf '%s\n' "$said" | grep -iE 'cannot connect|permission denied|refused' | head -1 || true)"
    [ -n "$reason" ] || reason="$(printf '%s\n' "$said" | tail -3 || true)"
    echo "  the \`docker\` binary is here but the daemon did not answer:"
    printf '%s\n' "$reason" | sed 's/^[[:space:]]*/    /'
    echo
    probe_root
    fix_lines "$ROOT_REACH" "$ROOT_SAID"
  else
    echo "  install it: https://docs.docker.com/engine/install/"
  fi
  skip_path_checks
fi

docker run --rm -i -v "$HERE/provision-host.sh:/provision-host.sh:ro" ubuntu:24.04 bash -s <<'IN_CONTAINER'
set -euo pipefail
pass=0; fail=0
ok(){ pass=$((pass+1)); printf '  ok   %s\n' "$1"; }
bad(){ fail=$((fail+1)); printf '  FAIL %s\n' "$1"; }
check(){ if eval "$2"; then ok "$1"; else bad "$1"; fi; }

# Stubs: everything that would reach the network or the init system. They log
# what they were asked to do so the run can be read afterwards.
mkdir -p /stub /var/log
for c in apt-get npm gh claude ufw systemctl fail2ban-client infisical caddy openssl curl gpg; do
  cat > "/stub/$c" <<STUB
#!/bin/sh
echo "$c \$*" >> /var/log/stubbed
exit 0
STUB
  chmod +x "/stub/$c"
done
# A few need to answer, not just succeed.
printf '#!/bin/sh\necho "openssl $*" >> /var/log/stubbed\necho deadbeefcafe\n' > /stub/openssl
printf '#!/bin/sh\necho "curl $*" >> /var/log/stubbed\nexit 0\n' > /stub/curl
printf '#!/bin/sh\necho "gh $*" >> /var/log/stubbed\necho "gh version 2.0.0 (stub)"\n' > /stub/gh
# node only has to answer the version check here: npm is stubbed, so nothing
# is actually built. git is real, because the clone is real.
printf '#!/bin/sh\ncase "$1" in -p) echo 22;; -v) echo v22.0.0;; *) exit 0;; esac\n' > /stub/node
chmod +x /stub/openssl /stub/curl /stub/gh /stub/node
export PATH="/stub:$PATH"
# node and git are real (the script reads node's version and clones with git);
# the clone is redirected to a local bare repo the way the smoke test does it.
mkdir -p /origin/alexandrapaiz
# git is the one real dependency of this test; everything else is stubbed.
/usr/bin/apt-get update -qq >/dev/null 2>&1 && /usr/bin/apt-get install -y -qq git sudo >/dev/null 2>&1 || true
command -v git >/dev/null && command -v sudo >/dev/null || { echo "  (no git/sudo in the container and apt is unreachable; nothing to assert)"; exit 0; }
seed=/seed; mkdir -p $seed/cli
printf '{"name":"epito","version":"0.1.0","bin":{"epito":"src/index.js"}}\n' > $seed/cli/package.json
git -c init.defaultBranch=main init -q $seed
git -C $seed add -A && git -C $seed -c user.name=t -c user.email=t@t commit -qm seed
git clone -q --bare $seed /origin/alexandrapaiz/epitome.git
# Every github.com clone in the container resolves to that bare repo — system
# scope, because the script clones as the seats user through sudo.
git config --system url."file:///origin/".insteadOf https://github.com/
git config --system --add safe.directory '*'

echo "== run 1"
bash /provision-host.sh --domain epitod.example.com --email ops@example.com --no-caddy > /run1.log 2>&1 || { echo "provision failed:"; tail -30 /run1.log; exit 1; }
sed -n '1,200p' /run1.log | sed 's/^/  | /' | tail -25

echo "== artifacts"
check "epitod.service written" "[ -f /etc/systemd/system/epitod.service ]"
check "epitod-worker.service written too — two units, not one" "[ -f /etc/systemd/system/epitod-worker.service ]"
check "the worker runs the worker, not the ingress" "grep -q 'epito worker' /etc/systemd/system/epitod-worker.service && ! grep -q 'epito run' /etc/systemd/system/epitod-worker.service"
check "the worker runs as the seats user too" "grep -q '^User=seats' /etc/systemd/system/epitod-worker.service"
check "the worker gets long enough to drain a run" "grep -q '^TimeoutStopSec=300' /etc/systemd/system/epitod-worker.service"
check "reloading the ingress re-reads the roster" "grep -q '^ExecReload=/bin/kill -HUP' /etc/systemd/system/epitod.service"
check "both units share one working directory, so one audit log" "[ \"\$(grep -h '^WorkingDirectory=' /etc/systemd/system/epitod.service /etc/systemd/system/epitod-worker.service | sort -u | wc -l)\" = 1 ]"
check "it runs as the seats user, not root" "grep -q '^User=seats' /etc/systemd/system/epitod.service"
check "it reads /srv/asc/env" "grep -q '^EnvironmentFile=/srv/asc/env' /etc/systemd/system/epitod.service"
check "it hosts /srv/asc/roster" "grep -q 'epito run /srv/asc/roster' /etc/systemd/system/epitod.service"
check "it restarts always" "grep -q '^Restart=always' /etc/systemd/system/epitod.service"
check "/srv/asc tree exists" "[ -d /srv/asc/repos ] && [ -d /srv/asc/state ] && [ -d /srv/asc/roster ]"
check "the seats user was created" "id seats >/dev/null 2>&1"
check "env file is 0600" "[ \$(stat -c %a /srv/asc/env) = 600 ]"
check "env file has a generated hook secret" "grep -q '^EPITO_HOOK_SECRET=deadbeefcafe' /srv/asc/env"
check "env file names the three secrets to fill in" "[ \$(grep -c 'replace-me' /srv/asc/env) = 3 ]"
check "env file names the engine, on loopback" "grep -q '^TEMPORAL_ADDRESS=127.0.0.1:7233' /srv/asc/env && grep -q '^TEMPORAL_NAMESPACE=asc' /srv/asc/env"
check "env file names the task queue the two units share" "grep -q '^EPITO_TASK_QUEUE=seats' /srv/asc/env"
# The box has to know the names the manifests only NAME — a road's endpoint and
# key, the board's two, every other one a seat lists in [runtime].env. This file
# used to carry a hand-copied subset of them and the copy had drifted: three
# names agents/pm/agent.toml asks for were never in it, so that seat would have
# run on this box, green, and filed nothing to the board. The list is generated
# from the roster now, so what is asserted is the pointer and not a copy.
check "env file sends the operator to the generator, not to a list in here" \
  "grep -q 'epito env /srv/asc/roster --template' /srv/asc/env"
check "and names the drift that is the reason why" \
  "grep -q 'BOARD_RUNTIME_TOKEN' /srv/asc/env"
check "an empty roster is said to be empty, not asked" \
  "grep -q 'no agent.toml under /srv/asc/roster yet' /run1.log"
check "health script and timer written" "[ -x /usr/local/bin/epitod-health ] && [ -f /etc/systemd/system/epitod-health.timer ]"
check "health posts epito ps" "grep -q 'epito ps' /usr/local/bin/epitod-health"
# Both units, because only one of them performs a run: a daily post that said
# "epitod is active" over a dead epitod-worker was a green line about a box
# that was running nothing.
check "health names both units, not just the ingress" "grep -q 'is-active epitod-worker' /usr/local/bin/epitod-health"
# An unquoted heredoc runs a backtick, and this comment had two unescaped ones:
# every provision ran `epito ps` in the provisioning shell and spliced its
# stdout into the generated file. The sentence arriving whole is the proof that
# nothing was executed on the way in.
check "the generated script's own comments arrive as text, not as commands" \
  "grep -q 'running nothing -- .epito ps. now says so' /usr/local/bin/epitod-health"

# The eighteen-hour outage, as four assertions. This unit died every run for a
# day and a half on this company's own host because its fourth line was
# `set -a; . /srv/asc/env`, the file is a systemd EnvironmentFile, and one
# value in it was a password hash -- which begins with a dollar sign. systemd
# was never confused; every shell that read the same bytes was. So no script
# this box writes may source that file again, and the assertion is written as
# a prohibition rather than a presence: a future edit that reintroduces
# `. /srv/asc/env` anywhere fails here.
check "the shared env-file reader is installed" "[ -f /usr/local/lib/epito-envfile.sh ] && grep -q 'load_env_file' /usr/local/lib/epito-envfile.sh"
check "the reader has systemd's rules, not the shell's (no eval of a value)" \
  "! grep -qE '^[^#]*eval' /usr/local/lib/epito-envfile.sh"
check "the health script reads the env file with that reader" \
  "grep -q '^\. /usr/local/lib/epito-envfile.sh' /usr/local/bin/epitod-health && grep -q '^load_env_file /srv/asc/env' /usr/local/bin/epitod-health"
check "nothing this box wrote sources the env file as a shell script" \
  "! grep -rlE '^[^#]*(\.|source)[[:space:]]+[\"\x27]?/srv/asc/env' /usr/local/bin/epitod-health /etc/systemd/system/epitod*.service"
# And the reader, against a value of the shape that caused it: proof on this
# box rather than in the unit suite, because what is under test here is the
# copy this script installed.
cat > /tmp/hash.env <<'HASHENV'
PASSWORD_HASH=$2b$12$KIXQe1mJ0rZ8wV
WITH_SPACE=hello world
HASHENV
check "a hash and a space survive the reader byte for byte" \
  "bash -c '. /usr/local/lib/epito-envfile.sh; load_env_file /tmp/hash.env; [ \"\$PASSWORD_HASH\" = \x27\$2b\$12\$KIXQe1mJ0rZ8wV\x27 ] && [ \"\$WITH_SPACE\" = \x27hello world\x27 ]'"
check "and the old way still mangles them, which is why the reader exists" \
  "! bash -c 'set -u; set -a; . /tmp/hash.env; set +a' 2>/dev/null"
# The engine is not installed with the CLI any more (cli/package.json makes
# @temporalio/* optional peers so `npm i -g epito-cli` stays half a megabyte), so
# this box has to ask for it by name. It got all the way through this suite
# green once without doing that: 35 assertions about a host whose two units
# would start, print an install line and exit 1.
check "the CLI was installed from the checkout" "grep -q 'npm install -g --silent \.' /var/log/stubbed"
for p in client worker activity workflow; do
  check "the engine was installed globally too: @temporalio/$p" \
        "grep -q 'npm install -g --silent .*@temporalio/'\"$p\" /var/log/stubbed"
done
check "and globally, not into the checkout where a global epito cannot see it" \
      "grep -q 'npm install -g --silent @temporalio/client' /var/log/stubbed"
check "ufw opened 22" "grep -q '^ufw allow 22/tcp' /var/log/stubbed"
check "ufw was enabled" "grep -q '^ufw --force enable' /var/log/stubbed"
check "fail2ban jail written" "grep -q 'enabled = true' /etc/fail2ban/jail.d/epitod.local"
check "both units enabled" "grep -q 'systemctl enable --quiet epitod-worker' /var/log/stubbed && grep -q 'systemctl enable --quiet epitod$' /var/log/stubbed"
check "the closing hints tell the chair to check the engine first" "grep -q 'temporal operator namespace describe' /run1.log"
check "and to start the worker before the ingress" "grep -q 'systemctl restart epitod-worker' /run1.log"

echo "== run 2 (idempotency)"
before=$(cat /srv/asc/env)
bash /provision-host.sh --domain epitod.example.com --no-caddy > /run2.log 2>&1 || { echo "second run failed:"; tail -30 /run2.log; exit 1; }
check "the second run did not touch the secrets" "[ \"\$before\" = \"\$(cat /srv/asc/env)\" ]"
check "it says so, by name" "grep -q 'left untouched' /run2.log"
check "the unit is still there and unchanged" "grep -q '^User=seats' /etc/systemd/system/epitod.service"

echo "== the roster's own names, asked of the roster"
# Give the box a manifest and an epito, and prove the script ASKS it rather
# than printing a list somebody typed in. The env file and the roster are two
# copies of one set of names unless exactly one of them is generated.
mkdir -p /srv/asc/roster/pm
cat > /srv/asc/roster/pm/agent.toml <<'TOML'
[agent]
name = "pm"
description = "A seat with two names this box does not hold."
[identity]
scopes = ["github:contents"]
[trigger]
cron = "0 12 * * 1"
[runtime]
model = "claude-sonnet-5"
entry = "prompts/pm-agent.md"
repo = "alexandrapaiz/epitome"
env = ["BOARD_API_URL", "BOARD_RUNTIME_TOKEN"]
TOML
chown -R seats:seats /srv/asc/roster
printf '#!/bin/sh\necho "epito $*" >> /var/log/stubbed\necho "(stub epito: 2 names, 0 held)"\n' > /stub/epito
chmod +x /stub/epito
bash /provision-host.sh --domain epitod.example.com --no-caddy > /run4.log 2>&1 || { echo "run 4 failed:"; tail -20 /run4.log; exit 1; }
check "the script asks the roster what this box must hold" "grep -q '^epito env /srv/asc/roster$' /var/log/stubbed"
check "it prints the answer where the operator is reading" "grep -q 'stub epito: 2 names' /run4.log"
check "and says what to do with it" "grep -q 'add any name above that this box should hold' /run4.log"
check "the secrets survived a run that read them" "grep -q '^EPITO_HOOK_SECRET=deadbeefcafe' /srv/asc/env"

echo "== caddy (--domain, no --no-caddy)"
bash /provision-host.sh --domain epitod.example.com --email ops@example.com > /run3.log 2>&1 || { tail -20 /run3.log; exit 1; }
check "Caddyfile serves the domain" "grep -q '^epitod.example.com {' /etc/caddy/Caddyfile"
check "it proxies the local ingress only" "grep -q 'reverse_proxy 127.0.0.1:4747' /etc/caddy/Caddyfile"
check "no plaintext listener (port 80 stays shut)" "grep -q 'disable_http_challenge' /etc/caddy/Caddyfile && grep -q 'auto_https disable_redirects' /etc/caddy/Caddyfile"
check "ufw opened 443 this time" "grep -q '^ufw allow 443/tcp' /var/log/stubbed"

echo "== refusals"
out=$(bash /provision-host.sh 2>&1 || true); check "no --domain and no --no-caddy is refused, with the fix" "grep -q 'pass --no-caddy' <<<\"\$out\""
out=$(bash /provision-host.sh --wat 2>&1 || true); check "an unknown option is named" "grep -q 'unknown option' <<<\"\$out\""

printf '\nprovision: %d ok, %d failed\n' "$pass" "$fail"
[ "$fail" = 0 ]
IN_CONTAINER
