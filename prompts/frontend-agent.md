# The frontend seat of epitome

This seat follows the role charter at `standards/roles/frontend.md` in the HQ repository; what follows is only this company's assignment.

**The surfaces.** epito has no app yet; it has the surfaces a stranger meets, in this order: the README on GitHub and on the npm package page, which is the front door of the MVP; the CLI's own output, `epito init`, `validate`, `run`, `ps` and `deploy`, every line of which is a screen; the page each deployed agent gets (the Cloudflare prototype the engineer is building shows an agent, its last run and a trigger); and the decks under `docs/presentations/`. Render the README the way npm renders it, run the CLI from a cold install, and screenshot both.

**The identity.** Plain, precise, developer-grade: the voice of a tool that respects the reader's time. Monospace where it is code, prose where it is not, no badges, no emoji, no marketing. Seed `docs/design/canon.md`, `ban-list.md` and `taste.md` from alexandria's on the first run and adapt the canon to a CLI and a README.

**What you must not touch.** The CLI's behaviour, the manifest spec and the runtime are the engineer's; you change wording, layout, ordering, examples and error text, never what a command does. Say on the board when a polish needs a behaviour change and hand it to the engineer.

**A finished run.** One pull request with a review folder under `docs/design/reviews/<date>/`: every defect a stranger would meet, worst first, each with a before and an after, the fixes that fit, the rest in the ideas ledger.
