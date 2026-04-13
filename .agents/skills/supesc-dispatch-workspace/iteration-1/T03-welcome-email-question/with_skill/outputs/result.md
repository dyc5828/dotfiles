# Triage Result: SUPESC-T03

## Routing Decision

**Category A: Answerable from the codebase**

This is a general question about platform behavior, not a bug report. The answer is determinable by reading the code.

## Answer

**Drew's 200 clients will get a welcome email with their first digest. He did not miss the window.**

Welcome emails in Homebot are not sent at the time of upload. They are sent automatically as part of the first digest delivery. When a home digest is triggered for a client - whether through an automated send or a manual blast - the system checks at that moment whether the client qualifies for a welcome email instead of a regular digest.

### What this means for Drew Delta

When Drew sends his first manual digest, each of those 200 clients will be evaluated individually. A client will receive the paid welcome email (instead of a regular digest) if all of the following are true at the time of send:

1. The client is a homeowner
2. They have never received any type of welcome email before
3. They have never received any digest before (no `last_digest_send_date` or `last_buyer_digest_send_date`)

Since these clients were uploaded last week and have never received any emails, they should all qualify for the welcome email on their first digest delivery.

One important note: the "welcome emails enabled" toggle on the customer profile (`welcome_emails_enabled`) is checked in the legacy `will_receive_homeowner_welcome_email?` path but is **not** checked in the `will_receive_paid_client_welcome_email?` path that the current home digest delivery flow uses. So the timing of when Drew flipped that setting on does not matter for this send path - the paid client welcome email eligibility is independent of that toggle.

### Technical detail for context

The flow is in `DigestDelivery::SendHomeDigest` (`mikasa/app/interactors/digest_delivery/send_home_digest.rb`). When a home digest is about to be sent, it calls `should_send_welcome_email?`, which checks `client.will_receive_paid_client_welcome_email?`. That method (`mikasa/app/models/client.rb`, line 503) checks:

- `homeowner?` - is the client a homeowner
- `skip_billing_at.nil?` - is this a paid client (not skipped for billing)
- `!has_received_welcome_email?` - no prior welcome email in the messages table
- `!has_received_a_digest?` - no `last_digest_send_date` or `last_buyer_digest_send_date`

If all conditions pass, the system sends a `PaidClientWelcome` email instead of the regular home digest. The next scheduled digest delivery for that client will then send the regular home digest.

## Comment to post (reply to Slack-synced thread)

> Good news - Drew hasn't missed the window. Welcome emails aren't sent at the time clients are uploaded. They're sent automatically as part of the first digest delivery.
>
> When Drew sends his manual digest, the system will check each client individually. Since those 200 clients have never received any emails from Homebot, they'll each get the welcome email as their first send instead of a regular digest. Their next scheduled digest after that will be the regular home digest.
>
> The timing of when the welcome emails setting was turned on does not affect this - the paid client welcome email path doesn't depend on that toggle.

## Follow-up comment (after closing)

> Closing this out since the behavior is clear from the codebase. If this doesn't fully answer the question or there's something else needed on top of this, feel free to reopen the ticket.
