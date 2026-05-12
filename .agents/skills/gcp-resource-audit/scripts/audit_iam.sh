#!/usr/bin/env bash
# audit_iam.sh — IAM bindings, API keys, service accounts.
# Usage: audit_iam.sh <PROJECT_ID>

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

PROJECT="${1:?Usage: audit_iam.sh <PROJECT_ID>}"

# Project-level IAM bindings — focus on user accounts and elevated roles. These
# are the ones most likely to surface stale humans (former employees, external
# parties, bouncing mailboxes).
section "IAM bindings (user accounts + elevated roles)"
run_gcloud gcloud projects get-iam-policy "$PROJECT" \
  --flatten="bindings[].members" \
  --filter="bindings.members:user:* OR bindings.role:roles/owner OR bindings.role:roles/editor" \
  --format="table(bindings.members,bindings.role)"

# Service accounts — capture once as JSON, render the human-readable table
# here, and reuse the parsed email list for the keys iteration below so we
# only make one API call.
section "Service accounts"
sa_err=$(mktemp)
sa_json=$(gcloud iam service-accounts list --project="$PROJECT" --format="json" 2>"$sa_err")
sa_rc=$?
sa_emails=""
if [[ $sa_rc -ne 0 ]]; then
  if is_permission_error "$sa_err"; then
    echo "(no access)"
  else
    echo "(error: $(head -n1 "$sa_err"))"
  fi
elif [[ -z "$sa_json" || "$sa_json" == "[]" || "$sa_json" == "null" ]]; then
  echo "(none)"
else
  {
    printf "EMAIL\tDISPLAY_NAME\tDISABLED\n"
    echo "$sa_json" | jq -r '.[] | [.email, (.displayName // ""), (.disabled // false | tostring)] | @tsv'
  } | column -t -s $'\t'
  sa_emails=$(echo "$sa_json" | jq -r '.[].email')
fi
rm -f "$sa_err"

# User-managed service account keys — long-lived JSON keys are a leak risk.
# Skip Google-managed keys (rotated automatically, uninteresting for audit).
section "User-managed service account keys"
if [[ -z "$sa_emails" ]]; then
  echo "(no service accounts or no access — see section above)"
else
  any_output=0
  while IFS= read -r sa; do
    keys=$(run_gcloud gcloud iam service-accounts keys list \
      --iam-account="$sa" --managed-by=user \
      --format="value(name.basename(),validAfterTime,validBeforeTime)")
    case "$keys" in
      "(none)")
        # No user-managed keys on this SA — the common, healthy case. Skip.
        ;;
      "(no access)"|"(API not enabled)"|"(error: "*)
        # Surface non-empty-but-failed markers so the caller knows we tried.
        any_output=1
        echo
        echo "**$sa**"
        echo "$keys"
        ;;
      *)
        any_output=1
        echo
        echo "**$sa**"
        echo "$keys" | awk -F'\t' '{print "- key: " $1 " | created: " $2 " | expires: " $3}'
        ;;
    esac
  done <<<"$sa_emails"
  [[ $any_output -eq 0 ]] && echo "(none — no user-managed keys across any service account)"
fi

# API keys — flag unrestricted ones explicitly with a warning marker. Capture
# stderr separately so permission denied is distinguishable from "no keys".
section "API keys"
keys_err=$(mktemp)
keys_json=$(gcloud services api-keys list --project="$PROJECT" --format="json" 2>"$keys_err")
keys_rc=$?
if [[ $keys_rc -ne 0 ]]; then
  if is_permission_error "$keys_err"; then
    echo "(no access)"
  else
    echo "(error: $(head -n1 "$keys_err"))"
  fi
elif [[ -z "$keys_json" || "$keys_json" == "[]" || "$keys_json" == "null" ]]; then
  echo "(none)"
else
  echo "$keys_json" | jq -r '
    .[] |
    "- " + (.displayName // "unnamed") +
    " | created: " + .createTime +
    " | " + (
      if (.restrictions.apiTargets // []) | length > 0
      then "restricted to: " + ((.restrictions.apiTargets | map(.service)) | join(", "))
      else "UNRESTRICTED ⚠️"
      end
    )
  '
fi
rm -f "$keys_err"
