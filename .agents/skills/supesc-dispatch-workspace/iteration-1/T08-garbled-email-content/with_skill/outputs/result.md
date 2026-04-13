# SUPESC-T08 Triage Result

## Ticket
- **ID:** SUPESC-T08
- **Title:** Customer's welcome email content showing garbled characters instead of spaces
- **Customer:** Gray Golf (REA)

## Action: Answerable from the codebase

This can be answered directly from the code. The root cause is a character encoding issue in the welcome email content pipeline when text is pasted from Microsoft Word.

## Findings

### What is happening

When Gray pasted her welcome email content from a Word document into the CEP editor, Microsoft Word's "spaces" came along as non-breaking space characters (Unicode `\u00A0`, which is `0xC2 0xA0` in UTF-8). These are visually identical to regular spaces in the browser-based editor, which is why the preview looks fine. But certain email clients can't render the raw `\u00A0` byte and display it as a `?` replacement character.

### The pipeline

1. **CEP editor** (`customer-admin/src/app/[lang]/(navigation)/profile/digest-settings/richTextEditor.tsx`) uses React-Quill, a rich text editor. When content is pasted from Word, Quill preserves the non-breaking space characters in its HTML output.

2. **API call** (`customer-admin/src/api/requests.ts`, lines 1120-1149, 1151-1181) Base64-encodes the HTML body and sends it to Mikasa as `encoded-body`.

3. **Mikasa controller** (`mikasa/app/controllers/custom_mailers_controller.rb`, line 95) decodes and force-encodes to UTF-8:
   ```ruby
   mailer_body = Base64.decode64(mailer_body).force_encoding('UTF-8')
   ```
   The `force_encoding` call tags the string as UTF-8 but does not transform the bytes. The `\u00A0` characters survive as-is.

4. **HTML sanitizer** (same controller, line 96) strips disallowed tags but does not normalize whitespace characters. The non-breaking spaces pass through untouched.

5. **Storage** - Content is stored in the `custom_mailers` table's `content` JSONB column (via `jsonb_accessor` in `mikasa/app/models/concerns/welcome_email_content_concern.rb`).

6. **Email rendering** (`email-templater/src/components/HomeownerWelcomeEmail/HomeownerWelcomeEmail.tsx`, line 287):
   ```typescript
   __html: (loan_officer_message as string)?.replace(/&nbsp;/g, ' ')
   ```
   This only replaces the HTML entity `&nbsp;` with a regular space. It does NOT replace the actual Unicode non-breaking space character (`\u00A0`). So Word's non-breaking spaces survive all the way into the final HTML sent to the email client.

7. **Email client** - Some email clients (especially older or non-Unicode-aware ones) can't render `\u00A0` and display `?` instead.

### The fix

The immediate fix for Gray's content would be to re-enter her welcome email text by typing it directly rather than pasting from Word, or to paste into a plain text editor first to strip the special characters, then paste into the CEP editor.

The permanent fix would be to normalize non-breaking spaces somewhere in the pipeline. The most appropriate places:
- The email-templater regex on line 287 could be extended to also replace `\u00A0` characters (not just the HTML entity form)
- Or the Mikasa controller's `scrub_custom_mailer_body` method could normalize Unicode whitespace characters after Base64 decoding

## Routing

**Routing: Customer Experience**

This is a CEP editor issue. The welcome email editor in customer-admin is part of the Customer Experience team's domain. The bug is in how the content pipeline handles pasted text from external sources like Word. The email-templater has a partial fix (replacing `&nbsp;` entities) but misses the actual Unicode non-breaking space character that Word inserts.

## Suggested comment for ticket

**Routing: Customer Experience**

Gray's welcome email content contains non-breaking space characters that came from pasting out of Microsoft Word. These are invisible in the editor preview but some email clients render them as question marks. The CEP editor and email rendering pipeline don't currently normalize these characters. Short-term, Gray can fix this by retyping the content directly or pasting through a plain text editor first. Longer term, the content pipeline needs to strip non-breaking spaces during save or render.

## Dry-run note

No Linear API calls were made. In a live triage, this ticket would be:
1. Commented with the findings above (replying to the Slack-synced thread)
2. Moved to the **Customer Experience** team
3. Left in **Triage** status for the team lead to prioritize
