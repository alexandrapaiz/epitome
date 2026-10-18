# `epito deploy --target cloudflare` — an agent that lives on the edge

Status: **prototype, built 2026-10-18** (owner ask, handed to this seat by the
PM the same morning; due Wednesday's brief, 2026-10-21). What is built is
below, and so is the one step that is not epito's to take.

## What the owner asked for

> `epito deploy` takes one of our manifests and produces an agent on
> Cloudflare with its own identity, a schedule that fires, state that
> survives, and a page showing the agent, its last run and a button that
> triggers it.

Done means she opens a link and triggers an agent herself.

## The shape

The resident runtime (`epito run` + `epito worker` + Temporal) is a box you
own. Cloudflare is the other end of the same promise: nothing to provision,
nothing to keep alive, and the agent still has an identity, a schedule and a
memory. One manifest reaches both, which is the claim this prototype was
built to test.

Four things the ask names, and what each one is on Cloudflare:

| the ask | on the resident runtime | on Cloudflare |
| --- | --- | --- |
| its own identity | the agent's GitHub App, key in `.epito/keys/` | the same App — the key is a Worker secret, and the Worker signs its own JWT and mints its own installation token per run, on WebCrypto |
| a schedule that fires | `epito run` registers a Temporal schedule from `[trigger].cron` | `triggers.crons` in the generated `wrangler.jsonc`, the same five UTC fields, copied verbatim |
| state that survives | the engine's history, `.epito/board.jsonl` | one Durable Object per agent, addressed by the agent's name, holding the run log |
| a page | the ingress on the host | the Worker's own `GET /`, behind one door |

**No new manifest field, not one.** That is the result worth reporting on its
own. Every one of the four already had an answer in `agent.toml`:
`[identity].scopes` is the App, `[trigger].cron` is the schedule,
`[runtime].repo` + `entry` is what a run reads, and where the state lives is
the runtime's business and never the manifest's. Had a second deploy target
needed a field, that would have been a finding about the freeze — the spec
claims a manifest is portable. It needed none.

## Using it

```sh
# say what it would do, touching nothing
epito deploy historian agents/historian --target cloudflare --dry-run

# write the bundle (default: .epito/cloudflare/<agent>/)
epito deploy historian agents/historian --target cloudflare

# the one step that is yours, because it spends your Cloudflare account
cd .epito/cloudflare/historian
npx wrangler deploy
wrangler secret put EPITO_TRIGGER_SECRET
wrangler secret put EPITO_APP_ID
wrangler secret put EPITO_APP_KEY < ../../keys/historian.pkcs8.pem
wrangler secret put ANTHROPIC_API_KEY
```

`wrangler deploy` prints the Worker's URL. The link to send is that URL with
the door key on it:

    https://epito-historian.<your-subdomain>.workers.dev/?key=<EPITO_TRIGGER_SECRET>

The bundle is four files and no more: `wrangler.jsonc` (the Workers config),
`agent.js` (the manifest's facts, compiled in), `worker.mjs` (the runtime,
identical in every bundle) and a `README.md` that says all of the above for
the agent in front of you.

### Why epito stops before `wrangler deploy`

The same reason it stops before the "Create GitHub App" button: the step
spends somebody's account and is not reversible by a tool. epito prepares
everything around it — the config, the permission set, the key in the only
encoding the runtime can read, the exact commands — and the human performs
the one irreversible act. `--dry-run` says what would be written and touches
neither the network nor a browser nor an account.

## The secrets, and why each exists

Named in the deploy output and in the bundle's README, derived from the
manifest, values never written anywhere by epito.

| name | what it is |
| --- | --- |
| `EPITO_TRIGGER_SECRET` | the one door. Every request carries it, as `?key=` in a link or `x-epito-secret` in a header — the same header the resident runtime's ingress reads. Unset, the Worker refuses everything rather than standing open. |
| `EPITO_APP_ID` | the agent's own GitHub App id |
| `EPITO_APP_KEY` | its App private key, **PKCS#8**. GitHub issues PKCS#1 and the Workers runtime imports PKCS#8 only, so `epito deploy --target cloudflare` writes the converted copy beside the original at `.epito/keys/<agent>.pkcs8.pem` (0600) and names it in the command. A PKCS#1 key set here is refused by name, with the path to the converted one. |
| `ANTHROPIC_API_KEY` | the edge's floor. On a box, the last road in a route chain names no `token_env` and runs on the operator's Claude subscription; a Worker cannot hold a subscription, so a road with no key of its own takes this one. Asked for only when the manifest has such a road. |
| each `token_env` / `base_url_env` | exactly the names the manifest's `[[runtime.route]]` chain declares, for the same reason the resident runtime wants them |
| `EPITO_GITHUB_API` | optional, GitHub Enterprise only — the same override every other epito command takes |

## What an edge run is, exactly

One turn.

1. Pick the first road whose key this Worker holds, in the order the manifest
   wrote them. A closed road is named with the reason, the same way
   `epito routes` names one on a box.
2. Sign a ≤10-minute JWT as the agent's own App and mint an installation
   token for **exactly** the permissions `[identity].scopes` maps to, on
   **exactly** the repository `[runtime].repo` names. The permission set is
   compiled into the bundle from the manifest, so there is no other input a
   mint could use — rule 2 holds on the edge by construction.
3. Read `[runtime].entry` out of that repository with that token, fresh. Not
   compiled in: the charter is the thing that changes, and an agent running a
   stale copy of its own charter is the bug the resident runtime avoids by
   cloning fresh.
4. Ask the model once, with the charter and a plain statement of what this
   run is.
5. Record the run in the Durable Object.

**It does not clone, commit or open a pull request.** A Worker has no git and
no disk. The deploy output says so before you deploy, and the page says so on
every run — `turns: 1 of 120` beside the manifest's own cap — because a
one-turn run quietly presented as a full seat is exactly the silence this
product refuses everywhere else. What an edge seat should eventually *do* is
an open question, recorded in `docs/ideas.md` and deliberately not answered
here.

## What it refuses, and why

Before anything is written, in the product's own vocabulary:

- **`[runtime].adapter = "langgraph"`** (and `[runtime].graph`) — an adapter
  is a process epito spawns, and a Worker spawns no processes: no
  interpreter, no virtualenv, no filesystem to install one into. The refusal
  names the resident runtime as the place that seat runs.
- **no `[runtime].repo`** — the Worker reads the charter out of it on every
  run, so a manifest with no repository describes a run with nothing to read.
- **no trigger at all** — a Worker made of it would never wake.
- **a cron Cloudflare would reject** — caught here rather than at
  `wrangler deploy`, long after this command said the bundle was ready.
- **an unmapped scope** — the same `SCOPE_MAP` refusal every mint makes.

And two things it *reports* rather than refuses, because they are honest
narrowings and not errors: the one-turn run against `max_turns`, and a seat
with no `[trigger].webhook`, whose page renders without a button and says
why (a seat that did not ask to be woken by hand is not woken by hand).

## How it is tested

`cli/test/unit-cloudflare.mjs` generates a bundle into a temp directory and
imports `worker.mjs` **out of that bundle**, then drives it against a fake
Durable Object and a fake fetch — the door, the page, the mint, the road
chain, and the three ways a run goes wrong. The JWT the Worker signs is
verified against the key pair the test generated, so "its own identity" is an
assertion rather than a claim.

`cli/test/smoke-cloudflare.sh` asserts the command surface always, and — when
wrangler is on the box (`bash test/prereqs.sh` installs it) — puts the
generated bundle into a real local Workers runtime and drives it end to end
against one stub standing in for GitHub and the model: the bundle boots with
no edits, the door refuses, the button mints and records a run, the schedule
fires the same run, and the runs are still there after the runtime is killed
and restarted.

Nothing in either suite touches an account, a real key or the network.

## What is left

One step: somebody with the Cloudflare account runs `wrangler deploy` and
sets four secrets. Everything before it is built and run; nothing after it
is code.
