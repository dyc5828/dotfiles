# SUPESC-T16 Triage Result

## Ticket

**Title:** Client not receiving any emails - digest, welcome, or notifications
**Reporter:** Logan Lima (LO) / Kai Kilo (client)

## Action: Route to User Messaging

**Category:** B - Routable to a team

## Routing Comment

**Routing: User Messaging**

Kai Kilo is not receiving any emails from Homebot - no digests, no welcome emails, no notifications - despite being on Logan Lima' client list with digests enabled. Other clients of Logan's receive emails normally, and manual sends also fail to reach Kai. This points to a client-level email delivery block rather than a customer/account config issue.

There are several possible causes, all of which live in the email send infrastructure layer rather than any single product domain:

1. **Email marked invalid from a prior hard bounce or spam report.** When SendGrid reports a hard bounce or spam complaint, Mikasa automatically sets `email_verification_code` to `hard_bounce` or `spam` and marks `email_valid` as false. The digest pipeline (`DigestDelivery::EnsureValidClient`) checks `email_valid` and `email_verification_code` before sending - if the code is in the `INVALID_EMAIL_CODES` list (`disposable`, `hard_bounce`, `invalid`, `reject`, `spam`), the job is silently skipped with reason `:client_email_invalid`. This is the most likely cause given that the problem affects all email types and manual sends fail too.

2. **Email on SendGrid's suppression list.** Even if Mikasa considers the email valid, SendGrid maintains its own bounce/complaint suppression lists at the platform level. If Kai's email is on the SendGrid suppression list for the `homebot_clients` subuser, SendGrid will silently drop the send before it ever leaves their infrastructure. Mikasa would still log the send as successful (the API returns 202) but the email never arrives.

3. **ExternalOptOut record.** Every subscription check (`subscribed_to_home_digest?`, `subscribed_to_buyer_digest?`, etc.) calls `externally_opted_out?`, which checks for an `ExternalOptOut` record matching the client's email and corporate profile. If one exists, all digest subscriptions return false. Additionally, the `ApiEmailDelivery::ClientEmails::Base#client` method applies a `.not_externally_opted_out` scope, filtering the client out entirely at the query level - the deliver service gets `nil` for the client and silently returns.

4. **`unsubscribed_from_customer_at` set on `client_email_settings`.** If this timestamp is set, all subscription checks return false via `unsubscribed_from_customer?`, and the `.subscribed_to_customer` scope in the base email delivery service filters the client out.

5. **Email on the `email_blocklists` table.** This is a hard block at the validation level - the client record itself would fail validation if someone tried to update it. Less likely for an existing client but worth checking.

The investigation requires checking Kai Kilo' client record in production for `email_verification_code`, `email_valid`, `email_settings.unsubscribed_from_customer_at`, any `ExternalOptOut` records, and the SendGrid suppression list for his email address. User Messaging owns the send infrastructure, email validation pipeline, and SendGrid integration, so they are the right team to investigate and resolve.

## Investigation Summary

### Code path traced

The digest email pipeline flows through:
- `DigestBlast::QueueHomeDigestForClientJob` - initial eligibility check (validated email, subscribed)
- `DigestDelivery::ProcessDigestSend` organizer, starting with `EnsureValidClient`
- `ApiEmailDelivery::ClientEmails::Base#client` - query-level filtering with multiple scopes
- `ApiEmailDelivery::ClientEmails::HomeDigest::Deliver#call` - final send via SendGrid

### Key files examined

- `mikasa/app/interactors/digest_delivery/ensure_valid_client.rb` - Pre-send validation checks
- `mikasa/app/models/concerns/client_email_subscription_concern.rb` - Subscription state including `externally_opted_out?`
- `mikasa/app/models/concerns/email_validator_concern.rb` - Email validation codes and bounce handling
- `mikasa/app/services/process_inbound_email_webhook/base.rb` - How bounces/complaints update `email_verification_code`
- `mikasa/app/services/api_email_delivery/client_emails/base.rb` - Query-level filtering that silently drops clients
- `mikasa/app/models/external_opt_out.rb` - External opt-out records
- `mikasa/app/models/client/email_setting.rb` - `unsubscribed_from_customer_at` field
- `mikasa/app/models/email_blocklist.rb` - Email blocklist

### What support should check in HB Admin

- Client's `email_verification_code` and `email_valid` fields
- Client's `email_settings.unsubscribed_from_customer_at` value
- Whether an `ExternalOptOut` record exists for Kai's email
- SendGrid Activity Feed and suppression list for Kai's email address
