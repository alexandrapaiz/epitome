# PR/FAQ: epitod v1 — the runtime on a durable engine

Status: proposed, 2026-09-26. Written Working Backwards before the code,
per the owner's directive of 2026-09-25 (recorded at HQ as ADR-036). The
owner's merge of the implementing PR is the go decision. Governed by
docs/standards/documents.md; the design section also answers to the
engineering-artifacts content bar.

---

## Read this first: the whole shape in a page

epitod v0 hand-built a scheduler, a per-seat mutex, a retry story, and a
crash story inside one Node process (`cli/src/run.js`, 364 lines). Those
four things are a workflow engine, badly. v1 deletes them and puts the
runtime on **Temporal**, self-hosted on the company host at
`127.0.0.1:7233`, for zero dollars. Temporal is the **engine**. `epitod`
is the **face**: manifests, agent identity, the vocabulary an owner reads.

The mapping is one-to-one, which is why this is a port and not a rewrite:

| What an agent needs | epitod v0 | epitod v1 |
|---|---|---|
| Wake on a schedule | `setInterval(tick, 30_000)` + `lib/cron.js` matcher | one Temporal **Schedule** per manifest, id `seat:<name>`, `cronExpressions` from `[trigger].cron`, `timezone = UTC` |
| One run at a time per seat | `s.running` boolean + hand-rolled coalescing | schedule `overlap = BUFFER_ONE`; ingress triggers use `signalWithStart` on workflow id `run:<name>` |
| A run | an `async` function that could not survive a restart | workflow **`SeatRun(name, trigger, payload, resume?)`** |
| Clone, execute, record, notify | four inline steps, no retry, no record of where they stopped | four **activities** with declared retries and timeouts |
| Presence (a held session) | a `Map` in process memory, lost on restart | workflow **`SeatWindow(name, ttl)`** holding `session_id` and the clone path, driven by signals |
| The roster you can see | `.epito/state.json`, written by the daemon | Temporal itself: `epito ps` lists schedules and running workflows |
| The record | `.epito/audit.jsonl` | `.epito/audit.jsonl`, unchanged, written by the `record` activity |

What actually changes for an operator: two units instead of one
(`epitod.service` reconciles schedules and serves the ingress,
`epitod-worker.service` runs the work), `state.json` stops being the
source of truth, and a machine reboot in the middle of a seat's run no
longer loses the run.

**If you only internalize one section, make it "Why an engine at all"
below.** The single most valuable item in this document is the line in
that section about what a restart costs today: a run in flight is simply
gone, and nothing in the system knows it existed. That is the defect the
engine retires, and it is the reason to spend a dependency on it.

The honest tension, stated once here and again at the end: this adds
**four runtime dependencies** (`@temporalio/client`, `worker`,
`workflow`, `activity`) to a component whose dependency budget in
docs/architecture.md reads "none targeted", and it adds a **server we
now operate**. We are trading a 364-line file we understand completely
for a system we understand partly. The trade is worth making because the
part we do not control is the part that is hardest to write and least
differentiating, and because Temporal is a surface we can leave: the
manifests, the activities, and the audit log are all engine-agnostic.

---

## Press release

**epito.me puts agents on a runtime that survives the machine**

*Agents woken by a schedule, spoken to in a held session, and resumed
exactly where they stopped — on a durable engine you host yourself, for
nothing.*

Today epito.me shipped epitod v1, the runtime leg of the agent primitive.
An agent is identity plus trigger plus runtime, minted from one file.
Until now the runtime leg was a resident daemon: good enough to prove the
shape, and honest about what it could not do. If the box rebooted while
an agent was working, the run vanished. If a clone failed because GitHub
blinked, the run failed with it. If you asked what happened at 06:00
yesterday, the answer was a log file.

epitod v1 keeps the manifest and replaces the machinery underneath it
with Temporal, self-hosted. A manifest's `[trigger].cron` becomes a
Temporal Schedule. A run becomes a workflow with four activities — clone,
execute, record, notify — each with its retries and timeouts declared in
one readable place instead of implied by control flow. A work window, the
stretch of time in which a human can speak to an agent in the session it
is holding, becomes a long-running workflow that receives messages as
signals.

Nothing about the product's vocabulary moves. The same `agent.toml` that
ran on v0 runs on v1 with no edit. `epito run <roster>` still takes a
directory of manifests. `epito ps` still prints a roster, now read from
the engine rather than from a file the daemon happened to write.
`.epito/audit.jsonl` is still the append-only record. What moves is the
class of failure an owner has to think about.

"The runtime was the leg people hand-built worst," said the engineer
seat. "Everyone building an agent org writes a cron loop, then a mutex,
then a retry, then a crash-recovery story they never finish. We wrote
the first four too. Deleting them in favor of an engine that has done
this for a decade is the whole point of being infrastructure rather than
a script."

epitod v1 runs on one small always-on host. Temporal runs beside it in
two containers on the host's existing Postgres, reachable only on
loopback. There is no hosted control plane to buy, no per-workflow bill,
and no vendor in the path: Temporal Cloud is explicitly out of scope.
The cost of the runtime leg remains zero dollars a month.

Available today for the four agent companies the owner runs — 36
manifests across HQ, alexandria, Ursa and epitome — starting with HQ
after a clean week of presence-only operation.

---

## FAQ

### Why an engine at all? What does a restart cost today?

It costs the run, silently. In v0 a run is an `await runAgent(...)` inside
`startRun` in `cli/src/run.js`. The state that says "this seat is running,
this is its trigger, this is the clone it is working in" lives in a
`Map` in that process. `SIGTERM` kills the child process group and the
`Map` goes with it. The next start re-reads the roster and knows nothing.
`.epito/audit.jsonl` holds a `run.start` line with no `run.end`, forever.

Three more costs follow from the same root:

1. **No retry that means anything.** `git clone` fails and the run is
   over (`exit: "clone"`). The right behavior is to retry the clone a few
   times with backoff, and to never retry the `claude -p` execution,
   because an execution that half-ran has already pushed commits. In v0
   those two policies would be two hand-written code paths. In v1 they
   are two `RetryPolicy` objects, four lines each, next to each other.
2. **Coalescing is ours to get right.** `enqueue()` in v0 implements a
   per-seat mutex with a one-slot buffer, including the subtle rule that
   two queued messages merge rather than replace. That is
   `ScheduleOverlapPolicy.BUFFER_ONE`, a field.
3. **No history.** "What did okr do last Tuesday, and why did it take 40
   minutes" is answerable from Temporal's event history and its UI. In v0
   it is answerable from a log file if nobody rotated it.

### Why Temporal and not a queue, or cron plus a script?

The unit of work here is long (an agent run is minutes to an hour),
stateful (a window holds a session id and a directory), and must survive
the process that started it. That is the durable-execution shape, and a
queue gives only the first half of it. The alternatives, honestly:

| Option | Why not |
|---|---|
| systemd timers plus a script | No state between steps, no per-seat overlap policy, no history, and presence (a held session with signals) has nowhere to live. This is v0 with extra files. |
| A job queue (BullMQ, pg-boss) | Buys retries. Does not buy the long-running stateful entity a window is, nor a schedule reconciler, nor searchable history. We would write those on top, which is writing Temporal badly. |
| Cloudflare Workflows / AWS Step Functions | A vendor in the runtime path and a bill. ADR-6 says integrations are surfaces, never dependencies; the runtime leg is not a surface. |
| Temporal Cloud | Same objection plus a per-action price. Explicitly forbidden by the directive. |
| **Temporal, self-hosted** | Schedules, per-schedule overlap policy, declared retries, signals and queries on long-running workflows, a UI, and a replay test story. Runs on the Postgres the host already has. |

### What does this cost?

Zero dollars. Temporal server runs as two containers on the existing host
(`temporalio/auto-setup` and `temporalio/ui`), against the host's
Postgres, bound to loopback: `127.0.0.1:7233` for gRPC and
`127.0.0.1:8080` for the UI, reached over an SSH tunnel rather than
published. The chair installed it with HQ's `runtime/temporal/install.sh`.

The real cost is memory and operational surface. Budget roughly 300–500 MB
resident for the server plus the UI on a small instance, and accept that
we now have a database whose retention we must set. Workflow history
retention is a namespace setting; 30 days is the right starting value for
a roster of 36 seats firing a handful of times a day.

### Node SDK or Python SDK?

**Node** (`@temporalio/client`, `@temporalio/worker`,
`@temporalio/workflow`, `@temporalio/activity`). The reason is language
continuity, not preference: the thing the `execute` activity must do is
exactly what `cli/src/lib/runner.js` already does — spawn
`claude -p --permission-mode bypassPermissions --model <m> --max-turns
<n> --output-format json` with a scrubbed environment, capture output,
parse `session_id` out of the result, kill the process group on timeout.
That is 171 lines of working, smoke-tested JavaScript. The Node SDK lets
the activity *wrap* it. The Python SDK would mean porting it, and a
second language in one repo for a component whose whole job is to shell
out.

The Python alternative is real and worth naming, because it is the one we
would pick if this were greenfield: Temporal's Python SDK is excellent,
the activity would be a `subprocess` call, and the wider agent ecosystem
is Python-first, which matters later if `[runtime]` grows a non-Claude
executor. The cost of switching to it, should we want to, is confined to
`cli/src/temporal/` — the workflows are 120 lines of orchestration and
the activities are thin. Nothing in the manifest spec, the ingress, or
the audit format is Node-shaped. Revisit when a second executor arrives,
not before.

### Does my `agent.toml` change?

No. Manifest spec v0.1 stays compatible and every existing key keeps its
meaning. v1 adds exactly one optional key, `[runtime].slack_webhook_env`,
for per-agent Slack routing. A manifest without it behaves as it does
today: a seat listing `SLACK_WEBHOOK_URL` under `[runtime].env` posts to
the single webhook the runtime holds, which is `#hq`.

```toml
[runtime]
model = "claude-sonnet-5"
entry = "prompts/engineer-agent.md"
repo = "alexandrapaiz/epitome"
slack_webhook_env = "SLACK_WEBHOOK_URL_EPITOME"   # new, optional
env = ["CLAUDE_CODE_OAUTH_TOKEN", "GH_TOKEN", "SLACK_WEBHOOK_URL_EPITOME"]
```

The rule that makes this safe is the rule that already governs every
secret: the manifest names it, the runtime holds the value, and a name
the manifest does not list is never injected. So `slack_webhook_env` must
also appear in `[runtime].env`, and `epito validate` says so by name when
it does not.

### What happens to `.epito/state.json`?

It stops being written and stops being read. `epito ps` reads Temporal:
`client.schedule.list()` for the registered schedules, and
`client.workflow.list()` for what is running, plus a query against each
open `SeatWindow` for the session it holds. This is the point of the
change — there is one place that knows what is happening, and it is the
engine, not a file a daemon rewrites on every state transition.

`.epito/audit.jsonl` does not change. It stays append-only, one JSON
object per line, written by the `record` activity. Temporal's history is
the engine's record of itself; `audit.jsonl` is the product's record, in
the product's vocabulary, and it outlives any engine we choose.

### What runs where?

Two systemd units and one container pair.

| Process | Unit | What it does |
|---|---|---|
| reconciler plus ingress | `epitod.service` | loads the roster, reconciles Temporal schedules to match it, serves `POST /hooks/<name>`, `/message/<name>`, `/window/open`, `/window/close`, `GET /healthz` as a thin Temporal client |
| worker | `epitod-worker.service` | polls task queue `seats`, runs the activities, does all the cloning and executing |
| Temporal server plus UI | docker, via HQ `runtime/temporal/install.sh` | `temporalio/auto-setup` on `127.0.0.1:7233`, `temporalio/ui` on `127.0.0.1:8080`, on the host's Postgres |

Both units run as the unprivileged user `seats` and read their secrets
from `/srv/asc/env`, which is where `TEMPORAL_ADDRESS` and
`TEMPORAL_NAMESPACE` live too. Splitting reconcile-plus-ingress from the
worker is not ceremony: restarting the ingress to pick up a roster change
must not kill work in flight, and with the worker in its own unit it
does not.

### Is the ingress still the same?

The routes, the shared-secret auth, the bodies and the error strings are
unchanged. What changes is what happens after the 202:

| Route | v1 behavior |
|---|---|
| `POST /hooks/<name>` | `signalWithStart` on workflow id `run:<name>`: starts `SeatRun`, or delivers a `followUp` signal to the run already going, which is v0's coalescing |
| `POST /message/<name>` | if a `SeatWindow` is open for the seat, send the `message` signal to it; otherwise `signalWithStart` a fresh `SeatRun` carrying the text, and say so in the response as today |
| `POST /window/open` | start `SeatWindow` with workflow id `window:<name>`; if one is running, send `refresh` |
| `POST /window/close` | send the `close` signal |
| `GET /healthz` | liveness, no secret, and it now also reports whether Temporal is reachable |

### What does the cutover look like?

All 36 manifests are presence-only today: no `[trigger].cron`, so
reconcile registers zero schedules and nothing fires on a clock. That is
deliberate, and it is what makes this cutover boring. The sequence:

1. Land this PR. Nothing in production changes, because nothing is
   scheduled.
2. Run the worker and the reconciler against the live server with the
   presence-only roster for a week. Open windows by hand, speak to seats,
   watch the UI. This exercises every path except the schedule.
3. HQ first: add `[trigger].cron` to HQ's 8 manifests, reconcile, watch
   one full day.
4. Then alexandria (12), Ursa (11), epitome (5), one company per day.

The rollback at any step is `epito run` against a roster with the cron
lines removed: reconcile deletes the schedules, and the seats go back to
presence-only.

### What is the failure story now?

| Failure | What happens |
|---|---|
| Host reboots mid-run | The workflow survives. The `execute` activity does not: its process is gone, and it is deliberately not retried, so the workflow records the failure and ends. The next scheduled fire is a clean run. Temporal knows the run existed and how it ended, which is the improvement. |
| `git clone` fails | Retried up to 5 times with backoff. Persistent failure ends the run with the same `clone` outcome v0 reported. |
| `claude -p` exits non-zero | Recorded, notified, not retried. An execution that half-ran has already pushed commits, so retrying it is worse than failing. |
| The run exceeds its timeout | `EPITO_RUN_TIMEOUT_MS` is the activity's `startToCloseTimeout` and the workflow's run timeout. The activity heartbeats while the child writes output, so a wedged run is detected rather than waited out. |
| Slack is down | `notify` is retried 3 times and then given up on. A Slack outage has never been allowed to take a run down and still is not. |
| Temporal is down | The ingress answers 503 naming the address it could not reach. Schedules fire late, not never, once it is back. |
| The worker dies mid-run | The activity's child process dies with it. The workflow is intact and will report the activity's failure when the worker returns. |

### What is deliberately not in v1?

- **A second worker host.** A window holds a filesystem path, so the
  child `SeatRun` of a `SeatWindow` must land on the host that made the
  clone. v1 runs exactly one worker host. Two hosts needs host-pinned
  task queues, which is a small change and a real design decision, so it
  waits for a reason.
- **A true cross-trigger per-seat mutex.** Scheduled runs serialize
  against each other by `BUFFER_ONE`, and ingress-triggered runs
  serialize against each other by `signalWithStart` on a shared workflow
  id. A cron fire and a hook can still overlap, because a schedule
  always appends its scheduled time to the workflow id it starts. Closing
  that gap wants a per-seat entity workflow in front of `SeatRun`. It is
  in docs/ideas.md as `proposed`, and it is the first thing to do in v1.1.
- **Replacing `GH_TOKEN` with a per-agent App token.** Still bet 2's
  slice. The `execute` activity is where it plugs in, unchanged.
- **Temporal Cloud, ever.**

---

## The design

What follows is the system design: components, the workflow and activity
signatures as code, the data that crosses each boundary, and the wire
flows. Names appear as they appear on disk.

### Laws (do not design around these)

1. **Temporal is the engine, epitod is the face.** No Temporal concept
   appears in a product-facing string. An owner reads about seats, runs,
   windows and manifests. `schedule`, `signal` and `task queue` live in
   `cli/src/temporal/` and in this document.
2. **Manifest spec v0.1 stays compatible.** New keys are optional. A
   manifest that ran on v0 runs on v1 unedited.
3. **The manifest crosses the boundary, not the roster.** A workflow's
   input carries the parsed manifest as a snapshot. The worker never
   reads the roster directory. This is what makes the worker stateless
   and a schedule's payload auditable.
4. **Workflows are deterministic; all input and output lives in
   activities.** No `fs`, no `spawn`, no `fetch`, no randomness in
   `workflows.js`. `Date.now()` is allowed and used: the workflow sandbox
   replaces it with workflow time, which replays identically.
5. **Retries and timeouts are declared, never implied.** Every activity
   names its `RetryPolicy` and its `startToCloseTimeout` at the call
   site in the workflow. `execute` is `maximumAttempts: 1`.
6. **$0, and no vendor in the runtime path.** Self-hosted Temporal on
   loopback. Temporal Cloud is never the answer.
7. **Secrets by name only.** `[runtime].env` lists names. The activity
   injects exactly those names into the child and nothing else. No secret
   value ever enters a workflow input, an activity input, an activity
   result, or `audit.jsonl`, because all four are written to Temporal's
   history in plain text.
8. **`audit.jsonl` is append-only and engine-agnostic.** It must remain
   readable if we replace Temporal.

Law 7 is the one with teeth and the one easiest to break by accident.
Temporal persists every workflow and activity argument to its database.
The `execute` activity therefore receives secret *names* and reads their
*values* from its own `process.env`, exactly as v0's `runAgent` does.

### Components

```
cli/src/
  index.js              argv -> command (adds `epito worker`)
  run.js                `epito run <dir>`: reconcile schedules + serve the ingress
  lib/
    manifest.js         spec v0.1 parse/validate  (+ slack_webhook_env)
    roster.js           NEW: find + load every agent.toml under a dir
    cron.js             still the validator for [trigger].cron (fail before registering)
    hooks.js            the HTTP ingress, unchanged
    runner.js           one run of one agent: clone, spawn, parse  (wrapped by an activity)
    slack.js            the one-line post  (+ per-agent webhook name)
    audit.js            .epito/audit.jsonl  (state.json writer retired)
  temporal/
    env.js              NEW: TEMPORAL_ADDRESS / TEMPORAL_NAMESPACE / EPITO_TASK_QUEUE, and the ids
    client.js           NEW: connect, with the error message an operator can act on
    schedules.js        NEW: reconcile(roster) -> created / updated / deleted / unchanged
    workflows.js        NEW: SeatRun, SeatWindow          (deterministic)
    activities.js       NEW: clone, execute, record, notify, cleanup
    worker.js           NEW: `epito worker`, task queue `seats`
    ps.js               NEW: `epito ps` from schedules + workflows + queries
```

### The two workflows

```js
// workflows.js — the whole orchestration contract.

// A seat run. `payload` is the trigger's data (a hook body, a message
// text, a window agenda); `resume` is an executor session id; `workDir`
// is a clone a window owns, which this run borrows and must not delete.
export async function SeatRun(input /* SeatRunInput */) { ... }

// SeatRunInput = {
//   name: string,            // [agent].name
//   manifest: Manifest,      // the parsed agent.toml, snapshotted
//   trigger: "cron" | "hook" | "message" | "window",
//   payload: { hookBody?: string, text?: string, instruction?: string },
//   resume?: string | null,  // executor session id to --resume
//   workDir?: string | null, // a window's clone; when set, no clone and no cleanup
//   keepWork?: boolean,      // a window asked for the clone to survive this run
// }
// SeatRunResult = { exit, durationMs, pr, sessionId, turns, log, workDir }

// signals
export const followUp = defineSignal/* <[SeatRunInput]> */("followUp");

// Every trigger carries a `token`, and a run has its own token in `seen`
// before that handler exists. This is not belt-and-braces. The ingress
// reaches a run with `signalWithStart`, which delivers the signal even on
// the call that STARTS the workflow, so without the token every fresh hook
// and message would execute twice: once from the input, once from its own
// signal. The smoke test found exactly that, which is the argument for
// smoke-testing against a real engine rather than a fake one.

// A work window. Holds the session id and the clone for `ttlMs`, runs a
// child SeatRun per message, and cleans the clone up on the way out.
export async function SeatWindow(input /* SeatWindowInput */) { ... }

// SeatWindowInput = { name, manifest, ttlMs, agenda?: string | null }

// signals and queries
export const message = defineSignal/* <[string]>  */("message");
export const close   = defineSignal/* <[]>        */("close");
export const refresh = defineSignal/* <[number]>  */("refresh");
export const windowState = defineQuery/* <WindowState> */("state");
// WindowState = { name, openedAt, expiresAt, session, workDir, runs, queued }
```

`SeatRun`'s body, in order, with the policies that are the point of the
exercise:

```js
const { clone, execute, record, notify, cleanup } = proxyActivities({
  startToCloseTimeout: "2 minutes",
  retry: { initialInterval: "2s", backoffCoefficient: 2,
           maximumInterval: "30s", maximumAttempts: 5 },
});
const { execute: executeOnce } = proxyActivities({
  startToCloseTimeout: runTimeout,       // EPITO_RUN_TIMEOUT_MS, from the input
  heartbeatTimeout: "5 minutes",
  retry: { maximumAttempts: 1 },         // law 5: a half-run execution is not replayed
});
```

and then a loop, because a follow-up that arrives mid-run is v0's
coalesced run and must not be dropped:

```js
let req = input;
for (;;) {
  const work = req.workDir ?? (await clone(req)).workDir;
  const r = await executeOnce({ ...req, workDir: work });
  await record({ name, trigger: req.trigger, ...r });
  await notify({ name, manifest, trigger: req.trigger, ...r });
  if (!req.workDir && !req.keepWork) await cleanup({ workDir: work });
  if (!queued.length) return { ...r, workDir: req.keepWork ? work : null };
  req = drain(queued);          // two queued messages merge, exactly as v0 did
}
```

`SeatWindow`'s body:

```js
const first = await executeChild(SeatRun, {
  workflowId: `run:${name}:window:${openedAt}`,
  args: [{ ...base, trigger: "window", payload: { instruction }, keepWork: true }],
});
let session = first.sessionId, workDir = first.workDir;

while (!closed) {
  const awake = await condition(() => queued.length > 0 || closed, msUntil(expiresAt));
  if (!awake || closed) break;                       // the clock, or the signal
  const text = drainMessages();                      // merged, never dropped
  const r = await executeChild(SeatRun, { args: [{ ...base, trigger: "message",
              payload: { text }, resume: session, workDir }] });
  if (r.sessionId) session = r.sessionId;
  if (r.exit === "workdir-gone") break;              // the clone is gone; the window is over
}
await cleanup({ workDir });
```

### The five activities

Each one is a plain `async` function in `activities.js`. Two of them are
thin wrappers over code that already exists and is already smoke-tested.

| Activity | Input | Output | Retry | Timeout |
|---|---|---|---|---|
| `clone` | `{ name, repo, ref, entry }` | `{ workDir }` | 5 attempts, 2s → 30s backoff | 2 min |
| `execute` | `{ name, manifest, trigger, payload, resume, workDir, runId }` | `{ exit, durationMs, pr, sessionId, turns, log }` | **1 attempt** | `EPITO_RUN_TIMEOUT_MS` |
| `record` | `{ name, trigger, exit, durationMs, pr, sessionId, turns, log }` | `{}` | 5 attempts | 10 s |
| `notify` | `{ name, manifest, trigger, turns, pr, durationMs, exit }` | `{ posted, reason? }` | 3 attempts | 30 s |
| `cleanup` | `{ workDir }` | `{}` | 3 attempts | 30 s |

- `clone` is `git clone --depth 1 [--branch <ref>] https://github.com/<repo>.git`
  into `mkdtemp($TMPDIR/epito-<name>-)`, then a check that `entry` exists
  inside it. A missing charter is a permanent failure
  (`ApplicationFailure.nonRetryable`), not something to retry, and the
  message is the one v0 gives: *`[runtime].entry "<e>"` does not exist in
  `<repo>`; the run refuses to improvise.*
- `execute` calls `runAgent()` from `lib/runner.js` with `workDir` set and
  `keepWork: true`, so the activity owns the clone's lifetime and the
  workflow decides when it dies. It heartbeats on every chunk of child
  output, and on activity cancellation it kills the child's process group,
  which is the `process.kill(-child.pid)` v0 already does on timeout.
- `record` appends the `run.end` line to `.epito/audit.jsonl`. It is
  idempotent on `runId`, because a retried activity must not double-write
  the record.
- `notify` calls `postToSlack()` from `lib/slack.js`.
- `cleanup` is `rm -rf` of a path that must be under `$TMPDIR` and must
  match `epito-<name>-*`. It refuses anything else, loudly.

### Schedule reconciliation

`epito run <dir>` loads the roster with the same validator `epito
validate` uses, then makes Temporal match it. The desired state is a pure
function of the roster, which is what makes this safe to run on every
restart:

```
desired = { `seat:${name}` : { cron, timezone: "UTC", action: SeatRun(manifest) }
            for every manifest with [trigger].cron }
actual  = every schedule whose id starts with "seat:"

create   : in desired, not in actual
update    : in both, and (cron, model, repo, ref, entry, max_turns, env) differ
delete   : in actual, not in desired          <- a seat that lost its cron, or left the roster
unchanged: everything else
```

Each schedule's action starts `SeatRun` on task queue `seats` with
workflow id `run:<name>`, to which Temporal appends the scheduled time.
`overlap: ScheduleOverlapPolicy.BUFFER_ONE` is v0's coalescing. Every
create, update and delete is an `audit.jsonl` line, so the reconcile is
in the product's record as well as the engine's.

`[trigger].cron` is validated by `lib/cron.js` *before* anything is
registered, so a bad expression fails the command with the validator's
own message rather than becoming a schedule Temporal refuses later.
`[trigger].on` and `[trigger].webhook = true` register no schedule: they
are served by the ingress, which is the same division of labor v0 had.

### Wire flows

```
cron fire
  Temporal Schedule seat:engineer  (0 6 * * *, UTC, BUFFER_ONE)
    -> SeatRun  id run:engineer-2026-09-27T06:00:00Z   queue seats
       -> clone    -> /tmp/epito-engineer-Xy9
       -> execute  -> claude -p ... --output-format json   (in the clone)
       -> record   -> .epito/audit.jsonl  {"action":"run.end","pr":"...","turns":37}
       -> notify   -> Slack: engineer · cron · 37 turns · 22m · https://.../pull/12
       -> cleanup  -> rm -rf /tmp/epito-engineer-Xy9

a human opens a window and speaks
  POST /window/open {"scope":"pm","ttl_ms":3600000}
    -> start SeatWindow  id window:pm
       -> child SeatRun (trigger=window, keepWork)  ->  session 4f3c..., clone held
  POST /message/pm {"text":"which PR did you open?"}
    -> signal message("which PR...") to window:pm
       -> child SeatRun (trigger=message, resume=4f3c..., workDir=the held clone)
  POST /window/close {"scope":"pm"}
    -> signal close() to window:pm  ->  cleanup the clone, workflow completes

an event wakes a seat while it is already running
  POST /hooks/okr  (body = payload)
    -> signalWithStart followUp on id run:okr
       -> the running SeatRun finishes, then loops once more with the new payload
```

### Environment

| name | default | meaning |
|---|---|---|
| `TEMPORAL_ADDRESS` | `127.0.0.1:7233` | the server's gRPC endpoint |
| `TEMPORAL_NAMESPACE` | `default` | the namespace; the company host sets `asc` |
| `EPITO_TASK_QUEUE` | `seats` | the queue the worker polls and the schedules target |
| `EPITO_RUN_TIMEOUT_MS` | `3600000` | per-run cap: the `execute` timeout and the workflow run timeout |
| `EPITO_WINDOW_MS` | `14400000` | default window TTL |
| `EPITO_HOOK_SECRET`, `EPITO_PORT` | — , `4747` | the ingress, unchanged |
| `CLAUDE_CODE_OAUTH_TOKEN`, `GH_TOKEN`, `SLACK_WEBHOOK_URL` | — | held by the worker, injected per run only when the manifest names them |

`TEMPORAL_NAMESPACE` defaults to `default` so a laptop and a dev server
work with no configuration. The company host sets `asc` in `/srv/asc/env`.
Both `epito run` and `epito worker` log the address and namespace they
connected to on the first line, so a misconfigured host is visible
immediately rather than after a silent day of writing to the wrong
namespace.

### Testing strategy

- **Unit, no server.** The reconcile diff is a pure function of
  (desired roster, actual schedule list), so `reconcilePlan()` is tested
  as a table: a new cron, a changed cron, a changed model, a cron
  removed, a seat removed, nothing changed. Validator additions get
  golden error strings, asserted verbatim, as every other error string in
  this repo is.
- **Smoke, against a real engine.** `cli/test/smoke-temporal.sh` starts
  `temporal server start-dev --headless` in its own SQLite file on its own
  port, runs the real worker and the real ingress with
  `EPITO_EXECUTOR=test/stub-executor.mjs` and
  `url.<local>.insteadOf https://github.com/`, and proves the three things
  the directive names: **a schedule fires a run** (on the real clock, not
  by a hand trigger), **a window holds a session and a message resumes it
  in the same clone**, and **`epito ps` reads Temporal**. It also covers
  what v0 had and must not lose: reconcile idempotence in both directions,
  per-agent Slack routing to two separate sinks, a seat with no charter
  refusing loudly and leaving no clone behind, and the four ingress
  refusals. 59 assertions, no tokens spent, no network touched. If the
  `temporal` CLI is absent it exits 0 after printing the reason and the
  one-line install command — an unrun test rather than a failing one, said
  in those words so nobody reads the skip as a pass.
- **Audit assertions match by JSON predicate, not by substring**
  (`cli/test/audit-has.mjs`). A substring match against a serialized object
  is really an assertion about key order, and key order is not a promise
  this runtime makes. Three of the first assertions written here were
  passing or failing for that reason rather than for a real one.
- **Not yet done, and named:** workflow replay tests against recorded
  histories, which are the regression suite that makes changing
  `workflows.js` safe. `@temporalio/testing`'s replayer is the tool.
  Wiring both of these into GitHub Actions needs a change to
  `.github/workflows/`, which the engineer charter forbids this seat from
  touching, so it is a handoff, not an omission.

### Threat model, the deltas

The v0 table in docs/architecture.md stands. Three rows are new:

- **Temporal's database now holds workflow inputs in plain text.** So no
  secret value may ever be a workflow or activity argument (law 7). The
  manifest is publishable by design, which is exactly why it is the thing
  we put in the schedule's payload.
- **The gRPC endpoint is unauthenticated.** Self-hosted Temporal with no
  mTLS accepts anything that can reach `7233`. It is bound to loopback
  and the host's `ufw` allows only 22 and 443, so reaching it means
  already being on the box. Documented rather than solved: mTLS between
  the worker and the server is the right fix when a second host exists.
- **The UI on `127.0.0.1:8080` shows history, which shows prompts.**
  Reach it over an SSH tunnel, never publish it. The install script binds
  it to loopback for this reason.

### For whoever picks this up next

The central problem is this: **an agent run is a long, stateful, failure-prone
unit of work that must outlive every process involved in starting it.**
Everything in `cli/src/temporal/` exists to make that sentence true, and
nothing in it should exist for any other reason.

The design test for any change here: *if the host reboots at the worst
possible moment, can an owner still find out what her agent was doing,
and does the system reach a sane state without a human?* If the answer
needs a log file, the change is wrong. If the answer needs a person to
delete a stale lock, a temp directory, or a row, the change is wrong.

The second test, equally load-bearing: *does this change add a Temporal
word to something an owner reads?* If so, move it behind the face.
