---
name: homebot-dev-setup
description: Set up a Homebot development environment from scratch on a new or remote macOS machine. Use when the user says "set up dev environment", "bootstrap homebot", "new machine setup", or needs to configure SSH keys, Docker services, or run hbdev bootstrap. Covers Docker network prep, SSH key generation and storage, GitHub authentication, and running the hbdev bootstrap script.
---

# Homebot Dev Environment Setup

End-to-end setup for a Homebot development machine. Handles prerequisites, SSH key configuration, 1Password storage, GitHub authentication (including SAML SSO), Docker services, and running the hbdev bootstrap.

## Prerequisites

Verify before starting:
- Xcode CLI tools (`xcode-select --print-path`)
- Docker Desktop running
- `gh` CLI authenticated (`GITHUB_TOKEN` env var set)
- `op` CLI signed in to Homebot 1Password account

## Step 1: Clean Up Stale Docker Networks

The hbdev `docker-compose.yml` defines `homebot` and `credentials_network`. If these were manually created (outside Compose), Compose will refuse to start with a label mismatch error.

Check for stale networks:
```bash
docker network inspect homebot --format '{{.Labels}}'
docker network inspect credentials_network --format '{{.Labels}}'
```

If labels are empty (`map[]`), remove them after verifying no containers are attached:
```bash
docker network inspect <network_name> --format '{{range .Containers}}{{.Name}} {{end}}'
docker network rm <network_name>
```

## Step 2: Generate SSH Key

Generate an ed25519 key with passphrase (**interactive** — user must enter passphrase):
```bash
ssh-keygen -t ed25519 -C "<user_email>"
```

## Step 3: Configure SSH

Create/update `~/.ssh/config`:
```
Host github.com
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519
```

Omit `UseKeychain yes` if no passphrase was set.

## Step 4: Load Key into SSH Agent

**Interactive** — user will be prompted for passphrase:
```bash
eval "$(ssh-agent -s)"
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
```

## Step 5: Save SSH Key to 1Password

1. Find the Homebot 1Password account UUID:
```bash
op account list --format json
```
Look for the `@homebot.ai` email and note `account_uuid`.

2. Create via template file (`op` CLI doesn't support direct field assignment for SSH Key items):
```bash
PRIV_KEY=$(cat ~/.ssh/id_ed25519) python3 -c "
import json, os
template = {
  'title': 'GitHub SSH Key (<user_email>)',
  'category': 'SSH_KEY',
  'fields': [
    {'id': 'notesPlain', 'type': 'STRING', 'purpose': 'NOTES', 'label': 'notesPlain', 'value': ''},
    {'id': 'private_key', 'type': 'SSHKEY', 'label': 'private key', 'value': os.environ['PRIV_KEY']}
  ]
}
print(json.dumps(template))
" > /tmp/op_ssh_key.json && op item create --template /tmp/op_ssh_key.json --account <account_uuid>; rm /tmp/op_ssh_key.json
```

Note: `op` CLI cannot edit SSH Key items or store the passphrase. Inform user to add passphrase manually in the 1Password app.

## Step 6: Add SSH Key to GitHub

```bash
gh ssh-key add ~/.ssh/id_ed25519.pub --type authentication --title "<user_email>"
```

If this fails with 404 / scope error, the `GITHUB_TOKEN` lacks `admin:public_key`. User needs to either:
- Run `gh auth refresh -h github.com -s admin:public_key`
- Or temporarily use a token with the correct scope

## Step 7: Authorize SSH Key for SAML SSO

**Manual step** — no CLI for this.

Instruct the user:
1. Go to https://github.com/settings/keys
2. Find the newly added key
3. Click "Configure SSO" → Authorize for `homebotapp`

Do NOT proceed until user confirms. Cloning will fail without SSO authorization.

## Step 8: Run Bootstrap

From `~/code/homebot/hbdev`:
```bash
./bin/bootstrap
```

The script validates dependencies, sets up DNS in `/etc/hosts`, clones all Homebot repos via SSH, and starts Docker services (traefik, postgres, redis, elasticsearch, mailhog, kibana).

If previously partially run, it skips already-cloned repos and re-creates Docker services.

## Troubleshooting

- **"Permission denied (publickey)"**: Key not loaded in agent, not on GitHub, or not authorized for SSO. Re-check steps 4, 6, 7.
- **Docker network label mismatch**: Re-run step 1.
- **Platform mismatch warnings** (amd64 vs arm64): Expected on Apple Silicon — safe to ignore.
- **`hbdev up` command**: Deprecated. Use `docker compose -f ~/code/homebot/hbdev/docker-compose.yml up -d`.
