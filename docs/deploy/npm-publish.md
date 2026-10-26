# Publishing the CLI to npm

Cycle 2, bet `mvp-stranger-npm-v0`, scope 2-1's last step. Written
2026-10-23 by the engineer seat, on the run that tried the real publish
and was refused.

**The publish is one command and one decision away, and neither is about
the token.** The name was decided on 2026-10-23 (`epito-cli`, below). The
decision that is left is the publish itself: the manifest now carries
`private: true`, so npm refuses this package until somebody removes that
field by hand. Step 3 is that removal, and it is deliberately a step of
its own rather than a line inside the publish.

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

**That expiry has passed. As of 2026-10-26 this token is two days dead,
so step 4 below will come back 401 until somebody mints a new one** —
an account action, not a code one, and not this seat's to take. The rest
of this document is still accurate: the name is decided, the sequence is
right, and the gates are green. Minting the replacement is the only
thing between them and a published package.

Everything else the publish needs is present. `NPM_TOKEN` is in
Infisical under that name and the credential path below works; what was
missing when this was written was a name npm would accept, and that was
settled on 2026-10-23.

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

# 3. lift the refusal. The manifest carries `private: true`, so npm will not
#    publish this package until somebody deliberately removes the field. That
#    removal IS the decision; it is not a chore, and it is why this is its own
#    numbered step.
#    Delete the line, do not rewrite the file. Both `npm pkg delete private`
#    and a JSON round-trip in node reformat the whole manifest — they expand
#    the hand-compacted `peerDependenciesMeta` entries, and `git diff --stat`
#    comes back "12 insertions, 5 deletions" instead of one. That churn would
#    ship in the tarball. Measured both ways on 2026-10-26.
cd cli
sed -i.guarded '/^  "private": true,$/d' package.json
git diff --stat package.json       # -> 1 file changed, 1 deletion. Nothing else.
node -e 'if (require("./package.json").private !== undefined) { console.error("the field is still there — the sed matched nothing; check the indentation and the trailing comma"); process.exit(1) } console.log("lifted")'

# 4. the publish. prepublishOnly runs pack.sh && stranger.sh on the way;
#    both must pass or nothing reaches the registry.
TMP=$(mktemp -d) && chmod 700 "$TMP"
printf '//registry.npmjs.org/:_authToken=%s\n' \
  "$(grep -m1 '^NPM_TOKEN=' /srv/asc/env.infisical | cut -d= -f2- | tr -d \"'\")" \
  > "$TMP/.npmrc" && chmod 600 "$TMP/.npmrc"
npm --userconfig "$TMP/.npmrc" publish
rm -rf "$TMP"

# 5. put the refusal back, in the same sitting, whether step 4 succeeded or
#    not. A tree left with the field lifted is a tree where the next
#    accidental `npm publish` succeeds. `sed -i.guarded` in step 3 left the
#    original beside it, so this is a move and not a re-edit.
mv package.json.guarded package.json
node -e 'console.log(require("./package.json").private === true ? "guarded" : "STILL LIFTED — put it back")'
git diff --stat package.json       # -> empty. The manifest is byte-identical again.

# 6. what a stranger gets, from outside any checkout
npm i -g <chosen> && epito --version && epito init historian && epito validate
```

The token is never written into this repository, never passed on a
command line, and the temporary `.npmrc` is 0600 and deleted. `epito`
has no npm-login step of its own; this is the whole credential path.

## Do not verify the refusal with `npm publish --dry-run`

It cannot see it. Run the dry run against the guarded manifest and it
prints `+ epito-cli@0.1.0` and exits 0 — the same output it prints with
the field removed. npm throws the refusal as the first statement of
`libnpmpublish`'s publish function and calls that function behind
`if (!dryRun)`, so the rehearsal never reaches it:

```
node_modules/libnpmpublish/lib/publish.js:15   if (manifest.private) throw EPRIVATE
lib/commands/publish.js:161                    if (!dryRun) { await ... libpub(...) }
```

Read on npm 10.9.8. The in-command copy of the same check at
`lib/commands/publish.js:136` does not help either; it is guarded by
`workspace &&`, and publishing `cli/` is not a workspace publish.

So anybody checking the guard the way this runbook used to imply would
conclude it is absent. The gate that actually asserts it is `pack.sh`
section 1d, which performs a real publish against a recording registry
the suite starts on `127.0.0.1` — three readings one field apart: the
lifted manifest sends a 376 kB tarball, the committed one refuses with
`EPRIVATE` and sends nothing, and the dry run of the committed one exits
0 having sent nothing. That section runs on every publish, because
`prepublishOnly` runs this suite.

One ordering detail, if you try to reproduce the refusal by hand. npm
checks for a credential *before* it reaches the private check: with no
token configured, `npm publish` stops at `ENEEDAUTH` ("This command
requires you to be logged in to …") and never gets as far as
`EPRIVATE`. So a bare `npm publish` with no credential proves nothing
about the guard either. Section 1d writes a throwaway `_authToken` for
its own loopback registry for exactly this reason — the fake token is
not only a safety belt, it is what lets `EPRIVATE` be the refusal that
fires.

Two things follow for whoever runs step 4. The dry run is still worth
running — it is what proves the gate's own suites execute rather than
skipping themselves, which is the leak fixed earlier and pinned by
section 1b — but a clean dry run is evidence about the gate, never about
the refusal. And a dry run that *fails* with `EPRIVATE` means you are on
a version of npm that fixed this; section 1d's last two assertions are
written to fail that day and say so.

**Where `name-check` finds a credential, and one npm behaviour that
matters here.** It reads `NPM_TOKEN` first, and otherwise reads
`//registry.npmjs.org/:_authToken` straight out of the npmrc files, in
npm's own precedence order: `cli/.npmrc`, then the userconfig (npm
exports its path as `npm_config_userconfig`, so `npm --userconfig`
works), then the globalconfig. It does **not** ask `npm config get` for
the token, which is what it did first and which cannot work: npm 10
marks that key PROTECTED and refuses to return it, answering `npm error
The //registry.npmjs.org/:_authToken option is protected, and can not
be retrieved in this way` and exiting 1. Measured on npm 10.9.8 against
a `--userconfig` that genuinely held a token — `npm config list` shows
the key as `(protected)`, so the credential was loaded and still
unreadable, and npm does not export it to a run-script either. The
practical effect, before the fix, was that a machine logged in with
`npm login` was told it had no credential at all, by a refusal whose own
suggested fix was `npm login`. Reading the file is what makes that line
true.

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
