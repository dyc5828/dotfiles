## Triage Result

**Ticket:** SUPESC-T15 - Mobile app crashing on launch for Android clients after latest update  
**Routed to:** Client Experience  
**Priority:** High  

### Routing Rationale

This is a crash-on-launch regression in the Android Homebot mobile app (v4.2.1) affecting Android 13+ devices. The mobile app (`native/` repo) is a client-facing product used by homeowners and buyers, which places it squarely in the Client Experience domain.

Key factors:
- **Client-facing impact** - 10+ clients across 4 LOs unable to use the app at all
- **Regression** - introduced by a specific version update (v4.2.1), suggesting a code change in the latest release
- **Platform-specific** - Android 13+ narrows the scope to an OS compatibility issue in the native Android build

### Triage Comment

Routing to **Client Experience**. This is a crash-on-launch regression in the Android app (v4.2.1) affecting Android 13+ devices. 10+ clients across 4 LOs are impacted. Recommend high priority given that affected users cannot access the app at all. The team should investigate recent changes in the v4.2.1 release targeting Android 13+ compatibility - likely a native dependency, permissions change, or SDK version issue.
