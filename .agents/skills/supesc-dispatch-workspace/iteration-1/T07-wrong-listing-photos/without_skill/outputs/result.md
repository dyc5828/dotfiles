## Triage Result

**Ticket:** SUPESC-T07 - Client home digest showing wrong listing photos
**Route to:** Data
**Priority:** High

## Triage Comment

Routing to **Data**. The listing thumbnail images in the home digest email come from the `thumbnail_image` field on the `search.listings` table in the MarketHub database. This data originates from MLS data providers and flows through the hb-airflow data pipeline (`transient_listings_table.sql` -> `listings_core.sql` -> MarketHub `search.listings`). The Mikasa application layer reads `thumbnail_image` directly from the listing record and passes it through to the email templater without any transformation or re-mapping - address, price, and photo all come from the same row. If addresses and prices are correct but photos are wrong, the mismatch is happening upstream in the data pipeline where `thumbnail_image` is being associated with the wrong listing record during ingestion or transformation. This is a data pipeline issue, not an application rendering bug.
