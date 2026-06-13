## Context

The system displays events in a `SfCalendar` widget driven by `CalendarViewModel`. While the Syncfusion calendar natively supports drag-and-drop and resize gestures, these are currently disabled (`allowDragAndDrop: false`, `allowAppointmentResize: false`). This design details how we expose drag/resize end events via reactive streams and update the database preserving the current repository architecture.

## Goals / Non-Goals

**Goals:**
- Enable visual drag-to-move and drag-to-resize operations on calendar events for administrators.
- Push state changes back to the database using the existing `BookingService` and `PrivateRequestDetails` lookup structure.
- Recover gracefully from backend validation errors by alerting the user and snapping the event back.

**Non-Goals:**
- Modifying the underlying database structure or the `BookingService` / `BookingRepo` update API signatures.
- Enabling drag-and-drop interactions for non-administrative or read-only users.

## Decisions

### 1. Unified Event Streams on `CalendarViewModel`
We will expose `dragEndStream` and `resizeEndStream` as streams on `CalendarViewModel` using `PublishSubject`.
- *Rationale:* This aligns with the existing pattern for tapping dates/bookings (`dateTapStream` and `requestTapStream`).
- *Alternatives Considered:* Passing drag/resize callback functions from `ViewBookingsScreen` directly to the `CalendarViewModel` constructor. This was rejected because it introduces widget-level coupling and makes dependency injection less clean.

### 2. Decouple `ResizeDetails` from UI Framework
The `ResizeDetails` class will hold a `Request` object instead of a Syncfusion `Appointment`.
- *Rationale:* Decouples business/presenter logic from the specific calendar widget library.

## Risks / Trade-offs

- **[Risk] Validation/Overlap Rejection** → Rescheduling to an invalid or overlapping slot will fail database/form validation.
  - *Mitigation:* Catch errors in the view model, display a warning SnackBar, and let the reactive Firestore stream naturally republish the original booking state, causing the calendar to automatically snap back.
- **[Risk] Concurrent Dragging & Rebuilds** → If the calendar rebuilding logic is triggered during a drag, the UI might jank.
  - *Mitigation:* Ensure `SfCalendar` is not rebuilt on temporary appointments list changes by keeping the data source stable, which is already handled by `BookingCalendarView`'s `distinct` stream checking.
