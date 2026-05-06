## ADDED Requirements

### Requirement: Duration-Preserving Reschedule
When an event is moved via a calendar tap during rescheduling, the system MUST preserve the original duration of the event.

#### Scenario: Move event to new time
- **WHEN** a 1-hour event (10:00 AM - 11:00 AM) is moved to 2:00 PM via a calendar tap
- **THEN** the event's new time SHALL be 2:00 PM - 3:00 PM.

### Requirement: Month View Interaction Guard
The system SHALL NOT allow rescheduling an event via calendar cell taps while in Month View.

#### Scenario: Tap calendar in Month View during reschedule
- **WHEN** the user taps a date in Month View while a rescheduling edit is active
- **THEN** the system SHALL NOT update the event's date or time
- **AND** the system SHALL NOT initiate a new booking flow.

### Requirement: Reschedule Mode Priority
When a rescheduling edit is active, calendar cell taps in time-aware views (Day/Week) MUST move the active event instead of initiating a new booking.

#### Scenario: Move event in Week View
- **WHEN** an edit session for an existing event is active and editable
- **AND** the user taps an empty slot in the Week View
- **THEN** the system SHALL update the active event's time to the tapped slot.
