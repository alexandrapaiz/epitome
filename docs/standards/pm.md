<!-- vendored-from: standards/pm.md @ becae2c223a1a828e4a26ed02c01cb5df67b05db -->
> **Vendored copy — do not edit here.** Source of truth is
> `alexandrapaiz/alexandra-systems` `standards/pm.md` at commit `becae2c`,
> vendored 2026-11-08. Changes to a company standard are HQ
> ADRs (standards/README.md). Deviations for this product belong in this
> repo's own decisions file, not in this copy.
<!-- end vendored header -->

# Standard: Project Management

The PM practice proven in alexandria, modularized so every Alexandra
Systems project inherits it. A product adopts this by vendoring this file
into its repo (bootstrap does it: `docs/standards/pm.md`, with a header
naming the source commit) and pointing its PM seat's charter at it.
Deviations are allowed per product and recorded in that product's
decisions file. Changes to this standard are HQ ADRs.

## 1. The seat model

A seat is a versioned prompt charter in `prompts/`, a schedule that wakes
it, and one pull request per run. Seats talk to each other through the
board and nowhere else: the inbox is an authority surface, and §15 is the
protocol. The owner is Product Owner, approval gate, and secret-holder;
her merge is the only authority. Seats run in fresh sessions with no
memory: all state lives in the repo, the PR queue, the board, the sprint
file, and the ideas ledger.

Until 2026-09-30 this paragraph read "Seats never message each other;
they read and write the repository," and §14 and §15 then made the board
a channel without amending it. On 2026-10-05 the event bus woke two PM
seats and both declined their messages, one of them citing this sentence
from its vendored copy. A standard that contradicts itself is read at the
paragraph a seat reaches first, so the contradiction is removed here
rather than answered in a later section.

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

**Sprints are deployment milestones, not dates (owner directive, 2026-09-30: "we want sprints to be about goals … it's about having deployment milestones … my mind needs some sort of meaning or goal").** Every sprint carries a name a person understands and a one-sentence goal that says what ships: "Every seat run visible on the Runs tab", "The console's Runs and Agents tabs live". The dates stay underneath for the machines. A sprint closes when its goal ships, which may be days before its end date, and the next milestone opens the same day; a sprint that reaches its end date with its goal unmet is closed with a written reason and the goal carried, not silently extended. Names are the PM's to invent, per company, and the owner wants them creative and memorable (2026-09-30: "I want the PM to be creative in naming and defining sprints, for each subcompany and company"): a name that says what the milestone is in this company's own voice, never a date and never a number. The PM sets the name and the goal on the board (`POST /api/sprints/<id> {"company": …, "name": …, "goal": …}`, or the owner clicks the goal on the page) in the Monday ceremony, and the standup reports progress against the goal in one sentence, never as a date.

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
`gh pr create --draft`. Commit as you go, and **`gh pr ready` at the
first moment the branch would be worth merging as it stands, not when
you are finished** — a readied pull request takes further commits
exactly as a draft does, so readying early forfeits nothing, while a run
here dies at a turn cap or a timeout it did not choose and cannot see
coming, so "when finished" names a moment many runs never reach
(L-A32's amended clause, and L-A97 for the whole class of duties this
applies to). A run that dies at turn 90 with a readied PR open has
delivered its work to the one gate that can release it; the same run
with a draft has delivered a branch nobody can merge, because GitHub
refuses to merge a draft at all; with nothing pushed it has delivered
none. If a run genuinely produces nothing worth shipping, say so in the
draft PR and close it. Ending silently is the one outcome never
acceptable.

**Readying is a handover, so check what you push after it.** The median
from ready to merge on an HQ branch has been measured at ten minutes,
and a run that keeps writing without looking can lose those commits to
a pull request that closed under it — that is how `#391` lost a
growth-ledger row and three ledger entries on 2026-10-24. The rule is
not "ready late", it is "after readying, confirm the pull request is
still open before you assume a commit was delivered, and carry what
missed it on a new one" (L-A97's fourth clause).

**And survey before you build.** Ship-first is about the artifact being
reachable at every moment of the run, not about its end; this is about
its first minute. Before writing code, run `gh pr list --state
open` and a closed-PR search for the thing you are about to build in
words, then read the hits whose scope overlaps yours. Every run starts
from `main` with no memory, and `main` is the one place where work that
is built but unmerged is invisible, so an open backlog card tells you
the work has not landed and tells you nothing about whether it was
done. Where an overlapping PR exists, take one of three moves in the
open: extend that branch, propose closing it with a reason, or land the
stack. Writing another implementation is never one of the three. Put
the survey in the PR description as named numbers, including "nothing
found" with the two searches that found nothing. (Lessons register
L-E10: `epito token` was built six times in five attempts in epitome
cycle 1 bet 2 and merged zero times, because six runs each read the
same open card and none could see the other five.)

**The deadline, counted for the first time, and the order it has with the
preflight (alexandria's exo, 2026-10-26).** "In the first few turns" was
quoted by every seat in the org for five weeks and had never been measured.
Read as six turns it is met by **9 runs of 1,765** across the five companies,
which is half of one percent; the median first push in the portfolio is **turn
25** and the ninetieth percentile is turn 50; and **no seat in any company has
a median inside it**, the nearest being Ursa's research seat at turn 8 and the
furthest HQ's own PM seat at turn 55. The rule's mechanism is not in doubt and
is not weakened here: of the runs killed non-zero after completing at least
one turn, **161 of 195 had already pushed** and 34 lost everything, so 83% of
the class this clause exists for was saved by it. What was wrong was only the
number, and the reason no run met it is not laziness. **The preflight the same
charters mandate has to happen before the branch can exist** — read the
charter, run the mode test, look for your own open pull request, check whether
the branch name has been used, unshallow the clone and widen its refspec, then
decide whether to supersede or branch fresh — and that is four to eight turns
on a good day. The deadline and the preflight live in the same files and had
never been read against each other.

So this section settles the order rather than asking a seat to fit both inside
six turns. **The draft comes first and the preflight comes after it.** Branch
from `main`, one small commit, push, `gh pr create --draft`: none of those four
acts needs anything read first, and a seat that does them before its charter
is a seat whose work survives its own kill. Then run §8's survey and the rest
of the preflight on the open draft, and where the survey turns up an
overlapping branch the three moves are exactly as above — extend it, propose
closing it, or land the stack — taken from a pull request that already exists
instead of from nothing. The cost of that order is one extra merge on the runs
where the survey turns something up, and the benefit is every cut run in the
83%. **The deadline is turn ten**, which the record says about a tenth of runs
meet today and a third meet by turn twenty, so it is a number a seat can hit
and an instrument can read rather than one nothing has ever satisfied. It is
counted, not asserted: `tools/ship_first.py` in alexandria's repository joins
HQ's audit log to the session transcripts the host already keeps, needs no
credential and no network, separates a run that lost work from one that was
refused before it could have any, and runs unchanged against the whole
portfolio from any company.

**And the rule that outlives this number: a deadline in a binding clause is
counted, or it is an aspiration teaching every other clause to be read as
one.** The cost of this one was not the misses. It was that five weeks of
seats learned to read a standard's clauses as things the company admires,
because the one clause they could all quote was satisfied by 0.5% of runs and
nothing had ever looked. The seat that paid for the measurement paid in the
only currency that counts here: its own previous run was cut at turn 20 with
nothing pushed, 13 of those 20 turns spent reading a charter that has grown to
240 kilobytes and no longer fits in one read of the tool that reads it, and it
died one turn before it would have created its branch.

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

**What each clause of the run-level instruction binds to, because reading it
harder does not settle it (Ursa's PM, 2026-10-26).** Every seat in the
portfolio is handed the same three clauses at the top of its wake — *never
merge your own PR, never push to main, never touch secrets or workflows* —
and the second one has no possessive. Read narrowly it forbids a raw
unreviewed push and leaves §21 intact; read broadly it forbids this seat from
merging anything at all, since a merge is how a pull request reaches `main`.
Ursa's own PM seat argued both sides **nine times in one day on one branch**
and flipped once, each pass finding the last pass insufficiently settled,
while in the same hours **three sibling PM seats — epitome, alexandra-systems
and alexandria — each merged another seat's pull request under the identical
instruction** without noticing a conflict. That is not nine failures of
reading. It is one missing sentence, and nine more re-derivations in nine more
companies would not produce it. So, clause by clause:

- **"Never merge your own PR"** binds to the pull request you opened, and §10
  Tier A is its exception: where every changed file is a knowledge surface,
  the seat merges its own, and `tools/check-tier.sh <pr>` answers that per
  pull request rather than by eyeballing §10.
- **"Never push to main"** binds to the **ref**, not to the merge button. It
  means no commit reaches `main` except through a merged pull request, and
  auto-merge stays off. It does **not** withdraw §21, which grants the PM seat
  of a company and any chair the merge of another seat's pull request; a merge
  performed under §21 is the way this clause expects `main` to move, not a
  violation of it. The possessive in the first clause does not travel to the
  second.
- **"Never touch secrets or workflows"** is two rules with different hands.
  Secret **values** never, in any surface, and secret **names** freely
  (L-X5). Workflow **files** belong to HQ: a product seat does not edit
  `.github/workflows` in its own repo and hands the fix up (§15), and GitHub
  refuses an App installation token that path whatever the `permissions:`
  block says (Incident 5). Where a run's own wake prompt carries the clause
  flat, the prompt wins over the charter silently (L-X10), so that run routes
  the workflow fix to a hand whose instruction does not forbid it and says on
  the board that it did — it does not apply it quietly and it does not drop
  it.

**And the clause is only in force where it is said.** This is the §10 Tier A
failure one rule over: HQ's PM opened two pull requests that
`tools/check-tier.sh` called its own to merge and declined both "per this
run's own launch instructions", and one of them was closed unmerged as an
orphan, because the authorised merger and the instructed merger were different
actors and nobody involved was wrong. The instrument for the whole class is
`tools/check-wake-prompts.py`, which enumerates every surface that composes a
wake and fails on one that states a rule without the exception the standard
attaches; a new rule with an exception costs one row there rather than an edit
in thirty-nine charters. It carried the same cost again on 2026-10-26, in the
other direction: Ursa's security seat measured that its redaction gate's grep
skips every binary file and handed the one-flag fix to HQ because workflows
are HQ's, and the HQ seat that received it is instructed "never touch
workflows", so the hand that holds the authority and the hand that was given
the work were again different actors.

## 10. Autonomy tiers (ADR-011)

**Amended by section 21 (owner, 2026-10-05).** The PM seat merges every tier in its own company and a chair merges in any company; the tiers below still say what must be true before a merge (green, scoped, reported), but no tier waits for the owner any more except a change to a seat's own authority.

The owner's merge gates authority, not knowledge. Three tiers, company-
wide:

**Tier A — self-merge.** A seat merges its own PR after verifying with
`gh pr diff --name-only` that EVERY changed file is a knowledge
surface: `docs/sprints/`, `docs/agents/` (org-chart, pending,
frameworks, lessons, incidents), grooming edits to `docs/ideas.md`,
`docs/finance/` register maintenance (never a new spend), and — for the
exo centralizer only — `standards/lessons.md` and each product's
vendored `docs/standards/lessons.md`. Merge as a normal merge, never
force. If the diff contains anything else, the PR waits for the owner.

**Tier B — PM merge (owner directive, 2026-09-30: "I want them to be in
charge of merges").** Everything that is not Tier A and not Tier C: product
code, the site, docs beyond the knowledge surfaces, sprint and standup
files, workflows and standards that HQ syncs into a product repo, and any
seat's PR in the PM's own company. The PM merges it in the daily run when
all of these hold, and records each merge in the standup PR:

1. It is not the PM's own PR (a PM's own Tier B PR waits for another
   merger: the owner, or HQ's PM for a product PM).
2. Not a draft, no `hold` label, and no owner comment since the last push.
3. Checks green, or no checks defined. A red check is a failed run (§11.7),
   never a merge.
4. `gh pr diff --name-only` shows no Tier C path.
5. It merges clean. A conflict is not the PM's to resolve in code: it
   messages the owning seat (`handoff`, board §15) to rebase and, if the
   criteria fire, dispatches it. Docs-only conflicts the PM may resolve.
6. It is under seven days old, or it has moved in the last seven days. Older
   and idle: close it with a one-line note naming what would reopen it.

Normal merge, never force, never squash a stack out of order: merge the
base of a stack first. A PR that targets another PR's branch is merged
into that branch, not into main.

**Tier C — owner merge.** Charters (`prompts/`), this section and any
change to the tiers or the dispatch stops, `company.yaml`'s roster and
secret names, anything that incurs or approves spend, anything that
touches secrets or deletes data, and any PR the owner has labelled `hold`
or commented on. These wait, and the merge-or-close rule escalates them
rather than bypassing her.

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

In this order, spending few turns: (1) `tools/gh-actions.sh run list
--limit 30`, every non-success since yesterday accounted for (the
wrapper, not bare `gh`, for the reason in §11.5); (2) `gh pr list --state
open` with age, seat, draft state, CI and review status, and
`tools/check-merge-queue.sh` for the merge state, which GitHub's cached
`mergeable` field may not have recomputed: a PR that conflicts waits on
the seat that wrote it, not on the owner, and filing it as "awaiting her
merge" sends the queue to the one person who cannot clear it; (3)
`docs/sprints/pending.md` and the current sprint file; (4) rulings
since the last run — `docs/decisions.md`, `docs/allhands/`, the ledger;
(5) the board, per §14, whenever `BOARD_API_URL` and
`BOARD_RUNTIME_TOKEN` are in the environment (this used to read
"`PROJECTS_TOKEN`", from the period before §14, when the board was
GitHub Projects); (6) milestones due within three days.

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
| A sprint item is due this week and its owning seat has not run this sprint | that seat | the item verbatim from the sprint file **and the PR survey for it** (§11.3a) |
| A seat has two or more open PRs on one scope, none merged | that seat | the PR numbers and "land or close this stack; build nothing new" |
| A ruling or ADR merged since the last run names a seat and no run followed | that seat | the ADR or minutes by name |
| A milestone is due within three days with open items | the owning seats | the milestone and its open items |
| An owner-merge PR is older than seven days | nobody — a pending line and the Slack report | — |
| Nothing observed | nobody — say so, cheaply | — |

### 11.3a A card is not evidence — the PR survey (2026-09-30)

Every row above whose evidence is a card, a sprint item or a hill is
checked against the pull requests before it fires. Run `gh pr list
--state open` and a closed-PR search for the item in words, and put what
you find in the instruction: the numbers, whether they merged, and which
of extend, close or land you are asking for. A dispatch that cites only
a card commissions work the repository may already contain, because the
card records landing and not doing.

This is not hypothetical arithmetic. In epitome cycle 1 bet 2 the same
card fired five attempts that produced six pull requests for `epito
token` — #9, #10, #14, #15, #20, #23 — and not one of them merged. The
standup's own reading order already puts `gh pr list --state open`
second (§11.2); what was missing was the rule that the dispatch must
*carry* it. A hill drawn from cards rather than from open PRs reports
progress on work that was built and lost, which is worse than reporting
no progress, because it hides the loss.

### 11.4 The hard stops

- **Ceilings, UTC days:** at most three PM dispatches a day, one per
  seat, ten in any rolling seven days. Count from the log, not memory.
- **Never dispatch a seat whose last PR is still open**, unless the
  instruction tells it to build on that branch in those words. Read
  *every* open PR by that seat, not only its most recent: the epitome
  duplicate-build ran six times behind a six-deep stack, and each run
  individually satisfied a rule written about one PR.
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

Dispatch is `gh workflow run agent-<seat>.yml -f owner_instructions='…'`,
and it needs two halves that only work together. The first is the grant:
`permissions: actions: write` on the PM workflow. The second is the
credential, and this is the half that was wrong in prose for four days.
A seat does not run on the token its workflow declares. The Claude Code
action exchanges the run's OIDC token for a Claude GitHub App
installation token and overwrites both `GH_TOKEN` and `GITHUB_TOKEN`
with it, and that token's scopes come from the action's own defaults
(contents, pull requests, issues) rather than from the `permissions:`
block. So every Actions call a seat makes with the ambient `gh`
answers `403: Resource not accessible by integration` no matter what the
workflow grants. The job's own `${{ github.token }}` is still present,
under the name `DEFAULT_WORKFLOW_TOKEN`, and that is the one the
`permissions:` block governs. Therefore:

```bash
tools/gh-actions.sh workflow run agent-<seat>.yml -f owner_instructions='…'
tools/gh-actions.sh run list --limit 30            # §11.2 step 1
```

`tools/gh-actions.sh` is `gh` with the arguments passed straight through
and the credential chosen for you, so no run has to remember the name of
an environment variable a third-party action sets.
`tools/check-actions-reach.sh` reports, per token, which of the two
halves is missing here, and it is the first thing to run when an Actions
call fails. Never conclude from a 403 that the owner must widen a grant
in the GitHub UI: no UI grant changes what the ambient `gh` can do.

Alexandria's charter §5 recorded that the runner's token cannot start
another run; that was the general rule misread —
`workflow_dispatch` and `repository_dispatch` are GitHub's two
exceptions, and HQ's `dispatch-probe` workflow is the evidence (a parent
run started a child run with `${{ github.token }}` in a bare shell step,
2026-09-24). That probe is also the only side-effect-free way to prove
`actions: write`, because the sole thing write grants is starting a run.
No App key is needed.

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

### 11.7 Failed runs are the PM's to triage (owner directive, 2026-09-30)

The owner: "review which new agent processes fail … and rerunning failed
workflows." Every standup, before the dispatch criteria:

0. **Separate the runs the company never got from the runs that went wrong,
   first, because they are triaged by different actors.** Three classes look
   identical in every field the run record has — all of them a non-zero exit —
   and two of the three are not about the branch they name:
   - *Refused* — the model provider declined the wake (a session or usage
     limit, a 429). Nothing for the seat to triage: it is capacity, it belongs
     on the capacity line of the daily brief (`GET /api/capacity`,
     `asc capacity`), and it is never counted as a pass against any seat (§18).
   - *Never started* — no runner took the job, so there is no log to read and
     `--log-failed` answers "log not found".
     `python3 tools/check-run-ran.py --branch <branch>` answers it in one
     call; the reason is in the job annotation, not in the log
     (`gh api repos/{owner}/{repo}/check-runs/<job>/annotations`).
   - *Ran and failed* — the only class the list below is about.
   State the three counts before triaging anything, and make the look-back at
   least as long as the interval between triages: a 24-hour look-back read by a
   seat whose own cadence is weekly cannot see its own escalation condition.
   *Sources: epitome/exo 2026-10-18 (nine runs failed before their first step,
   so the procedure read nothing and the manager honestly reported nothing);
   this seat, same day (274 host runs, 67 refused, recorded in the same field
   with the same value as a seat whose work went wrong).*

1. **List** the company's failed runs of the last 24 hours. **The host's own
   run record first**, because since decision 054 the host daemon runs the
   clock and the last `agent-<seat>.yml` run anywhere in the portfolio was
   epitome's at 2026-10-18T19:47Z — a seat run no longer appears in Actions at
   all, so a run list there answers "nothing failed" because nothing ran:

   ```sh
   asc turns --days 1 --company <yours>         # the seats and their caps
   jq -c 'select(.action=="run.end" and .exit!=0)' /srv/asc/state/.epito/audit.jsonl | tail -40
   ```

   `/srv/asc/state/.epito/audit.jsonl` is one JSON line per run event since
   2026-09-24 with `turns`, `exit`, `model`, `durationMs`, `trigger`,
   `session` and `pr` on every `run.end`, and it needs no credential. Then
   `gh run list --status failure --created ">=$(date -u -d '-24 hours' +%FT%TZ)" --json databaseId,workflowName,url,createdAt`
   for the Actions side, which still holds a pull request's checks and a seat
   run from before 2026-10-18. **Name which source answered** — the two are
   partial in different directions and a count with no scope is not a count
   (L-A47).
2. **Read** each one: `gh run view <id> --log-failed` where the run is in
   Actions, and the seat's own log on the host (`/srv/asc/state/.epito/`,
   beside the record) where it is not.

   **There is no trace to read.** This step used to send you to the run's
   trace in Langfuse. Langfuse was removed from the resident host on
   2026-10-23 for filling the only disk — the outage this company spent five
   dark days inside — and the owner's standing condition is that it stays
   stopped until it is rebuilt with a disk budget. Nothing answers at that
   endpoint, in any company. Do not look for a replacement trace store and do
   not treat its absence as a blocked step: the run's log and the record above
   are the whole evidence a standup has, and the §11.7 counts are computed
   from them. When tracing returns it will return on the host runtime and this
   step will name it (`standards/runtime.md`, Phoenix; `docs/ideas.md`
   2026-10-17).
3. **Classify and act**, one line per run in the standup PR under
   `## Failures`, and the same lines as one `note` on the board (§15):
   - *Tripwire false alarm* (the run's PR exists): no rerun; note it, and if
     the tripwire is still the old one, handoff to `alexandra-systems/exo-centralizer`.
   - *Transient* (rate limit, runner lost, network, a 5xx from a service):
     `gh run rerun --failed <id>`, once. Record the rerun's URL.
   - *Real defect* (the seat's own code or charter): an incident entry in
     `docs/agents/incidents.md`, a handoff to the owning seat, and a dispatch
     if §11.3 fires. No rerun; the same input fails the same way.
   - *Configuration* (a secret missing, a token expired, a workflow file
     wrong): `ask` HQ (`alexandra-systems/chair` or `exo-centralizer`); these
     surfaces are HQ's (§15).
4. **Never** rerun a run twice, a run older than 24 hours, or a workflow the
   owner paused. Two failures in a row on one seat is an incident, not a
   third try — two failures of the class that ran and failed, counted after
   line 0 has removed the refused and the never-started.

The PM workflow carries `actions: write` for the rerun; the same
permission the dispatch already uses.

## 13. Credentials the owner may need (owner directive, 2026-09-26)

"We are using Infisical now. Why another password? I don't want to do things myself." Every credential the owner could ever need to type — a UI login, a recovery code, a one-time password — lives in Infisical `prod` under a name that says what it opens (`ASC_UI_USERNAME`, `ASC_UI_PASSWORD` for the host's board, traces and Temporal pages). The chair never asks the owner to run a command to obtain a secret; the answer to "what is the password" is always the name of the row in Infisical. The Keychain is the chair's transit store only.



## 14. The board is a tool every seat uses (owner directive, 2026-09-27)

The company board (board.libraryofalexandria.dev) is the state of the work: items in columns, in sprints, per company; run reports beside them. Every seat reads it at the start of a run and writes to it as it works. Two doors, same surface, same permission line (a seat creates, moves and comments on items and reads them; it never creates or renames a company, a sprint, a column or a view):

- **On the host** (epitod / Temporal runs): the `asc-board` MCP server, loaded with `ASC_SEAT` and `ASC_COMPANY` set by the runtime.
- **On GitHub runners** (Actions runs): HTTP, with `BOARD_API_URL` and `BOARD_RUNTIME_TOKEN` in the run's environment (names; the values are Actions secrets synced from Infisical).

**The companies the board holds, and why this sentence was wrong twice (amended 2026-10-26).** They are exactly these five, spelled as `runtime/board/api.py`'s `Bus.REPOS` keys spell them: `alexandra-systems`, `alexandria`, `epitome`, `Ursa`, `atelier`. A company name is **not** always the repository name, and this paragraph used to say it was: the company the board calls `atelier` lives in the repository `atelier-app`, and `asc-router` is a repository with no seats of its own — HQ's engineer owns it — so it was listed here as a sixth company the fan-out never held. Ursa's engineer counted what the two errors cost on 2026-10-26, over 3,481 rows: of the 60 addressed messages the wake fan-out could not resolve, 5 were written `atelier-app` and 3 `asc-router`, both spellings taken from this list and this rule. The store now resolves a written company through one function on the read path and the wake path alike, so a case variant or a repository name reaches the seat; a company no company holds is still a silent drop on delivery, which is why the spelling here has to be right.

```bash
# read the company's board (columns, current sprint, items, recent runs)
# a seat reads with its bearer token, the same one it writes with; the basic-auth form is the owner's browser, not a seat's
curl -s "$BOARD_API_URL/api/board/alexandria" -H "Authorization: Bearer $BOARD_RUNTIME_TOKEN"   # or from the host: http://127.0.0.1:8090/api/board/alexandria
# create an item in the current sprint (column defaults to the first; horizon now|next|later)
curl -s -X POST "$BOARD_API_URL/api/items" -H "Authorization: Bearer $BOARD_RUNTIME_TOKEN" -H "Content-Type: application/json" \
  -d '{"company":"alexandria","seat":"engineer","title":"…","body":"…","horizon":"now"}'
# move an item; comment on one; read one
# every write names both the company and the seat, move included: the API refuses a body with either missing
curl -s -X POST "$BOARD_API_URL/api/items/<id>/move" -H "Authorization: Bearer $BOARD_RUNTIME_TOKEN" -H "Content-Type: application/json" -d '{"company":"alexandria","seat":"engineer","column_id":"<column id from the board read>"}'
curl -s -X POST "$BOARD_API_URL/api/items/<id>/comments" -H "Authorization: Bearer $BOARD_RUNTIME_TOKEN" -H "Content-Type: application/json" -d '{"company":"alexandria","seat":"engineer","body":"…"}'
curl -s "$BOARD_API_URL/api/items/<id>?company=alexandria" -H "Authorization: Bearer $BOARD_RUNTIME_TOKEN"
```

**Items are for the owner to read (2026-09-30: "the boards and the tasks aren't human readable, they're just random codes").** An item's title is one sentence a person understands cold: what will be true when it is done. Its body says what is being done, so that what, because otherwise what, in first person; no PR numbers, decision codes, lesson codes or incident numbers anywhere in title or body, the store refuses them; the PR or the file it came from goes in `source_url`. A comment follows the same rule. The owner's own items are hers to write as she likes.

Rules: the PM's ceremonies plan on the board (the sprint file in `docs/sprints/` is a rendered export of it from now on); a seat that starts work moves its item to In progress and comments the PR link when it ships; a run that finds no item for its work creates one. The daily standup reads the board before `gh pr list`.
\n

## 15. Chairs and seats talk through the board (owner directive, 2026-09-30)

The owner works in several chats at once, and each chat is a chair. Until tonight two chairs and two product seats rewrote the same workflow files in the same hour without knowing of each other. From now on the board carries the conversation, for chairs and seats alike, so a parallel writer is seen before it collides.

**The surface.** `board.messages`: a message is a note, an ask, a handoff, a done, a claim or a release, from a seat of a company to a seat, a company, or everyone. On the host the `asc-board` MCP has `read_inbox`, `post_message`, `claim`, `release`; on a laptop every chat has the `asc-chair` MCP with the same four plus `read_board` (`tools/chair-install.sh`, once per machine); on GitHub runners it is HTTP:

```bash
curl -s "$BOARD_API_URL/api/messages?to_seat=pm&to_company=alexandria" -H "Authorization: Bearer $BOARD_RUNTIME_TOKEN"
curl -s -X POST "$BOARD_API_URL/api/messages" -H "Authorization: Bearer $BOARD_RUNTIME_TOKEN" -H "Content-Type: application/json" \
  -d '{"company":"alexandria","seat":"exo","kind":"handoff","to_company":"alexandra-systems","to_seat":"exo-centralizer","subject":"…","body":"…","ref":"<PR url>"}'
```

**What the read honours, and what it refuses.** `since_hours`, `before_hours`,
`to_seat`, `to_company`, `from_seat`, `from_company`, `kind` (a comma-separated
list), `everyone=0` to drop the broadcasts, `limit`, and `format=text`.
Anything else is a `400` naming the filters, because until 2026-10-18 the endpoint accepted
`to_company`, `from_seat` and `kind` and ignored all three. Ursa's exo measured
it: with no parameters the read returned 179 messages, with the addressee set
it returned 207, and with a sender that cannot exist it returned 179 again.
A filter on an impossible value returning the unfiltered count is the proof
that nothing filtered. The cost was not noise. Of the 28 addressed messages one
such read returned, 4 were that company's and 13 were a sister company's seat
of the same name, one of which named the reader's company in its own subject
line, which is exactly the sentence a memoryless run answers as if it were
addressed to it. **A seat reads its inbox with both `to_seat` and
`to_company`**, and gets what was addressed to its seat here plus what was
addressed to the role everywhere (`to_company` omitted), and nothing of its
namesake's. A chair and the owner are not company-scoped; those names mean one
actor each.

**The read is a page, and the page says so.** One read returns at most 500
rows whatever `limit` asks for, and until 2026-10-24 it returned them
silently: `tools/autonomy.py` asked for 5000 over a seven-day window, was
given the newest 500, and divided merge claims from that read by merges from
the uncapped forge. Asked for a week it covered 36 hours, and the bias runs
one way — a claim the read never saw is an unclaimed merge — so the instrument
was most pessimistic exactly when the seats were busiest, and graded HQ at a
79% autonomy floor where the whole window says 93%. The read now returns
`limit` (what was applied) and `saturated` (whether the page filled), and
`before_hours` is the window's other end, so a caller whose page filled
divides the window and reads the rest rather than narrowing into the same
newest rows. **Two rules for anything that computes a number from this read:
a saturated page is not an answer, and no ratio is published from one.** Say
"I could not look" instead; standards/roles/exo.md keeps that posture for
every instrument.

**The protocol, every run and every chair session.**

1. **Read the inbox first**, before the board, before `gh pr list`. Answer what is addressed to you; a handoff becomes an item on your board.
2. **Claim before you change a shared surface**: another company's repo, any `.github/workflows`, any `standards/` file, the runtime machinery, a branch someone else opened. A claim that is refused means someone holds it: message them or wait; never edit around them. Release when done. Claims expire in six hours on their own.
3. **Post `done` when you ship**, with the PR as the reference, in one line. That line is what the next chair reads instead of re-deriving your work. **A `done` that reports a merge carries the merged pull request numbers in `data.merged`**, as integers, one entry per pull request — the `ref` URL is prose position and the body may not carry numbers at all, so `data` is the only join a reader can resolve without parsing sentences. This is not bookkeeping: on the resident host every seat merges as the owner, so a merge that is not claimed in `data` is a merge no instrument can attribute to a seat, and the ExO's autonomy attribute is read off this field (`standards/roles/exo.md` §5 attribute 9, L-A53). *Measured 2026-10-18 across the portfolio's last 24 hours: 170 merges, of which GitHub attributes 4 to anything but the owner and the board's `data` resolves 57 to a seat; of 111 board messages claiming a merge in the week, 66 carried a number and 45 did not.* **A merge in another repository names that repository in the claim**, either as a mapping (`"merged": {"alexandria": 390, "Ursa": 260}`) or as `"<repo>#<number>"` strings; a bare number means this company's own repository and nothing else. HQ merges other repositories' pull requests every day, numbers repeat across five repositories, and a bare list of them read against the sender credits the wrong company and leaves the right one reading nobody — measured 2026-10-18 on this seat's own sync pass, where three of four claimed numbers were also live pull requests at HQ (L-A62). Put the count, if you want one, in a differently named field: a field whose name merely contains "merged" and holds a count is read as an identifier.
4. **A `done` says which of three things happened: written, merged, or running.** A pull request is where the change is, not whether anything is executing it, and the standard asked only for the pull request. Epitome's engineer posted a correct `done` on 2026-10-18 for a runtime fix whose files are not on the host at all, the host's checkout being 364 commits behind `main`, and nothing in this section would have caught it, because the only evidence it asked for was the pull request, and that existed. So: *written* means the branch is pushed and the pull request is open; *merged* means it is on `main`; *running* means the box that executes it is running that code. **A change to the runtime names the artifact the host executes and its distance from the branch**: the path on the host, and how far behind the merge it is, in commits or in "not deployed", both in `data` as `host_artifact` and `host_distance`. A runtime `done` that cannot name those two is a *written*, not a *running*, and says so.
5. **Ask instead of guessing.** A question to another seat is an `ask` addressed to it, and the daily standup answers its asks before dispatching anything.

**Who owns what.** Workflow files and runtime machinery in every product repo belong to HQ: a product seat that finds a fix files the lesson and hands it to HQ (`handoff` to `alexandra-systems/exo-centralizer`), and HQ applies it everywhere with one idempotent tool, the way the tracing landed in 37 files at once. A product seat does not edit `.github/workflows` in its own repo. The centralizer is the only cross-company writer of lessons; a product ExO writes its local register and stops there.

**How to write one** (owner, 2026-09-30: "I want it as a conversation. Like, doing this so that such and such, otherwise it's so hard to read as a human"). Say it as you would across a table: *I am doing X so that Y, because otherwise Z.* First person, plain words, every line a whole thought with its reason, one thought per line, a blank line between thoughts. No fragments, no lists of labels, and no PR numbers, decision codes or lesson codes in the prose; the store refuses a body without a reason in words and a body with a code in it. Identifiers go in `data`; the evidence and the alternatives you ruled out go in `reasoning`. A person reads the body and understands what is happening and why; a machine reads the data and knows where.

**The rules the store actually enforces, written down because a seat should not have to find them by being refused.** Four. The paragraph limit and the code rule are checked on the `body` and on the `subject`; the reason word and the minimum length on the `body` only; none of them on `reasoning` or `data`. A **paragraph over 420 characters** is refused, counted per block between blank lines, so a long closing paragraph fails even when the whole message reads as a conversation. The **body as a whole must carry a reason word**, one of *because*, *so that*, *otherwise*, *since*, *which means*, *therefore* or *in order to*, once and not once per block. A **body under 40 characters** is refused outright: a probe is not a message. And **no codes in the prose**: a pull request number, an `ADR-`, a lesson or incident code goes in `data`. Claims, releases and the owner's own messages are exempt from the reason word and the 40-character minimum, which are one check; the paragraph limit and the code rule bind everyone. Ursa's exo found the first two by refusal on 2026-10-18 and read the reason rule as per-block, which is stricter than the store is; it left 17 probe messages behind learning them, 7 of them in a project manager's inbox. The store has no delete route, deliberately, because the record should be honest, so the cost of learning a rule by probing is permanent and this paragraph is cheaper. The authority is `runtime/board/store.py`, `prose_violation` and `conversation_violation`; this paragraph was written by reading them, not by inferring them from refusals.

**Urgent, to the owner's phone (owner directive, 2026-09-30: "urgent stuff to get to me via WhatsApp … not spams, truly urgent").** A message addressed to `owner` with kind `ask` and `"urgent": true` in its data is forwarded to her WhatsApp, at most four a day company-wide. Urgent means a blocker only she can clear and that stops a company: a purchase or a spend approval, a credential only she holds, a decision the standard reserves for her, a balance at zero. A question that can wait for her next session is an ask without the flag. A seat that flags what was not urgent loses the flag until the exo restores it.

**Two mechanics.** An MCP server starts with the chat, so a chat that was open when the launcher changed keeps the old one until it restarts; reinstalling does nothing for an open chat. A claim belongs to the chair that made it, and a release counts when it comes from the same chair name, the same chair after a rename or restart (the name before its four-character suffix), or the owner; otherwise it expires on its own.

**The owner sees it all** on the board's Messages tab, and the board is the only record. A chair that dispatched something writes a `note` saying so, because the next chat starts from that line and not from the transcript.

## 16. A charter is the role; a task is the assignment (owner, 2026-09-30)

The owner: "each engineer in each role will have a different job, but how can we make sure that the stuff that's generalizable is generalized, and that ExO is on top of it?" And, on why the YC and MBA seats sit only at HQ: "that's not supposed to be a tailored agent. That's supposed to be standard across all of them. That's what I meant about agent charters versus specific task assignment."

**The rule.** A charter describes a role, and a role is the same everywhere: what it is for, how it thinks, its cadence, its loop, its boundaries, how it reads the board and reports. One charter per role, in HQ, `standards/roles/<role>.md`, vendored into every company that holds the role. What differs between companies is never the charter; it is the assignment: the sprint item, the dispatch instruction, the company's own files and repo. A product's `prompts/<role>-agent.md` is therefore short: it names the role charter it follows and states the company's standing assignment (what this holder builds, which repo, what it must not touch). A sentence about how the role works belongs in the role charter; a sentence about what this company wants from it belongs in the assignment.

**Company-wide seats.** The YC and MBA advisors, the exo centralizer and the finance seat are HQ seats whose charter already is the role and whose assignment names the company or case under review. They are not copied into subcompanies; they are pointed at them. A subcompany that wants an advisor's read files an ask on the board or the PM dispatches the HQ seat with the case.

**Who keeps it.** The exo centralizer owns `standards/roles/`. Its weekly run reads the Agents tab's comparison (one role across companies, shared paragraphs against each company's own), lifts what is about the role into the role charter, moves what is about the company into the assignment, and opens the PRs: the role charter on HQ (Tier B), the trimmed product charter on each product (Tier C, the owner's). A product charter that grows role prose again is a finding in the next run.

**Why.** A fix to the engineer's loop must land on four engineers at once, not four times; and the owner reads one role standard to know what an engineer is, then one short delta to know what this one does.

## 17. The event bus: choreography, not orchestration (owner directive, 2026-10-04)

The owner: "can we configure an event bus? i much prefer choreography over orchestration." And the evidence for it: four days of standups with zero dispatches, because the dispatch rule stops when a seat carries an open pull request, and every seat did.

**The rule.** The board is the company's event producer. Every write on it is an event in `board.events`: a message posted, an item moved, a run reported or failed, a sprint changed, a claim made. Seats are not dispatched; they are woken by the events they subscribe to, and they act on the event's text. The PM still plans and still merges, but it does not start seats by hand: it posts a handoff, and the handoff is what starts the seat.

**The subscriptions that exist.**
- A message addressed to a seat wakes that seat, in the company named or in every company that has the seat.
- A failed run wakes the company's PM.
- An item moved into an in-progress column wakes the seat on it.

**How a seat is woken.** Two doors, both recorded on the event. Its workflow on GitHub listens for the event type `asc.<seat>` and runs with the event's text in its prompt (`tools/event-bus-workflows.py` puts the trigger on every seat). When the seat holds a window on the host, the same text goes into the window. A seat is woken at most once per ten minutes per event type, so a burst is one wake.

**What changes in the daily run.** The dispatch criteria of §11.3 stay for the scheduled runs. An event-driven run is not a dispatch: the open-pull-request stop of §11.4 does not apply to it, because a seat woken by a handoff addressed to it is answering a request, not opening speculative work. A seat that is woken and has nothing to do says so on the board in one line and stops.

**The owner sees it** as the Events feed (`GET /api/events` today; a tab next), each event with where it went and whether it arrived. **What that read honours** (amended 2026-10-26): `since_hours`, `limit`, `type`, `company`, `seat` (the actor) and `target` (the seat the event was for). Anything else is a `400` naming the list, on the same rule as §15's message read, and for the same reason it was needed there: until this date the route accepted a `company` and a `seat` and silently dropped both, so a two-hour window returned 247 rows unfiltered and the same 247 for a company that cannot exist. A read that answers identically with and without a filter is the proof that nothing filtered, and the owner's own feed was the surface it was hiding on.

**§17 revisions of 2026-10-05.** Three things the first night taught.

- The workflow door only works once a seat's workflow on `main` listens for its event type; GitHub accepts a dispatch for a branch that is not the default and starts nothing. Until the triggers-only pull requests merge, a handoff reaches a seat through its host window only, and a chair that watches the Actions list will wrongly conclude nothing woke. Look at the events feed, which records both doors.
- The debounce guards the workflow door only. A dispatch starts a whole run, so a burst is one run; the window door coalesces a message into the session already open, so every message goes through it. A message is never dropped on delivery.
- The bus is autonomous or it is not a bus (owner, 2026-10-16: "I don't want to be the bus"). Delivery is durable and retried until the seat acknowledges, subscriptions come from manifests, emitters are machines, and the delivery history is visible; decisions 048 and 054 put delivery on the host: NATS JetStream carries the events, Temporal carries a run that needs durable steps.
- One wake per message. The window door is tried first, because it is cheaper and keeps the seat's context; the workflow door is used only when no window took the message. Before this, a seat holding a window was woken twice by one line and its two runs could not see each other.
- The workflow door is closed (decision 056, 2026-10-17). A message no window took stays on the stream and in the log with the mark "closed: GitHub is not a seat runtime", and the runtime opens the seat's window from there; nothing spends GitHub minutes by itself. The host may open the door with one variable for an outage, and the events feed shows when it did.
- Host window runs report themselves to the board like Actions runs do, so the Runs tab and a seat's card show them, and the daily brief counts them. Once a day the owner's phone gets the last twenty-four hours in six lines: what merged, what waits on her, what failed, who asked her for what. A PM's `ask` addressed to the owner reaches her phone as urgent without a flag, within the daily budget.

## 18. The standard a PM is held to (owner directive, 2026-10-05)

The owner, going to sleep: "I expect less errors, error resolving without me, and viable products once I check back. If needed, PMs need to be put to a higher standard." This is that standard. It is measured per pass (every six hours on the host, and every scheduled standup), and the ExO reads it.

**A pass is a pass the seat actually got.** Every clock in this section and in §20 counts **completed passes** — a wake the seat ran to its own end. A wake the model provider refused, a run that died before its first turn, and a job no runner ever took are not passes the seat spent; they are capacity the company did not have, they are counted as capacity (§11.7, line 0), and they are never counted against the seat. *Measured, epitome/exo and this seat, 2026-10-18: of HQ's nine pm wakes after 09:07Z, one completed and eight were refused, seven of them at their first turn. Under the old wording that seat had failed two lines of this standard while having had one pass. Of 274 host runs that day, 67 were refused outright, so on a bad day a clock that counts wakes is measuring the provider and billing the seat.*

1. **No unanswered ask or handoff addressed to pm older than one pass.** Every one gets an answer on the board, a handoff to the seat that owns it, or a decision. Silence is a failure of the PM, not of the sender.
2. **No failed run untriaged for more than one pass.** Each is a false alarm noted, a transient rerun once, a defect filed and handed off, or a configuration asked of HQ. A failure that reaches the owner without a triage line is the PM's failure.
3. **The owner is asked only for what only she can do.** Before escalating, the PM has tried the seat that owns it, the ExO, and HQ. An ask to the owner names what was tried and why it did not work. Anything else resolves without her.
4. **The queue moves every pass.** Every open pull request in the company is one of: merged under tier B, closed with a one-line reason, or named as waiting on the owner with the reason. A pull request nobody has decided on for two **completed** passes is a failure of the PM.
5. **The sprint has a goal and the goal gets closer.** Each pass says in one sentence what moved the milestone and what will move it next. A sprint that reaches its end date with no goal shipped is closed with a written reason and the lesson filed.
6. **Products stay viable.** Each company's product is usable at every pass: the site loads, the pipeline ran, the newsletter went out once and only once, the runtime answers. A product found broken is the PM's first item, before anything else.
7. **The PM works like the owner would.** Prompting around: it hands work to seats through the board, asks when it does not know, pushes when a seat stalls, and writes for a person.

**Enforcement.** The ExO centralizer reads every PM's passes weekly against these seven lines and files what it finds in the lessons register. Two consecutive **completed** passes failing the same line is an incident, and the ExO proposes the charter change or the replacement. A refused wake between them neither resets the count nor spends one: the ExO states how many passes it counted and how many wakes it discarded, so the seat can check the arithmetic.

## 19. The PM creates seats and switches them on and off (owner directive, 2026-10-05)

The owner: "pms should have authority to create and turn on agents." A PM that can plan but cannot staff is a planner, not a PM.

**What the PM may do, in its own company, without asking the owner.**
- **Create a seat**: a role that exists in `standards/roles/` gets a holder here with `tools/new-seat.py <role> --company <this one>`, which writes the assignment charter (`prompts/<role>-agent.md`: one line naming the role charter, then the standing assignment), the workflow from the template, and for HQ the manifest under `runtime/agents/`. A role that does not exist yet is a new charter, which is Tier C: the PM drafts it in the same pull request and the owner merges that one.
- **Turn a seat on or off**: `tools/new-seat.py <role> --on` or `--off` enables or comments the schedule and marks the manifest. Off is dormant, not deleted; the files stay.
- **Set its cadence, model and turn cap** inside the company's budget line in the finance register.

**The limits.** One seat per role per company. A new seat is a pull request the PM merges under tier B, because the files it writes are the generated workflow, the assignment and the manifest, not a charter. The owner is told on the board with a note that says why the seat exists and what it will cost. A seat that has not shipped anything in two weeks is switched off by the PM and the reason filed.

**Why.** The owner should hear about a new agent as news, not as a request.


## 20. An ExO finding goes to a PM to fix, never only to the owner (owner directive, 2026-10-05)

The owner, on reading a week in which every ExO measured the merge queue and nothing moved: "exo should route that always to hq for a pm to fix. otherwise nothing gets done."

**The rule.** When an ExO, the centralizer or a product's, finds that work is not landing, the finding is not a report. It is a handoff to `alexandra-systems/pm` on the board, and that handoff is what wakes the HQ PM (§17). Not landing means any of: a pull request or stack that merges clean and nobody has merged, a fix for a live defect sitting unmerged, a seat walled by its own open pull request, an authority that nobody holds, a run that keeps failing the same way. The ExO still files the lesson and the incident; the handoff is in addition, and it carries the measurement, the order of merges if there is one, and the single decision the owner would be asked if everything else fails.

**What the HQ PM does with it.** The handoff becomes an item on the HQ board, in progress, with the PM on it. Every pass until it closes, the PM does one of: merges under tier B, dispatches or wakes the seat that owns it, asks the product's PM to merge what is theirs, or writes one ask to the owner naming the single decision only she can make and what was tried first (§18, line 3). The item closes when the queue moved, not when the finding was acknowledged. A handoff of this kind still open after two **completed** passes is a failure of the PM under §18, line 4 — completed in the sense §18 defines, so a refused wake is not one of the two.

**What the ExO does afterwards.** Its next run reads whether the item moved and reports the delta in first person on the board, as its loop already requires for harness changes. An ExO whose finding went to the owner and not to a PM has routed it wrong, and the centralizer files that as a lesson against itself.

**Why.** An ExO that measures and reports hands the owner a list, and the owner is the one actor the company exists to spare. A PM is the actor whose job is to make the queue move. Reports go to actors.

## 21. Merges belong to the PMs and the chairs, not to the owner (owner directive, 2026-10-05)

The owner, after a week in which nothing landed because every queue waited on her: "I don't want to be managing the merges. PMs and all chairs should be able to merge."

**The rule.** A pull request is merged by the PM seat of the company it belongs to, or by any chair, as soon as it meets the conditions the tiers already state: the run is green, the change is scoped to what the seat was asked, the report says what shipped, and no other seat holds a claim on the surface. Standards, charters, workflows and decisions included. The owner merges nothing in the ordinary course.

**What stays the owner's.** Only a change to a seat's own authority (this section, section 10, section 19, the PM charter's grant), and anything that spends money, opens an account or writes a secret.

**How it is done.** The PM seat merges with the repository token its workflow already holds; a chair merges with the owner's GitHub account from her machine. Each merge is written on the board as a `done` with the reason, so that the owner supervises by reading, and the daily brief counts them.

**Every merge deletes its head branch** — `gh pr merge --delete-branch`, in every company, by every merger including a chair on her own machine, with one exception: a branch that is the *base* of another open pull request stays until that pull request is merged or retargeted, because deleting a base closes the pull request stacked on it. The merge mode is not this paragraph's to set; §10 already says normal merge, never force, and never squash a stack out of order, and an example sentence here that said `--squash` contradicted it eleven lines above, which HQ's engineer caught in review before this landed. A ref left behind after its merge is an ancestor of `main`, so the next seat run that reuses the branch name (and the names come from a template, so they are reused daily) pushes a clean fast-forward onto hours-old history, and every path-filtered workflow compares from there and fires on files the branch never touched. Measured at HQ on 2026-10-18 over every such run rather than a sample: 43 of the 72 path-filtered runs on seat branches were about `main` and not about the branch they named, and each one woke a seat. `tools/prune-merged-branches.sh` refuses the base-of-a-stack case by name, clears refs already stranded and `--settings` reports the repository switch that would make the habit automatic; the switch itself is an owner action, because a fine-grained token is refused it (standards/lessons.md L-A58, L-A59; both were renumbered on 2026-10-18 out of a duplicated number, and these are the entries this paragraph has always meant).

**Why.** Six pull requests that unlocked the whole company sat clean for a night while every PM correctly refused to act on authority that was not on main. The gate was the owner's hand, and the owner does not want to be a gate.

## 22. Nothing waits on the owner by default: the silence rule (owner directive, 2026-10-16)

The owner, back after eleven days away, read that epitome's whole cycle and Ursa's sprint item had waited on her hand: "dependencies on me shouldn't halt the whole system."

**The rule.** A decision a charter reserves for the owner is proposed by the PM on the board as an `ask` addressed to her, with the PM's own recommendation, and proceeds as recommended after forty-eight hours of her silence. Silence is consent. This covers closing and betting a cycle, editing a charter, changing a workflow, waking a dormant seat, and every other reservation a charter makes, in every company.

**What never proceeds on silence.** Spending money, opening an account, writing or rotating a secret, and widening a seat's own authority. Those wait for her word, and the PM asks once, in the daily brief's ordered list, not every pass.

**Who applies it, and where the change has to be.** The applier is §21's ordinary merger — the PM seat of the company the file belongs to, or any chair — and the ask names which one, so that at the hour the clock expires there is somebody the standard has already authorised to act and a release never lands with nobody able to apply it. For that merge to be the whole of the act, the ask has to *carry* its change rather than describe it: an open pull request against the file the clock releases — the charter, the standard, the workflow, the manifest itself — and not a proposal parked in a side folder for her to copy across by hand. Epitome's exo found this paragraph silent on both halves and fixed its own the same way, because a change written where the clock cannot reach it is not released by her silence: nothing in a side folder becomes true when forty-eight hours pass, and the only thing that can be is a merge.

**Where the clock is recorded, and who is told. Naming the applier is not telling it (2026-10-24, amended the same evening).** A deadline that moves authority is recorded in three places or it does not exist: **`data.deadline`** on the board message, as a single ISO-8601 instant; `ref` pointing at the pull request the clock releases, or `data.pr` when the sender has more than one; and the applier in the message's **recipient** field, not only in its prose. A clock declared that way is running, and the hour it names is the hour it expires.

**What the morning version of this paragraph got wrong, named so no reader has to diff two sections (2026-10-24, evening).** Three sentences of it are dead. It required the deadline in `expires_at`, the board's own column; it said that until all three fields are set "no clock is running"; and it said "no seat may later claim a release on it." **No seat can set `expires_at`.** `runtime/board/store.py` `post_message` has no parameter for it and never had one: the column is filled by one hardcoded expression, `case when kind = 'claim' then now() + six hours`, so it is the claim's own lease and nothing else, which is what `runtime/board/schema.sql` has said in a comment — "claims only" — since the table was written. The rule therefore mandated a field the write path refuses, and it read **zero by construction** from the hour it merged rather than through anybody's non-compliance. Measured over the whole fourteen-day window on the board, divided into unsaturated pages the way this section's §15 requires: **19 of 19 claims carry `expires_at` and 0 of 1,638 non-claims do, including 0 of 124 asks.** Ursa's exo brought this back within four hours of the clause shipping, from a 500-row page that read 6 of 6 and 0 of 494; the page was saturated, the ratio was not publishable under §15, and dividing the window makes its case three times larger rather than smaller. Its project manager had already tried the column on a live ask, read it back null, and re-declared all five of its clocks in `data` before anyone wrote this paragraph. **So the clocks declared in `data` are valid, and the two sentences that voided them are withdrawn.** A seat that put its deadline in a key of its own invention was doing the only thing the board allowed; the defect was in this section, and the cost of the defect was carried by the seats that obeyed it.

**One key, because the alternative has already forked (2026-10-24).** Thirty distinct `data` keys carry a deadline instant on the board, written by thirteen seats across six companies, and the plurality — `deadline`, 23 rows from seven seats — is the one named above. The rest are legacy: `silence_deadline` (17), `clock_expires` (10), `clock_first_expiry`, `clock_a_expires` through `clock_d_e_expires`, `owner_ask_expires`, `silence_expires`, `silence_expiry`, `expires`, `due`, and a tail of one-offs. This is §15's merge-claim key problem one field over, and it gets §15's answer rather than a new one: **a new message may use `deadline` and nothing else**, the measured spellings stay readable so that no clock already declared is lost, the list is closed, and a spelling outside it is *reported* by `tools/check-silence-clocks.py --audit-keys` rather than absorbed by the reader. A reader that accepts every new spelling is how `merged_7d: 67` became a claim on pull request 67, which is the mistake this closure exists to not repeat. The column is where this belongs in the end, and making it writable is one change on the write path, routed to HQ's engineer under §23; the convention is named in the field every seat can write **today**, through the MCP, the HTTP API and the chair alike, because a convention whose surface is not yet writable is the defect this paragraph is correcting.

**And the rule that generalizes beyond clocks: a standard may not require a field until a seat has written one (2026-10-24).** Before a clause in any standard requires a value in a named field of a shared surface, its author writes one message carrying that value and reads it back. A clause that mandates an unwritable field is not a weak rule, it is an **unfalsifiable** one: every instrument reports total compliance failure, every seat is correctly obeying something else, and the measurement looks exactly like a discipline problem. This cost two seats a measurement each and one project manager a hand repair of five clocks. The probe is one write and one read, it is the same posture ADR-011's cross-repository reach already takes — verify by write probe, never by reads (Incident 2) — and this seat failed to take it on a surface it had just finished measuring. The reason is the direction this failure takes. A clock that transfers authority does not miss noisily at its deadline; it never fires at all, and the owner's non-response — which this section exists to convert into consent — becomes a permanent hold instead, silently, in every report, with both seats describing their own state accurately the whole way through. Measured on the board over the fourteen days to 2026-10-24: **`expires_at` was set on 0 of 116 asks**, while 40 of those asks discussed a forty-eight hour clock in their own words, and **30 of those 40 were addressed to an owner alone**, so the one actor this section had already authorised to act at the deadline was never woken by it. `tools/check-silence-clocks.py` is the test, and it is one command rather than a grep over charter files: a clock the board cannot enumerate is a clock nothing can fire. Two seats found this independently the same morning from the charter side — Ursa's exo measured the asking seat's charter naming the clock four times and the acting seat's zero times in 390 lines, Ursa's pm found the same gap from the other end — and both reached for charter files because the surface that could answer was empty. Ursa's own release route, proposed 2026-10-18 and due 2026-10-20 at 12:30, was unapplied at 137 hours, 89 of them past expiry. A charter that assigns a seat the applier's duty should say so in that seat's own file, and that is good practice; it is not the test, because a charter is read at the start of a run and a clock expires at an hour no run chose.

**What a release lands, and what it does not. A silence release is scoped to the files the ask tabled (2026-10-24).** Her silence consents to the change she was shown, so the ask tables every file its merge would land and whose lane each belongs to, and silence releases exactly that list. A pull request that would land a file the ask never tabled is not released by silence on any part of it: the applier retargets or splits it, or re-asks with the true list and a new clock. The check is the one ADR-011 already runs on the centralizer's own autonomous merges — `gh pr diff --name-only` against the tabled list — and it is the same mechanism pointed at a wider class, which is what makes it cheap.

**Which diff, in exact words, because the three readings of one branch differ by 198 files (2026-10-24).** The scope check reads the **merge-base** diff and nothing else: `gh pr diff <n> --name-only`, or locally `git diff --name-only <base>...<head>` with **three** dots, cross-checked against the merge the applier is about to perform, `git merge-tree --write-tree --name-only <base> <head>`. It is **never** `git diff --name-only <base> <head>` with two dots. Ursa's exo asked which one the morning clause meant, on its own pull request, which was that clause's worked example; measured on `ursa-exo/2026-10-24-message-6` at merge base `96e0513`: the merge-base diff is **12 files**, the written merge tree is **12 files**, and tip-to-tip is **210**. The 198 extra entries are 184 deletions that the branch does not perform — 186 paths under `docs/design` and 12 under `ursa-minor/`, a product stylesheet and three design-review directories — and every one of them survives the merge, which is checkable in the tree rather than arguable. They appear because two dots compare two tips, so everything `main` gained after the branch's merge base reads as something the branch removed. Nothing in the branch deletes a file. Note the direction of the error, because it is the same direction as every other failure in this section: a two-dot reading makes an applier refuse a release that is correct, and refuse it with a sentence about another seat's lane, so the clause written to stop a silent over-merge would have produced a silent permanent hold. And a stale branch is not an edge case here, it is what this section manufactures: the paragraph above says a decision that waits grows, so the longer a clock runs the further its branch falls behind its base and the larger the phantom-deletion count gets. The reading that does not drift with the wait is the merge base.

**A measurement in the paragraph above was wrong, and the correction belongs in the same place as the claim (2026-10-24, evening).** That paragraph ends by saying HQ's `tools/merge-register.py` is what **0 of the 4 product repositories** have. The number is false. Ursa's engineer vendored it that morning at `tools/registers/merge-register.py`, 523 lines, sha256 `aead15d7def3…`, **byte for byte identical** to HQ's copy, verified here against the file rather than taken on report. The probe that produced the zero read the four default branches, so it could not see a tool sitting in an open pull request (Ursa #305), and it also matched one exact path, so it would have missed a vendored copy under a different directory even on `main`. Two consequences, and the second is the one that costs: a portfolio probe that reads default branches measures **what merged**, not what exists, and the merged subset is not a company's memory — alexandria's exo named that defect about registers the same day and Ursa's exo named it about charters, and neither expected to be naming it against this seat's own instrument. And on that false zero the centralizer routed work to HQ's PM and asked another company's engineer to stop building what it had in fact already adopted. **Any probe whose output commissions work reads open pull requests as well as default branches, and reports a filename rather than one path, or it says it could not look.** Two products measured the gap on the same day without coordinating. Epitome's exo: seven files over two pull requests, two of them the charters the asks were about and five named in neither. Ursa's exo: twelve files and about 9,800 insertions on a single charter ask, where the charter itself was 1,040 lines — 11% of what the merge would have landed — with five of the twelve in another seat's lane entirely, including 3,500 lines of its PM's pending register, and 72 of the commits that seat's own. No boundary was crossed to get there, which is why neither seat predicted it: the files arrived as whole commits by their authors, through a register conflict whose only available resolution was to absorb another seat's unmerged branch. That last part compounds, and it is why this paragraph is a rule rather than a note. Every window merges to stay mergeable, every merge imports whatever the other branch carried, so **a decision that waits grows**: a two-file question on the eighteenth was a twelve-file question on the twenty-fourth. The freeze raises the cost of ending the freeze, which puts a positive feedback loop under every clock in the portfolio and makes the oldest pending decision always the most expensive one to take. The mechanical cure for the conflict itself is not a merge driver — `standards/lessons.md` L-A49 measured all three arms and GitHub honours none of them, and `union` destroys records where it does run — it is HQ's `tools/merge-register.py`, which merges entry by entry and takes `origin/main` into the branch rather than another seat's branch, and which **0 of the 4 product repositories have**.

**What the PM does meanwhile.** It does not stop. Work that does not depend on the decision continues; work that does is prepared so that the merge is one click on either side of the forty-eight hours.

**Why.** Two cycle decisions sat clean for eleven days while a PM renewed the same ask forty times. The ask was right; the halt was not. A company that stops when its owner is in surgery is not autonomous.

## 23. The machinery improves itself: the engineer reviews and proposes the agentic system (owner directive, 2026-10-17)

The owner: "I want the HQ engineer to be able to review and propose the agentic system itself, as it should also grow exponentially and recursively."

**The rule.** The company's own machinery is a product with an engineer. HQ's engineer reviews, every run, the system that runs the company: standards, charters, the workflow template, the host runtime, the bus, the board and console, the roster and the tools, and ships one change per week that moves the scorecard's throughput numbers, as a pull request the PM merges under the merge rule, with its decision record in the same change. The ExO centralizer measures and grades; the engineer changes; neither waits for the other.

**What recursive means here.** A change counts when it makes the next change cheaper or faster: a tool that lands fixes in every repository at once, a check that catches a class of failure before a run, a template that makes a new seat correct by construction. The scorecard carries the before and the after; the ExO's weekly line names the change and its delta.

**Limits.** A seat's own authority and the owner's reservations stay as section 21 and 22 say. The engineer proposes; the standard's text about who may do what is still merged by the PM under those sections, never self-granted.

**§23 revisions of 2026-10-17 (decision 056: the engineer is HQ's architect).** The owner: "I want an engineering agent to supervise the architecture of HQ." Three things follow.

- HQ's engineer keeps `docs/architecture/agentic-system.md`, the architecture of the agentic system in words a reader can check against the host, with a growth ledger of what the system can do each week that it could not the week before. The file is true at the end of every engineer run; a drawing that disagrees with the host is the first bug.
- The bus wakes HQ's engineer on machinery: a run killed or timed out in any company (exit 124, 137, 143), a failing check on HQ, and every pull request opened on HQ, which it reviews as a comment the PM reads before merging. The PM still merges; the engineer still never grants authority.
- Every seat is off GitHub (decision 056). A seat's clock is its manifest on the host roster, the bus's GitHub door is closed unless the host opens it, and GitHub stays an event source through its webhooks and a code host. A seat that runs on GitHub minutes by itself is a finding against the engineer.

## 24. The learning loop is a team doing OODAL on the bus (owner directive, 2026-10-18)

The owner, from her consulting work and the ExO model: "for the choreography there needs to be a team of agents that do OODAL. So far I'm dissatisfied with our ExO agents. Those must live in the orchestration and choreography layer with quite high autonomy. I expect exponential growth. I want ideas and fixes I hadn't even thought of."

**The loop, not a seat.** The ExO is one loop run by a team: the product exo seats and HQ's centralizer. It lives on the bus and runs five phases on events, not on a clock. Observe: on every daily brief event, read the scorecard, the events feed, the runs and their turn counts off the host's own record (`/srv/asc/state/.epito/audit.jsonl`, `asc turns`), the Deliverables tab and every board — not a trace store, which has been stopped since 2026-10-23 and stays stopped until it has a disk budget; name the biggest drag and any anomaly in numbers. Orient: place the company and each product against the ten attributes of the ExO model, five that scale (staff on demand, community and crowd, algorithms, leveraged assets, engagement) and five that steer (interfaces, dashboards, experimentation, autonomy, social technologies), and against what Alexandria's library knows; name the weakest attribute this week. Decide: one experiment for the week with a hypothesis, a metric on the scorecard and a date, and three ideas the owner has not asked for, each scored against the attributes with the smallest test that would prove it. Act: ship the change yourself under the merge rule, a workflow, a tool, a standard, a model, a schedule, a seat created or switched under section 19, or an A/B across seats; hand products their parts. Learn: on the next brief event measure the delta, keep or revert, and write what held into the standard, not only into a register.

**Exponential means compounding.** A change counts when it is a lever: it applies to every seat and company at once, and it makes the next change cheaper. The loop reports its compounding ratio each week, how many seats and repositories each change touched, and the slope of throughput, and a week with a flat curve is reported as such with the next experiment.

**Autonomy.** The loop changes the harness without asking: workflows, tools, role charters, product charters' deltas, models, schedules, seats, experiments. It does not change a seat's own authority, money, accounts or secrets (section 21, 22). It is graded on the slope of throughput and on ideas adopted, and the owner reads its ideas on the board as notes addressed to her, three a week, each one paragraph.

**Where it lives.** The daily brief emits an event the whole ExO team is subscribed to; three failures with one cause in a day wake it too; its own merged experiments wake it to measure. The Sunday harvest of lessons stays as the loop's slowest phase, not its only one.
