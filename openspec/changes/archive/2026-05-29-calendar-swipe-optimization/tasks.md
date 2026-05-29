## 1. View Model Enhancements
- [x] 1.1 Refactor `CalendarViewModel` to hold a single stable `_DataSource` instance.
- [x] 1.2 Implement `handleViewChanged(ViewChangedDetails details)` in `CalendarViewModel`.
- [x] 1.3 Optimize the `VisibleWindow` logic to trigger fetches based on `onViewChanged` hints.
- [x] 1.4 Update the state stream to notify the `_DataSource` of new appointments rather than creating a new one.

## 2. Widget Updates
- [x] 2.1 Connect the `onViewChanged` callback in `BookingCalendarView` to the view model.
- [x] 2.2 Refactor `BookingCalendarView` to handle the stable data source.
- [x] 2.3 Minimize the scope of the `StreamBuilder` or use `SelectiveBuilder` patterns to avoid full `SfCalendar` rebuilds.

## 3. Verification
- [x] 3.1 Verify swipe performance in Day View using Flutter DevTools (Performance Overlay).
- [x] 3.2 Ensure data still loads correctly when navigating between views (Month -> Day).
- [x] 3.3 Confirm that special regions (blackout windows) are still updating correctly.
