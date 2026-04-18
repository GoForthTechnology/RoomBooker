## ADDED Requirements

### Requirement: State Transition Stability
The calendar view model SHALL remain stable and MUST NOT crash during state transitions, including initialization, window resizing, or view type changes.

#### Scenario: Resize window during initialization
- **WHEN** the browser window is resized while the calendar is still initializing
- **THEN** the view model SHALL handle potentially null controller properties gracefully without throwing exceptions.
