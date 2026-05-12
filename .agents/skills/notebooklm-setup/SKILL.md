---
name: notebooklm-setup
description: Install, upgrade, and configure the notebooklm-py CLI for programmatic NotebookLM access, including browser-based Google auth and optional audio transcription tooling (ffmpeg + whisper). Use when setting up NotebookLM on a new machine, upgrading the CLI to a newer release (and refreshing the dotfile-shipped skill alongside it), re-authenticating after a session expires, or enabling local transcription of generated audio overviews.
---

# NotebookLM CLI Setup

Install, upgrade, or re-authenticate `notebooklm-py` — the unofficial Python CLI that wraps Google NotebookLM's undocumented APIs. After this setup, the `notebooklm` skill takes over for day-to-day use (create notebooks, add sources, generate audio/video/quiz artifacts).

**The same steps cover both fresh install and upgrade.** Step 2 uses `pip install --upgrade`, which installs if missing and upgrades if present. Step 6 (drift check) is most critical on upgrade: JSON output shapes and command surfaces can change between releases, so the dotfile-shipped `notebooklm` SKILL.md must be refreshed in lockstep with CLI version bumps. It's also worth running on fresh installs to catch any drift between your dotfiles snapshot and the latest release.

## What this sets up

- **`notebooklm-py[browser]`** — CLI + Playwright-based browser login support
- **Chromium browser binary** — for the one-time Google OAuth flow
- **Persistent auth state** — `~/.notebooklm/storage_state.json` holds the session cookies
- **Optional: `ffmpeg` + `openai-whisper`** — for local transcription of generated audio overviews so Claude can read and synthesize against them

The companion `notebooklm` skill should already be at `~/.agents/skills/notebooklm/SKILL.md` — shipped via dotfiles. (Upstream's standard install pattern is `notebooklm skill install` from the CLI, but we ship it via dotfiles so it travels with the rest of the agent config. Updates flow via the GitHub source, not via the CLI — see Step 6 below.)

> ⚠️ **Do not run `notebooklm skill install`.** It writes to both
> `~/.claude/skills/notebooklm/SKILL.md` and
> `~/.agents/skills/notebooklm/SKILL.md` — the second of which is the
> dotfile-tracked file. The write bypasses dotfiles entirely and would
> wipe the dotfile-only reconciliations at the top of the `notebooklm`
> skill (currently the Setup check section and the Installation redirect;
> Step 6 lists the current set). To pull upstream changes, use Step 6.

## Step 1: Upgrade pip

Not strictly required, but pip 25.x has had install quirks with some transitive deps. Upgrade first:

```bash
pip install --upgrade pip
```

## Step 2: Install or upgrade the CLI

The `[browser]` extra pulls in Playwright so `notebooklm login` can drive Chromium for the Google OAuth flow. The `--upgrade` flag is harmless on a fresh install and pulls the latest release otherwise — same command handles both.

```bash
pip install --upgrade "notebooklm-py[browser]"
```

Verify:
```bash
notebooklm --version
```

If you upgraded (vs. fresh install), note the new version — you'll need it in Step 6 to refresh the dotfile-shipped skill in lockstep.

## Step 3: Install Chromium

```bash
playwright install chromium
```

Downloads to `~/Library/Caches/ms-playwright/` (macOS) or `~/.cache/ms-playwright/` (Linux). Only used once for the login flow.

If it fails with `TypeError: onExit is not a function`, see the [Linux workaround in upstream troubleshooting docs](https://github.com/teng-lin/notebooklm-py/blob/main/docs/troubleshooting.md).

## Step 4: Authenticate

**Upgrading?** First check whether you're already authenticated:

```bash
notebooklm status
```

If it shows "Authenticated as: your-email@..." you can skip the rest of this step — the existing session in `~/.notebooklm/storage_state.json` usually survives a CLI upgrade. Otherwise, or on a fresh install:

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
notebooklm status     # skip if you just ran this in Step 4
notebooklm list
```

`status` should show "Authenticated as: your-email@...". `list` should return your notebooks (or an empty table if you have none).

If either fails with auth errors, run `notebooklm auth check --test` to diagnose, then re-run `notebooklm login` if needed.

## Step 6: Check for skill drift (recommended)

The `notebooklm` skill ships via dotfiles, so on this machine its SKILL.md is
whatever was committed last. Check against the GitHub source of truth at the
latest release tag (the same tag upstream recommends installing from):

```bash
LATEST_TAG=$(curl -s https://api.github.com/repos/teng-lin/notebooklm-py/releases/latest \
  | grep '"tag_name"' | cut -d'"' -f4)

diff <(curl -sL "https://raw.githubusercontent.com/teng-lin/notebooklm-py/${LATEST_TAG}/SKILL.md") \
     ~/.agents/skills/notebooklm/SKILL.md
```

Why GitHub instead of the CLI?
- The SKILL.md bundled inside a CLI release can lag the GitHub repo — older
  CLI versions may carry stale docs even if you upgrade later.
- GitHub at the latest release tag is the actual source of truth, and works
  regardless of which CLI version is installed.

The diff will include any reconciliations we maintain on top of upstream.
The dotfile copy of `notebooklm/SKILL.md` is reconciled against upstream
wherever the upstream instructions conflict with the dotfiles-managed install
pattern — i.e. anywhere upstream tells the user (or Claude) to do something
that mutates the skill file directly, bypasses dotfiles, or assumes a
different install flow than `notebooklm-setup`.

The current reconciliations are two sections near the top of the skill:

1. A **Setup check** section that routes users to this setup skill when the
   CLI isn't installed.
2. An **Installation** section replaced with a one-line redirect to
   `notebooklm-setup` (the upstream version recommends `notebooklm skill
   install`, which would clobber the dotfile copy).

When you read the diff, scan past the known reconciliations for substantive
upstream changes. **If a new upstream release introduces additional
instructions that conflict with the dotfiles-managed install pattern** (e.g.
new auto-install hooks, new commands that mutate the skill file, new install
methods promoted in the upstream body), add a reconciliation for it before
committing — and update this skill to list the new reconciliation.

### If you want to adopt upstream changes

Refresh through dotfiles, **not** through `notebooklm skill install`. The
procedure below preserves the current reconciliations by snapshotting the
range from `## Setup check` through (but not including) `## Prerequisites`.
If upstream renames or rearranges these section boundaries, or you've added
new reconciliations outside that range, adjust the splice accordingly:

```bash
LATEST_TAG=$(curl -s https://api.github.com/repos/teng-lin/notebooklm-py/releases/latest \
  | grep '"tag_name"' | cut -d'"' -f4)

# 1. Snapshot the dotfile-only sections (Setup check + our Installation redirect)
awk '/^## Setup check/,/^## Prerequisites/' ~/.agents/skills/notebooklm/SKILL.md \
  | sed '$d' > /tmp/dotfile-sections.md

# 2. Pull the upstream SKILL.md
curl -sL "https://raw.githubusercontent.com/teng-lin/notebooklm-py/${LATEST_TAG}/SKILL.md" \
  > /tmp/upstream.md

# 3. Splice: upstream intro + our sections + upstream from ## Prerequisites onward
awk '/^## Installation$/{exit}{print}' /tmp/upstream.md > /tmp/final.md
cat /tmp/dotfile-sections.md >> /tmp/final.md
awk '/^## Prerequisites$/{found=1} found{print}' /tmp/upstream.md >> /tmp/final.md
mv /tmp/final.md ~/.agents/skills/notebooklm/SKILL.md

# 4. Review and commit
dot diff ~/.agents/skills/notebooklm/SKILL.md
dot add ~/.agents/skills/notebooklm/SKILL.md
dot commit -m "refresh notebooklm SKILL.md from notebooklm-py ${LATEST_TAG}"
```

This keeps the dotfile as the source of truth on every machine and avoids the
direct CLI write that would bypass version control.

> **Why not `main`?** The repo's main branch can include unreleased and
> unstable changes. The upstream SKILL.md itself recommends pinning installs
> to a release tag — we follow the same rule when refreshing.

## Step 7 (optional): Transcription tooling

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

`notebooklm-py` 0.4.x ships a built-in `profile` subcommand for managing multiple Google accounts:

```bash
notebooklm profile create work
notebooklm profile switch work       # set the default profile
notebooklm profile list
notebooklm -p work login             # one-off use of a profile
```

See the `notebooklm` skill's Quick Reference for the full set of profile commands. Each profile has its own auth state and context — Claude can use profile-aware isolation in parallel workflows (`export NOTEBOOKLM_PROFILE=agent-$ID`).

For full env isolation (separate config home, separate Playwright browser profile), `NOTEBOOKLM_HOME` still works as an alternative:
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
