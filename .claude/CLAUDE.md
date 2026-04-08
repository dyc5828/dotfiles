# User Preferences

Global preferences for Claude behavior across all projects.

## Purpose of This File

This is the **user-level** configuration. It applies to every Claude session regardless of which directory you're in. Use this for:
- Cross-project behavior preferences
- Global tool configurations
- Self-learning protocols

For directory-specific context like dotfiles and project conventions, use a CLAUDE.md in that directory.

## Self-Learning Protocol

Be proactive about improving workflows. Watch for:

**Patterns to notice:**
- User frustration or repeated course-corrections
- Workarounds being used repeatedly
- Tools not working as expected
- Emerging preferences across sessions

**When you notice something:**
1. Synthesize the pattern or observation
2. Ask: "I've noticed [pattern]. Want me to update [file/agent/config] to capture this?"
3. Wait for approval before making changes

**Where learnings go:**
- Agent-specific behaviors → that agent's definition (e.g., `~/.claude/agents/genko.md`)
- Environment/tooling → `~/.claude/CLAUDE.md` (global) or `~/WARP.md` (reference)
- Directory-specific context → that directory's `CLAUDE.md`
- Global Claude preferences → this file

## Memory vs. Dotfiles: Where to Persist

Auto-memory (`~/.claude/projects/.../memory/`) is **machine-local and path-specific** — it does not sync across computers. The dotfiles repo (`dot` command) is the only persistence layer that transfers between machines. Before saving something to auto-memory, ask: **is this fundamental to how the user works, or is it specific to this machine/session?**

**Use auto-memory for:**
- Machine-specific setup details (local paths, installed versions, project-specific state)
- Ephemeral context useful for nearby future sessions but not universal
- References to external systems that may differ per environment

**Use dotfiles-tracked files instead when the learning is portable:**
- Workflow preferences, collaboration style, how to approach tasks → `~/.claude/CLAUDE.md`
- Agent behaviors and personalities → `~/.agents/<name>.md`
- Environment conventions and tool usage → `~/WARP.md`
- Directory-specific conventions → that directory's `CLAUDE.md`
- Skills and setup procedures → `~/.agents/skills/<name>/SKILL.md`

**The test:** If this preference or learning would apply on a completely different computer with the same dotfiles checked out, it belongs in a dotfile — not auto-memory. When in doubt, prefer dotfiles for durability.

## Writing Style

When writing or editing formal documents - policies, specs, proposals:
- No em dashes. Regular dashes are fine for context or asides.
- Never use two dashes in the same sentence. Break it into multiple sentences or use commas.
- No parentheses. Restructure the sentence or use dashes instead.
- Colons only for introducing lists, not as general punctuation.
- Bold for structural labels and headings only, not mid-sentence emphasis.
- Direct statements. No rhetorical questions.
- Keep it short. Prefer phrases over full sentences where the meaning is clear.
- Should read like a person wrote it, not like it was generated.

When presenting changes to a document, workshop one section at a time. Show current vs proposed, get feedback, then move on. Don't dump full rewrites.

## CLI Tools

Use these modern CLI tools across all projects:

- **eza** instead of `ls` - for listing files with colors/icons
- **fd** instead of `find` - for finding files (respects .gitignore)
- **rg** (ripgrep) instead of `grep` - for searching file contents (respects .gitignore)
- **bat** instead of `cat` - for viewing files with syntax highlighting
- **zoxide** (`z`) instead of `cd` - for smart directory navigation

Note: User has aliases for personal use (e.g., `l`, `ll`, `lt` for eza variants), but AI should use base commands with explicit flags (e.g., `eza -la` or `fd pattern`).

## Shell Environment

- Operating System: MacOS
- Shell: zsh 5.9
- Package Manager: pnpm (for Node.js global packages)

See `~/WARP.md` for detailed reference of user aliases and shell configuration.
