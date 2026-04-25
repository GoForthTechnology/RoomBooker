## MODIFIED Requirements

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
