## ADDED Requirements

### Requirement: Android Production Signing
The system SHALL support building the Android application with a production signing configuration using environment variables for the keystore, password, and alias.

#### Scenario: Signed Build
- **WHEN** a production build is triggered with the correct environment variables (signing keys) provided
- **THEN** the system generates a signed Android App Bundle (.aab) ready for distribution

### Requirement: Automated Android Deployment
The system SHALL automatically deploy the signed Android build to Firebase App Distribution upon a successful version bump commit.

#### Scenario: Auto-Deploy to Firebase
- **WHEN** a commit message starts with "Cut v" and includes a valid version string
- **THEN** the GitHub Actions workflow builds the .aab and uploads it to Firebase App Distribution

### Requirement: Version Syncing
The system SHALL ensure that the Android version (versionCode and versionName) stays synchronized with the version defined in `pubspec.yaml`.

#### Scenario: Version Match
- **WHEN** the `bump_version.sh` script is run and the changes are pushed
- **THEN** the Android build uses the updated version from `pubspec.yaml`
