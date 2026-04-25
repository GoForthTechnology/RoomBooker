## ADDED Requirements

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
