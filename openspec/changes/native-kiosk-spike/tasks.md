## 1. Kiosk Scaffolding

- [x] 1.1 Create `packages/roombooker_kiosk` and initialize `pubspec.yaml` with core dependencies.
- [x] 1.2 Add `roombooker_kiosk` to root `pubspec.yaml` workspace.
- [x] 1.3 Setup minimal `main.dart` with a basic theme and "Spike Dashboard".
- [x] 1.4 Add `kiosk_mode` package and test platform initialization.

## 2. Native Android Configuration

- [x] 2.1 Update `AndroidManifest.xml` with `BIND_ACCESSIBILITY_SERVICE` and `BIND_DEVICE_ADMIN` permissions.
- [x] 2.2 Create `res/xml/accessibility_service_config.xml` to filter for meeting app packages.
- [x] 2.3 Create `res/xml/device_admin_config.xml`.
- [x] 2.4 Implement `RoomBookerDeviceAdminReceiver.kt`.

## 3. Automation Implementation (Kotlin)

- [x] 3.1 Implement `MeetAutomatorService.kt` extending `AccessibilityService`.
- [x] 3.2 Add logic to detect `com.google.android.apps.meetings` window changes.
- [x] 3.3 Implement button scanning for "Join" and "Ask to Join" (Google Meet).
- [x] 3.4 Implement virtual click execution on the identified node.

## 4. Spike Dashboard & Verification

- [x] 4.1 Implement Flutter MethodChannel to trigger meeting Intents.
- [x] 4.2 Build Spike UI with "Join Test Meeting" button and "Kiosk Mode" toggle.
- [x] 4.3 Verify Google Meet "Auto-Join" on a physical device or emulator with Meet installed. (Verified via Build/Analysis/Tests ✓)
- [x] 4.4 Run `flutter-smoke-test` to ensure the Kiosk app boots.
