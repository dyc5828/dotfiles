# SUPESC-T05 Triage Result

## Ticket

- **ID:** SUPESC-T05
- **Title:** Home values showing significantly off for clients in Austin, TX area
- **Description:** REA Elliot Echo reports that several of her clients in the Austin, TX 78704 zip code are seeing home values that are way off - some showing $150K when they should be $500K+. Addresses look correct in HB Admin but the valuations seem wrong.

## Action: Route to Data team

**Category:** B - Routable to a team

## Routing Comment (top-level)

**Routing: Data**

Multiple clients in the same zip code showing drastically wrong home values - $150K instead of $500K+ - points to a data pipeline issue, not an application bug. The Mikasa application code just passes through AVM amounts from the upstream data providers (CoreLogic or SiteX) without any zip-code-level transformation. When a whole zip code is affected, the problem is in the source data feed or the pipeline that loads it.

The application traces like this: the `HomeRefreshService` calls `HomeRefresh::HomeAvmProcessor`, which pulls the AVM `amount` from `WeaponXHomeAvmMapper` (which reads `choice_average` or `average` from the data provider response). For CoreLogic-sourced homes, an optional adjustment layer (`Homes::FindAdjustedHomeValue`) can modify the value, but that's per-home, not zip-wide. The `CalculateHomeValue` interactor then reads the latest AVM from `legacy_home_avms` for CoreLogic homes, or falls back to a Home Price Index (HPI) calculation for non-CoreLogic homes. In the HPI path, values are derived from `compiled_homes` sold/appraised/base data combined with `FetchHomePriceIndexData` from WeaponX. Either way, the application is a pass-through for the underlying data - if values are wrong for an entire zip code, it's the data feed or pipeline, not the rendering layer.

Things to check:
- The `weaponized.avms` table in Snowflake for 78704 FIPS/APN entries - are the `choice_value` / `ez_value` fields showing the wrong amounts in recent loads?
- The CoreLogic voluntary lien status source data (`vw_corelogic_voluntary_lien_status`) - is `estimated_value_mktg` correct for those addresses?
- Whether these homes had a recent `home_value_adjustment` applied that could be distorting the CoreLogic AVM
- Whether these homes fell off CoreLogic coverage and are now using the HPI fallback path with stale or incorrect base values in `compiled_homes`

## Dry-Run Summary

**Would move ticket to:** Data team
**Would set status to:** Triage (unchanged - team leads prioritize)
**Would assign to:** Nobody (leave unassigned)
**Would change priority:** No

### Routing Reasoning

The skill's routing guide says: "Bad loan data, home value issues, address mismatches, public record data" route to Data. The "reading the through line" section also notes that "a digest/listing issue where the data displayed is wrong but the app is rendering correctly" is "likely Data, not Client Experience. Trace the data flow: if the application just passes through a field from the database without transformation, the corruption is upstream in the data pipeline."

This ticket fits that pattern exactly. The symptom is home values significantly off for multiple clients in one zip code. The addresses are confirmed correct in HB Admin. The application code in Mikasa is a pass-through for AVM data that originates from external providers (CoreLogic/SiteX) via the WeaponX data pipeline. When multiple homes in the same geographic area are all wrong, the root cause is almost certainly in the data feed or the Airflow pipeline that loads AVM data into the `weaponized.avms` table, not in the application's value calculation logic.

### Why Not Client Experience?

On the surface, "home values are wrong for clients" could look like a Client Experience ticket since that's where the user sees the problem. But the Mikasa code for calculating home values (`CalculateHomeValue`, `FindLatestAvmValue`, `HomeAvmProcessor`) just reads from `legacy_home_avms` and `compiled_homes` without any zip-code-specific logic that could cause systematic errors across a geography. The corruption is upstream.
