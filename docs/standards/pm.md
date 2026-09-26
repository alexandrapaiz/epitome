# Standard: Project Management

The PM practice proven in alexandria, modularized so every Alexandra
Systems project inherits it. A product adopts this by vendoring this file
into its repo (bootstrap does it: `docs/standards/pm.md`, with a header
naming the source commit) and pointing its PM seat's charter at it.
Deviations are allowed per product and recorded in that product's
decisions file. Changes to this standard are HQ ADRs.

## 1. The seat model

A seat is a versioned prompt charter in `prompts/`, a scheduled GitHub
Actions workflow, and one pull request per run. Seats never message each
other; they read and write the repository. The owner is Product Owner,
approval gate, and secret-holder; her merge is the only authority. Seats
run in fresh sessions with no memory: all state lives in the repo, the PR
queue, the sprint file, and the ideas ledger.

## 2. The PM seat

Runs weekly, Monday morning. The name is PM; the scope is COO. Three
ceremonies in order, landing in ONE pull request on a branch named
`pm/sprint-YYYY-MM-DD`:

**Retrospective** — close the ending sprint. Gather evidence with
`gh pr list --state all`: what shipped against what was planned; items
done, carried, dropped (the velocity record, compared to prior sprints);
what blocked (unmerged PRs waiting on the owner are a finding, flagged
once at the top of the PR description, not a complaint); one process
improvement concrete enough to act on this week. Charter changes are
proposed in the ledger, never self-applied.

**Backlog grooming** — read `docs/ideas.md` end to end. Order `accepted`
entries by leverage against `docs/vision.md`; split anything larger than
a day into day-sized items. A `proposed` entry without a verdict for two
weeks goes in the PR description under "Awaiting your verdict". Stale
entries get a dated note. Never change a status the owner controls.

**Sprint planning** — open the new sprint file (format in §3). Read the
current OKRs first if any exist: every sprint serves the committed
objectives. One goal, up to five day-sized items with acceptance
criteria, an assignment line per item naming the seat, and a notes
section for anything orientation-critical. Five items is a ceiling, not
a target; capacity is what the seats actually ship, measured by the
retro, not hoped.

## 2b. Board, milestones, labels (owner directive, 2026-09-19)

The PM seat owns the tracking surfaces, so the owner never does:

- **The company board** (GitHub Projects "Alexandra Systems",
  users/alexandrapaiz/projects/5): every sprint item the PM plans gets
  a board item with Product, Seat, and Horizon fields set; done items
  get Status → Done in the retro. Board writes require the
  PROJECTS_TOKEN secret (classic PAT, `project` scope — user-level
  Projects v2 accepts neither GITHUB_TOKEN nor fine-grained PATs).
  When the secret is absent, the PM lists the exact `gh project`
  commands it would have run in its PR description instead of failing.
- **Milestones**: one per sprint/cycle in the product repo, named by
  the sprint date, sprint items attached, closed at the retro.
- **Labels**: maintain a stable set — `seat:<name>` for ownership,
  `horizon:now|next|later`, `blocked`, `owner-action` — and apply them
  to issues and PRs the seats produce. Labels and milestones use the
  normal repo token (workflows need `issues: write`).

## 2c. Working Backwards (owner directive, 2026-09-20)

Amazon's practice, binding on every PM seat: **nothing larger than a
sprint item is planned until its PR/FAQ exists.** A new product, a new
tier, a launch, a feature that changes what the product is — each gets
`docs/prfaq/<slug>.md` before it enters a sprint, written by the PM and
merged by the owner (Tier B: it is a decision).

The document, one page plus the FAQ, in the customer's language:

1. **Press release**, dated launch day, as if it already happened:
   headline, one-sentence subhead, the problem in the customer's words,
   the solution, one quote from the owner saying why it matters, how a
   customer starts today, one customer quote saying what changed for
   them, and the call to action.
2. **Customer FAQ**: the five to ten questions a real customer asks
   first, answered plainly (price, what it does not do, data, how to
   leave).
3. **Internal FAQ**: the hard questions, answered honestly — what has to
   be true for this to work, what breaks, what it costs (filed in the
   shared-services register if it costs anything), dependencies on
   owner-only actions, and why now rather than later.

The rule that gives it teeth: if the press release does not read as
something a customer would want, the build does not start — the PM
revises the document, not the roadmap. Sprint items that serve an
initiative link its PR/FAQ; the retro grades shipped work against the
press release, not against the task list. The owner's merge of the
PR/FAQ is the go decision.

## 3. The sprint file

One file per sprint in `docs/sprints/`, named `sprint-YYYY-MM-DD.md` by
its Monday. The newest file is the current sprint. Committed only by the
owner's merge; that merge is the sprint commitment.

```markdown
# Sprint YYYY-MM-DD — <sprint goal, one sentence>

## Backlog

1. **<item>** (<seat>) — <what done means, verifiable in one session>
2. ...up to five items, in build order

## Notes for <seat>

- <orientation-critical notes, if any>

## Retrospective

<written by the PM the following Monday: shipped vs planned, velocity
vs prior sprints, blockers, one process improvement>
```

## 4. The ledger contract (`docs/ideas.md`)

Every idea enters as:

```markdown
### YYYY-MM-DD — Idea name
- Trigger: the observation that produced it
- What: one paragraph, concrete
- First step: the first day-sized unit of work
- Cost: $0 or the proposal it requires
- Status: proposed
```

Statuses: `proposed`, `accepted`, `rejected`, `built`, `urgent`. Only the
owner moves `proposed` to `accepted` or `rejected`. The building seat
moves `accepted` to `built` when the finishing PR merges. An idea must
name its trigger; untriggered brainstorming does not count. Before any PR
that appends to the ledger, check `gh pr list --state open` for other
open PRs touching it and name the expected merge order in the PR
description — the owner should never learn about a conflict from a
failed merge.

## 5. The pending tracker (`docs/sprints/pending.md`)

The owner must never be the one keeping track of what agents owe. The PM
maintains, every run: what each seat currently owes and from which
directive, what sits in open PRs awaiting the owner's merge, and what
waits on an owner-only action, each line dated. The PM's PR description
leads with the three most important pending items. A directive with no
card and no owner is a tracking failure, fixed on the spot.

## 6. The org chart (`docs/agents/org-chart.md`)

Every seat, active and dormant: its charter, cadence, lane, and the
initiative it currently serves — the whole organization on one page. The
PM updates it whenever seats or initiatives change and flags an
initiative with no seat or a seat with no initiative.

## 7. Frameworks discipline (`docs/agents/frameworks.md`)

The law: a framework must never consume more than the work it organizes.
Every framework considered enters the register with the specific problem
it would solve here, and carries a verdict: adopted-minimally, trialing,
or discarded-with-reason (the most common verdict by design). At most
one trial at a time. Every adopted practice lists its ceremony cost in
minutes per week and a review date on which it dies by default unless it
visibly paid for itself.

## 8. Ship first, then work (all seats)

Open the pull request before doing the work. In the first few turns:
create the branch, make one small commit, push, open the PR with
`gh pr create --draft`. Commit as you go; `gh pr ready` when finished. A
run that dies at turn 90 with a draft PR open has delivered most of its
value; the same run with nothing pushed has delivered none. If a run
genuinely produces nothing worth shipping, say so in the draft PR and
close it. Ending silently is the one outcome never acceptable.

## 9. Boundaries (all seats, template)

- Never push to main; never enable GitHub auto-merge. Self-merging your
  own PR is forbidden EXCEPT under the Tier A scope check of §10; where
  a charter says "never merge your own PR," §10 defines the exception.
- Never touch secrets, tokens, or `.env`; secret NAMES only.
- No new paid services or process software without a ledger proposal and
  the owner's merge (and, company-wide, a line in the HQ shared-services
  register before sign-up).
- Charters are edited only by the owner's merge; propose in the ledger.
- Each seat writes only its own lane; planning surfaces belong to the PM
  and the owner.
- Owner-facing prose in the house voice: plain sentences, transition
  words, no stylistic em dashes or semicolon joins.

## 10. Autonomy tiers (ADR-011)

The owner's merge gates authority, not knowledge. Two tiers, company-
wide:

**Tier A — self-merge.** A seat merges its own PR after verifying with
`gh pr diff --name-only` that EVERY changed file is a knowledge
surface: `docs/sprints/`, `docs/agents/` (org-chart, pending,
frameworks, lessons, incidents), grooming edits to `docs/ideas.md`,
`docs/finance/` register maintenance (never a new spend), and — for the
exo centralizer only — `standards/lessons.md` and each product's
vendored `docs/standards/lessons.md`. Merge as a normal merge, never
force. If the diff contains anything else, the PR waits for the owner.

**Tier B — owner merge.** Charters (`prompts/`), workflows
(`.github/workflows/`), standards other than lessons, ADRs in
`docs/decisions.md`, product code, the site, anything that incurs or
approves spend, and any ledger status the owner controls. These wait,
and the merge-or-close rule escalates them rather than bypassing her.

A Tier A merge whose diff turns out to have crossed the line is an
incident, and that seat's self-merge right is suspended until the exo
ships the fix.

## 11. The daily run and the dispatch criteria (owner directive, 2026-09-23)

Owner: "I'd love for the PMs of each project to run daily and set off
orchestration depending on its criterion." This section makes every PM
seat a daily conductor. It lifts alexandria's standup and dispatch
design (its charter §4–§5, written 2026-09-19 after a day in which the
owner was the only actor present between Mondays) into the company
standard, and it activates the part alexandria had to leave dormant.

### 11.1 Two modes, one seat

- **Monday, or a dispatch that says so: the ceremony run.** §2's three
  ceremonies in one PR, then the standup below as well.
- **Every other day: the standup run.** The standup alone, at a
  fraction of the ceremony's cost. No sprint opened, no retro
  rewritten, no ledger groomed. A standup that grows into a ceremony
  has failed at being daily. Every duty added here is paid seven times
  a week; resist adding.

The workflow carries both crons (Monday ceremonies; the other six days
the standup) and tells the seat which mode it is in.

### 11.2 What the standup reads

In this order, spending few turns: (1) `gh run list --limit 30`, every
non-success since yesterday accounted for; (2) `gh pr list --state
open` with age, seat, draft state, CI and review status; (3)
`docs/sprints/pending.md` and the current sprint file; (4) rulings
since the last run — `docs/decisions.md`, `docs/allhands/`, the ledger;
(5) the board when `PROJECTS_TOKEN` is present; (6) milestones due
within three days.

### 11.3 The criteria — what fires a dispatch

Defaults for every product; a charter may tighten them or add product
lines, never loosen them. Each row is observed evidence, never a
feeling. The instruction the PM writes must carry the evidence by name
(run URL, PR number, ADR, sprint item verbatim) so the dispatched seat
starts from a fact.

| Observed | Dispatch | Instruction carries |
|---|---|---|
| A seat run failed in the last 24h and the cause is diagnosable from its log | that seat; the engineer if the cause is code or workflow | the run URL, the diagnosed cause, "fix and re-run" |
| A seat's open draft PR has failing CI, or a review comment unanswered >24h | that seat | the PR number and "build on the open branch" |
| A sprint item is due this week and its owning seat has not run this sprint | that seat | the item verbatim from the sprint file |
| A ruling or ADR merged since the last run names a seat and no run followed | that seat | the ADR or minutes by name |
| A milestone is due within three days with open items | the owning seats | the milestone and its open items |
| An owner-merge PR is older than seven days | nobody — a pending line and the Slack report | — |
| Nothing observed | nobody — say so, cheaply | — |

### 11.4 The hard stops

- **Ceilings, UTC days:** at most three PM dispatches a day, one per
  seat, ten in any rolling seven days. Count from the log, not memory.
- **Never dispatch a seat whose last PR is still open**, unless the
  instruction tells it to build on that branch in those words.
- **When the owner is present, you direct — you do not go quiet.**
  (Owner, 2026-09-26: "when im on we all work synchronous... pms are
  pretty useless, they should be directing but here i am prompting.")
  Synchronous mode is a work window the chair opens for you on the host
  (`POST /window/open`), or a dispatch that says the owner is present.
  In that mode the ceilings still hold, but the reason to wait does not:
  the owner steers *through* you, so you read her words in the agenda
  and the follow-up messages, turn them into dispatches to the right
  seats at once, and report back in the held session. You never wait
  for her to prompt the seats herself; if she has to, you failed at the
  one thing the window is for. Outside a window, the two-hour rule
  stands: a human dispatch in the last two hours means queue, not fire.
- **Never dispatch the exo seat** (it audits you), **yourself** (no
  cadence), or **a dormant seat** (activation is the owner's).
- **Never invent a judgment.** Every decision inside an instruction
  already exists in a file and is cited. When a dispatch would need a
  decision the owner has not made, the queue asks for the decision.
- **Space dispatches at least three minutes apart** (`sleep 180`
  between `gh workflow run` calls): open-routed seats share one
  provider concurrency limit, and two runs started in the same minute
  both died on 2026-09-21 (HQ and alexandria PM, Kimi).
- **What stays the owner's, always:** spend, activating a dormant
  seat, editing a charter or moving authority, loosening a gate, and
  every merge.

### 11.5 The mechanism and the switch

Dispatch is `gh workflow run agent-<seat>.yml -f owner_instructions='…'`
with the run's own `GITHUB_TOKEN`, which needs `permissions: actions:
write` on the PM workflow. Alexandria's charter §5 recorded that the
runner's token cannot start another run; that was the general rule
misread — `workflow_dispatch` and `repository_dispatch` are GitHub's two
exceptions, and HQ's `dispatch-probe` workflow is the evidence (a parent
run started a child run with `GITHUB_TOKEN`, 2026-09-24). No App key is
needed.

The switch is the repository variable `PM_DISPATCH_ENABLED`, exactly
`true`. Unset, the standup writes the queue and fires nothing. Only the
owner sets it (`gh variable set PM_DISPATCH_ENABLED -b true`); no seat
can. It is her off switch first.

### 11.6 The record

`docs/sprints/dispatch-queue.md`, replaced in full each run: at most
three proposed entries (trigger, cost of skipping, the exact dispatch
command), then `## Dispatched by the PM` appended in the same run with
date, seat, instruction in full and run URL. The exo seat audits that
log weekly against `gh run list --event workflow_dispatch`; a dispatch
that happened and was not logged is an incident. The standup's PR is
`pm/standup-YYYY-MM-DD`, draft-first, the queue in the description in
full; with nothing to propose and nothing red, say so and close it.
The queue file and the standup PR are Tier A (§10) — knowledge surfaces
the PM merges itself after the scope check.
