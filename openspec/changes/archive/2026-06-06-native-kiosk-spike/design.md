## Context

Phase 2 is a technical spike to establish the foundation for the `roombooker_kiosk` application. The primary challenge is programmatically joining third-party video calls (Google Meet, Microsoft Teams, Zoom) from within a locked-down tablet environment. 

## Goals / Non-Goals

**Goals:**
- Scaffold the `roombooker_kiosk` Flutter app.
- Implement a native Kotlin `AccessibilityService` for UI automation.
- Prove "One-Touch Join" functionality for Google Meet.
- Establish `LockTaskMode` (Kiosk Mode) plumbing.
- Connect Kiosk to `roombooker_core` for future logic.

**Non-Goals:**
- Production-ready Dashboard UI.
- Firestore integration for real-time room status (Phase 3).
- Provisioning/Setup flows (Phase 3).
- Teams/Zoom automation (Spike will prioritize Google Meet first, with placeholders for others).

## Decisions

### 1. Automation Method: Android Accessibility Service
- **Decision**: Use `AccessibilityService` (Kotlin) to perform virtual clicks on "Join" buttons.
- **Rationale**: External apps like Google Meet do not expose "auto-join" parameters via deep links. Accessibility Services can inspect the window tree and simulate user input safely.
- **Alternatives**: UI Automator (too heavy, intended for testing), Deep Links (insufficient for bypassing lobbies).

### 2. Kiosk Management: Device Admin + `kiosk_mode`
- **Decision**: Register the app as a `DeviceAdmin` in `AndroidManifest.xml` and use the `kiosk_mode` Dart package.
- **Rationale**: `kiosk_mode` provides a clean Dart wrapper for `LockTaskMode`, while `DeviceAdmin` allows the app to be "whitelisted" for pinning without recurring user prompts.

### 3. Intent Strategy: Package-Specific Intents
- **Decision**: Use explicit package names (`com.google.android.apps.meetings`, etc.) when launching meeting URLs.
- **Rationale**: Ensures the tablet opens the correct app rather than a browser, triggering the `AccessibilityService` reliably.

## Risks / Trade-offs

- **[Risk] Conferencing App UI Changes** → **Mitigation**: The `AccessibilityService` will use string-matching and resource-ID matching for buttons. We will implement a "Watch and Retry" loop (3 seconds) to handle slow loading screens.
- **[Risk] Permission Friction** → **Mitigation**: Since these are specialized enterprise tablets, we will side-load the APK and manually grant "System Admin" and "Accessibility" permissions once per device.
