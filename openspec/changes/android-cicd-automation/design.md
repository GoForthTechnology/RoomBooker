## Context

The Room Booker application currently lacks automated infrastructure management and Android CI/CD. This design introduces Terraform for IaC and a GitHub Actions pipeline for Android builds and distribution.

## Goals / Non-Goals

**Goals:**
- Implement Terraform for managing Firebase/GCP resources.
- Use a remote GCS backend for Terraform state.
- Automate Android build signing using a production keystore.
- Automate Android distribution to Firebase App Distribution.
- Ensure version parity between `pubspec.yaml` and Android build artifacts.

**Non-Goals:**
- Automated iOS CI/CD (to be handled in a future change).
- Automated Google Play Store submission (limited to Internal/Firebase App Distro for now).
- Migration of existing manually created Firebase resources (we will import or define new ones as needed).

## Decisions

### 1. Terraform for IaC
- **Decision**: Use Terraform to manage Firebase and GCP resources.
- **Rationale**: Provides a declarative, version-controlled way to manage infrastructure, making it portable and repeatable.
- **Alternatives**: Manual console management (prone to errors) or Firebase CLI (less comprehensive for general GCP resources).

### 2. GCS Remote Backend
- **Decision**: Store Terraform state in a GCS bucket.
- **Rationale**: Ensures state is shared and protected, preventing conflicts during concurrent updates and providing a history of changes.
- **Alternatives**: Local state (unsuitable for CI/CD or team environments).

### 3. Keystore Management via GitHub Secrets
- **Decision**: Store the Base64-encoded keystore and passwords in GitHub Secrets.
- **Rationale**: Keeps sensitive credentials out of the codebase while allowing the CI/CD pipeline to sign release builds.
- **Alternatives**: Committing the keystore to the repo (major security risk) or using a cloud HSM (overkill for this scale).

### 4. Firebase App Distribution for Internal Releases
- **Decision**: Use Firebase App Distribution as the primary internal testing channel.
- **Rationale**: Seamless integration with the Firebase ecosystem and easy tester management without the overhead of Play Console tracks for early builds.

## Risks / Trade-offs

- **[Risk]**: Keystore loss → **Mitigation**: Securely back up the original `.jks` file in a password manager or secure vault outside of the repo.
- **[Risk]**: Terraform state corruption → **Mitigation**: Enable versioning on the GCS bucket used for the state backend.
- **[Trade-off]**: Terraform complexity → **Mitigation**: Keep the initial configuration minimal and focused on the necessary Firebase/GCP resources.
