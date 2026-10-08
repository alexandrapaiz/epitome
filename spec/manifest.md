# The agent manifest (agent.toml), spec v0.2 — v0.1 frozen 2026-09-30, v0.2 opened 2026-10-07

One file is the whole agent. The manifest is the unit of everything that
comes later: a deploy is a manifest provisioned, a team is manifests with
a shared roster, a marketplace listing is a manifest published. The file
an agent carries is its **epitome**: the abridged, faithful cut of its
owner's authority.

A manifest has four tables. `[agent]` says who it is; the other three are
the definition of an agent itself (ADR-2): `[identity]`, `[trigger]`,
`[runtime]`. A manifest missing any of the three describes a skill, and
`epito validate` says so in those words.

**What frozen means.** A shipped version's vocabulary is closed. The field
catalogue below is the whole of the current one, and `epito validate` refuses
a key that is not in it — including a misspelling of one that is, which it
answers with the spelling. That refusal is the point of freezing: while fields were
still arriving in-band (five did, across six merged PRs), a validator that
rejected unknown keys would have rejected the manifest introducing each
one, so it ignored everything it did not recognise, and `max_turn = 50`
validated with a ✓ and then ran 120 turns. A new field now goes through the
next version — an open question below, then a spec change, then code, in that
order and never two of them at once.

**What v0.2 opened with: one field, `[[runtime.route]].base_url_env`.**
The freeze's process ran exactly as written, which is the only reason this
field is here. The question was recorded under "open questions" on
2026-09-30 and it named the shape it would probably take; the first real
roster (`agents/`, 2026-10-03) hit the wall it described — this company's
`pm`, `market` and `okr` seats take a cheaper road whose endpoint it holds
as a repository secret, so the road could not be written in a publishable
manifest at all and the three files declared one road each with a comment
saying why; and this spec change came before the code, in the same pull
request as it, so the catalogue and the validator could not disagree about
whether the field exists. Nothing else in v0.1's vocabulary moved. A
manifest that validated under v0.1 validates under v0.2, because the one
field is optional and no rule changed around it.

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
                                        # optional: the endpoint that speaks the model's API,
                                        # as a literal. For a public provider's published URL.
base_url_env = "OPENROUTE_BASE_URL"     # optional (v0.2): the NAME of the variable holding
                                        # that endpoint, for a road whose URL is itself
                                        # confidential. Must also appear in `env`, like
                                        # token_env; refused beside base_url, because two
                                        # endpoints for one road is a guess about which the
                                        # operator meant. Absent from the box = road skipped.
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

## `env`: names in the file, values on the box

`env` is the list the runtime injects **from**, and it injects only the names
the box it is running on actually holds. Three consequences, written down here
because each of them was found on a box rather than read in this document:

- **A name the box does not hold is dropped, and the run goes ahead without
  it.** That is what makes one roster portable across boxes — the same rule a
  road whose key is absent follows — and it is silent in a way a skipped road
  is not: a skipped road leaves the seat on another road, while a missing name
  leaves the seat running, exiting 0, and doing less than it was built to do.
  So the run log names what went missing, and `epito env <dir>` answers "what
  does this box owe each seat" per box, the way `epito routes` answers it for
  the model.

- **Nothing in a manifest says a name is REQUIRED.** v0.1 did not distinguish
  "the agent cannot work without this" from "the agent uses it if it is there",
  and v0.2 does not either. Both live in one list, and this company's own PM
  seat holds both kinds: its `LINEAR_API_KEY` is genuinely optional (the
  charter skips the mirror and says so) while its `BOARD_RUNTIME_TOKEN` is not.
  So no command refuses a box for being short of a name; `epito env --complete`
  is the *operator* asserting that this box should hold all of them, which is a
  box's claim and not a manifest's. Whether the distinction belongs in the
  manifest is an open question below.

- **A name set to an empty value is held, not absent.** The runtime injects it,
  empty, and the agent reads it and fails somewhere far away. It is the
  env-file twin of a `base_url_env` that does not hold a URL, and it gets the
  same treatment for the same reason: the box has this one and has it wrong, so
  `epito env` refuses by name rather than letting it read as a box that was
  never configured.

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
of them the field v0.2 opened with, now built, which is the whole case for
keeping a roster that nobody wrote for the validator's benefit.

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

Given a directory, `--for-runtime` also refuses a roster when the engine
`epito run <dir>` would connect to is not answering at `TEMPORAL_ADDRESS`
(ADR-24). That is not a rule about a manifest and it adds no field: it is the
flag's contract — refuse precisely what `epito run <dir>` refuses — and `epito
run` asks about the engine before it reads a seat. The default still exits 0
and still needs no engine, because whether a directory of files is a roster is
a filesystem question; what changed is that the verdict no longer answers for
`epito run` without having asked it.

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

A route is `name`, `model`, and optionally `base_url` *or* `base_url_env`,
`token_env` and `concurrency`. The runtime tries them in the order written and
the run takes the first one that starts it (ADR-19).

- **`token_env` is a name, never a value**, and rule 1 is why. It must also
  appear in `[runtime].env`: the runtime injects only the names the manifest
  lists, so an unlisted key could never resolve to a value anyway, and
  `epito validate` says that rather than letting a seat discover it at 06:00.
  A `base_url` carrying a credential in the URL is refused for the same reason.

- **An endpoint may be a name too (`base_url_env`), under exactly `token_env`'s
  rule.** Rule 1 forbids a *value* that cannot be published, and for some roads
  the URL is that value: a private gateway's address is the thing you are not
  supposed to know. So `base_url_env` names the variable holding it, must also
  appear in `[runtime].env`, and is **refused beside `base_url`** — a road with
  two endpoints is a guess about which one the operator meant, and rule 3's
  spirit (never default anything that changes behaviour silently) says guess
  nothing. `base_url` stays for the ordinary case, a public provider's
  published URL, because naming a variable to hold a URL anyone can read is
  indirection that buys nothing and costs a line in `env`.

  What this does NOT do is let the manifest describe which endpoint. "Which
  model is this company actually running on" was already a per-box question
  (the bullet below); it is now a per-box question for the address as well, and
  `epito routes` is still the one place either is answerable.

- **A route whose key is not on this box is skipped**, not failed: the same
  roster runs on a machine that holds a Moonshot key and on one that does not.
  That makes "which model is this company actually running on" unanswerable
  from the manifests alone, which is what `epito routes` answers, per box.

  A route whose `base_url_env` is unset is skipped the same way and for the
  same reason — an endpoint you do not have is a road you cannot take. One case
  is louder than a skip, though, and it is the operator's typo: a variable that
  IS set and does not hold an http(s) URL, holds one with a credential in it,
  or holds nothing at all. That road is closed with the reason named (the
  variable, and what is wrong with what it holds — never the value itself,
  which goes in no log), so "the gateway is misconfigured" cannot read as "the
  gateway is not configured here". Both sentences end in the same fallback;
  only one of them is a bug somebody has to go fix.

  "Holds nothing at all" is in that list because an env file is where these
  values live and `KEY=` is what a half-filled line looks like. A box that
  never had the road and a box whose line is blank are not the same box, and
  do not get the same sentence — in `epito routes` or in `epito env`.

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

## Open questions (settle before v0.3)

Five open, one answered by v0.2 and one answered by the dogfood. The two
struck-through entries stay struck rather than deleted: the record of what a
question asked for is how the next one gets judged.

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
- ~~A route endpoint that is a NAME, not a URL.~~ **Answered, and shipped as
  v0.2's one field, 2026-10-07: `base_url_env`.** The question asked for it on
  2026-09-30 and guessed the shape right — a name beside `token_env`, under the
  same rule, skipped like any other road the box cannot open — so the field is
  what the question described and nothing more. What building it added, which
  the question had not seen: the variable that is *set to something wrong* is a
  third outcome, not a second, and it is closed by name rather than skipped in
  silence (see the routes section). This company's `pm`, `market` and `okr`
  seats now declare the road they actually take, so the three comments
  explaining what could not be written are gone from `agents/`.
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
- **Whether `env` should say which names are required.** A seat's `env` is one
  flat list of names, and the box either holds a name or does not; nothing
  distinguishes a name whose absence costs a feature from one whose absence
  costs the seat its job. The evidence that the question is real is this
  company's own PM manifest, which names both kinds in one line (see "`env`:
  names in the file, values on the box"). The evidence that it should wait is
  that the shape is not obvious — a second list (`env_required`), a modifier on
  the name, or nothing at all, because a charter that reads a name it did not
  get is in a position to say so itself and is the only thing that knows what
  the name was for. Decide it with a seat that actually failed for want of a
  name, not before; until then `epito env --complete` lets the box assert what
  the manifest cannot.
- Team/roster fields stay OUT of the manifest — **holding so far**: the first
  real roster (`agents/`, five seats, 2026-10-03) needed no field that
  described the roster, only a directory. `epito run <dir>` discovers the
  files; nothing in a manifest references a sibling. Confirm again at dogfood
  step 2, when a seat's Actions wiring is actually deleted.
