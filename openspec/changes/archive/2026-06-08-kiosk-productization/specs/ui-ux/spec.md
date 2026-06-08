## ADDED Requirements

### Requirement: Wall-Mounted Readability
The Kiosk UI MUST be readable from a distance of 10 feet. It SHALL use a high-contrast theme (Primary: Black/White) with large-scale typography (minimum 48pt for primary status).

### Requirement: Responsive Layout
The Kiosk application SHALL be responsive to various display sizes and aspect ratios, ensuring that critical room status information never wraps or becomes obscured.

#### Scenario: Verify Portrait Orientation
- **WHEN** the Kiosk app is viewed on a narrow mobile device (Portrait)
- **THEN** the primary status text (e.g., "AVAILABLE") SHALL scale down proportionally to fit the screen width without wrapping.

#### Scenario: Read Room Status from Hallway
- **WHEN** a user is standing 10 feet from the wall-mounted tablet
- **THEN** they SHALL be able to clearly identify if the room is "Available" or "Busy" via the background color and text size.

### Requirement: Ambient Status Background
The Kiosk application SHALL use the entire screen background as a primary status indicator (Green for Available, Red for Busy, Yellow for Transition).

#### Scenario: Verify Busy State
- **WHEN** a meeting is currently in progress
- **THEN** the entire tablet background SHALL be a high-saturation red to signal occupancy.

### Requirement: Service Handshake Visuals
The Kiosk UI SHALL provide real-time feedback during the "One-Touch Join" sequence.

#### Scenario: Track Join Progress
- **WHEN** the "Join" button is tapped
- **THEN** the Dashboard SHALL display a "Launching Meeting..." overlay until the video feed is successfully rendered on the Stage.
