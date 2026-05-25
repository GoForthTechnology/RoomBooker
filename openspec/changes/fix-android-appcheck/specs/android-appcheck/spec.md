## ADDED Requirements

### Requirement: Cross-Platform App Check
The system SHALL initialize Firebase App Check using providers appropriate for the current platform (Play Integrity for Android, Device Check for Apple, and ReCaptcha for Web).

#### Scenario: Android Initialization (Production)
- **WHEN** the app starts on Android in release mode
- **THEN** it activates App Check with `AndroidProvider.playIntegrity`

#### Scenario: Android Initialization (Debug)
- **WHEN** the app starts on Android in debug mode
- **THEN** it activates App Check with `AndroidProvider.debug`

#### Scenario: Apple Initialization (Production)
- **WHEN** the app starts on iOS or macOS in release mode
- **THEN** it activates App Check with `AppleProvider.deviceCheck`
