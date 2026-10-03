# The agent manifest (agent.toml), spec v0.1 — FROZEN 2026-09-30

One file is the whole agent. The manifest is the unit of everything that
comes later: a deploy is a manifest provisioned, a team is manifests with
a shared roster, a marketplace listing is a manifest published. The file
an agent carries is its **epitome**: the abridged, faithful cut of its
owner's authority.

A manifest has four tables. `[agent]` says who it is; the other three are
the definition of an agent itself (ADR-2): `[identity]`, `[trigger]`,
`[runtime]`. A manifest missing any of the three describes a skill, and
`epito validate` says so in those words.

**What frozen means.** v0.1's vocabulary is closed. The field catalogue
below is the whole of it, and `epito validate` now refuses a key that is
not in it — including a misspelling of one that is, which it answers with
the spelling. That refusal is the point of freezing: while fields were
still arriving in-band (five did, across six merged PRs), a validator that
rejected unknown keys would have rejected the manifest introducing each
one, so it ignored everything it did not recognise, and `max_turn = 50`
validated with a ✓ and then ran 120 turns. New fields now go through
v0.2 — an open question below, then a spec change, then code.

The catalogue and the validator are one list in one place
(`FIELDS` in `cli/src/lib/manifest.js`, and `ROUTE_FIELDS` beside the
route reader in `cli/src/lib/router.js`). They cannot drift; the drift is
what let five fields land as prose without ever being checked.

## The field catalogue

Every field v0.1 has. **This is a catalogue, not a file to copy** — some
of these are mutually exclusive, and a TOML table must follow every plain
key of the table above it. To copy something, copy a seat shape: the three
below are real, complete, validating manifests.

```toml
[agent]
name = "historian"                      # required: [a-z0-9-], 1-40 chars, unique per roster
description = "Writes the daily digest" # required: one sentence, shown on the roster

[identity]
scopes = ["github:contents", "github:pull_requests"]
                                        # required, non-empty: platform:permission strings.
                                        # v0.1 platform: github. Mapped to fine-grained App
                                        # permissions by the table under "Scopes" below;
                                        # anything unmapped fails the mint loudly.

[trigger]                               # required: at least one of the two
cron = "0 6 * * *"                      # 5-field cron, UTC. The runtime registers a schedule.
                                        # Parsed by `epito validate`, not counted: five
                                        # impossible fields ("0 99 * * *") is refused here and
                                        # not left for `epito run` to discover.
webhook = true                          # the ingress may wake this seat: POST /hooks/<name>.
                                        # Without it the ingress refuses — a trigger is
                                        # explicit and never defaulted (rule 3).

[runtime]
model = "claude-sonnet-5"               # required: explicit, never defaulted (an unset model
                                        # is silently under-modeled — alexandria incident 9)
entry = "prompts/historian.md"          # required: the charter file, a path inside `repo`
repo  = "owner/historian"               # the GitHub repository a run happens in: the runtime
                                        # clones it fresh, reads `entry` inside the clone, and
                                        # hands the clone to the agent as its working directory.
                                        # Also what bounds the minted token to one repo.
                                        # `epito validate` accepts it absent (Actions-era
                                        # manifests stay valid) and SAYS so: `epito run`,
                                        # `epito ps <dir>`, `epito deploy` and `epito token`
                                        # all refuse without it, so the ✓ names them instead
                                        # of implying they will not.
ref   = "main"                          # optional: branch or tag the runtime checks out;
                                        # unset = the repository's default branch
adapter = "claude"                      # optional: which KIND of agent this is. "claude" (the
                                        # default, and what every manifest written before this
                                        # field means) or "langgraph".
graph = "agent"                         # optional, and meaningful ONLY with adapter =
                                        # "langgraph": which graph in the agent's own
                                        # langgraph.json this seat is. Refused beside any other
                                        # adapter rather than quietly meaning nothing.
max_turns = 120                         # optional: run cap, default 100
env = []                                # optional: names of secrets the runtime injects;
                                        # values never appear in the manifest, ever
slack_webhook_env = "SLACK_WEBHOOK_URL_EPITOME"
                                        # optional: the NAME of the webhook secret this
                                        # agent's one-line post goes to, so a product seat
                                        # speaks in its own channel. Must also appear in `env`.
                                        # Unset = the runtime's default SLACK_WEBHOOK_URL, or
                                        # no post if that is not in `env` either.

[[runtime.route]]                       # optional, repeatable: the roads to a model, in the
name = "open"                           # order the runtime tries them. A run takes the first
model = "kimi-k2-turbo-preview"         # one that starts it. No route table at all = one road,
base_url = "https://api.moonshot.ai/anthropic"
                                        # optional: the endpoint that speaks the model's API
token_env = "MOONSHOT_API_KEY"          # optional: the NAME of the key that opens it, which
                                        # must also appear in `env` — never the key itself
concurrency = 1                         # optional: how many of one box's runs may be on this
                                        # road at once
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
   silently: model, scopes, and triggers have no defaults. A seat that
   did not ask to be woken by the ingress is not woken by it.
4. **One manifest, one principal.** Deploying the same file twice updates
   the same agent; renaming creates a new one. Identity follows `name`.

## The three seat shapes

v0.1 was frozen by trying it against the three shapes every roster so far
has turned out to contain. They live as real manifests, and the test suite
validates all three and asserts that **every field in the catalogue is
needed by at least one of them** — a field no real shape needs is a field
that did not earn its place, and the test names it
(`cli/test/unit.mjs`, "every field in the frozen catalogue is needed").

| Shape | File | What it exercises |
| --- | --- | --- |
| **Daily builder** — wakes on a schedule, writes code, leaves a PR | `cli/test/fixtures/shapes/daily-builder/agent.toml` | `cron`, `max_turns`, `slack_webhook_env`, the full route chain |
| **Weekly writer** — wakes weekly, writes prose | `cli/test/fixtures/shapes/weekly-writer/agent.toml` | `ref`, and how few fields a real seat needs |
| **Event-driven responder** — no schedule; answers what happened | `cli/test/fixtures/shapes/event-responder/agent.toml` | `webhook`, `adapter`, `graph`, a non-GitHub-write scope set |

The second shape is the one that does the work. Shape 1 asks whether the
manifest can express a complicated seat; shape 2 asks how little a real
seat needs, and every field absent from it had to justify itself against
one of the other two or go.

All three are fixtures, written by the same people who wrote the validator.
Since 2026-10-03 there is also a roster that is not: `agents/` holds this
company's own five seats, translated from the Actions workflows that have been
running them for weeks (`agents/README.md`). It is the stronger evidence, and
it is where the three "what did not translate" findings below came from — one
of them a field v0.2 probably needs.

## Scopes

`[identity].scopes` map to fine-grained GitHub App permissions. v0.1 maps
three, at write:

| scope | GitHub App permission |
| --- | --- |
| `github:contents` | `contents: write` |
| `github:pull_requests` | `pull_requests: write` |
| `github:issues` | `issues: write` |

Write, because every one of the three seat shapes commits, opens PRs, or
comments; a read-only agent is a reader, and nothing in v0.1 can express
one yet (see the open questions). `metadata: read` is absent because
GitHub grants it to every installation implicitly.

Anything outside the table fails **the mint**, naming the scope and the
mapped set — not `epito validate`. That placement is deliberate: a
stricter validator would refuse a running roster at startup over one
word, and a live box is downstream of that choice.

What that placement costs is a ✓ on a manifest the mint will refuse, so
`epito validate` **notes** the unmapped scope without failing on it — and the
same for an absent `[runtime].repo`. The rules belong to the other commands;
`cli/src/lib/readiness.js` holds them once and the validator reads them out,
so its tick is honest about what it did not promise. `epito validate
--for-runtime` turns those notes into an error and exits 1, for CI that wants
the stricter rule; the default stays exit 0, because these files are valid
v0.1 manifests and a validator that refused them would break every
Actions-era manifest on purpose.

Nothing about an agent's App belongs in the manifest, and rule 1 is why:
the App id and private key are named by convention
(`$EPITO_APP_ID_<NAME>`, `$EPITO_APP_KEY_<NAME>`) and live on the runtime
box, so a manifest stays publishable without redaction.

## Adapters: what kind of agent this is

`[runtime].adapter` is a *kind*, not a command: the manifest never names an
executable, because a manifest is publishable and a path on somebody's box
is not. `epito validate` refuses a value outside the set, listing the set
and what each member is (ADR-17).

The field exists because the runtime had exactly one agent shape hard-coded
into it, which contradicts the promise that epito runs the agent you already
have (R4, ADR-10). An adapter adds no dependency to the product: epito spawns
a process and reads the last JSON object it prints.

`[runtime].graph` names one graph in a LangGraph app that declares several.
Unset is fine when the app declares exactly one; with several, the run
refuses and names them, because picking one for the operator is a guess
about which agent they hired.

**Presence is a property of the adapter, not of the runtime.** A window and
`POST /message` hold a session id the agent's executor hands back. The claude
adapter has one; the langgraph adapter does not (a checkpointer is the agent's
own configuration, and epito does not configure the agent's insides). A
follow-up to a seat that holds no session runs the seat again with the message
as its prompt, and says so in the run log. No manifest field expresses this: it
follows from the adapter, and inventing `resumable = false` would let a manifest
claim a capability its agent does not have.

## Routes: which road to the model

A route is `name`, `model`, and optionally `base_url`, `token_env` and
`concurrency`. The runtime tries them in the order written and the run takes
the first one that starts it (ADR-19).

- **`token_env` is a name, never a value**, and rule 1 is why. It must also
  appear in `[runtime].env`: the runtime injects only the names the manifest
  lists, so an unlisted key could never resolve to a value anyway, and
  `epito validate` says that rather than letting a seat discover it at 06:00.
  A `base_url` carrying a credential in the URL is refused for the same reason.

- **A route whose key is not on this box is skipped**, not failed: the same
  roster runs on a machine that holds a Moonshot key and on one that does not.
  That makes "which model is this company actually running on" unanswerable
  from the manifests alone, which is what `epito routes` answers, per box.

- **`concurrency` is a property of the road, not of the seat.** A prepaid tier
  that allows one request at a time is a single-lane road, and two seats that
  take it at the same moment both die at turn one. One worker serializes its
  own runs on that road; a second worker host is a second counter, and the
  engine-side fix is an idea, not a claim (docs/ideas.md).

**Falling back is bounded by what the agent did, not by what the provider
said.** The runtime takes the next road only when the attempt ended with no
pull request and at most one turn — a run that never started. A run that
reached turn nine and failed is the agent's own outcome and is never started
again somewhere else, for the same reason `execute` is never retried: a run
that half-happened has already pushed commits.

**A held session belongs to the road that made it.** A window records the route
its opening run took, and every follow-up message lands on that road with no
fallback: `--resume <id>` at a different endpoint is a stranger being handed a
conversation it never had.

## What is deliberately NOT in the manifest

Nothing about the interpreter, the virtualenv, the container image, or where
the framework is installed. Those are properties of the box, and rule 1's
spirit (a manifest is publishable without redaction) extends to them:
`EPITO_PYTHON` names the interpreter on the runtime, the way
`$EPITO_APP_KEY_<NAME>` names the App key. A manifest that named a path would
stop being portable at exactly the moment a second person ran it.

Team and roster fields stay out too: a roster references manifests, not the
reverse.

## What the freeze retired

Two fields the v0.1 draft carried and the review removed. Both are refused
by name, with the reason — a reader who copied one out of the draft is owed
better than "unknown field".

- **`[trigger].on`** (platform event subscriptions). Nothing in v0.1
  subscribes to platform events and nothing filters on them, so the field
  could not change what happened: a hook runs the seat whatever event it
  carried. Worse, a manifest whose only trigger was `on` passed `epito
  validate` with a ✓ and was a seat that could never fire — the triad rule
  accepted it as a trigger and no schedule was ever registered for it. It
  returns with `epito deploy`, which is the command that would do the
  subscribing; see the open questions.

- **`[runtime].image`** (container image). Zero consumers anywhere in the
  tree, and the section above already says an image is a property of the
  box. Keeping it would have been the spec contradicting itself in two
  places one screen apart.

## Open questions (settle before v0.2)

- Scope grammar for non-GitHub platforms (`asana:tasks.write`?
  `postgres:read/dbname`?) — decide with the second integration, not
  before, per the backlog.
- **Access levels in the scope grammar.** Every mapped scope grants write,
  so a manifest cannot describe a read-only agent. The grammar already
  admits a modifier — `github:contents.read` parses — but inventing one
  before a real read-only agent exists is a guess. Decide with the
  non-GitHub grammar question above, so the two answers are designed
  together rather than in sequence.
- **Event subscription, and the shape of `[trigger].on`'s replacement.**
  `webhook = true` says the ingress may wake a seat; nothing says *what*
  may wake it, so the filtering lives in whatever points at the hook.
  Settle it with `epito deploy` (which is what would register a
  subscription), and decide then whether filtering belongs in the manifest
  at all or is the platform's job.
- **A route endpoint that is a NAME, not a URL.** `token_env` names the key
  that opens a road because rule 1 forbids the value; `base_url` is still a
  literal, and that is where the first real roster hit the wall. This
  company's own `pm`, `market` and `okr` seats take a cheaper road whose
  endpoint it holds as a repository secret (`OPENROUTE_BASE_URL`), so the road
  cannot be written in a publishable manifest at all — the three manifests in
  `agents/` declare one road each and say so in a comment. The shape is
  probably `base_url_env`, beside `token_env` and under the same rule: a name
  that must also appear in `env`, skipped like any other road whose
  credential is absent from the box. Not added here, because v0.1 is frozen
  and the freeze's point is that a field arrives through a question, then a
  spec change, then code — this is the question. Decide with v0.2.
- ~~Whether `[trigger]` combinations compose (cron + webhook on one agent,
  which v0.1 permits and no shape yet uses) or v1 forces exactly one.~~
  **Answered by the dogfood, 2026-10-03: they compose, and the ordinary seat
  needs both.** Every one of this company's five workflows can be fired by its
  clock *and* by hand (`workflow_dispatch`), and on the runtime the second one
  is the ingress — so four of the five manifests in `agents/` carry `cron` and
  `webhook = true` together, and the fifth carries only the webhook because
  its schedule block is commented out. Forcing exactly one would have made the
  first real roster unexpressible. v0.1's permissiveness here was right;
  nothing to change.
- Team/roster fields stay OUT of the manifest — **holding so far**: the first
  real roster (`agents/`, five seats, 2026-10-03) needed no field that
  described the roster, only a directory. `epito run <dir>` discovers the
  files; nothing in a manifest references a sibling. Confirm again at dogfood
  step 2, when a seat's Actions wiring is actually deleted.
