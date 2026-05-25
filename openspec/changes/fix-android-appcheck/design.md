## Context

The current implementation of App Check in `lib/main.dart` is limited to Web:

```dart
  await FirebaseAppCheck.instance.activate(
    providerWeb: ReCaptchaV3Provider(
      '6Lej2S0sAAAAAKBEX9lCwb1g4RBlAMb3dXeJHWv-',
    ),
  );
```

This causes all Android (and iOS) requests to fail App Check validation.

## Goals / Non-Goals

**Goals:**
- Correctly initialize App Check for Android, iOS, and Web.
- Support both Debug and Production environments for mobile.
- Restore functionality for Android users.

**Non-Goals:**
- Changing existing Web Recaptcha keys (unless verified broken).
- Implementing Recaptcha Enterprise on Android (Play Integrity is preferred).

## Decisions

### 1. Multi-Platform Initialization
- **Decision**: Update `activate` to use platform-specific providers.
- **Rationale**: App Check requires different attestation methods for each platform (Play Integrity for Android, Device Check/App Attest for Apple, Recaptcha for Web).

### 2. Conditional Debug Providers
- **Decision**: Use `kDebugMode` to toggle between `debug` and production providers.
- **Rationale**: The `debug` provider allows developers to use a "debug token" (visible in logs) to bypass attestation checks during local development or on emulators.

## Risks / Trade-offs

- **[Risk]**: Play Integrity requires GMS (Google Mobile Services).
- **[Risk]**: Debug tokens must be manually added to the Firebase Console by developers.
