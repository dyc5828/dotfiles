# SUPESC-T12 Triage Result

## Ticket

- **ID:** SUPESC-T12
- **Title:** Partner intel data showing wrong brokerage for LO in public records
- **Description:** LO Indigo India's partner intel page shows him affiliated with "Acme Bank Alpha" but he moved to "Acme Bank Bravo" 6 months ago. His NMLS record is correct on the NMLS site but Homebot's data hasn't updated.

## Action: Route to Data team

### Routing Comment (dry run)

**Routing: Data**

Partner intel's loan officer-to-lender affiliation comes from NMLS public record data that flows through a weekly pipeline. The LO's `dim_lender_id` is derived from the most recent `individual_registration_detail` record in the NMLS data feed, which determines which lender appears on the partner intel page. If the NMLS site shows the correct brokerage but Homebot doesn't, the issue is somewhere in the NMLS data ingestion or the downstream transformation - not in the application layer.

This is a non-obvious routing. The ticket reads like a partner intel display issue, but the customer-admin frontend just renders what the Mikasa markethub API returns, and the Mikasa `dim_loan_officer` table is a read-only replica from Snowflake. The application doesn't transform the lender affiliation at all - it passes through `dim_lender_id` directly. The root cause is upstream in the data pipeline.

**Technical detail for the Data team:**

The data flows through this chain:
1. NMLS SFTP weekly feed (`nmls_data` DAG, `@weekly` schedule) fetches `nmlsb2bfiles.zip` and loads into Snowflake landing/hist tables via CDC
2. `commons.dim_loan_officer` SQL derives `dim_lender_id` from the `latest_registration` CTE, which picks the `institution_nmls_id` from `hist.nmls_individual_registration_detail` with the most recent `start_date` (using `row_number() over (partition by loan_officer_nmls_id order by start_date desc)`)
3. `commons.dim_lender` maps that NMLS ID to the lender name from `hist.nmls_company`
4. The two-stage CDC replication pipeline (`generate_export_dags.py`) copies `dim_loan_officer` and `dim_lender` from Snowflake commons to the markethub Postgres database
5. Mikasa's `Markethub::DimLoanOfficer` model reads from that Postgres table and exposes it via the API

Possible failure points to investigate:
- The NMLS weekly file may not include Indigo India's updated registration yet (NMLS data feed lag)
- The CDC on `nmls_individual_registration_detail` may not have picked up the new row, so the `latest_registration` CTE still returns the old `institution_nmls_id`
- The `nmls_data` DAG may have had failures preventing recent refreshes (check DAG run history)
- If the new registration detail row has a `start_date` older than the previous one, the `order by start_date desc` logic would still pick the old row - edge case worth checking

## Metadata

- **Dry run:** Yes - no Linear API calls made
- **Category:** B (Routable to a team)
- **Routed to:** Data
- **Routing confidence:** High - traced the full data flow from NMLS source through Snowflake to Postgres to API; the application layer is purely pass-through
