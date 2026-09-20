# epitod v0: the resident runtime as one container.
# The whole mechanism is visible here: node for `epito run`, git for the
# per-run clone, gh for the agent's draft PR, and the claude CLI as the
# executor `epito run` spawns (`claude -p ...`). No supervisor inside the
# container; the host (Fly Machine, systemd, docker --restart) restarts it.
FROM node:22-alpine

RUN apk add --no-cache git github-cli bash ca-certificates \
 && npm install -g @anthropic-ai/claude-code \
 # git asks gh for credentials, and gh reads GH_TOKEN: the token never
 # lands in any clone's .git/config, so the agent's worktree cannot read it.
 && git config --system credential.helper '!gh auth git-credential'

WORKDIR /opt/epito
COPY cli/package.json cli/package-lock.json ./
RUN npm ci --omit=dev
COPY cli/src ./src
RUN ln -s /opt/epito/src/index.js /usr/local/bin/epito

# The roster: mount or COPY a directory of agent.toml files at /agents.
# State (.epito/audit.jsonl, state.json, logs) lives in /var/lib/epito.
RUN mkdir -p /agents /var/lib/epito
WORKDIR /var/lib/epito
VOLUME ["/var/lib/epito"]

ENV EPITO_PORT=4747
EXPOSE 4747
# Required at runtime, from the host's secret store, never baked in:
#   EPITO_HOOK_SECRET      shared secret for POST /hooks/<name>
#   CLAUDE_CODE_OAUTH_TOKEN (or ANTHROPIC_API_KEY)  the executor's auth
#   GH_TOKEN               git clone/push + gh pr create, for now (bet 2 replaces it)
# Each agent.toml lists the names it needs under [runtime].env.
ENTRYPOINT ["epito", "run", "/agents"]
