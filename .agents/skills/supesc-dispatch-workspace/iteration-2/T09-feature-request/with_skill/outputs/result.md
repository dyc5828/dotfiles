# Triage Result: SUPESC-T09

**Ticket:** Request to add AI-powered market summary to home digest
**Action:** Close the ticket and inform the requester this is a feature request

## Determination: Feature Request (not a support escalation)

This ticket is a product feature request from an enterprise customer (Acme Realty Group), not a bug, configuration issue, or question about existing behavior. There is no AI-generated market summary feature in the home digest today. The codebase has some market data tooling in `quasar` (an internal/newer surface), but nothing that feeds an AI-generated summary section into the client-facing home digest.

## Recommended Actions (dry run - no Linear API calls made)

### 1. Reply to the Slack-synced thread

> This is a feature request rather than a support issue, so the SUPESC queue isn't the right place for it. There's no AI-generated market summary in the home digest today - this would be a net-new product feature.
>
> The best path forward is to get this in front of the Client Experience product team as a feature request. I'd recommend the support team or the Acme Realty Group account CSM surface this directly to the Client Experience PM through the normal feature request channel. Noting that Acme Realty Group is willing to beta test is great context to include.
>
> Closing this ticket out since it's not something that can be triaged to an engineering team for implementation through support escalations.

### 2. Close the ticket (mark as Done)

Feature requests should not sit in engineering triage queues. The skill's routing guide notes for User Discovery: "Feature requests only - but usually better to just close the ticket and tell the requester it's a feature request." This is the right call here.

### 3. Do NOT route to a team

Per the skill guidelines, the correct handling for feature requests is to close and redirect, not to route to an engineering team's backlog. Routing it to Client Experience or Intelligence would put an unscoped feature request into a sprint triage queue where it doesn't belong.

## Routing Rationale

The Team Routing Guide says User Discovery handles feature requests, but also notes it's "usually better to just close the ticket and tell the requester it's a feature request." That guidance applies here. The ticket explicitly asks to "get this in front of product" - that's a product process question, not something that belongs in the engineering support escalation pipeline.

If this were routed to any team, the candidates would be:
- **Client Experience** - owns the home digest
- **Intelligence** - owns AI/GPT/semantics features

But neither team should receive unscoped feature requests through SUPESC. The right channel is a direct conversation with the Client Experience PM.
