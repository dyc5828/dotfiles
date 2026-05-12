#!/usr/bin/env bash
# audit_project.sh — full per-project audit, composing all audit_*.sh scripts.
# Usage: audit_project.sh <PROJECT_ID>

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

PROJECT="${1:?Usage: audit_project.sh <PROJECT_ID>}"

echo "## $PROJECT"

# Billing assignment
billing_json=$(gcloud billing projects describe "$PROJECT" --format="json" 2>/dev/null)
if [[ -n "$billing_json" && "$billing_json" != "null" ]]; then
  account=$(echo "$billing_json" | jq -r '.billingAccountName // "none"' | sed 's|billingAccounts/||')
  enabled=$(echo "$billing_json" | jq -r '.billingEnabled')
  echo ""
  echo "**Billing account:** $account"
  echo "**Billing enabled:** $enabled"
else
  echo ""
  echo "**Billing:** (no access or no billing assignment)"
fi

# Cache enabled APIs once for sub-scripts to reuse.
export ENABLED_APIS
ENABLED_APIS=$(gcloud services list --enabled --project="$PROJECT" \
  --format="value(config.name)" 2>/dev/null)

section "Enabled APIs (non-default)"
if [[ -z "$ENABLED_APIS" ]]; then
  echo "(none or no access)"
else
  echo "$ENABLED_APIS" \
    | grep -vE "^(serviceusage|cloudapis|monitoring|logging|cloudtrace|servicemanagement|servicecontrol|oslogin|storage-api|storage-component|bigquerystorage|datastore|cloudasset)\.googleapis\.com$"
fi

# Run each category script. Each handles its own API pre-check.
"$SCRIPT_DIR/audit_compute.sh"    "$PROJECT"
"$SCRIPT_DIR/audit_sql.sh"        "$PROJECT"
"$SCRIPT_DIR/audit_serverless.sh" "$PROJECT"
"$SCRIPT_DIR/audit_data.sh"       "$PROJECT"
"$SCRIPT_DIR/audit_iam.sh"        "$PROJECT"
