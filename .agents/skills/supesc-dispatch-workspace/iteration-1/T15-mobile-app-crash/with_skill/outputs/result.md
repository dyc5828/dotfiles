# SUPESC-T15 Triage Result

## Ticket
- **ID:** SUPESC-T15
- **Title:** Mobile app crashing on launch for Android clients after latest update
- **Labels:** Escalation, Mobile App
- **Current Status:** Triage

## Decision: Route to Client Experience

**Category:** B - Routable to a team

**Routing confidence:** High

## Routing Comment (dry-run, not posted)

**Routing: Client Experience**

The Android mobile app is crashing on launch after the v4.2.1 update, specifically on Android 13+ devices. Multiple LOs have reported this across at least 10 clients. This is a mobile app issue that falls squarely within Client Experience's domain. The version-specific nature (Android 13+) suggests a compatibility issue introduced in the latest build that will likely need crash log investigation and a hotfix.

## Actions (dry-run, not taken)

1. **Post routing comment** on the ticket with the reasoning above.
2. **Move ticket** to the **Client Experience** team.
3. **Keep status** as Triage for the team lead to prioritize.

## Reasoning

Per the team routing guide, Client Experience owns "Consumer app: home digest, home values, listings, mobile app, client emails." The mobile app is explicitly within their scope.

No through-line complication applies here. The issue is a crash-on-launch bug tied to a specific app version and OS version. The root cause is almost certainly in the native app build or React Native layer, not in upstream data, messaging infrastructure, or account configuration. The `native/` repo (React Native app with Android build at `native/android/`) is where investigation will happen.

The scope of impact (10+ clients across 4 LOs, all on Android 13+) and the nature of the issue (crash on launch, total app unusability) suggest this should be prioritized as a high-severity bug by the Client Experience team.
