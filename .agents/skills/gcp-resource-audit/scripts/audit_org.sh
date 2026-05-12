#!/usr/bin/env bash
# audit_org.sh — survey all projects under an org, group by billing account,
# optionally drill into each with a full per-project audit.
# Usage: audit_org.sh <ORG_ID> [--drill-in]

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

ORG_ID="${1:?Usage: audit_org.sh <ORG_ID> [--drill-in]}"
DRILL_IN=0
[[ "${2:-}" == "--drill-in" ]] && DRILL_IN=1

echo "# Org survey: $ORG_ID"

section "Projects under org"
projects=$(gcloud projects list --filter="parent.id=$ORG_ID" \
  --format="value(projectId)" 2>/dev/null)

if [[ -z "$projects" ]]; then
  echo "(no projects found, or no access to the org)"
  exit 0
fi

echo "$projects" | wc -l | awk '{print "Project count: " $1}'

section "Billing assignments"
{
  echo "PROJECT_ID|BILLING_ACCOUNT|ENABLED"
  while IFS= read -r p; do
    info=$(gcloud billing projects describe "$p" --format="json" 2>/dev/null)
    if [[ -n "$info" && "$info" != "null" ]]; then
      acct=$(echo "$info" | jq -r '.billingAccountName // "none"' | sed 's|billingAccounts/||')
      en=$(echo "$info" | jq -r '.billingEnabled')
    else
      acct="(no access)"; en="?"
    fi
    echo "$p|$acct|$en"
  done <<<"$projects"
} | column -t -s '|'

if [[ $DRILL_IN -eq 1 ]]; then
  while IFS= read -r p; do
    echo ""
    echo "---"
    "$SCRIPT_DIR/audit_project.sh" "$p"
  done <<<"$projects"
fi
