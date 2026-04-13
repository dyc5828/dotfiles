# SUPESC Dispatch Skill — Eval Scorecard

**Date:** 2026-04-13
**Iteration:** 3
**Skill version:** Adds Prerequisites section (Linear MCP required in all modes, local repos optional with silent degradation, clone/freshness nudges in non-auto only), Partner Intel routing shortcut (to Customer Experience with Chris Johnson as product escalation), and a Category-A fallback when repos are unavailable
**Model:** Claude Opus 4.6
**Scope:** 4 new tickets (T19–T22) plus 1 regression (T12) plus 2 auto-mode tests (T23–T24). Previous 15+3 tickets from iterations 1 and 2 not re-run.

## Results — New Coverage (T19–T22) + Regression (T12)

| Ticket | Description | Expected | Iter-3 With Skill | Iter-2 With Skill |
|--------|-------------|----------|-------------------|-------------------|
| T12 | Partner Intel stale brokerage — NMLS data | Data | **Data** ✅ | Data |
| T19 | Partner Intel LO volume looks off | Customer Experience | **Customer Experience** ✅ | — (new) |
| T20 | Follow-up on stalled CEP escalation | Customer Experience | **Customer Experience** ✅ | — (new) |
| T21 | Prospect home search email subject shows "Y" | Client Experience | **Client Experience** ✅ | — (new) |
| T22 | Multiple CEP maintenance list bugs | Customer Experience | **Customer Experience** ✅ | — (new) |

**Iter-3 with skill: 5/5**
**Regression check on T12: PASS**

## Auto-Mode Behavior Tests (T23–T24)

Purpose: verify the new Prerequisites section does not hang, prompt, or nudge in auto mode, and that repo detection degrades silently.

| Ticket | Scenario | Routed Correctly? | Auto-Mode Criteria | Overall |
|--------|----------|-------------------|-------------------|---------|
| T23 | Auto mode, `/Users/dan.chen@homebot.ai/code/homebot/` entirely missing | ✅ CX (via Partner Intel shortcut) | 5/5 passed | **PASS** |
| T24 | Auto mode, `customer-admin` missing but other repos available | ✅ CX (CEP dashboard ownership) | 5/5 passed | **PASS** |

**Auto-mode criteria scored per ticket:**
1. Routed without pausing or prompting
2. No commentary about missing repos in user-facing output
3. No freshness nudge or clone suggestion
4. Comment prefixed with `_Automatic triage by Claude Code_`
5. Routing comment is actionable for the receiving team

### Observations from auto-mode tests

**Silent degradation is working.** Neither T23 (no repos) nor T24 (partial repos) surfaced any meta-text about what was missing. The skill's "In auto mode, never nudge" directive held up under both scenarios.

**Partial repos remain useful.** T24 used `mikasa` (available) to identify the backend dedup logic for bulk client imports even though `customer-admin` was off-limits for the frontend investigation. The routing comment gave CX backend context about where to look on the data side without ever naming which repo was unavailable. This is exactly the "work with what's present" behavior the skill now codifies.

**Chris Johnson escalation is investigation-dependent, not routing-dependent.** T23 routed to CX without reading any code (repos missing), so the "tag Chris Johnson if investigation touches product criteria" trigger never fired. The T23 eval agent flagged this correctly as intended behavior: the tag applies when an investigation shifts toward criteria questions, not when we simply route a Partner Intel ticket. CX can escalate to Chris themselves once they start digging.

**No evidence of auto-mode getting hung up.** Zero prompts, zero approval requests, zero meta-commentary across both tests. This was the key risk when we added the Prerequisites section, and the explicit "None of this should impede auto mode" framing is holding.

## Key Observations — What's Working

### Partner Intel shortcut fires on the right cases only

The new **Partner Intel data accuracy** known shortcut routes ambiguous accuracy questions to Customer Experience (not Intelligence or Data). T19 — the real Payton Papa volume case — landed on CX correctly, and the agent surfaced the Chris Johnson product-escalation path for criteria questions.

Critically, T12 (stale NMLS data with root cause already diagnosed by the reporter) correctly **did not** fire the shortcut and stayed with Data. The agent explicitly noted the distinction: the shortcut is for ambiguous accuracy questions; T12's root cause is already pinned to upstream public record ingestion, so CX indirection would add nothing. **No regression.**

### Follow-up pattern recognized

T20 simulated a support follow-up on a previously-dispatched ticket. The agent recognized the follow-up nature, referenced the linked original (CUX-100), and routed back to the team that already holds it (CX) instead of re-triaging from scratch. The routing comment reused the prior investigation context and framed the ask as "needs movement" rather than "new look." This matches how the INT-285 → CUX-232 re-route went in real life this session.

### Email content vs delivery distinction held up

T21 ("Email Deliverability" label, subject shows "Y") is designed to bait routing to User Messaging. The agent traced the subject-generation code through `home_search_report`, `prospect_single_listing`, `saved_search`, and `base.rb`, confirmed all i18n paths produce proper strings, and correctly routed to **Client Experience** (prospect-facing email content). The routing comment narrowed the bug to SendGrid template layer / production data, giving CLE a running start.

### Multi-issue tickets enumerate fully

T22 bundles three CEP bugs. The agent didn't short-circuit — it enumerated all three in the routing comment with file-level root-cause hints (`email_issue_types[0]` only rendering the first tag, count using unfiltered total, Highly Engaged list fetch). This matches how the real CUX-230 landed with a useful routing comment that Taylor Berry immediately engaged with.

## Key Observations — Skill Behavior

### Prerequisites section is invisible when not needed

All five evals ran without any mention of prerequisites, repo checks, or freshness nudges in the output. The guidance that "none of this should impede auto mode" is being respected — the skill degrades silently when it needs to and doesn't add noise when repos are present.

### Code investigation depth scales with ambiguity

- T22 (clearly CX): minimal code check, confident routing
- T20 (follow-up pattern): reused prior findings, didn't re-investigate
- T12 (root cause already diagnosed): no deep code dive, straight route
- T19 (needs to differentiate CX vs Data vs Intelligence): deep trace through customer-admin → mikasa → fact_loan → hb-airflow SQL
- T21 (needs to disprove "this is in the app"): deep trace through all three email subject paths

This is the desired behavior — investigate deeply only when investigation actually changes the routing.

### Chris Johnson escalation path surfaced appropriately

T19's routing comment explicitly called out: if investigation shifts from "is the data flowing through correctly" to "is the criteria for what counts as volume the right criteria" → tag Chris Johnson on the ticket. Matches the skill's updated Known Shortcut language.

## No Regressions

- T12 maintained Data routing. The new Partner Intel shortcut does not over-fire.
- No observed drift in comment format, comment placement (top-level vs Slack-synced reply), or auto-mode attribution across the 5 runs.

## What's Not Yet Covered in Evals

- **Freshness nudge behavior in non-auto mode.** Not testable via the synthetic-ticket harness since it's a one-per-session session-level behavior, not a per-ticket behavior. Could be added as a scripted interactive eval.
- **Multi-ticket queue runs.** The harness runs one ticket at a time. A future iteration could simulate a queue of mixed tickets to catch ordering/interaction issues (e.g., does the freshness nudge fire exactly once across a non-auto session of 5 tickets?).

## Summary

**7/7 pass on iteration-3.** 5/5 on new routing coverage, 1/1 on regression, 2/2 on auto-mode behavior. The skill's routing decisions match the patterns established by real dispatches in this session (CLE-427, CUX-230, CUX-232), the Partner Intel shortcut fires on ambiguous accuracy questions without regressing on already-diagnosed cases, and auto mode degrades silently through missing/partial repos without hanging or leaking meta-commentary.
