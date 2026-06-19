## 1. Remove Diagnostic Panel from KioskDashboard

- [x] 1.1 Delete `final List<String> _logs = [];` field from `_KioskDashboardState`
- [x] 1.2 Slim `diagnosticChannel.setMethodCallHandler` in `initState` to only update `_isServiceRunning` (drop `_logs.insert` and length cap)
- [x] 1.3 Remove `setState(() => _logs.insert(0, ...))` call from `_checkServiceStatus` error branch
- [x] 1.4 Remove `setState(() => _logs.insert(0, ...))` calls from `_launchMeeting`
- [x] 1.5 Remove `setState(() => _logs.insert(0, ...))` calls from `_onQuickBook` (both success and error paths)
- [x] 1.6 Remove `_buildDiagnosticSection()` call from the `build()` body's `Column` children
- [x] 1.7 Delete the `_buildDiagnosticSection()` method

## 2. Validate

- [x] 2.1 Run `flutter analyze` in `packages/roombooker_kiosk` and confirm no errors
- [x] 2.2 Run `flutter test` in `packages/roombooker_kiosk` and confirm all tests pass
