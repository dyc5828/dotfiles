---
name: gh-setup
description: Install and configure GitHub CLI as the single authentication source for GitHub. Replaces plaintext PATs with Keychain-backed OAuth tokens. Use when setting up a new machine, resetting GitHub auth, or migrating from classic PATs.
---

# GitHub CLI Authentication Setup

Set up `gh` as the single source of truth for GitHub authentication. All GitHub access - git operations, API calls, Homebrew private taps, Docker builds, GitHub MCP server - flows through one OAuth token stored in the macOS Keychain. No plaintext tokens in dotfiles.

## What this replaces

- Plaintext `GITHUB_TOKEN` in `.zshenv` / `.bashrc`
- `HOMEBREW_GITHUB_API_TOKEN` env var pointing to a hardcoded PAT
- `git config --global url."https://${GITHUB_TOKEN}:@github.com/".insteadOf` hack
- Multiple classic PATs across machines

## What this sets up

- **`gh` CLI** authenticated via OAuth, token stored in macOS Keychain (`gho_` prefix)
- **Git credential helper** via `gh auth setup-git` - HTTPS git operations authenticate on demand
- **Full scope coverage** - repo, workflow, read:org, admin:public_key, write:packages, codespace, gist, read:user, user:email
- **Env var exports** derived from `gh auth token` for tools that need them (Docker, Homebrew private taps, GitHub MCP server)

## Token lifecycle

`gho_` OAuth tokens created by `gh auth login` do not expire. The only ways one stops working:

- You manually revoke it on GitHub
- 1 year of inactivity (no API calls using the token)
- You run `gh auth login` on 10+ machines, bumping the oldest token
- An org admin revokes your SSO authorization

There is no background refresh process. `gh auth token` returns the same stable string until you explicitly re-authenticate.

## Step 1: Install gh

```bash
brew install gh
```

Verify:
```bash
gh --version
```

## Step 2: Authenticate

```bash
gh auth login -s admin:public_key,codespace,read:user,user:email,write:packages
```

When prompted:
1. Where do you use GitHub? → **GitHub.com**
2. What is your preferred protocol for Git operations on this host? → **HTTPS**
3. Authenticate Git with your GitHub credentials? → **Yes**
4. How would you like to authenticate GitHub CLI? → **Login with a web browser**

This stores the OAuth token in the macOS Keychain under `gh:github.com`. No token touches the filesystem. The `-s` flag requests additional scopes beyond the defaults — it's idempotent and safe to include on repeat setups (scopes are tied to the OAuth app authorization on your GitHub account, not the device).

Verify:
```bash
gh auth status
```

Expected scopes: `admin:public_key`, `codespace`, `gist`, `read:org`, `read:user`, `repo`, `user:email`, `workflow`, `write:packages`

You should see `(keyring)` as the source. If you see `(GITHUB_TOKEN)` instead, a plaintext env var is overriding the keyring - find and remove it (see Step 4).

## Step 3: Configure git credential helper

```bash
gh auth setup-git
```

This registers `gh` as the git credential helper. When any tool makes an HTTPS git request, git calls `gh auth git-credential`, which pulls the token from the Keychain on demand. Replaces the `insteadOf` URL rewrite pattern entirely.

Verify:
```bash
# Should show gh entries for github.com and gist.github.com
git config --global --list | rg credential
```

Expected output includes:
```
credential.https://github.com.helper=
credential.https://github.com.helper=!/opt/homebrew/bin/gh auth git-credential
credential.https://gist.github.com.helper=
credential.https://gist.github.com.helper=!/opt/homebrew/bin/gh auth git-credential
```

Note: `gh auth setup-git` adds **host-specific** overrides for `github.com`, not a global `credential.helper`. Checking only `git config --global credential.helper` will not show these entries and will falsely appear unconfigured.

Also verify HTTPS clones work:
```bash
git clone https://github.com/homebotapp/<any-private-repo>.git /tmp/test-clone && rm -rf /tmp/test-clone
```

No password prompt should appear.

## Step 4: Configure shell env vars

Several tools read GitHub tokens from environment variables rather than calling `gh` directly - Docker builds, Homebrew private taps (`homebotapp/homebrew-tap`), and the GitHub MCP server. Export all three from a single `gh auth token` call.

Add to `~/.zshenv` (or `~/.bashrc`):

```bash
# Github - all tokens derived from gh CLI keyring auth
export GITHUB_TOKEN="$(gh auth token)"
export GITHUB_PERSONAL_ACCESS_TOKEN="$GITHUB_TOKEN"
export HOMEBREW_GITHUB_API_TOKEN="$GITHUB_TOKEN"
```

Remove any existing plaintext token exports:

```bash
# Delete these if present:
# export GITHUB_TOKEN="ghp_..."
# export GITHUB_PERSONAL_ACCESS_TOKEN="ghp_..."
# export HOMEBREW_GITHUB_API_TOKEN="ghp_..."
```

Also remove the `insteadOf` rule from git config if present:
```bash
git config --global --unset-all url.https://.insteadof 2>/dev/null
```

## Step 5: Authorize for SAML SSO (Homebot-specific)

**Manual step** - no CLI for this.

1. Go to https://github.com/settings/applications
2. Find **GitHub CLI** in the Authorized OAuth Apps list
3. Click **Configure SSO** next to `homebotapp` and authorize

Without this, `gh` can authenticate to GitHub but cannot access `homebotapp` org resources. If `gh repo list homebotapp` returns an empty list or a 403, SSO authorization is the problem.

## Step 6: Revoke classic PATs

Once everything works, go to https://github.com/settings/tokens and revoke classic PATs you no longer need. Each one is an attack surface.

Keep a classic PAT only if you have a specific tool or CI system that cannot use OAuth tokens.

## Verification checklist

Run these in a **new terminal** (so `.zshenv` re-evaluates):

```bash
# Auth status - should show full scopes
gh auth status

# Env vars populated
echo $GITHUB_TOKEN
echo $GITHUB_PERSONAL_ACCESS_TOKEN
echo $HOMEBREW_GITHUB_API_TOKEN

# GitHub API
gh api user --jq .login

# Private repo clone over HTTPS
git clone https://github.com/homebotapp/<repo>.git /tmp/test && rm -rf /tmp/test

# Homebrew private tap
brew upgrade godev

# Org access (SAML SSO)
gh repo list homebotapp --limit 3
```

## Starting fresh / full reset

If you need to wipe `gh` auth completely and start over:

```bash
gh auth logout
```

This removes the token from the Keychain. Then re-run from Step 2.

To also revoke the OAuth app authorization on GitHub's side (nuclear option):
1. Go to https://github.com/settings/applications
2. Revoke **GitHub CLI**
3. Re-run from Step 2 (the `-s` flag will re-grant scopes since the app authorization was revoked)

## Troubleshooting

**`gh auth status` shows `(GITHUB_TOKEN)` not `(keyring)`**: A `GITHUB_TOKEN` env var is set. This is expected if you followed Step 5 - the env var contains the same keyring-backed token. It takes precedence over the keyring entry but the token is identical.

**`gh auth token` returns nothing**: Not logged in. Run `gh auth login`.

**HTTPS clone prompts for password**: `gh auth setup-git` wasn't run, or the credential helper isn't configured. Check with `git config --global --list | rg credential` — do NOT use `git config --global credential.helper` alone, as it only shows the global helper and will miss the host-specific `github.com` overrides that `gh auth setup-git` adds.

**Homebrew private tap fails with "HOMEBREW_GITHUB_API_TOKEN is required"**: The `homebotapp/homebrew-tap` custom download strategy requires this specific env var. Verify it's exported: `echo $HOMEBREW_GITHUB_API_TOKEN`.

**"Resource protected by organization SAML enforcement"**: The OAuth token isn't authorized for SSO. Complete Step 6.

**10+ machines / oldest token revoked**: If `gh auth login` has been run on many machines, the oldest tokens get bumped. Re-run `gh auth login` on the affected machine.
