# supesc-dispatch

Dispatch Support Escalation tickets from the Linear SUPESC triage queue to the right product domain team.

## What it does

Pulls every ticket in the Support Escalations team's **Triage** status. For each one, it decides whether to:

1. **Answer from the code** — if the ticket is a question and the answer is in the codebase, reply on the ticket's Slack-synced thread and close it.
2. **Route to a team** — if it's a bug or investigation, post a routing comment explaining why and move it to the right team's triage queue.
3. **Route with a flag** — if the right team isn't obvious, make a best guess and flag the uncertainty so the team lead can confirm.

Tickets stay in **Triage** after routing so the receiving team prioritizes it on their own terms.

## Prerequisites

- **Linear MCP** — required. The skill can't run without it.
- **Homebot repos at `/Users/dan.chen@homebot.ai/code/homebot/`** — optional but recommended. When available, dispatch quality is noticeably better (code-level investigation, better root-cause routing). When missing, the skill degrades to routing-only mode.

## Manual use

```
/supesc-dispatch
```

Runs once. Presents findings and routing recommendations. Waits for your approval before posting comments or moving tickets.

If local repos are available, the skill will nudge you once per session to pull the latest on the repos most likely to be touched.

## Auto mode

```
/supesc-dispatch auto
```

Runs once, autonomously. Posts comments, moves tickets, and closes resolved questions without asking. Every action on a Linear ticket is prepended with `_Automatic triage by Claude Code_` so it's clear to anyone reading that it wasn't a human reviewer.

## Continuous auto dispatch (loop)

Pair with `/loop` to keep the queue flowing throughout the workday:

```
/loop 30min /supesc-dispatch auto
```

This schedules `/supesc-dispatch auto` to run every 30 minutes for the session (loops auto-expire after 7 days). Adjust the interval to taste — `15m`, `1h`, etc. The skill is silent when the queue is empty, so frequent runs aren't noisy.

When running in a loop, the skill never prompts or nudges — it just dispatches and moves on.

## Cancel the loop

```
CronList       # see scheduled jobs
CronDelete <id>  # cancel by ID
```

## Other notes

- The skill won't assign tickets to specific people. Team leads assign from their own triage.
- The skill won't change priority, route to Design/BI/User Discovery, or touch `.env` files.
- For Partner Intel data accuracy questions, routing goes to Customer Experience first for a code/data check; if the investigation needs a product take, Chris Johnson gets tagged on the ticket.
