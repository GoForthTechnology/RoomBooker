# Specification: Independent Instance Rescheduling

## Purpose
This document defines the requirements for independent instance rescheduling and visual reschedule actions (drag-to-move and drag-to-resize).

## [RESCHED-000] Compliance
The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119.
## Requirements
### Requirement: Independent Instance Rescheduling
The system SHALL allow a single instance of a recurring booking series to be moved to a different time and date without affecting the rest of the series.

#### Scenario: Reschedule one instance to a new day
- **WHEN** a user modifies a single instance of a weekly series from Monday to Tuesday
- **THEN** the calendar SHALL show the original Monday series as confirmed
- **AND** the calendar SHALL NOT show an event on the modified Monday
- **AND** the calendar SHALL show the modified event on the Tuesday

### Requirement: Persistent Original Reference
When an instance is overridden, the system MUST use the original instance's start date as the primary lookup key for the override, regardless of the new start date.

#### Scenario: Verify lookup key stability
- **WHEN** an instance originally scheduled for 2026-05-11 is moved to 2026-05-12
- **THEN** the system SHALL store the override using 2026-05-11 as the key
- **AND** expansion logic SHALL correctly retrieve this override when evaluating 2026-05-11

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

### Requirement: Recurring Instance Visual Drag-to-Move Target
When a repeating instance of a recurring booking series is rescheduled via a visual calendar drag-and-drop gesture, the system SHALL target that specific instance's original start time as the `originalStartTime` during the update.

#### Scenario: Drag and drop repeating instance
- **WHEN** an administrator drags a repeating instance of a weekly series originally starting on Wednesday to a new time slot
- **THEN** the system SHALL invoke the booking update service with `originalStartTime` set to the Wednesday occurrence's start time
- **AND** the system SHALL trigger the recurring edit choice provider.

### Requirement: Recurring Instance Visual Drag-to-Resize Target
When a repeating instance of a recurring booking series is rescheduled via a visual calendar resize gesture, the system SHALL target that specific instance's original start time as the `originalStartTime` during the update.

#### Scenario: Resize repeating instance
- **WHEN** an administrator resizes a repeating instance of a weekly series originally starting on Wednesday
- **THEN** the system SHALL invoke the booking update service with `originalStartTime` set to the Wednesday occurrence's start time
- **AND** the system SHALL trigger the recurring edit choice provider.

