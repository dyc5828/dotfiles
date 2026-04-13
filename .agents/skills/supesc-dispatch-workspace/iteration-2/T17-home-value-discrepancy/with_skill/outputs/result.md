# SUPESC-T17 Triage Result

## Ticket
- **ID:** SUPESC-T17
- **Title:** Customer's clients seeing different home values in mobile app vs email digest

## Determination: Category A - Answerable from the codebase

## Action: Answer the question, then close the ticket

### Slack-synced thread reply

Both values are "correct" in that they come from the same calculation, but they were computed at different times. This is the expected behavior of how our system works, not a bug.

The **mobile app** computes the home value in real time every time the client opens their home report. The **email digest** uses a cached version of the home value that was computed when the home was last indexed into Elasticsearch, which could be hours or days before the email was sent.

Here's what likely happened with Nico's home: between the time the email digest value was cached and the time she opened the app, a new AVM (automated valuation) came in from our data provider. The mobile app picked up the new value ($390K) immediately, while the email still showed the value from the previous index ($425K).

**What this means for Morgan's client:** The $390K value in the mobile app is the most current and should be treated as the accurate one. The email value was accurate at the time it was generated, but has since been updated by newer data. Going forward, whenever there's a discrepancy, the mobile app value reflects the latest data.

**Technical detail for context:** Both channels use the same `CalculateHomeValue` interactor in Mikasa, which selects the best available value from AVM records (CoreLogic, Home Price Index, or custom valuations like agent CMAs). The difference is timing:

- Mobile app path: `getReport` Cloud Function -> `MikasaAPI.getUserHome()` -> `Frontend::DetailedHomesController` -> `Frontend::DetailedHomeSerializer` -> `HomeMetaData#home_value` -> `HomeMetadata::CalculateHomeValue` (computed fresh at request time)
- Email digest path: `ApiEmailDelivery::ClientEmails::HomeDigest::DynamicData::V1` -> `HomeDataConcern#elastic_home_value` -> reads `metadata.homeValue` from Elasticsearch (computed when `HomeRecompileJob` last ran via `Home::BuildElasticDocument` -> same `HomeMetaData#home_value`)

The Elasticsearch document for a home gets reindexed when AVMs are created/updated (via `Valuation::Upsert` -> `HomeRecompileJob`), when loans change, or during full reindex jobs. But the email template reads the cached Elasticsearch value, not a fresh computation. If a new AVM arrived after the last reindex but before the email was assembled, the email would show the stale value.

### Closing comment

Closing this out since the behavior is clear from the codebase. If this doesn't fully answer the question or there's something else needed on top of this, feel free to reopen the ticket.

## Routing

Not routed - answered directly and closed.

## Dry-run note

This is a dry-run evaluation. No Linear actions were taken. In a live run:
1. The Slack-synced thread reply above would be posted as a reply to the first comment on the ticket (using `parentId`)
2. The closing comment would be posted as a top-level comment
3. The ticket would be marked as Done
