## Why

When the booking editor panel is open, it is visually unclear which event on the calendar corresponds to the details being shown. Adding a visual indicator, such as a border or outline, to the "active" event will improve user orientation and clarify the connection between the calendar and the editor.

## What Changes

- **Add** a visual indicator (border and drop shadow) to the active booking in the calendar view.
- **Update** the calendar data source to include information about which booking is currently "active" (being edited).

## Capabilities

### New Capabilities
- None

### Modified Capabilities
- `ui-ux`: Add a requirement for visual feedback on the active/selected booking in the calendar.

## Impact

- `lib/ui/widgets/booking_calendar/view_model.dart`: Update `CalendarViewState` and `CalendarViewModel` to track the active request ID.
- `lib/ui/widgets/booking_calendar/booking_calendar.dart`: Update the `_appointmentBuilder` to render a border for the active appointment.
