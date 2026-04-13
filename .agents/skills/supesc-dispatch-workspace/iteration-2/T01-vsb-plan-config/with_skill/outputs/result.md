# SUPESC-T01 Triage Result

## Routing Decision

**Category: B - Routable to a team**

**Route to: VSB**

## Action

1. Post a top-level routing comment on the ticket (see below).
2. Move the ticket to the **VSB** team.
3. Keep status as **Triage** for the VSB team lead to prioritize.

## Comment

**Routing: VSB**

This is likely a plan configuration issue. The agent-teams plan is designed to include both mobile app access and the buyer landing page - those features are gated by the `full_access` flag on the plan. When `full_access` is enabled, the mobile app (`has_native_access?`) and buyers landing page (`buyers_enabled`) both turn on automatically, regardless of sponsorship status.

If Alex Alpha's plan has `full_access` toggled off in HB Admin, those features won't show up even though she's on the right plan. Worth checking the plan's configuration in HB Admin's Plans tab to confirm `full_access` is set to true. If it's a per-customer override rather than a plan-level issue, check whether a `disabled_features` entry for `native_access` exists on her profile.
