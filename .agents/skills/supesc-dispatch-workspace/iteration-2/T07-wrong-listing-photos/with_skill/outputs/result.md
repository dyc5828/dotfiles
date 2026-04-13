# SUPESC-T07 Triage Result

## Ticket

- **ID:** SUPESC-T07
- **Title:** Client home digest showing wrong listing photos - photos belong to different properties
- **Customer:** Finley Foxtrot

## Action: Route to Data team

### Routing Comment (top-level)

**Routing: Data**

The listing photos shown in the home digest are pulled directly from the `thumbnail_image` field in the listings database. The application code at every layer - the email template, the listing decorator, the shared dynamic data builder, and the Snowflake-to-RDS sync - passes this field through without any transformation or re-association. Since the addresses and prices are correct but the photos are wrong, the mismatch is in the `thumbnail_image` value stored against each listing record, not in how the app renders them.

The data flow: Constellation1 MLS feed -> `c1_formatted_listing_events` (built by ECS pipeline tasks) -> `transient_listings_table` -> `commons.listings` -> `markethub.listings_core` -> RDS `search.listings` -> Mikasa's `Markethub::Listing` model -> digest email template. The `thumbnail_image` field is passed through at every stage with no logic that could re-associate it with the wrong listing. The corruption is upstream in the data pipeline, likely in how the ECS integration tasks join listing records with their media/thumbnail URLs from the raw MLS feed.

### Dry-Run Note

No Linear API calls were made. In a live run, this ticket would be:
1. Commented with the routing reasoning above (top-level comment)
2. Moved to the **Data** team
3. Left in **Triage** status for team leads to prioritize

## Investigation Summary

### Data Flow Traced

| Layer | File | What happens to `thumbnail_image` |
|-------|------|-----------------------------------|
| Email template | `mikasa/app/views/shared/_listing_card.html.inky-erb` | Renders `listing[:thumbnail_image]` as `<img src>` directly |
| Decorator | `mikasa/app/decorators/listing_decorator.rb` | Does not touch `thumbnail_image` - only merges calculated fields |
| Dynamic data | `mikasa/app/services/api_email_delivery/client_emails/shared_dynamic_data/listings.rb` | Calls `Markethub::Listing.fetch_recently_sold()`, passes attributes through |
| Model | `mikasa/app/models/markethub/listing.rb` | Reads from `search.listings` table - `thumbnail_image` is a text column selected via `LISTINGS_FIELDS` |
| Snowflake sync | `hb-airflow/include/sql/markethub/listings_core.sql` | Passes `thumbnail_image` directly from upstream table |
| Integration | `hb-airflow/include/sql/integration/transient_listings_table.sql` | Passes `fle.thumbnail_image` from `c1_formatted_listing_events` |
| Pipeline | `hb-airflow/dags/constellation1_listings_sql_pipeline.py` | ECS tasks build `c1_formatted_listing_events` from raw MLS data + media |

### Why Data, not Client Experience

The ticket looks like a digest display issue, but the home digest application code is just a pass-through for listing data. There is zero logic in Mikasa that associates photos with listings - that association happens entirely in the data pipeline when the `c1_formatted_listing_events` table is built from raw listing records and their media. The Data team owns this pipeline.
