# Decisions

Architectural and organizational decisions, recorded with alternatives
and why, per the agent-company playbook. Owner's merge is ratification.

## ADR-1: The product is the identity+trigger+runtime primitive

Owner's decision (2026-09-18). The company builds one thing: the primitive
that mints an agent — a real principal (scoped, revocable, non-personal
credentials with audit), a trigger surface (cron/webhook/event), and a
persistent container — from a single manifest with a single deploy
command. Alternatives considered and rejected: an identity-only layer
(a database row without a body; the runtime is what makes autonomy real),
and the five-layer platform (identity, runtime, interop, convening,
marketplace) as co-equal pillars — rejected because it is five startups.
Interop ships integration-by-integration as part of identity (per-agent
OAuth grants, GitHub first). Marketplace, teams, and convening are later
features that emerge from accumulated manifests.

## ADR-2: Agent means identity + trigger + runtime; skill means neither

Owner's definition (2026-09-18), doubling as product spec and future
marketplace bar. An agent is *someone* (its own identity, never the
owner's token), *autonomous* (woken by cron, webhook, or event — not by a
prompt), and *resident* (its own container, outliving any session). A
skill is a capability loaded into someone else's identity and runtime,
run when prompted. Anything failing the three-part test is a skill and
does not belong in the agent repository.

## ADR-3: Name epito.me, explicitly subject to change

Owner's decision (2026-09-18) after a naming session (multipse, somos,
nosismo, multitudes, marque, tessera considered; shortlist preserved in
the parent-company memory). Epitomē — Greek "a cutting-upon": an
abridgment that faithfully stands in for the whole — names the mechanism
(a scoped credential is an abridgment of the owner's authority) and the
aspiration (each agent the epitome of one function of its owner). Domain
epito.me verified available 2026-09-18, not yet registered (owner action).
CLI verb `epito`; `epito me` aliases `epito init`. The name is held
loosely: revisit before any public launch.

## ADR-4: The company runs on the agent-company playbook

Owner's standing instruction: new projects reuse the playbook (canonical
at alexandria docs/playbook.md; bootstrap steps at its end) rather than
ad-hoc prompting. Seats arrive in the playbook's order — mission first
(done, vision §0), then OKR, PM, ExO, builders, market — each smoke-run
supervised before its cron is trusted. Workflow gotchas from alexandria's
incident register apply from day zero: id-token write, bypassPermissions,
explicit --model, draft-PR-first. Secrets are owner-only, starting with
CLAUDE_CODE_OAUTH_TOKEN.

## ADR-5: Shape Up trial on the PM seat; Linear as the board

Owner's decision (2026-09-18): epito.me's PM seat runs Shape Up instead
of the playbook's minimal Scrum, as a deliberate A/B — alexandria stays
on Scrum, and the owner judges which she likes more. This amends ADR-4's
playbook adoption for the PM seat only, and follows the frameworks
register's own rules (one trial at a time, kill-by-default review date).
Terms, adapted to this org's scale: two-week cycles with a two-day
cooldown; the PM shapes pitches (problem, appetite, rough solution,
rabbit holes, no-gos); the OWNER is the betting table and bets by
merging the PM's betting memo; appetite is fixed and scope is variable;
unfinished work does not roll over without a fresh bet (the circuit
breaker); progress is reported as hill charts inferred from the
engineer's PRs, never as percentages. Review at the end of cycle 2: the
owner compares against alexandria's Scrum on ceremony cost, quality of
what shipped, and which one she'd rather read on Monday — killed by
default if unjudged. Linear is the PM's board (a mirror only; the repo
stays the source of truth, exactly as the playbook's board rule
states), through an owner-made LINEAR_API_KEY secret; when the secret
is absent the PM notes it and skips the mirror, never fails the run.

## ADR-6: Integrations are surfaces, never dependencies; Linear rejected as #2

Owner's ruling (2026-09-18): "i dont think we should depend on
linear." Two effects. First, the verdict on the market seat's standing
recommendation: Linear is REJECTED as integration #2. The runner-up
(Vercel) does not inherit the slot automatically — the market seat
re-justifies the ranking under this ADR's principle in its 10-02
integration-map refresh, and the owner rules again. Second, and
larger, the principle the ruling encodes, now product law: **an
integration is a surface the agent shows up on, never a load-bearing
dependency of the core.** The provider architecture already embodies
this (platforms exist only behind the three seams) and this ADR pins
it: core, the CLI, the MCP server, and epitod must work with zero
integrations installed beyond whichever identity target the USER
chooses; no epito.me feature may require a specific third-party
product to exist. Scope note: this governs the product. The org's own
PM board on Linear (ADR-5) is an ops tool of this company, not a
product dependency, and stands until the owner says otherwise.

## ADR-7: Slack accepted as integration #2; WhatsApp and WeChat enter the map

Owner's verdict (2026-09-19) on the market seat's rev-2 re-rank:
"yes i love slack for agents." Slack is integration #2 — the
SlackProvider mints a per-agent app via `apps.manifest.create`
(structurally the GitHub provider's manifest-conversion flow), bot
user as the principal, workspace OAuth install, manifest scope
grammar `slack:chat.write` settling v0.2's second-platform question.
Distribution stays optional per ranking law 4 (unlisted per-workspace
install is self-serve). The PM shapes the pitch for the cycle-2
betting table; no mid-cycle bet (ADR-5 circuit rules).

Owner addition, same breath: "id even consider whatsapp group chats
too and wechat for international markets." Both enter the market
seat's research queue for the next brief revision: WhatsApp Business
Platform (group-chat agents) and WeChat (official accounts /
mini-programs) as international-market surfaces, evaluated under the
four ranking laws like everything else. Ledger entries carry them.

## ADR-8: The agent is the identity, not the model

Owner's doctrine (2026-09-19), verbatim: "im a big fan of agent
routing, so agents should not be models necessarily but the
identities." An agent's self is its identity — its principal, scopes,
name, and audit trail — and the model is a routable runtime parameter
beneath it. The same agent may run on different models per task,
cost, or escalation policy (the playbook's routing levers, HQ
ADR-015's open-source routing) without changing who it is anywhere it
acts.

Design consequences, binding:
1. `[runtime].model` names today's brain, never the agent's identity;
   manifest v0.2 may accept a routing policy in its place (e.g. a
   model list with an escalation rule). Identity fields never move
   with it.
2. The audit entry gains a `model` field: every action attributes to
   the identity AND records which model executed it, so routing
   changes stay visible in the trail.
3. No provider, platform mapping, or roster surface may key on the
   model; everything keys on the principal. A model swap is invisible
   to every integration.

This sharpens ADR-2 rather than amending it: identity + trigger +
runtime define the agent; the model is a detail of the runtime leg.

## ADR-9: Messaging is a category; we are the car, not the driver

Owner's direction (2026-09-19), verbatim: "slack is one option. we
can have several messaging platforms. additionally, the point is
integration: how can we help integrate all companies that make
agents? we dont necessarily want to be agent builders, we want agent
cars. also open claw is a big think to look into as well as gpt
astra."

Three effects:

1. **Messaging is a provider family, not a pick.** Slack (ADR-7) is
   the FIRST MessagingProvider, not the only one; WhatsApp, WeChat,
   Discord and kin are siblings evaluated by the same laws. The
   manifest's scope grammar for messaging should generalize across
   the family rather than hardcode Slack.
2. **Positioning: the vehicle layer for everyone else's agents.** We
   do not compete with companies that build agents; we integrate
   them. Any agent built anywhere (OpenClaw's, OpenAI's, a CrewAI or
   LangGraph crew, another company's product) should be able to get
   its identity, containment, and platform presence from epito.me —
   the car its driver rides in. This raises agent-framework
   integrations to first-class roadmap material and elevates A2A
   agent-card interop from someday to a tracked consideration
   (agents made by others must be able to carry our identity).
3. **Research dispatched**: OpenClaw as a big opportunity (its crisis
   is precisely our product's absence — can epito.me be the identity
   and containment layer FOR OpenClaw agents, and what would that
   integration or channel look like); and "GPT Astra" (identify what
   the owner is pointing at — verify against OpenAI surfaces and
   Google's Project Astra — and assess under the ranking laws).

ADR-6 still governs: every framework we integrate is a surface,
never a dependency, and ADR-2's triad test still defines what counts
as an agent regardless of who built it.

## ADR-10: Portability for all agents, never a better agent

Owner's law (2026-09-19), verbatim: "the biggest problem would be to
try to generalize or centralize agents because new agent inventions
are going to be made and all the companies are going to release
their agents. So we don't want to make our version of that. And
propose a better agent. That's not what we want to do. We want
portability for all the agents every company does."

Binding consequences:

1. epito.me never defines what an agent's insides should be: no agent
   framework, no orchestration library, no opinion on brains, tools,
   memory, or prompting. The manifest is an ENVELOPE (identity,
   trigger, runtime) around whatever the maker built, never a format
   for the agent itself.
2. The adapter runtime (proposal C) runs foreign agents UNMODIFIED —
   that property is the point, not a convenience.
3. The passport (proposal B) binds identities without requiring our
   runtime, our manifest internals, or anyone's migration.
4. Any feature that only works if the agent was "built the epito way"
   is a violation and dies in review. New agent inventions appearing
   is the expected environment, not a threat: each one is a future
   passenger.

Owner's signal on the proposals, recorded without forcing a ranking:
B (the passport) is her favorite ("already adopted... I like the
concept of an agent passport"); C also liked. The PM sequences all
four at the cycle-2 betting table; B's prototype is pulled forward
in priority per this signal.

## ADR-11: Customer #1 is the owner's own company; chat is visibility, git is collaboration

Owner's direction (2026-09-20, relayed from the Alexandra Systems
session, verbatim): "Agents showing up in a chat as themselves — their
own identity, their own permissions, able to receive an @-mention and
act — is exactly Epitome's thesis, and it's the best possible demo of
it. But the product is the identity, not the chat room. Phase 1 needs
no identity infrastructure at all (each seat is a webhook with a name
and an emoji). Phase 2, after Epitome's cycle 1 ships
deploy-identity-v0, upgrades every seat to a real principal that can
be talked to, not just heard from. That's Epitome dogfooded on your
own company, which is a far better first customer than a stranger."
And: "we should get to building because i need this product myself
really... chat spaces for agents are just for visibility, agents
collaborate a lot better through blackboard and git."

Consequences:

1. **Dogfood customer #1 = Alexandra Systems HQ's seats** (in
   addition to the alexandria-seat migration already on the backlog).
   HQ's chat presence phase 1 (webhook + name + emoji) needs nothing
   from us; phase 2 (each seat a real principal, @-mentionable) is
   epito's deploy-identity-v0 plus the MessagingProvider. Sequencing:
   cycle 1 ships identity; the HQ upgrade is the first consumer of
   the Slack/messaging pitch at the cycle-2 table.
2. **Chat is a visibility surface, never a coordination bus.** The
   MessagingProvider's contract is: post as yourself, be @-mentioned
   to receive an instruction, thread a reply. Agents coordinate
   through the repo (blackboard) and git, exactly as the playbook
   says; no agent-to-agent chat protocols in the product. This is a
   design constraint on proposal D, not a feature request.
3. **Urgency: the owner is the user.** "I need this product myself"
   is the demand signal; the build starts with EPI-4 as planned, and
   the roadmap's first milestone after identity is the HQ upgrade.

## ADR-12: LangSmith is a standing watch — integrate or outdo, never ignore

Owner's ruling (2026-09-20), verbatim: "thats why we need to observe
langsmith then. we cant pretend it doesnt exist. we either find a way
to integrate or outdo."

Context: market §8 found LangChain building a credential layer inside
its hosted runtime at speed (Fleet agent identity 2026-03, Agent Auth
beta, per-caller identity 2026-08, Connections 2026-09-09). Every
piece still resolves to a stored shared key or the invoking human's
OAuth — no agent gets its own principal on outside platforms — so the
whitespace stands, but their own words call it "the basis for future
credential patterns."

Decision: LangSmith/LangChain moves from a tiered integration target
to a **named strategic watch**, the first of its kind, with two arms
that run in parallel rather than as alternatives:

1. **Integrate** (the surface arm, proposal A): `langchain-epito` and
   the OTLP attribution export ship as planned — build-next behind
   Slack. Their OSS LangGraph is a passenger; their hosted runtime
   gets recipes, never dependency (ADR-6).
2. **Outdo** (the moat arm, proposal B): the passport — signed,
   cross-platform identity binding — is the thing LangChain's
   vault-shaped design cannot produce without abandoning the vault.
   Its prototype is pulled forward to sit alongside the Slack work,
   not behind it: the outdo arm must be visible before their next
   credential release, not after.

Decision rule (tripwire, market seat owns it, checked every Friday
run): if LangChain ships any mechanism where a LangSmith-deployed
agent acts on GitHub, Slack, or any outside platform under its OWN
principal (not a shared key, not the human's OAuth), the market seat
escalates to the owner within the same run and the betting table
convenes out of cycle — the one exception to ADR-5's no-mid-cycle
rule, granted here in advance.

Register note: LangSmith joins Cloudflare Agents SDK and Anthropic
Managed Agents as a wedge-adjacent watch item, but is the only one
with a pre-authorized out-of-cycle response, because it is the only
one already shipping credential features monthly.

## ADR-13: Two buyers — the builder with a roster, and the agent-maker itself

Owner's direction (2026-09-20), verbatim: "i want a product that
would serve companies even like langchain."

The gap (vision §1) is unchanged; the buyer set doubles. Buyer 1 is
the builder running a roster of agents (vibecoder, HQ, the owner
herself). Buyer 2 is the agent-maker: the company that hosts or
frameworks other people's agents (LangChain, OpenClaw's foundation,
the hosted builders) and must answer how those agents authenticate to
the outside world without building a cross-platform identity system
of its own. epito supplies that answer as embeddable infrastructure.

Consequences:
1. **The issuer is a product, not a phase-3 afterthought.** Buyer 2
   needs a callable service: mint a principal for this agent, hand it
   a short-lived token, verify its passport. The all-hands engineer
   counsel (no token server before phase 3) stands for buyer 1's
   local-first path; the issuer for buyer 2 is sequenced by the PM as
   its own pitch once the passport mechanism exists, because the
   passport is what a platform embeds first.
2. **ADR-12 gains a third arm: supply.** Integrate (langchain-epito),
   outdo (the passport), and supply (be the provider their Connections
   resolve to, so their agents get outside principals through us
   rather than by their own build). The tripwire stays.
3. **The passport must be an open spec with a reference
   implementation**, adoptable by a platform without depending on
   this company (ADR-6 pointed at ourselves). Trust is the hard part
   of buyer 2; a standard earns it, a startup does not.
4. Market seat adds a column to the universe map: for each
   agent-maker, "as customer" alongside "as surface." Pricing rev 2
   must price buyer 2 (platform/issuer tier) separately from roster
   tiers.

## ADR-14: Mission signed; the Omarchy craft standard

Owner (2026-09-20): "lets adopt the mission." Vision §0 now reads
"Give every agent, whoever built it, a self its owner holds and every
platform honors." All-hands ruling R1 closed; the OKR seat grades Q4
against it from today.

Same breath, the craft bar: "epito isnt supposed to be only
vibecoders at the loveable level. i want a true piece of
engineering... most programmers today are vibecoders. i want
something on the level of omarchy." Recorded in vision §0b as the
standard every layer is judged by: serious systems engineering that a
newcomer installs in one command and can understand by reading —
easy from craft, never from a veneer. Omarchy is the named exemplar
(and, per the ideas ledger, a channel and runtime target). This
retires "sold to vibecoders" as the mission's closing phrase without
retiring vibecoders as the audience: they are most programmers now,
and they deserve real engineering.

## ADR-15: Temporal self-hosted is the runtime engine; epitod is its face

Status: proposed 2026-09-26 by the engineer seat, on the owner's
directive of 2026-09-25 recorded at HQ as ADR-036 ("i need the runtimes
to be working ... for all four companies ... and the seats active.
almost fully autonomous"). The owner ratifies by merging the
implementing PR. The full argument, written Working Backwards before
the code, is docs/prfaq/epitod-v1-temporal.md.

**Decision.** The durable-execution engine under epitod is Temporal,
self-hosted on the company host at `127.0.0.1:7233`. epitod is the
face: manifests, agent identity, and the vocabulary an owner reads.
Temporal Cloud is rejected permanently.

**Why.** epitod v0 hand-built four things inside one Node process
(`cli/src/run.js`): a cron scheduler, a per-seat mutex with coalescing,
a retry story, and a crash story. Those four things are a workflow
engine, and the version we wrote had one silent defect that mattered
more than the rest — a run in flight when the host rebooted was simply
gone, with nothing in the system aware it had existed. The mapping to
Temporal is one-to-one, which is why this was a port and not a rewrite:
`[trigger].cron` is a Schedule, the mutex is
`ScheduleOverlapPolicy.BUFFER_ONE`, a run is a workflow over four
activities with declared retries, and presence is a long-running
workflow holding a session id.

**Consequences.**

1. **The dependency budget for epitod changed**, from "none targeted"
   to four `@temporalio/*` packages plus a server we operate. The
   justification line is in docs/architecture.md, as that document's own
   rule requires. This is the first load-bearing runtime dependency the
   product has taken, and it is taken knowingly.
2. **ADR-6 is honored by construction, not by promise.** The engine is
   a swappable backend, and the test that it stayed swappable is
   mechanical: `.epito/audit.jsonl` and `cli/src/temporal/activities.js`
   carry no Temporal type, and the manifest spec carries no Temporal
   concept. If a future ADR replaces the engine, the product's record
   survives it unchanged.
3. **No Temporal word may reach a product-facing string.** An owner
   reads about seats, runs, windows and manifests. `schedule`, `signal`
   and `task queue` live in `cli/src/temporal/` and in the design doc.
   A violation of this is an ExO trigger, not a style note.
4. **The runtime leg still costs zero dollars**, which was a condition
   of the directive. The server is two containers on the host's existing
   Postgres.
5. **A new security rule, because the engine persists its inputs.**
   Temporal writes every workflow and activity argument to its database
   in plain text. No secret value may ever be one. The manifest — which
   spec rule 1 already makes publishable without redaction — is what
   crosses that boundary, and the worker process reads secret values
   from its own environment at the last moment. This is why the manifest
   being publishable turned out to be load-bearing twice: once for the
   future marketplace, once for the engine's database.
6. **The Node SDK, not Python**, because the `execute` activity's whole
   job is to wrap `cli/src/lib/runner.js`, which already works. The
   Python alternative is named in the PR/FAQ along with what it would
   cost, and the cost is confined to `cli/src/temporal/`. Revisit when a
   second executor arrives, not before.
7. **`.epito/state.json` is retired.** `epito ps` reads the engine. Two
   copies of what is running is one copy that can be wrong.

## ADR-16: The board's store is an append-only event log, not a database and not a repo file

**Date.** 2026-09-27. **Status.** Proposed by the engineer seat; the
owner ratifies by merging, objects by editing.

**Context.** Owner directive 2026-09-26 (synchronous session, relayed
by the chair), priority 1 of four: "the task manager/board that
replaces Linear — own store; seats cannot create views; run reports
live on the board." The PM wrote it up Working Backwards
(`docs/prfaq/task-board-v0.md`, PR #12) and left the storage engine
open, naming two candidates and saying the engineer decides and records
a route ADR, the way bet 1a did for the GitHub App route. This is that
ADR.

**Decision.** The board's store is `.epito/board.jsonl`: append-only,
one JSON object per line, on the host the runtime runs on, folded into
the board on read. Its schema is `KINDS` in `cli/src/lib/board.js` and
the writer refuses any field not in it.

**Why not the two candidates.**

1. **A repo-tracked file, the way `docs/cycles/` is.** Seats cannot
   push to main — that is in every charter — so every run report would
   be a pull request waiting on a human merge, and the board would show
   nothing that had happened since the last one. This is not
   hypothetical: on the day this shipped, four engineer PRs were open
   and nothing had merged since 2026-09-24, so a repo-tracked board
   would have been three days blind about the seat doing the most work.
   A board that is stale exactly when the company is busiest is the
   Linear failure again with different plumbing.
2. **Postgres beside the engine.** The runtime's Temporal server
   already has one on the company host, so this costs nothing *there* —
   and that is the trap. `epito` is a product other people run, and its
   promise is that `epito run` works on a laptop for nothing (ADR-6,
   the $0 stack). A board that needs a database makes the CLI
   unrunnable without one. ADR-15 took the product's first load-bearing
   runtime dependency knowingly and wrote down what it cost; taking a
   second one for a table of run reports is not the same trade.

**Why an event log specifically.** Both candidates would have been
built on a stream of appended events anyway. Keeping the stream is what
makes the choice reversible: if the board outgrows a file, the events
replay into whatever comes next and `foldBoard` is the only code that
changes. It is also the shape the product already trusts — ADR-15's law
8 keeps `.epito/audit.jsonl` engine-agnostic for exactly this reason,
and a single-line `O_APPEND` write is atomic on Linux, which is why two
epitod processes can share one ledger without a lock.

**Consequences.**

1. **The board and the audit log are two files and one call.** They
   answer different questions — the audit log answers "what exactly
   happened, including the six lines nobody reads until something is
   wrong"; the board answers the owner's question, "what have the seats
   been doing" — and `record` writes both, which is what keeps them
   agreeing. The board holds run reports and notes, and nothing else.
2. **"Seats cannot create views" is code, not a promise.** `boardEvent`
   refuses an unknown field by name and says where the meaning belongs
   instead. A seat can fill the board in and cannot widen it because
   its own run happened to have one more fact in it.
3. **The board is not a second source of truth for the plan.** Bets,
   scopes and hills stay in `docs/cycles/` (ADR-5), as the PR/FAQ says.
   v0 renders run reports, not the cycle. Rendering the cycle file on
   the board is a later slice and a decision of its own; a parser for
   this company's markdown conventions is not product code, and
   shipping a bad one would put a wrong hill in front of the owner.
4. **One board, including seats epitod does not host.** Reports arrive
   at `POST /board` over the ingress that already exists, so the seats
   still running as GitHub Actions jobs file onto the same board as the
   ones on the runtime. The alternative — a board that only knows the
   seats already migrated — would make the board useless for exactly as
   long as the migration takes.
5. **Reading it needs no engine.** `epito board` is a file read. When
   Temporal is down, the board still says what the seats did before it
   went down, which is when an owner most wants to know.

## ADR-17: A foreign agent is hosted by a spawn contract, never by an SDK integration

**Date.** 2026-09-27. **Status.** Proposed by the engineer seat; the
owner ratifies by merging, objects by editing.

**Context.** Owner directive 2026-09-26 (synchronous session, relayed by
the chair, recorded in `docs/sprints/dispatch-queue.md`), priority 3 of
four: "the LangGraph implementation with tracing (Phoenix is
installed)". Priority 1 was the board (ADR-16), priority 2 the engine
(ADR-15). Until this card, epitod could host exactly one kind of agent:
`cli/src/lib/runner.js` spawned `claude` and hard-coded that CLI's
flags, so a seat whose agent is a LangGraph app could not run at all —
epitod would have spawned it with `-p <prompt> --permission-mode
bypassPermissions`. That is the opposite of R4 and ADR-10: the product's
promise is that it runs the agent you already have.

**Decision.** An agent kind is an **adapter**: a named entry in
`cli/src/lib/adapters.js` that turns one run's facts into one command to
spawn, and nothing else. `[runtime].adapter` names it in the manifest —
`"claude"` (the default, and the behaviour every existing manifest
already gets) or `"langgraph"`. epito depends on no framework SDK, links
no framework library, and imports nothing from the agent's language.
Every adapter returns the same three things — a file to spawn, its
argv, and the extra environment for that one child — and every adapter
speaks the same result contract: the last JSON object the child prints,
read for `session_id`, `num_turns` and `result` (the shape
`claude --output-format json` already emits).

**Why not a LangGraph integration.** The obvious build is the one ADR-12
calls the integrate arm: a `@epito/langchain` package a graph author
imports. It is a fine distribution play and it is the wrong thing to put
under the runtime, for three reasons.

1. **It requires changing the agent.** R4 and ADR-10 both say the first
   agent we run is one we did not write, unmodified. An import is a
   modification, and a product whose runtime needs one has a different
   promise than ours.
2. **It buys a version treadmill.** LangChain shipped 1.0 this year and
   LangGraph's own surface moves under it. A spawn contract cannot break
   when a framework renames a class; a linked SDK can, and would break
   it on the runtime box where every seat lives.
3. **It would be a second executor in the product's own dependency
   budget**, which ADR-15 consequence 6 explicitly deferred: "revisit
   when a second executor arrives, not before". The second executor has
   arrived, and the answer that keeps the budget at zero is a
   subprocess, which is what epitod already is.

**Why LangGraph still gets code.** A LangGraph app has no one-shot
entry point: the framework's own invocation paths are a dev server and a
library call. The adapter therefore ships a **shim** —
`cli/adapters/langgraph_run.py`, stdlib-only Python — which reads the
`langgraph.json` the author already has, resolves the graph it names,
streams it once with the run's prompt, and prints the result contract.
The agent's repository is unchanged: `langgraph.json` is LangGraph's own
file, not ours. The shim is the adapter's body, the way claude's flags
are the claude adapter's body, and it is the only Python epito owns.

**Consequences.**

1. **`[runtime].adapter` and `[runtime].graph` are proposed in-band in
   `spec/manifest.md`**, both optional, both additive. An absent
   `adapter` is `"claude"`, so every manifest in every roster behaves
   exactly as it did — the acceptance test for this card is that the
   claude argv is byte-identical before and after.
2. **A window is a claude capability, not a runtime one.** Presence
   (`--resume`, `POST /message`) rests on a session id the executor
   hands back. The langgraph adapter holds no session: a follow-up
   message to a langgraph seat starts a fresh run with the message as
   its prompt, and the run log and audit line say so in those words. An
   adapter declares `resumes: false` rather than pretending.
3. **The mint, the board, the audit log and the trace are adapter-blind.**
   An agent's identity is its App, not its framework (ADR-8): a
   langgraph seat clones on its own minted token, commits as
   `<name>[bot]`, files on the board, and appears in the audit log
   through exactly the code the claude seats use. Nothing in
   `activities.js` learned a new word.
4. **A third adapter is a table entry and a smoke section.** n8n and
   OpenClaw (portability proposal C) are now that shape rather than a
   rewrite, and the shape is what ADR-10's "adapter runtime" always
   meant.
5. **The prompt does not fork per adapter.** One `buildPrompt` reaches
   every agent, because the charter is the agent's contract with its
   company and it cannot depend on which framework is reading it.

## ADR-18: Runs emit OpenTelemetry spans; Phoenix is a surface, never a dependency

**Date.** 2026-09-27. **Status.** Proposed by the engineer seat; the
owner ratifies by merging, objects by editing.

**Context.** The other half of the same directive: "with tracing
(Phoenix is installed)". Arize Phoenix is running on the owner's box.
Until this card the only record of what happened inside a run was
`.epito/logs/<agent>/<runId>.log` — a transcript you read after you
already know which run went wrong — plus a one-line board entry. A
foreign agent makes that worse, not better: ADR-17 hands epitod a child
process it deliberately knows nothing about, so without spans the graph
is a single opaque exit code.

**Decision.** epitod emits OTLP spans over HTTP/JSON, hand-rolled in
`cli/src/lib/trace.js`, with no OpenTelemetry package in the dependency
list. One trace per run: `run` (the root, filed by `record`), `clone`
and `execute` beneath it, and beneath `execute` whatever the agent
itself emits. The destination is `OTEL_EXPORTER_OTLP_ENDPOINT` — the
standard variable, so pointing epitod at Phoenix is the same setting a
Phoenix user already knows. Unset means tracing is off and costs
nothing: no spans, no warnings, no behaviour change.

**Why hand-rolled.** The OpenTelemetry Node SDK is six packages, a
provider, a batch processor and a background flush whose lifetime fights
an activity's — every activity invocation would have to shut the
provider down to guarantee its spans left the process. What epito needs
is three spans per run with ids that two separate processes can agree on
without passing context, which is nine lines of `crypto` and one
`fetch`. **Span and trace ids are derived from the run id by SHA-256**,
so `clone`, `execute` and `record` — three activity invocations that
never share memory, may run on different hosts, and are retried
independently — compute the same ids from the same run, and a retried
activity re-files the same span rather than inventing a sibling. That
property is what pays for writing the exporter: with the SDK we would
have had to thread a trace context through Temporal's persisted inputs,
and law 7 makes every such input a thing written to a database forever.
If epito ever needs context propagated from a process it did not spawn,
adopt the SDK then and keep the ids.

**Why Phoenix is not in the decision.** ADR-6: integrations are
surfaces, never dependencies. What ships is OTLP, which Phoenix,
Jaeger, Grafana Tempo, LangSmith's `/otel` endpoint and Honeycomb all
accept; Phoenix is where the owner's spans happen to land tonight. No
Phoenix name appears in the product's code, and the smoke test asserts
against a fourteen-line OTLP sink rather than against Phoenix, so the
test does not need what the box has.

**Consequences.**

1. **Tracing can never fail a run.** Export is best-effort with a short
   timeout; a refused connection is one log line, not a retry loop and
   not an exit code. The rule the board set (ADR-16, consequence 1) now
   holds for three ledgers: the run already happened, and a record of it
   that argues with the run is worse than a record that is missing.
2. **The agent inherits the trace, not the credential.** The child is
   given `OTEL_EXPORTER_OTLP_ENDPOINT`, `OTEL_RESOURCE_ATTRIBUTES` and
   `TRACEPARENT`, so anything already instrumented — openinference,
   LangSmith's OTel exporter, the langgraph shim's own node spans —
   nests under `execute` with no epito import. It is **not** given
   `OTEL_EXPORTER_OTLP_HEADERS`, because a headers value carries an api
   key on every hosted tracing backend, and law 6 says a run sees only
   the secrets its manifest names. A seat that needs authenticated
   export lists that variable in `[runtime].env` like any other secret,
   and the log redacts it.
3. **No span attribute may hold a secret**, and the mint's attributes
   are the test: app id, installation id, permissions and expiry are
   attributes, the token never is. This is law 7 applied to a second
   store we do not own — a trace backend is forever in exactly the way
   Temporal's database is.
4. **The trace is not a third source of truth.** The board answers what
   the seats did, the audit log answers what exactly happened, and the
   trace answers where the time went and what the agent did inside its
   own run. A fact that belongs on the board goes on the board;
   `trace.js` is not allowed to grow a query surface.

## ADR-19: A seat declares its roads; the runtime takes the detour, and only for a run that never started

**Date.** 2026-09-28. **Status.** Proposed by the engineer seat; the
owner ratifies by merging, objects by editing.

**Context.** Priority 4 of the four the owner gave on 2026-09-26, and
the last of them: "the router". (Own-model hosting with vLLM was dropped
in the same breath, so this is about routing runs to models somebody
else hosts, not about hosting one.)

The company has already built this five times. Every HQ seat workflow
carries an open-routed step — `ANTHROPIC_BASE_URL` and
`ANTHROPIC_AUTH_TOKEN` pointed at Moonshot, `continue-on-error: true`,
an `id` — and a second step on the Claude subscription that runs when
the first did not succeed. That is eleven lines of YAML repeated in
fifteen workflows across five repositories, and the company's own
register records what it cost to get right: a fallback step without
`continue-on-error` kills the job instead of falling back; three runs
died at turn one against a provider whose prepaid tier allows one
concurrent request; the switch had to move behind a repository variable
rather than behind the presence of a key. A detour hand-wired into every
driver is a detour that is wrong in one driver.

epitod is the one place a company's runs all pass through. It should
own the detour.

**Decision.** `[[runtime.route]]`, an ordered list. Each route is a
model, optionally an endpoint (`base_url`), optionally the NAME of the
key that opens it (`token_env`), optionally a lane width
(`concurrency`). A run tries them in order and takes the first road
that starts it. No `[[runtime.route]]` means one road — `[runtime].model`
on whatever login the executor already has — which is what every
manifest in every roster means today.

**Why not a gateway** (LiteLLM, OpenRouter, a proxy on the box), which
is the obvious build and a real product: it is a second service to run,
and a seat's road would then be an operational fact with no expression
in the manifest — the opposite of what the manifest is for. A gateway
remains a perfectly good `base_url` for one route, which is the honest
relationship: surfaces, never dependencies.

**Why not "retry the run on another model"**, which is what a naive
router does: `execute` is never retried in this runtime because a run
that half-ran has already pushed commits. The router inherits that
bound, and it is the whole of consequence 2.

**Consequences.**

1. **A route whose key is not on this box is skipped, not failed.** Open
   routing is opt-in per machine, so the same roster runs on a box with
   a Moonshot key and on one without, and only the second goes straight
   to the subscription. What it may never do is go there silently: every
   skip is a line in the run log, and `epito routes` says per box which
   road each seat takes and why the others are closed. A seat whose every
   road is closed refuses the run, naming each one.

2. **Falling back is bounded by what the AGENT did, never by what the
   provider said.** The next road is taken only when the attempt opened
   no pull request and reached at most one turn — a run that provably
   never started. Turn nine and a failure is the agent's own outcome; a
   timeout, a cancellation and a spawn failure are the box's. That rule
   is what makes the detour safe without a distributed lock, and it is
   asserted six ways in `cli/test/unit.mjs`.

3. **A held session belongs to the road that made it.** A window records
   the route its opening run took, and follow-up messages land on that
   road with no fallback. `--resume <id>` at a different endpoint is a
   stranger handed a conversation it never had.

4. **The ledger, the board and the trace say which road ran.** One audit
   line per refusal, one per detour taken, one span per road under the
   run's `execute`, and the run's recorded `model` is the model that
   actually ran rather than the one the manifest named first. A fallback
   nobody can see is a cost nobody can see — which is exactly how fifteen
   hand-wired detours stayed wrong.

5. **A route's key is a secret like every other**: named in the manifest,
   read from the worker's own environment at spawn time, never written
   to Temporal's database, never in a span, and scrubbed out of the run
   log — because a provider that refuses is precisely the child that
   prints the key it tried.

6. **One worker serializes its own lane.** `concurrency` is honoured
   inside one worker process, which is the whole of a single-host
   install. Two worker hosts are two counters; the engine-side lease
   that would fix that is an idea, not a claim.

## ADR-20: An agent gets its own GitHub App, created by the app-manifest flow

**Date.** 2026-09-30. **Status.** Proposed by the engineer seat; the
owner ratifies by merging, objects by editing. This is EPI-4, the route
decision cycle 1 named as its central unknown and left open when the
cycle was re-bet to the runtime.

**Context.** `epito deploy` has printed "platform in progress" since
founding night, and it is the command the product is named for. The mint
(`epito token`), the trigger wiring (`epito run`) and the ledger all
landed without it, which means every principal in existence today was
created by a human in GitHub's 14-field App form and installed by hand.
The question the cycle framed: does an agent get **its own App**, created
per agent, or does one epito-owned App get **installed per agent**?

**Decision.** App-per-agent, created through GitHub's app-manifest flow:
`epito deploy` serves one local page that POSTs a manifest built from
`[identity].scopes`, a human clicks Create once, GitHub returns a code to
a one-shot loopback listener, and the conversion hands back the App's id
and private key, which land in `.epito/` at 0600.

**Why, on the evidence available.** Not a live spike: no App was created
on any account for this decision, and the flow is proved end to end
against a stand-in api.github.com (`cli/test/smoke-deploy.sh`, 52
assertions) rather than against github.com. What decided it is three
properties that are structural rather than empirical, so a live spike
would not have changed them:

1. **A shared App makes every agent the same someone.** ADR-2 says an
   agent is *someone* — its own identity, never the owner's. Under the
   shared route every PR in every customer's repository is authored by
   `epito[bot]`, and the audit trail can no longer answer "which agent
   did this" from the artifact itself. The market brief's differentiator
   (§1) is exactly the leg that would be given away.
2. **A shared App is one key for every customer's every agent.** Its
   compromise is total and its revocation is total: "uninstall the App"
   is ADR-2's one-click revoke, and under the shared route that click
   revokes the whole roster. Per-agent keys make the blast radius one
   agent, which is the promise the product sells.
3. **Neither route costs us portability.** `lib/identity.js` already
   reduces both to (app id, key, installation id) — it was written that
   way deliberately, and not one line of it changed to build this. If
   the owner overrules, the change is a second `IdentityProvider`, not a
   rewrite.

**What it costs, named plainly.** GitHub has no API that creates an App
without a human at a keyboard, so `epito deploy` cannot be fully
headless: creation is one click in a browser, and installation on the
repository is a second. Everything around those two clicks is gone — the
form, the permission guesswork, the key file in Downloads, the "which App
was this" a month later — but the clicks stay, and a hosted callback
service that removed them was ruled a rabbit hole for this cycle and
still is. The redeploy path (recording the installation) *is* headless,
which is why deploying twice is the documented shape.

**Consequences.**

1. **One manifest, one principal, enforced by the command.** A second
   `epito deploy` never creates a second App: it re-discovers the
   installation for `[runtime].repo` and updates the one record (spec
   rule 4). Two Apps answering to one name would make the ledger unable
   to say who acted.
2. **App names are globally unique on GitHub, so they carry a suffix.**
   `<agent>-<repo owner>`, capped at GitHub's 34 characters,
   `--app-name` to override. A naming *system* was a named rabbit hole;
   this is one suffix derived from the manifest.
3. **The App this creates subscribes to nothing.** No `hook_attributes`,
   no `default_events`. Triggers belong to `epito run`, and an App that
   declares a hook URL nobody serves is a dead endpoint in somebody's
   settings page forever. `[trigger].webhook` is served by the runtime's
   ingress, not by GitHub.
4. **The ceiling is set once, from the file.** `default_permissions` is
   `[identity].scopes` through the same `SCOPE_MAP` every mint uses, so
   an App cannot be created wider than the manifest that describes it —
   and an unmapped scope fails before a human is sent to a browser.
5. **An account-level cap on Apps exists and this seat has not measured
   it.** A roster of a few hundred seats may meet it. That is an open
   question against the per-agent route, recorded rather than guessed at.

## ADR-21: `epito validate` notes what the runtime will still refuse; `--for-runtime` is the strict pass

**Date.** 2026-10-01. **Status.** Proposed by the engineer seat; the
owner ratifies by merging, objects by editing. Settles the open decision
recorded in docs/ideas.md ("`epito validate` passes a manifest that
`epito run` will refuse"), which named both candidate answers and
declined to pick one.

**Context.** `epito init` scaffolded a manifest, `epito validate` printed
`✓`, and `epito run`, `epito ps <dir>`, `epito deploy` and `epito token`
then every one refused it for a missing `[runtime].repo`. Those are the
first three commands a vibecoder runs, in order, out of the box, and the
sequence ended in a refusal the tick had just said would not come. The
same shape applies to a scope outside `SCOPE_MAP`: valid, ticked, refused
at the mint.

Both gaps are the spec being deliberate, not careless. v0.1 says
`epito validate` "accepts [repo] absent (Actions-era manifests stay
valid)", and that an unmapped scope "fails **the mint** … not `epito
validate`. That placement is deliberate: a stricter validator would
refuse a running roster at startup over one word, and a live box is
downstream of that choice." Both calls survive this ADR unchanged.

**Decision.** Three parts.

1. **The notes are on by default and change no exit code.** A valid
   manifest stays valid and still exits 0. What changes is that the tick
   stops implying the rules it does not apply do not exist: it names the
   commands that will refuse, and carries the fix, to the bar `epito
   validate` already sets for its errors.
2. **`--for-runtime` is the strict pass**, exit 1 — for CI that wants the
   refusal here instead of at 06:00. Opt-in, because the default must keep
   saying yes to every manifest the spec blesses.
3. **The rules live in one module** (`cli/src/lib/readiness.js`), owned by
   the commands that enforce them, and the validator reads them out. A
   drift test asserts the printed list of commands is the whole list of
   commands whose source refuses over the field.

**Why this and not the alternatives.** The ideas entry named the real
risk: "a warning nobody can silence becomes noise on the 36 manifests
that are deliberately Actions-era." That decided the shape.

- **Making the validator strict** was the obvious fix and is the one the
  spec forbids, for a reason that is still good: a live box reconciling a
  roster must not refuse a seat over a word it does not need.
- **`--for-runtime` only, with a silent default**, leaves the false `✓`
  exactly where it is for everyone who does not know to pass a flag —
  which is everyone the card is about.
- **Noise was the objection to a default note, and it does not apply
  here.** `epito validate` reads one `agent.toml`, in the directory the
  user is standing in, because they asked. The 36-manifest case is a
  roster being loaded by `epito run`, which hard-refuses already and
  prints no notes at all.

**A note fires on doubt, never on the good case.** The third note v0.1 has
says the `✓` did not check `[runtime].entry` — the validator skips that stat
once `repo` is set, because the runtime reads the charter inside the clone.
It is said only when the file is also absent from the directory you are
standing in. A note on every correctly configured manifest would be the
noise this ADR's objection is about, and noise on the good case is worse
than noise on the broken one: standing in the repo with the charter beside
you is evidence, and a path that resolves nowhere on this machine is the
case that earns a sentence.

**What it costs.** One more thing on screen for a repo-less manifest that
its author knows is repo-less. The honest mitigation was to remove the
common case rather than argue about it: `epito init` now reads
`[runtime].repo` off the directory's git origin, so the manifest it
writes in the normal case has nothing to warn about.

**Also settled, with no spec cover needed.** `[trigger].cron` was counted
(five fields present) and not parsed, so `"0 99 * * *"` ticked here and
was refused by `epito run` when it built the matcher. That was a plain
validator bug, not a deliberate placement: it is parsed in the validator
now, and `loadRoster`'s duplicate copy of the check is gone, so the two
commands cannot print different sentences about the same expression.

## ADR-22: The ledger is read-only from the CLI, and it is not the board

**Date.** 2026-10-02. **Status.** Proposed by the engineer seat; the owner
ratifies by merging, objects by editing. Closes cycle 1's scope 1e, whose
read-back ("optional `epito audit`") was named the cycle's first cut on
2026-09-21 and duly cut.

**Context.** `.epito/audit.jsonl` has been written since PR #4 and is now
appended to by six code paths: `epito deploy`, `epito token`, `epito run`'s
ingress, the worker, and the `clone` and `execute` activities. Until this
ADR nothing could read it. `epito ps` printed the path and told the operator
to look at the Temporal UI for anything more.

That is a gap in the product's central claim, not a missing convenience.
epito sells agents that act as themselves under named permissions. "This
agent held `contents:write` and `pull_requests:write` on `acme/product`,
minted at 14:04, expiring at 15:04, as `digest[bot]`" is the sentence the
whole identity leg exists to be able to say, every fact in it has been on
disk for two weeks, and no command could say it.

**Decision.** Three parts.

1. **`epito audit` reads, and there is no way to write through it.** No
   `--add`, no `epito audit note`, no ingress route that appends. A ledger a
   hand can append to from outside is not a ledger: the single thing an audit
   log sells is that every line in it was put there by the thing that did the
   work. `epito report` exists for a seat that wants to say something, and it
   files to the *board*.
2. **The board and the ledger stay two files answering two questions.** The
   board (ADR-16) is "what have the seats been doing" — run reports, folded
   for an owner, one shape refused field by field. The ledger is "what exactly
   happened", in the runtime's vocabulary, including the lines nobody reads
   until something is wrong. They agree about runs because one activity files
   both (`record`, in `temporal/activities.js`). Merging them would force one
   of the two questions to be asked in the other's words.
3. **An action this epito does not know still prints.** Unknown actions render
   their own fields as `key=value`. The worst line in a ledger is the one a
   *newer* epito wrote, and a reader that hid it would blind the auditor on
   exactly the events that are new — upgrading the runtime would quietly
   narrow the record.

**Why this and not the alternatives.**

- **A second kind of board entry** (`kind: "audit"`) was the cheap route and
  is wrong twice: the board refuses any field not in its one shape, which is
  ADR-16's whole point and which an audit line — different per action —
  cannot satisfy; and it would put the ledger behind the ingress and its
  secret, when the ledger's reader needs no network at all.
- **Only `--json`, and let `jq` do the rest.** It is already there and it is
  not an answer: the person who needs this most is the vibecoder the product
  is for, and "pipe it through jq and group by agent" is the hand-wiring epito
  exists to delete. The fold is four columns of arithmetic that nobody should
  do twice.
- **Deferring it to the Temporal UI**, which `epito ps` currently suggests.
  The UI knows workflows, not permissions, and it is the engine's — ADR-15
  and law 8 both say the product's record must outlive the engine. A mint
  that happened in `epito token` on a laptop was never in Temporal at all.

**What it costs.** One more command in `--help`, and a second reader to keep
honest when a new action is added: `ACTIONS` in `cli/src/lib/audit.js` is the
list, and a unit test asserts every entry in it renders a sentence. An action
written by the runtime and missing from that list prints its fields instead of
a sentence — degraded, never hidden, which is part 3 above working as intended
rather than a gap.

**No spec change.** `spec/manifest.md` defines the manifest, and nothing here
touches a field in it. The audit log is the runtime's, not the manifest's.

## ADR-23: The company's roster lives in `agents/`, and it does not retire the workflows

**Date.** 2026-10-03. **Status.** Proposed by the engineer seat; the owner
ratifies by merging, objects by editing. Cycle 1 closed 2026-10-02; this is
the top open card in `docs/backlog.md`'s Now section.

**Context.** epito.me runs five seats, and all five are GitHub Actions jobs:
`.github/workflows/agent-{engineer,pm,market,okr,exo}.yml`, ~130 lines each,
most of it identical. The product exists because that is the wrong way to run
an agent (the cycle-1 amendment records the owner's words: "there isn't
anything to give agents a consistent runtime... a consistent runtime that
isn't just a cron"). Up to this ADR, nothing in this repository described a
seat as a manifest. The only manifests were three fixtures under
`cli/test/fixtures/shapes/`, written to freeze the spec against.

So the product had never been pointed at a seat it did not invent — and
"customer #1 is the owner's own company" (ADR-11) was a claim with no file
behind it.

**Decision.** Three parts.

1. **The roster is `agents/<seat>/agent.toml`, in the repository the seats
   work in.** One directory, one manifest per subdirectory, which is the
   layout `epito run <dir>` already discovers (`lib/roster.js`). Not a single
   multi-agent file, and no roster manifest describing the roster: the spec's
   open question — team/roster fields stay out — survived contact, because
   `epito run agents` needs a directory and nothing more.

2. **Every value is translated, never invented, and the translation is
   tested.** `cli/test/smoke-roster.sh` asserts each manifest's `max_turns`
   still equals the `--max-turns` its workflow passes, and that the engineer's
   two `- cron:` entries are the one list expression that means the same
   thing. A roster that drifts from the wiring it replaces proves nothing, and
   drift is silent by default.

3. **The workflows stay.** This ADR describes the seats; it does not move
   them. Dogfood step 2 — deleting a seat's Actions wiring — waits for a box
   that is actually running them, and conflating the two would mean a
   half-migrated org where a seat is described in one place and run in
   another with no way to tell which fired.

**Alternatives.**

- *A single `roster.toml` listing five agents.* Rejected: a manifest is the
  unit of everything later (a deploy is a manifest provisioned, a marketplace
  listing is a manifest published, spec v0.1's opening). Five agents in one
  file is one file five agents cannot be published out of, and `epito deploy
  <name>` would need a selector where it currently needs a path.
- *Generate the manifests from the workflows at build time.* Rejected: the
  direction of travel is the other way. The workflows are what we intend to
  delete; deriving the product's input from the thing it replaces makes the
  replacement permanent.
- *Translate one seat, not five.* Tempting — the card says "one alexandria
  seat" — and rejected because the findings came from the spread. Three of
  the five share an unexpressible second road, one has two crons, one has no
  cron at all; a single-seat roster would have been the easy case and would
  have found none of it.
- *Wait for a live box.* Rejected: it is what every previous run did, and the
  card has been open since founding night. The seats-as-manifests half needs
  no box, and the two bugs it found were in the dry-run path specifically —
  the path an operator uses *before* they have a box.

**Consequence.** `agents/` is product surface now: a change to a seat's
schedule or model has two homes until step 2, and `smoke-roster.sh` is what
catches the one that forgot the other. Accepted deliberately — the alternative
is a roster that is decorative, and a decorative roster is how the three
synthetic fixtures ended up being the only evidence the spec had.

**Spec delta.** Flagged in the PR, and it is a question rather than a field:
`[[runtime.route]].base_url` is a literal URL, and the open road three of
these seats take has its endpoint held as a repository secret, so the road
cannot be written in a publishable manifest. `spec/manifest.md`'s open
questions now carry it (probable shape: `base_url_env`, beside `token_env`).
v0.1 stays frozen; nothing was added to the catalogue.
