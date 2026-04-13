## Triage Result

**Ticket:** SUPESC-T10 - Loan data showing incorrect interest rates for FHA loans in client reports
**Routed to:** Data
**Severity:** Medium - stale rate data affecting refinance calculations

## Triage Comment

Routing to **Data**. FHA loan rates in client home digests are about 2 months stale, which is throwing off refinance savings calculations.

Homebot's mortgage rate data flows through `MortgageRates::Importer`, which runs daily via sidecloq (`Imports::MortgageRatesJob` at 8AM UTC). The importer pulls 30-year fixed and 15-year fixed rates from Freddie Mac's weekly PMMS data, and 5/1 ARM rates from Mortgage News Daily. These get stored in the `mortgage_rates` table and consumed by `FetchLatestAverageMortgageRate`, which feeds the `RefiEligibilityCalculator` to compute refinance savings shown in digests.

The key issue: the `MortgageRate` model only stores generic FIX and ARM types with 30-year and 15-year terms. There is no FHA-specific rate in the mortgage_rates table or the importer pipeline. FHA loans typically carry different rates than conventional 30-year fixed, but Homebot appears to use the same conventional rate for all refi calculations regardless of loan type. If the Freddie Mac PMMS feed has been stale or failing for ~2 months, all rate-dependent calculations would be affected, and the gap would be most visible on FHA loans where the rate differential from conventional is larger.

The Data team should investigate whether the `MortgageRates::Importer` has been successfully pulling fresh rates (check the `mortgage_rates` table for the latest `end_date` and look at Slack notifications to `@skunk-works-team`). If the importer is healthy but rates still appear stale in digests, there may be an Elasticsearch indexing lag - the `bulk_update_clients_elastic_after_importing_rates` job that runs after the import may not be propagating updated rates to elastic documents correctly.
