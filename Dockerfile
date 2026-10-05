# epitod v1 as one image, run twice: once as the worker, once as the
# reconciler + ingress (docs/prfaq/epitod-v1-temporal.md).
#
#   docker run ... epitod worker          the process that runs seats
#   docker run ... epitod run /agents     reconcile the roster, serve the ingress
#
# The whole mechanism is visible here: node for both processes, git for the
# per-run clone, gh for the agent's draft PR, and the claude CLI as the executor
# the `execute` activity spawns (`claude -p ...`). What is NOT here is the
# engine: Temporal is a separate service reached at TEMPORAL_ADDRESS, self-
# hosted (HQ runtime/temporal/install.sh), never Temporal Cloud. No supervisor
# inside the container; the host restarts it.
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

# The roster: mount or COPY a directory of agent.toml files at /agents. Only
# the reconciler reads it — the worker gets each manifest in the workflow input.
# State (.epito/audit.jsonl, logs) lives in /var/lib/epito, and both processes
# must share it so there is one audit log.
RUN mkdir -p /agents /var/lib/epito
WORKDIR /var/lib/epito
VOLUME ["/var/lib/epito"]

ENV EPITO_PORT=4747 \
    TEMPORAL_ADDRESS=127.0.0.1:7233 \
    TEMPORAL_NAMESPACE=default \
    EPITO_TASK_QUEUE=seats
EXPOSE 4747
# Required at runtime, from the host's secret store, never baked in:
#   TEMPORAL_ADDRESS       the engine (use host networking or a shared network)
#   EPITO_HOOK_SECRET      shared secret for the ingress routes
#   CLAUDE_CODE_OAUTH_TOKEN (or ANTHROPIC_API_KEY)  the executor's auth
#   GH_TOKEN               git clone/push + gh pr create, for now (bet 2 replaces it)
#   SLACK_WEBHOOK_URL[_<PRODUCT>]  where a seat's one line goes
# Each agent.toml lists the names it needs under [runtime].env, and only the
# worker's environment ever holds a value.
ENTRYPOINT ["epito"]
CMD ["run", "/agents"]
