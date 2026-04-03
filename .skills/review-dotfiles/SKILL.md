---
name: review-dotfiles
description: Review dotfiles for uncommitted changes and new files worth tracking. Use when the user says "check dotfiles", "dot review", "review my dotfiles", "sync dotfiles", or wants to audit what's changed and what could be added to their dotfiles repo.
allowed-tools: Bash(dot *), Bash(eza *), Bash(mkdir *), Bash(rm *), Read, Grep, Glob, Edit
---

# Dot Files Review

Holistic review of the user's dotfiles repo (bare repo at `~/.dotfiles/`, aliased to `dot`). Surfaces everything that's changed or could be tracked, then walks through each file with the user before committing anything.

## Phase 1: Gather State

Run in parallel:

1. `dot status` - modified tracked files
2. `dot ls-files | sort` - everything currently tracked
3. `eza -a1 ~ | grep '^\.' | sort` - all dotfiles/dirs in home

## Phase 2: Scan for Changes

### Modified tracked files

For each modified file from `dot status`, run `dot diff <file>`.

### New files worth tracking

Compare what exists against what's tracked. Explore these directories for portable config:

- **AI tools:** `.claude/`, `.codex/`, `.gemini/`, `.cursor/`, `.copilot/`, `.augment/`, `.cagent/`
- **Dev tools:** `.config/gh/`, `.config/starship.toml`, `.config/karabiner/`, `.docker/`
- **Shell:** `.zshrc`, `.zshenv`, `.zprofile`, `.bashrc`
- **Editors:** `.vscode/`, `.vim/`
- **Skills/agents:** `.skills/`, `.agents/`

For each untracked file found, read the contents. Skip anything that is:
- Secrets (API keys, tokens, passwords, credentials)
- Machine-local runtime data (caches, sessions, history, backups, telemetry)
- Binary files or large databases

Always surface skill workspaces (e.g., eval data, iteration results, benchmarks) for review. These contain portable work product worth tracking.

### Already tracked and unchanged

Note these briefly so the user knows they were checked.

## Phase 3: Present Full Report

Show a single summary table with all findings:

**Modified tracked files:**
| File | Change | Commit? |
|---|---|---|

**New files to add:**
| File | What it is | Commit? |

**Reviewed and skipped:**
| File/Dir | Why |

**Already tracked, unchanged:**
Brief list or count.

## Phase 4: Turn-by-Turn Review

Do NOT stage or commit anything yet. Wait for the user to tell you which files they want to look at.

When the user asks to see a file:
- If it's a modified tracked file, print the diff in a code block
- If it's a new untracked file, print the full file contents in a code block
- Print the actual content - do not summarize or recap

When the user asks to see multiple files, show each one with a clear heading.

Wait for the user's verdict on each file before moving on. They may say:
- "Add it" / "commit it" - mark for commit
- "Skip it" - move on
- "Partial" - discuss which parts to include

### After each decision

After each turn where files are added, skipped, or committed, reprint the full report from Phase 3 with updated statuses. This lets the user see the current state of everything at a glance - what's done, what's pending, and what's been skipped.

### Handling sensitive files

If a file contains a mix of safe changes and secrets:
1. Discuss with the user what the committed version should look like
2. Edit the file to the commit-safe version (e.g., empty string for secrets)
3. Stage it
4. Restore the working copy with the real values

Never decide unilaterally how to handle secrets - work it out with the user.

## Phase 5: Commit

Once the user has approved files, stage and commit. Group related changes into logical commits:

```bash
dot add <files>
dot commit -m "$(cat <<'EOF'
<summary line>

<details if needed>
EOF
)"
```

## Phase 6: Push (user-initiated only)

Do NOT push automatically after committing. Wait for the user to explicitly say "push".

When the user says push, run the pre-push secret check first:

```bash
dot diff <base>..HEAD
```

Where `<base>` is the commit before the first new commit in this session. Review the entire outgoing diff for:
- Hardcoded API keys or tokens (`ghp_`, `gho_`, `sk-`, `AIza`, `Bearer`, etc.)
- Credential pairs (username:password patterns)
- Private keys or certificates
- Any string that looks like a secret

If clean, push. If anything looks wrong, stop and flag it.

```bash
dot push
```

## Rules

- NEVER commit plaintext secrets
- NEVER stage or commit files without the user reviewing and approving them first
- Always print actual file contents when the user asks to see something - no summaries
- Use `dot` not `git` for all operations
- Keep tables concise - one line per file
- Track the running state of what's been committed, what's been skipped, and what's still pending
