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

## Quick Reference

```bash
dot status          # Check dotfiles status
dot add <file>      # Stage a dotfile
dot commit -m "..." # Commit changes
dot push            # Push to remote
```

## Environment Reference

See `~/warp.md` for:
- Shell configuration (zshenv vs zshrc)
- Node.js global package management (pnpm vs npm)
- General development preferences

When learning new environment-specific information, update `~/warp.md` to keep knowledge centralized across AI tools.