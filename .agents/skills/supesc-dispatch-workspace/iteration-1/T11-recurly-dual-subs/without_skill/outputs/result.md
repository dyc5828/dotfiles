## Triage Result

**Ticket:** SUPESC-T11 - Recurly showing duplicate subscriptions after HBN partner upgraded to paid plan
**Routed to:** VSB
**Confidence:** High

## Routing Rationale

This is a billing/subscription lifecycle bug in the HBN preferred partner to paid plan upgrade path. The VSB team owns self-service billing, subscription management, and the Recurly integration for individual partners.

The root cause is likely in how the onboarding upgrade flow cancels the old HBN subscription before creating the new paid one. In `Onboarding::Create#cancel_hbn_subscription`, the code calls `BillingProvider.trigger(:cancel, subscription)`, which uses Recurly's `cancel_subscription` with `timeframe: 'term_end'`. This tells Recurly to keep the subscription active until the end of the current billing period rather than terminating it immediately. The method then sets the local state to `expired`, but Recurly still shows it as active/canceled-pending-expiry. When the new paid subscription is created moments later via `create_subscription`, Recurly now has two subscriptions on the same account - the old one waiting to expire at term end, and the new paid one.

The `TransitionToPreferredPartner` domain class has the same pattern - it cancels via `BillingProvider.trigger(:cancel, ...)` which also uses `term_end`. This means any path from HBN preferred partner to paid plan can produce duplicate active subscriptions in Recurly.

The fix likely involves using `terminate` instead of `cancel` when the subscription is being replaced by an upgrade, so the old subscription is immediately removed from Recurly rather than lingering until term end. The `on_subscription_terminate` handler exists and calls `recurly_client.terminate_subscription` which would remove it immediately.

The fact that this has happened three times in the past month suggests it is a systematic issue with the upgrade flow, not a one-off data problem.

## Triage Comment

Routing to VSB. This appears to be a bug in the HBN preferred partner to paid plan upgrade path. When a preferred partner upgrades, the old HBN subscription is canceled in Recurly with `timeframe: 'term_end'` rather than being terminated immediately. Recurly keeps the canceled subscription active until end of term while the new paid subscription is created, resulting in two subscriptions visible on the account. This has been reported three times in the past month, indicating a systematic issue. The immediate customer concern about double-billing should be verified - the old subscription may still be accruing charges until its term expires. For affected customers, the orphaned HBN subscription in Recurly likely needs to be manually terminated. The code-level fix would be in `Onboarding::Create#cancel_hbn_subscription` (and potentially `TransitionToPreferredPartner#cancel_subscription`) to use terminate instead of cancel when the subscription is being replaced.
