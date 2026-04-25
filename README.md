# Room Booker

Room Booker is a cross-platform Flutter application (iOS, Android, Web) designed to streamline the process of reserving shared spaces. It allows users to view availability, book rooms, and manage reservations with ease, supporting both guest access and authenticated user accounts.

## Features

*   **Room Calendar:** A clear, interactive calendar view to check room availability.
*   **Guest Booking:** Guests can view schedules and request bookings without creating an account (email verification required).
*   **User Accounts:** Sign up or log in using Email or Google to manage bookings centrally.
*   **Booking Management:** Create, view, and cancel reservations.
*   **Organization Support:** Manage settings and join organizations.
*   **Cross-Platform:** Seamless experience across Mobile and Web.

## Tech Stack

*   **Frontend:** Flutter (Dart)
*   **Backend:** Firebase (Firestore, Auth, Functions, App Check)
*   **State Management:** Provider
*   **Routing:** Auto Route
*   **Calendar:** Syncfusion Flutter Calendar
*   **Monitoring:** Sentry

## Getting Started

### Prerequisites

*   Flutter SDK (>=3.8.0 <4.0.0)
*   Dart SDK

### Installation

1.  Clone the repository:
    ```bash
    git clone https://github.com/GoForthTechnology/RoomBooker.git
    ```
2.  Install dependencies:
    ```bash
    flutter pub get
    ```
3.  Run the app:
    ```bash
    flutter run
    ```

## Configuration

### Firebase

This project uses Firebase for backend services. You need to configure it with your own Firebase project.

1.  Install the [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/).
2.  Run `flutterfire configure` to generate `lib/firebase_options.dart`.

### Sentry

Sentry is used for error tracking and performance monitoring. The DSN is configured in `lib/main.dart`.

For production builds (via GitHub Actions), the project is configured to upload source maps and debug symbols to Sentry. This requires a `SENTRY_AUTH_TOKEN` to be set as a GitHub Secret.

## Deployment & Observability

### Continuous Deployment (CD)

The project uses GitHub Actions for automatic deployment to Firebase Hosting when changes are merged into the `main` branch with a specific versioning tag (e.g., `Cut v1.2.3+10`).

### Production Error Reporting

To ensure production errors have readable stack traces, the deployment pipeline:
1.  Generates Web source maps using the `--source-maps` flag during `flutter build web`.
2.  Uploads these maps and Dart symbols to Sentry using the `sentry_dart_plugin`.

**Setup Requirement:**
A `SENTRY_AUTH_TOKEN` must be added to the GitHub repository secrets. You can generate this token in your Sentry User Settings.

## Project Structure

*   `lib/`: Main application code.
    *   `data/`: Data layer (Repositories, Services).
    *   `logic/`: Business logic.
    *   `ui/`: User Interface (Screens, Widgets).
    *   `router.dart`: Navigation configuration.
*   `functions/`: Firebase Cloud Functions.
