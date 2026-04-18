## 1. Cleanup and Defensive Guards

- [x] 1.1 Add boolean guard to `DebugLoggingService.stopColdStartTrace` in `lib/data/services/logging_service.dart`.
- [x] 1.2 Remove the `stopColdStartTrace()` call from `lib/ui/widgets/booking_calendar/booking_calendar.dart`.

## 2. Implement Correct Lifecycle Trigger

- [x] 2.1 Identify a suitable top-level widget (e.g., `MyApp` or `LandingScreen`) to host the one-time stop call.
- [x] 2.2 Implement `addPostFrameCallback` to call `stopColdStartTrace()` once after the first frame.

## 3. Verification

- [x] 3.1 Verify that "Stopping cold start trace" log only appears once on app launch.
- [x] 3.2 Verify that resizing the window no longer produces "Stopping cold start trace" logs.
