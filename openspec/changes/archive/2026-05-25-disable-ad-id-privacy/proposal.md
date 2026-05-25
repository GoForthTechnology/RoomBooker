## Why

The current implementation of Firebase Analytics automatically includes the `AD_ID` permission, which enables demographic and interest reporting. Since the application does not intend to show ads and prioritizes a clean privacy profile for the user, disabling this collection is necessary to simplify the Data Safety disclosures and minimize data collection.

## What Changes

- Disable Advertising ID (`AD_ID`) collection in Firebase Analytics.
- Explicitly remove the `com.google.android.gms.permission.AD_ID` permission from the merged Android manifest.
- Update the application's documented privacy stance to reflect the decision to minimize data collection.

## Capabilities

### New Capabilities
- `privacy-stance`: Defines the application's approach to data collection and privacy, specifically regarding the exclusion of advertising identifiers and demographic tracking.

### Modified Capabilities
<!-- No existing requirement changes to other capabilities. -->

## Impact

- **Android Manifest**: Modification of `AndroidManifest.xml` to include metadata for disabling `AD_ID` collection and adding a remove node for the permission.
- **Firebase Analytics**: Loss of demographic (age, gender) and interest reports in the Firebase console.
- **Google Play Store**: Simplified Data Safety form requirements.
