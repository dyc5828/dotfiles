---
name: pritunl-vpn-setup
description: Install Pritunl and configure one or more Homebot VPN profiles (bev, prod, data, nexus, forge, dev). Use when setting up VPN on a new machine OR re-run to add additional VPN profiles to an existing Pritunl install.
---

# Pritunl VPN Setup

Set up the Pritunl client and configure VPN profiles for Homebot environments. Re-runnable: if Pritunl is already installed, skip to profile configuration and only set up the VPNs the user is missing.

## Available VPNs

Look up the current login URL for each VPC in the [source Notion doc](https://www.notion.so/homebot/Configuring-Pritunl-VPN-2cca359d8a55819f8db9d47b908c8193) — it has the canonical table. Don't bake URLs into this skill (this file is in a public dotfiles repo).

| VPC | Used for |
|---|---|
| **bev** | Engineers: local dev, staging (bev) envs, some elastic.co clusters |
| **prod** | Metabase, some elastic.co clusters |
| **data** | Local RDS access (except markethub — needs ALL VPNs disconnected), Data Eng EC2s |
| **nexus** | Plural (Data Eng) |
| **forge** | Data Eng + Infra: services migrated off Plural, Airbyte Web UI |
| **dev** | Data Eng dev RDS |

Most product engineers need **bev** + **prod**. Data Engineering also needs **data**, **nexus**, **forge**, **dev**.

## Step 1: Determine current state

Before doing anything, check what's already set up so you can skip steps and ask the user only about missing pieces.

```bash
# Is Pritunl installed?
ls /Applications/ | rg -i pritunl
```

Ask the user which VPN(s) they want to set up (reference table above). If re-running, ask which *additional* VPNs they need.

## Step 2: Install the Pritunl client (skip if installed)

```bash
brew install --cask pritunl
```

**Important:** the `.pkg` installer requires `sudo`, which cannot prompt for a password through Claude's Bash tool. Tell the user to run this themselves with the `!` prefix:

```
! brew install --cask pritunl
```

If that still fails with "a terminal is required to read the password", the user should run it directly in their own Terminal.app window where they can type their password.

Verify:
```bash
ls /Applications/ | rg -i pritunl   # → Pritunl.app
```

## Step 3: Configure each VPN profile (web)

For each VPN the user wants, do this loop:

1. Look up the login URL for that VPC in the [Notion doc](https://www.notion.so/homebot/Configuring-Pritunl-VPN-2cca359d8a55819f8db9d47b908c8193), then open it: `open "<login URL>"`
2. Open the Pritunl client (helpful to have it ready): `open -a Pritunl`
3. User clicks **Sign in with Google** with their `@homebot.ai` account
4. **MFA setup** — user scans the QR code at the top of the profile page into 1Password (recommended) or Google Authenticator. Each VPN has its **own** TOTP — save them as e.g. "Pritunl - bev", "Pritunl - prod" so they can be told apart later.
5. **PIN** — the doc says set a 6-digit PIN, but in practice the current Pritunl deployment does not require one for sign-in. Skip if not enforced. If set, store in 1Password.
6. **Download Profile** — scroll down, click **Show More**, then **Download Profile** (or **Download Profile (zip)**). Lands in `~/Downloads/` as `homebot_<email>_homebot-<vpc>.ovpn`.
7. **Keep the browser tab open** — the import step needs the **Profile URI** shown on this page.

## Step 4: Import each profile into the Pritunl client

**Gotcha:** `open -a Pritunl <file>.ovpn` does **not** auto-import in the current client version — it just opens Pritunl. The user must use the GUI Import flow:

1. In the Pritunl client, click **Import** (top right)
2. Provide **both**:
   - The `.ovpn` file (Browse → `~/Downloads/homebot_<email>_homebot-<vpc>.ovpn`)
   - The **Profile URI** shown on the user's web profile page
3. Click Import
4. The profile appears in the client (named e.g. `homebot-bev`)

You can find downloaded profiles to confirm:
```bash
ls -lt ~/Downloads/ | rg -i ovpn
```

## Step 5: Connect and verify

1. In the Pritunl client, click **Connect** on the new profile
2. Enter the **MFA 6-digit code** from 1Password (and PIN if set)
3. Wait a few seconds — the card should show: User, Server, Server Address, Client Address, "Online For" timer

Multiple VPNs can be connected simultaneously (e.g. bev + prod at the same time is fine, except for `markethub` RDS which requires all VPNs disconnected).

Ask the user for a screenshot of the client to confirm.

## Re-running the skill

When invoked again to add more VPNs:
1. Skip install (Pritunl already in `/Applications`)
2. Ask which *additional* VPNs the user needs (don't re-do existing ones)
3. Loop through Steps 3–5 only for the new ones

Existing connected profiles in the client are visible at the top — use that to confirm what's already set up.

## Notes / gotchas

- **VPN drops on sleep / network change** — the client will not auto-reconnect. User just clicks Connect again.
- **Each Pritunl server is independent** — separate Google sign-in, separate MFA TOTP, separate PIN. Don't try to reuse credentials across servers.
- **`markethub` RDS** — requires disconnecting from *all* VPNs (it routes through the public internet, not the VPN tunnel).
- **PIN reset** — the user can reset their own PIN if they remember the current one. Otherwise an admin reset is needed (see admin companion doc linked in the source).

## Reference

- Source doc: [Configuring Pritunl VPN](https://www.notion.so/homebot/Configuring-Pritunl-VPN-2cca359d8a55819f8db9d47b908c8193)
- Admin companion: [Configuring Pritunl VPN :: Admin Companion Docs](https://www.notion.so/2cca359d8a5581c58d6acbe40eca5520)
- Pritunl client downloads: https://client.pritunl.com/
