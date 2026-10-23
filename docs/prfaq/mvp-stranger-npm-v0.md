# PR/FAQ: epito ships to npm — a stranger mints an agent from one file

Status: proposed, 2026-10-18. Written Working Backwards, before the bet
enters build, per the company PM standard: nothing larger than a sprint
item is planned until its PR/FAQ exists. The owner's merge of this file
is the go decision; the cycle-2 cooldown retro grades the shipped work
against the press release below, not against a task list. Full pitch:
docs/pitches/mvp-stranger-npm-v0.md. Bet placed in the cycle-2 betting
memo (docs/pitches/BETTING-MEMO-cycle-2.md, merged 2026-10-18), on the
owner's own override, relayed by the chair: "we need our product to
work, we need an MVP."

---

## Press release

**epito ships to npm: a stranger mints an agent from one file**

*`npm i -g epito`, then `init`, `validate`, `deploy`, `run` — no owner
in the chain, no code to read first.*

Today epito.me published `epito` to the npm registry. Until now, every
piece of the agent primitive — a manifest, its own GitHub identity, a
schedule, a durable runtime — worked, but only inside this repository.
Nobody outside it could install the CLI, because the package had never
been published. The product existed; the door to it did not.

A stranger who has never seen this repository now runs four commands
against one file, `agent.toml`, and ends with an agent that is a real
principal rather than an impostor: `epito init` scaffolds the manifest,
`epito validate` checks it before anything is created, `epito deploy`
walks GitHub's own app-manifest flow to mint the agent a GitHub App of
its own (one browser click, on the stranger's own account, for their
own agent), and `epito run` puts it on a self-hosted, durable runtime
that survives a reboot mid-run. The README is the only guide; there is
no issue tracker, no Slack channel, no second document to find first.

"We need our product to work, we need an MVP," the owner said, cutting
two other candidate bets to make this one the whole of a cycle's small
batch. The four commands already worked inside the repository before
today; this release is the two things that were not engineering —
putting the package where a stranger can reach it, and proving the
deploy flow once against a real GitHub account instead of only a dry
run.

A stranger starts today with:

```bash
npm i -g epito
epito init my-agent
epito validate my-agent
epito deploy my-agent    # opens a browser, one click, their own account
epito run my-agent       # requires `temporal server start-dev` once, locally
```

"I pointed it at a repo I already had, answered four prompts, and ten
minutes later a GitHub App I own was opening pull requests under its
own name — not mine," is the shape of the first real report this
release is written to earn, not yet a quote from an actual stranger,
because there is not one yet. That sentence is the test: if the first
real user cannot say something close to it, the release does not
publish as planned.

Available today at the npm registry, under the name `epito`, at no
cost to install or run.

---

## Customer FAQ

**What does it cost?** Nothing, for the CLI itself — installing and
running `epito` costs nothing. Running an agent costs whatever the
agent's own provider charges (for example, a Claude API key or
subscription the stranger already holds) and whatever compute the
stranger runs it on; epito charges nothing on top. The company has not
yet ruled on a paid tier for anything (team rosters, shared audit,
hosted runtime); nothing in this release depends on that ruling. What
licence it ships under is a separate question from what it costs, and
that one is not yet decided — see the internal FAQ below.

**What does `epito` not do?** It does not host anything for the
stranger. There is no epito.me server in the loop: the GitHub App
lives in the stranger's own GitHub account, the runtime runs on a
machine the stranger controls, and the only epito-owned infrastructure
touched is the npm registry the package is downloaded from. It is not
a no-code tool — `agent.toml` is a real file, `epito validate`'s
errors name the exact line to fix, and the README assumes the reader
can run a shell command.

**Where do my secrets go?** Nowhere outside the stranger's own
machine. `epito deploy` mints the GitHub App's credentials directly
from GitHub into a local file; nothing is sent to epito.me, because
there is no epito.me service to send it to. The manifest's `env` list
names which environment variables a run may read; a name the manifest
does not list is never injected into the agent's run.

**How do I leave?** Delete the GitHub App from GitHub's own settings
page (revokes every credential it minted), stop the local runtime, and
`npm uninstall -g epito`. Nothing about leaving requires contacting
anyone, because nothing about staying required an account with epito
either.

**What do I need before I start?** Node, a GitHub account, and
(for `epito run`, not for `init`/`validate`/`deploy --dry-run`) a
locally running Temporal dev server — one command, documented in the
README, no account or signup.

**Where do I get help if the four commands don't work?** The README is
the only guide this release ships with, on purpose, so it is also the
thing being tested: a fresh read-through on a machine that has never
seen this repository, walking the same four commands, is one of the
items below the fold before this publishes.

---

## Internal FAQ

**What has to be true for this to work?** Three things, none of them
new engineering: the package has to actually be on the npm registry
(checked today, 2026-10-18: `npm view epito` returns 404 — not yet
true); the deploy flow has to be proven once against a real GitHub
account rather than only a dry run and a mocked smoke test (not yet
done — every prior proof, including the chair's walk-through on the
host the night of 2026-10-05, stopped short of the live browser
click); and the README has to survive a read-through by someone who
has never seen this repository (not yet done).

**What is blocked on the owner's hand, and is it actually unblocked?**
Three things, all hers alone:

- **An `NPM_TOKEN`.** The backlog record from the 2026-10-18 00:22 UTC
  pass says the chair created the npm account `alexandrapaiz` and the
  token now lives in Infisical and this repository's Actions secrets,
  capped at seven days, dead 2026-10-24. This run could not
  independently verify that claim: this seat's token cannot list
  repository secrets (`gh secret list` returns a 403), and `npm view
  epito` still returns 404, which is consistent with either "the token
  exists but nobody has run `npm publish` yet" or "the token never
  landed." Whoever runs the publish step should treat the backlog's
  claim as unverified until the registry actually answers with a
  version, not as settled.
- **One real GitHub App approval, in the owner's browser, once**, for
  one of the company's own seats. Still open as of this run, asked
  2026-10-16. Not a blocker for a stranger's own deploy — a stranger
  clicks through their own App on their own account, which has no
  owner dependency at all — but the claim "proven end to end" should
  rest on one real approval, not zero, before this release calls
  itself proven rather than merely built.
- **The licence word.** `cli/package.json` on `main` says `UNLICENSED`
  next to `publishConfig.access: "public"`, and the repository ships
  no LICENSE file. Earlier drafts of this press release and FAQ said
  "free and open source" anyway, which was the document asserting a
  decision nobody had made — fixed in this revision to claim only what
  is true today (no cost), not the licence. npm keeps a first
  release's licence field permanent even after an unpublish, so this
  is the one item on this list that becomes unfixable the moment the
  package publishes, not merely unproven. Asked on the board
  2026-10-18; once she names it, the engineer adds the LICENSE file
  and the matching `package.json` field.

**What breaks if this ships anyway, before all three land?** The four
commands and the README remain true and testable for a stranger even
without the publish or the live approval — `npm pack` plus a local
install already proves the tarball behaves identically to this
working tree. What breaks is the claim: "install it from npm" is false
until the registry has it, "proven end to end" is false until one
real GitHub account has been through the click, and the npm page
reads *Proprietary* until the licence word and file agree with the
package. Shipping the press release before all three are true would
be shipping a release that reads as something that already happened
and has not — the licence word, specifically, cannot be fixed after
the fact.

**What does this cost?** Nothing beyond the npm account itself (free)
and the seven-day clock on the current token, which is a deadline, not
a cost — if it expires unused, a new one is a repeat of the same
owner-only step with no component charge. No new dependency, no new
infrastructure, no shared-services line.

**Why now, rather than cycle 3?** Every leg already works inside this
repository — this is not new build, it is removing the two things
that are not code (an account, a browser click) and proving a claim
that would otherwise go stale silently, the way earlier plan files in
this company already have. The owner's own override named this
explicitly: the product needs to work before it needs a second
identity platform or a cross-platform claim. Both of the pitches this
cycle's bet displaced (a second identity surface, a cross-platform
passport) stay shaped as the first candidates for the cycle after
this one; nothing about them was wrong, they answer a different
question than the one the owner asked first.

**What is deliberately not in this release?** No new identity surface,
no passport, no MCP server, no new manifest field, and no
release-automation workflow — whether the publish step is a hand-run
command or a tag-triggered job is named as an open question in the
pitch, not decided here. This release touches publishing and the
documentation of what already ships; nothing else.
