# SUPESC-T14 Triage Result

## Ticket
- **ID:** SUPESC-T14
- **Title:** Customer CEP showing wrong client count - dashboard says 500 but HB Admin shows 1,200

## Action: Route to Customer Experience

**Routing: Customer Experience**

Jordan's CEP dashboard is showing a stale client count from before her bulk upload. HB Admin shows the correct 1,200 because it reads the cached `clients_count` field on the customer profile, which gets updated by a Sidekiq job after each client creation. The CEP dashboard gets its count from a different source - the combined activity v2 report endpoint in Mikasa, which does a live database count. However, the CEP's fetch call for this endpoint uses a Next.js Data Cache tag (`get-combined-activity-for-customer`) that is never invalidated anywhere in the codebase. Because the bulk upload happened outside the CEP (through enterprise admin), nothing triggered a cache refresh in customer-admin. A hard refresh or cache purge should show the correct count. The underlying issue is that the combined activity fetch response is tagged for caching but has no revalidation path when clients are added externally.

### Technical detail for the receiving team

The data flow for the client count on the CEP dashboard:

1. `customer-admin/src/app/[lang]/(navigation)/dashboard/page.tsx` calls `getCombinedActivityForCustomerV2()`
2. That fetches `GET /reports/combined-activity-v2/:id` from Mikasa with `next: { tags: ['get-combined-activity-for-customer'] }`
3. In Mikasa, `Clients::CombinedActivityV2::Report#client_stats` does `customer_profile.clients.count` - a live DB query that returns the correct number
4. But the Next.js Data Cache holds the response. The tag `get-combined-activity-for-customer` is defined but `revalidateTag('get-combined-activity-for-customer')` is never called anywhere in the codebase
5. The `PerformanceSnapshotTable` component reads `combinedActivityData.attributes['clients-count']` for the "Your Clients" card total

Meanwhile, HB Admin at `lockbox/app/views/employee/customer_profiles/tabs/_data.html.erb` displays `customer_profile.clients_count` - the denormalized field updated by `TrackClientCountsJob`, which ran after the bulk import completed.

The math checks out: 500 (pre-upload) + 700 (bulk upload) = 1,200 (current actual count shown in HB Admin).

### Key files
- `customer-admin/src/api/requests.ts` (line 646-662) - fetch with cache tag, no revalidation
- `mikasa/app/models/clients/combined_activity_v2/report.rb` (line 81-86) - live count query
- `customer-admin/src/app/[lang]/(navigation)/dashboard/_components/performance-snapshot-table.tsx` (line 58) - reads `clients-count` from combined activity
- `lockbox/app/views/employee/customer_profiles/tabs/_data.html.erb` (line 13) - HB Admin reads cached `clients_count` field

## Dry-run note

This is a dry-run evaluation. No Linear API calls were made. In a live run, this ticket would be:
1. Moved to the **Customer Experience** team
2. Kept in **Triage** status
3. A top-level routing comment posted with the reasoning above
