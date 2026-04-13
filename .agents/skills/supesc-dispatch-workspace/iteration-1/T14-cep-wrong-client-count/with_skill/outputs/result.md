# SUPESC-T14 Triage Result

## Ticket
- **ID:** SUPESC-T14
- **Title:** Customer CEP showing wrong client count -- dashboard says 500 but HB Admin shows 1,200
- **Status:** Triage (dry-run, no Linear actions taken)

## Triage Category

**B. Routable to a team**

## Routing

**Routing: Customer Experience**

Jordan's CEP dashboard and client list both show stale client counts after a bulk upload done by her enterprise admin. The dashboard count and client list are powered by live Mikasa queries, but the CEP (customer-admin, a Next.js app) caches these API responses using Next.js fetch cache tags. When clients are added externally (bulk upload via enterprise admin rather than through the CEP itself), nothing invalidates the CEP's cached data. The 500 count she sees is the cached value from before the bulk upload. This is a CEP caching/cache-invalidation issue, not a data integrity problem.

## Detailed Findings

### How the numbers work

There are two distinct data paths:

1. **HB Admin "Client Count"** (shows 1,200 correctly):
   - Reads `customer_profile.clients_count`, a denormalized counter column on the `customer_profiles` table.
   - Updated asynchronously via `TrackClientCountsJob` (Sidekiq), triggered by `Client`'s `after_commit` callback on create/destroy.
   - File: `lockbox/app/views/employee/customer_profiles/tabs/_data.html.erb` line 13 -- renders `customer_profile.clients_count`.

2. **CEP Dashboard "Your Clients" card** (shows 500, stale):
   - The dashboard page (`customer-admin/src/app/[lang]/(navigation)/dashboard/page.tsx`) fetches `getCombinedActivityForCustomerV2(customerProfile.data.id)`.
   - This hits Mikasa's `/reports/combined-activity-v2/:id` endpoint, which returns `clients_count: customer_profile.clients.count` -- a live SQL COUNT query (`mikasa/app/models/clients/combined_activity_v2/report.rb`, line 83).
   - The fetch call uses `next: { tags: ['get-combined-activity-for-customer'] }` for Next.js caching.
   - **There is no `revalidateTag('get-combined-activity-for-customer')` call anywhere in the codebase.** This tag is never invalidated.

3. **CEP Client List** (also stale):
   - The client list page fetches from `getOpportunityCounts()` (tag: `get-opportunity-counts`) and `getOpportunityClients()` (tag: `get-opportunity-clients`).
   - These tags are only revalidated when the user creates/deletes opportunity suppressions through the CEP itself (`requests.ts` lines 522-523, 548-549, 573-574).
   - A bulk upload done externally does not trigger these revalidations.

### Root cause

The Next.js data cache in customer-admin has no mechanism to invalidate when clients are added externally (bulk imports, enterprise admin actions, API-driven uploads). The Mikasa backend data is correct -- all 1,200 clients exist in the database. But the CEP serves cached API responses from before the bulk upload.

The user would likely see the correct count if they:
- Hard-refreshed the page (bypassing Next.js cache)
- Waited for the Next.js cache to naturally expire (if a TTL/revalidation interval is configured)
- Performed any action in the CEP that triggers a `revalidateTag` for those tags

### Key files

- `mikasa/app/models/clients/combined_activity_v2/report.rb` -- Dashboard count source (line 83: `customer_profile.clients.count`)
- `mikasa/app/interactors/opportunity_clients/counts.rb` -- Client list total count (line 31: `customer_profile.clients.count`)
- `customer-admin/src/api/requests.ts` -- All fetch calls with cache tags; lines 646-661 for combined-activity-v2, lines 429-436 for opportunity counts
- `customer-admin/src/app/[lang]/(navigation)/dashboard/_components/performance-snapshot-table.tsx` -- Dashboard rendering (line 58: reads `clients-count` from combined activity)
- `lockbox/app/views/employee/customer_profiles/tabs/_data.html.erb` -- HB Admin client count display (line 13: `customer_profile.clients_count`)
- `mikasa/app/models/client.rb` -- `after_commit :update_customer_clients_count` (line 299), triggers `TrackClientCountsJob`

### Immediate workaround

A hard refresh or cache-busting navigation in the CEP should show the correct count. The underlying data is not wrong.

### Surface vs. root cause

- **Surface:** CEP dashboard shows wrong client count after bulk upload
- **Root cause:** Next.js fetch cache in customer-admin is never invalidated for externally-triggered data changes. The `get-combined-activity-for-customer` tag has no revalidation path at all. The `get-opportunity-counts` and `get-opportunity-clients` tags are only revalidated by CEP-initiated suppression actions, not by external client additions.
