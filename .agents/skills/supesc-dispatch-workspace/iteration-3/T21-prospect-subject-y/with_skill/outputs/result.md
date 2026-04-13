# SUPESC-T21 Triage Result

## Ticket

- **ID:** SUPESC-T21
- **Title:** Subject line shows 'Y' in home search email to prospects
- **Customer:** Reese Sierra

## Action: Route to Client Experience

### Routing Comment (top-level)

**Routing: Client Experience**

This is a content issue with the subject line in prospect-facing home search emails, not a delivery infrastructure problem. Even though the ticket is labeled "Email Deliverability," the emails are being delivered successfully - the problem is that the subject line displays just the letter "Y" instead of the expected text. CLE owns the prospect-facing home search emails and the subject-generation pipeline.

**Technical detail for the receiving team:** The subject-generation code in Mikasa looks correct across all prospect email paths. `HomeSearchReport::DynamicData::V1#generate_subject` (line 95-100 of `home_search_report/dynamic_data/v1.rb`) calls `I18n.t('api_email_dynamic_data.home_search_report.subject_with_zip_code')` or `subject_without_zip_code`, both of which produce full strings in both `en.yml` and `es.yml`. The same is true for `ProspectSingleListing::DynamicData::V1#generate_subject` and `SavedSearch::DynamicData::V1#generate_subject` - all i18n keys resolve to proper sentences. The subject is set on the SendGrid personalization object in `Base#add_personalization_data_to_mail` (line 54 of `base.rb`) directly from `personalization_data[:dynamic_template_data][:subject]`. The email-templater receives the subject as a prop and only uses it for the HTML preview text - it does not modify or override it. Since all Rails code paths produce correct subject strings, the "Y" is likely coming from either (1) a SendGrid dynamic template override on the subject field, (2) a production data issue where the `subject` key in the dynamic template data is being overwritten downstream, or (3) a template-level subject override in SendGrid that contains a Handlebars expression resolving to "Y" from the template data. The team should check the SendGrid template configuration for the `home_search_report` template to see if there's a subject override at the template level that could be pulling a single-character value from the dynamic data.

### Dry-Run Note

No Linear API calls were made. In a live run, this ticket would be:
1. Commented with the routing reasoning above (top-level comment)
2. Moved to the **Client Experience** team
3. Left in **Triage** status for team leads to prioritize

## Investigation Summary

### Why Client Experience, not User Messaging

The "Email Deliverability" label is a red herring. The emails are being delivered - the symptom is wrong subject line content. User Messaging owns send infrastructure (delivery failures, IP warming, throttling, notification channels). This is a content rendering problem in a prospect-facing email, which is Client Experience's domain.

### Code paths examined

| File | What it does with subject |
|------|--------------------------|
| `mikasa/app/services/api_email_delivery/client_emails/home_search_report/dynamic_data/v1.rb` | `generate_subject` (lines 95-100) calls `I18n.t` with zip-code-based keys. Both keys resolve to full sentences. |
| `mikasa/app/services/api_email_delivery/client_emails/prospect_single_listing/dynamic_data/v1.rb` | `generate_subject` (lines 97-111) branches on listing type. All paths return full i18n strings. |
| `mikasa/app/services/api_email_delivery/client_emails/saved_search/dynamic_data/v1.rb` | `generate_subject` (lines 49-71) branches on variant type. All paths return full i18n strings. |
| `mikasa/config/locales/en.yml` | `home_search_report.subject_with_zip_code`: "Your buyer report for %{zip_code} is ready!" / `subject_without_zip_code`: "Your buyer report is ready!" |
| `mikasa/config/locales/es.yml` | Spanish equivalents present and correct for all three email types. |
| `mikasa/app/services/api_email_delivery/client_emails/base_dynamic_data.rb` | Sets `I18n.locale = client.locale \|\| :en` in initializer. Merges `specific_template_data` (which includes `subject`) with shared data. |
| `mikasa/app/services/api_email_delivery/client_emails/base.rb` | Line 54: `personalization.subject = personalization_data[:dynamic_template_data][:subject]` - sets subject on SendGrid personalization directly from dynamic data. |
| `mikasa/app/services/api_email_delivery/client_emails/home_search_report/deliver.rb` | Calls `EmailTemplaterClient.new.home_search_report_html_content(personalization_data[:dynamic_template_data])` for HTML body only. |
| `email-templater/src/components/MonthlyProspectEmail/MonthlyProspectEmail.tsx` | Receives `subject` as a prop, uses it only for `preview` text in the HTML. Does not modify or override the subject. |

### Root cause assessment

All Rails translation paths produce correct, full subject strings. The email-templater does not touch the subject. The bug likely lives outside the Rails codebase - candidates include:

1. **SendGrid template-level subject override** - If the SendGrid dynamic template has a subject field configured (rather than relying solely on the personalization subject), and that template subject contains a Handlebars expression like `{{Y}}` or references a field that resolves to "Y", it would override the personalization subject.
2. **Production data anomaly** - Something specific to Reese Sierra's client data causing an unexpected code path, though this seems unlikely given the code's straightforward i18n approach.
3. **SendGrid template version mismatch** - A recently published template version could have introduced a static or malformed subject.

The CLE team should start by checking the SendGrid template configuration for the `home_search_report` template (and related prospect email templates) to see if there is a subject override at the template level.

**Category:** B - Routable to a team

**Confidence:** High. The "Email Deliverability" label points toward User Messaging, but the symptom is clearly about email content (subject line text), not delivery infrastructure. All code paths in Mikasa produce correct subjects, so the issue is downstream - likely in the SendGrid template configuration. CLE owns these prospect-facing emails end to end.
