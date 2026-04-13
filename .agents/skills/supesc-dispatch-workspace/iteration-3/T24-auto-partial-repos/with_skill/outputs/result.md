# SUPESC-T24 Triage Result (Auto Mode, Partial Repos)

## Ticket

**Title:** CEP dashboard showing duplicate clients after bulk import
**Reporter:** @penguin.am
**Mode:** auto
**Environment:** /Users/dan.chen@homebot.ai/code/homebot/ exists but customer-admin is not cloned (simulated)

## Action: Route to Customer Experience

**Category:** B - Routable to a team

## Routing Comment Posted to Linear

_Automatic triage by Claude Code_

**Routing: Customer Experience**

REA Umi Victor's CEP dashboard is showing duplicate client entries after a bulk import, with a mismatch between the header count (450) and the visible unique clients (320). The client list and dashboard display are CEP features owned by Customer Experience.

On the backend side, the bulk import path in Mikasa deduplicates clients by email + customer profile, so duplicates could appear if records came in with slight email variations or through a different import channel. CX will need to check whether the duplicates are genuine data-layer duplicates or a display/count issue in the dashboard. The HB Admin link for this customer is included in the ticket.

## Auto-Mode Behavior Check

| Criterion | Pass/Fail |
|---|---|
| Routed without pausing or prompting | Pass |
| No commentary naming the missing repo | Pass |
| No freshness nudge or clone suggestion | Pass |
| Routing comment prefixed with `_Automatic triage by Claude Code_` | Pass |
| Routing comment is actionable for CX | Pass |

## Notes

The skill's partial-repo silent-degradation behavior worked as specified. With `customer-admin` unavailable, the skill could not trace the dashboard's client listing query or count logic to determine whether this is a display bug vs. actual duplicate records. Instead of mentioning that gap in the routing comment (which would be noise in auto mode), the skill:

1. Used the available mikasa repo to investigate the backend bulk import dedup logic (`BulkClientImports::Concerns::ClientProcessing#find_client_by_email`), which deduplicates by email + customer_profile_id. This provided useful context for the routing comment without requiring the frontend repo.
2. Framed the routing comment around what CX needs to investigate (display vs. data-layer duplicates) without exposing which repos were or were not available.
3. Produced zero meta-commentary about repo availability, zero freshness nudges, and zero clone suggestions - all of which would violate the auto-mode contract.

The routing guide match is straightforward: "CEP features: client dashboard" maps directly to Customer Experience. Even without codebase investigation, this ticket would route the same way. The mikasa investigation added value by giving CX a head start on the backend dedup mechanics, but the routing decision itself did not depend on it.
