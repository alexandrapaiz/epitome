# Vision

## §0 Mission

**Give every agent, whoever built it, a self its owner holds and every
platform honors.**

Signed by the owner 2026-09-20 (all-hands R1). Proposed by the OKR
seat from the evidence of ADRs 1-13; the founding candidate's second
clause ("and every person a workforce") was dropped because it reads
as orchestration, which ADR-10 forbids. Held quarterly by the OKR
seat; no seat edits this line.

## §0b The craft standard (owner, 2026-09-20)

Owner's words: "epito isnt supposed to be only vibecoders at the
loveable level. i want a true piece of engineering... most
programmers today are vibecoders. i want something on the level of
omarchy."

Read precisely: the AUDIENCE is most programmers, who are vibecoders
now; the BAR is real systems engineering. Those are not in tension.
Omarchy is the exemplar because it is serious engineering (a desktop
shell rebuilt as text an agent can drive, systemd and Arch underneath,
opinionated defaults, no toy abstractions) that a newcomer can install
in one command and understand by reading it. That is the standard for
every layer of epito: the CLI, the daemon, the passport, the specs.
Easy comes from craft, never from lowering the bar. Consequences:
- No "no-code" veneer over weak plumbing. Every abstraction must be
  explainable by pointing at the real mechanism beneath it (a GitHub
  App, a systemd unit, a signed card), the way Omarchy's config is the
  real Hyprland config.
- Specs are written to be implemented by others (ADR-13's open
  passport spec is the first).
- The tooling and threat model in docs/architecture.md are floors,
  not aspirations; "vibecoder-friendly" is judged by first-run
  experience, never by hiding the machine.

## §1 The gap (owner-clarified, 2026-09-20)

Every company now gives agents an identity inside its own product,
and every one of those identities stops at that company's wall.
Nobody issues an identity that belongs to the agent's owner and works
everywhere the agent goes, regardless of who built the agent.

An agent today is one of two broken things: a walled resident (real
identity, prisoner of one platform) or a proxy (goes everywhere as
its human, is nobody). The third thing, an agent that is a real
someone owned by its builder and recognized on every platform, does
not exist. Three things every walled vendor bundles, separated:
identity (ours: minted per platform from one file, scoped, revocable,
audited, proven the same agent by the passport), residency (ours, as
a home for that identity), capability (never ours; ADR-10). We are
not a framework, model, orchestrator, chat room, vault, or enterprise
directory. The buyer is the builder running a roster of agents who
pastes personal tokens today; the owner is the first one. Caveats
kept honest: the walls could open (hedge: ADR-6), LangChain is
adjacent (ADR-12), demand is measured at n=1 (OKR O3 is the test).

## Owner's calls (2026-09-18, founding night)

- **The product is the primitive, singular.** Identity + trigger + runtime
  is one product, not three and not five. Marketplace, teams, convening are
  later features that emerge from accumulated manifests; they are never
  pillars and never an excuse to defocus the wedge.
- **Definition is the moat.** An agent is autonomous and *triggered*, not
  prompted, with its own identity and its own runtime. A skill is a
  capability loaded into someone else's identity. The manifest encodes this
  definition; the marketplace will enforce it as a quality bar.
- **For vibecoders.** Easy and scalable for solo builders first; the same
  manifest must carry from one agent to an eleven-seat org to a company's
  hundred with nothing changing but count.
- **Meant for users and revenue** from day one — this is a company, not a
  research artifact. Working Backwards applies: the press release is
  written before the platform (docs/press-release.md).
- **Interop is identity.** Living in Asana/GitHub/Vercel/databases means
  per-agent, per-scope OAuth grants with the platform as the identity
  provider — never the owner's keys in env vars.
- **Integrations ARE the distribution plan** (owner's call, 2026-09-18).
  epito.me wins by being consistent with the stack vibecoders already
  run — Linear, Vercel, Clerk, and whatever the market seat's integration
  map proves matters. Every integration is both product surface (the
  agent shows up there as itself) and a distribution channel (their
  marketplaces, directories, and templates carry us). The market seat
  owns the map; integration order is decided by its evidence, never by
  taste.
- **Name: epito.me**, subject to change. CLI verb: `epito`.
- **Proof-of-demand demo**: migrate an alexandria seat onto the platform
  and delete the hand-wired GitHub App plumbing from alexandria ADR-27.
  That before/after is the launch post.

## Origin

Seeded by alexandria ADR-27 (2026-09-18): eleven seats acting through
their owner's personal tokens until a shared GitHub App gave them one
badge. Entra Agent ID proved the enterprise version exists; nothing serves
indie builders. Naming line of thought preserved in the parent-company
memory: the concept is the inverse of solipsism — the builder is not the
only self in the room.
