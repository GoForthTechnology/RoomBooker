## ADDED Requirements

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
