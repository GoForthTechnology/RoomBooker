## ADDED Requirements

### Requirement: Interactive Drag-to-Move
The system SHALL allow administrators to visually drag and drop confirmed bookings on the calendar to change their start and end dates and times.

#### Scenario: Drag and drop confirmed booking
- **WHEN** an administrator drags a confirmed booking to a new calendar time slot
- **THEN** the system SHALL update the booking's start and end times in Firestore
- **AND** the calendar SHALL show the booking at the new time slot.

### Requirement: Interactive Drag-to-Resize
The system SHALL allow administrators to visually drag the top or bottom edges of a confirmed booking on the calendar to change its duration.

#### Scenario: Resize confirmed booking
- **WHEN** an administrator drags the bottom edge of a confirmed booking to a new time
- **THEN** the system SHALL update the booking's end time in Firestore
- **AND** the calendar SHALL show the booking with the new duration.
