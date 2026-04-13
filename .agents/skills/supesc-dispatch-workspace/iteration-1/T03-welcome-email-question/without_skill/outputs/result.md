# SUPESC-T03 Triage Result

## Ticket Summary

LO Drew Delta uploaded ~200 clients last week and turned on welcome emails yesterday. He's about to send his first manual digest and wants to know if those clients will get a welcome email with it.

## Investigation

Reviewed the codebase to trace how welcome emails are triggered during digest delivery.

**Key code path for home digests** (`DigestDelivery::SendHomeDigest`):
- When a home digest is about to be sent, the interactor calls `should_send_welcome_email?`
- This checks `client.will_receive_paid_client_welcome_email?`
- If true, a paid client welcome email is sent *instead of* the digest

**`will_receive_paid_client_welcome_email?`** on the Client model evaluates:
1. `homeowner?` - client is a homeowner
2. `skip_billing_at.nil?` - client is on a paid plan
3. `!has_received_welcome_email?` - client has never received any welcome email
4. `!has_received_a_digest?` - client has never received a digest (`last_digest_send_date` and `last_buyer_digest_send_date` are both nil)

**Crucially, this method does NOT check `customer_profile.welcome_emails_enabled?`.** The `welcome_emails_enabled` setting on the customer profile only gates the older `will_receive_homeowner_welcome_email?` path. The paid client welcome path is independent of that toggle.

## Answer

Yes, those ~200 clients will receive a welcome email with the first manual digest send - assuming they are homeowner clients on a paid plan who have never received a prior welcome email or digest. Since they were uploaded last week and no digests have been sent yet, they meet all the criteria. The timing of when the "welcome emails" setting was toggled on does not matter for the paid client welcome email flow.

## Triage Decision

- **Route to:** User Messaging
- **Priority:** Low - this is a general question, not a bug or urgent issue
- **Action:** Respond to the support request confirming the behavior, then close

## Suggested Comment

This is a product behavior question, not a bug. Based on the codebase, the answer is yes - those clients will receive a welcome email.

When a home digest is triggered (including manual sends), the system checks whether the client qualifies for a paid client welcome email before sending the digest. The criteria are: the client is a homeowner, on a paid plan, has never received a welcome email, and has never received a digest. Since these clients were uploaded last week and haven't received any emails yet, they meet all the conditions. On the first manual digest, they'll get the welcome email instead of the regular digest, and then subsequent sends will deliver the normal digest.

The `welcome_emails_enabled` toggle on the customer profile does not gate this particular flow - it only applies to the older homeowner welcome email path. So the timing of toggling that setting on is not a factor here.

Routing to User Messaging for awareness, but this can be answered and closed.
