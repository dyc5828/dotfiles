# GCP Pricing Reference

Pricing for GCP resources changes regularly and varies by region. **Always verify the current rate** before quoting numbers in an audit report.

This file gives you a starting point and a list of canonical pricing pages to verify against during an audit.

## Snapshot rates (us-central1, captured 2024)

These rates worked at a known point in time. Treat them as orientation, not gospel.

### Persistent disks
- **PD Standard**: ~$0.04 / GB / month
- **PD Balanced**: ~$0.10 / GB / month
- **PD SSD**: ~$0.17 / GB / month
- **Hyperdisk Balanced**: ~$0.10 / GB / month

### Static IPs
- **Unattached / reserved static IP**: ~$0.012 / hour → ~$8.75 / month
- **Attached external IP on VM**: first IP per VM is free; additional IPs ~$0.005 / hour

### Cloud SQL (PostgreSQL or MySQL)
- **Per-vCPU (db-custom)**: ~$0.0413 / hour
- **Per-GB memory**: ~$0.0070 / hour
- **PD SSD storage**: ~$0.187 / GB / month
- **Stopped instance**: pays for storage only, no compute or memory

### Cloud Storage
- **Standard**: ~$0.020 / GB / month
- **Nearline**: ~$0.010 / GB / month
- **Coldline**: ~$0.004 / GB / month
- **Archive**: ~$0.0012 / GB / month
- Plus egress, operations, and retrieval fees that vary by class and region

### Cloud Load Balancer / forwarding rules
- First 5 forwarding rules: ~$0.025 / hour each, then scales with data processed
- Outbound data processing: ~$0.008–0.012 / GB depending on region

## How to look up current pricing

For any resource you find during an audit, the canonical sources are:

| Resource | Pricing URL |
|---|---|
| Compute (VMs, disks, IPs) | https://cloud.google.com/compute/disks-image-pricing and https://cloud.google.com/compute/all-pricing |
| Cloud SQL | https://cloud.google.com/sql/pricing |
| Cloud Storage | https://cloud.google.com/storage/pricing |
| BigQuery | https://cloud.google.com/bigquery/pricing |
| Cloud Functions | https://cloud.google.com/functions/pricing |
| Cloud Run | https://cloud.google.com/run/pricing |
| App Engine | https://cloud.google.com/appengine/pricing |
| GKE | https://cloud.google.com/kubernetes-engine/pricing |
| Cloud Load Balancer | https://cloud.google.com/vpc/network-pricing |
| Pub/Sub | https://cloud.google.com/pubsub/pricing |
| Artifact Registry | https://cloud.google.com/artifact-registry/pricing |

The [GCP Pricing Calculator](https://cloud.google.com/products/calculator) can also model specific configurations.

## Quick mental math

For SSD-heavy zombies, disk cost is usually the biggest line item. As sanity checks:

- 1 TB PD SSD ≈ $170 / month
- 1 TB PD Standard ≈ $40 / month
- 100 GB Cloud SQL on PD SSD (stopped) ≈ $17 / month
- 1 unattached reserved static IP ≈ $9 / month

If your back-of-envelope math is more than ~25% off from a fresh lookup, re-verify before quoting in a report.
