#!/usr/bin/env bash
# audit_compute.sh — enumerate compute, disks, IPs, snapshots, forwarding rules.
# Usage: audit_compute.sh <PROJECT_ID>

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

PROJECT="${1:?Usage: audit_compute.sh <PROJECT_ID>}"
ENABLED_APIS="${ENABLED_APIS:-$(gcloud services list --enabled --project="$PROJECT" --format="value(config.name)" 2>/dev/null)}"

if ! has_api "compute.googleapis.com"; then
  section "Compute"
  echo "(API not enabled)"
  exit 0
fi

section "Compute instances"
run_gcloud gcloud compute instances list --project="$PROJECT" \
  --format="table(name,zone.basename(),machineType.basename(),status)"

section "Persistent disks"
run_gcloud gcloud compute disks list --project="$PROJECT" \
  --format="table(name,zone.basename(),sizeGb,type.basename(),status,lastDetachTimestamp)"

section "Static IPs"
run_gcloud gcloud compute addresses list --project="$PROJECT" \
  --format="table(name,region.basename(),status,users.basename())"

section "Disk snapshots"
run_gcloud gcloud compute snapshots list --project="$PROJECT" \
  --format="table(name,diskSizeGb,storageBytes,creationTimestamp)"

section "Forwarding rules"
run_gcloud gcloud compute forwarding-rules list --project="$PROJECT" \
  --format="table(name,region.basename(),IPAddress,target.basename())"

section "VPC networks"
run_gcloud gcloud compute networks list --project="$PROJECT" \
  --format="table(name,subnet_mode,bgp_routing_mode)"

section "Firewall rules"
run_gcloud gcloud compute firewall-rules list --project="$PROJECT" \
  --format="table(name,network,direction,priority,sourceRanges.list():label=SRC_RANGES,allowed[].map().firewall_rule().list():label=ALLOW,disabled)"
