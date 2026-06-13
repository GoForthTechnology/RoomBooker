## Why

The current deployment process for the RoomBooker applications (Android and Web) requires a manual intervention step in the Google Play Console to promote builds from the Internal track to Production. This manual step introduces toil and slows down the delivery of features. By linking our semantic versioning tags directly to deployment targets, we can automate the rollout of minor and major features while preserving a safe, internal track for patch testing.

## What Changes

- The `.github/workflows/android-release.yml` will be updated to automatically push `Minor` and `Major` versions directly to the Google Play Production track.
- `Patch` versions will continue to be deployed only to the Internal track.
- The `bump_version.sh` script will remain the primary trigger, but the CI pipeline will parse the SemVer format (e.g., `v1.4.0+50`) to determine the rollout track dynamically.

## Capabilities

### New Capabilities
- `version-driven-cd`: Defines the relationship between Semantic Versioning (Major, Minor, Patch) and the automated deployment targets (Internal vs Production) for the Android application.

### Modified Capabilities
*(None)*

## Impact

- **Infrastructure**: Updates to GitHub Actions workflows.
- **Process**: Developers will no longer need to log into the Play Console for feature releases.
- **Risk Profile**: Minor and Major releases will go directly to users without a manual "Promote" gate, placing higher reliance on the automated test suite.