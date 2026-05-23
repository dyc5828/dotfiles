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

## Operating Principles

**Act, don't ask.** This skill runs autonomously end-to-end. When the agent
hits a fork — multiple reasonable encodings of the fix, two plausible owners,
ambiguous priority, etc. — pick the more defensible option and proceed. A
draft PR is cheap to discard; pausing for confirmation defeats the point.

When the choice is non-obvious, encode the choice in the artifact (PR
description, ticket comment) with the alternatives written out so the
engineer and product can override. The PR carries the conversation that
didn't happen up front.

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
   - `priority` (if not set): pick from the table below. Default to Low (4)
     for triage-discovered systemic bugs — the customer was unblocked
     manually, the code fix is preventive

   **Linear priority values** (numeric, easy to confuse):
   | value | label |
   |---|---|
   | 0 | No priority |
   | 1 | Urgent |
   | 2 | High |
   | 3 | Medium |
   | 4 | Low |

   **Retired teams:** Linear silently rejects writes to retired teams with
   "Entity is retired." If the obvious team is retired, fall back to the
   active equivalent (`list_teams` shows all; check `archivedAt` or the name
   pattern — e.g. `CustomerExp` was retired in favor of `Customer Experience`).

2. **Post investigation findings** via `mcp__claude_ai_Linear__save_comment`:
   - Root cause: exact file, line number, and the problematic logic
   - Proposed fix: what needs to change and why
   - Related issues if any
   - Keep it factual and useful for the assignee — they should be able to act
     on it without re-investigating

---

## Phase 5 — Implement Fix (optional)

Skip this phase unless the user explicitly asks for a fix or PR.

The output of this phase is one or more PRs ready for handoff. Quality
matters: the engineer will read this PR as a starting point and the bar is
"could merge as-is after product confirmation," not "rough sketch."

### Scope the change

A fix may need to land as one PR or several across multiple repos. Homebot
is multi-repo — backend changes go in `mikasa` / `native-backend`, UI in
`customer-admin` / `clients-frontend-v2` / `native`, admin in `lockbox` /
`kraken`, etc. (see Repo Map).

When the fix spans repos:
- File **separate PRs per repo**. Don't try to combine changes from
  different repos into one PR — they can't be.
- Each PR references the same Linear ticket.
- Each PR's description **cross-links its sibling PRs**.
- **Order matters:** migration before code that reads the new schema;
  backend before frontend consumers; schema before clients.

### Follow the repo's conventions

- **Read the repo's CLAUDE.md first.** Each repo encodes its own rules
  (mikasa: rspec inside docker, never modify rubocop config, PR description
  goes in `PR_DESCRIPTION.md`; native-backend: Doppler for secrets; etc.).
- **Invoke the relevant hb language skill** before writing or editing in
  that language: `hb:rails`, `hb:rspec`, `hb:ruby`, `hb:react`,
  `hb:typescript`, `hb:vitest`, `hb:nextjs`, `hb:playwright`,
  `hb:testing-library`, `hb:jsdoc`, `hb:markdown`. These encode the org's
  patterns — don't reinvent.
- **Match what's already there:** file structure, naming, test style. Read
  a couple of nearby files in the same repo before editing.

### Testing

- Add a **failing test that captures the bug**, then make it pass. The test
  is the proof that the fix works and the regression guard against the bug
  coming back.
- Cover edge cases, not just the happy path: nil branches, discarded-vs-kept,
  feature-flag-off, permission-denied, multiple-of-same-type, empty
  collections.
- **Run the repo's test command before pushing:**
  - mikasa: `docker exec -it mikasa rspec <path>`
  - Others: see the repo's CLAUDE.md
- **If tests can't run locally** (e.g. docker stack not up), say so
  explicitly in the PR description. Don't claim CI as a substitute and
  don't hide that you skipped them.

### Per-PR mechanics

For each PR:

1. **Worktree** as a sibling to the repo:
   ```bash
   git -C homebot/<repo> worktree add ../<repo>-<branch> -b <branch>
   ```
   Branch name from Linear: `cux-422-short-description`.

2. **Make the change.** Read the file in the worktree before editing.

3. **Update tests** that assert the old (broken) behavior, and add new
   tests per the Testing section above.

4. **Commit** with a descriptive message referencing the ticket ID.

5. **Read `.github/PULL_REQUEST_TEMPLATE.md`** if present. mikasa writes the
   PR description to `PR_DESCRIPTION.md` (user copies and deletes); other
   repos use `--body` directly.

6. **Push and open the PR** via `gh pr create --repo homebotapp/<repo>`.

7. **If the fix encoded a judgment call** (multiple reasonable interpretations
   of intent), the PR description must include:
   - The encoded behavior, in plain English
   - At least one alternative interpretation, with a one-line "what would
     change in the code" hint
   - "Please confirm with product before merging" — verbatim or close to it

8. **Flag out-of-scope items** found during investigation in the PR's
   "Out of scope" section. File as a separate ticket if material; don't
   scope-creep the immediate fix.

---

## Phase 6 — Handoff to the Engineer

Phase 5 ends with one or more PRs open. Phase 6 is the explicit transfer of
ownership: the agent stops working, the engineer takes over. Walk through
these steps in order — skipping one leaves the ticket in an ambiguous state.

### Reassign the Linear ticket

`mcp__claude_ai_Linear__save_issue`:
- `assignee`: Linear user ID from Phase 3
- `state`: confirm the right name with `list_issue_statuses` for the team
  (commonly `Todo` or `Backlog` — pick Backlog when the engineer hasn't
  actually started)
- `priority`: see the priority table in Phase 4

### Reassign the PR(s)

GitHub login is **separate** from Linear identity. Don't guess — look it up:

```bash
gh search commits --repo homebotapp/<repo> "<name>" --limit 1 \
  --json author --jq '.[].author.login'
```

(Linear `displayName` is rarely the GH login. If `gh search commits` returns
nothing, fall back to `git -C homebot/<repo> log --author=<email> --format='%an %ae'`
and try the email's local-part.)

Then:

```bash
gh pr edit <num> --repo homebotapp/<repo> --add-assignee <login>
```

Repeat for every sibling PR in this triage run.

### Reset Linear status to Backlog

Linking a PR auto-moves the Linear ticket to "In Progress." If the engineer
hasn't actually started, that's a lie that clutters their cycle board. Reset:

- Fetch backlog state ID once: `mcp__claude_ai_Linear__list_issue_statuses`
  (look for `type: "backlog"`)
- `mcp__claude_ai_Linear__save_issue` with `state: <backlog-state-id>`

Skip the reset only if the engineer explicitly told the user they're
starting now.

### Post the handoff comment

One comment on the ticket. Neutral voice (see "Voice and Framing" at the
top). Template:

> Automated investigation complete. Root cause and proposed fix are
> documented above.
>
> PR up at <link>. Starting point — use as-is, modify, or start fresh.
>
> Pending product confirmation on <the behavior choice, if any — name it>.

If the agent filed a *new* ticket for a systemic bug uncovered while
resolving a different support ticket, also post a one-line back-link on
the original support ticket so CX doesn't lose the thread:

> Filed <new-ticket> for the underlying bug. <one-sentence summary.>
> Tracking the code fix there.

### Tear down

- Local mikasa Rails console / SSM shell from investigation? `exit` twice,
  then `tmux kill-session -t <name>`.
- Worktrees: leave in place. The engineer may use them. If they ask for
  cleanup, run `git -C homebot/<repo> worktree remove ../<worktree-dir>`.
- Don't auto-delete anything the user didn't ask to delete.

### Walk away

After Phase 6, the agent's job is done. Do not:
- Loop back to check on the PR unless the user explicitly asks
- Iterate on the fix based on the engineer's feedback (that's their PR now)
- Re-comment on the ticket without a fresh prompt from the user

The handoff is a transfer of responsibility, not a request for feedback.

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
- Opened PR #1457 on `homebotapp/customer-admin`

**Phase 6 — Handoff:**
- Reassigned ticket + PR to Seán O'Neill (Linear user + GH login `soneill-hbm`)
- Reset Linear status to Backlog (PR-link auto-bumped to In Progress)
- Posted neutral handoff comment with PR link and note about GREEN-350

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
