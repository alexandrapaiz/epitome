# Publishing the CLI to npm

Cycle 2, bet `mvp-stranger-npm-v0`, scope 2-1's last step. Written
2026-10-23 by the engineer seat, on the run that tried the real publish
and was refused.

**The publish is one command and one decision away. The decision is the
owner's and it is not about the token.**

## What happened

Both publish gates were green — `pack.sh` 118 assertions, `stranger.sh`
33, and green *inside* `npm publish --dry-run` too, so the gate leak
#136 fixed stays fixed. The real publish then came back:

```
npm notice Publishing to https://registry.npmjs.org/ with tag latest and public access
npm error code E403
npm error 403 Forbidden - PUT https://registry.npmjs.org/epito -
  Package name too similar to existing packages exit,pino;
  try renaming your package to '@alexandrapaiz/epito' and
  publishing with 'npm publish --access=public' instead
```

That is npm's typosquat filter. It is not a quota, not an outage, and
not the token:

- the token authenticates — `npm whoami` answers `alexandrapaiz`
- the tarball is right — 58 files, 244 KB, README included, no engine
- the name `epito` is unpublished; nobody holds it. npm simply will not
  issue it, because it is two edits from `exit` and from `pino`

**A new token does not fix this.** The filter does not clear with time,
and retrying tomorrow spends the clock on the same refusal. The name
has to change, or move under a scope.

## The token

```
name        epito-publish
created     2026-10-17T19:26:26Z
expires     2026-10-24T19:26:26Z      ← not midnight: 19:26 UTC
permission  package: write, all packages
bypass_2fa  true
stored      Infisical prod, as NPM_TOKEN
            (rendered to /srv/asc/env.infisical on the host, 0600)
```

Nothing the publish needs is missing from the host or from Infisical.
`NPM_TOKEN` is there, by that name, and it works. The one thing missing
is a name npm will accept.

Note that `NPM_TOKEN` is in `/srv/asc/env.infisical` but **not** in
`/srv/asc/env`, the agent-visible file — so a seat reads it from the
Infisical-rendered file for the length of one command and no agent
carries it in its environment.

## Which names npm will accept

Checked with `npm run name-check -- <candidate>`, which asks the
registry and publishes nothing (see "How name-check asks" below). All
ten candidates were still unpublished afterwards.

| Candidate | Verdict |
|---|---|
| `epito` | refused — too similar to `exit`, `pino` |
| `epito.me` | refused — too similar to `epitome` |
| `epito-me` | refused — too similar to `epitome` |
| `epitome` | **taken** — published, maintained by `dimitarchristoff` |
| `epitomecli` | refused — too similar to `epitome-cli` |
| `epitome-cli` | accepted |
| `epito-cli` | accepted |
| `epito-agents` | accepted |
| `epito-mint` | accepted |
| `@alexandrapaiz/epito` | accepted — npm's own suggestion |

Two facts worth saying plainly, because they close doors rather than
open them:

1. **`epito` is gone for good as an unscoped name.** The similarity
   filter compares against `exit` and `pino`, which are not going
   anywhere.
2. **`epitome`, the company's own word, belongs to someone else** on
   npm already. So does every name that collapses onto it once npm
   strips punctuation — `epito.me` and `epito-me` both die on it.

The word `epito` survives in exactly two shapes: under a scope
(`@alexandrapaiz/epito`, or `@<org>/epito` if an npm org is created),
or with a suffix (`epito-cli`).

## The decision, and what it costs

**Decided 2026-10-23 19:01 UTC by the PM: `epito-cli`.** The tree on
this branch already carries it, so the publish below needs no rename —
start at step 2.

The PM took the call under its own authority rather than leaving the
scope under an owner-only tag a second time: a package name is not
money, not an account, not a secret and not a widening of the PM's own
authority, so pm.md §22 does not reserve it for the owner. It could not
have waited the 48-hour silence rule either way — the token dies at
19:26Z on the 24th, which is the shorter clock. **The owner can still
overrule it in one word until this merges**, and that door is
deliberately left open; what follows is the comparison she would be
overruling.

The install line the README, the PR/FAQ and the press release all
promise is `npm i -g epito`. That line cannot exist. Whichever way this
goes, one sentence of the promise changes.

- **`epito-cli`** — `npm i -g epito-cli`. Unscoped, one word, no org to
  create, publishable tonight. The binary is still `epito`, so every
  other line of the README is unchanged: a stranger types `epito init`,
  `epito validate`, `epito deploy`, `epito run` exactly as promised.
  Only the install line moves.
- **`@alexandrapaiz/epito`** — `npm i -g @alexandrapaiz/epito`. Keeps
  the word exactly; npm suggested it. The scope is the owner's personal
  handle, which reads personal rather than company.
- **`@epitome/epito` or `@alexandra-systems/epito`** — the brand under a
  company scope. Costs one browser action first: npm orgs are free for
  public packages, but only the owner can create one. Same shape as the
  deploy click scope 2-2 has been waiting on since 2026-10-16.

The engineer's recommendation was **`epito-cli`**, and it is what the
PM chose: the only option that needs nothing from the owner's browser,
and the command a stranger types twenty times a day is `epito` — the
binary, unchanged — not the install line they type once.

## The publish

The rename is **done and committed**, so step 1 is a check and not a
chore. It was five lines, not the three an earlier pass measured: that
pass applied the rename and reverted it without an `npm install` in
between, so it never saw `package-lock.json`, which carries the name
twice.

```bash
# 1. the name — already applied, verify rather than edit
#    cli/package.json        "name": "epito-cli"
#    cli/package-lock.json   "name", twice: the root and the "" package
#    cli/README.md:6         npm i -g epito-cli
#    cli/README.md:547       ...so `npm i -g epito-cli` does not drag in Temporal's
#    (stranger.sh asserts the README install line names the package, so a
#     half-done rename fails the gate rather than shipping a lie)
cd cli && node -e 'console.log(require("./package.json").name)'   # -> epito-cli

# 2. the preflight — no publish, no side effect
cd cli
NPM_TOKEN=$(grep -m1 '^NPM_TOKEN=' /srv/asc/env.infisical | cut -d= -f2-) \
  npm run name-check

# 3. the publish. prepublishOnly runs pack.sh && stranger.sh on the way;
#    both must pass or nothing reaches the registry.
TMP=$(mktemp -d) && chmod 700 "$TMP"
printf '//registry.npmjs.org/:_authToken=%s\n' \
  "$(grep -m1 '^NPM_TOKEN=' /srv/asc/env.infisical | cut -d= -f2- | tr -d \"'\")" \
  > "$TMP/.npmrc" && chmod 600 "$TMP/.npmrc"
npm --userconfig "$TMP/.npmrc" publish
rm -rf "$TMP"

# 4. what a stranger gets, from outside any checkout
npm i -g <chosen> && epito --version && epito init historian && epito validate
```

The token is never written into this repository, never passed on a
command line, and the temporary `.npmrc` is 0600 and deleted. `epito`
has no npm-login step of its own; this is the whole credential path.

One detail from this run: the value in `/srv/asc/env.infisical` is
single-quoted, so `cut -d= -f2-` yields `'npm_…'` with the quotes. npm's
ini parser strips them, and `name-check` strips them too, but anything
else reading that file must.

## How name-check asks, and why it publishes nothing

`npm run name-check` PUTs an **empty body** to
`https://registry.npmjs.org/<name>`. The registry runs its name checks —
spam, then similarity — before it validates the request body, so the
verdict comes back and the request is then thrown out for containing no
package:

| Status | Means |
|---|---|
| 403 | the name is refused; npm's text names the similar packages |
| 402 | `must sign up for private packages` — **the name is fine**; an empty probe declares no access, and `publishConfig.access` does at publish time |
| 400 | `Missing required package name or _id` — **the name is fine** |
| 401 | the credential is expired or revoked — a different fix entirely |

Verified by probing ten names and then `GET`ting every one of them: all
ten still 404. No version exists, no name is burned, no candidate is
spent. That is what makes it safe to ask about a name before deciding
on it.

`name-check` is deliberately **not** in `prepublishOnly`. The two gates
there touch no account and no network beyond a local tarball install,
and that property is worth more than catching this one class
automatically. It is step 2 above instead.

## What is still not done

- The publish itself. It no longer waits on a name: it waits on
  whoever holds `NPM_TOKEN` — the chair on the host, or the owner —
  because reaching a credential is a secrets action and not the
  engineer's. Before 19:26Z on 2026-10-24, or it costs her a new token.
- Scope 2-2's browser click, unrelated to any of this and still open
  since 2026-10-16.
