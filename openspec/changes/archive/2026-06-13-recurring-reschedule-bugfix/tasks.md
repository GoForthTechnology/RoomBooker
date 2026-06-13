## 1. Calendar View Model Updates

- [x] 1.1 Add original start time tracking fields `_draggedAppointmentOriginalStartTime` and `_resizedAppointmentOriginalStartTime` to `CalendarViewModel`.
- [x] 1.2 Implement `handleDragStart` and `handleResizeStart` in `CalendarViewModel` to record the start time of the target appointment before the gesture updates it.
- [x] 1.3 Update `DragDetails` and `ResizeDetails` classes to include `originalStartTime`.
- [x] 1.4 Populate `originalStartTime` in `handleDragEnd` and `handleResizeEnd`.

## 2. Widget Bindings

- [x] 2.1 Bind `onDragStart: viewModel.handleDragStart` and `onAppointmentResizeStart: viewModel.handleResizeStart` on `SfCalendar` in `booking_calendar.dart`.

## 3. View Model Handlers

- [x] 3.1 Update `_onDragEnd` and `_onResizeEnd` in `ViewBookingsViewModel` to pass `details.originalStartTime` to `_rescheduleRequest` and `updateBooking`.

## 4. Tests and Verification

- [x] 4.1 Update existing tests in `view_model_test.dart` and `view_bookings_view_model_test.dart` to support the new `originalStartTime` parameter.
- [x] 4.2 Add unit tests in `view_bookings_view_model_test.dart` verifying that dragging/resizing a repeating instance passes the correct occurrence start time (not the master request's start time) to `updateBooking`.
- [x] 4.3 Run `flutter test` to ensure all 273+ tests pass successfully.
