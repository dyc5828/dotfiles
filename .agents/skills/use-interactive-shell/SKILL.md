---
name: use-interactive-shell
description: Maintain a persistent interactive shell across multiple Bash tool calls using tmux as a state container. Use when a task requires multi-turn dialogue with the same process — Rails console, psql, Python REPL, ssh sessions, paginated CLIs, or anything that expects an ongoing PTY. Solves the "each Bash call is a fresh shell" limitation. Triggers on "open a rails console", "psql session", "ssh into", "stay logged in", "interactive shell", or any task where state must survive between commands.
allowed-tools: Bash
---

# Use Interactive Shell

Maintain a persistent interactive process across multiple Bash tool calls. Each Bash call is a fresh shell — `cd`, env vars, login subshells, and TTY-bound programs (Rails console, psql, REPLs) don't carry over. Tmux solves this by holding the process and PTY between your calls.

## Lifecycle

**1. Start a session** with an initial shell or program:

```bash
tmux new-session -d -s <name> '<initial-command>'
```

- Use a shell (`zsh`, `bash`) not a one-shot command — if the initial command exits, the session dies.
- For an aws-vault / authenticated subshell: `tmux new-session -d -s work 'av exec dev'`.

**2. Send commands** (newline = Enter):

```bash
tmux send-keys -t <name> '<command>' Enter
```

**3. Read output** after a brief sleep so the command can run:

```bash
sleep <N> && tmux capture-pane -t <name> -p -S -<lines>
```

- `-p` prints to stdout; `-S -50` includes 50 lines of scrollback.
- Tune sleep to the operation (1–2s for shell builtins, 10–30s for Rails console boot).

**4. Tear down** when finished:

```bash
tmux kill-session -t <name>
```

## Session naming

Pick a short, descriptive name based on what the session is for: `bev`, `rails`, `psql`, `console`, `dbshell`, etc. Short enough that the user can easily type it for `tmux attach`. Check it's free first:

```bash
tmux has-session -t bev 2>/dev/null && echo "in use"
```

If it's taken, pick a different contextual name (`bev2`, `rails-water`, etc.) — your call, don't ask the user.

## Let the user follow along

When you start a session, tell the user the attach command so they can watch in real time:

```
tmux attach -t <name>
```

Detach with `Ctrl+b d` (leaves the session running). Mention this proactively for long-running sessions or anytime the user might want to verify what's happening.

## Gotchas

- **Session dies if the initial command exits.** Launch a shell (`zsh`, `bash`) or a long-running process, not a one-shot command.
- **Always sleep before capture.** Send-keys returns immediately; the command hasn't run yet. Tune sleep to the operation (1–2s for shell builtins, 10–30s for Rails console boot, longer for migrations).
- **Use scrollback (`-S -N`) when output is long.** `capture-pane -p` shows only the visible pane. `-S -100` includes 100 lines of history.
- **Output is line-wrapped.** Tmux wraps at the pane width, so long lines get broken. Plan for it when parsing.
- **Interactive prompts hang silently.** SSO browser auth, sudo, MFA, `Are you sure? [y/N]` — none announce themselves. If a capture looks stalled, peek with `capture-pane` and surface what you find to the user. For browser auth, paste the URL and any verification code directly into chat so they can act on it.
- **Don't nest aws-vault.** Inside an `av exec` subshell, `AWS_VAULT` is set; running `av exec` again fails. Either work inside the existing subshell or `unset AWS_VAULT` first.
- **Clean up.** `tmux kill-session -t <name>` when done. Leftover sessions accumulate and confuse the next run.
