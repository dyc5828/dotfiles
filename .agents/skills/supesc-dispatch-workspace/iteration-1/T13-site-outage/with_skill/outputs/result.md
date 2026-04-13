# SUPESC-T13 Triage Result

**Ticket:** SUPESC-T13 - Homebot website completely down - 503 errors across all pages
**Action:** Route to **Infrastructure**
**Status:** Keep in Triage (for team lead to prioritize)

## Routing Decision

**Category:** B - Routable to a team

**Target Team:** Infrastructure

**Confidence:** High

## Routing Comment (dry-run, not posted)

**Routing: Infrastructure**

Site-wide 503 errors affecting all Homebot pages - customer admin, client pages, and the marketing site - point to an infrastructure-level issue rather than any single application. This matches Infrastructure's ownership of site-wide outages and page-serving failures. The team should investigate load balancers, web servers, and upstream service health as a starting point.

## Reasoning

The Team Routing Guide is explicit: Infrastructure handles "site-wide outages, pages not serving." This ticket describes exactly that - 503 errors across every surface of homebot.ai, affecting multiple independent applications (customer admin, client-facing pages, marketing site). A 503 Service Unavailable error at this scale indicates a problem at the infrastructure layer (load balancer, reverse proxy, hosting platform, or similar) rather than an application-level bug in any single repo.

The skill notes that Infrastructure tickets are "rare from supesc," but this is the textbook case for when they do come through. No codebase investigation is needed - this is an operational incident, not a code behavior question.

## Actions (dry-run, not executed)

1. Post routing comment on SUPESC-T13 (reply to Slack-synced thread if present)
2. Move ticket to Infrastructure team
3. Keep status as Triage
