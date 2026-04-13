## Triage Result

**Ticket:** SUPESC-T05 - Home values showing significantly off for clients in Austin, TX area
**Routed to:** Data
**Severity:** Medium - data quality issue affecting a specific zip code

## Triage Comment

Routing to **Data**. REA Elliot Echo is reporting home values showing ~$150K for properties in Austin 78704 that should be $500K+. The addresses are confirmed correct in HB Admin, so this isn't an address mismatch or client setup issue - the underlying AVM valuations themselves are wrong for this area.

Home values in Homebot come from the `legacy_home_avms` table, which stores automated valuation model estimates from external data providers (CoreLogic, etc.). A zip-code-wide pattern of dramatically low valuations - off by 3x or more - suggests either a bad data feed update for this market, a provider-side issue, or a data pipeline problem that affected this region's property records. The Data team owns home value data quality and the AVM data pipeline, so they're best positioned to investigate whether this is isolated to 78704 or part of a broader data issue.
