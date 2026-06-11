---
name: comb
description: Comb every available source for context — use everything at your disposal. Slack, Linear, Notion, GitHub, the local codebase, meeting notes, observability, analytics, anything else connected. Also the go-to for finding precedent: how we did something before, so it can be replicated. Defines where to look, not what to do with what's found. Triggers on "/comb", "pull context", "gather context", "dig up", "investigate", "how did we do X", "how do I do X", "find prior art", "how was this done before".
---

# Comb

Use everything at your disposal. Sweep broadly — never stop at one source.

A common use: **finding precedent.** When the task is "how did we do this before" or "how do I do X here," the goal is to dig up the prior example — the old PR, the Slack thread, the ticket, the existing code path — pull it into context, and surface it in enough detail that it can be replicated or followed. Don't just confirm it exists; bring back the actual recipe.


The list below is what we usually reach for. It is a starting point, not a fence:

- **Local codebase** — rg, git history, recent PRs, blame. Always include. Homebot's repos usually live under `~/code/homebot/` (a multi-repo workspace — mikasa, native-backend, lockbox, etc.), and the skill often runs from there, so that's a good place to look first.
- **Issue tracking & docs** — Linear, Notion, GitHub (PRs, issues, discussions).
- **Conversations** — Slack, Gmail.
- **Meetings** — Granola, Zoom (transcripts, summaries, recordings).
- **Observability & errors** — Sentry, Datadog.
- **Analytics & data** — Amplitude, Sigma, Braintrust.
- **Calendar & files** — Google Calendar, Google Drive.

These may be connected, or they may not. If a source isn't available, skip it silently — don't complain, don't flag it, just move on. And don't limit yourself to this list: if something else is connected that could hold relevant context, use it too.

Vary queries; fetch multiple promising hits per source, not one. Cite everything: `file:line`, ticket IDs, permalinks.

The surrounding task defines what to do with the findings. This only defines where to look.
