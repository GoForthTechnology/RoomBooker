## Context

The Room Booker application currently uses Firebase App Distribution for internal Android testing. Expanding to the Google Play Store requires a more formal release process, including Play Store API integration for automated uploads.

## Goals / Non-Goals

**Goals:**
- Automate Android App Bundle (.aab) uploads to Google Play Console.
- Manage Play Store service account credentials via Terraform.
- Support multi-track distribution (Internal, Alpha, Production).
- Maintain version consistency between `pubspec.yaml` and Play Store releases.

**Non-Goals:**
- Automating iOS App Store publishing (future change).
- Managing Play Store listing metadata (screenshots, descriptions) via code (to be handled manually in the console).
- Initial manual upload to Play Console (required by Google to establish the package).

## Decisions

### 1. Service Account for Play Store API
- **Decision**: Create a dedicated service account in Terraform with the necessary IAM roles for Google Play Android Developer API access.
- **Rationale**: Provides a secure, automated way for GitHub Actions to interact with the Play Store without using personal credentials.
- **Alternatives**: Manual uploads (not scalable) or using an existing broad-access service account (violates least privilege).

### 2. GitHub Actions Integration
- **Decision**: Use the `r0adkll/upload-google-play` action in the existing `android-release.yml` workflow.
- **Rationale**: Industry standard for Flutter/Android Play Store automation with robust support for tracks and release notes.
- **Alternatives**: Custom shell scripts using the Google Play API (high maintenance).

### 3. Build Artifact Selection
- **Decision**: Build both `.apk` (for Firebase) and `.aab` (for Play Store) in the release workflow.
- **Rationale**: APKs are still useful for quick internal sharing via Firebase, while AABs are required by Google Play.
- **Alternatives**: Build only AAB (would break the current Firebase APK-based flow).

## Risks / Trade-offs

- **[Risk]**: Service account permissions mismatch → **Mitigation**: Test the service account with an "internal" track upload before attempting production.
- **[Risk]**: Google Play API rate limits → **Mitigation**: Only trigger Play Store uploads on official version bumps (not every commit).
- **[Trade-off]**: Increased build time → **Mitigation**: Building both APK and AAB adds ~2-3 minutes to the CI run, which is acceptable for release cycles.
