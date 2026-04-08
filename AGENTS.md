# Home Directory Context

Directory-level configuration for the home directory (`~`). Applies to AI agents launched from this directory.

- Dotfiles management (the `dot` command)
- Home directory conventions
- References to environment config (`WARP.md`)

---

When working in the home directory or with dotfiles:

- Use `dot` instead of `git` for version control (bare repo at `~/.dotfiles/`)
- See `~/WARP.md` for detailed dotfiles configuration and environment setup

## Agents & Skills (directory layout)

`~/.agents/` follows the `.agents/` folder spec pattern:
- `delegates/` - subagent `.md` files
- `skills/` - skill directories with `SKILL.md`

For dotfiles tracking, stage `.agents/` content with `dot`.

## Quick Reference

```bash
dot status          # Check dotfiles status
dot add <file>      # Stage a dotfile
dot commit -m "..." # Commit changes
dot push            # Push to remote
```

## Environment Reference

See `~/WARP.md` for CLI tools, shell configuration, aliases, and development preferences.
