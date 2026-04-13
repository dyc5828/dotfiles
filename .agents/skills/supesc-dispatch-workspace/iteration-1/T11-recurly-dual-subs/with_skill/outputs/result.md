# SUPESC-T11 Triage Result

## Ticket

- **ID:** SUPESC-T11
- **Title:** Recurly showing duplicate subscriptions after HBN partner upgraded to paid plan
- **Labels:** Escalation, HBN
- **Relevant Area:** Customer - Billing

## Action: Route to Customer Experience

**Category B** - Routable to a team.

## Routing

**Routing: Customer Experience**

This is an HBN partner-to-paid-plan transition issue. When an HBN Preferred Partner upgrades to a paid Agent Partner plan, the system is supposed to cancel the old HBN subscription in Recurly before creating the new paid subscription. The duplicate subscription showing in Recurly is likely a stale "canceled but not yet expired" subscription from the old HBN plan, not a true double-billing scenario. However, the fact that this is the third occurrence in a month suggests a pattern that needs investigation by the team that owns HBN and partner lifecycle.

## Codebase Findings

The upgrade path for HBN preferred partners is handled in `Onboarding::Create` (`mikasa/app/interactors/onboarding/create.rb`).

### How the transition works

1. `find_or_create_customer_profile` (line 120-149) detects existing preferred partners via `on_preferred_partner_plan?` or `preferred_partner?` state.
2. `cancel_hbn_subscription` (lines 341-349) is called to clean up the old subscription. It does two things:
   - Calls `BillingProvider.trigger(:cancel, subscription)` if the plan syncs with Recurly
   - Sets the local subscription state to `expired`
3. `create_subscription` (lines 207-224) then creates a brand new subscription on the target paid plan and sends it to Recurly via `BillingProvider.trigger(:create, subscription)`.
4. `activate_if_preferred_partner` (lines 335-339) transitions the customer state from `preferred_partner` to `active`.

### Where the duplicate likely comes from

The `on_subscription_cancel` billing provider method (`mikasa/app/models/billing_provider/subscription.rb`, line 79) cancels subscriptions in Recurly with `timeframe: 'term_end'`. This means the Recurly-side subscription does not immediately disappear - it stays in a "canceled" state until the end of its current billing term, then expires.

For HBN Preferred Partner plans, the `current_period_ends_at` is often set far into the future (the ticket mentions "a far-future expiration"). So after the upgrade:

- **In Mikasa:** The old subscription is marked `expired` locally (line 348 of `cancel_hbn_subscription`)
- **In Recurly:** The old subscription is merely "canceled" with `term_end` timeframe, meaning it persists as canceled until that far-future date. Meanwhile, the new paid subscription is created and active.

The result is two subscriptions visible in Recurly's UI - one canceled-but-not-yet-expired (old HBN plan) and one active (new paid plan). This looks like a double-billing risk to the customer, even though the canceled subscription should not actually charge.

### Two possible paths this is happening

**Path A - Active HBN partner upgrading (line 129-136):** The customer is `active` and `on_preferred_partner_plan?`. `cancel_hbn_subscription` is called, which uses `BillingProvider.trigger(:cancel, ...)` with `term_end` timeframe. The old sub lingers in Recurly.

**Path B - Preferred partner state upgrading (line 335-339):** The customer was already transitioned to `preferred_partner` state via `TransitionToPreferredPartner` (`mikasa/app/domains/homebot_network/transition_to_preferred_partner.rb`). That domain object also calls `BillingProvider.trigger(:cancel, subscription)` with the same `term_end` approach. If the subscription was already expired locally, `cancel_hbn_subscription` in Onboarding skips the Recurly cancel (line 344: `return if subscription.expired?`), but the Recurly-side sub may still be lingering from the earlier transition.

### The fix would likely involve

Changing the cancellation of HBN subscriptions to use immediate termination rather than `term_end`. The `on_subscription_terminate` method (line 97-101 of `billing_provider/subscription.rb`) calls `recurly_client.terminate_subscription` which would immediately remove the subscription from Recurly. Alternatively, the HBN cancellation path could use a custom timeframe or call terminate directly for HBN plan subscriptions specifically.

### The customer is NOT being double-billed

A canceled Recurly subscription with `term_end` timeframe should not generate new invoices. The concern is cosmetic/confusing rather than a real billing issue. But this should still be cleaned up since it's causing recurring customer anxiety.

## Key Files

- `mikasa/app/interactors/onboarding/create.rb` - Main upgrade path, `cancel_hbn_subscription` method (lines 341-349)
- `mikasa/app/models/billing_provider/subscription.rb` - `on_subscription_cancel` uses `term_end` timeframe (line 79)
- `mikasa/app/domains/homebot_network/transition_to_preferred_partner.rb` - State-based transition also calls `BillingProvider.trigger(:cancel, ...)`
- `mikasa/app/models/plan.rb` - Plan model, `syncs_with_recurly` flag
- `mikasa/app/domains/homebot_network/create_hbn_partner.rb` - HBN plan codes defined here

## Routing Comment (for Linear)

**Routing: Customer Experience**

When an HBN Preferred Partner upgrades to a paid plan, the old HBN subscription is canceled in Recurly with a `term_end` timeframe, which leaves it visible as "canceled" until its far-future expiration date. Meanwhile a new active subscription is created for the paid plan. The result is two subscriptions in Recurly - one canceled-but-lingering, one active. The customer is not actually being double-billed, but the visual is concerning. This is the third report in a month, so the HBN-to-paid transition path likely needs to terminate (not just cancel) the old subscription immediately. The relevant code is in `Onboarding::Create#cancel_hbn_subscription` and `BillingProvider::Subscription#on_subscription_cancel`.

## Dry Run

No Linear API calls were made. In a live triage, the actions would be:

1. Post the routing comment above as a reply to the Slack-synced comment thread on the ticket
2. Move the ticket to the **Customer Experience** team
3. Keep the ticket in **Triage** status for the team lead to prioritize
