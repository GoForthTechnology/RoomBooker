## ADDED Requirements

### Requirement: Exclusion of Advertising Identifiers
The system SHALL NOT collect or transmit the Android Advertising ID (AD_ID) for any purpose.

#### Scenario: Firebase Analytics Initialization
- **WHEN** the application starts and initializes Firebase Analytics
- **THEN** the collection of the Advertising ID MUST be disabled via manifest configuration

### Requirement: Manifest Permission Removal
The system SHALL explicitly remove the `com.google.android.gms.permission.AD_ID` permission from the final merged Android manifest to ensure it is not requested by any third-party SDKs.

#### Scenario: Build Verification
- **WHEN** the Android application is built in release mode
- **THEN** the `AD_ID` permission MUST NOT be present in the merged `AndroidManifest.xml`

### Requirement: Privacy Stance Documentation
The application's technical documentation MUST clearly state the decision to prioritize user privacy by disabling demographic tracking and advertising identifiers.

#### Scenario: Developer Review
- **WHEN** a developer reviews the application's specifications
- **THEN** they MUST be able to find the rationale and implementation details for the exclusion of `AD_ID`
