# Triage Result: SUPESC-T01

## Routing Decision

**Routed to: VSB (Very Small Business)**

## Comment

Routing to **VSB**. This is a plan configuration issue on the agent-teams plan (`hb-agent-team` / `hb-rea-team`), which falls under the REA business line owned by VSB.

**Root cause analysis from the codebase:**

The customer is on the `agent-teams` plan for Real Estate Agents. Looking at the plan's factory definition in Mikasa (`spec/factories/plans.rb`), the `rea_teams_plan` includes `with_sponsorship_creation`, `with_homebot_listings`, and `with_manage_videos` as features, but does **not** explicitly attach the `NATIVE_ACCESS` power-up.

However, `NATIVE_ACCESS` is listed in `FeatureFlag::AUTO_ENABLED` (`app/models/feature_flag.rb` line 143-147), which means it should be automatically available on any plan that has it in its power-ups list. The `auto_enabled_powerups` method in `PowerUpAvailabilityConcern` resolves auto-enabled features by intersecting `AUTO_ENABLED` with the plan's power-ups - but the `rea_teams_plan` factory does not attach `NATIVE_ACCESS` as a power-up on the plan itself, so the auto-enable logic would not surface it.

This looks like the `NATIVE_ACCESS` power-up (which controls both mobile app access and the buyer landing page) was never added to this plan's feature configuration. The individual LO plans all get `INDIVIDUAL_PLAN_POWERUPS` which includes `NATIVE_ACCESS`, but the REA teams plan does not.

**Recommended investigation:** Check whether the production `agent-teams` plan has the `native_access` feature flag attached via `entity_features`. If not, it needs to be added. This is a plan configuration fix - either via Crawlspace's plan feature management UI or a direct data update.

**Labels to add:** Plan Configuration, REA
