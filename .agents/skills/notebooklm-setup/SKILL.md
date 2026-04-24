---
name: notebooklm-setup
description: Install and configure the notebooklm-py CLI for programmatic NotebookLM access, including browser-based Google auth and optional audio transcription tooling (ffmpeg + whisper). Use when setting up NotebookLM on a new machine, re-authenticating after a session expires, or enabling local transcription of generated audio overviews.
---

# NotebookLM CLI Setup

Install and authenticate `notebooklm-py` — the unofficial Python CLI that wraps Google NotebookLM's undocumented APIs. After this setup, the `notebooklm` skill takes over for day-to-day use (create notebooks, add sources, generate audio/video/quiz artifacts).

## What this sets up

- **`notebooklm-py[browser]`** — CLI + Playwright-based browser login support
- **Chromium browser binary** — for the one-time Google OAuth flow
- **Persistent auth state** — `~/.notebooklm/storage_state.json` holds the session cookies
- **Optional: `ffmpeg` + `openai-whisper`** — for local transcription of generated audio overviews so Claude can read and synthesize against them

The companion `notebooklm` skill is typically already present in `~/.agents/skills/notebooklm/` (tracked via the `notebooklm skill install` bundled inside the CLI, though in this dotfiles setup it's just a resident directory). No action needed on the skill itself — this setup skill is purely for the CLI + auth.

## Step 1: Upgrade pip

Not strictly required, but pip 25.x has had install quirks with some transitive deps. Upgrade first:

```bash
pip install --upgrade pip
```

## Step 2: Install the CLI with browser support

The `[browser]` extra pulls in Playwright so `notebooklm login` can drive Chromium for the Google OAuth flow.

```bash
pip install "notebooklm-py[browser]"
```

Verify:
```bash
notebooklm --version
```

## Step 3: Install Chromium

```bash
playwright install chromium
```

Downloads to `~/Library/Caches/ms-playwright/` (macOS) or `~/.cache/ms-playwright/` (Linux). Only used once for the login flow.

If it fails with `TypeError: onExit is not a function`, see the Linux workaround in the notebooklm-py troubleshooting docs.

## Step 4: Authenticate

```bash
notebooklm login
```

This opens a Chromium window with a persistent profile at `~/.notebooklm/browser_profile`. Complete the Google login in the browser, wait for the NotebookLM homepage to load, then press ENTER in the terminal to save and close.

### Known issue: first attempt can fail with `TargetClosedError`

On some machines the first `notebooklm login` invocation crashes with:

```
playwright._impl._errors.TargetClosedError: Page.goto: Target page, context or browser has been closed
```

**Just re-run `notebooklm login`.** The second attempt typically succeeds because the persistent profile directory now exists from the failed first run. If it fails three times in a row, delete `~/.notebooklm/browser_profile/` and retry.

On success you'll see:
```
Authentication saved to: /Users/you/.notebooklm/storage_state.json
```

## Step 5: Verify

```bash
notebooklm status
notebooklm list
```

`status` should show "Authenticated as: your-email@...". `list` should return your notebooks (or an empty table if you have none).

If either fails with auth errors, run `notebooklm auth check --test` to diagnose, then re-run `notebooklm login` if needed.

## Step 6 (optional): Transcription tooling

Install this only if you want Claude to transcribe generated audio overviews and feed them back into synthesis. Without it, Claude can start audio generations and download MP3s but can't read their contents.

```bash
brew install ffmpeg
pip install openai-whisper
```

- `ffmpeg` is required — `openai-whisper` shells out to it to decode MP3 into the 16kHz WAV format the model expects. Whisper alone cannot read MP3.
- First `whisper` run downloads the chosen model (~140 MB for `base`, ~1.5 GB for `large`) to `~/.cache/whisper/`.

### Typical transcribe command

```bash
whisper ~/Downloads/some-audio.mp3 --model base --output_format txt --output_dir /tmp/transcripts
```

Runtime on Apple Silicon with `base` model: roughly one-third realtime (a 30-min podcast → ~9-10 min). Use `--model tiny` for faster/rougher; `--model small` or `--model medium` for better accuracy at the cost of time.

## Multiple accounts

`notebooklm-py` 0.3.4 does not have a `profile` subcommand. For multiple Google accounts, use one of these:

**Per-command `--storage` flag:**
```bash
notebooklm --storage ~/.notebooklm/work.json login
notebooklm --storage ~/.notebooklm/work.json list
```

**Per-shell `NOTEBOOKLM_HOME` env var** (completely separate home dir, including browser profile):
```bash
export NOTEBOOKLM_HOME=~/.notebooklm-work
notebooklm login
notebooklm list
```

Default single-account layout:
- `~/.notebooklm/storage_state.json` — auth cookies
- `~/.notebooklm/browser_profile/` — Playwright persistent profile

## Troubleshooting

| Symptom | Action |
|---|---|
| `notebooklm login` crashes with `TargetClosedError` | Re-run. Delete `~/.notebooklm/browser_profile/` if it fails 3x in a row. |
| `notebooklm list` returns auth error | `notebooklm auth check --test` to diagnose, then `notebooklm login` |
| `whisper` fails with "ffmpeg not found" | `brew install ffmpeg` |
| Command "killed" after `brew install` | Check `com.apple.quarantine` xattr (see `fix-quarantined-cli` skill) |
| `playwright install chromium` hangs or fails | Check corporate proxy/VPN; retry on personal network |

## Next steps

Once authenticated, use the `notebooklm` skill for day-to-day operations — creating notebooks, adding sources (URLs, YouTube, PDFs), generating audio/video/quiz/mind-map artifacts, and downloading results. That skill is already available whenever the CLI is installed.
