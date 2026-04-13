---
name: supesc-dispatch
description: Dispatch Support Escalation tickets from the SUPESC triage queue in Linear to the right product domain teams. Use when the user says "dispatch", "triage", "check supesc", "support escalations", "route tickets", "check the queue", or wants to process production support tickets. Also use when running in a /loop for continuous dispatch monitoring throughout the day.
---

# SUPESC Dispatch

Dispatch production support tickets from the **Support Escalations** team's triage queue in Linear to the correct product domain teams. This skill is designed to run once per invocation - pull the queue, process what's there, done. It pairs well with `/loop` for continuous monitoring throughout a workday.

## Arguments

- `auto` - Run without supervision. Move tickets, post comments, and close tickets autonomously. When this flag is on, every action taken on a Linear ticket must include a note that it was an automatic action from Claude Code (see Comment Format below).

Without `auto`, present findings and routing recommendations to the user and wait for approval before taking any action in Linear.

## Prerequisites

### Linear MCP — required in all modes

The skill cannot function without Linear MCP access — it's needed to pull the queue, read tickets, post comments, and move tickets. This is the only hard stop, and it applies whether you're in `auto` mode or not. If Linear MCP isn't available, report it and stop.

### Local Homebot repos — optional, never impede auto mode

Local Homebot repos at `/Users/dan.chen@homebot.ai/code/homebot/` are **recommended but optional**. When available, dispatch quality is noticeably better: Category-A tickets can be closed directly from code, and ambiguous tickets can be traced to the team that owns the root cause. When missing or partial, the skill still works — it just falls back on ticket content and the routing guide.

**Neither the repo-availability check nor the freshness nudge is allowed to impede auto mode.** Auto mode runs unattended on loops and must never block, prompt, or add unnecessary chatter.

#### Detecting local repos (all modes, silent in auto)

Do a silent, passive check on the first ticket that needs codebase context — don't announce it up front:

- **Directory missing entirely** → code-based investigation is unavailable this run. Proceed in routing-only mode. In auto mode, no commentary. In non-auto mode, mention once that cloning the Homebot repos into `/Users/dan.chen@homebot.ai/code/homebot/` would let this skill do codebase investigation and close Category-A tickets directly.
- **Directory exists but some repos are missing** → work with the repos that are present. Common repos: `mikasa`, `native-backend`, `lockbox`, `kraken`, `customer-admin`, `clients-frontend-v2`, `email-templater`, `crawlspace`. In non-auto mode, if a ticket would have benefited from a missing repo, mention which missing repo(s) would have helped so the user can decide whether to clone them.
- **All repos present** → proceed normally.

#### Freshness nudge (non-auto mode only, once per session)

When **not** running in `auto` mode, if repos are available, give the user a single one-line nudge at the start suggesting they pull the latest on repos likely to be touched, or clone any missing repos they want covered. Don't repeat it on subsequent invocations in the same session.

**In auto mode, never nudge.** No freshness commentary, no clone suggestions, no prompts, no blocking. Auto mode gets re-invoked by `/loop` on a schedule and can't tolerate noise.

## Workflow

### 1. Pull the queue

Fetch all issues from the **Support Escalations** team in **Triage** status. If the queue is empty, say so and stop.

### 2. For each ticket, read the full details

Use `get_issue` with `includeRelations: true` to get the complete picture - description, labels, attachments, related issues, comments.

### 3. Determine the action

Each ticket falls into one of three categories:

**A. Answerable from the codebase** - The ticket is a question about how the platform behaves, not a bug report. If the answer can be determined by reading the code (no production data access needed), go find it. The Homebot repos are at `/Users/dan.chen@homebot.ai/code/homebot/` with subdirectories for each repo (mikasa, native-backend, lockbox, etc.). Read the repo's CLAUDE.md before diving in if one exists.

**If the local repos aren't available** (directory missing, or the relevant repo isn't cloned), a Category-A ticket can't be resolved this run — treat it as Category B instead and route it to the team most likely to own the code path. Note in the routing comment that a codebase check was skipped because the repos weren't available locally.

When answering from code:
- Post findings as a reply to the Slack-synced comment thread on the ticket (reply to the first comment, which is usually the Slack sync marker)
- Close the ticket (mark as Done)
- Add a follow-up comment: "Closing this out since the behavior is clear from the codebase. If this doesn't fully answer the question or there's something else needed on top of this, feel free to reopen the ticket."
- No need to move the ticket to another team

**B. Routable to a team** - The ticket is a bug, config issue, or investigation that belongs with a specific product domain team. Route it (see Team Routing Guide below).

**C. Uncertain routing** - You can make a best guess but aren't confident. Still route it, but flag the uncertainty in the comment and ping the team lead (PM or EM) to confirm it belongs with them.

### 4. Route the ticket

For tickets being routed (categories B and C):

1. Post a routing comment on the ticket with reasoning (see Comment Format)
2. Move the ticket to the target team
3. Keep the ticket in **Triage** status - the team leads will prioritize it from there

## Team Routing Guide

| Team | Routes here when... | Watch out for... |
|------|---------------------|------------------|
| **Infrastructure** | Site-wide outages, pages not serving | Rare from supesc |
| **VSB** | Individual (non-enterprise) customer account setup/config issues | Could be CX if it's app behavior, not account config |
| **User Messaging** | Send infrastructure, delivery failures, notification channel issues | NOT email content - route content issues to the domain team. Email cadence, sequencing, throttle, volume, IP warming questions also belong here. |
| **Customer Experience** | CEP features: client dashboard, building interface, HBN, partners (incl. Partner Intel data accuracy), co-sponsors, co-sponsorship management | Big surface area - read the through line. Root cause might be data, billing, etc. underneath |
| **Enterprise** | Bulk migration/changes, enterprise-specific features, enterprise admin | Usually one-off requests |
| **Client Experience** | Consumer app: home digest, home values, listings, mobile app, client emails | Look for root cause that might belong elsewhere |
| **Intelligence** | AI/GPT/semantics (except partner intel AI or CFE AI assistant) | Nothing public-facing yet, so rare |
| **Data** | Bad loan data, home value issues, address mismatches, public record data (partner intel/HBN), listing data quality (photos, MLS fields) | Listing/digest issues that look like CLE may actually be data pipeline problems - trace the data flow |
| **Design** | Don't route here | |
| **User Discovery** | Feature requests only - but usually better to just close the ticket and tell the requester it's a feature request | |
| **BI** | Don't route from supesc | |

### Investigate before routing ambiguous tickets

When the right team isn't immediately obvious, don't just guess from surface-level signals. If the local repos are available, dig into the codebase to trace the issue. If the application code looks solid and is just passing data through, the problem is likely deeper — in a data pipeline, an external feed, or a different system entirely. This investigation often shifts the routing from the team where the symptom appears to the team that owns the root cause.

When this investigation leads you to route a ticket to a team that wouldn't be obvious from the ticket's surface description, include the technical reasoning in the top-level routing comment. The receiving team needs to understand why it landed on their board when it doesn't look like their kind of ticket at first glance. A routing comment like "this looks like a digest display issue but the app just passes `thumbnail_image` through from the data pipeline — the mismatch is upstream" gives the Data team the context they need to act on it.

**If the local repos aren't available,** skip the code-trace step and route based on the ticket content alone using the routing guide. Treat ambiguous tickets as Category C: pick the best-guess team, note the uncertainty in the routing comment, and flag that a deeper codebase trace would help confirm the routing.

### Reading the through line

Many tickets surface through Customer Experience or Client Experience because that's where the user sees the problem. But the root cause may live elsewhere:

- A CEP issue that's really about bad underlying data -> **Data**
- A client-facing email content issue -> the team that owns that content, not **User Messaging**
- A feature that looks like CX but is really a billing/subscription problem -> check if **VSB** or another team owns billing
- An account config issue that looks like a bug -> could be a simple toggle in HB Admin (like the `full_access` field on plans) that support can fix themselves
- A digest/listing issue where the data displayed is wrong (photos, values, rates) but the app is rendering correctly -> likely **Data**, not Client Experience. Trace the data flow: if the application just passes through a field from the database without transformation, the corruption is upstream in the data pipeline.

When you spot this, note both the surface issue and the underlying root cause in the routing comment so the receiving team has context.

### Known shortcuts

- **"Missing features on a plan" tickets** are often just the `full_access` toggle missing in HB Admin's Plans tab. Anyone with Plans tab access can turn this on. Worth noting in the comment so the team can resolve quickly.
- **Partner Intel data accuracy questions** (e.g. LO volume looks wrong, transaction counts off) → route to **Customer Experience** for initial investigation, not Intelligence. Do a first-pass look through the code repos for anything glaring before routing. If the investigation starts touching product behaviors around the criteria for when/how data is selected, `@`-tag **Chris Johnson** in a Linear comment on the ticket for a product take.

## Comment Format

The audience is customer support and CSMs - they are not technical. Ground your reasoning in what you found in the code, but explain it in plain language first.

### For routing comments

```
**Routing: [Team Name]**

[1-3 sentences explaining why this ticket belongs with this team, in plain language tied to the specific situation in the ticket.]
```

Keep routing comments concise. The team leads just need to know why it landed on their board.

**When routing is non-obvious:** If your investigation led you to a different team than the ticket's surface description would suggest, add a brief technical justification below the plain-language routing. This helps the receiving team understand why the ticket is theirs when it doesn't look like it at first glance. For example, if a "listing photos are wrong in the digest" ticket routes to Data instead of Client Experience, explain that the app passes the photo field through untouched and the mismatch is in the upstream data pipeline.

### For codebase answers

Structure in this order:

1. **Plain-language answer** - Directly answer the question, tied to the specific customer/situation mentioned in the ticket
2. **What this means for [customer name]** - Practical implications, concrete scenarios
3. **Technical detail for context** - Code references and implementation details for anyone who wants to dig deeper

### Auto mode attribution

When running in `auto` mode, prepend every comment with:

```
_Automatic triage by Claude Code_

```

This makes it clear to anyone reading that the action was taken automatically, not by a human reviewer.

## Where Comments Go

There are two places to put comments, and the distinction matters:

**Top-level comment on the ticket** — Use for routing reasoning and behind-the-scenes context. The audience is the engineers and team leads who will pick up the ticket. This is where routing comments go.

**Reply to the Slack-synced thread** — Use when communicating back to the people who created the ticket (answering questions, closing the loop, providing status). Most SUPESC tickets have a Slack-synced comment thread (the first comment usually says "This comment thread is synced to a corresponding thread in Slack"). Not all CSMs and support staff use Linear - they read the Slack thread. Reply to this thread (use the `parentId` of the Slack sync comment) so the message flows back to Slack.

In practice:
- Routing a ticket? Post a **top-level comment** with the routing reasoning.
- Answering a question from the codebase (Category A)? Reply to the **Slack-synced thread** with the answer, so the person who asked gets the response.

## What NOT to do

- Don't assign tickets to specific people - leave them unassigned for the team lead to assign
- Don't change priority unless there's a clear reason
- Don't route to Design, BI, or User Discovery (unless it's genuinely a feature request for User Discovery)
- Don't access production data or .env files
- Don't make changes to the codebase - this skill is for dispatch only
