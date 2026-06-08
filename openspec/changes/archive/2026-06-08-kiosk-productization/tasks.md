## 1. Setup & Scaffolding

- [x] 1.1 Add `presentation_displays`, `flutter_inappwebview`, and `flutter_secure_storage` to `roombooker_kiosk/pubspec.yaml`.
- [x] 1.2 Define the `KioskIdentity` and `ProvisioningHandshake` entities in `roombooker_core`.
- [x] 1.3 Initialize the `provisioning_codes` collection and security rules.

## 2. Provisioning Flow Implementation

- [x] 2.1 Implement `ProvisioningService` in `roombooker_core` to handle code generation and consumption.
- [x] 2.2 Add "Provision Kiosk" capability to the Portal app's Room Management screen.
- [x] 2.3 Build the "Enter Activation Code" UI in the Kiosk application.
- [x] 2.4 Implement Secure Storage persistence for `orgID` and `roomID` on the Kiosk.

## 3. Dual-Display Orchestration

- [x] 3.1 Implement `DisplayOrchestrator` to detect HDMI displays and trigger the Stage UI.
- [x] 3.2 Create the `MeetingStageWidget` for rendering content on the Secondary Display (TV).
- [x] 3.3 Implement a shared `KioskStateNotifier` to synchronize state between Tablet and TV contexts.
- [x] 3.4 Build the high-contrast Dashboard UI (Available/Busy/Transition states).

## 4. Productized Meeting Integration

- [x] 4.1 Implement `MeetingOrchestrator` to handle display routing for Native conferencing apps.
- [x] 4.2 Build the `IntegratedWebViewStage` for Desktop-spoofed meeting sessions.
- [x] 4.3 Implement JavaScript Join Automation for the WebView Stage.
- [x] 4.4 Implement Android `RECEIVE_BOOT_COMPLETED` logic to ensure Kiosk re-entry after power failure.

## 5. Verification & Finalization

- [x] 5.1 Verify successful provisioning handshake between Portal and Kiosk.
- [x] 5.2 Verify Dual-Display context separation using physical hardware or simulated display.
- [x] 5.3 Run `flutter-smoke-test` on both Portal and Kiosk packages.
- [x] 5.4 Document the new Kiosk production features in `GEMINI.md`.
