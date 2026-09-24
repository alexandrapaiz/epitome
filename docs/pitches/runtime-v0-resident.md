# Pitch: runtime v0, resident — presence for epitod

Owner-directed 2026-09-20 (Alexandra Systems HQ ADR-032). Supersedes
runtime-v0-actions.md as the runtime pitch: the owner wants agents
with cloud runtimes "not tied to my laptop or ephemeral triggers", on
free compute, built with epitome because "this is kind of the product
for Epitome". The first customer is HQ: eight seats, manifests in
alexandra-systems/runtime/agents/, and the whole portfolio behind them.

## Problem

`epito run` already hosts a roster: cron tick, `POST /hooks/<name>`,
the runner, audit, `epito ps`, a systemd unit. But every trigger is a
fresh run — the agent finishes and forgets. The owner's synchronous
mode (HQ standards/operating-modes.md) needs **presence**: an agent
that holds its session for a work window, takes a follow-up in the
same conversation, can be spoken to from Slack, and wakes on GitHub
events — resident on an always-on host, billed to the subscription.

## Appetite

Small batch: 4 engineer runs. The daemon exists; this is four features
on it and a host script. If it swells, the pitch was wrong.

## Rough solution (breadboard)

1. **Held sessions.** `runner.js` captures the executor's `session_id`
   from `--output-format json`; per agent, `state` keeps
   `{session_id, window_opened_at}`. Within an open window, the next
   invocation passes `--resume <session_id>` so context is held. A
   window is opened by `POST /window/open` (or `epito window open`)
   and closed by `POST /window/close` or a wall-clock (default 4h);
   closing discards the session id (the PRs are the record — ADR-2's
   "repo-as-state" holds).
2. **The mailbox.** `POST /message/<name>` `{text}` → if a session is
   held, continue it with `text` as the prompt; else behave as
   `/hooks/<name>`. Queued per agent behind the existing `running`
   mutex; `pending` coalescing unchanged.
3. **Slack post.** After every run or message, if `SLACK_WEBHOOK_URL`
   is in the agent's `[runtime].env`, post one line: agent, trigger,
   turns, PR url if the run opened one (parse from the executor's
   output), duration. The seat posts; it never reads.
4. **All-hands.** `POST /window/open` `{scope}` opens windows for every
   agent whose manifest matches scope and fires each once with the
   synchronous instruction (HQ tools/all-hands.sh gains
   `--runtime epitod` that calls this instead of `gh workflow run`).
5. **The host.** `deploy/provision-host.sh`: idempotent over SSH for
   Ubuntu 24.04 arm64 (Oracle Always Free A1): Node 22, claude-code,
   gh, git, Caddy (TLS in front of the daemon), user `seats`, repos
   under `/srv/asc/repos`, Infisical agent → `/srv/asc/env` (0600),
   `epitod.service` from the existing unit, UFW 22/443, fail2ban,
   daily `epito ps` to `#hq` as health + keepalive.

## Rabbit holes

- Rebuilding a session store: no. `--resume` and one id per agent is
  the whole design; the repo is the memory.
- A Slack *reader* in the daemon: no. The bridge (Slack Events → the
  mailbox) is a separate, later, tiny process; seats never read Slack.
- Multi-host or containers per agent: no. One VM, systemd units,
  `DynamicUser` decided later per the epitod pitch.

## No-gos

No metered API (owner: "no i wont pay extra") — the executor runs on
`CLAUDE_CODE_OAUTH_TOKEN`. No new runtime dependency without a
justification line (architecture § dependency budget). No change to
manifest spec v0.1 beyond what `[runtime].repo` already proposes.

## Definition of done

HQ's pm manifest hosted on the Oracle VM; one window: the charter run
opens a draft PR; a `POST /message/pm` follow-up continues the same
session (context demonstrably held: it references its own PR); Slack
shows both; `epito ps` shows the held session; the window closes on
the clock. Audit lines for all of it.
