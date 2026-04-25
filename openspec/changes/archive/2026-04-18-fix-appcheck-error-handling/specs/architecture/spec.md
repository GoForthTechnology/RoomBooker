## MODIFIED Requirements

### Requirement: Non-Blocking Initialization
The application initialization sequence SHALL be designed to reach the primary UI as quickly as possible. However, critical security services (specifically AppCheck) MUST complete successfully before the user is allowed to access any application features or data.

#### Scenario: Verify Fast main() Execution
- **WHEN** the `main()` function is executed
- **THEN** it SHALL call `runApp()` with a minimal `MaterialApp` or splash container if subsequent initializations are slow.

#### Scenario: Abusive Traffic Detection
- **WHEN** AppCheck activation fails due to a security rejection (abusive traffic)
- **THEN** the application SHALL display a specific "Abusive Traffic Detected" message and prevent further navigation or data fetching.

#### Scenario: Critical Initialization Failure UI
- **WHEN** a critical initialization step (e.g., Firebase Core) fails due to a non-security error
- **THEN** the `AppInitializer` SHALL display a user-friendly error message with a "Retry" option.
