---
name: close-session
description: Wraps up a coding session by creating documentation and committing artifacts. Use when the user says "wrap up", "close session", "let's finish", or similar end-of-session language.
---

# Close Session

Wraps up a coding session by documenting work and committing artifacts.

## Steps

1. Get the current date/time via Bash: `date "+%Y-%m-%d %H:%M"`
2. Preprocess session into raw material (see below)
3. Invoke SUMA with date/time + raw material
4. Stage session artifacts (SESSIONS/ or SESSIONS.md)
5. Commit with message: `docs: add session log for [date]`
6. Ask user if they want to push to remote

## Invoking SUMA

SUMA does NOT have access to conversation context - you must pass it in.

### Preprocessing (your job)

Extract raw facts from the session. Be thorough but don't synthesize - that's SUMA's job.

Capture:
- **Files touched:** created, modified, deleted (with paths)
- **Topics discussed:** what questions came up, what was debated
- **Options considered:** alternatives that were weighed
- **Problems encountered:** errors, blockers, things that didn't work
- **Commands/tools used:** significant actions taken

Keep it factual and raw. Don't editorialize or conclude.

### SUMA's job

SUMA takes your raw material and:
- Extracts the *reasoning* behind decisions
- Identifies patterns and learnings
- Determines what matters for future sessions
- Formats the final documentation

### Prompt template

```
Current date/time: [date from step 1]

## Raw Session Material

### Files Touched
- [list files with what happened to each]

### Topics Discussed
- [list key topics/questions]

### Options Considered
- [list alternatives that were weighed]

### Problems Encountered
- [list issues, errors, blockers]

### Significant Actions
- [list key commands, commits, etc.]

---

Analyze this material. Extract decisions, reasoning, and learnings. Create session documentation.
```

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
