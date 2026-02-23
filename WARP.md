# Warp AI Configuration

This file contains home directory-level rules and preferences for Warp AI Agent Mode.

**Note**: For user-level configuration that applies everywhere (like CLI tool preferences), see `~/.claude/CLAUDE.md`. This file should focus on home directory-specific context.

## Meta Instructions

- **Document as you learn**: When discovering useful information, update the appropriate file:
  - User-level (global) preferences → `~/.claude/CLAUDE.md`
  - Home directory context → `~/WARP.md` or `~/CLAUDE.md`
  - Project-specific → that project's WARP.md or CLAUDE.md
- **Sync to Warp UI rules**: When adding significant preferences or tool choices, suggest corresponding Warp UI rules for the user to add. These rules sync across all Warp instances and should be concise, actionable directives.
- Keep documentation organic and focused on real usage patterns, not exhaustive environment dumps
- Prioritize information that helps avoid repeating solved problems

## Command Preferences

**Always use these modern tools when suggesting commands:**

- `rg` (ripgrep) instead of `grep` - for searching file contents
- `fd` instead of `find` - for finding files
- `eza` instead of `ls` - for listing files
- `bat` instead of `cat` - for viewing files
- `z` (zoxide) instead of `cd` - for directory navigation

Use base commands with explicit flags (e.g., `rg pattern`, `fd filename`, `eza -la`), not user aliases.

## Home Directory Specific

### Dotfiles Management

- **Use `dot` command** instead of `git` for version control in home directory
- Configured as a bare repository at `~/.dotfiles/` with work-tree at `~`
- Remote tracking refs configured with: `dot config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'`
- This enables `dot status` to show ahead/behind info and `dot rev-parse origin/main` to work

**Quick Commands:**
```bash
dot status          # Check dotfiles status
dot add <file>      # Stage a dotfile
dot commit -m "..." # Commit changes
dot push            # Push to remote
```

### Shell Configuration

- `~/.zshenv` - Environment variables and PATH (all shells, including non-interactive)
- `~/.zshrc` - Aliases, prompt, interactive features (interactive shells only)

### Node.js Global Packages

Using pnpm for global CLI tools avoids reinstalling when switching Node versions (nvm/fnm/asdf):

- npm globals install to active Node version directory (e.g., `~/.nvm/versions/node/v24/...`)
- pnpm globals install to `~/.local/share/pnpm` (Node-version-independent)
- Executables use `#!/usr/bin/env node`, so they run with whatever Node is active
- Requires `PNPM_HOME` in PATH (configured in `~/.zshenv`)

```bash
# Check if pnpm globals are properly configured
command -v pnpm && echo "$PATH" | tr ':' '\n' | grep -q "$(pnpm bin -g)" && echo "OK"
```

## Development Preferences

### Homebot Development

- `hbdev` - homebot dev CLI at `~/code/homebot/hbdev/bin/hbdev`
- `hdev` - docker-compose for hbdev
- `av` - aws-vault (credential management)
- `dc` - docker-compose

---

## Appendix: User Aliases & Reference

**Note for AI**: This section is reference material for the user. Global CLI tool preferences are in `~/.claude/CLAUDE.md`.

### Modern CLI Tools

The user has these modern tools installed with personal aliases:

#### File Listing
- **eza** (replaces `ls`) - Modern replacement with colors, icons, git integration
  - `e` - basic eza
  - `le` - eza with icons
  - `l` - all files with icons (`eza --icons -a`)
  - `ll` - detailed list (`l -l`)
  - `lt` - tree view (`l --tree`)

#### File Searching
- **fd** (replaces `find`) - Fast, user-friendly alternative to find
  - Usage: `fd <pattern>` - respects .gitignore by default
  - Use `fd` instead of `find` for file/directory searches

#### Content Searching  
- **rg/ripgrep** (replaces `grep`) - Extremely fast recursive search
  - Respects .gitignore, colors output, recursive by default
  - Use `rg <pattern>` instead of `grep -r`
  - Rule: Always use `rg` for: searching, finding text/patterns, matching strings, grepping content, text search in files/codebases

#### File Viewing
- **bat** (replaces `cat`) - Cat with syntax highlighting and line numbers
  - `cat` aliased to `bat --paging=never`
  - Automatic syntax highlighting for code
  - `-h` and `--help` flags auto-pipe to bat

#### Diff Viewing
- **riff** (replaces `diff`) - Better diff visualization
  - `diff` aliased to `riff`

#### Directory Navigation
- **zoxide** (replaces `cd`) - Smart directory jumper
  - `z <partial-path>` - jump to frequently used directories
  - `~` aliased to `z ` (jump to home-like paths)
  - `..` aliased to `z ..`
  - `...` aliased to `z ../..`

### Git Shortcuts

Comprehensive git aliases (use `g` prefix):

**Status & Info:**
- `g` / `gs` - git status
- `gl` - git log
- `gbl` - branch list
- `glsf` - list tracked files

**Adding & Committing:**
- `ga` - add files
- `gaa` - add all
- `gc` / `gcm "msg"` - commit / commit with message
- `gca` - amend last commit

**Branching:**
- `gb` - branch
- `gbd` - delete branch  
- `gco` - checkout
- `gsw` - switch
- `gsw_origin <branch>` - create and switch to branch from origin
- `gsw_pr <num>` - checkout PR by number to new branch

**Diffing:**
- `gd` - diff working directory
- `gdc` - diff with compact summary
- `gds` - diff staged changes

**Syncing:**
- `gph` - push
- `gpl` - pull
- `gplr` - pull with rebase
- `gplm` - pull without rebase
- `gplf` - pull fast-forward only

**Stashing:**
- `gsh` - stash changes
- `gshl` - list stashes
- `gshp` - pop stash
- `gsha <n>` - apply stash@{n}
- `gshd <n>` - drop stash@{n}
- `gsh_unstaged` - stash only unstaged changes

**Resetting:**
- `gr` - reset
- `grs` - soft reset
- `grh` - hard reset
- `gr_head <n>` - reset to HEAD~n (default 1)

**Skip Worktree (ignore local changes):**
- `g_skip <file>` - mark file to skip
- `g_unskip <file>` - unmark file
- `gls_skipped` - list skipped files

**Other:**
- `gcp` - cherry-pick
- `glsr_tags [remote]` - list remote tags

### Dotfiles Management

- Use **`dot`** command (not `git`) for dotfiles in home directory
- Bare repo at `~/.dotfiles/` with work-tree at `~`
- Examples: `dot status`, `dot add .zshrc`, `dot commit -m "msg"`

### Development Tools

**Homebot:**
- `hbdev` - homebot dev CLI
- `hdev` - docker-compose for hbdev
- `av` - aws-vault
- `dc` - docker-compose

**Package Managers:**
- `pn` - pnpm shortcut

**Process & Port Management:**
- `ls_port <port>` - list processes on port
- `ps_find <name>` - search running processes
- `kill_port <port>` - kill process on port

**Other:**
- `lg` - lazygit (terminal UI for git)
- `fabric` - fabric-ai (aliased from fabric-ai)
- `b` - bkup
- `n` - nano editor
- `c` - clear terminal
- `sim` - open iOS Simulator
- `dateutc` - ISO 8601 UTC timestamp

### Shell Functions

- `reload` - reload all shell configs (.zprofile, .zshenv, .zshrc)
- `count_files [pattern] [dir]` - count files matching pattern in directory

### Quick Reference: Traditional → Modern

| Traditional | Modern Alternative | Alias/Command |
|------------|-------------------|---------------|
| `ls` | eza | `l`, `ll`, `lt` |
| `cat` | bat | `cat` (aliased) |
| `cd` | zoxide | `z`, `~` |
| `find` | fd | `fd` |
| `grep` | ripgrep | `rg` |
| `diff` | riff | `diff` (aliased) |
| `git` | - | `g` + shortcuts |
