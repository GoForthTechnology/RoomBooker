## ADDED Requirements

### Requirement: Log-to-Calendar Deep Linking
When a user navigates to a booking from an audit log entry, the calendar SHALL automatically center on the relevant time slot and open the booking details panel.

#### Scenario: Navigate from Log to Calendar
- **WHEN** a user clicks "View" on a log entry for a specific booking
- **THEN** the calendar view SHALL open, the target booking SHALL be centered in the view, and the booking details panel SHALL be open.

### Requirement: Navigation Stack Persistence
Deep-linking from the settings screen to the calendar view SHALL preserve the navigation stack such that the user can return to the settings screen using the system back button or UI back affordance.

#### Scenario: Return to Settings from Calendar
- **WHEN** a user has navigated from the settings log to the calendar view and clicks the back button
- **THEN** the application SHALL return the user to the settings screen.
