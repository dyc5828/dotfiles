---
name: comb
description: Comb every available source for context — use everything at your disposal. Slack, Gmail, Linear, Notion, GitHub, the local codebase, meeting notes in Wispr Flow, Granola, Zoom, and Notion, observability, analytics, anything else connected. Also the go-to for finding precedent: how we did something before, so it can be replicated. Defines where to look, not what to do with what's found. Triggers on "/comb", "pull context", "gather context", "dig up", "investigate", "how did we do X", "how do I do X", "find prior art", "how was this done before".
---

# Comb

Use everything at your disposal. Sweep broadly — never stop at one source.

A common use: **finding precedent.** When the task is "how did we do this before" or "how do I do X here," the goal is to dig up the prior example — the old PR, the Slack thread, the ticket, the existing code path — pull it into context, and surface it in enough detail that it can be replicated or followed. Don't just confirm it exists; bring back the actual recipe.


The list below is what we usually reach for. It is a starting point, not a fence:

- **Local codebase** — rg, git history, recent PRs, blame. Always include. Homebot's repos usually live under `~/code/homebot/` (a multi-repo workspace — mikasa, native-backend, lockbox, etc.), and the skill often runs from there, so that's a good place to look first.
- **Issue tracking & docs** — Linear, Notion, GitHub (PRs, issues, discussions).
- **Conversations** — Slack, Gmail. Don't skip Gmail. It's the Google Workspace mailbox at `dan.chen@homebot.ai`, and it's the easiest source to forget even though it's often the only place a thread exists. Look there whenever someone outside the company might have been involved: vendors, partners, enterprise customers, contracts, security notices, anything that never landed in Slack. `search_threads` takes Gmail query syntax, not natural language, so translate first — `from:`, `to:`, `subject:`, `newer_than:7d`, `has:attachment`, quoted phrases, `OR`, and `-` to exclude. It returns snippets only, so follow up with `get_thread` on the promising hits to read the actual bodies.
- **Meetings** — Wispr Flow first, then Granola, Zoom, and Notion. Meeting notes hold the decisions and rationale that never made it into a ticket, doc, or Slack thread, which makes them the highest-yield source for "why did we do it this way."
  - **Wispr Flow** is the primary source. It's where Dan records most meeting transcripts. `search_meetings` takes a keyword plus `since`/`until` and `attendee_emails` filters, and matches titles, summaries, and notes but not transcripts. Follow up with `get_meeting` on the hits and pass `view_transcript={}` when `has_transcript` is true, since the notes summary drops details. Carry each meeting's `share_link` into your findings, and convert its UTC timestamps to local time before reporting them. Share links on `notes.wisprflow.ai/shared/` go through `resolve_share_link`, not a web fetch.
  - **Granola, Zoom, and Notion** are one tier down, in no particular order. Always try all three for completeness, and especially when Flow turns up nothing. A meeting may only have been captured in one of them, and plenty of people take notes in Notion instead of a notetaker.
    - **Granola:** lead with `query_granola_meetings` — natural language, searches across all notes, and returns citation links you must carry through into your findings. Fall back to `list_meetings` when you need a specific date range or want to sweep a period, then `get_meetings` for the notes and summary of the hits. Reach for `get_meeting_transcript` only when exact wording matters, e.g. who committed to what, or the precise phrasing of a decision.
    - **Zoom:** holds AI Companion summaries, cloud recordings, and My Notes, which also cover Teams, Meet, and in-person meetings. Lead with `ask` for decisions, owners, and action items. It returns a synthesized answer with citations to carry through. Use `search` to find specific meetings, scoped with `datasource_filters` to `zoom_meeting` for host-owned summaries and recordings or `zoom_my_notes` for notes and attendee-side transcripts. Include both when it's unclear which kind of transcript holds the answer. Then read a meeting with `get_meeting_assets`, or a note with `my_notes_get_note_content` and `include=transcript`. `search` needs local dates converted to UTC.
    - **Notion:** `notion-query-meeting-notes` filters the meeting-notes data source by title, attendee, or created date. Don't push words like "action items," "todos," or "summary" into a title filter; filter down to the right meetings and read the outcomes out of the notes. `notion-search` catches notes living outside that database.
- **Observability & errors** — Sentry, Datadog.
- **Analytics & data** — Amplitude, Sigma, Braintrust.
- **Calendar & files** — Google Calendar, Google Drive.

These may be connected, or they may not. If a source isn't available, skip it silently — don't complain, don't flag it, just move on. And don't limit yourself to this list: if something else is connected that could hold relevant context, use it too.

Vary queries; fetch multiple promising hits per source, not one. Cite everything: `file:line`, ticket IDs, permalinks, Wispr Flow share links, Granola and Zoom citation links.

The surrounding task defines what to do with the findings. This only defines where to look.
