## ADDED Requirements

### Requirement: Editor Back Navigation Handling
The system SHALL intercept standard system back gestures (such as swipe-back on iOS or the hardware back button on Android) when the inline request editor panel is active, and it SHALL use these gestures to close the editor panel instead of navigating away from the calendar view.

#### Scenario: User swipes back while editor is open
- **WHEN** the inline request editor panel is visible on the ViewBookingsScreen
- **AND** the user performs a system back navigation (e.g., swiping back)
- **THEN** the request editor panel SHALL close
- **AND** the underlying calendar view SHALL remain active and visible on the screen.

#### Scenario: User swipes back while editor is closed
- **WHEN** the inline request editor panel is not visible on the ViewBookingsScreen
- **AND** the user performs a system back navigation
- **THEN** the system SHALL perform the default back navigation (e.g., popping the screen).
