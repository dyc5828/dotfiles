# SUPESC-T01 Triage Result

## Routing Decision

**Route to: VSB**

This is an individual customer account/plan configuration issue, not an app behavior bug. The agent-teams plan (`hb-agent-team`) should include both the mobile app and buyer landing page features, but those features depend on specific plan-level configuration being set correctly.

## Routing Comment

**Routing: VSB**

This looks like a plan configuration issue rather than a platform bug. The agent-teams plan is designed to include mobile app access and the buyer landing page, but both depend on the plan having the right feature flags and the `full_access` toggle enabled. Specifically, mobile app access requires the `native_access` power-up to be present on the plan (it auto-enables when available), and the buyer landing page requires `full_access` to be true on the plan for unsponsored agents. Worth checking the plan's feature flags in HB Admin - if `native_access` isn't attached to the plan as a power-up, or if `full_access` is toggled off, that would explain the missing features. This may be a quick fix in the Plans tab of HB Admin.

## Analysis Notes

Key code paths investigated:

- **Mobile app access** is gated by the `native_access` feature flag (`FeatureFlag::NATIVE_ACCESS`). It's defined as both a POWERUP and AUTO_ENABLED, meaning it auto-enables for customers if the power-up exists on their plan. The REA teams plan factory includes `full_access` but does not explicitly add `native_access` as a power-up. If the production plan record is missing this feature flag in its entity_features, mobile app access would not appear.

- **Buyer landing page** (`buyer_share_uri`) is gated by two conditions: (1) `corporate_profile.show_buyer_purl` must be true (defaults to true), and (2) for unsponsored agents, `full_access?` must be true on their plan. The `full_access?` method delegates to `plan.full_access?`, which checks the boolean `full_access` column on the plans table.

- **`requires_sponsor?` in PowerUpDecorators::Base** (line 62) explicitly checks `!@customer.plan&.full_access` - if the plan has `full_access` set, the sponsorship requirement is bypassed for power-ups.

- The REA teams plan factory (`spec/factories/plans.rb:1128`) shows the plan should have `full_access`, `with_homebot_listings`, and `with_manage_videos` - but the actual production plan record may differ from the factory definition.

The most likely root cause is that the production plan record is either missing the `full_access` flag or missing the `native_access` power-up in its entity_features. Both are configurable in HB Admin's Plans tab.
