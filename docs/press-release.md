# Press release (Working Backwards draft — written before the platform)

*Draft v0, 2026-09-18. Rewritten freely until launch; the FAQ below is
the honest ledger of what must be true for this page to publish.*

---

**epito.me launches: give your agents their own identities, triggers, and
runtimes — in one file**

Solo builders run companies of AI agents now. Until today, every one of
those agents was an impostor: it committed as its owner, deployed with its
owner's keys, and died when the chat window closed. epito.me makes an
agent a real principal. You write one `agent.toml` — who the agent is,
what wakes it, where it runs — and `epito deploy` mints the rest: scoped,
revocable credentials that are not yours, short-lived tokens per run, a
container that persists, and an audit log that finally answers *which
agent did that*.

Your agents show up in GitHub, Asana, and Vercel as themselves. Revoking
one touches nothing personal. Scaling from one agent to an eleven-seat
org changes nothing but the number of files.

The first migration is public: alexandria, an eleven-seat agent company,
replaced its hand-wired shared GitHub App with three manifests and
deleted the plumbing.

---

## FAQ (what must be true to publish this)

- **Q: What does `epito deploy` actually provision on day one?**
  A GitHub App–backed principal with fine-grained scopes, per-run token
  minting, cron/webhook triggers, a container, and the audit log. One
  integration (GitHub) done completely beats five done as demos.
- **Q: What does it cost the user?** Free for the first agents (the
  vibecoder on their own subscription), paid per active agent beyond
  that; the paid tier is the roster (teams, shared audit, org controls).
  Pricing is a market-seat question before launch, not a guess at launch.
- **Q: Why not just use Entra Agent ID?** You don't have a tenant, an IT
  department, or an enterprise directory. That's the point.
- **Q: What's deliberately not in v1?** The marketplace, convening, and
  every integration beyond GitHub.
