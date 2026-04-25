## Why

Debugging errors in Sentry for this project is currently hindered by obfuscated code, making it difficult to identify the root cause of issues in production. While the project has the Sentry Flutter SDK and Dart plugin installed, it is not configured to generate and upload the necessary debug symbols and source maps. Since the project now relies exclusively on GitHub Actions for deployment to Firebase Hosting, the CI/CD pipeline must be updated to support these observability features.

## What Changes

- Update the GitHub Actions workflow to generate Web source maps using the `--source-maps` flag.
- Integrate the Sentry Dart plugin into the GitHub Actions pipeline to automatically upload debug symbols and source maps.
- Remove deprecated Sentry-related build steps from the `Dockerfile` (as it is no longer used for deployment).
- Document the updated CD process, including the requirement for Sentry authentication tokens.
- Verify and synchronize the Sentry project and organization configuration in `pubspec.yaml`.

## Capabilities

### New Capabilities
- none

### Modified Capabilities
- `architecture`: Update the production CI/CD pipeline to mandate observability artifacts (source maps/symbols).

## Impact

- **Observability**: Readable stack traces in Sentry for production Web errors.
- **CI/CD**: The GitHub Actions workflow is now the source of truth for deployment and symbol management.
- **Documentation**: New guidance on managing Sentry tokens for the deployment pipeline.
