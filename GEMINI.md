# Gemini Project Guide: Room Booker

This document provides instructions for interacting with the Room Booker Flutter project using Gemini.
## Project Overview

This is a Flutter monorepo workspace for managing room reservations. It consists of multiple packages:
- **roombooker_core**: Shared domain logic, data entities, and Firestore services.
- **roombooker_portal**: The primary user-facing mobile and web application.
- **roombooker_kiosk**: Specialized hardware terminal for meeting rooms. Supports Dual-Display (Tablet + TV) and "One-Touch Join" automation.

## Kiosk Production Workflow

### Provisioning a New Device

1.  **Generate Code**: In the **Portal App**, navigate to "Organization Settings" -> "Rooms".
2.  **Link Kiosk**: Tap the **Monitor Icon** (Provision Kiosk) next to the desired room.
3.  **Activate**: Enter the 6-digit code on the fresh Kiosk terminal.
4.  **Auto-Lock**: Once linked, the Kiosk will automatically enter **LockTaskMode** (Kiosk Mode).

### Dual-Display Setup

The Kiosk is designed for a **USB-C Hub** connection:
- **Tablet (Primary)**: Acts as the **Controller**. Shows meeting status, "Join" buttons, and administrative controls.
- **TV (Secondary)**: Acts as the **Stage**. Renders the video conference session via HDMI.

### Automation (Autopilot)

- **MeetAutomatorService**: A native Android Accessibility Service that automatically clicks "Join" buttons.
- **One-Shot Auth**: Automation is only authorized for a single click per meeting launch to prevent loops.
- **WebView Fallback**: If a native app cannot be routed to the TV, the system uses a Desktop-spoofed WebView on the secondary display.

### Production Controls

- **One-Touch Join**: When a meeting is active and contains a URL (Google Meet/Teams/Zoom), a large "JOIN MEETING" button appears on the dashboard.
- **Programmatic Lockdown**: The "Lock" icon in the AppBar triggers `LockTaskMode` to pin the application and disable system navigation.
- **Safe De-provisioning**: To prevent accidental resets, the "De-provision" action is hidden inside the "Device Info" dialog under a confirmation flow.

## Getting Started
...

- **Backend:** Firebase (Authentication, Firestore, Analytics, Performance Monitoring)
- **Routing:** `auto_route`
- **State Management:** `provider`
- **Error Reporting:** `sentry_flutter`
- **Calendar UI:** `syncfusion_flutter_calendar`

## Architecture

- **Shared Core:** All booking-related logic and data access lives in `packages/roombooker_core`. UI components MUST NOT implement business logic or direct repository access.
- **Portal App:** The primary interface for users and admins lives in `packages/roombooker_portal`.

## Getting Started

### Workspace Setup

This project uses Flutter Workspaces. Initialize all packages from the root:

```bash
flutter pub get
```

### Running the Application (Portal)

To run the primary Portal application:

```bash
cd packages/roombooker_portal
flutter run
```

### Running Tests

Run tests for all packages from the root:

```bash
# Core tests
(cd packages/roombooker_core && flutter test)

# Portal tests
(cd packages/roombooker_portal && flutter test)
```

## Testing Standards

### Test Maintenance
- **Always update existing tests** to match new implementation logic or UI changes. 
- **NEVER remove a test file** or test case without explicit permission from the user. If you believe a test is truly obsolete, you MUST ask for permission before deleting it.
- **Coverage**: All new functionality, data entities, and business logic MUST be covered by appropriate unit or widget tests.

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

**Note:** You can use the `gh` CLI command within this environment to update GitHub secrets, variables, and other repository settings (e.g., `gh secret set GOOGLE_PLAY_SERVICE_ACCOUNT_KEY -b"$(terraform output -raw google_play_service_account_key)"`).

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

### Production Fingerprints (Google Play App Signing)
- **SHA-1**: `15:80:6B:C9:60:0B:C6:16:3D:AB:D4:1F:2D:5E:3A:74:27:22:24:F3`
- **SHA-256**: `1B:61:99:A2:6D:EE:E1:BF:EE:F8:2B:57:A5:4B:CF:C6:FA:4E:66:C2:00:FB:91:66:B5:1E:FA:A5:73:08:54:80`

### Troubleshooting Sign-in Issues
If the Play Store build fails to sign in:
1. Ensure the **SHA-1** above is registered in the Firebase Console (Project Settings > General > Android app).
2. Ensure **Play Integrity** is enabled in the Firebase Console (App Check > Play Integrity) with the **SHA-256** above.

## Google Play Setup (One-time)

1.  **Invite Service Account:** In the Play Console, invite `google-play-deployer@roombooker-5e947.iam.gserviceaccount.com` and grant it Admin or Release Manager permissions.
2.  **Manual Upload:** Perform the first upload of a signed `.aab` manually to the Play Console to establish the package.

## Project Structure

- `packages/roombooker_core/`: Core business logic and data.
- `packages/roombooker_portal/`: Primary application (Portal).
- `firebase.json`: Configuration for Firebase services.
- `pubspec.yaml`: Workspace root configuration.

## Development Workflow

When working on tasks, you **MUST** always follow the OpenSpec flow:
...
6. **Archive and Commit:** Run `openspec archive <change>` and commit the changes using `git`.

### Kiosk Development Iteration (APK Server)

For rapid iteration on the hardware-bound `roombooker_kiosk` application:

1.  **Build the Spike APK**:
    ```bash
    cd packages/roombooker_kiosk/android && ./gradlew assembleDebug --no-daemon
    ```
2.  **Serve for LAN Download**:
    Start a temporary server from the APK output directory:
    ```bash
    cd packages/roombooker_kiosk/build/app/outputs/flutter-apk/
    python3 -m http.server 8000 --bind 0.0.0.0
    ```
3.  **Install on Hardware**:
    Access `http://<server-lan-ip>:8000` from the device's browser to download and install.

This loop allows for testing native features (Accessibility Services, Kiosk Mode) that cannot be verified in a headless environment.
