---
name: flutter-smoke-test
description: Performs a headless smoke test of a Flutter application to ensure it boots to a landing page. Use when you need to verify that a structural change (like a monorepo refactor) hasn't broken the application startup sequence.
---

# Flutter Smoke Test

This skill automates the verification of a Flutter application's boot sequence using a combination of background server monitoring and headless widget testing.

## Workflow

### 1. Identify the App Package
Determine which package in the monorepo contains the main application (e.g., `packages/roombooker_portal`).

### 2. Verify Background Startup
Start the application on a local web server to check for critical compilation or early initialization errors.

```bash
# In the app directory
flutter run -d web-server --web-port 8080 --web-hostname 127.0.0.1
```

- **Wait 30 seconds** for the build to complete.
- **Read the logs** for errors (e.g., `Exception`, `Error`, `Crash`).
- **Check Connectivity**: `curl -s http://127.0.0.1:8080` should return the index HTML.

### 3. Headless Widget Assertion
Create or run a widget test that "pumps" the entire application to verify the widget tree is constructed without crashing.

#### Example Smoke Test (`test/smoke_test.dart`)
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
// Add project-specific imports for MyApp and Mocks
...
void main() {
  testWidgets('App boots to LandingScreen', (tester) async {
    // 1. Mock Firebase/Sentry/Services
    // 2. Pump MyApp
    // 3. expect(find.byType(LandingScreen), findsOneWidget);
  });
}
```

### 4. Teardown
Ensure all background processes are killed after verification.

## Troubleshooting

- **Missing Desktop Support**: Ensure the package has the relevant `android/`, `ios/`, or `web/` directories.
- **Firebase Initialization**: If the app crashes on `Firebase.initializeApp`, verify that `firebase_options.dart` is present and correctly referenced.
- **Monorepo Imports**: If compilation fails, check for legacy `package:room_booker/` imports that should now be `package:roombooker_core/` or `package:roombooker_portal/`.
