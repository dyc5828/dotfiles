# SUPESC Dispatch Skill — Eval Scorecard

**Date:** 2026-04-08
**Iteration:** 1
**Skill version:** Initial draft
**Model:** Claude Opus 4.6

## Results

| Ticket | Description | Expected | With Skill | Baseline | Skill | Baseline |
|--------|-------------|----------|------------|----------|-------|----------|
| T01 | Plan config — missing features on agent-teams plan | VSB | VSB | VSB | Pass | Pass |
| T02 | Co-sponsor search — preferred partner tag blocking | CX | CX | CX | Pass | Pass |
| T03 | Welcome email question — answerable from codebase | Answer + close | Answer + close | User Messaging | Pass | **Fail** |
| T04 | Enterprise bulk migration — 5K client reassignment | Enterprise | Enterprise | Enterprise | Pass | Pass |
| T05 | Home values off — Austin TX zip code | Data | Data | Data | Pass | Pass |
| T06 | Digest delivery failure — widespread send outage | User Messaging | User Messaging | Infrastructure | Pass | **Fail** |
| T07 | Wrong listing photos — data pipeline issue | Data | Data | Data | Pass | Pass |
| T08 | Garbled email content — CEP editor encoding | CX | CX | CX | Pass | Pass |
| T09 | Feature request — AI market summary | Close | Close | Intelligence | Pass | **Fail** |
| T10 | Stale loan rates — FHA rates 2 months old | Data | Data | Data | Pass | Pass |
| T11 | Recurly dual subs — HBN upgrade flow | CX | CX | VSB | Pass | **Fail** |
| T12 | Partner intel stale — NMLS brokerage data | Data | Data | Data | Pass | Pass |
| T13 | Site outage — 503 errors across all pages | Infrastructure | Infrastructure | Infrastructure | Pass | Pass |
| T14 | CEP wrong client count — cache invalidation | CX | CX | Client Experience | Pass | **Fail** |
| T15 | Mobile app crash — Android v4.2.1 | CLE | CLE | CLE | Pass | Pass |

## Summary

- **With skill:** 15/15 (100%)
- **Baseline (no skill):** 10/15 (67%)
- **Skill advantage:** +5 tickets correctly routed

## Where the skill made the difference

### T03 — Welcome email question
Baseline found the code answer but still routed to User Messaging instead of closing. Skill correctly identified it as "answerable from codebase" (Category A) and closed the ticket with findings.

### T06 — Digest delivery failure
Baseline confused widespread email delivery failure with site infrastructure and routed to Infrastructure. Skill correctly distinguished send infrastructure (User Messaging) from site availability (Infrastructure).

### T09 — Feature request
Baseline tried to route a feature request to Intelligence (because it mentioned AI). Skill correctly recognized it as a feature request and closed it with a note to use product feedback channels.

### T11 — Recurly dual subscriptions after HBN upgrade
Baseline focused on the Recurly/billing angle and routed to VSB. Skill recognized the HBN-to-paid upgrade flow as Customer Experience territory, while flagging the billing angle in the comment.

### T14 — CEP showing wrong client count
Baseline routed to Client Experience (consumer/client team) instead of Customer Experience (CEP/customer team). Skill correctly identified the CEP dashboard as CX-owned.

## Notable observations

- **T07 expected answer updated:** Originally expected Client Experience, but both with-skill and baseline agents independently traced the full data pipeline and proved the `thumbnail_image` mismatch originates in upstream data ingestion, not the application layer. Updated expected to Data.
- **Codebase depth:** Both with-skill and baseline agents frequently investigated the codebase to support their routing decisions. The with-skill agents tended to be more focused in their investigation, guided by the routing rules.
- **Comment quality:** With-skill agents consistently produced plain-language routing comments suitable for a non-technical audience, while baseline agents tended toward more technical explanations.
- **Edge cases are where the skill shines:** All 5 baseline failures were on non-obvious routing decisions — the straightforward tickets (T01, T04, T05, T12, T13, T15) were handled correctly by both.
