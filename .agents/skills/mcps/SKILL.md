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

- **Empty** → table of servers that need fixing, connected servers as a comma list, disabled as a count only
- **`all`** → table of every enabled server, disabled servers as a comma list

## Steps

1. Run `claude mcp list` with a 120s timeout. It health-checks every server, so it takes a while.

2. Put each server in one bucket:
   - **Disabled**: status starts with `⊘ Disabled`.
   - **Attention**: any status other than `Connected` or `Disabled`, e.g. failed to connect or needs authentication.
   - **Needs auth (session)**: the CLI says `Connected`, but in this session the server's only tools are `authenticate` and `complete_authentication`. The CLI health check misses this case. Look at the tools this session can see, including the deferred tool list. Tool prefixes come from the display name with non-alphanumerics turned into `_`, so `claude.ai Google Drive` becomes `mcp__claude_ai_Google_Drive__`.
   - **Connected**: everything else.

3. Drop the `claude.ai ` prefix from names. Sort alphabetically within each group.

4. Output, in this order:
   - One summary line, e.g. `30 connected, 2 attention, 30 disabled.`
   - The table, using the rules below for each mode.
   - The connected or disabled list for that mode.

### Default

Table holds only Attention and Needs auth rows. Omit the table when nothing needs fixing.

| Server | Status | Fix |
|---|---|---|
| Sentry | Needs auth | `/mcp` → Sentry → Authenticate |

Then these two lines as plain text:

**Connected (30):** Amplitude, Braintrust, CircleCI, ...
30 disabled servers hidden. Run /mcps all to list them.

### `all`

Table holds every enabled server: Attention and Needs auth rows first, then Connected rows with an empty Fix.

| Server | Status | Fix |
|---|---|---|
| Sentry | Needs auth | `/mcp` → Sentry → Authenticate |
| Amplitude | Connected | |

Then this line as plain text:

**Disabled (30):** Asana, Ashby, Astronomer, ... Re-enable via `/mcp`.

### Fixes

- Needs auth → `/mcp` → server → Authenticate
- Failed to connect → `/mcp` → server → Reconnect. For a local server like playwright, check the command in the CLI output.

Write nothing else.
