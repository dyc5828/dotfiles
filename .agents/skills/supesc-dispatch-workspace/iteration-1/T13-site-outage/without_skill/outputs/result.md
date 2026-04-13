# SUPESC-T13 Triage Result

## Routing Decision

**Assigned Team:** Infrastructure

## Triage Comment

503 errors across all Homebot surfaces - customer admin, client pages, and marketing site - indicate a platform-level outage, not a product-specific issue. This is an Infrastructure incident.

**Severity:** Critical / P0 - full site outage affecting all users.

**Recommended next steps:**
- Check load balancer and origin server health
- Review recent deployments or infrastructure changes
- Check hosting provider status pages
- Spin up incident response channel if not already active
