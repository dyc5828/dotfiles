#!/usr/bin/env bash
# audit_data.sh — Storage buckets, BigQuery datasets, Pub/Sub topics.
# Usage: audit_data.sh <PROJECT_ID>

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

PROJECT="${1:?Usage: audit_data.sh <PROJECT_ID>}"
ENABLED_APIS="${ENABLED_APIS:-$(gcloud services list --enabled --project="$PROJECT" --format="value(config.name)" 2>/dev/null)}"

# Storage buckets — the Storage API is enabled by default on most projects,
# so we always try this. The run_gcloud wrapper will mark (no access) if denied.
section "Storage buckets"
run_gcloud gcloud storage buckets list --project="$PROJECT" \
  --format="table(name,location,storageClass,timeCreated)"

# BigQuery — run_gcloud is a generic command wrapper, so it works for bq too.
if has_api "bigquery.googleapis.com"; then
  section "BigQuery datasets"
  run_gcloud bq ls --project_id="$PROJECT"
fi

# Pub/Sub
if has_api "pubsub.googleapis.com"; then
  section "Pub/Sub topics"
  run_gcloud gcloud pubsub topics list --project="$PROJECT" \
    --format="value(name.basename())"
fi
