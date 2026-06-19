## REMOVED Requirements

### Requirement: Diagnostic Log Panel
**Reason**: The on-screen SYSTEM LOGS panel was a development aid and is no longer appropriate for a production kiosk display. Log output is still available via `adb logcat` (`debugPrint`).
**Migration**: No user-facing migration needed. Developers requiring on-device log visibility should use `adb logcat` during hardware testing.
