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

## Proposed in-band (identity slice, cycle 1 bet 2)

Additive clarifications the mint (`epito token <name>`, cli/src/lib/identity.js)
forced into the open. Neither changes a rule; both write down an answer the
spec left to the implementation, which is exactly the kind of thing that
drifts if it stays unwritten.

- **A mapped scope grants write.** v0.1 says scopes map to fine-grained App
  permissions but never says at which access level. The mint reads them as:

  | scope | GitHub App permission |
  | --- | --- |
  | `github:contents` | `contents: write` |
  | `github:pull_requests` | `pull_requests: write` |
  | `github:issues` | `issues: write` |

  Write, because every one of the three seat shapes commits, opens PRs, or
  comments; a read-only agent is a reader, and nothing in v0.1 can express
  one yet (see the open question below). `metadata: read` is absent because
  GitHub grants it to every installation implicitly. Anything outside the
  table fails the mint loudly, naming the scope and the mapped set — the
  behaviour v0.1 already requires of deploy, now real.

- **`[runtime].repo` bounds the credential, not just the clone.** A minted
  token is scoped to exactly one repository, and `repo` is what says which.
  The field is already PROPOSED above as the resident runtime's clone
  target; this is a second, independent reason it is required in practice.
  `epito validate` still stays silent when it is absent (Actions-era
  manifests remain valid); `epito run` and `epito token` both refuse.

## Open questions (settle before v0.2)

- Scope grammar for non-GitHub platforms (`asana:tasks.write`?
  `postgres:read/dbname`?) — decide with the second integration, not
  before, per the backlog.
- Whether `[trigger]` combinations compose (cron + events on one agent)
  or v1 forces exactly one.
- **Access levels in the scope grammar.** Every mapped scope grants write
  today (above), so a manifest cannot describe a read-only agent. The
  grammar already admits a modifier — `github:contents.read` parses — but
  inventing one before a real read-only agent exists is a guess. Decide with
  the second integration, alongside the non-GitHub grammar question above,
  so the two answers are designed together rather than in sequence.
- Team/roster fields stay OUT of the manifest (a roster references
  manifests, not the reverse) — confirm this survives contact with the
  dogfood migration.
