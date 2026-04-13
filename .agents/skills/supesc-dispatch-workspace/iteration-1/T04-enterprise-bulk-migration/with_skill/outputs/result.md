# SUPESC-T04 Triage Result

## Ticket

- **ID:** SUPESC-T04
- **Title:** Enterprise customer requesting bulk migration of 5,000 clients to new LO assignments
- **Customer:** Riley Romeo (Acme Lending Co admin)
- **Requester:** @panda.sales

## Routing Decision

**Route to: Enterprise**

## Actions (Dry Run)

1. **Move ticket** to the **Enterprise** team, keep in **Triage** status.
2. **Post routing comment** (reply to Slack-synced thread).

## Routing Comment

**Routing: Enterprise**

Acme Lending Co needs ~5,000 clients reassigned across LOs as part of a territory restructure. They have a CSV mapping file ready and a hard deadline before their next digest send on the 15th. This is a bulk client team membership migration for an enterprise customer - squarely in Enterprise's wheelhouse. The existing bulk transfer infrastructure in Mikasa (BulkOperation model, BulkTransferClients interactor, and the CreateTeamMembershipsWithCustomer service) can handle the mechanics, but the CSV will need to be reviewed and the operations coordinated given the volume and the digest deadline.

## Reasoning

This ticket matches the Enterprise routing criteria from the skill's team routing guide: "Bulk migration/changes, enterprise-specific features, enterprise admin. Usually one-off requests."

Key factors:
- **Enterprise customer** (Acme Lending Co) with an enterprise subscription.
- **Bulk operation** involving 5,000 clients across multiple LOs - this is not a single account config issue (which would be VSB) or a platform behavior question.
- **CSV-based migration** - Mikasa has existing infrastructure for this: the `BulkTransferClients` interactor handles bulk operations via `BulkOperation` records, and `HomebotNetwork::CreateTeamMembershipsWithCustomer` handles bulk team membership creation. The Enterprise team is familiar with orchestrating these at scale.
- **Time-sensitive** - needs to complete before the next digest send on the 15th. The Enterprise team owns the relationship and can coordinate the execution timeline.
- No "through line" misdirection here: the surface issue and root cause are the same - a straightforward bulk LO reassignment request.

## Confidence

High. This is a textbook Enterprise routing per the guide's own description.
