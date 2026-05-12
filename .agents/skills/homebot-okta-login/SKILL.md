---
name: homebot-okta-login
description: Log into a Homebot Okta SSO-protected app (e.g. Snowflake) using Playwright browser automation and 1Password CLI for credentials and TOTP. Use when navigating to a Homebot internal URL that redirects to Okta and requires sign-in, or when the user says "log me in", "sign in via Okta", or "use SSO to log in".
---

# Homebot Okta Login via Playwright + 1Password

Automates the Homebot Okta SSO login flow — username/password and TOTP both fetched from 1Password — using Playwright MCP browser tools. No secrets are stored anywhere; everything is fetched live from 1Password.

This skill starts at the Okta login form. Navigation to the target app and detecting the auth redirect is out of scope — invoke this once you've confirmed the browser is showing the Okta login page.

## Prerequisites

- Playwright MCP must be running (see `/playwright-setup` if not)
- 1Password CLI (`op`) must be installed and unlocked
- User must be present to biometric-confirm 1Password prompts

## Flow

### Step 1: Fetch credentials from 1Password

Tell the user before running `op`:

> "I'm about to request your credentials from 1Password — you may need to confirm with Touch ID or your system password."

Then fetch:

```bash
op item get "Okta" --fields username,password
```

The item may also be named "Homebot" — if "Okta" isn't found, try that or run `op item list` to locate it.

If the password is hidden (shows `[use 'op item get ... --reveal' to reveal]`), note the item ID in that output and run:

```bash
op item get <item_id> --reveal --fields password
```

### Step 2: Fill in the login form

First take a snapshot to get element refs:

```
mcp__playwright__browser_snapshot
```

Then fill the username and password fields using the refs from the snapshot:

```
mcp__playwright__browser_fill_form → fields: [
  { target: <username_ref>, name: "Username", type: "textbox", value: <username> },
  { target: <password_ref>, name: "Password", type: "textbox", value: <password> }
]
```

Click the "Sign In" button.

### Step 3: Handle MFA (Google Authenticator TOTP)

Okta will redirect to a TOTP challenge page. Take a snapshot to confirm you're on the TOTP page and get the field ref. Then tell the user before running `op`:

> "I'm fetching your TOTP code from 1Password — you may need to confirm with Touch ID again."

Fetch and type immediately:

```bash
op item get "Okta" --otp
```

Then type the 6-digit code:

```
mcp__playwright__browser_type → target: <Enter Code field ref>, text: <6-digit code>
```

Use `slowly: true` if the code isn't accepted — some OTP inputs need per-keystroke events to trigger validation. Click "Verify".

### Step 4: Confirm successful login

Take a snapshot. Confirm the URL no longer contains `okta.com` — that's the reliable signal that authentication succeeded regardless of which app you logged into.

## Troubleshooting

**"Invalid code" on TOTP**: The code may have expired. Re-run `op item get "Okta" --otp` to get a fresh code and retry — TOTP codes rotate on a timer so retrying with a new code is always the first fix.

**Item not found in 1Password**: Try "Homebot" as the item name, or run `op item list` and ask the user to identify it.

**Biometric prompt not appearing**: The `op` session may already be unlocked — credentials will still be returned, this is fine.

**Playwright tools not available**: Run `/playwright-setup` first.
