# SUPESC-T11 Triage Result

**Ticket:** SUPESC-T11 - Recurly showing duplicate subscriptions after HBN partner upgraded to paid plan
**Action:** Route to team (Category B)
**Dry run:** Yes - no Linear API calls made

---

## Routing

**Routing: Customer Experience**

This is a known gap in the HBN-to-paid upgrade flow. When an HBN Preferred Partner upgrades to a paid Agent Partner plan, the system cancels the old HBN subscription in Recurly using a "term_end" timeframe instead of terminating it immediately. This leaves the old subscription lingering in Recurly until its term expires (which can be far in the future), while the new paid subscription is created on top of it. The customer is not being double-billed - the old subscription will not renew - but both show as "active" or "canceled" in Recurly's UI, which is confusing. Harper Hotel's account should have no billing risk, but the old HBN subscription may need to be manually terminated in Recurly to clean up the display. The fact that this is the third occurrence in a month suggests a code fix is warranted.

## Technical Detail

The root cause is in `mikasa/app/interactors/onboarding/create.rb`, method `cancel_hbn_subscription` (line 341-349):

```ruby
def cancel_hbn_subscription(customer_profile)
  subscription = customer_profile.subscription
  return unless subscription.present?
  return if subscription.expired?

  BillingProvider.trigger(:cancel, subscription) if subscription.syncs_with_recurly?

  subscription.update!(state: :expired)
end
```

This calls `BillingProvider.trigger(:cancel, ...)`, which routes to `on_subscription_cancel` in `mikasa/app/models/billing_provider/subscription.rb` (line 70-95). That method uses Recurly's `cancel_subscription` API with `timeframe: 'term_end'`:

```ruby
resp = recurly_client.cancel_subscription(
  subscription_id: "uuid-#{subscription.recurly_ref}",
  body: { timeframe: 'term_end' }
)
```

The `term_end` timeframe tells Recurly to let the subscription run until its current billing period ends and then expire it. For HBN preferred partner plans that may have been set up with long or indefinite terms, this means the subscription persists in Recurly for a long time even though it's marked `expired` locally in Mikasa.

Meanwhile, `Onboarding::Create#create_subscription` (line 207-224) creates a brand new subscription on the same billing account for the paid plan. The result: two subscriptions visible in Recurly on the same account.

The fix would be to use `BillingProvider.trigger(:terminate, subscription)` instead of `:cancel` in `cancel_hbn_subscription`, which calls `recurly_client.terminate_subscription` and removes the subscription from Recurly immediately. This is appropriate because HBN preferred partner subscriptions are free/zero-cost, so there's no proration or refund concern.

The same pattern exists in `mikasa/app/domains/homebot_network/transition_to_preferred_partner.rb` (line 38), which also uses `:cancel` rather than `:terminate`.

## Routing Reasoning

This routes to **Customer Experience** because HBN partner management, partner upgrades, and the preferred partner flow are CEP/HBN domain features owned by that team. The root cause is in the onboarding upgrade path for HBN partners, which is CX-owned code. While the symptom shows up in billing/Recurly, the fix belongs in the HBN transition logic, not in billing infrastructure.

## Immediate Resolution for Harper Hotel

Someone with Recurly admin access can manually terminate the old HBN preferred partner subscription on Harper's account. This will clean up the duplicate display. There is no double-billing risk - the old HBN plan is free.

## Draft Routing Comment

```
**Routing: Customer Experience**

When an HBN Preferred Partner upgrades to a paid plan, the old HBN subscription gets "canceled at term end" in Recurly instead of being terminated immediately. Since HBN plans can have long or indefinite terms, this leaves the old subscription lingering in Recurly alongside the new paid one. Harper Hotel is not being double-billed - the old HBN plan is free - but both subscriptions show up in Recurly, which is understandably confusing. This is the third time this has come up in a month, so a code fix to terminate (rather than cancel-at-term-end) the HBN subscription during upgrade would prevent it from recurring. The relevant code is in `Onboarding::Create#cancel_hbn_subscription`.

For Harper's account specifically, the old HBN subscription can be manually terminated in Recurly to clean up the display.
```
