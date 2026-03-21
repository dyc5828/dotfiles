# Home Directory Context

## Purpose of This File

This is the **directory-level** configuration for the home directory (`~`). It applies when Claude is launched from `~`. Use this for:
- Dotfiles management (the `dot` command)
- Home directory conventions
- References to environment config (`warp.md`)

For global Claude behavior that applies everywhere, see `~/.claude/CLAUDE.md`.

---

When working in the home directory or with dotfiles:

- Use `dot` instead of `git` for version control (bare repo at `~/.dotfiles/`)
- See `~/warp.md` for detailed dotfiles configuration and environment setup

## Agents & Skills

- `~/.agents/` is the source of truth for agents (flat `.md` files)
- `~/.skills/` is the source of truth for skills (`<name>/SKILL.md` layout)
- `~/.claude/agents` and `~/.claude/skills` are **directory symlinks** to the above
- To add a new agent: create `~/.agents/foo.md`
- To add a new skill: create `~/.skills/foo/SKILL.md`

## Quick Reference

```bash
dot status          # Check dotfiles status
dot add <file>      # Stage a dotfile
dot commit -m "..." # Commit changes
dot push            # Push to remote
```

## CLI Tools

Use these modern CLI tools (not the user's aliases):

- **eza** instead of `ls` - for listing files with colors/icons
- **fd** instead of `find` - for finding files (respects .gitignore)
- **rg** (ripgrep) instead of `grep` - for searching file contents (respects .gitignore)
- **bat** instead of `cat` - for viewing files with syntax highlighting
- **zoxide** (`z`) instead of `cd` - for smart directory navigation

Note: The user has aliases for personal use (e.g., `l`, `ll`, `lt` for eza variants), but AI should use the base commands directly (e.g., `eza -la` or `fd pattern`).

## Environment Reference

See `~/WARP.md` for:
- Complete list of CLI tools and user aliases
- Shell configuration (zshenv vs zshrc)
- Node.js global package management (pnpm vs npm)
- Git shortcuts and workflow
- General development preferences

When learning new environment-specific information, update `~/WARP.md` to keep knowledge centralized across AI tools.
