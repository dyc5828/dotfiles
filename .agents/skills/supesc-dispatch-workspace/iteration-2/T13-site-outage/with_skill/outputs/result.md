# Triage Result: SUPESC-T13

## Ticket
- **ID:** SUPESC-T13
- **Title:** Homebot website completely down - 503 errors across all pages
- **Description:** Multiple reports that homebot.ai is returning 503 errors. Customer admin, client pages, and marketing site all affected. Started 20 minutes ago.

## Classification
**Category B: Routable to a team**

This is a site-wide outage, not a question answerable from the codebase and not ambiguous in routing.

## Routing Decision
**Route to: Infrastructure**

## Routing Comment (dry run - not posted)

**Routing: Infrastructure**

All of homebot.ai is returning 503 errors across every surface - customer admin, client pages, and the marketing site. This is a site-wide outage affecting all services, not isolated to any single product domain. Infrastructure owns site-wide availability and serving issues.

## Actions (dry run - not executed)

1. Post the routing comment above as a top-level comment on the ticket.
2. Move the ticket to the **Infrastructure** team.
3. Keep the ticket in **Triage** status for the Infrastructure team lead to prioritize.

## Reasoning

The Team Routing Guide is explicit: Infrastructure handles "site-wide outages, pages not serving." The ticket describes 503 errors across all pages with multiple services affected simultaneously, which is the textbook Infrastructure routing case. No codebase investigation was needed because the symptoms clearly point to an infrastructure-level problem rather than any application-level bug in a specific domain.

The skill notes that Infrastructure tickets are "rare from supesc," which is expected since most support escalations involve feature-level or data-level issues. A full site outage is exactly the rare scenario where Infrastructure is the correct route.
