# Gemini Project Guide: Room Booker

This document provides instructions for interacting with the Room Booker Flutter project using Gemini.

## Project Overview

This is a Flutter application for managing room reservations. It uses Firebase for backend services, including authentication, Firestore, and Analytics.

## Tech Stack

- **Framework:** Flutter (SDK version >=3.4.3 <4.0.0)
- **Backend:** Firebase (Authentication, Firestore, Analytics, Performance Monitoring)
- **Routing:** `auto_route`
- **State Management:** `provider`
- **Error Reporting:** `sentry_flutter`
- **Calendar UI:** `syncfusion_flutter_calendar`

## Architecture

- **Booking Logic:** All booking-related logic and data access must go through `BookingService`.
- **BookingRepo:** The `BookingRepo` is an internal data access layer for `BookingService` and **must not** be accessed directly by UI components or ViewModels. It is not a `ChangeNotifier` to enforce this rule.

## Getting Started

### Running the Application

To run the application, use the following command:

```bash
flutter run
```

### Running Tests

To run the unit and widget tests, use the following command:

```bash
flutter test
```

## Code Generation

This project uses `build_runner` for code generation, primarily for `auto_route` and `json_serializable`. If you make changes that require code generation (e.g., adding new routes or serializable classes), run the following command:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Linting

The project uses the `flutter_lints` package for code analysis. To run the linter, use the following command:

```bash
flutter analyze
```

The linting rules are defined in the `analysis_options.yaml` file.

## Infrastructure (Terraform)

The project's infrastructure on Google Cloud and Firebase is managed using Terraform.

- **Location:** `terraform/`
- **State Management:** Remote state is stored in a GCS bucket (`roombooker-5e947-terraform-state`).
- **Commands:**
  - `terraform init`: Initialize the working directory.
  - `terraform plan`: Preview changes.
  - `terraform apply`: Apply changes to the infrastructure.

## Security Guidelines

**CRITICAL: Never commit secrets, credentials, or keys to the repository.**

This includes, but is not limited to:
- Service account JSON files (`*.json`).
- Base64 encoded versions of keys or secrets (`*.base64`).
- Keystore files (`*.jks`, `*.keystore`).
- `.env` files or the `.secrets` file used for local CI testing.

If you are working with tools or scripts that require these files locally, ensure they are listed in `.gitignore`. Any changes involving new types of credentials must also include an update to `.gitignore` to prevent accidental exposure.

## CI/CD (Android)

The project uses GitHub Actions for automated Android builds and distribution.

- **Workflow:** `.github/workflows/android-release.yml`
- **Trigger:** Pushing a commit with a message matching "Cut v#.#.#+#" (e.g., via `scripts/bump_version.sh`).
- **Distribution:** Signed Android artifacts are automatically distributed:
  - **Firebase App Distribution:** Signed APK for internal testing.
  - **Google Play Console:** Signed AAB uploaded to the **Internal Track**.

### Local CI Testing (with `act`)

You can test your GitHub Actions workflows locally using [act](https://github.com/nektos/act).

1. **Install act:** Follow the [installation guide](https://github.com/nektos/act#installation).
2. **Setup Secrets:** Copy `.secrets.example` to `.secrets` and fill in the required values. **Never commit the `.secrets` file.**
3. **Run a Workflow:**
   ```bash
   # Run the Android release workflow simulating a tag push
   act push -s GITHUB_TOKEN=$(gh auth token) --secret-file .secrets -g v1.2.20+48
   ```
   *Note: Using `-g` allows you to simulate the tag trigger.*

- **Secrets Required:**
  - `ANDROID_KEYSTORE_BASE64`: The production keystore file encoded in Base64.
  - `ANDROID_KEYSTORE_PASSWORD`: Password for the keystore.
  - `ANDROID_KEY_ALIAS`: Alias for the signing key.
  - `ANDROID_KEY_PASSWORD`: Password for the signing key.
  - `FIREBASE_ANDROID_APP_ID`: The App ID from Firebase Console.
  - `FIREBASE_SERVICE_ACCOUNT_KEY`: The JSON key for Firebase distribution.
  - `GOOGLE_PLAY_SERVICE_ACCOUNT_KEY`: The JSON key for Play Store publishing (managed via Terraform).

## Google Play Setup (One-time)

1.  **Invite Service Account:** In the Play Console, invite `google-play-deployer@roombooker-5e947.iam.gserviceaccount.com` and grant it Admin or Release Manager permissions.
2.  **Manual Upload:** Perform the first upload of a signed `.aab` manually to the Play Console to establish the package.

## Project Structure

- `lib/`: Contains the main source code for the application.
  - `lib/data/`: Data models, repositories, and services.
  - `lib/logic/`: Business logic.
  - `lib/ui/`: UI components and screens.
  - `lib/router.dart`: Route definitions for `auto_route`.
- `test/`: Contains the tests for the application.
- `firebase.json`: Configuration for Firebase services.
- `pubspec.yaml`: Project dependencies and configuration.

## Development Workflow

When working on tasks, you **MUST** always follow the OpenSpec flow:
1. **Propose:** Propose the changes (e.g., using `openspec change new "<name>"`) and outline the plan.
2. **Ask for Review:** Ask the user for review and approval of the proposal.
3. **Apply:** Apply the code changes.
4. **Ask for Verification:** Ask the user to verify the changes.
5. **Archive and Commit:** Run `openspec archive <change>` and commit the changes using `git`.
