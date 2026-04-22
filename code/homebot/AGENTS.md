# Homebot

This is the top-level working directory for Homebot's multi-repo codebase. It is **not** a git repository itself — each subdirectory is a separate git repo.

## Repository Map

### Core Backend
- **mikasa/** — Rails API backend. The primary data layer for Homebot (clients, customer profiles, team memberships, subscriptions, etc.). Tests run inside Docker: `docker exec -it mikasa rspec <path>`. Has its own CLAUDE.md at `mikasa/.claude/CLAUDE.md`.
- **native-backend/** — Firebase Cloud Functions + GraphQL server ("gqlactus"). Backend for the native mobile app and Clients Frontend. TypeScript. Has its own CLAUDE.md.

### Frontend
- **clients-frontend-v2/** — Client-facing frontend (CFE). Depends on gqlactus.
- **customer-admin/** — Customer admin portal (for LOs/REAs to manage their accounts).
- **native/** — React Native mobile app.
- **hb-web-component-catalog/** — Shared web component library.

### Admin / Internal Tools
- **lockbox/** — Identity provider, authentication service, and **HPAdmin** (back-of-house admin control panel). Contains bulk client operations UI, TableFlow imports, and employee-facing admin views.
- **kraken/** — Contains **Porthole** (React admin frontend at `apps/porthole/`). Modern admin UI with bulk delete functionality. Links to Lockbox/HPAdmin for legacy operations.
- **crawlspace/** — Minimal admin app for plans, feature flags, and customer profile settings. Mostly stubs that redirect to HPAdmin for bulk operations.

### Infrastructure / Tooling
- **hbdev/** — Development utilities and local environment setup.
- **hb-airflow/** — Airflow DAGs for data pipelines. Has its own CLAUDE.md.
- **botfiles/** — Bot/automation files.
- **docs/** — Documentation repo that syncs markdown to Notion. Has its own CLAUDE.md.
- **email-templater/** — Email template management.
- **purl/** — URL shortener/redirect service.

### Review Copies
- **mikasa-test-review/** — Review copy of mikasa (has its own CLAUDE.md).
- **native-backend-test-review/** — Review copy of native-backend.

## Repo-Level CLAUDE.md

Before working in a subdirectory repo, read its CLAUDE.md if one exists. Common locations are `<repo>/CLAUDE.md` and `<repo>/.claude/CLAUDE.md`. These contain repo-specific conventions, test commands, and workflows that are not loaded automatically when launched from the homebot root.

## Working with Multiple Repos

Since this is not a git repo, use `git -C <repo>` to run git commands from this directory:

```bash
git -C mikasa status
git -C native-backend log --oneline -5
git -C lockbox diff
```

## Key Domain Concepts

### Homebot Network (HBN) — Team Memberships
The preferred agent/partner system is managed through `client_team_memberships` in Mikasa:
- A **Client** (homeowner/buyer) can have one partner per type: RealEstateAgent, LoanOfficer, InsuranceAgent
- **ClientTeamMembership** is the join table between clients and customer profiles (agents/partners)
- Key services in `mikasa/app/services/homebot_network/`:
  - `CreateTeamMembership` — single client + existing agent
  - `CreateTeamMembershipsWithCustomer` — bulk: many clients + one agent (creates agent if needed)
  - `DiscardClientTeamMemberships` — bulk soft-delete (accepts array of membership objects)
  - `ReplaceTeamMembership` — orchestrates discard + create for a single client
  - `CreateNewTeamMembershipForReplacement` — handles both existing and new agent scenarios

### Bulk Operations
- **Rake tasks** in `mikasa/lib/tasks/` for operational scripts (enterprise imports, one-and-done fixes)
- **BulkOperation model** in Mikasa for delete/transfer (used by Lockbox and Porthole admin UIs)
- **TableFlow imports** via Lockbox HPAdmin for CSV-based bulk operations
- **Bifrost** integration for bulk client CSV uploads

## Worktrees & Parallel Work

When working on a feature in parallel (or when the main repo checkout is busy with other changes), use git worktrees. Create worktree directories as **siblings** to the repo, named `<repo>-<branch-or-feature>`:

```bash
# Example: create a worktree for mikasa
git -C mikasa worktree add ../mikasa-bulk-agent-update csx-1254-bulk-agent-update

# Result: homebot/mikasa-bulk-agent-update/ exists alongside homebot/mikasa/
```

This keeps worktrees discoverable at a glance from the homebot root directory. Clean up when done:

```bash
git -C mikasa worktree remove ../mikasa-bulk-agent-update
```

## PRs

Always use `--repo` to target the correct repository with `gh` commands. Do not rely on the shell working directory — in this multi-repo workspace it's easy to accidentally target the wrong repo.

```bash
gh pr create --repo homebotapp/mikasa --title "..." --body "..."
gh pr edit 123 --repo homebotapp/clients-frontend-v2 --body "..."
```

For repos with PR templates, read `.github/PULL_REQUEST_TEMPLATE.md` first. Mikasa prefers PR descriptions written to a `PR_DESCRIPTION.md` file (user copies and deletes) rather than output inline in chat.

## PR Reviews

When reviewing a PR:

1. **Read thoroughly.** Fetch the full diff, read all existing comments/review threads, and understand the complete scope of changes before forming opinions.
2. **Use the local codebase.** Don't review the diff in isolation. Cross-reference against the actual source files to verify business logic, check how things are used elsewhere, understand domain concepts, and fill knowledge gaps. The local repos are right here — use them.
3. **Collaborate, don't submit.** Your job is to walk through the changes with me, present your findings, and get my input on what's right and what needs to be called out. We work through the review together — draft comments, iterate on wording and tone, and only submit when I say it's ready. Never post a review without my explicit go-ahead.

## Environment Notes

- Mikasa runs in Docker locally
- Native-backend uses Firebase emulators + Doppler for secrets
- Never read `.env` files — reference `environment.yaml` for variable documentation
