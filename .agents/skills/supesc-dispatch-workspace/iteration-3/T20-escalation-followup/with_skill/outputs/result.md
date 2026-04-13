# SUPESC-T20 Triage Result

## Ticket
- **ID:** SUPESC-T20
- **Title:** Follow up on unresolved escalation - CEP dashboard client count still off weeks later

## Action: Route to Customer Experience

**Routing: Customer Experience**

This is a follow-up on CUX-100, which is already on the Customer Experience board. The original ticket tracked a CEP dashboard client count discrepancy for Jordan Juliet's account - the dashboard was showing a stale number while HB Admin reflected the correct count. That investigation stalled waiting on confirmation from the customer. Rather than re-triaging from scratch, this ticket should go back to the same team so the engineer who was already looking into it can pick up where they left off.

The LO is asking for an update, and the original ticket's last status indicates specific information was requested from the customer before the investigation could proceed. The Customer Experience team should check whether that confirmation was ever received on CUX-100, and if not, follow up directly to unblock resolution.

### Technical context for the receiving team

The root cause identified in the original investigation points to the CEP dashboard's client count coming from the combined activity v2 report endpoint in Mikasa, fetched via `getCombinedActivityForCustomerV2()` in `customer-admin/src/api/requests.ts`. That fetch uses a Next.js Data Cache tag (`get-combined-activity-for-customer`) that has no revalidation path - `revalidateTag('get-combined-activity-for-customer')` is never called anywhere in the codebase. When clients are added externally (bulk upload, enterprise admin), nothing triggers a cache refresh in customer-admin, so the dashboard keeps showing the old count until the cache expires or is manually purged.

The HB Admin count at `lockbox/app/views/employee/customer_profiles/tabs/_data.html.erb` reads the denormalized `clients_count` field, which is updated by `TrackClientCountsJob` and reflects the correct number.

This is the same technical detail from CUX-100 - linking it here so context isn't lost if a different engineer picks this up.

### Key references
- **Original ticket:** CUX-100 (CEP client count discrepancy) - on the Customer Experience board
- **Customer HB Admin:** https://hbadmin.homebot.rocks/employee/users/amb20000-fake-uuid
- `customer-admin/src/api/requests.ts` - fetch with cache tag, no revalidation
- `customer-admin/src/app/[lang]/(navigation)/dashboard/_components/performance-snapshot-table.tsx` - reads `clients-count` from combined activity
- `mikasa/app/models/clients/combined_activity_v2/report.rb` - live count query

## Investigation Summary

No new code investigation was needed. This ticket is a follow-up on a stalled escalation (CUX-100), not a new report. The right move is to route it to the same team that holds the original ticket so context stays consolidated and the engineer who was already investigating can resume. The technical root cause - a missing cache revalidation path for the CEP dashboard's client count fetch - was identified during the original triage and remains unresolved.

## Dry-run note

This is a dry-run evaluation. No Linear API calls were made. In a live run, this ticket would be:
1. Moved to the **Customer Experience** team
2. Kept in **Triage** status
3. A top-level routing comment posted with the reasoning above, referencing CUX-100 as the original ticket
