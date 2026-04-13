# SUPESC-T12 Triage Result

## Ticket

- **ID:** SUPESC-T12
- **Title:** Partner intel data showing wrong brokerage for LO in public records
- **Description:** LO Indigo India's partner intel page shows him affiliated with "Acme Bank Alpha" but he moved to "Acme Bank Bravo" 6 months ago. His NMLS record is correct on the NMLS site but Homebot's data hasn't updated.

## Action: Route to Data team

### Routing Comment (dry run)

**Routing: Data**

The LO's brokerage affiliation on the partner intel page comes from NMLS public record data that flows through a weekly pipeline into Homebot's database. The reporter confirms the NMLS site itself shows the correct brokerage ("Acme Bank Bravo"), which means the source data is right but Homebot's copy is stale. This is a data ingestion or pipeline refresh issue, not an application-layer problem.

This is a non-obvious routing. The ticket mentions partner intel, which is a Customer Experience surface, but the application layer is purely pass-through for lender affiliation data. The `dim_loan_officer` table in the markethub database gets its `dim_lender_id` from Snowflake's `commons.dim_loan_officer`, which derives it from the NMLS `individual_registration_detail` feed. If the NMLS source is correct but Homebot's data hasn't caught up, the break is somewhere in that pipeline.

**Technical detail for the Data team:**

The data flows through this chain:
1. NMLS SFTP weekly feed (`nmls_data` DAG) fetches `nmlsb2bfiles.zip` and loads into Snowflake landing/hist tables via CDC
2. `commons.dim_loan_officer` derives `dim_lender_id` from a `latest_registration` CTE that picks the `institution_nmls_id` from `hist.nmls_individual_registration_detail` with the most recent `start_date`
3. `commons.dim_lender` maps that NMLS ID to the lender name from `hist.nmls_company`
4. CDC replication copies `dim_loan_officer` and `dim_lender` from Snowflake to the markethub Postgres database
5. Mikasa's `Markethub::DimLoanOfficer` model reads from that Postgres table and exposes it via the API

Possible failure points:
- The `nmls_data` DAG may have had failures preventing recent refreshes (check DAG run history)
- The CDC on `nmls_individual_registration_detail` may not have picked up the new registration row
- If the new registration detail row has a `start_date` older than the previous one, the `order by start_date desc` logic would still pick the old row
- The NMLS weekly file itself may lag behind what the NMLS website shows

### Why the Partner Intel shortcut does not apply

The skill's "Partner Intel data accuracy questions" known shortcut routes ambiguous accuracy questions to Customer Experience for initial investigation. That shortcut targets tickets where the root cause is unclear - for example, an LO's volume numbers look wrong but it's not obvious whether the issue is in how data is selected, how it's displayed, or what the source data says.

This ticket is not ambiguous. The reporter has already diagnosed the root cause: the NMLS source site shows the correct brokerage, but Homebot's data hasn't updated. That points directly at the data ingestion pipeline, not at any application-layer logic around how partner intel selects or displays data. Routing to CX for "initial investigation" would add unnecessary indirection when the investigation is already done - the data is stale.

## Metadata

- **Dry run:** Yes - no Linear API calls made
- **Category:** B (Routable to a team)
- **Routed to:** Data
- **Routing confidence:** High - the reporter explicitly identified that the NMLS source is correct and Homebot's data is stale, which places the issue squarely in the data pipeline
- **Partner Intel shortcut evaluated:** Yes - determined not applicable because the root cause is already diagnosed as stale public record ingestion, not an ambiguous data accuracy question
- **Regression status:** PASS - routing matches iteration-1 and iteration-2 (Data team)
