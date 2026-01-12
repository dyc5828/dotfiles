---
name: close-session
description: Wraps up a coding session by creating documentation and committing artifacts. Use when the user says "wrap up", "close session", "let's finish", or similar end-of-session language.
---

# Close Session

Wraps up a coding session by documenting work and committing artifacts.

## Steps

1. Invoke the SUMA agent to create session documentation
2. Stage session artifacts (SESSIONS/ or SESSIONS.md)
3. Commit with message: `docs: add session log for [date]`
4. Ask user if they want to push to remote

## Git Commands

First check if in a git repo:
```bash
git rev-parse --git-dir 2>/dev/null
```

If not a git repo, skip git operations and inform user.

If in a git repo:
```bash
git add SESSIONS/ SESSIONS.md 2>/dev/null
git commit -m "docs: add session log for $(date +%Y-%m-%d)"
```

If commit fails (nothing to commit), inform user session was documented but no git changes needed.

If user confirms push:
```bash
git push
```

If push fails, report the error to user.
