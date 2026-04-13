# SUPESC-T18 Triage Result

## Ticket
- **ID:** SUPESC-T18
- **Title:** New customer signed up but HB Admin shows no subscription and Recurly has no record
- **Customer:** Oakley Oscar (REA, Agent Solo plan)

## Dry-Run Mode
No Linear API calls were made. All actions below are recommendations only.

## Determination: Category B - Routable to a team

## Recommended Routing: VSB

**Routing: VSB**

Oakley Oscar signed up for an Agent Solo plan 3 days ago and has a Lockbox account, but no subscription appears in HB Admin and Recurly has no record of him. He says he was charged. This is an individual REA account setup/billing issue that belongs with VSB.

There are two possible signup paths that could have led to this state, and both point to a failure in the billing provider integration during onboarding:

**Path 1 - Customer Admin onboarding flow (most likely for "signed up through the website"):**
The customer-admin frontend handles REA signups in two separate steps: first it creates or updates a billing account with a Recurly token (`POST /billing-accounts` or `PATCH /billing-accounts/:id`), then creates the subscription (`POST /subscriptions`). If the billing account step succeeded (which would explain the Lockbox account existing and the credit card charge) but the subscription creation step failed or never completed, the customer would end up in exactly this state - they have an account, can log in, but have no subscription in Mikasa or Recurly.

**Path 2 - Mikasa Onboarding::Create interactor (direct signup API):**
This path wraps everything in a single database transaction. It creates the billing account in Recurly, creates a Lockbox user, creates the customer profile, creates a subscription, and assigns it. If the Recurly `create_subscription` call failed (e.g., invalid plan code, Recurly API error, coupon validation failure), the whole transaction would roll back. But the billing account creation in Recurly and the Lockbox user creation are external API calls that happen before the rollback - so those persist even though the local database records get rolled back. This would also explain the symptoms: Lockbox account exists, possible Recurly billing account with a charge, but no subscription record in either Mikasa or Recurly.

**Key code details:**
- The Agent Solo plan (`hb-rea-solo` / `hb-agent-solo`) has `syncs_with_recurly: true`, so the `BillingProvider.trigger(:create, subscription)` call should create the subscription in Recurly. If this returned a failure, the subscription would not be saved locally.
- `BillingProvider.trigger` in `billing_provider.rb` line 44 checks `syncs_with_recurly?` - if it returns false, it skips Recurly entirely and returns `:ok`. But for the Agent Solo plan this flag is true, so Recurly should have been called.
- The Recurly billing account creation (`on_billing_account_create`) sends the billing token (credit card info) to Recurly. This is where the charge could have occurred even if the subscription creation later failed.

**What VSB should investigate:**
1. Check if a billing account exists in Mikasa for Oakley Oscar's email (the `billing_accounts` table). If it does, check its `recurly_ref` and look it up in Recurly directly - there may be a Recurly account with billing info but no subscription.
2. Check Sentry for errors around the time of signup (3 days ago) related to `Onboarding::Create`, `BillingProvider`, or `SubscriptionsController` for this email.
3. If a Recurly account exists with a charge but no subscription, the charge may be from account creation with a setup fee or an initial charge that didn't result in a subscription being provisioned. The customer may need a refund for that charge and a manual subscription setup, or the signup needs to be re-attempted.
4. If no billing account exists in Mikasa at all, the transaction likely rolled back. The Lockbox account and Recurly billing account would be orphaned external records. A fresh signup attempt through the normal flow might work, or the subscription needs to be manually provisioned.
