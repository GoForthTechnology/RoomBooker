## 1. RequestEditorViewModel Enhancements

- [x] 1.1 Add `isRescheduling` getter to `RequestEditorViewModel` that returns true if `initialRequest` is an existing booking and `editingEnabled` is true.
- [x] 1.2 Implement `moveEventTo(DateTime newStart)` method in `RequestEditorViewModel` that updates the event start and end times while preserving duration.

## 2. ViewBookingsViewModel Updates

- [x] 2.1 Refactor `ViewBookingsViewModel._onTapDate` to check for `isRescheduling` state.
- [x] 2.2 Implement branching logic: if rescheduling, call `moveEventTo` (except in Month view); otherwise, call `loadNewRequest`.
- [x] 2.3 Add logic to specifically ignore taps in `CalendarView.month` when rescheduling.

## 3. Verification

- [x] 3.1 Verify \"Tap to Move\" works in Week view for an existing booking.
- [x] 3.2 Verify tapping in Month view while rescheduling does nothing.
- [x] 3.3 Verify duration is preserved after multiple \"teleport\" moves.

