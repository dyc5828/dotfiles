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

Create or update `~/.aws/config` with SSO profiles. The correct profiles depend on the user's team.

**Ask the user which team they're on**, then write the appropriate config.

### App Foundations, Client Experience, Customer Experience, Data In & Out, Mercenary Teams

```ini
[profile dev]
sso_start_url=https://d-906767f97d.awsapps.com/start
sso_region=us-east-1
sso_account_id=383767018415
sso_role_name=developers_dev
region=us-east-1

[profile prod]
sso_start_url=https://d-906767f97d.awsapps.com/start
sso_region=us-east-1
sso_account_id=358063161710
sso_role_name=developers_prod
region=us-east-1
```

### Data Engineering

Data Engineering gets a superset - the above plus a `nexus` account.

```ini
[profile dev]
sso_start_url=https://d-906767f97d.awsapps.com/start
sso_region=us-east-1
sso_account_id=383767018415
sso_role_name=data_engineering_dev
region=us-east-1

[profile prod]
sso_start_url=https://d-906767f97d.awsapps.com/start
sso_region=us-east-1
sso_account_id=358063161710
sso_role_name=data_engineering_prod
region=us-east-1

[profile nexus]
sso_start_url=https://d-906767f97d.awsapps.com/start
sso_region=us-east-1
sso_account_id=738383832226
sso_role_name=nexus_terraformers
region=us-east-1
```

### Infrastructure

Use the `infra` sso_role_name for all AWS accounts. Work with the infrastructure team for specific IAC-managed permissions.

### SFTP S3 bucket access (optional, any team)

For access to the `data-partners` S3 bucket used for customer SFTP uploads:

```ini
[profile sftp]
sso_start_url=https://d-906767f97d.awsapps.com/start
sso_region=us-east-1
sso_account_id=250654616568
sso_role_name=data_sftp
region=us-east-1
```

**Note:** Profile names in `[profile <name>]` are user-defined. The names above are conventions, not requirements. Profiles are read top-to-bottom; duplicates get overridden by the last definition.

**Important:** `sso_region` and `region` are different fields. `sso_region` is the region of the SSO/Identity Center instance (used during the SSO login flow). `region` is the default region for AWS API calls (STS, S3, EC2, etc.) once you have credentials. Both must be set. The Notion source doc historically omitted `region`, which causes `sts..amazonaws.com: no such host` errors with downstream tools like the `dev` CLI. Always include both.

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
