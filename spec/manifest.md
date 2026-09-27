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
adapter = "claude"                      # PROPOSED (v0.1, the adapter slice), optional:
                                        # which KIND of agent this is — what the
                                        # runtime spawns for a run. "claude" (the
                                        # default, and what every manifest written
                                        # before this field means) or "langgraph".
graph = "agent"                         # PROPOSED, optional: which graph in the
                                        # agent's own langgraph.json this seat runs.
                                        # Only the langgraph adapter reads it, and
                                        # `epito validate` refuses it beside any
                                        # other adapter — the two lines above are a
                                        # catalogue of fields, not a manifest to copy.
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

## Proposed in-band (the adapter slice, owner priority 3)

Two optional, additive fields. Both default to the behaviour every existing
manifest already has, which is the compatibility bar this slice had to clear:
an absent `adapter` is `"claude"`, and the argv the runtime spawns for such a
manifest is byte-identical to what it spawned before adapters existed (asserted
in `cli/test/unit.mjs`).

- **`[runtime].adapter`**, optional. Which kind of agent this is, from the set
  the runtime can host: `"claude"` (the Claude Code CLI, headless) or
  `"langgraph"` (a LangGraph app, run through the `langgraph.json` its author
  already wrote). It is a *kind*, not a command: the manifest never names an
  executable, because a manifest is publishable and a path on somebody's box is
  not. `epito validate` refuses a value outside the set, listing the set and
  what each member is (ADR-17).

  The field exists because the runtime had exactly one agent shape hard-coded
  into it, which contradicts the promise that epito runs the agent you already
  have (R4, ADR-10). An adapter adds no dependency to the product: epito spawns
  a process and reads the last JSON object it prints.

- **`[runtime].graph`**, optional, and meaningful only when
  `adapter = "langgraph"`. A LangGraph app may declare several graphs in its
  `langgraph.json`; this names the one this seat is. Unset is fine when the app
  declares exactly one; with several, the run refuses and names them, because
  picking one for the operator is a guess about which agent they hired.
  `epito validate` refuses `graph` beside any other adapter rather than letting
  a field quietly mean nothing.

**What is deliberately NOT in the manifest.** Nothing about the interpreter, the
virtualenv, the image, or where the framework is installed. Those are properties
of the box, and rule 1's spirit (a manifest is publishable without redaction)
extends to them: `EPITO_PYTHON` names the interpreter on the runtime, the way
`$EPITO_APP_KEY_<NAME>` names the App key. A manifest that named a path would
stop being portable at exactly the moment a second person ran it.

**Presence is a property of the adapter, not of the runtime.** A window and
`POST /message` hold a session id the agent's executor hands back. The claude
adapter has one; the langgraph adapter does not (a checkpointer is the agent's
own configuration, and epito does not configure the agent's insides). A
follow-up to a seat that holds no session runs the seat again with the message
as its prompt, and says so in the run log. No manifest field expresses this: it
follows from the adapter, and inventing `resumable = false` would let a manifest
claim a capability its agent does not have.

## Proposed in-band (the identity slice, cycle 1 bet 2)

Additive clarifications the mint (`epito token <name>`,
cli/src/lib/identity.js) forced into the open. Neither changes a rule;
both write down an answer the spec left to the implementation, which is
exactly the kind of thing that drifts if it stays unwritten.

- **A mapped scope grants write.** v0.1 says `[identity].scopes` map to
  fine-grained App permissions but never says at which access level. The
  mint reads them as:

  | scope | GitHub App permission |
  | --- | --- |
  | `github:contents` | `contents: write` |
  | `github:pull_requests` | `pull_requests: write` |
  | `github:issues` | `issues: write` |

  Write, because every one of the three seat shapes commits, opens PRs,
  or comments; a read-only agent is a reader, and nothing in v0.1 can
  express one yet (see the open question below). `metadata: read` is
  absent because GitHub grants it to every installation implicitly.
  Anything outside the table fails the mint loudly, naming the scope and
  the mapped set — the behavior v0.1 already requires of deploy, now
  real. The failure lands at the mint and not at `epito validate` on
  purpose: a stricter validator would refuse a running roster at startup
  over one word, and a live box is downstream of that choice.

- **`[runtime].repo` bounds the credential, not just the clone.** A
  minted token is scoped to exactly one repository, and `repo` is what
  says which. The field is already PROPOSED below as the resident
  runtime's clone target; this is a second, independent reason it is
  required in practice. `epito validate` still stays silent when it is
  absent (Actions-era manifests remain valid); `epito run` and `epito
  token` both refuse.

Nothing about an agent's App belongs in the manifest, and rule 1 is why:
the App id and private key are named by convention
(`$EPITO_APP_ID_<NAME>`, `$EPITO_APP_KEY_<NAME>`) and live on the runtime
box, so a manifest stays publishable without redaction.

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
- **Access levels in the scope grammar.** Every mapped scope grants write
  today (above), so a manifest cannot describe a read-only agent. The
  grammar already admits a modifier — `github:contents.read` parses — but
  inventing one before a real read-only agent exists is a guess. Decide
  with the second integration, alongside the non-GitHub grammar question
  above, so the two answers are designed together rather than in sequence.
- Team/roster fields stay OUT of the manifest (a roster references
  manifests, not the reverse) — confirm this survives contact with the
  dogfood migration.
