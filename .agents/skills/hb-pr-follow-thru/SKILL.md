---
name: hb-pr-follow-thru
description: >-
  Active monitoring loop for a PR you've authored — stick with it, watch for
  anything that changes, evaluate each change, and react: address review
  feedback via hb:pr-address when it's automatable, escalate to
  hb:pr-address-interactive when it needs per-item human judgment, flag the
  user when something is genuinely outside what you can decide. Handles
  approval dismissals, BEHIND branches, CI re-runs, late-arriving comments,
  and the final merge confirmation. Use whenever the user says "get this PR
  merged", "watch this PR", "stick with PR X", "follow this PR through",
  "shepherd PR X", "monitor PR X", or invokes `/goal` with a PR-to-merge
  intent. Also trigger after the user opens a PR and the natural next step
  is staying on it through merge — don't wait for an explicit "merge" word.
argument-hint: "<PR number, URL, or blank>"
allowed-tools: Bash, Read, Edit, Skill, Agent, Monitor, PushNotification
---

# hb-pr-follow-thru

You are the resident watcher on a single PR. Your job is to **stay with it**: poll for change, evaluate what changed, and route the response correctly. You do not own the PR's content edits or its review-feedback application — `hb:pr-address` and `hb:pr-address-interactive` own those. You own the loop and the routing.

## When to trigger

Auto-invoke when the user expresses any of:

- "get this PR merged" / "land this PR" / "ship this PR"
- "watch PR #N" / "stick with this PR" / "monitor it"
- "follow this PR through" / "shepherd PR X"
- `/goal` with a clear intent to drive a specific PR to merge
- The user just opened a PR and there's no other obvious next step — staying with it is the obvious next step

Do NOT trigger when:

- The user is reviewing someone else's PR (use the review skills).
- The user only wants to apply review feedback once (use `hb:pr-address` directly — no loop needed).
- The PR is a draft and the user has explicitly said "not ready."

## Draft PRs

Draft status does **not** change the loop. Snapshot it, watch it, run the same routing matrix as for ready PRs. If anything, lean harder into the "new commits pushed by someone else" branch — drafts are where collaborators are most likely to iterate on the code in parallel, and where an external agent's changes are most likely to land unreviewed.

The only thing that does differ is the **terminal step**: a draft PR cannot be merged, so when every other gate clears (approval landed, CI green, branch up to date) but `isDraft` is still `true`, that's the moment to surface it. See the "New review with APPROVED" event below for the handoff.

## Core loop

```
┌─→ poll PR state
│   │
│   ├─ change since last poll? ─ no ──┐
│   │                                 │
│   yes                                │
│   │                                 │
│   ▼                                 │
│   evaluate the change                │
│   │                                 │
│   ▼                                 │
│   route the response ─→ delegate ───┤
│                          or flag    │
│                          or merge   │
│                                     │
└─────────────── sleep ───────────────┘

                  exit on: MERGED / CLOSED / user halt
```

Each turn through the loop is a single `gh pr view` + `gh pr checks` + diff against the last snapshot. The sleep interval is the dial. Routing is where the judgment lives — the rest is mechanical.

## How to run the loop

Two primitives, both required for the loop to actually persist:

### 1. `/goal` — keeps the agent committed to the task

The canonical invocation pattern for this skill is:

```text
/goal get PR #<N> merged. monitor for changes, evaluate them, resolve what you can,
flag what you can't.
```

`/goal` installs a session-scoped Stop hook that blocks the agent from ending its turn until the goal condition holds (the PR is merged, or you've genuinely run out of moves and have flagged the user). Without `/goal`, the agent will happily respond once and then yield — fine for one-shot work, fatal for a multi-hour monitoring loop where new events arrive asynchronously.

The hook auto-clears the moment the condition is met. Don't tell the user to `/goal clear` it on success — it's already gone.

If the user invokes this skill **without** `/goal` (just typed "shepherd PR X" or similar), suggest pairing them in your first message:

> Want me to set a `/goal` so I stick with this PR through merge? Otherwise I'll do one pass and yield.

Default to suggesting it for any "watch through to merge" intent. Skip the suggestion if the user has clearly framed this as a single check-in ("is it merged yet?", "did CI pass?").

### 2. `Monitor` — the actual polling backbone

Use the `Monitor` tool for the polling itself — it's the right primitive for "watch X across multiple events without burning conversation turns." See **Monitor recipe** at the end of this file.

If you find yourself writing `until [...]; do sleep`-style logic in your main turn instead of `Monitor`, stop — you're polling in-conversation, which burns turns and prompt-cache. Hand it to `Monitor`.

### How the two interact

`/goal` is the commitment layer. `Monitor` is the eyes. Each event from `Monitor` re-wakes the agent; `/goal` is what stops the agent from declaring victory after handling that one event and yielding. Together they produce the "resident watcher" behavior — the agent stays on the PR, reacts to each event from the routing matrix below, and only fully releases when the PR is merged (or the user explicitly halts).

## What counts as a change

These are the events worth surfacing. Anything else is silence — don't notify, don't act.

| Event                   | How to detect (delta vs last poll)                                                          |
| ----------------------- | ------------------------------------------------------------------------------------------- |
| New review              | `reviews[]` length increased, OR `latestReviews[]` has a new `submittedAt`                  |
| New inline comment      | `pulls/<N>/comments` length increased                                                       |
| New top-level comment   | `issues/<N>/comments` length increased                                                      |
| Review decision flipped | `reviewDecision` differs from snapshot                                                      |
| Merge state flipped     | `mergeStateStatus` differs from snapshot                                                    |
| New commits pushed      | `headRefOid` (or last commit SHA from `gh pr view`) differs                                 |
| CI completed            | `gh pr checks` no longer has pending/in_progress/queued                                     |
| Draft flipped to ready  | `isDraft` went `true` → `false` — re-check approval + CI and enable auto-merge if both hold |
| Terminal                | `state` is `MERGED` or `CLOSED`                                                             |

Track a small snapshot between polls — just the counts, the SHAs, and the decision strings. You don't need full diff content in memory.

## Routing — what to do when something lands

The interesting work is here. Each event class maps to a response. **The PR is the source of truth** — always re-read the actual content before deciding; don't act on stale snapshot data.

### Event: CI completed

Outcome `pass`: silent if the PR was already approved (auto-merge will handle it); otherwise just log progress in your next polling tick. No action.

Outcome `fail`:

1. Pull the failing job's log: `gh run view --repo <owner>/<repo> --job <id> --log-failed | head -80`.
2. Classify:
   - **Mechanical lint / format / type / autofixable** (Rubocop, oxlint, prettier, eslint --fix candidates) — small, deterministic, the cop tells you what it wants. You can apply, push, and continue. State this plainly to the user in the next message ("Rubocop wants X, applying and re-pushing") — don't hide it.
   - **Test failure** — flaky? a real regression? Don't guess. Re-read the assertion and the changed code. If it's obviously yours and you understand the fix, propose it to the user first. If it's flaky (intermittent, unrelated to the diff), call it out and ask whether to retry or investigate. Don't auto-push test "fixes" without confirmation.
   - **Anything else** (security scan, infra failure, missing env, weird CI internals) — flag the user with the specific failure and your hypothesis.

After any push you make, **expect approvals to be dismissed** — see "Approval dismissed" below.

### Event: New review with `APPROVED`

Combined with green CI, this is the moment auto-merge becomes the right move.

**If the PR is still draft**, don't try to enable auto-merge — `gh pr merge --auto` will error or queue forever on a draft. Surface a single plain notification to the user:

> PR #<N> has approval and green CI but is still in draft. Flip it to ready when you want auto-merge to fire.

Then resume polling. Flipping draft → ready is the user's call (it's a judgment about whether the work is actually done). The events table already catches `isDraft → false` as a delta — when that transition lands, re-evaluate this event (approval + CI are presumably still good) and enable auto-merge then.

For non-draft PRs, if auto-merge isn't already enabled:

```bash
gh pr merge <N> --repo <owner>/<repo> --squash --auto --delete-branch
```

(Squash is the Homebot default. Confirm with `git log --oneline -5 origin/master` — look for `(#NNNN)` suffixes for squash, `Merge pull request` for merge commits.)

If auto-merge is already enabled, do nothing — GitHub will fire it.

### Event: New review with `CHANGES_REQUESTED` or inline comments

This is the routing decision that matters most. Don't just dump it on the user, and don't just blindly invoke `hb:pr-address`. Read the actual comment content and decide:

| Comment shape                                                                                                                                                             | Route                                                                                                                                                                                                       |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Concrete change with verbatim `suggestion` block, no architectural language, in-diff line, your confidence in the fix is high                                             | `hb:pr-address` — it'll apply, commit, push, post replies, resolve threads                                                                                                                                  |
| Concrete change but you're not 100% sure the fix is right, OR multiple comments where some are clear and some aren't, OR the user prefers walking through them themselves | `hb:pr-address-interactive` (TTY only) — surfaces them one-at-a-time with explicit per-item approval                                                                                                        |
| Architectural / "should we" / "have you considered" — judgment calls                                                                                                      | **Flag the user.** Don't invoke either pr-address variant for these — they'll mark as `decided` and the user still has to handle them. Save the round trip: surface the comment, give your read on it, ask. |
| Comment is wrong or already addressed in a later commit                                                                                                                   | Note it for `hb:pr-address` to dismiss with reasoning. Don't manually reply via `gh api` — bypassing `reporter_post.py` skips formatting and dedup logic and produces broken replies.                       |

When you do invoke `hb:pr-address` or `hb:pr-address-interactive`, pass the PR number and let them run. They have their own dedup, their own validators, their own reply-posting flow. Trust the abstraction.

After they return, your loop resumes — keep watching.

#### Optional: re-trigger Claude Code GHA after fix commits

Some repos run a Claude Code GitHub Actions chain (e.g., `claude-pr-chain.yml`) that fires on `pull_request opened` / `ready_for_review` but **not on `synchronize` pushes**. After `hb:pr-address` pushes fixes — or you push follow-ups for judgment items — the latest SHA won't have a fresh chain run. The chain may have only seen the original commits; everything you pushed since is un-reviewed.

**Rule: never auto-trigger. Always ask.** Even when the conditions for re-trigger look obvious — even when you just pushed a commit you want fresh eyes on — pause and prompt the user. Re-runs cost CI quota, can surface new comments, can push more commits that dismiss any prior human approval via stale-approval policy. The user has to weigh "fresh review of my latest commit" against "loop continues longer." That trade-off is theirs to make, not yours.

This means: after **every** push you make in this loop (your own fix commits, follow-ups for judgment items, anything that lands a new SHA), if the repo has this workflow and the chain isn't already firing, surface the question. Don't decide on the user's behalf. Don't fire and then narrate.

**Detection** — does the repo even have a Claude Code GHA workflow? Skip the rest of this subsection if not.

```bash
find .github/workflows -name '*claude*' 2>/dev/null
# or:
gh api repos/<owner>/<repo>/actions/workflows --jq '.workflows[].name' | awk 'tolower($0) ~ /claude/'
```

**Context for the prompt** — gather these before asking, so the user can decide with full information:

```bash
gh pr view <N> --repo <owner>/<repo> \
  --json mergeable,mergeStateStatus,reviewDecision,statusCheckRollup \
  -q '{merge: .mergeable, ms: .mergeStateStatus, rd: .reviewDecision, rollup: .statusCheckRollup[0].state}'
```

Two distinct reasons the user might say yes:

- **Merge-gating reason:** Rollup is `PENDING` with a required check named `claude` (or the workflow's equivalent) missing on the latest SHA. The PR can't merge without it.
- **Review-quality reason:** Rollup is `SUCCESS` (the required `claude` check is carrying forward its passing state from an earlier SHA), but the latest commit has never been reviewed by the chain. The earlier re-trigger in this same loop may have surfaced real issues — a second pass might too.

The first reason is forcing. The second is discretionary. **Surface both** when you prompt; let the user pick.

**Prompt shape:**

> Just pushed `<sha>`. The chain hasn't seen it. Re-trigger? `chain` re-runs review + address (may surface new comments + push commits, which will dismiss any standing approval). `address-only` skips review, just applies pending fixes. Or skip — earlier review still carries forward.

If the user approves:

```bash
gh workflow run claude-pr-chain.yml --repo <owner>/<repo> \
  --field pr_number=<N> --field mode=chain
```

- `mode=chain` re-runs review + address. **Posts the `claude` required status check via the review pass.** Use this when the merge gating reason applies (rollup `PENDING` because `claude` is missing on the latest SHA).
- `mode=address-only` skips review, just runs the address pass on any unresolved threads. **Does NOT post a `claude` status check** — the review pass is what writes that status. If the gating issue is a missing `claude` check, address-only won't satisfy it. Use address-only only when the review pass has already run on the current SHA and you just need to re-apply fixes for a specific thread set.

The workflow runs from the default branch but checks out the PR's head SHA internally — the run will show `headSha = <default-branch-sha>` on the run record, but the work happens against the PR. Watcher picks up new SHAs and comments as usual.

**Don't auto-fire even when you're confident.** This rule exists because the failure mode of auto-firing isn't catastrophic — it's that you've made a small decision the user wanted to make themselves, and over a long PR cycle those small unilateral choices compound. The cost of asking is one short message. The cost of not asking is trust.

### Event: New review with `COMMENTED` (no decision)

Read it. If it's substantive but not a request for change (a question, an FYI, an observation), reply only if you're confident you have the answer from this session's context — otherwise flag the user.

### Event: Review decision flipped to `REVIEW_REQUIRED` (approval dismissed)

Almost always caused by a new commit on the head branch after approval landed. Branch protection's "Dismiss stale pull request approvals when new commits are pushed" is on by default.

Response:

1. Re-request review from whoever previously approved:
   ```bash
   gh pr edit <N> --repo <owner>/<repo> --add-reviewer <reviewer-1>,<reviewer-2>
   ```
2. **Flag the user** with what happened, who you nudged, and why (e.g., "Rubocop fix push dismissed <reviewer-1>'s and <reviewer-2>'s approvals; re-requested both"). They may want to ping the reviewers directly.
3. Resume polling. Don't try to "merge it anyway" — branch protection won't let you, and trying just burns cycles.

If you're the PR author and the user is the PR author too, neither of you can self-approve. State that plainly when flagging.

### Event: Merge state flipped to `BEHIND`

Auto-merge alone will sit on `BEHIND` indefinitely if the repo requires "branch up to date" and GitHub isn't auto-updating. Kick it:

```bash
gh pr update-branch <N> --repo <owner>/<repo>
```

Two properties to know:

- **Approval usually survives** the auto-update merge commit (branch protection typically exempts it). Verify by re-reading `reviewDecision` after — if it's still `APPROVED`, fine. If it flipped, treat as "approval dismissed" above.
- **CI re-runs on the new SHA.** That's expected. Loop continues.

If `gh pr update-branch` errors with conflicts (`mergeable: CONFLICTING` / `mergeStateStatus: DIRTY`), see the next event.

### Event: Merge state flipped to `DIRTY` (conflicts with base)

Try to resolve first. Flag only when you can't.

```bash
git fetch origin <base-branch>
git -C <repo-or-worktree> merge origin/<base-branch>
# or: git rebase origin/<base-branch>
```

Use `merge` (not rebase) by default — it keeps the PR's commit history intact and avoids re-dismissing approvals as aggressively as a force-push would. Rebase only if the repo's convention is rebase-only or the PR has unsquashed cleanup commits the user has signaled they want to flatten.

Walk each conflict file:

- **Mechanical conflicts** (lockfiles, generated files like `db/structure.sql`, formatter-rearranged imports, version bumps in `package.json` / `Gemfile.lock`) — resolve directly. Regenerate lockfiles by re-running the tool (`bundle install`, `pnpm install`, etc.) rather than hand-editing. Schema files: regenerate from migrations.
- **Code conflicts where both sides have a clear intent and they don't interact** — keep both, in the order they appear.
- **Code conflicts where one side touches the same lines you wrote** — re-apply your change against the new base if the intent is preserved.

Then `git add` the resolved files, complete the merge/rebase, push, and let CI re-run. Narrate what you resolved in the next message.

**Flag the user when** any of these hold:

- A conflict is in a file central to the PR's purpose and resolving requires choosing between two competing intents (yours vs. the base's).
- Resolution would meaningfully alter what the PR does, how it does it, or its blast radius.
- The conflicting code is security-, billing-, or data-sensitive (auth, payments, migrations, prod config).
- You're not confident the resolution is correct after one read.

When flagging, surface the specific files and the competing changes — don't dump the merge state and walk away.

### Event: New commits pushed to the head branch (not by you)

Snapshot the new SHA. Then **review the new commits** — don't just wait for CI passively.

```bash
git fetch origin <branch>
git log --oneline <prev-sha>..<new-sha>
git diff <prev-sha>..<new-sha>
```

Read every commit in the range. Three kinds of contributor matter and each gets a different response:

- **The PR author / user themselves.** They're driving — usually a follow-up to your work or a manual fix. Read the diff, confirm it makes sense in context, note anything that affects your earlier reasoning (e.g., the user just reverted something you suggested). No comment needed unless you spot an issue.
- **Another human (co-author, helper).** Read the diff and evaluate against the PR's purpose: does it advance the goal, does it match the style of the rest of the PR, does it leave anything half-done? If you see something worth flagging — bug, test gap, convention mismatch, unintended scope — leave an inline comment via `hb:pr-address` or directly via `gh api repos/<owner>/<repo>/pulls/<N>/comments` for a single targeted note. If you see a complementary change that's clearly needed (e.g., they updated a model but not the matching spec), make that change in a follow-up commit and push it.
- **An external agent / bot (Copilot autopilot, another agent the user dispatched).** Same evaluation as a human, with extra skepticism — agents can mass-rewrite scope, regress style, or silently change behavior. Read carefully. If the change looks correct, narrate that. If it looks wrong or out-of-scope, leave a comment OR revert via a follow-up commit (and flag the user that you reverted, with reasoning).

After reviewing and reacting, wait for CI to settle on the new SHA. Prior reviews are now stale — `reviewDecision` may flip to `REVIEW_REQUIRED` if branch protection dismisses on push (see that event).

**Don't auto-revert someone else's work silently.** If you decide a revert is warranted, push the revert AND immediately flag the user with what you reverted and why. The user has the final call on whether the revert sticks.

### Event: PR closed without merge

Loop exits. Surface this to the user — closure can be deliberate ("dropping this approach") or accidental. Don't assume.

### Event: PR merged

This is the terminus. See **On merge** below.

## On merge

```bash
gh pr view <N> --repo <owner>/<repo> --json state,mergedAt,mergeCommit,headRefName
```

Confirm:

1. `state === "MERGED"`.
2. Linear ticket auto-transitioned (the GitHub-Linear integration moves issues forward on merge — typically `In Progress → In QA`):
   ```text
   mcp__claude_ai_Linear__get_issue { id: "<ticket-id>" }
   ```
   Look at `status`. If it didn't move (race condition, integration glitch), nudge it manually via `mcp__claude_ai_Linear__save_issue` with the right state ID. Most of the time this Just Works.
3. Remote branch deleted (auto-merge with `--delete-branch` does this; verify with `git ls-remote --heads <repo-url> <branch>`).

Then send a `PushNotification` — the merge is the moment the user wants to know about, especially if they walked away.

```
PR #<N> merged. <ticket-id> fix live in code. Linear → <new status>. Awaiting next deploy.
```

Keep it under one line, concrete, no markdown.

After that, check whether there are tied-off loose ends the user might want:

- **Worktree removal** — if the PR was developed in a sibling worktree (per the homebot multi-repo convention), offer to remove it: `git -C <repo> worktree remove ../<repo>-<feature>`. Don't do it unprompted — confirm.
- **Slack / Linear comment closing the loop** — if the PR was the resolution to a thread the user was actively working in (support escalation, customer-experience question, etc.), ask whether to post a closing update. **Do not auto-post** unless the user pre-authorized follow-ups on that specific thread. Phrase non-technically when the audience is non-engineering.

The loop exits.

## What to flag vs. what to act on

This is the central judgment call. Default to flagging when:

- A test failure isn't obviously yours or obviously flaky.
- A review comment is architectural ("should we", "have you considered", "two options").
- A merge conflict requires choosing between competing intents, sits in a security/billing/data-sensitive file, or would meaningfully alter what the PR does.
- A new commit from someone else looks wrong, out-of-scope, or you reverted it — narrate the revert and surface the reasoning.
- Auto-merge has been blocked >30 minutes for a non-obvious reason.
- An approval gets dismissed and you've already nudged the same reviewers.
- The PR receives a `CHANGES_REQUESTED` review from someone you weren't expecting (new reviewer, late comment).
- Anything destructive or visible to the outside world (force-push, close, comment external to the PR).

Default to acting when:

- Mechanical CI failures with deterministic fixes (lint, format, type errors with obvious resolutions).
- BEHIND state needing a routine branch update.
- Mechanical merge conflicts — lockfiles, generated schema files, formatter-rearranged imports, non-overlapping code changes.
- A new commit from someone else introduces a clear half-done change you can complete (e.g., they updated a model but not its spec).
- Auto-merge enablement when approval + green CI both hold.
- Re-requesting the same reviewers after a dismissal.
- Linear status nudges if the auto-transition didn't fire.

When you act, narrate plainly in the next message — what changed, what you did, what's still pending. The user shouldn't have to ask "what happened while I was away."

## Monitor recipe

The polling backbone. Adjust to taste, but this shape covers the events listed above:

```bash
# Track baselines at entry — only the counts and SHAs you need
base_reviews=$(gh api repos/<owner>/<repo>/pulls/<N>/reviews -q 'length' 2>/dev/null)
base_comments=$(gh api repos/<owner>/<repo>/pulls/<N>/comments -q 'length' 2>/dev/null)
base_issue_comments=$(gh api repos/<owner>/<repo>/issues/<N>/comments -q 'length' 2>/dev/null)
base_sha=$(gh pr view <N> --repo <owner>/<repo> --json headRefOid -q '.headRefOid')

while true; do
  s=$(gh pr view <N> --repo <owner>/<repo> \
        --json state,mergeStateStatus,reviewDecision,headRefOid \
        -q '"\(.state)|\(.mergeStateStatus)|\(.reviewDecision)|\(.headRefOid)"' 2>/dev/null || echo "ERR")
  st=$(echo "$s"   | cut -d'|' -f1)
  ms=$(echo "$s"   | cut -d'|' -f2)
  rd=$(echo "$s"   | cut -d'|' -f3)
  sha=$(echo "$s"  | cut -d'|' -f4)

  nrev=$(gh api repos/<owner>/<repo>/pulls/<N>/reviews -q 'length' 2>/dev/null)
  ncom=$(gh api repos/<owner>/<repo>/pulls/<N>/comments -q 'length' 2>/dev/null)
  nicom=$(gh api repos/<owner>/<repo>/issues/<N>/comments -q 'length' 2>/dev/null)

  # Terminal — exit
  if [ "$st" = "MERGED" ]; then echo "MERGED|$s"; break; fi
  if [ "$st" = "CLOSED" ]; then echo "CLOSED|$s"; break; fi

  # Routing-trigger events — emit and continue
  if [ "$rd" = "CHANGES_REQUESTED" ]; then echo "CHANGES_REQUESTED|$s"; fi
  if [ "$rd" = "REVIEW_REQUIRED" ]; then echo "REVIEW_REQUIRED|$s"; fi
  if [ "$ms" = "BEHIND" ];           then echo "BEHIND|$s"; fi
  if [ "$ms" = "DIRTY" ];            then echo "DIRTY|$s"; fi

  # Delta events
  if [ "$nrev"  != "$base_reviews"        ]; then echo "new_review nrev=$nrev (was $base_reviews)";          base_reviews=$nrev; fi
  if [ "$ncom"  != "$base_comments"       ]; then echo "new_inline ncom=$ncom (was $base_comments)";          base_comments=$ncom; fi
  if [ "$nicom" != "$base_issue_comments" ]; then echo "new_comment nicom=$nicom (was $base_issue_comments)"; base_issue_comments=$nicom; fi
  if [ "$sha"   != "$base_sha"            ]; then echo "new_sha sha=$sha (was $base_sha)";                     base_sha=$sha; fi

  sleep 150
done
```

Run via `Monitor` with `persistent: true` and a long `timeout_ms` (e.g., 3,600,000 = 1 hr — re-arm if you need longer).

**Poll interval.** `sleep 150` is the sweet spot. Shorter wastes API quota and prompt-cache. Longer than ~300s starts losing the prompt cache between wake-ups (Anthropic cache TTL is 5 min). Don't go past 300s for active PR watching.

**Sleep behavior.** Monitors freeze when the computer sleeps. On wake, the loop resumes and reads _current_ state — so terminal conditions (`MERGED`, `CLOSED`, persistent `BEHIND`) will fire correctly on resume. Transient events that came and went during sleep are lost; the monitor can only see the snapshot at wake time.

**The fire-and-forget mistake.** Don't emit on conditions you can't act on. For example: emitting `BEHIND` every poll while you're waiting on a human re-approval will spam the chat. Track whether you've already reacted to a state and only emit on the _first_ poll where it appears (track a `prev_<state>` variable).

## Cross-verify status before reporting

GitHub exposes the same PR state through multiple endpoints — and they don't always agree at the same instant. A single `gh pr view` is one snapshot; a confident report needs at least two independent views that converge. When they disagree, the disagreement itself is the answer — don't pick the convenient one and move on.

**Use cases where divergence is common:**

- **Run-level `status` vs. per-job `status`.** `gh run view --json status` can read `in_progress` while every job inside reports `completed`. Often means a post-step or summary job is still finalizing. To know what's really happening, list jobs (`.jobs[]`) and their steps — surface the actively-running step (e.g., `Run Claude Code ← in_progress`) rather than parroting the run-level summary.
- **`gh pr checks` vs. raw check-runs API.** `gh pr checks` aggregates and filters. `gh api repos/<o>/<r>/commits/<sha>/check-runs` is raw and shows everything reported on the head commit, including app source. When the user is looking at the PR UI and you're disagreeing, the raw API is more likely to match what they see.
- **`statusCheckRollup.state` vs. legacy combined `commits/<sha>/status`.** Rollup includes check-runs; combined status only includes statuses posted via the legacy API. A `pending` combined status with empty `statuses[]` plus an `SUCCESS` rollup usually means everything reports via check-runs and combined status is unused for this repo — but it can also mean a required `claude` (or other) status is genuinely missing for the SHA. Decide by reading branch-protection's required contexts and comparing against what's actually on the SHA.
- **Comment counts (`pulls/<N>/comments` vs. UI).** Counts can include outdated/resolved comments depending on the filter. When the user says "you missed X" and your count seems complete, list comments by `created_at` since the last reference point and read each — don't trust an aggregate length.

**Practice: show the evidence, not the conclusion.** When reporting state in chat, surface the raw data the user can verify themselves — the job step trace, the specific check name and its conclusion, the open thread count from GraphQL. "It's running" gets pushback. "Step 12 of 18 (`Run Claude Code`) is in_progress, started 7 minutes ago" doesn't. Reach for the precise quote when the user is questioning a claim.

**When two endpoints disagree on the same question**, that's a signal — surface both and reason about which represents reality:

> Run-level `in_progress`; job-level both completed `success`. Likely a post-step or summary finalizing — treating as "done modulo cleanup" but won't claim merge-ready until the run flips to completed.

The user will accept ambiguity surfaced honestly. They won't accept a confident answer that turns out to be wrong.

## Proactive completeness in status updates

The user shouldn't have to ask "what's the PR link?" or "is it running?" or "did anything new land?" five times across a long PR cycle. Each ask costs a round trip and a small chip of trust. Pre-empt them.

**Every material event update should include:**

- **The PR URL.** Always. Even on the third update in a row. The user is reading these messages across hours, on different devices, while context-switching to other work — re-pasting the link costs nothing and saves the "pr link?" round trip every time. Same applies to run URLs when you reference a specific Action run.
- **Evidence, not summary.** When you say "running," show the in-progress step from the job trace. When you say "passed," list the checks by name. The "show the evidence" rule from the Cross-verify section applies to every status update, not just contested ones.
- **The current blocker(s) in one line.** Even if it's the same blocker as last update. "Still waiting on `<reviewer>`'s approval — all checks green, all threads resolved" beats "still waiting" because the next time the user asks "what's left?" you've already answered.
- **What you're doing next.** "Watcher is armed; will fire on review or new SHA" beats trailing silence.

**Specifically after `hb:pr-address` finishes**, don't just announce "address job done." Immediately:

1. Read the new top-level run summary comment (the `## PR Re-Address` block).
2. List any new inline comments by `created_at > <last-cycle-cutoff>`.
3. Read the new replies on existing threads (the "Fixed in `<sha>`" / "Marked for your judgment" pattern).
4. Classify each open thread: auto-fix-already-applied, judgment-needed, dismissable.
5. Surface the open judgment items to the user in one message — your read on each, plus the recommended action. Don't wait for the user to say "look through them."

The user kicked off the loop so they could _not_ watch the PR. Make that worth it.

A few things that look reasonable but bite:

- **Polling in a tight in-conversation `sleep` loop.** Burns turns, burns prompt-cache. Use `Monitor`.
- **Self-approving / asking the PR author to approve.** Doesn't work, wastes a round trip. Re-request the previous reviewers instead.
- **Posting Slack / Linear updates without explicit go-ahead.** First reply needs the user's nod; subsequent auto-replies on the same thread are OK once they've greenlit it.
- **Acting on `mergeable: UNKNOWN`.** GitHub is still computing — sleep ~10s and re-check.
- **Reporting a single-endpoint status without cross-verifying.** See the section above. Default to two views; surface divergence honestly.
- **Manually replying to review threads via `gh api`** instead of letting `hb:pr-address` do it via `reporter_post.py`. You'll bypass the formatting helper (`escape_html_tags`, suggestion-block fencing, dedup against prior replies). Always go through the skill.
- **Force-pushing during shepherd flow.** Don't. Compounds approval-dismissal headaches and confuses reviewers refreshing mid-review.
- **Re-running `hb:pr-address` after the first invocation already handed off decides.** `pr-address` short-circuits in this case (the "already-handed-off" pattern); recognize the signal and switch to `pr-address-interactive` if the user wants to walk through them.

## Closure shape

When the PR merges and any cleanup is offered/done, produce a single concise summary the user can scan at a glance:

```
✓ Merged · PR #<N> · <merge-commit-sha>
  Linear: <ticket-id> → <new-status>
  Branch deleted: <branch-name>
  Next: <deploy marker | none>
```

State `result:` with a one-line headline that's self-contained — someone who never saw the ask should understand what was delivered. The watch terminates with the merge; the `/goal` Stop hook auto-clears on the merge confirmation. There is no downstream chain — don't tell the user to clear the goal manually.
