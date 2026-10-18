# Cloudflare brief — PM to the owner (2026-10-18)

Answers the second half of board item 31d66aeb: what Cloudflare gives
that the host does not, what it costs at 10 and 1000 agents, and
whether our own seats should move. The first half — the prototype
itself — is PR #148 (draft, engineer, 2026-10-18): `epito deploy
--target cloudflare` packs one manifest into a Worker with its own
GitHub App identity, a schedule copied verbatim from `[trigger].cron`,
a Durable Object that survives a redeploy, and a page with a button.
Built and run against a real Workers runtime on the engineer's machine;
not yet deployed, because `wrangler deploy` spends your Cloudflare
account and that step is refused as anyone's but yours.

## 1. What Cloudflare gives that the host does not

The host today (`deploy/provision-host.sh`) is one Oracle Always Free
A1 instance: hand-provisioned, one region, kept alive by systemd, state
on its filesystem and in the Temporal engine, no public URL unless you
open a port and point a domain at it. It is free, and it is also one
machine — reclaimed by Oracle if it goes idle (`provision-host.sh`'s
own keepalive ping exists because of that), and every new agent is
another thing running on the same box.

A Cloudflare Worker needs none of that provisioning. `epito deploy`
writes the bundle, Cloudflare runs it at whichever of its edge
locations is nearest the request, and it scales to zero between runs
with nothing idling and nothing to keep alive. Its page and its public
URL are the Worker's own `GET /` route — no port to open, no domain to
point. Its state is one Durable Object addressed by the agent's name,
which is what "survives a redeploy" means mechanically: redeploying the
Worker's code does not touch the Object's storage.

Cloudflare's own Agents SDK already gets close to this shape natively
— a Durable Object per agent, alarm-based scheduling (`scheduleEvery()`)
— which is the finding docs/market.md recorded in cycle 1 (rev 1, §1,
"Cloudflare has trigger + runtime + *addressable* identity"). What it
does not ship is an agent that is a **credentialed principal on a
third-party platform** — a GitHub App, specifically. PR #148 is that
missing piece: the Worker signs its own JWT on WebCrypto and mints its
own installation token per run, so your GitHub credentials are never
near it, same as the host's identity leg (ADR-2/ADR-20) and no new
manifest field to get there (§3 below).

## 2. What it costs, at 10 and 1000 agents

Pricing, read off Cloudflare's own page
([developers.cloudflare.com/workers/platform/pricing](https://developers.cloudflare.com/workers/platform/pricing/),
accessed 2026-10-18): Workers Paid is a flat $5/month, and that plan is
required for Durable Objects at all (the free Workers plan does not
carry them). Included in the $5: 10 million requests/month and 30
million CPU-ms/month on the Worker side; 1 million Durable Object
requests/month and 400,000 GB-seconds/month on the Object side, plus 5
GB-month of SQLite storage. Overage, if you ever cross those lines, is
$0.30/million requests, $0.02/million CPU-ms, $0.15/million DO
requests, $12.50/million GB-s, and $0.20/GB-month of storage.

The shape of an edge run keeps you far under all of that. One run is
one Worker invocation (the trigger) plus a handful of Durable Object
operations (read the charter's prior state, write the new run record)
— no sustained compute, because the model call itself is a fetch, not
CPU time, and no idle cost between runs, because nothing is kept alive
to idle.

- **10 agents**, run at the busiest cadence any seat here already uses
  (twice daily) plus slack for owner page-views: call it 60
  runs/month/agent, 600 runs/month total. That is 600 Worker requests
  (0.006% of the included 10M) and, even generously counting 10 DO
  operations per run, 6,000 DO requests (0.6% of the included 1M).
  **Cost: $5/month flat** — the base fee, not usage, is the whole bill.
- **1000 agents**, same cadence: 60,000 runs/month, 60,000 Worker
  requests (0.6% of 10M), 600,000 DO requests at the same generous
  10-per-run estimate (60% of the 1M included, still inside it).
  GB-seconds and storage scale the same way — kilobytes of run-log
  state per agent, not gigabytes, and short bursts of CPU, not held
  compute. **Cost: still $5/month**, and would need roughly an order of
  magnitude more runs per agent, or ten times the DO operations per run,
  before overage charges start showing up at all.

Honest caveat: the model call itself bills to Anthropic, not
Cloudflare, and costs the same no matter which runtime dispatches it.
Cloudflare's meter stays close to free here because our runs are
bursty and short — exactly the shape its per-use pricing is built to
reward, and the shape a kept-alive host pays for whether it is busy or
not. The host's $0 and Cloudflare's ~$5/month are both real numbers;
neither is the dominant cost at either scale.

## 3. Whether our own seats should move

**No, not the five that exist today** (engineer, pm, market, okr, exo).
What they do — clone a repository, commit, open a pull request — is
exactly what a Worker cannot do: no git, no disk, so an edge run is one
model turn against its own charter and nothing more. The engineer's own
report on PR #148 says this plainly and so does the page it builds,
printing `turns: 1 of 120` beside every run so nobody mistakes the
Worker for the full seat. Moving a seat that needs to open pull requests
onto a runtime that cannot open one trades a free host for a $5 one and
loses the only thing that seat is for.

**Yes, for a narrower shape that does not exist yet.** `docs/ideas.md`
already carries this as a proposed idea in the engineer's own words
("the edge agent has no hands"), naming two possible shapes and a
recommendation: either give the Worker direct write access to GitHub's
content APIs for small diffs with no git, or make it a trigger-and-face
for work actually performed by `epito run` on a box, woken from the
page the Worker shows. The engineer's own read — "the second is
probably the honest one and it is a smaller build" — matches what this
brief finds independently from the cost side: an edge seat is cheap
precisely because it does one shallow thing well (mint, read, answer,
or wake something else), not because it was made to do everything a
resident seat does.

## Recommendation

1. **Treat the edge seat's purpose as settled in the direction the
   engineer already proposed** — a trigger and a public face for work
   done elsewhere, not a git-capable builder — unless you rule
   otherwise. Per the silence rule (standards/pm.md §22), this proceeds
   on 48 hours of silence from the `ask` this brief accompanies; nothing
   is built against it before then.
2. **Don't move engineer, pm, market, okr, or exo to Cloudflare.** The
   host is free and every one of them needs git. Nothing about this
   prototype argues otherwise.
3. **The one open step on PR #148 is yours whenever you want to see it
   live**: `wrangler deploy`, then four `wrangler secret put` lines and
   a link. Nothing on the build side blocks it.
4. **If you confirm direction 1, the edge-seat pilot gets its own
   PR/FAQ before it is shaped into a pitch** (standards/pm.md §2c) —
   this brief answers the cost-and-shape question Working Backwards
   needs answered first; it is not itself the go-ahead to build.
