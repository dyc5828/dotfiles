# gcp-resource-audit

A skill for auditing Google Cloud projects and organizations: inventory billable resources, identify zombies and orphans, estimate monthly cost, and surface security findings. Output is structured, agnostic to what the caller does next, and the caller composes the final report.

## When this triggers

- "audit GCP" / "review GCP" / "GCP cleanup"
- "what's running in this project"
- The user shares a GCP project ID or organization ID and asks about its state
- Proactively when GCP spending, shutdowns, or migrations come up

See `SKILL.md` for the full triggering description and workflow.

## Layout

```
gcp-resource-audit/
├── SKILL.md             primary skill instructions (read this first)
├── README.md            this file
├── references/
│   ├── pricing.md       GCP pricing cheatsheet + canonical lookup URLs
│   └── eol-versions.md  EOL status for managed runtimes / databases
└── scripts/
    ├── lib.sh                shared helpers (run_gcloud, has_api, section)
    ├── audit_org.sh          org-level survey + optional drill-in
    ├── audit_project.sh      per-project orchestrator
    ├── audit_compute.sh      VMs, disks, IPs, snapshots, forwarding, VPC, firewall
    ├── audit_sql.sh          Cloud SQL instances
    ├── audit_serverless.sh   Cloud Functions, Run, App Engine, GKE
    ├── audit_data.sh         Storage, BigQuery, Pub/Sub
    └── audit_iam.sh          IAM bindings, service accounts, SA keys, API keys
```

## Prerequisites

`gcloud`, `jq`, `bq`, `column` on PATH. `gcloud` must be authenticated. See SKILL.md's Prerequisites section for details and install hints.

## Quick start

```bash
# Audit a single project
scripts/audit_project.sh <PROJECT_ID>

# Survey an org (project list + billing assignments)
scripts/audit_org.sh <ORG_ID>

# Survey + drill into every project in the org
scripts/audit_org.sh <ORG_ID> --drill-in

# Run a single category
scripts/audit_compute.sh <PROJECT_ID>
```

## Output markers

Each section may print one of these instead of resource rows:

| Marker | Meaning |
|---|---|
| `(none)` | Command succeeded, zero resources |
| `(API not enabled)` | The category's API is disabled on this project |
| `(no access)` | Your account lacks permission to read this category |
| `(error: ...)` | Anything else; first line of stderr included |
