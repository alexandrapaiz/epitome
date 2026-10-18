#!/usr/bin/env bash
# The three downloads that stand between a cold machine and a green run.
#
#   bash test/prereqs.sh              # into ${TMPDIR}/epito-prereqs
#   bash test/prereqs.sh ~/.cache/epito-prereqs
#   bash test/all.sh --with-prereqs   # calls this, then runs everything
#
# Why this exists. `test/all.sh` reports four outcomes rather than two because a
# suite that could not run must not be read as a suite that passed. That was the
# right fix and it left a second problem behind: on every machine nobody had
# prepared by hand, three of the eight suites were *permanently* incomplete —
# smoke-temporal `unrun` (no `temporal` binary), smoke-roster `partial` (no
# engine answering), smoke-langgraph `partial` (langgraph not importable). The
# harness named the fix in each case and no one ran it, so a reconcile loop that
# never converged sat live for days behind an `unrun` line (PR #71 found it the
# first time smoke-temporal actually ran).
#
# A permanent `partial` teaches people to read past the column. So the
# prerequisites are one command now, and what they cost is measured rather than
# guessed: the Temporal CLI is a ~45 MB download, the langgraph wheel set is
# ~40 MB of pip, nats-server is 7 MB, and everything else the suites need was
# already on the box.
#
# nats-server joined them on 2026-10-17, when the bus got a suite that drives a
# real one: the NATS client in src/lib/nats.js is written here rather than
# depended on, so a mock of the server tests the client against its own author's
# idea of the protocol and nothing else.
#
# What it does NOT do: decide whether a suite can run. Each suite owns that
# question and already answers it honestly — this only puts the binaries where
# the suites already look, and writes down where that was. Detection stays where
# it is; see the note at the top of test/all.sh.
set -uo pipefail

CLI="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIR="${1:-${EPITO_PREREQS_DIR:-${TMPDIR:-/tmp}/epito-prereqs}}"
case "$DIR" in
  -h|--help) sed -n '2,8p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
  -*) echo "test/prereqs.sh: \"$DIR\" is not a directory — the only argument is where to install, and the only option is --help."; exit 2 ;;
esac
mkdir -p "$DIR" || { echo "test/prereqs.sh: cannot create $DIR — pass a directory this user can write to."; exit 2; }
DIR="$(cd "$DIR" && pwd)"

say() { printf '%s\n' "$*"; }
step() { printf '\n\033[1m== %s\033[0m\n' "$*"; }

TEMPORAL_HOME="$DIR/temporalio"
TEMPORAL_EXE="$TEMPORAL_HOME/bin/temporal"
VENV="$DIR/lgvenv"
NATS_HOME="$DIR/nats"
NATS_EXE=""
NATS_VERSION="v2.15.1"
VENV_PY="$VENV/bin/python"
ENV_FILE="$DIR/env.sh"

# ---- 1. the Temporal CLI -----------------------------------------------------
# smoke-temporal.sh starts its own `server start-dev` on a private port, so the
# binary is the whole prerequisite; it looks at $TEMPORAL_BIN, then PATH, then
# ~/.temporalio/bin. This installs into the cache directory and env.sh points
# TEMPORAL_BIN at it, so nothing has to land in $HOME.
step "the Temporal CLI"
if [ -x "$TEMPORAL_EXE" ] && "$TEMPORAL_EXE" --version >/dev/null 2>&1; then
  say "  already here: $TEMPORAL_EXE ($("$TEMPORAL_EXE" --version 2>&1 | head -1))"
elif command -v temporal >/dev/null 2>&1; then
  say "  already on PATH: $(command -v temporal) ($(temporal --version 2>&1 | head -1))"
  TEMPORAL_EXE="$(command -v temporal)"
else
  installer="$DIR/.cli.sh"
  say "  downloading the installer (temporal.download/cli.sh)"
  if ! curl -fsSL --proto '=https' --tlsv1.2 https://temporal.download/cli.sh -o "$installer"; then
    say "  FAILED to download https://temporal.download/cli.sh — this machine has no route to it."
    say "  Install the CLI by hand and re-run with TEMPORAL_BIN set, or accept that"
    say "  smoke-temporal reports unrun here. It is not a failing test; it is an unrun one."
    exit 1
  fi
  say "  installing into $TEMPORAL_HOME (~45 MB, under a minute on a cold runner)"
  if ! sh "$installer" --dir "$TEMPORAL_HOME" >"$DIR/.cli-install.log" 2>&1; then
    say "  FAILED — the installer said:"
    tail -5 "$DIR/.cli-install.log" | sed 's/^/    /'
    exit 1
  fi
  rm -f "$installer"
  [ -x "$TEMPORAL_EXE" ] || { say "  FAILED — the installer exited 0 but $TEMPORAL_EXE is not executable."; exit 1; }
  say "  installed: $TEMPORAL_EXE ($("$TEMPORAL_EXE" --version 2>&1 | head -1))"
fi

# ---- 2. a Python with langgraph in it ---------------------------------------
# smoke-langgraph.sh's real-framework half imports langgraph with $EPITO_PYTHON
# (falling back to python3, then to /tmp/lgvenv). A venv, not a --user install:
# the adapter is proof that epito runs a framework it knows nothing about, and
# installing that framework into the box's python would make this suite's own
# machine a worse model of a customer's.
step "langgraph, in its own venv"
if [ -x "$VENV_PY" ] && "$VENV_PY" -c 'import langgraph' >/dev/null 2>&1; then
  say "  already here: $VENV_PY ($("$VENV_PY" -c 'from importlib.metadata import version; print("langgraph", version("langgraph"))'))"
elif ! command -v python3 >/dev/null 2>&1; then
  say "  SKIPPED — no python3 on this machine, so there is nothing to make a venv with."
  say "  smoke-langgraph's real-framework half will keep reporting partial, correctly."
  VENV_PY=""
else
  if [ ! -x "$VENV_PY" ] && ! python3 -m venv "$VENV" >"$DIR/.venv.log" 2>&1; then
    say "  FAILED to create a venv at $VENV — python3 said:"
    tail -5 "$DIR/.venv.log" | sed 's/^/    /'
    say "  On Debian and Ubuntu this is usually: sudo apt-get install -y python3-venv"
    exit 1
  fi
  say "  installing langgraph into $VENV (~40 MB of wheels)"
  if ! "$VENV/bin/pip" install --quiet --disable-pip-version-check langgraph >"$DIR/.pip.log" 2>&1; then
    say "  FAILED — pip said:"
    tail -5 "$DIR/.pip.log" | sed 's/^/    /'
    exit 1
  fi
  say "  installed: $VENV_PY ($("$VENV_PY" -c 'from importlib.metadata import version; print("langgraph", version("langgraph"))'))"
fi

# ---- 3. nats-server, for the bus ---------------------------------------------
# smoke-bus.sh starts its own on a free port with its own JetStream store, so
# the binary is the whole prerequisite; it looks at $NATS_BIN, then PATH, then
# here. One pinned release rather than "latest": a suite that asserts how a
# server answers should not change what it is asserting against overnight.
step "nats-server (the bus)"
FOUND="$(find "$NATS_HOME" -name nats-server -type f -perm -u+x 2>/dev/null | head -1)"
if [ -n "$FOUND" ] && "$FOUND" --version >/dev/null 2>&1; then
  NATS_EXE="$FOUND"
  say "  already here: $NATS_EXE ($("$NATS_EXE" --version 2>&1 | head -1))"
elif command -v nats-server >/dev/null 2>&1; then
  NATS_EXE="$(command -v nats-server)"
  say "  already on PATH: $NATS_EXE ($(nats-server --version 2>&1 | head -1))"
else
  case "$(uname -s)" in Linux) os=linux ;; Darwin) os=darwin ;; *) os="" ;; esac
  case "$(uname -m)" in x86_64|amd64) arch=amd64 ;; arm64|aarch64) arch=arm64 ;; *) arch="" ;; esac
  if [ -z "$os" ] || [ -z "$arch" ]; then
    say "  SKIPPED — no published nats-server build for $(uname -s)/$(uname -m)."
    say "  smoke-bus will report unrun here, correctly. Build one and set NATS_BIN."
  else
    pkg="nats-server-$NATS_VERSION-$os-$arch"
    url="https://github.com/nats-io/nats-server/releases/download/$NATS_VERSION/$pkg.tar.gz"
    mkdir -p "$NATS_HOME"
    say "  downloading $pkg (~7 MB)"
    if ! curl -fsSL --proto '=https' --tlsv1.2 "$url" -o "$NATS_HOME/$pkg.tar.gz"; then
      say "  FAILED to download $url — this machine has no route to it."
      say "  Install nats-server by hand and re-run with NATS_BIN set, or accept that"
      say "  smoke-bus reports unrun here. It is not a failing test; it is an unrun one."
      exit 1
    fi
    if ! tar xzf "$NATS_HOME/$pkg.tar.gz" -C "$NATS_HOME"; then
      say "  FAILED to unpack $NATS_HOME/$pkg.tar.gz"
      exit 1
    fi
    rm -f "$NATS_HOME/$pkg.tar.gz"
    NATS_EXE="$(find "$NATS_HOME" -name nats-server -type f -perm -u+x 2>/dev/null | head -1)"
    [ -n "$NATS_EXE" ] || { say "  FAILED — the tarball unpacked and carried no nats-server."; exit 1; }
    say "  installed: $NATS_EXE ($("$NATS_EXE" --version 2>&1 | head -1))"
  fi
fi

# ---- 4. write down where everything went ------------------------------------
# One file, so that neither all.sh nor a human has to re-derive any of this.
{
  echo "# Written by cli/test/prereqs.sh on $(date -u '+%Y-%m-%dT%H:%M:%SZ'). Source it:"
  echo "#   . $ENV_FILE"
  echo "export TEMPORAL_BIN=\"$TEMPORAL_EXE\""
  echo "export PATH=\"$(dirname "$TEMPORAL_EXE"):\$PATH\""
  [ -n "$VENV_PY" ] && echo "export EPITO_PYTHON=\"$VENV_PY\""
  [ -n "$NATS_EXE" ] && echo "export NATS_BIN=\"$NATS_EXE\""
} > "$ENV_FILE"

step "what this put where"
say "  $ENV_FILE"
sed 's/^/    /' "$ENV_FILE"
say ""
say "  Now either:"
say "    bash test/all.sh --with-prereqs       # finds this and starts an engine too"
say "    . $ENV_FILE && bash test/all.sh"
say ""
say "  smoke-roster's planning section needs an engine as well as a binary; that is"
say "  the one thing this script does not leave running. --with-prereqs starts one"
say "  for the length of the run, or start your own: temporal server start-dev"
