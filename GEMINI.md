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

## Project Structure

- `lib/`: Contains the main source code for the application.
  - `lib/data/`: Data models, repositories, and services.
  - `lib/logic/`: Business logic.
  - `lib/ui/`: UI components and screens.
  - `lib/router.dart`: Route definitions for `auto_route`.
- `test/`: Contains the tests for the application.
- `firebase.json`: Configuration for Firebase services.
- `pubspec.yaml`: Project dependencies and configuration.
