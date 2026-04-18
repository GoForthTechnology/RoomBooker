## Context

The `stopColdStartTrace` method is currently called within the `builder` of a `StreamBuilder` in `BookingCalendarView`. This builder executes on every rebuild of the calendar, which includes every frame during a window resize. In `DebugLoggingService`, this method prints a log message every time it's called, leading to log spam and potentially inaccurate performance metrics if they were being tracked in debug mode.

## Goals / Non-Goals

**Goals:**
- Eliminate redundant "Stopping cold start trace" logs during UI rebuilds.
- Ensure the cold start trace is only stopped once per application lifecycle.

**Non-Goals:**
- Refactoring the entire logging service.
- Changing how cold starts are measured beyond the stop trigger.

## Decisions

### 1. Move the Stop Trigger
- **Decision**: Remove the `stopColdStartTrace()` call from `lib/ui/widgets/booking_calendar/booking_calendar.dart`.
- **Rationale**: The UI builder is the wrong place for one-time initialization or teardown logic because builders must be idempotent and can be called many times.

### 2. Guard the Debug Logger
- **Decision**: Add a boolean guard to `DebugLoggingService.stopColdStartTrace` similar to the one in `SentryLoggingService`.
- **Rationale**: This provides a second layer of defense against accidental redundant calls from other parts of the app.

### 3. New Placement for Stop Trace
- **Decision**: Call `stopColdStartTrace()` once after the initial render of the main application view.
- **Alternatives Considered**: 
    - `main.dart` after `runApp`: Too early, doesn't account for UI frame rendering.
    - `initState` of a top-level widget: Better, but still might execute before the first frame is fully drawn.
- **Selected Approach**: Use `WidgetsBinding.instance.addPostFrameCallback` in a top-level widget or the landing screen to ensure it only runs once after the first frame.

## Risks / Trade-offs

- [Risk] Moving the trigger might result in the trace never being stopped if the specific code path isn't hit. → [Mitigation] Place it in a guaranteed code path like the landing screen or main app wrapper.
