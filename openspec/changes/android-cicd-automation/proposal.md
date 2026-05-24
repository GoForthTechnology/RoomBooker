## Why

Currently, Android builds and releases are manual, using a debug signing configuration. This slows down delivery, increases the risk of manual errors, and lacks a repeatable infrastructure foundation. Implementing CI/CD with Infrastructure as Code (IaC) ensures a portable, secure, and automated pipeline for the Room Booker Android application.

## What Changes

- **Infrastructure as Code (IaC)**: Introduce Terraform to manage Google Cloud Platform (GCP) and Firebase resources, including a GCS backend for state storage.
- **Android Signing**: Automate the generation and secure storage of a production keystore using GitHub Secrets.
- **CI/CD Pipeline**: Extend GitHub Actions to build signed Android App Bundles (.aab) and distribute them.
- **Distribution**: Automate deployment to Firebase App Distribution for internal testing.

## Capabilities

### New Capabilities
- `android-cicd`: Covers the automation of Android builds, signing, and distribution through GitHub Actions.
- `infrastructure-iac`: Covers the management of GCP and Firebase resources using Terraform, including service accounts and state management.

### Modified Capabilities
- None

## Impact

- **Build System**: `android/app/build.gradle.kts` will be updated to support production signing using environment variables.
- **GitHub Actions**: A new workflow file will be added to handle Android-specific tasks.
- **Security**: Introduction of GitHub Secrets for keystore data and service account keys.
- **Infrastructure**: New `terraform/` directory to hold IaC configurations.
