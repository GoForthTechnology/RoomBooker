## Why

Currently, Android releases are distributed via Firebase App Distribution as APKs. While this works for internal testing, it doesn't allow for public distribution via the Google Play Store. Automating this process ensures a streamlined path from development to production with minimal manual intervention.

## What Changes

- **Infrastructure as Code (IaC)**: Add a new service account in Terraform with permissions to interact with the Google Play Developer API.
- **CI/CD Pipeline**: Update the `android-release.yml` workflow to support uploading Android App Bundles (.aab) to Google Play tracks.
- **Build Process**: Re-introduce `.aab` builds alongside or instead of `.apk` for Play Store compatibility.

## Capabilities

### New Capabilities
- `google-play-publishing`: Covers the automation of uploading and distributing Android releases to the Google Play Store tracks.

### Modified Capabilities
- `android-cicd`: Extend the existing Android CI/CD capability to handle Play Store specific authentication and deployment steps.

## Impact

- **Infrastructure**: New service account and IAM roles defined in `terraform/iam.tf`.
- **GitHub Actions**: Updates to `.github/workflows/android-release.yml` to include Play Store upload steps and secrets.
- **Security**: Addition of a new GitHub Secret for the Google Play service account JSON key.
