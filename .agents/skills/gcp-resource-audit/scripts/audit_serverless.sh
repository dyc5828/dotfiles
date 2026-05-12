#!/usr/bin/env bash
# audit_serverless.sh — Cloud Functions, Cloud Run, App Engine, GKE.
# Usage: audit_serverless.sh <PROJECT_ID>

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

PROJECT="${1:?Usage: audit_serverless.sh <PROJECT_ID>}"
ENABLED_APIS="${ENABLED_APIS:-$(gcloud services list --enabled --project="$PROJECT" --format="value(config.name)" 2>/dev/null)}"

# Cloud Functions
if has_api "cloudfunctions.googleapis.com"; then
  section "Cloud Functions"
  run_gcloud gcloud functions list --project="$PROJECT" --regions=- \
    --format="table(name,state,updateTime)"
fi

# Cloud Run
if has_api "run.googleapis.com"; then
  region=$(gcloud config get-value run/region 2>/dev/null)
  if [[ -n "$region" && "$region" != "(unset)" ]]; then
    section "Cloud Run services ($region)"
    run_gcloud gcloud run services list --project="$PROJECT" --region="$region" \
      --format="table(metadata.name,status.url,status.latestReadyRevisionName)"
  else
    section "Cloud Run services"
    echo "(skipped — no default region set; run \`gcloud config set run/region <REGION>\` to enable enumeration, or loop over \`gcloud run regions list\`)"
  fi
fi

# App Engine
if has_api "appengine.googleapis.com"; then
  section "App Engine"
  status=$(gcloud app describe --project="$PROJECT" --format="value(servingStatus)" 2>/dev/null)
  if [[ -n "$status" ]]; then
    echo "servingStatus: $status"
    service_count=$(gcloud app services list --project="$PROJECT" --format="value(id)" 2>/dev/null | wc -l | tr -d ' ')
    echo "Services deployed: $service_count"
    if [[ "$service_count" != "0" ]]; then
      run_gcloud gcloud app versions list --project="$PROJECT" \
        --format="table(service,version.id,traffic_split,version.createTime,version.servingStatus)"
    fi
  else
    echo "(no App Engine application)"
  fi
fi

# GKE
if has_api "container.googleapis.com"; then
  section "GKE clusters"
  run_gcloud gcloud container clusters list --project="$PROJECT" \
    --format="table(name,location,currentMasterVersion,currentNodeCount,status)"
fi
