# SUPESC-T03 Triage Result

## Classification: Category A - Answerable from the codebase

## Action: Answer the question and close the ticket

---

### Slack thread reply (to first Slack-synced comment)

Drew's 200 clients will get a welcome email with their first digest. He did not miss the window.

When Homebot sends a home digest to a client, it first checks whether that client should receive a welcome email instead. The check is based entirely on the client's own history - specifically, whether they have ever received a welcome email or any digest before. It does not matter when the welcome email setting was turned on relative to when the clients were uploaded. As long as the client hasn't already received either a welcome email or a digest, their first send will be a welcome email.

So when Drew triggers his manual digest, each of those 200 clients will receive a paid client welcome email instead of the regular home digest. Their next scheduled send after that will be the normal home digest.

**What this means for Drew:** He's in exactly the right spot. The order of operations he followed - upload clients first, enable welcome emails later, then send - works fine. The system decides at send time, not at upload time.

**Technical detail for context:** The welcome-vs-digest decision lives in `DigestDelivery::SendHomeDigest`. At send time it calls `client.will_receive_paid_client_welcome_email?`, which returns true when the client is a homeowner, is on a paid plan (`skip_billing_at` is nil), and has never received a welcome email or digest. This check is independent of the customer-level `welcome_emails_enabled` toggle - the paid client welcome path does not consult that setting. If it returns true, the system sends a `PaidClientWelcome` email and records it as an Ahoy message. On the next send, `has_received_welcome_email?` will find that record and the client will get a regular home digest instead.

---

### Ticket actions (dry run)

- **Reply to Slack-synced comment thread** with the answer above
- **Close ticket** (mark as Done)
- **Post follow-up comment:** "Closing this out since the behavior is clear from the codebase. If this doesn't fully answer the question or there's something else needed on top of this, feel free to reopen the ticket."
- **No routing needed** - answered directly from code
