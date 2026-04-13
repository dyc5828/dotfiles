## Triage Result

**Ticket:** SUPESC-T08 - Customer's welcome email content showing garbled characters instead of spaces
**Routed to:** Customer Experience
**Severity:** Medium - single customer, workaround available

## Triage Comment

Routing to **Customer Experience**. This is a character encoding issue in the CEP email editor, not an email delivery problem. The customer pasted text from a Word document, which commonly introduces non-breaking spaces (Unicode \u00A0) or other special whitespace characters that don't survive the editor-to-email rendering pipeline. The preview looks fine because the editor tolerates these characters, but the sent email's encoding or mail client strips them down to replacement characters.

CX owns the CEP editor and the content processing path from editor input to sent email. The fix likely involves sanitizing or normalizing whitespace characters on paste or save in the editor. In the short term, support can advise Gray Golf to retype the spaces manually or paste as plain text (Ctrl+Shift+V) to strip the Word formatting.
