---
name: recent
description: Display recent Claude Code sessions in a formatted table. Use when the user wants to see their recent session history, recently worked on conversations, or wants to find a session to resume.
model: claude-sonnet-4-6
effort: low
argument-hint: [count | search query]
allowed-tools: Read, Grep, Bash(date *)
---

# Recent Sessions

Display recent Claude Code sessions as a formatted plain-text table by reading `~/.claude/history.jsonl`.

## Arguments

- `$ARGUMENTS` — one of:
  - **Empty** — show 5 most recent sessions
  - **A number** — show that many recent sessions (max: 30; invalid numbers default to 5)
  - **Text (words/phrases)** — search mode: find sessions matching the query

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

## Mode Detection

Determine the mode from `$ARGUMENTS`:
- **Empty or blank** → list mode, count = 5
- **Purely numeric** (e.g. `10`) → list mode, count = that number (max 30)
- **Anything else** (contains non-numeric characters) → **search mode**, query = `$ARGUMENTS`

## Steps — List Mode

1. **Get line count** using Grep:
   `Grep(pattern: ".", path: "~/.claude/history.jsonl", output_mode: "count")`

2. **Read the tail** using Read with an offset. Start conservatively:
   - 1-5 sessions → ~50 lines
   - 6-10 sessions → ~100 lines
   - 11-20 sessions → ~200 lines
   - 21-30 sessions → ~300 lines

3. **Parse and group**: Scan bottom-up. Group entries by `sessionId`, preserving the order each session is first encountered (most recent first). Stop once you have enough unique sessions.

4. **Check sufficiency**: If fewer unique sessions than requested, double the read window and read the expanded portion (new offset up to where the previous read started). Merge with what you already have. Repeat until satisfied or the file is exhausted.

5. Continue to **Common Steps** below.

## Steps — Search Mode

1. **Get line count** using Grep:
   `Grep(pattern: ".", path: "~/.claude/history.jsonl", output_mode: "count")`

2. **Search for matches** using Grep with a case-insensitive pattern against the history file:
   `Grep(pattern: "<query>", path: "~/.claude/history.jsonl", output_mode: "content", -i: true)`
   This finds lines where the `display` text or `project` path contains the search terms.
   - If the query has multiple words, search for the full phrase first.
   - If no results, try each word separately and intersect by sessionId (sessions that match ALL words across any of their messages).

3. **Parse and group**: From matched lines, extract the JSON objects. Group by `sessionId`, ordered by most recent match first. Cap at 10 results.

4. **Expand context**: For each matched sessionId, Read additional lines from the file to gather all messages for that session (for topic synthesis and LAST MESSAGES). Use Grep to find all entries for each sessionId:
   `Grep(pattern: "<sessionId>", path: "~/.claude/history.jsonl", output_mode: "content")`
   Batch multiple sessionIds into a single Grep using alternation: `id1|id2|id3`.

5. Continue to **Common Steps** below.

## Common Steps

These apply to both list and search mode after sessions have been collected.

1. **Convert timestamps** in a single Bash call (must match `Bash(date *)` pattern):
   ```
   date +%s && date -r TS1 '+%b %d, %H:%M' && date -r TS2 '+%b %d, %H:%M' && ...
   ```
   Divide millisecond timestamps by 1000 (truncate). This gets current epoch + all human-readable dates in one call.

2. **Synthesize topics**: Write a concise topic label for each session. Use ALL messages you've seen for that session to infer the gist. Keep it short and descriptive — longer than a few words is fine, but never a full sentence or rambling phrase.

3. **Compute column widths** (internal only — do NOT output these to the user): Calculate the exact character width of every cell across every line of every row. A multi-line row (topic line 1, topic line 2, UUID line) contributes one width per line — the column width is the max across ALL lines of ALL rows, including the header label itself.

4. **Build the table string**: Construct the full table using the computed widths. Every content cell must be right-padded with spaces to its column width. Every `─` divider segment for columns 1-3 must be exactly its column-width characters. The LAST MESSAGES column (col 4) `─` segment width = the width of the widest col 4 content across all rows (including the header label). No wider. Verify alignment by checking that every `│` and `┼` character falls at the same horizontal position across all lines. Output the table directly — do NOT wrap it in triple backticks or a code fence. Use the last 2-3 `display` strings per session for the LAST MESSAGES column.

5. **Search mode header**: In search mode, print a one-line header before the table:
   `Found N sessions matching "query":`
   If no sessions matched, print `No sessions found matching "query".` and stop.

## Output Format

Plain-text padded table. No markdown formatting.

### Columns

1. **SESSIONS** — lines 1-2: synthesized topic; last line: session UUID prefixed with `▸ ` to visually distinguish it (for `claude --resume <id>`)
2. **TIME** — line 1: absolute (`Mar 18, 21:23`); line 2: relative (see below)
3. **PROJECT** — line 1: folder name (last path segment); line 2: full path with `~` for home dir, prefixed with `└ `. For the home directory itself, line 1 is `(home)`.
4. **LAST MESSAGES** — last 2-3 `display` strings, verbatim, prefixed with `>`

### Relative Time

- Within last hour: `Xm ago`
- Within today: `Xh ago`
- Yesterday: `yesterday`
- Older: short date (`Mar 15`)

### Table Structure

- `│` column dividers, `─` row dividers, `┼` intersections
- Header row + separator, then rows separated by dividers
- Every `│` must appear at the exact same column position on every line of the table
- Every `─` separator line must be the exact same total width as every content line
- For multi-line rows: pad shorter content lines with spaces to the full column width — do not leave them short

### Example

SESSIONS                                  │ TIME          │ PROJECT                         │ LAST MESSAGES
──────────────────────────────────────────┼───────────────┼─────────────────────────────────┼──────────────────────────────────────
Workshopping the /recent CLI skill        │ Mar 18, 21:23 │ customer-admin                  │ > I just updated permissions so you
for session history viewing               │ 3h ago        │ └ ~/code/homebot/customer-admin │   can try to run it again.
▸ a14a20fb-fb95-4861-aa97-a162623641ce    │               │                                 │ > I forgot to paste it in, and I just
──────────────────────────────────────────┼───────────────┼─────────────────────────────────┼──────────────────────────────────────
Refining resume cover letter and          │ Mar 18, 19:02 │ homebot                         │ > I gotta sort it out, thanks.
trimming accomplishments section          │ 5h ago        │ └ ~/code/homebot                │ > I think in an older version, in the
▸ c9ee6fdc-f7b7-4a99-b428-809c728945c2    │               │                                 │   cover section, you talk a little...
──────────────────────────────────────────┼───────────────┼─────────────────────────────────┼──────────────────────────────────────
Creating Linear ticket for RD CEX project │ Mar 17, 14:30 │ homebot                         │ > make a linear ticket for me in rd
▸ 4ea7bad4-9153-4b2e-8f1a-2c3d4e5f6a7b    │ yesterday     │ └ ~/code/homebot                │   cex project for this https://...
──────────────────────────────────────────┼───────────────┼─────────────────────────────────┼──────────────────────────────────────

## Rules

- Plain text only — never wrap output in triple backticks or code fences, no markdown tables, no bold/italic
- Replace the user's home directory with `~` in project paths
- Topics must be synthesized summaries, not copies of a single message
- Last messages are verbatim from `display`, trimmed for width
- Session UUID line is always prefixed with `▸ ` to make it visually scannable
