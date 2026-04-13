# SUPESC-T08 Triage Result

## Action: Route to Customer Experience

## Routing Comment (for Linear)

**Routing: Customer Experience**

This is a character encoding issue in the welcome email customization flow. When Gray pasted text from a Word document into the CEP editor, Word's special Unicode characters (non-breaking spaces, smart quotes, etc.) were preserved through the save pipeline without being normalized. The editor preview looks fine because browsers handle these characters, but the downstream email rendering pipeline does not, causing the `?` replacement.

**Technical detail for the receiving team:** The data flow is: React Quill editor (customer-admin) -> Base64 encode -> Mikasa `CustomMailersController#scrub_custom_mailer_body` -> JSONB storage -> email-templater/SendGrid template. The `scrub_custom_mailer_body` method in `mikasa/app/controllers/custom_mailers_controller.rb` does `Base64.decode64(mailer_body).force_encoding('UTF-8')` and sanitizes HTML tags, but does not normalize Unicode characters like U+00A0 (non-breaking space) that Word injects. The email-templater does `.replace(/&nbsp;/g, ' ')` on the `loan_officer_message` field but this only catches the HTML entity form, not the raw Unicode character `\u00A0`. Fix options: (1) add Unicode normalization in `scrub_custom_mailer_body` to replace non-breaking spaces and other Word-specific characters, (2) configure Quill's clipboard module to strip/normalize on paste, or (3) extend the email-templater regex to also catch `\u00A0`.

## Dry-Run Summary

**What I would do if this were live:**
1. Move ticket SUPESC-T08 to the **Customer Experience** team
2. Post the routing comment above as a top-level comment on the ticket
3. Keep the ticket in **Triage** status for the CX team lead to prioritize

**Category:** B - Routable to a team

**Confidence:** High. The CEP welcome email editor is a Customer Experience feature, and the root cause is in the content sanitization pipeline that spans customer-admin and Mikasa's CustomMailersController. This is not a User Messaging issue (the send infrastructure is fine) - the problem is in how content is processed and stored.

## Investigation Notes

### Key files examined

- `/Users/dan.chen@homebot.ai/code/homebot/customer-admin/src/app/[lang]/(navigation)/profile/digest-settings/richTextEditor.tsx` - React Quill editor, no paste sanitization
- `/Users/dan.chen@homebot.ai/code/homebot/customer-admin/src/api/requests.ts` - `postToCustomMailer` and `patchToCustomMailer` use `Buffer.from(body).toString('base64')` for `encoded-body`
- `/Users/dan.chen@homebot.ai/code/homebot/mikasa/app/controllers/custom_mailers_controller.rb` - `scrub_custom_mailer_body` decodes Base64 and sanitizes tags but does not normalize Unicode characters
- `/Users/dan.chen@homebot.ai/code/homebot/mikasa/app/models/concerns/welcome_email_content_concern.rb` - stores body in JSONB via `jsonb_accessor :content`
- `/Users/dan.chen@homebot.ai/code/homebot/mikasa/app/views/welcome_mailer/for_homeowner.html.erb` - renders `@override.body.html_safe` with no character normalization
- `/Users/dan.chen@homebot.ai/code/homebot/email-templater/src/components/HomeownerWelcomeEmail/HomeownerWelcomeEmail.tsx` - `.replace(/&nbsp;/g, ' ')` only catches HTML entity, not Unicode U+00A0
- `/Users/dan.chen@homebot.ai/code/homebot/mikasa/app/services/api_email_delivery/client_emails/paid_client_welcome/dynamic_data/v1.rb` - passes `custom_welcome_email.body` directly as `loan_officer_message`

### Root cause

Microsoft Word uses Unicode non-breaking space (U+00A0) and other special characters (smart quotes U+201C/U+201D, em dashes U+2014) instead of standard ASCII equivalents. The Quill rich text editor does not sanitize these on paste. The backend sanitizer only strips disallowed HTML tags but does not normalize Unicode characters. The email-templater has a partial fix for `&nbsp;` HTML entities but misses the raw Unicode character form. The result is that these characters either render as `?` in email clients that don't handle them or get mangled during the SendGrid template rendering process.

### Immediate workaround for Gray Golf

Support can advise Gray to re-enter her welcome email content by typing it directly in the editor rather than pasting from Word. Alternatively, she can paste into a plain text editor first (like Notepad or a browser address bar) to strip special characters, then paste from there into the CEP editor.
