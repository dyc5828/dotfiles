# SUPESC-T04 Triage Result

**Ticket:** SUPESC-T04 - Enterprise customer requesting bulk migration of 5,000 clients to new LO assignments
**Customer:** Riley Romeo (Acme Lending Co admin)
**Action:** Route to team (Category B)

---

## Routing Decision

**Routing: Enterprise**

Acme Lending Co needs 5,000 clients reassigned from 12 departing LOs to 8 new LOs using a CSV mapping file, with a hard deadline before the next digest send on the 15th. This is a bulk client transfer operation for an enterprise customer - exactly the kind of one-off enterprise operational request this team handles.

## Codebase Investigation

The existing infrastructure supports this request well. There are two viable execution paths:

### Path 1: Rake task (preferred for this case)
The `transfer_clients:customers` rake task in `mikasa/lib/tasks/transfer_clients.rake` accepts a CSV file from S3 and a `corporate_profile_id`. It uses `CustomerClients::Transfer` which expects a CSV with columns: `current_email`, `new_email`, `client_email`. The service:
- Groups transfers by current LO -> new LO pair
- Looks up customer profiles scoped to the corporate profile
- Creates `ClientTransfer` records for auditability
- Enqueues `TransferClientJob` in batches of 1,000 per slice
- Reports missing clients and missing customer profiles at the end

This is the most direct path. Acme Lending Co's CSV just needs to be reformatted to have `current_email` (departing LO email), `new_email` (receiving LO email), and `client_email` (each client being transferred) - one row per client.

### Path 2: TableFlow import via Lockbox HPAdmin
The `Imports::TableFlow::TransferClients` service handles the same operation through the HPAdmin UI. Functionally equivalent but adds the TableFlow import layer on top.

### Path 3: BulkOperation model
The `BulkOperation` model supports `transfer-clients` actions but is designed for customer-profile-scoped transfers (one source -> one destination at a time). Less ideal for a 12-to-8 remapping.

## Key Considerations for the Enterprise Team

1. **Deadline sensitivity:** The 15th digest deadline is real. Transfers should be completed well before to allow time to verify. The rake task processes asynchronously via Sidekiq jobs, so 5,000 transfers should complete relatively quickly, but verification time matters.

2. **CSV format:** Riley's CSV mapping file will likely need reformatting. The rake task expects three columns: `current_email`, `new_email`, `client_email`. If she provided a mapping of LO-to-LO without individual client emails, someone will need to expand it (the `TransferAllClients` TableFlow service can transfer ALL clients from one LO to another, which may be simpler if entire books are moving).

3. **New LOs must exist in Mikasa:** The 8 new LOs need to have active customer profiles under Acme Lending Co's corporate profile before the transfer runs. If they're truly new hires, they may need to be imported first via `enterprise_imports:customers`.

4. **Audit trail:** `ClientTransfer` records are created automatically, providing a complete audit trail of every transfer.

## Dry-Run Actions

### Would post this top-level comment on the ticket:
> **Routing: Enterprise**
>
> Bulk client transfer for an enterprise customer - 5,000 clients across 12 departing LOs being reassigned to 8 new LOs via CSV. This is a standard enterprise operational request. Existing rake task infrastructure (`transfer_clients:customers`) supports this directly. Key detail: the 8 new LOs need active customer profiles under Acme Lending Co's corporate profile before the transfer can run, and Riley's CSV may need reformatting to match the expected format (`current_email`, `new_email`, `client_email`). Hard deadline is the 15th digest send.

### Would move the ticket to: Enterprise team
### Would keep status: Triage (for team lead to prioritize)
### Would NOT: assign to anyone, change priority, or modify labels
