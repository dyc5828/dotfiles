# SUPESC-T10 Triage Result

## Ticket

- **ID:** SUPESC-T10
- **Title:** Loan data showing incorrect interest rates for FHA loans in client reports
- **Relevant Area:** Client - Home Value

## Action: Route to Team

**Category B** - Routable to a team. This is a data pipeline issue, not a code bug.

## Routing

**Routing: Data**

The FHA loan rates shown in home digests come from the same mortgage rate pipeline that serves all loan types. There are no FHA-specific rates in the system - the platform uses national average rates for 30-year fixed, 15-year fixed, and 5/1 ARM products, sourced from Freddie Mac and Mortgage News Daily. These rates feed into the refinance savings calculations that LOs see in client digests.

The rates being "2 months stale" points to a failure in the daily import job (`Imports::MortgageRatesJob`) or an upstream data source issue. The import depends on two external sources - Freddie Mac's historical weekly XLSX file and Mortgage News Daily's ARM rate page - and the `MortgageRates::Compiler` requires matching dates from both sources to produce a rate record. If either source fails or stops publishing, new rates stop flowing in, and the system silently continues serving the last successfully imported rates. The job has `retry: 0` and sends Slack notifications only on Thursdays or when new rates are actually fetched, so a sustained failure could go unnoticed.

Surface issue: FHA loan rates look wrong in client digests, making LOs look bad.
Root cause: Likely a stalled mortgage rate import pipeline. The Data team should check the `mortgage_rates` table for the latest `end_date` and investigate why the daily import has not produced new records.

## Routing Comment (for Linear)

**Routing: Data**

The rates shown in client home digests for FHA loans come from the same national mortgage rate pipeline used for all loan types - there are no FHA-specific rates. The daily import job pulls from Freddie Mac and Mortgage News Daily, and both sources must have matching dates for a rate to be recorded. The "2 months stale" symptom suggests the import pipeline has been silently failing. The Data team should check the latest `end_date` in the `mortgage_rates` table and investigate the import job logs to see where the pipeline stalled.

## Codebase Investigation Summary

### Rate Data Pipeline

1. **Source:** Rates are imported daily at 2:00 AM MDT by `Imports::MortgageRatesJob` (Sidekiq, `system` queue, `retry: 0`).
2. **Compiler:** `MortgageRates::Compiler.compile_rates!` fetches from two sources:
   - `MortgageRates::FreddieMac` - 30yr and 15yr fixed rates from Freddie Mac XLSX
   - `MortgageRates::MortgageNewsDaily` - 5/1 ARM rate scraped from HTML
   - Both sources must have a matching date for a rate record to be produced. If either fails, the `rescue` block sends a Slack notification but returns nil/empty, so no rates get imported.
3. **Storage:** `MortgageRate` model in Mikasa (`mortgage_rates` table) with `start_date`, `end_date`, `percentage`, `term`, `mortgage_type`, `source`.
4. **Serving:** `MortgageRateResource` exposes rates via JSON API. The `latest_rates` scope joins on `MAX(end_date)` grouped by `mortgage_type` and `term`.

### How Rates Reach Client Digests

1. Native-backend's `getReport.f.ts` calls `MikasaAPI.instance.getMortgageRates()` (cached for 24 hours).
2. The response feeds into `calculatePrincipalInterestRefi()`, `yourMarket()`, and `shouldYouSell()` - all modules in the own_report (home digest).
3. Refinance savings calculations compare the client's existing loan rate against `rates[0].standardizedRate` (the most recent rate from the `latest_rates` query).

### Why FHA Is Not Special Here

The system does not distinguish FHA rates from conventional rates. All loan types use the same three national rate products (30yr fixed, 15yr fixed, 5/1 ARM). FHA-specific logic only exists for PMI calculations (`pmiRateForFHA` in `principalInterestRefi.ts`), not for the base interest rate. So "FHA rates are wrong" really means "all rates are stale."

### Key Files

- `mikasa/lib/mortgage_rates/compiler.rb` - orchestrates rate fetching from both sources
- `mikasa/lib/mortgage_rates/freddie_mac.rb` - Freddie Mac XLSX fetcher
- `mikasa/lib/mortgage_rates/mortgage_news_daily.rb` - MND HTML scraper
- `mikasa/lib/mortgage_rates/importer.rb` - imports compiled rates into `mortgage_rates` table
- `mikasa/app/jobs/imports/mortgage_rates_job.rb` - daily Sidekiq job
- `mikasa/app/models/mortgage_rate.rb` - model with `latest_rates` scope
- `mikasa/app/resources/mortgage_rate_resource.rb` - JSON API resource
- `native-backend/functions/src/own_report/getReport.f.ts` - home digest entry point
- `native-backend/functions/src/own_report/modules/principalInterestRefi.ts` - refi calculations
- `native-backend/functions/src/homeownership/ratesHelpers.ts` - `fetchCurrentRate` with fallback

### Failure Modes That Could Cause Staleness

1. **Freddie Mac XLSX download failure** - URL change, format change, or HTTP error. The `rescue` sends a Slack alert but the import produces zero records.
2. **Mortgage News Daily scraping failure** - HTML structure change breaks CSS selectors. Same silent failure pattern.
3. **Date mismatch** - The compiler requires both sources to have the same date. If Freddie Mac publishes on Thursday but MND doesn't (or vice versa), that week gets skipped.
4. **Sidekiq queue backup or job not running** - The job has `retry: 0`, so a single failure means that day's import is lost.
5. **Slack notification gap** - Success notifications only fire on Thursdays or when new rates are fetched. A sustained failure where zero rates are fetched on non-Thursdays would not trigger any alert.
