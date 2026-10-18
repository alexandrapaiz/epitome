# Pitch: the stranger MVP — `init`, `validate`, `deploy`, `run` from `npm i -g epito`, README only

Shaped 2026-10-16 by the PM seat, on the owner's direct override of the
cycle-2 betting table (relayed by the chair, verbatim: "we need our
product to work, we need an MVP").

## Problem

Every leg of the primitive already exists on `main` and is tested
green: `epito init` scaffolds a manifest, `epito validate` checks it,
`epito deploy` mints the agent its own GitHub App through GitHub's
app-manifest flow (ADR-20), `epito token` mints its short-lived
installation token, and `epito run` puts it on the Temporal engine
(ADR-24, the durable-execution rebuild recorded in the cycle-1 retro).
The CLI's own publish-readiness suite (`cli/test/pack.sh`) passes 104
of 104 assertions today, proving the packaged tarball installs clean
and every manifest command works with no engine present.

None of that is reachable by a stranger. `npm view epito version`
returns `404` — the package has never been published. Nobody outside
this repository can run `npm i -g epito`, so nobody outside it can
read the README and follow it. The product exists; the door to it does
not. That is the whole gap this pitch closes, which is why it is cheap:
it is not new engineering, it is removing the two things that are not
this seat's or the engineer's to remove.

Evidence, checked this run: `npm view epito` — not in the registry.
`docs/ideas.md`'s own open card ("Nobody can publish `epito`") has
said since landing #33 that this is owner-only: an npm account for the
name, and `NPM_TOKEN`. `docs/mvp/2026-10-05-status.md` separately
named the other owner-only step: a real GitHub App has never been
created end-to-end outside a dry run, because that step is a one-click
browser approval the chair declined to do without the owner present.

## Appetite

Small batch: 3 engineer runs. This is explicitly not a new build — if
any scope below wants more than that, it is cut and named, never
extended into a second bet for the same gap.

## Rough solution (breadboard)

1. **Publish.** `npm publish` from `cli/`, once `NPM_TOKEN` exists
   (Infisical, synced to the Actions secret the publish step reads).
   Whether that step is a hand-run command from the owner's machine or
   a tag-triggered workflow is the open question `docs/ideas.md`
   already named; this pitch does not reopen it, it just needs the
   token to exist so either path is possible. The moment this lands,
   `epito init`, `epito validate`, `epito deploy --dry-run` and
   `epito run --dry-run` are true for a stranger, not just for a
   checkout of this repository — the pack suite already proves the
   tarball behaves identically to the working tree.
2. **One real deploy, end to end.** The owner (or the chair, on her
   machine) runs `epito deploy` for one of HQ's own seats against a
   real GitHub account, clicks "Create GitHub App" once in the
   browser GitHub opens, and lets the installation complete. This is
   the one step no API can do by design (GitHub requires a human
   click to create an App) and the one step the mechanism has not yet
   been proven against outside a dry run or a mocked smoke test.
   Done when: one real App exists, owned by an agent and not a
   person, and `epito token` mints from it.
3. **README is the only guide, verified as one.** A fresh read-through
   of `cli/README.md` with nothing else available (no issue tracker,
   no Slack, no this repository's other docs) walking `init` →
   `validate` → `deploy` → `run` end to end, on a machine that has
   never seen this repo, noting every point a stranger would stall
   (a missing `temporal server start-dev` pointer, an assumed `git
   origin`, an unexplained `.epito/` directory). Fixes are README
   edits, not code, unless the walk-through finds a real defect.
4. **A regression gate for the claim itself.** `pack-check` already
   proves the tarball installs and the manifest commands work with no
   engine; nothing today proves the *stranger path* end to end on a
   schedule, so the claim this pitch makes can go stale silently the
   way the plan files did in cycle 1. One CI job that packs, installs
   into a throwaway prefix, and runs `init` → `validate` → `deploy
   --dry-run` with no repository checkout present, failing loudly if
   any of the four ever regresses to "requires this repo."

## What needs the owner's hand, named once

Exactly two things, both genuinely hers alone (§18 line 3: ask only
for what only she can do):

- **`NPM_TOKEN`** — an npm account claims the name `epito` and the
  token goes in Infisical under that name. Nothing else in the
  pipeline is blocked on anything else.
- **One GitHub App approval, in her browser, once** — not because a
  stranger needs her to do this (a stranger clicks through their own
  App, on their own account, for their own agent — that leg has no
  owner dependency at all), but because the end-to-end mechanism has
  never been proven against a live GitHub account, only against dry
  runs and a mocked smoke test, and the MVP claim "works end to end"
  should rest on one real proof, not zero.

Everything else in this pitch — the publish plumbing, the README
walk-through, the regression gate — proceeds without her and does not
wait on either item landing first, per section 22: work that does not
depend on the decision continues while it's pending.

## Rabbit holes

- Do not build a release-automation workflow as part of this pitch;
  naming the hand-run-vs-tag-triggered question is enough, deciding it
  is a one-line owner call whenever she gives the token.
- Do not re-litigate the app-manifest-vs-shared-App route (ADR-20
  already decided it); this pitch only proves the decided route once
  against a real account.
- Do not expand the README into a tutorial; it stays the reference
  it already is, fixed only where the walk-through actually stalls.

## No-gos

No Slack identity, no passport, no MCP server, no new manifest fields.
This pitch touches publishing and documentation of what already ships,
nothing else.
