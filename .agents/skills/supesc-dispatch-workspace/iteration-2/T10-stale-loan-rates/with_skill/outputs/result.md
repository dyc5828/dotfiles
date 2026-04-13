# SUPESC-T10 Triage Result

## Ticket
- **ID:** SUPESC-T10
- **Title:** Loan data showing incorrect interest rates for FHA loans in client reports
- **Description:** Several LOs report FHA loan rates in clients' home digests are significantly off from current market rates - about 2 months stale. Affecting refinance savings calculations.
- **Relevant Area:** Client - Home Value
- **Labels:** Escalation

## Triage Decision: Route to Data

**Category:** B - Routable to a team

## Routing Comment (would be posted as top-level comment on the ticket)

**Routing: Data**

FHA loan rates in the home digest appear stale because the mortgage rate data pipeline may have stopped importing successfully. The application code itself correctly passes through whatever rates are in the database - the staleness is upstream in the data feed, not in the digest rendering.

This needs a non-obvious routing explanation because the ticket surfaces as a "client report" issue, but the root cause is in the data pipeline:

The home digest's refinance calculations (`calculatePrincipalInterestRefi` in native-backend) consume rates from Mikasa's `mortgage_rates` table via the `getMortgageRates` API call. Mikasa imports rates on a daily scheduled job (`Imports::MortgageRatesJob`, runs at 8:00 UTC daily). The importer fetches 30-year fixed and 15-year fixed from Freddie Mac's weekly XLSX feed, and 5/1 ARM rates from Mortgage News Daily by scraping their HTML. The `Compiler` joins these two sources by date - if either source fails or returns no matching dates, no new rates get imported, and `MortgageRate.latest_rates` keeps returning the last successfully imported week.

Two things to investigate:
1. Whether the Freddie Mac XLSX download or Mortgage News Daily scrape has been failing silently. The importer rescues `StandardError` and sends Slack notifications to `@skunk-works-team`, but if the `Compiler.compile_rates!` call returns `nil` (which it does on rescue), the importer receives no new rates and reports zero fetched - which may not trigger any alert since the Slack notification in `message_slack_success` only fires on Thursdays or when rates were actually fetched.
2. Whether the `MortgageNewsDaily` HTML scraper broke due to a site layout change - it parses `div.rate-page table.mtg-rates tr` elements from mortgagenewsdaily.com.

Additionally, native-backend caches the `getMortgageRates` response in Firestore for 24 hours (`TWENTY_FOUR_HOURS_S`), so even after Mikasa's data is fixed, there will be up to a 24-hour delay before the digest shows updated rates.

One important note: there are no FHA-specific interest rates in the mortgage_rates table or the rate pipeline. The system stores conventional fixed (30yr, 15yr) and ARM (5/1) rates only. For home digest refi calculations, FHA loans use these same conventional rates. For the homeownership/buying power analysis engine, FHA loan programs (`FHAHighDTIProgram`, `FHANoReservesProgram`, etc.) consume the single `fetchCurrentRate` value, which is the 30-year fixed conventional rate from Mikasa. FHA-specific adjustments are limited to PMI calculations and LTV/DTI limits, not the base interest rate. So when LOs say "FHA rates are wrong," they're seeing stale conventional rates applied to FHA loan scenarios.

## Actions (dry run - not executed)

1. **Move ticket to Data team** - keep in Triage status for the team lead to prioritize
2. **Do not assign** to a specific person
3. **Do not change priority**

## Key Files Referenced

- `/Users/dan.chen@homebot.ai/code/homebot/mikasa/lib/mortgage_rates/importer.rb` - Rate import orchestrator
- `/Users/dan.chen@homebot.ai/code/homebot/mikasa/lib/mortgage_rates/compiler.rb` - Joins Freddie Mac + Mortgage News Daily sources
- `/Users/dan.chen@homebot.ai/code/homebot/mikasa/lib/mortgage_rates/freddie_mac.rb` - Freddie Mac XLSX fetcher
- `/Users/dan.chen@homebot.ai/code/homebot/mikasa/lib/mortgage_rates/mortgage_news_daily.rb` - MND HTML scraper
- `/Users/dan.chen@homebot.ai/code/homebot/mikasa/app/jobs/imports/mortgage_rates_job.rb` - Scheduled Sidekiq job (daily at 8:00 UTC)
- `/Users/dan.chen@homebot.ai/code/homebot/mikasa/app/models/mortgage_rate.rb` - MortgageRate model with `latest_rates` scope
- `/Users/dan.chen@homebot.ai/code/homebot/mikasa/app/resources/mortgage_rate_resource.rb` - API resource (applies `MortgageRateModifier`)
- `/Users/dan.chen@homebot.ai/code/homebot/native-backend/functions/src/web_apis/MikasaAPI.ts` - `getMortgageRates()` with 24hr Firestore cache
- `/Users/dan.chen@homebot.ai/code/homebot/native-backend/functions/src/homeownership/ratesHelpers.ts` - `fetchCurrentRate()` for buying power analysis
- `/Users/dan.chen@homebot.ai/code/homebot/native-backend/functions/src/own_report/modules/principalInterestRefi.ts` - Refi savings calculations using rates
