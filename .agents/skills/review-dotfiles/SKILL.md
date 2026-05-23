---
name: review-dotfiles
description: Review dotfiles for uncommitted changes and new files worth tracking. Use when the user says "check dotfiles", "dot review", "review my dotfiles", "sync dotfiles", or wants to audit what's changed and what could be added to their dotfiles repo.
allowed-tools: Bash(dot *), Bash(brew *), Bash(eza *), Bash(comm *), Bash(diff *), Bash(grep *), Bash(sort *), Bash(mkdir *), Bash(rm *), Read, Grep, Glob, Edit
---

# Dot Files Review

Holistic review of the user's dotfiles repo (bare repo at `~/.dotfiles/`, aliased to `dot`). Surfaces everything that's changed or could be tracked, then walks through each file with the user before committing anything.

## Phase 1: Gather State

Run in parallel:

1. `dot status` - modified tracked files
2. `dot ls-files | sort` - everything currently tracked
3. `eza -a1 ~ | grep '^\.' | sort` - all dotfiles/dirs in home
4. `dot log --oneline` - full commit history (ground truth for what's been tracked; use this to verify before claiming something is new or untracked)

## Phase 2: Brewfile Sync

Reconcile `~/Brewfile` with the actual brew install state before anything else gets staged. Brewfile edits made here flow through the rest of the review as a normal modified tracked file.

### Detect drift

```bash
brew bundle dump --file=/tmp/Brewfile.now --force
comm -13 <(sort ~/Brewfile) <(sort /tmp/Brewfile.now)  # installed locally, missing from Brewfile
comm -23 <(sort ~/Brewfile) <(sort /tmp/Brewfile.now)  # in Brewfile, not installed via brew
```

Categorize each diff entry by line prefix: `brew`, `cask`, `tap`, `mas`, `npm`, `vscode`.

### Present categorized drift

Show two tables. Group by category in each.

**Installed locally, missing from Brewfile:**
| Category | Items |
|---|---|
| brew | `foo`, `bar` |
| cask | `baz` |
| mas / npm / vscode | (only show if Brewfile already tracks that category, OR ask user if they want to start) |

**In Brewfile, not installed via brew:**
| Item | Note |
|---|---|
| `kubernetes-cli` | (investigate before suggesting removal — see below) |

### `mas` / `npm` / `vscode` opt-in

These are net-new categories for many Brewfiles. Check current tracking with `grep -oE '^[a-z]+' ~/Brewfile | sort -u` — if a category isn't already present, surface it as an opt-in choice ("Brewfile currently tracks zero `mas` entries — want to start?"). Do not silently add a new category.

### "Tracked but not installed" requires investigation

A Brewfile entry that's not in `brew list` does not automatically mean "remove from Brewfile." Common reasons it might still belong:

- **Satisfied by another install** — e.g., `kubernetes-cli` declared in Brewfile but `kubectl` comes from Docker Desktop's bundled binary at `/usr/local/bin/kubectl`. The Brewfile entry is correct intent; the actual install path is wrong.
- **Required transitively by another tool** — `kubectx` (a godev dep) needs `kubectl` in PATH. Removing the Brewfile entry would mask a real dependency.

Before suggesting removal, run `which <bin>` and check if anything in the Brewfile's brew/cask list depends on the missing entry. If a non-brew path provides the binary, the right answer is usually `brew install <pkg>` so the Brewfile becomes accurate, not removal.

### Resolve drift

For each item, get the user's call. Three options per row:

1. **Add to Brewfile** — for installed-not-tracked items. Edit `~/Brewfile` with the new line in alphabetical position within its section.
2. **Install via brew** — for tracked-not-installed items where the Brewfile declaration is correct. Run `brew install <pkg>` (or `brew install --cask <pkg>`).
3. **Skip / remove** — leave the drift, or remove the Brewfile line if it's truly stale.

After all decisions, `~/Brewfile` is either unchanged or modified. If modified, it shows up in Phase 3's "modified tracked files" table and follows the normal review flow.

## Phase 3: Scan for Changes

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

## Phase 4: Present Full Report

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

## Phase 5: Turn-by-Turn Review

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

After each turn where files are added, skipped, or committed, reprint the full report from Phase 4 with updated statuses. This lets the user see the current state of everything at a glance - what's done, what's pending, and what's been skipped.

### Handling sensitive files (scrub-and-restore)

Any file containing live secrets follows scrub-and-restore by default. Common cases: `.zshenv`, `.zshrc`, `.env`-style files, any shell config exporting API keys or credential pairs.

The pattern:
1. Identify the safe changes vs the secrets. Confirm with the user what the committed version should look like if it's ambiguous.
2. Edit the working copy to the commit-safe version. Usually empty string for secret values, preserving the variable name and surrounding structure.
3. Verify the diff is clean with `dot diff <file>` before staging.
4. Stage and commit through Phases 6 and 7.
5. Restore the real values to the working copy in Phase 8, after push succeeds.

Track which files need restoring so it doesn't get skipped.

Never decide unilaterally how to handle secrets. Work it out with the user, especially when deciding what belongs in the committed version.

## Phase 6: Commit (user-initiated only)

Staging is local and reversible. Committing locks content into history, so wait for the user to explicitly say "commit".

When they do:

1. **Pre-commit secret scan on the staged diff** before creating the commit:

   ```bash
   dot diff --cached
   ```

   Review for: hardcoded API keys/tokens (`ghp_`, `gho_`, `sk-`, `AIza`, `Bearer`, etc.), credential pairs, private keys, internal hostnames or URLs that shouldn't be in a public repo, anything that looks like a secret.

2. **Report results.** If anything looks wrong, stop and flag it. Get the user's explicit OK before committing, especially if anything ambiguous (internal URLs, internal service names) is in the diff and the dotfiles remote is public.

3. Group related changes into logical commits:

   ```bash
   dot add <files>
   dot commit -m "$(cat <<'EOF'
   <summary line>

   <details if needed>
   EOF
   )"
   ```

**Why scan at commit, not at push:** git history is part of the published artifact. Pushing a "fix" on top of a leaky commit does not remove the leak — anyone with the repo can read every commit. Catching leaks at commit time means they never enter history.

## Phase 7: Push (user-initiated only)

Do NOT push automatically after committing. Wait for the user to explicitly say "push".

When the user says push:

1. **Tell the user** you're running a defense-in-depth scan over the full outgoing history. The Phase 6 per-commit scans should have caught everything; this is a backstop for cases where commits were made outside this session.

2. Run the scan against the full outgoing range:

   ```bash
   dot diff origin/main..HEAD
   ```

   Same scan criteria as Phase 6.

3. **If anything is found, stop. Do NOT push.** A leak in unpushed commits is recoverable only if it never gets pushed. Fix by **rewriting the unpushed commits**, not by adding a follow-up commit:

   ```bash
   dot reset --soft origin/main
   ```

   `--soft` is non-destructive: it preserves working tree and index. Re-stage the sanitized content and recommit cleanly. Re-run the scan, then push.

4. If clean, say so and push:

   ```bash
   dot push
   ```

## Phase 8: Post-push restore (for scrubbed files)

If Phase 5 scrubbed any files, restore their real values to the working copy after push succeeds.

**Restore after push, not after commit.** Keeping the working tree scrubbed through push protects against accidental leaks if the push is rejected, amended, or reworked. It also keeps `dot diff` trustworthy until origin matches HEAD.

After restore, `dot status` will show the file as "modified" (scrubbed commit vs restored working tree). Expected, but warn the user never to `dot commit -a` or re-stage that file without re-scrubbing.

If the user explicitly defers push and wants shell access sooner, they can opt into early restore.

## Rules

- NEVER commit plaintext secrets. Scrub-and-restore any file with live secrets; restore only after push succeeds.
- **Always scan `dot diff --cached` before each `dot commit`.** Git history is the published artifact — a leak in any commit, even one later "fixed" on top, is exposed once pushed.
- If a leak makes it into an unpushed commit, fix by rewriting the commit (`dot reset --soft origin/main` + recommit), not by adding a follow-up commit.
- Treat the dotfiles remote as public unless verified otherwise. Internal hostnames, internal Notion page IDs, and infra topology are scan-worthy alongside obvious secrets.
- Staging is fine after user approves a file, but NEVER commit or push unless the user explicitly says to.
- Always print actual file contents when the user asks to see something - no summaries.
- Use `dot` not `git` for all operations.
- Keep tables concise - one line per file.
- Track the running state of what's been committed, what's been skipped, and what's still pending.
