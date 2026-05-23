---
name: hb:triage
description: >
  Triage a support escalation or bug ticket end-to-end: fetch the Linear issue,
  investigate the relevant Homebot codebase to find root cause, use git blame to
  identify the right owner, assign the ticket and move it to the correct state,
  and post investigation findings as a comment. Optionally creates a worktree,
  implements a suggested fix, opens a PR, and comments back on the ticket.
  Use when the user shares a Linear URL or ticket ID and wants to investigate,
  route, or action it — including phrases like "look into this ticket",
  "who owns this", "triage this", "investigate and assign", or "find the bug and
  put up a fix".
---

# hb:triage

A workflow for taking a Linear ticket from raw support escalation to actionable
state: investigated, assigned, commented, and optionally fixed.

## Voice and Framing

This skill runs as a neutral third-party agent — not as the engineer who invoked
it. All comments and PR descriptions should make this clear. The agent
investigates, documents findings, offers a suggested fix, and then hands
ownership to the assigned engineer. The engineer decides what to do with it.

**Do not:**
- Write in the first person as if you are the engineer who assigned the task
  (e.g. "I'm assigning this to you", "let me know what you think")
- Invite back-and-forth or iteration from the assignee
- Frame the work as a collaborative request

**Do:**
- Identify yourself as an automated agent acting on behalf of the invoker
- State findings neutrally and factually
- Frame the PR as a suggested starting point — the engineer owns the ticket
  and can use, modify, or discard the code entirely
- The handoff is a transfer of responsibility, not a request for feedback

**Example handoff comment tone:**
> "Automated investigation complete. Root cause and a suggested fix are
> documented above. A draft PR has been opened at [link] as a starting point.
> You now own this ticket — use the PR as-is, modify it, or start fresh."

---

## Phase 1 — Fetch and Read the Ticket

Use `mcp__claude_ai_Linear__get_issue` with `includeRelations: true`.

Extract:
- What the user is reporting (expected vs actual behavior)
- Which product area / UI surface is affected
- Any linked customer, HBAdmin URL, or Intercom thread
- Related issues (check `relatedTo`, `blockedBy`)

If the ticket is vague, scan attached Intercom or Slack links for more context
before proceeding.

---

## Phase 2 — Codebase Investigation

Based on the product area, identify which repo(s) to search. See **Repo Map**
below. Use `rg` and `fd` to locate the relevant files.

Search strategies that work well:
- Search for UI labels, button text, or route segments mentioned in the ticket
- Search for the feature/component name (e.g. `maintenance`, `bulk-delete`,
  `EmailIssues`)
- Follow imports from the entry point to the component rendering the broken UI

Read the relevant files. Understand the conditional logic around the broken
behavior — not just the symptom but why the code works the way it does.

Document your findings clearly: file path, line number, and the specific logic
causing the issue.

---

## Phase 3 — Identify the Owner (git blame)

Run `git blame` on the specific file and lines identified in Phase 2:

```bash
git -C /Users/dan.chen@homebot.ai/code/homebot/<repo> blame --date=short <file>
```

The author of the relevant lines is the right person to assign. Cross-reference
with the Linear user list using `mcp__claude_ai_Linear__list_users` — search by
name or email from the git commit.

> Note: There are two Seáns at Homebot. Seán O'Neill is eng
> (sean.oneill@homebot.ai). Seán Doran is PM (sean.doran@homebot.ai). Check
> the email carefully before assigning.

---

## Phase 4 — Update the Ticket

Do these in parallel:

1. **Assign + move state** via `mcp__claude_ai_Linear__save_issue`:
   - `assignee`: the engineer identified in Phase 3
   - `state`: `Todo` (use `mcp__claude_ai_Linear__list_issue_statuses` to
     confirm available states for the team)

2. **Post investigation findings** via `mcp__claude_ai_Linear__save_comment`:
   - Root cause: exact file, line number, and the problematic logic
   - Proposed fix: what needs to change and why
   - Related issues if any
   - Keep it factual and useful for the assignee — they should be able to act
     on it without re-investigating

---

## Phase 5 — Implement Fix (optional)

Skip this phase unless the user explicitly asks for a fix or PR.

If implementing:

1. Create a worktree as a sibling to the repo, named `<repo>-<branch>`:
   ```bash
   git -C homebot/<repo> worktree add ../<repo>-<branch> -b <branch-name>
   ```
   Use the Linear branch name format: `cux-370-short-description`

2. Make the change. Read the file in the worktree before editing.

3. Update any tests that assert the old (broken) behavior.

4. Commit with a descriptive message referencing the ticket ID.

5. Push and open a PR via `gh pr create --repo homebotapp/<repo>`. Read
   `.github/PULL_REQUEST_TEMPLATE.md` first if it exists.

6. Assign the PR to the engineer from Phase 3. Look up their GitHub login via
   git log (`git log --format='%ae %an'`) and `gh api users/<login>`.

7. Post the PR link back to the Linear ticket as a follow-up comment.

---

## Repo Map

| Product Area | Repo |
|---|---|
| Client list, Maintenance tab, bulk actions | `customer-admin` |
| Client detail, homeowner profile | `customer-admin` |
| Homebot Network (HBN), team memberships | `mikasa` |
| Native app, buyer experience | `native`, `native-backend` |
| Admin tools (HPAdmin) | `lockbox` |
| Modern admin (Porthole) | `kraken` |
| Feature flags, plans | `crawlspace` |
| Data pipelines | `hb-airflow` |

All repos live under `/Users/dan.chen@homebot.ai/code/homebot/`.
Git commands from the homebot root: `git -C <repo> <command>`

---

## Worked Example — CUX-370

A real triage run to reference when refining this skill.

**Ticket:** Bulk delete option missing for Incomplete and Missing Home Value tabs
in the Maintenance section of customer-admin.

**Phase 1 — Ticket read:**
- Reporter: Nawaal Immerfall (CSM)
- Surface: Clients tab → Maintenance → Incomplete / Missing Home Value subtabs
- Symptom: Select All checkbox appears but no action available after selection;
  delete only works under Email Issues
- Related: GREEN-350 (delete also missing from All Maintenance view — separate gap)

**Phase 2 — Codebase investigation:**
- Searched for `maintenance`, `bulk-delete`, `EmailIssues` in customer-admin
- Found `maintenance-bulk-toolbar.tsx` — the toolbar renders a ternary:
  `category === 'email_issues' ? <DeleteClientsButton> : <SendVideoButton>`
- All non-email categories fall through to Send Video, so the delete button
  never renders for Incomplete or Missing Home Value
- Tests in `maintenance-bulk-toolbar.test.tsx` asserted this broken behavior
  (confirmed it was intentional at write time, not a regression)

**Phase 3 — Git blame:**
- Entire file authored by Seán O'Neill (March 2026)
- Identified via `git blame --date=short`; matched to Linear user via email

**Phase 4 — Ticket update:**
- Moved to Todo, assigned to Seán O'Neill
- Posted investigation findings comment: root cause, file + line, proposed fix,
  note about GREEN-350

**Phase 5 — Fix + PR:**
- Created worktree: `customer-admin-cux-370`
- Fixed ternary → two independent conditions; Delete now renders for all
  non-`all` categories; Send Video still shows alongside it for non-email tabs
- Updated tests to assert Delete is present for `incomplete` and
  `missing_home_value`
- Opened PR #1457 on `homebotapp/customer-admin`, assigned to Seán O'Neill
- Posted PR link to ticket as handoff comment

---

## TODO — Extend This Skill

These sections are placeholders for rules that will be added as patterns emerge:

### Domain Routing Rules
> Which team/engineer owns which product area? Add routing logic here as
> it becomes clear — e.g. "Maintenance tab → @sean.oneill", "HBN → @X".

### Escalation Rules
> When should a ticket be escalated vs triaged normally? What priority
> thresholds trigger different workflows?

### Fix Confidence Thresholds
> When is a suggested fix safe to implement and PR vs just comment?
> (e.g. one-line logic fix vs architectural change)

### Ticket Templates
> Canned comment formats for common bug patterns — e.g. "missing conditional
> for new filter type", "state mutation bug", "missing migration".

---

## Notes

- Always use `--repo homebotapp/<repo>` with `gh` commands — the shell cwd is
  the homebot multi-repo root, not a git repo.
- For Mikasa bugs, tests run inside Docker:
  `docker exec -it mikasa rspec <path>`
- Never read `.env` files. Reference `environment.yaml` for variable docs.
