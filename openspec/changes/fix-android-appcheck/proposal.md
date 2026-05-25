## Why

Android users are experiencing Auth failures and errors when loading organizations. This is likely because Firebase App Check is enforced on the backend but only initialized for Web in the Flutter application. Without a valid App Check token from a mobile-specific provider (like Play Integrity), mobile clients are rejected by Firebase services.

## What Changes

- **App Check Initialization**: Update the `FirebaseAppCheck.instance.activate` call in `lib/main.dart` to include `androidProvider` and `appleProvider`.
- **Environment Support**: Use `AndroidProvider.debug` and `AppleProvider.debug` when the app is running in debug mode to facilitate testing.
- **Production Readiness**: Use `AndroidProvider.playIntegrity` for production Android builds.

## Capabilities

### New Capabilities
- `android-appcheck`: Implements robust App Check support for Android using Play Integrity and Debug providers.

## Impact

- **`lib/main.dart`**: Logic change in the initialization sequence.
- **Firebase Connectivity**: Restores access to Firestore and Auth for Android devices.
- **Development Workflow**: Requires setting up debug tokens in the Firebase Console for local Android testing.
