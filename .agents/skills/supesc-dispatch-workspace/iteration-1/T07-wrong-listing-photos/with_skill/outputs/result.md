# SUPESC-T07 Triage Result

## Ticket

- **ID:** SUPESC-T07
- **Title:** Client home digest showing wrong listing photos -- photos belong to different properties
- **Customer:** Finley Foxtrot

## Action: Route to Data team

**Category:** B -- Routable to a team

## Routing Comment

**Routing: Data**

The listing photos shown in the home digest come directly from the `thumbnail_image` field in the listings database (`search.listings`), which is populated by the data pipeline from the Constellation1 data provider. The addresses and prices are correct but the photos are wrong, which points to a `thumbnail_image` mismatch at the data layer -- either the upstream provider sent incorrect photo URLs or the photo-to-listing association was corrupted during ingestion. This is not a rendering or application bug; the email templater and Mikasa code pass through whatever `thumbnail_image` URL is stored for each listing record.

## Analysis

### Data flow traced through the codebase

1. **Email rendering:** `email-templater/src/components/base/ListingCard/ListingCard.tsx` renders `listing.thumbnail_image` as the photo for each listing card (line 50). It does not transform or remap images -- it uses whatever URL it receives.

2. **Digest assembly:** `mikasa/app/services/api_email_delivery/client_emails/home_digest/dynamic_data/v1.rb` builds the home digest email data. It calls `SharedDynamicData::Listings.build(...)` to get listings for the "recently sold" feed (line 98).

3. **Listings fetch:** `mikasa/app/services/api_email_delivery/client_emails/shared_dynamic_data/listings.rb` fetches listings via `Markethub::Listing.fetch_recently_sold(zip_code, target_price, state_abbreviation)` and caches the result for 24 hours (line 76-77). The cache key is `listings.recently_sold.{zip_code}.{target_price}.{state_abbreviation}`.

4. **Listing model:** `mikasa/app/models/markethub/listing.rb` defines `thumbnail_image` as a text column on `search.listings` (line 80 in schema comment, line 208 in `LISTINGS_FIELDS`). The `fetch_recently_sold` method selects `LISTINGS_FIELDS` which includes `thumbnail_image`.

5. **Listing decorator:** `mikasa/app/decorators/listing_decorator.rb` enriches listing data with formatted fields and URIs but does NOT touch `thumbnail_image` -- it passes through from the raw data.

6. **Data pipeline:** In `hb-airflow`, the `thumbnail_image` flows from `hist.listings_partial` through `integration.transient_listings_table` to `markethub.listings_core` and ultimately into the `search.listings` table. The source is the Constellation1 data provider (the only `VALID_DATA_PROVIDER`). For ATTOM-sourced listings, `thumbnail_image` is explicitly set to `null` (`attom_formatted_listing_events.sql` line 144).

### Why this is a Data team issue

- The symptom -- correct addresses/prices but wrong photos -- means the listing records themselves have mismatched `thumbnail_image` URLs. The application code has no logic that could cause cross-listing photo swaps.
- The `thumbnail_image` is ingested from the upstream data provider (Constellation1) through the Airflow data pipeline. Either the provider sent wrong URLs, or there is a data integrity issue in the pipeline.
- The Data team owns the listings data pipeline and the Constellation1 integration, and would need to investigate whether the mismatch is upstream or in the ETL.
- There is an existing Great Expectations check in `hb-airflow/dags/hourly_gx_checks.py` that validates `thumbnail_image` is not null, but there is no validation that the image URL corresponds to the correct property.

### Note on caching

The listings data is cached for 24 hours (`RECENTLY_SOLD_EXPIRES_IN = 24.hours`). If the data was already corrected upstream, the cached version may still be serving stale/incorrect thumbnails. The cache key is `listings.{feed_type}.{zip_code}.{target_price}.{state_abbreviation}`. This is worth mentioning to the Data team as context.
