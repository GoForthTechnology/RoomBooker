## MODIFIED Requirements

### Requirement: Meeting Join Automation
The system MUST include a native Android Accessibility Service that automatically identifies and clicks "Join" or "Ask to Join" buttons within Google Meet, Microsoft Teams, and Zoom. If the native application cannot be routed to a secondary display, the system SHALL fallback to a Desktop-Spoofed WebView using JavaScript injection for automation.

#### Scenario: Automate Google Meet Join (Native)
- **WHEN** the Kiosk app launches a Google Meet URL
- **THEN** the `MeetAutomatorService` SHALL detect the Google Meet foreground window and perform a virtual click on the "Join" button.

#### Scenario: Automate Join (WebView Fallback)
- **WHEN** a meeting is launched in the Integrated WebView Stage
- **THEN** the system SHALL inject a JavaScript handler to identify the DOM "Join" button and trigger an `HTMLElement.click()`.

### Requirement: Dual-Display Stage Management
The system MUST support displaying the video conference on a secondary screen (TV) while keeping the controller (Tablet) on the Kiosk Dashboard.

#### Scenario: Launch to Secondary Display
- **WHEN** a meeting is launched via USB-C HDMI
- **THEN** the system SHALL attempt to route the session to the HDMI output, and the Tablet SHALL NOT be obscured by the meeting session.
