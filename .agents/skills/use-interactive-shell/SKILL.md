---
name: use-interactive-shell
description: Maintain a persistent interactive shell across multiple Bash tool calls using tmux as a state container. Use when a task requires multi-turn dialogue with the same process — Rails console, psql, Python REPL, ssh sessions, paginated CLIs, or anything that expects an ongoing PTY. Solves the "each Bash call is a fresh shell" limitation. Triggers on "open a rails console", "psql session", "ssh into", "stay logged in", "interactive shell", or any task where state must survive between commands.
allowed-tools: Bash, Monitor, Skill
---

# Use Interactive Shell

Maintain a persistent interactive process across multiple Bash tool calls. Each Bash call is a fresh shell — `cd`, env vars, login subshells, and TTY-bound programs (Rails console, psql, REPLs) don't carry over. Tmux solves this by holding the process and PTY between your calls.

## Lifecycle

**1. Start a session** with an initial shell or program. Size the pane explicitly so long output doesn't wrap awkwardly:

```bash
tmux new-session -d -s <name> -x 220 -y 50 'zsh -l'
```

- Use a shell (`zsh`, `bash`) not a one-shot command — if the initial command exits, the session dies.
- For an aws-vault / authenticated subshell: `tmux new-session -d -s work -x 220 -y 50 'av exec dev'`.
- `-x 220 -y 50` is a sane default for Rails console / log work. Go wider for long lines.

**2. Send commands** (newline = Enter):

```bash
tmux send-keys -t <name> '<command>' Enter
```

**3. Read output.** For fast (<5s) operations a small sleep is fine; for anything that boots, pulls, or pages, **poll for a prompt marker instead** (see "Waiting for slow operations" below).

```bash
# Fast case — shell builtin
sleep 1 && tmux capture-pane -t <name> -p -J -S -50
```

- `-p` prints to stdout, `-J` joins wrapped lines (use this whenever you're parsing output), `-S -50` includes 50 lines of scrollback.

**4. Tear down** when finished:

```bash
tmux kill-session -t <name>
```

## Waiting for slow operations — don't go silent

The harness blocks long leading sleeps, and even when it doesn't, a fixed `sleep 30 && capture` is a bad bet: you either over-wait or capture mid-output and report "nothing happened" while the process is still working. **Never stop and wait passively** — keep monitoring until you see real progress, completion, or a recoverable failure signature.

**Default pattern: Monitor with an until-loop polling for a prompt marker.** Pass the `until ... done` line below as the `command` to the Monitor tool — it's not a shell one-liner you type at a prompt.

```bash
# command field for Monitor — wait for an irb/pry prompt to appear
until tmux capture-pane -t <name> -p -J | grep -qE 'irb\(main\)|pry\(main\)|>\s*$'; do sleep 5; done; echo READY
```

Pick the grep alternation to cover **both success and failure** — a Rails boot might print `irb(main)`, but it could also crash with `Error` or `Traceback`. If your filter only matches the happy path, a crashloop looks identical to "still booting."

```bash
# command field for Monitor — covers boot, crash, and bail-out
until tmux capture-pane -t <name> -p -J -S -20 | grep -qE 'irb\(|pry\(|Traceback|Error:|FATAL|exited'; do sleep 5; done
```

**If the monitor times out or returns no signal, don't surrender — recover:**

1. Re-capture the pane to see current state.
2. If output is advancing (line count grew, new log lines), the process is alive — re-arm Monitor with a longer timeout or a broader grep.
3. If output is frozen, look for an interactive prompt you missed. Drive it yourself when you can (arrow-key menu, `[y/N]` — see "Arrow-key TUI menus" below). If it needs something only the user can supply (password, MFA code, browser-based auth), surface the prompt and the URL/code directly.
4. If a command is genuinely stuck and you need to abort it (runaway query, hung pull, paginated `less`), send an interrupt: `tmux send-keys -t <name> C-c`. For `q`-style pagers, send `tmux send-keys -t <name> q`.
5. Only escalate to the user if you've genuinely exhausted recovery, and surface *what* you saw, not just "it stalled."

**For self-paced repeated monitoring** — when the wait spans many minutes, the next-step depends on state you can only check by re-looking, or you'd otherwise be tempted to chain ad-hoc Bash calls — invoke the `loop` skill. Treat the example below as a **starting point**, not a recipe: adapt the prompt, cadence, and exit condition to the actual operation. Tighten the check if the process is fast-moving; broaden it if you're babysitting a long deploy.

```
/loop check the tmux `prod` pane: if you see an irb/pry prompt or a recoverable error, report what you found and stop; if output is still advancing, keep watching; if frozen for two consecutive checks, look for an interactive prompt I missed and try to drive it forward
```

The point is that *you* keep the watch alive — don't punt back to the user mid-wait.

## Reading output without polluting your context

Every `capture-pane -p -S -<big>` dumps the full scrollback into your conversation — repeated captures replay the same wall of Rails boot warnings six times over. Keep captures lean:

- Use a small `-S` (e.g. `-S -15`) once you're past the noisy boot phase and just want the last response.
- Or reset the visible history between operations: `tmux send-keys -t <name> 'clear' Enter`.
- Or capture to a file and grep the tail you actually care about:
  ```bash
  tmux capture-pane -t <name> -p -J -S -500 > /tmp/<name>.out && tail -30 /tmp/<name>.out
  ```
- Always pass `-J` when parsing — wrapped lines break grep and visual scanning.

## Sending complex input

Long Ruby/SQL with nested quotes via `send-keys '...'` gets ugly fast and is error-prone. For anything multi-line or with tricky escaping, use the tmux paste buffer:

```bash
cat > /tmp/snippet.rb <<'EOF'
client = Client.find('uuid')
client.client_team_memberships.includes(:customer_profile).each { |m|
  puts "#{m.id} #{m.customer_profile.type}"
}
EOF
tmux load-buffer /tmp/snippet.rb && tmux paste-buffer -t <name> && tmux send-keys -t <name> Enter
```

**Quoting in send-keys:** prefer single-quoting the whole arg, use double quotes inside for the target shell/REPL, and watch for `$` triggering shell interpolation.

## Arrow-key TUI menus

CLIs like `dev console stop`, `gh` prompts, or `fzf`-style pickers use arrow-key selectors that won't accept a typed answer. Send key names directly:

```bash
tmux send-keys -t <name> Down Down Enter   # move highlight, accept
tmux send-keys -t <name> Space Enter       # toggle checkbox, confirm
tmux send-keys -t <name> Enter             # accept default (highlighted) option
```

After sending, capture to confirm the menu closed before continuing.

## Session naming

Pick a short, descriptive name: `bev`, `rails`, `psql`, `prod`, `dbshell`. Short enough the user can type it for `tmux attach`. Check it's free first:

```bash
tmux has-session -t <name> 2>/dev/null && echo "in use"
```

If taken, pick a different contextual name (`bev2`, `rails-water`, etc.) — your call, don't ask the user.

## Let the user follow along

When you start a session, tell the user the attach command so they can watch in real time:

```
tmux attach -t <name>
```

Detach with `Ctrl+b d` (leaves the session running). Mention this proactively for long-running sessions or anytime the user might want to verify what's happening.

## Gotchas

- **Session dies if the initial command exits.** Launch a shell (`zsh`, `bash`) or a long-running process, not a one-shot command.
- **Don't go silent on slow ops.** Use Monitor or the `loop` skill to actively poll — never report "nothing happened" mid-flight without re-checking.
- **Output is line-wrapped at pane width.** Use `capture-pane -J` to join wrapped lines whenever you're parsing.
- **Big `-S` scrollback inflates your context.** Keep `-S` small after the noisy startup phase, or capture to a file and tail it.
- **Interactive prompts hang silently.** SSO browser auth, sudo, MFA, `[y/N]`, arrow-key menus — none announce themselves. If a capture looks stalled, peek with `capture-pane` and surface what you find. For browser auth, paste the URL and verification code into chat so the user can act.
- **Don't nest aws-vault.** Inside an `av exec` subshell, `AWS_VAULT` is set; running `av exec` again fails. Either work inside the existing subshell or `unset AWS_VAULT` first.
- **Clean up.** `tmux kill-session -t <name>` when done. Leftover sessions accumulate and confuse the next run.
