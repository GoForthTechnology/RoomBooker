## Why

The `KioskDashboard` screen includes a 200px "SYSTEM LOGS" diagnostic panel at the bottom of the UI that was useful during early development but now clutters the production kiosk display. It should be removed so the kiosk presents a clean, hardware-appropriate interface.

## What Changes

- Remove the `_buildDiagnosticSection()` widget and all log-related state (`_logs` list) from `KioskDashboard`.
- Remove all `setState(() => _logs.insert(...))` calls from `_launchMeeting`, `_onQuickBook`, and `_checkServiceStatus`.
- Trim the `diagnosticChannel.setMethodCallHandler` to retain only the `_isServiceRunning` update (needed for the "ENABLE AUTOMATION SERVICE" button) while dropping the log collection.
- The `diagnosticChannel` MethodChannel itself remains, as it is still needed to receive service-connected status from the native Accessibility Service.

## Capabilities

### New Capabilities
<!-- none -->

### Modified Capabilities
<!-- none — this is a pure UI cleanup with no spec-level behavior change -->

## Impact

- `packages/roombooker_kiosk/lib/main.dart` (`_KioskDashboardState`): field removal, method removal, handler simplification.
- No changes to tests (no tests cover the diagnostic panel).
- No Firestore, routing, or service-layer changes.
