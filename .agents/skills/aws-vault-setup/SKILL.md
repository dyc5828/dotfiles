---
name: aws-vault-setup
description: Install and configure aws-vault with SSO for Homebot AWS access. Use when setting up AWS credentials on a new machine, adding profiles, or troubleshooting aws-vault/SSO issues.
---

# AWS Vault Setup

Set up `aws-vault` with AWS SSO for Homebot's dev and prod AWS accounts. Authentication flows through Okta via AWS IAM Identity Center.

## What this sets up

- **aws-vault** installed via Homebrew, credentials stored in macOS Keychain
- **AWS CLI v2** installed via Homebrew
- **`~/.aws/config`** with SSO profiles for the user's team
- **SSO login** verified against Homebot's Okta-backed AWS accounts

## Prerequisites

- Homebrew installed
- Okta account provisioned with AWS access (handled by IT during onboarding)

## Step 1: Install dependencies

```bash
brew install aws-vault awscli
```

Verify:
```bash
aws-vault --version
aws --version
```

## Step 2: Configure AWS profiles

Use the team-specific profile blocks from the canonical Notion doc, then apply the corrections in Step 2b below.

**Source**: [Managing your AWS account & aws-vault](https://www.notion.so/homebot/Managing-your-AWS-account-aws-vault-2a2a359d8a5581c6a591eb0c92069484)

Ask the user which team they're on, then have them follow the Notion doc to pick the right `[profile dev]` / `[profile prod]` / etc. snippets for their team. Snippets exist for:

- App Foundations / Client Experience / Customer Experience / Data In & Out / Mercenary Teams
- Data Engineering (gets a superset including `nexus`)
- Infrastructure (use `infra` sso_role_name across all accounts)
- SFTP S3 bucket access (optional, any team)

Copy the relevant blocks into `~/.aws/config`.

**Note:** Profile names in `[profile <name>]` are user-defined. The names in the Notion doc are conventions, not requirements. Profiles are read top-to-bottom; duplicates get overridden by the last definition.

## Step 2b: Required corrections to the Notion config

The Notion source doc is missing a key field. After copying any team's profile blocks, apply this correction to every `[profile ...]` block you added:

**Add `region=us-east-1` as the last line of every profile block.**

For example, the App Foundations / Client Experience / Customer Experience / Data In & Out / Mercenary Teams `[profile dev]` block becomes:

```ini
[profile dev]
sso_start_url=https://d-906767f97d.awsapps.com/start
sso_region=us-east-1
sso_account_id=383767018415
sso_role_name=developers_dev
region=us-east-1            # <-- add this line
```

Apply the same `region=us-east-1` addition to every other profile block you copied (prod, nexus, sftp, infra, etc.).

### Why this correction is needed

`sso_region` and `region` are different fields:

- `sso_region` is the region of the SSO/Identity Center instance (used during the SSO login flow).
- `region` is the default region for AWS API calls (STS, S3, EC2, etc.) once you have credentials.

**Both must be set.** Missing `region` causes `sts..amazonaws.com: no such host` errors with downstream tools like the `dev` CLI — the double-dot in the hostname means an empty region was substituted into the endpoint template.

The Notion source doc historically omits `region`. Until that's fixed upstream, this correction step is mandatory.

## Step 3: SSO login

The user must complete this step interactively - it opens a browser for Okta authentication.

```bash
aws sso login --profile dev
```

This opens a browser, shows a confirmation code in the terminal that must match the browser, and requires Okta approval.

## Step 4: Verify

```bash
# Dev account
aws-vault exec dev -- aws sts get-caller-identity

# Prod account
aws-vault exec prod -- aws sts get-caller-identity
```

Expected output shows the user's email as the UserId and the correct account number:
- Dev: `383767018415`
- Prod: `358063161710`
- Nexus (Data Eng only): `738383832226`

## Kubernetes access (optional)

For teams that need K8s access (e.g., running `godev` commands on `bev` environments):

```bash
# Login with the appropriate profile
aws sso login --profile dev

# Update kubeconfig for the cluster
aws eks update-kubeconfig --name bev --region us-east-1 --profile dev
```

For multiple clusters, install `kubectx` for easy context switching:
```bash
brew install kubectx
```

## Troubleshooting

**SSO login says "token expired"**: Tokens expire after a session window. Re-run `aws sso login --profile <profile>`.

**`aws-vault exec` opens browser again**: This is normal - aws-vault delegates to the SSO flow when credentials have expired.

**"An error occurred (ExpiredTokenException)"**: SSO session expired. Re-run `aws sso login --profile <profile>`.

**Wrong role or account**: Check `~/.aws/config` profile names and role names match what your team should have.

**Browser doesn't open**: Copy the URL printed in the terminal and open it manually. Match the confirmation code shown in the terminal to the one in the browser.

**`sts..amazonaws.com: no such host` (double-dot in URL)**: The profile is missing the `region` field. The double-dot in the hostname means an empty region is being substituted into the STS endpoint template. Quick fix in the current shell: `export AWS_DEFAULT_REGION=us-east-1`. Permanent fix: add `region=us-east-1` to the affected profile block in `~/.aws/config`. This typically happens with `dev console start` and similar tools that construct service endpoints from `region` (not `sso_region`).

## Reference

- Source doc: [Managing your AWS account & aws-vault](https://www.notion.so/homebot/Managing-your-AWS-account-aws-vault-2a2a359d8a5581c6a591eb0c92069484)
- aws-vault GitHub: https://github.com/99designs/aws-vault
