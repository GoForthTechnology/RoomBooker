## Why

Sentry is reporting a "Null check operator used on a null value" exception in production that cannot be reproduced locally. This crash likely occurs in the `BookingCalendarViewModel` when accessing `CalendarController` properties (like `displayDate` or `view`) during initialization or window resizing when they might be temporarily null.

## What Changes

- Update `BookingCalendarViewModel` to safely handle potentially null properties from the `CalendarController`.
- Replace direct null assertions (`!`) with safe navigation and sensible defaults for `displayDate` and `view`.
- Ensure the `_safeDisplayDate` getter provides a fallback to the current date if the controller's date is not yet available.

## Capabilities

### New Capabilities
- none

### Modified Capabilities
- `ui-ux`: Add requirement for stability during state transitions to prevent crashes during initialization or resizing.

## Impact

The changes will improve the stability of the calendar view, particularly on web platforms or during rapid layout changes, by preventing intermittent null-pointer exceptions in the view model. Only `lib/ui/widgets/booking_calendar/view_model.dart` is expected to be affected.
