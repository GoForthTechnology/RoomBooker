## Context

The project has transitioned to using GitHub Actions as the sole deployment mechanism for Firebase Hosting. Production error reports are currently obfuscated. Sentry requires source maps and debug symbols to provide readable stack traces.

## Goals / Non-Goals

**Goals:**
- Automate source map generation in GitHub Actions.
- Automate symbol upload to Sentry in GitHub Actions.
- Document the Sentry token requirement for CI/CD.
- Clean up the unused `Dockerfile`.

**Non-Goals:**
- Supporting Docker-based deployments for Sentry symbols.

## Decisions

### 1. Web Source Maps in GitHub Actions
We will update the `flutter build web` step in `.github/workflows/firebase-hosting-merge.yml` to include `--source-maps`.

### 2. Sentry Dart Plugin in CI/CD
We will add a step to the GitHub workflow: `dart run sentry_dart_plugin`. This will run after the build but before the deployment.

### 3. Documentation of CD Process
We will add a section to `README.md` or a new `DOCS/deployment.md` explaining how the CD pipeline works and how to rotate the `SENTRY_AUTH_TOKEN` secret in GitHub.

### 4. Deprecate Docker Build Logic
We will remove the `RUN flutter build web` and related steps from the `Dockerfile` or mark it as deprecated to avoid confusion, as GitHub Actions is the source of truth.

## Risks / Trade-offs

- **[Risk]** Broken CI if `SENTRY_AUTH_TOKEN` is missing -> **Mitigation**: The workflow step will be configured to provide a clear error message if the secret is not found.
