## ADDED Requirements

### Requirement: Accurate Audit Logs
The system SHALL maintain an audit log of all booking-related actions, correctly attributing each action to the person who performed it (the actor).

#### Scenario: Verify Admin Action Attribution
- **WHEN** an admin approves or denies a booking request
- **THEN** the audit log SHALL record the admin's email as the actor for that action.
