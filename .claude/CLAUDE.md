# User Preferences

Global preferences for Claude behavior across all projects.

## Purpose of This File

This is the **user-level** configuration. It applies to every Claude session regardless of which directory you're in. Use this for:
- Cross-project behavior preferences
- Global tool configurations
- Self-learning protocols

For directory-specific context (like dotfiles, project conventions), use a CLAUDE.md in that directory.

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
- Environment/tooling → `~/warp.md`
- Directory-specific context → that directory's `CLAUDE.md`
- Global Claude preferences → this file

<!-- Add user-level Claude preferences here as they emerge -->
