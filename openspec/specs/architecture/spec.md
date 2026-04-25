# Architecture Specification: Room Booker

## Purpose
This document defines the high-level architecture, tech stack, and structural constraints for the Room Booker project.

## [ARCH-000] Compliance
The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119.

## Requirements

### Requirement: Supported Frameworks
The system SHALL be built using Flutter with SDK version >=3.4.3 <4.0.0.

#### Scenario: Verify Framework Version
- **WHEN** checking the `pubspec.yaml` file
- **THEN** the Flutter SDK constraint matches the requirement

### Requirement: Firebase Backend
The system MUST use Firebase for Authentication, Firestore, Analytics, and Performance Monitoring.

#### Scenario: Verify Firebase Integration
- **WHEN** initializing the app
- **THEN** Firebase services are correctly configured and reachable

### Requirement: Early Error Reporting
The application SHALL initialize the error reporting service (Sentry) as the first asynchronous operation in the application's entry point (`main`).

#### Scenario: Catch crash during Firebase initialization
- **WHEN** the `Firebase.initializeApp` call fails during application startup
- **THEN** Sentry MUST capture and report the exception, as it was already initialized in `main`.

### Requirement: Global Initialization Coverage
Error reporting MUST cover all subsequent initialization steps, including database connection, authentication provider configuration, and local storage access.

#### Scenario: Catch crash during Auth configuration
- **WHEN** `FirebaseUIAuth.configureProviders` throws an error in `AppInitializer`
- **THEN** Sentry SHALL capture the error because the initialization happened within the Sentry-monitored execution flow.

### Requirement: Presentation Layer
The presentation layer SHALL be located in `lib/ui/` and SHALL follow a widget-based composition.

#### Scenario: Verify UI Structure
- **WHEN** adding a new screen
- **THEN** it is placed in `lib/ui/screens/`

### Requirement: Domain Layer
The domain layer SHALL contain entities and business logic, independent of external services.

#### Scenario: Verify Entity Location
- **WHEN** defining a data model
- **THEN** it is placed in `lib/data/entities/`

### Requirement: Service-First Logic
All booking-related logic SHALL go through the `BookingService` class.

#### Scenario: Verify Booking Logic Entry
- **WHEN** a UI component needs to create a booking
- **THEN** it calls a method on `BookingService`

### Requirement: Repository Isolation
The `BookingRepo` MUST NOT be accessed directly by UI components or ViewModels.

#### Scenario: Verify Repository Access
- **WHEN** checking imports in a UI widget
- **THEN** `BookingRepo` is not imported

### Requirement: Cold Start Trace Lifecycle
The application SHALL only stop the cold start performance trace once per application lifecycle, specifically after the initial landing page has rendered successfully.

#### Scenario: Verify Cold Start Trace Single Stop
- **WHEN** the application is first launched and the main view is rendered
- **THEN** the cold start trace SHALL be stopped exactly once.
- **WHEN** the window is resized or subsequent rebuilds occur
- **THEN** the cold start trace SHALL NOT be stopped again.

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

### Requirement: Production Observability
The build and deployment pipeline MUST ensure that production error reports are actionable and readable. This includes generating and uploading the necessary debug symbols and source maps to the error reporting service (Sentry).

#### Scenario: Verify Source Map Generation
- **WHEN** the Web application is built for production
- **THEN** the build command SHALL include the `--source-maps` flag to generate mapping files.

#### Scenario: Verify Automated Symbol Upload
- **WHEN** a production build completes successfully in the CI/CD pipeline
- **THEN** the pipeline SHALL execute the Sentry Dart Plugin to upload build artifacts and symbols.

#### Scenario: Verify Secure Authentication for Symbol Upload
- **WHEN** uploading symbols to Sentry
- **THEN** the pipeline MUST use a securely stored authentication token (e.g., GitHub Secret) for API communication.
