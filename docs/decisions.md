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
