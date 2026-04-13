# SUPESC-T22 Triage Result

## Ticket
- **ID:** SUPESC-T22
- **Title:** Multiple CEP maintenance list bugs - filtering, counts, and empty lists
- **Summary:** Customer Sage Tango reports three related bugs in the Maintenance lists section of CEP: (1) Spam Complaint filter only surfaces clients tagged Invalid Email, (2) the total count in the list header doesn't update when sub-filtering and the page-size option is missing, (3) Dashboard > Highly Engaged Clients > See all shows an empty list despite the Dashboard card showing clients.

## Action: Route to Customer Experience

**Routing: Customer Experience**

Three bugs in the CEP Maintenance and Dashboard surfaces. All three live squarely in Customer Experience territory - the Maintenance lists, their filtering/pagination UI, and the Highly Engaged smart list are all part of the customer-admin app that CX owns. Here's the full scope:

1. **Spam Complaint filter shows wrong tag.** When filtering Email Issues > Spam Complaints, clients who have both Invalid Email and Spam Complaint tags only display the Invalid Email badge. The underlying data is correct (clicking into the client shows both tags), but the list card only renders the first issue type in the array, which happens to be Invalid Email.
2. **Count header and pagination.** The list header stays at the unfiltered "x clients with email issues" total even after drilling into a specific issue type like Spam Complaints. Separately, the previous page-size selector (up to 100 results per page) is no longer available in the current UI.
3. **Highly Engaged list shows empty.** Navigating from Dashboard > Highly Engaged Clients > See all renders "No clients currently on this list" even though the Dashboard card shows a nonzero count. The Dashboard card and the full list page appear to use different data fetching paths or caching, so the card shows the correct count but the detail view comes back empty.

### Technical detail for the receiving team

All three issues are in `customer-admin`:

**Issue 1 - Tag display:** `maintenance-card.tsx` line 101 picks `client.email_issue_types[0]` to render the badge label. When a client has both `with_invalid_email` and `spam_complaint` in the array, only the first element is displayed. The sub-filter correctly fetches clients matching `spam_complaint`, but the card always renders whichever issue type appears first in the array.

**Issue 2 - Count header:** The maintenance page (`page.tsx` line 79-90) fetches a total count via `getClientsForFilterCounts({ email_issues: 'all' })` for the heading. The schema (`maintenance-schema.ts` lines 93-94) maps the heading count to `counts.email_issues` which is the parent-level total, not the sub-filter count. The page-size selector may have been removed during a recent redesign of the maintenance list UI.

**Issue 3 - Highly Engaged empty list:** The Dashboard calls `getHighlyEngagedClients()` (`requests.ts` line 664) for the card, but the "See all" link navigates to the smart list page which fetches its own data. A mismatch between these two data paths - potentially a caching or query parameter discrepancy - would explain the card showing clients while the detail list is empty.

### Key files
- `customer-admin/src/app/[lang]/(navigation)/(clients)/clients/maintenance/maintenance-card.tsx` (line 100-107) - badge only renders first email issue type
- `customer-admin/src/app/[lang]/(navigation)/(clients)/clients/maintenance/page.tsx` (lines 79-90) - heading count uses unfiltered total
- `customer-admin/src/app/[lang]/(navigation)/(clients)/clients/maintenance/maintenance-schema.ts` - filter categories, sub-filter definitions, count mapping
- `customer-admin/src/app/[lang]/(navigation)/(clients)/clients/maintenance/maintenance-sub-filter.tsx` (line 99) - email sub-filter values
- `customer-admin/src/api/requests.ts` (line 664) - `getHighlyEngagedClients` fetch
- `customer-admin/src/app/[lang]/(navigation)/dashboard/page.tsx` - Dashboard page with Highly Engaged card

## Dry-run note

This is a dry-run evaluation. No Linear API calls were made. In a live run, this ticket would be:
1. Moved to the **Customer Experience** team
2. Kept in **Triage** status
3. A top-level routing comment posted with the reasoning above
