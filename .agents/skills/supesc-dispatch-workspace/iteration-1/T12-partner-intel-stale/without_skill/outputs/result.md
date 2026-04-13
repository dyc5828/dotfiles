# Triage Result: SUPESC-T12

## Routing

**Team:** Data

## Comment

Routing to Data. The LO's brokerage affiliation in Partner Intel is sourced from the NMLS weekly data pipeline (`nmls_data` DAG in hb-airflow), which builds `dim_loan_officer_employment_history` and `fact_loan_officer_info_search` in Snowflake. The `most_recent_company` logic in `fact_loan_officer_info_search.sql` resolves current affiliation via `dim_loan_officer_location`.

Since the NMLS site shows the correct brokerage but Homebot's data is 6 months stale, the issue is likely in the NMLS data pipeline - either the weekly SFTP feed isn't reflecting the sponsorship change for this individual, the CDC isn't picking up the update, or the `most_recent_company` CTE is resolving to the wrong record. Would start by querying `hist.nmls_individual_sponsorship` and `latest.vw_nmls_individual_sponsorship` for this LO's NMLS ID to see whether the raw data has the updated affiliation.
