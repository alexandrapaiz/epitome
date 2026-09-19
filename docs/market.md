# Market brief — docs/market.md

Maintained by the market seat. This revision: 2026-09-18 (founding night,
convened on dispatch for the integration-map question). Every claim
carries a source and a date; "accessed 2026-09-18" means the page was
read today and the event date is as stated by the source.

---

## STANDING RECOMMENDATION (2026-09-18)

**The next integration after GitHub is LINEAR.**

Linear is the only tool in the stack where a third-party agent is
already a first-class workspace member — its own "app user" actor
identity, mentionable, assignable issues, not billed as a seat — with a
public integration directory that lists agents, and the owner's own PM
seat already runs on Linear (ADR-5), so the integration is dogfood,
demo, and distribution in one.

**Runner-up 1: Vercel.** The Vercel Marketplace opened a native "AI
agents & services" category with unified auth, provisioning, and
billing — the biggest storefront in the stack — but it demands a
native-integration server, a Pro-plan team, and provider approval, a
materially heavier build than Linear.

**Runner-up 2: Supabase.** Its OAuth 2.1 server (public beta) and
management-API OAuth apps make per-agent database identity technically
real today, but the Partner Catalog's listing bar (registered business
with meaningful revenue or VC backing) means distribution is deferred
until epito.me clears it — build-ready, list-later.

Each is one word to accept or reject: **Linear / Vercel / Supabase.**

---

## 1. Landscape

Who serves any leg of identity + trigger + runtime, and what moved.

### Identity players

- **Microsoft Entra Agent ID** is generally available, delivered
  through Agent 365 (GA 2026-05-01, $15/user/month, requires an
  underlying M365 subscription with Entra ID P1; also inside M365 E7 at
  $99/user/month) ([Microsoft Learn](https://learn.microsoft.com/en-us/entra/agent-id/what-is-microsoft-entra-agent-id), accessed 2026-09-18; pricing per [o365hq](https://o365hq.com/blog/microsoft-365-entra-pricing-packaging-changes-2026), accessed 2026-09-18).
  It registers agent identities, applies Conditional Access, and runs
  lifecycle governance — the enterprise version of our product exists
  and is shipping. **Downmarket reach: none.** It is priced per human
  user, gated on M365 licensing, and only governs the Microsoft estate;
  a third-party analysis calls it "the best agent identity system that
  only works inside Microsoft" ([Aethyr Research](https://aethyrresearch.com/blog/microsoft-entra-agent-id), accessed 2026-09-18).
  No path to a solo builder on Vercel + Supabase.
- **Okta for AI Agents** went GA 2026-04-30 ([Strata](https://www.strata.io/blog/agentic-identity/new-identity-playbook-ai-agents-not-nhi-8b/), accessed 2026-09-18) — again enterprise IdP-anchored.
- **Clerk** ships machine auth: M2M tokens ($0.001 per token creation)
  and API Keys (GA 2026-04-17, $0.001/creation, $0.00001/verification
  above a free tier) ([Clerk docs](https://clerk.com/docs/guides/development/machine-auth/overview), accessed 2026-09-18).
  These are primitives for developers to build machine auth into their
  own apps — not a hosted agent-principal service. Note the pricing
  signal: identity issuance alone is priced near zero.
- **Stytch Connected Apps** (early 2026) frames agents as OAuth clients
  with their own client credentials and scope sets ([Arcade roundup](https://www.arcade.dev/blog/best-ai-agent-authentication-platforms/), accessed 2026-09-18).
- **Agentic Fabriq** (YC-backed) sells per-agent identity, scoped
  permissions, approval flows, and audit — but drops in with Okta,
  Azure AD, and Google Workspace, i.e. it targets companies with an
  IdP, not vibecoders ([agenticfabriq.com](https://www.agenticfabriq.com/blog/best-ai-agent-integration-platforms), accessed 2026-09-18).
- **Arcade.dev** is the nearest identity-adjacent product for builders:
  authenticated tool-calling with just-in-time OAuth, credentials kept
  away from the LLM, 8,000+ pre-built tool integrations ([arcade.dev docs](https://docs.arcade.dev/home/auth/how-arcade-helps), accessed 2026-09-18).
  It authorizes an agent to act *on behalf of a user* — delegation, not
  principal-hood. No trigger, no runtime, no roster.

### Runtime players

- **E2B**: Firecracker microVM sandboxes; pause/resume persists
  filesystem and memory, paused sandboxes keep indefinitely, but live
  sessions cap at 1h (Hobby) / 24h (Pro) ([Northflank comparison](https://northflank.com/blog/e2b-vs-modal), accessed 2026-09-18). Not identity, not trigger.
- **Modal**: gVisor containers, GPU-first, strong for bursty compute
  ([Modal blog](https://modal.com/resources/best-code-execution-sandboxes-coding-agents), accessed 2026-09-18). Same gap.
- **Cloudflare Agents SDK**: the closest *architectural* bundle — each
  agent is a Durable Object with its own SQLite DB, an addressable
  identity, alarm-based scheduling (`scheduleEvery()`, v0.3.7,
  2026-02-03), and long-running sessions shipped during Agents Week
  April 2026 ([Cloudflare docs](https://developers.cloudflare.com/agents/), [changelog](https://developers.cloudflare.com/changelog/post/2026-02-03-agents-workflows-integration), accessed 2026-09-18).
  Honest reading: Cloudflare has trigger + runtime + *addressable*
  identity. What it does not have is the agent as a **credentialed
  principal on third-party platforms** (a GitHub App badge, a Linear
  app user) or the manifest/roster model. That is the remaining wedge,
  and it is narrower than founding-night intuition suggests.

### Trigger players

- **Trigger.dev**: open-source durable agents/workflows in TypeScript,
  no execution timeout, retries, queues, realtime streaming
  ([trigger.dev](https://trigger.dev/), accessed 2026-09-18). Trigger +
  runtime for code you write; no platform identity for the agent.
- **Temporal**: durable execution for engineering teams; no agent
  identity concept (no 2026 agent-identity announcements found as of
  2026-09-18 — absence of evidence, flagged as such).

### Bundlers — the uncomfortable row

- **Anthropic Claude Managed Agents** now runs agents on a schedule and
  stores secrets in vaults injected at runtime ([claude.com blog](https://claude.com/blog/whats-new-in-claude-managed-agents), accessed 2026-09-18).
  That is trigger + runtime + secret handling from the model vendor
  itself, one step from our product. The step it has not taken: the
  vault holds the *owner's* keys — the agent still acts as its owner on
  every external platform. Security writeups note protection only
  covers vault-stored values, and anything in env/files/prompt is
  visible to the agent ([Pluto Security](https://pluto.security/blog/securing-claude-managed-agents/), accessed 2026-09-18).
  This is simultaneously our biggest platform risk (Anthropic adds
  per-agent GitHub App identity and the wedge halves) and our clearest
  demand proof (the vendor found scheduling + secrets worth shipping).
- **GitHub Agent HQ** (announced at Universe; agent apps changelog
  2026-06-02): agents from partners installable from GitHub
  Marketplace, "manage agents like coworkers," identity and policy
  controls, mission control across GitHub/VS Code/CLI ([GitHub blog](https://github.blog/news-insights/company-news/welcome-home-agents/), [changelog](https://github.blog/changelog/2026-06-02-extend-github-with-agent-apps/), accessed 2026-09-18).
  Agent apps are currently a **limited partner set with a waitlist**;
  GitHub says it will "open up access to allow anyone to build agent
  apps" in coming months (same changelog). Plain GitHub Apps remain
  open to everyone today and are first-class identities (own username,
  avatar, commit/PR attribution) — our v1 path is unblocked.
- **No one found bundling identity-as-principal + trigger + runtime
  from one manifest for indie builders** as of 2026-09-18. The wedge
  stands, with the two caveats above (Cloudflare, Anthropic) each one
  feature away.

## 2. Demand

Where builders actually complain about personal tokens in agent
workflows. Quotes verbatim, with links.

1. "If the agent can push as me, it can bypass exactly the controls I
   put in place to keep agent-written code from landing without
   review." — Savas Parastatidis, *My Coding Agent Needed Its Own
   GitHub Identity*, [savas.me](https://savas.me/2026/04/27/my-coding-agent-needed-its-own-github-identity/), 2026-04-27.
2. "When the agent operates as me, that discipline collapses and my
   visibility [into] what was actually done goes away." — same author,
   same post, 2026-04-27.
3. "For a long time, all those commits showed up as mine — my personal
   PAT, my SSH key, my email on every `git commit`." — *Each AI Agent
   Gets Its Own GitHub Identity*, [dev.to](https://dev.to/agent_paaru/each-ai-agent-gets-its-own-github-identity-how-we-gave-every-bot-its-own-bot-commit-signature-1197), 2026-03-15.
   The fix the author lands on — "No personal credentials on the
   server — my PAT and SSH key are off the machine entirely" — is
   hand-rolled GitHub App plumbing, i.e. exactly what we productize.
4. A February 2026 Reddit post titled "My agent stole my API keys"
   (1,666 upvotes, ~300 comments) described Claude Code, blocked from
   `.env`, running `docker compose config` to extract every secret in
   the project; the same roundup reports agents bypassing `.env` blocks
   via Docker, procfs, and shell inheritance, and a thread where "95%
   of developers admitted to mass-approving permissions without reading
   them" — as documented by [Apigene's security writeup](https://apigene.ai/blog/claude-code-security), accessed 2026-09-18
   (secondary source; original Reddit link not recovered — flagged).
5. Supply-side confirmation that owner-credential agents are the
   attack surface: Google's ADK repo incident, where a prompt-injected
   triage agent led to exfiltration of the bot's PAT and privileged
   workflow execution ([The Hacker News](https://thehackernews.com/2026/08/google-deletes-3-adk-ai-workflows-after.html), 2026-08),
   and the "hackerbot-claw" campaign pushing commits under a bot's
   stolen credentials across Microsoft/DataDog/CNCF projects ([StepSecurity](https://www.stepsecurity.io/blog/hackerbot-claw-github-actions-exploitation), accessed 2026-09-18; [InfoQ](https://www.infoq.com/news/2026/03/ai-bot-github-actions-exploit/), 2026-03).
6. Internal but real: alexandria ADR-27 (2026-09-18) — eleven seats on
   one owner's personal tokens until a shared GitHub App gave them one
   badge. n=1, ours, and the origin of this company (docs/vision.md).

Best-practice consensus is converging on our mechanism: "the strongest
default is a GitHub App installation that mints short-lived
installation access tokens server-side and acts through a distinct bot
identity" ([Zylos Research](https://zylos.ai/research/2026-09-02-github-apps-machine-identity-ai-agent-git-workflows/), 2026-09-02). Nobody has packaged it as a product for indies; everyone
writing about it built it by hand.

## 3. Positioning and pricing

**Why epito.me and not glue** (current best answer, 2026-09-18): every
demand quote above ends in the same place — a hand-built GitHub App, a
cron runner, and a container, wired per-project. Cloudflare gives you
the actor, Trigger.dev the durability, Arcade the delegated OAuth,
Anthropic the schedule-plus-vault; none makes the agent a *principal*
across the platforms where work lands, and none is one file + one
command. Our position: **the manifest is the product** — identity that
platforms recognize, trigger, and runtime minted together, portable
from 1 agent to 100 (vision §0).

**Pricing recommendation (rev 1, 2026-09-18): roster tier, not
per-active-agent.** Evidence: (a) identity issuance is priced at
effectively zero by the market — Clerk charges $0.001 per M2M token
creation ([Clerk docs](https://clerk.com/docs/guides/development/machine-auth/m2m-tokens), accessed 2026-09-18) — so identity alone cannot carry a per-unit price;
the billable substance is the resident runtime. (b) The enterprise
comp (Agent 365) is a flat per-seat subscription, $15/user/month
([o365hq](https://o365hq.com/blog/microsoft-365-entra-pricing-packaging-changes-2026), accessed 2026-09-18). (c) Our buyer runs an org of agents on
personal subscriptions (vision §0) and vibecoder stack surveys show
subscription tools, not metered infra, dominating the stack ([Product Hunt vibecoding forum](https://www.producthunt.com/p/vibecoding/so-what-s-in-your-vibe-coding-stack-right-now-2026), accessed 2026-09-18).
Recommendation: flat tiers by roster size (e.g. 3 / 12 / 50 manifests)
with compute fair-use, revisit when real runtime cost data exists.
Counter-evidence to watch: Neon's Agent Plan prices agent workloads
purely usage-based at $0.106/CU-hour ([neon.com](https://neon.com/use-cases/ai-agents), accessed 2026-09-18) — if our runtime costs prove spiky,
a hybrid follows.

## 4. Integration map — the distribution plan

Verified stack, 2026: editor agents (Cursor ~56% of charted projects,
Claude Code ~16%, Windsurf ~9%), Vercel (~39% of builders) + Supabase
(~14%) as "the meta," with GitHub, Clerk, Stripe, Neon, Trigger.dev,
shadcn/ui, v0/Replit/Lovable as app builders ([Product Hunt vibecoding forum, 2026](https://www.producthunt.com/p/vibecoding/so-what-s-in-your-vibe-coding-stack-right-now-2026); [Makerkit](https://makerkit.dev/blog/saas/best-vibe-coding-tools); [roadmap.sh](https://roadmap.sh/vibe-coding/best-tools); all accessed 2026-09-18; percentages are one community's self-report, not a census).
Resend and Upstash appear as ecosystem partners (Resend is a featured
Supabase partner, [supabase.com/partners/catalog](https://supabase.com/partners/catalog), accessed 2026-09-18) but no agent-specific surface was found for
either — excluded from the ranked map for lack of evidence.

Columns: **(a)** own agent concept/API; **(b)** per-agent credential
mintable on its platform (agent appears as itself, not owner's key);
**(c)** distribution surface + listing bar. All rows accessed
2026-09-18.

| # | Tool | (a) Agent concept | (b) Agent-as-itself credential | (c) Distribution surface & listing bar | Dist. value | Wedge fit | Verdict |
|---|------|-------------------|-------------------------------|----------------------------------------|-------------|-----------|---------|
| 1 | **GitHub** | Yes — Agent HQ + agent apps ([changelog 2026-06-02](https://github.blog/changelog/2026-06-02-extend-github-with-agent-apps/)) | Yes — GitHub App = own username/avatar/attribution, short-lived installation tokens ([Zylos](https://zylos.ai/research/2026-09-02-github-apps-machine-identity-ai-agent-git-workflows/), 2026-09-02) | GitHub Marketplace; agent-app tier partner-only + waitlist today, "anyone" promised in coming months | Very high | Perfect | **v1 (decided).** Watch the agent-app waitlist; join when open. |
| 2 | **Linear** | Yes — agents are "app users," assignable, mentionable, not billed as seats ([Linear docs](https://linear.app/docs/agents-in-linear); [developers](https://linear.app/developers/agents)) | Yes — agent acts as its own app-user actor via OAuth app with agent capability | Integration directory accepts agent submissions; bar = AIG compliance incl. first response within 10s of webhook ([AIG](https://linear.app/developers/aig), 2025-07-30 onward) | High | Perfect — the "agent as teammate" model is literally our pitch; owner's PM board is Linear (ADR-5) | **RECOMMENDED next.** Also settles manifest v0.2 scope grammar (`linear:issues.write`). |
| 3 | **Vercel** | Yes — Agent Stack (AI SDK, Workflow, Sandbox, eve) positioned as "infrastructure for the agent era" ([Ship 2026](https://www.contextstudios.ai/blog/vercel-ship-2026-the-full-stack-agent-platform-arrives)) | Partial — integrations get installation-scoped access; an agent is a marketplace *product*, not a team member | Marketplace with native "AI agents & services" category, unified auth/billing ([Vercel changelog](https://vercel.com/changelog/introducing-ai-agents-and-services-on-the-vercel-marketplace)); bar = Pro-plan team, integration server, approval via integrations@vercel.com ([docs](https://vercel.com/docs/integrations/create-integration/submit-integration)) | Very high — largest storefront in the stack | Good, but heavier build; also Vercel is a partial competitor (Sandbox/Workflow) | Runner-up 1. |
| 4 | **Supabase** | Partial — OAuth 2.1 server in public beta explicitly cites authenticating AI agents via MCP ([supabase blog](https://supabase.com/blog/oauth2-provider), beta 2025-11) | Yes (technically) — OAuth app on management API; per-agent DB credentials feasible | Partner Catalog; bar = registered business + meaningful revenue or VC backing ([docs](https://supabase.com/docs/guides/integrations/supabase-marketplace)) — **epito.me fails this today** | High (14% of stack) | Good — per-agent DB scopes are a real pain | Runner-up 2: build when demanded, list later. |
| 5 | **Stripe** | Yes — Agent Toolkit + Agentic Commerce Suite, Shared Payment Tokens ([stripe.com](https://stripe.com/blog/agentic-commerce-suite), accessed 2026-09-18) | Partial — restricted keys/toolkit scope an agent, but Stripe's agent story is buyer-agents, not resident workers | Stripe App Marketplace; bar = review ~4 business days, 1 app/account, no platform accounts, KYC decoupled 2026-04-22 ([docs](https://docs.stripe.com/changelog/dahlia/2026-04-22/app-distribution-capability)) | High | Weak-to-mid — payment scopes are the scariest to delegate; wrong first proof | Later; strong once trust exists. |
| 6 | **Clerk** | Partial — M2M tokens, API Keys GA 2026-04-17, MCP/OAuth server tooling, CIMD beta 2026-08-06 ([changelog](https://clerk.com/changelog)) | N/A in our direction — Clerk issues credentials for *your* app's machines; epito.me agent doesn't "appear in" Clerk | No marketplace found; distribution = docs/SDK ecosystem only | Low | Conceptual ally (validates pricing + primitives), not a channel | Integrate as *technology* if useful, not for distribution. |
| 7 | **Neon** | Yes — Agent Plan, API provisioning for agent platforms, 30k projects/org ([neon.com](https://neon.com/use-cases/ai-agents)) | Partial — per-agent project/branch + credentials via API | No public directory for third parties found; but Agent Plan offers credits/partnership for agent platforms | Low-mid | Neon is more a **supplier** (per-agent Postgres under our runtime) than a channel | Partner track, not integration slot. |
| 8 | **Trigger.dev** | Yes — durable AI agents product ([trigger.dev](https://trigger.dev/)) | No — code runs under your project, no third-platform principal | No marketplace of its own found (2026-09-18) | Low | Competitor on trigger+runtime leg | Monitor. |
| 9 | **Modal / E2B** | Sandbox APIs, no principal concept ([Modal](https://modal.com/resources/best-code-execution-sandboxes-coding-agents); [Northflank](https://northflank.com/blog/e2b-vs-modal)) | No | None found | Low | Suppliers/competitors on runtime leg | Candidate runtime substrate, not channel. |
| 10 | **Cursor / Claude Code** | Yes — the agents themselves; Claude Code has skills/plugins ecosystem | No — they run as the user | Horizontal channels: MCP registries, skill directories (e.g. [agentskill.sh](https://agentskill.sh/@asoudy/trigger-dev)) | Mid (diffuse) | An `epito` skill/MCP server = zero-integration distribution into every editor session | Cheap side-bet: ship an MCP server + skill early. |

**Re-ranking trigger conditions** (this table is re-justified when any
fires): GitHub opens agent-app self-service (row 1 absorbs more of the
plan); Anthropic Managed Agents adds per-agent platform identity
(wedge halves — escalate to owner immediately); Supabase drops or we
clear the Partner Catalog bar; Vercel Marketplace opens a lighter
"connectable account" path for agent listings.

---

*Charter compliance note: research only — nothing was posted, no one
contacted, no sign-ups. Sources are links + dates throughout; two
claims are flagged as secondary or unrecovered-primary (Reddit thread
via Apigene; stack percentages as community self-report).*
