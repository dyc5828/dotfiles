---
name: fix-claude-agents
description: 'Fix Claude Code sessions that fail to start with "worker crashed (ENOENT: no such file or directory, posix_spawn ...)". Triggered when a session shows "Session is starting" followed by a respawn loop pointing at a Caskroom path that no longer exists, when new sessions hang or refuse to spawn after a claude-code cask upgrade, or when the user says things like "claude won''t start", "worker crashed respawning", "session is starting forever", or "ENOENT posix_spawn claude". Root cause is a long-lived background daemon pinned to the previous cask version whose binary directory has been removed by the upgrade.'
---

# Fix Stale Claude Code Daemon After Cask Upgrade

When `claude-code@latest` is upgraded via Homebrew, the previous version directory under `/opt/homebrew/Caskroom/claude-code@latest/<old-version>/` is removed. But the long-running supervisor daemon started by the previous version stays alive, holding the old absolute path in memory. When it tries to spawn a worker for a new session, `posix_spawn` returns ENOENT and the supervisor enters a respawn loop — the user sees "Session is starting" forever with `[worker crashed (ENOENT: …) — respawning…]` in the terminal.

## Diagnosis

Three signals to confirm this is the issue:

```bash
# 1. Currently installed cask version (should be NEW)
ls /opt/homebrew/Caskroom/claude-code@latest/

# 2. Symlink target (should point at the NEW version dir)
ls -la /opt/homebrew/bin/claude

# 3. Running daemon — look for the OLD version in argv
ps aux | grep -E "claude.*daemon" | grep -v grep
```

If the daemon's argv references a version directory that no longer exists in step 1, you've confirmed it.

Bonus check — the lock file pins the daemon's version:

```bash
cat ~/.claude/daemon.lock 2>/dev/null
```

## Fix

Kill the stale daemon. The next session start will spawn a fresh one against the current binary and rewrite `daemon.lock`.

```bash
# Find the PID
ps aux | grep -E "claude.*daemon" | grep -v grep

# Kill it
kill <pid>

# Verify it's gone and no replacement was spawned with the old path
ps aux | grep -E "claude.*daemon" | grep -v grep
```

If the daemon respawned itself before you killed it, it sometimes self-resolves — the supervisor process is what holds the stale path; once it exits, the next spawn picks up the current cask version. If `daemon.lock` still references the old version after killing, delete it:

```bash
rm ~/.claude/daemon.lock
```

## Verify

Open a fresh Claude Code session in your terminal. It should start normally. Confirm the new daemon is running against the current version:

```bash
ps aux | grep -E "claude.*daemon" | grep -v grep
```

The argv path should match the current `/opt/homebrew/Caskroom/claude-code@latest/<current-version>/claude`.

## Why this happens

The Claude Code supervisor daemon is spawned with an absolute path to its binary (resolved at start time, not via the `claude` shim). Homebrew cask upgrades replace the version directory atomically — the new dir appears, the old dir is deleted — but a running daemon's cached path is now invalid. The fix is restart, not reinstall.
