#!/usr/bin/env bash
# audit_sql.sh — enumerate Cloud SQL instances.
# Usage: audit_sql.sh <PROJECT_ID>

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

PROJECT="${1:?Usage: audit_sql.sh <PROJECT_ID>}"
ENABLED_APIS="${ENABLED_APIS:-$(gcloud services list --enabled --project="$PROJECT" --format="value(config.name)" 2>/dev/null)}"

if ! has_api "sqladmin.googleapis.com"; then
  section "Cloud SQL"
  echo "(API not enabled)"
  exit 0
fi

section "Cloud SQL instances"
run_gcloud gcloud sql instances list --project="$PROJECT" \
  --format="table(name,databaseVersion,settings.tier,settings.dataDiskType,settings.dataDiskSizeGb,state)"
