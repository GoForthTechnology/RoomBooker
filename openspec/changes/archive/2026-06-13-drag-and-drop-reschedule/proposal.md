## Why

Currently, rescheduling an event's date, start time, or end time requires opening the request editor and manually selecting new values using drop-downs and date-pickers. Enabling calendar drag-to-move and drag-to-resize capabilities allows administrators to manage schedules quickly and intuitively directly from the main view.

## What Changes

- Enable visual click-and-drag movement of existing bookings on the calendar for administrators.
- Enable visual dragging of event edges (resizing) to change the duration of bookings on the calendar for administrators.
- Intercept drag/resize end gestures and dispatch them reactively to update Firestore.
- Gracefully handle database validation errors by displaying warning SnackBars and restoring the booking's original visual position.

## Capabilities

### New Capabilities
*None*

### Modified Capabilities
- `instance-rescheduling`: Add requirements for dragging and resizing events interactively, handling errors, and keeping these features restricted to non-read-only administrative sessions.

## Impact

- `packages/roombooker_portal/lib/ui/widgets/booking_calendar/view_model.dart` (exposing streams and handling gestures)
- `packages/roombooker_portal/lib/ui/screens/view_bookings/view_bookings_screen.dart` (enabling interaction flags)
- `packages/roombooker_portal/lib/ui/screens/view_bookings/view_bookings_view_model.dart` (handling drag/resize streams and updating Firestore)
