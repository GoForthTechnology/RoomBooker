## MODIFIED Requirements

### Requirement: Automated Android Deployment
The system SHALL automatically deploy the signed Android builds to both Firebase App Distribution (APK) and Google Play Store (AAB) upon a successful version bump commit.

#### Scenario: Multi-Channel Auto-Deploy
- **WHEN** a commit message starts with "Cut v" and includes a valid version string
- **THEN** the GitHub Actions workflow builds both .apk and .aab artifacts
- **AND** it uploads the .apk to Firebase App Distribution
- **AND** it uploads the .aab to Google Play Store
