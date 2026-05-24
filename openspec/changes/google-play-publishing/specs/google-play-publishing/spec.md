## ADDED Requirements

### Requirement: Automated Play Store Upload
The system SHALL automatically upload the signed Android App Bundle (.aab) to a specified track in the Google Play Store upon a successful version bump.

#### Scenario: Upload to Internal Track
- **WHEN** a release build is triggered via a version bump commit
- **THEN** the GitHub Actions workflow builds the .aab and uploads it to the Google Play Console "internal" track

### Requirement: Play Store Authentication
The system SHALL use a dedicated service account with the required API access for authenticating Play Store publishing requests.

#### Scenario: Service Account Credential Usage
- **WHEN** the Play Store upload step is executed in CI
- **THEN** it uses the `GOOGLE_PLAY_SERVICE_ACCOUNT_KEY` secret for authentication
