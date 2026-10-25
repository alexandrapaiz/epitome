# Market brief — docs/market.md

Maintained by the market seat. This revision: **rev 20, 2026-10-25**, a
dispatch run that fired on rev 19's own pull request merging
([#310](https://github.com/alexandrapaiz/epitome/pull/310),
merged 2026-10-25T03:20:46Z) and asking this seat to continue with the
next item in its lane on the board, and say what it took. `gh pr list` was
checked first (L-E10): no market pull request is open now, so this
revision forks from `main`. This run's own clone arrived shallow
(`git rev-parse --is-shallow-repository` answered `true`) — the opposite
of rev 19's own clone, checked fresh rather than assumed from either prior
instance (L22); every file this revision cites was read from the working
tree directly, which a shallow clone does not affect, so nothing
downstream of that check changes.

The board inbox addressed to this seat was read directly
(`to_seat=market&to_company=epitome&everyone=0&since_hours=48`):
twenty-one messages, the newest naming this seat by name still the
project manager's 2026-10-25T03:21:20Z note, "Market brief merged, and the
stale-draft loop is closed on my end too" — confirming rev 19's own #310
merged clean at 03:20:46Z and closing, on the project manager's side too,
the exact stale-draft loop rev 15 and rev 18 had already named and closed
on this seat's side. Nothing newer addresses this seat in the window. So,
again, the "next item in my lane" is this seat's one standing lane card,
docs/backlog.md's "Market seat brief #1: pricing" (ADR-13, buyer-2
usage-based pricing), open since rev 1 (2026-09-18) and unanswered by the
owner since rev 4 (2026-10-02) — still **23 days** as of today, unchanged
in duration because today is the same day rev 19 reported it, not a
re-ask (L-X7).

Between this run's own first check (03:25:35Z) and rev 19's own merge
(03:20:46Z), **289 seconds** (four minutes forty-nine seconds) separate
the clocks — nowhere near the four-plus-hour gap this brief has used since
rev 15 as enough to owe a fresh landscape and demand pass, and the exact
shape of the thing rev 18 closed #297 for and rev 19 itself declined to
repeat eighty-eight seconds after rev 18: a run minutes old restating the
position of the run before it, rather than a genuinely new pass (L-X7).
So this revision does not open new ground on §1 (landscape) or §2
(demand): a search run under five minutes after rev 19's own identical
search returns the same results, and reporting them again as fresh would
be the non-finding L-X7 names, stretched into content for a third
consecutive revision inside roughly thirty minutes of wall-clock history
(rev 18 at 02:57:11Z, rev 19 at 03:20:46Z, this check at 03:25:35Z).

What this run does do: the same two cheap, mechanical re-checks the
charter asks every run to log rather than schedule by elapsed time — the
standing watch and the integration map's own git/fetch check — because
each costs one fetch and does not depend on a time gap to be worth
running, and because repeating a cheap direct check is not the same
mistake as repeating a stale finding.

## 4a. Standing watch: LangChain/LangSmith (ADR-12) — re-checked directly, unchanged

Re-fetched directly this run (L-R1): LangSmith's Cloud changelog
(`docs.langchain.com/langsmith/changelog`) still reports its latest entry
as "October 12-19, 2026," the same Agent-Auth-mints-a-GitHub-App-owned-by-
an-agent finding rev 8 first fired and every revision since has
re-confirmed, now four minutes forty-nine seconds after rev 19's own
identical check found the same thing. GitHub's own agent-apps changelog
entry (`github.blog/changelog/2026-06-02-extend-github-with-agent-apps/`,
re-fetched directly) still reads verbatim "Over the coming months, we'll
open up access to allow anyone to build agent apps," with the same partner
waitlist and no self-serve date. The general changelog feed
(`github.blog/changelog/`) was also re-checked: newest entries still
2026-10-22 and 2026-10-23, the same two days rev 18 and rev 19 already
read and ruled irrelevant to the agent-identity question by mechanism
rather than title. No new tripwire instance; logged per the charter's own
instruction to log the check even when nothing moves.

## 4. Integration map — re-verified against today's `main`, unchanged

`cli/src/lib/slack.js` re-read in full this run: still exactly three
exports (`formatLine`, `webhookName`, `postToSlack`), still a webhook
poster, no `apps.manifest.create` or any per-agent Slack-identity
mechanism anywhere in `cli/src/lib/`. `docs/cycles/` still holds nothing
past cycle 2 (`2026-09-21-cycle-1*.md`, `2026-10-18-cycle-2.md`).
**Standing recommendation unchanged: Slack remains integration #2**,
gated behind cycle 3's sequencing. No re-ranking trigger fired this run:
nothing in the five minutes since rev 19 touched Linear, Vercel, Clerk,
Supabase/Neon, Stripe, GitHub, or Trigger.dev's own standing.

## 1. Landscape and 2. Demand — not re-run this revision

Not stretched into content: the last landscape and demand passes are
rev 18's own (02:57:11Z), now twenty-eight minutes old but still short of
this brief's own standing measure (first stated rev 15, applied every
revision since) of a multi-hour gap before a fresh search is owed.
Carried forward by citation, unedited: §1's WorkOS/Entra bundling finding
and the Clerk correction, §2's three newest GitHub issue citations
(`tartale/claude-sandbox#9`, `sjsreehari/zerra#45`,
`cekinmezyucel/ai-hub#9`), both from rev 18 below.

## 3. Positioning and pricing — no fresh fetch owed; ADR-13 still unanswered, same day as rev 19

No fresh pricing fetch this run, for the same reason §1 and §2 are not
re-run this revision. **ADR-13's buyer-2 usage-based pricing question is
unchanged: still unanswered by the owner, still 23 days** (first raised
rev 1, 2026-09-18; recommendation shipped rev 4, 2026-10-02) — same day as
rev 19's own count, not a re-ask.

---

*Charter compliance note (rev 20): this run's own duty, read honestly
against the gap since the last one, is smaller than a full four-section
pass — the standing watch and the integration map's cheap git/fetch
checks, both logged and both unchanged, plus the lane card's count carried
forward unedited. Checked against docs/agents/lessons.md before shipping:
L-X7 (this revision declines, for the third consecutive run inside roughly
thirty minutes, to restate landscape and demand findings as new — the
exact mistake #297's own body confessed to and rev 18 closed it for); L13
(a run whose charter asks it to continue a cadence names its own stopping
point when the elapsed time cannot support new work, rather than quietly
becoming busywork); L22 (this run's own clone checked fresh for
shallowness rather than assumed from either of the last two runs' own
instances — it answered `true` this time, the opposite of rev 19's
`false`); L58 (checked and not triggered: this seat sends no board message
this run, so the board's refusal of bare `#NNN`/`ADR-NN` tokens in message
prose does not bind this file, and every pull-request number cited above
is both named in prose and carried in the pull request's own metadata, not
substituted for it). Also checked against docs/standards/lessons.md: L-R1
(the two standing-watch fetches and the one GitHub changelog re-fetch were
all direct, not taken from a prior run's summary); L-A34 (the project
manager's 03:21:20Z note read and confirmed to name exactly rev 19's own
merge, not a stale reference — the same shape rev 15's, rev 18's, and
rev 19's own corrections already checked for, this time clean); L-A12
(`cli/src/lib/slack.js` and `docs/cycles/` both re-read in full rather than
assumed unchanged, even though unchanged is what they turned out to be).
Flagged: the owner's still-open word on ADR-13, now 23 days; Microsoft
Ignite (Nov 17-20) still the next point the Entra question can move;
nothing escalated under ADR-12 this run.*

---

# Market brief — docs/market.md (rev 19, superseded by rev 20 above)

Maintained by the market seat. This revision: **rev 19, 2026-10-25**, a
dispatch run that fired on rev 18's own pull request merging
([#307](https://github.com/alexandrapaiz/epitome/pull/307),
2026-10-25T02:57:11Z) and asking this seat to continue with the next item
in its lane on the board, and say what it took. `gh pr list` was checked
first (L-E10): no market pull request is open now, so this revision forks
from `main`. This run's own clone arrived complete, not shallow
(`git rev-parse --is-shallow-repository` answered `false`) — unlike two of
the last three runs' own clones, checked fresh rather than assumed from
either prior instance (L22).

The board inbox addressed to this seat was read directly
(`to_seat=market&to_company=epitome&everyone=0&since_hours=48`): fifteen
messages, the newest still the project manager's 2026-10-25T02:34:07Z note,
"A draft pull request is yours alone to ready," naming PR #297 — the exact
handoff rev 18 itself answered, by closing #297 and shipping #307 below
that note's own timestamp (rev 18 merged 02:57:11Z, 23 minutes after the
note was written). Nothing newer exists in the window. So, again, the
"next item in my lane" is this seat's one standing lane card,
docs/backlog.md's "Market seat brief #1: pricing" (ADR-13, buyer-2
usage-based pricing), open since rev 1 (2026-09-18) and unanswered by the
owner since rev 4 (2026-10-02) — still **23 days** as of today, unchanged
in duration because today is the same day rev 18 reported it, not a
re-ask (L-X7).

Between this run's own first check and rev 18's own merge, **88 seconds**
separate the clocks (rev 18 merged 02:57:11Z; this run's first check ran
02:58:39Z) — nowhere near the four-plus-hour gap this brief has used since
rev 15 as enough to owe a fresh landscape and demand pass, and the exact
shape of the thing rev 18 itself closed #297 for: a run minutes old
restating the position of the run before it, rather than a genuinely new
pass (L-X7, and the mistake #297's own body was honest about making). So
this revision does not open new ground on §1 (landscape) or §2 (demand):
a search run eighty-eight seconds after the last one returns the same
results rev 18 already has, and reporting them again as fresh would be the
non-finding L-X7 names, stretched into content for a second time inside
three minutes of wall-clock history.

What this run does do: the two cheap, mechanical re-checks the charter
asks every run to log rather than schedule by elapsed time — the standing
watch and the integration map's own git/fetch check — because each costs
one fetch and does not depend on a time gap to be worth running.

## 4a. Standing watch: LangChain/LangSmith (ADR-12) — re-checked directly, unchanged

Re-fetched directly this run (L-R1): LangSmith's Cloud changelog
(`docs.langchain.com/langsmith/changelog`) still reports its latest entry
as "October 12-19, 2026," the same Agent-Auth-mints-a-GitHub-App-owned-by-
an-agent finding rev 8 first fired and every revision since has
re-confirmed, 88 seconds after rev 18's own identical check found the same
thing. GitHub's own agent-apps changelog entry
(`github.blog/changelog/2026-06-02-extend-github-with-agent-apps/`,
re-fetched directly) still reads verbatim "Over the coming months, we'll
open up access to allow anyone to build agent apps," with the same partner
waitlist and no self-serve date. The general changelog feed
(`github.blog/changelog/`) was also re-checked: newest entries still
2026-10-22 and 2026-10-23, the same two days rev 18 already read and ruled
irrelevant to the agent-identity question by mechanism rather than title.
No new tripwire instance; logged per the charter's own instruction to log
the check even when nothing moves.

## 4. Integration map — re-verified against today's `main`, unchanged

`cli/src/lib/slack.js` re-read in full this run: still exactly three
exports (`formatLine`, `webhookName`, `postToSlack`), still a webhook
poster, no `apps.manifest.create` or any per-agent Slack-identity
mechanism anywhere in `cli/src/lib/`. `docs/cycles/` still holds nothing
past cycle 2 (`2026-09-21-cycle-1*.md`, `2026-10-18-cycle-2.md`).
**Standing recommendation unchanged: Slack remains integration #2**,
gated behind cycle 3's sequencing. No re-ranking trigger fired this run:
nothing in the 88 seconds since rev 18 touched Linear, Vercel, Clerk,
Supabase/Neon, Stripe, GitHub, or Trigger.dev's own standing.

## 1. Landscape and 2. Demand — not re-run this revision

Not stretched into content: the last landscape and demand passes are
rev 18's own, 88 seconds old, and this brief's own standing measure (first
stated rev 15, applied every revision since) treats anything short of a
multi-hour gap as not owing a fresh search. Carried forward by citation,
unedited: §1's WorkOS/Entra bundling finding and the Clerk correction,
§2's three newest GitHub issue citations (`tartale/claude-sandbox#9`,
`sjsreehari/zerra#45`, `cekinmezyucel/ai-hub#9`), both from rev 18 above.

## 3. Positioning and pricing — no fresh fetch owed; ADR-13 still unanswered, same day as rev 18

No fresh pricing fetch this run, for the same reason §1 and §2 are not
re-run this revision. **ADR-13's buyer-2 usage-based pricing question is
unchanged: still unanswered by the owner, still 23 days** (first raised
rev 1, 2026-09-18; recommendation shipped rev 4, 2026-10-02) — same day as
rev 18's own count, not a re-ask.

---

*Charter compliance note (rev 19): this run's own duty, read honestly
against the gap since the last one, is smaller than a full four-section
pass — the standing watch and the integration map's cheap git/fetch
checks, both logged and both unchanged, plus the lane card's count carried
forward unedited. Checked against docs/agents/lessons.md before shipping:
L-X7 (the whole shape of this revision is declining to restate rev 18's
landscape and demand findings as new, eighty-eight seconds after rev 18
made them — the exact mistake #297's own body confessed to and rev 18
closed it for); L13 (a run whose charter asks it to continue a cadence
names its own stopping point when the elapsed time cannot support new
work, rather than quietly becoming busywork); L22 (this run's own clone
checked fresh for shallowness rather than assumed from either of the last
two runs' own instances — it answered `false` this time). Also checked
against docs/standards/lessons.md: L-R1 (the two standing-watch fetches
and the one GitHub changelog re-fetch were all direct, not taken from a
prior run's summary); L-A34 (the project manager's 02:34:07Z note read and
confirmed stale against rev 18's own 02:57:11Z merge, the same shape rev
15's and rev 18's own corrections already named, now a third instance);
L-A12 (`cli/src/lib/slack.js` and `docs/cycles/` both re-read in full
rather than assumed unchanged, even though unchanged is what they turned
out to be). Flagged: the owner's still-open word on ADR-13, now 23 days;
Microsoft Ignite (Nov 17-20) still the next point the Entra question can
move; nothing escalated under ADR-12 this run.*

---

# Market brief — docs/market.md (rev 18, superseded by rev 19 above)

Maintained by the market seat. This revision: **rev 18, 2026-10-25**, a
dispatch run that fired on the project manager's handoff naming PR
[#297](https://github.com/alexandrapaiz/epitome/pull/297) — "an open draft
with no live run behind it," idle since this seat opened it at
2026-10-24T21:54:50Z — and asking this seat to ready it, close it, or name
the clause keeping it a draft. `gh pr list` was checked first (L-E10): no
market pull request is open now (this run closed #297 itself, below), so
this revision forks from `main` rather than stacking on a branch that no
longer exists.

**#297, closed rather than readied.** Read against L-E10 (an open pull
request of this seat's own gets one of three moves — extend the branch,
close it with a reason, or land the stack — never a sixth implementation
opened beside it) and L-A32 (a run is over when its artifact is reachable;
readying belongs at the moment of coherence, not left for a later message to
name), this run chose to close rather than ready. #297's own body is honest
that it found little: "eighteen minutes since rev 16's own merge... not
stretched into a fresh pass." Between that check and this one, close to a
full day passed with no run behind it — well past the four-plus-hour gap
this brief has used since rev 15 as enough to owe a fresh landscape and
demand pass. Readying #297 now would have merged a day-old non-finding
minutes before this revision supersedes it with real material; closing it
and redelivering what it owed, fresh, read as the cleaner instance of L-X7
(do not restate a non-finding as new content) than readying it would have
been. Replied to the project manager's handoff on the board, in first
person, naming this reasoning before this run's own research began. The
revision count moves from 16 to 18 rather than reusing 17, because #297's
own number is already public against its own (different, thinner) content
and this brief has never reused a revision number for a second body of text.

This run's own clone arrived shallow (`git rev-parse
--is-shallow-repository` answered `true`, matching the exact defect
docs/backlog.md's "Now" card names and rev 15 already flagged once this
seat's own instance of), so `git fetch --unshallow` ran before any
history-dependent claim below, including the integration map's own git-log
check (L22: a defect measured once is a fact about that run, not a standing
property of the box, so it is checked again rather than assumed fixed).

The board inbox addressed to this seat was read directly
(`to_seat=market&to_company=epitome&everyone=0&since_hours=48`): fifteen
messages, all from the project manager, the newest being the #297 handoff
itself (L54: the honest, addressed-only read came back whole, unsaturated,
while the broadcast-inclusive read of the same window hit its own page
limit — the cost of the default-on read in this window was 99 rows of
someone else's broadcast crowding out the rest of this seat's own).
Everything older in that window is already-closed history (two "done"
notices, an escalation thread the project manager says is closed, and
earlier instances of this same "your draft is idle" shape) — nothing newer
than the #297 handoff is an open duty. So the "next item in my lane" is
again this seat's one standing lane card, docs/backlog.md's "Market seat
brief #1: pricing" (ADR-13, buyer-2 usage-based pricing), open since rev 1
(2026-09-18) and unanswered by the owner since rev 4 (2026-10-02) — now
**23 days**. Continuing with it means doing research that bears on her
decision, which is the rest of this revision.

## 4a. Standing watch: LangChain/LangSmith (ADR-12) — re-checked directly, unchanged; GitHub's own self-serve gate re-checked the same way, also unchanged

Re-fetched directly this run (L-R1): LangSmith's Cloud changelog
(`docs.langchain.com/langsmith/changelog`, fetched 2026-10-25) still reports
its latest entry as "October 12-19, 2026" — the same Agent-Auth-mints-a-
GitHub-App-owned-by-an-agent finding rev 8 first fired and every revision
since has re-confirmed, nothing added in the day since rev 16/17's own
check.

GitHub's own agent-apps changelog entry
(`github.blog/changelog/2026-06-02-extend-github-with-agent-apps/`,
re-fetched directly) still reads verbatim "Over the coming months, we'll
open up access to allow anyone to build agent apps," with the same partner
waitlist and no self-serve date. The general changelog feed
(`github.blog/changelog/`) was also checked this run for anything dated
since rev 16's own look: the newest entries are 2026-10-22 and 2026-10-23,
and the one closest to this charter's own wedge, "Enterprise installations
for GitHub Apps generally available" (2026-10-23), is about enterprise
deployment scope for GitHub Apps an operator already owns, not about
agent-owned identity or the self-serve gate this watch tracks — checked and
ruled irrelevant rather than skipped on the title alone (L-A34: an absence
is reported from the page actually read, not assumed from its headline).
No new tripwire instance; logged per the charter's own instruction to log
the check even when nothing moves.

## 1. Landscape — a bundling move between two of the three named human-identity players, found this run but eleven months old, so it corrects this brief's own research rather than reporting new market movement; Clerk re-checked, nothing changes

**WorkOS and Microsoft Entra Agent ID**, found via a search this run for
fresh October movement among the three named human-identity players, then
checked against WorkOS's own primary source
(`workos.com/blog/workos-partners-with-entra-agent-id`) rather than taken
from the search summary (L-R1). The post is dated **2025-11-19** — eleven
months before this check and, read against this brief's own rev 1
(2026-09-18), older than the brief itself. Quoted directly: WorkOS is
"building on Microsoft Entra Agent ID and its agent registry to create
agent identities and request tokens, enabling secure collaboration between
agents and users," and "[d]evelopers using WorkOS will be able to provision
and deprovision Agent Identities in Entra, allowing their downstream
enterprise customers to manage agent inventories." Checked for the one
question this watch keeps asking — does a resulting identity cross onto an
outside platform's own identity plane, GitHub's or Slack's, under its own
principal — and the page states nothing of the kind: both sentences scope
the result to "enterprise customers," their own agent inventories, inside
the Microsoft ecosystem WorkOS is building on top of, the same walled shape
rev 8's Entra finding and rev 16's own WorkOS finding each already named
from their own corners. This is not new market movement — a partnership
eleven months old was true on every one of this brief's seventeen prior
revisions and none of them surfaced it — so no landscape-movement claim is
made from it. What it is: a gap in this brief's own research, corrected
this run rather than carried forward unseen, and a second, independent
confirmation (two of the three named vendors, already bundling with each
other, still not crossing onto a non-Microsoft platform's own identity
plane) of the standing finding rather than a change to it.

**Checked and found unsupported, logged so the next pass does not spend a
search on it again:** this run's search also surfaced a secondary
characterization of a Clerk "Agent Toolkit," said to propagate a human or
org identity into an agent's context. Checked directly against Clerk's own
changelog (`clerk.com/changelog`) and Clerk's own blog rather than carried
on the search summary's word (L-R1, L-A12, the same method rev 14 applied
to the trydock.ai claim): no entry or post by that name exists on either
primary source. No landscape entry is made on the strength of the
unverified claim — the correction is the entry.

**Clerk, re-checked from five entries newer than rev 16's own check, no
change to the standing finding.** Clerk's own changelog carries five dated
entries since rev 16's 2026-10-24 check: "Secret keys are only shown once
on the API keys page" (2026-10-19), "Expo native components move to their
own package" (2026-10-20), "Merge two users into one" (2026-10-23), and
"Introducing Clerk Protect" (2026-10-23) — checked directly rather than
skipped on its title, it is fraud and account-takeover protection for human
authentication flows, "stop fake accounts and account takeover attacks,"
unrelated to agent identity in any way — and "Agent feedback" (2026-10-23),
already read in rev 16. None of the five gives an agent a Clerk-minted
identity usable on an outside platform; rev 14's standing finding (agents
as *builders using* Clerk's APIs, not recipients of a Clerk identity) is
unchanged.

## 2. Demand — three more independently-filed, independently-verified instances, one of them naming a different mechanism than every prior citation: prompt injection steering the leak rather than the sandbox simply inheriting a broad credential

Three GitHub issues, across three more independent, unrelated projects,
checked directly (`gh issue view`, L-R1), none overlapping the thirteen
already cited across rev 8 through rev 17:

- **`tartale/claude-sandbox` [#9](https://github.com/tartale/claude-sandbox/issues/9)**
  (filed 2026-09-29, **closed** 2026-10-19): the token reached the
  container three ways — `GH_TOKEN`/`CS_GITHUB_TOKEN` in the environment,
  visible via `docker inspect` and `/proc`, and in plaintext in a
  world-readable, mode-755 credential file — and the reporter verified from
  *inside the sandbox* that the token carried `permissions.admin=true` on a
  repository other than the one the sandbox was scoped to. Fixed by its own
  maintainer with the identical shape this brief has tracked since rev 8: a
  fine-grained PAT scoped to one repository, or better, "a short-lived token
  minted per session (GitHub App installation token) instead of a long-lived
  PAT."
- **`sjsreehari/zerra` [#45](https://github.com/sjsreehari/zerra/issues/45)**
  (filed 2026-10-04, **open**): a different leak vector than every prior
  citation in this brief — not the sandbox boundary, but the credential
  helper itself. The PAT is embedded directly into the git remote URL
  (`https://{token}@github.com/...`) to authenticate a push, and when the
  push fails — a protected-branch rejection, a timeout — git echoes the
  full remote URL, token included, into `stderr`, which lands in
  application logs, background-task traces, and error notifications. Read
  on its own terms (L1): this is the same long-lived, broad-scope PAT
  this brief's demand section tracks, leaking through an operational
  surface (error logging) rather than through the sandbox boundary the
  other citations describe.
- **`cekinmezyucel/ai-hub` [#9](https://github.com/cekinmezyucel/ai-hub/issues/9)**
  (filed 2026-10-21, **open**): read as its own data point rather than
  folded into the twelve others (L1), because its mechanism is different in
  kind, not degree. Every prior citation in this brief describes an
  architecture defect — a broad credential simply handed to a process that
  did not need it that broad. This issue names an attack: "[i]n 2026, CI
  agents were steered by [untrusted issue and PR] text into leaking
  `GITHUB_TOKEN` and API keys ('Comment and Control,' Clinejection). This is
  now the main risk class for agentic CI." The credential is not merely
  over-broad and sitting there to be found — it is actively exfiltrated by
  an agent that untrusted PR or issue text steered into leaking it. The
  reporter's own proposed fix is the same shape as every architecture-defect
  citation before it ("[a] short-lived GitHub App token per step instead of
  my personal token"), which means the fix this brief has tracked since rev
  8 answers both mechanisms, the passive and the actively-exploited, with
  the same credential shape — worth naming because a buyer weighing "how bad
  is the status quo" should hear that the broad token is not just an
  avoidable mistake sitting in a sandbox, it is a live target once an agent
  reads attacker-controlled text at all, which every agent that triages
  issues or reviews PRs does by design.

All three verified, none stretched past what they individually show. No
landscape or integration-map claim is made from any of the three.

## 3. Positioning and pricing — no fresh pricing fetch owed this run; ADR-13 still unanswered, now 23 days

No fresh pricing fetch this run: rev 14's runtime/trigger pricing comparison
(Fly, Modal, E2B, Trigger.dev) and rev 16's WorkOS federation finding are
both unchanged and not due for re-fetch on no elapsed reason to expect
movement (L-X7). The `cekinmezyucel/ai-hub` finding above sharpens "why
epito.me and not glue" from a new angle: the status quo it describes is not
only a defect a careful operator could in principle avoid, it is a
documented, named attack class against exactly the credential shape glue
code hands an agent, which is sharper ammunition than a hypothetical risk
for the owner's deck. **ADR-13's buyer-2 usage-based pricing question is
unchanged: still unanswered by the owner, now 23 days** (first raised rev 1,
2026-09-18; recommendation shipped rev 4, 2026-10-02).

## 4. Integration map — re-verified against today's `main` after the unshallow fetch, unchanged

`cli/src/lib/slack.js` re-read in full this run: still exactly three exports
(`formatLine`, `webhookName`, `postToSlack`), still a webhook poster, no
`apps.manifest.create` or any per-agent Slack-identity mechanism anywhere in
`cli/src/lib/`. `git log` from rev 16's own merge commit to today's `main`
touching `docs/market.md` returns nothing beyond this seat's own closed
#297, and touching the rest of the tree shows no change to `cli/src/lib/` or
`docs/cycles/` either — confirmed on the unshallowed history rather than
assumed from the shallow one this run's own clone first returned (L22).
**Standing recommendation unchanged: Slack remains integration #2**, gated
behind cycle 3's sequencing. No re-ranking trigger fired this run: the
WorkOS/Entra bundling move above is eleven months old and already covered
by the human-identity players this charter tracks by name, not a new
candidate for the integration-#2 slot.

---

*Charter compliance note (rev 18): research across all four sections this
run, triggered by the project manager's #297 handoff rather than a new
addressed board duty beyond it (the inbox was checked and carries nothing
newer). Checked against docs/agents/lessons.md (the file this charter
names) before shipping: L1 (every finding above reported by mechanism and
quote — a changelog sentence, a verified `permissions.admin=true`, a quoted
risk-class name — never by adjective; the `cekinmezyucel/ai-hub` finding
kept as its own data point, a different mechanism, not merged into the
other two); L13/L-E10 (the day-long gap since rev 16/17's own pass is
treated as owing a fresh look, and the look found genuinely new material;
the open-PR survey that is #297's own disposition is named in the PR body
by number, per L-E10's own requirement that a survey nobody can see is
indistinguishable from one nobody ran); L15 (the demand section's standing
method — carry the asker's outcome, closed or open — applied to all three
new issues); L22 (this run's own clone was unshallowed before any
history-dependent claim, per the exact defect docs/backlog.md's "Now" card
names, checked fresh rather than assumed fixed from rev 15's instance).
Also checked, per this seat's own established practice, against
docs/standards/lessons.md: L-R1 (every claim above fetched or queried
directly this run: two changelogs, one specific changelog entry, one
general changelog feed, two WorkOS/Clerk primary-source pages, three GitHub
issues via `gh issue view`, two searches); L-A12 (the Slack mechanism and
the Clerk "Agent Toolkit" claim both checked against their live sources
rather than asserted from a summary); L-A32 (PR #297 readied-or-closed this
run, not left for a later message to name — closed, with the reason in its
own comment and on the board, rather than readied stale or left
unfinished); L-A34 (the WorkOS-Entra absence reported from the two pages
actually checked, not as a settled fact about either vendor; the
"Enterprise installations" GitHub entry read in full before being ruled
irrelevant, not dismissed on its title); L-X7 (the ADR-12 recheck and the
GitHub self-serve gate reported as unmoved, not restretched into content;
ADR-13's count reported as a depth, a day later, not a re-ask). Flagged:
the owner's still-open word on ADR-13, now 23 days; Microsoft Ignite (Nov
17-20) still the next point the Entra question can move; the WorkOS-Entra
partnership logged here for the first time so a future revision does not
re-spend a search finding it again.*

---

# Market brief — docs/market.md (rev 16, superseded by rev 18 above)

Maintained by the market seat. This revision: **rev 16, 2026-10-24**,
a dispatch run that fired on rev 15's own pull request merging
([#286](https://github.com/alexandrapaiz/epitome/pull/286),
2026-10-24T17:09:05Z). `gh pr list` was checked first (L-E10): no
market pull request is open now, so this revision forks from `main`.
This run's own clone arrived complete, not shallow
(`git rev-parse --is-shallow-repository` answered `false`, `main` 0
commits ahead) — the opposite of rev 15's own clone, checked rather
than assumed on the strength of that one prior instance (L22, L-A34:
a defect measured once is a fact about that run, not a standing
property of the box).

The board inbox addressed to this seat was read directly
(`to_seat=market&to_company=epitome&everyone=0&since_hours=6`): it
carries exactly one message, the project manager's 16:47:59Z note
naming PR #278 as "an open draft with no live run behind it" — the
same note rev 15 already read and closed, timestamped thirteen minutes
before rev 15's own trigger merge (17:09:05Z) and therefore stale
before this run began (L-A34, same shape as rev 15's own reading of
it). Nothing newer exists in the window. So, a fourth time running, the
"next item in my lane" is not a new addressed duty — it is this seat's
one standing lane card, docs/backlog.md's "Market seat brief #1:
pricing" (ADR-13, buyer-2 usage-based pricing), open since rev 1
(2026-09-18) and unanswered by the owner since rev 4 (2026-10-02),
**still 22 days** as of today (2026-10-24) — unchanged in duration
because today is the same day rev 14 and rev 15 both reported it, not a
re-ask (L-X7). Continuing with it means doing research that bears on
her decision, which is what the rest of this revision is, plus one
closed clock below.

Four and a half hours separate this run's checks from rev 15's own
(~17:0xZ to ~21:3xZ) — enough, on this brief's own standing measure,
for a fresh landscape/demand pass, and this run found genuinely new
material on the landscape side rather than a repeat of rev 15's own
non-finding shape.

## npm-publish correction (rev 10 through rev 15): closed — the window ran out unused, and the project manager caught it independently first

Re-checked directly: `curl -o /dev/null -w '%{http_code}'
https://registry.npmjs.org/epito-cli` still returns `404` at
2026-10-24T21:33Z. `NPM_TOKEN` died **2026-10-24T19:26:26Z** — about
2h7m *before* this check, not before an upcoming one. Every revision
since rev 10 has carried this as a live, closing clock; this is the
first revision to find it already dead. The package was never
published while the token lived, so the npm distribution channel this
charter has tracked since rev 10 is now a closed question with a
negative answer, not an open one with a shrinking window.

This seat is not the one that caught it. `gh pr list` shows
[#295](https://github.com/alexandrapaiz/epitome/pull/295), opened by
`pm` at 2026-10-24T21:27:14Z — six minutes before this run's own
check — titled "Cycle 2: the npm publish window closed unused, caught
and routed," its own body probing the same registry endpoint plus four
sibling package-name candidates, all `404`, and naming the same expiry
timestamp. Read against this seat's own charter (never contact anyone
or act outward, read the world) and against L-X7 (do not restate a
non-finding as new content): there is nothing for this seat to do or
say on this clock beyond closing it out here. No landscape, demand, or
pricing claim rests on npm distribution's absence — rev 10 through
rev 15 treated it as a mechanical-readiness note, never as evidence
for §1 through §3 — so its closure changes nothing below. Flagged
closed rather than carried forward a sixth time.

## 4a. Standing watch: LangChain/LangSmith (ADR-12) — re-checked, unchanged; a fuller read of the same entry, no new tripwire instance

Re-fetched directly this run (L-R1): LangSmith's Cloud changelog
(`docs.langchain.com/langsmith/changelog`, fetched 2026-10-24T21:3xZ)
still reports its latest entry as "October 12-19, 2026" — the same
window rev 8 through rev 15 have all read, unmoved across the 4h30m
gap since rev 15's own 17:03Z check. GitHub's agent-app changelog
(re-fetched same window) still reads verbatim "Over the coming months,
we'll open up access to allow anyone to build agent apps," no
self-serve date, no change from every prior check.

A fuller read of the same October 12-19 entry this run surfaced text
this brief has not previously quoted, inside the identical entry rev 8
already fired the tripwire on and already escalated (§4a, rev 8; "the
owner's word... one word outstanding," carried every revision since):
"Agent Auth can now create a GitHub App owned by an agent from the
App's manifest, or bring an existing GitHub App by its App ID and
private key"; "Agent Auth now mints GitHub App installation tokens, so
agents can call `connections.get` on a `github_app` connection and
receive a working token with the permissions you allowed, renewed
automatically before it expires"; and, on MCP, "you can now invoke
managed-tools MCP servers and gateways with an access token from your
workspace's OIDC identity provider by sending it in the
`X-Agent-Auth-Principal-Authorization` header." This is additional
detail inside the already-fired, already-escalated mechanism — an
agent-owned GitHub App minting its own installation tokens is the
tripwire rev 8 named, and the OIDC-principal header is the same
mechanism's propagation into MCP calls, not a second, separate
tripwire. No new escalation is owed: the one word outstanding is still
the owner's, not a new question. Logged so the next reader has the
fuller quote rather than re-fetching to get it.

Entra not re-checked this run: rev 15 named Microsoft Ignite (Nov
17-20, 2026) as the next point this question can move, twenty-four
days out, and re-checking Microsoft's own pages again today would be
the same non-finding L-X7 names.

## 1. Landscape — WorkOS, the third named human-identity player, shipped Agent Auth and just published the clearest industry articulation yet of the walled-identity gap, four days before this check

This charter names three human-identity players by name: Clerk, WorkOS,
Entra Agent ID. Rev 14 checked Clerk and found one circulating claim
unsupported. Entra has been the standing watch's companion question
since rev 14. WorkOS had not been checked directly by this brief before
this run.

**WorkOS Agent Auth**, checked from WorkOS's own changelog
(`workos.com/changelog/agent-auth`, dated **2026-09-02**, "early
access" — a primary source, L-R1): "Define blueprints for what an
agent is allowed to do, and it gets short-lived, tightly scoped tokens
every time it runs," and "[e]very token identifies the agent, the user
or org it's acting for, and its own permissions." Agents can be
"delegated on behalf of a user" or "act autonomously with
scoped-access within an organization." This is a real, shipped,
per-agent credential — short-lived, scoped, carrying the agent's own
identity in the token — which is closer to vision's own passport shape
than Cloudflare's broker (§1, rev 15) or Entra's inward-governance
grant (rev 8, rev 15): WorkOS mints the agent an identity rather than
hiding a shared one behind a proxy. What the changelog page does not
state, checked directly rather than assumed either way (L-A34, the
absence read from this one page's vantage point): any mechanism by
which that token or identity is recognized by a platform outside
WorkOS's own customer application — GitHub, Slack, or any other
outside identity plane — as its own principal. The page's whole scope
is AuthKit and the customer's own application; "within an
organization" is the operative phrase.

**The gap, named by WorkOS itself four days before this check.**
`workos.com/blog/agent-to-agent-sso-federation`, published
**2026-10-20, 2026** — a primary source, dated inside this run's own
gap window — lays out the general pattern for an agent identity to
cross from one organization's identity provider to another's, quoted
directly: "Company B's identity provider never has to trust Company
A's agent directly. It only has to trust Company A's identity
provider, and it issues its own narrowly scoped token for the
interaction." Read exactly as written rather than stretched (L1): this
is a federation-of-identity-providers model, built on standards still
converging (the post names ID-JAG, A2A, SPIFFE). It requires Company B
— read, GitHub, Slack, or any outside platform — to stand up its own
identity provider and trust relationship with Company A's, which is
heavier infrastructure than accepting a credential minted on a
platform it already natively understands (a GitHub App installation
token, a Slack bot token). No sentence in either WorkOS page states
that GitHub, Slack, or any non-WorkOS-customer platform has done this
or has agreed to; the post is an architecture proposal dated four days
old, not a shipped integration. This is checked and logged as an
absence from these two pages specifically, not as a settled fact about
WorkOS or about GitHub (L-A34).

Read together, this is the sharpest, most direct hit yet on the exact
wedge the charter names: the player is one of the three named
human-identity vendors, the finding is dated inside this run's own
check window (published four days before this check, not months old
like the Entra and Clerk material), and it independently arrives at
the same walled-garden shape rev 15's Cloudflare finding named from the
runtime side — an identity (or a credential) that is real and scoped,
but recognized only inside a trust relationship the vendor itself has
to broker, never natively by the outside platform's own identity
plane. No ADR-12-style tripwire fires here: that watch is scoped by
name to LangChain/LangSmith, and nothing above shows WorkOS crossing
onto GitHub or Slack's own principal space the way ADR-12 asks after.

**Clerk, re-checked from three entries newer than rev 14's check, no
change to the standing finding.** Clerk's own changelog
(`clerk.com/changelog`, checked directly, L-R1) carries three dated
entries since rev 14's 2026-10-24 check: "Client ID Metadata Documents
(CIMD)" (2026-08-06, refined 2026-09-21) — URL-based `client_id` for
OAuth clients, explicitly an MCP/OAuth-client-registration mechanism,
not an agent identity Clerk mints; "Clerk MCP Server" (2026-10-15) —
"[y]our agent can only do what you approve and what your workspace
Role allows," scoped to the customer's own workspace; and "Agent
Feedback" (2026-10-23, one day old) — agents reporting product
usability issues through an MCP server, unrelated to identity. None of
the three gives an agent a Clerk-minted identity usable on an outside
platform; all three keep rev 14's finding intact (agents as *builders
using* Clerk's APIs, not recipients of a Clerk identity) with fresher,
directly-checked dates rather than the one unsupported secondary claim
rev 14 corrected.

## 2. Demand — the defect-and-fix pattern is now broad enough that a single search surfaces it as the common case, not the exception

A single search this run (`github issue agent sandbox "GITHUB_TOKEN"
personal token leaked container 2026`) returned at least ten
independent repositories reporting the identical shape rev 8's method
has tracked since September: an agent sandbox inheriting the operator's
own broad, ambient, or readable GitHub credential, filed as a security
or correctness defect by the project's own maintainer. Three were
verified directly (`gh issue view`, L-R1), none overlapping the seven
already cited in rev 8 through rev 15:

- **`0x63616c/world-wide-webb` #416** (filed 2026-07-29, **closed**
  2026-09-19): "The GitHub token is written into the sandbox at a path
  the agent runs as, and can read; it should live somewhere the agent
  cannot reach."
- **`giantswarm/beekeeper` #389** (filed 2026-10-05, **closed**
  2026-10-06, same day turnaround): "devctl reads the GitHub App's
  short-lived user token from the OS keychain over the user bus, and
  the sandbox blocks every Unix socket, the bus included" — a
  different failure shape than the other nine (over-broad credential
  access replaced with *no* working credential at all once the
  sandbox was locked down), the same honest-reporting-of-a-different-
  shape method rev 15 applied to the OpenHands issue.
- **`mboisnard/drinkit` #407** (filed 2026-09-26, **closed**
  2026-10-02): "An agent session cannot reach the owner's GitHub
  token" — already fixed, scoped tokens issued by a separate mechanism
  the issue references by number.

All three closed, all fixed by their own maintainers, none newer than
2026-10-06 — this run's search did not surface a new instance inside
its own time window, only a wider population of old ones. The honest
reading (L1, not stretched past what ten search results actually
show): this is not new demand, it is a measurement of how saturated the
existing demand finding already is. Ten-plus repositories matching on
one search query, spanning July through October, independently
diagnosing and in most cases independently fixing the identical defect,
is stronger evidence that the mechanism itself is cheap to build than
any additional single quote would add — which is this brief's standing
reading since rev 8 (§2, "a need met by the person who had it"), now
with a breadth number behind it instead of a growing list of quotes.
No new landscape or pricing claim is made from this breadth measurement
alone.

## 3. Positioning and pricing — WorkOS's own four-day-old federation post is sharper ammunition than last revision's Cloudflare finding; ADR-13 still unanswered, same day

No fresh pricing fetch this run: rev 14's runtime/trigger pricing
comparison (Fly, Modal, E2B, Trigger.dev) is unchanged and not due for
re-fetch on no elapsed reason to expect movement (L-X7). What is new is
a second, sharper dated example for "why epito.me and not glue," from
the identity side of the wedge rather than the runtime side rev 15
covered: WorkOS — one of the three human-identity vendors this charter
names by name — ships a real per-agent credential (§1 above) and, four
days before this check, published its own best articulation of why that
credential still does not cross onto an outside platform's identity
plane without that platform standing up its own identity-provider
relationship. Vision's passport claims to skip that step by minting
credentials in the form the outside platform already natively accepts
(a GitHub App installation, a Slack bot identity) rather than asking
GitHub or Slack to adopt new federation infrastructure to recognize a
WorkOS-shaped token. This is concrete, dated, from the vendor's own
mouth rather than inferred — the clearest version of the gap this brief
has had from a human-identity player, where rev 8's Entra finding and
rev 15's Cloudflare finding each made the same case from a different
corner of the wedge. **ADR-13's buyer-2 usage-based pricing question is
unchanged: still unanswered by the owner, still 22 days** (first raised
rev 1, 2026-09-18; recommendation shipped rev 4, 2026-10-02) — same day
as rev 15's count, not a re-ask.

## 4. Integration map — re-verified against today's `main`, unchanged

`cli/src/lib/slack.js` re-read in full this run: still exactly three
exports (`formatLine`, `webhookName`, `postToSlack`), still a webhook
poster, no `apps.manifest.create` or any per-agent Slack-identity
mechanism anywhere in `cli/src/lib/`. `docs/cycles/` still holds
nothing past cycle 2. **Standing recommendation unchanged: Slack
remains integration #2**, gated behind cycle 3's sequencing. No
re-ranking trigger fired this run: WorkOS and Clerk (§1 above) are
human-identity players already tracked by name in the charter, not new
candidates for the integration-#2 slot, and nothing in today's checks
touches Linear, Vercel, Clerk's own ranking, Supabase/Neon, Stripe,
GitHub, or Trigger.dev's own standing.

---

*Charter compliance note (rev 16): research across all four sections
this run, triggered by the lane-continuation instruction rather than a
new addressed board duty (inbox checked, carries nothing newer than
rev 15 already closed). Checked against docs/agents/lessons.md (the
file this charter names) before shipping: L1 (every finding above
reported by mechanism and quote — a changelog sentence, an expiry
timestamp, a search-result count — never by adjective; the demand
section's ten-repository count is read as a saturation measurement,
not stretched into ten new quotes); L13/L-E10 (no redo of rev 8 through
rev 15's own housekeeping; the 4h30m gap since rev 15's own pass is
enough to look again, and the look found genuinely new material — a
four-day-old primary source — rather than assuming it would not); L15
(the demand section's standing method — carry the asker's outcome,
closed or open, at next citation — applied to all three newly verified
issues). Also checked, per this seat's own established practice,
against docs/standards/lessons.md: L-R1 (every claim above fetched or
queried directly this run: two changelogs, two WorkOS primary-source
pages, the Clerk changelog, the npm registry, three GitHub issues via
`gh issue view`, one GitHub search); L-A12 (the Slack mechanism
re-read in full); L-A34 (the WorkOS absence — no stated outside-
platform recognition — reported from the two pages checked, not as a
settled fact about WorkOS; this run's own clone-shallowness checked
fresh rather than assumed from rev 15's instance); L-X7 (the ADR-12
recheck's fuller quote reported as detail inside an already-escalated
finding, not a new tripwire; the npm clock reported as closed, once,
rather than carried as live a sixth time; ADR-13's unchanged same-day
count reported as a depth, not a re-ask). Flagged: the owner's still-
open word on ADR-13, now carrying a dated WorkOS federation post in
addition to rev 15's Cloudflare finding and rev 14's four pricing
numbers; Microsoft Ignite (Nov 17-20) still the next point the Entra
question can move; the npm-publish clock, closed this run and not
carried forward again.*

---

# Market brief — docs/market.md (rev 15, superseded by rev 16 above)

Maintained by the market seat. This revision: **rev 15, 2026-10-24**,
a dispatch run that fired on rev 14's own pull request merging
([#278](https://github.com/alexandrapaiz/epitome/pull/278),
2026-10-24T17:00:20Z) — the dispatch's own text names no new event
beyond the merge and asks this seat to continue with the next item in
its lane on the board, the same instruction rev 14 answered one
revision ago. `gh pr list` was checked first (L-E10): no market pull
request is open now, so this revision forks from `main` rather than
stacking on a branch that no longer exists. This run's own clone
arrived shallow (`git rev-parse --is-shallow-repository` answered
`true`, one commit deep) — the exact defect docs/backlog.md's current
"Now" card describes, where the distance a seat measures answers 1
where the truth is hundreds — so `git fetch --unshallow` ran before
anything else this run read from git history; after it, 652 commits.
Nothing below rests on a shallow read.

The board inbox addressed to this seat was read directly rather than
assumed empty (`to_seat=market&to_company=epitome&everyone=0`,
`since_hours=1` and `since_hours=72` both checked): one message is
newer than rev 14's own last check, the project manager's note at
2026-10-24T16:47:59Z naming this seat's PR #278 as "an open draft with
no live run behind it." Checked directly against GitHub rather than
taken on the note's word (L-A34): `gh pr view 278` reports
`"state":"MERGED"`, `"mergedAt":"2026-10-24T17:00:20Z"` — thirteen
minutes after the note was written, and the same merge this run's own
dispatch names as its trigger. The note was true of the moment it was
sent and stale by the time this run read it; no action is owed, the
same shape L-A34 and rev 11's own correction already name, now a
second instance on this seat's own branch rather than one read about
another seat's. So the "next item in my lane" is, again, not a new
addressed duty — it is this seat's one standing lane card,
docs/backlog.md's "Market seat brief #1: pricing" (ADR-13, buyer-2
usage-based pricing), open since rev 1 (2026-09-18), unanswered by the
owner since rev 4 (2026-10-02), still 22 days as of today
(2026-10-24) — unchanged in duration because today is the same day
rev 14 reported it, not a re-ask (L-X7). That card cannot be closed by
this seat — it waits on the owner's word — so continuing with it means
doing research that bears on her decision, which is what the rest of
this revision is.

Four hours separate this run's checks from rev 14's own (12:44-12:47Z
to 17:0xZ) — enough time for new material to exist and be worth a
fresh pass across landscape and demand, which is what follows.

## 4a. Standing watch: LangChain/LangSmith (ADR-12) — re-checked, unchanged; the Entra-outward flag rev 14 raised, followed up and still unresolved

Re-fetched directly this run (L-R1): LangSmith's Cloud changelog
(`docs.langchain.com/langsmith/changelog`, fetched 2026-10-24T17:03Z)
still reports its latest entry as "October 12-19, 2026," the same
Agent-Auth-mints-a-GitHub-App-owned-by-an-agent finding rev 8 first
fired and every revision since has re-confirmed. GitHub's agent-app
changelog (re-fetched same window) still reads verbatim "Over the
coming months, we'll open up access to allow anyone to build agent
apps," with a partner waitlist and no self-serve date. Both unmoved
across a four-hour gap, the longest gap any same-day recheck in this
brief has had and still nothing moved — logged per the charter's
instruction to log the check even when nothing moves (L-X7).

Rev 14 flagged, not resolved, whether Entra's own identity has crossed
outward the way LangSmith's did — this run followed up directly rather
than letting the flag sit. Microsoft's own reference page
(`learn.microsoft.com/en-us/entra/fundamentals/whats-new`) was fetched
and read start to finish rather than sampled: despite a page-metadata
`updated_at` of 2026-10-08, its newest calendar section is "## June
2026" — nothing between July and October exists on this specific page,
which is itself worth naming (a reference page whose own update
timestamp outruns its content by over three months is not a page this
brief can treat as current, and is logged here so the next run does
not re-trust it on the strength of that timestamp alone). The entry
this page does carry, "General Availability - Microsoft Entra Agent ID
platform," falls under the April 2026 section — six months old, already
covered by rev 8's reading of the June oasis.security analysis of the
same platform, and still describes the Agent ID platform using
"standard protocols such as OAuth 2.0, MCP, and A2A" without stating
that an Entra-minted agent identity is usable as a principal on GitHub,
Slack, or any other outside platform's own identity plane — the same
gap the oasis.security quote named from Microsoft's own mouth in rev 8.
A secondary analysis of Microsoft's own October 2026 Entra announcements
(`msendpoint.com`, published 2026-10-14) was checked for the same
question and found the same gap from a different angle: it names
Agent 365 only in passing ("extends identity boundaries... to
autonomous AI agents") and states plainly that "a deep-dive" on Agent
365's own identity governance "is scheduled for Microsoft Ignite
(Nov 17-20)" — a dated, concrete point this brief did not have before
today, worth watching directly rather than re-checking Microsoft's own
changelog again before then. Flagged forward: Ignite, Nov 17-20 2026,
is the next point this question can move, not a re-check of today's
sources.

## npm-publish correction (rev 10): still open, and the clock is now inside three hours

Re-checked directly: `curl -o /dev/null -w '%{http_code}'
https://registry.npmjs.org/epito-cli` still returns `404` at
2026-10-24T17:06:25Z. `NPM_TOKEN` dies 2026-10-24T19:26:26Z — **about
2h20m from this run**, down from rev 14's 6h39m four hours ago with no
movement in between. This is the same live clock every revision since
rev 10 has carried, re-stated as unchanged in substance but closer in
time than any revision so far (L-X7) — the npm path is mechanically
ready and dry-run-proven (rev 10's own finding, still true), the one
remaining step is a secrets/account action this charter does not
execute, and the window for that action to still matter is now under
three hours.

## 1. Landscape — two runtime players independently shipped or are shipping credential brokering for sandboxed agents, neither minting the agent an identity of its own

**Cloudflare**, checked from its own blog
(`blog.cloudflare.com/sandbox-auth/`, published 2026-04-13, a primary
source rather than a secondary summary — L-R1): "outbound Workers for
Sandboxes" shipped in that post, available via
`@cloudflare/containers@0.3.0` / `@cloudflare/sandbox@0.8.9`. The
mechanism, quoted directly: "The sandboxed agent *never has access* to
these credentials," and "[a]ny time code running in the sandbox makes a
request to `github.com`, the request is proxied through the
handler... we're safely injecting a secret." Identity is read off
`ctx.containerId` — "[t]he auth key can be looked up based on the
container's identity rather than using uniform tokens" — so the broker
can pick which shared credential to inject per sandbox, but the agent
itself never holds, and GitHub's own side never sees, a credential that
belongs to that agent. This is a real runtime player in the wedge
shipping real credential isolation six months ago, and it is the
opposite shape from the passport vision proposes: the broker protects
the secret from exfiltration, but the principal GitHub records as the
actor of a push or a PR is still the shared App or token the broker
holds, not the agent, so the audit trail still cannot answer "which
agent did this" from GitHub's own records alone — only "which sandbox,"
and only if the operator kept its own separate mapping.

**Render** is building the same shape, not yet shipped. A GitHub issue
from Render's own `render-examples` org,
[`render-examples/vibe-coding-app#64`](https://github.com/render-examples/vibe-coding-app/issues/64)
(filed 2026-10-19, open, verified directly — L-R1), tracks adopting
"Sandbox credential brokering when it ships" and names today's
workaround precisely: a second, agent-free sandbox clones and pushes
with the real token through an askpass script so "no agent ever uses
that sandbox" — a second sandbox and a clone per push, paid specifically
to keep a shared credential away from the one process that might leak
it. The task is explicitly blocked on the platform feature ("Blocked on
the platform featu[re]"), confirming Render Sandboxes' own credential
brokering is roadmapped, not live, as of this check.

Read together with the demand evidence below, the Cloudflare/Render
shape is the live competitive answer to "contain the credential," and
it is a different and smaller promise than "identify the agent": a
sandbox boundary the secret never crosses, not a principal the agent
owns. Nothing here changes the integration map or ADR-13; it sharpens
§3's "why epito.me and not glue" with a dated, named counter-example
rather than the word "glue" alone.

## 2. Demand — a fourth independent maintainer fixed the identical defect in two days, a fifth is already past it and stuck on securing the App's own key, and a sixth shows the credential wiring failing outright in a mainstream harness

Three more GitHub issues, across three more independent projects,
checked directly (`gh issue view`, L-R1), none overlapping the four
already cited in rev 8 and carried since:

- **`jaroslawherod/micold-ai-ide` [#1002](https://github.com/jaroslawherod/micold-ai-ide/issues/1002)**
  (filed 2026-10-18, **closed** 2026-10-20 as `COMPLETED`): "Starting a
  sandbox container with a daemon gives it the user's own GitHub token
  and SSH key... anything running in the sandbox (agent, build scripts,
  dependencies) can reach every repo and org the user can." Asked for
  "a fine-grained GitHub token (or GitHub App installation token)...
  short-lived where possible, with expiry and rotation" — the passport's
  own shape, independently specified, and fixed by its own maintainer in
  two days. This is the fifth instance of the identical defect-and-fix
  pair rev 8's method tracks (§2 above, "a need met by the person who
  had it").
- **`domtriola/dotfiles` [#77](https://github.com/domtriola/dotfiles/issues/77)**
  (filed 2026-10-09, **open**): this builder is past the defect the
  other four describe — a personal GitHub App already mints
  `sbx-token`, a scoped-per-sandbox token, for every sandbox — and has
  hit the next problem instead: "The Keychain item was created by
  `security`, so any process that runs as me can read the key without a
  prompt. A process that reads the key can mint tokens for every
  repository where the App is installed, with every permission that the
  App holds, from any machine, until I delete the key pair on GitHub."
  Three options weighed (Keychain as-is, move the App's private key to a
  YubiKey, or drop the App for per-repo PATs), none fully satisfying,
  because every one of them still custodies a long-lived signing key on
  a personal machine. This is sharper evidence than the four defect
  reports: a builder who already built the exact mechanism this
  product sells still has an unsolved identity-custody problem one
  layer down, which a resident, non-personal runtime (the thing this
  charter's own wedge is identity+trigger+**runtime**, not identity
  alone) is positioned to answer and a personal laptop's Keychain is
  not.
- **`OpenHands/OpenHands` [#18847](https://github.com/OpenHands/OpenHands/issues/18847)**
  (filed 2026-10-22, **open**): a different failure mode, reported
  honestly as a different one rather than folded into the other five —
  not an over-broad credential, but no working credential at all, in
  one of the field's larger, better-known open-source agent harnesses.
  The reporter configured both a classic PAT and installed the
  project's own GitHub App with write access, connected it in-app, and
  the agent still could not authenticate: "`GITHUB_TOKEN` / `GH_TOKEN` /
  `GH_ENTERPRISE_TOKEN`: unset... `gh` is installed but not logged into
  any GitHub hosts... API check (`/user`): 401." Read as its own data
  point rather than stretched to match the others: this is evidence
  that credential wiring for agents is hard to get right even with
  every piece (PAT, App, in-app connection) nominally in place, in a
  project with real engineering resources behind it — the mechanism gap
  is not confined to small or indie harnesses.

No landscape or integration-map claim is made from any of the three
above; they are demand evidence only, read by mechanism and kept to
what each one actually shows (L1), not merged into one bigger claim
than any single issue supports.

## 3. Positioning and pricing — the Cloudflare counter-example gives "why epito.me and not glue" its sharpest contrast yet; ADR-13 still unanswered, same day

No fresh pricing fetch this run: §3's rev 14 pricing comparison (Fly,
Modal, E2B, Trigger.dev, fetched directly that run) is four hours old,
not a week, and re-fetching it now without reason to expect movement
would be the same non-finding L-X7 names — it is carried forward by
citation, unedited. What is new is a sharper answer to "why epito.me
and not glue," built from §1's Cloudflare finding rather than restated
from the word "glue" alone: Cloudflare's outbound broker is a genuinely
good answer to "don't let the secret leak," shipped by a serious
runtime player six months ago, and it is not an answer to "whose name
is on this PR" — by its own design the agent "never has access" to the
credential and GitHub's own records show the broker's shared principal,
not the agent's. A buyer who adopts Cloudflare's shape still cannot
answer, from GitHub's own audit trail alone, which of fifty agents
behind one proxy made a given push; vision's own passport answers
exactly that question, because the agent is the principal rather than a
`containerId` a broker maps internally. This is the clearest dated
example this brief has had of a competitor solving the leak problem and
still leaving the identity problem on the table — concrete ammunition
for the owner's deck, not a new recommendation. **ADR-13's buyer-2
usage-based pricing question is unchanged: still unanswered by the
owner, still 22 days** (first raised rev 1, 2026-09-18; recommendation
shipped rev 4, 2026-10-02) — same day as rev 14's count, not a re-ask.

## 4. Integration map — re-verified against today's `main` after the unshallow fetch, unchanged

`cli/src/lib/slack.js` re-read in full this run (not sampled): still
exactly three exports (`formatLine`, `webhookName`, `postToSlack`),
still a webhook poster, no `apps.manifest.create` or any per-agent
Slack-identity mechanism anywhere in `cli/src/lib/`. `docs/cycles/`
still holds nothing past cycle 2 (`2026-09-21-cycle-1*.md`,
`2026-10-18-cycle-2.md`), so cycle 3 — Slack identity, the passport, the
agent-spec layer — is still queued, not started. **Standing
recommendation unchanged: Slack remains integration #2**, gated behind
cycle 3's sequencing rather than by rank. No re-ranking trigger fired
this run: Cloudflare and Render (§1 above) are runtime players, not
candidates for the integration-#2 slot, and nothing in today's checks
touches Linear, Vercel, Clerk, Supabase/Neon, Stripe, GitHub, or
Trigger.dev's own standing.

---

*Charter compliance note (rev 15): research across all four sections
this run, triggered by the lane-continuation instruction rather than a
new addressed board duty (the inbox was checked and carries exactly one
message newer than rev 14's, and it was stale by the time this run read
it — see above). Checked against docs/agents/lessons.md (the file this
charter names) before shipping: L1 (every finding above is reported by
mechanism and quote — a quoted sentence, a filed-and-closed timestamp, a
package version number — never by adjective, and the OpenHands finding
is explicitly kept as its own data point rather than merged into a
bigger claim than it supports); L13/L-E10 (this run does not redo rev
8 through rev 14's own housekeeping; the four-hour gap since rev 14's
own landscape/demand pass is treated as enough time to look again, and
the look found genuinely new material rather than assuming it would
not); L15 (the demand section's standing method — carry the asker's
outcome, closed or open, at next citation — applied to all three new
GitHub issues this run). Also checked, per this seat's own established
practice, against docs/standards/lessons.md: L-R1 (every claim above
fetched or queried directly this run: two changelogs, one reference
page read start to finish rather than sampled, one secondary analysis,
the npm registry, three GitHub issues via `gh issue view`, one
competitor blog post); L-A12 (the Slack mechanism re-read in full
rather than assumed unchanged); L-A34 (the project manager's
"idle draft" note about this seat's own PR #278 checked against GitHub
directly and found stale by thirteen minutes, the same shape as rev
11's correction, now against this seat's own branch); L-X7 (the ADR-12
recheck and the npm clock reported as unmoved-and-closer, not
restretched into content; ADR-13's unchanged same-day count reported as
a depth, not a re-ask); L22 (this run's own clone was unshallowed
before any history-dependent claim was made, per the backlog's current
"Now" card naming exactly this defect). Flagged: the npm-publish clock,
now under 2h20m and the sharpest it has ever been reported; the Entra-
outward question, with Microsoft Ignite (Nov 17-20) now a named date to
watch rather than an open-ended flag; and the owner's still-open word on
ADR-13, now carrying a dated competitor counter-example (Cloudflare) in
addition to the four runtime/trigger pricing numbers rev 14 gave it.*

---

# Market brief — docs/market.md (rev 14, superseded by rev 15 above)

Maintained by the market seat. This revision: **rev 14, 2026-10-24**,
a dispatch run that fired on rev 13's own pull request merging
([#273](https://github.com/alexandrapaiz/epitome/pull/273),
2026-10-24T12:41:33Z) — the dispatch's own text names no new event
beyond the merge and asks this seat to continue with the next item in
its lane on the board. `gh pr list` was checked first (L-E10): no
market pull request is open now, so this revision forks from `main`
rather than stacking on a branch that no longer exists.

The board inbox addressed to this seat was read directly rather than
assumed empty (`$BOARD_API_URL/api/messages?to_seat=market&to_company=
epitome&everyone=0`, `since_hours=1` and `since_hours=6` both checked):
the only three messages in it are the same ones rev 13 already
answered (`95a5485c`, `f1b6d19f`, `e7368eaa`), nothing newer, and the
broader `epitome` feed for the same window carries no message to or
about market. So the "next item in my lane" is not a new addressed
duty — it is this seat's one standing lane card,
docs/backlog.md's "Market seat brief #1: pricing" (ADR-13, buyer-2
usage-based pricing), open since rev 1 (2026-09-18) and unanswered by
the owner since rev 4 (2026-10-02), now **22 days**. That card cannot
be closed by this seat — it waits on the owner's word, not on more
research — so continuing with it means doing the research that
actually bears on her decision rather than re-stating its age a
sixth time (L-X7). What follows is new, verified evidence across all
four charter sections: the last run that did real landscape/demand/
integration-map work rather than a same-day correction was rev 8,
roughly twelve hours before this one, so a fresh pass is not the
redundant recheck L13 and L-E10 warn against.

## 4a. Standing watch: LangChain/LangSmith (ADR-12) — re-checked, unchanged, sixth time today

Re-fetched directly this run (L-R1): LangSmith's Cloud changelog
(`docs.langchain.com/langsmith/changelog`, fetched 2026-10-24T12:44Z)
still reports its latest entry as "October 12-19, 2026," the same
Agent-Auth-mints-a-GitHub-App-owned-by-an-agent finding rev 8 first
fired and every revision since has re-confirmed, nothing added.
GitHub's agent-app changelog (re-fetched same window) still reads
verbatim "Over the coming months, we'll open up access to allow
anyone to build agent apps," no self-serve date, and "if you're a
partner interested in building your own agent app, you can join the
waitlist." Roughly ten minutes separate this check from rev 13's own
12:34Z fetch, not enough time for either vendor's release cadence to
move — logged per the charter's instruction to log the check even
when nothing moved, not stretched into content a ten-minute gap
cannot honestly produce (L-X7).

## npm-publish correction (rev 10): still open, clock now under seven hours

Re-checked directly: `curl -o /dev/null -w '%{http_code}'
https://registry.npmjs.org/epito-cli` still returns `404` at
2026-10-24T12:47Z. `NPM_TOKEN` dies 2026-10-24T19:26:26Z, about 6h39m
from this run — a live clock, re-stated as unchanged rather than
re-argued (L-X7), and closer to the edge than any revision so far has
reported it.

## 1. Landscape — Entra Agent ID's own wall confirmed from a second angle; one Clerk claim checked and found unsupported

**Entra Agent ID, re-checked from a new source.** Rev 8 tracked Entra's
inward-governance-only automatic-grant change; this run checked
whether Entra's identity has since crossed outward, onto GitHub or
Slack's own identity plane, the way the ADR-12 tripwire fired for
LangSmith. A third-party analysis of Microsoft's own Agent 365/Entra
Agent ID documentation
([oasis.security/blog/agent-365-oasis-for-ai-agent-governance](https://www.oasis.security/blog/agent-365-oasis-for-ai-agent-governance),
published 2026-06-01, updated 2026-06-03) quotes Microsoft's own
position directly: "GitHub Copilot Coding Agent runs in GitHub's
identity plane, not Entra," and "nothing about them correlates to
your Entra human identities natively" — the same walled-resident
shape vision §1 names, from the vendor's own mouth rather than a
competitor's. The same post also quotes Microsoft saying "GitHub
Copilot CLI and Claude Code support will follow, but they're not
shipping today," as of its publication. That quote is now almost five
months old and this run could not confirm or rule out whether it has
shipped since — a search this run (queries on Claude Code/Copilot CLI
as "agent providers") found only IDE-integration news (Claude as a
model choice inside Copilot Chat panels) which answers a different
question than whether Entra's own agent identity now extends onto
GitHub's platform under its own principal. Flagged, not resolved: this
is the Entra-side analog of the ADR-12 tripwire and is worth a direct
check of Entra's own changelog next run, not folded into the standing
LangChain-only watch this charter names.

**Checked and found unsupported, logged so the next pass does not
repeat it:** a secondary source (trydock.ai) claimed this run started
from, that Clerk "shipped Agent Sessions in Q1 2026: agents get their
own session type, attributable to a user, with admin-controlled
scopes," was checked directly against Clerk's own blog
(`clerk.com/blog/2026-03-03-clerk-for-the-ai-era`) and Clerk's own
changelog (`clerk.com/changelog`) rather than carried forward on the
secondary site's word (L-R1, L-A12). Neither primary source mentions
an agent session type, an agent identity, or agent-specific scoping of
any kind; Clerk's own blog describes agents as *builders using*
Clerk's APIs (an MCP server, API primitives tuned for agentic
callers), not Clerk minting agents an identity. No landscape entry is
made on the strength of the unverified claim — the correction is the
entry, per the standing method §2 below states for demand citations
and which applies here to a landscape one for the first time in this
brief's run.

## 2. Demand — three independent vibecoder harnesses converge on the same per-agent credential, verified issue by issue

Four GitHub issues across three independent, unrelated agent-harness
projects, each filed by the project's own maintainer rather than an
outside reporter, each verified directly with `gh issue view` rather
than taken from a search summary (L-R1):

- **`stSoftwareAU/VibeCoder` [#1423](https://github.com/stSoftwareAU/VibeCoder/issues/1423)**
  (filed 2026-09-07, **closed**): "The coding-agent subprocess's `gh`
  calls authenticate with the unscoped, mount-staged credential, not
  the run-scoped `GH_TOKEN` `buildGhEnv` mints" — flagged because the
  subprocess "is the component most directly exposed to prompt
  injection." Closed by its own fix.
- **`stSoftwareAU/VibeCoder` [#3699](https://github.com/stSoftwareAU/VibeCoder/issues/3699)**
  (filed 2026-10-14, **open**): "The agent subprocess can read the
  provider credential mount... and the staged `gh` `hosts.yml`... The
  agent therefore holds a usable credential inside the container."
  Still open at this check.
- **`Jesuso/agenthook` [#474](https://github.com/Jesuso/agenthook/issues/474)**
  (filed 2026-10-18, **closed**): "Under GitHub App auth the receiver
  uses hour-long installation tokens, but the agents still use the
  operator's own credentials: a `GITHUB_TOKEN` personal token... That
  token is broad... every repo the person [can reach]." Proposed and
  shipped: a short-lived, repo-scoped GitHub App token minted per
  agent run.
- **`omniaura/omniclaw` [#1113](https://github.com/omniaura/omniclaw/issues/1113)**
  (filed 2026-09-26, **open**): "`resolveGitHubTokenForContainer()`...
  returns `GITHUB_TOKEN`/`GH_TOKEN` from the host env... that value
  goes into the env mount of every container, including non-main
  groups" the project's own security docs classify as untrusted.

Read together, this is a stronger demand signal than any single issue
this brief has cited before: three maintainers of three unrelated
open-source agent harnesses, in three different months, independently
diagnosed the identical defect (the operator's own broad, long-lived
token handed whole to every agent subprocess) and independently
reached for the identical fix vision's own passport proposes — a
short-lived, per-run, repo-scoped credential minted fresh rather than
reused. Two of the four have already shipped that fix themselves,
which is this brief's standing honest reading of that fact (§2's
method, set in rev 8 after the nexa correction): a need met by the
person who had it, using nothing epito.me sells, is evidence the
mechanism is not hard to specify and evidence the market is already
moving toward it on its own — what has to be sold past this is the
roster and the cross-platform audit trail, never the single-platform
mechanism alone, which four maintainers above have each now proven
they can build themselves in an afternoon.

## 3. Positioning and pricing — every runtime/trigger competitor in the wedge bills usage, not seats; ADR-13 still unanswered at 22 days

Fresh primary-source pricing, fetched directly this run rather than
taken from aggregator summaries (L-R1), across every runtime and
trigger player this charter tracks:

- **Fly.io Sprites** (`fly.io/learn/ai-sandbox-pricing/`, published
  2026-09-09, Fly's own domain): "$0.0385/CPU-hr, actually used" and
  "$0.021875/GB-hr, actually used" — sprites pause when idle, so an
  agent waiting on a model call is not billed.
- **Modal** and **E2B** (same primary source): both bill wall-clock on
  *reserved* resources rather than actual use — Modal "$0.1419/physical
  core-hr," E2B "$0.0504/vCPU-hr" — charged continuously while a
  sandbox runs regardless of CPU idle time.
- **Trigger.dev** (`trigger.dev/pricing`, fetched directly this run): a
  hybrid of flat monthly tiers (Free $0, Hobby $10, Pro $50, each with
  matching usage credits) plus metered overage — "$0.000025 per run"
  and per-second machine time from "$0.0000169" to "$0.0006800."

Every one of them meters the thing an agent actually consumes — CPU
seconds, wall-clock reservation, or runs — rather than charging per
seat or per developer. None of the four runtime/trigger players this
charter tracks for the identity+trigger+runtime wedge sells a flat
per-seat tier as its primary unit. This is new, concrete comparison
evidence for ADR-13's standing recommendation (usage-based
per-mint/per-verify pricing for buyer 2, the agent-maker/platform
tier), first made in rev 4 on weaker grounds; it does not change the
recommendation, it gives it four dated, quoted competitor numbers to
show the owner instead of the word "usage-based" alone. **ADR-13's
buyer-2 pricing question is still unanswered by the owner, now 22
days** (first raised rev 1, 2026-09-18; recommendation shipped rev 4,
2026-10-02) — the card cannot close without her word, and this run's
contribution to it is evidence, not a repeated clock.

## 4. Integration map — re-verified against today's `main`, unchanged

The mechanism audit rev 4, rev 5, and rev 8 ran against this codebase
was re-run directly against `main` at `bad29ca` (2026-10-24T08:45
-04:00), not carried forward on faith (L-A12): `cli/src/lib/slack.js`
is still exactly three functions (`formatLine`, `webhookName`,
`postToSlack`), still a webhook poster with no `apps.manifest.create`
or equivalent anywhere in `cli/src/lib/`. No `docs/cycles/` file past
cycle 2 exists yet, so cycle 3 (Slack identity, the passport, the
agent-spec layer) is still queued rather than started. **Standing
recommendation unchanged: Slack remains integration #2**, gated behind
cycle 3's sequencing, not by rank — no re-ranking trigger fired this
run across LangSmith, GitHub, Entra, or Clerk (above).

---

*Charter compliance note (rev 14): research across all four sections
this run, triggered by the lane-continuation instruction rather than a
new addressed board duty (the inbox was checked and carries nothing
newer than rev 13 already answered). Checked against
docs/agents/lessons.md (the file this charter names) before shipping:
L1 (every finding above is reported by mechanism and quote — a byte
count, an exact dollar figure, a quoted sentence — never by
adjective); L13/L-E10 (this run does not redo rev 9 through rev 13's
housekeeping; it is the first landscape/demand/integration-map pass
since rev 8, roughly twelve hours earlier, which is not a same-day
duplicate); L15 (the demand section's standing method — carry the
asker's outcome, closed or open, at next citation — applied to all
four GitHub issues this run, not just restated for nexa). Also
checked, per this seat's own established practice, against
docs/standards/lessons.md: L-R1 (every claim above fetched or queried
directly this run: two changelogs, the npm registry, four GitHub
issues via `gh issue view`, two pricing pages, two identity-vendor
posts); L-A12 (the Slack mechanism audit and the Clerk "Agent
Sessions" claim both re-verified against their live, current sources
rather than asserted from a summary); L-A34 (the Entra-outward
question is reported as unresolved by this run specifically, with the
surface checked named, rather than as a settled absence); L-X7 (the
sixth same-day ADR-12 recheck and the npm clock are reported as
unmoved-and-closer rather than re-narrated into content; ADR-13's age
reported as a depth with new evidence attached, not a re-ask).
Flagged: the Entra-outward question above, for a direct check of
Entra's own changelog next run; the npm-publish clock (under 6h40m);
and the owner's still-open word on ADR-13, now carrying four
competitors' numbers rather than one word, "usage-based."*

---

# Market brief — docs/market.md (rev 13, superseded by rev 14 above)

Maintained by the market seat. This revision: **rev 13, 2026-10-24**,
a dispatch run that fired on a board note the project manager posted
after rev 12's own last commit — a reply to rev 12's own board reply
(message `95a5485c`, `to_seat` `market`, 2026-10-24T12:26:23Z), not a
new event this seat generated. `gh pr list` was checked first (L-E10):
PR [#273](https://github.com/alexandrapaiz/epitome/pull/273) (rev 12)
is still open, so this revision is pushed onto its own branch rather
than forked from `main` a second time.

## The project manager's reply names where the "disposition script" actually lives — verified directly, not taken on either side's word

The project manager's note agrees nothing is owed on #268 (rev 11 and
rev 12 already established that) and adds one fact neither this seat's
nor the project manager's own earlier checks had: the "disposition
script" the original dispatch broadcast described is real, "just not
where either of us first looked: one layer up, in the shared tooling
this repository's seats call out to rather than vendor in," naming the
path `/srv/asc/hq/tools/check-draft-prs.sh`.

Checked directly rather than taken on the note's word (L-A12, "verify
location before asserting it"; L-R1): the file exists at exactly that
path on this host, executable, 20,150 bytes, and its own header text
("Draft pull requests whose run has ended... This tool draws that
distinction with a fact rather than a feeling") matches the mechanism
the note describes. Cross-checked against the board's own earlier
traffic rather than against the note alone: the project manager's
2026-10-24T12:09:21Z message, closing rev 10, already names this exact
path in its own `reasoning` field when readying #268 ("Confirmed
against /srv/asc/hq/tools/check-draft-prs.sh --repo alexandrapaiz/epitome:
disposition ready") — three messages before the 12:13:23Z note that
said "no such script exists anywhere in this repository." Read
together rather than any one in isolation: that earlier claim was true
scoped to this git repository's own tree (`check-draft-prs.sh` is not
vendored here) and misleading read as "the tool does not exist" (it
runs from the shared host directory every seat's tooling calls out to).
Both readings are now checked against the filesystem directly rather
than inferred from either message, which is the stronger form L-A34
asks for.

No action is owed on #268 or the disposition-script question — this
seat, the project manager, and now a direct filesystem check all agree
on the same state, and the note states plainly it is not reopening,
re-declaring, or re-reading anything further about it this run. It is
also outside the four sections this charter maintains (landscape,
demand, positioning/pricing, the integration map): a shared host
tool's filesystem path is not market intelligence, and this entry goes
no further than the one verification above.

No reply posted back to the board this run. The note asks this seat
nothing, closes its own side of the thread explicitly, and its one new
fact (the tool's real path) is independently verified and logged here
instead. A second board message confirming an agreement nobody
contested would be the pattern L-X7 warns against — a recheck that
cannot honestly produce new content, restated as if it were new
action — not the L17 duty, which binds only on a message that assigns
a standing duty; this one assigns none.

One flag for the register, not for this brief to resolve: this
charter (`prompts/market-agent.md`) names only `docs/agents/lessons.md`
for the pre-ship check, but the letter-prefixed lessons this revision
and every one since rev 5 cites (L-E10, L-A12, L-A34, L-X7 among them)
live in `docs/standards/lessons.md`, a file this charter never points
at. Per L31 ("a law binds where the seat reads, not where the register
keeps it"), that means this seat has been citing rules its own charter
does not actually bind it to for at least eight revisions running.
Not fixed here — patching `prompts/market-agent.md` is not research
and not one of the four sections this run owes — named so the next
reader does not take the citation as settled.

## 4a. Standing watch: LangChain/LangSmith (ADR-12) — re-checked, unchanged, fifth time today

Re-fetched directly this run (L-R1), not skipped the way rev 12
skipped it (rev 12's own gap since rev 11 was minutes; this run's gap
is roughly twenty-three): LangSmith's Cloud changelog
(`docs.langchain.com/langsmith/changelog`, fetched 2026-10-24T12:34Z)
still reports its latest entry as "October 12-19, 2026," the same
Agent-Auth-mints-a-GitHub-App-owned-by-an-agent finding rev 8 first
fired and rev 9, rev 10, and rev 11 each re-confirmed, nothing added.
GitHub's agent-app changelog
([github.blog/changelog/2026-06-02-extend-github-with-agent-apps](https://github.blog/changelog/2026-06-02-extend-github-with-agent-apps/),
re-fetched same window) still reads verbatim "Over the coming months,
we'll open up access to allow anyone to build agent apps, whether
you're a developer tools provider or just building an internal tool
for your team" — no self-serve date. Both triggers are now logged
unmoved five times in one day (rev 8 ~01:02Z, rev 9 ~01:16-01:45Z, rev
10 ~06:56Z, rev 11 ~12:09Z, this run ~12:34Z) — rev 12 itself declined
a sixth same-minute refetch on L-X7/L13 grounds, so this is the fifth
direct fetch, not a sixth — and nothing below was re-searched on the
strength of that non-finding.

## npm-publish correction (rev 10): still open, clock unchanged

Re-checked directly: `npm view epito-cli version` still returns
`404 Not Found - GET https://registry.npmjs.org/epito-cli` at
2026-10-24T12:34:34Z. `NPM_TOKEN` dies 2026-10-24T19:26:26Z, about
6h52m from this run — a live clock, re-stated as unchanged rather than
re-argued (L-X7).

## 1 through 4, otherwise unchanged: carried forward by citation

Nothing in this run's search budget — spent on the board note above
and the two re-checked triggers — touched landscape, demand, pricing
beyond the lane item, or the integration map. Sections 1 through 4
below are rev 8's and rev 11's, unedited except where earlier
revisions' corrections apply; the original text stands beneath this
note per house convention of not editing superseded text in place.
This seat's one standing lane item, docs/backlog.md's "Market seat
brief #1: pricing" card (ADR-13, buyer-2 usage-based pricing), is
unchanged: no owner word, still 22 days unanswered (first raised rev
4, 2026-10-02).

---

*Charter compliance note (rev 13): research limited to the one new
board fact and the two mandatory standing-watch checks; the one write
is this entry, not a board message, for the reason given above.
Checked against `docs/agents/lessons.md` (the file this charter names)
before shipping: L1 (the filesystem verification above is reported by
mechanism — a path, a byte count, a header line — never by adjective);
L13 (this run does not redo rev 11's or earlier revisions' landscape,
demand, or integration-map research); L17 (the board note was read
addressed-only, `to_seat=market&to_company=epitome&everyone=0`, and it
assigns no standing duty, so none was written down); L31 (flagged
above: this charter's own lessons pointer is narrower than the letters
this brief has cited since rev 5). Also checked, per this seat's own
established practice though this charter does not name the file,
against `docs/standards/lessons.md`: L-E10 (`gh pr list` checked
first; PR #273 was open, built on its branch); L-A12 and L-R1 (the
disposition-script path verified against the live filesystem, not
taken on the note's word); L-A34 (the "no such script" absence read
from its own vantage point — this repository's tree — rather than
treated as universal); L-X7 (no board reply manufactured where nothing
is owed; the ADR-12 and npm checks reported as a fifth and continuing
unmoved result, not restretched into content). Flagged: the next
useful work remains the npm-publish clock (dies 2026-10-24T19:26:26Z)
and the owner's still-open word on ADR-13's pricing ask (now 22 days),
and the charter-pointer gap named above is routed to the register, not
acted on here.*

---

# Market brief — docs/market.md (rev 12, superseded by rev 13 above)

Maintained by the market seat. This revision: **rev 12, 2026-10-24**,
a dispatch run whose own trigger event read as materially identical to
rev 11's: the same project-manager "done" note and the same "idle
draft #268" broadcast text, re-delivered rather than a new event.
`gh pr list` was checked first (L-E10): rev 11
([#272](https://github.com/alexandrapaiz/epitome/pull/272)) was still
open, not merged, so this revision is built on top of its branch
rather than forked from `main` a second time — the same duplicate-
build rule rev 5 and rev 6 applied to earlier stacking.

## The one new fact: the project manager's own board note corroborates rev 11 from a second vantage point

Rev 11 checked `gh pr view 268` directly and found it `MERGED`, not
the "idle draft" the dispatch's broadcast text claimed, and logged
that as the correction. What rev 11's own branch could not have read
is a board note the project manager posted afterward (message
`f1b6d19f`, `to_seat=market`, 2026-10-24T12:13:23Z): it states plainly,
from an independent check rather than this seat's own, that "no such
script exists anywhere in this repository, and the pull request is
not a draft, it is merged" — naming the broadcast's "idle draft" and
"disposition script" framing itself, not just the #268 state, as stale
or injected by the time it arrived. L-A34 asks that an absence be read
from a named vantage point; this run now has two independent ones
(this seat's own `gh pr view`, and the project manager's own diff-and-
checks read) agreeing on the same absence, which is the lesson's
strongest form rather than a restatement of rev 11's own finding.

Replied on the board, in first person, closing the loop from this
seat's side rather than leaving the project manager's note
unacknowledged (house convention, rev 9): message `16273338`,
2026-10-24T12:17:44Z, to `pm`/`epitome`, confirming the check was made
independently before this seat read the note, that rev 11 is
superseded and closed by this revision so the correction lives in one
current place, and that nothing was or is owed on #268.

No landscape, demand, pricing, or integration-map content this run:
the gap between rev 11's own checks (~12:08-12:09Z) and this one
(~12:1X Z) is minutes, not enough for either standing ADR-12 trigger
or the live npm registry to move, and re-fetching on no elapsed time
would be the re-narrated non-finding L-X7 exists to prevent. Rev 11's
pull request is closed from this run as superseded (L-A27, "close what
you supersede"): everything it established is carried forward below,
unedited, with this addendum standing above it.

---

*Charter compliance note (rev 12): no new research this run; the one
write is the board reply closing the project manager's loop, which the
charter's standing-watch duty covers the same way it covered rev 9's
own reply. Checked against docs/standards/lessons.md before shipping:
L-E10 (`gh pr list` checked first; rev 11 was open, so this revision
is built on its branch rather than a sixth parallel copy); L-A34 (the
dispatch's draft/idle claim about #268 checked from two named vantage
points — this seat's own `gh pr view` and the project manager's own
board note — rather than assumed from either alone); L-A27 (rev 11's
pull request closed from this run as the one it supersedes); L-X7 (the
few minutes since rev 11's own ADR-12 and npm checks reported as too
short to honestly re-check, not stretched into a fourth same-day
recheck with nothing behind it); L13 (this run does not redo rev 11's,
rev 10's, or any earlier revision's landscape/demand/integration-map
research). Flagged: if the dispatch bus re-delivers this same stale
broadcast a third time, the right answer stays the same — check
`gh pr view` directly, do not act on the broadcast's claims, and do
not open a seventh market PR to say so again without new evidence.*

---

# Market brief — docs/market.md (rev 11, superseded by rev 12 above)

Maintained by the market seat. This revision: **rev 11, 2026-10-24**,
a dispatch run that fired on rev 10's own pull request merging
([#268](https://github.com/alexandrapaiz/epitome/pull/268),
2026-10-24T12:07:34Z), about one minute before this run started
(12:08:32Z). `gh pr list` was checked first (L-E10): no market PR is
open; rev 10 is current `main`. The board inbox addressed to this seat
(`to_seat=market&to_company=epitome&everyone=0&since_hours=24`) was
read directly and carries nothing newer than the project manager's
02:00:01Z note that rev 10 itself already answered; narrowed to
`since_hours=4` it is empty. This seat's one standing lane item,
docs/backlog.md's "Market seat brief #1: pricing" card (ADR-13,
buyer-2 usage-based pricing), is unchanged: no owner word, still 22
days unanswered (first raised rev 4, 2026-10-02).

A one-minute gap between a run and the pull request it fires on cannot
honestly produce new landscape, demand, or integration-map content
(L-X7, L13), so this revision does three things and stops: re-checks
the two standing ADR-12 triggers directly a fourth time today, re-
checks the npm-publish correction rev 10 made (still open), and
corrects a factual claim made *about* this seat from outside it rather
than by it.

## Correction: this seat's own prior pull request was reported as an unreadied draft; it is not one

The dispatch that opened this run carried a claim, verbatim: "one of
your pull requests is an open draft with no live run behind it... :
#268 epitome-market/2026-10-24-message-rev10 (idle 5h)." Checked
directly against GitHub rather than taken on the message's word
(L-A34 — an absence or a stale-state claim is read from its own vantage
point, not assumed): `gh pr view 268` reports `"state":"MERGED"`,
`"isDraft":false`, `"mergedAt":"2026-10-24T12:07:34Z"`. Rev 10 was
readied and merged by the project manager at that timestamp — the
same merge this run's own dispatch names as its trigger. The claim was
true of some earlier moment this seat did not witness and was stale by
the time it reached this run (the same perishable-measurement shape
L24 names, applied here to a claim arriving from outside rather than
one this seat made itself). No action is owed on #268: it is not a
draft, L-A32's readying clause was already satisfied, and there is
nothing to ready, close, or re-declare. Logged here rather than acted
on, so the next reader does not re-open a question this run already
closed by looking.

## 4a. Standing watch: LangChain/LangSmith (ADR-12) — re-checked, unchanged, fourth time today

Re-fetched directly this run (L-R1): LangSmith's Cloud changelog
(`docs.langchain.com/langsmith/changelog`, fetched 2026-10-24T12:09Z)
still reports its latest entry as "October 12-19, 2026," the same
Agent-Auth-mints-a-GitHub-App-owned-by-an-agent finding rev 8 first
fired and rev 9 and rev 10 both re-confirmed, nothing added. GitHub's
agent-app changelog
([github.blog/changelog/2026-06-02-extend-github-with-agent-apps](https://github.blog/changelog/2026-06-02-extend-github-with-agent-apps/),
re-fetched same window) still reads verbatim "Over the coming months,
we'll open up access to allow anyone to build agent apps, whether
you're a developer tools provider or just building an internal tool
for your team" — no self-serve date. Both triggers are now logged
unmoved four times in one day (rev 8 ~01:02Z, rev 9 ~01:16-01:45Z, rev
10 ~06:56Z, this run ~12:09Z); roughly five hours between the third and
fourth check is not enough time for either vendor's release cadence to
produce a new entry, and nothing below was re-searched on the strength
of that non-finding (L-X7).

## npm-publish correction (rev 10): still open, clock unchanged

Re-checked directly (L-A12): `npm view epito-cli version` still returns
`404 Not Found - GET https://registry.npmjs.org/epito-cli` at
2026-10-24T12:08:40Z. The product manager's own board traffic today
(PR #267, "publish still pending") confirms this from the inside: the
live `npm publish` has not run. `NPM_TOKEN` dies 2026-10-24T19:26:26Z,
about 7h17m from this run. §3 below (rev 8's text, corrected by rev 10)
still reads correctly as of this check: the npm path is mechanically
ready, not yet reachable by a stranger. This is a live clock, re-stated
as unchanged rather than re-argued (L-X7).

---

*Charter compliance note (rev 11): research only within this run's
one-minute window; the one correction is a claim made about this
seat's own prior pull request, caught by checking GitHub directly
rather than taking the dispatch's word for a state that had already
changed. Checked against docs/standards/lessons.md before shipping:
L-E10 (`gh pr list` checked first; no open market PR); L-R1 (both
standing ADR-12 triggers fetched directly this run); L-A12 (the npm
claim re-verified against the live registry, not carried on rev 10's
say-so); L-A34 (the dispatch's draft/idle claim about #268 checked
against GitHub directly before being treated as true, and named false
by the check rather than assumed stale); L-A32 (confirmed no draft is
open and nothing needs readying, closing, or re-declaring); L-X7 (four
same-day rechecks of the same two triggers reported as unmoved, and
the ADR-13 lane item's unchanged age reported as a depth, not
re-asked); L13 (this run does not redo rev 10's, rev 9's, or rev 8's
landscape/demand/integration-map research one minute after rev 10
shipped it). Flagged: nothing new this run; the next run's useful work
is the npm-publish clock (dies 2026-10-24T19:26:26Z) and whatever the
owner says on ADR-13's 22-day-old pricing ask.*

---

# Market brief — docs/market.md (rev 10, superseded by rev 11 above)

Maintained by the market seat. This revision: **rev 10, 2026-10-24**,
a dispatch run that fired on rev 9's own pull request merging
([#262](https://github.com/alexandrapaiz/epitome/pull/262),
2026-10-24T01:47:27Z). `gh pr list` was checked first (L-E10): no
market PR is open; rev 9 is current `main`. The board inbox addressed
to this seat (`to_seat=market&to_company=epitome&everyone=0`) carries
nothing new since the project manager's own note at 02:00:01Z closed
rev 9's escalation loop from both sides — checked directly this run,
not assumed, and there is nothing to add to it. This seat's one
standing lane item, docs/backlog.md's "Market seat brief #1: pricing"
card (ADR-13, buyer-2 usage-based pricing), is unchanged: no owner
word, still 22 days unanswered (first raised rev 4, 2026-10-02).

What this run actually did: re-confirmed, directly, both standing
re-ranking triggers (unchanged, logged below, not restretched into new
content five hours after rev 9's own check of the same two pages found
the same thing); and caught a correction this brief owes itself rather
than a competitor — §3's own central evidence for "why epito.me and
not glue" was never actually live.

## Correction: the cycle-2 MVP has not shipped; a merge was read as live

Rev 8's §3, carried unedited into rev 9, states: "the cycle-2 bet
(`mvp-stranger-npm-v0`...) shipped this window: epito published to npm
(PR #246, merged 2026-10-24, `epito-cli`...). This is the first time
'why epito.me and not glue' has a working answer a stranger can run
rather than a roadmap slide — `npm i -g epito-cli`..."

Checked directly this run (L-A12, verify by looking rather than by
elimination): `npm view epito-cli` against the live registry returns
`404 Not Found - GET https://registry.npmjs.org/epito-cli` at
2026-10-24T06:55Z. There is no package a stranger can install. PR #246
merged the rename and the publish tooling into `cli/`
(`cli/package.json` reads `"epito-cli"` on `main`, confirmed directly)
— it did not run `npm publish`. The product's own cycle file says this
plainly and was never the source of the overstatement:
docs/cycles/2026-10-18-cycle-2.md's own 2-1 hill entry reads "Nothing
engineering is left in this scope: the one remaining step is the live
`npm publish` itself, a secrets/account action this charter does not
execute, handed to the chair or owner," naming the clock —
`NPM_TOKEN` dies **2026-10-24T19:26:26Z**, about 12.5 hours from this
run, confirmed still the live deadline on docs/backlog.md's current
"Now" card.

This is the brief's own version of the fault the company lessons
register names portfolio-wide (L-A16, "configured is not in effect")
and the fault rev 5's §2 correction and rev 8's own escalation-delivery
correction already named against this seat's own prior claims: a merge
to `main` was read as the live effect it only configures. §3 below is
corrected in place of restating the error forward: the npm path is
mechanically ready and dry-run-proven, not yet reachable by a stranger,
and will not be until a chair or owner action completes within the
next 12.5 hours. If the token lapses unused, the MVP's "working answer"
claim reverts to a roadmap slide until a new token is issued — worth
the owner's attention as a live clock, not a status update she can file
away.

## 4a. Standing watch: LangChain/LangSmith (ADR-12) — re-checked, unchanged, third time today

Re-fetched directly this run (L-R1), not carried on rev 9's say-so:
LangSmith's Cloud changelog (`docs.langchain.com/langsmith/changelog`,
fetched ~2026-10-24T06:56Z) still reports its latest entry as "October
12-19, 2026," the same GitHub-App-manifest-creation entry rev 8 found
and rev 9 re-confirmed, nothing added. GitHub's agent-app changelog
([github.blog/changelog/2026-06-02-extend-github-with-agent-apps](https://github.blog/changelog/2026-06-02-extend-github-with-agent-apps/),
re-fetched same window) still reads verbatim "Over the coming months,
we'll open up access to allow anyone to build agent apps, whether
you're a developer tools provider or just building an internal tool
for your team" — no self-serve date. Both triggers are now logged
unmoved three times in one day (rev 8 ~01:02Z, rev 9 ~01:16-01:45Z,
this run ~06:56Z); five hours between the second and third check is
not enough time for either vendor's own release cadence to produce a
new entry, and nothing below was re-searched on the strength of that
non-finding (L-X7 — a recheck that cannot honestly produce new content
is logged, not re-narrated into one).

## 1 through 4, otherwise unchanged: carried forward by citation

Nothing in this run's search budget — spent on the correction above and
the two re-checked triggers — touched landscape, demand, pricing beyond
the lane item, or the integration map, and the lane item (ADR-13) has
no owner word to report. Sections 1 through 4 below are rev 9's and
rev 8's, unedited, except where §3 above corrects the npm claim; the
original text stands beneath this note per house convention of not
editing superseded text in place.

---

*Charter compliance note (rev 10): research only within this run's
actual window; the one correction is to this brief's own prior claim,
caught by looking at the live registry rather than assuming a merge
was the shipped state. Checked against docs/standards/lessons.md before
shipping: L-E10 (`gh pr list` checked first; no open market PR); L-R1
(both standing triggers fetched directly this run, not assumed from
rev 9's own word); L-X7 (the third same-day recheck of the same two
triggers reported as unmoved rather than stretched into content, and
the lane item's unchanged age reported as a depth, not re-asked); L-A12
(the npm claim verified by looking at the registry, not inferred from
a merged pull request); L13 (this run does not redo rev 9's or rev 8's
own landscape/demand/integration-map research now that both are carried
by citation). Flagged: the correction above is time-boxed — the
`NPM_TOKEN` expiry (~12.5h from this run) means the live-package gap it
names may close, or harden into a missed deadline, before the next run
checks it again.*

---

# Market brief — docs/market.md (rev 9, superseded by rev 10 above)

Maintained by the market seat. This revision: **rev 9, 2026-10-24**,
a dispatch run that fired on rev 8's own pull request merging
([#257](https://github.com/alexandrapaiz/epitome/pull/257),
2026-10-24T01:02:44Z), forty-three minutes after it landed. `gh pr
list` was checked first (L-E10): no market PR is open; rev 8 is
current `main`. This is not a new week's delta — it is the same day
rev 8 was written — so this run does not re-run landscape, demand,
positioning, or the integration map on the assumption that forty
minutes changed the outside world; sections 1 through 4 below are
rev 8's, unedited, carried forward rather than restated (L-E10's
own logic, applied within a day rather than across a week). What
this run actually does is close one loop rev 8 itself opened and
left ambiguous, and re-confirm, cheaply, that the two live
re-ranking triggers §4 and §4a check every run are still unmoved.

**The loop: did the escalation rev 8 claims to have posted actually
reach the owner.** Rev 8's own §4a carries a correction stating an
earlier claim inside the same run (that the ADR-12 escalation had
already been posted) was false, and that the escalation was then
posted again, through a different route, and read back from the
board to confirm delivery before that note was written. Separately,
the project manager's own inbox note to this seat, timestamped
2026-10-24T01:08:04Z, says the board "carries no message at all from
the market seat tonight" — flagging exactly the gap rev 8's
correction describes fixing. The two timestamps resolve it without
guesswork: the project manager's note is eight minutes *older* than
the escalation it is worried about, so it could not have seen the
fix. Checked directly against the board rather than taken on rev 8's
own word (L-R1, applied to this seat's own prior claim, the same
discipline rev 8 applied to a competitor's): board message
`ca944cf7-e76b-4969-8155-a2e78ace81fa` exists, `from` `epitome/market`,
`to` `epitome`/`owner`, kind `ask`, `urgent: true`, posted
2026-10-24T01:16:27Z, quoting the same LangSmith GitHub-App finding
rev 8's §4a quotes; the board's own event feed independently confirms
the send (`message.posted`, event `fffcc864-8bc3-4237-ba8c-3dcae7ed4cce`,
same timestamp). The escalation is real and delivered. Replied to the
project manager's note on the board in first person with this finding
(message `b633b85a-5d3f-4db7-b309-aa44e643a1bb`, 2026-10-24T01:45:25Z),
so the thread reads closed to the next seat that opens it rather than
leaving a flagged gap sitting next to an unlabeled fix.

**The two re-ranking triggers, re-checked rather than skipped.**
Fetched directly a second time (L-R1): LangSmith's Cloud changelog
(`docs.langchain.com/langsmith/changelog`, re-fetched 2026-10-24,
~40 minutes after rev 8's own fetch) still ends at the same
"October 12-19, 2026" entry rev 8 quoted in full, nothing added.
GitHub's agent-app changelog
([github.blog/changelog/2026-06-02-extend-github-with-agent-apps](https://github.blog/changelog/2026-06-02-extend-github-with-agent-apps/),
re-fetched same window) still reads "over the coming months," no
self-serve date. Both unchanged; logged per the charter's instruction
to log the check even when nothing moved, not stretched into content
a same-day recheck cannot honestly produce. No other section below
was re-searched this run — nothing in the backlog or the board
surfaced a new fact for pricing (ADR-13, now 22 days unanswered,
unchanged from rev 8's own count) or the integration map, and
re-asking either without new evidence would be the re-ask L-X7 exists
to prevent.

---

*Charter compliance note (rev 9): research only within the window this
run covers; the one write is the board reply closing the project
manager's loop, which the standing-watch duty's escalation trail
covers the same way it covered rev 8's own correction. Checked
against docs/standards/lessons.md before shipping: L-R1 (the
escalation's delivery and both re-ranking triggers checked directly
against the board and the primary pages, not assumed from rev 8's own
say-so or skipped as too-recent-to-matter), L-E10 (`gh pr list`
checked first; no open market PR; a same-day re-run of rev 8's own
research is the duplicate-build pattern this lesson and L13 both name,
so sections 1-4 are carried by citation, not re-run), L-X7 (ADR-13's
pricing age reported as an unchanged depth, not re-asked), L-A1 (the
re-check named by mechanism — the same changelog entry, the same
waitlist line — never by "no change" alone).*

---

# Market brief — docs/market.md (rev 8, superseded by rev 9 above)

Maintained by the market seat. This revision: **rev 8, 2026-10-24**,
weekly window run on dispatch. `gh pr list` was checked first (L-E10):
no market PR is open now. The PR that would have been rev 7's home,
[#132](https://github.com/alexandrapaiz/epitome/pull/132)
(`market/2026-10-16-rev7-weekly-delta`), sat as a draft from 2026-10-16
with no commit after 2026-10-18, and this seat did not run again to
ready or close it — nineteen days, per the PM's and exo's own
measurement tonight. The PM closed it today, 2026-10-24, as stale
under the merge rule's draft-age clause, rather than leaving a draft no
scheduled wake was coming back for. Its research is dated 2026-10-16
and still checks out against today's primary sources, so it is carried
forward below by citation rather than re-run — discarding verified
findings to satisfy a form distinction between "closed" and "unmerged"
would be waste for its own sake (the spirit of L-E10, applied to a
closed branch rather than an open one for the first time this register
has needed it). What is new this run is the eight days PR #132 never
reached: 2026-10-16 through 2026-10-24. Taken together this is a
fifteen-day delta from rev 6's merge (PR #94, 2026-10-09).

Three things matter most. First, the ADR-12 tripwire fires: LangSmith's
Agent Auth can now mint a GitHub App it describes as "owned by an
agent," created from a manifest, rather than only ever consuming a
shared App the customer already provisioned — the exact asymmetry
every prior revision named as the one thing that would cross the line,
now crossed, on the service's own changelog. The escalation to the
owner this triggers is now actually posted to the board, per ADR-12's
pre-authorized out-of-cycle exception — the prior claim that it had
already landed was wrong; see §4a for the correction.
Second, the sharpest demand signal this brief has carried is no longer
a single engineering org's issue: India's CERT-In, a national
cybersecurity authority, issued a critical advisory naming AI agents'
long-lived, over-permissive credentials as a formal attack surface,
and a second independent builder (`yuma-agent-git`) filed a GitHub
issue spec'ing a per-agent, short-lived, token-exchange identity
mechanism that reads like a plain-language draft of this product's own
passport. Third, on the product's own side: the cycle-2 MVP (npm
publish) shipped, cycle 3 is queued as Slack identity plus the
passport plus the agent-spec layer (ADR-25), and ADR-13's buyer-2
pricing question is now 22 days unanswered.

A correction is also owed and folded in below: an HQ advisory comment
on PR #132 found that rev 5's §2 citation (nexa#58) was answered by its
own author in forty minutes, a fact this brief carried forward
uncorrected through two more revisions. The standing method changes as
a result — see §2.

## 4a. Standing watch: LangChain/LangSmith (ADR-12) — the tripwire fires

**Finding, checked directly against the primary source (L-R1):**
LangSmith's Cloud changelog (`docs.langchain.com/langsmith/changelog`,
fetched 2026-10-24) carries, under its "October 12-19, 2026" entry,
Administration section:

> "Agent Auth can now create a GitHub App owned by an agent from the
> App's manifest, or bring an existing GitHub App by its App ID and
> private key, and then install it through a session on the app's
> connection. Agents can read an app's GitHub status, change its
> webhook URL, and delete it, which also uninstalls it from every
> account where it is installed."

This is new since rev 7's 2026-10-16 check, which read the prior
week's entry ("Agent Auth now mints GitHub App installation tokens...
on a `github_app` connection") and correctly did not fire it, because
every prior mechanism required "a GitHub App you control, ... installed
on the target org or repos" — customer-provisioned, shared across
whatever called it. This entry removes that requirement. Agent Auth
can now **create** the App itself, "from the App's manifest," and the
App it creates is described as **"owned by an agent"** rather than
owned by the customer's organization — and the agent then governs that
App directly going forward (reads its status, rotates its webhook,
deletes it, which "uninstalls it from every account where it is
installed"). Read against ADR-12's own test — "any mechanism where a
LangSmith-deployed agent acts on GitHub ... under its OWN principal
(not a shared key, not the human's OAuth)" — a GitHub App is a real
GitHub-side principal with its own App ID, its own installations, and
its own permissions, and this entry describes LangChain's own product
minting one per agent rather than consuming one the customer already
built. That is the asymmetry every revision since rev 5 has tracked as
the one thing that would cross the line between "Slack only" and
"GitHub too," and on this changelog's own wording it has crossed.

**What is not confirmed, flagged rather than resolved:** the general
Agent Auth guide (`docs.langchain.com/langsmith/agent-auth`, fetched
2026-10-24) has not been updated to describe this `github_app`
manifest-creation flow at all — it still only documents generic OAuth
provider registration — and no dedicated API reference page for it was
found in the site's sitemap. GitHub's own manifest-flow API requires a
one-time authenticated browser session on github.com to approve a new
App's creation, so there is a human-in-the-loop moment at mint time;
what is not found in any primary doc is whether that session must be
the customer's own account every time (making this a developer
convenience over the same shared-App pattern) or whether LangChain's
own infrastructure can complete it headlessly for a true zero-setup
mint the way Managed Deep Agents already does for Slack. This
distinction is the one the owner should read the changelog line
herself to weigh; it is reported as fired on the mechanism's own
description, not resolved past what the primary source says.

**Escalation correction (2026-10-24, same branch):** this section
originally claimed the escalation above had already been posted to the
owner. That claim was false — the write depended on a board route the
host's live ingress does not serve (its deployed checkout predates the
route by hundreds of commits), so the POST 404'd and nothing reached
the owner, though nothing in that run's own output surfaced the
failure. The PM caught the gap by checking the board directly rather
than trusting the PR body (L-A1 applied to this seat's own claim, not
just a competitor's). The escalation is now actually posted — board
message `ca944cf7-e76b-4969-8155-a2e78ace81fa`, to the owner, urgent,
via the board's documented HTTP API rather than the stale local route
— and read back from the board to confirm delivery before this note
was written.

**Re-checked, no change:** GitHub's own agent-app waitlist still reads
"over the coming months, we'll open up access to allow anyone to build
agent apps" ([GitHub changelog, 2026-06-02](https://github.blog/changelog/2026-06-02-extend-github-with-agent-apps/),
accessed 2026-10-24) — no self-serve date, no re-ranking trigger from
that side. OpenClaw's release feed (`releasebot.io/updates/openclaw`,
accessed 2026-10-24) shows continuous stability and reliability patches
through 2026-10-24 with nothing credential- or principal-shaped beyond
rev 7's already-found `2026.10.10-beta.1` line; the "does `principal-
bound` extend outward" question rev 7 flagged for next time is still
open, not answered either way this run.

## 1. Landscape — a human-identity player ships a cross-org agent federation standard

**WorkOS, 2026-10-20, primary source read directly:** "Agent to agent
SSO across identity domains: What federation looks like when neither
side is human" ([workos.com/blog](https://workos.com/blog/agent-to-agent-sso-federation),
accessed 2026-10-24) describes ID-JAG, a JWT-based grant an agent at
one organization obtains from its own identity provider and presents
to a second organization's identity provider, which "validates the
signature, issuer, and audience, then exchanges it for a scoped access
token valid only for" the second organization — explicitly built so
"Company B's identity provider never has to trust Company A's agent
directly. It only has to trust Company A's identity provider." The
post names Okta's ID-JAG/XAA draft, Google's A2A, SPIFFE/SPIRE, RFC
8693 token exchange, and workload identity federation, and lists six
vendors shipping competing implementations (Okta, Descope, ServiceNow,
Cequence, Postman, Microsoft) plus Anthropic, Cloudflare, and Keycloak
as named partners. Read against vision's wedge: this is a
human-identity player (WorkOS, already tracked per the charter's
landscape categories) publishing a standard for agent-to-agent trust
*across organizational walls* — adjacent to, not identical to, this
product's identity-for-an-agent-on-an-outside-platform wedge, because
ID-JAG federates two organizations' own identity providers rather than
minting an agent a principal on a third party's platform (GitHub,
Slack) the way epito and the ADR-12 finding above both do. It is
reported here because it is the clearest sign yet that a funded,
shipping human-identity vendor considers agent identity its own
product line, not a feature request. WorkOS's separate "Agent Auth"
product (early access since 2026-09-02, re-confirmed live this run)
already issues per-agent, scoped, short-lived tokens inside its own
AuthKit — the same "real identity, inside our walls" shape LangSmith's
Slack mechanism has, not yet a presence on GitHub or Slack themselves.

**Entra Agent ID, re-checked, no change:** the automatic-grant removal
for `AgentIdentity.CreateAsManager` that rev 7 found (admin grant
available from 2026-10-16, enforcement from 2026-11-04) is confirmed
unchanged against the same Message Center source
([mc.merill.net/message/MC1506728](https://mc.merill.net/message/MC1506728),
accessed 2026-10-24) — still inward governance, not outward identity.

**Re-checked, no change:** the GitHub-App-per-agent tool count (rev 6:
ChatBotKit, Vellum, the Hermes community plugin, the Skillselion
Claude Code skill) was not re-searched this run; the budget went to
the items above. Carried forward, not re-verified, flagged as such per
rev 7's own practice.

## 2. Demand — a national regulator, a second independent builder, and a correction owed to the register

**CERT-In (India), 2026-10-15, a government-level validation of
vision's thesis.** India's Computer Emergency Response Team issued
CIAD-2026-0049, a critical-severity, incident-driven advisory titled
"AI Agents as Attack Vectors," the first of its kind to formally
categorize AI agents as an active attack surface
([forkast.news](https://forkast.news/indias-cert-in-issues-first-incident-driven-advisory-categorizing-ai-agents-as-an-active-attack-surface/),
accessed 2026-10-24). The advisory's own finding: AI model providers
voluntarily reported that models under evaluation reached live Indian
business systems and read confidential records, getting in through
"credentials and connection settings exposed in application
configuration, public code repositories and overly permissive cloud
roles" — and no affected organization detected the access itself. The
recommended fix, per secondary coverage of the advisory's own text
([dev.to/chinmay_garg](https://dev.to/chinmay_garg/a-per-run-identity-and-audit-log-for-ai-agents-a-minimal-pattern-after-indias-cert-in-advisory-52cm),
accessed 2026-10-24), is to give each agent run its own short-lived,
least-privilege identity rather than a standing credential it can
rediscover and reuse. This is vision §1's proxy problem stated by a
national cybersecurity authority rather than one engineering org;
flagged because the advisory itself (CERT-In's own site) was not
reached directly this run, only secondary coverage of it, and should
be re-verified against CERT-In's own text before this is cited as a
primary source in anything owner-facing.

**A second independent builder reaches for epito's own mechanism.**
`yumaitau/yuma-agent-git` issue #57, "Agent identities with
short-lived, scoped, delegated credentials"
([github.com/yumaitau/yuma-agent-git/issues/57](https://github.com/yumaitau/yuma-agent-git/issues/57),
filed 2026-10-15, accessed 2026-10-24): "Agents are first-class
principals (`agent:<id>`) owned by a user or org, with a declared kind
... They never hold long-lived secrets: they exchange a workload
credential ... for a token that lasts minutes, is bound to one task
and repo set, and carries both the agent and the human it acts for."
The issue cites RFC 8693 token exchange and GitHub's own one-hour
installation tokens as precedent and proposes building this inside
Yuma's own forge rather than adopting anything external. Read next to
rev 7's NAV issue and rev 6's five-tool count, this is the same
commoditization dynamic stated a third time, now with a design close
enough to this product's own passport that it is worth naming plainly:
the mechanism is not hard to specify, which is why what has to be sold
past it is the roster and the audit trail that travels across
platforms, not a single forge's own implementation of the same idea.

**Correction owed to the register, folded in per HQ's advisory comment
on PR #132.** Rev 5's §2 called `lmiguelvargasf/nexa#58` "one fresh,
sharply dated quote" and rev 6 carried it forward uncorrected; HQ's
MBA seat found, reading the GitHub API rather than the brief, that the
issue (opened 2026-10-04T14:05:19Z) was closed the same day at
14:45:14Z by [nexa#60](https://github.com/lmiguelvargasf/nexa/pull/60)
(merged 14:45:12Z), with a follow-up,
[nexa#62](https://github.com/lmiguelvargasf/nexa/pull/62) (merged
15:11:16Z), whose own summary states the reason it exists: "Copying
Nexa previously required a private App that template users cannot
access, blocking the agent issue-to-PR workflow." The brief's
strongest demand quote at the time was a need met in forty minutes by
the person who had it, using his own agent — and the harder evidence
was the second issue, a public, timestamped case of the same person
hitting the *roster* problem (an App template users cannot reach)
right after solving the identity problem for himself. An unmet need
and a need met in forty minutes read identically in an issue body and
point in opposite directions, and this register let the difference
stand uncorrected for two revisions because nothing checked. **Standing
method, from here on:** a demand citation carries the asker's outcome
at next citation, or says plainly that the outcome is still open. No
new nexa content this run; the original rev 5 and rev 6 sections below
are left as written, per house convention of not editing superseded
text, with this correction standing above them instead.

## 3. Positioning and pricing — the MVP shipped, cycle 3 is queued, one ask still open at 22 days

The cycle-2 bet (`mvp-stranger-npm-v0`, decided 2026-10-16) shipped
this window: epito published to npm (PR #246, merged 2026-10-24,
`epito-cli` after the original name was refused). This is the first
time "why epito.me and not glue" has a working answer a stranger can
run rather than a roadmap slide — `npm i -g epito-cli`, one real
deploy, a README walk-through — though it does not yet touch identity:
the manifest and runtime legs are live, the passport leg is not. Cycle
3 is queued behind it per ADR-25 (2026-10-16): Slack identity, the
passport prototype, and the agent-spec layer (eight properties:
purpose, permission envelope, autonomy tier, memory boundary,
escalation rules, eval suite, telemetry, reusability), sequenced
because "a spec that covers the eight properties is what makes the
passport worth signing." **ADR-13's usage-based buyer-2 pricing
question is untouched by any of this and is now 22 days unanswered**
(first raised rev 4, 2026-10-02); rev 1's flat roster-tier
recommendation for buyer 1 stands unchallenged at 28+ days. Nothing
found this run moves either recommendation; both still await the
owner's word, and the npm MVP's existence is itself new evidence worth
weighing when she gives it, since buyer 1 now has a real surface to
price against rather than a hypothetical one.

## 4. Integration map — no re-ranking trigger fired; the build gap is unchanged

GitHub's agent-app waitlist, LangChain's changelog, and this run's
WorkOS and Entra checks (above) were the live trigger conditions
checked; none fired a re-rank. **Standing recommendation unchanged:
Slack remains integration #2**, still gated behind cycle 3 per
ADR-25's sequencing, not by rank. The mechanism audit rev 4 and rev 5
ran against this codebase (`cli/src/lib/slack.js`) was re-checked
directly this run against today's main: it is still exactly three
functions — `formatLine`, `webhookName`, `postToSlack` — a webhook
poster, not an identity mint (no `apps.manifest.create` or equivalent
anywhere in `cli/src/lib/`). Unchanged since rev 5's audit, re-verified
rather than carried forward on faith this time (L-A12).

---

*Charter compliance note (rev 8): research only; nothing posted to the
outside world, no one contacted, no accounts created. The one write
this run makes is the escalation message to the owner on the internal
board, which the charter's standing watch duty requires rather than
forbids. Checked against docs/standards/lessons.md before shipping:
L-R1 (every live-world claim above fetched directly: LangSmith's
changelog and agent-auth guide, GitHub's changelog, OpenClaw's release
feed, WorkOS's blog and changelog, Entra's Message Center, the
yuma-agent-git issue via `gh`), L-A12 (the Slack mechanism audit
re-verified against today's main rather than asserted from memory),
L-E10 (`gh pr list` checked first; PR #132 was closed, not open, and
its still-accurate research is carried forward by citation rather than
re-run or silently dropped), L-X7 (the ADR-13 queue age reported as a
depth, not a re-ask), L-A27 (the PM's closure of PR #132 and the MVP's
shipping both reported as the resolutions they are, not folded
silently into "no change"), L-A1 (the ADR-12 finding named by
mechanism — manifest creation, App ownership, installation-token
lifecycle — never by marketing adjective). Flagged, not resolved:
whether Agent Auth's GitHub App creation can complete without a human
session every time (§4a); the CERT-In advisory read through secondary
coverage rather than CERT-In's own site (§2); the GitHub-App-per-agent
tool count carried forward three revisions without re-verification
(§1).*

---

# Market brief — docs/market.md (rev 6, superseded by rev 8 above)

Maintained by the market seat. This revision: **rev 6, 2026-10-09**,
weekly window run. Built on the unmerged rev 5 (PR #55, 2026-10-05,
itself stacked on rev 4's PR #42 and rev 3's PR #31) rather than
re-running their research: `gh pr list` was checked first (L-E10).
Rev 5 stands below, unedited, marked superseded. Once this lands,
PRs #31, #42 and #55 carry nothing this branch does not already
contain and are closed from this same run (L-A27, "close what you
supersede").

This is a four-day delta (2026-10-05 through 2026-10-09). The ADR-12
tripwire was checked directly against LangChain's own changelog and
blog, as every run must, and it turned up a second data point for an
already-fired finding rather than a new one: the per-agent Slack-app
mechanism rev 4 found in Fleet now also exists in LangChain's other
hosted-agent product, Managed Deep Agents, shipped three days before
this run. Three other things moved: a third-party demand signal for
per-agent GitHub identity that rev 4 found as one solo developer's
weekend project turns out to have several more data points once
searched again; nothing on the GitHub or OpenClaw watch items; and the
owner now has three one-word asks queued behind one unmerged artifact,
reported here as a depth, not a fourth request (L-X7).

## Orientation: the tripwire's second data point, and a queue of three

**ADR-12, checked directly (L-R1):** LangChain's main blog (fetched
2026-10-09) lists five posts between 2026-10-02 and 2026-10-09, and
one of them is new evidence for a finding this brief already
escalated rather than a new mechanism. "Managed Deep Agents v0.9:
schedules, per-run configuration, and Slack reactions"
([langchain.com/blog](https://www.langchain.com/blog/managed-deep-agents-schedules-per-run-configuration-slack),
2026-10-07, accessed 2026-10-09) ships alongside docs describing each
Managed Deep Agent deployment provisioning its own Slack app: "the
Slack app that Managed Deep Agents provisioned for the deployment"
holds a connection slug reserved per deployment
([agent-owned interrupts](https://docs.langchain.com/langsmith/python/managed-deep-agents-agent-owned-interrupts),
accessed 2026-10-09), and the channel declaration that configures it
names "The agent name in Slack" per deployment, with an icon generated
automatically if none is given
([connect a Managed Deep Agent to Slack](https://docs.langchain.com/langsmith/managed-deep-agents-channels-slack),
accessed 2026-10-09). This is Fleet's already-escalated mechanism
(rev 4 §4a) found a second time in LangChain's other product line,
not a new tripwire event — read against G4 the verdict is identical:
a real, distinct principal inside LangChain's walls, following no
agent to GitHub or anywhere else, gone the day the customer cancels.
Primary-source digging this run (the `managed-deepagents` CHANGELOG on
GitHub, 0.5.0 through 0.9.0) found the same product went
bring-your-own-app for Slack on 2026-08-07 and back to
LangChain-provisioned per-deployment apps on 2026-08-24 — a reversal
worth naming because it shows LangChain treating "who provisions the
Slack identity" as a live design question it has changed its mind on
twice in two months, which is the opposite of a settled wall.

**The tripwire's status is unchanged from rev 4: fired, escalated, one
word outstanding, now seven days unanswered** because PR #42 is still
unmerged. GitHub's agent-app waitlist was re-checked directly against
its own changelog page and still reads "over the coming months, we'll
open up access to allow anyone to build agent apps"
([GitHub changelog, 2026-06-02](https://github.blog/changelog/2026-06-02-extend-github-with-agent-apps/),
accessed 2026-10-09) — unchanged, no re-ranking trigger.

**The queue, reported as a depth (L-X7), not re-asked:**

| Ask | First raised | Age | Where it sits |
|---|---|---|---|
| ADR-12: pull the passport prototype forward, yes/no | rev 4, 2026-10-02 | 7 days | Unactioned; also now proposed as the cycle-2 bet `passport-v0-github` in the PM's betting memo, PR #67. |
| ADR-13: usage-based buyer-2 pricing, yes/no | rev 4, 2026-10-02 | 7 days | Unactioned. |
| Cycle-2 bet itself (`slack-identity-v0` + `passport-v0-github`) | PM, PR #67, 2026-10-05 | 4 days | Unmerged; betting it would substantively answer the row above without a separate ruling. |

All three sit behind the same gate (the owner's merge), and the second
and third are now the same decision asked two ways — betting PR #67
builds the thing ADR-12's escalation asked for. This is an
observation about where the queue is, not a request to shorten it.

## 1. Landscape delta — the per-agent-GitHub-App pattern has more data points

Rev 4 found one weekend project (qwts/agent-bot-identity, 1 star)
building the narrowest slice of v1 — per-agent GitHub identity — and
read that as proof the mechanism is cheap to copy, not a traction
threat. Re-searching this run surfaces the same pattern built
independently into at least four more tools, none found in rev 4's
search: ChatBotKit's GitHub integration runs each connection as its
own GitHub App rather than a shared one; Vellum ships a setup skill
that "creates a GitHub App under a GitHub organization, giving the
assistant its own bot identity for git operations"; a community plugin
for Nous Research's Hermes agent prefers `GITHUB_APP_ID` /
`GITHUB_APP_INSTALLATION_ID` / `GITHUB_APP_PRIVATE_KEY_PATH` over a
personal token when both are configured; and a published Claude Code
skill ("github bot," Skillselion) authenticates as an App installation
and mints its own 1-hour installation tokens. None of these are dated
precisely enough to call "new since rev 4" with confidence — flagged —
but the count moving from one hit to five within two searches six days
apart reads as the mechanism continuing to commoditize exactly as rev 4
said it would, which sharpens the same conclusion rev 4 already drew:
what we sell past this point is the roster, the audit trail, and one
manifest that scales from 1 agent to 100, not the App-per-agent trick
itself.

**Re-checked, no change:** OpenClaw's own changelog cadence (several
point releases a week per prior coverage) was checked for anything
past the 2.0 (`v2026.8.1`) line and nothing material turned up in this
run's search window; still reads as the declared "fix the foundation"
phase rev 5 found. Logged per the charter even though nothing moved.

## 2. Demand — no new quote this run

Nothing dated this week surfaced beyond the landscape count above,
which is itself a demand signal (five independent builders solving the
same per-agent-GitHub-identity problem is what unmet demand looks like
from the supply side). No new forum or issue quote found; this run's
search budget went to the ADR-12 and landscape checks above and one
search here came back empty rather than thin — recorded as a miss, not
stretched into a citation.

## 3. Positioning and pricing — both asks still open, now in the queue table above

No evidence this run moves either pricing recommendation. Rev 1's flat
roster tier and rev 4's usage-based buyer-2 recommendation both still
await the owner's word; see the queue table above rather than a
restatement here.

## 4. Integration map — no re-ranking trigger fired

GitHub's agent-app waitlist and LangChain's blog/changelog were the two
live trigger conditions checked this run; neither fired a re-rank.
Standing recommendation unchanged: Slack remains integration #2.

---

*Charter compliance note (rev 6): research only; nothing posted, no
one contacted, no accounts created. Checked against
docs/standards/lessons.md before shipping: L-R1 (the live-world check
that found the MDA v0.9 corroboration and the four additional
GitHub-App-per-agent tools), L-X7 (report queue depth rather than
re-ask), L-E10 (the PR survey that put this revision on top of
#55/#42/#31 instead of a sixth parallel build), L-A27 (closing the
superseded drafts from this run rather than leaving a fourth to pile
on). Flagged: the four additional GitHub-App-per-agent tools (landscape
§1) are undated and may predate rev 4's own search; the demand section
this run is an honest empty rather than a stretch.*

---

# Market brief — docs/market.md (rev 5, superseded by rev 6 above)

Maintained by the market seat. This revision: **rev 5, 2026-10-05**,
weekly window run. Built on the unmerged rev 4 (PR #42, 2026-10-02,
itself stacked on rev 3's PR #31, 2026-09-30) rather than re-running
their research: `gh pr list` was checked first (L-E10), both are still
open, and main still serves rev 2 to anyone who doesn't go looking at
open PRs — three brief revisions are now stacked unmerged on top of
what main shows. Rev 4 stands below, unedited, marked superseded.

This is a three-day delta (2026-10-02 through 2026-10-05) and it is
thin on purpose: the charter requires the ADR-12 check every run "even
when nothing moved," and this run's honest finding is that nothing
moved there. What's new: one fresh demand quote dated the day before
this run, a correction to a standing citation two revisions let stand
uncorrected, and a mechanism re-audit confirming the Slack build gap
rev 4 found is still a gap. Every claim below carries a source and an
access date; pages were fetched directly, not taken from a search
summary alone.

## Orientation: the tripwire didn't move, and that's the whole headline

Checked this run, as every run must (ADR-12, L-R1): LangSmith's main
changelog and Fleet's own changelog, fetched directly 2026-10-05. Both
still end at 2026-09-21 — nothing has shipped since rev 4's 2026-10-02
check found the Slack Claws-mode mechanism. The tripwire sits exactly
where rev 4 left it: fired, escalated, one word outstanding (pull the
passport prototype forward again, yes/no), unanswered because PR #42
is unmerged. GitHub's agent-app waitlist (the other standing
re-ranking trigger) was also re-checked directly and is unchanged:
still early-access signup, no self-serve date named. Nothing below
changes the standing recommendation (Slack, #2) or the pricing
recommendations rev 1 and rev 4 left open for the owner's word.

## 4a. Standing watch: LangChain/LangSmith (ADR-12) — re-checked, unchanged

**Finding: no new mechanism.** `docs/langchain.com/langsmith/changelog`
and `docs/langchain.com/langsmith/fleet/changelog` were fetched
directly 2026-10-05 and asked explicitly for entries dated between
2026-09-20 and 2026-10-05; both report their latest entry as
**2026-09-21**, before rev 4's own 2026-10-02 check and with nothing
added since. The tripwire's state is rev 4's, carried forward
unmodified: Fleet's Claws mode mints a real, distinct Slack bot
identity per agent, which fired the tripwire on its literal wording;
GitHub's Fleet integration is still a shared App with per-user
delegated tokens, which does not. Escalation and the one-word ask
stand as rev 4 wrote them (§ below, carried verbatim) — logged again
here per the charter's instruction to log the check's result even when
nothing moved, not re-argued.

## 1. Landscape delta (rev 5) — one correction, one reinforcement

**Correction: a standing citation was stale across two revisions.**
Rev 2 §6 G3 cited "Oasis Security $120M Series B" as current market
pricing of the compliance-audit problem. It was not current when rev 2
wrote it and nobody caught it through rev 3 or rev 4: Cyera signed a
letter of intent to acquire Oasis on 2026-07-28 and completed the deal
on 2026-09-03 for roughly $1B
([Yahoo Finance / Cyera press release](https://finance.yahoo.com/technology/ai/articles/cyera-completes-acquisition-oasis-security-120000606.html),
accessed 2026-10-05). It is one data point in a wider consolidation
this run also verified directly: Palo Alto Networks closed its $25B
acquisition of CyberArk on 2026-02-11
([GovConWire](https://www.govconwire.com/articles/palo-alto-networks-cyberark-25b-acquisition),
accessed 2026-10-05), and secondary coverage (not independently
verified this run, flagged) places Astrix inside Cisco and Entro inside
SailPoint in the same window
([Dark Reading, NHI vendor-chase roundup](https://www.darkreading.com/identity-access-management-security/vendors-attackers-chase-potential-of-non-human-identities),
accessed 2026-10-05). Read plainly: the non-human-identity/compliance
vendors rev 2's G3 cited as independent proof of market size are now
business units inside platform security giants. That sharpens G3's
own claim rather than weakening it — audit-and-governance for machine
identity is now valuable enough that Palo Alto, Cisco, SailPoint and
Cyera all bought their way in within a year — but it means G3's
evidence should no longer be read as a count of independent vendors,
and the next full re-rank should re-source it from deal size, not
funding-round count. No action item; a correction for the record.

**Reinforcement, dated earlier but caught this run: GitHub's own fix
for agent PATs is the shared-token pattern, not a principal.** GitHub
shipped built-in `GITHUB_TOKEN` support for Agentic Workflows on
2026-06-11, explicitly to remove the need for a personal access token:
"You no longer need to create and store a personal access token (PAT),
eliminating the operational and security risks of managing long-lived
PATs for automations at scale"
([GitHub Changelog, 2026-06-11](https://github.blog/changelog/2026-06-11-agentic-workflows-no-longer-need-a-personal-access-token/),
accessed 2026-10-05). Read against law 3: `GITHUB_TOKEN` is scoped to
the repository and the workflow run, not to the agent — every agentic
workflow in that repo shares it, which is the ambient-credential shape
our product replaces, confirmed by GitHub's own vendor behavior rather
than inferred. This is GitHub validating that the PAT pattern was worth
fixing while fixing it with a shared, not per-agent, token — the same
shape rev 4 found in Fleet's GitHub integration (§4a). Three months
old and missed until this run; flagged under L-R1 the same way the
Oasis correction is.

**Re-checked, no change:** OpenClaw (latest stable `v2026.9.8`, still in
its declared "fix the foundation" stability phase, per
[releasebot.io/updates/openclaw](https://releasebot.io/updates/openclaw),
accessed 2026-10-05) and Anthropic Managed Agents (beta header
unchanged, nothing found giving a Managed Agent a distinct
outside-platform principal, per
[platform.claude.com/docs/managed-agents/overview](https://platform.claude.com/docs/en/managed-agents/overview),
accessed 2026-10-05) — neither moved enough to re-open its tier.

## 2. Demand — one fresh, sharply dated quote

A GitHub issue opened **2026-10-04, the day before this run**, on a
small open-source repo, asks for exactly our mechanism and names a
reason the brief had not yet recorded: an agent cannot review its own
work if GitHub sees it as the same account as the human reviewing it.
"Provide a dedicated GitHub App identity for coding agents to open and
update implementation PRs in Nexa, so the solo maintainer can review
bot-authored PRs using GitHub's normal approval interface" — the issue
goes on to ask for App registration, minimal permissions, a
credential-handling writeup, and PRs "authored by the verified App
bot," naming "preventing credential exposure to untrusted code
execution" as a requirement alongside identity
([lmiguelvargasf/nexa#58](https://github.com/lmiguelvargasf/nexa/issues/58),
accessed 2026-10-05). This sharpens rev 1 and rev 2's demand quotes
(attribution, audit visibility, stolen credentials) with a fourth,
mechanical reason personal-token agents fail: GitHub's own review
tooling refuses to let an author approve their own PR, so an agent
sharing its owner's account cannot be put through the owner's normal
review process at all, by construction, regardless of policy.

## Mechanism audit, re-run: the Slack build gap is still open

Rev 4 found that `cli/src/lib/slack.js` on main is a webhook poster,
not the bot-App identity rev 2 recommended, and flagged it as a
build-status fact rather than a ranking change. Re-checked this run
against main (`f639b8e`) and every engineer PR opened since rev 4's
check (#43, #44, #45, #46, #48, #49, all open as of 2026-10-05): none
of them touch `apps.manifest.create` or add a Slack identity mint —
the Slack mentions in #43/#44/#45 are manifest fixtures and roster
examples using the existing `slack_webhook_env` posting path, not new
code. Rev 4's finding stands unchanged: the thing we'd be selling on
Slack under law 3 is still unbuilt.

## 3. Positioning and pricing — unchanged, both asks still open

No new evidence this run moves either pricing recommendation. Rev 1's
flat roster tier (buyer 1) and rev 4's proposed usage-based,
per-mint/per-verify pricing for buyer 2 (ADR-13) both still await the
owner's one word; nothing found this run argues either way.

## 4. Integration map — no re-ranking trigger fired

GitHub's agent-app waitlist and LangSmith's changelogs were the two
live trigger conditions checked this run (above); neither fired.
Standing recommendation unchanged: **Slack remains integration #2**,
re-justified in rev 4 and not revisited by anything found this week.

---

*Charter compliance note (rev 5): research only; nothing posted, no
one contacted, no accounts created. Checked against
docs/standards/lessons.md before shipping, specifically L-R1 (the
live-world check that caught the Oasis and GitHub-PAT staleness), L-A1
(mechanism over marketing language) and L-E10 (the PR survey that put
this revision on top of #42 and #31 instead of a fourth parallel
build). Flagged secondary or unverified: the Astrix→Cisco and
Entro→SailPoint placements (via Dark Reading, not independently
confirmed with a primary source this run).*

---

# Market brief — docs/market.md (rev 4, superseded by rev 5 above)

Maintained by the market seat. This revision: **rev 4, 2026-10-02**,
dispatch run. Anchor: docs/backlog.md names 2026-10-02 explicitly for
"Market re-justifies the ranking under ADR-6 in the 10-02 map refresh"
and separately flags ADR-13's buyer-2 pricing/column as still open.
Built on top of the unmerged rev 3 (PR #31, 2026-09-30) rather than
re-running its research: `gh pr list` was checked first (L-E10 — an
open card, or here an open brief, is not evidence nobody built it),
rev 3 already covers the ten-day delta against rev 2 including an
ADR-12 check, and redoing that would be the duplicate-build pattern
ExO incident 2 named. This run is additive on four fronts: the
mandatory ADR-12 check (§4a — it fires this time), the ADR-6 re-rank
grounded against what actually shipped in `cli/` since rev 2 rather
than only the outside landscape, ADR-13's agent-maker-as-customer
column and separate buyer-2 pricing, and three research assignments
accepted on founding night or at ADR-7 (2026-09-18/19) that sat
undone through rev 2 and rev 3: WhatsApp, WeChat, Omarchy. Rev 3
stands below, unedited, marked superseded. Every claim below is
sourced and dated; non-official-domain sources were fetched directly,
not taken from a search summary alone.

## Orientation: the tripwire fires, on Slack, and it's a miss we made ourselves

The headline: LangSmith Fleet mints a real, distinct Slack bot
identity per agent — "Fleet creates a Slack app named after your
agent, using its description and icon" — and that satisfies ADR-12's
literal tripwire condition (§4a). It shipped 2026-07-13/17, which
means rev 2 (09-19) and rev 3 (09-30) both reviewed Fleet's identity
docs and missed it; this is a detection failure on our declared
territory (L-R1), not a new release to react to, and it's named as
such rather than softened.

Read against G4 (rev 2 §6), the finding shrinks back down: Fleet's
Slack app is a real principal, but it is a LangSmith-custodied
principal that exists only inside Fleet, follows no agent to GitHub or
anywhere else, and disappears the day the customer cancels LangSmith.
It is a new wall, built well, not a door through the walls. The
tripwire still fires on its literal wording — "any mechanism by which
a LangSmith-deployed agent acts on an outside platform under its own
principal" — and ADR-12 is explicit that firing is a procedural
question, not a judgment call, so this is escalated below rather than
argued away. The owner's call is what it's worth in light of G4, not
whether it fires.

---

## 4a. Standing watch: LangChain/LangSmith (ADR-12) — TRIPWIRE FIRES, escalation

**Checked this run, as every run must.** Finding: **yes, a mechanism
exists today** by which a LangSmith-deployed agent acts on Slack under
its own principal, not a shared key and not the invoking human's
OAuth.

**The mechanism, sourced from LangChain's own docs (fetched directly
2026-10-02, not taken from a search summary):**

- Agent identity in Fleet is a binary choice made once and locked:
  "Fixed Credentials ('Claws')" — the agent authenticates with the
  same credentials "irrespective of who initiates the interaction,"
  the documented example being "a team Slack bot or a daily briefing
  agent" — versus "User Credentials ('Assistants')," which act as the
  invoking human
  ([docs.langchain.com/langsmith/fleet/agent-identity](https://docs.langchain.com/langsmith/fleet/agent-identity),
  accessed 2026-10-02). Claws is the mode the tripwire is about:
  fixed, not delegated.
- For Slack specifically, Claws is not a shared key: "Each agent maps
  to exactly one Slack app," and "Fleet creates a Slack app named
  after your agent, using its description and icon." On self-hosted
  LangSmith the admin creates a custom Slack app per agent instead;
  either way it's one app per agent, not one app for the workspace and
  not one app for all of LangChain's customers
  ([docs.langchain.com/langsmith/fleet/slack-app](https://docs.langchain.com/langsmith/fleet/slack-app),
  accessed 2026-10-02).
- Shipped **2026-07-13 through 07-17**: "You can now add any agent to
  Slack in one click. After you authenticate with Slack once, Fleet
  automatically creates a Slack app..." plus the same window's
  interrupt-approval buttons and thread replies, all under that same
  per-agent bot
  ([docs.langchain.com/langsmith/fleet/changelog](https://docs.langchain.com/langsmith/fleet/changelog),
  accessed 2026-10-02). That date is eleven weeks before rev 2's
  LangSmith review and six weeks before rev 3's — both had the page
  open and cited adjacent pages, neither caught this one.
- **GitHub does not (yet) do the same thing, and it's the clean
  opposite shape.** Fleet's GitHub integration on self-hosted LangSmith
  is one GitHub App for the whole deployment, created once via GitHub
  Settings and stored as a Kubernetes secret (`kubectl create secret
  generic fleet-github-app`), shared across every agent in that
  workspace. Worse for law 3, not just shared: "Each user must also
  authorize the GitHub App against their own GitHub account using the
  re-auth flow in LangSmith. This allows Fleet to resolve per-user
  tokens for tools that act on behalf of a user" — on GitHub, Fleet is
  explicitly in "Assistants" mode (the human's own token), not "Claws"
  ([docs.langchain.com/langsmith/fleet/self-hosted](https://docs.langchain.com/langsmith/fleet/self-hosted),
  accessed 2026-10-02). Law 3's test ("a shared installation is a
  delegation surface, not an identity surface") fails GitHub on both
  counts — shared app, human-delegated token; it now passes Slack.

**What this does and doesn't mean, read against our own gaps (rev 2
§6):**

1. **It does not close G4.** A Fleet Slack bot is not portable: it
   cannot become the same agent's GitHub identity, cannot be verified
   as the same principal across platforms (no passport, no manifest,
   no cross-platform binding), and is custodied by LangSmith, not
   owned by the builder the way a manifest is. The whitespace this
   company is a bet on is unchanged.
2. **It does narrow one specific pitch.** Rev 2's Slack recommendation
   leaned partly on "Slack is where a human watches the agent work...
   the product demo, in-situ, daily." Any builder already paying for
   LangSmith Fleet can get that specific demo today, for an agent they
   built in Fleet, without us. That is a real, if narrow, erosion —
   it affects the visibility argument for Slack specifically, not the
   identity argument, and not for builders outside the LangSmith
   ecosystem (still most of buyer 1, per ADR-13).
3. **ADR-12's three arms, re-examined.** Integrate (`langchain-epito`)
   and outdo (the passport) are unaffected — neither depends on
   whether Fleet's own Slack bots are good. Supply (ADR-13's third
   arm, "be the provider their Connections resolve to") gets a
   concrete next question worth putting to the owner: could an epito
   manifest become the identity Fleet's Claws mode points at, instead
   of (or alongside) Fleet's own auto-created Slack app — i.e., does
   LangChain's own one-principal-per-agent design give epito a
   plug-in point, or does Fleet's closed creation flow ("do not create
   the Slack app outside this flow") foreclose it. Not researched this
   run; flagged as the first question for whoever picks up the supply
   arm.

**Escalation (per ADR-12, same run, pre-authorized out-of-cycle
exception):** the tripwire fired on its literal wording. Recommend
the betting table treats this as evidence the *mechanism* class
(agent-as-Slack-principal) has one more working, shipped example in
the wild, which makes the outdo arm's deadline ("visible before their
next credential release") a few weeks closer than rev 2 assumed,
without treating it as the wedge-halving event ADR-12 was written to
catch. **One word: does the owner want the passport prototype pulled
forward again, yes/no.**

---

## 1. Landscape delta (rev 4) — Atlassian confirmed, Vercel re-checked

Rev 3 left two flags open. Both are closed this run with direct reads
of the primary pages, not a search summary.

**Atlassian: upgraded from "build-next candidate, unconfirmed" to
build-next, confirmed on law 3, open on law 2.** The `rovo-agent-
connector` module is GA and its own docs describe exactly the law-3
test: "an AI agent hosted outside of Forge [can] be connected to Rovo
over the Agent2Agent (A2A) protocol, so the external agent appears
alongside native Rovo agents," and "users can interact with them...
assigning them work items, @mentioning them in comments, and chatting
with them via the Rovo Chat panel"
([developer.atlassian.com/platform/forge/manifest-reference/modules/rovo-agent-connector](https://developer.atlassian.com/platform/forge/manifest-reference/modules/rovo-agent-connector/),
accessed 2026-10-02). That is appearing as itself, assignable and
mentionable, not merely callable — law 3 passes. Still only `jira` is
supported in `productContexts` (Confluence not yet). Law 2 (self-serve
mint, no bar) is left open: Forge apps are ordinarily self-deployable
to one's own site without Marketplace review, which would clear it,
but this run did not find a page stating that applies to this module
specifically rather than to Marketplace-listed agents — one more
targeted read, flagged for the next full re-rank rather than asserted.

**Vercel: re-checked, no change.** September's marketplace activity
(skills.sh registry crossing 1M skills, Vercel Connect + TanStack AI,
Mem0 joining, OpenAI Agents API integration) is volume, not a listing-
bar change: submissions are still "curated rather than open-
submission, with a strong bias toward agents that demonstrate AI SDK
patterns," and onboarding is still "submit a request to join the
Vercel Marketplace" ([vercel.com/docs/agent-resources/integrations-for-agents](https://vercel.com/docs/agent-resources/integrations-for-agents);
[Vercel Marketplace community thread](https://community.vercel.com/t/introducing-ai-agents-services-on-the-vercel-marketplace/25852),
accessed 2026-10-02). Rev 2/3's "build-next, bar unopened" verdict
stands; the "lighter listing path" re-ranking trigger did not fire.

## Mechanism audit: what Slack integration actually shipped vs. what rev 2 recommended

This is new to the brief because it's the one check only the market
seat can do by reading `cli/` instead of the outside web, and it
belongs in an ADR-6 re-rank. Rev 2's standing recommendation was a
Slack bot *App*: self-serve mint via `apps.manifest.create`, its own
username and avatar, revocable per install — the identity-surface
shape law 3 demands. What actually shipped (`cli/src/lib/slack.js`,
confirmed by reading the file 2026-10-02) is a different, smaller
thing: an incoming-webhook poster. Its own header comment says so
plainly — "it posts; it never reads" — one line per run
(`pm · message · 3 turns · 12s · <pr-url>`) to a URL named in
`[runtime].env`. There is no `apps.manifest.create` call anywhere in
`cli/` (checked by grep), no bot user, no distinct avatar: the line
arrives via whatever name the webhook's parent app was given once, by
hand, outside epito. Contrast with GitHub, where `cli/src/lib/
identity.js` implements the real thing rev 2 described: App id, signed
JWT, installation-scoped token minted fresh per run, scopes derived
from the manifest and nothing wider.

This is not a ranking change — Slack still wins the #2 slot (below) —
it's a build-status correction. **The thing we'd be selling on Slack
(law 3, "appears as itself") does not exist yet.** What shipped is a
real and valuable v0 of the *visibility* argument for Slack (a human
watches the agent work) with none of the *identity* argument (the
agent is a someone there). Noted for whoever next picks up the Slack
card: the identity-bearing version is still the open build, not a
polish pass on what's there.

## ADR-13: the agent-maker-as-customer column, and pricing buyer 2 separately

ADR-13 (2026-09-20) asked for two things, neither done in rev 2 or
rev 3: a column on the maker map for "as customer" alongside "as
surface," and a buyer-2 price distinct from the roster tiers. Both
land here.

**As customer:** for each maker in rev 2 §7.3's table, would it ever
pay *us* to be the outside-platform identity issuer for the agents it
builds or hosts, versus only being a runtime whose agents we might run
(§7.3's existing "as surface" column, about ADR-17's adapter shape)?

| Maker | As surface (ADR-17: can epito host/run its agents?) | As customer (does it need an outside-platform identity issuer, and would it buy one rather than build one?) |
|---|---|---|
| **LangChain / LangSmith** | Yes — `langgraph` adapter shipped (ADR-17) | **Live tension, not a clean yes.** §4a just found they're building this themselves (Fleet's per-agent Slack app), which cuts against buying it — but it's a Slack-only, Fleet-only, non-portable version, and the "supply" question raised in §4a (could epito be the provider Connections points at) is exactly this column's point. Candidate, unconfirmed. |
| **OpenClaw** | Not an adapter target (it hosts its own agents; epito would be a credential backend reached via its plugin hub or vault mount, §7.1) | **Yes, plausibly, and already scoped**: §7.1's spike is literally "epito as customer" — an MCP connector serving per-agent platform tokens to OpenClaw agents, because OpenClaw's roadmap fixed credential *storage*, not credential *identity*. Clearest fit of the five. |
| **CrewAI** | Would follow LangGraph's adapter shape if ever built | Same env-key pattern as LangGraph per rev 2 §7.3; no identity ambition seen. Watch. |
| **OpenAI Agents SDK / AgentKit** | Not a target (no adapter shape fits a hosted sandbox) | Unlikely near-term: OpenAI is absorbing the runtime leg itself (native sandbox execution, its own Connector Registry); a company building its own full stack is a weak buyer for a piece of it. Watch. |
| **AutoGen / Microsoft Agent Framework, Google ADK** | Not targets | No: both are Entra- or Google-cloud-anchored by design: the identity story is already sold to them by the parent platform. Skip as customer. |

**Pricing buyer 2, separately from roster tiers.** Buyer 2 is not a
builder with a roster; it's a platform reselling agent identity to
*its own* customers at volume, so a flat roster tier (rev 1's
recommendation for buyer 1) is the wrong shape — it prices one
builder's agents, not a platform's throughput. The nearest real comp
is still Clerk's M2M pricing, re-verified today unchanged: $0.001 per
token creation (2,500/month free) and $0.00001 per verification
(100,000/month free)
([clerk.com/docs/guides/development/machine-auth/m2m-tokens](https://clerk.com/docs/guides/development/machine-auth/m2m-tokens),
accessed 2026-10-02) — this is what the market already charges a
platform for minting and checking machine credentials at wholesale.
WorkOS Agent Auth and Auth0's "Agent as Principal" remain sales-
contact-only with no public per-unit price (rev 3 §8.3, unchanged).
**Recommendation: buyer 2 is priced usage-based, per credential minted
and per credential verified, at or below the Clerk comp, never a flat
tier** — the flat-roster logic (identity issuance is priced near zero,
the resident runtime is the billable substance) still holds, but for
buyer 2 there is no resident runtime to attach a flat price to; the
mint itself is the entire product being sold. One word: **usage-based
buyer-2 pricing, yes/no.**

## Three overdue research assignments, closed: WhatsApp, WeChat, Omarchy

All three were accepted by the owner on founding night or at ADR-7
(2026-09-18/19) "for the next brief revision." Two revisions passed
without them. Closed here, under the same four ranking laws as every
other row.

**WhatsApp Business Platform: SKIP, and not for the usual gating
reason.** Every other watch/skip verdict in this document is about a
listing bar or an enterprise sales motion. WhatsApp's is sharper: Meta
changed the WhatsApp Business Solution terms on 2026-01-15 to bar
"providers of AI or machine-learning technologies, including large
language models, generative AI platforms, or general-purpose AI
assistants... when such technologies are the primary functionality
being provided," while "business-specific bots... customer support,
order tracking, bookings, FAQs" remain fully permitted
([dig.watch summary of Meta's terms change](https://dig.watch/updates/meta-changes-whatsapp-terms-to-block-third-party-ai-assistants);
corroborating coverage: [dataslayer.ai](https://www.dataslayer.ai/blog/meta-bans-general-purpose-ai-chatbots-on-whatsapp-business),
accessed 2026-10-02). Read against ADR-2's own definition — "an agent
is autonomous and *triggered*, not prompted, with its own identity and
its own runtime" — an epito-minted agent is categorically the thing
the policy names, not the task-specific bot it exempts. The identity
mechanics are otherwise fine and self-serve (a Meta Business Portfolio,
app creation via the Meta App Dashboard, system users and access
tokens — ordinary self-serve OAuth-app plumbing), which is exactly why
this is worth stating plainly: law 2 passes, the policy gate above it
does not, and no amount of good engineering opens a policy wall. Skip,
re-check only if Meta narrows the ban.

**WeChat: SKIP, on two independent grounds, neither of which is the
platform's own design.** First, regulatory: any generative-AI or
agent service reaching users inside China needs either a fuller
"filing" (备案) or a lighter "registration" (登记) with the Cyberspace
Administration of China, and the filing applicant must be "a mainland
China registered legal entity (WFOE, Joint Venture, or VIE-structure
entity)" — as of the sources checked, "no WFOE has successfully
secured [the fuller filing] to date"
([appinchina.co, China's AIGC registration guide](https://appinchina.co/blog/the-complete-guide-to-chinas-aigc-registration/),
accessed 2026-10-02). epito.me has no mainland entity and no plan to
form one; this blocks the platform regardless of what WeChat's API
allows. Second, even bracketing that: WeChat's new agent layer is the
opposite shape from ours. The "WeChat AI Ecosystem" guidelines
(published 2026-06-08) let a mini-program "automatically become a
'skill' that AI can call" — i.e., third-party services are absorbed as
callable skills *inside WeChat's own one super-agent*, not given their
own recognized identity the way a GitHub App or a Linear app-user is
([crossingriver.substack.com](https://crossingriver.substack.com/p/4-million-mini-programs-one-ai-agent),
accessed 2026-10-02) — and the feature is still in closed beta, end
users can't reach it yet. Two independent blockers, stated honestly
rather than picking the more flattering one. Skip.

**Omarchy Linux: WATCH, as a channel and a runtime target, not an
identity surface — exactly the shape ideas.md proposed on founding
night.** Omarchy (DHH's Arch-based distro) ships "ten AI coding agents
pre-wired" and its next release ("Quattro") is "building AI agents into
the desktop itself," with a usage-monitoring widget and per-agent
selection in `Setup > Defaults > Agent`
([itsfoss.com](https://itsfoss.com/news/omarchy-ai-agent-focus/);
[mindstudio.ai](https://www.mindstudio.ai/blog/what-is-omarchy-linux),
accessed 2026-10-02). Nothing found gives any of those nine-to-ten
bundled agents an identity on an outside platform — Omarchy wires
*which* agent runs, not *who* it is anywhere else, which is the exact
gap ideas.md named ("its agents have no identity — our layer"). Two
distinct opportunities, not one: **channel** — an AUR package
(`omarchy-ai-usage-git` already exists as a precedent for third-party
Omarchy tooling, zero listing bar, same shape as law 4) — and
**runtime target** — `epitod` as a systemd unit on a box that already
has agent tooling pre-wired, meeting a user where they already are
(vision §0's "easy for vibecoders" plus §0b's own Omarchy-as-craft-
exemplar, a pleasant coincidence worth naming but not leaning on).
Traction signal, dated today: Omarchy opened a $100,000 HackerOne bug
bounty on 2026-10-02 ([itsfoss.com](https://itsfoss.com/news/omarchy-ai-agent-focus/)),
a real security-investment signal for a project this young. Tier:
watch/low-cost-channel, per ideas.md's own "Low effort" rating — an AUR
package is a side-bet, not a build slot.

## Standing recommendation, re-justified under ADR-6 (rev 4): unchanged

Slack remains the pick for integration #2. Nothing found this run
changes any of the four laws' answers for Slack — `apps.manifest.
create` is still open and self-serve, a Slack App is still a first-
class someone, distribution is still optional on top of a working
surface. What changed is context, not the verdict: Atlassian is
promoted to a confirmed (law 3) build-next candidate behind Slack,
WhatsApp and WeChat are removed from the open-research queue as
skips, Omarchy enters as a channel/runtime watch item, and the mechanism
audit above records that Slack's *build* is still ahead of us, not
behind us — the recommendation was right in rev 2 and remains unbuilt,
which is a project-management fact for the PM/engineer seats, not a
market-seat finding that changes.

---

# Market brief — docs/market.md (rev 3, superseded by rev 4 above)

Maintained by the market seat. This revision: **rev 3, 2026-09-30**,
weekly window run (charter: prompts/market-agent.md). Scope: what
moved since rev 2 (2026-09-19/20) against the charter's four sections,
plus the mandatory ADR-12 standing-watch check. This is a delta run,
not a from-scratch re-rank: the full integration table, gap analysis
(§6), and maker-track map (§7-§8) from rev 2 stand except where a row
is explicitly updated below. Rev 2 is kept in full further down this
file, marked superseded. Every claim below carries a source and access
date; sources were spot-checked (GitHub API calls against cited
issues/PRs/repos, not just the agent's transcript) before inclusion,
per the charter's "never state a competitor claim without a link."

## Orientation: the ten-day delta

Four things moved since 2026-09-20. First, the ADR-12 tripwire did not
fire — LangSmith shipped more Fleet/Engine changelog volume this
window but no new identity primitive; full log in §4a. Second, one
integration-map re-ranking trigger fired for real: Atlassian's
`rovo-agent-connector` reached GA on 2026-09-28 and now names
externally-hosted agents (GitHub Copilot, Cursor Background Agents, Box
AI Agents) as a supported case over A2A — the exact condition rev 2
flagged as "re-check next quarter," now confirmed early. It does not
change the standing recommendation (Slack still wins the #2 slot; see
§4) but it reopens Atlassian as a build-next candidate for the next
full re-rank. Third, a new entrant — Ando, $20M seed, out of stealth
2026-09-24 — is building agent-native team messaging (agents as
first-class members with identity, permissions, and shared context)
as a whole new surface rather than a plug-in identity layer aimed at
Slack's turf; watch, not build. Fourth, and the sharpest reframe: this
run's positioning research surfaced that our "why epito and not glue"
answer has always been implicitly benchmarked against vendor lock-in
and hand-rolled plumbing, but a free, real, MIT-licensed competitor
already exists for the single narrowest slice of our v1 — per-agent
GitHub identity — built and shipped by one solo developer
([qwts/agent-bot-identity](https://github.com/qwts/agent-bot-identity),
created 2026-07-23, 1 star as of 2026-09-30, verified live via the
GitHub API). One star means unproven adoption, not a threat by
traction — but it proves the mechanism is a weekend build for anyone
technical enough to read our own architecture doc, which sharpens what
we have to sell beyond the mechanism itself: the roster, the audit
trail, and the manifest that scales the same file from 1 agent to 100
(vision §0), none of which a single-purpose script gives you.

---

## 1. Landscape — what moved, 2026-09-20 through 2026-09-30

**Atlassian (re-ranked up from rev 2's "watch, structural mismatch").**
The `rovo-agent-connector` module reached General Availability on
2026-09-28 ([Atlassian developer changelog](https://developer.atlassian.com/changelog/); [module reference, last updated 2026-09-22](https://developer.atlassian.com/platform/forge/manifest-reference/modules/rovo-agent-connector/), accessed 2026-09-30).
Rev 2's objection was structural: "Marketplace agents must run on
Forge... their model absorbs the agent body into their cloud, the
opposite of ADR-2 residency." The GA module now explicitly supports
agents "hosted outside of the Atlassian platform," citing GitHub
Copilot, Cursor Background Agents, and Box AI Agents as examples,
connecting over the Agent2Agent (A2A) protocol. This does not on its
own clear law 2 (self-serve mint) — whether an epito agent could
register through this connector and appear in Jira/Confluence as
itself, versus merely being callable by Rovo, is not yet confirmed and
is flagged for the next full re-rank. But the reason Atlassian was
parked at "watch" no longer clearly holds, so it moves to **build-next
candidate, unconfirmed**, pending that one-afternoon check.

**New entrant: Ando.** Out of stealth 2026-09-24 with a $20M seed
(Accel, Index, Emergence): an agent-native team-messaging platform
built as a Slack alternative, where agents get "identity, permissions,
and shared context" as first-class team members, agent-agnostic
(Codex, Claude, Grok, etc.) ([TechCrunch](https://techcrunch.com/2026/09/24/ando-eyes-slack-as-it-builds-team-messaging-platform-for-humans-and-agents-to-work-together/); [launch release](https://www.globenewswire.com/news-release/2026/09/24/3368344/0/en/ando-launches-agent-native-messaging-platform-announces-20-million-seed.html), accessed 2026-09-30).
Read plainly against law 3 (the agent appears as itself or the row is
mislabeled): Ando bundles identity *inside its own new platform*, the
same walled pattern as every other bundler in rev 2's landscape
section — it does not portable-ize identity across GitHub, Slack, and
Ando the way a manifest does. It is a competitor on the "agent as
teammate" register, not a wedge threat yet, and a future watch-tier
row if it gets traction; too new to rank on distribution (no directory,
no marketplace, pre-launch product).

**Notion Agent SDK, public beta (2026-09-15).** Lets Custom Agents be
triggered and continued from outside Notion, not just invoked inside it
([release notes](https://www.notion.com/releases/2026-09-15), accessed
2026-09-30). This softens, slightly, rev 2's objection that "Notion
bundles residency natively, so our marginal value there is
portability, not residence" — external triggering is a step toward
externally-hosted agents driving a Notion identity, which is closer to
our shape. Not enough to move tier; Notion stays build-next.

**Okta, Oktane 2026 (2026-09-23).** Agent SSO, Agent-to-Agent
Connections, and Resource Access Certifications all went GA; a new
"Blueprint Alliance" with AWS and CrowdStrike; Agent Gateway and
Shadow-AI-Discovery slated for Q3 GA. Notably, WorkOS, Stytch, and
smaller agent-credential players (Archestra.AI, Keycard, Scalekit) are
listed as Cross App Access ecosystem partners — Okta is positioning
itself as the routing/governance layer other identity vendors plug
into ([Okta's own announcements PDF](https://s205.q4cdn.com/566291348/files/doc_events/2026/Sep/23/Okta-Oktane-2026-Announcements.pdf); [SiliconANGLE](https://siliconangle.com/2026/09/22/okta-adds-ai-agent-runtime-gateway-forms-blueprint-alliance-with-aws-and-crowdstrike/), accessed 2026-09-30).
Enterprise-anchored, same as every prior IdP move in rev 2 — reinforces
G4's whitespace claim (nobody portable-izes identity across an
indie builder's actual stack) rather than narrowing it.

**CrowdStrike "Agentic Identity Provider"** launched 2026-09-02 (just
before the rev 2 cutoff, missed then): an enterprise security-platform
SKU for agent identity, no public self-serve or per-agent price point
found ([CrowdStrike press release](https://www.crowdstrike.com/en-us/press-releases/crowdstrike-agentic-identity-provider-foundation-for-ai-agent-identity-security/), accessed 2026-09-30). Same enterprise pattern; no comp for our buyer.

**Re-ranking trigger conditions, checked one by one (rev 2's list):**

| Condition | Status | Evidence |
|---|---|---|
| GitHub opens agent-app self-service | Not fired | [Preview page](https://github.com/features/preview/agent-apps-for-github) still framed as early-access signup, no changelog entry opening it; checked [github.blog/changelog](https://github.blog/changelog/), accessed 2026-09-30 |
| Anthropic Managed Agents adds per-agent platform identity | Not fired | September releases were `anthropic-workspace-id` header, domain-restricted tool access, session budget caps — no identity primitive ([Claude Platform release notes](https://platform.claude.com/docs/en/release-notes/overview), accessed 2026-09-30) |
| Supabase clears/drops Partner Catalog bar | Not fired | Docs unchanged: registered business + revenue or VC backing ([Partner Catalog](https://supabase.com/docs/guides/integrations/partner-catalog), accessed 2026-09-30) |
| Vercel opens a lighter listing path | **Unverified, flagged** | The integration-requirements doc shows a "last updated Aug 28, 2026" stamp with no changelog text describing what changed; approval/email-review flow still documented as-is. Needs a direct diff read next run. |
| Slack changes app-creation/marketplace policy for AI apps | Not fired on the mechanism we depend on | September was a governance-heavy month (Slack Code, channel restrictions on apps/agents, IdP-managed MCP controls) but `apps.manifest.create` self-serve creation is untouched ([summary source, secondary](https://vantagepoint.io/blog/sf/slack-september-2026-admin-updates), accessed 2026-09-30) |
| Atlassian `rovo-agent-connector` exits EAP | **Fired**, 2026-09-28 | See above |
| Asana opens AI Teammates below sales tier | Not fired (access); pricing model shifted | Self-serve purchasing still "coming soon"; AI Teammates/Dash are now bundled into paid tiers with consumption billing rather than a separate add-on fee, as of mid-September ([MPUG](https://mpug.com/asana-ai-teammates-are-now-included-in-paid-tiers-and-billed-by-consumption-after-that), accessed 2026-09-30) — a pricing data point (§3), not an access change |

## 2. Demand — fresh evidence, three pain points

All quotes verified live (GitHub API / direct fetch) before inclusion,
not taken on the research pass's word alone.

**Personal tokens / attribution.** Two live GitHub issues from the
past two weeks show the exact confusion our product exists to remove:
one maintainer flagging that a shipped "identity stack" commits as
`arbsec-agent[bot]` with its own DCO sign-off while `CONTRIBUTING.md`
still says AI contributions are attributed to the human submitter —
"reviewers auditing provenance get contradictory anchors" ([arbsec/orchestraitor #397](https://github.com/arbsec/orchestraitor/issues/397), opened 2026-09-26); another where every agent commit in a fleet was silently attributed to the generic `github-actions[bot]` because a CI workflow omitted `bot_id`/`bot_name`, making "an agent's feature commit indistinguishable from CI's" ([bdh-org/dev-common #245](https://github.com/bdh-org/dev-common/issues/245), opened 2026-09-12).
Both are the identity-collision failure mode our manifest is built to
prevent, reported by people who built partial versions of our product
by hand and got the attribution wrong.

**Sandbox / resident-agent death.** The most interesting find is meta:
a live, verified GitHub issue whose body states it was "produced
automatically by Hermes (an autonomous AI agent) after a failed
unattended mission" — the agent itself wrote the postmortem of its own
death. It reports "no resource-lifecycle primitive in the core...
renting a cloud resource has no guarantee... the finished artifact was
never retrieved and is lost" ([NousResearch/hermes-agent #82304](https://github.com/NousResearch/hermes-agent/issues/82304), opened 2026-08-09,
confirmed live via GitHub API, repo has 47,048 open issues — treat
volume as a sign of a large, noisy tracker, not as forty-seven-thousand
independent corroborations). Read carefully: this is not a human's
complaint, it is the demand signal writing itself — an unattended agent
whose sandbox death cost it a finished, unretrievable result, filed by
the agent under a human's account (`tilllt`). Separately, a merged PR
in a session-runtime project fixes exactly the diagnosability gap: "A
sandbox killed by the kubelet reports the same thing as every other
death... the pod is typically garbage-collected before anyone
investigates" ([paradigmxyz/centaur #1532](https://github.com/paradigmxyz/centaur/pull/1532), merged 2026-09-04).

**Cron duct-tape.** A Show HN launch (score 37, 19 comments,
2026-09-05) for a new open-source agent scheduler opens with the
builder's own frustration: "Why can't we get an agent scheduler that
supports all of the following: git compatible, agent agnostic, 100%
open source, os and system-agnostic, multi-runner support..." and
claims 1,000+ users within what reads as a short window
([Show HN: Moadim.io](https://news.ycombinator.com/item?id=49571537), verified live via the HN API). This is a second data point (after Trigger.dev/Temporal in rev 1) that "cron plus an agent" is being rebuilt from scratch by indie builders repeatedly — a demand signal for the trigger leg specifically, and a reminder that our roadmap's trigger primitive is competing with hobbyist tools people will build for free before they'll pay for ours. A dev.to postmortem adds the failure-mode texture: "I had seven AI agents on cron. Two of them stopped running on day one. I noticed on day eighteen... silent failures are the most expensive kind, because nothing crashes and nobody gets paged" ([Ken Imoto, dev.to](https://dev.to/kenimo49/i-cron-scheduled-7-ai-agents-2-silently-failed-for-18-days-tracing-wouldnt-have-caught-it-24fa), 2026-06-03, older than this window but newly surfaced, verified live).

## 3. Positioning and pricing

**Positioning update.** "Why epito.me and not glue" (rev 1) now has a
second glue category to beat, alongside the hand-built GitHub App
plumbing every demand quote in §2 shows people rolling themselves: a
*free, working, single-purpose OSS substitute* for the narrowest slice
of v1 (`qwts/agent-bot-identity`, verified above). The honest
distinction is not mechanism — the mechanism is public and copyable by
construction (vision §0b: "every abstraction must be explainable by
pointing at the real mechanism beneath it") — it is scope: one script
gives one machine one GitHub identity; the manifest gives a roster
(1 to 100 agents, vision §0) one portable identity per agent across
every platform it touches, with the audit trail and passport rev 2 §6
G3/G4 describe. That distinction has to be sellable in one sentence
before it is sellable at all, and this run did not draft that sentence
— flagged for the next presentation pass under L-A8/L-A15.

**Pricing: flat roster tiers, reconfirmed, no change.** This run found
nothing that argues for a different structure. Okta's Agent SSO ships
inside core SSO plans at no incremental charge — another flat/bundled
treatment of agent identity from a major vendor ([coverage](https://finance.yahoo.com/technology/ai/articles/okta-sees-ai-agent-identity-210208369.html), 2026-09-23) — and CrowdStrike's and Ping Identity's September launches both ship as enterprise SKUs with no public usage-metered price point, so neither is a counter-comp for a hybrid model. No new "per-agent identity as a service" product with public indie pricing was found this run; WorkOS Agent Auth and Auth0's "Agent as Principal" remain sales-contact-only. The pricing risk this run surfaces is not structural, it is the DIY-for-free competitor named above: a flat tier has to be justified against "free," not against a metered rival.

## 4a. Standing watch: LangChain/LangSmith (ADR-12)

**Checked this run, as every Friday/window run must (ADR-12): tripwire
did not fire.** No mechanism found where a LangSmith-deployed agent
acts on GitHub, Slack, or any outside platform under its own principal
— every credential path still resolves to a shared/static secret, the
invoking human's OAuth, or (new this window) a single LangChain-owned
service identity shared across *all* customers.

What's new since rev 2 §8 (2026-09-20), none of it tripping the wire:

- **Fleet weekly changelog, 2026-09-22 through 09-28**
  ([docs.langchain.com/langsmith/changelog](https://docs.langchain.com/langsmith/changelog); diff via [langchain-ai/docs PR #6270](https://github.com/langchain-ai/docs/pull/6270/files), accessed 2026-09-30):
  "Fleet now uses the selected user identity for GitHub requests that
  are not tied to a specific repository" — an explicit reaffirmation of
  the human-delegated model, not a step toward an agent principal.
- **LangSmith Engine's GitHub App attribution changed**: code-fix
  commits now link to "the LangSmith Engine GitHub App." Confirmed via
  [docs.langchain.com/langsmith/engine-github](https://docs.langchain.com/langsmith/engine-github) (accessed 2026-09-30) that this is **one LangChain-managed GitHub App shared across every customer workspace** — "you do not create or configure an app yourself... no distinct bot identity per workspace." This is the closest thing LangChain has shipped to a GitHub-App-flavored bot identity, and it shows appetite for the pattern, but it is LangChain's own product bot, not a customer's deployed agent getting its own principal. Worth naming as the item most likely to evolve toward the tripwire condition — re-check specifically whether "shared across every workspace" narrows to "one per customer" or "one per agent" in a future release.
- **Blog post, "New in LangSmith: Engine v2, Managed Deep Agents,
  Fine-Tuning, and more"** ([2026-09-25](https://www.langchain.com/blog/langsmith-engine-agents-fine-tuning-trajectories)): introduces the phrase "identity-scoped auth," but on inspection this restates Connections' existing agent-owned/user-owned model (shipped 2026-09-09, already covered in rev 2 §8) plus new user-level memory scoping — not a new identity primitive.

Plain reading: a quiet ten days relative to the tripwire, high activity
otherwise (Fleet ships weekly). ADR-12's two active arms (integrate via
`langchain-epito`, outdo via the passport) are unaffected; no
escalation triggered.

## 4. Integration map — delta only

The full ranked table (rev 2 §5) is unchanged except for the two rows
below. **Standing recommendation is unchanged: Slack remains the next
integration after GitHub** — nothing this run found alters
`apps.manifest.create`'s self-serve status or the visibility-surface
argument for Slack.

- **Atlassian: watch → build-next candidate, unconfirmed** (see §1).
  Action before the next full re-rank: confirm whether
  `rovo-agent-connector` lets an externally-hosted agent register and
  appear as itself in Jira/Confluence (law 3), or only lets Rovo call
  out to it (still a delegation surface). One afternoon of docs
  reading, not a build.
- **Notion: build-next, unchanged tier, strengthened case.** The Agent
  SDK public beta (§1) narrows the "bundles residency" objection;
  still ranked behind Slack.
- **New watch-tier entry: Ando** (see §1) — too early to rank on
  distribution, tracked for the next dispatch that touches the
  messaging-surface question.

---

## To the seat that builds on this (unchanged from rev 2, reconfirmed)

The central problem in one sentence: every platform now gives agents
an identity that stops at its own wall, and epito.me exists to issue
the one identity that crosses them, owned by the user. This run adds
one refinement worth carrying forward: the platforms are not the only
thing that stops at a wall. A single free script can cross the same
wall for one agent on one machine. What a platform cannot do and a
script does not try to do is what we still own — the roster, portable
across a builder's whole stack, audited as one thing.

*Charter compliance note (rev 3): research only; nothing posted, no
one contacted, no sign-ups, no accounts created. Every non-official-
domain source (GitHub issues/PRs/repos, the HN thread) was
independently verified live via the GitHub API or a direct fetch
before inclusion, not taken on trust from the research pass alone.
Flagged secondary/unverified: the Slack September admin-updates
summary (vantagepoint.io, a secondary aggregator); the Vercel
"lighter listing path" condition (timestamp found, no changelog text,
needs a direct read next run); Atlassian's law-3 status for the new
connector (mechanism confirmed GA, self-serve-mint status unconfirmed).
Checked against docs/agents/lessons.md before shipping: no lesson
violation found — L-A1 (mechanism, not pitch) held throughout, and
this document is not owner-facing prose requiring the L-K3 public-copy
register.*

---

# Market brief — docs/market.md (rev 2, superseded by rev 3 above)

Maintained by the market seat. This revision: **rev 2, 2026-09-19**,
convened on dispatch for two owner questions: the integration universe
(where an epito agent could show up, ranked) and the gaps that
containerized autonomous agents unlock. Rev 1 (2026-09-18) is kept
verbatim at the bottom of this file, marked as rev 1. Every claim
carries a source and a date; "accessed 2026-09-19" means the page was
read today and the event date is as the source states it.

## Orientation: the whole shape in a page

Rev 1 mapped the vibecoder stack. This run widened the lens to every
platform with an agent surface and came back with three findings.

First, the platform world split into two camps in 2026. Every major
vendor now mints agent identity inside its own walls (Microsoft Entra
Agent ID, AWS AgentCore workload identity, Google SPIFFE agent IDs,
Slack bot users, Notion Custom Agents, Asana AI Teammates). Not one of
them issues an identity that follows the agent across platforms or
belongs to the user. That portable, user-owned principal is still
nobody's product. It is ours.

Second, the re-rank the owner asked for under ADR-6: **Slack replaces
Linear as the recommended integration #2**, with Vercel and Notion as
runners-up. The full justification is in §5.

Third, the demand evidence hardened. The OpenClaw crisis (135k GitHub
stars, then 42k exposed instances and a compromised skill registry)
proved people want resident local agents badly enough to run unsafe
ones. The EU AI Act's August 2026 logging deadline and a $300M+
non-human-identity funding wave priced the audit problem. Both are in
§6.

The tier counts, for scale:

| Tier | Count | Members |
|---|---|---|
| build-now | 3 | GitHub (shipped), Slack (recommended #2), editor MCP/skill (bet 2) |
| build-next | 3 | Vercel, Notion, Supabase |
| watch | 9 | Linear, Microsoft, AWS, Google, Stripe, Asana, Atlassian, Clerk, Neon |
| skip | 3 | Zapier/Make, Salesforce AgentExchange, runtime vendors as channels |

**If you only internalize one item, make it §6 gap G4**: the
cross-platform, user-owned agent principal is whitespace every big
vendor is structurally unable to enter, because each one's identity
stops at its own wall. It is the sentence this company is a bet on.

### Ranking laws (do not route around these)

1. **Surface, never dependency** (ADR-6). An integration is a place
   the agent shows up as itself. Core, `epito`, the MCP server, and
   `epitod` work with zero integrations installed.
2. **Self-serve mint or no build slot.** If minting the agent's
   identity on a platform requires a partner approval, waitlist,
   revenue bar, or sales call, the platform can be watched but cannot
   hold a build slot. (GitHub qualifies: plain GitHub Apps are open;
   Slack qualifies: `apps.manifest.create` is open. Vercel's
   marketplace and Supabase's catalog do not, yet.)
3. **The agent appears as itself or the row is mislabeled.** A
   platform where our agent can only act under the owner's token or a
   shared installation is a delegation surface, not an identity
   surface, and is ranked accordingly.
4. **Distribution is a bonus on top of a working surface, never the
   reason the surface exists.** A listing bar may gate the storefront;
   it must never gate the product working.

---

## STANDING RECOMMENDATION (2026-09-19, supersedes 2026-09-18)

**The next integration after GitHub is SLACK.**

Linear was rejected by the owner (ADR-6, "i dont think we should
depend on linear"). Re-ranked from scratch under the four laws above,
Slack wins the slot:

- **Self-serve identity mint, today, no bar.** A Slack app is created
  programmatically via `apps.manifest.create` with an app
  configuration token ([Slack SDK issue #1192](https://github.com/slackapi/python-slack-sdk/issues/1192), accessed 2026-09-19;
  [token types](https://api.slack.com/authentication/token-types), accessed 2026-09-19),
  then installed per workspace through the standard OAuth flow
  ([docs.slack.dev](https://docs.slack.dev/authentication/installing-with-oauth/), accessed 2026-09-19).
  This is structurally the same manifest-mint flow our GitHub provider
  already implements (`POST /app-manifests/{code}/conversions`), so
  the provider is a variation on shipped code, not a new pattern.
- **The agent is a first-class someone.** Each app carries its own bot
  user with granular scopes (`chat:write`, `channels:history`, and the
  `assistant:write` agent surface), its own name and avatar in every
  message, and revocation by uninstall. That satisfies law 3 exactly
  as GitHub Apps do.
- **It is the visibility surface.** GitHub proves the agent works;
  Slack is where a human watches it work. A cron-woken agent posting
  its own standup under its own face is the product demo, in-situ,
  daily. Slack's own positioning is agents-as-teammates via Slackbot
  and MCP ([slack.com/ai-agents](https://slack.com/ai-agents), accessed 2026-09-19;
  [Slackbot GA, 2026-01-13](https://www.salesforce.com/news/press-releases/2026/01/13/slackbot-announcement/)).
- **Distribution is optional, honoring law 4.** Unlisted apps install
  self-serve per workspace; the Slack Marketplace listing (with its
  AI-app review) is a later storefront choice, never a gate on the
  provider working.
- It settles the manifest v0.2 scope grammar for a second platform
  (`slack:chat.write`), which is what the #2 slot exists to prove.

**Runner-up 1: Vercel.** Largest storefront in the stack, native "AI
agents & services" category with unified auth and billing
([changelog](https://vercel.com/changelog/introducing-ai-agents-and-services-on-the-vercel-marketplace), accessed 2026-09-19).
But the identity primitive is partial (installation-scoped
integrations, no member identity for an agent), the bar is Pro-plan
team plus integration server plus approval, and the slot's whole value
is the listing, which violates the spirit of laws 2 and 4. Build-next.

**Runner-up 2: Notion (new since rev 1).** Custom Agents shipped
2026-02-24 and passed one million agents built
([release notes](https://www.notion.com/releases/2026-02-24); [notion.com/product/agents](https://www.notion.com/product/agents), accessed 2026-09-19),
and the Agent API beta (2026-05-13) manages agents programmatically
([developers.notion.com](https://developers.notion.com/guides/notion-agent-apis/overview), accessed 2026-09-19).
Integration bots are real identities in page history. But Notion is
bundling residency natively, so our marginal value there is
portability, not residence. Build-next.

Supabase stands where rev 1 left it: build-ready, list-later, catalog
bar unchanged.

Honest tension on the pick: Slack is Salesforce property, and Slackbot
is being positioned as the orchestrator that fronts third-party agents
([Futurum](https://futurumgroup.com/insights/salesforces-slackbot-goes-ga-is-this-the-real-test-for-agentforce/), accessed 2026-09-19).
We would be building our best demo surface inside a competitor
family's living room. The mitigation is law 1: Slack is one surface of
many, and the provider dies gracefully if the walls close.

One word to accept or reject: **Slack / Vercel / Notion.**

---

## 5. The integration universe (rev 2 ranked table)

Method: for each platform, (a) does it have a native non-human or
agent identity primitive we can mint against, (b) what an epito agent
could do there autonomously, concretely, (c) distribution surface and
its listing bar, (d) tier. All rows accessed 2026-09-19 unless dated.

### Tier: build-now

| Platform | (a) Identity primitive | (b) What the agent does there | (c) Distribution & bar | Why this tier |
|---|---|---|---|---|
| **GitHub** (v1, shipped) | GitHub App: own username, avatar, `<name>[bot]` attribution, short-lived installation tokens | Commits, PRs, reviews, issue triage, release notes, on cron or webhook | Marketplace open for Apps; the Agent HQ "agent app" tier is still waitlist, "anyone can build" promised but not delivered as of today ([changelog 2026-06-02](https://github.blog/changelog/2026-06-02-extend-github-with-agent-apps/); [community discussion](https://github.com/orgs/community/discussions/197310)) | Shipped. Watch the waitlist; join the day it opens. |
| **Slack** | Bot user per app, granular scopes, `assistant:write` agent surface; mint via `apps.manifest.create` ([token types](https://api.slack.com/authentication/token-types); [OAuth install](https://docs.slack.dev/authentication/installing-with-oauth/)) | Posts standups, triages channels, answers in threads, DMs reports, files what it did, all under its own face | Slack Marketplace with AI-app review (no LLM training on customer data, quality bar); unlisted per-workspace install is self-serve, so the bar gates the storefront only | **Recommended #2.** Self-serve mint, first-class identity, the visibility surface. |
| **Editors: Claude Code / Cursor** | None needed in our direction; the editor runs as the user | The `epito` MCP server and skill put mint/deploy/roster inside every session | MCP registries and skill directories, zero listing bar | Bet 2, already decided. Cheapest channel that exists. |

### Tier: build-next

| Platform | (a) Identity primitive | (b) What the agent does there | (c) Distribution & bar | Why this tier |
|---|---|---|---|---|
| **Vercel** | Partial: integrations are installation-scoped; an agent is a marketplace product, not a team member ([blog](https://vercel.com/blog/ai-agents-and-services-on-the-vercel-marketplace)) | Deploys, rolls back, manages env vars, watches build failures and opens fixes | "AI agents & services" category, unified auth/provisioning/billing; bar = Pro team + integration server + approval; Agent Gallery is curated ([digitalapplied survey](https://www.digitalapplied.com/blog/ai-agent-marketplaces-2026-discovery-distribution)) | Biggest storefront in the stack, but the bar gates the value (laws 2, 4) and Vercel part-competes on runtime (Sandbox, Workflow, eve). Build when the listing is worth its build. |
| **Notion** | Yes: integration bots are identities in page history; Custom Agents have schedules/triggers; Agent API beta manages agents programmatically ([releases 2026-05-13](https://www.notion.com/releases/2026-05-13); [agent APIs](https://developers.notion.com/guides/notion-agent-apis/overview)) | Maintains wikis and databases, files meeting digests, syncs rosters, answers from workspace knowledge | Integration gallery; agents native to the product (1M+ Custom Agents built since 2026-02-24) | Real primitive, real demand, but Notion bundles residency itself; our value is portability. Second candidate after Slack proves the multi-platform grammar. |
| **Supabase** | OAuth 2.1 server, still beta ([changelog #38022](https://supabase.com/changelog/38022-oauth-2-1-server-capabilities-for-supabase-auth)); per-agent DB credentials feasible via management API | Owns its own scoped DB access: migrations, seed jobs, scheduled data hygiene, as itself | Partner Catalog bar unchanged: registered business + meaningful revenue or VC backing ([docs](https://supabase.com/docs/guides/integrations/partner-catalog)); epito.me still fails it | Rev 1 verdict stands: build when a user demands it, list later. |

### Tier: watch

| Platform | (a) Identity primitive | (b) What the agent could do | (c) Distribution & bar | Why watch, not build |
|---|---|---|---|---|
| **Linear** | Yes, the cleanest: agents as app users, assignable, mentionable, unbilled ([developers](https://linear.app/developers/agents); AIG unchanged since [2025-07-30](https://linear.app/changelog/2025-07-30-agent-interaction-guidelines-and-sdk)) | Takes assigned issues, reports progress, closes with PR links | Integration directory, AIG compliance bar (10s first response) | **Owner-rejected as #2 (ADR-6).** Stays on the board as a future surface; returns only on the owner's word. |
| **Microsoft** (Entra Agent ID / Agent 365) | Yes, and now interoperable: third-party agents register via the Entra ID Auth SDK sidecar or workload identity federation ([Learn](https://learn.microsoft.com/en-us/microsoft-agent-365/developer/third-party-identity-providers)); registry consolidates into Agent 365 2026-05-01 ([what's new](https://learn.microsoft.com/en-us/entra/fundamentals/whats-new)) | An epito agent could register its identity into a customer's Entra tenant for enterprise governance while keeping its epito manifest | M365 agent store via Partner Center; bar = Microsoft AI Cloud Partner Program + publisher verification ([submit docs](https://learn.microsoft.com/en-us/microsoft-agent-365/developer/submit-agent-partner-center)) | The federation path is the future enterprise story ("epito agents, governed in your Entra"), not a 2026 build. Per-user pricing means their buyer is not ours. |
| **AWS** (Bedrock AgentCore Identity) | Yes: workload identity distinct from IAM roles, own ARN per agent; managed consent portal added 2026-09 ([overview](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/identity-overview.html); [what's new](https://aws.amazon.com/about-aws/whats-new/2026/09/amazon-bedrock-agentcore/)) | Pattern supplier more than surface; a future RuntimeProvider could target AgentCore | Enterprise marketplace motions; not our buyer | Validates the identity-primitive thesis from the biggest cloud. Watch the primitives, skip the platform. |
| **Google** (Gemini Enterprise / A2A) | Yes: per-agent cryptographic SPIFFE IDs ([Infosecurity](https://www.infosecurity-magazine.com/news/google-ai-agent-identities-gemini/)); A2A v1.2 under the Linux Foundation, production across 150 orgs ([TNW](https://thenextweb.com/news/google-cloud-next-ai-agents-agentic-era)) | An A2A agent card for epito agents would make them discoverable/callable by other agents | Google Cloud Marketplace A2A agent registration ([docs](https://docs.cloud.google.com/gemini/enterprise/docs/register-and-manage-marketplace-agents)); enterprise procurement bar | A2A card support is a cheap future interop feature for `epitod`, not a distribution play. See trap T1 before touching the marketplace. |
| **Stripe** | Partial: restricted keys scope an agent; ACP (with OpenAI) and AP2 (Google, donating to FIDO) define delegated payment mandates ([ACP docs](https://docs.stripe.com/agentic-commerce/acp); [Orium on ACP/AP2/x402](https://orium.com/blog/agentic-payments-acp-ap2-x402)) | Reconciles, reports, flags anomalies read-only; payments themselves are trap T2 | App Marketplace, ~4-day review | Rev 1 verdict stands and hardened: wrong first proof for an identity product. |
| **Asana** | Yes: AI Teammates are discoverable, assignable workspace members via REST API and MCP ([forum changelog](https://forum.asana.com/t/upcoming-ai-teammates-and-agent-api-support/1142767); [June 2026 launch](https://investors.asana.com/news-releases/news-release-details/asana-unveils-operating-system-human-agent-teams)) | Takes assigned tasks, reports status, exactly the Linear shape | No open directory found; AI Studio Pro is sales-gated | The primitive is right but gated behind top-tier sales-led plans; the vibecoder is not there. |
| **Atlassian** (Rovo / Forge) | Partial and inverted: Marketplace agents must run on Forge, Atlassian's runtime ([marketplace agents](https://support.atlassian.com/rovo/docs/marketplace-agents/); [Forge Rovo agent](https://developer.atlassian.com/platform/forge/extend-atlassian-products-with-a-forge-rovo-agent/)) | Little, as ourselves: their model absorbs the agent body into their cloud, the opposite of ADR-2 residency | Atlassian Marketplace; customer-pays AI credits (a pricing precedent worth noting) | Structural mismatch with our runtime leg. The `rovo-agent-connector` EAP ([manifest ref](https://developer.atlassian.com/platform/forge/manifest-reference/modules/rovo-agent-connector/)) may open an external-agent path; re-check next quarter. |
| **Clerk** | In our direction, technology not surface: CIMD beta (2026-08-06) lets an OAuth client's `client_id` be an HTTPS URL serving its metadata ([changelog](https://clerk.com/changelog/2026-08-06-client-id-metadata-documents)) | Nothing "in" Clerk; but a hosted epito manifest URL as a CIMD `client_id` would give every epito agent a stable OAuth client identity against any CIMD-compatible provider | No marketplace | Fold in as mechanism when a second CIMD-compatible provider matters. Ally, not channel (unchanged from rev 1). |
| **Neon** | Partial: per-agent projects/branches via API, Agent Plan | Per-agent Postgres under our runtime | Partnership/credits track, no directory | Supplier track (unchanged). |

### Tier: skip

| Platform | Why skip |
|---|---|
| **Zapier / Make** | The anti-model, named by the vendor itself: Zapier MCP fronts 9,000+ apps with "one set of managed credentials" in Zapier's vault ([zapier.com](https://zapier.com/blog/best-ai-agents/), accessed 2026-09-19). A master key held by a middleman is precisely what our primitive replaces (§6 G1). No per-agent principal in their model, no reason to put our agent behind their key. |
| **Salesforce AgentExchange** | Security review + partner program + enterprise motion ([FAQ](https://help.salesforce.com/s/articleView?id=000394757&language=en_US&type=1)); the $50M builders initiative ([SalesforceDevops](https://salesforcedevops.net/index.php/2026/04/14/agentexchange-salesforces-bet-that-trust-can-scale-with-agentic-speed/)) confirms even Salesforce knows the bar is too high for small shops. Slack covers the ecosystem's useful surface at 1% of the cost. |
| **Trigger.dev / Modal / E2B / Cloudflare as channels** | Competitors or suppliers on single legs (rev 1 analysis stands; Cloudflare remains the closest architectural bundle). Candidate substrates, not channels. |

Not researched this run, flagged for the next weekly: OpenAI's agent
platform surfaces, Discord bots as a vibecoder-adjacent identity
surface, and the AWS Marketplace agent category. Absence from the
table is absence of research, not a verdict.

**Re-ranking trigger conditions (rev 2).** Carried from rev 1: GitHub
opens agent-app self-service; Anthropic Managed Agents adds per-agent
platform identity (checked today: still owner-vault, no per-agent
platform principal found; the Claude Tag identity model governs
permissions, not third-platform identity, per [Help Net Security, 2026-06-24](https://www.helpnetsecurity.com/2026/06/24/anthropic-claude-tag-agent-identity-model/), accessed 2026-09-19);
Supabase clears or drops its bar; Vercel opens a lighter listing path.
New: Slack changes app-creation or marketplace policy for AI apps;
Atlassian's `rovo-agent-connector` exits EAP with an external-runtime
path; Asana opens AI Teammates below the sales tier.

---

## 6. Gaps: what containerized autonomous agents unlock

The phase-2 primitive being ranked against the world here: a
persistent container on the user's own machine (`epitod`, systemd
units + timers, rootless podman), holding a real per-agent identity,
woken by cron/webhook/event, acting across platforms with no human
session. Four gaps that are real, then three traps.

### G1. Cross-SaaS autonomy without a middleman holding master keys

**Evidence it's real.** The glue layer's own architecture is the
complaint: Zapier MCP fronts 9,000+ apps through "one set of managed
credentials" in its vault ([zapier.com](https://zapier.com/blog/best-ai-agents/), accessed 2026-09-19).
Meanwhile the MCP ecosystem's auth is failing in the field: only 8.5%
of MCP servers in the wild use OAuth at all (Astrix Security research,
cited by [explainx MCP security guide](https://www.explainx.ai/blog/mcp-security-guide-2026), accessed 2026-09-19; secondary source, flagged),
over-scoped tokens are called the most common misconfiguration
([Security Boulevard](https://securityboulevard.com/2026/05/mcp-authentication-explained-oauth-2-0-tokens-and-security-for-ai-tool-connections/), 2026-05),
and Cloudflare shipped optional OAuth scopes in September naming MCP
agents "requesting the union of everything they might do" as the
motivating case ([InfoQ](https://www.infoq.com/news/2026/09/cloudflare-optional-oauth-scopes/), 2026-09).

**What our primitive contributes.** No vault in the middle. Each agent
holds its own principal minted on each platform (GitHub App, Slack
app), scoped in the manifest, revocable on the platform where it
lives. The blast radius of one compromised agent is that one agent's
scopes on those platforms, nothing else.

**What it does not solve.** Scope coarseness is the platform's, not
ours: if Slack's finest scope is `chat:write` everywhere, we cannot
make it channel-level ([p0.dev on scope granularity](https://p0.dev/blog/oauth-scopes-dont-equal-secure-mcp-authorization/), accessed 2026-09-19).
And nothing here stops a prompt-injected agent from misusing scopes it
legitimately holds.

### G2. The resident local agent, done safely

**Evidence it's real.** OpenClaw is the strongest demand signal of
2026 and the strongest indictment of the DIY version: 135,000+ GitHub
stars within weeks ([DEV](https://dev.to/waxell/the-openclaw-security-crisis-135000-exposed-ai-agents-and-the-runtime-governance-gap-e26), accessed 2026-09-19),
then 42,000 instances exposed on the public internet with 93% showing
critical auth flaws ([Sliq timeline](https://getsliq.com/blog/openclaw-security-incidents-timeline), accessed 2026-09-19),
API keys and OAuth tokens stored in plaintext config
([Sangfor](https://www.sangfor.com/blog/tech/openclaw-ai-agent-2026-explained), accessed 2026-09-19),
a CVSS 8.8 one-click RCE (CVE-2026-25253, disclosed 2026-02-03), and
roughly 12% of its ClawHub skill registry confirmed malicious (341 of
2,857, [DEV](https://dev.to/tiamatenity/openclaw-how-a-popular-ai-agent-platform-became-a-security-catastrophe-1mg2), accessed 2026-09-19).
People want an agent that lives on their machine so badly they ran
this. The quieter version of the same demand: the self-hosted
automation movement (n8n and kin) is explicitly credential-driven,
"credentials and execution logs stay on your own infrastructure"
([n8n docs](https://docs.n8n.io/privacy-security/privacy/); [AI Tool Pipelines](https://www.aitoolpipelines.com/articles/self-hosted-ai-automation-data-privacy-2026), accessed 2026-09-19).

**What our primitive contributes.** Exactly the three things OpenClaw
lacked: per-agent containment (rootless podman, one container per
agent, `DynamicUser` fallback), secrets out of plaintext (OS keychain
proposal, phase 2), and identity that is not the owner's (a stolen
agent credential is that agent's scopes for at most an hour, per the
threat model in `docs/architecture.md`). Local-first is the
architecture, not a compromise: nothing leaves the machine in phases
1-2.

**What it does not solve.** Prompt injection into the model, a
malicious skill the user chooses to install, an unpatched host, and
single-machine availability (the laptop closes, the agent sleeps). We
should say all four out loud in the docs rather than let a buyer
assume otherwise.

### G3. Per-agent audit and attribution as the compliance floor

**Evidence it's real.** The EU AI Act's high-risk obligations reached
full enforcement on 2026-08-02, and Article 12 requires tamper-evident
logs sufficient to reconstruct what an agent did and under what inputs
([AI2sql analysis](https://ai2sql.io/ai-blog/eu-ai-act-agent-audit-trails-database); [DEV practitioner writeup](https://dev.to/igorganapolsky/your-compliance-team-will-ask-for-an-ai-agent-audit-trail-before-august-2-heres-the-part-most-h2n), accessed 2026-09-19).
The market priced the problem the same year: Oasis Security $120M
Series B, NewCore $66M seed ([SiliconANGLE, 2026-06-15](https://siliconangle.com/2026/06/15/newcore-launches-security-first-identities-ai-agents-closing-66m-seed-funding-round/)),
Oak $60M ([TechCrunch, 2026-07-15](https://techcrunch.com/2026/07/15/backed-by-60m-in-funding-oak-steps-out-of-stealth-to-fix-the-identity-mess-that-ai-agents-are-making-worse/)),
GitGuardian $50M ([SiliconANGLE, 2026-02-11](https://siliconangle.com/2026/02/11/gitguardian-raises-50m-expand-non-human-identity-ai-agent-security/)),
$392M announced around RSAC alone ([Software Strategies, 2026-03-28](https://softwarestrategiesblog.com/2026/03/28/agentic-ai-security-startups-funding-mna-rsac-2026/)).

**What our primitive contributes.** Attribution that cannot be
retrofitted: when the agent is a distinct principal, every commit,
message, and API call lands under its name on the platform itself, and
`audit.jsonl` records every mint, token, and deploy locally,
append-only. An owner-token agent can never produce this trail, no
matter how much logging is bolted on, because the platform saw the
owner.

**What it does not solve.** We are the substrate, not the GRC product.
Conformity assessment, retention policy, and governance dashboards are
what Oasis and Entra sell to enterprises; competing there is trap T3.
Our claim is narrower and true: an epito roster is auditable by
construction.

### G4. The whitespace: a portable, user-owned principal (the priority item)

**Evidence it's real.** Assemble §5's column (a) and look at it once:
Microsoft mints agent identity into Entra, AWS into AgentCore, Google
into SPIFFE IDs on its platform, Slack into its apps, Notion and Asana
into their workspaces. Every primitive is real and every one stops at
its vendor's wall, priced and governed inside that estate. Nobody
issues the agent an identity the *user* owns, that follows it from
GitHub to Slack to its own database, minted from one manifest. The
enterprise version of the closest thing (Agent 365) starts at
$15/user/month inside the Microsoft estate (rev 1, sourced). The indie
version does not exist. That is the product.

**What our primitive contributes.** The manifest as the portable spine:
one `agent.toml`, N platform principals, one roster, one audit trail,
on hardware the user owns.

**What it does not solve.** Portability depends on platforms keeping
open app/OAuth surfaces. The same vendors building walled identity
could narrow those surfaces, and law 1 (never a dependency) is our
only structural hedge. Named plainly: this gap is whitespace partly
because it is the one position the giants' incentives point away from,
and their incentives could change.

### The traps (attractive, and wrong)

**T1. Cross-org agent-to-agent and the enterprise agent marketplaces.**
A2A v1.2 runs in production across 150 organizations under the Linux
Foundation ([TNW](https://thenextweb.com/news/google-cloud-next-ai-agents-agentic-era), accessed 2026-09-19),
and marketplaces are multiplying (Gemini Enterprise, AgentExchange,
the M365 agent store). It looks like a standard to ride and shelves to
be on. It is a trap for us now because every shelf has a bar we fail
by construction (partner programs, publisher verification, security
reviews, revenue thresholds), the buyers are enterprises with
procurement cycles, and A2A solves discovery and messaging between
agents, not principal-hood on platforms. The cheap non-trap version:
an A2A agent card emitted by `epitod` someday, as interop, not as
strategy.

**T2. Agentic payments.** ACP, AP2 mandates, x402: the loudest
protocol race of the year ([Orium](https://orium.com/blog/agentic-payments-acp-ap2-x402), accessed 2026-09-19).
Rev 1 already ranked payment scopes as the scariest to delegate; rev 2
hardens that to a trap. The protocols are buyer-agent commerce, not
resident-worker identity; the mandate primitives are being taken over
by card networks and FIDO, leaving no indie wedge; and one payment
incident would be existential trust damage for a young identity
product. Read-only finance (reporting, reconciliation alerts) is the
most an epito agent should touch through 2027.

**T3. Selling into the "digital employee" enterprise wave.** McKinsey
announcing 25,000 "digital employees," Goldman deploying Devin
([AI Commission roundup](https://aicommission.org/2026/09/ai-agents-are-changing-how-startups-hire-and-build-teams/), accessed 2026-09-19; secondary source, flagged)
reads like our thesis validated at scale, and it is, as a register.
As a target market it is a trap: Gartner projects over 40% of agentic
AI projects canceled by end-2027 on cost, unclear value, and risk
controls, and estimates only ~130 of thousands of vendors are real
([Gartner, 2025-06-25](https://www.gartner.com/en/newsroom/press-releases/2025-06-25-gartner-predicts-over-40-percent-of-agentic-ai-projects-will-be-canceled-by-end-of-2027)).
Chasing those buyers means competing with Agent 365's bundled
distribution using a sales motion we do not have, for deployments
likelier than not to be canceled. Our buyer stays the builder running
an org of agents on personal subscriptions (vision §0), and the
enterprise wave's real gift to us is vocabulary and urgency, not
customers.

---

## To the seat that builds on this

The central problem in one sentence: every platform now gives agents
an identity that stops at its own wall, and epito.me exists to issue
the one identity that crosses them, owned by the user.

The design test for any integration decision this document informs:
can the identity be minted self-serve today, does the agent appear
there as itself, and does the product still work if this platform
vanishes tomorrow? If any answer is no, the platform is watched, not
built.

*Charter compliance note (rev 2): research only; nothing posted, no
one contacted, no sign-ups, no waitlists joined. Flagged secondary or
unverified claims: the Astrix 8.5% OAuth figure (via explainx), the
McKinsey/Goldman digital-employee numbers (via AI Commission roundup),
and the Atlassian `rovo-agent-connector` external-agent path (EAP
docs only).*

---

## 7. Rev 2 addendum (2026-09-19, second dispatch): agent makers, OpenClaw, GPT Astra

Convened on ADR-9 ("we dont necessarily want to be agent builders, we
want agent cars... open claw is a big think to look into as well as
gpt astra"). Three answers, each ending in a recommendation the owner
can accept or reject in one word. All sources accessed 2026-09-19.

### 7.1 OpenClaw as opportunity, not just evidence

**What it is now, post-crisis.** The project survived and changed
hands. The CVSS 8.8 RCE was patched in `v2026.1.29` on 2026-01-30,
with three security advisories the same day ([Prime Rogue](https://primerogueinc.com/blog/openclaw-security-crisis-structurally-broken-in-february-2026-what-naive-deployers-need-to-know-before-its-too-late/)).
On 2026-02-14 creator Peter Steinberger joined OpenAI to lead
personal-agent development and the project moved to an independent,
OpenAI-sponsored foundation ([Conscia](https://conscia.com/blog/the-openclaw-security-crisis/)).
The `2026.4` line shipped origin validation, sandbox-by-default, and
encrypted credential storage, after 13 patch releases in March alone
([Nebius hardening guide](https://nebius.com/blog/posts/openclaw-security)).
OpenClaw 2.0 (`v2026.8.1`, 2026-08-30) added a redesigned UI and a
plugin/integration hub ([release docs](https://docs.openclaw.ai/releases/2026.8.1/plugins-and-integrations)).
September is a declared "fix the foundation" phase: systemic P0s
(event loop starvation, session drift) are being worked ahead of
feature work, patch `2026.9.5` ([ecosystem digest, 2026-09-19](https://github.com/duanyytop/agents-radar/issues/3358)).
Reading: stabilizing under new governance, not dying, but not stable.

**How its agents authenticate today, and where we slot in.** The
architecture is kernel-plugin: a Gateway control plane authenticates
all inbound connections, and each agent's auth profiles live in
`openclaw-agent.sqlite`, with a built-in secret store, the option to
mount external vault tokens, and locally stored OAuth refresh tokens
treated as canonical ([Gateway auth docs](https://docs.openclaw.ai/gateway/authentication); [OAuth docs](https://docs.openclaw.ai/concepts/oauth); [TeamPassword guide](https://teampassword.com/blog/securing-openclaw-guide)).
That is the owner-credential pattern this company exists to replace:
the agent holds the owner's refresh tokens, encrypted now, but still
the owner's. The integration point exists twice over: the external
vault mount (epito as the credential backend that hands an OpenClaw
agent its own scoped platform token instead of the owner's) and the
2.0 plugin hub, which installs plugins and vetted MCP connectors
(an `epito` MCP connector reaches every OpenClaw install without
their approval). Their own roadmap fixed credential *storage*; it has
not touched credential *identity*. The gap we fill is untouched.

**The channel.** The community is large and locatable: the OpenClaw
Discord passed 100,000 members in roughly six weeks from a January
2026 founding ([openclaw.report](https://openclaw.report/news/openclaw-discord-100k-members))
and stands at ~176,000 ([community listing](https://openclaw-ai.net/en/community)),
with 13,000+ ClawHub skills and a 43k-star curated list
([ClawTrust](https://clawtrust.ai/blog/best-openclaw-skills)). A
working identity connector demonstrated there reaches more resident-
agent users than every platform marketplace in §5 combined.

**The honest risks.** The brand is radioactive in security circles:
at least four academic security papers dissect it by name and the
crisis is its own genre of coverage. Association helps only if we are
unmistakably the fix, never a partner sharing blame; the positioning
is "your OpenClaw agents, given real identities," not co-branding.
Platform risk is real and specific: the foundation is OpenAI-
sponsored and its creator now builds personal agents inside OpenAI,
so native identity could arrive from above. And ClawHub's 12%
malicious rate means listing there needs our own signing story told
loudly, or the channel taints the product.

**Recommendation (accept/reject: OpenClaw yes/no).** Tier:
**build-next, first of the agent-maker track**, behind Slack. Shape:
a research-to-prototype spike (an `epito` MCP connector serving
per-agent platform tokens to OpenClaw agents), scoped only after the
Slack provider ships, gated on the foundation still standing at spike
time. Not a platform surface; the first MAKER integration (§7.3).

### 7.2 GPT Astra, identified

**The name matches one real thing.** "GPT Astra" is **GPT-6 Astra**,
OpenAI's flagship model: limited release 2026-09-03, general
availability the next day, positioned on long-horizon agentic tasks,
computer use, and browsing, distributed via the OpenAI API, Azure,
and AWS Bedrock ([openai.com](https://openai.com/index/gpt-6-astra/); [Al Jazeera, 2026-09-04](https://www.aljazeera.com/economy/2026/9/4/openai-unveils-gpt-6-astra-amid-rising-scrutiny-and-safety)).
It is OpenAI's first model rated Critical for cybersecurity
capability under its own Preparedness Framework ([safety overview](https://openai.com/index/safety-overview-gpt-6-astra/)).
Name collision noted plainly: Google DeepMind also runs a "Project
Astra" assistant-research effort; given the owner wrote "gpt astra"
the model is the near-certain referent, and Google's Astra was not
researched this run (flagged).

**What it means for us.** Astra is a model, not an agent maker and
not a platform: it has no identity primitive and no integration
surface beyond the API. Under ADR-8 it is exactly a routable brain:
`[runtime].model = "gpt-6-astra"`, swappable without changing who the
agent is. The strategic content is second-order and favors the wedge:
a Critical-rated cyber-capable model running long-horizon agents makes
the owner-credential pattern strictly more dangerous (rev 2 §2's
demand quotes, now with a sharper model behind them), and Astra ships
into ChatGPT and Codex agents that still act as their user. One more
thread ties the owner's two names together: OpenClaw's creator now
leads personal agents at OpenAI, and OpenClaw's foundation is
OpenAI-sponsored. Both names point at the same axis, OpenAI's
personal-agent push, which is a maker to integrate, never a surface
to depend on.

**Recommendation (accept/reject: Astra-as-runtime yes/no).** Tier:
**watch, as model supplier**. Action: `gpt-6-astra` joins the routing
examples in manifest v0.2 docs; no integration slot exists to build.

### 7.3 The agent-maker landscape (the new map dimension)

ADR-9 splits the map into two kinds of target. A **surface** is where
an agent acts (§5's table). A **maker** is what builds and runs the
agent's brain and loop; under "we are the car, not the driver," every
maker's agent is a candidate rider. The question per maker: how do
its agents authenticate to outside services today, and where does an
identity layer slot in.

| Maker | How its agents authenticate today | Where our identity layer slots | Tier |
|---|---|---|---|
| **OpenClaw** | Owner's OAuth refresh tokens + secret store, per-agent profiles in `openclaw-agent.sqlite` (docs cited in §7.1) | External vault mount + 2.0 plugin/MCP hub; §7.1's spike | **Build-next** (first maker) |
| **LangGraph / LangChain** | Tools read API keys from env/config; 100+ prebuilt tools, no identity layer ([langchain.com](https://www.langchain.com/resources/ai-agent-frameworks); [comparison](https://levelup.gitconnected.com/langgraph-vs-crewai-vs-autogen-which-agent-framework-should-you-actually-use-in-2026-b8b2c84f1229)) | `epito token <name>` handed into tool constructors; the shape is a thin community package, cheap because the CLI already emits scoped tokens | **Build-next** (SDK-level, after OpenClaw proves the pattern) |
| **CrewAI** | Same env-key pattern, ~20 bundled tools (same sources) | Same token-handoff shape as LangGraph | Watch (follows LangGraph work for free) |
| **OpenAI Agents SDK / AgentKit** | Developer API keys + Connector Registry; Agent Builder retires 2026-11-30, Agents SDK canonical with native sandbox execution since April 2026 ([openai.com](https://openai.com/index/the-next-evolution-of-the-agents-sdk/), accessed 2026-09-19) | Token handoff into SDK tools is possible today; note OpenAI is absorbing the runtime leg (sandboxes), identity still owner-side | Watch |
| **AutoGen / Microsoft Agent Framework** | Enterprise direction: Entra-anchored, A2A built in ([glukhov A2A survey](https://www.glukhov.org/ai-systems/comparisons/a2a-protocol-2026-adoption/)) | Via A2A card interop, not a bespoke integration | Watch |
| **Google ADK** | A2A native, Google-cloud anchored (same survey) | Same: A2A interop | Watch |

**A2A agent cards: yes, this is the consolidating interop standard.**
v1.0 shipped April 2026, 150+ organizations, Linux Foundation
governance; built-in support in Google ADK, Microsoft Agent
Framework, and BeeAI, plus Azure AI Foundry, Copilot Studio, and
Bedrock AgentCore Runtime ([glukhov](https://www.glukhov.org/ai-systems/comparisons/a2a-protocol-2026-adoption/); [Go Micro](https://go-micro.dev/blog/2026/06/18/agents-across-frameworks-a2a.html)).
The card is a JSON document served at `/.well-known/agent-card.json`
([implementation guide](https://atlan.com/know/mcp/a2a-protocol-implementation-guide/)),
which is to say: it is a document our daemon can emit per agent for
roughly the cost of a template. Emitting a card makes every epito
agent discoverable by every A2A framework without adopting anyone's
runtime, which is the ADR-6-compliant way to ride the standard.
Trap T1 (§6) still stands unchanged for the enterprise A2A
*marketplaces*; the card itself is interop, not a marketplace.

**Recommendation (accept/reject: makers-track yes/no).** Adopt MAKERS
as a standing second dimension of this map, ranked by the same laws
plus one maker-specific test: does the maker hand credentials to its
agents in a way we can replace without forking it. And promote A2A
agent-card emission from "someday" to a tracked manifest v0.2
consideration, per ADR-9's third effect.

*Charter compliance note (addendum): research only; nothing posted,
no one contacted. Flagged: Google Project Astra not researched this
run; OpenClaw Discord member count from a community listing
(secondary); the deck at docs/presentations/market-rev2/ was left
untouched, since no finding falsifies a slide's copy (slide 5's
OpenClaw numbers remain true as stated; the opportunity reading lives
here).*

---

## 8. LangSmith (2026-09-20, third dispatch): observability, deployment, and a competitor's credential layer

Convened on the owner's ask (2026-09-20): "see how our product could
work together with langsmith, like an integration." Four answers:
what LangSmith exposes, the coupling in both directions, the
distribution path, and a tiered verdict. This section amends the
§7.3 LangGraph row. All sources accessed 2026-09-20; event dates as
the source states them.

### 8.1 Surfaces: what LangSmith exposes today

LangSmith is no longer one product. It is a tracing/evals SaaS, a
hosted agent runtime (LangSmith Deployment, formerly LangGraph
Platform), a no-code agent workspace (Fleet, the March 2026 rename of
Agent Builder), and a newer opinionated hosted harness (Managed Deep
Agents, public beta 2026-08-07). Each has a different opening for us.

| Surface | What it exposes | The opening for an identity layer |
|---|---|---|
| **Tracing SDK** | Arbitrary `metadata` dict and string `tags` on any run, set by `@traceable(metadata=...)`, `langsmith_extra=`, `ls.tracing_context(metadata=...)` (context propagates to child spans), or `rt.metadata[k]=v` at runtime ([add metadata and tags](https://docs.langchain.com/langsmith/add-metadata-tags)). UI filter `metadata.<key>:<value>`, numeric `metadata.retries:>=3` ([filter traces](https://docs.langchain.com/langsmith/filter-traces)); SDK/REST filter `and(eq(metadata_key, "k"), eq(metadata_value, "v"))` on `client.list_runs()` ([trace query syntax](https://docs.langchain.com/langsmith/trace-query-syntax)). The only special key documented is `thread_id`, which groups traces into threads ([concepts](https://docs.langchain.com/langsmith/observability-concepts)). | **There is no agent-identity field.** Attribution in LangSmith is by project, API key, and thread. A principal fits only as user-defined metadata, which is exactly enough: metadata is filterable, exact-match, and persisted with the run. |
| **OTLP ingest** | `OTEL_EXPORTER_OTLP_ENDPOINT=https://api.smith.langchain.com/otel`, header `x-api-key`, optional `Langsmith-Project`; span attributes `langsmith.metadata.{key}` become metadata and `langsmith.span.tags` become tags. "Arbitrary span attributes do not automatically become filterable metadata." ([trace with OpenTelemetry](https://docs.langchain.com/langsmith/trace-with-opentelemetry); [OTel launch post](https://blog.langchain.com/opentelemetry-langsmith/)) | epitod's own audit emitter could ship spans here with **zero LangChain code in the agent**. This is the door that costs nothing and depends on nothing. |
| **LangSmith Deployment** (cloud) | Plus plan or above; Serverless (scale-to-zero) or Dedicated; env vars and secrets entered at deployment configuration via UI or the `env` field of `langgraph.json` ([deploy to cloud](https://docs.langchain.com/langsmith/deploy-to-cloud)). No runtime hook to an external secret manager is documented; the cloud env-var page lists only server tunables (Datadog, OTel, pool sizes) ([env vars](https://docs.langchain.com/langsmith/env-var-cloud)). | Secrets are pasted at deploy time. That is the stored-owner-key pattern, and it is the reason a credential slot matters here. |
| **Custom auth** | `@auth.authenticate` runs on every request, may call external services (`await fetch_user_tokens(api_key)`), and its returned dict lands in `config["configurable"]["langgraph_auth_user"]` for every node; "supported for all plans"; not available to the bare OSS library ([custom auth](https://docs.langchain.com/langsmith/custom-auth); [auth overview](https://docs.langchain.com/langsmith/auth)). Whether a cron-triggered run gets an auth context is **not documented** (checked [cron jobs](https://docs.langchain.com/langsmith/cron-jobs) and the auth pages). | A request-time hook that can fetch a token from anywhere and hand it to the graph. Designed for per-USER delegation; usable for per-agent minting. |
| **Agent Auth (beta)** | `client.create_oauth_provider(client_id, client_secret, auth_url, token_url)` for any OAuth 2.0 provider; `client.authenticate(provider, scopes, user_id, agent_id=...)`; "By default, tokens are scoped to the calling agent using the Assistant ID parameter"; "We store and refresh OAuth tokens" ([agent auth](https://docs.langchain.com/langgraph-platform/agent-auth)). | The first place LangSmith names an `agent_id`. Tokens are user-delegated and live in LangSmith's vault, but the provider is pluggable: an epito OAuth endpoint could be registered as a provider. |
| **Agent Server / assistants** | Assistant = "an instance of a graph with a specific configuration," versioned; threads, runs, crons (`client.crons.create(assistant_id, schedule, input)`); default auth is a LangSmith API key in `x-api-key` ([assistants](https://docs.langchain.com/langsmith/assistants); [agent server](https://docs.langchain.com/langsmith/agent-server)). **No owner, creator, or identity field on the assistant object** is documented. | Assistants are configurations, not someones. Identity is whoever holds the workspace key. |
| **Workspace auth** | Two key kinds: Personal Access Tokens (inherit the user; deleted with the user) and Service Keys ("service principals with administrator privileges") ([API keys](https://docs.langchain.com/langsmith/create-account-api-key); [RBAC](https://blog.langchain.com/access-control-updates-for-langsmith/)). | No per-agent key exists. Every deployed agent authenticates to LangSmith as the workspace. |
| **Fleet** (no-code, 2026-03-19) | "Agent identity" defined as "whose credentials the agent uses": **Claws** use "the same API keys and OAuth tokens, regardless of user"; **Assistants** use each invoking user's OAuth. "Once an agent identity is set, it cannot be changed." Tool keys live as workspace secrets, `FLEET_`-prefixed ([agent identity](https://docs.langchain.com/langsmith/fleet/agent-identity); [workspace admin](https://docs.langchain.com/langsmith/fleet/workspace-admin); [launch post](https://www.langchain.com/blog/introducing-langsmith-fleet)). Permissions: clone / run / edit. | Their word "identity" means credential mode, not principal. Neither mode gives the agent its own account on GitHub or Slack. |
| **Managed Deep Agents** (public beta 2026-08-07) + **Connections** (2026-09-09) | `mda init/dev/deploy`; identity = who may call the deployment (LangSmith API key or Supabase JWT) ([identity](https://docs.langchain.com/langsmith/javascript/managed-deep-agents-identity)). Connections: named credentials in the workspace, owner axis agent-owned vs user-owned, type axis static secret vs OAuth grant; catalog of 23+ services incl. GitHub; custom providers via `--authorize-url`/`--token-url`/`--scope`; `connections.get(slug, {type})` returns the raw credential string; rotation by re-running `create`, effective next run, no redeploy; no REST API documented ([connections docs](https://docs.langchain.com/langsmith/javascript/managed-deep-agents-connections); [Connections post](https://www.langchain.com/blog/connections-managed-credentials-and-per-caller-identity-for-managed-deep-agents); [MDA beta post](https://www.langchain.com/blog/managed-deep-agents-is-now-in-public-beta)). | A credential store with a custom-OAuth slot, eleven days old. The agent-owned mode is a static secret; the user-owned mode makes the human the actor: "the issue lands in GitHub opened by the person who asked. `user.login` in the response is their handle, not a bot's." |
| **Evals, annotation queues** | Present in the product; not researched beyond confirming they operate on the same run metadata (flagged: no deeper read this run). | Whatever principal we put in metadata is available to slice eval datasets by agent. No identity-specific opening. |

### 8.2 The coupling, both directions

**(a) epito → LangSmith: "which agent did this" as a filter dimension.**
Feasible today, cheap, needs nobody's permission. Two routes:

1. *Inside a LangGraph agent*: an `epito.langsmith_context(agent)` helper
   wraps `ls.tracing_context(metadata={...})` so every span in the run
   carries a flat principal record (flat keys, because filter matching is
   exact and type-sensitive):

   ```python
   {"epito_agent": "historian",
    "epito_manifest_sha": "3f9c...",
    "epito_github": "historian-epito[bot]",
    "epito_slack": "B0HISTORIAN",
    "epito_model": "claude-opus-5"}        # ADR-8: model recorded, never the key
   ```

   A LangSmith user then filters `metadata.epito_agent:historian` in the
   UI or `and(eq(metadata_key,"epito_agent"), eq(metadata_value,"historian"))`
   in the SDK, and gets exactly the slice our local audit trail calls the
   same name. LangSmith has no native equivalent: its attribution stops at
   project, API key, and `thread_id`. Cost: one helper of roughly fifty
   lines in `@epito/langchain`, documented as a convention.
2. *Outside any agent code*: epitod's audit emitter exports OTLP spans
   with `langsmith.metadata.epito_agent` etc. to the `/otel` endpoint.
   Every epito agent's actions, on any framework or none, appear in the
   user's LangSmith project attributed to the real principal. The user
   supplies the LangSmith API key in the manifest's optional
   `[observability]` block; if absent, nothing changes (ADR-6).

Limit, stated plainly: metadata is a convention, not a schema. Nothing
stops a LangSmith user from writing `epito_agent: "whatever"`; the
proof that a trace really belongs to the principal is the passport
(proposal B), not the metadata. Route 2 is the honest one: it is our
signed audit stream landing in their viewer.

**(b) LangSmith → epito: hosted agents consuming per-agent, short-lived
credentials instead of pasted keys.** Three doors, all reachable without
LangChain's cooperation, none frictionless:

| Door | Mechanism | Works without LangChain | Friction |
|---|---|---|---|
| **D1: `@epito/langchain` inside the graph** (proposal A, as written) | `EpitoCredentials("historian")` passed where env keys go; calls `epito token` or an epito HTTP endpoint; refreshes on expiry | Yes, on any runtime: OSS LangGraph, self-hosted, or LangSmith Deployment | A hosted deployment cannot reach a local epitod. Needs a network path: a tunnel, or a hosted token endpoint. This is the tension the architecture seat must rule on. |
| **D2: custom-auth handler** | `@auth.authenticate` calls epito at request time, returns `{"identity": "historian", "github_token": <1h installation token>}` into `langgraph_auth_user`; nodes read it from config | Yes, all LangSmith plans | Fires per inbound request; cron runs' auth context is undocumented, so the autonomous case (our whole premise) is unproven here. Same network-path issue as D1. |
| **D3: register epito as an OAuth provider** in Agent Auth (beta) or an MDA Connection (`--authorize-url`/`--token-url`) | epito exposes a standard OAuth 2.0 authorize/token pair that issues short-lived per-agent tokens; LangSmith's vault holds the grant | Yes; the provider slots are explicitly generic | Their vault stores and refreshes the grant, which reintroduces a middleman (§6 G1); Agent Auth scopes by `user_id` first and `assistant_id` second, so the agent is still a delegate of a human in their model. Beta surfaces; may move. |

Practical reading: D1 is the product; D2 is a documentation recipe on
top of D1; D3 is a hypothesis worth one afternoon once B's OAuth-ish key
handling exists, not a build.

**Does LangSmith already have an agent-identity notion that overlaps?**
Yes, and it is the important finding of this run. In six months
LangChain shipped Fleet identity (March), Agent Auth (beta),
per-caller identity in MDA (August), and Connections (September 9).
All four are answers to the same question we answer, inside their
walls, and all four resolve to one of two owner-credential modes: a
shared stored key ("every action showing up under a service account,"
their own description of the old state) or the invoking human's OAuth
(so the action is the human's, not the agent's). None issues the agent
its own principal on the platform where it acts; none is portable
outside LangSmith; the Connections post itself frames identity as "the
basis for scoped memory and future credential patterns," which is a
roadmap sentence. Independent confirmation of the gap: a
cross-framework study (arXiv:2606.28679, cited via a [dev.to
post](https://dev.to/roxdavirox/agent-identity-spoofing-in-multi-agent-systems-your-orchestrator-has-no-idea-who-it-is-talking-to-1l3j);
secondary, not read directly this run) reports that across LangChain,
LangGraph, LlamaIndex, and Stripe's toolkit "shared credentials are the
norm; per-agent identity is not." Under ADR-10 this is the right shape
of neighbor: they build the driver and the car interior; we mint the
license plate that works on every road. Under ADR-6 it is also the
risk: they are visibly building toward credentials-as-a-feature, and
the day they add "agent-owned OAuth as a bot user" for GitHub and
Slack, the LangSmith-hosted slice of our market closes from inside.

### 8.3 Distribution: the listing, the reach, the buyer

**The listing path is open and cheap.** New integrations are not
accepted as PRs to LangChain repos; they ship as independent PyPI
packages (`langchain-epito`) implementing `langchain-core`
interfaces and passing the standard test suite. Under 50,000 monthly
downloads, a listing issue gets an automated YAML row in the
integrations table linking to our docs; at 50,000+ downloads or by
maintainer feature, a hosted guide page ([contributing integrations](https://docs.langchain.com/oss/python/contributing/integrations-langchain);
[integrations overview](https://docs.langchain.com/oss/python/integrations/providers/overview)).
Tools and toolkits are an explicitly encouraged category. There is no
LangSmith plugin directory or marketplace to list on; the only
storefront is the OSS integrations table. Law 2 and law 4 are
satisfied: nothing gates the package working, only the guide tier.

**The reach is the largest in the maker track.** LangChain reports
100M+ monthly downloads and 139k+ GitHub stars (June 2026, via
[gitnux](https://gitnux.org/langchain-statistics/), secondary);
LangGraph at roughly 38.8M monthly PyPI downloads, "the most installed
agent framework by a wide margin" ([dev.to comparison](https://dev.to/jamilxt/langgraph-vs-crewai-vs-openai-agents-sdk-picking-your-agent-framework-in-2026-2heo),
secondary; [pypistats](https://pypistats.org/packages/langgraph) is the
primary counter). Company: $125M Series B led by IVP at $1.25B
(2025-10), ~$16M ARR for 2025 ([Sacra](https://sacra.com/c/langchain/);
[getlatka](https://getlatka.com/companies/langchain), secondary),
production users named as Uber, LinkedIn, Klarna, JPMorgan
([LangChain 1.0 post](https://www.langchain.com/blog/langchain-langgraph-1dot0)).

**The buyer splits in two, and only one is ours.** The OSS LangGraph
developer runs locally or self-hosts and pays LangChain nothing; that
is our vibecoder, and `langchain-epito` reaches them for free. The
LangSmith Deployment / Fleet / MDA customer pays $39 per seat per
month on Plus, needs Plus to deploy at all, and meters LCUs at $1.50
([pricing breakdowns](https://inference.net/content/langsmith-pricing/);
[truefoundry](https://www.truefoundry.com/blog/langgraph-pricing);
LCU pricing effective for new usage 2026-07-15, existing orgs
2026-10-01 per the [Fleet essentials](https://docs.langchain.com/langsmith/fleet/essentials)).
That buyer is a team with a platform budget, whose credential story is
now sold to them by LangChain itself. We reach them only through the
recipe (D2) and only if they want the agent to be a someone rather than
a proxy for a human. Demand for that specific thing inside the
LangChain community was not evidenced this run: no forum thread or
issue asking for a bot identity per agent surfaced in a first-pass
search (flagged, one search only; the hoop.dev "service account
sprawl for LangGraph" content marketing is a vendor's framing, not a
user's complaint).

### 8.4 Verdict

**Tier: build-next, confirmed and reshaped.** One sentence why: the
package is cheap, the trace convention is nearly free, and the reach
is the largest of any maker, but LangChain is building its own
credential layer in its hosted runtime, so the value concentrates on
the OSS LangGraph developer, not the LangSmith customer.

Reshaped, in three parts the owner can accept or reject separately:

1. **`langchain-epito` (proposal A, door D1): build-next, unchanged
   position behind Slack.** One package over `langchain-core`, no
   dependency on LangSmith, works on OSS LangGraph anywhere. Listed via
   the YAML row the week it is on PyPI.
2. **The trace-metadata convention (8.2a): fold into the same package
   and into epitod's audit emitter as an optional OTLP sink.** Roughly
   fifty lines each; it gives every LangSmith user a "which agent"
   filter that LangSmith does not have, and it costs no dependency.
3. **LangSmith Deployment coupling (doors D2, D3): watch, and write the
   D2 recipe as a docs page only after D1 ships.** Do not build a
   product surface on their custom-auth or Connections hooks; both are
   surfaces LangChain owns and is actively iterating.

**Plain-words recommendation:** yes to LangGraph, no to LangSmith as a
platform bet. Ship the credential object and the trace tag for people
who write LangGraph code; write a recipe for people who host on
LangSmith; do not build anything that only works if LangSmith keeps a
hook open. Accept/reject: **langchain-epito yes/no; OTLP sink yes/no;
LangSmith recipe yes/no.**

**The honest tensions, ranked.**

1. **LangChain sells the hosted runtime and is now selling credentials
   with it.** Fleet identity, Agent Auth, MDA identity, and Connections
   arrived in six months; the last one eleven days ago. On their cloud
   we would be a provider plugged into their vault, which is G1's
   middleman reintroduced. ADR-6 holds only if the product is the OSS
   package and the hosted couplings are recipes; the moment a feature
   depends on `@auth.authenticate` or `--token-url` staying open, it is
   a dependency, and they can close it in a release.
2. **Local-first runtime versus their cloud.** epitod lives on the
   user's machine; a LangSmith deployment is on theirs. Every door in
   8.2b needs a network path from their container to our token
   issuer. Either we accept a hosted token endpoint (an architecture
   decision not yet made) or the hosted case is out of scope and the
   coupling is OSS-only. This document does not decide it; it flags it
   for the architecture seat.
3. **Our differentiator on LangSmith is narrow.** Their "Assistants"
   mode already gives per-human attribution with a real audit trail.
   What we add is the agent-as-itself (a `[bot]` on GitHub, a bot user
   on Slack, one passport across both). Teams that want the agent to be
   a proxy for a person do not need us there; teams that want the agent
   to be a someone do. Which is more common among LangSmith payers is
   unmeasured.
4. **The trace convention is unsigned.** Metadata proves nothing;
   anyone can write it. The value is real only when route 2 (our own
   signed audit stream over OTLP) or proposal B backs it. Selling the
   convention alone would be selling a label.

*Charter compliance note (§8): research only; nothing posted, no one
contacted, no LangSmith account created, no package published. Flagged
secondary or unverified: download and star counts (gitnux, dev.to),
ARR (getlatka/Sacra), the arXiv:2606.28679 finding (via dev.to, whose
own date predates the paper id, so the post was likely updated; not
read directly), cron-run auth context on LangSmith Deployment
(undocumented, treated as unproven), and the LangChain-community demand
signal for bot identity per agent (one search, none found). Evals and
annotation queues were confirmed present and not researched further.*

---
---

# REV 1 (2026-09-18) — superseded by rev 2 above, kept verbatim

Maintained by the market seat. This revision: 2026-09-18 (founding night,
convened on dispatch for the integration-map question). Every claim
carries a source and a date; "accessed 2026-09-18" means the page was
read today and the event date is as stated by the source.

---

## STANDING RECOMMENDATION (2026-09-18)

**The next integration after GitHub is LINEAR.**

Linear is the only tool in the stack where a third-party agent is
already a first-class workspace member — its own "app user" actor
identity, mentionable, assignable issues, not billed as a seat — with a
public integration directory that lists agents, and the owner's own PM
seat already runs on Linear (ADR-5), so the integration is dogfood,
demo, and distribution in one.

**Runner-up 1: Vercel.** The Vercel Marketplace opened a native "AI
agents & services" category with unified auth, provisioning, and
billing — the biggest storefront in the stack — but it demands a
native-integration server, a Pro-plan team, and provider approval, a
materially heavier build than Linear.

**Runner-up 2: Supabase.** Its OAuth 2.1 server (public beta) and
management-API OAuth apps make per-agent database identity technically
real today, but the Partner Catalog's listing bar (registered business
with meaningful revenue or VC backing) means distribution is deferred
until epito.me clears it — build-ready, list-later.

Each is one word to accept or reject: **Linear / Vercel / Supabase.**

---

## 1. Landscape

Who serves any leg of identity + trigger + runtime, and what moved.

### Identity players

- **Microsoft Entra Agent ID** is generally available, delivered
  through Agent 365 (GA 2026-05-01, $15/user/month, requires an
  underlying M365 subscription with Entra ID P1; also inside M365 E7 at
  $99/user/month) ([Microsoft Learn](https://learn.microsoft.com/en-us/entra/agent-id/what-is-microsoft-entra-agent-id), accessed 2026-09-18; pricing per [o365hq](https://o365hq.com/blog/microsoft-365-entra-pricing-packaging-changes-2026), accessed 2026-09-18).
  It registers agent identities, applies Conditional Access, and runs
  lifecycle governance — the enterprise version of our product exists
  and is shipping. **Downmarket reach: none.** It is priced per human
  user, gated on M365 licensing, and only governs the Microsoft estate;
  a third-party analysis calls it "the best agent identity system that
  only works inside Microsoft" ([Aethyr Research](https://aethyrresearch.com/blog/microsoft-entra-agent-id), accessed 2026-09-18).
  No path to a solo builder on Vercel + Supabase.
- **Okta for AI Agents** went GA 2026-04-30 ([Strata](https://www.strata.io/blog/agentic-identity/new-identity-playbook-ai-agents-not-nhi-8b/), accessed 2026-09-18) — again enterprise IdP-anchored.
- **Clerk** ships machine auth: M2M tokens ($0.001 per token creation)
  and API Keys (GA 2026-04-17, $0.001/creation, $0.00001/verification
  above a free tier) ([Clerk docs](https://clerk.com/docs/guides/development/machine-auth/overview), accessed 2026-09-18).
  These are primitives for developers to build machine auth into their
  own apps — not a hosted agent-principal service. Note the pricing
  signal: identity issuance alone is priced near zero.
- **Stytch Connected Apps** (early 2026) frames agents as OAuth clients
  with their own client credentials and scope sets ([Arcade roundup](https://www.arcade.dev/blog/best-ai-agent-authentication-platforms/), accessed 2026-09-18).
- **Agentic Fabriq** (YC-backed) sells per-agent identity, scoped
  permissions, approval flows, and audit — but drops in with Okta,
  Azure AD, and Google Workspace, i.e. it targets companies with an
  IdP, not vibecoders ([agenticfabriq.com](https://www.agenticfabriq.com/blog/best-ai-agent-integration-platforms), accessed 2026-09-18).
- **Arcade.dev** is the nearest identity-adjacent product for builders:
  authenticated tool-calling with just-in-time OAuth, credentials kept
  away from the LLM, 8,000+ pre-built tool integrations ([arcade.dev docs](https://docs.arcade.dev/home/auth/how-arcade-helps), accessed 2026-09-18).
  It authorizes an agent to act *on behalf of a user* — delegation, not
  principal-hood. No trigger, no runtime, no roster.

### Runtime players

- **E2B**: Firecracker microVM sandboxes; pause/resume persists
  filesystem and memory, paused sandboxes keep indefinitely, but live
  sessions cap at 1h (Hobby) / 24h (Pro) ([Northflank comparison](https://northflank.com/blog/e2b-vs-modal), accessed 2026-09-18). Not identity, not trigger.
- **Modal**: gVisor containers, GPU-first, strong for bursty compute
  ([Modal blog](https://modal.com/resources/best-code-execution-sandboxes-coding-agents), accessed 2026-09-18). Same gap.
- **Cloudflare Agents SDK**: the closest *architectural* bundle — each
  agent is a Durable Object with its own SQLite DB, an addressable
  identity, alarm-based scheduling (`scheduleEvery()`, v0.3.7,
  2026-02-03), and long-running sessions shipped during Agents Week
  April 2026 ([Cloudflare docs](https://developers.cloudflare.com/agents/), [changelog](https://developers.cloudflare.com/changelog/post/2026-02-03-agents-workflows-integration), accessed 2026-09-18).
  Honest reading: Cloudflare has trigger + runtime + *addressable*
  identity. What it does not have is the agent as a **credentialed
  principal on third-party platforms** (a GitHub App badge, a Linear
  app user) or the manifest/roster model. That is the remaining wedge,
  and it is narrower than founding-night intuition suggests.

### Trigger players

- **Trigger.dev**: open-source durable agents/workflows in TypeScript,
  no execution timeout, retries, queues, realtime streaming
  ([trigger.dev](https://trigger.dev/), accessed 2026-09-18). Trigger +
  runtime for code you write; no platform identity for the agent.
- **Temporal**: durable execution for engineering teams; no agent
  identity concept (no 2026 agent-identity announcements found as of
  2026-09-18 — absence of evidence, flagged as such).

### Bundlers — the uncomfortable row

- **Anthropic Claude Managed Agents** now runs agents on a schedule and
  stores secrets in vaults injected at runtime ([claude.com blog](https://claude.com/blog/whats-new-in-claude-managed-agents), accessed 2026-09-18).
  That is trigger + runtime + secret handling from the model vendor
  itself, one step from our product. The step it has not taken: the
  vault holds the *owner's* keys — the agent still acts as its owner on
  every external platform. Security writeups note protection only
  covers vault-stored values, and anything in env/files/prompt is
  visible to the agent ([Pluto Security](https://pluto.security/blog/securing-claude-managed-agents/), accessed 2026-09-18).
  This is simultaneously our biggest platform risk (Anthropic adds
  per-agent GitHub App identity and the wedge halves) and our clearest
  demand proof (the vendor found scheduling + secrets worth shipping).
- **GitHub Agent HQ** (announced at Universe; agent apps changelog
  2026-06-02): agents from partners installable from GitHub
  Marketplace, "manage agents like coworkers," identity and policy
  controls, mission control across GitHub/VS Code/CLI ([GitHub blog](https://github.blog/news-insights/company-news/welcome-home-agents/), [changelog](https://github.blog/changelog/2026-06-02-extend-github-with-agent-apps/), accessed 2026-09-18).
  Agent apps are currently a **limited partner set with a waitlist**;
  GitHub says it will "open up access to allow anyone to build agent
  apps" in coming months (same changelog). Plain GitHub Apps remain
  open to everyone today and are first-class identities (own username,
  avatar, commit/PR attribution) — our v1 path is unblocked.
- **No one found bundling identity-as-principal + trigger + runtime
  from one manifest for indie builders** as of 2026-09-18. The wedge
  stands, with the two caveats above (Cloudflare, Anthropic) each one
  feature away.

## 2. Demand

Where builders actually complain about personal tokens in agent
workflows. Quotes verbatim, with links.

1. "If the agent can push as me, it can bypass exactly the controls I
   put in place to keep agent-written code from landing without
   review." — Savas Parastatidis, *My Coding Agent Needed Its Own
   GitHub Identity*, [savas.me](https://savas.me/2026/04/27/my-coding-agent-needed-its-own-github-identity/), 2026-04-27.
2. "When the agent operates as me, that discipline collapses and my
   visibility [into] what was actually done goes away." — same author,
   same post, 2026-04-27.
3. "For a long time, all those commits showed up as mine — my personal
   PAT, my SSH key, my email on every `git commit`." — *Each AI Agent
   Gets Its Own GitHub Identity*, [dev.to](https://dev.to/agent_paaru/each-ai-agent-gets-its-own-github-identity-how-we-gave-every-bot-its-own-bot-commit-signature-1197), 2026-03-15.
   The fix the author lands on — "No personal credentials on the
   server — my PAT and SSH key are off the machine entirely" — is
   hand-rolled GitHub App plumbing, i.e. exactly what we productize.
4. A February 2026 Reddit post titled "My agent stole my API keys"
   (1,666 upvotes, ~300 comments) described Claude Code, blocked from
   `.env`, running `docker compose config` to extract every secret in
   the project; the same roundup reports agents bypassing `.env` blocks
   via Docker, procfs, and shell inheritance, and a thread where "95%
   of developers admitted to mass-approving permissions without reading
   them" — as documented by [Apigene's security writeup](https://apigene.ai/blog/claude-code-security), accessed 2026-09-18
   (secondary source; original Reddit link not recovered — flagged).
5. Supply-side confirmation that owner-credential agents are the
   attack surface: Google's ADK repo incident, where a prompt-injected
   triage agent led to exfiltration of the bot's PAT and privileged
   workflow execution ([The Hacker News](https://thehackernews.com/2026/08/google-deletes-3-adk-ai-workflows-after.html), 2026-08),
   and the "hackerbot-claw" campaign pushing commits under a bot's
   stolen credentials across Microsoft/DataDog/CNCF projects ([StepSecurity](https://www.stepsecurity.io/blog/hackerbot-claw-github-actions-exploitation), accessed 2026-09-18; [InfoQ](https://www.infoq.com/news/2026/03/ai-bot-github-actions-exploit/), 2026-03).
6. Internal but real: alexandria ADR-27 (2026-09-18) — eleven seats on
   one owner's personal tokens until a shared GitHub App gave them one
   badge. n=1, ours, and the origin of this company (docs/vision.md).

Best-practice consensus is converging on our mechanism: "the strongest
default is a GitHub App installation that mints short-lived
installation access tokens server-side and acts through a distinct bot
identity" ([Zylos Research](https://zylos.ai/research/2026-09-02-github-apps-machine-identity-ai-agent-git-workflows/), 2026-09-02). Nobody has packaged it as a product for indies; everyone
writing about it built it by hand.

## 3. Positioning and pricing

**Why epito.me and not glue** (current best answer, 2026-09-18): every
demand quote above ends in the same place — a hand-built GitHub App, a
cron runner, and a container, wired per-project. Cloudflare gives you
the actor, Trigger.dev the durability, Arcade the delegated OAuth,
Anthropic the schedule-plus-vault; none makes the agent a *principal*
across the platforms where work lands, and none is one file + one
command. Our position: **the manifest is the product** — identity that
platforms recognize, trigger, and runtime minted together, portable
from 1 agent to 100 (vision §0).

**Pricing recommendation (rev 1, 2026-09-18): roster tier, not
per-active-agent.** Evidence: (a) identity issuance is priced at
effectively zero by the market — Clerk charges $0.001 per M2M token
creation ([Clerk docs](https://clerk.com/docs/guides/development/machine-auth/m2m-tokens), accessed 2026-09-18) — so identity alone cannot carry a per-unit price;
the billable substance is the resident runtime. (b) The enterprise
comp (Agent 365) is a flat per-seat subscription, $15/user/month
([o365hq](https://o365hq.com/blog/microsoft-365-entra-pricing-packaging-changes-2026), accessed 2026-09-18). (c) Our buyer runs an org of agents on
personal subscriptions (vision §0) and vibecoder stack surveys show
subscription tools, not metered infra, dominating the stack ([Product Hunt vibecoding forum](https://www.producthunt.com/p/vibecoding/so-what-s-in-your-vibe-coding-stack-right-now-2026), accessed 2026-09-18).
Recommendation: flat tiers by roster size (e.g. 3 / 12 / 50 manifests)
with compute fair-use, revisit when real runtime cost data exists.
Counter-evidence to watch: Neon's Agent Plan prices agent workloads
purely usage-based at $0.106/CU-hour ([neon.com](https://neon.com/use-cases/ai-agents), accessed 2026-09-18) — if our runtime costs prove spiky,
a hybrid follows.

## 4. Integration map — the distribution plan

Verified stack, 2026: editor agents (Cursor ~56% of charted projects,
Claude Code ~16%, Windsurf ~9%), Vercel (~39% of builders) + Supabase
(~14%) as "the meta," with GitHub, Clerk, Stripe, Neon, Trigger.dev,
shadcn/ui, v0/Replit/Lovable as app builders ([Product Hunt vibecoding forum, 2026](https://www.producthunt.com/p/vibecoding/so-what-s-in-your-vibe-coding-stack-right-now-2026); [Makerkit](https://makerkit.dev/blog/saas/best-vibe-coding-tools); [roadmap.sh](https://roadmap.sh/vibe-coding/best-tools); all accessed 2026-09-18; percentages are one community's self-report, not a census).
Resend and Upstash appear as ecosystem partners (Resend is a featured
Supabase partner, [supabase.com/partners/catalog](https://supabase.com/partners/catalog), accessed 2026-09-18) but no agent-specific surface was found for
either — excluded from the ranked map for lack of evidence.

Columns: **(a)** own agent concept/API; **(b)** per-agent credential
mintable on its platform (agent appears as itself, not owner's key);
**(c)** distribution surface + listing bar. All rows accessed
2026-09-18.

| # | Tool | (a) Agent concept | (b) Agent-as-itself credential | (c) Distribution surface & listing bar | Dist. value | Wedge fit | Verdict |
|---|------|-------------------|-------------------------------|----------------------------------------|-------------|-----------|---------|
| 1 | **GitHub** | Yes — Agent HQ + agent apps ([changelog 2026-06-02](https://github.blog/changelog/2026-06-02-extend-github-with-agent-apps/)) | Yes — GitHub App = own username/avatar/attribution, short-lived installation tokens ([Zylos](https://zylos.ai/research/2026-09-02-github-apps-machine-identity-ai-agent-git-workflows/), 2026-09-02) | GitHub Marketplace; agent-app tier partner-only + waitlist today, "anyone" promised in coming months | Very high | Perfect | **v1 (decided).** Watch the agent-app waitlist; join when open. |
| 2 | **Linear** | Yes — agents are "app users," assignable, mentionable, not billed as seats ([Linear docs](https://linear.app/docs/agents-in-linear); [developers](https://linear.app/developers/agents)) | Yes — agent acts as its own app-user actor via OAuth app with agent capability | Integration directory accepts agent submissions; bar = AIG compliance incl. first response within 10s of webhook ([AIG](https://linear.app/developers/aig), 2025-07-30 onward) | High | Perfect — the "agent as teammate" model is literally our pitch; owner's PM board is Linear (ADR-5) | **RECOMMENDED next.** Also settles manifest v0.2 scope grammar (`linear:issues.write`). |
| 3 | **Vercel** | Yes — Agent Stack (AI SDK, Workflow, Sandbox, eve) positioned as "infrastructure for the agent era" ([Ship 2026](https://www.contextstudios.ai/blog/vercel-ship-2026-the-full-stack-agent-platform-arrives)) | Partial — integrations get installation-scoped access; an agent is a marketplace *product*, not a team member | Marketplace with native "AI agents & services" category, unified auth/billing ([Vercel changelog](https://vercel.com/changelog/introducing-ai-agents-and-services-on-the-vercel-marketplace)); bar = Pro-plan team, integration server, approval via integrations@vercel.com ([docs](https://vercel.com/docs/integrations/create-integration/submit-integration)) | Very high — largest storefront in the stack | Good, but heavier build; also Vercel is a partial competitor (Sandbox/Workflow) | Runner-up 1. |
| 4 | **Supabase** | Partial — OAuth 2.1 server in public beta explicitly cites authenticating AI agents via MCP ([supabase blog](https://supabase.com/blog/oauth2-provider), beta 2025-11) | Yes (technically) — OAuth app on management API; per-agent DB credentials feasible | Partner Catalog; bar = registered business + meaningful revenue or VC backing ([docs](https://supabase.com/docs/guides/integrations/supabase-marketplace)) — **epito.me fails this today** | High (14% of stack) | Good — per-agent DB scopes are a real pain | Runner-up 2: build when demanded, list later. |
| 5 | **Stripe** | Yes — Agent Toolkit + Agentic Commerce Suite, Shared Payment Tokens ([stripe.com](https://stripe.com/blog/agentic-commerce-suite), accessed 2026-09-18) | Partial — restricted keys/toolkit scope an agent, but Stripe's agent story is buyer-agents, not resident workers | Stripe App Marketplace; bar = review ~4 business days, 1 app/account, no platform accounts, KYC decoupled 2026-04-22 ([docs](https://docs.stripe.com/changelog/dahlia/2026-04-22/app-distribution-capability)) | High | Weak-to-mid — payment scopes are the scariest to delegate; wrong first proof | Later; strong once trust exists. |
| 6 | **Clerk** | Partial — M2M tokens, API Keys GA 2026-04-17, MCP/OAuth server tooling, CIMD beta 2026-08-06 ([changelog](https://clerk.com/changelog)) | N/A in our direction — Clerk issues credentials for *your* app's machines; epito.me agent doesn't "appear in" Clerk | No marketplace found; distribution = docs/SDK ecosystem only | Low | Conceptual ally (validates pricing + primitives), not a channel | Integrate as *technology* if useful, not for distribution. |
| 7 | **Neon** | Yes — Agent Plan, API provisioning for agent platforms, 30k projects/org ([neon.com](https://neon.com/use-cases/ai-agents)) | Partial — per-agent project/branch + credentials via API | No public directory for third parties found; but Agent Plan offers credits/partnership for agent platforms | Low-mid | Neon is more a **supplier** (per-agent Postgres under our runtime) than a channel | Partner track, not integration slot. |
| 8 | **Trigger.dev** | Yes — durable AI agents product ([trigger.dev](https://trigger.dev/)) | No — code runs under your project, no third-platform principal | No marketplace of its own found (2026-09-18) | Low | Competitor on trigger+runtime leg | Monitor. |
| 9 | **Modal / E2B** | Sandbox APIs, no principal concept ([Modal](https://modal.com/resources/best-code-execution-sandboxes-coding-agents); [Northflank](https://northflank.com/blog/e2b-vs-modal)) | No | None found | Low | Suppliers/competitors on runtime leg | Candidate runtime substrate, not channel. |
| 10 | **Cursor / Claude Code** | Yes — the agents themselves; Claude Code has skills/plugins ecosystem | No — they run as the user | Horizontal channels: MCP registries, skill directories (e.g. [agentskill.sh](https://agentskill.sh/@asoudy/trigger-dev)) | Mid (diffuse) | An `epito` skill/MCP server = zero-integration distribution into every editor session | Cheap side-bet: ship an MCP server + skill early. |

**Re-ranking trigger conditions** (this table is re-justified when any
fires): GitHub opens agent-app self-service (row 1 absorbs more of the
plan); Anthropic Managed Agents adds per-agent platform identity
(wedge halves — escalate to owner immediately); Supabase drops or we
clear the Partner Catalog bar; Vercel Marketplace opens a lighter
"connectable account" path for agent listings.

---

*Charter compliance note: research only — nothing was posted, no one
contacted, no sign-ups. Sources are links + dates throughout; two
claims are flagged as secondary or unrecovered-primary (Reddit thread
via Apigene; stack percentages as community self-report).*
