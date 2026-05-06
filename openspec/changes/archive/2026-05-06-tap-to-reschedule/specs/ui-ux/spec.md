## ADDED Requirements

### Requirement: Modal Rescheduling State
The application SHALL distinguish between "Creation" and "Rescheduling" states. While in the "Rescheduling" state, secondary calendar interactions (like taps) MUST be re-routed to modify the active event rather than initiating new workflows.

#### Scenario: Verify re-routed tap
- **WHEN** an existing booking is being edited (Rescheduling state)
- **AND** the user taps an available time slot in a time-aware view
- **THEN** the active booking SHALL "teleport" to the new time slot instead of opening a new request form.
