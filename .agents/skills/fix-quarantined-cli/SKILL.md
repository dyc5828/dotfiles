---
name: fix-quarantined-cli
description: Fix CLI tools that get killed by macOS Gatekeeper quarantine after a Homebrew install. Trigger this skill automatically whenever you see any of these symptoms — exit code 137, "zsh: killed", a command that runs fine then suddenly stops working after a brew install or upgrade, or a process that dies immediately with no error output. Also trigger when the user says things like "my CLI keeps getting killed", "it just died", "brew install worked but the command doesn't run", "macOS is blocking my tool", "quarantine issue", or "it was working before". Use this proactively as the first thing to check when diagnosing any mysterious Homebrew binary crash — check for com.apple.quarantine before assuming a deeper issue.
---

# Fix macOS Gatekeeper Quarantine on CLI Tools

This is a well-known recurring issue with Homebrew cask installs (especially `claude-code`). Homebrew propagates the `com.apple.quarantine` attribute from its download cache to the installed binary. On macOS, this causes `taskgated` (the kernel's runtime code-signing daemon) to kill the process with `SIGKILL` — even though `codesign --verify` reports the binary as valid on disk.

Symptom in crash reports: `"signal": "SIGKILL (Code Signature Invalid)"` / `"indicator": "Taskgated Invalid Signature"`.

## Step 1: Try removing the quarantine attribute first

```bash
xattr -d com.apple.quarantine $(which <tool-name>)
```

Then test. If it still fails, proceed to Step 2.

## Step 2: If still failing — reinstall clean, then remove quarantine

Sometimes the binary's code signature state is corrupt at the kernel level even after xattr removal. A fresh reinstall fixes this:

```bash
brew reinstall --cask <cask-name>
xattr -d com.apple.quarantine $(which <tool-name>)
```

For `claude-code` specifically:

```bash
brew reinstall --cask claude-code@latest
xattr -d com.apple.quarantine $(which claude)
```

## Step 3: Prevent recurrence with HOMEBREW_CASK_OPTS

Add this to `~/.zshenv` so quarantine is never applied to future cask installs/upgrades. Use `.zshenv` (not `.zshrc`) because it's sourced for all zsh instances — interactive, non-interactive, and scripts — ensuring `brew` always picks it up regardless of how it's invoked:

```bash
export HOMEBREW_CASK_OPTS="--no-quarantine"
```

## Diagnosis commands

```bash
# Check for quarantine attribute
xattr -l $(which <tool>)

# Check crash reports for root cause
ls ~/Library/Logs/DiagnosticReports/<tool>-*.ips

# Verify code signature (valid on disk ≠ valid at runtime)
codesign --verify --verbose=4 $(which <tool>)
```

## Notes

- This issue is tracked in multiple GitHub issues against `anthropics/claude-code` and `Homebrew/homebrew-cask`.
- The quarantine attribute comes back after every `brew upgrade` unless `HOMEBREW_CASK_OPTS="--no-quarantine"` is set.
- `codesign --verify` saying "valid on disk" while the process still gets killed is expected — the kernel's runtime validation (`taskgated`) is stricter than the userspace tool.
