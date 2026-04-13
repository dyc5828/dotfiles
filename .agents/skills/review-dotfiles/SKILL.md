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
- **Agents/skills:** `.agents/`, `.agents/skills/`

For each untracked file found, read the contents. Skip anything that is:
- Secrets (API keys, tokens, passwords, credentials)
- Machine-local runtime data (caches, sessions, history, backups, telemetry)
- Binary files or large databases

Always surface skill workspaces (e.g., eval data, iteration results, benchmarks) for review. These contain portable work product worth tracking.

### Already tracked and unchanged

Note these briefly so the user knows they were checked.

## Phase 3: Present Full Report

Show a single summary with all findings:

**Modified tracked files:**
| File | Change | Status |
|---|---|---|

**New files to add:**
| File | What it is | Status |

**Reviewed and skipped:**
| File/Dir | Why |

**Already tracked, unchanged:**
Brief list or count.

After a visual separator (`---`), show unpushed commits. Check using `dot fetch origin` then `dot log FETCH_HEAD..HEAD --oneline`. List each as a bullet point with the short hash and commit message. If none, say "All pushed."

## Phase 4: Turn-by-Turn Review

Do NOT stage or commit anything yet. Wait for the user to tell you which files they want to look at.

When the user asks to see a file:
- If it's a modified tracked file, print the diff in a code block
- If it's a new untracked file, print the full file contents in a code block
- Print the actual content - do not summarize or recap

When the user asks to see multiple files, show each one with a clear heading.

Wait for the user's verdict on each file before moving on. They may say:
- Approve it (e.g., "looks good", "I'm good with that", "yes") - stage it immediately
- "Skip it" - move on
- "Partial" - discuss which parts to include

### After each decision

After each turn where files are added, skipped, or committed, reprint the full report from Phase 3 with updated statuses. This lets the user see the current state of everything at a glance - what's done, what's pending, and what's been skipped.

### Handling sensitive files (scrub-and-restore)

Any file containing live secrets follows scrub-and-restore by default. Common cases: `.zshenv`, `.zshrc`, `.env`-style files, any shell config exporting API keys or credential pairs.

The pattern:
1. Identify the safe changes vs the secrets. Confirm with the user what the committed version should look like if it's ambiguous.
2. Edit the working copy to the commit-safe version. Usually empty string for secret values, preserving the variable name and surrounding structure.
3. Verify the diff is clean with `dot diff <file>` before staging.
4. Stage and commit through Phases 5 and 6.
5. Restore the real values to the working copy in Phase 7, after push succeeds.

Track which files need restoring so it doesn't get skipped.

Never decide unilaterally how to handle secrets. Work it out with the user, especially when deciding what belongs in the committed version.

## Phase 5: Commit (user-initiated only)

Staging files is fine - it's local and reversible. But committing is the point of no return for secrets, so wait for the user to explicitly say "commit". When they do, group related changes into logical commits:

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

When the user says push:

1. **Tell the user** you're running the pre-push secret scan before pushing. Example: "Running the pre-push secret check on the outgoing diff first."
2. Run the check:

```bash
dot diff <base>..HEAD
```

Where `<base>` is the commit before the first new commit in this session. Review the entire outgoing diff for:
- Hardcoded API keys or tokens (`ghp_`, `gho_`, `sk-`, `AIza`, `Bearer`, etc.)
- Credential pairs (username:password patterns)
- Private keys or certificates
- Any string that looks like a secret

3. **Report the result** before pushing. If clean, say so and then push. If anything looks wrong, stop and flag it.

```bash
dot push
```

## Phase 7: Post-push restore (for scrubbed files)

If Phase 4 scrubbed any files, restore their real values to the working copy after push succeeds.

**Restore after push, not after commit.** Keeping the working tree scrubbed through push protects against accidental leaks if the push is rejected, amended, or reworked. It also keeps `dot diff` trustworthy until origin matches HEAD.

After restore, `dot status` will show the file as "modified" (scrubbed commit vs restored working tree). Expected, but warn the user never to `dot commit -a` or re-stage that file without re-scrubbing.

If the user explicitly defers push and wants shell access sooner, they can opt into early restore.

## Rules

- NEVER commit plaintext secrets. Scrub-and-restore any file with live secrets; restore only after push succeeds.
- Staging is fine after user approves a file, but NEVER commit or push unless the user explicitly says to
- Always print actual file contents when the user asks to see something - no summaries
- Use `dot` not `git` for all operations
- Keep tables concise - one line per file
- Track the running state of what's been committed, what's been skipped, and what's still pending
