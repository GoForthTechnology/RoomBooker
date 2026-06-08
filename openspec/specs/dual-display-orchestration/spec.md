## ADDED Requirements

### Requirement: Display Detection and Role Assignment
The Kiosk application MUST detect the presence of a secondary display (HDMI/USB-C) and automatically assign display roles.

#### Scenario: Identify Displays
- **WHEN** the application starts with a TV connected via HDMI
- **THEN** the Tablet SHALL be assigned the "Controller" role and the TV SHALL be assigned the "Stage" role.

### Requirement: Dual-Context Orchestration
The system MUST allow the Tablet and TV to display different UI layouts and interactive states simultaneously.

#### Scenario: Active Meeting Controls
- **WHEN** a video call is active on the TV (Stage)
- **THEN** the Tablet (Controller) SHALL display "Extend Meeting" and "End Call" controls rather than mirroring the video feed.

### Requirement: Stage Content Hierarchy
The Stage (TV) SHALL display high-value room status information when no meeting is active.

#### Scenario: Idle Stage View
- **WHEN** the room is available
- **THEN** the TV SHALL display the Room Name and Current Time in a large, readable format.

### Requirement: Display Lifecycle Management
The Kiosk application MUST ensure that the secondary display (Stage) does not display stale or "ghost" content when the primary application is closed.

#### Scenario: Application Termination
- **WHEN** the primary application (Controller) is closed or destroyed
- **THEN** the system MUST explicitly dismiss the active presentation on the secondary display (Stage).
