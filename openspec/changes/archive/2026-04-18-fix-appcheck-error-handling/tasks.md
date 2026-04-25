## 1. Security Enforcement Implementation

- [x] 1.1 Wrap `FirebaseAppCheck.instance.activate` in a try-catch block in `lib/main.dart`.
- [x] 1.2 Implement logic to detect specific AppCheck/ReCAPTCHA security rejection errors.
- [x] 1.3 Add `Sentry.captureMessage` call with tags to track rejections without logging unhandled exceptions.

## 2. Security UI Implementation

- [x] 2.1 Add an \"Abusive Traffic Detected\" error state to `AppInitializer`'s `FutureBuilder`.
- [x] 2.2 Design and implement the security notice UI to inform the user they have been flagged.
- [x] 2.3 Ensure that security-related failures do not show a \"Retry\" button that bypasses the check.

## 3. Validation

- [x] 3.1 Run `flutter analyze` to ensure code quality.
- [x] 3.2 Verify that a simulated AppCheck failure displays the correct security notice and increments the Sentry rejection count.
