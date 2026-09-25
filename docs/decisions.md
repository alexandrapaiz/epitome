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

## ADR-15: One GitHub App per agent — proposed, owner rules (EPI-4 route spike)

Engineer seat, 2026-09-25, from building the identity slice (cycle 1
bet 2). Status: **proposed**; the owner ratifies by merging and objects
by editing. R2 asked for both routes measured before a ruling; this is
the measurement, taken by building one of them.

The question cycle 1 scope 1a left open: does an epito agent get its
own GitHub App, or do all agents share one epito-owned App with
per-repository installations?

**What the build measured.** Both routes end in the same API call —
`POST /app/installations/{id}/access_tokens` with a permissions object
and one repository — and therefore share every line of
`cli/src/lib/identity.js` except the credential lookup in
`loadPrincipal`: per-agent reads `EPITO_APP_ID_<NAME>` /
`EPITO_APP_KEY_<NAME>`, shared would read one `EPITO_APP_ID`. That is
the finding, and it is not the one the pitch expected. The shared App
was shaped as the "worse story, simpler build" fallback
(deploy-identity-v0.md); **the build is not simpler.** It is about six
lines of environment lookup either way, because GitHub's scoping
mechanism is the installation, and an installation exists under both
routes.

With build cost equal, the difference is entirely in what the user sees
and what the box holds:

| | App per agent | One shared App |
|---|---|---|
| PR author | `<agent>[bot]`, its own name and avatar | `epito[bot]` for every agent everywhere |
| Revoke one agent | uninstall its App; nothing else moves | uninstall the repo, taking every agent on it |
| Permission ceiling | per agent, set at its App | one ceiling, the union of every agent's needs |
| Audit at GitHub's end | per agent, in GitHub's own log | one actor for the whole roster |
| Secrets on the box | one key per agent | one key total |
| Setup cost | one App created per agent | one App, ever |
| Ceiling | 100 Apps per account (GitHub's limit) | none |
| Name collisions | App names are globally unique on GitHub | one name to claim |

**Decision: one App per agent.** ADR-1 and the market brief's demand
quotes both say the credentialed principal *is* the wedge; a shared bot
badge deletes the wedge to save six lines and a click. The
union-ceiling row is the sharper argument: a shared App must hold every
permission any agent on the roster needs, so the weakest agent's token
is issued from the strongest agent's App — exactly the blast radius
spec rule 2 exists to prevent. Per-request narrowing survives under
both routes (that part surprised us, and it is why the fallback stays
cheap), but **key isolation does not**: one shared private key
compromises every agent on the box at once. The 100-App limit is real
and distant, and it is an argument about an org's roster size rather
than about v0.

**Rejected outright: a fine-grained PAT per agent.** It is a person's
credential wearing an agent's name — the thing the product exists to
end (ADR-2) — and it can be neither attributed nor revoked per agent
without touching the human's account.

**What is deliberately not decided here.** The *provisioning* route —
GitHub's one-click app-manifest flow with a localhost callback (pitch
step 1) versus the owner creating an App by hand — is still open, and
this PR builds neither: v0 asks for an App created by hand and two
environment variables on the box. That is the cut, taken knowingly.
Minting is the leg the runtime consumes, and a creation flow that
produces an unmintable credential is worth nothing. Either route ends
with the agent holding its own App, so the flow changes nothing above.

**Evidence status, stated plainly.** No App has been created live: the
owner holds the GitHub account, and the engineer charter forbids
live-account calls without a card that says so. What *is* retired is
the mint — proven end to end against a stub of GitHub's API that
verifies the RS256 JWT against the App key's public half
(`cli/test/smoke-token.sh`, 34 assertions): the JWT, the installation
lookup, the scope→permission body, the injection into a run, and every
refusal. What stays open is a browser flow the owner must drive once
per agent under either route.

**Consequences.**
1. A roster of N agents means N Apps and N keys on the runtime box, at
   0600, named by the convention in `deploy/provision-host.sh`'s env
   template and README.md's table.
2. Onboarding an agent gains a manual step until the app-manifest flow
   lands. `epito token <name>` is how that step gets verified before a
   schedule depends on it: it mints once, on demand, and prints what
   the run would have acted under.
3. If the owner rules the other way, the change is confined to
   `loadPrincipal` in `cli/src/lib/identity.js`. Nothing else in the
   runtime knows which route it is on.
