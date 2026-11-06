---
name: mcps
description: Show MCP server status with problems sorted to the top and disabled servers hidden. Use when the user runs /mcps or asks "check my MCPs", "what MCPs do we have", "which MCPs need auth", "MCP status", or "list MCP servers".
effort: low
argument-hint: [all]
allowed-tools: Bash(claude mcp list*)
---

# MCP Status

`/mcp` is a built-in command and can't be changed. This skill is the readable version: problems first, disabled servers hidden.

## Arguments

- **Empty** → hide disabled servers, show only a count
- **`all`** → also list disabled servers at the bottom

## Steps

1. Run `claude mcp list` with a 120s timeout. It health-checks every server, so it takes a while.

2. Put each server in one bucket:
   - **Disabled**: status starts with `⊘ Disabled`.
   - **Needs attention**: any status other than `Connected` or `Disabled`, e.g. failed to connect or needs authentication.
   - **Needs auth (session)**: the CLI says `Connected`, but in this session the server's only tools are `authenticate` and `complete_authentication`. The CLI health check misses this case. Look at the tools this session can see, including the deferred tool list. Tool prefixes come from the display name with non-alphanumerics turned into `_`, so `claude.ai Google Drive` becomes `mcp__claude_ai_Google_Drive__`.
   - **Connected**: everything else.

3. Output one table. Needs attention and Needs auth rows go first, then Connected. Sort alphabetically within each group. Drop the `claude.ai ` prefix from names.

   | Server | Status | Fix |
   |---|---|---|
   | Sentry | Needs auth | `/mcp` → Sentry → Authenticate |
   | Amplitude | Connected | |

   Fixes:
   - Needs auth → `/mcp` → server → Authenticate
   - Failed to connect → `/mcp` → server → Reconnect. For a local server like playwright, check the command in the CLI output.

4. End with one line: `N disabled servers hidden. Run /mcps all to list them.`
   With `all`, list the disabled servers alphabetically on one line below the table and note they can be re-enabled via `/mcp`.

Keep the summary above the table to one line, e.g. `30 connected, 2 need attention, 30 disabled (hidden).` Write nothing else.
