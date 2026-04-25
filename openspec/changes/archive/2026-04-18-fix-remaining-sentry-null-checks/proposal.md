## Why

Despite a previous fix for `BookingCalendarViewModel`, Sentry continues to report "Null check operator used on a null value" exceptions in production (specifically in `main.dart.js`). Further investigation revealed several other locations where `CalendarController` properties are accessed using the null assertion operator (`!`) without safe fallbacks, particularly in `ViewBookingsViewModel`. These likely trigger crashes if a user interacts with the UI (e.g., clicking "Add New Booking") before the calendar is fully initialized.

## What Changes

- Eliminate all remaining unsafe null assertions (`!`) on `CalendarController.displayDate` and `CalendarController.view` in `ViewBookingsViewModel`.
- Provide sensible fallbacks (`DateTime.now()` and `CalendarView.month`) for these properties to ensure stability during initialization or rapid UI transitions.
- Review and safely refactor other high-risk null assertions identified in UI code.

## Capabilities

### New Capabilities
- none

### Modified Capabilities
- `ui-ux`: Strengthen stability requirements for UI interactions during asynchronous state transitions.

## Impact

The change will improve the robustness of the Room Booker application, specifically preventing crashes when users interact with the booking screen early in the lifecycle or during layout changes. This addresses the persistent Sentry errors that were not fully resolved by the initial fix.
