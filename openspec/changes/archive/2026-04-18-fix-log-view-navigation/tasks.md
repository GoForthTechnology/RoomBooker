## 1. Calendar View Model Enhancements

- [x] 1.1 Add `scrollToTime(DateTime time)` method to `CalendarViewModel` in `lib/ui/widgets/booking_calendar/view_model.dart`.
- [x] 1.2 Implement vertical scrolling logic in `CalendarViewModel` using the Syncfusion `CalendarController`.

## 2. View Bookings View Model Updates

- [x] 2.1 Update `loadExistingRequest` in `lib/ui/screens/view_bookings/view_bookings_view_model.dart` to trigger `scrollToTime` on the calendar view model.
- [x] 2.2 Modify `loadExistingRequest` to call `showEditorAsDialog()` when on small screens to ensure the info panel is visible.

## 3. View Bookings Screen UI Updates

- [x] 3.1 Update `ViewBookingsScreen` in `lib/ui/screens/view_bookings/view_bookings_screen.dart` to dynamically show a `BackButton` in the `AppBar` if the router can pop.
- [x] 3.2 Ensure the room selector toggle remains visible as the leading widget when the screen is the root of its stack.

## 4. Verification

- [x] 4.1 Verify event centering vertically in Day and Week views when navigating from logs.
- [x] 4.2 Verify automatic opening of the editor panel (sidebar or dialog) upon navigation.
- [x] 4.3 Verify back-navigation returns correctly to the Settings screen from the Calendar view.
