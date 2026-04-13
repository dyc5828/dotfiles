# Triage: SUPESC-T04

## Routed to: Enterprise

## Triage Comment

Routing to **Enterprise**. This is a bulk LO territory reassignment for Acme Lending Co - an enterprise customer requesting ~5,000 client-to-LO remappings from 12 departing LOs to 8 new LOs via CSV, with a hard deadline before the next digest send on the 15th.

The existing tooling supports this workflow. Mikasa has a `BulkOperation` model with a `transfer-clients` action that drives `BulkTransferClients`, which creates `ClientTransfer` records and queues `TransferClientJob` per client. For the many-to-many mapping here (12 source LOs to 8 destination LOs), this will likely require multiple bulk operations or a rake task that iterates the CSV and calls `ReplaceTeamMembership` per row (discard old `ClientTeamMembership`, create new one). Lockbox HPAdmin also supports TableFlow CSV imports for bulk operations.

Key considerations for the executing team:
- The CSV mapping file needs validation before execution - confirm each row maps a client to a valid destination LO customer profile.
- The digest deadline on the 15th means the reassignment must complete and the new LO associations must be active before digest generation begins.
- At 5,000 clients this is well within the scale that the async job infrastructure handles, but should be run during off-peak hours given the volume.
- Coordinate with the customer on whether departing LOs should be deactivated after the migration completes.
