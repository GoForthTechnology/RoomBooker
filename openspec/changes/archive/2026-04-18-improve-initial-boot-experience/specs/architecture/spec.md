## ADDED Requirements

### Requirement: Non-Blocking Initialization
The application initialization sequence in `main()` SHALL be designed to reach the first `runApp()` call as quickly as possible. Heavy asynchronous operations (like full Firebase initialization or deep-link parsing) SHALL be handled in a way that allows a placeholder UI to be rendered first if they take more than 200ms.

#### Scenario: Verify Fast main() Execution
- **WHEN** the `main()` function is executed
- **THEN** it SHALL call `runApp()` with a minimal `MaterialApp` or splash container if subsequent initializations are slow.
