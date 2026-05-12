---
name: gcp-resource-audit
description: Audit Google Cloud projects to inventory billable resources, identify zombies and orphans, estimate monthly cost, and categorize each project's state (active, zombie, empty, API key holder). Use whenever the user wants to audit GCP, find unused resources, investigate shutdown candidates, or understand what a forgotten project is doing. Trigger on "audit GCP", "review GCP", "GCP cleanup", "what's running in this project", or whenever the user shares a GCP project or org ID and wants its state. Use proactively when GCP spending, shutdowns, or migrations come up — the audit is usually the first useful step.
---

# GCP Resource Audit

A repeatable workflow for auditing Google Cloud projects — single project, several projects, or an entire organization — so you can confidently answer: *what's actually running here, what is it costing, and how would I categorize its state?*

The output is a structured inventory plus categorization. It is intentionally agnostic about what the caller does next (delete, archive, document, file tickets) — this skill produces the findings; the caller composes the report and decides what counts as "waste."

## How to use this skill

The skill bundles a small toolkit of bash scripts under `scripts/` and two reference docs under `references/`. The general flow is:

1. Establish scope (single project vs whole org) — see "Input modes"
2. (Optional, with user confirmation) Grant viewer access via org-admin shortcut — see Step 2
3. Run the enumeration scripts to produce a resource inventory
4. Categorize each project by archetype
5. Look up current pricing for the resources you found and estimate monthly cost
6. Surface security and hygiene findings (unrestricted API keys, EOL versions, stale IAM)
7. Compose findings into whatever format the caller wants

The scripts are designed to be called individually if you only care about one category, or composed via `audit_project.sh` / `audit_org.sh` for the full sweep.

## Prerequisites

The bundled scripts require these CLIs on the caller's PATH:

- `gcloud` — Google Cloud SDK (https://cloud.google.com/sdk/docs/install)
- `jq` — JSON processor (`brew install jq` on macOS)
- `bq` — BigQuery CLI (ships with gcloud; install with `gcloud components install bq` if absent)
- `column` — table formatter (built into macOS and most Linux distros)

**Verify these are installed before running any of the bundled scripts.** A quick `command -v gcloud jq bq column` is enough — if anything comes back empty, stop and walk the user through installing it. The scripts intentionally do not check for dependencies themselves; running them in a broken environment produces silently misleading output (empty results, false "(API not enabled)" markers), which is worse than failing fast with a clear install hint.

The scripts also set `CLOUDSDK_CORE_DISABLE_PROMPTS=1` so gcloud commands that would otherwise prompt for region, project, or confirmation fail fast instead of hanging on stdin.

Additionally verify `gcloud auth list` shows an active account before running the audit. An unauthenticated gcloud will trigger "(no access)" markers for every category, which is technically correct but useless.

## Be smart when things go wrong

Real audits hit edge cases the bundled scripts don't anticipate: regional defaults that aren't set, services that have been renamed, gcloud commands that behave differently between project generations, output formats that drift over time. When a script returns unexpected results or a gcloud call fails, **read the error, infer what the step was trying to accomplish, and find a working alternative**. Don't grind on a broken command for ten retries — step back, look at what the audit needs at that point, and use a different gcloud subcommand, the console, Cloud Asset Inventory (`gcloud asset search-all-resources`) for bulk enumeration, or whatever else gets you the same information.

The bundled scripts are a starting harness, not a contract. If you find a better command or a cleaner path during an audit, use it.

## When to use this

Trigger whenever someone wants a clear picture of what a GCP project or organization contains. Common situations:

- Someone inherited an org or project and doesn't know what's in it
- A billing review surfaced suspicious spend and we want to know what's driving it
- A migration or shutdown is being considered and we need a "do not touch" inventory
- A team is decommissioning a legacy product and wants to confirm nothing is still live
- A security review wants to know what's exposed, including unrestricted API keys

Don't gate yourself on the user using the exact phrase "audit" — if they're asking what's in a project, what's costing money, or whether a project is safe to shut down, this skill applies.

## Input modes

The user may give you:

- **A single project ID** (e.g., `my-project-123`) → audit just that project deeply. Use `scripts/audit_project.sh <PROJECT_ID>`.
- **An organization ID** or org domain (e.g., `1003138529567`, `example.com`) → discover all projects under the org first, then audit each. Use `scripts/audit_org.sh <ORG_ID>` for the survey pass, and `scripts/audit_org.sh <ORG_ID> --drill-in` to follow up with per-project audits on everything the survey turns up.
- **An ambiguous reference** (e.g., "audit our legacy GCP org") → list orgs the user has access to with `gcloud organizations list` and ask which they meant.

Adapt the depth of audit to the input:

- Single project → exhaustive resource enumeration.
- Whole org with many projects → start with a survey pass (project list, billing assignments, enabled APIs per project), then drill into each project that has anything worth investigating. Skip empty/ghost projects after a one-line note.

## Step 1: Discovery

Before touching any resources, establish the ground truth: what projects exist, where they live, and who's paying.

For an org-level audit, `audit_org.sh` does this in one shot: lists every project under the org and tabulates billing assignments. Look at the output and surface two things to the user immediately:

1. **Billing account groupings.** Multiple projects on the same billing account often share an owner or a payment instrument. Projects on a non-default billing account are interesting — they're either intentionally separated (different team, different cost center) or accidentally orphaned. Call these out.
2. **Enabled APIs (next step).** The set of enabled APIs on each project is a strong hint about its role even before you list resources. A project with only `geocoding-backend.googleapis.com` is an API key holder. A project with `compute`, `container`, `sqladmin`, and `cloudfunctions` is (or was) a real workload.

For a single project, run `audit_project.sh <PROJECT_ID>` directly — it handles billing and API discovery before resource enumeration.

## Step 2: Grant audit access (only with user confirmation)

If the user lacks viewer access on some projects in scope, the scripts will report `(no access)` for those projects' resources. You can sometimes grant viewer access via org-admin powers — but **this is a side effect and a permission elevation**. Do not run it silently.

First, check whether the shortcut is even available:

```bash
gcloud organizations get-iam-policy <ORG_ID> \
  --flatten="bindings[].members" \
  --filter="bindings.members:<USER_EMAIL>" \
  --format="value(bindings.role)"
```

If they have `roles/resourcemanager.organizationAdmin`, they (or you on their behalf) can grant `roles/viewer` on any project in the org. Before doing so:

- **Tell the user what you're about to do**, exactly which projects and which role, and that the binding will persist until revoked.
- **Ask explicit permission** to apply it. Don't infer consent from "audit this org" — the user may want to audit only what they already have access to.
- **Note that `roles/owner` is blocked** for cross-domain users by `ORG_MUST_INVITE_EXTERNAL_OWNERS`. Use `roles/viewer` (sufficient for audit) or `roles/editor` (if write access is later needed).
- **Track the grants you made** in your output. The caller typically wants them revoked post-audit, and you should make that easy.

Example confirmation prompt:

> I can grant you `roles/viewer` on these N projects via your org-admin permissions: `<list>`. This persists until revoked. Want me to proceed?

Only run `gcloud projects add-iam-policy-binding ...` after the user says yes.

Once granted, re-run the per-project audit — `(no access)` markers should turn into actual resource listings.

## Step 3: Resource enumeration

Per-project enumeration lives in the bundled scripts. Each script is independently executable and emits a markdown section for its category. They all share the same `lib.sh` helpers, which distinguish between empty results, missing API access, and permission denials — so you can trust the markers in the output.

| Script | What it covers |
|---|---|
| `audit_project.sh <PROJECT>` | Orchestrator — composes the rest in order |
| `audit_compute.sh <PROJECT>` | Instances, disks, static IPs, snapshots, forwarding rules |
| `audit_sql.sh <PROJECT>` | Cloud SQL instances |
| `audit_serverless.sh <PROJECT>` | Cloud Functions, Cloud Run, App Engine, GKE |
| `audit_data.sh <PROJECT>` | Storage buckets, BigQuery datasets, Pub/Sub |
| `audit_iam.sh <PROJECT>` | IAM bindings, service accounts, user-managed SA keys, API keys |

Call them à la carte when you only need one category (e.g., "is there active compute here?"), or `audit_project.sh` for the full sweep.

### Output markers to know

Each section may print one of these special markers instead of resource rows:

- `(none)` — command succeeded, zero resources
- `(API not enabled)` — the category's API is disabled on this project
- `(no access)` — your account lacks permission to read this category
- `(error: ...)` — anything else; the first line of stderr is included

Treat them as distinct findings. `(none)` means nothing's there; `(no access)` means you can't see what's there. They are not interchangeable.

### Activity and recency signals

When reading the script output, lean on the timestamp and state fields to spot orphans:

- `lastAttachTimestamp` / `lastDetachTimestamp` on disks
- `updateTime` on functions and Cloud Run services
- Cloud SQL state of `STOPPED` plus an old `createTime`
- `creationTimestamp` years old with no other activity

A resource untouched for 2+ years is strong evidence of orphan status, not just "old."

## Step 4: Categorize each project

After enumerating resources, label each project with one of these archetypes. The categorization makes the report scannable and helps the caller prioritize next steps.

- **Active** — running compute, SQL, GKE, or Cloud Run with recent activity. Don't propose action without deeper investigation.
- **Zombie** — had a real workload at some point; now everything is stopped, terminated, or detached, but billing-incurring resources remain (stopped SQL, orphaned disks, reserved IPs). Common shutdown candidate.
- **Empty** — APIs enabled but no resources, or only a couple of default APIs and nothing else. Ghost project — safe to delete after confirming the name doesn't carry intent.
- **API key holder** — only Maps, Geocoding, or similar consumer APIs enabled, with one or more API keys and no other resources. Decommissioning these requires verifying nothing external is still calling. Treat with higher caution when billing is enabled and there's evidence of recent API consumption.

Mix and match where helpful (e.g., "zombie with significant data" — no compute, but lots of buckets to triage).

## Step 5: Estimate monthly cost

Roll up the cost of running each project in its current state. Be neutral: this is what the project costs to maintain today, not a judgment about whether the cost is justified. That judgment depends on whether resources are in use, which is what the Step 4 categorization speaks to — the caller combines the two to decide whether a given line item is "waste" or "essential."

GCP pricing changes regularly and varies by region. **After enumeration, look up current pricing for each resource type you actually found before quoting any numbers.** See `references/pricing.md` for a snapshot of rates that worked at a known point in time, plus a list of canonical pricing URLs to verify against. The reference is a starting point, not a substitute for fresh lookup.

Workflow:

1. From the script output, list the billable resources you actually found (e.g., "1.1 TB PD SSD attached to stopped Cloud SQL", "4 reserved unattached static IPs").
2. For each, look up the current rate in the relevant region. Web search the cloud.google.com SKU page if you're not certain.
3. Compute approximate monthly cost per resource and sum per project.
4. For org-level audits, sum across projects and break the total down by archetype (active / zombie / empty). The bulk of spend often sits in zombies — that's the actionable signal.

Precision isn't the point; magnitude is. The reader should leave knowing whether this is $20/month or $2000/month.

## Step 6: Surface security and hygiene findings

Audits regularly surface things that aren't about cost but matter just as much. Always check for and report:

- **Unrestricted API keys** — `audit_iam.sh` flags keys with no restrictions explicitly with a ⚠️ marker
- **Service account keys** — long-lived JSON keys are a leak risk; deprecated where avoidable
- **EOL database versions or managed runtimes** — see `references/eol-versions.md` for current EOL status across Postgres, MySQL, Python, Node, etc. Verify with a fresh lookup if in doubt, since EOL dates move and Cloud SQL's deprecation schedule often trails the upstream project.
- **IAM bindings to user accounts that look stale** — former employees, external parties, mailboxes that bounce. `audit_iam.sh` emits the user-account binding list; cross-reference against current org membership where possible.

## Step 7: Compose the findings

The output format is intentionally flexible — the caller may want a Markdown report, a JSON blob, a Notion page, a Slack message, or just an inline summary. Default to a per-project section structure that contains:

- **Project name and categorization** (Active / Zombie / Empty / API key holder)
- **Billing account name and ID**, including whether `billingEnabled: true`
- **Resource inventory** — short, grouped by category, with cost-relevant details inline (sizes, states, last-activity dates)
- **Estimated monthly cost** for the project, with line items for anything significant
- **Security or hygiene notes** if applicable

Then top it with an org-level summary if you audited more than one project:

- Total projects audited, broken down by category
- Total estimated monthly cost
- Notable cross-project patterns (e.g., all projects on the same billing account; a deleted GKE cluster leaving orphans across multiple environments)

Resist the urge to recommend specific shutdown sequences or file tickets unless the user asks. This skill produces findings; the caller decides what to do with them.

## Common pitfalls

- **`gcloud compute X list` hangs** on projects without the compute API enabled. The bundled scripts check the API list first and skip categories whose APIs aren't enabled. Don't bypass this.
- **`gcloud projects describe` doesn't include billing.** Use `gcloud billing projects describe` for that, separately.
- **Output redaction.** GCP commands sometimes mask sensitive fields (API key strings, IP addresses) when displayed in certain formats. If you need the unredacted value, use `--format=json` and read the specific field.
- **Org-external Owner grant is blocked** by `ORG_MUST_INVITE_EXTERNAL_OWNERS`. Don't fight it — use `roles/viewer` or `roles/editor` for cross-domain audit access.
- **Default service accounts** (`<PROJECT_NUMBER>-compute@developer.gserviceaccount.com`) often show up as the only IAM binding on dormant projects. That's not a sign of activity; it's a sign that humans stopped touching the project but the default SA was never removed.
- **App Engine "SERVING" with zero versions** — don't take the project-level flag at face value. Check `gcloud app services list` and versions; `audit_serverless.sh` does both.
- **Cloud Run region defaults.** `gcloud run services list` needs a region. The bundled script reads `run/region` from gcloud config; if there's no default, it skips with a note. If you need cross-region enumeration, loop over `gcloud run regions list` explicitly.

## Communication style

When reporting findings, be concrete and avoid hedging. "Cloud SQL `api-prod` is stopped and consuming 1.1 TB of SSD storage" is more useful than "There may be some storage costs from the Cloud SQL instance." Numbers, dates, and resource names belong in the report; vague language doesn't.

If the user is non-technical (e.g., a director or VP reviewing the report), keep the executive summary plain-language and push the gcloud command-level detail into an appendix or methodology section.
