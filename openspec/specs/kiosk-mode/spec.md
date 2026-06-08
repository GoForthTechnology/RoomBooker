# Kiosk Mode Specification: Room Booker

## Purpose
This document defines the requirements for application pinning and device administration to ensure the Room Booker application can operate as a dedicated kiosk.

## [KIOSK-MODE-000] Compliance
The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119.

## Requirements

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

### Requirement: Manual Kiosk Lockdown Control
The application SHALL provide a user-accessible control to programmatically trigger application pinning (LockTaskMode) without requiring Android system settings navigation.

#### Scenario: Manual Lockdown Trigger
- **WHEN** an administrator taps the "Lock" icon in the dashboard AppBar
- **THEN** the application SHALL invoke `startKioskMode()` to restrict device navigation.
