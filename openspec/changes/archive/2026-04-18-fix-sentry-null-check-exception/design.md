## Context

The application is experiencing intermittent "Null check operator used on a null value" exceptions in production, as reported by Sentry. These exceptions occur in the `BookingCalendarViewModel`, specifically when accessing properties of the `CalendarController` (part of the `syncfusion_flutter_calendar` package). 

Flutter Web environments and rapid window resizing can cause these controller properties to be null momentarily during initialization or layout updates, leading to crashes when using the null assertion operator (`!`).

## Goals / Non-Goals

**Goals:**
- Eliminate the null pointer crash in `BookingCalendarViewModel`.
- Implement robust defaults for `CalendarController` properties.
- Ensure the UI remains stable during window resizing and initial load.

**Non-Goals:**
- Redesigning the `BookingCalendarViewModel` or the calendar logic.
- Updating the `syncfusion_flutter_calendar` package version.

## Decisions

### Use Null-Safe Accessors with Fallbacks
We will remove all instances of `!` when accessing `controller.displayDate` and `controller.view`.

- **Decision:** Fall back to `DateTime.now()` for `displayDate`.
- **Rationale:** If the calendar has not yet established its display date, defaulting to today is the most logical behavior for the view model's internal calculations.
- **Alternatives:** We could return `null` and make downstream logic nullable, but this would propagate null-handling complexity throughout the view model and view state.

- **Decision:** Fall back to `CalendarView.month` for `view`.
- **Rationale:** `CalendarView.month` is the default view for the SfCalendar widget when none is specified.
- **Alternatives:** None considered, as this matches the library's default behavior.

### Refactor `_safeDisplayDate`
The `_safeDisplayDate` getter will be updated to handle the null check internally and return a normalized `DateTime` (year, month, day only) using the fallback date.

## Risks / Trade-offs

- **[Risk]** Potential UI "jump" → **Mitigation:** If the fallback date (`DateTime.now()`) differs from the intended initial date, there might be a one-frame mismatch. However, since the controller usually initializes almost immediately, this will be imperceptible or quickly corrected by the stream. This is a much better trade-off than a hard crash.
