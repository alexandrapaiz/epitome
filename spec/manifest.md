# The agent manifest (agent.toml), spec v0.1

One file is the whole agent. The manifest is the unit of everything that
comes later: a deploy is a manifest provisioned, a team is manifests with
a shared roster, a marketplace listing is a manifest published. The file
an agent carries is its **epitome**: the abridged, faithful cut of its
owner's authority.

A manifest has four tables. `[agent]` says who it is; the other three are
the definition of an agent itself (ADR-2): `[identity]`, `[trigger]`,
`[runtime]`. A manifest missing any of the three describes a skill, and
`epito validate` says so in those words.

```toml
[agent]
name = "historian"                      # required: [a-z0-9-], 1-40 chars, unique per roster
description = "Writes the daily digest" # required: one sentence, shown on the roster

[identity]
scopes = ["github:contents", "github:pull_requests"]
                                        # required, non-empty: platform:permission strings.
                                        # v0.1 platform: github. The deploy target maps these
                                        # to fine-grained App permissions; anything unmapped
                                        # fails deploy loudly.

[trigger]                               # required: at least one of the three
cron = "0 6 * * *"                      # 5-field cron, UTC
on   = ["issue.opened"]                 # platform event subscriptions
webhook = true                          # deploy returns a per-agent signed URL

[runtime]
model = "claude-sonnet-5"               # required: explicit, never defaulted (an unset model
                                        # is silently under-modeled — alexandria incident 9)
entry = "prompts/historian.md"          # required: the charter file, path in repo
repo  = "owner/historian"               # PROPOSED (v0.1, epitod v0): the GitHub repository
                                        # the resident runtime clones fresh for every run;
                                        # `entry` is a path inside it. Required by `epito run`.
ref   = "main"                          # PROPOSED, optional: branch or tag the runtime checks
                                        # out; unset = the repository's default branch
image = "default"                       # optional: container image; "default" = platform base
max_turns = 100                         # optional: run cap, default 100
env = []                                # optional: names of secrets the runtime injects;
                                        # values never appear in the manifest, ever
slack_webhook_env = "SLACK_WEBHOOK_URL_EPITOME"
                                        # PROPOSED (v0.1, epitod v1), optional: the NAME of
                                        # the webhook secret this agent's one-line post goes
                                        # to, so a product seat speaks in its own channel.
                                        # Must also appear in `env`. Unset = the runtime's
                                        # default SLACK_WEBHOOK_URL, or no post if that is
                                        # not listed in `env` either.
```

## Rules

1. **Nothing personal in the file.** No tokens, no keys, no owner
   credentials. `env` carries secret *names* only. A manifest must be
   publishable without redaction — that property is what makes the later
   marketplace possible.
2. **Scopes are the ceiling.** The runtime can never acquire a permission
   the manifest doesn't declare. Widening a scope is a manifest change,
   which means a diff, which means the audit trail includes intent.
3. **Explicit beats defaulted** for anything that changes behavior
   silently: model, scopes, and triggers have no defaults.
4. **One manifest, one principal.** Deploying the same file twice updates
   the same agent; renaming creates a new one. Identity follows `name`.

## Proposed in-band (epitod v1, cycle 2 bet)

- `[runtime].slack_webhook_env`, optional. The name of the environment
  variable holding the Slack webhook this agent posts its one line to.
  It exists because four companies now share one runtime and one
  `SLACK_WEBHOOK_URL` that goes to `#hq`: a product seat needs to be
  able to speak in its own channel without the runtime growing a
  routing table. Rule 1 governs it exactly as it governs `env`: the
  manifest carries the NAME, never the URL. `epito validate` refuses a
  value that looks like a URL rather than a variable name, and refuses
  a name that is not also listed in `[runtime].env`, because the
  runtime injects only the names the manifest lists and an unlisted
  webhook could never resolve to a value. Absent the field, behavior
  is exactly what it was: `SLACK_WEBHOOK_URL` if `env` lists it, no
  post otherwise. Every existing manifest is therefore unaffected,
  which is the compatibility bar epitod v1 had to clear.

## Proposed in-band (epitod v0, cycle 1 bet 1)

- `[runtime].repo = "owner/name"`. The resident runtime (`epito run`)
  needs to know which repository a run happens in: it clones it into a
  fresh temp dir, reads `entry` inside the clone, and hands the clone to
  the agent as its working directory. In the Actions runtime the repo
  was implicit (the workflow lives in it); in a resident daemon that
  hosts many agents from one directory it must be explicit. `epito
  validate` accepts the field when present (owner/name grammar) and, when
  it is set, checks `entry` at run time inside the clone instead of at
  validate time on disk. Absent `repo`, `epito run` refuses the manifest
  and says so; `epito validate` stays silent (Actions-era manifests
  remain valid).
- `[runtime].ref`, optional. Which branch or tag the run checks out
  (`git clone --branch <ref>`); unset means the default branch, which
  is what every HQ seat wants. Exists so a charter can be staged on a
  branch and run before it merges (this PR's own smoke test needs it).

## Open questions (settle before v0.2)

- Scope grammar for non-GitHub platforms (`asana:tasks.write`?
  `postgres:read/dbname`?) — decide with the second integration, not
  before, per the backlog.
- Whether `[trigger]` combinations compose (cron + events on one agent)
  or v1 forces exactly one.
- Team/roster fields stay OUT of the manifest (a roster references
  manifests, not the reverse) — confirm this survives contact with the
  dogfood migration.
