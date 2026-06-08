# Kiosk Automation Specification: Room Booker

## Purpose
This document defines the requirements for meeting join automation and system-level interaction handling for the Room Booker Kiosk application.

## [KIOSK-AUTO-000] Compliance
The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119.

## Requirements

### Requirement: Meeting Join Automation
The system MUST include a native Android Accessibility Service that automatically identifies and clicks "Join" or "Ask to Join" buttons within Google Meet, Microsoft Teams, and Zoom.

#### Scenario: Automate Google Meet Join
- **WHEN** the Kiosk app launches a Google Meet URL
- **THEN** the `MeetAutomatorService` SHALL detect the Google Meet foreground window and perform a virtual click on the "Join" button.

### Requirement: Automation Safety and Scope
The `MeetAutomatorService` MUST NOT interact with applications outside the authorized whitelist (Google Meet, Google Play Services).

#### Scenario: Verify App Restriction
- **WHEN** the user switches to an unauthorized app (e.g., YouTube)
- **THEN** the `MeetAutomatorService` SHALL immediately stop all scanning and clicking.

### Requirement: One-Shot Authorization
The automation service SHALL only perform virtual clicks when explicitly authorized by the Kiosk application for a specific meeting session.

#### Scenario: Prevent Auto-Rejoin
- **WHEN** a meeting ends and a "Rejoin" button appears
- **THEN** the service SHALL NOT click it unless the user manually triggers a new meeting from the Kiosk dashboard.

### Requirement: Account Picker Automation
The system SHALL automatically handle Google Account selection screens when launching meetings.

#### Scenario: Automate Account Selection
- **WHEN** a "Choose an account" dialog appears
- **THEN** the service SHALL identify and click the first available email address or account container.

### Requirement: System Permissions
The Kiosk application MUST request and be granted `CALL_PHONE` and `INTERNET` permissions to properly launch conferencing intents.

#### Scenario: Verify Permission Grant
- **WHEN** launching a meeting for the first time
- **THEN** the system SHALL prompt the user to "Allow phone calls" (required by Google Meet telephony stack).

### Requirement: Dual-Display Stage Management
The system MUST support displaying the video conference on a secondary screen (TV) while keeping the controller (Tablet) on the Kiosk Dashboard.

#### Scenario: Launch to Secondary Display
- **WHEN** a meeting is launched via USB-C HDMI
- **THEN** the system SHALL attempt to route the session to the HDMI output, and the Tablet SHALL NOT be obscured by the meeting session.

### Requirement: Service Lifecycle Management
The `MeetAutomatorService` SHALL remain active in the background as long as the device is in Kiosk mode.

#### Scenario: Verify Service Persistence
- **WHEN** the device is rebooted
- **THEN** the `MeetAutomatorService` MUST automatically restart (if allowed by system settings) or be prompted for activation.

### Requirement: Intent Integration
The Kiosk application MUST provide a mechanism to launch conferencing URLs via standard Android Intent filters.

#### Scenario: Trigger Intent from Flutter
- **WHEN** a user taps the "Launch Spike" button in Flutter
- **THEN** the application SHALL invoke a platform channel call to launch the provided URL in the respective conferencing app.
or be prompted for activation.

### Requirement: Intent Integration
The Kiosk application MUST provide a mechanism to launch conferencing URLs via standard Android Intent filters.

#### Scenario: Trigger Intent from Flutter
- **WHEN** a user taps the "Launch Spike" button in Flutter
- **THEN** the application SHALL invoke a platform channel call to launch the provided URL in the respective conferencing app.
