## Why

Dragging a repeating instance of a recurring booking series to a new day currently makes a copy, leaving the original occurrence in place and creating a new one. This happens because the calendar does not pass the specific occurrence's original start time, making Firestore treat it as a modification to the first instance of the series (or a new booking) rather than an override to the specific occurrence.

## What Changes

- Modify `CalendarViewModel` to track the original start time of the appointment being dragged or resized.
- Update `DragDetails` and `ResizeDetails` to forward the `originalStartTime` to `ViewBookingsViewModel`.
- Update `ViewBookingsViewModel` to pass the `originalStartTime` of the occurrence to `BookingService.updateBooking`.
- Update the UI gesture bindings on `SfCalendar` to hook into `onDragStart` and `onAppointmentResizeStart`.

## Capabilities

### New Capabilities

*(None)*

### Modified Capabilities

- `instance-rescheduling`: Add requirement to support visual drag/resize rescheduling for specific instances of a recurring booking series, correctly matching the instance's original start time in database updates.

## Impact

- Affected files:
  - `view_model.dart` (CalendarViewModel)
  - `booking_calendar.dart` (SfCalendar widget wrapper)
  - `view_bookings_view_model.dart` (ViewBookingsViewModel)
  - Rescheduling unit tests in `view_model_test.dart` and `view_bookings_view_model_test.dart`.
