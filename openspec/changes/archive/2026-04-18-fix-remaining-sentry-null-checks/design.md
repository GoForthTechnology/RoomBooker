## Context

Previous fixes addressed null checks within the `BookingCalendarViewModel`, but other components that consume the same `CalendarController` (directly or indirectly) were missed. The `ViewBookingsViewModel` is a primary consumer that uses the controller to determine the target date for new bookings and printing.

## Goals / Non-Goals

**Goals:**
- Eliminate remaining `!` assertions on `CalendarController` properties.
- Ensure all user-triggered actions (Add, Print) are null-safe.

**Non-Goals:**
- Comprehensive refactoring of the view model interaction layer.

## Decisions

### Safe Property Access in `ViewBookingsViewModel`
We will update `ViewBookingsViewModel` to use the same safety patterns established in the view model fix.

- **`onAddNewBooking`**: Use `controller.displayDate ?? DateTime.now()` instead of `controller.displayDate!`.
- **`onPrint`**: (Verified already uses `??`, but will be reviewed for consistency).

## Risks / Trade-offs

- **[Risk]** Wrong default date → **Mitigation:** Defaulting to `DateTime.now()` is the most reasonable fallback for a calendar that hasn't established its own date yet. The impact of a slightly incorrect date in a fallback scenario is negligible compared to a hard crash.
