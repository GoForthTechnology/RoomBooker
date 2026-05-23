## ADDED Requirements

### Requirement: Initial Load Feedback
The PWA SHALL provide immediate visual feedback to the user while the Flutter engine is downloading and initializing.

#### Scenario: User opens web app
- **WHEN** the user navigates to the web application URL
- **THEN** the system SHALL immediately display a loading indicator (e.g., spinner or splash screen) before the main Flutter bundle executes

### Requirement: Splash Screen Hiding
The system SHALL remove or hide the initial loading indicator automatically once the Flutter application is fully initialized and ready to paint its first frame.

#### Scenario: Flutter app initialization complete
- **WHEN** the Flutter framework finishes its bootstrapping process
- **THEN** the initial HTML loading indicator SHALL no longer be visible
- **AND** the main application UI SHALL be displayed

### Requirement: Deep Link Preservation
The implementation of the startup splash screen SHALL NOT interfere with or alter the incoming URL, ensuring that deep links (e.g., links directly to a specific calendar view or booking) are correctly parsed and handled by the Flutter routing system upon initialization.

#### Scenario: User opens a deep link
- **WHEN** a user navigates directly to a deep link URL (e.g., `/calendar/view/123`)
- **THEN** the splash screen SHALL display during loading
- **AND** the application SHALL successfully open the specific calendar view or booking once loaded, without losing the URL path or query parameters
