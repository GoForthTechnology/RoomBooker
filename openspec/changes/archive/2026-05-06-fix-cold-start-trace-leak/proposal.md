## Why

The "cold start" performance trace is currently being stopped inside a UI builder that executes on every rebuild, including window resizes. This leads to redundant logs and incorrect performance data, as cold start monitoring should only trigger once during the initial application load.

## What Changes

- **Move** the `stopColdStartTrace` call from the `BookingCalendarView` builder to a more appropriate location that only executes once (e.g., after the initial render of the main screen).
- **Ensure** that the logging service internally guards against multiple stop calls if necessary, although the primary fix is to avoid redundant calls.

## Capabilities

### New Capabilities
- None

### Modified Capabilities
- `architecture`: Clarify the usage and lifecycle of the cold start tracing mechanism.

## Impact

- `lib/ui/widgets/booking_calendar/booking_calendar.dart`: Remove the redundant call.
- `lib/main.dart` or a top-level widget: Potentially move the call here or handle it via a one-time effect.
