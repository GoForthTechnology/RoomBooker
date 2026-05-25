## Context

Firebase Analytics SDK for Android automatically requests the `com.google.android.gms.permission.AD_ID` permission and collects the Advertising ID to provide demographic tracking. This happens during manifest merging, even if the permission is not explicitly declared in the app's `AndroidManifest.xml`. To maintain a high level of user privacy and simplify compliance with Google Play Data Safety policies, we need to explicitly disable this behavior.

## Goals / Non-Goals

**Goals:**
- Prevent the `AD_ID` permission from being included in the final APK/AAB.
- Configure Firebase Analytics to skip Advertising ID collection.
- Document this privacy stance for future maintainers.

**Non-Goals:**
- Completely removing Firebase Analytics (we still need basic event tracking).
- Modifying iOS privacy configurations (already managed by App Tracking Transparency if applicable, but this task is Android-focused based on the user's report).

## Decisions

### 1. Manifest Tool Removal for AD_ID
We will use the Android Manifest Merger `tools:node="remove"` attribute.
- **Rationale**: This is the only reliable way to ensure a permission added by a library (like Firebase) is stripped from the final merged manifest.
- **Alternative**: Requesting the permission but never using it. This is rejected as it still flags the app as collecting sensitive identifiers.

### 2. Global Disable for AD_ID Collection
We will use the `google_analytics_adid_collection_enabled` metadata flag.
- **Rationale**: This is the official Google recommendation for disabling AD_ID collection at the SDK level.
- **Alternative**: Disabling all analytics collection. Rejected as we still want non-identifying event tracking.

## Risks / Trade-offs

- **[Risk] Loss of Demographic Data** → **Mitigation**: Accepted as a trade-off for better privacy. The app is a utility for room booking where detailed demographic breakdown is less critical than user trust.
- **[Risk] Incorrect Manifest Merging** → **Mitigation**: Verify the merged manifest using `flutter build` and checking the output (though manual verification of the merged XML is preferred if possible, or relying on the build success).
