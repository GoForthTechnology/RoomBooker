## Context

`KioskDashboard` in `packages/roombooker_kiosk/lib/main.dart` renders a fixed-height (200px) black diagnostic panel via `_buildDiagnosticSection()`. The panel displays a `_logs: List<String>` that is populated by:

- `diagnosticChannel.setMethodCallHandler` (native Accessibility Service events)
- Inline `setState(() => _logs.insert(0, ...))` calls in `_launchMeeting`, `_onQuickBook`, and `_checkServiceStatus`

The `diagnosticChannel` MethodChannel must be retained because it also drives `_isServiceRunning`, which controls the "ENABLE AUTOMATION SERVICE" button.

## Goals / Non-Goals

**Goals:**
- Remove the diagnostic panel from the kiosk display entirely.
- Eliminate all in-memory log accumulation (`_logs` list).
- Retain native→Flutter communication for `_isServiceRunning` state.

**Non-Goals:**
- Replacing the logs with a hidden/conditional debug mode.
- Adding any remote logging or observability in this change.
- Touching the Portal app or core package.

## Decisions

**Keep `diagnosticChannel`, remove log handling:** The method call handler in `initState` is the sole source of `SERVICE_CONNECTED` events that flip `_isServiceRunning`. Rather than deleting the channel entirely, slim the handler to only update that flag and drop the `_logs.insert` side-effect.

**Delete `_logs` entirely:** No in-memory accumulation, no conditional show/hide. A show/hide toggle would preserve the pattern for debugging; full deletion signals this is production-only code now.

## Risks / Trade-offs

- [Risk] Loss of on-device debug visibility during hardware iteration → Mitigation: `debugPrint` calls are still present for logcat output; developers can use `adb logcat` during testing.
