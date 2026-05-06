## ADDED Requirements

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
