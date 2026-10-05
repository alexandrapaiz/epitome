# Published artifacts — index

Every deck this company has published, what it is, and where its source
of truth lives. The rule (HQ standards/documents.md §2b): a deck renders
from a document the owning seat authored. Where a deck and its document
disagree, the document wins.

| Artifact | What it is | Status | Source of truth in this repo |
|---|---|---|---|
| [Market Brief Rev 2](https://claude.ai/artifact/GLjp562JRrDrgsHZdRADh8) | The gap, the integration universe, the gaps, four owner decisions | **Approved** (owner, 2026-09-19: "much better presentation good job") | `docs/market.md` (brief) + `docs/presentations/market-rev2/deck-content.md` (market seat's Copy/Notes/Visual direction) + slide HTML beside it |
| [epito System Architecture](https://claude.ai/artifact/GTDQJ6QJfp9ZPz4aJ3hcwD) | 15-slide engineering plan (seams, data model, flows, toolchain, threat model, connective stack) | **Abandoned** by the owner after five revisions (epitome Incident 1). Do not revive; rebuild from the exemplar if ever needed | `docs/architecture.md` |
| [Cycle 1 Briefing](https://claude.ai/artifact/W1PXs8WB68AtpzfUGN5VPB) | PM's orders to all seats for cycle 1 | **Superseded** by two owner re-bets (amendments 1 and 2) | `docs/briefings/2026-09-18-cycle-1-briefing.md`, `docs/cycles/` |

Slide HTML for the abandoned and superseded decks was scratch-only and
is gone; their content lives in the documents above, which is the point
of the rule. Only the approved deck keeps its rendered sources in-repo.

## Rebuilding or revising a deck

1. The owning seat writes or updates the content document (Copy verbatim,
   Speaker notes with sources, Visual direction).
2. The chair renders Copy into slide files under
   `docs/presentations/<deck>/` and publishes to the artifact URL above.
3. Never edit a published deck without the document changing first.
