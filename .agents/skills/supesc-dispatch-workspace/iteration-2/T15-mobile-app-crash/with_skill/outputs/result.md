# SUPESC-T15 Triage Result

## Ticket
- **ID:** SUPESC-T15
- **Title:** Mobile app crashing on launch for Android clients after latest update
- **Labels:** Escalation, Mobile App
- **Relevant Area:** Client - Mobile App

## Classification
**Category B: Routable to a team**

This is a bug report, not a codebase question. The crash-on-launch pattern affecting Android 13+ devices after a specific version update (v4.2.1) requires debugging and a fix from the team that owns the mobile app.

## Routing Decision
**Route to: Client Experience**

## Routing Comment (dry-run, not posted)

**Routing: Client Experience**

Android app crash-on-launch affecting 10+ clients across 4 LOs since v4.2.1. The crash is specific to Android 13+ devices and started after the latest update, pointing to a build or runtime regression in the native app itself. The `native/` repo (React Native) is within Client Experience's ownership.

## Actions (dry-run, not executed)

1. **Move ticket** to **Client Experience** team
2. **Keep status** as **Triage** (team lead will prioritize)
3. **Post top-level comment** with the routing reasoning above
4. **Do not assign** to a specific person

## Routing Reasoning

The skill's Team Routing Guide maps "mobile app" directly to Client Experience: "Consumer app: home digest, home values, listings, **mobile app**, client emails."

The through-line check confirms this belongs with Client Experience and not elsewhere:
- Not a data issue - the crash is on launch, not related to displaying incorrect data
- Not a backend issue - the crash occurs before the app would meaningfully interact with gqlactus (native-backend)
- Not a User Messaging issue - no send/delivery component
- The correlation with a specific app version (v4.2.1) and a specific OS version (Android 13+) points to a native build or compatibility regression, which is firmly in the mobile app team's domain

No ambiguity in routing. Confidence: high.
