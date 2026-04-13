## Triage Result

**Route to: Client Experience**

**Priority: Medium**

---

### Comment

The CEP dashboard client count comes from the `combined-activity-v2` Mikasa endpoint, which does a live `customer_profile.clients.count` query. The customer-admin frontend caches this response using a Next.js fetch cache tag (`get-combined-activity-for-customer`), but there is no `revalidateTag` call that invalidates this cache after bulk client imports. HB Admin queries the database directly and reflects the real count.

The 500 vs 1,200 discrepancy (difference of ~700, matching the bulk upload size) is consistent with a stale Next.js Data Cache on the combined activity endpoint. The bulk-uploaded clients exist in the database but the CEP dashboard is serving a cached response from before the import.

**Immediate fix for the customer:** Have Jordan hard-refresh or clear her browser cache, or the team can trigger a revalidation of the `get-combined-activity-for-customer` cache tag.

**Underlying bug:** `customer-admin/src/api/requests.ts` lines 646-662 - the `getCombinedActivityForCustomerV2` fetch uses `next: { tags: ['get-combined-activity-for-customer'] }` for caching, but no code path calls `revalidateTag('get-combined-activity-for-customer')` after client mutations like bulk imports. This cache tag needs to be invalidated when client counts change.

**Key files:**
- `customer-admin/src/api/requests.ts` (lines 646-662) - cached fetch with no revalidation
- `customer-admin/src/app/[lang]/(navigation)/dashboard/_components/performance-snapshot-table.tsx` (line 58) - where `clients-count` is read from combined activity
- `mikasa/app/models/clients/combined_activity_v2/report.rb` (line 83) - the live DB query that returns the correct count
