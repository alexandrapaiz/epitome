# Market brief rev 2 — slide-by-slide content

Authored by the market seat (prompts/market-agent.md), 2026-09-19, on
the coordinator's dispatch after the owner rejected the chair's
rendering ("the content you previously shared was great, the
presentations suck... lots of jargon"). Format follows the alexandria
pitch-deck exemplar (alexandria docs/sales/pitch-deck.md): each slide
is "Copy" (the words on the slide, verbatim, don't embellish),
"Speaker notes" (sourcing and internal vocabulary, never on the
slide), and "Visual direction" (a plain-language brief). Every fact
below is sourced to docs/market.md rev 2 (2026-09-19) or the linked
primary; nothing is invented. Where a number carries a confidence
flag in the brief, that flag is carried into the copy.

The deck's job, per the owner: guide her and the PM on where to
direct the project. It ends in four decisions she can answer yes or
no, one slide each.

**For the chair rendering this:** the spine is slide 2. Every slide
either proves it, prices it, or turns it into a decision. Render the
words as written; the technical vocabulary lives in the notes on
purpose.

---

## Slide 1 — What happened this year

**Copy:**
> In 2026, Microsoft, Amazon, Google, Slack, Notion, and Asana each
> gave AI agents their own identity inside their product.

**Speaker notes:** all six are sourced in docs/market.md rev 2 §5:
Microsoft Entra Agent ID / Agent 365 ([Learn](https://learn.microsoft.com/en-us/microsoft-agent-365/developer/third-party-identity-providers)),
AWS Bedrock AgentCore workload identity ([docs](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/identity-overview.html)),
Google's per-agent SPIFFE IDs in Gemini Enterprise ([Infosecurity](https://www.infosecurity-magazine.com/news/google-ai-agent-identities-gemini/)),
Slack bot users, Notion Custom Agents (1M+ built since 2026-02-24,
[release notes](https://www.notion.com/releases/2026-02-24)), Asana AI
Teammates ([investor release, June 2026](https://investors.asana.com/news-releases/news-release-details/asana-unveils-operating-system-human-agent-teams)).
All accessed 2026-09-19. This slide only establishes that the giants
agree agents need identities. The turn comes next.

**Visual direction:** the six company names in a row, each with the
one thing it shipped and the year. Quiet, factual, no logos fighting
each other.

---

## Slide 2 — The gap (the spine of this deck)

**Copy:**
> Every one of those identities stops at that company's wall.
>
> Nobody issues an identity that belongs to the user and follows the
> agent everywhere it works.

**Speaker notes:** this is the priority finding of docs/market.md
rev 2, marked there as "the sentence this company is a bet on" (§6,
gap G4). Internally we call it the portable, user-owned principal;
never say that phrase in the room. Microsoft's identity governs the
Microsoft estate, Amazon's lives in AWS, Google's on its cloud,
Slack's in Slack, and so on. The nearest enterprise product, Agent
365, is $15 per human user per month inside the Microsoft world (rev
1 §1, sourced). The version for an individual builder does not exist.
If the room remembers one slide, it is this one.

**Visual direction:** the two sentences alone, large, heavy
whitespace. This is the deck's title treatment even though it is
slide 2.

---

## Slide 3 — What epito.me is, in one line

**Copy:**
> One file describes the agent. One command gives it a real identity,
> a schedule, and a home on your own machine. The identity is yours
> to limit and yours to cancel.

**Speaker notes:** this is ADR-1 and ADR-2 (docs/decisions.md) in
plain words: the manifest (`agent.toml`) mints identity + trigger +
runtime. "Yours to limit and yours to cancel" translates scoped and
revocable. "On your own machine" is the phase-2 daemon
(docs/architecture.md, `epitod`): a persistent container per agent,
woken on a schedule or an event, no human session needed. Do not say
manifest, principal, container, or cron on the slide.

**Visual direction:** three short phrases stacked (a file, a command,
an identity you control), or one line of text beside a small
file-to-badge illustration. No architecture diagram here.

---

## Slide 4 — Today's alternative is a middleman with a master key

**Copy:**
> The biggest automation hub connects agents to 9,000+ apps through
> "one set of managed credentials" held in its own vault. One key,
> one middleman, everything behind it.
>
> And in the open ecosystem, only 8.5% of agent tool servers use
> standard sign-in at all, by one security firm's measurement (2026).

**Speaker notes:** the quote is Zapier's own marketing for Zapier MCP
([zapier.com](https://zapier.com/blog/best-ai-agents/), accessed
2026-09-19), sourced in docs/market.md rev 2 §5 (skip tier) and §6
G1. The 8.5% figure is Astrix Security research via a secondary
source ([explainx guide](https://www.explainx.ai/blog/mcp-security-guide-2026)),
which is why the copy says "by one security firm's measurement"
rather than stating it flat. Supporting color if asked: Cloudflare
shipped optional permission scopes in September 2026 specifically
because agents "request the union of everything they might do"
([InfoQ](https://www.infoq.com/news/2026/09/cloudflare-optional-oauth-scopes/)).
Our answer: no vault in the middle; each agent carries its own
limited, cancelable identity on each platform.

**Visual direction:** left side, many apps funneling into one key
icon (the middleman). Right side, one agent holding its own small
key per app. Label them "their model" and "ours."

---

## Slide 5 — People want live-in agents so badly they run dangerous ones

**Copy:**
> OpenClaw, an open-source agent that lives on your computer, passed
> 135,000 GitHub stars within weeks of launch (2026).
>
> Then: 42,000 copies found exposed on the public internet, passwords
> stored in plain text, and roughly 1 in 8 add-ons in its store
> confirmed malicious.

**Speaker notes:** docs/market.md rev 2 §6 G2. Stars: [DEV writeup](https://dev.to/waxell/the-openclaw-security-crisis-135000-exposed-ai-agents-and-the-runtime-governance-gap-e26).
Exposure and auth flaws: [Sliq incident timeline](https://getsliq.com/blog/openclaw-security-incidents-timeline).
Plaintext credentials: [Sangfor](https://www.sangfor.com/blog/tech/openclaw-ai-agent-2026-explained).
Malicious add-ons: 341 of 2,857 in ClawHub, about 12%
([DEV](https://dev.to/tiamatenity/openclaw-how-a-popular-ai-agent-platform-became-a-security-catastrophe-1mg2)).
All accessed 2026-09-19. The reading for the room: the demand for a
resident agent is proven at internet scale, and so is the failure of
the do-it-yourself version. Our phase 2 is exactly the three fixes
OpenClaw lacked: each agent walled off in its own container, secrets
out of plain text, and an identity that is not the owner's. Honest
caveats we say if asked, not on the slide: we do not solve prompt
injection, a bad add-on the user installs anyway, or an unpatched
computer.

**Visual direction:** two big numbers side by side, 135,000 and
42,000, with the "1 in 8" beneath. Let the numbers be the picture.

---

## Slide 6 — The clock is running and the money has noticed

**Copy:**
> Since August 2, 2026, EU law requires companies running high-risk
> AI to prove, with tamper-evident logs, what their agents did.
>
> In 2026 investors put over $300M into startups whose only product
> is tracking and securing agent identities ($120M, $66M, $60M, $50M
> rounds among them).
>
> An agent with its own identity produces that proof automatically.
> An agent using its owner's account never can.

**Speaker notes:** docs/market.md rev 2 §6 G3. EU AI Act Article 12
enforcement date: [AI2sql analysis](https://ai2sql.io/ai-blog/eu-ai-act-agent-audit-trails-database)
and a [practitioner writeup](https://dev.to/igorganapolsky/your-compliance-team-will-ask-for-an-ai-agent-audit-trail-before-august-2-heres-the-part-most-h2n).
Rounds: Oasis Security $120M, NewCore $66M ([SiliconANGLE](https://siliconangle.com/2026/06/15/newcore-launches-security-first-identities-ai-agents-closing-66m-seed-funding-round/)),
Oak $60M ([TechCrunch](https://techcrunch.com/2026/07/15/backed-by-60m-in-funding-oak-steps-out-of-stealth-to-fix-the-identity-mess-that-ai-agents-are-making-worse/)),
GitGuardian $50M ([SiliconANGLE](https://siliconangle.com/2026/02/11/gitguardian-raises-50m-expand-non-human-identity-ai-agent-security/)),
over $392M around one security conference alone ([Software Strategies](https://softwarestrategiesblog.com/2026/03/28/agentic-ai-security-startups-funding-mna-rsac-2026/)).
The third line is the mechanism: when the agent is a distinct someone
on each platform, every commit and message lands under its name, and
our local log records every action, append-only. Boundary we state
if pushed: we are the substrate that makes agents auditable, not a
compliance-dashboard company; competing there is one of the refusals
on slide 9.

**Visual direction:** a date (Aug 2, 2026) and a money figure
($300M+) as the two anchors, third line as the takeaway beneath.

---

## Slide 7 — Decision 1: build the team-chat surface next (yes / no)

**Copy:**
> GitHub proved the agent can work. Slack is where you watch it work:
> your agent posting its morning report under its own name and face.
>
> Creating that identity is open to anyone today, needs no approval
> from Slack, and reuses the pattern we already shipped for GitHub.
>
> The honest catch: Slack belongs to Salesforce, which sells its own
> agents. We would be demoing in a competitor's living room. We build
> there anyway because the product must never depend on any single
> platform, this one included.

**Speaker notes:** this is the standing recommendation of
docs/market.md rev 2 (integration #2 = Slack; Linear was rejected by
the owner in ADR-6, and this pick was re-justified from scratch under
that ADR's principle). "Open to anyone, no approval" = programmatic
app creation via `apps.manifest.create` plus standard per-workspace
install; "reuses the pattern" = the same manifest-mint flow as our
GitHub provider. Distribution through the Slack Marketplace is
optional and later; it never gates the feature working. Runner-ups if
she says no: Vercel (biggest storefront, but our agent can't appear
there as itself and listing needs their approval) and Notion (real
identity, but Notion now bundles its own resident agents). The
Salesforce tension is stated on the slide deliberately; source for
Slack-as-orchestrator positioning: [Slackbot GA, 2026-01-13](https://www.salesforce.com/news/press-releases/2026/01/13/slackbot-announcement/).

**Visual direction:** a mock chat message from an agent with its own
avatar and name, timestamped early morning. One small "yes / no"
marker in the corner, as on the next three slides.

---

## Slide 8 — Decision 2: what we research next (yes / no)

**Copy:**
> Five places we have not yet checked for the same question, does an
> agent get to be someone there, and on what terms:
>
> WhatsApp. WeChat. Discord. OpenAI's agent platform. Amazon's agent
> marketplace.
>
> One research run, next week, no build commitment.

**Speaker notes:** Discord, OpenAI's platform surfaces, and the AWS
marketplace category are flagged in docs/market.md rev 2 §5 as "not
researched this run, absence of research not a verdict." WhatsApp and
WeChat were added by the coordinator's dispatch and we make no claim
about either yet; that is the point of the slide. The question each
gets is the same three-part test from the brief's closing section:
can the identity be created without anyone's permission, does the
agent appear as itself, does the product survive if the platform
vanishes.

**Visual direction:** five names as plain cards, each with a question
mark, nothing else. The restraint is the message.

---

## Slide 9 — Decision 3: three markets we recommend refusing (yes / no each)

**Copy:**
> Enterprise agent app-stores. Every shelf (Microsoft, Google,
> Salesforce) requires partner programs and verified-business bars we
> fail today, to reach buyers with year-long purchasing cycles.
>
> Agent payments. The loudest protocol race of the year, but one
> payment mistake would be fatal to a young identity product. Agents
> read financial data; they do not move money. Not before 2028.
>
> Selling "digital employees" to big companies. Gartner projects over
> 40% of those projects canceled by end of 2027 and estimates only
> about 130 of the thousands of vendors are real. Our buyer stays the
> individual builder running a roster of agents.

**Speaker notes:** the three traps of docs/market.md rev 2 §6 (T1,
T2, T3), in plain words. Gartner: [press release, 2025-06-25](https://www.gartner.com/en/newsroom/press-releases/2025-06-25-gartner-predicts-over-40-percent-of-agentic-ai-projects-will-be-canceled-by-end-of-2027).
Payments protocols (ACP, AP2) context: [Orium](https://orium.com/blog/agentic-payments-acp-ap2-x402).
Marketplace bars: Salesforce's own $50M program to help small shops
clear its security review ([SalesforceDevops](https://salesforcedevops.net/index.php/2026/04/14/agentexchange-salesforces-bet-that-trust-can-scale-with-agentic-speed/))
is the confession that the bar is too high for companies our size.
Each refusal is separately reversible by the owner; phrase them as
three independent nos she can veto.

**Visual direction:** three cards, each titled with the refused
market and one reason line. Muted styling; these are things we are
not doing.

---

## Slide 10 — What would change this map, and the close

**Copy:**
> Three tripwires. If any fires, this deck gets rewritten:
>
> GitHub opens its agent store to everyone (it is invite-only today,
> promised open "in coming months" since June).
>
> Anthropic or another model vendor starts giving agents their own
> identities on outside platforms (today the agent still acts as its
> owner; checked this week).
>
> Any platform we build on closes its open door for app-making.
>
> Until then: nobody issues an identity that belongs to the user and
> follows the agent everywhere it works. We do.

**Speaker notes:** the re-ranking trigger conditions of docs/market.md
rev 2 §5, plain-worded. GitHub agent-app waitlist status:
[changelog 2026-06-02](https://github.blog/changelog/2026-06-02-extend-github-with-agent-apps/)
and the open [community discussion](https://github.com/orgs/community/discussions/197310),
both re-checked 2026-09-19. Anthropic check, done this run: Managed
Agents still holds the owner's keys in its vault and the Claude Tag
identity model governs permissions, not identity on outside platforms
([Help Net Security, 2026-06-24](https://www.helpnetsecurity.com/2026/06/24/anthropic-claude-tag-agent-identity-model/));
if that changes, the market seat escalates to the owner immediately,
per the brief. The final two lines bookend slide 2 on purpose.

**Visual direction:** three tripwires as small labeled fuses or
flags, then the closing sentence in the slide-2 treatment, large and
alone.

---

## Change log

- 2026-09-19: first version, authored by the market seat on
  coordinator dispatch, replacing the chair's rejected rendering.
  Content substrate only; no HTML rendered, no chart built.
