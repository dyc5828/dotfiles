# SUPESC-T19 Triage Result

## Ticket

**Title:** LO's partner intel volume number doesn't match what she expects
**Reporter:** @dolphin.csm

## Action: Route to Customer Experience

**Category:** B - Routable to a team

## Routing Comment

**Routing: Customer Experience**

This is a Partner Intel data accuracy question - LO Payton Papa's volume on the Partner Intel page looks lower than her actual production. Per the known shortcut for Partner Intel data accuracy, CX should take the initial investigation.

The volume numbers shown on the LO profile page come from the `fact_loan` table in Mikasa's listings database. The "Production Snapshot" sidebar displays three volume figures (7-month, 14-month, and YTD), all computed by aggregating `SUM(loan_amount)` from `fact_loan` rows where the `loan_officer_nmls_id` matches and `recording_date` falls within the selected timeframe. The `fact_loan` data itself is sourced from ICE deed records, SAM mortgage records, and active loan feeds, loaded through the Airflow data pipeline. Common reasons for volume appearing low include: the LO's NMLS ID not matching all her records in the underlying ICE data, recent transactions not yet having recording dates populated, or loans attributed to a different NMLS ID (e.g., broker vs. lender NMLS).

CX should start by verifying that Payton Papa's NMLS ID in the `dim_loan_officer` table is correct and checking whether her `fact_loan` records cover the expected transactions. Alberto also asked where the numbers pull from - the answer is public record data (county deed recordings and mortgage filings) via ICE, not self-reported production. If the investigation shifts into questions about the product criteria for how transactions are selected or filtered for display (e.g., which loan types are included, how timeframes are calculated), tag @Chris Johnson on the ticket for a product take.

## Investigation Summary

### Code path traced

- Customer-admin frontend calls `getLoanOfficer(nmlsId)` which hits `GET /markethub/dim-loan-officers/:nmls_id`
- `DimLoanOfficerResource#records` calls `with_loan_metrics(timeframe:)` and `with_fixed_timeframe_loan_metrics` on every query
- `with_loan_metrics` joins a subquery against `fact_loan` that computes `SUM(loan_amount)` grouped by `loan_officer_nmls_id` within a timeframe range
- `with_fixed_timeframe_loan_metrics` computes three fixed-window rollups (7M, 14M, YTD) as separate subquery joins, producing `metrics_total_volume_7m`, `metrics_total_volume_14m`, `metrics_total_volume_ytd`
- The sidebar component renders these as "Loan volume 7 mo", "Loan volume 14 mo", and "YTD loan volume" via `abbreviateCurrency()`
- The `fact_loan` table is built from `vw_conformed_loan_from_ice_deed`, `vw_conformed_loan_from_ice_sam`, and `vw_conformed_loan_from_ice_activeloan` - all public record data, not self-reported
- Timeframe ranges are computed by `TimeframeSupport#timeframe_range`, which calculates rolling windows from `Time.current`

### Key files examined

- `customer-admin/src/app/[lang]/(navigation)/insights/_components/loan-officer-profile/lo-profile-sidebar.tsx` - Frontend display of volume stats
- `customer-admin/src/api/requests/partner-intel.ts` - API call to Mikasa for LO data
- `mikasa/app/resources/markethub/dim_loan_officer_resource.rb` - JSONAPI resource that joins metrics subqueries
- `mikasa/app/models/markethub/concerns/lender_transaction_metrics.rb` - Core volume aggregation SQL (SUM of loan_amount from fact_loan)
- `mikasa/app/models/markethub/concerns/timeframe_support.rb` - Timeframe range calculations (7M, 14M, YTD, etc.)
- `mikasa/app/models/markethub/fact_loan.rb` - fact_loan model, scopes, and schema
- `mikasa/app/resources/markethub/fact_loan_resource.rb` - Individual transaction listing resource
- `hb-airflow/include/sql/commons/fact_loan.sql` - Data pipeline that builds fact_loan from ICE deed/SAM/activeloan sources
- `hb-airflow/include/sql/commons/dim_loan_officer.sql` - LO dimension table built from NMLS registry data

### What support/team should check

- Verify Payton Papa's NMLS ID is correct and matches the `dim_loan_officer` record
- Query `fact_loan` for her NMLS ID to see how many records exist and what date range they cover
- Compare the recording dates of her transactions against the timeframe window she's looking at (the default is 14 months rolling from today)
- Check whether she has loans attributed to a different NMLS ID (broker vs. lender side) or if some transactions have NULL `loan_officer_nmls_id`
- Confirm the user understands that the volume data comes from public records (county recordings), not self-reported production, so there will be a natural lag and some transactions may not appear if they haven't been recorded yet
- If investigation reveals questions about which loan types or transaction types are included/excluded from the count, escalate to @Chris Johnson for product criteria guidance
