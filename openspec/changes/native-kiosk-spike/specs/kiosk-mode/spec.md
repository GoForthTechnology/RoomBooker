## ADDED Requirements

### Requirement: App Pinning (LockTaskMode)
The application MUST support Android `LockTaskMode` to prevent users from exiting the application or accessing system settings.

#### Scenario: Enable Kiosk Mode
- **WHEN** the application starts
- **THEN** it SHALL call `startKioskMode()` and verify that the system navigation bar is hidden or restricted.

### Requirement: Device Admin Authorization
The application MUST be registered as a `DeviceAdmin` to enable seamless `LockTaskMode` without a system confirmation prompt.

#### Scenario: Verify Admin Status
- **WHEN** checking app settings in Android
- **THEN** the RoomBooker Kiosk MUST appear in the "Device Admin Apps" list.
