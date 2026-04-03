---
name: dot-review
description: Review dotfiles for uncommitted changes and untracked files worth adding. Use when the user says "check dotfiles", "dot review", "what's changed in my dotfiles", "sync dotfiles", or wants to audit and commit dotfile changes.
allowed-tools: Bash(dot *), Bash(eza *), Bash(cat *), Read, Grep, Glob, Edit
---

# Dot Review

Holistic review of the user's dotfiles repo (bare repo at `~/.dotfiles/`, aliased to `dot`). Surfaces modified tracked files, finds new untracked files worth adding, and helps commit changes safely.

## Step 1: Gather State

Run these in parallel:

```bash
dot status
```

```bash
dot ls-files | sort
```

```bash
eza -a1 ~ | grep '^\.' | sort
```

This gives you: current modifications, what's already tracked, and what exists in `~`.

## Step 2: Show Modified Tracked Files

For each modified file from `dot status`, run `dot diff <file>` and present a summary table:

| File | Change | Commit? |
|---|---|---|
| path | description of change | Yes/No/Partial |

Flag any file where the diff contains patterns that look like secrets:
- API keys, tokens, passwords (strings starting with `ghp_`, `gho_`, `sk-`, `AIza`, `Bearer`, etc.)
- Credential pairs (username:password patterns)
- Private keys or certificates

For files with mixed safe/secret changes, mark as "Partial" and note which parts are safe.

## Step 3: Scan for New Files Worth Tracking

Compare what exists in `~` against what's tracked. Check these categories for new portable config files:

**AI tools:** `.claude/`, `.codex/`, `.gemini/`, `.cursor/`, `.copilot/`, `.augment/`, `.cagent/`
**Dev tools:** `.config/gh/`, `.config/starship.toml`, `.config/karabiner/`, `.docker/`
**Shell:** `.zshrc`, `.zshenv`, `.zprofile`, `.bashrc`, `.bash_profile`
**Editors:** `.vscode/`, `.vim/`, `.nvim/`
**Skills/agents:** `.skills/`, `.agents/`

For each untracked file or directory found, read the contents and assess:
- Does it contain secrets? Skip it.
- Is it machine-local runtime data (caches, sessions, history)? Skip it.
- Is it a portable preference or config? Flag for addition.

Present new files in a table:

| File | What it is | Commit? |
|---|---|---|
| path | description | Yes/No |

## Step 4: Present Full Report

Combine into a single report with sections:
1. **Modified tracked files** - with diffs available on request
2. **New files to add** - with full contents available on request
3. **Skipped** - brief list of what was checked and why it was skipped

## Step 5: Commit Flow

Wait for user direction on what to commit. For each file the user approves:

1. **Secret check**: Before staging, re-read the file and verify no secrets are being committed. If the file has mixed content (safe changes + secrets), edit the file to the commit-safe version, stage it, then restore the working copy.

2. **Stage**: `dot add <file>`

3. **Commit**: Group related changes into logical commits. Use this format:
   ```
   dot commit -m "$(cat <<'EOF'
   <summary line>

   <details if needed>

   Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
   EOF
   )"
   ```

4. **Push**: Only after user confirms. Run `dot diff HEAD~N..HEAD` first so they can review the full outgoing diff for secrets.

## Rules

- NEVER commit files containing plaintext secrets (API keys, tokens, passwords, credentials)
- When a file has mixed safe/secret content, stage only the safe version and restore secrets after
- Always show the user what's being committed before pushing
- Use `dot` not `git` for all operations
- Print file contents directly when user asks to "see" or "show" a file - don't summarize or recap
- Keep tables concise - one line per file, not paragraph descriptions
