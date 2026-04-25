## 1. Implementation

- [x] 1.1 Update `onAddNewBooking` in `lib/ui/screens/view_bookings/view_bookings_view_model.dart` to safely handle `controller.displayDate`.
- [x] 1.2 Review all other usages of `CalendarController` in `lib/ui/screens/view_bookings/` for potential null crashes.
- [x] 1.3 Review `lib/ui/screens/landing/landing.dart` for safe handling of dialog results.

## 2. Validation

- [x] 2.1 Run `flutter analyze` to ensure static analysis passes.
- [x] 2.2 Run `flutter test` to ensure no regressions.
