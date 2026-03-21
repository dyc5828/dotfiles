---
name: recent
description: Display recent Claude Code sessions in a formatted table. Use when the user wants to see their recent session history, recently worked on conversations, or wants to find a session to resume.
model: claude-sonnet-4-6
effort: low
argument-hint: [count]
allowed-tools: Read, Grep, Bash(date *)
---

# Recent Sessions

Display recent Claude Code sessions as a formatted plain-text table by reading `~/.claude/history.jsonl`.

## Arguments

- `$ARGUMENTS` — optional number of sessions to show (default: 5, max: 30)
- If `$ARGUMENTS` is not a valid number or exceeds 30, default to 5

## Data Source

`~/.claude/history.jsonl` — one JSON object per line, one line per user message:

```json
{
  "display": "first ~80 chars of user message",
  "timestamp": 1773869038434,
  "project": "/Users/dan.chen@homebot.ai/code/homebot/customer-admin",
  "sessionId": "a14a20fb-fb95-4861-aa97-a162623641ce",
  "pastedContents": {}
}
```

## Steps

1. **Get line count** using Grep:
   `Grep(pattern: ".", path: "~/.claude/history.jsonl", output_mode: "count")`

2. **Read the tail** using Read with an offset. Start conservatively:
   - 1-5 sessions → ~50 lines
   - 6-10 sessions → ~100 lines
   - 11-20 sessions → ~200 lines
   - 21-30 sessions → ~300 lines

3. **Parse and group**: Scan bottom-up. Group entries by `sessionId`, preserving the order each session is first encountered (most recent first). Stop once you have enough unique sessions.

4. **Check sufficiency**: If fewer unique sessions than requested, double the read window and read the expanded portion (new offset up to where the previous read started). Merge with what you already have. Repeat until satisfied or the file is exhausted.

5. **Convert timestamps** in a single Bash call (must match `Bash(date *)` pattern):
   ```
   date +%s && date -r TS1 '+%b %d, %H:%M' && date -r TS2 '+%b %d, %H:%M' && ...
   ```
   Divide millisecond timestamps by 1000 (truncate). This gets current epoch + all human-readable dates in one call.

6. **Synthesize topics**: For each session, write a short topic label (~8 words max). Use ALL messages you've seen for that session — everything in your context — to infer the gist.

7. **Format output** as the table below, using the last 2-3 `display` strings per session for the LAST MESSAGES column. Output the table directly — do NOT wrap it in triple backticks or a code fence.

## Output Format

Plain-text padded table. No markdown formatting.

### Columns

1. **SESSIONS** — lines 1-2: synthesized topic; last line: full session UUID (for `claude --resume <id>`)
2. **TIME** — line 1: absolute (`Mar 18, 21:23`); line 2: relative (see below). Pad minimally — just enough for the widest value in the column.
3. **PROJECT** — line 1: folder name (last path segment); line 2: full path with `~` for home dir, prefixed with `└ ` to visually subordinate it
4. **LAST MESSAGES** — last 2-3 `display` strings, verbatim, prefixed with `>`

### Relative Time

- Within last hour: `Xm ago`
- Within today: `Xh ago`
- Yesterday: `yesterday`
- Older: short date (`Mar 15`)

### Table Structure

- `│` column dividers, `─` row dividers, `┼` intersections
- Header row + separator, then rows separated by dividers
- Pad each column to its widest content so all dividers align

### Example

SESSIONS                                   │ TIME              │ PROJECT                       │ LAST MESSAGES
───────────────────────────────────────────┼───────────────────┼───────────────────────────────┼─────────────────────────────────────────────────
Workshopping a /recent CLI skill for       │ Mar 18, 21:23     │ customer-admin                │ > I just updated permissions so you can try
non-interactive session history viewing    │ 3h ago            │ ~/code/homebot/customer-admin │   to run it again.
a14a20fb-fb95-4861-aa97-a162623641ce       │                   │                               │ > I forgot to paste it in, and I just did,
                                           │                   │                               │   so now you can see what it actually has.
───────────────────────────────────────────┼───────────────────┼───────────────────────────────┼─────────────────────────────────────────────────
Refining resume cover letter language and   │ Mar 18, 19:02     │ homebot                       │ > I gotta sort it out, thanks.
trimming down the accomplishments section  │ 5h ago            │ ~/code/homebot                │ > I think in an older version, in the cover
c9ee6fdc-f7b7-4a99-b428-809c728945c2       │                   │                               │   section, you talk a little bit more about...
───────────────────────────────────────────┼───────────────────┼───────────────────────────────┼─────────────────────────────────────────────────
Creating Linear ticket for RD CEX project  │ Mar 17, 14:30     │ homebot                       │ > make a linear ticket for me in rd cex
4ea7bad4-9153-4b2e-8f1a-2c3d4e5f6a7b       │ yesterday         │ ~/code/homebot                │   project for this https://...
───────────────────────────────────────────┼───────────────────┼───────────────────────────────┼─────────────────────────────────────────────────

## Rules

- Plain text only — never wrap output in triple backticks or code fences, no markdown tables, no bold/italic
- Replace the user's home directory with `~` in project paths
- Topics must be synthesized summaries, not copies of a single message
- Last messages are verbatim from `display`, trimmed for width
