## Context

The Room Booker application uses a side-by-side or modal editor panel to show booking details. Currently, there is no visual link between the open editor and the corresponding event on the calendar, making it difficult for users to maintain context, especially in crowded calendar views.

## Goals / Non-Goals

**Goals:**
- Provide a clear visual indication of the "active" booking on the calendar.
- The indicator should be high-contrast and work with both light and dark themes.

**Non-Goals:**
- Changing the overall appointment rendering style beyond the border.
- Adding interactive elements to the indicator.

## Decisions

### 1. Tracking Active ID in ViewState
- **Decision**: Add `activeRequestID` to `CalendarViewState` in `lib/ui/widgets/booking_calendar/view_model.dart`.
- **Rationale**: This follows the existing pattern of using `ViewState` to drive the UI rendering. The `CalendarViewModel` already has access to the `_newAppointmentSubject` which holds the active request's appointment.

### 2. Highlighting in Appointment Builder
- **Decision**: Modify the `_appointmentBuilder` in `lib/ui/widgets/booking_calendar/booking_calendar.dart` to use the `activeRequestID`.
- **Rationale**: The custom builder allows for full control over the `Container` decoration. Adding a `border` to the `BoxDecoration` is the most straightforward way to implement this.

### 3. Styling the Indicator
- **Border**: Use a black border with a width of 2.0 for maximum contrast.
- **Drop Shadow**: Add a multi-layered drop shadow (Black with 0.3 opacity, blur radius 4.0, offset 2.0) when the event is active.
- **Rationale**: The black border provides immediate edge clarity, while the drop shadow provides a "lifted" Material 3 effect that aligns with project-wide UI guidelines.

## Risks / Trade-offs

- [Risk] Performance impact of adding logic to the builder. → [Mitigation] The ID comparison is a simple string match and will not impact performance significantly.
