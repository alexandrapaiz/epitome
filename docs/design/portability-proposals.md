# Portability proposals — making agents portable across makers

Chair's draft, 2026-09-19, on the owner's direction: "every company is
building their own agents, but the portability is the problem... we
need to figure out how we can make something portable for a Slack
agent or N8N or OpenClaw... we need to figure out how to make
integrations because that's our biggest distribution edge... I've
heard a lot about Langraph... I want to see what proposals there are."
Grounded in docs/market.md §5-§7 and ADR-6/8/9. Each proposal ends
with a done-when; the owner accepts or rejects per proposal.

## The problem, decomposed

An agent is a brain (model + prompt), tools, credentials, a home
(runtime), and a history (audit). Portability fails at credentials
and home: every maker either stores the OWNER's long-lived keys
(OpenClaw's per-agent OAuth refresh tokens, LangGraph's env keys,
n8n's credential store) or mints an identity that works only inside
its wall (Slack apps, Entra, AgentCore). Nothing proves two platform
identities are the same agent. epito's portable spine is the
manifest + per-platform principals + one audit trail; these proposals
are the concrete couplings to other makers.

## Proposal A — the universal credential slot (`epito token`)

Every framework has one narrow opening: where it reads a credential.
We replace the pasted owner key with a runtime call that returns a
short-lived, per-agent, per-scope token.

The primitive (exists after cycle-1 bet 1):

```
$ epito token historian --scope github:contents
ghs_xx短lived...        # ~1h installation token, never written to disk
```

Per-framework couplings:

- **LangGraph / LangChain**: `@epito/langchain` exporting
  `EpitoCredentials(agent: string)` — a credential provider object
  passed into tool constructors where env keys go today. Internally
  it shells to `epito token` (or calls @epito/core directly) and
  refreshes on expiry. Effort: one thin package over shipped code.
- **n8n**: a community credential node ("epito identity") using n8n's
  dynamic-credential resolution, so each workflow-agent resolves its
  own principal's token at execution instead of a stored owner key.
  n8n is self-hosted and credential-driven by design (market §6 G2),
  which makes it culturally our closest neighbor.
- **OpenClaw**: their 2026.4+ external vault mount and MCP connector
  points (market §7) — epitod exposes a vault-compatible socket; an
  OpenClaw agent's outbound credentials resolve to per-agent tokens.
  Reachable without their approval; positioned as "your OpenClaw
  agents, given real identities."

Distribution: each coupling lands in an existing community (LangChain
integrations directory, n8n community nodes, OpenClaw's ~176k Discord
— counts per market §7, flagged secondary).

**Done when:** a LangGraph tool call and an n8n workflow step each
execute against GitHub as `<name>[bot]` with a token minted at run
time, demonstrated in a fresh clone with transcripts.

## Proposal B — the agent passport (identity binding, the invention)

Every epito agent serves a public card at
`/.well-known/agent-card.json` (the A2A standard, Linux Foundation,
production across ~150 orgs per market §5), extended with **identity
binding proofs**: the card lists the agent's platform identities and
is signed with the agent's own key, and each platform principal
carries a verifiable link back.

Example payload (illustrative shape, not final):

```json
{
  "name": "historian",
  "manifest": "https://.../agent.toml",
  "identities": [
    {"platform": "github", "id": "historian-epito[bot]",
     "proof": "https://github.com/.../signed-commit"},
    {"platform": "slack", "id": "B0HISTORIAN",
     "proof": "profile-field:epito-passport"}
  ],
  "jwks": {"keys": ["..."]},
  "audit": "self-attested, append-only, locally held"
}
```

Verification answers the question no walled vendor can: "is this
Slack bot the same agent as this GitHub bot?" This operationalizes
the market gap (the deck's slide 2) as a checkable mechanism, and
makes epito agents discoverable by Microsoft Agent Framework, Google
ADK, Copilot Studio, and Bedrock AgentCore without adopting any of
their runtimes (market §7).

**Done when:** a third party, given only the card URL, can
cryptographically confirm two platform identities belong to one agent
— shown end to end for one agent on GitHub + Slack.
Track as manifest v0.2 material; the key handling rides the existing
per-agent PEM.

## Proposal C — the adapter runtime (bring-your-agent)

`epito run --adapter openclaw|langgraph <their-config>`: the agent
stays authored in the maker's framework; epitod wraps it in our
container, identity, schedule, and audit — the car, literally.
Depends on phase-2 epitod; the adapter surface is per-framework work
(LangGraph: execute the graph inside our container with Proposal A
credentials injected; OpenClaw: run their agent process with vault →
epitod). Deliberately last: A must prove the demand first.

**Done when:** an unmodified agent definition from one foreign
framework runs on epitod with its own identity and appears in
`epito ps`.

## Proposal D — one voice across chat (the messaging family, ADR-9)

One MessagingProvider abstraction (post, read, thread; scope grammar
`msg:write`-style generalizing across backends) with Slack as the
first backend and Discord/WhatsApp/WeChat as siblings pending the
decision-2 research run. An agent's chat presence then moves across
platforms without rewriting the agent.

**Done when:** the same manifest, with only the backend name changed,
posts as itself on two different chat platforms.

## Recommendation (accept/reject per line)

1. **A ships alongside the Slack work** (cycle-2 pitch material):
   cheapest, rides bet-1 code, three communities of distribution.
2. **B is tracked for manifest v0.2** and prototyped for one agent as
   the standard-setting move; it is the company's distinctive claim.
3. **C waits for phase 2** (epitod), re-bet then.
4. **D ships with the Slack provider** as its abstraction layer, so
   Slack is born as the first of a family, per ADR-9.

Constraint check: every coupling is a surface (ADR-6) — epito works
with none of them installed; the model stays routable beneath every
identity (ADR-8).
