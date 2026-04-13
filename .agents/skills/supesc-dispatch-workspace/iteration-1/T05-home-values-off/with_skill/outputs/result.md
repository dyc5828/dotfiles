# SUPESC-T05 Triage Result

## Ticket

- **ID:** SUPESC-T05
- **Title:** Home values showing significantly off for clients in Austin, TX area
- **Customer:** Elliot Echo (REA)
- **Affected area:** Austin, TX 78704

## Action: Route to Data team

**Category B** - Routable to a team. This is a data quality issue, not a platform bug.

## Routing Comment

**Routing: Data**

Home values showing significantly off ($150K vs expected $500K+) for multiple clients in Austin, TX 78704. This affects 6 clients reported so far, all in the same zip code, which points to a systemic data issue rather than individual address mismatches. The addresses are confirmed correct in HB Admin - the problem is in the underlying valuation data.

Home values in Mikasa come from one of two paths: CoreLogic AVM estimates or Home Price Index (HPI) derived values. For CoreLogic-supported homes, the AVM amount is pulled from the `home_avms` table via `FindLatestAvmValue`. For HPI-supported homes, the value is calculated using a base data point (appraised value, base value, or sold price from `compiled_homes`) multiplied by an HPI ratio fetched from WeaponX. A zip-code-wide pattern like this could be caused by bad AVM data from CoreLogic for that area, stale or incorrect HPI index data for zip 78704, or outdated/incorrect base values in `compiled_homes`. The Data team has the tools and access to investigate the upstream data source.

## Routing Actions (dry run - not executed)

1. Post routing comment on the ticket (reply to Slack-synced thread if present)
2. Move ticket to **Data** team
3. Keep status as **Triage** for team leads to prioritize

## Reasoning

Per the skill's routing guide, the **Data** team handles "bad loan data, home value issues, address mismatches, public record data." This ticket is a textbook match. Although the symptom surfaces in the client experience (home digest / home values), the skill's "reading the through line" guidance says to look for the root cause. Here, the root cause is clearly bad underlying valuation data for a specific geographic area - not a frontend rendering issue or a platform behavior bug. Multiple clients in the same zip code seeing wrong values rules out individual data entry errors and points to a data provider or data pipeline issue.
