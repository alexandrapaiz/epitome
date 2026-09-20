# Market brief — docs/market.md

Maintained by the market seat. This revision: **rev 2, 2026-09-19**,
convened on dispatch for two owner questions: the integration universe
(where an epito agent could show up, ranked) and the gaps that
containerized autonomous agents unlock. Rev 1 (2026-09-18) is kept
verbatim at the bottom of this file, marked as rev 1. Every claim
carries a source and a date; "accessed 2026-09-19" means the page was
read today and the event date is as the source states it.

## Orientation: the whole shape in a page

Rev 1 mapped the vibecoder stack. This run widened the lens to every
platform with an agent surface and came back with three findings.

First, the platform world split into two camps in 2026. Every major
vendor now mints agent identity inside its own walls (Microsoft Entra
Agent ID, AWS AgentCore workload identity, Google SPIFFE agent IDs,
Slack bot users, Notion Custom Agents, Asana AI Teammates). Not one of
them issues an identity that follows the agent across platforms or
belongs to the user. That portable, user-owned principal is still
nobody's product. It is ours.

Second, the re-rank the owner asked for under ADR-6: **Slack replaces
Linear as the recommended integration #2**, with Vercel and Notion as
runners-up. The full justification is in §5.

Third, the demand evidence hardened. The OpenClaw crisis (135k GitHub
stars, then 42k exposed instances and a compromised skill registry)
proved people want resident local agents badly enough to run unsafe
ones. The EU AI Act's August 2026 logging deadline and a $300M+
non-human-identity funding wave priced the audit problem. Both are in
§6.

The tier counts, for scale:

| Tier | Count | Members |
|---|---|---|
| build-now | 3 | GitHub (shipped), Slack (recommended #2), editor MCP/skill (bet 2) |
| build-next | 3 | Vercel, Notion, Supabase |
| watch | 9 | Linear, Microsoft, AWS, Google, Stripe, Asana, Atlassian, Clerk, Neon |
| skip | 3 | Zapier/Make, Salesforce AgentExchange, runtime vendors as channels |

**If you only internalize one item, make it §6 gap G4**: the
cross-platform, user-owned agent principal is whitespace every big
vendor is structurally unable to enter, because each one's identity
stops at its own wall. It is the sentence this company is a bet on.

### Ranking laws (do not route around these)

1. **Surface, never dependency** (ADR-6). An integration is a place
   the agent shows up as itself. Core, `epito`, the MCP server, and
   `epitod` work with zero integrations installed.
2. **Self-serve mint or no build slot.** If minting the agent's
   identity on a platform requires a partner approval, waitlist,
   revenue bar, or sales call, the platform can be watched but cannot
   hold a build slot. (GitHub qualifies: plain GitHub Apps are open;
   Slack qualifies: `apps.manifest.create` is open. Vercel's
   marketplace and Supabase's catalog do not, yet.)
3. **The agent appears as itself or the row is mislabeled.** A
   platform where our agent can only act under the owner's token or a
   shared installation is a delegation surface, not an identity
   surface, and is ranked accordingly.
4. **Distribution is a bonus on top of a working surface, never the
   reason the surface exists.** A listing bar may gate the storefront;
   it must never gate the product working.

---

## STANDING RECOMMENDATION (2026-09-19, supersedes 2026-09-18)

**The next integration after GitHub is SLACK.**

Linear was rejected by the owner (ADR-6, "i dont think we should
depend on linear"). Re-ranked from scratch under the four laws above,
Slack wins the slot:

- **Self-serve identity mint, today, no bar.** A Slack app is created
  programmatically via `apps.manifest.create` with an app
  configuration token ([Slack SDK issue #1192](https://github.com/slackapi/python-slack-sdk/issues/1192), accessed 2026-09-19;
  [token types](https://api.slack.com/authentication/token-types), accessed 2026-09-19),
  then installed per workspace through the standard OAuth flow
  ([docs.slack.dev](https://docs.slack.dev/authentication/installing-with-oauth/), accessed 2026-09-19).
  This is structurally the same manifest-mint flow our GitHub provider
  already implements (`POST /app-manifests/{code}/conversions`), so
  the provider is a variation on shipped code, not a new pattern.
- **The agent is a first-class someone.** Each app carries its own bot
  user with granular scopes (`chat:write`, `channels:history`, and the
  `assistant:write` agent surface), its own name and avatar in every
  message, and revocation by uninstall. That satisfies law 3 exactly
  as GitHub Apps do.
- **It is the visibility surface.** GitHub proves the agent works;
  Slack is where a human watches it work. A cron-woken agent posting
  its own standup under its own face is the product demo, in-situ,
  daily. Slack's own positioning is agents-as-teammates via Slackbot
  and MCP ([slack.com/ai-agents](https://slack.com/ai-agents), accessed 2026-09-19;
  [Slackbot GA, 2026-01-13](https://www.salesforce.com/news/press-releases/2026/01/13/slackbot-announcement/)).
- **Distribution is optional, honoring law 4.** Unlisted apps install
  self-serve per workspace; the Slack Marketplace listing (with its
  AI-app review) is a later storefront choice, never a gate on the
  provider working.
- It settles the manifest v0.2 scope grammar for a second platform
  (`slack:chat.write`), which is what the #2 slot exists to prove.

**Runner-up 1: Vercel.** Largest storefront in the stack, native "AI
agents & services" category with unified auth and billing
([changelog](https://vercel.com/changelog/introducing-ai-agents-and-services-on-the-vercel-marketplace), accessed 2026-09-19).
But the identity primitive is partial (installation-scoped
integrations, no member identity for an agent), the bar is Pro-plan
team plus integration server plus approval, and the slot's whole value
is the listing, which violates the spirit of laws 2 and 4. Build-next.

**Runner-up 2: Notion (new since rev 1).** Custom Agents shipped
2026-02-24 and passed one million agents built
([release notes](https://www.notion.com/releases/2026-02-24); [notion.com/product/agents](https://www.notion.com/product/agents), accessed 2026-09-19),
and the Agent API beta (2026-05-13) manages agents programmatically
([developers.notion.com](https://developers.notion.com/guides/notion-agent-apis/overview), accessed 2026-09-19).
Integration bots are real identities in page history. But Notion is
bundling residency natively, so our marginal value there is
portability, not residence. Build-next.

Supabase stands where rev 1 left it: build-ready, list-later, catalog
bar unchanged.

Honest tension on the pick: Slack is Salesforce property, and Slackbot
is being positioned as the orchestrator that fronts third-party agents
([Futurum](https://futurumgroup.com/insights/salesforces-slackbot-goes-ga-is-this-the-real-test-for-agentforce/), accessed 2026-09-19).
We would be building our best demo surface inside a competitor
family's living room. The mitigation is law 1: Slack is one surface of
many, and the provider dies gracefully if the walls close.

One word to accept or reject: **Slack / Vercel / Notion.**

---

## 5. The integration universe (rev 2 ranked table)

Method: for each platform, (a) does it have a native non-human or
agent identity primitive we can mint against, (b) what an epito agent
could do there autonomously, concretely, (c) distribution surface and
its listing bar, (d) tier. All rows accessed 2026-09-19 unless dated.

### Tier: build-now

| Platform | (a) Identity primitive | (b) What the agent does there | (c) Distribution & bar | Why this tier |
|---|---|---|---|---|
| **GitHub** (v1, shipped) | GitHub App: own username, avatar, `<name>[bot]` attribution, short-lived installation tokens | Commits, PRs, reviews, issue triage, release notes, on cron or webhook | Marketplace open for Apps; the Agent HQ "agent app" tier is still waitlist, "anyone can build" promised but not delivered as of today ([changelog 2026-06-02](https://github.blog/changelog/2026-06-02-extend-github-with-agent-apps/); [community discussion](https://github.com/orgs/community/discussions/197310)) | Shipped. Watch the waitlist; join the day it opens. |
| **Slack** | Bot user per app, granular scopes, `assistant:write` agent surface; mint via `apps.manifest.create` ([token types](https://api.slack.com/authentication/token-types); [OAuth install](https://docs.slack.dev/authentication/installing-with-oauth/)) | Posts standups, triages channels, answers in threads, DMs reports, files what it did, all under its own face | Slack Marketplace with AI-app review (no LLM training on customer data, quality bar); unlisted per-workspace install is self-serve, so the bar gates the storefront only | **Recommended #2.** Self-serve mint, first-class identity, the visibility surface. |
| **Editors: Claude Code / Cursor** | None needed in our direction; the editor runs as the user | The `epito` MCP server and skill put mint/deploy/roster inside every session | MCP registries and skill directories, zero listing bar | Bet 2, already decided. Cheapest channel that exists. |

### Tier: build-next

| Platform | (a) Identity primitive | (b) What the agent does there | (c) Distribution & bar | Why this tier |
|---|---|---|---|---|
| **Vercel** | Partial: integrations are installation-scoped; an agent is a marketplace product, not a team member ([blog](https://vercel.com/blog/ai-agents-and-services-on-the-vercel-marketplace)) | Deploys, rolls back, manages env vars, watches build failures and opens fixes | "AI agents & services" category, unified auth/provisioning/billing; bar = Pro team + integration server + approval; Agent Gallery is curated ([digitalapplied survey](https://www.digitalapplied.com/blog/ai-agent-marketplaces-2026-discovery-distribution)) | Biggest storefront in the stack, but the bar gates the value (laws 2, 4) and Vercel part-competes on runtime (Sandbox, Workflow, eve). Build when the listing is worth its build. |
| **Notion** | Yes: integration bots are identities in page history; Custom Agents have schedules/triggers; Agent API beta manages agents programmatically ([releases 2026-05-13](https://www.notion.com/releases/2026-05-13); [agent APIs](https://developers.notion.com/guides/notion-agent-apis/overview)) | Maintains wikis and databases, files meeting digests, syncs rosters, answers from workspace knowledge | Integration gallery; agents native to the product (1M+ Custom Agents built since 2026-02-24) | Real primitive, real demand, but Notion bundles residency itself; our value is portability. Second candidate after Slack proves the multi-platform grammar. |
| **Supabase** | OAuth 2.1 server, still beta ([changelog #38022](https://supabase.com/changelog/38022-oauth-2-1-server-capabilities-for-supabase-auth)); per-agent DB credentials feasible via management API | Owns its own scoped DB access: migrations, seed jobs, scheduled data hygiene, as itself | Partner Catalog bar unchanged: registered business + meaningful revenue or VC backing ([docs](https://supabase.com/docs/guides/integrations/partner-catalog)); epito.me still fails it | Rev 1 verdict stands: build when a user demands it, list later. |

### Tier: watch

| Platform | (a) Identity primitive | (b) What the agent could do | (c) Distribution & bar | Why watch, not build |
|---|---|---|---|---|
| **Linear** | Yes, the cleanest: agents as app users, assignable, mentionable, unbilled ([developers](https://linear.app/developers/agents); AIG unchanged since [2025-07-30](https://linear.app/changelog/2025-07-30-agent-interaction-guidelines-and-sdk)) | Takes assigned issues, reports progress, closes with PR links | Integration directory, AIG compliance bar (10s first response) | **Owner-rejected as #2 (ADR-6).** Stays on the board as a future surface; returns only on the owner's word. |
| **Microsoft** (Entra Agent ID / Agent 365) | Yes, and now interoperable: third-party agents register via the Entra ID Auth SDK sidecar or workload identity federation ([Learn](https://learn.microsoft.com/en-us/microsoft-agent-365/developer/third-party-identity-providers)); registry consolidates into Agent 365 2026-05-01 ([what's new](https://learn.microsoft.com/en-us/entra/fundamentals/whats-new)) | An epito agent could register its identity into a customer's Entra tenant for enterprise governance while keeping its epito manifest | M365 agent store via Partner Center; bar = Microsoft AI Cloud Partner Program + publisher verification ([submit docs](https://learn.microsoft.com/en-us/microsoft-agent-365/developer/submit-agent-partner-center)) | The federation path is the future enterprise story ("epito agents, governed in your Entra"), not a 2026 build. Per-user pricing means their buyer is not ours. |
| **AWS** (Bedrock AgentCore Identity) | Yes: workload identity distinct from IAM roles, own ARN per agent; managed consent portal added 2026-09 ([overview](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/identity-overview.html); [what's new](https://aws.amazon.com/about-aws/whats-new/2026/09/amazon-bedrock-agentcore/)) | Pattern supplier more than surface; a future RuntimeProvider could target AgentCore | Enterprise marketplace motions; not our buyer | Validates the identity-primitive thesis from the biggest cloud. Watch the primitives, skip the platform. |
| **Google** (Gemini Enterprise / A2A) | Yes: per-agent cryptographic SPIFFE IDs ([Infosecurity](https://www.infosecurity-magazine.com/news/google-ai-agent-identities-gemini/)); A2A v1.2 under the Linux Foundation, production across 150 orgs ([TNW](https://thenextweb.com/news/google-cloud-next-ai-agents-agentic-era)) | An A2A agent card for epito agents would make them discoverable/callable by other agents | Google Cloud Marketplace A2A agent registration ([docs](https://docs.cloud.google.com/gemini/enterprise/docs/register-and-manage-marketplace-agents)); enterprise procurement bar | A2A card support is a cheap future interop feature for `epitod`, not a distribution play. See trap T1 before touching the marketplace. |
| **Stripe** | Partial: restricted keys scope an agent; ACP (with OpenAI) and AP2 (Google, donating to FIDO) define delegated payment mandates ([ACP docs](https://docs.stripe.com/agentic-commerce/acp); [Orium on ACP/AP2/x402](https://orium.com/blog/agentic-payments-acp-ap2-x402)) | Reconciles, reports, flags anomalies read-only; payments themselves are trap T2 | App Marketplace, ~4-day review | Rev 1 verdict stands and hardened: wrong first proof for an identity product. |
| **Asana** | Yes: AI Teammates are discoverable, assignable workspace members via REST API and MCP ([forum changelog](https://forum.asana.com/t/upcoming-ai-teammates-and-agent-api-support/1142767); [June 2026 launch](https://investors.asana.com/news-releases/news-release-details/asana-unveils-operating-system-human-agent-teams)) | Takes assigned tasks, reports status, exactly the Linear shape | No open directory found; AI Studio Pro is sales-gated | The primitive is right but gated behind top-tier sales-led plans; the vibecoder is not there. |
| **Atlassian** (Rovo / Forge) | Partial and inverted: Marketplace agents must run on Forge, Atlassian's runtime ([marketplace agents](https://support.atlassian.com/rovo/docs/marketplace-agents/); [Forge Rovo agent](https://developer.atlassian.com/platform/forge/extend-atlassian-products-with-a-forge-rovo-agent/)) | Little, as ourselves: their model absorbs the agent body into their cloud, the opposite of ADR-2 residency | Atlassian Marketplace; customer-pays AI credits (a pricing precedent worth noting) | Structural mismatch with our runtime leg. The `rovo-agent-connector` EAP ([manifest ref](https://developer.atlassian.com/platform/forge/manifest-reference/modules/rovo-agent-connector/)) may open an external-agent path; re-check next quarter. |
| **Clerk** | In our direction, technology not surface: CIMD beta (2026-08-06) lets an OAuth client's `client_id` be an HTTPS URL serving its metadata ([changelog](https://clerk.com/changelog/2026-08-06-client-id-metadata-documents)) | Nothing "in" Clerk; but a hosted epito manifest URL as a CIMD `client_id` would give every epito agent a stable OAuth client identity against any CIMD-compatible provider | No marketplace | Fold in as mechanism when a second CIMD-compatible provider matters. Ally, not channel (unchanged from rev 1). |
| **Neon** | Partial: per-agent projects/branches via API, Agent Plan | Per-agent Postgres under our runtime | Partnership/credits track, no directory | Supplier track (unchanged). |

### Tier: skip

| Platform | Why skip |
|---|---|
| **Zapier / Make** | The anti-model, named by the vendor itself: Zapier MCP fronts 9,000+ apps with "one set of managed credentials" in Zapier's vault ([zapier.com](https://zapier.com/blog/best-ai-agents/), accessed 2026-09-19). A master key held by a middleman is precisely what our primitive replaces (§6 G1). No per-agent principal in their model, no reason to put our agent behind their key. |
| **Salesforce AgentExchange** | Security review + partner program + enterprise motion ([FAQ](https://help.salesforce.com/s/articleView?id=000394757&language=en_US&type=1)); the $50M builders initiative ([SalesforceDevops](https://salesforcedevops.net/index.php/2026/04/14/agentexchange-salesforces-bet-that-trust-can-scale-with-agentic-speed/)) confirms even Salesforce knows the bar is too high for small shops. Slack covers the ecosystem's useful surface at 1% of the cost. |
| **Trigger.dev / Modal / E2B / Cloudflare as channels** | Competitors or suppliers on single legs (rev 1 analysis stands; Cloudflare remains the closest architectural bundle). Candidate substrates, not channels. |

Not researched this run, flagged for the next weekly: OpenAI's agent
platform surfaces, Discord bots as a vibecoder-adjacent identity
surface, and the AWS Marketplace agent category. Absence from the
table is absence of research, not a verdict.

**Re-ranking trigger conditions (rev 2).** Carried from rev 1: GitHub
opens agent-app self-service; Anthropic Managed Agents adds per-agent
platform identity (checked today: still owner-vault, no per-agent
platform principal found; the Claude Tag identity model governs
permissions, not third-platform identity, per [Help Net Security, 2026-06-24](https://www.helpnetsecurity.com/2026/06/24/anthropic-claude-tag-agent-identity-model/), accessed 2026-09-19);
Supabase clears or drops its bar; Vercel opens a lighter listing path.
New: Slack changes app-creation or marketplace policy for AI apps;
Atlassian's `rovo-agent-connector` exits EAP with an external-runtime
path; Asana opens AI Teammates below the sales tier.

---

## 6. Gaps: what containerized autonomous agents unlock

The phase-2 primitive being ranked against the world here: a
persistent container on the user's own machine (`epitod`, systemd
units + timers, rootless podman), holding a real per-agent identity,
woken by cron/webhook/event, acting across platforms with no human
session. Four gaps that are real, then three traps.

### G1. Cross-SaaS autonomy without a middleman holding master keys

**Evidence it's real.** The glue layer's own architecture is the
complaint: Zapier MCP fronts 9,000+ apps through "one set of managed
credentials" in its vault ([zapier.com](https://zapier.com/blog/best-ai-agents/), accessed 2026-09-19).
Meanwhile the MCP ecosystem's auth is failing in the field: only 8.5%
of MCP servers in the wild use OAuth at all (Astrix Security research,
cited by [explainx MCP security guide](https://www.explainx.ai/blog/mcp-security-guide-2026), accessed 2026-09-19; secondary source, flagged),
over-scoped tokens are called the most common misconfiguration
([Security Boulevard](https://securityboulevard.com/2026/05/mcp-authentication-explained-oauth-2-0-tokens-and-security-for-ai-tool-connections/), 2026-05),
and Cloudflare shipped optional OAuth scopes in September naming MCP
agents "requesting the union of everything they might do" as the
motivating case ([InfoQ](https://www.infoq.com/news/2026/09/cloudflare-optional-oauth-scopes/), 2026-09).

**What our primitive contributes.** No vault in the middle. Each agent
holds its own principal minted on each platform (GitHub App, Slack
app), scoped in the manifest, revocable on the platform where it
lives. The blast radius of one compromised agent is that one agent's
scopes on those platforms, nothing else.

**What it does not solve.** Scope coarseness is the platform's, not
ours: if Slack's finest scope is `chat:write` everywhere, we cannot
make it channel-level ([p0.dev on scope granularity](https://p0.dev/blog/oauth-scopes-dont-equal-secure-mcp-authorization/), accessed 2026-09-19).
And nothing here stops a prompt-injected agent from misusing scopes it
legitimately holds.

### G2. The resident local agent, done safely

**Evidence it's real.** OpenClaw is the strongest demand signal of
2026 and the strongest indictment of the DIY version: 135,000+ GitHub
stars within weeks ([DEV](https://dev.to/waxell/the-openclaw-security-crisis-135000-exposed-ai-agents-and-the-runtime-governance-gap-e26), accessed 2026-09-19),
then 42,000 instances exposed on the public internet with 93% showing
critical auth flaws ([Sliq timeline](https://getsliq.com/blog/openclaw-security-incidents-timeline), accessed 2026-09-19),
API keys and OAuth tokens stored in plaintext config
([Sangfor](https://www.sangfor.com/blog/tech/openclaw-ai-agent-2026-explained), accessed 2026-09-19),
a CVSS 8.8 one-click RCE (CVE-2026-25253, disclosed 2026-02-03), and
roughly 12% of its ClawHub skill registry confirmed malicious (341 of
2,857, [DEV](https://dev.to/tiamatenity/openclaw-how-a-popular-ai-agent-platform-became-a-security-catastrophe-1mg2), accessed 2026-09-19).
People want an agent that lives on their machine so badly they ran
this. The quieter version of the same demand: the self-hosted
automation movement (n8n and kin) is explicitly credential-driven,
"credentials and execution logs stay on your own infrastructure"
([n8n docs](https://docs.n8n.io/privacy-security/privacy/); [AI Tool Pipelines](https://www.aitoolpipelines.com/articles/self-hosted-ai-automation-data-privacy-2026), accessed 2026-09-19).

**What our primitive contributes.** Exactly the three things OpenClaw
lacked: per-agent containment (rootless podman, one container per
agent, `DynamicUser` fallback), secrets out of plaintext (OS keychain
proposal, phase 2), and identity that is not the owner's (a stolen
agent credential is that agent's scopes for at most an hour, per the
threat model in `docs/architecture.md`). Local-first is the
architecture, not a compromise: nothing leaves the machine in phases
1-2.

**What it does not solve.** Prompt injection into the model, a
malicious skill the user chooses to install, an unpatched host, and
single-machine availability (the laptop closes, the agent sleeps). We
should say all four out loud in the docs rather than let a buyer
assume otherwise.

### G3. Per-agent audit and attribution as the compliance floor

**Evidence it's real.** The EU AI Act's high-risk obligations reached
full enforcement on 2026-08-02, and Article 12 requires tamper-evident
logs sufficient to reconstruct what an agent did and under what inputs
([AI2sql analysis](https://ai2sql.io/ai-blog/eu-ai-act-agent-audit-trails-database); [DEV practitioner writeup](https://dev.to/igorganapolsky/your-compliance-team-will-ask-for-an-ai-agent-audit-trail-before-august-2-heres-the-part-most-h2n), accessed 2026-09-19).
The market priced the problem the same year: Oasis Security $120M
Series B, NewCore $66M seed ([SiliconANGLE, 2026-06-15](https://siliconangle.com/2026/06/15/newcore-launches-security-first-identities-ai-agents-closing-66m-seed-funding-round/)),
Oak $60M ([TechCrunch, 2026-07-15](https://techcrunch.com/2026/07/15/backed-by-60m-in-funding-oak-steps-out-of-stealth-to-fix-the-identity-mess-that-ai-agents-are-making-worse/)),
GitGuardian $50M ([SiliconANGLE, 2026-02-11](https://siliconangle.com/2026/02/11/gitguardian-raises-50m-expand-non-human-identity-ai-agent-security/)),
$392M announced around RSAC alone ([Software Strategies, 2026-03-28](https://softwarestrategiesblog.com/2026/03/28/agentic-ai-security-startups-funding-mna-rsac-2026/)).

**What our primitive contributes.** Attribution that cannot be
retrofitted: when the agent is a distinct principal, every commit,
message, and API call lands under its name on the platform itself, and
`audit.jsonl` records every mint, token, and deploy locally,
append-only. An owner-token agent can never produce this trail, no
matter how much logging is bolted on, because the platform saw the
owner.

**What it does not solve.** We are the substrate, not the GRC product.
Conformity assessment, retention policy, and governance dashboards are
what Oasis and Entra sell to enterprises; competing there is trap T3.
Our claim is narrower and true: an epito roster is auditable by
construction.

### G4. The whitespace: a portable, user-owned principal (the priority item)

**Evidence it's real.** Assemble §5's column (a) and look at it once:
Microsoft mints agent identity into Entra, AWS into AgentCore, Google
into SPIFFE IDs on its platform, Slack into its apps, Notion and Asana
into their workspaces. Every primitive is real and every one stops at
its vendor's wall, priced and governed inside that estate. Nobody
issues the agent an identity the *user* owns, that follows it from
GitHub to Slack to its own database, minted from one manifest. The
enterprise version of the closest thing (Agent 365) starts at
$15/user/month inside the Microsoft estate (rev 1, sourced). The indie
version does not exist. That is the product.

**What our primitive contributes.** The manifest as the portable spine:
one `agent.toml`, N platform principals, one roster, one audit trail,
on hardware the user owns.

**What it does not solve.** Portability depends on platforms keeping
open app/OAuth surfaces. The same vendors building walled identity
could narrow those surfaces, and law 1 (never a dependency) is our
only structural hedge. Named plainly: this gap is whitespace partly
because it is the one position the giants' incentives point away from,
and their incentives could change.

### The traps (attractive, and wrong)

**T1. Cross-org agent-to-agent and the enterprise agent marketplaces.**
A2A v1.2 runs in production across 150 organizations under the Linux
Foundation ([TNW](https://thenextweb.com/news/google-cloud-next-ai-agents-agentic-era), accessed 2026-09-19),
and marketplaces are multiplying (Gemini Enterprise, AgentExchange,
the M365 agent store). It looks like a standard to ride and shelves to
be on. It is a trap for us now because every shelf has a bar we fail
by construction (partner programs, publisher verification, security
reviews, revenue thresholds), the buyers are enterprises with
procurement cycles, and A2A solves discovery and messaging between
agents, not principal-hood on platforms. The cheap non-trap version:
an A2A agent card emitted by `epitod` someday, as interop, not as
strategy.

**T2. Agentic payments.** ACP, AP2 mandates, x402: the loudest
protocol race of the year ([Orium](https://orium.com/blog/agentic-payments-acp-ap2-x402), accessed 2026-09-19).
Rev 1 already ranked payment scopes as the scariest to delegate; rev 2
hardens that to a trap. The protocols are buyer-agent commerce, not
resident-worker identity; the mandate primitives are being taken over
by card networks and FIDO, leaving no indie wedge; and one payment
incident would be existential trust damage for a young identity
product. Read-only finance (reporting, reconciliation alerts) is the
most an epito agent should touch through 2027.

**T3. Selling into the "digital employee" enterprise wave.** McKinsey
announcing 25,000 "digital employees," Goldman deploying Devin
([AI Commission roundup](https://aicommission.org/2026/09/ai-agents-are-changing-how-startups-hire-and-build-teams/), accessed 2026-09-19; secondary source, flagged)
reads like our thesis validated at scale, and it is, as a register.
As a target market it is a trap: Gartner projects over 40% of agentic
AI projects canceled by end-2027 on cost, unclear value, and risk
controls, and estimates only ~130 of thousands of vendors are real
([Gartner, 2025-06-25](https://www.gartner.com/en/newsroom/press-releases/2025-06-25-gartner-predicts-over-40-percent-of-agentic-ai-projects-will-be-canceled-by-end-of-2027)).
Chasing those buyers means competing with Agent 365's bundled
distribution using a sales motion we do not have, for deployments
likelier than not to be canceled. Our buyer stays the builder running
an org of agents on personal subscriptions (vision §0), and the
enterprise wave's real gift to us is vocabulary and urgency, not
customers.

---

## To the seat that builds on this

The central problem in one sentence: every platform now gives agents
an identity that stops at its own wall, and epito.me exists to issue
the one identity that crosses them, owned by the user.

The design test for any integration decision this document informs:
can the identity be minted self-serve today, does the agent appear
there as itself, and does the product still work if this platform
vanishes tomorrow? If any answer is no, the platform is watched, not
built.

*Charter compliance note (rev 2): research only; nothing posted, no
one contacted, no sign-ups, no waitlists joined. Flagged secondary or
unverified claims: the Astrix 8.5% OAuth figure (via explainx), the
McKinsey/Goldman digital-employee numbers (via AI Commission roundup),
and the Atlassian `rovo-agent-connector` external-agent path (EAP
docs only).*

---

## 7. Rev 2 addendum (2026-09-19, second dispatch): agent makers, OpenClaw, GPT Astra

Convened on ADR-9 ("we dont necessarily want to be agent builders, we
want agent cars... open claw is a big think to look into as well as
gpt astra"). Three answers, each ending in a recommendation the owner
can accept or reject in one word. All sources accessed 2026-09-19.

### 7.1 OpenClaw as opportunity, not just evidence

**What it is now, post-crisis.** The project survived and changed
hands. The CVSS 8.8 RCE was patched in `v2026.1.29` on 2026-01-30,
with three security advisories the same day ([Prime Rogue](https://primerogueinc.com/blog/openclaw-security-crisis-structurally-broken-in-february-2026-what-naive-deployers-need-to-know-before-its-too-late/)).
On 2026-02-14 creator Peter Steinberger joined OpenAI to lead
personal-agent development and the project moved to an independent,
OpenAI-sponsored foundation ([Conscia](https://conscia.com/blog/the-openclaw-security-crisis/)).
The `2026.4` line shipped origin validation, sandbox-by-default, and
encrypted credential storage, after 13 patch releases in March alone
([Nebius hardening guide](https://nebius.com/blog/posts/openclaw-security)).
OpenClaw 2.0 (`v2026.8.1`, 2026-08-30) added a redesigned UI and a
plugin/integration hub ([release docs](https://docs.openclaw.ai/releases/2026.8.1/plugins-and-integrations)).
September is a declared "fix the foundation" phase: systemic P0s
(event loop starvation, session drift) are being worked ahead of
feature work, patch `2026.9.5` ([ecosystem digest, 2026-09-19](https://github.com/duanyytop/agents-radar/issues/3358)).
Reading: stabilizing under new governance, not dying, but not stable.

**How its agents authenticate today, and where we slot in.** The
architecture is kernel-plugin: a Gateway control plane authenticates
all inbound connections, and each agent's auth profiles live in
`openclaw-agent.sqlite`, with a built-in secret store, the option to
mount external vault tokens, and locally stored OAuth refresh tokens
treated as canonical ([Gateway auth docs](https://docs.openclaw.ai/gateway/authentication); [OAuth docs](https://docs.openclaw.ai/concepts/oauth); [TeamPassword guide](https://teampassword.com/blog/securing-openclaw-guide)).
That is the owner-credential pattern this company exists to replace:
the agent holds the owner's refresh tokens, encrypted now, but still
the owner's. The integration point exists twice over: the external
vault mount (epito as the credential backend that hands an OpenClaw
agent its own scoped platform token instead of the owner's) and the
2.0 plugin hub, which installs plugins and vetted MCP connectors
(an `epito` MCP connector reaches every OpenClaw install without
their approval). Their own roadmap fixed credential *storage*; it has
not touched credential *identity*. The gap we fill is untouched.

**The channel.** The community is large and locatable: the OpenClaw
Discord passed 100,000 members in roughly six weeks from a January
2026 founding ([openclaw.report](https://openclaw.report/news/openclaw-discord-100k-members))
and stands at ~176,000 ([community listing](https://openclaw-ai.net/en/community)),
with 13,000+ ClawHub skills and a 43k-star curated list
([ClawTrust](https://clawtrust.ai/blog/best-openclaw-skills)). A
working identity connector demonstrated there reaches more resident-
agent users than every platform marketplace in §5 combined.

**The honest risks.** The brand is radioactive in security circles:
at least four academic security papers dissect it by name and the
crisis is its own genre of coverage. Association helps only if we are
unmistakably the fix, never a partner sharing blame; the positioning
is "your OpenClaw agents, given real identities," not co-branding.
Platform risk is real and specific: the foundation is OpenAI-
sponsored and its creator now builds personal agents inside OpenAI,
so native identity could arrive from above. And ClawHub's 12%
malicious rate means listing there needs our own signing story told
loudly, or the channel taints the product.

**Recommendation (accept/reject: OpenClaw yes/no).** Tier:
**build-next, first of the agent-maker track**, behind Slack. Shape:
a research-to-prototype spike (an `epito` MCP connector serving
per-agent platform tokens to OpenClaw agents), scoped only after the
Slack provider ships, gated on the foundation still standing at spike
time. Not a platform surface; the first MAKER integration (§7.3).

### 7.2 GPT Astra, identified

**The name matches one real thing.** "GPT Astra" is **GPT-6 Astra**,
OpenAI's flagship model: limited release 2026-09-03, general
availability the next day, positioned on long-horizon agentic tasks,
computer use, and browsing, distributed via the OpenAI API, Azure,
and AWS Bedrock ([openai.com](https://openai.com/index/gpt-6-astra/); [Al Jazeera, 2026-09-04](https://www.aljazeera.com/economy/2026/9/4/openai-unveils-gpt-6-astra-amid-rising-scrutiny-and-safety)).
It is OpenAI's first model rated Critical for cybersecurity
capability under its own Preparedness Framework ([safety overview](https://openai.com/index/safety-overview-gpt-6-astra/)).
Name collision noted plainly: Google DeepMind also runs a "Project
Astra" assistant-research effort; given the owner wrote "gpt astra"
the model is the near-certain referent, and Google's Astra was not
researched this run (flagged).

**What it means for us.** Astra is a model, not an agent maker and
not a platform: it has no identity primitive and no integration
surface beyond the API. Under ADR-8 it is exactly a routable brain:
`[runtime].model = "gpt-6-astra"`, swappable without changing who the
agent is. The strategic content is second-order and favors the wedge:
a Critical-rated cyber-capable model running long-horizon agents makes
the owner-credential pattern strictly more dangerous (rev 2 §2's
demand quotes, now with a sharper model behind them), and Astra ships
into ChatGPT and Codex agents that still act as their user. One more
thread ties the owner's two names together: OpenClaw's creator now
leads personal agents at OpenAI, and OpenClaw's foundation is
OpenAI-sponsored. Both names point at the same axis, OpenAI's
personal-agent push, which is a maker to integrate, never a surface
to depend on.

**Recommendation (accept/reject: Astra-as-runtime yes/no).** Tier:
**watch, as model supplier**. Action: `gpt-6-astra` joins the routing
examples in manifest v0.2 docs; no integration slot exists to build.

### 7.3 The agent-maker landscape (the new map dimension)

ADR-9 splits the map into two kinds of target. A **surface** is where
an agent acts (§5's table). A **maker** is what builds and runs the
agent's brain and loop; under "we are the car, not the driver," every
maker's agent is a candidate rider. The question per maker: how do
its agents authenticate to outside services today, and where does an
identity layer slot in.

| Maker | How its agents authenticate today | Where our identity layer slots | Tier |
|---|---|---|---|
| **OpenClaw** | Owner's OAuth refresh tokens + secret store, per-agent profiles in `openclaw-agent.sqlite` (docs cited in §7.1) | External vault mount + 2.0 plugin/MCP hub; §7.1's spike | **Build-next** (first maker) |
| **LangGraph / LangChain** | Tools read API keys from env/config; 100+ prebuilt tools, no identity layer ([langchain.com](https://www.langchain.com/resources/ai-agent-frameworks); [comparison](https://levelup.gitconnected.com/langgraph-vs-crewai-vs-autogen-which-agent-framework-should-you-actually-use-in-2026-b8b2c84f1229)) | `epito token <name>` handed into tool constructors; the shape is a thin community package, cheap because the CLI already emits scoped tokens | **Build-next** (SDK-level, after OpenClaw proves the pattern) |
| **CrewAI** | Same env-key pattern, ~20 bundled tools (same sources) | Same token-handoff shape as LangGraph | Watch (follows LangGraph work for free) |
| **OpenAI Agents SDK / AgentKit** | Developer API keys + Connector Registry; Agent Builder retires 2026-11-30, Agents SDK canonical with native sandbox execution since April 2026 ([openai.com](https://openai.com/index/the-next-evolution-of-the-agents-sdk/), accessed 2026-09-19) | Token handoff into SDK tools is possible today; note OpenAI is absorbing the runtime leg (sandboxes), identity still owner-side | Watch |
| **AutoGen / Microsoft Agent Framework** | Enterprise direction: Entra-anchored, A2A built in ([glukhov A2A survey](https://www.glukhov.org/ai-systems/comparisons/a2a-protocol-2026-adoption/)) | Via A2A card interop, not a bespoke integration | Watch |
| **Google ADK** | A2A native, Google-cloud anchored (same survey) | Same: A2A interop | Watch |

**A2A agent cards: yes, this is the consolidating interop standard.**
v1.0 shipped April 2026, 150+ organizations, Linux Foundation
governance; built-in support in Google ADK, Microsoft Agent
Framework, and BeeAI, plus Azure AI Foundry, Copilot Studio, and
Bedrock AgentCore Runtime ([glukhov](https://www.glukhov.org/ai-systems/comparisons/a2a-protocol-2026-adoption/); [Go Micro](https://go-micro.dev/blog/2026/06/18/agents-across-frameworks-a2a.html)).
The card is a JSON document served at `/.well-known/agent-card.json`
([implementation guide](https://atlan.com/know/mcp/a2a-protocol-implementation-guide/)),
which is to say: it is a document our daemon can emit per agent for
roughly the cost of a template. Emitting a card makes every epito
agent discoverable by every A2A framework without adopting anyone's
runtime, which is the ADR-6-compliant way to ride the standard.
Trap T1 (§6) still stands unchanged for the enterprise A2A
*marketplaces*; the card itself is interop, not a marketplace.

**Recommendation (accept/reject: makers-track yes/no).** Adopt MAKERS
as a standing second dimension of this map, ranked by the same laws
plus one maker-specific test: does the maker hand credentials to its
agents in a way we can replace without forking it. And promote A2A
agent-card emission from "someday" to a tracked manifest v0.2
consideration, per ADR-9's third effect.

*Charter compliance note (addendum): research only; nothing posted,
no one contacted. Flagged: Google Project Astra not researched this
run; OpenClaw Discord member count from a community listing
(secondary); the deck at docs/presentations/market-rev2/ was left
untouched, since no finding falsifies a slide's copy (slide 5's
OpenClaw numbers remain true as stated; the opportunity reading lives
here).*

---

## 8. LangSmith (2026-09-20, third dispatch): observability, deployment, and a competitor's credential layer

Convened on the owner's ask (2026-09-20): "see how our product could
work together with langsmith, like an integration." Four answers:
what LangSmith exposes, the coupling in both directions, the
distribution path, and a tiered verdict. This section amends the
§7.3 LangGraph row. All sources accessed 2026-09-20; event dates as
the source states them.

### 8.1 Surfaces: what LangSmith exposes today

LangSmith is no longer one product. It is a tracing/evals SaaS, a
hosted agent runtime (LangSmith Deployment, formerly LangGraph
Platform), a no-code agent workspace (Fleet, the March 2026 rename of
Agent Builder), and a newer opinionated hosted harness (Managed Deep
Agents, public beta 2026-08-07). Each has a different opening for us.

| Surface | What it exposes | The opening for an identity layer |
|---|---|---|
| **Tracing SDK** | Arbitrary `metadata` dict and string `tags` on any run, set by `@traceable(metadata=...)`, `langsmith_extra=`, `ls.tracing_context(metadata=...)` (context propagates to child spans), or `rt.metadata[k]=v` at runtime ([add metadata and tags](https://docs.langchain.com/langsmith/add-metadata-tags)). UI filter `metadata.<key>:<value>`, numeric `metadata.retries:>=3` ([filter traces](https://docs.langchain.com/langsmith/filter-traces)); SDK/REST filter `and(eq(metadata_key, "k"), eq(metadata_value, "v"))` on `client.list_runs()` ([trace query syntax](https://docs.langchain.com/langsmith/trace-query-syntax)). The only special key documented is `thread_id`, which groups traces into threads ([concepts](https://docs.langchain.com/langsmith/observability-concepts)). | **There is no agent-identity field.** Attribution in LangSmith is by project, API key, and thread. A principal fits only as user-defined metadata, which is exactly enough: metadata is filterable, exact-match, and persisted with the run. |
| **OTLP ingest** | `OTEL_EXPORTER_OTLP_ENDPOINT=https://api.smith.langchain.com/otel`, header `x-api-key`, optional `Langsmith-Project`; span attributes `langsmith.metadata.{key}` become metadata and `langsmith.span.tags` become tags. "Arbitrary span attributes do not automatically become filterable metadata." ([trace with OpenTelemetry](https://docs.langchain.com/langsmith/trace-with-opentelemetry); [OTel launch post](https://blog.langchain.com/opentelemetry-langsmith/)) | epitod's own audit emitter could ship spans here with **zero LangChain code in the agent**. This is the door that costs nothing and depends on nothing. |
| **LangSmith Deployment** (cloud) | Plus plan or above; Serverless (scale-to-zero) or Dedicated; env vars and secrets entered at deployment configuration via UI or the `env` field of `langgraph.json` ([deploy to cloud](https://docs.langchain.com/langsmith/deploy-to-cloud)). No runtime hook to an external secret manager is documented; the cloud env-var page lists only server tunables (Datadog, OTel, pool sizes) ([env vars](https://docs.langchain.com/langsmith/env-var-cloud)). | Secrets are pasted at deploy time. That is the stored-owner-key pattern, and it is the reason a credential slot matters here. |
| **Custom auth** | `@auth.authenticate` runs on every request, may call external services (`await fetch_user_tokens(api_key)`), and its returned dict lands in `config["configurable"]["langgraph_auth_user"]` for every node; "supported for all plans"; not available to the bare OSS library ([custom auth](https://docs.langchain.com/langsmith/custom-auth); [auth overview](https://docs.langchain.com/langsmith/auth)). Whether a cron-triggered run gets an auth context is **not documented** (checked [cron jobs](https://docs.langchain.com/langsmith/cron-jobs) and the auth pages). | A request-time hook that can fetch a token from anywhere and hand it to the graph. Designed for per-USER delegation; usable for per-agent minting. |
| **Agent Auth (beta)** | `client.create_oauth_provider(client_id, client_secret, auth_url, token_url)` for any OAuth 2.0 provider; `client.authenticate(provider, scopes, user_id, agent_id=...)`; "By default, tokens are scoped to the calling agent using the Assistant ID parameter"; "We store and refresh OAuth tokens" ([agent auth](https://docs.langchain.com/langgraph-platform/agent-auth)). | The first place LangSmith names an `agent_id`. Tokens are user-delegated and live in LangSmith's vault, but the provider is pluggable: an epito OAuth endpoint could be registered as a provider. |
| **Agent Server / assistants** | Assistant = "an instance of a graph with a specific configuration," versioned; threads, runs, crons (`client.crons.create(assistant_id, schedule, input)`); default auth is a LangSmith API key in `x-api-key` ([assistants](https://docs.langchain.com/langsmith/assistants); [agent server](https://docs.langchain.com/langsmith/agent-server)). **No owner, creator, or identity field on the assistant object** is documented. | Assistants are configurations, not someones. Identity is whoever holds the workspace key. |
| **Workspace auth** | Two key kinds: Personal Access Tokens (inherit the user; deleted with the user) and Service Keys ("service principals with administrator privileges") ([API keys](https://docs.langchain.com/langsmith/create-account-api-key); [RBAC](https://blog.langchain.com/access-control-updates-for-langsmith/)). | No per-agent key exists. Every deployed agent authenticates to LangSmith as the workspace. |
| **Fleet** (no-code, 2026-03-19) | "Agent identity" defined as "whose credentials the agent uses": **Claws** use "the same API keys and OAuth tokens, regardless of user"; **Assistants** use each invoking user's OAuth. "Once an agent identity is set, it cannot be changed." Tool keys live as workspace secrets, `FLEET_`-prefixed ([agent identity](https://docs.langchain.com/langsmith/fleet/agent-identity); [workspace admin](https://docs.langchain.com/langsmith/fleet/workspace-admin); [launch post](https://www.langchain.com/blog/introducing-langsmith-fleet)). Permissions: clone / run / edit. | Their word "identity" means credential mode, not principal. Neither mode gives the agent its own account on GitHub or Slack. |
| **Managed Deep Agents** (public beta 2026-08-07) + **Connections** (2026-09-09) | `mda init/dev/deploy`; identity = who may call the deployment (LangSmith API key or Supabase JWT) ([identity](https://docs.langchain.com/langsmith/javascript/managed-deep-agents-identity)). Connections: named credentials in the workspace, owner axis agent-owned vs user-owned, type axis static secret vs OAuth grant; catalog of 23+ services incl. GitHub; custom providers via `--authorize-url`/`--token-url`/`--scope`; `connections.get(slug, {type})` returns the raw credential string; rotation by re-running `create`, effective next run, no redeploy; no REST API documented ([connections docs](https://docs.langchain.com/langsmith/javascript/managed-deep-agents-connections); [Connections post](https://www.langchain.com/blog/connections-managed-credentials-and-per-caller-identity-for-managed-deep-agents); [MDA beta post](https://www.langchain.com/blog/managed-deep-agents-is-now-in-public-beta)). | A credential store with a custom-OAuth slot, eleven days old. The agent-owned mode is a static secret; the user-owned mode makes the human the actor: "the issue lands in GitHub opened by the person who asked. `user.login` in the response is their handle, not a bot's." |
| **Evals, annotation queues** | Present in the product; not researched beyond confirming they operate on the same run metadata (flagged: no deeper read this run). | Whatever principal we put in metadata is available to slice eval datasets by agent. No identity-specific opening. |

### 8.2 The coupling, both directions

**(a) epito → LangSmith: "which agent did this" as a filter dimension.**
Feasible today, cheap, needs nobody's permission. Two routes:

1. *Inside a LangGraph agent*: an `epito.langsmith_context(agent)` helper
   wraps `ls.tracing_context(metadata={...})` so every span in the run
   carries a flat principal record (flat keys, because filter matching is
   exact and type-sensitive):

   ```python
   {"epito_agent": "historian",
    "epito_manifest_sha": "3f9c...",
    "epito_github": "historian-epito[bot]",
    "epito_slack": "B0HISTORIAN",
    "epito_model": "claude-opus-5"}        # ADR-8: model recorded, never the key
   ```

   A LangSmith user then filters `metadata.epito_agent:historian` in the
   UI or `and(eq(metadata_key,"epito_agent"), eq(metadata_value,"historian"))`
   in the SDK, and gets exactly the slice our local audit trail calls the
   same name. LangSmith has no native equivalent: its attribution stops at
   project, API key, and `thread_id`. Cost: one helper of roughly fifty
   lines in `@epito/langchain`, documented as a convention.
2. *Outside any agent code*: epitod's audit emitter exports OTLP spans
   with `langsmith.metadata.epito_agent` etc. to the `/otel` endpoint.
   Every epito agent's actions, on any framework or none, appear in the
   user's LangSmith project attributed to the real principal. The user
   supplies the LangSmith API key in the manifest's optional
   `[observability]` block; if absent, nothing changes (ADR-6).

Limit, stated plainly: metadata is a convention, not a schema. Nothing
stops a LangSmith user from writing `epito_agent: "whatever"`; the
proof that a trace really belongs to the principal is the passport
(proposal B), not the metadata. Route 2 is the honest one: it is our
signed audit stream landing in their viewer.

**(b) LangSmith → epito: hosted agents consuming per-agent, short-lived
credentials instead of pasted keys.** Three doors, all reachable without
LangChain's cooperation, none frictionless:

| Door | Mechanism | Works without LangChain | Friction |
|---|---|---|---|
| **D1: `@epito/langchain` inside the graph** (proposal A, as written) | `EpitoCredentials("historian")` passed where env keys go; calls `epito token` or an epito HTTP endpoint; refreshes on expiry | Yes, on any runtime: OSS LangGraph, self-hosted, or LangSmith Deployment | A hosted deployment cannot reach a local epitod. Needs a network path: a tunnel, or a hosted token endpoint. This is the tension the architecture seat must rule on. |
| **D2: custom-auth handler** | `@auth.authenticate` calls epito at request time, returns `{"identity": "historian", "github_token": <1h installation token>}` into `langgraph_auth_user`; nodes read it from config | Yes, all LangSmith plans | Fires per inbound request; cron runs' auth context is undocumented, so the autonomous case (our whole premise) is unproven here. Same network-path issue as D1. |
| **D3: register epito as an OAuth provider** in Agent Auth (beta) or an MDA Connection (`--authorize-url`/`--token-url`) | epito exposes a standard OAuth 2.0 authorize/token pair that issues short-lived per-agent tokens; LangSmith's vault holds the grant | Yes; the provider slots are explicitly generic | Their vault stores and refreshes the grant, which reintroduces a middleman (§6 G1); Agent Auth scopes by `user_id` first and `assistant_id` second, so the agent is still a delegate of a human in their model. Beta surfaces; may move. |

Practical reading: D1 is the product; D2 is a documentation recipe on
top of D1; D3 is a hypothesis worth one afternoon once B's OAuth-ish key
handling exists, not a build.

**Does LangSmith already have an agent-identity notion that overlaps?**
Yes, and it is the important finding of this run. In six months
LangChain shipped Fleet identity (March), Agent Auth (beta),
per-caller identity in MDA (August), and Connections (September 9).
All four are answers to the same question we answer, inside their
walls, and all four resolve to one of two owner-credential modes: a
shared stored key ("every action showing up under a service account,"
their own description of the old state) or the invoking human's OAuth
(so the action is the human's, not the agent's). None issues the agent
its own principal on the platform where it acts; none is portable
outside LangSmith; the Connections post itself frames identity as "the
basis for scoped memory and future credential patterns," which is a
roadmap sentence. Independent confirmation of the gap: a
cross-framework study (arXiv:2606.28679, cited via a [dev.to
post](https://dev.to/roxdavirox/agent-identity-spoofing-in-multi-agent-systems-your-orchestrator-has-no-idea-who-it-is-talking-to-1l3j);
secondary, not read directly this run) reports that across LangChain,
LangGraph, LlamaIndex, and Stripe's toolkit "shared credentials are the
norm; per-agent identity is not." Under ADR-10 this is the right shape
of neighbor: they build the driver and the car interior; we mint the
license plate that works on every road. Under ADR-6 it is also the
risk: they are visibly building toward credentials-as-a-feature, and
the day they add "agent-owned OAuth as a bot user" for GitHub and
Slack, the LangSmith-hosted slice of our market closes from inside.

### 8.3 Distribution: the listing, the reach, the buyer

**The listing path is open and cheap.** New integrations are not
accepted as PRs to LangChain repos; they ship as independent PyPI
packages (`langchain-epito`) implementing `langchain-core`
interfaces and passing the standard test suite. Under 50,000 monthly
downloads, a listing issue gets an automated YAML row in the
integrations table linking to our docs; at 50,000+ downloads or by
maintainer feature, a hosted guide page ([contributing integrations](https://docs.langchain.com/oss/python/contributing/integrations-langchain);
[integrations overview](https://docs.langchain.com/oss/python/integrations/providers/overview)).
Tools and toolkits are an explicitly encouraged category. There is no
LangSmith plugin directory or marketplace to list on; the only
storefront is the OSS integrations table. Law 2 and law 4 are
satisfied: nothing gates the package working, only the guide tier.

**The reach is the largest in the maker track.** LangChain reports
100M+ monthly downloads and 139k+ GitHub stars (June 2026, via
[gitnux](https://gitnux.org/langchain-statistics/), secondary);
LangGraph at roughly 38.8M monthly PyPI downloads, "the most installed
agent framework by a wide margin" ([dev.to comparison](https://dev.to/jamilxt/langgraph-vs-crewai-vs-openai-agents-sdk-picking-your-agent-framework-in-2026-2heo),
secondary; [pypistats](https://pypistats.org/packages/langgraph) is the
primary counter). Company: $125M Series B led by IVP at $1.25B
(2025-10), ~$16M ARR for 2025 ([Sacra](https://sacra.com/c/langchain/);
[getlatka](https://getlatka.com/companies/langchain), secondary),
production users named as Uber, LinkedIn, Klarna, JPMorgan
([LangChain 1.0 post](https://www.langchain.com/blog/langchain-langgraph-1dot0)).

**The buyer splits in two, and only one is ours.** The OSS LangGraph
developer runs locally or self-hosts and pays LangChain nothing; that
is our vibecoder, and `langchain-epito` reaches them for free. The
LangSmith Deployment / Fleet / MDA customer pays $39 per seat per
month on Plus, needs Plus to deploy at all, and meters LCUs at $1.50
([pricing breakdowns](https://inference.net/content/langsmith-pricing/);
[truefoundry](https://www.truefoundry.com/blog/langgraph-pricing);
LCU pricing effective for new usage 2026-07-15, existing orgs
2026-10-01 per the [Fleet essentials](https://docs.langchain.com/langsmith/fleet/essentials)).
That buyer is a team with a platform budget, whose credential story is
now sold to them by LangChain itself. We reach them only through the
recipe (D2) and only if they want the agent to be a someone rather than
a proxy for a human. Demand for that specific thing inside the
LangChain community was not evidenced this run: no forum thread or
issue asking for a bot identity per agent surfaced in a first-pass
search (flagged, one search only; the hoop.dev "service account
sprawl for LangGraph" content marketing is a vendor's framing, not a
user's complaint).

### 8.4 Verdict

**Tier: build-next, confirmed and reshaped.** One sentence why: the
package is cheap, the trace convention is nearly free, and the reach
is the largest of any maker, but LangChain is building its own
credential layer in its hosted runtime, so the value concentrates on
the OSS LangGraph developer, not the LangSmith customer.

Reshaped, in three parts the owner can accept or reject separately:

1. **`langchain-epito` (proposal A, door D1): build-next, unchanged
   position behind Slack.** One package over `langchain-core`, no
   dependency on LangSmith, works on OSS LangGraph anywhere. Listed via
   the YAML row the week it is on PyPI.
2. **The trace-metadata convention (8.2a): fold into the same package
   and into epitod's audit emitter as an optional OTLP sink.** Roughly
   fifty lines each; it gives every LangSmith user a "which agent"
   filter that LangSmith does not have, and it costs no dependency.
3. **LangSmith Deployment coupling (doors D2, D3): watch, and write the
   D2 recipe as a docs page only after D1 ships.** Do not build a
   product surface on their custom-auth or Connections hooks; both are
   surfaces LangChain owns and is actively iterating.

**Plain-words recommendation:** yes to LangGraph, no to LangSmith as a
platform bet. Ship the credential object and the trace tag for people
who write LangGraph code; write a recipe for people who host on
LangSmith; do not build anything that only works if LangSmith keeps a
hook open. Accept/reject: **langchain-epito yes/no; OTLP sink yes/no;
LangSmith recipe yes/no.**

**The honest tensions, ranked.**

1. **LangChain sells the hosted runtime and is now selling credentials
   with it.** Fleet identity, Agent Auth, MDA identity, and Connections
   arrived in six months; the last one eleven days ago. On their cloud
   we would be a provider plugged into their vault, which is G1's
   middleman reintroduced. ADR-6 holds only if the product is the OSS
   package and the hosted couplings are recipes; the moment a feature
   depends on `@auth.authenticate` or `--token-url` staying open, it is
   a dependency, and they can close it in a release.
2. **Local-first runtime versus their cloud.** epitod lives on the
   user's machine; a LangSmith deployment is on theirs. Every door in
   8.2b needs a network path from their container to our token
   issuer. Either we accept a hosted token endpoint (an architecture
   decision not yet made) or the hosted case is out of scope and the
   coupling is OSS-only. This document does not decide it; it flags it
   for the architecture seat.
3. **Our differentiator on LangSmith is narrow.** Their "Assistants"
   mode already gives per-human attribution with a real audit trail.
   What we add is the agent-as-itself (a `[bot]` on GitHub, a bot user
   on Slack, one passport across both). Teams that want the agent to be
   a proxy for a person do not need us there; teams that want the agent
   to be a someone do. Which is more common among LangSmith payers is
   unmeasured.
4. **The trace convention is unsigned.** Metadata proves nothing;
   anyone can write it. The value is real only when route 2 (our own
   signed audit stream over OTLP) or proposal B backs it. Selling the
   convention alone would be selling a label.

*Charter compliance note (§8): research only; nothing posted, no one
contacted, no LangSmith account created, no package published. Flagged
secondary or unverified: download and star counts (gitnux, dev.to),
ARR (getlatka/Sacra), the arXiv:2606.28679 finding (via dev.to, whose
own date predates the paper id, so the post was likely updated; not
read directly), cron-run auth context on LangSmith Deployment
(undocumented, treated as unproven), and the LangChain-community demand
signal for bot identity per agent (one search, none found). Evals and
annotation queues were confirmed present and not researched further.*

---
---

# REV 1 (2026-09-18) — superseded by rev 2 above, kept verbatim

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
