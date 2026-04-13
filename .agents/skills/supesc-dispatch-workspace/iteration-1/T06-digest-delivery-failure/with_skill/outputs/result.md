# SUPESC-T06 Triage Result

**Ticket:** SUPESC-T06 - Digest emails not being delivered for any customers since this morning
**Category:** B - Routable to a team
**Route to:** User Messaging
**Status:** Keep in Triage (for team lead to prioritize)
**Dry run:** Yes - no Linear API calls made

---

## Routing Comment (dry run - would be posted to ticket)

**Routing: User Messaging**

This is a widespread digest delivery failure affecting all customers across plans, with both scheduled and manual sends failing. That pattern points to send infrastructure rather than a content, configuration, or customer-specific issue. User Messaging owns send infrastructure and delivery pipeline, which is where the investigation should start.

---

## Reasoning

### Why User Messaging

The skill's routing guide maps "send infrastructure, delivery failures, notification channel issues" to **User Messaging**. This ticket hits all three signals:

1. **Delivery failure, not content issue.** The digests are not arriving at all. This is not a complaint about what the email says or looks like - it is a failure in the send pipeline itself.
2. **Widespread across customers and plans.** 15+ reports from different customers on different plans rules out per-customer config problems (which would be VSB) or per-plan feature issues.
3. **Manual sends also failing.** This eliminates scheduling/cadence as the root cause and points to the underlying send infrastructure being down or degraded.

### What I checked in the codebase

Mikasa contains the full digest delivery pipeline:

- `mikasa/app/jobs/digest_blast/` - Jobs that queue digest sends for due clients (home digests, buyer digests, heartbeats, unpaid clients, prospect heartbeats)
- `mikasa/app/interactors/digest_delivery/` - Interactors that process and execute the actual sends (validation, scheduling, sending, tracking)
- `mikasa/app/jobs/digest_job.rb` - Top-level digest job coordinator

The architecture flows from blast jobs (which determine who is due for a send) through delivery interactors (which execute the send). Since manual sends are also failing, the issue is likely downstream of the interactor layer - in the email delivery service or third-party provider integration, not in the scheduling/queuing logic.

### Teams ruled out

- **Client Experience** - They own the consumer app and client emails from a product perspective, but this is an infrastructure-level delivery failure, not a feature or content bug.
- **VSB** - Would apply if this were account config or setup issues for specific customers. The cross-customer, cross-plan scope rules this out.
- **Infrastructure** - Could be relevant if this were a site-wide outage, but the issue is scoped specifically to email delivery, which is User Messaging's domain.
- **Data** - No indication of data quality issues; emails are simply not delivering.

### Urgency note

This is time-sensitive. Digest emails are a core product touchpoint. Every hour of downtime means a full day's worth of customer communications are missed or delayed. The receiving team should treat this as high priority.
