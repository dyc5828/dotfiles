# SUPESC-T06 Triage Result

## Ticket
- **ID:** SUPESC-T06
- **Title:** Digest emails not being delivered for any customers since this morning
- **Labels:** Escalation, Email

## Action: Route to User Messaging

**Category B** - Bug/outage routable to a team.

## Routing Comment (would be posted as top-level comment on ticket)

**Routing: User Messaging**

Widespread digest delivery failure across all customers and plans, with manual sends also failing, points to send infrastructure rather than scheduling or customer configuration. This is a delivery pipeline outage, not a content or data issue.

The digest delivery flow runs through three external dependencies in sequence: the email-templater service (generates HTML), SendGrid (delivers the email), and Sidekiq (processes the job queue). The failure hitting both scheduled and manual sends rules out the scheduling layer (sidecloq cron jobs, `DISABLE_DIGEST_SCHEDULING` env var, or the `HomeDigestDueClient` materialized view being stale). Since manual sends bypass all of that and go straight through `DigestDelivery::ProcessDigestSend` to the `EmailTemplaterClient` and `SendGridClient`, the break is in one of those two services or their authentication credentials.

Likely suspects in order of probability:
1. **Email-templater service down or unhealthy** - The `EmailTemplaterClient` calls out to the email-templater service (configured via `EMAIL_TEMPLATER_URL` / `EMAIL_TEMPLATER_TOKEN` env vars) to generate HTML content. If this service is down or returning errors, every digest type fails with `template_generation_failed`.
2. **SendGrid API key issue** - The `SendGridClient` raises `APIKeyMissing` if the `SENDGRID_HOMEBOT_CLIENTS_API_KEY` env var is blank, and `ResponseError` on non-202 responses. A rotated or expired key would break all sends.
3. **Sidekiq queue backlog or worker crash** - Digest jobs run on the `marketing_email` queue (scheduled) and `transactional_email` queue (manual). If Sidekiq workers for these queues are down, jobs queue up but never execute.

User Messaging owns send infrastructure and delivery pipeline health, making this their ticket to investigate.

## Dry-Run Notes

- No Linear API calls were made.
- Ticket would be moved to the **User Messaging** team, kept in **Triage** status.
- No assignment to a specific person.
- Priority left unchanged (widespread outage, but the team lead should set priority based on their own assessment of blast radius).

## Codebase References

Key files investigated to determine routing:

| File | Role |
|------|------|
| `mikasa/app/jobs/digest_job.rb` | Sidekiq job entry point for all digest sends (scheduled + manual) |
| `mikasa/app/interactors/digest_delivery/process_digest_send.rb` | Organizer: validates client, sends digest, tracks, schedules next |
| `mikasa/app/interactors/digest_delivery/send_digest.rb` | Dispatches to home or buyer digest based on type |
| `mikasa/app/interactors/digest_delivery/send_home_digest.rb` | Calls `ApiEmailDelivery::ClientEmails::HomeDigest::Deliver` |
| `mikasa/app/interactors/digest_delivery/base.rb` | Failure categorization: `template_generation_failed`, `sendgrid_auth_failed`, `sendgrid_api_error`, `network_error` |
| `mikasa/app/services/api_email_delivery/client_emails/base.rb` | Builds SendGrid mail object, posts via `SendGridClient` |
| `mikasa/app/services/api_email_delivery/client_emails/home_digest/deliver.rb` | Home digest delivery - calls `EmailTemplaterClient` for HTML |
| `mikasa/app/services/email_templater_client.rb` | HTTP client to email-templater service (`EMAIL_TEMPLATER_URL`) |
| `mikasa/lib/send_grid_client.rb` | SendGrid API wrapper, subuser routing, API key resolution |
| `mikasa/app/jobs/digest_blast/queue_home_digests_job.rb` | Scheduled blast job (cron: 5:30 AM MDT), checks `DISABLE_DIGEST_SCHEDULING` |
| `mikasa/app/controllers/homeowner_emails_controller.rb` | Manual send endpoint, queues via `QueueManualDigestSendJob` |
| `mikasa/config/sidecloq.yml` | Cron schedule for all digest blast jobs |
