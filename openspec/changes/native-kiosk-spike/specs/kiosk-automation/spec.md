## ADDED Requirements

### Requirement: Meeting Join Automation
The system MUST include a native Android Accessibility Service that automatically identifies and clicks "Join" or "Ask to Join" buttons within Google Meet, Microsoft Teams, and Zoom.

#### Scenario: Automate Google Meet Join
- **WHEN** the Kiosk app launches a Google Meet URL
- **THEN** the `MeetAutomatorService` SHALL detect the Google Meet foreground window and perform a virtual click on the "Join" button.

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
