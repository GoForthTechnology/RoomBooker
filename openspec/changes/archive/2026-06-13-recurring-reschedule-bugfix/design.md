## Context

When an appointment is dragged or resized on the calendar, we map it to its corresponding `Request` object using the ID mapping `_requestIndex`. If the appointment represents an occurrence of a recurring series, the indexed `Request` represents the entire recurring series (the master request). Since the calendar only reports the dropping time or resized times, the view model does not know which specific occurrence was dragged or resized unless we capture its original start time.

## Goals / Non-Goals

**Goals:**
- Capture the original start time of the dragged or resized occurrence before it changes.
- Forward this start time to `ViewBookingsViewModel` and `BookingService.updateBooking`.
- Prevent duplication bugs when dragging or resizing recurring booking instances.

**Non-Goals:**
- Supporting drag-and-drop or resize in Month View (which remains guarded/disabled).
- Modifying the underlying Firestore data structures.

## Decisions

### 1. Capture Original Start Time on Gestures
- **Option A (Chosen)**: Store `_draggedAppointmentOriginalStartTime` and `_resizedAppointmentOriginalStartTime` during `onDragStart` and `onAppointmentResizeStart` callbacks on `SfCalendar`. When `onDragEnd` or `onAppointmentResizeEnd` is fired, retrieve these stored values and pack them into `DragDetails` and `ResizeDetails`.
  - *Rationale*: This is simple, robust, and leverages existing Syncfusion hooks at the start of gestures before the appointment times are updated in memory.
- **Option B**: Try to find the occurrence by matching the dropped time back to the recurrence pattern.
  - *Rationale*: Rejected because it requires complex timezone and calendar logic, and doesn't handle cases where the user drags an event back and forth or drops it onto a day with conflicts.

### 2. Forward `originalStartTime` to `updateBooking`
- Modify `ViewBookingsViewModel` to listen to `dragEndStream` and `resizeEndStream`, extract `originalStartTime` from `DragDetails` and `ResizeDetails`, and pass it as the `originalStartTime` parameter to `updateBooking`.
  - *Rationale*: This aligns with how `updateBooking` expects to target a specific occurrence for recurring overrides.

## Risks / Trade-offs

- *[Risk]*: If a gesture starts but does not fire start callbacks, `originalStartTime` could be null.
  - *Mitigation*: Fall back to `request.eventStartTime` if the tracked variable is null.
