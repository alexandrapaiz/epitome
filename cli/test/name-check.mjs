#!/usr/bin/env node
// Will the registry take this package name? — asked before the tarball is
// built and before a publish token is spent.
//
//   npm run name-check              # the name in package.json
//   npm run name-check -- epito-cli # a candidate
//
// This exists because a publish can fail for a reason the publish gate cannot
// see. test/pack.sh and test/stranger.sh prove the tarball is right; neither
// of them talks to an account, on purpose. So on 2026-10-23, with both suites
// green at 118 and 33 assertions, `npm publish` came back:
//
//   403 Package name too similar to existing packages exit,pino; try renaming
//       your package to '@alexandrapaiz/epito' and publishing with
//       'npm publish --access=public' instead
//
// npm's typosquat filter refuses `epito` outright, and no new token and no
// amount of waiting changes that. The name was the blocker and nothing in
// this repository could say so until the publish itself said it.
//
// HOW IT ASKS, AND WHY IT PUBLISHES NOTHING
//
// The registry runs its name checks — spam, then similarity — before it
// validates the request body. So a PUT whose body is `{}` gets the real name
// verdict and is then rejected for having no package in it:
//
//   403  the name is refused (similarity or spam); npm's text names why
//   402  "must sign up for private packages" — the name is FINE; an empty
//        probe declares no access, and package.json's publishConfig.access
//        does at publish time
//   400  "Missing required package name or _id" — the name is FINE; the
//        verdict came back and the body was thrown out, which is the point
//
// Verified by probing seven names and then GETting each one: all seven still
// 404. Nothing is created, no version exists, no name is burned. That is what
// makes this safe to run on a candidate you have not decided on yet.
import { readFileSync } from 'node:fs'
import { execFileSync } from 'node:child_process'
import { fileURLToPath } from 'node:url'
import { dirname, join } from 'node:path'

const CLI = dirname(dirname(fileURLToPath(import.meta.url)))
const REGISTRY = 'https://registry.npmjs.org'

const die = (msg) => { console.error(msg); process.exit(1) }

const pkg = JSON.parse(readFileSync(join(CLI, 'package.json'), 'utf8'))
const name = process.argv[2] || pkg.name

// The token comes from the environment or from npm's own config, so this reads
// the same credential `npm publish` would use and never takes one on argv —
// a token on a command line lands in shell history and in the process table.
function token () {
  if (process.env.NPM_TOKEN) return process.env.NPM_TOKEN.replace(/^'|'$/g, '')
  try {
    const v = execFileSync('npm', ['config', 'get', '//registry.npmjs.org/:_authToken'],
      { cwd: CLI, encoding: 'utf8' }).trim()
    if (v && v !== 'undefined' && v !== 'null') return v
  } catch { /* npm absent or no such key: handled by the caller */ }
  return null
}

const tok = token()
if (!tok) {
  die(`epito: name-check needs the same npm credential a publish would use, and there is none on this machine.

It asks the registry whether it would accept the name — a question only an authenticated request can ask — and it publishes nothing either way.

Fix: put the publish token in NPM_TOKEN for this one command, or log the machine in:
  NPM_TOKEN=... npm run name-check
  npm login`)
}

const auth = { Authorization: `Bearer ${tok}` }

// Who the credential is, and whether it is still alive. An expired token and a
// refused name are both "the publish failed" and want opposite fixes, so the
// two answers are reported apart.
let who = null
{
  const r = await fetch(`${REGISTRY}/-/whoami`, { headers: auth })
  if (r.status === 401) {
    die(`epito: the npm credential on this machine is not accepted by the registry (401), so name-check cannot ask it anything.

A publish token that has expired or been revoked fails exactly like this.

Fix: check the token's expiry on npmjs.com (Access Tokens), mint a replacement, and store it wherever this machine reads NPM_TOKEN from.`)
  }
  if (!r.ok) die(`epito: the registry answered ${r.status} to \`GET /-/whoami\`, so the credential could not be identified.\n\nFix: retry; if it persists, check https://status.npmjs.org before treating it as a token problem.`)
  who = (await r.json()).username
}

// Any token this credential can see that dies within three days. The clock on a
// publish token is the thing nobody remembers until the publish is overdue.
const SOON_MS = 3 * 24 * 60 * 60 * 1000
const expiring = []
{
  const r = await fetch(`${REGISTRY}/-/npm/v1/tokens`, { headers: auth })
  if (r.ok) {
    const { objects = [] } = await r.json()
    for (const t of objects) {
      if (t.revoked || !t.expiry) continue
      const ms = Date.parse(t.expiry) - Date.now()
      if (ms < SOON_MS) expiring.push({ name: t.name || '(unnamed)', expiry: t.expiry, hours: Math.floor(ms / 3600000) })
    }
  }
}

// Is the name already somebody's?
const taken = await fetch(`${REGISTRY}/${encodeURIComponent(name)}`)
let owners = null
if (taken.ok) {
  const doc = await taken.json()
  owners = (doc.maintainers || []).map((m) => m.name)
}

// The verdict. Empty body on purpose: see the header.
const probe = await fetch(`${REGISTRY}/${encodeURIComponent(name)}`, {
  method: 'PUT',
  headers: { ...auth, 'Content-Type': 'application/json' },
  body: '{}'
})
const said = await probe.text()
const because = (() => { try { return JSON.parse(said).error } catch { return said.slice(0, 300) } })()

console.log(`name-check: ${name} — as ${who}`)
for (const t of expiring) {
  console.log(`  !    token "${t.name}" expires ${t.expiry} (${t.hours}h) — a publish after that needs a new one`)
}

if (owners) {
  const mine = owners.includes(who)
  console.log(`  ${mine ? 'ok  ' : 'FAIL'} ${name} is published already, maintained by ${owners.join(', ')}`)
  if (!mine) {
    die(`
epito: the name "${name}" on npm belongs to ${owners.join(', ')}, not to ${who}, so a publish of it would be refused however good the tarball is.

Fix: pick a name this account can hold and set it in cli/package.json's "name", or ask ${owners[0]} to add ${who} as a maintainer. \`npm run name-check -- <candidate>\` answers for a candidate without publishing it.`)
  }
} else {
  console.log(`  ok   ${name} is unpublished — nobody holds it`)
}

if (probe.status === 400 || probe.status === 402) {
  console.log(`  ok   the registry accepts the name "${name}" (probe: ${probe.status}, body rejected as intended)`)
  console.log(`\nname-check: 0 blockers — \`npm publish\` from cli/ is the next command, and the publish gate runs on the way.`)
  process.exit(0)
}

if (probe.status === 403) {
  die(`  FAIL the registry refuses the name "${name}"

epito: npm will not accept the package name "${name}", so the publish cannot succeed no matter what the tarball or the token look like. The registry said:

  ${because}

This is npm's typosquat filter, not a quota and not an outage: it does not clear with time, a new token does not change it, and retrying spends the clock on nothing. The name has to change, or move under a scope.

Fix: choose a name and set it in cli/package.json's "name" — and change the install line in cli/README.md to match, which test/stranger.sh checks. \`npm run name-check -- <candidate>\` gives a verdict on any candidate and publishes nothing, so the choice can be made before anything is spent.`)
}

die(`  FAIL the registry answered ${probe.status}

epito: name-check cannot tell whether npm would accept "${name}" — it expected 400, 402 or 403 from the probe and got ${probe.status}:

  ${because}

Fix: treat the name as unknown rather than clear, and read the response above against https://status.npmjs.org before publishing.`)
