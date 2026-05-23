## MODIFIED Requirements

### Requirement: Splash Screen Hiding
The system SHALL remove or hide the initial loading indicator automatically once the Flutter application is fully initialized and ready to paint its first frame. The system SHALL NOT display a secondary, momentary loading indicator (e.g., a Flutter-rendered spinner) that causes visual flashing immediately after the splash screen is hidden during standard initialization or redirection flows.

#### Scenario: Flutter app initialization complete
- **WHEN** the Flutter framework finishes its bootstrapping process
- **THEN** the initial HTML loading indicator SHALL no longer be visible
- **AND** the main application UI SHALL be displayed without an intermediate flash of a secondary loading indicator.
