---
name: pnpm-setup
description: Install and configure pnpm via Homebrew alongside nvm. Use when setting up pnpm on a new machine or verifying the pnpm + nvm setup is correct.
---

# pnpm Setup

Install pnpm as a standalone package manager via Homebrew, coexisting with nvm for Node.js version management.

## Design Decision

**pnpm via Homebrew + nvm for Node versions.** These two tools have separate responsibilities and don't conflict:

- **nvm** owns Node.js version management (switching between Node versions)
- **pnpm** owns package management (fast, disk-efficient installs)
- Homebrew installs pnpm as a system-wide binary at `/opt/homebrew/bin/pnpm`
- pnpm uses whatever `node` binary nvm currently has active

### Why Homebrew over alternatives

- **Portability**: On any new machine, it's just `brew install pnpm` — one command, consistent every time
- **No Node coupling**: Unlike corepack, switching Node versions with nvm doesn't affect pnpm
- **Already in the Brewfile**: Tracked in dotfiles, so `brew bundle` installs it automatically

### Why not corepack

Corepack ties pnpm to each Node version. Switching Node versions via nvm could lose or mismatch the pnpm install. Adds unnecessary complexity for no benefit.

### Why not pnpm's own Node management

`pnpm env use` installs Node globally and would conflict with nvm's PATH shims. There's no sandboxed mode — they can't coexist cleanly.

## Step 1: Install via Homebrew

```bash
brew install pnpm
```

Verify:
```bash
pnpm --version
which pnpm  # should be /opt/homebrew/bin/pnpm
```

## Step 2: Verify nvm coexistence

```bash
nvm current        # shows active Node version
node --version     # Node from nvm
pnpm --version     # pnpm from Homebrew
```

Switch Node versions and confirm pnpm still works:
```bash
nvm use 18
pnpm --version     # same pnpm, different Node
```

## Step 3: Ensure Brewfile is updated

pnpm should already be in the Brewfile. Verify:
```bash
grep 'brew "pnpm"' ~/Brewfile
```

If missing, add `brew "pnpm"` to the Brewfile and commit via `dot`.

## Step 4: Configure pnpm global store (optional)

pnpm stores global packages separately from npm/nvm at `~/.local/share/pnpm`. This is independent of Node versions. To set up the global bin directory:

```bash
pnpm setup
```

This adds the pnpm global bin path to your shell config. You may need to restart your shell afterward.

## How it works at runtime

- `pnpm install` in a project uses pnpm's content-addressable store (saves disk space via hard links)
- Global packages (`pnpm add -g`) go to pnpm's own store, not nvm's Node-specific `node_modules`
- Switching Node versions with nvm changes the runtime but pnpm itself and its global packages stay put

## Troubleshooting

**"pnpm: command not found"**: Ensure Homebrew's bin is on your PATH (`/opt/homebrew/bin`). Run `brew link pnpm` if needed.

**pnpm can't find Node**: nvm might not be initialized in the current shell. Ensure your `.zshrc` sources nvm:
```bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
```

**Version mismatch after brew upgrade**: Homebrew may trail the latest pnpm release by a few days. This is an accepted trade-off for portability.
