## 1. Calendar View Model Updates

- [x] 1.1 Expose `dragEndStream` and `resizeEndStream` in `CalendarViewModel` using PublishSubjects.
- [x] 1.2 Update `ResizeDetails` to store a `Request` object instead of an `Appointment`.
- [x] 1.3 Dispatch drag and resize end events into the new streams from `handleDragEnd` and `handleResizeEnd`.

## 2. UI Configuration and View Model Binding

- [x] 2.1 Pass `allowDragAndDrop: !readOnlyMode && orgState.currentUserIsAdmin` and `allowAppointmentResize: !readOnlyMode && orgState.currentUserIsAdmin` during `CalendarViewModel` instantiation in `view_bookings_screen.dart`.
- [x] 2.2 Subscribe to `dragEndStream` and `resizeEndStream` in the constructor of `ViewBookingsViewModel`.
- [x] 2.3 Implement the `_onDragEnd` and `_onResizeEnd` handlers in `ViewBookingsViewModel` to fetch private details, calculate new times, invoke `updateBooking`, and handle errors with SnackBars.

## 3. Verification & Testing

- [x] 3.1 Verify existing tests compile and pass.
- [x] 3.2 Add unit tests in `view_bookings_view_model_test.dart` to verify drag and resize event handling works as expected.
