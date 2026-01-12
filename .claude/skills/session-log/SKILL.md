---
name: session-log
description: Formats and writes session documentation to the appropriate location. Use when creating session logs or documentation entries.
---

# Session Log

Formats and writes session documentation.

## Storage Location

1. Use existing `SESSIONS/` directory if present
2. Otherwise use `SESSIONS.md` or `sessions.md` if present (prepend entry)
3. Otherwise create `SESSIONS/` directory

## File Naming

For `SESSIONS/` directory: `YYYY-MM-DD_HH-MM-SS.md`

Get actual current time via: `date +%Y-%m-%d_%H-%M-%S`

## Entry Format

```markdown
## Session: [Date] [Time]

### Summary
[2-3 sentence overview]

### Key Actions
- [Action with file/component names]

### Decisions & Reasoning
- **Decision:** [What]
  - **Reasoning:** [Why]
  - **Alternatives:** [If any]

### Technical Details
[Implementation notes, patterns used]

### Open Items
- [ ] [Incomplete work]
- [ ] [Known issues]

### Session Context
- **Files Modified:** [list]
- **Related Issues/PRs:** [if any]
- **Blockers:** [if any]
```

## Rules

- Prepend to SESSIONS.md (most recent first)
- Match existing format when appending to existing file
- Use project timezone if apparent, otherwise UTC
