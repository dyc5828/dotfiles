## Triage Result

**Ticket:** SUPESC-T06 - Digest emails not being delivered for any customers since this morning
**Routed to:** Infrastructure
**Severity:** High - system-wide outage

## Triage Comment

Routing to **Infrastructure**. This is a system-wide email delivery outage - 15+ reports across different customers and plans in 2 hours, with both scheduled and manual sends failing. The breadth of the failure (all customers, all plans, all send types) points to a break in the email delivery pipeline or third-party email service integration rather than a logic or configuration issue. Needs immediate investigation into the sending infrastructure, job queue health, and ESP connectivity.
