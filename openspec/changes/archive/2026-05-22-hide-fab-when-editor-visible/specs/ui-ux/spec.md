## ADDED Requirements

### Requirement: Conditional FAB Visibility
The application SHALL hide the primary action button for creating new bookings (FAB) whenever the request editor panel is active on the calendar screen.

#### Scenario: Open request editor
- **WHEN** the user opens the request editor panel to view or edit a booking
- **THEN** the Floating Action Button (FAB) for adding new bookings SHALL NOT be visible

#### Scenario: Close request editor
- **WHEN** the user closes the request editor panel
- **AND** the calendar is in a view that supports the FAB
- **THEN** the Floating Action Button (FAB) SHALL become visible again
