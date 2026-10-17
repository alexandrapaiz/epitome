# Market brief — docs/market.md

Maintained by the market seat. This revision: **rev 7, 2026-10-16**,
weekly window run. `gh pr list` was checked first (L-E10): rev 6
merged as PR #94 on 2026-10-09, no market PR is open now, so this
revision is written fresh on top of main rather than stacked on an
unmerged draft — the first clean week since rev 3.

This is a seven-day delta (2026-10-09 through 2026-10-16). The ADR-12
tripwire was checked directly against LangChain's changelog and blog,
as every run must; it did not newly fire, but it moved closer than any
prior check on the GitHub side specifically, and the finding below
says exactly how close. Two other things moved: the owner closed the
longest-open item in rev 6's queue table herself, today, inside a
cycle-level ruling rather than by answering the market seat's question
directly — reported as a resolution, not a re-ask; and a GitHub issue
from a real engineering org, opened one day before rev 6 shipped and
missed until this run, is the sharpest demand quote this brief has
carried.

## Orientation: the queue lost its oldest item, and GitHub moved one step closer

**The queue, resolved not re-asked.** Rev 6 reported three asks sitting
behind one gate (the owner's merge), the oldest seven days old. Today,
2026-10-16, the owner ruled on cycle 2 directly — relayed by the chair,
verbatim: "we need our product to work, we need an MVP" — closing
cycle 1 under the PM standard's new silence rule (`docs/standards/pm.md`
§22, vendored today) and replacing the cycle-2 bet with
`mvp-stranger-npm-v0` (publish to npm, one real deploy proof, a README
walk-through), declining `slack-identity-v0` and `passport-v0-github`
"on timing not worth, first in line for cycle 3" (PR #67, rewritten
2026-10-16). Read against this brief's own queue table: row 3 (the
cycle-2 bet) is resolved, and row 1 (ADR-12's "pull the passport
prototype forward, yes/no," open 14 days) is answered in substance —
not now, cycle 3 — though not in the form the tripwire asked, which was
a direct yes/no on the passport alone. **Row 2 is not touched by
today's ruling and stays open at 14 days**: ADR-13's usage-based
buyer-2 pricing question is a pricing-model ruling, not a
build-sequencing one, and nothing in today's MVP override answers it
either way. Reported per L-A27: the owner exercised the authority
herself rather than the queue draining through a lesson; the one row
that remains is named so it does not quietly inherit the resolved
appearance of the other two.

**ADR-12, checked directly (L-R1):** LangChain's blog (fetched
2026-10-16, `langchain.com/blog`) lists twelve posts since rev 6's
2026-10-09 check, and the LangSmith Cloud changelog's "October 5-12,
2026" entry ([docs.langchain.com/langsmith/changelog](https://docs.langchain.com/langsmith/changelog),
accessed 2026-10-16) carries the one item worth escalating attention to
without calling it a new fire: **"Agent Auth now mints GitHub App
installation tokens, so agents can call `connections.get` on a
`github_app` connection"** and receive "a working token... renewed
automatically before it expires." This is the first time Agent Auth's
token-minting has named GitHub specifically rather than generic OAuth.
It does not fire the tripwire on inspection of the surrounding docs:
the GitHub channel guide ([Add a GitHub channel to Managed Deep
Agents](https://docs.langchain.com/langsmith/managed-deep-agents-channels/github),
accessed 2026-10-16) lists as a prerequisite "a GitHub App you control,
... installed on the target org or repos" — the App itself is
customer-provisioned and shared across whatever calls it, the same
shape as LangSmith Engine's own GitHub integration ("connects through a
LangChain-managed GitHub App," one installation per organization,
per search this run) and the same shape rev4/rev5 already assessed as
not firing. What changed is that Agent Auth now handles that shared
App's token *lifecycle* automatically; it still does not mint a new,
distinct principal per agent. **The asymmetry worth naming:** Slack is
still the only outside platform where LangChain's own product
auto-provisions a new per-deployment principal with no customer App
required (rev6 §Orientation, reconfirmed, no new check needed this
run); GitHub requires the customer to bring an App first, every time,
which is a materially higher bar than Slack's zero-setup path. If
LangChain ever auto-provisions the GitHub App the way it auto-provisions
the Slack app, that is the tripwire; this run confirms it has not,
while also confirming GitHub is the platform to re-check first next
time, not Slack. Flagged: the exact scoping of an Agent Auth-minted
installation token (whether two agents calling the same `github_app`
connection can ever receive tokens for two different installations
rather than one) was not found in any primary doc this run; the
CLI reference and the per-caller-identity post both predate this
changelog entry and don't cover `github_app` connections at all.

**GitHub's agent-app waitlist, re-checked directly** against its own
changelog page: still reads "Over the coming months, we'll open up
access to allow anyone to build agent apps," unchanged, no date named
([GitHub changelog, 2026-06-02](https://github.blog/changelog/2026-06-02-extend-github-with-agent-apps/),
accessed 2026-10-16) — no re-ranking trigger.

## 1. Landscape delta — OpenClaw starts shipping credentials work; Entra tightens its own wall

**OpenClaw moves past "fix the foundation."** Rev 4 and rev 5 both
found OpenClaw holding at a stability-only release cadence; this run
is the first to find it shipping credential-shaped work again. The
latest line, `2026.10.10-beta.1` (dated 2026-10-15, per
[releasebot.io/updates/openclaw](https://releasebot.io/updates/openclaw),
accessed 2026-10-16), notes work to "protect provider and MCP
credentials from concurrent CLI writes," a "principal-bound relay
plugin" for connecting MCP apps, and a "principal-bound remote Control
UI for trusted plugins." None of this names GitHub, Slack, or any
outside-platform identity — it reads as OpenClaw hardening its own
internal credential and principal model, not opening a cross-platform
one — but it is the first forward motion on this axis since rev 4's
search found the 2.0 stability phase, and the next run should check
whether "principal-bound" extends outward.

**Entra Agent ID tightens, inward, not outward.** Microsoft is ending
the automatic grant of `AgentIdentity.CreateAsManager` to agent
blueprint principals — admins can grant it manually starting
2026-10-16 (today) and the automatic grant ends worldwide in November
([Microsoft Entra Message Center MC1506728, mirrored at
mc.merill.net](https://mc.merill.net/message/MC1506728), accessed
2026-10-16). Read against vision §1: this is Microsoft adding more
governance around who may create an agent identity *inside its own
tenant*, the walled-resident pattern the gap names, not a step toward
an identity that leaves the wall. Secondary coverage claims Conditional
Access now treats Agent ID as a first-class principal type; not
confirmed against a Microsoft primary source this run, flagged.

**Re-checked, no change:** the GitHub-App-per-agent tool count rev 6
found (ChatBotKit, Vellum, the Hermes community plugin, the Skillselion
Claude Code skill) was not re-searched this run — the search budget
went to the ADR-12 and demand items above and below — so that count
stands at rev 6's number, not re-verified higher or lower.

## 2. Demand — the sharpest quote this brief has carried, from a real engineering org

A GitHub issue opened 2026-10-08 (one day before rev 6 shipped, missed
until this run) on NAV's (Norway's national digital-services agency)
internal Copilot tooling repo states the proxy problem this brief has
argued from vision all along, now in a real backlog with a
`needs-decision` label:

> "Every agent we run acts on GitHub as the human who started it.
> Claude Code subagents, Copilot CLI and OpenCode launched through
> nav-pilot, the scheduled canary and local scripts all use the
> owner's personal `gh` login. Their PR comments, review replies,
> thread resolutions, merge-queue enqueues and new issues all appear
> under the human's account. A reviewer can't tell agent actions from
> human ones, and the token the agent holds can do everything the
> human can."

— and names the business reasons in the issue's own words: "Nav must
be able to say who did what," "a misbehaving agent can't be cut off
without revoking the human's login," "an agent that can comment,
resolve threads and enqueue with the same identity as the approving
human weakens the review requirement," and "agent traffic draws on the
human's 5,000/h REST budget... agent and human usage can't be
separated in metrics" ([navikt/copilot#1508](https://github.com/navikt/copilot/issues/1508),
accessed 2026-10-16). This is vision §1's "proxy" branch — "goes
everywhere as its human, is nobody" — written independently by an
engineering org with no knowledge of this product, with audit,
revocation, review-integrity, and billing-separation all named as
reasons in one issue rather than inferred across several, which is
sharper than any single prior quote this brief has carried. The issue
links a sibling (`navikt/cplt#731`) already building the DIY partial
fix — a scoped fine-grained PAT per repo, opt-in author names, a local
identity log — which is the same commoditization dynamic rev 6's
landscape section already named: the narrow mechanism is cheap to
build piecemeal, which is exactly why what we sell has to be the
roster and the audit trail, not the App-per-agent trick alone.

**Reinforcing, weaker signal:** a one-star repo's issue opened
2026-10-15 hits the mechanical half of the same problem from the
builder side — `GITHUB_TOKEN` can't trigger downstream workflow runs,
"breaks autonomous bot chaining," and the fix adopted is a GitHub App
token specifically because, in the issue's own words, PATs are
"tied to individual users and are less secure than GitHub App tokens,
which are scoped and short-lived" ([arii/boomtick#859](https://github.com/arii/boomtick/issues/859),
accessed 2026-10-16). The App token this issue reaches for is still
one shared App for the whole repo, not a per-agent identity — it
reinforces rev 5's finding (GitHub's own PAT fix is shared, not
per-agent) from the builder's side rather than the vendor's.

## 3. Positioning and pricing — one ask resolved in substance, one still fully open

The cycle-sequencing question is answered (orientation, above): the
passport prototype is not being pulled forward now, it is first in
line for cycle 3. That is a scheduling answer, not a pricing one.
ADR-13's usage-based, per-mint/per-verify pricing recommendation for
buyer 2 — and rev 1's flat roster tier for buyer 1 — both still await
the owner's word, now 14 and 28 days respectively, untouched by
anything found this run.

## 4. Integration map — no re-ranking trigger fired; a build-schedule note, not a rank change

GitHub's agent-app waitlist and LangChain's changelog/blog were the two
live trigger conditions checked this run (above); neither fired.
Standing recommendation unchanged: **Slack remains integration #2**.
One clarification worth stating plainly so it isn't read into the
ranking: today's cycle-2 ruling means no Slack-identity or
passport work lands before cycle 3 regardless of this ranking — the
mechanism audit (rev 4, rev 5) already found `cli/src/lib/slack.js`
unbuilt as an identity mint (still a webhook poster, re-confirmed
against main this run, no new engineer PRs touch `apps.manifest.create`
— unchanged since rev 5's audit), and that gap now has an explicit
cycle, not just an open rank, standing between it and being built.

---

*Charter compliance note (rev 7): research only; nothing posted, no
one contacted, no accounts created. Checked against
docs/standards/lessons.md before shipping: L-R1 (the live-world checks
above — LangChain's changelog, GitHub's changelog, OpenClaw's release
feed, Entra's Message Center, and the two GitHub issues, all fetched
directly), L-E10 (`gh pr list` checked first; rev 6 was merged, so this
revision starts clean on main rather than stacking), L-X7 (the queue
reported as resolved-in-substance for one row and still-open for
another, not re-asked as a flat three), L-A27 (the owner's own exercise
of authority today reported as that, not folded silently into "no
change"). Flagged: the exact scoping of Agent Auth's GitHub App
installation-token minting (landscape §Orientation) — whether it can
ever be per-agent rather than per-App — was not confirmed in any
primary doc and needs a direct re-check once LangChain documents the
`github_app` connection type on its own terms; the Conditional
Access/Agent-ID claim (§1) is secondary-sourced only; the GitHub-App-
per-agent tool count (§1) was carried from rev 6 without re-verification
this run, flagged as such rather than silently restated as current.*

---

# Market brief — docs/market.md (rev 6, superseded by rev 7 above)

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
