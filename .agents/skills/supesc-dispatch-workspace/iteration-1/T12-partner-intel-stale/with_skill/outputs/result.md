# SUPESC-T12 Triage Result

## Ticket
- **ID:** SUPESC-T12
- **Title:** Partner intel data showing wrong brokerage for LO in public records

## Action: Route to Data team

## Routing Comment

**Routing: Data**

The partner intel page displays lender/brokerage info for loan officers by looking up the `dim_loan_officer` table in the listings database, which links to `dim_lender` via `dim_lender_id`. Both tables are sourced from NMLS public records data that flows through a weekly Airflow pipeline: NMLS SFTP files are loaded into Snowflake, transformed into `commons.dim_loan_officer` and `commons.dim_lender`, then replicated to the Postgres listings database that Mikasa reads from.

The `dim_lender_id` on the loan officer record is derived from the LO's most recent registration detail in the NMLS data (sorted by `start_date desc`, row 1). If the NMLS site already shows the correct employer (Acme Bank Bravo) but our data still shows Acme Bank Alpha, the issue is somewhere in this data pipeline - either the weekly NMLS file drop hasn't picked up the change, the CDC process didn't propagate it, or the Snowflake-to-Postgres replication hasn't run since the source updated.

This is a data freshness/pipeline issue, not an application bug. The Data team owns the NMLS ingestion pipeline (`nmls_data` DAG) and the Snowflake-to-Postgres export DAGs that populate `dim_loan_officer` and `dim_lender` in the listings database.

## Dry-Run: No Linear actions taken

## Analysis Details

### Data flow traced through the codebase

1. **Display layer:** `PartnerIntel::ProfessionalLookup.lookup_loan_officer` (`mikasa/app/services/partner_intel/professional_lookup.rb`) queries `Markethub::DimLoanOfficer`, which has a `belongs_to :lender` association via `dim_lender_id`. The `company_name` shown on the partner intel page comes from `lo.lender&.lender_name` - the `lender_name` column on the `dim_lender` table.

2. **Database:** Both `dim_loan_officer` and `dim_lender` live in the `listings` Postgres database, accessed via `Markethub::MlsBase` (`connects_to database: { writing: :listings, reading: :listings }`).

3. **Replication:** The `generate_export_dags.py` file defines Snowflake-to-Postgres CDC replication DAGs for both `dim_loan_officer` (line 278-289) and `dim_lender` (line 303-312), sourced from `commons.dim_loan_officer` and `commons.dim_lender` respectively.

4. **Snowflake transformation:** `commons/dim_loan_officer.sql` builds the LO record by joining NMLS individual data with registration details. The `dim_lender_id` is set from the `institution_nmls_id` of the LO's latest registration record (most recent `start_date`). `commons/dim_lender.sql` builds lender records from `hist.nmls_company`.

5. **Source ingestion:** The `nmls_data` DAG (`hb-airflow/dags/nmls_data.py`) runs `@weekly`, fetching NMLS B2B files from SFTP, loading into Snowflake landing tables, running CDC into `hist` tables, then building downstream dimension tables (`dim_lender`, `dim_lender_branch`, `dim_loan_officer_location`, etc.).

### Root cause hypothesis

The LO's NMLS registration detail record showing Acme Bank Bravo either hasn't been picked up in the weekly NMLS file drop yet, or the `nmls_individual_registration_detail` CDC hasn't propagated the new employer. Since the NMLS site shows the correct data, the weekly file should contain it - worth checking whether the most recent `nmls_data` DAG run completed successfully and whether the `hist.nmls_individual_registration_detail` table has a current row for this LO with Acme Bank Bravo as the institution.
