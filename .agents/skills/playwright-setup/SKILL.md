---
name: playwright-setup
description: Install and configure @playwright/mcp for browser-based verification in Claude Code. Sets up the MCP server, Chromium browser, and a persistent browser profile for reusable staging sessions. Use when setting up Playwright on a new machine or reconfiguring browser verification.
---

# Playwright MCP Setup

Set up `@playwright/mcp` for interactive browser verification in Claude Code. This gives you native browser automation tools (navigate, click, type, snapshot, screenshot) that work step-by-step — not scripted test suites.

## What this sets up

- **`@playwright/mcp`** — Microsoft's official Playwright MCP server (global npm install)
- **Chromium browser binary** — Playwright's bundled Chromium (not system Chrome)
- **Persistent browser profile** — dedicated directory that retains cookies/sessions between runs
- **MCP server in Claude Code** — so browser tools appear natively in the tool list

## Step 1: Install the package

Install `@playwright/mcp` globally. Use whichever package manager is available:

```bash
npm install -g @playwright/mcp@latest
```

Verify it installed:
```bash
npx @playwright/mcp --version
```

## Step 2: Install the Chromium browser binary

```bash
npx playwright install chromium
```

This downloads Playwright's bundled Chromium to `~/Library/Caches/ms-playwright/` (macOS) or `~/.cache/ms-playwright/` (Linux). It does NOT use or connect to any system browser.

Ignore the warning about "installing project dependencies first" — it works fine for global installs.

## Step 3: Create a persistent browser profile

Create a dedicated directory for the browser profile. This is what retains login sessions, cookies, and local storage between runs.

```bash
mkdir -p ~/.playwright-profile
```

This directory is passed to the MCP server via `--user-data-dir`. It is completely isolated from any personal Chrome profile.

## Step 4: Register the MCP server in Claude Code

Add the Playwright MCP server to `~/.claude.json` so Claude Code starts it automatically. The server config goes under the appropriate project key in the `projects` object.

Find the project entry matching your working directory (e.g., the home directory project) and add a `playwright` entry to its `mcpServers` object:

```json
"mcpServers": {
  "playwright": {
    "type": "stdio",
    "command": "npx",
    "args": ["-y", "@playwright/mcp", "--user-data-dir", "<ABSOLUTE_PATH_TO_PROFILE_DIR>"]
  }
}
```

Replace `<ABSOLUTE_PATH_TO_PROFILE_DIR>` with the absolute path to the profile directory created in Step 3 (e.g., `/Users/you/.playwright-profile`).

**Important**: Use an absolute path, not `~`. The MCP server process doesn't expand tildes.

### Adding to multiple projects

The MCP server config is per-project in `~/.claude.json`. To make it available when launching Claude Code from different directories, add the same `playwright` entry to each project's `mcpServers`. Alternatively, use the CLI:

```bash
claude mcp add --transport stdio --scope project playwright -- npx -y @playwright/mcp --user-data-dir /absolute/path/to/.playwright-profile
```

## Step 5: Restart Claude Code and verify

Restart Claude Code for the MCP server to initialize. Then verify by searching for the tools:

1. Use ToolSearch to look for `playwright browser` — you should see tools like `browser_navigate`, `browser_click`, `browser_snapshot`, etc.
2. Navigate to a test URL:
   ```
   mcp__playwright__browser_navigate → url: "https://example.com"
   ```
3. Confirm you see page content in the snapshot (title, headings, links).

## Key MCP server flags for future tuning

These can be added to the `args` array in the config:

| Flag | Effect |
|------|--------|
| `--headless` | Run without a visible browser window (default is headed) |
| `--caps vision` | Enable screenshot-based reasoning (adds token cost) |
| `--snapshot-mode incremental` | Only send accessibility tree diffs (default, token efficient) |
| `--snapshot-mode full` | Send complete accessibility tree each time |
| `--viewport-size 1280x720` | Set browser window dimensions |
| `--ignore-https-errors` | Useful for staging environments with self-signed certs |
| `--timeout-navigation 60000` | Navigation timeout in ms (default 60s) |

## How this is meant to be used

- **Intent-based verification**: Give Claude organic prompts like "log in to staging and check the dashboard" — not selectors or API calls
- **Step-by-step navigation**: Claude reads each page snapshot, decides what to click/type, reacts to what it sees
- **Session persistence**: Log in once, credentials persist in the profile directory across Claude Code restarts
- **Staging/dev only**: This is for verifying features on staging environments, not writing permanent test suites

## Troubleshooting

**"Browser not installed" error**: Run `npx playwright install chromium` again, or use the `mcp__playwright__browser_install` tool.

**MCP tools don't appear**: Check that the config is in the correct project entry in `~/.claude.json`, and that you've restarted Claude Code.

**Profile directory issues**: If sessions aren't persisting, verify the `--user-data-dir` path is absolute and the directory exists. Check that the directory has a `Default/` subdirectory after first use.

**Headed mode not showing window**: On remote/SSH sessions, headed mode won't work. Add `--headless` to the args.
